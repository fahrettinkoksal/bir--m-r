import 'dart:math';

import '../../data/name_pool.dart';
import '../models/game_state.dart';
import '../models/gender.dart';
import '../models/life_log.dart';
import '../models/parental_status.dart';
import '../models/person.dart';
import '../models/player_character.dart';
import '../models/relation.dart';
import '../models/stats.dart';
import '../models/wealth.dart';
import 'random_util.dart';

/// Başlangıç modları (D-005).
enum StartMode {
  /// İsim ve cinsiyet dahil her şey rastgele.
  tamamenRastgele,

  /// Oyuncu yalnızca isim ve cinsiyet seçer; kalan koşullar rastgele.
  isimVeCinsiyet,
}

/// Bir hayatın başlangıç durumunu üretir.
///
/// Üretim kuralları D-004, D-013 ve D-014'e dayanır:
/// tek bir 'ortalama aile' kalıbı yoktur, akrabalık ile hane ayrıdır ve
/// yaşlar akrabalık bakımından çelişmez. Aşağıdaki sayısal ağırlıklar
/// **yalnızca prototip içindir** (`prototypeOnly`), onaylanmış oyun dengesi
/// değildir.
class LifeGenerator {
  /// prototypeOnly: oyuncu doğduğunda annenin yaş aralığı ve tepe noktası.
  static const int prototypeOnlyMotherAgeMin = 17;
  static const int prototypeOnlyMotherAgePeak = 28;
  static const int prototypeOnlyMotherAgeMax = 45;

  /// prototypeOnly: oyuncu doğduğunda babanın yaş aralığı ve tepe noktası.
  static const int prototypeOnlyFatherAgeMin = 18;
  static const int prototypeOnlyFatherAgePeak = 31;
  static const int prototypeOnlyFatherAgeMax = 60;

  LifeGenerator({int? seed})
      : seed = seed ?? Random().nextInt(1 << 32),
        _rng = Random(seed ?? Random().nextInt(1 << 32));

  /// Test ve hata ayıklama için sabit tohumla üretim.
  LifeGenerator.seeded(this.seed) : _rng = Random(seed);

  final int seed;
  final Random _rng;
  int _idCounter = 0;

  /// prototypeOnly: bir ebeveynin doğumdan önce vefat etmiş olma ihtimali.
  static const double _prototypeOnlyDeceasedFatherChance = 0.03;
  static const double _prototypeOnlyDeceasedMotherChance = 0.01;

  String _nextId(String prefix) => '$prefix-${_idCounter++}';

  GameState generate({
    required StartMode mode,
    String? chosenFirstName,
    Gender? chosenGender,
  }) {
    final Gender playerGender = mode == StartMode.isimVeCinsiyet && chosenGender != null
        ? chosenGender
        : _rng.pick(Gender.values);

    final String babaSoyad = _rng.pick(soyisimler);
    String anneSoyad = _rng.pick(soyisimler);
    while (anneSoyad == babaSoyad) {
      anneSoyad = _rng.pick(soyisimler);
    }

    final String playerFirstName = _cleanName(chosenFirstName) ??
        _rng.pick(playerGender == Gender.kadin ? kadinIsimleri : erkekIsimleri);

    final String city = _rng.pick(sehirler);

    final ParentalStatus parentalStatus = _rng.pickWeighted(
      ParentalStatus.values,
      // prototypeOnly ağırlıklar: evli / birlikte / ayrı / boşanmış
      <double>[0.58, 0.09, 0.13, 0.20],
    );

    // --- Ebeveynler -------------------------------------------------------
    // Yaşlar oyuncunun doğumuna göre tutarlı: anne en az 17, baba en az 18
    // yaşındayken oyuncu doğmuş olur.
    // Ebeveyn yaşları üçgen dağılımdan gelir: çok genç veya ileri yaşta
    // ebeveynle doğmak mümkün, ama uç yaşlar seyrek (D-041). Uniform
    // dağılım, çocukken ebeveyn kaybını gereğinden sık üretiyordu.
    final int motherAge = _rng.triangular(
      prototypeOnlyMotherAgeMin,
      prototypeOnlyMotherAgePeak,
      prototypeOnlyMotherAgeMax,
    );
    final int fatherAge = _rng.triangular(
      prototypeOnlyFatherAgeMin,
      prototypeOnlyFatherAgePeak,
      prototypeOnlyFatherAgeMax,
    );

    final bool motherAlive = !_rng.chance(_prototypeOnlyDeceasedMotherChance);
    final bool fatherAlive = !_rng.chance(_prototypeOnlyDeceasedFatherChance);

    // Hane: ayrı/boşanmış ebeveynlerin ikisi birden aynı evde olamaz.
    bool motherInHome;
    bool fatherInHome;
    if (parentalStatus.birlikteMi) {
      motherInHome = motherAlive;
      fatherInHome = fatherAlive;
    } else {
      String custodian = _rng.pickWeighted(
        <String>['anne', 'baba', 'hicbiri'],
        <double>[0.68, 0.24, 0.08], // prototypeOnly
      );
      // Seçilen veli hayatta değilse diğeri devreye girer.
      if (custodian == 'anne' && !motherAlive) {
        custodian = fatherAlive ? 'baba' : 'hicbiri';
      } else if (custodian == 'baba' && !fatherAlive) {
        custodian = motherAlive ? 'anne' : 'hicbiri';
      }
      motherInHome = custodian == 'anne';
      fatherInHome = custodian == 'baba';
    }

    final Person mother = _makeAdult(
      idPrefix: 'anne',
      relation: RelationType.anne,
      gender: Gender.kadin,
      firstName: _rng.pick(kadinIsimleri),
      lastName: parentalStatus.birlikteMi
          ? babaSoyad
          : (_rng.chance(0.5) ? babaSoyad : anneSoyad),
      age: motherAge,
      isAlive: motherAlive,
      inHome: motherInHome,
    );

    final Person father = _makeAdult(
      idPrefix: 'baba',
      relation: RelationType.baba,
      gender: Gender.erkek,
      firstName: _rng.pick(erkekIsimleri),
      lastName: babaSoyad,
      age: fatherAge,
      isAlive: fatherAlive,
      inHome: fatherInHome,
    );

    final List<Person> people = <Person>[mother, father];

    // --- Kardeşler --------------------------------------------------------
    // Kardeş yaşı, ebeveynlerin o kardeşi doğurabileceği yaşı aşamaz.
    final int maxSiblingAge = <int>[16, motherAge - 17, fatherAge - 18]
        .reduce((int a, int b) => a < b ? a : b);
    final int siblingCount = _rng.pickWeighted(
      <int>[0, 1, 2, 3, 4, 5, 6],
      <double>[0.28, 0.27, 0.20, 0.12, 0.07, 0.04, 0.02], // prototypeOnly
    );

    final Set<int> usedSiblingAges = <int>{};
    for (int i = 0; i < siblingCount; i++) {
      int? age;
      if (i == 0 && _rng.chance(0.05)) {
        age = 0; // ikiz
      } else if (maxSiblingAge >= 1) {
        for (int attempt = 0; attempt < 12; attempt++) {
          final int candidate = _rng.between(1, maxSiblingAge);
          if (!usedSiblingAges.contains(candidate)) {
            age = candidate;
            break;
          }
        }
      }
      if (age == null) continue;
      usedSiblingAges.add(age);

      final Gender g = _rng.pick(Gender.values);
      final bool inHome = parentalStatus.birlikteMi
          ? _rng.chance(0.95)
          : _rng.chance(0.75); // prototypeOnly
      people.add(
        Person(
          id: _nextId('kardes'),
          firstName: _rng.pick(g == Gender.kadin ? kadinIsimleri : erkekIsimleri),
          lastName: babaSoyad,
          gender: g,
          relation: RelationType.kardes,
          age: age,
          isAlive: true,
          inPlayerHousehold: inHome,
          employment: _employmentForAge(age),
          occupation: null,
          // Çocuk/öğrenci kardeşin kendine ait ekonomik durumu tutulmaz.
          wealth: _wealthForAge(age),
          bond: _rng.between(45, 80),
        ),
      );
    }

    // --- Büyükanne / büyükbabalar ----------------------------------------
    final Person? anneanne = _maybeGrandparent(
      relation: RelationType.anneanne,
      gender: Gender.kadin,
      childAge: motherAge,
      lastName: anneSoyad,
      parentInHome: motherInHome,
    );
    final Person? anneTarafiDede = _maybeGrandparent(
      relation: RelationType.anneTarafiDede,
      gender: Gender.erkek,
      childAge: motherAge,
      lastName: anneSoyad,
      parentInHome: motherInHome,
    );
    final Person? babaanne = _maybeGrandparent(
      relation: RelationType.babaanne,
      gender: Gender.kadin,
      childAge: fatherAge,
      lastName: babaSoyad,
      parentInHome: fatherInHome,
    );
    final Person? babaTarafiDede = _maybeGrandparent(
      relation: RelationType.babaTarafiDede,
      gender: Gender.erkek,
      childAge: fatherAge,
      lastName: babaSoyad,
      parentInHome: fatherInHome,
    );
    for (final Person? g in <Person?>[anneanne, anneTarafiDede, babaanne, babaTarafiDede]) {
      if (g != null) people.add(g);
    }

    // --- Teyze / dayı / hala / amca --------------------------------------
    people.addAll(
      _makeSiblingsOfParent(
        parentAge: motherAge,
        parentInHome: motherInHome,
        lastName: anneSoyad,
        grandparentAges: <int>[
          if (anneanne != null) anneanne.age,
          if (anneTarafiDede != null) anneTarafiDede.age,
        ],
        femaleRelation: RelationType.teyze,
        maleRelation: RelationType.dayi,
      ),
    );
    people.addAll(
      _makeSiblingsOfParent(
        parentAge: fatherAge,
        parentInHome: fatherInHome,
        lastName: babaSoyad,
        grandparentAges: <int>[
          if (babaanne != null) babaanne.age,
          if (babaTarafiDede != null) babaTarafiDede.age,
        ],
        femaleRelation: RelationType.hala,
        maleRelation: RelationType.amca,
      ),
    );

    // --- Hane tutarlılığı --------------------------------------------------
    // Yeni doğan bir çocuk yetişkinsiz bir hanede yaşamaz: ebeveynlerin ikisi
    // de hanede değilse hayattaki bir büyük (önce büyükanne/büyükbaba) bakımı
    // üstlenir. Bu yalnızca haneyi değiştirir, akrabalık bağını değiştirmez.
    if (!people.any((Person p) => p.isAlive && p.inPlayerHousehold && p.age >= 18)) {
      int idx = people.indexWhere(
        (Person p) =>
            p.isAlive &&
            p.age >= 18 &&
            p.relation.group == RelationGroup.genis &&
            _isGrandparent(p.relation),
      );
      if (idx < 0) {
        idx = people.indexWhere((Person p) => p.isAlive && p.age >= 18);
      }
      if (idx >= 0) {
        people[idx] = people[idx].copyWith(inPlayerHousehold: true);
      }
    }

    // --- Evcil hayvan -----------------------------------------------------
    final List<Pet> pets = <Pet>[];
    if (_rng.chance(0.26)) {
      pets.add(
        Pet(
          id: _nextId('hayvan'),
          name: _rng.pick(evcilHayvanIsimleri),
          species: _rng.pick(evcilHayvanTurleri),
        ),
      );
    }

    final PlayerCharacter player = PlayerCharacter(
      id: 'oyuncu',
      firstName: playerFirstName,
      lastName: babaSoyad,
      gender: playerGender,
      age: 0,
      birthCity: city,
      stats: Stats(
        // prototypeOnly aralık: 25-85
        appearance: _rng.between(25, 85),
        happiness: _rng.between(45, 85),
        health: _rng.between(40, 90),
        intelligence: _rng.between(25, 85),
        charisma: _rng.between(25, 85),
      ),
      // Ün başlangıçta açık değildir (D-027).
      fame: null,
    );

    final GameState state = GameState(
      seed: seed,
      player: player,
      people: List<Person>.unmodifiable(people),
      pets: List<Pet>.unmodifiable(pets),
      parentalStatus: parentalStatus,
      log: const <LifeLogEntry>[],
    );

    return state.copyWith(log: _birthLog(state));
  }

  // --------------------------------------------------------------------
  // Yardımcılar
  // --------------------------------------------------------------------

  static String? _cleanName(String? raw) {
    final String trimmed = (raw ?? '').trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Person _makeAdult({
    required String idPrefix,
    required RelationType relation,
    required Gender gender,
    required String firstName,
    required String lastName,
    required int age,
    required bool isAlive,
    required bool inHome,
  }) {
    final EmploymentStatus employment = _employmentForAge(age);
    final WealthTier? varlik = _wealthForAge(age);
    return Person(
      id: _nextId(idPrefix),
      firstName: firstName,
      lastName: lastName,
      gender: gender,
      relation: relation,
      age: age,
      isAlive: isAlive,
      // Hayatta olmayan kişi hanede sayılmaz.
      inPlayerHousehold: isAlive && inHome,
      employment: employment,
      occupation: employment == EmploymentStatus.calisiyor ? _rng.pick(meslekler) : null,
      // Kişilerin ekonomik durumu birbirinden bağımsızdır (D-013).
      wealth: varlik,
      estate: _estateFor(varlik, age),
      bond: inHome ? _rng.between(55, 90) : _rng.between(35, 75),
    );
  }

  Person? _maybeGrandparent({
    required RelationType relation,
    required Gender gender,
    required int childAge,
    required String lastName,
    required bool parentInHome,
  }) {
    // Her hayatta bütün büyükler bulunmak zorunda değildir.
    if (_rng.chance(0.12)) return null; // hiç kaydı yok
    final int age = childAge + _rng.between(18, 44);
    final bool alive = _rng.chance(_aliveChanceForAge(age));
    final EmploymentStatus employment = _employmentForAge(age);
    final WealthTier? buyukVarlik = _wealthForAge(age);
    return Person(
      id: _nextId(relation.name),
      firstName: _rng.pick(gender == Gender.kadin ? kadinIsimleri : erkekIsimleri),
      lastName: lastName,
      gender: gender,
      relation: relation,
      age: age,
      isAlive: alive,
      // Akraba olmak aynı evde yaşamayı gerektirmez (D-014).
      inPlayerHousehold: alive && parentInHome && _rng.chance(0.18),
      employment: employment,
      occupation: employment == EmploymentStatus.calisiyor ? _rng.pick(meslekler) : null,
      wealth: buyukVarlik,
      estate: _estateFor(buyukVarlik, age),
      bond: _rng.between(35, 80),
    );
  }

  List<Person> _makeSiblingsOfParent({
    required int parentAge,
    required bool parentInHome,
    required String lastName,
    required List<int> grandparentAges,
    required RelationType femaleRelation,
    required RelationType maleRelation,
  }) {
    final int count = _rng.pickWeighted(
      <int>[0, 1, 2, 3],
      <double>[0.34, 0.33, 0.22, 0.11], // prototypeOnly
    );
    final List<Person> result = <Person>[];
    final Set<int> usedAges = <int>{parentAge};

    // Büyükanne/babanın yaşı biliniyorsa, kardeşin yaşı onu aşamaz.
    int maxAge = parentAge + 14;
    for (final int gAge in grandparentAges) {
      final int limit = gAge - 17;
      if (limit < maxAge) maxAge = limit;
    }
    final int minAge = parentAge - 14 < 14 ? 14 : parentAge - 14;
    if (maxAge < minAge) return result;

    for (int i = 0; i < count; i++) {
      int? age;
      for (int attempt = 0; attempt < 12; attempt++) {
        final int candidate = _rng.between(minAge, maxAge);
        if (!usedAges.contains(candidate)) {
          age = candidate;
          break;
        }
      }
      if (age == null) continue;
      usedAges.add(age);

      final Gender gender = _rng.pick(Gender.values);
      final bool alive = _rng.chance(_aliveChanceForAge(age));
      final EmploymentStatus employment = _employmentForAge(age);
      final WealthTier? akrabaVarlik = _wealthForAge(age);
      result.add(
        Person(
          id: _nextId(gender == Gender.kadin ? femaleRelation.name : maleRelation.name),
          firstName: _rng.pick(gender == Gender.kadin ? kadinIsimleri : erkekIsimleri),
          lastName: lastName,
          gender: gender,
          relation: gender == Gender.kadin ? femaleRelation : maleRelation,
          age: age,
          isAlive: alive,
          inPlayerHousehold: alive && parentInHome && _rng.chance(0.07),
          employment: employment,
          occupation: employment == EmploymentStatus.calisiyor ? _rng.pick(meslekler) : null,
          wealth: akrabaVarlik,
          estate: _estateFor(akrabaVarlik, age),
          bond: _rng.between(30, 75),
        ),
      );
    }
    return result;
  }

  static bool _isGrandparent(RelationType relation) =>
      relation == RelationType.anneanne ||
      relation == RelationType.babaanne ||
      relation == RelationType.anneTarafiDede ||
      relation == RelationType.babaTarafiDede;

  /// Reşit olmayan kişinin kendine ait ekonomik durumu tutulmaz; uydurma
  /// bir değer üretmek yerine `null` bırakılır.
  WealthTier? _wealthForAge(int age) => age >= 18 ? _randomWealth() : null;

  /// prototypeOnly: yetişkinin sahip olduğu eşyalar.
  ///
  /// Ekonomik duruma göre üretilir ve kişi kaydında saklanır; kişi
  /// ekranında görünür, vefat edince mirasçılara bu liste paylaştırılır.
  /// Böylece miras, kişinin gerçekten sahip olduğu şeylerden gelir.
  List<String> _estateFor(WealthTier? wealth, int age) {
    if (wealth == null || age < 18) return const <String>[];
    switch (wealth) {
      case WealthTier.cokYoksul:
        return const <String>[];
      case WealthTier.yoksul:
        return <String>[_rng.pick(<String>['kol_saati', 'radyo'])];
      case WealthTier.ortaHalli:
        return <String>[
          _rng.pick(<String>['kol_saati', 'telefon']),
          _rng.pick(<String>['cay_takimi', 'bisiklet']),
        ];
      case WealthTier.varlikli:
        return <String>[
          'antika_saat',
          _rng.pick(<String>['otomobil_ikinci_el', 'otomobil_ekonomik']),
          _rng.pick(<String>['bilgisayar', 'telefon']),
        ];
      case WealthTier.cokVarlikli:
        return <String>[
          'antika_saat',
          _rng.pick(<String>['otomobil_orta', 'otomobil_luks']),
          _rng.pick(<String>['kucuk_daire', 'standart_daire']),
        ];
    }
  }

  WealthTier _randomWealth() => _rng.pickWeighted(
        WealthTier.values,
        <double>[0.12, 0.26, 0.38, 0.17, 0.07], // prototypeOnly
      );

  EmploymentStatus _employmentForAge(int age) {
    if (age < 6) return EmploymentStatus.cocuk;
    if (age < 18) return EmploymentStatus.ogrenci;
    if (age >= 60) {
      return _rng.pickWeighted(
        <EmploymentStatus>[
          EmploymentStatus.emekli,
          EmploymentStatus.calisiyor,
          EmploymentStatus.evIsleri,
        ],
        <double>[0.62, 0.20, 0.18], // prototypeOnly
      );
    }
    if (age <= 25) {
      return _rng.pickWeighted(
        <EmploymentStatus>[
          EmploymentStatus.calisiyor,
          EmploymentStatus.ogrenci,
          EmploymentStatus.issiz,
          EmploymentStatus.evIsleri,
        ],
        <double>[0.52, 0.22, 0.14, 0.12], // prototypeOnly
      );
    }
    return _rng.pickWeighted(
      <EmploymentStatus>[
        EmploymentStatus.calisiyor,
        EmploymentStatus.issiz,
        EmploymentStatus.evIsleri,
      ],
      <double>[0.68, 0.13, 0.19], // prototypeOnly
    );
  }

  double _aliveChanceForAge(int age) {
    if (age < 55) return 0.985;
    if (age < 70) return 0.93;
    if (age < 80) return 0.78;
    if (age < 90) return 0.52;
    return 0.22;
  }

  List<LifeLogEntry> _birthLog(GameState state) {
    final List<LifeLogEntry> log = <LifeLogEntry>[];
    final Person? mother = state.people
        .where((Person p) => p.relation == RelationType.anne)
        .firstOrNull;
    final Person? father = state.people
        .where((Person p) => p.relation == RelationType.baba)
        .firstOrNull;

    log.add(
      LifeLogEntry(
        age: 0,
        text: '${state.player.birthCity} şehrinde dünyaya geldin. '
            'Adın ${state.player.fullName} kondu.',
        category: LogCategory.dogum,
      ),
    );

    if (mother != null && father != null) {
      final String durum = switch (state.parentalStatus) {
        ParentalStatus.evli => 'evli',
        ParentalStatus.birlikte => 'birlikte yaşıyor',
        ParentalStatus.ayri => 'ayrı yaşıyor',
        ParentalStatus.bosanmis => 'boşanmış',
      };
      log.add(
        LifeLogEntry(
          age: 0,
          text: 'Annen ${mother.firstName} ile baban ${father.firstName} $durum.',
          category: LogCategory.aile,
        ),
      );
    }

    for (final Person parent in <Person>[
      if (mother != null) mother,
      if (father != null) father,
    ]) {
      if (!parent.isAlive) {
        final String kim = parent.relation == RelationType.anne ? 'Annen' : 'Baban';
        log.add(
          LifeLogEntry(
            age: 0,
            text: '$kim ${parent.firstName} sen doğmadan önce vefat etmişti.',
            category: LogCategory.aile,
          ),
        );
      }
    }

    final int siblingCount =
        state.people.where((Person p) => p.relation == RelationType.kardes).length;
    if (siblingCount > 0) {
      log.add(
        LifeLogEntry(
          age: 0,
          text: 'Hayata $siblingCount kardeşle birlikte başladın.',
          category: LogCategory.aile,
        ),
      );
    } else {
      log.add(
        const LifeLogEntry(
          age: 0,
          text: 'Ailenin tek çocuğusun.',
          category: LogCategory.aile,
        ),
      );
    }

    final int householdCount = state.household.length;
    log.add(
      LifeLogEntry(
        age: 0,
        text: householdCount == 0
            ? 'Doğduğun evde seninle birlikte yaşayan bir yakının yok.'
            : 'Doğduğun evde seninle birlikte $householdCount kişi yaşıyor.',
        category: LogCategory.aile,
      ),
    );

    for (final Pet pet in state.pets) {
      log.add(
        LifeLogEntry(
          age: 0,
          text: 'Evde ${pet.species} ${pet.name} de var.',
          category: LogCategory.aile,
        ),
      );
    }

    return List<LifeLogEntry>.unmodifiable(log);
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
