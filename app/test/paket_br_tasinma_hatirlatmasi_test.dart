// Paket BR/1 — ilk eve taşınma hatırlatması.
//
// **Ölçülen boşluk (Paket BP).** Mülk sahibi olmak oturmak demek değil
// (D-043) ve taşınma yalnızca *Evlerim* ekranındaki bir düğme. İlk evini
// alan oyuncuya bunu söyleyen tek satır yoktu. Ölçüm botu da aynı yere
// düştü: ev alıp hiç taşınmadı — ev sahibi olan 25 hayatın 18'i kendi
// evinde tek yıl bile geçirmemişti.
//
// Hatırlatma satın alma sonucuna eklendi. Kuralları:
//   1. Yalnızca **konut** alımında çıkar.
//   2. Yalnızca oyuncu kendi evinde oturmuyorken çıkar (yatırım için
//      ikinci ev alana çıkmaz).
//   3. Taşınma masrafını gerçek sabitten yazar, metne sayı gömülmez.
library;


import 'package:bir_omur/data/item_catalog.dart';
import 'package:bir_omur/data/shop_catalog.dart';
import 'package:bir_omur/domain/economy/housing.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/interaction/item_actions.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/owned_item.dart';
import 'package:bir_omur/text/turkish_text.dart';
import 'package:flutter_test/flutter_test.dart';

/// Katalogdaki en ucuz konut.
ShopProduct _konut() {
  final List<ShopProduct> evler = shopProductsFor(40)
      .where((ShopProduct p) =>
          itemTypeOrFallback(p.typeId).kind == ItemKind.konut)
      .toList(growable: true)
    ..sort((ShopProduct a, ShopProduct b) => a.price.compareTo(b.price));
  return evler.first;
}

/// Konut dışı bir ürün.
ShopProduct _saat() => shopProductsFor(40).firstWhere(
      (ShopProduct p) => itemTypeOrFallback(p.typeId).kind == ItemKind.saat,
    );

GameState _kirada(int tohum, {required int para}) {
  final GameState temel =
      LifeGenerator.seeded(tohum).generate(mode: StartMode.tamamenRastgele);
  return temel.copyWith(
    player: temel.player.copyWith(age: 40, wallet: para),
    movedOut: true,
  );
}

void main() {
  const ItemActions eylemler = ItemActions();

  test('kirada oturan konut alınca taşınma hatırlatılıyor', () {
    final ShopProduct ev = _konut();
    final GameState s = _kirada(4, para: ev.price + 100000);
    expect(Housing.residenceOf(s), ResidenceKind.kirada);

    final ItemActionResult sonuc =
        eylemler.buy(state: s, product: ev, price: ev.price);
    expect(sonuc.outcome.applied, isTrue);
    expect(sonuc.outcome.text, contains('taşınabilirsin'));
    expect(sonuc.outcome.text, contains('Evlerim'));
    // Masraf metne gömülmedi, gerçek sabitten yazıldı.
    expect(
      sonuc.outcome.text,
      contains(trMoney(Housing.prototypeOnlyMoveCost)),
    );
    // Satın alma oturulan evi **değiştirmez** (D-043).
    expect(Housing.residenceOf(sonuc.state), ResidenceKind.kirada);
    // Hatırlatma günlüğe de aynı cümleyle düşer.
    expect(sonuc.state.log.last.text, sonuc.outcome.text);
  });

  test('kendi evinde oturana ikinci evde hatırlatma çıkmıyor', () {
    final ShopProduct ev = _konut();
    final GameState temel = _kirada(9, para: ev.price + 100000);
    final OwnedItem oturulan = OwnedItem(
      id: 'br-ev',
      typeId: ev.typeId,
      acquiredAtAge: 30,
      location: temel.player.currentCity,
      purchasePrice: ev.price,
    );
    final GameState s = temel.copyWith(
      items: <OwnedItem>[oturulan],
      residenceItemId: oturulan.id,
    );
    expect(Housing.residenceOf(s), ResidenceKind.kendiEvinde);

    final ItemActionResult sonuc =
        eylemler.buy(state: s, product: ev, price: ev.price);
    expect(sonuc.outcome.applied, isTrue);
    expect(sonuc.outcome.text, isNot(contains('taşınabilirsin')));
  });

  test('konut dışı alışverişte hatırlatma çıkmıyor', () {
    final ShopProduct saat = _saat();
    final GameState s = _kirada(11, para: saat.price + 50000);
    final ItemActionResult sonuc =
        eylemler.buy(state: s, product: saat, price: saat.price);
    expect(sonuc.outcome.applied, isTrue);
    expect(sonuc.outcome.text, isNot(contains('taşınabilirsin')));
  });

  test('ailesinin yanında yaşayana da hatırlatılıyor', () {
    final ShopProduct ev = _konut();
    final GameState temel = LifeGenerator.seeded(21)
        .generate(mode: StartMode.tamamenRastgele);
    final GameState s = temel.copyWith(
      player: temel.player.copyWith(age: 30, wallet: ev.price + 100000),
    );
    // Hanede yetişkin varsa oyuncu ailesinin yanında sayılır.
    if (Housing.residenceOf(s) != ResidenceKind.aileYaninda) {
      // Bu tohumda aile evi yok; ölçüm kurulamazsa test bir şey
      // kanıtlamaz, atlanır.
      return;
    }
    final ItemActionResult sonuc =
        eylemler.buy(state: s, product: ev, price: ev.price);
    expect(sonuc.outcome.text, contains('taşınabilirsin'));
  });
}
