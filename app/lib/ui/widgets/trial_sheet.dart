import 'package:flutter/material.dart';

import '../../data/crime_catalog.dart';
import '../../data/lawyer_catalog.dart';
import '../../domain/models/criminal_record.dart';
import '../../domain/models/pending_trial.dart';
import '../../state/game_controller.dart';
import '../../state/game_scope.dart';
import '../../text/turkish_text.dart';
import 'kilim_divider.dart';

/// Duruşma penceresi (D-128).
///
/// İki karar aynı ekranda verilir: **avukat** ve **savunma tutumu**.
/// Seçenekler hukuki taktik öğretmez; insanın o anda takınabileceği
/// tutumu anlatır. Sonuç garanti değildir ve pencere bunu açıkça söyler.
class TrialSheet extends StatefulWidget {
  const TrialSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (BuildContext context) => const TrialSheet(),
    );
  }

  @override
  State<TrialSheet> createState() => _TrialSheetState();
}

class _TrialSheetState extends State<TrialSheet> {
  String _avukatId = kSelfDefenceTier.id;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final GameController controller = GameScope.of(context);
    final PendingTrial? durusma = controller.pendingTrial;

    // Karar verildiyse pencere kendini kapatır; sonucu bildirim anlatır
    // (D-114), burada ikinci kez yazılmaz.
    if (durusma == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).maybePop();
      });
      return const SizedBox.shrink();
    }

    final CriminalCase? dosya = controller.trialCase;
    final CrimeType? suc = dosya?.crime;

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Duruşma', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(
                suc == null
                    ? 'Dosyan görülüyor.'
                    : '${suc.label} · ${suc.severity.label}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              const KilimDivider(),
              const SizedBox(height: 16),
              Text(durusma.text, style: theme.textTheme.titleMedium),
              const SizedBox(height: 20),

              // 1) Avukat.
              Text('Avukat', style: theme.textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(
                'Avukat sonucu garanti etmez. Yalnızca ihtimalleri bir '
                'miktar değiştirir.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              for (final LawyerTier kademe in kLawyerCatalog)
                _AvukatSatiri(
                  tier: kademe,
                  secili: _avukatId == kademe.id,
                  engel: controller.lawyerBlockReason(kademe),
                  onSec: () => setState(() => _avukatId = kademe.id),
                ),

              const SizedBox(height: 18),
              const KilimDivider(),
              const SizedBox(height: 16),

              // 2) Savunma tutumu — karar bu düğmeyle verilir.
              Text('Sıra sende', style: theme.textTheme.titleSmall),
              const SizedBox(height: 10),
              for (final DefenceStance tutum in DefenceStance.values) ...<Widget>[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    key: Key('trial_stance_${tutum.name}'),
                    onPressed: () {
                      controller.respondToTrial(
                        stance: tutum,
                        lawyerId: _avukatId,
                      );
                      if (mounted) Navigator.of(context).maybePop();
                    },
                    style: OutlinedButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(tutum.label),
                        const SizedBox(height: 2),
                        Text(
                          tutum.description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
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

class _AvukatSatiri extends StatelessWidget {
  const _AvukatSatiri({
    required this.tier,
    required this.secili,
    required this.engel,
    required this.onSec,
  });

  final LawyerTier tier;
  final bool secili;
  final String engel;
  final VoidCallback onSec;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool acik = engel.isEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              key: Key('trial_lawyer_${tier.id}'),
              onPressed: acik ? onSec : null,
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                backgroundColor: secili
                    ? theme.colorScheme.primary.withValues(alpha: 0.12)
                    : null,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    secili
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          tier.fee == 0
                              ? tier.label
                              : '${tier.label} · ${trMoney(tier.fee)}',
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tier.description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!acik)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text(
                engel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
