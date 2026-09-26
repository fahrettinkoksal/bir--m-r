import 'package:flutter/material.dart';

import '../../domain/law/prison_life.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/person.dart';
import '../../state/game_controller.dart';
import '../../state/game_scope.dart';
import '../theme/bir_omur_theme.dart';
import 'effect_chips.dart';
import 'person_detail_sheet.dart';
import 'section_scaffold.dart';

/// Cezaevi sayfasının "koğuş hayatı" bölümü (D-140).
///
/// İçeride geçen yıllar boş geçmez: konuşulur, sakin durulur ya da sözü
/// geçen bir gruba yakın durulur. Metinler **yöntemsizdir**: ne yapıldığı
/// değil, tutumun karşılığı ve bedeli yazılır.
///
/// Çete tarafı bu sürümde bir **sayaçtır**: itibar yükselir, koşullu
/// salıverilme kapanır. Dışarıda örgüt kurulmaz (Q-148).
class PrisonLifePanel extends StatefulWidget {
  const PrisonLifePanel({super.key});

  @override
  State<PrisonLifePanel> createState() => _PrisonLifePanelState();
}

class _PrisonLifePanelState extends State<PrisonLifePanel> {
  PrisonOutcome? _sonuc;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final GameController controller = GameScope.of(context);
    final GameState state = controller.state!;
    final List<Person> kogus = controller.cellmates();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const MenuGroupTitle(
          text: 'Koğuş hayatı',
          accent: BirOmurAccents.nar,
        ),
        const SizedBox(height: 8),
        InfoPanel(
          key: const Key('kogus_durum'),
          icon: Icons.insights_outlined,
          text: 'İyi hâl: ${state.legal.goodBehaviour}/100 · '
              'Koğuştaki itibar: ${state.legal.crewStanding}/100.\n'
              'İyi hâl koşullu salıverilmeyi yaklaştırır; gruba yakın '
              'durmak o kapıyı kapatır.',
        ),
        const SizedBox(height: 10),
        for (final PrisonAction eylem in PrisonAction.values) ...<Widget>[
          Builder(
            builder: (BuildContext context) {
              final String engel =
                  controller.prisonActionBlockReason(eylem);
              return _PrisonActionCard(
                action: eylem,
                blockReason: engel,
                onTap: engel.isNotEmpty
                    ? null
                    : () {
                        final PrisonOutcome? sonuc =
                            controller.doPrisonAction(eylem);
                        setState(() => _sonuc = sonuc);
                      },
              );
            },
          ),
          const SizedBox(height: 10),
        ],
        if (_sonuc != null) ...<Widget>[
          const SizedBox(height: 4),
          _PrisonOutcomeCard(outcome: _sonuc!),
          const SizedBox(height: 10),
        ],
        if (kogus.isNotEmpty) ...<Widget>[
          const SizedBox(height: 4),
          const MenuGroupTitle(
            text: 'Koğuşta tanıştıkların',
            accent: BirOmurAccents.turuncu,
          ),
          const SizedBox(height: 8),
          for (final Person kisi in kogus) ...<Widget>[
            Card(
              child: ListTile(
                key: Key('kogus_kisi_${kisi.id}'),
                leading: const Icon(Icons.person_outline),
                title: Text('${kisi.firstName} ${kisi.lastName}'),
                subtitle: Text(
                  'Koğuş arkadaşı · yakınlık ${kisi.bond}/100',
                  style: theme.textTheme.bodySmall,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    PersonDetailSheet.show(context, personId: kisi.id),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ],
    );
  }
}

class _PrisonActionCard extends StatelessWidget {
  const _PrisonActionCard({
    required this.action,
    required this.blockReason,
    required this.onTap,
  });

  final PrisonAction action;
  final String blockReason;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool acik = blockReason.isEmpty;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(action.label, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              action.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (!acik) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                blockReason,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonal(
                key: Key('cezaevi_${action.name}'),
                onPressed: onTap,
                child: Text(acik ? 'Yap' : 'Şu an olmaz'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrisonOutcomeCard extends StatelessWidget {
  const _PrisonOutcomeCard({required this.outcome});

  final PrisonOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color accent = outcome.applied
        ? theme.colorScheme.secondary
        : theme.colorScheme.error;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(outcome.text, style: theme.textTheme.bodyMedium),
          if (outcome.effects.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            EffectChips(effects: outcome.effects),
          ],
        ],
      ),
    );
  }
}
