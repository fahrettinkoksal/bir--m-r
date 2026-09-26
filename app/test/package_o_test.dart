import 'dart:math';

import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:bir_omur/domain/education/education_path.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/interaction/finger.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/interaction.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:bir_omur/domain/pets/pet_care.dart';
import 'package:bir_omur/text/turkish_text.dart';
import 'package:flutter_test/flutter_test.dart';

/// Paket O: Faho'nun bildirdiği gerçek hatalar (D-111, D-112).
void main() {
  GameState taban({int seed = 3, int age = 25}) {
    final GameState base =
        LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
    return base.copyWith(
      pendingEvent: null,
      player: base.player.copyWith(age: age, wallet: 200000),
    );
  }

  group('Hayvan hastalık bildirimi', () {
    test('sayı cümle sonunda kalmaz, sıra sayısı gibi okunmaz', () {
      // Faho'nun ekran görüntüsü: "Sağlığı 57. Aktiviteler → ..." satırı
      // "57. Aktiviteler" diye okunuyordu.
      GameState s = taban(age: 30);
      s = s.copyWith(
        pets: <Pet>[
          const Pet(
            id: 'p1',
            species: 'kedi',
            name: 'Minnoş',
            age: 3,
            adoptedAtPlayerAge: 27,
            bond: 70,
            health: 57,
          ),
        ],
      );
      bool goruldu = false;
      for (int seed = 0; seed < 200 && !goruldu; seed++) {
        final GameState sonra =
            PetCare.advanceYear(s, s.player.age + 1, Random(seed));
        for (final PendingNotice n in sonra.notices) {
          if (!n.text.contains('hastalandı')) continue;
          goruldu = true;
          expect(
            RegExp(r'Sağlığı \d+\.').hasMatch(n.text),
            isFalse,
            reason: 'Sıra sayısı gibi okunan kalıp kaldı: ${n.text}',
          );
          expect(n.text, contains('(sağlığı '));
          // Ücret ham değil, Türkçe biçimde yazılır.
          expect(RegExp(r'\(\d{4,} ₺\)').hasMatch(n.text), isFalse);
          break;
        }
      }
      expect(goruldu, isTrue, reason: 'Hasta bildirimi hiç üretilmedi');
    });

    test('veteriner ücreti Türkçe binlik ayracıyla yazılır', () {
      // Aynı cümlede ham "5500 ₺" vardı; her yerde trMoney kullanılıyor.
      expect(trMoney(5500), '5.500 ₺');
    });
  });

  group('Eğitim kararı yaş almayı kilitler (D-111)', () {
    test('lise bitince sonraki yol seçilmeden karar bekler', () {
      GameState s = taban(age: 18);
      s = s.copyWith(
        education: s.education.copyWith(
          enrolled: false,
          finished: true,
          grade: null,
        ),
      );
      expect(s.education.awaitingAfterSchoolChoice, isTrue);
      expect(EducationPath.needsAfterSchoolChoice(s), isTrue);
    });

    test('üniversiteye gitmeme kararı kilidi açar', () {
      GameState s = taban(age: 18);
      s = s.copyWith(
        education: s.education.copyWith(
          enrolled: false,
          finished: true,
          grade: null,
        ),
      );
      final EducationResult r = const EducationPath().skipUniversity(s);
      expect(r.outcome.applied, isTrue);
      // Karar verildi: artık beklemiyor. Eskiden bu bayrak okunmadığı
      // için oyuncu sonsuza dek "karar bekliyor" durumunda kalırdı.
      expect(
        EducationPath.needsAfterSchoolChoice(r.state),
        isFalse,
        reason: 'Karar verildiği hâlde kilit açılmıyor; oyuncu kilitlenir.',
      );
    });

    test('lise sürerken sonraki yol kararı sorulmaz', () {
      final GameState s = taban(age: 15);
      expect(EducationPath.needsAfterSchoolChoice(s), isFalse);
    });
  });

  group('Finger: arkadaşlık bir son değil (D-112)', () {
    Person arkadas({int bond = 60, int age = 26}) => Person(
          id: 'f1',
          firstName: 'Deniz',
          lastName: 'Aksoy',
          gender: Gender.kadin,
          relation: RelationType.arkadas,
          age: age,
          isAlive: true,
          inPlayerHousehold: false,
          employment: EmploymentStatus.calisiyor,
          wealth: WealthTier.ortaHalli,
          bond: bond,
        );

    GameState ile(Person p, {int age = 26}) {
      final GameState s = taban(age: age);
      return s.copyWith(people: <Person>[...s.people, p]);
    }

    test('yeterli yakınlıkta çıkma teklif edilebilir', () {
      final GameState s = ile(arkadas());
      expect(Finger.askOutAvailability(s, 'f1').isAllowed, isTrue);
    });

    test('yakınlık yetmiyorsa sebebi ve mevcut yakınlık yazar', () {
      final GameState s = ile(arkadas(bond: 30));
      final InteractionAvailability a = Finger.askOutAvailability(s, 'f1');
      expect(a.isAllowed, isFalse);
      expect(a.reason, contains('50'));
      expect(a.reason, contains('30'));
    });

    test('kabul edilirse flört başlar, reddedilirse arkadaş kalınır', () {
      bool flortGoruldu = false;
      bool retGoruldu = false;
      for (int seed = 0; seed < 40; seed++) {
        final GameState s = ile(arkadas(bond: 55));
        final FingerResult r = Finger.askOut(s, 'f1', Random(seed));
        expect(r.outcome.applied, isTrue);
        final Person sonra = r.state.personById('f1')!;
        if (sonra.relation == RelationType.flort) {
          flortGoruldu = true;
        } else {
          retGoruldu = true;
          // Teklif bedelsiz değil: reddedilince yakınlık düşer.
          expect(sonra.bond, lessThan(55));
          expect(sonra.relation, RelationType.arkadas);
        }
      }
      expect(flortGoruldu, isTrue, reason: 'Hiç kabul edilmedi');
      expect(retGoruldu, isTrue, reason: 'Hiç reddedilmedi');
    });

    test('hayatında biri varken teklif edilemez', () {
      GameState s = ile(arkadas());
      s = s.copyWith(
        people: <Person>[
          ...s.people.map((Person p) => p.id == 'f1'
              ? p
              : p.relation == RelationType.anne
                  ? p
                  : p),
          Person(
            id: 'sev1',
            firstName: 'Ece',
            lastName: 'Kaya',
            gender: Gender.kadin,
            relation: RelationType.sevgili,
            age: 26,
            isAlive: true,
            inPlayerHousehold: false,
            employment: EmploymentStatus.calisiyor,
          wealth: WealthTier.ortaHalli,
            bond: 70,
          ),
        ],
      );
      final InteractionAvailability a = Finger.askOutAvailability(s, 'f1');
      expect(a.isAllowed, isFalse);
      expect(a.reason, contains('zaten biri var'));
    });
  });

  group('Finger: sevgili olma koşulu önceden görünür (D-112)', () {
    GameState flortIle(int bond) {
      final GameState s = taban(age: 26);
      return s.copyWith(
        people: <Person>[
          ...s.people,
          Person(
            id: 'x1',
            firstName: 'Kaan',
            lastName: 'Er',
            gender: Gender.erkek,
            relation: RelationType.flort,
            age: 27,
            isAlive: true,
            inPlayerHousehold: false,
            employment: EmploymentStatus.calisiyor,
          wealth: WealthTier.ortaHalli,
            bond: bond,
          ),
        ],
      );
    }

    test('yakınlık yetmiyorsa gereken ve mevcut değer birlikte yazar', () {
      final InteractionAvailability a =
          Finger.officialAvailability(flortIle(52), 'x1');
      expect(a.isAllowed, isFalse);
      expect(a.reason, contains('60'));
      expect(a.reason, contains('52'));
    });

    test('yakınlık yetiyorsa açıktır', () {
      expect(
        Finger.officialAvailability(flortIle(75), 'x1').isAllowed,
        isTrue,
      );
    });
  });
}
