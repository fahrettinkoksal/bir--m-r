import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/activity_catalog.dart';
import '../data/education_tracks.dart';
import '../data/item_catalog.dart';
import '../data/job_catalog.dart';
import '../data/save/save_service.dart';
import '../data/shop_catalog.dart';
import '../data/social_catalog.dart';
import '../data/university_catalog.dart';

import '../domain/generation/generation_continuation.dart';
import '../domain/generation/life_generator.dart';
import '../domain/generation/life_progression.dart';
import '../domain/effects/effect_diff.dart';
import '../domain/events/event_engine.dart';
import '../domain/models/applied_effect.dart';
import '../domain/interaction/family_interactions.dart';
import '../domain/activities/activity_engine.dart';
import '../domain/career/career_progress.dart';
import '../domain/career/job_market.dart';
import '../domain/career/retirement.dart';
import '../domain/education/education_path.dart';
import '../domain/education/school_performance.dart';
import '../domain/interaction/adoption.dart';
import '../domain/life/notices.dart';
import '../domain/life/life_verdict.dart';
import '../domain/life/will.dart';
import '../domain/models/pending_notice.dart';
import '../domain/interaction/item_actions.dart';
import '../data/license_catalog.dart';
import '../domain/casino/blackjack.dart';
import '../data/health_crisis_catalog.dart';
import '../domain/economy/housing.dart';
import '../domain/education/school_transfer.dart';
import '../domain/life/health_crisis_engine.dart';
import '../domain/models/pending_crisis.dart';
import '../domain/casino/casino_rules.dart';
import '../domain/licensing/license_office.dart';
import '../domain/models/pending_license_exam.dart';
import '../domain/casino/horse_race.dart';
import '../domain/casino/roulette.dart';
import '../domain/models/blackjack_game.dart';
import '../domain/models/game_settings.dart';
import '../domain/models/life_log.dart';
import '../domain/models/life_summary.dart';
import '../domain/models/marriage.dart';
import '../domain/activities/travel.dart';
import '../domain/models/sponsorship.dart';
import '../domain/models/trip.dart';
import '../domain/social/social_engine.dart';
import '../data/military_catalog.dart';
import '../domain/career/military_service.dart';
import '../domain/interaction/intimacy.dart';
import '../domain/interaction/marriage_engine.dart';
import '../domain/interaction/parenthood.dart';
import '../domain/interaction/romance.dart';
import '../domain/models/game_event.dart';
import '../domain/models/game_state.dart';
import '../domain/models/gender.dart';
import '../domain/models/interaction.dart';
import '../domain/models/owned_item.dart';
import '../domain/models/pending_interview.dart';
import '../domain/models/person.dart';

/// Uygulamanın tek durum sahibi.
///
/// Harici bir durum yönetimi paketine bağlı değildir; yeni sekmeler ve
/// sistemler eklendiğinde bu sınıfın üzerine modül eklenebilir.
class GameController extends ChangeNotifier {
  GameController({Random? random, SaveService? saveService})
      : _random = random ?? Random(),
        _saveService = saveService;

  final Random _random;
  final FamilyInteractions _interactions = const FamilyInteractions();
  final EventEngine _events = const EventEngine();
  final Romance _romance = const Romance();
  final MarriageEngine _marriages = const MarriageEngine();
  final Parenthood _parenthood = const Parenthood();
  final ItemActions _items = const ItemActions();
  final EducationPath _education = const EducationPath();
  final JobMarket _jobs = const JobMarket();
  final ActivityEngine _activities = const ActivityEngine();
  final SocialEngine _social = const SocialEngine();
  final Blackjack _blackjack = const Blackjack();
  final Roulette _roulette = const Roulette();
  final LicenseOffice _licenses = const LicenseOffice();
  final Housing _housing = const Housing();
  final HealthCrisisEngine _crises = const HealthCrisisEngine();

  /// Kayıt servisi. `null` ise oyun yalnızca bellekte çalışır (testler).
  final SaveService? _saveService;

  GameState? _state;

  /// Yazma işlemleri sıraya alınır: iki kayıt birbirinin üzerine binmez.
  Future<void> _saveChain = Future<void>.value();

  /// Okunamayan bir kayıt bulunduğunda otomatik kayıt durdurulur.
  ///
  /// Böylece bozuk dosyanın üzerine habersizce yazılmaz; kullanıcı yeni bir
  /// hayat başlatmayı onaylayana kadar dosyaya dokunulmaz.
  bool _autoSaveBlocked = false;

  /// Cihazda kayıt var mı? Açılışta [checkForSavedLife] ile doldurulur.
  bool _hasSavedLife = false;

  /// Okunamayan kayıt için kullanıcıya gösterilecek açıklama.
  String? _saveProblem;

  GameState? get state => _state;

  bool get hasLife => _state != null;

  /// Cihazda devam edilebilecek bir kayıt bulundu mu?
  bool get hasSavedLife => _hasSavedLife;

  /// Kayıt okunamadıysa nedeni; sorun yoksa `null`.
  String? get saveProblem => _saveProblem;

  /// Kayıt sistemi etkin mi?
  bool get savingEnabled => _saveService != null;

  /// Açılışta kayıt olup olmadığına bakar.
  Future<void> checkForSavedLife() async {
    final SaveService? service = _saveService;
    if (service == null) return;
    _hasSavedLife = await service.hasSave();
    notifyListeners();
  }

  /// Kayıtlı hayatı yükler ve sonucu bildirir.
  ///
  /// Kayıt bozuksa durum değişmez, dosyaya dokunulmaz ve sebep
  /// [saveProblem] üzerinden okunabilir.
  Future<SaveLoadStatus> restoreSavedLife() async {
    final SaveService? service = _saveService;
    if (service == null) return SaveLoadStatus.yok;

    final SaveLoadResult result = await service.load();
    switch (result.status) {
      case SaveLoadStatus.yuklendi:
        _state = result.state;
        _hasSavedLife = true;
        _saveProblem = null;
        _autoSaveBlocked = false;
      case SaveLoadStatus.bozuk:
        // Bozuk kaydın üzerine yazma: kullanıcı karar verene kadar dokunma.
        _hasSavedLife = true;
        _saveProblem = result.message;
        _autoSaveBlocked = true;
      case SaveLoadStatus.yok:
        _hasSavedLife = false;
        _saveProblem = null;
    }
    notifyListeners();
    return result.status;
  }

  /// Kayıtlı hayatı **açıkça** siler. Yalnızca kullanıcı onayıyla çağrılır.
  Future<void> deleteSavedLife() async {
    final SaveService? service = _saveService;
    if (service == null) return;
    await _saveChain;
    await service.clear();
    _hasSavedLife = false;
    _saveProblem = null;
    _autoSaveBlocked = false;
    notifyListeners();
  }

  /// Oyun durumunu değiştiren her anlamlı işlemden sonra otomatik kayıt.
  ///
  /// Arayüzü bekletmemek için eşzamansız çalışır; testler [flushSaves] ile
  /// yazmanın bitmesini bekleyebilir.
  void _autoSave() {
    final SaveService? service = _saveService;
    final GameState? current = _state;
    if (service == null || current == null || _autoSaveBlocked) return;
    _hasSavedLife = true;
    _saveChain = _saveChain.then((_) => service.save(current)).catchError(
      (Object error) {
        // Kayıt yazılamadıysa oyun durmaz; sorun kullanıcıya bildirilir.
        _saveProblem = 'Oyun kaydedilemedi: $error';
      },
    );
  }

  /// Bekleyen kayıt yazmalarının bitmesini bekler.
  Future<void> flushSaves() => _saveChain;

  /// Yeni bir hayat başlatır (D-005 iki başlangıç modu).
  ///
  /// [seed] verilirse üretim tekrarlanabilir olur; verilmezse her oyuncu
  /// farklı bir hayat görür.
  void startNewLife({
    required StartMode mode,
    String? firstName,
    Gender? gender,
    int? seed,
  }) {
    // Tamamlanmış hayat varsa özeti **önce arşivlenir**; yeni hayat geçmiş
    // hayat özetini silmez (D-037).
    final List<LifeSummary> arsiv = _archiveWithCurrentLife();

    final int usedSeed = seed ?? _random.nextInt(1 << 32);
    final LifeGenerator generator = LifeGenerator.seeded(usedSeed);
    _state = generator
        .generate(
          mode: mode,
          chosenFirstName: mode == StartMode.isimVeCinsiyet ? firstName : null,
          chosenGender: mode == StartMode.isimVeCinsiyet ? gender : null,
        )
        .copyWith(
          pastLives: List<LifeSummary>.unmodifiable(arsiv),
          settings: _state?.settings ?? const GameSettings(),
        );
    // Yeni hayat, bozuk kayıt engelini kaldırır: oyuncu bilerek baştan
    // başladı, artık yazmak güvenli.
    _autoSaveBlocked = false;
    _saveProblem = null;
    _autoSave();
    notifyListeners();
  }

  /// Kuşak devamında seçilebilecek çocuklar (Paket E3).
  ///
  /// Hayat tamamlanmadıysa veya hayatta çocuk yoksa liste boştur; arayüz
  /// o zaman hiçbir seçenek göstermez (sahte düğme olmaz, D-038).
  List<Person> get generationHeirs {
    final GameState? state = _state;
    return state == null
        ? const <Person>[]
        : GenerationContinuation.heirs(state);
  }

  bool get canContinueGeneration => generationHeirs.isNotEmpty;

  /// **Çocuğum olarak devam et** (Paket E3).
  ///
  /// Tamamlanan hayat önce arşivlenir, sonra seçilen çocuğun kaydıyla
  /// devam edilir. Engel varsa durum **değişmez** ve gerekçe döner; boş
  /// metin başarı demektir.
  String continueAsChild(String childId) {
    final GameState? state = _state;
    if (state == null) return 'Devam edilecek bir hayat yok.';

    final List<LifeSummary> arsiv = _archiveWithCurrentLife();
    final ({GameState? state, String blockReason}) sonuc =
        GenerationContinuation.continueAs(state, childId, _random);
    final GameState? yeni = sonuc.state;
    if (yeni == null) return sonuc.blockReason;

    _state = yeni.copyWith(
      pastLives: List<LifeSummary>.unmodifiable(arsiv),
    );
    // Yeni kuşak bilinçli bir seçimdir; kayıt yazmak güvenli.
    _autoSaveBlocked = false;
    _saveProblem = null;
    _autoSave();
    notifyListeners();
    return '';
  }

  /// **Yaş Al** (D-018).
  ///
  /// Ekranda çözülmemiş bir olay varken çalışmaz; böylece olaylar üst üste
  /// binmez.
  /// Oyuncu vefat etti mi? Hayat tamamlanmışsa yaş ilerlemez.
  bool get isDeceased => _state?.deceased ?? false;

  void ageUp() {
    final GameState? current = _state;
    if (current == null || current.hasPendingEvent) return;
    // Hayat tamamlandıysa yaş ilerlemez.
    if (current.deceased) return;
    _state = LifeProgression(_random).advanceOneYear(current);
    _autoSave();
    notifyListeners();
  }

  /// Ekrandaki olayı verilen seçimle çözer (D-021, D-022).
  ///
  /// Sonuç metninin yanında **gerçekten uygulanmış** değişimleri de döndürür;
  /// bunlar niyetten değil, durumun öncesi/sonrası farkından hesaplanır.
  EventChoiceResult? chooseEventOption(String choiceId) {
    final GameState? current = _state;
    if (current == null || !current.hasPendingEvent) return null;
    final GameState next = _events.resolve(current, choiceId, rng: _random);
    _state = next;
    _autoSave();
    notifyListeners();
    return EventChoiceResult(
      text: next.log.isEmpty ? '' : next.log.last.text,
      effects: diffAppliedEffects(current, next),
    );
  }

  /// Bir aile bireyiyle etkileşim kurar ve sonucu döndürür (D-016).
  ///
  /// Genel bir etkileşim kotası yoktur; sınır yalnızca aynı kişiyle aynı
  /// etkinliğin aynı yaştaki **getirisinde** işler (D-026).
  InteractionOutcome? interact(String personId, InteractionKind kind) {
    final GameState? current = _state;
    if (current == null || current.hasPendingEvent) return null;
    final InteractionResult result = _interactions.perform(
      state: current,
      personId: personId,
      kind: kind,
      rng: _random,
    );
    // Oyun içi ilerlemeye bağlı olarak aralıklı bir ek olay çıkabilir
    // (D-023, D-024). Gerçek dünya dakikası beklenmez ve bir yaşta en fazla
    // bir ek olay açılır.
    GameState next = result.state;
    final ActiveEvent? extra = _events.progressEvent(next, _random);
    if (extra != null) {
      next = next.copyWith(
        pendingEvent: extra,
        extraEventsThisAge: next.extraEventsThisAge + 1,
      );
    }

    _state = next;
    _autoSave();
    notifyListeners();
    return result.outcome;
  }

  /// Etkileşimin şu an mümkün olup olmadığı; arayüz bunu kullanarak
  /// yapılamayacak eylemi düğme olarak göstermez.
  InteractionAvailability availabilityFor(
    Person person, [
    InteractionKind? kind,
  ]) {
    final GameState? current = _state;
    if (current == null) {
      return const InteractionAvailability.blocked('Etkin bir hayat yok.');
    }
    return _interactions.availability(current, person, kind);
  }

  /// Bir kişi için **şu an gerçekten yapılabilen** etkileşimler.
  ///
  /// Parası olmayan oyuncuya hediye düğmesi, kendi parası olmayan kişiye
  /// para isteme düğmesi açılmaz.
  List<InteractionKind> availableKindsFor(Person person) {
    final GameState? current = _state;
    if (current == null) return const <InteractionKind>[];
    return _interactions.availableKinds(current, person);
  }

  // =====================================================================
  // Eşyalar (Varlıklar)
  // =====================================================================

  /// Bir eşyada şu an gerçekten yapılabilecek eylemler.
  List<ItemActionKind> itemActionsFor(OwnedItem item) {
    final GameState? current = _state;
    if (current == null) return const <ItemActionKind>[];
    return _items.availableActions(current, item);
  }

  /// Eylemin neden kapalı olduğunu açıklar.
  InteractionAvailability itemAvailability(
    OwnedItem item,
    ItemActionKind action,
  ) {
    final GameState? current = _state;
    if (current == null) {
      return const InteractionAvailability.blocked('Etkin bir hayat yok.');
    }
    return _items.availability(current, item, action);
  }

  /// Bu eşyaya takılabilecek, envanterdeki aksesuarlar.
  List<OwnedItem> compatibleAccessoriesFor(OwnedItem item) {
    final GameState? current = _state;
    if (current == null) return const <OwnedItem>[];
    return _items.compatibleAccessories(current, item);
  }

  /// Bakım ücreti.
  int repairCostFor(OwnedItem item) {
    final GameState? current = _state;
    if (current == null) return 0;
    return _items.repairCost(current, item);
  }

  /// Satışta teklif edilecek tutar.
  int estimatedPriceFor(OwnedItem item) => _items.estimatedPrice(item);

  /// Eşya eylemini uygular (kullan / temizle / bakım).
  ItemOutcome? performItemAction(String itemId, ItemActionKind action) =>
      _runItemAction(
        (GameState current) => _items.perform(
          state: current,
          itemId: itemId,
          action: action,
          rng: _random,
        ),
      );

  /// Uyumlu aksesuarı eşyaya takar.
  ItemOutcome? attachAccessory(String itemId, String accessoryItemId) =>
      _runItemAction(
        (GameState current) => _items.attachAccessory(
          state: current,
          itemId: itemId,
          accessoryItemId: accessoryItemId,
        ),
      );

  /// Eşyayı satar. Onay arayüzde alınır; burada tek bir satış uygulanır.
  ItemOutcome? sellItem(String itemId) => _runItemAction(
        (GameState current) => _items.sell(state: current, itemId: itemId),
      );

  /// Mağazadan ürün alır.
  /// Mağazadan ürün alır.
  ///
  /// [location] yalnızca konutlarda anlamlıdır: hangi şehirden alındığı
  /// mülk kaydına yazılır (D-043).
  ItemOutcome? buyProduct(ShopProduct product, {String? location}) =>
      _runItemAction(
        (GameState current) => _items.buy(
          state: current,
          product: product,
          location: location,
        ),
      );

  /// Eşya işlemlerinin ortak akışı: olay varken çalışmaz, yalnızca durum
  /// gerçekten değiştiyse kaydeder.
  ItemOutcome? _runItemAction(ItemActionResult Function(GameState) islem) {
    final GameState? current = _state;
    if (current == null || current.hasPendingEvent) return null;

    final ItemActionResult result = islem(current);
    if (!result.outcome.applied) {
      // İşlem gerçekleşmedi: durum ve kayıt dosyası değişmez.
      return result.outcome;
    }

    _state = result.state;
    _autoSave();
    notifyListeners();
    return result.outcome;
  }

  // =====================================================================
  // Eğitim ve meslek
  // =====================================================================

  /// Puanın yettiği lise alanları.
  List<EducationTrackInfo> availableTracks() {
    final GameState? current = _state;
    if (current == null) return const <EducationTrackInfo>[];
    return _education.availableTracks(current);
  }

  /// Lise alanını seçer.
  EducationOutcome? chooseTrack(EducationTrack track) => _runEducation(
        (GameState current) => _education.chooseTrack(current, track),
      );

  /// Başvurulabilecek üniversite bölümleri.
  List<UniversityProgram> availablePrograms() {
    final GameState? current = _state;
    if (current == null) return const <UniversityProgram>[];
    return _education.availablePrograms(current);
  }

  /// Üniversiteye başvurur; kabul garanti değildir.
  EducationOutcome? applyToUniversity(UniversityProgram program) =>
      _runEducation(
        (GameState current) =>
            _education.applyToUniversity(current, program, _random),
      );

  /// Üniversiteye gitmeyip iş hayatına yönelir.
  EducationOutcome? skipUniversity() => _runEducation(
        (GameState current) => _education.skipUniversity(current),
      );

  EducationOutcome? _runEducation(EducationResult Function(GameState) islem) {
    final GameState? current = _state;
    if (current == null || current.hasPendingEvent) return null;
    final EducationResult result = islem(current);
    if (!result.outcome.applied) return result.outcome;
    _state = result.state;
    _autoSave();
    notifyListeners();
    return result.outcome;
  }

  /// Başvurulabilecek işler.
  List<JobType> openJobs() {
    final GameState? current = _state;
    if (current == null) return const <JobType>[];
    return _jobs.openJobs(current);
  }

  /// Koşulu sağlanmayan işler ve gerekçeleri.
  Map<JobType, String> lockedJobs() {
    final GameState? current = _state;
    if (current == null) return const <JobType, String>{};
    return _jobs.lockedJobs(current);
  }

  /// Oyuncunun üniversite sınav puanı; hesaplanmadıysa `null`.
  int? get universityExamScore => _state?.education.universityExamScore;

  /// Bir bölüme başvururken geçerli olan etkin puan (alan uyumu dahil).
  int programScore(UniversityProgram program) {
    final GameState? current = _state;
    if (current == null) return 0;
    return _education.effectiveScore(current, program);
  }

  /// Bölümün tercih ettiği alandan geliniyorsa eklenen puan.
  int programTrackBonus(UniversityProgram program) {
    final GameState? current = _state;
    if (current == null) return 0;
    return _education.trackBonusFor(current, program);
  }

  /// Başvurunun neden mümkün olmadığı; uygunsa boş metin.
  String programBlockReason(UniversityProgram program) {
    final GameState? current = _state;
    if (current == null) return 'Etkin bir hayat yok.';
    return _education.eligibilityReason(current, program);
  }

  /// Sınav puanı eksikse hesaplar (eski kayıtlar ve yeni mezunlar için).
  void ensureUniversityExamScore() {
    final GameState? current = _state;
    if (current == null) return;
    final GameState next = _education.ensureUniversityExamScore(current, _random);
    if (identical(next, current)) return;
    _state = next;
    _autoSave();
    notifyListeners();
  }

  /// Cevap bekleyen mülakat.
  PendingInterview? get pendingInterview => _state?.pendingInterview;

  /// Mülakat sorusunu cevaplar.
  JobOutcome? answerInterview(int optionIndex) => _runJob(
        (GameState current) =>
            _jobs.answerInterview(current, optionIndex, _random),
      );

  /// Mülakatı yarıda bırakır.
  JobOutcome? cancelInterview() => _runJob(
        (GameState current) => _jobs.cancelInterview(current),
      );

  /// Başvurunun şu an mümkün olup olmadığı.
  InteractionAvailability jobApplicationAvailability(JobType job) {
    final GameState? current = _state;
    if (current == null) {
      return const InteractionAvailability.blocked('Etkin bir hayat yok.');
    }
    return _jobs.applicationAvailability(current, job);
  }

  /// İşe başvurur.
  JobOutcome? applyForJob(JobType job) => _runJob(
        (GameState current) => _jobs.apply(current, job, _random),
      );

  /// İşten ayrılır.
  JobOutcome? quitJob() => _runJob((GameState current) => _jobs.quit(current));

  // -------------------------------------------------------------------
  // Meslekte ilerleme (Paket 9)
  // -------------------------------------------------------------------

  /// Zam istemek şu an mümkün mü?
  InteractionAvailability raiseAvailability() {
    final GameState? current = _state;
    if (current == null) {
      return const InteractionAvailability.blocked('Oyun yüklenmedi.');
    }
    return CareerProgress.raiseAvailability(current);
  }

  /// Terfi istemek şu an mümkün mü?
  InteractionAvailability promotionAvailability() {
    final GameState? current = _state;
    if (current == null) {
      return const InteractionAvailability.blocked('Oyun yüklenmedi.');
    }
    return CareerProgress.promotionAvailability(current);
  }

  // -------------------------------------------------------------------
  // Okul başarısı (Paket 13)
  // -------------------------------------------------------------------

  /// Ders çalışmak şu an mümkün mü?
  InteractionAvailability studyAvailability() {
    final GameState? current = _state;
    if (current == null) {
      return const InteractionAvailability.blocked('Oyun yüklenmedi.');
    }
    return SchoolPerformance.studyAvailability(current);
  }

  /// Ders çalışır; sonucu metin olarak döner.
  String? study() {
    final GameState? current = _state;
    if (current == null || current.hasPendingEvent) return null;
    final StudyResult sonuc = SchoolPerformance.study(current, _random);
    if (!sonuc.applied) return sonuc.text;
    _state = sonuc.state;
    _autoSave();
    notifyListeners();
    return sonuc.text;
  }

  /// Emeklilik şu an mümkün mü?
  InteractionAvailability retirementAvailability() {
    final GameState? current = _state;
    if (current == null) {
      return const InteractionAvailability.blocked('Oyun yüklenmedi.');
    }
    return Retirement.availability(current);
  }

  /// prototypeOnly: şu an emekli olunsa bağlanacak yıllık aylık.
  int pensionPreview() {
    final GameState? current = _state;
    if (current == null) return 0;
    return Retirement.prototypeOnlyPensionFor(current);
  }

  /// Emekli eder; sonucu metin olarak döner.
  String? retire() {
    final GameState? current = _state;
    if (current == null || current.hasPendingEvent) return null;
    final RetirementResult sonuc = Retirement.retire(current);
    if (!sonuc.applied) return sonuc.text;
    _state = sonuc.state;
    _autoSave();
    notifyListeners();
    return sonuc.text;
  }

  /// Zam ister; sonucu metin olarak döner.
  String? askForRaise() => _runCareerRequest(
        (GameState current) => CareerProgress.askForRaise(current, _random),
      );

  /// Terfi ister; sonucu metin olarak döner.
  String? askForPromotion() => _runCareerRequest(
        (GameState current) =>
            CareerProgress.askForPromotion(current, _random),
      );

  String? _runCareerRequest(CareerRequestResult Function(GameState) islem) {
    final GameState? current = _state;
    if (current == null || current.hasPendingEvent) return null;
    final CareerRequestResult sonuc = islem(current);
    if (!sonuc.applied) return sonuc.text;
    _state = sonuc.state;
    _autoSave();
    notifyListeners();
    return sonuc.text;
  }

  JobOutcome? _runJob(JobResult Function(GameState) islem) {
    final GameState? current = _state;
    if (current == null || current.hasPendingEvent) return null;
    final JobResult result = islem(current);
    if (!result.outcome.applied) return result.outcome;
    _state = result.state;
    _autoSave();
    notifyListeners();
    return result.outcome;
  }

  // =====================================================================
  // Aktiviteler (berber, spor salonu, kütüphane)
  // =====================================================================

  /// Mekânda şu an gerçekten yapılabilen eylemler.
  List<ActivityAction> availableActivities(ActivityVenue venue) {
    final GameState? current = _state;
    if (current == null) return const <ActivityAction>[];
    return _activities.availableActions(current, venue);
  }

  /// Eylemin neden kapalı olduğunu açıklar.
  InteractionAvailability activityAvailability(ActivityAction action) {
    final GameState? current = _state;
    if (current == null) {
      return const InteractionAvailability.blocked('Etkin bir hayat yok.');
    }
    return _activities.availability(current, action);
  }

  /// Bir aktivite eylemini uygular.
  ///
  /// Fal eylemlerinin sonucu sabit değil **rastgele bir metindir** ve
  /// mutluluğu düşürebilir de; bu yüzden ayrı yoldan geçer (Paket 27).
  /// Yönlendirme tek yerde yapılır ki arayüz hangi eylemin fal olduğunu
  /// bilmek zorunda kalmasın.
  ActivityOutcome? performActivity(ActivityAction action) => _runActivity(
        (GameState current) => ActivityEngine.isFortune(action)
            ? _activities.tellFortune(
                state: current,
                action: action,
                rng: _random,
              )
            : _activities.perform(
                state: current,
                action: action,
                rng: _random,
              ),
      );

  /// Yaşa uygun kitaplar.
  List<BookInfo> availableBooks() {
    final GameState? current = _state;
    if (current == null) return const <BookInfo>[];
    return _activities.availableBooks(current);
  }

  /// Kitabı açar.
  ActivityOutcome? openBook(BookInfo book) => _runActivity(
        (GameState current) => _activities.openBook(current, book),
      );

  /// Bir sayfa çevirir.
  ActivityOutcome? turnBookPage(BookInfo book) => _runActivity(
        (GameState current) => _activities.turnPage(current, book),
      );

  ActivityOutcome? _runActivity(ActivityResult Function(GameState) islem) {
    final GameState? current = _state;
    if (current == null || current.hasPendingEvent) return null;
    final ActivityResult result = islem(current);
    if (!result.outcome.applied) return result.outcome;
    _state = result.state;
    _autoSave();
    notifyListeners();
    return result.outcome;
  }

  // =====================================================================
  // Sosyal medya
  // =====================================================================

  /// Hesap açmanın şu an mümkün olup olmadığı.
  InteractionAvailability socialAccountAvailability(SocialPlatform platform) {
    final GameState? current = _state;
    if (current == null) {
      return const InteractionAvailability.blocked('Etkin bir hayat yok.');
    }
    return _social.accountAvailability(current, platform);
  }

  /// Paylaşımın şu an mümkün olup olmadığı.
  /// Bu yıl **bu platformda** kalan paylaşım hakkı.
  ///
  /// Sayaç platform başına ayrıdır; bir platformun dolması diğerini
  /// etkilemez.
  int remainingSocialPosts(SocialPlatform platform) {
    final GameState? current = _state;
    if (current == null) return 0;
    return _social.remainingPosts(current, platform);
  }

  InteractionAvailability socialPostAvailability(SocialContent content) {
    final GameState? current = _state;
    if (current == null) {
      return const InteractionAvailability.blocked('Etkin bir hayat yok.');
    }
    return _social.postAvailability(current, content);
  }

  /// Sosyal medya hesabı açar.
  SocialOutcome? openSocialAccount(SocialPlatform platform) => _runSocial(
        (GameState current) => _social.openAccount(current, platform),
      );

  // -------------------------------------------------------------------
  // Sponsorluk (Paket 10)
  // -------------------------------------------------------------------

  /// Yanıt bekleyen sponsorluk teklifi.
  SponsorOffer? get sponsorOffer => _state?.sponsorOffer;

  /// Yerine getirilmemiş sponsorluk yükümlülükleri.
  List<SponsorDeal> get openSponsorDeals =>
      _state?.openDeals ?? const <SponsorDeal>[];

  /// Teklifi kabul eder; ücret paylaşım yapılınca ödenir.
  SocialOutcome? acceptSponsor() =>
      _runSocial((GameState current) => _social.acceptSponsor(current));

  /// Teklifi reddeder; hiçbir gelir oluşmaz.
  SocialOutcome? declineSponsor() =>
      _runSocial((GameState current) => _social.declineSponsor(current));

  // -------------------------------------------------------------------
  // Seyahat (Paket 11)
  // -------------------------------------------------------------------

  /// Gidilebilecek şehirler.
  List<String> travelDestinations() =>
      _state == null ? const <String>[] : Travel.destinations(_state!);

  /// Şu an açık olan yolculuk türleri.
  List<TravelMode> travelModes() =>
      _state == null ? const <TravelMode>[] : Travel.availableModes(_state!);

  /// Birlikte gidilebilecek yakınlar.
  List<Person> travelCompanions() =>
      _state == null ? const <Person>[] : Travel.companions(_state!);

  /// Gezi şu an mümkün mü?
  InteractionAvailability travelAvailability({
    required TravelMode mode,
    required String city,
    String? companionId,
  }) {
    final GameState? current = _state;
    if (current == null) {
      return const InteractionAvailability.blocked('Oyun yüklenmedi.');
    }
    return Travel.availability(
      current,
      mode: mode,
      city: city,
      companionId: companionId,
    );
  }

  /// Geziyi yapar; ücret bir kez düşer.
  TripOutcome? takeTrip({
    required TravelMode mode,
    required String city,
    String? companionId,
  }) {
    final GameState? current = _state;
    if (current == null || current.hasPendingEvent) return null;
    final TripResult sonuc = Travel.take(
      current,
      mode: mode,
      city: city,
      companionId: companionId,
      rng: _random,
    );
    if (!sonuc.outcome.applied) return sonuc.outcome;
    _state = sonuc.state;
    _autoSave();
    notifyListeners();
    return sonuc.outcome;
  }

  /// Paylaşım yapar.
  SocialOutcome? postContent(SocialContent content) => _runSocial(
        (GameState current) => _social.post(current, content, _random),
      );

  SocialOutcome? _runSocial(SocialResult Function(GameState) islem) {
    final GameState? current = _state;
    if (current == null || current.hasPendingEvent) return null;
    final SocialResult result = islem(current);
    if (!result.outcome.applied) return result.outcome;
    _state = result.state;
    _autoSave();
    notifyListeners();
    return result.outcome;
  }

  // =====================================================================
  // Sağlık krizleri (D-044)
  // =====================================================================

  /// Cevap bekleyen sağlık krizi.
  PendingCrisis? get pendingCrisis => _state?.pendingCrisis;

  /// Bu seçenek şu an seçilebilir mi (bedeli ödenebiliyor mu)?
  bool canChooseCrisis(CrisisChoice choice) {
    final GameState? current = _state;
    if (current == null) return false;
    return _crises.canChoose(current, choice);
  }

  /// Krize yanıt verir; sonuç bir kez uygulanır.
  CrisisOutcome? respondToCrisis(String choiceId) {
    final GameState? current = _state;
    if (current == null || current.pendingCrisis == null) return null;
    final CrisisResult result =
        _crises.respond(current, choiceId, _random);
    if (!result.outcome.applied) return result.outcome;
    _state = result.state;
    _autoSave();
    notifyListeners();
    return result.outcome;
  }

  // =====================================================================
  // Konut: taşınma ve kiraya verme (D-043)
  // =====================================================================

  /// Oyuncunun oturduğu ev (varsa).
  OwnedItem? get residenceHome =>
      _state == null ? null : Housing.residenceHome(_state!);

  /// Oyuncunun yaşam düzeni.
  ResidenceKind get residence =>
      _state == null ? ResidenceKind.aileYaninda : Housing.residenceOf(_state!);

  /// Oyuncunun yaşadığı şehir.
  String get currentCity =>
      _state == null ? '' : Housing.cityOf(_state!);

  /// Kiraya verilen konutların yıllık toplam geliri.
  int get yearlyRentIncome =>
      _state == null ? 0 : Housing.yearlyRentIncome(_state!);

  /// Bu eve taşınmanın engeli; yoksa boş metin.
  String moveBlockReason(OwnedItem home) =>
      _state == null ? 'Etkin bir hayat yok.' : _housing.moveBlockReason(_state!, home);

  /// Bu evi kiraya vermenin engeli; yoksa boş metin.
  String rentOutBlockReason(OwnedItem home) => _state == null
      ? 'Etkin bir hayat yok.'
      : _housing.rentOutBlockReason(_state!, home);

  HousingOutcome? moveInto(OwnedItem home) =>
      _runHousing((GameState current) => _housing.moveInto(current, home));

  HousingOutcome? moveToRental() =>
      _runHousing((GameState current) => _housing.moveToRental(current));

  HousingOutcome? moveBackToFamily() =>
      _runHousing((GameState current) => _housing.moveBackToFamily(current));

  HousingOutcome? rentOutHome(OwnedItem home) =>
      _runHousing((GameState current) => _housing.rentOut(current, home));

  HousingOutcome? endLease(OwnedItem home) =>
      _runHousing((GameState current) => _housing.endLease(current, home));

  HousingOutcome? _runHousing(HousingResult Function(GameState) islem) {
    final GameState? current = _state;
    if (current == null || current.hasPendingEvent) return null;
    final HousingResult result = islem(current);
    if (!result.outcome.applied) return result.outcome;

    GameState next = result.state;
    String metin = result.outcome.text;

    // Şehir değiştiyse okul ve iş bağları da güncellenir (Paket 3).
    if (next.player.currentCity != current.player.currentCity) {
      final ({GameState state, String? logText}) nakil =
          const SchoolTransfer().transferIfNeeded(next, _random);
      next = nakil.state;
      if (nakil.logText != null) metin = '$metin\n${nakil.logText}';

      // Çalışan karakterin işine kendiliğinden son verilmez; yalnızca
      // durum açıkça yazılır (Q-065).
      if (next.career.isInAnotherCity(next.player.currentCity)) {
        final String isMetni = '${next.career.job?.name ?? 'İşin'} hâlâ '
            '${next.career.jobCity} şehrinde; işine devam ediyorsun.';
        next = next.copyWith(
          log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
            ...next.log,
            LifeLogEntry(
              age: next.player.age,
              text: isMetni,
              category: LogCategory.kisisel,
            ),
          ]),
        );
        metin = '$metin\n$isMetni';
      }
    }

    _state = next;
    _autoSave();
    notifyListeners();
    return HousingOutcome(applied: true, text: metin);
  }

  // =====================================================================
  // Ehliyet işlemleri
  // =====================================================================

  /// Cevap bekleyen ehliyet sınavı.
  PendingLicenseExam? get pendingLicenseExam => _state?.pendingLicenseExam;

  /// Sahip olunan ehliyetler.
  Set<String> get licenses => _state?.licenses ?? const <String>{};

  bool hasLicense(LicenseType type) => licenses.contains(type.id);

  /// Başvuru şu an mümkün mü?
  InteractionAvailability licenseAvailability(LicenseType type) {
    final GameState? current = _state;
    if (current == null) {
      return const InteractionAvailability.blocked('Etkin bir hayat yok.');
    }
    return _licenses.applicationAvailability(current, type);
  }

  /// Ehliyet başvurusu yapar; ücret bir kez alınır ve sınav açılır.
  LicenseOutcome? applyForLicense(LicenseType type) => _runLicense(
        (GameState current) => _licenses.apply(current, type, _random),
      );

  /// Sınav sorusunu cevaplar.
  LicenseOutcome? answerLicenseExam(int optionIndex) => _runLicense(
        (GameState current) => _licenses.answer(current, optionIndex),
      );

  /// Sınavdan vazgeçer.
  LicenseOutcome? cancelLicenseExam() =>
      _runLicense((GameState current) => _licenses.cancel(current));

  LicenseOutcome? _runLicense(LicenseResult Function(GameState) islem) {
    final GameState? current = _state;
    if (current == null || current.hasPendingEvent) return null;
    final LicenseResult result = islem(current);
    if (!result.outcome.applied) return result.outcome;
    _state = result.state;
    _autoSave();
    notifyListeners();
    return result.outcome;
  }

  // =====================================================================
  // Kumarhane (yalnızca oyunun sanal parası)
  // =====================================================================

  /// Masada devam eden ya da yeni bitmiş el.
  BlackjackGame? get blackjack => _state?.blackjack;

  /// Bu yaşta kumarhanede oynanan toplam bahis.
  int get wagerThisAge => _state?.wagerThisAge ?? 0;

  /// Kumarhaneye girilebilir mi?
  InteractionAvailability casinoAvailability() {
    final GameState? current = _state;
    if (current == null) {
      return const InteractionAvailability.blocked('Etkin bir hayat yok.');
    }
    return CasinoAccess.check(current);
  }

  /// Bu yılki bahis bütçesi (D-040).
  int casinoYearlyBudget() {
    final GameState? current = _state;
    if (current == null) return 0;
    return CasinoAccess.yearlyBudget(current);
  }

  /// Masada gösterilecek hazır bahis adımları.
  List<int> betSteps() {
    final GameState? current = _state;
    if (current == null) {
      return <int>[CasinoRules.prototypeOnlyMinBet];
    }
    return CasinoRules.prototypeOnlyBetSteps(CasinoAccess.maxBet(current));
  }

  /// Bu bahis şu an oynanabilir mi?
  InteractionAvailability betAvailability(int bet) {
    final GameState? current = _state;
    if (current == null) {
      return const InteractionAvailability.blocked('Etkin bir hayat yok.');
    }
    return CasinoAccess.checkBet(current, bet);
  }

  /// Blackjack eli açar.
  CasinoOutcome? dealBlackjack(int bet) => _runCasino(
        (GameState current) => _blackjack.deal(current, bet, _random),
      );

  /// Kart çeker.
  CasinoOutcome? hitBlackjack() =>
      _runCasino((GameState current) => _blackjack.hit(current));

  /// Durur; krupiye oynar ve el sonuçlanır.
  CasinoOutcome? standBlackjack() =>
      _runCasino((GameState current) => _blackjack.stand(current));

  /// Biten eli masadan kaldırır.
  CasinoOutcome? closeBlackjackHand() =>
      _runCasino((GameState current) => _blackjack.closeHand(current));

  /// Rulette **en son** çıkan sayı (Paket 30).
  ///
  /// Arayüz çarkı bu sayının üzerine indirir. Animasyon sonucu
  /// belirlemez; sonuç zaten çekilmiştir.
  int? _sonRuletSayisi;

  int? get lastRouletteNumber => _sonRuletSayisi;

  /// Rulette bahis oynar.
  CasinoOutcome? spinRoulette(RouletteBetType type, int bet, {int? number}) {
    final GameState? current = _state;
    if (current == null || current.hasPendingEvent) return null;
    final ({CasinoResult result, int? number}) cikti = _roulette.spinDetailed(
      current,
      type,
      bet,
      _random,
      number: number,
    );
    if (!cikti.result.outcome.applied) return cikti.result.outcome;
    _sonRuletSayisi = cikti.number;
    _state = cikti.result.state;
    _autoSave();
    notifyListeners();
    return cikti.result.outcome;
  }

  // =====================================================================
  // At yarışı (Paket 30)
  // =====================================================================

  /// Masadaki güncel kadro; sayfa açıldığında kurulur.
  List<RaceHorse> _yarisKadrosu = const <RaceHorse>[];

  /// Son koşunun sonucu; animasyon bunu gösterir.
  RaceResult? _sonKosu;

  List<RaceHorse> get raceField => _yarisKadrosu;
  RaceResult? get lastRace => _sonKosu;

  /// Yeni bir kadro kurar.
  List<RaceHorse> newRaceField() {
    _yarisKadrosu = HorseRacing.buildField(_random);
    _sonKosu = null;
    notifyListeners();
    return _yarisKadrosu;
  }

  /// At yarışında bahis oynar.
  CasinoOutcome? betOnHorse(int lane, int bet) {
    final GameState? current = _state;
    if (current == null || current.hasPendingEvent) return null;
    if (_yarisKadrosu.isEmpty) newRaceField();
    final ({CasinoResult result, RaceResult? race}) cikti =
        HorseRacing.placeBet(current, _yarisKadrosu, lane, bet, _random);
    if (!cikti.result.outcome.applied) return cikti.result.outcome;
    _sonKosu = cikti.race;
    _state = cikti.result.state;
    _autoSave();
    notifyListeners();
    return cikti.result.outcome;
  }

  /// At yarışında bahse engel var mı?
  InteractionAvailability horseBetAvailability(int bet) {
    final GameState? current = _state;
    if (current == null) {
      return const InteractionAvailability.blocked('Etkin bir hayat yok.');
    }
    return HorseRacing.betAvailability(current, bet);
  }

  CasinoOutcome? _runCasino(CasinoResult Function(GameState) islem) {
    final GameState? current = _state;
    if (current == null || current.hasPendingEvent) return null;
    final CasinoResult result = islem(current);
    if (!result.outcome.applied) return result.outcome;
    _state = result.state;
    _autoSave();
    notifyListeners();
    return result.outcome;
  }

  /// Sevgiliden ayrılır (D-029).
  ///
  /// Kişi kaydı silinmez; **aynı kimlikle** eski sevgili statüsüne geçer.
  /// Yalnızca gerçekten sevgili olan kişi için çalışır.
  String? endRomance(String personId) {
    final GameState? current = _state;
    if (current == null || current.hasPendingEvent) return null;
    final GameState next = _romance.end(current, personId);
    if (identical(next, current)) return null;
    _state = next;
    _autoSave();
    notifyListeners();
    return next.log.last.text;
  }

  // =====================================================================
  // Evlilik ve çocuklar (Paket E1-E2)
  // =====================================================================

  /// Bu kişiyle evlenilebilir mi? Engel varsa gerekçesiyle döner.
  InteractionAvailability marriageAvailability(String personId) {
    final GameState? current = _state;
    if (current == null) {
      return const InteractionAvailability.blocked('Etkin bir hayat yok.');
    }
    final Person? person = current.personById(personId);
    if (person == null) {
      return const InteractionAvailability.blocked('Bu kişi kayıtlarda yok.');
    }
    final String engel = _marriages.marryBlockReason(current, person);
    return engel.isEmpty
        ? const InteractionAvailability.allowed()
        : InteractionAvailability.blocked(engel);
  }

  /// Sevgiliyle evlenir. Kişi kimliği değişmez; kayıt silinmez.
  FamilyOutcome? marry(String personId) =>
      _runFamily((GameState current) => _marriages.marry(current, personId));

  // =====================================================================
  // Vasiyet (D-052)
  // =====================================================================

  /// Vasiyet yazmaya engel var mı?
  InteractionAvailability willAvailability() {
    final GameState? current = _state;
    if (current == null) {
      return const InteractionAvailability.blocked('Etkin bir hayat yok.');
    }
    final String engel = Will.blockReason(current);
    return engel.isEmpty
        ? const InteractionAvailability.allowed()
        : InteractionAvailability.blocked(engel);
  }

  /// Vasiyette **gerçekten geçerli** mirasçı; yoksa `null`.
  Person? get heirChild {
    final GameState? current = _state;
    return current == null ? null : Will.effectiveHeir(current);
  }

  /// Mirasçı olarak bir çocuk seçer.
  String? chooseHeir(String childId) {
    final GameState? current = _state;
    if (current == null || current.deceased) return null;
    final ({GameState state, String text, bool applied}) sonuc =
        Will.choose(current, childId);
    if (!sonuc.applied) return sonuc.text;
    _state = sonuc.state;
    _autoSave();
    notifyListeners();
    return sonuc.text;
  }

  /// Mirasçı seçimini kaldırır.
  String? clearHeir() {
    final GameState? current = _state;
    if (current == null || current.deceased) return null;
    final ({GameState state, String text, bool applied}) sonuc =
        Will.clear(current);
    if (!sonuc.applied) return sonuc.text;
    _state = sonuc.state;
    _autoSave();
    notifyListeners();
    return sonuc.text;
  }

  // =====================================================================
  // Bildirimler (D-050)
  // =====================================================================

  /// Sıradaki önemli haber; yoksa `null`.
  PendingNotice? get pendingNotice => _state?.nextNotice;

  /// Bilgilendirme bildirimini kapatır.
  ///
  /// Aynı bildirim bir daha açılmaz; kuyruktaki sıradaki habere geçilir.
  void dismissNotice() {
    final GameState? current = _state;
    if (current == null || !current.hasNotice) return;
    _state = Notices.dismissFirst(current);
    _autoSave();
    notifyListeners();
  }

  /// Bu cenaze seçeneği şu an sunulabilir mi?
  bool canChooseFuneral(FuneralChoice choice) {
    final GameState? current = _state;
    final PendingNotice? notice = current?.nextNotice;
    if (current == null || notice == null) return false;
    return Notices.canChoose(current, notice, choice);
  }

  /// Seçeneğin gerçekten ödenecek tutarı.
  int funeralAmount(FuneralChoice choice) {
    final GameState? current = _state;
    final PendingNotice? notice = current?.nextNotice;
    if (current == null || notice == null) return 0;
    return Notices.amountFor(current, notice, choice);
  }

  /// Cenazeye katılım ve masraf seçimini uygular.
  ///
  /// Katılmak ile katkıda bulunmak ayrı seçimlerdir; ödeme **bir kez**
  /// düşer ve cüzdan eksiye düşmez.
  String? respondToFuneral(
    FuneralChoice choice, {
    FuneralAttendance attendance = FuneralAttendance.katildi,
  }) {
    final GameState? current = _state;
    if (current == null || !current.hasNotice) return null;
    final ({GameState state, String text}) sonuc =
        Notices.respondToFuneral(current, choice, attendance: attendance);
    _state = sonuc.state;
    _autoSave();
    notifyListeners();
    return sonuc.text;
  }

  /// Bu kişiye evlenme teklifi edilebilir mi?
  InteractionAvailability proposalAvailability(String personId) {
    final GameState? current = _state;
    if (current == null) {
      return const InteractionAvailability.blocked('Etkin bir hayat yok.');
    }
    final Person? person = current.personById(personId);
    if (person == null) {
      return const InteractionAvailability.blocked('Bu kişi kayıtlarda yok.');
    }
    final String engel = _marriages.proposeBlockReason(current, person);
    return engel.isEmpty
        ? const InteractionAvailability.allowed()
        : InteractionAvailability.blocked(engel);
  }

  /// Evlenme teklifi eder (D-048).
  ///
  /// Sonuç **her zaman kabul değildir**; ret ilişkiyi bitirmez ve yanıt
  /// kayda girer.
  FamilyOutcome? propose(String personId, {String styleId = 'sade'}) =>
      _runFamily(
        (GameState current) => _marriages.propose(
          current,
          personId,
          _random,
          styleId: styleId,
        ),
      );

  /// Bekleyen düğünü yapar (Paket 25).
  ///
  /// Teklif kabul edildikten sonra oyuncu cüzdanına göre bir düğün seçer;
  /// evlilik ancak burada kurulur. Bedelsiz seçenek her zaman vardır.
  FamilyOutcome? holdWedding(String styleId) => _runFamily(
        (GameState current) => _marriages.holdWedding(current, styleId),
      );

  // =====================================================================
  // Askerlik (Paket 29)
  // =====================================================================

  /// Bu askerlik yoluna başvurmaya engel var mı?
  InteractionAvailability militaryAvailability(MilitaryTrack track) {
    final GameState? current = _state;
    if (current == null) {
      return const InteractionAvailability.blocked('Etkin bir hayat yok.');
    }
    return MilitaryService.availability(current, track);
  }

  /// Bedelli ödemeye engel var mı?
  InteractionAvailability bedelliAvailability() {
    final GameState? current = _state;
    if (current == null) {
      return const InteractionAvailability.blocked('Etkin bir hayat yok.');
    }
    final String engel = MilitaryService.bedelliBlockReason(current);
    return engel.isEmpty
        ? const InteractionAvailability.allowed()
        : InteractionAvailability.blocked(engel);
  }

  /// Bedelliyi ödeyebilecek yakınlar.
  List<Person> bedelliPayers() {
    final GameState? current = _state;
    if (current == null) return const <Person>[];
    return MilitaryService.possiblePayers(current);
  }

  /// Askerliğe katılır ya da rütbeli yola başvurur.
  MilitaryResult? enlistMilitary(MilitaryTrack track) =>
      _runMilitary((GameState c) =>
          MilitaryService.enlist(c, track, _random));

  /// Bedelliyi kendi cebinden öder.
  MilitaryResult? payBedelli() =>
      _runMilitary(MilitaryService.payBedelli);

  /// Askerliği tecil ettirir (Paket 31).
  MilitaryResult? deferMilitary() => _runMilitary(MilitaryService.defer);

  /// Çağrıya gitmez: bakaya kalır (Paket 31).
  MilitaryResult? fleeMilitary() => _runMilitary(MilitaryService.flee);

  /// Bakayayken kendiliğinden teslim olur.
  MilitaryResult? surrenderMilitary() =>
      _runMilitary(MilitaryService.surrender);

  /// Bedelli ücretini bir yakından ister.
  MilitaryResult? askFamilyForBedelli(String personId) =>
      _runMilitary((GameState c) =>
          MilitaryService.askFamilyForBedelli(c, personId, _random));

  MilitaryResult? _runMilitary(MilitaryResult Function(GameState) islem) {
    final GameState? current = _state;
    if (current == null || current.hasPendingEvent || current.deceased) {
      return null;
    }
    final MilitaryResult sonuc = islem(current);
    if (!sonuc.applied) return sonuc;
    _state = sonuc.state;
    _autoSave();
    notifyListeners();
    return sonuc;
  }

  /// Bu kişiyle yakınlaşmaya engel var mı? (Paket 25)
  InteractionAvailability intimacyAvailability(String personId) {
    final GameState? current = _state;
    if (current == null) {
      return const InteractionAvailability.blocked('Etkin bir hayat yok.');
    }
    final Person? person = current.personById(personId);
    if (person == null) {
      return const InteractionAvailability.blocked('Bu kişi kayıtlarda yok.');
    }
    final String engel = Intimacy.blockReason(current, person);
    return engel.isEmpty
        ? const InteractionAvailability.allowed()
        : InteractionAvailability.blocked(engel);
  }

  /// Eş veya sevgiliyle baş başa kalır (Paket 25).
  ///
  /// Korunma tercihi oyuncunundur. Korunmazsa çocuk bir **ihtimaldir**;
  /// garanti değildir.
  FamilyOutcome? beIntimate(String personId, Protection protection) =>
      _runFamily(
        (GameState current) => const IntimacyEngine().perform(
          current,
          personId,
          protection,
          _random,
        ),
      );

  /// Evlat edinme başvurusuna engel var mı?
  InteractionAvailability adoptionAvailability() {
    final GameState? current = _state;
    if (current == null) {
      return const InteractionAvailability.blocked('Etkin bir hayat yok.');
    }
    final String engel = const Adoption().blockReason(current);
    return engel.isEmpty
        ? const InteractionAvailability.allowed()
        : InteractionAvailability.blocked(engel);
  }

  /// Evlat edinme başvurusu yapar (D-049).
  ///
  /// Dönen kayıtta `adopted` başvurunun kabul edilip edilmediğini söyler;
  /// olumsuz sonuç da gerçek bir sonuçtur ve kayda girer.
  ({FamilyOutcome outcome, bool adopted})? adopt() {
    final GameState? current = _state;
    if (current == null || current.hasPendingEvent || current.deceased) {
      return null;
    }
    final AdoptionResult sonuc = const Adoption().apply(current, _random);
    if (!sonuc.outcome.applied) {
      return (outcome: sonuc.outcome, adopted: false);
    }
    _state = sonuc.state;
    _autoSave();
    notifyListeners();
    return (outcome: sonuc.outcome, adopted: sonuc.adopted);
  }

  /// Boşanmaya engel var mı?
  InteractionAvailability divorceAvailability() {
    final GameState? current = _state;
    if (current == null) {
      return const InteractionAvailability.blocked('Etkin bir hayat yok.');
    }
    final String engel = _marriages.divorceBlockReason(current);
    return engel.isEmpty
        ? const InteractionAvailability.allowed()
        : InteractionAvailability.blocked(engel);
  }

  /// Boşanır: eş **aynı kimlikle** eski eş olur.
  FamilyOutcome? divorce() =>
      _runFamily((GameState current) => _marriages.divorce(current));

  /// Çocuk sahibi olmaya engel var mı?
  InteractionAvailability childAvailability() {
    final GameState? current = _state;
    if (current == null) {
      return const InteractionAvailability.blocked('Etkin bir hayat yok.');
    }
    final String engel = _parenthood.blockReason(current);
    return engel.isEmpty
        ? const InteractionAvailability.allowed()
        : InteractionAvailability.blocked(engel);
  }

  /// Çocuk sahibi olur: kalıcı kimlikli yeni bir kişi kaydı açılır.
  FamilyOutcome? haveChild() => _runFamily(
        (GameState current) => _parenthood.haveChild(current, _random),
      );

  FamilyOutcome? _runFamily(FamilyResult Function(GameState) islem) {
    final GameState? current = _state;
    if (current == null || current.hasPendingEvent || current.deceased) {
      return null;
    }
    final FamilyResult sonuc = islem(current);
    if (!sonuc.outcome.applied) return sonuc.outcome;
    _state = sonuc.state;
    _autoSave();
    notifyListeners();
    return sonuc.outcome;
  }

  /// Yalnızca testler için: durumu doğrudan ayarlar.
  @visibleForTesting
  void debugSetState(GameState state) {
    _state = state;
    notifyListeners();
  }

  /// Hayatı ekrandan kaldırıp başlangıç ekranına döner.
  ///
  /// **Kaydı silmez**: oyuncu başlangıç ekranından "Devam Et" ile aynı
  /// hayata geri dönebilir. Kaydı silmek için [deleteSavedLife] gerekir.
  /// Aktif hayatı bırakır.
  ///
  /// Tamamlanmış bir hayat varsa özeti **arşive yazılır**; arşiv bir
  /// sonraki hayata taşınır ve habersizce silinmez (D-037).
  void clearLife() {
    _pendingArchive = _archiveWithCurrentLife();
    _state = null;
    notifyListeners();
  }

  /// Geçmiş hayat özetleri (en yenisi sonda).
  List<LifeSummary> get pastLives =>
      _state?.pastLives ?? _pendingArchive ?? const <LifeSummary>[];

  /// Aktif hayat yokken taşınan arşiv.
  List<LifeSummary>? _pendingArchive;

  /// Mevcut hayat tamamlandıysa özetini arşive ekleyip listeyi döndürür.
  List<LifeSummary> _archiveWithCurrentLife() {
    final GameState? current = _state;
    final List<LifeSummary> arsiv = <LifeSummary>[
      ...?current?.pastLives ?? _pendingArchive,
    ];
    if (current == null || !current.deceased) return arsiv;

    final List<String> satirlar = <String>[
      for (final LifeLogEntry e in current.log)
        if (e.category != LogCategory.yasDegisimi) '${e.age}: ${e.text}',
    ];

    arsiv.add(
      LifeSummary(
        fullName: current.player.fullName,
        birthCity: current.player.birthCity,
        deathAge: current.deathAge ?? current.player.age,
        deathCause: current.deathCause ?? 'bilinmiyor',
        educationLabel: current.education.program == null
            ? current.education.label
            : '${current.education.label} · '
                '${current.education.program!.name}',
        careerLabel: current.career.isEmployed
            ? current.career.label
            : current.career.pastJobIds.isEmpty
                ? 'Çalışmadı'
                : 'Son iş: ${current.career.label}',
        wallet: current.player.wallet,
        itemCount: current.items.length,
        licenseCount: current.licenses.length,
        highlights: List<String>.unmodifiable(
          satirlar.length > 8
              ? satirlar.sublist(satirlar.length - 8)
              : satirlar,
        ),
        familyLine: _familyLine(current),
        generation: current.generation,
        verdictTitle: LifeVerdictBuilder.build(current).title,
      ),
    );
    return arsiv;
  }

  /// Arşive yazılacak aile özeti; evlilik de çocuk da yoksa `null`.
  ///
  /// Uydurma bilgi yazılmaz: yalnızca gerçek evlilik kaydı ve gerçek çocuk
  /// kayıtları okunur.
  static String? _familyLine(GameState state) {
    final List<String> parcalar = <String>[];
    final Marriage? evlilik = state.marriage;
    if (evlilik != null) {
      final Person? es = state.personById(evlilik.spouseId);
      final String ad = es?.fullName ?? 'bilinmiyor';
      switch (evlilik.status) {
        case MarriageStatus.evli:
          parcalar.add('Eşi: $ad (${evlilik.marriedAtAge} yaşında evlendi)');
        case MarriageStatus.bosandi:
          parcalar.add('Eski eşi: $ad '
              '(${evlilik.marriedAtAge}-${evlilik.endedAtAge} yaş)');
        case MarriageStatus.dul:
          parcalar.add('Eşi: $ad (${evlilik.endedAtAge} yaşında kaybetti)');
      }
    }
    final int cocuk = state.children.length;
    if (cocuk > 0) {
      final int hayatta = state.livingChildren.length;
      parcalar.add(
        hayatta == cocuk ? '$cocuk çocuk' : '$cocuk çocuk ($hayatta hayatta)',
      );
    }
    return parcalar.isEmpty ? null : parcalar.join(' · ');
  }

  /// Oyuncu ayarlarını günceller (D-032).
  void updateSettings(GameSettings settings) {
    final GameState? current = _state;
    if (current == null) return;
    _state = current.copyWith(settings: settings);
    _autoSave();
    notifyListeners();
  }

  /// Oyuncunun kendi belirlediği yıllık bahis limiti.
  int? get wagerLimitPerAge => _state?.settings.wagerLimitPerAge;

  /// Kumarhane modülü açık mı?
  bool get casinoEnabled => _state?.settings.casinoEnabled ?? true;
}

/// Bir olay seçiminin oyuncuya gösterilecek sonucu.
class EventChoiceResult {
  const EventChoiceResult({required this.text, required this.effects});

  final String text;
  final List<AppliedEffect> effects;
}
