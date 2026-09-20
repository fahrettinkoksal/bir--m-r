import 'package:flutter/material.dart';

import '../../domain/models/game_settings.dart';
import '../../state/game_controller.dart';
import '../../state/game_scope.dart';
import 'kilim_divider.dart';
import '../../text/turkish_text.dart';

/// Oyuncu ayarları.
///
/// Kumarhane **isteğe bağlı bir modüldür**: buradan kapatılınca menüde hiç
/// görünmez. Oyuncu ayrıca kendisi için **isteğe bağlı bir yıllık bahis
/// limiti** koyabilir (D-032). Limit dolduğunda yalnızca nötr bir bilgi
/// gösterilir; oyuncu daha fazla oynamaya teşvik edilmez.
class SettingsSheet extends StatefulWidget {
  const SettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext context) => const SettingsSheet(),
    );
  }

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  /// prototypeOnly: seçilebilen yıllık kendi limiti adımları.
  static const List<int?> _limitSecenekleri = <int?>[
    null,
    10000,
    25000,
    50000,
    100000,
  ];

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final GameController controller = GameScope.of(context);
    final GameSettings ayarlar =
        controller.state?.settings ?? const GameSettings();

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Ayarlar', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 12),
              const KilimDivider(),
              const SizedBox(height: 14),
              SwitchListTile(
                key: const Key('settings_casino_toggle'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Kumarhane'),
                subtitle: Text(
                  ayarlar.casinoEnabled
                      ? 'Aktiviteler menüsünde görünüyor.'
                      : 'Tamamen kapalı; menüde görünmüyor.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                value: ayarlar.casinoEnabled,
                onChanged: (bool acik) {
                  controller.updateSettings(
                    ayarlar.copyWith(casinoEnabled: acik),
                  );
                  setState(() {});
                },
              ),
              if (ayarlar.casinoEnabled) ...<Widget>[
                const SizedBox(height: 10),
                Text(
                  'Kendi yıllık bahis limitin',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'İstersen kendine bir sınır koyabilirsin. Oyun ayrıca '
                  'gelirine ve cüzdanına göre bir yıllık bütçe hesaplar; '
                  'hangisi düşükse o geçerli olur.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    for (final int? limit in _limitSecenekleri)
                      ChoiceChip(
                        key: Key('settings_limit_${limit ?? 'yok'}'),
                        label: Text(limit == null ? 'Sınır yok' : trMoney(limit)),
                        selected: ayarlar.wagerLimitPerAge == limit,
                        onSelected: (_) {
                          controller.updateSettings(
                            ayarlar.copyWith(wagerLimitPerAge: limit),
                          );
                          setState(() {});
                        },
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Kapat'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
