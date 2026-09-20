/// Hayat evrelerine dağıtılmış olay paketi (Paket 4).
///
/// Ölçüm (`tool/event_report.dart`) 0-4 yaş aralığında hiç olay olmadığını
/// ve 55 yaşından sonra olay oranının hızla düştüğünü gösterdi. Bu dosya
/// o boşlukları doldurur.
///
/// Kurallar:
/// - Kişi, eşya, ehliyet, sosyal medya hesabı gerektiren olay yalnızca o
///   şey **gerçekten varken** çıkar.
/// - Vefat etmiş veya gündelik hayatta erişilemeyen kişiyle olay kurulmaz.
/// - Nostalji ile güncel hayat dengelidir; her olay nostalji şakasına
///   dönüşmez.
library;

import '../domain/models/game_event.dart';
import '../domain/models/relation.dart';
import 'event_pool.dart';

/// Bu pakette açılan yeni hikâye izleri.
abstract final class StageFlags {
  static const String hobiEdinildi = 'hobi_edinildi';
  static const String hobiBirakildi = 'hobi_birakildi';
  static const String mahalleyeDonuldu = 'mahalleye_donuldu';
  static const String sinavaCalisti = 'sinava_calisti';
  static const String sinavaCalismadi = 'sinava_calismadi';
  static const String ilkEvHatirasi = 'ilk_ev_hatirasi';
  static const String vasiyetYazildi = 'vasiyet_yazildi';
}

const List<GameEvent> kLifeStageEvents = <GameEvent>[
  // =====================================================================
  // 0-4 yaş: kararlar bilinçli değil, tepkiler yaşa uygun
  // =====================================================================
  GameEvent(
    id: 'ilk_adim',
    category: EventCategory.aile,
    text: 'Sehpanın kenarına tutunup doğruldun. Karşıda {sahipk} {kisi} '
        'iki kolunu açmış, seni bekliyor. Aradaki üç adım şu an dünyanın '
        'en uzun mesafesi.',
    requirement: EventRequirement(
      minAge: 1,
      maxAge: 2,
      livingRelations: <RelationType>{
        RelationType.anne,
        RelationType.baba,
      },
      requireSameHousehold: true,
    ),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'birak',
        label: 'Sehpayı bırak',
        resultText: 'İki adım attın, üçüncüde kucağa düştün. O gün evde '
            'kimse başka bir şey konuşmadı.',
        happiness: 4,
        health: 1,
        bond: 5,
      ),
      EventChoice(
        id: 'tutun',
        label: 'Sıkıca tutunmaya devam et',
        resultText: 'Bugün olmadı. Sehpanın kenarında bir tur attın, '
            'bu da bir başlangıçtı.',
        happiness: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'ilk_kelime',
    category: EventCategory.aile,
    text: 'Herkes senin ağzına bakıyor. {sahip} {kisi} sabahtan beri aynı '
        'kelimeyi tekrarlıyor.',
    requirement: EventRequirement(
      minAge: 1,
      maxAge: 3,
      livingRelations: <RelationType>{
        RelationType.anne,
        RelationType.baba,
        RelationType.anneanne,
        RelationType.babaanne,
      },
    ),
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'soyle',
        label: 'Bekleneni söyle',
        resultText: 'Söyledin. Odadaki ses, senin çıkardığın sesten çok '
            'daha yüksekti.',
        happiness: 4,
        charisma: 2,
        bond: 6,
      ),
      EventChoice(
        id: 'baska',
        label: 'Bambaşka bir şey söyle',
        resultText: 'Kimsenin beklemediği bir kelime çıktı ağzından. '
            'Yıllarca bu anlatıldı, her seferinde biraz daha komik oldu.',
        happiness: 5,
        charisma: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'asi_gunu',
    category: EventCategory.aile,
    text: 'Sağlık ocağının koridoru kalabalık. Sıra sana geldiğinde '
        'hemşire gülümsüyor ama elindeki şeyi saklamıyor.',
    requirement: EventRequirement(
      minAge: 1,
      maxAge: 4,
      livingRelations: <RelationType>{
        RelationType.anne,
        RelationType.baba,
      },
    ),
    repeatable: true,
    minAgeGap: 2,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'agla',
        label: 'Bütün koridoru ayağa kaldır',
        resultText: 'İğne bir saniye sürdü, ağlama on dakika. Çıkışta '
            'alınan simit her şeyi çözdü.',
        health: 3,
        happiness: -1,
      ),
      EventChoice(
        id: 'sus',
        label: 'Kolunu uzat, sesini çıkarma',
        resultText: 'Hemşire "aferin" dedi, sen yalnızca baktın. '
            'Kolunda pamuk, elinde bir tane daha simit.',
        health: 3,
        happiness: 2,
      ),
    ],
  ),
  GameEvent(
    id: 'komsu_bebek_ziyareti',
    category: EventCategory.mahalle,
    text: 'Komşular seni görmeye geldi. Herkes sırayla kucağına almak '
        'istiyor, sen ise tanıdık bir yüz arıyorsun.',
    requirement: EventRequirement(minAge: 0, maxAge: 3),
    repeatable: true,
    minAgeGap: 2,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'gulumse',
        label: 'Gülümse',
        resultText: 'Bütün mahalle senin ne kadar uslu olduğunu konuştu. '
            'Bu ün birkaç yıl sürdü.',
        happiness: 3,
        charisma: 3,
      ),
      EventChoice(
        id: 'kacin',
        label: 'Yüzünü sakla',
        resultText: 'Yabancı kokulardan hoşlanmadın. Kimse alınmadı, '
            'ikram yine de yenildi.',
        happiness: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'ilk_oyuncak_paylasimi',
    category: EventCategory.mahalle,
    text: 'Elinde tek bir oyuncak var, karşında da senin kadar küçük biri. '
        'İkiniz de aynı şeye bakıyorsunuz.',
    requirement: EventRequirement(minAge: 2, maxAge: 4),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'ver',
        label: 'Uzat',
        resultText: 'Verdin. Beş dakika sonra ikiniz de başka bir şeyle '
            'oynuyordunuz; paylaşmak sandığın kadar zor değilmiş.',
        happiness: 2,
        charisma: 3,
      ),
      EventChoice(
        id: 'sakla',
        label: 'Arkana sakla',
        resultText: 'Sakladın. Oyuncak sende kaldı, oyun arkadaşı gitti. '
            'İkisi birden olmuyormuş.',
        happiness: -1,
        charisma: -1,
      ),
    ],
  ),

  // =====================================================================
  // 5-12 yaş: mahalle, okul, eşya
  // =====================================================================
  GameEvent(
    id: 'sokak_lambasi',
    category: EventCategory.mahalle,
    text: 'Sokak lambası yandı; bu, eve dönme işareti. Oyun tam da '
        'şimdi kızıştı.',
    requirement: EventRequirement(minAge: 7, maxAge: 12),
    repeatable: true,
    minAgeGap: 4,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'don',
        label: 'Hemen eve dön',
        resultText: 'Kapıda kimse kızmadı. Sofraya ilk sen oturdun, '
            'sıcak yemek yedin.',
        happiness: 2,
        health: 1,
      ),
      EventChoice(
        id: 'kal',
        label: 'Bir tur daha oyna',
        resultText: 'Bir tur üç tur oldu. Eve girdiğinde konuşan yalnızca '
            'saat oldu; kimse bir şey demedi, bakış yetti.',
        happiness: 3,
        health: -1,
      ),
    ],
  ),
  GameEvent(
    id: 'kantin_borcu',
    category: EventCategory.okul,
    text: 'Kantinde parası yetmeyen bir arkadaşın var. Kantinci "kim '
        'ödüyor?" diye bakıyor.',
    requirement: EventRequirement(
      minAge: 8,
      maxAge: 13,
      livingRelations: <RelationType>{RelationType.sinifArkadasi},
      requireReachable: true,
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'ode',
        label: 'Sen öde',
        resultText: 'Tostu ikiye böldünüz. Paranın yarısı gitti, '
            'teneffüsün tamamı kazanıldı.',
        happiness: 3,
        bond: 8,
        money: -30,
      ),
      EventChoice(
        id: 'sessiz',
        label: 'Sırandan ayrılma',
        resultText: 'Kimse bir şey demedi. {kisi} o gün kantinden '
            'boş döndü, sen de tostu yiyemedin.',
        happiness: -2,
        bond: -4,
      ),
    ],
  ),
  GameEvent(
    id: 'kutuphane_kokusu',
    category: EventCategory.okul,
    text: 'Okul kütüphanesi öğle arasında boş. Rafların arasında, '
        'kimsenin almadığı kalın bir kitap duruyor.',
    requirement: EventRequirement(
      minAge: 9,
      maxAge: 14,
      requiresSchoolStudent: true,
    ),
    repeatable: true,
    minAgeGap: 4,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'al',
        label: 'Ödünç al',
        resultText: 'Yarısını anlamadın, yarısını iki kez okudun. '
            'Kitabın arkasındaki kartta bir tek senin adın vardı.',
        intelligence: 4,
        happiness: 2,
      ),
      EventChoice(
        id: 'raf',
        label: 'Rafta bırak',
        resultText: 'Zil çaldı, kitap rafta kaldı. Başka bir gün, '
            'belki.',
        happiness: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'bisikletle_uzak_sokak',
    category: EventCategory.mahalle,
    text: 'Bisikletinle mahallenin sınırına geldin. Karşıda hiç '
        'gitmediğin bir sokak var ve eve dönüş yolu uzuyor.',
    requirement: EventRequirement(
      minAge: 8,
      maxAge: 14,
      requiredPossessions: <String>{Possessions.bisiklet},
    ),
    repeatable: true,
    minAgeGap: 5,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'git',
        label: 'Pedalla ve gir',
        resultText: 'Yeni bir fırın, yeni bir park, tanımadığın çocuklar. '
            'Mahallenin bittiği yer, senin dünyanın bittiği yer değilmiş.',
        happiness: 4,
        charisma: 2,
        health: 1,
      ),
      EventChoice(
        id: 'don',
        label: 'Geri dön',
        resultText: 'Bildiğin sokaklara döndün. Tanıdık olmanın da bir '
            'rahatlığı var.',
        happiness: 1,
      ),
    ],
  ),

  // =====================================================================
  // 13-17 yaş: tercih, hobi, aile ve gelecek
  // =====================================================================
  GameEvent(
    id: 'lise_kulubu',
    category: EventCategory.okul,
    text: 'Okulda kulüp listesi asıldı. Müzik, satranç, tiyatro ve '
        'gönüllülük. Bir tanesinin yanında senin adın da olabilir.',
    requirement: EventRequirement(
      minAge: 13,
      maxAge: 17,
      requiresSchoolStudent: true,
      forbiddenFlags: <String>{
        StageFlags.hobiEdinildi,
        StageFlags.hobiBirakildi,
      },
    ),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'yazil',
        label: 'Bir kulübe yazıl',
        resultText: 'Haftada iki öğle arası artık senin değil. Karşılığında '
            'bir şeyi gerçekten öğrenmeye başladın.',
        happiness: 4,
        charisma: 3,
        intelligence: 2,
        addFlags: <String>{StageFlags.hobiEdinildi},
      ),
      EventChoice(
        id: 'yazilma',
        label: 'Listeye bakıp geç',
        resultText: 'Adını yazmadın. Öğle araları boş kaldı, boşluk da '
            'bir seçim.',
        happiness: -1,
        addFlags: <String>{StageFlags.hobiBirakildi},
      ),
    ],
  ),
  GameEvent(
    id: 'aile_ile_gorus_ayriligi',
    category: EventCategory.aile,
    text: '{sahip} {kisi} ile geleceğin hakkında aynı fikirde değilsiniz. '
        'İkiniz de sesini yükseltmiyor ama kimse geri de adım atmıyor.',
    requirement: EventRequirement(
      minAge: 14,
      maxAge: 18,
      livingRelations: <RelationType>{
        RelationType.anne,
        RelationType.baba,
      },
      requireReachable: true,
    ),
    repeatable: true,
    minAgeGap: 3,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'anlat',
        label: 'Sebebini anlat',
        resultText: 'Anlattın. İkna olmadı ama dinledi; "sen bilirsin" '
            'dediğinde bu sefer gerçekten öyle demek istiyordu.',
        happiness: 3,
        charisma: 3,
        bond: 5,
      ),
      EventChoice(
        id: 'sus',
        label: 'Tartışmayı büyütme',
        resultText: 'Sustun. Konu kapandı, mesele kapanmadı.',
        happiness: -2,
        bond: -2,
      ),
    ],
  ),
  GameEvent(
    id: 'gece_telefonu',
    category: EventCategory.kisisel,
    text: 'Işıklar kapandıktan sonra telefonun ekranı hâlâ açık. '
        'Sabah ilk ders erken.',
    requirement: EventRequirement(
      minAge: 13,
      maxAge: 19,
      requiredPossessions: <String>{'telefon'},
    ),
    repeatable: true,
    minAgeGap: 4,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'kapat',
        label: 'Ekranı kapat',
        resultText: 'Sabah kalkmak kolay oldu. Kaçırdığın hiçbir şey '
            'yoktu zaten.',
        health: 3,
        intelligence: 1,
      ),
      EventChoice(
        id: 'devam',
        label: 'Bir video daha',
        resultText: 'Saat üçte yattın. İlk derste öğretmenin sesi '
            'uzaktan geliyordu.',
        health: -3,
        happiness: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'sinav_oncesi_gece',
    category: EventCategory.okul,
    text: 'Yarın sınav var. Masada açık defter, pencerede mahallenin '
        'sesi. İkisi aynı anda olmuyor.',
    requirement: EventRequirement(
      minAge: 15,
      maxAge: 18,
      requiresSchoolStudent: true,
      forbiddenFlags: <String>{
        StageFlags.sinavaCalisti,
        StageFlags.sinavaCalismadi,
      },
    ),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'calis',
        label: 'Masaya otur',
        resultText: 'Gece yarısına kadar çalıştın. Sınavda bildiğin '
            'soruları görmek, çalışmanın en güzel kısmıymış.',
        intelligence: 4,
        happiness: 1,
        health: -1,
        addFlags: <String>{StageFlags.sinavaCalisti},
      ),
      EventChoice(
        id: 'birak',
        label: 'Bu gece olmaz',
        resultText: 'Defteri kapattın. Sınav beklediğin gibi geçti; '
            'beklentin zaten düşüktü.',
        happiness: 2,
        intelligence: -1,
        addFlags: <String>{StageFlags.sinavaCalismadi},
      ),
    ],
  ),

  // =====================================================================
  // 18-29 yaş: iş, ev, geçim, çevre
  // =====================================================================
  GameEvent(
    id: 'ilk_ev_ilk_gece',
    category: EventCategory.yetiskinlik,
    text: 'Kendi evinde ilk gece. Kutular açılmadı, buzdolabı boş, '
        'duvarda kimsenin fotoğrafı yok.',
    requirement: EventRequirement(
      minAge: 18,
      maxAge: 32,
      forbiddenFlags: <String>{StageFlags.ilkEvHatirasi},
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'yerlestir',
        label: 'Sabaha kadar yerleştir',
        resultText: 'Güneş doğarken her şey yerindeydi. İlk kahvaltını '
            'kendi masanda yaptın.',
        happiness: 4,
        health: -1,
        addFlags: <String>{StageFlags.ilkEvHatirasi},
      ),
      EventChoice(
        id: 'otur',
        label: 'Yere oturup sessizliği dinle',
        resultText: 'Kutuların arasında oturdun. Ne zaman büyüdüğünü '
            'tam olarak o gece anladın.',
        happiness: 3,
        charisma: 1,
        addFlags: <String>{StageFlags.ilkEvHatirasi},
      ),
    ],
  ),
  GameEvent(
    id: 'is_gorusmesi_sonrasi',
    category: EventCategory.yetiskinlik,
    text: 'Görüşmeden çıktın. Otobüs durağında, söylemek isteyip '
        'söyleyemediğin cümleyi tekrar kuruyorsun.',
    requirement: EventRequirement(minAge: 18, maxAge: 35),
    repeatable: true,
    minAgeGap: 6,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'not_al',
        label: 'Eksiklerini yaz',
        resultText: 'Telefonuna üç madde yazdın. Bir sonraki görüşmede '
            'üçü de işine yaradı.',
        intelligence: 3,
        charisma: 2,
      ),
      EventChoice(
        id: 'unut',
        label: 'Kafana takma',
        resultText: 'Durakta beklerken konu değişti. Bazı görüşmeler '
            'sadece geçmek içindir.',
        happiness: 2,
      ),
    ],
  ),
  GameEvent(
    id: 'kira_ve_ay_sonu',
    category: EventCategory.yetiskinlik,
    text: 'Ay sonu geldi; kira, fatura ve market aynı haftaya denk '
        'düştü. Hesap tam çıkmıyor.',
    requirement: EventRequirement(minAge: 20, maxAge: 45),
    repeatable: true,
    minAgeGap: 7,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'kis',
        label: 'Kendi harcamandan kıs',
        resultText: 'Bu ay dışarıda yemek yok, yeni bir şey de yok. '
            'Hesap tuttu, canın biraz sıkıldı.',
        money: -200,
        happiness: -2,
        intelligence: 1,
      ),
      EventChoice(
        id: 'liste',
        label: 'Oturup bütçe listesi çıkar',
        resultText: 'Gelir gider tek sayfada. Rakamlar değişmedi ama '
            'artık nereye gittiğini biliyorsun.',
        intelligence: 3,
        happiness: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'eski_mahalleye_donus',
    category: EventCategory.mahalle,
    text: 'İşin bir şekilde seni eski mahallene düşürdü. Bakkal aynı '
        'yerde ama tabelası değişmiş.',
    requirement: EventRequirement(
      minAge: 22,
      maxAge: 45,
      forbiddenFlags: <String>{StageFlags.mahalleyeDonuldu},
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'dolas',
        label: 'Sokakları dolaş',
        resultText: 'Oyun oynadığın boşluğa bina yapılmış. Yine de '
            'ayakların yolu kendiliğinden hatırladı.',
        happiness: 4,
        addFlags: <String>{StageFlags.mahalleyeDonuldu},
      ),
      EventChoice(
        id: 'gec',
        label: 'İşini bitirip dön',
        resultText: 'İşini bitirdin, geri döndün. Geçmişe uğramak her '
            'zaman iyi gelmiyor.',
        happiness: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'sosyal_medya_mesaji',
    category: EventCategory.kisisel,
    text: 'Hesabına tanımadığın birinden uzun bir mesaj geldi: bir '
        'paylaşımın onu etkilemiş.',
    requirement: EventRequirement(
      minAge: 16,
      maxAge: 60,
      requiresSocialAccount: true,
    ),
    repeatable: true,
    minAgeGap: 6,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'cevap',
        label: 'Uzun uzun cevap yaz',
        resultText: 'Yazdıkların karşı tarafa iyi geldi. Sana da iyi '
            'geldiği kısmını kimseye söylemedin.',
        happiness: 3,
        charisma: 3,
      ),
      EventChoice(
        id: 'okundu',
        label: 'Okudun, geçtin',
        resultText: 'Mesaj okundu olarak kaldı. Bazı konuşmalar '
            'başlamadan biter.',
        happiness: -1,
      ),
    ],
  ),
  GameEvent(
    id: 'direksiyon_basinda',
    category: EventCategory.yetiskinlik,
    text: 'Arabanın anahtarı cebinde, yol uzun ve hava kapalı. Yanına '
        'kimseyi almadın.',
    requirement: EventRequirement(
      minAge: 18,
      maxAge: 70,
      requiredPossessions: <String>{'otomobil_ikinci_el'},
      requiredLicenses: <String>{'otomobil_ehliyeti'},
    ),
    repeatable: true,
    minAgeGap: 8,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'yavas',
        label: 'Acele etme, yavaş git',
        resultText: 'Radyoda eski bir şarkı çaldı, sonuna kadar '
            'dinledin. Yol uzadı, sen kısalmadın.',
        happiness: 3,
        health: 1,
      ),
      EventChoice(
        id: 'hizli',
        label: 'Erken varmak için hızlan',
        resultText: 'Yarım saat erken vardın. Kalan yarım saati de '
            'kalbinin hızlanmasıyla geçirdin.',
        happiness: 1,
        health: -2,
      ),
    ],
  ),

  // =====================================================================
  // 30+ : meslek, mülk, yakınlar, yaşlanma
  // =====================================================================
  GameEvent(
    id: 'is_yerinde_soz_hakki',
    category: EventCategory.yetiskinlik,
    text: 'Toplantıda yanlış bildiğini düşündüğün bir karar alınıyor. '
        'Söz almak için el kaldırmak yeterli.',
    requirement: EventRequirement(
      minAge: 30,
      maxAge: 60,
      requiredFlags: <String>{StoryFlags.calismaHayati},
    ),
    repeatable: true,
    minAgeGap: 7,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'soz_al',
        label: 'İtiraz et',
        resultText: 'Söyledin. Karar değişmedi ama toplantıdan sonra '
            'iki kişi yanına gelip "haklıydın" dedi.',
        charisma: 3,
        happiness: 2,
      ),
      EventChoice(
        id: 'sus',
        label: 'Sırası değil',
        resultText: 'Elini kaldırmadın. Karar uygulandı, sonuç senin '
            'düşündüğün gibi oldu; kimse hatırlamadı.',
        happiness: -2,
        intelligence: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'eski_arkadasla_karsilasma',
    category: EventCategory.kisisel,
    text: '{sahip} {kisi} ile aylar sonra karşılaştın. İkiniz de '
        '"bir ara görüşelim" diyecek kadar meşgulsünüz.',
    requirement: EventRequirement(
      minAge: 28,
      maxAge: 70,
      livingRelations: <RelationType>{RelationType.arkadas},
      requireReachable: true,
    ),
    repeatable: true,
    minAgeGap: 8,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'otur',
        label: 'Hemen bir çay iç',
        resultText: 'Yarım saat dediğiniz buluşma iki saat sürdü. '
            '"Bir ara" bugün oldu.',
        happiness: 4,
        bond: 9,
        money: -150,
      ),
      EventChoice(
        id: 'sonra',
        label: 'Bir ara, mutlaka',
        resultText: 'Telefon numaralarını kontrol ettiniz, ikiniz de '
            'aramayacağınızı biliyordunuz.',
        happiness: -1,
        bond: -3,
      ),
    ],
  ),
  GameEvent(
    id: 'mahalledeki_degisim',
    category: EventCategory.mahalle,
    text: 'Eski mahallende yıkım başladı. Çocukluğunun geçtiği sokak '
        'birkaç aya bambaşka olacak.',
    requirement: EventRequirement(
      minAge: 35,
      maxAge: 75,
      requiredFlags: <String>{StageFlags.mahalleyeDonuldu},
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'fotograf',
        label: 'Son hâlini fotoğrafla',
        resultText: 'Birkaç kare çektin. Yıllar sonra o fotoğraflar, '
            'sokağın var olduğunun tek kanıtı olacak.',
        happiness: 3,
        intelligence: 1,
      ),
      EventChoice(
        id: 'bakma',
        label: 'Dönüp bakma',
        resultText: 'Arabadan inmedin. Bazı şeyleri hatırladığın gibi '
            'bırakmak da bir seçim.',
        happiness: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'saglik_kontrolu',
    category: EventCategory.kisisel,
    text: 'Yıllık kontrol zamanı geldi. Randevu almak on dakika, '
        'ertelemek ise sadece bir tıklama.',
    requirement: EventRequirement(minAge: 40, maxAge: 75),
    repeatable: true,
    minAgeGap: 6,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'git',
        label: 'Randevuyu al ve git',
        resultText: 'Tahliller iyi çıktı. Doktorun tek uyarısı yürüyüş '
            'oldu; ertesi sabah başladın, üç gün sürdü.',
        health: 5,
        happiness: 1,
        money: -400,
      ),
      EventChoice(
        id: 'ertele',
        label: 'Seneye',
        resultText: 'Takvimde bir yıl ileri attın. Bir şeyin yok; '
            'bilmediğin sürece.',
        health: -3,
      ),
    ],
  ),
  GameEvent(
    id: 'emeklilik_karari',
    category: EventCategory.yetiskinlik,
    text: 'Emeklilik konuşulmaya başlandı. Kalmak da gitmek de '
        'mümkün; ikisi de bir şey bitiriyor.',
    requirement: EventRequirement(
      minAge: 58,
      maxAge: 68,
      requiredFlags: <String>{StoryFlags.calismaHayati},
    ),
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'devam',
        label: 'Biraz daha çalış',
        resultText: 'Sabahları hâlâ bir yere yetişiyorsun. Bu, sandığından '
            'daha çok işe yarıyor.',
        happiness: 2,
        health: -2,
      ),
      EventChoice(
        id: 'birak',
        label: 'Bırakma vakti',
        resultText: 'Son gün masanı topladın. Kapıdan çıkarken kimse '
            'konuşma yapmadı; sen de istemezdin.',
        happiness: 3,
        health: 2,
      ),
    ],
  ),
  GameEvent(
    id: 'eski_hobi_donusu',
    category: EventCategory.kisisel,
    text: 'Dolabın üstünde lise yıllarından kalan o şey duruyor. '
        'Tozunu alsan bugün başlayabilirsin.',
    requirement: EventRequirement(
      minAge: 50,
      maxAge: 85,
      requiredFlags: <String>{StageFlags.hobiEdinildi},
    ),
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'basla',
        label: 'Yeniden başla',
        resultText: 'Eller unutmamış. İlk gün yarım saat, ikinci gün '
            'iki saat; aradaki otuz yıl bir anda kısaldı.',
        happiness: 6,
        health: 1,
        intelligence: 2,
      ),
      EventChoice(
        id: 'kaldir',
        label: 'Yerine kaldır',
        resultText: 'Tozunu aldın, yerine koydun. Bazı şeyler '
            'durduğu yerde de iyi.',
        happiness: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'komsu_cocugu_buyudu',
    category: EventCategory.mahalle,
    text: 'Apartmanda kucağında taşıdığın çocuk, bugün sana kapıyı '
        'tutup "buyurun" dedi.',
    requirement: EventRequirement(minAge: 55, maxAge: 85),
    repeatable: true,
    minAgeGap: 10,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'gulumse',
        label: 'Gülümse ve teşekkür et',
        resultText: 'Merdivende birkaç basamak boyunca konuştunuz. '
            'Yaşlanmanın kötü tarafı bu değilmiş.',
        happiness: 3,
        charisma: 1,
      ),
      EventChoice(
        id: 'sitem',
        label: '"Ne çabuk büyüdünüz" de',
        resultText: 'Güldü. Sen de güldün ama cümlenin altındaki şeyi '
            'ikiniz de duydunuz.',
        happiness: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'evin_tamiri',
    category: EventCategory.yetiskinlik,
    text: 'Oturduğun evde bir şey bozuldu. Usta çağırmak pahalı, '
        'kendin bakmak ise vakit istiyor.',
    requirement: EventRequirement(minAge: 25, maxAge: 80),
    repeatable: true,
    minAgeGap: 9,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'usta',
        label: 'Usta çağır',
        resultText: 'Yarım saatte bitti. Parası canını yaktı ama '
            'akşam sıcak suyun vardı.',
        money: -3500,
        happiness: 2,
      ),
      EventChoice(
        id: 'kendin',
        label: 'Kendin bak',
        resultText: 'İki video, üç deneme ve bir kesik parmak. '
            'Sonunda oldu; anlatacak bir hikâyen de oldu.',
        happiness: 2,
        health: -1,
        intelligence: 2,
      ),
    ],
  ),
  GameEvent(
    id: 'vasiyet_dusuncesi',
    category: EventCategory.kisisel,
    text: 'Bir tanıdığın vefat etti ve geride hiçbir şey yazılı '
        'bırakmamış. Aklına kendi listesi geliyor.',
    requirement: EventRequirement(
      minAge: 65,
      maxAge: 95,
      forbiddenFlags: <String>{StageFlags.vasiyetYazildi},
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'yaz',
        label: 'Otur ve yaz',
        resultText: 'Bir sayfa sürdü. Yazarken, sahip olduklarından çok '
            'kime ne bıraktığını düşündün.',
        happiness: 2,
        intelligence: 1,
        addFlags: <String>{StageFlags.vasiyetYazildi},
      ),
      EventChoice(
        id: 'erteleme',
        label: 'Daha vakit var',
        resultText: 'Kâğıdı çekmecede bıraktın. Herkes öyle düşünür.',
        happiness: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'sessiz_ev_aksami',
    category: EventCategory.kisisel,
    text: 'Ev bu akşam çok sessiz. Televizyonu açtın, sesi kısık '
        'bıraktın; asıl mesele ses değil.',
    requirement: EventRequirement(minAge: 65, maxAge: 100),
    repeatable: true,
    minAgeGap: 6,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'ara',
        label: 'Birini ara',
        resultText: 'Uzun konuşmadınız. Telefonu kapattığında ev hâlâ '
            'sessizdi ama aynı sessizlik değildi.',
        happiness: 4,
        bond: 4,
      ),
      EventChoice(
        id: 'otur',
        label: 'Sessizliği bırak öyle kalsın',
        resultText: 'Pencereden sokağı izledin. Kimse geçmedi; '
            'bu da bir akşamdı.',
        happiness: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'hayat_muhasebesi',
    category: EventCategory.kisisel,
    text: 'Sabah erken uyandın ve uzun uzun geçmişi düşündün. '
        'Çalıştığın o sınav gecesi bile listenin bir yerinde.',
    requirement: EventRequirement(
      minAge: 72,
      maxAge: 105,
      requiredFlags: <String>{StageFlags.sinavaCalisti},
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'yaz',
        label: 'Hatırladıklarını yaz',
        resultText: 'Bir defter aldın. İlk sayfada o gece vardı; '
            'kalanını yavaş yavaş dolduracaksın.',
        happiness: 5,
        intelligence: 2,
      ),
      EventChoice(
        id: 'kalk',
        label: 'Kalk, güne başla',
        resultText: 'Çay demledin. Geçmiş nereye gidecek, dursun orada.',
        happiness: 2,
      ),
    ],
  ),
  GameEvent(
    id: 'mirasin_konusulmasi',
    category: EventCategory.aile,
    text: 'Yıllar önce yazdığın o sayfa çekmecede duruyor. Bugün '
        'yanındakilere ondan söz etmek için uygun bir akşam.',
    requirement: EventRequirement(
      minAge: 72,
      maxAge: 105,
      requiredFlags: <String>{StageFlags.vasiyetYazildi},
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'anlat',
        label: 'Açıkça konuş',
        resultText: 'Konuşulması zor sanılan şey yarım saatte bitti. '
            'Kimse şaşırmadı, herkes rahatladı.',
        happiness: 4,
        bond: 6,
      ),
      EventChoice(
        id: 'sakla',
        label: 'Yeri gelince öğrenirler',
        resultText: 'Çekmeceyi kapattın. Yazılı olması yetiyor dedin; '
            'belki de yetmez.',
        happiness: -1,
      ),
    ],
  ),
  GameEvent(
    id: 'ilk_evin_hatirasi',
    category: EventCategory.kisisel,
    text: 'Bir kutunun dibinden ilk evinin anahtarı çıktı. O eve ait '
        'olmayan tek şey, artık o anahtar.',
    requirement: EventRequirement(
      minAge: 55,
      maxAge: 95,
      requiredFlags: <String>{StageFlags.ilkEvHatirasi},
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'sakla',
        label: 'Sakla',
        resultText: 'Anahtarı çekmeceye koydun. Açacağı kapı yok ama '
            'hatırlattığı bir gece var.',
        happiness: 4,
      ),
      EventChoice(
        id: 'at',
        label: 'Kutuyla birlikte at',
        resultText: 'Attın. Bir süre sonra o geceyi hatırlarken '
            'anahtarı aradın, yoktu.',
        happiness: -2,
      ),
    ],
  ),
  GameEvent(
    id: 'torun_yasindaki_komsu',
    category: EventCategory.mahalle,
    text: 'Parkta bir çocuk topunu senin ayağına kadar yuvarladı ve '
        'bekliyor.',
    requirement: EventRequirement(minAge: 60, maxAge: 95),
    repeatable: true,
    minAgeGap: 7,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'vur',
        label: 'Topa vur',
        resultText: 'Vuruş eskisi gibi değildi ama top gitti. '
            'Çocuk "bir daha" dedi, iki kere daha oldu.',
        happiness: 4,
        health: 1,
      ),
      EventChoice(
        id: 'uzat',
        label: 'Eğilip uzat',
        resultText: 'Topu eline verdin. Teşekkür ederken kullandığı hitap '
            'yaşını sana hatırlattı; alışmak zaman aldı.',
        happiness: 2,
      ),
    ],
  ),
];
