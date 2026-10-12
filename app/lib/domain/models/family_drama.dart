import 'package:flutter/foundation.dart';

/// Bir hayatın **gizli** aile dram eğilimi (Paket AP §2).
///
/// Faho'nun kuralı: "her hayat Türk dizisi olmasın". Bazı ailelerde
/// sürekli bir mesele olur, bazı ailelerde yıllarca hiçbir şey olmaz.
/// Bu sınıf o farkı tek yerde tutar.
///
/// Üç şey bilinçli olarak böyle:
///
/// * **Yalnızca sıklığı** değiştirir. Hangi olayın çıkacağına, olayın
///   sonucuna ya da bir kararın etkisine karışmaz. Yani "dramatik aile"
///   daha çok mesele yaşar; aynı meseleyi daha ağır yaşamaz.
/// * **Kayda yazılmaz.** Tamamen `GameState.seed`'den türetilir, o yüzden
///   eski kayıtlar da bir profille açılır ve yeni bir save alanı
///   gerekmez (§2, "yeni save alanı gerekmiyorsa ekleme").
/// * **Oyuncuya gösterilmez.** Ekranda "dram katsayın 1,3" diye bir şey
///   yazmaz (§58: her internal sayı gösterilmez).
///
/// Sayısal değerler `prototypeOnly`'dir; denge kararı değildir (Q-133).
@immutable
class FamilyDramaProfile {
  const FamilyDramaProfile({
    required this.frequency,
    required this.cocukAgirligi,
    required this.kardesAgirligi,
    required this.kayinAgirligi,
    required this.bakimAgirligi,
  });

  /// prototypeOnly: sıklık çarpanının alt sınırı — sakin aile.
  static const double prototypeOnlyMinFrequency = 0.55;

  /// prototypeOnly: sıklık çarpanının üst sınırı — hareketli aile.
  ///
  /// Üst sınır bilinçli olarak 2 değil: "bazı aileler daha hareketli"
  /// demek "bazı ailelerde her yıl kavga var" demek değildir.
  static const double prototypeOnlyMaxFrequency = 1.45;

  /// prototypeOnly: bir alanın ağırlık bandı.
  static const double prototypeOnlyMinWeight = 0.6;
  static const double prototypeOnlyMaxWeight = 1.4;

  /// Bu hayatta aile meselelerinin genel sıklık çarpanı.
  final double frequency;

  /// Çocukla ilgili meselelerin ağırlığı.
  final double cocukAgirligi;

  /// Kardeşle ilgili meselelerin ağırlığı.
  final double kardesAgirligi;

  /// Gelin/damat ve kayın aileyle ilgili meselelerin ağırlığı.
  final double kayinAgirligi;

  /// Yaşlı bakımıyla ilgili meselelerin ağırlığı.
  final double bakimAgirligi;

  /// Tohumdan **deterministik** olarak türetilir.
  ///
  /// `Random` kullanılmıyor: aynı tohum her açılışta aynı profili
  /// vermeli, ve bu üretim oyunun olay akışındaki zar sırasını
  /// kaydırmamalı. Bir zar çekilse bütün hayat kayardı; Paket AO'da
  /// bunun ne demek olduğu ölçülerek görüldü.
  factory FamilyDramaProfile.forSeed(int seed) {
    // Tek bir tohumdan birbirinden bağımsız beş sayı gerekiyor. Her biri
    // farklı bir asal çarpanla karıştırılıyor ki "sıklığı yüksek olanın
    // çocuk ağırlığı da hep yüksek" gibi bir bağ oluşmasın.
    double bant(int tuz, double alt, double ust) {
      final int karisim = (seed * 2654435761 + tuz * 40503).abs();
      final double birim = (karisim % 1000) / 999.0;
      return alt + (ust - alt) * birim;
    }

    return FamilyDramaProfile(
      frequency: bant(1, prototypeOnlyMinFrequency, prototypeOnlyMaxFrequency),
      cocukAgirligi: bant(2, prototypeOnlyMinWeight, prototypeOnlyMaxWeight),
      kardesAgirligi: bant(3, prototypeOnlyMinWeight, prototypeOnlyMaxWeight),
      kayinAgirligi: bant(4, prototypeOnlyMinWeight, prototypeOnlyMaxWeight),
      bakimAgirligi: bant(5, prototypeOnlyMinWeight, prototypeOnlyMaxWeight),
    );
  }

  /// Verilen alanın bu hayattaki ağırlığı.
  double weightFor(FamilyDramaArea area) {
    switch (area) {
      case FamilyDramaArea.cocuk:
        return cocukAgirligi;
      case FamilyDramaArea.kardes:
        return kardesAgirligi;
      case FamilyDramaArea.kayin:
        return kayinAgirligi;
      case FamilyDramaArea.bakim:
        return bakimAgirligi;
    }
  }

  /// Taban ihtimali bu hayatın profiline göre ölçekler.
  ///
  /// Sonuç 0 ile [cap] arasında sıkıştırılır: profil bir olayı
  /// kendiliğinden "her yıl olur" hâline getiremez.
  double scale(
    double baseChance,
    FamilyDramaArea area, {
    double cap = 0.9,
  }) {
    final double sonuc = baseChance * frequency * weightFor(area);
    return sonuc.clamp(0.0, cap);
  }
}

/// Aile meselelerinin alanları (§2).
///
/// Ağırlık bu alanlara veriliyor, tek tek olaylara değil: olay eklendikçe
/// profilin büyümesi gerekmesin.
enum FamilyDramaArea {
  /// Çocuk ve yetişkin çocuk.
  cocuk,

  /// Kardeş ve üvey/yarım kardeş.
  kardes,

  /// Gelin, damat ve kayın aile.
  kayin,

  /// Yaşlı ebeveyn bakımı.
  bakim,
}
