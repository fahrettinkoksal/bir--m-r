import 'dart:math';

import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/domain/generation/generation_continuation.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/person_development.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/stats.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:flutter_test/flutter_test.dart';

/// Kuşak devamında torunların kaybolmaması (D-087).
///
/// Faho'nun bildirdiği hata: "ölüp çocuğumun hayatı ile devam ettiğimde
/// torunlarım vardı, fakat çocuğumun hayatına geçtiğimde çocuklarım
/// görünmedi."
void main() {
  Person cocuk(String id, {int age = 40}) => Person(
        id: id,
        firstName: 'Çocuk$id',
        lastName: 'Demir',
        gender: Gender.kadin,
        relation: RelationType.cocuk,
        age: age,
        isAlive: true,
        inPlayerHousehold: false,
        employment: EmploymentStatus.calisiyor,
        occupation: 'öğretmen',
        wealth: WealthTier.ortaHalli,
        bond: 70,
        development: const PersonDevelopment(
          tracksLife: true,
          stats: Stats(
            appearance: 60,
            happiness: 60,
            health: 70,
            intelligence: 60,
            charisma: 60,
          ),
        ),
      );

  Person torun(String id, String ebeveynId, {int age = 8}) => Person(
        id: id,
        firstName: 'Torun$id',
        lastName: 'Demir',
        gender: Gender.erkek,
        relation: RelationType.torun,
        age: age,
        isAlive: true,
        inPlayerHousehold: false,
        employment: EmploymentStatus.cocuk,
        wealth: null,
        bond: 60,
        development: PersonDevelopment(
          tracksLife: true,
          otherParentId: ebeveynId,
          stats: const Stats(
            appearance: 60,
            happiness: 60,
            health: 70,
            intelligence: 60,
            charisma: 60,
          ),
        ),
      );

  GameState olmusHayat() {
    final GameState base =
        LifeGenerator.seeded(7).generate(mode: StartMode.tamamenRastgele);
    return base.copyWith(
      player: base.player.copyWith(age: 78, wallet: 500000),
      people: List<Person>.unmodifiable(<Person>[
        ...base.people.where((Person p) => p.relation != RelationType.cocuk),
        cocuk('cocuk-A'),
        cocuk('cocuk-B'),
        torun('torun-A1', 'cocuk-A'),
        torun('torun-A2', 'cocuk-A', age: 3),
        torun('torun-B1', 'cocuk-B'),
      ]),
      deceased: true,
      deathAge: 78,
    );
  }

  test('devam edilen çocuğun torunları onun çocuğu olur', () {
    final GameState olu = olmusHayat();
    final ({GameState? state, String blockReason}) r =
        GenerationContinuation.continueAs(olu, 'cocuk-A', Random(1));
    expect(r.state, isNotNull, reason: r.blockReason);

    final GameState yeni = r.state!;
    final List<Person> cocuklar = yeni.people
        .where((Person p) => p.relation == RelationType.cocuk)
        .toList(growable: false);
    final Set<String> idler = cocuklar.map((Person p) => p.id).toSet();

    expect(idler, contains('torun-A1'),
        reason: 'Devam edilen çocuğun torunu, yeni oyuncunun çocuğu olmalı');
    expect(idler, contains('torun-A2'));
    expect(idler, isNot(contains('torun-B1')),
        reason: 'Başka çocuğun torunu, yeni oyuncunun çocuğu değildir');
  });

  test('diğer çocuğun torunu silinmez, yeğen olur', () {
    final GameState olu = olmusHayat();
    final GameState yeni =
        GenerationContinuation.continueAs(olu, 'cocuk-A', Random(2)).state!;

    final Person? b1 = yeni.personById('torun-B1');
    expect(b1, isNotNull, reason: 'Kayıt silinmemeli');
    expect(b1!.relation, RelationType.yegen);
  });

  test('hiçbir torun kaydı kaybolmaz', () {
    final GameState olu = olmusHayat();
    final List<String> oncekiTorunlar = olu.people
        .where((Person p) => p.relation == RelationType.torun)
        .map((Person p) => p.id)
        .toList(growable: false);
    expect(oncekiTorunlar, hasLength(3));

    final GameState yeni =
        GenerationContinuation.continueAs(olu, 'cocuk-A', Random(3)).state!;
    for (final String id in oncekiTorunlar) {
      expect(yeni.personById(id), isNotNull, reason: '$id kayboldu');
    }
  });

  test('küçük yaştaki yeni çocuk hanede yaşar', () {
    final GameState olu = olmusHayat();
    final GameState yeni =
        GenerationContinuation.continueAs(olu, 'cocuk-A', Random(4)).state!;
    expect(yeni.personById('torun-A2')!.inPlayerHousehold, isTrue);
  });

  test('yeni kuşak kapat-aç ile korunur', () {
    final GameState olu = olmusHayat();
    final GameState yeni =
        GenerationContinuation.continueAs(olu, 'cocuk-A', Random(5)).state!;
    final GameState geri = decodeGameState(encodeGameState(yeni));
    expect(geri.personById('torun-A1')!.relation, RelationType.cocuk);
    expect(geri.personById('torun-B1')!.relation, RelationType.yegen);
  });

  test('devam edilen çocuğun kendisi kişi listesinden çıkar', () {
    final GameState olu = olmusHayat();
    final GameState yeni =
        GenerationContinuation.continueAs(olu, 'cocuk-A', Random(6)).state!;
    expect(yeni.personById('cocuk-A'), isNull);
    // Kardeş olarak duran diğer çocuk kayıtta kalır.
    expect(yeni.personById('cocuk-B')!.relation, RelationType.kardes);
  });
}
