// Paket BK/6 — çocuğa özel eylemlerin istismar taraması.
//
// Sorulan soru: oyuncu bu dört yeni eylemle oyunu kırabilir mi?
//
//   * Para üretebilir mi? (harçlık bir **gider**; geri dönmemeli)
//   * Çocuğun statlarını 100'e yapıştırabilir mi?
//   * Aynı yıl üst üste tıklayarak faydayı katlayabilir mi?
//   * Kuralı her yıl yenileyerek okul sorununu tamamen kapatabilir mi?
//   * Kayıt alıp vererek bir eylemi iki kez uygulayabilir mi?
library;

import 'dart:math';

import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/domain/family/child_rules.dart';
import 'package:bir_omur/domain/family/child_school_issue.dart';
import 'package:bir_omur/domain/interaction/family_interactions.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/education.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/interaction.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/person_development.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/stats.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const FamilyInteractions etkilesim = FamilyInteractions();

  GameState hayat({int cuzdan = 50000000, int zeka = 50, int cocukYasi = 10}) {
    final GameState base =
        LifeGenerator.seeded(207).generate(mode: StartMode.tamamenRastgele);
    final GameState s = base.copyWith(
      pendingEvent: null,
      notices: const <PendingNotice>[],
      player: base.player.copyWith(age: 40, wallet: cuzdan),
      movedOut: true,
    );
    final Person cocuk = Person(
      id: 'cocuk-bk6',
      firstName: 'Deniz',
      lastName: s.player.lastName,
      gender: Gender.kadin,
      relation: RelationType.cocuk,
      age: cocukYasi,
      isAlive: true,
      inPlayerHousehold: true,
      employment: EmploymentStatus.ogrenci,
      wealth: null,
      schoolLevel: SchoolLevel.ilkokul,
      bond: 70,
      happiness: 60,
      development: PersonDevelopment(
        stats: Stats(
          appearance: 55,
          happiness: 60,
          health: 70,
          intelligence: zeka,
          charisma: 50,
        ),
        tracksLife: true,
        schoolLevel: SchoolLevel.ilkokul,
        grade: 3,
        money: 0,
      ),
    );
    return s.copyWith(
      people: List<Person>.unmodifiable(<Person>[...s.people, cocuk]),
    );
  }

  Person cocukOf(GameState s) => s.personById('cocuk-bk6')!;

  GameState spam(GameState s, InteractionKind kind, int kez) {
    GameState guncel = s;
    for (int i = 0; i < kez; i++) {
      guncel = etkilesim
          .perform(
            state: guncel,
            personId: 'cocuk-bk6',
            kind: kind,
            rng: Random(100 + i),
          )
          .state;
    }
    return guncel;
  }

  group('Para üretilemiyor', () {
    test('harçlık tek yönlü bir giderdir', () {
      final GameState s = hayat();
      final GameState sonra = spam(s, InteractionKind.harclikVer, 30);
      expect(sonra.player.wallet, lessThan(s.player.wallet));
      // Çocuğa giden para oyuncuya geri dönmüyor.
      final int cikan = s.player.wallet - sonra.player.wallet;
      final int girenToplam = cocukOf(sonra).development!.money;
      expect(girenToplam, lessThanOrEqualTo(cikan));
    });

    test('kurs ücreti her denemede ödenir, bedava uğraş yok', () {
      final GameState s = hayat();
      final GameState sonra = spam(s, InteractionKind.hobiyeYazdir, 10);
      final int ilgiSayisi = cocukOf(sonra).development!.interests.length;
      final int odenen = s.player.wallet - sonra.player.wallet;
      // Her uğraş tam ücretle alınmış: bedava ya da indirimli yok.
      expect(
        odenen,
        ilgiSayisi * FamilyInteractions.prototypeOnlyHobbyCost,
      );
    });

    test('çocuğun birikimi oyuncunun cüzdanına dönmüyor', () {
      GameState s = hayat();
      s = spam(s, InteractionKind.harclikVer, 5);
      final int cuzdan = s.player.wallet;
      // Çocuğa özel eylemlerin hiçbiri oyuncuya para getirmiyor.
      for (final InteractionKind k in InteractionKind.values) {
        if (!k.childOnly) continue;
        final GameState sonra = spam(s, k, 5);
        expect(sonra.player.wallet, lessThanOrEqualTo(cuzdan), reason: k.name);
      }
    });
  });

  group('Stat farming yok', () {
    test('ödeve 200 kez oturmak zekâyı 100 yapmıyor', () {
      GameState s = hayat(zeka: 60);
      s = spam(s, InteractionKind.odevYardim, 200);
      expect(cocukOf(s).development!.stats.intelligence, lessThan(100));
    });

    test('aynı yıl tekrarında kazanç eriyor', () {
      final GameState s = hayat(zeka: 50);
      final List<int> artislar = <int>[];
      GameState guncel = s;
      int once = 50;
      for (int i = 0; i < 6; i++) {
        guncel = etkilesim
            .perform(
              state: guncel,
              personId: 'cocuk-bk6',
              kind: InteractionKind.odevYardim,
              rng: Random(11 + i),
            )
            .state;
        final int simdi = cocukOf(guncel).development!.stats.intelligence;
        artislar.add(simdi - once);
        once = simdi;
      }
      // İlk denemenin kazancı sonrakilerin toplamından büyük olmasa da,
      // son denemelerin kazancı sıfıra inmeli: sonsuz tırmanış yok.
      expect(artislar.last, 0, reason: 'Kazanç erimiyor: $artislar');
    });

    test('kurs ilgi alanı üst sınırını aşmıyor', () {
      GameState s = hayat();
      s = spam(s, InteractionKind.hobiyeYazdir, 20);
      expect(
        cocukOf(s).development!.interests.length,
        lessThanOrEqualTo(3),
      );
    });
  });

  group('Kural sınırı', () {
    test('kural okul sorununu tamamen kapatmıyor', () {
      GameState s = hayat(zeka: 40);
      s = spam(s, InteractionKind.kuralKoy, 10);
      final double sans = ChildSchoolIssue.chanceFor(s, cocukOf(s));
      expect(sans, greaterThan(0), reason: 'Kural garanti vermez');
    });

    test('indirim en çok yarıya kadar', () {
      GameState s = hayat(zeka: 40);
      final double once = ChildSchoolIssue.chanceFor(s, cocukOf(s));
      s = spam(s, InteractionKind.kuralKoy, 10);
      final double sonra = ChildSchoolIssue.chanceFor(s, cocukOf(s));
      expect(
        sonra,
        greaterThanOrEqualTo(once * ChildRules.prototypeOnlyRelief - 0.0001),
      );
    });

    test('arası kopuk çocukta kural işlemiyor', () {
      GameState s = hayat(zeka: 40);
      s = s.copyWith(
        people: List<Person>.unmodifiable(<Person>[
          for (final Person p in s.people)
            if (p.id == 'cocuk-bk6')
              p.copyWith(bond: ChildRules.prototypeOnlyDeafBond - 1)
            else
              p,
        ]),
      );
      s = spam(s, InteractionKind.kuralKoy, 5);
      expect(ChildRules.reliefFor(s, cocukOf(s)), 1.0);
    });
  });

  group('Kayıt alıp vermek bir şeyi iki kez uygulamıyor', () {
    test('save/load sonrası sayaçlar korunuyor', () {
      GameState s = hayat();
      s = spam(s, InteractionKind.odevYardim, 3);
      final int sayac =
          s.interactionCount('cocuk-bk6', InteractionKind.odevYardim.name);
      expect(sayac, greaterThan(0));

      final GameState geri = decodeGameState(encodeGameState(s));
      expect(
        geri.interactionCount('cocuk-bk6', InteractionKind.odevYardim.name),
        sayac,
      );
      // Yükledikten sonra devam edince kazanç sıfırlanmıyor: eğri
      // kaldığı yerden sürüyor.
      final int zekaOnce = cocukOf(geri).development!.stats.intelligence;
      final GameState devam = spam(geri, InteractionKind.odevYardim, 3);
      expect(
        cocukOf(devam).development!.stats.intelligence - zekaOnce,
        lessThanOrEqualTo(
          FamilyInteractions.prototypeOnlyHomeworkIntelligence,
        ),
      );
    });

    test('kural yılı kayda giriyor, yükleyince yenilenmiyor', () {
      GameState s = hayat(zeka: 40);
      s = spam(s, InteractionKind.kuralKoy, 6);
      final int? yil = ChildRules.setAtAge(s, 'cocuk-bk6');
      expect(yil, isNotNull);
      final GameState geri = decodeGameState(encodeGameState(s));
      expect(ChildRules.setAtAge(geri, 'cocuk-bk6'), yil);
    });
  });
}
