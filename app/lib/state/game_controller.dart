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

import '../domain/generation/life_generator.dart';
import '../domain/generation/life_progression.dart';
import '../domain/effects/effect_diff.dart';
import '../domain/events/event_engine.dart';
import '../domain/models/applied_effect.dart';
import '../domain/interaction/family_interactions.dart';
import '../domain/activities/activity_engine.dart';
import '../domain/career/job_market.dart';
import '../domain/education/education_path.dart';
import '../domain/interaction/item_actions.dart';
import '../data/license_catalog.dart';
import '../domain/casino/blackjack.dart';
import '../domain/licensing/license_office.dart';
import '../domain/models/pending_license_exam.dart';
import '../domain/casino/roulette.dart';
import '../domain/models/blackjack_game.dart';
import '../domain/models/game_settings.dart';
import '../domain/models/life_log.dart';
import '../domain/models/life_summary.dart';
import '../domain/social/social_engine.dart';
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
  final ItemActions _items = const ItemActions();
  final EducationPath _education = const EducationPath();
  final JobMarket _jobs = const JobMarket();
  final ActivityEngine _activities = const ActivityEngine();
  final SocialEngine _social = const SocialEngine();
  final Blackjack _blackjack = const Blackjack();
  final Roulette _roulette = const Roulette();
  final LicenseOffice _licenses = const LicenseOffice();

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
  ItemOutcome? buyProduct(ShopProduct product) => _runItemAction(
        (GameState current) => _items.buy(state: current, product: product),
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
        (GameState current) => _jobs.answerInterview(current, optionIndex),
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

  /// Berber veya spor salonu eylemini uygular.
  ActivityOutcome? performActivity(ActivityAction action) => _runActivity(
        (GameState current) => _activities.perform(
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

  /// Rulette bahis oynar.
  CasinoOutcome? spinRoulette(RouletteBetType type, int bet, {int? number}) =>
      _runCasino(
        (GameState current) =>
            _roulette.spin(current, type, bet, _random, number: number),
      );

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
      ),
    );
    return arsiv;
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
