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
    this.personId,
  });

  /// Olayın yaşandığı yaş.
  final int age;
  final String text;
  final LogCategory category;

  /// Bu satır belirli bir kişiyle ilgiliyse o kişinin kalıcı kimliği
  /// (Paket 14).
  ///
  /// Kişi detayındaki "ortak geçmişiniz" bölümü bunu kullanır. Eski
  /// kayıtlarda `null`'dır ve **geriye dönük kişi bağlanmaz**.
  final String? personId;
}
