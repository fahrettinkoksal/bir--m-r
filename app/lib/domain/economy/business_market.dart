/// İşletmenin **kendi piyasası** (Paket AE, §3, §4, §5).
///
/// **Neden var.** AE öncesinde işletmenin tek sayısı vardı: `condition`.
/// Kâr ondan çıkıyordu, oyuncunun tek hamlesi "işine bak" idi ve ölçümde
/// `girisim + yatirim` dokuz stratejiyi birden eziyordu (Q-174/1). Çözüm
/// işletme kârını yapay olarak kesmek değil; işletmeyi **yönetilen bir
/// sistem** hâline getirmek.
///
/// Bu dosya talebin doğduğu yeri kurar:
///
/// * **Bölge ortalaması** (§3). Oyuncuya "Bölgendeki ortalama: 1.250 ₺"
///   yazar. Gerçek dünyadan gelmez, gerçek yıla bağlı değildir (§25):
///   şehirden, işletme türünden, oyunun ekonomi rejiminden ve kurgusal
///   rekabetten türetilir.
/// * **Talep** (§5). Fiyat/ortalama oranı, itibar, kalite, reklam, şehir,
///   rekabet, personel ve bakım birlikte müşteri yoğunluğunu verir. Tek
///   bir sayıdan kâr çıkmaz.
///
/// **Exploit kuralı (§4, §34).** Fiyat yükseldikçe birim kâr artar ama
/// müşteri azalır; düştükçe müşteri artar ama birim kâr düşer ve yoğunluk
/// personeli ve ekipmanı yorar. Her işin kendi [BusinessType.priceElasticity]
/// değeri olduğu için tek bir "doğru fiyat" yoktur.
///
/// Bütün sayılar `prototypeOnly`'dir (Q-175).
library;

import 'dart:math';

import '../../data/business_catalog.dart';
import '../../data/city_catalog.dart';
import '../models/business.dart';
import '../models/game_state.dart';
import '../models/market_state.dart';

/// Bir yılın talep tablosu: yoğunluk ve onu doğuran parçalar.
class BusinessDemand {
  const BusinessDemand({
    required this.marketPrice,
    required this.price,
    required this.index,
    required this.priceEffect,
    required this.reputationEffect,
    required this.adEffect,
    required this.serviceEffect,
    required this.competition,
  });

  /// Bölgedeki ortalama fiyat (₺).
  final int marketPrice;

  /// İşletmenin uyguladığı fiyat (₺).
  final int price;

  /// Müşteri yoğunluğu endeksi; 100 = taban koşullar.
  final int index;

  final double priceEffect;
  final double reputationEffect;
  final double adEffect;
  final double serviceEffect;

  /// Bölgedeki rekabet baskısı (1,0 = normal; büyüdükçe zor).
  final double competition;

  /// Ekrandaki okunur hâli.
  String get label {
    if (index >= 145) return 'Yerinde duracak hâlin yok';
    if (index >= 115) return 'Yoğun';
    if (index >= 88) return 'Normal';
    if (index >= 62) return 'Durgun';
    if (index >= 35) return 'Müşteri az';
    return 'Neredeyse kimse gelmiyor';
  }
}

abstract final class BusinessMarket {
  // -------------------------------------------------------------------
  // Kalibrasyon — hepsi prototypeOnly (Q-175)
  // -------------------------------------------------------------------

  /// prototypeOnly: şehir farkının fiyata yansıma payı.
  ///
  /// Konut çarpanı doğrudan kullanılmadı: İstanbul'un kirası Amasya'nın
  /// 2,2 katı olabilir ama bir tost 2,2 katı değildir. Fark yumuşatıldı.
  static const double prototypeOnlyCityPass = 0.42;

  /// prototypeOnly: rekabet endeksinin genişliği.
  static const double prototypeOnlyCompetitionSpread = 0.22;

  /// prototypeOnly: rekabetin ortalama fiyatı aşağı çekme gücü.
  static const double prototypeOnlyCompetitionPricePull = 0.10;

  /// prototypeOnly: itibarın talebe etkisinin genliği.
  static const double prototypeOnlyReputationSwing = 0.55;

  /// prototypeOnly: bakım ve personelin hizmete etkisinin genliği.
  static const double prototypeOnlyServiceSwing = 0.45;

  /// prototypeOnly: işin **kendi durumunun** talebe doğrudan etkisi.
  ///
  /// **Gerçek hata (ölçümde yakalandı).** AE'nin ilk hâlinde `condition`
  /// talebe yalnızca hizmet notu üzerinden giriyordu ve payı o kadar
  /// küçüktü ki durumu 10/100 olan bir büfe hâlâ kâr ediyordu. Oysa
  /// oyunun kendi sözü şu: **ilgilenilmeyen iş batar.** Durum artık
  /// talebe doğrudan biniyor: 50'nin altında hızla düşen bir eğri,
  /// üstünde ölçülü bir prim.
  static const double prototypeOnlyConditionFloorExp = 0.85;
  static const double prototypeOnlyConditionAtHalf = 0.90;
  static const double prototypeOnlyConditionTopBonus = 0.20;

  /// prototypeOnly: itibarın esnekliği kaydırma payı (§34).
  ///
  /// Adı iyi olan dükkân pahalı olmayı taşıyabilir; adı kötü olan
  /// taşıyamaz. Doğru fiyat böylece **duruma göre** değişir.
  static const double prototypeOnlyReputationElasticityShift = 0.35;

  /// prototypeOnly: rekabetin esnekliği kaydırma payı.
  static const double prototypeOnlyCompetitionElasticityShift = 0.45;

  /// prototypeOnly: kalıcı talep baskısının yılda ne kadar toparlandığı.
  ///
  /// Karşı sokağa açılan rakip birkaç yıl sonra sönümlenir ama o yıl
  /// içinde geçmez. 0,18 ile %12'lik bir darbe sekiz yılda üçte birine
  /// iner; oyuncu bu arada fiyat, reklam ve itibarla karşılık verebilir.
  static const double prototypeOnlyPressureRecovery = 0.10;

  /// prototypeOnly: kalıcı baskının inebileceği ve çıkabileceği sınır.
  ///
  /// Üst üste gelen rakipler işi sıfıra indirmesin, art arda gelen iyi
  /// haberler de işi sonsuz büyütmesin.
  static const double prototypeOnlyPressureFloor = 0.55;
  static const double prototypeOnlyPressureCeiling = 1.35;

  /// prototypeOnly: maaşlı işte de çalışan sahibin işletmeye
  /// verebildiği ilgi (§32).
  ///
  /// **Neden var.** §32 işletmenin bedelleri arasında "yönetim zamanı"nı
  /// sayıyor ama AE'nin ilk hâlinde bu hiç uygulanmıyordu: oyuncu tam
  /// zamanlı bir işte çalışırken dükkânı da eksiksiz yönetebiliyor,
  /// ikisinin gelirini birden alıyordu. İşletmeyi yönetmek bir iştir;
  /// iki işi birden yapan ikisini de tam yapamaz.
  ///
  /// Bu, işvereni de rahatsız eden aynı durumun dükkân tarafındaki
  /// karşılığıdır (D-143: işveren ikinci iş için laf eder).
  static const double prototypeOnlyEmployedAttention = 0.88;

  /// prototypeOnly: mevsimin talebe salınım payı.
  static const double prototypeOnlySeasonSwing = 0.22;

  /// prototypeOnly: işin kendi oynaklığının talebe salınım payı.
  static const double prototypeOnlyTypeVolatilitySwing = 0.34;

  /// prototypeOnly: fiyat oranının alt/üst sınırı.
  ///
  /// Oyuncu 1 ₺ fiyat yazıp sonsuz müşteri üretemez, 10 katı yazıp
  /// "belki birkaç kişi gelir" diyemez: iki uçta da eğri düzleşir.
  static const double prototypeOnlyMinPriceRatio = 0.35;
  static const double prototypeOnlyMaxPriceRatio = 2.60;

  /// prototypeOnly: ekonomi rejiminin ortalama fiyata etkisi.
  static double regimePriceFactor(MarketRegime r) => switch (r) {
        MarketRegime.kriz => 0.88,
        MarketRegime.durgun => 0.95,
        MarketRegime.normal => 1.00,
        MarketRegime.toparlanma => 1.03,
        MarketRegime.guclu => 1.09,
      };

  /// prototypeOnly: ekonomi rejiminin **talebe** etkisi.
  ///
  /// Krizde insanlar dışarıda daha az yiyor, salona daha az yazılıyor.
  static double regimeDemandFactor(MarketRegime r) => switch (r) {
        MarketRegime.kriz => 0.78,
        MarketRegime.durgun => 0.91,
        MarketRegime.normal => 1.00,
        MarketRegime.toparlanma => 1.04,
        MarketRegime.guclu => 1.14,
      };

  // -------------------------------------------------------------------
  // Zar
  // -------------------------------------------------------------------

  /// İşletme akışının tohumu.
  ///
  /// Piyasa zarından ayrıdır ve ana oyun akışından **çekiliş çalmaz**:
  /// aynı hayatın aynı yılı her zaman aynı işletme sonucunu verir, kayıt
  /// geri yüklenerek olay yeniden çevrilemez.
  static int seed(GameState state, String businessId, int age) {
    int h = 0x811c9dc5;
    void karistir(String metin) {
      for (final int kod in metin.codeUnits) {
        h = (h ^ kod) & 0xffffffff;
        h = (h * 0x01000193) & 0xffffffff;
      }
    }

    karistir(state.player.firstName);
    karistir(state.player.lastName);
    karistir(state.player.birthCity);
    karistir(businessId);
    h = (h ^ age) & 0xffffffff;
    h = (h * 0x01000193) & 0xffffffff;
    return h ^ 0x5bd1e995;
  }

  // -------------------------------------------------------------------
  // 1) Bölge ortalaması (§3)
  // -------------------------------------------------------------------

  /// Şehrin fiyat çarpanı.
  static double cityFactor(String? city) {
    if (city == null) return 1.0;
    final CityProfile p = cityProfile(city);
    return 1 + (p.housingFactor - 1) * prototypeOnlyCityPass;
  }

  /// Bölgedeki **rekabet baskısı** (§5).
  ///
  /// Kurgusaldır ve hayattan hayata değişir: aynı mahallede üç kuaför
  /// olabilir de, tek oto tamirci olabilir de. Yıllar içinde yumuşak
  /// biçimde kayar — bir yıl rakip açılır, birkaç yıl sonra kapanır —
  /// ama zıplamaz.
  static double competition(GameState state, BusinessType tur, int age) {
    final int t = seed(state, tur.id, 0);
    // İki farklı periyodun toplamı: tek bir sinüs fazla düzenli olurdu.
    final double faz1 = (t & 0xffff) / 0xffff * 2 * pi;
    final double faz2 = ((t >> 16) & 0xffff) / 0xffff * 2 * pi;
    final double dalga =
        sin(age / 7.0 + faz1) * 0.62 + sin(age / 17.0 + faz2) * 0.38;
    // Şehirde iş imkânı genişse rakip de fazladır.
    final CityProfile p = cityProfile(state.player.currentCity);
    final double sehirBaskisi = (p.opportunity - 0.5) * 0.12;
    return 1 + dalga * prototypeOnlyCompetitionSpread + sehirBaskisi;
  }

  /// Bölgedeki ortalama birim fiyat (§3).
  ///
  /// **Gerçek dünyadan gelmez.** Oyunun kendi ölçeğinden, şehirden,
  /// ekonomi rejiminden ve rekabetten doğar.
  static int averagePrice(GameState state, BusinessType tur, int age) {
    final double rekabet = competition(state, tur, age);
    // Rekabet arttıkça ortalama fiyat bir miktar **aşağı** gider:
    // karşı sokaktaki yeni dükkân indirim yapar.
    final double rekabetEtkisi =
        1 - (rekabet - 1) * prototypeOnlyCompetitionPricePull;
    final double ham = tur.basePrice *
        cityFactor(state.player.currentCity) *
        regimePriceFactor(state.market.regime) *
        rekabetEtkisi;
    return _yuvarla(ham);
  }

  /// İşletmenin fiilî fiyatı: belirlenmemişse bölge ortalaması (§4).
  static int effectivePrice(
    GameState state,
    Business business,
    BusinessType tur,
    int age,
  ) {
    if (business.price > 0) return business.price;
    return averagePrice(state, tur, age);
  }

  /// Fiyatı okunur bir basamağa yuvarlar: 1.247 yerine 1.250.
  static int _yuvarla(double ham) {
    if (ham <= 0) return 1;
    if (ham < 50) return ham.round().clamp(1, 1 << 30);
    if (ham < 500) return (ham / 5).round() * 5;
    if (ham < 5000) return (ham / 10).round() * 10;
    if (ham < 50000) return (ham / 100).round() * 100;
    return (ham / 1000).round() * 1000;
  }

  // -------------------------------------------------------------------
  // 2) Talep (§5)
  // -------------------------------------------------------------------

  /// Bir yılın müşteri yoğunluğunu hesaplar.
  ///
  /// [rng] yalnızca mevsim/şans salınımı için kullanılır; kararların
  /// etkisi zardan bağımsızdır.
  static BusinessDemand demand({
    required GameState state,
    required Business business,
    required BusinessType tur,
    required int age,
    required Random rng,
    double adLift = 0.0,
  }) {
    final int ortalama = averagePrice(state, tur, age);
    final int fiyat = effectivePrice(state, business, tur, age);
    final double oran = (fiyat / ortalama)
        .clamp(prototypeOnlyMinPriceRatio, prototypeOnlyMaxPriceRatio);

    // --- Fiyat (§4, §34) ---------------------------------------------
    final double fiyatEtkisi =
        pow(oran, -elasticityFor(business, tur, competition(state, tur, age)))
            .toDouble();

    // --- İtibar (§9) -------------------------------------------------
    final double itibar = 1 +
        (business.reputation - 50) / 50 *
            prototypeOnlyReputationSwing *
            tur.reputationWeight;

    // --- Hizmet: personel + bakım (§7, §10) --------------------------
    final double hizmet = 1 + (_serviceScore(business, tur) - 50) / 50 *
        prototypeOnlyServiceSwing;

    // --- İşin durumu -------------------------------------------------
    final double durum = conditionFactor(business.condition);

    // --- Sahibin zamanı (§32) ----------------------------------------
    final double ilgi = state.career.isEmployed && !state.career.isRetired
        ? prototypeOnlyEmployedAttention
        : 1.0;

    // --- Reklam (§8) -------------------------------------------------
    final double reklam = 1 + adLift;

    // --- Şehir, ekonomi, rekabet (§5) --------------------------------
    final CityProfile p = cityProfile(state.player.currentCity);
    final double sehir = 0.94 + p.opportunity * 0.14;
    final double ekonomi = regimeDemandFactor(state.market.regime);
    final double rekabet = competition(state, tur, age);

    // --- Mevsim, işin kendi oynaklığı ve şans ------------------------
    //
    // **Gerçek hata (ölçümde yakalandı).** AE'nin ilk hâlinde buraya
    // yalnızca [BusinessType.seasonality] giriyordu;
    // [BusinessType.volatility] ise eski motordan kalma biçimde sadece
    // `condition` salınımına bakıyordu. İşine bakan bir sahipte durum
    // tavanda kaldığı için katalogda yazan oynaklık (lokanta 0,60,
    // terzi 0,25) kâra **hiç** yansımıyordu: 14 işletmede 1400'er yıl
    // ölçüldü, zarar yılı %0 ile %3,7 arasında ve en uzun zarar serisi
    // 3 çıktı. Yani iyi yönetilen işletme tahvil gibi davranıyordu ve
    // `isletme aktif` oyunun en güvenli stratejisi oluyordu — §32'nin
    // yasakladığı şey.
    //
    // Oynaklık artık doğrudan talebe biniyor: lokantanın yılı terzininkine
    // benzemez.
    final double salinim = (rng.nextDouble() * 2 - 1) *
        (tur.seasonality * prototypeOnlySeasonSwing +
            tur.volatility * prototypeOnlyTypeVolatilitySwing);

    final double toplam = fiyatEtkisi *
        itibar *
        hizmet *
        durum *
        ilgi *
        reklam *
        sehir *
        ekonomi *
        business.demandPressure /
        rekabet *
        (1 + salinim);

    return BusinessDemand(
      marketPrice: ortalama,
      price: fiyat,
      index: (toplam * 100).round().clamp(0, 400),
      priceEffect: fiyatEtkisi,
      reputationEffect: itibar,
      adEffect: reklam,
      serviceEffect: hizmet,
      competition: rekabet,
    );
  }

  /// Bu işletmenin **fiilî** fiyat esnekliği (§4, §34).
  ///
  /// **Gerçek hata (ölçümde yakalandı).** İlk hâlinde esneklik doğrudan
  /// katalogdan geliyordu ve 1'in altında kalan her işte "fiyatı sonuna
  /// kadar yükselt" **mutlak baskın** stratejiydi: sabit esneklikli talep
  /// eğrisinde ciro, esneklik 1'in altındayken fiyatla birlikte sürekli
  /// artar. Ölçüm 14 işletmenin 10'unda en pahalı seçeneğin kazandığını
  /// gösterdi — §34'ün tam olarak yasakladığı şey.
  ///
  /// Çözüm, esnekliği **gider yapısına çıpalamak**. Birim maliyeti
  /// cironun `m` payı olan bir işte, piyasa fiyatını tam optimum yapan
  /// esneklik `1 / (1 - m)`'dir. Katalogdaki [BusinessType.priceElasticity]
  /// artık bunun **etrafında bir çarpan**: 1'den büyükse müşteri fiyata
  /// duyarlıdır ve optimum piyasanın altına iner (halı saha), küçükse
  /// güvenle gelinir ve optimum piyasanın üstüne çıkar (oto tamir).
  ///
  /// Üstüne itibar ve rekabet biner: adı iyi olan dükkân pahalı olmayı
  /// taşır, rakip çoğalınca taşıyamaz. Böylece doğru fiyat sabit bir
  /// sayı değil, işletmenin hâline bağlı bir karar olur (§34).
  static double elasticityFor(
    Business business,
    BusinessType tur,
    double rekabet,
  ) {
    final double m = tur.supplyShare.clamp(0.0, 0.85);
    final double notr = 1 / (1 - m);
    final double itibarKaymasi = 1 +
        (50 - business.reputation) / 50 * prototypeOnlyReputationElasticityShift;
    final double rekabetKaymasi =
        1 + (rekabet - 1) * prototypeOnlyCompetitionElasticityShift;
    // Esneklik 1'in altına inemez: indiği anda "fiyatı sonsuza yükselt"
    // yeniden baskın strateji olurdu.
    return (notr * tur.priceElasticity * itibarKaymasi * rekabetKaymasi)
        .clamp(1.05, 6.0)
        .toDouble();
  }

  /// İşin durumunun talebe çarpanı.
  ///
  /// 50'de 0,90; 100'de 1,10; 10'da 0,23. Batmak üzere olan dükkâna
  /// kimse gelmez — ve sabit giderler ödenmeye devam eder.
  static double conditionFactor(int condition) {
    final int d = condition.clamp(0, 100);
    if (d >= 50) {
      return prototypeOnlyConditionAtHalf +
          (d - 50) / 50 * prototypeOnlyConditionTopBonus;
    }
    return prototypeOnlyConditionAtHalf *
        pow(d / 50, prototypeOnlyConditionFloorExp).toDouble();
  }

  /// İşin **hizmet notu**: personel, bakım ve işin genel durumu.
  ///
  /// Tek tek çalışan kaydı tutulmaz (§7): kadro sayı, kalite ve
  /// memnuniyetten ibarettir.
  static double serviceScore(Business business, BusinessType tur) =>
      _serviceScore(business, tur);

  static double _serviceScore(Business business, BusinessType tur) {
    final int tam = tur.staffSlots;
    if (tam <= 0) {
      // Tek başına yürüyen işte hizmeti işin durumu ve ekipman belirler.
      return business.condition * 0.55 + business.upkeep * 0.45;
    }
    final double kadro = tam == 0 ? 1.0 : business.effectiveStaff / tam;
    final double personel =
        (business.staffQuality * 0.6 + business.staffMorale * 0.4) *
            (0.45 + kadro * 0.55);
    return personel * 0.50 + business.upkeep * 0.28 + business.condition * 0.22;
  }
}
