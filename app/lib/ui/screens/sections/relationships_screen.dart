import 'package:flutter/material.dart';

import '../../../domain/models/game_state.dart';
import '../../../domain/models/person.dart';
import '../../../data/pet_catalog.dart';
import '../../../domain/pets/pet_care.dart';
import '../../../domain/family/family_decision.dart';
import '../../../domain/generation/parent_divorce.dart';
import '../../../domain/activities/activity_engine.dart';
import '../../../domain/models/family_issue.dart';
import '../../../domain/models/person_development.dart';
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

  /// Paket AO §38: kardeşler kendi sayfasına alındı.
  ///
  /// Öz kardeşin yanına **üvey** ve **yarım** kardeş geldi. Eskiden
  /// kardeşler "Akrabalar" içinde dede-nine ve teyze-amcayla aynı
  /// listedeydi; üvey ve yarım kardeş ise hiçbir listeye düşmüyordu:
  /// kaydı vardı, ekranda yoktu.
  kardesler,

  /// Paket AO §38: kayınvalide ve kayınpeder.
  ///
  /// Çekirdek aile değiller, geniş aile de değiller; kendi başlıkları
  /// var. Boşanınca kayıt kalır, bu yüzden liste de kalır.
  esinAilesi,
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

  /// Geniş aile: dede-nine, teyze-amca-dayı-hala, yeğenler.
  ///
  /// Paket AO §38'den beri **kardeşler burada değil**: kendi sayfaları
  /// var. Torunların da kendi sayfası var; ikisi de burada tekrar
  /// gösterilmez.
  List<Person> _akrabalar(GameState state) => state.people
      .where((Person p) =>
          p.relation.group == RelationGroup.genis &&
          p.relation != RelationType.torun)
      .toList(growable: false)
    ..sort((Person a, Person b) => b.age.compareTo(a.age));

  /// Kardeşler: öz, üvey ve yarım (Paket AO §9, §12, §38).
  ///
  /// Üçü aynı sayfada durur çünkü oyuncunun hayatında üçü de kardeştir;
  /// aradaki fark kartın etiketinde ve kişi kartındaki soy bilgisinde
  /// görünür, ayrı bir menüde değil.
  List<Person> _kardesler(GameState state) => state.people
      .where((Person p) =>
          p.relation == RelationType.kardes ||
          p.relation == RelationType.uveyKardes ||
          p.relation == RelationType.yariKardes)
      .toList(growable: false)
    ..sort((Person a, Person b) => b.age.compareTo(a.age));

  /// Eşinin ailesi (Paket AO §21-§24, §38).
  List<Person> _esinAilesi(GameState state) =>
      state.byGroup(RelationGroup.esinAilesi);

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
  ///
  /// Paket AO §18-§20: eşin önceki ilişkisinden olan çocuğu da burada
  /// listelenir. `state.children` **değiştirilmedi** — miras, velayet ve
  /// kuşak devamı gibi kurallar biyolojik çocuğa bakmaya devam eder
  /// (§17). Değişen yalnızca ekran: üvey çocuk aynı evde yaşıyorsa
  /// oyuncunun onu görebilmesi gerekir.
  List<Person> _cocuklar(GameState state) => <Person>[
        ...state.children,
        ...state.people
            .where((Person p) => p.relation == RelationType.uveyCocuk),
      ]..sort((Person a, Person b) => b.age.compareTo(a.age));

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
        RelationshipSubPage.kardesler => _kardesler(state),
        RelationshipSubPage.esinAilesi => _esinAilesi(state),
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
        RelationshipSubPage.kardesler => 'Kardeşler',
        RelationshipSubPage.esinAilesi => 'Eşinin ailesi',
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
        RelationshipSubPage.kardesler =>
          'Öz, üvey ve yarım kardeşler. Etiket bağı söyler.',
        RelationshipSubPage.esinAilesi =>
          'Eşinin annesi ve babası. Boşansan da kayıtları kalır.',
        RelationshipSubPage.arkadaslar =>
          'Okulda ve hayatta tanıştığın kişiler; akraba değildir.',
        RelationshipSubPage.romantik =>
          'İlişki geçmişi; akrabalık ve hane değildir.',
        RelationshipSubPage.cocuklar =>
          'Kendi çocukların ve varsa eşinin çocuğu. Kayıt silinmez.',
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
              // Paket AP §57, §59-§60: çocuğun eşi ve süren aile
              // meselesi kartın üzerinde görünür. İkisi de gerçek
              // kayıttan okunur; yoksa satır hiç çıkmaz.
              spouseLine: _esSatiri(person),
              statusLine: GameScope.of(context).familyStatusLine(person),
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
    final int kardesSayisi = _kardesler(state).length;
    final int kayinSayisi = _esinAilesi(state).length;
    final int arkadasSayisi = _arkadaslar(state).length;
    final int tanidikSayisi = _tanidiklar(state).length;
    final int romantikSayisi = _romantikler(state).length;
    final int hayvanSayisi = PetCare.livingPets(state)
        .where((Pet p) => p.inPlayerHousehold)
        .length;

    // Paket AO §38: ekran beş aile öbeğine ayrıldı. Öbek başlığı
    // **yalnızca içinde kişi varsa** çizilir; boş başlık gösterilmez.
    // Öbekler: çekirdek aile, kendi ailen, geniş aile, eşinin ailesi ve
    // geçmiş ilişkiler. Arkadaşlar ve evcil hayvan aile değildir; en
    // altta kendi başlıklarında dururlar.
    final List<Person> uveyEbeveynler = _uveyEbeveynler(state);
    final bool cekirdekVar =
        anne != null || baba != null || uveyEbeveynler.isNotEmpty ||
            kardesSayisi > 0;
    final bool kendiAilemVar = (es != null && es.relation == RelationType.es) ||
        cocukSayisi > 0 ||
        _torunlar(state).isNotEmpty;
    final bool gecmisVar = romantikSayisi > 0 || state.marriageCount > 0;

    return SectionScaffold(
      icon: Icons.favorite_rounded,
      title: 'İlişkiler',
      accent: BirOmurAccents.gul,
      onBack: widget.onBack,
      children: <Widget>[
        // --- BEKLEYEN KARAR: hangi ebeveynle kalacaksın? (§4) --------
        //
        // `ParentDivorce` kararı Paket AO/1'de yazıldı ama hiçbir
        // ekrandan sorulmuyordu: boşanma oluyor, varsayılan hane
        // kuruluyor, oyuncu hiç seçmiyordu. Karar burada, ailenin
        // ekranında soruluyor. Seçilmezse oyun kilitlenmez; varsayılan
        // hane geçerli kalır.
        if (GameScope.of(context).hasParentDivorceChoice()) ...<Widget>[
          _HaneSecimiKarti(
            anne: anne,
            baba: baba,
            onSecim: (DivorceHouseholdChoice secim) {
              GameScope.of(context).chooseDivorceHousehold(secim);
              setState(() {});
            },
          ),
          const SizedBox(height: 14),
        ],
        // --- BEKLEYEN AİLE KARARI (Paket AP §56) --------------------
        //
        // Paket AP yedi aile kararı getirdi. Hepsi tek bir kart olarak
        // soruluyor; motorların her biri için ayrı kart yazılmadı.
        //
        // Paket AO'da üç motorun hiçbir ekrandan ulaşılamadığı
        // görülmüştü; kapı bu yüzden motorlarla aynı pakette açıldı.
        if (_aileKarari(context) != null) ...<Widget>[
          _AileKarariKarti(
            karar: _aileKarari(context)!,
            onCevap: (FamilyIssueResponse cevap) {
              final ActivityOutcome? sonuc =
                  GameScope.of(context).answerFamilyDecision(cevap);
              if (sonuc != null && !sonuc.applied) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(sonuc.text)),
                );
              }
              setState(() {});
            },
          ),
          const SizedBox(height: 14),
        ],
        // --- ÇEKİRDEK AİLE ------------------------------------------
        if (cekirdekVar) ...<Widget>[
          const MenuGroupTitle(
            text: 'Çekirdek aile',
            accent: BirOmurAccents.gul,
          ),
          const SizedBox(height: 8),
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
          for (final Person uvey in uveyEbeveynler) ...<Widget>[
            PersonCard(
              key: Key('uvey_ebeveyn_${uvey.id}'),
              person: uvey,
              playerAge: playerAge,
              onTap: () => _openPerson(uvey.id),
            ),
            const SizedBox(height: 10),
          ],
          // Kardeşler kendi sayfasında (§38): öz, üvey ve yarım birlikte.
          if (kardesSayisi > 0) ...<Widget>[
            MenuRow(
              key: const Key('relationships_siblings_row'),
              title: 'Kardeşler',
              subtitle: 'Öz, üvey ve yarım kardeşlerin',
              icon: Icons.diversity_1_outlined,
              accent: BirOmurAccents.cini,
              trailingText: '$kardesSayisi',
              onTap: () =>
                  setState(() => _subPage = RelationshipSubPage.kardesler),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 6),
        ],
        // --- KENDİ AİLEM --------------------------------------------
        if (kendiAilemVar) ...<Widget>[
          const MenuGroupTitle(
            text: 'Kendi ailem',
            accent: BirOmurAccents.gul,
          ),
          const SizedBox(height: 8),
          // Eş kendi hanenin diğer yarısıdır (Paket E1).
          if (es != null && es.relation == RelationType.es) ...<Widget>[
            PersonCard(
              person: es,
              playerAge: playerAge,
              onTap: () => _openPerson(es.id),
            ),
            const SizedBox(height: 10),
          ],
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
          const SizedBox(height: 6),
        ],
        // --- GENİŞ AİLE ---------------------------------------------
        if (akrabaSayisi > 0) ...<Widget>[
          const MenuGroupTitle(
            text: 'Geniş aile',
            accent: BirOmurAccents.cini,
          ),
          const SizedBox(height: 8),
          MenuRow(
            key: const Key('relationships_relatives_row'),
            title: 'Akrabalar',
            subtitle: 'Büyükler, teyze-amca ve yeğenler',
            icon: Icons.diversity_3_outlined,
            accent: BirOmurAccents.cini,
            trailingText: '$akrabaSayisi',
            onTap: () =>
                setState(() => _subPage = RelationshipSubPage.akrabalar),
          ),
          const SizedBox(height: 16),
        ],
        // --- EŞİN AİLESİ --------------------------------------------
        if (kayinSayisi > 0) ...<Widget>[
          const MenuGroupTitle(
            text: 'Eşinin ailesi',
            accent: BirOmurAccents.turuncu,
          ),
          const SizedBox(height: 8),
          MenuRow(
            key: const Key('relationships_inlaws_row'),
            title: 'Kayın aile',
            subtitle: 'Eşinin annesi ve babası',
            icon: Icons.family_restroom_outlined,
            accent: BirOmurAccents.turuncu,
            trailingText: '$kayinSayisi',
            onTap: () =>
                setState(() => _subPage = RelationshipSubPage.esinAilesi),
          ),
          const SizedBox(height: 16),
        ],
        // --- GEÇMİŞ İLİŞKİLER ---------------------------------------
        if (gecmisVar) ...<Widget>[
          const MenuGroupTitle(
            text: 'Geçmiş ilişkiler',
            accent: BirOmurAccents.gul,
          ),
          const SizedBox(height: 8),
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
          const SizedBox(height: 6),
        ],
        // --- AİLE DIŞI ----------------------------------------------
        if (arkadasSayisi > 0 ||
            tanidikSayisi > 0 ||
            state.pets.isNotEmpty ||
            playerAge >= PetCare.prototypeOnlyMinAge) ...<Widget>[
          const MenuGroupTitle(
            text: 'Aile dışı',
            accent: BirOmurAccents.turuncu,
          ),
          const SizedBox(height: 8),
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

/// §4: "Kiminle kalmak istersin?" kartı.
///
/// İki ebeveyn de listede kalır; bu soru yalnızca oyuncunun hangi
/// hanede yaşayacağını belirler. Ebeveynlerden biri kayıtta yoksa soru
/// da çıkmaz — olmayan kişi seçenek olarak gösterilmez.
/// Bekleyen aile kararı; yoksa `null`.
FamilyDecision? _aileKarari(BuildContext context) =>
    GameScope.of(context).pendingFamilyDecision();

/// Kişinin eşini anlatan satır; eşi yoksa `null` (Paket AP §57).
///
/// Ad **gerçek kayıttan** gelir; uydurma isim yazılmaz (§58).
String? _esSatiri(Person person) {
  final PersonDevelopment? gelisim = person.development;
  if (gelisim == null) return null;
  final String? ad = gelisim.spouseName;
  if (ad == null || ad.isEmpty) return null;
  if (gelisim.isMarried) return 'Eşi: $ad';
  if (gelisim.isWidowed) return 'Eşini kaybetti';
  if (gelisim.isDivorced) return 'Boşandı';
  return null;
}

/// Bekleyen aile kararını soran kart (Paket AP §56-§58).
///
/// Metinler doğal Türkçe; iç sayı göstermez. Seçilemeyen seçenek
/// **görünür** ama pasiftir ve gerekçesi altında yazar (D-095).
class _AileKarariKarti extends StatelessWidget {
  const _AileKarariKarti({required this.karar, required this.onCevap});

  final FamilyDecision karar;
  final ValueChanged<FamilyIssueResponse> onCevap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      key: const Key('aile_karari_karti'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(Comic.yaricapBuyuk),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            karar.title,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            karar.text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          for (final FamilyDecisionOption secenek in karar.options) ...<Widget>[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                key: Key('aile_karari_${secenek.response.name}'),
                onPressed:
                    secenek.isAllowed ? () => onCevap(secenek.response) : null,
                child: Text(secenek.label),
              ),
            ),
            if (!secenek.isAllowed) ...<Widget>[
              const SizedBox(height: 2),
              Text(
                secenek.blockedReason!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _HaneSecimiKarti extends StatelessWidget {
  const _HaneSecimiKarti({
    required this.anne,
    required this.baba,
    required this.onSecim,
  });

  final Person? anne;
  final Person? baba;
  final ValueChanged<DivorceHouseholdChoice> onSecim;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    if (anne == null || baba == null) return const SizedBox.shrink();
    return Container(
      key: const Key('aile_hane_secimi_karti'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(Comic.yaricapBuyuk),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Kiminle kalmak istersin?',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Annenle baban ayrıldı. İkisi de annen ve baban olarak '
            'kalıyor; değişen yalnızca hangi evde yaşadığın.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              OutlinedButton(
                key: const Key('aile_hane_secimi_anne'),
                onPressed: () => onSecim(DivorceHouseholdChoice.anne),
                child: Text('${anne!.firstName} ile kal'),
              ),
              OutlinedButton(
                key: const Key('aile_hane_secimi_baba'),
                onPressed: () => onSecim(DivorceHouseholdChoice.baba),
                child: Text('${baba!.firstName} ile kal'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
