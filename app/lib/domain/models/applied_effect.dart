import 'package:flutter/foundation.dart';

import '../../text/turkish_text.dart';

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
  ///
  /// **Ölçülmüş hata — para değişimi binlik ayraçsız yazılıyordu.**
  /// Sayı `'$d'` diye ham basılıyordu. Stat değişimlerinde (+5) sorun
  /// yok ama birimi ` ₺` olan kayıtlarda oyuncu şunu görüyordu:
  ///
  ///     34 yaşın böyle geçti
  ///     Mutluluk +5 · Karizma +4 · Cüzdan -988619 ₺
  ///
  /// Oyunun geri kalanı aynı tutarı "988.619 ₺" diye yazıyor; yedi
  /// haneli bir sayının ayraçsız hâli tek blok olarak okunmuyor —
  /// `trNumber`in kendi açıklaması da bu yüzden yazılmış. İki yerde
  /// görünüyordu: yıl özeti (`year_review.dart`) ve olay sonucu
  /// penceresi (`effect_diff.dart`), yani **parası değişen her olay**.
  /// Bot dökümünde 35 yaşındaki oyuncunun ekranında yakalandı.
  ///
  /// `trNumber` eksiyi doğru yazıyor (-988619 → "-988.619"), bu yüzden
  /// işareti ayrıca eklemek gerekmiyor; yalnızca artı işareti elle
  /// konur. Gerileme testi: `paket_be_para_bicimi_test.dart`.
  String get text {
    final int? d = delta;
    if (d == null) return label;
    final String sayi = d > 0 ? '+${trNumber(d)}' : trNumber(d);
    return '$label $sayi$unit';
  }
}
