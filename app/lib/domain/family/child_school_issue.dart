import 'dart:math';

import '../generation/random_util.dart';
import 'family_mood.dart';
import '../models/family_drama.dart';
import '../models/family_issue.dart';
import 'child_rules.dart';
import '../models/game_state.dart';
import '../models/life_log.dart';
import '../models/pending_notice.dart';
import '../models/person.dart';
import '../models/person_development.dart';
import '../models/relation.dart';
import '../models/stats.dart';

/// Oyuncunun okul çağındaki çocuğuyla **gerçekten** yaşadığı sorun ve
/// oyuncunun verdiği karar (Paket AP §5-§7).
///
/// Üç kural bu dosyanın her yerinde geçerli:
///
/// * **Olmayan problemi uydurma (§5).** Sorun ancak çocuğun kendi
///   kaydından okunabilen bir sebebi varsa açılır: dersleri zorlanıyor,
///   mutsuz, ya da oyuncuyla arası çok uzak. Sebepsiz "çocuğun okulda
///   sorun yaşıyor" olayı çıkmaz.
/// * **Çocuk oyuncunun kuklası değildir (§1).** Oyuncunun kararı
///   sonucu **belirlemez**, ihtimali kaydırır. En iyi seçim de kötü
///   sonuç verebilir; karışmamak da iyi sonuç verebilir.
/// * **Tek olayla +20 zekâ yok (§6).** Etkiler küçük ve yıllara yayılı.
///
/// Sayısal değerler `prototypeOnly`'dir (Q-133).
abstract final class ChildSchoolIssue {
  /// prototypeOnly: okul sorununun açılabileceği yaş aralığı.
  static const int prototypeOnlyMinAge = 7;
  static const int prototypeOnlyMaxAge = 17;

  /// prototypeOnly: "dersleri zor geliyor" sayılan zekâ eşiği.
  static const int prototypeOnlyLowIntelligence = 45;

  /// prototypeOnly: "okula gitmek istemiyor" sayılan mutluluk eşiği.
  static const int prototypeOnlyLowHappiness = 40;

  /// prototypeOnly: "arası çok uzak" sayılan yakınlık eşiği.
  static const int prototypeOnlyLowBond = 25;

  /// prototypeOnly: sebebi olan bir çocukta sorunun yıllık taban
  /// ihtimali. Dram profili bunu ölçekler (§2).
  static const double prototypeOnlyBaseChance = 0.12;

  /// prototypeOnly: her ek sebep ihtimali bu kadar artırır.
  static const double prototypeOnlyPerReasonBonus = 0.06;

  /// prototypeOnly: ihtimalin üst sınırı.
  static const double prototypeOnlyMaxChance = 0.30;

  /// prototypeOnly: aynı çocukta yeni sorun açılması için geçmesi
  /// gereken yıl (§46 soğuma).
  static const int prototypeOnlyCooldown = 4;

  /// prototypeOnly: özel dersin yıllık bedeli.
  static const int prototypeOnlyTutorCost = 48000;

  /// prototypeOnly: her yılın en fazla stat etkisi.
  ///
  /// Kasten küçük: §6 "tek olayla +20 intelligence YOK" dedi.
  static const int prototypeOnlyMaxStatStep = 4;

  // =================================================================
  // §5 — sorunun gerçek sebebi
  // =================================================================

  /// Bu çocuğun okul sorununun **gerçek** sebepleri.
  ///
  /// Boş dönerse sorun açılmaz: oyun bir problem uydurmaz.
  static List<String> reasonsFor(Person child) {
    final PersonDevelopment? gelisim = child.development;
    if (gelisim == null) return const <String>[];
    if (!gelisim.isStudent) return const <String>[];
    if (child.age < prototypeOnlyMinAge) return const <String>[];
    if (child.age > prototypeOnlyMaxAge) return const <String>[];

    final List<String> sebepler = <String>[];
    final Stats s = gelisim.stats;
    if (s.intelligence < prototypeOnlyLowIntelligence) {
      sebepler.add('dersler');
    }
    if (s.happiness < prototypeOnlyLowHappiness) {
      sebepler.add('isteksizlik');
    }
    if (child.bond < prototypeOnlyLowBond) {
      sebepler.add('mesafe');
    }
    return List<String>.unmodifiable(sebepler);
  }

  /// Okul sorunu açılabilecek çocuklar.
  ///
  /// Yalnızca oyuncunun **kendi** çocuğu: üvey çocuk ve kardeşin okul
  /// hayatına karışmak bu paketin konusu değil, ve her bağ için ikinci
  /// bir sistem kurulmasın.
  static Iterable<Person> candidates(GameState state) =>
      state.people.where((Person p) =>
          p.isAlive &&
          p.relation == RelationType.cocuk &&
          reasonsFor(p).isNotEmpty);

  /// Bu çocukta bu yıl sorun çıkma ihtimali.
  static double chanceFor(GameState state, Person child) {
    final List<String> sebepler = reasonsFor(child);
    if (sebepler.isEmpty) return 0;
    final double taban = (prototypeOnlyBaseChance +
            (sebepler.length - 1) * prototypeOnlyPerReasonBonus)
        .clamp(0.0, prototypeOnlyMaxChance);
    // Evde konulmuş taze bir kural ihtimali azaltır (Paket BK/3).
    // Kural yoksa çarpan **tam olarak 1,0**: hiçbir hesap kaymaz.
    final double kurall = taban * ChildRules.reliefFor(state, child);
    return state.familyDrama.scale(
      kurall,
      FamilyDramaArea.cocuk,
      cap: prototypeOnlyMaxChance,
    );
  }

  /// Bu çocukta soğuma süresi doldu mu? (§46)
  static bool offCooldown(GameState state, Person child) {
    for (final FamilyIssue mesele in state.familyIssues) {
      if (mesele.personId != child.id) continue;
      if (mesele.kind != FamilyIssueKind.cocukOkul) continue;
      if (mesele.isOpen) return false;
      final int bitis = mesele.resolvedAtAge ?? mesele.lastEventAge;
      if (state.player.age - bitis < prototypeOnlyCooldown) return false;
    }
    return true;
  }

  /// Bu yıl bir okul sorunu açar; açılmadıysa durum aynen döner.
  ///
  /// §3'ün sınırı [GameState.openFamilyIssue] içinde: bir yılda en fazla
  /// bir büyük aile kararı.
  static ({GameState state, PendingNotice? notice}) maybeOpen(
    GameState state,
    Random rng,
  ) {
    if (!state.canOpenFamilyDecision) {
      return (state: state, notice: null);
    }
    // Aday çocuklar sabit bir sırayla geziliyor: zar sırası kayıttan
    // kayıta aynı kalsın.
    for (final Person cocuk in candidates(state)) {
      if (!offCooldown(state, cocuk)) continue;
      if (!rng.chance(chanceFor(state, cocuk))) continue;

      final GameState acik = state.openFamilyIssue(
        kind: FamilyIssueKind.cocukOkul,
        personId: cocuk.id,
      );
      // `openFamilyIssue` §3 yüzünden hiçbir şey yapmadıysa durma.
      if (acik.familyIssues.length == state.familyIssues.length) {
        return (state: state, notice: null);
      }
      final String metin = _problemText(cocuk, reasonsFor(cocuk));
      return (
        state: acik.copyWith(
          log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
            ...acik.log,
            LifeLogEntry(
              age: acik.player.age,
              text: metin,
              category: LogCategory.aile,
              // §55: `SharedHistory` kişinin ortak geçmişini günlükteki
              // `personId` alanından topluyor. Boş kalırsa aile meselesi
              // o kişinin kartında hiç görünmüyor.
              personId: cocuk.id,
            ),
          ]),
        ),
        notice: PendingNotice(
          id: 'cocuk-okul-${cocuk.id}-${state.player.age}',
          kind: NoticeKind.aileDonum,
          age: state.player.age,
          title: 'Okuldan haber',
          text: metin,
          personId: cocuk.id,
        ),
      );
    }
    return (state: state, notice: null);
  }

  // =================================================================
  // §6 — oyuncunun kararı
  // =================================================================

  /// Oyuncuya sorulmayı bekleyen okul sorunu; yoksa `null`.
  static FamilyIssue? pendingIssue(GameState state) {
    for (final FamilyIssue mesele in state.familyIssues) {
      if (!mesele.isOpen) continue;
      if (mesele.kind != FamilyIssueKind.cocukOkul) continue;
      if (mesele.response != null) continue;
      return mesele;
    }
    return null;
  }

  static bool isPending(GameState state) => pendingIssue(state) != null;

  /// Bu seçenek şu an uygulanabilir mi, değilse neden?
  ///
  /// Para yetmiyorsa seçenek **sessizce** kaybolmaz; gerekçesi yazılır
  /// (D-095).
  static String? blockReason(GameState state, FamilyIssueResponse cevap) {
    if (cevap != FamilyIssueResponse.paraVerdi) return null;
    if (state.player.wallet < prototypeOnlyTutorCost) {
      return 'Özel ders için ${prototypeOnlyTutorCost ~/ 1000} bin ₺ '
          'gerekiyor; cüzdanında yok.';
    }
    return null;
  }

  /// Oyuncu kararını verdi.
  ///
  /// Karar **sonucu belirlemez** (§1): yalnızca çocuğun o yıl
  /// toparlanma ihtimalini kaydırır. Etki küçüktür ve yıllara yayılır.
  static ({GameState state, String text}) choose(
    GameState state,
    FamilyIssueResponse cevap,
    Random rng,
  ) {
    final FamilyIssue? mesele = pendingIssue(state);
    if (mesele == null) return (state: state, text: '');
    final String? engel = blockReason(state, cevap);
    if (engel != null) return (state: state, text: engel);

    final Person? cocuk = state.personById(mesele.personId);
    if (cocuk == null) {
      // Çocuk kayıttan düşmüşse mesele kapanır; hayalet mesele kalmaz.
      return (
        state: state.updateFamilyIssue(
          mesele.id,
          status: FamilyIssueStatus.kapandi,
          resolvedAtAge: state.player.age,
        ),
        text: '',
      );
    }

    GameState next = state;
    if (cevap == FamilyIssueResponse.paraVerdi) {
      next = next.copyWith(
        player: next.player.copyWith(
          wallet: next.player.wallet - prototypeOnlyTutorCost,
        ),
      );
    }

    next = next.updateFamilyIssue(
      mesele.id,
      response: cevap,
      lastEventAge: next.player.age,
      stage: mesele.stage + 1,
    );

    final String metin = _choiceText(cocuk, cevap);
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
    // Karar verildiği yıl çocuğun yakınlığı biraz değişir: ilgilenmek
    // yakınlaştırır, karışmamak uzaklaştırır. İkisi de küçük.
    final int bagDegisimi = switch (cevap) {
      FamilyIssueResponse.destekOldu => 3,
      FamilyIssueResponse.paraVerdi => 2,
      FamilyIssueResponse.konustu => 1,
      FamilyIssueResponse.karismadi => -2,
      FamilyIssueResponse.reddetti => -3,
    };
    next = _bumpBond(next, cocuk.id, bagDegisimi);
    // Zar burada **atılmaz**: sonucun kendisi bir sonraki yıl
    // [advanceYear] içinde belirlenir. Böylece karar ile sonuç aynı
    // anda olmuyor ve oyuncu "seçtim, oldu" hissi yaşamıyor (§1).
    return (state: next, text: metin);
  }

  // =================================================================
  // §6, §7 — meselenin yıllara yayılması ve başarı
  // =================================================================

  /// prototypeOnly: cevaba göre toparlanma ihtimali.
  ///
  /// Hiçbiri 0 ya da 1 değil: en iyi seçim de tutmayabilir, karışmamak
  /// da tutabilir (§1).
  static double recoveryChance(FamilyIssueResponse? cevap) =>
      switch (cevap) {
        FamilyIssueResponse.destekOldu => 0.45,
        FamilyIssueResponse.paraVerdi => 0.50,
        FamilyIssueResponse.konustu => 0.32,
        FamilyIssueResponse.karismadi => 0.18,
        FamilyIssueResponse.reddetti => 0.14,
        null => 0.18,
      };

  /// prototypeOnly: mesele kendi kendine kapanmadan en fazla kaç yıl
  /// sürer.
  static const int prototypeOnlyMaxYears = 4;

  /// Açık okul meselelerini bir yıl ilerletir.
  ///
  /// Dönen metinler oyuncunun günlüğüne yazılabilir.
  static ({GameState state, List<String> logTexts}) advanceYear(
    GameState state,
    int newAge,
    Random rng,
  ) {
    GameState next = state;
    final List<String> satirlar = <String>[];

    for (final FamilyIssue mesele in state.familyIssues) {
      if (!mesele.isOpen) continue;
      if (mesele.kind != FamilyIssueKind.cocukOkul) continue;
      // Kararın verildiği yıl sonuç açıklanmaz.
      if (mesele.lastEventAge >= newAge) continue;

      final Person? cocuk = next.personById(mesele.personId);
      if (cocuk == null || !cocuk.isAlive) {
        next = next.updateFamilyIssue(
          mesele.id,
          status: FamilyIssueStatus.kapandi,
          resolvedAtAge: newAge,
        );
        continue;
      }

      final bool toparlandi = rng.chance(recoveryChance(mesele.response));
      final bool sureBitti = newAge - mesele.openedAtAge >= prototypeOnlyMaxYears;

      if (toparlandi) {
        next = _nudgeStats(next, cocuk.id, intelligence: 2, happiness: 3);
        next = next.updateFamilyIssue(
          mesele.id,
          status: FamilyIssueStatus.cozuldu,
          resolvedAtAge: newAge,
          lastEventAge: newAge,
        );
        satirlar.add('${cocuk.firstName} okulda toparlandı; '
            'öğretmeni "artık derse giriyor" dedi.');
      } else if (sureBitti) {
        // Mesele kapanır ama iyi bitmez: oyun kimseyi kurtarmaya mecbur
        // değil. Etki yine küçük.
        next = _nudgeStats(next, cocuk.id, happiness: -2);
        next = next.updateFamilyIssue(
          mesele.id,
          status: FamilyIssueStatus.kapandi,
          resolvedAtAge: newAge,
          lastEventAge: newAge,
        );
        satirlar.add('${cocuk.firstName} okulu zar zor sürdürüyor; '
            'bu yıl da istediğin gibi olmadı.');
      } else {
        next = next.updateFamilyIssue(
          mesele.id,
          lastEventAge: newAge,
          stage: mesele.stage + 1,
        );
        satirlar.add('${cocuk.firstName} ile okul meselesi sürüyor.');
      }
    }
    return (state: next, logTexts: List<String>.unmodifiable(satirlar));
  }

  // =================================================================
  // §7 — başarı: aile hayatı yalnızca sorun değildir
  // =================================================================

  /// prototypeOnly: başarı olayının yıllık taban ihtimali.
  static const double prototypeOnlyAchievementChance = 0.10;

  /// prototypeOnly: başarı için gereken zekâ.
  static const int prototypeOnlyAchievementIntelligence = 62;

  /// prototypeOnly: aynı çocukta iki başarı arasında geçmesi gereken
  /// yıl (§46: tekrar tekrar aynı bildirim basılmaz).
  static const int prototypeOnlyAchievementCooldown = 3;

  /// Okuldaki bir başarıyı bildirir; çıkmadıysa `null`.
  ///
  /// Başarı da **gerçek** olmalı: zekâsı iyi olan, okula giden ve o
  /// yıl bir meselesi olmayan çocukta çıkar. Uydurma madalya yok.
  static ({GameState state, PendingNotice? notice, String? logText})
      maybeAchievement(GameState state, int newAge, Random rng) {
    for (final Person cocuk in state.people) {
      if (!cocuk.isAlive) continue;
      if (cocuk.relation != RelationType.cocuk) continue;
      final PersonDevelopment? gelisim = cocuk.development;
      if (gelisim == null || !gelisim.isStudent) continue;
      if (cocuk.age < prototypeOnlyMinAge) continue;
      if (gelisim.stats.intelligence < prototypeOnlyAchievementIntelligence) {
        continue;
      }
      // Açık bir okul meselesi varken başarı bildirimi çelişki üretirdi.
      if (state.openFamilyIssueFor(cocuk.id, FamilyIssueKind.cocukOkul) !=
          null) {
        continue;
      }
      if (!_achievementOffCooldown(state, cocuk, newAge)) continue;
      final double ihtimal = state.familyDrama.scale(
        prototypeOnlyAchievementChance,
        FamilyDramaArea.cocuk,
        cap: 0.25,
      );
      if (!rng.chance(ihtimal)) continue;

      final String metin = '${cocuk.firstName} okulda derece yaptı; '
          'öğretmeni seni arayıp tebrik etti.';
      GameState next = _bumpBond(state, cocuk.id, 2);
      next = _nudgeStats(next, cocuk.id, happiness: 3);
      next = next.copyWith(
        lastInteractionAge: <String, int>{
          ...next.lastInteractionAge,
          _achievementKey(cocuk.id): newAge,
        },
      );
      return (
        state: next,
        notice: PendingNotice(
          id: 'cocuk-basari-${cocuk.id}-$newAge',
          kind: NoticeKind.aileDonum,
          age: newAge,
          title: 'Çocuğunun başarısı',
          text: metin,
          personId: cocuk.id,
        ),
        logText: metin,
      );
    }
    return (state: state, notice: null, logText: null);
  }

  /// Başarı bildiriminin soğuma anahtarı.
  ///
  /// Yeni bir save alanı açmak gerekmedi: `lastInteractionAge` zaten
  /// "bu kişiyle bu şey en son hangi yıl oldu" sorusunu tutuyor.
  ///
  /// Anahtar `FamilyMood` ile **paylaşılıyor**: gurur etkisi de aynı
  /// kaydı okuyor, iki yerde iki gerçeklik oluşmasın.
  static String _achievementKey(String personId) =>
      FamilyMood.achievementKey(personId);

  static bool _achievementOffCooldown(
    GameState state,
    Person child,
    int newAge,
  ) {
    final int? son = state.lastInteractionAge[_achievementKey(child.id)];
    if (son == null) return true;
    return newAge - son >= prototypeOnlyAchievementCooldown;
  }

  // =================================================================
  // Yardımcılar
  // =================================================================

  static GameState _bumpBond(GameState state, String personId, int delta) {
    final List<Person> yeni = <Person>[
      for (final Person p in state.people)
        if (p.id == personId)
          p.copyWith(bond: (p.bond + delta).clamp(0, 100))
        else
          p,
    ];
    return state.copyWith(people: List<Person>.unmodifiable(yeni));
  }

  /// Çocuğun özelliklerini **küçük** adımlarla değiştirir (§6).
  static GameState _nudgeStats(
    GameState state,
    String personId, {
    int intelligence = 0,
    int happiness = 0,
  }) {
    final int zeka =
        intelligence.clamp(-prototypeOnlyMaxStatStep, prototypeOnlyMaxStatStep);
    final int mutluluk =
        happiness.clamp(-prototypeOnlyMaxStatStep, prototypeOnlyMaxStatStep);
    // Artış `Stats.gain` üzerinden geçiyor: oyunun azalan verim kuralı
    // tek yerde duruyor ve `stat_gain_test` bunu kalıcı olarak
    // denetliyor. İlk yazımda doğrudan toplama yapılmıştı; o testin
    // yakaladığı gerçek bir kural ihlaliydi.
    final List<Person> yeni = <Person>[
      for (final Person p in state.people)
        if (p.id == personId && p.development != null)
          p.copyWith(
            development: p.development!.copyWith(
              stats: p.development!.stats.gain(
                intelligence: zeka,
                happiness: mutluluk,
              ),
            ),
          )
        else
          p,
    ];
    return state.copyWith(people: List<Person>.unmodifiable(yeni));
  }

  static String _problemText(Person child, List<String> sebepler) {
    final String ad = child.firstName;
    if (sebepler.contains('dersler') && sebepler.contains('isteksizlik')) {
      return '$ad\'in öğretmeni aradı: dersleri geriden geliyor ve son '
          'zamanlarda okula gitmek istemiyor.';
    }
    if (sebepler.contains('dersler')) {
      return '$ad\'in öğretmeni aradı: dersleri geriden geliyor, '
          'desteklenmesi gerekiyor.';
    }
    if (sebepler.contains('isteksizlik')) {
      return '$ad bu sabah da okula gitmek istemedi; bir süredir '
          'isteksiz.';
    }
    return '$ad\'in okuldan haberlerini başkasından duydun; aranız '
        'uzun zamandır mesafeli.';
  }

  static String _choiceText(Person child, FamilyIssueResponse cevap) {
    final String ad = child.firstName;
    return switch (cevap) {
      FamilyIssueResponse.destekOldu =>
        '$ad ile akşamları birlikte oturup ders çalışmaya başladın.',
      FamilyIssueResponse.paraVerdi =>
        '$ad için özel ders tuttun.',
      FamilyIssueResponse.konustu =>
        '$ad ile uzun uzun konuştun; kararı ona bıraktın.',
      FamilyIssueResponse.karismadi =>
        '$ad\'in okul meselesine karışmamayı seçtin.',
      FamilyIssueResponse.reddetti =>
        '$ad\'e bu konuda yardım etmeyeceğini söyledin.',
    };
  }
}
