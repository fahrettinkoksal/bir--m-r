import 'package:flutter/material.dart';

import '../../../data/finger_catalog.dart';
import '../../../domain/interaction/finger.dart';
import '../../../domain/models/finger_profile.dart';
import '../../../domain/models/interaction.dart';
import '../../../state/game_controller.dart';
import '../../../state/game_scope.dart';
import '../../theme/bir_omur_theme.dart';
import '../../widgets/section_scaffold.dart';

/// "Finger" tanışma uygulaması (Paket 34).
///
/// Profil gelir, beğenilir ya da geçilir. Beğeni karşılık bulursa eşleşme
/// olur; **tanışıldığında** kişi gerçekten hayata girer.
class FingerPage extends StatefulWidget {
  const FingerPage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<FingerPage> createState() => _FingerPageState();
}

class _FingerPageState extends State<FingerPage> {
  FingerOutcome? _sonuc;
  bool _desteDolduruldu = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_desteDolduruldu) return;
    _desteDolduruldu = true;
    // Deste ekran açılırken bir kez doldurulur; her çizimde karılmaz.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) GameScope.of(context).fillFingerDeck();
    });
  }

  @override
  Widget build(BuildContext context) {
    final GameController controller = GameScope.of(context);
    final List<FingerProfile> deste = controller.fingerDeck;
    final List<FingerProfile> eslesmeler = controller.fingerMatches;
    final InteractionAvailability izin = controller.fingerSwipeAvailability;
    final int kalan =
        kFingerMaxSwipesPerAge - controller.fingerSwipesThisAge;

    return SectionScaffold(
      icon: Icons.favorite_rounded,
      accent: BirOmurAccents.gul,
      title: 'Finger',
      subtitle: 'Bu yıl ${kalan < 0 ? 0 : kalan} profile daha bakabilirsin.',
      backLabel: 'Aktiviteler',
      onBack: widget.onBack,
      children: <Widget>[
        InfoPanel(
          icon: Icons.percent_rounded,
          text: 'Beğenilerinin yaklaşık '
              '%${(controller.fingerMatchChance * 100).round()}\'i karşılık '
              'buluyor. Görünüş ve karizma yükseldikçe bu oran artar. '
              'Eşleşmek tanışmak değildir: buluşana kadar kimse hayatına '
              'girmez.',
        ),
        const SizedBox(height: 12),
        if (!izin.isAllowed) ...<Widget>[
          InfoPanel(
            icon: Icons.hourglass_bottom_rounded,
            text: izin.reason!,
          ),
          const SizedBox(height: 12),
        ] else if (deste.isEmpty) ...<Widget>[
          const InfoPanel(
            icon: Icons.hourglass_empty_rounded,
            text: 'Yeni profiller yükleniyor.',
          ),
          const SizedBox(height: 12),
        ] else ...<Widget>[
          _ProfileCard(
            profile: deste.first,
            onLike: () => setState(
              () => _sonuc = controller.likeFingerProfile(deste.first.id),
            ),
            onPass: () => setState(
              () => _sonuc = controller.passFingerProfile(deste.first.id),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_sonuc != null) ...<Widget>[
          InfoPanel(
            icon: _sonuc!.matched
                ? Icons.favorite_rounded
                : Icons.info_outline_rounded,
            text: _sonuc!.text,
          ),
          const SizedBox(height: 12),
        ],
        if (eslesmeler.isNotEmpty) ...<Widget>[
          const MenuGroupTitle(
            text: 'Eşleşmelerin',
            accent: BirOmurAccents.gul,
          ),
          for (final FingerProfile p in eslesmeler) ...<Widget>[
            _MatchRow(
              profile: p,
              onMeet: () => setState(
                () => _sonuc = controller.meetFingerMatch(p.id),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.profile,
    required this.onLike,
    required this.onPass,
  });

  final FingerProfile profile;
  final VoidCallback onLike;
  final VoidCallback onPass;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      key: const Key('finger_profil'),
      decoration: panelDecoration(context, radius: 22),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                // Gerçek fotoğraf yok; baş harfler gösterilir.
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: BirOmurAccents.gul.softOf(context),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Comic.konturOf(context),
                      width: Comic.inceKontur,
                    ),
                  ),
                  child: Text(
                    profile.initials,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '${profile.firstName}, ${profile.age}',
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        profile.occupation == null
                            ? profile.city
                            : '${profile.city} · ${profile.occupation}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(profile.bio, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: <Widget>[
                for (final String ilgi in profile.interests)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: BirOmurAccents.gul.softOf(context),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Comic.konturOf(context),
                        width: Comic.inceKontur,
                      ),
                    ),
                    child: Text(ilgi, style: theme.textTheme.bodySmall),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('finger_gec'),
                    onPressed: onPass,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Geç'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    key: const Key('finger_begen'),
                    onPressed: onLike,
                    icon: const Icon(Icons.favorite_rounded, size: 18),
                    label: const Text('Beğen'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchRow extends StatelessWidget {
  const _MatchRow({required this.profile, required this.onMeet});

  final FingerProfile profile;
  final VoidCallback onMeet;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      decoration: panelDecoration(context, radius: 16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: <Widget>[
            AccentIconTile(
              icon: Icons.favorite_border_rounded,
              accent: BirOmurAccents.gul,
              size: 34,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '${profile.firstName}, ${profile.age}',
                    style: theme.textTheme.titleSmall,
                  ),
                  Text(
                    profile.isMet ? 'Tanıştınız' : profile.city,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(
              key: Key('finger_tanis_${profile.id}'),
              onPressed: profile.isMet ? null : onMeet,
              child: Text(profile.isMet ? 'Tanıştın' : 'Tanış'),
            ),
          ],
        ),
      ),
    );
  }
}
