import 'package:flutter/foundation.dart';

import 'applied_effect.dart';

/// Aile bireyleriyle yapılabilen etkileşim türleri (D-016).
///
/// Birden fazla tür bulunması, bir faaliyetin aynı yaşta faydasının bitmesinin
/// **diğer faaliyetleri kilitlemediğini** göstermek için gereklidir
/// (`docs/CORE_LOOP.md`).
///
/// Para ve eşya taşıyan türler (hediye, para isteme) yalnızca **oyuncunun
/// kendi cüzdanıyla** çalışır (ECO-001): ailenin ekonomik durumu oyuncunun
/// parası değildir, yalnızca karşı tarafın verebileceği miktarı etkiler.
/// Para veya hediye gerçekten el değiştirmediyse eylem olmuş gibi
/// gösterilmez.
enum InteractionKind {
  vakitGecir('Vakit Geçir'),
  sohbet('Sohbet Et'),
  hediyeVer('Hediye Ver'),
  hediyeIste('Hediye İste'),
  paraIste('Para İste');

  const InteractionKind(this.label);

  final String label;

  /// Para veya eşya el değiştiren türler.
  bool get transfersResource =>
      this == hediyeVer || this == hediyeIste || this == paraIste;
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
    this.moneyDelta = 0,
    this.gainedPossession,
    this.noNewBenefit = false,
    this.effects = const <AppliedEffect>[],
  });

  final InteractionKind kind;
  final String personId;
  final bool accepted;

  /// Oyuncuya gösterilecek özgün Türkçe sonuç metni.
  final String text;
  final int bondDelta;
  final int happinessDelta;
  final int charismaDelta;

  /// Oyuncunun **kendi** cüzdanındaki değişim (ECO-001).
  final int moneyDelta;

  /// Etkileşim sonucu gerçekten eline geçen eşyanın kimliği.
  final String? gainedPossession;

  final bool noNewBenefit;

  /// Durumun öncesi ile sonrası karşılaştırılarak bulunan, **gerçekten
  /// uygulanmış** değişimler. Ekranda bunlar gösterilir.
  final List<AppliedEffect> effects;

  InteractionOutcome withEffects(List<AppliedEffect> applied) =>
      InteractionOutcome(
        kind: kind,
        personId: personId,
        accepted: accepted,
        text: text,
        bondDelta: bondDelta,
        happinessDelta: happinessDelta,
        charismaDelta: charismaDelta,
        moneyDelta: moneyDelta,
        gainedPossession: gainedPossession,
        noNewBenefit: noNewBenefit,
        effects: applied,
      );

  bool get hasAnyEffect =>
      bondDelta != 0 ||
      happinessDelta != 0 ||
      charismaDelta != 0 ||
      moneyDelta != 0 ||
      gainedPossession != null;

  /// Hayat günlüğüne yalnızca anlamlı sonuçlar yazılır.
  bool get worthLogging => !accepted || hasAnyEffect;
}
