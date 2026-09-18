import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/parental_status.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/player_character.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:flutter_test/flutter_test.dart';

/// Üretilen hayatlar birçok tohum üzerinde sınanır: tek bir örneğin tesadüfen
/// tutarlı çıkması yeterli değildir.
const int kSeedCount = 300;

Iterable<GameState> allLives({
  StartMode mode = StartMode.tamamenRastgele,
  String? name,
  Gender? gender,
}) sync* {
  for (int seed = 0; seed < kSeedCount; seed++) {
    yield LifeGenerator.seeded(seed).generate(
      mode: mode,
      chosenFirstName: name,
      chosenGender: gender,
    );
  }
}

Person? _findRelation(GameState state, RelationType relation) {
  for (final Person p in state.people) {
    if (p.relation == relation) return p;
  }
  return null;
}

void main() {
  group('Başlangıç modları (D-005)', () {
    test('tamamen rastgele mod isim ve cinsiyeti kendisi belirler', () {
      final Set<String> names = <String>{};
      final Set<Gender> genders = <Gender>{};
      for (final GameState state in allLives()) {
        expect(state.player.firstName, isNotEmpty);
        names.add(state.player.firstName);
        genders.add(state.player.gender);
      }
      expect(names.length, greaterThan(1));
      expect(genders.length, 2, reason: 'İki cinsiyet de üretilebilmeli');
    });

    test('isim/cinsiyet modu seçimi aynen kullanır, kalanı rastgele kalır', () {
      final Set<String> cities = <String>{};
      for (final GameState state in allLives(
        mode: StartMode.isimVeCinsiyet,
        name: 'Nergis',
        gender: Gender.kadin,
      )) {
        expect(state.player.firstName, 'Nergis');
        expect(state.player.gender, Gender.kadin);
        cities.add(state.player.birthCity);
      }
      expect(cities.length, greaterThan(1),
          reason: 'Şehir oyuncu tarafından seçilmez, rastgele kalır');
    });

    test('boş isim verilirse rastgele isim atanır', () {
      final GameState state = LifeGenerator.seeded(11).generate(
        mode: StartMode.isimVeCinsiyet,
        chosenFirstName: '   ',
        chosenGender: Gender.erkek,
      );
      expect(state.player.firstName.trim(), isNotEmpty);
      expect(state.player.gender, Gender.erkek);
    });

    test('her oyuncuya tek bir sabit aile verilmez', () {
      final Set<String> signatures = <String>{};
      for (final GameState state in allLives()) {
        signatures.add(
          '${state.parentalStatus}|${state.people.length}|'
          '${state.people.map((Person p) => '${p.relation}${p.age}').join(',')}',
        );
      }
      expect(signatures.length, greaterThan(kSeedCount ~/ 2));
    });

    test('aynı tohum aynı hayatı üretir', () {
      final GameState a =
          LifeGenerator.seeded(42).generate(mode: StartMode.tamamenRastgele);
      final GameState b =
          LifeGenerator.seeded(42).generate(mode: StartMode.tamamenRastgele);
      expect(a.player.fullName, b.player.fullName);
      expect(a.people.length, b.people.length);
      expect(a.player.birthCity, b.player.birthCity);
    });
  });

  group('Karakter (D-006, D-027)', () {
    test('oyuncu doğumda 0 yaşındadır ve Ün açık değildir', () {
      for (final GameState state in allLives()) {
        final PlayerCharacter p = state.player;
        expect(p.age, 0);
        expect(p.fame, isNull, reason: 'Ün baştan açık olmamalı');
        expect(p.fameUnlocked, isFalse);
      }
    });

    test('beş başlangıç değeri 0-100 aralığındadır', () {
      for (final GameState state in allLives()) {
        expect(state.player.stats.entries.length, 5);
        for (final dynamic entry in state.player.stats.entries) {
          expect(entry.value, inInclusiveRange(0, 100));
        }
      }
    });
  });

  group('Aile tutarlılığı (D-004, D-013, D-014)', () {
    test('kişi kimlikleri benzersizdir', () {
      for (final GameState state in allLives()) {
        final Set<String> ids = state.people.map((Person p) => p.id).toSet();
        expect(ids.length, state.people.length);
      }
    });

    test('ebeveyn yaşları oyuncunun doğumuyla çelişmez', () {
      for (final GameState state in allLives()) {
        final Person anne = _findRelation(state, RelationType.anne)!;
        final Person baba = _findRelation(state, RelationType.baba)!;
        expect(anne.age - state.player.age, greaterThanOrEqualTo(17));
        expect(baba.age - state.player.age, greaterThanOrEqualTo(18));
      }
    });

    test('kardeş yaşları ebeveyn yaşlarıyla çelişmez', () {
      for (final GameState state in allLives()) {
        final Person anne = _findRelation(state, RelationType.anne)!;
        final Person baba = _findRelation(state, RelationType.baba)!;
        final List<Person> kardesler = state.people
            .where((Person p) => p.relation == RelationType.kardes)
            .toList();
        final List<int> nonTwinAges = <int>[];
        for (final Person k in kardesler) {
          expect(k.age, greaterThanOrEqualTo(0));
          expect(anne.age - k.age, greaterThanOrEqualTo(17));
          expect(baba.age - k.age, greaterThanOrEqualTo(18));
          if (k.age != 0) nonTwinAges.add(k.age);
        }
        expect(nonTwinAges.length, nonTwinAges.toSet().length,
            reason: 'İkiz olmayan kardeşler aynı yaşta olamaz');
      }
    });

    test('büyükanne/büyükbaba yaşları kendi çocuklarıyla çelişmez', () {
      for (final GameState state in allLives()) {
        final Person anne = _findRelation(state, RelationType.anne)!;
        final Person baba = _findRelation(state, RelationType.baba)!;
        for (final Person p in state.people) {
          switch (p.relation) {
            case RelationType.anneanne:
            case RelationType.anneTarafiDede:
              expect(p.age - anne.age, greaterThanOrEqualTo(17));
            case RelationType.babaanne:
            case RelationType.babaTarafiDede:
              expect(p.age - baba.age, greaterThanOrEqualTo(17));
            default:
              break;
          }
        }
      }
    });

    test('teyze/dayı/hala/amca yaşları büyüklerle çelişmez', () {
      for (final GameState state in allLives()) {
        final Person? anneanne = _findRelation(state, RelationType.anneanne);
        final Person? anneDede = _findRelation(state, RelationType.anneTarafiDede);
        final Person? babaanne = _findRelation(state, RelationType.babaanne);
        final Person? babaDede = _findRelation(state, RelationType.babaTarafiDede);

        for (final Person p in state.people) {
          final List<Person?> buyukler = switch (p.relation) {
            RelationType.teyze || RelationType.dayi => <Person?>[anneanne, anneDede],
            RelationType.hala || RelationType.amca => <Person?>[babaanne, babaDede],
            _ => const <Person?>[],
          };
          for (final Person? buyuk in buyukler) {
            if (buyuk == null) continue;
            expect(buyuk.age - p.age, greaterThanOrEqualTo(17));
          }
        }
      }
    });

    test('hayatta olmayan kişi hanede sayılmaz', () {
      for (final GameState state in allLives()) {
        for (final Person p in state.people) {
          if (!p.isAlive) {
            expect(p.inPlayerHousehold, isFalse);
          }
        }
        expect(state.household.every((Person p) => p.isAlive), isTrue);
      }
    });

    test('ayrı/boşanmış ebeveynler aynı hanede birlikte bulunmaz', () {
      int ayriSayisi = 0;
      for (final GameState state in allLives()) {
        if (state.parentalStatus.birlikteMi) continue;
        ayriSayisi++;
        final Person anne = _findRelation(state, RelationType.anne)!;
        final Person baba = _findRelation(state, RelationType.baba)!;
        expect(anne.inPlayerHousehold && baba.inPlayerHousehold, isFalse);
      }
      expect(ayriSayisi, greaterThan(0), reason: 'Ayrı yaşayan örnek üretilmeli');
    });

    test('akrabalık hane demek değildir: ayrı evde yaşayan akraba bulunur', () {
      int ayriEvdeAkraba = 0;
      for (final GameState state in allLives()) {
        ayriEvdeAkraba += state.people
            .where((Person p) => p.isAlive && !p.inPlayerHousehold)
            .length;
      }
      expect(ayriEvdeAkraba, greaterThan(0));
    });

    test('yeni doğan çocuk yetişkinsiz hanede kalmaz', () {
      for (final GameState state in allLives()) {
        final bool yetiskinVar =
            state.household.any((Person p) => p.age >= 18);
        final bool hicYetiskinAkrabaVar =
            state.people.any((Person p) => p.isAlive && p.age >= 18);
        if (hicYetiskinAkrabaVar) {
          expect(yetiskinVar, isTrue,
              reason: 'Hanede en az bir yetişkin bulunmalı (tohum ${state.seed})');
        }
      }
    });

    test('çalışmayan kişiye meslek uydurulmaz', () {
      for (final GameState state in allLives()) {
        for (final Person p in state.people) {
          if (p.employment == EmploymentStatus.calisiyor) {
            expect(p.occupation, isNotNull);
            expect(p.occupation, isNotEmpty);
          } else {
            expect(p.occupation, isNull,
                reason: '${p.employment} durumundaki kişiye meslek atanmamalı');
          }
        }
      }
    });

    test('reşit olmayan kişiye kendi ekonomik durumu atanmaz', () {
      for (final GameState state in allLives()) {
        for (final Person p in state.people) {
          if (p.age < 18) {
            expect(p.wealth, isNull);
            expect(p.employment,
                anyOf(EmploymentStatus.cocuk, EmploymentStatus.ogrenci));
          }
        }
      }
    });

    test('anne ve babanın ekonomik durumu birbirinden bağımsızdır', () {
      final Set<String> ciftler = <String>{};
      for (final GameState state in allLives()) {
        final Person anne = _findRelation(state, RelationType.anne)!;
        final Person baba = _findRelation(state, RelationType.baba)!;
        ciftler.add('${anne.wealth}-${baba.wealth}');
      }
      expect(ciftler.length, greaterThan(1));
      expect(
        ciftler.any((String c) => c.split('-')[0] != c.split('-')[1]),
        isTrue,
        reason: 'Anne ve babanın maddi durumu farklı olabilmeli',
      );
    });

    test('kardeş sayısı sıfır da olabilir, çok da', () {
      final Set<int> sayilar = <int>{};
      for (final GameState state in allLives()) {
        sayilar.add(state.people
            .where((Person p) => p.relation == RelationType.kardes)
            .length);
      }
      expect(sayilar.contains(0), isTrue);
      expect(sayilar.any((int n) => n >= 3), isTrue);
    });

    test('her hayatta bütün geniş aile bireyleri bulunmak zorunda değil', () {
      final Set<int> genisAileSayilari = <int>{};
      for (final GameState state in allLives()) {
        genisAileSayilari.add(state.byGroup(RelationGroup.genis).length);
      }
      expect(genisAileSayilari.length, greaterThan(1));
    });

    test('prototipte romantik bağ ile başlanmaz', () {
      for (final GameState state in allLives()) {
        expect(state.byGroup(RelationGroup.romantik), isEmpty);
      }
    });

    test('ebeveyn durumunun bütün hâlleri üretilebilir', () {
      final Set<ParentalStatus> durumlar = <ParentalStatus>{};
      for (final GameState state in allLives()) {
        durumlar.add(state.parentalStatus);
      }
      expect(durumlar.length, ParentalStatus.values.length);
    });
  });

  group('Hayat günlüğü', () {
    test('doğum günlüğü dolu ve hepsi 0 yaşına ait', () {
      for (final GameState state in allLives()) {
        expect(state.log, isNotEmpty);
        expect(state.log.every((dynamic e) => e.age == 0), isTrue);
      }
    });

    test('vefat etmiş ebeveyn günlükte belirtilir', () {
      bool bulundu = false;
      for (final GameState state in allLives()) {
        final Iterable<Person> olenEbeveynler = state.people.where(
          (Person p) =>
              !p.isAlive &&
              (p.relation == RelationType.anne || p.relation == RelationType.baba),
        );
        for (final Person p in olenEbeveynler) {
          bulundu = true;
          expect(
            state.log.any((dynamic e) => (e.text as String).contains(p.firstName)),
            isTrue,
          );
        }
      }
      expect(bulundu, isTrue, reason: 'Örnek üretilebilmeli');
    });
  });
}
