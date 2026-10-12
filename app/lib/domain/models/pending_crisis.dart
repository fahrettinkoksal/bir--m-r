import 'package:flutter/foundation.dart';

import '../../data/health_crisis_catalog.dart';

/// Cevap bekleyen sağlık krizi (D-044).
///
/// Kaydedilir: uygulama kapatılıp açılınca **aynı kriz** ve aynı seçenekler
/// gelir. Seçim bir kez uygulanır; bedel iki kez kesilmez.
@immutable
class PendingCrisis {
  const PendingCrisis({
    required this.crisisId,
    required this.age,
    this.causeId,
  });

  final String crisisId;

  /// Krizin çıktığı yaş.
  final int age;

  /// Kritik sağlık durumunun **bilinen** sebebi (Paket AQ).
  ///
  /// `CriticalHealthCause.id` değerini taşır. `null` ise sebep kayıtta
  /// yoktur ve ekranda **uydurma sebep yazılmaz**. Eski kayıtlarda bu
  /// alan hiç bulunmaz; o yüzden isteğe bağlı.
  final String? causeId;

  HealthCrisis? get crisis => healthCrisisById(crisisId);
}
