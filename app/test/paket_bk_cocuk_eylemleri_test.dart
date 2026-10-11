// Paket BK/3 — çocuğa özel eylemler (Q-203).
//
// Ölçülmüş bulgu: altı etkileşim türünün hiçbiri çocuğa özel değildi;
// annene de çocuğuna da aynı liste çıkıyordu. Dört yeni tür o kalıbı
// kırıyor ve hedefleri **çocuğun kendi kaydı**: zekâsı, birikimi, ilgi
// alanları, evdeki kural.
//
// Bu testler üç şeyi sabitler:
//   1. Eylem gerçekten çocuğun kaydını değiştiriyor (sahte kazanç yok).
//   2. Para gerçekten el değiştiriyor ve cüzdanda yoksa kapı kapalı.
//   3. Tekrarlamakla çocuk 100'e yapışmıyor (azalan fayda + Stats.gain).
library;

import 'dart:math';

import 'package:bir_omur/domain/family/child_rules.dart';
import 'package:bir_omur/domain/family/child_school_issue.dart';
import 'package:bir_omur/domain/generation/child_progression.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/interaction/family_interactions.dart';
import 'package:bir_omur/domain/interaction/interaction_policy.dart';
import 'package:bir_omur/domain/models/education.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/interaction.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/person_development.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/stats.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const FamilyInteractions etkilesim = FamilyInteractions();

  /// Okula giden bir çocuğu olan hayat.
  GameState hayat({
    int cocukYasi = 10,
    SchoolLevel kademe = SchoolLevel.ilkokul,
    int zeka = 50,
    int cocukKeyfi = 60,
    int yakinlik = 60,
    int cuzdan = 500000,
    List<String> ilgiler = const <String>[],
  }) {
    final GameState base =
        LifeGenerator.seeded(91).generate(mode: StartMode.tamamenRastgele);
    final GameState s = base.copyWith(
      pendingEvent: null,
      notices: const <PendingNotice>[],
      player: base.player.copyWith(age: 36, wallet: cuzdan),
      movedOut: true,
    );
    final Person cocuk = Person(
      id: 'cocuk-bk3',
      firstName: 'Deniz',
      lastName: s.player.lastName,
      gender: Gender.kadin,
      relation: RelationType.cocuk,
      age: cocukYasi,
      isAlive: true,
      inPlayerHousehold: true,
      employment: EmploymentStatus.ogrenci,
      wealth: null,
      schoolLevel: kademe,
      bond: yakinlik,
      happiness: cocukKeyfi,
      development: PersonDevelopment(
        stats: Stats(
          appearance: 55,
          happiness: cocukKeyfi,
          health: 70,
          intelligence: zeka,
          charisma: 50,
        ),
        tracksLife: true,
        schoolLevel: kademe,
        grade: kademe.firstGrade,
        money: 0,
        interests: List<String>.unmodifiable(ilgiler),
      ),
    );
    return s.copyWith(
      people: List<Person>.unmodifiable(<Person>[...s.people, cocuk]),
    );
  }

  Person cocukOf(GameState s) => s.personById('cocuk-bk3')!;

  InteractionResult yap(
    GameState s,
    InteractionKind kind, {
    int seed = 5,
  }) =>
      etkilesim.perform(
        state: s,
        personId: 'cocuk-bk3',
        kind: kind,
        rng: Random(seed),
      );

  group('Liste çocuğa özel', () {
    test('dört yeni tür yalnızca çocukta anlamlı', () {
      final Set<InteractionKind> cocukta =
          meaningfulKindsFor(RelationType.cocuk);
      for (final InteractionKind k in InteractionKind.values) {
        if (!k.childOnly) continue;
        expect(cocukta, contains(k), reason: k.name);
        // Anne, kardeş, arkadaş: hiçbirinde çıkmaz.
        for (final RelationType r in <RelationType>[
          RelationType.anne,
          RelationType.kardes,
          RelationType.arkadas,
          RelationType.es,
          RelationType.torun,
        ]) {
          expect(meaningfulKindsFor(r), isNot(contains(k)),
              reason: '${k.name} / ${r.name}');
        }
      }
    });

    test('anneye uygulanmak istenirse gerekçesiyle kapanır', () {
      final GameState s = hayat();
      final Person anne = s.people
          .firstWhere((Person p) => p.relation == RelationType.anne);
      final InteractionAvailability u = etkilesim.availability(
        s,
        anne,
        InteractionKind.harclikVer,
      );
      expect(u.isAllowed, isFalse);
      expect(u.reason, isNotNull);
    });
  });

  group('Ödevine otur', () {
    test('çocuğun zekâsı gerçekten artar', () {
      final GameState s = hayat(zeka: 45);
      final InteractionResult r = yap(s, InteractionKind.odevYardim);
      // Red gelebilir (D-020); kabul edilen bir denemede etki aranır.
      if (!r.outcome.accepted) return;
      final PersonDevelopment sonra = cocukOf(r.state).development!;
      expect(sonra.stats.intelligence, greaterThan(45));
      expect(cocukOf(r.state).bond, greaterThan(cocukOf(s).bond));
    });

    test('okula gitmeyen çocukta kapı gerekçeyle kapalı', () {
      GameState s = hayat(cocukYasi: 4);
      s = s.copyWith(
        people: List<Person>.unmodifiable(<Person>[
          for (final Person p in s.people)
            if (p.id == 'cocuk-bk3')
              p.copyWith(
                employment: EmploymentStatus.cocuk,
                development: p.development!.copyWith(
                  tracksLife: true,
                  schoolLevel: null,
                  grade: null,
                ),
              )
            else
              p,
        ]),
      );
      final InteractionAvailability u = etkilesim.availability(
        s,
        cocukOf(s),
        InteractionKind.odevYardim,
      );
      expect(u.isAllowed, isFalse);
      expect(u.reason, contains('okula gitmiyor'));
    });

    test('tekrar tekrar oturmak çocuğu 100 zekâya çıkarmaz', () {
      GameState s = hayat(zeka: 70);
      for (int i = 0; i < 40; i++) {
        s = yap(s, InteractionKind.odevYardim, seed: i).state;
      }
      expect(cocukOf(s).development!.stats.intelligence, lessThan(100));
    });
  });

  group('Harçlık ver', () {
    test('para cüzdandan çıkar ve çocuğun birikimine girer', () {
      final GameState s = hayat(cocukYasi: 10);
      final int cuzdanOnce = s.player.wallet;
      final InteractionResult r = yap(s, InteractionKind.harclikVer);
      expect(r.outcome.accepted, isTrue,
          reason: 'Harçlık vermek reddedilmez');
      expect(r.state.player.wallet, lessThan(cuzdanOnce));
      expect(cocukOf(r.state).development!.money, greaterThan(0));
      // Çıkan para ile çocuğa giren para **aynı**: kayıp yok, uydurma
      // kazanç yok.
      expect(
        cuzdanOnce - r.state.player.wallet,
        cocukOf(r.state).development!.money,
      );
    });

    test('kademe yükseldikçe harçlık artar', () {
      int tutar(SchoolLevel kademe, int yas) {
        final GameState s = hayat(cocukYasi: yas, kademe: kademe);
        final InteractionResult r = yap(s, InteractionKind.harclikVer);
        return s.player.wallet - r.state.player.wallet;
      }

      final int ilk = tutar(SchoolLevel.ilkokul, 9);
      final int orta = tutar(SchoolLevel.ortaokul, 12);
      final int lise = tutar(SchoolLevel.lise, 16);
      expect(orta, greaterThan(ilk));
      expect(lise, greaterThan(orta));
    });

    test('cüzdanda para yoksa kapı gerekçeyle kapalı', () {
      final GameState s = hayat(cuzdan: 100);
      final InteractionAvailability u = etkilesim.availability(
        s,
        cocukOf(s),
        InteractionKind.harclikVer,
      );
      expect(u.isAllowed, isFalse);
      expect(u.reason, contains('Harçlık için'));
    });

    test('aynı yıl tekrarında tutar erir, sonsuz aktarım olmaz', () {
      GameState s = hayat();
      final List<int> tutarlar = <int>[];
      for (int i = 0; i < 6; i++) {
        final int once = s.player.wallet;
        s = yap(s, InteractionKind.harclikVer, seed: i).state;
        tutarlar.add(once - s.player.wallet);
      }
      expect(tutarlar.first, greaterThan(0));
      expect(tutarlar.last, lessThan(tutarlar.first));
    });
  });

  group('Hobiye yazdır', () {
    test('çocuk gerçekten yeni bir uğraş edinir', () {
      final GameState s = hayat();
      final InteractionResult r = yap(s, InteractionKind.hobiyeYazdir);
      expect(r.outcome.accepted, isTrue);
      final List<String> ilgiler = cocukOf(r.state).development!.interests;
      expect(ilgiler, hasLength(1));
      expect(ChildProgression.prototypeOnlyInterests, contains(ilgiler.single));
      // Sonuç metni hangi uğraş olduğunu yazar: ekranda yer tutucu
      // kalmaz.
      expect(r.outcome.text, contains(ilgiler.single));
      expect(r.outcome.text, isNot(contains('{hobi}')));
    });

    test('ilgi alanları dolu çocukta kapı kapalı', () {
      final GameState s = hayat(
        ilgiler: ChildProgression.prototypeOnlyInterests
            .take(ChildProgression.prototypeOnlyMaxInterests)
            .toList(growable: false),
      );
      final InteractionAvailability u = etkilesim.availability(
        s,
        cocukOf(s),
        InteractionKind.hobiyeYazdir,
      );
      expect(u.isAllowed, isFalse);
    });

    test('kurs ücreti gerçekten ödenir', () {
      final GameState s = hayat();
      final InteractionResult r = yap(s, InteractionKind.hobiyeYazdir);
      expect(
        s.player.wallet - r.state.player.wallet,
        FamilyInteractions.prototypeOnlyHobbyCost,
      );
    });
  });

  group('Kural koy', () {
    test('kuralın bedeli çocuğun keyfi, karşılığı okul sorunu ihtimali', () {
      // Sorun ihtimali olan bir çocuk: zekâsı eşiğin altında.
      final GameState s = hayat(zeka: 40, cocukKeyfi: 60);
      final double once = ChildSchoolIssue.chanceFor(s, cocukOf(s));
      expect(once, greaterThan(0), reason: 'Ölçüm için sorun sebebi olmalı');

      final InteractionResult r = yap(s, InteractionKind.kuralKoy, seed: 3);
      if (!r.outcome.accepted) return; // ergen/çocuk reddedebilir
      expect(
        cocukOf(r.state).happiness,
        lessThan(cocukOf(s).happiness),
        reason: 'Kural sevilmez',
      );
      expect(ChildRules.activeFor(r.state, cocukOf(r.state)), isTrue);
      expect(
        ChildSchoolIssue.chanceFor(r.state, cocukOf(r.state)),
        lessThan(once),
      );
    });

    test('kural üç yılda söner', () {
      GameState s = hayat(zeka: 40);
      InteractionResult r = yap(s, InteractionKind.kuralKoy, seed: 3);
      int deneme = 0;
      while (!r.outcome.accepted && deneme < 10) {
        deneme++;
        r = yap(s, InteractionKind.kuralKoy, seed: 3 + deneme);
      }
      s = r.state;
      expect(ChildRules.activeFor(s, cocukOf(s)), isTrue);

      final GameState ileri = s.copyWith(
        player: s.player.copyWith(
          age: s.player.age + ChildRules.prototypeOnlyFadeYears,
        ),
      );
      expect(ChildRules.activeFor(ileri, cocukOf(ileri)), isFalse);
      expect(ChildRules.reliefFor(ileri, cocukOf(ileri)), 1.0);
    });

    test('kural konulmamışsa hesap hiç değişmez', () {
      final GameState s = hayat(zeka: 40);
      expect(ChildRules.reliefFor(s, cocukOf(s)), 1.0);
    });

    test('18 yaşını geçmiş çocuğa kural konulmaz', () {
      final GameState s = hayat(cocukYasi: 20, kademe: SchoolLevel.lise);
      final InteractionAvailability u = etkilesim.availability(
        s,
        cocukOf(s),
        InteractionKind.kuralKoy,
      );
      expect(u.isAllowed, isFalse);
      expect(u.reason, contains('kendi kararlarını'));
    });
  });
}
