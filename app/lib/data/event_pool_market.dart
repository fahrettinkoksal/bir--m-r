/// Şirket ve piyasa olayları (Paket AC).
///
/// **Hiçbiri yatırım tavsiyesi vermez.** "Şunu al kesin yükselir",
/// "krizde altın al" gibi bir cümle yok. Hiçbir seçenek **doğru cevap**
/// değildir: sattığında pişman olabilirsin, beklediğinde daha da
/// düşebilir, aldığında risk almış olursun. Sonucu önceden bilmenin yolu
/// yok — olay metni sonucu söylemez.
///
/// **Şirket adları tamamen kurgusaldır** (`data/company_catalog.dart`).
/// Gerçek bir şirket, borsa, banka, fon, kurum ya da kişi adı geçmez ve
/// gerçek bir olayla ilişkilendirilmez.
///
/// **Hiçbiri portföyü kendi kendine al/sat yapmaz.** Portföyün değerini
/// `IncidentEngine` değiştirir; bu olaylar oyuncunun o haberle
/// karşılaştığı **anı** anlatır ve para/mutluluk üzerinden işler. Böylece
/// aynı işi yapan ikinci bir ekonomi motoru doğmaz.
///
/// Metin üslubu `docs/WRITING_STYLE_TR.md`: doğal, kısa, yer yer esprili.
/// "Abi/oğlum/aga/lan" her cümlede tekrarlanmaz.
///
/// Ağırlıklar ve tutarlar `prototypeOnly`'dir (Q-168).
library;

import 'company_catalog.dart';
import '../domain/models/game_event.dart';
import '../domain/models/relation.dart';

const List<GameEvent> kMarketEvents = <GameEvent>[
  // =====================================================================
  // Şirket haberleri — portföyü olanlara
  // =====================================================================
  GameEvent(
    id: 'ac_sirket_konkordato',
    category: EventCategory.kisisel,
    text: 'Bozkır Holding\'in borçlarını çevirmekte zorlandığı bir '
        'süredir konuşuluyordu. Bu sabah haber netleşti: konkordato '
        'süreci başlamış.\n\nSepette o şirketin de payı var.',
    requirement: EventRequirement(
      minAge: 20,
      requiresPortfolio: true,
      requiresCompanyStatus: CompanyStatus.konkordato,
    ),
    repeatable: true,
    minAgeGap: 9,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'takip',
        label: 'Takip et, acele etme',
        resultText: 'Haberi okudun, kapattın. Şimdilik yapacak bir şey yok; '
            'süreç kendi hızında yürüyecek.',
        happiness: -3,
      ),
      EventChoice(
        id: 'arastir',
        label: 'Ne olduğunu anlamaya çalış',
        resultText: 'Akşam boyunca okudun. Konkordatonun ne olduğunu artık '
            'biliyorsun; bilmek rahatlatmadı ama en azından ne beklediğini '
            'anlıyorsun.',
        happiness: -2,
        intelligence: 2,
      ),
      EventChoice(
        id: 'kapat',
        label: 'Bakmayı bırak',
        resultText: 'Uygulamayı sildin gitti. Bakmamak da bir yöntem; '
            'değeri değiştirmiyor ama uykun daha iyi.',
        happiness: 1,
      ),
      // **Gerçek karar (Paket AD, §AD/3).** Şirket ciddi sorunluyken
      // oyuncu ya çıkar ya azaltır ya bekler. Hiçbiri doğru cevap değil:
      // konkordatodan çıkan şirket de var, kapanan da.
      EventChoice(
        id: 'azalt',
        label: 'Bir miktar azalt',
        resultText: 'Hepsini değil, bir kısmını çıkardın. Tamamen çıkmak da '
            'hiç dokunmamak da içine sinmedi.',
        happiness: -1,
        portfolioAction: PortfolioAction.satKismi,
        portfolioShare: 0.25,
      ),
      EventChoice(
        id: 'cik',
        label: 'Çık, bu iş bitti',
        resultText: 'Sattın. Zarar kesinleşti. Şirket toparlanırsa canın '
            'sıkılacak, batarsa iyi ki dedirtecek.',
        happiness: -3,
        portfolioAction: PortfolioAction.satKismi,
        portfolioShare: 0.60,
      ),
    ],
  ),
  GameEvent(
    id: 'ac_sirket_kayyum',
    category: EventCategory.kisisel,
    text: 'Sabah piyasayı açtığında herkes aynı haberi konuşuyordu: '
        'Doruk Yapı\'nın yönetimine geçici olarak müdahale edilmiş.'
        '\n\nHissede işlemler durduruldu. Satmak istesen de şimdilik '
        'satamıyorsun.',
    requirement: EventRequirement(
      minAge: 20,
      requiresPortfolio: true,
      requiresCompanyStatus: CompanyStatus.kayyum,
    ),
    repeatable: true,
    minAgeGap: 11,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'bekle',
        label: 'Beklemekten başka yol yok',
        resultText: 'Ekranda "işlem birimi kapalı" yazıyor. Yenile tuşuna '
            'basmak da bir şeyi değiştirmiyor.',
        happiness: -4,
      ),
      EventChoice(
        id: 'ogren',
        label: 'Süreç nasıl işliyor, öğren',
        resultText: 'Okuduğun kadarını anladın: kısa sürebilir, uzun da. '
            'Kimse tarih vermiyor.',
        happiness: -2,
        intelligence: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'ac_sirket_iflas',
    category: EventCategory.kisisel,
    text: 'Şirket faaliyetlerini sürdüremedi.\n\nGeçen yıl "toparlar" '
        'diyorlardı. Toparlamadı.',
    requirement: EventRequirement(
      minAge: 22,
      requiresPortfolio: true,
      requiresStrainedCompany: true,
    ),
    repeatable: true,
    minAgeGap: 14,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'kabul',
        label: 'Olan oldu',
        resultText: 'Sepette o şirketin payı kadar bir delik açıldı. '
            'Kalanı duruyor; hepsi gitmedi.',
        happiness: -6,
      ),
      EventChoice(
        id: 'ders',
        label: 'Ders çıkar',
        resultText: 'Tek bir isme çok fazla bağlanmanın ne demek olduğunu '
            'gördün. Bu bilgi bedava gelmedi.',
        happiness: -4,
        intelligence: 2,
      ),
    ],
  ),
  GameEvent(
    id: 'ac_bilanco_soku',
    category: EventCategory.kisisel,
    text: 'Pusula Yazılım\'ın bilançosunda beklenmeyen bir açık ortaya '
        'çıktı. Yönetimden iki kişi istifa etti.\n\nHisse günün daha '
        'başında sert düştü.',
    requirement: EventRequirement(
      minAge: 20,
      requiresPortfolio: true,
      requiresStrainedCompany: true,
    ),
    repeatable: true,
    minAgeGap: 8,
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'sogukkanli',
        label: 'Soğukkanlı kal',
        resultText: 'Ekranı kapattın. Panikle satan çok oldu bugün; sen '
            'olmadın. İyi mi kötü mü, birkaç yıl sonra belli olacak.',
        happiness: -2,
      ),
      EventChoice(
        id: 'sinirlen',
        label: 'Sinirlen',
        resultText: 'Akşam boyunca söylendin. Kimse duymadı, hisse de '
            'duymadı.',
        happiness: -4,
      ),
      EventChoice(
        id: 'azalt',
        label: 'Küçük bir miktar azalt',
        resultText: 'Riski biraz düşürdün. Tamamen çıkmadın; belki de '
            'doğrusu buydu, belki değil.',
        happiness: -1,
        portfolioAction: PortfolioAction.satKismi,
        portfolioShare: 0.15,
      ),
    ],
  ),
  GameEvent(
    id: 'ac_regulator_incelemesi',
    category: EventCategory.kisisel,
    text: 'Bir şirket hakkında inceleme başlatıldığı yazıyor. Ayrıntı yok, '
        '"gelişmeler takip edilecek" var.\n\nBu cümleyi daha önce de '
        'okudun.',
    requirement: EventRequirement(
      minAge: 20,
      requiresPortfolio: true,
      requiresCompanyStatus: CompanyStatus.inceleme,
    ),
    repeatable: true,
    minAgeGap: 6,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'bekle',
        label: 'Sonucu bekle',
        resultText: 'Bazı incelemeler temize çıkar, bazıları çıkmaz. '
            'Bekliyorsun.',
        happiness: -1,
      ),
      EventChoice(
        id: 'okuma',
        label: 'Haberi okumayı bırak',
        resultText: 'Bildirimleri kapattın. Haber gelmeyince gün daha sakin '
            'geçiyor.',
        happiness: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'ac_sermaye_artirimi',
    category: EventCategory.kisisel,
    text: 'Şirket yeni sermaye artırımı açıkladı.\n\nPiyasa haberi pek '
        'sevmedi.',
    requirement: EventRequirement(
      minAge: 20,
      requiresPortfolio: true,
    ),
    repeatable: true,
    minAgeGap: 7,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'anla',
        label: 'Neden gerektiğini anlamaya çalış',
        resultText: 'Şirket para topluyor. İyi bir işaret mi kötü mü, '
            'ona bakan yorumların yarısı biri yarısı öteki diyor.',
        intelligence: 1,
        happiness: -1,
      ),
      EventChoice(
        id: 'gecir',
        label: 'Geçiştir',
        resultText: 'Başlığı okudun, devamını okumadın. Hayat kısa.',
        happiness: -1,
      ),
    ],
  ),
  GameEvent(
    id: 'ac_satin_alma_haberi',
    category: EventCategory.kisisel,
    text: 'Bir şirket için satın alma konuşuluyor. Haber çıkar çıkmaz '
        'fiyat yukarı zıpladı.\n\nDaha dün "bu iş bitti" diyen aynı '
        'kişiler şimdi başka bir şey diyor.',
    requirement: EventRequirement(
      minAge: 20,
      requiresPortfolio: true,
      requiresThrivingCompany: true,
    ),
    repeatable: true,
    minAgeGap: 8,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'sevin',
        label: 'Sevin ama sesini çıkarma',
        resultText: 'Bugün iyi bir gün. Yarın ne olacağı ayrı konu.',
        happiness: 4,
      ),
      EventChoice(
        id: 'kuskulan',
        label: 'Kuşkuyla bak',
        resultText: 'Haberin doğrulanmadığını fark ettin. Bazı satın alma '
            'haberleri satın almayla bitmiyor.',
        happiness: 1,
        intelligence: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'ac_temettu_surprizi',
    category: EventCategory.kisisel,
    text: 'Hesaba küçük bir para düştü. Bir an "ne bu?" dedin, sonra '
        'anladın: temettü.\n\nMiktar hayatını değiştirecek gibi değil ama '
        'gelen para gelen paradır.',
    requirement: EventRequirement(
      minAge: 20,
      requiresPortfolio: true,
      requiresThrivingCompany: true,
    ),
    repeatable: true,
    minAgeGap: 5,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'kahve',
        label: 'Kendine bir şey al',
        resultText: 'Uzun zamandır almadığın şeyi aldın. Parayı da böyle '
            'harcamak gerekiyor bazen.',
        money: -1200,
        happiness: 4,
      ),
      EventChoice(
        id: 'birak',
        label: 'Dursun',
        resultText: 'Hesapta kalsın dedin. Bir yere gitmiyor.',
        happiness: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'ac_sektor_krizi',
    category: EventCategory.kisisel,
    text: 'Bütün bir sektör aynı hafta kötü haber verdi. Tek bir şirket '
        'olsa "kendi hatası" derdin; hepsi birdense başka bir şey var.',
    requirement: EventRequirement(
      minAge: 22,
      requiresPortfolio: true,
    ),
    repeatable: true,
    minAgeGap: 9,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'dagit',
        label: 'Dağıtmayı düşün',
        resultText: 'Her şeyi aynı yere koymanın ne demek olduğunu yeniden '
            'düşündün. Düşünmek bedava.',
        intelligence: 2,
        happiness: -2,
      ),
      EventChoice(
        id: 'bekle',
        label: 'Geçmesini bekle',
        resultText: 'Sektörler bazen toparlar, bazen yıllar alır. '
            'Bekliyorsun.',
        happiness: -2,
      ),
    ],
  ),
  GameEvent(
    id: 'ac_sektor_patlamasi',
    category: EventCategory.kisisel,
    text: 'Bir sektör birden herkesin dilinde. Yıllarca kimse bakmıyordu, '
        'şimdi haberler ondan açılıyor.',
    requirement: EventRequirement(
      minAge: 20,
      requiresPortfolio: true,
    ),
    repeatable: true,
    minAgeGap: 8,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'keyif',
        label: 'Keyfini sür',
        resultText: 'Ekrandaki yeşili sevdin. Not: yeşil kalıcı değil.',
        happiness: 4,
      ),
      EventChoice(
        id: 'temkin',
        label: 'Temkinli ol',
        resultText: 'Herkesin aynı şeyi konuştuğu dönemleri hatırladın. '
            'Sonları hep aynı olmuyor ama bazen oluyor.',
        happiness: 1,
        intelligence: 1,
      ),
    ],
  ),

  // =====================================================================
  // Fon tarafı
  // =====================================================================
  GameEvent(
    id: 'ac_fon_yonetici_degisti',
    category: EventCategory.kisisel,
    text: 'Fonun yöneticisi değişmiş. Bilgilendirme yazısı geldi; üç '
        'paragraf okudun, hiçbir şey anlamadın.',
    requirement: EventRequirement(
      minAge: 20,
      requiresPortfolio: true,
    ),
    repeatable: true,
    minAgeGap: 7,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'oku',
        label: 'Baştan sona oku',
        resultText: 'İkinci okuyuşta anladın: yeni kişi gelmiş, strateji '
            'aynı kalıyormuş. Şimdilik.',
        intelligence: 1,
      ),
      EventChoice(
        id: 'gec',
        label: 'Geç',
        resultText: 'Arşivledin. Bir gün gerekirse bulursun.',
        happiness: -1,
      ),
    ],
  ),
  GameEvent(
    id: 'ac_fon_yanlis_yatirim',
    category: EventCategory.kisisel,
    text: 'Fonun büyük bir yatırımı ters gitmiş. "Beklenenin altında '
        'performans" diye yazmışlar.\n\nGüzel cümle. Anlamı hoş değil.',
    requirement: EventRequirement(
      minAge: 20,
      requiresPortfolio: true,
    ),
    repeatable: true,
    minAgeGap: 8,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'sabret',
        label: 'Sabret',
        resultText: 'Fon dediğin şey içinde çok şey taşıyor; biri kötü '
            'gidince hepsi bitmiyor. Yine de can sıkıcı.',
        happiness: -3,
      ),
      EventChoice(
        id: 'sorgula',
        label: 'Neden olduğunu araştır',
        resultText: 'Raporu okudun. Yöneticinin savunması ikna edici '
            'değildi ama en azından ne olduğunu biliyorsun.',
        happiness: -2,
        intelligence: 2,
      ),
    ],
  ),
  GameEvent(
    id: 'ac_fon_tasfiye',
    category: EventCategory.kisisel,
    text: 'Fon kapanıyor.\n\nSenin bir kararın yok bu işte: payın '
        'hesabına geçecek, sonra ne yapacağına sen karar vereceksin.',
    requirement: EventRequirement(
      minAge: 20,
      requiresPortfolio: true,
    ),
    repeatable: true,
    minAgeGap: 13,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'kabul',
        label: 'Parayı bekle',
        resultText: 'Birkaç gün sonra hesapta göründü. Ne kâr ne zarar '
            'diye bakmadın bile; sadece kapandı.',
        happiness: -2,
      ),
      EventChoice(
        id: 'kizgin',
        label: 'Kızgınlığını belli et',
        resultText: 'Müşteri hizmetlerini aradın. Karşıdaki kişinin de '
            'elinde bir şey yoktu.',
        happiness: -3,
      ),
    ],
  ),
  GameEvent(
    id: 'ac_fon_birlesti',
    category: EventCategory.kisisel,
    text: 'Fon başka bir fonla birleşti. Adı değişti, içeriği biraz '
        'değişti, sen aynı yerdesin.',
    requirement: EventRequirement(
      minAge: 20,
      requiresPortfolio: true,
    ),
    repeatable: true,
    minAgeGap: 10,
    weight: 2,
    choices: <EventChoice>[
      EventChoice(
        id: 'tamam',
        label: 'Olur',
        resultText: 'Yeni adı bir süre yanlış söyledin, sonra alıştın.',
        happiness: -1,
      ),
      EventChoice(
        id: 'incele',
        label: 'Yeni fonun içine bak',
        resultText: 'Birleşme belgesini açtın. İçerik biraz değişmiş; '
            'senin durumun için büyük fark yok ama artık biliyorsun.',
        intelligence: 1,
      ),
    ],
  ),

  // =====================================================================
  // Piyasa geneli — panik, balon, tüyo
  // =====================================================================
  GameEvent(
    id: 'ac_piyasa_panigi',
    category: EventCategory.kisisel,
    text: 'Sabah telefonu açtın.\n\nEkran kıpkırmızı. Daha kahveyi '
        'içmeden para erimeye başladı.',
    // **Panik olayı sakin bir yılda çıkmaz (Paket AD, §6).** Piyasa
    // gerçekten kriz rejiminde olacak ya da işlem durması yaşanacak.
    requirement: EventRequirement(
      minAge: 20,
      requiresPortfolio: true,
      requiresCrisis: true,
    ),
    repeatable: true,
    minAgeGap: 7,
    weight: 6,
    choices: <EventChoice>[
      // **Seçimler portföyde gerçekten bir şey yapıyor (Paket AD, §6).**
      // Paket AC'de bunların tek etkisi mutluluktu, yani karar değil süslü
      // metindi. Hiçbiri "doğru cevap" değil: satmak zararı kesinleştirir
      // ama toparlanmayı kaçırır, almak dip olabilir de olmayabilir de.
      // Sonucu sonraki yılların piyasası söyler; burası bilmiyor.
      EventChoice(
        id: 'sat',
        label: 'Bir kısmını sat, rahatla',
        resultText: 'Elini titretmeden sattın. Zararı gerçekleştirdin; '
            'bazen kişinin uykusu paradan değerli oluyor. Doğru muydu, '
            'zamanla anlayacaksın.',
        happiness: -2,
        portfolioAction: PortfolioAction.satKismi,
        portfolioShare: 0.35,
      ),
      EventChoice(
        id: 'bekle',
        label: 'Hiçbir şey yapma',
        resultText: 'Uygulamayı kapattın. Ne kadar düşeceğini bilmiyorsun; '
            'kimse bilmiyor.',
        happiness: -4,
      ),
      EventChoice(
        id: 'al',
        label: 'Biraz daha al',
        resultText: 'Düşen fiyattan aldın. Cesaret mi inat mı, sonuç '
            'söyleyecek.',
        happiness: -1,
        intelligence: 1,
        portfolioAction: PortfolioAction.alKismi,
        portfolioShare: 0.30,
      ),
    ],
  ),
  GameEvent(
    id: 'ac_devre_kesici',
    category: EventCategory.kisisel,
    text: 'Düşüş öyle hızlı oldu ki işlemlere kısa süre ara verdiler.'
        '\n\nEkranda fiyat duruyor, hiçbir şey olmuyor. En tuhaf kısmı bu.',
    requirement: EventRequirement(
      minAge: 20,
      requiresPortfolio: true,
      requiresCrisis: true,
    ),
    repeatable: true,
    minAgeGap: 11,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'bekle',
        label: 'Açılmasını bekle',
        resultText: 'Açıldığında ne olacağını bilmeden bekledin. Uzun '
            'yirmi dakikaydı.',
        happiness: -3,
      ),
      EventChoice(
        id: 'uzaklas',
        label: 'Telefonu bırak',
        resultText: 'Yürüyüşe çıktın. Döndüğünde olan olmuştu; zaten '
            'elinde bir şey yoktu.',
        happiness: -1,
        health: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'ac_fomo_balon',
    category: EventCategory.kisisel,
    text: 'İş yerinde herkes aynı hisseden konuşuyor.\n\n"Kaçırma, daha '
        'yeni başlıyor."\n\nTelefonu açınca grafik zaten epey başlamış '
        'gibi duruyor.',
    // **FOMO olayı gerçekten ısınmış piyasada çıkar (Paket AD, §7).**
    // Değerleme ısısı oyuncuya **gösterilmiyor**: o yalnızca "herkes
    // bundan bahsediyor" cümlesini görüyor. Zirveyi önceden bilmenin yolu
    // yok — ısı yüksekken de piyasa bir süre daha yükselebilir.
    requirement: EventRequirement(
      minAge: 20,
      requiresEmployed: true,
      requiresHotAsset: 'hisse',
    ),
    repeatable: true,
    minAgeGap: 6,
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'buyuk',
        label: 'Ciddi bir miktar koy',
        resultText: 'Koydun. Şimdi her sabah ilk baktığın şey o. Bazı '
            'balonlar sürüyor, bazıları çöküyor; hangisi olduğunu '
            'önceden söyleyen kimse yok.',
        happiness: 2,
        portfolioAction: PortfolioAction.alKismi,
        portfolioShare: 0.45,
      ),
      EventChoice(
        id: 'kucuk',
        label: 'Küçük bir miktarla dene',
        resultText: 'Kaybetsen üzülmeyeceğin kadar koydun. Merakını da '
            'giderdin.',
        happiness: 1,
        portfolioAction: PortfolioAction.alKismi,
        portfolioShare: 0.10,
      ),
      EventChoice(
        id: 'karal',
        label: 'Tam tersi: elindekinin bir kısmını sat',
        resultText: 'Herkes alırken sen bir miktar çıktın. Erken mi davrandın, '
            'akıllılık mı ettin — bunu ancak yıllar söyler.',
        happiness: -1,
        intelligence: 1,
        portfolioAction: PortfolioAction.karAl,
        portfolioShare: 0.30,
      ),
      EventChoice(
        id: 'uzak',
        label: 'Uzak dur',
        resultText: 'Girmedin. Bir hafta boyunca herkes konuştukça içine '
            'bir şey oldu ama girmedin.',
        happiness: -1,
        intelligence: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'ac_arkadas_tuyosu',
    category: EventCategory.kisisel,
    text: '{kisi} mesaj attı: "Sağlam yerden duydum."\n\nNereden '
        'duyduğunu sormadın. Sorsan da net bir cevap almayacaktın.',
    requirement: EventRequirement(
      minAge: 20,
      maxAge: 75,
      livingRelations: <RelationType>{
        RelationType.arkadas,
        RelationType.kardes,
      },
      requireReachable: true,
    ),
    repeatable: true,
    minAgeGap: 7,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'guven',
        label: 'Güven ve gir',
        resultText: 'Girdin. Tüyo bazen tutuyor, bazen hiçbir şey olmuyor, '
            'bazen para gidiyor. Bu sefer hangisi olacak, henüz belli '
            'değil.',
        money: -9000,
        bond: 2,
      ),
      EventChoice(
        id: 'sor',
        label: 'Nereden duyduğunu sor',
        resultText: 'Sorunca konu değişti. Bu da bir cevap sayılır.',
        intelligence: 1,
        bond: -1,
      ),
      EventChoice(
        id: 'gulup',
        label: 'Gülüp geç',
        resultText: '"Sen yap abi, sonra anlat" dedin. Kırılmadı.',
        happiness: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'ac_faiz_soku',
    category: EventCategory.kisisel,
    text: 'Faizler sert yükseldi. Haberlerde ekonomistler konuşuyor, '
        'hepsi farklı şey söylüyor.\n\nKesin olan tek şey: vadeli '
        'hesabın oranı bugün dünden farklı.',
    requirement: EventRequirement(minAge: 22),
    repeatable: true,
    minAgeGap: 9,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'hesapla',
        label: 'Kendi hesabını yap',
        resultText: 'Kâğıda yazdın. Sayılar, kendi durumun için ne anlama '
            'geliyor onu gösterdi. Karar hâlâ senin.',
        intelligence: 2,
      ),
      EventChoice(
        id: 'takipsiz',
        label: 'Takip etme',
        resultText: 'Haberi kapattın. Faiz senden izin almadan hareket '
            'ediyor zaten.',
        happiness: -1,
      ),
    ],
  ),
  GameEvent(
    id: 'ac_kur_soku',
    category: EventCategory.kisisel,
    text: 'Kur bir günde ciddi biçimde oynadı. Markette fiyat etiketi '
        'değişmiş bile.\n\nAynı hafta bir de geri geldi; kimse ne '
        'olduğunu tam anlatamıyor.',
    requirement: EventRequirement(minAge: 20),
    repeatable: true,
    minAgeGap: 8,
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'gozle',
        label: 'İzle, karışma',
        resultText: 'Bir hafta izledin. İki yöne de gitti. Karışmadığına '
            'sevindin — ya da sevinmedin, belli değil.',
        happiness: -1,
      ),
      EventChoice(
        id: 'panik',
        label: 'Bir şey yapmak için acele et',
        resultText: 'Acele bir hamle yaptın. Acele hamleler bazen iyi '
            'çıkıyor; genelde çıkmıyor.',
        money: -2500,
        happiness: -2,
      ),
    ],
  ),
  GameEvent(
    id: 'ac_ani_yukselis',
    category: EventCategory.kisisel,
    text: 'Sebepsiz gibi görünen bir yükseliş oldu. Portföy bir haftada '
        'güzelleşti.\n\nGeçen ay herkes bu hisseden bahsediyordu, bu ay '
        'kimse adını anmıyordu. Şimdi yeniden konuşuluyor.',
    requirement: EventRequirement(
      minAge: 20,
      requiresPortfolio: true,
    ),
    repeatable: true,
    minAgeGap: 6,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'kar_al',
        label: 'Bir kısmını sat',
        resultText: 'Bir dilim sattın. "Keşke tutsaydım" ya da "iyi ki '
            'çıktım" — hangisini diyeceğini sonra öğreneceksin.',
        happiness: 2,
      ),
      EventChoice(
        id: 'tut',
        label: 'Elinde tut',
        resultText: 'Dokunmadın. Yükselen şeyi satmak da zor, tutmak da.',
        happiness: 3,
      ),
    ],
  ),
  GameEvent(
    id: 'ac_pisman_satis',
    category: EventCategory.kisisel,
    text: 'Geçen yıl paniğe kapılıp sattığın şey bu yıl toparlamış.'
        '\n\nHesabı yapmadın. Yapmasan daha iyi.',
    requirement: EventRequirement(
      minAge: 25,
      requiresPortfolio: true,
    ),
    repeatable: true,
    minAgeGap: 10,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'ders',
        label: 'Ders say',
        resultText: 'Bir dahaki paniğe daha hazırlıklı gireceksin. '
            'Hazırlıklı girmek panik yapmamak demek değil ama bir şey.',
        intelligence: 2,
        happiness: -2,
      ),
      EventChoice(
        id: 'unut',
        label: 'Unut',
        resultText: 'Kapattın. Geçmiş fiyatlara bakmanın kimseye faydası '
            'olmadı bugüne kadar.',
        happiness: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'ac_yeniden_islem',
    category: EventCategory.kisisel,
    text: 'Aylardır kapalı olan işlem sırası yeniden açıldı.\n\nAçılış '
        'fiyatını görmek için ekrana bakarken elin biraz titredi.',
    requirement: EventRequirement(
      minAge: 21,
      requiresPortfolio: true,
    ),
    repeatable: true,
    minAgeGap: 12,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'cik',
        label: 'Fırsatı kullan, çık',
        resultText: 'Açılır açılmaz sattın. Bu sefer bekleyip görmek '
            'istemedin.',
        happiness: 1,
      ),
      EventChoice(
        id: 'kal',
        label: 'Kal',
        resultText: 'Kapalıyken çıkamıyordun; açıkken de çıkmadın. '
            'Kararını verdin sayılır.',
        happiness: -1,
      ),
    ],
  ),
  GameEvent(
    id: 'ac_herkes_uzman',
    category: EventCategory.kisisel,
    text: 'Bir dönem geldi, tanıdığın herkes borsadan anlıyor. Kuzenin, '
        'komşun, berberin.\n\nKimse kaybettiğini anlatmıyor. Tuhaf bir '
        'istatistik.',
    requirement: EventRequirement(minAge: 22),
    repeatable: true,
    minAgeGap: 9,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'dinle',
        label: 'Dinle ama uygulamadan',
        resultText: 'Dinledin, not almadın. Fena bir yöntem değil.',
        happiness: 1,
        intelligence: 1,
      ),
      EventChoice(
        id: 'kapil',
        label: 'Sen de kapıl',
        resultText: 'Konuşulanlara uydun. Bir süre kendini kalabalığın '
            'içinde iyi hissettin.',
        money: -7000,
        happiness: 2,
      ),
    ],
  ),
];
