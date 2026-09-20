/// Ehliyet sınavı soruları.
///
/// Her ehliyet türünün **ayrı** soru havuzu vardır; sorular basit trafik
/// bilgisi, güvenli sürüş ve araç kontrolü üzerinedir. Metinler özgündür,
/// gerçek bir sınav kitapçığından alınmamıştır ve resmî sürücü belgesi
/// bilgisi olarak sunulmaz (`docs/DESIGN_REVIEW_QUEUE.md`, Q-057).
library;

import 'package:flutter/foundation.dart';

import 'license_catalog.dart';

/// Tek doğru cevaplı bir sınav sorusu.
@immutable
class LicenseQuestion {
  const LicenseQuestion({
    required this.id,
    required this.licenseId,
    required this.text,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  final String id;

  /// Hangi ehliyetin sınavına ait ([LicenseType.id]).
  final String licenseId;

  final String text;

  /// Seçenekler; sıra sabittir, böylece kayıt geri yüklenince soru aynı
  /// görünür.
  final List<String> options;

  final int correctIndex;

  /// Yanlış cevaptan sonra gösterilen kısa açıklama.
  final String explanation;

  String get correctOption => options[correctIndex];
}

const List<LicenseQuestion> kLicenseQuestions = <LicenseQuestion>[
  // --- Motosiklet -------------------------------------------------------
  LicenseQuestion(
    id: 'moto_kask',
    licenseId: 'motosiklet_ehliyeti',
    text: 'Motosiklete binerken kask ne zaman takılır?',
    options: <String>[
      'Yalnızca uzun yolda',
      'Her sürüşte, kısa mesafede bile',
      'Yalnızca yağmurlu havada',
      'Yalnızca yolcu varken',
    ],
    correctIndex: 1,
    explanation: 'Kask her sürüşte takılır; kaza mesafeye bakmaz.',
  ),
  LicenseQuestion(
    id: 'moto_fren',
    licenseId: 'motosiklet_ehliyeti',
    text: 'Islak yolda motosikletle giderken en doğru davranış nedir?',
    options: <String>[
      'Hızı artırıp çabuk geçmek',
      'Yalnızca ön freni sert kullanmak',
      'Hızı düşürüp frene yumuşak basmak',
      'Viraja yatarak hızlı girmek',
    ],
    correctIndex: 2,
    explanation: 'Islak zeminde tutuş azalır; hız düşürülür, fren yumuşak '
        'kullanılır.',
  ),
  LicenseQuestion(
    id: 'moto_takip',
    licenseId: 'motosiklet_ehliyeti',
    text: 'Önündeki araca ne kadar yaklaşmalısın?',
    options: <String>[
      'Frene basınca durabileceğin kadar mesafe bırakırsın',
      'Tamponuna değecek kadar yakın durursun',
      'Şeridi paylaşıp yanında gidersin',
      'Görüşünü kapatacak kadar yaklaşırsın',
    ],
    correctIndex: 0,
    explanation: 'Takip mesafesi, ani durmada çarpmadan durabilecek kadar '
        'olmalıdır.',
  ),
  LicenseQuestion(
    id: 'moto_donus',
    licenseId: 'motosiklet_ehliyeti',
    text: 'Dönüş yapmadan önce ilk ne yaparsın?',
    options: <String>[
      'Korna çalarsın',
      'Sinyal verip aynaya bakarsın',
      'Gazı köklersin',
      'Farı söndürürsün',
    ],
    correctIndex: 1,
    explanation: 'Önce niyetini bildirir (sinyal), sonra çevreyi kontrol '
        'edersin.',
  ),
  LicenseQuestion(
    id: 'moto_lastik',
    licenseId: 'motosiklet_ehliyeti',
    text: 'Yola çıkmadan önceki kontrolde en gerekli olan nedir?',
    options: <String>[
      'Aynaların rengi',
      'Lastik basıncı ve fren kontrolü',
      'Deponun boyası',
      'Sele yüksekliği',
    ],
    correctIndex: 1,
    explanation: 'Lastik ve fren, yol güvenliğini doğrudan belirler.',
  ),

  // --- Otomobil ---------------------------------------------------------
  LicenseQuestion(
    id: 'oto_emniyet',
    licenseId: 'otomobil_ehliyeti',
    text: 'Emniyet kemeri kimler için gereklidir?',
    options: <String>[
      'Yalnızca sürücü için',
      'Yalnızca şehirler arası yolda',
      'Sürücü ve yolcular için, her yolculukta',
      'Yalnızca ön koltuktakiler için',
    ],
    correctIndex: 2,
    explanation: 'Kemer her koltukta ve her yolculukta takılır.',
  ),
  LicenseQuestion(
    id: 'oto_kavsak',
    licenseId: 'otomobil_ehliyeti',
    text: 'Işıklı kavşakta sarı ışık yandığında ne yaparsın?',
    options: <String>[
      'Güvenle durabilecek durumdaysan durursun',
      'Hızlanıp geçersin',
      'Kornaya basıp devam edersin',
      'Geri manevra yaparsın',
    ],
    correctIndex: 0,
    explanation: 'Sarı ışık "hazırlan ve dur" demektir; güvenli durulabiliyorsa '
        'durulur.',
  ),
  LicenseQuestion(
    id: 'oto_yaya',
    licenseId: 'otomobil_ehliyeti',
    text: 'Yaya geçidine yaklaşırken doğru davranış nedir?',
    options: <String>[
      'Yayayı korna ile uyarıp geçmek',
      'Hızı düşürüp geçmek isteyen yayaya yol vermek',
      'Geçidin üstünde durmak',
      'Şerit değiştirip hızlanmak',
    ],
    correctIndex: 1,
    explanation: 'Yaya geçidinde öncelik yayanındır.',
  ),
  LicenseQuestion(
    id: 'oto_mesafe',
    licenseId: 'otomobil_ehliyeti',
    text: 'Hız arttıkça takip mesafesi ne olur?',
    options: <String>[
      'Değişmez',
      'Kısalır',
      'Uzar',
      'Yalnızca gece uzar',
    ],
    correctIndex: 2,
    explanation: 'Hız arttıkça durma mesafesi uzar, bu yüzden takip mesafesi '
        'de uzar.',
  ),
  LicenseQuestion(
    id: 'oto_park',
    licenseId: 'otomobil_ehliyeti',
    text: 'Aracı park ettikten sonra ne yapılır?',
    options: <String>[
      'Motor çalışır bırakılır',
      'El freni çekilir ve motor durdurulur',
      'Vites boşta bırakılıp inilir',
      'Kapılar açık bırakılır',
    ],
    correctIndex: 1,
    explanation: 'Park edilen araçta el freni çekilir ve motor durdurulur.',
  ),
  LicenseQuestion(
    id: 'oto_lastik',
    licenseId: 'otomobil_ehliyeti',
    text: 'Gösterge panelinde motor yağı uyarısı yandığında ne yaparsın?',
    options: <String>[
      'Uyarıyı kapatıp yola devam edersin',
      'Güvenli bir yerde durup kontrol edersin',
      'Hızlanıp servise yetişmeye çalışırsın',
      'Klimayı kapatırsın',
    ],
    correctIndex: 1,
    explanation: 'Yağ uyarısında güvenli bir yerde durup kontrol etmek '
        'gerekir.',
  ),
];

/// Bir ehliyetin soru havuzu.
List<LicenseQuestion> questionsForLicense(String licenseId) => kLicenseQuestions
    .where((LicenseQuestion q) => q.licenseId == licenseId)
    .toList(growable: false);

LicenseQuestion? licenseQuestionById(String id) {
  for (final LicenseQuestion q in kLicenseQuestions) {
    if (q.id == id) return q;
  }
  return null;
}

/// prototypeOnly: sınav/başvuru bedelleri (₺, `lib/data/economy.dart`).
int prototypeOnlyExamFee(LicenseType type) {
  switch (type) {
    case LicenseType.motosiklet:
      return 4000;
    case LicenseType.otomobil:
      return 8000;
  }
}
