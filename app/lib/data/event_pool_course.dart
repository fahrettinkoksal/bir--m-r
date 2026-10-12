/// Kursa ulaşmanın **parasız** yolları (Paket AJ, §7).
///
/// Aile ücreti karşılayamadığında kurs sonsuza kapanmamalı. Bu olaylar
/// nadir ama gerçek çıkışlar açar: belediyenin ücretsiz atölyesi, okul
/// kulübü, öğretmenin sahip çıkması, akrabanın desteği.
///
/// Hepsi `kurs_destegi` izini bırakır. O iz varken kurs dersleri yıl
/// içinde belli bir sayıya kadar ücretsizdir (bkz. `CourseProgress`);
/// sonsuz bedava ders değil, bir yıl boyunca açık kalan bir kapıdır.
///
/// Ağırlıklar ve yaş aralıkları `prototypeOnly`'dir.
library;

import '../domain/models/game_event.dart';

const List<GameEvent> kCourseSupportEvents = <GameEvent>[
  GameEvent(
    id: 'kurs_belediye_atolyesi',
    category: EventCategory.kisisel,
    text: 'Mahalle merkezinin camına bir ilan asılmış: belediyenin '
        'ücretsiz atölyeleri başlıyor. Kontenjan az, sıra uzun.',
    requirement: EventRequirement(minAge: 8, maxAge: 17),
    repeatable: true,
    minAgeGap: 4,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'kaydol',
        label: 'Sıraya gir',
        resultText: 'İki saat bekledin ve son kontenjanlardan birini '
            'kaptın. Bu yıl ders parası sorun değil.',
        happiness: 4,
        addFlags: <String>{'kurs_destegi'},
      ),
      EventChoice(
        id: 'vazgec',
        label: 'Bu kadar beklemeye değmez',
        resultText: 'Sırayı görünce vazgeçtin. Dönerken ilanın '
            'fotoğrafını çektin, sonra bir daha bakmadın.',
        happiness: -1,
      ),
    ],
  ),

  GameEvent(
    id: 'kurs_okul_kulubu',
    category: EventCategory.kisisel,
    text: 'Okulda kulüp seçimleri var. Listedeki kulüplerden biri tam '
        'ilgilendiğin şey ve okul bütün masrafı karşılıyor.',
    requirement: EventRequirement(
      minAge: 10,
      maxAge: 18,
      requiresSchoolStudent: true,
    ),
    repeatable: true,
    minAgeGap: 3,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'yazil',
        label: 'Kulübe yazıl',
        resultText: 'Haftada iki öğlen arası artık dolu. Malzemeyi okul '
            'veriyor.',
        happiness: 5,
        addFlags: <String>{'kurs_destegi'},
      ),
      EventChoice(
        id: 'bos_ver',
        label: 'Boş ver',
        resultText: 'Listeyi geri verdin. Teneffüste arkadaşların '
            'kulüpten konuşurken sustun.',
        happiness: -2,
      ),
    ],
  ),

  GameEvent(
    id: 'kurs_ogretmen_destegi',
    category: EventCategory.kisisel,
    text: 'Öğretmenin koridorda durdurdu. "Bunu bırakma," dedi. '
        '"Kursun ücretini konuşabileceğimiz bir yer biliyorum."',
    requirement: EventRequirement(
      minAge: 11,
      maxAge: 18,
      requiresSchoolStudent: true,
    ),
    repeatable: true,
    minAgeGap: 5,
    weight: 2,
    choices: <EventChoice>[
      EventChoice(
        id: 'kabul',
        label: 'Kabul et',
        resultText: 'Bir hafta sonra elinde bir kâğıtla geldi. '
            'Ücretsiz kontenjan ayarlanmış.',
        happiness: 6,
        addFlags: <String>{'kurs_destegi'},
      ),
      EventChoice(
        id: 'utan',
        label: 'Utandın, geçiştirdin',
        resultText: '"Gerek yok hocam," dedin. Eve giderken keşke '
            'demeseydim diye düşündün.',
        happiness: -2,
      ),
    ],
  ),

  GameEvent(
    id: 'kurs_akraba_destegi',
    category: EventCategory.aile,
    text: 'Bayram ziyaretinde konu kursa geldi. Akrabalardan biri '
        '"o parayı ben veririm, çocuk devam etsin" dedi.',
    requirement: EventRequirement(minAge: 9, maxAge: 17),
    repeatable: true,
    minAgeGap: 6,
    weight: 2,
    choices: <EventChoice>[
      EventChoice(
        id: 'tesekkur',
        label: 'Teşekkür et',
        resultText: 'Söz tutuldu. Bu yıl kayıt ücreti derdin olmadı.',
        happiness: 5,
        addFlags: <String>{'kurs_destegi'},
      ),
      EventChoice(
        id: 'reddet',
        label: 'Ailen kabul etmedi',
        resultText: 'Baban "gerek yok" diye kestirip attı. Konu orada '
            'kapandı.',
        happiness: -3,
      ),
    ],
  ),
];
