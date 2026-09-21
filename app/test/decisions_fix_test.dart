import 'dart:convert';
import 'dart:math';

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
import 'package:bir_omur/domain/life/inheritance.dart';
import 'package:bir_omur/domain/models/game_settings.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/life_summary.dart';
import 'package:bir_omur/domain/models/owned_item.dart';
import 'package:bir_omur/domain/models/parental_status.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:bir_omur/text/turkish_text.dart';
import 'package:flutter_test/flutter_test.dart';

GameState hayat(int seed, {int age = 30, int wallet = 0}) {
  final GameState state =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  return state.copyWith(
    player: state.player.copyWith(age: age, wallet: wallet),
  );
}

GameState vefatEttir(GameState state, bool Function(Person) secici) {
  final List<Person> people = state.people
      .map((Person p) => secici(p)
          ? p.copyWith(isAlive: false, inPlayerHousehold: false)
          : p)
      .toList(growable: false);
  return state.copyWith(people: List<Person>.unmodifiable(people));
}

void main() {
  // ===================================================================
  // D-033: yıllık geçim gideri
  // ===================================================================
  group('Yaşam gideri (D-033)', () {
    test('çocuğa yetişkin gideri yüklenmez', () {
      final GameState cocuk = hayat(1, age: 10, wallet: 5000);
      expect(LivingCosts.yearlyCost(cocuk), 0);

      final GameState sonra = LivingCosts.apply(cocuk).state;
      expect(sonra.player.wallet, 5000);
      expect(LivingCosts.apply(cocuk).logText, isNull);
    });

    test('ailesiyle yaşayan ile bağımsız yaşayanın gideri farklı', () {
      final GameState aileYaninda = hayat(2, age: 25, wallet: 500000);
      expect(LivingCosts.livesWithFamily(aileYaninda), isTrue);
      final int aileGideri = LivingCosts.yearlyCost(aileYaninda);

      // Hanedeki bütün yetişkinler ayrılırsa oyuncu bağımsız yaşar.
      final GameState bagimsiz = aileYaninda.copyWith(
        people: List<Person>.unmodifiable(
          aileYaninda.people
              .map((Person p) => p.copyWith(inPlayerHousehold: false))
              .toList(growable: false),
        ),
      );
      final int bagimsizGider = LivingCosts.yearlyCost(bagimsiz);

      expect(LivingCosts.situationOf(aileYaninda),
          LivingSituation.aileYaninda);
      expect(LivingCosts.situationOf(bagimsiz), LivingSituation.kirada);
      expect(bagimsizGider, greaterThan(aileGideri));
    });

    test('kendi evi olan bağımsız yetişkin daha az öder', () {
      GameState bagimsiz = hayat(3, age: 30, wallet: 500000).copyWith(
        people: const <Person>[],
      );
      final int kirada = LivingCosts.yearlyCost(bagimsiz);
      bagimsiz = bagimsiz.grantItems(
        <String>['kucuk_daire'],
        source: ItemSource.satinAlma,
      );
      // Ev almak taşınmak değildir; oturmak için taşınmak gerekir (D-043).
      bagimsiz = bagimsiz.copyWith(
        residenceItemId: bagimsiz.items.last.id,
        movedOut: true,
      );
      final int kendiEvi = LivingCosts.yearlyCost(bagimsiz);

      expect(LivingCosts.situationOf(bagimsiz), LivingSituation.kendiEvinde);
      expect(kendiEvi, lessThan(kirada),
          reason: 'Kendi evinde kira ödenmez');
    });

    test('gider cüzdandan bir kez düşer ve günlüğe yazılır', () {
      final GameState state = hayat(4, age: 25, wallet: 500000);
      final int gider = LivingCosts.yearlyCost(state);
      final ({GameState state, String? logText}) sonuc =
          LivingCosts.apply(state);

      expect(sonuc.state.player.wallet, 500000 - gider);
      // Tutar günlükte Türkçe binlik ayırıcıyla yazılır (20.000 ₺).
      expect(sonuc.logText, contains(trMoney(gider)));
      expect(sonuc.state.hardshipYears, 0);
    });

    test('para yetmezse cüzdan eksiye düşmez, geçim sıkıntısı yazılır', () {
      final GameState fakir = hayat(5, age: 25, wallet: 1000);
      final ({GameState state, String? logText}) sonuc =
          LivingCosts.apply(fakir);

      expect(sonuc.state.player.wallet, 0);
      expect(sonuc.state.player.wallet, greaterThanOrEqualTo(0));
      expect(sonuc.state.hardshipYears, 1);
      expect(sonuc.logText, contains('geçim sıkıntısı'));

      // Sıkıntı sürerse sayaç artar, para borçlanmaz.
      final ({GameState state, String? logText}) ikinci =
          LivingCosts.apply(sonuc.state);
      expect(ikinci.state.hardshipYears, 2);
      expect(ikinci.state.player.wallet, 0);
    });

    test('yaş alırken maaş ve gider bir kez uygulanır', () {
      final GameState state = hayat(6, age: 25, wallet: 300000);
      final GameState sonra =
          LifeProgression(Random(1)).advanceOneYear(state);

      // Çalışmıyor: yalnızca gider düşer.
      expect(
        sonra.player.wallet,
        300000 - LivingCosts.yearlyCost(sonra),
      );
      expect(
        sonra.log.where((dynamic e) =>
            (e.text as String).contains('geçim gider')).length,
        1,
        reason: 'Gider yılda bir kez yazılmalı',
      );
    });
  });

  // ===================================================================
  // D-036: yas zamanla hafifler
  // ===================================================================
  group('Yas (D-036)', () {
    test('kayıp mutluluğu düşürür ama yas kalıcı ceza değildir', () {
      // Yeni kayıp olmasın diye kişi listesi boş; yalnızca yasın
      // hafiflemesi ölçülür.
      final GameState temel = hayat(10, age: 40)
          .copyWith(people: const <Person>[], pendingEvent: null);
      final int mutlulukOnce = temel.player.stats.happiness;

      GameState state = temel.copyWith(
        grief: 12,
        player: temel.player.copyWith(
          stats: temel.player.stats.copyWith(
            happiness: (mutlulukOnce - 12).clamp(0, 100),
          ),
        ),
      );
      final int dusukMutluluk = state.player.stats.happiness;

      for (int i = 0; i < 4 && !state.deceased; i++) {
        state = LifeProgression(Random(20 + i))
            .advanceOneYear(state)
            .copyWith(pendingEvent: null);
      }

      expect(state.grief, lessThan(12));
      expect(state.player.stats.happiness, greaterThan(dusukMutluluk));
    });

    test('yas tamamen biter', () {
      GameState state = hayat(11, age: 35)
          .copyWith(people: const <Person>[], pendingEvent: null, grief: 9);
      for (int i = 0; i < 12 && state.grief > 0 && !state.deceased; i++) {
        state = LifeProgression(Random(30 + i))
            .advanceOneYear(state)
            .copyWith(pendingEvent: null);
      }
      expect(state.grief, 0);
    });
  });

  // ===================================================================
  // D-037: eş payı, bakım durumu, arşiv
  // ===================================================================
  group('Miras ve bakım (D-037)', () {
    GameState ebeveynMirasi(int seed, ParentalStatus durum) {
      GameState state = hayat(seed, age: 30).copyWith(parentalStatus: durum);
      // Anne ve baba hayatta, anne varlıklı; sonra anne vefat eder.
      final List<Person> people = state.people.map((Person p) {
        if (p.relation == RelationType.anne) {
          return p.copyWith(
            isAlive: true,
            wealth: WealthTier.varlikli,
            estate: const <String>[],
          );
        }
        if (p.relation == RelationType.baba) {
          return p.copyWith(isAlive: true);
        }
        return p;
      }).toList(growable: false);
      state = state.copyWith(people: List<Person>.unmodifiable(people));
      return vefatEttir(state, (Person p) => p.relation == RelationType.anne);
    }

    test('boşanmış ebeveyn eş payı almaz', () {
      final GameState evli = ebeveynMirasi(20, ParentalStatus.evli);
      final GameState bosanmis = ebeveynMirasi(20, ParentalStatus.bosanmis);

      Person anne(GameState s) =>
          s.people.firstWhere((Person p) => p.relation == RelationType.anne);

      final InheritanceShare evliPay =
          Inheritance.shareFor(evli, anne(evli));
      final InheritanceShare bosanmisPay =
          Inheritance.shareFor(bosanmis, anne(bosanmis));

      expect(bosanmisPay.money, greaterThan(evliPay.money),
          reason: 'Eş payı ayrılmışsa çocuklara kalır');
    });

    test('sevgili eş sayılmaz ve mirasçı olmaz', () {
      GameState state = hayat(21, age: 25);
      final List<Person> people = <Person>[
        ...state.people,
        Person(
          id: 'sevgili-1',
          firstName: 'Deniz',
          lastName: 'Yıldız',
          gender: state.player.gender,
          relation: RelationType.sevgili,
          age: 25,
          isAlive: false,
          inPlayerHousehold: false,
          employment: EmploymentStatus.calisiyor,
          occupation: 'öğretmen',
          wealth: WealthTier.cokVarlikli,
          bond: 80,
          estate: const <String>['kol_saati'],
        ),
      ];
      state = state.copyWith(people: List<Person>.unmodifiable(people));

      final Person sevgili =
          state.people.firstWhere((Person p) => p.id == 'sevgili-1');
      final InheritanceShare pay = Inheritance.shareFor(state, sevgili);
      expect(pay.money, 0);
      expect(pay.itemTypeIds, isEmpty);

      final ({GameState state, List<String> logLines}) sonuc =
          Inheritance.settle(state, sevgili);
      expect(sonuc.logLines, isEmpty);
      expect(sonuc.state.player.wallet, state.player.wallet);
    });

    test('bakım veren yoksa açık bir bakım durumu oluşur', () {
      GameState state = hayat(22, age: 9);
      // Bütün yetişkin akrabalar vefat etsin.
      state = vefatEttir(state, (Person p) => p.age >= 18);
      final int kisiSayisi = state.people.length;

      final GameState sonra =
          LifeProgression(Random(5)).advanceOneYear(state);

      expect(sonra.people.length, kisiSayisi,
          reason: 'Sahte kişi üretilmemeli');
      expect(sonra.careStatus, CareStatus.kurumBakimi);
      expect(
        sonra.log.any((dynamic e) =>
            (e.text as String).contains('bakımın kurum')),
        isTrue,
      );
    });

    test('hayattaki yakın akraba bakım veren olur', () {
      GameState state = hayat(23, age: 8);
      // Hanedeki yetişkinler vefat etsin; hane dışında yaşayan yetişkin
      // akraba hayatta kalsın.
      state = vefatEttir(
        state,
        (Person p) => p.inPlayerHousehold && p.age >= 18,
      );
      final bool uygunVar = state.people.any((Person p) =>
          p.isAlive && !p.inPlayerHousehold && p.age >= 18);

      final GameState sonra =
          LifeProgression(Random(6)).advanceOneYear(state);

      if (uygunVar) {
        expect(sonra.careStatus, CareStatus.yakinAkraba);
        expect(
          sonra.householdMembers.any((Person p) => p.age >= 18),
          isTrue,
        );
      } else {
        expect(sonra.careStatus, CareStatus.kurumBakimi);
      }
      expect(sonra.people.length, state.people.length);
    });

    test('kişilerin mal varlığı hayat boyunca değişebilir', () {
      GameState state = hayat(24, age: 30);
      final Map<String, int> once = <String, int>{
        for (final Person p in state.people) p.id: p.estate.length,
      };

      for (int i = 0; i < 20 && !state.deceased; i++) {
        // Ekrandaki olay yaş ilerlemesini durdurur; testte temizlenir.
        state = LifeProgression(Random(40 + i))
            .advanceOneYear(state.copyWith(pendingEvent: null));
      }

      final bool degisenVar = state.people.any((Person p) =>
          once.containsKey(p.id) && p.estate.length != once[p.id]);
      expect(degisenVar, isTrue,
          reason: 'Miras donmuş bir servet listesine dayanmamalı');
    });
  });

  // ===================================================================
  // D-037: Geçmiş Hayatlar arşivi
  // ===================================================================
  group('Geçmiş Hayatlar arşivi (D-037)', () {
    GameState olmusHayat(int seed) => hayat(seed, age: 82, wallet: 1234)
        .copyWith(deceased: true, deathAge: 82, deathCause: 'yaşlılık');

    test('yeni hayat geçmiş hayat özetini silmez', () {
      final GameController c = GameController(random: Random(50));
      c.debugSetState(olmusHayat(50));
      final String ad = c.state!.player.fullName;

      c.startNewLife(mode: StartMode.tamamenRastgele, seed: 51);

      expect(c.state!.deceased, isFalse, reason: 'Yeni hayat başladı');
      expect(c.state!.pastLives.length, 1);
      final LifeSummary ozet = c.state!.pastLives.single;
      expect(ozet.fullName, ad);
      expect(ozet.deathAge, 82);
      expect(ozet.deathCause, 'yaşlılık');
      expect(ozet.wallet, 1234);
    });

    test('arşiv birden çok hayatı biriktirir', () {
      final GameController c = GameController(random: Random(52));
      c.debugSetState(olmusHayat(52));
      c.startNewLife(mode: StartMode.tamamenRastgele, seed: 53);

      // İkinci hayat da tamamlanır.
      c.debugSetState(
        c.state!.copyWith(deceased: true, deathAge: 70, deathCause: 'hastalık'),
      );
      c.startNewLife(mode: StartMode.tamamenRastgele, seed: 54);

      expect(c.state!.pastLives.length, 2);
      expect(c.state!.pastLives.last.deathAge, 70);
    });

    test('tamamlanmamış hayat arşive yazılmaz', () {
      final GameController c = GameController(random: Random(55));
      c.startNewLife(mode: StartMode.tamamenRastgele, seed: 55);
      c.startNewLife(mode: StartMode.tamamenRastgele, seed: 56);
      expect(c.state!.pastLives, isEmpty);
    });

    test('arşiv kaydedilip geri okunur', () async {
      final GameController c = GameController(random: Random(57));
      c.debugSetState(olmusHayat(57));
      c.startNewLife(mode: StartMode.tamamenRastgele, seed: 58);

      final SaveService service = SaveService(MemorySaveStore());
      await service.save(c.state!);
      final SaveLoadResult result = await service.load();
      expect(result.isLoaded, isTrue, reason: result.message);
      expect(result.state!.pastLives.length, 1);
      expect(
        result.state!.pastLives.single.fullName,
        c.state!.pastLives.single.fullName,
      );
      expect(
        result.state!.pastLives.single.highlights,
        c.state!.pastLives.single.highlights,
      );
    });
  });

  // ===================================================================
  // D-032: kumarhane ayarları
  // ===================================================================
  group('Kumarhane ayarları (D-032)', () {
    const Blackjack blackjack = Blackjack();
    const Roulette roulette = Roulette();

    test('kapalı modülde masa açılmaz', () {
      final GameState kapali = hayat(60, age: 30, wallet: 500000).copyWith(
        settings: const GameSettings(casinoEnabled: false),
      );
      final CasinoResult r = blackjack.deal(kapali, 1000, Random(1));
      expect(r.outcome.applied, isFalse);
      expect(r.state.player.wallet, 500000);
      expect(CasinoAccess.check(kapali).isAllowed, isFalse);

      final CasinoResult rulet = roulette.spin(
        kapali,
        RouletteBetType.kirmizi,
        1000,
        Random(1),
      );
      expect(rulet.outcome.applied, isFalse);
    });

    test('oyuncunun kendi limiti bahsi durdurur', () {
      GameState state = hayat(61, age: 30, wallet: 1000000).copyWith(
        settings: const GameSettings(wagerLimitPerAge: 10000),
      );

      // Kendi limiti 10.000 ₺ olduğu için tek bahis en fazla 2.000 ₺ olur.
      final int enFazla = CasinoAccess.maxBet(state);
      expect(enFazla, 2000);

      int oynanan = 0;
      for (int i = 0; i < 20; i++) {
        final CasinoResult r = roulette.spin(
          state,
          RouletteBetType.siyah,
          enFazla,
          Random(i),
        );
        if (!r.outcome.applied) break;
        state = r.state;
        oynanan += enFazla;
      }

      expect(oynanan, 10000, reason: 'Kendi limiti aşılamaz');
      expect(
        roulette.spinAvailability(state, CasinoRules.prototypeOnlyMinBet)
            .reason,
        contains('Kendine koyduğun'),
      );
    });

    test('ayarlar kaydedilip geri okunur', () async {
      final GameState state = hayat(62, age: 30).copyWith(
        settings: const GameSettings(
          casinoEnabled: false,
          wagerLimitPerAge: 25000,
        ),
      );
      final SaveService service = SaveService(MemorySaveStore());
      await service.save(state);
      final GameState geri = (await service.load()).state!;
      expect(geri.settings.casinoEnabled, isFalse);
      expect(geri.settings.wagerLimitPerAge, 25000);
    });
  });

  // ===================================================================
  // D-034: araç satın alma yaşı
  // ===================================================================
  group('Araç satın alma yaşı (D-034)', () {
    test('araçlar 18 yaşından önce galeride görünmez', () {
      const List<String> araclar = <String>[
        'motosiklet_ekonomik',
        'motosiklet_guclu',
        'otomobil_ikinci_el',
        'otomobil_ekonomik',
        'otomobil_orta',
        'otomobil_luks',
      ];
      for (final String id in araclar) {
        expect(shopProductByTypeId(id)!.minAge, 18, reason: id);
      }

      final List<ShopProduct> onYediYas =
          shopProductsIn(ShopCategory.aracGalerisi, 17);
      expect(
        onYediYas.any((ShopProduct p) => araclar.contains(p.typeId)),
        isFalse,
      );
    });

    test('miras yoluyla küçük yaşta araç sahibi olunabilir', () {
      // Sahiplik yaş koşuluna bağlı değildir; yalnızca kullanmak ehliyet
      // ister (D-034).
      final GameState cocuk = hayat(70, age: 12).grantItems(
        <String>['otomobil_ikinci_el'],
        source: ItemSource.miras,
      );
      expect(cocuk.items.single.isVehicle, isTrue);
      expect(cocuk.items.single.source, ItemSource.miras);
    });
  });

  // ===================================================================
  // Kayıt göçü
  // ===================================================================
  group('Sürüm 11 kaydı', () {
    test('arşiv, ayar ve bakım alanları olmadan açılır', () async {
      final GameState state = hayat(80, age: 40, wallet: 7000);
      final Map<String, Object?> body = encodeGameState(state);
      body
        ..remove('pastLives')
        ..remove('careStatus')
        ..remove('grief')
        ..remove('hardshipYears')
        ..remove('settings');

      final SaveLoadResult result = await SaveService(
        MemorySaveStore(
          initial: jsonEncode(
            <String, Object?>{'formatVersion': 21, 'state': body},
          ),
        ),
      ).load();
      expect(result.isLoaded, isTrue, reason: result.message);

      final GameState geri = result.state!;
      expect(geri.pastLives, isEmpty);
      expect(geri.careStatus, CareStatus.aileYaninda);
      expect(geri.grief, 0);
      expect(geri.hardshipYears, 0);
      expect(geri.settings.casinoEnabled, isTrue);
      expect(geri.settings.wagerLimitPerAge, isNull);
      expect(geri.player.wallet, 7000);
      expect(geri.people.length, state.people.length);
    });

    // Not: "tek soruluk eski sınav" biçimi yalnızca sürüm 21 öncesinde
    // vardı. Paket 12'de geriye dönük destek son beş sürümle
    // sınırlandığı için (Faho'nun kararı) o biçim artık hiçbir
    // desteklenen kayıtta bulunamaz; ilgili göç adımı ve testi
    // kaldırıldı. Güncel biçimdeki bekleyen sınav testi yukarıda duruyor.
  });
}
