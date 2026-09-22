import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/domain/casino/blackjack.dart';
import 'package:bir_omur/domain/casino/casino_rules.dart';
import 'package:bir_omur/domain/casino/horse_race.dart';
import 'package:bir_omur/domain/casino/roulette.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:bir_omur/ui/sound/sound_service.dart';
import 'package:bir_omur/ui/widgets/roulette_wheel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_flow.dart';

GameState kumarbaz({int wallet = 400000, int age = 30}) {
  final GameState base =
      LifeGenerator.seeded(9).generate(mode: StartMode.tamamenRastgele);
  return base.copyWith(
    pendingEvent: null,
    notices: const <PendingNotice>[],
    player: base.player.copyWith(age: age, wallet: wallet),
  );
}

void main() {
  group('At yarışı alanı', () {
    test('kadroda beş at var, adları ve kulvarları benzersiz', () {
      for (int seed = 0; seed < 20; seed++) {
        final List<RaceHorse> kadro = HorseRacing.buildField(Random(seed));
        expect(kadro, hasLength(HorseRacing.prototypeOnlyHorseCount));
        expect(
          kadro.map((RaceHorse h) => h.lane).toSet(),
          hasLength(kadro.length),
        );
        expect(
          kadro.map((RaceHorse h) => h.name).toSet(),
          hasLength(kadro.length),
        );
      }
    });

    test('oranlar sınırlar içinde kalır', () {
      for (int seed = 0; seed < 30; seed++) {
        for (final RaceHorse h in HorseRacing.buildField(Random(seed))) {
          expect(
            h.odds,
            inInclusiveRange(
              HorseRacing.prototypeOnlyMinOdds,
              HorseRacing.prototypeOnlyMaxOdds,
            ),
          );
        }
      }
    });

    test('gerçek ihtimallerin toplamı 1', () {
      for (int seed = 0; seed < 20; seed++) {
        final List<double> p =
            HorseRacing.trueChances(HorseRacing.buildField(Random(seed)));
        expect(p.reduce((double a, double b) => a + b), closeTo(1.0, 1e-9));
      }
    });

    test('bitiş sırası bütün atları bir kez içerir', () {
      final List<RaceHorse> kadro = HorseRacing.buildField(Random(3));
      for (int seed = 0; seed < 30; seed++) {
        final RaceResult r = HorseRacing.run(kadro, Random(seed));
        expect(r.finishOrder, hasLength(kadro.length));
        expect(r.finishOrder.toSet(), hasLength(kadro.length));
        expect(r.winnerLane, r.finishOrder.first);
      }
    });

    test('favori daha sık kazanır ama her zaman değil', () {
      final List<RaceHorse> kadro = HorseRacing.buildField(Random(11));
      final RaceHorse favori = kadro.reduce(
        (RaceHorse a, RaceHorse b) => a.odds < b.odds ? a : b,
      );
      int favoriKazandi = 0;
      const int n = 400;
      for (int seed = 0; seed < n; seed++) {
        if (HorseRacing.run(kadro, Random(seed)).winnerLane == favori.lane) {
          favoriKazandi++;
        }
      }
      expect(favoriKazandi, greaterThan(0));
      expect(favoriKazandi, lessThan(n), reason: 'Favori hep kazanmamalı');
      // Favori, en düşük oranlı at olduğu için ortalamanın üstünde
      // kazanmalı.
      expect(favoriKazandi, greaterThan(n ~/ kadro.length));
    });

    test('sonuç bahisten bağımsızdır', () {
      // Aynı tohumla aynı koşu çıkar; hangi ata oynandığı sonucu
      // değiştirmez.
      final List<RaceHorse> kadro = HorseRacing.buildField(Random(5));
      final GameState s = kumarbaz();
      final int bahis = CasinoRules.prototypeOnlyMinBet;
      final Set<int> kazananlar = <int>{};
      for (final RaceHorse at in kadro) {
        final ({CasinoResult result, RaceResult? race}) c =
            HorseRacing.placeBet(s, kadro, at.lane, bahis, Random(42));
        expect(c.race, isNotNull);
        kazananlar.add(c.race!.winnerLane);
      }
      expect(kazananlar, hasLength(1),
          reason: 'Kazanan, oynanan ata göre değişmemeli');
    });

    test('kazanınca oran kadar öder, kaybedince bahis gider', () {
      final List<RaceHorse> kadro = HorseRacing.buildField(Random(7));
      final GameState s = kumarbaz(wallet: 100000);
      final int bahis = 1000;
      bool kazancGorundu = false;
      bool kayipGorundu = false;
      for (int seed = 0; seed < 60; seed++) {
        final ({CasinoResult result, RaceResult? race}) c =
            HorseRacing.placeBet(s, kadro, 1, bahis, Random(seed));
        final int fark = c.result.state.player.wallet - s.player.wallet;
        if (c.race!.winnerLane == 1) {
          final int beklenen = (bahis * kadro.first.odds).round() - bahis;
          expect(fark, beklenen);
          kazancGorundu = true;
        } else {
          expect(fark, -bahis);
          kayipGorundu = true;
        }
      }
      expect(kazancGorundu, isTrue);
      expect(kayipGorundu, isTrue);
    });

    test('bahis yıllık bütçeye sayılır', () {
      final List<RaceHorse> kadro = HorseRacing.buildField(Random(2));
      final GameState s = kumarbaz();
      final ({CasinoResult result, RaceResult? race}) c =
          HorseRacing.placeBet(s, kadro, 1, 500, Random(1));
      expect(c.result.state.wagerThisAge, s.wagerThisAge + 500);
    });

    test('olmayan kulvara oynanamaz ve cüzdan değişmez', () {
      final List<RaceHorse> kadro = HorseRacing.buildField(Random(2));
      final GameState s = kumarbaz();
      final ({CasinoResult result, RaceResult? race}) c =
          HorseRacing.placeBet(s, kadro, 99, 500, Random(1));
      expect(c.result.outcome.applied, isFalse);
      expect(c.race, isNull);
      expect(c.result.state.player.wallet, s.player.wallet);
    });

    test('küçük yaşta masa açılmaz', () {
      final List<RaceHorse> kadro = HorseRacing.buildField(Random(2));
      final GameState cocuk = kumarbaz(age: 12);
      final ({CasinoResult result, RaceResult? race}) c =
          HorseRacing.placeBet(cocuk, kadro, 1, 500, Random(1));
      expect(c.result.outcome.applied, isFalse);
      expect(c.result.state.player.wallet, cocuk.player.wallet);
    });

    test('kasanın payı oranlara yansır', () {
      // Oranların işaret ettiği ihtimallerin toplamı 1'i aşar.
      for (int seed = 0; seed < 20; seed++) {
        final List<RaceHorse> kadro = HorseRacing.buildField(Random(seed));
        final double toplam = kadro
            .map((RaceHorse h) => h.impliedChance)
            .reduce((double a, double b) => a + b);
        expect(toplam, greaterThan(1.0));
      }
    });
  });

  group('Rulet çarkı animasyonu', () {
    test('çark sırası 37 sayıyı bir kez içerir', () {
      expect(kRouletteOrder, hasLength(Roulette.pockets));
      expect(kRouletteOrder.toSet(), hasLength(Roulette.pockets));
      for (int i = 0; i <= 36; i++) {
        expect(kRouletteOrder, contains(i));
      }
    });

    test('çarkta kırmızı ve siyah dönüşümlü gider (0 dışında)', () {
      // Gerçek Avrupa ruletinde sıfırdan sonra renkler dönüşümlüdür.
      int ayniArdArda = 0;
      for (int i = 1; i < kRouletteOrder.length - 1; i++) {
        final int a = kRouletteOrder[i];
        final int b = kRouletteOrder[i + 1];
        if (a == 0 || b == 0) continue;
        if (kRouletteRedNumbers.contains(a) ==
            kRouletteRedNumbers.contains(b)) {
          ayniArdArda++;
        }
      }
      expect(ayniArdArda, 0);
    });

    test('alan çıkan sayıyı da döndürür', () {
      const Roulette rulet = Roulette();
      final GameState s = kumarbaz();
      for (int seed = 0; seed < 20; seed++) {
        final ({CasinoResult result, int? number}) c = rulet.spinDetailed(
          s,
          RouletteBetType.kirmizi,
          CasinoRules.prototypeOnlyMinBet,
          Random(seed),
        );
        expect(c.number, isNotNull);
        expect(c.number, inInclusiveRange(0, 36));
        // Metinde de aynı sayı yazmalı: animasyon ile metin ayrışmaz.
        expect(c.result.outcome.text, contains('${c.number}'));
      }
    });
  });

  group('Masalar arayüzde açılır', () {
    late GameController controller;
    setUp(() => controller = GameController(random: Random(9)));
    tearDown(() => controller.dispose());

    testWidgets('at yarışı masası açılır ve koşu oynanır',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 4200);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        BirOmurApp(controller: controller, sound: SoundService.silent()),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rastgele bir hayat'));
      await tester.pumpAndSettle();
      controller.debugSetState(kumarbaz());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('tab_aktiviteler')));
      await tester.pumpAndSettle();
      await scrollToFinder(tester, find.text('Kumarhane'));
      await tester.tap(find.text('Kumarhane'));
      await tester.pumpAndSettle();
      await scrollToFinder(tester, find.byKey(const Key('casino_horse_row')));
      await tester.tap(find.byKey(const Key('casino_horse_row')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('race_track')), findsOneWidget);
      expect(controller.raceField, hasLength(5));

      final int once = controller.state!.player.wallet;
      await scrollToFinder(
        tester,
        find.byKey(const Key('horse_race_start')),
      );
      await tester.tap(find.byKey(const Key('horse_race_start')));
      // Koşu sürerken sonuç yazılmaz.
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.textContaining('birinci geldi'), findsNothing);

      await tester.pumpAndSettle(const Duration(seconds: 5));
      expect(controller.lastRace, isNotNull);
      expect(controller.state!.player.wallet, isNot(once));
    });
  });
}
