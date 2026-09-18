import 'dart:math';

/// Küçük rastgelelik yardımcıları.
///
/// Rastgelelik bütün ihtimallerin eşit ağırlıkta olduğu anlamına gelmez
/// (`SYSTEMS.md`); ağırlıklar prototip içindir, onaylanmış denge değildir.
extension RandomHelpers on Random {
  /// [min] ve [max] dahil aralıktan tam sayı.
  int between(int min, int max) {
    if (max <= min) return min;
    return min + nextInt(max - min + 1);
  }

  T pick<T>(List<T> items) => items[nextInt(items.length)];

  bool chance(double probability) => nextDouble() < probability;

  /// Ağırlıklı seçim. [weights] uzunluğu [items] ile aynı olmalıdır.
  T pickWeighted<T>(List<T> items, List<double> weights) {
    assert(items.length == weights.length, 'Ağırlık sayısı seçenek sayısına eşit olmalı.');
    double total = 0;
    for (final double w in weights) {
      total += w;
    }
    double roll = nextDouble() * total;
    for (int i = 0; i < items.length; i++) {
      roll -= weights[i];
      if (roll <= 0) return items[i];
    }
    return items.last;
  }
}
