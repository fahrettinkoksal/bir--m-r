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
      setupCost: _wage(0.7),
      baseYearlyProfit: _wage(0.9),
      volatility: 0.30,
      minAge: 18,
    ),
    BusinessType(
      id: 'is_kuruyemis',
      name: 'Kuruyemişçi',
      description: 'Kavurma kokusu sokağa yayılır, müşteri ona gelir.',
      scale: BusinessScale.kucuk,
      setupCost: _wage(0.9),
      baseYearlyProfit: _wage(1.0),
      volatility: 0.28,
      minAge: 18,
    ),
    BusinessType(
      id: 'is_serbest_yazilim',
      name: 'Serbest yazılımcılık',
      description: 'Sermaye bir bilgisayar. Gerisi iş bulmakta.',
      scale: BusinessScale.kucuk,
      setupCost: _wage(0.25),
      baseYearlyProfit: _wage(1.6),
      volatility: 0.55,
      minAge: 18,
      minIntelligence: 55,
    ),
    BusinessType(
      id: 'is_terzi',
      name: 'Terzi atölyesi',
      description: 'Bir makine, bir ütü, sabır.',
      scale: BusinessScale.kucuk,
      setupCost: _wage(0.6),
      baseYearlyProfit: _wage(0.8),
      volatility: 0.25,
      minAge: 20,
    ),

    // =================================================================
    // Orta ölçek — dükkân tutulur, çalışan olur
    // =================================================================
    BusinessType(
      id: 'is_kahve',
      name: 'Kahve dükkânı',
      description: 'Sabah kalabalığı, akşam sessizliği, sürekli kira.',
      scale: BusinessScale.orta,
      setupCost: _wage(2.4),
      baseYearlyProfit: _wage(1.9),
      volatility: 0.45,
      minAge: 20,
      minCharisma: 35,
    ),
    BusinessType(
      id: 'is_bakkal',
      name: 'Bakkal',
      description: 'Herkes seni tanır, yarısı veresiye ister.',
      scale: BusinessScale.orta,
      setupCost: _wage(2.0),
      baseYearlyProfit: _wage(1.5),
      volatility: 0.32,
      minAge: 20,
    ),
    BusinessType(
      id: 'is_kuafor_salonu',
      name: 'Kuaför salonu',
      description: 'Koltuklar dolu olursa güzel, boşsa uzun gün.',
      scale: BusinessScale.orta,
      setupCost: _wage(1.3),
      baseYearlyProfit: _wage(1.7),
      volatility: 0.40,
      minAge: 20,
      minCharisma: 40,
    ),
    BusinessType(
      id: 'is_oto_tamir',
      name: 'Oto tamir dükkânı',
      description: 'Sanayide bir bölme, bir kriko, bitmeyen iş.',
      scale: BusinessScale.orta,
      setupCost: _wage(1.8),
      baseYearlyProfit: _wage(2.1),
      volatility: 0.38,
      minAge: 22,
    ),
    BusinessType(
      id: 'is_pastane',
      name: 'Pastane',
      description: 'Sabah dörtte fırın yanar, bayramlarda kuyruk olur.',
      scale: BusinessScale.orta,
      setupCost: _wage(2.6),
      baseYearlyProfit: _wage(2.0),
      volatility: 0.42,
      minAge: 22,
    ),
    BusinessType(
      id: 'is_nakliye',
      name: 'Nakliyecilik',
      description: 'Bir kamyonet, bir telefon. Yol seni yer.',
      scale: BusinessScale.orta,
      setupCost: _wage(3.4),
      baseYearlyProfit: _wage(2.3),
      volatility: 0.50,
      minAge: 22,
      requiredLicenses: <String>{'otomobil_ehliyeti'},
    ),

    // =================================================================
    // Büyük ölçek — büyük sermaye, büyük oynaklık
    // =================================================================
    BusinessType(
      id: 'is_hali_saha',
      name: 'Halı saha işletmesi',
      description: 'Akşam yedi-on bir arası dolu, gerisi boş.',
      scale: BusinessScale.buyuk,
      setupCost: _wage(7.0),
      baseYearlyProfit: _wage(3.4),
      volatility: 0.48,
      minAge: 24,
    ),
    BusinessType(
      id: 'is_spor_salonu',
      name: 'Spor salonu',
      description: 'Ocak ayında dolar, martta boşalır.',
      scale: BusinessScale.buyuk,
      setupCost: _wage(8.5),
      baseYearlyProfit: _wage(3.8),
      volatility: 0.55,
      minAge: 24,
    ),
    BusinessType(
      id: 'is_lokanta',
      name: 'Lokanta',
      description: 'Mutfak, personel, denetim ve her akşam yeni bir sınav.',
      scale: BusinessScale.buyuk,
      setupCost: _wage(6.0),
      baseYearlyProfit: _wage(3.2),
      volatility: 0.60,
      minAge: 24,
    ),
  ],
);

BusinessType? businessTypeById(String id) {
  for (final BusinessType b in kBusinessCatalog) {
    if (b.id == id) return b;
  }
  return null;
}
