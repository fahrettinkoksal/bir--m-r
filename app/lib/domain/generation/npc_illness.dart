/// Oyuncunun yönetmediği kişilerin **hastalanması** (Paket CN).
///
/// **Neden ayrı dosya.** Kural zaten vardı ama tek bir yere gömülüydü:
/// `SpouseLife._maybeIllness` eşi hastalandırıyordu (D-154). `EKSIKLER`
/// §3.2'nin son açık maddesi "çocuk hastalanamıyor" diyordu ve kodda
/// doğrulandı: `ChildProgression` içinde hastalık hiç yok. Aynı kuralı
/// ikinci kez yazmak yerine buraya taşındı; eşin davranışı **birebir
/// aynı** (sayılar, üç yıllık ara, izin dönüm noktasından okunması,
/// zarın hangi sırada tüketildiği). Tek ek koşul `isAlive`: eşin
/// yolunda `SpouseLife.spouseOf` zaten yaşayan eşi süzüyor, bu yüzden
/// o dal eşte hiç çalışmaz. Ölçüldü: eski kodla yeni kodun
/// modül-kapalı koşusu 40 hayatta satır satır aynı.
///
/// **Zar oyunun akışından ayrı.** Çocuk başına yıllık bir atış, ana
/// zar dizisinden çekilseydi 70 yıllık bir hayatta sıranın tamamı
/// kayar ve bütün tohumlu ölçümler karşılaştırılamaz hale gelirdi.
/// Bunun yerine atış, kişinin **kimliği ve yaşından** türeyen kendi
/// tohumuyla yapılıyor:
///
/// * Mevcut ölçümler bit bit aynı kalır (zar sözleşmesi).
/// * Aynı kişi-yıl her zaman aynı sonucu verir; kaydı kapatıp açarak
///   hastalığı yeniden çevirmek **imkânsız** (piyasa endeksinde
///   alınan kararın aynısı).
///
/// Bütün sayılar `prototypeOnly`'dir (Q-230).
library;

import 'dart:math';

import '../models/person.dart';
import '../models/person_development.dart';

/// Bir yılın hastalık sonucu.
typedef NpcIllnessYear = ({Person person, String? text});

abstract final class NpcIllness {
  /// prototypeOnly: bir yılda hastalanma olasılığı (yaşla artar).
  ///
  /// `SpouseLife`'tan taşındı; sayılar değişmedi.
  static double prototypeOnlyChance(int age) {
    if (age < 35) return 0.012;
    if (age < 50) return 0.022;
    if (age < 65) return 0.038;
    return 0.055;
  }

  /// prototypeOnly: hastalığın kişinin sağlığından düşürdüğü puan.
  static const int prototypeOnlyHealth = -9;

  /// prototypeOnly: hastalığın kişinin keyfinden düşürdüğü puan.
  static const int prototypeOnlyHappiness = -8;

  /// prototypeOnly: iki hastalık arasında geçmesi gereken en az yıl.
  static const int prototypeOnlyGap = 3;

  /// prototypeOnly: **hanedeki** çocuğun hastalığının oyuncunun
  /// mutluluğuna etkisi.
  ///
  /// Eşin hastalığı −4 (`SpouseLife.prototypeOnlyPlayerWorry`);
  /// çocukta daha küçük tutuldu, çünkü çocuk sayısı en çok dörde
  /// kadar çıkıyor (ölçüm) ve dört ayrı −4 bir yılda ağır olurdu.
  /// Evden ayrılmış çocuğun hastalığı haber olarak gelir, bu yükü
  /// getirmez.
  static const int prototypeOnlyWorry = -2;

  /// Kişinin geçmişindeki en son hastalık yılı; hiç yoksa `null`.
  ///
  /// Ayrı bir alan eklenmedi: iz kişinin **kendi** dönüm
  /// noktalarından okunur.
  static int? lastIllnessAge(PersonDevelopment dev) {
    int? son;
    for (final LifeMilestone m in dev.milestones) {
      if (m.text.contains('hastalandı')) son = m.age;
    }
    return son;
  }

  /// Bu kişi bu yıl hastalanır mı? Zarı **çağıran** verir.
  ///
  /// `SpouseLife` ana zarı kullanmaya devam ediyor (davranışı
  /// değişmesin); çocuk tarafı [derivedRandom] ile kendi tohumunu
  /// kullanır.
  static NpcIllnessYear maybe(Person person, Random rng) {
    final PersonDevelopment? dev = person.development;
    if (dev == null || !person.isAlive) {
      return (person: person, text: null);
    }
    final int? sonHastalik = lastIllnessAge(dev);
    if (sonHastalik != null && person.age - sonHastalik < prototypeOnlyGap) {
      return (person: person, text: null);
    }
    if (rng.nextDouble() >= prototypeOnlyChance(person.age)) {
      return (person: person, text: null);
    }

    final String metin = '${person.firstName} bir süre hastalandı.';
    final PersonDevelopment yeni = dev
        .copyWith(
          stats: dev.stats.gain(
            health: prototypeOnlyHealth,
            happiness: prototypeOnlyHappiness,
          ),
        )
        .withMilestone(person.age, metin);
    return (
      person: person.copyWith(
        development: yeni,
        happiness: (person.happiness + prototypeOnlyHappiness).clamp(0, 100),
      ),
      text: metin,
    );
  }

  /// Kişi-yıla özel, **kararlı** zar.
  ///
  /// Kimlik ve yaştan türer: aynı kişi-yıl her koşuda aynı sonucu
  /// verir, ana zar dizisi hiç tüketilmez. Dart'ın `String.hashCode`
  /// değeri sürümler arasında değişebildiği için karma burada elle
  /// yazıldı.
  static Random derivedRandom(String id, int age) {
    int h = 0x1f3b;
    for (final int c in id.codeUnits) {
      h = (h * 31 + c) & 0x3fffffff;
    }
    return Random((h * 131 + age) & 0x3fffffff);
  }
}
