// Paket AD/5 — servetin kullanımı (§12-§17).
//
// **Denetimin bulduğu sorun.** Paket AD öncesinde oyundaki en pahalı şey
// ₺16.000.000'luk villaydı; oysa altmış yıl yatırım yapan oyuncunun
// portföyü ₺30.000.000'u aşıyor. Yani paranın harcanacak yeri yoktu ve
// "her şeyi yatır" doğal olarak tek akıllı strateji oluyordu. §13 bunu
// açıkça söyledi: sorunu getiriyi düşürerek değil, **paraya anlam
// vererek** çöz.
//
// Bu dosya üç şeyi bekliyor: gerçekten pahalı şeyler var, onların bakım
// masrafı var ama **yapay zengin vergisi yok**, ve servet seviyesine göre
// hayat farklı hissettiriyor.
// ignore_for_file: avoid_print
library;

import 'package:bir_omur/data/event_pool.dart';
import 'package:bir_omur/data/item_catalog.dart';
import 'package:bir_omur/data/shop_catalog.dart';
import 'package:bir_omur/domain/economy/living_costs.dart';
import 'package:bir_omur/domain/economy/net_worth.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/owned_item.dart';
import 'package:flutter_test/flutter_test.dart';

GameState _hayat({int wallet = 0, List<OwnedItem> items = const <OwnedItem>[]}) {
  final GameState s =
      LifeGenerator.seeded(41).generate(mode: StartMode.tamamenRastgele);
  return s.copyWith(
    player: s.player.copyWith(wallet: wallet, age: 40),
    items: items,
  );
}

void main() {
  group('Paket AD/5 — servetin kullanımı', () {
    test('§12: paranın gidebileceği gerçekten pahalı yerler var', () {
      final List<ItemType> sirali = List<ItemType>.of(kItemTypes)
        ..sort((ItemType a, ItemType b) => b.baseValue.compareTo(a.baseValue));
      print('--- EN PAHALI 6 ---');
      for (final ItemType t in sirali.take(6)) {
        print('  ${t.baseValue.toString().padLeft(11)}  ${t.name}');
      }
      // Paket AD öncesi tavan ₺16.000.000'du; portföy onu kolayca aşıyordu.
      expect(sirali.first.baseValue, greaterThan(100000000),
          reason: 'En pahali esya hala 100M altinda; servetin gidecek yeri yok');
      // Tek bir pahalı şey yetmez: birkaç ayrı kanal olmalı.
      final Set<ItemKind> luksTurler = <ItemKind>{
        ItemKind.yazlik,
        ItemKind.tekne,
        ItemKind.koleksiyon,
      };
      for (final ItemKind k in luksTurler) {
        final int adet = kItemTypes.where((ItemType t) => t.kind == k).length;
        expect(adet, greaterThanOrEqualTo(2),
            reason: '$k icin yeterli secenek yok');
      }
    });

    test('§13: lüks mağazalar servet eşiğiyle açılıyor', () {
      // Fakir oyuncu lüks kategorileri **görmemeli**.
      final List<ShopCategory> fakir = shopCategoriesFor(40, netWorth: 100000);
      expect(fakir.any((ShopCategory c) => c.isLuxury), isFalse,
          reason: 'Parasi olmayana luks vitrin gosteriliyor');
      // Zengin oyuncu görmeli.
      final List<ShopCategory> zengin =
          shopCategoriesFor(40, netWorth: 300000000);
      final List<ShopCategory> acik =
          zengin.where((ShopCategory c) => c.isLuxury).toList(growable: false);
      print('Zengin oyuncuya acik luks magaza: '
          '${acik.map((ShopCategory c) => c.label).toList()}');
      expect(acik.length, 3);
      // Kademeli: koleksiyon en erken, marina en geç.
      expect(ShopCategory.koleksiyoncu.wealthGate,
          lessThan(ShopCategory.marina.wealthGate));
      final List<ShopCategory> ortaHalli =
          shopCategoriesFor(40, netWorth: 10000000);
      print('10M servetle acik luks magaza: '
          '${ortaHalli.where((ShopCategory c) => c.isLuxury).map((ShopCategory c) => c.label).toList()}');
      expect(ortaHalli.any((ShopCategory c) => c == ShopCategory.koleksiyoncu),
          isTrue);
      expect(ortaHalli.any((ShopCategory c) => c == ShopCategory.marina),
          isFalse);
      // Öbek de görünmeli.
      expect(shopGroupsFor(40, netWorth: 300000000).containsKey(ShopGroup.luks),
          isTrue);
      expect(shopGroupsFor(40, netWorth: 100000).containsKey(ShopGroup.luks),
          isFalse);
    });

    test('§14: lüks varlık masraf çıkarıyor ama yapay zengin vergisi yok', () {
      final GameState sade = _hayat(wallet: 5000000);
      final int sadeGider = LivingCosts.yearlyCost(sade);

      final GameState tekneli = _hayat(
        wallet: 5000000,
        items: <OwnedItem>[
          const OwnedItem(
            id: 'tekne-1',
            typeId: 'tekne_motoryat',
            acquiredAtAge: 38,
          ),
        ],
      );
      final int tekneliGider = LivingCosts.yearlyCost(tekneli);
      print('Yillik gider: sade $sadeGider · motoryatli $tekneliGider '
          '(fark ${tekneliGider - sadeGider})');
      expect(tekneliGider, greaterThan(sadeGider),
          reason: 'Tekne sifir masrafla duruyor');

      // **Yapay zengin vergisi yok:** aynı eşyaya sahip iki oyuncudan
      // portföyü büyük olanın gideri daha yüksek OLMAMALI.
      final GameState zenginAmaSade = _hayat(wallet: 400000000);
      print('Cuzdani 400M olan sade oyuncunun gideri: '
          '${LivingCosts.yearlyCost(zenginAmaSade)}');
      expect(LivingCosts.yearlyCost(zenginAmaSade), sadeGider,
          reason: 'Servete gore gider artiyor; §14 bunu yasakliyor');

      // Bakım masrafı ayrı satır olarak görünmeli (D-123).
      final List<({String label, int amount})> kalemler =
          LivingCosts.luxuryItems(tekneli);
      print('Bakim kalemi: ${kalemler.map((e) => "${e.label} = ${e.amount}")}');
      expect(kalemler.length, 1);
      expect(kalemler.first.label, contains('bağlama'));
    });

    test('§15-§17: servet seviyesine açılan olaylar var', () {
      final List<GameEvent> servetli = kEventPool
          .where((GameEvent e) => e.requirement.minNetWorth != null)
          .toList(growable: false);
      print('Servet kapili olay: ${servetli.length}');
      for (final GameEvent e in servetli) {
        print('  ${e.id.padRight(26)} >= ${e.requirement.minNetWorth}');
      }
      expect(servetli.length, greaterThanOrEqualTo(5),
          reason: 'Servet seviyesine acilan olay yok; zenginin hayati ayni');

      // §15: aileye para veren/vermeyen kararı gerçekten ilişkiyi etkilesin.
      final GameEvent aile = kEventPool
          .firstWhere((GameEvent e) => e.id == 'ad_aile_borc_ister');
      final EventChoice ver =
          aile.choices.firstWhere((EventChoice c) => c.id == 'ver');
      final EventChoice verme =
          aile.choices.firstWhere((EventChoice c) => c.id == 'verme');
      expect(ver.money, lessThan(0), reason: 'Para vermek para gotermiyor');
      expect(ver.bond, greaterThan(0));
      expect(verme.bond, lessThan(0),
          reason: 'Vermemenin iliskiye bedeli yok');

      // §16: sağlık olayı nadir olmalı.
      final GameEvent saglik = kEventPool
          .firstWhere((GameEvent e) => e.id == 'ad_saglik_masrafi');
      expect(saglik.minAgeGap, greaterThanOrEqualTo(10),
          reason: 'Saglik masrafi cok sik; yasli oyuncu surekli servet eritir');
      expect(saglik.weight, lessThanOrEqualTo(3));
    });

    test('§14: lüks varlık net servette duruyor ve satılabiliyor', () {
      // Lüks varlıklar ayrı bir sistem değil, normal eşya: net servete
      // giriyor, yani borç tahsilinde de satılabilirler.
      final GameState s = _hayat(
        wallet: 0,
        items: <OwnedItem>[
          const OwnedItem(
            id: 'yali-1',
            typeId: 'yali_bogaz',
            acquiredAtAge: 39,
            purchasePrice: 145000000,
          ),
        ],
      );
      print('Yali sahibinin net serveti: ${NetWorth.of(s)}');
      expect(NetWorth.of(s), 145000000);
      expect(actionsFor(ItemKind.yazlik).contains(ItemActionKind.sat), isTrue);
      expect(actionsFor(ItemKind.tekne).contains(ItemActionKind.sat), isTrue);
      expect(
          actionsFor(ItemKind.koleksiyon).contains(ItemActionKind.sat), isTrue);
    });
  });
}
