import 'package:flutter/material.dart';

import 'gift_catalog.dart';

/// Sahip olunan eşyaların okunaklı adları ve simgeleri.
///
/// Hediye kataloğundaki eşyalar adlarını oradan alır; burada yalnızca
/// katalog dışından edinilen eşyalar tanımlanır. Böylece aynı eşya iki yerde
/// farklı adla görünmez.
const Map<String, ({String ad, IconData ikon})> kPossessionNames =
    <String, ({String ad, IconData ikon})>{
  'bisiklet': (ad: 'Bisiklet', ikon: Icons.pedal_bike_outlined),
};

String possessionName(String id) =>
    kPossessionNames[id]?.ad ?? giftById(id)?.name ?? id;

IconData possessionIcon(String id) =>
    kPossessionNames[id]?.ikon ??
    giftById(id)?.icon ??
    Icons.inventory_2_outlined;
