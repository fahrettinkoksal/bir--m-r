import 'package:flutter/foundation.dart';

import '../../data/health_crisis_catalog.dart';

/// Cevap bekleyen sağlık krizi (D-044).
///
/// Kaydedilir: uygulama kapatılıp açılınca **aynı kriz** ve aynı seçenekler
/// gelir. Seçim bir kez uygulanır; bedel iki kez kesilmez.
@immutable
class PendingCrisis {
  const PendingCrisis({required this.crisisId, required this.age});

  final String crisisId;

  /// Krizin çıktığı yaş.
  final int age;

  HealthCrisis? get crisis => healthCrisisById(crisisId);
}
