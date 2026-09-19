import 'package:flutter/foundation.dart';

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

  bool get isStudent => enrolled;

  SchoolLevel? get level => grade == null ? null : SchoolLevel.forGrade(grade!);

  /// Ekranda gösterilecek kısa durum metni.
  String get label {
    if (enrolled && grade != null) {
      final SchoolLevel? current = level;
      if (current == null) return '$grade. sınıf';
      return '${current.label} ${current.gradeWithinLevel(grade!)}. sınıf';
    }
    if (finished) return 'Liseyi bitirdi';
    return 'Okula başlamadı';
  }

  /// Üst özet için yaşa göre kısa evre metni.
  String stageLabel(int age) {
    if (enrolled) return label;
    if (finished) return 'Okul bitti';
    if (age < 6) return 'Okul öncesi';
    return 'Okul dışı';
  }

  EducationState copyWith({
    bool? enrolled,
    int? grade,
    int? startedAtAge,
    bool? finished,
  }) {
    return EducationState(
      enrolled: enrolled ?? this.enrolled,
      grade: grade ?? this.grade,
      startedAtAge: startedAtAge ?? this.startedAtAge,
      finished: finished ?? this.finished,
    );
  }

  /// Okuldan ayrılmış/bitirmiş durum: sınıf bilgisi kalmaz.
  EducationState asFinished() => EducationState(
        enrolled: false,
        startedAtAge: startedAtAge,
        finished: true,
      );
}
