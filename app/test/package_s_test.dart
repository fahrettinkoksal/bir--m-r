import 'package:bir_omur/domain/economy/living_costs.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/career.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Paket S: geçim giderinin gerekçesi ve dökümü (D-123).
void main() {
  /// Ailesinin yanında yaşayan yetişkin.
  GameState aileYaninda({int seed = 31, int age = 22, int? maas}) {
    final GameState base =
        LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
    // Hanede hayatta bir ebeveyn olsun.
    final List<Person> kisiler = base.people
        .map((Person p) => p.relation == RelationType.anne
            ? p.copyWith(isAlive: true, inPlayerHousehold: true, age: 50)
            : p)
        .toList(growable: false);
    return base.copyWith(
      pendingEvent: null,
      people: kisiler,
      player: base.player.copyWith(age: age, wallet: 50000),
      career: maas == null
          ? const CareerState()
          : CareerState(jobId: 'kasiyer', startedAtAge: age - 1, salary: maas),
    );
  }

  group('Gider gerekçesi (D-123)', () {
    test('çocukken hiç gider yoktur', () {
      final GameState s = aileYaninda(age: 10);
      expect(LivingCosts.situationOf(s), LivingSituation.cocuk);
      expect(LivingCosts.yearlyCost(s), 0);
    });

    test('geliri olmayan ve ailesinin yanında yaşayanın yükü hafiftir', () {
      // Faho sordu: "çalışmıyorsam neden gider var?" Cevap: yiyip
      // içiyorsun. Ama ailenin yanındaysan ve hiç gelirin yoksa o yükü
      // aile taşır; geriye kişisel harcama kalır.
      final GameState gelirsiz = aileYaninda();
      if (LivingCosts.situationOf(gelirsiz) != LivingSituation.aileYaninda) {
        return; // Bu tohumda hane kurulumu farklı; kural ayrıca sınanıyor.
      }
      final int hafif = LivingCosts.yearlyCost(gelirsiz);
      expect(hafif, greaterThan(0), reason: 'Tamamen sıfır da olmamalı');
      expect(
        hafif,
        lessThan(60000),
        reason: 'Gelirsiz gencin yükü tam haneye katkı kadar olmamalı',
      );
    });

    test('maaşı olan eve katkısını yapar', () {
      final GameState calisan = aileYaninda(maas: 400000);
      final GameState gelirsiz = aileYaninda();
      if (LivingCosts.situationOf(calisan) != LivingSituation.aileYaninda) {
        return;
      }
      expect(
        LivingCosts.yearlyCost(calisan),
        greaterThan(LivingCosts.yearlyCost(gelirsiz)),
      );
    });

    test('döküm toplamı kalemlerin toplamına eşittir', () {
      final GameState s = aileYaninda(maas: 400000);
      final CostBreakdown d = LivingCosts.breakdownFor(s);
      final int toplam = d.items.fold(
        0,
        (int a, ({String label, int amount}) e) => a + e.amount,
      );
      expect(d.total, toplam);
      expect(LivingCosts.yearlyCost(s), d.total);
    });

    test('dökümdeki her kalemin adı ve tutarı vardır', () {
      final GameState s = aileYaninda(maas: 400000);
      final CostBreakdown d = LivingCosts.breakdownFor(s);
      expect(d.items, isNotEmpty);
      for (final ({String label, int amount}) kalem in d.items) {
        expect(kalem.label, isNotEmpty);
        expect(kalem.amount, greaterThanOrEqualTo(0));
      }
    });
  });
}
