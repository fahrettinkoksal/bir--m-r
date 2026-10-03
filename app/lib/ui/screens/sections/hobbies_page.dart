import 'package:flutter/material.dart';

import '../../../data/hobby_catalog.dart';
import '../../../domain/models/game_state.dart';
import '../../../domain/models/hobby_progress.dart';
import '../../../state/game_scope.dart';
import '../../theme/bir_omur_theme.dart';
import '../../widgets/kilim_divider.dart';
import '../../widgets/section_scaffold.dart';

/// Hobilerim sayfası (D-133).
///
/// Hobi sistemi vardı ama neyle uğraşıldığını **tek yerde** gösteren bir
/// ekran yoktu; oyuncu kendi geçmişini göremiyordu. Bu ekran yalnızca
/// gerçek kayıttan okur, hiçbir şey uydurmaz.
class HobbiesPage extends StatelessWidget {
  const HobbiesPage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final GameState state = GameScope.of(context).state!;
    final int yas = state.player.age;

    // Sürenler ve bırakılanlar ayrı durur: "bıraktım" da bilgidir.
    final List<HobbyProgress> suren = state.hobbies
        .where((HobbyProgress h) => h.isActiveAt(yas))
        .toList(growable: false);
    final List<HobbyProgress> birakilan = state.hobbies
        .where((HobbyProgress h) => !h.isActiveAt(yas))
        .toList(growable: false);

    return SectionScaffold(
      icon: Icons.palette_rounded,
      accent: BirOmurAccents.mor,
      title: 'Hobilerim',
      subtitle: state.hobbies.isEmpty
          ? null
          : 'Kayıt silinmez: bıraktığın uğraş da burada durur.',
      backLabel: 'Aktiviteler',
      onBack: onBack,
      children: <Widget>[
        if (state.hobbies.isEmpty)
          const InfoPanel(
            key: Key('hobi_yok'),
            icon: Icons.palette_outlined,
            text: 'Henüz bir hobin yok. Kurslar, kütüphane ve spor '
                'salonu birer uğraşa dönüşebilir.',
          ),
        if (suren.isNotEmpty) ...<Widget>[
          const MenuGroupTitle(
            text: 'Sürüyor',
            accent: BirOmurAccents.yesil,
          ),
          const SizedBox(height: 8),
          for (final HobbyProgress h in suren) ...<Widget>[
            _HobiKarti(progress: h, playerAge: yas, active: true),
            const SizedBox(height: 10),
          ],
        ],
        if (birakilan.isNotEmpty) ...<Widget>[
          const SizedBox(height: 8),
          const MenuGroupTitle(
            text: 'Uzun süredir uğraşılmayan',
            accent: BirOmurAccents.pirinc,
          ),
          const SizedBox(height: 4),
          Text(
            'Bırakılmış sayılıyor ama geçmişi duruyor; yeniden '
            'başlanabilir.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          for (final HobbyProgress h in birakilan) ...<Widget>[
            _HobiKarti(progress: h, playerAge: yas, active: false),
            const SizedBox(height: 10),
          ],
        ],
      ],
    );
  }
}

class _HobiKarti extends StatelessWidget {
  const _HobiKarti({
    required this.progress,
    required this.playerAge,
    required this.active,
  });

  final HobbyProgress progress;
  final int playerAge;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final HobbyKind? hobi = progress.hobby;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: active ? 0.45 : 0.25,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(hobi?.icon ?? Icons.palette_outlined, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hobi?.label ?? progress.hobbyId,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              Text(
                progress.stageLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const KilimDivider(),
          const SizedBox(height: 8),
          _satir(theme, 'Başlangıç', '${progress.startedAtAge} yaş'),
          _satir(
            theme,
            'Son uğraş',
            '${progress.lastPracticedAge} yaş'
                '${active ? '' : ' (${playerAge - progress.lastPracticedAge} yıl önce)'}',
          ),
          _satir(theme, 'Süre', '${progress.years} yıl'),
          _satir(theme, 'Deneyim', '${progress.experience}'),
          if (progress.memories.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              'Anılar',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            for (final HobbyMemory an in progress.memories)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  '${an.age} yaş · ${an.text}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _satir(ThemeData theme, String baslik, String deger) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 88,
              child: Text(
                baslik,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: Text(deger, style: theme.textTheme.bodySmall),
            ),
          ],
        ),
      );
}
