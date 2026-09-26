import 'dart:math';

import 'package:bir_omur/data/chronic_catalog.dart';
import 'package:bir_omur/data/health_crisis_catalog.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/generation/life_progression.dart';
import 'package:bir_omur/domain/life/chronic_engine.dart';
import 'package:bir_omur/domain/life/health_crisis_engine.dart';
import 'package:bir_omur/domain/life/health_report.dart';
import 'package:bir_omur/domain/models/chronic_condition.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/health_history.dart';
import 'package:bir_omur/domain/models/pending_crisis.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:flutter_test/flutter_test.dart';

/// Paket Y — B grubu: kronik durumlar ve sağlık geçmişi (D-153).
void main() {
  GameState hayat({int seed = 8, int age = 50, int wallet = 900000}) {
    final GameState base =
        LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
    return base.copyWith(
      pendingEvent: null,
      notices: const <PendingNotice>[],
      player: base.player.copyWith(age: age, wallet: wallet),
      movedOut: true,
    );
  }

  GameState kronikli(
    GameState s,
    String typeId, {
    int? startedAtAge,
    int? lastCaredAtAge,
  }) =>
      s.copyWith(
        chronicConditions: <ChronicCondition>[
          ...s.chronicConditions,
          ChronicCondition(
            typeId: typeId,
            startedAtAge: startedAtAge ?? s.player.age - 5,
            lastCaredAtAge: lastCaredAtAge,
          ),
        ],
      );

  group('Katalog (D-153)', () {
    test('kronik kimlikleri benzersiz, sayılar tutarlı', () {
      final List<String> kimlikler =
          kChronicConditions.map((ChronicConditionType t) => t.id).toList();
      expect(kimlikler.toSet(), hasLength(kimlikler.length));
      for (final ChronicConditionType t in kChronicConditions) {
        expect(t.label, isNotEmpty);
        expect(t.description, isNotEmpty);
        expect(t.yearlyHealthDrain, greaterThan(0), reason: t.id);
        // Takip **yönetir**, ortadan kaldırmaz: yönetilen düşüş
        // yönetilmeyenden küçük olmalı ama mutlaka olmalı değil.
        expect(t.managedDrain, lessThan(t.yearlyHealthDrain), reason: t.id);
        expect(t.managedDrain, greaterThanOrEqualTo(0), reason: t.id);
        expect(t.yearlyCareCost, greaterThan(0), reason: t.id);
        expect(t.crisisRiskFactor, greaterThanOrEqualTo(1.0), reason: t.id);
      }
    });

    test('kriz sonrası durumlar gerçek bir krize bağlı', () {
      for (final ChronicConditionType t in kChronicConditions) {
        if (t.origin == ChronicOrigin.krizSonrasi) {
          expect(t.afterCrisisIds, isNotEmpty, reason: t.id);
          for (final String id in t.afterCrisisIds) {
            expect(
              kHealthCrises.any((HealthCrisis c) => c.id == id),
              isTrue,
              reason: '${t.id} olmayan bir krize ($id) bağlanmış',
            );
          }
        } else {
          // Yaşla gelen durumun yaş eşiği olmalı; sıfırdan başlayan
          // "yaşla gelen" durum yanlış olurdu.
          expect(t.onsetMinAge, greaterThan(0), reason: t.id);
        }
      }
    });
  });

  group('Yıllık etki', () {
    test('takip edilmeyen durum her yıl sağlıktan düşürür', () {
      final GameState s = kronikli(hayat(), 'tansiyon');
      final int dusus = ChronicEngine.yearlyDrain(s, s.player.age);
      expect(dusus, chronicTypeById('tansiyon')!.yearlyHealthDrain);
    });

    test('takip edilen durum daha az düşürür', () {
      final GameState s = hayat();
      final GameState takipli =
          kronikli(s, 'kalp_takibi', lastCaredAtAge: s.player.age);
      final GameState takipsiz = kronikli(s, 'kalp_takibi');
      expect(
        ChronicEngine.yearlyDrain(takipli, s.player.age),
        lessThan(ChronicEngine.yearlyDrain(takipsiz, s.player.age)),
      );
    });

    test('yıl ilerleyince sağlık gerçekten düşer', () {
      final GameState s = kronikli(
        hayat().copyWith(
          player: hayat().player.copyWith(age: 50),
        ),
        'kan_sekeri',
      );
      final int once = s.player.stats.health;
      final GameState sonra = ChronicEngine.advanceYear(
        state: s,
        newAge: 51,
        rng: Random(3),
      );
      expect(sonra.player.stats.health, lessThan(once));
    });

    test('geçmiş (bitmiş) durum artık sağlıktan düşürmez', () {
      GameState s = kronikli(hayat(), 'tansiyon');
      s = s.copyWith(
        chronicConditions: s.chronicConditions
            .map((ChronicCondition c) => c.copyWith(endedAtAge: 49))
            .toList(growable: false),
      );
      expect(ChronicEngine.yearlyDrain(s, 50), 0);
      expect(s.activeChronic, isEmpty);
      expect(s.chronicConditions, hasLength(1), reason: 'Kayıt silinmez');
    });

    test('kriz riski yükselir ama tavanı var', () {
      expect(ChronicEngine.crisisRiskFactor(hayat()), 1.0);
      GameState s = kronikli(hayat(), 'kalp_takibi');
      expect(ChronicEngine.crisisRiskFactor(s), greaterThan(1.0));
      s = kronikli(s, 'tansiyon');
      s = kronikli(s, 'kan_sekeri');
      expect(ChronicEngine.crisisRiskFactor(s), lessThanOrEqualTo(2.5));
    });
  });

  group('Takip (bakım)', () {
    test('takip bedeli düşer ve kayıt güncellenir', () {
      final GameState s = kronikli(hayat(), 'kalp_takibi');
      final int once = s.player.wallet;
      final ChronicCareResult r =
          ChronicEngine.care(state: s, typeId: 'kalp_takibi');
      expect(r.outcome.applied, isTrue);
      expect(
        r.state.player.wallet,
        once - chronicTypeById('kalp_takibi')!.yearlyCareCost,
      );
      final ChronicCondition c = r.state.chronicConditions.single;
      expect(c.lastCaredAtAge, s.player.age);
      expect(c.careYears, 1);
      expect(r.state.log.last.text, contains('takibini yaptın'));
    });

    test('aynı yıl ikinci takip yapılamaz', () {
      final GameState s = kronikli(hayat(), 'kalp_takibi');
      final ChronicCareResult ilk =
          ChronicEngine.care(state: s, typeId: 'kalp_takibi');
      final ChronicCareResult ikinci =
          ChronicEngine.care(state: ilk.state, typeId: 'kalp_takibi');
      expect(ikinci.outcome.applied, isFalse);
      expect(ikinci.outcome.text, contains('zaten'));
      expect(ikinci.state.player.wallet, ilk.state.player.wallet);
    });

    test('parası yetmeyen takip edemez ve cüzdan bozulmaz', () {
      final GameState s =
          kronikli(hayat(wallet: 100), 'kalp_takibi');
      final ChronicCareResult r =
          ChronicEngine.care(state: s, typeId: 'kalp_takibi');
      expect(r.outcome.applied, isFalse);
      expect(r.state.player.wallet, 100);
    });

    test('olmayan durumun takibi istenirse hiçbir şey değişmez', () {
      final GameState s = hayat();
      final ChronicCareResult r =
          ChronicEngine.care(state: s, typeId: 'tansiyon');
      expect(r.outcome.applied, isFalse);
      expect(r.state.player.wallet, s.player.wallet);
    });

    test('engel gerekçesi boş metinle bildirilir, null dönmez', () {
      final GameState s = kronikli(hayat(), 'tansiyon');
      final ChronicCondition c = s.chronicConditions.single;
      expect(ChronicEngine.careBlockReason(s, c), isEmpty);
    });
  });

  group('Kriz sonrası iz', () {
    test('atlatılan kriz sağlık geçmişine yazılır', () {
      GameState s = hayat(age: 55);
      s = s.copyWith(
        pendingCrisis: const PendingCrisis(crisisId: 'kalp_uyarisi', age: 55),
      );
      final CrisisResult r = const HealthCrisisEngine()
          .respond(s, 'tedavi', Random(1));
      if (!r.outcome.survived) return; // Atlatamadıysa bu test konusu değil.
      expect(r.state.healthHistory, hasLength(1));
      final HealthHistoryEntry k = r.state.healthHistory.single;
      expect(k.crisisId, 'kalp_uyarisi');
      expect(k.age, 55);
      expect(k.choiceId, 'tedavi');
    });

    test('kalp uyarısı bazen kalıcı bir durum bırakır, bıraktığı doğru tür',
        () {
      int izli = 0;
      int izsiz = 0;
      for (int seed = 0; seed < 300; seed++) {
        GameState s = hayat(age: 55);
        s = s.copyWith(
          pendingCrisis: const PendingCrisis(crisisId: 'kalp_uyarisi', age: 55),
        );
        final CrisisResult r = const HealthCrisisEngine()
            .respond(s, 'tedavi', Random(seed));
        if (!r.outcome.survived) continue;
        if (r.state.activeChronic.isEmpty) {
          izsiz++;
        } else {
          izli++;
          // Kalp uyarısından yalnızca kalp takibi kalabilir.
          expect(r.state.activeChronic.single.typeId, 'kalp_takibi');
          expect(r.state.healthHistory.single.chronicTypeId, 'kalp_takibi');
        }
      }
      expect(izli, greaterThan(0), reason: 'Hiç iz kalmadıysa bağlantı kopuk');
      expect(izsiz, greaterThan(0), reason: 'Her kriz iz bırakmamalı');
    });

    test('aynı durum ikinci kez eklenmez', () {
      GameState s = kronikli(hayat(age: 55), 'kalp_takibi');
      final ({GameState state, String? typeId}) r = ChronicEngine.afterCrisis(
        state: s,
        crisisId: 'kalp_uyarisi',
        age: 55,
        rng: Random(1),
      );
      expect(r.typeId, isNull);
      expect(r.state.chronicConditions, hasLength(1));
    });

    test('en fazla üç süren durum taşınır', () {
      GameState s = hayat(age: 60);
      s = kronikli(s, 'tansiyon');
      s = kronikli(s, 'kan_sekeri');
      s = kronikli(s, 'solunum');
      expect(s.activeChronic, hasLength(ChronicEngine.prototypeOnlyMaxActive));
      final ({GameState state, String? typeId}) r = ChronicEngine.afterCrisis(
        state: s,
        crisisId: 'dusme',
        age: 60,
        rng: Random(1),
      );
      expect(r.typeId, isNull, reason: 'Sınır aşılmamalı');
    });
  });

  group('Yaşla gelen durum', () {
    test('ileri yaşta ortaya çıkıyor, bildirim ve günlük yazılıyor', () {
      int cikan = 0;
      for (int seed = 0; seed < 600 && cikan == 0; seed++) {
        final GameState s = hayat(age: 49);
        final GameState sonra = ChronicEngine.advanceYear(
          state: s,
          newAge: 50,
          rng: Random(seed),
        );
        if (sonra.chronicConditions.isEmpty) continue;
        cikan++;
        final ChronicCondition c = sonra.chronicConditions.single;
        expect(chronicTypeById(c.typeId)!.origin, ChronicOrigin.yasla);
        expect(c.startedAtAge, 50);
        expect(
          sonra.notices.any((PendingNotice n) => n.id.startsWith('kronik-')),
          isTrue,
        );
        expect(sonra.log.last.text, contains('kaydına girdi'));
      }
      expect(cikan, 1, reason: '600 denemede hiç çıkmadıysa bağlantı kopuk');
    });

    test('yaş eşiğinin altında yaşla gelen durum çıkmaz', () {
      for (int seed = 0; seed < 200; seed++) {
        final GameState s = hayat(age: 20);
        final GameState sonra = ChronicEngine.advanceYear(
          state: s,
          newAge: 21,
          rng: Random(seed),
        );
        expect(sonra.chronicConditions, isEmpty);
      }
    });
  });

  group('Kayıt', () {
    test('kronik durum ve sağlık geçmişi kaydedilip geri okunur', () {
      GameState s = kronikli(hayat(), 'kalp_takibi', lastCaredAtAge: 49);
      s = s.copyWith(
        healthHistory: const <HealthHistoryEntry>[
          HealthHistoryEntry(
            crisisId: 'kalp_uyarisi',
            age: 48,
            choiceId: 'tedavi',
            chronicTypeId: 'kalp_takibi',
          ),
        ],
      );
      final GameState geri = decodeGameState(encodeGameState(s));
      expect(geri.chronicConditions, hasLength(1));
      expect(geri.chronicConditions.single.typeId, 'kalp_takibi');
      expect(geri.chronicConditions.single.lastCaredAtAge, 49);
      expect(geri.healthHistory, hasLength(1));
      expect(geri.healthHistory.single.chronicTypeId, 'kalp_takibi');
    });

    test('eski kayıtta bu alanlar yoksa boş okunur, kayıt bozulmaz', () {
      final Map<String, Object?> json = encodeGameState(hayat());
      json.remove('chronicConditions');
      json.remove('healthHistory');
      final GameState geri = decodeGameState(json);
      expect(geri.chronicConditions, isEmpty);
      expect(geri.healthHistory, isEmpty);
    });
  });

  group('Yıl akışına bağlı', () {
    test('bir ömür boyunca kronik durum gerçekten yaşanıyor', () {
      int kronikGoren = 0;
      for (int seed = 0; seed < 40; seed++) {
        GameState s = hayat(seed: seed, age: 30);
        final LifeProgression motor = LifeProgression(Random(seed + 500));
        for (int i = 0; i < 50 && !s.deceased; i++) {
          s = motor.advanceOneYear(s);
          s = s.copyWith(
            pendingEvent: null,
            pendingCrisis: null,
            notices: const <PendingNotice>[],
          );
        }
        if (s.chronicConditions.isNotEmpty) kronikGoren++;
      }
      expect(
        kronikGoren,
        greaterThan(0),
        reason: '40 hayatta hiç kronik durum çıkmadıysa bağlantı kopuk',
      );
    });
  });

  group('Check-up raporu kronik durumu görüyor', () {
    test('her kronik durumun rapor satırı gerçekten raporda var', () {
      final Set<String> satirlar = HealthChecks.checkup(hayat())
          .lines
          .map((HealthLine l) => l.system)
          .toSet();
      for (final ChronicConditionType t in kChronicConditions) {
        expect(
          satirlar,
          contains(t.reportSystem),
          reason: '${t.id} olmayan bir rapor satırına bağlanmış',
        );
      }
    });

    test('taşınan durum ilgili satırı aşağı çeker', () {
      final GameState saglikli = hayat(age: 45).copyWith(
        player: hayat(age: 45).player.copyWith(
              stats: hayat().player.stats.gain(health: 100),
            ),
      );
      final GameState kalpli = kronikli(saglikli, 'kalp_takibi');

      OrganStatus durum(GameState s, String sistem) => HealthChecks.checkup(s)
          .lines
          .firstWhere((HealthLine l) => l.system == sistem)
          .status;

      expect(
        durum(kalpli, 'Kalp ve tansiyon').index,
        greaterThan(durum(saglikli, 'Kalp ve tansiyon').index),
        reason: 'Kalp rahatsızlığı kalp satırını etkilemedi',
      );
      // Alakasız satır etkilenmez.
      expect(
        durum(kalpli, 'Görme'),
        durum(saglikli, 'Görme'),
      );
    });

    test('takip edilen durumun etkisi daha az', () {
      final GameState s = hayat(age: 45);
      final GameState takipsiz = kronikli(s, 'kalp_takibi');
      final GameState takipli =
          kronikli(s, 'kalp_takibi', lastCaredAtAge: s.player.age);
      expect(
        HealthChecks.prototypeOnlyManagedChronicPenalty,
        lessThan(HealthChecks.prototypeOnlyChronicPenalty),
      );
      final int takipsizIndex = HealthChecks.checkup(takipsiz)
          .lines
          .firstWhere((HealthLine l) => l.system == 'Kalp ve tansiyon')
          .status
          .index;
      final int takipliIndex = HealthChecks.checkup(takipli)
          .lines
          .firstWhere((HealthLine l) => l.system == 'Kalp ve tansiyon')
          .status
          .index;
      expect(takipliIndex, lessThanOrEqualTo(takipsizIndex));
    });
  });
}
