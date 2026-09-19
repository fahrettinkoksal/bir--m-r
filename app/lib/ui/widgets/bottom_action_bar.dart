import 'package:flutter/material.dart';

import '../theme/bir_omur_theme.dart';

/// Alt gezinmedeki bir ana menü.
class BottomTab {
  const BottomTab({
    required this.id,
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String id;
  final String label;
  final IconData icon;
  final IconData activeIcon;
}

/// Alt sabit gezinme çubuğu (NAV-001).
///
/// Soldan sağa: iki ana menü — ortada bağımsız **Yaş Al** eylem düğmesi —
/// iki ana menü. `Yaş Al` bir sekme değildir; menülerin arasında duran ana
/// oyun eylemidir ve seçili sekmeyi değiştirmez.
///
/// Görsel dil Bir Ömür'e özgüdür: sıcak koyu ahşap zemin, krem ikonlar ve
/// ortada nar kırmızısı, pirinç halkalı yükseltilmiş eylem düğmesi.
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
    final List<BottomTab> sol = tabs.sublist(0, 2);
    final List<BottomTab> sag = tabs.sublist(2);

    return Container(
      decoration: const BoxDecoration(color: BirOmurColors.koyuAhsap),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 74,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              for (final BottomTab tab in sol)
                Expanded(child: _TabButton(tab: tab, onTap: onTabSelected, selectedId: selectedId)),
              _AgeUpButton(onPressed: ageUpEnabled ? onAgeUp : null),
              for (final BottomTab tab in sag)
                Expanded(child: _TabButton(tab: tab, onTap: onTabSelected, selectedId: selectedId)),
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
    final bool secili = selectedId == tab.id;
    final Color renk =
        secili ? BirOmurColors.pirinc : BirOmurColors.sonukKrem;

    return Semantics(
      selected: secili,
      button: true,
      child: InkWell(
        key: Key('tab_${tab.id}'),
        onTap: () => onTap(tab.id),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(secili ? tab.activeIcon : tab.icon, size: 23, color: renk),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                tab.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.1,
                  color: renk,
                  fontWeight: secili ? FontWeight.w800 : FontWeight.w600,
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
    final bool aktif = onPressed != null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Semantics(
        button: true,
        label: 'Yaş Al',
        child: InkWell(
          key: const Key('age_up_button'),
          onTap: onPressed,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: 74,
            height: 60,
            decoration: BoxDecoration(
              color: aktif
                  ? BirOmurColors.nar
                  : BirOmurColors.nar.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: BirOmurColors.pirinc.withValues(alpha: aktif ? 0.85 : 0.3),
                width: 2,
              ),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(Icons.cake_outlined, color: Color(0xFFFDF6EC), size: 22),
                SizedBox(height: 2),
                Text(
                  'Yaş Al',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFFDF6EC),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
