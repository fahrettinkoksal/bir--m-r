import 'package:flutter/material.dart';

import '../../domain/models/applied_effect.dart';

/// Bir seçimin ardından **gerçekten uygulanmış** değişimleri rozetler hâlinde
/// gösterir.
///
/// Olay ekranı ve kişi etkileşimleri aynı bileşeni kullanır; böylece sonuç
/// gösterimi her yerde aynı kaynaktan ve aynı biçimde gelir.
class EffectChips extends StatelessWidget {
  const EffectChips({super.key, required this.effects});

  final List<AppliedEffect> effects;

  @override
  Widget build(BuildContext context) {
    if (effects.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: <Widget>[
        for (final AppliedEffect effect in effects) _Chip(effect: effect),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.effect});

  final AppliedEffect effect;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color color = effect.isPositive
        ? theme.colorScheme.secondary
        : theme.colorScheme.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        effect.text,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}
