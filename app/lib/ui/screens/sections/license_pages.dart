import 'package:flutter/material.dart';

import '../../../data/license_catalog.dart';
import '../../../data/license_questions.dart';
import '../../../domain/licensing/license_office.dart';
import '../../../domain/models/game_state.dart';
import '../../../domain/models/interaction.dart';
import '../../../state/game_controller.dart';
import '../../../state/game_scope.dart';
import '../../theme/bir_omur_theme.dart';
import '../../widgets/license_exam_sheet.dart';
import '../../widgets/section_scaffold.dart';
import '../../../text/turkish_text.dart';

/// Ehliyet işlemleri sayfası.
///
/// İki ehliyet ayrı ayrı alınır; biri diğerini vermez.
class LicenseOfficePage extends StatefulWidget {
  const LicenseOfficePage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<LicenseOfficePage> createState() => _LicenseOfficePageState();
}

class _LicenseOfficePageState extends State<LicenseOfficePage> {
  String? _sonMesaj;

  Future<void> _apply(LicenseType type) async {
    final GameController controller = GameScope.of(context);
    final LicenseOutcome? outcome = controller.applyForLicense(type);
    if (!mounted) return;
    setState(() => _sonMesaj = outcome?.text);
    if (outcome != null && outcome.examStarted) {
      await LicenseExamSheet.show(context);
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final GameController controller = GameScope.of(context);
    final GameState state = controller.state!;

    return SectionScaffold(
      accent: BirOmurAccents.turuncu,
      title: 'Ehliyet İşlemleri',
      subtitle: 'Cüzdanın: ${state.player.walletLabel}',
      backLabel: 'Aktiviteler',
      onBack: widget.onBack,
      children: <Widget>[
        if (state.hasPendingLicenseExam) ...<Widget>[
          MenuRow(
            title: 'Sınava devam et',
            subtitle: state.pendingLicenseExam?.license?.label ?? '',
            icon: Icons.assignment_outlined,
            accent: BirOmurAccents.turuncu,
            onTap: () async {
              await LicenseExamSheet.show(context);
              if (mounted) setState(() {});
            },
          ),
          const SizedBox(height: 12),
        ],
        for (final LicenseType type in LicenseType.values) ...<Widget>[
          _LicenseCard(
            type: type,
            owned: controller.hasLicense(type),
            availability: controller.licenseAvailability(type),
            onApply: () => _apply(type),
          ),
          const SizedBox(height: 10),
        ],
        if (_sonMesaj != null) ...<Widget>[
          const SizedBox(height: 6),
          InfoPanel(icon: Icons.chat_bubble_outline, text: _sonMesaj!),
          const SizedBox(height: 6),
        ],
        const SizedBox(height: 4),
        Text(
          'Sınav kısa bir soruyla yapılır. Yanlış cevapta ehliyet '
          'verilmez; ücret iade edilmez ve aynı yıl sınırlı sayıda '
          'başvurabilirsin. Yaş sınırları ve ücretler oyun içi geçici '
          'değerlerdir.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _LicenseCard extends StatelessWidget {
  const _LicenseCard({
    required this.type,
    required this.owned,
    required this.availability,
    required this.onApply,
  });

  final LicenseType type;
  final bool owned;
  final InteractionAvailability availability;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int ucret = prototypeOnlyExamFee(type);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(type.icon, color: theme.colorScheme.secondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(type.label, style: theme.textTheme.titleMedium),
                ),
                if (owned)
                  Icon(
                    Icons.verified_outlined,
                    color: theme.colorScheme.primary,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              owned
                  ? 'Bu ehliyet sende. İlgili aracı kullanabilirsin.'
                  : 'Sınav ücreti: ${trMoney(ucret)} · En az '
                      '${type.prototypeOnlyMinAge} yaş',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (!owned) ...<Widget>[
              const SizedBox(height: 10),
              if (!availability.isAllowed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    availability.reason ?? '',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonal(
                  key: Key('license_apply_${type.name}'),
                  onPressed: availability.isAllowed ? onApply : null,
                  child: const Text('Başvur'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
