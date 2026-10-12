/// Dulluk: eşini kaybettikten sonraki yıllar (Paket CS).
///
/// **Ölçülen eksik.** `docs/EKSIKLER.md` §3.6 dulluğu 26 Eylül 2026'da
/// yarım bırakmıştı: "dul kalmak ile boşanmak ayrı durumlar" tespiti
/// doğruydu ama maddenin kalanı açık kaldı — *"hâlâ yok: dulluğun
/// kendine ait olay havuzu (anma, yıl dönümü, eşin ailesiyle bağın
/// sürmesi)."*
///
/// 11 Ekim 2026'da ölçüldü (250 bot hayatı, dört arketip):
///
/// | ölçülen | sayı |
/// |---|---|
/// | dul kalan hayat | 43 / 250 (%17,2) |
/// | dul kalma yaşı | en küçük 38 · medyan 68 · en büyük 87 |
/// | dul geçen yıl | en az 0 · medyan 10 · en çok 39 |
/// | **toplam dul yılı** | **502** |
/// | dulken görülen olay türü | 212 |
/// | bunlardan dulluğa ait olan | **0** |
///
/// Yani oyuncular 502 yılı eşini kaybetmiş olarak oynuyor ve o yılların
/// tek satırı yok. En çok çıkan olaylar `komsu_apartman_karari`,
/// `orta_teknoloji_gerisi`, `sabah_yuruyusu` gibi orta yaş ve mahalle
/// olaylarıydı: 70 yaşında eşini kaybetmiş oyuncu, 40 yaşında evli
/// oyuncuyla **aynı** havuzu çekiyordu. Kodda hiçbir
/// `EventRequirement` `MarriageStatus.dul` okumuyordu.
///
/// **Yeni mekanik getirmez.** Kurallar:
///
/// - Kapı kayıttan okunur: `requiresWidowed`, `minWidowYears`,
///   `maxWidowYears`. Üçü de `marriage.status` ve `marriage.endedAtAge`
///   ile hesaplanır; yeni alan, yeni ekran, yeni sayaç yoktur.
/// - Boşanma bu havuzun konusu **değil**. Oyunda dulluk ile boşanma
///   ayrı iki durumdur; boşanmış oyuncuya bu olaylar çıkmaz.
/// - Tekrar evlenmek yerinde kalır ve havuzu kendiliğinden kapatır:
///   yürürlükteki kayıt artık yeni evliliktir. Dulluk "kilitli bir
///   son" değildir.
/// - Ağır konu sade anlatılır; espri yok
///   (`docs/WRITING_STYLE_TR.md` §7). Din, siyaset, gerçek kurum ya da
///   marka adı geçmez. Ölümün kendisi anlatılmaz — bu olaylar
///   **yaşanan** yılları anlatır.
/// - Metinde `{es}` yer tutucusu kayıttaki eşin gerçek adıyla
///   doldurulur. Ad okunamazsa cümle yine tamdır: hiçbir metin `{es}`
///   olmadan bozulmaz.
/// - Bırakılan her iz **okunur**: dosyanın sonundaki beş olay kendi
///   izlerinin karşılığıdır. Karşılığı olmayan iz bırakmak Paket AR'nin
///   ölçtüğü "sessiz iz" hatasını yeniden üretir.
/// - Para gerçekten cüzdandan çıkar ve girer; tutarlar küçüktür
///   (ECO-001).
///
/// Bütün sayılar `prototypeOnly`'dir.
///
/// Modül: `FeatureId.dulluk` — kapatılınca bu havuz hiç listelenmez
/// (`docs/FEATURE_FLAGS.md`).
library;

import '../domain/models/game_event.dart';
import '../domain/models/relation.dart';

/// Dulluk yıllarının hikâye izleri.
abstract final class WidowFlags {
  /// Eşinin eşyalarını kaldırmadı, olduğu gibi bıraktı.
  static const String esyaKaldirilmadi = 'dul_esya_kaldirilmadi';

  /// Eşinin eşyalarını ihtiyacı olana verdi.
  static const String esyaVerildi = 'dul_esya_verildi';

  /// Yıl dönümünü ailece anmaya çevirdi.
  static const String anmaDuzeni = 'dul_anma_duzeni_kuruldu';

  /// Eşinin ailesiyle bağı sürdürdü.
  static const String kayinBagiSurdu = 'dul_kayin_bagi_surdu';

  /// Eşinin bir işini, tarifini ya da uğraşını devraldı.
  static const String isiDevraldi = 'dul_isi_devraldi';

  // **Kapanış izi yazılmıyor (Paket AR çıtası).** İlk yazımda beş
  // karşılık olayı kendi "kapandı" izini bırakıyordu; depo çapındaki
  // `paket_ar_hikaye_izi_test.dart` bunu yakaladı: hiçbir yerin
  // okumadığı iz sayısı 22'den 27'ye çıkıyordu. İzin bir işi yoktu —
  // olaylar `repeatable` değil, tekrar çıkmalarını `seenEventIds`
  // zaten engelliyor. Yazılmayan iz, okunmayan iz sorununu da
  // doğurmuyor.
}

/// Dulluk olay havuzu (Paket CS).
const List<GameEvent> kWidowhoodEvents = <GameEvent>[
  // --- İlk yıl ------------------------------------------------------------
  //
  // `maxWidowYears: 1` ile kapatılır: bunlar kaybın hemen ardından
  // gelen yılın olayları, yirmi yıl sonrasının değil.
  GameEvent(
    id: 'dul_evin_sessizligi',
    category: EventCategory.kisisel,
    text: 'Ev sessiz. Akşamları televizyonu açık bırakıyorsun, ses olsun '
        'diye.',
    requirement: EventRequirement(requiresWidowed: true, maxWidowYears: 1),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'kabul',
        label: 'Sessizliğe alışmaya çalış',
        resultText: 'Alışmak doğru kelime değil ama günler geçiyor.',
        happiness: -3,
      ),
      EventChoice(
        id: 'cagir',
        label: 'Birini çağır, kalabalık olsun',
        resultText: 'Akşama misafir geldi. Ev bir süre eski haline '
            'benzedi.',
        happiness: 5,
        money: -400,
      ),
    ],
  ),
  GameEvent(
    id: 'dul_dolabin_tarafi',
    category: EventCategory.kisisel,
    text: 'Dolabın {es}\'in tarafı olduğu gibi duruyor. Kapağı her '
        'açışında aynı yerde duruyorsun.',
    requirement: EventRequirement(requiresWidowed: true, maxWidowYears: 2),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'birak',
        label: 'Dokunma, kalsın',
        resultText: 'Kapağı kapattın. Henüz değil.',
        happiness: -2,
        addFlags: <String>{WidowFlags.esyaKaldirilmadi},
      ),
      EventChoice(
        id: 'ver',
        label: 'İhtiyacı olana ver',
        resultText: 'Giysileri topladın, mahalledeki yardım sandığına '
            'bıraktın. Dolap bomboş ve bu da ayrı bir şey.',
        happiness: -1,
        addFlags: <String>{WidowFlags.esyaVerildi},
      ),
      EventChoice(
        id: 'birkac',
        label: 'Birkaç parçayı sakla, gerisini ver',
        resultText: 'Bir gömlek, bir atkı ve bir fotoğraf kaldı. '
            'Gerisini verdin.',
        happiness: 2,
        addFlags: <String>{WidowFlags.esyaVerildi},
      ),
    ],
  ),
  GameEvent(
    id: 'dul_kapidaki_komsu',
    category: EventCategory.aile,
    text: 'Komşu kapıyı çaldı, elinde tencere var. "Bugün de bizden" '
        'dedi.',
    requirement: EventRequirement(
      requiresWidowed: true,
      maxWidowYears: 1,
      livingRelations: <RelationType>{RelationType.komsu},
    ),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'al',
        label: 'Al ve teşekkür et',
        resultText: 'Tencereyi aldın. Akşam yemek yapmak zorunda '
            'kalmadın.',
        happiness: 4,
        bond: 4,
      ),
      EventChoice(
        id: 'cagir',
        label: 'İçeri çağır, birlikte yiyin',
        resultText: 'Masaya iki tabak koydun. Konuşmadan da oturulabiliyor.',
        happiness: 6,
        bond: 7,
      ),
    ],
  ),
  GameEvent(
    id: 'dul_evraklar',
    category: EventCategory.yetiskinlik,
    text: 'Üstüne kalan işler var: abonelikler, kayıtlar, imzalar. '
        'Masanın üstünde duruyorlar.',
    requirement: EventRequirement(requiresWidowed: true, maxWidowYears: 2),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'otur',
        label: 'Otur ve bitir',
        resultText: 'Bir günde bitti. Yorucuydu ama masa temiz.',
        happiness: 2,
        health: -2,
        money: -700,
      ),
      EventChoice(
        id: 'ertele',
        label: 'Sonra hallederim',
        resultText: 'Kâğıtlar masada kaldı. Bir gecikme bedeli çıktı.',
        happiness: -2,
        money: -1500,
      ),
      EventChoice(
        id: 'yardim',
        label: 'Çocuğundan yardım iste',
        resultText: 'İkiniz oturdunuz, yarısını o yazdı. İki saatte bitti.',
        happiness: 4,
        bond: 5,
      ),
    ],
  ),
  GameEvent(
    id: 'dul_ilk_tek_sofra',
    category: EventCategory.kisisel,
    text: 'Masaya oturdun ve iki tabak çıkardığını fark ettin.',
    requirement: EventRequirement(requiresWidowed: true, maxWidowYears: 1),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'kaldir',
        label: 'İkinciyi kaldır',
        resultText: 'Kaldırdın. Yemek soğumadan bitti.',
        happiness: -2,
      ),
      EventChoice(
        id: 'kalsin',
        label: 'Kalsın, dursun',
        resultText: 'Karşıda boş bir tabak. Yemeği öyle yedin.',
        happiness: -1,
      ),
    ],
  ),

  // --- İlk yıllar: 2-6 ----------------------------------------------------
  GameEvent(
    id: 'dul_yil_donumu',
    category: EventCategory.aile,
    text: 'Bugün evlilik yıl dönümünüz. Takvimde kendi kendine duruyor.',
    requirement: EventRequirement(
      requiresWidowed: true,
      minWidowYears: 1,
    ),
    repeatable: true,
    minAgeGap: 4,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'tek',
        label: 'Kendi başına an',
        resultText: 'Akşam fotoğraflara baktın. Uzun sürdü.',
        happiness: -1,
      ),
      EventChoice(
        id: 'ailece',
        label: 'Ailece bir araya gel',
        resultText: 'Herkes geldi. {es}\'i konuştunuz, güldünüz de. '
            'Bundan sonra bu günü böyle geçirmeye karar verdiniz.',
        happiness: 7,
        money: -900,
        addFlags: <String>{WidowFlags.anmaDuzeni},
      ),
      EventChoice(
        id: 'calis',
        label: 'Günü meşgul geçir',
        resultText: 'Akşama kadar oyalandın. Akşam yine aynı yerdeydi.',
        happiness: -2,
      ),
    ],
  ),
  GameEvent(
    id: 'dul_el_yazisi',
    category: EventCategory.kisisel,
    text: 'Bir kitabın arasında {es}\'in el yazısı çıktı. Alışveriş '
        'listesi.',
    requirement: EventRequirement(
      requiresWidowed: true,
      minWidowYears: 1,
      maxWidowYears: 12,
    ),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'sakla',
        label: 'Kitabın arasında bırak',
        resultText: 'Kitabı kapattın, rafa koydun. Yeri belli.',
        happiness: 3,
      ),
      EventChoice(
        id: 'goster',
        label: 'Çocuğuna göster',
        resultText: '"Annemin yazısı bu" dedi, eline aldı. Bir süre '
            'öyle durdu.',
        happiness: 5,
        bond: 6,
      ),
    ],
  ),
  GameEvent(
    id: 'dul_torun_sorusu',
    category: EventCategory.aile,
    text: 'Torunun sordu: "Dedemi anlatır mısın?" Nereden başlayacağını '
        'bilemedin.',
    requirement: EventRequirement(
      requiresWidowed: true,
      minWidowYears: 1,
      livingRelations: <RelationType>{RelationType.torun},
      personMinAge: 5,
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'anlat',
        label: 'Baştan anlat',
        resultText: 'İki saat konuştun. {kisi} hiç sıkılmadı, sorular '
            'sordu.',
        happiness: 8,
        bond: 9,
      ),
      EventChoice(
        id: 'kisa',
        label: 'Kısa kes',
        resultText: 'İki cümle söyledin, konuyu değiştirdin. {kisi} '
            'üstelemedi.',
        happiness: -1,
      ),
      EventChoice(
        id: 'fotograf',
        label: 'Fotoğrafları çıkar, birlikte bakın',
        resultText: 'Kutudaki fotoğrafları yere yaydınız. Her birinin '
            'ayrı hikâyesi vardı.',
        happiness: 9,
        bond: 10,
      ),
    ],
  ),
  GameEvent(
    id: 'dul_kayin_telefonu',
    category: EventCategory.aile,
    text: 'Eşinin ailesi aradı. "Bayramda bekliyoruz, sen de bizdensin" '
        'dediler.',
    requirement: EventRequirement(
      requiresWidowed: true,
      minWidowYears: 1,
      livingRelations: <RelationType>{
        RelationType.kayinvalide,
        RelationType.kayinpeder,
      },
    ),
    // **Ölçülmüş ağırlık (Paket CS).** Dul kalan 43 hayatın 397 dul
    // karesinde eşin ailesinden biri **yaşıyor** olan kare yalnızca 56
    // (12 hayat): evlilik sürerken bu oran %55 iken dullukta %14'e
    // düşüyor, çünkü kayınlar oyuncudan bir kuşak büyük. Ağırlık 4 ile
    // 250 hayatta beklenen görülme 0,7'ydi ve ölçümde gerçekten 0
    // çıktı — yani zincirin ilk halkası ölü doğuyordu (Paket CD'nin
    // ölçtüğü hata). Ağırlık 12, aynı 56 karede beklenen görülmeyi
    // ~2'ye çıkarır. Koşul gevşetilmedi: olay hâlâ yalnızca kayını
    // gerçekten yaşayan oyuncuya çıkıyor.
    weight: 12,
    choices: <EventChoice>[
      EventChoice(
        id: 'git',
        label: 'Git',
        resultText: 'Gittin. Masada senin yerin hâlâ ayrılmış.',
        happiness: 7,
        bond: 8,
        money: -600,
        addFlags: <String>{WidowFlags.kayinBagiSurdu},
      ),
      EventChoice(
        id: 'arasira',
        label: 'Teşekkür et, arada bir uğra',
        resultText: 'Gitmedin ama telefonu kapatmadın. Arada bir '
            'konuşuyorsunuz.',
        happiness: 2,
        bond: 2,
      ),
      EventChoice(
        id: 'uzaklas',
        label: 'Bağı burada bırak',
        resultText: 'Nazikçe hayır dedin. Bir süre sonra aramalar '
            'seyreldi.',
        happiness: -3,
        bond: -8,
      ),
    ],
  ),
  GameEvent(
    id: 'dul_esin_dostu',
    category: EventCategory.mahalle,
    text: 'Eşinin eski bir arkadaşı kapıya geldi. Elinde eski bir '
        'fotoğraf var.',
    requirement: EventRequirement(requiresWidowed: true, minWidowYears: 1),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'cay',
        label: 'Çay koy, otursun',
        resultText: 'İki saat {es}\'i konuştunuz. Bilmediğin bir '
            'hikâyesini öğrendin.',
        happiness: 7,
      ),
      EventChoice(
        id: 'kapida',
        label: 'Kapıda konuş',
        resultText: 'Fotoğrafı aldın, teşekkür ettin. Kapıyı kapattın.',
        happiness: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'dul_isini_devralma',
    category: EventCategory.kisisel,
    text: 'Eşinin yarım bıraktığı bir iş var: bitmemiş bir uğraş, '
        'defterde duran bir tarif.',
    requirement: EventRequirement(
      requiresWidowed: true,
      minWidowYears: 1,
      maxWidowYears: 15,
    ),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'devral',
        label: 'Sen sürdür',
        resultText: 'Baştan öğrendin. İlk denemeler kötüydü, sonra '
            'oturdu.',
        happiness: 6,
        money: -1200,
        addFlags: <String>{WidowFlags.isiDevraldi},
      ),
      EventChoice(
        id: 'kaldir',
        label: 'Olduğu gibi kaldır',
        resultText: 'Defteri çekmeceye koydun. Yeri orası.',
        happiness: 1,
      ),
    ],
  ),

  GameEvent(
    id: 'dul_o_taraftan_kimse',
    category: EventCategory.aile,
    text: 'Eşinin tarafından arayan kimse kalmadı. O ailenin hikâyesini '
        'bilen tek kişi sensin.',
    requirement: EventRequirement(requiresWidowed: true, minWidowYears: 2),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'yaz',
        label: 'Bildiklerini çocuğuna aktar',
        resultText: '{es}\'in annesini, babasını, oturdukları sokağı '
            'anlattın. Çocuğun ilk kez duyuyordu.',
        happiness: 6,
        bond: 5,
      ),
      EventChoice(
        id: 'sus',
        label: 'Kendine sakla',
        resultText: 'Anlatacak kimse aramadı, sen de anlatmadın.',
        happiness: -2,
      ),
    ],
  ),

  // --- Uzun yıllar: 7+ ----------------------------------------------------
  GameEvent(
    id: 'dul_iki_fincan',
    category: EventCategory.kisisel,
    text: 'Yıllar geçti ama hâlâ iki fincan çıkarıyorsun. Alışkanlık '
        'inatçı.',
    requirement: EventRequirement(requiresWidowed: true, minWidowYears: 7),
    repeatable: true,
    minAgeGap: 6,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'guldu',
        label: 'Kendi kendine gülümse',
        resultText: 'İkinciyi dolaba koydun. Bu kadar.',
        happiness: 3,
      ),
      EventChoice(
        id: 'doldur',
        label: 'İkisini de doldur',
        resultText: 'İki fincan çay. Biri soğuyana kadar karşıda durdu.',
        happiness: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'dul_anlatan_oldu',
    category: EventCategory.aile,
    text: 'Ailede {es}\'i hatırlayan en eski kişi sen kaldın. Anlatmazsan '
        'kimse bilmeyecek.',
    requirement: EventRequirement(requiresWidowed: true, minWidowYears: 10),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'yaz',
        label: 'Yaz, kalsın',
        resultText: 'Bir deftere yazdın. Nereden tanıştığınızı, ilk '
            'evinizi, kavgalarınızı.',
        happiness: 8,
        money: -200,
        addFlags: <String>{WidowFlags.anmaDuzeni},
      ),
      EventChoice(
        id: 'anlat',
        label: 'Anlatmaya devam et',
        resultText: 'Her buluşmada bir hikâye daha. Çocuklar artık '
            'kendileri soruyor.',
        happiness: 6,
        bond: 5,
      ),
      EventChoice(
        id: 'kendine',
        label: 'Kendine sakla',
        resultText: 'Anlatmadın. Bazı şeyler sende kalacak.',
        happiness: -2,
      ),
    ],
  ),
  GameEvent(
    id: 'dul_yeniden_birisi',
    category: EventCategory.mahalle,
    text: 'Biri sordu: "Hiç yeniden düşünmedin mi?" Cevabı sen de '
        'bilmiyorsun.',
    requirement: EventRequirement(
      requiresWidowed: true,
      minWidowYears: 3,
      maxAge: 95,
    ),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'acik',
        label: 'Olabilir, kim bilir',
        resultText: 'Kapıyı kapatmadın. Konu orada kaldı.',
        happiness: 3,
      ),
      EventChoice(
        id: 'hayir',
        label: 'Bir kere oldu, yeter',
        resultText: '"Bir ömür bir kişiye yeter" dedin. Kendin de '
            'inandın.',
        happiness: 2,
      ),
      EventChoice(
        id: 'kizdi',
        label: 'Soruyu hiç sevme',
        resultText: 'Sert cevap verdin. Soran pişman oldu, sen de.',
        happiness: -3,
      ),
    ],
  ),

  // --- İzlerin karşılığı --------------------------------------------------
  //
  // Beş iz, beş karşılık. Karşılığı olmayan iz bırakılmaz (Paket AR).
  GameEvent(
    id: 'dul_odanin_kapisi',
    category: EventCategory.kisisel,
    text: 'Dokunmadığın o taraf yıllardır öyle duruyor. Bugün kapağı '
        'açtın.',
    requirement: EventRequirement(
      requiresWidowed: true,
      minWidowYears: 3,
      requiredFlags: <String>{WidowFlags.esyaKaldirilmadi},
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'topla',
        label: 'Artık topla',
        resultText: 'Bir günde topladın. Hafifledin — hem iyi hem değil.',
        happiness: 4,
        removeFlags: <String>{WidowFlags.esyaKaldirilmadi},
      ),
      EventChoice(
        id: 'kapat',
        label: 'Kapat, dursun',
        resultText: 'Kapağı kapattın. Belki seneye.',
        happiness: -1,
      ),
    ],
  ),
  GameEvent(
    id: 'dul_verilen_ceket',
    category: EventCategory.mahalle,
    text: 'Sokakta birini gördün: üstündeki ceket {es}\'in ceketi.',
    requirement: EventRequirement(
      requiresWidowed: true,
      minWidowYears: 2,
      requiredFlags: <String>{WidowFlags.esyaVerildi},
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'bak',
        label: 'Arkasından bak, bir şey söyleme',
        resultText: 'Geçip gitti. Ceket üşümeyen birinin üstünde.',
        happiness: 6,
      ),
      EventChoice(
        id: 'selam',
        label: 'Selam ver',
        resultText: 'Konuştunuz. Ceketin nereden geldiğini bilmiyordu; '
            'söylemedin.',
        happiness: 7,
      ),
    ],
  ),
  GameEvent(
    id: 'dul_anma_yerlesti',
    category: EventCategory.aile,
    text: 'O günü ailece anma düzeni yerleşti. Bu yıl seni kimse '
        'hatırlatmadan herkes geldi.',
    requirement: EventRequirement(
      requiresWidowed: true,
      minWidowYears: 3,
      requiredFlags: <String>{WidowFlags.anmaDuzeni},
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'sofra',
        label: 'Sofrayı sen kur',
        resultText: 'Ev kalabalıktı. Torunlar {es}\'in adını artık '
            'kendiliğinden anıyor.',
        happiness: 9,
        bond: 7,
        money: -1100,
      ),
      EventChoice(
        id: 'birak',
        label: 'Bu yıl gençler kursun',
        resultText: 'Masayı çocuğun kurdu. Sen oturdun, anlatan oldun.',
        happiness: 8,
        bond: 8,
      ),
    ],
  ),
  GameEvent(
    id: 'dul_kayin_kapida',
    category: EventCategory.aile,
    text: 'Eşinin ailesi habersiz geldi. "Geçerken uğradık" dediler ama '
        'yol uzun.',
    requirement: EventRequirement(
      requiresWidowed: true,
      minWidowYears: 3,
      requiredFlags: <String>{WidowFlags.kayinBagiSurdu},
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'kal',
        label: 'Bu akşam kalın',
        resultText: 'Kaldılar. Sabaha kadar eski hikâyeler konuşuldu.',
        happiness: 9,
        bond: 9,
        money: -500,
      ),
      EventChoice(
        id: 'cay',
        label: 'Çay içip gitsinler',
        resultText: 'Bir saat oturdular. Giderken "yine geliriz" '
            'dediler.',
        happiness: 5,
        bond: 4,
      ),
    ],
  ),
  GameEvent(
    id: 'dul_devralinan_is',
    category: EventCategory.kisisel,
    text: 'Devraldığın uğraş artık senin elinde oturdu. Biri "bunu nasıl '
        'yapıyorsun" diye sordu.',
    requirement: EventRequirement(
      requiresWidowed: true,
      minWidowYears: 3,
      requiredFlags: <String>{WidowFlags.isiDevraldi},
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'ogret',
        label: 'Öğret',
        resultText: 'Anlattın. "{es} öğretti" demedin ama öyleydi.',
        happiness: 8,
      ),
      EventChoice(
        id: 'sat',
        label: 'Yaptığını sat',
        resultText: 'Beş parça yaptın, hepsi gitti. Para küçük, mesele '
            'o değil.',
        happiness: 7,
        money: 2400,
      ),
    ],
  ),
];
