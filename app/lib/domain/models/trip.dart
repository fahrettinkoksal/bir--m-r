import 'package:flutter/foundation.dart';

/// Yolculuk türü.
///
/// Ücretler `prototypeOnly`'dir (Q-080). Kendi aracıyla gitmek yalnızca
/// **gerçekten araba sahibi olan, ehliyeti olan ve aracı yola çıkacak
/// durumda olan** oyuncuya açılır; sahte düğme gösterilmez.
enum TravelMode {
  otobus('Otobüs', 'Uzun ama ucuz; camdan şehirler geçer.', 2200),
  tren('Tren', 'Sarsıntısız, biraz daha pahalı.', 3400),
  ucak('Uçak', 'En hızlısı, en pahalısı.', 7800),
  kendiArabasi('Kendi arabanla', 'Yakıt ve yol; araç yıpranır.', 3000);

  const TravelMode(this.label, this.description, this.prototypeOnlyCost);

  final String label;
  final String description;

  /// prototypeOnly: tek kişilik gidiş-dönüş ücreti (₺).
  final int prototypeOnlyCost;
}

/// Yapılmış bir gezinin kalıcı kaydı.
///
/// Gezi **kalıcı taşınmadan ayrıdır**: oyuncunun yaşadığı veya doğduğu
/// şehri değiştirmez.
@immutable
class TripRecord {
  const TripRecord({
    required this.id,
    required this.city,
    required this.age,
    required this.mode,
    required this.cost,
    this.companionId,
    this.note,
  });

  /// Tekil kimlik; aynı gezi iki kez ücretlendirilmesin diye kullanılır.
  final String id;

  /// Gidilen şehir.
  final String city;

  /// Gidildiği yaş.
  final int age;

  final TravelMode mode;

  /// Cüzdandan gerçekten düşen tutar (₺).
  final int cost;

  /// Birlikte gidilen kişinin kalıcı kimliği; yalnız gidildiyse `null`.
  final String? companionId;

  /// Gezide yaşanan önemli an; yoksa `null`.
  final String? note;

  bool get alone => companionId == null;
}
