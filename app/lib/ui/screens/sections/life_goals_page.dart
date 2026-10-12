import 'package:flutter/material.dart';

import '../../../data/life_goal_catalog.dart';
import '../../../domain/life/life_goals.dart';
import '../../../domain/models/game_state.dart';
import '../../../state/game_scope.dart';
import '../../theme/bir_omur_theme.dart';
import '../../widgets/section_scaffold.dart';

/// Hayat Hedefleri sayfası (D-156).
///
/// Hayat sonu değerlendirmesi hayatın **sonunda** tek seferlik bir özet
/// veriyordu; oyun içinde oyuncuyu yönlendiren hiçbir hedef yoktu.
///
/// Bu ekran **hiçbir ödül vermez** ve hiçbir şeyi değiştirmez. Ulaşılan
/// hedefin **hangi yaşta** ulaşıldığı kayıttan okunur; bugünün
/// durumundan yeniden hesaplanmaz.
class LifeGoalsPage extends StatelessWidget {
  const LifeGoalsPage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final GameState state = GameScope.of(context).state!;
    final int ulasilan = LifeGoals.reachedCount(state);

    return SectionScaffold(
      icon: Icons.flag_rounded,
      accent: BirOmurAccents.pirinc,
      title: 'Hayat Hedefleri',
      subtitle: '$ulasilan / ${kLifeGoals.length} hedefe ulaştın.',
      backLabel: 'Aktiviteler',
      onBack: onBack,
      children: <Widget>[
        for (final GoalArea alan in GoalArea.values) ...<Widget>[
          MenuGroupTitle(
            text: alan.label,
            accent: _alanRengi(alan),
          ),
          const SizedBox(height: 8),
          for (final LifeGoal hedef in lifeGoalsIn(alan)) ...<Widget>[
            _HedefSatiri(
              goal: hedef,
              reachedAtAge: state.goalsReachedAt[hedef.id],
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 6),
        ],
      ],
    );
  }

  static BirOmurAccent _alanRengi(GoalArea alan) {
    switch (alan) {
      case GoalArea.egitim:
        return BirOmurAccents.mor;
      case GoalArea.kariyer:
        return BirOmurAccents.pirinc;
      case GoalArea.ekonomi:
        return BirOmurAccents.yesil;
      case GoalArea.aile:
        return BirOmurAccents.gul;
      case GoalArea.kendin:
        return BirOmurAccents.nar;
    }
  }
}

class _HedefSatiri extends StatelessWidget {
  const _HedefSatiri({required this.goal, required this.reachedAtAge});

  final LifeGoal goal;

  /// Ulaşıldığı yaş; ulaşılmadıysa `null`.
  final int? reachedAtAge;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool ulasildi = reachedAtAge != null;

    return Container(
      key: Key('hedef_${goal.id}'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest
            .withValues(alpha: ulasildi ? 0.55 : 0.28),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            ulasildi
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 20,
            color: ulasildi
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(goal.label, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  ulasildi
                      ? '$reachedAtAge yaşında'
                      : goal.description,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
