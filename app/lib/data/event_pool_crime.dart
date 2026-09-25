/// Suç ve hukuk olayları (D-128).
///
/// **Kapsam:** oyuncu riskli bir seçim yapar; hukuk tarafını motor
/// yürütür (`LegalEngine`). Olay metinleri **yüksek seviyededir**: suç
/// işleme yöntemi, kaçış, saklanma ya da denetimden kurtulma hiçbir
/// yerde anlatılmaz ve anlatılmayacaktır.
///
/// **Suç zorunlu içerik değildir.** Olayların hepsinde "uzaklaş",
/// "sesini çıkarma" ya da "vazgeç" gibi temiz bir kapı vardır; normal
/// oynayan biri bütün hayatını sabıkasız geçirebilir (Q-141).
///
/// Dil: `docs/WRITING_STYLE_TR.md`. Anlatıcı hafif esprili ve doğal;
/// **ciddi sonuç şakaya çevrilmez.** Polis kısa ve ciddi konuşur,
/// hâkim resmî, avukat yarı resmî; sokak ağzı yalnızca sokakta.
library;

import '../domain/economy/financial_strain.dart';
import '../domain/models/game_event.dart';
import 'item_catalog.dart';
import '../domain/models/relation.dart';

/// Bu havuzun bıraktığı izler.
abstract final class CrimeFlags {
  // Zincir 1 — Sokakta büyüyen tartışma
  static const String kavgadanCekildi = 'suc_kavgadan_cekildi';
  static const String kavgayaGirdi = 'suc_kavgaya_girdi';
  static const String kavgaPismanligi = 'suc_kavga_pismanligi';

  // Zincir 2 — Arkadaşın teklifi
  static const String teklifiReddetti = 'suc_teklifi_reddetti';
  static const String teklifeUydu = 'suc_teklife_uydu';

  // Zincir 3 — İş yerindeki açık
  static const String isyerindeSustu = 'suc_isyerinde_sustu';
  static const String isyerindeBildirdi = 'suc_isyerinde_bildirdi';
  static const String isyerindeAldi = 'suc_isyerinde_aldi';

  // Zincir 4 — Borç
  static const String borcVerdi = 'suc_borc_verdi';
  static const String borcuIsteyecek = 'suc_borcu_isteyecek';
  static const String mahkemeyeGitti = 'suc_borc_mahkemeye';

  // Zincir 5 — Tahliye sonrası
  static const String tahliyeSonrasiCalisti = 'suc_tahliye_calisti';
  static const String tahliyeSonrasiKapandi = 'suc_tahliye_kapandi';

  // Tekil olaylar
  static const String direksiyonUyarisi = 'suc_direksiyon_uyarisi';
  static const String alkolluHayir = 'suc_alkollu_hayir';
}

/// Bu havuzun kilitlediği kişi rolleri.
abstract final class CrimeRoles {
  static const String kavgaKarsisi = 'suc_kavga_karsisi';
  static const String teklifEden = 'suc_teklif_eden';
  static const String borclu = 'suc_borclu';
}

/// Suç ve hukuk olayları.
const List<GameEvent> kCrimeEvents = <GameEvent>[
  // ===================================================================
  // ZİNCİR 1 — Sokakta büyüyen tartışma (3 halka)
  // ===================================================================
  GameEvent(
    id: 'suc_gece_tartismasi',
    category: EventCategory.mahalle,
    text: 'Gece çıkışında iki laf derken sesler yükseldi. Karşı taraf '
        'da geri adım atmıyor.\n\n'
        'Yanındakiler bir sana bakıyor, bir ona.',
    requirement: EventRequirement(
      minAge: 17,
      maxAge: 45,
      forbiddenFlags: <String>{
        CrimeFlags.kavgayaGirdi,
        CrimeFlags.kavgadanCekildi,
      },
    ),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'uzaklas',
        label: 'Uzaklaş',
        resultText: 'Arkanı döndün. Birkaç laf daha geldi arkandan, '
            'duymadın. Sabah aynı sokaktan geçerken hiçbir şey olmamıştı.',
        happiness: 1,
        charisma: -1,
        addFlags: <String>{CrimeFlags.kavgadanCekildi},
      ),
      EventChoice(
        id: 'arkadasini_sok',
        label: 'Araya arkadaşını sok',
        resultText: 'Arkadaşın ikinizin arasına girdi. "Tamam abi, '
            'tamam." İki dakika sonra ortam dağıldı.',
        happiness: 1,
        charisma: 2,
        bond: 3,
        addFlags: <String>{CrimeFlags.kavgadanCekildi},
        rememberPersonAs: CrimeRoles.kavgaKarsisi,
      ),
      EventChoice(
        id: 'karsilik_ver',
        label: 'Karşılık ver',
        resultText: 'Sen daha ne olduğunu anlamadan ortalık karıştı. '
            'Sonrasını parça parça hatırlıyorsun.',
        happiness: -3,
        health: -6,
        charisma: 1,
        addFlags: <String>{CrimeFlags.kavgayaGirdi},
        crimeId: 'sokak_kavgasi',
      ),
    ],
  ),
  GameEvent(
    id: 'suc_kavga_sonrasi',
    category: EventCategory.kisisel,
    text: 'Dudağındaki şişlik indi ama olay kafandan çıkmıyor.\n\n'
        'O gece gerçekten gerekli miydi?',
    requirement: EventRequirement(
      minAge: 17,
      requiredFlags: <String>{CrimeFlags.kavgayaGirdi},
      forbiddenFlags: <String>{CrimeFlags.kavgaPismanligi},
    ),
    weight: 7,
    choices: <EventChoice>[
      EventChoice(
        id: 'bir_daha_yok',
        label: 'Bir daha yok',
        resultText: 'Kendine söz verdin. Sözü tutmak, vermekten zor.',
        happiness: 2,
        charisma: 1,
        addFlags: <String>{CrimeFlags.kavgaPismanligi},
      ),
      EventChoice(
        id: 'haklıydim',
        label: '"Haklıydım"',
        resultText: 'Kendini haklı bulmak işe yaradı; bir süre. '
            'Sonra aynı öfke aynı yerde duruyordu.',
        happiness: -1,
        charisma: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'suc_kavga_karsisindaki',
    category: EventCategory.mahalle,
    text: 'Aylar sonra markette karşılaştınız. İkiniz de aynı reyonda '
        'durdunuz.\n\nO önce baktı.',
    requirement: EventRequirement(
      minAge: 18,
      requiredFlags: <String>{CrimeFlags.kavgayaGirdi},
      personRole: CrimeRoles.kavgaKarsisi,
    ),
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'selam_ver',
        label: 'Selam ver',
        resultText: 'Başını sallayıp geçtin. O da salladı. '
            'Bazı şeyler böyle kapanıyor.',
        happiness: 2,
        charisma: 2,
        bond: 6,
      ),
      EventChoice(
        id: 'gormezden_gel',
        label: 'Görmezden gel',
        resultText: 'Reyonu değiştirdin. Kasada yine yan yana '
            'düştünüz; kimse konuşmadı.',
        happiness: -1,
      ),
    ],
  ),

  // ===================================================================
  // ZİNCİR 2 — Arkadaşın teklifi (3 halka)
  // ===================================================================
  GameEvent(
    id: 'suc_arkadasin_teklifi',
    category: EventCategory.mahalle,
    text: 'Arkadaşın sesini alçalttı. "Kolay para" dedi, sonra '
        '"kimse bir şey anlamaz" diye ekledi.\n\n'
        'Abi bu iş pek iyi kokmuyor.',
    requirement: EventRequirement(
      minAge: 17,
      maxAge: 40,
      maxComfort: FinancialComfort.zor,
      forbiddenFlags: <String>{
        CrimeFlags.teklifiReddetti,
        CrimeFlags.teklifeUydu,
      },
    ),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'reddet',
        label: '"Ben yokum"',
        resultText: 'Kısa kestin. Arkadaşın bozuldu ama üstelemedi. '
            'Eve giderken cebin yine boştu, kafan rahattı.',
        happiness: 1,
        charisma: 2,
        addFlags: <String>{CrimeFlags.teklifiReddetti},
        rememberPersonAs: CrimeRoles.teklifEden,
      ),
      EventChoice(
        id: 'vazgecir',
        label: 'Onu vazgeçirmeye çalış',
        resultText: 'Yarım saat konuştun. Sonunda "tamam ya, boş yapma" '
            'dedi. Yaptı mı bilmiyorsun ama sen yapmadın.',
        happiness: 2,
        charisma: 3,
        bond: 4,
        addFlags: <String>{CrimeFlags.teklifiReddetti},
        rememberPersonAs: CrimeRoles.teklifEden,
      ),
      EventChoice(
        id: 'uy',
        label: 'Bir kere denemekten ne olur',
        resultText: 'Bir anlık gazla girdiğin iş pahalıya patladı. '
            'Ne kadar sürdüğünü bile hatırlamıyorsun.',
        happiness: -4,
        money: 4000,
        addFlags: <String>{CrimeFlags.teklifeUydu},
        crimeId: 'kucuk_hirsizlik',
        rememberPersonAs: CrimeRoles.teklifEden,
      ),
    ],
  ),
  GameEvent(
    id: 'suc_teklif_ikinci_kez',
    category: EventCategory.mahalle,
    text: 'Aynı arkadaş yine aradı. Bu sefer daha rahat konuşuyor: '
        '"Geçen sefer oldu ya."',
    requirement: EventRequirement(
      minAge: 18,
      requiredFlags: <String>{CrimeFlags.teklifeUydu},
      personRole: CrimeRoles.teklifEden,
    ),
    weight: 7,
    choices: <EventChoice>[
      EventChoice(
        id: 'kapat',
        label: 'Telefonu kapat',
        resultText: 'Konuşmayı yarıda bıraktın. Bir daha aramadı. '
            'İyi bari.',
        happiness: 2,
        charisma: 1,
        bond: -8,
        addFlags: <String>{CrimeFlags.teklifiReddetti},
      ),
      EventChoice(
        id: 'devam',
        label: 'Bu sefer de gir',
        resultText: 'İkincisinde tedirginlik yoktu. Sonrası ilkinden '
            'kötü oldu.',
        happiness: -5,
        money: 6000,
        crimeId: 'kucuk_hirsizlik',
      ),
    ],
  ),
  GameEvent(
    id: 'suc_teklif_eden_sonu',
    category: EventCategory.mahalle,
    text: 'Mahallede laf hızlı yayılmış: o arkadaşın işi büyümüş, '
        'sonra da başına iş almış.',
    requirement: EventRequirement(
      minAge: 20,
      requiredFlags: <String>{CrimeFlags.teklifiReddetti},
      personRole: CrimeRoles.teklifEden,
    ),
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'ara',
        label: 'Ara, halini sor',
        resultText: 'Sesi yorgundu. Uzun konuşmadınız. '
            'Kapatırken "iyi ki dinlemişsin beni" dedi.',
        happiness: 1,
        charisma: 2,
        bond: 5,
      ),
      EventChoice(
        id: 'uzak_dur',
        label: 'Uzak dur',
        resultText: 'Bu sefer aramadın. Doğru mu yaptın, '
            'bir süre emin olamadın.',
        happiness: -1,
      ),
    ],
  ),

  // ===================================================================
  // ZİNCİR 3 — İş yerindeki açık (3 halka)
  // ===================================================================
  GameEvent(
    id: 'suc_isyerinde_acik',
    category: EventCategory.yetiskinlik,
    text: 'Kasadaki tutarsızlığı önce sen gördün. Kimse fark '
        'etmemiş.\n\nEkranda duran sayı iki gündür değişmiyor.',
    requirement: EventRequirement(
      minAge: 20,
      requiresEmployed: true,
      forbiddenFlags: <String>{
        CrimeFlags.isyerindeBildirdi,
        CrimeFlags.isyerindeSustu,
        CrimeFlags.isyerindeAldi,
      },
    ),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'bildir',
        label: 'Müdüre bildir',
        resultText: 'Müdür ekrana baktı, sonra sana: "İyi ki söyledin." '
            'Ertesi gün kimse konuşmadı ama yüzüne bakışları değişti.',
        happiness: 2,
        charisma: 3,
        intelligence: 1,
        addFlags: <String>{CrimeFlags.isyerindeBildirdi},
      ),
      EventChoice(
        id: 'sus',
        label: 'Sesini çıkarma',
        resultText: 'Görmedin saydın. Sayı bir hafta sonra kendiliğinden '
            'düzeldi; kimin düzelttiğini öğrenemedin.',
        happiness: -1,
        addFlags: <String>{CrimeFlags.isyerindeSustu},
      ),
      EventChoice(
        id: 'al',
        label: 'Kimse anlamaz',
        resultText: 'O ay cebin rahat etti. Sonraki ay denetim geldi.',
        happiness: -2,
        money: 25000,
        addFlags: <String>{CrimeFlags.isyerindeAldi},
        crimeId: 'is_etigi',
      ),
    ],
  ),
  GameEvent(
    id: 'suc_isyerinde_denetim',
    category: EventCategory.yetiskinlik,
    text: 'Denetim ekibi üç gün kaldı. Üçüncü gün senin masana '
        'oturdular.\n\n"Şu kalemi bir açalım."',
    requirement: EventRequirement(
      minAge: 20,
      requiredFlags: <String>{CrimeFlags.isyerindeAldi},
    ),
    weight: 8,
    choices: <EventChoice>[
      EventChoice(
        id: 'kabul',
        label: 'Kabul et',
        resultText: 'Anlattın. Odada kimse yüzüne bakmadı. '
            'En azından ikinci bir yalan kurmadın.',
        happiness: -3,
        charisma: 1,
      ),
      EventChoice(
        id: 'inkar',
        label: 'Bilmediğini söyle',
        resultText: 'İnkâr ettin. Dosya yine de yürüdü; '
            'inkâr onu durdurmuyor.',
        happiness: -4,
        charisma: -2,
      ),
    ],
  ),
  GameEvent(
    id: 'suc_isyerinde_bildirdi_sonra',
    category: EventCategory.yetiskinlik,
    text: 'Müdür kapıda seni bekledi. "Geçen seferki iş var ya" '
        'dedi.\n\nElinde bir dosya.',
    requirement: EventRequirement(
      minAge: 21,
      requiresEmployed: true,
      requiredFlags: <String>{CrimeFlags.isyerindeBildirdi},
    ),
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'kabul_et',
        label: 'Sorumluluğu al',
        resultText: 'Yeni bir işi sana verdiler. Daha fazla iş, '
            'biraz daha fazla söz hakkı.',
        happiness: 2,
        charisma: 3,
        intelligence: 2,
      ),
      EventChoice(
        id: 'istemem',
        label: 'Kalsın',
        resultText: '"Şimdilik kalsın" dedin. Müdür ısrar etmedi; '
            'dosya başka masaya gitti.',
        happiness: 1,
      ),
    ],
  ),

  // ===================================================================
  // ZİNCİR 4 — Borç (3 halka)
  // ===================================================================
  GameEvent(
    id: 'suc_borc_istendi',
    category: EventCategory.mahalle,
    text: 'Bir tanıdık kapıya geldi. "İki ay içinde veririm" dedi, '
        'sonra sustu.\n\nSuratından belli, gerçekten sıkışmış.',
    requirement: EventRequirement(
      minAge: 22,
      minComfort: FinancialComfort.idare,
      forbiddenFlags: <String>{CrimeFlags.borcVerdi},
    ),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'ver',
        label: 'Ver',
        resultText: 'Verdin. Senet istemedin, "aramız iyi" dedin. '
            'Bu cümleyi sonra çok hatırlayacaksın.',
        happiness: 1,
        money: -40000,
        charisma: 2,
        bond: 6,
        addFlags: <String>{CrimeFlags.borcVerdi},
        rememberPersonAs: CrimeRoles.borclu,
      ),
      EventChoice(
        id: 'yazili',
        label: 'Ver ama yazılı olsun',
        resultText: 'Bir kâğıt yazdınız, ikiniz de imzaladınız. '
            'Havası biraz bozuldu ama imzayı attı.',
        happiness: 1,
        money: -40000,
        intelligence: 2,
        bond: 2,
        addFlags: <String>{CrimeFlags.borcVerdi},
        rememberPersonAs: CrimeRoles.borclu,
      ),
      EventChoice(
        id: 'verme',
        label: 'Veremeyeceğini söyle',
        resultText: '"Kusura bakma, denk gelmiyor" dedin. '
            'Kapıdan çıkarken teşekkür etti, gözüne bakmadı.',
        happiness: -1,
        bond: -4,
      ),
    ],
  ),
  GameEvent(
    id: 'suc_borc_odenmedi',
    category: EventCategory.mahalle,
    text: 'İki ay dört ay oldu, dört ay bir yıl. Telefonları '
        'açmıyor.\n\nBu işte bir iş var.',
    requirement: EventRequirement(
      minAge: 23,
      requiredFlags: <String>{CrimeFlags.borcVerdi},
      forbiddenFlags: <String>{CrimeFlags.borcuIsteyecek},
      personRole: CrimeRoles.borclu,
    ),
    weight: 7,
    choices: <EventChoice>[
      EventChoice(
        id: 'bir_daha_sor',
        label: 'Bir kere daha sor',
        resultText: 'Sonunda açtı. "Bu ay biraz, sonra gerisi" dedi. '
            'Biraz geldi, gerisi gelmedi.',
        happiness: -1,
        money: 8000,
        addFlags: <String>{CrimeFlags.borcuIsteyecek},
      ),
      EventChoice(
        id: 'hukuka_tasi',
        label: 'Hukuka taşı',
        resultText: 'Dilekçeyi verdin. Kâğıt işi uzun sürdü; '
            'aranız da o kâğıtla birlikte kapandı.',
        happiness: -2,
        bond: -25,
        addFlags: <String>{
          CrimeFlags.borcuIsteyecek,
          CrimeFlags.mahkemeyeGitti,
        },
        crimeId: 'borc_davasi',
      ),
      EventChoice(
        id: 'sil',
        label: 'Sil gitsin',
        resultText: 'Aklından sildin. Tam silinmedi ama '
            'peşinde koşmayı bıraktın.',
        happiness: 1,
        charisma: 1,
        addFlags: <String>{CrimeFlags.borcuIsteyecek},
      ),
    ],
  ),
  GameEvent(
    id: 'suc_borc_sonrasi',
    category: EventCategory.mahalle,
    text: 'Mahkeme kâğıdı geldikten sonra o tanıdık bir mesaj attı: '
        '"Mahalleye rezil ettin beni."',
    requirement: EventRequirement(
      minAge: 24,
      requiredFlags: <String>{CrimeFlags.mahkemeyeGitti},
      personRole: CrimeRoles.borclu,
    ),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'cevap_yaz',
        label: 'Kısa cevap yaz',
        resultText: '"Param lazımdı" yazdın, o kadar. '
            'Karşı taraf yazmayı bıraktı.',
        happiness: 1,
        charisma: 1,
      ),
      EventChoice(
        id: 'cevap_verme',
        label: 'Cevap verme',
        resultText: 'Mesaj okundu kaldı. Millet çoktan konuşmaya '
            'başlamış, sen karışmadın.',
        happiness: -1,
      ),
    ],
  ),

  // ===================================================================
  // ZİNCİR 5 — Tahliye sonrası hayat (3 halka)
  // ===================================================================
  GameEvent(
    id: 'suc_tahliye_ilk_gun',
    category: EventCategory.kisisel,
    text: 'İlk sabah alışkanlıkla erken kalktın. Kapıyı kimse '
        'açıp kapatmıyor.\n\nDışarıda her şey biraz daha hızlı.',
    requirement: EventRequirement(
      minAge: 20,
      requiredFlags: <String>{},
      forbiddenFlags: <String>{
        CrimeFlags.tahliyeSonrasiCalisti,
        CrimeFlags.tahliyeSonrasiKapandi,
      },
      requiresReleased: true,
    ),
    weight: 9,
    choices: <EventChoice>[
      EventChoice(
        id: 'ise_bak',
        label: 'İş aramaya başla',
        resultText: 'İki yere sordun, ikisi de "arayalım" dedi. '
            'Aramadılar. Yarın yine soracaksın.',
        happiness: 1,
        charisma: 2,
        addFlags: <String>{CrimeFlags.tahliyeSonrasiCalisti},
      ),
      EventChoice(
        id: 'eve_kapan',
        label: 'Bir süre eve kapan',
        resultText: 'Perdeyi açmadın. Birkaç hafta böyle geçti; '
            'kimse de zorlamadı.',
        happiness: -3,
        health: -2,
        addFlags: <String>{CrimeFlags.tahliyeSonrasiKapandi},
      ),
    ],
  ),
  GameEvent(
    id: 'suc_tahliye_kapi',
    category: EventCategory.yetiskinlik,
    text: 'İş görüşmesinde her şey iyi gidiyordu. Sonra kâğıda '
        'baktı.\n\n"Bir de şu kayıt var" dedi.',
    requirement: EventRequirement(
      minAge: 20,
      requiredFlags: <String>{CrimeFlags.tahliyeSonrasiCalisti},
      requiresRecord: true,
    ),
    weight: 7,
    choices: <EventChoice>[
      EventChoice(
        id: 'acikla',
        label: 'Olduğu gibi anlat',
        resultText: 'Anlattın, süslemedin. "Düşünüp döneriz" dedi; '
            'bu sefer gerçekten döndüler.',
        happiness: 3,
        charisma: 3,
      ),
      EventChoice(
        id: 'konusma',
        label: 'Konuyu kapat',
        resultText: '"Eski hikâye" deyip geçtin. Görüşme de '
            'orada bitti.',
        happiness: -2,
      ),
    ],
  ),
  GameEvent(
    id: 'suc_tahliye_mahalle',
    category: EventCategory.mahalle,
    text: 'Kahvede eski tanıdıklar var. Biri yanına geldi, '
        'biri başını çevirdi.',
    requirement: EventRequirement(
      minAge: 20,
      requiresRecord: true,
      livingRelations: <RelationType>{RelationType.arkadas},
    ),
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'otur',
        label: 'Otur, çayını iç',
        resultText: 'Oturdun. İlk on dakika zor geçti, sonrası '
            'eskisi gibi oldu. Neredeyse.',
        happiness: 3,
        charisma: 2,
        bond: 5,
      ),
      EventChoice(
        id: 'cik',
        label: 'Çayı ayakta iç, çık',
        resultText: 'Uzatmadın. Kapıdan çıkarken arkandan '
            'konuşulduğunu duydun ama dönmedin.',
        happiness: -1,
      ),
    ],
  ),

  // ===================================================================
  // TEKİL OLAYLAR — trafik
  // ===================================================================
  GameEvent(
    id: 'suc_radar',
    category: EventCategory.yetiskinlik,
    text: 'Yol boştu, ayağın ağırlaştı. İki kilometre sonra '
        'kenarda o tanıdık kutu.',
    requirement: EventRequirement(
      minAge: 18,
      requiredLicenses: <String>{'otomobil_ehliyeti'},
      requiredPossessionKinds: <ItemKind>{ItemKind.otomobil},
    ),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'yavasla',
        label: 'Ayağını çek',
        resultText: 'Erken gördün, yavaşladın. Kalan yolu '
            'sakin gittin.',
        happiness: 1,
        addFlags: <String>{CrimeFlags.direksiyonUyarisi},
      ),
      EventChoice(
        id: 'devam',
        label: 'Aynı hızla devam',
        resultText: 'Aynada bir şey yoktu. Tebligat üç hafta sonra '
            'posta kutusundaydı.',
        happiness: -1,
        crimeId: 'trafik_hiz',
      ),
    ],
  ),
  GameEvent(
    id: 'suc_yanlis_park',
    category: EventCategory.yetiskinlik,
    text: 'Park yeri yok. Beş dakikalık iş için kaldırıma '
        'yarım çektin.',
    requirement: EventRequirement(
      minAge: 18,
      requiredPossessionKinds: <ItemKind>{ItemKind.otomobil},
    ),
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'tur_at',
        label: 'Tur at, yer bul',
        resultText: 'Üç tur attın, sonunda bir yer açıldı. '
            'İş beş dakika, park on beş dakika sürdü.',
        happiness: -1,
        charisma: 1,
      ),
      EventChoice(
        id: 'birak',
        label: 'Beş dakika bir şey olmaz',
        resultText: 'Dönüşte camda o kâğıdı gördün. '
            'Kenarı rüzgârda kıvrılmış.',
        happiness: -2,
        crimeId: 'trafik_park',
      ),
    ],
  ),
  GameEvent(
    id: 'suc_dugun_donusu',
    category: EventCategory.yetiskinlik,
    text: 'Düğünden çıktınız. Biri anahtarı sana uzattı: '
        '"Sen kullan, ben olmam."\n\nSen de bir şeyler içtin.',
    requirement: EventRequirement(
      minAge: 20,
      requiredLicenses: <String>{'otomobil_ehliyeti'},
      requiredPossessionKinds: <ItemKind>{ItemKind.otomobil},
      forbiddenFlags: <String>{CrimeFlags.alkolluHayir},
    ),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'taksi',
        label: 'Arabayı bırak, taksi tut',
        resultText: 'Arabayı orada bıraktın. Taksi parası canını '
            'yaktı, sabah araba yerindeydi.',
        happiness: 1,
        money: -900,
        charisma: 2,
        intelligence: 1,
        addFlags: <String>{CrimeFlags.alkolluHayir},
      ),
      EventChoice(
        id: 'baskasi',
        label: 'İçmeyen birini bul',
        resultText: 'Masada içmeyen birini buldun. Yolda iki kere '
            '"yavaş" dedin, üçüncüsünde sustun.',
        happiness: 2,
        charisma: 1,
        addFlags: <String>{CrimeFlags.alkolluHayir},
      ),
      EventChoice(
        id: 'ben_surerim',
        label: '"Ben sürerim"',
        resultText: 'Direksiyona geçtin. İki sokak sonra '
            'uygulama noktası vardı.',
        happiness: -4,
        health: -3,
        crimeId: 'trafik_alkollu',
      ),
    ],
  ),
  GameEvent(
    id: 'suc_kavsak_kazasi',
    category: EventCategory.yetiskinlik,
    text: 'Kavşakta karşıdan gelen aracı son anda gördün. '
        'Fren sesi, sonra sessizlik.\n\nİkinizin de camı inik.',
    requirement: EventRequirement(
      minAge: 18,
      requiredPossessionKinds: <ItemKind>{ItemKind.otomobil},
    ),
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'tutanak',
        label: 'Tutanak tutalım',
        resultText: 'Kâğıtları doldurdunuz. Uzun sürdü ama '
            'ikiniz de aynı şeyi yazdınız.',
        happiness: -2,
        health: -2,
        intelligence: 1,
        crimeId: 'trafik_kaza',
      ),
      EventChoice(
        id: 'anlas',
        label: 'Aramızda çözelim',
        resultText: 'Karşı taraf "sigortaya girmesin" dedi. '
            'Parayı verdin, fişi almadın.',
        happiness: -2,
        health: -2,
        money: -18000,
      ),
    ],
  ),

  // ===================================================================
  // TEKİL OLAYLAR — kamu düzeni, mala zarar, yaralama
  // ===================================================================
  GameEvent(
    id: 'suc_tribun',
    category: EventCategory.mahalle,
    text: 'Maç bitti, tribün boşalmıyor. Öndeki gruptan bir '
        'şeyler atılmaya başladı.\n\nPolis yan kapıya yürüdü.',
    requirement: EventRequirement(minAge: 16, maxAge: 45),
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'cik',
        label: 'Kalabalıktan çık',
        resultText: 'Yandan sıyrıldın. Dışarıda simit aldın, '
            'olayı ertesi gün haberlerden öğrendin.',
        happiness: 1,
      ),
      EventChoice(
        id: 'katil',
        label: 'Sen de sesini yükselt',
        resultText: 'Ortada kaldın. Memur kimliğine baktı: '
            '"Şöyle kenara geçelim."',
        happiness: -2,
        crimeId: 'kamu_duzeni',
      ),
    ],
  ),
  GameEvent(
    id: 'suc_apartman_kavgasi',
    category: EventCategory.mahalle,
    text: 'Üst kat yine gece yarısı. Bu sefer kapıya çıktın, '
        'karşılık geldi.\n\nMerdivende sesler yükseldi.',
    requirement: EventRequirement(minAge: 20, requiresTenant: true),
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'apartman_toplantisi',
        label: 'Apartman toplantısına taşı',
        resultText: 'Konuyu toplantıya taşıdın. Yarım saat konuşuldu, '
            'yönetici bir kâğıt astı. Bir ay işe yaradı.',
        happiness: 1,
        charisma: 3,
        intelligence: 1,
      ),
      EventChoice(
        id: 'kapiyi_yumrukla',
        label: 'Kapıyı tekmele',
        resultText: 'Kapı hasar gördü, ortalık karıştı. '
            'Gece yarısı tutanak tutuluyordu.',
        happiness: -3,
        crimeId: 'mala_zarar',
      ),
    ],
  ),
  GameEvent(
    id: 'suc_otoparkta_cizik',
    category: EventCategory.yetiskinlik,
    text: 'Aracının kapısında derin bir çizik var. Yandaki '
        'araç fazla yakın park etmiş.',
    requirement: EventRequirement(
      minAge: 18,
      requiredPossessionKinds: <ItemKind>{ItemKind.otomobil},
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'not_birak',
        label: 'Not bırak',
        resultText: 'Cama bir not sıkıştırdın. Akşam aradı, '
            'masrafı paylaştınız.',
        happiness: 1,
        charisma: 2,
        money: -6000,
      ),
      EventChoice(
        id: 'ayni_seyi_yap',
        label: 'Sen de onun kapısını çiz',
        resultText: 'İki araba da çizik oldu. Kamera vardı.',
        happiness: -2,
        crimeId: 'mala_zarar',
      ),
      EventChoice(
        id: 'gec',
        label: 'Boş ver',
        resultText: 'Çizik kaldı. Her binişte gözün oraya gidiyor.',
        happiness: -1,
      ),
    ],
  ),
  GameEvent(
    id: 'suc_halisaha_gerginligi',
    category: EventCategory.mahalle,
    text: 'Halı sahada faul tartışması büyüdü. Karşı takımdan '
        'biri göğsüne dokundu.\n\nHerkes durdu.',
    requirement: EventRequirement(minAge: 17, maxAge: 45),
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'geri_cekil',
        label: 'Geri çekil',
        resultText: 'İki adım geri gittin. Maç devam etti, '
            'sonunda tokalaştınız.',
        happiness: 1,
        charisma: 2,
      ),
      EventChoice(
        id: 'it',
        label: 'Sen de it',
        resultText: 'Bir itiş iki oldu. Biri yerde kaldı; '
            'işler sarpa sardı.',
        happiness: -4,
        health: -4,
        crimeId: 'yaralama',
      ),
    ],
  ),
  GameEvent(
    id: 'suc_marketten_cikis',
    category: EventCategory.mahalle,
    text: 'Kasada sıra uzun. Cebindeki para almak istediğin '
        'şeye yetmiyor.\n\nKimse sana bakmıyor.',
    requirement: EventRequirement(
      minAge: 15,
      maxAge: 30,
      maxComfort: FinancialComfort.zor,
    ),
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'rafa_koy',
        label: 'Rafa geri koy',
        resultText: 'Geri koydun. Kasadan ucuz olanı aldın. '
            'Kimse bir şey demedi.',
        happiness: -1,
        charisma: 1,
      ),
      EventChoice(
        id: 'cebe_koy',
        label: 'Cebine koy',
        resultText: 'Kapıdaki alarm çaldı. Görevli sakin '
            'yaklaştı: "Bir saniye."',
        happiness: -4,
        crimeId: 'kucuk_hirsizlik',
      ),
    ],
  ),

  // ===================================================================
  // TEKİL OLAYLAR — süreç ve sonrası
  // ===================================================================
  GameEvent(
    id: 'suc_ifade_gunu',
    category: EventCategory.kisisel,
    text: 'Sabah ifade için gittin. Koridorda bekleyenler '
        'birbirine bakmıyor.\n\nİsmin okunduğunda iki kişi başını kaldırdı.',
    requirement: EventRequirement(minAge: 17, requiresOpenCase: true),
    weight: 8,
    choices: <EventChoice>[
      EventChoice(
        id: 'kisa_kes',
        label: 'Kısa kes',
        resultText: 'Sorulana cevap verdin, fazlasını söylemedin. '
            'Yirmi dakikada bitti.',
        happiness: 1,
        intelligence: 1,
      ),
      EventChoice(
        id: 'hepsini_anlat',
        label: 'Baştan anlat',
        resultText: 'Uzun uzun anlattın. Memur iki kere '
            '"bunu yazmasam da olur" dedi.',
        happiness: -1,
        charisma: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'suc_dosya_beklerken',
    category: EventCategory.kisisel,
    text: 'Dosya bekliyor. Günler normal geçiyor, sonra bir '
        'telefon çalıyor ve içinde bir şey kalkıyor.',
    requirement: EventRequirement(minAge: 17, requiresOpenCase: true),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'birine_anlat',
        label: 'Birine anlat',
        resultText: 'Anlattın. Çözülmedi ama omzundan bir şey indi.',
        happiness: 3,
        bond: 4,
      ),
      EventChoice(
        id: 'kendine_sakla',
        label: 'Kendine sakla',
        resultText: 'Kimseye söylemedin. Geceleri uyku '
            'yarım kalıyor.',
        happiness: -2,
        health: -2,
      ),
    ],
  ),
  GameEvent(
    id: 'suc_ceza_odemesi',
    category: EventCategory.kisisel,
    text: 'Vezne sırası. Elindeki kâğıtta bir tutar, '
        'cebinde daha azı var.',
    requirement: EventRequirement(
      minAge: 18,
      requiresRecord: true,
      maxComfort: FinancialComfort.zor,
    ),
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'taksit',
        label: 'Taksit sor',
        resultText: 'Taksit yaptılar. Her ay gelen mesajı '
            'görmemeye çalışıyorsun.',
        happiness: -1,
        intelligence: 1,
      ),
      EventChoice(
        id: 'borc_al',
        label: 'Birinden borç al',
        resultText: 'Borç aldın, ödedin. Şimdi kâğıt yerine '
            'bir tanıdığa borçlusun.',
        happiness: -1,
        money: 12000,
        bond: -3,
      ),
    ],
  ),
  GameEvent(
    id: 'suc_cocuga_anlatmak',
    category: EventCategory.aile,
    text: 'Çocuğun okulda duymuş. Akşam sofrada sordu:\n\n'
        '"Baba, doğru mu?"',
    requirement: EventRequirement(
      minAge: 28,
      requiresRecord: true,
      livingRelations: <RelationType>{RelationType.cocuk},
      personMinAge: 7,
      requireSameHousehold: true,
    ),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'dogru_soyle',
        label: 'Doğrusunu söyle',
        resultText: 'Anlattın, yaşına göre. Başını sallayıp '
            'yemeğine döndü. Konu bir daha açılmadı.',
        happiness: 2,
        charisma: 2,
        bond: 5,
      ),
      EventChoice(
        id: 'gecistir',
        label: 'Geçiştir',
        resultText: '"Büyüyünce anlarsın" dedin. Anladı zaten; '
            'sormayı bıraktı.',
        happiness: -2,
        bond: -4,
      ),
    ],
  ),
  GameEvent(
    id: 'suc_esiyle_konusma',
    category: EventCategory.aile,
    text: 'Eşin masaya iki çay koydu, karşına oturdu.\n\n'
        '"Şimdi sakin sakin konuşacağız."',
    requirement: EventRequirement(
      minAge: 22,
      requiresRecord: true,
      livingRelations: <RelationType>{RelationType.es},
    ),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'her_seyi',
        label: 'Her şeyi anlat',
        resultText: 'Baştan anlattın. Araya girmedi. Sonunda '
            '"tamam" dedi; o "tamam" kolay gelmedi.',
        happiness: 3,
        bond: 8,
      ),
      EventChoice(
        id: 'yarim',
        label: 'Yarısını anlat',
        resultText: 'Bir kısmını söyledin. Gerisini zaten '
            'biliyordu.',
        happiness: -2,
        bond: -6,
      ),
    ],
  ),
  GameEvent(
    id: 'suc_avukat_gorusmesi',
    category: EventCategory.kisisel,
    text: 'Avukatın dosyayı masaya koydu.\n\n'
        '"Bakın, garanti veremem. Ama şunu birlikte yapacağız."',
    requirement: EventRequirement(minAge: 18, requiresOpenCase: true),
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'dinle',
        label: 'Dinle, not al',
        resultText: 'Yazdıklarını okudun, anlamadığını sordun. '
            'Çıkarken kafan daha düzenliydi.',
        happiness: 2,
        intelligence: 2,
      ),
      EventChoice(
        id: 'garanti_iste',
        label: '"Kazanacak mıyız?"',
        resultText: '"Kazanırız" demedi. "Çalışırız" dedi. '
            'İstediğin cevap değildi.',
        happiness: -1,
        intelligence: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'suc_sabikasiz_yol',
    category: EventCategory.kisisel,
    text: 'Eski bir tanıdığın işi büyümüş, senin adını da '
        'anmış: "O adam hiç bulaşmadı bu işlere."',
    requirement: EventRequirement(
      minAge: 30,
      requiredFlags: <String>{CrimeFlags.teklifiReddetti},
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'gulumse',
        label: 'Gülümse, geç',
        resultText: 'Bir şey demedin. İçinden "iyi ki" dedin.',
        happiness: 3,
        charisma: 1,
      ),
      EventChoice(
        id: 'hatirlat',
        label: 'O günü hatırlat',
        resultText: '"Bir seferinde sen de teklif etmiştin" dedin. '
            'Güldü, konuyu değiştirdi.',
        happiness: 1,
        charisma: 2,
      ),
    ],
  ),
];
