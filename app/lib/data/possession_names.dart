import 'package:flutter/material.dart';

/// Sahip olunan eşyaların okunaklı adları ve simgeleri.
///
/// Kapsamlı bir eşya kataloğu değildir; yalnızca oyunda gerçekten
/// edinilebilen birkaç eşyayı adlandırır.
const Map<String, ({String ad, IconData ikon})> kPossessionNames =
    <String, ({String ad, IconData ikon})>{
  'bisiklet': (ad: 'Bisiklet', ikon: Icons.pedal_bike_outlined),
  'defter': (ad: 'Hatıra defteri', ikon: Icons.menu_book_outlined),
  'bilye': (ad: 'Bilye torbası', ikon: Icons.circle_outlined),
  'kol_saati': (ad: 'Kol saati', ikon: Icons.watch_outlined),
};

String possessionName(String id) => kPossessionNames[id]?.ad ?? id;

IconData possessionIcon(String id) =>
    kPossessionNames[id]?.ikon ?? Icons.inventory_2_outlined;
