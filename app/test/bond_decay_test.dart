import 'dart:math';

import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/generation/life_progression.dart';
import 'package:bir_omur/domain/interaction/bond_decay.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/interaction.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_flow.dart';

/// Yetişkin, evden ayrılmış, annesiyle teması olan bir hayat.
GameState ayriEvde({int seed = 5, int age = 30, int bond = 70}) {
  final GameState temel =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  final List<Person> kisiler = temel.people
      .map((Person p) => p.copyWith(
            bond: bond,
            inPlayerHousehold: false,
          ))
      .toList(growable: false);
  return temel.copyWith(
    player: temel.player.copyWith(age: age),
    people: kisiler,
    movedOut: true,
  );
}

Person anneOf(GameState state) =>
    state.people.firstWhere((Person p) => p.relation == RelationType.anne);

void main() {
  group('İlgisizlik bağı zayıflatır', () {
    test('hoşgörü yılları içinde bağ düşmez', () {
      final GameState state = ayriEvde();
      final Person anne = anneOf(state);
      final GameState temasli = state.copyWith(
        lastInteractionAge: <String, int>{
          anne.id: state.player.age - BondDecay.prototypeOnlyGraceYears,
        },
      );
      final BondDecayResult sonuc = BondDecay.applyYear(temasli);
      expect(sonuc.changed, isFalse);
    });

    test('hoşgörü yılı aşılınca bağ düşer', () {
      final GameState state = ayriEvde();
      final Person anne = anneOf(state);
      final GameState ihmal = state.copyWith(
        lastInteractionAge: <String, int>{
          anne.id: state.player.age - BondDecay.prototypeOnlyGraceYears - 1,
        },
      );
      final BondDecayResult sonuc = BondDecay.applyYear(ihmal);
      expect(sonuc.weakened, contains(anne.id));
      final Person sonra =
          sonuc.people.firstWhere((Person p) => p.id == anne.id);
      expect(sonra.bond, anne.bond - BondDecay.prototypeOnlyBloodLoss);
    });

    test('aynı evde yaşayan kişi zayıflamaz', () {
      final GameState state = ayriEvde();
      final Person anne = anneOf(state);
      final GameState evde = state.copyWith(
        people: state.people
            .map((Person p) =>
                p.id == anne.id ? p.copyWith(inPlayerHousehold: true) : p)
            .toList(growable: false),
        lastInteractionAge: <String, int>{anne.id: 0},
      );
      expect(BondDecay.decays(evde, anneOf(evde)), isFalse);
      expect(BondDecay.applyYear(evde).changed, isFalse);
    });

    test('hiç temas kaydı yokken ilk yıl yalnızca sayaç başlar', () {
      // Geriye dönük geçmiş uydurulmaz: o yıl kayıp olmaz, yalnızca
      // "son temas" o yaşa yazılır.
      final GameState state = ayriEvde();
      expect(state.lastInteractionAge, isEmpty);
      final BondDecayResult sonuc = BondDecay.applyYear(state);
      expect(sonuc.changed, isFalse);
      expect(
        sonuc.lastInteractionAge[anneOf(state).id],
        state.player.age,
      );
    });

    test('sayaç başladıktan sonra hoşgörü yılları geçince kayıp başlar', () {
      GameState akan = ayriEvde(age: 30, bond: 80);
      final String anneId = anneOf(akan).id;
      final int once = akan.personById(anneId)!.bond;

      // İlk yıl sayaç başlar, sonraki hoşgörü yıllarında kayıp yok.
      for (int i = 0; i <= BondDecay.prototypeOnlyGraceYears; i++) {
        final BondDecayResult s = BondDecay.applyYear(akan);
        akan = akan.copyWith(
          people: s.people,
          lastInteractionAge: s.lastInteractionAge,
        );
        akan = akan.copyWith(
          player: akan.player.copyWith(age: akan.player.age + 1),
        );
      }
      expect(akan.personById(anneId)!.bond, once);

      // Bir yıl daha geçince düşer.
      final BondDecayResult son = BondDecay.applyYear(akan);
      expect(son.weakened, contains(anneId));
    });

    test('kan bağı tabanın altına ilgisizlikten düşmez', () {
      final GameState state = ayriEvde(
        bond: BondDecay.prototypeOnlyBloodFloor + 1,
      );
      final Person anne = anneOf(state);
      GameState akan = state.copyWith(
        lastInteractionAge: <String, int>{anne.id: 0},
      );
      for (int i = 0; i < 30; i++) {
        final BondDecayResult sonuc = BondDecay.applyYear(akan);
        akan = akan.copyWith(people: sonuc.people);
      }
      final Person sonra = akan.personById(anne.id)!;
      expect(sonra.bond, BondDecay.prototypeOnlyBloodFloor);
      expect(sonra.bond, greaterThan(0), reason: 'Anne annedir');
    });

    test('kan bağı dışındaki bağ sıfıra kadar düşebilir', () {
      final GameState temel = ayriEvde(bond: 40);
      final Person aday = temel.people.first;
      final GameState arkadasli = temel.copyWith(
        people: <Person>[
          aday.copyWith(relation: RelationType.arkadas, bond: 40),
          ...temel.people.skip(1),
        ],
        lastInteractionAge: <String, int>{aday.id: 0},
      );
      GameState akan = arkadasli;
      for (int i = 0; i < 40; i++) {
        akan = akan.copyWith(people: BondDecay.applyYear(akan).people);
      }
      expect(akan.personById(aday.id)!.bond, 0);
    });

    test('erişilemeyen kişi ilgisizlikten cezalandırılmaz', () {
      // Yıllar önceki bir okul tanıdığı zaten aranamıyor.
      final GameState temel = ayriEvde();
      final Person aday = temel.people.first;
      final GameState uzak = temel.copyWith(
        people: <Person>[
          aday.copyWith(
            relation: RelationType.sinifArkadasi,
            classId: 'baska-sinif',
            city: 'Uzakşehir',
          ),
          ...temel.people.skip(1),
        ],
        lastInteractionAge: <String, int>{aday.id: 0},
      );
      final Person uzaktaki = uzak.personById(aday.id)!;
      expect(uzak.isReachable(uzaktaki), isFalse);
      expect(BondDecay.decays(uzak, uzaktaki), isFalse);
    });

    test('vefat etmiş kişinin bağı değişmez', () {
      final GameState temel = ayriEvde();
      final Person aday = temel.people.first;
      final GameState olu = temel.copyWith(
        people: <Person>[
          aday.copyWith(isAlive: false),
          ...temel.people.skip(1),
        ],
        lastInteractionAge: <String, int>{aday.id: 0},
      );
      final BondDecayResult sonuc = BondDecay.applyYear(olu);
      expect(sonuc.weakened, isNot(contains(aday.id)));
    });
  });

  group('Yaş alırken uygulanır', () {
    test('ihmal edilen bağ yıl geçtikçe düşer', () {
      final GameState state = ayriEvde(age: 30, bond: 80);
      final Person anne = anneOf(state);
      GameState akan = state.copyWith(
        lastInteractionAge: <String, int>{anne.id: 20},
      );
      final int once = akan.personById(anne.id)!.bond;
      for (int i = 0; i < 5; i++) {
        akan = LifeProgression(Random(7)).advanceOneYear(akan);
        if (akan.deceased) break;
        // Olay ekranda kalırsa yıl ilerlemez.
        akan = akan.copyWith(pendingEvent: null);
      }
      expect(akan.personById(anne.id)!.bond, lessThan(once));
    });

    test('görüşülen kişinin bağı düşmez', () {
      final GameController c = GameController(random: Random(11));
      c.startNewLife(mode: StartMode.tamamenRastgele, seed: 11);
      advanceToAge(c, 12);
      resolvePendingEvents(c);
      final Person anne = anneOf(c.state!);
      final int once = c.state!.personById(anne.id)!.bond;

      // Her yıl görüşülürse ilgisizlik hiç başlamaz.
      for (int i = 0; i < 8 && !c.state!.deceased; i++) {
        c.interact(anne.id, InteractionKind.vakitGecir);
        resolvePendingEvents(c);
        // Lise alanı seçilmeden yaş atlanmaz (D-094).
        resolveTrackChoice(c);
        c.ageUp();
        resolvePendingEvents(c);
      }
      if (c.state!.deceased) return;
      expect(
        c.state!.personById(anne.id)!.bond,
        greaterThanOrEqualTo(once),
        reason: 'Düzenli görüşülen kişide ilgisizlik kaybı olmamalı',
      );
    });

    test('araya belirgin mesafe girince günlüğe bir satır düşer', () {
      final GameState state = ayriEvde(
        age: 40,
        bond: BondDecay.prototypeOnlyNoticeBond + 1,
      );
      final Person anne = anneOf(state);
      final GameState ihmal = state.copyWith(
        lastInteractionAge: <String, int>{anne.id: 20},
      );
      final BondDecayResult sonuc = BondDecay.applyYear(ihmal);
      final String? satir = BondDecay.logLineFor(ihmal, sonuc);
      expect(satir, isNotNull);
      expect(satir, contains(anne.fullName));
    });

    test('her yıl günlüğe satır yazılmaz', () {
      // Eşik geçilmediği sürece günlük dolup taşmamalı.
      final GameState state = ayriEvde(age: 40, bond: 90);
      final Person anne = anneOf(state);
      final GameState ihmal = state.copyWith(
        lastInteractionAge: <String, int>{anne.id: 20},
      );
      final BondDecayResult sonuc = BondDecay.applyYear(ihmal);
      expect(sonuc.changed, isTrue);
      expect(BondDecay.logLineFor(ihmal, sonuc), isNull);
    });
  });
}
