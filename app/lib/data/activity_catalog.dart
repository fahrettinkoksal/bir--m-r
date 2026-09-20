/// Aktivite katalogları: berber, spor salonu ve kütüphane.
///
/// Ücretler, etkiler ve tekrar sınırları `prototypeOnly`'dir
/// (`docs/DESIGN_REVIEW_QUEUE.md`, Q-049).
library;

import 'package:flutter/material.dart';

/// Aktivitenin hangi alanda olduğu.
enum ActivityVenue {
  berber('Berber / Kuaför'),
  sporSalonu('Spor salonu'),
  kutuphane('Kütüphane');

  const ActivityVenue(this.label);

  final String label;
}

/// Tek bir aktivite eylemi.
@immutable
class ActivityAction {
  const ActivityAction({
    required this.id,
    required this.venue,
    required this.label,
    required this.description,
    required this.icon,
    this.cost = 0,
    this.minAge = 0,
    this.appearance = 0,
    this.charisma = 0,
    this.happiness = 0,
    this.health = 0,
    this.maxPerAge = 2,
    this.changesHairStyle = false,
  });

  final String id;
  final ActivityVenue venue;
  final String label;
  final String description;
  final IconData icon;

  /// prototypeOnly: cüzdandan düşen ücret (₺).
  final int cost;

  /// prototypeOnly: en küçük yaş.
  final int minAge;

  /// prototypeOnly: tam etkiyle uygulandığında kazanılan değerler.
  final int appearance;
  final int charisma;
  final int happiness;
  final int health;

  /// prototypeOnly: aynı yaşta kaç kez anlamlı sonuç verir.
  ///
  /// Sınıra ulaşıldığında eylem kapanır; sınırsız stat kasma olmaz.
  final int maxPerAge;

  /// Saç stilini değiştiren eylem mi?
  final bool changesHairStyle;
}

const List<ActivityAction> kActivityActions = <ActivityAction>[
  // --- Berber -----------------------------------------------------------
  ActivityAction(
    id: 'sac_kestir',
    venue: ActivityVenue.berber,
    label: 'Saç kestir',
    description: 'Klasik tıraş. Ense temiz, ayna iki taraflı.',
    icon: Icons.content_cut_outlined,
    cost: 120, // prototypeOnly
    minAge: 4,
    appearance: 3,
    happiness: 1,
    maxPerAge: 2,
  ),
  ActivityAction(
    id: 'sac_stili',
    venue: ActivityVenue.berber,
    label: 'Saç stilini değiştir',
    description: 'Yeni bir model dene. Bazen iyi gider, bazen saç uzamasını '
        'beklersin.',
    icon: Icons.auto_fix_high_outlined,
    cost: 260, // prototypeOnly
    minAge: 10,
    appearance: 4,
    charisma: 2,
    maxPerAge: 1,
    changesHairStyle: true,
  ),
  ActivityAction(
    id: 'sakal_bakim',
    venue: ActivityVenue.berber,
    label: 'Bakım yaptır',
    description: 'Yıkama, düzeltme ve biraz kolonya.',
    icon: Icons.spa_outlined,
    cost: 90, // prototypeOnly
    minAge: 12,
    appearance: 2,
    happiness: 2,
    maxPerAge: 2,
  ),

  // --- Spor salonu -------------------------------------------------------
  ActivityAction(
    id: 'kosu',
    venue: ActivityVenue.sporSalonu,
    label: 'Koşu yap',
    description: 'Bandın üstünde kırk dakika; ilk on dakika en zoru.',
    icon: Icons.directions_run_outlined,
    cost: 60, // prototypeOnly
    minAge: 12,
    health: 4,
    happiness: 1,
    maxPerAge: 3,
  ),
  ActivityAction(
    id: 'agirlik',
    venue: ActivityVenue.sporSalonu,
    label: 'Ağırlık kaldır',
    description: 'Ağırlıklar, sayılan tekrarlar ve ertesi gün ağrıyan her yer.',
    icon: Icons.fitness_center_outlined,
    cost: 60, // prototypeOnly
    minAge: 14,
    health: 3,
    appearance: 3,
    maxPerAge: 3,
  ),
  ActivityAction(
    id: 'esneme',
    venue: ActivityVenue.sporSalonu,
    label: 'Esneme ve temel egzersiz',
    description: 'Sakin bir ısınma; kalp atışı yerine nefes sayılır.',
    icon: Icons.self_improvement_outlined,
    cost: 0,
    minAge: 8,
    health: 2,
    happiness: 2,
    maxPerAge: 3,
  ),
];

List<ActivityAction> actionsAt(ActivityVenue venue) => kActivityActions
    .where((ActivityAction a) => a.venue == venue)
    .toList(growable: false);

ActivityAction? activityActionById(String id) {
  for (final ActivityAction a in kActivityActions) {
    if (a.id == id) return a;
  }
  return null;
}

/// prototypeOnly: saç stilleri. Görsel bir karakter sistemi henüz yok;
/// seçilen stil metin olarak saklanır.
const List<String> kHairStyles = <String>[
  'Kısa ve sade',
  'Yana ayrılmış',
  'Dağınık',
  'Kısacık',
  'Uzun ve toplu',
  'Kıvırcık bırakılmış',
];

// =======================================================================
// Kitaplar
// =======================================================================

/// Kitabın türü.
enum BookKind {
  cocuk('Çocuk kitabı'),
  macera('Macera'),
  roman('Roman'),
  bilim('Bilim'),
  klasik('Klasik');

  const BookKind(this.label);

  final String label;
}

/// Kütüphanedeki bir kitap.
///
/// Metinler özgündür; telifli eserlerin içeriği kullanılmaz. Sayfalar
/// ekranda soyut satır çizgileriyle gösterilir.
@immutable
class BookInfo {
  const BookInfo({
    required this.id,
    required this.title,
    required this.author,
    required this.kind,
    required this.pages,
    required this.minAge,
    required this.maxAge,
    required this.intelligenceGain,
    this.happinessGain = 0,
    this.charismaGain = 0,
  });

  final String id;
  final String title;

  /// Özgün, oyuna ait yazar adı.
  final String author;
  final BookKind kind;

  /// Kaç sayfa çevrilince biter (prototypeOnly).
  final int pages;

  final int minAge;
  final int maxAge;

  /// prototypeOnly: kitap **bitirildiğinde** bir kez uygulanan kazanç.
  final int intelligenceGain;
  final int happinessGain;
  final int charismaGain;

  bool fitsAge(int age) => age >= minAge && age <= maxAge;
}

const List<BookInfo> kBookCatalog = <BookInfo>[
  // --- İlkokul çağı: kısa ve kolay --------------------------------------
  BookInfo(
    id: 'kirmizi_bisiklet',
    title: 'Kırmızı Bisikletin Peşinde',
    author: 'Nihal Aydın',
    kind: BookKind.cocuk,
    pages: 6,
    minAge: 6,
    maxAge: 11,
    intelligenceGain: 2,
    happinessGain: 2,
  ),
  BookInfo(
    id: 'mahalle_kedisi',
    title: 'Mahallenin Kedisi',
    author: 'Sabri Gülen',
    kind: BookKind.cocuk,
    pages: 5,
    minAge: 6,
    maxAge: 10,
    intelligenceGain: 2,
    happinessGain: 2,
  ),
  BookInfo(
    id: 'kayip_anahtar',
    title: 'Kayıp Anahtar',
    author: 'Deniz Akman',
    kind: BookKind.macera,
    pages: 8,
    minAge: 9,
    maxAge: 14,
    intelligenceGain: 3,
    happinessGain: 1,
  ),

  // --- Ortaokul / lise ---------------------------------------------------
  BookInfo(
    id: 'ucuncu_kat',
    title: 'Üçüncü Kattaki Sessizlik',
    author: 'Melis Ergün',
    kind: BookKind.roman,
    pages: 14,
    minAge: 13,
    maxAge: 120,
    intelligenceGain: 4,
    charismaGain: 1,
  ),
  BookInfo(
    id: 'gokyuzu_defteri',
    title: 'Gökyüzü Defteri',
    author: 'Orhan Taşkın',
    kind: BookKind.bilim,
    pages: 16,
    minAge: 13,
    maxAge: 120,
    intelligenceGain: 5,
  ),

  // --- Lise sonu / üniversite --------------------------------------------
  BookInfo(
    id: 'uzun_kis',
    title: 'Uzun Kış',
    author: 'Bedri Yalçın',
    kind: BookKind.klasik,
    pages: 22,
    minAge: 16,
    maxAge: 120,
    intelligenceGain: 6,
    charismaGain: 1,
  ),
  BookInfo(
    id: 'sayilarin_dili',
    title: 'Sayıların Dili',
    author: 'Ayla Serin',
    kind: BookKind.bilim,
    pages: 24,
    minAge: 16,
    maxAge: 120,
    intelligenceGain: 7,
  ),
];

BookInfo? bookById(String id) {
  for (final BookInfo b in kBookCatalog) {
    if (b.id == id) return b;
  }
  return null;
}

/// Yaşa uygun kitaplar.
List<BookInfo> booksFor(int age) =>
    kBookCatalog.where((BookInfo b) => b.fitsAge(age)).toList(growable: false);
