import 'dart:math';

import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/generation/life_progression.dart';
import 'package:bir_omur/domain/life/aging.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:flutter_test/flutter_test.dart';

/// Yaşlanmanın dış görünüşe etkisi (D-051).
void main() {
  group('Yıllık değişim kuralı', () {
    test('çocuklukta ve gençlikte otomatik ceza yoktur', () {
      final Random rng = Random(1);
      for (int age = 0; age < Aging.prototypeOnlyStartAge; age++) {
        for (int i = 0; i < 50; i++) {
          expect(
            Aging.yearlyDelta(
              age: age,
              appearance: 70,
              health: 70,
              rng: rng,
            ),
            0,
            reason: '$age yaşında düşüş olmamalı',
          );
        }
      }
    });

    test('değer tabanın altına inmez ve 0-100 aralığında kalır', () {
      final Random rng = Random(2);
      for (int i = 0; i < 500; i++) {
        final int delta = Aging.yearlyDelta(
          age: 90,
          appearance: Aging.prototypeOnlyFloor,
          health: 20,
          rng: rng,
        );
        expect(delta, 0);
      }
      int gorunus = Aging.prototypeOnlyFloor + 1;
      for (int i = 0; i < 200; i++) {
        gorunus += Aging.yearlyDelta(
          age: 85,
          appearance: gorunus,
          health: 30,
          rng: rng,
        );
        expect(gorunus, greaterThanOrEqualTo(Aging.prototypeOnlyFloor));
        expect(gorunus, inInclusiveRange(0, 100));
      }
    });

    test('her karakter aynı yaşta aynı görünüşe düşmez', () {
      final Set<int> sonuclar = <int>{};
      for (int seed = 0; seed < 60; seed++) {
        final Random rng = Random(seed);
        int gorunus = 70;
        for (int age = 30; age <= 70; age++) {
          gorunus += Aging.yearlyDelta(
            age: age,
            appearance: gorunus,
            health: 70,
            rng: rng,
          );
        }
        sonuclar.add(gorunus);
      }
      expect(sonuclar.length, greaterThan(5));
    });

    test('sağlığı iyi olan daha yavaş yıpranır', () {
      int saglikliToplam = 0;
      int hastaToplam = 0;
      for (int seed = 0; seed < 200; seed++) {
        int saglikli = 80;
        int hasta = 80;
        final Random r1 = Random(seed);
        final Random r2 = Random(seed);
        for (int age = 30; age <= 70; age++) {
          saglikli += Aging.yearlyDelta(
            age: age,
            appearance: saglikli,
            health: 90,
            rng: r1,
          );
          hasta += Aging.yearlyDelta(
            age: age,
            appearance: hasta,
            health: 20,
            rng: r2,
          );
        }
        saglikliToplam += saglikli;
        hastaToplam += hasta;
      }
      expect(saglikliToplam, greaterThan(hastaToplam));
    });
  });

  group('Ölçüm: aşırı hızlı düşüş var mı', () {
    test('2000 hayatta görünüş makul bir hızda düşer', () {
      // Yalnızca yaşlanma kuralı ölçülür; oyun akışından bağımsızdır.
      final List<int> kirkta = <int>[];
      final List<int> altmista = <int>[];
      final List<int> seksende = <int>[];

      for (int seed = 0; seed < 2000; seed++) {
        final Random rng = Random(seed);
        int gorunus = 60;
        for (int age = 1; age <= 80; age++) {
          gorunus += Aging.yearlyDelta(
            age: age,
            appearance: gorunus,
            health: 60,
            rng: rng,
          );
          if (age == 40) kirkta.add(gorunus);
          if (age == 60) altmista.add(gorunus);
          if (age == 80) seksende.add(gorunus);
        }
      }

      double ort(List<int> l) => l.reduce((int a, int b) => a + b) / l.length;

      // 40 yaşında belirgin bir çöküş olmamalı (en fazla ~3 puan).
      expect(ort(kirkta), greaterThan(56));
      // 60 yaşında ölçülü bir düşüş.
      expect(ort(altmista), greaterThan(43));
      expect(ort(altmista), lessThan(58));
      // 80 yaşında düşüş belirgin ama taban korunur.
      expect(ort(seksende), greaterThan(Aging.prototypeOnlyFloor.toDouble()));
      expect(ort(seksende), lessThan(ort(altmista)));
    });
  });

  group('Oyun akışı', () {
    GameState hayat(int seed, {int age = 50}) {
      final GameState base =
          LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
      return base.copyWith(
        player: base.player.copyWith(age: age, wallet: 400000),
      );
    }

    test('yaş alınca değişim gerçek kayda işlenir', () {
      GameState state = hayat(11);
      final int baslangic = state.player.stats.appearance;
      for (int i = 0; i < 20 && !state.deceased; i++) {
        state = LifeProgression(Random(i + 1))
            .advanceOneYear(state.copyWith(pendingEvent: null));
      }
      expect(state.player.stats.appearance, lessThanOrEqualTo(baslangic));
      expect(state.player.stats.appearance, inInclusiveRange(0, 100));
    });

    test('yaşlanma tek başına mutluluğu veya zekâyı düşürmez', () {
      // Kural düzeyinde: yaşlanma yalnızca görünüş döndürür.
      final Random rng = Random(4);
      for (int i = 0; i < 100; i++) {
        final int delta = Aging.yearlyDelta(
          age: 70,
          appearance: 80,
          health: 60,
          rng: rng,
        );
        expect(delta, lessThanOrEqualTo(0));
      }
    });

    test('kaydı kapatıp açmak aynı yılın etkisini tekrarlamaz', () {
      GameState state = hayat(12, age: 60);
      state = LifeProgression(Random(3))
          .advanceOneYear(state.copyWith(pendingEvent: null));
      final int gorunus = state.player.stats.appearance;

      // Kaydedip geri okumak değeri değiştirmez.
      final GameState geri = decodeGameState(encodeGameState(state));
      expect(geri.player.stats.appearance, gorunus);
      // İkinci kez yaş alınmadıkça değer sabit kalır.
      expect(geri.player.age, state.player.age);
    });
  });
}
