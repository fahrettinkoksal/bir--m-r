import 'dart:math';

import '../../data/name_pool.dart';
import '../models/game_state.dart';
import '../models/gender.dart';
import '../models/person.dart';
import '../models/person_development.dart';
import '../models/relation.dart';
import '../models/stats.dart';
import '../models/wealth.dart';
import 'random_util.dart';
import 'trait_inheritance.dart';

/// Torunlar (Paket 12).
///
/// Yetişkin çocukların da kendi çocukları olabilir. Torun **gerçek bir
/// kişi kaydıdır**: kalıcı kimliği, kendi yaşı ve kendi özellikleri
/// vardır; kaydı silinmez. Doğumu, gerçekten olduğu yıl kaydedilir —
/// geriye dönük torun uydurulmaz.
///
/// Sayılar `prototypeOnly`'dir (Q-081).
abstract final class Grandchildren {
  /// prototypeOnly: çocuğun torun sahibi olabileceği yaş aralığı.
  static const int prototypeOnlyMinParentAge = 24;
  static const int prototypeOnlyMaxParentAge = 42;

  /// prototypeOnly: uygun bir yılda torun doğma ihtimali.
  static const double prototypeOnlyChance = 0.12;

  /// prototypeOnly: bir çocuğun sahip olabileceği en fazla çocuk.
  static const int prototypeOnlyMaxPerChild = 3;

  /// prototypeOnly: torunun başlangıç yakınlığı.
  static const int prototypeOnlyStartBond = 60;

  /// prototypeOnly: torun doğumunun mutluluk etkisi.
  static const int prototypeOnlyHappiness = 8;

  /// Bu çocuğun kayıtlı torunları.
  static List<Person> childrenOf(GameState state, String childId) =>
      state.people
          .where((Person p) =>
              p.relation == RelationType.torun &&
              p.development?.otherParentId == childId)
          .toList(growable: false);

  /// Oyuncunun bütün torunları (vefat edenler de listede kalır).
  static List<Person> all(GameState state) => state.people
      .where((Person p) => p.relation == RelationType.torun)
      .toList(growable: false);

  /// Bu yıl bu çocuktan bir torun doğar mı?
  ///
  /// Doğarsa yeni kişi döner; doğmazsa `null`. Vefat etmiş çocuk için
  /// hiçbir zaman torun üretilmez.
  static Person? maybeBorn({
    required GameState state,
    required Person child,
    required Random rng,
  }) {
    if (!child.isAlive) return null;
    if (child.relation != RelationType.cocuk) return null;
    if (child.age < prototypeOnlyMinParentAge) return null;
    if (child.age > prototypeOnlyMaxParentAge) return null;
    if (childrenOf(state, child.id).length >= prototypeOnlyMaxPerChild) {
      return null;
    }
    if (!rng.chance(prototypeOnlyChance)) return null;

    final Gender cinsiyet = rng.chance(0.5) ? Gender.kadin : Gender.erkek;
    final Set<String> kullanilan = <String>{
      for (final Person p in state.people) p.id,
    };
    String id = 'torun-${all(state).length + 1}';
    int ek = 0;
    while (kullanilan.contains(id)) {
      ek++;
      id = 'torun-${all(state).length + 1}-$ek';
    }

    // Özellikler, torunun kendi anne-babasından (yani oyuncunun
    // çocuğundan) türetilir; oyuncunun değerleri kopyalanmaz.
    final Stats stats = TraitInheritance.newbornStats(
      rng: rng,
      first: child.development?.stats,
      second: null,
    );

    return Person(
      id: id,
      firstName: rng.pick(
        cinsiyet == Gender.kadin ? kadinIsimleri : erkekIsimleri,
      ),
      lastName: child.lastName,
      gender: cinsiyet,
      relation: RelationType.torun,
      age: 0,
      isAlive: true,
      // Torun oyuncunun hanesinde yaşamaz; kendi ailesiyle büyür.
      inPlayerHousehold: false,
      employment: EmploymentStatus.cocuk,
      // Bebeğin kendi ekonomik durumu yazılmaz.
      wealth: null,
      bond: prototypeOnlyStartBond,
      city: child.city,
      development: PersonDevelopment(
        // Kendi hayatı izlenir: okulu, mesleği kendi yıllarında oluşur.
        tracksLife: true,
        stats: stats,
        // Torunun ebeveyni: oyuncunun çocuğu.
        otherParentId: child.id,
        milestones: const <LifeMilestone>[
          LifeMilestone(age: 0, text: 'Dünyaya geldi.'),
        ],
      ),
    );
  }
}
