import 'package:flutter/material.dart';

import '../../state/game_scope.dart';
import 'family_screen.dart';
import 'life_screen.dart';
import 'me_screen.dart';

/// Alt gezinmede yer alan bir bölüm.
///
/// Bölümler listeden okunur; yeni bir alan (örneğin Sosyal) eklemek için
/// bu listeye bir kayıt eklemek yeterlidir (`docs/PROTOTYPE_UI.md` §1).
/// Beşten fazla bölüm gerektiğinde 'Daha Fazla' benzeri bir gruplamaya
/// geçilmesi gerekir; bu gezinme çözümü henüz kararlaştırılmadı.
class AppSection {
  const AppSection({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.builder,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final WidgetBuilder builder;
}

const List<AppSection> kAppSections = <AppSection>[
  AppSection(
    label: 'Hayat',
    icon: Icons.auto_stories_outlined,
    selectedIcon: Icons.auto_stories,
    builder: _lifeBuilder,
  ),
  AppSection(
    label: 'Aile',
    icon: Icons.groups_outlined,
    selectedIcon: Icons.groups,
    builder: _familyBuilder,
  ),
  AppSection(
    label: 'Ben',
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
    builder: _meBuilder,
  ),
];

Widget _lifeBuilder(BuildContext context) => const LifeScreen();
Widget _familyBuilder(BuildContext context) => const FamilyScreen();
Widget _meBuilder(BuildContext context) => const MeScreen();

/// Üç sekmeli ana kabuk.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  Future<void> _confirmNewLife() async {
    final bool? yes = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Yeni hayat'),
        content: const Text(
          'Bu hayatı bırakıp yeni bir hayata başlamak istiyor musun? '
          'Şu anki hayatın kaydedilmez.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yeni hayat'),
          ),
        ],
      ),
    );
    if (yes ?? false) {
      if (!mounted) return;
      GameScope.of(context).clearLife();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppSection section = kAppSections[_index];

    return Scaffold(
      appBar: AppBar(
        title: Text(section.label),
        actions: <Widget>[
          IconButton(
            tooltip: 'Yeni hayat',
            onPressed: _confirmNewLife,
            icon: const Icon(Icons.restart_alt),
          ),
        ],
      ),
      body: SafeArea(top: false, child: section.builder(context)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (int i) => setState(() => _index = i),
        destinations: <Widget>[
          for (final AppSection s in kAppSections)
            NavigationDestination(
              icon: Icon(s.icon),
              selectedIcon: Icon(s.selectedIcon),
              label: s.label,
            ),
        ],
      ),
    );
  }
}
