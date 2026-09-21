import 'package:flutter/material.dart';

import '../../../data/activity_catalog.dart';
import '../../../data/social_catalog.dart';
import '../../../data/license_catalog.dart';
import '../../../domain/casino/casino_rules.dart';
import '../../../domain/interaction/adoption.dart';
import '../../../domain/models/game_state.dart';
import '../../../domain/models/person.dart';
import '../../../state/game_scope.dart';
import '../../widgets/person_card.dart';
import '../../widgets/person_detail_sheet.dart';
import '../../widgets/section_scaffold.dart';
import 'activity_pages.dart';
import 'casino_pages.dart';
import 'license_pages.dart';
import 'social_pages.dart';

/// Aktiviteler ana menüsü (NAV-001).
///
/// İç içe menü mantığıyla kurulmuştur: ana ekranda kategoriler, kategorinin
/// içinde gerçek eylemler. **Yalnızca gerçekten çalışan şeyler gösterilir**;
/// spor salonu, berber ve seyahat gibi henüz yazılmamış alanlar sahte
/// düğme olarak konmaz.
class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

/// Aktiviteler alt sayfaları.
enum _ActivityPage {
  kok,
  sosyal,
  berber,
  spor,
  kutuphane,
  sosyalMedya,
  kumarhane,
  ehliyet,
  evlatEdinme,
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  _ActivityPage _page = _ActivityPage.kok;

  void _go(_ActivityPage page) => setState(() => _page = page);

  /// Şu an gündelik hayatta gerçekten erişilebilen ve etkileşim kurulabilen
  /// kişiler.
  ///
  /// Yıllar önce tanışılmış bir ilkokul öğretmeni kayıtta kalır ama her gün
  /// görüşülen biri değildir; bu liste [GameState.isReachable] koşullarını
  /// kullanır. Yeniden karşılaşma ileride özel bir olayla gelecek.
  List<Person> _uygunKisiler(BuildContext context, GameState state) {
    return state.reachablePeople
        .where((Person p) =>
            GameScope.of(context).availableKindsFor(p).isNotEmpty)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final GameState state = GameScope.of(context).state!;
    final List<Person> kisiler = _uygunKisiler(context, state);

    switch (_page) {
      case _ActivityPage.berber:
        return VenuePage(
          venue: ActivityVenue.berber,
          onBack: () => _go(_ActivityPage.kok),
        );
      case _ActivityPage.spor:
        return VenuePage(
          venue: ActivityVenue.sporSalonu,
          onBack: () => _go(_ActivityPage.kok),
        );
      case _ActivityPage.kutuphane:
        return LibraryPage(onBack: () => _go(_ActivityPage.kok));
      case _ActivityPage.sosyalMedya:
        return SocialMediaPage(onBack: () => _go(_ActivityPage.kok));
      case _ActivityPage.kumarhane:
        return CasinoPage(onBack: () => _go(_ActivityPage.kok));
      case _ActivityPage.ehliyet:
        return LicenseOfficePage(onBack: () => _go(_ActivityPage.kok));
      case _ActivityPage.evlatEdinme:
        return AdoptionPage(onBack: () => _go(_ActivityPage.kok));
      case _ActivityPage.sosyal:
      case _ActivityPage.kok:
        break;
    }

    if (_page == _ActivityPage.sosyal) {
      return SectionScaffold(
        title: 'Birlikte vakit geçir',
        subtitle: 'Hayatında şu an gerçekten görüştüğün kişiler. '
            'Herkesle aynı etkileşimler açık değildir.',
        backLabel: 'Aktiviteler',
        onBack: () => _go(_ActivityPage.kok),
        children: <Widget>[
          for (final Person person in kisiler) ...<Widget>[
            PersonCard(
              person: person,
              playerAge: state.player.age,
              onTap: () =>
                  PersonDetailSheet.show(context, personId: person.id),
            ),
            const SizedBox(height: 10),
          ],
        ],
      );
    }

    return SectionScaffold(
      title: 'Aktiviteler',
      onBack: widget.onBack,
      children: <Widget>[
        if (kisiler.isNotEmpty)
          MenuRow(
            title: 'Birlikte vakit geçir',
            subtitle: 'Ailen ve arkadaşlarınla',
            icon: Icons.groups_2_outlined,
            trailingText: '${kisiler.length}',
            onTap: () => _go(_ActivityPage.sosyal),
          )
        else
          const InfoPanel(
            icon: Icons.groups_2_outlined,
            text: 'Şu an birlikte vakit geçirebileceğin kimse yok. '
                'Bu yaşta etkileşimler henüz açılmamış olabilir.',
          ),
        const SizedBox(height: 12),
        MenuRow(
          title: ActivityVenue.berber.label,
          subtitle: 'Saç kestir, stil değiştir, bakım yaptır',
          icon: Icons.content_cut_outlined,
          onTap: () => _go(_ActivityPage.berber),
        ),
        const SizedBox(height: 10),
        MenuRow(
          title: ActivityVenue.sporSalonu.label,
          subtitle: 'Koşu, ağırlık ve temel egzersiz',
          icon: Icons.fitness_center_outlined,
          onTap: () => _go(_ActivityPage.spor),
        ),
        const SizedBox(height: 10),
        MenuRow(
          title: ActivityVenue.kutuphane.label,
          subtitle: 'Yaşına uygun kitap seç ve oku',
          icon: Icons.local_library_outlined,
          onTap: () => _go(_ActivityPage.kutuphane),
        ),
        const SizedBox(height: 10),
        // Sosyal medya 16 yaşından itibaren açılır; öncesinde menüde yok.
        if (state.player.age >= kSocialMinAge) ...<Widget>[
          MenuRow(
            title: 'Sosyal medya',
            subtitle: state.socialAccounts.isEmpty
                ? 'Hesap açmak isteğe bağlı'
                : '${state.totalFollowers} takipçi',
            icon: Icons.public_outlined,
            onTap: () => _go(_ActivityPage.sosyalMedya),
          ),
          const SizedBox(height: 10),
        ],
        // Ehliyet işlemleri en erken başvuru yaşında görünür.
        if (state.player.age >=
            LicenseType.motosiklet.prototypeOnlyMinAge) ...<Widget>[
          MenuRow(
            title: 'Ehliyet İşlemleri',
            subtitle: state.hasPendingLicenseExam
                ? 'Devam eden bir sınavın var'
                : state.licenses.isEmpty
                    ? 'Motosiklet ve otomobil ehliyeti'
                    : '${state.licenses.length} ehliyetin var',
            icon: Icons.badge_outlined,
            onTap: () => _go(_ActivityPage.ehliyet),
          ),
          const SizedBox(height: 10),
        ],
        // Evlat edinme yetişkin yaşında açılır (D-049); evli olmak şart
        // değildir.
        if (state.player.age >= Adoption.prototypeOnlyMinAge) ...<Widget>[
          MenuRow(
            title: 'Evlat Edinme',
            subtitle: state.children.isEmpty
                ? 'Bir çocuğa aile olmak'
                : '${state.children.length} çocuğun var',
            icon: Icons.volunteer_activism_outlined,
            onTap: () => _go(_ActivityPage.evlatEdinme),
          ),
          const SizedBox(height: 10),
        ],
        // Kumarhane yetişkin yaşında açılır; öncesinde menüde yoktur.
        if (state.settings.casinoEnabled &&
            state.player.age >= CasinoRules.prototypeOnlyMinAge) ...<Widget>[
          MenuRow(
            title: 'Kumarhane',
            subtitle: state.hasOpenHand
                ? 'Masada devam eden bir elin var'
                : 'Blackjack ve rulet — yalnızca oyun parası',
            icon: Icons.casino_outlined,
            onTap: () => _go(_ActivityPage.kumarhane),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 2),
        const InfoPanel(
          icon: Icons.construction_outlined,
          text: 'Seyahat gibi alanlar bu bölüme sonra eklenecek. Henüz '
              'yazılmadıkları için düğme olarak gösterilmiyorlar.',
        ),
      ],
    );
  }
}
