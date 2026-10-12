/// Bebeklik olayları: 0-3 yaş (Paket CX).
///
/// Bu dosya `event_pool_infancy.dart`'ın (Paket 13) **devamıdır**, onun
/// yerine geçmez: oradaki altı olay oyunun en eski içeriğidir ve her
/// zaman açıktır. Buradaki on altı olay `FeatureId.ilkYillarOlaylari`
/// anahtarına bağlıdır — anahtar kapalıyken ilk yıllar Paket BM ve
/// Paket CX öncesi gibi geçer. Modülü tamamen silme tarifi:
/// `docs/FEATURE_FLAGS.md`.
library;

import '../domain/models/game_event.dart';
import '../domain/models/relation.dart';

/// Bebekliğin bıraktığı, yıllar sonra okunan izler.
abstract final class BabyhoodFlags {
  /// Doğum hediyesi altın bozdurulmayıp saklandı.
  static const String altinSaklandi = 'bebeklik_altin_saklandi';

  /// Bırakmadığı bir oyuncak/battaniye oldu.
  static const String vazgecmedigiOyuncak = 'bebeklik_vazgecmedigi_oyuncak';
}

// =====================================================================
// Paket CX — ilk iki yılın ölçülmüş yoksulluğu
// =====================================================================
//
// **Ölçüm (60 bot hayatı, `EventEngine.debugEligibleIds`).** O yıl
// oyuncunun gerçekten karşılaşabileceği **tekil** aday olay sayısı:
//
// | yaş | aday ortalama | tekil aday |
// |---|---|---|
// | 0 | 8,6 | **9** |
// | 1 | 14,4 | 16 |
// | 2 | 17,2 | 20 |
// | 6 | 30,6 | 39 |
// | 12 | 52,4 | **92** |
//
// Yani ilk yıl, on ikinci yıldan **on kat** yoksuldu — ve oyuncunun
// oyunla ilk teması o yıl. `docs/EKSIKLER.md` §4.1 bunu "hâlâ en
// zayıf bant 0-5" diye not etmişti; sayı buydu.
//
// Kurallar (dosyanın başındaki nottan devam):
// - Bu yaşta kararları **aile** verir; seçim bebeğin bilinçli
//   tercihi gibi sunulmaz.
// - Yeni mekanik yok: var olan ilişki, para ve iz sistemine bağlanır.
// - Din, siyaset, gerçek marka ve tıbbi tavsiye geçmez
//   (`docs/WRITING_STYLE_TR.md`).
// - Bırakılan iki iz dosyanın sonunda **okunur**.
const List<GameEvent> kBabyhoodEvents = <GameEvent>[
  GameEvent(
    id: 'bebek_altin_hediyesi',
    category: EventCategory.aile,
    text: 'Kapı çaldı, kalabalık girdi. Yastığının yanına küçük bir '
        'kutu bırakıldı.',
    requirement: EventRequirement(
      minAge: 0,
      maxAge: 1,
      livingRelations: <RelationType>{RelationType.anne, RelationType.baba},
      requireSameHousehold: true,
    ),
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'saklandi',
        label: 'Kaldırılsın, dursun',
        resultText: 'Kutu çekmeceye girdi. Yıllarca orada duracak.',
        happiness: 2,
        addFlags: <String>{BabyhoodFlags.altinSaklandi},
      ),
      EventChoice(
        id: 'bozduruldu',
        label: 'İhtiyaç var, bozdurulsun',
        resultText: 'Bozduruldu. Ayın sonu bu kez rahat geçti.',
        happiness: 1,
        money: 4200,
      ),
    ],
  ),
  GameEvent(
    id: 'bebek_kime_benzemis',
    category: EventCategory.aile,
    text: 'Odadaki herkes aynı tartışmada: kime benzemişsin. Kimse '
        'anlaşamıyor.',
    requirement: EventRequirement(
      minAge: 0,
      maxAge: 2,
      livingRelations: <RelationType>{RelationType.anne, RelationType.baba},
      requireSameHousehold: true,
    ),
    repeatable: true,
    minAgeGap: 2,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'guldu',
        label: 'Tartışmanın ortasında gül',
        resultText: 'Güldün. Tartışma bitti, herkes sana baktı.',
        happiness: 5,
        bond: 4,
      ),
      EventChoice(
        id: 'agladi',
        label: 'Kalabalıktan rahatsız ol',
        resultText: 'Ağlamaya başladın. Oda bir anda boşaldı.',
        happiness: -1,
      ),
    ],
  ),
  GameEvent(
    id: 'bebek_ilk_banyo',
    category: EventCategory.aile,
    text: 'Leğen dolduruldu, su dirsekle denendi, üç kişi başına '
        'toplandı.',
    requirement: EventRequirement(
      minAge: 0,
      maxAge: 1,
      livingRelations: <RelationType>{RelationType.anne, RelationType.baba},
      requireSameHousehold: true,
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'sevdi',
        label: 'Suyu sev',
        resultText: 'Suya vurdun, her yer ıslandı. Kimse kızmadı.',
        happiness: 5,
        health: 1,
      ),
      EventChoice(
        id: 'korktu',
        label: 'Korkup bağır',
        resultText: 'Banyo iki dakikada bitti. Bir dahaki sefere daha '
            'az su kondu.',
        happiness: -2,
      ),
    ],
  ),
  GameEvent(
    id: 'bebek_besik_montaji',
    category: EventCategory.aile,
    text: 'Yerde parçalar, bir kâğıt tarif ve kaybolan bir vida var. '
        'Beşik akşama kadar kurulmadı.',
    requirement: EventRequirement(
      minAge: 0,
      maxAge: 1,
      livingRelations: <RelationType>{RelationType.baba},
      requireSameHousehold: true,
    ),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'komsu',
        label: 'Komşu yardıma gelsin',
        resultText: 'Komşu bir tornavidayla geldi, yarım saatte bitti. '
            'Çay içildi.',
        happiness: 3,
        bond: 3,
      ),
      EventChoice(
        id: 'kendi',
        label: 'Kendisi bitirsin',
        resultText: 'Gece yarısı bitti. Vida hâlâ eksik ama beşik '
            'sağlam.',
        happiness: 2,
      ),
    ],
  ),
  GameEvent(
    id: 'bebek_nufusa_yazdirma',
    category: EventCategory.aile,
    text: 'Sıra bekleniyor, evrak eksik çıkıyor, bir kez daha gidiliyor. '
        'Adın resmen yazıldı.',
    requirement: EventRequirement(
      minAge: 0,
      maxAge: 1,
      livingRelations: <RelationType>{RelationType.anne, RelationType.baba},
      requireSameHousehold: true,
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'tamam',
        label: 'İşlem tamam',
        resultText: 'Kâğıt üstünde artık varsın. Eve dönüşte pastane '
            'durağı yapıldı.',
        happiness: 3,
        money: -250,
      ),
      EventChoice(
        id: 'ikinci_ad',
        label: 'İkinci bir ad da eklensin',
        resultText: 'Dedenin adı ikinci ad olarak yazıldı. Kimse sana '
            'o adla seslenmeyecek ama orada duruyor.',
        happiness: 4,
        money: -250,
      ),
    ],
  ),
  GameEvent(
    id: 'bebek_buyukanne_cekismesi',
    category: EventCategory.aile,
    text: 'Kucaktan kucağa dolaştırıldın. Sıranın kimde olduğu konusunda '
        'sessiz bir çekişme var.',
    requirement: EventRequirement(
      minAge: 0,
      maxAge: 2,
      livingRelations: <RelationType>{
        RelationType.anneanne,
        RelationType.babaanne,
      },
    ),
    repeatable: true,
    minAgeGap: 2,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'ilk',
        label: 'Uzanan ilk kucağa git',
        resultText: 'İlk uzanan kucağa gittin. Kısa bir sessizlik oldu, '
            'sonra gülüştüler.',
        happiness: 4,
        bond: 4,
      ),
      EventChoice(
        id: 'huysuz',
        label: 'Hiçbirinde durma',
        resultText: 'Hiçbir kucakta duramadın; gün huysuzlukla geçti.',
        happiness: -1,
      ),
    ],
  ),
  GameEvent(
    id: 'bebek_kalin_giydirme',
    category: EventCategory.aile,
    text: 'Üç kat giydirildin. Dışarıda beş dakika geçmeden sırtın '
        'sırılsıklam oldu.',
    requirement: EventRequirement(
      minAge: 0,
      maxAge: 2,
      livingRelations: <RelationType>{RelationType.anne, RelationType.baba},
      requireSameHousehold: true,
    ),
    repeatable: true,
    minAgeGap: 2,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'cikardi',
        label: 'Bir kat çıkarılsın',
        resultText: 'Bir kat çıktı. Yolun kalanı daha rahat geçti.',
        happiness: 3,
        health: 1,
      ),
      EventChoice(
        id: 'kaldi',
        label: '"Üşütür" denip kalsın',
        resultText: 'Üç kat kaldı. Eve dönüşte terden sırtın kızarmıştı.',
        happiness: -1,
        health: -1,
      ),
    ],
  ),
  GameEvent(
    id: 'bebek_yaz_sicagi',
    category: EventCategory.kisisel,
    text: 'Öğle sıcağında ev fırın gibi. Perdeler çekildi, yere ıslak '
        'havlu serildi.',
    requirement: EventRequirement(minAge: 0, maxAge: 2),
    repeatable: true,
    minAgeGap: 3,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'uyudu',
        label: 'Serinlikte uyu',
        resultText: 'Yerdeki serinlikte uyudun. Akşama kadar kimse seni '
            'uyandırmadı.',
        happiness: 4,
        health: 1,
      ),
      EventChoice(
        id: 'huysuz',
        label: 'Sıcaktan huysuzlan',
        resultText: 'Bütün gün ağladın. Akşam serinleyince geçti.',
        happiness: -2,
      ),
    ],
  ),
  GameEvent(
    id: 'bebek_arabasiyla_kaldirim',
    category: EventCategory.mahalle,
    text: 'Bebek arabası kaldırıma sığmadı. Yolun kenarından yürümek '
        'zorunda kaldınız.',
    requirement: EventRequirement(
      minAge: 0,
      maxAge: 2,
      livingRelations: <RelationType>{RelationType.anne, RelationType.baba},
      requireSameHousehold: true,
    ),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'kucak',
        label: 'Kucağa alınsın',
        resultText: 'Araba katlandı, sen kucağa geçtin. Yolun kalanı '
            'yakındı.',
        happiness: 3,
        bond: 3,
      ),
      EventChoice(
        id: 'devam',
        label: 'Yoldan devam edilsin',
        resultText: 'Arabayla yoldan gidildi. Arkadan korna çaldı.',
        happiness: -1,
      ),
    ],
  ),
  GameEvent(
    id: 'bebek_vazgecmedigi_oyuncak',
    category: EventCategory.kisisel,
    text: 'Bir tanesini bırakmıyorsun: nereye gidilse o da geliyor.',
    requirement: EventRequirement(minAge: 1, maxAge: 3),
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'yanimda',
        label: 'Hep yanında olsun',
        resultText: 'Yıkanırken bile kenarda bekliyor. Kokusu bile '
            'tanıdık.',
        happiness: 5,
        addFlags: <String>{BabyhoodFlags.vazgecmedigiOyuncak},
      ),
      EventChoice(
        id: 'evde',
        label: 'Evde kalsın',
        resultText: 'Kapıda bırakıldı. Yol boyunca aradın.',
        happiness: -2,
      ),
    ],
  ),
  GameEvent(
    id: 'bebek_ev_sessizligi',
    category: EventCategory.aile,
    text: 'Sen uyurken ev başka bir eve dönüşüyor: fısıltıyla konuşuluyor, '
        'kapı tutularak kapatılıyor.',
    requirement: EventRequirement(
      minAge: 0,
      maxAge: 2,
      livingRelations: <RelationType>{RelationType.anne, RelationType.baba},
      requireSameHousehold: true,
    ),
    repeatable: true,
    minAgeGap: 2,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'uyudu',
        label: 'Rahat uyu',
        resultText: 'İki saat kesintisiz uyudun. Evde kimse yüksek sesle '
            'konuşmadı.',
        happiness: 4,
        health: 1,
      ),
      EventChoice(
        id: 'zil',
        label: 'Kapı zili her şeyi bozsun',
        resultText: 'Zil çaldı, uyandın. Kapıdaki kişi uzun uzun özür '
            'diledi.',
        happiness: -2,
      ),
    ],
  ),
  GameEvent(
    id: 'bebek_ilk_sac_kesimi',
    category: EventCategory.aile,
    text: 'Mutfak sandalyesine oturtuldun, boynuna havlu bağlandı. '
        'Makas evde.',
    requirement: EventRequirement(
      minAge: 1,
      maxAge: 3,
      livingRelations: <RelationType>{RelationType.anne, RelationType.baba},
      requireSameHousehold: true,
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'durdu',
        label: 'Kıpırdamadan dur',
        resultText: 'Kesim düzgün çıktı. Bir tutam kâğıda sarılıp '
            'saklandı.',
        happiness: 4,
        appearance: 2,
      ),
      EventChoice(
        id: 'kipirdadi',
        label: 'Kıpırdanıp dur',
        resultText: 'Bir taraf kısa kaldı. Şapka iki hafta kafandan '
            'inmedi.',
        happiness: -1,
        appearance: -2,
      ),
    ],
  ),
  GameEvent(
    id: 'bebek_akrabadan_mikrop',
    category: EventCategory.aile,
    text: 'Misafirde kucak kucak dolaştın. İki gün sonra burnun aktı.',
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
        id: 'evde',
        label: 'Evde dinlensin',
        resultText: 'Üç gün evden çıkılmadı. Geçti.',
        happiness: -1,
        health: -1,
      ),
      EventChoice(
        id: 'doktor',
        label: 'Hekime götürülsün',
        resultText: 'Muayene oldun, kayda geçti. Birkaç gün sonra '
            'düzeldin.',
        health: 1,
        money: -900,
      ),
    ],
  ),
  GameEvent(
    id: 'bebek_yurume_kiyaslamasi',
    category: EventCategory.mahalle,
    text: '"Komşunun çocuğu yürüdü bile" dendi. Ev bir anda telaşa '
        'kapıldı.',
    requirement: EventRequirement(
      minAge: 1,
      maxAge: 2,
      livingRelations: <RelationType>{RelationType.anne, RelationType.baba},
      requireSameHousehold: true,
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'bekle',
        label: '"Her çocuk kendi vaktinde"',
        resultText: 'Telaş yatıştı. Birkaç hafta sonra kendin kalktın, '
            'kimse hazır değildi.',
        happiness: 4,
      ),
      EventChoice(
        id: 'calistir',
        label: 'Her gün elinden tutup yürütülsün',
        resultText: 'Her akşam koridorda tur attınız. Yürüdüğünde '
            'alışkanlıktan kimse şaşırmadı.',
        happiness: 2,
        health: 1,
        bond: 3,
      ),
    ],
  ),

  // --- İki izin karşılığı ------------------------------------------------
  //
  // Karşılığı olmayan iz yazılmaz (Paket AR); yukarıdaki iki iz
  // aşağıda okunur.
  GameEvent(
    id: 'bebek_cekmecedeki_altin',
    category: EventCategory.aile,
    text: 'Çekmecenin arkasından bebeklik kutun çıktı. İçindekiler hâlâ '
        'yerinde.',
    requirement: EventRequirement(
      minAge: 7,
      maxAge: 18,
      requiredFlags: <String>{BabyhoodFlags.altinSaklandi},
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'okul',
        label: 'Okul masrafına bozdurulsun',
        resultText: 'Bozduruldu; kitap, çanta ve ayakkabı aynı hafta '
            'alındı.',
        happiness: 3,
        money: 9500,
      ),
      EventChoice(
        id: 'dursun',
        label: 'Dursun, yeri belli',
        resultText: 'Kutu çekmeceye geri girdi. Bir gün işe yarayacak.',
        happiness: 2,
      ),
    ],
  ),
  GameEvent(
    id: 'bebek_oyuncaga_veda',
    category: EventCategory.kisisel,
    text: 'Bırakmadığın o şey dolabın üstünde duruyor. Artık senden '
        'küçük görünüyor.',
    requirement: EventRequirement(
      minAge: 6,
      maxAge: 14,
      requiredFlags: <String>{BabyhoodFlags.vazgecmedigiOyuncak},
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'sakla',
        label: 'Sakla',
        resultText: 'Dolabın üstünde kaldı. Kimse atmaya kalkmadı.',
        happiness: 4,
      ),
      EventChoice(
        id: 'ver',
        label: 'Küçük bir çocuğa ver',
        resultText: 'Komşunun küçüğüne verdin. İlk gün bırakmadı onu da.',
        happiness: 5,
        bond: 3,
      ),
    ],
  ),
];
