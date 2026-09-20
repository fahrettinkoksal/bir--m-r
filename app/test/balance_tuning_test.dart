import 'dart:convert';
import 'dart:math';

import 'package:bir_omur/data/job_catalog.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/data/save/save_service.dart';
import 'package:bir_omur/data/save/save_store.dart';
import 'package:bir_omur/data/shop_catalog.dart';
import 'package:bir_omur/domain/casino/blackjack.dart';
import 'package:bir_omur/domain/casino/casino_rules.dart';
import 'package:bir_omur/domain/casino/roulette.dart';
import 'package:bir_omur/domain/economy/living_costs.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/generation/life_progression.dart';
import 'package:bir_omur/domain/life/mortality.dart';
import 'package:bir_omur/domain/models/career.dart';
import 'package:bir_omur/domain/models/game_settings.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/owned_item.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:flutter_test/flutter_test.dart';

GameState hayat(int seed, {int age = 30, int wallet = 0}) {
  final GameState state =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  return state.copyWith(
    player: state.player.copyWith(age: age, wallet: wallet),
  );
}

/// Bağımsız yaşayan (hanede yetişkin yok), belirli işte çalışan oyuncu.
GameState calisan(
  int seed, {
  required String jobId,
  int wallet = 0,
  int age = 30,
  bool aileYaninda = false,
}) {
  final GameState base = hayat(seed, age: age, wallet: wallet);
  return base.copyWith(
    people: aileYaninda
        ? base.people
        : List<Person>.unmodifiable(
            base.people
                .map((Person p) => p.copyWith(inPlayerHousehold: false))
                .toList(growable: false),
          ),
    career: CareerState(jobId: jobId, startedAtAge: age - 1, lastPaidAge: age),
  );
}

void main() {
  // ===================================================================
  // 1) Geçim gideri: taban + gelire bağlı pay (D-039)
  // ===================================================================
  group('Geçim gideri formülü (D-039)', () {
    test('gider taban tutar ve gelir payından oluşur', () {
      final GameState garson =
          calisan(1, jobId: 'garson', wallet: 1000000);
      final CostBreakdown dokum = LivingCosts.breakdownFor(garson);

      expect(dokum.situation, LivingSituation.kirada);
      expect(dokum.income, jobById('garson')!.yearlySalary);
      expect(dokum.items.length, 3, reason: 'Kalemler ayrı gösterilebilmeli');
      expect(
        dokum.items.map((({String label, int amount}) e) => e.label),
        containsAll(<String>['Kira', 'Beslenme']),
      );
      expect(dokum.total, dokum.items.fold(0,
          (int t, ({String label, int amount}) e) => t + e.amount));

      // Gelir arttıkça gider artar ama maaştan hızlı artmaz.
      final GameState yazilim =
          calisan(1, jobId: 'yazilim_gelistirici', wallet: 1000000);
      final int garsonGider = LivingCosts.yearlyCost(garson);
      final int yazilimGider = LivingCosts.yearlyCost(yazilim);
      expect(yazilimGider, greaterThan(garsonGider));

      final double garsonOran =
          garsonGider / jobById('garson')!.yearlySalary;
      final double yazilimOran =
          yazilimGider / jobById('yazilim_gelistirici')!.yearlySalary;
      expect(garsonOran, greaterThan(yazilimOran),
          reason: 'Sabit taban düşük gelirde daha ağır basar');
      expect(yazilimOran, greaterThan(0.15),
          reason: 'Yüksek gelirlinin de bütün maaşı birikmemeli');
    });

    test('düşük gelirli bağımsız karakter de birikim yapabilir', () {
      for (final String jobId in <String>['garson', 'magaza_calisani']) {
        final GameState oyuncu = calisan(2, jobId: jobId, wallet: 0);
        final int maas = jobById(jobId)!.yearlySalary;
        final int gider = LivingCosts.yearlyCost(oyuncu);
        final int birikim = maas - gider;

        expect(birikim, greaterThan(0), reason: '$jobId birikim yapabilmeli');
        expect(birikim / maas, greaterThan(0.3),
            reason: '$jobId: maaşın en az üçte biri kalmalı');
      }
    });

    test('yüksek gelirlinin bütün maaşı birikmez', () {
      final GameState yazilim =
          calisan(3, jobId: 'yazilim_gelistirici', wallet: 0);
      final int maas = jobById('yazilim_gelistirici')!.yearlySalary;
      final int birikim = maas - LivingCosts.yearlyCost(yazilim);
      expect(birikim, lessThan(maas * 0.85));
      expect(birikim, greaterThan(maas * 0.6));
    });

    test('üç yaşam düzeni birbirinden farklı', () {
      final GameState ailede =
          calisan(4, jobId: 'ogretmen', wallet: 0, aileYaninda: true);
      final GameState kirada = calisan(4, jobId: 'ogretmen', wallet: 0);
      // Ev sahibi olmak yetmez: oyuncunun o eve **taşınmış** olması gerekir
      // (D-043).
      final GameState evSahibi = kirada.grantItems(
        <String>['kucuk_daire'],
        source: ItemSource.miras,
      );
      final GameState kendiEvi = evSahibi.copyWith(
        residenceItemId: evSahibi.items.last.id,
        movedOut: true,
      );

      final int a = LivingCosts.yearlyCost(ailede);
      final int k = LivingCosts.yearlyCost(kirada);
      final int e = LivingCosts.yearlyCost(kendiEvi);

      expect(LivingCosts.situationOf(ailede), LivingSituation.aileYaninda);
      expect(LivingCosts.situationOf(kirada), LivingSituation.kirada);
      expect(LivingCosts.situationOf(kendiEvi), LivingSituation.kendiEvinde);
      expect(a, lessThan(e));
      expect(e, lessThan(k), reason: 'Kendi evinde kira yok');
    });

    test('çocukta gider yok, maaşsız yetişkinde yalnızca taban var', () {
      final GameState cocuk = hayat(5, age: 12, wallet: 10000);
      expect(LivingCosts.yearlyCost(cocuk), 0);

      final GameState issiz = hayat(5, age: 30, wallet: 10000).copyWith(
        people: const <Person>[],
      );
      final int gider = LivingCosts.yearlyCost(issiz);
      expect(gider, greaterThan(0));
      expect(LivingCosts.breakdownFor(issiz).income, 0);
    });

    test('gider yılda bir kez uygulanır ve iki kez düşmez', () {
      final GameState oyuncu =
          calisan(6, jobId: 'ogretmen', wallet: 500000, age: 30);
      final int maas = jobById('ogretmen')!.yearlySalary;

      final GameState sonra = LifeProgression(Random(1))
          .advanceOneYear(oyuncu.copyWith(pendingEvent: null));
      final int gider = LivingCosts.yearlyCost(sonra);

      expect(sonra.player.wallet, 500000 + maas - gider);
      expect(
        sonra.log
            .where((dynamic e) => (e.text as String).contains('geçim gider'))
            .length,
        1,
      );
    });
  });

  // ===================================================================
  // 2) Ebeveyn yaşları ve ölüm eğrisi (D-041, D-036)
  // ===================================================================
  group('Ebeveyn yaşları ve ölüm (D-041)', () {
    test('uç ebeveyn yaşları mümkün ama seyrek', () {
      final List<int> anneYaslari = <int>[];
      for (int seed = 0; seed < 600; seed++) {
        final GameState state =
            LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
        for (final Person p in state.people) {
          if (p.relation == RelationType.anne) {
            anneYaslari.add(p.age - state.player.age);
          }
        }
      }

      final int enKucuk = anneYaslari.reduce(min);
      final int enBuyuk = anneYaslari.reduce(max);
      final double ortalama =
          anneYaslari.reduce((int a, int b) => a + b) / anneYaslari.length;

      // Aralık korunur: çok genç ve ileri yaş anne mümkün.
      expect(enKucuk, lessThanOrEqualTo(20));
      expect(enBuyuk, greaterThanOrEqualTo(40));
      // Ama dağılım tepe noktası çevresinde toplanır.
      expect(ortalama, closeTo(LifeGenerator.prototypeOnlyMotherAgePeak, 5));

      final int uclar = anneYaslari
          .where((int y) => y <= 19 || y >= 42)
          .length;
      expect(uclar / anneYaslari.length, lessThan(0.12),
          reason: 'Uç yaşlar gereğinden sık seçilmemeli');
    });

    test('ölüm eğrisi yaşla artmaya devam eder', () {
      double p(int age) => Mortality.prototypeOnlyYearlyChance(age);
      expect(p(80), lessThan(p(87)));
      expect(p(87), lessThan(p(92)));
      expect(p(92), lessThan(p(97)));
      expect(p(97), lessThan(p(102)));
      // Genç yetişkin ölümü artırılmadı.
      expect(p(25), lessThan(0.002));
      expect(p(45), lessThan(0.006));
    });

    test('sağlık 100 olsa da ölüm mümkün', () {
      expect(
        Mortality.prototypeOnlyYearlyChance(90, health: 100),
        greaterThan(0),
      );
      int olen = 0;
      for (int seed = 0; seed < 200; seed++) {
        if (Mortality.diesThisYear(95, Random(seed), health: 100)) olen++;
      }
      expect(olen, greaterThan(0), reason: 'Sağlık ölümsüzlük vermez');
    });
  });

  // ===================================================================
  // 3) Araç aksesuarı yaşları (D-042)
  // ===================================================================
  group('Araç aksesuarı yaşları (D-042)', () {
    test('otomobil aksesuarları 18, motosiklet kaskı 16', () {
      for (final String id in <String>[
        'arac_kamerasi',
        'tavan_bagaji',
        'bebek_koltugu',
      ]) {
        expect(shopProductByTypeId(id)!.minAge, 18, reason: id);
      }
      expect(shopProductByTypeId('kask')!.minAge, 16);
      expect(shopProductByTypeId('motosiklet_cantasi')!.minAge, 16);

      final List<ShopProduct> onYedi =
          shopProductsIn(ShopCategory.aracGalerisi, 17);
      expect(
        onYedi.any((ShopProduct p) => p.typeId == 'tavan_bagaji'),
        isFalse,
      );
      expect(onYedi.any((ShopProduct p) => p.typeId == 'kask'), isTrue);
    });

    test('aksesuar veya araç sahipliği sürme hakkı vermez', () {
      final GameState genc = hayat(10, age: 16)
          .grantItems(<String>['otomobil_ekonomik'], source: ItemSource.miras)
          .grantItems(<String>['kask'], source: ItemSource.satinAlma);

      final OwnedItem araba =
          genc.items.firstWhere((OwnedItem i) => i.typeId.startsWith('otomobil'));
      expect(genc.licenses, isEmpty);
      expect(araba.isVehicle, isTrue);
      // Ehliyet olmadan sürme eylemi kapalı kalır.
      expect(genc.hasLicense('otomobil_ehliyeti'), isFalse);
    });
  });

  // ===================================================================
  // 4) Bahis bütçesi (D-040)
  // ===================================================================
  group('Bahis bütçesi (D-040)', () {
    const Roulette roulette = Roulette();
    const Blackjack blackjack = Blackjack();

    test('bütçe gelire ve cüzdana göre değişir', () {
      final GameState garson =
          calisan(20, jobId: 'garson', wallet: 20000);
      final GameState yazilim =
          calisan(20, jobId: 'yazilim_gelistirici', wallet: 20000);

      final int garsonButce = CasinoAccess.yearlyBudget(garson);
      final int yazilimButce = CasinoAccess.yearlyBudget(yazilim);

      expect(garsonButce, lessThan(yazilimButce));
      expect(CasinoAccess.maxBet(garson), lessThan(CasinoAccess.maxBet(yazilim)));
      // Düşük gelirli büyük bahse yönlendirilmez.
      expect(CasinoAccess.maxBet(garson),
          lessThan(CasinoRules.prototypeOnlyMaxYearlyBudget ~/ 10));
    });

    test('düşük gelirli de küçük bahisle oynayabilir', () {
      final GameState garson = calisan(21, jobId: 'garson', wallet: 5000);
      expect(
        CasinoAccess.checkBet(garson, CasinoRules.prototypeOnlyMinBet)
            .isAllowed,
        isTrue,
      );
      expect(CasinoRules.prototypeOnlyBetSteps(CasinoAccess.maxBet(garson))
          .first,
          greaterThanOrEqualTo(CasinoRules.prototypeOnlyMinBet));
    });

    test('maaşsız mirasçı tamamen engellenmez', () {
      final GameState mirasci = hayat(22, age: 40, wallet: 800000)
          .copyWith(people: const <Person>[]);
      expect(LivingCosts.yearlyIncome(mirasci), 0);

      final int butce = CasinoAccess.yearlyBudget(mirasci);
      expect(butce, greaterThan(CasinoRules.prototypeOnlyMinYearlyBudget));
      expect(
        CasinoAccess.checkBet(mirasci, CasinoAccess.maxBet(mirasci)).isAllowed,
        isTrue,
      );
    });

    test('bütçe üst sınırı aşılmaz', () {
      final GameState cokZengin = calisan(23,
          jobId: 'yazilim_gelistirici', wallet: 50000000);
      expect(CasinoAccess.yearlyBudget(cokZengin),
          CasinoRules.prototypeOnlyMaxYearlyBudget);
    });

    test('oyuncunun kendi limiti sistem limitinden düşükse o geçerlidir', () {
      final GameState yazilim = calisan(24,
          jobId: 'yazilim_gelistirici', wallet: 200000);
      final int sistem = CasinoRules.prototypeOnlyYearlyBudget(
        disposableIncome: CasinoAccess.disposableIncome(yazilim),
        wallet: yazilim.player.wallet,
      );
      expect(sistem, greaterThan(20000));

      final GameState kendiLimiti = yazilim.copyWith(
        settings: const GameSettings(wagerLimitPerAge: 20000),
      );
      expect(CasinoAccess.yearlyBudget(kendiLimiti), 20000);

      // Kendi limiti sistemden büyükse sistem geçerlidir.
      final GameState yuksekLimit = yazilim.copyWith(
        settings: const GameSettings(wagerLimitPerAge: 10000000),
      );
      expect(CasinoAccess.yearlyBudget(yuksekLimit), sistem);
    });

    test('bahis cüzdandan bir kez düşer, bütçe iki kez sayılmaz', () {
      final GameState oyuncu =
          calisan(25, jobId: 'ogretmen', wallet: 300000);
      final int bahis = CasinoRules.prototypeOnlyBetSteps(
        CasinoAccess.maxBet(oyuncu),
      ).first;

      final CasinoResult r = roulette.spin(
        oyuncu,
        RouletteBetType.kirmizi,
        bahis,
        Random(3),
      );
      expect(r.outcome.applied, isTrue);
      expect(r.state.wagerThisAge, bahis);
      final int cuzdan = r.state.player.wallet;
      expect(cuzdan, anyOf(oyuncu.player.wallet - bahis,
          oyuncu.player.wallet + bahis));

      // Blackjack elinde bahis yalnızca el açılırken sayılır.
      final CasinoResult el = blackjack.deal(r.state, bahis, Random(4));
      expect(el.state.wagerThisAge, bahis * 2);
      final CasinoResult dur = blackjack.stand(el.state);
      expect(dur.state.wagerThisAge, bahis * 2,
          reason: 'Sonuç bahsi ikinci kez saymamalı');
    });

    test('kumarhane kapalıyken bütçe hesabı oyunu açmaz', () {
      final GameState kapali = calisan(26, jobId: 'ogretmen', wallet: 300000)
          .copyWith(settings: const GameSettings(casinoEnabled: false));
      expect(CasinoAccess.check(kapali).isAllowed, isFalse);
      expect(
        blackjack.deal(kapali, CasinoRules.prototypeOnlyMinBet, Random(1))
            .outcome
            .applied,
        isFalse,
      );
    });
  });

  // ===================================================================
  // Eski kayıtlar
  // ===================================================================
  group('Eski kayıt uyumu', () {
    test('sürüm 11 kaydı yeni denge ile açılır', () async {
      final GameState state =
          calisan(30, jobId: 'ogretmen', wallet: 250000);
      final Map<String, Object?> body = encodeGameState(state);
      body
        ..remove('pastLives')
        ..remove('settings')
        ..remove('grief')
        ..remove('hardshipYears')
        ..remove('careStatus');

      final SaveLoadResult result = await SaveService(
        MemorySaveStore(
          initial: jsonEncode(
            <String, Object?>{'formatVersion': 11, 'state': body},
          ),
        ),
      ).load();
      expect(result.isLoaded, isTrue, reason: result.message);

      final GameState geri = result.state!;
      expect(geri.player.wallet, 250000);
      expect(geri.career.jobId, 'ogretmen');
      expect(geri.wagerThisAge, state.wagerThisAge);
      // Yeni gider ve bütçe hesapları eski kayıtta da çalışır.
      expect(LivingCosts.yearlyCost(geri), greaterThan(0));
      expect(CasinoAccess.yearlyBudget(geri), greaterThan(0));
    });

    test('kaydedilip yüklenen durumda gider ikinci kez uygulanmaz', () async {
      final GameState state =
          calisan(31, jobId: 'magaza_calisani', wallet: 400000);
      final GameState birYilSonra = LifeProgression(Random(2))
          .advanceOneYear(state.copyWith(pendingEvent: null));

      final SaveService service = SaveService(MemorySaveStore());
      await service.save(birYilSonra);
      final GameState geri = (await service.load()).state!;

      expect(geri.player.wallet, birYilSonra.player.wallet,
          reason: 'Yükleme gideri yeniden uygulamamalı');
      expect(geri.hardshipYears, birYilSonra.hardshipYears);
      expect(
        geri.log.where((dynamic e) =>
            (e.text as String).contains('geçim gider')).length,
        birYilSonra.log.where((dynamic e) =>
            (e.text as String).contains('geçim gider')).length,
      );
    });
  });
}
