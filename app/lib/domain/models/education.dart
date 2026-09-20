import 'package:flutter/foundation.dart';

import '../../data/education_tracks.dart';
import '../../data/university_catalog.dart';

/// Okul kademesi. Türkiye'deki 4+4+4 yapısına karşılık gelir.
enum SchoolLevel {
  ilkokul('İlkokul', 1, 4),
  ortaokul('Ortaokul', 5, 8),
  lise('Lise', 9, 12);

  const SchoolLevel(this.label, this.firstGrade, this.lastGrade);

  final String label;
  final int firstGrade;
  final int lastGrade;

  /// Sınıf numarasının hangi kademeye düştüğü.
  static SchoolLevel? forGrade(int grade) {
    for (final SchoolLevel level in SchoolLevel.values) {
      if (grade >= level.firstGrade && grade <= level.lastGrade) return level;
    }
    return null;
  }

  /// Kademe içindeki sınıf numarası (ör. 6. sınıf → ortaokul 2).
  int gradeWithinLevel(int grade) => grade - firstGrade + 1;
}

/// Bir kişinin **okul bağı**: oyuncuyla aynı sınıfta mı, öğretmeni mi?
///
/// Bu bağ, [RelationType] ile tutulan **yakınlık derecesinden bağımsızdır**.
/// Sınıf arkadaşıyla yakın arkadaş olmak, o kişiyi sınıftan çıkarmaz: bağ
/// `sinifArkadasi` kalır, yakınlık `arkadas`a yükselir. Böylece aynı kişi
/// hem Sınıf Arkadaşları hem Yakın Arkadaşların listesinde görünür ve
/// ikinci bir kayıt oluşmaz.
enum SchoolTie {
  sinifArkadasi,
  ogretmen,
}

/// Oyuncunun eğitim durumu.
///
/// **Öğrencilik yaştan türetilmez**, oyun verisinde tutulur: okula başlamamış
/// veya okulu bitirmiş bir karakter okul çağında olsa bile öğrenci değildir.
/// Bu ilk sürümde sınav, not, diploma ve bölüm yoktur; yalnızca okula başlama
/// ve sınıf ilerlemesi izlenir.
@immutable
class EducationState {
  const EducationState({
    this.enrolled = false,
    this.grade,
    this.startedAtAge,
    this.finished = false,
    this.schoolId,
    this.classId,
    this.track,
    this.placementScore,
    this.universityExamScore,
    this.universityProgramId,
    this.universityYear,
    this.universityFinished = false,
  }) : assert(
          !enrolled || grade != null,
          'Okula kayıtlı öğrencinin sınıfı olmalı.',
        );

  /// Hiç okula başlamamış başlangıç durumu.
  const EducationState.notStarted() : this();

  /// Şu an okula devam ediyor mu?
  final bool enrolled;

  /// Kaçıncı sınıf (1-12). Kayıtlı değilse `null`.
  final int? grade;

  /// Okula başlanan yaş.
  final int? startedAtAge;

  /// Lise bitirildi mi?
  final bool finished;

  /// Şu an devam edilen okulun kimliği.
  ///
  /// Kademeden ayrı tutulur: ileride aynı kademede okul değiştirmek
  /// (taşınma, nakil) mümkün olsun diye kişiler kademeye değil **okula ve
  /// sınıfa** bağlanır.
  final String? schoolId;

  /// Şu an devam edilen sınıfın kimliği.
  ///
  /// Sınıf arkadaşlığı bu kimlikle takip edilir; böylece her sınıf
  /// değişiminde herkesin değişmesi zorunlu olmaz.
  final String? classId;

  /// Seçilen lise alanı. 9. sınıfa geçince oyuncu seçer; kozmetik değildir,
  /// üniversite bölümlerini ve iş seçeneklerini etkiler.
  final EducationTrack? track;

  /// 8. sınıf sonunda hesaplanan **lise yerleştirme puanı**
  /// (0-100, prototypeOnly). Lise alanını bu puan belirler.
  final int? placementScore;

  /// Lise bitince hesaplanan **üniversite sınav puanı**
  /// (0-100, prototypeOnly).
  ///
  /// Lise yerleştirme puanından ayrı bir değerdir ve bir kez hesaplanıp
  /// saklanır; böylece oyuncu başvuru ekranında kendi puanını görebilir ve
  /// puan her başvuruda değişmez.
  final int? universityExamScore;

  /// Kayıtlı olunan üniversite bölümü.
  final String? universityProgramId;

  /// Üniversitede kaçıncı yıl (1'den başlar).
  final int? universityYear;

  /// Üniversite bitirildi mi?
  final bool universityFinished;

  /// Okula (lise veya üniversiteye) devam ediliyor mu?
  bool get isStudent => enrolled || isUniversityStudent;

  /// Yalnızca 1-12. sınıf öğrenciliği. Okul olayları buna bakar.
  bool get isSchoolStudent => enrolled;

  bool get isUniversityStudent =>
      universityProgramId != null && !universityFinished;

  UniversityProgram? get program => universityProgramId == null
      ? null
      : universityProgramById(universityProgramId!);

  /// Lise bitti ama henüz bir yol seçilmedi mi?
  bool get awaitingAfterSchoolChoice =>
      finished && universityProgramId == null && !universityFinished;

  /// Lise alanı seçilmeyi bekliyor mu? (9. sınıfa geçildi, alan boş.)
  bool get awaitingTrackChoice =>
      enrolled && (grade ?? 0) >= 9 && track == null;

  EducationTrackInfo? get trackInfo =>
      track == null ? null : kEducationTracks.firstWhere(
            (EducationTrackInfo t) => t.track == track,
          );

  SchoolLevel? get level => grade == null ? null : SchoolLevel.forGrade(grade!);

  /// Ekranda gösterilecek kısa durum metni.
  String get label {
    if (enrolled && grade != null) {
      final SchoolLevel? current = level;
      final String alan = trackInfo == null ? '' : ' · ${trackInfo!.label}';
      if (current == null) return '$grade. sınıf$alan';
      return '${current.label} ${current.gradeWithinLevel(grade!)}. sınıf$alan';
    }
    if (isUniversityStudent) {
      return '${program?.name ?? 'Üniversite'} $universityYear. sınıf';
    }
    if (universityFinished) return '${program?.name ?? 'Üniversite'} mezunu';
    if (finished) return 'Liseyi bitirdi';
    return 'Okula başlamadı';
  }

  /// Üst özet için yaşa göre kısa evre metni.
  String stageLabel(int age) {
    if (enrolled || isUniversityStudent) return label;
    if (universityFinished) return label;
    if (finished) return 'Okul bitti';
    if (age < 6) return 'Okul öncesi';
    return 'Okul dışı';
  }

  EducationState copyWith({
    bool? enrolled,
    int? grade,
    int? startedAtAge,
    bool? finished,
    Object? schoolId = _unsetEdu,
    Object? classId = _unsetEdu,
    Object? track = _unsetEdu,
    Object? placementScore = _unsetEdu,
    Object? universityExamScore = _unsetEdu,
    Object? universityProgramId = _unsetEdu,
    Object? universityYear = _unsetEdu,
    bool? universityFinished,
  }) {
    return EducationState(
      enrolled: enrolled ?? this.enrolled,
      grade: grade ?? this.grade,
      startedAtAge: startedAtAge ?? this.startedAtAge,
      finished: finished ?? this.finished,
      schoolId: schoolId == _unsetEdu ? this.schoolId : schoolId as String?,
      classId: classId == _unsetEdu ? this.classId : classId as String?,
      track: track == _unsetEdu ? this.track : track as EducationTrack?,
      placementScore: placementScore == _unsetEdu
          ? this.placementScore
          : placementScore as int?,
      universityExamScore: universityExamScore == _unsetEdu
          ? this.universityExamScore
          : universityExamScore as int?,
      universityProgramId: universityProgramId == _unsetEdu
          ? this.universityProgramId
          : universityProgramId as String?,
      universityYear:
          universityYear == _unsetEdu ? this.universityYear : universityYear as int?,
      universityFinished: universityFinished ?? this.universityFinished,
    );
  }

  /// Okuldan ayrılmış/bitirmiş durum: sınıf bilgisi kalmaz.
  /// Okul bitti: sınıf ve okul kimliği düşer, kişiler silinmez.
  EducationState asFinished() => EducationState(
        enrolled: false,
        startedAtAge: startedAtAge,
        finished: true,
        track: track,
        placementScore: placementScore,
        universityExamScore: universityExamScore,
        universityProgramId: universityProgramId,
        universityYear: universityYear,
        universityFinished: universityFinished,
      );
}

const Object _unsetEdu = Object();
