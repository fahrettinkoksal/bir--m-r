/// Okul öncesi yıllar: 3-6 yaş (Paket DE).
///
/// **Neden var.** Yaş bandı yoğunluğu yeniden ölçüldü (160 bot hayatı,
/// `BotLifeResult.eventsByAge`):
///
/// | bant | yıl başına olay | farklı olay |
/// |---|---|---|
/// | 0-2 bebeklik | 1,00 | 36 |
/// | **3-6 okul öncesi** | **1,04** | **55** |
/// | 7-11 ilkokul | 1,47 | 103 |
/// | 12-15 ergenlik | 1,57 | 130 |
/// | 16-20 eşik | 1,67 | 166 |
/// | 21-29 | 1,76 | 197 |
/// | 30-39 | 1,81 | 259 |
/// | 40-49 | 1,74 | 269 |
/// | 50-59 | 1,71 | 280 |
/// | 65-74 | 1,63 | 267 |
/// | 75+ | 1,47 | 187 |
///
/// Yani 0-2'yi Paket CX doldurduktan sonra **en ince bant 3-6 kaldı**:
/// farklı olay sayısı ilkokulun yarısından az. `docs/EKSIKLER.md` §4.1
/// zaten "çocukluk en fakir dönemdi" diyordu; ölçüm hâlâ onu
/// gösteriyor.
///
/// **Yıl başına 1,04 sayısının tavanı yok, tabanı var.** Motor yılın bir
/// olayını her zaman çeker; ek olay için üç ilerleme adımı ister
/// (D-125) ve bu yaşta çocuk ilerleme adımı üretmiyor. Yani bu bandın
/// yoğunluğu **havuzun genişliğiyle** değil motorun kuralıyla sınırlı;
/// bu dosyanın işi yıl başına olay sayısını artırmak değil, o bir
/// olayın **hep aynı altı olay olmasını** engellemek.
///
/// **Bu yaşta kararı aile verir.** Seçimler çocuğun hesaplı tercihi gibi
/// sunulmaz; ev halkının davranışı ile çocuğun tepkisi arasında durur.
/// Hiçbiri tıbbi ya da pedagojik tavsiye değildir.
///
/// Modül anahtarı: `FeatureId.okulOncesiYillar`. Kapatma tarifi:
/// `docs/FEATURE_FLAGS.md`.
library;

import '../domain/models/game_event.dart';
import '../domain/models/relation.dart';

/// Okul öncesi yılların bıraktığı, sonradan okunan izler.
///
/// **Her izin bir okuyanı var** (bu dosyanın sonundaki karşılık
/// olayları). Paket AR/CZ'nin kuralı: okunmayan iz yazılmaz.
abstract final class PreschoolFlags {
  /// Misafir önünde şiir/şarkı söyledi.
  static const String misafirSahnesi = 'okul_oncesi_misafir_sahnesi';

  /// Kalabalıkta birkaç dakika kayboldu.
  static const String kalabalikta = 'okul_oncesi_kalabalikta_kayboldu';

  /// Duvara çizdi ve çizgi bir süre orada kaldı.
  static const String duvardakiCizgi = 'okul_oncesi_duvardaki_cizgi';

  /// Bayram harçlığını biriktirdi.
  static const String harcligiBiriktirdi = 'okul_oncesi_harcligi_biriktirdi';

  /// Yazı köyde/akrabada geçirdi.
  static const String yazKoyde = 'okul_oncesi_yaz_koyde';

  /// Mahalle çocuklarının oyununa katıldı.
  static const String sokakOyunu = 'okul_oncesi_sokak_oyunu';
}

const List<GameEvent> kPreschoolEvents = <GameEvent>[
  // -------------------------------------------------------------------
  // Ev içi
  // -------------------------------------------------------------------
  GameEvent(
    id: 'okul_oncesi_misafir_siiri',
    category: EventCategory.aile,
    text: 'Misafir geldi, çay demlendi. Sonra o cümle: "hadi bize bir '
        'şey söyle." Bütün salon sana döndü.',
    requirement: EventRequirement(
      minAge: 3,
      maxAge: 6,
      livingRelations: <RelationType>{RelationType.anne, RelationType.baba},
      requireSameHousehold: true,
    ),
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'soyledi',
        label: 'Ortaya çık, söyle',
        resultText: 'Yarısını unuttun, kimse fark etmedi. Alkış uzun '
            'sürdü, {sahip} o günü yıllarca anlattı.',
        happiness: 5,
        charisma: 3,
        bond: 3,
        addFlags: <String>{PreschoolFlags.misafirSahnesi},
      ),
      EventChoice(
        id: 'saklandi',
        label: 'Perdenin arkasına geç',
        resultText: 'Perdeyi kendine doladın ve orada bekledin. '
            'Misafir gülüp konuyu değiştirdi.',
        happiness: 1,
        bond: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'okul_oncesi_duvara_cizgi',
    category: EventCategory.aile,
    text: 'Kalem eline geçti, kâğıt küçük geldi. Koridorun duvarında '
        'artık bir şey var.',
    requirement: EventRequirement(
      minAge: 3,
      maxAge: 6,
      livingRelations: <RelationType>{RelationType.anne, RelationType.baba},
      requireSameHousehold: true,
    ),
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'kaldi',
        label: 'Silinmesin, kalsın',
        resultText: 'Boya kutusu kapandı ama duvar silinmedi. O köşe '
            'uzun süre öyle durdu.',
        happiness: 4,
        bond: 3,
        addFlags: <String>{PreschoolFlags.duvardakiCizgi},
      ),
      EventChoice(
        id: 'silindi',
        label: 'Birlikte sil',
        resultText: 'Islak bezle beraber sildiniz. Kalemler daha yüksek '
            'bir rafa çıktı.',
        happiness: 1,
        intelligence: 1,
        bond: 2,
      ),
    ],
  ),
  GameEvent(
    id: 'okul_oncesi_cizgi_film_pazarligi',
    category: EventCategory.aile,
    text: 'Bir bölüm daha istiyorsun. Saat geç, cevap belli; yine de '
        'denemek lazım.',
    requirement: EventRequirement(
      minAge: 3,
      maxAge: 6,
      livingRelations: <RelationType>{RelationType.anne, RelationType.baba},
      requireSameHousehold: true,
    ),
    repeatable: true,
    minAgeGap: 2,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'pazarlik',
        label: '"Son bir tane"',
        resultText: 'Pazarlık tuttu. Son bölümün yarısında uyuyakaldın, '
            'kucakta taşındın.',
        happiness: 3,
        charisma: 2,
      ),
      EventChoice(
        id: 'uyku',
        label: 'Kapat, yatağa git',
        resultText: 'İtiraz etmedin. Sabah erken kalktın ve ev henüz '
            'uyanmamıştı.',
        happiness: 1,
        health: 2,
      ),
    ],
  ),
  GameEvent(
    id: 'okul_oncesi_elektrik_kesintisi',
    category: EventCategory.aile,
    text: 'Işıklar gitti. Mum bulundu, herkes aynı odada toplandı. '
        'Televizyon yok, konuşmak var.',
    requirement: EventRequirement(
      minAge: 3,
      maxAge: 6,
      livingRelations: <RelationType>{RelationType.anne, RelationType.baba},
      requireSameHousehold: true,
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'hikaye',
        label: 'Hikâye istemek',
        resultText: 'Anlatılan hikâyenin yarısı uydurmaydı. Işıklar '
            'gelince "biraz daha kalsın" dedin.',
        happiness: 5,
        bond: 4,
        intelligence: 1,
      ),
      EventChoice(
        id: 'golge',
        label: 'Duvarda gölge oyunu',
        resultText: 'Elinden tavşan çıkmadı ama kuş oldu. Mumun önünden '
            'kimse seni kaldıramadı.',
        happiness: 4,
        bond: 2,
      ),
    ],
  ),

  // -------------------------------------------------------------------
  // Mahalle
  // -------------------------------------------------------------------
  GameEvent(
    id: 'okul_oncesi_sokaga_cikma',
    category: EventCategory.mahalle,
    text: 'Aşağıda top sesi var. Senden büyük çocuklar oynuyor ve '
        'kapı aralık.',
    requirement: EventRequirement(
      minAge: 4,
      maxAge: 6,
      livingRelations: <RelationType>{RelationType.anne, RelationType.baba},
      requireSameHousehold: true,
    ),
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'katildi',
        label: 'Aşağı in, oyuna gir',
        resultText: 'Kaleye geçtin, iki gol yedin, kimse kızmadı. '
            'Akşam seslenildiğinde çıkmak istemedin.',
        happiness: 5,
        charisma: 3,
        health: 2,
        addFlags: <String>{PreschoolFlags.sokakOyunu},
      ),
      EventChoice(
        id: 'balkondan',
        label: 'Balkondan izle',
        resultText: 'Balkonun demirinden izledin. Oyunun kurallarını '
            'oradan öğrendin.',
        happiness: 2,
        intelligence: 2,
      ),
    ],
  ),
  GameEvent(
    id: 'okul_oncesi_oyuncak_kavgasi',
    category: EventCategory.mahalle,
    text: 'Aynı oyuncağı iki kişi tutuyor. Biri sensin, diğeri '
        'alt kattan.',
    requirement: EventRequirement(
      minAge: 3,
      maxAge: 6,
      livingRelations: <RelationType>{RelationType.anne, RelationType.baba},
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'biraktin',
        label: 'Bırak, onda kalsın',
        resultText: 'Bıraktın. Ertesi gün o çocuk kapıya kendi '
            'oyuncağıyla geldi.',
        happiness: 2,
        charisma: 3,
        bond: 1,
      ),
      EventChoice(
        id: 'birakmadin',
        label: 'Bırakma',
        resultText: 'Oyuncak sende kaldı ama oyun bitti. Akşam ikinizin '
            'de evinde aynı konu konuşuldu.',
        happiness: 1,
        charisma: -1,
      ),
    ],
  ),
  GameEvent(
    id: 'okul_oncesi_pazar_gunu',
    category: EventCategory.mahalle,
    text: 'Pazara gidildi. Elin tutuldu, tezgâhların arası kalabalık '
        've her şey senin boyundan yukarıda.',
    requirement: EventRequirement(
      minAge: 3,
      maxAge: 6,
      livingRelations: <RelationType>{RelationType.anne, RelationType.baba},
      requireSameHousehold: true,
    ),
    repeatable: true,
    minAgeGap: 2,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'eli_tuttu',
        label: 'Eli bırakma',
        resultText: 'Dönüşte filenin birini sen taşıdın; ağırdı, '
            'bırakmadın.',
        happiness: 3,
        bond: 3,
      ),
      EventChoice(
        id: 'kayboldu',
        label: 'Bir tezgâha dalıp kal',
        resultText: 'Üç dakika sürdü, üç saat gibi geldi. Bulunduğunda '
            'kimse kızmadı, sadece el sıkı tutuldu.',
        happiness: -2,
        bond: 4,
        addFlags: <String>{PreschoolFlags.kalabalikta},
      ),
    ],
  ),

  // -------------------------------------------------------------------
  // Aile ve akraba
  // -------------------------------------------------------------------
  GameEvent(
    id: 'okul_oncesi_bayram_harcligi',
    category: EventCategory.aile,
    text: 'Bayram sabahı. El öpüldü, avucuna katlanmış para kondu ve '
        'cebin ilk kez kendi parasıyla doldu.',
    requirement: EventRequirement(
      minAge: 4,
      maxAge: 6,
      livingRelations: <RelationType>{
        RelationType.anneanne,
        RelationType.babaanne,
        RelationType.anneTarafiDede,
        RelationType.babaTarafiDede,
      },
    ),
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'biriktirdi',
        label: 'Kumbaraya at',
        resultText: 'Kumbara ağırlaştı. Sallayıp dinlemek günlerce '
            'sürdü.',
        happiness: 3,
        intelligence: 2,
        money: 300,
        addFlags: <String>{PreschoolFlags.harcligiBiriktirdi},
      ),
      EventChoice(
        id: 'harcadi',
        label: 'Bakkala koş',
        resultText: 'Bir solukta bitti. Ne aldığını bugün hatırlamıyor '
            'olabilirsin ama o koşuyu hatırlıyorsun.',
        happiness: 5,
      ),
    ],
  ),
  GameEvent(
    id: 'okul_oncesi_buyukler_yaninda_kalma',
    category: EventCategory.aile,
    text: 'Bir iki gün büyüklerde kalacaksın. Çanta hazır, kapıda '
        'durdun.',
    requirement: EventRequirement(
      minAge: 3,
      maxAge: 6,
      livingRelations: <RelationType>{
        RelationType.anneanne,
        RelationType.babaanne,
        RelationType.anneTarafiDede,
        RelationType.babaTarafiDede,
      },
    ),
    repeatable: true,
    minAgeGap: 2,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'kaldi',
        label: 'Kal, iyi olur',
        resultText: 'Akşam yemeği erken, yatma saati gevşek. '
            'Dönerken bir poşet yemek de verildi.',
        happiness: 4,
        bond: 5,
      ),
      EventChoice(
        id: 'donmek',
        label: 'Akşam eve dönmek istemek',
        resultText: 'Gece olmadan dönüldü. Kimse "neden" diye '
            'sormadı.',
        happiness: 1,
        bond: 2,
      ),
    ],
  ),
  GameEvent(
    id: 'okul_oncesi_yaz_koyu',
    category: EventCategory.aile,
    text: 'Yaz geldi, yol göründü. Şehrin dışında bir ev, bir avlu ve '
        'senden başka çocuklar.',
    requirement: EventRequirement(
      minAge: 4,
      maxAge: 6,
      livingRelations: <RelationType>{
        RelationType.anneanne,
        RelationType.babaanne,
        RelationType.anneTarafiDede,
        RelationType.babaTarafiDede,
        RelationType.teyze,
        RelationType.amca,
      },
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'kaldi',
        label: 'Bütün yaz orada kal',
        resultText: 'Dizin sürekli yaralıydı, akşamları erken '
            'uyudun. Eylülde şehir küçük göründü.',
        happiness: 6,
        health: 3,
        addFlags: <String>{PreschoolFlags.yazKoyde},
      ),
      EventChoice(
        id: 'kisa',
        label: 'Birkaç gün kal, dön',
        resultText: 'Kısa sürdü. Dönüş yolunda arabada uyudun ve '
            'avlunun kokusu bir süre üstünde kaldı.',
        happiness: 3,
        bond: 2,
      ),
    ],
  ),
  GameEvent(
    id: 'okul_oncesi_dugunde',
    category: EventCategory.aile,
    text: 'Düğün salonu kalabalık, müzik yüksek. Ortada dönen bir '
        'halka var ve seni çekiyorlar.',
    requirement: EventRequirement(
      minAge: 3,
      maxAge: 6,
      livingRelations: <RelationType>{RelationType.anne, RelationType.baba},
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'ortaya',
        label: 'Ortaya çık',
        resultText: 'Adımları bilmiyordun, kimse de bakmıyordu zaten. '
            'Terli ve mutlu çıktın.',
        happiness: 5,
        charisma: 3,
      ),
      EventChoice(
        id: 'masada',
        label: 'Masada kal',
        resultText: 'Masadaki iki tabağı tek başına bitirdin. Müziği '
            'oradan dinledin.',
        happiness: 3,
      ),
    ],
  ),

  // -------------------------------------------------------------------
  // Bedenin ve okulun eşiği
  // -------------------------------------------------------------------
  GameEvent(
    id: 'okul_oncesi_ilk_bisiklet',
    category: EventCategory.kisisel,
    text: 'Üç tekerli bir şey geldi eve. Koridorda bir tur attın, '
        'duvara iki kez vurdun.',
    requirement: EventRequirement(
      minAge: 3,
      maxAge: 6,
      livingRelations: <RelationType>{RelationType.anne, RelationType.baba},
      requireSameHousehold: true,
    ),
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'disari',
        label: 'Aşağıda dene',
        resultText: 'Kaldırımda gitti, eğimde korkuttu. Akşam '
            'bırakmak istemedin.',
        happiness: 5,
        health: 2,
      ),
      EventChoice(
        id: 'koridor',
        label: 'Koridorda kalsın',
        resultText: 'Koridor kısa ama senin için uzundu. Duvarın '
            'boyası birkaç yerden gitti.',
        happiness: 3,
      ),
    ],
  ),
  GameEvent(
    id: 'okul_oncesi_okulun_onunden',
    category: EventCategory.okul,
    text: 'Yolunuz bir okulun önünden geçti. Bahçede zil çaldı ve '
        'yüzlerce çocuk aynı anda koştu. "Seneye sen de" dendi.',
    requirement: EventRequirement(
      minAge: 5,
      maxAge: 6,
      livingRelations: <RelationType>{RelationType.anne, RelationType.baba},
    ),
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'merak',
        label: 'Demirden içeri bak',
        resultText: 'Zil, koşuş, toz. Eve dönerken çantalı çocukları '
            'saydın.',
        happiness: 3,
        intelligence: 2,
      ),
      EventChoice(
        id: 'korku',
        label: 'Eli sıkı tut',
        resultText: 'Kalabalık fazla geldi. "Daha var" dendi ve '
            'yürüdünüz.',
        happiness: 1,
        bond: 2,
      ),
    ],
  ),
  GameEvent(
    id: 'okul_oncesi_hastalik_gunu',
    category: EventCategory.aile,
    text: 'Boğazın ağrıyor, sesin çıkmıyor. Bugün hiçbir yere '
        'gidilmiyor.',
    requirement: EventRequirement(
      minAge: 3,
      maxAge: 6,
      livingRelations: <RelationType>{RelationType.anne, RelationType.baba},
      requireSameHousehold: true,
    ),
    repeatable: true,
    minAgeGap: 3,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'yatakta',
        label: 'Yatakta kal',
        resultText: 'Battaniye, çorba, uzun bir gün. Akşama sesin '
            'yarısı geri geldi.',
        health: 3,
        bond: 4,
        happiness: 1,
      ),
      EventChoice(
        id: 'oyun',
        label: 'Yine de oyna',
        resultText: 'Yatakta durmadın. Gece ateşin biraz yükseldi, '
            'sabaha düştü.',
        health: -1,
        happiness: 2,
      ),
    ],
  ),
  GameEvent(
    id: 'okul_oncesi_dogum_gunu_mahalle',
    category: EventCategory.mahalle,
    text: 'Salonda birkaç çocuk, bir pasta ve bir tabak kuruyemiş. '
        'Davet listesi apartmandan.',
    requirement: EventRequirement(
      minAge: 4,
      maxAge: 6,
      livingRelations: <RelationType>{RelationType.anne, RelationType.baba},
      requireSameHousehold: true,
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'paylasti',
        label: 'İlk dilimi arkadaşına ver',
        resultText: 'İlk dilim senin değildi. Kimse söylemedi ama '
            'herkes gördü.',
        happiness: 4,
        charisma: 3,
      ),
      EventChoice(
        id: 'kendi',
        label: 'İlk dilim senin',
        resultText: 'Mumu sen üfledin, ilk dilimi sen aldın. Günün '
            'sahibi belliydi.',
        happiness: 5,
      ),
    ],
  ),
  GameEvent(
    id: 'okul_oncesi_fotografci',
    category: EventCategory.aile,
    text: 'Stüdyoya gidildi. Saçın ıslatılıp yana yatırıldı, '
        '"gülümse" dendi ve tam o an aksilik çıktı.',
    requirement: EventRequirement(
      minAge: 3,
      maxAge: 6,
      livingRelations: <RelationType>{RelationType.anne, RelationType.baba},
    ),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'guldu',
        label: 'Gül',
        resultText: 'Çıkan karede iki dişin eksik görünüyor. '
            'Çerçeveletildi, salonda durdu.',
        happiness: 4,
        appearance: 2,
        bond: 3,
      ),
      EventChoice(
        id: 'surat',
        label: 'Surat yap',
        resultText: 'Fotoğrafçı üç kez denedi, üçünde de aynı surat. '
            'En çok o kare sevildi.',
        happiness: 3,
        bond: 2,
      ),
    ],
  ),

  // -------------------------------------------------------------------
  // Karşılık olayları: yukarıdaki her iz burada okunuyor
  // (Paket AR/CZ kuralı — okunmayan iz yazılmaz).
  // -------------------------------------------------------------------
  GameEvent(
    id: 'okul_oncesi_iz_misafir_sahnesi',
    category: EventCategory.aile,
    text: 'Kalabalık bir masada yine o cümle geçti: "bu çocuk küçükken '
        'herkese şiir okurdu." Anlatan hâlâ gülüyor.',
    requirement: EventRequirement(
      minAge: 14,
      requiredFlags: <String>{PreschoolFlags.misafirSahnesi},
      livingRelations: <RelationType>{RelationType.anne, RelationType.baba},
    ),
    repeatable: true,
    minAgeGap: 15,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'devam',
        label: 'Bu kez de kalk',
        resultText: 'Kalktın. Aynı ev, aynı salon, farklı bir ses.',
        happiness: 4,
        charisma: 3,
        bond: 3,
      ),
      EventChoice(
        id: 'yeter',
        label: '"O çocuk büyüdü"',
        resultText: 'Konu kapandı. Ama masadan kalkarken birinin '
            'hâlâ gülümsediğini gördün.',
        happiness: 2,
      ),
    ],
  ),
  GameEvent(
    id: 'okul_oncesi_iz_kalabalik_korkusu',
    category: EventCategory.kisisel,
    text: 'Kalabalık bir yerde elin boşta kaldı ve içinde eski bir şey '
        'kıpırdadı: üç dakika süren o kaybolma.',
    requirement: EventRequirement(
      minAge: 12,
      requiredFlags: <String>{PreschoolFlags.kalabalikta},
    ),
    repeatable: true,
    minAgeGap: 12,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'kenara',
        label: 'Kenara çekil, bekle',
        resultText: 'Kalabalık geçti. Artık nerede durulacağını '
            'biliyorsun.',
        happiness: 2,
        intelligence: 2,
      ),
      EventChoice(
        id: 'icinden',
        label: 'İçinden geç',
        resultText: 'Geçtin. Çıkışta omzun ağrıyordu ama yolunu '
            'kaybetmedin.',
        happiness: 3,
        charisma: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'okul_oncesi_iz_duvardaki_cizgi',
    category: EventCategory.aile,
    text: 'Koridor boyandı. Fırça o köşeye gelince duran oldu: '
        'yıllardır duvarda kalan çizgiyi herkes biliyor.',
    requirement: EventRequirement(
      minAge: 11,
      requiredFlags: <String>{PreschoolFlags.duvardakiCizgi},
      livingRelations: <RelationType>{RelationType.anne, RelationType.baba},
      requireSameHousehold: true,
    ),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'kapatildi',
        label: 'Boyanın altına gitsin',
        resultText: 'Boyandı. O köşe artık diğerleri gibi, ama nereye '
            'bakacağını biliyorsun.',
        happiness: 2,
        bond: 2,
      ),
      EventChoice(
        id: 'fotografi',
        label: 'Önce fotoğrafını çek',
        resultText: 'Çizginin fotoğrafı çekildi, sonra duvar boyandı. '
            'Fotoğraf telefondan telefona taşındı.',
        happiness: 4,
        bond: 3,
      ),
    ],
  ),
  GameEvent(
    id: 'okul_oncesi_iz_kumbara',
    category: EventCategory.kisisel,
    text: 'Dolabın üstünden eski kumbara çıktı. Ağırlığı hâlâ aynı; '
        'içinde çocukluğunun bütün bayramları var.',
    requirement: EventRequirement(
      minAge: 13,
      requiredFlags: <String>{PreschoolFlags.harcligiBiriktirdi},
    ),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'kirdi',
        label: 'Kır, say',
        resultText: 'Beklediğinden azdı ama hiç beklemediğin kadar '
            'eskiydi. Hepsini bir kenara koydun.',
        happiness: 3,
        money: 1800,
        intelligence: 1,
      ),
      EventChoice(
        id: 'durdu',
        label: 'Yerine koy',
        resultText: 'Kumbara dolabın üstüne döndü. İçindeki para '
            'artık para değil.',
        happiness: 4,
      ),
    ],
  ),
  GameEvent(
    id: 'okul_oncesi_iz_yaz_koyu',
    category: EventCategory.kisisel,
    text: 'Bir avlu, bir asma, bir de o toprak kokusu. Yolun oradan '
        'geçti ve bütün yazlar aynı anda aklına geldi.',
    requirement: EventRequirement(
      minAge: 15,
      requiredFlags: <String>{PreschoolFlags.yazKoyde},
    ),
    repeatable: true,
    minAgeGap: 18,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'durdu',
        label: 'Dur, bak',
        resultText: 'Kapı eskimiş, avlu küçülmüş. Küçülen avlu '
            'değildi.',
        happiness: 4,
        bond: 2,
      ),
      EventChoice(
        id: 'gecti',
        label: 'Geç, dönme',
        resultText: 'Durmadın. Yine de o gece uykun geç geldi.',
        happiness: 2,
      ),
    ],
  ),
  GameEvent(
    id: 'okul_oncesi_iz_sokak_oyunu',
    category: EventCategory.mahalle,
    text: 'Bir halı sahanın kenarından geçerken ayağına top geldi. '
        'Sokakta oynamayı unutmamışsın.',
    requirement: EventRequirement(
      minAge: 12,
      requiredFlags: <String>{PreschoolFlags.sokakOyunu},
    ),
    repeatable: true,
    minAgeGap: 14,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'vurdu',
        label: 'Topu geri at',
        resultText: 'Düzgün bir pas çıktı. "Gel bir oyna" dediler.',
        happiness: 4,
        charisma: 2,
        health: 1,
      ),
      EventChoice(
        id: 'gecti',
        label: 'Kenardan geç',
        resultText: 'Topu ayağınla kenara ittin ve yürüdün. Arkanda '
            'oyun kaldığı yerden devam etti.',
        happiness: 2,
      ),
    ],
  ),
];
