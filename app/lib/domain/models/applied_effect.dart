import 'package:flutter/foundation.dart';

/// Bir seçimin ardından **gerçekten uygulanmış** tek bir değişim.
///
/// Bu kayıtlar niyetten değil, durumun öncesi ile sonrası karşılaştırılarak
/// üretilir. Bu yüzden bir değer üst/alt sınıra dayandıysa ekranda olduğundan
/// fazla artış gösterilmez.
@immutable
class AppliedEffect {
  const AppliedEffect({required this.label, this.delta, this.unit = ''});

  /// "Mutluluk", "Deden Kemal ile yakınlık", "Bisiklet kazanıldı" gibi.
  final String label;

  /// Sayısal değişim. `null` ise sayısız bir kazanım/kayıptır.
  final int? delta;

  /// Sayının sonuna eklenecek birim (ör. ' ₺').
  final String unit;

  bool get isPositive => delta == null || delta! > 0;

  /// Ekranda gösterilecek tam metin.
  String get text {
    final int? d = delta;
    if (d == null) return label;
    return '$label ${d > 0 ? '+' : ''}$d$unit';
  }
}
