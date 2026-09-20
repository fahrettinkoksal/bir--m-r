import 'package:flutter/foundation.dart';

/// Oyuncunun kendi ayarları.
///
/// Kumarhane **isteğe bağlı bir modüldür** ve buradan tamamen kapatılabilir
/// (D-032). Kapalıyken menüde hiç görünmez; sahte düğme bırakılmaz.
@immutable
class GameSettings {
  const GameSettings({
    this.casinoEnabled = true,
    this.wagerLimitPerAge,
  });

  /// Kumarhane modülü açık mı?
  final bool casinoEnabled;

  /// Oyuncunun kendisi için belirlediği **isteğe bağlı** yıllık bahis
  /// limiti. `null` ise yalnızca oyunun geçici üst sınırı geçerlidir.
  final int? wagerLimitPerAge;

  GameSettings copyWith({
    bool? casinoEnabled,
    Object? wagerLimitPerAge = _unset,
  }) =>
      GameSettings(
        casinoEnabled: casinoEnabled ?? this.casinoEnabled,
        wagerLimitPerAge: wagerLimitPerAge == _unset
            ? this.wagerLimitPerAge
            : wagerLimitPerAge as int?,
      );
}

const Object _unset = Object();

/// Oyuncunun bakım durumu (D-037).
///
/// Çocuk yaşta hanede yetişkin kalmadığında oyuncu açıklamasız
/// bırakılmaz; durum burada saklanır ve ekranda görünür. Ayrıntılı
/// velayet sistemi sonraki paketlerde genişletilecek.
enum CareStatus {
  aileYaninda('Ailesinin yanında'),
  yakinAkraba('Yakın akrabasının yanında'),
  kurumBakimi('Kurum bakımında');

  const CareStatus(this.label);

  final String label;
}
