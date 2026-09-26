import 'package:flutter/material.dart';

import '../../../domain/models/game_state.dart';
import '../../../domain/models/person.dart';
import '../../../data/pet_catalog.dart';
import '../../../domain/pets/pet_care.dart';
import '../../../domain/models/relation.dart';
import '../../../state/game_scope.dart';
import '../../theme/bir_omur_theme.dart';
import '../../widgets/person_card.dart';
import '../../widgets/person_detail_sheet.dart';
import '../../widgets/section_scaffold.dart';
import 'marriage_history_page.dart';
import 'pets_page.dart';

/// İlişkiler ana menüsü (NAV-001).
///
/// Ana ekranda **anne ve baba en üstte** durur; akrabalar, arkadaşlar ve
/// romantik bağlar alt menülere ayrılır. Uzun tek liste yerine iç içe menü
/// tercih edilmiştir. Veri yapısı değişmez: kişiler aynı kalıcı kimlikle,
/// aynı bağ türleriyle okunur.
/// Evcil hayvan satırının alt metni: gerçek kayda bakar, uydurmaz.
///
/// D-146 ile Aktiviteler ekranından buraya taşındı.
String _hayvanAltMetni(GameState state) {
  final List<Pet> yasayan = PetCare.livingPets(state);
  if (yasayan.isEmpty) {
    return adoptablePetSpecies.map((PetSpecies s) => s.label).join(' ya da ');
  }
  if (yasayan.length == 1) {
    return '${yasayan.first.name} seninle yaşıyor';
  }
  return '${yasayan.length} hayvana bakıyorsun';
}

enum RelationshipSubPage {
  akrabalar,
  arkadaslar,
  romantik,
  cocuklar,
  torunlar,
  // Faho'nun Q-115 kararı: geri takip eden ünlüler arkadaş listesine
  // karışmaz, kendi başlığında durur (D-106).
  tanidiklar,

  /// D-133: ikinci evlilik D-036'da geldi ama geçmiş evlilikler
  /// hiçbir ekranda görünmüyordu.
  evlilikGecmisi,

  /// D-146: evcil hayvan Varlıklar'dan İlişkiler'e taşındı.
  ///
  /// Faho'nun isteği: "evdeki evcil hayvanımı ilişkiler kısmına taşı,
  /// varlıklarda değil." Hayvan bir mülk değil, bir ilişkidir.
  evcilHayvanlar,
}

class RelationshipsScreen extends StatefulWidget {
  const RelationshipsScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<RelationshipsScreen> createState() => _RelationshipsScreenState();
}

class _RelationshipsScreenState extends State<RelationshipsScreen> {
  RelationshipSubPage? _subPage;

  List<Person> _akrabalar(GameState state) => state.people
      .where((Person p) =>
          p.relation == RelationType.kardes ||
          // Torunların kendi sayfası var; akraba listesinde tekrar
          // gösterilmez.
          (p.relation.group == RelationGroup.genis &&
              p.relation != RelationType.torun))
      .toList(growable: false)
    ..sort((Person a, Person b) => b.age.compareTo(a.age));

  List<Person> _arkadaslar(GameState state) => state.people
      .where((Person p) =>
          p.relation == RelationType.arkadas ||
          // Cezaevinde tanışılan kişi de burada listelenir (D-140);
          // yoksa kayıt oluşuyor ama oyuncu hiç göremiyordu.
          p.relation == RelationType.kogusArkadasi)
      .toList(growable: false);

  /// Üvey anne ve üvey baba (D-141).
  ///
  /// Anne/baba kartlarının hemen altında dururlar: aynı hanede yaşarlar
  /// ama kan bağı değildirler.
  List<Person> _uveyEbeveynler(GameState state) => state.people
      .where((Person p) =>
          p.relation == RelationType.uveyAnne ||
          p.relation == RelationType.uveyBaba)
      .toList(growable: false);

  List<Person> _romantikler(GameState state) =>
      state.byGroup(RelationGroup.romantik);

  /// Geri takip eden ünlüler ve benzeri tanışıklıklar (D-106).
  List<Person> _tanidiklar(GameState state) =>
      state.byGroup(RelationGroup.tanidiklar);

  /// Çocuklar en büyükten küçüğe. Vefat edenler de listede kalır (D-029).
  List<Person> _cocuklar(GameState state) => <Person>[...state.children]
    ..sort((Person a, Person b) => b.age.compareTo(a.age));

  /// Torunlar en büyükten küçüğe. Vefat edenler de listede kalır.
  List<Person> _torunlar(GameState state) => state.people
      .where((Person p) => p.relation == RelationType.torun)
      .toList(growable: false)
    ..sort((Person a, Person b) => b.age.compareTo(a.age));

  Person? _byRelation(GameState state, RelationType relation) {
    for (final Person p in state.people) {
      if (p.relation == relation) return p;
    }
    return null;
  }

  void _openPerson(String id) =>
      PersonDetailSheet.show(context, personId: id);

  @override
  Widget build(BuildContext context) {
    final GameState state = GameScope.of(context).state!;
    final int playerAge = state.player.age;

    // Evlilik Geçmişi kişi listesi değil, kayıt ekranıdır (D-133).
    if (_subPage == RelationshipSubPage.evlilikGecmisi) {
      return MarriageHistoryPage(onBack: () => setState(() => _subPage = null));
    }

    // Evcil hayvanlar da kişi listesi değil: kendi sayfası var (D-146).
    if (_subPage == RelationshipSubPage.evcilHayvanlar) {
      return PetsPage(
        backLabel: 'İlişkiler',
        onBack: () => setState(() => _subPage = null),
      );
    }

    if (_subPage != null) {
      final List<Person> kisiler = switch (_subPage!) {
        RelationshipSubPage.akrabalar => _akrabalar(state),
        RelationshipSubPage.arkadaslar => _arkadaslar(state),
        RelationshipSubPage.romantik => _romantikler(state),
        RelationshipSubPage.cocuklar => _cocuklar(state),
        RelationshipSubPage.torunlar => _torunlar(state),
        RelationshipSubPage.tanidiklar => _tanidiklar(state),
        // Buraya ulaşılmaz: evlilik geçmişi yukarıda ayrı ekran olarak
        // açılıyor. Derleyicinin tam kapsama isteği için duruyor.
        RelationshipSubPage.evlilikGecmisi => const <Person>[],
        RelationshipSubPage.evcilHayvanlar => const <Person>[],
      };
      final String baslik = switch (_subPage!) {
        RelationshipSubPage.akrabalar => 'Akrabalar',
        RelationshipSubPage.arkadaslar => 'Arkadaşlar',
        RelationshipSubPage.romantik => 'Romantik bağlar',
        RelationshipSubPage.cocuklar => 'Çocuklar',
        RelationshipSubPage.torunlar => 'Torunlar',
        RelationshipSubPage.tanidiklar => 'Ünlüler ve tanıdıklar',
        RelationshipSubPage.evlilikGecmisi => 'Evlilik Geçmişi',
        RelationshipSubPage.evcilHayvanlar => 'Evcil hayvanlar',
      };
      final String altBaslik = switch (_subPage!) {
        RelationshipSubPage.akrabalar =>
          'Akraba olmak aynı evde yaşamayı gerektirmez.',
        RelationshipSubPage.arkadaslar =>
          'Okulda ve hayatta tanıştığın kişiler; akraba değildir.',
        RelationshipSubPage.romantik =>
          'İlişki geçmişi; akrabalık ve hane değildir.',
        RelationshipSubPage.cocuklar =>
          'Büyüyen çocuklar evden çıkar; kayıtları silinmez.',
              RelationshipSubPage.torunlar =>
          'Çocuklarının çocukları. Kendi hayatlarını yaşarlar.',
        RelationshipSubPage.tanidiklar =>
          'Sana geri dönen ünlüler. Arkadaş değiller; tanışıklık.',
        RelationshipSubPage.evlilikGecmisi => '',
        RelationshipSubPage.evcilHayvanlar => '',
      };

      return SectionScaffold(
        icon: Icons.groups_rounded,
        title: baslik,
        subtitle: altBaslik,
        backLabel: 'İlişkiler',
        onBack: () => setState(() => _subPage = null),
        children: <Widget>[
          for (final Person person in kisiler) ...<Widget>[
            PersonCard(
              person: person,
              playerAge: playerAge,
              onTap: () => _openPerson(person.id),
            ),
            const SizedBox(height: 10),
          ],
        ],
      );
    }

    final Person? es = state.spouse;
    final Person? anne = _byRelation(state, RelationType.anne);
    final Person? baba = _byRelation(state, RelationType.baba);
    final int cocukSayisi = _cocuklar(state).length;
    final int akrabaSayisi = _akrabalar(state).length;
    final int arkadasSayisi = _arkadaslar(state).length;
    final int tanidikSayisi = _tanidiklar(state).length;
    final int romantikSayisi = _romantikler(state).length;
    final int hayvanSayisi = PetCare.livingPets(state)
        .where((Pet p) => p.inPlayerHousehold)
        .length;

    return SectionScaffold(
      icon: Icons.favorite_rounded,
      title: 'İlişkiler',
      accent: BirOmurAccents.gul,
      onBack: widget.onBack,
      children: <Widget>[
        // Eş en üstte durur; kendi hanenin diğer yarısıdır (Paket E1).
        if (es != null && es.relation == RelationType.es) ...<Widget>[
          PersonCard(
            person: es,
            playerAge: playerAge,
            onTap: () => _openPerson(es.id),
          ),
          const SizedBox(height: 10),
        ],
        // Anne ve baba en üstte (NAV-001).
        for (final Person? ebeveyn in <Person?>[anne, baba])
          if (ebeveyn != null) ...<Widget>[
            PersonCard(
              person: ebeveyn,
              playerAge: playerAge,
              onTap: () => _openPerson(ebeveyn.id),
            ),
            const SizedBox(height: 10),
          ],
        // Üvey anne / üvey baba hemen altta (D-141).
        for (final Person uvey in _uveyEbeveynler(state)) ...<Widget>[
          PersonCard(
            key: Key('uvey_ebeveyn_${uvey.id}'),
            person: uvey,
            playerAge: playerAge,
            onTap: () => _openPerson(uvey.id),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 8),
        // Alt listeler tek başlık altında toplanır (D-138): yukarıda
        // yakınların kartları, aşağıda "kimler var" listeleri.
        const MenuGroupTitle(
          text: 'Listeler',
          accent: BirOmurAccents.gul,
        ),
        const SizedBox(height: 8),
        if (cocukSayisi > 0) ...<Widget>[
          MenuRow(
            key: const Key('relationships_children_row'),
            title: 'Çocuklar',
            subtitle: 'Kendi çocukların',
            icon: Icons.child_care_outlined,
            accent: BirOmurAccents.mavi,
            trailingText: '$cocukSayisi',
            onTap: () =>
                setState(() => _subPage = RelationshipSubPage.cocuklar),
          ),
          const SizedBox(height: 10),
        ],
        if (_torunlar(state).isNotEmpty) ...<Widget>[
          MenuRow(
            key: const Key('relationships_grandchildren_row'),
            title: 'Torunlar',
            subtitle: 'Çocuklarının çocukları',
            icon: Icons.child_friendly_outlined,
            accent: BirOmurAccents.pirinc,
            trailingText: '${_torunlar(state).length}',
            onTap: () =>
                setState(() => _subPage = RelationshipSubPage.torunlar),
          ),
          const SizedBox(height: 10),
        ],
        if (akrabaSayisi > 0) ...<Widget>[
          MenuRow(
            title: 'Akrabalar',
            subtitle: 'Kardeşler, büyükler, teyze-amca',
            icon: Icons.diversity_3_outlined,
            accent: BirOmurAccents.cini,
            trailingText: '$akrabaSayisi',
            onTap: () =>
                setState(() => _subPage = RelationshipSubPage.akrabalar),
          ),
          const SizedBox(height: 10),
        ],
        if (arkadasSayisi > 0) ...<Widget>[
          MenuRow(
            title: 'Arkadaşlar',
            subtitle: 'Okul ve hayat arkadaşların',
            key: const Key('relationships_friends_row'),
            icon: Icons.handshake_outlined,
            accent: BirOmurAccents.turuncu,
            trailingText: '$arkadasSayisi',
            onTap: () =>
                setState(() => _subPage = RelationshipSubPage.arkadaslar),
          ),
          const SizedBox(height: 10),
        ],
        if (tanidikSayisi > 0) ...<Widget>[
          MenuRow(
            title: 'Ünlüler ve tanıdıklar',
            subtitle: 'Sana geri dönen ünlüler',
            icon: Icons.star_outline_rounded,
            accent: BirOmurAccents.pirinc,
            trailingText: '$tanidikSayisi',
            onTap: () =>
                setState(() => _subPage = RelationshipSubPage.tanidiklar),
          ),
          const SizedBox(height: 10),
        ],
        if (romantikSayisi > 0) ...<Widget>[
          MenuRow(
            title: 'Romantik bağlar',
            subtitle: 'Sevgili, eski sevgili ve eski eş',
            icon: Icons.favorite_outline,
            accent: BirOmurAccents.gul,
            trailingText: '$romantikSayisi',
            onTap: () =>
                setState(() => _subPage = RelationshipSubPage.romantik),
          ),
          const SizedBox(height: 10),
        ],
        // Evlilik Geçmişi (D-133): ikinci evlilik geldi ama eski kayıt
        // hiçbir ekranda görünmüyordu.
        if (state.marriageCount > 0) ...<Widget>[
          MenuRow(
            key: const Key('iliskiler_evlilik_gecmisi'),
            title: 'Evlilik Geçmişi',
            subtitle: state.marriageCount == 1
                ? 'Bir evlilik kaydı'
                : '${state.marriageCount} evlilik kaydı',
            icon: Icons.favorite_rounded,
            accent: BirOmurAccents.gul,
            trailingText: '${state.marriageCount}',
            onTap: () => setState(
              () => _subPage = RelationshipSubPage.evlilikGecmisi,
            ),
          ),
          const SizedBox(height: 10),
        ],
        // Evcil hayvanlar (D-146). Satır, evde hayvan varsa **her yaşta**
        // görünür; sahiplenme yaşı geldiğinde de görünür.
        //
        // Faho bildirdi: "oynadığım bir hayatta evde evcil hayvan vardı
        // fakat iletişim yoktu." Sebebi buydu: menü yalnızca sahiplenme
        // yaşından (7) itibaren açılıyordu, oysa oyuncu doğduğunda evde
        // olan hayvanla beş yaşındaki çocuk da oynayabilmeli.
        if (state.pets.isNotEmpty ||
            playerAge >= PetCare.prototypeOnlyMinAge) ...<Widget>[
          MenuRow(
            key: const Key('relationships_pets_row'),
            title: 'Evcil hayvanlar',
            subtitle: _hayvanAltMetni(state),
            icon: Icons.pets_outlined,
            accent: BirOmurAccents.turuncu,
            trailingText: hayvanSayisi == 0 ? null : '$hayvanSayisi',
            onTap: () => setState(
              () => _subPage = RelationshipSubPage.evcilHayvanlar,
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}
