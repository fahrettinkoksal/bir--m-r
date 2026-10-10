/// Komşu olayları (Paket BU): komşu artık **adı olan** biri.
///
/// **Neden bu havuz var.** Paket BP evin binasını konuşturdu: kombi,
/// çatı, küf, apartman toplantısı, üst kattan gelen ses, yandaki
/// dairenin satılması. O dosyada bir satır vardı: "Komşu ve apartman
/// **metinde** yaşar; yeni kişi kaydı açılmaz. Komşunun kalıcı kişi
/// olması ayrı bir paket." Bu, o paket.
///
/// Buradaki olayların hepsi **gerçek bir komşuyu** hedefler
/// (`livingRelations: {komsu}` + `requireReachable`): metinde `{kisi}`
/// gördüğün yerde ekranda komşunun adı yazar, yakınlık o kişide birikir
/// ve ertesi yıl aynı kişi hatırlanır.
///
/// Kurallar:
///
/// - Para gerçekten cüzdandan çıkar (ECO-001) ve tutarlar Paket BP'nin
///   çıpalarıyla aynı ölçekte kalır (hepsi `prototypeOnly`).
/// - Komşuluk ağır konulara da değer (hastalık, vefat, kavga); bunlarda
///   espri yoktur (`docs/WRITING_STYLE_TR.md` §7).
/// - Gerçek marka, firma ve kişi adı geçmez.
/// - Bırakılan her iz **okunur**: dosyanın sonundaki dört olay kendi
///   izlerinin karşılığıdır (Paket AR'nin "sessiz iz" hatası
///   tekrarlanmaz).
///
/// Modül: `FeatureId.komsular` — kapatılınca bu havuz hiç listelenmez
/// ve komşu kişisi de üretilmez (`docs/FEATURE_FLAGS.md`).
library;

import '../domain/models/game_event.dart';
import '../domain/models/relation.dart';

/// Komşuluğun hikâye izleri.
abstract final class NeighbourFlags {
  /// Anahtarı komşuya bıraktı: güven verdi.
  static const String anahtarVerildi = 'komsu_anahtar_verildi';

  /// Gürültüyü konuştu (kapıyı çaldı, söyledi).
  static const String gurultuKonusuldu = 'komsu_gurultu_konusuldu';

  /// Apartman işinde komşuyla aynı tarafta durdu.
  static const String apartmandaYanYana = 'komsu_apartmanda_yan_yana';

  /// Komşunun yardım isteğini geri çevirdi.
  static const String yardimReddedildi = 'komsu_yardim_reddedildi';
}

/// prototypeOnly: komşu olaylarının para çıpaları (₺).
const int _kucukMasraf = 900;
const int _ortaMasraf = 4000;
const int _ustaMasrafi = 9000;

const List<GameEvent> kNeighbourEvents = <GameEvent>[
  // ===================================================================
  // Gündelik komşuluk
  // ===================================================================
  GameEvent(
    id: 'komsu_kapida_tanisma',
    category: EventCategory.kisisel,
    text: 'Asansörü beklerken {kisi} elinde poşetlerle geldi. '
        '"Yeni mi taşındınız?" diye sordu.\n\n'
        'Bir daire arayla yaşayacaksınız.',
    requirement: EventRequirement(
      minAge: 18,
      livingRelations: <RelationType>{RelationType.komsu},
      requireReachable: true,
    ),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'poset',
        label: 'Poşetlerini taşımaya yardım et',
        resultText: 'İki poşeti aldın, kapıya kadar çıktın. '
            'Kapıda "sağ olun" derken adını öğrendin.',
        happiness: 2,
        bond: 8,
      ),
      EventChoice(
        id: 'selam',
        label: 'Selam ver, geç',
        resultText: 'Selam verdin, asansörde iki kelime konuştunuz. '
            'Bu kadarı da bir şeydir.',
        bond: 3,
      ),
    ],
  ),
  GameEvent(
    id: 'komsu_tencere',
    category: EventCategory.kisisel,
    text: '{kisi} kapıyı çaldı; elinde üstü kapalı bir tencere var. '
        '"Çok oldu, size de getirdim" dedi.',
    requirement: EventRequirement(
      minAge: 18,
      livingRelations: <RelationType>{RelationType.komsu},
      requireReachable: true,
    ),
    weight: 5,
    repeatable: true,
    minAgeGap: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'bos_gonderme',
        label: 'Tencereyi boş geri gönderme',
        resultText: 'Tencereyi yıkadın, içine bir şeyler koyup geri '
            'götürdün. Kapıda "zahmet etmişsiniz" dedi, ikiniz de '
            'memnun oldunuz.',
        happiness: 2,
        bond: 7,
        money: -_kucukMasraf,
      ),
      EventChoice(
        id: 'tesekkur',
        label: 'Teşekkür et, yemeği ye',
        resultText: 'Yemek güzeldi. Tencereyi ertesi gün yıkayıp '
            'geri verdin.',
        happiness: 3,
        bond: 2,
      ),
    ],
  ),
  GameEvent(
    id: 'komsu_kargo',
    category: EventCategory.kisisel,
    text: 'Kapının önünde senin olmayan bir kargo var; üstünde '
        '{kisi} yazıyor. Sahibi akşama kadar gelmeyecek.',
    requirement: EventRequirement(
      minAge: 18,
      livingRelations: <RelationType>{RelationType.komsu},
      requireReachable: true,
    ),
    weight: 5,
    repeatable: true,
    minAgeGap: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'al',
        label: 'İçeri al, akşam haber ver',
        resultText: 'Kargoyu içeri aldın. Akşam kapıyı çalıp verdin; '
            '"iyi ki varsınız" dedi.',
        bond: 6,
        happiness: 1,
      ),
      EventChoice(
        id: 'kapiciya',
        label: 'Kapıcıya bırak',
        resultText: 'Kargoyu kapıcıya bıraktın. Sahibine ulaştı, '
            'kimse kimseye bir şey demedi.',
        bond: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'komsu_gurultu',
    category: EventCategory.kisisel,
    text: 'Gece yarısı üst kattan yine ses geliyor. {kisi} '
        'evde misafir ağırlıyor belli ki.\n\n'
        'Sabah işin var.',
    requirement: EventRequirement(
      minAge: 18,
      livingRelations: <RelationType>{RelationType.komsu},
      requireReachable: true,
    ),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'konus',
        label: 'Sabah kapısını çal, söyle',
        resultText: 'Sabah çaldın, kızmadan söyledin. Mahcup oldu, '
            '"haberim yoktu" dedi. Bir daha o saatte ses gelmedi.',
        happiness: 2,
        bond: 3,
        addFlags: <String>{NeighbourFlags.gurultuKonusuldu},
      ),
      EventChoice(
        id: 'sus',
        label: 'Sus, kulaklık tak',
        resultText: 'Kulaklıkla uyumayı denedin. Sabah yorgun kalktın; '
            'kimseye bir şey demedin.',
        happiness: -2,
        health: -1,
      ),
    ],
  ),
  GameEvent(
    id: 'komsu_anahtar',
    category: EventCategory.kisisel,
    text: 'Birkaç gün şehir dışına çıkıyorsun. {kisi} '
        '"çiçeklerinize bakarım, anahtar bırakın" dedi.',
    requirement: EventRequirement(
      minAge: 20,
      livingRelations: <RelationType>{RelationType.komsu},
      requireReachable: true,
      forbiddenFlags: <String>{NeighbourFlags.anahtarVerildi},
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'ver',
        label: 'Anahtarı bırak',
        resultText: 'Anahtarı bıraktın. Döndüğünde çiçekler yerinde, '
            'kapının önü süpürülmüş.',
        happiness: 2,
        bond: 10,
        addFlags: <String>{NeighbourFlags.anahtarVerildi},
      ),
      EventChoice(
        id: 'verme',
        label: 'Teşekkür et, anahtar verme',
        resultText: 'Teşekkür ettin, anahtarı vermedin. Döndüğünde iki '
            'çiçek kurumuştu.',
        happiness: -1,
        bond: -2,
      ),
    ],
  ),
  GameEvent(
    id: 'komsu_tamir_yardim',
    category: EventCategory.kisisel,
    text: '{kisi} kapıda: "Musluk akıyor, ben beceremedim. '
        'Sizde alet var mı?"',
    requirement: EventRequirement(
      minAge: 20,
      livingRelations: <RelationType>{RelationType.komsu},
      requireReachable: true,
    ),
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'bak',
        label: 'Gidip bir bak',
        resultText: 'Contayı değiştirdin, akıntı durdu. Elin yağ '
            'kokarken çayı içtin.',
        happiness: 2,
        bond: 9,
      ),
      EventChoice(
        id: 'usta',
        label: 'Usta numarası ver',
        resultText: 'Tanıdığın ustanın numarasını verdin. Usta gitti, '
            'işi çözdü; komşun "çok sağ olun" diye mesaj attı.',
        bond: 4,
        happiness: 1,
      ),
      EventChoice(
        id: 'reddet',
        label: 'Müsait olmadığını söyle',
        resultText: 'Müsait olmadığını söyledin. Kapı kapandı; '
            'ertesi gün merdivende selam kısa sürdü.',
        bond: -6,
        happiness: -1,
        addFlags: <String>{NeighbourFlags.yardimReddedildi},
      ),
    ],
  ),
  GameEvent(
    id: 'komsu_apartman_karari',
    category: EventCategory.kisisel,
    text: 'Apartman toplantısında dış cephe konusu açıldı. {kisi} '
        'bir öneri sundu ve salonun yarısı karşı çıktı.',
    requirement: EventRequirement(
      minAge: 20,
      livingRelations: <RelationType>{RelationType.komsu},
      requireReachable: true,
    ),
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'destek',
        label: 'Önerisini destekle',
        resultText: 'Elini kaldırdın. Öneri bir oy farkla geçti; '
            'çıkışta "arkamda durduğunuz için sağ olun" dedi.',
        bond: 8,
        money: -_ortaMasraf,
        happiness: 1,
        addFlags: <String>{NeighbourFlags.apartmandaYanYana},
      ),
      EventChoice(
        id: 'karsi',
        label: 'Karşı tarafta dur',
        resultText: 'Masrafın şimdilik gereksiz olduğunu söyledin. '
            'Öneri düştü; aidat aynı kaldı.',
        bond: -5,
      ),
      EventChoice(
        id: 'cekimser',
        label: 'Oy kullanma',
        resultText: 'Oy kullanmadın. Karar sensiz çıktı; kimse '
            'tarafını merak etmedi.',
        happiness: -1,
      ),
    ],
  ),
  GameEvent(
    id: 'komsu_hastalik',
    category: EventCategory.kisisel,
    text: '{kisi} birkaç gündür görünmüyor. Kapıyı çaldın; '
        'sesi zayıf çıktı, hasta.',
    requirement: EventRequirement(
      minAge: 22,
      livingRelations: <RelationType>{RelationType.komsu},
      requireReachable: true,
      personMinAge: 55,
    ),
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'carsi',
        label: 'Alışverişini sen yap',
        resultText: 'Listeyi aldın, çarşıya indin. Poşetleri kapıya '
            'bıraktın; kapıyı açarken gözleri doldu.',
        happiness: 3,
        bond: 12,
        money: -_kucukMasraf,
      ),
      EventChoice(
        id: 'doktor',
        label: 'Doktora götür',
        resultText: 'Arabayla hastaneye götürdün, sıra bekledin. '
            'Dönüşte ilaçları aldınız.',
        happiness: 2,
        bond: 14,
        money: -_ortaMasraf,
        health: -1,
      ),
      EventChoice(
        id: 'karisma',
        label: 'Geçmiş olsun de, karışma',
        resultText: '"Geçmiş olsun" dedin, kapıyı kapattın. '
            'Akşam ışığının yandığını görünce biraz rahatladın.',
        happiness: -1,
        addFlags: <String>{NeighbourFlags.yardimReddedildi},
      ),
    ],
  ),

  // ===================================================================
  // İzlerin karşılığı: her iz burada okunur
  // ===================================================================
  GameEvent(
    id: 'komsu_anahtar_karsiligi',
    category: EventCategory.kisisel,
    text: 'Elin kolun dolu, kapının önünde anahtarı bulamıyorsun. '
        'Sonra hatırladın: yedek anahtar {kisi} oğlunda.',
    requirement: EventRequirement(
      minAge: 22,
      livingRelations: <RelationType>{RelationType.komsu},
      requireReachable: true,
      requiredFlags: <String>{NeighbourFlags.anahtarVerildi},
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'cal',
        label: 'Komşunun kapısını çal',
        resultText: 'Anahtarı aldın, kapıyı açtın. '
            '"İyi ki vermişsiniz" dedi, güldünüz.',
        happiness: 3,
        bond: 5,
      ),
      EventChoice(
        id: 'cilingir',
        label: 'Çilingir çağır',
        resultText: 'Çilingiri çağırdın, kapı açıldı. Parayı verirken '
            'yedek anahtarı hatırlayıp kendine kızdın.',
        money: -_ustaMasrafi,
        happiness: -2,
      ),
    ],
  ),
  GameEvent(
    id: 'komsu_gurultu_karsiligi',
    category: EventCategory.kisisel,
    text: 'Senin evde kalabalık var, saat geç oldu. Kapı çaldı: '
        '{kisi} pijamayla duruyor.\n\n'
        'Geçen sene aynı kapıyı sen çalmıştın.',
    requirement: EventRequirement(
      minAge: 22,
      livingRelations: <RelationType>{RelationType.komsu},
      requireReachable: true,
      requiredFlags: <String>{NeighbourFlags.gurultuKonusuldu},
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'ozur',
        label: 'Özür dile, sesi kıs',
        resultText: 'Özür diledin, müziği kıstın. "Olur böyle şeyler" '
            'dedi; ikiniz de geçen seneyi hatırlayıp gülümsediniz.',
        happiness: 1,
        bond: 6,
      ),
      EventChoice(
        id: 'savun',
        label: 'Bir kere de sen katlan de',
        resultText: 'Bir kerelik olduğunu söyledin, kapıyı kapattın. '
            'Ertesi gün merdivende kimse konuşmadı.',
        bond: -8,
        happiness: -2,
      ),
    ],
  ),
  GameEvent(
    id: 'komsu_apartman_karsiligi',
    category: EventCategory.kisisel,
    text: 'Apartmanda bu yıl yönetici seçimi var. {kisi} '
        '"geçen sene yanımda durdunuz, bu sene de sizinle rahatım" '
        'diyor.',
    requirement: EventRequirement(
      minAge: 24,
      livingRelations: <RelationType>{RelationType.komsu},
      requireReachable: true,
      requiredFlags: <String>{NeighbourFlags.apartmandaYanYana},
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'yonetici',
        label: 'Yöneticiliği birlikte al',
        resultText: 'İkiniz birlikte aldınız. Yıl boyunca aidat, '
            'asansör ve kapıcı işi konuşuldu; apartman düzene girdi.',
        happiness: 2,
        charisma: 2,
        bond: 8,
      ),
      EventChoice(
        id: 'destekle',
        label: 'Sen al, ben destek olurum',
        resultText: 'Yöneticiliği o aldı, sen gerektiğinde yardım '
            'ettin. İkinizin de işine geldi.',
        bond: 5,
        happiness: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'komsu_ret_karsiligi',
    category: EventCategory.kisisel,
    text: 'Su kesildi, evde hiç su yok. Kapıyı çalacak tek kişi '
        '{kisi}.\n\n'
        'Geçen sefer kapıyı sen kapatmıştın.',
    requirement: EventRequirement(
      minAge: 24,
      livingRelations: <RelationType>{RelationType.komsu},
      requireReachable: true,
      requiredFlags: <String>{NeighbourFlags.yardimReddedildi},
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'cal',
        label: 'Yine de kapıyı çal',
        resultText: 'Çaldın. Bir bidon su verdi, fazla konuşmadı. '
            'Kapıyı kapatırken "geçen sefer" lafı ikinizin de '
            'aklından geçti.',
        bond: 4,
        happiness: -1,
      ),
      EventChoice(
        id: 'market',
        label: 'Markete in, su al',
        resultText: 'Markete indin, damacana taşıdın. Asansör de '
            'çalışmıyordu.',
        money: -_kucukMasraf,
        health: -1,
      ),
    ],
  ),
];
