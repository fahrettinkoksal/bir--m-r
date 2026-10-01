import 'dart:math';

import '../generation/random_util.dart';
import '../models/family_drama.dart';
import '../models/family_issue.dart';
import '../models/game_state.dart';
import '../models/life_log.dart';
import '../models/pending_notice.dart';
import '../models/person.dart';
import '../models/person_development.dart';
import '../models/relation.dart';

/// Kardeşle para, yaşlı bakımı ve miras anlaşmazlıkları
/// (Paket AP §28-§32, §35-§36).
///
/// Üç mesele de aynı iskelete oturuyor (`FamilyIssue` + oyuncunun
/// cevabı) çünkü §4 "gereksiz generic framework kurma" dedi: üç ayrı
/// sistem değil, üç ayrı **içerik**.
///
/// Sözleşme:
///
/// * **"Kan bağı = bedava ATM" değil (§29).** Kardeş para isterken
///   gerçek bir ihtiyaç gösteriyor; oyuncu kardeşinden para isterse
///   kardeş **her zaman evet demiyor** — kendi birikimi ve yakınlık
///   belirliyor. Uydurma milyonluk hesap açılmıyor: kardeşin verebileceği
///   para kendi kaydındaki paradır.
/// * **Bakım kapasitesi gerçek (§31).** "Ben bakarım" demek para, hane
///   ve şehir gerektiriyor. Kapasitesi olmayan oyuncuya bu seçenek
///   gerekçesiyle kapalı (D-095).
/// * **Miras ikinci kez üretilmiyor (§36).** Anlaşmazlık parayı
///   oyuncunun cüzdanından kardeşin kaydına **taşıyor**; toplam
///   değişmiyor, yeni para doğmuyor.
/// * **Kuslük garanti değil, barışma da (§33-§34).** O mekanizma Paket
///   AO'da `FriendshipDepth` içinde zaten var ve ikinci kez
///   kurulmuyor; buradaki kararlar yalnızca yakınlığı değiştiriyor,
///   küslüğü kendileri yazmıyor.
///
/// Sayısal değerler `prototypeOnly`'dir (Q-133).
abstract final class FamilyDisputes {
  // =================================================================
  // §28-§29 — kardeşle para
  // =================================================================

  /// prototypeOnly: kardeşin "sıkıntıda" sayıldığı birikim eşiği.
  static const int prototypeOnlySiblingBrokeBelow = 50000;

  /// prototypeOnly: kardeşin para isteme ihtimalinin tabanı.
  static const double prototypeOnlySiblingAskChance = 0.10;

  /// prototypeOnly: ihtimalin üst sınırı.
  static const double prototypeOnlySiblingMaxChance = 0.24;

  /// prototypeOnly: aynı kardeşten iki istek arasındaki yıl (§46).
  static const int prototypeOnlySiblingCooldown = 5;

  /// prototypeOnly: kardeşin istediği tutar.
  static const int prototypeOnlySiblingAsk = 80000;

  /// prototypeOnly: oyuncunun kardeşinden isteyebileceği en çok tutar.
  static const int prototypeOnlyBorrowMax = 150000;

  /// prototypeOnly: kardeşin kendine ayırdığı pay — birikiminin bu
  /// kadarını vermez.
  ///
  /// "Uydurma milyonluk hesap açma": kardeş ancak kendi parasından
  /// verir ve hepsini vermez.
  static const double prototypeOnlySiblingKeepShare = 0.6;

  /// prototypeOnly: kardeşin kabul etmesi için gereken yakınlık.
  static const int prototypeOnlyBorrowBond = 40;

  static String siblingAskKey(String personId) => 'kardes-para:$personId';
  static String borrowKey(String personId) => 'kardes-borc:$personId';

  /// Kardeş gerçekten sıkıntıda mı?
  static bool siblingInTrouble(Person sibling) {
    final PersonDevelopment? gelisim = sibling.development;
    if (gelisim == null) return false;
    if (sibling.age < 20) return false;
    if (gelisim.isStudent) return false;
    if (gelisim.isEmployed) return false;
    return gelisim.money < prototypeOnlySiblingBrokeBelow;
  }

  /// Para isteyebilecek kardeşler.
  static Iterable<Person> siblingCandidates(GameState state) =>
      state.people.where((Person p) =>
          p.isAlive &&
          (p.relation == RelationType.kardes ||
              p.relation == RelationType.uveyKardes ||
              p.relation == RelationType.yariKardes) &&
          siblingInTrouble(p));

  /// Bu yıl bir kardeş para ister mi?
  static ({GameState state, PendingNotice? notice}) maybeSiblingAsk(
    GameState state,
    int newAge,
    Random rng,
  ) {
    if (!state.canOpenFamilyDecision) return (state: state, notice: null);
    final double ihtimal = state.familyDrama.scale(
      prototypeOnlySiblingAskChance,
      FamilyDramaArea.kardes,
      cap: prototypeOnlySiblingMaxChance,
    );
    for (final Person kardes in siblingCandidates(state)) {
      final int? son = state.lastInteractionAge[siblingAskKey(kardes.id)];
      if (son != null && newAge - son < prototypeOnlySiblingCooldown) {
        continue;
      }
      if (state.openFamilyIssueFor(kardes.id, FamilyIssueKind.kardesPara) !=
          null) {
        continue;
      }
      if (!rng.chance(ihtimal)) continue;

      final GameState acik = state.openFamilyIssue(
        kind: FamilyIssueKind.kardesPara,
        personId: kardes.id,
      );
      if (acik.familyIssues.length == state.familyIssues.length) {
        return (state: state, notice: null);
      }
      final String metin = '${kardes.firstName} para sıkıntısında; '
          '${prototypeOnlySiblingAsk ~/ 1000} bin ₺ borç istiyor.';
      final GameState next = acik.copyWith(
        lastInteractionAge: <String, int>{
          ...acik.lastInteractionAge,
          siblingAskKey(kardes.id): newAge,
        },
        log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
          ...acik.log,
          LifeLogEntry(age: newAge, text: metin, category: LogCategory.aile),
        ]),
      );
      return (
        state: next,
        notice: PendingNotice(
          id: 'kardes-para-${kardes.id}-$newAge',
          kind: NoticeKind.aileDonum,
          age: newAge,
          title: 'Kardeşin para istiyor',
          text: metin,
          personId: kardes.id,
        ),
      );
    }
    return (state: state, notice: null);
  }

  /// Oyuncuya sorulmayı bekleyen kardeş para isteği.
  static FamilyIssue? pendingSiblingAsk(GameState state) {
    for (final FamilyIssue mesele in state.familyIssues) {
      if (!mesele.isOpen) continue;
      if (mesele.kind != FamilyIssueKind.kardesPara) continue;
      if (mesele.response != null) continue;
      return mesele;
    }
    return null;
  }

  /// Bu cevap neden seçilemiyor; seçilebiliyorsa `null` (D-095).
  static String? siblingAskBlockReason(
    GameState state,
    FamilyIssueResponse cevap,
  ) {
    if (cevap != FamilyIssueResponse.paraVerdi) return null;
    if (state.player.wallet < prototypeOnlySiblingAsk) {
      return '${prototypeOnlySiblingAsk ~/ 1000} bin ₺ gerekiyor; '
          'cüzdanında o kadar yok.';
    }
    return null;
  }

  /// Oyuncu kardeşin para isteğine cevap verdi.
  ///
  /// Para cüzdandan düşer ve kardeşin kaydına eklenir: toplam değişmez.
  static ({GameState state, String text}) respondSiblingAsk(
    GameState state,
    FamilyIssueResponse cevap,
  ) {
    final FamilyIssue? mesele = pendingSiblingAsk(state);
    if (mesele == null) return (state: state, text: '');
    final String? engel = siblingAskBlockReason(state, cevap);
    if (engel != null) return (state: state, text: engel);
    final Person? kardes = state.personById(mesele.personId);
    if (kardes == null) {
      return (
        state: state.updateFamilyIssue(
          mesele.id,
          status: FamilyIssueStatus.kapandi,
          resolvedAtAge: state.player.age,
        ),
        text: '',
      );
    }

    final int tutar =
        cevap == FamilyIssueResponse.paraVerdi ? prototypeOnlySiblingAsk : 0;
    GameState next = _transfer(state, kardes.id, tutar);

    final int bagDegisimi = switch (cevap) {
      FamilyIssueResponse.paraVerdi => 5,
      FamilyIssueResponse.destekOldu => 2,
      FamilyIssueResponse.konustu => 0,
      FamilyIssueResponse.karismadi => -3,
      FamilyIssueResponse.reddetti => -6,
    };
    next = _bumpBond(next, kardes.id, bagDegisimi);

    final String metin = switch (cevap) {
      FamilyIssueResponse.paraVerdi =>
        '${kardes.firstName}\'e istediği parayı verdin.',
      FamilyIssueResponse.destekOldu =>
        '${kardes.firstName}\'e para vermedin ama iş bulmasına yardım '
            'ettin.',
      FamilyIssueResponse.konustu =>
        '${kardes.firstName} ile konuştun; para konusunu açmadın.',
      FamilyIssueResponse.karismadi =>
        '${kardes.firstName}\'in isteğini cevapsız bıraktın.',
      FamilyIssueResponse.reddetti =>
        '${kardes.firstName}\'e para vermeyeceğini söyledin.',
    };

    next = next.updateFamilyIssue(
      mesele.id,
      response: cevap,
      lastEventAge: next.player.age,
      status: FamilyIssueStatus.cozuldu,
      resolvedAtAge: next.player.age,
    );
    return (state: _log(next, metin), text: metin);
  }

  /// Oyuncu kardeşinden borç isteyebilir mi; isteyemiyorsa gerekçesi.
  ///
  /// **Kardeş her zaman evet demez (§29).** Burada yalnızca isteğin
  /// yapılabilirliği var; cevap [borrowFromSibling] içinde belirlenir.
  static String? borrowBlockReason(GameState state, String personId) {
    final Person? kardes = state.personById(personId);
    if (kardes == null) return 'Böyle bir kişi yok.';
    if (!kardes.isAlive) return '${kardes.firstName} hayatta değil.';
    if (kardes.relation != RelationType.kardes &&
        kardes.relation != RelationType.uveyKardes &&
        kardes.relation != RelationType.yariKardes) {
      return 'Bu yalnızca kardeşin için.';
    }
    final int? son = state.lastInteractionAge[borrowKey(personId)];
    if (son != null &&
        state.player.age - son < prototypeOnlySiblingCooldown) {
      return '${kardes.firstName}\'den yakın zamanda borç istedin; '
          'üst üste olmaz.';
    }
    return null;
  }

  /// Kardeşin verebileceği en çok para.
  ///
  /// Kendi kaydındaki paradan, kendine ayırdığı payı çıkararak. Kaydı
  /// olmayan kardeş para veremez: uydurma hesap açılmaz.
  static int siblingLendCapacity(Person sibling) {
    final PersonDevelopment? gelisim = sibling.development;
    if (gelisim == null) return 0;
    final int verilebilir =
        (gelisim.money * (1 - prototypeOnlySiblingKeepShare)).floor();
    if (verilebilir <= 0) return 0;
    return verilebilir > prototypeOnlyBorrowMax
        ? prototypeOnlyBorrowMax
        : verilebilir;
  }

  /// Oyuncu kardeşinden borç ister.
  ///
  /// Kabul garanti değil: yakınlık eşiğin altındaysa reddediliyor,
  /// üstündeyse de zar atılıyor. Verilen para kardeşin kaydından
  /// düşüp oyuncunun cüzdanına geçiyor — yeni para doğmuyor.
  static ({GameState state, String text, bool accepted}) borrowFromSibling(
    GameState state,
    String personId,
    Random rng,
  ) {
    final String? engel = borrowBlockReason(state, personId);
    if (engel != null) {
      return (state: state, text: engel, accepted: false);
    }
    final Person kardes = state.personById(personId)!;
    final int kapasite = siblingLendCapacity(kardes);

    GameState next = state.copyWith(
      lastInteractionAge: <String, int>{
        ...state.lastInteractionAge,
        borrowKey(personId): state.player.age,
      },
    );

    if (kapasite <= 0) {
      const String metin0 = 'Kardeşinin de durumu iyi değil; '
          'verebileceği bir şey yok.';
      return (state: _log(next, metin0), text: metin0, accepted: false);
    }
    if (kardes.bond < prototypeOnlyBorrowBond) {
      final String metin1 = '${kardes.firstName} "şu an olmaz" dedi. '
          'Aranız zaten mesafeliydi.';
      next = _bumpBond(next, personId, -2);
      return (state: _log(next, metin1), text: metin1, accepted: false);
    }

    // Yakınlık arttıkça kabul ihtimali artıyor ama garanti olmuyor.
    final int sans = (30 + kardes.bond ~/ 2).clamp(30, 85);
    if (rng.nextInt(100) >= sans) {
      final String metin2 = '${kardes.firstName} uzun uzun anlattı: '
          'kendi borçları varmış. Bu kez olmadı.';
      return (state: _log(next, metin2), text: metin2, accepted: false);
    }

    next = _transfer(next, personId, -kapasite);
    next = _bumpBond(next, personId, -3);
    final String metin = '${kardes.firstName} ${kapasite ~/ 1000} bin ₺ '
        'verdi. "Acele etmene gerek yok" dedi.';
    return (state: _log(next, metin), text: metin, accepted: true);
  }

  // =================================================================
  // §30-§32 — yaşlı ebeveynin bakımı
  // =================================================================

  /// prototypeOnly: ebeveynin bakıma ihtiyaç duyduğu yaş.
  static const int prototypeOnlyCareAge = 76;

  /// prototypeOnly: bakım meselesinin yıllık taban ihtimali.
  static const double prototypeOnlyCareChance = 0.16;

  /// prototypeOnly: oyuncunun bakımı üstlenmesi için gereken yıllık para.
  static const int prototypeOnlyCareCost = 96000;

  /// prototypeOnly: ücretli bakıma katkı payı.
  static const int prototypeOnlyCareShare = 48000;

  /// Bakıma ihtiyacı olan ebeveyn; yoksa `null`.
  static Person? parentNeedingCare(GameState state) {
    for (final Person p in state.people) {
      if (!p.isAlive) continue;
      if (p.relation != RelationType.anne && p.relation != RelationType.baba) {
        continue;
      }
      if (p.age < prototypeOnlyCareAge) continue;
      return p;
    }
    return null;
  }

  /// Bakımı paylaşabilecek kardeşler.
  static List<Person> careSiblings(GameState state) => state.people
      .where((Person p) =>
          p.isAlive &&
          p.age >= 20 &&
          (p.relation == RelationType.kardes ||
              p.relation == RelationType.yariKardes))
      .toList(growable: false);

  /// Bu yıl bakım meselesi açar.
  static ({GameState state, PendingNotice? notice}) maybeCareDispute(
    GameState state,
    int newAge,
    Random rng,
  ) {
    if (!state.canOpenFamilyDecision) return (state: state, notice: null);
    final Person? ebeveyn = parentNeedingCare(state);
    if (ebeveyn == null) return (state: state, notice: null);
    if (state.openFamilyIssueFor(ebeveyn.id, FamilyIssueKind.bakim) != null) {
      return (state: state, notice: null);
    }
    // Zaten çözülmüş bir bakım meselesi varsa tekrar açılmaz.
    final bool dahaOnce = state.familyIssues.any((FamilyIssue m) =>
        m.kind == FamilyIssueKind.bakim && m.personId == ebeveyn.id);
    if (dahaOnce) return (state: state, notice: null);

    final double ihtimal = state.familyDrama.scale(
      prototypeOnlyCareChance,
      FamilyDramaArea.bakim,
      cap: 0.35,
    );
    if (!rng.chance(ihtimal)) return (state: state, notice: null);

    final GameState acik = state.openFamilyIssue(
      kind: FamilyIssueKind.bakim,
      personId: ebeveyn.id,
    );
    if (acik.familyIssues.length == state.familyIssues.length) {
      return (state: state, notice: null);
    }

    final int kardesSayisi = careSiblings(state).length;
    final String metin = kardesSayisi > 0
        ? '${ebeveyn.firstName} artık tek başına idare edemiyor. '
            'Kardeşlerinle "kim bakacak" konusunu konuşmanız gerekiyor.'
        : '${ebeveyn.firstName} artık tek başına idare edemiyor. '
            'Bu meselede yanında kimse yok.';
    final GameState next = _log(acik, metin);
    return (
      state: next,
      notice: PendingNotice(
        id: 'bakim-${ebeveyn.id}-$newAge',
        kind: NoticeKind.aileDonum,
        age: newAge,
        title: 'Bakım meselesi',
        text: metin,
        personId: ebeveyn.id,
      ),
    );
  }

  /// Oyuncuya sorulmayı bekleyen bakım meselesi.
  static FamilyIssue? pendingCareDispute(GameState state) {
    for (final FamilyIssue mesele in state.familyIssues) {
      if (!mesele.isOpen) continue;
      if (mesele.kind != FamilyIssueKind.bakim) continue;
      if (mesele.response != null) continue;
      return mesele;
    }
    return null;
  }

  /// Bu cevap neden seçilemiyor; seçilebiliyorsa `null`.
  ///
  /// §31: "ben bakarım" demek gerçek kapasite istiyor. Kapasitesi
  /// olmayan oyuncuya seçenek **gerekçesiyle** kapalı, sessizce
  /// kaybolmuyor (D-095).
  static String? careBlockReason(
    GameState state,
    FamilyIssueResponse cevap,
  ) {
    switch (cevap) {
      case FamilyIssueResponse.destekOldu:
        if (state.player.wallet < prototypeOnlyCareCost) {
          return 'Bakımı üstlenmek yılda '
              '${prototypeOnlyCareCost ~/ 1000} bin ₺ demek; '
              'cüzdanında o kadar yok.';
        }
        return null;
      case FamilyIssueResponse.paraVerdi:
        if (state.player.wallet < prototypeOnlyCareShare) {
          return 'Ücretli bakıma katkı '
              '${prototypeOnlyCareShare ~/ 1000} bin ₺; cüzdanında o '
              'kadar yok.';
        }
        return null;
      default:
        return null;
    }
  }

  /// Oyuncu bakım meselesinde kararını verdi.
  static ({GameState state, String text}) respondCare(
    GameState state,
    FamilyIssueResponse cevap,
  ) {
    final FamilyIssue? mesele = pendingCareDispute(state);
    if (mesele == null) return (state: state, text: '');
    final String? engel = careBlockReason(state, cevap);
    if (engel != null) return (state: state, text: engel);
    final Person? ebeveyn = state.personById(mesele.personId);
    if (ebeveyn == null) {
      return (
        state: state.updateFamilyIssue(
          mesele.id,
          status: FamilyIssueStatus.kapandi,
          resolvedAtAge: state.player.age,
        ),
        text: '',
      );
    }

    final int maliyet = switch (cevap) {
      FamilyIssueResponse.destekOldu => prototypeOnlyCareCost,
      FamilyIssueResponse.paraVerdi => prototypeOnlyCareShare,
      _ => 0,
    };
    GameState next = state;
    if (maliyet > 0) {
      next = next.copyWith(
        player: next.player.copyWith(
          wallet: next.player.wallet - maliyet,
        ),
      );
    }

    // Ebeveynle ve kardeşlerle bağ ayrı ayrı değişiyor: bakımı üstlenmek
    // ebeveyni yakınlaştırıyor, yükü kardeşe bırakmak kardeşi
    // uzaklaştırıyor. Kardeşler otomatik olarak küsmüyor (§33): yalnızca
    // yakınlık değişiyor.
    final int ebeveynEtkisi = switch (cevap) {
      FamilyIssueResponse.destekOldu => 8,
      FamilyIssueResponse.paraVerdi => 4,
      FamilyIssueResponse.konustu => 0,
      FamilyIssueResponse.karismadi => -5,
      FamilyIssueResponse.reddetti => -8,
    };
    final int kardesEtkisi = switch (cevap) {
      FamilyIssueResponse.destekOldu => 3,
      FamilyIssueResponse.paraVerdi => 1,
      FamilyIssueResponse.konustu => 0,
      FamilyIssueResponse.karismadi => -4,
      FamilyIssueResponse.reddetti => -6,
    };
    next = _bumpBond(next, ebeveyn.id, ebeveynEtkisi);
    for (final Person kardes in careSiblings(next)) {
      next = _bumpBond(next, kardes.id, kardesEtkisi);
    }

    final String metin = switch (cevap) {
      FamilyIssueResponse.destekOldu =>
        '${ebeveyn.firstName}\'in bakımını üstlendin.',
      FamilyIssueResponse.paraVerdi =>
        '${ebeveyn.firstName} için ücretli bakıma katkı vermeyi kabul '
            'ettin.',
      FamilyIssueResponse.konustu =>
        'Kardeşlerinle konuştun ama bir karar çıkmadı.',
      FamilyIssueResponse.karismadi =>
        'Bakım meselesine karışmadın; yük kardeşlerinde kaldı.',
      FamilyIssueResponse.reddetti =>
        'Bakımı üstlenemeyeceğini açıkça söyledin.',
    };

    next = next.updateFamilyIssue(
      mesele.id,
      response: cevap,
      lastEventAge: next.player.age,
      status: FamilyIssueStatus.cozuldu,
      resolvedAtAge: next.player.age,
    );
    return (state: _log(next, metin), text: metin);
  }

  // =================================================================
  // §35-§36 — miras anlaşmazlığı
  // =================================================================

  /// prototypeOnly: anlaşmazlığın çıkma ihtimali.
  static const double prototypeOnlyEstateDisputeChance = 0.22;

  /// prototypeOnly: kardeşin itiraz ettiği pay.
  static const double prototypeOnlyContestedShare = 0.3;

  /// Bir miras kapandıktan sonra kardeş itiraz eder mi?
  ///
  /// Mesele **kardeşin** kimliğine açılıyor; itirazın tutarı o yıl
  /// oyuncunun eline geçen paradan türetiliyor.
  static ({GameState state, PendingNotice? notice}) maybeEstateDispute(
    GameState state,
    int newAge,
    Random rng, {
    required int inheritedThisYear,
  }) {
    if (inheritedThisYear <= 0) return (state: state, notice: null);
    if (!state.canOpenFamilyDecision) return (state: state, notice: null);
    final List<Person> kardesler = careSiblings(state);
    if (kardesler.isEmpty) return (state: state, notice: null);
    final double ihtimal = state.familyDrama.scale(
      prototypeOnlyEstateDisputeChance,
      FamilyDramaArea.kardes,
      cap: 0.45,
    );
    if (!rng.chance(ihtimal)) return (state: state, notice: null);

    final Person kardes = rng.pick(kardesler);
    if (state.openFamilyIssueFor(kardes.id, FamilyIssueKind.miras) != null) {
      return (state: state, notice: null);
    }
    final GameState acik = state.openFamilyIssue(
      kind: FamilyIssueKind.miras,
      personId: kardes.id,
    );
    if (acik.familyIssues.length == state.familyIssues.length) {
      return (state: state, notice: null);
    }
    final int itirazTutari = _contested(inheritedThisYear);
    final String metin = '${kardes.firstName} mirasın paylaşımına itiraz '
        'ediyor: ${itirazTutari ~/ 1000} bin ₺ hakkı olduğunu söylüyor.';
    // İtiraz tutarı meselenin `stage` alanında bin TL olarak taşınıyor:
    // yeni bir kayıt alanı açmak gerekmedi.
    final GameState next = acik.updateFamilyIssue(
      acik.familyIssues.last.id,
      stage: itirazTutari ~/ 1000,
    );
    return (
      state: _log(next, metin),
      notice: PendingNotice(
        id: 'miras-itiraz-${kardes.id}-$newAge',
        kind: NoticeKind.aileDonum,
        age: newAge,
        title: 'Miras anlaşmazlığı',
        text: metin,
        personId: kardes.id,
      ),
    );
  }

  static int _contested(int inherited) {
    final int tutar = (inherited * prototypeOnlyContestedShare).round();
    return tutar < 1000 ? 1000 : tutar;
  }

  /// Oyuncuya sorulmayı bekleyen miras anlaşmazlığı.
  static FamilyIssue? pendingEstateDispute(GameState state) {
    for (final FamilyIssue mesele in state.familyIssues) {
      if (!mesele.isOpen) continue;
      if (mesele.kind != FamilyIssueKind.miras) continue;
      if (mesele.response != null) continue;
      return mesele;
    }
    return null;
  }

  /// İtiraz edilen tutar (mesele kaydından okunur).
  static int contestedAmount(GameState state) {
    final FamilyIssue? mesele = pendingEstateDispute(state);
    if (mesele == null) return 0;
    return mesele.stage * 1000;
  }

  /// Oyuncu miras anlaşmazlığında kararını verdi.
  ///
  /// **§36: miras ikinci kez üretilmiyor.** Kabul edilirse para
  /// oyuncunun cüzdanından kardeşin kaydına **taşınır**; hiçbir yerde
  /// yeni para doğmaz. Cüzdanda o kadar yoksa seçenek gerekçesiyle
  /// kapalıdır.
  static String? estateBlockReason(
    GameState state,
    FamilyIssueResponse cevap,
  ) {
    if (cevap != FamilyIssueResponse.paraVerdi) return null;
    final int tutar = contestedAmount(state);
    if (state.player.wallet < tutar) {
      return 'İtiraz edilen ${tutar ~/ 1000} bin ₺ şu an cüzdanında yok.';
    }
    return null;
  }

  static ({GameState state, String text}) respondEstateDispute(
    GameState state,
    FamilyIssueResponse cevap,
  ) {
    final FamilyIssue? mesele = pendingEstateDispute(state);
    if (mesele == null) return (state: state, text: '');
    final String? engel = estateBlockReason(state, cevap);
    if (engel != null) return (state: state, text: engel);
    final Person? kardes = state.personById(mesele.personId);
    if (kardes == null) {
      return (
        state: state.updateFamilyIssue(
          mesele.id,
          status: FamilyIssueStatus.kapandi,
          resolvedAtAge: state.player.age,
        ),
        text: '',
      );
    }

    final int tutar =
        cevap == FamilyIssueResponse.paraVerdi ? contestedAmount(state) : 0;
    GameState next = _transfer(state, kardes.id, tutar);

    final int bagDegisimi = switch (cevap) {
      FamilyIssueResponse.paraVerdi => 6,
      FamilyIssueResponse.destekOldu => 2,
      FamilyIssueResponse.konustu => -1,
      FamilyIssueResponse.karismadi => -5,
      FamilyIssueResponse.reddetti => -10,
    };
    next = _bumpBond(next, kardes.id, bagDegisimi);

    final String metin = switch (cevap) {
      FamilyIssueResponse.paraVerdi =>
        '${kardes.firstName}\'in itiraz ettiği payı verdin; mesele '
            'kapandı.',
      FamilyIssueResponse.destekOldu =>
        '${kardes.firstName} ile oturup hesabı baştan konuştunuz.',
      FamilyIssueResponse.konustu =>
        '${kardes.firstName} ile konuştun ama anlaşamadınız.',
      FamilyIssueResponse.karismadi =>
        '${kardes.firstName}\'in itirazına cevap vermedin.',
      FamilyIssueResponse.reddetti =>
        '${kardes.firstName}\'e hakkı olmadığını söyledin.',
    };

    next = next.updateFamilyIssue(
      mesele.id,
      response: cevap,
      lastEventAge: next.player.age,
      status: FamilyIssueStatus.cozuldu,
      resolvedAtAge: next.player.age,
    );
    return (state: _log(next, metin), text: metin);
  }

  // =================================================================
  // Yardımcılar
  // =================================================================

  /// Oyuncunun cüzdanından [personId] kaydına [amount] taşır.
  ///
  /// Negatif [amount] ters yöne taşır. Kaydı olmayan kişiye para
  /// yazılmaz ama cüzdandan da çıkmaz: para hiçbir yerde kaybolmaz ve
  /// hiçbir yerde doğmaz.
  static GameState _transfer(GameState state, String personId, int amount) {
    if (amount == 0) return state;
    final Person? kisi = state.personById(personId);
    if (kisi?.development == null) return state;
    return state.copyWith(
      player: state.player.copyWith(
        wallet: state.player.wallet - amount,
      ),
      people: List<Person>.unmodifiable(<Person>[
        for (final Person p in state.people)
          if (p.id == personId && p.development != null)
            p.copyWith(
              development: p.development!.copyWith(
                money: p.development!.money + amount,
              ),
            )
          else
            p,
      ]),
    );
  }

  static GameState _bumpBond(GameState state, String personId, int delta) {
    if (delta == 0) return state;
    return state.copyWith(
      people: List<Person>.unmodifiable(<Person>[
        for (final Person p in state.people)
          if (p.id == personId)
            p.copyWith(bond: (p.bond + delta).clamp(0, 100))
          else
            p,
      ]),
    );
  }

  static GameState _log(GameState state, String text) => state.copyWith(
        log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
          ...state.log,
          LifeLogEntry(
            age: state.player.age,
            text: text,
            category: LogCategory.aile,
          ),
        ]),
      );
}
