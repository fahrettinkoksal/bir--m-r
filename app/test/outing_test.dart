import 'dart:math';

import 'package:bir_omur/data/activity_catalog.dart';
import 'package:bir_omur/domain/activities/activity_engine.dart';
import 'package:bir_omur/domain/activities/outing.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/interaction/shared_history.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/life_log.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:flutter_test/flutter_test.dart';

const ActivityEngine motor = ActivityEngine();

ActivityAction eylem(String id) =>
    kActivityActions.firstWhere((ActivityAction a) => a.id == id);

Person kisi({
  String id = 'kisi-1',
  RelationType relation = RelationType.arkadas,
  int age = 30,
  int bond = 70,
  bool alive = true,
  bool household = true,
  String? city,
}) =>
    Person(
      id: id,
      firstName: 'Kerem',
      lastName: 'Aydın',
      relation: relation,
      gender: Gender.erkek,
      age: age,
      bond: bond,
      isAlive: alive,
      inPlayerHousehold: household,
      employment: EmploymentStatus.issiz,
      wealth: WealthTier.ortaHalli,
      city: city,
    );

GameState hayat({
  int age = 30,
  int wallet = 500000,
  List<Person> people = const <Person>[],
}) {
  final GameState taban =
      LifeGenerator.seeded(11).generate(mode: StartMode.tamamenRastgele);
  return taban.copyWith(
    pendingEvent: null,
    notices: const <PendingNotice>[],
    pets: const <Pet>[],
    people: people,
    player: taban.player.copyWith(age: age, wallet: wallet),
  );
}

void main() {
  group('Kimler katılabilir', () {
    test('eş, sevgili, çocuk, anne, baba, kardeş ve yakın arkadaş', () {
      const List<RelationType> beklenen = <RelationType>[
        RelationType.es,
        RelationType.sevgili,
        RelationType.cocuk,
        RelationType.anne,
        RelationType.baba,
        RelationType.kardes,
        RelationType.arkadas,
      ];
      for (final RelationType r in beklenen) {
        final Person p = kisi(relation: r, age: 30);
        final GameState s = hayat(people: <Person>[p]);
        expect(
          Outing.companionAvailability(s, eylem('sinema'), p).isAllowed,
          isTrue,
          reason: r.name,
        );
      }
    });

    test('uzak akraba ya da iş arkadaşı katılmaz', () {
      for (final RelationType r in <RelationType>[
        RelationType.anneTarafiDede,
        RelationType.hala,
        RelationType.ogretmen,
      ]) {
        final Person p = kisi(relation: r, id: 'uzak', household: false);
        final GameState s = hayat(people: <Person>[p]);
        expect(
          Outing.companionAvailability(s, eylem('sinema'), p).isAllowed,
          isFalse,
          reason: r.name,
        );
      }
    });

    test('vefat etmiş kişi yanına gelmez', () {
      final Person olu = kisi(alive: false, relation: RelationType.anne);
      final GameState s = hayat(people: <Person>[olu]);
      expect(
        Outing.companionAvailability(s, eylem('sinema'), olu).isAllowed,
        isFalse,
      );
      expect(Outing.companionsFor(s, eylem('sinema')), isEmpty);
    });

    test('kayıtta olmayan kişi yanına gelmez', () {
      final GameState s = hayat();
      expect(
        Outing.companionAvailability(s, eylem('sinema'), kisi()).isAllowed,
        isFalse,
      );
    });

    test('başka şehirdeki arkadaş bir anda yanında belirmez', () {
      final GameState taban = hayat();
      final Person uzak = kisi(
        relation: RelationType.arkadas,
        household: false,
        city: '${taban.player.currentCity} değil',
      );
      final GameState s = taban.copyWith(people: <Person>[uzak]);
      expect(s.isReachable(uzak), isFalse);
      expect(
        Outing.companionAvailability(s, eylem('sinema'), uzak).isAllowed,
        isFalse,
      );
    });

    test('uzak arkadaş değil de yakın arkadaş katılır', () {
      final Person uzakBag = kisi(
        bond: Outing.prototypeOnlyCloseFriendBond - 1,
      );
      final Person yakin = kisi(
        id: 'kisi-2',
        bond: Outing.prototypeOnlyCloseFriendBond,
      );
      final GameState s = hayat(people: <Person>[uzakBag, yakin]);
      expect(
        Outing.companionAvailability(s, eylem('sinema'), uzakBag).isAllowed,
        isFalse,
      );
      expect(
        Outing.companionAvailability(s, eylem('sinema'), yakin).isAllowed,
        isTrue,
      );
    });

    test('yaşı uymayan kişi katılmaz', () {
      // Konser 13 yaşından itibaren.
      final Person kucuk = kisi(relation: RelationType.cocuk, age: 8);
      final GameState s = hayat(people: <Person>[kucuk]);
      expect(
        Outing.companionAvailability(s, eylem('konsere_git'), kucuk).isAllowed,
        isFalse,
      );
      expect(
        Outing.companionAvailability(s, eylem('sinema'), kucuk).isAllowed,
        isTrue,
      );
    });

    test('çok küçük çocuk hiçbir programa götürülmez', () {
      final Person bebek = kisi(relation: RelationType.cocuk, age: 2);
      final GameState s = hayat(people: <Person>[bebek]);
      for (final ActivityAction a in actionsAt(ActivityVenue.eglence)) {
        expect(
          Outing.companionAvailability(s, a, bebek).isAllowed,
          isFalse,
          reason: a.id,
        );
      }
    });

    test('yalnızca Eğlence eylemleri birlikte yapılır', () {
      for (final ActivityAction a in kActivityActions) {
        expect(
          Outing.supports(a),
          a.venue == ActivityVenue.eglence,
          reason: a.id,
        );
      }
      final Person p = kisi(relation: RelationType.es);
      final GameState s = hayat(people: <Person>[p]);
      expect(
        Outing.companionAvailability(s, eylem('sac_kestir'), p).isAllowed,
        isFalse,
      );
    });
  });

  group('Birlikte gitmek', () {
    test('ücret bir kez alınır: yalnız gitmekle aynı', () {
      final Person p = kisi(relation: RelationType.es);
      final GameState s = hayat(people: <Person>[p]);
      final ActivityAction a = eylem('sinema');

      final GameState yalniz =
          motor.perform(state: s, action: a, rng: Random(1)).state;
      final GameState birlikte = motor
          .perform(state: s, action: a, rng: Random(1), companion: p)
          .state;

      expect(yalniz.player.wallet, s.player.wallet - a.cost);
      expect(birlikte.player.wallet, yalniz.player.wallet);
    });

    test('mutluluk ve bağ gerçekten artar', () {
      final Person p = kisi(relation: RelationType.baba, bond: 50);
      final GameState s = hayat(people: <Person>[p]);
      final ActivityResult r = motor.perform(
        state: s,
        action: eylem('maca_git'),
        rng: Random(2),
        companion: p,
      );
      expect(r.outcome.applied, isTrue);
      expect(
        r.state.player.stats.happiness,
        greaterThan(s.player.stats.happiness),
      );
      expect(r.state.personById(p.id)!.bond, greaterThan(50));
    });

    test('ortak geçmişe tek satır düşer, kayıt ikilenmez', () {
      final Person p = kisi(relation: RelationType.anne);
      final GameState s = hayat(people: <Person>[p]);
      final GameState sonra = motor
          .perform(
            state: s,
            action: eylem('kafede_otur'),
            rng: Random(3),
            companion: p,
          )
          .state;

      final List<LifeLogEntry> yeni =
          sonra.log.sublist(s.log.length).toList(growable: false);
      expect(yeni, hasLength(1), reason: 'Tek kayıt yazılmalı');
      expect(yeni.single.personId, p.id);

      final List<SharedMoment> anlar =
          SharedHistory.of(sonra, sonra.personById(p.id)!);
      expect(
        anlar.where((SharedMoment m) => m.text == yeni.single.text).length,
        1,
      );
    });

    test('sahne metninde yer tutucu kalmaz ve kişinin adı geçer', () {
      for (final ActivityAction a in actionsAt(ActivityVenue.eglence)) {
        for (final RelationType r in Outing.companionRelations) {
          final Person p = kisi(relation: r, age: 30);
          final String sahne = Outing.sceneFor(a, p, Random(4));
          expect(sahne, contains(p.firstName), reason: '${a.id}/${r.name}');
          expect(sahne, isNot(contains('{kisi}')));
        }
      }
    });

    test('en az altı farklı sahne var', () {
      final Set<String> sahneler = <String>{};
      for (final ActivityAction a in actionsAt(ActivityVenue.eglence)) {
        for (final RelationType r in Outing.companionRelations) {
          sahneler.add(Outing.sceneFor(a, kisi(relation: r), Random(0)));
        }
      }
      expect(sahneler.length, greaterThanOrEqualTo(6));
    });

    test('çocukla maç ile sevgiliyle konser aynı sahne değil', () {
      final String mac = Outing.sceneFor(
        eylem('maca_git'),
        kisi(relation: RelationType.cocuk, age: 10),
        Random(0),
      );
      final String konser = Outing.sceneFor(
        eylem('konsere_git'),
        kisi(relation: RelationType.sevgili),
        Random(0),
      );
      expect(mac, isNot(konser));
    });

    test('aynı kişiyle tekrar çıkıldıkça bağ kazancı azalır', () {
      final Person p = kisi(relation: RelationType.kardes, bond: 20);
      GameState s = hayat(people: <Person>[p]);
      final ActivityAction a = eylem('parkta_yuruyus');
      final List<int> kazanclar = <int>[];
      for (int i = 0; i < a.maxPerAge; i++) {
        final int once = s.personById(p.id)!.bond;
        s = motor
            .perform(state: s, action: a, rng: Random(i), companion: p)
            .state;
        kazanclar.add(s.personById(p.id)!.bond - once);
      }
      expect(kazanclar.first, greaterThanOrEqualTo(kazanclar.last));
      expect(kazanclar.last, greaterThan(0), reason: 'Sıfıra inmemeli');
    });

    test('yıllık kota birlikte gidince de geçerlidir', () {
      final Person p = kisi(relation: RelationType.es);
      GameState s = hayat(people: <Person>[p]);
      final ActivityAction a = eylem('maca_git');
      for (int i = 0; i < a.maxPerAge; i++) {
        s = motor
            .perform(state: s, action: a, rng: Random(i), companion: p)
            .state;
      }
      final ActivityResult fazla = motor.perform(
        state: s,
        action: a,
        rng: Random(9),
        companion: p,
      );
      expect(fazla.outcome.applied, isFalse);
      expect(fazla.state.player.wallet, s.player.wallet);
    });

    test('katılamayacak kişiyle eylem hiç uygulanmaz', () {
      final Person olu = kisi(relation: RelationType.anne, alive: false);
      final GameState s = hayat(people: <Person>[olu]);
      final ActivityResult r = motor.perform(
        state: s,
        action: eylem('sinema'),
        rng: Random(1),
        companion: olu,
      );
      expect(r.outcome.applied, isFalse);
      expect(r.state.player.wallet, s.player.wallet);
      expect(r.state.log.length, s.log.length);
    });

    test('birlikte çıkmak anlamlı temas sayılır', () {
      final Person p = kisi(relation: RelationType.arkadas);
      final GameState s = hayat(people: <Person>[p]);
      final GameState sonra = motor
          .perform(
            state: s,
            action: eylem('sinema'),
            rng: Random(1),
            companion: p,
          )
          .state;
      expect(sonra.lastInteractionAge[p.id], sonra.player.age);
    });
  });

  group('Hatırlanabilirlik', () {
    test('ilk kez birlikte gidilen program hatırlanmaya değer', () {
      final Person p = kisi(relation: RelationType.baba);
      GameState s = hayat(people: <Person>[p]);
      final ActivityAction a = eylem('maca_git');
      expect(Outing.isMemorable(s, a, p), isTrue);

      s = motor
          .perform(state: s, action: a, rng: Random(1), companion: p)
          .state;
      expect(Outing.isMemorable(s, a, p), isFalse);
      // Aynı yıl başka bir program yine ilk kezdir.
      expect(Outing.isMemorable(s, eylem('sinema'), p), isTrue);
    });

    test('yıllar sonra ortak geçmişte hâlâ duruyor', () {
      final Person p = kisi(relation: RelationType.cocuk, age: 10);
      GameState s = hayat(people: <Person>[p]);
      final GameState sonra = motor
          .perform(
            state: s,
            action: eylem('sinema'),
            rng: Random(5),
            companion: p,
          )
          .state;
      final String sahne = sonra.log.last.text;

      // Yıllar geçsin: kayıt silinmez.
      s = sonra.copyWith(
        player: sonra.player.copyWith(age: sonra.player.age + 20),
        people: sonra.people
            .map((Person x) => x.copyWith(age: x.age + 20))
            .toList(growable: false),
      );
      final List<SharedMoment> anlar =
          SharedHistory.of(s, s.personById(p.id)!);
      expect(anlar.any((SharedMoment m) => m.text == sahne), isTrue);
    });
  });
}
