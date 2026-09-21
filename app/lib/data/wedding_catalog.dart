/// Evlenme teklifi ve düğün seçenekleri (Paket 25).
///
/// **Faho'nun kararı:** Evlenme teklifi **ücretsizdir**. Para, teklif
/// kabul edildikten sonra **düğünde** devreye girer ve orada da her
/// cüzdana uyan bir seçenek vardır. Böylece "60.000 ₺'n yoksa hiç
/// evlenemezsin" duvarı kalkar: parası olmayan da aile arasında nikâh
/// kıyar, parası olan salon tutar.
///
/// Tutarlar, kabul katkıları ve etkiler `prototypeOnly`'dir (Q-093).
library;

import 'package:flutter/material.dart';

/// Teklifin nasıl yapıldığı.
///
/// Hiçbiri zorunlu değildir; **her zaman ücretsiz bir seçenek vardır**.
/// Para harcamak yanıtı satın almaz, yalnızca ihtimali biraz artırır.
@immutable
class ProposalStyle {
  const ProposalStyle({
    required this.id,
    required this.label,
    required this.description,
    required this.prototypeOnlyCost,
    required this.prototypeOnlyAcceptBonus,
    required this.prototypeOnlyHappiness,
    required this.prototypeOnlyBond,
    required this.icon,
  });

  final String id;
  final String label;
  final String description;

  /// Hazırlık masrafı (₺). Sıfırsa bedelsizdir.
  final int prototypeOnlyCost;

  /// Kabul ihtimaline eklenen pay (0-1 arası).
  final double prototypeOnlyAcceptBonus;

  /// Kabul edilirse oyuncunun mutluluğuna eklenen.
  final int prototypeOnlyHappiness;

  /// Kabul edilirse yakınlığa eklenen.
  final int prototypeOnlyBond;

  final IconData icon;

  bool get isFree => prototypeOnlyCost == 0;
}

const List<ProposalStyle> kProposalStyles = <ProposalStyle>[
  ProposalStyle(
    id: 'sade',
    label: 'Sade bir an',
    description: 'Ne salon ne kalabalık. Bir akşam, iki kişi ve soru.',
    prototypeOnlyCost: 0,
    prototypeOnlyAcceptBonus: 0,
    prototypeOnlyHappiness: 4,
    prototypeOnlyBond: 3,
    icon: Icons.favorite_outline,
  ),
  ProposalStyle(
    id: 'yemek',
    label: 'Romantik bir yemek',
    description: 'Masa ayırtılır, mum yakılır, yüzük tatlıdan sonra '
        'gelir.',
    prototypeOnlyCost: 3500,
    prototypeOnlyAcceptBonus: 0.08,
    prototypeOnlyHappiness: 7,
    prototypeOnlyBond: 6,
    icon: Icons.restaurant_rounded,
  ),
  ProposalStyle(
    id: 'arkadas',
    label: 'Arkadaşlarınla küçük bir sürpriz',
    description: 'Herkes önceden haberdar, tek habersiz olan o.',
    prototypeOnlyCost: 7000,
    prototypeOnlyAcceptBonus: 0.12,
    prototypeOnlyHappiness: 9,
    prototypeOnlyBond: 8,
    icon: Icons.groups_rounded,
  ),
  ProposalStyle(
    id: 'tatil',
    label: 'Tatile götür, orada sor',
    description: 'Deniz, otel, iki gün sonra da o soru.',
    prototypeOnlyCost: 22000,
    prototypeOnlyAcceptBonus: 0.18,
    prototypeOnlyHappiness: 12,
    prototypeOnlyBond: 10,
    icon: Icons.beach_access_rounded,
  ),
];

ProposalStyle? proposalStyleById(String id) {
  for (final ProposalStyle s in kProposalStyles) {
    if (s.id == id) return s;
  }
  return null;
}

/// Teklif kabul edildikten sonra yapılan düğün.
///
/// **En ucuz seçenek bedelsizdir**: parası olmayan da evlenebilir.
@immutable
class WeddingStyle {
  const WeddingStyle({
    required this.id,
    required this.label,
    required this.description,
    required this.prototypeOnlyCost,
    required this.prototypeOnlyHappiness,
    required this.prototypeOnlyBond,
    required this.prototypeOnlyCharisma,
    required this.prototypeOnlyFame,
    required this.icon,
    required this.logText,
  });

  final String id;
  final String label;
  final String description;

  /// Düğün masrafı (₺). Sıfırsa bedelsizdir.
  final int prototypeOnlyCost;

  final int prototypeOnlyHappiness;
  final int prototypeOnlyBond;
  final int prototypeOnlyCharisma;

  /// Ün açıksa eklenen pay; Ün kapalıysa **açılmaz** (D-027).
  final int prototypeOnlyFame;

  final IconData icon;

  /// Hayat günlüğüne yazılacak cümlenin gövdesi ("{es} ile " ile başlar).
  final String logText;

  bool get isFree => prototypeOnlyCost == 0;
}

const List<WeddingStyle> kWeddingStyles = <WeddingStyle>[
  WeddingStyle(
    id: 'nikah',
    label: 'Sadece nikâh',
    description: 'Belediyede imza, çıkışta simit. Masrafı yok.',
    prototypeOnlyCost: 0,
    prototypeOnlyHappiness: 6,
    prototypeOnlyBond: 6,
    prototypeOnlyCharisma: 0,
    prototypeOnlyFame: 0,
    icon: Icons.edit_document,
    logText: 'belediyede nikâh kıydınız; masrafsız ama gerçek.',
  ),
  WeddingStyle(
    id: 'aile',
    label: 'Aile arasında',
    description: 'Evde yemek, iki masa, herkes tanıdık.',
    prototypeOnlyCost: 18000,
    prototypeOnlyHappiness: 10,
    prototypeOnlyBond: 9,
    prototypeOnlyCharisma: 1,
    prototypeOnlyFame: 0,
    icon: Icons.home_rounded,
    logText: 'aile arasında evlendiniz; kalabalık değildi ama sıcaktı.',
  ),
  WeddingStyle(
    id: 'arkadas_partisi',
    label: 'Arkadaşlarınla parti',
    description: 'Müzik, kalabalık, sabaha kadar. Salon yok, keyif çok.',
    prototypeOnlyCost: 45000,
    prototypeOnlyHappiness: 14,
    prototypeOnlyBond: 10,
    prototypeOnlyCharisma: 3,
    prototypeOnlyFame: 1,
    icon: Icons.celebration_rounded,
    logText: 'arkadaşlarınızla sabaha kadar süren bir düğün yaptınız.',
  ),
  WeddingStyle(
    id: 'salon',
    label: 'Düğün salonu',
    description: 'Salon, orkestra, davetiye. Herkes orada.',
    prototypeOnlyCost: 90000,
    prototypeOnlyHappiness: 16,
    prototypeOnlyBond: 12,
    prototypeOnlyCharisma: 4,
    prototypeOnlyFame: 2,
    icon: Icons.nightlife_rounded,
    logText: 'düğün salonunda kalabalık bir düğün yaptınız.',
  ),
];

WeddingStyle? weddingStyleById(String id) {
  for (final WeddingStyle s in kWeddingStyles) {
    if (s.id == id) return s;
  }
  return null;
}

/// Bedelsiz düğün: cüzdanı boş oyuncu da evlenebilmeli.
///
/// Katalogda **her zaman** bedelsiz bir seçenek bulunmalı; yoksa oyuncu
/// "evet" almış ama evlenemeyen bir durumda kalır. Kalıcı bir test bunu
/// korur.
WeddingStyle get kFreeWedding =>
    kWeddingStyles.firstWhere((WeddingStyle s) => s.isFree);
