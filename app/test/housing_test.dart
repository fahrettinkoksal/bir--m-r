import 'dart:convert';
import 'dart:math';

import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/data/save/save_service.dart';
import 'package:bir_omur/data/save/save_store.dart';
import 'package:bir_omur/data/shop_catalog.dart';
import 'package:bir_omur/domain/economy/housing.dart';
import 'package:bir_omur/domain/economy/living_costs.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/generation/life_progression.dart';
import 'package:bir_omur/domain/interaction/item_actions.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/owned_item.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:flutter_test/flutter_test.dart';

const Housing housing = Housing();
const ItemActions items = ItemActions();

GameState oyuncu(int seed, {int age = 30, int wallet = 12000000}) {
  final GameState state =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  return state.copyWith(
    player: state.player.copyWith(age: age, wallet: wallet),
  );
}

GameState evAl(GameState state, {String typeId = 'kucuk_daire', String? sehir}) {
  final ItemActionResult r = items.buy(
    state: state,
    product: shopProductByTypeId(typeId)!,
    location: sehir,
  );
  expect(r.outcome.applied, isTrue, reason: r.outcome.text);
  return r.state;
}

void main() {
  // ===================================================================
  // Taşınma
  // ===================================================================
  group('Taşınma (D-043)', () {
    test('ev almak taşınmak değildir', () {
      final GameState state = evAl(oyuncu(1));
      expect(state.residenceItemId, isNull);
      expect(Housing.residenceOf(state), ResidenceKind.aileYaninda);
      expect(LivingCosts.situationOf(state), LivingSituation.aileYaninda);
    });

    test('kendi evine taşınmak oturumu ve gideri değiştirir', () {
      final GameState state = evAl(oyuncu(2));
      final OwnedItem ev = state.items.last;
      final int aileGideri = LivingCosts.yearlyCost(state);
      final int cuzdan = state.player.wallet;

      final HousingResult r = housing.moveInto(state, ev);
      expect(r.outcome.applied, isTrue);
      expect(r.state.residenceItemId, ev.id);
      expect(Housing.residenceOf(r.state), ResidenceKind.kendiEvinde);
      expect(r.state.player.wallet,
          cuzdan - Housing.prototypeOnlyMoveCost,
          reason: 'Taşınma masrafı bir kez düşer');
      expect(LivingCosts.situationOf(r.state), LivingSituation.kendiEvinde);
      expect(LivingCosts.yearlyCost(r.state), greaterThan(aileGideri));
      expect(r.state.log.last.text, contains('taşı'));
      // Mülk sahipliği değişmez.
      expect(r.state.itemById(ev.id), isNotNull);
    });

    test('kiraya çıkmak ve ailenin yanına dönmek', () {
      final GameState state = oyuncu(3);
      final HousingResult kiraya = housing.moveToRental(state);
      expect(kiraya.outcome.applied, isTrue);
      expect(Housing.residenceOf(kiraya.state), ResidenceKind.kirada);
      expect(LivingCosts.situationOf(kiraya.state), LivingSituation.kirada);

      final HousingResult geri = housing.moveBackToFamily(kiraya.state);
      expect(geri.outcome.applied, isTrue);
      expect(Housing.residenceOf(geri.state), ResidenceKind.aileYaninda);
    });

    test('hanede yetişkin yoksa aileye dönülemez', () {
      GameState state = oyuncu(4).copyWith(movedOut: true);
      state = state.copyWith(
        people: List<Person>.unmodifiable(
          state.people
              .map((Person p) => p.copyWith(inPlayerHousehold: false))
              .toList(growable: false),
        ),
      );
      final HousingResult r = housing.moveBackToFamily(state);
      expect(r.outcome.applied, isFalse);
      expect(Housing.residenceOf(r.state), ResidenceKind.kirada);
    });

    test('18 yaşından küçük taşınamaz', () {
      // Ev yetişkinken alınır; sonra çocuk yaşa bakılır (miras senaryosu).
      final GameState yetiskin = evAl(oyuncu(5));
      final GameState cocuk = yetiskin.copyWith(
        player: yetiskin.player.copyWith(age: 15),
      );
      final OwnedItem ev = cocuk.items.last;
      expect(housing.moveBlockReason(cocuk, ev), contains('18'));
      expect(housing.moveInto(cocuk, ev).outcome.applied, isFalse);
      expect(housing.moveToRental(cocuk).outcome.applied, isFalse);
    });

    test('parası yetmeyen taşınamaz, cüzdan değişmez', () {
      GameState state = evAl(oyuncu(6));
      state = state.copyWith(player: state.player.copyWith(wallet: 1000));
      final OwnedItem ev = state.items.last;

      final HousingResult r = housing.moveInto(state, ev);
      expect(r.outcome.applied, isFalse);
      expect(r.state.player.wallet, 1000);
      expect(r.state.residenceItemId, isNull);
    });

    test('başka şehirdeki eve taşınmak şehri değiştirir', () {
      final GameState state = evAl(oyuncu(7), sehir: 'Trabzon');
      final OwnedItem ev = state.items.last;
      expect(ev.location, 'Trabzon');

      final HousingResult r = housing.moveInto(state, ev);
      expect(r.state.player.currentCity, 'Trabzon');
      expect(Housing.cityOf(r.state), 'Trabzon');
      expect(r.state.player.birthCity, state.player.birthCity,
          reason: 'Doğum şehri değişmez');
    });
  });

  // ===================================================================
  // Kiraya verme ve kira geliri
  // ===================================================================
  group('Kira geliri (D-043)', () {
    test('oturulan ev kiraya verilemez, kiradaki eve taşınılamaz', () {
      final GameState state = evAl(oyuncu(10));
      final OwnedItem ev = state.items.last;
      final GameState oturan = housing.moveInto(state, ev).state;

      expect(housing.rentOutBlockReason(oturan, oturan.itemById(ev.id)!),
          contains('taşınman'));
      expect(housing.rentOut(oturan, oturan.itemById(ev.id)!).outcome.applied,
          isFalse);

      // Kiraya verilmiş eve taşınılamaz.
      final GameState kiralik = housing.rentOut(state, ev).state;
      expect(kiralik.itemById(ev.id)!.rentedOut, isTrue);
      expect(housing.moveInto(kiralik, kiralik.itemById(ev.id)!)
          .outcome
          .applied,
          isFalse);
    });

    test('kira geliri yılda bir kez cüzdana girer', () {
      final GameState state = evAl(oyuncu(11));
      final OwnedItem ev = state.items.last;
      final GameState kiralik = housing.rentOut(state, ev).state;
      final int kira = Housing.yearlyRentOf(ev);
      expect(kira, greaterThan(0));
      expect(Housing.yearlyRentIncome(kiralik), kira);

      int kiraliYil = 0;
      GameState akan = kiralik;
      for (int i = 0; i < 10 && !akan.deceased; i++) {
        final int once = akan.player.wallet;
        akan = LifeProgression(Random(i))
            .advanceOneYear(akan.copyWith(pendingEvent: null));
        final int gelirSatiri = akan.log
            .where((dynamic e) =>
                (e.text as String).contains('kira geliri aldın'))
            .length;
        expect(gelirSatiri, lessThanOrEqualTo(i + 1),
            reason: 'Kira yılda bir kez ödenir');
        if (akan.player.wallet > once) kiraliYil++;
      }
      expect(kiraliYil, greaterThan(0), reason: 'Kira geliri gerçekten gelmeli');
    });

    test('kira geliri ekonomiye katılır', () {
      final GameState state = evAl(oyuncu(12));
      final GameState kiralik =
          housing.rentOut(state, state.items.last).state;
      expect(
        LivingCosts.yearlyIncome(kiralik),
        greaterThan(LivingCosts.yearlyIncome(state)),
      );
    });

    test('kira sözleşmesi bitirilebilir', () {
      final GameState state = evAl(oyuncu(13));
      final GameState kiralik =
          housing.rentOut(state, state.items.last).state;
      final HousingResult bitir =
          housing.endLease(kiralik, kiralik.items.last);
      expect(bitir.outcome.applied, isTrue);
      expect(bitir.state.items.last.rentedOut, isFalse);
      expect(Housing.yearlyRentIncome(bitir.state), 0);
    });

    test('kiradaki ev satılınca gelir durur', () {
      final GameState state = evAl(oyuncu(14));
      final GameState kiralik =
          housing.rentOut(state, state.items.last).state;
      final ItemActionResult satis =
          items.sell(state: kiralik, itemId: kiralik.items.last.id);
      expect(satis.outcome.applied, isTrue);
      expect(Housing.yearlyRentIncome(satis.state), 0);
    });
  });

  // ===================================================================
  // Kayıt
  // ===================================================================
  group('Konut kaydı', () {
    test('oturum, şehir ve kira kaydedilip geri okunur', () async {
      GameState state = evAl(oyuncu(20), sehir: 'İzmir');
      state = housing.moveInto(state, state.items.last).state;
      state = evAl(state, typeId: 'standart_daire', sehir: 'Bursa');
      state = housing.rentOut(state, state.items.last).state;

      final SaveService service = SaveService(MemorySaveStore());
      await service.save(state);
      final SaveLoadResult result = await service.load();
      expect(result.isLoaded, isTrue, reason: result.message);

      final GameState geri = result.state!;
      expect(geri.residenceItemId, state.residenceItemId);
      expect(geri.movedOut, isTrue);
      expect(geri.player.currentCity, 'İzmir');
      expect(Housing.yearlyRentIncome(geri), Housing.yearlyRentIncome(state));
      expect(geri.items.last.rentedOut, isTrue);
      expect(geri.items.last.location, 'Bursa');
      expect(geri.player.wallet, state.player.wallet,
          reason: 'Yükleme masrafı yeniden kesmemeli');
    });

    test('sürüm 12 kaydı ailenin yanında açılır', () async {
      final GameState state = evAl(oyuncu(21));
      final Map<String, Object?> body = encodeGameState(state);
      body
        ..remove('residenceItemId')
        ..remove('movedOut');
      (body['player']! as Map<String, Object?>).remove('currentCity');
      for (final Object? e in body['items']! as List<Object?>) {
        (e! as Map<String, Object?>).remove('rentedOut');
      }

      final SaveLoadResult result = await SaveService(
        MemorySaveStore(
          initial: jsonEncode(
            <String, Object?>{'formatVersion': 12, 'state': body},
          ),
        ),
      ).load();
      expect(result.isLoaded, isTrue, reason: result.message);

      final GameState geri = result.state!;
      expect(geri.residenceItemId, isNull);
      expect(geri.movedOut, isFalse);
      expect(Housing.residenceOf(geri), ResidenceKind.aileYaninda);
      expect(geri.player.currentCity, geri.player.birthCity);
      expect(geri.items.length, state.items.length,
          reason: 'Mülkler korunur');
      expect(geri.items.every((OwnedItem i) => !i.rentedOut), isTrue);
    });
  });
}
