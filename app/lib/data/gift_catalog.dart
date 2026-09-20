/// Küçük başlangıç hediye kataloğu.
///
/// Amaç kapsamlı bir mağaza değil, **gerçekten çalışan** birkaç eşyadır.
/// Her hediye envanterde yer alan gerçek bir eşya kimliğine karşılık gelir;
/// ileride eşya kondisyonu ve satış sistemi bu kataloğa bağlanacak.
///
/// Fiyatlar ve yaş aralıkları `prototypeOnly`'dir; onaylanmış oyun dengesi
/// değildir (`docs/DESIGN_REVIEW_QUEUE.md`, Q-025).
library;

import 'dart:math';

import 'package:flutter/material.dart';

import '../domain/models/wealth.dart';
import 'item_catalog.dart';

/// Kataloğa kayıtlı bir hediye.
@immutable
class GiftItem {
  const GiftItem({
    required this.id,
    required this.minAge,
    required this.maxAge,
    this.minGiverWealth = WealthTier.cokYoksul,
  });

  /// Envanterde kullanılan kalıcı **eşya türü** kimliği
  /// (`item_catalog.dart`).
  final String id;

  /// Hediyeyi **alan** kişinin yaş aralığı.
  final int minAge;
  final int maxAge;

  /// Tür bilgisi: ad, simge ve temel değer tek kaynaktan gelir.
  ItemType get type => itemTypeOrFallback(id);

  /// Ekranda ve sonuç metninde geçen ad.
  String get name => type.name;
  IconData get icon => type.icon;

  /// prototypeOnly: yaklaşık değeri (₺); alım bedeli ve satış hesabının
  /// temeli aynı sayıdır.
  int get value => type.baseValue;

  /// Hediyeyi verenin en az bu ekonomik düzeyde olması beklenir.
  ///
  /// Çok yoksul bir aile gerekçesiz şekilde pahalı bir eşya hediye etmez.
  final WealthTier minGiverWealth;

  bool fitsAge(int age) => age >= minAge && age <= maxAge;

  bool affordableBy(WealthTier? wealth) =>
      wealth != null && wealth.index >= minGiverWealth.index;
}

/// Başlangıç kataloğu. Az sayıda, gerçekten çalışan örnek.
///
/// Cinsiyete göre **yasak** yoktur: oyuncak bebek de oyuncak araba da her
/// karaktere gelebilir. Tercih çeşitliliği ileride kişinin ilgi alanlarıyla
/// modellenecek (Q-025).
const List<GiftItem> kGiftCatalog = <GiftItem>[
  // --- 4-8 yaş ----------------------------------------------------------
  GiftItem(
    id: 'yoyo',
    minAge: 4,
    maxAge: 8,
  ),
  GiftItem(
    id: 'oyuncak_araba',
    minAge: 4,
    maxAge: 8,
  ),
  GiftItem(
    id: 'oyuncak_bebek',
    minAge: 4,
    maxAge: 8,
  ),
  GiftItem(
    id: 'boyama_kitabi',
    minAge: 4,
    maxAge: 8,
  ),
  GiftItem(
    id: 'bilye',
    minAge: 4,
    maxAge: 10,
  ),
  GiftItem(
    id: 'ucurtma',
    minAge: 4,
    maxAge: 10,
  ),
  GiftItem(
    id: 'pelus_oyuncak',
    minAge: 4,
    maxAge: 9,
  ),

  // --- 9-12 yaş ---------------------------------------------------------
  GiftItem(
    id: 'futbol_topu',
    minAge: 8,
    maxAge: 14,
    minGiverWealth: WealthTier.yoksul,
  ),
  GiftItem(
    id: 'bisiklet_zili',
    minAge: 8,
    maxAge: 16,
  ),
  GiftItem(
    id: 'cizim_seti',
    minAge: 8,
    maxAge: 17,
    minGiverWealth: WealthTier.yoksul,
  ),
  GiftItem(
    id: 'hikaye_kitabi',
    minAge: 7,
    maxAge: 13,
  ),
  GiftItem(
    id: 'kutu_oyunu',
    minAge: 8,
    maxAge: 15,
    minGiverWealth: WealthTier.yoksul,
  ),

  // --- 13-17 yaş --------------------------------------------------------
  GiftItem(
    id: 'kulaklik',
    minAge: 12,
    maxAge: 120,
    minGiverWealth: WealthTier.ortaHalli,
  ),
  GiftItem(
    id: 'roman',
    minAge: 13,
    maxAge: 120,
  ),
  GiftItem(
    id: 'spor_ayakkabi',
    minAge: 12,
    maxAge: 120,
    minGiverWealth: WealthTier.ortaHalli,
  ),
  GiftItem(
    id: 'kiyafet',
    minAge: 10,
    maxAge: 120,
    minGiverWealth: WealthTier.yoksul,
  ),

  // --- 18 yaş ve sonrası -------------------------------------------------
  GiftItem(
    id: 'kol_saati',
    minAge: 15,
    maxAge: 120,
    minGiverWealth: WealthTier.ortaHalli,
  ),
  GiftItem(
    id: 'radyo',
    minAge: 16,
    maxAge: 120,
    minGiverWealth: WealthTier.ortaHalli,
  ),
  GiftItem(
    id: 'cay_takimi',
    minAge: 18,
    maxAge: 120,
    minGiverWealth: WealthTier.yoksul,
  ),
  GiftItem(
    id: 'defter',
    minAge: 7,
    maxAge: 120,
  ),
];

/// Kimlikten hediye bilgisi.
GiftItem? giftById(String id) {
  for (final GiftItem item in kGiftCatalog) {
    if (item.id == id) return item;
  }
  return null;
}

/// Verilen koşullara uyan hediyeler.
///
/// - [receiverAge]: hediyeyi alan kişinin yaşı.
/// - [giverWealth]: verenin ekonomik durumu; `null` ise bedeli oyuncunun
///   cüzdanı karşılar ve [maxValue] üzerinden elenir.
/// - [excluded]: zaten sahip olunan eşyalar.
List<GiftItem> giftsFor({
  required int receiverAge,
  WealthTier? giverWealth,
  int? maxValue,
  Set<String> excluded = const <String>{},
}) {
  return kGiftCatalog.where((GiftItem item) {
    if (!item.fitsAge(receiverAge)) return false;
    if (excluded.contains(item.id)) return false;
    if (maxValue != null && item.value > maxValue) return false;
    if (giverWealth != null && !item.affordableBy(giverWealth)) return false;
    return true;
  }).toList(growable: false);
}

/// Koşullara uyan hediyelerden birini seçer; uygun hediye yoksa `null`.
GiftItem? pickGift({
  required Random rng,
  required int receiverAge,
  WealthTier? giverWealth,
  int? maxValue,
  Set<String> excluded = const <String>{},
}) {
  final List<GiftItem> uygun = giftsFor(
    receiverAge: receiverAge,
    giverWealth: giverWealth,
    maxValue: maxValue,
    excluded: excluded,
  );
  if (uygun.isEmpty) return null;
  return uygun[rng.nextInt(uygun.length)];
}
