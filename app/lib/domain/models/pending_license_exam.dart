import 'package:flutter/foundation.dart';

import '../../data/license_catalog.dart';
import '../../data/license_questions.dart';

/// Devam eden ehliyet sınavı.
///
/// Sınav **3 kısa sorudan** oluşur ve **en az 2 doğru** cevapla geçilir
/// (D-035). Sorular ve verilen cevaplar kaydedilir: uygulama sınavın
/// ortasında kapatılıp açılsa bile **aynı sorulardan devam edilir**,
/// ücret ikinci kez alınmaz ve verilen cevaplar korunur.
@immutable
class PendingLicenseExam {
  const PendingLicenseExam({
    required this.licenseId,
    required this.questionIds,
    required this.answers,
    required this.askedAtAge,
    required this.feePaid,
  });

  final String licenseId;

  /// Sınavın soruları; sıra sabittir.
  final List<String> questionIds;

  /// Verilen cevapların seçenek sırası; soru sırasıyla aynı hizadadır.
  final List<int> answers;

  final int askedAtAge;

  /// Başvuruda ödenen bedel.
  final int feePaid;

  LicenseType? get license => licenseTypeById(licenseId);

  /// Sınavdaki bütün sorular.
  List<LicenseQuestion> get questions => <LicenseQuestion>[
        for (final String id in questionIds)
          if (licenseQuestionById(id) != null) licenseQuestionById(id)!,
      ];

  /// Sıradaki cevaplanmamış soru; sınav bittiyse `null`.
  LicenseQuestion? get currentQuestion =>
      answers.length >= questionIds.length
          ? null
          : licenseQuestionById(questionIds[answers.length]);

  /// Kaçıncı sorudayız (1'den başlar).
  int get currentIndex => answers.length + 1;

  int get questionCount => questionIds.length;

  /// Şu ana kadarki doğru cevap sayısı.
  int get correctCount {
    int dogru = 0;
    for (int i = 0; i < answers.length && i < questionIds.length; i++) {
      final LicenseQuestion? soru = licenseQuestionById(questionIds[i]);
      if (soru != null && soru.correctIndex == answers[i]) dogru++;
    }
    return dogru;
  }

  bool get isComplete => answers.length >= questionIds.length;

  PendingLicenseExam copyWith({List<int>? answers}) => PendingLicenseExam(
        licenseId: licenseId,
        questionIds: questionIds,
        answers: answers ?? this.answers,
        askedAtAge: askedAtAge,
        feePaid: feePaid,
      );
}
