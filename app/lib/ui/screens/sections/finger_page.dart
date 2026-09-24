import 'package:flutter/material.dart';

import '../../../data/finger_catalog.dart';
import '../../../domain/interaction/finger.dart';
import '../../../domain/models/game_state.dart';
import '../../../text/turkish_text.dart';
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
      subtitle: 'Bu yıl ${kalan < 0 ? 0 : kalan} profile daha bakabilirsin '
          '· ${controller.fingerLikesLeft} beğeni hakkın var.',
      backLabel: 'Aktiviteler',
      onBack: widget.onBack,
      children: <Widget>[
        InfoPanel(
          icon: Icons.percent_rounded,
          text: 'Beğenilerinin yaklaşık '
              '%${(controller.fingerMatchChance * 100).round()}\'i karşılık '
              'buluyor. Görünüş, karizma ve **doldurulmuş profil** bu '
              'oranı yükseltir. Eşleşmek tanışmak değildir: buluşana '
              'kadar kimse hayatına girmez.',
        ),
        const SizedBox(height: 12),
        // Kendi profilin (D-081): boş profili kimse beğenmez.
        _SelfProfileCard(
          onSaved: (FingerOutcome? o) => setState(() => _sonuc = o),
        ),
        const SizedBox(height: 12),
        // Premium (D-081): beğeni hakkını artırır, sınırsız yapmaz.
        if (!controller.hasFingerPremium) ...<Widget>[
          _PremiumCard(
            onBuy: () => setState(
              () => _sonuc = controller.buyFingerPremium(),
            ),
          ),
          const SizedBox(height: 12),
        ],
        // Seni beğenenler: buradan gelen beğeni kesin eşleşir.
        if (controller.fingerIncoming.isNotEmpty) ...<Widget>[
          const MenuGroupTitle(
            text: 'Seni beğenenler',
            accent: BirOmurAccents.gul,
          ),
          for (final FingerProfile p in controller.fingerIncoming) ...<Widget>[
            _MatchRow(
              key: Key('incoming_${p.id}'),
              profile: p,
              actionLabel: 'Sen de beğen',
              onMeet: () => setState(
                () => _sonuc = controller.likeFingerProfile(p.id),
              ),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
        ],
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
  const _MatchRow({
    super.key,
    required this.profile,
    required this.onMeet,
    this.actionLabel,
  });

  final FingerProfile profile;
  final VoidCallback onMeet;

  /// Düğmenin yazısı; boşsa "Tanış" kullanılır.
  ///
  /// "Seni beğenenler" listesinde düğme tanıştırmaz, **beğenir**.
  final String? actionLabel;

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
              child: Text(
                profile.isMet ? 'Tanıştın' : (actionLabel ?? 'Tanış'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Oyuncunun kendi Finger profili (D-081).
///
/// Faho'nun isteği: "bir finger profili oluşturalım, hobilerimi falan
/// sorsun, ona göre insanlar da beni beğenebilsin". Profil doldurmadan
/// kimse oyuncuyu kendiliğinden beğenmez.
class _SelfProfileCard extends StatefulWidget {
  const _SelfProfileCard({required this.onSaved});

  final void Function(FingerOutcome?) onSaved;

  @override
  State<_SelfProfileCard> createState() => _SelfProfileCardState();
}

class _SelfProfileCardState extends State<_SelfProfileCard> {
  bool _acik = false;
  String? _bio;
  late Set<String> _ilgiler;
  bool _yuklendi = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final GameController controller = GameScope.of(context);
    final GameState state = controller.state!;

    if (!_yuklendi) {
      _bio = state.fingerBio;
      _ilgiler = <String>{...state.fingerInterests};
      _yuklendi = true;
    }

    return Container(
      decoration: panelDecoration(context, radius: 16),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  state.hasFingerProfile ? 'Profilin' : 'Profilin boş',
                  style: theme.textTheme.titleSmall,
                ),
              ),
              TextButton(
                key: const Key('finger_profil_ac'),
                onPressed: () => setState(() => _acik = !_acik),
                child: Text(_acik ? 'Kapat' : 'Düzenle'),
              ),
            ],
          ),
          if (!_acik)
            Text(
              state.hasFingerProfile
                  ? '${state.fingerBio ?? ''}\n'
                      '${state.fingerInterests.join(', ')}'
                  : 'Profilini doldurmadan kimse seni kendiliğinden '
                      'beğenmez.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          if (_acik) ...<Widget>[
            const SizedBox(height: 8),
            Text('Kendini anlat', style: theme.textTheme.labelLarge),
            const SizedBox(height: 6),
            // RadioMenuButton kullanılmıştı; o bir **menü** bileşeni ve
            // etiketini sınırsız genişlikte yerleştiriyor. Uzun tanıtım
            // cümleleri satırı 271-325 piksel taşırıyordu (D-088).
            // Yerine metni saran, kendi satırında duran bir seçim satırı
            // kondu.
            for (final String metin in kFingerBios.take(6))
              _SecimSatiri(
                key: Key('finger_bio_${kFingerBios.indexOf(metin)}'),
                secili: _bio == metin,
                metin: metin,
                onTap: () => setState(() => _bio = metin),
              ),
            const SizedBox(height: 10),
            Text('İlgi alanların', style: theme.textTheme.labelLarge),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: <Widget>[
                for (final String ilgi in kFingerInterests)
                  FilterChip(
                    key: Key('finger_ilgi_$ilgi'),
                    label: Text(ilgi),
                    selected: _ilgiler.contains(ilgi),
                    onSelected: (bool secili) => setState(() {
                      if (secili) {
                        _ilgiler.add(ilgi);
                      } else {
                        _ilgiler.remove(ilgi);
                      }
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('finger_profil_kaydet'),
                onPressed: () {
                  final FingerOutcome? o = controller.saveFingerProfile(
                    bio: _bio ?? '',
                    interests: _ilgiler.toList(growable: false),
                  );
                  setState(() => _acik = false);
                  widget.onSaved(o);
                },
                child: const Text('Profili kaydet'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Premium üyelik kartı (D-081).
class _PremiumCard extends StatelessWidget {
  const _PremiumCard({required this.onBuy});

  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final GameController controller = GameScope.of(context);
    final InteractionAvailability izin = controller.fingerPremiumAvailability;

    return Container(
      decoration: panelDecoration(context, radius: 16),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Premium üyelik', style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            'Yılda $kFingerMaxLikesPerAge beğeni yerine '
            '$kFingerPremiumLikesPerAge beğeni. '
            'Ücreti ${trMoney(kFingerPremiumYearlyCost)}, bir yıl geçerli.',
            style: theme.textTheme.bodySmall,
          ),
          if (!izin.isAllowed)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                izin.reason!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              key: const Key('finger_premium_al'),
              onPressed: izin.isAllowed ? onBuy : null,
              child: const Text('Premium al'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Metni saran, tek satıra sıkışmayan seçim satırı (D-088).
///
/// Menü bileşenleri (RadioMenuButton, MenuItemButton) etiketlerini
/// sınırsız genişlikte yerleştirir ve uzun metinle ekranı taşırır. Bu
/// satır `Expanded` ile sarar, böylece dar telefonda da bozulmaz.
class _SecimSatiri extends StatelessWidget {
  const _SecimSatiri({
    super.key,
    required this.secili,
    required this.metin,
    required this.onTap,
  });

  final bool secili;
  final String metin;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              secili
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(metin, style: theme.textTheme.bodySmall),
            ),
          ],
        ),
      ),
    );
  }
}
