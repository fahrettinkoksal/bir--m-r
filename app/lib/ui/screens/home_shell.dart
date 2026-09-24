import 'package:flutter/material.dart';

import '../../domain/models/game_event.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/person.dart';
import '../../state/game_controller.dart';
import '../../state/game_scope.dart';
import '../theme/bir_omur_theme.dart';
import '../widgets/bottom_action_bar.dart';
import '../widgets/character_header.dart';
import '../widgets/comic.dart';
import '../widgets/event_dialog.dart';
import '../widgets/health_crisis_sheet.dart';
import '../widgets/notice_sheet.dart';
import '../widgets/after_school_choice_sheet.dart';
import '../widgets/track_choice_sheet.dart';
import '../../domain/life/will.dart';
import '../../domain/models/pending_notice.dart';
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

  /// Aynı anda yalnızca tek sağlık krizi penceresi açılır.
  bool _crisisVisible = false;

  /// Aynı anda yalnızca tek bildirim penceresi açılır (D-050).
  bool _noticeVisible = false;

  /// Bekleyen önemli haberi gösterir.
  ///
  /// Sağlık krizinden **sonra**, olay penceresinden **önce** gelir; mevcut
  /// bekleyen olay ezilmez, sırayla gösterilir.
  void _showNotice(PendingNotice notice) {
    if (_noticeVisible) return;
    _noticeVisible = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final NavigatorState navigator =
          Navigator.of(context, rootNavigator: true);
      navigator.popUntil((Route<dynamic> route) => route.isFirst);
      await NoticeSheet.show(context, notice);
      if (!mounted) return;
      setState(() => _noticeVisible = false);
    });
  }

  void _showCrisis() {
    if (_crisisVisible) return;
    _crisisVisible = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final NavigatorState navigator =
          Navigator.of(context, rootNavigator: true);
      navigator.popUntil((Route<dynamic> route) => route.isFirst);
      await HealthCrisisSheet.show(context);
      if (!mounted) return;
      setState(() => _crisisVisible = false);
    });
  }

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

  /// Aynı anda yalnızca tek eğitim seçimi penceresi açılır (D-094, D-111).
  bool _educationChoiceVisible = false;

  /// Bekleyen eğitim kararını **hemen** sorar (D-094, D-111).
  ///
  /// Faho bildirdi: karar bir sonraki "Yaş Al"a kalıyordu, yani oyuncu
  /// lise alanını seçmeden o yılın bütün aktivitelerini yapabiliyordu.
  /// Karar artık ortaya çıktığı anda sorulur.
  Future<void> _showEducationChoice() async {
    if (_educationChoiceVisible) return;
    final GameController controller = GameScope.of(context);
    if (!controller.needsEducationChoice) return;
    _educationChoiceVisible = true;
    if (controller.needsTrackChoice) {
      await TrackChoiceSheet.show(context);
    } else {
      await AfterSchoolChoiceSheet.show(context);
    }
    if (!mounted) return;
    setState(() => _educationChoiceVisible = false);
  }

  void _ageUp() {
    final GameController controller = GameScope.of(context);
    // Eğitim kararı verilmeden yaş atlanamaz; düğme sessiz kalmaz, seçim
    // ekranı açılır (D-094, D-111).
    if (controller.needsEducationChoice) {
      _goHome();
      _showEducationChoice();
      return;
    }
    controller.ageUp();
    // Yaş alınca yeni günlük satırı ve olay görünsün diye ana ekrana dönülür.
    _goHome();
    // Bu yıl liseye ya da mezuniyete gelindiyse karar **hemen** sorulur;
    // bir sonraki yıla ertelenmez.
    if (controller.needsEducationChoice) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showEducationChoice();
      });
    }
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

  /// **Çocuğum olarak devam et** (Paket E3).
  ///
  /// Hayatta çocuk yoksa bu akış hiç açılmaz; seçenek de gösterilmez.
  Future<void> _continueAsChild() async {
    final GameState? mevcut = GameScope.of(context).state;
    final List<Person> cocuklar = GameScope.of(context).generationHeirs;
    if (mevcut == null || cocuklar.isEmpty) return;
    final int oyuncuYasi = mevcut.deathAge ?? mevcut.player.age;
    // Vasiyetteki mirasçı yalnızca **önerilen** olarak işaretlenir;
    // oyuncu istediği çocuğu seçmekte serbesttir (D-052).
    final String? mirasciId = Will.effectiveHeirId(mevcut);

    final String? secilen = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Kimin hayatıyla devam edilsin?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Hayatın arşive yazılır ve seçtiğin çocuğun hayatından '
              'devam edersin. Mirasın payına düşen kısmı ona geçer; '
              'mesleğin, eğitimin ve ünün taşınmaz.',
            ),
            const SizedBox(height: 12),
            for (final Person cocuk in cocuklar)
              ListTile(
                key: Key('continue_child_${cocuk.id}'),
                contentPadding: EdgeInsets.zero,
                title: Text(cocuk.fullName),
                subtitle: Text(
                  '${cocuk.labelFor(oyuncuYasi)} · ${cocuk.age} yaşında'
                  '${cocuk.id == mirasciId ? ' · vasiyetinde mirasçı' : ''}',
                ),
                onTap: () => Navigator.of(context).pop(cocuk.id),
              ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Vazgeç'),
          ),
        ],
      ),
    );

    if (secilen == null || !mounted) return;
    final String engel = GameScope.of(context).continueAsChild(secilen);
    if (!mounted) return;
    if (engel.isNotEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(engel)));
      return;
    }
    setState(() {
      _archiveVisible = false;
      _selectedTab = null;
    });
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
                  onContinueAsChild: _continueAsChild,
                  onShowArchive: () =>
                      setState(() => _archiveVisible = true),
                ),
        ),
      );
    }

    // Sağlık krizi, olaylardan önce ekrana gelir (D-044).
    if (state.hasPendingCrisis) _showCrisis();

    // Önemli haberler (ölüm, miras, cenaze) krizden sonra, olaydan önce.
    final PendingNotice? notice = state.nextNotice;
    if (notice != null && !state.hasPendingCrisis) _showNotice(notice);

    final ActiveEvent? pending = state.pendingEvent;
    if (pending != null && !state.hasPendingCrisis && !state.hasNotice) {
      _showPendingEvent(pending);
    }

    // Soldaki menü oyuncunun durumuna göre Okul veya Meslek olur (NAV-001).
    final List<BottomTab> tabs = <BottomTab>[
      BottomTab(
        id: TabIds.okulMeslek,
        label: SchoolCareerScreen.labelFor(state),
        accent: BirOmurAccents.mavi,
        icon: state.education.isStudent
            ? Icons.school_outlined
            : Icons.work_outline,
        activeIcon:
            state.education.isStudent ? Icons.school : Icons.work,
      ),
      const BottomTab(
        id: TabIds.varliklar,
        label: 'Varlıklar',
        accent: BirOmurAccents.yesil,
        icon: Icons.inventory_2_outlined,
        activeIcon: Icons.inventory_2,
      ),
      const BottomTab(
        id: TabIds.iliskiler,
        label: 'İlişkiler',
        accent: BirOmurAccents.gul,
        icon: Icons.favorite_outline,
        activeIcon: Icons.favorite,
      ),
      const BottomTab(
        id: TabIds.aktiviteler,
        label: 'Aktiviteler',
        accent: BirOmurAccents.turuncu,
        icon: Icons.local_activity_outlined,
        activeIcon: Icons.local_activity,
      ),
    ];

    return Scaffold(
      // Bütün gövde çizim kâğıdının üzerinde durur (Paket 19).
      body: PaperBackground(
        child: Column(
          children: <Widget>[
            CharacterHeader(state: state, onRestart: _confirmNewLife),
            Expanded(child: _body()),
          ],
        ),
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
