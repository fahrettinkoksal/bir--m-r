import 'dart:math';

import 'package:bir_omur/data/activity_catalog.dart';
import 'package:bir_omur/domain/activities/activity_engine.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/life/hair_loss.dart';
import 'package:bir_omur/domain/life/sick_leave.dart';
import 'package:bir_omur/domain/life/upkeep_tracker.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/activities/martial_arts_engine.dart';
import 'package:bir_omur/data/martial_arts_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

/// Paket J: statlar gerçekten hissedilsin (D-099 … D-102).
void main() {
  GameState hayat({int seed = 11, int age = 30}) {
    final GameState base =
        LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
    return base.copyWith(
      pendingEvent: null,
      player: base.player.copyWith(age: age, wallet: 500000),
    );
  }

  group('Sağlık Merkezi yıllık sağlık kazancı (D-100)', () {
    test('tek yılda kazanılan toplam sağlık sınırı aşmaz', () {
      GameState s = hayat(age: 30).copyWith(
        player: hayat(age: 30).player.copyWith(
              stats: hayat(age: 30).player.stats.copyWith(health: 50),
            ),
      );
      final int once = s.player.stats.health;

      const ActivityEngine motor = ActivityEngine();
      for (final ActivityAction a in kActivityActions.where(
        (ActivityAction a) => a.venue == ActivityVenue.saglikMerkezi,
      )) {
        for (int i = 0; i < 3; i++) {
          final ActivityResult r = motor.perform(
            state: s,
            action: a,
            rng: Random(7),
          );
          if (r.outcome.applied) s = r.state;
        }
      }

      final int kazanc = s.player.stats.health - once;
      // ignore: avoid_print
      print('SAGLIK MERKEZI bir yilda: +$kazanc saglik');
      expect(
        kazanc,
        lessThanOrEqualTo(
          ActivityEngine.prototypeOnlyHealthCentreYearlyCap,
        ),
      );
      expect(kazanc, greaterThan(0), reason: 'Kapı tamamen kapanmamalı');
    });

    test('yeni yaşta hak yenilenir', () {
      GameState s = hayat(age: 30).copyWith(
        player: hayat(age: 30).player.copyWith(
              stats: hayat(age: 30).player.stats.copyWith(health: 50),
            ),
      );
      const ActivityEngine motor = ActivityEngine();
      final ActivityAction kontrol = kActivityActions
          .firstWhere((ActivityAction a) => a.id == 'genel_kontrol');

      s = motor.perform(state: s, action: kontrol, rng: Random(1)).state;
      final int ilkYil = s.player.stats.health;

      // Yaş değişince sayaçlar sıfırlanır (gerçek akışın yaptığı gibi).
      s = s.copyWith(
        player: s.player.copyWith(age: s.player.age + 1),
        interactionCounts: const <String, int>{},
      );
      s = motor.perform(state: s, action: kontrol, rng: Random(1)).state;
      expect(s.player.stats.health, greaterThan(ilkYil));
    });
  });

  group('Hastalık sağlığı düşürür (D-101)', () {
    test('rapor alan karakterin sağlığı gerçekten düşer', () {
      bool hastalikGoruldu = false;
      for (int seed = 0; seed < 40 && !hastalikGoruldu; seed++) {
        final SickLeave h = SickLeaves.roll(
          age: 40,
          health: 70,
          yearsSinceSport: null,
          yearlySalary: 900000,
          previousWarnings: 0,
          rng: Random(seed),
        );
        if (!h.happened) continue;
        hastalikGoruldu = true;
        expect(h.healthDelta, lessThan(0));
      }
      expect(hastalikGoruldu, isTrue);
    });

    test('uzun rapor kısa rapordan daha çok yıpratır', () {
      final List<int> kisa = <int>[];
      final List<int> uzun = <int>[];
      for (int seed = 0; seed < 200; seed++) {
        final SickLeave h = SickLeaves.roll(
          age: 40,
          health: 70,
          yearsSinceSport: null,
          yearlySalary: 900000,
          previousWarnings: 0,
          rng: Random(seed),
        );
        if (!h.happened) continue;
        (h.days >= SickLeaves.prototypeOnlyUpsetDays ? uzun : kisa)
            .add(-h.healthDelta);
      }
      expect(kisa, isNotEmpty);
      expect(uzun, isNotEmpty);
      expect(uzun.reduce(max), greaterThan(kisa.reduce(min)));
    });

    test('sağlığı zayıf olan daha çok yıpranır', () {
      SickLeave? saglam;
      SickLeave? zayif;
      for (int seed = 0; seed < 200 && (saglam == null || zayif == null); seed++) {
        final SickLeave a = SickLeaves.roll(
          age: 40,
          health: 80,
          yearsSinceSport: null,
          yearlySalary: null,
          previousWarnings: 0,
          rng: Random(seed),
        );
        final SickLeave b = SickLeaves.roll(
          age: 40,
          health: 20,
          yearsSinceSport: null,
          yearlySalary: null,
          previousWarnings: 0,
          rng: Random(seed),
        );
        if (a.happened && b.happened && a.days == b.days) {
          saglam = a;
          zayif = b;
        }
      }
      expect(saglam, isNotNull);
      expect(zayif!.healthDelta, lessThan(saglam!.healthDelta));
    });
  });

  test('dövüş dersi spor bakımına sayılır (Q-116 kararı)', () {
    final GameState s = hayat(age: 25).copyWith(lastSportAge: null);
    expect(s.yearsSinceSport, isNull);

    final MartialArt sanat = MartialArt.values.first;
    final ActivityResult r = const MartialArtsEngine().takeLesson(
      state: s,
      art: sanat,
    );
    expect(r.outcome.applied, isTrue, reason: r.outcome.text);
    expect(
      UpkeepTracker.statusOf(r.state).yearsSinceSport,
      0,
      reason: 'Dövüş dersi spor sayılmalı.',
    );
  });

  group('Saç dökülmesi (Q-117 kararı)', () {
    test('karizmayı etkilemez, yalnızca görünüşü etkiler', () {
      for (final int basamak in HairLoss.prototypeOnlyCharismaCost) {
        expect(basamak, 0);
      }
      expect(HairLoss.prototypeOnlyAppearanceCost.last, greaterThan(0));
    });

    test('adım karizma değişimi üretmez', () {
      for (int seed = 0; seed < 200; seed++) {
        final HairLossStep adim = HairLoss.step(
          gender: Gender.erkek,
          age: 45,
          stage: 1,
          groomedRecently: false,
          rng: Random(seed),
        );
        expect(adim.charisma, 0);
      }
    });
  });

  test('saç ekimi ileri basamakta iki kademe düşürür', () {
    const ActivityEngine motor = ActivityEngine();
    final ActivityAction ekim = kActivityActions
        .firstWhere((ActivityAction a) => a.reducesHairLoss);

    for (final int basamak in <int>[1, 2, 3]) {
      GameState s = hayat(age: 40).copyWith(
        player: hayat(age: 40).player.copyWith(hairLossStage: basamak),
      );
      // Başarısız işlem basamağı düşürmez; başarılı olana kadar denenir.
      int? sonuc;
      for (int seed = 0; seed < 50; seed++) {
        final ActivityResult r = motor.perform(
          state: s,
          action: ekim,
          rng: Random(seed),
        );
        if (!r.outcome.applied) continue;
        if (r.state.player.hairLossStage < basamak) {
          sonuc = r.state.player.hairLossStage;
          break;
        }
        s = s.copyWith(interactionCounts: const <String, int>{});
      }
      expect(sonuc, isNotNull, reason: 'Basamak $basamak düşürülemedi');
      expect(basamak - sonuc!, basamak >= 2 ? 2 : 1);
    }
  });
}
