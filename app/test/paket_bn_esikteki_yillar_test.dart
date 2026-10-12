// Paket BN — eşikteki yılların (16-20) içerik ölçümü.
//
// **Ölçülen sorun.** Oyuncunun o yıl gerçekten karşılaşabileceği olay
// sayısı oynanan 40 hayatta yaşa göre ölçüldü: 25'te 67, 30'da 77,
// 40'ta 80 — ama 16'da 41, **18'de 34**, 20'de 44. Çocukluktan sonra en
// ince bant, hayatın en çok şey olan yıllarıydı.
//
// Bu dosya üç şeyi ölçer: bandın gerçekten doldu mu, modül kapalıyken
// tek olay sızıyor mu, ve eşikteki kararların karşılığı yıllar sonra
// okunuyor mu.
// ignore_for_file: avoid_print
library;

import 'dart:math';

import 'package:bir_omur/data/event_pool.dart';
import 'package:bir_omur/data/event_pool_threshold_years.dart';
import 'package:bir_omur/domain/events/event_engine.dart';
import 'package:bir_omur/domain/features/feature_catalog.dart';
import 'package:bir_omur/domain/features/feature_events.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/player_bot.dart';

/// prototypeOnly: ölçülen hayat sayısı.
const int kHayat = 60;

/// Bandın sınırları.
const int kEsikBas = 16;
const int kEsikSon = 20;

Set<String> get _modulKimlikleri =>
    FeatureEvents.idsOf(FeatureId.esiktekiYillar);

void main() {
  group('Paket BN — havuzun yapısı', () {
    test('bütün olaylar ana havuzda ve modüle bağlı', () {
      final Set<String> havuz = kEventPool.map((GameEvent e) => e.id).toSet();
      for (final GameEvent olay in kThresholdYearsEvents) {
        expect(havuz.contains(olay.id), isTrue,
            reason: '${olay.id} ana havuza eklenmemiş.');
        expect(_modulKimlikleri.contains(olay.id), isTrue,
            reason: '${olay.id} modül kapısına bağlı değil.');
      }
      print('Eşikteki yıllar havuzu: ${kThresholdYearsEvents.length} olay.');
    });

    test('16-20 bandının her yaşında yeni olay var', () {
      for (int yas = kEsikBas; yas <= kEsikSon; yas++) {
        final int sayi = kThresholdYearsEvents
            .where((GameEvent e) =>
                e.requirement.minAge <= yas && e.requirement.maxAge >= yas)
            .length;
        expect(sayi, greaterThan(0), reason: '$yas yaşında yeni olay yok.');
      }
    });

    test('bırakılan her iz katalogda okunuyor', () {
      final Set<String> konan = <String>{
        for (final GameEvent e in kThresholdYearsEvents)
          for (final EventChoice c in e.choices) ...c.addFlags,
      };
      final Set<String> aranan = <String>{
        for (final GameEvent e in kEventPool) ...e.requirement.requiredFlags,
        for (final GameEvent e in kEventPool) ...e.requirement.forbiddenFlags,
      };
      final Set<String> sessiz = konan.difference(aranan);
      expect(sessiz, isEmpty,
          reason: 'Karşılığı olmayan iz: ${sessiz.join(", ")}');
      print('Eşikteki yılların izi: ${konan.length} kondu, hepsi okunuyor.');
    });
  });

  group('Paket BN — kapalı modül zarı kaydırmıyor', () {
    test('kapalı modülle, modül hiç yokmuş gibi aynı olay çıkıyor', () {
      final List<GameEvent> modulsuzHavuz = kEventPool
          .where((GameEvent e) => !_modulKimlikleri.contains(e.id))
          .toList(growable: false);
      const EventEngine tamHavuz = EventEngine();
      final EventEngine modulsuz = EventEngine(pool: modulsuzHavuz);

      int karsilastirilan = 0;
      for (int tohum = 0; tohum < 40; tohum++) {
        final GameState temel = LifeGenerator.seeded(tohum)
            .generate(mode: StartMode.tamamenRastgele);
        for (final int yas in <int>[16, 18, 20, 24, 30]) {
          final GameState kapali = temel.copyWith(
            player: temel.player.copyWith(age: yas),
            settings: temel.settings.copyWith(
              features: FeatureSwitches.defaults
                  .toggled(FeatureId.esiktekiYillar, false),
            ),
          );
          final String? a =
              tamHavuz.openingEvent(kapali, Random(tohum * 89 + yas))?.eventId;
          final String? b =
              modulsuz.openingEvent(kapali, Random(tohum * 89 + yas))?.eventId;
          expect(a, b,
              reason: 'tohum $tohum, yaş $yas: kapalı modül zarı kaydırdı');
          karsilastirilan++;
        }
      }
      print('Zar karşılaştırması: $karsilastirilan durum, hepsi aynı.');
    });
  });

  group('Paket BN — oynanan hayatta ölçüm', () {
    test('16-20 bandında uygun olay sayısı arttı', () {
      Map<int, List<int>> olc({required bool modulAcik}) {
        final Map<int, List<int>> sayilar = <int, List<int>>{};
        for (int i = 0; i < kHayat; i++) {
          playBotLife(
            archetype: PlayerArchetype.casual,
            seed: 41000 + i,
            features: modulAcik
                ? FeatureSwitches.defaults
                : FeatureSwitches.defaults
                    .toggled(FeatureId.esiktekiYillar, false),
            onPreAge: (GameState s) {
              final int yas = s.player.age;
              if (yas < kEsikBas || yas > kEsikSon) return;
              const EventEngine motor = EventEngine();
              sayilar.putIfAbsent(yas, () => <int>[]).add(
                    motor.debugEligibleIds(s, Random(yas * 31 + i)).length,
                  );
            },
          );
        }
        return sayilar;
      }

      final Map<int, List<int>> kapali = olc(modulAcik: false);
      final Map<int, List<int>> acik = olc(modulAcik: true);
      double ort(List<int>? l) => (l == null || l.isEmpty)
          ? 0
          : l.reduce((int a, int b) => a + b) / l.length;

      print('Yaş | modül kapalı | modül açık');
      for (int yas = kEsikBas; yas <= kEsikSon; yas++) {
        print('${yas.toString().padLeft(3)} | '
            '${ort(kapali[yas]).toStringAsFixed(1).padLeft(12)} | '
            '${ort(acik[yas]).toStringAsFixed(1).padLeft(10)}');
      }
      for (int yas = kEsikBas; yas <= kEsikSon; yas++) {
        expect(kapali[yas], isNotNull, reason: '$yas yaşı ölçülemedi.');
        expect(ort(acik[yas]), greaterThan(ort(kapali[yas])),
            reason: '$yas yaşında modül aday sayısını artırmadı.');
      }
    });

    test('modül kapalıyken tek olay bile çıkmıyor', () {
      int kapaliGorulen = 0;
      final Set<String> acikGorulen = <String>{};
      const Set<String> karsiliklar = <String>{
        'esik_karsilik_ehliyet',
        'esik_karsilik_usta',
        'esik_karsilik_evden_cikma',
        'esik_karsilik_arkadaslar',
      };

      for (int i = 0; i < kHayat; i++) {
        playBotLife(
          archetype: PlayerArchetype.casual,
          seed: 42000 + i,
          features: FeatureSwitches.defaults
              .toggled(FeatureId.esiktekiYillar, false),
          onYear: (GameState s) {
            kapaliGorulen +=
                s.seenEventIds.where(_modulKimlikleri.contains).length;
          },
        );
        playBotLife(
          archetype: PlayerArchetype.casual,
          seed: 42000 + i,
          onYear: (GameState s) {
            for (final String id in s.seenEventIds) {
              if (_modulKimlikleri.contains(id)) acikGorulen.add(id);
            }
          },
        );
      }

      final int karsilik =
          acikGorulen.where(karsiliklar.contains).length;
      print('Modül kapalı: $kapaliGorulen olay görüldü (0 olmalı).');
      print('Modül açık: $kHayat hayatta ${acikGorulen.length} farklı '
          'eşik olayı, bunların $karsilik tanesi karşılık olayı.');

      expect(kapaliGorulen, 0, reason: 'Kapalı modülün olayı çıktı.');
      expect(acikGorulen.length, greaterThan(10),
          reason: 'Açık modülün olayları hayata hiç girmedi.');
      expect(karsilik, greaterThan(0),
          reason: 'Eşikteki kararların karşılığı hiç okunmadı.');
    });
  });
}
