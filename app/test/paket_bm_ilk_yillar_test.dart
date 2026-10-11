// Paket BM — ilk yılların içerik ölçümü.
//
// **Ölçülen sorun.** Katalogda yaş aralığı yazılı olaylar yaşa göre
// tarandığında ilk yıllar bomboştu: 0 yaşında 3, 1 yaşında 9, 3 yaşında
// 16 aday olay; 25 yaşında 194. Her yeni hayat 0 yaşında başlıyor,
// yani oyunun ilk izlenimi en dar havuzdan geliyordu.
//
// Bu dosya üç şeyi ölçer:
//   1. Modül açıkken ilk yılların aday olay sayısı gerçekten arttı mı
//      (motorun kendi uygunluk hesabıyla, oynanan hayatın içinde)?
//   2. Modül kapalıyken tek bir olayı bile sızıyor mu?
//   3. İlk yılların izleri sonradan **okunuyor** mu — yani karşılığı
//      olmayan sessiz iz bırakmadık mı?
// ignore_for_file: avoid_print
library;

import 'dart:math';

import 'package:bir_omur/data/event_pool.dart';
import 'package:bir_omur/data/event_pool_early_years.dart';
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

/// İlk yılların bandı: oyuncunun okula başlamadan önceki dokunuşları.
const int kIlkYilSonu = 7;

Set<String> get _modulKimlikleri =>
    FeatureEvents.idsOf(FeatureId.ilkYillarOlaylari);

void main() {
  group('Paket BM — havuzun yapısı', () {
    test('bütün olaylar ana havuzda ve modüle bağlı', () {
      final Set<String> havuz =
          kEventPool.map((GameEvent e) => e.id).toSet();
      for (final GameEvent olay in kEarlyYearsEvents) {
        expect(havuz.contains(olay.id), isTrue,
            reason: '${olay.id} ana havuza eklenmemiş.');
        expect(_modulKimlikleri.contains(olay.id), isTrue,
            reason: '${olay.id} modül kapısına bağlı değil.');
      }
      print('İlk yıllar havuzu: ${kEarlyYearsEvents.length} olay.');
    });

    test('her yaş için 0-7 bandında olay var', () {
      for (int yas = 0; yas <= kIlkYilSonu; yas++) {
        final int sayi = kEarlyYearsEvents
            .where((GameEvent e) =>
                e.requirement.minAge <= yas && e.requirement.maxAge >= yas)
            .length;
        expect(sayi, greaterThan(0), reason: '$yas yaşında yeni olay yok.');
      }
    });

    test('bırakılan her iz katalogda okunuyor', () {
      // Paket AR'nin ölçtüğü hata: iz konur, hiçbir olay onu aramaz.
      final Set<String> konan = <String>{
        for (final GameEvent e in kEarlyYearsEvents)
          for (final EventChoice c in e.choices) ...c.addFlags,
      };
      final Set<String> aranan = <String>{
        for (final GameEvent e in kEventPool) ...e.requirement.requiredFlags,
        for (final GameEvent e in kEventPool) ...e.requirement.forbiddenFlags,
      };
      final Set<String> sessiz = konan.difference(aranan);
      expect(sessiz, isEmpty,
          reason: 'Karşılığı olmayan iz: ${sessiz.join(", ")}');
      print('İlk yılların izi: ${konan.length} kondu, hepsi okunuyor.');
    });
  });

  group('Paket BM — kapalı modül zarı kaydırmıyor', () {
    test('kapalı modülle, modül hiç yokmuş gibi aynı olay çıkıyor', () {
      // **Ölçülen hata.** Modül kapısı ilk hâlinde `_matches` içindeydi,
      // yani kişi çözümünden **sonra**. Kişi çözümü `rng` tüketiyor;
      // dolayısıyla kapalı modülün olayları bile oyunun zarını
      // kaydırıyordu: hepsi kapalı 100 hayatta ortalama ömür 70,4'ten
      // 72,1'e çıkmıştı. Kapı artık zardan önce.
      //
      // Bu test iki motoru karşılaştırır: (a) tam havuz + modül kapalı,
      // (b) modülün olayları havuzda hiç yok. İkisi aynı tohumda aynı
      // olayı vermek zorunda.
      final List<GameEvent> modulsuzHavuz = kEventPool
          .where((GameEvent e) => !_modulKimlikleri.contains(e.id))
          .toList(growable: false);
      const EventEngine tamHavuz = EventEngine();
      final EventEngine modulsuz = EventEngine(pool: modulsuzHavuz);

      int karsilastirilan = 0;
      for (int tohum = 0; tohum < 40; tohum++) {
        final GameState temel = LifeGenerator.seeded(tohum)
            .generate(mode: StartMode.tamamenRastgele);
        for (final int yas in <int>[0, 2, 4, 6, 9, 14]) {
          final GameState kapali = temel.copyWith(
            player: temel.player.copyWith(age: yas),
            settings: temel.settings.copyWith(
              features: FeatureSwitches.defaults
                  .toggled(FeatureId.ilkYillarOlaylari, false),
            ),
          );
          final String? a =
              tamHavuz.openingEvent(kapali, Random(tohum * 97 + yas))?.eventId;
          final String? b =
              modulsuz.openingEvent(kapali, Random(tohum * 97 + yas))?.eventId;
          expect(a, b,
              reason: 'tohum $tohum, yaş $yas: kapalı modül zarı kaydırdı');
          karsilastirilan++;
        }
      }
      print('Zar karşılaştırması: $karsilastirilan durum, hepsi aynı.');
    });
  });

  group('Paket BM — oynanan hayatta ölçüm', () {
    test('ilk yılların aday olay sayısı arttı', () {
      // Motorun kendi uygunluk hesabı, gerçek hayatın içinde: her yaşta
      // "şu an çıkabilecek" olay sayısı.
      Map<int, List<int>> olc({required bool modulAcik}) {
        final Map<int, List<int>> sayilar = <int, List<int>>{};
        for (int i = 0; i < kHayat; i++) {
          playBotLife(
            archetype: PlayerArchetype.casual,
            seed: 21000 + i,
            features: modulAcik
                ? FeatureSwitches.defaults
                : FeatureSwitches.defaults
                    .toggled(FeatureId.ilkYillarOlaylari, false),
            onPreAge: (GameState s) {
              final int yas = s.player.age;
              if (yas > kIlkYilSonu) return;
              const EventEngine motor = EventEngine();
              final int aday =
                  motor.debugEligibleIds(s, Random(yas * 31 + i)).length;
              sayilar.putIfAbsent(yas, () => <int>[]).add(aday);
            },
          );
        }
        return sayilar;
      }

      final Map<int, List<int>> kapali = olc(modulAcik: false);
      final Map<int, List<int>> acik = olc(modulAcik: true);

      double ort(List<int>? l) =>
          (l == null || l.isEmpty) ? 0 : l.reduce((int a, int b) => a + b) / l.length;

      print('Yaş | modül kapalı | modül açık');
      for (int yas = 0; yas <= kIlkYilSonu; yas++) {
        print('${yas.toString().padLeft(3)} | '
            '${ort(kapali[yas]).toStringAsFixed(1).padLeft(12)} | '
            '${ort(acik[yas]).toStringAsFixed(1).padLeft(10)}');
      }

      for (int yas = 0; yas <= kIlkYilSonu; yas++) {
        expect(kapali[yas], isNotNull, reason: '$yas yaşı ölçülemedi.');
        expect(
          ort(acik[yas]),
          greaterThan(ort(kapali[yas])),
          reason: '$yas yaşında modül aday sayısını artırmadı.',
        );
      }
      // En dar yaş en çok kazanmalı: 0 yaşında aday sayısı en az iki kat.
      expect(
        ort(acik[0]),
        greaterThanOrEqualTo(ort(kapali[0]) * 2),
        reason: '0 yaşı hâlâ dar.',
      );
    });

    test('modül kapalıyken tek olay bile çıkmıyor', () {
      int kapaliGorulen = 0;
      int acikGorulen = 0;
      int acikKarsilik = 0;
      final Set<String> gorulenKimlikler = <String>{};
      final Set<String> karsilikKimlikleri = <String>{
        'ilk_yil_karsilik_bisiklet',
        'ilk_yil_karsilik_kumbara',
        'ilk_yil_karsilik_harfler',
        'ilk_yil_karsilik_sokak',
      };

      for (int i = 0; i < kHayat; i++) {
        playBotLife(
          archetype: PlayerArchetype.casual,
          seed: 22000 + i,
          features: FeatureSwitches.defaults
              .toggled(FeatureId.ilkYillarOlaylari, false),
          onYear: (GameState s) {
            kapaliGorulen +=
                s.seenEventIds.where(_modulKimlikleri.contains).length;
          },
        );
        playBotLife(
          archetype: PlayerArchetype.casual,
          seed: 22000 + i,
          onYear: (GameState s) {
            for (final String id in s.seenEventIds) {
              if (_modulKimlikleri.contains(id)) gorulenKimlikler.add(id);
            }
          },
        );
      }
      acikGorulen = gorulenKimlikler.length;
      acikKarsilik =
          gorulenKimlikler.where(karsilikKimlikleri.contains).length;

      print('Modül kapalı: $kapaliGorulen olay görüldü (0 olmalı).');
      print('Modül açık: $kHayat hayatta $acikGorulen farklı ilk yıl '
          'olayı, bunların $acikKarsilik tanesi karşılık olayı.');

      expect(kapaliGorulen, 0, reason: 'Kapalı modülün olayı çıktı.');
      expect(acikGorulen, greaterThan(10),
          reason: 'Açık modülün olayları hayata hiç girmedi.');
      expect(acikKarsilik, greaterThan(0),
          reason: 'İlk yılların izi sonradan hiç okunmadı.');
    });
  });
}
