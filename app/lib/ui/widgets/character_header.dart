import 'package:flutter/material.dart';

import '../../domain/models/game_settings.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/stats.dart';
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

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      state.player.fullName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _WalletPill(label: state.player.walletLabel),
                  IconButton(
                    key: const Key('open_settings'),
                    tooltip: 'Ayarlar',
                    iconSize: 18,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.only(left: 6),
                    constraints: const BoxConstraints(),
                    onPressed: () => SettingsSheet.show(context),
                    icon: const Icon(Icons.settings_outlined),
                  ),
                  if (onRestart != null)
                    IconButton(
                      tooltip: 'Yeni hayat',
                      iconSize: 18,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.only(left: 6),
                      constraints: const BoxConstraints(),
                      onPressed: onRestart,
                      icon: const Icon(Icons.restart_alt),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${state.player.age} yaşında · $evre · '
                '${state.player.birthCity}'
                // Kuşak bilgisi yalnızca gerçekten devam eden hayatlarda
                // yazılır; ilk kuşakta hiç görünmez.
                '${state.isContinuedGeneration ? ' · ${state.generation}. kuşak' : ''}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _durumSatiri(state),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              const KilimDivider(height: 8),
              const SizedBox(height: 10),
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
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiary.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.colorScheme.tertiary.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 15,
            color: theme.colorScheme.onSurface,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        children: <Widget>[
          Text(
            '${entry.value}',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: statColor(theme, entry.value),
            ),
          ),
          const SizedBox(height: 4),
          AnimatedStatBar(
            value: entry.value,
            color: statColor(theme, entry.value),
          ),
          const SizedBox(height: 4),
          Text(
            entry.short,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
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
