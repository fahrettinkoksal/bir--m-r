import 'package:flutter/foundation.dart';

import '../../data/social_catalog.dart';

import 'blackjack_game.dart';
import 'education.dart';
import 'book_progress.dart';
import 'career.dart';
import 'game_event.dart';
import 'game_settings.dart';
import 'gift_record.dart';
import 'owned_item.dart';
import 'life_log.dart';
import 'life_summary.dart';
import 'marriage.dart';
import 'parental_status.dart';
import 'pending_notice.dart';
import 'pending_interview.dart';
import 'pending_crisis.dart';
import 'pending_license_exam.dart';
import 'person.dart';
import 'social_account.dart';
import 'sponsorship.dart';
import 'player_character.dart';
import 'relation.dart';

/// Tek bir hayatın tüm durumu.
///
/// Kişiler tek bir listede tutulur; Aile ekranı da ileride eklenecek olay
/// motoru da aynı kayıtları kullanır, böylece iki yerde farklı gerçeklik
/// oluşmaz.
@immutable
class GameState {
  const GameState({
    required this.seed,
    required this.player,
    required this.people,
    required this.pets,
    required this.parentalStatus,
    required this.log,
    this.interactionCounts = const <String, int>{},
    this.lastInteractionAge = const <String, int>{},
    this.storyFlags = const <String>{},
    this.items = const <OwnedItem>[],
    this.seenEventIds = const <String>{},
    this.lastEventAge = const <String, int>{},
    this.storyPeople = const <String, String>{},
    this.gifts = const <GiftRecord>[],
    this.pendingEvent,
    this.progressSinceLastEvent = 0,
    this.extraEventsThisAge = 0,
    this.education = const EducationState.notStarted(),
    this.career = const CareerState.none(),
    this.books = const <BookProgress>[],
    this.socialAccounts = const <SocialAccount>[],
    this.sponsorOffer,
    this.sponsorDeals = const <SponsorDeal>[],
    this.pendingInterview,
    this.blackjack,
    this.wagerThisAge = 0,
    this.licenses = const <String>{},
    this.pendingLicenseExam,
    this.settledEstates = const <String>{},
    this.deceased = false,
    this.deathAge,
    this.deathCause,
    this.pastLives = const <LifeSummary>[],
    this.careStatus = CareStatus.aileYaninda,
    this.grief = 0,
    this.hardshipYears = 0,
    this.settings = const GameSettings(),
    this.residenceItemId,
    this.movedOut = false,
    this.pendingCrisis,
    this.lastCrisisAge,
    this.healthWarned = false,
    this.marriage,
    this.generation = 1,
    this.proposalAges = const <String, int>{},
    this.notices = const <PendingNotice>[],
    this.heirChildId,
  });

  /// Üretimde kullanılan tohum. Tekrarlanabilir test senaryosu içindir;
  /// her oyuncuya sabit bir aile verilmez.
  final int seed;
  final PlayerCharacter player;
  final List<Person> people;
  final List<Pet> pets;
  final ParentalStatus parentalStatus;
  final List<LifeLogEntry> log;

  /// **Yalnızca içinde bulunulan yaşa ait** tekrar geçmişi:
  /// `'<kişiKimliği>|<etkileşimTürü>' -> kaç kez gerçekleşti`.
  ///
  /// Sayaç kişi ve etkileşim türü bazındadır; bu yüzden anneyle vakit
  /// geçirmek babayla vakit geçirmeyi ya da aynı kişiyle sohbeti etkilemez
  /// (D-026: genel etkileşim kotası yoktur). Yaş değişince sıfırlanır.
  final Map<String, int> interactionCounts;

  static String interactionKey(String personId, String kindName) =>
      '$personId|$kindName';

  int interactionCount(String personId, String kindName) =>
      interactionCounts[interactionKey(personId, kindName)] ?? 0;

  /// Bir kişiyle **oyun içinde** en son hangi yaşta anlamlı temas kurulduğu.
  /// Gerçek dünya saati değil, oyun ilerleyişi ölçüsüdür (D-024, D-025).
  final Map<String, int> lastInteractionAge;

  /// Geçmiş seçimlerin bıraktığı izler (D-008).
  final Set<String> storyFlags;

  /// Envanterdeki eşya örnekleri.
  ///
  /// Aynı türden iki eşya iki ayrı örnektir; her birinin kendi kimliği,
  /// kondisyonu ve takılı aksesuarları vardır.
  final List<OwnedItem> items;

  /// Sahip olunan eşya **türleri**. Olay motoru bu kümeye bakar: olmayan
  /// varlık için olay çıkmaz.
  ///
  /// Envanterden türetilir; ayrı bir liste tutulmaz, böylece iki yerde
  /// farklı gerçeklik oluşmaz.
  Set<String> get possessions =>
      <String>{for (final OwnedItem item in items) item.typeId};

  /// Kimlikten eşya örneği.
  OwnedItem? itemById(String id) {
    for (final OwnedItem item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  /// Verilen türden sahip olunan örnekler.
  List<OwnedItem> itemsOfType(String typeId) =>
      items.where((OwnedItem i) => i.typeId == typeId).toList(growable: false);

  /// Yeni eşya örneği için çakışmayan kimlik üretir.
  String nextItemId() => _nextItemId(<String>{for (final OwnedItem i in items) i.id});

  static String _nextItemId(Set<String> mevcut) {
    int n = mevcut.length + 1;
    while (mevcut.contains('esya-$n')) {
      n++;
    }
    return 'esya-$n';
  }

  /// Envantere yeni eşya örnekleri ekler.
  ///
  /// Aynı türden ikinci bir eşya ayrı bir örnek olur; kimlikler çakışmaz.
  GameState grantItems(
    Iterable<String> typeIds, {
    required ItemSource source,
    String? fromPersonId,
    int condition = OwnedItem.defaultCondition,
    int? purchasePrice,
    String? location,
  }) {
    if (typeIds.isEmpty) return this;
    final Set<String> mevcut = <String>{for (final OwnedItem i in items) i.id};
    final List<OwnedItem> yeni = <OwnedItem>[...items];
    for (final String typeId in typeIds) {
      final String id = _nextItemId(mevcut);
      mevcut.add(id);
      yeni.add(
        OwnedItem(
          id: id,
          typeId: typeId,
          acquiredAtAge: player.age,
          source: source,
          fromPersonId: fromPersonId,
          condition: condition,
          purchasePrice: purchasePrice,
          location: location,
        ),
      );
    }
    return copyWith(items: List<OwnedItem>.unmodifiable(yeni));
  }

  /// Bir eşya örneğini envanterden çıkarır (satış, tüketim).
  GameState removeItem(String itemId) => copyWith(
        items: List<OwnedItem>.unmodifiable(
          items.where((OwnedItem i) => i.id != itemId).toList(growable: false),
        ),
      );

  /// Bir eşya örneğini günceller.
  GameState updateItem(OwnedItem updated) => copyWith(
        items: List<OwnedItem>.unmodifiable(
          items
              .map((OwnedItem i) => i.id == updated.id ? updated : i)
              .toList(growable: false),
        ),
      );

  /// Bu hayatta görülmüş olaylar; tekrarlanabilir olmayanlar bir kez çıkar.
  final Set<String> seenEventIds;

  /// Tekrarlanabilir olayların **en son hangi yaşta** çıktığı:
  /// `'<olayKimliği>' -> yaş`.
  ///
  /// Tekrar aralığı buradan denetlenir; böylece bayram sabahı gibi doğal
  /// olarak tekrar eden olaylar art arda değil, uygun yaş farkıyla gelir
  /// (bkz. [GameEvent.minAgeGap]).
  final Map<String, int> lastEventAge;

  /// Hikâye rolüne kilitlenmiş kişiler: `'<rol>' -> kişiKimliği`.
  ///
  /// Bir olayda kim olduğu belirlenen kişi (ör. teneffüste savunduğun
  /// arkadaş) yıllar sonraki devam olayında **aynı kimlikle** kullanılır;
  /// olmayan bir kişi uydurulmaz.
  final Map<String, String> storyPeople;

  /// Gerçekleşmiş hediyeleşmeler: kim, kime, ne verdi.
  ///
  /// Yalnızca gerçekten el değiştiren hediyeler yazılır; reddedilen istek
  /// buraya girmez.
  final List<GiftRecord> gifts;

  /// Oyuncunun karşısındaki tek olay. Aynı anda ikinci bir olay açılmaz
  /// (D-021): bu alan doluyken yeni olay üretilmez.
  final ActiveEvent? pendingEvent;

  /// Son olaydan bu yana yapılan anlamlı oyun içi ilerleme adımı sayısı.
  final int progressSinceLastEvent;

  /// İçinde bulunulan yaşta açılış olayından **sonra** çıkan ek olay sayısı.
  final int extraEventsThisAge;

  /// Oyuncunun eğitim durumu. Öğrencilik yaştan türetilmez (bkz.
  /// [EducationState]); olay uygunluğu bu veriye bakar.
  final EducationState education;

  /// Oyuncunun çalışma durumu ve maaş geçmişi.
  final CareerState career;

  /// Okunan kitapların ilerlemesi. Bitirilen kitap bir daha kazanç vermez.
  final List<BookProgress> books;

  /// Açılmış sosyal medya hesapları. Hesap açmak **zorunlu değildir**;
  /// hesabı olmayan platformdan paylaşım veya olay gelmez.
  final List<SocialAccount> socialAccounts;

  /// Yanıt bekleyen sponsorluk teklifi (Paket 10).
  ///
  /// Aynı anda yalnızca bir teklif bekler; kabul veya ret verilene kadar
  /// yenisi gelmez.
  final SponsorOffer? sponsorOffer;

  /// Kabul edilmiş sponsorluk yükümlülükleri ve geçmişi.
  final List<SponsorDeal> sponsorDeals;

  /// Henüz yerine getirilmemiş sponsorluklar.
  List<SponsorDeal> get openDeals =>
      sponsorDeals.where((SponsorDeal d) => d.isOpen).toList(growable: false);

  /// Sosyal medyadan bugüne kadar kazanılan toplam tutar.
  int get totalSocialEarnings {
    int toplam = 0;
    for (final SocialAccount a in socialAccounts) {
      for (final SocialPost p in a.posts) {
        toplam += p.earned;
      }
    }
    return toplam;
  }

  /// Cevap bekleyen iş mülakatı; yoksa `null`.
  ///
  /// Kaydedilir: uygulama kapatılıp açılınca aynı soru geri gelir.
  final PendingInterview? pendingInterview;

  bool get hasPendingInterview => pendingInterview != null;

  /// Kumarhane masasında devam eden ya da yeni bitmiş el.
  ///
  /// Kaydedilir: oyun kapatılıp açılınca aynı el aynı kartlarla sürer.
  final BlackjackGame? blackjack;

  bool get hasOpenHand => blackjack != null;

  /// Sahip olunan ehliyetler (`lib/data/license_catalog.dart`).
  ///
  /// Araç **sahibi olmak** ile aracı **kullanmak** ayrı koşullardır:
  /// ehliyet yalnızca sürme eyleminde aranır.
  final Set<String> licenses;

  bool hasLicense(String licenseId) => licenses.contains(licenseId);

  /// Cevap bekleyen ehliyet sınavı.
  final PendingLicenseExam? pendingLicenseExam;

  bool get hasPendingLicenseExam => pendingLicenseExam != null;

  /// Mirası **dağıtılmış** kişilerin kimlikleri.
  ///
  /// Aynı miras iki kez dağıtılmaz.
  final Set<String> settledEstates;

  /// Oyuncu vefat etti mi? Hayat tamamlanmış sayılır.
  final bool deceased;

  /// Oyuncunun vefat ettiği yaş.
  final int? deathAge;

  /// Kısa ölüm gerekçesi.
  final String? deathCause;

  /// Tamamlanmış hayatların arşivi (D-037).
  ///
  /// Yeni hayat başlatmak bu listeyi **silmez**; hayatlar üst üste birikir.
  final List<LifeSummary> pastLives;

  /// Oyuncunun bakım durumu (D-037).
  ///
  /// Çocuk yaşta hanede yetişkin kalmadığında açık bir duruma geçilir;
  /// oyuncu açıklamasız bırakılmaz.
  final CareStatus careStatus;

  /// Kalan **yas** yükü (D-036).
  ///
  /// Kayıp anında mutluluktan düşülen değerin henüz geri verilmemiş kısmı.
  /// Her yaşta bir bölümü geri verilir; yas kalıcı bir ceza değildir.
  final int grief;

  /// Üst üste geçim sıkıntısı çekilen yıl sayısı (D-033).
  final int hardshipYears;

  /// Oyuncunun kendi ayarları (D-032).
  final GameSettings settings;

  /// Oyuncunun **oturduğu** konutun eşya kimliği (D-043).
  ///
  /// Mülk sahipliğinden ayrıdır: oyuncu evi olup ailesinin yanında
  /// yaşayabilir. `null` ise kendi evinde oturmuyordur.
  final String? residenceItemId;

  /// Cevap bekleyen sağlık krizi (D-044).
  final PendingCrisis? pendingCrisis;

  bool get hasPendingCrisis => pendingCrisis != null;

  /// Son sağlık krizinin çıktığı yaş; krizler seyrek olsun diye tutulur.
  final int? lastCrisisAge;

  /// Düşük sağlık uyarısı verildi mi? Aynı uyarı her yıl tekrarlanmaz.
  final bool healthWarned;

  /// Oyuncunun evlilik kaydı; hiç evlenilmediyse `null` (D-045 önerisi).
  ///
  /// Kayıt boşanmadan veya eşin vefatından sonra da **silinmez**; yalnızca
  /// durumu değişir. Miras hesabı "gerçek birliktelik kaydı" ararken
  /// buraya bakar (D-037).
  final Marriage? marriage;

  /// Vasiyetinde mirasçı olarak seçilen çocuğun kimliği (D-052).
  ///
  /// Seçim isteğe bağlıdır; `null` ise miras çocuklar arasında eşit
  /// bölünür. Seçilen çocuk vefat ederse kayıt silinmez ama seçim
  /// **geçersiz** sayılır (bkz. `Will.effectiveHeirId`).
  final String? heirChildId;

  /// Oyuncuya gösterilmeyi bekleyen önemli haberler (D-050).
  ///
  /// Ölüm, miras ve cenaze bildirimleri sırayla gösterilir; bekleyen
  /// bildirim kayıtla birlikte saklanır ve uygulama kapatılıp açılınca
  /// kaybolmaz. Aynı bildirim iki kez kuyruğa girmez.
  final List<PendingNotice> notices;

  bool get hasNotice => notices.isNotEmpty;

  /// Sıradaki bildirim; yoksa `null`.
  PendingNotice? get nextNotice => notices.isEmpty ? null : notices.first;

  /// Teklif ve başvuru geçmişi: `anahtar -> yaş`.
  ///
  /// Anahtar bir **kişi kimliğidir** (evlenme teklifi, D-048) ya da
  /// ayrılmış bir başvuru anahtarıdır (evlat edinme başvurusu, D-049).
  /// Sonuç kayda girer: aynı adım hemen tekrarlanamaz ve oyunu yeniden
  /// yükleyerek sonuç değiştirilemez.
  final Map<String, int> proposalAges;

  /// Bu kişiye en son kaç yaşında teklif edildi? Hiç edilmediyse `null`.
  int? lastProposalAge(String personId) => proposalAges[personId];

  /// Kaçıncı kuşağın hayatı oynanıyor (Paket E3).
  ///
  /// İlk hayat 1. kuşaktır. "Çocuğum olarak devam et" ile geçilen her
  /// hayatta bir artar; eski kayıtlarda alan yoktur ve 1 kabul edilir.
  /// Kuşak sayısının bir üst sınırı olup olmayacağı henüz kararlaştırılmadı
  /// (`docs/DESIGN_REVIEW_QUEUE.md`, Q-067).
  final int generation;

  /// Bu hayat bir önceki kuşaktan devam mı ediyor?
  bool get isContinuedGeneration => generation > 1;

  /// Eşin kişi kaydı; evlilik kaydı yoksa `null`.
  ///
  /// Boşanılmış veya vefat etmiş eş de bu kimlikten okunur; kişi listeden
  /// silinmez.
  Person? get spouse {
    final Marriage? kayit = marriage;
    if (kayit == null) return null;
    return personById(kayit.spouseId);
  }

  /// Şu anda yürüyen bir evlilik var mı? (Eş hayatta ve kayıt etkin.)
  bool get isMarried {
    final Marriage? kayit = marriage;
    if (kayit == null || !kayit.isActive) return false;
    final Person? es = spouse;
    return es != null && es.isAlive;
  }

  /// Oyuncunun çocukları; vefat edenler de listede kalır.
  List<Person> get children => people
      .where((Person p) => p.relation == RelationType.cocuk)
      .toList(growable: false);

  /// Hayattaki çocuklar.
  List<Person> get livingChildren => people
      .where((Person p) => p.relation == RelationType.cocuk && p.isAlive)
      .toList(growable: false);

  /// Oyuncu aile evinden ayrıldı mı?
  ///
  /// Kirada yaşamak ile ailenin yanında yaşamayı ayırır; hanede yetişkin
  /// kalmadığında da oyuncu otomatik "kirada" sayılır.
  final bool movedOut;

  /// Hayatta olan hane üyeleri.
  List<Person> get householdMembers => people
      .where((Person p) => p.isAlive && p.inPlayerHousehold)
      .toList(growable: false);

  /// Vefat etmiş kişiler; kayıtları **silinmez**.
  List<Person> get deceasedPeople =>
      people.where((Person p) => !p.isAlive).toList(growable: false);

  /// **Bu yaşta** kumarhanede oynanan toplam bahis.
  ///
  /// Yıllık bahis sınırı için tutulur; yaş değişince sıfırlanır.
  final int wagerThisAge;

  /// Bir platformdaki hesap; açılmamışsa `null`.
  SocialAccount? accountFor(SocialPlatform platform) {
    for (final SocialAccount a in socialAccounts) {
      if (a.platform == platform) return a;
    }
    return null;
  }

  /// Bütün platformlardaki toplam takipçi.
  int get totalFollowers => socialAccounts.fold(
        0,
        (int toplam, SocialAccount a) => toplam + a.followers,
      );

  /// Bir kitabın ilerlemesi; hiç açılmamışsa `null`.
  BookProgress? bookProgress(String bookId) {
    for (final BookProgress b in books) {
      if (b.bookId == bookId) return b;
    }
    return null;
  }

  bool get hasPendingEvent => pendingEvent != null;

  List<Person> get livingPeople =>
      people.where((Person p) => p.isAlive).toList(growable: false);

  /// Oyuncuyla aynı evde yaşayan, hayattaki kişiler.
  List<Person> get household => people
      .where((Person p) => p.isAlive && p.inPlayerHousehold)
      .toList(growable: false);

  Person? personById(String id) {
    for (final Person person in people) {
      if (person.id == id) return person;
    }
    return null;
  }

  List<Person> byGroup(RelationGroup group) => people
      .where((Person p) => p.relation.group == group)
      .toList(growable: false);

  /// Şu anda devam edilen **sınıftaki** arkadaşlar.
  ///
  /// Liste okul bağına ve **sınıf kimliğine** bakar, yakınlık derecesine
  /// değil: aynı sınıftaki bir kişi yakın arkadaş olsa da burada kalır.
  /// Kademe değişince eski sınıf arkadaşları **silinmez**; yalnızca güncel
  /// listeye girmezler (D-029: kişi kaydı korunur).
  List<Person> get currentClassmates => people
      .where((Person p) => p.isClassmateIn(education.classId))
      .toList(growable: false);

  /// Şu anda devam edilen **okuldaki** öğretmenler.
  List<Person> get currentTeachers => people
      .where((Person p) => p.isTeacherIn(education.schoolId))
      .toList(growable: false);

  /// Geçmişte tanışılmış, artık güncel sınıfta/okulda olmayan okul kişileri.
  ///
  /// Yakın arkadaş olmuş biri de buraya düşebilir; kaydı korunur ve ileride
  /// yeniden karşılaşma mümkündür.
  List<Person> get pastSchoolPeople => people
      .where((Person p) =>
          p.schoolTie != null &&
          !p.isClassmateIn(education.classId) &&
          !p.isTeacherIn(education.schoolId))
      .toList(growable: false);

  /// Oyuncunun **şu anki hayatında gerçekten erişebildiği** kişiler.
  ///
  /// Gündelik etkileşim listeleri bunu kullanır. Yıllar önce tanışılmış bir
  /// ilkokul öğretmeni, hayatta kalmaya devam etse bile her gün görüşülen
  /// biri değildir; kaydı silinmez ama gündelik listeye girmez. Yeniden
  /// karşılaşma ileride özel bir olayla mümkün olacak.
  List<Person> get reachablePeople =>
      people.where(isReachable).toList(growable: false);

  /// Bir kişi şu an gündelik hayatta erişilebilir mi?
  ///
  /// Şehir de bir ölçüttür (Paket 3): başka şehirde kalan okul/hayat
  /// arkadaşı gündelik listelerde görünmez. **Kaydı silinmez**, yakınlığı
  /// sıfırlanmaz ve yakın aile bu kuraldan etkilenmez.
  bool isReachable(Person person) {
    if (!person.isAlive) return false;
    // Aynı evde yaşayanlar her zaman erişilebilir.
    if (person.inPlayerHousehold) return true;

    // Kişinin şehri bilinmiyorsa (eski kayıtlar) şehir koşulu uygulanmaz.
    final bool baskaSehirde =
        person.city != null && person.city != player.currentCity;
    // Güncel okul çevresi.
    if (person.isClassmateIn(education.classId)) return true;
    if (person.isTeacherIn(education.schoolId)) return true;
    // Güncel iş çevresi: yalnızca **o işte çalışılırken** ve iş aynı
    // şehirdeyken görüşülür. İşten ayrılınca kayıt silinmez, sadece
    // gündelik listelerden düşer (Paket 9).
    if (person.isColleagueAt(career.jobId)) return !baskaSehirde;
    // Yakın arkadaşlar ve romantik bağlar görüşmeye devam eder.
    switch (person.relation) {
      // Eş ve çocuklar evden ayrılsalar da görüşülmeye devam eder.
      case RelationType.es:
      case RelationType.cocuk:
        return true;
      // Arkadaşlık ve romantik bağ sürer ama başka şehirdeki kişi her gün
      // görüşülen biri değildir; yeniden karşılaşma olayla gelir.
      case RelationType.arkadas:
      case RelationType.sevgili:
        return !baskaSehirde;
      default:
        break;
    }
    // Hane dışındaki yakın akrabalar (anne/baba/kardeş) başka şehirde de
    // görüşülmeye devam eder; uzak akrabalar bayram/ziyaret olaylarıyla
    // gelir.
    return person.relation == RelationType.anne ||
        person.relation == RelationType.baba ||
        person.relation == RelationType.kardes;
  }

  GameState copyWith({
    PlayerCharacter? player,
    List<Person>? people,
    List<Pet>? pets,
    ParentalStatus? parentalStatus,
    List<LifeLogEntry>? log,
    Map<String, int>? interactionCounts,
    Map<String, int>? lastInteractionAge,
    Set<String>? storyFlags,
    List<OwnedItem>? items,
    Set<String>? seenEventIds,
    Map<String, int>? lastEventAge,
    Map<String, String>? storyPeople,
    List<GiftRecord>? gifts,
    Object? pendingEvent = _unsetEvent,
    int? progressSinceLastEvent,
    int? extraEventsThisAge,
    EducationState? education,
    CareerState? career,
    List<BookProgress>? books,
    List<SocialAccount>? socialAccounts,
    Object? sponsorOffer = _unsetEvent,
    List<SponsorDeal>? sponsorDeals,
    Object? pendingInterview = _unsetEvent,
    Object? blackjack = _unsetEvent,
    int? wagerThisAge,
    Set<String>? licenses,
    Object? pendingLicenseExam = _unsetEvent,
    Set<String>? settledEstates,
    bool? deceased,
    int? deathAge,
    String? deathCause,
    List<LifeSummary>? pastLives,
    CareStatus? careStatus,
    int? grief,
    int? hardshipYears,
    GameSettings? settings,
    Object? residenceItemId = _unsetEvent,
    bool? movedOut,
    Object? pendingCrisis = _unsetEvent,
    int? lastCrisisAge,
    bool? healthWarned,
    Object? marriage = _unsetEvent,
    int? generation,
    Map<String, int>? proposalAges,
    List<PendingNotice>? notices,
    Object? heirChildId = _unsetEvent,
  }) {
    return GameState(
      seed: seed,
      player: player ?? this.player,
      people: people ?? this.people,
      pets: pets ?? this.pets,
      parentalStatus: parentalStatus ?? this.parentalStatus,
      log: log ?? this.log,
      interactionCounts: interactionCounts ?? this.interactionCounts,
      lastInteractionAge: lastInteractionAge ?? this.lastInteractionAge,
      storyFlags: storyFlags ?? this.storyFlags,
      items: items ?? this.items,
      seenEventIds: seenEventIds ?? this.seenEventIds,
      lastEventAge: lastEventAge ?? this.lastEventAge,
      storyPeople: storyPeople ?? this.storyPeople,
      gifts: gifts ?? this.gifts,
      pendingEvent: pendingEvent == _unsetEvent
          ? this.pendingEvent
          : pendingEvent as ActiveEvent?,
      progressSinceLastEvent:
          progressSinceLastEvent ?? this.progressSinceLastEvent,
      extraEventsThisAge: extraEventsThisAge ?? this.extraEventsThisAge,
      education: education ?? this.education,
      career: career ?? this.career,
      books: books ?? this.books,
      socialAccounts: socialAccounts ?? this.socialAccounts,
      sponsorOffer: sponsorOffer == _unsetEvent
          ? this.sponsorOffer
          : sponsorOffer as SponsorOffer?,
      sponsorDeals: sponsorDeals ?? this.sponsorDeals,
      pendingInterview: pendingInterview == _unsetEvent
          ? this.pendingInterview
          : pendingInterview as PendingInterview?,
      blackjack: blackjack == _unsetEvent
          ? this.blackjack
          : blackjack as BlackjackGame?,
      wagerThisAge: wagerThisAge ?? this.wagerThisAge,
      licenses: licenses ?? this.licenses,
      pendingLicenseExam: pendingLicenseExam == _unsetEvent
          ? this.pendingLicenseExam
          : pendingLicenseExam as PendingLicenseExam?,
      settledEstates: settledEstates ?? this.settledEstates,
      deceased: deceased ?? this.deceased,
      deathAge: deathAge ?? this.deathAge,
      deathCause: deathCause ?? this.deathCause,
      pastLives: pastLives ?? this.pastLives,
      careStatus: careStatus ?? this.careStatus,
      grief: grief ?? this.grief,
      hardshipYears: hardshipYears ?? this.hardshipYears,
      settings: settings ?? this.settings,
      residenceItemId: residenceItemId == _unsetEvent
          ? this.residenceItemId
          : residenceItemId as String?,
      movedOut: movedOut ?? this.movedOut,
      pendingCrisis: pendingCrisis == _unsetEvent
          ? this.pendingCrisis
          : pendingCrisis as PendingCrisis?,
      lastCrisisAge: lastCrisisAge ?? this.lastCrisisAge,
      healthWarned: healthWarned ?? this.healthWarned,
      marriage:
          marriage == _unsetEvent ? this.marriage : marriage as Marriage?,
      generation: generation ?? this.generation,
      proposalAges: proposalAges ?? this.proposalAges,
      notices: notices ?? this.notices,
      heirChildId: heirChildId == _unsetEvent
          ? this.heirChildId
          : heirChildId as String?,
    );
  }
}

const Object _unsetEvent = Object();
