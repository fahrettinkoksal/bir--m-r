/// Küçük başlangıç mağazası.
///
/// Geniş bir katalog değil; gerçekten çalışan birkaç ürün. Fiyatlar eşya
/// kataloğundaki temel değerden gelir, böylece aynı ürün iki yerde farklı
/// fiyatlanmaz. Kredi, banka, yatırım, emlak ve otomobil **yok**.
///
/// Değerler `prototypeOnly` (`docs/DESIGN_REVIEW_QUEUE.md`, Q-041).
library;

import 'package:flutter/foundation.dart';

import 'item_catalog.dart';

/// Mağazada satılan bir ürün.
@immutable
class ShopProduct {
  const ShopProduct({
    required this.typeId,
    required this.description,
    this.minAge = 0,
  });

  /// Satılan eşya türü.
  final String typeId;

  /// Ürünün ne işe yaradığını anlatan kısa satır.
  final String description;

  /// prototypeOnly: satın alabilmek için gereken en küçük yaş.
  final int minAge;

  ItemType get type => itemTypeOrFallback(typeId);

  String get name => type.name;

  /// Sıfır ürünün fiyatı.
  int get price => type.baseValue;
}

const List<ShopProduct> kShopCatalog = <ShopProduct>[
  ShopProduct(
    typeId: 'bisiklet_zili',
    description: 'Bisiklete takılır. Sokakta kimse duymazlık edemez.',
    minAge: 6,
  ),
  ShopProduct(
    typeId: 'bisiklet_kornasi',
    description: 'Bisiklete takılır; zilden gürültülü olanı.',
    minAge: 6,
  ),
  ShopProduct(
    typeId: 'bisiklet_reflektoru',
    description: 'Bisiklete takılır. Akşamüstü görünür olmanı sağlar.',
    minAge: 6,
  ),
  ShopProduct(
    typeId: 'bisiklet_susu',
    description: 'Gidona takılan küçük süs.',
    minAge: 6,
  ),
  ShopProduct(
    typeId: 'bisiklet_bakim_seti',
    description: 'Yağ, bez ve birkaç anahtar. Bakımı ucuzlatır.',
    minAge: 8,
  ),
  ShopProduct(
    typeId: 'yoyo',
    description: 'Ucuz ve eğlenceli. Küçük bir hediye olur.',
    minAge: 5,
  ),
  ShopProduct(
    typeId: 'kol_saati',
    description: 'Basit ama sağlam bir kol saati.',
    minAge: 12,
  ),
];

/// Oyuncunun yaşına uygun ürünler.
List<ShopProduct> shopProductsFor(int age) =>
    kShopCatalog.where((ShopProduct p) => age >= p.minAge).toList(growable: false);

ShopProduct? shopProductByTypeId(String typeId) {
  for (final ShopProduct p in kShopCatalog) {
    if (p.typeId == typeId) return p;
  }
  return null;
}
