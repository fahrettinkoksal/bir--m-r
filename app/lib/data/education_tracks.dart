/// Lise eğitim alanları.
///
/// Türkiye'deki resmî okul türlerinin birebir listesi **değildir**; oyuna
/// özgü, tutarlı ve genişletilebilir bir modeldir. Puan eşikleri
/// `prototypeOnly`'dir (`docs/DESIGN_REVIEW_QUEUE.md`, Q-047).
library;

import 'package:flutter/foundation.dart';

/// Bir lise alanı.
@immutable
class EducationTrackInfo {
  const EducationTrackInfo({
    required this.track,
    required this.label,
    required this.description,
    required this.minScore,
    this.intelligenceBonus = 0,
    this.charismaBonus = 0,
    this.appearanceBonus = 0,
  });

  final EducationTrack track;
  final String label;
  final String description;

  /// prototypeOnly: bu alana yerleşmek için gereken en düşük puan.
  final int minScore;

  /// prototypeOnly: lise boyunca her yıl eklenen küçük kazanç.
  final int intelligenceBonus;
  final int charismaBonus;
  final int appearanceBonus;
}

enum EducationTrack {
  fenBilim,
  sosyalBilimler,
  bilisim,
  guzelSanatlar,
  muzik,
  tasarim,
  elSanatlari,
  teknikMeslek,
  genelAkademik,
}

const List<EducationTrackInfo> kEducationTracks = <EducationTrackInfo>[
  EducationTrackInfo(
    track: EducationTrack.fenBilim,
    label: 'Fen ve bilim',
    description: 'Matematik ve deney ağırlıklı. Mühendislik ve bilim '
        'bölümlerinin kapısını aralar.',
    minScore: 70,
    intelligenceBonus: 3,
  ),
  EducationTrackInfo(
    track: EducationTrack.bilisim,
    label: 'Bilişim ve yazılım',
    description: 'Bilgisayar laboratuvarı, kod ve mantık dersleri.',
    minScore: 65,
    intelligenceBonus: 3,
  ),
  EducationTrackInfo(
    track: EducationTrack.sosyalBilimler,
    label: 'Sosyal bilimler',
    description: 'Tarih, edebiyat ve toplum dersleri ağırlıkta.',
    minScore: 55,
    intelligenceBonus: 2,
    charismaBonus: 1,
  ),
  EducationTrackInfo(
    track: EducationTrack.tasarim,
    label: 'Tasarım',
    description: 'Çizim, biçim ve üretim. Atölye çok, tahta az.',
    minScore: 45,
    intelligenceBonus: 1,
    appearanceBonus: 1,
  ),
  EducationTrackInfo(
    track: EducationTrack.guzelSanatlar,
    label: 'Güzel sanatlar ve resim',
    description: 'Resim atölyesi, boya kokusu, uzun sessiz saatler.',
    minScore: 40,
    charismaBonus: 1,
    appearanceBonus: 1,
  ),
  EducationTrackInfo(
    track: EducationTrack.muzik,
    label: 'Müzik',
    description: 'Enstrüman, kulak eğitimi ve çok fazla prova.',
    minScore: 40,
    charismaBonus: 2,
  ),
  EducationTrackInfo(
    track: EducationTrack.elSanatlari,
    label: 'El sanatları',
    description: 'Ahşap, seramik, dokuma. Elle öğrenilen işler.',
    minScore: 0,
    appearanceBonus: 1,
  ),
  EducationTrackInfo(
    track: EducationTrack.teknikMeslek,
    label: 'Teknik ve mesleki eğitim',
    description: 'Elektrik, makine, tesisat. Mezun olunca iş bulmak kolay.',
    minScore: 0,
    intelligenceBonus: 1,
  ),
  EducationTrackInfo(
    track: EducationTrack.genelAkademik,
    label: 'Genel akademik eğitim',
    description: 'Her dersten biraz. Kapıları açık bırakır.',
    minScore: 0,
    intelligenceBonus: 1,
  ),
];

EducationTrackInfo trackInfo(EducationTrack track) =>
    kEducationTracks.firstWhere((EducationTrackInfo t) => t.track == track);

/// Puanı yeten alanlar.
///
/// Puan ne kadar düşük olursa olsun en az üç alan her zaman açıktır:
/// oyuncunun bütün seçenekleri tek bir istatistik yüzünden kapanmaz.
List<EducationTrackInfo> tracksFor(int score) => kEducationTracks
    .where((EducationTrackInfo t) => score >= t.minScore)
    .toList(growable: false);
