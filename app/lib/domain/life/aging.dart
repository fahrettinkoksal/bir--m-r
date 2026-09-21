import 'dart:math';

import '../generation/random_util.dart';

/// Yaşlanmanın dış görünüşe etkisi (D-051).
///
/// Kurallar:
/// - Bebeklikten ve çocukluktan itibaren **her yıl otomatik ceza yoktur**;
///   etki yetişkinlikte başlar.
/// - Etki **kademeli, hafif ve değişkendir**: her karakter aynı yaşta aynı
///   görünüşe düşmez.
/// - Sağlık ve bakım koşulları etkiyi değiştirebilir; sağlığı iyi olan
///   daha yavaş yıpranır.
/// - Yaşlanma tek başına mutluluğu veya zekâyı düşürmez.
/// - Değer 0-100 sınırında kalır ve belirli bir tabanın altına inmez;
///   görünüşün düşmesi yalnızca **karakterin yaşlandığı** anlamına gelir.
///
/// Bütün yaş aralıkları ve miktarlar `prototypeOnly`'dir (Q-075).
abstract final class Aging {
  /// prototypeOnly: etkinin başladığı yaş. Öncesinde hiç düşüş olmaz.
  static const int prototypeOnlyStartAge = 30;

  /// prototypeOnly: görünüşün inebileceği taban.
  ///
  /// Yaşlanma karakteri sıfıra indirmez; bu bir yargı değil, ölçek
  /// tabanıdır.
  static const int prototypeOnlyFloor = 15;

  /// prototypeOnly: yaş aralığına göre **yıllık düşüş olasılığı**.
  static double prototypeOnlyChance(int age) {
    if (age < prototypeOnlyStartAge) return 0;
    if (age < 45) return 0.25;
    if (age < 60) return 0.45;
    if (age < 75) return 0.6;
    return 0.7;
  }

  /// prototypeOnly: düşüşün iki puan olma olasılığı (ileri yaşta).
  static double prototypeOnlyDoubleChance(int age) {
    if (age < 60) return 0;
    if (age < 75) return 0.2;
    return 0.35;
  }

  /// Bu yılın görünüş değişimi (0 veya negatif).
  ///
  /// Sağlığı yüksek karakter daha yavaş yıpranır; sağlığı düşük olan
  /// biraz daha hızlı. Sonuç her yıl aynı değildir.
  static int yearlyDelta({
    required int age,
    required int appearance,
    required int health,
    required Random rng,
  }) {
    if (age < prototypeOnlyStartAge) return 0;
    if (appearance <= prototypeOnlyFloor) return 0;

    // Sağlık 50 nötrdür: yüksek sağlık ihtimali azaltır, düşük artırır.
    final double saglikEtkisi = ((50 - health) / 100) * 0.3;
    final double sans =
        (prototypeOnlyChance(age) + saglikEtkisi).clamp(0.0, 0.9);
    if (!rng.chance(sans)) return 0;

    final int dusus = rng.chance(prototypeOnlyDoubleChance(age)) ? 2 : 1;
    final int yeni = (appearance - dusus).clamp(prototypeOnlyFloor, 100);
    return yeni - appearance;
  }

  /// Belirgin bir yıpranma bu yıl yaşandı mı? (Günlüğe yazmak için.)
  ///
  /// Her yıl günlüğe satır yazılmaz; yalnızca iki puanlık düşüşlerde
  /// kısa bir satır çıkar ve satır **gerçekten uygulanan** değişimi
  /// anlatır.
  static bool worthLogging(int delta) => delta <= -2;
}
