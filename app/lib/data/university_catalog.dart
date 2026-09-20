/// Üniversite bölümleri (küçük prototip).
///
/// Kabul koşulları ve puanlar `prototypeOnly`'dir
/// (`docs/DESIGN_REVIEW_QUEUE.md`, Q-047).
library;

import 'package:flutter/foundation.dart';

import 'education_tracks.dart';

@immutable
class UniversityProgram {
  const UniversityProgram({
    required this.id,
    required this.name,
    required this.description,
    required this.minScore,
    this.preferredTracks = const <EducationTrack>{},
    this.durationYears = 4,
  });

  final String id;
  final String name;
  final String description;

  /// prototypeOnly: kabul için gereken en düşük başvuru puanı.
  final int minScore;

  /// Bu alanlardan gelen öğrenci puanına ek alır.
  final Set<EducationTrack> preferredTracks;

  final int durationYears;
}

const List<UniversityProgram> kUniversityPrograms = <UniversityProgram>[
  UniversityProgram(
    id: 'muhendislik',
    name: 'Mühendislik',
    description: 'Hesap, proje ve laboratuvar.',
    minScore: 72,
    preferredTracks: <EducationTrack>{
      EducationTrack.fenBilim,
      EducationTrack.bilisim,
      EducationTrack.teknikMeslek,
    },
  ),
  UniversityProgram(
    id: 'bilgisayar',
    name: 'Bilgisayar bilimleri',
    description: 'Algoritma, yazılım ve sistemler.',
    minScore: 68,
    preferredTracks: <EducationTrack>{
      EducationTrack.bilisim,
      EducationTrack.fenBilim,
    },
  ),
  UniversityProgram(
    id: 'egitim',
    name: 'Eğitim fakültesi',
    description: 'Öğretmenlik yolunun zorunlu durağı.',
    minScore: 55,
    preferredTracks: <EducationTrack>{
      EducationTrack.genelAkademik,
      EducationTrack.sosyalBilimler,
    },
  ),
  UniversityProgram(
    id: 'guzel_sanatlar',
    name: 'Güzel sanatlar',
    description: 'Atölye, portföy ve çok sayıda eskiz.',
    minScore: 45,
    preferredTracks: <EducationTrack>{
      EducationTrack.guzelSanatlar,
      EducationTrack.tasarim,
      EducationTrack.muzik,
      EducationTrack.elSanatlari,
    },
  ),
  UniversityProgram(
    id: 'isletme',
    name: 'İşletme',
    description: 'Her alandan öğrenci alır; gerisi sana kalmış.',
    minScore: 40,
  ),
  UniversityProgram(
    id: 'sosyoloji',
    name: 'Sosyoloji',
    description: 'İnsanın topluluk hâlini inceler.',
    minScore: 45,
    preferredTracks: <EducationTrack>{
      EducationTrack.sosyalBilimler,
      EducationTrack.genelAkademik,
    },
  ),
];

UniversityProgram? universityProgramById(String id) {
  for (final UniversityProgram p in kUniversityPrograms) {
    if (p.id == id) return p;
  }
  return null;
}
