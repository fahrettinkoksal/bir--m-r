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

/// Kataloğa kayıtlı bir hediye.
@immutable
class GiftItem {
  const GiftItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.minAge,
    required this.maxAge,
    required this.value,
    this.minGiverWealth = WealthTier.cokYoksul,
  });

  /// Envanterde kullanılan kalıcı eşya kimliği.
  final String id;

  /// Ekranda ve sonuç metninde geçen ad.
  final String name;
  final IconData icon;

  /// Hediyeyi **alan** kişinin yaş aralığı.
  final int minAge;
  final int maxAge;

  /// prototypeOnly: yaklaşık değeri (₺). Hem alım bedeli hem ileride satış
  /// hesabının temeli olacak.
  final int value;

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
    name: 'Yo-yo',
    icon: Icons.sports_baseball_outlined,
    minAge: 4,
    maxAge: 8,
    value: 25,
  ),
  GiftItem(
    id: 'oyuncak_araba',
    name: 'Oyuncak araba',
    icon: Icons.toys_outlined,
    minAge: 4,
    maxAge: 8,
    value: 60,
  ),
  GiftItem(
    id: 'oyuncak_bebek',
    name: 'Oyuncak bebek',
    icon: Icons.child_friendly_outlined,
    minAge: 4,
    maxAge: 8,
    value: 60,
  ),
  GiftItem(
    id: 'boyama_kitabi',
    name: 'Boyama kitabı',
    icon: Icons.palette_outlined,
    minAge: 4,
    maxAge: 8,
    value: 20,
  ),
  GiftItem(
    id: 'bilye',
    name: 'Bilye torbası',
    icon: Icons.circle_outlined,
    minAge: 4,
    maxAge: 10,
    value: 15,
  ),
  GiftItem(
    id: 'ucurtma',
    name: 'Uçurtma',
    icon: Icons.air_outlined,
    minAge: 4,
    maxAge: 10,
    value: 30,
  ),
  GiftItem(
    id: 'pelus_oyuncak',
    name: 'Pelüş oyuncak',
    icon: Icons.pets_outlined,
    minAge: 4,
    maxAge: 9,
    value: 70,
  ),

  // --- 9-12 yaş ---------------------------------------------------------
  GiftItem(
    id: 'futbol_topu',
    name: 'Futbol topu',
    icon: Icons.sports_soccer_outlined,
    minAge: 8,
    maxAge: 14,
    value: 150,
    minGiverWealth: WealthTier.yoksul,
  ),
  GiftItem(
    id: 'bisiklet_zili',
    name: 'Bisiklet zili',
    icon: Icons.notifications_active_outlined,
    minAge: 8,
    maxAge: 16,
    value: 40,
  ),
  GiftItem(
    id: 'cizim_seti',
    name: 'Çizim seti',
    icon: Icons.draw_outlined,
    minAge: 8,
    maxAge: 17,
    value: 120,
    minGiverWealth: WealthTier.yoksul,
  ),
  GiftItem(
    id: 'hikaye_kitabi',
    name: 'Hikâye kitabı',
    icon: Icons.menu_book_outlined,
    minAge: 7,
    maxAge: 13,
    value: 50,
  ),
  GiftItem(
    id: 'kutu_oyunu',
    name: 'Kutu oyunu',
    icon: Icons.casino_outlined,
    minAge: 8,
    maxAge: 15,
    value: 180,
    minGiverWealth: WealthTier.yoksul,
  ),

  // --- 13-17 yaş --------------------------------------------------------
  GiftItem(
    id: 'kulaklik',
    name: 'Kulaklık',
    icon: Icons.headphones_outlined,
    minAge: 12,
    maxAge: 120,
    value: 400,
    minGiverWealth: WealthTier.ortaHalli,
  ),
  GiftItem(
    id: 'roman',
    name: 'Roman',
    icon: Icons.auto_stories_outlined,
    minAge: 13,
    maxAge: 120,
    value: 90,
  ),
  GiftItem(
    id: 'spor_ayakkabi',
    name: 'Spor ayakkabı',
    icon: Icons.directions_run_outlined,
    minAge: 12,
    maxAge: 120,
    value: 600,
    minGiverWealth: WealthTier.ortaHalli,
  ),
  GiftItem(
    id: 'kiyafet',
    name: 'Yeni kıyafet',
    icon: Icons.checkroom_outlined,
    minAge: 10,
    maxAge: 120,
    value: 350,
    minGiverWealth: WealthTier.yoksul,
  ),

  // --- 18 yaş ve sonrası -------------------------------------------------
  GiftItem(
    id: 'kol_saati',
    name: 'Kol saati',
    icon: Icons.watch_outlined,
    minAge: 15,
    maxAge: 120,
    value: 900,
    minGiverWealth: WealthTier.ortaHalli,
  ),
  GiftItem(
    id: 'radyo',
    name: 'Küçük radyo',
    icon: Icons.radio_outlined,
    minAge: 16,
    maxAge: 120,
    value: 500,
    minGiverWealth: WealthTier.ortaHalli,
  ),
  GiftItem(
    id: 'cay_takimi',
    name: 'Çay takımı',
    icon: Icons.emoji_food_beverage_outlined,
    minAge: 18,
    maxAge: 120,
    value: 300,
    minGiverWealth: WealthTier.yoksul,
  ),
  GiftItem(
    id: 'defter',
    name: 'Hatıra defteri',
    icon: Icons.book_outlined,
    minAge: 7,
    maxAge: 120,
    value: 45,
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
