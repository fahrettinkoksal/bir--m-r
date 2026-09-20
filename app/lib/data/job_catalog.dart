/// Meslekler (küçük prototip).
///
/// Maaşlar ve koşullar `prototypeOnly`'dir; ekonomi dengesi
/// kararlaştırılmadı (`docs/DESIGN_REVIEW_QUEUE.md`, Q-048).
library;

import 'package:flutter/foundation.dart';

import 'education_tracks.dart';

/// İşin gerektirdiği asgari eğitim.
enum JobEducation {
  yok('Eğitim şartı yok'),
  lise('Lise mezunu'),
  universite('Üniversite mezunu');

  const JobEducation(this.label);

  final String label;
}

@immutable
class JobType {
  const JobType({
    required this.id,
    required this.name,
    required this.description,
    required this.minAge,
    required this.yearlySalary,
    this.education = JobEducation.yok,
    this.tracks = const <EducationTrack>{},
    this.programs = const <String>{},
    this.minIntelligence = 0,
    this.minCharisma = 0,
  });

  final String id;
  final String name;
  final String description;
  final int minAge;

  /// prototypeOnly: bir oyun yılında cüzdana giren tutar (₺).
  final int yearlySalary;

  final JobEducation education;

  /// Bu lise alanlarından biri işe uygunluk sağlar (boşsa alan aranmaz).
  final Set<EducationTrack> tracks;

  /// Bu üniversite bölümlerinden biri işe uygunluk sağlar.
  final Set<String> programs;

  final int minIntelligence;
  final int minCharisma;
}

const List<JobType> kJobCatalog = <JobType>[
  JobType(
    id: 'magaza_calisani',
    name: 'Mağaza çalışanı',
    description: 'Raf düzeni, kasa ve ayakta geçen uzun saatler.',
    minAge: 16,
    yearlySalary: 21000, // prototypeOnly
  ),
  JobType(
    id: 'garson',
    name: 'Garson',
    description: 'Tepsi, sipariş, akşam vardiyası.',
    minAge: 16,
    yearlySalary: 19500, // prototypeOnly
    minCharisma: 35,
  ),
  JobType(
    id: 'teknik_servis',
    name: 'Teknik servis çalışanı',
    description: 'Arızalı cihazlar, tornavida ve sabır.',
    minAge: 18,
    yearlySalary: 34000, // prototypeOnly
    education: JobEducation.lise,
    tracks: <EducationTrack>{
      EducationTrack.teknikMeslek,
      EducationTrack.bilisim,
      EducationTrack.fenBilim,
    },
    minIntelligence: 45,
  ),
  JobType(
    id: 'ressam_tasarimci',
    name: 'Ressam / tasarımcı',
    description: 'Siparişle çalışan, portföyüyle iş alan bir meslek.',
    minAge: 18,
    yearlySalary: 42000, // prototypeOnly
    education: JobEducation.lise,
    tracks: <EducationTrack>{
      EducationTrack.guzelSanatlar,
      EducationTrack.tasarim,
      EducationTrack.muzik,
      EducationTrack.elSanatlari,
    },
    programs: <String>{'guzel_sanatlar'},
  ),
  JobType(
    id: 'yazilim_gelistirici',
    name: 'Yazılım geliştirici',
    description: 'Ekran başında çözülen problemler.',
    minAge: 20,
    yearlySalary: 96000, // prototypeOnly
    education: JobEducation.lise,
    tracks: <EducationTrack>{EducationTrack.bilisim},
    programs: <String>{'bilgisayar', 'muhendislik'},
    minIntelligence: 60,
  ),
  JobType(
    id: 'ogretmen',
    name: 'Öğretmen',
    description: 'Sınıfın önünde durmak; bir zamanlar sıradaydın.',
    minAge: 22,
    yearlySalary: 62000, // prototypeOnly
    education: JobEducation.universite,
    programs: <String>{'egitim'},
    minIntelligence: 50,
    minCharisma: 40,
  ),
];

JobType? jobById(String id) {
  for (final JobType j in kJobCatalog) {
    if (j.id == id) return j;
  }
  return null;
}
