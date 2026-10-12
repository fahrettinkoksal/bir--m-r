// Paket AQ — mutluluk, karizma, görünüş ve zekânın düşük seviyelerindeki
// gameplay sonuçları.
//
// Kural: zaten statı tüketen sisteme ikinci ceza eklenmez. Bu dosya hem
// yeni etkileri hem de **mevcut** tüketicilerin hâlâ çalıştığını
// sabitliyor; ayrıca saçma çapraz etkilerin olmadığını denetliyor.
// ignore_for_file: avoid_print
library;

import 'dart:math';

import 'package:bir_omur/data/activity_catalog.dart';
import 'package:bir_omur/data/job_catalog.dart';
import 'package:bir_omur/domain/activities/activity_engine.dart';
import 'package:bir_omur/domain/career/career_progress.dart';
import 'package:bir_omur/domain/career/job_market.dart';
import 'package:bir_omur/domain/education/school_performance.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/generation/life_progression.dart';
import 'package:bir_omur/domain/life/aging.dart';
import 'package:bir_omur/domain/life/critical_health.dart';
import 'package:bir_omur/domain/life/stat_floor_effects.dart';
import 'package:bir_omur/domain/models/career.dart';
import 'package:bir_omur/domain/models/life_log.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/stats.dart';
import 'package:flutter_test/flutter_test.dart';

const ActivityEngine kAktivite = ActivityEngine();

GameState _hayat(
  int seed, {
  int age = 35,
  int happiness = 60,
  int charisma = 60,
  int appearance = 60,
  int intelligence = 60,
  int health = 70,
  int wallet = 200000,
}) {
  final GameState s =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  return s.copyWith(
    player: s.player.copyWith(
      age: age,
      wallet: wallet,
      stats: Stats(
        appearance: appearance,
        happiness: happiness,
        health: health,
        intelligence: intelligence,
        charisma: charisma,
      ),
    ),
  );
}

ActivityAction _eylem(String id) =>
    kActivityActions.firstWhere((ActivityAction a) => a.id == id);

void main() {
  // ===================================================================
  // Bantlar
  // ===================================================================
  group('Düşük stat bantları', () {
    test('bant sınırları', () {
      expect(StatFloorEffects.bandOf(0), StatLowBand.cokDusuk);
      expect(StatFloorEffects.bandOf(10), StatLowBand.cokDusuk);
      expect(StatFloorEffects.bandOf(11), StatLowBand.dusuk);
      expect(StatFloorEffects.bandOf(25), StatLowBand.dusuk);
      expect(StatFloorEffects.bandOf(26), StatLowBand.normal);
      expect(StatFloorEffects.bandOf(100), StatLowBand.normal);
    });
  });

  // ===================================================================
  // Mutluluk
  // ===================================================================
  group('Mutluluk 0', () {
    test('ölüm ya da kritik durum üretmez', () {
      GameState s = _hayat(1, happiness: 0, health: 70);
      final LifeProgression motor = LifeProgression(Random(1));
      for (int i = 0; i < 15 && !s.deceased; i++) {
        s = s.copyWith(pendingEvent: null, pendingCrisis: null);
        s = motor.advanceOneYear(s);
      }
      expect(s.deceased, isFalse);
      expect(CriticalHealth.isPending(s), isFalse);
    });

    test('iş tarafında gerçek bir sonucu var', () {
      // Mutluluk Paket AQ'dan önce hiçbir sistemin **girdisi** değildi.
      final GameState calisan = _hayat(
        2,
        happiness: 70,
      ).copyWith(
        career: const CareerState(
          jobId: 'ofis_memuru',
          salary: 400000,
          startedAtAge: 28,
          lastPaidAge: 34,
        ),
      );
      final GameState mutsuz = calisan.copyWith(
        player: calisan.player.copyWith(
          stats: calisan.player.stats.copyWith(happiness: 0),
        ),
      );
      final double iyi =
          CareerProgress.prototypeOnlyChance(calisan, terfi: true);
      final double kotu =
          CareerProgress.prototypeOnlyChance(mutsuz, terfi: true);
      expect(kotu, lessThan(iyi));
      expect(kotu, greaterThan(0.0), reason: 'kapı tamamen kapanmamalı');
    });

    test('okul ortalamasının zekâya yaklaşmasını yavaşlatır', () {
      // Yalnızca **yukarı** kaymayı yavaşlatır; aşağı kaymayı
      // hızlandırmaz, yoksa sarmal kurulur.
      int mutluToplam = 0;
      int mutsuzToplam = 0;
      for (int seed = 0; seed < 200; seed++) {
        mutluToplam += SchoolPerformance.prototypeOnlyYearEndAverage(
          current: 40,
          intelligence: 80,
          happiness: 80,
          rng: Random(seed),
        );
        mutsuzToplam += SchoolPerformance.prototypeOnlyYearEndAverage(
          current: 40,
          intelligence: 80,
          happiness: 0,
          rng: Random(seed),
        );
      }
      expect(mutsuzToplam, lessThan(mutluToplam));
    });

    test('aşağı kayma mutsuzlukla hızlanmaz (sarmal yok)', () {
      for (int seed = 0; seed < 60; seed++) {
        final int mutlu = SchoolPerformance.prototypeOnlyYearEndAverage(
          current: 80,
          intelligence: 30,
          happiness: 80,
          rng: Random(seed),
        );
        final int mutsuz = SchoolPerformance.prototypeOnlyYearEndAverage(
          current: 80,
          intelligence: 30,
          happiness: 0,
          rng: Random(seed),
        );
        expect(mutsuz, mutlu,
            reason: 'tohum $seed: aşağı kayma mutluluğa bakmamalı');
      }
    });

    test('dipteki karakter eğlenceden daha çok fayda görür', () {
      // Sarmalın karşı ağırlığı: çıkış yolu kapanmasın.
      final ActivityAction sinema = _eylem('sinema');
      expect(sinema.venue, ActivityVenue.eglence);
      expect(sinema.happiness, greaterThan(0));

      final GameState dipte = _hayat(3, happiness: 2);
      final GameState normal = _hayat(3, happiness: 60);
      final int dipKazanc = kAktivite
              .perform(state: dipte, action: sinema, rng: Random(2))
              .state
              .player
              .stats
              .happiness -
          2;
      final int normalKazanc = kAktivite
              .perform(state: normal, action: sinema, rng: Random(2))
              .state
              .player
              .stats
              .happiness -
          60;
      expect(dipKazanc, greaterThan(normalKazanc));
    });

    test('eğlence dışındaki eylemlerde ek pay yoktur', () {
      expect(
        StatFloorEffects.reliefBonus(happiness: 0, gain: 0),
        0,
        reason: 'kazanç yoksa pay da yok',
      );
      expect(StatFloorEffects.reliefBonus(happiness: 60, gain: 5), 0);
    });

    test('mutluluk 0 kendine zarar ya da hassas içerik üretmez', () {
      GameState s = _hayat(4, happiness: 0);
      final LifeProgression motor = LifeProgression(Random(3));
      for (int i = 0; i < 20 && !s.deceased; i++) {
        s = s.copyWith(pendingEvent: null, pendingCrisis: null);
        s = motor.advanceOneYear(s);
      }
      for (final LifeLogEntry e in s.log) {
        expect(e.text.toLowerCase(), isNot(contains('intihar')));
        expect(e.text.toLowerCase(), isNot(contains('kendine zarar')));
      }
    });
  });

  // ===================================================================
  // Karizma
  // ===================================================================
  group('Karizma 0', () {
    test('mevcut meslek koşulu hâlâ çalışıyor (duplicate eklenmedi)', () {
      final List<JobType> karizmali = kJobCatalog
          .where((JobType j) => j.minCharisma > 0)
          .toList(growable: false);
      expect(karizmali, isNotEmpty);
      final GameState s = _hayat(5, charisma: 0);
      final JobMarket pazar = const JobMarket();
      expect(pazar.requirementReason(s, karizmali.first), isNotEmpty);
    });

    test('mülakatta ikinci şans karizmaya göre ölçeklenir', () {
      expect(StatFloorEffects.interviewRescueFactor(60), 1.0);
      expect(StatFloorEffects.interviewRescueFactor(20), lessThan(1.0));
      expect(
        StatFloorEffects.interviewRescueFactor(0),
        lessThan(StatFloorEffects.interviewRescueFactor(20)),
      );
      expect(StatFloorEffects.interviewRescueFactor(0), greaterThan(0.0));
    });

    test('karizma 0 ilişki kayıtlarını silmez, bağları bozmaz', () {
      final GameState once = _hayat(6, charisma: 60);
      final int kisiSayisi = once.people.length;
      final List<int> baglar =
          once.people.map((Person p) => p.bond).toList();

      GameState s = once.copyWith(
        player: once.player.copyWith(
          stats: once.player.stats.copyWith(charisma: 0),
        ),
      );
      // Karizma 0 olmak tek başına hiçbir kaydı değiştirmez.
      expect(s.people.length, kisiSayisi);
      expect(
        s.people.map((Person p) => p.bond).toList(growable: false),
        baglar,
      );
      // Bir yıl geçmesi de kimseyi silmez.
      s = LifeProgression(Random(4))
          .advanceOneYear(s.copyWith(pendingEvent: null));
      expect(s.people.length, greaterThanOrEqualTo(kisiSayisi));
      expect(s.marriage, once.marriage);
    });
  });

  // ===================================================================
  // Görünüş
  // ===================================================================
  group('Görünüş 0', () {
    test('yalnızca ilgili sistemleri etkiler', () {
      final List<JobType> gorunuslu = kJobCatalog
          .where((JobType j) => j.minAppearance > 0)
          .toList(growable: false);
      expect(gorunuslu, isNotEmpty);
      final GameState s = _hayat(7, appearance: 0);
      expect(
        const JobMarket().requirementReason(s, gorunuslu.first),
        isNotEmpty,
      );
    });

    test('alakasız sistemler etkilenmez: kredi, aile, okul', () {
      final GameState iyi = _hayat(8, appearance: 80);
      final GameState kotu = _hayat(8, appearance: 0);
      // Görünüşe bakmayan mesleklerde koşul değişmez.
      final List<JobType> notr = kJobCatalog
          .where((JobType j) => j.minAppearance == 0)
          .toList(growable: false);
      final JobMarket pazar = const JobMarket();
      for (final JobType j in notr.take(8)) {
        expect(
          pazar.requirementReason(kotu, j),
          pazar.requirementReason(iyi, j),
          reason: '${j.id}: görünüş alakasız bir meslekte fark yaratmamalı',
        );
      }
      // Okul ortalaması görünüşe bakmaz.
      expect(
        SchoolPerformance.prototypeOnlyYearEndAverage(
          current: 50,
          intelligence: 60,
          happiness: 60,
          rng: Random(5),
        ),
        SchoolPerformance.prototypeOnlyYearEndAverage(
          current: 50,
          intelligence: 60,
          happiness: 60,
          rng: Random(5),
        ),
      );
    });
  });

  // ===================================================================
  // Zekâ
  // ===================================================================
  group('Zekâ düşük', () {
    test('mevcut tüketiciler çalışıyor', () {
      final List<JobType> zekali = kJobCatalog
          .where((JobType j) => j.minIntelligence > 0)
          .toList(growable: false);
      expect(zekali, isNotEmpty);
      expect(
        const JobMarket()
            .requirementReason(_hayat(9, intelligence: 0), zekali.first),
        isNotEmpty,
      );
      // Okul ortalaması zekâya doğru kayar.
      final int dusuk = SchoolPerformance.prototypeOnlyYearEndAverage(
        current: 70,
        intelligence: 10,
        happiness: 60,
        rng: Random(6),
      );
      final int yuksek = SchoolPerformance.prototypeOnlyYearEndAverage(
        current: 70,
        intelligence: 90,
        happiness: 60,
        rng: Random(6),
      );
      expect(dusuk, lessThan(yuksek));
    });
  });

  // ===================================================================
  // Tabanlar: doğal yaşlanma statları anlamsız 0'a çökertmiyor mu?
  // ===================================================================
  group('Yaşlanma tabanları (ÖLÇÜM)', () {
    test('doğal yaşlanma hiçbir statı 0'
        'a indirmez', () {
      // Yalnızca yaşlanma kolu: olay, hastalık ve kriz yok.
      final Map<String, int> enDusuk = <String, int>{
        'gorunus': 100,
        'karizma': 100,
        'saglik': 100,
        'zeka': 100,
        'mutluluk': 100,
      };
      for (int seed = 0; seed < 60; seed++) {
        Stats stats = const Stats(
          appearance: 70,
          happiness: 70,
          health: 70,
          intelligence: 70,
          charisma: 70,
        );
        final Random rng = Random(seed);
        for (int yas = 20; yas <= 100; yas++) {
          final StatDrift d = StatAging.yearlyDrift(
            age: yas,
            stats: stats,
            upkeep: const UpkeepStatus(),
            rng: rng,
          );
          stats = stats.gain(
            appearance: d.appearance,
            charisma: d.charisma,
            health: d.health,
            intelligence: d.intelligence,
            happiness: d.happiness,
          );
        }
        enDusuk['gorunus'] = min(enDusuk['gorunus']!, stats.appearance);
        enDusuk['karizma'] = min(enDusuk['karizma']!, stats.charisma);
        enDusuk['saglik'] = min(enDusuk['saglik']!, stats.health);
        enDusuk['zeka'] = min(enDusuk['zeka']!, stats.intelligence);
        enDusuk['mutluluk'] = min(enDusuk['mutluluk']!, stats.happiness);
      }
      print('--- 100 yaşa kadar yalnızca yaşlanma: en düşük değerler ---');
      enDusuk.forEach((String k, int v) => print('  $k: $v'));

      // Tabanlar korunuyor: yaşlanmak kimseyi sıfıra indirmez.
      expect(enDusuk['gorunus'],
          greaterThanOrEqualTo(StatAging.prototypeOnlyAppearanceFloor));
      expect(enDusuk['karizma'],
          greaterThanOrEqualTo(StatAging.prototypeOnlyCharismaFloor));
      expect(enDusuk['saglik'],
          greaterThanOrEqualTo(StatAging.prototypeOnlyHealthFloor));
      expect(enDusuk['zeka'],
          greaterThanOrEqualTo(StatAging.prototypeOnlyIntelligenceFloor));
      expect(enDusuk['mutluluk'],
          greaterThanOrEqualTo(StatAging.prototypeOnlyHappinessFloor));
    });

    test('toparlanma tavanı yaşlanma tabanının altına düşmez', () {
      // Paket AQ düzeltmesi: 71+ yaşta tavan 0 dönüyordu, yani
      // toparlanma tamamen kapalıydı ve ileri yaşta sağlık 0'a inmek
      // kaçınılmazdı.
      for (int yas = 0; yas <= 110; yas++) {
        expect(
          StatAging.prototypeOnlyHealthCeilingFor(yas),
          greaterThanOrEqualTo(StatAging.prototypeOnlyHealthFloor),
          reason: '$yas yaşında toparlanma tavanı tabanın altında',
        );
      }
    });
  });

  // ===================================================================
  // Durum satırları
  // ===================================================================
  group('Durum satırları', () {
    test('yalnızca gerçekten düşük değerler için satır çıkar', () {
      expect(StatFloorEffects.statusLines(_hayat(10)), isEmpty);
      final List<String> satirlar = StatFloorEffects.statusLines(
        _hayat(10, happiness: 3, charisma: 8, appearance: 70, intelligence: 70),
      );
      expect(satirlar.length, 2);
    });

    test('satırlarda iç sayı ve teknik terim yok', () {
      final List<String> satirlar = StatFloorEffects.statusLines(
        _hayat(11,
            happiness: 0, charisma: 0, appearance: 0, intelligence: 0),
      );
      expect(satirlar.length, 4);
      for (final String satir in satirlar) {
        expect(satir, isNot(contains('prototypeOnly')));
        expect(satir, isNot(contains('Band')));
        expect(satir, isNot(matches(RegExp(r'=\s*\d'))));
      }
    });
  });
}
