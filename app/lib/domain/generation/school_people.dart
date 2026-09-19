import 'dart:math';

import '../../data/name_pool.dart';
import '../models/education.dart';
import '../models/game_state.dart';
import '../models/gender.dart';
import '../models/person.dart';
import '../models/relation.dart';
import '../models/wealth.dart';
import 'random_util.dart';

/// Okuldaki kalıcı kimlikli kişileri üretir.
///
/// Her kademe (ilkokul / ortaokul / lise) kendi sınıf arkadaşlarını ve
/// öğretmenini getirir. Kademe değişince **eski kişiler silinmez**; yalnızca
/// [Person.schoolLevel] alanları sayesinde güncel sınıf listesinde
/// görünmezler.
///
/// Sınıf arkadaşı olmak **yakın arkadaş olmak değildir**: tanışıklık düşük
/// bir yakınlıkla başlar, yakın arkadaşlık ayrı bir olayla kurulur.
class SchoolPeople {
  const SchoolPeople();

  /// prototypeOnly: bir kademede üretilecek sınıf arkadaşı sayısı.
  static const int prototypeOnlyClassmateCount = 4;

  /// Verilen kademe için sınıf arkadaşlarını ve öğretmeni üretir.
  List<Person> generateFor({
    required GameState state,
    required SchoolLevel level,
    required Random rng,
  }) {
    final List<Person> people = <Person>[];
    final Set<String> kullanilanIsimler = <String>{
      for (final Person p in state.people) p.firstName,
      state.player.firstName,
    };

    String benzersizIsim(Gender gender) {
      final List<String> havuz =
          gender == Gender.kadin ? kadinIsimleri : erkekIsimleri;
      for (int deneme = 0; deneme < 20; deneme++) {
        final String aday = rng.pick(havuz);
        if (!kullanilanIsimler.contains(aday)) {
          kullanilanIsimler.add(aday);
          return aday;
        }
      }
      return rng.pick(havuz);
    }

    String soyad() {
      String aday = rng.pick(soyisimler);
      while (aday == state.player.lastName) {
        aday = rng.pick(soyisimler);
      }
      return aday;
    }

    for (int i = 0; i < prototypeOnlyClassmateCount; i++) {
      final Gender gender = rng.pick(Gender.values);
      people.add(
        Person(
          id: 'sinif-${level.name}-${i + 1}',
          firstName: benzersizIsim(gender),
          lastName: soyad(),
          gender: gender,
          relation: RelationType.sinifArkadasi,
          // Aynı sınıfta oldukları için yaşları oyuncuyla aynı kuşakta.
          age: (state.player.age + rng.between(-1, 1)).clamp(5, 120),
          isAlive: true,
          inPlayerHousehold: false,
          employment: EmploymentStatus.ogrenci,
          occupation: null,
          wealth: null,
          // Tanışıklık düşük başlar; yakın arkadaşlık ayrı kurulur.
          bond: rng.between(15, 35), // prototypeOnly
          schoolLevel: level,
        ),
      );
    }

    final Gender ogretmenCinsiyeti = rng.pick(Gender.values);
    people.add(
      Person(
        id: 'ogretmen-${level.name}',
        firstName: benzersizIsim(ogretmenCinsiyeti),
        lastName: soyad(),
        gender: ogretmenCinsiyeti,
        relation: RelationType.ogretmen,
        age: rng.between(28, 58),
        isAlive: true,
        inPlayerHousehold: false,
        employment: EmploymentStatus.calisiyor,
        occupation: 'öğretmen',
        wealth: WealthTier.ortaHalli,
        bond: rng.between(15, 35), // prototypeOnly
        schoolLevel: level,
      ),
    );

    return List<Person>.unmodifiable(people);
  }
}
