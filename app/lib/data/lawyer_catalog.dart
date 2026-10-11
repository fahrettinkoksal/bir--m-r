/// Avukat kataloğu (D-128).
///
/// Avukat **sonucu garanti etmez.** Yaptığı tek şey, mahkeme sonucunun
/// ihtimallerini bir miktar iyi tarafa çekmektir. Oyun hukuki savunma
/// taktiği öğretmez; avukat soyut bir oyun mekaniğidir.
///
/// Gerçek bir avukatın ya da hukuk bürosunun adı **kullanılmaz**.
///
/// Ücretler 2026 Türkiye'sine göre: Türkiye Barolar Birliği asgari ücret
/// tarifesi ceza davalarında beş haneli tutarlardan başlar, tanınmış
/// bürolar çok daha yukarısını ister. Sayılar `prototypeOnly`'dir
/// (Q-142).
library;

import 'package:flutter/foundation.dart';

import 'economy.dart';

@immutable
class LawyerTier {
  const LawyerTier({
    required this.id,
    required this.label,
    required this.fee,
    required this.description,
    required this.mercyBonus,
  });

  final String id;
  final String label;

  /// Peşin ödenen ücret (₺).
  final int fee;

  final String description;

  /// prototypeOnly: sonucu yumuşatma payı (0-1 arası).
  ///
  /// Beraat ya da erteleme ihtimaline eklenir; hiçbir zaman sonucu
  /// kesinleştirmez.
  final double mercyBonus;
}

/// Kendini savunma: ücretsiz, katkısız. Katalogda ayrı bir kademe olarak
/// durur ki ekranda "avukat tutmamak" da bir seçim olsun.
const LawyerTier kSelfDefenceTier = LawyerTier(
  id: 'kendim',
  label: 'Avukat tutma',
  fee: 0,
  description: 'Kendin anlatırsın. Masraf yok, yardım da yok.',
  mercyBonus: 0,
);

final List<LawyerTier> kLawyerCatalog = List<LawyerTier>.unmodifiable(
  <LawyerTier>[
    kSelfDefenceTier,
    LawyerTier(
      id: 'ucuz',
      label: 'Uygun ücretli avukat',
      fee: (Economy.netMonthlyMinimumWage * 1.2).round(),
      description: 'Dosyayı duruşmadan bir gün önce okumuş gibi duruyor.',
      mercyBonus: 0.10,
    ),
    LawyerTier(
      id: 'standart',
      label: 'Deneyimli avukat',
      fee: (Economy.netMonthlyMinimumWage * 3.5).round(),
      description: 'Dosyayı baştan sona çalışmış. Söz verdiği tek şey bu.',
      mercyBonus: 0.20,
    ),
    LawyerTier(
      id: 'iyi',
      label: 'Adı duyulmuş avukat',
      fee: (Economy.netMonthlyMinimumWage * 9).round(),
      description: 'Pahalı. Yine de "kazanırız" demiyor, "çalışırız" diyor.',
      mercyBonus: 0.32,
    ),
  ],
);

LawyerTier? lawyerTierById(String id) {
  for (final LawyerTier t in kLawyerCatalog) {
    if (t.id == id) return t;
  }
  return null;
}
