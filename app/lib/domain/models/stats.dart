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
        StatEntry('Dış görünüş', appearance),
        StatEntry('Mutluluk', happiness),
        StatEntry('Sağlık', health),
        StatEntry('Zekâ', intelligence),
        StatEntry('Karizma', charisma),
      ];

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

@immutable
class StatEntry {
  const StatEntry(this.label, this.value);

  final String label;
  final int value;
}
