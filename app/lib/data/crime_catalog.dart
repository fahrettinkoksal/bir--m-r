/// Suç ve hukuk kataloğu (D-128).
///
/// **Kapsam bilinçli olarak dardır.** Oyun suç işlemeyi öğretmez; yalnızca
/// seçimlerin hukuki ve toplumsal sonucunu canlandırır. Bu yüzden katalog
/// **yüksek seviyede** durur: olayın adı, ağırlığı ve sonucu vardır;
/// yöntem, kaçış ya da yakalanmama taktiği **yoktur ve yazılmayacaktır**.
///
/// Ağır/organize suç bu sürümde yoktur (Q-141).
///
/// Para tutarları 2026 Türkiye alım gücüne göre `Economy` çıpasından
/// türetilir ve hepsi `prototypeOnly`'dir.
library;

import 'package:flutter/foundation.dart';

import 'economy.dart';

/// Olayın ağırlığı. Sonucu ve sabıkanın etkisini bu belirler.
enum CrimeSeverity {
  /// İdari yaptırım düzeyinde: ceza kesilir, iş orada biter.
  hafif('Hafif'),

  /// Soruşturma açılabilir, mahkemeye gidebilir.
  orta('Orta'),

  /// Genellikle mahkemeye gider; hapis ihtimali gerçektir.
  agir('Ağır');

  const CrimeSeverity(this.label);

  final String label;
}

/// Olayın türü. Sabıkanın hangi işleri etkilediği buna bakar.
enum CrimeCategory {
  trafik('Trafik'),
  kavga('Kavga / asayiş'),
  kamuDuzeni('Kamu düzeni'),
  malaZarar('Mala zarar'),
  hirsizlik('Hırsızlık'),
  isEtigi('İş yerinde etik ihlali'),
  yaralama('Yaralama'),
  borcAlacak('Borç / alacak');

  const CrimeCategory(this.label);

  final String label;
}

/// Bir hukuki olayın tanımı.
///
/// Katalog **sonucu** tarif eder, eylemi değil: oyuncu olay ekranında
/// riskli bir seçim yapar, bu kayıt o seçimin hukuk tarafını anlatır.
@immutable
class CrimeType {
  const CrimeType({
    required this.id,
    required this.label,
    required this.category,
    required this.severity,
    required this.recordLabel,
    this.courtChance = 0.0,
    this.onSpotFine = 0,
    this.fineMin = 0,
    this.fineMax = 0,
    this.prisonYearsMin = 0,
    this.prisonYearsMax = 0,
    this.familyShockPoints = 0,
  });

  final String id;

  /// Bildirimde ve günlükte görünen ad.
  final String label;

  final CrimeCategory category;
  final CrimeSeverity severity;

  /// Adli Geçmiş ekranında yazılan sabıka satırı.
  final String recordLabel;

  /// prototypeOnly: olayın mahkemeye gitme ihtimali.
  ///
  /// 0 ise olay idari cezayla kapanır ve **sabıka kaydı açılmaz**;
  /// trafik cezası insanı sabıkalı yapmaz.
  final double courtChance;

  /// Olay yerinde kesilen ceza (₺). Yalnızca hafif olaylarda doludur.
  final int onSpotFine;

  /// Mahkeme para cezası verirse alt ve üst sınır (₺).
  final int fineMin;
  final int fineMax;

  /// Mahkûmiyet hapisle sonuçlanırsa yıl aralığı.
  ///
  /// 0 ise bu olaydan hapis çıkmaz.
  final int prisonYearsMin;
  final int prisonYearsMax;

  /// prototypeOnly: ailenin tepkisinin ağırlığı (0 = tepki yok).
  final int familyShockPoints;

  /// Bu olay sabıka kaydı bırakabilir mi?
  bool get canLeaveRecord => courtChance > 0;
}

/// prototypeOnly: para cezaları asgari ücret çıpasından türetilir.
int _wagePart(double oran) =>
    (Economy.netMonthlyMinimumWage * oran).round();

/// Suç ve hukuk kataloğu.
///
/// Yeni türler listenin **sonuna** eklenir; kimlikler kayda yazıldığı için
/// değiştirilmez.
final List<CrimeType> kCrimeCatalog = List<CrimeType>.unmodifiable(
  <CrimeType>[
    // =================================================================
    // Trafik — idari, sabıka bırakmaz
    // =================================================================
    CrimeType(
      id: 'trafik_hiz',
      label: 'Hız ihlali',
      category: CrimeCategory.trafik,
      severity: CrimeSeverity.hafif,
      recordLabel: 'Hız ihlali cezası',
      onSpotFine: _wagePart(0.09),
    ),
    CrimeType(
      id: 'trafik_park',
      label: 'Yanlış park',
      category: CrimeCategory.trafik,
      severity: CrimeSeverity.hafif,
      recordLabel: 'Park cezası',
      onSpotFine: _wagePart(0.03),
    ),
    CrimeType(
      id: 'trafik_kaza',
      label: 'Maddi hasarlı trafik kazası',
      category: CrimeCategory.trafik,
      severity: CrimeSeverity.hafif,
      recordLabel: 'Trafik kazası tutanağı',
      onSpotFine: _wagePart(0.22),
    ),
    // Alkollü araç kullanmak idari olarak ağır bir ihlaldir ve ehliyete
    // dokunur; mahkemeye de gidebilir.
    CrimeType(
      id: 'trafik_alkollu',
      label: 'Alkollü araç kullanma',
      category: CrimeCategory.trafik,
      severity: CrimeSeverity.orta,
      recordLabel: 'Alkollü araç kullanma',
      onSpotFine: _wagePart(1.1),
      courtChance: 0.35,
      fineMin: _wagePart(1.5),
      fineMax: _wagePart(4.0),
      familyShockPoints: 4,
    ),

    // =================================================================
    // Asayiş
    // =================================================================
    CrimeType(
      id: 'sokak_kavgasi',
      label: 'Kavga',
      category: CrimeCategory.kavga,
      severity: CrimeSeverity.orta,
      recordLabel: 'Kavgaya karışma',
      courtChance: 0.45,
      fineMin: _wagePart(0.8),
      fineMax: _wagePart(3.0),
      familyShockPoints: 3,
    ),
    CrimeType(
      id: 'kamu_duzeni',
      label: 'Kamu düzenini bozma',
      category: CrimeCategory.kamuDuzeni,
      severity: CrimeSeverity.hafif,
      recordLabel: 'Kamu düzenini bozma',
      onSpotFine: _wagePart(0.35),
      courtChance: 0.12,
      fineMin: _wagePart(0.5),
      fineMax: _wagePart(1.4),
      familyShockPoints: 2,
    ),
    CrimeType(
      id: 'mala_zarar',
      label: 'Mala zarar verme',
      category: CrimeCategory.malaZarar,
      severity: CrimeSeverity.orta,
      recordLabel: 'Mala zarar verme',
      courtChance: 0.5,
      fineMin: _wagePart(0.9),
      fineMax: _wagePart(3.5),
      familyShockPoints: 3,
    ),
    CrimeType(
      id: 'kucuk_hirsizlik',
      label: 'Hırsızlık girişimi',
      category: CrimeCategory.hirsizlik,
      severity: CrimeSeverity.orta,
      recordLabel: 'Hırsızlık girişimi',
      courtChance: 0.65,
      fineMin: _wagePart(1.0),
      fineMax: _wagePart(3.0),
      prisonYearsMin: 1,
      prisonYearsMax: 1,
      familyShockPoints: 6,
    ),
    CrimeType(
      id: 'yaralama',
      label: 'Kavgada yaralama',
      category: CrimeCategory.yaralama,
      severity: CrimeSeverity.agir,
      recordLabel: 'Yaralama',
      courtChance: 0.85,
      fineMin: _wagePart(2.0),
      fineMax: _wagePart(6.0),
      prisonYearsMin: 1,
      prisonYearsMax: 3,
      familyShockPoints: 8,
    ),

    // =================================================================
    // İş ve para
    // =================================================================
    CrimeType(
      id: 'is_etigi',
      label: 'İş yerinde usulsüzlük',
      category: CrimeCategory.isEtigi,
      severity: CrimeSeverity.agir,
      recordLabel: 'İş yerinde usulsüzlük',
      courtChance: 0.8,
      fineMin: _wagePart(2.5),
      fineMax: _wagePart(8.0),
      prisonYearsMin: 1,
      prisonYearsMax: 2,
      familyShockPoints: 7,
    ),
    CrimeType(
      id: 'borc_davasi',
      label: 'Borç davası',
      category: CrimeCategory.borcAlacak,
      severity: CrimeSeverity.hafif,
      recordLabel: 'Borç davası',
      courtChance: 1.0,
      fineMin: _wagePart(0.6),
      fineMax: _wagePart(2.5),
      familyShockPoints: 1,
    ),
  ],
);

CrimeType? crimeTypeById(String id) {
  for (final CrimeType c in kCrimeCatalog) {
    if (c.id == id) return c;
  }
  return null;
}
