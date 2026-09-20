import 'package:flutter/foundation.dart';

import '../../data/license_catalog.dart';
import '../../data/license_questions.dart';

/// Cevap bekleyen ehliyet sınavı.
///
/// Kaydedilir: uygulama kapatılıp açıldığında **aynı soru ve aynı aşama**
/// geri gelir. Ücret başvuruda bir kez alınır ve [feePaid] içinde saklanır;
/// aynı başvuru için ikinci kez tahsil edilmez.
@immutable
class PendingLicenseExam {
  const PendingLicenseExam({
    required this.licenseId,
    required this.questionId,
    required this.askedAtAge,
    required this.feePaid,
  });

  final String licenseId;
  final String questionId;
  final int askedAtAge;

  /// Başvuruda ödenen bedel.
  final int feePaid;

  LicenseType? get license => licenseTypeById(licenseId);

  LicenseQuestion? get question => licenseQuestionById(questionId);
}
