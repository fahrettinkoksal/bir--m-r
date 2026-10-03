/// Oyuncunun taşıdığı kronik sağlık durumu (D-153).
library;

import 'package:flutter/foundation.dart';

import '../../data/chronic_catalog.dart';

/// Bir kronik durumun oyuncudaki kaydı.
///
/// **Kayıt silinmez.** Durum geçse bile kayıt kalır; yalnızca
/// [endedAtAge] dolar. "Kırk yaşında başladı, elli beşte kontrol altına
/// alındı" bilgisi hayat boyu durur.
@immutable
class ChronicCondition {
  const ChronicCondition({
    required this.typeId,
    required this.startedAtAge,
    this.lastCaredAtAge,
    this.endedAtAge,
    this.careYears = 0,
  });

  /// `chronic_catalog.dart` içindeki tür kimliği.
  final String typeId;

  /// Oyuncunun kaç yaşında başladığı.
  final int startedAtAge;

  /// En son hangi yaşta takip edildiği (bakımı ödendiği).
  final int? lastCaredAtAge;

  /// Durumun bittiği yaş; sürüyorsa `null`.
  final int? endedAtAge;

  /// Kaç yıl takip edildiği. Yalnızca gerçekten ödenen yıllar sayılır.
  final int careYears;

  bool get isActive => endedAtAge == null;

  /// [age] yaşında takip edilmiş mi?
  bool caredAt(int age) => lastCaredAtAge == age;

  ChronicConditionType? get type => chronicTypeById(typeId);

  /// Ekranda görünen ad; tür kaybolduysa kimliğe düşer.
  String get label => type?.label ?? typeId;

  ChronicCondition copyWith({
    int? lastCaredAtAge,
    int? endedAtAge,
    int? careYears,
  }) =>
      ChronicCondition(
        typeId: typeId,
        startedAtAge: startedAtAge,
        lastCaredAtAge: lastCaredAtAge ?? this.lastCaredAtAge,
        endedAtAge: endedAtAge ?? this.endedAtAge,
        careYears: careYears ?? this.careYears,
      );
}
