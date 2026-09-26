/// Piyasanın o yıldaki hâli (D-162).
library;

import 'package:flutter/foundation.dart';

/// Yıllık piyasa rejimi.
///
/// Her varlık kendi başına zar atmaz; yılın rejimi ortak etkenleri belirler
/// ve varlıklar o etkenlere kendi ağırlıklarıyla tepki verir.
enum MarketRegime {
  durgun('Durgun'),
  normal('Normal'),
  guclu('Güçlü'),
  kriz('Kriz');

  const MarketRegime(this.label);

  final String label;

  /// Oyuncuya gösterilebilecek kadar belirgin bir yıl mı?
  bool get isNotable => this == MarketRegime.kriz || this == MarketRegime.guclu;
}

/// Piyasanın kalıcı durumu.
///
/// **Kayda girer.** Böylece oyuncu ekranı kapatıp açarak fiyatı yeniden
/// çeviremez ve kayıt geri yüklenince aynı fiyatlar döner.
///
/// [priceIndex] her varlık türü için **baz puan** tutar: 10.000 = 1,00.
/// Tamsayı tutuluyor, çünkü kayıt tarafında kesir yuvarlama kaymasına
/// açıktır ve bu oyunda paranın doğrusu tamsayıdır.
@immutable
class MarketState {
  const MarketState({
    this.regime = MarketRegime.normal,
    this.inflationPressure = 50,
    this.confidence = 50,
    this.priceIndex = const <String, int>{},
    this.advancedAtAge,
    this.lastNoticeAge,
  });

  /// Baz puan ölçeği: 10.000 = 1,00.
  static const int basis = 10000;

  final MarketRegime regime;

  /// Gizli parametre (0-100): enflasyon baskısı.
  ///
  /// Oyuncuya sayı olarak gösterilmez; yalnızca varlıkların davranışını
  /// kaydırır.
  final int inflationPressure;

  /// Gizli parametre (0-100): piyasa güveni.
  final int confidence;

  /// Varlık kimliği -> fiyat endeksi (baz puan). Eksik anahtar 1,00 sayılır.
  final Map<String, int> priceIndex;

  /// Piyasanın **en son ilerletildiği** yaş.
  ///
  /// Yaş başına bir kez ilerler; aynı yıl içinde ekran açıp kapamak fiyatı
  /// değiştirmez.
  final int? advancedAtAge;

  /// En son piyasa bildirimi verilen yaş; her yıl pencere açılmaz.
  final int? lastNoticeAge;

  /// Bu varlığın endeksi (baz puan). Hiç işlem görmemişse 1,00.
  int indexOf(String typeId) => priceIndex[typeId] ?? basis;

  MarketState copyWith({
    MarketRegime? regime,
    int? inflationPressure,
    int? confidence,
    Map<String, int>? priceIndex,
    int? advancedAtAge,
    int? lastNoticeAge,
  }) =>
      MarketState(
        regime: regime ?? this.regime,
        inflationPressure:
            (inflationPressure ?? this.inflationPressure).clamp(0, 100),
        confidence: (confidence ?? this.confidence).clamp(0, 100),
        priceIndex: priceIndex ?? this.priceIndex,
        advancedAtAge: advancedAtAge ?? this.advancedAtAge,
        lastNoticeAge: lastNoticeAge ?? this.lastNoticeAge,
      );
}

/// Bir yılın varlık başına getirisi (oran: 0,12 = +%12).
@immutable
class MarketYear {
  const MarketYear({
    required this.regime,
    required this.returns,
  });

  final MarketRegime regime;

  /// Varlık kimliği -> o yılın getirisi.
  final Map<String, double> returns;

  /// Endeksle hareket eden varlıkların ortalama getirisi.
  double get average {
    if (returns.isEmpty) return 0;
    double toplam = 0;
    for (final double d in returns.values) {
      toplam += d;
    }
    return toplam / returns.length;
  }
}
