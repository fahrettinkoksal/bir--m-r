/// Ev ve araç **ilan panosu**: yalnızca oyuncunun yaşadığı ildeki ilanlar.
///
/// Faho'nun kesin kararı: oyuncu ev ya da araba ararken yaşadığı il
/// dışında ilan görmez. "Türkiye geneli" varsayılan liste yoktur.
/// Amasya'da yaşayan oyuncuya Samsun ya da İstanbul ilanı çıkmaz.
///
/// Kurallar:
/// - İlan havuzu **yaşanan şehirden** türetilir; taşınınca kendiliğinden
///   yenilenir.
/// - İlan azsa başka şehir ilanı eklenmez; aynı şehirde yeni ilan
///   üretilir. Katalogdaki her tür, şehre özgü varyantlarla çoğaltılır.
/// - Daha önce **başka şehirde alınmış mülk silinmez**; o, ilan panosu
///   değil envanter meselesidir. Ankara'da alınan ev, oyuncu Amasya'ya
///   taşınsa da Varlıklarım'da durur.
/// - Fiyat şehir katsayısıyla hesaplanır (`lib/data/city_catalog.dart`).
///
/// Havuz **belirlenimlidir**: aynı şehirde aynı ilanlar görünür, kayda
/// yazılmasına gerek kalmaz ve uygulama kapanıp açılınca ilanlar
/// değişmez.
library;

import '../../data/city_catalog.dart';
import '../../data/item_catalog.dart';
import '../../data/shop_catalog.dart';
import '../models/game_state.dart';

/// Panodaki tek bir ilan.
class PropertyListing {
  const PropertyListing({
    required this.id,
    required this.product,
    required this.city,
    required this.price,
    required this.note,
  });

  /// Şehir + ürün + varyanttan türetilen kalıcı kimlik.
  final String id;

  final ShopProduct product;

  /// İlanın bulunduğu il. Her zaman oyuncunun yaşadığı ildir.
  final String city;

  /// Şehir katsayısı ve varyant uygulanmış fiyat (₺).
  final int price;

  /// "3. kat, güney cephe" ya da "2019 model, 96.000 km" gibi kısa satır.
  final String note;

  String get name => product.name;
}

abstract final class PropertyMarket {
  /// prototypeOnly: her tür için üretilen varyant sayısı.
  ///
  /// İlan sayısı azaldığında başka şehirden ilan çekmek yerine aynı
  /// şehirde yeni varyant üretilir; bu sabit "kaç tane" sorusunun
  /// cevabıdır.
  static const int prototypeOnlyVariantsPerType = 3;

  /// Konut ilanlarının kat/cephe seçenekleri.
  static const List<String> _konutNotlari = <String>[
    'ara kat, güney cephe',
    'yüksek kat, asansörlü',
    'giriş kat, bahçe kullanımlı',
    'ara kat, doğalgazlı',
    'son kat, çatı yalıtımlı',
  ];

  /// Araç ilanlarının durum seçenekleri.
  static const List<String> _aracNotlari = <String>[
    'az kullanılmış, bakımlı',
    'orta yaşlı, düzenli servisli',
    'yüksek kilometreli, uygun fiyatlı',
    'tek elden, hasarsız',
    'boyalı ama sağlam',
  ];

  /// prototypeOnly: varyantın fiyata etkisi (sırayla yukarıdaki notlara).
  static const List<double> _notCarpanlari = <double>[
    1.00,
    1.08,
    0.88,
    1.04,
    0.92,
  ];

  /// Oyuncunun **yaşadığı ildeki** ilanlar.
  ///
  /// Başka ilin ilanı hiçbir koşulda listeye girmez.
  static List<PropertyListing> listingsFor(
    GameState state,
    ShopCategory category,
  ) {
    final String sehir = state.player.currentCity;
    final List<ShopProduct> urunler = shopProductsIn(
      category,
      state.player.age,
    );
    if (urunler.isEmpty) return const <PropertyListing>[];

    final bool konut = category == ShopCategory.emlakci;
    final List<String> notlar = konut ? _konutNotlari : _aracNotlari;

    // Şehir adından belirlenimli bir başlangıç noktası: aynı şehirde
    // aynı ilanlar, taşınınca başka ilanlar.
    final int tohum = _sehirTohumu(sehir);

    final List<PropertyListing> ilanlar = <PropertyListing>[];
    for (int u = 0; u < urunler.length; u++) {
      final ShopProduct urun = urunler[u];
      for (int v = 0; v < prototypeOnlyVariantsPerType; v++) {
        final int secim = (tohum + u * 7 + v * 3) % notlar.length;
        final double carpan = _notCarpanlari[secim];
        final int taban = konut
            ? housingPriceIn(sehir, urun.price)
            : vehiclePriceIn(sehir, urun.price);
        ilanlar.add(
          PropertyListing(
            id: '${sehir}_${urun.typeId}_$v',
            product: urun,
            city: sehir,
            price: _yuvarla(taban * carpan),
            note: notlar[secim],
          ),
        );
      }
    }
    ilanlar.sort(
      (PropertyListing a, PropertyListing b) => a.price.compareTo(b.price),
    );
    return List<PropertyListing>.unmodifiable(ilanlar);
  }

  /// Bu ilanın hangi eşya türü olduğu.
  static ItemType typeOf(PropertyListing listing) => listing.product.type;

  static int _sehirTohumu(String sehir) {
    int t = 0;
    for (final int kod in sehir.codeUnits) {
      t = (t * 31 + kod) % 100000;
    }
    return t;
  }

  static int _yuvarla(double tutar) {
    if (tutar < 1000) return tutar.round();
    return (tutar / 1000).round() * 1000;
  }
}
