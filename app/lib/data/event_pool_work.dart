/// İş hayatı olayları (Paket 9).
///
/// Hepsi yalnızca **gerçekten çalışan** oyuncuya çıkar. İki olay zinciri
/// önceki kararı hatırlar: iş arkadaşına yardım eden ile sorumluluktan
/// kaçan yıllar sonra farklı bir sahneyle karşılaşır. Metinler özgündür.
library;

import '../domain/career/career_progress.dart';
import '../domain/models/game_event.dart';
import '../domain/models/relation.dart';

/// İş hayatı hikâye izleri.
abstract final class WorkFlags {
  static const String isArkadasinaYardim = 'is_arkadasina_yardim';
  static const String isArkadasiniYalniz = 'is_arkadasini_yalniz_birakti';
  static const String zorMusteriSakin = 'zor_musteri_sakin';
  static const String zorMusteriSert = 'zor_musteri_sert';
  static const String isTeklifiReddetti = 'is_teklifi_reddetti';
}

const List<GameEvent> kWorkEvents = <GameEvent>[
  // 1 — İş arkadaşına yardım (zincirin başı)
  GameEvent(
    id: 'is_arkadasina_yardim',
    category: EventCategory.yetiskinlik,
    text: '{kisi} bugün yetişemeyeceği bir işin altında kalmış. Kimseye bir '
        'şey söylemiyor ama masasındaki yığın büyüyor.',
    requirement: EventRequirement(
      minAge: 16,
      requiresEmployed: true,
      livingRelations: <RelationType>{RelationType.isArkadasi},
      requireReachable: true,
    ),
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'yardim',
        label: 'Kendi işini bırakıp yardım et',
        resultText: 'Akşam ikiniz de geç çıktınız. {kisi} çıkarken '
            '"bunu unutmam" dedi, sen omuz silktin.',
        happiness: 3,
        bond: 12,
        addFlags: <String>{
          WorkFlags.isArkadasinaYardim,
          CareerProgress.flagSorumlulukAldi,
        },
        rememberPersonAs: 'is_arkadasi_yardim',
      ),
      EventChoice(
        id: 'kendi_isin',
        label: 'Kendi işine bak',
        resultText: 'Başını kaldırmadan çalıştın. {kisi} o akşam yalnız '
            'kaldı; ertesi gün selamı kısa sürdü.',
        bond: -6,
        addFlags: <String>{WorkFlags.isArkadasiniYalniz},
      ),
    ],
  ),

  // 2 — Yıllar sonra aynı kişi (zincirin devamı: yardım edilmişti)
  GameEvent(
    id: 'is_arkadasi_karsilik',
    category: EventCategory.yetiskinlik,
    text: 'Yıllar önce yardım ettiğin {kisi} şimdi senin için bir iyilik '
        'yapabilecek yerde. Kimsenin duymayacağı bir anda soruyor: '
        '"Bir şeye ihtiyacın var mı?"',
    requirement: EventRequirement(
      minAge: 20,
      requiredFlags: <String>{WorkFlags.isArkadasinaYardim},
      personRole: 'is_arkadasi_yardim',
    ),
    repeatable: true,
    minAgeGap: 12,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'destek_iste',
        label: 'Yöneticiye senden söz etmesini iste',
        resultText: '{kisi} sözünü tuttu. Toplantıda adın geçti; bu kadarı '
            'bile insanın sırtını dikleştiriyor.',
        happiness: 5,
        charisma: 2,
        addFlags: <String>{CareerProgress.flagSorumlulukAldi},
      ),
      EventChoice(
        id: 'gerek_yok',
        label: '"Gerek yok, kendi işim kendi işim"',
        resultText: 'Gülüp geçtin. {kisi} ısrar etmedi ama teklifin '
            'kendisi bile iyi geldi.',
        happiness: 3,
        bond: 4,
      ),
    ],
  ),

  // 3 — Zor müşteri (zincirin başı)
  GameEvent(
    id: 'zor_musteri',
    category: EventCategory.yetiskinlik,
    text: 'Karşındaki kişi sesini yükseltti. Ortalık sessizleşti; herkes '
        'ne yapacağına bakıyor.',
    requirement: EventRequirement(
      minAge: 16,
      requiresEmployed: true,
    ),
    repeatable: true,
    minAgeGap: 6,
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'sakin',
        label: 'Sesini yükseltmeden çöz',
        resultText: 'Adam sonunda sustu, sen de kendi sesini hiç '
            'yükseltmedin. Yan masadan biri başparmağını kaldırdı.',
        happiness: 2,
        charisma: 3,
        addFlags: <String>{WorkFlags.zorMusteriSakin},
      ),
      EventChoice(
        id: 'sert',
        label: 'Sert karşılık ver',
        resultText: 'Tartışma büyüdü. Haklıydın ama akşam eve giderken '
            'hâlâ elin titriyordu.',
        happiness: -3,
        addFlags: <String>{WorkFlags.zorMusteriSert},
      ),
      EventChoice(
        id: 'cagir',
        label: 'Yöneticiyi çağır',
        resultText: 'Sorunu devrettin. Çözüldü; yine de "ben halledemedim" '
            'duygusu bir süre kaldı.',
        happiness: -1,
      ),
    ],
  ),

  // 4 — Yıllar sonra hatırlanan sakinlik (zincirin devamı)
  GameEvent(
    id: 'sakinligin_hatirlandi',
    category: EventCategory.yetiskinlik,
    text: 'Yeni gelen biri sana bakıp soruyor: "Sinirlenen birine nasıl '
        'davranıyorsun?" Yıllar önceki o günü hatırlıyorsun.',
    requirement: EventRequirement(
      minAge: 24,
      requiresEmployed: true,
      requiredFlags: <String>{WorkFlags.zorMusteriSakin},
    ),
    repeatable: true,
    minAgeGap: 10,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'anlat',
        label: 'Öğrendiğini anlat',
        resultText: 'Anlattın. Bir şeyi anlatabiliyor olmak, onu gerçekten '
            'öğrendiğini gösteriyor.',
        happiness: 4,
        charisma: 2,
        addFlags: <String>{CareerProgress.flagSorumlulukAldi},
      ),
      EventChoice(
        id: 'kisa',
        label: '"Alışırsın" deyip geç',
        resultText: 'Kısa kestin. Soruyu soran biraz bekleyip masasına '
            'döndü.',
        happiness: -1,
      ),
    ],
  ),

  // 5 — Sorumluluk almak
  GameEvent(
    id: 'iste_sorumluluk',
    category: EventCategory.yetiskinlik,
    text: 'Kimsenin istemediği bir iş masaya kondu: zor, görünmeyen ve '
        'uzun. "Gönüllü var mı?" diye soruldu.',
    requirement: EventRequirement(
      minAge: 17,
      requiresEmployed: true,
      requiresMinYearsInJob: 1,
    ),
    repeatable: true,
    minAgeGap: 5,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'ustlen',
        label: 'Üstlen',
        resultText: 'Aylar sürdü. Bitince kimse alkışlamadı ama senin '
            'adın o işle birlikte anılmaya başladı.',
        happiness: 2,
        intelligence: 2,
        addFlags: <String>{CareerProgress.flagSorumlulukAldi},
        removeFlags: <String>{CareerProgress.flagIsiSavsakladi},
      ),
      EventChoice(
        id: 'sessiz',
        label: 'Sessiz kal',
        resultText: 'Başını eğdin, iş başkasına gitti. Rahat bir yıl '
            'geçirdin.',
        happiness: 2,
      ),
    ],
  ),

  // 6 — İşi savsaklamak
  GameEvent(
    id: 'iste_savsaklama',
    category: EventCategory.yetiskinlik,
    text: 'Teslim günü geldi ve iş yarım. Kimse henüz fark etmedi.',
    requirement: EventRequirement(
      minAge: 17,
      requiresEmployed: true,
      requiresMinYearsInJob: 1,
    ),
    repeatable: true,
    minAgeGap: 6,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'soyle',
        label: 'Açıkça söyle, ek süre iste',
        resultText: 'Söyledin. Hoş karşılanmadı ama "haber vermen iyi '
            'oldu" dediler.',
        happiness: -1,
        charisma: 2,
        removeFlags: <String>{CareerProgress.flagIsiSavsakladi},
      ),
      EventChoice(
        id: 'gizle',
        label: 'Bitmiş gibi göster',
        resultText: 'O gün kurtardın. Eksik, birkaç hafta sonra başkasının '
            'masasında patladı.',
        happiness: -2,
        addFlags: <String>{CareerProgress.flagIsiSavsakladi},
      ),
    ],
  ),

  // 7 — Zam görüşmesi (karşı taraftan gelen)
  GameEvent(
    id: 'zam_gorusmesi',
    category: EventCategory.yetiskinlik,
    text: 'Yöneticin kapıyı kapatıp oturdu: "Yılsonu değerlendirmesi. '
        'Sen ne düşünüyorsun?"',
    requirement: EventRequirement(
      minAge: 18,
      requiresEmployed: true,
      requiresMinYearsInJob: 2,
    ),
    repeatable: true,
    minAgeGap: 7,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'rakam_soyle',
        label: 'Beklediğin rakamı söyle',
        resultText: 'Rakamı duyunca kaşını kaldırdı, sonra not aldı. '
            '"Bakacağız" dedi — bu kez gerçekten bakacak gibiydi.',
        happiness: 2,
        charisma: 2,
        money: 12000,
      ),
      EventChoice(
        id: 'size_birakiyorum',
        label: '"Uygun gördüğünüz gibi"',
        resultText: 'Konu kapandı. Kendi payına düşeni istemediğin bir '
            'toplantıydı.',
        happiness: -2,
      ),
    ],
  ),

  // 8 — Başka iş teklifi
  GameEvent(
    id: 'baska_is_teklifi',
    category: EventCategory.yetiskinlik,
    text: 'Tanımadığın biri arıyor: başka bir yerde senin yaptığın işe '
        'benzer bir kadro açılmış. "Bir konuşalım" diyor.',
    requirement: EventRequirement(
      minAge: 20,
      requiresEmployed: true,
      requiresMinYearsInJob: 2,
    ),
    repeatable: true,
    minAgeGap: 8,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'dinle',
        label: 'En azından dinle',
        resultText: 'Dinledin. Gitmedin ama kendi işinin değerini bir '
            'kere daha ölçmüş oldun.',
        happiness: 2,
        charisma: 1,
      ),
      EventChoice(
        id: 'kapat',
        label: 'Teşekkür edip kapat',
        resultText: 'Kısa kestin. Bulunduğun yerde kalmak da bir karar.',
        happiness: 1,
        addFlags: <String>{WorkFlags.isTeklifiReddetti},
      ),
    ],
  ),
];
