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
  // --- Sağlık bölümleri -------------------------------------------------
  //
  // Sağlık meslekleri (hemşire, doktor, eczacı, psikolog) bu bölümler
  // olmadan hiçbir hayatta açılamazdı. Meslek kataloğu bu diplomaları
  // aradığı için bölümler de gerçekten seçilebilir olmalı.
  UniversityProgram(
    id: 'tip',
    name: 'Tıp',
    description: 'Altı yıl, sonra uzmanlık. En uzun ve en dar yol.',
    minScore: 88,
    durationYears: 6,
    preferredTracks: <EducationTrack>{EducationTrack.fenBilim},
  ),
  UniversityProgram(
    id: 'hemsirelik',
    name: 'Hemşirelik',
    description: 'Klinik uygulama, nöbet ve ayakta geçen uzun vardiyalar.',
    minScore: 58,
    preferredTracks: <EducationTrack>{
      EducationTrack.fenBilim,
      EducationTrack.genelAkademik,
    },
  ),
  UniversityProgram(
    id: 'eczacilik',
    name: 'Eczacılık',
    description: 'Beş yıl kimya, farmakoloji ve dikkat.',
    minScore: 78,
    durationYears: 5,
    preferredTracks: <EducationTrack>{EducationTrack.fenBilim},
  ),
  UniversityProgram(
    id: 'psikoloji',
    name: 'Psikoloji',
    description: 'İnsanın kendi hâlini inceler; sabır ister.',
    minScore: 62,
    preferredTracks: <EducationTrack>{
      EducationTrack.sosyalBilimler,
      EducationTrack.fenBilim,
      EducationTrack.genelAkademik,
    },
  ),
  UniversityProgram(
    id: 'iletisim',
    name: 'İletişim',
    description: 'Haber, metin ve görüntü.',
    minScore: 48,
    preferredTracks: <EducationTrack>{
      EducationTrack.sosyalBilimler,
      EducationTrack.genelAkademik,
      EducationTrack.tasarim,
    },
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
