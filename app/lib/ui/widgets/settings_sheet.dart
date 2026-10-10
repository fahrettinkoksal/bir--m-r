import 'package:flutter/material.dart';

import '../sound/sound_scope.dart';
import '../sound/sound_service.dart';

import '../../domain/features/feature_catalog.dart';
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
              // Ses efektleri (Paket 15): kapatıldığında oyun tamamen
              // sessiz çalışır ve ayar kayıtla birlikte saklanır.
              SwitchListTile(
                key: const Key('settings_sound_toggle'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Ses efektleri'),
                subtitle: Text(
                  ayarlar.soundEnabled
                      ? 'Menü, seçim ve bildirim sesleri açık.'
                      : 'Oyun tamamen sessiz çalışıyor.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                value: ayarlar.soundEnabled,
                onChanged: (bool acik) {
                  controller.updateSettings(
                    ayarlar.copyWith(soundEnabled: acik),
                  );
                  SoundScope.maybeOf(context)?.enabled = acik;
                  // Açıldığını duyurmak için kısa bir ses.
                  if (acik) SoundScope.play(context, GameSound.select);
                  setState(() {});
                },
              ),
              const SizedBox(height: 4),
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
              const KilimDivider(),
              const SizedBox(height: 14),
              // --- Görünüm (Paket BQ) -----------------------------------
              //
              // Koyu tema oyunda baştan beri vardı ama oyuncu
              // seçemiyordu: uygulamanın kökü `ThemeMode.system` ile
              // sabitti. Seçim artık kayıtta duruyor.
              Text('Görünüm', style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                'Cihazının ayarını izleyebilir ya da kendin '
                'seçebilirsin.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final AppThemeChoice secim in AppThemeChoice.values)
                    ChoiceChip(
                      key: Key('settings_theme_${secim.saveKey}'),
                      label: Text(secim.label),
                      selected: ayarlar.themeChoice == secim,
                      onSelected: (_) {
                        controller.updateSettings(
                          ayarlar.copyWith(themeChoice: secim),
                        );
                        setState(() {});
                      },
                    ),
                ],
              ),
              const SizedBox(height: 18),
              const KilimDivider(),
              const SizedBox(height: 14),
              // --- Modüller (Paket BL) ----------------------------------
              //
              // Sonradan eklenen her özellik buradan kapatılabilir.
              // Kapalı modül ekranda yer tutmaz; kapatınca neyin
              // kaybolduğu satırın altında yazar.
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text('Modüller', style: theme.textTheme.titleMedium),
                  ),
                  if (!ayarlar.features.allDefault)
                    TextButton(
                      key: const Key('settings_features_reset'),
                      onPressed: () {
                        controller.resetFeatures();
                        setState(() {});
                      },
                      child: const Text('Hepsini aç'),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Sonradan eklenen özellikler. Kapattığın modül oyunda hiç '
                'görünmez; oyunun geri kalanı aynı şekilde çalışır. '
                'Ayarı bu hayatın kaydında durur.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              for (final MapEntry<String, List<FeatureId>> grup
                  in FeatureId.byPaket.entries) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  grup.key,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                for (final FeatureId modul in grup.value)
                  SwitchListTile(
                    key: Key('settings_feature_${modul.saveKey}'),
                    contentPadding: EdgeInsets.zero,
                    title: Text(modul.title),
                    subtitle: Text(
                      ayarlar.features.isOn(modul)
                          ? 'Açık.'
                          : 'Kapalı. ${modul.lostWhenOff}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    value: ayarlar.features.isOn(modul),
                    onChanged: (bool acik) {
                      controller.setFeature(modul, acik);
                      setState(() {});
                    },
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
