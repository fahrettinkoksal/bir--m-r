/// Kendi işi kataloğu (D-132).
///
/// **Ölçülen sorun:** 44 mesleğin **hepsi maaşlıydı**. 120 hayatta en çok
/// girilen işler hep giriş seviyesiydi (depo personeli 35, kasiyer 28,
/// garson 25) ve bir hayatta ortalama 2,58 meslek görülüyordu. Kariyerin
/// tek bir şekli vardı: birine çalışmak.
///
/// Kendi işi bunu kırar. Maaş gibi **garanti değildir**: sermaye ister,
/// kâr da eder zarar da, ilgilenilmezse batar.
///
/// Sermaye ve kâr sayıları 2026 Türkiye'sine göre `Economy` çıpasından
/// türetilir ve hepsi `prototypeOnly`'dir (Q-146).
library;

import 'package:flutter/foundation.dart';

import 'economy.dart';

/// İşin ölçeği. Sermaye ve risk buna bağlıdır.
enum BusinessScale {
  /// Tek başına, küçük sermayeyle kurulan iş.
  kucuk('Küçük'),

  /// Dükkân tutulan, birkaç kişi çalıştırılan iş.
  orta('Orta'),

  /// Büyük sermaye, büyük gider, büyük kâr ihtimali.
  buyuk('Büyük');

  const BusinessScale(this.label);

  final String label;
}

@immutable
class BusinessType {
  const BusinessType({
    required this.id,
    required this.name,
    required this.description,
    required this.scale,
    required this.setupCost,
    required this.baseYearlyProfit,
    required this.volatility,
    required this.priceLabel,
    required this.basePrice,
    required this.priceElasticity,
    required this.reputationWeight,
    required this.staffSlots,
    required this.staffShare,
    required this.supplyShare,
    required this.fixedShare,
    required this.wearRate,
    this.hasShopfront = true,
    this.equipmentLabel,
    this.seasonality = 0.0,
    this.incidentTags = const <String>{},
    this.minAge = 18,
    this.requiredLicenses = const <String>{},
    this.hobbyId,
    this.minIntelligence = 0,
    this.minCharisma = 0,
  });

  final String id;
  final String name;
  final String description;
  final BusinessScale scale;

  /// Kurulum sermayesi (₺). Peşin ödenir.
  final int setupCost;

  /// İşin durumu **iyi** olduğunda yıllık kâr (₺).
  ///
  /// Gerçek kâr işin durumuna göre bunun altına iner ve **eksiye
  /// düşebilir**: kötü giden iş para yer.
  final int baseYearlyProfit;

  /// prototypeOnly: yıldan yıla oynaklık (0-1). Yüksek oynaklık hem
  /// büyük kâr hem büyük zarar demektir.
  final double volatility;

  /// Bu işin **sattığı şeyin** adı (Paket AE, §2).
  ///
  /// Ekranda fiyatın başlığı olarak görünür: halı sahada "Maç / saat
  /// ücreti", kuaförde "Saç kesim ortalaması". Her işin kendi satışı
  /// vardır; hepsine "fiyat" demek işleri birbirinin aynısı yapardı.
  final String priceLabel;

  /// prototypeOnly: bu işin **oyun içi** referans birim fiyatı (₺).
  ///
  /// Gerçek dünyadan gelmez ve gerçek yıla bağlı değildir (§3). Oyunun
  /// kendi 2026 alım gücü ölçeğine oturur; bölgedeki piyasa ortalaması
  /// bunun üstünden şehir, rekabet ve ekonomiyle türetilir.
  final int basePrice;

  /// prototypeOnly: fiyat hassasiyeti (§4).
  ///
  /// **1,0 etrafında bir çarpandır**, ham esneklik değil. Ham esneklik
  /// işin gider yapısından türetilir ([BusinessMarket.elasticityFor]):
  /// piyasa fiyatını tam optimum yapan değer çıpadır, bu sayı onu kaydırır.
  ///
  /// * 1'den **büyük**: müşteri fiyata duyarlı, optimum piyasanın altına
  ///   iner (halı saha — bir sokak ötede başka saha var).
  /// * 1'den **küçük**: iş güvenle gelir, optimum piyasanın üstüne çıkar
  ///   (oto tamir — usta değiştirmek kolay değil).
  final double priceElasticity;

  /// prototypeOnly: itibarın talebe etkisinin ağırlığı (§9).
  ///
  /// Oto tamir ve serbest yazılımcılıkta yüksektir: iş referansla gelir.
  /// Büfede düşüktür: yolun üstündeki büfeden tost alınır.
  final double reputationWeight;

  /// prototypeOnly: işin tam kadrosundaki çalışan sayısı (§7).
  ///
  /// 0 ise iş tek başına yürür ve personel olayları çıkmaz. Tek tek
  /// [Person] kaydı **açılmaz**: kadro sayı, kalite ve memnuniyetten
  /// ibarettir.
  final int staffSlots;

  /// prototypeOnly: cironun personel payı.
  final double staffShare;

  /// prototypeOnly: cironun tedarik/malzeme payı.
  final double supplyShare;

  /// prototypeOnly: cironun kira ve sabit gider payı.
  final double fixedShare;

  /// prototypeOnly: ekipmanın yıllık yıpranması (§10).
  final double wearRate;

  /// Yıpranan şeyin adı (§10): "sentetik çim ve projektörler".
  ///
  /// `null` ise işin bakım gerektiren bir mekânı/ekipmanı yoktur.
  final String? equipmentLabel;

  /// prototypeOnly: mevsim oynaklığı (0-1).
  ///
  /// Spor salonu ocakta dolar martta boşalır; halı saha yazın boşalır.
  /// Bakkalın mevsimi yoktur.
  final double seasonality;

  /// Bu işin çekebileceği olay etiketleri (§11-24).
  final Set<String> incidentTags;

  /// İşin fiziksel bir dükkânı/mekânı var mı?
  ///
  /// Serbest yazılımcılıkta yoktur: su basması, dolap bozulması, ruhsat
  /// denetimi gibi olaylar ona **gelmez** (§21).
  final bool hasShopfront;

  /// Cironun sabit gider payı toplamı.
  double get costShare => staffShare + supplyShare + fixedShare;

  /// prototypeOnly: **iyi yönetilen** bir yılda beklenen ciro (₺).
  ///
  /// [baseYearlyProfit] tasarımın hedefi; ciro ondan **türetilir**.
  /// Böylece gider yapısı değişince kâr hedefi elde kalır.
  int get baseRevenue => (baseYearlyProfit / (1 - costShare)).round();

  /// prototypeOnly: iyi yönetilen bir işletmenin müşteri yoğunluğu.
  ///
  /// **Ölçümle seçildi.** Fiyatı yerinde, bakımı yapılmış, kadrosu tam
  /// ve adı iyi bir işletmenin yoğunluk endeksi 14 işletmede 138-164
  /// arasında, medyanı 148 çıktı. Adet bu noktaya çıpalanıyor: yani
  /// [baseYearlyProfit] artık "işi iyi yöneten kişinin kazandığı" —
  /// katalogdaki açıklamasıyla aynı şey.
  ///
  /// Çıpa taban koşullara (100) konsaydı iyi yönetilen iş taban kârın
  /// 2,5 katını verirdi ve §32'nin uyardığı dominans daha da büyürdü.
  static const double prototypeOnlyWellRunDemand = 148;

  /// prototypeOnly: iyi yönetilen bir yılda satılan birim sayısı.
  ///
  /// Fiyat oyuncunun elindedir; satılan **adet** talep motorundan gelir.
  double get baseUnits =>
      baseRevenue / (basePrice * prototypeOnlyWellRunDemand / 100);

  final int minAge;
  final Set<String> requiredLicenses;

  /// Bu iş bir hobiye dayanıyorsa o hobinin kimliği.
  final String? hobbyId;

  final int minIntelligence;
  final int minCharisma;

  /// İşi kapatırken geri alınabilecek kabaca tutar (devir/hurda değeri).
  ///
  /// Kurulum sermayesinin bir kısmı geri gelir; tamamı gelmez.
  int get salvageValue => (setupCost * 0.45).round();
}

/// prototypeOnly: tutarlar asgari ücret çıpasından türetilir.
int _wage(double kat) => (Economy.netYearlyMinimumWage * kat).round();

/// Kurulabilecek işler.
///
/// Yeni türler listenin **sonuna** eklenir; kimlikler kayda yazıldığı
/// için değiştirilmez.
final List<BusinessType> kBusinessCatalog = List<BusinessType>.unmodifiable(
  <BusinessType>[
    // =================================================================
    // Küçük ölçek — az sermaye, az kâr, düşük risk
    // =================================================================
    BusinessType(
      id: 'is_buyfe',
      name: 'Büfe',
      description: 'Tost, çay, gazete. Sabah altıda açılır.',
      scale: BusinessScale.kucuk,
      setupCost: _wage(1.60),
      baseYearlyProfit: _wage(0.62),
      volatility: 0.34,
      minAge: 18,
      priceLabel: 'Ortalama ürün fiyatı',
      basePrice: 95,
      priceElasticity: 1.12,
      reputationWeight: 0.60,
      staffSlots: 0,
      staffShare: 0.00,
      supplyShare: 0.55,
      fixedShare: 0.12,
      wearRate: 5,
      equipmentLabel: 'dolap ve tost makinesi',
      seasonality: 0.12,
      incidentTags: <String>{'dukkan', 'tedarik', 'perakende'},
    ),
    BusinessType(
      id: 'is_kuruyemis',
      name: 'Kuruyemişçi',
      description: 'Kavurma kokusu sokağa yayılır, müşteri ona gelir.',
      scale: BusinessScale.kucuk,
      setupCost: _wage(1.90),
      baseYearlyProfit: _wage(0.68),
      volatility: 0.32,
      minAge: 18,
      priceLabel: 'Ortalama kilo fiyatı',
      basePrice: 480,
      priceElasticity: 1.04,
      reputationWeight: 0.75,
      staffSlots: 0,
      staffShare: 0.00,
      supplyShare: 0.52,
      fixedShare: 0.13,
      wearRate: 5,
      equipmentLabel: 'kavurma makinesi ve teraziler',
      seasonality: 0.14,
      incidentTags: <String>{'dukkan', 'tedarik', 'perakende'},
    ),
    BusinessType(
      id: 'is_serbest_yazilim',
      name: 'Serbest yazılımcılık',
      description: 'Sermaye bir bilgisayar. Gerisi iş bulmakta.',
      scale: BusinessScale.kucuk,
      setupCost: _wage(1.60),
      baseYearlyProfit: _wage(1.05),
      volatility: 0.95,
      minAge: 18,
      minIntelligence: 55,
      priceLabel: 'Ortalama proje teklifi',
      basePrice: 85000,
      priceElasticity: 0.72,
      reputationWeight: 1.30,
      staffSlots: 0,
      staffShare: 0.00,
      supplyShare: 0.08,
      fixedShare: 0.18,
      wearRate: 4,
      hasShopfront: false,
      equipmentLabel: 'bilgisayar',
      seasonality: 0.10,
      incidentTags: <String>{'serbest'},
    ),
    BusinessType(
      id: 'is_terzi',
      name: 'Terzi atölyesi',
      description: 'Bir makine, bir ütü, sabır.',
      scale: BusinessScale.kucuk,
      setupCost: _wage(1.50),
      baseYearlyProfit: _wage(0.55),
      volatility: 0.30,
      minAge: 20,
      priceLabel: 'Ortalama işlem ücreti',
      basePrice: 550,
      priceElasticity: 0.86,
      reputationWeight: 1.05,
      staffSlots: 1,
      staffShare: 0.12,
      supplyShare: 0.22,
      fixedShare: 0.14,
      wearRate: 6,
      equipmentLabel: 'dikiş makineleri',
      seasonality: 0.26,
      incidentTags: <String>{'dukkan', 'atolye', 'tedarik', 'dugun'},
    ),

    // =================================================================
    // Orta ölçek — dükkân tutulur, çalışan olur
    // =================================================================
    BusinessType(
      id: 'is_kahve',
      name: 'Kahve dükkânı',
      description: 'Sabah kalabalığı, akşam sessizliği, sürekli kira.',
      scale: BusinessScale.orta,
      setupCost: _wage(4.60),
      baseYearlyProfit: _wage(1.25),
      volatility: 0.50,
      minAge: 20,
      minCharisma: 35,
      priceLabel: 'Ortalama içecek fiyatı',
      basePrice: 130,
      priceElasticity: 1.00,
      reputationWeight: 0.95,
      staffSlots: 3,
      staffShare: 0.24,
      supplyShare: 0.28,
      fixedShare: 0.18,
      wearRate: 9,
      equipmentLabel: 'kahve makinesi ve değirmen',
      seasonality: 0.14,
      incidentTags: <String>{'dukkan', 'kahve', 'tedarik', 'sosyal', 'gida'},
    ),
    BusinessType(
      id: 'is_bakkal',
      name: 'Bakkal',
      description: 'Herkes seni tanır, yarısı veresiye ister.',
      scale: BusinessScale.orta,
      setupCost: _wage(4.00),
      baseYearlyProfit: _wage(1.05),
      volatility: 0.38,
      minAge: 20,
      priceLabel: 'Ortalama sepet tutarı',
      basePrice: 240,
      priceElasticity: 1.10,
      reputationWeight: 0.70,
      staffSlots: 1,
      staffShare: 0.10,
      supplyShare: 0.52,
      fixedShare: 0.12,
      wearRate: 6,
      equipmentLabel: 'soğutucu dolaplar',
      seasonality: 0.10,
      incidentTags: <String>{'dukkan', 'tedarik', 'perakende'},
    ),
    BusinessType(
      id: 'is_kuafor_salonu',
      name: 'Kuaför salonu',
      description: 'Koltuklar dolu olursa güzel, boşsa uzun gün.',
      scale: BusinessScale.orta,
      setupCost: _wage(4.00),
      baseYearlyProfit: _wage(1.15),
      volatility: 0.44,
      minAge: 20,
      minCharisma: 40,
      priceLabel: 'Saç kesim ortalaması',
      basePrice: 400,
      priceElasticity: 0.84,
      reputationWeight: 1.20,
      staffSlots: 2,
      staffShare: 0.26,
      supplyShare: 0.12,
      fixedShare: 0.17,
      wearRate: 7,
      equipmentLabel: 'koltuklar ve ekipman',
      seasonality: 0.22,
      incidentTags: <String>{'dukkan', 'kuafor', 'sosyal', 'dugun'},
    ),
    BusinessType(
      id: 'is_oto_tamir',
      name: 'Oto tamir dükkânı',
      description: 'Sanayide bir bölme, bir kriko, bitmeyen iş.',
      scale: BusinessScale.orta,
      setupCost: _wage(5.20),
      baseYearlyProfit: _wage(1.40),
      volatility: 0.42,
      minAge: 22,
      priceLabel: 'Ortalama işçilik ücreti',
      basePrice: 2200,
      priceElasticity: 0.70,
      reputationWeight: 1.25,
      staffSlots: 2,
      staffShare: 0.22,
      supplyShare: 0.30,
      fixedShare: 0.13,
      wearRate: 9,
      equipmentLabel: 'lift ve kompresör',
      seasonality: 0.12,
      incidentTags: <String>{'dukkan', 'atolye', 'oto', 'tedarik', 'filo'},
    ),
    BusinessType(
      id: 'is_pastane',
      name: 'Pastane',
      description: 'Sabah dörtte fırın yanar, bayramlarda kuyruk olur.',
      scale: BusinessScale.orta,
      setupCost: _wage(5.00),
      baseYearlyProfit: _wage(1.30),
      volatility: 0.46,
      minAge: 22,
      priceLabel: 'Ortalama ürün sepeti',
      basePrice: 320,
      priceElasticity: 0.98,
      reputationWeight: 1.00,
      staffSlots: 3,
      staffShare: 0.22,
      supplyShare: 0.32,
      fixedShare: 0.15,
      wearRate: 10,
      equipmentLabel: 'fırın ve hamur makinesi',
      seasonality: 0.30,
      incidentTags: <String>{'dukkan', 'firin', 'tedarik', 'gida', 'bayram'},
    ),
    BusinessType(
      id: 'is_nakliye',
      name: 'Nakliyecilik',
      description: 'Bir kamyonet, bir telefon. Yol seni yer.',
      scale: BusinessScale.orta,
      setupCost: _wage(6.20),
      baseYearlyProfit: _wage(1.55),
      volatility: 0.54,
      minAge: 22,
      requiredLicenses: <String>{'otomobil_ehliyeti'},
      priceLabel: 'Ortalama taşıma ücreti',
      basePrice: 9500,
      priceElasticity: 0.92,
      reputationWeight: 1.10,
      staffSlots: 2,
      staffShare: 0.20,
      supplyShare: 0.34,
      fixedShare: 0.11,
      wearRate: 10,
      hasShopfront: false,
      equipmentLabel: 'araçlar',
      seasonality: 0.24,
      incidentTags: <String>{'nakliye', 'arac', 'tedarik', 'filo'},
    ),
    BusinessType(
      id: 'is_oto_yikama',
      name: 'Oto yıkama',
      description: 'Su, köpük, basınç. Yağmur yağınca gün boş geçer.',
      scale: BusinessScale.orta,
      setupCost: _wage(4.20),
      baseYearlyProfit: _wage(1.10),
      volatility: 0.48,
      minAge: 20,
      priceLabel: 'Yıkama ücreti',
      basePrice: 550,
      priceElasticity: 1.14,
      reputationWeight: 0.80,
      staffSlots: 3,
      staffShare: 0.28,
      supplyShare: 0.14,
      fixedShare: 0.18,
      wearRate: 11,
      equipmentLabel: 'basınç makinesi',
      seasonality: 0.32,
      incidentTags: <String>{'dukkan', 'oto', 'yikama', 'filo', 'su'},
    ),

    // =================================================================
    // Büyük ölçek — büyük sermaye, büyük oynaklık
    // =================================================================
    BusinessType(
      id: 'is_hali_saha',
      name: 'Halı saha işletmesi',
      description: 'Akşam yedi-on bir arası dolu, gerisi boş.',
      scale: BusinessScale.buyuk,
      setupCost: _wage(10.00),
      baseYearlyProfit: _wage(1.95),
      volatility: 0.54,
      minAge: 24,
      priceLabel: 'Maç / saat ücreti',
      basePrice: 1250,
      priceElasticity: 1.30,
      reputationWeight: 0.70,
      staffSlots: 2,
      staffShare: 0.14,
      supplyShare: 0.06,
      fixedShare: 0.34,
      wearRate: 12,
      equipmentLabel: 'sentetik çim ve projektörler',
      seasonality: 0.36,
      incidentTags: <String>{'saha', 'tesis', 'su', 'turnuva'},
    ),
    BusinessType(
      id: 'is_spor_salonu',
      name: 'Spor salonu',
      description: 'Ocak ayında dolar, martta boşalır.',
      scale: BusinessScale.buyuk,
      setupCost: _wage(12.00),
      baseYearlyProfit: _wage(2.15),
      volatility: 0.60,
      minAge: 24,
      priceLabel: 'Aylık üyelik',
      basePrice: 1400,
      priceElasticity: 1.16,
      reputationWeight: 0.95,
      staffSlots: 4,
      staffShare: 0.26,
      supplyShare: 0.05,
      fixedShare: 0.32,
      wearRate: 12,
      equipmentLabel: 'aletler ve duşlar',
      seasonality: 0.42,
      incidentTags: <String>{'tesis', 'salon', 'su', 'sosyal'},
    ),
    BusinessType(
      id: 'is_lokanta',
      name: 'Lokanta',
      description: 'Mutfak, personel, denetim ve her akşam yeni bir sınav.',
      scale: BusinessScale.buyuk,
      setupCost: _wage(10.00),
      baseYearlyProfit: _wage(1.85),
      volatility: 0.66,
      minAge: 24,
      priceLabel: 'Ortalama hesap',
      basePrice: 700,
      priceElasticity: 0.94,
      reputationWeight: 1.15,
      staffSlots: 6,
      staffShare: 0.24,
      supplyShare: 0.29,
      fixedShare: 0.17,
      wearRate: 11,
      equipmentLabel: 'mutfak, buzdolabı ve fırın',
      seasonality: 0.24,
      incidentTags: <String>{
        'dukkan',
        'mutfak',
        'tedarik',
        'gida',
        'sosyal',
        'bayram',
      },
    ),
  ],
);

BusinessType? businessTypeById(String id) {
  for (final BusinessType b in kBusinessCatalog) {
    if (b.id == id) return b;
  }
  return null;
}
