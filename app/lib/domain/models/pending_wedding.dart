/// Teklifi kabul edilmiş ama düğünü henüz yapılmamış evlilik (Paket 25).
library;

import 'package:flutter/foundation.dart';

import '../../data/wedding_catalog.dart';

/// "Evet" alındı; sıra düğünde.
///
/// Bu durum **kayda girer**: oyuncu uygulamayı kapatıp açsa da teklifi
/// kabul edilmiş sevgilisiyle düğün seçimine kaldığı yerden devam eder.
/// Yarıda kalan bir "evet" kaybolmaz.
@immutable
class PendingWedding {
  const PendingWedding({
    required this.spouseId,
    required this.acceptedAtAge,
  });

  /// "Evet" diyen kişinin kalıcı kimliği.
  final String spouseId;

  /// Teklifin kabul edildiği yaş.
  final int acceptedAtAge;

  /// Bu cüzdanla seçilebilecek düğünler.
  ///
  /// Bedelsiz seçenek her zaman listede olduğu için liste **hiçbir zaman
  /// boş kalmaz**.
  static List<WeddingStyle> affordable(int wallet) => kWeddingStyles
      .where((WeddingStyle s) => s.prototypeOnlyCost <= wallet)
      .toList(growable: false);
}
