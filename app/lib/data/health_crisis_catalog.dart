/// Hastalık ve kaza kaynaklı sağlık krizleri (D-036, D-044).
///
/// Metinler kısa, saygılı ve bağlama uygundur; ayrıntılı ya da rahatsız
/// edici tasvir kullanılmaz. Krizler **seyrektir** ve oyuncuyu sürekli
/// trajediyle cezalandırmaz. Sayısal değerler `prototypeOnly`'dir
/// (`docs/DESIGN_REVIEW_QUEUE.md`, Q-061).
library;

import 'package:flutter/foundation.dart';

/// Krizin kaynağı.
enum CrisisKind {
  hastalik('Hastalık'),
  kaza('Kaza');

  const CrisisKind(this.label);

  final String label;
}

/// Krize verilebilecek bir yanıt.
@immutable
class CrisisChoice {
  const CrisisChoice({
    required this.id,
    required this.label,
    required this.resultText,
    required this.cost,
    required this.survivalBonus,
    required this.healthChange,
    this.needsMoney = false,
  });

  final String id;
  final String label;

  /// Seçimden sonra gösterilen ve günlüğe yazılan metin (atlatıldığında).
  final String resultText;

  /// prototypeOnly: seçimin bedeli (₺).
  final int cost;

  /// prototypeOnly: hayatta kalma ihtimaline eklenen pay.
  final double survivalBonus;

  /// prototypeOnly: atlatıldığında sağlığa etkisi.
  final int healthChange;

  /// Bedeli ödenemiyorsa seçenek kapanır.
  final bool needsMoney;
}

/// Bir sağlık krizi.
@immutable
class HealthCrisis {
  const HealthCrisis({
    required this.id,
    required this.kind,
    required this.text,
    required this.minAge,
    required this.maxAge,
    required this.baseSurvival,
    required this.choices,
  });

  final String id;
  final CrisisKind kind;

  /// Ekranda gösterilen kısa metin.
  final String text;

  final int minAge;
  final int maxAge;

  /// prototypeOnly: hiçbir şey yapılmazsa atlatma ihtimali.
  final double baseSurvival;

  final List<CrisisChoice> choices;
}

const List<HealthCrisis> kHealthCrises = <HealthCrisis>[
  // --- Çocukluk ve gençlik ---------------------------------------------
  HealthCrisis(
    id: 'ates_hastalik',
    kind: CrisisKind.hastalik,
    text: 'Günlerdir geçmeyen yüksek ateşin var; halsizlik seni yatağa '
        'bağladı.',
    minAge: 3,
    maxAge: 40,
    baseSurvival: 0.95,
    choices: <CrisisChoice>[
      CrisisChoice(
        id: 'doktor',
        label: 'Doktora git',
        resultText: 'Doktor tedaviye başladı; birkaç hafta içinde '
            'toparlandın.',
        cost: 6000,
        survivalBonus: 0.07,
        healthChange: -4,
        needsMoney: true,
      ),
      CrisisChoice(
        id: 'dinlen',
        label: 'Dinlenerek atlatmayı dene',
        resultText: 'Uzun bir dinlenmenin ardından ateşin düştü.',
        cost: 0,
        survivalBonus: 0.02,
        healthChange: -8,
      ),
    ],
  ),
  HealthCrisis(
    id: 'trafik_kazasi',
    kind: CrisisKind.kaza,
    text: 'Yolda bir trafik kazası geçirdin; ilk kontrolde durumun ciddi '
        'görünüyor.',
    minAge: 16,
    maxAge: 75,
    baseSurvival: 0.9,
    choices: <CrisisChoice>[
      CrisisChoice(
        id: 'hastane',
        label: 'Hastanede tedavi ol',
        resultText: 'Tedavi işe yaradı; bir süre dinlenerek iyileştin.',
        cost: 25000,
        survivalBonus: 0.1,
        healthChange: -10,
        needsMoney: true,
      ),
      CrisisChoice(
        id: 'evde',
        label: 'Evde iyileşmeyi dene',
        resultText: 'Zorlu geçen haftaların ardından ayağa kalktın.',
        cost: 0,
        survivalBonus: 0.0,
        healthChange: -18,
      ),
    ],
  ),

  // --- Orta yaş ---------------------------------------------------------
  HealthCrisis(
    id: 'kalp_uyarisi',
    kind: CrisisKind.hastalik,
    text: 'Göğsünde sıkışma hissiyle uyandın; doktorlar kalbini yakından '
        'izlemek istiyor.',
    minAge: 40,
    maxAge: 95,
    baseSurvival: 0.8,
    choices: <CrisisChoice>[
      CrisisChoice(
        id: 'tedavi',
        label: 'Tedaviyi kabul et',
        resultText: 'Tedavi ve düzenli kontrollerle durumun toparlandı.',
        cost: 40000,
        survivalBonus: 0.12,
        healthChange: -8,
        needsMoney: true,
      ),
      CrisisChoice(
        id: 'ertele',
        label: 'Şimdilik ertele',
        resultText: 'Şikâyetin zamanla azaldı ama tedirginlik kaldı.',
        cost: 0,
        survivalBonus: -0.05,
        healthChange: -14,
      ),
    ],
  ),
  HealthCrisis(
    id: 'is_kazasi',
    kind: CrisisKind.kaza,
    text: 'İşte ciddi bir kaza geçirdin; hemen müdahale gerekiyor.',
    minAge: 18,
    maxAge: 65,
    baseSurvival: 0.87,
    choices: <CrisisChoice>[
      CrisisChoice(
        id: 'mudahale',
        label: 'Acil müdahaleyi kabul et',
        resultText: 'Müdahale zamanında yapıldı; yaraların iyileşti.',
        cost: 18000,
        survivalBonus: 0.09,
        healthChange: -9,
        needsMoney: true,
      ),
      CrisisChoice(
        id: 'idare',
        label: 'İdare etmeye çalış',
        resultText: 'Uzun süre ağrı çektin ama toparlandın.',
        cost: 0,
        survivalBonus: -0.02,
        healthChange: -16,
      ),
    ],
  ),

  // --- İleri yaş --------------------------------------------------------
  HealthCrisis(
    id: 'zatürre',
    kind: CrisisKind.hastalik,
    text: 'Geçmeyen öksürük zatürreye dönüştü; nefes almak zorlaşıyor.',
    minAge: 60,
    maxAge: 120,
    baseSurvival: 0.72,
    choices: <CrisisChoice>[
      CrisisChoice(
        id: 'hastane',
        label: 'Hastanede tedavi ol',
        resultText: 'Tedavi sonrası nefesin rahatladı.',
        cost: 22000,
        survivalBonus: 0.13,
        healthChange: -10,
        needsMoney: true,
      ),
      CrisisChoice(
        id: 'evde',
        label: 'Evde ilaçla idare et',
        resultText: 'İlaçlar yavaş da olsa işe yaradı.',
        cost: 3000,
        survivalBonus: 0.03,
        healthChange: -15,
        needsMoney: true,
      ),
    ],
  ),
  HealthCrisis(
    id: 'dusme',
    kind: CrisisKind.kaza,
    text: 'Evde düşüp kalçanı incittin; tek başına ayağa kalkamıyorsun.',
    minAge: 65,
    maxAge: 120,
    baseSurvival: 0.75,
    choices: <CrisisChoice>[
      CrisisChoice(
        id: 'ameliyat',
        label: 'Hastaneye git',
        resultText: 'Tedaviden sonra yeniden yürümeye başladın.',
        cost: 30000,
        survivalBonus: 0.12,
        healthChange: -12,
        needsMoney: true,
      ),
      CrisisChoice(
        id: 'yatak',
        label: 'Evde yatarak iyileşmeyi bekle',
        resultText: 'Uzun bir yatak istirahatinin ardından toparlandın.',
        cost: 0,
        survivalBonus: -0.04,
        healthChange: -20,
      ),
    ],
  ),
];

/// Yaşa uygun krizler.
List<HealthCrisis> crisesForAge(int age) => kHealthCrises
    .where((HealthCrisis c) => age >= c.minAge && age <= c.maxAge)
    .toList(growable: false);

HealthCrisis? healthCrisisById(String id) {
  for (final HealthCrisis c in kHealthCrises) {
    if (c.id == id) return c;
  }
  return null;
}
