import 'package:flutter/foundation.dart';

/// Hayat günlüğü satırının konusu. Günlüğe yalnızca anlamlı sonuçlar yazılır.
enum LogCategory {
  dogum,
  aile,
  kisisel,
  yasDegisimi,
}

@immutable
class LifeLogEntry {
  const LifeLogEntry({
    required this.age,
    required this.text,
    required this.category,
  });

  /// Olayın yaşandığı yaş.
  final int age;
  final String text;
  final LogCategory category;
}
