import 'package:flutter/foundation.dart';

/// Evlilik kaydının durumu.
///
/// Kayıt **silinmez**: boşanma veya eşin vefatı durumu değiştirir, kaydı
/// ortadan kaldırmaz. Miras kuralı (D-037) "gerçek birliktelik kaydı"
/// ararken buraya bakar.
enum MarriageStatus {
  evli('Evli'),
  bosandi('Boşandı'),
  dul('Eşini kaybetti');

  const MarriageStatus(this.label);

  final String label;
}

/// Oyuncunun evlilik kaydı.
///
/// Eşin kendisi kişi listesinde **kalıcı kimliğiyle** durur; burada yalnızca
/// birlikteliğin kaydı tutulur. Böylece eş vefat etse veya boşanılsa bile
/// "kiminle, kaç yaşında evlenildi" bilgisi kaybolmaz.
@immutable
class Marriage {
  const Marriage({
    required this.spouseId,
    required this.marriedAtAge,
    required this.status,
    this.endedAtAge,
  });

  /// Eşin kişi kimliği. Kişi kaydı listede durur.
  final String spouseId;

  /// Oyuncunun evlendiği yaş.
  final int marriedAtAge;

  final MarriageStatus status;

  /// Birlikteliğin bittiği yaş (boşanma veya vefat); sürüyorsa `null`.
  final int? endedAtAge;

  /// Şu anda yürüyen bir evlilik mi?
  bool get isActive => status == MarriageStatus.evli;

  Marriage copyWith({
    MarriageStatus? status,
    int? endedAtAge,
  }) =>
      Marriage(
        spouseId: spouseId,
        marriedAtAge: marriedAtAge,
        status: status ?? this.status,
        endedAtAge: endedAtAge ?? this.endedAtAge,
      );
}
