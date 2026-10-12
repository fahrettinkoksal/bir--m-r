/// Son yıllar: 65 yaş ve sonrası (Paket CC).
///
/// **Ölçülen sorun.** Oynanan 60 hayatta, oyuncunun o yıl gerçekten
/// karşılaşabileceği olay sayısı yaşa göre ölçüldü
/// (`EventEngine.debugEligibleIds`): 65-74 bandında yılda 75,3 olay —
/// yani bant **aç değil**. Ama o 65+ taramasında görülen 228 tekil
/// olaydan yalnızca **11 tanesi** o yaşlara aitti (`vasiyet_dusuncesi`,
/// `sessiz_ev_aksami`, `eski_dostun_haberi`, `ileri_yas_muhasebe`,
/// `unutulan_isim`, `mirasin_konusulmasi`, `radyo_ve_sessizlik`,
/// `kapidaki_yardim`, `evin_anahtari`, `yillarin_hesabi`,
/// `hayat_muhasebesi`). Gerisi orta yaşın havuzuydu: 70 yaşındaki
/// oyuncu 40 yaşındakiyle aynı olayları çekiyordu. Sorun kıtlık değil
/// **yaşa ait olmama**.
///
/// Paket BM ilk yedi yıl için, Paket BN eşikteki yıllar için aynı işi
/// yapmıştı; bu dosya hayatın son bandı için yapıyor.
///
/// **Yeni mekanik getirmez.** Kurallar:
///
/// - Emeklilik, torun, komşu ve ev gibi **var olan** sistemlere bağlanır;
///   yeni ekran, yeni düğme, yeni yıllık hesap yoktur.
/// - Ölüm bu havuzun konusu değil: ölümü `life_progression` ve sağlık
///   motoru yürütür. Buradaki olaylar **yaşanan** yılları anlatır.
/// - Ağır konu sade anlatılır; espri yok (`docs/WRITING_STYLE_TR.md` §7).
///   Din, siyaset ve gerçek kurum/marka adı geçmez.
/// - Bırakılan her iz **okunur**: dosyanın sonundaki altı olay kendi
///   izlerinin karşılığıdır. Karşılığı olmayan iz bırakmak Paket AR'nin
///   ölçtüğü "sessiz iz" hatasını yeniden üretir.
/// - Para gerçekten cüzdandan çıkar ve girer; emekli oyuncunun bütçesi
///   küçük olduğu için tutarlar küçüktür (ECO-001).
///
/// Bütün sayılar `prototypeOnly`'dir.
///
/// Modül: `FeatureId.sonYillar` — kapatılınca bu havuz hiç listelenmez
/// (`docs/FEATURE_FLAGS.md`).
library;

import '../domain/models/game_event.dart';
import '../domain/models/relation.dart';

/// Son yılların hikâye izleri.
abstract final class LateYearFlags {
  /// Bildiğini yazıya geçirdi.
  static const String defteriYazdi = 'son_defteri_yazdi';

  /// Mesleğini bir gence öğretti.
  static const String ciragaOgretti = 'son_ciraga_ogretti';

  /// Bahçeye ya da saksıya fidan dikti.
  static const String fidanDikti = 'son_fidan_dikti';

  /// Torununun sırrını tuttu.
  static const String torunSirriniTuttu = 'son_torun_sirri_tutuldu';

  /// Komşusuyla "her sabah bir ses ver" düzeni kurdu.
  static const String komsuDuzeni = 'son_komsu_duzeni_kuruldu';

  /// Takımını, aletini ya da tezgâhını bir gence devretti.
  static const String aletiDevretti = 'son_aleti_devretti';

  /// Karşılık olaylarının kapanış izleri.
  static const String defterOkundu = 'son_defter_okundu';
  static const String cirakGeriDondu = 'son_cirak_dondu';
  static const String fidanBuyudu = 'son_fidan_buyudu';
  static const String torunGeriGeldi = 'son_torun_geri_geldi';
  static const String komsuDuzeniIsleDi = 'son_komsu_duzeni_isledi';
  static const String aletKullanildi = 'son_alet_kullanildi';
}

/// Son yılların olay havuzu (Paket CC).
const List<GameEvent> kLateYearsEvents = <GameEvent>[
  // --- Emekliliğin ritmi -------------------------------------------------
  GameEvent(
    id: 'son_ilk_pazartesi',
    category: EventCategory.kisisel,
    text: 'Pazartesi sabahı erken uyandın. Gidecek bir yer yok ve bu '
        'tuhaf geliyor.',
    requirement: EventRequirement(minAge: 60, requiresRetired: true),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'yurudu',
        label: 'Yürüyüşe çık',
        resultText: 'Mahalleyi iki tur attın. Dönüşte simit aldın, '
            'oturup yedin.',
        happiness: 4,
        health: 2,
      ),
      EventChoice(
        id: 'uyudu',
        label: 'Yat, uyu',
        resultText: 'Öğlene kadar uyudun. Kalktığında gün yarılanmıştı.',
        happiness: 1,
        health: -1,
      ),
    ],
  ),
  GameEvent(
    id: 'son_gunun_duzeni',
    category: EventCategory.kisisel,
    text: 'Günler birbirine benzemeye başladı. Bir düzen kurmak lazım.',
    requirement: EventRequirement(minAge: 63, requiresRetired: true),
    repeatable: true,
    minAgeGap: 9,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'defter',
        label: 'Bildiklerini yazmaya başla',
        resultText: 'Bir defter aldın ve ilk sayfaya kendi mahallenin '
            'adını yazdın. Her gün birkaç satır yazıyorsun.',
        happiness: 5,
        intelligence: 2,
        addFlags: <String>{LateYearFlags.defteriYazdi},
      ),
      EventChoice(
        id: 'sabah_yurumesi',
        label: 'Her sabah aynı saatte yürü',
        resultText: 'Saat yediyi kurdun. Üçüncü haftada ayakların '
            'kendiliğinden kalkıyordu.',
        happiness: 3,
        health: 3,
      ),
    ],
  ),
  GameEvent(
    id: 'son_parkta_tanidik',
    category: EventCategory.kisisel,
    text: 'Parktaki bankta her gün aynı adam oturuyor. Bugün yanına '
        'oturmak için yer açtı.',
    requirement: EventRequirement(minAge: 65),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'oturdu',
        label: 'Otur ve konuş',
        resultText: 'İki saat konuştunuz. Aynı yıl aynı şehirde iş '
            'aradığınız çıktı.',
        happiness: 5,
        charisma: 2,
        startsFriendship: true,
      ),
      EventChoice(
        id: 'gecti',
        label: 'Selam ver, yürümeye devam et',
        resultText: 'Başını sallayıp geçtin. Dönüşte bank boştu.',
        happiness: 1,
      ),
    ],
  ),

  // --- Beden ve zaman ----------------------------------------------------
  GameEvent(
    id: 'son_merdiven',
    category: EventCategory.kisisel,
    text: 'Üçüncü kata çıkarken ilk kez ara verdin. Sahanlıkta durup '
        'nefesini bekledin.',
    requirement: EventRequirement(minAge: 66),
    repeatable: true,
    minAgeGap: 8,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'doktora',
        label: 'Doktora görün',
        resultText: 'Tansiyonunu ölçtüler, yürüyüş ve tuzu azaltmayı '
            'yazdılar. Reçete cebinde.',
        health: 4,
        happiness: -1,
        money: -1200,
      ),
      EventChoice(
        id: 'onemsemedi',
        label: 'Geçer, önemseme',
        resultText: 'Bir hafta sonra aynı sahanlıkta yine durdun.',
        health: -3,
      ),
    ],
  ),
  GameEvent(
    id: 'son_gozluk_numarasi',
    category: EventCategory.kisisel,
    text: 'Gazetenin yazısı küçülmüş gibi. Kolunu uzatarak okumaya '
        'çalışıyorsun.',
    requirement: EventRequirement(minAge: 65),
    weight: 2,
    choices: <EventChoice>[
      EventChoice(
        id: 'numara',
        label: 'Numarayı yenile',
        resultText: 'Yeni gözlükle gazetenin alt köşesindeki küçük '
            'yazıyı da okudun.',
        happiness: 3,
        money: -2800,
      ),
      EventChoice(
        id: 'kolunu_uzatti',
        label: 'İdare et',
        resultText: 'Kolun yetmediği gün başlığı okuyup katladın.',
        happiness: -1,
      ),
    ],
  ),
  GameEvent(
    id: 'son_ilac_kutusu',
    category: EventCategory.kisisel,
    text: 'Masada dört ilaç kutusu var ve hangisini ne zaman '
        'alacağını karıştırıyorsun.',
    requirement: EventRequirement(minAge: 68),
    repeatable: true,
    minAgeGap: 10,
    weight: 2,
    choices: <EventChoice>[
      EventChoice(
        id: 'kutu_yapti',
        label: 'Günlük kutu hazırla',
        resultText: 'Yedi gözlü bir kutu aldın, pazar akşamı hepsini '
            'dizdin. Artık bakıp alıyorsun.',
        health: 3,
        happiness: 2,
        money: -400,
      ),
      EventChoice(
        id: 'akilda_tuttu',
        label: 'Akılda tut',
        resultText: 'İki gün sabah ilacını atladın, bir gün iki kez '
            'aldın.',
        health: -3,
      ),
    ],
  ),

  // --- Torunlar ----------------------------------------------------------
  GameEvent(
    id: 'son_torun_eski_zaman',
    category: EventCategory.aile,
    text: '{kisi} yanına oturdu: "Sen küçükken burada ne vardı?"',
    requirement: EventRequirement(
      minAge: 62,
      livingRelations: <RelationType>{RelationType.torun},
      personMinAge: 6,
      personMaxAge: 17,
      requireReachable: true,
    ),
    repeatable: true,
    minAgeGap: 7,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'anlatti',
        label: 'Anlat',
        resultText: 'Sokağın eski hâlini, kaybolan dükkânı ve ilk işini '
            'anlattın. {kisi} sonunu bekledi.',
        happiness: 6,
        bond: 7,
      ),
      EventChoice(
        id: 'kisa_kesti',
        label: 'Kısa kes',
        resultText: '"Çok şey vardı" dedin. {kisi} biraz daha bekledi, '
            'sonra kalktı.',
        happiness: 1,
        bond: -1,
      ),
    ],
  ),
  GameEvent(
    id: 'son_torun_ogretme',
    category: EventCategory.aile,
    text: '{kisi} elindeki şeyi uzatıyor: "Bunu bana öğretir misin?"',
    requirement: EventRequirement(
      minAge: 62,
      livingRelations: <RelationType>{RelationType.torun},
      personMinAge: 7,
      personMaxAge: 18,
      requireReachable: true,
    ),
    repeatable: true,
    minAgeGap: 8,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'ogretti',
        label: 'Öğret',
        resultText: 'Masayı temizleyip yanına oturttun. Akşama kadar '
            'ikiniz uğraştınız; sonunda kendi başına yaptı.',
        happiness: 6,
        bond: 8,
        intelligence: 1,
      ),
      EventChoice(
        id: 'sonra',
        label: 'Başka gün',
        resultText: '"Yarın" dedin. Yarın {kisi} sormadı.',
        bond: -2,
      ),
    ],
  ),
  GameEvent(
    id: 'son_torun_sirri',
    category: EventCategory.aile,
    text: '{kisi} sesini alçaltıyor: "Anneme söylemezsin, değil mi?" '
        'Okulda bir not sakladığını anlatıyor.',
    requirement: EventRequirement(
      minAge: 62,
      livingRelations: <RelationType>{RelationType.torun},
      personMinAge: 9,
      personMaxAge: 18,
      requireReachable: true,
    ),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'tuttu',
        label: 'Aranızda kalsın',
        resultText: 'Söz verdin ve tuttun. Ama "bir dahaki notu bana '
            'kendin göstereceksin" dedin.',
        happiness: 3,
        bond: 8,
        addFlags: <String>{LateYearFlags.torunSirriniTuttu},
      ),
      EventChoice(
        id: 'soyledi',
        label: 'Annesine söyle',
        resultText: 'Akşam telefonu açtın. Not konuşuldu, {kisi} seninle '
            'bir süre konuşmadı.',
        happiness: -2,
        bond: -6,
      ),
    ],
  ),
  GameEvent(
    id: 'son_torun_harclik',
    category: EventCategory.aile,
    text: '{kisi} kapıda duruyor, bir şey isteyecek gibi ama '
        'söylemiyor.',
    requirement: EventRequirement(
      minAge: 63,
      livingRelations: <RelationType>{RelationType.torun},
      personMinAge: 10,
      personMaxAge: 22,
      requireReachable: true,
    ),
    repeatable: true,
    minAgeGap: 9,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'verdi',
        label: 'Harçlık ver',
        resultText: 'Cebinden çıkarıp verdin. {kisi} kulağına eğilip '
            'teşekkür etti.',
        happiness: 3,
        bond: 5,
        money: -2000,
      ),
      EventChoice(
        id: 'konustu',
        label: 'Önce ne olduğunu sor',
        resultText: 'Oturup dinledin. Para değil, bir imza gerekiyordu; '
            'onu sen attın.',
        happiness: 4,
        bond: 6,
        charisma: 1,
      ),
    ],
  ),

  // --- Komşuluk ve mahalle ----------------------------------------------
  GameEvent(
    id: 'son_komsu_duzeni',
    category: EventCategory.mahalle,
    text: 'Karşı komşu kapıda: "Her sabah perdeni açarsan ben de '
        'balkona çıkarım. Böylece birbirimizi görürüz."',
    requirement: EventRequirement(minAge: 67),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'kabul',
        label: 'Anlaşalım',
        resultText: 'Ertesi sabah perdeyi açtığında komşu balkondaydı. '
            'Üçüncü gün el sallamayı da eklediniz.',
        happiness: 5,
        addFlags: <String>{LateYearFlags.komsuDuzeni},
      ),
      EventChoice(
        id: 'gerek_yok',
        label: 'Gerek yok',
        resultText: '"Ben iyiyim" dedin. Komşu başını sallayıp indi.',
        happiness: -1,
      ),
    ],
  ),
  GameEvent(
    id: 'son_apartman_cocuk_sesi',
    category: EventCategory.mahalle,
    text: 'Üst kata çocuklu bir aile taşındı. Akşamüstü tepende koşuşma '
        'sesi var.',
    requirement: EventRequirement(minAge: 65),
    weight: 2,
    choices: <EventChoice>[
      EventChoice(
        id: 'hos_gordu',
        label: 'Ses olsun, ev ölü gibiydi',
        resultText: 'Koşuşmayı dinledin. Ev kalabalık gibi geldi.',
        happiness: 4,
      ),
      EventChoice(
        id: 'uyardi',
        label: 'Çıkıp konuş',
        resultText: 'Kapıyı çaldın, kibarca söyledin. Akşamları sessiz '
            'oldu; selamlaşma da azaldı.',
        happiness: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'son_bakkal_hesabi',
    category: EventCategory.mahalle,
    text: 'Bakkal poşeti kapıya kadar getiriyor artık. Bugün hesabı '
        'yazmayı da unuttu.',
    requirement: EventRequirement(minAge: 70),
    weight: 2,
    choices: <EventChoice>[
      EventChoice(
        id: 'hatirlatti',
        label: 'Hatırlat, borcunu öde',
        resultText: 'Defteri uzattın, yazdırdın ve ödedin. "Sizden '
            'öğreniyorum" dedi.',
        happiness: 3,
        charisma: 2,
        money: -900,
      ),
      EventChoice(
        id: 'sustu',
        label: 'Sus',
        resultText: 'Hesap yazılmadı. Ertesi hafta kendisi fark etti ve '
            'sen de ödedin.',
        happiness: -1,
        money: -900,
      ),
    ],
  ),

  // --- Bilgi, iş ve devretme --------------------------------------------
  GameEvent(
    id: 'son_genc_tavsiye_ister',
    category: EventCategory.yetiskinlik,
    text: 'Eski iş yerinden genç biri numaranı bulmuş. "Yarım saat '
        'ayırabilir misiniz? Bir işe gireceğim" diyor.',
    requirement: EventRequirement(minAge: 62, requiresRetired: true),
    repeatable: true,
    minAgeGap: 8,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'ogretti',
        label: 'Bildiğini öğret',
        resultText: 'Mutfak masasında kâğıda çizerek anlattın. Not aldı, '
            'bir daha gelmek için izin istedi.',
        happiness: 6,
        charisma: 2,
        addFlags: <String>{LateYearFlags.ciragaOgretti},
      ),
      EventChoice(
        id: 'reddetti',
        label: 'Artık o işleri bıraktım',
        resultText: '"Benden geçti" dedin. Telefon kapandı.',
        happiness: -1,
      ),
    ],
  ),
  GameEvent(
    id: 'son_aletleri_devretme',
    category: EventCategory.yetiskinlik,
    text: 'Balkondaki sandıkta yıllarca kullandığın takım duruyor. '
        'Artık eline almıyorsun.',
    requirement: EventRequirement(minAge: 66),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'devretti',
        label: 'Bir gence devret',
        resultText: 'Mahalledeki çırağa verdin. Sandığı sırtlarken '
            '"bunları çürütmem" dedi.',
        happiness: 5,
        charisma: 1,
        addFlags: <String>{LateYearFlags.aletiDevretti},
      ),
      EventChoice(
        id: 'sakladi',
        label: 'Dursun, benim',
        resultText: 'Sandığı kapattın. Üstüne bir örtü attın.',
        happiness: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'son_fidan',
    category: EventCategory.kisisel,
    text: 'Komşunun oğlu elinde iki fidan: "Bir tanesini siz dikin."',
    requirement: EventRequirement(minAge: 65),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'dikti',
        label: 'Dik',
        resultText: 'Bahçenin köşesine diktin, suyunu verdin. '
            'Boyunu geçmesini göremeyebileceğini biliyorsun.',
        happiness: 5,
        health: 1,
        addFlags: <String>{LateYearFlags.fidanDikti},
      ),
      EventChoice(
        id: 'vermedi',
        label: 'Sen dik, ben bakarım',
        resultText: 'Çocuk dikti, sen tarif ettin. İkisi de tuttu.',
        happiness: 3,
      ),
    ],
  ),
  GameEvent(
    id: 'son_fotograf_kutusu',
    category: EventCategory.kisisel,
    text: 'Dolabın üstündeki ayakkabı kutusu fotoğraf dolu. Bir kısmında '
        'kimin kim olduğunu artık sen biliyorsun.',
    requirement: EventRequirement(minAge: 67),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'yazdi',
        label: 'Arkalarına isim yaz',
        resultText: 'Kurşun kalemle tek tek yazdın: kim, nerede, hangi '
            'yıl. Kutuyu kapatırken elin ağrıyordu.',
        happiness: 4,
        intelligence: 1,
        addFlags: <String>{LateYearFlags.defteriYazdi},
      ),
      EventChoice(
        id: 'kaldirdi',
        label: 'Kutuyu geri koy',
        resultText: 'Birkaçına baktın ve kutuyu yerine koydun.',
        happiness: 2,
      ),
    ],
  ),

  // --- Emekli bütçesi ---------------------------------------------------
  GameEvent(
    id: 'son_fatura_zami',
    category: EventCategory.yetiskinlik,
    text: 'Faturalar aynı ayda arka arkaya geldi. Emekli aylığı aynı '
        'kaldı.',
    requirement: EventRequirement(minAge: 65, requiresRetired: true),
    repeatable: true,
    minAgeGap: 9,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'kisti',
        label: 'Harcamayı kıs',
        resultText: 'Isıtmayı bir kademe düşürdün, kahveyi evde '
            'yapmaya başladın. Hesap denkleşti.',
        happiness: -2,
        money: 1500,
      ),
      EventChoice(
        id: 'cocuguna_sordu',
        label: 'Çocuğuna sor',
        resultText: 'Telefonu açtın. Kapatırken "ben bakarım" dedi ama '
            'sen sormaktan rahatsız oldun.',
        happiness: -1,
        money: 4000,
        bond: 2,
      ),
    ],
  ),
  GameEvent(
    id: 'son_eski_esya_satisi',
    category: EventCategory.yetiskinlik,
    text: 'Depodaki eşyaları soran biri var: eski radyo, dikiş '
        'makinesi, bir sandık.',
    requirement: EventRequirement(minAge: 68),
    weight: 2,
    choices: <EventChoice>[
      EventChoice(
        id: 'satti',
        label: 'Sat',
        resultText: 'Üçünü birlikte verdin. Para cebe girdi, depo '
            'genişledi.',
        money: 6500,
        happiness: 1,
      ),
      EventChoice(
        id: 'saklamadi',
        label: 'Torunlara kalsın',
        resultText: 'Kapağı kapattın. "Birileri ister" dedin.',
        happiness: 3,
      ),
    ],
  ),
  GameEvent(
    id: 'son_dolandirici_telefon',
    category: EventCategory.yetiskinlik,
    text: 'Telefonda biri kendini banka görevlisi gibi tanıtıyor ve '
        'hesabındaki parayı "güvenli hesaba" aktarmanı istiyor.',
    requirement: EventRequirement(minAge: 65),
    repeatable: true,
    minAgeGap: 10,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'kapatti',
        label: 'Kapat, kimseye bir şey verme',
        resultText: 'Telefonu kapattın ve numarayı not ettin. Akşam '
            'komşuna da anlattın.',
        happiness: 2,
        intelligence: 1,
        charisma: 1,
      ),
      EventChoice(
        id: 'konustu',
        label: 'Dinle, belki gerçektir',
        resultText: 'Konuşma uzadı. Sen hesap numarası vermedin ama '
            'telefonu kapatınca elin titriyordu.',
        happiness: -3,
      ),
    ],
  ),

  // --- Eş, yalnızlık, dostluk -------------------------------------------
  GameEvent(
    id: 'son_es_ile_sessiz_aksam',
    category: EventCategory.aile,
    text: '{kisi} ile akşam yemeğinde kimse konuşmadı. Kötü bir şey yok; '
        'söylenecek yeni bir şey de yok.',
    requirement: EventRequirement(
      minAge: 65,
      livingRelations: <RelationType>{RelationType.es},
      requireSameHousehold: true,
    ),
    repeatable: true,
    minAgeGap: 9,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'eski_yer',
        label: 'Eskiden gittiğiniz yere gidin',
        resultText: 'Sahildeki çay bahçesini açık buldunuz. Masada iki '
            'saat oturdunuz, bu kez konuştunuz.',
        happiness: 5,
        bond: 6,
        money: -600,
      ),
      EventChoice(
        id: 'oyle_kaldi',
        label: 'Sessizlik de iyidir',
        resultText: 'Yemek bitti, bulaşığı birlikte yıkadınız. Kimse '
            'bir şey söylemedi.',
        happiness: 2,
        bond: 2,
      ),
    ],
  ),
  GameEvent(
    id: 'son_dostun_cenazesi',
    category: EventCategory.aile,
    text: 'Yıllardır görüştüğün bir arkadaşının haberi geldi. Cenaze '
        'yarın.',
    requirement: EventRequirement(
      minAge: 66,
      livingRelations: <RelationType>{RelationType.arkadas},
      requireReachable: true,
    ),
    repeatable: true,
    minAgeGap: 11,
    weight: 2,
    choices: <EventChoice>[
      EventChoice(
        id: 'gitti',
        label: 'Git',
        resultText: 'Gittin. Tanıdığın yüzler azalmıştı; birkaçıyla '
            'uzun uzun konuştun.',
        happiness: -2,
        bond: 4,
        charisma: 1,
      ),
      EventChoice(
        id: 'gitmedi',
        label: 'Gitme',
        resultText: 'Evde kaldın. Akşam telefonu açıp ailesine taziye '
            'ilettin, sesin titredi.',
        happiness: -4,
      ),
    ],
  ),
  GameEvent(
    id: 'son_eski_mahalle',
    category: EventCategory.kisisel,
    text: 'Büyüdüğün sokağa gitmek aklına geldi. Otobüs kırk dakika.',
    requirement: EventRequirement(minAge: 66),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'gitti',
        label: 'Git',
        resultText: 'Sokak duruyor, köşedeki dükkân yok. Oturduğunuz '
            'apartmanın kapısı yeni boyanmış.',
        happiness: 4,
        money: -200,
      ),
      EventChoice(
        id: 'gitmedi',
        label: 'Aklında kalsın',
        resultText: 'Gitmedin. Sokağı hatırladığın gibi tuttun.',
        happiness: 2,
      ),
    ],
  ),

  // --- Evin hâli --------------------------------------------------------
  GameEvent(
    id: 'son_evin_fazla_odasi',
    category: EventCategory.mahalle,
    text: 'Evin bir odası aylardır kapalı. İçeride kimse kalmıyor.',
    requirement: EventRequirement(minAge: 66, requiresOwnedResidence: true),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'ogrenciye',
        label: 'Bir öğrenciye ver',
        resultText: 'Mahalledeki okulda okuyan bir öğrenci yerleşti. '
            'Ev sesli, sofra iki kişi oldu.',
        happiness: 5,
        money: 3500,
      ),
      EventChoice(
        id: 'calisma_odasi',
        label: 'Kendine çalışma odası yap',
        resultText: 'Masayı pencerenin önüne çektin. Defterin orada '
            'duruyor artık.',
        happiness: 4,
      ),
    ],
  ),
  GameEvent(
    id: 'son_tamir_isi',
    category: EventCategory.mahalle,
    text: 'Mutfak musluğu damlıyor. Eskiden bunu kendin yapardın.',
    requirement: EventRequirement(minAge: 68),
    repeatable: true,
    minAgeGap: 9,
    weight: 2,
    choices: <EventChoice>[
      EventChoice(
        id: 'kendi',
        label: 'Yine kendin yap',
        resultText: 'Eğilip kalkmak zorladı ama contayı değiştirdin. '
            'Damlama durdu.',
        happiness: 4,
        health: -2,
        money: -150,
      ),
      EventChoice(
        id: 'usta',
        label: 'Usta çağır',
        resultText: 'Usta on dakikada bitirdi. Sen yanında durup '
            'izledin.',
        happiness: 1,
        money: -1200,
      ),
    ],
  ),

  // --- Karşılıklar: bırakılan iz okunur ---------------------------------
  GameEvent(
    id: 'son_karsilik_defter',
    category: EventCategory.aile,
    text: '{kisi} yazdığın defteri bulmuş. "Buradaki sokak hâlâ var mı?" '
        'diye soruyor.',
    requirement: EventRequirement(
      minAge: 70,
      livingRelations: <RelationType>{RelationType.torun},
      requireReachable: true,
      requiredFlags: <String>{LateYearFlags.defteriYazdi},
      forbiddenFlags: <String>{LateYearFlags.defterOkundu},
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'birlikte_okudu',
        label: 'Birlikte oku',
        resultText: 'Sayfaları birlikte çevirdiniz. {kisi} sonuna kendi '
            'el yazısıyla bir satır ekledi.',
        happiness: 8,
        bond: 8,
        addFlags: <String>{LateYearFlags.defterOkundu},
      ),
      EventChoice(
        id: 'hediye_etti',
        label: 'Defteri ona ver',
        resultText: 'Defteri uzattın. "Sen devam et" dedin.',
        happiness: 7,
        bond: 9,
        addFlags: <String>{LateYearFlags.defterOkundu},
      ),
    ],
  ),
  GameEvent(
    id: 'son_karsilik_cirak',
    category: EventCategory.yetiskinlik,
    text: 'Yıllar önce yarım saat ayırdığın genç kapıda. Artık kendi '
        'yerini açmış; elinde bir kutu var.',
    requirement: EventRequirement(
      minAge: 68,
      requiredFlags: <String>{LateYearFlags.ciragaOgretti},
      forbiddenFlags: <String>{LateYearFlags.cirakGeriDondu},
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'oturdu',
        label: 'İçeri al, çay koy',
        resultText: 'Kutudan kendi yaptığı ilk işi çıkardı. Masaya '
            'koydu: "Sizin çizdiğiniz kâğıtla yaptım."',
        happiness: 9,
        charisma: 2,
        addFlags: <String>{LateYearFlags.cirakGeriDondu},
      ),
      EventChoice(
        id: 'kapida',
        label: 'Kapıda konuş',
        resultText: 'Kapıda konuştunuz. Giderken kutuyu bıraktı.',
        happiness: 5,
        addFlags: <String>{LateYearFlags.cirakGeriDondu},
      ),
    ],
  ),
  GameEvent(
    id: 'son_karsilik_fidan',
    category: EventCategory.kisisel,
    text: 'Diktiğin fidan artık gölge yapıyor. Altına bir bank koymuş '
        'birileri.',
    requirement: EventRequirement(
      minAge: 72,
      requiredFlags: <String>{LateYearFlags.fidanDikti},
      forbiddenFlags: <String>{LateYearFlags.fidanBuyudu},
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'oturdu',
        label: 'Gölgesine otur',
        resultText: 'Oturdun. Yanına gelen çocuk "bunu kim dikti?" diye '
            'sordu.',
        happiness: 8,
        health: 1,
        addFlags: <String>{LateYearFlags.fidanBuyudu},
      ),
      EventChoice(
        id: 'uzaktan',
        label: 'Uzaktan bak',
        resultText: 'Karşı kaldırımdan baktın ve yürümeye devam ettin.',
        happiness: 5,
        addFlags: <String>{LateYearFlags.fidanBuyudu},
      ),
    ],
  ),
  GameEvent(
    id: 'son_karsilik_torun',
    category: EventCategory.aile,
    text: '{kisi} yine kapıda ve yine sesi alçak. Bu kez konu okuldan '
        'büyük.',
    requirement: EventRequirement(
      minAge: 68,
      livingRelations: <RelationType>{RelationType.torun},
      personMinAge: 14,
      requireReachable: true,
      requiredFlags: <String>{LateYearFlags.torunSirriniTuttu},
      forbiddenFlags: <String>{LateYearFlags.torunGeriGeldi},
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'dinledi',
        label: 'Dinle, sonra birlikte karar verin',
        resultText: 'Sonuna kadar dinledin. Ne yapılacağını birlikte '
            'konuştunuz; annesine ikiniz söylediniz.',
        happiness: 8,
        bond: 9,
        charisma: 2,
        addFlags: <String>{LateYearFlags.torunGeriGeldi},
      ),
      EventChoice(
        id: 'ailesine',
        label: 'Bu kez ailesine haber ver',
        resultText: 'Konu ağırdı, tek başına taşımadın. {kisi} kırıldı '
            'ama iş çözüldü.',
        happiness: 3,
        bond: -2,
        addFlags: <String>{LateYearFlags.torunGeriGeldi},
      ),
    ],
  ),
  GameEvent(
    id: 'son_karsilik_komsu',
    category: EventCategory.mahalle,
    text: 'Bu sabah perdeyi açmakta geciktin. Kapı çaldı: karşı komşu, '
        'elinde anahtarla kapıda.',
    requirement: EventRequirement(
      minAge: 70,
      requiredFlags: <String>{LateYearFlags.komsuDuzeni},
      forbiddenFlags: <String>{LateYearFlags.komsuDuzeniIsleDi},
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'ictiler',
        label: 'İçeri al, kahvaltı et',
        resultText: 'İkiniz kahvaltı ettiniz. Düzene "perde geç '
            'açılırsa" maddesi eklendi.',
        happiness: 8,
        bond: 5,
        addFlags: <String>{LateYearFlags.komsuDuzeniIsleDi},
      ),
      EventChoice(
        id: 'ozur',
        label: 'İyiyim de, gönder',
        resultText: '"Uyuyakalmışım" dedin. Komşu gülüp indi; ertesi '
            'sabah perde yine saatinde açıldı.',
        happiness: 5,
        addFlags: <String>{LateYearFlags.komsuDuzeniIsleDi},
      ),
    ],
  ),
  GameEvent(
    id: 'son_karsilik_alet',
    category: EventCategory.mahalle,
    text: 'Devrettiğin takımı sokakta gördün: çırak, senin aletlerle '
        'komşunun kapısını tamir ediyor.',
    requirement: EventRequirement(
      minAge: 70,
      requiredFlags: <String>{LateYearFlags.aletiDevretti},
      forbiddenFlags: <String>{LateYearFlags.aletKullanildi},
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'yanina_gitti',
        label: 'Yanına git',
        resultText: 'Yanına gittin. Eline bakıp "burayı biraz daha sık" '
            'dedin; dinledi.',
        happiness: 8,
        charisma: 2,
        addFlags: <String>{LateYearFlags.aletKullanildi},
      ),
      EventChoice(
        id: 'karismadi',
        label: 'Karışma, izle',
        resultText: 'Karşıdan izledin. İşi doğru yaptı.',
        happiness: 6,
        addFlags: <String>{LateYearFlags.aletKullanildi},
      ),
    ],
  ),
];
