import 'package:flutter/foundation.dart';

import '../features/feature_catalog.dart';

/// Oyuncunun görünüm seçimi (Paket BQ).
///
/// Oyunda koyu tema baştan beri **vardı** (`BirOmurTheme.dark()`) ama
/// oyuncu seçemiyordu: uygulamanın kökü `ThemeMode.system` ile sabitti,
/// yani telefonun ayarı neyse o. Bu enum seçimi kayda taşır.
///
/// Flutter'ın `ThemeMode`'u burada kullanılmaz: kayıt biçimi arayüz
/// kütüphanesine bağlanmaz, eşleme arayüz katmanında yapılır.
enum AppThemeChoice {
  sistem('Cihaza göre', 'sistem'),
  acik('Açık', 'acik'),
  koyu('Koyu', 'koyu');

  const AppThemeChoice(this.label, this.saveKey);

  /// Ayarlar ekranında görünen ad.
  final String label;

  /// Kayıttaki anahtar. Yeni değer eklenirse eski kayıtlar bozulmasın
  /// diye tanınmayan anahtar [sistem] sayılır.
  final String saveKey;

  static AppThemeChoice byKey(Object? key) {
    for (final AppThemeChoice secim in values) {
      if (secim.saveKey == key) return secim;
    }
    return sistem;
  }
}

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
    this.themeChoice = AppThemeChoice.sistem,
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

  /// Açık/koyu/sistem seçimi (Paket BQ). Varsayılan cihazın ayarıdır.
  final AppThemeChoice themeChoice;

  GameSettings copyWith({
    bool? casinoEnabled,
    Object? wagerLimitPerAge = _unset,
    bool? soundEnabled,
    FeatureSwitches? features,
    AppThemeChoice? themeChoice,
  }) =>
      GameSettings(
        casinoEnabled: casinoEnabled ?? this.casinoEnabled,
        soundEnabled: soundEnabled ?? this.soundEnabled,
        features: features ?? this.features,
        themeChoice: themeChoice ?? this.themeChoice,
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
