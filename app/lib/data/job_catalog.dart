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
    this.levels = const <String>[],
    this.martialArtId,
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

  /// Bu meslekteki görev basamakları (giriş seviyesinden yukarı).
  ///
  /// İlk sıra işe girildiğinde geçerli olan unvandır. Boş bırakılırsa
  /// mesleğin adı tek unvan sayılır. Basamaklar `prototypeOnly`'dir
  /// (Q-078); meslek kataloğu büyütülmeden yalnızca unvan eklenir.
  final List<String> levels;

  /// Bu iş bir dövüş sanatı eğitmenliğiyse o sanatın kimliği (Paket 32).
  ///
  /// Doluysa iş yalnızca o sanatta eğitmenlik basamağına gelmiş oyuncuya
  /// açılır; katalogdaki eşik `MartialArt.instructorFromLevel`'dir.
  final String? martialArtId;

  /// Bu meslekte çıkılabilecek en üst basamak.
  int get maxLevel => levels.isEmpty ? 0 : levels.length - 1;
}

/// Bir meslekte [level] basamağındaki görev adı.
///
/// Seviye listesi yoksa ya da aralık dışındaysa mesleğin kendi adı
/// kullanılır; uydurma unvan üretilmez.
String jobTitleFor(JobType job, int level) {
  if (job.levels.isEmpty) return job.name;
  final int i = level.clamp(0, job.levels.length - 1);
  return job.levels[i];
}

const List<JobType> kJobCatalog = <JobType>[
  JobType(
    id: 'magaza_calisani',
    name: 'Mağaza çalışanı',
    description: 'Raf düzeni, kasa ve ayakta geçen uzun saatler.',
    minAge: 16,
    yearlySalary: 180000, // prototypeOnly
    levels: <String>[
      'Mağaza çalışanı',
      'Kıdemli mağaza çalışanı',
      'Mağaza sorumlusu',
    ],
  ),
  JobType(
    id: 'garson',
    name: 'Garson',
    description: 'Tepsi, sipariş, akşam vardiyası.',
    minAge: 16,
    yearlySalary: 165000, // prototypeOnly
    minCharisma: 35,
    levels: <String>[
      'Garson',
      'Deneyimli garson',
      'Servis şefi',
    ],
  ),
  JobType(
    id: 'teknik_servis',
    name: 'Teknik servis çalışanı',
    description: 'Arızalı cihazlar, tornavida ve sabır.',
    minAge: 18,
    yearlySalary: 260000, // prototypeOnly
    education: JobEducation.lise,
    tracks: <EducationTrack>{
      EducationTrack.teknikMeslek,
      EducationTrack.bilisim,
      EducationTrack.fenBilim,
    },
    minIntelligence: 45,
    levels: <String>[
      'Teknik servis çalışanı',
      'Kıdemli teknisyen',
      'Servis sorumlusu',
    ],
  ),
  JobType(
    id: 'ressam_tasarimci',
    name: 'Ressam / tasarımcı',
    description: 'Siparişle çalışan, portföyüyle iş alan bir meslek.',
    minAge: 18,
    yearlySalary: 300000, // prototypeOnly
    education: JobEducation.lise,
    tracks: <EducationTrack>{
      EducationTrack.guzelSanatlar,
      EducationTrack.tasarim,
      EducationTrack.muzik,
      EducationTrack.elSanatlari,
    },
    programs: <String>{'guzel_sanatlar'},
    levels: <String>[
      'Ressam / tasarımcı',
      'Deneyimli tasarımcı',
      'Sanat yönetmeni',
    ],
  ),
  JobType(
    id: 'yazilim_gelistirici',
    name: 'Yazılım geliştirici',
    description: 'Ekran başında çözülen problemler.',
    minAge: 20,
    yearlySalary: 720000, // prototypeOnly
    education: JobEducation.lise,
    tracks: <EducationTrack>{EducationTrack.bilisim},
    programs: <String>{'bilgisayar', 'muhendislik'},
    minIntelligence: 60,
    levels: <String>[
      'Yazılım geliştirici',
      'Kıdemli geliştirici',
      'Takım lideri',
    ],
  ),
  JobType(
    id: 'ogretmen',
    name: 'Öğretmen',
    description: 'Sınıfın önünde durmak; bir zamanlar sıradaydın.',
    minAge: 22,
    yearlySalary: 420000, // prototypeOnly
    education: JobEducation.universite,
    programs: <String>{'egitim'},
    minIntelligence: 50,
    minCharisma: 40,
    levels: <String>[
      'Öğretmen',
      'Kıdemli öğretmen',
      'Zümre başkanı',
    ],
  ),

  // --- Dövüş sanatları eğitmenliği (Paket 32) ---------------------------
  //
  // Bu üç iş ilan panosunda **sürekli durmaz**: ancak salonda yıllarca
  // çalışıp basamağı yükselten oyuncuya açılır. Diplomayla değil,
  // kuşakla/boyla girilir.
  JobType(
    id: 'karate_egitmeni',
    name: 'Karate eğitmeni',
    description: 'Kendi kuşağını aldın; şimdi salonun çocuklarını '
        'çalıştırıyorsun.',
    minAge: 18,
    yearlySalary: 300000, // prototypeOnly
    martialArtId: 'karate',
    levels: <String>[
      'Yardımcı antrenör',
      'Karate eğitmeni',
      'Baş eğitmen',
    ],
  ),
  JobType(
    id: 'kungfu_egitmeni',
    name: 'Kung fu eğitmeni',
    description: 'Formları sen öğrendin, şimdi sen öğretiyorsun.',
    minAge: 18,
    yearlySalary: 290000, // prototypeOnly
    martialArtId: 'kung_fu',
    levels: <String>[
      'Yardımcı antrenör',
      'Kung fu eğitmeni',
      'Salon hocası',
    ],
  ),
  JobType(
    id: 'gures_antrenoru',
    name: 'Güreş antrenörü',
    description: 'Çayırdan sahaya: kıspeti astın, pehlivan yetiştiriyorsun.',
    minAge: 18,
    yearlySalary: 270000, // prototypeOnly
    martialArtId: 'gures',
    levels: <String>[
      'Çırak antrenör',
      'Güreş antrenörü',
      'Kulüp baş antrenörü',
    ],
  ),
];

JobType? jobById(String id) {
  for (final JobType j in kJobCatalog) {
    if (j.id == id) return j;
  }
  return null;
}
