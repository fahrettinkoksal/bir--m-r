import 'package:flutter/material.dart';

import '../../domain/life/astrology.dart';
import '../../domain/models/game_settings.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/stats.dart';
import '../../domain/models/player_character.dart';
import '../../text/turkish_text.dart';
import '../theme/bir_omur_theme.dart';
import 'character_face.dart';
import 'comic.dart';
import 'settings_sheet.dart';
import 'stat_bar.dart';

/// Ekranın üstünde sabit duran karakter özeti.
///
/// İçerik: ad, yaş ve evre, şehir, kısa durum satırı, kişisel cüzdan ve
/// beş karakter değerinin sıkışmayan, okunaklı şeridi. Değer şeridine
/// dokunulduğunda ayrıntılı liste açılır.
class CharacterHeader extends StatelessWidget {
  const CharacterHeader({super.key, required this.state, this.onRestart});

  final GameState state;

  /// Yeni hayat başlatma eylemi; verilmezse düğme gösterilmez.
  final VoidCallback? onRestart;

  void _showStatDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) => _StatDetailSheet(state: state),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String evre = state.education.stageLabel(state.player.age);

    // Üst özet artık renkli bir şerit değil, kâğıda yapıştırılmış bir
    // künye kartı: solda karakterin çizilmiş yüzü, sağında adı ve
    // değerleri (Paket 19).
    return Container(
      color: theme.colorScheme.surface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
          child: ComicCard(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _FaceBadge(player: state.player),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Flexible(
                                child: Text(
                                  state.player.fullName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleLarge,
                                ),
                              ),
                              const SizedBox(width: 7),
                              // Paket 28: rozet biraz küçüldü; "Tolga
                              // Erdoğan · 250.000 ₺" gibi dolu bir
                              // satırda ad kırpılmasın diye.
                              ComicTag(
                                // Kısaltılmış: tam tutar Varlıklar
                                // ekranında yazar. Uzun tutar burada adı
                                // kırpıyordu (Paket 30).
                                text: trMoneyShort(state.player.wallet),
                                color: BirOmurColors.sari,
                                tilt: -2,
                                fontSize: 11.5,
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${state.player.age} yaşında · $evre'
                            '${state.isContinuedGeneration ? ' · ${state.generation}. kuşak' : ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            // Burç bu satırda: üst satır yaş ve eğitim
                            // evresiyle dolu, oraya eklenince
                            // kırpılıyordu (Paket 27).
                            '${state.player.birthCity} · '
                            '${Astrology.zodiacOf(state).display} · '
                            '${_durumSatiri(state)}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      children: <Widget>[
                        _RoundIconButton(
                          itemKey: const Key('open_settings'),
                          tooltip: 'Ayarlar',
                          icon: Icons.settings_rounded,
                          onPressed: () => SettingsSheet.show(context),
                        ),
                        if (onRestart != null) ...<Widget>[
                          const SizedBox(height: 4),
                          _RoundIconButton(
                            itemKey: const Key('new_life_button'),
                            tooltip: 'Yeni hayat',
                            icon: Icons.restart_alt_rounded,
                            onPressed: onRestart,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => _showStatDetails(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: <Widget>[
                        for (final StatEntry entry in state.player.stats.entries)
                          Expanded(child: _StatPill(entry: entry)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _durumSatiri(GameState state) {
    final int hane = state.household.length;
    final String haneMetni = hane == 0
        ? 'Evde seninle yaşayan kimse yok'
        : 'Evde seninle $hane kişi yaşıyor';

    // Bakım durumu ve geçim sıkıntısı gerçek kayıtlardan okunur (D-033,
    // D-037); yalnızca olağandışı durumlarda yazılır.
    final List<String> ekler = <String>[
      if (state.careStatus != CareStatus.aileYaninda)
        state.careStatus.label.toLowerCase(),
      if (state.hardshipYears > 0) 'geçim sıkıntısı',
    ];
    return ekler.isEmpty ? haneMetni : '$haneMetni · ${ekler.join(' · ')}';
  }
}

/// Karakterin yüzünü taşıyan yuvarlak künye.
class _FaceBadge extends StatelessWidget {
  const _FaceBadge({required this.player});

  final PlayerCharacter player;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? BirOmurColors.geceZemin
            : BirOmurColors.kagitKoyu,
        shape: BoxShape.circle,
        border: Border.all(color: Comic.konturOf(context), width: Comic.kontur),
        boxShadow: comicShadow(context, offset: Comic.kucukGolge),
      ),
      child: ClipOval(
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: CharacterFace(player: player, size: 54),
        ),
      ),
    );
  }
}

/// Başlıktaki küçük, yuvarlak düğme.
class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.itemKey,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final Key? itemKey;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: StickerButton(
        key: itemKey,
        onPressed: onPressed,
        color: theme.colorScheme.surfaceContainer,
        radius: 999,
        shadowOffset: 2.5,
        padding: const EdgeInsets.all(7),
        child: Icon(icon, size: 17, color: theme.colorScheme.onSurface),
      ),
    );
  }
}

/// Üst şeritteki tek değer: sayı, ince çubuk ve kısa etiket.
class _StatPill extends StatelessWidget {
  const _StatPill({required this.entry});

  final StatEntry entry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color renk = statColorOnDark(entry.value);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        children: <Widget>[
          Text(
            '${entry.value}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedStatBar(value: entry.value, color: renk, minHeight: 11),
          const SizedBox(height: 4),
          Text(
            entry.short,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDetailSheet extends StatelessWidget {
  const _StatDetailSheet({required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Karakter değerleri', style: theme.textTheme.titleLarge),
            const SizedBox(height: 14),
            for (final StatEntry entry in state.player.stats.entries) ...<Widget>[
              StatBar(label: entry.label, value: entry.value),
              const SizedBox(height: 14),
            ],
            // Ün açılmadıysa hiç gösterilmez (D-027).
            if (state.player.fameUnlocked)
              StatBar(label: 'Ün', value: state.player.fame!),
          ],
        ),
      ),
    );
  }
}
