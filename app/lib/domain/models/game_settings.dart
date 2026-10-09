import 'package:flutter/foundation.dart';

import '../features/feature_catalog.dart';

/// Oyuncunun kendi ayarları.
///
/// Kumarhane **isteğe bağlı bir modüldür** ve buradan tamamen kapatılabilir
/// (D-032). Kapalıyken menüde hiç görünmez; sahte düğme bırakılmaz.
@immutable
class GameSettings {
  const GameSettings({
    this.casinoEnabled = true,
    this.wagerLimitPerAge,
    this.soundEnabled = true,
    this.features = FeatureSwitches.defaults,
  });

  /// Kumarhane modülü açık mı?
  final bool casinoEnabled;

  /// Ses efektleri açık mı? (Paket 15)
  ///
  /// Kapatıldığında oyun tamamen sessiz çalışır; ayar kayıtla birlikte
  /// saklanır.
  final bool soundEnabled;

  /// Oyuncunun kendisi için belirlediği **isteğe bağlı** yıllık bahis
  /// limiti. `null` ise yalnızca oyunun geçici üst sınırı geçerlidir.
  final int? wagerLimitPerAge;

  /// Çıkarılabilir özellik anahtarları (Paket BL).
  ///
  /// Kumarhane anahtarı (D-032) bu katalogdan **önce** vardı ve kendi
  /// alanında kalır; yeni özelliklerin hepsi buradan açılıp kapanır.
  final FeatureSwitches features;

  GameSettings copyWith({
    bool? casinoEnabled,
    Object? wagerLimitPerAge = _unset,
    bool? soundEnabled,
    FeatureSwitches? features,
  }) =>
      GameSettings(
        casinoEnabled: casinoEnabled ?? this.casinoEnabled,
        soundEnabled: soundEnabled ?? this.soundEnabled,
        features: features ?? this.features,
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
