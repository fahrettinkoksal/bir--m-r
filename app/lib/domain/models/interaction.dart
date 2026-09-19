import 'package:flutter/foundation.dart';

/// Aile bireyleriyle yapılabilen etkileşim türleri (D-016).
///
/// Birden fazla tür bulunması, bir faaliyetin aynı yaşta faydasının bitmesinin
/// **diğer faaliyetleri kilitlemediğini** göstermek için gereklidir
/// (`docs/CORE_LOOP.md`). Hediye verme gibi para gerektiren etkileşimler,
/// ekonomi sistemi henüz tasarlanmadığı için bu aşamada yoktur.
enum InteractionKind {
  vakitGecir('Vakit Geçir'),
  sohbet('Sohbet Et');

  const InteractionKind(this.label);

  final String label;
}

/// Bir etkileşimin yapılıp yapılamayacağı ve yapılamıyorsa gerekçesi.
@immutable
class InteractionAvailability {
  const InteractionAvailability.allowed()
      : isAllowed = true,
        reason = null;

  const InteractionAvailability.blocked(this.reason) : isAllowed = false;

  final bool isAllowed;
  final String? reason;
}

/// Bir etkileşimin sonucu.
///
/// [accepted] false ise kişi doğal bir gerekçeyle reddetmiştir (D-020).
/// [noNewBenefit] true ise etkileşim gerçekleşmiş ama o yaş için ilgili
/// kazanç sıfıra inmiştir (D-019, D-026).
@immutable
class InteractionOutcome {
  const InteractionOutcome({
    required this.kind,
    required this.personId,
    required this.accepted,
    required this.text,
    this.bondDelta = 0,
    this.happinessDelta = 0,
    this.charismaDelta = 0,
    this.noNewBenefit = false,
  });

  final InteractionKind kind;
  final String personId;
  final bool accepted;

  /// Oyuncuya gösterilecek özgün Türkçe sonuç metni.
  final String text;
  final int bondDelta;
  final int happinessDelta;
  final int charismaDelta;
  final bool noNewBenefit;

  bool get hasAnyEffect =>
      bondDelta != 0 || happinessDelta != 0 || charismaDelta != 0;

  /// Hayat günlüğüne yalnızca anlamlı sonuçlar yazılır.
  bool get worthLogging => !accepted || hasAnyEffect;
}
