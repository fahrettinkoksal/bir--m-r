import 'package:flutter/material.dart';

import '../../../data/activity_catalog.dart';
import '../../../data/social_catalog.dart';
import '../../../data/license_catalog.dart';
import '../../../data/martial_arts_catalog.dart';
import '../../../data/lottery_catalog.dart';
import '../../../data/finger_catalog.dart';
import '../../../domain/activities/travel.dart';
import '../../../domain/casino/casino_rules.dart';
import '../../../domain/life/astrology.dart';
import '../../../domain/interaction/adoption.dart';
import '../../../domain/models/game_state.dart';
import '../../../domain/models/person.dart';
import '../../../state/game_scope.dart';
import '../../theme/bir_omur_theme.dart';
import '../../widgets/person_card.dart';
import '../../widgets/person_detail_sheet.dart';
import '../../widgets/section_scaffold.dart';
import 'activity_pages.dart';
import 'casino_pages.dart';
import 'martial_arts_page.dart';
import 'lottery_page.dart';
import 'finger_page.dart';
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
  saglik,
  eglence,
  kurs,
  falTarot,
  dovus,
  sosyalMedya,
  kumarhane,
  piyango,
  finger,
  ehliyet,
  evlatEdinme,
  vasiyet,
  seyahat,
}

/// Dövüş sanatlarına en erken hangi yaşta başlanabilir?
int get _enKucukDovusYasi {
  int enKucuk = 120;
  for (final MartialArt a in MartialArt.values) {
    if (a.minAge < enKucuk) enKucuk = a.minAge;
  }
  return enKucuk;
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
          extraRows: <Widget>[
            if (state.player.age >= _enKucukDovusYasi)
              MenuRow(
                key: const Key('spor_dovus'),
                title: 'Dövüş sanatları',
                subtitle: 'Karate, kung fu ve yağlı güreş dersleri',
                icon: Icons.sports_martial_arts_outlined,
                accent: BirOmurAccents.nar,
                onTap: () => _go(_ActivityPage.dovus),
              ),
          ],
        );
      case _ActivityPage.dovus:
        return MartialArtsPage(onBack: () => _go(_ActivityPage.spor));
      case _ActivityPage.kutuphane:
        return LibraryPage(onBack: () => _go(_ActivityPage.kok));
      case _ActivityPage.saglik:
        return VenuePage(
          venue: ActivityVenue.saglikMerkezi,
          onBack: () => _go(_ActivityPage.kok),
        );
      case _ActivityPage.eglence:
        return VenuePage(
          venue: ActivityVenue.eglence,
          onBack: () => _go(_ActivityPage.kok),
        );
      case _ActivityPage.kurs:
        return VenuePage(
          venue: ActivityVenue.kurs,
          onBack: () => _go(_ActivityPage.kok),
        );
      case _ActivityPage.falTarot:
        return VenuePage(
          venue: ActivityVenue.falTarot,
          onBack: () => _go(_ActivityPage.kok),
        );
      case _ActivityPage.sosyalMedya:
        return SocialMediaPage(onBack: () => _go(_ActivityPage.kok));
      case _ActivityPage.kumarhane:
        return CasinoPage(onBack: () => _go(_ActivityPage.kok));
      case _ActivityPage.piyango:
        return LotteryPage(onBack: () => _go(_ActivityPage.kok));
      case _ActivityPage.finger:
        return FingerPage(onBack: () => _go(_ActivityPage.kok));
      case _ActivityPage.ehliyet:
        return LicenseOfficePage(onBack: () => _go(_ActivityPage.kok));
      case _ActivityPage.evlatEdinme:
        return AdoptionPage(onBack: () => _go(_ActivityPage.kok));
      case _ActivityPage.vasiyet:
        return WillPage(onBack: () => _go(_ActivityPage.kok));
      case _ActivityPage.seyahat:
        return TravelPage(onBack: () => _go(_ActivityPage.kok));
      case _ActivityPage.sosyal:
      case _ActivityPage.kok:
        break;
    }

    if (_page == _ActivityPage.sosyal) {
      return SectionScaffold(
        icon: Icons.groups_2_rounded,
        accent: BirOmurAccents.gul,
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
      icon: Icons.local_activity_rounded,
      title: 'Aktiviteler',
      accent: BirOmurAccents.turuncu,
      onBack: widget.onBack,
      children: <Widget>[
        if (kisiler.isNotEmpty)
          MenuRow(
            title: 'Birlikte vakit geçir',
            subtitle: 'Ailen ve arkadaşlarınla',
            icon: Icons.groups_2_outlined,
            accent: BirOmurAccents.gul,
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
        // Paket 28: uzun liste gruplara ayrıldı. Aradığını bulmak için
        // bütün ekranı kaydırmak gerekmiyor.
        const MenuGroupTitle(
          text: 'Kendine bak',
          accent: BirOmurAccents.yesil,
        ),
        MenuRow(
          title: ActivityVenue.berber.label,
          subtitle: 'Saç kestir, stil değiştir, bakım yaptır',
          icon: Icons.content_cut_outlined,
          accent: BirOmurAccents.mor,
          onTap: () => _go(_ActivityPage.berber),
        ),
        const SizedBox(height: 10),
        MenuRow(
          title: ActivityVenue.sporSalonu.label,
          subtitle: 'Koşu, ağırlık ve temel egzersiz',
          icon: Icons.fitness_center_outlined,
          accent: BirOmurAccents.yesil,
          onTap: () => _go(_ActivityPage.spor),
        ),
        const SizedBox(height: 10),
        if (state.player.age >= ActivityVenue.saglikMerkezi.minAge) ...<Widget>[
          MenuRow(
            key: const Key('activity_saglik'),
            title: ActivityVenue.saglikMerkezi.label,
            subtitle: 'Kontroller, aşı ve bir uzmanla konuşmak',
            icon: Icons.medical_services_outlined,
            accent: BirOmurAccents.nar,
            onTap: () => _go(_ActivityPage.saglik),
          ),
          const SizedBox(height: 10),
        ],
        const MenuGroupTitle(
          text: 'Öğren',
          accent: BirOmurAccents.mavi,
        ),
        MenuRow(
          title: ActivityVenue.kutuphane.label,
          subtitle: 'Yaşına uygun kitap seç ve oku',
          icon: Icons.local_library_outlined,
          accent: BirOmurAccents.mavi,
          onTap: () => _go(_ActivityPage.kutuphane),
        ),
        const SizedBox(height: 10),
        if (state.player.age >= ActivityVenue.kurs.minAge) ...<Widget>[
          MenuRow(
            key: const Key('activity_kurs'),
            title: ActivityVenue.kurs.label,
            subtitle: 'Resim, müzik, dil ve bilgisayar',
            icon: Icons.palette_outlined,
            accent: BirOmurAccents.mor,
            onTap: () => _go(_ActivityPage.kurs),
          ),
          const SizedBox(height: 10),
        ],
        const MenuGroupTitle(
          text: 'Keyfine bak',
          accent: BirOmurAccents.turuncu,
        ),
        if (state.player.age >= ActivityVenue.eglence.minAge) ...<Widget>[
          MenuRow(
            key: const Key('activity_eglence'),
            title: ActivityVenue.eglence.label,
            subtitle: 'Sinema, maç, konser, parkta yürüyüş',
            icon: Icons.celebration_outlined,
            accent: BirOmurAccents.turuncu,
            onTap: () => _go(_ActivityPage.eglence),
          ),
          const SizedBox(height: 10),
        ],
        if (state.player.age >= ActivityVenue.falTarot.minAge) ...<Widget>[
          MenuRow(
            key: const Key('activity_fal'),
            title: ActivityVenue.falTarot.label,
            subtitle: 'Kahve falı, tarot ve '
                '${Astrology.zodiacOf(state).display} yorumu',
            icon: Icons.auto_awesome_outlined,
            accent: BirOmurAccents.gul,
            onTap: () => _go(_ActivityPage.falTarot),
          ),
          const SizedBox(height: 10),
        ],
        // Paket 18: sağlığa kriz beklemeden bakmanın, mutluluğu kendi
        // isteğinle yükseltmenin ve okul dışında bir şey öğrenmenin yolu
        // yoktu. Her alan yaşına uygun olduğu andan itibaren görünür;
        // çalışmayan düğme konmaz.
        // Seyahat, tek başına yola çıkılabilecek yaştan itibaren görünür
        // (Paket 11). Kalıcı taşınmadan ayrıdır.
        if (state.player.age >= Travel.prototypeOnlyMinAge) ...<Widget>[
          MenuRow(
            title: 'Seyahat',
            subtitle: state.trips.isEmpty
                ? 'Başka bir şehre kısa bir gezi'
                : '${state.trips.length} gezi yaptın',
            icon: Icons.luggage_outlined,
            accent: BirOmurAccents.mavi,
            onTap: () => _go(_ActivityPage.seyahat),
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
            accent: BirOmurAccents.nar,
            onTap: () => _go(_ActivityPage.kumarhane),
          ),
          const SizedBox(height: 10),
        ],
        // Piyango da kumar ayarına bağlıdır: kumar kapalıysa bayi de
        // menüde görünmez (Paket 33).
        if (state.settings.casinoEnabled &&
            state.player.age >= kLotteryMinAge) ...<Widget>[
          MenuRow(
            key: const Key('activity_piyango'),
            title: 'Milli Piyango',
            subtitle: state.lotteryTickets.isEmpty
                ? 'Bilet al, çekilişi yıl sonunda bekle'
                : '${state.lotteryTickets.length} biletin çekilişi bekliyor',
            icon: Icons.confirmation_number_outlined,
            accent: BirOmurAccents.pirinc,
            onTap: () => _go(_ActivityPage.piyango),
          ),
          const SizedBox(height: 10),
        ],
        // Finger: tanışma uygulaması (Paket 34).
        if (state.player.age >= kFingerMinAge) ...<Widget>[
          MenuRow(
            key: const Key('activity_finger'),
            title: 'Finger',
            subtitle: state.fingerMatches.isEmpty
                ? 'Tanışma uygulaması — profillere bak, eşleş'
                : '${state.fingerMatches.length} eşleşmen var',
            icon: Icons.favorite_border_rounded,
            accent: BirOmurAccents.gul,
            onTap: () => _go(_ActivityPage.finger),
          ),
          const SizedBox(height: 10),
        ],
        const MenuGroupTitle(
          text: 'Hayat işleri',
          accent: BirOmurAccents.mor,
        ),
        // Sosyal medya 16 yaşından itibaren açılır; öncesinde menüde yok.
        if (state.player.age >= kSocialMinAge) ...<Widget>[
          MenuRow(
            title: 'Sosyal medya',
            subtitle: state.socialAccounts.isEmpty
                ? 'Hesap açmak isteğe bağlı'
                : '${state.totalFollowers} takipçi',
            icon: Icons.public_outlined,
            accent: BirOmurAccents.cini,
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
            accent: BirOmurAccents.turuncu,
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
            accent: BirOmurAccents.gul,
            onTap: () => _go(_ActivityPage.evlatEdinme),
          ),
          const SizedBox(height: 10),
        ],
        // Vasiyet yalnızca hayatta çocuğu olan oyuncuda görünür (D-052);
        // çocuğu olmayana çalışmayan düğme gösterilmez.
        if (state.livingChildren.isNotEmpty) ...<Widget>[
          MenuRow(
            title: 'Vasiyet',
            subtitle: GameScope.of(context).heirChild == null
                ? 'Mirasçı seçilmedi'
                : 'Mirasçın: ${GameScope.of(context).heirChild!.firstName}',
            icon: Icons.history_edu_outlined,
            accent: BirOmurAccents.pirinc,
            onTap: () => _go(_ActivityPage.vasiyet),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 2),
        const InfoPanel(
          icon: Icons.construction_outlined,
          text: 'Bu bölüme yeni alanlar zamanla eklenecek. Henüz '
              'yazılmamış özellikler düğme olarak gösterilmiyor.',
        ),
      ],
    );
  }
}
