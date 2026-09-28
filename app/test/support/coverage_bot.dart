// Paket AI — CoverageBot.
//
// **Bu bot hayatı temsil etmiyor.** `PlayerBot` gerçek oyuncunun neyi ne
// sıklıkta yaptığını ölçer ve öyle kalmalı; bu bot ise oyuncunun
// yapabildiği **her şeye en az bir kez dokunmaya** çalışır. İkisinin
// görevi ayrı: "bot bunu normalde seçmedi" bir test sonucu değildir.
//
// Kurallar (AI §27):
//
// * `debugSetState` ile para, stat, eğitim, meslek, ilişki, işletme,
//   ehliyet ya da ün **verilmez**. Bot her şeyi oyuncunun gerçek
//   yollarından yapar.
// * Test süresini kısaltmak için hedefli tohum ve hedefli yaşam
//   politikası kullanılabilir — bu hile değil, oyuncunun bilinçli bir
//   hayat sürmesidir.
//
// Her çağrı `ActionLog` üzerinden geçer: "hangi aksiyon gerçekten
// çalıştı" sorusu tahminle değil kayıtla cevaplanır.
library;

import 'dart:math';

import 'package:bir_omur/data/activity_catalog.dart';
import 'package:bir_omur/data/business_catalog.dart';
import 'package:bir_omur/data/celebrity_catalog.dart';
import 'package:bir_omur/data/education_tracks.dart';
import 'package:bir_omur/data/finger_catalog.dart';
import 'package:bir_omur/data/gift_catalog.dart';
import 'package:bir_omur/data/item_catalog.dart';
import 'package:bir_omur/data/investment_catalog.dart';
import 'package:bir_omur/data/job_catalog.dart';
import 'package:bir_omur/data/lawyer_catalog.dart';
import 'package:bir_omur/data/martial_arts_catalog.dart';
import 'package:bir_omur/data/media_catalog.dart';
import 'package:bir_omur/domain/models/hobby_progress.dart';
import 'package:bir_omur/data/license_catalog.dart';
import 'package:bir_omur/data/military_catalog.dart';
import 'package:bir_omur/data/pet_catalog.dart';
import 'package:bir_omur/data/shop_catalog.dart';
import 'package:bir_omur/data/social_catalog.dart';
import 'package:bir_omur/data/tour_catalog.dart';
import 'package:bir_omur/data/university_catalog.dart';
import 'package:bir_omur/data/wedding_catalog.dart';
import 'package:bir_omur/domain/casino/roulette.dart';
import 'package:bir_omur/domain/economy/business_engine.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/interaction/intimacy.dart';
import 'package:bir_omur/domain/law/prison_life.dart';
import 'package:bir_omur/domain/life/notices.dart';
import 'package:bir_omur/domain/models/business.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/interaction.dart';
import 'package:bir_omur/domain/models/loan.dart';
import 'package:bir_omur/domain/models/owned_item.dart';
import 'package:bir_omur/domain/models/pending_crisis.dart';
import 'package:bir_omur/domain/models/pending_trial.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/rental.dart';
import 'package:bir_omur/domain/models/trip.dart';
import 'package:bir_omur/domain/pets/pet_care.dart';
import 'package:bir_omur/domain/social/celebrity_engine.dart';
import 'package:bir_omur/data/health_crisis_catalog.dart';
import 'package:bir_omur/data/lottery_catalog.dart';
import 'package:bir_omur/domain/activities/activity_engine.dart';
import 'package:bir_omur/domain/career/job_market.dart';
import 'package:bir_omur/domain/casino/horse_race.dart';
import 'package:bir_omur/domain/economy/banking.dart';
import 'package:bir_omur/domain/economy/investment_engine.dart';
import 'package:bir_omur/domain/economy/property_market.dart';
import 'package:bir_omur/domain/economy/used_vehicle_market.dart';
import 'package:bir_omur/domain/education/education_path.dart';
import 'package:bir_omur/domain/interaction/item_actions.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/models/investment.dart';
import 'package:bir_omur/domain/social/social_engine.dart';
import 'package:bir_omur/state/game_controller.dart';

import 'action_inventory.dart';

/// Hedefli hayat politikaları. Her biri belli bir sistemin koşullarını
/// oluşturmaya çalışır; hepsi birlikte kataloğu tarar.
enum CoveragePlan {
  /// Kumar masalarını açan, bahis yapan hayat.
  kumarbaz,

  /// Sosyal medya, ün, sponsor, ünlü, medya işi.
  sosyalci,

  /// Kütüphane, kitap, hobi, kurs, dövüş sanatı.
  okuyucu,

  /// Ev, kira, kiracı, bakım, taşınma.
  evSahibi,

  /// İşletme kurar ve yönetir.
  patron,

  /// Askerlik yollarını dener.
  asker,

  /// Evlilik, çocuk, boşanma, tekrar evlilik, cenaze, vasiyet.
  aileci,

  /// Evcil hayvan.
  hayvansever,

  /// Seyahat, tur, taşınma.
  gezgin,

  /// Araç, alışveriş, ikinci el.
  tuketici,
}

/// Bir kapsam hayatının sonucu.
class CoverageResult {
  CoverageResult(this.plan, this.seed);

  final CoveragePlan plan;
  final int seed;
  final ActionLog log = ActionLog();

  int deathAge = 0;
  bool endedByDeath = false;
  String? stuckReason;

  /// Dokunulan içerik (rapor için).
  final Set<String> businessTypes = <String>{};
  final Set<String> hobbies = <String>{};
  final Set<String> martialArts = <String>{};
  final Set<String> books = <String>{};
  final Set<String> jobIds = <String>{};
  final Set<String> programIds = <String>{};
  final Set<String> petSpecies = <String>{};
  final Set<String> socialPlatforms = <String>{};
  final Set<String> investmentTypes = <String>{};
  final Set<String> itemTypeIds = <String>{};
  final Set<String> cities = <String>{};
  final Set<String> eventChoices = <String>{};

  /// Aktivite kimliği → oyunun verdiği engel gerekçesi (son görülen).
  final Map<String, String> blockedActivities = <String, String>{};

  /// Gerçekten yapılan aktiviteler.
  final Set<String> performedActivities = <String>{};

  int maxIntelligence = 0;
  int maxCharisma = 0;
  int maxFame = 0;
  int finalNetWorth = 0;
}

/// Yılın bir bölümü.
typedef _CoverageStep = void Function(
  GameController c,
  CoveragePlan plan,
  Random rng,
  CoverageResult r,
  ActionLog log,
);

/// Yılın bölümleri, sırayla. Her biri ayrı bir adım: biri bildirim
/// üretirse ötekiler o yıl atlanmaz.
///
/// **Sıra önemli.** Yatırım ve alışveriş önce gelirse cüzdan boşalıyor
/// ve ₺3.200-16.000 arası kurslar "yeterli paran yok" diye kapanıyor;
/// ölçümde 12 hobinin 10'u hiç ilerlemiyordu. Gerçek oyuncu da önce
/// gününü yaşar, artanı yatırır.
const List<_CoverageStep> _adimlar = <_CoverageStep>[
  _education,
  _career,
  _books,
  _dailyActivities,
  _martial,
  _health,
  _relationships,
  _social,
  _extras,
  _bank,
  _invest,
  _shopping,
  _items,
  _housing,
  _business,
  _gambling,
];

/// Listedeki ilk uyan öğe ya da null.
extension _FirstOrNull<T> on Iterable<T> {
  T? firstOrNullCov(bool Function(T) test) {
    for (final T e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}

/// Bir kapsam hayatını doğumdan ölüme oynar.
CoverageResult runCoverageLife({
  required CoveragePlan plan,
  required int seed,
}) {
  final GameController c = GameController(random: Random(seed));
  c.startNewLife(mode: StartMode.tamamenRastgele, seed: seed);
  final Random rng = Random(seed * 7907 + plan.index * 90001 + 7);
  final CoverageResult r = CoverageResult(plan, seed);
  final ActionLog log = r.log;

  int islenenYas = -1;
  int adim = 0;
  int guard = 0;
  while (!c.state!.deceased && guard++ < 8000) {
    final GameState s = c.state!;
    r.cities.add(s.player.currentCity);
    if (s.player.stats.intelligence > r.maxIntelligence) {
      r.maxIntelligence = s.player.stats.intelligence;
    }
    if (s.player.stats.charisma > r.maxCharisma) {
      r.maxCharisma = s.player.stats.charisma;
    }
    final int unu = s.player.fame ?? 0;
    if (unu > r.maxFame) r.maxFame = unu;

    // ---- Bekleyenler -------------------------------------------------
    if (_handlePending(c, rng, r, log)) continue;
    if (r.stuckReason != null) break;

    // ---- Yılın eylemleri ---------------------------------------------
    //
    // **Adım adım ilerliyor.** İlk yazımda bütün bölümler tek blokta
    // çalışıyordu ve bir bölüm bildirim/olay ürettiğinde `continue`
    // sonrası yıl "işlenmiş" sayıldığı için geri kalan bölümler o yıl
    // hiç çalışmıyordu: 109 aksiyonun 92'si **hiç denenmiyordu**
    // (kapsam %15,6). Şimdi her bölüm kendi adımı; bekleyen karşılanınca
    // kaldığı yerden devam ediyor.
    if (islenenYas != s.player.age) {
      islenenYas = s.player.age;
      adim = 0;
    }
    if (adim < _adimlar.length) {
      final _CoverageStep bolum = _adimlar[adim++];
      bolum(c, plan, rng, r, log);
      continue;
    }

    final int onceki = c.state!.player.age;
    log('ageUp', () {
      c.ageUp();
      return true;
    }, uygulandi: (bool v) => c.state!.player.age != onceki);
    if (c.state!.player.age == onceki) {
      if (c.state!.hasNotice ||
          c.state!.hasPendingEvent ||
          c.state!.pendingCrisis != null ||
          c.state!.hasPendingTrial ||
          c.needsEducationChoice) {
        continue;
      }
      r.stuckReason = 'yas ilerlemedi';
      break;
    }
  }
  if (guard >= 8000) {
    final GameState son = c.state!;
    r.stuckReason ??= 'tur siniri('
        'yas=${son.player.age} '
        'bildirim=${son.hasNotice ? son.notices.first.kind.name : '-'} '
        'olay=${son.pendingEvent?.eventId ?? '-'} '
        'kriz=${son.pendingCrisis?.crisisId ?? '-'} '
        'durusma=${son.hasPendingTrial} '
        'mulakat=${son.pendingInterview != null} '
        'sinav=${c.pendingLicenseExam != null} '
        'dugun=${son.pendingWedding != null} '
        'egitim=${c.needsEducationChoice})';
  }
  r.deathAge = c.state!.player.age;
  r.endedByDeath = c.state!.deceased;
  r.finalNetWorth = c.state!.player.wallet;
  c.dispose();
  return r;
}

bool _kesildi(GameController c) =>
    c.state!.hasNotice || c.state!.hasPendingEvent;

/// Yalnızca **olay** akışı kesiyor mu?
///
/// Bildirim biriktirmek eylemleri engellemiyor (denetleyici çoğu yerde
/// `hasPendingEvent`e bakıyor). İlk yazımda aktivite döngüsü bildirimde
/// de duruyordu; her aktivite bir bildirim ürettiği için bot **yılda
/// tek aktivite** yapabiliyordu ve 12 hobinin yalnızca 2'si ilerliyordu.
bool _olayVar(GameController c) => c.state!.hasPendingEvent;

/// Bekleyen olay/kriz/duruşma/mülakat/sınav/bildirim. `true` dönerse ana
/// döngü baştan başlar.
bool _handlePending(
  GameController c,
  Random rng,
  CoverageResult r,
  ActionLog log,
) {
  final GameState s = c.state!;
  if (s.hasNotice) {
    // Cenaze kararı bildirimden çıkıyor.
    for (final FuneralChoice f in FuneralChoice.values) {
      if (c.canChooseFuneral(f)) {
        log('respondToFuneral', () => c.respondToFuneral(f));
        break;
      }
    }
    log('dismissNotice', () {
      c.dismissNotice();
      return true;
    }, uygulandi: (bool v) => true);
    return true;
  }
  if (s.pendingEvent != null) {
    // **Her seçenek kolu denensin (AI §22):** seçim sırayla dönüyor,
    // hep ilk seçenek işaretlenmiyor.
    final List<String> secenekler = <String>[
      for (final EventChoice o in s.pendingEvent!.choices) o.id,
    ];
    final String secim = secenekler.isEmpty
        ? ''
        : secenekler[rng.nextInt(secenekler.length)];
    r.eventChoices.add('${s.pendingEvent!.eventId}:$secim');
    log.outcome('chooseEventOption', () => c.chooseEventOption(secim));
    return true;
  }
  if (s.pendingCrisis != null) {
    final PendingCrisis kriz = s.pendingCrisis!;
    final HealthCrisis? bilgi = kriz.crisis;
    for (final CrisisChoice secenek in bilgi?.choices ?? const <CrisisChoice>[]) {
      if (c.canChooseCrisis(secenek)) {
        log.outcome('respondToCrisis', () => c.respondToCrisis(secenek.id));
        return true;
      }
    }
    // Karşılanabilir seçenek yoksa ilkini dene: kilit sayılır.
    if (bilgi != null && bilgi.choices.isNotEmpty) {
      log.outcome('respondToCrisis', () => c.respondToCrisis(bilgi.choices.first.id));
      return true;
    }
  }
  if (s.hasPendingTrial) {
    final LawyerTier avukatTier = kLawyerCatalog.firstOrNullCov(
            (LawyerTier t) => c.lawyerBlockReason(t).isEmpty) ??
        kLawyerCatalog.last;
    final String avukat = avukatTier.id;
    log('respondToTrial', () {
      c.respondToTrial(
        stance: DefenceStance.values[rng.nextInt(DefenceStance.values.length)],
        lawyerId: avukat,
      );
      return true;
    }, uygulandi: (bool v) => !c.state!.hasPendingTrial);
    return true;
  }
  if (s.pendingInterview != null) {
    // Mülakatın iki kolu da denensin: bazen iptal, çoğunlukla cevap.
    if (rng.nextDouble() < 0.12) {
      log.outcome('cancelInterview', () => c.cancelInterview());
    } else {
      log.outcome('answerInterview', () => c.answerInterview(rng.nextInt(3)));
    }
    return true;
  }
  if (c.pendingLicenseExam != null) {
    if (rng.nextDouble() < 0.08) {
      log.outcome('cancelLicenseExam', () => c.cancelLicenseExam());
      return true;
    }
    while (c.pendingLicenseExam != null) {
      final int dogru = c.pendingLicenseExam!.questions
          .elementAt(c.pendingLicenseExam!.answers.length)
          .correctIndex;
      log.outcome('answerLicenseExam', () => c.answerLicenseExam(dogru));
    }
    return true;
  }
  if (s.pendingWedding != null) {
    log('holdWedding',
        () => c.holdWedding(kWeddingStyles[rng.nextInt(kWeddingStyles.length)].id));
    return true;
  }
  if (c.needsEducationChoice) {
    // **Eğitim kapısı mutlaka kapanmalı.** Lise bitince oyun ya bir
    // bölüme yerleşmeyi ya da üniversiteyi boşvermeyi bekliyor; ikisi de
    // yapılmazsa `ageUp` ilerlemiyor ve hayat 18'de kilitleniyor.
    // (İlk yazımda `skipUniversity` yalnızca %10 ihtimalle deneniyordu
    // ve bütün kapsam hayatları 18 yaşında turu tüketiyordu.)
    final List<EducationTrackInfo> yollar = c.availableTracks();
    if (yollar.isNotEmpty) {
      final EducationTrack secilen = yollar[rng.nextInt(yollar.length)].track;
      log.outcome('chooseTrack', () => c.chooseTrack(secilen));
      if (!c.needsEducationChoice) return true;
    }
    final List<UniversityProgram> bolumler = c.availablePrograms();
    if (bolumler.isNotEmpty) {
      final UniversityProgram b = bolumler[r.seed % bolumler.length];
      final EducationOutcome? sonuc =
          log.outcome('applyToUniversity', () => c.applyToUniversity(b));
      // **`applied` kabul demek değil.** Reddedilen başvuru da
      // `applied: true` döner (işlem yapıldı, günlüğe yazıldı); yerleşme
      // `accepted` alanında. İlk yazımda bunu karıştırdım ve bot
      // reddedilen başvuruyu "oldu" sayıp eğitim kapısını hiç
      // kapatamadan 18 yaşında sonsuz döngüye girdi.
      if (sonuc?.accepted ?? false) {
        r.programIds.add(b.id);
        return true;
      }
    }
    final EducationOutcome? atla =
        log.outcome('skipUniversity', () => c.skipUniversity());
    if (c.needsEducationChoice) {
      // Üç yolun üçü de kapıyı kapatamadı: bu bir **oyun kilidi**
      // adayıdır, botun tembelliği değil. Hayatı burada bitirip
      // gerekçeyi taşıyoruz ki rapor bunu sayabilsin.
      r.stuckReason = 'egitim kapisi kapanmiyor '
          '(track=${c.availableTracks().length} '
          'bolum=${c.availablePrograms().length} '
          'skip=${atla?.applied} "${atla?.text ?? '-'}" '
          'yol=${c.state!.education.track?.name ?? '-'} puan=${c.state!.education.placementScore ?? -1} '
          'kayitli=${c.state!.education.enrolled} '
          'bitti=${c.state!.education.finished})';
      return false;
    }
    return true;
  }
  return false;
}

// =====================================================================
// Eğitim
// =====================================================================
void _education(
  GameController c,
  CoveragePlan plan,
  Random rng,
  CoverageResult r,
  ActionLog log,
) {
  if (c.studyAvailability().isAllowed) {
    log('study', () => c.study(), uygulandi: (String? v) => v != null);
  }
  final List<UniversityProgram> bolumler = c.availablePrograms();
  if (bolumler.isNotEmpty) {
    // Kapsam için bölümü **tohuma göre** seç: farklı hayatlar farklı
    // bölüm okusun, hep aynısı değil.
    final UniversityProgram b = bolumler[r.seed % bolumler.length];
    final EducationOutcome? sonuc =
        log.outcome('applyToUniversity', () => c.applyToUniversity(b));
    if (sonuc?.accepted ?? false) r.programIds.add(b.id);
  }
}

// =====================================================================
// Kariyer
// =====================================================================
void _career(
  GameController c,
  CoveragePlan plan,
  Random rng,
  CoverageResult r,
  ActionLog log,
) {
  final GameState s = c.state!;
  if (s.career.job == null) {
    final List<JobType> acik = c.openJobs();
    if (acik.isNotEmpty) {
      final JobType is_ = acik[rng.nextInt(acik.length)];
      final JobOutcome? sonuc = log.outcome('applyForJob', () => c.applyForJob(is_));
      if (sonuc?.applied ?? false) r.jobIds.add(is_.id);
    }
  } else {
    r.jobIds.add(s.career.jobId!);
    if (c.raiseAvailability().isAllowed) {
      log('askForRaise', () => c.askForRaise(),
          uygulandi: (String? v) => v != null);
    }
    if (c.promotionAvailability().isAllowed) {
      log('askForPromotion', () => c.askForPromotion(),
          uygulandi: (String? v) => v != null);
    }
    // İşten ayrılma da bir oyuncu hamlesi: ara sıra denensin.
    if (rng.nextDouble() < 0.06) {
      log('quitJob', () => c.quitJob());
    }
  }
  if (c.retirementAvailability().isAllowed && rng.nextDouble() < 0.5) {
    log('retire', () => c.retire(), uygulandi: (String? v) => v != null);
  }
  if (c.crewOfferAvailability().isAllowed) {
    if (rng.nextBool()) {
      log('acceptCrewOffer', () => c.acceptCrewOffer());
    } else {
      log('declineCrewOffer', () => c.declineCrewOffer());
    }
  }
}

// =====================================================================
// Para: banka, yatırım, ev/kira, işletme, alışveriş, kumar
// =====================================================================
void _bank(
  GameController c,
  CoveragePlan plan,
  Random rng,
  CoverageResult r,
  ActionLog log,
) {
  final GameState s = c.state!;
  if (s.player.age < 18) return;

  // ---- Kredi -------------------------------------------------------
  if (s.loans.isEmpty && rng.nextDouble() < 0.35) {
    final Bank banka = Bank.values[rng.nextInt(Bank.values.length)];
    final int tutar = 150000 + rng.nextInt(400000);
    log('previewLoanQuery', () => c.previewLoan(
          bank: banka,
          amount: tutar,
          termYears: 1 + rng.nextInt(3),
        ), uygulandi: (LoanDecision v) => true);
    log('applyForLoan', () => c.applyForLoan(
          bank: banka,
          amount: tutar,
          termYears: 1 + rng.nextInt(3),
          purpose: LoanPurpose.values[rng.nextInt(LoanPurpose.values.length)],
        ), uygulandi: (LoanDecision? v) => v?.approved ?? false);
  }
  for (final Loan k in c.state!.loans) {
    if (rng.nextDouble() < 0.3) {
      log('payOffLoan', () => c.payOffLoan(k.id),
          uygulandi: (String v) => !v.contains('yetmiyor'));
    }
  }

}

/// Kapsam botunun cüzdanında bıraktığı pay.
///
/// Yatırım ve alışveriş cüzdanı sonuna kadar boşaltınca ertesi yılın
/// ₺3.200-16.000'lik kursları "yeterli paran yok" diye kapanıyor ve 12
/// hobinin 10'u hiç ilerlemiyordu. Gerçek oyuncu da gündelik hayatına
/// bir pay ayırır.
const int kCoverageReserve = 250000;

void _invest(
  GameController c,
  CoveragePlan plan,
  Random rng,
  CoverageResult r,
  ActionLog log,
) {
  if (c.state!.player.age < 18) return;
  // **Okuyucu planı parasını yatırmaz.** Ücretli kurslara neden hiç
  // gidilemediğini ayırt etmek için bir kontrol grubu gerekiyordu:
  // bot mu parayı bitiriyor, yoksa kurslar normal bir hayatın
  // erişemeyeceği kadar mı pahalı?
  if (plan == CoveragePlan.okuyucu) return;
  if (c.state!.player.wallet <= kCoverageReserve) return;
  // **Her yatırım türüne dokun.** İlk yazımda ilk uygun türde `break`
  // vardı ve 60 hayatta yalnızca 1 tür deneniyordu.
  for (final InvestmentType t in kInvestmentTypes) {
    if (c.investmentBuyBlockReason(t, 20000).isEmpty) {
      final InvestmentOutcome? sonuc =
          log.outcome('buyInvestment', () => c.buyInvestment(t.id, 20000));
      if (sonuc?.applied ?? false) r.investmentTypes.add(t.id);
    }
  }
  if (c.state!.investments.isNotEmpty && rng.nextDouble() < 0.3) {
    final Holding h = c.state!.investments.first;
    final InvestmentType? tipi = investmentTypeById(h.typeId);
    if (tipi != null &&
        c.investmentSellBlockReason(tipi, h.value ~/ 2).isEmpty) {
      log.outcome('sellInvestment', () => c.sellInvestment(h.typeId, h.value ~/ 2));
    }
  }
  if (c.state!.termDeposits.isNotEmpty && rng.nextDouble() < 0.4) {
    log.outcome('breakTermDeposit', () => c.breakTermDeposit(c.state!.termDeposits.first.id));
  }

}

void _shopping(
  GameController c,
  CoveragePlan plan,
  Random rng,
  CoverageResult r,
  ActionLog log,
) {
  final GameState s = c.state!;
  if (plan == CoveragePlan.okuyucu) return;
  final int harcanabilir = s.player.wallet - kCoverageReserve;
  if (harcanabilir <= 0) return;
  if (plan == CoveragePlan.tuketici || rng.nextDouble() < 0.25) {
    final List<ShopProduct> urunler = shopProductsFor(s.player.age)
        .where((ShopProduct p) => p.price <= harcanabilir)
        .toList(growable: false);
    if (urunler.isNotEmpty) {
      final ShopProduct u = urunler[rng.nextInt(urunler.length)];
      final ItemOutcome? sonuc = log.outcome('buyProduct', () => c.buyProduct(u));
      if (sonuc?.applied ?? false) r.itemTypeIds.add(u.typeId);
    }
    // İkinci el araç ve emlak ilanları ayrı aksiyonlar.
    final List<UsedVehicleListing> ikinciEl = c.usedVehicleListings();
    final UsedVehicleListing? uygunArac = ikinciEl
        .firstOrNullCov((UsedVehicleListing l) => l.price <= c.state!.player.wallet);
    if (uygunArac != null) {
      log.outcome('buyUsedVehicle', () => c.buyUsedVehicle(uygunArac));
    }
    for (final ShopCategory kat in ShopCategory.values) {
      final List<PropertyListing> ilanlar = c.listings(kat);
      final PropertyListing? ucuz = ilanlar
          .firstOrNullCov((PropertyListing l) => l.price <= c.state!.player.wallet);
      if (ucuz != null) {
        log.outcome('buyListing', () => c.buyListing(ucuz));
        break;
      }
    }
  }

}

void _items(
  GameController c,
  CoveragePlan plan,
  Random rng,
  CoverageResult r,
  ActionLog log,
) {
  for (final OwnedItem i in c.state!.items) {
    final List<ItemActionKind> eylemler = c.itemActionsFor(i);
    if (eylemler.isNotEmpty && rng.nextDouble() < 0.5) {
      log('performItemAction',
          () => c.performItemAction(i.id, eylemler[rng.nextInt(eylemler.length)]));
    }
    final List<OwnedItem> aksesuarlar = c.compatibleAccessoriesFor(i);
    if (aksesuarlar.isNotEmpty) {
      log.outcome('attachAccessory', () => c.attachAccessory(i.id, aksesuarlar.first.id));
    }
    if (rng.nextDouble() < 0.05) {
      log.outcome('sellItem', () => c.sellItem(i.id));
      break;
    }
  }

}

void _housing(
  GameController c,
  CoveragePlan plan,
  Random rng,
  CoverageResult r,
  ActionLog log,
) {
  final GameState s = c.state!;
  for (final OwnedItem ev in s.properties) {
    if (c.moveBlockReason(ev).isEmpty && rng.nextDouble() < 0.3) {
      log.outcome('moveInto', () => c.moveInto(ev));
    }
    if (c.rentOutBlockReason(ev).isEmpty) {
      final int kira = c.marketRent(ev);
      final List<TenantRecord> adaylar = c.tenantCandidatesFor(ev, kira);
      if (adaylar.isNotEmpty) {
        log('signLease',
            () => c.signLease(home: ev, tenant: adaylar.first, yearlyRent: kira));
      }
    }
    final Lease? sozlesme = c.leaseOf(ev);
    if (sozlesme != null) {
      if (rng.nextDouble() < 0.2) {
        log.outcome('renewLease', () => c.renewLease(ev, (c.marketRent(ev) * 1.05).round()));
      } else if (rng.nextDouble() < 0.1) {
        log.outcome('endLease', () => c.endLease(ev));
      }
    }
    for (final bool buyuk in <bool>[false, true]) {
      if (c.upkeepBlockReason(ev, major: buyuk).isEmpty &&
          rng.nextDouble() < 0.35) {
        log.outcome('upkeepProperty', () => c.upkeepProperty(ev, major: buyuk));
      }
    }
  }
  if (rng.nextDouble() < 0.06) {
    log.outcome('moveToRental', () => c.moveToRental());
  }
  if (rng.nextDouble() < 0.04) {
    log.outcome('moveBackToFamily', () => c.moveBackToFamily());
  }
  if ((plan == CoveragePlan.gezgin || rng.nextDouble() < 0.05) &&
      c.relocationTargets().isNotEmpty) {
    log('relocate',
        () => c.relocate(city: c.relocationTargets().first),
        uygulandi: (String v) => v.isNotEmpty);
  }
}

void _business(
  GameController c,
  CoveragePlan plan,
  Random rng,
  CoverageResult r,
  ActionLog log,
) {
  final GameState s = c.state!;
  if (s.businesses.where((Business b) => b.isOpen).isEmpty) {
    // Hedef tür: plan patronsa kataloğu tohuma göre tara.
    final List<BusinessType> uygun = kBusinessCatalog
        .where((BusinessType t) =>
            c.businessOpenAvailability(t).isAllowed &&
            t.setupCost <= s.player.wallet)
        .toList(growable: false);
    if (uygun.isNotEmpty) {
      final BusinessType t = uygun[r.seed % uygun.length];
      final BusinessOutcome? sonuc =
          log.outcome('openBusinessOf', () => c.openBusinessOf(t));
      if (sonuc?.applied ?? false) r.businessTypes.add(t.id);
    }
  }
  if (c.state!.businesses.where((Business b) => b.isOpen).isEmpty) return;
  r.businessTypes.add(c.state!.businesses.first.typeId);
  if (c.businessTendAvailability().isAllowed) {
    log.outcome('tendBusiness', () => c.tendBusiness());
  }
  final int piyasa = c.businessMarketPrice();
  if (piyasa > 0) {
    final ({int min, int max}) bant = c.businessPriceRange();
    log('setBusinessPrice',
        () => c.setBusinessPrice((piyasa * (0.85 + rng.nextDouble() * 0.4))
            .round()
            .clamp(bant.min, bant.max)));
  }
  log('setBusinessAd',
      () => c.setBusinessAd(BusinessAd.values[rng.nextInt(BusinessAd.values.length)]));
  if (c.businessMaintenanceAvailability().isAllowed) {
    log.outcome('maintainBusiness', () => c.maintainBusiness());
  }
  for (final StaffAction h in StaffAction.values) {
    if (c.businessStaffAvailability(h).isAllowed) {
      log.outcome('businessStaff', () => c.businessStaff(h));
      break;
    }
  }
  final int koy = (c.state!.player.wallet * 0.2).round();
  if (koy > 0 && c.businessInvestAvailability(koy).isAllowed) {
    log.outcome('investInBusiness', () => c.investInBusiness(koy));
  }
  if (rng.nextDouble() < 0.04) {
    log.outcome('closeBusiness', () => c.closeBusiness());
  }
}

void _gambling(
  GameController c,
  CoveragePlan plan,
  Random rng,
  CoverageResult r,
  ActionLog log,
) {
  final bool kumarbaz = plan == CoveragePlan.kumarbaz;
  if (!kumarbaz && rng.nextDouble() > 0.15) return;
  if (!c.casinoAvailability().isAllowed) return;
  final List<int> adimlar = c.betSteps();
  if (adimlar.isEmpty) return;
  final int bahis = adimlar.first;

  // Blackjack: dağıt → kart çek / dur → eli kapat.
  if (c.betAvailability(bahis).isAllowed) {
    log.outcome('dealBlackjack', () => c.dealBlackjack(bahis));
    int tur = 0;
    while (c.state!.blackjack != null && tur++ < 8) {
      if (rng.nextBool()) {
        log.outcome('hitBlackjack', () => c.hitBlackjack());
      } else {
        log.outcome('standBlackjack', () => c.standBlackjack());
      }
      if (c.state!.blackjack?.settled ?? false) {
        log.outcome('closeBlackjackHand', () => c.closeBlackjackHand());
        break;
      }
    }
    if (c.state!.blackjack != null) {
      log.outcome('closeBlackjackHand', () => c.closeBlackjackHand());
    }
  }
  // Rulet: her bahis türü denensin.
  if (c.betAvailability(bahis).isAllowed) {
    final RouletteBetType tip =
        RouletteBetType.values[rng.nextInt(RouletteBetType.values.length)];
    log('spinRoulette',
        () => c.spinRoulette(tip, bahis, number: rng.nextInt(37)));
  }
  // At yarışı: saha kur → bahis → sonuçlandır.
  log('newRaceField', () => c.newRaceField(),
      uygulandi: (List<RaceHorse> v) => v.isNotEmpty);
  if (c.horseBetAvailability(bahis).isAllowed) {
    log.outcome('betOnHorse', () => c.betOnHorse(1 + rng.nextInt(4), bahis));
    log.outcome('settleRace', () => c.settleRace());
  }
  // Piyango: her çekiliş ve her pay denensin.
  for (final LotteryDraw cekilis in LotteryDraw.values) {
    for (final TicketShare pay in TicketShare.values) {
      if (c.lotteryAvailability(cekilis, pay).isAllowed) {
        log('buyLotteryTicket', () => c.buyLotteryTicket(cekilis, pay),
            uygulandi: (String? v) => v != null);
        return;
      }
    }
  }
}

// =====================================================================
// İlişkiler
// =====================================================================
void _relationships(
  GameController c,
  CoveragePlan plan,
  Random rng,
  CoverageResult r,
  ActionLog log,
) {
  GameState s = c.state!;
  final bool aileci = plan == CoveragePlan.aileci;

  // ---- Her kişiyle her etkileşim türü -------------------------------
  final List<Person> yasayanlar =
      s.people.where((Person p) => p.isAlive).toList(growable: false);
  for (final Person p in yasayanlar) {
    final List<InteractionKind> turler = c.availableKindsFor(p);
    for (final InteractionKind k in turler) {
      if (!c.availabilityFor(p, k).isAllowed) continue;
      if (k == InteractionKind.hediyeVer) {
        final List<GiftItem> hediyeler = c.giftOptionsFor(p.id);
        if (hediyeler.isEmpty) continue;
        final GiftItem h = hediyeler[rng.nextInt(hediyeler.length)];
        log('giftReactionPreviewQuery', () => c.giftReactionPreview(p.id, h),
            uygulandi: (Object? v) => true);
        log.outcome('interact', () => c.interact(p.id, k, giftId: h.id));
      } else {
        log.outcome('interact', () => c.interact(p.id, k));
      }
      if (_kesildi(c)) return;
      if (rng.nextDouble() < 0.6) break;
    }
    if (c.makeUpAvailability(p.id).isAllowed) {
      log.outcome('makeUp', () => c.makeUp(p.id));
    }
    if (c.closeFriendAvailability(p.id).isAllowed) {
      log.outcome('proposeCloseFriend', () => c.proposeCloseFriend(p.id));
    }
    if (c.askOutAvailability(p.id).isAllowed) {
      log.outcome('askOut', () => c.askOut(p.id));
    }
    if (c.officialAvailability(p.id).isAllowed) {
      log.outcome('makeRelationshipOfficial', () => c.makeRelationshipOfficial(p.id));
    }
    if (c.intimacyAvailability(p.id).isAllowed) {
      log('beIntimate',
          () => c.beIntimate(p.id, Protection.values[rng.nextInt(Protection.values.length)]));
    }
  }

  // ---- Finger --------------------------------------------------------
  s = c.state!;
  if (s.player.age >= 18) {
    log('setFingerIntent', () {
      c.setFingerIntent(FingerIntent.values[rng.nextInt(FingerIntent.values.length)]);
      return true;
    }, uygulandi: (bool v) => true);
    log('setFingerWealthFilter', () {
      c.setFingerWealthFilter(null);
      return true;
    }, uygulandi: (bool v) => true);
    log.outcome('saveFingerProfile', () => c.saveFingerProfile(
          bio: kFingerBios[rng.nextInt(kFingerBios.length)],
          interests: <String>[kFingerInterests.first],
        ));
    log('fillFingerDeck', () {
      c.fillFingerDeck();
      return true;
    }, uygulandi: (bool v) => c.state!.fingerDeck.isNotEmpty);
    if (rng.nextDouble() < 0.2) {
      log.outcome('buyFingerPremium', () => c.buyFingerPremium());
    }
    final List<FingerProfileLike> deste = <FingerProfileLike>[
      for (final dynamic p in c.state!.fingerDeck) FingerProfileLike(p.id as String),
    ];
    if (deste.isNotEmpty) {
      log.outcome('likeFingerProfile', () => c.likeFingerProfile(deste.first.id));
      if (deste.length > 1) {
        log.outcome('passFingerProfile', () => c.passFingerProfile(deste[1].id));
      }
    }
    for (final dynamic m in c.state!.fingerMatches) {
      log.outcome('meetFingerMatch', () => c.meetFingerMatch(m.id as String));
      break;
    }
  }

  // ---- Evlilik / çocuk ----------------------------------------------
  s = c.state!;
  final Person? sevgili = s.people.firstOrNullCov(
      (Person p) => p.isAlive && p.relation == RelationType.sevgili);
  if (sevgili != null) {
    if (c.proposalAvailability(sevgili.id).isAllowed) {
      log('propose',
          () => c.propose(sevgili.id, styleId: kProposalStyles[rng.nextInt(kProposalStyles.length)].id));
    }
    // **Önce teklif.** `marry` nikâhı kendi içinde bedava düğünle
    // kapatıyor; `holdWedding` ancak teklif kabul edilip bekleyen düğün
    // oluştuğunda çalışıyor. İlk yazımda bot hep `marry` çağırdığı için
    // düğün ekranı hiç açılmıyordu.
    if (c.state!.pendingWedding == null &&
        c.marriageAvailability(sevgili.id).isAllowed &&
        rng.nextDouble() < 0.3) {
      log.outcome('marry', () => c.marry(sevgili.id));
    }
    if (!aileci && rng.nextDouble() < 0.05) {
      log('endRomance', () => c.endRomance(sevgili.id),
          uygulandi: (String? v) => v != null);
    }
  }
  if (c.childAvailability().isAllowed && (aileci || rng.nextDouble() < 0.4)) {
    log.outcome('haveChild', () => c.haveChild());
  }
  if (c.adoptionAvailability().isAllowed && rng.nextDouble() < 0.3) {
    log.outcome('tryFertilityTreatment', () => c.tryFertilityTreatment());
  }
  if (c.divorceAvailability().isAllowed && rng.nextDouble() < 0.08) {
    log.outcome('divorce', () => c.divorce());
  }
  // Vasiyet: mirasçı seç ve temizle.
  if (c.willAvailability().isAllowed) {
    final Person? cocuk = c.state!.people
        .firstOrNullCov((Person p) => p.relation == RelationType.cocuk && p.isAlive);
    if (cocuk != null) {
      log('chooseHeir', () => c.chooseHeir(cocuk.id),
          uygulandi: (String? v) => v != null);
      if (rng.nextDouble() < 0.3) {
        log('clearHeir', () => c.clearHeir(), uygulandi: (String? v) => v != null);
      }
    }
  }
}

/// Finger destesindeki profilin kimliğini taşıyan küçük sarmalayıcı.
class FingerProfileLike {
  const FingerProfileLike(this.id);
  final String id;
}

// =====================================================================
// Aktiviteler: kitap, hobi, spor, dövüş sanatı, sağlık, sosyal medya
// =====================================================================
void _books(
  GameController c,
  CoveragePlan plan,
  Random rng,
  CoverageResult r,
  ActionLog log,
) {
  // ---- Kitap: aç, sayfa çevir, bitir (AI §3) ------------------------
  final List<BookInfo> kitaplar = c.availableBooks();
  if (kitaplar.isNotEmpty) {
    final BookInfo k = kitaplar[r.seed % kitaplar.length];
    final ActivityOutcome? acildi = log.outcome('openBook', () => c.openBook(k));
    if (acildi?.applied ?? false) r.books.add(k.id);
    // Kitabı **bitirene kadar** sayfa çevir: okuma hobisi ancak
    // bitirilen kitapla ilerliyor (AH'de Yazar mesleğinin kilidi buydu).
    int sayfa = 0;
    while (sayfa++ < 400) {
      final ActivityOutcome? tur = log.outcome('turnBookPage', () => c.turnBookPage(k));
      if (!(tur?.applied ?? false)) break;
      if (_kesildi(c)) return;
    }
  }

}

void _dailyActivities(
  GameController c,
  CoveragePlan plan,
  Random rng,
  CoverageResult r,
  ActionLog log,
) {
  // ---- Aktiviteler: kataloğun tamamı --------------------------------
  //
  // **Kataloğun kendisi taranıyor, `availableActivities` değil.** O
  // yardımcı zaten uygunluk süzgecinden geçmiş listeyi veriyor;
  // onunla ölçünce "hiçbir aktivite engellenmedi" gibi yanlış bir
  // sonuç çıkıyordu. Engellenenleri görmek için ham katalog gerekli.
  final List<ActivityAction> denenecek = <ActivityAction>[];
  for (final ActivityAction a in kActivityActions) {
    final InteractionAvailability uygun = c.activityAvailability(a);
    if (uygun.isAllowed) {
      denenecek.add(a);
    } else {
      r.blockedActivities[a.id] = uygun.reason ?? '';
    }
  }
  // Kapsam için hepsine dokunmaya çalış; yıl içinde tükenirse bırakır.
  for (final ActivityAction a in denenecek) {
    if (!c.activityAvailability(a).isAllowed) continue;
    final ActivityOutcome? cikti =
        log.outcome('performActivity', () => c.performActivity(a));
    if (cikti?.applied ?? false) r.performedActivities.add(a.id);
    // Hobi ilerlemesi **durumdan** okunuyor: aktivite kimliğini
    // eşleştirmek eksik kalıyordu (kitapla beslenen okuma hobisi hiç
    // sayılmıyordu).
    for (final HobbyProgress h in c.state!.hobbies) {
      r.hobbies.add(h.hobbyId);
    }
    if (_olayVar(c)) return;
  }
}

void _martial(
  GameController c,
  CoveragePlan plan,
  Random rng,
  CoverageResult r,
  ActionLog log,
) {
  // ---- Dövüş sanatları: her sanat, ders ve sezon ---------------------
  for (final MartialArt art in MartialArt.values) {
    if (!c.martialAvailability(art).isAllowed) continue;
    final ActivityOutcome? ders =
        log.outcome('takeMartialLesson', () => c.takeMartialLesson(art));
    if (ders?.applied ?? false) r.martialArts.add(art.id);
    final ActivityOutcome? sezon =
        log.outcome('takeMartialSeason', () => c.takeMartialSeason(art));
    if (sezon?.applied ?? false) r.martialArts.add(art.id);
    if (_olayVar(c)) return;
  }

}

void _health(
  GameController c,
  CoveragePlan plan,
  Random rng,
  CoverageResult r,
  ActionLog log,
) {
  for (final dynamic kronik in c.state!.chronicConditions) {
    log('careForChronic', () => c.careForChronic(kronik.typeId as String),
        uygulandi: (String? v) => v != null);
  }
  // Göz muayenesi mini oyunu ayrı bir aksiyon.
  for (final ActivityVenue mekan in ActivityVenue.values) {
    final ActivityAction? goz = c
        .availableActivities(mekan)
        .firstOrNullCov((ActivityAction a) => a.id == 'goz_muayenesi');
    if (goz != null && c.activityAvailability(goz).isAllowed) {
      log.outcome('finishEyeExam',
          () => c.finishEyeExam(goz, correct: 6 + rng.nextInt(4), total: 10));
      break;
    }
  }
}

void _social(
  GameController c,
  CoveragePlan plan,
  Random rng,
  CoverageResult r,
  ActionLog log,
) {
  final bool sosyalci = plan == CoveragePlan.sosyalci;
  // Her platformda hesap aç.
  for (final SocialPlatform p in SocialPlatform.values) {
    if (c.socialAccountAvailability(p).isAllowed) {
      final SocialOutcome? sonuc =
          log.outcome('openSocialAccount', () => c.openSocialAccount(p));
      if (sonuc?.applied ?? false) r.socialPlatforms.add(p.name);
      if (!sosyalci) break;
    }
  }
  // Her içerik türünü dene.
  for (final SocialContent icerik in kSocialContents) {
    if (!c.socialPostAvailability(icerik).isAllowed) continue;
    log.outcome('postContent', () => c.postContent(icerik));
    if (_kesildi(c)) return;
    if (!sosyalci) break;
  }
  // Sponsor: hem kabul hem ret kolu.
  if (c.state!.sponsorOffer != null) {
    if (rng.nextDouble() < 0.7) {
      log.outcome('acceptSponsor', () => c.acceptSponsor());
    } else {
      log.outcome('declineSponsor', () => c.declineSponsor());
    }
  }
  // Ünlüyle iletişim.
  for (final SocialPlatform p in SocialPlatform.values) {
    final List<Celebrity> unluler = c.celebritiesOnPlatform(p);
    if (unluler.isEmpty) continue;
    for (final CelebrityAction eylem in CelebrityAction.values) {
      if (c.celebrityAvailability(unluler.first, eylem).isAllowed) {
        log.outcome('contactCelebrity', () => c.contactCelebrity(unluler.first, eylem));
        break;
      }
    }
    break;
  }
  // Medya işi.
  for (final MediaOpportunity is_ in kMediaOpportunities) {
    if (c.mediaAvailability(is_).isAllowed) {
      log.outcome('acceptMediaJob', () => c.acceptMediaJob(is_));
      break;
    }
  }
}

// =====================================================================
// Kalanlar: ehliyet, askerlik, hapis, hayvan, seyahat
// =====================================================================
void _extras(
  GameController c,
  CoveragePlan plan,
  Random rng,
  CoverageResult r,
  ActionLog log,
) {
  // ---- Ehliyet -------------------------------------------------------
  for (final LicenseType t in LicenseType.values) {
    if (c.hasLicense(t)) continue;
    if (!c.licenseAvailability(t).isAllowed) continue;
    log.outcome('applyForLicense', () => c.applyForLicense(t));
    break;
  }

  // ---- Askerlik ------------------------------------------------------
  final MilitaryTrack yol =
      MilitaryTrack.values[rng.nextInt(MilitaryTrack.values.length)];
  if (c.militaryAvailability(yol).isAllowed) {
    final double zar = rng.nextDouble();
    if (zar < 0.45) {
      log.outcome('enlistMilitary', () => c.enlistMilitary(yol));
    } else if (zar < 0.65) {
      if (c.bedelliAvailability().isAllowed) {
        log.outcome('payBedelli', () => c.payBedelli());
      } else {
        final List<Person> odeyenler = c.bedelliPayers();
        if (odeyenler.isNotEmpty) {
          log.outcome('askFamilyForBedelli', () => c.askFamilyForBedelli(odeyenler.first.id));
        }
      }
    } else if (zar < 0.85) {
      log.outcome('deferMilitary', () => c.deferMilitary());
    } else {
      log.outcome('fleeMilitary', () => c.fleeMilitary());
    }
  }
  if (c.state!.military.isFugitive) {
    log.outcome('surrenderMilitary', () => c.surrenderMilitary());
  }

  // ---- Hapis ---------------------------------------------------------
  if (c.state!.legal.imprisonedSinceAge != null) {
    if (c.selfBailBlockReason().isEmpty) {
      log.outcome('payBailSelf', () => c.payBailSelf());
    }
    final List<Person> yardim = c.bailHelpers();
    if (yardim.isNotEmpty) {
      log.outcome('askFamilyForBail', () => c.askFamilyForBail(yardim.first.id));
    }
    for (final PrisonAction a in PrisonAction.values) {
      if (c.prisonActionBlockReason(a).isEmpty) {
        log.outcome('doPrisonAction', () => c.doPrisonAction(a));
        break;
      }
    }
  }

  // ---- Evcil hayvan --------------------------------------------------
  if (plan == CoveragePlan.hayvansever || rng.nextDouble() < 0.3) {
    for (final PetSpecies tur in PetSpecies.values) {
      if (!c.petAdoptionAvailability(tur).isAllowed) continue;
      final String? sonuc = log('adoptPet',
          () => c.adoptPet(tur, kPetSuggestedNames[rng.nextInt(kPetSuggestedNames.length)]),
          uygulandi: (String? v) => v != null);
      if (sonuc != null) r.petSpecies.add(tur.name);
      break;
    }
  }
  for (final Pet h in c.state!.pets) {
    for (final PetAction a in PetAction.values) {
      if (c.petActionAvailability(h, a).isAllowed) {
        log('petInteract', () => c.petInteract(h, a),
            uygulandi: (String? v) => v != null);
      }
    }
    if (c.petRehomeAvailability(h).isAllowed && rng.nextDouble() < 0.05) {
      log('rehomePet', () => c.rehomePet(h), uygulandi: (String? v) => v != null);
    }
    break;
  }

  // ---- Seyahat -------------------------------------------------------
  if (plan == CoveragePlan.gezgin || rng.nextDouble() < 0.25) {
    final List<TravelMode> modlar = c.travelModes();
    final List<String> sehirler = c.travelDestinations();
    final List<Person> yoldaslar = c.travelCompanions();
    if (modlar.isNotEmpty && sehirler.isNotEmpty) {
      final TravelMode mod = modlar[rng.nextInt(modlar.length)];
      final String sehir = sehirler[rng.nextInt(sehirler.length)];
      final String? arkadas =
          yoldaslar.isEmpty || rng.nextBool() ? null : yoldaslar.first.id;
      if (c.travelAvailability(mode: mod, city: sehir, companionId: arkadas)
          .isAllowed) {
        log('takeTrip',
            () => c.takeTrip(mode: mod, city: sehir, companionId: arkadas));
      }
    }
    for (final TourPackage tur in kTourPackages) {
      if (c.tourAvailability(tour: tur).isAllowed) {
        log.outcome('takeTour', () => c.takeTour(tour: tur));
        break;
      }
    }
  }

  // ---- Hayatın sonu --------------------------------------------------
  if (c.state!.player.age >= 95 && rng.nextDouble() < 0.02) {
    log('endLifeByChoice', () => c.endLifeByChoice(),
        uygulandi: (String v) => v.isNotEmpty);
  }
}
