/// 2. el araç pazarı (D-137).
///
/// Faho'nun isteği: "2. el araç pazarı ekleyelim, içerisinde araç ilanları
/// olsun, araç detayları yazsın — 2. el araç ilanlarında olduğu gibi:
/// şasi podyede oynama yoktur, bel altı temizlik, boyalı vb."
///
/// Pazar galerilerin **yerine geçmez**, yanına eklenir: galeride sıfır ya
/// da galeri elden araç vardır, pazarda ilan sahibi vardır. Pazarın oyun
/// içindeki işi şudur: lüks/arazi/spor sınıfı bir araç, sıfır fiyatına
/// ulaşamayan bir oyuncuya **yaşlı ve yorgun hâliyle** erişilebilir olur.
/// Alınan araç envantere ilanın kondisyonuyla girer; yorgun bir araç
/// gerçekten yorgundur.
///
/// **Model yılı yazılmaz.** Oyunda takvim yılı ve tarihsel dönem motoru
/// yok (`CLAUDE.md`); ilan "8 yaşında" der, "2018 model" demez. Böylece
/// pazarın ilan dili gerçekçi kalırken oyuna gizli bir takvim girmez.
///
/// Havuz **belirlenimlidir**: aynı şehirde aynı yaşta aynı ilanlar çıkar,
/// kayda yazılmasına gerek kalmaz. Yaş değişince pazar tazelenir; yani
/// ilanlar her yıl yenilenir ama yıl içinde sayfadan çıkıp girmekle
/// değişmez.
///
/// Fiyatlar `prototypeOnly` (`docs/DESIGN_REVIEW_QUEUE.md`, Q-041).
library;

import 'package:flutter/foundation.dart';

import '../../data/city_catalog.dart';
import '../../data/item_catalog.dart';
import '../../data/shop_catalog.dart';
import '../models/game_state.dart';

/// İlan sahibinin kim olduğu.
enum UsedVehicleSeller {
  /// Aracın sahibi satıyor: biraz daha ucuz, garantisi yok.
  sahibinden('Sahibinden', 0.97),

  /// Galeri satıyor: biraz daha pahalı, evrak işi kolay.
  galeriden('Galeriden', 1.04);

  const UsedVehicleSeller(this.label, this.priceFactor);

  final String label;

  /// prototypeOnly: ilan fiyatına uygulanan çarpan.
  final double priceFactor;
}

/// İlanın durumu. İlan metinleri ve kondisyon buradan gelir.
enum UsedVehicleGrade {
  hatasiz('Hatasız', 1.08, 92),
  bakimli('Bakımlı', 1.00, 78),
  ortalama('Ortalama', 0.88, 60),
  yorgun('Yorgun', 0.72, 38);

  const UsedVehicleGrade(this.label, this.priceFactor, this.condition);

  final String label;

  /// prototypeOnly: aynı yaştaki araçlar arasında durumun fiyata etkisi.
  final double priceFactor;

  /// prototypeOnly: satın alındığında envantere giren kondisyon (0-100).
  ///
  /// `Travel.prototypeOnlyMinCarCondition` 25'tir: en yorgun ilan bile
  /// yola çıkabilir, ama bakım ister.
  final int condition;

  /// İlanın "araç detayları" satırları — gerçek 2. el ilan dili.
  List<String> get details => switch (this) {
        UsedVehicleGrade.hatasiz => const <String>[
            'Hatasız, boyasız, değişensiz',
            'Şasi, podye ve direklerde oynama yoktur',
            'Tramer kaydı yoktur',
            'Servis bakımları eksiksiz ve faturalı',
            'Muayenesi yeni yapıldı',
          ],
        UsedVehicleGrade.bakimli => const <String>[
            'Bel altı temizlik; kaportada oynama yok',
            'Şasi ve podyede oynama yoktur',
            'İki parça lokal boyalı, değişen yok',
            'Tramer kaydı düşük, ekspertiz raporu var',
            'Dört lastik yeni, bakımı çıkmış',
          ],
        UsedVehicleGrade.ortalama => const <String>[
            'Boyalı parçaları var, değişeni yok',
            'Şasi ve podyede oynama yoktur',
            'Tramer kaydı var; ekspertize götürülebilir',
            'Klima soğutur, motor ve şanzıman sağlam',
            'Döşemede yer yer yorgunluk var',
          ],
        UsedVehicleGrade.yorgun => const <String>[
            'Boyalı ve değişen parçaları var',
            'Podye düzeltmesi görmüş, şasi sağlam',
            'Tramer kaydı yüksek, fiyatına yansıtıldı',
            'Yolda kalmaz ama küçük masrafı var',
            'Kısa vadede lastik ve fren isteyecek',
          ],
      };
}

/// Pazardaki tek bir 2. el araç ilanı.
@immutable
class UsedVehicleListing {
  const UsedVehicleListing({
    required this.id,
    required this.typeId,
    required this.city,
    required this.price,
    required this.ageYears,
    required this.km,
    required this.grade,
    required this.seller,
    required this.sellerNote,
  });

  /// Şehir + yaş + tür + varyanttan türeyen kalıcı kimlik.
  final String id;

  /// Satılan aracın katalog türü.
  final String typeId;

  /// İlanın bulunduğu il. Her zaman oyuncunun yaşadığı ildir.
  final String city;

  /// İstenen fiyat (₺). Şehir katsayısı, yaş, durum ve satıcı uygulanmış.
  final int price;

  /// Aracın yaşı (yıl). Model yılı yazılmaz; oyunda takvim yoktur.
  final int ageYears;

  /// Kilometre.
  final int km;

  final UsedVehicleGrade grade;
  final UsedVehicleSeller seller;

  /// "Takasa açık." gibi ilan sahibinin tek satırlık notu.
  final String sellerNote;

  ItemType get type => itemTypeOrFallback(typeId);

  String get name => type.name;

  /// Sıfır hâlin katalog fiyatı; oyuncu ne kadar kazandığını görsün.
  int get newPrice => type.baseValue;

  /// Envantere girecek kondisyon.
  int get condition => grade.condition;

  /// İlan satırları: durum satırları + yaş/km özeti.
  List<String> get details => grade.details;

  /// [ItemActions.buy] ortak satın alma yolunu kullanabilmek için üretilen
  /// ürün kaydı. Katalogda ikinci bir kopya tutulmaz; pazar kendi ürününü
  /// burada tarif eder.
  ShopProduct get product => ShopProduct(
        typeId: typeId,
        description: '$ageYears yaşında, ${grade.label.toLowerCase()}',
        category: ShopCategory.ikinciElPazar,
        minAge: UsedVehicleMarket.minAge,
      );
}

abstract final class UsedVehicleMarket {
  /// prototypeOnly: pazardan araç almak için gereken en küçük yaş.
  ///
  /// Galerilerle aynı: araç sahibi olmak ehliyet istemez, kullanmak ister.
  static const int minAge = 18;

  /// prototypeOnly: panoda gösterilen ilan sayısı.
  static const int prototypeOnlyListingCount = 9;

  /// prototypeOnly: aracın her yılı için değer kaybı.
  static const double prototypeOnlyYearlyLoss = 0.07;

  /// prototypeOnly: yaş indirimi bu oranın altına inmez.
  static const double prototypeOnlyLossFloor = 0.35;

  /// prototypeOnly: bir yılda takılan ortalama kilometre.
  static const int prototypeOnlyKmPerYear = 14000;

  /// Pazarda ilanı çıkabilen araç türleri.
  ///
  /// Bisiklet pazara girmez: pazarın anlamı motorlu araçta.
  static List<ItemType> get sellableTypes => kItemTypes
      .where((ItemType t) =>
          t.kind == ItemKind.otomobil || t.kind == ItemKind.motosiklet)
      .toList(growable: false);

  static const List<String> _satirlar = <String>[
    'Takasa açık, ciddi alıcılar arasın.',
    'Takas olmaz, nakit alıcı arıyorum.',
    'Pazarlık payı var, gelip görmek gerek.',
    'Fiyatta esneklik yok, sebebi ilanda yazıyor.',
    'Ekspertize birlikte götürebiliriz.',
    'Acil ihtiyaçtan satılıktır.',
  ];

  /// Oyuncunun **yaşadığı ildeki** 2. el araç ilanları.
  ///
  /// Başka ilin ilanı hiçbir koşulda listeye girmez (D-066 ile aynı kural).
  /// Oyuncu 18'in altındaysa pazar boştur.
  static List<UsedVehicleListing> listingsFor(GameState state) {
    if (state.player.age < minAge) return const <UsedVehicleListing>[];

    final String sehir = state.player.currentCity;
    final List<ItemType> turler = sellableTypes;
    if (turler.isEmpty) return const <UsedVehicleListing>[];

    // Şehir + oyuncunun yaşı: aynı yıl aynı ilanlar, yıl geçince pazar
    // tazelenir. Rastgele sayı üreteci kullanılmadığı için sayfadan
    // çıkıp girmek listeyi değiştirmez ve kayda bir şey yazılmaz.
    final int tohum = _tohum(sehir) + state.player.age * 977;

    final List<UsedVehicleListing> ilanlar = <UsedVehicleListing>[];
    for (int i = 0; i < prototypeOnlyListingCount; i++) {
      final ItemType tur = turler[(tohum ~/ 3 + i * 5) % turler.length];
      final UsedVehicleGrade durum = UsedVehicleGrade
          .values[(tohum + i * 7) % UsedVehicleGrade.values.length];
      final UsedVehicleSeller satici = UsedVehicleSeller
          .values[(tohum ~/ 7 + i * 3) % UsedVehicleSeller.values.length];

      // Yorgun araç daha yaşlı olur: durum ve yaş birbirini tutsun.
      final int tabanYas = 2 + durum.index * 3;
      final int yas = tabanYas + (tohum ~/ 11 + i * 4) % 5;

      final int kmSapma = (tohum ~/ 13 + i * 9) % 5000;
      final int km = yas * prototypeOnlyKmPerYear +
          kmSapma +
          durum.index * 6000 * yas ~/ 3;

      final double yasCarpani =
          (1 - prototypeOnlyYearlyLoss * yas).clamp(prototypeOnlyLossFloor, 1.0);
      final int fiyat = _yuvarla(
        vehiclePriceIn(sehir, tur.baseValue) *
            yasCarpani *
            durum.priceFactor *
            satici.priceFactor,
      );

      ilanlar.add(
        UsedVehicleListing(
          id: 'ikinciel_${sehir}_${state.player.age}_${tur.id}_$i',
          typeId: tur.id,
          city: sehir,
          price: fiyat,
          ageYears: yas,
          km: km - km % 500,
          grade: durum,
          seller: satici,
          sellerNote: _satirlar[(tohum ~/ 17 + i * 5) % _satirlar.length],
        ),
      );
    }

    // Ucuzdan pahalıya: oyuncu bütçesine uyan ilanı üstte bulsun.
    ilanlar.sort(
      (UsedVehicleListing a, UsedVehicleListing b) =>
          a.price.compareTo(b.price),
    );
    return List<UsedVehicleListing>.unmodifiable(ilanlar);
  }

  static int _tohum(String sehir) {
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
