import 'package:flutter/foundation.dart';

/// Karakterin beş başlangıç değeri (D-006).
///
/// **Ün burada yoktur.** D-027 gereği Ün her karakterde baştan bulunan bir
/// değer değildir; koşullu olarak açılır ve [PlayerCharacter.fame] alanında
/// tutulur.
@immutable
class Stats {
  const Stats({
    required this.appearance,
    required this.happiness,
    required this.health,
    required this.intelligence,
    required this.charisma,
  });

  final int appearance;
  final int happiness;
  final int health;
  final int intelligence;
  final int charisma;

  /// Ekranda sabit sırayla gösterilecek değer listesi.
  List<StatEntry> get entries => <StatEntry>[
        StatEntry('Dış görünüş', appearance, short: 'Görünüş'),
        StatEntry('Mutluluk', happiness, short: 'Mutluluk'),
        StatEntry('Sağlık', health, short: 'Sağlık'),
        StatEntry('Zekâ', intelligence, short: 'Zekâ'),
        StatEntry('Karizma', charisma, short: 'Karizma'),
      ];

  /// Değerleri **azalan getiriyle** artırır (D-099).
  ///
  /// [copyWith] kesin bir değer yazar; bu yöntem ise bir **değişim**
  /// uygular. Yükselen değer yükseldikçe her yeni puan pahalılaşır:
  /// 50'den 55'e çıkmak kolaydır, 93'ten 94'e çıkmak bir hayat işidir.
  /// Böylece hiçbir değer sıradan tekrarlarla 100'e yapışmaz.
  ///
  /// Düşüşler **tam uygulanır**: yıpranma pazarlık etmez.
  Stats gain({
    int appearance = 0,
    int happiness = 0,
    int health = 0,
    int intelligence = 0,
    int charisma = 0,
  }) {
    return Stats(
      appearance: StatGain.apply(this.appearance, appearance),
      happiness: StatGain.apply(this.happiness, happiness),
      health: StatGain.apply(this.health, health),
      intelligence: StatGain.apply(this.intelligence, intelligence),
      charisma: StatGain.apply(this.charisma, charisma),
    );
  }

  Stats copyWith({
    int? appearance,
    int? happiness,
    int? health,
    int? intelligence,
    int? charisma,
  }) {
    return Stats(
      appearance: _clamp(appearance ?? this.appearance),
      happiness: _clamp(happiness ?? this.happiness),
      health: _clamp(health ?? this.health),
      intelligence: _clamp(intelligence ?? this.intelligence),
      charisma: _clamp(charisma ?? this.charisma),
    );
  }

  static int _clamp(int value) => value.clamp(0, 100);
}

/// Azalan getiri kuralı (D-099).
///
/// Faho bildirdi: "zekâ 100 olarak başladım 100 olarak bitirdim",
/// "statlar gerçekten hissedilsin". Sorun yalnızca yaşla düşmemesi
/// değildi; yukarı yol da fazla ucuzdu. Artık her puan bir öncekinden
/// pahalıdır ve tavan pratikte kapalıdır.
///
/// Bütün basamaklar ve katsayılar `prototypeOnly`'dir (Q-124).
abstract final class StatGain {
  /// prototypeOnly: çabayla ulaşılabilecek en yüksek değer.
  ///
  /// Azalan getiri tek başına yetmiyordu: yılda +4 kazandıran bir
  /// alışkanlık 40 yılda yine 100'e ulaşıyordu (ölçüldü). Artık sıradan
  /// kazançların bir **tavanı** var. Tavanın üstü ancak hayatın kendi
  /// verdiği bir başlangıçla mümkündür; oraya çalışarak çıkılmaz ve
  /// yaşlanma (D-072) oradan da aşağı çeker.
  static const int prototypeOnlySoftCap = 95;

  /// prototypeOnly: değer bu eşiklerin üstündeyken kazancın çarpanı.
  ///
  /// Çarpan **o anki değere** bakar; bu yüzden büyük bir kazanç da
  /// yükseldikçe yavaşlar, tek hamlede tavana çıkılamaz.
  static double factorFor(int value) {
    if (value < 60) return 1.0;
    if (value < 75) return 0.7;
    if (value < 85) return 0.5;
    if (value < 93) return 0.3;
    return 0.15;
  }

  /// [current] değerine [delta] uygulanınca ortaya çıkan yeni değer.
  ///
  /// Kazanç puan puan işlenir: her puan, o anki seviyenin çarpanıyla
  /// eklenir. Kayıp (negatif [delta]) olduğu gibi uygulanır.
  static int apply(int current, int delta) {
    if (delta <= 0) return (current + delta).clamp(0, 100);
    // Zaten tavanın üstündeyse kazanç yükseltmez; düşürmez de.
    if (current >= prototypeOnlySoftCap) return current.clamp(0, 100);
    double birikim = current.toDouble();
    for (int i = 0; i < delta; i++) {
      if (birikim >= prototypeOnlySoftCap) break;
      birikim += factorFor(birikim.floor());
    }
    return birikim.round().clamp(0, prototypeOnlySoftCap);
  }

  /// [current] değerinden [target] değerine çıkmak için gereken **ham**
  /// kazanç puanı. Ölçüm ve belge içindir.
  static int rawPointsFor(int current, int target) {
    int ham = 0;
    int simdi = current;
    while (simdi < target && ham < 100000) {
      ham++;
      simdi = apply(current, ham);
    }
    return ham;
  }
}

@immutable
class StatEntry {
  const StatEntry(this.label, this.value, {String? short})
      : short = short ?? label;

  final String label;

  /// Dar alanlarda kullanılan kısa etiket.
  final String short;
  final int value;
}
