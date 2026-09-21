import 'package:flutter/material.dart';

import '../sound/sound_scope.dart';
import '../sound/sound_service.dart';
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            BirOmurColors.koyuAhsap,
            BirOmurColors.koyuAhsapDip,
          ],
        ),
        border: Border(
          top: BorderSide(color: Color(0x33D69A2B), width: 1.2),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 78,
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
        onTap: () {
          SoundScope.play(context, GameSound.tap);
          onTap(tab.id);
        },
        borderRadius: BorderRadius.circular(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Seçili sekmenin ikonu renkli bir hapın içinde durur; hangi
            // menüde olunduğu ilk bakışta görülür.
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: secili
                    ? BirOmurColors.pirinc.withValues(alpha: 0.20)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(
                secili ? tab.activeIcon : tab.icon,
                size: 22,
                color: renk,
              ),
            ),
            const SizedBox(height: 3),
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
          onTap: onPressed == null
              ? null
              : () {
                  SoundScope.play(context, GameSound.ageUp);
                  onPressed!();
                },
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 78,
            height: 62,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: aktif
                    ? const <Color>[BirOmurColors.nar, BirOmurColors.narKoyu]
                    : <Color>[
                        BirOmurColors.nar.withValues(alpha: 0.35),
                        BirOmurColors.narKoyu.withValues(alpha: 0.35),
                      ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: BirOmurColors.pirinc.withValues(alpha: aktif ? 0.9 : 0.25),
                width: 2,
              ),
              boxShadow: aktif
                  ? <BoxShadow>[
                      BoxShadow(
                        color: BirOmurColors.nar.withValues(alpha: 0.55),
                        blurRadius: 16,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : const <BoxShadow>[],
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(Icons.cake_outlined, color: BirOmurColors.krem, size: 23),
                SizedBox(height: 2),
                Text(
                  'Yaş Al',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                    color: BirOmurColors.krem,
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
