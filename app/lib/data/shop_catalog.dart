/// Mağazalar: genel mağaza, elektronik, spor ve hobi, araç galerisi ve
/// emlakçı.
///
/// Fiyatlar eşya kataloğundaki temel değerden gelir, böylece aynı ürün iki
/// yerde farklı fiyatlanmaz ve ikinci bir envanter/ekonomi sistemi oluşmaz.
/// Ölçek `lib/data/economy.dart` tablosuna dayanır.
///
/// Araçlar ve **otomobile özgü aksesuarlar** galeriden 18 yaşından itibaren
/// satın alınabilir (D-034, D-042). Motosiklet kaskı ve motosiklete özgü
/// parçalar 16 yaşında alınabilir. Aksesuar almak veya araç sahibi olmak
/// **araç sürme hakkı vermez**: sürmek ehliyet ister.
///
/// Eski açıklama: araçlar galeriden **18 yaşından itibaren** alınabilir (D-034);
/// miras veya hediye yoluyla daha küçük yaşta araç sahibi olmak mümkündür,
/// ancak aracı kullanmak ehliyet ister.
///
/// Değerler `prototypeOnly` (`docs/DESIGN_REVIEW_QUEUE.md`, Q-041, Q-055).
library;

import 'package:flutter/material.dart';

import 'item_catalog.dart';

/// Mağaza kategorisi. Her kategori ayrı bir alt sayfadır.
enum ShopCategory {
  genel('Genel mağaza', 'Gündelik eşya, kitap, kıyafet', Icons.storefront_outlined),
  elektronik('Elektronik', 'Telefon, bilgisayar, konsol', Icons.devices_outlined),
  sporHobi('Spor ve hobi', 'Spor ekipmanı, müzik, kamp', Icons.sports_basketball_outlined),
  // --- Araç galerileri (D-079) -----------------------------------------
  //
  // Tek bir "Araç galerisi" hem ikinci el otomobili hem lüks otomobili
  // aynı rafta gösteriyordu. Galeriler kademeye ayrıldı: oyuncu bütçesine
  // uyan yere gidiyor ve ucuz galerinin **gerçek bir bedeli** var
  // (masraf olayları).
  galeriUcuz(
    'Uygun fiyatlı galeri',
    'İkinci el ve yıpranmış otomobiller',
    Icons.car_repair_outlined,
  ),
  galeriOrta(
    'Orta sınıf galeri',
    'Ekonomik, aile ve orta sınıf otomobiller',
    Icons.directions_car_outlined,
  ),
  galeriLuks(
    'Lüks galeri',
    'Lüks, spor ve prestij otomobilleri',
    Icons.car_rental_outlined,
  ),
  motorUcuz(
    'Motosiklet galerisi',
    'Scooter ve ekonomik motosikletler',
    Icons.two_wheeler_outlined,
  ),
  motorLuks(
    'Büyük motosiklet galerisi',
    'Güçlü ve tur motosikletleri',
    Icons.motorcycle_outlined,
  ),
  otoAksesuar(
    'Oto aksesuarcısı',
    'Otomobile takılan parçalar',
    Icons.settings_outlined,
  ),
  motorAksesuar(
    'Motosiklet aksesuarcısı',
    'Kask, çanta, rüzgâr siperi',
    Icons.sports_motorsports_outlined,
  ),

  // --- Emlakçılar (D-079) ----------------------------------------------
  emlakciOrta(
    'Emlakçı',
    'Küçük ve standart daireler',
    Icons.apartment_outlined,
  ),
  emlakciLuks(
    'Lüks emlak ofisi',
    'Müstakil ev ve villa',
    Icons.villa_outlined,
  );

  const ShopCategory(this.label, this.description, this.icon);

  final String label;
  final String description;
  final IconData icon;

  /// Bu kategori konut satıyor mu? (D-066: şehir filtresi ve ilan listesi.)
  bool get isHousing =>
      this == ShopCategory.emlakciOrta || this == ShopCategory.emlakciLuks;

  /// Bu kategori araç satıyor mu? Aksesuarcılar araç satmaz.
  bool get isVehicle =>
      this == ShopCategory.galeriUcuz ||
      this == ShopCategory.galeriOrta ||
      this == ShopCategory.galeriLuks ||
      this == ShopCategory.motorUcuz ||
      this == ShopCategory.motorLuks;

  /// Şehir bazlı ilan listesiyle mi gösterilir? (D-066)
  bool get isListed => isHousing || isVehicle;

  /// Bu galeriden alınan araç masraf çıkarabilir mi? (D-079)
  ///
  /// Yalnızca uygun fiyatlı galeri: ucuz araç gerçekten başa iş açar.
  bool get cheapVehicles => this == ShopCategory.galeriUcuz;
}

/// Mağazada satılan bir ürün.
@immutable
class ShopProduct {
  const ShopProduct({
    required this.typeId,
    required this.description,
    required this.category,
    this.minAge = 0,
  });

  /// Satılan eşya türü.
  final String typeId;

  /// Ürünün ne işe yaradığını anlatan kısa satır.
  final String description;

  /// Hangi mağazada satıldığı.
  final ShopCategory category;

  /// prototypeOnly: satın alabilmek için gereken en küçük yaş.
  final int minAge;

  ItemType get type => itemTypeOrFallback(typeId);

  String get name => type.name;

  /// Sıfır ürünün fiyatı.
  int get price => type.baseValue;
}

const List<ShopProduct> kShopCatalog = <ShopProduct>[
  // --- Genel mağaza -----------------------------------------------------
  ShopProduct(
    typeId: 'bisiklet_zili',
    description: 'Bisiklete takılır. Sokakta kimse duymazlık edemez.',
    category: ShopCategory.genel,
    minAge: 6,
  ),
  ShopProduct(
    typeId: 'bisiklet_kornasi',
    description: 'Bisiklete takılır; zilden gürültülü olanı.',
    category: ShopCategory.genel,
    minAge: 6,
  ),
  ShopProduct(
    typeId: 'bisiklet_reflektoru',
    description: 'Bisiklete takılır. Akşamüstü görünür olmanı sağlar.',
    category: ShopCategory.genel,
    minAge: 6,
  ),
  ShopProduct(
    typeId: 'bisiklet_susu',
    description: 'Gidona takılan küçük süs.',
    category: ShopCategory.genel,
    minAge: 6,
  ),
  ShopProduct(
    typeId: 'bisiklet_bakim_seti',
    description: 'Yağ, bez ve birkaç anahtar. Bakımı ucuzlatır.',
    category: ShopCategory.genel,
    minAge: 8,
  ),
  ShopProduct(
    typeId: 'yoyo',
    description: 'Ucuz ve eğlenceli. Küçük bir hediye olur.',
    category: ShopCategory.genel,
    minAge: 5,
  ),
  ShopProduct(
    typeId: 'kutu_oyunu',
    description: 'Kalabalık akşamları kurtaran kutu oyunu.',
    category: ShopCategory.genel,
    minAge: 7,
  ),
  ShopProduct(
    typeId: 'hikaye_kitabi',
    description: 'Kısa hikâyeler; okuması kolay.',
    category: ShopCategory.genel,
    minAge: 6,
  ),
  ShopProduct(
    typeId: 'roman',
    description: 'Uzun bir roman. Sabır ister.',
    category: ShopCategory.genel,
    minAge: 12,
  ),
  ShopProduct(
    typeId: 'defter',
    description: 'Not tutmak, liste yapmak, karalamak için.',
    category: ShopCategory.genel,
    minAge: 6,
  ),
  ShopProduct(
    typeId: 'cizim_seti',
    description: 'Kalemler, boyalar ve bir blok.',
    category: ShopCategory.genel,
    minAge: 7,
  ),
  ShopProduct(
    typeId: 'kiyafet',
    description: 'Yeni bir kıyafet; görünüşüne iyi gelir.',
    category: ShopCategory.genel,
    minAge: 8,
  ),
  ShopProduct(
    typeId: 'spor_ayakkabi',
    description: 'Rahat, dayanıklı bir spor ayakkabı.',
    category: ShopCategory.genel,
    minAge: 8,
  ),
  ShopProduct(
    typeId: 'kol_saati',
    description: 'Basit ama sağlam bir kol saati.',
    category: ShopCategory.genel,
    minAge: 12,
  ),
  ShopProduct(
    typeId: 'cay_takimi',
    description: 'Eve misafir geldiğinde işe yarar.',
    category: ShopCategory.genel,
    minAge: 16,
  ),

  // --- Elektronik -------------------------------------------------------
  ShopProduct(
    typeId: 'kulaklik',
    description: 'Yolda ve derste (ders hariç) iyi gider.',
    category: ShopCategory.elektronik,
    minAge: 10,
  ),
  ShopProduct(
    typeId: 'radyo',
    description: 'Küçük, taşınabilir bir radyo.',
    category: ShopCategory.elektronik,
    minAge: 8,
  ),
  ShopProduct(
    typeId: 'akilli_saat',
    description: 'Adım sayar, saati gösterir, bildirim yağdırır.',
    category: ShopCategory.elektronik,
    minAge: 13,
  ),
  ShopProduct(
    typeId: 'telefon',
    description: 'Akıllı telefon. Sosyal medya için de işe yarar.',
    category: ShopCategory.elektronik,
    minAge: 12,
  ),
  ShopProduct(
    typeId: 'oyun_konsolu',
    description: 'Oyun konsolu; akşamları hızlı geçirir.',
    category: ShopCategory.elektronik,
    minAge: 10,
  ),
  ShopProduct(
    typeId: 'bilgisayar',
    description: 'Dizüstü bilgisayar; okul ve iş için.',
    category: ShopCategory.elektronik,
    minAge: 12,
  ),

  // --- Spor ve hobi -----------------------------------------------------
  ShopProduct(
    typeId: 'futbol_topu',
    description: 'Sahada da sokakta da olur.',
    category: ShopCategory.sporHobi,
    minAge: 6,
  ),
  ShopProduct(
    typeId: 'agirlik_seti',
    description: 'Evde çalışmak için küçük bir ağırlık seti.',
    category: ShopCategory.sporHobi,
    minAge: 15,
  ),
  ShopProduct(
    typeId: 'gitar',
    description: 'Öğrenmesi zaman ister; çalması keyifli.',
    category: ShopCategory.sporHobi,
    minAge: 10,
  ),
  ShopProduct(
    typeId: 'kamp_cadiri',
    description: 'İki kişilik bir çadır.',
    category: ShopCategory.sporHobi,
    minAge: 14,
  ),
  ShopProduct(
    typeId: 'bisiklet',
    description: 'Şehirde ve kırda işe yarayan bir bisiklet.',
    category: ShopCategory.sporHobi,
    minAge: 7,
  ),

  // --- Uygun fiyatlı galeri (D-079) -------------------------------------
  //
  // Ucuz araç gerçekten ucuzdur ve gerçekten başa iş açar: bu galeriden
  // alınan otomobiller yıl içinde masraf olayı üretebilir.
  ShopProduct(
    typeId: 'otomobil_hurdaya_yakin',
    description:
        'Çok yıpranmış; ucuz ama tamirciyle tanışacaksın.',
    category: ShopCategory.galeriUcuz,
    minAge: 18,
  ),
  ShopProduct(
    typeId: 'otomobil_ikinci_el',
    description: 'Yaşını almış ama yolda kalmayan bir otomobil.',
    category: ShopCategory.galeriUcuz,
    minAge: 18,
  ),
  ShopProduct(
    typeId: 'otomobil_ekonomik',
    description: 'Yeni, ekonomik bir otomobil.',
    category: ShopCategory.galeriUcuz,
    minAge: 18,
  ),

  // --- Orta sınıf galeri ------------------------------------------------
  ShopProduct(
    typeId: 'otomobil_aile',
    description: 'Geniş bagaj, rahat arka koltuk.',
    category: ShopCategory.galeriOrta,
    minAge: 18,
  ),
  ShopProduct(
    typeId: 'otomobil_orta',
    description: 'Orta sınıf; donanımı biraz daha iyi.',
    category: ShopCategory.galeriOrta,
    minAge: 18,
  ),
  ShopProduct(
    typeId: 'otomobil_arazi',
    description: 'Yüksek gövde; kötü yolda rahat.',
    category: ShopCategory.galeriOrta,
    minAge: 18,
  ),

  // --- Lüks galeri ------------------------------------------------------
  ShopProduct(
    typeId: 'otomobil_luks',
    description: 'Lüks bir otomobil. Pahalı ve göz alıcı.',
    category: ShopCategory.galeriLuks,
    minAge: 18,
  ),
  ShopProduct(
    typeId: 'otomobil_spor',
    description: 'Hızlı, alçak ve herkesin dönüp baktığı.',
    category: ShopCategory.galeriLuks,
    minAge: 18,
  ),
  ShopProduct(
    typeId: 'otomobil_prestij',
    description: 'Bu otomobil bir şey söylüyor; sen söylemesen de.',
    category: ShopCategory.galeriLuks,
    minAge: 18,
  ),

  // --- Motosiklet galerisi ----------------------------------------------
  ShopProduct(
    typeId: 'motosiklet_scooter',
    description: 'Şehir içi için küçük ve pratik.',
    category: ShopCategory.motorUcuz,
    minAge: 18,
  ),
  ShopProduct(
    typeId: 'motosiklet_ekonomik',
    description: 'Küçük motorlu, ekonomik bir motosiklet.',
    category: ShopCategory.motorUcuz,
    minAge: 18,
  ),

  // --- Büyük motosiklet galerisi ----------------------------------------
  ShopProduct(
    typeId: 'motosiklet_guclu',
    description: 'Daha güçlü bir motosiklet; dikkat ister.',
    category: ShopCategory.motorLuks,
    minAge: 18,
  ),
  ShopProduct(
    typeId: 'motosiklet_tur',
    description: 'Uzun yol için; koltuğu ve deposu geniş.',
    category: ShopCategory.motorLuks,
    minAge: 18,
  ),

  // --- Oto aksesuarcısı -------------------------------------------------
  ShopProduct(
    typeId: 'arac_kamerasi',
    description: 'Otomobile takılır; yol kaydı tutar.',
    category: ShopCategory.otoAksesuar,
    minAge: 18,
  ),
  ShopProduct(
    typeId: 'bebek_koltugu',
    description: 'Otomobile takılır; çocuk için güvenli koltuk.',
    category: ShopCategory.otoAksesuar,
    minAge: 18,
  ),
  ShopProduct(
    typeId: 'tavan_bagaji',
    description: 'Otomobile takılır; uzun yolda yer açar.',
    category: ShopCategory.otoAksesuar,
    minAge: 18,
  ),

  // --- Motosiklet aksesuarcısı ------------------------------------------
  //
  // Kask ve motosiklete özgü parçalar 16 yaşından itibaren alınabilir
  // (D-042); aksesuar almak sürme hakkı vermez.
  ShopProduct(
    typeId: 'kask',
    description: 'Motosiklete binerken takılır.',
    category: ShopCategory.motorAksesuar,
    minAge: 16,
  ),
  ShopProduct(
    typeId: 'motosiklet_cantasi',
    description: 'Motosiklete takılan yük çantası.',
    category: ShopCategory.motorAksesuar,
    minAge: 16,
  ),
  ShopProduct(
    typeId: 'motosiklet_cami',
    description: 'Motosiklete takılan rüzgâr siperi.',
    category: ShopCategory.motorAksesuar,
    minAge: 16,
  ),

  // --- Emlakçı ----------------------------------------------------------
  ShopProduct(
    typeId: 'kucuk_daire',
    description: 'Tek odalı, küçük bir daire.',
    category: ShopCategory.emlakciOrta,
    minAge: 18,
  ),
  ShopProduct(
    typeId: 'standart_daire',
    description: 'İki yatak odalı standart bir daire.',
    category: ShopCategory.emlakciOrta,
    minAge: 18,
  ),

  // --- Lüks emlak ofisi -------------------------------------------------
  ShopProduct(
    typeId: 'mustakil_ev',
    description: 'Bahçeli, müstakil bir ev.',
    category: ShopCategory.emlakciLuks,
    minAge: 18,
  ),
  ShopProduct(
    typeId: 'villa',
    description: 'Büyük bir ev; bakımı da büyük.',
    category: ShopCategory.emlakciLuks,
    minAge: 18,
  ),
];

/// Oyuncunun yaşına uygun ürünler.
List<ShopProduct> shopProductsFor(int age) =>
    kShopCatalog.where((ShopProduct p) => age >= p.minAge).toList(growable: false);

/// Bir kategorideki, yaşa uygun ürünler.
List<ShopProduct> shopProductsIn(ShopCategory category, int age) => kShopCatalog
    .where((ShopProduct p) => p.category == category && age >= p.minAge)
    .toList(growable: false);

/// Bu yaşta gerçekten ürün gösteren kategoriler.
///
/// Boş kategori menüde gösterilmez; sahte düğme olmaz.
List<ShopCategory> shopCategoriesFor(int age) => ShopCategory.values
    .where((ShopCategory c) => shopProductsIn(c, age).isNotEmpty)
    .toList(growable: false);

ShopProduct? shopProductByTypeId(String typeId) {
  for (final ShopProduct p in kShopCatalog) {
    if (p.typeId == typeId) return p;
  }
  return null;
}
