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

  /// Kayıtta **kullanılmayan** bir ad seçer; hepsi kullanılıyorsa
  /// rastgele döner.
  ///
  /// **Paket BV'de ölçüldü.** Kişi üreten yerlerin çoğu (`in_laws`,
  /// `step_siblings`, `step_parents`, `school_people`) aynı adı
  /// yakalayıp otuz kez yeniden çekiyordu; **çocuğun eşi** ve **torun**
  /// bunu yapmıyordu. 300 hayatta çocuğu olan hayatların %12-15'inde
  /// çocuğun adı hanedeki yaşayan biriyle çakışıyordu ve örneklerin
  /// tamamı gelin/damat ya da torundu. Günlük soyadsız yazdığı için
  /// "Deniz okula başladı" satırı kimi anlattığı belirsiz kalıyordu.
  ///
  /// Bu, mevcut kalıbın eksik kalmış iki yerine uygulanmasıdır; yeni bir
  /// kural değildir. Hayat üretimindeki **ebeveyn ve kardeş** adları
  /// bilerek dışarıda: o soru Q-198 #6'da Faho'nun kararını bekliyor.
  String pickFreshName(List<String> pool, Set<String> used) {
    final List<String> bos =
        pool.where((String ad) => !used.contains(ad)).toList(growable: false);
    return pick(bos.isEmpty ? pool : bos);
  }

  bool chance(double probability) => nextDouble() < probability;

  /// Üçgen dağılımdan tam sayı: uçlar mümkün ama **seyrek**.
  ///
  /// [min] ve [max] dahil aralıkta, [peak] çevresinde yoğunlaşır. Yaş
  /// üretiminde çok genç veya çok ileri yaş mümkün kalsın ama uç değerler
  /// gereğinden sık seçilmesin diye kullanılır (D-041).
  int triangular(int min, int peak, int max) {
    if (max <= min) return min;
    final double a = min.toDouble();
    final double b = max.toDouble();
    final double c = peak.clamp(min, max).toDouble();
    final double u = nextDouble();
    final double esik = (c - a) / (b - a);
    final double x = u < esik
        ? a + sqrt(u * (b - a) * (c - a))
        : b - sqrt((1 - u) * (b - a) * (b - c));
    return x.round().clamp(min, max);
  }

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
