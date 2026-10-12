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

      // `acikKarsilik > 0` iddiası buradan **kaldırılmadı, aşağıdaki
      // teste taşındı ve zarsız hale getirildi.** Gerekçe ölçüldü
      // (Paket DG, 2×300 hayat):
      //
      // | iz | DG açık: iz → olay | DG kapalı: iz → olay |
      // |---|---|---|
      // | bisiklet | 12 → 5 | 13 → 6 |
      // | kumbara  |  2 → 1 |  2 → 0 |
      // | harfler  |  8 → 2 | 12 → 7 |
      // | sokak    | 19 → 11| 18 → 9 |
      // | en az bir karşılık gören hayat | 19/300 (%6,3) | 21/300 (%7,0) |
      //
      // İki kohort aynı: yeni içerik bu oranı düşürmedi. Ama p=%6,3'te
      // 60 hayatta hiç görülmeme ihtimali **%2**. Yani bu satır bir
      // bekçi değil, iki yüzde birlik bir kuraydı; Paket DG'nin zar
      // kayması ona denk geldi. Kohortu 300'e çıkarmak da çareydi ama
      // süit 600 hayat daha uzardı; iddianın kendisi zar gerektirmiyor
      // (okuyucuların tek kapısı yaş + iz), bu yüzden yapısal bekçiye
      // çevrildi. Sayı yine basılıyor: ÖLÇÜM kalıyor, kura gidiyor.
      print('(Karşılık sayısı ÖLÇÜMdür; bekçisi aşağıdaki testte.)');
    });

    // -----------------------------------------------------------------
    // İzin okunması — zarsız bekçi (Paket DG)
    // -----------------------------------------------------------------
    test('ilk yılların izi sonradan okunuyor', () {
      // §1 KATALOG. İlk yılların koyduğu her iz bir yerde okunmalı.
      // Paket AR'ın avladığı kusur: iz konur, kimse okumaz.
      final Set<String> konan = <String>{};
      for (final GameEvent olay in kEarlyYearsEvents) {
        for (final EventChoice secim in olay.choices) {
          konan.addAll(secim.addFlags);
        }
      }
      final Set<String> okunan = <String>{};
      for (final GameEvent olay in kEventPool) {
        okunan.addAll(olay.requirement.requiredFlags);
        okunan.addAll(olay.requirement.forbiddenFlags);
      }
      expect(konan, isNotEmpty, reason: 'İlk yıllar hiç iz koymuyor.');
      for (final String iz in konan) {
        expect(okunan.contains(iz), isTrue,
            reason: '$iz sessiz iz: hiçbir olay onu okumuyor.');
      }
      print('İlk yılların koyduğu ${konan.length} izin hepsi okunuyor.');

      // §2 OYNANAN HAYAT. Karşılık olayının tek kapısı yaş + iz. O
      // halde iddia zar gerektirmez: izi taşıyan ve penceresi açık bir
      // kare **bulunursa**, okuyucu o karede aday olmak **zorundadır**.
      //
      // Kare ARANIR, kurulmaz: `onPreAge` bütün bekleyen iş kapandıktan
      // sonraki kare (Paket CR/DC dersi).
      const EventEngine motor = EventEngine();
      final Map<String, int> bulunanKare = <String, int>{};
      final Map<String, int> adayCikti = <String, int>{};
      final Map<String, int> zatenCikmis = <String, int>{};
      final List<String> sorunlar = <String>[];

      for (final GameEvent okuyucu in kEarlyYearsEvents) {
        if (okuyucu.requirement.requiredFlags.isEmpty) continue;
        bulunanKare[okuyucu.id] = 0;
        adayCikti[okuyucu.id] = 0;
        zatenCikmis[okuyucu.id] = 0;
      }

      for (int i = 0; i < kHayat; i++) {
        final Set<String> buHayattaCikan = <String>{};
        playBotLife(
          archetype: PlayerArchetype.casual,
          seed: 22000 + i,
          onPreAge: (GameState s) {
            for (final String id in bulunanKare.keys) {
              if (s.seenEventIds.contains(id)) buHayattaCikan.add(id);
            }
            for (final GameEvent okuyucu in kEarlyYearsEvents) {
              final EventRequirement k = okuyucu.requirement;
              if (k.requiredFlags.isEmpty) continue;
              if (s.player.age < k.minAge || s.player.age > k.maxAge) continue;
              if (!s.storyFlags.containsAll(k.requiredFlags)) continue;
              if (k.forbiddenFlags.any(s.storyFlags.contains)) continue;
              bulunanKare[okuyucu.id] = bulunanKare[okuyucu.id]! + 1;
              final Set<String> adaylar = motor.debugEligibleIds(
                  s.copyWith(pendingEvent: null), Random(s.player.age * 31 + i));
              // Tekrarlanamaz olay bir kez çıkınca adaylıktan düşer:
              // "aday **ya da** çıkmış" (Paket CK dersi).
              if (adaylar.contains(okuyucu.id) ||
                  s.seenEventIds.contains(okuyucu.id)) {
                adayCikti[okuyucu.id] = adayCikti[okuyucu.id]! + 1;
              } else {
                sorunlar.add('${okuyucu.id}: ${s.player.age} yaşında iz var, '
                    'pencere açık, ama aday değil.');
              }
            }
          },
        );
        for (final String id in buHayattaCikan) {
          zatenCikmis[id] = zatenCikmis[id]! + 1;
        }
      }

      print('');
      print('İZ TAŞIYAN KARE / OKUYUCU ADAY  ($kHayat hayat)');
      print('  "kare" = iz konmuş, pencere açık ve karşılık **henüz**');
      print('  çıkmamış kare. Karşılık ×8 katsayısıyla ilk uygun yılda');
      print('  çıkarsa kendi `forbiddenFlags`\'i sonraki kareleri eler,');
      print('  yani kare=0 + çıkmış>0 sağlıklı bir sonuçtur.');
      for (final String id in bulunanKare.keys) {
        print('  ${id.padRight(28)} kare=${bulunanKare[id]!.toString().padLeft(4)}'
            '  aday=${adayCikti[id]!.toString().padLeft(4)}'
            '  çıkmış hayat=${zatenCikmis[id]!.toString().padLeft(3)}');
      }

      // Bulunan her karede okuyucu aday olmalı: tek istisna yok.
      expect(sorunlar, isEmpty, reason: sorunlar.take(5).join('\n'));

      // Araç ölü olmasın. "Kare bulundu" ya da "karşılık çıktı":
      // ikisi de izin okunduğunu gösterir, biri yeter.
      final int kareToplam =
          bulunanKare.values.fold<int>(0, (int a, int b) => a + b);
      final int cikmisToplam =
          zatenCikmis.values.fold<int>(0, (int a, int b) => a + b);
      expect(kareToplam + cikmisToplam, greaterThan(0),
          reason: '$kHayat hayatta ne izi taşıyan kare bulundu ne karşılık '
              'çıktı: iz koyan olaylar artık hiç çıkmıyor olabilir.');

      // §1 ile §2 birlikte iki ayrı kusur sınıfını kapatır ve bu
      // ayrım bilerek böyledir:
      //   · §2 arama ölçütünü okuyucunun **kendi** koşulundan alır.
      //     Bu yüzden koşula yeni bir kapı eklenirse (örn.
      //     `requiresSchoolStudent`) motor o karede olayı eler ve §2
      //     düşer — Paket BZ'nin "yanlış kapıdaki olay" kusuru.
      //   · Ama izin adı yanlış yazılırsa §2 hiç kare bulamaz ve
      //     sessiz kalır; o kusuru §1 yakalar: iz okuyucusuz kalır.
      // İkisi birbirinin kör noktasıdır; biri silinirse diğeri yetmez.
    });
  });
}
