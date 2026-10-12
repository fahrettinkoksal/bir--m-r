/// Ekranda bekleyen duruşma (D-128).
///
/// Sağlık krizi gibi kayda girer: uygulama kapatılıp açılınca **aynı
/// duruşma** aynı seçeneklerle gelir ve karar bir kez uygulanır.
library;

import 'package:flutter/foundation.dart';

/// Duruşmadaki savunma tutumu.
///
/// Seçenekler bilinçli olarak **hukuki taktik öğretmez**; insanın o anda
/// takınabileceği tutumu anlatır.
enum DefenceStance {
  pismanlik(
    'Pişman olduğunu söyle',
    'Kısa konuşursun. Uzatmazsın.',
  ),
  anlat(
    'Olayı olduğu gibi anlat',
    'Baştan sona anlatırsın. Nasıl karşılanacağı belli değil.',
  ),
  avukat(
    'Avukatın konuşsun',
    'Sen susarsın. Tuttuysan avukatın anlatır.',
  );

  const DefenceStance(this.label, this.description);

  final String label;
  final String description;
}

@immutable
class PendingTrial {
  const PendingTrial({
    required this.caseId,
    required this.age,
    required this.text,
  });

  /// Duruşması görülen dosyanın kimliği ([CriminalCase.id]).
  final String caseId;

  /// Duruşmanın görüldüğü yaş.
  final int age;

  /// Ekranda okunan anlatı.
  final String text;
}
