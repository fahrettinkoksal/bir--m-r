/// Evcil hayvanlar (Paket 40 — Issue #67, 2. kısım).
///
/// **İkinci bir evcil hayvan sistemi kurulmaz.** `GameState.pets` zaten
/// vardı; burada yalnızca o kaydın gerçek bir kimliği, yaşı ve sonu olması
/// için gereken katalog tanımlanır.
///
/// **Tür listesi genişletildi (D-082).** Faho istedi: "evcil hayvan
/// kısmına köpek ve kediden başka hayvanlar da eklenmeli: muhabbet kuşu,
/// papağan, timsah, kanarya vb". Bu, D-058'in "ilk kapsamda yalnızca
/// kedi ve köpek" hükmünü değiştirir.
///
/// Ömür ve bakım değerleri türün gerçek özelliklerine dayanır: papağan
/// on yıllarca yaşar, hamsterın ömrü birkaç yıldır. **Timsah gerçek
/// hayatta sıradan bir evcil hayvan değildir**; özel izin gerektirir ve
/// çoğu yerde bireysel olarak beslenmesi yasaktır. Oyunda bu, yüksek
/// maliyet, yüksek kaçma riski ve açık bir uyarı metniyle anlatılır;
/// oyun bunu normal bir tercih gibi sunmaz (Q-121).
///
/// Sayısal değerler `prototypeOnly`'dir
/// (`docs/DESIGN_REVIEW_QUEUE.md`, Q-107).
library;

import 'package:flutter/material.dart';

/// Bir evcil hayvan türü.
/// Sahiplenme menüsündeki hayvan grubu (D-135).
enum PetGroup {
  kedi('Kediler', 'Bağımsız, sessiz, kendi kuralları var'),
  kopek('Köpekler', 'Bakım ister, karşılığını da verir'),
  kus('Kuşlar', 'Ses, tüy ve açık pencereye dikkat'),
  kemirgen('Kemirgenler ve tavşan', 'Küçük kafes, kısa ömür'),
  suVeSurungen('Su ve sürüngen', 'Sessiz; bakımı düzen ister'),
  egzotik('Egzotik', 'Özel izin ve ciddi sorumluluk');

  const PetGroup(this.label, this.description);

  final String label;
  final String description;
}

enum PetSpecies {
  kedi(
    group: PetGroup.kedi,
    id: 'kedi',
    label: 'Kedi',
    icon: Icons.pets_rounded,
    adoptable: true,
    adoptionCost: 2500,
    yearlyCareCost: 18000,
    vetCost: 5500,
    // prototypeOnly: ev kedisi ortalaması 13-17 yıl.
    typicalLifespan: 15,
    maxLifespan: 21,
  ),
  kopek(
    group: PetGroup.kopek,
    id: 'köpek',
    label: 'Köpek',
    icon: Icons.pets_outlined,
    adoptable: true,
    adoptionCost: 3500,
    yearlyCareCost: 26000,
    vetCost: 7500,
    // prototypeOnly: ortalama köpek ömrü 11-13 yıl.
    typicalLifespan: 12,
    maxLifespan: 18,
  ),
  muhabbetKusu(
    group: PetGroup.kus,
    id: 'muhabbet kuşu',
    label: 'Muhabbet kuşu',
    icon: Icons.flutter_dash_rounded,
    adoptable: true,
    escapeRisk: 0.10,
    adoptionCost: 900,
    yearlyCareCost: 4500,
    vetCost: 2200,
    typicalLifespan: 8,
    maxLifespan: 14,
  ),
  kaplumbaga(
    group: PetGroup.suVeSurungen,
    id: 'kaplumbağa',
    label: 'Kaplumbağa',
    icon: Icons.eco_rounded,
    adoptable: true,
    escapeRisk: 0.04,
    adoptionCost: 1200,
    yearlyCareCost: 3200,
    vetCost: 2500,
    typicalLifespan: 30,
    maxLifespan: 55,
  ),
  balik(
    group: PetGroup.suVeSurungen,
    id: 'balık',
    label: 'Balık',
    icon: Icons.set_meal_rounded,
    adoptable: true,
    adoptionCost: 450,
    yearlyCareCost: 2000,
    vetCost: 1100,
    typicalLifespan: 5,
    maxLifespan: 10,
    escapeRisk: 0.0,
  ),

  // --- D-082 ile eklenen türler ----------------------------------------
  kanarya(
    group: PetGroup.kus,
    id: 'kanarya',
    label: 'Kanarya',
    icon: Icons.music_note_rounded,
    adoptable: true,
    adoptionCost: 1400,
    yearlyCareCost: 5200,
    vetCost: 2400,
    // prototypeOnly: kanarya ortalama 10 yıl yaşar.
    typicalLifespan: 10,
    maxLifespan: 16,
    escapeRisk: 0.10,
  ),
  papagan(
    group: PetGroup.kus,
    id: 'papağan',
    label: 'Papağan',
    icon: Icons.record_voice_over_rounded,
    adoptable: true,
    adoptionCost: 22000,
    yearlyCareCost: 14000,
    vetCost: 6200,
    // prototypeOnly: büyük papağanlar insan ömrüne yaklaşır; oyun için
    // ölçülü bir orta yol seçildi.
    typicalLifespan: 35,
    maxLifespan: 60,
    escapeRisk: 0.07,
  ),
  hamster(
    group: PetGroup.kemirgen,
    id: 'hamster',
    label: 'Hamster',
    icon: Icons.cruelty_free_rounded,
    adoptable: true,
    adoptionCost: 600,
    yearlyCareCost: 3200,
    vetCost: 1400,
    // prototypeOnly: hamster ömrü 2-3 yıldır.
    typicalLifespan: 3,
    maxLifespan: 4,
    escapeRisk: 0.14,
  ),
  tavsan(
    group: PetGroup.kemirgen,
    id: 'tavşan',
    label: 'Tavşan',
    icon: Icons.grass_rounded,
    adoptable: true,
    adoptionCost: 2200,
    yearlyCareCost: 11000,
    vetCost: 4200,
    // prototypeOnly: ev tavşanı 8-12 yıl.
    typicalLifespan: 9,
    maxLifespan: 14,
    escapeRisk: 0.09,
  ),
  timsah(
    group: PetGroup.egzotik,
    id: 'timsah',
    label: 'Timsah',
    icon: Icons.warning_amber_rounded,
    adoptable: true,
    adoptionCost: 180000,
    yearlyCareCost: 95000,
    vetCost: 38000,
    // prototypeOnly: timsahlar esarette on yıllarca yaşar.
    typicalLifespan: 40,
    maxLifespan: 70,
    escapeRisk: 0.12,
    requiresPermit: true,
    warning: 'Timsah sıradan bir evcil hayvan değildir: özel izin '
        'gerektirir, bireysel olarak beslenmesi çoğu yerde yasaktır ve '
        'tehlikelidir. Oyunda bulunur ama kolay değildir.',
  );

  const PetSpecies({
    required this.group,
    required this.id,
    required this.label,
    required this.icon,
    required this.adoptable,
    required this.adoptionCost,
    required this.yearlyCareCost,
    required this.vetCost,
    required this.typicalLifespan,
    required this.maxLifespan,
    this.escapeRisk = 0.03,
    this.requiresPermit = false,
    this.warning,
  });

  /// Sahiplenme menüsündeki grubu (D-135).
  ///
  /// Faho'nun isteği: menü kedi/köpek/kuş/egzotik diye ayrılsın. Tek
  /// uzun liste yerine gruplanmış menü.
  final PetGroup group;

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

  /// prototypeOnly: bir yılda evden kaçma ihtimali (D-082).
  ///
  /// Kuşlar ve kemirgenler kaçar; balık kaçmaz. Kaçan hayvan **yok
  /// olmaz** (D-058): geri dönebilir.
  final double escapeRisk;

  /// Bu tür özel izin gerektiriyor mu?
  final bool requiresPermit;

  /// Sahiplenme ekranında gösterilecek uyarı; yoksa `null`.
  final String? warning;
}

PetSpecies? petSpeciesById(String id) {
  final String k = id.toLowerCase().trim();
  for (final PetSpecies s in PetSpecies.values) {
    if (s.id == k) return s;
  }
  return null;
}

/// Sahiplenilebilen türler (v1: kedi ve köpek).
/// Bu gruptaki sahiplenilebilir türler (D-135).
List<PetSpecies> adoptableIn(PetGroup group) => adoptablePetSpecies
    .where((PetSpecies s) => s.group == group)
    .toList(growable: false);

/// Sahiplenilebilir tür barındıran gruplar, menü sırasıyla.
List<PetGroup> get adoptablePetGroups => PetGroup.values
    .where((PetGroup g) => adoptableIn(g).isNotEmpty)
    .toList(growable: false);

List<PetSpecies> get adoptablePetSpecies => PetSpecies.values
    .where((PetSpecies s) => s.adoptable)
    .toList(growable: false);

/// Sahiplenilen hayvana verilebilecek adlar.
///
/// `name_pool.dart` içindeki liste hayat başında evde bulunan hayvan için
/// kullanılıyordu; sahiplenme ekranında da aynı havuz kullanılır ki oyunun
/// isim dünyası ikiye bölünmesin.
const List<String> kPetSuggestedNames = <String>[
  'Pamuk',
  'Boncuk',
  'Karabaş',
  'Tekir',
  'Duman',
  'Minnoş',
  'Zeytin',
  'Fındık',
  'Paşa',
  'Mırmır',
  'Şeker',
  'Kömür',
  'Badem',
  'Leblebi',
];

/// Tür etiketi; tanınmayan tür kayıttaki yazımıyla döner.
String petSpeciesLabel(String speciesId) =>
    petSpeciesById(speciesId)?.label ?? speciesId;
