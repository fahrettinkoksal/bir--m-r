import 'package:flutter/material.dart';

import '../../domain/models/game_state.dart';
import '../../domain/models/stats.dart';
import '../../state/game_scope.dart';
import '../widgets/kilim_divider.dart';
import '../widgets/life_log_view.dart';
import '../widgets/section_header.dart';

/// Ana yaşam ekranı: özet, değerler, hayat günlüğü ve **Yaş Al**.
class LifeScreen extends StatelessWidget {
  const LifeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final GameState state = GameScope.of(context).state!;
    final ThemeData theme = Theme.of(context);

    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            children: <Widget>[
              _SummaryCard(state: state),
              const SizedBox(height: 22),
              const SectionHeader(title: 'Değerler'),
              const SizedBox(height: 10),
              _StatGrid(stats: state.player.stats),
              if (state.player.fameUnlocked) ...<Widget>[
                const SizedBox(height: 12),
                // Ün yalnızca açıldıysa görünür (D-027).
                _FameTile(fame: state.player.fame!),
              ],
              const SizedBox(height: 24),
              const SectionHeader(
                title: 'Hayat günlüğü',
                subtitle: 'Başından geçenlerin kaydı',
              ),
              const SizedBox(height: 10),
              LifeLogView(entries: state.log),
              const SizedBox(height: 12),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            border: Border(
              top: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => GameScope.of(context).ageUp(),
                  icon: const Icon(Icons.cake_outlined),
                  label: const Text('Yaş Al'),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Hazır olduğunda bas; bir yaşın her şeyini bitirmek zorunda '
                'değilsin.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int householdCount = state.household.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(state.player.fullName, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              '${state.player.age} yaşında · ${state.player.gender.label} · '
              '${state.player.birthCity}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            const KilimDivider(),
            const SizedBox(height: 14),
            Text(
              householdCount == 0
                  ? 'Evde seninle yaşayan kimse yok.'
                  : 'Evde seninle birlikte $householdCount kişi yaşıyor.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Annen ve baban: ${state.parentalStatus.label.toLowerCase()}.',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.stats});

  final Stats stats;

  @override
  Widget build(BuildContext context) {
    final List<StatEntry> entries = stats.entries;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            for (int i = 0; i < entries.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(height: 14),
              _CompactStat(entry: entries[i]),
            ],
          ],
        ),
      ),
    );
  }
}

class _CompactStat extends StatelessWidget {
  const _CompactStat({required this.entry});

  final StatEntry entry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      children: <Widget>[
        SizedBox(
          width: 100,
          child: Text(entry.label, style: theme.textTheme.bodyMedium),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: entry.value / 100,
              minHeight: 8,
              backgroundColor:
                  theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              valueColor:
                  AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            ),
          ),
        ),
        SizedBox(
          width: 34,
          child: Text(
            '${entry.value}',
            textAlign: TextAlign.end,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _FameTile extends StatelessWidget {
  const _FameTile({required this.fame});

  final int fame;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Icon(Icons.star_outline, color: theme.colorScheme.tertiary),
            const SizedBox(width: 10),
            Expanded(child: Text('Ün', style: theme.textTheme.titleMedium)),
            Text('$fame', style: theme.textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
