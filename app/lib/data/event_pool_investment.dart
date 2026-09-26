/// Yatırım olayları (D-162).
///
/// **Hiçbiri yatırım tavsiyesi vermez.** "Şunu al kesin kazanırsın" yok,
/// "en iyi yatırım şudur" yok. Olaylar bir insanın para karşısındaki
/// hâlini anlatır: merak, panik, açgözlülük, pişmanlık, sabır. Kararın
/// sonucu bazen iyi bazen kötü çıkar; hiçbir seçenek garantili değildir.
///
/// **Hiçbiri portföyü kendi kendine değiştirmez.** Yatırım al/sat yalnızca
/// Yatırımlar ekranından yapılır (D-162); olaylar para, mutluluk ve
/// yakınlık üzerinden işler. Böylece aynı işi yapan ikinci bir ekonomi
/// motoru doğmaz.
///
/// Portföyü olmayana "hisselerin düştü" denmez: `requiresPortfolio` ve
/// `forbidsPortfolio` kapıları bunu sağlar.
///
/// Metin üslubu `docs/WRITING_STYLE_TR.md`: doğal, kısa, yer yer esprili.
/// Ağırlıklar ve para tutarları `prototypeOnly`'dir (Q-165).
library;

import '../domain/models/game_event.dart';
import '../domain/models/relation.dart';

const List<GameEvent> kInvestmentEvents = <GameEvent>[
  // --- Henüz yatırımı olmayanlar -----------------------------------------
  GameEvent(
    id: 'yatirim_ilk_merak',
    category: EventCategory.kisisel,
    text: 'Maaş yattı, ay sonuna kadar bir şey kalmayacak gibi duruyor. '
        'Kafanda bir ses "bunun bir kısmını kenara koysan?" diyor.',
    requirement: EventRequirement(
      minAge: 20,
      maxAge: 55,
      forbidsPortfolio: true,
    ),
    repeatable: true,
    minAgeGap: 6,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'arastir',
        label: 'Biraz araştır',
        resultText: 'Akşam boyunca okudun. Yarısını anlamadın ama artık '
            'Varlıklar\'daki Yatırımlar\'ın ne olduğunu biliyorsun.',
        happiness: 2,
        intelligence: 1,
      ),
      EventChoice(
        id: 'sonra',
        label: 'Şimdi sırası değil',
        resultText: 'Kapattın gitti. Zaten ayın on beşi, hesap ortada.',
        happiness: -1,
      ),
    ],
  ),
  GameEvent(
    id: 'yatirim_arkadas_ovunuyor',
    category: EventCategory.kisisel,
    text: '{kisi} sohbetin ortasında "ben geçen yıl şu kadar kazandım" '
        'diye girdi. Ne kadar kaybettiğinden hiç bahsetmedi.',
    requirement: EventRequirement(
      minAge: 22,
      livingRelations: <RelationType>{RelationType.arkadas},
      requireReachable: true,
    ),
    repeatable: true,
    minAgeGap: 7,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'dinle',
        label: 'Dinle, not al',
        resultText: 'Yarısı hava, yarısı işe yarar bilgiydi. Ayırt etmeyi '
            'öğrenmek de bir şey.',
        intelligence: 1,
        bond: 2,
      ),
      EventChoice(
        id: 'takil',
        label: 'Takıl biraz',
        resultText: '"Kaybettiğin yılı da anlat" dedin. Konu bir anda '
            'hava durumuna geçti.',
        happiness: 3,
        charisma: 2,
        bond: -1,
      ),
    ],
  ),
  GameEvent(
    id: 'yatirim_amca_tavsiyesi',
    category: EventCategory.aile,
    text: 'Çay içerken {kisi} sesini alçaltıp "sana bir şey söyleyeceğim, '
        'kimseye demeyeceksin" dedi. Anlattığı şey kulağa fazla iyi geliyor.',
    requirement: EventRequirement(
      minAge: 22,
      livingRelations: <RelationType>{RelationType.amca, RelationType.dayi},
      requireReachable: true,
    ),
    repeatable: true,
    minAgeGap: 9,
    weight: 2,
    choices: <EventChoice>[
      EventChoice(
        id: 'kibar',
        label: 'Kibarca geç',
        resultText: '"Bakarım" deyip konuyu değiştirdin. Kırılmadı, yine '
            'anlatacak.',
        bond: 1,
      ),
      EventChoice(
        id: 'sorgula',
        label: 'Detay sor',
        resultText: 'Üç soru sordun, üçüne de net cevap gelmedi. Kendi '
            'kafanda mesele kapandı.',
        intelligence: 2,
      ),
    ],
  ),

  // --- Portföyü olanlar: iyi yıl -----------------------------------------
  GameEvent(
    id: 'yatirim_iyi_yil_gurur',
    category: EventCategory.kisisel,
    text: 'Yatırımlar ekranını açtın, rakam beklediğinden iyi. İçinden '
        '"ben bu işi biliyorum" demek geçiyor.',
    requirement: EventRequirement(
      minAge: 20,
      requiresPortfolio: true,
    ),
    repeatable: true,
    minAgeGap: 5,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'sakin',
        label: 'Sakin ol',
        resultText: 'Ekranı kapattın. İyi yılın da kötü yılın da geçtiğini '
            'biliyorsun artık.',
        happiness: 4,
      ),
      EventChoice(
        id: 'anlat',
        label: 'Herkese anlat',
        resultText: 'Üç ayrı sohbette anlattın. Dinleyenlerin yüz ifadesi '
            'giderek soğudu.',
        happiness: 5,
        charisma: -1,
      ),
    ],
  ),
  GameEvent(
    id: 'yatirim_kar_harcama_istegi',
    category: EventCategory.kisisel,
    text: 'Portföy iyi durumda. Aklına hemen bir liste geldi: telefon, '
        'tatil, bir de şu çoktandır istediğin şey.',
    requirement: EventRequirement(
      minAge: 21,
      requiresPortfolio: true,
    ),
    repeatable: true,
    minAgeGap: 6,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'kendine_bak',
        label: 'Küçük bir şey al',
        resultText: 'Kendine ufak bir şey aldın. Portföye dokunmadın, '
            'cebe biraz dokundu.',
        happiness: 6,
        money: -4000,
      ),
      EventChoice(
        id: 'dur',
        label: 'Elleme',
        resultText: 'Listeyi kapattın. Ay sonunda o listeyi neden yaptığını '
            'hatırlamıyorsun bile.',
        happiness: 1,
      ),
    ],
  ),

  // --- Portföyü olanlar: kötü yıl ----------------------------------------
  GameEvent(
    id: 'yatirim_dusus_panik',
    category: EventCategory.kisisel,
    text: 'Sabah ekrana baktın, rakam gece boyunca aşağı gitmiş. Elin '
        'kendiliğinden "sat" düğmesine gidiyor.',
    requirement: EventRequirement(
      minAge: 20,
      requiresPortfolio: true,
    ),
    repeatable: true,
    minAgeGap: 5,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'bekle',
        label: 'Ekranı kapat, bekle',
        resultText: 'Telefonu bıraktın. Akşama kadar üç kere açıp kapattın '
            'ama bir şey yapmadın.',
        happiness: -2,
      ),
      EventChoice(
        id: 'dusun',
        label: 'Oturup neden aldığını hatırla',
        resultText: 'Niye aldığını yazdın bir kenara. Sebep hâlâ duruyorsa '
            'düşen rakam bir şey değil.',
        happiness: -1,
        intelligence: 2,
      ),
    ],
  ),
  GameEvent(
    id: 'yatirim_kriz_haberleri',
    category: EventCategory.kisisel,
    text: 'Televizyonda herkes aynı şeyi konuşuyor, hepsi farklı şey '
        'söylüyor. Biri "dip burası" diyor, öbürü "daha var".',
    requirement: EventRequirement(
      minAge: 20,
      requiresPortfolio: true,
    ),
    repeatable: true,
    minAgeGap: 6,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'kapat',
        label: 'Kapat televizyonu',
        resultText: 'Kapattın. Kimsenin bilmediği bir şeyi bilen kimse '
            'yoktu zaten.',
        happiness: 2,
      ),
      EventChoice(
        id: 'izle',
        label: 'Sonuna kadar izle',
        resultText: 'İki saat izledin. Öğrendiğin tek şey: ekranda kimse '
            '"bilmiyorum" demiyor.',
        happiness: -3,
      ),
    ],
  ),
  GameEvent(
    id: 'yatirim_es_soruyor',
    category: EventCategory.aile,
    text: '{kisi} akşam yemeğinde sordu: "şu yatırım işi ne durumda?" '
        'Sesinde merak da var, biraz da tedirginlik.',
    requirement: EventRequirement(
      minAge: 22,
      livingRelations: <RelationType>{RelationType.es},
      requiresPortfolio: true,
    ),
    repeatable: true,
    minAgeGap: 5,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'goster',
        label: 'Ekranı aç, göster',
        resultText: 'İkiniz birlikte baktınız. Rakamı beraber görmek '
            'ikinize de iyi geldi.',
        happiness: 3,
        bond: 6,
      ),
      EventChoice(
        id: 'gecistir',
        label: 'Geçiştir',
        resultText: '"İyi gidiyor" dedin, konuyu kapattın. {kisi} bir şey '
            'demedi ama yüzünden okundu.',
        bond: -4,
      ),
    ],
  ),

  // --- Fırsat ve baskı ---------------------------------------------------
  GameEvent(
    id: 'yatirim_hizli_zengin_teklifi',
    category: EventCategory.kisisel,
    text: 'Telefonda tanımadığın bir numara. Karşıdaki adam çok kibar, çok '
        'ikna edici ve "bugün son gün" diyor.',
    requirement: EventRequirement(minAge: 20),
    repeatable: true,
    minAgeGap: 6,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'kapat',
        label: 'Telefonu kapat',
        resultText: 'Kapattın. Üç gün daha aradı, açmadın.',
        happiness: 1,
        intelligence: 1,
      ),
      EventChoice(
        id: 'dinle',
        label: 'Bir dinle bakalım',
        resultText: 'Yirmi dakika dinledin. Anlattığı şeyin ne olduğunu '
            'hâlâ bilmiyorsun; o da bilmiyor gibiydi.',
        happiness: -2,
      ),
    ],
  ),
  GameEvent(
    id: 'yatirim_is_arkadasi_grubu',
    category: EventCategory.kisisel,
    text: 'İş yerinde bir grup kurulmuş, her gün "şuna girdim, buna '
        'girdim" yazıyorlar. Seni de eklediler.',
    requirement: EventRequirement(
      minAge: 22,
      maxAge: 60,
      requiresEmployed: true,
    ),
    repeatable: true,
    minAgeGap: 8,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'sessize_al',
        label: 'Sessize al',
        resultText: 'Bildirimleri kapattın. Ara sıra bakıyorsun, kimse '
            'kaybını yazmıyor.',
        happiness: 2,
      ),
      EventChoice(
        id: 'takip',
        label: 'Her mesajı takip et',
        resultText: 'Gün boyu telefona baktın. Akşam işin yarısı yarım '
            'kalmıştı.',
        happiness: -1,
        intelligence: -1,
      ),
    ],
  ),
  GameEvent(
    id: 'yatirim_ev_birikimi',
    category: EventCategory.kisisel,
    text: 'Ev için biriktirdiğin para bir kenarda duruyor. "Bunu bir yıl '
        'çalıştırsam" diye düşünmeden geçemiyorsun.',
    requirement: EventRequirement(
      minAge: 24,
      maxAge: 55,
      forbidsProperty: true,
    ),
    repeatable: true,
    minAgeGap: 8,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'guvenli',
        label: 'Bağlanmayan bir yerde dursun',
        resultText: 'Parayı kilitlemeye elin gitmedi. Ev için lazım olursa '
            'hemen ulaşabilmek istiyorsun.',
        happiness: 2,
      ),
      EventChoice(
        id: 'dusun',
        label: 'Hesabı yap',
        resultText: 'Kâğıt kalemle oturdun. Bir yıl bağlamanın ne '
            'kazandırıp ne kaybettireceğini gördün.',
        intelligence: 2,
      ),
    ],
  ),

  // --- Uzun vadeli, geçmişi hatırlayan -----------------------------------
  GameEvent(
    id: 'yatirim_yillar_sonra_bakis',
    category: EventCategory.kisisel,
    text: 'Eski bir defterde ilk yatırım notunu buldun. O gün yazdığın '
        'rakama bugün bakınca gülümsüyorsun.',
    requirement: EventRequirement(
      minAge: 40,
      requiresPortfolio: true,
    ),
    repeatable: true,
    minAgeGap: 12,
    weight: 2,
    choices: <EventChoice>[
      EventChoice(
        id: 'sakla',
        label: 'Defteri sakla',
        resultText: 'Defteri çekmeceye geri koydun. Bir gün birine '
            'göstermek istersin.',
        happiness: 4,
      ),
      EventChoice(
        id: 'yaz',
        label: 'Bugünü de yaz',
        resultText: 'Altına bugünün tarihini ve rakamı yazdın. Sıradaki '
            'satırı kim okuyacak bilinmez.',
        happiness: 5,
        intelligence: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'yatirim_cocuga_anlatma',
    category: EventCategory.aile,
    text: '{kisi} sordu: "para nasıl büyüyor?" Cevabı verirken kendi '
        'kafandaki karışıklığı fark ediyorsun.',
    requirement: EventRequirement(
      minAge: 30,
      livingRelations: <RelationType>{RelationType.cocuk},
      personMinAge: 8,
      requiresPortfolio: true,
    ),
    repeatable: true,
    minAgeGap: 7,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'basit',
        label: 'Basit anlat',
        resultText: 'Kumbara örneğiyle anlattın. "Ya kaybolursa?" diye '
            'sordu; iyi soru.',
        bond: 6,
        happiness: 3,
      ),
      EventChoice(
        id: 'goster',
        label: 'Ekranı göster',
        resultText: 'Rakamlara birlikte baktınız. Anladığından emin '
            'değilsin ama dikkatle dinledi.',
        bond: 4,
        intelligence: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'yatirim_emeklilik_dusunmesi',
    category: EventCategory.kisisel,
    text: 'Emeklilik artık uzak bir laf değil. Elindekine bakıp "bu ne '
        'kadar götürür" diye hesap yapıyorsun.',
    requirement: EventRequirement(
      minAge: 50,
      maxAge: 68,
      requiresPortfolio: true,
    ),
    repeatable: true,
    minAgeGap: 8,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'hesapla',
        label: 'Oturup hesapla',
        resultText: 'Kabaca bir hesap yaptın. Rakam seni ne çok korkuttu '
            'ne çok rahatlattı; en azından biliyorsun.',
        intelligence: 2,
        happiness: 1,
      ),
      EventChoice(
        id: 'ertele',
        label: 'Sonra bakarım',
        resultText: 'Ertelendi. Aynı soru gelecek yıl aynı yerde duruyor '
            'olacak.',
        happiness: -1,
      ),
    ],
  ),
  GameEvent(
    id: 'yatirim_kardes_borc_ister',
    category: EventCategory.aile,
    text: '{kisi} sıkışmış, borç istiyor. Cüzdanda o kadar yok ama '
        'yatırımın var; bozmak da elinde.',
    requirement: EventRequirement(
      minAge: 25,
      livingRelations: <RelationType>{RelationType.kardes},
      requireReachable: true,
      requiresPortfolio: true,
    ),
    repeatable: true,
    minAgeGap: 9,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'ver',
        label: 'Elinden geleni ver',
        resultText: 'Cüzdandakini verdin. {kisi} "iki ay içinde" dedi; '
            'sen de "acelesi yok" dedin.',
        money: -15000,
        bond: 10,
        happiness: 2,
      ),
      EventChoice(
        id: 'anlat',
        label: 'Durumu anlat',
        resultText: 'Neyin bağlı, neyin serbest olduğunu anlattın. '
            'Kırılmadı ama araya bir sessizlik girdi.',
        bond: -2,
      ),
    ],
  ),
];
