/// Yıllara yayılan çok adımlı olay zincirleri.
///
/// Havuzdaki zincirlerin çoğu iki adımdı: bir seçim, bir de yıllar sonra
/// gelen tek bir yankı. Buradaki dört zincir üç ya da dört adım sürüyor
/// ve **sonunda gerçek bir sonuca** varıyor — para, bir işin açılması,
/// bir ilişkinin yön değiştirmesi ya da kapanan bir hesap.
///
/// Yeni bir sistem gerekmedi: altyapı (`requiredFlags`, `forbiddenFlags`,
/// `rememberPersonAs`, `personRole`) Paket 4'ten beri duruyordu, yalnızca
/// içerik yazılmadı.
///
/// Yazım kuralları:
/// - Her adımın koşulu, **kendinden önceki bir adımın bıraktığı** izdir.
///   Koda gömülü ya da hiç üretilmeyen bir iz aranmaz; bunu
///   `test/event_chain_test.dart` kalıcı olarak denetliyor.
/// - Adımların yaş aralıkları ileri gider; ikinci adım birincisinden
///   önce çıkamaz.
/// - Kişiye bağlı adımlar `personRole` ile **aynı kişiyi** bulur. Kişi
///   vefat etmişse olay çıkmaz; uydurma bir yedek üretilmez.
/// - Dallar birbirini dışlar: bir dalın izini taşıyan oyuncu öbür dalın
///   adımını görmez.
/// - Sayısal etkiler `prototypeOnly` (Q-114).
library;

import '../domain/models/game_event.dart';
import '../domain/models/relation.dart';

/// Bu dosyadaki zincirlerin bıraktığı izler.
abstract final class ChainFlags {
  // Zincir 1 — Öğretmenin defteri
  static const String ogretmeneInandi = 'zincir_ogretmene_inandi';
  static const String ogretmeniGecti = 'zincir_ogretmeni_gecti';
  static const String ogretmeninYolunda = 'zincir_ogretmenin_yolunda';
  static const String kendiYolunuSecti = 'zincir_kendi_yolunu_secti';
  static const String defteriHatirladi = 'zincir_defteri_hatirladi';

  // Zincir 2 — Emanet para
  static const String borcVerdi = 'zincir_borc_verdi';
  static const String borcVermedi = 'zincir_borc_vermedi';
  static const String borcuIstedi = 'zincir_borcu_istedi';
  static const String borcuBekledi = 'zincir_borcu_bekledi';

  // Zincir 3 — Mahallenin boş arsası
  static const String arsayaSahipCikti = 'zincir_arsaya_sahip_cikti';
  static const String arsayaKarismadi = 'zincir_arsaya_karismadi';
  static const String parkOldu = 'zincir_park_oldu';

  // Zincir 4 — İş yerindeki haksızlık
  static const String isyerindeSavundu = 'zincir_isyerinde_savundu';
  static const String isyerindeSustu = 'zincir_isyerinde_sustu';
  static const String kidemliOldu = 'zincir_kidemli_oldu';
}

/// Bu dosyadaki zincirlerin kilitlediği kişi rolleri.
abstract final class ChainRoles {
  /// Defterine bir şey yazmış olan öğretmen.
  static const String gormusOgretmen = 'zincir_gormus_ogretmen';

  /// Kendisine borç verilen (ya da verilmeyen) arkadaş.
  static const String borcluArkadas = 'zincir_borclu_arkadas';

  /// İş yerinde haksızlığa uğrayan iş arkadaşı.
  static const String haksizligaUgrayan = 'zincir_haksizliga_ugrayan';
}

const List<GameEvent> kChainEvents = <GameEvent>[
  // ===================================================================
  // Zincir 1 — Öğretmenin defteri (4 adım, 10 → 45 yaş)
  //
  // Bir öğretmenin çocukken söylediği tek cümlenin ömür boyu sürmesi.
  // İki dal: inanmak ve geçiştirmek. İnanan dal üç adım daha sürüyor,
  // geçiştiren dal tek bir geç farkındalıkla kapanıyor.
  // ===================================================================
  GameEvent(
    id: 'zincir_ogretmen_1',
    category: EventCategory.okul,
    text:
        'Ders bitince {kisi} seni kalmaya çağırdı. Masasındaki defteri '
        'açıp bir satır gösterdi: senin adının yanına bir şey yazmış. '
        '"Bunu sana okumam lazım" diyor.',
    requirement: EventRequirement(
      minAge: 10,
      maxAge: 13,
      requiresSchoolStudent: true,
      livingRelations: <RelationType>{RelationType.ogretmen},
      forbiddenFlags: <String>{
        ChainFlags.ogretmeneInandi,
        ChainFlags.ogretmeniGecti,
      },
    ),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'dinle',
        label: 'Dikkatle dinle',
        resultText:
            'Okudu: "Bu çocuk bir işin ucundan tutarsa bırakmaz." '
            'Ne diyeceğini bilemedin. O gün eve yürürken cümle aklından '
            'çıkmadı.',
        happiness: 4,
        intelligence: 2,
        bond: 8,
        addFlags: <String>{ChainFlags.ogretmeneInandi},
        rememberPersonAs: ChainRoles.gormusOgretmen,
      ),
      EventChoice(
        id: 'gecistir',
        label: 'Gülüp geçiştir',
        resultText:
            '"Tamam hocam" deyip çantanı aldın. {kisi} defteri '
            'kapattı, bir şey demedi. Zil çalmıştı bile.',
        happiness: -1,
        bond: -2,
        addFlags: <String>{ChainFlags.ogretmeniGecti},
        rememberPersonAs: ChainRoles.gormusOgretmen,
      ),
    ],
  ),

  // 2. adım — inanan dal. Aynı öğretmen, yıllar sonra araya giriyor.
  GameEvent(
    id: 'zincir_ogretmen_2',
    category: EventCategory.okul,
    text:
        'Alan seçimi haftası. {kisi} koridorda seni durdurdu: '
        '"O defteri hatırlıyor musun? Sana bir şey söyleyeceğim, sonra '
        'kararı sen ver."',
    requirement: EventRequirement(
      minAge: 14,
      maxAge: 18,
      requiredFlags: <String>{ChainFlags.ogretmeneInandi},
      personRole: ChainRoles.gormusOgretmen,
      forbiddenFlags: <String>{
        ChainFlags.ogretmeninYolunda,
        ChainFlags.kendiYolunuSecti,
      },
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'dinle',
        label: 'Ne diyeceğini dinle',
        resultText:
            'Uzun uzun anlattı; nerede zorlanacağını da söyledi, '
            'kolay olanı değil. Çıkarken "arkanda duracağım" dedi ve '
            'durdu da.',
        happiness: 5,
        intelligence: 3,
        bond: 10,
        addFlags: <String>{ChainFlags.ogretmeninYolunda},
      ),
      EventChoice(
        id: 'kendi',
        label: 'Teşekkür et, kendi kararını ver',
        resultText:
            '"Sağ olun hocam, ben kendim seçeceğim" dedin. '
            'Gücenmedi. "En doğrusu da bu zaten" dedi.',
        happiness: 3,
        charisma: 3,
        addFlags: <String>{ChainFlags.kendiYolunuSecti},
      ),
    ],
  ),

  // 3. adım — inanan dal. Öğretmen emekli oluyor.
  GameEvent(
    id: 'zincir_ogretmen_3',
    category: EventCategory.kisisel,
    text:
        'Telefonuna eski bir numaradan mesaj geldi. {kisi} emekli '
        'oluyor; okulda küçük bir tören var ve senin adını listeye '
        'yazdırmış.',
    requirement: EventRequirement(
      minAge: 24,
      maxAge: 45,
      requiredFlags: <String>{ChainFlags.ogretmeninYolunda},
      personRole: ChainRoles.gormusOgretmen,
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'git',
        label: 'Törene git',
        resultText:
            'Sıranın sonunda seni gördü ve yanındakine "işte bu" '
            'dedi. Defteri getirmişti; o sayfa hâlâ duruyordu.',
        happiness: 10,
        bond: 12,
        addFlags: <String>{ChainFlags.defteriHatirladi},
      ),
      EventChoice(
        id: 'yazamadim',
        label: 'Gidemeyeceğini yaz',
        resultText:
            'Uzun bir mesaj yazdın, sonra çoğunu sildin. '
            '"Gelemiyorum ama o cümleyi hiç unutmadım" diye gönderdin. '
            'Kısa bir "biliyorum" geldi.',
        happiness: 4,
        bond: 4,
        addFlags: <String>{ChainFlags.defteriHatirladi},
      ),
    ],
  ),

  // 4. adım — zincirin kapanışı. Artık anlatan sensin.
  GameEvent(
    id: 'zincir_ogretmen_4',
    category: EventCategory.kisisel,
    text:
        'Bir genç sana ne iş yaptığını sordu, sonra "ben de bunu '
        'istiyorum ama bende olur mu bilmiyorum" dedi. Yüzünde tanıdık '
        'bir tereddüt var.',
    requirement: EventRequirement(
      minAge: 34,
      maxAge: 70,
      requiredFlags: <String>{ChainFlags.defteriHatirladi},
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'anlat',
        label: 'Sana yazılan o cümleyi anlat',
        resultText:
            'Defteri, o sayfayı, hocanın sesini anlattın. '
            'Genç bir süre sustu, sonra "bunu birinin bana söylemesini '
            'bekliyordum" dedi. Zincirin bir halkası daha eklendi.',
        happiness: 9,
        charisma: 4,
      ),
      EventChoice(
        id: 'kisa',
        label: 'Kısa kes: "Dene, olur"',
        resultText:
            '"Dene, olur" dedin. Söylediğin an, bunun sana '
            'yetmemiş olduğunu hatırladın.',
        happiness: 3,
      ),
    ],
  ),

  // 2. adım — geçiştiren dal. Tek adımda kapanıyor.
  GameEvent(
    id: 'zincir_ogretmen_gec',
    category: EventCategory.kisisel,
    text:
        'Bir kutunun dibinden eski okul defterin çıktı. Sayfayı '
        'çevirince aklına o gün geldi: hocan bir şey okuyacaktı, sen '
        'dinlememiştin.',
    requirement: EventRequirement(
      minAge: 18,
      maxAge: 40,
      requiredFlags: <String>{ChainFlags.ogretmeniGecti},
      forbiddenFlags: <String>{ChainFlags.defteriHatirladi},
    ),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'ara',
        label: 'Okulu arayıp hocayı sor',
        resultText:
            'Okul sekreteri "çoktan emekli oldu" dedi, numara '
            'veremedi. Telefonu kapattığında elinde yalnızca defter '
            'kaldı.',
        happiness: -2,
        addFlags: <String>{ChainFlags.defteriHatirladi},
      ),
      EventChoice(
        id: 'kaldir',
        label: 'Defteri kutuya geri koy',
        resultText:
            'Kapağı kapattın. Bazı cümleler söylendiği anda '
            'dinlenmezse bir daha söylenmiyor.',
        happiness: -1,
        addFlags: <String>{ChainFlags.defteriHatirladi},
      ),
    ],
  ),

  // ===================================================================
  // Zincir 2 — Emanet para (3-4 adım, 17 → 45 yaş)
  //
  // Verilen borcun yıllar sonra ne olduğu. İki dal: sıkıştırmak ve
  // beklemek. Her ikisi de gerçek bir sonuca varıyor; "beklemek" daha
  // geç ama daha fazla dönüyor, "istemek" daha erken ama ilişki
  // soğuyor. Hangisinin doğru olduğu söylenmiyor.
  // ===================================================================
  GameEvent(
    id: 'zincir_emanet_1',
    category: EventCategory.kisisel,
    text:
        '{kisi} akşam eve geldi, uzun uzun konuştu, sonra asıl '
        'söyleyeceğine geldi: sıkışmış, borç istiyor. Gözünü kaçırarak '
        '"iki ay içinde" diyor.',
    requirement: EventRequirement(
      minAge: 17,
      maxAge: 30,
      livingRelations: <RelationType>{RelationType.arkadas},
      requireReachable: true,
      forbiddenFlags: <String>{ChainFlags.borcVerdi, ChainFlags.borcVermedi},
    ),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'ver',
        label: 'Elindekini ver',
        resultText:
            'Saydın, verdin, senet falan olmadı. Kapıdan '
            'çıkarken "unutmam" dedi. Unutup unutmadığını zaman '
            'gösterecek.',
        money: -12000, // 2026: bir aylık asgari ücretin yarısı
        happiness: 2,
        bond: 10,
        addFlags: <String>{ChainFlags.borcVerdi},
        rememberPersonAs: ChainRoles.borcluArkadas,
      ),
      EventChoice(
        id: 'verme',
        label: 'Veremeyeceğini söyle',
        resultText:
            '"Kusura bakma, bende de yok" dedin. Doğruydu ama '
            'söylerken sesin tuhaf çıktı. {kisi} anlayışla başını '
            'salladı; o akşam erken gitti.',
        happiness: -3,
        bond: -6,
        addFlags: <String>{ChainFlags.borcVermedi},
        rememberPersonAs: ChainRoles.borcluArkadas,
      ),
    ],
  ),

  // 2. adım — iki ay çoktan geçti.
  GameEvent(
    id: 'zincir_emanet_2',
    category: EventCategory.kisisel,
    text:
        'İki ay dediği zaman geçeli çok oldu. {kisi} ortalıkta yok '
        'sayılır: mesajlara geç dönüyor, konu hiç açılmıyor.',
    requirement: EventRequirement(
      minAge: 19,
      maxAge: 35,
      requiredFlags: <String>{ChainFlags.borcVerdi},
      personRole: ChainRoles.borcluArkadas,
      forbiddenFlags: <String>{ChainFlags.borcuIstedi, ChainFlags.borcuBekledi},
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'iste',
        label: 'Açıkça iste',
        resultText:
            'Lafı dolandırmadan sordun. Bozuldu, "isteseydin '
            'verirdim zaten" dedi. Bir hafta sonra parayı getirdi ve '
            'çayı içmeden gitti.',
        money: 12000, // prototypeOnly
        happiness: -2,
        bond: -12,
        addFlags: <String>{ChainFlags.borcuIstedi},
      ),
      EventChoice(
        id: 'bekle',
        label: 'Hiç açma, bekle',
        resultText:
            'Açmadın. Bazen aklına geldi, bazen gelmedi. '
            'Arkadaşlık yerinde durdu; para havada kaldı.',
        happiness: -1,
        addFlags: <String>{ChainFlags.borcuBekledi},
      ),
    ],
  ),

  // 3. adım — bekleyen dalın karşılığı.
  GameEvent(
    id: 'zincir_emanet_3_bekle',
    category: EventCategory.kisisel,
    text:
        'Kapıda bir zarf ve üstünde senin adın. İçinde para ve tek '
        'satır: "Geç oldu. Sormadığın için ayrıca."',
    requirement: EventRequirement(
      minAge: 26,
      maxAge: 55,
      requiredFlags: <String>{ChainFlags.borcuBekledi},
      personRole: ChainRoles.borcluArkadas,
    ),
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'ara',
        label: 'Hemen ara',
        resultText:
            'Açtığında sesi titriyordu. "Utandığım için '
            'kaybolmuştum" dedi. O akşam iki saat konuştunuz; arada '
            'geçen yıllar birden kısaldı.',
        money: 20000, // Q-114: verilenin ~1,7 katı
        happiness: 12,
        bond: 18,
      ),
      EventChoice(
        id: 'sakla',
        label: 'Zarfı kaldır, bir şey deme',
        resultText:
            'Zarfı çekmeceye koydun. Borç kapandı; konuşulmayan '
            'şey kapanmadı.',
        money: 20000, // Q-114: verilenin ~1,7 katı
        happiness: 3,
        bond: 2,
      ),
    ],
  ),

  // 3. adım — isteyen dalın karşılığı.
  GameEvent(
    id: 'zincir_emanet_3_iste',
    category: EventCategory.kisisel,
    text:
        'Bir düğünde {kisi} ile aynı masaya düştünüz. Selamlaştınız; '
        'sonrası gelmedi. O akşam iki kere göz göze geldiniz.',
    requirement: EventRequirement(
      minAge: 26,
      maxAge: 55,
      requiredFlags: <String>{ChainFlags.borcuIstedi},
      personRole: ChainRoles.borcluArkadas,
    ),
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'konus',
        label: 'Kalk yanına git',
        resultText:
            '"O para meselesi" diye başladın, o "biliyorum" '
            'diye bitirdi. Uzun sürmedi ama ikiniz de rahatladınız.',
        happiness: 8,
        bond: 12,
      ),
      EventChoice(
        id: 'otur',
        label: 'Yerinde kal',
        resultText:
            'Kalkmadın. Düğün bitti, herkes dağıldı. '
            'Parayı geri almıştın; arkadaşını almamıştın.',
        happiness: -4,
      ),
    ],
  ),

  // ===================================================================
  // Zincir 3 — Mahallenin boş arsası (3 adım, 11 → 60 yaş)
  //
  // Kişisiz zincir: çocukluk mahallesinin yıllar içinde değişmesi.
  // Seçim çocukken yapılıyor, karşılığı otuz yıl sonra görünüyor.
  // ===================================================================
  GameEvent(
    id: 'zincir_arsa_1',
    category: EventCategory.mahalle,
    text:
        'Top oynadığınız boş arsanın köşesine bir tabela çakıldı: '
        'inşaat başlıyor. Büyüklerden biri kapı kapı imza topluyor ve '
        'sana da "sen de yaz" diyor.',
    requirement: EventRequirement(
      minAge: 11,
      maxAge: 15,
      forbiddenFlags: <String>{
        ChainFlags.arsayaSahipCikti,
        ChainFlags.arsayaKarismadi,
      },
    ),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'imzala',
        label: 'İmzala ve sen de kapı çal',
        resultText:
            'İki gün boyunca kapı çaldın. Kimi kovdu, kimi çay '
            'ikram etti. Listeyi muhtara birlikte götürdünüz.',
        happiness: 5,
        charisma: 4,
        addFlags: <String>{ChainFlags.arsayaSahipCikti},
      ),
      EventChoice(
        id: 'karisma',
        label: 'Karışma, oyununa dön',
        resultText:
            'Omuz silkip topa döndün. Arsa zaten hep oradaydı; '
            'hep orada kalacakmış gibi geliyordu.',
        happiness: 1,
        addFlags: <String>{ChainFlags.arsayaKarismadi},
      ),
    ],
  ),

  // 2. adım — arsanın ne olduğu.
  GameEvent(
    id: 'zincir_arsa_2',
    category: EventCategory.mahalle,
    text:
        'Yıllar sonra eski mahalleye yolun düştü. Arsanın yerinde '
        'küçük bir park var: birkaç bank, iki salıncak, bir de adı '
        'yazılı taş.',
    requirement: EventRequirement(
      minAge: 22,
      maxAge: 45,
      requiredFlags: <String>{ChainFlags.arsayaSahipCikti},
      forbiddenFlags: <String>{ChainFlags.parkOldu},
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'oku',
        label: 'Taştaki yazıyı oku',
        resultText:
            'Mahallelinin adları yazılmış; listenin ortasında '
            'seninki de var. O gün kapı çalan çocuk olduğunu kimse '
            'bilmiyor, sen biliyorsun.',
        happiness: 11,
        addFlags: <String>{ChainFlags.parkOldu},
      ),
      EventChoice(
        id: 'otur',
        label: 'Banka otur, bir süre kal',
        resultText:
            'Oturdun. Salıncaktaki çocuklar buranın bir zamanlar '
            'toprak bir arsa olduğunu bilmiyor. Bilmelerine de gerek '
            'yok.',
        happiness: 9,
        addFlags: <String>{ChainFlags.parkOldu},
      ),
    ],
  ),

  // 2. adım — karışmayan dal.
  GameEvent(
    id: 'zincir_arsa_2_gec',
    category: EventCategory.mahalle,
    text:
        'Eski mahalleden geçerken arsanın yerinde on katlı bir bina '
        'gördün. Girişinde güvenlik var; içeri bakamadın bile.',
    requirement: EventRequirement(
      minAge: 22,
      maxAge: 45,
      requiredFlags: <String>{ChainFlags.arsayaKarismadi},
      forbiddenFlags: <String>{ChainFlags.parkOldu},
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'bak',
        label: 'Bir süre karşıdan bak',
        resultText:
            'Kaçıncı katın top oynadığınız yere denk geldiğini '
            'hesapladın. Sonra bunun anlamsız olduğunu düşünüp yürüdün.',
        happiness: -3,
        addFlags: <String>{ChainFlags.parkOldu},
      ),
      EventChoice(
        id: 'gec',
        label: 'Durmadan geç',
        resultText:
            'Durmadın. Bazı yerler yıkılmıyor, yalnızca '
            'başkasının oluyor.',
        happiness: -1,
        addFlags: <String>{ChainFlags.parkOldu},
      ),
    ],
  ),

  // 3. adım — zincirin kapanışı, iki dal için de.
  GameEvent(
    id: 'zincir_arsa_3',
    category: EventCategory.mahalle,
    text:
        'Mahalleden biri seni buldu: eski sokağın yeniden düzenleniyor '
        've o günleri bilen birine soruyorlar. "Sen oradaydın" diyor.',
    requirement: EventRequirement(
      minAge: 46,
      maxAge: 80,
      requiredFlags: <String>{ChainFlags.parkOldu},
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'anlat',
        label: 'Ne hatırlıyorsan anlat',
        resultText:
            'Toprağın rengini, kalenin iki taş olduğunu, '
            'akşamları kimin annesinin önce seslendiğini anlattın. '
            'Yazdılar. Mahallenin hafızası bir kişinin ağzında '
            'duruyormuş.',
        happiness: 10,
        charisma: 3,
      ),
      EventChoice(
        id: 'reddet',
        label: '"Ben pek hatırlamıyorum" de',
        resultText:
            'Hatırlıyordun. Ama anlatmaya başlarsan '
            'duramayacağını biliyordun.',
        happiness: 2,
      ),
    ],
  ),

  // ===================================================================
  // Zincir 4 — İş yerindeki haksızlık (3 adım, 24 → 60 yaş)
  //
  // İş hayatının içinden bir zincir. Savunan dal iş açılmasıyla,
  // susan dal aynı şeyin başına gelmesiyle devam ediyor; ikisi de
  // üçüncü adımda seni kıdemli tarafa geçiriyor.
  // ===================================================================
  GameEvent(
    id: 'zincir_isyeri_1',
    category: EventCategory.yetiskinlik,
    text:
        'Toplantıda bir hata konuşuldu ve fatura {kisi} kesildi. '
        'Hatanın ondan çıkmadığını masada bir tek sen biliyorsun.',
    requirement: EventRequirement(
      minAge: 22,
      maxAge: 55,
      requiresEmployed: true,
      requiresMinYearsInJob: 1,
      livingRelations: <RelationType>{RelationType.isArkadasi},
      forbiddenFlags: <String>{
        ChainFlags.isyerindeSavundu,
        ChainFlags.isyerindeSustu,
      },
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'savun',
        label: 'Orada söyle',
        resultText:
            'Sözü aldın ve işin aslını anlattın. Ortam gerildi, '
            'toplantı erken bitti. Çıkışta {kisi} hiçbir şey demeden '
            'omzuna dokundu.',
        happiness: 4,
        charisma: 5,
        bond: 15,
        addFlags: <String>{ChainFlags.isyerindeSavundu},
        rememberPersonAs: ChainRoles.haksizligaUgrayan,
      ),
      EventChoice(
        id: 'sus',
        label: 'Sesini çıkarma',
        resultText:
            'Ekrana baktın, toplantı bitti. Asansörde yalnız '
            'kaldığında o cümleyi kendi kendine kurdun; artık çok '
            'geçti.',
        happiness: -6,
        bond: -8,
        addFlags: <String>{ChainFlags.isyerindeSustu},
        rememberPersonAs: ChainRoles.haksizligaUgrayan,
      ),
    ],
  ),

  // 2. adım — savunan dal.
  GameEvent(
    id: 'zincir_isyeri_2',
    category: EventCategory.yetiskinlik,
    text:
        '{kisi} başka bir yerde iyi bir noktaya geldi ve seni aradı: '
        '"O gün masada tek sen konuştun. Burada bir yer açılıyor."',
    requirement: EventRequirement(
      minAge: 26,
      maxAge: 60,
      requiredFlags: <String>{ChainFlags.isyerindeSavundu},
      personRole: ChainRoles.haksizligaUgrayan,
      forbiddenFlags: <String>{ChainFlags.kidemliOldu},
    ),
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'gorus',
        label: 'Git görüş',
        resultText:
            'Görüştünüz. Teklif ciddiydi ve karşılığı da. '
            'Kararı sonra verdin ama o gün anladın: doğru söylenmiş bir '
            'cümle yıllar sonra kapı açıyor.',
        money: 25000, // prototypeOnly
        happiness: 9,
        charisma: 3,
        bond: 8,
        addFlags: <String>{ChainFlags.kidemliOldu},
      ),
      EventChoice(
        id: 'tesekkur',
        label: 'Teşekkür et, yerinde kal',
        resultText:
            '"Sağ ol, ben buradayım" dedin. "Kapı açık" dedi ve '
            'gerçekten açık bıraktı.',
        happiness: 6,
        bond: 6,
        addFlags: <String>{ChainFlags.kidemliOldu},
      ),
    ],
  ),

  // 2. adım — susan dal. Aynı şey bu sefer sana oluyor.
  GameEvent(
    id: 'zincir_isyeri_2_sus',
    category: EventCategory.yetiskinlik,
    text:
        'Bu sefer masada konuşulan hata senin adına yazıldı ve '
        'hatanın senden çıkmadığını bilen birkaç kişi susuyor.',
    requirement: EventRequirement(
      minAge: 26,
      maxAge: 60,
      requiresEmployed: true,
      requiredFlags: <String>{ChainFlags.isyerindeSustu},
      forbiddenFlags: <String>{ChainFlags.kidemliOldu},
    ),
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'konus',
        label: 'Kendin savun',
        resultText:
            'Anlattın. Kimse arkanda durmadı ama söylemiş '
            'oldun. O akşam, yıllar önce susmanın ne demek olduğunu '
            'tam olarak anladın.',
        happiness: 2,
        charisma: 4,
        addFlags: <String>{ChainFlags.kidemliOldu},
      ),
      EventChoice(
        id: 'kabullen',
        label: 'Üstlen, geç',
        resultText:
            'Üstlendin. Kimse teşekkür etmedi, kimse bir şey '
            'sormadı. Sıra sende olunca sessizliğin ağırlığı belli '
            'oluyormuş.',
        happiness: -7,
        addFlags: <String>{ChainFlags.kidemliOldu},
      ),
    ],
  ),

  // 3. adım — kapanış: artık masadaki kıdemli sensin.
  GameEvent(
    id: 'zincir_isyeri_3',
    category: EventCategory.yetiskinlik,
    text:
        'Toplantıda genç birine haksız yere yükleniliyor ve masadaki '
        'en kıdemli kişi sensin. Herkes bir an sana bakıyor.',
    requirement: EventRequirement(
      minAge: 34,
      maxAge: 70,
      requiredFlags: <String>{ChainFlags.kidemliOldu},
    ),
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'araya_gir',
        label: 'Araya gir',
        resultText:
            'Tek cümleyle durdurdun: "Bu iş öyle olmadı." '
            'Toplantı sürdü, konu kapandı. Çıkarken genç arkandan '
            'yetişip teşekkür etti; sen bir şey demedin, gerek yoktu.',
        happiness: 12,
        charisma: 5,
      ),
      EventChoice(
        id: 'sonra',
        label: 'Toplantıdan sonra özel konuş',
        resultText:
            'Masada bir şey demedin, sonra yanına gittin. '
            '"Haklıydın" dedin. İşe yaradı ama orada, herkesin önünde '
            'söylenmesi başkaydı.',
        happiness: 5,
        charisma: 2,
      ),
    ],
  ),
];
