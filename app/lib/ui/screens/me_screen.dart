import 'package:flutter/material.dart';

import '../../domain/models/game_state.dart';
import '../../domain/models/stats.dart';
import '../../state/game_scope.dart';
import '../widgets/kilim_divider.dart';
import '../widgets/section_header.dart';
import '../widgets/stat_bar.dart';

/// Ben ekranı.
///
/// İleride spor salonu, berber, seyahat gibi eylemlerin merkezi olacak
/// (`docs/PROTOTYPE_UI.md` §5). Bu sürümde o eylemler **yazılmadığı için**
/// sahte düğme konmaz; yalnızca gerçek karakter bilgileri gösterilir.
class MeScreen extends StatelessWidget {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final GameState state = GameScope.of(context).state!;
    final ThemeData theme = Theme.of(context);
    final List<StatEntry> entries = state.player.stats.entries;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(state.player.fullName, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 12),
                const KilimDivider(),
                const SizedBox(height: 12),
                _InfoRow(label: 'Yaş', value: '${state.player.age}'),
                _InfoRow(label: 'Cinsiyet', value: state.player.gender.label),
                _InfoRow(label: 'Doğum şehri', value: state.player.birthCity),
                // Eğitim durumu yaştan türetilmez; gerçek duruma bakar.
                _InfoRow(label: 'Eğitim', value: state.education.label),
                _InfoRow(
                  label: 'Hane',
                  value: state.household.isEmpty
                      ? 'Seninle yaşayan kimse yok'
                      : '${state.household.length} kişi seninle yaşıyor',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        const SectionHeader(title: 'Karakter değerleri'),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: <Widget>[
                for (int i = 0; i < entries.length; i++) ...<Widget>[
                  if (i > 0) const SizedBox(height: 16),
                  StatBar(label: entries[i].label, value: entries[i].value),
                ],
              ],
            ),
          ),
        ),
        // Ün, açılmamış karakterde hiç gösterilmez (D-027).
        if (state.player.fameUnlocked) ...<Widget>[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: StatBar(label: 'Ün', value: state.player.fame!),
            ),
          ),
        ],
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
          child: Text(
            'Bu bölüm ilerleyen sürümlerde spor salonu, berber ve seyahat gibi '
            'eylemlerin merkezi olacak. Henüz yazılmamış eylemler burada '
            'düğme olarak gösterilmiyor.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

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
            width: 120,
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
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
