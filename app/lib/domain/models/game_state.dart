import 'package:flutter/foundation.dart';

import '../../data/social_catalog.dart';

import 'blackjack_game.dart';
import 'education.dart';
import 'book_progress.dart';
import 'martial_progress.dart';
import 'hobby_progress.dart';
import 'lottery_ticket.dart';
import 'finger_profile.dart';
import 'career.dart';
import 'game_event.dart';
import 'game_settings.dart';
import 'gift_record.dart';
import 'owned_item.dart';
import 'life_log.dart';
import 'loan.dart';
import 'pending_race.dart';
import 'life_summary.dart';
import 'marriage.dart';
import 'parental_status.dart';
import 'pending_notice.dart';
import 'pending_interview.dart';
import 'pending_crisis.dart';
import 'military.dart';
import 'pending_wedding.dart';
import 'pregnancy.dart';
import 'pending_license_exam.dart';
import 'person.dart';
import 'celebrity_contact.dart';
import 'social_account.dart';
import 'sponsorship.dart';
import 'trip.dart';
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
    this.pendingWedding,
    this.pregnancy,
    this.military = const MilitaryState(),
    this.unprotectedTries = 0,
    this.ivfAttempts = 0,
    this.lastConceptionTryAge,
    this.conceptionTriesAtAge = 0,
    this.storyFlags = const <String>{},
    this.items = const <OwnedItem>[],
    this.seenEventIds = const <String>{},
    this.lastEventAge = const <String, int>{},
    this.eventSeenCounts = const <String, int>{},
    this.storyPeople = const <String, String>{},
    this.gifts = const <GiftRecord>[],
    this.pendingEvent,
    this.progressSinceLastEvent = 0,
    this.extraEventsThisAge = 0,
    this.education = const EducationState.notStarted(),
    this.career = const CareerState.none(),
    this.books = const <BookProgress>[],
    this.martialArts = const <MartialProgress>[],
    this.hobbies = const <HobbyProgress>[],
    this.lotteryTickets = const <LotteryTicket>[],
    this.fingerDeck = const <FingerProfile>[],
    this.fingerMatches = const <FingerProfile>[],
    this.socialAccounts = const <SocialAccount>[],
    this.celebrityContacts = const <CelebrityContact>[],
    this.sponsorOffer,
    this.sponsorDeals = const <SponsorDeal>[],
    this.trips = const <TripRecord>[],
    this.pendingInterview,
    this.blackjack,
    this.pendingRace,
    this.wagerThisAge = 0,
    this.loans = const <Loan>[],
    this.fingerIncoming = const <FingerProfile>[],
    this.fingerBio,
    this.fingerInterests = const <String>[],
    this.fingerPremiumUntilAge,
    this.lastSportAge,
    this.lastGroomingAge,
    this.lastLearningAge,
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
    this.pastMarriages = const <Marriage>[],
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

  /// Teklifi kabul edilmiş ama düğünü henüz yapılmamış evlilik
  /// (Paket 25).
  ///
  /// Kayda girer: yarıda kalan bir "evet" uygulama kapansa da kaybolmaz.
  final PendingWedding? pendingWedding;

  bool get hasPendingWedding => pendingWedding != null;

  /// Süren hamilelik (Paket 26).
  ///
  /// Kayda girer; doğum bir sonraki yaş ilerlemesinde olur.
  final Pregnancy? pregnancy;

  bool get isExpecting => pregnancy != null;

  /// Askerlik durumu (Paket 29).
  final MilitaryState military;

  /// Korunmadan geçen, çocukla sonuçlanmamış deneme sayısı (Paket 25).
  ///
  /// Doğumla sıfırlanır. Belli bir sayıdan sonra oyuncuya "olmuyor"
  /// denir; kısırlık böyle **anlaşılır**, baştan söylenmez.
  final int unprotectedTries;

  /// Bugüne kadar yapılan tüp bebek denemesi sayısı (Paket 35).
  ///
  /// Kayda girer; başarılı denemeden sonra da sıfırlanmaz, çünkü kaç kez
  /// denendiği hayatın bir parçasıdır.
  final int ivfAttempts;

  /// Bu yıl gebelik ihtimalinin denendiği yaş (Paket 25).
  ///
  /// Aynı yıl üst üste denemekle ihtimal katlanmaz; yıl başına bir kez
  /// hesaplanır.
  final int? lastConceptionTryAge;

  /// [lastConceptionTryAge] yaşında yapılan gebelik denemesi sayısı
  /// (D-086).
  ///
  /// Sayaç **yaşa bağlıdır**: oyuncunun yaşı değiştiği anda kendiliğinden
  /// geçersiz olur, çünkü okurken `lastConceptionTryAge` ile bugünkü yaş
  /// karşılaştırılır. Böylece ayrı bir sıfırlama adımına gerek kalmaz.
  final int conceptionTriesAtAge;

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

  /// Her olayın bu hayatta **kaç kez** çıktığı (Paket 20).
  ///
  /// `seenEventIds` yalnızca "çıktı mı" sorusunu yanıtlıyordu; tekrar eden
  /// olaylar bu yüzden bir hayatta üç dört kez görülebiliyordu. Sayaç,
  /// olayın ağırlığını her tekrarda düşürmek ve tekrar aralığını büyütmek
  /// için kullanılır.
  final Map<String, int> eventSeenCounts;

  /// Bir olayın bu hayatta kaç kez çıktığı.
  int eventSeenCount(String eventId) => eventSeenCounts[eventId] ?? 0;

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

  /// Paket 32: dövüş sanatlarındaki ilerleme (karate, kung fu, güreş).
  final List<MartialProgress> martialArts;

  /// Paket 39: kalıcı hobi geçmişi (müzik, resim, okuma, spor).
  ///
  /// Mevcut aktivitelerden beslenir; ayrı bir aktivite sistemi değildir.
  final List<HobbyProgress> hobbies;

  /// Paket 33: çekilişi bekleyen Milli Piyango biletleri.
  final List<LotteryTicket> lotteryTickets;

  /// Paket 34: Finger uygulamasında bakılmayı bekleyen profiller.
  final List<FingerProfile> fingerDeck;

  /// Paket 34: eşleşilen profiller. Tanışılanlar `metPersonId` taşır.
  final List<FingerProfile> fingerMatches;

  /// Açılmış sosyal medya hesapları. Hesap açmak **zorunlu değildir**;
  /// hesabı olmayan platformdan paylaşım veya olay gelmez.
  final List<SocialAccount> socialAccounts;

  /// Ünlülerle kurulan temasların kalıcı kaydı (Faho'nun isteği).
  ///
  /// Yalnızca **gerçekten denenmiş** ünlüler burada durur; katalogdaki
  /// her ünlü kayda girmez.
  final List<CelebrityContact> celebrityContacts;

  /// Bu ünlüyle daha önce temas kuruldu mu?
  CelebrityContact? contactWith(String celebrityId) {
    for (final CelebrityContact c in celebrityContacts) {
      if (c.celebrityId == celebrityId) return c;
    }
    return null;
  }

  /// Yanıt bekleyen sponsorluk teklifi (Paket 10).
  ///
  /// Aynı anda yalnızca bir teklif bekler; kabul veya ret verilene kadar
  /// yenisi gelmez.
  final SponsorOffer? sponsorOffer;

  /// Kabul edilmiş sponsorluk yükümlülükleri ve geçmişi.
  final List<SponsorDeal> sponsorDeals;

  /// Yapılmış geziler (Paket 11).
  ///
  /// Gezi kalıcı taşınmadan ayrıdır: yaşanan veya doğulan şehri
  /// değiştirmez. Kayıtlar silinmez.
  final List<TripRecord> trips;

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

  /// Sona ermiş **önceki** evlilikler (Paket 36).
  ///
  /// İkinci evlilikte eski kayıt silinmez, buraya taşınır: "kiminle, kaç
  /// yaşında evlenildi, nasıl bitti" bilgisi hayat boyu durur.
  final List<Marriage> pastMarriages;

  /// Bu kişiyle olan evlilik kaydı — şimdiki ya da geçmiş.
  Marriage? marriageWith(String personId) {
    final Marriage? simdiki = marriage;
    if (simdiki != null && simdiki.spouseId == personId) return simdiki;
    for (final Marriage m in pastMarriages) {
      if (m.spouseId == personId) return m;
    }
    return null;
  }

  /// Bu hayatta kaç kez evlenildi?
  int get marriageCount => pastMarriages.length + (marriage == null ? 0 : 1);

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

  /// Sonuçlanmayı bekleyen at yarışı bahsi (D-089).
  ///
  /// Bahis tutarı cüzdandan çıkmış, ödeme **henüz yapılmamıştır**.
  /// Animasyon bitince tek ve atomik bir işlemle kesinleşir.
  final PendingRace? pendingRace;

  /// Sonuçlanmamış bir bahis var mı?
  bool get hasPendingRace => pendingRace != null;

  /// **Bu yaşta** kumarhanede oynanan toplam bahis.
  ///
  /// Yıllık bahis sınırı için tutulur; yaş değişince sıfırlanır.
  final int wagerThisAge;

  /// Oyuncuyu **kendiliğinden beğenmiş** profiller (D-081).
  ///
  /// Karşılıklı beğeni için: oyuncu bu profillerden birini beğenirse
  /// eşleşme **kesindir**, çünkü karşı taraf zaten beğenmiştir.
  final List<FingerProfile> fingerIncoming;

  /// Oyuncunun kendi Finger profilindeki tanıtım yazısı (D-081).
  ///
  /// Boşsa profil doldurulmamıştır ve eşleşme ihtimali düşüktür.
  final String? fingerBio;

  /// Oyuncunun kendi profilinde yazan ilgi alanları (D-081).
  final List<String> fingerInterests;

  /// Premium üyeliğin geçerli olduğu son yaş; üyelik yoksa `null`.
  final int? fingerPremiumUntilAge;

  /// Premium üyelik şu an geçerli mi?
  bool get hasFingerPremium =>
      fingerPremiumUntilAge != null && player.age <= fingerPremiumUntilAge!;

  /// Oyuncunun profili doldurulmuş mu?
  bool get hasFingerProfile =>
      (fingerBio != null && fingerBio!.isNotEmpty) ||
      fingerInterests.isNotEmpty;

  /// Çekilmiş krediler (D-080).
  ///
  /// Kapanmış krediler de listede kalır: borç geçmişi silinmez, yeni
  /// başvuruda ödeme geçmişine bakılır.
  final List<Loan> loans;

  /// Oyuncunun en son spor yaptığı yaş; hiç yapmadıysa `null` (D-072).
  ///
  /// Tekrar sayaçları her yaşta sıfırlandığı için bakım geçmişi ayrıca
  /// tutulur: "kaç yıldır spor yapmıyor" sorusunun cevabı buradadır.
  final int? lastSportAge;

  /// Oyuncunun en son berber/kuaför bakımı yaptırdığı yaş.
  final int? lastGroomingAge;

  /// Oyuncunun en son zihnini çalıştırdığı (kitap, kurs) yaş.
  final int? lastLearningAge;

  /// Şu an kaç yıldır spor yapılmadığı; hiç yapılmadıysa `null`.
  int? get yearsSinceSport => _yearsSince(lastSportAge);

  /// Şu an kaç yıldır bakım yaptırılmadığı; hiç yaptırılmadıysa `null`.
  int? get yearsSinceGrooming => _yearsSince(lastGroomingAge);

  /// Şu an kaç yıldır zihin çalıştırılmadığı; hiç yapılmadıysa `null`.
  int? get yearsSinceLearning => _yearsSince(lastLearningAge);

  int? _yearsSince(int? age) {
    if (age == null) return null;
    final int fark = player.age - age;
    return fark < 0 ? 0 : fark;
  }

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
      // Torunla da başka şehirde olsanız görüşülür (Paket 12).
      case RelationType.torun:
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
    Object? pendingWedding = _unsetEvent,
    Object? pregnancy = _unsetEvent,
    MilitaryState? military,
    int? unprotectedTries,
    int? ivfAttempts,
    Object? lastConceptionTryAge = _unsetEvent,
    int? conceptionTriesAtAge,
    Set<String>? storyFlags,
    List<OwnedItem>? items,
    Set<String>? seenEventIds,
    Map<String, int>? lastEventAge,
    Map<String, int>? eventSeenCounts,
    Map<String, String>? storyPeople,
    List<GiftRecord>? gifts,
    Object? pendingEvent = _unsetEvent,
    int? progressSinceLastEvent,
    int? extraEventsThisAge,
    EducationState? education,
    CareerState? career,
    List<BookProgress>? books,
    List<MartialProgress>? martialArts,
    List<HobbyProgress>? hobbies,
    List<LotteryTicket>? lotteryTickets,
    List<FingerProfile>? fingerDeck,
    List<FingerProfile>? fingerMatches,
    List<SocialAccount>? socialAccounts,
    List<CelebrityContact>? celebrityContacts,
    Object? sponsorOffer = _unsetEvent,
    List<SponsorDeal>? sponsorDeals,
    List<TripRecord>? trips,
    Object? pendingInterview = _unsetEvent,
    Object? blackjack = _unsetEvent,
    Object? pendingRace = _unsetEvent,
    int? wagerThisAge,
    List<Loan>? loans,
    List<FingerProfile>? fingerIncoming,
    String? fingerBio,
    List<String>? fingerInterests,
    int? fingerPremiumUntilAge,
    int? lastSportAge,
    int? lastGroomingAge,
    int? lastLearningAge,
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
    List<Marriage>? pastMarriages,
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
      pendingWedding: pendingWedding == _unsetEvent
          ? this.pendingWedding
          : pendingWedding as PendingWedding?,
      pregnancy: pregnancy == _unsetEvent
          ? this.pregnancy
          : pregnancy as Pregnancy?,
      military: military ?? this.military,
      unprotectedTries: unprotectedTries ?? this.unprotectedTries,
      ivfAttempts: ivfAttempts ?? this.ivfAttempts,
      lastConceptionTryAge: lastConceptionTryAge == _unsetEvent
          ? this.lastConceptionTryAge
          : lastConceptionTryAge as int?,
      conceptionTriesAtAge: conceptionTriesAtAge ?? this.conceptionTriesAtAge,
      storyFlags: storyFlags ?? this.storyFlags,
      items: items ?? this.items,
      seenEventIds: seenEventIds ?? this.seenEventIds,
      lastEventAge: lastEventAge ?? this.lastEventAge,
      eventSeenCounts: eventSeenCounts ?? this.eventSeenCounts,
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
      martialArts: martialArts ?? this.martialArts,
      hobbies: hobbies ?? this.hobbies,
      lotteryTickets: lotteryTickets ?? this.lotteryTickets,
      fingerDeck: fingerDeck ?? this.fingerDeck,
      fingerMatches: fingerMatches ?? this.fingerMatches,
      socialAccounts: socialAccounts ?? this.socialAccounts,
      celebrityContacts: celebrityContacts ?? this.celebrityContacts,
      sponsorOffer: sponsorOffer == _unsetEvent
          ? this.sponsorOffer
          : sponsorOffer as SponsorOffer?,
      sponsorDeals: sponsorDeals ?? this.sponsorDeals,
      trips: trips ?? this.trips,
      pendingInterview: pendingInterview == _unsetEvent
          ? this.pendingInterview
          : pendingInterview as PendingInterview?,
      blackjack: blackjack == _unsetEvent
          ? this.blackjack
          : blackjack as BlackjackGame?,
      pendingRace: pendingRace == _unsetEvent
          ? this.pendingRace
          : pendingRace as PendingRace?,
      wagerThisAge: wagerThisAge ?? this.wagerThisAge,
      loans: loans ?? this.loans,
      fingerIncoming: fingerIncoming ?? this.fingerIncoming,
      fingerBio: fingerBio ?? this.fingerBio,
      fingerInterests: fingerInterests ?? this.fingerInterests,
      fingerPremiumUntilAge:
          fingerPremiumUntilAge ?? this.fingerPremiumUntilAge,
      lastSportAge: lastSportAge ?? this.lastSportAge,
      lastGroomingAge: lastGroomingAge ?? this.lastGroomingAge,
      lastLearningAge: lastLearningAge ?? this.lastLearningAge,
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
      pastMarriages: pastMarriages ?? this.pastMarriages,
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
