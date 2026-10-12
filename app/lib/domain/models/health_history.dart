/// Sağlık geçmişi kaydı (D-153).
library;

import 'package:flutter/foundation.dart';

import '../../data/health_crisis_catalog.dart';

/// Atlatılmış bir sağlık krizinin kalıcı kaydı.
///
/// Önceden yalnızca **son** krizin yaşı tutuluyordu (`lastCrisisAge`);
/// aynı krizi üçüncü kez yaşayan oyuncuda hiçbir iz kalmıyordu. Bu kayıt
/// silinmez ve Sağlık Geçmişi ekranını besler.
@immutable
class HealthHistoryEntry {
  const HealthHistoryEntry({
    required this.crisisId,
    required this.age,
    required this.choiceId,
    this.chronicTypeId,
  });

  final String crisisId;

  /// Krizin yaşandığı yaş.
  final int age;

  /// Oyuncunun verdiği yanıtın kimliği.
  final String choiceId;

  /// Bu krizin ardından kalan kronik durumun kimliği; kalmadıysa `null`.
  final String? chronicTypeId;

  /// Kataloğa karşılık gelen kriz; katalogdan kalkmışsa `null`.
  HealthCrisis? get crisis {
    for (final HealthCrisis c in kHealthCrises) {
      if (c.id == crisisId) return c;
    }
    return null;
  }

  /// Ekranda görünen kısa ad.
  String get label => crisis?.kind.label ?? 'Sağlık olayı';

  /// Ekranda görünen metin; kriz katalogdan kalktıysa kimliğe düşer.
  String get text => crisis?.text ?? crisisId;
}
