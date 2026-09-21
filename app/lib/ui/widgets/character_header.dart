import 'package:flutter/material.dart';

import '../../domain/models/game_settings.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/stats.dart';
import '../theme/bir_omur_theme.dart';
import 'kilim_divider.dart';
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

    // Ekranın en çok bakılan yeri: koyu, doygun bir degrade şerit. Gövde
    // açık kaldığı için ekranın üstü çerçeve gibi durur ve karakter
    // bilgisi günlükle karışmaz (Paket 16).
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            BirOmurColors.basligUst,
            BirOmurColors.basligAlt,
          ],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 14, 13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      state.player.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _WalletPill(label: state.player.walletLabel),
                  const SizedBox(width: 2),
                  _HeaderIconButton(
                    itemKey: const Key('open_settings'),
                    tooltip: 'Ayarlar',
                    icon: Icons.settings_rounded,
                    onPressed: () => SettingsSheet.show(context),
                  ),
                  if (onRestart != null)
                    _HeaderIconButton(
                      itemKey: const Key('new_life_button'),
                      tooltip: 'Yeni hayat',
                      icon: Icons.restart_alt_rounded,
                      onPressed: onRestart,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${state.player.age} yaşında · $evre · '
                '${state.player.birthCity}'
                // Kuşak bilgisi yalnızca gerçekten devam eden hayatlarda
                // yazılır; ilk kuşakta hiç görünmez.
                '${state.isContinuedGeneration ? ' · ${state.generation}. kuşak' : ''}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.82),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                _durumSatiri(state),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.62),
                ),
              ),
              const SizedBox(height: 9),
              const KilimDivider(height: 8, onDark: true),
              const SizedBox(height: 9),
              InkWell(
                onTap: () => _showStatDetails(context),
                borderRadius: BorderRadius.circular(14),
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

class _WalletPill extends StatelessWidget {
  const _WalletPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        // Cüzdan her temada pirinç rengidir; başlık zemini koyu olduğu
        // için doğrudan palet kullanılır.
        gradient: const LinearGradient(
          colors: <Color>[
            BirOmurColors.pirincAcik,
            BirOmurColors.pirinc,
          ],
        ),
        borderRadius: BorderRadius.circular(999),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: BirOmurColors.pirinc.withValues(alpha: 0.45),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.account_balance_wallet_rounded,
            size: 15,
            color: Color(0xFF4A2A00),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              color: Color(0xFF3A2000),
            ),
          ),
        ],
      ),
    );
  }
}

/// Başlık şeridindeki küçük, yuvarlak düğme.
class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
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
    return IconButton(
      key: itemKey,
      tooltip: tooltip,
      iconSize: 19,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(7),
      constraints: const BoxConstraints(),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.14),
        foregroundColor: Colors.white,
      ),
      onPressed: onPressed,
      icon: Icon(icon),
    );
  }
}

/// Üst şeritteki tek değer: sayı, ince çubuk ve kısa etiket.
class _StatPill extends StatelessWidget {
  const _StatPill({required this.entry});

  final StatEntry entry;

  @override
  Widget build(BuildContext context) {
    // Başlık zemini her temada koyudur; değer renkleri koyu zemin
    // karşılıklarından seçilir.
    final Color renk = statColorOnDark(entry.value);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        children: <Widget>[
          Text(
            '${entry.value}',
            style: TextStyle(
              fontSize: 15,
              height: 1.1,
              fontWeight: FontWeight.w900,
              color: renk,
            ),
          ),
          const SizedBox(height: 5),
          AnimatedStatBar(
            value: entry.value,
            color: renk,
            trackColor: Colors.white.withValues(alpha: 0.18),
          ),
          const SizedBox(height: 5),
          Text(
            entry.short,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.72),
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
