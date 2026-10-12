// Paket BP — oturduğun ev.
//
// **Ölçülen sorun.** Katalogdaki konut olaylarının hepsi *başkasının*
// eviydi: 524 olayda kiracı kapısı 11, kiraya veren kapısı 14, boş ev
// kapısı 8 — oturulan evin kapısı **sıfır**; motorda böyle bir koşul
// bile yoktu. Kendi evinde oturan oyuncunun konut havuzundan aday
// olayı 30/40/50/60 yaşında 0'dı, kiracının 8. Yani hayatının en büyük
// alışverişini yapan oyuncunun hayatı sessizleşiyordu.
//
// Bu dosya dört şeyi ölçer:
//   1. Havuzun yapısı: her olay oturulan ev kapısından geçiyor mu,
//      bıraktığı iz okunuyor mu?
//   2. Kapı doğru mu: kiracıya ve ailesinin yanında yaşayana bu
//      olaylardan hiçbiri çıkmıyor mu?
//   3. Modül kapalıyken tek olay bile sızıyor mu, zarı kaydırıyor mu?
//   4. Oynanan hayatta gerçekten çıkıyor mu?
// ignore_for_file: avoid_print
library;

import 'dart:math';

import 'package:bir_omur/data/event_pool.dart';
import 'package:bir_omur/data/event_pool_home.dart';
import 'package:bir_omur/data/item_catalog.dart';
import 'package:bir_omur/domain/economy/housing.dart';
import 'package:bir_omur/domain/events/event_engine.dart';
import 'package:bir_omur/domain/features/feature_catalog.dart';
import 'package:bir_omur/domain/features/feature_events.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/owned_item.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/player_bot.dart';

/// Modülün olay kimlikleri.
Set<String> get _modulKimlikleri => FeatureEvents.idsOf(FeatureId.oturulanEv);

/// Kendi evinde oturan oyuncu kurar.
GameState _evSahibi(int tohum, int yas, {FeatureSwitches? anahtarlar}) {
  final GameState temel =
      LifeGenerator.seeded(tohum).generate(mode: StartMode.tamamenRastgele);
  final OwnedItem ev = OwnedItem(
    id: 'bp-ev-$tohum',
    typeId:
        kItemTypes.firstWhere((ItemType t) => t.kind == ItemKind.konut).id,
    acquiredAtAge: 25,
    location: temel.player.currentCity,
    purchasePrice: 3500000,
  );
  return temel.copyWith(
    player: temel.player.copyWith(age: yas),
    items: <OwnedItem>[ev],
    residenceItemId: ev.id,
    movedOut: true,
    settings: anahtarlar == null
        ? temel.settings
        : temel.settings.copyWith(features: anahtarlar),
  );
}

void main() {
  group('Paket BP — havuzun yapısı', () {
    test('bütün olaylar ana havuzda, modülde ve doğru kapıda', () {
      final Set<String> havuz = kEventPool.map((GameEvent e) => e.id).toSet();
      for (final GameEvent olay in kHomeEvents) {
        expect(havuz.contains(olay.id), isTrue,
            reason: '${olay.id} ana havuza eklenmemiş.');
        expect(_modulKimlikleri.contains(olay.id), isTrue,
            reason: '${olay.id} modül kapısına bağlı değil.');
        expect(olay.requirement.requiresOwnedResidence, isTrue,
            reason: '${olay.id} oturulan ev kapısından geçmiyor.');
      }
      print('Oturulan ev havuzu: ${kHomeEvents.length} olay.');
    });

    test('bırakılan her iz katalogda okunuyor', () {
      // Paket AR'nin ölçtüğü hata: iz konur, hiçbir olay onu aramaz.
      final Set<String> konan = <String>{
        for (final GameEvent e in kHomeEvents)
          for (final EventChoice c in e.choices) ...c.addFlags,
      };
      final Set<String> aranan = <String>{
        for (final GameEvent e in kEventPool) ...e.requirement.requiredFlags,
        for (final GameEvent e in kEventPool) ...e.requirement.forbiddenFlags,
      };
      final Set<String> sessiz = konan.difference(aranan);
      expect(sessiz, isEmpty,
          reason: 'karşılığı olmayan iz: ${sessiz.join(", ")}');
      print('Bırakılan iz: ${konan.length}, hepsinin karşılığı var.');
    });

    test('karşılık olayları bir iz arıyor', () {
      final List<GameEvent> karsiliklar = kHomeEvents
          .where((GameEvent e) => e.requirement.requiredFlags.isNotEmpty)
          .toList(growable: false);
      expect(karsiliklar.length, greaterThanOrEqualTo(7),
          reason: 'karşılık olayı sayısı düştü');
      for (final GameEvent e in karsiliklar) {
        expect(e.weight, 4,
            reason: '${e.id}: karşılık olayının ağırlığı 4 olmalı');
      }
    });
  });

  group('Paket BP — kapı', () {
    test('kiracıya ve ailesinin yanında yaşayana çıkmıyor', () {
      const EventEngine motor = EventEngine();
      for (int tohum = 0; tohum < 10; tohum++) {
        final GameState temel = LifeGenerator.seeded(tohum)
            .generate(mode: StartMode.tamamenRastgele);
        for (final int yas in <int>[25, 35, 45, 60]) {
          final GameState kirada = temel.copyWith(
            player: temel.player.copyWith(age: yas),
            movedOut: true,
          );
          final GameState ailede =
              temel.copyWith(player: temel.player.copyWith(age: yas));
          for (final GameState s in <GameState>[kirada, ailede]) {
            expect(Housing.residenceOf(s), isNot(ResidenceKind.kendiEvinde));
            final Set<String> adaylar = motor.debugEligibleIds(s);
            expect(adaylar.intersection(_modulKimlikleri), isEmpty,
                reason: 'tohum $tohum, yaş $yas: oturmadığı ev olayı çıktı');
          }
        }
      }
    });

    test('kendi evinde oturana çıkıyor ve bant boyunca sürüyor', () {
      const EventEngine motor = EventEngine();
      final Map<int, int> yasaGore = <int, int>{};
      for (final int yas in <int>[22, 30, 40, 50, 65]) {
        int toplam = 0;
        for (int tohum = 0; tohum < 10; tohum++) {
          final Set<String> adaylar =
              motor.debugEligibleIds(_evSahibi(tohum, yas));
          toplam += adaylar.intersection(_modulKimlikleri).length;
        }
        yasaGore[yas] = (toplam / 10).round();
        expect(yasaGore[yas], greaterThanOrEqualTo(6),
            reason: '$yas yaşında oturulan ev olayı yetersiz');
      }
      print('Kendi evinde aday olay sayısı (10 tohum ortalaması): '
          '${yasaGore.entries.map((MapEntry<int, int> e) => "${e.key} yaş: "
              "${e.value}").join(" · ")}');
    });
  });

  group('Paket BP — modül kapalıyken', () {
    test('tek olay bile aday olmuyor', () {
      const EventEngine motor = EventEngine();
      final FeatureSwitches kapali =
          FeatureSwitches.defaults.toggled(FeatureId.oturulanEv, false);
      for (int tohum = 0; tohum < 10; tohum++) {
        for (final int yas in <int>[25, 40, 60]) {
          final Set<String> adaylar = motor.debugEligibleIds(
            _evSahibi(tohum, yas, anahtarlar: kapali),
          );
          expect(adaylar.intersection(_modulKimlikleri), isEmpty,
              reason: 'tohum $tohum, yaş $yas: kapalı modül sızdı');
        }
      }
    });

    test('kapalı modül zarı kaydırmıyor', () {
      // Paket BL/BM sözleşmesi: kapalı modül, hiç yazılmamış gibi
      // davranmalı. Karşılaştırma iki motorla yapılır.
      final List<GameEvent> modulsuzHavuz = kEventPool
          .where((GameEvent e) => !_modulKimlikleri.contains(e.id))
          .toList(growable: false);
      const EventEngine tamHavuz = EventEngine();
      final EventEngine modulsuz = EventEngine(pool: modulsuzHavuz);
      final FeatureSwitches kapali =
          FeatureSwitches.defaults.toggled(FeatureId.oturulanEv, false);
      int karsilastirilan = 0;
      for (int tohum = 0; tohum < 20; tohum++) {
        for (final int yas in <int>[25, 40, 60]) {
          final GameState s = _evSahibi(tohum, yas, anahtarlar: kapali);
          final int zar = tohum * 131 + yas;
          expect(
            tamHavuz.openingEvent(s, Random(zar))?.eventId,
            modulsuz.openingEvent(s, Random(zar))?.eventId,
            reason: 'tohum $tohum, yaş $yas: kapalı modül zarı kaydırdı',
          );
          karsilastirilan++;
        }
      }
      print('Zar karşılaştırması: $karsilastirilan durum, hepsi aynı.');
    });
  });

  group('Paket BP — oynanan hayatta', () {
    test('kendi evine çıkan oyuncu bu olayları yaşıyor', () {
      const int kHayat = 40;
      int evSahibiOlan = 0;
      int olayGoren = 0;
      final Set<String> gorulen = <String>{};
      for (int i = 0; i < kHayat; i++) {
        final BotLifeResult sonuc = playBotLife(
          archetype: i.isEven
              ? PlayerArchetype.career
              : PlayerArchetype.investor,
          seed: 700 + i * 13,
        );
        if (!sonuc.ownedHome) continue;
        evSahibiOlan++;
        final Set<String> evOlaylari =
            sonuc.seenEvents.intersection(_modulKimlikleri);
        if (evOlaylari.isNotEmpty) olayGoren++;
        gorulen.addAll(evOlaylari);
      }
      print('Ev sahibi olan hayat: $evSahibiOlan/$kHayat · '
          'oturulan ev olayı gören: $olayGoren · '
          'havuzun ${gorulen.length}/${kHomeEvents.length} olayı görüldü');
      expect(evSahibiOlan, greaterThan(10),
          reason: 'ölçüm kurulamadı: ev sahibi olan hayat az');
      expect(olayGoren * 2, greaterThan(evSahibiOlan),
          reason: 'ev sahiplerinin yarısı bile bu olayları görmüyor');
      expect(gorulen.length, greaterThanOrEqualTo(10),
          reason: 'havuzun çok küçük bir kısmı erişiliyor');
    });
  });
}
