import 'package:flutter/foundation.dart';

import '../../data/interview_catalog.dart';
import '../../data/job_catalog.dart';

/// Devam eden bir iş mülakatı.
///
/// Oyuncu başvurduğunda oluşur ve cevap verilene kadar durumda kalır.
/// Kaydedildiği için uygulama kapatılıp açıldığında **aynı soru** geri
/// gelir; cevap ve işe kabul sonucu iki kez uygulanmaz.
@immutable
class PendingInterview {
  const PendingInterview({
    required this.jobId,
    required this.questionId,
    required this.askedAtAge,
  });

  final String jobId;
  final String questionId;

  /// Mülakatın açıldığı yaş.
  final int askedAtAge;

  JobType? get job => jobById(jobId);

  InterviewQuestion? get question => interviewQuestionById(questionId);
}
