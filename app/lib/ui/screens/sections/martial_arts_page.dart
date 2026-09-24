import 'package:flutter/material.dart';

import '../../../data/martial_arts_catalog.dart';
import '../../../domain/activities/activity_engine.dart';
import '../../../domain/models/interaction.dart';
import '../../../domain/models/martial_progress.dart';
import '../../../state/game_controller.dart';
import '../../../state/game_scope.dart';
import '../../../text/turkish_text.dart';
import '../../theme/bir_omur_theme.dart';
import '../../widgets/section_scaffold.dart';
import 'activity_pages.dart';

/// Spor salonunun dövüş sanatları bölümü (Paket 32).
///
/// Üç dal: karate, kung fu ve yağlı güreş. Her dalın kendi **gerçek**
/// basamak düzeni vardır; ders ucuz, ilerleme yavaştır.
class MartialArtsPage extends StatefulWidget {
  const MartialArtsPage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<MartialArtsPage> createState() => _MartialArtsPageState();
}

class _MartialArtsPageState extends State<MartialArtsPage> {
  ActivityOutcome? _sonuc;
  MartialArt? _acik;

  @override
  Widget build(BuildContext context) {
    final GameController controller = GameScope.of(context);

    return SectionScaffold(
      icon: Icons.sports_martial_arts_rounded,
      accent: BirOmurAccents.nar,
      title: 'Dövüş sanatları',
      subtitle:
          'Ders ucuz, ustalık pahalı: kuşak yılla gelir. '
          'Cüzdanında ${controller.state!.player.walletLabel} var.',
      backLabel: 'Spor salonu',
      onBack: widget.onBack,
      children: <Widget>[
        for (final MartialArt art in MartialArt.values) ...<Widget>[
          _ArtCard(
            art: art,
            progress: controller.martialProgress(art),
            availability: controller.martialAvailability(art),
            lessonsThisAge: controller.martialLessonsThisAge(art),
            expanded: _acik == art,
            onToggle: () => setState(() => _acik = _acik == art ? null : art),
            seasonLessons: controller.martialSeasonLessons(art),
            onLesson: () {
              final ActivityOutcome? outcome = controller.takeMartialLesson(
                art,
              );
              setState(() => _sonuc = outcome);
            },
            onSeason: () {
              final ActivityOutcome? outcome = controller.takeMartialSeason(
                art,
              );
              setState(() => _sonuc = outcome);
            },
          ),
          const SizedBox(height: 10),
        ],
        if (_sonuc != null) ...<Widget>[
          const SizedBox(height: 4),
          OutcomeCard(outcome: _sonuc!),
        ],
      ],
    );
  }
}

class _ArtCard extends StatelessWidget {
  const _ArtCard({
    required this.art,
    required this.progress,
    required this.availability,
    required this.lessonsThisAge,
    required this.expanded,
    required this.onToggle,
    required this.onLesson,
    required this.seasonLessons,
    required this.onSeason,
  });

  final MartialArt art;
  final MartialProgress progress;
  final InteractionAvailability availability;
  final int lessonsThisAge;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onLesson;

  /// Bu yıl tek seferde alınabilecek ders sayısı (0 ise düğme çıkmaz).
  final int seasonLessons;
  final VoidCallback onSeason;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool acik = availability.isAllowed;
    final int? kalan = progress.lessonsToNextRank;

    return Container(
      decoration: panelDecoration(context, radius: 20),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                AccentIconTile(
                  icon: art.icon,
                  accent: BirOmurAccents.nar,
                  size: 38,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(art.label, style: theme.textTheme.titleMedium),
                      Text(
                        progress.lessons == 0
                            ? 'Henüz başlamadın'
                            : progress.rankName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  trMoney(art.lessonCost),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              art.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress.ratio,
                minHeight: 8,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              progress.isTopRank
                  ? 'En üst basamak: ${progress.rankName}'
                  : 'Sonraki basamak: ${art.ranks[progress.level + 1].name}'
                        '${kalan == null ? '' : ' — $kalan ders kaldı'}',
              style: theme.textTheme.bodySmall,
            ),
            Text(
              'Bu yıl $lessonsThisAge/$kMaxMartialLessonsPerAge ders · '
              'toplam ${progress.lessons} ders',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (progress.canTeach) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                'Bu basamakta eğitmenlik işine başvurabilirsin.',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            if (!acik && (availability.reason ?? '').isNotEmpty) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                availability.reason!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 10),
            // Dar ekranda düğmeler alt alta iner; sebep metni yukarıda
            // ayrı satırda durur, böylece taşma olmaz.
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 6,
              runSpacing: 6,
              children: <Widget>[
                TextButton(
                  onPressed: onToggle,
                  child: Text(expanded ? 'Gizle' : 'Basamaklar'),
                ),
                FilledButton.tonal(
                  key: Key('dovus_ders_${art.id}'),
                  onPressed: acik ? onLesson : null,
                  child: Text(acik ? 'Ders al' : 'Şu an kapalı'),
                ),
                // Basamaklar yüzlerce ders istiyor; tek tek tıklamak
                // yerine yılın kalanı bir hamlede çalışılabilir. Kural
                // aynı: yıllık sınır, ücret ve eşikler değişmiyor.
                if (acik && seasonLessons > 1)
                  FilledButton(
                    key: Key('dovus_yil_${art.id}'),
                    onPressed: onSeason,
                    child: Text('Yılı çalış ($seasonLessons ders)'),
                  ),
              ],
            ),
            if (expanded) ...<Widget>[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 8),
              for (int i = 0; i < art.ranks.length; i++)
                _RankLine(
                  art: art,
                  index: i,
                  current: progress.level,
                  reached: progress.lessons >= art.ranks[i].lessonsNeeded,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RankLine extends StatelessWidget {
  const _RankLine({
    required this.art,
    required this.index,
    required this.current,
    required this.reached,
  });

  final MartialArt art;
  final int index;
  final int current;
  final bool reached;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MartialRank rank = art.ranks[index];
    final bool simdiki = index == current;
    final bool egitmenlik = index == art.instructorFromLevel;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            reached
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 16,
            color: reached
                ? BirOmurAccents.yesil.color
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  rank.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: simdiki ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
                Text(
                  egitmenlik
                      ? '${rank.note} (eğitmenlik burada açılır)'
                      : rank.note,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${rank.lessonsNeeded} ders',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
