/// Prototipin özgün olay havuzu.
///
/// Havuz bilerek küçüktür; amaç olay motorunun uygunluk, seçim, etki ve
/// hafıza davranışını gerçek veriyle göstermektir. Yeni olay eklemek bu
/// listeye bir kayıt eklemektir. **Bu şema onaylanmış bir tasarım kararı
/// değildir**; nihai olay veri şeması Faho ile kararlaştırılacaktır.
library;

import '../domain/models/game_event.dart';
import '../domain/models/relation.dart';

/// Hikâye izleri (D-008). Seçimler bu izleri bırakır, sonraki olaylar arar.
abstract final class StoryFlags {
  static const String arkadasiniSavundu = 'arkadasini_savundu';
  static const String sessizKaldi = 'sessiz_kaldi';
  static const String universitede = 'universitede';
  static const String calismaHayati = 'calisma_hayati';

  /// Okul hikâyesi izleri.
  static const String okuldaArkadasEdindi = 'okulda_arkadas_edindi';
  static const String okuldaCekingen = 'okulda_cekingen';
  static const String arkadasaYardimEtti = 'arkadasa_yardim_etti';
  static const String arkadasaYardimEtmedi = 'arkadasa_yardim_etmedi';
  static const String dersteSozAldi = 'derste_soz_aldi';

  /// Romantik hikâye izleri (D-030).
  static const String romantikIlgi = 'romantik_ilgi';
  static const String romantikIliskide = 'romantik_iliskide';
  static const String romantikBitti = 'romantik_bitti';
  static const String romantikGecti = 'romantik_gecti';
}

/// Sahip olunan varlıklar. Sahip olunmayan varlık için olay çıkmaz.
abstract final class Possessions {
  static const String bisiklet = 'bisiklet';
}

const Set<RelationType> _buyuklerVeAkrabalar = <RelationType>{
  RelationType.anneanne,
  RelationType.babaanne,
  RelationType.anneTarafiDede,
  RelationType.babaTarafiDede,
  RelationType.teyze,
  RelationType.dayi,
  RelationType.hala,
  RelationType.amca,
};

const List<GameEvent> kEventPool = <GameEvent>[
  // --- Çocukluk / mahalle ------------------------------------------------
  GameEvent(
    id: 'mahalle_ilk_oyun',
    category: EventCategory.mahalle,
    text: 'Sokakta senden büyük çocuklar oyun kuruyor. Biri sana dönüp '
        '"sen de var mısın?" diye soruyor.',
    requirement: EventRequirement(minAge: 5, maxAge: 8),
    choices: <EventChoice>[
      EventChoice(
        id: 'katil',
        label: 'Varım de',
        resultText: 'Oyuna girdin. Kuralları yolda öğrendin, birkaç kez '
            'ebe kaldın ama akşam eve gülerek döndün.',
        happiness: 4,
        charisma: 3,
      ),
      EventChoice(
        id: 'izle',
        label: 'Kenardan izle',
        resultText: 'Duvarın dibinde oturup izledin. Oyunu ezberledin; '
            'oynamak başka şeymiş.',
        intelligence: 2,
        happiness: -1,
      ),
    ],
  ),
  GameEvent(
    id: 'komsu_televizyonu',
    category: EventCategory.mahalle,
    text: 'Elektrikler kesilince bütün sokak apartman girişinde toplandı. '
        'Birileri mum yaktı, birileri hikâye anlatmaya başladı.',
    requirement: EventRequirement(minAge: 6, maxAge: 13),
    choices: <EventChoice>[
      EventChoice(
        id: 'dinle',
        label: 'Hikâyeleri dinle',
        resultText: 'Anlatılanların yarısı abartıydı, yarısı gerçek. '
            'Hangisinin hangisi olduğunu hâlâ bilmiyorsun.',
        happiness: 3,
        intelligence: 1,
      ),
      EventChoice(
        id: 'anlat',
        label: 'Sen de bir şey anlat',
        resultText: 'Sesin ilk cümlede titredi, sonra düzeldi. '
            'Sonunda kalabalık sana döndü.',
        charisma: 4,
        happiness: 2,
      ),
    ],
  ),

  // --- Okul ve iz bırakan seçim -----------------------------------------
  GameEvent(
    id: 'okul_ilk_gun',
    category: EventCategory.okul,
    text: 'Okulun ilk günü. Sıranın hangi tarafına oturacağını bile '
        'bilmiyorsun; herkes birbirine bakıyor.',
    requirement: EventRequirement(minAge: 6, maxAge: 8, requiresSchoolStudent: true),
    choices: <EventChoice>[
      EventChoice(
        id: 'on_sira',
        label: 'En öne otur',
        resultText: 'Ön sırada tahtaya en yakın yerdesin. Öğretmen adını '
            'ilk günden öğrendi.',
        intelligence: 3,
        happiness: 1,
      ),
      EventChoice(
        id: 'arka_sira',
        label: 'Arkalara geç',
        resultText: 'Arka sırada pencere kenarını kaptın. Dışarıyı '
            'izlemek dersten daha kolaydı.',
        happiness: 3,
        intelligence: -1,
      ),
    ],
  ),
  GameEvent(
    id: 'arkadasi_savunma',
    category: EventCategory.okul,
    text: 'Teneffüste sınıftan biri, sessiz bir arkadaşınla alay ediyor. '
        'Etraftaki herkes sana bakıyor.',
    requirement: EventRequirement(
      minAge: 9,
      maxAge: 13,
      requiresSchoolStudent: true,
      forbiddenFlags: <String>{
        StoryFlags.arkadasiniSavundu,
        StoryFlags.sessizKaldi,
      },
    ),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'savun',
        label: 'Arkadaşını savun',
        resultText: 'Araya girdin. Ortalık bir an sessizleşti; o gün '
            'kimse bir şey demedi ama arkadaşın sana baktı.',
        charisma: 3,
        happiness: 2,
        addFlags: <String>{StoryFlags.arkadasiniSavundu},
      ),
      EventChoice(
        id: 'sus',
        label: 'Sessiz kal',
        resultText: 'Başını önüne eğdin. Zil çaldığında herkes dağıldı, '
            'içindeki sıkıntı dağılmadı.',
        happiness: -4,
        addFlags: <String>{StoryFlags.sessizKaldi},
      ),
    ],
  ),

  // --- Geçmiş seçimin görünür devamı (D-022) -----------------------------
  GameEvent(
    id: 'savundugun_arkadas',
    category: EventCategory.okul,
    text: 'Yıllar önce savunduğun arkadaşın seni buldu. "O gün araya '
        'girmeseydin okulu bırakacaktım" diyor ve bir işte beraber '
        'çalışmayı teklif ediyor.',
    requirement: EventRequirement(
      minAge: 15,
      maxAge: 20,
      requiredFlags: <String>{StoryFlags.arkadasiniSavundu},
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'kabul',
        label: 'Teklifi kabul et',
        resultText: 'Birlikte çalışmaya başladınız. İşin kendisinden çok, '
            'birinin seni hatırlamış olması iyi geldi.',
        happiness: 6,
        charisma: 3,
      ),
      EventChoice(
        id: 'tesekkur',
        label: 'Teşekkür et, kendi yolundan git',
        resultText: 'Teklifini kibarca geri çevirdin. Ayrılırken '
            '"aramızda kalsın, o gün kahramandın" dedi.',
        happiness: 4,
      ),
    ],
  ),
  GameEvent(
    id: 'sessiz_kaldigin_gun',
    category: EventCategory.okul,
    text: 'O gün alay edilen arkadaşınla yıllar sonra karşılaştın. '
        'Seni tanıdı, selam verdi ve hızlıca uzaklaştı.',
    requirement: EventRequirement(
      minAge: 15,
      maxAge: 20,
      requiredFlags: <String>{StoryFlags.sessizKaldi},
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'ozur',
        label: 'Peşinden git ve özür dile',
        resultText: 'Nefes nefese yetiştin. "Biliyorum" dedi, "çocuktuk." '
            'İkinizin de yükü biraz hafifledi.',
        happiness: 5,
        charisma: 2,
      ),
      EventChoice(
        id: 'birak',
        label: 'Olduğun yerde kal',
        resultText: 'Arkasından baktın. Söylenmemiş cümle hâlâ '
            'boğazında duruyor.',
        happiness: -3,
      ),
    ],
  ),

  // --- Varlık zinciri: sahip olmadığın şey için olay çıkmaz --------------
  GameEvent(
    id: 'bisiklet_hediyesi',
    category: EventCategory.aile,
    text: '{kisi} eve ikinci el ama tertemiz bir bisikletle geldi. '
        '"{bag} olarak bu kadarını yapabildim" diyor.',
    requirement: EventRequirement(
      minAge: 8,
      maxAge: 13,
      livingRelations: <RelationType>{
        RelationType.baba,
        RelationType.anne,
        RelationType.anneTarafiDede,
        RelationType.babaTarafiDede,
        RelationType.amca,
        RelationType.dayi,
      },
    ),
    weight: 2,
    choices: <EventChoice>[
      EventChoice(
        id: 'sarilarak',
        label: 'Sarılıp teşekkür et',
        resultText: 'Bisikleti o gün akşama kadar bırakmadın. '
            'Zincir yağı kokusu hâlâ aklında.',
        happiness: 6,
        bond: 8,
        addPossessions: <String>{Possessions.bisiklet},
      ),
      EventChoice(
        id: 'sessiz',
        label: 'Sessizce al',
        resultText: 'Teşekkür etmeyi unuttun. Bisiklet senin oldu ama '
            '{kisi} bir an duraksadı.',
        happiness: 3,
        bond: -2,
        addPossessions: <String>{Possessions.bisiklet},
      ),
    ],
  ),
  GameEvent(
    id: 'bisiklet_zinciri',
    category: EventCategory.kisisel,
    text: 'Bisikletinin zinciri yokuş ortasında koptu. Eve kadar itmek '
        'yarım saat sürer.',
    requirement: EventRequirement(
      minAge: 10,
      maxAge: 18,
      requiredPossessions: <String>{Possessions.bisiklet},
    ),
    weight: 2,
    choices: <EventChoice>[
      EventChoice(
        id: 'tamir',
        label: 'Kendin tamir etmeye çalış',
        resultText: 'Elin yağ içinde kaldı ama zinciri taktın. '
            'Bir şeyi kendin onarmanın tadı başkaymış.',
        intelligence: 3,
        happiness: 2,
      ),
      EventChoice(
        id: 'it',
        label: 'İterek eve götür',
        resultText: 'Yokuşu bisikleti iterek çıktın. Bacakların ağrıdı, '
            'canın sıkılmadı.',
        health: 2,
      ),
    ],
  ),

  // --- Aile ---------------------------------------------------------------
  GameEvent(
    id: 'bayram_ziyareti',
    category: EventCategory.aile,
    text: 'Bayram sabahı {kisi} sizi bekliyor. Kapıda kolonya, masada '
        'şeker, ortada herkesin bildiği ama yine anlatılan hikâyeler var.',
    requirement: EventRequirement(
      minAge: 6,
      livingRelations: _buyuklerVeAkrabalar,
    ),
    repeatable: true,
    choices: <EventChoice>[
      EventChoice(
        id: 'kal',
        label: 'Akşama kadar kal',
        resultText: 'Gün boyu kaldın. {kisi} anlattıkça anlattı, sen '
            'dinledikçe dinledin.',
        happiness: 4,
        bond: 6,
      ),
      EventChoice(
        id: 'kisa',
        label: 'Elini öpüp erken çık',
        resultText: 'Kısa bir ziyaret oldu. {kisi} bir şey demedi ama '
            'kapıda biraz fazla bekledi.',
        happiness: 1,
        bond: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'aile_sitemi',
    category: EventCategory.aile,
    text: '{kisi} uzun zamandır senden haber alamadığını söylüyor: '
        '"Aynı evdeyiz ama seni günlerdir doğru dürüst görmedim."',
    requirement: EventRequirement(
      minAge: 8,
      requiresNeglectedRelative: true,
      requireSameHousehold: true,
    ),
    repeatable: true,
    weight: 2,
    choices: <EventChoice>[
      EventChoice(
        id: 'otur',
        label: 'Bırak elindekini, otur konuş',
        resultText: '{kisi} ile uzun uzun oturdunuz. Sitem, yerini '
            'sohbete bıraktı.',
        happiness: 3,
        bond: 7,
      ),
      EventChoice(
        id: 'sonra',
        label: '"Sonra konuşuruz" de',
        resultText: '{kisi} başını salladı. Konu kapandı ama '
            'kapanmamış gibi durdu.',
        happiness: -2,
        bond: -4,
      ),
    ],
  ),

  // --- Yetişkinliğe giriş: öğrenci olmayana üniversite olayı çıkmaz ------
  GameEvent(
    id: 'lise_sonrasi',
    category: EventCategory.yetiskinlik,
    text: 'Okul bitti. Herkes sana aynı soruyu soruyor: bundan sonra ne '
        'yapacaksın?',
    requirement: EventRequirement(
      minAge: 18,
      maxAge: 19,
      forbiddenFlags: <String>{
        StoryFlags.universitede,
        StoryFlags.calismaHayati,
      },
    ),
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'universite',
        label: 'Üniversiteye devam et',
        resultText: 'Kaydını yaptırdın. Yeni bir şehir, yeni bir sıra, '
            'yine en öndeki boş yer.',
        intelligence: 4,
        happiness: 2,
        addFlags: <String>{StoryFlags.universitede},
      ),
      EventChoice(
        id: 'calis',
        label: 'Çalışmaya başla',
        resultText: 'İşe girdin. İlk gün eve yorgun döndün ama '
            'yorgunluğun bir karşılığı vardı.',
        happiness: 2,
        health: -1,
        addFlags: <String>{StoryFlags.calismaHayati},
      ),
    ],
  ),
  GameEvent(
    id: 'universite_ilk_hafta',
    category: EventCategory.yetiskinlik,
    text: 'Üniversitede ilk haftan. Kimse kimseyi tanımıyor, herkes '
        'tanıyormuş gibi davranıyor.',
    requirement: EventRequirement(
      minAge: 18,
      maxAge: 24,
      requiredFlags: <String>{StoryFlags.universitede},
    ),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'kulup',
        label: 'Bir kulübe yazıl',
        resultText: 'Kulüp odasında ilk gün üç kişiydiniz. Sonra '
            'kalabalıklaştı, sen ilk gelenlerdendin.',
        charisma: 4,
        happiness: 3,
      ),
      EventChoice(
        id: 'kutuphane',
        label: 'Kütüphaneye kapan',
        resultText: 'Kütüphanenin en dip masası senin oldu. Sessizlik '
            'sana iyi geldi.',
        intelligence: 4,
        happiness: 1,
      ),
    ],
  ),
  // --- Okul paketi -------------------------------------------------------
  // Olaylar yaşa değil **eğitim durumuna** bakar: okula başlamamış veya
  // okulu bitirmiş karaktere okul olayı çıkmaz.
  GameEvent(
    id: 'okul_sira_arkadasi',
    category: EventCategory.okul,
    text: 'Yan sıradaki çocuk silgisini ikiye bölmüş, yarısını sana '
        'uzatıyor. "Benimkini kaybedersem seninkini isterim ama" diyor.',
    requirement: EventRequirement(
      requiresSchoolStudent: true,
      minGrade: 1,
      maxGrade: 4,
      forbiddenFlags: <String>{
        StoryFlags.okuldaArkadasEdindi,
        StoryFlags.okuldaCekingen,
      },
    ),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'tanis',
        label: 'Al ve adını sor',
        resultText: 'Adı {kisi}. O gün teneffüste de yan yana oturdunuz; '
            'ertesi gün sırayı kimse size sormadan ayırdınız.',
        happiness: 4,
        charisma: 2,
        bond: 8,
        addFlags: <String>{StoryFlags.okuldaArkadasEdindi},
        startsSchoolFriendship: true,
      ),
      EventChoice(
        id: 'cekin',
        label: '"Gerek yok" de',
        resultText: 'Silgiyi almadın. Çocuk yarısını sıranın kenarına '
            'bıraktı, sen de almadın; ikiniz de bir şey demediniz.',
        happiness: -2,
        addFlags: <String>{StoryFlags.okuldaCekingen},
      ),
    ],
  ),
  GameEvent(
    id: 'teneffus_oyun_daveti',
    category: EventCategory.okul,
    text: 'Zil çaldı, {kisi} kapıda seni bekliyor: "Bahçede yer tuttuk, '
        'sensiz başlamayız."',
    requirement: EventRequirement(
      requiresSchoolStudent: true,
      livingRelations: <RelationType>{RelationType.arkadas},
    ),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'katil',
        label: 'Çantayı bırak, koş',
        resultText: 'Zil çalana kadar bahçedeydiniz. Dizin sıyrıldı, '
            'kimse fark etmedi; {kisi} hâlâ gülüyordu.',
        happiness: 5,
        health: 1,
        charisma: 1,
        bond: 5,
      ),
      EventChoice(
        id: 'calis',
        label: 'Sırada kal, derse bak',
        resultText: 'Teneffüsü kitabın başında geçirdin. Konuyu anladın '
            'ama bahçeden gelen sesler bir yerini tırmaladı.',
        intelligence: 3,
        happiness: -2,
        bond: -2,
      ),
    ],
  ),
  GameEvent(
    id: 'arkadas_odev_yardimi',
    category: EventCategory.okul,
    text: '{kisi} defterini önüne koydu: "Bunu hiç anlamadım, yarın '
        'kontrol var. Bir bakar mısın?"',
    requirement: EventRequirement(
      requiresSchoolStudent: true,
      minGrade: 2,
      maxGrade: 8,
      livingRelations: <RelationType>{RelationType.arkadas},
      forbiddenFlags: <String>{
        StoryFlags.arkadasaYardimEtti,
        StoryFlags.arkadasaYardimEtmedi,
      },
    ),
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'yardim',
        label: 'Otur, birlikte çöz',
        resultText: 'Teneffüsü verdin ama {kisi} sonunda kendi çözdü. '
            '"Sen anlatınca oluyor" dedi.',
        intelligence: 2,
        charisma: 1,
        bond: 9,
        addFlags: <String>{StoryFlags.arkadasaYardimEtti},
      ),
      EventChoice(
        id: 'reddet',
        label: '"Benim de işim var" de',
        resultText: '{kisi} defterini sessizce kapattı. Bir şey demedi, '
            'ertesi gün de sormadı.',
        happiness: -2,
        bond: -7,
        addFlags: <String>{StoryFlags.arkadasaYardimEtmedi},
      ),
    ],
  ),
  GameEvent(
    id: 'ogretmen_sorusu',
    category: EventCategory.okul,
    text: 'Öğretmen tahtadaki soruyu gösterip sınıfa baktı: "Kim '
        'deneyecek?" Kimse parmak kaldırmıyor, cevabı biliyorsun.',
    requirement: EventRequirement(
      requiresSchoolStudent: true,
      minGrade: 2,
      forbiddenFlags: <String>{StoryFlags.dersteSozAldi},
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'kaldir',
        label: 'Parmak kaldır',
        resultText: 'Tahtaya kalktın, elin titredi ama soruyu çözdün. '
            'Yerine otururken sınıf hâlâ sana bakıyordu.',
        intelligence: 3,
        charisma: 3,
        happiness: 2,
        addFlags: <String>{StoryFlags.dersteSozAldi},
      ),
      EventChoice(
        id: 'sessiz',
        label: 'Sessiz kal',
        resultText: 'Başka biri kalktı ve yanlış yaptı. Doğrusu hâlâ '
            'defterinin kenarında yazılı duruyor.',
        happiness: -2,
        intelligence: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'yardimin_karsiligi',
    category: EventCategory.okul,
    text: 'Kantinde paran yetmedi. Arkandan {kisi} geldi, bozuklukları '
        'tezgâha bıraktı: "O gün defterime baktın ya, ödeştik."',
    requirement: EventRequirement(
      requiresSchoolStudent: true,
      minGrade: 4,
      livingRelations: <RelationType>{RelationType.arkadas},
      requiredFlags: <String>{StoryFlags.arkadasaYardimEtti},
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'tesekkur',
        label: 'Teşekkür et',
        resultText: 'Bir dahakine senden dediniz. {kisi} ile aranızda '
            'sayılmayan bir hesap açıldı.',
        happiness: 5,
        bond: 6,
      ),
      EventChoice(
        id: 'geri_ver',
        label: 'Parayı ertesi gün geri ver',
        resultText: 'Ertesi gün bozuklukları geri verdin. {kisi} aldı ama '
            '"gerek yoktu" der gibi baktı.',
        happiness: 2,
        charisma: 1,
        bond: 2,
      ),
    ],
  ),

  // --- Romantik hikâye: tanışma → sevgili → ayrılık → eski sevgili --------
  GameEvent(
    id: 'ilk_goz_agrisi',
    category: EventCategory.kisisel,
    text: 'Durakta her gün aynı saatte karşılaştığın biri var. Bugün '
        'otobüs gecikti ve ikiniz de aynı tabelaya bakıyorsunuz.',
    requirement: EventRequirement(
      minAge: 15,
      maxAge: 22,
      forbiddenFlags: <String>{
        StoryFlags.romantikIlgi,
        StoryFlags.romantikGecti,
      },
    ),
    // prototypeOnly: romantik zincir ilk prototipte gerçekten oynanabilmeli
    // (D-030); yine de her hayatta zorunlu değildir.
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'selam',
        label: 'Selam ver, konuş',
        resultText: 'İki cümle kurdunuz, otobüs geldi. Ertesi gün yine '
            'aynı durakta, yine aynı saatte buluştunuz.',
        charisma: 2,
        happiness: 2,
        addFlags: <String>{StoryFlags.romantikIlgi},
      ),
      EventChoice(
        id: 'gec',
        label: 'Bir şey deme',
        resultText: 'Otobüse bindin, bakıştınız, o kadar. Bazı cümleler '
            'kurulmadan biter.',
        happiness: -1,
        addFlags: <String>{StoryFlags.romantikGecti},
      ),
    ],
  ),
  GameEvent(
    id: 'cikma_teklifi',
    category: EventCategory.kisisel,
    text: 'Duraktaki sohbetler aylardır sürüyor. Bugün ikiniz de '
        'konuşmayı uzatmak için bahane arıyorsunuz.',
    requirement: EventRequirement(
      minAge: 15,
      maxAge: 25,
      requiredFlags: <String>{StoryFlags.romantikIlgi},
      forbiddenFlags: <String>{
        StoryFlags.romantikIliskide,
        StoryFlags.romantikBitti,
      },
    ),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'teklif',
        label: 'Açıl ve teklif et',
        resultText: 'Adının {kisi} olduğunu o gün öğrendin. Artık '
            'birliktesiniz; Aile bölümünde onu görebilirsin.',
        happiness: 8,
        charisma: 2,
        bond: 5,
        // İlişki izleri Romance içinde yönetilir; burada tekrarlanmaz.
        startsRomance: true,
      ),
      EventChoice(
        id: 'erteleme',
        label: 'Bugün de erteledin',
        resultText: 'Cümleyi yine kuramadın. Otobüs geldi, sen bindin.',
        happiness: -2,
      ),
    ],
  ),
  GameEvent(
    id: 'iliski_tartismasi',
    category: EventCategory.kisisel,
    text: '{kisi} ile uzun zamandır aynı konuda tartışıyorsunuz. Bugün '
        'konu yine açıldı ve ikiniz de yorgunsunuz.',
    requirement: EventRequirement(
      minAge: 15,
      livingRelations: <RelationType>{RelationType.sevgili},
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'konus',
        label: 'Oturup konuş',
        resultText: 'Uzun konuştunuz. Mesele bitmedi ama ikiniz de '
            'birbirinizi daha iyi anladınız.',
        happiness: 3,
        bond: 6,
      ),
      EventChoice(
        id: 'ayril',
        label: 'Ayrılmayı teklif et',
        resultText: 'Konuşma bitmeden karar verdiniz. {kisi} ile '
            'yollarınız ayrıldı.',
        happiness: -6,
        // İlişki izleri Romance içinde yönetilir; burada tekrarlanmaz.
        endsRomance: true,
      ),
    ],
  ),
  GameEvent(
    id: 'eski_sevgili_karsilasma',
    category: EventCategory.kisisel,
    text: '{kisi} ile bir caddede karşılaştın. Aynı durak, aynı saat '
        'değil ama aynı yüz.',
    requirement: EventRequirement(
      minAge: 15,
      livingRelations: <RelationType>{RelationType.eskiSevgili},
      requiredFlags: <String>{StoryFlags.romantikBitti},
    ),
    weight: 2,
    choices: <EventChoice>[
      EventChoice(
        id: 'selamlas',
        label: 'Selamlaş',
        resultText: 'Kısa konuştunuz. Eski hâliniz değilsiniz ama '
            'yabancı da değilsiniz.',
        happiness: 2,
      ),
      EventChoice(
        id: 'gormezden',
        label: 'Görmezden gel',
        resultText: 'Karşı kaldırıma geçtin. Arkana bakmadın; bakmak '
            'istedin.',
        happiness: -2,
      ),
    ],
  ),

  GameEvent(
    id: 'ilk_maas',
    category: EventCategory.yetiskinlik,
    text: 'İlk maaşını elden aldın. Zarf ince ama senin.',
    requirement: EventRequirement(
      minAge: 18,
      maxAge: 24,
      requiredFlags: <String>{StoryFlags.calismaHayati},
    ),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'eve',
        label: 'Eve bir şeyler al',
        resultText: 'Zarfın yarısıyla eve alışveriş yaptın. Kimse bir şey '
            'demedi, herkes gördü.',
        happiness: 4,
        money: 1500, // prototypeOnly
      ),
      EventChoice(
        id: 'kendine',
        label: 'Kendine sakla',
        resultText: 'Zarfı olduğu gibi kaldırdın. İlk defa kendine ait '
            'bir şeyin var.',
        happiness: 3,
        charisma: 1,
        money: 3000, // prototypeOnly
      ),
    ],
  ),
];
