import 'dart:math';

import 'package:bir_omur/data/activity_catalog.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/domain/activities/activity_engine.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/generation/life_progression.dart';
import 'package:bir_omur/domain/life/aging.dart';
import 'package:bir_omur/domain/life/hair_loss.dart';
import 'package:bir_omur/domain/life/upkeep_tracker.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/stats.dart';
import 'package:flutter_test/flutter_test.dart';

/// Statların yaşla düşmesi ve bakımın karşılığı (D-072, D-073).
///
/// Faho'nun bildirdiği durum: "zekâ 100 olarak başladım 100 olarak
/// bitirdim", "kullanıcı sene atlayınca statlar aynı kalmasın", "bakım
/// yapmayınca görünüşüm ve karizmam düşsün", "sürekli spor yapan
/// birisinin karizması daha az düşsün".
void main() {
  Stats tam() => const Stats(
        appearance: 100,
        happiness: 100,
        health: 100,
        intelligence: 100,
        charisma: 100,
      );

  const UpkeepStatus bakimsiz = UpkeepStatus();
  group('Başlangıç yaşları', () {
    test('her değerin kendi başlangıç yaşından önce düşüş olmaz', () {
      final Random rng = Random(1);
      for (int age = 0; age < 100; age++) {
        for (int i = 0; i < 40; i++) {
          final StatDrift d = StatAging.yearlyDrift(
            age: age,
            stats: tam(),
            upkeep: bakimsiz,
            rng: rng,
          );
          if (age < StatAging.prototypeOnlyAppearanceFromAge) {
            expect(d.appearance, 0, reason: '$age yaşında görünüş düşmemeli');
          }
          if (age < StatAging.prototypeOnlyCharismaFromAge) {
            expect(d.charisma, 0, reason: '$age yaşında karizma düşmemeli');
          }
          if (age < StatAging.prototypeOnlyHealthFromAge) {
            expect(d.health, 0, reason: '$age yaşında sağlık düşmemeli');
          }
          if (age < StatAging.prototypeOnlyIntelligenceFromAge) {
            expect(d.intelligence, 0, reason: '$age yaşında zekâ düşmemeli');
          }
          if (age < StatAging.prototypeOnlyHappinessFromAge) {
            expect(d.happiness, 0, reason: '$age yaşında mutluluk düşmemeli');
          }
        }
      }
    });

    test('değişim yalnızca aşağı yönlüdür; yaşlanmak puan kazandırmaz', () {
      final Random rng = Random(2);
      for (int age = 30; age <= 95; age++) {
        for (int i = 0; i < 20; i++) {
          final StatDrift d = StatAging.yearlyDrift(
            age: age,
            stats: tam(),
            upkeep: bakimsiz,
            rng: rng,
          );
          expect(d.appearance, lessThanOrEqualTo(0));
          expect(d.charisma, lessThanOrEqualTo(0));
          expect(d.health, lessThanOrEqualTo(0));
          expect(d.intelligence, lessThanOrEqualTo(0));
          expect(d.happiness, lessThanOrEqualTo(0));
        }
      }
    });
  });

  group('Tabanlar', () {
    test('ilgisizlik ve yaş hiçbir değeri tabanın altına indirmez', () {
      final Random rng = Random(3);
      Stats s = Stats(
        appearance: StatAging.prototypeOnlyAppearanceFloor,
        happiness: StatAging.prototypeOnlyHappinessFloor,
        health: StatAging.prototypeOnlyHealthFloor,
        intelligence: StatAging.prototypeOnlyIntelligenceFloor,
        charisma: StatAging.prototypeOnlyCharismaFloor,
      );
      for (int i = 0; i < 400; i++) {
        final StatDrift d = StatAging.yearlyDrift(
          age: 95,
          stats: s,
          upkeep: bakimsiz,
          rng: rng,
        );
        expect(d.isEmpty, isTrue, reason: 'tabanda kayıp üretilmemeli');
      }

      // Tabanın bir üstünden başlayan uzun bir hayat da tabanı delmez.
      s = Stats(
        appearance: StatAging.prototypeOnlyAppearanceFloor + 3,
        happiness: StatAging.prototypeOnlyHappinessFloor + 3,
        health: StatAging.prototypeOnlyHealthFloor + 3,
        intelligence: StatAging.prototypeOnlyIntelligenceFloor + 3,
        charisma: StatAging.prototypeOnlyCharismaFloor + 3,
      );
      for (int age = 60; age <= 110; age++) {
        final StatDrift d = StatAging.yearlyDrift(
          age: age,
          stats: s,
          upkeep: bakimsiz,
          rng: rng,
        );
        s = s.copyWith(
          appearance: s.appearance + d.appearance,
          charisma: s.charisma + d.charisma,
          health: s.health + d.health,
          intelligence: s.intelligence + d.intelligence,
          happiness: s.happiness + d.happiness,
        );
      }
      expect(s.appearance,
          greaterThanOrEqualTo(StatAging.prototypeOnlyAppearanceFloor));
      expect(
          s.charisma, greaterThanOrEqualTo(StatAging.prototypeOnlyCharismaFloor));
      expect(s.health, greaterThanOrEqualTo(StatAging.prototypeOnlyHealthFloor));
      expect(s.intelligence,
          greaterThanOrEqualTo(StatAging.prototypeOnlyIntelligenceFloor));
      expect(s.happiness,
          greaterThanOrEqualTo(StatAging.prototypeOnlyHappinessFloor));
    });
  });

  group('Bakımın karşılığı', () {
    /// 35'ten 80'e kadar yaşanan bir hayatın sonundaki değerler.
    Stats yasa(UpkeepStatus upkeep, int seed) {
      final Random rng = Random(seed);
      Stats s = tam();
      for (int age = 35; age <= 80; age++) {
        final StatDrift d = StatAging.yearlyDrift(
          age: age,
          stats: s,
          upkeep: upkeep,
          rng: rng,
        );
        s = s.copyWith(
          appearance: s.appearance + d.appearance,
          charisma: s.charisma + d.charisma,
          health: s.health + d.health,
          intelligence: s.intelligence + d.intelligence,
          happiness: s.happiness + d.happiness,
        );
      }
      return s;
    }

    test('spor yapanın karizması ve sağlığı belirgin biçimde az düşer', () {
      int sporluKarizma = 0, sporsuzKarizma = 0;
      int sporluSaglik = 0, sporsuzSaglik = 0;
      for (int seed = 0; seed < 120; seed++) {
        final Stats sporlu = yasa(
          const UpkeepStatus(yearsSinceSport: 0),
          seed,
        );
        final Stats sporsuz = yasa(const UpkeepStatus(), seed);
        sporluKarizma += sporlu.charisma;
        sporsuzKarizma += sporsuz.charisma;
        sporluSaglik += sporlu.health;
        sporsuzSaglik += sporsuz.health;
      }
      expect(sporluKarizma, greaterThan(sporsuzKarizma),
          reason: 'spor karizma kaybını yavaşlatmalı');
      expect(sporluSaglik, greaterThan(sporsuzSaglik),
          reason: 'spor sağlık kaybını yavaşlatmalı');
    });

    test('berbere gidenin görünüşü daha yavaş düşer', () {
      int bakimliToplam = 0, bakimsizToplam = 0;
      for (int seed = 0; seed < 120; seed++) {
        bakimliToplam +=
            yasa(const UpkeepStatus(yearsSinceGrooming: 0), seed).appearance;
        bakimsizToplam += yasa(const UpkeepStatus(), seed).appearance;
      }
      expect(bakimliToplam, greaterThan(bakimsizToplam));
    });

    test('okuyan/kurs alan zekâsını daha iyi korur', () {
      int okuyanToplam = 0, okumayanToplam = 0;
      for (int seed = 0; seed < 120; seed++) {
        okuyanToplam +=
            yasa(const UpkeepStatus(yearsSinceLearning: 0), seed).intelligence;
        okumayanToplam += yasa(const UpkeepStatus(), seed).intelligence;
      }
      expect(okuyanToplam, greaterThan(okumayanToplam));
    });

    test('hiç yapmamak, uzun süredir yapmamakla aynı kovaya düşer', () {
      expect(
        StatAging.upkeepFactor(null, 40),
        StatAging.upkeepFactor(StatAging.prototypeOnlyNeglectYears + 5, 40),
      );
    });

    test('çocuk yaşta bakımsızlık cezası yoktur', () {
      expect(
        StatAging.upkeepFactor(null, StatAging.prototypeOnlyUpkeepFromAge - 1),
        1.0,
      );
    });
  });

  group('Bakım kaydı', () {
    GameState hayat(int seed, {int age = 40}) {
      final GameState base =
          LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
      return base.copyWith(
        player: base.player.copyWith(age: age, wallet: 500000),
      );
    }

    ActivityAction eylem(String id) =>
        kActivityActions.firstWhere((ActivityAction a) => a.id == id);

    test('spor salonuna gitmek bakım geçmişine yazılır', () {
      final GameState state = hayat(5);
      expect(state.lastSportAge, isNull);
      final ActivityResult r = const ActivityEngine().perform(
        state: state,
        action: eylem('kosu'),
        rng: Random(1),
      );
      expect(r.outcome.applied, isTrue);
      expect(r.state.lastSportAge, state.player.age);
      expect(r.state.yearsSinceSport, 0);
    });

    test('berbere gitmek bakım geçmişine yazılır', () {
      final GameState state = hayat(6);
      final ActivityResult r = const ActivityEngine().perform(
        state: state,
        action: eylem('sac_kestir'),
        rng: Random(1),
      );
      expect(r.outcome.applied, isTrue);
      expect(r.state.lastGroomingAge, state.player.age);
    });

    test('kursa gitmek zihin bakımına yazılır', () {
      final GameState state = hayat(7);
      final ActivityResult r = const ActivityEngine().perform(
        state: state,
        action: eylem('dil_kursu'),
        rng: Random(1),
      );
      expect(r.outcome.applied, isTrue);
      expect(r.state.lastLearningAge, state.player.age);
    });

    test('bakım geçmişi ve saç basamağı kapat-aç ile korunur', () {
      GameState state = hayat(8);
      state = UpkeepTracker.recordSport(state);
      state = UpkeepTracker.recordGrooming(state);
      state = UpkeepTracker.recordLearning(state);
      state = state.copyWith(
        player: state.player.copyWith(hairLossStage: 2),
      );

      final GameState geri = decodeGameState(encodeGameState(state));
      expect(geri.lastSportAge, state.lastSportAge);
      expect(geri.lastGroomingAge, state.lastGroomingAge);
      expect(geri.lastLearningAge, state.lastLearningAge);
      expect(geri.player.hairLossStage, 2);
    });

    test('eski kayıtta bakım geçmişi yoktur ve ihmal sayılmaz', () {
      final GameState state = hayat(9);
      final Map<String, Object?> json = encodeGameState(state);
      json.remove('lastSportAge');
      json.remove('lastGroomingAge');
      json.remove('lastLearningAge');
      final GameState geri = decodeGameState(json);
      expect(geri.lastSportAge, isNull);
      expect(geri.yearsSinceSport, isNull);
      expect(geri.player.hairLossStage, 0);
    });
  });

  group('Saç dökülmesi', () {
    HairLossStep adim(Gender g, int age, int stage, Random rng,
            {bool groomed = false}) =>
        HairLoss.step(
          gender: g,
          age: age,
          stage: stage,
          groomedRecently: groomed,
          rng: rng,
        );

    test('kadın karakterde işletilmez', () {
      final Random rng = Random(1);
      for (int i = 0; i < 500; i++) {
        expect(adim(Gender.kadin, 60, 0, rng).stage, 0);
      }
    });

    test('30 yaşından önce başlamaz', () {
      final Random rng = Random(2);
      for (int age = 0; age < HairLoss.prototypeOnlyStartAge; age++) {
        for (int i = 0; i < 60; i++) {
          expect(adim(Gender.erkek, age, 0, rng).stage, 0,
              reason: '$age yaşında dökülme başlamamalı');
        }
      }
    });

    test('50 yaşında erkeklerin kabaca yarısında başlamış olur', () {
      // Epidemiyolojik çıpa: androjenetik alopesi erkeklerin yaklaşık
      // %50'sinde 50'li yaşlarda görülür. Oyunda başlangıç 30 olduğu
      // için 30-49 arası birikimli ihtimal bu bandı tutmalıdır.
      int baslayan = 0;
      const int kisi = 3000;
      for (int seed = 0; seed < kisi; seed++) {
        final Random rng = Random(seed);
        int stage = 0;
        for (int age = 30; age < 50; age++) {
          stage = adim(Gender.erkek, age, stage, rng).stage;
        }
        if (stage > 0) baslayan++;
      }
      final double oran = baslayan / kisi;
      expect(oran, greaterThan(0.42), reason: 'ölçülen oran: $oran');
      expect(oran, lessThan(0.58), reason: 'ölçülen oran: $oran');
    });

    test('basamak geri gitmez ve en fazla üçe çıkar', () {
      final Random rng = Random(4);
      int stage = 0;
      for (int age = 30; age <= 110; age++) {
        final HairLossStep s = adim(Gender.erkek, age, stage, rng);
        expect(s.stage, greaterThanOrEqualTo(stage));
        expect(s.stage, lessThanOrEqualTo(HairLoss.maxStage));
        stage = s.stage;
      }
      // En üst basamakta artık kayıp üretilmez.
      for (int i = 0; i < 200; i++) {
        final HairLossStep s =
            adim(Gender.erkek, 90, HairLoss.maxStage, rng);
        expect(s.changed, isFalse);
      }
    });

    test('bakım yapan oyuncuda kayıp yarıya iner', () {
      int bakimliToplam = 0, bakimsizToplam = 0;
      for (int seed = 0; seed < 400; seed++) {
        final HairLossStep a =
            adim(Gender.erkek, 45, 1, Random(seed), groomed: true);
        final HairLossStep b =
            adim(Gender.erkek, 45, 1, Random(seed), groomed: false);
        bakimliToplam += a.appearance + a.charisma;
        bakimsizToplam += b.appearance + b.charisma;
      }
      expect(bakimliToplam, greaterThan(bakimsizToplam),
          reason: 'bakımlı kayıp daha küçük (negatiflerde daha büyük sayı)');
    });
  });

  group('Oyun akışı ölçümü', () {
    test('statlar bir ömür boyunca sabit kalmaz ve ömür makul kalır', () {
      final List<int> olumYaslari = <int>[];
      int zekasiSabitKalan = 0;
      int statiDegisen = 0;
      const int hayatSayisi = 120;

      for (int seed = 0; seed < hayatSayisi; seed++) {
        GameState s = LifeGenerator.seeded(seed)
            .generate(mode: StartMode.tamamenRastgele);
        final Stats basla = s.player.stats;
        final LifeProgression lp = LifeProgression(Random(seed + 9000));
        while (!s.deceased && s.player.age < 105) {
          s = lp.advanceOneYear(s.copyWith(pendingEvent: null));
        }
        final Stats bitir = s.player.stats;
        if (s.deathAge != null && s.deathAge! >= 65) {
          if (bitir.intelligence == basla.intelligence) zekasiSabitKalan++;
          if (bitir.charisma != basla.charisma ||
              bitir.appearance != basla.appearance ||
              bitir.health != basla.health) {
            statiDegisen++;
          }
        }
        olumYaslari.add(s.deathAge ?? s.player.age);
      }

      // Faho'nun şikâyeti: "zekâ 100 olarak başladım 100 olarak bitirdim".
      // 65 yaşını geçen hayatların büyük çoğunluğunda değerler oynamalı.
      expect(statiDegisen, greaterThan(0));
      expect(zekasiSabitKalan, lessThan(statiDegisen),
          reason: 'zekâsı hiç değişmeyen uzun hayat çoğunluk olmamalı');

      // Regresyon koruması: sağlık düşüşü ölüm eğrisini besliyor
      // (Mortality sağlığa bakar). Ortalama ömür makul bandın dışına
      // çıkarsa bu test uyarır; sayı 2026 Türkiye beklentisine yakın
      // durmalıdır.
      final double ortalama =
          olumYaslari.reduce((int a, int b) => a + b) / olumYaslari.length;
      expect(ortalama, greaterThan(70.0), reason: 'ölçülen: $ortalama');
      expect(ortalama, lessThan(85.0), reason: 'ölçülen: $ortalama');
    });
  });
}
