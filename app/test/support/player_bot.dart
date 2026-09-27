/// Gerçek oyuncu davranışını taklit eden simülasyon botu.
///
/// **Neden var.** Mevcut ölçüm botları (`playActiveLife`, `paket_*_measure`)
/// hayatı sürekli "Yaş Al"a basarak ve olaylarda rastgele/ilk seçeneği
/// seçerek geçiyordu. Regresyon avlamak için iyi, **ürün metriği için
/// kullanılamaz**: kariyer geliştirmeyen, üniversiteye bilinçli karar
/// vermeyen, parasını yönetmeyen bir bottan "kaç kişi ev alabiliyor"
/// sorusunun cevabı çıkmaz.
///
/// Bu bot hayat kurmaya çalışıyor: okuyor, iş arıyor, iş değiştiriyor, zam
/// istiyor, evleniyor, çocuk yapıyor, para biriktiriyor, yatırım yapıyor,
/// ev almayı deniyor, iş kuruyor, hobi ediniyor.
///
/// **Kurallar:**
/// * `debugSetState` ile para/stat/ilişki/ev/iş **verilmez**. Bot üretim
///   kurallarını atlayarak avantaj kazanmaz; her şey `GameController`'ın
///   gerçek public aksiyonlarından geçer.
/// * Olaylarda `choices.first` **yasak**. Seçim arketip, para, sağlık,
///   ilişki ve risk profiliyle puanlanır.
/// * Bot optimal oynamaz: her arketipte %15-30 insani/rastgele karar payı
///   var (`_humanSlip`).
/// * Hafıza test tarafında (`_Intent`); `GameState`'e alan eklenmedi.
///
/// Bu dosya **yalnızca test altyapısıdır**; ürün kodu değildir.
library;

import 'dart:math';

import 'package:bir_omur/data/activity_catalog.dart';
import 'package:bir_omur/data/business_catalog.dart';
import 'package:bir_omur/data/education_tracks.dart';
import 'package:bir_omur/domain/education/education_path.dart';
import 'package:bir_omur/data/health_crisis_catalog.dart';
import 'package:bir_omur/data/hobby_catalog.dart';
import 'package:bir_omur/data/interview_catalog.dart';
import 'package:bir_omur/domain/models/finger_profile.dart';
import 'package:bir_omur/data/investment_catalog.dart';
import 'package:bir_omur/data/item_catalog.dart';
import 'package:bir_omur/domain/career/craft_mastery.dart';
import 'package:bir_omur/domain/career/job_market.dart';
import 'package:bir_omur/domain/economy/business_engine.dart';
import 'package:bir_omur/domain/economy/investment_engine.dart';
import 'package:bir_omur/domain/interaction/divorce_settlement.dart';
import 'package:bir_omur/domain/interaction/item_actions.dart';
import 'package:bir_omur/domain/interaction/marriage_engine.dart';
import 'package:bir_omur/data/job_catalog.dart';
import 'package:bir_omur/data/lawyer_catalog.dart';
import 'package:bir_omur/data/martial_arts_catalog.dart';
import 'package:bir_omur/data/pet_catalog.dart';
import 'package:bir_omur/domain/activities/travel.dart';
import 'package:bir_omur/domain/models/trip.dart';
import 'package:bir_omur/domain/social/social_engine.dart';
import 'package:bir_omur/domain/pets/pet_care.dart';
import 'package:bir_omur/data/shop_catalog.dart';
import 'package:bir_omur/data/social_catalog.dart';
import 'package:bir_omur/data/university_catalog.dart';
import 'package:bir_omur/domain/economy/banking.dart';
import 'package:bir_omur/domain/economy/living_costs.dart';
import 'package:bir_omur/domain/economy/net_worth.dart';
import 'package:bir_omur/domain/economy/rental_engine.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/chronic_condition.dart';
import 'package:bir_omur/domain/models/hobby_progress.dart';
import 'package:bir_omur/domain/models/marriage.dart';
import 'package:bir_omur/domain/models/martial_progress.dart';
import 'package:bir_omur/domain/models/business.dart';
import 'package:bir_omur/domain/models/criminal_record.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/interaction.dart';
import 'package:bir_omur/domain/models/loan.dart';
import 'package:bir_omur/domain/models/owned_item.dart';
import 'package:bir_omur/domain/models/pending_crisis.dart';
import 'package:bir_omur/domain/models/pending_trial.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/investment.dart';
import 'package:bir_omur/domain/models/rental.dart';
import 'package:bir_omur/domain/events/event_engine.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:bir_omur/state/game_controller.dart';

import 'bot_diagnostics.dart';

export 'bot_diagnostics.dart';

/// Oyuncu tipleri. Her biri farklı hedeflerle oynar.
enum PlayerArchetype {
  career('Kariyer odaklı'),
  investor('Para / yatırım odaklı'),
  entrepreneur('Girişimci'),
  family('Aile odaklı'),
  social('Sosyal / ün odaklı'),
  education('Eğitim odaklı'),
  casual('Rahat / ortalama'),
  risky('Riskli hayat'),
  sport('Spor / hobi odaklı'),
  randomValid('Rastgele ama geçerli');

  const PlayerArchetype(this.label);

  final String label;
}

/// Yatırım tarzı.
enum InvestStyle { none, cautious, balanced, aggressive }

/// Arketipin karar ağırlıkları. Hepsi 0-1 arası.
class BotProfile {
  const BotProfile({
    required this.university,
    required this.savingRate,
    required this.jobHopping,
    required this.familyDesire,
    required this.socialDesire,
    required this.hobbyDesire,
    required this.sportDesire,
    required this.healthCare,
    required this.riskAppetite,
    required this.crimeWillingness,
    required this.investStyle,
    required this.wantsBusiness,
    required this.wantsProperty,
    required this.wantsRental,
    required this.usesLoan,
    required this.slip,
  });

  /// Üniversiteye gitme eğilimi.
  final double university;

  /// Gelirin ne kadarını kenara koyma eğilimi.
  final double savingRate;

  /// Daha iyi iş için işten ayrılma eğilimi.
  final double jobHopping;

  final double familyDesire;
  final double socialDesire;
  final double hobbyDesire;
  final double sportDesire;
  final double healthCare;

  /// Riskli seçeneklere yatkınlık.
  final double riskAppetite;

  /// Suç içeren seçeneği seçebilme eğilimi.
  final double crimeWillingness;

  final InvestStyle investStyle;
  final double wantsBusiness;

  /// Oturmak için ev alma eğilimi.
  final double wantsProperty;

  /// Kiraya vermek için ikinci ev alma eğilimi.
  final double wantsRental;

  /// Kredi kullanmaya yatkınlık.
  final double usesLoan;

  /// İnsani/rastgele karar payı (%15-30 bandı).
  final double slip;
}

/// prototypeOnly: arketip profilleri. Ürün dengesi değil, **oyuncu
/// davranışı** modelidir; oyunun sayılarına dokunmaz.
const Map<PlayerArchetype, BotProfile> kBotProfiles =
    <PlayerArchetype, BotProfile>{
  PlayerArchetype.career: BotProfile(
    university: 0.85,
    savingRate: 0.30,
    jobHopping: 0.55,
    familyDesire: 0.45,
    socialDesire: 0.30,
    hobbyDesire: 0.30,
    sportDesire: 0.30,
    healthCare: 0.50,
    riskAppetite: 0.20,
    crimeWillingness: 0.0,
    investStyle: InvestStyle.balanced,
    wantsBusiness: 0.05,
    wantsProperty: 0.65,
    wantsRental: 0.15,
    usesLoan: 0.55,
    slip: 0.18,
  ),
  PlayerArchetype.investor: BotProfile(
    university: 0.55,
    savingRate: 0.55,
    jobHopping: 0.45,
    familyDesire: 0.35,
    socialDesire: 0.20,
    hobbyDesire: 0.20,
    sportDesire: 0.25,
    healthCare: 0.45,
    riskAppetite: 0.35,
    crimeWillingness: 0.0,
    investStyle: InvestStyle.aggressive,
    wantsBusiness: 0.15,
    wantsProperty: 0.80,
    wantsRental: 0.70,
    usesLoan: 0.70,
    slip: 0.15,
  ),
  PlayerArchetype.entrepreneur: BotProfile(
    university: 0.35,
    savingRate: 0.50,
    jobHopping: 0.35,
    familyDesire: 0.40,
    socialDesire: 0.35,
    hobbyDesire: 0.20,
    sportDesire: 0.20,
    healthCare: 0.35,
    riskAppetite: 0.60,
    crimeWillingness: 0.02,
    investStyle: InvestStyle.balanced,
    wantsBusiness: 0.95,
    wantsProperty: 0.40,
    wantsRental: 0.25,
    usesLoan: 0.75,
    slip: 0.22,
  ),
  PlayerArchetype.family: BotProfile(
    university: 0.50,
    savingRate: 0.25,
    jobHopping: 0.25,
    familyDesire: 0.95,
    socialDesire: 0.45,
    hobbyDesire: 0.30,
    sportDesire: 0.25,
    healthCare: 0.60,
    riskAppetite: 0.15,
    crimeWillingness: 0.0,
    investStyle: InvestStyle.cautious,
    wantsBusiness: 0.05,
    wantsProperty: 0.75,
    wantsRental: 0.10,
    usesLoan: 0.60,
    slip: 0.20,
  ),
  PlayerArchetype.social: BotProfile(
    university: 0.45,
    savingRate: 0.15,
    jobHopping: 0.40,
    familyDesire: 0.45,
    socialDesire: 0.95,
    hobbyDesire: 0.45,
    sportDesire: 0.35,
    healthCare: 0.45,
    riskAppetite: 0.35,
    crimeWillingness: 0.01,
    investStyle: InvestStyle.none,
    wantsBusiness: 0.10,
    wantsProperty: 0.35,
    wantsRental: 0.10,
    usesLoan: 0.40,
    slip: 0.25,
  ),
  PlayerArchetype.education: BotProfile(
    university: 0.95,
    savingRate: 0.30,
    jobHopping: 0.35,
    familyDesire: 0.40,
    socialDesire: 0.25,
    hobbyDesire: 0.55,
    sportDesire: 0.20,
    healthCare: 0.50,
    riskAppetite: 0.15,
    crimeWillingness: 0.0,
    investStyle: InvestStyle.cautious,
    wantsBusiness: 0.05,
    wantsProperty: 0.55,
    wantsRental: 0.15,
    usesLoan: 0.45,
    slip: 0.15,
  ),
  PlayerArchetype.casual: BotProfile(
    university: 0.45,
    savingRate: 0.20,
    jobHopping: 0.30,
    familyDesire: 0.60,
    socialDesire: 0.45,
    hobbyDesire: 0.45,
    sportDesire: 0.35,
    healthCare: 0.40,
    riskAppetite: 0.30,
    crimeWillingness: 0.01,
    investStyle: InvestStyle.cautious,
    wantsBusiness: 0.10,
    wantsProperty: 0.50,
    wantsRental: 0.15,
    usesLoan: 0.45,
    slip: 0.30,
  ),
  PlayerArchetype.risky: BotProfile(
    university: 0.25,
    savingRate: 0.10,
    jobHopping: 0.70,
    familyDesire: 0.35,
    socialDesire: 0.40,
    hobbyDesire: 0.25,
    sportDesire: 0.25,
    healthCare: 0.20,
    riskAppetite: 0.90,
    crimeWillingness: 0.55,
    investStyle: InvestStyle.aggressive,
    wantsBusiness: 0.25,
    wantsProperty: 0.30,
    wantsRental: 0.15,
    usesLoan: 0.85,
    slip: 0.25,
  ),
  PlayerArchetype.sport: BotProfile(
    university: 0.40,
    savingRate: 0.25,
    jobHopping: 0.30,
    familyDesire: 0.45,
    socialDesire: 0.40,
    hobbyDesire: 0.75,
    sportDesire: 0.95,
    healthCare: 0.70,
    riskAppetite: 0.30,
    crimeWillingness: 0.0,
    investStyle: InvestStyle.cautious,
    wantsBusiness: 0.08,
    wantsProperty: 0.45,
    wantsRental: 0.10,
    usesLoan: 0.40,
    slip: 0.22,
  ),
  // Rastgele ama **geçerli**: ilk şıkkı seçmez, yalnızca açık ve mantıklı
  // seçenekler arasından ağırlıklı rastgele karar verir. Amaç bizim
  // öngörmediğimiz hayat yollarını bulmak.
  PlayerArchetype.randomValid: BotProfile(
    university: 0.50,
    savingRate: 0.30,
    jobHopping: 0.50,
    familyDesire: 0.50,
    socialDesire: 0.50,
    hobbyDesire: 0.50,
    sportDesire: 0.50,
    healthCare: 0.50,
    riskAppetite: 0.50,
    crimeWillingness: 0.15,
    investStyle: InvestStyle.balanced,
    wantsBusiness: 0.30,
    wantsProperty: 0.50,
    wantsRental: 0.30,
    usesLoan: 0.50,
    slip: 0.60,
  ),
};

/// Bir hayatın ölçüm çıktısı.
class BotLifeResult {
  BotLifeResult({required this.archetype, required this.seed});

  final PlayerArchetype archetype;
  final int seed;

  int deathAge = 0;

  /// Hayat gerçekten ölümle mi bitti? `false` ise simülasyon takıldı ve
  /// **ölçüm o hayatı temsil etmez**. Ayrı sayılır; ölüm yaşı ortalamasına
  /// karıştırılmaz.
  bool endedByDeath = false;

  /// Takılma sebebi (varsa).
  String? stuckReason;

  // Eğitim
  bool wentToUniversity = false;
  bool graduatedUniversity = false;
  String? programId;
  bool finishedHighSchool = false;

  // Kariyer
  final Set<String> jobIds = <String>{};
  int jobChanges = 0;
  bool retired = false;
  bool everEmployed = false;
  bool partTime = false;
  int raiseAttempts = 0;
  int raisesGranted = 0;
  int promotions = 0;
  /// Meslekte **itibar** (0-100), kademe değil.
  int masteryReputation = 0;

  // Para
  int finalNetWorth = 0;
  int finalDebt = 0;
  bool investedEver = false;
  final Set<String> investmentTypes = <String>{};
  bool usedLoan = false;
  bool ownedHome = false;
  bool ownedRental = false;
  bool letProperty = false;
  bool ownedVehicle = false;
  bool ownedBusiness = false;
  final Set<String> businessTypes = <String>{};

  // Aile
  bool married = false;
  bool divorced = false;
  bool remarried = false;
  int childCount = 0;
  bool sawGrandchild = false;
  bool everPartner = false;

  // Sosyal
  int friendCount = 0;
  int closeFriendCount = 0;
  bool estranged = false;
  bool openedSocial = false;
  int finalFame = 0;

  // Sağlık / spor
  bool chronic = false;
  bool checkup = false;
  bool didSport = false;
  final Set<String> hobbies = <String>{};
  final Set<String> martialArts = <String>{};
  int finalHealth = 0;

  // Suç
  bool hasRecord = false;
  bool wentToTrial = false;
  bool imprisoned = false;
  final Set<String> crimeIds = <String>{};

  // İçerik
  final Set<String> seenEvents = <String>{};
  final Set<String> cities = <String>{};
  bool traveled = false;
  bool hadPet = false;
  bool usedFinger = false;
  bool gambled = false;

  /// Teşhis kayıtları (bkz. `bot_diagnostics.dart`). Her hayatta
  /// doldurulur; oyunun akışına dokunmaz, yalnızca okur.
  final BotDiag diag = BotDiag();

  bool get wentToUni => wentToUniversity;
}

/// Botun hafızası. **Test tarafı**; `GameState`'e alan eklenmedi.
class _Intent {
  _Intent(this.profile, this.rng, this.overrides);

  final BotProfile profile;
  final Random rng;

  /// Teşhis turunda kapatılan politikalar. Varsayılan hiçbir şeyi
  /// kapatmaz; kapatırken bile niyet zarı **atılır** (aşağıda), böylece
  /// aynı tohum bütün senaryolarda aynı rastgele akışla başlar.
  final BotOverrides overrides;

  /// Bu hayatta üniversiteye gitmeye karar verdi mi? Lise sonrası rastgele
  /// vazgeçmemesi için bir kez karar verilir ve hatırlanır.
  late final bool wantsUniversity = rng.nextDouble() < profile.university;

  /// Ev için para biriktiriyor mu?
  late final bool savingForHome =
      rng.nextDouble() < profile.wantsProperty && !overrides.noProperty;

  /// Kiralık ev hedefi var mı?
  late final bool wantsRental =
      rng.nextDouble() < profile.wantsRental && !overrides.noProperty;

  /// İş kurma hedefi var mı?
  late final bool wantsBusiness =
      rng.nextDouble() < profile.wantsBusiness && !overrides.noBusiness;

  /// Evlenmek istiyor mu? (Bekar kalmak da geçerli bir hayat.)
  late final bool wantsMarriage = rng.nextDouble() < profile.familyDesire;

  /// Çocuk istiyor mu?
  late final bool wantsChildren =
      rng.nextDouble() < profile.familyDesire * 0.9;

  /// Sosyal medya kullanacak mı?
  late final bool wantsSocial = rng.nextDouble() < profile.socialDesire;

  /// Seçtiği hobi ve dövüş sanatı: hayat boyunca **aynısına** devam eder,
  /// her yıl başka bir hobiye atlamaz.
  late final HobbyKind? favouriteHobby = rng.nextDouble() < profile.hobbyDesire
      ? HobbyKind.values[rng.nextInt(HobbyKind.values.length)]
      : null;
  late final MartialArt? favouriteArt = rng.nextDouble() < profile.sportDesire
      ? MartialArt.values[rng.nextInt(MartialArt.values.length)]
      : null;

  /// Yatırım türü tercihi: profile göre sabit bir sepet.
  late final List<String> investmentBasket = overrides.noInvesting
      ? const <String>[]
      : switch (profile.investStyle) {
          InvestStyle.none => const <String>[],
          InvestStyle.cautious => const <String>['vadeli', 'altin'],
          InvestStyle.balanced => const <String>['fon', 'altin', 'doviz'],
          InvestStyle.aggressive => const <String>['hisse', 'fon'],
        };

  /// Kaç yıldır aynı işte? İş değiştirme kararında kullanılır.
  int yearsInCurrentJob = 0;
  String? lastJobId;

  /// Bu hayatta ev almaya çalışıldı mı (tekrar tekrar denemesin diye).
  int homeAttemptAge = -99;
  int rentalAttemptAge = -99;
  int businessAttemptAge = -99;
}

/// Bir hayatı **doğumdan ölüme** oynar ve ölçümünü döner.
///
/// Sıra her yıl şu şekilde: bekleyen şeyler (olay, kriz, duruşma, mülakat,
/// bildirim) → eğitim → kariyer → para → ilişki → aktivite → yaş al.
BotLifeResult playBotLife({
  required PlayerArchetype archetype,
  required int seed,
  /// Yalnızca teşhis için: her yılın sonunda çağrılır.
  void Function(GameState state)? onYear,
  /// Teşhis turunda botun politikasını kısıtlar. Oyunun sayıları
  /// **değişmez**; yalnızca botun tercihleri kapanır.
  BotOverrides overrides = BotOverrides.none,
  /// Olay uygunluğunu her yıl tarar (O bölümü). Pahalı olduğu için
  /// varsayılan kapalı; açıkken **kendi ayrı zarını** kullanır, oyunun
  /// rastgele akışına dokunmaz.
  bool scanEventEligibility = false,
}) {
  final BotProfile profile = kBotProfiles[archetype]!;
  final GameController c = GameController(random: Random(seed));
  c.startNewLife(mode: StartMode.tamamenRastgele, seed: seed);

  // Botun kendi zarı oyunun zarından **ayrı**: bot kararları oyunun
  // rastgele akışını kaydırmasın.
  final Random rng = Random(seed * 7919 + archetype.index * 104729 + 13);
  final _Intent intent = _Intent(profile, rng, overrides);
  final BotLifeResult sonuc = BotLifeResult(archetype: archetype, seed: seed);
  final BotDiag diag = sonuc.diag;
  // Teşhis taramasının **ayrı** zarı: oyunun akışını kaydırmasın.
  final Random tarayiciRng = Random(seed * 31 + 17);
  const EventEngine tarayici = EventEngine();

  /// Eylemlerin çalıştığı son yaş: yıl içinde tekrar çalışmasınlar.
  int islenenYas = -1;

  int guard = 0;
  while (!c.state!.deceased && guard++ < 6000) {
    final GameState s = c.state!;
    sonuc.cities.add(s.player.currentCity);

    // ---- 1) Bekleyen şeyler ------------------------------------------
    if (s.hasNotice) {
      // Teşhis: mirası bildirimin kendi tutarından okuyoruz. Cüzdan
      // farkından çıkarmak yanlış olurdu — aynı yıl maaş, gider ve kira
      // da cüzdanı oynatıyor.
      final PendingNotice bildirim = s.notices.first;
      if (bildirim.kind == NoticeKind.miras) {
        diag.inheritanceCount++;
        diag.inheritanceMoney += bildirim.money;
        diag.inheritanceItems += bildirim.itemNames.length;
      }
      c.dismissNotice();
      continue;
    }
    final ActiveEvent? olay = s.pendingEvent;
    if (olay != null) {
      sonuc.seenEvents.add(olay.eventId);
      final EventChoice secim = _chooseEventChoice(
        state: s,
        event: olay,
        profile: profile,
        intent: intent,
        rng: rng,
      );
      if (secim.crimeId != null) sonuc.crimeIds.add(secim.crimeId!);
      diag.eventsAnswered++;
      c.chooseEventOption(secim.id);
      continue;
    }
    if (s.pendingCrisis != null) {
      if (!_handleCrisis(c, rng)) {
        // Karşılanabilir seçeneği olmayan kriz: oyuncu ekranda sıkışır.
        // Bu bir **oyun kilidi** işareti; ölüm değil. Ayrı raporlanır.
        sonuc.stuckReason = 'karsilanamayan kriz';
        break;
      }
      continue;
    }
    if (s.hasPendingTrial) {
      _handleTrial(c, rng, profile);
      sonuc.wentToTrial = true;
      continue;
    }
    if (s.pendingInterview != null) {
      // Mülakatta bilinçli cevap: zekâsı yüksek olan doğruyu daha sık
      // bulur ama garanti değil.
      final InterviewQuestion? soru =
          interviewQuestionById(s.pendingInterview!.questionId);
      final bool bilir =
          rng.nextDouble() < 0.35 + s.player.stats.intelligence / 200;
      c.answerInterview(
        bilir && soru != null ? soru.correctIndex : rng.nextInt(2),
      );
      continue;
    }
    if (s.pendingWedding != null) {
      diag.pendingWeddingSeen = true;
      diag.proposalAccepted = true;
      if (diag.separationAge != null) {
        diag.postSepAccepted = true;
      }
      // **Doğru akış `holdWedding`.** `marry` teklifsiz doğrudan yol;
      // bekleyen düğünde çağrılınca kabul edilmeyebiliyor ve pencere
      // kapanmadan kalıyordu (2 hayat sonsuz döngüye girdi). Bedelsiz
      // nikâh her cüzdanda var, bu yüzden düğün her hâlde kapanır.
      final FamilyOutcome? dugun = c.holdWedding('nikah');
      if (dugun?.applied ?? false) {
        sonuc.married = true;
        _markWeddingHeld(c, diag);
        continue;
      }
      // Yine olmadıysa doğrudan evlenmeyi dene; o da olmazsa bu düğünü
      // bırak (pencere oyunun kendi akışında kapanacak).
      final FamilyOutcome? dogrudan = c.marry(s.pendingWedding!.spouseId);
      if (dogrudan?.applied ?? false) {
        sonuc.married = true;
        _markWeddingHeld(c, diag);
        continue;
      }
      sonuc.stuckReason = 'dugun kapanmiyor';
      break;
    }

    // ---- 2) Eğitim ---------------------------------------------------
    if (c.needsTrackChoice) {
      _chooseTrack(c, rng);
      continue;
    }
    if (c.needsAfterSchoolChoice) {
      sonuc.finishedHighSchool = true;
      _decideUniversity(c, intent, rng, sonuc);
      continue;
    }

    // ---- 3-6) Yılın eylemleri: **yaş başına bir kez** ----------------
    //
    // Gerçek bir bot hatası buradaydı: eylemler bildirim üretiyor, ana
    // döngü bildirimi kapatıp başa dönüyor ve aynı yıl içinde eylemleri
    // **yeniden** yapıyordu. Yıl hiç bitmiyordu; hayatların %25,6'sı
    // 6000 turluk güvenlik sınırına çarpıyor ve ölçüme "ölmedi" diye
    // giriyordu. Artık her yaş için eylemler bir kez çalışıyor.
    if (islenenYas != s.player.age) {
      islenenYas = s.player.age;
      if (s.player.age >= 18) diag.adultYears++;
      if (scanEventEligibility) {
        // Ayrı zar: oyunun akışı kaymaz. "Bir kez bile uygun hale geldi
        // mi" sorusunu yanıtlar; görülenle arasındaki fark havuz
        // rekabetinde kaybedilen olaylardır.
        diag.eligibleEvents.addAll(tarayici.debugEligibleIds(s, tarayiciRng));
      }
      // Doğan bebeğe isim: **sonsuz döngü kaynağıydı.** Bot ilk yazımda
      // bebeğe kendi adını veriyordu; `ChildNaming.rename` aynı adı
      // değişiklik saymıyor, pencere açık kalıyor ve bot "isim
      // verilebilir" diye her turda başa dönüyordu. Yıl hiç bitmiyordu.
      // Artık yılda bir kez deneniyor ve sonucu ne olursa olsun
      // ilerleniyor; isim vermek zorunlu değil.
      for (final Person bebek in s.people) {
        if (!bebek.isAlive || !c.canNameChild(bebek.id)) continue;
        c.nameChild(bebek.id, _botChildName(bebek, rng));
        break;
      }
      _handleCareer(c, profile, intent, rng, sonuc);
      _handleMoney(c, profile, intent, rng, sonuc);
      _handleRelationships(c, profile, intent, rng, sonuc);
      _handleActivities(c, profile, intent, rng, sonuc);
      // Eylemler bildirim ya da olay ürettiyse ana döngü onları karşılar;
      // eylemler bu yıl bir daha çalışmaz.
      if (c.state!.hasNotice || c.state!.hasPendingEvent) continue;
    }

    // ---- 7) Yaş al ---------------------------------------------------
    final int oncekiYas = c.state!.player.age;
    // Teşhis: yaş almadan **önce** gideri ve cüzdanı okuyoruz.
    // `LivingCosts.apply` cüzdanı sıfırlayıp borç yazmıyor, portföye
    // hiç dokunmuyor (Q-165/5'in kaynağı); ödenen kısmı ancak burada
    // doğru hesaplayabiliriz.
    _snapshotBeforeAge(c.state!, diag);
    c.ageUp();
    if (c.state!.player.age == oncekiYas) {
      // İlerlemeyi engelleyen bir şey kaldıysa döngüyü kırmak yerine
      // bir sonraki turda bekleyenleri karşıla; iki kez üst üste
      // ilerlemiyorsa gerçekten kilitli.
      if (c.state!.hasNotice ||
          c.state!.hasPendingEvent ||
          c.state!.pendingCrisis != null ||
          c.state!.hasPendingTrial ||
          c.needsEducationChoice) {
        continue;
      }
      sonuc.stuckReason = 'yas ilerlemedi';
      break;
    }
    intent.yearsInCurrentJob++;
    _snapshotAfterAge(c.state!, diag);
    if (onYear != null) onYear(c.state!);
  }

  if (guard >= 6000) {
    final GameState son = c.state!;
    sonuc.stuckReason ??= 'tur siniri('
        'bildirim=${son.hasNotice ? son.notices.first.kind.name : '-'} '
        'olay=${son.pendingEvent?.eventId ?? '-'} '
        'kriz=${son.pendingCrisis != null} '
        'durusma=${son.hasPendingTrial} '
        'mulakat=${son.pendingInterview != null} '
        'dugun=${son.pendingWedding != null} '
        'egitim=${c.needsEducationChoice} '
        'yas=${son.player.age})';
  }
  _collectFinalMetrics(c, sonuc);
  _collectDiagAtDeath(c, diag);
  c.dispose();
  return sonuc;
}

// =====================================================================
// Teşhis yardımcıları — hiçbiri oyunun akışını değiştirmez, `rng`
// tüketmez, yalnızca okur.
// =====================================================================

/// Düğün gerçekten yapıldı: huninin son basamağı.
void _markWeddingHeld(GameController c, BotDiag diag) {
  diag.weddingHeld = true;
  if (diag.separationAge != null) {
    diag.postSepMarried = true;
    diag.remarriageAge ??= c.state!.player.age;
  }
}

/// Yaş almadan **önce** okunanlar: yaşam gideri ve portföy koruması.
void _snapshotBeforeAge(GameState s, BotDiag diag) {
  final int gider = LivingCosts.yearlyCost(s);
  if (gider <= 0) return;
  final int cuzdan = s.player.wallet;
  diag.lifetimeLivingCostAccrued += gider;
  diag.lifetimeLivingCostPaid += cuzdan >= gider ? gider : cuzdan;
  if (cuzdan < gider) {
    // **Q-165/5'in ölçüsü.** `LivingCosts.apply` yalnızca cüzdana
    // dokunuyor: portföy satılmıyor, borç yazılmıyor. Yani bu yıl
    // portföy giderden korunuyor ve bileşik büyümeye devam ediyor.
    final int portfoy = s.portfolioValue;
    if (portfoy > 0) {
      diag.protectedYears++;
      diag.protectedYearsPortfolioSum += portfoy;
    }
  }
  // Maaş: çalışıyorsa o yılın yıllık maaşı. Yaklaşık brüt kariyer
  // geliri; vergi/kesinti modeli değil.
  diag.lifetimeSalary += s.career.job?.yearlySalary ?? 0;
}

/// Yaş aldıktan **sonra** okunanlar: servet eğrisi ve sıkıntı sayacı.
void _snapshotAfterAge(GameState s, BotDiag diag) {
  final int yas = s.player.age;
  if (kWealthCurveAges.contains(yas)) {
    diag.netWorthAtAge[yas] = NetWorth.of(s);
    diag.portfolioAtAge[yas] = s.portfolioValue;
  }
  // `hardshipYears` üst üste sıkıntı sayacı; en yükseğini tutuyoruz.
  if (s.hardshipYears > diag.hardshipYears) {
    diag.hardshipYears = s.hardshipYears;
  }
  _trackSeparation(s, diag);
}

/// Boşanma ya da dulluk oldu mu, oldu ise kayıt doğru kapandı mı?
void _trackSeparation(GameState s, BotDiag diag) {
  if (diag.separationAge != null) {
    diag.yearsAfterSeparation = s.player.age - diag.separationAge!;
    return;
  }
  final Marriage? bitmis = <Marriage>[
    ...s.pastMarriages,
    if (s.marriage != null) s.marriage!,
  ].firstWhereOrNullBot((Marriage m) =>
      m.status == MarriageStatus.bosandi ||
      m.status == MarriageStatus.dul);
  if (bitmis == null) return;
  diag.separationAge = s.player.age;
  diag.separationKind =
      bitmis.status == MarriageStatus.bosandi ? 'bosanma' : 'dulluk';
  // Kayıt korundu mu: eski eş aynı kimlikle listede duruyor mu?
  // (İlk yazımda bunu "bağı artık `es` değil" diye ölçmüştüm ve %37,7
  // çıkmıştı; ama dullukta eş vefat eder ve bağı `es` kalabilir. O ölçü
  // dulluğu haksız yere "kayıt bozuldu" sayıyordu. İki soru ayrıldı.)
  diag.exSpouseRecordKept = !s.isMarried &&
      s.people.any((Person p) => p.id == bitmis.spouseId);
  if (bitmis.status == MarriageStatus.bosandi) {
    diag.exSpouseRelationUpdated = s.people.any((Person p) =>
        p.id == bitmis.spouseId && p.relation != RelationType.es);
  }
  // Oyun yeniden bekar kabul ediyor mu? `marryBlockReason`'ın ilk
  // kapısı "Zaten evlisin." — o kapı açıldı mı diye bakıyoruz.
  diag.treatedAsSingleAfter = !s.isMarried;
}

/// Teklif hunisinin bir basamağını işaretler.
void _trackProposalFunnel({
  required GameController c,
  required Person partner,
  required BotDiag diag,
}) {
  final bool ayrilikSonrasi = diag.separationAge != null;
  diag.hadPartner = true;
  if (ayrilikSonrasi) diag.postSepPartner = true;
  if (partner.bond > diag.bestPartnerBond) {
    diag.bestPartnerBond = partner.bond;
  }
  if (partner.bond >= 30) diag.bond30 = true;
  if (partner.bond >= MarriageEngine.prototypeOnlyMinBond) {
    diag.bond45 = true;
    if (ayrilikSonrasi) diag.postSepBond45 = true;
  }
  final InteractionAvailability uygunluk = c.proposalAvailability(partner.id);
  if (uygunluk.isAllowed) {
    diag.proposalEligible = true;
    if (ayrilikSonrasi) diag.postSepEligible = true;
  } else if (diag.wantedMarriage && c.state!.player.age >= 20) {
    // Bot teklif etmek istiyor ama oyun izin vermiyor: gerekçeyi
    // **oyunun kendi metninden** alıyoruz, tahmin etmiyoruz.
    final String sebep = _normalizeBlocker(uygunluk.reason ?? '');
    diag.marriageBlockers.add(sebep);
    if (ayrilikSonrasi) diag.postSepBlockers.add(sebep);
  }
}

/// Engel metnini sayılabilir bir etikete indirir: metinde yakınlık
/// değeri, kalan yıl gibi değişkenler var, ham metin sayılamaz.
String _normalizeBlocker(String reason) {
  if (reason.contains('Zaten evlisin')) return 'zaten evli';
  if (reason.contains('yeterince yakın değil')) return 'yakinlik yetersiz';
  if (reason.contains('yeterli zaman geçmedi')) return 'teklif bekleme suresi';
  if (reason.contains('Yalnızca sevgilinle')) return 'sevgili degil';
  if (reason.contains('çok genç')) return 'partner yasi kucuk';
  if (reason.contains('yaşından itibaren')) return 'oyuncu yasi kucuk';
  if (reason.contains('hayatta değil')) return 'partner hayatta degil';
  if (reason.contains('kayıtlarda yok')) return 'partner kayitta yok';
  if (reason.isEmpty) return 'engel yok';
  return 'diger: $reason';
}

/// Ölüm anı servet bileşenleri ve akış toplamları.
void _collectDiagAtDeath(GameController c, BotDiag diag) {
  final GameState s = c.state!;
  diag.wallet = s.player.wallet;
  diag.portfolio = s.portfolioValue;
  diag.debt = NetWorth.debt(s);
  diag.netWorth = NetWorth.of(s);
  diag.portfolioInvestedAtDeath = s.portfolioInvested;
  diag.portfolioUnrealizedAtDeath = s.portfolioUnrealized;
  diag.portfolioRealizedAtDeath = s.portfolioRealized;

  // Eşya değerini **boşanma paylaşımıyla aynı yerden** okuyoruz
  // (`NetWorth.itemsValue` de öyle yapıyor): iki ayrı değer ölçüsü
  // olmasın, toplam tutsun.
  for (final OwnedItem i in s.items) {
    final int deger = DivorceSettlement.valueOf(i);
    if (itemTypeOrFallback(i.typeId).kind == ItemKind.konut) {
      diag.realEstate += deger;
    } else if (i.isVehicle) {
      diag.vehicles += deger;
    } else {
      diag.otherAssets += deger;
    }
  }

  for (final PropertyLedger defter in s.propertyLedgers) {
    diag.lifetimeRent += defter.rentCollected;
    diag.lifetimeMaintenance += defter.maintenanceSpent;
  }
  for (final Business b in s.businesses) {
    diag.businessInvested += b.totalInvested;
    diag.businessProfit += b.totalProfit;
  }
}

/// Küçük yardımcı: listedeki ilk uyan öğe ya da null.
extension _FirstWhereOrNullBot<T> on Iterable<T> {
  T? firstWhereOrNullBot(bool Function(T) test) {
    for (final T e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}

// =====================================================================
// Olay seçimi — **ilk şık yasak**
// =====================================================================

/// Bir olayda seçeneği puanlayarak seçer.
///
/// Puan yalnızca `EventChoice` üzerinde gerçekten yazılı olan şeylerden
/// çıkar: para, mutluluk, sağlık, zekâ, karizma, görünüş, yakınlık, suç
/// bağı, romantizm ve arkadaşlık başlatma. Arketip bu kalemleri farklı
/// ağırlıklandırır; aynı olay farklı oyuncuda farklı sonuç verir.
///
/// **`choices.first` hiçbir yolda kullanılmaz.** En iyi puanlı seçenek
/// alınır ama `slip` payı kadar rastgele bir seçenek seçilir: gerçek
/// oyuncu da hata yapar.
EventChoice _chooseEventChoice({
  required GameState state,
  required ActiveEvent event,
  required BotProfile profile,
  required _Intent intent,
  required Random rng,
}) {
  final List<EventChoice> secenekler = event.choices;
  if (secenekler.length == 1) return secenekler.single;

  // İnsani kayma: hedefe uymayan ama saçma da olmayan bir seçim.
  if (rng.nextDouble() < profile.slip) {
    final List<EventChoice> makul = secenekler
        .where((EventChoice ch) =>
            // Parası olmayan, cebinden büyük para çıkaran seçeneği
            // "insani kayma" diye bile seçmez.
            ch.money >= 0 || state.player.wallet + ch.money >= 0)
        .toList(growable: false);
    final List<EventChoice> havuz = makul.isEmpty ? secenekler : makul;
    return havuz[rng.nextInt(havuz.length)];
  }

  double enIyiPuan = double.negativeInfinity;
  EventChoice? enIyi;
  for (final EventChoice ch in secenekler) {
    final double puan = _scoreChoice(
      choice: ch,
      state: state,
      profile: profile,
      intent: intent,
    );
    // Eşitlikte ilk şıkka takılmamak için küçük bir gürültü.
    final double gurultu = rng.nextDouble() * 0.6;
    if (puan + gurultu > enIyiPuan) {
      enIyiPuan = puan + gurultu;
      enIyi = ch;
    }
  }
  return enIyi ?? secenekler[rng.nextInt(secenekler.length)];
}

double _scoreChoice({
  required EventChoice choice,
  required GameState state,
  required BotProfile profile,
  required _Intent intent,
}) {
  double puan = 0;

  // --- Para ---------------------------------------------------------
  if (choice.money != 0) {
    // Para biriktiren oyuncu için çıkan para daha çok acıtır; kasası
    // boşsa herkes için acıtır.
    final int cuzdan = state.player.wallet;
    final double olcek = cuzdan <= 0 ? 1.8 : 1.0;
    if (choice.money > 0) {
      puan += choice.money / 20000 * (0.6 + profile.savingRate);
    } else {
      // Karşılanamayan harcama neredeyse hiç seçilmez.
      if (cuzdan + choice.money < 0) return -1000;
      puan += choice.money / 20000 * (0.8 + profile.savingRate) * olcek;
    }
  }

  // --- Statlar ------------------------------------------------------
  puan += choice.happiness * 0.22;
  puan += choice.health * (0.18 + profile.healthCare * 0.35);
  puan += choice.intelligence * (0.15 + profile.university * 0.45);
  puan += choice.charisma * (0.12 + profile.socialDesire * 0.45);
  puan += choice.appearance * (0.08 + profile.socialDesire * 0.25);
  puan += choice.bond * (0.10 + profile.familyDesire * 0.50);

  // Sağlığı düşükse sağlık kazancı çok daha değerli.
  if (state.player.stats.health < 45 && choice.health > 0) {
    puan += choice.health * 0.5;
  }

  // --- İlişki ve arkadaşlık ----------------------------------------
  if (choice.startsRomance) {
    puan += intent.wantsMarriage ? 4.0 : -1.0;
  }
  if (choice.endsRomance) {
    puan += intent.wantsMarriage ? -3.0 : 1.0;
  }
  if (choice.startsFriendship || choice.startsSchoolFriendship) {
    puan += 1.5 + profile.socialDesire * 4.0;
  }

  // --- Suç ----------------------------------------------------------
  if (choice.crimeId != null) {
    // Suçtan uzak duran arketipler bunu neredeyse hiç seçmez; riskli
    // arketip bilinçli olarak girebilir.
    puan += profile.crimeWillingness > 0
        ? -6.0 + profile.crimeWillingness * 18.0
        : -60.0;
  }

  // --- Eşya ---------------------------------------------------------
  if (choice.addPossessions.isNotEmpty) puan += 1.5;

  return puan;
}

// =====================================================================
// Kriz, duruşma, eğitim
// =====================================================================

/// Sağlık krizini karşılanabilir bir seçenekle kapatır.
/// Karşılanabilir seçenek yoksa `false` döner (kilitlenme işareti).
bool _handleCrisis(GameController c, Random rng) {
  final PendingCrisis kriz = c.state!.pendingCrisis!;
  final HealthCrisis? katalog = healthCrisisById(kriz.crisisId);
  final List<CrisisChoice> acik = katalog == null
      ? const <CrisisChoice>[]
      : katalog.choices
          .where((CrisisChoice ch) => c.canChooseCrisis(ch))
          .toList(growable: false);
  if (acik.isEmpty) return false;
  // Gerçek oyuncu gibi: en çok sağlık getiren karşılanabilir seçeneği
  // tercih eder, ama her zaman değil.
  acik.sort((CrisisChoice a, CrisisChoice b) =>
      b.healthChange.compareTo(a.healthChange));
  final CrisisChoice secim =
      rng.nextDouble() < 0.75 ? acik.first : acik[rng.nextInt(acik.length)];
  c.respondToCrisis(secim.id);
  return true;
}

/// Duruşmada savunma: parası yetiyorsa avukat tutar.
void _handleTrial(GameController c, Random rng, BotProfile profile) {
  final GameState s = c.state!;
  final List<LawyerTier> uygun = kLawyerCatalog
      .where((LawyerTier t) => t.fee == 0 || s.player.wallet >= t.fee)
      .toList(growable: false);
  // Riskli oyuncu ucuza kaçar, temkinli oyuncu en iyi avukatı tutar.
  uygun.sort((LawyerTier a, LawyerTier b) => b.fee.compareTo(a.fee));
  final LawyerTier avukat =
      rng.nextDouble() < 0.6 - profile.riskAppetite * 0.3
          ? uygun.first
          : uygun.last;
  c.respondToTrial(
    stance: rng.nextDouble() < 0.6
        ? DefenceStance.pismanlik
        : DefenceStance.values[rng.nextInt(DefenceStance.values.length)],
    lawyerId: avukat.id,
  );
}

/// Lise alanı: notları ve arketip eğilimi.
void _chooseTrack(GameController c, Random rng) {
  final List<EducationTrackInfo> acik = c.availableTracks();
  if (acik.isEmpty) return;
  // Alanı puanına göre sıralayıp en üsttekini değil, **açık olanlar
  // arasından** seçer: herkes aynı alana yığılmasın.
  c.chooseTrack(acik[rng.nextInt(acik.length)].track);
}

/// Üniversite kararı: **herkes otomatik gitmez**.
///
/// Karar hafızadan gelir (`intent.wantsUniversity`, hayat başında bir kez
/// belirlenir), üstüne para ve puan durumu bakılır. Girişimci bilerek
/// atlayabilir, eğitim odaklı neredeyse her zaman girer.
void _decideUniversity(
  GameController c,
  _Intent intent,
  Random rng,
  BotLifeResult sonuc,
) {
  if (!intent.wantsUniversity) {
    c.skipUniversity();
    return;
  }
  final List<UniversityProgram> acik = c
      .availablePrograms()
      .where((UniversityProgram p) => c.programBlockReason(p).isEmpty)
      .toList(growable: false);
  if (acik.isEmpty) {
    c.skipUniversity();
    return;
  }
  // Puanı en yüksek bölüme değil, **açık bölümler arasından** seçer:
  // herkes aynı bölüme yığılmasın.
  final UniversityProgram secim = acik[rng.nextInt(acik.length)];
  final EducationOutcome? sonucu = c.applyToUniversity(secim);
  if (sonucu?.applied ?? false) {
    sonuc.wentToUniversity = true;
    sonuc.programId = secim.id;
  } else {
    c.skipUniversity();
  }
}

// =====================================================================
// Kariyer
// =====================================================================

/// İş arama, zam/terfi isteme, iş değiştirme, emeklilik.
///
/// **Bot ilk işe girip 50 yıl aynı yerde kalmıyor.** Maaşı piyasanın
/// altındaysa ve profil iş değiştirmeye yatkınsa daha iyisine başvuruyor.
void _handleCareer(
  GameController c,
  BotProfile profile,
  _Intent intent,
  Random rng,
  BotLifeResult sonuc,
) {
  GameState s = c.state!;
  if (s.player.age < 15 || sonuc.retired) return;

  // Emeklilik: hakkı doğduysa ve yaşı ilerlediyse emekli olur. Kariyer
  // odaklı oyuncu biraz daha çalışmayı sürdürür.
  if (c.retirementAvailability().isAllowed) {
    final bool devamEt =
        profile.jobHopping < 0.5 && rng.nextDouble() < 0.35;
    if (!devamEt) {
      final String? mesaj = c.retire();
      if (mesaj != null) {
        sonuc.retired = true;
        return;
      }
    }
  }

  if (!s.career.isEmployed) {
    // İşsiz: açık işler arasından **maaşa göre** seçer ama en yükseğe
    // saplanmaz; uygun olanlar arasından ağırlıklı seçim yapar.
    // Yarım zamanlı iş **yalnızca öğrencilik/gençlik döneminde** kabul
    // edilir. İlk ölçümde bu filtre yoktu ve hayatların %99,3'ü yarım
    // zamanlı iş görüyordu — gerçek oyuncu 40 yaşında kafe garsonluğuna
    // razı olmaz, bu bir bot davranışı hatasıydı.
    final bool yarimZamanliUygun = s.player.age < 25;
    // Teşhis: işsizken açık ilanda görülen her iş sayılır. `openJobs`
    // yalnızca **şartları sağlanan** işleri veriyor, yani buradaki sayaç
    // "bot bu işe girebilir durumdaydı" demektir. Kapalı işlerin
    // gerekçesi de kaydediliyor (M bölümü).
    for (final JobType j in c.openJobs()) {
      sonuc.diag.jobOpenYears[j.id] = (sonuc.diag.jobOpenYears[j.id] ?? 0) + 1;
    }
    c.lockedJobs().forEach((JobType j, String sebep) {
      sonuc.diag.jobLockReason[j.id] = sebep;
    });
    final List<JobType> acik = c
        .openJobs()
        .where((JobType j) =>
            c.jobApplicationAvailability(j).isAllowed &&
            (yarimZamanliUygun || !j.partTime))
        .toList(growable: true);
    if (acik.isEmpty) return;
    acik.sort((JobType a, JobType b) => b.yearlySalary.compareTo(a.yearlySalary));
    // Üst üçte birden seçmeye çalışır; yarım zamanlı işi öğrenciyken
    // kabul eder.
    final int ustSinir = max(1, (acik.length / 3).ceil());
    final JobType secim = rng.nextDouble() < 0.7
        ? acik[rng.nextInt(ustSinir)]
        : acik[rng.nextInt(acik.length)];
    sonuc.diag.jobApplications++;
    sonuc.diag.jobApplied[secim.id] =
        (sonuc.diag.jobApplied[secim.id] ?? 0) + 1;
    final JobOutcome? sonucu = c.applyForJob(secim);
    if (sonucu != null) {
      intent.yearsInCurrentJob = 0;
      if (secim.partTime) sonuc.partTime = true;
    }
    if (!c.state!.career.isEmployed) {
      sonuc.diag.jobFailed[secim.id] =
          (sonuc.diag.jobFailed[secim.id] ?? 0) + 1;
    }
    return;
  }

  // Çalışıyor: kaydı tut.
  sonuc.everEmployed = true;
  final String? isId = s.career.jobId;
  if (isId != null) {
    sonuc.jobIds.add(isId);
    if (intent.lastJobId != null && intent.lastJobId != isId) {
      sonuc.jobChanges++;
      intent.yearsInCurrentJob = 0;
    }
    intent.lastJobId = isId;
  }

  // Zam ve terfi: gerçek oyuncu ister.
  if (c.raiseAvailability().isAllowed && rng.nextDouble() < 0.55) {
    sonuc.raiseAttempts++;
    final String? cevap = c.askForRaise();
    if (cevap != null && !cevap.contains('olmaz') && !cevap.contains('Olmaz')) {
      sonuc.raisesGranted++;
    }
  }
  if (c.promotionAvailability().isAllowed && rng.nextDouble() < 0.6) {
    final String? cevap = c.askForPromotion();
    if (cevap != null) sonuc.promotions++;
  }
  // Ustalık: meslekte ilerlemek için çalışıp öğrenir.
  if (c.studyAvailability().isAllowed && rng.nextDouble() < 0.45) {
    c.study();
  }

  // İş değiştirme: en az 3 yıl aynı işte durduysa ve daha iyi maaşlı
  // açık iş varsa dener. Kararı profil belirler.
  s = c.state!;
  if (intent.yearsInCurrentJob >= 3 && rng.nextDouble() < profile.jobHopping) {
    final int mevcut = s.career.job?.yearlySalary ?? 0;
    final List<JobType> daha = c
        .openJobs()
        .where((JobType j) =>
            j.yearlySalary > mevcut * 1.2 &&
            c.jobApplicationAvailability(j).isAllowed)
        .toList(growable: false);
    if (daha.isNotEmpty) {
      final JobType hedef = daha[rng.nextInt(daha.length)];
      sonuc.diag.jobApplications++;
      sonuc.diag.jobApplied[hedef.id] =
          (sonuc.diag.jobApplied[hedef.id] ?? 0) + 1;
      c.applyForJob(hedef);
    }
  }
}

// =====================================================================
// Para: bütçe, yatırım, konut, girişim, kredi
// =====================================================================

/// Botun bilinçli para yönetimi.
///
/// **Cüzdandaki bütün para rastgele harcanmaz.** Önce yıllık giderin
/// belirli katı kadar yaşam rezervi ayrılır; ancak onun üstündeki para
/// arketipe göre yatırıma, ev peşinatına, iş sermayesine ya da araca
/// gider.
void _handleMoney(
  GameController c,
  BotProfile profile,
  _Intent intent,
  Random rng,
  BotLifeResult sonuc,
) {
  GameState s = c.state!;
  if (s.player.age < 18) return;

  final int yillikGider = max(1, LivingCosts.yearlyCost(s));
  // Rezerv: tasarruf eğilimi yüksek olan daha çok yastık altı tutar.
  final double rezervKat = 1.0 + profile.savingRate * 2.0;
  final int rezerv = (yillikGider * rezervKat).round();
  int serbest() => max(0, c.state!.player.wallet - rezerv);

  // ---- Girişim -----------------------------------------------------
  if (intent.wantsBusiness &&
      s.businesses.isEmpty &&
      s.player.age >= 22 &&
      s.player.age - intent.businessAttemptAge >= 3) {
    intent.businessAttemptAge = s.player.age;
    // Teşhis: her tür için "şart açık mı" ve "sermaye yetiyor mu" ayrı
    // sayılır (N bölümü). Böylece hiç kurulmayan işletmenin sebebi
    // şartta mı sermayede mi belli olur.
    for (final BusinessType t in kBusinessCatalog) {
      final InteractionAvailability u = c.businessOpenAvailability(t);
      if (!u.isAllowed) {
        sonuc.diag.bizLockReason[t.id] = u.reason ?? '';
        continue;
      }
      sonuc.diag.bizAllowedYears[t.id] =
          (sonuc.diag.bizAllowedYears[t.id] ?? 0) + 1;
      if (t.setupCost <= serbest()) {
        sonuc.diag.bizAffordableYears[t.id] =
            (sonuc.diag.bizAffordableYears[t.id] ?? 0) + 1;
      }
    }
    final List<BusinessType> uygun = kBusinessCatalog
        .where((BusinessType t) =>
            c.businessOpenAvailability(t).isAllowed &&
            t.setupCost <= serbest())
        .toList(growable: false);
    if (uygun.isNotEmpty) {
      final BusinessType secim = uygun[rng.nextInt(uygun.length)];
      sonuc.diag.bizAttempted[secim.id] =
          (sonuc.diag.bizAttempted[secim.id] ?? 0) + 1;
      final BusinessOutcome? sonucu = c.openBusinessOf(secim);
      if (sonucu?.applied ?? false) {
        sonuc.ownedBusiness = true;
        sonuc.businessTypes.add(secim.id);
      }
    }
  }
  // İşi varsa ilgilenir, kötü gidiyorsa kapatır.
  final Business? isletme =
      c.state!.businesses.isEmpty ? null : c.state!.businesses.first;
  if (isletme != null) {
    sonuc.ownedBusiness = true;
    sonuc.businessTypes.add(isletme.typeId);
    if (c.businessTendAvailability().isAllowed && rng.nextDouble() < 0.7) {
      c.tendBusiness();
    }
    // Sermaye koyma: parası varsa ve iş ayaktaysa.
    final int yatirim = (serbest() * 0.3).round();
    if (yatirim > 0 &&
        c.businessInvestAvailability(yatirim).isAllowed &&
        rng.nextDouble() < 0.4) {
      c.investInBusiness(yatirim);
    }
    // Zarar ediyorsa devret: üst üste kötü giden işi tutmaz.
    // Toplam kârı eksiye düşen işi bir noktada bırakır: zarar eden işi
    // ömür boyu taşımaz.
    if (isletme.totalProfit < 0 && rng.nextDouble() < 0.25) {
      c.closeBusiness();
    }
  }

  // ---- Oturmak için ev ---------------------------------------------
  s = c.state!;
  final bool eviVar = s.properties.isNotEmpty;
  if (intent.savingForHome &&
      !eviVar &&
      s.player.age >= 24 &&
      s.player.age - intent.homeAttemptAge >= 2) {
    intent.homeAttemptAge = s.player.age;
    _tryBuyHome(c, profile, rng, sonuc, forRental: false, reserve: rezerv);
  }

  // ---- Kiralık ev --------------------------------------------------
  s = c.state!;
  if (intent.wantsRental &&
      s.properties.isNotEmpty &&
      s.player.age >= 28 &&
      s.player.age - intent.rentalAttemptAge >= 3) {
    intent.rentalAttemptAge = s.player.age;
    _tryBuyHome(c, profile, rng, sonuc, forRental: true, reserve: rezerv);
  }
  // Boş yatırım evini kiraya ver.
  _rentOutVacant(c, rng, sonuc);

  // ---- Yatırım -----------------------------------------------------
  if (s.player.age >= kInvestmentMinAge &&
      serbest() >= kInvestmentMinBuy) {
    // Yatırım **yapabilecek** durumda geçen yıl: "bot her yıl mı
    // yatırıyor" sorusunun paydası (Q bölümü).
    sonuc.diag.investOpportunityYears++;
  }
  if (intent.investmentBasket.isNotEmpty) {
    final int pay = (serbest() * (0.25 + profile.savingRate * 0.5)).round();
    if (pay >= kInvestmentMinBuy) {
      final String tur =
          intent.investmentBasket[rng.nextInt(intent.investmentBasket.length)];
      final InvestmentType? tip = investmentTypeById(tur);
      if (tip != null && c.investmentBuyBlockReason(tip, pay).isEmpty) {
        final InvestmentOutcome? sonucu = c.buyInvestment(tur, pay);
        if (sonucu?.applied ?? false) {
          sonuc.investedEver = true;
          sonuc.investmentTypes.add(tur);
          sonuc.diag.investBuys++;
          sonuc.diag.investedPrincipalEver += pay;
        }
      }
    }
  }

  // ---- Araç --------------------------------------------------------
  s = c.state!;
  if (!s.items.any((OwnedItem i) => i.isVehicle) &&
      s.player.age >= 20 &&
      rng.nextDouble() < 0.12) {
    final ShopProduct? arac = shopProductsFor(s.player.age).firstWhereOrNullBot(
      (ShopProduct p) =>
          p.price <= serbest() * 0.6 &&
          itemTypeOrFallback(p.typeId).kind == ItemKind.otomobil,
    );
    if (arac != null) {
      final ItemOutcome? sonucu = c.buyProduct(arac);
      if (sonucu?.applied ?? false) sonuc.ownedVehicle = true;
    }
  }

  // ---- Kredi borcu -------------------------------------------------
  s = c.state!;
  if (s.loans.isNotEmpty) {
    sonuc.usedLoan = true;
    // Parası bolsa borcu kapatır: borç yükünü kontrol eder.
    final Loan borc = s.loans.first;
    if (serbest() > borc.outstanding && rng.nextDouble() < 0.4) {
      c.payOffLoan(borc.id);
    }
  }
}

/// Ev almayı dener: nakit yetmezse **konut kredisi** kullanır.
void _tryBuyHome(
  GameController c,
  BotProfile profile,
  Random rng,
  BotLifeResult sonuc, {
  required bool forRental,
  required int reserve,
}) {
  final List<ShopProduct> evler = shopProductsFor(c.state!.player.age)
      .where((ShopProduct p) =>
          itemTypeOrFallback(p.typeId).kind == ItemKind.konut)
      .toList(growable: true);
  if (evler.isEmpty) return;
  evler.sort((ShopProduct a, ShopProduct b) => a.price.compareTo(b.price));

  // **Tek hedef, tek kredi denemesi.** İlk yazdığımda döngü her ev için
  // ayrı ayrı kredi çekiyordu: en ucuz ev tutmayınca bir sonrakine geçip
  // yeni kredi alıyordu ve bot bir yılda üst üste kredi yığıyordu. Bu
  // gerçek bir bot hatasıydı ve serveti şişiriyordu.
  final int serbest = max(0, c.state!.player.wallet - reserve);
  // Nakit yetiyorsa en pahalı karşılanabilir ev; yetmiyorsa en ucuzu
  // hedeflenir ve **bir kez** kredi denenir.
  final ShopProduct hedef = evler.lastWhere(
    (ShopProduct p) => p.price <= serbest,
    orElse: () => evler.first,
  );

  if (c.state!.player.wallet < hedef.price &&
      rng.nextDouble() < profile.usesLoan &&
      c.state!.loans.isEmpty) {
    // Banka geliri değerlendirir; bot kuralı atlamaz. Zaten kredisi olan
    // üstüne ikinci konut kredisi çekmez.
    final int eksik = hedef.price - c.state!.player.wallet;
    final LoanDecision? karar = c.applyForLoan(
      bank: Bank.bankavrupa,
      amount: eksik,
      termYears: Banking.maxTermFor(LoanPurpose.konut),
      purpose: LoanPurpose.konut,
    );
    if (karar?.approved ?? false) sonuc.usedLoan = true;
  }

  if (c.state!.player.wallet < hedef.price) return;
  final ItemOutcome? sonucu = c.buyProduct(
    hedef,
    location: c.state!.player.currentCity,
  );
  if (!(sonucu?.applied ?? false)) return;
  if (forRental) {
    sonuc.ownedRental = true;
  } else {
    sonuc.ownedHome = true;
    // İlk ev oturmak için: gerçekten taşınır.
    final OwnedItem yeni = c.state!.properties.last;
    if (c.moveBlockReason(yeni).isEmpty) c.moveInto(yeni);
  }
}

/// Boş yatırım evlerini gerçek akışla kiraya verir.
void _rentOutVacant(GameController c, Random rng, BotLifeResult sonuc) {
  final GameState s = c.state!;
  for (final OwnedItem ev in s.properties) {
    if (ev.id == s.residenceItemId) continue;
    if (c.leaseOf(ev) != null) {
      sonuc.letProperty = true;
      continue;
    }
    final int piyasa = c.marketRent(ev);
    if (piyasa <= 0) continue;
    // Gerçek oyuncu gibi: piyasa civarında bir rakam ister, tutmazsa
    // biraz aşağı çeker.
    for (final double oran in <double>[1.05, 1.0, 0.95]) {
      final int istenen = (piyasa * oran).round();
      if (c.rentOutAskBlockReason(ev, istenen).isNotEmpty) continue;
      final List<TenantRecord> adaylar = c.tenantCandidatesFor(ev, istenen);
      if (adaylar.isEmpty) continue;
      // Kiracıyı seçer: ödeme geçmişi iyi olanı tercih eder ama garanti
      // değil.
      adaylar.sort((TenantRecord a, TenantRecord b) =>
          a.track.index.compareTo(b.track.index));
      final TenantRecord secim = rng.nextDouble() < 0.7
          ? adaylar.first
          : adaylar[rng.nextInt(adaylar.length)];
      final RentalOutcome? sonucu = c.signLease(
        home: ev,
        tenant: secim,
        yearlyRent: istenen,
      );
      if (sonucu?.applied ?? false) sonuc.letProperty = true;
      break;
    }
  }
  // Kondisyonu düşen evi onarır.
  for (final OwnedItem ev in c.state!.properties) {
    if (ev.condition < 55 &&
        c.upkeepBlockReason(ev, major: false).isEmpty &&
        rng.nextDouble() < 0.6) {
      c.upkeepProperty(ev, major: false);
    }
  }
}

// =====================================================================
// İlişki ve aile
// =====================================================================

/// İlişki kurma, evlenme, çocuk, arkadaşlık.
///
/// **İlişkiler yalnızca olay şansına bırakılmıyor:** bot Finger'ı açıyor,
/// çıkma teklif ediyor, flörtü resmîleştiriyor, evlenme teklif ediyor ve
/// eşiyle/çocuklarıyla vakit geçiriyor. Bekar kalmak da geçerli bir hayat:
/// `wantsMarriage` yanlışsa bot evlenmeye çalışmıyor.
void _handleRelationships(
  GameController c,
  BotProfile profile,
  _Intent intent,
  Random rng,
  BotLifeResult sonuc,
) {
  GameState s = c.state!;
  if (s.player.age < 14) {
    // Çocukken aileyle vakit geçirmek: yakınlık sönmesin.
    _spendTimeWithFamily(c, profile, rng, sonuc);
    return;
  }
  if (s.player.age >= MarriageEngine.prototypeOnlyMinAge) {
    sonuc.diag.reachedRomanceAge = true;
  }

  // Teşhis: "bu hayatta evlenmek istedi mi" **botun kendi okuduğu
  // yerde** kaydedilir. İlk yazımda bunu hayatın başında okumuştum;
  // `_Intent`'in `late final` alanları erişim sırasına göre zar attığı
  // için bu, bütün niyet zarlarının sırasını kaydırdı ve ölçüm eskiyle
  // karşılaştırılamaz hale geldi (ölüm yaşı 74,1 → 74,2, üniversite
  // %48,5 → %47,4). Teşhis akışa dokunmamalı.
  sonuc.diag.wantedMarriage = intent.wantsMarriage;
  // Finger: partner arayan oyuncu uygulamayı kullanır.
  if (intent.wantsMarriage &&
      s.player.age >= 18 &&
      !s.isMarried &&
      s.people.every((Person p) =>
          p.relation != RelationType.sevgili &&
          p.relation != RelationType.flort) &&
      rng.nextDouble() < 0.5) {
    c.fillFingerDeck();
    final List<FingerProfile> deste = c.state!.fingerDeck;
    if (deste.isNotEmpty) {
      sonuc.usedFinger = true;
      sonuc.diag.sawCandidate = true;
      if (sonuc.diag.separationAge != null) {
        sonuc.diag.postSepCandidate = true;
      }
      final FingerProfile profil = deste[rng.nextInt(deste.length)];
      c.likeFingerProfile(profil.id);
      c.meetFingerMatch(profil.id);
    }
  }

  s = c.state!;
  // Flört → sevgili → nişan → evlilik yolunu yürütür.
  for (final Person p in s.people) {
    if (!p.isAlive) continue;
    if (p.relation == RelationType.flort) {
      sonuc.everPartner = true;
      sonuc.diag.sawCandidate = true;
      sonuc.diag.flirted = true;
      if (sonuc.diag.separationAge != null) {
        sonuc.diag.postSepCandidate = true;
        sonuc.diag.postSepFlirt = true;
      }
      if (c.officialAvailability(p.id).isAllowed && rng.nextDouble() < 0.7) {
        c.makeRelationshipOfficial(p.id);
      }
      break;
    }
    if (p.relation == RelationType.sevgili) {
      sonuc.everPartner = true;
      sonuc.diag.sawCandidate = true;
      _trackProposalFunnel(c: c, partner: p, diag: sonuc.diag);
      // **Evlenmek isteyen oyuncu ilişkisine yatırım yapar.** İlk
      // ölçümde bot sevgilisine özel zaman ayırmıyordu: rastgele bir
      // yakınla vakit geçiriyordu, sevgilinin yakınlığı evlilik eşiğine
      // (45) çıkmıyordu ve aile odaklı arketipte bile evlilik oranı
      // %43'te kalıyordu. Bu bir bot davranışı hatasıydı.
      if (intent.wantsMarriage && p.bond < 60) {
        final List<InteractionKind> acik = c.availableKindsFor(p);
        if (acik.isNotEmpty) {
          sonuc.diag.interactions++;
          c.interact(p.id, acik[rng.nextInt(acik.length)]);
          while (c.state!.hasNotice) {
            c.dismissNotice();
          }
          if (c.state!.hasPendingEvent) return;
        }
      }
      // **`!isMarried`, `marriage == null` değil.** Botta da üretim
      // kodundaki aynı hata vardı (Q-167/3): boşanmadan sonra evlilik
      // kaydı silinmediği için bot bir daha hiç teklif etmiyordu.
      // `finger.dart` düzeltildikten sonra ayrılık sonrası huni
      // flört %47,5 / sevgili %8,5'e çıktı ama "teklif etti" %0'da
      // kaldı — kalan sıfır botun kendi kapısıydı.
      if (intent.wantsMarriage &&
          !c.state!.isMarried &&
          c.state!.player.age >= 20 &&
          c.proposalAvailability(p.id).isAllowed &&
          rng.nextDouble() < 0.7) {
        sonuc.diag.proposed = true;
        sonuc.diag.proposalAttempts++;
        if (sonuc.diag.separationAge != null) {
          sonuc.diag.postSepProposed = true;
        }
        c.propose(p.id);
      }
      break;
    }
  }

  // Boşanma: mutsuz evlilik sonsuza kadar sürmez. İlk ölçümde bot hiç
  // boşanmıyordu ve "boşanan %0,0" çıkıyordu — metrik anlamsızdı.
  s = c.state!;
  final Person? es = s.spouse;
  if (es != null && s.player.age >= 25) {
    final bool mutsuz = es.bond < 25 || s.player.stats.happiness < 25;
    final double sans = mutsuz ? 0.18 : 0.012;
    if (rng.nextDouble() < sans &&
        c.divorceAvailability().isAllowed) {
      c.divorce();
      while (c.state!.hasNotice) {
        c.dismissNotice();
      }
      return;
    }
  }

  // Çocuk: **oyun evlilik şartı koymuyor** — eş ya da sevgili yeterli
  // (D-047). İlk ölçümde bot yalnızca evliyken deniyordu ve "çocuklu
  // %5,4" çıkıyordu; bot oyundan daha katı davranıyordu. Çocuk isteyen
  // oyuncu ısrarcıdır, bu yüzden deneme ihtimali de yükseltildi.
  s = c.state!;
  if (intent.wantsChildren &&
      s.player.age >= 22 &&
      rng.nextDouble() < 0.6 &&
      c.childAvailability().isAllowed) {
    c.haveChild();
    while (c.state!.hasNotice) {
      c.dismissNotice();
    }
    if (c.state!.hasPendingEvent) return;
  }

  // Kısırlık çıktıysa tedaviyi dener: aile odaklı oyuncu vazgeçmez.
  if (intent.wantsChildren &&
      s.children.isEmpty &&
      s.player.age >= 30 &&
      profile.familyDesire > 0.6 &&
      rng.nextDouble() < 0.25) {
    c.tryFertilityTreatment();
  }

  // Yakın arkadaşlık: sosyal oyuncu teklif eder.
  for (final Person p in c.state!.people) {
    if (!p.isAlive) continue;
    if (p.relation == RelationType.arkadas &&
        c.closeFriendAvailability(p.id).isAllowed &&
        rng.nextDouble() < profile.socialDesire) {
      c.proposeCloseFriend(p.id);
      break;
    }
    // Küslük varsa barışmayı dener.
    if (c.makeUpAvailability(p.id).isAllowed && rng.nextDouble() < 0.4) {
      c.makeUp(p.id);
      break;
    }
  }

  _spendTimeWithFamily(c, profile, rng, sonuc);
}

/// Eş, çocuk ve ebeveynle vakit geçirir. Yakınlık kendiliğinden sönüyor;
/// gerçek oyuncu buna müdahale eder.
void _spendTimeWithFamily(
  GameController c,
  BotProfile profile,
  Random rng,
  BotLifeResult sonuc,
) {
  final GameState s = c.state!;
  final List<Person> yakinlar = s.people
      .where((Person p) =>
          p.isAlive &&
          (p.relation == RelationType.es ||
              p.relation == RelationType.cocuk ||
              p.relation == RelationType.anne ||
              p.relation == RelationType.baba ||
              p.relation == RelationType.sevgili))
      .toList(growable: false);
  if (yakinlar.isEmpty) return;
  // Yılda bir-iki kişiyle: her yıl herkesle uğraşmak gerçekçi değil.
  final int adet = rng.nextDouble() < profile.familyDesire ? 2 : 1;
  for (int i = 0; i < adet && i < yakinlar.length; i++) {
    final Person kisi = yakinlar[rng.nextInt(yakinlar.length)];
    final List<InteractionKind> acik = c.availableKindsFor(kisi);
    if (acik.isEmpty) continue;
    sonuc.diag.interactions++;
    c.interact(kisi.id, acik[rng.nextInt(acik.length)]);
    while (c.state!.hasNotice) {
      c.dismissNotice();
    }
    if (c.state!.hasPendingEvent) return;
  }
}

// =====================================================================
// Aktiviteler: hobi, spor, sağlık, sosyal medya, gezi, evcil hayvan
// =====================================================================

/// Gerçek oyuncu yalnızca "Yaş Al"a basmaz.
///
/// Bot yılda birkaç aksiyon yapıyor — her yıl yirmi tane değil, ama hayat
/// boyunca sistemleri gerçekten kullanacak kadar. Hobi ve dövüş sanatı
/// hafızadan geliyor: her yıl başka bir hobiye atlamıyor.
void _handleActivities(
  GameController c,
  BotProfile profile,
  _Intent intent,
  Random rng,
  BotLifeResult sonuc,
) {
  GameState s = c.state!;
  if (s.player.age < 7) return;

  bool kesildiMi() {
    while (c.state!.hasNotice) {
      c.dismissNotice();
    }
    return c.state!.hasPendingEvent;
  }

  // ---- Hobi --------------------------------------------------------
  final HobbyKind? hobi = intent.favouriteHobby;
  if (hobi != null && rng.nextDouble() < 0.6) {
    for (final String id in hobi.activityIds) {
      final ActivityAction? eylem = _actionByIdBot(id);
      if (eylem == null) continue;
      if (c.activityAvailability(eylem).isAllowed) {
        sonuc.diag.activityActions++;
        c.performActivity(eylem);
        sonuc.hobbies.add(hobi.id);
        if (kesildiMi()) return;
        break;
      }
    }
  }

  // ---- Spor / dövüş sanatı -----------------------------------------
  if (rng.nextDouble() < profile.sportDesire) {
    final ActivityAction? kosu = _actionByIdBot('kosu');
    if (kosu != null && c.activityAvailability(kosu).isAllowed) {
      sonuc.diag.activityActions++;
      sonuc.diag.sportActions++;
      c.performActivity(kosu);
      sonuc.didSport = true;
      if (kesildiMi()) return;
    }
  }
  final MartialArt? sanat = intent.favouriteArt;
  if (sanat != null && rng.nextDouble() < 0.5) {
    if (c.martialAvailability(sanat).isAllowed) {
      sonuc.diag.activityActions++;
      sonuc.diag.sportActions++;
      c.takeMartialSeason(sanat);
      sonuc.martialArts.add(sanat.id);
      sonuc.didSport = true;
      if (kesildiMi()) return;
    }
  }

  // ---- Sağlık: check-up ve kronik bakımı ---------------------------
  s = c.state!;
  if (rng.nextDouble() < profile.healthCare * 0.5) {
    final ActivityAction? checkup = _actionByIdBot('genel_kontrol');
    if (checkup != null && c.activityAvailability(checkup).isAllowed) {
      sonuc.diag.activityActions++;
      sonuc.diag.checkupActions++;
      c.performActivity(checkup);
      sonuc.checkup = true;
      if (kesildiMi()) return;
    }
  }
  for (final ChronicCondition kronik in c.state!.chronicConditions) {
    sonuc.chronic = true;
    if (rng.nextDouble() < profile.healthCare) {
      c.careForChronic(kronik.typeId);
      if (kesildiMi()) return;
    }
    break;
  }

  // ---- Sosyal medya ------------------------------------------------
  s = c.state!;
  if (intent.wantsSocial && s.player.age >= 16) {
    if (s.socialAccounts.isEmpty) {
      for (final SocialPlatform p in SocialPlatform.values) {
        if (c.socialAccountAvailability(p).isAllowed) {
          final SocialOutcome? sonucu = c.openSocialAccount(p);
          if (sonucu?.applied ?? false) sonuc.openedSocial = true;
          break;
        }
      }
      if (kesildiMi()) return;
    }
    final GameState g = c.state!;
    if (g.socialAccounts.isNotEmpty && rng.nextDouble() < 0.7) {
      final SocialPlatform p = g.socialAccounts.first.platform;
      final List<SocialContent> icerik = contentsFor(p);
      if (icerik.isNotEmpty && c.remainingSocialPosts(p) > 0) {
        c.postContent(icerik[rng.nextInt(icerik.length)]);
        if (kesildiMi()) return;
      }
    }
    // Sponsorluk teklifi varsa değerlendir.
    if (c.state!.sponsorOffer != null) {
      if (rng.nextDouble() < 0.8) {
        c.acceptSponsor();
      } else {
        c.declineSponsor();
      }
      if (kesildiMi()) return;
    }
  }

  // ---- Eğlence / bakım: mutluluk ve görünüş ------------------------
  s = c.state!;
  if (s.player.stats.happiness < 55 && rng.nextDouble() < 0.5) {
    final ActivityAction? eglence = _actionByIdBot('sinema');
    if (eglence != null && c.activityAvailability(eglence).isAllowed) {
      sonuc.diag.activityActions++;
      c.performActivity(eglence);
      if (kesildiMi()) return;
    }
  }
  if (s.player.age >= 18 &&
      s.player.stats.appearance < 60 &&
      rng.nextDouble() < profile.socialDesire * 0.6) {
    final ActivityAction? berber = _actionByIdBot('berber_sac');
    if (berber != null && c.activityAvailability(berber).isAllowed) {
      sonuc.diag.activityActions++;
      c.performActivity(berber);
      if (kesildiMi()) return;
    }
  }

  // ---- Gezi: yanına birini alarak ----------------------------------
  s = c.state!;
  if (s.player.age >= 20 && rng.nextDouble() < 0.10) {
    final List<String> yerler = c.travelDestinations();
    final List<Person> yoldaslar = c.travelCompanions();
    final List<TravelMode> modlar = c.travelModes();
    if (yerler.isNotEmpty && modlar.isNotEmpty) {
      final String yer = yerler[rng.nextInt(yerler.length)];
      final TravelMode mod = modlar[rng.nextInt(modlar.length)];
      final Person? yoldas =
          yoldaslar.isEmpty ? null : yoldaslar[rng.nextInt(yoldaslar.length)];
      if (c
          .travelAvailability(mode: mod, city: yer, companionId: yoldas?.id)
          .isAllowed) {
        final TripOutcome? sonucu = c.takeTrip(
          mode: mod,
          city: yer,
          companionId: yoldas?.id,
        );
        if (sonucu?.applied ?? false) sonuc.traveled = true;
        if (kesildiMi()) return;
      }
    }
  }

  // ---- Evcil hayvan ------------------------------------------------
  s = c.state!;
  if (s.pets.isEmpty && s.player.age >= 12 && rng.nextDouble() < 0.06) {
    for (final PetSpecies tur in PetSpecies.values) {
      if (c.petAdoptionAvailability(tur).isAllowed) {
        final String? mesaj = c.adoptPet(tur, 'Zeytin');
        if (mesaj != null) sonuc.hadPet = true;
        break;
      }
    }
    if (kesildiMi()) return;
  }
  if (c.state!.pets.isNotEmpty) {
    sonuc.hadPet = true;
    final Pet hayvan = c.state!.pets.first;
    for (final PetAction eylem in PetAction.values) {
      if (c.petActionAvailability(hayvan, eylem).isAllowed &&
          rng.nextDouble() < 0.4) {
        c.petInteract(hayvan, eylem);
        break;
      }
    }
    if (kesildiMi()) return;
  }

  // ---- Kumar: yalnızca riskli oyuncu, küçük bahisle ---------------
  if (profile.riskAppetite > 0.7 &&
      c.state!.player.age >= 18 &&
      rng.nextDouble() < 0.12) {
    final List<int> adimlar = c.betSteps();
    if (adimlar.isNotEmpty && c.casinoAvailability().isAllowed) {
      final int bahis = adimlar.first;
      if (c.betAvailability(bahis).isAllowed) {
        c.dealBlackjack(bahis);
        c.standBlackjack();
        c.closeBlackjackHand();
        sonuc.gambled = true;
      }
    }
    if (kesildiMi()) return;
  }
}

ActivityAction? _actionByIdBot(String id) {
  for (final ActivityAction a in kActivityActions) {
    if (a.id == id) return a;
  }
  return null;
}

// =====================================================================
// Son metrikler
// =====================================================================

void _collectFinalMetrics(GameController c, BotLifeResult sonuc) {
  final GameState s = c.state!;
  sonuc.deathAge = s.player.age;
  sonuc.endedByDeath = s.deceased;
  sonuc.finalNetWorth = NetWorth.of(s);
  sonuc.finalDebt = NetWorth.debt(s);
  sonuc.finalHealth = s.player.stats.health;
  sonuc.finalFame = s.totalFollowers;

  sonuc.graduatedUniversity = s.education.universityFinished;
  sonuc.programId ??= s.education.universityProgramId;
  if (s.education.universityProgramId != null) {
    sonuc.wentToUniversity = true;
  }

  sonuc.ownedHome = s.properties.isNotEmpty;
  sonuc.ownedRental = s.properties
      .where((OwnedItem i) => i.id != s.residenceItemId)
      .isNotEmpty;
  sonuc.letProperty = sonuc.letProperty || s.leases.isNotEmpty;
  sonuc.ownedVehicle =
      sonuc.ownedVehicle || s.items.any((OwnedItem i) => i.isVehicle);
  sonuc.investedEver = sonuc.investedEver || s.investmentHistory.isNotEmpty;
  for (final Holding h in s.investments) {
    sonuc.investmentTypes.add(h.typeId);
  }
  if (s.termDeposits.isNotEmpty) sonuc.investmentTypes.add('vadeli');
  sonuc.usedLoan = sonuc.usedLoan || s.loans.isNotEmpty;

  // Bir kez evlenmiş olmak: kayıt varsa evlenmiştir (boşanmış olsa da).
  // Burada `marriage != null` **doğru** soru: "hiç evlendi mi?"
  sonuc.married = sonuc.married || s.marriage != null;
  sonuc.divorced = s.pastMarriages
          .any((Marriage m) => m.status == MarriageStatus.bosandi) ||
      s.marriage?.status == MarriageStatus.bosandi;
  // Tekrar evlenmiş olmak: geçmişte evlilik var **ve** şu an yürüyen
  // bir evlilik var. Boşanmış kayıt "yürüyen" sayılmamalı, o yüzden
  // `isMarried`.
  sonuc.remarried = s.pastMarriages.isNotEmpty && s.isMarried;
  sonuc.childCount = s.children.length;
  sonuc.sawGrandchild =
      s.people.any((Person p) => p.relation == RelationType.torun);

  sonuc.friendCount = s.people
      .where((Person p) => p.isAlive && p.relation == RelationType.arkadas)
      .length;
  sonuc.closeFriendCount = s.people
      .where((Person p) =>
          p.isAlive &&
          p.relation == RelationType.arkadas &&
          p.becameFriendAtAge != null)
      .length;
  sonuc.estranged = s.people.any((Person p) => p.estrangedSinceAge != null);
  sonuc.openedSocial = sonuc.openedSocial || s.socialAccounts.isNotEmpty;

  sonuc.chronic = sonuc.chronic || s.chronicConditions.isNotEmpty;
  sonuc.hasRecord = s.legal.hasRecord;
  sonuc.imprisoned =
      s.legal.cases.any((CriminalCase x) => x.verdict == Verdict.hapis);
  // "Mahkemeye çıkan" = gerçekten bir karara bağlanmış dosyası olan.
  // İlk ölçümde bu `cases.isNotEmpty` idi ve açılmış her dosyayı
  // duruşma sayıyordu; oran %51 çıkıyordu, metrik yanlıştı.
  sonuc.wentToTrial = sonuc.wentToTrial ||
      s.legal.cases.any((CriminalCase x) => x.verdict != Verdict.yok);
  for (final CriminalCase x in s.legal.cases) {
    sonuc.crimeIds.add(x.crimeId);
  }

  sonuc.masteryReputation = CraftMastery.reputationOf(s);
  for (final HobbyProgress h in s.hobbies) {
    sonuc.hobbies.add(h.hobbyId);
  }
  for (final MartialProgress m in s.martialArts) {
    sonuc.martialArts.add(m.artId);
  }
  if (s.businesses.isNotEmpty) {
    sonuc.ownedBusiness = true;
    for (final Business b in s.businesses) {
      sonuc.businessTypes.add(b.typeId);
    }
  }
}

/// Bebeğe verilecek ad. Mevcut adından **farklı** olmalı, yoksa isim
/// penceresi kapanmıyor.
String _botChildName(Person baby, Random rng) {
  const List<String> havuz = <String>[
    'Ada', 'Deniz', 'Ege', 'Mira', 'Aras', 'Nehir', 'Can', 'Eylül',
  ];
  final List<String> uygun =
      havuz.where((String ad) => ad != baby.firstName).toList(growable: false);
  return uygun[rng.nextInt(uygun.length)];
}
