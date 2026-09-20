import 'package:flutter/material.dart';

import 'item_catalog.dart';

/// Eşya türünün okunaklı adı.
///
/// Tek kaynak `item_catalog.dart`'tır; ad ve simge iki yerde farklı olmaz.
String possessionName(String typeId) => itemTypeOrFallback(typeId).name;

IconData possessionIcon(String typeId) => itemTypeOrFallback(typeId).icon;
