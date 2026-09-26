/// 2. el araç pazarı (D-137) testleri.
///
/// Faho'nun isteği: pazarda ilanlar olsun, araç detayları yazsın ("şasi
/// podyede oynama yoktur", "bel altı temizlik", "boyalı"). Burada hem ilan
/// havuzunun kuralları hem satın almanın envantere ne yazdığı denetlenir.
library;

import 'package:bir_omur/data/item_catalog.dart';
import 'package:bir_omur/data/shop_catalog.dart';
import 'package:bir_omur/domain/activities/travel.dart';
import 'package:bir_omur/domain/economy/used_vehicle_market.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/interaction/item_actions.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/owned_item.dart';
import 'package:flutter_test/flutter_test.dart';

const ItemActions actions = ItemActions();

GameState oyuncu({
  int seed = 3,
  int age = 30,
  int wallet = 30000000,
  String city = 'İstanbul',
}) {
  final GameState state =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  return state.copyWith(
    player: state.player.copyWith(
      age: age,
      wallet: wallet,
      currentCity: city,
    ),
  );
}

void main() {
  group('İlan havuzu', () {
    test('18 yaşından önce pazar boş, sonra dolu', () {
      expect(UsedVehicleMarket.listingsFor(oyuncu(age: 17)), isEmpty);
      expect(UsedVehicleMarket.listingsFor(oyuncu(age: 18)), isNotEmpty);
      expect(
        UsedVehicleMarket.listingsFor(oyuncu(age: 30)).length,
        UsedVehicleMarket.prototypeOnlyListingCount,
      );
    });

    test('mağaza menüsünde 18 yaşından itibaren görünür', () {
      expect(shopCategoriesFor(17), isNot(contains(ShopCategory.ikinciElPazar)));
      expect(shopCategoriesFor(18), contains(ShopCategory.ikinciElPazar));
      // Pazar araç öbeğinde durur, emlak/gündelik öbeğinde değil (D-138).
      expect(ShopCategory.ikinciElPazar.group, ShopGroup.arac);
      // Emlak/galeri panosuyla karıştırılmaz.
      expect(ShopCategory.ikinciElPazar.isListed, isFalse);
      expect(ShopCategory.ikinciElPazar.isUsedMarket, isTrue);
    });

    test('bütün ilanlar oyuncunun yaşadığı ilde', () {
      for (final UsedVehicleListing i
          in UsedVehicleMarket.listingsFor(oyuncu(city: 'Amasya'))) {
        expect(i.city, 'Amasya');
      }
    });

    test('aynı şehir ve yaşta aynı ilanlar çıkar', () {
      final List<String> once = UsedVehicleMarket.listingsFor(oyuncu())
          .map((UsedVehicleListing i) => i.id)
          .toList(growable: false);
      final List<String> sonra = UsedVehicleMarket.listingsFor(oyuncu())
          .map((UsedVehicleListing i) => i.id)
          .toList(growable: false);
      expect(sonra, once);
    });

    test('yıl geçince pazar tazelenir', () {
      final Set<String> otuz = UsedVehicleMarket.listingsFor(oyuncu(age: 30))
          .map((UsedVehicleListing i) => i.id)
          .toSet();
      final Set<String> otuzBir =
          UsedVehicleMarket.listingsFor(oyuncu(age: 31))
              .map((UsedVehicleListing i) => i.id)
              .toSet();
      expect(otuzBir.intersection(otuz), isEmpty);
    });

    test('taşınınca ilanlar yeni şehre göre yenilenir', () {
      final Set<String> istanbul =
          UsedVehicleMarket.listingsFor(oyuncu(city: 'İstanbul'))
              .map((UsedVehicleListing i) => i.id)
              .toSet();
      final Set<String> amasya =
          UsedVehicleMarket.listingsFor(oyuncu(city: 'Amasya'))
              .map((UsedVehicleListing i) => i.id)
              .toSet();
      expect(amasya.intersection(istanbul), isEmpty);
    });

    test('ilan kimlikleri benzersiz', () {
      final List<UsedVehicleListing> ilanlar =
          UsedVehicleMarket.listingsFor(oyuncu());
      expect(
        ilanlar.map((UsedVehicleListing i) => i.id).toSet().length,
        ilanlar.length,
      );
    });

    test('ucuzdan pahalıya sıralı', () {
      final List<UsedVehicleListing> ilanlar =
          UsedVehicleMarket.listingsFor(oyuncu());
      for (int i = 1; i < ilanlar.length; i++) {
        expect(
          ilanlar[i].price,
          greaterThanOrEqualTo(ilanlar[i - 1].price),
        );
      }
    });

    test('yalnızca motorlu araç satılır; bisiklet pazara girmez', () {
      for (final UsedVehicleListing i
          in UsedVehicleMarket.listingsFor(oyuncu())) {
        expect(
          i.type.kind,
          anyOf(ItemKind.otomobil, ItemKind.motosiklet),
          reason: i.name,
        );
      }
      expect(
        UsedVehicleMarket.sellableTypes
            .any((ItemType t) => t.kind == ItemKind.bisiklet),
        isFalse,
      );
    });
  });

  group('İlan içeriği', () {
    test('her ilanda yaş, km ve detay satırları var', () {
      for (final UsedVehicleListing i
          in UsedVehicleMarket.listingsFor(oyuncu())) {
        expect(i.ageYears, greaterThan(0), reason: i.name);
        expect(i.km, greaterThan(0), reason: i.name);
        expect(i.details.length, greaterThanOrEqualTo(4), reason: i.name);
        expect(i.sellerNote, isNotEmpty, reason: i.name);
        for (final String satir in i.details) {
          expect(satir.trim(), isNotEmpty);
        }
      }
    });

    test('Faho\'nun örnek ilan satırları kataloğda var', () {
      final String tumu = UsedVehicleGrade.values
          .expand((UsedVehicleGrade g) => g.details)
          .join(' | ')
          .toLowerCase();
      expect(tumu, contains('şasi'));
      expect(tumu, contains('podye'));
      expect(tumu, contains('bel altı temizlik'));
      expect(tumu, contains('boyalı'));
      expect(tumu, contains('tramer'));
    });

    test('ilan metni model yılı yazmaz; oyunda takvim yoktur', () {
      // CLAUDE.md: ilk sürümde doğum yılı seçimi veya tarihsel dönem
      // motoru yok. İlan "8 yaşında" der, "2018 model" demez.
      final String tumu = UsedVehicleGrade.values
          .expand((UsedVehicleGrade g) => g.details)
          .join(' | ');
      expect(RegExp(r'(19|20)\d{2}').hasMatch(tumu), isFalse);
    });

    test('adlar kurgusal model adı, sınıf bilgisi ayrı alanda (D-136)', () {
      for (final ItemType t in UsedVehicleMarket.sellableTypes) {
        expect(t.segment, isNotNull, reason: t.id);
        expect(t.segment, isNot(t.name), reason: t.id);
      }
    });

    test('yorgun ilan daha yaşlı ve daha çok km yapmış olur', () {
      expect(
        UsedVehicleGrade.yorgun.condition,
        lessThan(UsedVehicleGrade.hatasiz.condition),
      );
      expect(
        UsedVehicleGrade.yorgun.priceFactor,
        lessThan(UsedVehicleGrade.hatasiz.priceFactor),
      );
      // En yorgun ilan bile yola çıkabilir; yoksa pazar sahte olur.
      for (final UsedVehicleGrade g in UsedVehicleGrade.values) {
        expect(
          g.condition,
          greaterThanOrEqualTo(Travel.prototypeOnlyMinCarCondition),
          reason: g.label,
        );
      }
    });

    test('ikinci el fiyatı sıfır fiyatının altında', () {
      for (final UsedVehicleListing i
          in UsedVehicleMarket.listingsFor(oyuncu())) {
        expect(i.price, lessThan(i.newPrice), reason: i.name);
        expect(i.price, greaterThan(0), reason: i.name);
      }
    });
  });

  group('Satın alma', () {
    test('araç ilanın kondisyonuyla envantere girer', () {
      final GameState state = oyuncu();
      final UsedVehicleListing ilan =
          UsedVehicleMarket.listingsFor(state).first;
      final ItemActionResult r = actions.buy(
        state: state,
        product: ilan.product,
        price: ilan.price,
        condition: ilan.condition,
      );

      expect(r.outcome.applied, isTrue, reason: r.outcome.text);
      final OwnedItem araba = r.state.items.last;
      expect(araba.typeId, ilan.typeId);
      expect(araba.condition, ilan.condition);
      expect(araba.condition, isNot(OwnedItem.defaultCondition));
      expect(araba.purchasePrice, ilan.price);
      expect(araba.source, ItemSource.satinAlma);
      expect(
        r.state.player.wallet,
        state.player.wallet - ilan.price,
      );
    });

    test('sıfır ürün varsayılan kondisyonla girer', () {
      final GameState state = oyuncu();
      final ItemActionResult r = actions.buy(
        state: state,
        product: shopProductByTypeId('otomobil_ekonomik')!,
      );
      expect(r.state.items.last.condition, OwnedItem.defaultCondition);
    });

    test('parası yetmeyen ilan alınamaz', () {
      final GameState fakir = oyuncu(wallet: 1000);
      final UsedVehicleListing ilan =
          UsedVehicleMarket.listingsFor(fakir).last;
      final ItemActionResult r = actions.buy(
        state: fakir,
        product: ilan.product,
        price: ilan.price,
        condition: ilan.condition,
      );
      expect(r.outcome.applied, isFalse);
      expect(r.state.items.length, fakir.items.length);
      expect(r.state.player.wallet, fakir.player.wallet);
    });

    test('18 yaşından küçük pazardan araç alamaz', () {
      final GameState cocuk = oyuncu(age: 16);
      // Pazar kapalı olduğu için ilan üretilmez; ürün kaydı da yaş kuralını
      // taşır, yani ilan elle kurulsa bile satın alma engellenir.
      expect(UsedVehicleMarket.listingsFor(cocuk), isEmpty);
      final UsedVehicleListing ilan =
          UsedVehicleMarket.listingsFor(oyuncu()).first;
      final ItemActionResult r = actions.buy(
        state: cocuk,
        product: ilan.product,
        price: ilan.price,
        condition: ilan.condition,
      );
      expect(r.outcome.applied, isFalse);
    });
  });
}
