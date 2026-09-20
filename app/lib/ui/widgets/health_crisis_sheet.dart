import 'package:flutter/material.dart';

import '../../data/health_crisis_catalog.dart';
import '../../domain/life/health_crisis_engine.dart';
import '../../domain/models/pending_crisis.dart';
import '../../state/game_controller.dart';
import '../../state/game_scope.dart';
import 'kilim_divider.dart';

/// Sağlık krizi penceresi (D-044).
///
/// Metin kısa ve saygılıdır. Seçimin sonucu etkiler ama sonucu garanti
/// etmez; kriz ölümle biterse hayat olağan yolundan tamamlanır.
class HealthCrisisSheet extends StatefulWidget {
  const HealthCrisisSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (BuildContext context) => const HealthCrisisSheet(),
    );
  }

  @override
  State<HealthCrisisSheet> createState() => _HealthCrisisSheetState();
}

class _HealthCrisisSheetState extends State<HealthCrisisSheet> {
  CrisisOutcome? _sonuc;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final GameController controller = GameScope.of(context);
    final PendingCrisis? bekleyen = controller.pendingCrisis;

    if (bekleyen == null) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                _sonuc?.survived == false ? 'Hayat tamamlandı' : 'Geçmiş olsun',
                key: const Key('crisis_result_title'),
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              const KilimDivider(),
              const SizedBox(height: 14),
              Text(
                _sonuc?.text ?? 'Durum kapandı.',
                style: theme.textTheme.bodyMedium,
              ),
              if ((_sonuc?.cost ?? 0) > 0) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  'Tedavi için ${_sonuc!.cost} ₺ ödedin.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Kapat'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final HealthCrisis? kriz = bekleyen.crisis;
    if (kriz == null) return const SizedBox.shrink();

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(kriz.kind.label, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(
                'Ne yapacağına sen karar veriyorsun.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              const KilimDivider(),
              const SizedBox(height: 16),
              Text(kriz.text, style: theme.textTheme.titleMedium),
              const SizedBox(height: 16),
              for (int i = 0; i < kriz.choices.length; i++) ...<Widget>[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    key: Key('crisis_choice_${kriz.choices[i].id}'),
                    onPressed: controller.canChooseCrisis(kriz.choices[i])
                        ? () {
                            final CrisisOutcome? outcome =
                                controller.respondToCrisis(kriz.choices[i].id);
                            setState(() => _sonuc = outcome);
                          }
                        : null,
                    style: OutlinedButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    child: Text(
                      kriz.choices[i].cost > 0
                          ? '${kriz.choices[i].label} '
                              '(${kriz.choices[i].cost} ₺)'
                          : kriz.choices[i].label,
                    ),
                  ),
                ),
                if (!controller.canChooseCrisis(kriz.choices[i]))
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 6),
                    child: Text(
                      'Bu seçenek için cüzdanında yeterli para yok.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
