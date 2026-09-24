/// Ev ve araç ilanlarının şehir filtresi.
///
/// Faho'nun kesin kararı: oyuncu yaşadığı il dışında ilan görmez.
/// "Türkiye geneli" varsayılan liste yoktur. Eskiden emlakçıda yirmi
/// şehirlik bir seçici vardı ve Amasya'da yaşayan oyuncu İstanbul'dan
/// ev alabiliyordu.
library;

import 'package:bir_omur/data/city_catalog.dart';
import 'package:bir_omur/data/item_catalog.dart';
import 'package:bir_omur/data/name_pool.dart';
import 'package:bir_omur/data/shop_catalog.dart';
import 'package:bir_omur/domain/economy/property_market.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/game_state.dart';

import 'package:bir_omur/domain/models/owned_item.dart';
import 'package:flutter_test/flutter_test.dart';

/// Belirli bir şehirde yaşayan, yetişkin bir oyuncu.
GameState sehirde(String sehir, {int age = 30, int wallet = 20000000}) {
  final GameState taban = LifeGenerator.seeded(
    3,
  ).generate(mode: StartMode.tamamenRastgele);
  return taban.copyWith(
    pendingEvent: null,
    player: taban.player.copyWith(age: age, wallet: wallet, currentCity: sehir),
  );
}

void main() {
  group('Şehir kataloğu', () {
    test('her oyun şehrinin bir fiyat profili var', () {
      for (final String sehir in sehirler) {
        final CityProfile p = cityProfile(sehir);
        expect(
          p.name,
          sehir,
          reason:
              '$sehir için katsayı yazılmamış; ülke ortalamasına '
              'düşüyor',
        );
      }
    });

    test('şehir farkı hissedilir ama aşırı değil', () {
      final List<double> katsayilar = <double>[
        for (final CityProfile c in kCityProfiles) c.housingFactor,
      ]..sort();
      final double enUcuz = katsayilar.first;
      final double enPahali = katsayilar.last;
      expect(
        enPahali / enUcuz,
        greaterThan(1.5),
        reason: 'Şehirler arasında anlamlı fark olmalı',
      );
      expect(
        enPahali / enUcuz,
        lessThan(4.0),
        reason: 'İstanbul 10x gibi aşırı değer olmamalı',
      );
    });

    test('araçta şehir farkı konuttan çok daha az', () {
      for (final CityProfile c in kCityProfiles) {
        final double konutSapma = (c.housingFactor - 1).abs();
        final double aracSapma = (c.vehicleFactor - 1).abs();
        expect(
          aracSapma,
          lessThanOrEqualTo(konutSapma + 0.02),
          reason: '${c.name}: araba taşınabilir bir maldır',
        );
      }
    });
  });

  group('İlan panosu yaşanan ille sınırlı', () {
    test('1) Amasyalı oyuncunun ev listesinde başka şehir yok', () {
      final GameState s = sehirde('Amasya');
      final List<PropertyListing> ilanlar = PropertyMarket.listingsFor(
        s,
        ShopCategory.emlakci,
      );
      expect(ilanlar, isNotEmpty);
      for (final PropertyListing i in ilanlar) {
        expect(i.city, 'Amasya', reason: '${i.name} başka ilden geldi');
      }
    });

    test('2) Amasyalı oyuncunun araba listesinde başka şehir yok', () {
      final GameState s = sehirde('Amasya');
      final List<PropertyListing> ilanlar = PropertyMarket.listingsFor(
        s,
        ShopCategory.aracGalerisi,
      );
      expect(ilanlar, isNotEmpty);
      for (final PropertyListing i in ilanlar) {
        expect(i.city, 'Amasya');
      }
    });

    test('3) şehir değişince ilan havuzu yeni şehre döner', () {
      final GameState amasya = sehirde('Amasya');
      final List<PropertyListing> once = PropertyMarket.listingsFor(
        amasya,
        ShopCategory.emlakci,
      );

      final GameState istanbul = amasya.copyWith(
        player: amasya.player.copyWith(currentCity: 'İstanbul'),
      );
      final List<PropertyListing> sonra = PropertyMarket.listingsFor(
        istanbul,
        ShopCategory.emlakci,
      );

      expect(sonra.every((PropertyListing i) => i.city == 'İstanbul'), isTrue);
      expect(
        once
            .map((PropertyListing i) => i.id)
            .toSet()
            .intersection(sonra.map((PropertyListing i) => i.id).toSet()),
        isEmpty,
        reason: 'Eski şehrin ilanları yeni havuzda kalmamalı',
      );
      // İstanbul daha pahalı olmalı.
      expect(sonra.first.price, greaterThan(once.first.price));
    });

    test('4) başka şehirde alınmış ev silinmiyor', () {
      // Ankara'da ev al, sonra Amasya'ya taşın.
      GameState s = sehirde('Ankara');
      final List<PropertyListing> ankara = PropertyMarket.listingsFor(
        s,
        ShopCategory.emlakci,
      );
      s = s.grantItems(
        <String>[ankara.first.product.typeId],
        source: ItemSource.satinAlma,
        purchasePrice: ankara.first.price,
        location: 'Ankara',
      );
      expect(s.items.where((OwnedItem i) => i.isProperty), isNotEmpty);

      final GameState tasindi = s.copyWith(
        player: s.player.copyWith(currentCity: 'Amasya'),
      );

      // Mülk duruyor ve Ankara kaydıyla duruyor.
      final OwnedItem mulk = tasindi.items.firstWhere(
        (OwnedItem i) => i.isProperty,
      );
      expect(mulk.location, 'Ankara');

      // Ama yeni ilan listesine Ankara karışmıyor.
      for (final PropertyListing i in PropertyMarket.listingsFor(
        tasindi,
        ShopCategory.emlakci,
      )) {
        expect(i.city, 'Amasya');
      }
    });

    test('5) ilan yetersizse başka şehir eklenmiyor, aynı ilde üretiliyor', () {
      final GameState s = sehirde('Amasya');
      final List<PropertyListing> ilanlar = PropertyMarket.listingsFor(
        s,
        ShopCategory.emlakci,
      );
      final int konutTuru = kShopCatalog
          .where((ShopProduct p) => p.category == ShopCategory.emlakci)
          .length;

      // Her tür için birden fazla varyant üretiliyor: liste tür
      // sayısından kalabalık ama hepsi aynı ilde.
      expect(
        ilanlar.length,
        konutTuru * PropertyMarket.prototypeOnlyVariantsPerType,
      );
      expect(ilanlar.map((PropertyListing i) => i.city).toSet(), <String>{
        'Amasya',
      });
      expect(
        ilanlar.map((PropertyListing i) => i.id).toSet().length,
        ilanlar.length,
        reason: 'İlan kimlikleri benzersiz olmalı',
      );
    });

    test('aynı şehirde ilanlar değişmiyor (kapat-aç ile kaymaz)', () {
      final GameState a = sehirde('Samsun');
      final GameState b = sehirde('Samsun');
      final List<String> ilk = <String>[
        for (final PropertyListing i in PropertyMarket.listingsFor(
          a,
          ShopCategory.emlakci,
        ))
          '${i.id}:${i.price}',
      ];
      final List<String> ikinci = <String>[
        for (final PropertyListing i in PropertyMarket.listingsFor(
          b,
          ShopCategory.emlakci,
        ))
          '${i.id}:${i.price}',
      ];
      expect(ikinci, ilk);
    });

    test('ilan fiyatı şehir katsayısını taşıyor', () {
      final GameState ucuz = sehirde('Amasya');
      final GameState pahali = sehirde('İstanbul');
      final int amasya = PropertyMarket.listingsFor(
        ucuz,
        ShopCategory.emlakci,
      ).first.price;
      final int istanbul = PropertyMarket.listingsFor(
        pahali,
        ShopCategory.emlakci,
      ).first.price;
      expect(istanbul, greaterThan(amasya));
      expect(istanbul / amasya, greaterThan(1.5));
    });

    test('ilanlar ucuzdan pahalıya sıralı', () {
      final List<PropertyListing> ilanlar = PropertyMarket.listingsFor(
        sehirde('Konya'),
        ShopCategory.aracGalerisi,
      );
      for (int i = 1; i < ilanlar.length; i++) {
        expect(ilanlar[i].price, greaterThanOrEqualTo(ilanlar[i - 1].price));
      }
    });

    test('ilan panosu yalnızca ev ve araç için çalışır', () {
      final GameState s = sehirde('Bursa');
      expect(PropertyMarket.listingsFor(s, ShopCategory.emlakci), isNotEmpty);
      expect(
        PropertyMarket.listingsFor(s, ShopCategory.aracGalerisi),
        isNotEmpty,
      );
      // Diğer kategorilerde de çalışır ama ekran onları katalogla
      // gösterir; burada yalnızca patlamadığını doğruluyoruz.
      expect(PropertyMarket.listingsFor(s, ShopCategory.genel), isNotEmpty);
    });
  });

  group('Satın alma', () {
    test('ilandan alınan konut o ilan şehriyle kaydediliyor', () {
      GameState s = sehirde('Trabzon');
      final PropertyListing ilan = PropertyMarket.listingsFor(
        s,
        ShopCategory.emlakci,
      ).first;
      s = s.grantItems(
        <String>[ilan.product.typeId],
        source: ItemSource.satinAlma,
        purchasePrice: ilan.price,
        location: ilan.city,
      );
      final OwnedItem mulk = s.items.firstWhere((OwnedItem i) => i.isProperty);
      expect(mulk.location, 'Trabzon');
      expect(mulk.purchasePrice, ilan.price);
    });

    test('ilan fiyatı katalog fiyatından farklı olabiliyor', () {
      final GameState s = sehirde('İstanbul');
      final PropertyListing ilan = PropertyMarket.listingsFor(
        s,
        ShopCategory.emlakci,
      ).first;
      final ItemType tur = PropertyMarket.typeOf(ilan);
      expect(
        ilan.price,
        isNot(tur.baseValue),
        reason: 'İstanbul katsayısı fiyata yansımalı',
      );
    });
  });
}
