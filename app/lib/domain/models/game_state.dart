import 'package:flutter/foundation.dart';

import '../../data/social_catalog.dart';
import '../features/feature_catalog.dart';

import 'blackjack_game.dart';
import 'business.dart';
import 'criminal_record.dart';
import 'education.dart';
import 'family_drama.dart';
import 'family_issue.dart';
import 'book_progress.dart';
import 'combat_career.dart';
import 'martial_progress.dart';
import '../sports/football_career.dart';
import 'school_club_progress.dart';
import 'hobby_progress.dart';
import 'lottery_ticket.dart';
import '../../data/finger_catalog.dart';
import 'finger_profile.dart';
import 'wealth.dart';
import 'career.dart';
import 'chronic_condition.dart';
import 'health_history.dart';
import 'household.dart';
import 'investment.dart';
import 'market_state.dart';
import 'game_event.dart';
import 'game_settings.dart';
import 'gift_record.dart';
import 'owned_item.dart';
import 'rental.dart';
import 'life_log.dart';
import 'loan.dart';
import 'pending_race.dart';
import '../life/year_review.dart';
import 'life_summary.dart';
import 'marriage.dart';
import 'parental_status.dart';
import 'pending_notice.dart';
import 'pending_interview.dart';
import 'pending_crisis.dart';
import 'pending_trial.dart';
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
    this.familyPlan = FamilyPlan.belirsiz,
    this.familyPlanPartnerId,
    this.military = const MilitaryState(),
    this.legal = const LegalState(),
    this.businesses = const <Business>[],
    this.pendingTrial,
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
    this.combatCareers = const <CombatCareer>[],
    this.schoolClubs = const <SchoolClubProgress>[],
    this.footballCareer,
    this.footballTrialAge,
    this.hobbies = const <HobbyProgress>[],
    this.chronicConditions = const <ChronicCondition>[],
    this.goalsReachedAt = const <String, int>{},
    this.vehicleInspectionAt = const <String, int>{},
    this.alimony,
    this.investments = const <Holding>[],
    this.termDeposits = const <TermDeposit>[],
    this.investmentHistory = const <InvestmentRecord>[],
    this.market = const MarketState(),
    this.leases = const <Lease>[],
    this.propertyLedgers = const <PropertyLedger>[],
    this.landlord,
    this.healthHistory = const <HealthHistoryEntry>[],
    this.lotteryTickets = const <LotteryTicket>[],
    this.fingerDeck = const <FingerProfile>[],
    this.fingerMatches = const <FingerProfile>[],
    this.socialAccounts = const <SocialAccount>[],
    this.celebrityContacts = const <CelebrityContact>[],
    this.sponsorOffer,
    this.mediaInvitationId,
    this.mediaInvitationAge,
    this.mediaJobLastAge = const <String, int>{},
    this.friendNewsLastAge = const <String, int>{},
    this.sponsorDeals = const <SponsorDeal>[],
    this.trips = const <TripRecord>[],
    this.pendingInterview,
    this.blackjack,
    this.pendingRace,
    this.yearMark,
    this.lastYearSummary,
    this.wagerThisAge = 0,
    this.loans = const <Loan>[],
    this.fingerIncoming = const <FingerProfile>[],
    this.fingerBio,
    this.fingerInterests = const <String>[],
    this.fingerPremiumUntilAge,
    this.fingerIntent = FingerIntent.belirsiz,
    this.fingerWealthFilter,
    this.lastSportAge,
    this.lastGroomingAge,
    this.lastLearningAge,
    this.familyIssues = const <FamilyIssue>[],
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
    this.healthDangerWarned = false,
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

  /// Çiftin çocuk planı (Paket BK/2, Q-201).
  ///
  /// Kayıt **çifte** aittir: planı hangi partnerle konuştuğun
  /// [familyPlanPartnerId] içinde durur. Ayrılıp başkasıyla
  /// birlikte olan oyuncunun eski niyeti yeni ilişkiye taşınmaz;
  /// [familyPlanFor] o yüzden kimliği karşılaştırır.
  final FamilyPlan familyPlan;

  /// Planın konuşulduğu kişinin kimliği; plan yoksa `null`.
  final String? familyPlanPartnerId;

  /// Bu kişiyle konuşulmuş plan; konuşulmamışsa [FamilyPlan.belirsiz].
  FamilyPlan familyPlanFor(String partnerId) =>
      familyPlanPartnerId == partnerId ? familyPlan : FamilyPlan.belirsiz;

  /// Askerlik durumu (Paket 29).
  final MilitaryState military;

  /// Kurulmuş işler (D-132).
  ///
  /// **Kayıt silinmez:** batan ya da devredilen iş listede kalır. Eski
  /// kayıtlarda bu alan yoktur ve boş açılır — geriye dönük iş
  /// **uydurulmaz**.
  final List<Business> businesses;

  /// Adli durum: dosyalar, sabıka, hapis ve denetim dönemi (D-128).
  ///
  /// Kayıt **silinmez**: kapanan dosya listede kalır. Eski kayıtlarda bu
  /// alan yoktur ve boş açılır — geriye dönük sabıka **uydurulmaz**.
  final LegalState legal;

  /// Ekranda cevap bekleyen duruşma (D-128).
  final PendingTrial? pendingTrial;

  bool get hasPendingTrial => pendingTrial != null;

  /// Oyuncu şu an cezaevinde mi?
  bool get isImprisoned => legal.isImprisoned;

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
  /// Bir eşya örneğini envanterden çıkarır.
  ///
  /// **Kiralama kayıtları da temizlenir (D-163).** Gerçek bir exploit
  /// buradaydı: kiradaki ev satılınca sözleşme listede kalıyor ve kira
  /// gelmeye devam ediyordu — elinde olmayan evden gelir. Tek çıkış
  /// noktası burası olduğu için temizlik burada yapılıyor; satış, boşanma
  /// ve başka bütün yollar aynı yerden geçiyor.
  GameState removeItem(String itemId) => copyWith(
        items: List<OwnedItem>.unmodifiable(
          items.where((OwnedItem i) => i.id != itemId).toList(growable: false),
        ),
        leases: List<Lease>.unmodifiable(
          leases
              .where((Lease l) => l.propertyItemId != itemId)
              .toList(growable: false),
        ),
        propertyLedgers: List<PropertyLedger>.unmodifiable(
          propertyLedgers
              .where((PropertyLedger l) => l.propertyItemId != itemId)
              .toList(growable: false),
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

  /// Dövüş sanatlarındaki **rekabet** kariyerleri (Paket AL).
  ///
  /// `martialArts` teknik ilerlemeyi tutar (kaç ders, hangi kuşak);
  /// bu liste müsabakayı tutar (rakip, sıralama, sakatlık, ödül,
  /// emeklilik). Eski kayıtlarda yoktur ve boş olarak yüklenir.
  final List<CombatCareer> combatCareers;

  /// Okul kulüpleri ve takımlarındaki kalıcı geçmiş (Paket AU).
  ///
  /// Aktif üyelikler ve **bitmiş** üyelikler aynı listede durur: okul
  /// değişince ya da ayrılınca kayıt silinmez, `active` kapanır. Çocuklukta
  /// kurulan futbol geçmişi profesyonel yolun önkoşulu olduğu için bu
  /// listenin kaybolmaması kritiktir. Eski kayıtlarda yoktur ve boş
  /// yüklenir; geçmiş **uydurulmaz**.
  final List<SchoolClubProgress> schoolClubs;

  /// Profesyonel futbol kariyeri (Paket AU). Yoksa `null`.
  ///
  /// **Normal bir meslek değildir:** `kJobCatalog` içinde yer almaz,
  /// çünkü ileride kulüp, lig, sezon, kontrat ve transfer taşıyacak.
  /// Okul futbolu bu alanı açmaz; profesyonel deneme açar.
  final FootballCareer? footballCareer;

  /// Profesyonel futbol denemesine en son girilen yaş (Paket AY).
  ///
  /// **Neden var:** deneme yılda bir kezdir. Bu alan olmadan oyuncu aynı
  /// yıl içinde düğmeye kabul alana kadar basabiliyordu; ölçümde kapıya
  /// gelen 49 hayatın 49'u profesyonel oldu. Deneme bir fırsattır,
  /// çevirmeli bir kura makinesi değil.
  final int? footballTrialAge;

  /// Paket 39: kalıcı hobi geçmişi (müzik, resim, okuma, spor).
  ///
  /// Mevcut aktivitelerden beslenir; ayrı bir aktivite sistemi değildir.
  final List<HobbyProgress> hobbies;

  /// D-153: oyuncunun taşıdığı kronik sağlık durumları.
  ///
  /// Kayıt silinmez; geçen durum da listede kalır ve `endedAtAge` dolar.
  final List<ChronicCondition> chronicConditions;

  /// D-156: hedef kimliği -> ulaşıldığı yaş.
  ///
  /// Sonradan hesaplanmaz: ulaşıldığı **yıl** yazılır ve bir daha
  /// değişmez. Böylece "kırk beşinde ilk milyonunu gördün" cümlesi
  /// gerçek bir andır, bugünün durumundan türetilmiş bir tahmin değil.
  final Map<String, int> goalsReachedAt;

  /// Bu hedefe ulaşıldı mı?
  bool goalReached(String id) => goalsReachedAt.containsKey(id);

  /// D-162: portföydeki pozisyonlar. Boşsa hiç yatırım yapılmamıştır.
  final List<Holding> investments;

  /// D-162: açık ve kapanmamış vadeli hesaplar.
  final List<TermDeposit> termDeposits;

  /// D-162: portföy geçmişi (alım, satım, vade kapanışı, sıra dışı yıl).
  ///
  /// Yıllık fiyat hareketi buraya yazılmaz; yoksa geçmiş okunamaz hâle
  /// gelirdi.
  final List<InvestmentRecord> investmentHistory;

  /// D-162: piyasanın kalıcı durumu (rejim, gizli parametreler, endeks).
  final MarketState market;

  /// Yürüyen kira sözleşmeleri (D-163).
  ///
  /// Bir mülkte en fazla bir sözleşme olur. **"Bu ev kirada" bilgisinin
  /// tek kaynağı budur**; `OwnedItem.rentedOut` yalnızca eski kayıtları
  /// açmak için duruyor ve yükleme sırasında sözleşmeye çevriliyor.
  final List<Lease> leases;

  /// Mülk başına ömür boyu defter: kira, bakım, boş yıl, değer.
  final List<PropertyLedger> propertyLedgers;

  /// Oyuncu kiradaysa ev sahibi kaydı. Person değil, hafif kayıt.
  final LandlordRecord? landlord;

  /// Bu mülkün yürüyen sözleşmesi (yoksa null).
  Lease? leaseOf(String itemId) {
    for (final Lease l in leases) {
      if (l.propertyItemId == itemId) return l;
    }
    return null;
  }

  /// Bu mülkün defteri (yoksa boş bir defter).
  PropertyLedger ledgerOf(String itemId) {
    for (final PropertyLedger l in propertyLedgers) {
      if (l.propertyItemId == itemId) return l;
    }
    return PropertyLedger(propertyItemId: itemId);
  }

  /// Sahip olunan konutlar.
  List<OwnedItem> get properties =>
      items.where((OwnedItem i) => i.isProperty).toList(growable: false);

  /// Portföyün bugünkü toplam değeri (vadeli anaparalar dahil).
  ///
  /// Vadeli hesapta **anapara** sayılır, vade sonu değeri değil: henüz
  /// kazanılmamış faizi servet gibi göstermek yanlış olurdu.
  int get portfolioValue =>
      investments.fold<int>(0, (int t, Holding h) => t + h.value) +
      termDeposits.fold<int>(0, (int t, TermDeposit d) => t + d.amount);

  /// Portföye hayat boyu yatırılan toplam (₺).
  int get portfolioInvested =>
      investments.fold<int>(0, (int t, Holding h) => t + h.totalInvested) +
      termDeposits.fold<int>(0, (int t, TermDeposit d) => t + d.amount);

  /// Elde duran pozisyonların gerçekleşmemiş kâr/zararı (₺).
  int get portfolioUnrealized =>
      investments.fold<int>(0, (int t, Holding h) => t + h.unrealizedProfit);

  /// Hayat boyu gerçekleşen kâr/zarar (₺).
  int get portfolioRealized =>
      investments.fold<int>(0, (int t, Holding h) => t + h.realizedProfit);

  /// Bu türdeki pozisyon; yoksa `null`.
  Holding? holdingOf(String typeId) {
    for (final Holding h in investments) {
      if (h.typeId == typeId) return h;
    }
    return null;
  }

  /// D-160: süren ya da kapanmış nafaka kaydı; hiç olmadıysa `null`.
  ///
  /// Kayıt silinmez: süresi dolan nafaka listede kalır ve `endedAtAge`
  /// dolar. Q-118'in "nafaka yazılmasın" kararını değiştirir (Q-163).
  final Alimony? alimony;

  /// D-157: araç kimliği -> muayeneden **geçtiği** son yaş.
  ///
  /// Eksik anahtar "hiç muayene edilmemiş" demektir; o zaman aracın
  /// edinildiği yaş başlangıç sayılır.
  final Map<String, int> vehicleInspectionAt;

  /// D-153: atlatılmış sağlık krizlerinin kalıcı geçmişi.
  ///
  /// Önceden yalnızca son krizin yaşı tutuluyordu (`lastCrisisAge`).
  final List<HealthHistoryEntry> healthHistory;

  /// Şu an süren kronik durumlar.
  List<ChronicCondition> get activeChronic => chronicConditions
      .where((ChronicCondition c) => c.isActive)
      .toList(growable: false);

  /// Bu kronik durum şu an sürüyor mu?
  bool hasChronic(String typeId) => chronicConditions.any(
      (ChronicCondition c) => c.typeId == typeId && c.isActive);

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

  /// Kendiliğinden gelen medya daveti: işin kimliği (D-120).
  ///
  /// Faho bildirdi: "oyuncunun menüye girip fırsat seçmesi yerine bazen
  /// firmalar/TV programları kendiliğinden teklif yollasın". Davet gelen
  /// iş için Ün şartı aranmaz ve başvuru reddedilmez — zaten **onlar**
  /// çağırmıştır. Davet o yıl içinde kullanılmazsa düşer.
  final String? mediaInvitationId;

  /// Davetin geldiği yaş; davet yalnızca o yıl geçerlidir.
  final int? mediaInvitationAge;

  /// Bu iş için şu an geçerli bir davet var mı?
  bool hasMediaInvitation(String jobId) =>
      mediaInvitationId == jobId && mediaInvitationAge == player.age;

  /// Her medya işinin **en son hangi yaşta** yapıldığı (D-147).
  ///
  /// Faho bildirdi: "medya fırsatları sürekli açık olması, oradan da çok
  /// kolay para spamlanabiliyor... bir fenomen her sene radyo programına
  /// vb işlere çağırılıyor mu gibi düşün". Aynı kapı her yıl çalınmaz;
  /// bu harita bekleme süresinin ölçüldüğü yerdir.
  ///
  /// Eski kayıtlarda yoktur; boş açılır ve geriye dönük geçmiş
  /// **uydurulmaz**.
  final Map<String, int> mediaJobLastAge;

  /// Bu iş en son hangi yaşta yapıldı? Hiç yapılmadıysa `null`.
  int? mediaJobDoneAt(String jobId) => mediaJobLastAge[jobId];

  /// Arkadaş haberlerinin en son hangi yaşta geldiği (D-149).
  ///
  /// Faho bildirdi: "yakın arkadaş ile alakalı aynı bildirimler çok fazla
  /// geliyor! Ahmet her sene iş değiştiriyor ve sesi çok iyi geliyor
  /// mesela." Anahtarlar `kişiKimliği` ve `kişiKimliği|haberTürü`
  /// biçimindedir; ilki "bu kişiden ne zaman haber geldi", ikincisi "aynı
  /// haber ne zaman geldi" sorusunu yanıtlar.
  ///
  /// Eski kayıtlarda yoktur; boş açılır ve geriye dönük geçmiş
  /// **uydurulmaz**.
  final Map<String, int> friendNewsLastAge;

  /// Bu kişiden en son hangi yaşta haber geldi?
  int? friendNewsAt(String personId) => friendNewsLastAge[personId];

  /// Bu kişiden bu tür haber en son hangi yaşta geldi?
  int? friendNewsAtKind(String personId, String kind) =>
      friendNewsLastAge['$personId|$kind'];

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

  /// Çıkarılabilir özellik açık mı? (Paket BL)
  ///
  /// Motorlar ve ekranlar bu tek kapıdan sorar; kapalı özellik hem
  /// listelenmez hem de çağrıldığında reddedilir. Ayrıntı:
  /// `docs/FEATURE_FLAGS.md`.
  bool featureOn(FeatureId id) => settings.features.isOn(id);

  /// Kapalı özelliğin kısa gerekçesi; açıkken `null`.
  String? featureBlockReason(FeatureId id) =>
      featureOn(id) ? null : '${id.title} ayarlardan kapatılmış.';

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

  /// Hayati tehlike bandı uyarısı verildi mi? (Paket AQ)
  ///
  /// [healthWarned] "kritik derecede düşük" bandına (11-25) girildiğinde
  /// bir kez konuşur. Bu alan ise 1-10 bandı içindir: iki bant ayrı
  /// şeylerdir ve tek bayrakla ayrılamıyordu, bu yüzden 22 → 8 düşüşü
  /// oyuncuya hiç haber verilmiyordu. Her +1/-1 için pencere açılmasın
  /// diye bant **geçişinde** bir kez çalışır ve bant düzelince sıfırlanır.
  final bool healthDangerWarned;

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

  /// Bildirimi kuyruğa ekler.
  ///
  /// **Aynı kimlikli bildirim ikinci kez girmez**: motor bir yılda iki
  /// kez çağrılsa da oyuncu aynı pencereyi iki kez görmez.
  GameState queueNotice(PendingNotice notice) {
    if (notices.any((PendingNotice n) => n.id == notice.id)) return this;
    return copyWith(
      notices: List<PendingNotice>.unmodifiable(<PendingNotice>[
        ...notices,
        notice,
      ]),
    );
  }

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

  /// İçinde bulunulan yılın başındaki değerlerin fotoğrafı (D-096).
  ///
  /// Yıl sonunda "ne değişti" sorusu bununla yanıtlanır; uydurma bir
  /// başlangıç değeri kullanılmaz.
  final YearMark? yearMark;

  /// Biten yılın özeti (D-096).
  ///
  /// Oyuncu hayat günlüğünü taramadan yılın nasıl geçtiğini görebilsin
  /// diye ana ekranda gösterilir.
  final YearSummary? lastYearSummary;

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

  /// Oyuncunun Finger'da **ne aradığı** (D-107).
  ///
  /// Buluşmanın sonucu hem buna hem karşı tarafın niyetine bakar:
  /// tanışmak kendiliğinden sevgili olmak değildir.
  final FingerIntent fingerIntent;

  /// Adayları ekonomik duruma göre süzme tercihi (D-107).
  ///
  /// `null` ise süzgeç kapalıdır ve bütün adaylar gösterilir. Süzgeç
  /// gerçek bir kısıttır: dar tutmak deste üretimini zorlaştırır.
  final WealthTier? fingerWealthFilter;

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

  /// Birden fazla yıl süren aile meseleleri (Paket AP §4).
  ///
  /// Kapanmış meseleler de listede kalır: "üç yıl önce ne olmuştu"
  /// sorusunun cevabı kaybolmasın (§51). Liste [prototypeOnlyMaxIssues]
  /// ile sınırlı tutulur ki kayıt şişmesin.
  final List<FamilyIssue> familyIssues;

  /// prototypeOnly: kayıtta tutulan en fazla aile meselesi sayısı.
  static const int prototypeOnlyMaxIssues = 40;

  /// Hâlâ süren aile meseleleri.
  Iterable<FamilyIssue> get openFamilyIssues =>
      familyIssues.where((FamilyIssue i) => i.isOpen);

  /// Bu kişinin süren meselesi; yoksa `null`.
  FamilyIssue? openFamilyIssueFor(String personId, [FamilyIssueKind? kind]) {
    for (final FamilyIssue mesele in familyIssues) {
      if (!mesele.isOpen) continue;
      if (mesele.personId != personId) continue;
      if (kind != null && mesele.kind != kind) continue;
      return mesele;
    }
    return null;
  }

  /// Bu yıl **büyük** bir aile kararı daha çıkabilir mi? (Paket AP §3)
  ///
  /// Kural: bir yılda en fazla bir büyük aile kararı. Beş çocuğu olan
  /// oyuncu aynı yıl beş aile krizi yaşamaz; aile hayatı oyunun geri
  /// kalanını boğmaz.
  ///
  /// Sayaç ayrı bir save alanında değil, meselelerin kendi
  /// `lastEventAge` değerinde duruyor: §3'ün sorduğu soruyu zaten o
  /// alan cevaplıyor, ikinci bir alan açmak gerekmedi.
  bool get canOpenFamilyDecision {
    for (final FamilyIssue mesele in familyIssues) {
      if (mesele.lastEventAge == player.age) return false;
      if (mesele.openedAtAge == player.age) return false;
    }
    return true;
  }

  /// Bu hayatın gizli aile dram eğilimi (Paket AP §2).
  ///
  /// Kayıttan okunmaz, tohumdan türetilir; o yüzden eski kayıtlar da
  /// bir profille açılır.
  FamilyDramaProfile get familyDrama => FamilyDramaProfile.forSeed(seed);

  /// Yeni bir aile meselesi açar; aynı mesele ikinci kez açılmaz.
  ///
  /// [canOpenFamilyDecision] yanlışsa hiçbir şey yapılmaz: §3'ün
  /// sınırı tek kapıdan geçsin.
  GameState openFamilyIssue({
    required FamilyIssueKind kind,
    required String personId,
  }) {
    if (!canOpenFamilyDecision) return this;
    if (openFamilyIssueFor(personId, kind) != null) return this;
    final FamilyIssue yeni = FamilyIssue(
      id: FamilyIssue.idFor(kind, personId, player.age),
      kind: kind,
      personId: personId,
      openedAtAge: player.age,
      lastEventAge: player.age,
    );
    return copyWith(familyIssues: _trimIssues(<FamilyIssue>[
      ...familyIssues,
      yeni,
    ]));
  }

  /// Bir meseleyi günceller; kimlik bulunamazsa durum değişmez.
  GameState updateFamilyIssue(
    String issueId, {
    FamilyIssueStatus? status,
    int? stage,
    int? lastEventAge,
    int? resolvedAtAge,
    FamilyIssueResponse? response,
  }) {
    bool bulundu = false;
    final List<FamilyIssue> yeni = <FamilyIssue>[
      for (final FamilyIssue mesele in familyIssues)
        if (mesele.id == issueId)
          () {
            bulundu = true;
            return mesele.copyWith(
              status: status,
              stage: stage,
              lastEventAge: lastEventAge,
              resolvedAtAge: resolvedAtAge,
              response: response,
            );
          }()
        else
          mesele,
    ];
    if (!bulundu) return this;
    return copyWith(familyIssues: List<FamilyIssue>.unmodifiable(yeni));
  }

  /// Kayıt şişmesin: en eskiler düşer, **açık** meseleler korunur.
  static List<FamilyIssue> _trimIssues(List<FamilyIssue> hepsi) {
    if (hepsi.length <= prototypeOnlyMaxIssues) {
      return List<FamilyIssue>.unmodifiable(hepsi);
    }
    final List<FamilyIssue> acik =
        hepsi.where((FamilyIssue i) => i.isOpen).toList();
    final List<FamilyIssue> kapali =
        hepsi.where((FamilyIssue i) => !i.isOpen).toList();
    final int yer = prototypeOnlyMaxIssues - acik.length;
    if (yer <= 0) return List<FamilyIssue>.unmodifiable(acik);
    return List<FamilyIssue>.unmodifiable(<FamilyIssue>[
      ...kapali.sublist(kapali.length - yer),
      ...acik,
    ]);
  }

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
      // Komşu (Paket BU): komşuluk **oturulan eve** bağlıdır. Kişinin
      // `homeTie` anahtarı bugünkü evin anahtarıyla aynı olduğu sürece
      // erişilebilir; taşınınca `Neighbours.reconcile` onu eski komşu
      // yapar ve bu dal da kapanır.
      case RelationType.komsu:
        return !baskaSehirde;
      // Eski komşu: kayıt durur, gündelik listede görünmez.
      case RelationType.eskiKomsu:
        return false;
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
    FamilyPlan? familyPlan,
    Object? familyPlanPartnerId = _unsetEvent,
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
    List<CombatCareer>? combatCareers,
    List<SchoolClubProgress>? schoolClubs,
    FootballCareer? footballCareer,
    int? footballTrialAge,
    List<HobbyProgress>? hobbies,
    List<ChronicCondition>? chronicConditions,
    Map<String, int>? goalsReachedAt,
    Map<String, int>? vehicleInspectionAt,
    Object? alimony = _unsetEvent,
    List<Holding>? investments,
    List<TermDeposit>? termDeposits,
    List<InvestmentRecord>? investmentHistory,
    MarketState? market,
    List<HealthHistoryEntry>? healthHistory,
    List<LotteryTicket>? lotteryTickets,
    List<FingerProfile>? fingerDeck,
    List<FingerProfile>? fingerMatches,
    List<SocialAccount>? socialAccounts,
    List<CelebrityContact>? celebrityContacts,
    Object? sponsorOffer = _unsetEvent,
    Object? mediaInvitationId = _unsetEvent,
    Object? mediaInvitationAge = _unsetEvent,
    Map<String, int>? mediaJobLastAge,
    Map<String, int>? friendNewsLastAge,
    List<SponsorDeal>? sponsorDeals,
    List<TripRecord>? trips,
    Object? pendingInterview = _unsetEvent,
    Object? blackjack = _unsetEvent,
    Object? pendingRace = _unsetEvent,
    Object? yearMark = _unsetEvent,
    Object? lastYearSummary = _unsetEvent,
    int? wagerThisAge,
    List<Loan>? loans,
    List<FingerProfile>? fingerIncoming,
    String? fingerBio,
    List<String>? fingerInterests,
    int? fingerPremiumUntilAge,
    FingerIntent? fingerIntent,
    Object? fingerWealthFilter = _unsetEvent,
    int? lastSportAge,
    int? lastGroomingAge,
    int? lastLearningAge,
    List<FamilyIssue>? familyIssues,
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
    List<Lease>? leases,
    List<PropertyLedger>? propertyLedgers,
    Object? landlord = _unsetEvent,
    Object? residenceItemId = _unsetEvent,
    bool? movedOut,
    Object? pendingCrisis = _unsetEvent,
    LegalState? legal,
    List<Business>? businesses,
    Object? pendingTrial = _unsetEvent,
    int? lastCrisisAge,
    bool? healthWarned,
    bool? healthDangerWarned,
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
      familyPlan: familyPlan ?? this.familyPlan,
      familyPlanPartnerId: familyPlanPartnerId == _unsetEvent
          ? this.familyPlanPartnerId
          : familyPlanPartnerId as String?,
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
      combatCareers: combatCareers ?? this.combatCareers,
      schoolClubs: schoolClubs ?? this.schoolClubs,
      footballCareer: footballCareer ?? this.footballCareer,
      footballTrialAge: footballTrialAge ?? this.footballTrialAge,
      hobbies: hobbies ?? this.hobbies,
      chronicConditions: chronicConditions ?? this.chronicConditions,
      goalsReachedAt: goalsReachedAt ?? this.goalsReachedAt,
      vehicleInspectionAt:
          vehicleInspectionAt ?? this.vehicleInspectionAt,
      alimony: alimony == _unsetEvent ? this.alimony : alimony as Alimony?,
      investments: investments ?? this.investments,
      termDeposits: termDeposits ?? this.termDeposits,
      investmentHistory: investmentHistory ?? this.investmentHistory,
      market: market ?? this.market,
      healthHistory: healthHistory ?? this.healthHistory,
      lotteryTickets: lotteryTickets ?? this.lotteryTickets,
      fingerDeck: fingerDeck ?? this.fingerDeck,
      fingerMatches: fingerMatches ?? this.fingerMatches,
      socialAccounts: socialAccounts ?? this.socialAccounts,
      celebrityContacts: celebrityContacts ?? this.celebrityContacts,
      sponsorOffer: sponsorOffer == _unsetEvent
          ? this.sponsorOffer
          : sponsorOffer as SponsorOffer?,
      mediaInvitationId: mediaInvitationId == _unsetEvent
          ? this.mediaInvitationId
          : mediaInvitationId as String?,
      mediaJobLastAge: mediaJobLastAge == null
          ? this.mediaJobLastAge
          : Map<String, int>.unmodifiable(mediaJobLastAge),
      friendNewsLastAge: friendNewsLastAge == null
          ? this.friendNewsLastAge
          : Map<String, int>.unmodifiable(friendNewsLastAge),
      mediaInvitationAge: mediaInvitationAge == _unsetEvent
          ? this.mediaInvitationAge
          : mediaInvitationAge as int?,
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
      yearMark:
          yearMark == _unsetEvent ? this.yearMark : yearMark as YearMark?,
      lastYearSummary: lastYearSummary == _unsetEvent
          ? this.lastYearSummary
          : lastYearSummary as YearSummary?,
      wagerThisAge: wagerThisAge ?? this.wagerThisAge,
      loans: loans ?? this.loans,
      fingerIncoming: fingerIncoming ?? this.fingerIncoming,
      fingerBio: fingerBio ?? this.fingerBio,
      fingerInterests: fingerInterests ?? this.fingerInterests,
      fingerPremiumUntilAge:
          fingerPremiumUntilAge ?? this.fingerPremiumUntilAge,
      fingerIntent: fingerIntent ?? this.fingerIntent,
      fingerWealthFilter: fingerWealthFilter == _unsetEvent
          ? this.fingerWealthFilter
          : fingerWealthFilter as WealthTier?,
      lastSportAge: lastSportAge ?? this.lastSportAge,
      lastGroomingAge: lastGroomingAge ?? this.lastGroomingAge,
      lastLearningAge: lastLearningAge ?? this.lastLearningAge,
      familyIssues: familyIssues ?? this.familyIssues,
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
      leases: leases ?? this.leases,
      propertyLedgers: propertyLedgers ?? this.propertyLedgers,
      landlord: landlord == _unsetEvent
          ? this.landlord
          : landlord as LandlordRecord?,
      residenceItemId: residenceItemId == _unsetEvent
          ? this.residenceItemId
          : residenceItemId as String?,
      movedOut: movedOut ?? this.movedOut,
      pendingCrisis: pendingCrisis == _unsetEvent
          ? this.pendingCrisis
          : pendingCrisis as PendingCrisis?,
      legal: legal ?? this.legal,
      businesses: businesses == null
          ? this.businesses
          : List<Business>.unmodifiable(businesses),
      pendingTrial: pendingTrial == _unsetEvent
          ? this.pendingTrial
          : pendingTrial as PendingTrial?,
      lastCrisisAge: lastCrisisAge ?? this.lastCrisisAge,
      healthWarned: healthWarned ?? this.healthWarned,
      healthDangerWarned: healthDangerWarned ?? this.healthDangerWarned,
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
