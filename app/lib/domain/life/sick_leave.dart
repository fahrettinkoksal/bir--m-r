/// Hastalık ve işe gidememe (D-078).
///
/// **Neden var:** Faho istedi — "oyunda hasta olayım, 3-5 gün işe
/// gidemeyeyim, işverenim sorun etsin". Sağlık yalnızca büyük krizlerde
/// (D-044) ya da sessiz bir sayı olarak vardı; gündelik hastalığın
/// hayatta bir karşılığı yoktu.
///
/// Kurallar:
/// - Hastalık **sağlığa bağlıdır**: sağlığı iyi olan daha seyrek yatar,
///   düzenli spor yapan daha az hasta olur, yaşlı karakter daha sık.
/// - Çalışan karakter **gelir kaybeder**. Türkiye'de geçici iş göremezlik
///   ödeneği raporun ilk iki günü için ödenmez; oyun bu ayrıntıyı
///   basitleştirir ve **ilk iki günü** kayıp sayar, kalanını saymaz.
/// - **İşveren her hastalığı sorun etmez.** Kısa rapor geçer; uzun ya da
///   üst üste gelen rapor uyarıya dönüşür ve uyarılar işten çıkarılma
///   ihtimalini artırır. Uyarı **tek başına** kimseyi işten atmaz.
/// - Çalışmayan karakter de hasta olur; sadece gelir kaybı olmaz.
///
/// **Tıbbi bir model değildir.** Süreler ve ihtimaller oyun dengesi
/// içindir (Q-119).
library;

import 'dart:math';

import '../generation/random_util.dart';
import 'aging.dart';

/// Bir yılın hastalık sonucu.
class SickLeave {
  const SickLeave({
    required this.days,
    required this.wageLoss,
    required this.happinessDelta,
    required this.employerUpset,
    required this.text,
  });

  /// İşe/okula gidilemeyen gün sayısı; hastalık yoksa 0.
  final int days;

  /// Gelirden düşen tutar (₺).
  final int wageLoss;

  /// Mutluluğa uygulanacak değişim (negatif ya da 0).
  final int happinessDelta;

  /// İşveren bu sefer sorun etti mi?
  final bool employerUpset;

  final String text;

  bool get happened => days > 0;

  static const SickLeave none = SickLeave(
    days: 0,
    wageLoss: 0,
    happinessDelta: 0,
    employerUpset: false,
    text: '',
  );
}

abstract final class SickLeaves {
  /// prototypeOnly: en kısa ve en uzun rapor.
  static const int prototypeOnlyMinDays = 3;
  static const int prototypeOnlyMaxDays = 7;

  /// prototypeOnly: işverenin sorun etmeye başladığı gün sayısı.
  static const int prototypeOnlyUpsetDays = 6;

  /// prototypeOnly: ödenmeyen ilk gün sayısı.
  ///
  /// Gerçekte geçici iş göremezlik ödeneği raporun ilk iki günü için
  /// ödenmez; oyun bunu böyle basitleştirir.
  static const int prototypeOnlyUnpaidDays = 2;

  /// prototypeOnly: uyarının işten çıkarılma ihtimaline kattığı pay.
  static const double prototypeOnlyWarningLayoffBonus = 0.04;

  /// prototypeOnly: uyarıların toplayabileceği en yüksek pay.
  static const double prototypeOnlyMaxWarningBonus = 0.16;

  /// Hastalığın işletilmeye başladığı yaş.
  ///
  /// Küçük çocuk elbette hasta olur; ama oyunda bunun bir karşılığı
  /// yok: işe ya da okula gidemediği bir program henüz yok, geliri yok.
  /// Karşılığı olmayan bir olay her yıl günlüğe girmesin diye kapı okul
  /// çağında açılır.
  static const int prototypeOnlyMinAge = 6;

  /// Bu yıl hasta olma ihtimali.
  static double chance({
    required int age,
    required int health,
    required int? yearsSinceSport,
  }) {
    double taban;
    if (health >= 80) {
      taban = 0.12;
    } else if (health >= 60) {
      taban = 0.20;
    } else if (health >= 40) {
      taban = 0.30;
    } else {
      taban = 0.42;
    }

    // Spor koruyor; hareketsizlik yormuyor ama direnci düşürüyor.
    if (yearsSinceSport != null &&
        yearsSinceSport <= StatAging.prototypeOnlyFreshYears) {
      taban *= 0.75;
    } else if (yearsSinceSport == null ||
        yearsSinceSport >= StatAging.prototypeOnlyNeglectYears) {
      taban *= 1.2;
    }

    if (age >= 65) taban *= 1.25;
    if (age < 12) taban *= 1.2; // Okul çağı çocuğu daha sık hasta olur.

    return taban.clamp(0.0, 0.7);
  }

  /// Bir yılı işletir.
  ///
  /// [yearlySalary] çalışmıyorsa `null` verilir; o zaman gelir kaybı
  /// hesaplanmaz.
  static SickLeave roll({
    required int age,
    required int health,
    required int? yearsSinceSport,
    required int? yearlySalary,
    required int previousWarnings,
    required Random rng,
    bool isStudent = false,
  }) {
    if (age < prototypeOnlyMinAge) return SickLeave.none;
    if (!rng.chance(
      chance(age: age, health: health, yearsSinceSport: yearsSinceSport),
    )) {
      return SickLeave.none;
    }

    final int gun = prototypeOnlyMinDays +
        rng.nextInt(prototypeOnlyMaxDays - prototypeOnlyMinDays + 1);

    final int odenmeyen =
        gun < prototypeOnlyUnpaidDays ? gun : prototypeOnlyUnpaidDays;
    final int kayip = yearlySalary == null
        ? 0
        : (yearlySalary * odenmeyen / 365).round();

    // İşveren uzun rapora ya da üst üste gelen rapora tepki verir.
    final bool kizdi = yearlySalary != null &&
        (gun >= prototypeOnlyUpsetDays || previousWarnings > 0);

    final String metin = <String>[
      _hastalikCumlesi(
        gun: gun,
        calisiyor: yearlySalary != null,
        ogrenci: isStudent,
      ),
      if (kayip > 0) 'Raporun ilk iki günü ödenmedi.',
      if (kizdi)
        'İşverenin bu kez memnun olmadığını belli etti.'
      else if (yearlySalary != null)
        'İş yerinde sorun çıkmadı.',
    ].join(' ');

    return SickLeave(
      days: gun,
      wageLoss: kayip,
      happinessDelta: gun >= prototypeOnlyUpsetDays ? -4 : -2,
      employerUpset: kizdi,
      text: metin,
    );
  }

  /// Uyarıların işten çıkarılma ihtimaline kattığı pay.
  static double layoffBonus(int warnings) =>
      (warnings * prototypeOnlyWarningLayoffBonus)
          .clamp(0.0, prototypeOnlyMaxWarningBonus);

  /// Hastalık cümlesi **gerçek duruma** göre kurulur.
  ///
  /// Çalışmayan birine "işe gidemedin", okula gitmeyen birine "okula
  /// gidemedin" yazılmaz.
  static String _hastalikCumlesi({
    required int gun,
    required bool calisiyor,
    required bool ogrenci,
  }) {
    final String nere = calisiyor
        ? 'işe gidemedin'
        : ogrenci
            ? 'okula gidemedin'
            : 'evden çıkamadın';
    if (gun >= prototypeOnlyUpsetDays) {
      return '$gun gün yatakta kaldın; $nere.';
    }
    return '$gun gün hasta yattın; $nere.';
  }
}
