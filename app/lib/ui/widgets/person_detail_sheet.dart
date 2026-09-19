import 'package:flutter/material.dart';

import '../../domain/models/game_state.dart';
import '../../domain/models/interaction.dart';
import '../../domain/models/person.dart';
import '../../state/game_scope.dart';
import 'kilim_divider.dart';

/// Kişi ayrıntısı ve aile etkileşimleri.
///
/// Kişi kimliğiyle çalışır; etkileşimden sonra güncel kayıt durumdan yeniden
/// okunur. Yapılamayacak bir etkileşim düğme olarak gösterilmez, gerekçesi
/// yazılır.
class PersonDetailSheet extends StatefulWidget {
  const PersonDetailSheet({super.key, required this.personId});

  final String personId;

  static Future<void> show(BuildContext context, {required String personId}) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext context) => PersonDetailSheet(personId: personId),
    );
  }

  @override
  State<PersonDetailSheet> createState() => _PersonDetailSheetState();
}

class _PersonDetailSheetState extends State<PersonDetailSheet> {
  InteractionOutcome? _lastOutcome;

  void _run(InteractionKind kind) {
    final InteractionOutcome? outcome =
        GameScope.of(context).interact(widget.personId, kind);
    if (outcome == null) return;
    setState(() => _lastOutcome = outcome);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final GameState state = GameScope.of(context).state!;
    final Person? person = state.personById(widget.personId);
    if (person == null) return const SizedBox.shrink();

    final int playerAge = state.player.age;
    final InteractionAvailability availability =
        GameScope.of(context).availabilityFor(person);

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(person.fullName, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(
                person.labelFor(playerAge),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              const KilimDivider(),
              const SizedBox(height: 14),
              _Row(
                label: 'Yaş',
                value:
                    person.isAlive ? '${person.age}' : '${person.age} (vefat etti)',
              ),
              _Row(label: 'Cinsiyet', value: person.gender.label),
              _Row(label: 'Durum', value: person.occupationLabel),
              if (person.wealth != null)
                _Row(label: 'Kendi maddi durumu', value: person.wealth!.label),
              _Row(
                label: 'Hane',
                value: person.isAlive
                    ? (person.inPlayerHousehold ? 'Seninle aynı evde' : 'Ayrı evde')
                    : '—',
              ),
              if (person.isAlive) ...<Widget>[
                const SizedBox(height: 16),
                Text('Yakınlık', style: theme.textTheme.labelLarge),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: person.bond / 100,
                    minHeight: 8,
                    backgroundColor:
                        theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.secondary,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              if (availability.isAllowed)
                _Actions(onSelected: _run)
              else
                _Note(text: availability.reason!),
              if (_lastOutcome != null) ...<Widget>[
                const SizedBox(height: 16),
                _OutcomeCard(outcome: _lastOutcome!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.onSelected});

  final void Function(InteractionKind kind) onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: <Widget>[
        for (final InteractionKind kind in InteractionKind.values)
          FilledButton.tonal(
            onPressed: () => onSelected(kind),
            child: Text(kind.label),
          ),
      ],
    );
  }
}

/// Son etkileşimin sonucu: metin ve gerçekten uygulanan değişimler.
class _OutcomeCard extends StatelessWidget {
  const _OutcomeCard({required this.outcome});

  final InteractionOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color accent =
        outcome.accepted ? theme.colorScheme.secondary : theme.colorScheme.primary;

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
          if (outcome.hasAnyEffect) ...<Widget>[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: <Widget>[
                if (outcome.bondDelta != 0)
                  _Chip(label: 'Yakınlık', delta: outcome.bondDelta),
                if (outcome.happinessDelta != 0)
                  _Chip(label: 'Mutluluk', delta: outcome.happinessDelta),
                if (outcome.charismaDelta != 0)
                  _Chip(label: 'Karizma', delta: outcome.charismaDelta),
              ],
            ),
          ],
          if (outcome.accepted && outcome.noNewBenefit) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              'Bu yaş için bu etkinlikten kazanacağın kalmadı. Başka kişiler '
              've başka etkinlikler açık.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.delta});

  final String label;
  final int delta;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool positive = delta > 0;
    final Color color =
        positive ? theme.colorScheme.secondary : theme.colorScheme.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label ${positive ? '+' : ''}$delta',
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
