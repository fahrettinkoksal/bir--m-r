/// İleri yaş olayları (Paket 12).
///
/// Emeklilik, torunlar ve yaşlılığın gündelik hâlleri. Hiçbiri yaşlılığı
/// yalnızca kayıp olarak anlatmaz: bu yaşın kendi sevinçleri, alışkanlıkları
/// ve kararları var.
library;

import '../domain/career/retirement.dart';
import '../domain/models/game_event.dart';
import '../domain/models/relation.dart';

/// İleri yaş hikâye izleri.
abstract final class ElderFlags {
  static const String emeklilikRutini = 'emeklilik_rutini';
  static const String torunlaVakit = 'torunla_vakit';
  static const String eskiIsYeri = 'eski_is_yerine_ugradi';
}

const List<GameEvent> kElderEvents = <GameEvent>[
  // 1 — Emekliliğin ilk sabahı
  GameEvent(
    id: 'emeklilik_ilk_sabah',
    category: EventCategory.yetiskinlik,
    text: 'Alarm kurmadığın ilk sabah. Uyandın ve hiçbir yere '
        'yetişmen gerekmediğini fark ettin.',
    requirement: EventRequirement(
      minAge: Retirement.prototypeOnlyEarlyAge,
      requiresRetired: true,
    ),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'rutin_kur',
        label: 'Kendine yeni bir düzen kur',
        resultText: 'Sabah yürüyüşü, öğleden sonra bahçe. Düzen insanı '
            'ayakta tutuyor.',
        happiness: 5,
        health: 2,
        addFlags: <String>{ElderFlags.emeklilikRutini},
      ),
      EventChoice(
        id: 'akisina_birak',
        label: 'Akışına bırak',
        resultText: 'Günler birbirine karıştı. Bazıları çok uzun, bazıları '
            'hiç yaşanmamış gibi geçti.',
        happiness: 1,
      ),
    ],
  ),

  // 2 — Eski iş yeri
  GameEvent(
    id: 'eski_is_yeri',
    category: EventCategory.yetiskinlik,
    text: 'Yolun eski iş yerinin önünden geçiyor. İçeride tanımadığın '
        'insanlar çalışıyor.',
    requirement: EventRequirement(
      minAge: Retirement.prototypeOnlyEarlyAge,
      requiresRetired: true,
    ),
    repeatable: true,
    minAgeGap: 7,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'ugra',
        label: 'Uğra, bir çay iç',
        resultText: 'Seni hatırlayan iki kişi kalmış. Çay içtiniz; '
            '"burası sensiz farklı" dediler, inanmadın ama iyi geldi.',
        happiness: 4,
        addFlags: <String>{ElderFlags.eskiIsYeri},
      ),
      EventChoice(
        id: 'gecip_git',
        label: 'Geçip git',
        resultText: 'Durmadın. Bazı kapılar bir kez kapanır ve bu kötü bir '
            'şey değildir.',
        happiness: 2,
      ),
    ],
  ),

  // 3 — Torunla vakit
  GameEvent(
    id: 'torunla_gun',
    category: EventCategory.aile,
    text: '{kisi} bugün sana bırakıldı. Bütün gün senin yanında.',
    requirement: EventRequirement(
      minAge: 45,
      livingRelations: <RelationType>{RelationType.torun},
      personMaxAge: 12,
    ),
    repeatable: true,
    minAgeGap: 3,
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'oyun',
        label: 'Bütün gün oyun oyna',
        resultText: 'Dizlerin ağrıdı ama {kisi} akşam giderken sarıldı. '
            'Ağrıya değdi.',
        happiness: 7,
        health: -1,
        bond: 10,
        addFlags: <String>{ElderFlags.torunlaVakit},
      ),
      EventChoice(
        id: 'anlat',
        label: 'Eski hikâyeler anlat',
        resultText: '{kisi} bazılarını anlamadı, bazılarını iki kere '
            'dinlemek istedi. Anlatmak da bir tür miras.',
        happiness: 6,
        bond: 8,
      ),
    ],
  ),

  // 4 — Torunun büyümesi
  GameEvent(
    id: 'torun_buyudu',
    category: EventCategory.aile,
    text: '{kisi} geçen sefer gördüğünden bir baş uzamış. Sana bir şey '
        'anlatmak için sabırsız.',
    requirement: EventRequirement(
      minAge: 50,
      livingRelations: <RelationType>{RelationType.torun},
      personMinAge: 13,
    ),
    repeatable: true,
    minAgeGap: 5,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'dinle',
        label: 'Sonuna kadar dinle',
        resultText: 'Yarısını anlamadın ama {kisi} anlatırken gözlerinin '
            'parladığını gördün.',
        happiness: 5,
        bond: 8,
      ),
      EventChoice(
        id: 'ogut',
        label: 'Bir öğüt ver',
        resultText: 'Verdiğin öğüt tutulur mu bilinmez. Sana da bir zamanlar '
            'aynısını söylemişlerdi.',
        happiness: 3,
        bond: 3,
      ),
    ],
  ),

  // 5 — Sağlık kontrolü
  GameEvent(
    id: 'ileri_yas_kontrol',
    category: EventCategory.kisisel,
    text: 'Yıllık kontrol zamanı. Gitmek zorunda değilsin ama randevu '
        'duruyor.',
    requirement: EventRequirement(minAge: 55),
    repeatable: true,
    minAgeGap: 5,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'git',
        label: 'Randevuya git',
        resultText: 'Birkaç tahlil, birkaç öneri. Ciddi bir şey çıkmadı; '
            'yine de bilmek rahatlattı.',
        happiness: 3,
        health: 4,
        money: -2500,
      ),
      EventChoice(
        id: 'erteleme',
        label: 'Ertele',
        resultText: 'Ertelendi. Bir şey olmadı — bu sefer.',
        happiness: 1,
        health: -2,
      ),
    ],
  ),

  // 6 — Mahalle ve alışkanlıklar
  GameEvent(
    id: 'ileri_yas_mahalle',
    category: EventCategory.mahalle,
    text: 'Parkta her sabah aynı saatte oturan birkaç kişi var. Bugün '
        'sana yer açtılar.',
    requirement: EventRequirement(minAge: 60),
    repeatable: true,
    minAgeGap: 6,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'otur',
        label: 'Otur, tanış',
        resultText: 'Adlarını ikinci günde öğrendin. Artık senin de bir '
            'sabah düzenin var.',
        happiness: 5,
        charisma: 2,
        startsFriendship: true,
      ),
      EventChoice(
        id: 'yurumeye_devam',
        label: 'Yürümeye devam et',
        resultText: 'Selam verip geçtin. Yalnız yürümek de bir tercih.',
        happiness: 2,
        health: 1,
      ),
    ],
  ),

  // 7 — Geçmişe bakış
  GameEvent(
    id: 'ileri_yas_muhasebe',
    category: EventCategory.kisisel,
    text: 'Akşam sessizliğinde aklından bütün bir ömür geçti: yaptıkların, '
        'yapmadıkların.',
    requirement: EventRequirement(minAge: 65),
    repeatable: true,
    minAgeGap: 8,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'yaz',
        label: 'Bir şeyler yaz',
        resultText: 'Birkaç sayfa yazdın. Kimse okumayacak olsa bile '
            'yazılmış olması bir şey değiştirdi.',
        happiness: 5,
        intelligence: 1,
      ),
      EventChoice(
        id: 'ara',
        label: 'Birini ara',
        resultText: 'Uzun zamandır aramadığın birini aradın. Konuşma kısa '
            'sürdü ama ikiniz de sevindiniz.',
        happiness: 6,
      ),
    ],
  ),

  // 8 — Emeklilikte çalışma isteği
  GameEvent(
    id: 'emeklilikte_ugras',
    category: EventCategory.yetiskinlik,
    text: 'Bir tanıdık, bildiğin işten küçük bir yardım istedi. Para '
        'değil, sadece birkaç gün.',
    requirement: EventRequirement(
      minAge: Retirement.prototypeOnlyEarlyAge,
      requiresRetired: true,
      requiredFlags: <String>{ElderFlags.emeklilikRutini},
    ),
    repeatable: true,
    minAgeGap: 6,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'yardim_et',
        label: 'Yardım et',
        resultText: 'Elinin hâlâ o işi bildiğini görmek iyi geldi. '
            'Karşılığında ısrarla bir zarf bıraktılar.',
        happiness: 5,
        money: 6000,
      ),
      EventChoice(
        id: 'artik_yok',
        label: '"Ben o defteri kapattım"',
        resultText: 'Nazikçe reddettin. Kapattığın defteri açmamak da bir '
            'olgunluk.',
        happiness: 3,
      ),
    ],
  ),
];
