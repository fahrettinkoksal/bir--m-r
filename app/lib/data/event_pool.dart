/// Prototipin özgün olay havuzu.
///
/// Havuz bilerek küçüktür; amaç olay motorunun uygunluk, seçim, etki ve
/// hafıza davranışını gerçek veriyle göstermektir. Yeni olay eklemek bu
/// listeye bir kayıt eklemektir. **Bu şema onaylanmış bir tasarım kararı
/// değildir**; nihai olay veri şeması Faho ile kararlaştırılacaktır.
library;

import '../domain/models/game_event.dart';
import '../domain/models/relation.dart';
import 'event_pool_chains.dart';
import 'event_pool_childhood.dart';
import 'event_pool_crime.dart';
import 'event_pool_elder.dart';
import 'event_pool_extra.dart';
import 'event_pool_exam.dart';
import 'event_pool_infancy.dart';
import 'event_pool_midlife.dart';
import 'event_pool_hobby.dart';
import 'event_pool_pet.dart';
import 'event_pool_romance.dart';
import 'event_pool_social.dart';
import 'event_pool_travel.dart';
import 'event_pool_work.dart';
import 'event_pool_stages.dart';

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

  /// Evlilik izleri (Paket E1).
  static const String evlendi = 'evlendi';
  static const String bosandi = 'bosandi';

  /// Çocuk sahibi olma izi (Paket E2).
  static const String cocukSahibi = 'cocuk_sahibi';

  /// Evlilik dışı çocuk izi (D-047).
  static const String evlilikDisiCocuk = 'evlilik_disi_cocuk';

  /// Ebeveynlik izleri (Paket 2). Geçmiş kararlar ileride hatırlanır.
  static const String cocukIlkGunDestek = 'cocuk_ilk_gun_destek';
  static const String cocukIlkGunYalniz = 'cocuk_ilk_gun_yalniz';
  static const String cocugaSozVerildi = 'cocuga_soz_verildi';
  static const String cocugaSozTutuldu = 'cocuga_soz_tutuldu';
  static const String cocugaSozUnutuldu = 'cocuga_soz_unutuldu';
  static const String cocukKendiSecti = 'cocuk_kendi_secti';
  static const String bebekBakimiPaylasildi = 'bebek_bakimi_paylasildi';

  /// Evlilik izleri (Paket 2).
  static const String esleKonusuldu = 'esle_konusuldu';
  static const String esleSusuldu = 'esle_susuldu';
}

/// Hikâyede kimliği sabitlenen kişi rolleri.
///
/// Bir olayda kim olduğu belirlenen kişi, yıllar sonraki devam olayında
/// **aynı kayıtla** karşına çıkar; yeni bir NPC uydurulmaz.
abstract final class StoryRoles {
  /// Teneffüste alay edilen ve savunulan/savunulmayan okul arkadaşı.
  static const String alayEdilenArkadas = 'alay_edilen_arkadas';

  /// Okulun ilk gününde yanında olunan (ya da olunmayan) çocuk.
  ///
  /// Birden fazla çocuk varsa devam olayları **aynı çocukla** kurulur.
  static const String ilkOkulCocugu = 'ilk_okul_cocugu';

  /// Kendisine bir söz verilen çocuk.
  static const String sozVerilenCocuk = 'soz_verilen_cocuk';
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
    text:
        'Sokakta senden birkaç yaş büyük çocuklar takım kuruyor. '
        'İçlerinden biri sana dönüp "eksiğimiz var, oynar mısın?" diyor.',
    requirement: EventRequirement(minAge: 5, maxAge: 8),
    choices: <EventChoice>[
      EventChoice(
        id: 'katil',
        label: 'Varım de',
        resultText:
            'Oyuna girdin. Kuralları yolda öğrendin, birkaç kez '
            'ebe kaldın ama akşam eve gülerek döndün.',
        happiness: 4,
        charisma: 3,
      ),
      EventChoice(
        id: 'izle',
        label: 'Kenardan izle',
        resultText:
            'Duvarın dibinde oturup izledin. Oyunu ezberledin; '
            'oynamak başka şeymiş.',
        intelligence: 2,
        happiness: -1,
      ),
    ],
  ),
  GameEvent(
    id: 'komsu_televizyonu',
    category: EventCategory.mahalle,
    text:
        'Elektrikler kesildi, bütün apartman merdiven başında toplandı. '
        'Bir komşu mum yaktı, yaşlı bir amca anlatmaya başladı.',
    requirement: EventRequirement(minAge: 6, maxAge: 13),
    choices: <EventChoice>[
      EventChoice(
        id: 'dinle',
        label: 'Hikâyeleri dinle',
        resultText:
            'Anlatılanların yarısı abartıydı, yarısı gerçek. '
            'Hangisinin hangisi olduğunu hâlâ bilmiyorsun.',
        happiness: 3,
        intelligence: 1,
      ),
      EventChoice(
        id: 'anlat',
        label: 'Sen de bir şey anlat',
        resultText:
            'Sesin ilk cümlede titredi, sonra düzeldi. '
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
    text:
        'Okulun ilk günü. Sıranın hangi tarafına oturacağını bile '
        'bilmiyorsun; herkes birbirine bakıyor.',
    requirement: EventRequirement(
      minAge: 6,
      maxAge: 8,
      requiresSchoolStudent: true,
    ),
    // **Bilerek önceliksiz (Paket 21).** Öncelik verildiğinde okulun ilk
    // yılındaki tek olay yuvasını kapıyor ve sıra arkadaşıyla tanışma
    // olayını bastırıyordu: ölçümde okulda arkadaş edinen hayat oranı
    // 44/60'tan 34/60'a düştü. Okula başlama zaten ekranda bildirimle
    // duyuruluyor (Paket 17), bu olayın ayrıca öne çekilmesi gerekmiyor.
    choices: <EventChoice>[
      EventChoice(
        id: 'on_sira',
        label: 'En öne otur',
        resultText:
            'Ön sırada, tahtaya en yakın yerdesin. Yoklamada adın '
            'okunurken elini kaldırdın; ilk günden tanındın.',
        intelligence: 3,
        happiness: 1,
      ),
      EventChoice(
        id: 'arka_sira',
        label: 'Arkalara geç',
        resultText:
            'Arka sırada pencere kenarını kaptın. Dışarıyı '
            'izlemek dersten daha kolaydı.',
        happiness: 3,
        intelligence: -1,
      ),
    ],
  ),
  GameEvent(
    id: 'arkadasi_savunma',
    category: EventCategory.okul,
    text:
        'Teneffüste sınıftan biri {sahipk} {kisi} ile alay ediyor. '
        'Etraftaki herkes sana bakıyor.',
    requirement: EventRequirement(
      minAge: 9,
      maxAge: 13,
      requiresSchoolStudent: true,
      // Olay gerçekten var olan bir okul arkadaşına bağlanır; sonraki
      // devam olayları aynı kişiyi kullanır.
      livingRelations: <RelationType>{
        RelationType.arkadas,
        RelationType.sinifArkadasi,
      },
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
        resultText:
            'Araya girdin. Ortalık bir an sessizleşti; o gün '
            'kimse bir şey demedi ama {kisi} sana baktı.',
        charisma: 3,
        happiness: 2,
        bond: 6,
        addFlags: <String>{StoryFlags.arkadasiniSavundu},
        rememberPersonAs: StoryRoles.alayEdilenArkadas,
      ),
      EventChoice(
        id: 'sus',
        label: 'Sessiz kal',
        resultText:
            'Başını önüne eğdin. Zil çaldığında herkes dağıldı, '
            'içindeki sıkıntı dağılmadı.',
        happiness: -4,
        bond: -5,
        addFlags: <String>{StoryFlags.sessizKaldi},
        rememberPersonAs: StoryRoles.alayEdilenArkadas,
      ),
    ],
  ),

  // --- Geçmiş seçimin görünür devamı (D-022) -----------------------------
  GameEvent(
    id: 'savundugun_arkadas',
    category: EventCategory.okul,
    text:
        'Yıllar önce savunduğun {kisi} seni buldu. "O gün araya '
        'girmeseydin okulu bırakacaktım" diyor ve bir işte beraber '
        'çalışmayı teklif ediyor.',
    requirement: EventRequirement(
      minAge: 15,
      maxAge: 20,
      requiredFlags: <String>{StoryFlags.arkadasiniSavundu},
      // O gün savunduğun kişi kimse, yıllar sonra da aynı kişi gelir.
      personRole: StoryRoles.alayEdilenArkadas,
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'kabul',
        label: 'Teklifi kabul et',
        resultText:
            'Birlikte çalışmaya başladınız. İşin kendisinden çok, '
            '{kisi} gibi birinin seni hatırlamış olması iyi geldi.',
        happiness: 6,
        charisma: 3,
        bond: 8,
      ),
      EventChoice(
        id: 'tesekkur',
        label: 'Teşekkür et, kendi yolundan git',
        resultText:
            'Teklifini kibarca geri çevirdin. Ayrılırken '
            '"aramızda kalsın, o gün kahramandın" dedi.',
        happiness: 4,
      ),
    ],
  ),
  GameEvent(
    id: 'sessiz_kaldigin_gun',
    category: EventCategory.okul,
    text:
        'O gün alay edilen {kisi} ile yıllar sonra karşılaştın. '
        'Seni tanıdı, selam verdi ve hızlıca uzaklaştı.',
    requirement: EventRequirement(
      minAge: 15,
      maxAge: 20,
      requiredFlags: <String>{StoryFlags.sessizKaldi},
      personRole: StoryRoles.alayEdilenArkadas,
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'ozur',
        label: 'Peşinden git ve özür dile',
        resultText:
            'Nefes nefese yetiştin. "Biliyorum" dedi {kisi}, '
            '"çocuktuk." İkinizin de yükü biraz hafifledi.',
        happiness: 5,
        charisma: 2,
        bond: 7,
      ),
      EventChoice(
        id: 'birak',
        label: 'Olduğun yerde kal',
        resultText:
            'Arkasından baktın. Söylenmemiş cümle hâlâ '
            'boğazında duruyor.',
        happiness: -3,
      ),
    ],
  ),

  // --- Varlık zinciri: sahip olmadığın şey için olay çıkmaz --------------
  GameEvent(
    id: 'bisiklet_hediyesi',
    category: EventCategory.aile,
    text:
        '{sahip} {kisi} eve ikinci el ama tertemiz bir bisikletle geldi. '
        '"Elimden bu kadarı geldi, sağlamdır" diyor.',
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
        resultText:
            'Bisikleti o gün akşama kadar bırakmadın. '
            'Zincir yağı kokusu hâlâ aklında.',
        happiness: 6,
        bond: 8,
        addPossessions: <String>{Possessions.bisiklet},
      ),
      EventChoice(
        id: 'sessiz',
        label: 'Sessizce al',
        resultText:
            'Teşekkür etmeyi unuttun. Bisiklet senin oldu ama '
            '{sahipk} {kisi} bir an duraksadı.',
        happiness: 3,
        bond: -2,
        addPossessions: <String>{Possessions.bisiklet},
      ),
    ],
  ),
  GameEvent(
    id: 'bisiklet_zinciri',
    category: EventCategory.kisisel,
    text:
        'Bisikletinin zinciri yokuş ortasında koptu. Eve kadar itmek '
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
        resultText:
            'Elin yağ içinde kaldı ama zinciri taktın. '
            'Bir şeyi kendin onarmanın tadı başkaymış.',
        intelligence: 3,
        happiness: 2,
      ),
      EventChoice(
        id: 'it',
        label: 'İterek eve götür',
        resultText:
            'Yokuşu bisikleti iterek çıktın. Bacakların ağrıdı, '
            'canın sıkılmadı.',
        health: 2,
      ),
    ],
  ),

  // --- Aile ---------------------------------------------------------------
  GameEvent(
    id: 'bayram_ziyareti',
    category: EventCategory.aile,
    text:
        'Bayram sabahı {sahipk} {kisi} kapıda sizi bekliyor. Elinde '
        'kolonya, masada şeker, ortada herkesin bildiği ama yine anlatılan '
        'hikâyeler var.',
    requirement: EventRequirement(
      minAge: 6,
      livingRelations: _buyuklerVeAkrabalar,
    ),
    // Bayram doğal olarak tekrar eder; ama art arda gelmemesi için
    // aralarında oyun içi yaş farkı aranır (prototypeOnly).
    repeatable: true,
    minAgeGap: 9,
    choices: <EventChoice>[
      EventChoice(
        id: 'kal',
        label: 'Akşama kadar kal',
        resultText:
            'Gün boyu kaldın. {sahip} {kisi} anlattıkça anlattı, sen '
            'dinledikçe dinledin.',
        happiness: 4,
        bond: 6,
      ),
      EventChoice(
        id: 'kisa',
        label: 'Elini öpüp erken çık',
        resultText:
            'Kısa bir ziyaret oldu. {sahip} {kisi} bir şey demedi ama '
            'kapıda biraz fazla bekledi.',
        happiness: 1,
        bond: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'aile_sitemi',
    category: EventCategory.aile,
    text:
        '{sahip} {kisi} uzun zamandır senden haber alamadığını söylüyor: '
        '"Aynı evdeyiz ama seni günlerdir doğru dürüst görmedim."',
    requirement: EventRequirement(
      minAge: 8,
      requiresNeglectedRelative: true,
      requireSameHousehold: true,
    ),
    repeatable: true,
    minAgeGap: 9,
    weight: 2,
    choices: <EventChoice>[
      EventChoice(
        id: 'otur',
        label: 'Bırak elindekini, otur konuş',
        resultText:
            '{sahipk} {kisi} ile uzun uzun oturdunuz. Sitem, yerini '
            'sohbete bıraktı.',
        happiness: 3,
        bond: 7,
      ),
      EventChoice(
        id: 'sonra',
        label: '"Sonra konuşuruz" de',
        resultText:
            '{sahip} {kisi} başını salladı. Konu kapandı ama '
            'kapanmamış gibi durdu.',
        happiness: -2,
        bond: -4,
      ),
    ],
  ),

  // --- Uzak kalmış yakın: sitem (D-093) ---------------------------------
  //
  // Faho'nun isteği: "ayrıca sitem olayları ekle: 'Kızınla uzun süredir
  // görüşmüyorsun.' Seçenekler: Ara / Ziyaret et / Biraz daha ertele.
  // Gerçek sonuç: yakınlık / kişi keyfi değişsin."
  //
  // Mevcut `aile_sitemi` aynı evde yaşayanlar içindi. Bu olay **evden
  // ayrılmış** yakın içindir: yetişkin çocuk, ebeveyn, kardeş.
  GameEvent(
    id: 'uzak_yakin_sitemi',
    category: EventCategory.aile,
    text:
        'Telefon çaldı. {sahip} {kisi} aradı ve sesindeki şey sitemdi: '
        '"Aramayı hep ben mi yapacağım?"',
    requirement: EventRequirement(
      minAge: 20,
      requiresNeglectedRelative: true,
      requireOutsideHousehold: true,
      requireReachable: true,
    ),
    repeatable: true,
    minAgeGap: 12,
    weight: 1,
    choices: <EventChoice>[
      EventChoice(
        id: 'hemen_konus',
        label: 'Ara ve uzun uzun konuş',
        resultText:
            '{sahipk} {kisi} ile bir saat konuştunuz. Aradaki mesafe '
            'kapanmadı ama ilk adım atıldı.',
        happiness: 2,
        bond: 8,
      ),
      EventChoice(
        id: 'ziyaret',
        label: 'Ziyarete git',
        resultText:
            'Yola çıktın. {sahip} {kisi} kapıda seni görünce bir şey '
            'demedi, sadece kenara çekildi.',
        happiness: 4,
        bond: 14,
        money: -3500,
      ),
      EventChoice(
        id: 'ertele',
        label: 'Biraz daha ertele',
        resultText:
            '"Bu hafta çok yoğunum" dedin. {sahip} {kisi} "tabii" dedi '
            've telefonu kapattı.',
        happiness: -3,
        bond: -8,
      ),
    ],
  ),

  // --- Yetişkinliğe giriş: öğrenci olmayana üniversite olayı çıkmaz ------
  GameEvent(
    id: 'lise_sonrasi',
    category: EventCategory.yetiskinlik,
    text:
        'Okul bitti. Herkes sana aynı soruyu soruyor: bundan sonra ne '
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
    priority: 1,
    choices: <EventChoice>[
      EventChoice(
        id: 'universite',
        label: 'Üniversiteye devam et',
        resultText:
            'Kaydını yaptırdın. Yeni bir şehir, yeni bir sıra, '
            'yine en öndeki boş yer.',
        intelligence: 4,
        happiness: 2,
        addFlags: <String>{StoryFlags.universitede},
      ),
      EventChoice(
        id: 'calis',
        label: 'Çalışmaya başla',
        resultText:
            'İşe girdin. İlk gün eve yorgun döndün ama '
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
    text:
        'Üniversitede ilk haftan. Kimse kimseyi tanımıyor, herkes '
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
        resultText:
            'Kulüp odasında ilk gün üç kişiydiniz. Sonra '
            'kalabalıklaştı, sen ilk gelenlerdendin.',
        charisma: 4,
        happiness: 3,
      ),
      EventChoice(
        id: 'kutuphane',
        label: 'Kütüphaneye kapan',
        resultText:
            'Kütüphanenin en dip masası senin oldu. Sessizlik '
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
    text:
        'Silgin yok. Yan sıranda oturan {sahipk} {kisi} kendi silgisini '
        'ikiye bölüp yarısını sana uzatıyor: "Benimki biterse seninkini '
        'isterim ama."',
    requirement: EventRequirement(
      requiresSchoolStudent: true,
      minGrade: 1,
      maxGrade: 8,
      // Tanışıklık gerçek bir sınıf arkadaşıyla kurulur; olmayan bir
      // çocuk uydurulmaz.
      livingRelations: <RelationType>{RelationType.sinifArkadasi},
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
        resultText:
            '{kisi} ile o gün teneffüste de yan yana oturdunuz; '
            'ertesi gün sırayı kimse size sormadan ayırdınız. Artık sınıf '
            'arkadaşından fazlası.',
        happiness: 4,
        charisma: 2,
        bond: 8,
        addFlags: <String>{StoryFlags.okuldaArkadasEdindi},
        startsSchoolFriendship: true,
      ),
      EventChoice(
        id: 'cekin',
        label: '"Gerek yok" de',
        resultText:
            'Silgiyi almadın. {kisi} yarısını sıranın kenarına '
            'bıraktı, sen de almadın; ikiniz de bir şey demediniz.',
        happiness: -2,
        addFlags: <String>{StoryFlags.okuldaCekingen},
      ),
    ],
  ),
  GameEvent(
    id: 'teneffus_oyun_daveti',
    category: EventCategory.okul,
    text:
        'Zil çaldı, {sahipk} {kisi} kapıda seni bekliyor: "Bahçede yer '
        'tuttuk, sensiz başlamayız."',
    requirement: EventRequirement(
      requiresSchoolStudent: true,
      livingRelations: <RelationType>{RelationType.arkadas},
    ),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'katil',
        label: 'Çantayı bırak, koş',
        resultText:
            'Zil çalana kadar bahçedeydiniz. Dizin sıyrıldı, '
            'kimse fark etmedi; {kisi} hâlâ gülüyordu.',
        happiness: 5,
        health: 1,
        charisma: 1,
        bond: 5,
      ),
      EventChoice(
        id: 'calis',
        label: 'Sırada kal, derse bak',
        resultText:
            'Teneffüsü kitabın başında geçirdin. Konuyu anladın '
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
    text:
        '{sahip} {kisi} defterini önüne koydu: "Bunu hiç anlamadım, '
        'yarın kontrol var. Bir bakar mısın?"',
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
        resultText:
            'Teneffüsü verdin ama {kisi} sonunda kendi çözdü. '
            '"Sen anlatınca oluyor" dedi.',
        intelligence: 2,
        charisma: 1,
        bond: 9,
        addFlags: <String>{StoryFlags.arkadasaYardimEtti},
      ),
      EventChoice(
        id: 'reddet',
        label: '"Benim de işim var" de',
        resultText:
            '{kisi} defterini sessizce kapattı. Bir şey demedi, '
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
    text:
        '{sahip} {kisi} tahtadaki soruyu gösterip sınıfa baktı: "Kim '
        'deneyecek?" Kimse parmak kaldırmıyor, cevabı biliyorsun.',
    requirement: EventRequirement(
      requiresSchoolStudent: true,
      minGrade: 2,
      livingRelations: <RelationType>{RelationType.ogretmen},
      forbiddenFlags: <String>{StoryFlags.dersteSozAldi},
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'kaldir',
        label: 'Parmak kaldır',
        resultText:
            'Tahtaya kalktın, elin titredi ama soruyu çözdün. '
            'Yerine otururken {kisi} başını salladı, sınıf hâlâ sana '
            'bakıyordu.',
        intelligence: 3,
        charisma: 3,
        happiness: 2,
        bond: 6,
        addFlags: <String>{StoryFlags.dersteSozAldi},
      ),
      EventChoice(
        id: 'sessiz',
        label: 'Sessiz kal',
        resultText:
            'Başka biri kalktı ve yanlış yaptı. Doğrusu hâlâ '
            'defterinin kenarında yazılı duruyor.',
        happiness: -2,
        intelligence: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'yardimin_karsiligi',
    category: EventCategory.okul,
    text:
        'Kantinde sıradasın, paran yetmedi. Arkandan {sahipk} {kisi} '
        'yetişip bozuklukları tezgâha bıraktı: "O gün defterime baktın ya, '
        'ödeştik."',
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
        resultText:
            'Bir dahakine senden dediniz. {kisi} ile aranızda '
            'sayılmayan bir hesap açıldı.',
        happiness: 5,
        bond: 6,
      ),
      EventChoice(
        id: 'geri_ver',
        label: 'Parayı ertesi gün geri ver',
        resultText:
            'Ertesi gün bozuklukları geri verdin. {kisi} aldı ama '
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
    text:
        'Durakta her gün aynı saatte karşılaştığın biri var. Bugün '
        'otobüs gecikti ve ikiniz de aynı tabelaya bakıyorsunuz.',
    requirement: EventRequirement(
      minAge: 15,
      maxAge: 22,
      forbiddenFlags: <String>{
        StoryFlags.romantikIlgi,
        StoryFlags.romantikGecti,
        // Evli karakterin karşısına yeni bir tanışma zinciri çıkmaz;
        // böylece ikinci bir romantik kişi kaydı da üretilmez.
        StoryFlags.evlendi,
      },
    ),
    // **Not (Paket 23):** Bu olay gençliğin kapısıdır ve dar kalması
    // bilerek. Burayı kaçıran ya da geçen oyuncu artık ömür boyu kapalı
    // kalmıyor: yetişkinlik kapıları `event_pool_romance.dart` içinde.
    // prototypeOnly: romantik zincir ilk prototipte gerçekten oynanabilmeli
    // (D-030); yine de her hayatta zorunlu değildir.
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'selam',
        label: 'Selam ver, konuş',
        resultText:
            'İki cümle kurdunuz, otobüs geldi. Ertesi gün yine '
            'aynı durakta, yine aynı saatte buluştunuz.',
        charisma: 2,
        happiness: 2,
        addFlags: <String>{StoryFlags.romantikIlgi},
      ),
      EventChoice(
        id: 'gec',
        label: 'Bir şey deme',
        resultText:
            'Otobüse bindin, bakıştınız, o kadar. Bazı cümleler '
            'kurulmadan biter.',
        happiness: -1,
        addFlags: <String>{StoryFlags.romantikGecti},
      ),
    ],
  ),
  GameEvent(
    id: 'cikma_teklifi',
    category: EventCategory.kisisel,
    text:
        'Duraktaki sohbetler aylardır sürüyor. Bugün ikiniz de '
        'konuşmayı uzatmak için bahane arıyorsunuz.',
    requirement: EventRequirement(
      minAge: 15,
      maxAge: 25,
      requiredFlags: <String>{StoryFlags.romantikIlgi},
      forbiddenFlags: <String>{StoryFlags.romantikIliskide, StoryFlags.evlendi},
    ),
    // **`romantik_bitti` yasağı kaldırıldı (Paket 23).** Bir kez ayrılmak
    // ömrün geri kalanında yeniden ilişki kurmayı imkânsız kılıyordu;
    // ölçümde 60 hayatın yalnızca 15'inde hiç sevgili oluyordu. Zincir
    // hâlâ `romantik_ilgi` izini ve 15-25 yaş penceresini istiyor.
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'teklif',
        label: 'Açıl ve teklif et',
        resultText:
            'Adının {kisi} olduğunu o gün öğrendin. Artık '
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
    text:
        '{kisi} ile uzun zamandır aynı konuda tartışıyorsunuz. Bugün '
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
        resultText:
            'Uzun konuştunuz. Mesele bitmedi ama ikiniz de '
            'birbirinizi daha iyi anladınız.',
        happiness: 3,
        bond: 6,
      ),
      EventChoice(
        id: 'ayril',
        label: 'Ayrılmayı teklif et',
        resultText:
            'Konuşma bitmeden karar verdiniz. {kisi} ile '
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
    text:
        '{kisi} ile bir caddede karşılaştın. Aynı durak, aynı saat '
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
        resultText:
            'Kısa konuştunuz. Eski hâliniz değilsiniz ama '
            'yabancı da değilsiniz.',
        happiness: 2,
      ),
      EventChoice(
        id: 'gormezden',
        label: 'Görmezden gel',
        resultText:
            'Karşı kaldırıma geçtin. Arkana bakmadın; bakmak '
            'istedin.',
        happiness: -2,
      ),
    ],
  ),

  GameEvent(
    id: 'ilk_maas',
    category: EventCategory.yetiskinlik,
    text: 'İlk maaşını elden aldın. Zarf ince ama senin.',
    // calismaHayati bir geçmiş izidir ve işten ayrılınca silinmez;
    // maaş olayı anlık iş durumuna bakmalı.
    requirement: EventRequirement(
      requiresEmployed: true,
      minAge: 18,
      maxAge: 24,
    ),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'eve',
        label: 'Yarısıyla eve alışveriş yap',
        resultText:
            'Zarfın yarısıyla eve alışveriş yaptın, kalanı cebinde. '
            'Kimse bir şey demedi ama herkes gördü.',
        happiness: 4,
        money: 5000, // prototypeOnly: zarfın oyuncuda kalan yarısı
      ),
      EventChoice(
        id: 'kendine',
        label: 'Zarfı olduğu gibi sakla',
        resultText:
            'Zarfı açmadan kaldırdın. İlk defa yalnızca sana ait '
            'bir birikmiş paran var.',
        happiness: 3,
        charisma: 1,
        money: 9000, // prototypeOnly: zarfın tamamı
      ),
    ],
  ),

  // --- Küçük çeşitlilik paketi -------------------------------------------
  // Amaç havuzu onlarca benzer metinle şişirmek değil; tekrar eden olayların
  // arasına farklı sahneler koymaktır. Sayılar prototypeOnly'dir.
  GameEvent(
    id: 'kar_tatili',
    category: EventCategory.okul,
    text:
        'Sabah radyoda okulların tatil edildiğini duydun. Cam buğulu, '
        'sokak bembeyaz, bütün gün senin.',
    requirement: EventRequirement(requiresSchoolStudent: true, minGrade: 1),
    repeatable: true,
    minAgeGap: 8,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'disari',
        label: 'Sokağa çık',
        resultText:
            'Eldivenin ıslandı, burnun dondu, yanakların yandı. '
            'Eve girdiğinde soba kokusu seni karşıladı.',
        happiness: 6,
        health: -1,
      ),
      EventChoice(
        id: 'evde',
        label: 'Evde kal, kitaba dal',
        resultText:
            'Battaniyenin altında bir kitabı bitirdin. Dışarıdaki '
            'bağırışlar fon sesi gibiydi.',
        intelligence: 3,
        happiness: 2,
      ),
    ],
  ),
  GameEvent(
    id: 'ogretmen_veli_notu',
    category: EventCategory.okul,
    text:
        'Ders bitiminde {sahipk} {kisi} seni yanına çağırdı ve katlanmış '
        'bir kâğıt verdi: "Bunu evde verirsin, velinle görüşmek istiyorum." '
        'Nedenini söylemedi.',
    requirement: EventRequirement(
      requiresSchoolStudent: true,
      minGrade: 3,
      livingRelations: <RelationType>{RelationType.ogretmen},
    ),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'goster',
        label: 'Kâğıdı eve götür',
        resultText:
            'Kâğıdı akşam sofrada uzattın. Görüşme iyi geçmiş; '
            '{kisi} senin için iyi şeyler söylemiş.',
        happiness: 3,
        charisma: 2,
        bond: 7,
      ),
      EventChoice(
        id: 'sakla',
        label: 'Çantanın dibinde unut',
        resultText:
            'Kâğıt çantanın dibinde buruştu. {sahip} {kisi} ertesi '
            'gün bir şey sormadı, bir daha da çağırmadı.',
        happiness: -3,
        bond: -6,
      ),
    ],
  ),
  GameEvent(
    id: 'sinif_fotografi',
    category: EventCategory.okul,
    text:
        'Bahçede sıraya diziliyorsunuz, fotoğrafçı geldi. {sahip} {kisi} '
        'yanında yer ayırmış, eliyle çağırıyor.',
    requirement: EventRequirement(
      requiresSchoolStudent: true,
      livingRelations: <RelationType>{
        RelationType.sinifArkadasi,
        RelationType.arkadas,
      },
    ),
    repeatable: true,
    minAgeGap: 6,
    weight: 2,
    choices: <EventChoice>[
      EventChoice(
        id: 'yanina',
        label: 'Yanına geç',
        resultText:
            'Deklanşöre basıldığı an ikiniz de gülüyordunuz. '
            'O fotoğraf yıllarca bir çekmecede durdu.',
        happiness: 4,
        bond: 5,
      ),
      EventChoice(
        id: 'arkada',
        label: 'En arkada dur',
        resultText:
            'En arka sırada, yarı görünür bir yerdesin. '
            'Fotoğrafta seni ancak sen buluyorsun.',
        happiness: -1,
        bond: -2,
      ),
    ],
  ),
  GameEvent(
    id: 'aile_aksam_sofrasi',
    category: EventCategory.aile,
    text:
        'Akşam sofrası kuruldu, televizyonun sesi kısıldı. {sahip} '
        '{kisi} "anlat bakalım, bugün ne oldu?" diyor.',
    requirement: EventRequirement(
      minAge: 7,
      livingRelations: <RelationType>{
        RelationType.anne,
        RelationType.baba,
        RelationType.kardes,
      },
      requireSameHousehold: true,
    ),
    repeatable: true,
    minAgeGap: 8,
    weight: 2,
    choices: <EventChoice>[
      EventChoice(
        id: 'anlat',
        label: 'Gününü anlat',
        resultText: 'Anlattıkça anlattın. Yemek soğudu, kimse kalkmadı.',
        happiness: 4,
        bond: 6,
      ),
      EventChoice(
        id: 'kisa_kes',
        label: '"İyiydi" deyip kes',
        resultText:
            'Tek kelimeyle geçiştirdin. Sofrada bir sessizlik '
            'oldu, sonra televizyonun sesi yeniden açıldı.',
        happiness: -1,
        bond: -3,
      ),
    ],
  ),
  GameEvent(
    id: 'bakkal_veresiye',
    category: EventCategory.mahalle,
    text:
        'Bakkalda ekmek alacaksın, paran tam çıkmadı. Bakkal tezgâhın '
        'altından veresiye defterini çıkarıp açıyor: "Babanın hesabına '
        'yazayım mı?"',
    requirement: EventRequirement(minAge: 7, maxAge: 14),
    weight: 2,
    choices: <EventChoice>[
      EventChoice(
        id: 'yaz',
        label: 'Yazmasını iste',
        resultText:
            'Bakkal tarihi ve tutarı yazdı, sen de altını '
            'okudun. Borç küçüktü ama sorumluluk büyük hissettirdi.',
        happiness: 1,
        intelligence: 2,
      ),
      EventChoice(
        id: 'vazgec',
        label: 'Vazgeç, elin boş dön',
        resultText:
            'Ekmeği tezgâhta bıraktın. Eve vardığında kimse '
            'kızmadı; sen kendine kızdın.',
        happiness: -2,
        charisma: -1,
      ),
    ],
  ),
  // =====================================================================
  // Aile hayatı: eş ve çocuklar (Paket 2)
  //
  // Bu olaylar **gerçek kayıtlara** bağlıdır: eşi olmayan oyuncuya eş
  // olayı, çocuğu olmayana çocuk olayı çıkmaz. Çocuk olayları çocuğun
  // kendi yaşına göre seçilir (personMinAge/personMaxAge).
  // =====================================================================

  // --- Bebeklik ----------------------------------------------------------
  GameEvent(
    id: 'bebek_gece_aglamasi',
    category: EventCategory.aile,
    text:
        'Gece yarısı {sahipk} {kisi} ağlıyor. Yorgunsun, yarın da erken '
        'kalkacaksın.',
    requirement: EventRequirement(
      livingRelations: <RelationType>{RelationType.cocuk},
      personMaxAge: 2,
      requireSameHousehold: true,
    ),
    repeatable: true,
    minAgeGap: 3,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'kucagina_al',
        label: 'Kucağına al, sabaha kadar dolaş',
        resultText:
            'Odanın içinde yavaşça yürüdün. Bir süre sonra ağlama '
            'kesildi, omzunda uyudu. Sen uyuyamadın.',
        happiness: 3,
        health: -2,
        bond: 8,
      ),
      EventChoice(
        id: 'sirayla',
        label: 'Eşinle sırayla kalkmayı konuş',
        resultText:
            'Bu gece sen, yarın o. Konuşunca ikiniz de rahatladı; '
            'bebek de sırayı fark etmedi.',
        happiness: 2,
        bond: 4,
        addFlags: <String>{StoryFlags.bebekBakimiPaylasildi},
      ),
    ],
  ),

  // --- Okulun ilk günü: ileride hatırlanacak karar -----------------------
  GameEvent(
    id: 'cocuk_ilk_okul_gunu',
    category: EventCategory.aile,
    text:
        '{sahip} {kisi} bugün okula başlıyor. Okul bahçesinde elini '
        'tutuyor ve bırakmak istemiyor. İşe de geç kalıyorsun.',
    requirement: EventRequirement(
      livingRelations: <RelationType>{RelationType.cocuk},
      personMinAge: 6,
      personMaxAge: 7,
    ),
    weight: 8,
    choices: <EventChoice>[
      EventChoice(
        id: 'kal',
        label: 'Zil çalana kadar yanında kal',
        resultText:
            'Zil çalana kadar bahçede durdun. Sıraya girerken bir '
            'kez daha döndü, el salladı. İşe geç kaldın, kimse ölmedi.',
        happiness: 4,
        bond: 10,
        money: -1500,
        addFlags: <String>{StoryFlags.cocukIlkGunDestek},
        rememberPersonAs: StoryRoles.ilkOkulCocugu,
      ),
      EventChoice(
        id: 'birak',
        label: 'Öğretmene teslim edip işe git',
        resultText:
            'Öğretmenin elini tuttu, sen kapıdan çıktın. Akşam '
            'anlattıklarının hepsi güzeldi ama ilk cümlesi '
            '"beni bırakıp gittin" oldu.',
        happiness: -3,
        bond: -4,
        addFlags: <String>{StoryFlags.cocukIlkGunYalniz},
        rememberPersonAs: StoryRoles.ilkOkulCocugu,
      ),
    ],
  ),

  // --- Okul hayatı -------------------------------------------------------
  GameEvent(
    id: 'cocuk_karne_gunu',
    category: EventCategory.aile,
    text:
        '{sahip} {kisi} karnesiyle geldi. Kapıda duruyor, karneyi '
        'arkasında tutuyor.',
    requirement: EventRequirement(
      livingRelations: <RelationType>{RelationType.cocuk},
      personMinAge: 7,
      personMaxAge: 17,
    ),
    repeatable: true,
    minAgeGap: 5,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'kutla',
        label: 'Notlara bakmadan sarıl',
        resultText:
            'Önce sarıldın, sonra baktın. Karnede iki zayıf vardı '
            'ama o gün konuşulan konu bu olmadı.',
        happiness: 4,
        bond: 8,
      ),
      EventChoice(
        id: 'incele',
        label: 'Tek tek incele',
        resultText:
            'Ders ders konuştunuz. Bazı yerlerde haklıydın, '
            'bazı yerlerde karşındaki yedi yaşındaydı.',
        intelligence: 2,
        bond: -2,
      ),
    ],
  ),
  GameEvent(
    id: 'cocuk_okul_sorunu',
    category: EventCategory.aile,
    text:
        'Okuldan aradılar: {sahipk} {kisi} teneffüste bir tartışmaya '
        'karışmış. Öğretmen seni bekliyor.',
    requirement: EventRequirement(
      livingRelations: <RelationType>{RelationType.cocuk},
      personMinAge: 8,
      personMaxAge: 16,
    ),
    repeatable: true,
    minAgeGap: 6,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'once_dinle',
        label: 'Önce çocuğunu dinle',
        resultText:
            'Eve dönerken anlattı. Haklı olduğu bir yer vardı, '
            'haksız olduğu iki yer. İkisini de konuştunuz.',
        happiness: 2,
        bond: 6,
        intelligence: 1,
      ),
      EventChoice(
        id: 'ogretmene_hak_ver',
        label: 'Öğretmenin yanında ona çık',
        resultText:
            'Öğretmenin önünde azarladın. Mesele orada kapandı; '
            'eve kadar tek kelime konuşulmadı.',
        happiness: -2,
        bond: -7,
      ),
    ],
  ),

  // --- Söz verme zinciri: ileride hatırlanır ------------------------------
  GameEvent(
    id: 'cocuk_bisiklet_istegi',
    category: EventCategory.aile,
    text:
        '{sahip} {kisi} vitrindeki bisikletin önünde durdu. Bir şey '
        'istemiyor, sadece bakıyor.',
    requirement: EventRequirement(
      livingRelations: <RelationType>{RelationType.cocuk},
      personMinAge: 6,
      personMaxAge: 12,
      forbiddenFlags: <String>{StoryFlags.cocugaSozVerildi},
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'simdi_al',
        label: 'Bugün al',
        resultText:
            'Kutusuyla eve taşıdınız. Akşam sokakta iki tur attı, '
            'üçüncüde düştü, dördüncüde yine bindi.',
        happiness: 5,
        bond: 10,
        money: -27000,
      ),
      EventChoice(
        id: 'soz_ver',
        label: 'Doğum gününde alacağına söz ver',
        resultText:
            'Söz verdin. Elini sıktı, çok ciddiydi. Bu sözün '
            'tutulup tutulmadığını unutmayacak.',
        happiness: 1,
        bond: 3,
        addFlags: <String>{StoryFlags.cocugaSozVerildi},
        rememberPersonAs: StoryRoles.sozVerilenCocuk,
      ),
    ],
  ),
  GameEvent(
    id: 'cocuk_sozun_hatirlatilmasi',
    category: EventCategory.aile,
    text:
        '{sahip} {kisi} bir şey istemiyor ama takvime bakıp duruyor. '
        'Geçen yıl verdiğin sözü ikiniz de hatırlıyorsunuz.',
    requirement: EventRequirement(
      personRole: StoryRoles.sozVerilenCocuk,
      requiredFlags: <String>{StoryFlags.cocugaSozVerildi},
      forbiddenFlags: <String>{
        StoryFlags.cocugaSozTutuldu,
        StoryFlags.cocugaSozUnutuldu,
      },
    ),
    weight: 7,
    choices: <EventChoice>[
      EventChoice(
        id: 'sozu_tut',
        label: 'Sözünü tut',
        resultText:
            'Bisiklet kapının önünde duruyordu. "Unutmadın" dedi. '
            'Unutmamıştın.',
        happiness: 6,
        bond: 12,
        money: -27000,
        addFlags: <String>{StoryFlags.cocugaSozTutuldu},
      ),
      EventChoice(
        id: 'ertele',
        label: 'Bu yıl da ertele',
        resultText:
            'Gerekçen geçerliydi. Bir şey demedi; bir daha da '
            'sormadı.',
        happiness: -4,
        bond: -10,
        addFlags: <String>{StoryFlags.cocugaSozUnutuldu},
      ),
    ],
  ),

  // --- Ergenlik: ilk okul günü kararının hatırlandığı yer ----------------
  GameEvent(
    id: 'cocuk_ergen_sessizlik',
    category: EventCategory.aile,
    text:
        '{sahip} {kisi} günlerdir odasından çıkmıyor. Kapı kapalı, '
        'müzik açık.',
    requirement: EventRequirement(
      personRole: StoryRoles.ilkOkulCocugu,
      personMinAge: 13,
      personMaxAge: 17,
      forbiddenFlags: <String>{StoryFlags.cocukIlkGunDestek},
    ),
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'kapiyi_cal',
        label: 'Kapıyı çal, ısrar etme',
        resultText:
            'Kapıyı araladın, "buradayım" dedin ve kapattın. '
            'İki gün sonra kendisi geldi.',
        happiness: 2,
        bond: 6,
      ),
      EventChoice(
        id: 'zorla',
        label: 'Kapıyı aç ve konuşmasını iste',
        resultText:
            'Konuşmadı. Kapı bir kez daha kapandı, bu sefer '
            'senin yüzüne.',
        happiness: -3,
        bond: -6,
      ),
    ],
  ),
  GameEvent(
    id: 'cocuk_ergen_guven',
    category: EventCategory.aile,
    text:
        '{sahip} {kisi} akşam mutfağa geldi, karşına oturdu. '
        '"Bir şey anlatacağım" dedi. Yıllar önce okulun ilk günü elini '
        'bırakmamıştın; bugün o kendi isteğiyle geldi.',
    requirement: EventRequirement(
      personRole: StoryRoles.ilkOkulCocugu,
      personMinAge: 13,
      personMaxAge: 18,
      requiredFlags: <String>{StoryFlags.cocukIlkGunDestek},
    ),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'dinle',
        label: 'Sonuna kadar dinle',
        resultText:
            'Uzun sürdü. Bir kez bile araya girmedin. Kalkarken '
            '"iyi ki anlattım" dedi.',
        happiness: 6,
        bond: 12,
      ),
      EventChoice(
        id: 'akil_ver',
        label: 'Hemen ne yapması gerektiğini söyle',
        resultText:
            'Cümlesini bitirmeden çözümü söyledin. Başını salladı, '
            'kalktı. Anlatacağı asıl şeyi anlatamadı.',
        happiness: -1,
        bond: -4,
      ),
    ],
  ),

  // --- Yetişkinlik ve evden ayrılma --------------------------------------
  GameEvent(
    id: 'cocuk_meslek_secimi',
    category: EventCategory.aile,
    text:
        '{sahip} {kisi} ne okuyacağına karar veremiyor. Senin ne '
        'düşündüğünü soruyor ama cevabı çoktan aklında gibi.',
    requirement: EventRequirement(
      livingRelations: <RelationType>{RelationType.cocuk},
      personMinAge: 17,
      personMaxAge: 20,
    ),
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'kendi_secsin',
        label: 'Kendi seçmesini söyle',
        resultText:
            'Seçimi kendisi yaptı. Doğru mu bilmiyorsun ama '
            'sorumluluğu da kendisinde.',
        happiness: 3,
        bond: 7,
        addFlags: <String>{StoryFlags.cocukKendiSecti},
      ),
      EventChoice(
        id: 'yonlendir',
        label: 'Sağlam bir meslek öner',
        resultText:
            'Senin dediğini yazdı. Kazandı da. Yıllar sonra o '
            'günü konuştuğunuzda ikiniz de farklı hatırlayacaksınız.',
        happiness: 1,
        intelligence: 1,
        bond: -3,
      ),
    ],
  ),
  GameEvent(
    id: 'cocuk_evden_ayrilma',
    category: EventCategory.aile,
    text:
        '{sahip} {kisi} kendi evine çıkmaktan söz ediyor. Kutular '
        'daha ortada yok ama karar verilmiş.',
    requirement: EventRequirement(
      livingRelations: <RelationType>{RelationType.cocuk},
      personMinAge: 22,
      personMaxAge: 25,
      requireSameHousehold: true,
    ),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'destek',
        label: 'Depozitoya destek ol',
        resultText:
            'Parayı sayarken "borcum olsun" dedi, "olmaz" dedin. '
            'İlk gece seni aradı; ev sessizmiş.',
        happiness: 3,
        bond: 9,
        money: -75000,
      ),
      EventChoice(
        id: 'kendi_bilsin',
        label: 'Kendi ayakları üstünde dursun',
        resultText:
            'Taşındı. İlk aylar zor geçti, sonra alıştı. '
            'Aranızdaki mesafe bir süre ev kirasından fazla oldu.',
        happiness: -2,
        bond: -5,
      ),
    ],
  ),

  // --- Eş ----------------------------------------------------------------
  GameEvent(
    id: 'es_ile_tartisma',
    category: EventCategory.aile,
    text:
        '{sahip} {kisi} ile aynı konuyu üçüncü kez konuşuyorsunuz. '
        'Konu aslında o konu değil, ikiniz de biliyorsunuz.',
    requirement: EventRequirement(
      livingRelations: <RelationType>{RelationType.es},
      forbiddenFlags: <String>{StoryFlags.esleKonusuldu},
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'konus',
        label: 'Asıl meseleyi konuş',
        resultText:
            'Gece yarısını geçti. Mesele bitmedi ama ilk kez '
            'doğru yerinden tutuldu.',
        happiness: 3,
        bond: 8,
        addFlags: <String>{StoryFlags.esleKonusuldu},
      ),
      EventChoice(
        id: 'sus',
        label: 'Tartışmayı kapat',
        resultText:
            'Konuyu kapattın. Ev sessizleşti; sessizlik de bir '
            'cevaptır.',
        happiness: -3,
        bond: -6,
        addFlags: <String>{StoryFlags.esleSusuldu},
      ),
    ],
  ),
  GameEvent(
    id: 'es_ile_eski_konusma',
    category: EventCategory.aile,
    text:
        '{sahip} {kisi} yıllar önce oturup konuştuğunuz o geceyi '
        'hatırlattı: "O gün kaçmasaydın bugün burada olmazdık."',
    requirement: EventRequirement(
      livingRelations: <RelationType>{RelationType.es},
      requiredFlags: <String>{StoryFlags.esleKonusuldu},
    ),
    repeatable: true,
    minAgeGap: 15,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'hatirla',
        label: 'Sen de hatırla',
        resultText:
            'İkiniz de aynı geceyi farklı hatırlıyordunuz; '
            'önemli olan kısmı aynıydı.',
        happiness: 5,
        bond: 7,
      ),
      EventChoice(
        id: 'gec',
        label: 'Konuyu değiştir',
        resultText: 'Güldün, konuyu değiştirdin. O da üstelemedi.',
        happiness: -1,
      ),
    ],
  ),
  GameEvent(
    id: 'es_is_karari',
    category: EventCategory.aile,
    text:
        '{sahip} {kisi} işini değiştirmeyi düşünüyor. Yeni iş daha '
        'az güvenli ama gözleri parlıyor.',
    requirement: EventRequirement(
      livingRelations: <RelationType>{RelationType.es},
      minAge: 25,
    ),
    repeatable: true,
    minAgeGap: 18,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'destekle',
        label: 'Destekle',
        resultText:
            'İlk aylar zor geçti. Sonra eve dönerken yüzündeki '
            'ifade değişti; o kadarı bile kârdı.',
        happiness: 4,
        bond: 9,
        money: -36000,
      ),
      EventChoice(
        id: 'karsi_cik',
        label: 'Riski hatırlat',
        resultText: 'Haklıydın, vazgeçti. Bazen haklı olmak yetmiyor.',
        happiness: -2,
        bond: -5,
      ),
    ],
  ),

  // --- Ziyaret: ayrı evde yaşayan yakınlar -------------------------------
  GameEvent(
    id: 'aile_ziyareti',
    category: EventCategory.aile,
    text:
        '{sahip} {kisi} haber vermeden kapıda: elinde poşet, '
        '"yoldan geçiyordum" diyor.',
    requirement: EventRequirement(
      minAge: 18,
      livingRelations: <RelationType>{
        RelationType.anne,
        RelationType.baba,
        RelationType.kardes,
        RelationType.cocuk,
      },
      requireOutsideHousehold: true,
    ),
    repeatable: true,
    minAgeGap: 9,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'sofra_kur',
        label: 'Sofrayı kur, kalsın',
        resultText:
            'Akşam yemeği uzadı. Gitmeden önce mutfakta bir şeyleri '
            'yerini değiştirdi; itiraz etmedin.',
        happiness: 4,
        bond: 8,
        money: -2500,
      ),
      EventChoice(
        id: 'kisa_kes',
        label: 'Kısa kes, işin var',
        resultText:
            'Çayını içti, kalktı. Kapıda "bir ara uğrarım" dedi; '
            'uğramadı.',
        happiness: -2,
        bond: -4,
      ),
    ],
  ),

  // Hayat evrelerine dağıtılmış paket (Paket 4).
  ...kLifeStageEvents,

  // İleri yaş, iş hayatı, komşuluk ve sonuç zincirleri (Paket F1).
  ...kExtraEvents,

  // Meslek hayatı: iş arkadaşları, sorumluluk ve zam görüşmeleri (Paket 9).
  ...kWorkEvents,

  // Ün ve sosyal medya (Paket 10).
  ...kSocialFameEvents,

  // Gezi sahneleri ve anıları (Paket 11).
  ...kTravelEvents,

  // İleri yaş, emeklilik ve torunlar (Paket 12).
  ...kElderEvents,

  // İlk yıllar: 0-4 yaş (Paket 13).
  ...kInfancyEvents,
  ...kExamEvents,
  ...kMidlifeEvents,

  // Yetişkinlikte tanışma ve bekâr hayat (Paket 23).
  ...kRomanceEvents,
  // Hobi olayları (Paket 39): yalnızca gerçek hobi geçmişi olana çıkar.
  ...kHobbyEvents,
  ...kPetEvents,

  // Yıllara yayılan çok adımlı zincirler: bir seçim, yıllar sonra
  // gerçek bir sonuç.
  ...kChainEvents,

  // Çocukluk ve ergenlik (D-126): hayatın ilk on sekiz yılı en fakir
  // dönemdi; `docs/EKSIKLER.md` ölçtü.
  ...kChildhoodEvents,
  ...kCrimeEvents,
];
