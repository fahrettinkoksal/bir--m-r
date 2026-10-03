import 'dart:convert';
import 'dart:math';

import 'package:bir_omur/data/event_pool.dart';
import 'package:bir_omur/data/item_catalog.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/data/save/save_format.dart';
import 'package:bir_omur/data/save/save_service.dart';
import 'package:bir_omur/data/save/save_store.dart';
import 'package:bir_omur/data/shop_catalog.dart';
import 'package:bir_omur/domain/events/event_engine.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/interaction/family_interactions.dart';
import 'package:bir_omur/domain/interaction/item_actions.dart';
import 'package:bir_omur/domain/models/applied_effect.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/interaction.dart';
import 'package:bir_omur/domain/models/owned_item.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_flow.dart';

const ItemActions actions = ItemActions();

GameState life(int seed, {int age = 12, int wallet = 0}) {
  final GameState state =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  return state.copyWith(
    player: state.player.copyWith(age: age, wallet: wallet),
  );
}

/// Duruma belirli kondisyonda bir eşya ekler ve örneği döndürür.
({GameState state, OwnedItem item}) withItem(
  GameState state,
  String typeId, {
  int condition = OwnedItem.defaultCondition,
}) {
  final GameState next = state.grantItems(
    <String>[typeId],
    source: ItemSource.olay,
    condition: condition,
  );
  return (state: next, item: next.items.last);
}

/// Sürüm 2 biçiminde bir kayıt gövdesi üretir (eşyalar tür kümesi hâlinde).
Map<String, Object?> asVersion2Body(GameState state) {
  final Map<String, Object?> body = encodeGameState(state);
  body['possessions'] = state.possessions.toList(growable: false);
  body.remove('items');
  return body;
}

void main() {
  // ===================================================================
  // AŞAMA 1 — Eşya modeli ve kayıt uyumu
  // ===================================================================
  group('Aşama 1 — eşya modeli', () {
    test('aynı türden iki eşya ayrı kimlikle tutulur', () {
      GameState state = life(1);
      state = state.grantItems(<String>['bisiklet'], source: ItemSource.hediye);
      state = state.grantItems(<String>['bisiklet'], source: ItemSource.satinAlma);

      expect(state.items.length, 2);
      expect(state.items[0].id, isNot(state.items[1].id));
      expect(state.itemsOfType('bisiklet').length, 2);
      // Tür kümesi envanterden türetilir.
      expect(state.possessions, <String>{'bisiklet'});
      expect(state.items[0].source, ItemSource.hediye);
      expect(state.items[1].source, ItemSource.satinAlma);
    });

    test('eşya örneği edinme bilgisini taşır', () {
      final GameState state = life(2, age: 9).grantItems(
        <String>['yoyo'],
        source: ItemSource.hediye,
        fromPersonId: 'anne',
      );
      final OwnedItem item = state.items.single;
      expect(item.typeId, 'yoyo');
      expect(item.acquiredAtAge, 9);
      expect(item.fromPersonId, 'anne');
      expect(item.condition, OwnedItem.defaultCondition);
      expect(item.attachments, isEmpty);
      expect(item.name, 'Yo-yo');
    });

    test('hediye edilen eşya gerçek envanter örneği olur', () {
      const FamilyInteractions interactions = FamilyInteractions();
      final GameState temel = life(3, age: 6);
      final Person anne = temel.people
          .firstWhere((Person p) => p.relation == RelationType.anne);
      GameState oyun = temel.copyWith(
        people: temel.people
            .map((Person p) => p.id == anne.id
                ? p.copyWith(bond: 95, wealth: WealthTier.ortaHalli)
                : p)
            .toList(growable: false),
      );

      InteractionResult? basarili;
      for (int i = 0; i < 6 && basarili == null; i++) {
        final InteractionResult r = interactions.perform(
          state: oyun,
          personId: anne.id,
          kind: InteractionKind.hediyeIste,
          rng: Random(10 + i),
        );
        oyun = r.state;
        if (r.outcome.gainedPossession != null) basarili = r;
      }
      expect(basarili, isNotNull);

      final OwnedItem item = oyun.items.single;
      expect(item.typeId, basarili!.outcome.gainedPossession);
      expect(item.source, ItemSource.hediye);
      expect(item.fromPersonId, anne.id);
      expect(item.acquiredAtAge, 6);
    });

    // Not: Sürüm 1-2 göç adımları Paket 12'de kaldırıldı (Faho'nun
    // kararı: geriye dönük yalnızca son beş sürüm taşınır). Bu yüzden
    // eski "sürüm 2 gövdesi" testleri yerine desteklenen en eski
    // sürümün gerçek gövdesi sınanır.
    test('desteklenen en eski sürümün kaydı eşyaları kaybetmeden açılır',
        () async {
      final GameState orijinal = life(4, age: 14, wallet: 500).grantItems(
        <String>['bisiklet', 'kol_saati'],
        source: ItemSource.hediye,
        fromPersonId: 'anne',
      );

      final SaveLoadResult result = await SaveService(
        MemorySaveStore(
          initial: jsonEncode(<String, Object?>{
            'formatVersion': kMinReadableSaveVersion,
            'state': encodeGameState(orijinal),
          }),
        ),
      ).load();
      expect(result.isLoaded, isTrue, reason: result.message);

      final GameState yuklenen = result.state!;
      expect(yuklenen.player.id, orijinal.player.id);
      expect(yuklenen.player.age, 14);
      expect(yuklenen.player.wallet, 500);
      expect(yuklenen.items.length, 2);
      expect(yuklenen.possessions, <String>{'bisiklet', 'kol_saati'});
      expect(
        yuklenen.items.map((OwnedItem i) => i.id).toSet().length,
        2,
        reason: 'Kimlikler benzersiz olmalı',
      );
    });


    test('hediye geçmişi kayıt turunda eşyaya bağlı kalır', () async {
      GameState orijinal = life(5, age: 8);
      orijinal = orijinal.grantItems(
        <String>['yoyo'],
        source: ItemSource.hediye,
        fromPersonId: 'anne',
      );

      final SaveLoadResult result = await SaveService(
        MemorySaveStore(
          initial: jsonEncode(<String, Object?>{
            'formatVersion': kMinReadableSaveVersion,
            'state': encodeGameState(orijinal),
          }),
        ),
      ).load();
      expect(result.isLoaded, isTrue, reason: result.message);

      final OwnedItem item = result.state!.items.single;
      expect(item.typeId, 'yoyo');
      expect(item.source, ItemSource.hediye);
      expect(item.fromPersonId, 'anne');
      expect(item.acquiredAtAge, orijinal.items.single.acquiredAtAge);
    });


    test('desteklenen aralıktaki her sürüm eşyaları koruyarak açılır',
        () async {
      final GameState orijinal = life(6, age: 11).grantItems(
        <String>['bisiklet'],
        source: ItemSource.olay,
      );

      for (int surum = kMinReadableSaveVersion;
          surum <= kSaveFormatVersion;
          surum++) {
        final SaveLoadResult result = await SaveService(
          MemorySaveStore(
            initial: jsonEncode(<String, Object?>{
              'formatVersion': surum,
              'state': encodeGameState(orijinal),
            }),
          ),
        ).load();
        expect(result.isLoaded, isTrue,
            reason: 'Sürüm $surum açılmadı: ${result.message}');
        expect(result.state!.possessions, <String>{'bisiklet'},
            reason: 'Sürüm $surum');
        expect(result.state!.items.length, 1, reason: 'Sürüm $surum');
      }
    });


    test('güncel sürüm kaydı eşya ayrıntılarını korur', () async {
      final ({GameState state, OwnedItem item}) kur =
          withItem(life(7, age: 13), 'bisiklet', condition: 62);
      final GameState orijinal = kur.state.updateItem(
        kur.item.copyWith(attachments: <String>['bisiklet_zili']),
      );

      final MemorySaveStore store = MemorySaveStore();
      final SaveService service = SaveService(store);
      await service.save(orijinal);
      final SaveLoadResult result = await service.load();
      expect(result.isLoaded, isTrue);

      final OwnedItem item = result.state!.items.single;
      expect(item.id, kur.item.id);
      expect(item.condition, 62);
      expect(item.attachments, <String>['bisiklet_zili']);
      expect(item.source, kur.item.source);
    });

    test('kayıt sürümü yükseltildi', () {
      expect(kSaveFormatVersion, greaterThanOrEqualTo(3));
    });
  });

  // ===================================================================
  // AŞAMA 2 — Eşya eylemleri
  // ===================================================================
  group('Aşama 2 — eşya eylemleri', () {
    test('tür dışı eylem hiç sunulmaz', () {
      final ({GameState state, OwnedItem item}) saat =
          withItem(life(11, age: 20, wallet: 5000), 'kol_saati');
      final List<ItemActionKind> saatEylemleri =
          actions.availableActions(saat.state, saat.item);
      expect(saatEylemleri, isNot(contains(ItemActionKind.aksesuarTak)),
          reason: 'Kol saatine bisiklet aksesuarı takılmaz');

      final ({GameState state, OwnedItem item}) kitap =
          withItem(life(11, age: 20), 'roman');
      expect(actions.availableActions(kitap.state, kitap.item),
          isNot(contains(ItemActionKind.kullan)),
          reason: 'Kitap sürülmez; okuma Aktiviteler paketinde gelecek');

      final ({GameState state, OwnedItem item}) bisiklet =
          withItem(life(11, age: 20, wallet: 5000), 'bisiklet');
      expect(
        actionsFor(bisiklet.item.type.kind),
        containsAll(<ItemActionKind>[
          ItemActionKind.kullan,
          ItemActionKind.temizle,
          ItemActionKind.bakim,
          ItemActionKind.aksesuarTak,
          ItemActionKind.sat,
        ]),
      );
    });

    test('bisiklete binmek değerleri artırır ve kondisyonu düşürür', () {
      final ({GameState state, OwnedItem item}) kur =
          withItem(life(12, age: 12), 'bisiklet', condition: 80);
      final int mutlulukOnce = kur.state.player.stats.happiness;

      final ItemActionResult r = actions.perform(
        state: kur.state,
        itemId: kur.item.id,
        action: ItemActionKind.kullan,
        rng: Random(1),
      );

      expect(r.outcome.applied, isTrue);
      final OwnedItem sonra = r.state.itemById(kur.item.id)!;
      expect(sonra.condition, lessThan(80));
      expect(r.state.player.stats.happiness, greaterThan(mutlulukOnce));
      expect(
        r.outcome.effects.map((AppliedEffect e) => e.label),
        contains('${sonra.name} kondisyonu'),
      );
      // Günlüğe yazılır.
      expect(r.state.log.length, kur.state.log.length + 1);
    });

    test('aynı yaşta tekrar kullanım kazancı azalır, yıpranma sürer', () {
      GameState state = withItem(life(13, age: 12), 'bisiklet').state;
      final String id = state.items.single.id;

      int oncekiMutluluk = state.player.stats.happiness;
      bool faydaBittiMi = false;
      for (int i = 0; i < 5; i++) {
        final int kondisyonOnce = state.itemById(id)!.condition;
        final ItemActionResult r = actions.perform(
          state: state,
          itemId: id,
          action: ItemActionKind.kullan,
          rng: Random(20 + i),
        );
        state = r.state;
        expect(state.itemById(id)!.condition, lessThan(kondisyonOnce),
            reason: 'Kullanım her zaman yıpratır');
        if (r.outcome.noNewBenefit) {
          faydaBittiMi = true;
          expect(state.player.stats.happiness, oncekiMutluluk,
              reason: 'Fayda bitince değer artmaz');
        }
        oncekiMutluluk = state.player.stats.happiness;
      }
      expect(faydaBittiMi, isTrue);
    });

    test('temizlik ve bakım farklı sonuç üretir', () {
      // Cüzdan 2026 ölçeğine çekildi: bisikletin değeri 9.000 ₺'den
      // 28.000 ₺'ye çıktı, bakım ücreti de değere oranlı. Eski 2.000 ₺
      // artık bakımı karşılamıyordu; iddia aynen duruyor.
      final ({GameState state, OwnedItem item}) kur = withItem(
        life(14, age: 14, wallet: 8000),
        'bisiklet',
        condition: 30,
      );

      final ItemActionResult temiz = actions.perform(
        state: kur.state,
        itemId: kur.item.id,
        action: ItemActionKind.temizle,
        rng: Random(1),
      );
      final int temizSonrasi = temiz.state.itemById(kur.item.id)!.condition;
      expect(temizSonrasi, 30 + ItemActions.prototypeOnlyCleanGain);
      expect(temiz.state.player.wallet, 8000,
          reason: 'Temizlik ücretsizdir');

      final ItemActionResult bakim = actions.perform(
        state: kur.state,
        itemId: kur.item.id,
        action: ItemActionKind.bakim,
        rng: Random(1),
      );
      final int bakimSonrasi = bakim.state.itemById(kur.item.id)!.condition;
      expect(bakimSonrasi, greaterThan(temizSonrasi),
          reason: 'Bakım temizlikten daha çok iyileştirir');
      expect(bakim.state.player.wallet, lessThan(8000),
          reason: 'Bakım ücretlidir');
      // Hiçbiri sihirli şekilde sıfırlamaz.
      expect(bakimSonrasi, lessThanOrEqualTo(ItemActions.prototypeOnlyRepairCeiling));
    });

    test('temizlik mekanik hasarı gideremez', () {
      GameState state =
          withItem(life(15, age: 14), 'bisiklet', condition: 40).state;
      final String id = state.items.single.id;
      for (int i = 0; i < 20; i++) {
        final InteractionAvailability uygun =
            actions.availability(state, state.itemById(id)!, ItemActionKind.temizle);
        if (!uygun.isAllowed) break;
        state = actions
            .perform(
              state: state,
              itemId: id,
              action: ItemActionKind.temizle,
              rng: Random(i),
            )
            .state;
      }
      expect(state.itemById(id)!.condition,
          lessThanOrEqualTo(ItemActions.prototypeOnlyCleanCeiling));
      expect(
        actions
            .availability(state, state.itemById(id)!, ItemActionKind.temizle)
            .isAllowed,
        isFalse,
        reason: 'Tavana gelince temizlik sunulmaz',
      );
    });

    test('parası yetmeyen bakım hiçbir şeyi değiştirmez', () {
      final ({GameState state, OwnedItem item}) kur =
          withItem(life(16, age: 14), 'bisiklet', condition: 30);
      expect(kur.state.player.wallet, 0);

      final ItemActionResult r = actions.perform(
        state: kur.state,
        itemId: kur.item.id,
        action: ItemActionKind.bakim,
        rng: Random(1),
      );
      expect(r.outcome.applied, isFalse);
      expect(r.outcome.text, contains('yeterli para yok'));
      expect(r.state.player.wallet, 0);
      expect(r.state.itemById(kur.item.id)!.condition, 30);
      expect(r.outcome.effects, isEmpty);
    });

    test('çok yıpranmış eşya kullanılamaz', () {
      final ({GameState state, OwnedItem item}) kur =
          withItem(life(17, age: 14), 'bisiklet', condition: 5);
      expect(
        actions.availability(kur.state, kur.item, ItemActionKind.kullan).isAllowed,
        isFalse,
      );
    });

    test('kondisyon 0-100 aralığının dışına çıkmaz', () {
      GameState state =
          withItem(life(18, age: 14, wallet: 100000), 'bisiklet', condition: 12).state;
      final String id = state.items.single.id;
      for (int i = 0; i < 30; i++) {
        final OwnedItem item = state.itemById(id)!;
        final ItemActionKind eylem =
            actions.availability(state, item, ItemActionKind.kullan).isAllowed
                ? ItemActionKind.kullan
                : ItemActionKind.bakim;
        final ItemActionResult r = actions.perform(
          state: state,
          itemId: id,
          action: eylem,
          rng: Random(i),
        );
        state = r.state;
        final int kondisyon = state.itemById(id)!.condition;
        expect(kondisyon, inInclusiveRange(0, 100));
      }
    });
  });

  // ===================================================================
  // AŞAMA 3 — Aksesuar ve alışveriş
  // ===================================================================
  group('Aşama 3 — aksesuar ve alışveriş', () {
    ShopProduct zil() => shopProductByTypeId('bisiklet_zili')!;

    test('yetersiz bakiyeyle satın alma yapılamaz', () {
      final GameState state = life(21, age: 12, wallet: 5);
      final ItemActionResult r = actions.buy(state: state, product: zil());
      expect(r.outcome.applied, isFalse);
      expect(r.state.player.wallet, 5);
      expect(r.state.items, isEmpty);
    });

    test('satın alma ücreti bir kez keser ve eşyayı envantere ekler', () {
      final GameState state = life(22, age: 12, wallet: 1000);
      final ItemActionResult r = actions.buy(state: state, product: zil());

      expect(r.outcome.applied, isTrue);
      expect(r.state.player.wallet, 1000 - zil().price);
      expect(r.state.items.length, 1);
      expect(r.state.items.single.typeId, 'bisiklet_zili');
      expect(r.state.items.single.source, ItemSource.satinAlma);
      expect(r.outcome.text, contains(zil().name));
      expect(
        r.outcome.effects.map((AppliedEffect e) => e.text),
        contains('Cüzdan -${zil().price} ₺'),
      );

      // İkinci alış ayrı bir örnek ve ayrı bir ücret.
      final ItemActionResult ikinci =
          actions.buy(state: r.state, product: zil());
      expect(ikinci.state.player.wallet, 1000 - 2 * zil().price);
      expect(ikinci.state.items.length, 2);
      expect(ikinci.state.items[0].id, isNot(ikinci.state.items[1].id));
    });

    test('yaşı yetmeyen ürün alınamaz', () {
      final ShopProduct saat = shopProductByTypeId('kol_saati')!;
      final GameState state = life(23, age: 7, wallet: 100000);
      final ItemActionResult r = actions.buy(state: state, product: saat);
      expect(r.outcome.applied, isFalse);
      expect(r.state.player.wallet, 100000);
    });

    test('uyumsuz aksesuar takılamaz', () {
      GameState state = life(24, age: 16, wallet: 5000);
      state = state.grantItems(<String>['kol_saati'], source: ItemSource.olay);
      state = state.grantItems(
        <String>['bisiklet_kornasi'],
        source: ItemSource.satinAlma,
      );
      final OwnedItem saat =
          state.items.firstWhere((OwnedItem i) => i.typeId == 'kol_saati');
      final OwnedItem korna =
          state.items.firstWhere((OwnedItem i) => i.typeId == 'bisiklet_kornasi');

      final ItemActionResult r = actions.attachAccessory(
        state: state,
        itemId: saat.id,
        accessoryItemId: korna.id,
      );
      expect(r.outcome.applied, isFalse);
      expect(r.state.items.length, 2, reason: 'Hiçbir şey tüketilmemeli');
      expect(r.state.itemById(saat.id)!.attachments, isEmpty);
    });

    test('uyumlu aksesuar takılır ve envanterden düşer', () {
      GameState state = life(25, age: 12, wallet: 5000);
      state = state.grantItems(<String>['bisiklet'], source: ItemSource.hediye);
      final OwnedItem bisiklet = state.items.single;
      state = actions.buy(state: state, product: zil()).state;
      final OwnedItem zilEsya =
          state.items.firstWhere((OwnedItem i) => i.typeId == 'bisiklet_zili');

      final ItemActionResult r = actions.attachAccessory(
        state: state,
        itemId: bisiklet.id,
        accessoryItemId: zilEsya.id,
      );

      expect(r.outcome.applied, isTrue);
      expect(r.state.itemById(zilEsya.id), isNull,
          reason: 'Takılan aksesuar envanterde ayrı durmaz');
      expect(r.state.itemById(bisiklet.id)!.attachments,
          contains('bisiklet_zili'));
      expect(r.state.items.length, 1);
      expect(
        r.outcome.effects.map((AppliedEffect e) => e.label),
        contains('Bisiklet: Bisiklet zili takıldı'),
      );
    });

    test('aile serveti oyuncunun cüzdanına geçmez', () {
      final GameState state = life(26, age: 12, wallet: 0);
      // Zengin bir aile üyesi olsa bile cüzdan sıfırdır.
      final ItemActionResult r = actions.buy(state: state, product: zil());
      expect(r.outcome.applied, isFalse);
      expect(r.state.player.wallet, 0);
    });
  });

  // ===================================================================
  // AŞAMA 4 — Satış ve değerleme
  // ===================================================================
  group('Aşama 4 — satış ve değerleme', () {
    test('değer türe, kondisyona ve özel niteliğe göre değişir', () {
      final GameState state = life(31, age: 30);
      final OwnedItem saglamBisiklet =
          withItem(state, 'bisiklet', condition: 95).item;
      final OwnedItem yipranmisBisiklet =
          withItem(state, 'bisiklet', condition: 20).item;
      final OwnedItem siradanSaat =
          withItem(state, 'kol_saati', condition: 95).item;
      final OwnedItem antikaSaat =
          withItem(state, 'antika_saat', condition: 95).item;

      expect(
        actions.estimatedPrice(saglamBisiklet),
        greaterThan(actions.estimatedPrice(yipranmisBisiklet)),
        reason: 'Kondisyon düştükçe değer azalır',
      );
      expect(
        actions.estimatedPrice(antikaSaat),
        greaterThan(actions.estimatedPrice(siradanSaat)),
        reason: 'Antika nitelik değeri yükseltir',
      );
      expect(
        actions.estimatedPrice(saglamBisiklet),
        isNot(actions.estimatedPrice(siradanSaat)),
        reason: 'Tek sabit fiyat yok',
      );
    });

    test('takılı aksesuar satış değerini artırır', () {
      final ({GameState state, OwnedItem item}) kur =
          withItem(life(32, age: 20), 'bisiklet', condition: 80);
      final int sade = actions.estimatedPrice(kur.item);
      final OwnedItem aksesuarli =
          kur.item.copyWith(attachments: <String>['bisiklet_zili']);
      expect(actions.estimatedPrice(aksesuarli), greaterThan(sade));
    });

    test('satış envanterden çıkarır ve parayı bir kez ekler', () {
      final ({GameState state, OwnedItem item}) kur =
          withItem(life(33, age: 20, wallet: 100), 'bisiklet', condition: 70);
      final int bedel = actions.estimatedPrice(kur.item);

      final ItemActionResult r =
          actions.sell(state: kur.state, itemId: kur.item.id);
      expect(r.outcome.applied, isTrue);
      expect(r.state.player.wallet, 100 + bedel);
      expect(r.state.itemById(kur.item.id), isNull);
      expect(r.state.possessions, isNot(contains('bisiklet')));
      expect(
        r.outcome.effects.map((AppliedEffect e) => e.text),
        contains('Cüzdan +$bedel ₺'),
      );
      expect(r.state.log.last.text, contains('satıldı'));
    });

    test('aynı eşya iki kez satılamaz', () {
      final ({GameState state, OwnedItem item}) kur =
          withItem(life(34, age: 20, wallet: 0), 'bisiklet');
      final ItemActionResult ilk =
          actions.sell(state: kur.state, itemId: kur.item.id);
      final int cuzdan = ilk.state.player.wallet;

      final ItemActionResult ikinci =
          actions.sell(state: ilk.state, itemId: kur.item.id);
      expect(ikinci.outcome.applied, isFalse);
      expect(ikinci.state.player.wallet, cuzdan,
          reason: 'İkinci satıştan para kazanılmaz');
    });

    test('satılan eşyada bakım ve aksesuar ekranı açık kalmaz', () {
      final ({GameState state, OwnedItem item}) kur =
          withItem(life(35, age: 20, wallet: 5000), 'bisiklet', condition: 50);
      final GameState sonra =
          actions.sell(state: kur.state, itemId: kur.item.id).state;

      for (final ItemActionKind eylem in ItemActionKind.values) {
        expect(actions.availability(sonra, kur.item, eylem).isAllowed, isFalse,
            reason: '$eylem satılmış eşyada açık kalmamalı');
      }
      final ItemActionResult bakim = actions.perform(
        state: sonra,
        itemId: kur.item.id,
        action: ItemActionKind.bakim,
        rng: Random(1),
      );
      expect(bakim.outcome.applied, isFalse);
      expect(bakim.state.player.wallet, sonra.player.wallet);
    });

    test('küçük yaşta değerli eşya satışı engellenir', () {
      final ({GameState state, OwnedItem item}) kucuk =
          withItem(life(36, age: 9), 'bisiklet');
      expect(
        actions.availability(kucuk.state, kucuk.item, ItemActionKind.sat).isAllowed,
        isFalse,
      );

      // Ucuz oyuncak her yaşta satılabilir.
      final ({GameState state, OwnedItem item}) oyuncak =
          withItem(life(36, age: 9), 'yoyo');
      expect(
        actions.availability(oyuncak.state, oyuncak.item, ItemActionKind.sat).isAllowed,
        isTrue,
      );

      final ({GameState state, OwnedItem item}) buyuk =
          withItem(life(36, age: 18), 'bisiklet');
      expect(
        actions.availability(buyuk.state, buyuk.item, ItemActionKind.sat).isAllowed,
        isTrue,
      );
    });
  });

  // ===================================================================
  // AŞAMA 5 — Mevcut sistemlerle bağlantı
  // ===================================================================
  group('Aşama 5 — uçtan uca zincir', () {
    test('hediye → bin → bakım → zil al ve tak → sat → kaydet/yükle',
        () async {
      final MemorySaveStore store = MemorySaveStore();
      // Başlangıç durumu kayıt servisi olmadan kurulur; böylece elle
      // yazdığımız kaydın üzerine otomatik kayıt binmez.
      final GameController kurucu = GameController(random: Random(41));
      kurucu.startNewLife(mode: StartMode.tamamenRastgele, seed: 41);

      // 1) Anne bisiklet hediye etti (olay yerine doğrudan envantere).
      GameState hazir = kurucu.state!;
      hazir = hazir.copyWith(
        player: hazir.player.copyWith(age: 16, wallet: 3000),
        pendingEvent: null,
      );
      hazir = hazir.grantItems(
        <String>['bisiklet'],
        source: ItemSource.hediye,
        fromPersonId: 'anne',
      );
      final GameController oyun = GameController(
        random: Random(42),
        saveService: SaveService(store),
      );
      await SaveService(store).save(hazir);
      expect(await oyun.restoreSavedLife(), SaveLoadStatus.yuklendi);

      final String bisikletId = oyun.state!.items.single.id;
      expect(oyun.state!.possessions, contains('bisiklet'));

      // D-125'ten sonra eşya eylemleri de ilerleme sayılıyor; motor
      // aynı yaşta ek olay sunabiliyor. Gerçek oyuncu o pencereyi
      // kapatıp devam eder — test de öyle yapar, yoksa bir sonraki
      // eylem "olay bekliyor" diye reddedilir.
      void devamEt() {
        int guard = 0;
        while (oyun.state!.hasNotice || oyun.state!.hasPendingEvent) {
          if (guard++ > 20) fail('Pencereler kapanmıyor.');
          if (oyun.state!.hasNotice) {
            oyun.dismissNotice();
            continue;
          }
          oyun.chooseEventOption(oyun.state!.pendingEvent!.choices.first.id);
        }
      }

      devamEt();

      // 2) Bisiklete bindim.
      final ItemOutcome? bindi =
          oyun.performItemAction(bisikletId, ItemActionKind.kullan);
      expect(bindi!.applied, isTrue);
      devamEt();
      final int kullanimSonrasi = oyun.state!.itemById(bisikletId)!.condition;
      expect(kullanimSonrasi, lessThan(OwnedItem.defaultCondition));

      // 3) Bakım yaptım: gerçek masraf ve iyileşme.
      final int cuzdanOnce = oyun.state!.player.wallet;
      final ItemOutcome? bakim =
          oyun.performItemAction(bisikletId, ItemActionKind.bakim);
      expect(bakim!.applied, isTrue);
      expect(oyun.state!.player.wallet, lessThan(cuzdanOnce));
      expect(oyun.state!.itemById(bisikletId)!.condition,
          greaterThan(kullanimSonrasi));

      devamEt();

      // 4) Zil aldım ve taktım.
      final ShopProduct zil = shopProductByTypeId('bisiklet_zili')!;
      final int cuzdanAlimOnce = oyun.state!.player.wallet;
      expect(oyun.buyProduct(zil)!.applied, isTrue);
      expect(oyun.state!.player.wallet, cuzdanAlimOnce - zil.price);
      final String zilId = oyun.state!.items
          .firstWhere((OwnedItem i) => i.typeId == 'bisiklet_zili')
          .id;
      devamEt();
      expect(oyun.attachAccessory(bisikletId, zilId)!.applied, isTrue);
      expect(oyun.state!.itemById(bisikletId)!.attachments,
          contains('bisiklet_zili'));
      expect(oyun.state!.itemById(zilId), isNull);

      // 5) Bisikleti sattım.
      final int bedel =
          oyun.estimatedPriceFor(oyun.state!.itemById(bisikletId)!);
      final int satisOncesi = oyun.state!.player.wallet;
      expect(oyun.sellItem(bisikletId)!.applied, isTrue);
      expect(oyun.state!.player.wallet, satisOncesi + bedel);
      expect(oyun.state!.itemById(bisikletId), isNull);

      // 6) Oyunu kapatıp açtım.
      await oyun.flushSaves();
      final GameController yeniden = GameController(
        random: Random(43),
        saveService: SaveService(store),
      );
      expect(await yeniden.restoreSavedLife(), SaveLoadStatus.yuklendi);
      expect(yeniden.state!.player.wallet, satisOncesi + bedel);
      expect(yeniden.state!.itemById(bisikletId), isNull);
      expect(yeniden.state!.possessions, isNot(contains('bisiklet')));
      expect(yeniden.state!.log.last.text, contains('satıldı'));
    });

    test('olay motorundaki eşya koşulu yeni envanterle çalışır', () {
      final EventEngine engine = EventEngine(
        pool: <GameEvent>[
          kEventPool.firstWhere((GameEvent e) => e.id == 'bisiklet_zinciri'),
        ],
      );
      final GameState state = life(44, age: 12);
      expect(engine.openingEvent(state, Random(1)), isNull,
          reason: 'Bisikleti olmayana zincir olayı çıkmaz');

      final GameState bisikletli =
          state.grantItems(<String>['bisiklet'], source: ItemSource.hediye);
      expect(engine.openingEvent(bisikletli, Random(1)), isNotNull);

      // Satınca koşul yeniden kapanır.
      final GameState satildi = actions
          .sell(
            state: bisikletli.copyWith(
              player: bisikletli.player.copyWith(age: 18),
            ),
            itemId: bisikletli.items.single.id,
          )
          .state;
      expect(engine.openingEvent(satildi, Random(1)), isNull);
    });

    test('olayla kazanılan eşya gerçek örnek olur', () {
      final EventEngine engine = EventEngine(
        pool: <GameEvent>[
          kEventPool.firstWhere((GameEvent e) => e.id == 'bisiklet_hediyesi'),
        ],
      );
      GameState state = life(45, age: 10);
      final ActiveEvent? olay = engine.openingEvent(state, Random(3));
      expect(olay, isNotNull);
      state = engine.resolve(
        state.copyWith(pendingEvent: olay),
        'sarilarak',
        rng: Random(3),
      );

      expect(state.items.length, 1);
      final OwnedItem item = state.items.single;
      expect(item.typeId, 'bisiklet');
      expect(item.source, ItemSource.olay);
      expect(item.acquiredAtAge, 10);
    });

    test('yaş alma ve aile sistemleri eşya modeliyle bozulmuyor', () {
      for (int seed = 0; seed < 6; seed++) {
        final GameController c = GameController(random: Random(seed));
        c.startNewLife(mode: StartMode.tamamenRastgele, seed: seed);
        for (int i = 0; i < 25; i++) {
          if (c.state!.hasPendingEvent) {
            c.chooseEventOption(c.state!.pendingEvent!.choices.first.id);
          } else {
            // Lise alanı seçilmeden yaş atlanmaz (D-094).
            resolveEducationChoices(c);
            c.ageUp();
          }
          final List<String> ids =
              c.state!.items.map((OwnedItem e) => e.id).toList();
          expect(ids.toSet().length, ids.length,
              reason: 'Eşya kimlikleri çakışmamalı');
        }
        expect(c.state!.player.age, greaterThan(0));
      }
    });
  });
}
