/// Hobi olayları (Paket 39 — Issue #67, 1. kısım).
///
/// **Yeni bir sistem kurmaz.** Bu olaylar yalnızca `HobbyProgress` kaydına
/// bakar: oyuncu gerçekten yıllarca müzik, resim, okuma ya da sporla
/// uğraştıysa dünya bunu fark eder. Hiçbiri yeni meslek ağacı ya da
/// profesyonel sanatçı yolu açmaz (Issue #67 sınırı).
///
/// İki olay **geçmişi doğrudan hatırlar**: `hobi_cocuga_ogret` ve
/// `hobi_yillar_sonra_donus`. İkisi de yalnızca uzun sürmüş bir hobi
/// geçmişi varsa çıkar ve metinleri o geçmişe göndermede bulunur.
///
/// Ağırlıklar ve yaş aralıkları `prototypeOnly`'dir (Q-106).
library;

import '../domain/models/game_event.dart';
import '../domain/models/relation.dart';

const List<GameEvent> kHobbyEvents = <GameEvent>[
  // --- İş hayatı ---------------------------------------------------------
  GameEvent(
    id: 'hobi_is_yerinde_muzik',
    category: EventCategory.kisisel,
    text: 'İş yerinde yılbaşı programı hazırlanıyor. Birileri senin '
        'çaldığını duymuş; sahneye çıkman isteniyor.',
    requirement: EventRequirement(
      minAge: 22,
      maxAge: 60,
      requiresEmployed: true,
      requiredHobbyId: 'muzik',
      minHobbyYears: 2,
      requiresActiveHobby: true,
    ),
    repeatable: true,
    minAgeGap: 8,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'cal',
        label: 'Çal',
        resultText: 'İki parça çaldın. Ertesi gün koridorda seni hiç '
            'tanımayan insanlar selam verdi.',
        happiness: 6,
        charisma: 4,
      ),
      EventChoice(
        id: 'reddet',
        label: 'Bu sefer olmasın',
        resultText: 'Kibarca reddettin. Kimse ısrar etmedi ama biri '
            '"yazık" dedi.',
        happiness: -1,
      ),
    ],
  ),

  // --- Arkadaşlık --------------------------------------------------------
  GameEvent(
    id: 'hobi_arkadas_resim_ister',
    category: EventCategory.kisisel,
    text: '{kisi} bir şey rica ediyor: yeni taşındığı evin duvarına '
        'asmak için senden bir resim istiyor.',
    requirement: EventRequirement(
      minAge: 16,
      livingRelations: <RelationType>{RelationType.arkadas},
      requireReachable: true,
      requiredHobbyId: 'resim',
      minHobbyYears: 2,
      requiresActiveHobby: true,
    ),
    repeatable: true,
    minAgeGap: 10,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'yap',
        label: 'Otur ve yap',
        resultText: 'Haftalar sürdü. {kisi} resmi salonun tam ortasına '
            'astı; oraya her gidişinde kendi işini görüyorsun.',
        happiness: 7,
        bond: 8,
      ),
      EventChoice(
        id: 'vakit_yok',
        label: 'Vaktim yok',
        resultText: '"Anlıyorum" dedi. Konu bir daha açılmadı.',
        bond: -2,
      ),
    ],
  ),

  // --- Romantik ----------------------------------------------------------
  GameEvent(
    id: 'hobi_sevgili_kitapci',
    category: EventCategory.kisisel,
    text: 'Şehirde dolaşırken {kisi} seni bir sahafın önünde durdurdu: '
        '"Buraya girersek iki saat çıkamayız, biliyorum."',
    requirement: EventRequirement(
      minAge: 18,
      livingRelations: <RelationType>{
        RelationType.sevgili,
        RelationType.es,
      },
      requireReachable: true,
      requiredHobbyId: 'okuma',
      minHobbyStage: 1,
    ),
    repeatable: true,
    minAgeGap: 9,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'gir',
        label: 'Gir tabii',
        resultText: 'İki saat çıkamadınız. {kisi} sıkılmadı; senin '
            'raflar arasında hâlini izledi.',
        happiness: 6,
        bond: 6,
      ),
      EventChoice(
        id: 'sonra',
        label: 'Başka zaman',
        resultText: 'Geçip gittiniz. Dönüşte aklın hâlâ vitrindeydi.',
        happiness: -2,
      ),
    ],
  ),

  // --- Çocukla etkileşim (geçmişi hatırlar) ------------------------------
  GameEvent(
    id: 'hobi_cocuga_ogret',
    category: EventCategory.aile,
    text: 'Yıllar önce sen de bu yaştayken başlamıştın. {kisi} merakla '
        'bakıyor: "Bana da öğretir misin?"',
    requirement: EventRequirement(
      minAge: 28,
      livingRelations: <RelationType>{RelationType.cocuk},
      personMinAge: 6,
      personMaxAge: 16,
      requireSameHousehold: true,
      // Geçmişi hatırlayan olay: yalnızca **uzun sürmüş** bir hobi varsa.
      requiredHobbyId: 'muzik',
      minHobbyYears: 4,
      minHobbyStage: 2,
    ),
    repeatable: true,
    minAgeGap: 12,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'ogret',
        label: 'Öğret',
        resultText: 'Akşamları yarım saat ayırdın. {kisi} senin bir '
            'zamanlar yaptığın hataları aynen yapıyor; buna gülüyorsun.',
        happiness: 9,
        bond: 10,
      ),
      EventChoice(
        id: 'kendi_bulsun',
        label: 'Kendi yolunu bulsun',
        resultText: 'Enstrümanı ortada bıraktın, karışmadın. {kisi} bir '
            'süre denedi, sonra bıraktı.',
        happiness: -2,
        bond: -3,
      ),
    ],
  ),

  // --- Geçmişe dönüş (geçmişi hatırlar) ----------------------------------
  GameEvent(
    id: 'hobi_yillar_sonra_donus',
    category: EventCategory.kisisel,
    text: 'Dolabı toplarken yıllar önce bıraktığın şeyle karşılaştın. '
        'Bir süre elinde tuttun.',
    requirement: EventRequirement(
      minAge: 35,
      // Geçmişi hatırlayan ikinci olay: hobi **gerçekten bırakılmış**
      // olmalı. `requiresActiveHobby` bilerek kapalı.
      requiredHobbyId: 'resim',
      minHobbyYears: 3,
      minHobbyStage: 2,
    ),
    repeatable: true,
    minAgeGap: 15,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'yeniden_basla',
        label: 'Yeniden başla',
        resultText: 'İlk çizgide el hafızası geri geldi. Bıraktığın yer '
            'seni bekliyormuş.',
        happiness: 10,
      ),
      EventChoice(
        id: 'kaldir',
        label: 'Kaldır, yeri gelir',
        resultText: 'Kutuya geri koydun. Kapağı kapatırken içinden '
            '"bir ara" dedin.',
        happiness: -1,
      ),
    ],
  ),

  // --- Spor --------------------------------------------------------------
  GameEvent(
    id: 'hobi_mahalle_maci',
    category: EventCategory.kisisel,
    text: 'Mahallede bir maç kuruluyor ve bir kişi eksikler. Senin '
        'düzenli spor yaptığını biliyorlar.',
    requirement: EventRequirement(
      minAge: 15,
      maxAge: 55,
      requiredHobbyId: 'spor',
      minHobbyYears: 1,
      requiresActiveHobby: true,
    ),
    repeatable: true,
    minAgeGap: 6,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'oyna',
        label: 'Oyna',
        resultText: 'Ertesi gün her yerin ağrıdı ama akşam boyunca '
            'gülündü.',
        happiness: 7,
        health: 2,
      ),
      EventChoice(
        id: 'izle',
        label: 'Kenardan izle',
        resultText: 'Kenarda oturdun. İyi bir maçtı.',
        happiness: 1,
      ),
    ],
  ),

  // --- Okuma / yalnız zaman ----------------------------------------------
  GameEvent(
    id: 'hobi_okuma_gecesi',
    category: EventCategory.kisisel,
    text: 'Elektrikler kesildi. Mum ışığında okumaya çalışmak gençken '
        'daha kolaydı ama vazgeçmedin.',
    requirement: EventRequirement(
      minAge: 14,
      requiredHobbyId: 'okuma',
      // Paket 47 ölçümü: "okumak" hobisini yalnızca **bitirilen kitaplar**
      // besliyor ve kütüphanede 7 kitap var. Basamak 2'nin eşiği 8 deneyim
      // olduğu için bu olay hiçbir hayatta çıkamıyordu. Şart, verinin
      // gerçekten ulaşabildiği basamağa indirildi. Kitap sayısı ile hobi
      // merdiveni arasındaki uyumsuzluk Q-110'da karara sunuldu.
      minHobbyStage: 1,
      requiresActiveHobby: true,
    ),
    repeatable: true,
    minAgeGap: 11,
    weight: 2,
    choices: <EventChoice>[
      EventChoice(
        id: 'oku',
        label: 'Okumaya devam et',
        resultText: 'Elektrik gelince kitabın yarısı bitmişti.',
        happiness: 5,
        intelligence: 1,
      ),
      EventChoice(
        id: 'uyu',
        label: 'Bırak, uyu',
        resultText: 'Kitabı kapatıp yattın. Karanlıkta bir süre '
            'öyle kaldın.',
        happiness: 1,
      ),
    ],
  ),
];
