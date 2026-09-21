/// Yetişkinlikte tanışma ve bekâr hayat olayları (Paket 23).
///
/// **Neden bu dosya var:** Ölçüm, 176 olayın **yalnızca birinin**
/// (`cikma_teklifi`) romantik ilişki başlatabildiğini gösterdi. Üstelik o
/// tek kapı çok dardı:
///
/// * Önce `ilk_goz_agrisi` olayı **15-22** yaş arasında çıkmalı,
/// * orada "selam ver" seçilmeli (geçilirse `romantik_gecti` izi kalıcı
///   olarak kapıyı kapatıyordu),
/// * sonra `cikma_teklifi` **26 yaşından önce** çıkmalıydı,
/// * bir kez ayrılındıysa `romantik_bitti` izi yine kalıcı olarak
///   kapatıyordu.
///
/// Sonuç: 60 hayatın yalnızca **15'inde** hiç sevgili oluyordu. 26 yaşını
/// bekâr geçiren ya da bir kez ayrılan oyuncu, ömrünün geri kalanında
/// evlenemiyor, çocuk sahibi olamıyor; evlilik motoru, çocuklar, torunlar,
/// miras ve "çocuğum olarak devam et" akışı tamamen erişilmez kalıyordu.
///
/// Bu dosya iki şey yapar:
///
/// 1. **Yetişkinlik kapıları.** İş yeri, arkadaş aracılığı, düğün, kurs,
///    komşuluk ve ileri yaş için tanışma olayları. Hiçbiri `romantik_gecti`
///    veya `romantik_bitti` izine bakmaz: gençlikte bir otobüsü kaçırmak
///    ya da bir kez ayrılmak bir ömrü kapatmamalı.
/// 2. **Bekâr hayat içeriği.** Evlenmeyen hayatın da anlatacak şeyleri
///    olsun diye: aile baskısı, yalnız bayram, tek başına yaşamanın
///    kendine göre hâlleri.
///
/// Ağırlıklar ve yaş aralıkları `prototypeOnly`'dir (Q-091). Eşleşme ve
/// yönelim kuralları hâlâ Faho ile kararlaştırılacaktır; burada yalnızca
/// **erişilebilirlik** onarıldı.
library;

import '../domain/models/game_event.dart';
import '../domain/models/relation.dart';
import 'event_pool.dart';

/// Bekâr yetişkinlik izleri.
abstract final class SingleLifeFlags {
  /// Aileye "evlenmeyeceğim" denildi.
  static const String ailenineCevapVerdi = 'bekar_aileye_cevap';

  /// Yalnız yaşamayı benimsedi.
  static const String yalnizligiSecti = 'bekar_yalnizligi_secti';

  /// Tanışma çabası bir kez reddedildi; kapı kapanmaz, yalnızca iz kalır.
  static const String tanismayiErteledi = 'bekar_tanismayi_erteledi';
}

/// Yetişkinlikte romantik ilişki başlatabilen olaylarda **ortak** yasak
/// izler.
///
/// Zaten ilişkisi olan ya da evli olan oyuncunun karşısına ikinci bir
/// tanışma zinciri çıkmaz; böylece ikinci bir romantik kişi kaydı da
/// üretilmez. `romantik_gecti` ve `romantik_bitti` **bilerek** yok:
/// gençlikteki bir seçim ya da bir ayrılık ömrün geri kalanını
/// kapatmamalı.
const Set<String> _kapiYasaklari = <String>{
  StoryFlags.romantikIliskide,
  StoryFlags.evlendi,
};

const List<GameEvent> kRomanceEvents = <GameEvent>[
  // -----------------------------------------------------------------
  // Yetişkinlik kapıları
  // -----------------------------------------------------------------
  GameEvent(
    id: 'yetiskin_is_yerinde_tanisma',
    category: EventCategory.kisisel,
    text: 'İş çıkışı aynı otobüsü bekleyen bir iş arkadaşınla sohbet '
        'uzuyor. Bugün "bir kahve içelim mi" diye soruyor.',
    requirement: EventRequirement(
      minAge: 24,
      maxAge: 52,
      requiresEmployed: true,
      forbiddenFlags: _kapiYasaklari,
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'kahve',
        label: 'Kahveye çık',
        resultText: 'Kahve akşam yemeğine döndü. Artık birliktesiniz; '
            'İlişkiler bölümünde {kisi} görünüyor.',
        happiness: 8,
        charisma: 2,
        startsRomance: true,
      ),
      EventChoice(
        id: 'mesai',
        label: 'İşi işte bırak',
        resultText: 'Gülümseyip otobüse bindin. İş arkadaşlığı iş '
            'arkadaşlığı olarak kaldı.',
        happiness: -1,
        addFlags: <String>{SingleLifeFlags.tanismayiErteledi},
      ),
    ],
  ),
  GameEvent(
    id: 'yetiskin_arkadas_tanistirdi',
    category: EventCategory.kisisel,
    text: '{kisi} telefonda bir süredir aynı şeyi söylüyor: "Tanıştırmak '
        'istediğim biri var." Bu akşam yemeğe çağırıyor.',
    requirement: EventRequirement(
      minAge: 24,
      maxAge: 58,
      livingRelations: <RelationType>{RelationType.arkadas},
      forbiddenFlags: _kapiYasaklari,
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'git',
        label: 'Yemeğe git',
        resultText: 'Masada üç kişiydiniz ama {kisi} erken kalktı. '
            'Siz konuşmaya devam ettiniz.',
        happiness: 7,
        bond: 3,
        startsRomance: true,
      ),
      EventChoice(
        id: 'gitme',
        label: 'Bu akşam olmaz de',
        resultText: '"Başka zaman" dedin. {kisi} ısrar etmedi ama '
            'sesinden belli oldu.',
        happiness: -1,
        bond: -2,
        addFlags: <String>{SingleLifeFlags.tanismayiErteledi},
      ),
    ],
  ),
  GameEvent(
    id: 'yetiskin_dugunde_tanisma',
    category: EventCategory.kisisel,
    text: 'Bir düğündesin. Gelin tarafındaki masada yer kalmamış; seni '
        'tanımadığın bir masaya oturtuyorlar.',
    requirement: EventRequirement(
      minAge: 24,
      maxAge: 60,
      forbiddenFlags: _kapiYasaklari,
    ),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'sohbet',
        label: 'Yanındakiyle sohbet et',
        resultText: 'Gece boyunca konuştunuz. Düğünden çıkarken '
            'numaralarınızı verdiniz; sonrası kendiliğinden geldi.',
        happiness: 7,
        charisma: 2,
        startsRomance: true,
      ),
      EventChoice(
        id: 'erken_cik',
        label: 'Pastadan sonra çık',
        resultText: 'Pastayı bekleyip çıktın. Evde çay koydun, '
            'ayakkabılarını fırlattın.',
        happiness: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'yetiskin_kursta_tanisma',
    category: EventCategory.kisisel,
    text: 'Gittiğin kursta hep aynı kişiyle eşleşiyorsunuz. Bu hafta '
        '"dersten sonra devam edelim mi" diye soruyor.',
    requirement: EventRequirement(
      minAge: 26,
      maxAge: 64,
      forbiddenFlags: _kapiYasaklari,
    ),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'devam',
        label: 'Devam edelim de',
        resultText: 'Ders bitti, sohbet bitmedi. Bir süredir ilk kez '
            'birine anlatacak şeyin var.',
        happiness: 8,
        intelligence: 1,
        startsRomance: true,
      ),
      EventChoice(
        id: 'sadece_ders',
        label: 'Ders dersle kalsın',
        resultText: 'Kibarca geçiştirdin. Bir sonraki hafta başka '
            'biriyle eşleştiniz.',
        happiness: -1,
        addFlags: <String>{SingleLifeFlags.tanismayiErteledi},
      ),
    ],
  ),
  GameEvent(
    id: 'yetiskin_komsu_tanisma',
    category: EventCategory.kisisel,
    text: 'Karşı daireye yeni taşınan komşu kapıyı çaldı: elinde bir '
        'tabak, "ilk gün pişirdim, tek başıma yiyemedim" diyor.',
    requirement: EventRequirement(
      minAge: 28,
      maxAge: 66,
      forbiddenFlags: _kapiYasaklari,
    ),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'buyur',
        label: 'İçeri buyur et',
        resultText: 'Tabak boşaldı, sohbet bitmedi. Sonraki hafta '
            'kapı yine çaldı.',
        happiness: 7,
        startsRomance: true,
      ),
      EventChoice(
        id: 'tesekkur',
        label: 'Teşekkür edip kapıda kal',
        resultText: 'Tabağı aldın, teşekkür ettin. Ertesi gün boş '
            'tabağı kapının önüne bıraktın.',
        happiness: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'gec_yasta_arkadaslik',
    category: EventCategory.kisisel,
    text: 'Parkta her sabah aynı banka oturan biri var. Bugün yanına '
        'oturup "hep buradasınız" diyor.',
    requirement: EventRequirement(
      minAge: 58,
      maxAge: 84,
      forbiddenFlags: _kapiYasaklari,
    ),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'otur',
        label: 'Sohbeti uzat',
        resultText: 'Bir sabah iki oldu, iki sabah her gün. Bu yaşta '
            'yeniden birine alışmak tuhaf ama iyi geliyor.',
        happiness: 9,
        startsRomance: true,
      ),
      EventChoice(
        id: 'kalk',
        label: 'Kalkıp yürüyüşe devam et',
        resultText: 'Başını salladın, yürüyüşüne devam ettin. Sabah '
            'kendi sabahın.',
        happiness: 1,
        addFlags: <String>{SingleLifeFlags.yalnizligiSecti},
      ),
    ],
  ),

  // -----------------------------------------------------------------
  // Bekâr hayat: evlenmeyen ömrün de anlatacak şeyleri var
  // -----------------------------------------------------------------
  GameEvent(
    id: 'bekar_aile_baskisi',
    category: EventCategory.aile,
    text: 'Yemekte soru yine geldi: "Sen ne zaman?" Herkes tabağına '
        'bakıyor ama cevabı bekliyor.',
    requirement: EventRequirement(
      minAge: 27,
      maxAge: 55,
      forbiddenFlags: <String>{
        StoryFlags.romantikIliskide,
        StoryFlags.evlendi,
      },
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'net',
        label: 'Net cevap ver',
        resultText: '"Olursa olur, olmazsa olmaz" dedin. Masa bir an '
            'sustu, sonra konu değişti.',
        happiness: 3,
        charisma: 2,
        addFlags: <String>{SingleLifeFlags.ailenineCevapVerdi},
      ),
      EventChoice(
        id: 'gecistir',
        label: 'Gülüp geçiştir',
        resultText: '"İnşallah" deyip tabağına döndün. Soru bir '
            'dahakine yine gelecek.',
        happiness: -2,
      ),
    ],
  ),
  GameEvent(
    id: 'bekar_bayram_sabahi',
    category: EventCategory.kisisel,
    text: 'Bayram sabahı ev sessiz. Telefon birkaç kez çaldı, sonra o '
        'da sustu.',
    requirement: EventRequirement(
      minAge: 30,
      maxAge: 80,
      forbiddenFlags: <String>{
        StoryFlags.romantikIliskide,
        StoryFlags.evlendi,
      },
    ),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'cik',
        label: 'Kalk, birilerini ziyarete git',
        resultText: 'Kapı kapı dolaştın. Akşam yorgun ama kalabalık '
            'döndün.',
        happiness: 6,
        charisma: 1,
      ),
      EventChoice(
        id: 'evde',
        label: 'Evde kendi bayramını yap',
        resultText: 'Kahveni yaptın, pencereyi açtın. Sokaktaki '
            'bayramı oradan izledin.',
        happiness: 3,
        addFlags: <String>{SingleLifeFlags.yalnizligiSecti},
      ),
    ],
  ),
  GameEvent(
    id: 'bekar_tek_kisilik_ev',
    category: EventCategory.kisisel,
    text: 'Markette iki kişilik paket indirimde, tek kişilik olan '
        'değil. Elinde tutup bir süre baktın.',
    requirement: EventRequirement(
      minAge: 26,
      maxAge: 75,
      forbiddenFlags: <String>{
        StoryFlags.romantikIliskide,
        StoryFlags.evlendi,
      },
    ),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'al',
        label: 'Al, yarısı yarın olsun',
        resultText: 'Aldın. Yarısını dolaba koydun; yarın da yemek '
            'derdin olmadı.',
        happiness: 2,
      ),
      EventChoice(
        id: 'birak',
        label: 'Rafa geri koy',
        resultText: 'Geri koydun. Tek kişilik olanı aldın, kasada '
            'kuyruk kısaydı.',
        happiness: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'bekar_hafta_sonu_plani',
    category: EventCategory.kisisel,
    text: 'Cuma akşamı. Kimseye haber vermen gerekmiyor, kimse de '
        'sormuyor. Hafta sonu bütünüyle senin.',
    requirement: EventRequirement(
      minAge: 25,
      maxAge: 70,
      forbiddenFlags: <String>{
        StoryFlags.romantikIliskide,
        StoryFlags.evlendi,
      },
    ),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'kendine',
        label: 'Tamamen kendine ayır',
        resultText: 'Uyandığın saatte kalktın, canın ne istediyse onu '
            'yaptın. Pazar akşamı pişmanlık yoktu.',
        happiness: 6,
        addFlags: <String>{SingleLifeFlags.yalnizligiSecti},
      ),
      EventChoice(
        id: 'ara',
        label: 'Birilerini ara',
        resultText: 'İki kişiyi aradın, biri çıktı. Uzun zamandır '
            'gülmemiştin.',
        happiness: 5,
        charisma: 2,
      ),
    ],
  ),
  GameEvent(
    id: 'bekar_soru_aynada',
    category: EventCategory.kisisel,
    text: 'Gece yarısı mutfakta su içerken durdun: hayat böyle mi '
        'geçecek, yoksa böyle geçtiği için mi iyi?',
    requirement: EventRequirement(
      minAge: 34,
      maxAge: 70,
      forbiddenFlags: <String>{
        StoryFlags.romantikIliskide,
        StoryFlags.evlendi,
      },
    ),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'kabul',
        label: 'Böyle iyi de',
        resultText: 'Bardağı bıraktın, yattın. Sabah kimse sormadı, '
            'sen de anlatmadın.',
        happiness: 4,
        addFlags: <String>{SingleLifeFlags.yalnizligiSecti},
      ),
      EventChoice(
        id: 'ac_kapiyi',
        label: 'Belki de kapıyı açık tut',
        resultText: 'Ertesi hafta iki davete birden gittin. Ne olacağı '
            'belli değil ama hareketsiz de değilsin.',
        happiness: 3,
        charisma: 2,
      ),
    ],
  ),
];
