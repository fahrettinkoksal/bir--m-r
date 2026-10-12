/// Kronik sağlık durumları (D-153).
///
/// **Neden var:** Sağlık tek bir sayıydı ve krizler birbirinden
/// bağımsızdı. Aynı krizi üçüncü kez yaşayan oyuncuda hiçbir iz kalmıyor,
/// "hayatım boyunca şu rahatsızlıkla yaşadım" diye bir anlatı
/// kurulamıyordu.
///
/// **Yeni bir sağlık sistemi değildir.** Mevcut `HealthCrisisEngine` ve
/// Sağlık Merkezi eylemleri aynen duruyor; bu katman yalnızca atlatılan
/// krizin **kalıcı bir kayıt** bırakmasını ve o kaydın sonraki yılları
/// etkilemesini sağlar.
///
/// **Tıbbi bilgi değildir.** Adlar günlük Türkçedir, teşhis ya da tedavi
/// tarifi içermez; hiçbir metin ilaç adı, doz ya da uygulama anlatmaz.
/// Oyunun yaptığı tek şey "bu rahatsızlık var, takip edilmezse sağlık
/// düşer" demektir.
///
/// Bütün sayılar `prototypeOnly`'dir (Q-156).
library;

import 'package:flutter/foundation.dart';

/// Kronik bir durumun nasıl başladığı.
enum ChronicOrigin {
  /// Atlatılan bir krizin ardından kaldı.
  krizSonrasi('Kriz sonrası'),

  /// Yaşla birlikte ortaya çıktı.
  yasla('Yaşla birlikte');

  const ChronicOrigin(this.label);

  final String label;
}

/// Kronik bir sağlık durumunun türü.
@immutable
class ChronicConditionType {
  const ChronicConditionType({
    required this.id,
    required this.label,
    required this.description,
    required this.origin,
    required this.yearlyHealthDrain,
    required this.yearlyCareCost,
    required this.crisisRiskFactor,
    required this.reportSystem,
    this.afterCrisisIds = const <String>{},
    this.onsetMinAge = 0,
    this.managedDrain = 0,
  });

  final String id;

  /// Ekranda görünen ad. Günlük Türkçe; teşhis değil.
  final String label;

  /// Oyuncuya ne anlattığı. Tavsiye vermez, durum anlatır.
  final String description;

  final ChronicOrigin origin;

  /// prototypeOnly: takip edilmezse her yıl sağlıktan düşen puan.
  final int yearlyHealthDrain;

  /// prototypeOnly: takip edildiyse (o yıl bakım ödendiyse) düşen puan.
  ///
  /// Sıfır değildir: takip rahatsızlığı **yönetir**, ortadan kaldırmaz.
  final int managedDrain;

  /// prototypeOnly: bir yıllık takibin bedeli (₺, 2026 ölçeği).
  final int yearlyCareCost;

  /// prototypeOnly: yıllık kriz ihtimalinin çarpanı.
  final double crisisRiskFactor;

  /// Check-up raporunda hangi satırı aşağı çektiği.
  ///
  /// `health_report.dart` içindeki sistem adıyla **birebir** aynı olmalı;
  /// kalıcı bir test bunu denetler. Böylece kalp rahatsızlığı taşıyan
  /// oyuncunun kontrolünde kalp satırı gerçekten düşük çıkar.
  final String reportSystem;

  /// Bu durumu bırakabilecek krizlerin kimlikleri.
  ///
  /// Boşsa kriz sonrası kalmaz; yalnızca yaşla gelir.
  final Set<String> afterCrisisIds;

  /// prototypeOnly: yaşla gelen durumun en erken çıkabileceği yaş.
  final int onsetMinAge;
}

/// Oyundaki kronik durumlar.
///
/// Liste bilerek kısadır: her biri **mevcut bir krizle** ya da **yaşla**
/// bağlantılıdır, süs olarak eklenmiş durum yoktur.
const List<ChronicConditionType> kChronicConditions = <ChronicConditionType>[
  ChronicConditionType(
    id: 'kalp_takibi',
    label: 'Kalp rahatsızlığı',
    description:
        'Kalbin düzenli takip istiyor. Yorulunca kendini daha çabuk '
        'belli ediyor.',
    origin: ChronicOrigin.krizSonrasi,
    afterCrisisIds: <String>{'kalp_uyarisi'},
    yearlyHealthDrain: 3,
    managedDrain: 1,
    yearlyCareCost: 24000, // prototypeOnly
    crisisRiskFactor: 1.6,
    reportSystem: 'Kalp ve tansiyon',
  ),
  ChronicConditionType(
    id: 'solunum',
    label: 'Solunum rahatsızlığı',
    description:
        'Ciğerlerin eski hâlinde değil. Soğuk havada ve merdivende '
        'fark ediyorsun.',
    origin: ChronicOrigin.krizSonrasi,
    afterCrisisIds: <String>{'zatürre'},
    yearlyHealthDrain: 2,
    managedDrain: 1,
    yearlyCareCost: 16000, // prototypeOnly
    crisisRiskFactor: 1.4,
    reportSystem: 'Akciğerler',
  ),
  ChronicConditionType(
    id: 'bel_agrisi',
    label: 'Süregelen bel ağrısı',
    description:
        'Kazadan sonra geçmedi. Uzun oturmak ve ağır kaldırmak '
        'zorlaşıyor.',
    origin: ChronicOrigin.krizSonrasi,
    afterCrisisIds: <String>{'trafik_kazasi', 'is_kazasi'},
    yearlyHealthDrain: 2,
    managedDrain: 0,
    yearlyCareCost: 12000, // prototypeOnly
    crisisRiskFactor: 1.1,
    reportSystem: 'Kemik ve eklemler',
  ),
  ChronicConditionType(
    id: 'eklem',
    label: 'Eklem rahatsızlığı',
    description:
        'Düşmeden sonra kalça ve dizler eskisi gibi değil. Havaya göre '
        'değişiyor.',
    origin: ChronicOrigin.krizSonrasi,
    afterCrisisIds: <String>{'dusme'},
    yearlyHealthDrain: 2,
    managedDrain: 1,
    yearlyCareCost: 14000, // prototypeOnly
    crisisRiskFactor: 1.2,
    reportSystem: 'Kemik ve eklemler',
  ),
  ChronicConditionType(
    id: 'tansiyon',
    label: 'Yüksek tansiyon',
    description:
        'Ölçüm yüksek çıkıyor. Kendini belli etmiyor; takip ettiğin '
        'sürece hayatın değişmiyor.',
    origin: ChronicOrigin.yasla,
    onsetMinAge: 42,
    yearlyHealthDrain: 2,
    managedDrain: 0,
    yearlyCareCost: 9000, // prototypeOnly
    crisisRiskFactor: 1.5,
    reportSystem: 'Kalp ve tansiyon',
  ),
  ChronicConditionType(
    id: 'kan_sekeri',
    label: 'Kan şekeri düzensizliği',
    description:
        'Tahlilde çıktı. Düzen istiyor: takipsiz kaldığında yıllar '
        'içinde birikiyor.',
    origin: ChronicOrigin.yasla,
    onsetMinAge: 38,
    yearlyHealthDrain: 3,
    managedDrain: 1,
    yearlyCareCost: 18000, // prototypeOnly
    crisisRiskFactor: 1.5,
    reportSystem: 'Kan değerleri',
  ),
];

ChronicConditionType? chronicTypeById(String id) {
  for (final ChronicConditionType t in kChronicConditions) {
    if (t.id == id) return t;
  }
  return null;
}

/// Bu krizin ardından kalabilecek durumlar.
List<ChronicConditionType> chronicAfterCrisis(String crisisId) =>
    kChronicConditions
        .where((ChronicConditionType t) => t.afterCrisisIds.contains(crisisId))
        .toList(growable: false);

/// Yaşla gelebilecek durumlar.
List<ChronicConditionType> chronicByAge(int age) => kChronicConditions
    .where((ChronicConditionType t) =>
        t.origin == ChronicOrigin.yasla && age >= t.onsetMinAge)
    .toList(growable: false);
