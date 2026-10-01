import 'dart:math';

import '../../data/name_pool.dart';
import '../generation/random_util.dart';
import '../interaction/parenthood.dart';
import '../models/family_drama.dart';
import '../models/family_issue.dart';
import '../models/game_state.dart';
import '../models/life_log.dart';
import '../models/pending_notice.dart';
import '../models/person.dart';
import '../models/person_development.dart';
import '../models/relation.dart';

/// Yetişkin çocuğun para sıkıntısı, eve dönüşü ve şehir değiştirmesi
/// (Paket AP §8-§13).
///
/// Bu dosyanın sözleşmesi:
///
/// * **Sıkıntı gerçek olmalı (§8).** Çocuk ancak kendi kaydındaki
///   birikimi gerçekten azsa ve işi yoksa para ister. "Çocuğun para
///   istiyor" olayı sebepsiz çıkmaz.
/// * **Para yoktan üretilmez (§9).** Verilen para oyuncunun cüzdanından
///   **düşer** ve çocuğun `PersonDevelopment.money` kaydına **eklenir**.
///   Toplam değişmez. Reddedilen para da hiçbir yere gitmez.
/// * **Hane değişimi gerçek (§12).** Eve dönen çocuk gerçekten
///   `inPlayerHousehold = true` olur ve `LivingCosts` bunu bir gider
///   kalemi olarak görür. Dekoratif değil.
/// * **Şehir değişimi gerçek (§13).** Taşınan çocuğun `Person.city`
///   alanı değişir; mesafe kuralları (§43) bunu okur.
/// * **Soğuma süresi var (§10).** Her yıl para isteyen çocuk olmaz.
///
/// Sayısal değerler `prototypeOnly`'dir (Q-133).
abstract final class AdultChildSupport {
  /// prototypeOnly: yetişkin sayılan yaş.
  static const int prototypeOnlyAdultAge = 20;

  /// prototypeOnly: "birikimi az" sayılan eşik.
  static const int prototypeOnlyBrokeBelow = 40000;

  /// prototypeOnly: para isteğinin yıllık taban ihtimali.
  static const double prototypeOnlyRequestChance = 0.14;

  /// prototypeOnly: ihtimalin üst sınırı.
  static const double prototypeOnlyMaxRequestChance = 0.30;

  /// prototypeOnly: aynı çocuktan iki istek arasında geçmesi gereken
  /// yıl (§10).
  static const int prototypeOnlyRequestCooldown = 4;

  /// prototypeOnly: istenen paranın tabanı.
  static const int prototypeOnlyAskBase = 60000;

  /// prototypeOnly: istenen paranın en fazlası.
  static const int prototypeOnlyAskMax = 240000;

  /// prototypeOnly: "yarısını ver" seçeneğinin oranı.
  static const double prototypeOnlyPartialShare = 0.5;

  /// prototypeOnly: eve dönüş isteğinin eşiği — bu kadar yıl açık
  /// kalan para meselesi eve dönüşe çevrilir (§11).
  static const int prototypeOnlyMoveBackAfterYears = 2;

  /// prototypeOnly: iş bulan çocuğun evden yeniden çıkma ihtimali.
  static const double prototypeOnlyMoveOutChance = 0.45;

  /// prototypeOnly: çalışan çocuğun iş için şehir değiştirme ihtimali
  /// (§13).
  static const double prototypeOnlyRelocateChance = 0.05;

  /// prototypeOnly: şehir değiştirmek için gereken en küçük birikim.
  ///
  /// Taşınmak para ister; parasız çocuk kendiliğinden şehir değiştirmez.
  static const int prototypeOnlyRelocateMoney = 120000;

  /// prototypeOnly: taşınmanın çocuğun birikiminden götürdüğü.
  static const int prototypeOnlyRelocateCost = 60000;

  /// İsteğin soğuma anahtarı.
  static String requestKey(String personId) => 'cocuk-para:$personId';

  /// Eve dönüşün kaydedildiği anahtar.
  ///
  /// Yeni bir save alanı açmak gerekmedi: `lastInteractionAge` zaten
  /// "bu kişiyle bu şey en son hangi yıl oldu" sorusunu tutuyor.
  static String returnKey(String personId) => 'cocuk-eve-donus:$personId';

  /// prototypeOnly: eve dönen çocuğun kalabileceği yıl sayısı.
  ///
  /// Bu pencere olmadan §12 anlamsız kalıyordu: `_childrenLeaveHome`
  /// 25 yaşını geçmiş **her** çocuğu her yıl haneden çıkarıyor, yani
  /// oyuncunun "gelsin" demesi bir yıl sonra kendiliğinden geri
  /// alınıyordu. Hane değişimi gerçek olacaksa bir süre durmalı.
  static const int prototypeOnlyStayYears = 5;

  /// Bu çocuk oyuncunun onayıyla **yakın zamanda** eve döndü mü?
  ///
  /// `_childrenLeaveHome` bunu okuyor ve o çocuğu haneden çıkarmıyor.
  static bool recentlyReturned(GameState state, Person child) {
    final int? donus = state.lastInteractionAge[returnKey(child.id)];
    if (donus == null) return false;
    return state.player.age - donus < prototypeOnlyStayYears;
  }

  // =================================================================
  // §8 — sıkıntı gerçek mi?
  // =================================================================

  /// Bu çocuk gerçekten sıkıntıda mı?
  static bool inTrouble(Person child) {
    final PersonDevelopment? gelisim = child.development;
    if (gelisim == null) return false;
    if (child.age < prototypeOnlyAdultAge) return false;
    if (gelisim.isStudent) return false;
    if (gelisim.money >= prototypeOnlyBrokeBelow) return false;
    // İşi varsa sıkıntı "para yok" değil; maaşı kendi giderini karşılar.
    return !gelisim.isEmployed;
  }

  /// Para isteyebilecek çocuklar.
  static Iterable<Person> candidates(GameState state) =>
      state.people.where((Person p) =>
          p.isAlive && p.relation == RelationType.cocuk && inTrouble(p));

  /// Bu çocuğun bu yıl para isteme ihtimali.
  static double requestChanceFor(GameState state, Person child) {
    if (!inTrouble(child)) return 0;
    return state.familyDrama.scale(
      prototypeOnlyRequestChance,
      FamilyDramaArea.cocuk,
      cap: prototypeOnlyMaxRequestChance,
    );
  }

  static bool offCooldown(GameState state, Person child, int newAge) {
    final int? son = state.lastInteractionAge[requestKey(child.id)];
    if (son == null) return true;
    return newAge - son >= prototypeOnlyRequestCooldown;
  }

  /// Çocuğun bu yıl istediği tutar.
  ///
  /// Açığından türetilir, rastgele bir sayı değil: ne kadar eksiği
  /// varsa o kadar ister.
  static int askedAmount(Person child) {
    final int birikim = child.development?.money ?? 0;
    final int acik = prototypeOnlyBrokeBelow - birikim;
    final int tutar = prototypeOnlyAskBase + (acik < 0 ? 0 : acik);
    return tutar.clamp(prototypeOnlyAskBase, prototypeOnlyAskMax);
  }

  /// Bu yıl bir para isteği açar.
  static ({GameState state, PendingNotice? notice}) maybeRequest(
    GameState state,
    int newAge,
    Random rng,
  ) {
    if (!state.canOpenFamilyDecision) return (state: state, notice: null);
    for (final Person cocuk in candidates(state)) {
      if (!offCooldown(state, cocuk, newAge)) continue;
      if (state.openFamilyIssueFor(cocuk.id, FamilyIssueKind.cocukPara) !=
          null) {
        continue;
      }
      if (!rng.chance(requestChanceFor(state, cocuk))) continue;

      final GameState acik = state.openFamilyIssue(
        kind: FamilyIssueKind.cocukPara,
        personId: cocuk.id,
      );
      if (acik.familyIssues.length == state.familyIssues.length) {
        return (state: state, notice: null);
      }
      final int tutar = askedAmount(cocuk);
      final String metin = '${cocuk.firstName} aradı: işsiz kaldığından '
          'beri zor geçiniyor, ${_bin(tutar)} bin ₺ borç istiyor.';
      GameState next = acik.copyWith(
        lastInteractionAge: <String, int>{
          ...acik.lastInteractionAge,
          requestKey(cocuk.id): newAge,
        },
        log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
          ...acik.log,
          LifeLogEntry(
            age: newAge,
            text: metin,
            category: LogCategory.aile,
            // §55: ortak geçmiş günlükteki `personId`'den toplanıyor.
            personId: cocuk.id,
          ),
        ]),
      );
      return (
        state: next,
        notice: PendingNotice(
          id: 'cocuk-para-${cocuk.id}-$newAge',
          kind: NoticeKind.aileDonum,
          age: newAge,
          title: 'Çocuğun para istiyor',
          text: metin,
          personId: cocuk.id,
        ),
      );
    }
    return (state: state, notice: null);
  }

  // =================================================================
  // §9-§10 — oyuncunun kararı ve paranın gerçekten el değiştirmesi
  // =================================================================

  /// Oyuncuya sorulmayı bekleyen para isteği; yoksa `null`.
  static FamilyIssue? pendingRequest(GameState state) {
    for (final FamilyIssue mesele in state.familyIssues) {
      if (!mesele.isOpen) continue;
      if (mesele.kind != FamilyIssueKind.cocukPara) continue;
      if (mesele.response != null) continue;
      return mesele;
    }
    return null;
  }

  static bool isPending(GameState state) => pendingRequest(state) != null;

  /// Bu cevap için ödenecek tutar.
  static int amountFor(GameState state, FamilyIssueResponse cevap) {
    final FamilyIssue? mesele = pendingRequest(state);
    if (mesele == null) return 0;
    final Person? cocuk = state.personById(mesele.personId);
    if (cocuk == null) return 0;
    final int istenen = askedAmount(cocuk);
    return switch (cevap) {
      FamilyIssueResponse.paraVerdi => istenen,
      FamilyIssueResponse.destekOldu =>
        (istenen * prototypeOnlyPartialShare).round(),
      _ => 0,
    };
  }

  /// Bu cevap neden seçilemiyor; seçilebiliyorsa `null` (D-095).
  static String? blockReason(GameState state, FamilyIssueResponse cevap) {
    final int tutar = amountFor(state, cevap);
    if (tutar <= 0) return null;
    if (state.player.wallet < tutar) {
      return '${_bin(tutar)} bin ₺ gerekiyor; cüzdanında o kadar yok.';
    }
    return null;
  }

  /// Oyuncu kararını verdi.
  ///
  /// Verilen para cüzdandan **düşer** ve çocuğun kaydına **eklenir**:
  /// toplam değişmez (§9).
  static ({GameState state, String text}) respond(
    GameState state,
    FamilyIssueResponse cevap,
  ) {
    final FamilyIssue? mesele = pendingRequest(state);
    if (mesele == null) return (state: state, text: '');
    final String? engel = blockReason(state, cevap);
    if (engel != null) return (state: state, text: engel);

    final Person? cocuk = state.personById(mesele.personId);
    if (cocuk == null) {
      return (
        state: state.updateFamilyIssue(
          mesele.id,
          status: FamilyIssueStatus.kapandi,
          resolvedAtAge: state.player.age,
        ),
        text: '',
      );
    }

    final int tutar = amountFor(state, cevap);
    GameState next = state;
    if (tutar > 0) {
      next = next.copyWith(
        player: next.player.copyWith(wallet: next.player.wallet - tutar),
        people: List<Person>.unmodifiable(<Person>[
          for (final Person p in next.people)
            if (p.id == cocuk.id && p.development != null)
              p.copyWith(
                development: p.development!.copyWith(
                  money: p.development!.money + tutar,
                ),
              )
            else
              p,
        ]),
      );
    }

    // Bağ değişimi: para kadar, tutumun kendisi de sayılır.
    final int bagDegisimi = switch (cevap) {
      FamilyIssueResponse.paraVerdi => 4,
      FamilyIssueResponse.destekOldu => 2,
      FamilyIssueResponse.konustu => 0,
      FamilyIssueResponse.karismadi => -2,
      FamilyIssueResponse.reddetti => -5,
    };
    next = next.copyWith(
      people: List<Person>.unmodifiable(<Person>[
        for (final Person p in next.people)
          if (p.id == cocuk.id)
            p.copyWith(bond: (p.bond + bagDegisimi).clamp(0, 100))
          else
            p,
      ]),
    );

    final String metin = switch (cevap) {
      FamilyIssueResponse.paraVerdi =>
        '${cocuk.firstName}\'in istediği parayı verdin.',
      FamilyIssueResponse.destekOldu =>
        '${cocuk.firstName}\'e elinden geldiği kadarını verdin.',
      FamilyIssueResponse.konustu =>
        '${cocuk.firstName} ile konuştun ama para vermedin.',
      FamilyIssueResponse.karismadi =>
        '${cocuk.firstName}\'in para isteğine cevap vermedin.',
      FamilyIssueResponse.reddetti =>
        '${cocuk.firstName}\'e para vermeyeceğini söyledin.',
    };

    next = next.updateFamilyIssue(
      mesele.id,
      response: cevap,
      lastEventAge: next.player.age,
      stage: mesele.stage + 1,
      // Para verildiyse mesele o yıl kapanır: sıkıntı giderildi.
      status: tutar > 0 ? FamilyIssueStatus.cozuldu : null,
      resolvedAtAge: tutar > 0 ? next.player.age : null,
    );
    next = next.copyWith(
      log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
        ...next.log,
        LifeLogEntry(
          age: next.player.age,
          text: metin,
          category: LogCategory.aile,
          personId: cocuk.id,
        ),
      ]),
    );
    return (state: next, text: metin);
  }

  // =================================================================
  // §11-§12 — eve dönüş
  // =================================================================

  /// Eve dönmek isteyen çocuk var mı? (Kararı oyuncu verir.)
  static FamilyIssue? pendingMoveBack(GameState state) {
    for (final FamilyIssue mesele in state.familyIssues) {
      if (!mesele.isOpen) continue;
      if (mesele.kind != FamilyIssueKind.cocukPara) continue;
      if (mesele.response == null) continue;
      if (state.player.age - mesele.openedAtAge <
          prototypeOnlyMoveBackAfterYears) {
        continue;
      }
      final Person? cocuk = state.personById(mesele.personId);
      if (cocuk == null || !cocuk.isAlive) continue;
      if (cocuk.inPlayerHousehold) continue;
      if (!inTrouble(cocuk)) continue;
      return mesele;
    }
    return null;
  }

  /// Oyuncu çocuğun eve dönmesine izin verdi ya da vermedi.
  ///
  /// `true` ise çocuk gerçekten haneye girer: `inPlayerHousehold` ve
  /// şehri oyuncunun şehri olur, `LivingCosts` yeni bir gider kalemi
  /// görür (§12).
  static ({GameState state, String text}) answerMoveBack(
    GameState state,
    bool accept,
  ) {
    final FamilyIssue? mesele = pendingMoveBack(state);
    if (mesele == null) return (state: state, text: '');
    final Person cocuk = state.personById(mesele.personId)!;

    GameState next = state;
    final String metin;
    if (accept) {
      next = next.copyWith(
        people: List<Person>.unmodifiable(<Person>[
          for (final Person p in next.people)
            if (p.id == cocuk.id)
              p.copyWith(
                inPlayerHousehold: true,
                city: next.player.currentCity,
                bond: (p.bond + 4).clamp(0, 100),
              )
            else
              p,
        ]),
        // Dönüş kaydediliyor ki yıllık "çocuklar evden çıkar" kuralı
        // oyuncunun kararını bir yıl sonra geri almasın.
        lastInteractionAge: <String, int>{
          ...next.lastInteractionAge,
          returnKey(cocuk.id): next.player.age,
        },
      );
      metin = '${cocuk.firstName} eşyalarını toplayıp eve döndü.';
    } else {
      next = next.copyWith(
        people: List<Person>.unmodifiable(<Person>[
          for (final Person p in next.people)
            if (p.id == cocuk.id)
              p.copyWith(bond: (p.bond - 6).clamp(0, 100))
            else
              p,
        ]),
      );
      metin = '${cocuk.firstName}\'e eve dönmesinin olmayacağını söyledin.';
    }

    next = next.updateFamilyIssue(
      mesele.id,
      lastEventAge: next.player.age,
      status: FamilyIssueStatus.kapandi,
      resolvedAtAge: next.player.age,
    );
    next = next.copyWith(
      log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
        ...next.log,
        LifeLogEntry(
          age: next.player.age,
          text: metin,
          category: LogCategory.aile,
          personId: cocuk.id,
        ),
      ]),
    );
    return (state: next, text: metin);
  }

  // =================================================================
  // §13 — şehir değiştirme ve yeniden evden çıkma
  // =================================================================

  /// Yılın kendiliğinden olan kısmı: iş bulan çocuk evden yeniden
  /// çıkar, çalışan çocuk iş için şehir değiştirebilir.
  ///
  /// İkisi de **gerçek** kayıt değişikliği; dekoratif değil.
  static ({GameState state, List<String> logTexts}) advanceYear(
    GameState state,
    int newAge,
    Random rng,
  ) {
    GameState next = state;
    final List<String> satirlar = <String>[];

    for (final Person cocuk in state.people) {
      if (!cocuk.isAlive) continue;
      if (cocuk.relation != RelationType.cocuk) continue;
      if (cocuk.age < prototypeOnlyAdultAge) continue;
      final PersonDevelopment? gelisim = cocuk.development;
      if (gelisim == null) continue;

      // Eve dönmüş çocuk iş bulduysa yeniden kendi evine çıkabilir.
      //
      // DİKKAT — yaş eşiği `Parenthood.prototypeOnlyLeaveHomeAge`'den
      // okunuyor, buradaki yetişkinlik yaşından değil.
      //
      // İlk yazımda 20 yaşındaki çalışan çocuk da evden çıkıyordu ve bu
      // oyunun kendi kuralıyla çelişiyordu: çocuklar 25'inde kendi
      // evine çıkar (`_childrenLeaveHome`). `family_integration` testi
      // bunu yakaladı — 20 yaşında çalışan bir çocuk hanede olmadığı
      // için "çocuk hanede kalır" iddiası kırıldı. Kural iki yerde iki
      // farklı sayı olmasın diye tek kaynaktan okunuyor.
      if (cocuk.inPlayerHousehold &&
          cocuk.age >= Parenthood.prototypeOnlyLeaveHomeAge &&
          gelisim.isEmployed &&
          rng.chance(prototypeOnlyMoveOutChance)) {
        next = next.copyWith(
          people: List<Person>.unmodifiable(<Person>[
            for (final Person p in next.people)
              if (p.id == cocuk.id) p.copyWith(inPlayerHousehold: false) else p,
          ]),
        );
        satirlar.add('${cocuk.firstName} işe girdi ve yeniden kendi evine '
            'çıktı.');
        continue;
      }

      // Çalışan ve birikimi olan çocuk iş için başka şehre taşınabilir.
      if (!cocuk.inPlayerHousehold &&
          gelisim.isEmployed &&
          gelisim.money >= prototypeOnlyRelocateMoney &&
          rng.chance(prototypeOnlyRelocateChance)) {
        final String simdiki = cocuk.city ?? next.player.currentCity;
        final List<String> secenekler =
            sehirler.where((String s) => s != simdiki).toList(growable: false);
        if (secenekler.isEmpty) continue;
        final String yeni = rng.pick(secenekler);
        next = next.copyWith(
          people: List<Person>.unmodifiable(<Person>[
            for (final Person p in next.people)
              if (p.id == cocuk.id)
                p.copyWith(
                  city: yeni,
                  // Taşınmanın bedeli çocuğun kendi birikiminden çıkar;
                  // para yoktan üretilmez, oyuncunun cüzdanı da
                  // kendiliğinden eksilmez.
                  development: p.development!.copyWith(
                    money: p.development!.money - prototypeOnlyRelocateCost,
                  ),
                )
              else
                p,
          ]),
        );
        satirlar.add('${cocuk.firstName} işi için $yeni\'ye taşındı.');
      }
    }
    return (state: next, logTexts: List<String>.unmodifiable(satirlar));
  }

  static String _bin(int tutar) => (tutar / 1000).round().toString();
}
