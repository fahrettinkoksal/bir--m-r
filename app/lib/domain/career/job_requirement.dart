// İş ilanında gösterilen tek bir gereksinim satırı (Paket AM, §18).
//
// Oyuncu bir işe neden giremediğini tahmin etmek zorunda kalmasın:
// hangi şart tutuyor, hangisi tutmuyor ve eksik ne kadar — hepsi
// ekranda. Yüzde ya da formül gösterilmez, yalnızca eşik ve mevcut
// değer.
library;

import 'package:flutter/foundation.dart';

@immutable
class JobRequirement {
  const JobRequirement({
    required this.label,
    required this.need,
    required this.have,
    required this.met,
  });

  /// "Dış görünüş", "Sağlık" gibi okunur ad.
  final String label;

  /// "en az 80" gibi eşik metni.
  final String need;

  /// Oyuncunun şu andaki değeri.
  final String have;

  /// Şart sağlanıyor mu?
  final bool met;

  /// Ekranda tek satır: sağlanan şartta yalnızca ad, sağlanmayanda
  /// eksiğin ne olduğu yazılır.
  String get line => met ? label : '$label: $need (sende $have)';
}
