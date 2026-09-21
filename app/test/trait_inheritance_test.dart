import 'dart:math';

import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/domain/generation/trait_inheritance.dart';
import 'package:bir_omur/domain/interaction/parenthood.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/marriage.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/person_development.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/stats.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/generation_fixtures.dart';

const Parenthood ebeveynlik = Parenthood();

Stats stats(int deger) => Stats(
      appearance: deger,
      happiness: deger,
      health: deger,
      intelligence: deger,
      charisma: deger,
    );

/// Evli, çocuk sahibi olabilecek bir oyuncu kurar.
GameState evliOyuncu({required Stats oyuncuStats, Stats? esStats}) {
  final GameState temel = olenOyuncu(olumYasi: 30).copyWith(
    deceased: false,
    settledEstates: const <String>{},
    marriage: const Marriage(
      spouseId: 'es-1',
      marriedAtAge: 25,
      status: MarriageStatus.evli,
    ),
  );
  return temel.copyWith(
    player: temel.player.copyWith(age: 30, wallet: 500000, stats: oyuncuStats),
    people: temel.people
        .where((Person p) => p.relation != RelationType.cocuk)
        .map((Person p) => p.id == 'es-1'
            ? p.copyWith(
                age: 29,
                isAlive: true,
                development: esStats == null
                    ? null
                    : PersonDevelopment(stats: esStats),
              )
            : p)
        .toList(growable: false),
  );
}

/// Aynı ebeveynlerden çok sayıda çocuk üretip zekâ dağılımını ölçer.
List<int> zekaDagilimi({
  required Stats oyuncuStats,
  Stats? esStats,
  int adet = 200,
}) {
  final List<int> sonuc = <int>[];
  for (int seed = 0; seed < adet; seed++) {
    final GameState state = evliOyuncu(
      oyuncuStats: oyuncuStats,
      esStats: esStats,
    );
    final GameState sonra = ebeveynlik.haveChild(state, Random(seed)).state;
    sonuc.add(sonra.children.single.development!.stats.intelligence);
  }
  return sonuc;
}

double ortalama(List<int> degerler) =>
    degerler.reduce((int a, int b) => a + b) / degerler.length;

void main() {
  group('Karışım kuralı', () {
    test('değerler her zaman 0-100 sınırında kalır', () {
      final Random rng = Random(3);
      for (int i = 0; i < 500; i++) {
        final int deger = TraitInheritance.blend(
          rng.nextInt(101),
          rng.nextInt(101),
          rng,
        );
        expect(deger, inInclusiveRange(0, 100));
        expect(
          deger,
          inInclusiveRange(
            TraitInheritance.prototypeOnlyMin,
            TraitInheritance.prototypeOnlyMax,
          ),
        );
      }
    });

    test('ebeveyn bilgisi yoksa nötr aralıktan çizilir', () {
      final Random rng = Random(4);
      for (int i = 0; i < 200; i++) {
        final int deger = TraitInheritance.blend(null, null, rng);
        expect(
          deger,
          inInclusiveRange(
            TraitInheritance.prototypeOnlyUnknownMin,
            TraitInheritance.prototypeOnlyUnknownMax,
          ),
        );
      }
    });

    test('tek ebeveyn biliniyorsa uydurma ikinci ebeveyn üretilmez', () {
      final Random rng = Random(5);
      final List<int> tek = <int>[
        for (int i = 0; i < 300; i++) TraitInheritance.blend(20, null, rng),
      ];
      final List<int> cift = <int>[
        for (int i = 0; i < 300; i++) TraitInheritance.blend(20, 20, rng),
      ];
      // İkisi de düşük ebeveynden geliyor; tek bilgi daha geniş saçılır.
      expect(ortalama(tek), lessThan(60));
      expect(ortalama(cift), lessThan(60));
    });
  });

  group('Doğumda aktarım', () {
    test('düşük zekâlı ebeveynlerin çocuğu genelde daha düşük başlar', () {
      final List<int> dusuk =
          zekaDagilimi(oyuncuStats: stats(20), esStats: stats(20));
      final List<int> yuksek =
          zekaDagilimi(oyuncuStats: stats(90), esStats: stats(90));

      expect(ortalama(dusuk), lessThan(ortalama(yuksek) - 15));
    });

    test('düşük zekâlı ebeveynlerden yüksek zekâ da çıkabilir', () {
      final List<int> dusuk =
          zekaDagilimi(oyuncuStats: stats(20), esStats: stats(20));
      // Kader değil: ortalamanın belirgin üstünde çocuklar da var.
      expect(dusuk.any((int z) => z > ortalama(dusuk) + 10), isTrue);
      expect(dusuk.toSet().length, greaterThan(10), reason: 'Tek değer değil');
    });

    test('yüksek zekâlı ebeveynlerin çocuğu mutlaka yüksek doğmaz', () {
      final List<int> yuksek =
          zekaDagilimi(oyuncuStats: stats(95), esStats: stats(95));
      expect(yuksek.any((int z) => z < 75), isTrue);
      expect(yuksek.every((int z) => z <= 100), isTrue);
    });

    test('eşin özellik bilgisi yoksa uydurulmaz ama kalıcı kayıt açılır', () {
      final GameState state = evliOyuncu(oyuncuStats: stats(70));
      expect(state.personById('es-1')!.development, isNull);

      final GameState sonra = ebeveynlik.haveChild(state, Random(11)).state;
      final Person es = sonra.personById('es-1')!;
      // Eşin özellikleri bir kez üretilip saklanır.
      expect(es.development, isNotNull);
      expect(es.development!.tracksLife, isFalse,
          reason: 'Eşin hayatı izlenmiyor, yalnızca özellikleri var');

      // İkinci çocukta aynı kayıt kullanılır, yeniden çizilmez.
      final GameState ikinci = ebeveynlik
          .haveChild(
            sonra.copyWith(
              people: sonra.people
                  .map((Person p) =>
                      p.relation == RelationType.cocuk ? p.copyWith(age: 2) : p)
                  .toList(growable: false),
            ),
            Random(12),
          )
          .state;
      expect(
        ikinci.personById('es-1')!.development!.stats.intelligence,
        es.development!.stats.intelligence,
      );
    });

    test('özellikler doğumda bir kez çizilir, kayıttan dönünce değişmez', () {
      final GameState state = evliOyuncu(
        oyuncuStats: stats(70),
        esStats: stats(60),
      );
      final GameState sonra = ebeveynlik.haveChild(state, Random(21)).state;
      final Stats dogumda = sonra.children.single.development!.stats;

      final GameState geri = decodeGameState(encodeGameState(sonra));
      final Stats sonrasi = geri.children.single.development!.stats;
      expect(sonrasi.intelligence, dogumda.intelligence);
      expect(sonrasi.appearance, dogumda.appearance);
      expect(sonrasi.health, dogumda.health);
      expect(sonrasi.charisma, dogumda.charisma);
    });

    test('mutluluk ebeveynden devralınmaz', () {
      final List<int> mutluluklar = <int>[];
      for (int seed = 0; seed < 40; seed++) {
        final GameState state = evliOyuncu(
          oyuncuStats: stats(5),
          esStats: stats(5),
        );
        final GameState sonra = ebeveynlik.haveChild(state, Random(seed)).state;
        mutluluklar.add(sonra.children.single.development!.stats.happiness);
      }
      // Ebeveynler çok mutsuz olsa da bebek mutsuz doğmaz.
      expect(
        mutluluklar.every((int m) =>
            m >= TraitInheritance.prototypeOnlyNewbornHappinessMin),
        isTrue,
      );
    });

    test('evlat edinilen gibi hazır bir kaydın özellikleri korunur', () {
      // ensureTraits mevcut kaydı **değiştirmez**: evlat edinilen çocuğun
      // kimliği ve özellikleri yeniden çizilmez (D-046).
      final Person hazir = kisi(
        id: 'cocuk-5',
        relation: RelationType.cocuk,
        gender: Gender.erkek,
        age: 7,
      ).copyWith(
        development: PersonDevelopment(stats: stats(42), tracksLife: true),
      );
      final Person sonra = TraitInheritance.ensureTraits(hazir, Random(1));
      expect(identical(sonra, hazir), isTrue);
      expect(sonra.development!.stats.intelligence, 42);
    });
  });
}
