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
  aracGalerisi('Araç galerisi', 'Motosiklet ve otomobil', Icons.directions_car_outlined),
  emlakci('Emlakçı', 'Daire, müstakil ev, villa', Icons.apartment_outlined);

  const ShopCategory(this.label, this.description, this.icon);

  final String label;
  final String description;
  final IconData icon;
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

  // --- Araç galerisi ----------------------------------------------------
  ShopProduct(
    typeId: 'motosiklet_ekonomik',
    description: 'Küçük motorlu, ekonomik bir motosiklet.',
    category: ShopCategory.aracGalerisi,
    minAge: 18,
  ),
  ShopProduct(
    typeId: 'motosiklet_guclu',
    description: 'Daha güçlü bir motosiklet; dikkat ister.',
    category: ShopCategory.aracGalerisi,
    minAge: 18,
  ),
  ShopProduct(
    typeId: 'otomobil_ikinci_el',
    description: 'Yaşını almış ama yolda kalmayan bir otomobil.',
    category: ShopCategory.aracGalerisi,
    minAge: 18,
  ),
  ShopProduct(
    typeId: 'otomobil_ekonomik',
    description: 'Yeni, ekonomik bir otomobil.',
    category: ShopCategory.aracGalerisi,
    minAge: 18,
  ),
  ShopProduct(
    typeId: 'otomobil_orta',
    description: 'Orta sınıf; donanımı biraz daha iyi.',
    category: ShopCategory.aracGalerisi,
    minAge: 18,
  ),
  ShopProduct(
    typeId: 'otomobil_luks',
    description: 'Lüks bir otomobil. Pahalı ve göz alıcı.',
    category: ShopCategory.aracGalerisi,
    minAge: 18,
  ),
  ShopProduct(
    typeId: 'kask',
    description: 'Motosiklete binerken takılır.',
    category: ShopCategory.aracGalerisi,
    minAge: 16,
  ),
  ShopProduct(
    typeId: 'motosiklet_cantasi',
    description: 'Motosiklete takılan yük çantası.',
    category: ShopCategory.aracGalerisi,
    minAge: 16,
  ),
  ShopProduct(
    typeId: 'motosiklet_cami',
    description: 'Motosiklete takılan rüzgâr siperi.',
    category: ShopCategory.aracGalerisi,
    minAge: 16,
  ),
  ShopProduct(
    typeId: 'arac_kamerasi',
    description: 'Otomobile takılır; yol kaydı tutar.',
    category: ShopCategory.aracGalerisi,
    minAge: 18,
  ),
  ShopProduct(
    typeId: 'bebek_koltugu',
    description: 'Otomobile takılır; çocuk için güvenli koltuk.',
    category: ShopCategory.aracGalerisi,
    minAge: 18,
  ),
  ShopProduct(
    typeId: 'tavan_bagaji',
    description: 'Otomobile takılır; uzun yolda yer açar.',
    category: ShopCategory.aracGalerisi,
    minAge: 18,
  ),

  // --- Emlakçı ----------------------------------------------------------
  ShopProduct(
    typeId: 'kucuk_daire',
    description: 'Tek odalı, küçük bir daire.',
    category: ShopCategory.emlakci,
    minAge: 18,
  ),
  ShopProduct(
    typeId: 'standart_daire',
    description: 'İki yatak odalı standart bir daire.',
    category: ShopCategory.emlakci,
    minAge: 18,
  ),
  ShopProduct(
    typeId: 'mustakil_ev',
    description: 'Bahçeli, müstakil bir ev.',
    category: ShopCategory.emlakci,
    minAge: 18,
  ),
  ShopProduct(
    typeId: 'villa',
    description: 'Büyük bir ev; bakımı da büyük.',
    category: ShopCategory.emlakci,
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
