// Paket BU — **komşu gerçek kişi**: bağ türü, üretim, erişilebilirlik,
// etkileşim, olaylar, modül anahtarı ve ekran.
//
// **Nereden çıktı.** Paket BP apartmanı metinde yaşattı ve kendi
// dosyasına şunu yazdı: "Komşu ve apartman metinde yaşar; yeni kişi
// kaydı açılmaz. Komşunun kalıcı kişi olması ayrı bir paket." Yol
// haritası da aynı şeyi söylüyordu. Bu dosya o paketin bekçisi.
//
// **Ölçüldü (200'er hayat, iki blok, anahtar açık/kapalı):** komşu
// tanıyan hayat 145/200 ve 149/200; hayat başına tanınan komşu 2,88 ve
// 2,70; komşu olayı gören hayat 144/200, hayat başına görülen olay
// 4,77; komşuluktan arkadaşı olan hayat 38/200 ve 34/200. Anahtar
// kapalıyken hepsi **sıfır**. Ayrıntı: PROJECT_STATUS.
library;

import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/data/event_pool_neighbour.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/domain/features/feature_catalog.dart';
import 'package:bir_omur/domain/features/feature_events.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/generation/neighbours.dart';
import 'package:bir_omur/domain/interaction/friendship_depth.dart';
import 'package:bir_omur/domain/interaction/interaction_policy.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:bir_omur/domain/models/interaction.dart';
import 'package:bir_omur/domain/models/kinship.dart';
import 'package:bir_omur/domain/models/owned_item.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/player_bot.dart';

/// Kendi evinde oturan bir hayat; istenirse komşu listesi verilir.
GameState _hayat({
  bool kendiEvinde = true,
  bool kirada = false,
  bool anahtarAcik = true,
  List<Person> komsular = const <Person>[],
  /// Komşunun şehri oyuncunun şehrine eşitlenir mi? `false` ise bilerek
  /// **başka** bir şehir yazılır (erişilebilirlik testi için).
  bool ayniSehir = true,
}) {
  final GameState taban =
      LifeGenerator.seeded(515).generate(mode: StartMode.tamamenRastgele);
  return taban.copyWith(
    player: taban.player.copyWith(age: 34, wallet: 400000),
    items: kendiEvinde
        ? <OwnedItem>[
            const OwnedItem(
              id: 'ev-1',
              typeId: 'daire_kucuk',
              acquiredAtAge: 30,
              purchasePrice: 3000000,
            ),
          ]
        : const <OwnedItem>[],
    people: List<Person>.unmodifiable(<Person>[
      ...taban.people,
      // Komşunun şehri oyuncunun şehridir; tohumun şehri ne olursa
      // olsun test o şehre göre kurulur.
      for (final Person k in komsular)
        k.copyWith(
          city: ayniSehir
              ? taban.player.currentCity
              : (taban.player.currentCity == 'Trabzon'
                  ? 'İzmir'
                  : 'Trabzon'),
        ),
    ]),
    residenceItemId: kendiEvinde ? 'ev-1' : null,
    movedOut: kendiEvinde || kirada,
    settings: taban.settings.copyWith(
      features: anahtarAcik
          ? FeatureSwitches.defaults
          : FeatureSwitches.defaults.toggled(FeatureId.komsular, false),
    ),
  );
}

Person _komsu({
  required String id,
  required String homeTie,
  int bond = 15,
  RelationType relation = RelationType.komsu,
  String city = 'İstanbul',
}) =>
    Person(
      id: id,
      firstName: 'Sema',
      lastName: 'Demir',
      gender: Gender.kadin,
      relation: relation,
      age: 52,
      isAlive: true,
      inPlayerHousehold: false,
      employment: EmploymentStatus.calisiyor,
      occupation: 'terzi',
      wealth: WealthTier.ortaHalli,
      bond: bond,
      city: city,
      homeTie: homeTie,
    );

void main() {
  // ===================================================================
  // Bağ türü
  // ===================================================================
  group('Komşu bağ türü', () {
    test('kendi öbeğinde durur, akraba ve hane bağı değildir', () {
      expect(RelationType.komsu.group, RelationGroup.komsular);
      expect(RelationType.eskiKomsu.group, RelationGroup.komsular);
      expect(RelationType.komsu.kanBagi, isFalse);
      expect(RelationType.komsu.haneBagi, isFalse);
      expect(RelationGroup.komsular.title, 'Komşular');
    });

    test('etiketleri yazılı', () {
      expect(
        relationLabel(
          relation: RelationType.komsu,
          gender: Gender.kadin,
          personAge: 52,
          playerAge: 34,
        ),
        'Komşu',
      );
      expect(
        relationLabel(
          relation: RelationType.eskiKomsu,
          gender: Gender.erkek,
          personAge: 60,
          playerAge: 40,
        ),
        'Eski komşu',
      );
      expect(
        relationPossessive(
          relation: RelationType.komsu,
          gender: Gender.kadin,
          personAge: 52,
          playerAge: 34,
        ),
        'Komşun',
      );
    });

    test('komşu akrabalık yasağına girmez', () {
      // Akraba değildir; romantik yol bu pakette açılmadı ama bu bir
      // akrabalık yasağı değil (Q-217).
      expect(Kinship.isRomanceForbidden(RelationType.komsu), isFalse);
      expect(Kinship.isRomanceForbidden(RelationType.eskiKomsu), isFalse);
    });

    test('komşuyla sohbet, vakit ve hediye anlamlı; eski komşuyla yok', () {
      final Set<InteractionKind> komsu =
          meaningfulKindsFor(RelationType.komsu);
      expect(komsu, contains(InteractionKind.sohbet));
      expect(komsu, contains(InteractionKind.vakitGecir));
      expect(komsu, contains(InteractionKind.hediyeVer));
      expect(komsu, isNot(contains(InteractionKind.paraIste)));
      expect(meaningfulKindsFor(RelationType.eskiKomsu), isEmpty);
    });

    test('komşu yakın arkadaşlığa teklif edilebilir', () {
      final Person yakin = _komsu(id: 'k1', homeTie: 'ev:ev-1', bond: 70);
      final GameState s = _hayat(komsular: <Person>[yakin]);
      expect(
        FriendshipDepth.closeFriendAvailability(s, yakin.id).isAllowed,
        isTrue,
        reason: 'bağ eşiği geçen komşuya teklif açık olmalı',
      );
    });
  });

  // ===================================================================
  // Ev bağı ve erişilebilirlik
  // ===================================================================
  group('Komşuluk evin bağıdır', () {
    test('anahtar kendi evinde, kirada ve aile yanında farklı', () {
      expect(Neighbours.keyOf(_hayat()), 'ev:ev-1');
      expect(
        Neighbours.keyOf(_hayat(kendiEvinde: false, kirada: true)),
        startsWith('kira:'),
      );
      expect(
        Neighbours.keyOf(_hayat(kendiEvinde: false)),
        isNull,
        reason: 'ailesinin yanında yaşayanın komşuluk anahtarı olmaz',
      );
    });

    test('aynı şehirdeki komşu erişilebilir, eski komşu değil', () {
      final GameState s = _hayat(
        komsular: <Person>[
          _komsu(id: 'k1', homeTie: 'ev:ev-1'),
          _komsu(
            id: 'k2',
            homeTie: 'ev:eski',
            relation: RelationType.eskiKomsu,
          ),
        ],
      );
      expect(s.isReachable(s.personById('k1')!), isTrue);
      expect(s.isReachable(s.personById('k2')!), isFalse);
    });

    test('başka şehirdeki komşu gündelik listeye girmez', () {
      final GameState s = _hayat(
        ayniSehir: false,
        komsular: <Person>[_komsu(id: 'k1', homeTie: 'ev:ev-1')],
      );
      final Person k = s.personById('k1')!;
      expect(k.city, isNot(s.player.currentCity));
      expect(s.isReachable(k), isFalse);
    });
  });

  // ===================================================================
  // Üretim ve devir
  // ===================================================================
  group('Komşu üretimi ve devri', () {
    test('kendi evinde komşu üretilir ve ev bağı yazılır', () {
      final NeighbourUpdate u = Neighbours.reconcile(_hayat(), Random(4));
      final List<Person> komsular = Neighbours.current(u.state);
      expect(komsular, isNotEmpty);
      expect(komsular.length,
          lessThanOrEqualTo(Neighbours.prototypeOnlyMaxCount));
      for (final Person k in komsular) {
        expect(k.homeTie, 'ev:ev-1');
        expect(k.relation, RelationType.komsu);
        expect(k.inPlayerHousehold, isFalse);
        expect(k.bond,
            lessThanOrEqualTo(Neighbours.prototypeOnlyStartBondMax));
        expect(k.city, u.state.player.currentCity);
      }
      expect(u.logLines, isNotEmpty, reason: 'tanışma günlüğe yazılır');
    });

    test('ailesinin yanında yaşayana komşu üretilmez', () {
      final NeighbourUpdate u =
          Neighbours.reconcile(_hayat(kendiEvinde: false), Random(4));
      expect(Neighbours.current(u.state), isEmpty);
      expect(
        u.state.people.where((Person p) => p.relation == RelationType.komsu),
        isEmpty,
      );
    });

    test('taşınınca uzak komşu eski komşu olur, yakın olan arkadaş', () {
      final GameState once = _hayat(
        komsular: <Person>[
          _komsu(id: 'k1', homeTie: 'ev:eski-ev', bond: 20),
          _komsu(id: 'k2', homeTie: 'ev:eski-ev', bond: 80),
        ],
      );
      final NeighbourUpdate u = Neighbours.reconcile(once, Random(9));
      expect(u.state.personById('k1')!.relation, RelationType.eskiKomsu);
      final Person k2 = u.state.personById('k2')!;
      expect(k2.relation, RelationType.arkadas,
          reason: 'yakınlığı yüksek komşuyla görüşmeye devam edilir');
      expect(k2.homeTie, 'ev:eski-ev',
          reason: 'nerede tanışıldığı kayıtta kalır');
      expect(k2.becameFriendAtAge, isNotNull);
      // Yeni evin komşuları da aynı turda tanınır.
      expect(Neighbours.current(u.state), isNotEmpty);
    });

    test('düzen uyumluysa hiçbir şey değişmez', () {
      final GameState s = _hayat(
        komsular: <Person>[_komsu(id: 'k1', homeTie: 'ev:ev-1')],
      );
      final NeighbourUpdate u = Neighbours.reconcile(s, Random(1));
      expect(u.state.people.length, s.people.length);
      expect(u.logLines, isEmpty);
    });

    test('anahtar kapalıyken komşu üretilmez', () {
      final NeighbourUpdate u =
          Neighbours.reconcile(_hayat(anahtarAcik: false), Random(4));
      expect(Neighbours.current(u.state), isEmpty);
      expect(u.state.people.length, _hayat(anahtarAcik: false).people.length);
      expect(u.logLines, isEmpty);
    });

    test('komşu kaydı kapat-aç ile korunur', () {
      final GameState s = Neighbours.reconcile(_hayat(), Random(7)).state;
      final GameState geri = decodeGameState(encodeGameState(s));
      final List<Person> komsular = Neighbours.current(geri);
      expect(komsular.length, Neighbours.current(s).length);
      expect(komsular.first.homeTie, 'ev:ev-1');
      expect(komsular.first.relation, RelationType.komsu);
    });
  });

  // ===================================================================
  // Olaylar
  // ===================================================================
  group('Komşu olayları', () {
    test('her olay gerçek bir komşuyu hedefler', () {
      expect(kNeighbourEvents.length, greaterThanOrEqualTo(10));
      for (final GameEvent olay in kNeighbourEvents) {
        expect(
          olay.requirement.livingRelations,
          contains(RelationType.komsu),
          reason: '${olay.id} komşu koşulu taşımıyor',
        );
        expect(olay.requirement.requireReachable, isTrue,
            reason: '${olay.id} erişilebilirlik istemiyor');
        expect(olay.text, contains('{kisi}'),
            reason: '${olay.id} metninde komşunun adı geçmiyor');
      }
    });

    test('havuz modüle bağlı ve anahtar kapalıyken hiç listelenmez', () {
      final Set<String> idler = FeatureEvents.idsOf(FeatureId.komsular);
      expect(idler.length, kNeighbourEvents.length);
      final GameState kapali = _hayat(anahtarAcik: false);
      for (final String id in idler) {
        expect(FeatureEvents.allowed(kapali, id), isFalse,
            reason: '$id kapalı modülde aday olmamalı');
      }
      final GameState acik = _hayat();
      for (final String id in idler) {
        expect(FeatureEvents.allowed(acik, id), isTrue);
      }
    });

    test('bırakılan her izin karşılığı var', () {
      final Set<String> birakilan = <String>{
        for (final GameEvent o in kNeighbourEvents)
          for (final EventChoice s in o.choices) ...s.addFlags,
      };
      final Set<String> okunan = <String>{
        for (final GameEvent o in kNeighbourEvents)
          ...o.requirement.requiredFlags,
        for (final GameEvent o in kNeighbourEvents)
          ...o.requirement.forbiddenFlags,
      };
      expect(birakilan, isNotEmpty);
      for (final String iz in birakilan) {
        expect(okunan, contains(iz),
            reason: '$iz izi hiçbir yerde okunmuyor (sessiz iz)');
      }
    });
  });

  // ===================================================================
  // Ölçüm tabanı
  // ===================================================================
  group('Komşuluk hunisi', () {
    test('ÖLÇÜM: 60 hayatta komşu tanınıyor ve olayları çıkıyor', () {
      const int kHayat = 60;
      int komsuGoren = 0;
      int olayGoren = 0;
      final Set<String> buOlaylari = FeatureEvents.idsOf(FeatureId.komsular);
      for (int i = 0; i < kHayat; i++) {
        final BotLifeResult r = playBotLife(
          archetype: PlayerArchetype.values[i % PlayerArchetype.values.length],
          seed: 6100 + i * 23,
        );
        if (r.neighboursMet > 0) komsuGoren++;
        if (r.seenEvents.any(buOlaylari.contains)) olayGoren++;
      }
      // Ölçülen: 145/200 ve 149/200 (yaklaşık %73). Taban yarısı.
      expect(komsuGoren, greaterThanOrEqualTo(30),
          reason: 'komşu tanıyan hayat $komsuGoren/$kHayat: komşu '
              'üretimi ya da kapısı bozulmuş olabilir');
      // Ölçülen: 144/200 (%72). Taban üçte bir.
      expect(olayGoren, greaterThanOrEqualTo(20),
          reason: 'komşu olayı gören hayat $olayGoren/$kHayat: havuz '
              'erişilemez hâle gelmiş olabilir');
    });
  });

  // ===================================================================
  // Ekran
  // ===================================================================
  group('Komşular ekranı', () {
    testWidgets('İlişkiler ekranında satır ve liste görünür',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 6000);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final GameController controller = GameController(random: Random(6));
      addTearDown(controller.dispose);
      await tester.pumpWidget(BirOmurApp(controller: controller));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rastgele bir hayat'));
      await tester.pumpAndSettle();

      controller.debugSetState(
        _hayat(komsular: <Person>[_komsu(id: 'k1', homeTie: 'ev:ev-1')]),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tab_iliskiler')));
      await tester.pumpAndSettle();

      final Finder satir =
          find.byKey(const Key('relationships_neighbours_row'));
      expect(satir, findsOneWidget);
      await tester.ensureVisible(satir);
      await tester.pumpAndSettle();
      await tester.tap(satir);
      await tester.pumpAndSettle();

      expect(find.text('Komşular'), findsWidgets);
      expect(find.textContaining('Sema'), findsWidgets);
    });

    testWidgets('komşusu olmayan hayatta satır çıkmaz',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 6000);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final GameController controller = GameController(random: Random(8));
      addTearDown(controller.dispose);
      await tester.pumpWidget(BirOmurApp(controller: controller));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rastgele bir hayat'));
      await tester.pumpAndSettle();

      controller.debugSetState(_hayat(anahtarAcik: false));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tab_iliskiler')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('relationships_neighbours_row')),
        findsNothing,
      );
    });
  });
}
