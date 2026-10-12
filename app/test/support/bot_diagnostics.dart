/// PlayerBot ölçümünün **teşhis** katmanı.
///
/// **Neden var.** Son ürün simülasyonu birkaç aşırı sayı üretti: ölüm anı
/// medyan net serveti ~134M ₺, partneri olan %94,9 iken evlenen %22,
/// tekrar evlenen %0, hiç girilmeyen meslekler, hiç kurulmayan işletme
/// türleri ve hiç görülmeyen olaylar. Bu sayıları dengeyi değiştirerek
/// "düzeltmek" yanlış olurdu: önce **nereden geldiklerini** ölçmek
/// gerekiyor.
///
/// Bu dosya iki şey getirir:
///
/// * [BotDiag] — bir hayatın içinde biriken teşhis kayıtları. Servet
///   bileşenleri, para akışları, evlilik hunisinin her basamağı, ayrılık
///   sonrası huni, meslek/işletme uygunluğu ve botun kendi eylem
///   sıklıkları. Hiçbiri oyunun akışına dokunmaz; yalnızca **okur**.
/// * [BotOverrides] — teşhis için **bot politikasını** kısıtlar
///   (yatırım yapmayan bot, ev almayan bot…). Oyunun sayıları, şartları
///   ve motorları **değişmez**; yalnızca botun tercihleri kapanır.
///
/// **Kurallar:**
/// * Teşhis hiçbir yerde `rng` tüketmez. Tükettiği anda oyunun rastgele
///   akışı kayardı ve ölçüm eski ölçümle karşılaştırılamaz hale gelirdi.
///   Uygunluk taramaları (`debugEligibleIds`) **kendi ayrı zarıyla**
///   çalışır.
/// * [BotOverrides] bir politikayı kapatırken bile niyet zarını **atar**
///   (bkz. `_Intent`): aynı tohum, senaryolar arasında aynı rastgele
///   akışla başlar.
/// * `debugSetState` ile para/stat/ilişki/ev/iş **verilmez**. Teşhis
///   turunda da bot üretim kurallarını atlamaz.
///
/// Bu dosya **yalnızca test altyapısıdır**; ürün kodu değildir.
library;

/// Teşhis için bot politikası kısıtı.
///
/// D bölümü (karşılaştırmalı servet testi) bunu kullanır: aynı tohumla
/// "yatırım yapmayan bot" ve "ev almayan bot" koşup serveti hangi
/// sistemin büyüttüğünü görüyoruz. **Oyunun sayıları değişmez.**
class BotOverrides {
  const BotOverrides({
    this.noInvesting = false,
    this.noProperty = false,
    this.noBusiness = false,
    this.noElderSupport = false,
  });

  /// Bot hiç yatırım yapmaz (portföy kurmaz).
  final bool noInvesting;

  /// Bot ev/gayrimenkul almaya çalışmaz (oturmak için de, kiralık da).
  final bool noProperty;

  /// Bot işletme kurmaya çalışmaz.
  final bool noBusiness;

  /// Bot yaşlılıkta bakım kararını **vermez** (Paket CJ).
  ///
  /// Ölçüm için gerekli: bot kararı yılın başında verdiği için
  /// `onPreAge` ile taranan her kare "bu yılın kararı verilmiş" oluyor
  /// ve kapıların kendi gerekçeleri ölçülemiyordu. Bu kapalıyken
  /// tarama karar **öncesi** kareyi bulur. Oyunun sayıları değişmez.
  final bool noElderSupport;

  static const BotOverrides none = BotOverrides();

  String get label {
    final List<String> kapali = <String>[
      if (noInvesting) 'yatirimsiz',
      if (noProperty) 'gayrimenkulsuz',
      if (noBusiness) 'isletmesiz',
      if (noElderSupport) 'bakimsiz',
    ];
    return kapali.isEmpty ? 'normal' : kapali.join('+');
  }
}

/// Servet eğrisinin ölçüldüğü yaşlar (B bölümü).
const List<int> kWealthCurveAges = <int>[
  20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80,
];

/// Bir hayatın teşhis kayıtları.
///
/// Alanların hepsi **ölçüm**; hiçbiri karar değil.
class BotDiag {
  // ------------------------------------------------------------------
  // A — ölüm anı servet bileşenleri
  //
  // Double-count yapmamak için kural açık:
  //
  //   netWorth = wallet + portfolio + realEstate + otherAssets - debt
  //
  // `businessInvested` ve `businessProfit` bu toplamın **içinde
  // değildir**: oyunun net servet hesabı (`NetWorth.of`) işletmeyi
  // varlık saymıyor. Ayrı raporlanır ki "işletme serveti ne kadar
  // büyütüyor" sorusu kârın cüzdana geçmesi üzerinden yanıtlanabilsin.
  // ------------------------------------------------------------------

  /// Ölüm anı cüzdan (₺).
  int wallet = 0;

  /// Ölüm anı portföy değeri (hisse/fon/altın/döviz + vadeli anapara).
  int portfolio = 0;

  /// Ölüm anı konut/gayrimenkul değeri.
  int realEstate = 0;

  /// Ölüm anı araç değeri.
  int vehicles = 0;

  /// Kalan diğer satılabilir eşya değeri.
  int otherAssets = 0;

  /// Kalan kredi borcu.
  int debt = 0;

  /// Oyunun kendi hesabı (`NetWorth.of`). Bileşenlerin toplamıyla
  /// **tutmak zorunda**; tutmuyorsa teşhisin kendisi hatalıdır ve test
  /// bunu iddia eder.
  int netWorth = 0;

  /// İşletmeye konan sermaye ve işletmenin toplam kârı. Net servetin
  /// **dışında**; ayrı raporlanır.
  int businessInvested = 0;
  int businessProfit = 0;

  // ------------------------------------------------------------------
  // A — ömür boyu akışlar
  // ------------------------------------------------------------------

  /// Çalışılan yıllardaki yıllık maaşların toplamı (**yaklaşık** brüt
  /// kariyer geliri; vergi/kesinti modeli değil).
  int lifetimeSalary = 0;

  /// Kiraya verilen evlerden toplanan toplam kira (defterden okunur).
  int lifetimeRent = 0;

  /// Gayrimenkule yapılan bakım/onarım harcaması.
  int lifetimeMaintenance = 0;

  /// Tahakkuk eden toplam yaşam gideri (ödenebilmiş olsun ya da olmasın).
  int lifetimeLivingCostAccrued = 0;

  /// Gerçekten cüzdandan çıkan yaşam gideri.
  int lifetimeLivingCostPaid = 0;

  /// Mirastan gelen toplam nakit ve kaç kez miras geldiği.
  int inheritanceMoney = 0;
  int inheritanceCount = 0;

  /// Mirasla gelen eşya adedi.
  int inheritanceItems = 0;

  /// Portföye hayat boyu konan toplam anapara (bot her alımda toplar).
  int investedPrincipalEver = 0;

  /// Ölüm anında **elde duran** pozisyonların maliyet bedeli.
  int portfolioInvestedAtDeath = 0;

  /// Ölüm anında gerçekleşmemiş kâr/zarar.
  int portfolioUnrealizedAtDeath = 0;

  /// Hayat boyu gerçekleşen kâr/zarar (bot satmıyor; boşanmada nakde
  /// çevrilen pozisyonlardan gelebilir).
  int portfolioRealizedAtDeath = 0;

  /// Geçim sıkıntısı çekilen yıl sayısı (cüzdan gideri karşılamadı).
  int hardshipYears = 0;

  /// **Q-165/5'in ölçüsü.** Cüzdan yıllık gideri karşılamazken portföyün
  /// dolu olduğu yıl sayısı: o yıllarda portföy giderden korunuyor ve
  /// bileşik büyümeye devam ediyor.
  int protectedYears = 0;

  /// Korunan yıllarda portföyün toplam büyüklüğü (ortalama alınabilsin
  /// diye biriktirilir).
  int protectedYearsPortfolioSum = 0;

  // ------------------------------------------------------------------
  // B — yaşa göre servet eğrisi
  // ------------------------------------------------------------------

  /// Yaş → o yaştaki net servet. Yalnızca [kWealthCurveAges] için.
  final Map<int, int> netWorthAtAge = <int, int>{};

  /// Yaş → o yaştaki portföy değeri.
  final Map<int, int> portfolioAtAge = <int, int>{};

  // ------------------------------------------------------------------
  // G/H — evlilik hunisi
  // ------------------------------------------------------------------

  /// Bot bu hayatta evlenmek **istedi** mi? (Bekar kalmak geçerli bir
  /// hayat; isteyenle istemeyeni ayırmadan huni yanıltıcı olur.)
  bool wantedMarriage = false;

  /// Romantik ilişkiye uygun yaşa (18) geldi mi?
  bool reachedRomanceAge = false;

  /// Partner adayı gördü mü? (Finger destesi ya da listede flört/sevgili.)
  bool sawCandidate = false;

  /// Flört aşamasına geldi mi?
  bool flirted = false;

  /// Sevgilisi oldu mu?
  bool hadPartner = false;

  /// Bir sevgilide yakınlık 30'u / 45'i (teklif eşiği) gördü mü?
  bool bond30 = false;
  bool bond45 = false;

  /// Teklif **edilebilir** hale geldi mi? (`proposalAvailability` açık.)
  bool proposalEligible = false;

  /// Teklif etti mi, kabul edildi mi?
  bool proposed = false;
  bool proposalAccepted = false;

  /// Bekleyen düğün oluştu mu, düğün yapıldı mı?
  bool pendingWeddingSeen = false;
  bool weddingHeld = false;

  /// Teklif denemesinin sayısı ve en yüksek görülen sevgili yakınlığı.
  int proposalAttempts = 0;
  int bestPartnerBond = 0;

  /// Bot teklif etmek istediği halde engellendiğinde oyunun verdiği
  /// gerekçe. Aynı hayatta aynı gerekçe birden çok kez sayılabilir;
  /// rapor en sık gerekçeleri çıkarır.
  final List<String> marriageBlockers = <String>[];

  // ------------------------------------------------------------------
  // J/K — ayrılık ve tekrar evlenme hunisi
  // ------------------------------------------------------------------

  /// Ayrılık yaşı ve türü ('bosanma' | 'dulluk'). Hiç ayrılmadıysa null.
  int? separationAge;
  String separationKind = '';

  /// Eski eşin **kaydı korundu mu**: kişi listesinde aynı kimlikle
  /// duruyor mu? (Paket 36: geçmiş kaybolmasın.)
  bool exSpouseRecordKept = false;

  /// **Boşanmada** eski eşin bağı `es` olmaktan çıktı mı? Dullukta bu
  /// ölçü anlamsızdır (eş vefat eder, bağı `es` kalabilir), o yüzden
  /// yalnızca boşanmada doldurulur.
  bool exSpouseRelationUpdated = false;

  /// Ayrılıktan sonra oyun yeniden "bekar" kabul ediyor mu?
  /// (`marryBlockReason` artık "Zaten evlisin." demiyor.)
  bool treatedAsSingleAfter = false;

  /// Ayrılıktan sonraki huni basamakları.
  bool postSepCandidate = false;
  bool postSepFlirt = false;
  bool postSepPartner = false;
  bool postSepBond45 = false;
  bool postSepEligible = false;
  bool postSepProposed = false;
  bool postSepAccepted = false;
  bool postSepMarried = false;

  /// Ayrılıktan sonra kaç yıl yaşadı? (Huninin yürüyecek zamanı var mıydı?)
  int yearsAfterSeparation = 0;

  /// Yeniden evlenme yaşı.
  int? remarriageAge;

  /// Ayrılık sonrası teklif engelleri.
  final List<String> postSepBlockers = <String>[];

  // ------------------------------------------------------------------
  // M — meslek erişimi
  // ------------------------------------------------------------------

  /// Meslek → botun **işsizken** o işi açık ilanda kaç yıl gördüğü
  /// (şartları sağlanmış demektir: `openJobs` yalnızca açıkları verir).
  final Map<String, int> jobOpenYears = <String, int>{};

  /// Meslek → botun kaç kez başvurduğu.
  final Map<String, int> jobApplied = <String, int>{};

  /// Meslek → başvurunun sonuç vermediği kez sayısı.
  final Map<String, int> jobFailed = <String, int>{};

  /// Meslek → kapalıyken oyunun verdiği gerekçe (son görülen).
  final Map<String, String> jobLockReason = <String, String>{};

  // ------------------------------------------------------------------
  // N — işletme erişimi
  // ------------------------------------------------------------------

  /// İşletme türü → şartların açık olduğu yıl sayısı.
  final Map<String, int> bizAllowedYears = <String, int>{};

  /// İşletme türü → şartlar açıkken **sermayenin de yettiği** yıl sayısı.
  final Map<String, int> bizAffordableYears = <String, int>{};

  /// İşletme türü → kurma denemesi.
  final Map<String, int> bizAttempted = <String, int>{};

  /// İşletme türü → kapalıyken oyunun verdiği gerekçe (son görülen).
  final Map<String, String> bizLockReason = <String, String>{};

  // ------------------------------------------------------------------
  // O — olay erişimi
  // ------------------------------------------------------------------

  /// Hayat boyunca **bir kez bile uygun hale gelen** olaylar. Görülenle
  /// arasındaki fark "havuz rekabetinde kaybetti" demektir.
  final Set<String> eligibleEvents = <String>{};

  // ------------------------------------------------------------------
  // P/Q — botun kendi davranış sıklığı
  // ------------------------------------------------------------------

  /// 18 yaşından sonra yaşanan yıl sayısı (sıklıkların paydası).
  int adultYears = 0;

  /// Bot eylem sayaçları.
  int activityActions = 0;
  int investBuys = 0;
  int jobApplications = 0;
  int interactions = 0;

  /// Ehliyet başvurusu denemesi ve kazanılan ehliyet (Paket AD, §18).
  int licenseAttempts = 0;
  int licensesEarned = 0;
  int eventsAnswered = 0;
  int checkupActions = 0;
  int sportActions = 0;

  /// Yatırım yapabilecek durumdayken (18+, serbest para ≥ asgari alım)
  /// geçen yıl sayısı: "bot her yıl mı yatırıyor" sorusunun paydası.
  int investOpportunityYears = 0;

  // ------------------------------------------------------------------
  // AH — tam yaşam denetimi
  // ------------------------------------------------------------------
  //
  // Paket AE işletmeye fiyat/reklam/bakım/personel getirdi, ama
  // `PlayerBot` o gün güncellenmedi: yalnızca `tendBusiness`,
  // `investInBusiness` ve `closeBusiness` çağırıyordu. AH'nin §2'si
  // botun bu sistemleri **gerçekten** kullanmasını istiyor; aşağıdaki
  // sayaçlar kullandığını kanıtlıyor. Hiçbiri oyunun sayısını
  // değiştirmez, yalnızca okur.

  /// İşletmenin açık geçirdiği yıl (bütün işletmeler toplamı).
  int bizYears = 0;

  /// O yılın neti eksi olan işletme yılı.
  int bizLossYears = 0;

  /// Kurulan ve kapanan işletme sayısı.
  int bizOpened = 0;
  int bizClosed = 0;

  /// Bot eylem sayaçları: fiyat, reklam, bakım, personel.
  int bizPriceChanges = 0;
  int bizAdSet = 0;
  int bizAdYears = 0;
  int bizMaintain = 0;
  int bizStaff = 0;
  int bizTend = 0;

  /// Reklamın tuttuğu (viral) yıl: motorun bıraktığı bildirimden okunur.
  int bizViralYears = 0;

  /// Hayat boyunca işletmeye konan sermaye ve işletmeden çıkan kâr.
  int bizCapital = 0;
  int bizProfit = 0;

  /// En iyi tek işletme yılı (₺ net).
  int bizBestYear = 0;

  // --- Yatırım ------------------------------------------------------

  /// Botun **kendi isteğiyle** sattığı kez.
  int investSells = 0;

  /// Tek yılda tek varlıkta görülen düşüşler (§5).
  int drop20 = 0;
  int drop30 = 0;
  int drop40 = 0;

  /// Portföyün zirveden en kötü düşüşü (0-1).
  double worstDrawdown = 0;

  /// Yıl boyunca görülen piyasa olayları.
  bool sawScandal = false;
  bool sawCompanyFailure = false;
  final Set<String> marketIncidentKinds = <String>{};

  /// Zorunlu satış yılı: oyunun bozdurduğu, botun istemediği satış.
  /// (Toplam satış kaydı − botun kendi satışı.)
  int forcedSales = 0;

  /// Portföyü anaparasının altında biten hayat mı?
  bool investEndedInLoss = false;

  // --- Kariyer ------------------------------------------------------

  /// 18+ yaşta işi olan / olmayan yıl.
  int employedYears = 0;
  int unemployedAdultYears = 0;

  // --- Sağlık -------------------------------------------------------

  /// Sağlık krizi sayısı ve kronik tanı sayısı.
  int healthCrises = 0;
  int chronicCount = 0;

  /// Kontrol (check-up) ve tahlil eylemi sayısı.
  int healthActions = 0;

  // --- Suç / hukuk --------------------------------------------------

  int investigations = 0;
  int trials = 0;
  int convictions = 0;
  int prisonYears = 0;
  int probationYears = 0;

  /// Birden fazla dosyası olan hayat: yeniden suç.
  int caseCount = 0;

  // --- Yakın arkadaşlık hunisi (AH, §7/§10) -------------------------
  //
  // Tanışıklık (sınıf/iş arkadaşı) → yakınlık 55 → teklif → kabul.
  // Hangi basamakta tıkandığını görmek için her basamak ayrı sayılıyor.
  bool sawAcquaintance = false;
  int bestAcquaintanceBond = 0;
  int closeFriendEligibleYears = 0;
  int closeFriendAttempts = 0;
  int closeFriendAccepted = 0;
  String closeFriendBlockReason = '';

  // --- İç kullanım: yıl başı değerleri ------------------------------
  //
  // Rapor alanı değil; yıl sınırındaki karşılaştırmayı kurmak için
  // tutuluyor. Bot **yıl içinde alım/satım yapmıyor** (eylemler yaş
  // almadan önce biter), dolayısıyla iki okuma arasındaki fark saf
  // piyasa hareketidir.
  final Map<String, int> prevHoldingValue = <String, int>{};
  int peakPortfolio = 0;

  /// İşletme kimliği → sayılan son yıl (aynı yıl iki kez sayılmasın).
  final Map<String, int> lastCountedBizYearOf = <String, int>{};

  // ------------------------------------------------------------------
  // Türetilmiş ölçüler
  // ------------------------------------------------------------------

  /// Bileşenlerin toplamı. `netWorth` ile tutmak zorunda.
  int get componentSum =>
      wallet + portfolio + realEstate + vehicles + otherAssets - debt;

  /// Servetin portföyden gelen oranı (0-1). Servet ≤ 0 ise 0.
  double get portfolioShare =>
      netWorth <= 0 ? 0 : (portfolio / netWorth).clamp(0.0, 1.0);

  /// Servetin gayrimenkulden gelen oranı (0-1).
  double get realEstateShare =>
      netWorth <= 0 ? 0 : (realEstate / netWorth).clamp(0.0, 1.0);

  /// Mirasın servetteki oranı (0-1).
  double get inheritanceShare =>
      netWorth <= 0 ? 0 : (inheritanceMoney / netWorth).clamp(0.0, 1.0);

  /// Portföyün anaparaya oranı: 1,0 hiç büyümedi, 10,0 on katına çıktı.
  double get portfolioMultiple => portfolioInvestedAtDeath <= 0
      ? 0
      : portfolio / portfolioInvestedAtDeath;
}
