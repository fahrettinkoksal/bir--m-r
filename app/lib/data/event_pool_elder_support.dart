/// Yaşlılıkta bakımın **karşılığı**: kaydı okuyan olaylar (Paket CM).
///
/// **Neden var.** Paket CJ yaşlılıkta bakımı yazdı: 70 yaşından sonra
/// düşük sağlık bandında yılda bir karar veriliyor ve kayıt kaç yıl
/// destek görüldüğünü, kaç yılın kimseye yüklenmeden çevrildiğini
/// tutuyor. Ama o kayıt hiçbir yerde **hikâyeye dönmüyordu**; Q-228'in
/// beşinci maddesinde kendi önerim olarak bırakılmıştı.
///
/// **Koşul iz değil sayaç.** Olaylar `minElderSupportYears` ve
/// `minElderAloneYears` ile kayda bakar: "üç yıldır yanımda" diyen bir
/// cümle, o üç yıl gerçekten yaşanmadan çıkmaz. Hikâye izi
/// kullanılsaydı bir kez destek görmek ömür boyu yeterdi.
///
/// **Ölçüm (250 bot hayatı, ölüm anı kaydı).** Destek görülen yıl: 50
/// hayat, ortanca 4, en çok 17. Kimseye yüklenmeden çevrilen yıl: 72
/// hayat, ortanca 3, en çok 13. İki yıl ve üstü destek gören 43 hayat,
/// üç yıl ve üstü tek başına çeviren 44 hayat — eşikler buradan.
///
/// **Yeni iz bırakılmıyor.** Bu havuzun olayları hikâye izi yazmaz;
/// yazsalardı onları okuyan bir üçüncü katman gerekirdi (Paket AR'nin
/// ölçtüğü "sessiz iz" sorunu). Hikâye burada kapanıyor.
///
/// Argo yok, ağır konuda espri yok (`docs/WRITING_STYLE_TR.md`).
/// Gerçek marka, kurum ve kişi adı geçmez. Bütün sayılar
/// `prototypeOnly` (Q-228).
library;

import '../domain/models/game_event.dart';
import '../domain/models/relation.dart';

/// Bakım kaydını okuyan olaylar (Paket CM).
const List<GameEvent> kElderSupportEvents = <GameEvent>[
  // --- Destek görülen yılların karşılığı --------------------------------
  GameEvent(
    id: 'bakim_karsilik_aliskanlik',
    category: EventCategory.aile,
    text: 'Kapı çalınca kim olduğunu artık biliyorsun. Saat de hep '
        'aynı.',
    requirement: EventRequirement(
      minAge: 71,
      minElderSupportYears: 2,
    ),
    repeatable: true,
    minAgeGap: 5,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'soyle',
        label: 'Ne kadar iyi geldiğini söyle',
        resultText: 'Söyledin. "Bunu duymak için gelmiyorum" dedi ama '
            'yüzü başka şey söylüyordu.',
        happiness: 6,
        bond: 4,
      ),
      EventChoice(
        id: 'sessiz',
        label: 'Söylemesen de belli',
        resultText: 'Söylemedin. Belki belliydi, belki değildi.',
        happiness: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'bakim_karsilik_yorgunluk',
    category: EventCategory.aile,
    text: 'Yanında olan kişi bu akşam yorgun geldi. Bir şey söylemiyor '
        'ama gözleri belli ediyor.',
    requirement: EventRequirement(
      minAge: 72,
      minElderSupportYears: 3,
    ),
    repeatable: true,
    minAgeGap: 6,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'ara_ver',
        label: 'Bu hafta gelmemesini söyle',
        resultText: 'Bir hafta ara verdi. Sen idare ettin, o da '
            'dinlendi — ikisi de zor oldu.',
        happiness: -3,
        bond: 5,
      ),
      EventChoice(
        id: 'devam',
        label: 'Bir şey söylemeden devam et',
        resultText: 'Düzen bozulmadı. Yorgunluk da geçmedi.',
        happiness: 1,
        bond: -2,
      ),
    ],
  ),
  GameEvent(
    id: 'bakim_karsilik_torun_gorur',
    category: EventCategory.aile,
    text: 'Torunun, annesinin sana nasıl baktığını izliyor. Sonra sana '
        'soruyor: "Sen de böyle yapmış mıydın?"',
    requirement: EventRequirement(
      minAge: 73,
      minElderSupportYears: 3,
      livingRelations: <RelationType>{RelationType.torun},
      personMinAge: 8,
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'anlat',
        label: 'Kendi anne babanı anlat',
        resultText: 'Anlattın: neyi yapabildiğini, neyi yapamadığını. '
            'Kimseyi kahraman etmedin.',
        happiness: 5,
        bond: 4,
        intelligence: 1,
      ),
      EventChoice(
        id: 'gec',
        label: 'Konuyu kapat',
        resultText: '"Uzun hikâye" deyip geçtin. Çocuk bir daha '
            'sormadı.',
        happiness: -1,
      ),
    ],
  ),

  // --- Tek başına çevrilen yılların karşılığı ---------------------------
  GameEvent(
    id: 'bakim_karsilik_komsu_farketti',
    category: EventCategory.kisisel,
    text: 'Komşu merdivende durdu: "Ben her gün geçiyorum zaten, '
        'poşetini bırakayım mı?"',
    requirement: EventRequirement(
      minAge: 71,
      minElderAloneYears: 2,
    ),
    repeatable: true,
    minAgeGap: 6,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'kabul',
        label: 'Kabul et',
        resultText: 'Kabul ettin. Birkaç hafta sonra bu, iki kişinin '
            'de alıştığı bir düzen oldu.',
        happiness: 5,
        bond: 4,
      ),
      EventChoice(
        id: 'gerek_yok',
        label: 'Gerek yok, hallediyorum',
        resultText: '"Hallediyorum" dedin. Hallettin de; biraz daha '
            'uzun sürdü.',
        happiness: -1,
      ),
    ],
  ),
  GameEvent(
    id: 'bakim_karsilik_kimseyi_aramadim',
    category: EventCategory.kisisel,
    text: 'Telefonun son arama listesine baktın: bu ay kimseyi sen '
        'aramamışsın.',
    requirement: EventRequirement(
      minAge: 72,
      minElderAloneYears: 3,
    ),
    repeatable: true,
    minAgeGap: 7,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'ara',
        label: 'Birini ara',
        resultText: 'Aradın. İlk cümle zor kuruldu, gerisi kendi geldi.',
        happiness: 6,
        charisma: 1,
      ),
      EventChoice(
        id: 'birak',
        label: 'Bu da bir düzen',
        resultText: 'Telefonu bıraktın. Akşam sessiz geçti; alıştığın '
            'bir sessizlik.',
        happiness: -2,
      ),
    ],
  ),
  GameEvent(
    id: 'bakim_karsilik_defter_notu',
    category: EventCategory.kisisel,
    text: 'Yılları tek başına çevirdiğini kimse yazmıyor. Bir deftere '
        'kendin yazmayı düşünüyorsun.',
    requirement: EventRequirement(
      minAge: 74,
      minElderAloneYears: 4,
    ),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'yazdi',
        label: 'Yaz',
        resultText: 'Yazdın. Ne şikâyet ne övünme; sadece hangi yıl ne '
            'yaptığın.',
        happiness: 4,
        intelligence: 1,
      ),
      EventChoice(
        id: 'yazmadi',
        label: 'Gerek yok',
        resultText: 'Defteri açmadın. "Zaten hatırlıyorum" dedin; '
            'bazı yıllar birbirine karışmaya başlamıştı bile.',
        // **Etkisiz seçim yazılmaz** (`event_choice_effect_test`):
        // ilk yazımda burada `happiness: 0` vardı ve süit onu
        // yakaladı. Rakam uydurulmadı; yazmamanın karşılığı, yılların
        // birbirine karışması.
        happiness: -1,
      ),
    ],
  ),
];
