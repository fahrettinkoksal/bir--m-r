import 'package:flutter/foundation.dart';

import '../../data/job_catalog.dart';
import '../../data/university_catalog.dart';
import 'education.dart';
import 'stats.dart';

/// Bir kişinin hayatında **gerçekten yaşanmış** bir dönüm noktası.
///
/// Yaşı ve metni birlikte saklanır: ilerleme sonradan yaştan uydurulmaz,
/// gerçekleştiği yılda kaydedilir (D-045).
@immutable
class LifeMilestone {
  const LifeMilestone({required this.age, required this.text});

  final int age;
  final String text;
}

/// Üniversite durumu (NPC için basitleştirilmiş).
enum UniversityStatus {
  okuyor('Üniversitede'),
  bitirdi('Üniversite mezunu'),
  birakti('Üniversiteyi bırakmış');

  const UniversityStatus(this.label);

  final String label;
}

/// Oyuncu tarafından yönetilmeyen bir kişinin **kendi hayatı** (D-045).
///
/// Şimdilik yalnızca oyuncunun çocukları için tutulur: çocuk, oyuncu onu
/// yönetmiyorken de okula başlar, eğitimini ilerletir, ilgi alanı edinir,
/// iş bulur ve kendi birikimini yapar. Kuşak devamında ("Çocuğum olarak
/// devam et") bu kayıt **olduğu gibi** yeni oyuncuya taşınır; 40 yaşında
/// öğretmen olan çocuk "lise mezunu, işsiz" hâline gelmez.
///
/// Oyuncunun bütün mini oyunları burada tekrarlanmaz: mevcut eğitim ve
/// meslek katalogları kullanılır, işlem yükü yılda birkaç dallanmadır.
/// Bütün sayısal değerler `prototypeOnly`'dir (Q-069).
@immutable
class PersonDevelopment {
  const PersonDevelopment({
    required this.stats,
    this.tracksLife = false,
    this.schoolLevel,
    this.grade,
    this.finishedSchool = false,
    this.university,
    this.universityYear,
    this.universityProgramId,
    this.jobId,
    this.jobStartedAtAge,
    this.pastJobIds = const <String>[],
    this.money = 0,
    this.interests = const <String>[],
    this.milestones = const <LifeMilestone>[],
  });

  /// Kişinin kendi karakter değerleri (D-046 ile doğumda oluşturulur).
  final Stats stats;

  /// Bu kişinin **hayatı gerçekten izleniyor mu?**
  ///
  /// Oyuncunun çocuklarında `true`'dur: eğitim, meslek ve birikim yıl yıl
  /// işlenir, miras bu gerçek birikimden dağıtılır. Yalnızca özellik
  /// kaydı açılmış kişilerde (ör. çocuğun diğer ebeveyni, D-046) `false`
  /// kalır; onların ekonomik durumu eskisi gibi tahminle gösterilir ve
  /// **uydurma bir birikim** yazılmaz.
  final bool tracksLife;

  /// Devam edilen okul kademesi; okumuyorsa `null`.
  final SchoolLevel? schoolLevel;

  /// Kaçıncı sınıf (1-12); okumuyorsa `null`.
  final int? grade;

  /// Lise bitirildi mi?
  final bool finishedSchool;

  /// Üniversite durumu; hiç gitmediyse `null`.
  final UniversityStatus? university;

  /// Üniversitede kaçıncı yıl.
  final int? universityYear;

  /// Okuduğu bölümün kimliği ([kUniversityPrograms]).
  ///
  /// Bölüm, üniversiteye başlandığı yıl **gerçekten seçilir**; kuşak
  /// devamında oyuncunun eğitim kaydına aynen taşınır, sonradan
  /// uydurulmaz.
  final String? universityProgramId;

  /// Şu anki işin kimliği ([kJobCatalog]); çalışmıyorsa `null`.
  final String? jobId;
  final int? jobStartedAtAge;

  /// Daha önce çalıştığı işler; kayıt silinmez.
  final List<String> pastJobIds;

  /// Kişinin **kendi** birikimi (₺).
  final int money;

  /// Edindiği ilgi alanları.
  final List<String> interests;

  /// Yaşanmış dönüm noktaları (en eskisi başta).
  final List<LifeMilestone> milestones;

  bool get isStudent => grade != null;
  bool get isUniversityStudent => university == UniversityStatus.okuyor;
  bool get isEmployed => jobId != null;

  JobType? get job => jobId == null ? null : jobById(jobId!);

  /// Okuduğu bölüm; bilinmiyorsa `null`.
  UniversityProgram? get program => universityProgramId == null
      ? null
      : universityProgramById(universityProgramId!);

  /// Ekranda gösterilecek eğitim özeti.
  String get educationLabel {
    if (grade != null) {
      final SchoolLevel? kademe = schoolLevel;
      if (kademe == null) return '$grade. sınıf';
      return '${kademe.label} ${kademe.gradeWithinLevel(grade!)}. sınıf';
    }
    switch (university) {
      case UniversityStatus.okuyor:
        return '${program?.name ?? 'Üniversite'} ${universityYear ?? 1}. sınıf';
      case UniversityStatus.bitirdi:
        return '${program?.name ?? 'Üniversite'} mezunu';
      case UniversityStatus.birakti:
        return '${program?.name ?? 'Üniversite'} yarıda kaldı';
      case null:
        break;
    }
    if (finishedSchool) return 'Liseyi bitirdi';
    return 'Okula başlamadı';
  }

  PersonDevelopment copyWith({
    Stats? stats,
    bool? tracksLife,
    Object? schoolLevel = _unsetDev,
    Object? grade = _unsetDev,
    bool? finishedSchool,
    Object? university = _unsetDev,
    Object? universityYear = _unsetDev,
    Object? universityProgramId = _unsetDev,
    Object? jobId = _unsetDev,
    Object? jobStartedAtAge = _unsetDev,
    List<String>? pastJobIds,
    int? money,
    List<String>? interests,
    List<LifeMilestone>? milestones,
  }) {
    return PersonDevelopment(
      stats: stats ?? this.stats,
      tracksLife: tracksLife ?? this.tracksLife,
      schoolLevel: schoolLevel == _unsetDev
          ? this.schoolLevel
          : schoolLevel as SchoolLevel?,
      grade: grade == _unsetDev ? this.grade : grade as int?,
      finishedSchool: finishedSchool ?? this.finishedSchool,
      university: university == _unsetDev
          ? this.university
          : university as UniversityStatus?,
      universityYear: universityYear == _unsetDev
          ? this.universityYear
          : universityYear as int?,
      universityProgramId: universityProgramId == _unsetDev
          ? this.universityProgramId
          : universityProgramId as String?,
      jobId: jobId == _unsetDev ? this.jobId : jobId as String?,
      jobStartedAtAge: jobStartedAtAge == _unsetDev
          ? this.jobStartedAtAge
          : jobStartedAtAge as int?,
      pastJobIds: pastJobIds ?? this.pastJobIds,
      money: money ?? this.money,
      interests: interests ?? this.interests,
      milestones: milestones ?? this.milestones,
    );
  }

  /// Yeni bir dönüm noktası ekler.
  PersonDevelopment withMilestone(int age, String text) => copyWith(
        milestones: List<LifeMilestone>.unmodifiable(<LifeMilestone>[
          ...milestones,
          LifeMilestone(age: age, text: text),
        ]),
      );
}

const Object _unsetDev = Object();
