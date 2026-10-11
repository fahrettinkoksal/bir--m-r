/// 9-12 yaş: ortaokula giden yıllar (Paket AT).
///
/// **Neden var.** Olay havuzu yaş başına ölçüldü ve çocukluk, orta yaşın
/// onda biri kadar içerikle açılıyordu: 0 yaşında **1**, 6 yaşında 9,
/// 10 yaşında 15 "kapısız" olay varken 40 yaşında 78 vardı. Kapısız olay,
/// iz/kişi/sahiplik/iş/okul koşulu olmayan, yani neredeyse her oyuncuda
/// çıkabilen olay demek. Üstelik `event_pool_childhood.dart` 1-8 ve 13-15
/// yaşlara yoğunlaşmış, **9-12 arası tamamen boştu.**
///
/// Bu dönem oyunun ilk on dakikası ve herkesin gördüğü tek bölüm. Burası
/// fakir olduğunda oyun fakir açılıyor.
///
/// **Dönemin karakteri:** çocuk ilk kez kendi başına bir şeyler yapıyor —
/// yalnız markete gidiyor, parayı eline alıyor, ödevi kendi seçimiyle
/// yapıyor ya da yapmıyor, ilk kez bir şeyi biriktiriyor. Henüz işi, parası
/// ya da ilişkisi yok; elindeki tek şey **kararları**.
///
/// Kurallar:
/// - Olaylar bilerek **kapısız**: iz, kişi ya da sahiplik koşulu yok, ki
///   her oyuncu görsün. İçerideki üç küçük zincir kendi izini kendi
///   okuyor; dışarıya sessiz iz bırakılmıyor (AS/1 ölçütü).
/// - Dil `docs/WRITING_STYLE_TR.md`: çocuk basit ve doğrudan konuşur,
///   anlatıcı yaşanmış gibi yazar, sayı cümlenin içine gömülmez.
/// - Para yoksa dışlanma yok: ekonomik sıkıntı anlatılır ama oyuncuyu
///   cezalandırmaz; her olayda temiz bir kapı vardır.
library;

import '../domain/models/game_event.dart';
import '../domain/models/relation.dart';

/// Bu dönemin kendi izleri. Hepsi **bu dosya içinde** okunur.
abstract final class SchoolYearFlags {
  /// Yalnız markete gönderildi ve parayı doğru getirdi.
  static const String yalnizAlisveris = 'okul_yillari_yalniz_alisveris';

  /// Bakkaldan veresiye aldı.
  static const String veresiyeAldi = 'okul_yillari_veresiye';

  /// Bir şey için para biriktirmeye başladı.
  static const String birikimBasladi = 'okul_yillari_birikim';

  /// Biriktirdiğini alabildi.
  static const String birikimTamamlandi = 'okul_yillari_birikim_oldu';

  /// Ödevi kopyaladı.
  static const String odevKopyaladi = 'okul_yillari_odev_kopya';

  /// Sınıfta sorumluluk aldı (nöbetçi, başkan, bayrak).
  static const String sorumlulukAldi = 'okul_yillari_sorumluluk';
}

const List<GameEvent> kSchoolYearEvents = <GameEvent>[
  // ===================================================================
  // Okul — sınıfın içi
  // ===================================================================
  GameEvent(
    id: 'okul_yillari_karne_gunu',
    category: EventCategory.okul,
    text: 'Karne günü. Sıralar arasında dolaşan öğretmen senin adını '
        'okudu, kâğıdı uzattı ve bir şey demedi.\n\n'
        'Eve kadar katlı duracak.',
    requirement: EventRequirement(minAge: 9, maxAge: 12),
    repeatable: true,
    minAgeGap: 2,
    weight: 7,
    choices: <EventChoice>[
      EventChoice(
        id: 'hemen_goster',
        label: 'Eve varınca hemen göster',
        resultText: 'Kapıdan girer girmez uzattın. Uzun uzun baktılar, '
            'sonra "aferin, devam" dendi. Akşam tatlı vardı.',
        happiness: 4,
        charisma: 1,
      ),
      EventChoice(
        id: 'canta_dibi',
        label: 'Çantanın dibinde beklesin',
        resultText: 'İki gün sordular, "yarın veriyorlar" dedin. '
            'Üçüncü gün kendileri buldu. Konuşma kısa sürdü ama hoş '
            'olmadı.',
        happiness: -2,
        intelligence: 1,
      ),
      EventChoice(
        id: 'kendine_bak',
        label: 'Önce kendin otur incele',
        resultText: 'Notları tek tek okudun, iki tanesinin neden düşük '
            'olduğunu biliyordun. Bilmek, karnenin kendisinden daha '
            'çok işe yaradı.',
        intelligence: 3,
        happiness: 1,
      ),
    ],
  ),

  GameEvent(
    id: 'okul_yillari_nobetci',
    category: EventCategory.okul,
    text: 'Öğretmen sınıfa sordu: "Bu hafta tahtaya kim bakacak?"'
        '\n\nKimse elini kaldırmıyor.',
    requirement: EventRequirement(minAge: 9, maxAge: 12),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'kaldir',
        label: 'Elini kaldır',
        resultText: 'Bir hafta tahtayı sildin, tebeşiri sen getirdin. '
            'Cuma günü öğretmen "sen varsın" dedi; o cümle aklında '
            'kaldı.',
        charisma: 3,
        happiness: 2,
        addFlags: <String>{SchoolYearFlags.sorumlulukAldi},
      ),
      EventChoice(
        id: 'sessiz',
        label: 'Sessiz kal',
        resultText: 'Başka biri kaldırdı. Hafta boyunca tahta temizdi '
            've kimse senin adını anmadı.',
        happiness: 1,
      ),
    ],
  ),

  // Sorumluluk izinin karşılığı — aynı dosyada okunuyor.
  GameEvent(
    id: 'okul_yillari_toren_gorevi',
    category: EventCategory.okul,
    text: 'Tören için bir öğrenci seçecekler. Öğretmen listeye bakmadan '
        'sana döndü: "Sen yaparsın."',
    requirement: EventRequirement(
      minAge: 10,
      maxAge: 13,
      requiredFlags: <String>{SchoolYearFlags.sorumlulukAldi},
    ),
    weight: 7,
    choices: <EventChoice>[
      EventChoice(
        id: 'kabul',
        label: 'Kabul et',
        resultText: 'Bütün okulun önünde durdun. Sesin ilk cümlede '
            'titredi, sonrasında düzeldi. Alkışın bir kısmı gerçekten '
            'senin içindi.',
        charisma: 5,
        happiness: 4,
        intelligence: 1,
      ),
      EventChoice(
        id: 'reddet',
        label: '"Ben yapamam"',
        resultText: 'Öğretmen üstelemedi, başka birini seçti. Tören '
            'günü arkada durup izledin; fena da değildi.',
        happiness: -1,
        charisma: -1,
      ),
    ],
  ),

  GameEvent(
    id: 'okul_yillari_odev_kopya',
    category: EventCategory.okul,
    text: 'Ödevi yapmayı unuttun. Yanındaki sıra defterini uzatıyor: '
        '"Çabuk geçir, bir şey olmaz."',
    requirement: EventRequirement(minAge: 9, maxAge: 13),
    weight: 7,
    choices: <EventChoice>[
      EventChoice(
        id: 'gecir',
        label: 'Geçir',
        resultText: 'Teneffüsün yarısında bitirdin. Öğretmen defteri '
            'açtı, kaşını kaldırdı ama bir şey sormadı. O bakış bütün '
            'gün peşini bırakmadı.',
        happiness: -1,
        intelligence: -1,
        addFlags: <String>{SchoolYearFlags.odevKopyaladi},
      ),
      EventChoice(
        id: 'yapmadim_de',
        label: '"Yapmadım" de',
        resultText: 'Doğruyu söyledin. Bir uyarı aldın, bir de "yarın '
            'getireceksin" cümlesi. Getirdin.',
        intelligence: 2,
        charisma: 2,
        happiness: -1,
      ),
    ],
  ),

  // Kopya izinin karşılığı.
  GameEvent(
    id: 'okul_yillari_tahtaya_kalk',
    category: EventCategory.okul,
    text: 'Öğretmen ödev defterini eline aldı, sonra seni tahtaya '
        'çağırdı: "Hadi, şu soruyu bir de burada çöz."',
    requirement: EventRequirement(
      minAge: 9,
      maxAge: 13,
      requiredFlags: <String>{SchoolYearFlags.odevKopyaladi},
    ),
    weight: 8,
    choices: <EventChoice>[
      EventChoice(
        id: 'ugras',
        label: 'Elinden geleni yap',
        resultText: 'Yarısına kadar getirdin, sonra tıkandın. '
            'Öğretmen gerisini anlattı ve "defteri kendin yaz" dedi. '
            'Yazdın.',
        intelligence: 3,
        happiness: -1,
        removeFlags: <String>{SchoolYearFlags.odevKopyaladi},
      ),
      EventChoice(
        id: 'sus',
        label: 'Tahtanın önünde sus',
        resultText: 'Tebeşir elinde kaldı. Oturmana izin verdi, '
            'kimse gülmedi; en kötüsü de buydu.',
        happiness: -3,
        charisma: -2,
      ),
    ],
  ),

  GameEvent(
    id: 'okul_yillari_takim_secimi',
    category: EventCategory.okul,
    text: 'Beden dersinde iki kaptan sırayla isim okuyor. Sıra sonlara '
        'doğru geliyor ve sen hâlâ ayaktasın.',
    requirement: EventRequirement(minAge: 9, maxAge: 13),
    repeatable: true,
    minAgeGap: 3,
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'bekle',
        label: 'Bekle, sırası gelir',
        resultText: 'Sondan bir önce seçildin. Maçta iki top kestin, '
            'kaptan "iyiymiş" dedi. Bir dahaki sefere daha erken '
            'okundun.',
        charisma: 2,
        health: 1,
        happiness: 1,
      ),
      EventChoice(
        id: 'kaptan_ol',
        label: '"Ben kaptan olayım" de',
        resultText: 'Şaşırdılar ama itiraz da etmediler. Takımını sen '
            'kurdun; önce kimsenin seçmediklerini aldın.',
        charisma: 4,
        happiness: 3,
      ),
      EventChoice(
        id: 'cekil',
        label: 'Kenara çekil',
        resultText: 'Kendi kendine "zaten sevmiyorum" dedin. Maç '
            'boyunca duvarın dibinde oturdun.',
        happiness: -2,
        health: -1,
      ),
    ],
  ),

  // ===================================================================
  // Para — ilk kez elde tutulan
  // ===================================================================
  GameEvent(
    id: 'okul_yillari_yalniz_markete',
    category: EventCategory.aile,
    text: 'Eline bir kâğıt ve para tutuşturdular: "Ekmek, bir de '
        'yoğurt. Üstünü getir."\n\n'
        'İlk kez yalnız gidiyorsun.',
    requirement: EventRequirement(minAge: 9, maxAge: 12),
    weight: 8,
    choices: <EventChoice>[
      EventChoice(
        id: 'tam_getir',
        label: 'Listeyi al, üstünü getir',
        resultText: 'İkisini de aldın, parayı bozukluğuna kadar '
            'masaya koydun. "Bak sen" dediler. Ertesi hafta yine '
            'seni gönderdiler.',
        intelligence: 2,
        charisma: 2,
        happiness: 3,
        addFlags: <String>{SchoolYearFlags.yalnizAlisveris},
      ),
      EventChoice(
        id: 'ustune_seker',
        label: 'Üstüyle kendine bir şey al',
        resultText: 'Bir paket bir şey aldın, bozukluğu masaya '
            'koydun. Kimse saymadı ama sen biliyordun.',
        happiness: 2,
        intelligence: -1,
      ),
      EventChoice(
        id: 'unut',
        label: 'Yoğurdu unut',
        resultText: 'Eve ekmekle döndün. "Yoğurt?" dediler. Kâğıt '
            'hâlâ cebindeydi, okumayı akıl etmemişsin.',
        happiness: -2,
        intelligence: 1,
      ),
    ],
  ),

  GameEvent(
    id: 'okul_yillari_bakkal_veresiye',
    category: EventCategory.mahalle,
    text: 'Kantinde para yetmedi. Bakkal amca elini salladı: '
        '"Geç, yazarım deftere."',
    requirement: EventRequirement(minAge: 9, maxAge: 13),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'yaz',
        label: '"Yazın" de',
        resultText: 'Deftere bir satır düştü. Akşam evde söylemeyi '
            'erteledin, sonra söyledin; parayı verdiler ama bir de '
            '"önce bize sor" dediler.',
        happiness: 1,
        addFlags: <String>{SchoolYearFlags.veresiyeAldi},
      ),
      EventChoice(
        id: 'vazgec',
        label: 'Vazgeç',
        resultText: '"Kalsın" dedin, geri koydun. Teneffüsün kalanını '
            'susuz geçirdin; büyük bir şey de olmadı.',
        intelligence: 2,
        happiness: -1,
      ),
    ],
  ),

  // Veresiye izinin karşılığı.
  GameEvent(
    id: 'okul_yillari_defter_kapandi',
    category: EventCategory.mahalle,
    text: 'Bakkal amca seni görünce defteri açtı, bir şey çizdi ve '
        'kapattı: "Tamam, temiz."',
    requirement: EventRequirement(
      minAge: 10,
      maxAge: 14,
      requiredFlags: <String>{SchoolYearFlags.veresiyeAldi},
    ),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'tesekkur',
        label: 'Teşekkür et',
        resultText: '"Sağ ol amca" dedin. "Sen adamsın" dedi. '
            'O gün mahallede yürürken bir karış daha uzun gibiydin.',
        charisma: 3,
        happiness: 3,
        removeFlags: <String>{SchoolYearFlags.veresiyeAldi},
      ),
      EventChoice(
        id: 'bir_daha_yok',
        label: '"Bir daha yazdırmam"',
        resultText: 'Güldü, "yazdırırsın" dedi. Haklı çıkıp '
            'çıkmayacağı sende.',
        intelligence: 2,
        happiness: 1,
        removeFlags: <String>{SchoolYearFlags.veresiyeAldi},
      ),
    ],
  ),

  GameEvent(
    id: 'okul_yillari_birikim',
    category: EventCategory.kisisel,
    text: 'Vitrinde bir şey var ve fiyatı cebindekinin çok üstünde.'
        '\n\nHesap yaptın: her hafta biraz artırsan, yazın sonuna '
        'yetişir.',
    requirement: EventRequirement(minAge: 9, maxAge: 13),
    weight: 7,
    choices: <EventChoice>[
      EventChoice(
        id: 'basla',
        label: 'Biriktirmeye başla',
        resultText: 'Bir kutu buldun, üstüne de ne alacağını yazdın. '
            'İlk hafta kutu neredeyse boştu ama bir şey başlamıştı.',
        intelligence: 3,
        happiness: 1,
        addFlags: <String>{SchoolYearFlags.birikimBasladi},
      ),
      EventChoice(
        id: 'simdi_harca',
        label: 'Elindekini bugün harca',
        resultText: 'Küçük bir şey aldın, akşama kadar keyfin vardı. '
            'Vitrin ertesi gün de aynı yerdeydi.',
        happiness: 3,
        intelligence: -1,
      ),
    ],
  ),

  // Birikim izinin karşılığı — iki kol, ikisi de izi kapatıyor.
  GameEvent(
    id: 'okul_yillari_kutu_doldu',
    category: EventCategory.kisisel,
    text: 'Kutuyu masaya döküp saydın. Yetiyor.\n\n'
        'Hem de tam yetiyor.',
    requirement: EventRequirement(
      minAge: 9,
      maxAge: 14,
      requiredFlags: <String>{SchoolYearFlags.birikimBasladi},
    ),
    weight: 8,
    choices: <EventChoice>[
      EventChoice(
        id: 'al',
        label: 'Gidip al',
        resultText: 'Parayı tezgaha sen koydun, poşeti sen taşıdın. '
            'Birinin alıp vermesiyle aynı şey değildi; bunu o gün '
            'anladın.',
        happiness: 8,
        intelligence: 2,
        charisma: 1,
        addFlags: <String>{SchoolYearFlags.birikimTamamlandi},
        removeFlags: <String>{SchoolYearFlags.birikimBasladi},
      ),
      EventChoice(
        id: 'sakla',
        label: 'Dursun, başka şeye',
        resultText: 'Kutuyu geri kaldırdın. Almak için biriktirdiğin '
            'şey artık o kadar da önemli değildi; biriktirmek '
            'önemliydi.',
        intelligence: 4,
        happiness: 2,
        addFlags: <String>{SchoolYearFlags.birikimTamamlandi},
        removeFlags: <String>{SchoolYearFlags.birikimBasladi},
      ),
    ],
  ),

  GameEvent(
    id: 'okul_yillari_gezi_parasi',
    category: EventCategory.okul,
    text: 'Sınıf gezisi için para toplanıyor. Öğretmen "getiremeyen '
        'söylesin, bir şey ayarlarız" dedi.',
    requirement: EventRequirement(minAge: 9, maxAge: 13),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'evde_sor',
        label: 'Evde sor',
        resultText: 'Sordun. Biraz düşündüler, sonra "tamam" dendi. '
            'Parayı verirken yüzlerindeki hesabı gördün ama gezi '
            'güzeldi.',
        happiness: 4,
        charisma: 2,
      ),
      EventChoice(
        id: 'ogretmene_soyle',
        label: 'Öğretmene durumu söyle',
        resultText: 'Teneffüste kimse yokken söyledin. "Tamam, sen '
            'gel" dedi, bir daha da konu açılmadı. Otobüste sen de '
            'vardın.',
        happiness: 3,
        charisma: 1,
        intelligence: 1,
      ),
      EventChoice(
        id: 'gitmem_de',
        label: '"Gitmeyeceğim" de',
        resultText: 'Gezi günü okulda üç kişiydiniz. Kütüphanede '
            'oturdun, bir kitap bitirdin.',
        intelligence: 3,
        happiness: -2,
      ),
    ],
  ),

  // ===================================================================
  // Mahalle ve ev
  // ===================================================================
  GameEvent(
    id: 'okul_yillari_bisiklet_siniri',
    category: EventCategory.mahalle,
    text: 'Çocuklar bir sonraki mahalleye kadar gidiyor. "Sen '
        'gelmiyor musun?"\n\n'
        'Evden "sokaktan çıkma" demişlerdi.',
    requirement: EventRequirement(minAge: 9, maxAge: 12),
    weight: 7,
    choices: <EventChoice>[
      EventChoice(
        id: 'git',
        label: 'Git',
        resultText: 'Gittiniz. Dönüşte lastik patladı ve bisikleti '
            'ite ite geldin. Eve vardığında hava kararmıştı; '
            'konuşma uzun sürdü.',
        happiness: 2,
        health: -1,
        charisma: 2,
      ),
      EventChoice(
        id: 'sinirda_kal',
        label: 'Sokağın başında bekle',
        resultText: 'Köşeye kadar gidip durdun, onları orada '
            'bekledin. Anlattıklarını dinledin; gitmiş gibi olmadı '
            'ama sözünü de tutmuştun.',
        happiness: 1,
        intelligence: 2,
      ),
      EventChoice(
        id: 'izin_iste',
        label: 'Koşup izin iste',
        resultText: 'Eve koştun, nefes nefese sordun. "Yarım saat" '
            'dediler. Yarım saat çok şeye yetiyormuş.',
        happiness: 4,
        charisma: 2,
        intelligence: 1,
      ),
    ],
  ),

  GameEvent(
    id: 'okul_yillari_sokak_kedisi',
    category: EventCategory.mahalle,
    text: 'Apartmanın girişinde küçük bir kedi var ve kimse '
        'sahiplenmiyor. Yağmur da başladı.',
    requirement: EventRequirement(minAge: 9, maxAge: 13),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'kutu_yap',
        label: 'Kapıya bir kutu koy',
        resultText: 'Kartondan bir şey yaptın, içine eski bir tişört '
            'koydun. Sabah kedi hâlâ oradaydı ve artık senin '
            'bakışını tanıyordu.',
        happiness: 4,
        charisma: 1,
      ),
      EventChoice(
        id: 'eve_sor',
        label: 'Eve almayı sor',
        resultText: 'Sordun. Cevap "olmaz" oldu ama mama parası '
            'verdiler. İkisi aynı şey değildi; yine de bir şeydi.',
        happiness: 2,
        charisma: 2,
      ),
      EventChoice(
        id: 'gec',
        label: 'Geç',
        resultText: 'Yukarı çıktın. Pencereden iki kez baktın, '
            'üçüncüde bakmadın.',
        happiness: -2,
      ),
    ],
  ),

  GameEvent(
    id: 'okul_yillari_yeni_komsu_cocuk',
    category: EventCategory.mahalle,
    text: 'Üst kata biri taşındı, senin yaşlarında bir çocuk var. '
        'Merdivende karşılaştınız, ikiniz de bir şey demediniz.',
    requirement: EventRequirement(minAge: 9, maxAge: 13),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'selam',
        label: 'Selam ver, adını sor',
        resultText: 'İki cümle konuştunuz, üçüncüsünde ortak bir şey '
            'buldunuz. Akşam aşağıda buluştunuz.',
        charisma: 3,
        happiness: 4,
        startsFriendship: true,
      ),
      EventChoice(
        id: 'bekle',
        label: 'O konuşursa konuş',
        resultText: 'Kimse başlamadı. Haftalarca merdivende başını '
            'sallayıp geçtiniz.',
        happiness: -1,
      ),
    ],
  ),

  GameEvent(
    id: 'okul_yillari_ekran_suresi',
    category: EventCategory.aile,
    text: '"Kapat artık şunu." Üçüncü kez söylendi ve sesin tonu '
        'değişti.',
    requirement: EventRequirement(minAge: 9, maxAge: 13),
    repeatable: true,
    minAgeGap: 2,
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'kapat',
        label: 'Kapat',
        resultText: 'Kapattın. Canın sıkıldı, sonra sıkılmaktan bir '
            'şey çıktı: eski bir kutu oyun buldun.',
        happiness: 1,
        intelligence: 2,
      ),
      EventChoice(
        id: 'bes_dakika',
        label: '"Beş dakika" de',
        resultText: 'Beş dakika yirmi oldu. Priz çekildi, akşamın '
            'geri kalanı sessiz geçti.',
        happiness: -2,
        charisma: -1,
      ),
    ],
  ),

  GameEvent(
    id: 'okul_yillari_ev_isine_yardim',
    category: EventCategory.aile,
    text: 'Mutfakta bir telaş var, sofra kurulacak ve kimse senden '
        'bir şey istemedi.',
    requirement: EventRequirement(minAge: 9, maxAge: 13),
    repeatable: true,
    minAgeGap: 3,
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'kur',
        label: 'Sofrayı sen kur',
        resultText: 'Tabakları, çatalları sen dizdin. Biri mutfaktan '
            'bakıp durdu, bir şey demedi ama gülümsedi.',
        charisma: 3,
        happiness: 3,
      ),
      EventChoice(
        id: 'odana_git',
        label: 'Odana git',
        resultText: 'Kapıyı kapattın. Sofra yine kuruldu, seslendiler, '
            'oturdun.',
        happiness: 1,
      ),
    ],
  ),

  GameEvent(
    id: 'okul_yillari_ilk_roman',
    category: EventCategory.kisisel,
    text: 'Kütüphanede resimsiz, kalın bir kitap aldın. İlk sayfa zor '
        'geldi.',
    requirement: EventRequirement(minAge: 9, maxAge: 13),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'devam',
        label: 'Zorla da olsa devam et',
        resultText: 'Yirminci sayfadan sonra kolaylaştı, sonra '
            'bırakamadın. Son sayfayı gece battaniyenin altında '
            'okudun.',
        intelligence: 5,
        happiness: 3,
        health: -1,
      ),
      EventChoice(
        id: 'geri_ver',
        label: 'Geri ver, başkasını al',
        resultText: 'Resimli bir tane aldın, onu aynı gün bitirdin. '
            'Kalın olan rafta kaldı.',
        happiness: 2,
        intelligence: 1,
      ),
    ],
  ),

  GameEvent(
    id: 'okul_yillari_akraba_yazi',
    category: EventCategory.aile,
    text: 'Yaz tatili başladı ve kuzenler geliyor. Ev iki haftalığına '
        'kalabalık olacak.',
    requirement: EventRequirement(
      minAge: 9,
      maxAge: 13,
      livingRelations: <RelationType>{RelationType.kardes},
    ),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'odani_ver',
        label: 'Odanı paylaş',
        resultText: 'İki hafta yerde yattın ve iki hafta hiç '
            'sıkılmadın. Gittiklerinde ev fazla sessiz geldi.',
        happiness: 5,
        charisma: 3,
        health: -1,
      ),
      EventChoice(
        id: 'kendi_kosen',
        label: 'Kendi köşende kal',
        resultText: 'Odanı kimseye açmadın. Kalabalığı kapının '
            'arkasından dinledin.',
        happiness: -1,
        intelligence: 1,
      ),
    ],
  ),

  // Birikim izinin karşılığı — çocukken öğrenilen şey ergenlikte
  // geri dönüyor. Bu olay olmadan `birikimTamamlandi` sessiz bir iz
  // olarak kalıyordu ve bekçi testi bunu yakaladı (AS/1 ölçütü).
  GameEvent(
    id: 'okul_yillari_kutu_hatirlandi',
    category: EventCategory.kisisel,
    text: 'İstediğin bir şeyin fiyatını gördün ve içinden hesap '
        'yapmaya başladın.\n\n'
        'Çocukken bir kutun vardı; aynı hesabı orada öğrenmişsin.',
    requirement: EventRequirement(
      minAge: 14,
      maxAge: 19,
      requiredFlags: <String>{SchoolYearFlags.birikimTamamlandi},
    ),
    weight: 7,
    choices: <EventChoice>[
      EventChoice(
        id: 'ayni_yol',
        label: 'Aynı yolu yine dene',
        resultText: 'Bir kenara ayırmaya başladın. Bu sefer kutu '
            'değil, telefondaki bir not. Yöntem aynı, sen biraz '
            'daha sabırlısın.',
        intelligence: 4,
        happiness: 3,
        removeFlags: <String>{SchoolYearFlags.birikimTamamlandi},
      ),
      EventChoice(
        id: 'borc_ara',
        label: 'Birinden isteyeyim',
        resultText: 'Sordun, verdiler. Elindeydi ama bekleyerek '
            'almanın tadı yoktu; bunu da o gün fark ettin.',
        happiness: 1,
        charisma: -1,
        removeFlags: <String>{SchoolYearFlags.birikimTamamlandi},
      ),
    ],
  ),

  // Yalnız alışveriş izinin karşılığı.
  GameEvent(
    id: 'okul_yillari_artik_sen_gidiyorsun',
    category: EventCategory.aile,
    text: 'Artık liste bile yazmıyorlar. "Sen biliyorsun" deyip parayı '
        'uzatıyorlar.',
    requirement: EventRequirement(
      minAge: 10,
      maxAge: 14,
      requiredFlags: <String>{SchoolYearFlags.yalnizAlisveris},
    ),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'ucuzunu_bul',
        label: 'Ucuzunu araştır',
        resultText: 'İki dükkâna girdin, aynı şeyi daha azına aldın. '
            'Kalanı uzattığında "bunu nereden öğrendin" dediler.',
        intelligence: 4,
        charisma: 2,
        happiness: 2,
        removeFlags: <String>{SchoolYearFlags.yalnizAlisveris},
      ),
      EventChoice(
        id: 'hep_ayni_yer',
        label: 'Hep aynı yerden al',
        resultText: 'Alıştığın dükkâna gittin, alıştığın şeyleri '
            'aldın. İş görüyordu.',
        happiness: 1,
        removeFlags: <String>{SchoolYearFlags.yalnizAlisveris},
      ),
    ],
  ),
];
