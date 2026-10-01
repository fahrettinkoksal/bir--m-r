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

  /// Bu kişinin kayıtlı çocukları (torun ya da yeğen).
  static List<Person> childrenOf(
    GameState state,
    String parentId, {
    RelationType childRelation = RelationType.torun,
  }) =>
      state.people
          .where((Person p) =>
              p.relation == childRelation &&
              p.development?.otherParentId == parentId)
          .toList(growable: false);

  /// Oyuncunun bütün torunları (vefat edenler de listede kalır).
  static List<Person> all(
    GameState state, {
    RelationType childRelation = RelationType.torun,
  }) =>
      state.people
          .where((Person p) => p.relation == childRelation)
          .toList(growable: false);

  /// Bu yıl bu çocuktan bir torun doğar mı?
  ///
  /// Doğarsa yeni kişi döner; doğmazsa `null`. Vefat etmiş çocuk için
  /// hiçbir zaman torun üretilmez.
  static Person? maybeBorn({
    required GameState state,
    required Person child,
    required Random rng,
  }) =>
      maybeBornTo(
        state: state,
        parent: child,
        rng: rng,
        parentRelation: RelationType.cocuk,
        childRelation: RelationType.torun,
        idPrefix: 'torun',
      );

  /// Aynı kural, **başka bir bağ** için (D-158).
  ///
  /// Kardeşin çocuğu **yeğen** olarak doğar. Kural tek yerde durur:
  /// torun ve yeğen için ayrı iki sistem kurulmadı, yalnızca bağ ve
  /// kimlik öneki değişti.
  static Person? maybeBornTo({
    required GameState state,
    required Person parent,
    required Random rng,
    required RelationType parentRelation,
    required RelationType childRelation,
    required String idPrefix,
  }) {
    final Person child = parent;
    if (!child.isAlive) return null;
    if (child.relation != parentRelation) return null;
    if (child.age < prototypeOnlyMinParentAge) return null;
    if (child.age > prototypeOnlyMaxParentAge) return null;
    if (childrenOf(state, child.id, childRelation: childRelation).length >=
        prototypeOnlyMaxPerChild) {
      return null;
    }
    if (!rng.chance(prototypeOnlyChance)) return null;

    final Gender cinsiyet = rng.chance(0.5) ? Gender.kadin : Gender.erkek;
    final Set<String> kullanilan = <String>{
      for (final Person p in state.people) p.id,
    };
    final int sayi = all(state, childRelation: childRelation).length + 1;
    String id = '$idPrefix-$sayi';
    int ek = 0;
    while (kullanilan.contains(id)) {
      ek++;
      id = '$idPrefix-$sayi-$ek';
    }

    // Özellikler, torunun kendi anne-babasından (yani oyuncunun
    // çocuğundan) türetilir; oyuncunun değerleri kopyalanmaz.
    final Stats stats = TraitInheritance.newbornStats(
      rng: rng,
      first: child.development?.stats,
      second: null,
    );

    // --- Paket AP §49: torunun soy bağı ------------------------------
    //
    // Paket AO lineage modelini kurmuştu (`motherId` / `fatherId`) ama
    // torun doğarken o alanlar boş kalıyordu: torunun yalnızca
    // `development.otherParentId` içinde bir ebeveyni vardı.
    //
    // Paket AP'de gelin/damat gerçek bir kişi oldu, yani torunun **iki**
    // gerçek ebeveyni var ve ikisi de kayıtta duruyor. Burada yeni bir
    // torun motoru kurulmuyor (§49: "yeni torun motoru kurma"); var olan
    // motorun eksik bıraktığı iki alan yazılıyor.
    //
    // Hangi alan hangisine yazılacağı ebeveynin cinsiyetinden okunuyor;
    // eş kaydı yoksa yalnızca bilinen taraf yazılır — uydurma bir
    // ebeveyn kimliği yazılmaz (§53).
    final String? esKimligi = child.development?.spousePersonId;
    final bool ebeveynKadin = child.gender == Gender.kadin;
    final String? anneId = ebeveynKadin ? child.id : esKimligi;
    final String? babaId = ebeveynKadin ? esKimligi : child.id;

    return Person(
      id: id,
      firstName: rng.pick(
        cinsiyet == Gender.kadin ? kadinIsimleri : erkekIsimleri,
      ),
      lastName: child.lastName,
      gender: cinsiyet,
      relation: childRelation,
      age: 0,
      isAlive: true,
      motherId: anneId,
      fatherId: babaId,
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
        // Bebeğin ebeveyni: oyuncunun çocuğu ya da kardeşi.
        otherParentId: child.id,
        milestones: const <LifeMilestone>[
          LifeMilestone(age: 0, text: 'Dünyaya geldi.'),
        ],
      ),
    );
  }
}
