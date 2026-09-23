/// Evcil hayvanlar (Paket 40 — Issue #67, 2. kısım).
///
/// **İkinci bir evcil hayvan sistemi kurulmaz.** `GameState.pets` zaten
/// vardı; burada yalnızca o kaydın gerçek bir kimliği, yaşı ve sonu olması
/// için gereken katalog tanımlanır.
///
/// v1'de **yalnızca kedi ve köpek sahiplenilebilir** (Faho'nun kararı).
/// Hayat başında evde bulunabilen diğer türler (kuş, kaplumbağa, balık)
/// kayıtta durmaya devam eder ve onlar da yaşlanıp vefat eder; sahiplenme
/// menüsünde görünmezler.
///
/// Sayısal değerler `prototypeOnly`'dir
/// (`docs/DESIGN_REVIEW_QUEUE.md`, Q-107).
library;

import 'package:flutter/material.dart';

/// Bir evcil hayvan türü.
enum PetSpecies {
  kedi(
    id: 'kedi',
    label: 'Kedi',
    icon: Icons.pets_rounded,
    adoptable: true,
    adoptionCost: 900,
    yearlyCareCost: 4800,
    vetCost: 1500,
    // prototypeOnly: ev kedisi ortalaması 13-17 yıl.
    typicalLifespan: 15,
    maxLifespan: 21,
  ),
  kopek(
    id: 'köpek',
    label: 'Köpek',
    icon: Icons.pets_outlined,
    adoptable: true,
    adoptionCost: 1200,
    yearlyCareCost: 7200,
    vetCost: 2200,
    // prototypeOnly: ortalama köpek ömrü 11-13 yıl.
    typicalLifespan: 12,
    maxLifespan: 18,
  ),
  muhabbetKusu(
    id: 'muhabbet kuşu',
    label: 'Muhabbet kuşu',
    icon: Icons.flutter_dash_rounded,
    adoptable: false,
    adoptionCost: 300,
    yearlyCareCost: 1200,
    vetCost: 600,
    typicalLifespan: 8,
    maxLifespan: 14,
  ),
  kaplumbaga(
    id: 'kaplumbağa',
    label: 'Kaplumbağa',
    icon: Icons.eco_rounded,
    adoptable: false,
    adoptionCost: 400,
    yearlyCareCost: 900,
    vetCost: 700,
    typicalLifespan: 30,
    maxLifespan: 55,
  ),
  balik(
    id: 'balık',
    label: 'Balık',
    icon: Icons.set_meal_rounded,
    adoptable: false,
    adoptionCost: 150,
    yearlyCareCost: 600,
    vetCost: 300,
    typicalLifespan: 5,
    maxLifespan: 10,
  );

  const PetSpecies({
    required this.id,
    required this.label,
    required this.icon,
    required this.adoptable,
    required this.adoptionCost,
    required this.yearlyCareCost,
    required this.vetCost,
    required this.typicalLifespan,
    required this.maxLifespan,
  });

  /// `Pet.species` alanında saklanan kimlik.
  ///
  /// Eski kayıtlarla uyum için `name_pool.dart` içindeki küçük harfli
  /// yazım korunur; yeni bir tür kimliği uydurulmaz.
  final String id;

  final String label;
  final IconData icon;

  /// v1'de sahiplenme menüsünde görünür mü?
  final bool adoptable;

  /// prototypeOnly: sahiplenme masrafı (aşı, nakil, ilk malzeme).
  final int adoptionCost;

  /// prototypeOnly: **yılda bir kez** alınan bakım gideri.
  final int yearlyCareCost;

  /// prototypeOnly: veteriner ziyaretinin ücreti.
  final int vetCost;

  /// prototypeOnly: olağan ömür.
  final int typicalLifespan;

  /// prototypeOnly: bu yaştan sonra hiçbir hayvan yaşamaz.
  final int maxLifespan;
}

PetSpecies? petSpeciesById(String id) {
  final String k = id.toLowerCase().trim();
  for (final PetSpecies s in PetSpecies.values) {
    if (s.id == k) return s;
  }
  return null;
}

/// Sahiplenilebilen türler (v1: kedi ve köpek).
List<PetSpecies> get adoptablePetSpecies => PetSpecies.values
    .where((PetSpecies s) => s.adoptable)
    .toList(growable: false);

/// Sahiplenilen hayvana verilebilecek adlar.
///
/// `name_pool.dart` içindeki liste hayat başında evde bulunan hayvan için
/// kullanılıyordu; sahiplenme ekranında da aynı havuz kullanılır ki oyunun
/// isim dünyası ikiye bölünmesin.
const List<String> kPetSuggestedNames = <String>[
  'Pamuk', 'Boncuk', 'Karabaş', 'Tekir', 'Duman', 'Minnoş', 'Zeytin',
  'Fındık', 'Paşa', 'Mırmır', 'Şeker', 'Kömür', 'Badem', 'Leblebi',
];

/// Tür etiketi; tanınmayan tür kayıttaki yazımıyla döner.
String petSpeciesLabel(String speciesId) =>
    petSpeciesById(speciesId)?.label ?? speciesId;
