/// Burçlar (Paket 27).
///
/// **Doğum yılı yoktur (D-003).** Burç yalnızca doğum **ayı ve gününden**
/// hesaplanır; oyunda tarihsel bir takvim, dönem motoru ya da doğum yılı
/// seçimi hâlâ yok. Ay ve gün hayat üretilirken bir kez belirlenir ve
/// kayda girer.
library;

import 'package:flutter/foundation.dart';

/// On iki burç.
///
/// Tarih aralıkları yaygın kullanılan sınırlardır; kesin bir astroloji
/// iddiası değildir (`prototypeOnly`, Q-095).
enum Zodiac {
  koc('Koç', '♈', 3, 21, 4, 19, 'ateş'),
  boga('Boğa', '♉', 4, 20, 5, 20, 'toprak'),
  ikizler('İkizler', '♊', 5, 21, 6, 21, 'hava'),
  yengec('Yengeç', '♋', 6, 22, 7, 22, 'su'),
  aslan('Aslan', '♌', 7, 23, 8, 22, 'ateş'),
  basak('Başak', '♍', 8, 23, 9, 22, 'toprak'),
  terazi('Terazi', '♎', 9, 23, 10, 22, 'hava'),
  akrep('Akrep', '♏', 10, 23, 11, 21, 'su'),
  yay('Yay', '♐', 11, 22, 12, 21, 'ateş'),
  oglak('Oğlak', '♑', 12, 22, 1, 19, 'toprak'),
  kova('Kova', '♒', 1, 20, 2, 18, 'hava'),
  balik('Balık', '♓', 2, 19, 3, 20, 'su');

  const Zodiac(
    this.label,
    this.symbol,
    this.startMonth,
    this.startDay,
    this.endMonth,
    this.endDay,
    this.element,
  );

  final String label;

  /// Burç simgesi (♈ gibi).
  ///
  /// **Ekranda gösterilmiyor:** oyunun yazı tipleri (Baloo 2 ve Patrick
  /// Hand) U+2648-2653 aralığını içermiyor, simge boş kutu olarak
  /// çiziliyordu. Veri olarak duruyor; simgeleri olan bir yazı tipi
  /// eklenirse `display` buna dönebilir (Q-095).
  final String symbol;

  final int startMonth;
  final int startDay;
  final int endMonth;
  final int endDay;

  /// Element: ateş, toprak, hava, su.
  final String element;

  /// Ekranda gösterilecek ad.
  ///
  /// Simge **bilerek** yok; bkz. [symbol].
  String get display => label;

  /// Bu burcun tarih aralığı: "21 Mart – 19 Nisan".
  String get range => '$startDay ${_ayAdi(startMonth)} – '
      '$endDay ${_ayAdi(endMonth)}';
}

const List<String> _aylar = <String>[
  'Ocak',
  'Şubat',
  'Mart',
  'Nisan',
  'Mayıs',
  'Haziran',
  'Temmuz',
  'Ağustos',
  'Eylül',
  'Ekim',
  'Kasım',
  'Aralık',
];

String _ayAdi(int month) => _aylar[(month - 1).clamp(0, 11)];

/// Doğum ayı ve günü. **Yıl yoktur** (D-003).
@immutable
class BirthDate {
  const BirthDate({required this.month, required this.day});

  final int month;
  final int day;

  /// Bu tarihin burcu.
  Zodiac get zodiac => zodiacFor(month, day);

  /// "14 Nisan" biçiminde.
  String get label => '$day ${_ayAdi(month)}';

  /// Bu ayda kaç gün var? (Şubat **her zaman 28**: yıl olmadığı için
  /// artık yıl diye bir şey de yok.)
  static int daysInMonth(int month) {
    switch (month) {
      case 2:
        return 28;
      case 4:
      case 6:
      case 9:
      case 11:
        return 30;
      default:
        return 31;
    }
  }
}

/// Ay ve güne göre burç.
Zodiac zodiacFor(int month, int day) {
  for (final Zodiac z in Zodiac.values) {
    if (z.startMonth == z.endMonth) continue;
    // Yıl sınırını aşan tek burç Oğlak.
    if (z.startMonth > z.endMonth) {
      if ((month == z.startMonth && day >= z.startDay) ||
          (month == z.endMonth && day <= z.endDay)) {
        return z;
      }
      continue;
    }
    if ((month == z.startMonth && day >= z.startDay) ||
        (month == z.endMonth && day <= z.endDay)) {
      return z;
    }
  }
  // Buraya düşülmemeli; düşülürse en yakın makul burç döner.
  return Zodiac.oglak;
}
