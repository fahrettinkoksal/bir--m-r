import 'dart:math';

import 'package:bir_omur/domain/generation/generation_continuation.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/interaction/adoption.dart';
import 'package:bir_omur/domain/interaction/marriage_engine.dart';
import 'package:bir_omur/domain/interaction/parenthood.dart';
import 'package:bir_omur/domain/interaction/romance.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/parental_status.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/invariants.dart';

const Parenthood ebeveynlik = Parenthood();
const MarriageEngine evlilik = MarriageEngine();
const Adoption evlatEdinme = Adoption();

GameState oyuncu(int seed, {int age = 30, int wallet = 3000000}) {
  final GameState base =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  return base.copyWith(
    player: base.player.copyWith(age: age, wallet: wallet),
  );
}

({GameState state, Person partner}) sevgiliyle(int seed, {int bond = 85}) {
  final ({GameState state, Person partner}) r =
      const Romance().start(oyuncu(seed), Random(seed + 1));
  final GameState state = r.state.copyWith(
    people: r.state.people
        .map((Person p) => p.id == r.partner.id ? p.copyWith(bond: bond) : p)
        .toList(growable: false),
  );
  return (state: state, partner: state.personById(r.partner.id)!);
}

/// Oyuncuyu vefat ettirir ve çocuğu yetişkin yapar.
GameState olumAnina(GameState state, {int cocukYasi = 30}) {
  final int oyuncuYasi = state.player.age + cocukYasi;
  return state.copyWith(
    player: state.player.copyWith(age: oyuncuYasi),
    people: state.people
        .map((Person p) => p.relation == RelationType.cocuk
            ? p.copyWith(age: cocukYasi)
            : p.copyWith(age: p.age + cocukYasi))
        .toList(growable: false),
    deceased: true,
    deathAge: oyuncuYasi,
    deathCause: 'yaşlılık',
  );
}

void main() {
  test('evlilik dışı doğan çocukla devam edilince iki ebeveyn de korunur', () {
    final ({GameState state, Person partner}) v = sevgiliyle(201);
    final GameState dogum = ebeveynlik.haveChild(v.state, Random(2)).state;
    expect(dogum.marriage, isNull);
    final String cocukId = dogum.children.single.id;
    expect(
      dogum.children.single.development!.otherParentId,
      v.partner.id,
      reason: 'Diğer biyolojik ebeveyn kayda geçmeli',
    );

    final GameState olum = olumAnina(dogum);
    final GameState yeni =
        GenerationContinuation.continueAs(olum, cocukId, Random(3)).state!;

    // Sevgili artık çocuğun anne/babası; kayıt düşmedi.
    final Person digerEbeveyn = yeni.personById(v.partner.id)!;
    expect(
      digerEbeveyn.relation,
      anyOf(RelationType.anne, RelationType.baba),
    );
    // Vefat eden oyuncu da ebeveyn olarak kayıtta.
    expect(
      yeni.people.where((Person p) =>
          !p.isAlive &&
          (p.relation == RelationType.anne || p.relation == RelationType.baba)),
      isNotEmpty,
    );
    // Evlilik uydurulmadı.
    expect(yeni.parentalStatus, isNot(ParentalStatus.evli));
    expect(yeni.marriage, isNull);
    expect(checkInvariants(yeni), isEmpty);
  });

  test('evlat edinilen çocukla devam edilince bağlar ve kimliği korunur', () {
    GameState state = oyuncu(202);
    AdoptionResult? basarili;
    for (int seed = 0; seed < 40 && basarili == null; seed++) {
      final AdoptionResult r = evlatEdinme.apply(state, Random(seed));
      if (r.adopted) basarili = r;
    }
    state = basarili!.state;
    final Person evlatlik = state.children.single;
    final int zeka = evlatlik.development!.stats.intelligence;
    // Evlat edinilen çocukta uydurma bir biyolojik ebeveyn yazılmaz.
    expect(evlatlik.development!.otherParentId, isNull);

    final GameState olum = olumAnina(state, cocukYasi: 30);
    final GameState yeni =
        GenerationContinuation.continueAs(olum, evlatlik.id, Random(4)).state!;

    expect(yeni.player.firstName, evlatlik.firstName);
    // Özellikleri kuşak geçişinde yeniden çizilmedi.
    expect(yeni.player.stats.intelligence, zeka);
    // Vefat eden oyuncu ebeveyn olarak kayıtta kaldı.
    expect(
      yeni.people.where((Person p) =>
          !p.isAlive &&
          (p.relation == RelationType.anne || p.relation == RelationType.baba)),
      isNotEmpty,
    );
    expect(checkInvariants(yeni), isEmpty);
  });

  test('biyolojik çocukta evlilik varsa eş anne/baba olarak korunur', () {
    final ({GameState state, Person partner}) v = sevgiliyle(203, bond: 95);
    GameState state = v.state;
    for (int seed = 0; seed < 30 && !state.isMarried; seed++) {
      final GameState deneme =
          evlilik.propose(state, v.partner.id, Random(seed)).state;
      state = deneme.isMarried
          ? deneme
          : deneme.copyWith(
              player: deneme.player.copyWith(
                age: deneme.player.age +
                    MarriageEngine.prototypeOnlyProposalCooldown,
              ),
            );
    }
    expect(state.isMarried, isTrue);
    state = ebeveynlik.haveChild(state, Random(5)).state;
    final String cocukId = state.children.single.id;

    final GameState yeni = GenerationContinuation.continueAs(
      olumAnina(state),
      cocukId,
      Random(6),
    ).state!;

    expect(
      yeni.personById(v.partner.id)!.relation,
      anyOf(RelationType.anne, RelationType.baba),
    );
    expect(yeni.parentalStatus, ParentalStatus.evli);
    expect(checkInvariants(yeni), isEmpty);
  });
}
