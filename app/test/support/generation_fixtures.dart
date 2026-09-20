import 'package:bir_omur/domain/models/education.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/life_log.dart';
import 'package:bir_omur/domain/models/marriage.dart';
import 'package:bir_omur/domain/models/owned_item.dart';
import 'package:bir_omur/domain/models/parental_status.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/player_character.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/stats.dart';
import 'package:bir_omur/domain/models/wealth.dart';

// ---------------------------------------------------------------------
// Kurulum yardımcıları: kuşak devamı tam denetlenebilir bir dünyada
// sınanır, böylece sonuçlar rastgele üretime bağlı kalmaz.
// ---------------------------------------------------------------------

EmploymentStatus _durum(int age) {
  if (age < 6) return EmploymentStatus.cocuk;
  if (age < 24) return EmploymentStatus.ogrenci;
  if (age >= 65) return EmploymentStatus.emekli;
  return EmploymentStatus.issiz;
}

Person kisi({
  required String id,
  required RelationType relation,
  required Gender gender,
  required int age,
  String firstName = 'Kişi',
  String lastName = 'Yılmaz',
  bool alive = true,
  bool hane = false,
  int bond = 60,
  List<String> estate = const <String>[],
  String city = 'Ankara',
}) =>
    Person(
      id: id,
      firstName: firstName,
      lastName: lastName,
      gender: gender,
      relation: relation,
      age: age,
      isAlive: alive,
      inPlayerHousehold: alive && hane,
      employment: _durum(age),
      wealth: age >= 18 ? WealthTier.ortaHalli : null,
      bond: bond,
      estate: estate,
      city: city,
    );

/// Vefat etmiş, evli ve iki çocuklu bir oyuncu kurar.
///
/// Dünyada ayrıca oyuncunun annesi, kardeşi ve bir arkadaşı vardır; böylece
/// hangi bağların taşınıp hangilerinin arşivde kaldığı sınanabilir.
GameState olenOyuncu({
  Gender oyuncuCinsiyeti = Gender.erkek,
  int olumYasi = 70,
  int buyukCocukYasi = 40,
  int kucukCocukYasi = 36,
  bool esHayatta = true,
  bool cocuklarHayatta = true,
  int wallet = 400000,
  List<OwnedItem> items = const <OwnedItem>[],
  bool bosanmis = false,
}) {
  final List<Person> people = <Person>[
    kisi(
      id: 'es-1',
      relation: bosanmis ? RelationType.eskiEs : RelationType.es,
      gender: oyuncuCinsiyeti == Gender.erkek ? Gender.kadin : Gender.erkek,
      age: olumYasi - 2,
      firstName: 'Nurten',
      alive: esHayatta,
      hane: esHayatta && !bosanmis,
      bond: 80,
      estate: const <String>['kol_saati'],
    ),
    kisi(
      id: 'cocuk-1',
      relation: RelationType.cocuk,
      gender: Gender.kadin,
      age: buyukCocukYasi,
      firstName: 'Elif',
      alive: cocuklarHayatta,
      bond: 75,
    ),
    kisi(
      id: 'cocuk-2',
      relation: RelationType.cocuk,
      gender: Gender.erkek,
      age: kucukCocukYasi,
      firstName: 'Kerem',
      alive: cocuklarHayatta,
      bond: 65,
    ),
    kisi(
      id: 'anne-1',
      relation: RelationType.anne,
      gender: Gender.kadin,
      age: olumYasi + 22,
      firstName: 'Hatice',
      alive: false,
    ),
    kisi(
      id: 'kardes-1',
      relation: RelationType.kardes,
      gender: Gender.kadin,
      age: olumYasi - 3,
      firstName: 'Sevim',
    ),
    kisi(
      id: 'arkadas-1',
      relation: RelationType.arkadas,
      gender: Gender.erkek,
      age: olumYasi - 1,
      firstName: 'Cemal',
    ),
  ];

  return GameState(
    seed: 7,
    player: PlayerCharacter(
      id: 'oyuncu',
      firstName: 'Mehmet',
      lastName: 'Yılmaz',
      gender: oyuncuCinsiyeti,
      age: olumYasi,
      birthCity: 'Ankara',
      stats: const Stats(
        appearance: 50,
        happiness: 50,
        health: 0,
        intelligence: 50,
        charisma: 50,
      ),
      fame: 40,
      wallet: wallet,
    ),
    people: List<Person>.unmodifiable(people),
    pets: const <Pet>[],
    parentalStatus: ParentalStatus.evli,
    log: const <LifeLogEntry>[
      LifeLogEntry(age: 0, text: 'Dünyaya geldin.', category: LogCategory.dogum),
    ],
    items: List<OwnedItem>.unmodifiable(items),
    education: const EducationState(enrolled: false, finished: true),
    marriage: Marriage(
      spouseId: 'es-1',
      marriedAtAge: 25,
      status: bosanmis
          ? MarriageStatus.bosandi
          : (esHayatta ? MarriageStatus.evli : MarriageStatus.dul),
      endedAtAge: bosanmis || !esHayatta ? 60 : null,
    ),
    // Eski hayatta vefat edenlerin mirası zaten dağıtılmıştı; bu işaret
    // yeni kuşağa taşınmalı, yoksa aynı miras ikinci kez dağıtılır.
    settledEstates: <String>{'anne-1', if (!esHayatta) 'es-1'},
    deceased: true,
    deathAge: olumYasi,
    deathCause: 'yaşlılık',
  );
}

OwnedItem esya(String id, String typeId, {bool rentedOut = false}) => OwnedItem(
      id: id,
      typeId: typeId,
      acquiredAtAge: 40,
      source: ItemSource.satinAlma,
      purchasePrice: 100000,
      rentedOut: rentedOut,
    );

