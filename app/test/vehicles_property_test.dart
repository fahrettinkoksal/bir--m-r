import 'dart:convert';
import 'dart:math';

import 'package:bir_omur/data/economy.dart';
import 'package:bir_omur/data/item_catalog.dart';
import 'package:bir_omur/data/job_catalog.dart';
import 'package:bir_omur/data/license_catalog.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/data/save/save_service.dart';
import 'package:bir_omur/data/save/save_store.dart';
import 'package:bir_omur/data/shop_catalog.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/interaction/item_actions.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/interaction.dart';
import 'package:bir_omur/domain/models/owned_item.dart';
import 'package:flutter_test/flutter_test.dart';

const ItemActions actions = ItemActions();

GameState oyuncu(int seed, {int age = 25, int wallet = 20000000}) {
  final GameState state =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  return state.copyWith(
    player: state.player.copyWith(age: age, wallet: wallet),
  );
}

ShopProduct urun(String typeId) => shopProductByTypeId(typeId)!;

/// Ürünü satın alıp durumu döndürür.
GameState satinAl(GameState state, String typeId) {
  final ItemActionResult r = actions.buy(state: state, product: urun(typeId));
  expect(r.outcome.applied, isTrue, reason: r.outcome.text);
  return r.state;
}

OwnedItem sonEsya(GameState state) => state.items.last;

void main() {
  // ===================================================================
  // Mağaza kategorileri
  // ===================================================================
  group('Mağazalar', () {
    test('beş kategori de yaşına uygun ürün sunar', () {
      final List<ShopCategory> yetiskin = shopCategoriesFor(25);
      expect(yetiskin.length, ShopCategory.values.length);
      for (final ShopCategory kategori in ShopCategory.values) {
        expect(shopProductsIn(kategori, 25), isNotEmpty,
            reason: '${kategori.label} boş olmamalı');
      }
    });

    test('küçük çocuğa araç ve emlak gösterilmez', () {
      final List<ShopCategory> cocuk = shopCategoriesFor(8);
      expect(cocuk, isNot(contains(ShopCategory.aracGalerisi)));
      expect(cocuk, isNot(contains(ShopCategory.emlakci)));
      expect(cocuk, contains(ShopCategory.genel));
    });

    test('her ürünün kataloğu ve fiyatı tutarlı', () {
      for (final ShopProduct p in kShopCatalog) {
        expect(itemTypeById(p.typeId), isNotNull,
            reason: '${p.typeId} eşya kataloğunda yok');
        expect(p.price, p.type.baseValue,
            reason: 'Aynı ürün iki yerde farklı fiyatlanmamalı');
        expect(p.price, greaterThan(0));
      }
      // Aynı ürün iki kez listelenmemeli.
      final List<String> idler =
          kShopCatalog.map((ShopProduct p) => p.typeId).toList();
      expect(idler.toSet().length, idler.length);
    });
  });

  // ===================================================================
  // Araçlar
  // ===================================================================
  group('Araçlar', () {
    test('satın alınan araç gerçek bir varlık kaydı olur', () {
      final GameState state = satinAl(oyuncu(1), 'otomobil_ekonomik');
      final OwnedItem araba = sonEsya(state);

      expect(araba.id, isNotEmpty, reason: 'Kalıcı kimlik');
      expect(araba.typeId, 'otomobil_ekonomik');
      expect(araba.type.name, 'Ekonomik otomobil');
      expect(araba.purchasePrice, urun('otomobil_ekonomik').price);
      expect(araba.condition, OwnedItem.defaultCondition);
      expect(araba.attachments, isEmpty);
      expect(araba.isVehicle, isTrue);
      expect(actions.estimatedPrice(araba), greaterThan(0));
      expect(state.player.wallet,
          20000000 - urun('otomobil_ekonomik').price,
          reason: 'Para bir kez düşmeli');
    });

    test('aynı araçtan iki tane ayrı kayıt olur', () {
      GameState state = satinAl(oyuncu(2), 'motosiklet_ekonomik');
      state = satinAl(state, 'motosiklet_ekonomik');
      expect(state.items.length, 2);
      expect(state.items[0].id, isNot(state.items[1].id));
    });

    test('araç sürmek ehliyet ister, sahip olmak istemez', () {
      final GameState state = satinAl(oyuncu(3), 'otomobil_ikinci_el');
      final OwnedItem araba = sonEsya(state);

      final InteractionAvailability ehliyetsiz =
          actions.availability(state, araba, ItemActionKind.kullan);
      expect(ehliyetsiz.isAllowed, isFalse);
      expect(ehliyetsiz.reason, contains('otomobil ehliyeti'));

      final GameState ehliyetli = state.copyWith(
        licenses: <String>{LicenseType.otomobil.id},
      );
      expect(
        actions
            .availability(ehliyetli, araba, ItemActionKind.kullan)
            .isAllowed,
        isTrue,
      );
    });

    test('motosiklet ehliyeti otomobil kullandırmaz', () {
      GameState state = satinAl(oyuncu(4), 'otomobil_ekonomik');
      state = satinAl(state, 'motosiklet_guclu');
      state = state.copyWith(licenses: <String>{LicenseType.motosiklet.id});

      final OwnedItem araba =
          state.items.firstWhere((OwnedItem i) => i.typeId.startsWith('otomobil'));
      final OwnedItem motor = state.items
          .firstWhere((OwnedItem i) => i.typeId.startsWith('motosiklet'));

      expect(actions.availability(state, motor, ItemActionKind.kullan).isAllowed,
          isTrue);
      expect(actions.availability(state, araba, ItemActionKind.kullan).isAllowed,
          isFalse);
    });

    test('bisiklet ehliyet istemez', () {
      final GameState state = satinAl(oyuncu(5, age: 14), 'bisiklet');
      expect(
        actions
            .availability(state, sonEsya(state), ItemActionKind.kullan)
            .isAllowed,
        isTrue,
      );
    });

    test('araca yalnızca kendi aksesuarı takılır', () {
      GameState state = satinAl(oyuncu(6), 'otomobil_orta');
      state = satinAl(state, 'motosiklet_ekonomik');
      state = satinAl(state, 'bisiklet');
      state = satinAl(state, 'bisiklet_zili');
      state = satinAl(state, 'kask');
      state = satinAl(state, 'tavan_bagaji');

      OwnedItem bul(String typeId) =>
          state.items.firstWhere((OwnedItem i) => i.typeId == typeId);

      // Bisiklet zili otomobile takılmaz.
      final ItemActionResult yanlis = actions.attachAccessory(
        state: state,
        itemId: bul('otomobil_orta').id,
        accessoryItemId: bul('bisiklet_zili').id,
      );
      expect(yanlis.outcome.applied, isFalse);
      expect(yanlis.state.items.length, state.items.length,
          reason: 'Başarısız takma aksesuarı tüketmemeli');

      // Kask otomobile takılmaz, motosiklete takılır.
      expect(
        actions
            .attachAccessory(
              state: state,
              itemId: bul('otomobil_orta').id,
              accessoryItemId: bul('kask').id,
            )
            .outcome
            .applied,
        isFalse,
      );
      final ItemActionResult dogru = actions.attachAccessory(
        state: state,
        itemId: bul('motosiklet_ekonomik').id,
        accessoryItemId: bul('kask').id,
      );
      expect(dogru.outcome.applied, isTrue);

      // Tavan bagajı otomobile takılır.
      final ItemActionResult bagaj = actions.attachAccessory(
        state: dogru.state,
        itemId: bul('otomobil_orta').id,
        accessoryItemId: dogru.state.items
            .firstWhere((OwnedItem i) => i.typeId == 'tavan_bagaji')
            .id,
      );
      expect(bagaj.outcome.applied, isTrue);
      expect(
        bagaj.state.items
            .firstWhere((OwnedItem i) => i.typeId == 'otomobil_orta')
            .attachments,
        contains('tavan_bagaji'),
      );
    });

    test('araç kullanımı kondisyonu düşürür, bakım iyileştirir', () {
      GameState state = satinAl(oyuncu(7), 'otomobil_ekonomik');
      state = state.copyWith(licenses: <String>{LicenseType.otomobil.id});
      final String id = sonEsya(state).id;

      final int once = state.itemById(id)!.condition;
      state = actions
          .perform(
            state: state,
            itemId: id,
            action: ItemActionKind.kullan,
            rng: Random(1),
          )
          .state;
      final int sonra = state.itemById(id)!.condition;
      expect(sonra, lessThan(once));

      final int cuzdan = state.player.wallet;
      final ItemActionResult bakim = actions.perform(
        state: state,
        itemId: id,
        action: ItemActionKind.bakim,
        rng: Random(2),
      );
      expect(bakim.outcome.applied, isTrue);
      expect(bakim.state.itemById(id)!.condition, greaterThan(sonra));
      expect(bakim.state.player.wallet, lessThan(cuzdan),
          reason: 'Bakım ücreti cüzdandan düşmeli');
    });

    test('araç satılınca para bir kez girer ve kayıt kalmaz', () {
      final GameState state = satinAl(oyuncu(8), 'motosiklet_guclu');
      final OwnedItem motor = sonEsya(state);
      final int bedel = actions.estimatedPrice(motor);
      final int cuzdan = state.player.wallet;

      final ItemActionResult satis =
          actions.sell(state: state, itemId: motor.id);
      expect(satis.outcome.applied, isTrue);
      expect(satis.state.player.wallet, cuzdan + bedel);
      expect(satis.state.itemById(motor.id), isNull);

      // Aynı araç ikinci kez satılamaz.
      final ItemActionResult tekrar =
          actions.sell(state: satis.state, itemId: motor.id);
      expect(tekrar.outcome.applied, isFalse);
      expect(tekrar.state.player.wallet, satis.state.player.wallet);
    });
  });

  // ===================================================================
  // Emlak
  // ===================================================================
  group('Emlak', () {
    test('satın alınan konut mülk kaydı olur', () {
      final GameState state = satinAl(oyuncu(10), 'kucuk_daire');
      final OwnedItem ev = sonEsya(state);

      expect(ev.isProperty, isTrue);
      expect(ev.purchasePrice, urun('kucuk_daire').price);
      expect(ev.location, state.player.birthCity,
          reason: 'Konut kaydında konum bulunmalı');
      expect(ev.id, isNotEmpty);
      expect(actions.estimatedPrice(ev), greaterThan(0));
    });

    test('ev almak taşınma anlamına gelmez', () {
      final GameState once = oyuncu(11);
      final int haneOnce = once.people
          .where((dynamic p) => p.inPlayerHousehold as bool)
          .length;
      final GameState sonra = satinAl(once, 'mustakil_ev');

      expect(
        sonra.people.where((dynamic p) => p.inPlayerHousehold as bool).length,
        haneOnce,
        reason: 'Mülk sahipliği haneyi değiştirmemeli',
      );
      expect(sonra.people.length, once.people.length);
    });

    test('konutta sürme ve aksesuar eylemi yok', () {
      final GameState state = satinAl(oyuncu(12), 'villa');
      final OwnedItem ev = sonEsya(state);
      final List<ItemActionKind> eylemler =
          actions.availableActions(state, ev);
      expect(eylemler, contains(ItemActionKind.sat));
      expect(eylemler, isNot(contains(ItemActionKind.kullan)));
      expect(eylemler, isNot(contains(ItemActionKind.aksesuarTak)));
    });

    test('konut satılınca para bir kez girer', () {
      final GameState state = satinAl(oyuncu(13), 'standart_daire');
      final OwnedItem ev = sonEsya(state);
      final int bedel = actions.estimatedPrice(ev);
      final int cuzdan = state.player.wallet;

      final ItemActionResult satis =
          actions.sell(state: state, itemId: ev.id);
      expect(satis.state.player.wallet, cuzdan + bedel);
      expect(satis.state.itemById(ev.id), isNull);
    });

    test('parası yetmeyen konut alınamaz', () {
      final GameState fakir = oyuncu(14, wallet: 1000);
      final ItemActionResult r =
          actions.buy(state: fakir, product: urun('villa'));
      expect(r.outcome.applied, isFalse);
      expect(r.state.player.wallet, 1000);
      expect(r.state.items.length, fakir.items.length);
    });
  });

  // ===================================================================
  // Ekonomi ölçeği
  // ===================================================================
  group('Ekonomi ölçeği tutarlı', () {
    test('varlık sıralaması anlamlı', () {
      int fiyat(String id) => itemTypeById(id)!.baseValue;

      expect(fiyat('bisiklet'), lessThan(fiyat('motosiklet_ekonomik')));
      expect(fiyat('motosiklet_ekonomik'), lessThan(fiyat('motosiklet_guclu')));
      expect(fiyat('motosiklet_guclu'), lessThan(fiyat('otomobil_ikinci_el')));
      expect(fiyat('otomobil_ikinci_el'), lessThan(fiyat('otomobil_ekonomik')));
      expect(fiyat('otomobil_ekonomik'), lessThan(fiyat('otomobil_orta')));
      expect(fiyat('otomobil_orta'), lessThan(fiyat('otomobil_luks')));
      // Konutlar kendi içinde sıralı; lüks bir otomobil küçük bir daireye
      // yaklaşabilir, bu beklenen bir durum.
      expect(fiyat('kucuk_daire'), lessThan(fiyat('standart_daire')));
      expect(fiyat('standart_daire'), lessThan(fiyat('mustakil_ev')));
      expect(fiyat('mustakil_ev'), lessThan(fiyat('villa')));
      expect(fiyat('kol_saati'), lessThan(fiyat('telefon')));
      expect(fiyat('telefon'), lessThan(fiyat('bilgisayar')));
    });

    test('maaşlar eşya fiyatlarıyla aynı ölçekte', () {
      final int enDusukMaas = kJobCatalog
          .map((JobType j) => j.yearlySalary)
          .reduce((int a, int b) => a < b ? a : b);
      final int enYuksekMaas = kJobCatalog
          .map((JobType j) => j.yearlySalary)
          .reduce((int a, int b) => a > b ? a : b);

      // Bir yıllık en düşük maaş: birkaç küçük eşya ve bir telefon alır,
      // ama otomobil almaz.
      expect(enDusukMaas, greaterThan(itemTypeById('telefon')!.baseValue));
      expect(enDusukMaas, lessThan(itemTypeById('otomobil_ikinci_el')!.baseValue));

      // En yüksek maaşla bile bir yılda ev alınamaz.
      expect(enYuksekMaas, lessThan(itemTypeById('kucuk_daire')!.baseValue));

      // İkinci el otomobil birkaç yıllık birikimle alınabilir olmalı.
      final int ikinciEl = itemTypeById('otomobil_ikinci_el')!.baseValue;
      expect(ikinciEl / enYuksekMaas, lessThan(2));
      expect(ikinciEl / enDusukMaas, lessThan(4));
    });

    test('değerli eşya eşiği ortak tablodan gelir', () {
      expect(ItemActions.prototypeOnlyValuableThreshold,
          Economy.prototypeOnlyValuableThreshold);
      expect(itemTypeById('telefon')!.baseValue,
          greaterThan(ItemActions.prototypeOnlyValuableThreshold));
      expect(itemTypeById('bilye')!.baseValue,
          lessThan(ItemActions.prototypeOnlyValuableThreshold));
    });

    test('satış değeri satın alma fiyatının altında kalır', () {
      for (final String id in <String>[
        'otomobil_ekonomik',
        'motosiklet_guclu',
        'kucuk_daire',
        'telefon',
      ]) {
        final GameState state = satinAl(oyuncu(20), id);
        final OwnedItem esya = sonEsya(state);
        expect(actions.estimatedPrice(esya), lessThan(esya.purchasePrice!),
            reason: '$id: sıfır alıp aynı fiyata satılmamalı');
        expect(actions.estimatedPrice(esya), greaterThan(0));
      }
    });
  });

  // ===================================================================
  // Kayıt
  // ===================================================================
  group('Araç ve mülk kaydı', () {
    test('araç ve konut kaydedilip geri okunur', () async {
      GameState state = satinAl(oyuncu(30), 'otomobil_luks');
      state = satinAl(state, 'kucuk_daire');
      state = state.copyWith(licenses: <String>{LicenseType.otomobil.id});

      final SaveService service = SaveService(MemorySaveStore());
      await service.save(state);
      final SaveLoadResult result = await service.load();
      expect(result.isLoaded, isTrue, reason: result.message);
      final GameState geri = result.state!;

      expect(geri.items.length, state.items.length);
      for (int i = 0; i < state.items.length; i++) {
        expect(geri.items[i].id, state.items[i].id);
        expect(geri.items[i].typeId, state.items[i].typeId);
        expect(geri.items[i].purchasePrice, state.items[i].purchasePrice);
        expect(geri.items[i].location, state.items[i].location);
      }
      expect(geri.licenses, state.licenses);
      expect(geri.player.wallet, state.player.wallet);
    });

    test('sürüm 8 kaydı eski eşyaları bozmadan açılır', () async {
      final GameState state = satinAl(oyuncu(31), 'bisiklet');
      final Map<String, Object?> body = encodeGameState(state);
      for (final Object? e in body['items']! as List<Object?>) {
        (e! as Map<String, Object?>)
          ..remove('purchasePrice')
          ..remove('location');
      }
      body.remove('licenses');

      final SaveLoadResult result = await SaveService(
        MemorySaveStore(
          initial: jsonEncode(
            <String, Object?>{'formatVersion': 8, 'state': body},
          ),
        ),
      ).load();
      expect(result.isLoaded, isTrue, reason: result.message);
      expect(result.state!.items.length, state.items.length,
          reason: 'Eşyalar silinmemeli');
      expect(result.state!.items.first.purchasePrice, isNull);
      expect(result.state!.licenses, isEmpty);
      expect(result.state!.player.wallet, state.player.wallet);
    });
  });
}
