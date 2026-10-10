import 'package:flutter/foundation.dart';

import '../../data/company_catalog.dart';
import '../../data/insurance_catalog.dart';
import '../../data/item_catalog.dart';
import '../economy/financial_strain.dart';
import 'relation.dart';
import 'school_club_progress.dart';

/// Olayın hangi yaşam alanından geldiği (D-023).
enum EventCategory {
  aile('Aile'),
  okul('Okul'),
  mahalle('Mahalle'),
  kisisel('Kişisel'),
  yetiskinlik('Yetişkinlik');

  const EventCategory(this.label);

  final String label;
}

/// Bir olayın çıkabilmesi için aranan koşullar (D-009).
///
/// Yaş tek başına yeterli değildir: olayın kişisi gerçekten yaşıyor olmalı,
/// gereken hikâye izi bulunmalı, sahip olunmayan varlık için olay çıkmamalıdır.
@immutable
class EventRequirement {
  const EventRequirement({
    this.minAge = 0,
    this.maxAge = 120,
    this.livingRelations = const <RelationType>{},
    this.requireSameHousehold = false,
    this.requiredFlags = const <String>{},
    this.forbiddenFlags = const <String>{},
    this.requiredPossessions = const <String>{},
    this.requiredPossessionKinds = const <ItemKind>{},
    this.requiresSchoolStudent = false,
    this.requiresStudent = false,
    this.minGrade,
    this.maxGrade,
    this.requiresNeglectedRelative = false,
    this.personRole,
    this.personMinAge,
    this.personMaxAge,
    this.requireOutsideHousehold = false,
    this.requireReachable = false,
    this.requiresSocialAccount = false,
    this.requiresFriendCircle = false,
    this.minElderSupportYears = 0,
    this.minElderAloneYears = 0,
    this.requiredLicenses = const <String>{},
    this.requiresEmployed = false,
    this.requiresTenant = false,
    this.requiresOwnedResidence = false,
    this.forbidsProperty = false,
    this.maxComfort,
    this.minComfort,
    this.forbidsVehicle = false,
    this.requiresMinYearsInJob = 0,
    this.minFame = 0,
    this.requiresTripMemory = false,
    this.requiresRetired = false,
    this.requiresActiveClubId,
    this.minClubYears = 0,
    this.minSquadRole,
    this.requiredHobbyId,
    this.minHobbyYears = 0,
    this.minHobbyStage = 0,
    this.requiresLivingPet = false,
    this.minPetAge = 0,
    this.minPetYearsTogether = 0,
    this.requiresActiveHobby = false,
    this.requiresOpenCase = false,
    this.requiresRecord = false,
    this.requiresReleased = false,
    this.requiresPortfolio = false,
    this.requiresCompanyStatus,
    this.minNetWorth,
    this.requiresCrisis = false,
    this.requiresHotAsset,
    this.requiresHotAssetHeat = 68,
    this.requiresStrainedCompany = false,
    this.requiresThrivingCompany = false,
    this.forbidsPortfolio = false,
    this.requiresLetProperty = false,
    this.requiresVacantProperty = false,
  });

  /// Paket 39: bu olay yalnızca bu hobiyle uğraşmış oyuncuya çıkar.
  ///
  /// Hobi geçmişi **gerçek kayıttan** okunur; uydurulmaz.
  /// Olayın çıkabileceği **en rahat** mali kademe (D-092).
  ///
  /// Yoksulluk anlatan olaylar buna bağlanır: cüzdanında milyonlar olan
  /// oyuncuya "ay sonunu zor getirdin" çıkmaz. `null` ise kısıt yoktur.
  final FinancialComfort? maxComfort;

  /// Olayın çıkabileceği **en dar** mali kademe (D-092).
  ///
  /// Varlık gerektiren olaylar buna bağlanır. `null` ise kısıt yoktur.
  final FinancialComfort? minComfort;

  /// Oyuncunun **hiç konutu olmaması** gerekiyor mu? (D-085)
  ///
  /// Eşin ev istediği olay, zaten evi olan oyuncuya çıkmaz.
  final bool forbidsProperty;

  /// Oyuncunun **hiç aracı olmaması** gerekiyor mu? (D-085)
  final bool forbidsVehicle;

  /// Olay yalnızca bu okul kulübünde **aktif** üyeliği olan oyuncuya
  /// çıkar (Paket AU).
  ///
  /// Hobi koşulunun (`requiredHobbyId`) aynı fikri: geçmiş kayıttan
  /// okunur, uydurulmaz. Kulüp olayları takımda olmayan birine
  /// gelmesin.
  final String? requiresActiveClubId;

  /// Kulüpte en az kaç sezon geçmiş olmalı.
  final int minClubYears;

  /// Kadroda en az bu rol (takım sporları için). `null` ise rol
  /// aranmaz — yedek de olayı görebilir.
  final SquadRole? minSquadRole;

  final String? requiredHobbyId;

  /// prototypeOnly: hobinin kaç yıl sürmüş olması gerektiği.
  final int minHobbyYears;

  /// prototypeOnly: hobide ulaşılmış olması gereken basamak.
  final int minHobbyStage;

  /// Olay yalnızca **yaşayan ve hanede olan** bir evcil hayvanı olan
  /// oyuncuya çıkar (Paket 40). Metindeki `{hayvan}` o hayvanın gerçek
  /// adıyla doldurulur.
  /// Olay yalnızca **gerçekten yatırımı olan** oyuncuya çıksın (D-162).
  ///
  /// Portföyü olmayana "hisseler düştü, ne yapacaksın" sorulmaz.
  final bool requiresPortfolio;

  /// **Şirket durumu kapısı** (Paket AD, §4).
  ///
  /// Doluysa, olay yalnızca sepette bu durumda **en az bir şirket varsa**
  /// sunulur. Sebebi: Paket AC'de bu olayların metni şirketi adıyla
  /// anlatıyordu ama olay şirketin gerçek hâline bakmıyordu — oyuncu
  /// tamamen sağlıklı bir şirket için "konkordato başvurdu" haberi
  /// okuyabiliyordu. §4 bunu istedi: "olaylar state'ten doğsun."
  final CompanyStatus? requiresCompanyStatus;

  /// **En düşük net servet** (₺) — servet seviyesine açılan hayat
  /// (Paket AD, §13, §17).
  ///
  /// Zengin oyuncunun hayatı asgari ücretliyle aynı hissettirmemeli:
  /// belirli servet seviyelerinde farklı fırsatlar, farklı aile talepleri
  /// ve farklı yaşam tarzı olayları çıkar. Net servet **portföy ve mal
  /// dahil, borç düşülmüş** okunur (`NetWorth.of`).
  final int? minNetWorth;

  /// Piyasa gerçekten kriz/panik hâlinde mi olsun (Paket AD, §6)?
  ///
  /// Panik olayını sakin bir yılda göstermek oyuncuya yalan söylemek olur.
  final bool requiresCrisis;

  /// Bu varlığın değerleme ısısı yüksek olsun (Paket AD, §7).
  ///
  /// FOMO olayı **gerçekten** ısınmış piyasada çıksın. Isı oyuncuya
  /// gösterilmiyor; oyuncu yalnızca "herkes bundan bahsediyor" cümlesini
  /// görüyor ve zirveyi önceden bilemiyor.
  final String? requiresHotAsset;

  /// [requiresHotAsset] için gereken en düşük ısı.
  final int requiresHotAssetHeat;

  /// Sepette **zorda** bir şirket olmasını ister (gizli göstergelerden).
  final bool requiresStrainedCompany;

  /// Sepette **iyi giden** bir şirket olmasını ister.
  final bool requiresThrivingCompany;

  /// Olay yalnızca **hiç yatırımı olmayan** oyuncuya çıksın.
  final bool forbidsPortfolio;

  /// Olay yalnızca **kiracısı olan** ev sahibine çıksın (D-163).
  ///
  /// Kiracısı olmayana "kiracın aradı" denmez.
  final bool requiresLetProperty;

  /// Olay yalnızca **boş, kiraya verilmeyi bekleyen** evi olana çıksın.
  final bool requiresVacantProperty;

  final bool requiresLivingPet;

  /// Hayvanın kendi yaşı en az kaç olmalı?
  final int minPetAge;

  /// Oyuncuyla hayvan en az kaç yıldır birlikte olmalı?
  final int minPetYearsTogether;

  /// Hobi **hâlâ sürüyor** sayılmalı mı? (Uzun süredir bırakılmışsa çıkmaz.)
  final bool requiresActiveHobby;

  /// Süren bir adli dosya (soruşturma ya da dava) gerekir mi? (D-128)
  ///
  /// İfade ve bekleyiş olayları bunu kullanır; dosyası olmayana
  /// "mahkemeyi bekliyorsun" denmez.
  final bool requiresOpenCase;

  /// Sabıka kaydı gerekir mi? (D-128)
  ///
  /// Sabıkası olmayan oyuncuya "kayıt var" olayı çıkmaz.
  final bool requiresRecord;

  /// Hapisten **çıkmış** olmak gerekir mi? (D-128)
  ///
  /// Tahliye sonrası olayları içindir; hiç içeri girmemiş oyuncuya
  /// çıkmaz. İçerideyken de çıkmaz.
  final bool requiresReleased;

  final int minAge;
  final int maxAge;

  /// Bu bağlardan **hayatta** en az bir kişi gerekir; olay o kişiyle kurulur.
  /// Boşsa olay kişisizdir.
  final Set<RelationType> livingRelations;

  /// Olayın kişisinin oyuncuyla aynı evde yaşaması gerekir.
  final bool requireSameHousehold;

  /// Geçmişte bırakılmış olması gereken izler (D-008).
  final Set<String> requiredFlags;

  /// Bu izlerden biri varsa olay çıkmaz.
  final Set<String> forbiddenFlags;

  /// Sahip olunması gereken varlıklar; olmayan araç için olay çıkmaz.
  ///
  /// Tam **tür kimliği** arar: yalnızca o eşyaya özgü olaylar içindir.
  final Set<String> requiredPossessions;

  /// Sahip olunması gereken eşya **çeşitleri**.
  ///
  /// "Herhangi bir otomobil" gibi koşullar içindir: tek bir ürün kimliğine
  /// bağlanan olay, oyuncunun başka model araba almasıyla hiç çıkmaz hâle
  /// geliyordu. Listedeki her çeşitten **en az bir** eşya gerekir.
  final Set<ItemKind> requiredPossessionKinds;

  /// Okula devam ediyor olmayı gerektirir (yaş değil, eğitim durumu).
  final bool requiresSchoolStudent;

  /// **Herhangi bir öğrencilik** gerektirir: 1-12. sınıf ya da
  /// üniversite (Paket BZ).
  ///
  /// `requiresSchoolStudent` yalnızca 1-12'ye bakıyor
  /// (`EducationState.isSchoolStudent => enrolled`). 18-20 yaş
  /// olaylarının çoğu için doğru kapı bu değil: o yaşta oyuncu
  /// genellikle **üniversitede** ya da çalışıyor. Kampüs/üniversite
  /// metni taşıyan dört olay bu yüzden hiç çıkmıyordu — koşul içerikle
  /// çelişiyordu.
  final bool requiresStudent;

  /// Sınıf aralığı (1-12). Verilirse oyuncunun o sınıfta olması gerekir.
  final int? minGrade;
  final int? maxGrade;

  /// Uzun süre oyun içinde temas kurulmamış bir yakın gerektirir (D-025).
  final bool requiresNeglectedRelative;

  /// Olayın **kişisinin** yaş aralığı (oyuncunun değil).
  ///
  /// Çocukla ilgili olaylar bununla doğru yaşa bağlanır: bebeklik olayı
  /// 15 yaşındaki çocukta çıkmaz.
  final int? personMinAge;
  final int? personMaxAge;

  /// Olayın kişisinin oyuncuyla **ayrı evde** yaşaması gerekir.
  ///
  /// Ziyaret olayları bunu kullanır: aynı evde yaşanan kişiye "ziyarete
  /// geldi" denmez.
  final bool requireOutsideHousehold;

  /// Olayın kişisi, gündelik hayatta **gerçekten erişilebilir** olmalı.
  ///
  /// Yıllar önce tanışılmış, başka şehirde kalmış biri "her gün görüşülen
  /// kişi" gibi kullanılmaz (D-025, Paket 3). Bayram/ziyaret gibi uzak
  /// yakınları anlatan olaylar bunu **kullanmaz**.
  final bool requireReachable;

  /// En az bir sosyal medya hesabı gerektirir.
  ///
  /// Hesabı olmayan oyuncuya sosyal medya üzerinden mesaj gelmez.
  final bool requiresSocialAccount;

  /// Süren bir **arkadaş grubu** gerektirir (Paket CI).
  ///
  /// Grup kaydı olmayan oyuncuya "grup" diye bir şey anlatılmaz; grup
  /// dağılınca da anlatılmaz, çünkü koşul hikâye izi değil **yürürlükte
  /// olan kayıt**. İz kullanılsaydı grup dağıldıktan sonra da olaylar
  /// gelirdi (izler silinmez).
  final bool requiresFriendCircle;

  /// Yaşlılıkta **aileden destek görülen** en az yıl sayısı (Paket CM).
  ///
  /// Koşul hikâye izi değil **yürürlükteki sayaç**
  /// (`GameState.elderSupport.yearsSupported`): "üç yıldır yanımda"
  /// diyen bir olay, o üç yıl gerçekten yaşanmadan çıkmaz. İz
  /// kullanılsaydı bir kez destek görmek ömür boyu yeterdi.
  final int minElderSupportYears;

  /// Yaşlılıkta **kimseye yüklenmeden** çevrilen en az yıl sayısı.
  final int minElderAloneYears;

  /// Sahip olunması gereken ehliyetler.
  ///
  /// Aracı olan ama ehliyeti olmayan oyuncuya "direksiyona geçtin" denmez.
  final Set<String> requiredLicenses;

  /// Oyuncunun **emekli olmuş** olmasını gerektirir (Paket 12).
  final bool requiresRetired;

  /// Yıllar önce **birlikte** yapılmış, kişisi hâlâ hayatta olan bir gezi
  /// gerektirir (Paket 11).
  ///
  /// Olayın kişisi o gezinin yoldaşıdır; metindeki `{sehir}` gidilen
  /// şehirle doldurulur. Böyle bir gezi yoksa olay çıkmaz.
  final bool requiresTripMemory;

  /// Gerekli en az Ün değeri.
  ///
  /// Ün açılmamışsa (hiç kitle yoksa) bu olaylar çıkmaz (D-027).
  final int minFame;

  /// Oyuncunun **şu an bir işte çalışıyor** olmasını gerektirir.
  ///
  /// İşsiz oyuncuya iş yerinde geçen olay çıkmaz (Paket 9).
  final bool requiresEmployed;

  /// Oyuncunun **kirada** yaşıyor olmasını gerektirir.
  ///
  /// Ev sahibi, kira zammı ve depozito gibi olaylar içindir. Kendi
  /// evinde oturan ya da ailesinin yanında yaşayan oyuncuya "ev sahibi
  /// aradı" denmez.
  final bool requiresTenant;

  /// Oyuncunun **kendi evinde oturuyor** olmasını gerektirir (Paket BP).
  ///
  /// Mülk sahibi olmak yetmez: evi olup ailesinin yanında yaşayan ya da
  /// evini kiraya verip kirada oturan oyuncuya "evinin kombisi patladı"
  /// denmez. Ölçülen boşluk buydu: katalogda kiracı kapısı 11, kiraya
  /// veren kapısı 14, boş ev kapısı 8 olayda vardı; **oturulan evin
  /// kapısı hiç yoktu**. Kendi evinde oturan 40 yaşındaki oyuncunun
  /// konut havuzundan aday olayı sıfırdı, kiracının sekiz.
  final bool requiresOwnedResidence;

  /// Şu anki işte geçmiş olması gereken en az yıl.
  ///
  /// İşe girdiği gün "yıllardır buradasın" denmesin diye kullanılır.
  final int requiresMinYearsInJob;

  /// Olayın kişisi, daha önce bir hikâye rolüne kilitlenmiş kişidir.
  ///
  /// Devam olayları bunu kullanır: yıllar önce savunduğun arkadaş, yıllar
  /// sonra **aynı kişi** olarak karşına çıkar. Kişi artık yoksa olay çıkmaz.
  final String? personRole;
}

/// Bir olay seçiminin portföye **gerçek** etkisi (Paket AD, §AD/3).
///
/// **Neden var.** Paket AC'de panik ve balon olayları vardı ama
/// seçeneklerinin tek etkisi mutluluktu: "sat", "bekle", "al" seçmek
/// portföyde hiçbir şey değiştirmiyordu. Yani karar değil, süslü metindi.
/// §6 ve §7 bunu istedi — oyuncu panikte ve balonda gerçekten karar
/// verebilsin.
///
/// **İkinci bir ekonomi motoru kurulmuyor:** hamle `InvestmentEngine`'in
/// kendi al/sat yollarından geçiyor, yani komisyon, kazanç kesintisi,
/// işlem durması ve maliyet esası aynen işliyor. Aynı kalıp suç
/// seçimlerinde de var (`crimeId` -> `LegalEngine`).
enum PortfolioAction {
  /// Pozisyonun bir kısmını sat. Zararı gerçekleştirir; daha fazla
  /// düşmekten korur ama toparlanmayı da kaçırır.
  satKismi,

  /// Cüzdandaki nakdin bir kısmıyla al. Dip olabilir, olmayabilir.
  alKismi,

  /// **Kâr al:** yalnızca pozisyon kârdaysa bir kısmını sat.
  karAl,
}

/// Bir olay seçeneği ve sonuçları.
@immutable
class EventChoice {
  const EventChoice({
    required this.id,
    required this.label,
    required this.resultText,
    this.happiness = 0,
    this.health = 0,
    this.intelligence = 0,
    this.charisma = 0,
    this.appearance = 0,
    this.bond = 0,
    this.money = 0,
    this.addFlags = const <String>{},
    this.removeFlags = const <String>{},
    this.addPossessions = const <String>{},
    this.startsRomance = false,
    this.endsRomance = false,
    this.startsSchoolFriendship = false,
    this.startsFriendship = false,
    this.rememberPersonAs,
    this.crimeId,
    this.portfolioAction,
    this.portfolioTypeId = 'hisse',
    this.portfolioShare = 0.25,
  });

  final String id;
  final String label;

  /// Seçimden sonra gösterilen ve hayat günlüğüne yazılan özgün metin.
  final String resultText;

  /// Bu seçim hukuki bir sürecin önünü açıyorsa o olayın kimliği
  /// ([CrimeType.id], D-128).
  ///
  /// Seçim yapılınca motor dosyayı açar: idari ceza kesilir ya da
  /// soruşturma başlar. **Sonucu seçim değil, süreç belirler**; oyuncuya
  /// "şunu seçersen yakalanmazsın" diyen hiçbir bilgi verilmez.
  final String? crimeId;

  /// Bu seçim portföyde gerçekten bir şey yapıyorsa hamlesi.
  final PortfolioAction? portfolioAction;

  /// Hamlenin uygulanacağı yatırım türü.
  final String portfolioTypeId;

  /// Hamlenin büyüklüğü: pozisyonun (ya da nakdin) payı.
  final double portfolioShare;

  final int happiness;
  final int health;
  final int intelligence;
  final int charisma;
  final int appearance;

  /// Olayın kişisiyle ilişki değişimi.
  final int bond;

  /// Oyuncunun **kendi** cüzdanındaki değişim (ECO-001). Aile parasıyla
  /// karışmaz. Miktarlar prototypeOnly'dir.
  final int money;

  /// Geleceğe bırakılan iz (D-008, D-022).
  final Set<String> addFlags;

  /// Artık geçerli olmayan izler (örneğin ilişki bittiğinde).
  final Set<String> removeFlags;
  final Set<String> addPossessions;

  /// Bu seçim yeni bir romantik ilişki başlatır: kişi oluşturulur ve
  /// **sevgili** statüsüyle Aile'de listelenir (D-029, D-030).
  final bool startsRomance;

  /// Bu seçim mevcut ilişkiyi bitirir. Kişi **silinmez**; aynı kimlikle
  /// eski sevgili statüsüne geçer.
  final bool endsRomance;

  /// Bu seçim okuldaki tanışıklığı **yakın arkadaşlığa** çevirir.
  ///
  /// Olayın kişisi varsa o kişi (aynı kimlikle) arkadaş olur; yoksa kalıcı
  /// kimlikli yeni bir arkadaş kaydı oluşturulur. Her sınıf arkadaşı
  /// kendiliğinden yakın arkadaş sayılmaz.
  final bool startsSchoolFriendship;

  /// Bu seçim, okul dışında **yeni bir arkadaş** kaydı açar.
  ///
  /// Kişi yalnızca tanışma gerçekten olduğunda üretilir; reddedilen ya da
  /// gerçekleşmeyen tanışma için kayıt açılmaz. Yeni tanışıklık romantik
  /// ilişki değildir.
  final bool startsFriendship;

  /// Bu seçim, olayın kişisini bir hikâye rolüne kilitler.
  ///
  /// Sonraki olaylar [EventRequirement.personRole] ile aynı kişiyi bulur.
  final String? rememberPersonAs;

  /// Yalnızca etiketi değişmiş bir kopya.
  ///
  /// Seçenek metnindeki `{kisi}` gibi yer tutucular ekrana gelmeden
  /// doldurulsun diye vardır; sonuçlar aynen korunur.
  EventChoice withLabel(String newLabel) => EventChoice(
        id: id,
        label: newLabel,
        resultText: resultText,
        happiness: happiness,
        health: health,
        intelligence: intelligence,
        charisma: charisma,
        appearance: appearance,
        bond: bond,
        money: money,
        addFlags: addFlags,
        removeFlags: removeFlags,
        addPossessions: addPossessions,
        startsRomance: startsRomance,
        endsRomance: endsRomance,
        startsSchoolFriendship: startsSchoolFriendship,
        rememberPersonAs: rememberPersonAs,
      );
}

/// Olay tanımı. Havuz modülerdir; yeni olay eklemek listeye kayıt eklemektir.
@immutable
class GameEvent {
  const GameEvent({
    required this.id,
    required this.category,
    required this.text,
    required this.choices,
    this.requirement = const EventRequirement(),
    this.repeatable = false,
    this.minAgeGap = prototypeOnlyDefaultRepeatGap,
    this.weight = 1,
    this.insuredRisk,
    this.priority = 0,
  }) : assert(minAgeGap >= 1, 'Tekrar aralığı en az bir yaş olmalıdır.');

  /// prototypeOnly: tekrar aralığı belirtilmeyen tekrarlanabilir olaylar için
  /// varsayılan yaş farkı. Kesin tekrar dengesi henüz kararlaştırılmadı.
  static const int prototypeOnlyDefaultRepeatGap = 3;

  final String id;
  final EventCategory category;

  /// `{kisi}` kişinin adıyla, `{bag}` bağ etiketiyle değiştirilir.
  final String text;
  final List<EventChoice> choices;
  final EventRequirement requirement;

  /// Aynı hayatta birden çok kez çıkabilir mi?
  final bool repeatable;

  /// Tekrarlanabilir bir olayın yeniden çıkabilmesi için geçmesi gereken
  /// **oyun içi** yaş farkı.
  ///
  /// Doğal olarak tekrar eden olaylar (bayram sabahı gibi) tamamen
  /// yasaklanmaz; farklı yaşlarda, uygun koşullarda yeniden gelebilir.
  /// Buradaki sayılar prototypeOnly'dir.
  final int minAgeGap;

  /// Aynı anda uygun olan olaylar arasında görece ağırlık (prototypeOnly).
  final int weight;

  /// Bu olayın zararı **sigortalanabilir** bir riske mi ait? (Paket CA)
  ///
  /// Doluysa ve oyuncunun o türde yürürlükte poliçesi varsa, seçimin
  /// **eksi para** etkisi muafiyet + karşılanmayan paya iner. Boşsa
  /// hiçbir şey değişmez; yani etiketlenmemiş olay Paket CA öncesi gibi
  /// davranır.
  final InsuranceKind? insuredRisk;

  /// Dönüm noktası önceliği (Paket 21).
  ///
  /// Tek bir yıla bağlı olaylar — sınav yılı, okulun ilk günü, işe ilk
  /// gün — bütün havuzla yarıştıkları için çoğu hayatta hiç çıkmıyordu:
  /// ölçümde sınav yılı olayları oyuncuların ancak **%38'inde**
  /// görülüyordu. Önceliği sıfırdan büyük bir olay uygun olduğunda, o yıl
  /// **yalnızca en yüksek öncelikli olaylar** yarışır; sıradan olaylar
  /// o yılı beklemek zorunda kalır.
  ///
  /// Öncelik, olayın çıkacağını **garanti etmez**: koşulları tutmuyorsa
  /// yine elenir ve aynı öncelikte birden çok olay varsa aralarında
  /// ağırlıkla seçim yapılır.
  final int priority;
}

/// Oyuncunun karşısına çıkmış, kişisi ve metni çözülmüş olay.
@immutable
class ActiveEvent {
  const ActiveEvent({
    required this.eventId,
    required this.category,
    required this.text,
    required this.choices,
    this.personId,
    this.isContinuation = false,
  });

  final String eventId;
  final EventCategory category;

  /// Bu olay geçmiş bir seçimin devamı mı?
  ///
  /// Faho'nun Q-114 kararı: oyuncuya büyük bir "QUEST" etiketi
  /// konmayacak ama devam olayında küçük, doğal bir işaret olabilir.
  /// Ekranda "Geçmişten" rozeti olarak görünür.
  final bool isContinuation;

  /// Yer tutucuları doldurulmuş, ekranda gösterilecek metin.
  final String text;
  final List<EventChoice> choices;

  /// Olay bir kişiyle kurulduysa o kişinin kalıcı kimliği.
  final String? personId;
}

/// Bir seçimin uygulanmış hâli; arayüzde sonucu göstermek için.
@immutable
class EventResolution {
  const EventResolution({
    required this.eventId,
    required this.choiceId,
    required this.resultText,
  });

  final String eventId;
  final String choiceId;
  final String resultText;
}
