/// İlk yılların olayları: 0-4 yaş (Paket 13).
///
/// **Not:** ilk adım, ilk kelime, aşı günü, komşu ziyareti ve ilk oyuncak
/// paylaşımı `event_pool_stages.dart` içinde zaten vardı. Bu dosya onları
/// tekrar yazmaz; ilk yılların **eksik kalan** anlarını ekler.
///
/// Bu yaşlarda kararları çoğunlukla aile verir; oyun da bunu böyle
/// anlatır. Seçimler bebeğin bilinçli tercihi gibi sunulmaz. Hiçbiri
/// tıbbi tavsiye değildir.
library;

import '../domain/models/game_event.dart';
import '../domain/models/relation.dart';

/// Bebeklik hikâye izleri.
abstract final class InfancyFlags {
  static const String uykusuzGeceler = 'bebeklik_uykusuz_geceler';
  static const String atesliGece = 'bebeklik_atesli_gece';
  static const String ilkAyrilik = 'bebeklik_ilk_ayrilik';
  static const String merakli = 'bebeklik_merakli';
}

const List<GameEvent> kInfancyEvents = <GameEvent>[
  // 0-2 yaş — uykusuz geceler
  GameEvent(
    id: 'bebek_uyku_duzeni',
    category: EventCategory.aile,
    text: 'Gecenin ortasında uyandın. Evde ışıklar tek tek yanıyor, '
        'ayak sesleri koridorda gidip geliyor.',
    requirement: EventRequirement(
      minAge: 0,
      maxAge: 2,
      livingRelations: <RelationType>{RelationType.anne, RelationType.baba},
      requireSameHousehold: true,
    ),
    repeatable: true,
    minAgeGap: 2,
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'ninni',
        label: 'Ninniyle uyu',
        resultText: '{sahip} aynı ninniyi üçüncü kez söylerken uyudun. '
            'Sabaha kadar bir daha uyanmadın.',
        happiness: 3,
        health: 2,
        bond: 4,
      ),
      EventChoice(
        id: 'sabaha_kadar',
        label: 'Sabaha kadar uyuma',
        resultText: 'Ev halkı sırayla seni gezdirdi. Sabah kimse '
            'dinlenmiş değildi ama kimse kızmadı.',
        happiness: 1,
        health: -1,
        addFlags: <String>{InfancyFlags.uykusuzGeceler},
      ),
    ],
  ),

  // 0-3 yaş — ateşli gece
  GameEvent(
    id: 'bebek_atesli_gece',
    category: EventCategory.aile,
    text: 'Ateşin çıktı. Alnına konan el, termometre, telaşlı bir telefon '
        'görüşmesi… Gece uzun geçiyor.',
    requirement: EventRequirement(
      minAge: 0,
      maxAge: 3,
      livingRelations: <RelationType>{RelationType.anne, RelationType.baba},
      requireSameHousehold: true,
    ),
    repeatable: true,
    minAgeGap: 3,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'hastane',
        label: 'Gece hastaneye gidildi',
        resultText: 'Nöbetçi doktor "geçer" dedi ve geçti. Dönüş yolunda '
            'arabada uyuyakaldın.',
        happiness: -1,
        health: 3,
        bond: 5,
        money: -1500,
        addFlags: <String>{InfancyFlags.atesliGece},
      ),
      EventChoice(
        id: 'evde',
        label: 'Sabaha kadar başında beklendi',
        resultText: 'Islak bez, sık sık ölçülen ateş ve hiç kapanmayan bir '
            'göz. Sabaha ateşin düşmüştü.',
        health: 1,
        bond: 6,
        addFlags: <String>{InfancyFlags.atesliGece},
      ),
    ],
  ),

  // 2-4 yaş — ilk ayrılık
  GameEvent(
    id: 'bebek_ilk_ayrilik',
    category: EventCategory.aile,
    text: 'Bugün birkaç saatliğine başkasına bırakılacaksın. Kapıda elin '
        'bırakılmak istemiyor.',
    requirement: EventRequirement(
      minAge: 2,
      maxAge: 4,
      livingRelations: <RelationType>{RelationType.anne, RelationType.baba},
    ),
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'agladi',
        label: 'Kapıda ağladın',
        resultText: 'Kapı kapandıktan beş dakika sonra oyuna daldın. '
            '{sahip} ise yolda bir daha arkasına baktı.',
        happiness: 1,
        bond: 3,
        addFlags: <String>{InfancyFlags.ilkAyrilik},
      ),
      EventChoice(
        id: 'el_salladi',
        label: 'El sallayıp içeri koştun',
        resultText: 'Hiç zorlanmadan girdin. Akşam anlatacak o kadar çok '
            'şeyin vardı ki, kimse laf araya giremedi.',
        happiness: 4,
        charisma: 2,
        addFlags: <String>{InfancyFlags.ilkAyrilik},
      ),
    ],
  ),

  // 3-5 yaş — "neden" soruları
  GameEvent(
    id: 'neden_sorulari',
    category: EventCategory.aile,
    text: 'Yeni bir kelime keşfettin: "neden?" Günde yüz kere soruyorsun '
        've cevaplar hiç yetmiyor.',
    requirement: EventRequirement(
      minAge: 3,
      maxAge: 5,
      livingRelations: <RelationType>{RelationType.anne, RelationType.baba},
    ),
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'sormaya_devam',
        label: 'Sormaya devam et',
        resultText: '{sahip} bazılarına cevap veremedi ve "bilmiyorum, '
            'birlikte öğrenelim" dedi. Bu cümle aklında kaldı.',
        happiness: 3,
        intelligence: 3,
        addFlags: <String>{InfancyFlags.merakli},
      ),
      EventChoice(
        id: 'kendi_bul',
        label: 'Kendin karıştırmaya başla',
        resultText: 'Dolapları, çekmeceleri, kutuları açtın. Bazı sorular '
            'cevabını kendi buldu, bazı vazolar kırıldı.',
        happiness: 2,
        intelligence: 2,
        addFlags: <String>{InfancyFlags.merakli},
      ),
    ],
  ),

  // 1-3 yaş — ilk doğum günü
  GameEvent(
    id: 'ilk_dogum_gunu',
    category: EventCategory.aile,
    text: 'Masada tek mumlu bir pasta var. Herkes fotoğraf çekmeye hazır, '
        'sen pastaya bakıyorsun.',
    requirement: EventRequirement(
      minAge: 1,
      maxAge: 3,
      livingRelations: <RelationType>{RelationType.anne, RelationType.baba},
      requireSameHousehold: true,
    ),
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'pastaya_daldin',
        label: 'Elini pastaya daldır',
        resultText: 'Fotoğrafların en iyisi o an çekildi: iki yanağın da '
            'krema. Çerçeveletildi.',
        happiness: 5,
        bond: 4,
      ),
      EventChoice(
        id: 'korktun',
        label: 'Mumdan korkup ağla',
        resultText: 'Mum söndürüldü, ışıklar açıldı. Ağlaman geçtiğinde '
            'pasta çoktan kesilmişti.',
        happiness: 2,
        bond: 2,
      ),
    ],
  ),

  // 2-4 yaş — yıllar sonra hatırlanan bebeklik hikâyesi
  GameEvent(
    id: 'bebeklik_hikayesi',
    category: EventCategory.aile,
    text: '{sahip} yine bebekliğine dair o hikâyeyi anlatıyor. Anlatırken '
        'hâlâ gülüyor, sen yüzüncü kez dinliyorsun.',
    requirement: EventRequirement(
      minAge: 12,
      requiredFlags: <String>{InfancyFlags.merakli},
      livingRelations: <RelationType>{RelationType.anne, RelationType.baba},
    ),
    repeatable: true,
    minAgeGap: 12,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'dinle',
        label: 'Sonuna kadar dinle',
        resultText: 'Ezbere bildiğin hikâyeyi yine dinledin. Anlatanın '
            'sesi, hikâyeden daha önemliydi.',
        happiness: 4,
        bond: 6,
      ),
      EventChoice(
        id: 'yeter',
        label: '"Tamam, yeter"',
        resultText: 'Konuyu kapattın. Sonra bir ara, kimse yokken kendi '
            'kendine gülümsedin.',
        happiness: 2,
      ),
    ],
  ),
];
