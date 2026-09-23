/// Evcil hayvan olayları (Paket 40 — Issue #67, 2. kısım).
///
/// Hepsi yalnızca **gerçekten yaşayan ve hanede olan** bir hayvanı olan
/// oyuncuya çıkar. `{hayvan}` yer tutucusu kayıttaki gerçek adla,
/// `{tur}` gerçek türle doldurulur; uydurma hayvan üretilmez.
///
/// Ağırlıklar ve yaş aralıkları `prototypeOnly`'dir (Q-107).
library;

import '../domain/models/game_event.dart';
import '../domain/models/relation.dart';

const List<GameEvent> kPetEvents = <GameEvent>[
  // --- Kayıp ve bulunma --------------------------------------------------
  GameEvent(
    id: 'hayvan_kayboldu',
    category: EventCategory.kisisel,
    text: '{hayvan} akşam eve gelmedi. Sokak sokak dolaştın, adını '
        'bağırdın.',
    requirement: EventRequirement(
      minAge: 8,
      requiresLivingPet: true,
    ),
    repeatable: true,
    minAgeGap: 9,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'ara',
        label: 'Sabaha kadar ara',
        resultText: 'Gün ağarırken bir bahçe duvarının üstünde buldun. '
            'Hiçbir şey olmamış gibi bakıyordu.',
        happiness: 6,
        health: -2,
      ),
      EventChoice(
        id: 'bekle',
        label: 'Kapıyı aralık bırak, bekle',
        resultText: 'Gece yarısı kapı gıcırdadı. Yatağın ucuna çıkıp '
            'kıvrıldı.',
        happiness: 4,
      ),
    ],
  ),

  // --- Komşuyla ----------------------------------------------------------
  GameEvent(
    id: 'hayvan_komsu_sikayet',
    category: EventCategory.kisisel,
    text: 'Komşu kapıya geldi: {hayvan} yüzünden geceleri uyuyamıyormuş.',
    requirement: EventRequirement(
      minAge: 12,
      requiresLivingPet: true,
    ),
    repeatable: true,
    minAgeGap: 12,
    weight: 2,
    choices: <EventChoice>[
      EventChoice(
        id: 'ozur',
        label: 'Özür dile, önlem al',
        resultText: 'Bir şeyler denedin, işe yaradı. Komşu ertesi hafta '
            'kapıya kek bıraktı.',
        happiness: 3,
        charisma: 2,
      ),
      EventChoice(
        id: 'savun',
        label: 'Hayvanı savun',
        resultText: 'Tartışma büyüdü. Merdivende karşılaştığınızda artık '
            'selamlaşmıyorsunuz.',
        happiness: -3,
      ),
    ],
  ),

  // --- Yaşlanan hayvan ---------------------------------------------------
  GameEvent(
    id: 'hayvan_yaslandi',
    category: EventCategory.kisisel,
    text: '{hayvan} eskisi gibi koşmuyor. Merdiveni çıkarken duruyor, '
        'sonra sana bakıyor.',
    requirement: EventRequirement(
      minAge: 10,
      requiresLivingPet: true,
      // Yalnızca gerçekten yaşlanmış hayvan için.
      minPetAge: 9,
    ),
    repeatable: true,
    minAgeGap: 6,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'kucakla',
        label: 'Kucağına al, yukarı taşı',
        resultText: 'Artık merdiveni sen çıkarıyorsun. İkiniz de '
            'alıştınız.',
        happiness: 4,
      ),
      EventChoice(
        id: 'yavas',
        label: 'Kendi hızında bırak',
        resultText: 'Beklemeyi öğrendin. Her basamak ayrı bir mesele.',
        happiness: 2,
      ),
    ],
  ),

  // --- Yıllar sonra (geçmişi hatırlar) -----------------------------------
  GameEvent(
    id: 'hayvan_yillarin_dostu',
    category: EventCategory.kisisel,
    text: 'Eski bir fotoğrafta {hayvan} ile ilk günleriniz çıktı. '
        'O zamandan beri çok şey değişti.',
    requirement: EventRequirement(
      minAge: 14,
      requiresLivingPet: true,
      // Geçmişi hatırlayan olay: gerçekten uzun bir birliktelik gerekir.
      minPetYearsTogether: 6,
    ),
    repeatable: true,
    minAgeGap: 14,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'sakla',
        label: 'Fotoğrafı çerçevele',
        resultText: 'Çerçeve rafta duruyor. Bakan herkes "ne kadar '
            'küçükmüş" diyor.',
        happiness: 6,
      ),
      EventChoice(
        id: 'kaldir',
        label: 'Kutuya geri koy',
        resultText: 'Kapağı kapattın. Yine de akşam boyunca aklındaydı.',
        happiness: 2,
      ),
    ],
  ),

  // --- Çocukla -----------------------------------------------------------
  GameEvent(
    id: 'hayvan_cocukla',
    category: EventCategory.aile,
    text: '{kisi} bütün gün {hayvan} ile oynadı. Akşam "bu benim '
        'kardeşim" dedi.',
    requirement: EventRequirement(
      minAge: 22,
      livingRelations: <RelationType>{RelationType.cocuk},
      personMinAge: 3,
      personMaxAge: 14,
      requireSameHousehold: true,
      requiresLivingPet: true,
    ),
    repeatable: true,
    minAgeGap: 10,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'birak',
        label: 'Bırak, birlikte büyüsünler',
        resultText: 'İkisi de aynı yerde uyuyakaldı. Işığı kapattın.',
        happiness: 7,
        bond: 8,
      ),
      EventChoice(
        id: 'kural',
        label: 'Kurallar koy',
        resultText: 'Saat sınırı getirdin. {kisi} itiraz etti ama uydu.',
        happiness: 1,
        bond: -1,
      ),
    ],
  ),

  // --- Sokaktaki başka hayvan --------------------------------------------
  GameEvent(
    id: 'hayvan_sokakta_yavru',
    category: EventCategory.kisisel,
    text: 'Apartmanın girişinde bir yavru var. {hayvan} kapıdan onu '
        'izliyor.',
    requirement: EventRequirement(
      minAge: 12,
      requiresLivingPet: true,
    ),
    repeatable: true,
    minAgeGap: 11,
    weight: 2,
    choices: <EventChoice>[
      EventChoice(
        id: 'mama',
        label: 'Mama ve su bırak',
        resultText: 'Her sabah kabı dolduruyorsun. Yavru seni tanıdı.',
        happiness: 5,
      ),
      EventChoice(
        id: 'karisma',
        label: 'Karışma',
        resultText: 'Birkaç gün sonra yavru görünmez oldu. Nereye '
            'gittiğini bilmiyorsun.',
        happiness: -2,
      ),
    ],
  ),
];
