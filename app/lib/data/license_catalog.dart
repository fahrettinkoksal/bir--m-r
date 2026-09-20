/// Ehliyetler.
///
/// Ehliyet **kalıcı** bir kayıttır ve türleri birbirinden bağımsızdır:
/// motosiklet ehliyeti otomobil kullanma hakkı vermez.
///
/// Yaş eşikleri ve sınav kuralları `prototypeOnly`'dir; gerçek dünyadaki
/// resmî sürücü belgesi sınıfları veya yaş sınırları **doğrulanmış bilgi
/// olarak sunulmaz** (`docs/DESIGN_REVIEW_QUEUE.md`, Q-056).
library;

import 'package:flutter/material.dart';

import '../domain/models/owned_item.dart';
import 'item_catalog.dart';

/// Oyundaki ehliyet türü.
enum LicenseType {
  motosiklet(
    id: 'motosiklet_ehliyeti',
    label: 'Motosiklet ehliyeti',
    icon: Icons.two_wheeler_outlined,
    prototypeOnlyMinAge: 16,
  ),
  otomobil(
    id: 'otomobil_ehliyeti',
    label: 'Otomobil ehliyeti',
    icon: Icons.directions_car_outlined,
    prototypeOnlyMinAge: 18,
  );

  const LicenseType({
    required this.id,
    required this.label,
    required this.icon,
    required this.prototypeOnlyMinAge,
  });

  /// Kayıtta tutulan kalıcı kimlik.
  final String id;
  final String label;
  final IconData icon;

  /// prototypeOnly: başvuru için gereken en küçük yaş.
  final int prototypeOnlyMinAge;
}

LicenseType? licenseTypeById(String id) {
  for (final LicenseType t in LicenseType.values) {
    if (t.id == id) return t;
  }
  return null;
}

/// Bu eşyayı **sürmek** için gereken ehliyet; gerekmiyorsa `null`.
///
/// Bisiklet ehliyet istemez.
LicenseType? licenseRequiredFor(OwnedItem item) {
  switch (item.type.kind) {
    case ItemKind.motosiklet:
      return LicenseType.motosiklet;
    case ItemKind.otomobil:
      return LicenseType.otomobil;
    default:
      return null;
  }
}
