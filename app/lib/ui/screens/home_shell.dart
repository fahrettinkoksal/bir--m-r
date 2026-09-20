import 'package:flutter/material.dart';

import '../../domain/models/game_event.dart';
import '../../domain/models/game_state.dart';
import '../../state/game_scope.dart';
import '../widgets/bottom_action_bar.dart';
import '../widgets/character_header.dart';
import '../widgets/event_dialog.dart';
import 'life_screen.dart';
import 'life_summary_screen.dart';
import 'past_lives_screen.dart';
import 'sections/activities_screen.dart';
import 'sections/assets_screen.dart';
import 'sections/relationships_screen.dart';
import 'sections/school_career_screen.dart';

/// Ana menü kimlikleri (NAV-001).
abstract final class TabIds {
  static const String okulMeslek = 'okul_meslek';
  static const String varliklar = 'varliklar';
  static const String iliskiler = 'iliskiler';
  static const String aktiviteler = 'aktiviteler';
}

/// Uygulamanın ana kabuğu.
///
/// Düzen: üstte sabit karakter özeti, ortada hayat günlüğü veya seçilen ana
/// menünün ekranı, altta sabit gezinme çubuğu. Alt çubukta soldan sağa
/// `Okul/Meslek` — `Varlıklar` — **Yaş Al** — `İlişkiler` — `Aktiviteler`
/// bulunur; `Yaş Al` bir sekme değil, ortadaki bağımsız ana eylemdir.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  /// Seçili ana menü; `null` ise ana hayat ekranı açıktır.
  String? _selectedTab;

  /// Aynı anda yalnızca tek olay penceresi açılır (D-021).
  bool _eventVisible = false;

  /// Hayat tamamlandığında Geçmiş Hayatlar arşivi açık mı?
  bool _archiveVisible = false;

  void _showPendingEvent(ActiveEvent event) {
    if (_eventVisible) return;
    _eventVisible = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final NavigatorState navigator = Navigator.of(context, rootNavigator: true);
      navigator.popUntil((Route<dynamic> route) => route.isFirst);
      await EventDialog.show(context, event);
      if (!mounted) return;
      setState(() => _eventVisible = false);
    });
  }

  void _onTabSelected(String id) {
    // Seçili menüye tekrar dokunmak hayat ekranına döndürür.
    setState(() => _selectedTab = _selectedTab == id ? null : id);
  }

  void _goHome() => setState(() => _selectedTab = null);

  void _ageUp() {
    GameScope.of(context).ageUp();
    // Yaş alınca yeni günlük satırı ve olay görünsün diye ana ekrana dönülür.
    _goHome();
  }

  Future<void> _confirmNewLife() async {
    final bool? yes = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Yeni hayat'),
        content: Text(
          GameScope.of(context).isDeceased
              ? 'Tamamlanan hayatın yerine yeni bir hayat başlatılacak. '
                  'Bu hayatın kaydı silinir. Devam edilsin mi?'
              : 'Bu hayatı bırakıp yeni bir hayata başlamak istiyor musun? '
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
    if ((yes ?? false) && mounted) {
      GameScope.of(context).clearLife();
    }
  }

  Widget _body() {
    switch (_selectedTab) {
      case TabIds.okulMeslek:
        return SchoolCareerScreen(onBack: _goHome);
      case TabIds.varliklar:
        return AssetsScreen(onBack: _goHome);
      case TabIds.iliskiler:
        return RelationshipsScreen(onBack: _goHome);
      case TabIds.aktiviteler:
        return ActivitiesScreen(onBack: _goHome);
      default:
        return const LifeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final GameState state = GameScope.of(context).state!;

    // Hayat tamamlandıysa özet ekranı gösterilir; yaş alma ve menüler
    // kapanır. Kayıt silinmez, yeni hayat ancak onayla başlar.
    if (state.deceased) {
      return Scaffold(
        body: SafeArea(
          child: _archiveVisible
              ? PastLivesScreen(
                  lives: state.pastLives,
                  backLabel: 'Hayat özeti',
                  onBack: () => setState(() => _archiveVisible = false),
                )
              : LifeSummaryScreen(
                  onNewLife: _confirmNewLife,
                  onShowArchive: () =>
                      setState(() => _archiveVisible = true),
                ),
        ),
      );
    }

    final ActiveEvent? pending = state.pendingEvent;
    if (pending != null) _showPendingEvent(pending);

    // Soldaki menü oyuncunun durumuna göre Okul veya Meslek olur (NAV-001).
    final List<BottomTab> tabs = <BottomTab>[
      BottomTab(
        id: TabIds.okulMeslek,
        label: SchoolCareerScreen.labelFor(state),
        icon: state.education.isStudent
            ? Icons.school_outlined
            : Icons.work_outline,
        activeIcon:
            state.education.isStudent ? Icons.school : Icons.work,
      ),
      const BottomTab(
        id: TabIds.varliklar,
        label: 'Varlıklar',
        icon: Icons.inventory_2_outlined,
        activeIcon: Icons.inventory_2,
      ),
      const BottomTab(
        id: TabIds.iliskiler,
        label: 'İlişkiler',
        icon: Icons.favorite_outline,
        activeIcon: Icons.favorite,
      ),
      const BottomTab(
        id: TabIds.aktiviteler,
        label: 'Aktiviteler',
        icon: Icons.local_activity_outlined,
        activeIcon: Icons.local_activity,
      ),
    ];

    return Scaffold(
      body: Column(
        children: <Widget>[
          CharacterHeader(state: state, onRestart: _confirmNewLife),
          Expanded(child: _body()),
        ],
      ),
      bottomNavigationBar: BottomActionBar(
        tabs: tabs,
        selectedId: _selectedTab,
        onTabSelected: _onTabSelected,
        onAgeUp: _ageUp,
        ageUpEnabled: !state.hasPendingEvent,
      ),
    );
  }
}
