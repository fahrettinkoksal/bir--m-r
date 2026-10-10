/// İlk yıllar: 0-7 yaş olayları (Paket BM).
///
/// **Ölçülen sorun.** Katalogda yaş aralığı yazılı 430 olayın yaşa göre
/// dağılımı taranınca ilk yılların ne kadar ince olduğu çıktı: 0 yaşında
/// **3**, 1 yaşında 9, 3 yaşında 16, 6 yaşında 18 aday olay var; 25
/// yaşında 194. Oysa her yeni hayat 0 yaşında başlıyor ve oyuncu ilk
/// yedi dokunuşu bu havuzda yapıyor. Yani oyunun **ilk izlenimi** en dar
/// havuzdan geliyordu ve ikinci hayatta aynı olaylar tekrar ediyordu.
/// `docs/EVENT_CONTENT_REPORT.md` aynı şeyi motor tarafından ölçmüştü:
/// 0-5 bandında yıl başına olay %104, diğer bütün bantlarda ~%200.
///
/// **Bu dosya yeni mekanik getirmez.** Yalnızca o boşluğa içerik koyar.
/// Kurallar:
///
/// - Bu yaşlarda kararları aile verir; metin de bunu böyle anlatır.
///   Seçimler bebeğin bilinçli tercihi gibi sunulmaz
///   (`event_pool_infancy.dart` ile aynı yaklaşım).
/// - **Çocuğun cüzdanından para çıkmaz.** Hastane, kreş, okul alışverişi
///   gibi masrafları hane öder; olay metni masrafı anlatır ama çocuğun
///   kendi parasına dokunmaz (ECO-001). Harçlık ve hediye gibi çocuğa
///   **gelen** para yazılır.
/// - Nostalji ile bugün aynı havuzda: mahalle, bakkal, sokak oyunu ile
///   telefon, kargo ve site aynı çocuklukta olabilir. Doğum yılı motoru
///   yok, dönem kurgusu yok.
/// - Ağır konu (hastalık, kaybolma korkusu) sade anlatılır; espri yok
///   (`docs/WRITING_STYLE_TR.md` §7). Hiçbiri tıbbi tavsiye değildir.
/// - Gerçek marka, dizi, kişi adı geçmez.
/// - Bırakılan her iz **okunur**: bu dosyanın sonundaki üç olay kendi
///   izlerinin karşılığıdır. Karşılığı olmayan iz bırakmak Paket AR'nin
///   ölçtüğü "sessiz iz" hatasını yeniden üretirdi.
///
/// Bütün sayılar `prototypeOnly`'dir.
///
/// Modül: `FeatureId.ilkYillarOlaylari` — kapatılınca bu havuz hiç
/// listelenmez ve ilk yıllar paket öncesi hâline döner
/// (`docs/FEATURE_FLAGS.md`).
library;

import '../domain/models/game_event.dart';
import '../domain/models/relation.dart';

/// İlk yılların hikâye izleri.
///
/// Dördünün de karşılığı bu dosyada yazılıdır; biri okunmadan kalırsa
/// `paket_ar_hikaye_izi_test.dart` sessiz iz sayar.
abstract final class EarlyYearsFlags {
  /// Yan tekerleri söküp denedi.
  static const String bisikletiDendedi = 'ilk_yillar_bisiklet_denedi';

  /// Bayram harçlığını kumbaraya attı.
  static const String kumbaraBasladi = 'ilk_yillar_kumbara';

  /// Harfleri okul başlamadan söktü.
  static const String harfleriSoktu = 'ilk_yillar_harfleri_soktu';

  /// Sokak oyununda mahallenin çocuklarıyla takıldı.
  static const String sokakOyunu = 'ilk_yillar_sokak_oyunu';

  /// Karşılık olaylarının kendi kapanış izleri.
  static const String bisikletKarsiligi = 'ilk_yillar_bisiklet_karsiligi';
  static const String sokakKarsiligi = 'ilk_yillar_sokak_karsiligi';
  static const String kumbaraKarsiligi = 'ilk_yillar_kumbara_karsiligi';
  static const String harfKarsiligi = 'ilk_yillar_harf_karsiligi';
}

const List<GameEvent> kEarlyYearsEvents = <GameEvent>[
  // ---------------------------------------------------------------
  // 0-2 yaş: hane etrafında dönen yıllar
  // ---------------------------------------------------------------
  GameEvent(
    id: 'ilk_yil_ev_dolusu_misafir',
    category: EventCategory.aile,
    text:
        'Ev gün boyu kalabalık. Kapı her çaldığında yeni bir kucak, yeni '
        'bir "maşallah" geliyor.',
    requirement: EventRequirement(
      minAge: 0,
      maxAge: 2,
      livingRelations: <RelationType>{RelationType.anne},
      requireSameHousehold: true,
    ),
    repeatable: true,
    minAgeGap: 2,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'kucaktan_kucaga',
        label: 'Kucaktan kucağa dolaş',
        resultText:
            'Akşama kadar herkesin kucağında bir tur attın. Yorgunluktan '
            'sofra kurulmadan uyudun.',
        happiness: 3,
        health: -1,
        bond: 2,
      ),
      EventChoice(
        id: 'yabancilik',
        label: 'Yabancılık çek',
        resultText:
            '{sahip} seni bırakmadı. Misafirler uzaktan baktı, sen de '
            'omzundan izledin.',
        happiness: 1,
        bond: 4,
      ),
    ],
  ),

  GameEvent(
    id: 'ilk_yil_dis_cikarma',
    category: EventCategory.aile,
    text:
        'Dişlerin çıkıyor. Gün boyu huzursuzsun, geceleri evde kimse tam '
        'uyuyamıyor.',
    requirement: EventRequirement(
      minAge: 0,
      maxAge: 2,
      livingRelations: <RelationType>{RelationType.anne},
      requireSameHousehold: true,
    ),
    repeatable: true,
    minAgeGap: 2,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'kucakta_gezdirildi',
        label: 'Kucakta sabahlandı',
        resultText:
            'Koridorda saatler geçti. Sabah ilk dişin göründüğünde evde '
            'herkes sırayla baktı.',
        happiness: 2,
        bond: 5,
        health: -1,
      ),
      EventChoice(
        id: 'soguk_halka',
        label: 'Soğuk diş halkası',
        resultText:
            'Buzdolabından çıkan halka işe yaradı. Gece yarısı ev ilk kez '
            'sessizliğe döndü.',
        happiness: 1,
        health: 2,
      ),
    ],
  ),

  GameEvent(
    id: 'ilk_yil_bakim_karari',
    category: EventCategory.aile,
    text:
        'Evde bir karar konuşuluyor: gündüzler sana kim bakacak?',
    requirement: EventRequirement(
      minAge: 1,
      maxAge: 3,
      livingRelations: <RelationType>{RelationType.anne},
      requireSameHousehold: true,
    ),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'kres',
        label: 'Kreşe verildi',
        resultText:
            'İlk hafta kapıda ağladın, ikinci hafta oyuncak rafına koşarak '
            'gittin. Akşam eve yeni bir şarkı getirdin.',
        happiness: 2,
        charisma: 3,
        intelligence: 2,
      ),
      EventChoice(
        id: 'buyukler',
        label: 'Evde büyükler baktı',
        resultText:
            'Gündüzlerin aynı pencerenin önünde geçti. Masaldan çok anı '
            'dinledin.',
        happiness: 3,
        bond: 5,
      ),
      EventChoice(
        id: 'izin',
        label: 'Bir yıl daha evde kalındı',
        resultText:
            'Hane bir yıl daha sıkı bütçeyle idare etti. Karşılığında '
            'bütün ilk adımların görüldü.',
        happiness: 4,
        bond: 4,
      ),
    ],
  ),

  // ---------------------------------------------------------------
  // 2-4 yaş: dünyayı deneme yılları
  // ---------------------------------------------------------------
  GameEvent(
    id: 'ilk_yil_inat_donemi',
    category: EventCategory.kisisel,
    text:
        'Yeni bir kelime öğrendin ve her şeye onu söylüyorsun: "hayır".',
    requirement: EventRequirement(
      minAge: 2,
      maxAge: 4,
      livingRelations: <RelationType>{RelationType.anne},
      requireSameHousehold: true,
    ),
    repeatable: true,
    minAgeGap: 2,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'sinir',
        label: 'Sakin bir sınır çizildi',
        resultText:
            'Ağlamak bir süre sürdü, sonra geçti. Akşam aynı masada aynı '
            'tabaktan yedin.',
        happiness: -1,
        intelligence: 2,
        bond: 2,
      ),
      EventChoice(
        id: 'pazarlik',
        label: 'Pazarlık yapıldı',
        resultText:
            'İki seçenek verildi, birini sen seçtin. Seçmek işe yaradı.',
        happiness: 2,
        charisma: 3,
      ),
      EventChoice(
        id: 'taviz',
        label: 'Taviz verildi',
        resultText:
            'Bu akşam senin dediğin oldu. Yarın akşam aynı konu yeniden '
            'açıldı.',
        happiness: 3,
        intelligence: -1,
      ),
    ],
  ),

  GameEvent(
    id: 'ilk_yil_parkta_kalabalik',
    category: EventCategory.mahalle,
    text:
        'Park kalabalık. Salıncakların arasında bir an elini bıraktın ve '
        'kalabalık seni yuttu.',
    requirement: EventRequirement(
      minAge: 2,
      maxAge: 5,
      livingRelations: <RelationType>{RelationType.anne},
    ),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'bagirdi',
        label: 'Adını duyana kadar bekle',
        resultText:
            'Bankın arkasında kıpırdamadan durdun. Adını duyunca koşarak '
            'çıktın; o akşam kimse elini bırakmadı.',
        happiness: -2,
        bond: 6,
        intelligence: 2,
      ),
      EventChoice(
        id: 'aradi',
        label: 'Kendin aramaya çık',
        resultText:
            'Yanlış yöne yürüdün, sonra tanıdık bir ses seni çağırdı. '
            'Korku akşama kadar geçmedi.',
        happiness: -3,
        health: -1,
        bond: 3,
      ),
    ],
  ),

  GameEvent(
    id: 'ilk_yil_ekran_suresi',
    category: EventCategory.aile,
    text:
        'Elindeki telefonu bırakmak istemiyorsun. Evde "yeter" ile "bir '
        'bölüm daha" arasında bir pazarlık sürüyor.',
    requirement: EventRequirement(
      minAge: 2,
      maxAge: 6,
      livingRelations: <RelationType>{RelationType.anne},
      requireSameHousehold: true,
    ),
    repeatable: true,
    minAgeGap: 2,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'sure_sinirli',
        label: 'Süre sınırı konuldu',
        resultText:
            'Ekran kapandı, oyuncak sepeti devrildi. Akşamın kalanı yerde '
            'geçti.',
        happiness: -1,
        health: 2,
        intelligence: 2,
      ),
      EventChoice(
        id: 'birlikte',
        label: 'Birlikte izlendi',
        resultText:
            'Aynı bölümü üç kez izlediniz. Üçüncüsünde şarkıyı sen '
            'söylüyordun.',
        happiness: 3,
        bond: 4,
      ),
      EventChoice(
        id: 'serbest',
        label: 'Serbest bırakıldı',
        resultText:
            'Akşam sessiz geçti. Gece uykuya geçmek uzun sürdü.',
        happiness: 2,
        health: -2,
      ),
    ],
  ),

  GameEvent(
    id: 'ilk_yil_emzik_veda',
    category: EventCategory.kisisel,
    text:
        'Emziğe veda vakti geldi. Evdeki herkesin bir yöntemi var.',
    requirement: EventRequirement(
      minAge: 2,
      maxAge: 4,
      livingRelations: <RelationType>{RelationType.anne},
      requireSameHousehold: true,
    ),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'hediye_takasi',
        label: 'Oyuncakla takas edildi',
        resultText:
            'Emziği kutuya koydun, karşılığında ahşap bir araba aldın. İki '
            'gece sordun, üçüncüsünde sormadın.',
        happiness: 2,
        intelligence: 2,
      ),
      EventChoice(
        id: 'kendi_zamani',
        label: 'Kendi zamanına bırakıldı',
        resultText:
            'Kimse acele etmedi. Bir sabah kendiliğinden yatağın altında '
            'kaldı.',
        happiness: 3,
        bond: 2,
      ),
    ],
  ),

  GameEvent(
    id: 'ilk_yil_kulak_agrisi',
    category: EventCategory.kisisel,
    text:
        'Gece kulağın ağrımaya başladı. Yastığı her çevirişinde ağlama '
        'yeniden başlıyor.',
    requirement: EventRequirement(
      minAge: 2,
      maxAge: 6,
      livingRelations: <RelationType>{RelationType.anne},
      requireSameHousehold: true,
    ),
    repeatable: true,
    minAgeGap: 3,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'nobetci',
        label: 'Nöbetçi doktora gidildi',
        resultText:
            'Sıra beklendi, muayene oldu, ilaç yazıldı. Dönüşte arabada '
            'uyudun ve sabaha iyi kalktın.',
        health: 4,
        happiness: -1,
        bond: 4,
      ),
      EventChoice(
        id: 'sabah_beklendi',
        label: 'Sabah beklendi',
        resultText:
            'Gece kucakta geçti. Sabah ilk iş hekime gidildi; ağrı birkaç '
            'gün sürdü.',
        health: 1,
        happiness: -2,
        bond: 3,
      ),
    ],
  ),

  // ---------------------------------------------------------------
  // 3-6 yaş: mahalle, sokak ve ilk kurallar
  // ---------------------------------------------------------------
  GameEvent(
    id: 'ilk_yil_komsu_cocugu_oyuncak',
    category: EventCategory.mahalle,
    text:
        'Komşunun çocuğu kapıda. Gözü doğrudan en sevdiğin oyuncağında.',
    requirement: EventRequirement(minAge: 3, maxAge: 6),
    repeatable: true,
    minAgeGap: 2,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'paylas',
        label: 'Paylaş',
        resultText:
            'İkiniz de sırayla oynadınız. Akşam kapıda yeni bir arkadaşlık '
            'vardı.',
        happiness: 2,
        charisma: 4,
      ),
      EventChoice(
        id: 'paylasma',
        label: 'Paylaşma',
        resultText:
            'Oyuncak sende kaldı, oyun yarıda bitti. Odada yalnız '
            'oynamanın tadı aynı değildi.',
        happiness: -2,
        charisma: -1,
      ),
      EventChoice(
        id: 'degis_tokus',
        label: 'Değiş tokuş teklif et',
        resultText:
            'Oyuncaklar bir gün için el değiştirdi. İkisi de akşam evine '
            'sağlam döndü.',
        happiness: 3,
        intelligence: 2,
        charisma: 2,
      ),
    ],
  ),

  GameEvent(
    id: 'ilk_yil_dizini_kanatti',
    category: EventCategory.kisisel,
    text:
        'Koşarken taşa takıldın. Dizin kanıyor, ses mahalleyi ayağa '
        'kaldırdı.',
    requirement: EventRequirement(minAge: 3, maxAge: 7),
    repeatable: true,
    minAgeGap: 2,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'evde_pansuman',
        label: 'Evde pansuman',
        resultText:
            'Yara yıkandı, bantlandı. Akşam üstü aynı yerde yeniden '
            'koşuyordun.',
        health: 1,
        happiness: 1,
      ),
      EventChoice(
        id: 'hekime',
        label: 'Hekime gidildi',
        resultText:
            'İki dikiş atıldı. Bir hafta dizini kollayarak yürüdün; iz '
            'yıllarca kaldı.',
        health: 3,
        happiness: -2,
      ),
    ],
  ),

  GameEvent(
    id: 'ilk_yil_bakkal_hesabi',
    category: EventCategory.mahalle,
    text:
        'Elinde bir kâğıt ve para, ilk kez tek başına bakkala '
        'gönderiliyorsun. Dükkân üç kapı ötede.',
    requirement: EventRequirement(minAge: 4, maxAge: 7),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'tam_getirdi',
        label: 'Listeyi ve para üstünü tam getir',
        resultText:
            'Kâğıttaki her şey poşette, para üstü avucunda. O günden sonra '
            'bakkal yolu senin işin oldu.',
        happiness: 3,
        intelligence: 3,
        charisma: 2,
      ),
      EventChoice(
        id: 'sekere_gitti',
        label: 'Para üstünü şekere ver',
        resultText:
            'Poşet eksiksizdi, para üstü yoktu. Evde uzun bir hesap '
            'konuşması oldu.',
        happiness: 2,
        intelligence: -1,
        bond: -2,
      ),
    ],
  ),

  GameEvent(
    id: 'ilk_yil_sokak_oyunu',
    category: EventCategory.mahalle,
    text:
        'Sokakta oyun kurulmuş. Senden küçüğü de var, büyüğü de; akşam '
        'ezanına kadar vakit var.',
    requirement: EventRequirement(minAge: 4, maxAge: 7),
    repeatable: true,
    minAgeGap: 2,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'oyuna_katil',
        label: 'Oyuna katıl',
        resultText:
            'Takımlar seçildi, dizler kirlendi, kimse skoru hatırlamadı. '
            'Eve terli ve mutlu döndün.',
        happiness: 4,
        health: 2,
        charisma: 3,
        addFlags: <String>{EarlyYearsFlags.sokakOyunu},
      ),
      EventChoice(
        id: 'balkondan_izle',
        label: 'Balkondan izle',
        resultText:
            'Oyunu baştan sona seyrettin. Kuralları öğrendin ama adın '
            'takımlara yazılmadı.',
        happiness: -1,
        intelligence: 2,
      ),
    ],
  ),

  // **Kapısı ölçümle açıldı (Paket CK).** İlk yazımda kapı
  // `personMaxAge: 4` ve yalnızca `kardes`'ti; bu, ilan edilen 3-7
  // bandını pratikte **tek bir yıla** indiriyordu. Sebep üretimde:
  // tam kardeş oyuncudan **her zaman büyük** doğuyor
  // (`life_generator`: yaş 1..maxSiblingAge, %5 ikiz hariç), yani
  // "4 yaşından küçük kardeş" ancak ikizde ya da oyuncu tam 3
  // yaşındayken bir yaş büyük kardeşte oluşuyordu. 200 bot hayatında
  // ölçüldü: eşik 4 → 81 aday kare, beklenen çıkış 2,07; eşik 6 → 224
  // kare, 5,84 ve oyuncunun yaş dağılımı {3:82, 4:67, 5:49, 6:16,
  // 7:10}. Altı yaşına kadar kardeşin bakımı evin ilgisini gerçekten
  // üstünde tutar; metin aynı kaldı.
  //
  // `yariKardes` de eklendi: oyunda **yeni doğan** kardeş yalnızca
  // yarım kardeş olarak geliyor (`step_siblings.dart`, `age: 0`), yani
  // olayın asıl anlattığı durum tam o kapının dışındaydı (Paket BZ'nin
  // "yanlış kapı" deseni). Sayılar `prototypeOnly` (Q-229).
  GameEvent(
    id: 'ilk_yil_kardes_kiskancligi',
    category: EventCategory.aile,
    text:
        'Evin ilgisi {sahipk} üstünde. Senin oyuncak sepetin aynı yerde '
        'duruyor ama kimse bakmıyor.',
    requirement: EventRequirement(
      minAge: 3,
      maxAge: 7,
      livingRelations: <RelationType>{
        RelationType.kardes,
        RelationType.yariKardes,
      },
      requireSameHousehold: true,
      personMaxAge: 6,
    ),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'yardim_et',
        label: 'Bakımına yardım et',
        resultText:
            'Bez taşıdın, ninni söyledin, kapıyı sessiz kapattın. Evde '
            '"abla-abi" olmanın başka bir yeri var.',
        happiness: 2,
        bond: 6,
        charisma: 2,
      ),
      EventChoice(
        id: 'geri_cekil',
        label: 'Köşene çekil',
        resultText:
            'Bir hafta az konuştun. Sonunda fark edildi ve bir akşam '
            'yalnız sana ayrıldı.',
        happiness: -2,
        bond: 2,
      ),
      EventChoice(
        id: 'dikkat_cek',
        label: 'Dikkat çekmeye çalış',
        resultText:
            'Devrilen bardak, yükselen ses, kısa bir ceza. İlgi geldi ama '
            'istediğin gibi gelmedi.',
        happiness: -1,
        bond: -3,
      ),
    ],
  ),

  GameEvent(
    id: 'ilk_yil_dugun_sahnesi',
    category: EventCategory.mahalle,
    text:
        'Mahallede düğün var. Davul sesi duvarları titretiyor, çocuklar '
        'sahnenin önünü doldurmuş.',
    requirement: EventRequirement(minAge: 4, maxAge: 7),
    repeatable: true,
    minAgeGap: 3,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'ortaya_cik',
        label: 'Ortaya çık, oyna',
        resultText:
            'Halkanın ortasında bir tur attın. Alkışı yıllarca '
            'hatırladın.',
        happiness: 4,
        charisma: 5,
      ),
      EventChoice(
        id: 'masada_kal',
        label: 'Masada kal',
        resultText:
            'Tabağındaki pastayı bitirdin, kalabalığı uzaktan izledin. '
            'Gece yine iyi geçti.',
        happiness: 2,
      ),
    ],
  ),

  GameEvent(
    id: 'ilk_yil_bayram_harcligi',
    category: EventCategory.aile,
    text:
        'Bayram sabahı. El öpüldü, cebe üst üste harçlık kondu; avucunda '
        'buruşuk paralar var.',
    requirement: EventRequirement(
      minAge: 4,
      maxAge: 7,
      livingRelations: <RelationType>{RelationType.anne},
    ),
    repeatable: true,
    minAgeGap: 3,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'kumbara',
        label: 'Kumbaraya at',
        resultText:
            'Paralar tek tek kumbaraya girdi. Sallayınca çıkan ses hoşuna '
            'gitti.',
        happiness: 2,
        money: 400,
        intelligence: 2,
        addFlags: <String>{EarlyYearsFlags.kumbaraBasladi},
      ),
      EventChoice(
        id: 'hepsini_harca',
        label: 'Aynı gün harca',
        resultText:
            'Bakkalın rafı küçüldü, akşam cebin boştu. Gün boyu keyfin '
            'yerindeydi.',
        happiness: 4,
        health: -1,
      ),
      EventChoice(
        id: 'paylas_kardes',
        label: 'Kardeşinle paylaş',
        resultText:
            'Paraları ikiye böldün. Bölüşme eşit olmadı ama kimse '
            'itiraz etmedi.',
        happiness: 3,
        money: 150,
        bond: 4,
      ),
    ],
  ),

  GameEvent(
    id: 'ilk_yil_ilk_deniz',
    category: EventCategory.kisisel,
    text:
        'Suyun kenarına geldin. Dalga ayağına değdiğinde geri kaçtın.',
    requirement: EventRequirement(minAge: 3, maxAge: 7),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'kucakta_girdi',
        label: 'Kucakta suya gir',
        resultText:
            'Omuz hizasında tutuldun, tuzlu suyu tattın ve güldün. '
            'Akşam uykun erken geldi.',
        happiness: 4,
        health: 2,
      ),
      EventChoice(
        id: 'kiyida_kaldi',
        label: 'Kıyıda kal',
        resultText:
            'Kovayla kum taşıdın, suya bir daha girmedin. Deniz bu yıl '
            'uzaktan izlendi.',
        happiness: 2,
        health: 1,
      ),
    ],
  ),

  GameEvent(
    id: 'ilk_yil_kayip_oyuncak',
    category: EventCategory.kisisel,
    text:
        'En sevdiğin oyuncak yok. Ev baştan aşağı arandı, bulunamadı.',
    requirement: EventRequirement(minAge: 3, maxAge: 7),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'aramaya_devam',
        label: 'Aramaya devam et',
        resultText:
            'Üç gün sonra koltuğun altından çıktı. O geceden sonra hep '
            'aynı yere koydun.',
        happiness: 2,
        intelligence: 2,
      ),
      EventChoice(
        id: 'vazgec',
        label: 'Vazgeç',
        resultText:
            'Yerine başka bir oyuncak geldi. Aynısı olmadı ama bir süre '
            'sonra sormayı bıraktın.',
        happiness: -1,
      ),
    ],
  ),

  // ---------------------------------------------------------------
  // 5-7 yaş: okulun kapısı
  // ---------------------------------------------------------------
  GameEvent(
    id: 'ilk_yil_anaokulu_ilk_gun',
    category: EventCategory.okul,
    text:
        'Anaokulunun kapısında duruyorsun. İçeride şarkı, dışarıda '
        'bırakılmak istemeyen bir el var.',
    requirement: EventRequirement(
      minAge: 4,
      maxAge: 6,
      livingRelations: <RelationType>{RelationType.anne},
    ),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'iceri_kostu',
        label: 'İçeri koş',
        resultText:
            'Boyama masasına ilk sen oturdun. Akşam eve üç yeni isim '
            'getirdin.',
        happiness: 3,
        charisma: 4,
        intelligence: 2,
      ),
      EventChoice(
        id: 'kapida_agladi',
        label: 'Kapıda ağla',
        resultText:
            'Öğretmen seni oyuna kattı, ağlamak bir saat sürdü. İkinci gün '
            'daha kolay oldu.',
        happiness: -1,
        bond: 4,
        intelligence: 2,
      ),
    ],
  ),

  GameEvent(
    id: 'ilk_yil_bisiklet_yan_teker',
    category: EventCategory.kisisel,
    text:
        'Bisikletin yan tekerleri sökülüyor. Sokak düz, ama sana hiç düz '
        'görünmüyor.',
    requirement: EventRequirement(minAge: 5, maxAge: 7),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'denedi',
        label: 'Dene',
        resultText:
            'İki kez düştün, üçüncüde arkadan tutan el çekildi ve sen '
            'pedalı çevirmeye devam ettin.',
        happiness: 4,
        health: -1,
        charisma: 2,
        addFlags: <String>{EarlyYearsFlags.bisikletiDendedi},
      ),
      EventChoice(
        id: 'geri_takildi',
        label: 'Yan tekerler geri takılsın',
        resultText:
            'Bu yıl olmadı. Sokakta yine en yavaş sen gittin ama hiç '
            'düşmedin.',
        happiness: 1,
        health: 1,
      ),
    ],
  ),

  GameEvent(
    id: 'ilk_yil_harfler',
    category: EventCategory.kisisel,
    text:
        'Tabelalardaki harfleri tek tek soruyorsun. Evde kimse soruların '
        'sonunu göremiyor.',
    requirement: EventRequirement(minAge: 5, maxAge: 7),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'okumayi_sokti',
        label: 'Okumaya çalış',
        resultText:
            'Okul başlamadan kendi adını okudun. Sonra da evdeki her '
            'kutunun üstünü.',
        happiness: 3,
        intelligence: 5,
        addFlags: <String>{EarlyYearsFlags.harfleriSoktu},
      ),
      EventChoice(
        id: 'resme_dondu',
        label: 'Resme dön',
        resultText:
            'Harfler beklesin dedin. Duvara asılan üç resmin oldu.',
        happiness: 3,
        charisma: 2,
      ),
    ],
  ),

  GameEvent(
    id: 'ilk_yil_okul_alisverisi',
    category: EventCategory.okul,
    text:
        'İlkokul listesi elde: çanta, kalem, önlük. Vitrinde bir çanta var '
        'ama fiyatı listedekinden yüksek.',
    requirement: EventRequirement(
      minAge: 6,
      maxAge: 7,
      livingRelations: <RelationType>{RelationType.anne},
    ),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'vitrindeki',
        label: 'Vitrindeki çanta istendi',
        resultText:
            'Hane bütçesinde başka bir kalem kısıldı. Çanta omzuna tam '
            'oturdu ve üç yıl dayandı.',
        happiness: 4,
        bond: 2,
      ),
      EventChoice(
        id: 'listedeki',
        label: 'Listedeki çanta alındı',
        resultText:
            'Sade bir çanta oldu. Üstüne kendi çıkartmalarını yapıştırdın '
            've kimse farkı anlamadı.',
        happiness: 2,
        intelligence: 2,
      ),
    ],
  ),

  GameEvent(
    id: 'ilk_yil_servis_mi_yurume',
    category: EventCategory.okul,
    text:
        'Okul iki sokak ötede. Servis mi, yürüyerek mi — evde konu bu.',
    requirement: EventRequirement(
      minAge: 6,
      maxAge: 7,
      livingRelations: <RelationType>{RelationType.anne},
    ),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'servis',
        label: 'Servisle gidildi',
        resultText:
            'Her sabah aynı koltuk, aynı pencere. Yolda uyumayı '
            'öğrendin.',
        happiness: 2,
        health: -1,
      ),
      EventChoice(
        id: 'yuruyerek',
        label: 'Yürüyerek gidildi',
        resultText:
            'Yol arkadaşların oldu. Kışın soğuk, yazın uzun geldi ama '
            'ayakların alıştı.',
        happiness: 2,
        health: 3,
        charisma: 2,
      ),
    ],
  ),

  GameEvent(
    id: 'ilk_yil_dogum_gunu',
    category: EventCategory.aile,
    text:
        'Doğum günün. Salonda bir pasta, kapıda zil sesi ve bir sürü '
        'ayakkabı var.',
    requirement: EventRequirement(
      minAge: 4,
      maxAge: 7,
      livingRelations: <RelationType>{RelationType.anne},
      requireSameHousehold: true,
    ),
    repeatable: true,
    minAgeGap: 3,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'kalabalik',
        label: 'Bütün mahalle çağrıldı',
        resultText:
            'Ev doldu, pasta yetmedi, komşudan tabak geldi. Akşam '
            'oyuncaklar sayılamadı.',
        happiness: 4,
        charisma: 3,
        money: 300,
      ),
      EventChoice(
        id: 'ev_halki',
        label: 'Yalnız ev halkı',
        resultText:
            'Mum üflendi, fotoğraf çekildi, erken yatıldı. Fotoğraf '
            'yıllarca buzdolabında kaldı.',
        happiness: 3,
        bond: 4,
      ),
    ],
  ),

  // ---------------------------------------------------------------
  // Karşılıklar: ilk yılların izi sonradan okunur
  // ---------------------------------------------------------------
  GameEvent(
    id: 'ilk_yil_karsilik_bisiklet',
    category: EventCategory.mahalle,
    text:
        'Mahallenin çocukları bisikletle tur atıyor. Sen yan tekerleri '
        'yıllar önce söktürmüştün.',
    requirement: EventRequirement(
      minAge: 8,
      maxAge: 12,
      requiredFlags: <String>{EarlyYearsFlags.bisikletiDendedi},
      forbiddenFlags: <String>{EarlyYearsFlags.bisikletKarsiligi},
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'onde_git',
        label: 'Önde git',
        resultText:
            'Yolu sen açtın. Yokuş aşağı kimse seni geçemedi.',
        happiness: 3,
        health: 2,
        charisma: 3,
        addFlags: <String>{EarlyYearsFlags.bisikletKarsiligi},
      ),
      EventChoice(
        id: 'kucugune_ogret',
        label: 'Küçüğüne öğret',
        resultText:
            'Sabahtan akşama kadar arkasından koştun. Akşam o da yan '
            'tekerleri söktürdü.',
        happiness: 2,
        charisma: 2,
        bond: 3,
        addFlags: <String>{EarlyYearsFlags.bisikletKarsiligi},
      ),
    ],
  ),

  GameEvent(
    id: 'ilk_yil_karsilik_kumbara',
    category: EventCategory.kisisel,
    text:
        'Yıllardır doldurduğun kumbara ağırlaştı. Kırmak için bir sebep '
        'arıyorsun.',
    requirement: EventRequirement(
      minAge: 9,
      maxAge: 14,
      requiredFlags: <String>{EarlyYearsFlags.kumbaraBasladi},
      forbiddenFlags: <String>{EarlyYearsFlags.kumbaraKarsiligi},
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'kir',
        label: 'Kır ve harca',
        resultText:
            'Masanın üstü bozuk parayla doldu. Hepsi tek bir şeye gitti ve '
            'o şey uzun süre sende kaldı.',
        happiness: 4,
        money: 2600,
        addFlags: <String>{EarlyYearsFlags.kumbaraKarsiligi},
      ),
      EventChoice(
        id: 'biriktirmeye_devam',
        label: 'Biriktirmeye devam et',
        resultText:
            'Kumbara rafa geri kondu. Her hafta biraz daha ağırlaştı.',
        happiness: 1,
        money: 1200,
        intelligence: 3,
        addFlags: <String>{EarlyYearsFlags.kumbaraKarsiligi},
      ),
    ],
  ),

  GameEvent(
    id: 'ilk_yil_karsilik_harfler',
    category: EventCategory.okul,
    text:
        'Sınıfta sesli okuma sırası sana geldi. Harfleri okul başlamadan '
        'sökmüştün.',
    requirement: EventRequirement(
      minAge: 7,
      maxAge: 11,
      requiresSchoolStudent: true,
      requiredFlags: <String>{EarlyYearsFlags.harfleriSoktu},
      forbiddenFlags: <String>{EarlyYearsFlags.harfKarsiligi},
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'sinifin_onunde',
        label: 'Baştan sona oku',
        resultText:
            'Sayfayı duraksamadan bitirdin. Öğretmen sırayı sende uzattı.',
        happiness: 3,
        intelligence: 4,
        charisma: 2,
        addFlags: <String>{EarlyYearsFlags.harfKarsiligi},
      ),
      EventChoice(
        id: 'gorunmez_kal',
        label: 'Göze batmamaya çalış',
        resultText:
            'Sessizce okudun, kimse fark etmedi. Kitap okumayı evde '
            'sürdürdün.',
        happiness: 1,
        intelligence: 3,
        addFlags: <String>{EarlyYearsFlags.harfKarsiligi},
      ),
    ],
  ),

  GameEvent(
    id: 'ilk_yil_karsilik_sokak',
    category: EventCategory.mahalle,
    text:
        'Mahalle takımı kuruluyor. Sokak oyunlarının eskilerinden biri '
        'sensin.',
    requirement: EventRequirement(
      minAge: 10,
      maxAge: 15,
      requiredFlags: <String>{EarlyYearsFlags.sokakOyunu},
      forbiddenFlags: <String>{EarlyYearsFlags.sokakKarsiligi},
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'kaptanlik',
        label: 'Takımı sen kur',
        resultText:
            'Kadroyu sen seçtin, itiraz eden olmadı. Maçtan çok kurulan '
            'takım hatırlandı.',
        happiness: 3,
        charisma: 5,
        addFlags: <String>{EarlyYearsFlags.sokakKarsiligi},
      ),
      EventChoice(
        id: 'kenarda',
        label: 'Kadroya gir, yeter',
        resultText:
            'Adın listeye yazıldı. Oynadın, koştun, kaptanlık başkasına '
            'kaldı.',
        happiness: 2,
        health: 2,
        addFlags: <String>{EarlyYearsFlags.sokakKarsiligi},
      ),
    ],
  ),

  GameEvent(
    id: 'ilk_yil_adinin_hikayesi',
    category: EventCategory.aile,
    text:
        'Adın konuşuluyor. Herkesin bir önerisi, her önerinin bir '
        'hikâyesi var.',
    requirement: EventRequirement(
      minAge: 0,
      maxAge: 1,
      livingRelations: <RelationType>{RelationType.anne},
      requireSameHousehold: true,
    ),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'buyukten_gelen',
        label: 'Büyüklerden gelen ad',
        resultText:
            'Adın evin en yaşlısından geldi. Her bayram bu anlatıldı.',
        happiness: 2,
        bond: 5,
      ),
      EventChoice(
        id: 'annenin_sectigi',
        // Etikette yer tutucu yok: `{sahipk}` "annen" verir ve
        // "annen seçtiği ad" bozuk olur. Sonuç metninde aynı yer
        // tutucu doğru çalışıyor ("Adını annen seçti").
        label: 'Evdekilerden birinin seçtiği ad',
        resultText:
            'Adını {sahipk} seçti ve kimse itiraz etmedi. Nüfusa o '
            'haliyle yazıldı.',
        happiness: 3,
        bond: 3,
        charisma: 2,
      ),
    ],
  ),

  GameEvent(
    id: 'ilk_yil_ilk_kahkaha',
    category: EventCategory.aile,
    text:
        'İlk kez kahkahayla güldün. Evde herkes aynı hareketi tekrar '
        'etmeye çalışıyor.',
    requirement: EventRequirement(minAge: 0, maxAge: 1),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'tekrar_guldu',
        label: 'Her seferinde gül',
        resultText:
            'Aynı oyun akşama kadar kırk kez tekrarlandı ve kırkında da '
            'güldün.',
        happiness: 4,
        charisma: 3,
      ),
      EventChoice(
        id: 'bir_kez',
        label: 'Bir kez gül, sonra bak',
        resultText:
            'İkinci denemede yalnızca baktın. Herkes birinciyi anlattı '
            'durdu.',
        happiness: 2,
        intelligence: 2,
      ),
    ],
  ),

  GameEvent(
    id: 'ilk_yil_aksam_aglamasi',
    category: EventCategory.aile,
    text:
        'Akşam saatleri geldiğinde ağlaman dinmiyor. Saat hep aynı, sebep '
        'belirsiz.',
    requirement: EventRequirement(minAge: 0, maxAge: 1),
    repeatable: true,
    minAgeGap: 2,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'gezdirildi',
        label: 'Kucakta gezdirildi',
        resultText:
            'Koridor, balkon, yine koridor. Bir yerde uyudun ve ev '
            'sessizleşti.',
        happiness: 2,
        bond: 4,
        health: 1,
      ),
      EventChoice(
        id: 'hekime_danisildi',
        label: 'Hekime danışıldı',
        resultText:
            'Muayene oldun, "geçici" dendi ve birkaç hafta sonra gerçekten '
            'geçti.',
        health: 3,
        bond: 2,
      ),
    ],
  ),

  GameEvent(
    id: 'ilk_yil_ilk_fotograf',
    category: EventCategory.aile,
    text:
        'Fotoğraf çekilecek. Üstüne giydirilen takım kaşındırıyor, ışık '
        'gözünü alıyor.',
    requirement: EventRequirement(minAge: 0, maxAge: 2),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'poz_verdi',
        label: 'Poz ver',
        resultText:
            'Tek karede tutturuldu. O fotoğraf yıllarca salonun duvarında '
            'kaldı.',
        happiness: 3,
        appearance: 2,
      ),
      EventChoice(
        id: 'aglayarak',
        label: 'Ağlayarak çekil',
        resultText:
            'Bütün karelerde ağlıyorsun. Ailede en çok gülünen fotoğraf o '
            'oldu.',
        happiness: 1,
        bond: 3,
      ),
    ],
  ),
];
