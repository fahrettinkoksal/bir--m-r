import 'dart:math';

import '../../data/name_pool.dart';
import '../models/education.dart';
import '../models/game_state.dart';
import '../models/gender.dart';
import '../models/person.dart';
import '../models/relation.dart';
import '../models/wealth.dart';
import 'random_util.dart';

/// Yeni bir sınıf ortamı kurulduğunda oluşan kişiler ve taşınan kayıtlar.
class ClassRoster {
  const ClassRoster({required this.newPeople, required this.movedIds});

  /// İlk kez oluşturulan kişiler.
  final List<Person> newPeople;

  /// Eski sınıftan **aynı kimlikle** yeni sınıfa geçen kişilerin kimlikleri.
  final List<String> movedIds;
}

/// Okuldaki kalıcı kimlikli kişileri üretir.
///
/// Kişiler kademeye değil **okula ve sınıfa** bağlanır
/// ([Person.schoolId], [Person.classId]); böylece ileride aynı kademede
/// okul/sınıf değişimi de modellenebilir.
///
/// Kademe değiştiğinde sınıfın tamamı yenilenmez: bir bölümü aynı kimlikle
/// yeni sınıfa taşınır (gerçek hayatta çoğu arkadaş birlikte devam eder),
/// kalanlar eski sınıfta kayıtlı kalır ve ileride yeniden karşılaşılabilir.
/// Hiçbir kayıt silinmez (D-029).
///
/// Sınıf arkadaşı olmak **yakın arkadaş olmak değildir**: tanışıklık düşük
/// bir yakınlıkla başlar, yakın arkadaşlık ayrı bir olayla kurulur.
class SchoolPeople {
  const SchoolPeople();

  /// prototypeOnly: oyuncu hariç bir sınıftaki arkadaş sayısı.
  ///
  /// Nihai oyun kuralı değildir; sınıf mevcudu Faho'nun kararıyla
  /// değişebilir (`docs/DESIGN_REVIEW_QUEUE.md`, Q-024).
  static const int prototypeOnlyClassmateCount = 10;

  /// prototypeOnly: kademe geçişinde yeni sınıfa taşınan arkadaş oranı.
  static const double prototypeOnlyCarryOverRatio = 0.4;

  /// prototypeOnly: bir okulda kaç öğretmen tanınır.
  static const int prototypeOnlyTeacherCount = 1;

  /// Kademe için okul kimliği.
  static String schoolIdFor(SchoolLevel level) => 'okul-${level.name}';

  /// Kademe için sınıf kimliği.
  static String classIdFor(SchoolLevel level) => 'sinif-${level.name}';

  /// Yeni bir sınıf ortamı kurar.
  ///
  /// [previousClassmates] verilirse bir bölümü yeni sınıfa taşınır ve
  /// kimlikleri [ClassRoster.movedIds] içinde döner; geri kalan mevcut yeni
  /// kişilerle tamamlanır.
  ClassRoster buildClass({
    required GameState state,
    required SchoolLevel level,
    required Random rng,
    List<Person> previousClassmates = const <Person>[],
  }) {
    final String schoolId = schoolIdFor(level);
    final String classId = classIdFor(level);

    // Eski sınıftan devam edenler.
    final List<Person> adaylar = List<Person>.from(
      previousClassmates.where((Person p) => p.isAlive),
    )..shuffle(rng);
    final int tasinacak = min(
      adaylar.length,
      (prototypeOnlyClassmateCount * prototypeOnlyCarryOverRatio).round(),
    );
    final List<String> tasinanlar = adaylar
        .take(tasinacak)
        .map((Person p) => p.id)
        .toList(growable: false);

    final int uretilecek = prototypeOnlyClassmateCount - tasinanlar.length;
    final List<Person> yeniler = _generatePeople(
      state: state,
      level: level,
      schoolId: schoolId,
      classId: classId,
      classmateCount: uretilecek,
      rng: rng,
    );

    return ClassRoster(newPeople: yeniler, movedIds: tasinanlar);
  }

  /// Bir kişiyi **aynı kimlikle** yeni sınıfa taşır.
  Person moveToClass(Person person, SchoolLevel level) => person.copyWith(
        schoolLevel: level,
        schoolId: schoolIdFor(level),
        classId: classIdFor(level),
      );

  List<Person> _generatePeople({
    required GameState state,
    required SchoolLevel level,
    required String schoolId,
    required String classId,
    required int classmateCount,
    required Random rng,
  }) {
    final List<Person> people = <Person>[];
    final Set<String> kullanilanIsimler = <String>{
      for (final Person p in state.people) p.firstName,
      state.player.firstName,
    };
    final Set<String> kullanilanKimlikler = <String>{
      for (final Person p in state.people) p.id,
    };

    String benzersizIsim(Gender gender) {
      final List<String> havuz =
          gender == Gender.kadin ? kadinIsimleri : erkekIsimleri;
      for (int deneme = 0; deneme < 30; deneme++) {
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

    /// Kimlikler hiçbir zaman çakışmaz; aynı kişi ikiye bölünmez.
    String benzersizKimlik(String onek) {
      int n = 1;
      while (kullanilanKimlikler.contains('$onek-$n')) {
        n++;
      }
      kullanilanKimlikler.add('$onek-$n');
      return '$onek-$n';
    }

    for (int i = 0; i < classmateCount; i++) {
      final Gender gender = rng.pick(Gender.values);
      people.add(
        Person(
          id: benzersizKimlik('sinif-${level.name}'),
          firstName: benzersizIsim(gender),
          lastName: soyad(),
          gender: gender,
          relation: RelationType.sinifArkadasi,
          // Aynı sınıfta oldukları için yaşları oyuncuyla aynı kuşakta.
          age: (state.player.age + rng.between(-1, 1)).clamp(5, 120),
          isAlive: true,
          // Sınıf arkadaşı olmak aynı evde yaşamak demek değildir (D-014).
          inPlayerHousehold: false,
          employment: EmploymentStatus.ogrenci,
          occupation: null,
          wealth: null,
          // Tanışıklık düşük başlar; yakın arkadaşlık ayrı kurulur.
          bond: rng.between(10, 30), // prototypeOnly
          schoolLevel: level,
          schoolTie: SchoolTie.sinifArkadasi,
          schoolId: schoolId,
          classId: classId,
        ),
      );
    }

    for (int i = 0; i < prototypeOnlyTeacherCount; i++) {
      final Gender gender = rng.pick(Gender.values);
      people.add(
        Person(
          id: benzersizKimlik('ogretmen-${level.name}'),
          firstName: benzersizIsim(gender),
          lastName: soyad(),
          gender: gender,
          relation: RelationType.ogretmen,
          age: rng.between(28, 58),
          isAlive: true,
          // Öğretmen de yalnızca tanışıklık nedeniyle haneye eklenmez.
          inPlayerHousehold: false,
          employment: EmploymentStatus.calisiyor,
          occupation: 'öğretmen',
          wealth: WealthTier.ortaHalli,
          bond: rng.between(10, 30), // prototypeOnly
          schoolLevel: level,
          schoolTie: SchoolTie.ogretmen,
          schoolId: schoolId,
          classId: classId,
        ),
      );
    }

    return List<Person>.unmodifiable(people);
  }
}
