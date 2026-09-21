import 'package:flutter/material.dart';

import '../sound/sound_scope.dart';
import '../sound/sound_service.dart';
import '../theme/bir_omur_theme.dart';
import 'comic.dart';

/// Alt gezinmedeki bir ana menü.
class BottomTab {
  const BottomTab({
    required this.id,
    required this.label,
    required this.icon,
    required this.activeIcon,
    this.accent = BirOmurAccents.mavi,
  });

  final String id;
  final String label;
  final IconData icon;
  final IconData activeIcon;

  /// Seçiliyken arkasında beliren çıkartmanın rengi.
  final BirOmurAccent accent;
}

/// Alt sabit gezinme çubuğu (NAV-001).
///
/// Soldan sağa: iki ana menü — ortada bağımsız **Yaş Al** eylem düğmesi —
/// iki ana menü. `Yaş Al` bir sekme değildir; menülerin arasında duran ana
/// oyun eylemidir ve seçili sekmeyi değiştirmez.
///
/// Görsel dil çizgi romandır (Paket 19): kâğıt zemin, üstte kalın mürekkep
/// çizgisi, seçili sekmenin arkasında renkli bir çıkartma ve ortada
/// basınca çöken kırmızı bir düğme.
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({
    super.key,
    required this.tabs,
    required this.selectedId,
    required this.onTabSelected,
    required this.onAgeUp,
    this.ageUpEnabled = true,
  });

  /// Tam olarak dört ana menü beklenir: ikisi solda, ikisi sağda.
  final List<BottomTab> tabs;

  /// Seçili menü; `null` ise ana hayat ekranı açıktır.
  final String? selectedId;
  final void Function(String id) onTabSelected;
  final VoidCallback onAgeUp;
  final bool ageUpEnabled;

  @override
  Widget build(BuildContext context) {
    assert(tabs.length == 4, 'Alt gezinmede dört ana menü olmalı (NAV-001).');
    final ThemeData theme = Theme.of(context);
    final List<BottomTab> sol = tabs.sublist(0, 2);
    final List<BottomTab> sag = tabs.sublist(2);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(color: Comic.konturOf(context), width: Comic.kontur),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 80,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              for (final BottomTab tab in sol)
                Expanded(
                  child: _TabButton(
                    tab: tab,
                    onTap: onTabSelected,
                    selectedId: selectedId,
                  ),
                ),
              _AgeUpButton(onPressed: ageUpEnabled ? onAgeUp : null),
              for (final BottomTab tab in sag)
                Expanded(
                  child: _TabButton(
                    tab: tab,
                    onTap: onTabSelected,
                    selectedId: selectedId,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.tab,
    required this.onTap,
    required this.selectedId,
  });

  final BottomTab tab;
  final void Function(String id) onTap;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool secili = selectedId == tab.id;

    return Semantics(
      selected: secili,
      button: true,
      child: InkWell(
        key: Key('tab_${tab.id}'),
        onTap: () {
          SoundScope.play(context, GameSound.tap);
          onTap(tab.id);
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Seçili sekmenin ikonu renkli bir çıkartmanın içinde durur.
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              width: 42,
              height: 34,
              decoration: BoxDecoration(
                color: secili ? tab.accent.color : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: secili
                      ? Comic.konturOf(context)
                      : Colors.transparent,
                  width: Comic.inceKontur,
                ),
              ),
              child: Icon(
                secili ? tab.activeIcon : tab.icon,
                size: 21,
                color: secili
                    ? tab.accent.onColor
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                tab.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  fontWeight: secili ? FontWeight.w800 : FontWeight.w600,
                  color: secili
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ortadaki bağımsız ana eylem düğmesi.
class _AgeUpButton extends StatelessWidget {
  const _AgeUpButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Semantics(
        button: true,
        label: 'Yaş Al',
        child: StickerButton(
          key: const Key('age_up_button'),
          onPressed: onPressed,
          color: BirOmurColors.kirmizi,
          radius: 20,
          sound: GameSound.ageUp,
          shadowOffset: 5,
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 7),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.cake_rounded, color: BirOmurColors.krem, size: 24),
              SizedBox(height: 1),
              Text(
                'Yaş Al',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  color: BirOmurColors.krem,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
