import 'package:flutter/foundation.dart';

import 'life_log.dart';
import 'parental_status.dart';
import 'person.dart';
import 'player_character.dart';
import 'relation.dart';

/// Tek bir hayatın tüm durumu.
///
/// Kişiler tek bir listede tutulur; Aile ekranı da ileride eklenecek olay
/// motoru da aynı kayıtları kullanır, böylece iki yerde farklı gerçeklik
/// oluşmaz.
@immutable
class GameState {
  const GameState({
    required this.seed,
    required this.player,
    required this.people,
    required this.pets,
    required this.parentalStatus,
    required this.log,
  });

  /// Üretimde kullanılan tohum. Tekrarlanabilir test senaryosu içindir;
  /// her oyuncuya sabit bir aile verilmez.
  final int seed;
  final PlayerCharacter player;
  final List<Person> people;
  final List<Pet> pets;
  final ParentalStatus parentalStatus;
  final List<LifeLogEntry> log;

  List<Person> get livingPeople =>
      people.where((Person p) => p.isAlive).toList(growable: false);

  /// Oyuncuyla aynı evde yaşayan, hayattaki kişiler.
  List<Person> get household => people
      .where((Person p) => p.isAlive && p.inPlayerHousehold)
      .toList(growable: false);

  Person? personById(String id) {
    for (final Person person in people) {
      if (person.id == id) return person;
    }
    return null;
  }

  List<Person> byGroup(RelationGroup group) => people
      .where((Person p) => p.relation.group == group)
      .toList(growable: false);

  GameState copyWith({
    PlayerCharacter? player,
    List<Person>? people,
    List<Pet>? pets,
    ParentalStatus? parentalStatus,
    List<LifeLogEntry>? log,
  }) {
    return GameState(
      seed: seed,
      player: player ?? this.player,
      people: people ?? this.people,
      pets: pets ?? this.pets,
      parentalStatus: parentalStatus ?? this.parentalStatus,
      log: log ?? this.log,
    );
  }
}
