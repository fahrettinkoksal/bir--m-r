import 'dart:math';

import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/interaction/fertility_treatment.dart';
import 'package:bir_omur/domain/interaction/intimacy.dart';
import 'package:bir_omur/domain/interaction/marriage_engine.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:flutter_test/flutter_test.dart';

/// Karşı cinsten bir sevgilisi olan, denemiş ama sonuç alamamış bir hayat.
GameState cift({
  int age = 32,
  int partnerAge = 30,
  int wallet = 1000000,
  int tries = 6,
  bool playerInfertile = false,
  bool partnerInfertile = false,
}) {
  for (int seed = 0; seed < 200; seed++) {
    final GameState taban =
        LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
    if (taban.player.gender != Gender.erkek) continue;

    final List<Person> kisiler = taban.people
        .where((Person p) => p.relation != RelationType.sevgili)
        .toList(growable: true)
      ..add(
        Person(
          id: 'sevgili-1',
          firstName: 'Elif',
          lastName: 'Yaman',
          gender: Gender.kadin,
          relation: RelationType.sevgili,
          age: partnerAge,
          isAlive: true,
          inPlayerHousehold: false,
          employment: EmploymentStatus.calisiyor,
          occupation: 'öğretmen',
          wealth: WealthTier.ortaHalli,
          bond: 70,
          infertile: partnerInfertile,
        ),
      );

    return taban.copyWith(
      pendingEvent: null,
      notices: const <PendingNotice>[],
      people: List<Person>.unmodifiable(kisiler),
      unprotectedTries: tries,
      player: taban.player.copyWith(
        age: age,
        wallet: wallet,
        infertile: playerInfertile,
      ),
    );
  }
  throw StateError('Uygun hayat bulunamadı');
}

void main() {
  group('Başarı oranları', () {
    test('yaşla birlikte düşer ve bir yerden sonra sıfırlanır', () {
      double onceki = 1;
      for (final int yas in <int>[30, 36, 39, 41, 44, 46, 50]) {
        final double simdi = FertilityTreatment.prototypeOnlySuccessByAge(yas);
        expect(simdi, lessThanOrEqualTo(onceki), reason: '$yas yaşında');
        onceki = simdi;
      }
      expect(FertilityTreatment.prototypeOnlySuccessByAge(50), 0);
    });

    test('hiçbir yaşta garanti değildir', () {
      for (int yas = 18; yas <= 60; yas++) {
        expect(FertilityTreatment.prototypeOnlySuccessByAge(yas),
            lessThan(1.0));
      }
    });

    test('kısır çiftte ihtimal düşer ama sıfırlanmaz', () {
      final double saglikli =
          FertilityTreatment.successChance(cift());
      final double kisir = FertilityTreatment.successChance(
        cift(partnerInfertile: true),
      );
      expect(kisir, greaterThan(0),
          reason: 'Tedavinin varlık sebebi kısır çifte şans vermesi');
      expect(kisir, lessThan(saglikli));
    });

    test('oyuncunun kısırlığı da aynı şekilde işler', () {
      expect(
        FertilityTreatment.successChance(cift(playerInfertile: true)),
        greaterThan(0),
      );
    });
  });

  group('Engeller', () {
    test('denemeden başvurulamaz', () {
      final GameState s = cift(tries: 0);
      expect(FertilityTreatment.blockReason(s), isNotEmpty);
      expect(FertilityTreatment.blockReason(s), contains('kendiniz'));
    });

    test('yeterince denemiş çift başvurabilir', () {
      expect(FertilityTreatment.blockReason(cift()), isEmpty);
    });

    test('eşik, "olmuyor" uyarısıyla aynıdır', () {
      // Oyuncu uyarıyı gördüğü anda kapı açılmalı; uyarı gerçek bir yol
      // göstermeli.
      final GameState s = cift(tries: Intimacy.prototypeOnlyWorryAfter);
      expect(Intimacy.shouldWorry(s), isTrue);
      expect(FertilityTreatment.blockReason(s), isEmpty);
    });

    test('parası yetmeyen başvuramaz', () {
      final GameState s = cift(wallet: 100);
      expect(FertilityTreatment.blockReason(s), contains('yeterli para'));
    });

    test('eşi olmayan başvuramaz', () {
      GameState s = cift();
      s = s.copyWith(
        people: s.people
            .where((Person p) => p.relation != RelationType.sevgili)
            .toList(growable: false),
      );
      expect(FertilityTreatment.blockReason(s), contains('eşin'));
    });

    test('hamileyken başvurulamaz', () {
      GameState s = cift();
      s = FertilityTreatment.attempt(s, Random(0)).state;
      // Tuttuysa hamile; tutmadıysa bu testi anlamlı kılacak şekilde ara.
      for (int seed = 0; seed < 80 && !s.isExpecting; seed++) {
        s = cift();
        s = FertilityTreatment.attempt(s, Random(seed)).state;
      }
      expect(s.isExpecting, isTrue, reason: 'Hiç tutmadı');
      expect(FertilityTreatment.blockReason(s), contains('bekliyorsunuz'));
    });

    test('yılda bir deneme sınırı vardır', () {
      GameState s = cift();
      final FamilyResult r = FertilityTreatment.attempt(s, Random(3));
      s = r.state;
      if (s.isExpecting) return; // Tuttuysa zaten kapalı; ayrı test var.
      expect(FertilityTreatment.blockReason(s), contains('seneye'));
    });

    test('çok ileri yaşta hekim tedaviyi önermiyor', () {
      final GameState s = cift(age: 55, partnerAge: 52);
      expect(FertilityTreatment.blockReason(s), contains('sonuç vermeyeceğini'));
    });
  });

  group('Deneme', () {
    test('başarısız olsa da ücret ödenir ve mutluluk düşer', () {
      for (int seed = 0; seed < 100; seed++) {
        final GameState s = cift();
        final FamilyResult r = FertilityTreatment.attempt(s, Random(seed));
        if (r.state.isExpecting) continue;
        expect(r.outcome.applied, isTrue);
        expect(
          r.state.player.wallet,
          s.player.wallet - FertilityTreatment.prototypeOnlyCost,
        );
        expect(r.state.player.stats.happiness,
            lessThan(s.player.stats.happiness));
        expect(r.state.ivfAttempts, 1);
        return;
      }
      fail('Hiç başarısız deneme çıkmadı');
    });

    test('başarılı deneme hamilelik başlatır', () {
      for (int seed = 0; seed < 100; seed++) {
        final GameState s = cift();
        final FamilyResult r = FertilityTreatment.attempt(s, Random(seed));
        if (!r.state.isExpecting) continue;
        expect(r.state.pregnancy!.partnerId, 'sevgili-1');
        expect(r.state.unprotectedTries, 0,
            reason: 'Bekleyiş bitti, sayaç sıfırlanmalı');
        expect(r.state.player.stats.happiness,
            greaterThan(s.player.stats.happiness));
        expect(
          r.state.player.wallet,
          s.player.wallet - FertilityTreatment.prototypeOnlyCost,
        );
        return;
      }
      fail('Hiç başarılı deneme çıkmadı');
    });

    test('kısır çift de sonunda çocuk sahibi olabilir', () {
      // Paket 25'ten beri kısır çiftin tıbbi çıkışı yoktu; artık var.
      GameState s = cift(partnerInfertile: true);
      bool oldu = false;
      for (int yil = 0; yil < 60 && !oldu; yil++) {
        final FamilyResult r = FertilityTreatment.attempt(s, Random(yil));
        if (r.state.isExpecting) {
          oldu = true;
          break;
        }
        // Yeni yıl: sayaç sıfırlanır, cüzdan doldurulur.
        s = r.state.copyWith(
          interactionCounts: const <String, int>{},
          player: r.state.player.copyWith(wallet: 1000000),
        );
      }
      expect(oldu, isTrue, reason: 'Kısır çiftin şansı gerçekten olmalı');
    });

    test('hiçbir metin "kısır" demez', () {
      for (int seed = 0; seed < 40; seed++) {
        final GameState s = cift(playerInfertile: true);
        final FamilyResult r = FertilityTreatment.attempt(s, Random(seed));
        expect(r.outcome.text.toLowerCase(), isNot(contains('kısır')));
      }
      expect(
        FertilityTreatment.blockReason(cift(tries: 0)).toLowerCase(),
        isNot(contains('kısır')),
      );
    });

    test('engelliyken durum hiç değişmez', () {
      final GameState s = cift(tries: 0);
      final FamilyResult r = FertilityTreatment.attempt(s, Random(1));
      expect(r.outcome.applied, isFalse);
      expect(r.state.player.wallet, s.player.wallet);
      expect(r.state.ivfAttempts, 0);
      expect(r.state.isExpecting, isFalse);
    });
  });

  test('deneme sayısı kayda girer', () {
    GameState s = cift();
    s = FertilityTreatment.attempt(s, Random(5)).state;
    final GameState geri = decodeGameState(encodeGameState(s));
    expect(geri.ivfAttempts, s.ivfAttempts);
  });

  test('eski kayıtta alan yoksa sıfır okunur', () {
    final Map<String, Object?> json =
        Map<String, Object?>.from(encodeGameState(cift()));
    json.remove('ivfAttempts');
    expect(decodeGameState(json).ivfAttempts, 0);
  });
}
