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

import '../domain/models/relation.dart';
import '../domain/models/wealth.dart';
import 'item_catalog.dart';

/// Hediyenin ne olduğu (D-134).
///
/// Beğeni bu sınıfa bakar: anneye tavla vermekle çeyrek altın vermek aynı
/// şey değildir.
enum GiftCategory {
  oyuncak('Oyuncak'),
  kirtasiye('Kırtasiye'),
  kitap('Kitap'),
  spor('Spor'),
  elektronik('Elektronik'),
  giyim('Giyim'),
  taki('Takı ve altın'),
  cicek('Çiçek ve çikolata'),
  evEsyasi('Ev eşyası'),
  masaOyunu('Masa oyunu');

  const GiftCategory(this.label);

  final String label;
}

/// Hediyenin karşı tarafta bıraktığı izlenim (D-134).
enum GiftReaction {
  /// Tam isabet: aradığı şey buydu.
  sevindi('Çok sevindi'),

  /// Fena değil ama özel bir şey de değil.
  idare('İdare etti'),

  /// Yanlış hediye. Nazik davranır ama belli olur.
  begenmedi('Pek beğenmedi');

  const GiftReaction(this.label);

  final String label;
}

/// Kataloğa kayıtlı bir hediye.
@immutable
class GiftItem {
  const GiftItem({
    required this.id,
    required this.minAge,
    required this.maxAge,
    required this.category,
    this.minGiverWealth = WealthTier.cokYoksul,
  });

  /// Hediyenin sınıfı; beğeni buna bakar (D-134).
  final GiftCategory category;

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
    category: GiftCategory.oyuncak,
    minAge: 4,
    maxAge: 8,
  ),
  GiftItem(
    id: 'oyuncak_araba',
    category: GiftCategory.oyuncak,
    minAge: 4,
    maxAge: 8,
  ),
  GiftItem(
    id: 'oyuncak_bebek',
    category: GiftCategory.oyuncak,
    minAge: 4,
    maxAge: 8,
  ),
  GiftItem(
    id: 'boyama_kitabi',
    category: GiftCategory.kirtasiye,
    minAge: 4,
    maxAge: 8,
  ),
  GiftItem(
    id: 'bilye',
    category: GiftCategory.oyuncak,
    minAge: 4,
    maxAge: 10,
  ),
  GiftItem(
    id: 'ucurtma',
    category: GiftCategory.oyuncak,
    minAge: 4,
    maxAge: 10,
  ),
  GiftItem(
    id: 'pelus_oyuncak',
    category: GiftCategory.oyuncak,
    minAge: 4,
    maxAge: 9,
  ),

  // --- 9-12 yaş ---------------------------------------------------------
  GiftItem(
    id: 'futbol_topu',
    category: GiftCategory.spor,
    minAge: 8,
    maxAge: 14,
    minGiverWealth: WealthTier.yoksul,
  ),
  GiftItem(
    id: 'bisiklet_zili',
    category: GiftCategory.spor,
    minAge: 8,
    maxAge: 16,
  ),
  GiftItem(
    id: 'cizim_seti',
    category: GiftCategory.kirtasiye,
    minAge: 8,
    maxAge: 17,
    minGiverWealth: WealthTier.yoksul,
  ),
  GiftItem(
    id: 'hikaye_kitabi',
    category: GiftCategory.kitap,
    minAge: 7,
    maxAge: 13,
  ),
  GiftItem(
    id: 'kutu_oyunu',
    category: GiftCategory.masaOyunu,
    minAge: 8,
    maxAge: 15,
    minGiverWealth: WealthTier.yoksul,
  ),

  // --- 13-17 yaş --------------------------------------------------------
  GiftItem(
    id: 'kulaklik',
    category: GiftCategory.elektronik,
    minAge: 12,
    maxAge: 120,
    minGiverWealth: WealthTier.ortaHalli,
  ),
  GiftItem(
    id: 'roman',
    category: GiftCategory.kitap,
    minAge: 13,
    maxAge: 120,
  ),
  GiftItem(
    id: 'spor_ayakkabi',
    category: GiftCategory.giyim,
    minAge: 12,
    maxAge: 120,
    minGiverWealth: WealthTier.ortaHalli,
  ),
  GiftItem(
    id: 'kiyafet',
    category: GiftCategory.giyim,
    minAge: 10,
    maxAge: 120,
    minGiverWealth: WealthTier.yoksul,
  ),

  // --- 18 yaş ve sonrası -------------------------------------------------
  GiftItem(
    id: 'kol_saati',
    category: GiftCategory.taki,
    minAge: 15,
    maxAge: 120,
    minGiverWealth: WealthTier.ortaHalli,
  ),
  GiftItem(
    id: 'radyo',
    category: GiftCategory.elektronik,
    minAge: 16,
    maxAge: 120,
    minGiverWealth: WealthTier.ortaHalli,
  ),
  GiftItem(
    id: 'cay_takimi',
    category: GiftCategory.evEsyasi,
    minAge: 18,
    maxAge: 120,
    minGiverWealth: WealthTier.yoksul,
  ),
  GiftItem(
    id: 'defter',
    category: GiftCategory.kirtasiye,
    minAge: 7,
    maxAge: 120,
  ),

  // --- Faho'nun istediği hediyeler (D-134) -------------------------------
  GiftItem(
    id: 'cicek_buketi',
    category: GiftCategory.cicek,
    minAge: 14,
    maxAge: 120,
  ),
  GiftItem(
    id: 'kutu_cikolata',
    category: GiftCategory.cicek,
    minAge: 6,
    maxAge: 120,
  ),
  GiftItem(
    id: 'ceyrek_altin',
    category: GiftCategory.taki,
    minAge: 0,
    maxAge: 120,
    minGiverWealth: WealthTier.ortaHalli,
  ),
  GiftItem(
    id: 'gram_altin',
    category: GiftCategory.taki,
    minAge: 0,
    maxAge: 120,
    minGiverWealth: WealthTier.yoksul,
  ),
  GiftItem(
    id: 'bilezik',
    category: GiftCategory.taki,
    minAge: 15,
    maxAge: 120,
    minGiverWealth: WealthTier.varlikli,
  ),
  GiftItem(
    id: 'kolye',
    category: GiftCategory.taki,
    minAge: 12,
    maxAge: 120,
    minGiverWealth: WealthTier.ortaHalli,
  ),
  GiftItem(
    id: 'kupe',
    category: GiftCategory.taki,
    minAge: 12,
    maxAge: 120,
    minGiverWealth: WealthTier.ortaHalli,
  ),
  GiftItem(
    id: 'parfum',
    category: GiftCategory.cicek,
    minAge: 15,
    maxAge: 120,
    minGiverWealth: WealthTier.yoksul,
  ),
  GiftItem(
    id: 'tavla',
    category: GiftCategory.masaOyunu,
    minAge: 12,
    maxAge: 120,
  ),
  GiftItem(
    id: 'satranc',
    category: GiftCategory.masaOyunu,
    minAge: 8,
    maxAge: 120,
  ),
  GiftItem(
    id: 'kasmir_atki',
    category: GiftCategory.giyim,
    minAge: 18,
    maxAge: 120,
    minGiverWealth: WealthTier.yoksul,
  ),
  GiftItem(
    id: 'seccade',
    category: GiftCategory.evEsyasi,
    minAge: 30,
    maxAge: 120,
  ),
  GiftItem(
    id: 'kahve_makinesi',
    category: GiftCategory.elektronik,
    minAge: 20,
    maxAge: 120,
    minGiverWealth: WealthTier.ortaHalli,
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

// =====================================================================
// Hediye beğenisi (D-134)
//
// Faho'nun isteği: "tavla hediye edersem beğenmesin bu şekilde kısaca
// sistem". Beğeni **kişinin kim olduğuna** bakar: anneye takı ve çiçek
// gider, tavla gitmez; dede tavlayı sever, parfümü umursamaz.
//
// Kural basit ve okunur tutuldu: her bağ için **sevdiği** ve
// **sevmediği** sınıflar. Listede olmayan sınıf "idare eder".
// =====================================================================

/// Bir bağın hediye zevki.
@immutable
class GiftTaste {
  const GiftTaste({this.loves = const <GiftCategory>{}, this.dislikes = const <GiftCategory>{}});

  final Set<GiftCategory> loves;
  final Set<GiftCategory> dislikes;
}

/// Bağ türüne göre hediye zevki.
///
/// Listede olmayan bağlar için yaşa bakılır (`giftReactionFor`).
const Map<RelationType, GiftTaste> kGiftTastes = <RelationType, GiftTaste>{
  RelationType.anne: GiftTaste(
    loves: <GiftCategory>{
      GiftCategory.taki,
      GiftCategory.cicek,
      GiftCategory.evEsyasi,
    },
    dislikes: <GiftCategory>{
      GiftCategory.masaOyunu,
      GiftCategory.oyuncak,
      GiftCategory.spor,
    },
  ),
  RelationType.baba: GiftTaste(
    loves: <GiftCategory>{
      GiftCategory.masaOyunu,
      GiftCategory.elektronik,
      GiftCategory.giyim,
    },
    dislikes: <GiftCategory>{GiftCategory.oyuncak, GiftCategory.cicek},
  ),
  RelationType.es: GiftTaste(
    loves: <GiftCategory>{
      GiftCategory.taki,
      GiftCategory.cicek,
      GiftCategory.giyim,
    },
    dislikes: <GiftCategory>{GiftCategory.kirtasiye, GiftCategory.oyuncak},
  ),
  RelationType.sevgili: GiftTaste(
    loves: <GiftCategory>{
      GiftCategory.taki,
      GiftCategory.cicek,
      GiftCategory.giyim,
    },
    dislikes: <GiftCategory>{GiftCategory.evEsyasi, GiftCategory.kirtasiye},
  ),
  RelationType.flort: GiftTaste(
    loves: <GiftCategory>{GiftCategory.cicek, GiftCategory.giyim},
    dislikes: <GiftCategory>{GiftCategory.evEsyasi, GiftCategory.taki},
  ),
  RelationType.arkadas: GiftTaste(
    loves: <GiftCategory>{
      GiftCategory.masaOyunu,
      GiftCategory.elektronik,
      GiftCategory.spor,
    },
    dislikes: <GiftCategory>{GiftCategory.taki, GiftCategory.evEsyasi},
  ),
  RelationType.kardes: GiftTaste(
    loves: <GiftCategory>{
      GiftCategory.elektronik,
      GiftCategory.spor,
      GiftCategory.masaOyunu,
    },
    dislikes: <GiftCategory>{GiftCategory.evEsyasi},
  ),
  RelationType.anneTarafiDede: GiftTaste(
    loves: <GiftCategory>{
      GiftCategory.masaOyunu,
      GiftCategory.giyim,
      GiftCategory.evEsyasi,
    },
    dislikes: <GiftCategory>{GiftCategory.elektronik, GiftCategory.oyuncak},
  ),
  RelationType.babaTarafiDede: GiftTaste(
    loves: <GiftCategory>{
      GiftCategory.masaOyunu,
      GiftCategory.giyim,
      GiftCategory.evEsyasi,
    },
    dislikes: <GiftCategory>{GiftCategory.elektronik, GiftCategory.oyuncak},
  ),
  RelationType.anneanne: GiftTaste(
    loves: <GiftCategory>{
      GiftCategory.evEsyasi,
      GiftCategory.giyim,
      GiftCategory.cicek,
    },
    dislikes: <GiftCategory>{GiftCategory.elektronik, GiftCategory.spor},
  ),
  RelationType.babaanne: GiftTaste(
    loves: <GiftCategory>{
      GiftCategory.evEsyasi,
      GiftCategory.giyim,
      GiftCategory.cicek,
    },
    dislikes: <GiftCategory>{GiftCategory.elektronik, GiftCategory.spor},
  ),
  RelationType.isArkadasi: GiftTaste(
    loves: <GiftCategory>{GiftCategory.cicek, GiftCategory.elektronik},
    dislikes: <GiftCategory>{GiftCategory.taki, GiftCategory.oyuncak},
  ),
  RelationType.ogretmen: GiftTaste(
    loves: <GiftCategory>{GiftCategory.cicek, GiftCategory.kitap},
    dislikes: <GiftCategory>{GiftCategory.taki, GiftCategory.oyuncak},
  ),
};

/// Bu hediye bu kişiye nasıl gider?
///
/// Önce **yaş** bakılır: on yaşındaki çocuk altın bilezikten değil
/// oyuncaktan sevinir. Sonra bağın zevki okunur. Zevk listesinde
/// olmayan hediye "idare eder".
GiftReaction giftReactionFor({
  required GiftItem gift,
  required RelationType relation,
  required int receiverAge,
}) {
  // Çocuk (0-12): oyuncak ve kırtasiye sevinç, takı anlamsız.
  if (receiverAge <= 12) {
    if (gift.category == GiftCategory.oyuncak ||
        gift.category == GiftCategory.cicek) {
      return GiftReaction.sevindi;
    }
    if (gift.category == GiftCategory.taki ||
        gift.category == GiftCategory.evEsyasi) {
      return GiftReaction.begenmedi;
    }
    return GiftReaction.idare;
  }
  // Ergen (13-17): elektronik ve giyim sevinç, ev eşyası değil.
  if (receiverAge <= 17) {
    if (gift.category == GiftCategory.elektronik ||
        gift.category == GiftCategory.giyim) {
      return GiftReaction.sevindi;
    }
    if (gift.category == GiftCategory.evEsyasi ||
        gift.category == GiftCategory.oyuncak) {
      return GiftReaction.begenmedi;
    }
    return GiftReaction.idare;
  }

  final GiftTaste? zevk = kGiftTastes[relation];
  if (zevk == null) return GiftReaction.idare;
  if (zevk.loves.contains(gift.category)) return GiftReaction.sevindi;
  if (zevk.dislikes.contains(gift.category)) return GiftReaction.begenmedi;
  return GiftReaction.idare;
}
