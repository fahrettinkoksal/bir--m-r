import 'dart:math';

import 'package:bir_omur/data/pet_catalog.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/generation/life_progression.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/interaction.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/marriage.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/pregnancy.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/pets/pet_care.dart';
import 'package:flutter_test/flutter_test.dart';

/// Paket N: hayvan sahiplendirme, kayıp hayvanın sonu, özel izin ve
/// genç ebeveyne ailenin tepkisi (D-109, D-110).
void main() {
  GameState hayat({int seed = 8, int age = 30, int wallet = 900000}) {
    final GameState base =
        LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
    return base.copyWith(
      pendingEvent: null,
      notices: const <PendingNotice>[],
      player: base.player.copyWith(age: age, wallet: wallet),
      movedOut: true,
    );
  }

  GameState hayvanli(GameState s, {String tur = 'kedi'}) => s.copyWith(
        pets: <Pet>[
          Pet(
            id: 'hayvan-1',
            name: 'Zeytin',
            species: tur,
            age: 3,
            adoptedAtPlayerAge: s.player.age - 3,
            bond: 70,
          ),
        ],
      );

  group('Sahiplendirme (D-109)', () {
    test('hayvan yeni yuvaya verilir; ölmez, kaydı silinmez', () {
      final GameState s = hayvanli(hayat());
      final ({GameState state, bool applied, String text}) r =
          PetCare.rehome(state: s, petId: 'hayvan-1');

      expect(r.applied, isTrue);
      final Pet pet = r.state.pets.single;
      expect(pet.isAlive, isTrue, reason: 'Sahiplendirmek vefat değildir');
      expect(pet.isRehomed, isTrue);
      expect(pet.isActive, isFalse);
      expect(PetCare.livingPets(r.state), isEmpty);
      expect(PetCare.pastPets(r.state), hasLength(1));
      expect(r.state.log.last.text, contains('yuva'));
    });

    test('aynı hayvan iki kez verilemez', () {
      GameState s = hayvanli(hayat());
      s = PetCare.rehome(state: s, petId: 'hayvan-1').state;
      final ({GameState state, bool applied, String text}) tekrar =
          PetCare.rehome(state: s, petId: 'hayvan-1');
      expect(tekrar.applied, isFalse);
      expect(tekrar.text, contains('zaten'));
    });

    test('kayıp hayvan verilemez, sebebi yazar', () {
      GameState s = hayvanli(hayat());
      s = s.copyWith(
        pets: <Pet>[s.pets.single.copyWith(missingSinceAge: s.player.age)],
      );
      final InteractionAvailability a =
          PetCare.rehomeAvailability(s, s.pets.single);
      expect(a.isAllowed, isFalse);
      expect(a.reason, contains('kayıp'));
    });

    test('sahiplendirme kayıt açılıp kapandığında korunur', () {
      GameState s = hayvanli(hayat());
      s = PetCare.rehome(state: s, petId: 'hayvan-1').state;
      final GameState geri = decodeGameState(encodeGameState(s));
      expect(geri.pets.single.isRehomed, isTrue);
      expect(geri.pets.single.rehomedAtPlayerAge, s.player.age);
    });

    test('verilen hayvanın bakım gideri artık işlemez', () {
      GameState s = hayvanli(hayat());
      s = PetCare.rehome(state: s, petId: 'hayvan-1').state;
      final int cuzdan = s.player.wallet;
      final GameState sonra =
          PetCare.advanceYear(s, s.player.age + 1, Random(3));
      expect(sonra.player.wallet, cuzdan);
    });
  });

  group('Kayıp hayvan mutlaka sonuçlanır (D-109)', () {
    test('kayıp süresi dolunca durum kapanır', () {
      GameState s = hayvanli(hayat(), tur: 'muhabbet_kusu');
      final int kayipYas = s.player.age;
      s = s.copyWith(
        pets: <Pet>[s.pets.single.copyWith(missingSinceAge: kayipYas)],
      );

      // Dönme ihtimali tutmayan bir tohumla süre sonuna kadar ilerlet.
      for (int yil = 1;
          yil <= PetCare.prototypeOnlyMaxMissingYears + 1;
          yil++) {
        s = PetCare.advanceYear(s, kayipYas + yil, Random(999));
        if (!s.pets.single.isMissing) break;
      }

      final Pet pet = s.pets.single;
      expect(
        pet.isMissing,
        isFalse,
        reason: 'Hayvan sonsuza kadar kayıp kalmamalı',
      );
      // Ya döndü ya da yeni bir yuva buldu; her hâlde çözüldü.
      expect(pet.isRehomed || pet.isActive, isTrue);
    });

    test('kayıp kapandığında hayvan ölmüş sayılmaz', () {
      GameState s = hayvanli(hayat(), tur: 'hamster');
      final int kayipYas = s.player.age;
      s = s.copyWith(
        pets: <Pet>[s.pets.single.copyWith(missingSinceAge: kayipYas)],
      );
      for (int yil = 1; yil <= 6; yil++) {
        s = PetCare.advanceYear(s, kayipYas + yil, Random(999));
        if (s.pets.single.isRehomed) {
          expect(s.pets.single.isAlive, isTrue);
          return;
        }
      }
    });
  });

  group('Özel izin gerektiren hayvan (D-109)', () {
    final PetSpecies izinli =
        PetSpecies.values.firstWhere((PetSpecies s) => s.requiresPermit);

    test('genç oyuncuya izin verilmez, sebebi yazar', () {
      final GameState s = hayat(age: 20, wallet: 5000000);
      final InteractionAvailability a =
          PetCare.adoptionAvailability(s, izinli);
      expect(a.isAllowed, isFalse);
      expect(a.reason, contains('izin'));
    });

    test('ailesinin yanında yaşayana izin verilmez', () {
      final GameState s =
          hayat(age: 40, wallet: 5000000).copyWith(movedOut: false);
      final InteractionAvailability a =
          PetCare.adoptionAvailability(s, izinli);
      expect(a.isAllowed, isFalse);
      expect(a.reason, contains('kendi evinde'));
    });

    test('izin masrafı bedelin üstüne eklenir ve gerçekten düşer', () {
      final int izinUcreti = PetCare.permitFeeFor(izinli);
      expect(izinUcreti, greaterThan(0));

      final GameState s = hayat(age: 40, wallet: 5000000);
      expect(PetCare.adoptionAvailability(s, izinli).isAllowed, isTrue);

      final ({GameState state, bool applied, String text}) r = PetCare.adopt(
        state: s,
        species: izinli,
        name: 'Şans',
        rng: Random(1),
      );
      expect(r.applied, isTrue);
      expect(
        r.state.player.wallet,
        s.player.wallet - izinli.adoptionCost - izinUcreti,
      );
    });

    test('izin gerektirmeyen türde ek masraf yoktur', () {
      final PetSpecies kedi =
          PetSpecies.values.firstWhere((PetSpecies s) => s.id == 'kedi');
      expect(PetCare.permitFeeFor(kedi), 0);
    });
  });

  group('Genç ebeveyne ailenin tepkisi (D-110)', () {
    GameState dogumBekleyen({required int age, required bool evli}) {
      GameState s = hayat(age: age, wallet: 200000);
      // Hayatta bir ebeveyn olsun.
      final Person ebeveyn = s.people.firstWhere(
        (Person p) => p.relation == RelationType.anne,
        orElse: () =>
            s.people.firstWhere((Person p) => p.relation == RelationType.baba),
      );
      s = s.copyWith(
        people: s.people
            .map((Person p) =>
                p.id == ebeveyn.id ? p.copyWith(isAlive: true, bond: 60) : p)
            .toList(growable: false),
      );

      // Partner ve hamilelik.
      final Person partner = Person(
        id: 'partner-1',
        firstName: 'Eren',
        lastName: 'Yıldız',
        gender: s.player.gender == Gender.kadin ? Gender.erkek : Gender.kadin,
        relation: RelationType.sevgili,
        age: age,
        isAlive: true,
        inPlayerHousehold: true,
        employment: EmploymentStatus.calisiyor,
        wealth: WealthTier.ortaHalli,
        bond: 70,
      );
      s = s.copyWith(
        people: List<Person>.unmodifiable(<Person>[...s.people, partner]),
        pregnancy: Pregnancy(
          partnerId: partner.id,
          startedAtAge: age,
          expecting: ExpectingParty.oyuncu,
        ),
        marriage: evli
            ? Marriage(
                spouseId: partner.id,
                marriedAtAge: age - 1,
                status: MarriageStatus.evli,
              )
            : null,
      );
      return s;
    }

    test('evli değilse aile endişelenir, yakınlık düşer', () {
      final GameState s = dogumBekleyen(age: 19, evli: false);
      final Person ebeveyn = s.people.firstWhere(
        (Person p) =>
            p.isAlive &&
            (p.relation == RelationType.anne ||
                p.relation == RelationType.baba),
      );
      final int onceki = ebeveyn.bond;

      final GameState sonra = LifeProgression(Random(4)).advanceOneYear(s);
      final Person? yeni = sonra.personById(ebeveyn.id);
      if (yeni == null || !yeni.isAlive) return;
      if (sonra.children.isEmpty) return;

      expect(yeni.bond, lessThan(onceki));
      expect(
        sonra.notices.any((PendingNotice n) => n.title == 'Ailenin tepkisi'),
        isTrue,
      );
    });

    test('evliyse aile destekler, yakınlık artar', () {
      final GameState s = dogumBekleyen(age: 19, evli: true);
      final Person ebeveyn = s.people.firstWhere(
        (Person p) =>
            p.isAlive &&
            (p.relation == RelationType.anne ||
                p.relation == RelationType.baba),
      );
      final int onceki = ebeveyn.bond;

      final GameState sonra = LifeProgression(Random(4)).advanceOneYear(s);
      final Person? yeni = sonra.personById(ebeveyn.id);
      if (yeni == null || !yeni.isAlive) return;
      if (sonra.children.isEmpty) return;

      expect(yeni.bond, greaterThan(onceki));
    });

    test('yaş bandının dışında tepki üretilmez', () {
      final GameState s = dogumBekleyen(age: 30, evli: false);
      final GameState sonra = LifeProgression(Random(4)).advanceOneYear(s);
      expect(
        sonra.notices.any((PendingNotice n) => n.title == 'Ailenin tepkisi'),
        isFalse,
      );
    });
  });
}
