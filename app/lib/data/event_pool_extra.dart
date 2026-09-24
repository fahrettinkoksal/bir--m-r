/// Ek olay paketi (Paket F1): ileri yaş, iş hayatı, mahalle ve sonuç
/// zincirleri.
///
/// Ölçüm (`tool/event_report.dart`, 300 hayat) şunu gösterdi: 80 yaşından
/// sonra olay oranı %63'ten %30'a kadar düşüyordu; hayatın son yılları
/// sessizleşiyordu. Bu paket önce o boşluğu doldurur, sonra gündelik
/// hayatın az temsil edilen alanlarını (iş yeri, komşuluk, sokak) ekler.
///
/// Kurallar (Paket 4 ile aynı):
/// - Olmayan eşya, hesap, ehliyet veya kişi üzerine olay kurulmaz.
/// - Vefat etmiş kişi konuşturulmaz.
/// - Bir seçim sonucu gerçekten ileride hatırlanır; "hiç olmamış olayın
///   devamı" yazılmaz.
/// - Nostalji ile güncel hayat dengelidir.
library;

import '../domain/models/game_event.dart';
import '../domain/models/relation.dart';
import 'item_catalog.dart';

/// Bu pakette açılan hikâye izleri.
abstract final class ExtraFlags {
  /// Emanet para: tutuldu mu, yenildi mi?
  static const String emanetTutuldu = 'emanet_tutuldu';
  static const String emanetYendi = 'emanet_yendi';

  /// Komşuyla yaşanan gerginliğin sonucu.
  static const String komsuKazanildi = 'komsu_kazanildi';
  static const String komsuylaKusuldu = 'komsuyla_kusuldu';

  /// Çocukken dikilen fidan.
  static const String agacDikildi = 'agac_dikildi';

  /// Beslenen sokak hayvanı.
  static const String sokakHayvaniBeslendi = 'sokak_hayvani_beslendi';

  /// Ergenlikte tutulan defter.
  static const String siirDefteri = 'siir_defteri';

  /// Telefonla dolandırılma girişimi.
  static const String dolandiriciyaKanmadi = 'dolandiriciya_kanmadi';

  /// İş yerinde zam istenip istenmediği.
  static const String zamIstendi = 'zam_istendi';
}

/// Bu paketin kilitlediği kişi rolleri.
abstract final class ExtraRoles {
  /// Yaz işinde tanışılan usta/arkadaş.
  static const String yazIsiArkadasi = 'yaz_isi_arkadasi';
}

const List<GameEvent> kExtraEvents = <GameEvent>[
  // =====================================================================
  // Çocukluk (5-13): küçük kararlar, uzun izler
  // =====================================================================
  GameEvent(
    id: 'agac_dikimi',
    category: EventCategory.mahalle,
    text:
        'Okulun bahçesine fidan dağıtıldı. Herkese bir tane, adını '
        'yazacağın küçük bir etiketle birlikte.',
    requirement: EventRequirement(minAge: 7, maxAge: 13),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'dik',
        label: 'Fidanı dik ve adını yaz',
        resultText:
            'Toprağı elinle bastırdın. Etikete adını yazarken harfler '
            'biraz büyük kaçtı ama okunuyordu.',
        happiness: 4,
        addFlags: <String>{ExtraFlags.agacDikildi},
      ),
      EventChoice(
        id: 'ver',
        label: 'Fidanı başkasına ver',
        resultText:
            'Elindeki fidanı sıranın arkasındakine uzattın. O çok '
            'sevindi, sen de bahçenin gölgesinde oturdun.',
        happiness: 2,
        charisma: 2,
      ),
    ],
  ),
  GameEvent(
    id: 'diktigin_agac',
    category: EventCategory.mahalle,
    text:
        'Yolun kenarındaki okulun bahçesinden geçiyorsun. İçeride, '
        'senin boyunu çoktan geçmiş bir ağaç var.',
    requirement: EventRequirement(
      minAge: 35,
      requiredFlags: <String>{ExtraFlags.agacDikildi},
    ),
    repeatable: true,
    minAgeGap: 15,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'gir',
        label: 'Bahçeye gir, gövdesine bak',
        resultText:
            'Etiket yok artık, olması da beklenmezdi. Gövdeye elini '
            'koydun; ağaç senden daha uzun yaşayacak gibi duruyor.',
        happiness: 6,
      ),
      EventChoice(
        id: 'gec',
        label: 'Uzaktan bakıp yoluna devam et',
        resultText: 'Durmadın. Ama o gün boyunca aklından çıkmadı.',
        happiness: 3,
      ),
    ],
  ),
  GameEvent(
    id: 'sokak_hayvani',
    category: EventCategory.mahalle,
    text: 'Apartmanın girişinde bir kedi var. Islak, zayıf ve gitmiyor.',
    requirement: EventRequirement(minAge: 8, maxAge: 17),
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'besle',
        label: 'Evden bir şeyler getir',
        resultText:
            'Mutfaktan aşırdığın tabakla döndün. Kedi önce bakmadı '
            'bile, sonra tabak boşaldı.',
        happiness: 5,
        addFlags: <String>{ExtraFlags.sokakHayvaniBeslendi},
      ),
      EventChoice(
        id: 'haber',
        label: 'Kapıcıya haber ver',
        resultText:
            'Kapıcı kutu bulup girişe koydu. Kedi o kutuya taşındı, '
            'sen de her gün girerken selam verdin.',
        happiness: 3,
        charisma: 2,
      ),
      EventChoice(
        id: 'gec',
        label: 'Üzülerek geç',
        resultText:
            'Merdivenleri çıkarken arkana baktın. Bu, uzun süre '
            'aklında kaldı.',
        happiness: -2,
      ),
    ],
  ),
  GameEvent(
    id: 'hayvanin_donusu',
    category: EventCategory.mahalle,
    text:
        'Girişte tanıdık bir duruş: aynı köşe, daha iri bir kedi. '
        'Seni görünce kaçmıyor.',
    requirement: EventRequirement(
      minAge: 14,
      requiredFlags: <String>{ExtraFlags.sokakHayvaniBeslendi},
    ),
    repeatable: true,
    minAgeGap: 12,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'otur',
        label: 'Çöm ve seslen',
        resultText: 'Adı yoktu, sen de koymamıştın. Yine de geldi.',
        happiness: 5,
      ),
      EventChoice(
        id: 'devam',
        label: 'Gülümseyip geç',
        resultText: 'Kapıyı açarken arkandan bakıyordu.',
        happiness: 2,
      ),
    ],
  ),
  GameEvent(
    id: 'harclik_pazarligi',
    category: EventCategory.aile,
    text:
        '{sahip} {kisi} ile haftalık harçlık konusunu yeniden açtın. '
        'Sofrada herkes susup seni dinliyor.',
    requirement: EventRequirement(
      minAge: 9,
      maxAge: 15,
      livingRelations: <RelationType>{RelationType.anne, RelationType.baba},
      requireSameHousehold: true,
    ),
    repeatable: true,
    minAgeGap: 6,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'gerekce',
        label: 'Gerekçelerini sırala',
        resultText:
            'Otobüs parası, defter, arada bir tost. Sayınca kimse '
            'itiraz edemedi; harçlık biraz arttı.',
        money: 800,
        intelligence: 2,
        bond: 2,
      ),
      EventChoice(
        id: 'kus',
        label: 'Küs ve masadan kalk',
        resultText: 'Odana çekildin. Harçlık aynı kaldı, akşam da uzun sürdü.',
        happiness: -3,
        bond: -4,
      ),
      EventChoice(
        id: 'vazgec',
        label: 'Vazgeç, konuyu kapat',
        resultText:
            'Evin durumunu biliyordun. Konuyu kendin kapattın; '
            "kimse bir şey demedi ama {sahipk} {kisi} sana uzun baktı.",
        bond: 4,
        happiness: -1,
      ),
    ],
  ),
  GameEvent(
    id: 'okul_gosterisi',
    category: EventCategory.okul,
    text:
        'Yıl sonu gösterisi için sahneye çıkacak birileri aranıyor. '
        'Öğretmen sınıfa bakıyor, bakışlar seninkiyle kesişiyor.',
    requirement: EventRequirement(
      minAge: 7,
      maxAge: 13,
      requiresSchoolStudent: true,
    ),
    repeatable: true,
    minAgeGap: 5,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'cik',
        label: 'Parmak kaldır',
        resultText:
            'Sahnede ses titredi ama cümle tamamlandı. Alkış bitince '
            'kulağında bir uğultu kaldı, iyi cinsten.',
        charisma: 4,
        happiness: 4,
      ),
      EventChoice(
        id: 'perde',
        label: 'Perde arkasında çalış',
        resultText:
            'Işıkları ve sıraları sen ayarladın. Gösteri aksamadı; '
            'bunu bilen üç kişiydi.',
        intelligence: 3,
        happiness: 2,
      ),
    ],
  ),

  // =====================================================================
  // Ergenlik (14-19)
  // =====================================================================
  GameEvent(
    id: 'defter_siiri',
    category: EventCategory.kisisel,
    text:
        'Arka sayfalarına kimseye göstermediğin şeyler yazdığın bir '
        'defter var. Bugün biri onu masanın üstünde açık bıraktığını fark '
        'etti.',
    requirement: EventRequirement(minAge: 14, maxAge: 19),
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'sakla',
        label: 'Defteri kap ve sakla',
        resultText:
            'Çantaya attın. O gün defteri bir daha açmadın ama '
            'atmadın da.',
        happiness: 2,
        addFlags: <String>{ExtraFlags.siirDefteri},
      ),
      EventChoice(
        id: 'oku',
        label: 'Bir sayfa oku',
        resultText:
            'Sesin ortasında kısıldı. Kimse gülmedi; bu, beklediğin '
            'şey değildi.',
        charisma: 4,
        happiness: 3,
        addFlags: <String>{ExtraFlags.siirDefteri},
      ),
      EventChoice(
        id: 'yirt',
        label: 'Sayfayı yırt',
        resultText:
            'Yırtılan kâğıdın sesi sınıfta duyuldu. Akşam, yazdığını '
            'hatırlamaya çalıştın; olmadı.',
        happiness: -3,
      ),
    ],
  ),
  GameEvent(
    id: 'eski_defter',
    category: EventCategory.kisisel,
    text:
        'Dolabın üst rafında, kenarları sararmış bir defter çıktı. '
        'El yazısı seninki ama kelimeler bir başkasının gibi.',
    requirement: EventRequirement(
      minAge: 50,
      requiredFlags: <String>{ExtraFlags.siirDefteri},
    ),
    repeatable: true,
    minAgeGap: 18,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'oku',
        label: 'Baştan sona oku',
        resultText:
            'Bazı satırlarda güldün, birinde durdun. O satırı yazan '
            'çocuk hâlâ bir yerlerde.',
        happiness: 5,
      ),
      EventChoice(
        id: 'kaldir',
        label: 'Kapağını kapat, yerine koy',
        resultText: 'Rafa geri koydun. Orada durması yeterliydi.',
        happiness: 3,
      ),
    ],
  ),
  GameEvent(
    id: 'yaz_isi',
    category: EventCategory.yetiskinlik,
    text:
        'Yaz tatili başladı. Mahallenin köşesindeki dükkân iki aylığına '
        'birini arıyor; ücret az, saatler uzun.',
    requirement: EventRequirement(minAge: 16, maxAge: 20),
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'basla',
        label: 'İşe başla',
        resultText:
            'İlk gün ayakların şişti, ikinci hafta alıştın. Ay sonunda '
            'kendi kazandığın parayı elinde tuttun.',
        money: 11000,
        health: -2,
        intelligence: 2,
        charisma: 2,
        rememberPersonAs: ExtraRoles.yazIsiArkadasi,
      ),
      EventChoice(
        id: 'reddet',
        label: 'Yazı kendine ayır',
        resultText:
            'Sabahları geç kalktın, akşamları uzundu. Eylülde anlatacak '
            'çok şeyin yoktu ama dinlenmiştin.',
        happiness: 4,
        health: 2,
      ),
    ],
  ),
  GameEvent(
    id: 'grup_baskisi',
    category: EventCategory.mahalle,
    text:
        'Herkesin gittiği bir yer var, sen gitmeyince konu kapanmıyor. '
        'Bugün yine soruldu.',
    requirement: EventRequirement(minAge: 14, maxAge: 18),
    repeatable: true,
    minAgeGap: 4,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'git',
        label: 'Bu sefer git',
        resultText:
            'Gittin. Ortam sandığın kadar iyi değildi ama artık '
            'konuşulan şeyin ne olduğunu biliyorsun.',
        charisma: 3,
        happiness: 1,
      ),
      EventChoice(
        id: 'hayir',
        label: 'Gitmeyeceğini net söyle',
        resultText:
            '"Gelmiyorum" demek ilk seferde zor. İkinci seferde kimse '
            'ısrar etmedi.',
        charisma: 2,
        happiness: 2,
      ),
    ],
  ),
  GameEvent(
    id: 'gece_muzigi',
    category: EventCategory.kisisel,
    text:
        'Kulaklık takılı, ses biraz fazla. Duvarın öbür tarafından iki '
        'kez vuruldu.',
    requirement: EventRequirement(
      minAge: 13,
      maxAge: 24,
      // Kulaklık kimliğine bağlıyken oyuncuların çoğunda hiç çıkmıyordu;
      // müzik dinlenen herhangi bir cihaz yeterli.
      requiredPossessionKinds: <ItemKind>{ItemKind.elektronik},
    ),
    repeatable: true,
    minAgeGap: 5,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'kis',
        label: 'Sesi kıs',
        resultText:
            'Kıstın. Şarkı aynı şarkıydı ama artık tek başına '
            'dinleniyordu.',
        happiness: 2,
      ),
      EventChoice(
        id: 'devam',
        label: 'Aynı sesle devam et',
        resultText:
            'Sabah merdivende karşılaştığınızda kimse konuyu açmadı; '
            'selam da verilmedi.',
        happiness: 1,
        charisma: -2,
      ),
    ],
  ),

  // =====================================================================
  // Yetişkinlik ve iş hayatı
  // =====================================================================
  GameEvent(
    id: 'emanet_para',
    category: EventCategory.yetiskinlik,
    text:
        'Bir tanıdık, birkaç haftalığına sende dursun diye zarfla para '
        'bıraktı. Zarf çekmecede duruyor ve ay sonuna daha var.',
    // Emanete dokunmamak her bütçede anlamlıdır; olay kapatılmaz.
    // Kapatılan şey **yoksulluk iddiası**: sonuç metni artık oyuncunun
    // ay sonunu zor getirdiğini söylemiyor (D-092).
    requirement: EventRequirement(minAge: 20),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'dokunma',
        label: 'Zarfa hiç dokunma',
        resultText:
            'Zarf çekmecede durduğu gibi el değiştirdi. Bunu kimseye '
            'anlatmadın.',
        happiness: 3,
        addFlags: <String>{ExtraFlags.emanetTutuldu},
      ),
      EventChoice(
        id: 'kullan',
        label: 'Bir kısmını kullan, sonra yerine koy',
        resultText:
            'Yerine koymak düşündüğünden uzun sürdü. Zarf tamamlandı '
            'ama sen o çekmeceye bir daha aynı gözle bakmadın.',
        money: 8000,
        happiness: -4,
        addFlags: <String>{ExtraFlags.emanetYendi},
      ),
    ],
  ),
  GameEvent(
    id: 'emanetin_hatirlatilmasi',
    category: EventCategory.yetiskinlik,
    text:
        'Yıllar sonra aynı tanıdıkla karşılaştın. "Sana güvenilir" dedi, '
        'başka da bir şey demedi.',
    requirement: EventRequirement(
      minAge: 26,
      requiredFlags: <String>{ExtraFlags.emanetTutuldu},
    ),
    repeatable: true,
    minAgeGap: 20,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'tesekkur',
        label: 'Teşekkür et',
        resultText: 'Küçük bir cümleydi, akşam boyunca yanında kaldı.',
        happiness: 5,
        charisma: 2,
      ),
      EventChoice(
        id: 'gec',
        label: 'Konuyu değiştir',
        resultText: 'Hava durumuna geçtiniz. Yine de duymuştun.',
        happiness: 3,
      ),
    ],
  ),
  GameEvent(
    id: 'emanetin_golgesi',
    category: EventCategory.yetiskinlik,
    text:
        'Aynı tanıdık bir iş için isim aranıyor dedi ve sana bakmadan '
        'başkasının adını yazdı.',
    requirement: EventRequirement(
      minAge: 26,
      requiredFlags: <String>{ExtraFlags.emanetYendi},
    ),
    repeatable: true,
    minAgeGap: 20,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'sor',
        label: 'Neden diye sor',
        resultText: 'Cevap vermedi, gülümsedi. Cevap zaten sendeydi.',
        happiness: -3,
        intelligence: 2,
      ),
      EventChoice(
        id: 'sus',
        label: 'Sesini çıkarma',
        resultText:
            'Çekmecedeki zarfı hatırladın. O gün başka bir şey '
            'konuşulmadı.',
        happiness: -2,
      ),
    ],
  ),
  GameEvent(
    id: 'komsu_gerginligi',
    category: EventCategory.mahalle,
    text:
        'Üst kattan akşam boyu ses geliyor. Bu üçüncü gece ve yarın erken '
        'kalkacaksın.',
    requirement: EventRequirement(minAge: 22),
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'kapi_cal',
        label: 'Kapıyı çal, sakin konuş',
        resultText:
            'Kapıda kısa bir şaşkınlık, sonra özür. Ertesi hafta '
            'kapına bir tabak geldi.',
        charisma: 4,
        happiness: 3,
        addFlags: <String>{ExtraFlags.komsuKazanildi},
      ),
      EventChoice(
        id: 'sikayet',
        label: 'Yönetime şikâyet et',
        resultText: 'Ses kesildi. Merdivende selam da kesildi.',
        happiness: 1,
        addFlags: <String>{ExtraFlags.komsuylaKusuldu},
      ),
      EventChoice(
        id: 'katlan',
        label: 'Yastığı kulağına bastır',
        resultText: 'Sabaha kadar döndün durdun. İşe uykusuz gittin.',
        health: -3,
        happiness: -2,
      ),
    ],
  ),
  GameEvent(
    id: 'komsunun_yardimi',
    category: EventCategory.mahalle,
    text:
        'Anahtarın içeride kaldı ve kapı kapandı. Merdivende tanıdık bir '
        'yüz duruyor: üst kattaki komşu.',
    requirement: EventRequirement(
      minAge: 25,
      requiredFlags: <String>{ExtraFlags.komsuKazanildi},
    ),
    repeatable: true,
    minAgeGap: 14,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'kabul',
        label: 'Yardımı kabul et',
        resultText:
            'Çilingir gelene kadar onların mutfağında çay içtin. '
            'O gece iyi ki bir zamanlar kapıyı çalmıştın diye düşündün.',
        happiness: 5,
        charisma: 2,
      ),
      EventChoice(
        id: 'kendim',
        label: 'Kendin hallet',
        resultText:
            'Kendi başına çözdün ama teklif edilmiş olması bile '
            'yetti.',
        happiness: 3,
      ),
    ],
  ),
  GameEvent(
    id: 'komsunun_soguklugu',
    category: EventCategory.mahalle,
    text:
        'Asansörde üst kattaki komşuyla yalnız kaldın. Beş kat, tek '
        'kelime yok.',
    requirement: EventRequirement(
      minAge: 25,
      requiredFlags: <String>{ExtraFlags.komsuylaKusuldu},
    ),
    repeatable: true,
    minAgeGap: 12,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'selam',
        label: 'Önce sen selam ver',
        resultText: 'Kısa bir baş hareketi geldi. Başlangıç sayılır.',
        charisma: 3,
        happiness: 2,
        addFlags: <String>{ExtraFlags.komsuKazanildi},
        removeFlags: <String>{ExtraFlags.komsuylaKusuldu},
      ),
      EventChoice(
        id: 'bekle',
        label: 'Sen de sus',
        resultText: 'Kapı açıldı, ikiniz de farklı yöne yürüdünüz.',
        happiness: -1,
      ),
    ],
  ),
  GameEvent(
    id: 'is_yerinde_yeni_gelen',
    category: EventCategory.yetiskinlik,
    text:
        'İşe yeni biri başladı. Kimse anlatmaya gönüllü değil, ilk günün '
        'nasıl geçtiğini hatırlıyorsun.',
    requirement: EventRequirement(
      minAge: 22,
      requiredFlags: <String>{'calisma_hayati'},
    ),
    repeatable: true,
    minAgeGap: 13,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'anlat',
        label: 'İşi baştan anlat',
        resultText:
            'Yarım saatin gitti, karşılığında ekip içinde adın '
            '"sorulacak kişi" oldu.',
        charisma: 4,
        happiness: 2,
      ),
      EventChoice(
        id: 'kendi',
        label: 'Kendi işine bak',
        resultText:
            'Akşama kadar kimse sana bir şey sormadı. Bu da bir tür '
            'sessizlik.',
        happiness: -1,
      ),
    ],
  ),
  GameEvent(
    id: 'zam_istegi',
    category: EventCategory.yetiskinlik,
    text: 'Zam konuşmaları başladı. Odanın kapısı açık ve sıra sende.',
    requirement: EventRequirement(
      minAge: 24,
      requiredFlags: <String>{'calisma_hayati'},
    ),
    repeatable: true,
    minAgeGap: 15,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'iste',
        label: 'Rakam söyle',
        resultText:
            'Söylediğin rakam masada bir sessizlik yarattı. Sonuç '
            'istediğin kadar değildi ama sıfır da değildi.',
        money: 18000,
        charisma: 3,
        addFlags: <String>{ExtraFlags.zamIstendi},
      ),
      EventChoice(
        id: 'bekle',
        label: 'Gelecek seneyi bekle',
        resultText:
            'Kapıdan çıkarken söylemediğin cümleyi düşündün. Bir yıl '
            'daha aynı rakamla geçecek.',
        happiness: -3,
      ),
    ],
  ),
  GameEvent(
    id: 'is_cikisinda_yagmur',
    category: EventCategory.yetiskinlik,
    text:
        'Çıkışta bardaktan boşanırcasına yağıyor, şemsiye yok. Durakta '
        'kalabalık var.',
    requirement: EventRequirement(
      minAge: 18,
      requiredFlags: <String>{'calisma_hayati'},
    ),
    repeatable: true,
    minAgeGap: 12,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'kos',
        label: 'Islanmayı göze al, yürü',
        resultText:
            'Eve vardığında ayakkabıların içi su doluydu. Yine de '
            'yolda kimse konuşmadığı için kafan dinlendi.',
        health: -2,
        happiness: 3,
      ),
      EventChoice(
        id: 'bekle',
        label: 'Saçak altında bekle',
        resultText:
            'Yarım saat sonra yağmur dindi. Aynı saçağın altındaki '
            'kişiyle hava üzerine iki cümle kurdunuz.',
        charisma: 2,
        happiness: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'araba_yolda_kaldi',
    category: EventCategory.yetiskinlik,
    text:
        'Araba şehirden çıkışta öksürüp durdu. Kapılar açık, dörtlüler '
        'yanıyor.',
    requirement: EventRequirement(
      minAge: 18,
      requiredPossessionKinds: <ItemKind>{ItemKind.otomobil},
      requiredLicenses: <String>{'otomobil_ehliyeti'},
    ),
    repeatable: true,
    minAgeGap: 8,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'cekici',
        label: 'Çekici çağır',
        resultText:
            'Beklemek uzun sürdü, fatura da kısa değildi. En azından '
            'araba servise ulaştı.',
        money: -8000,
        happiness: -2,
      ),
      EventChoice(
        id: 'bak',
        label: 'Kaputu aç, kendin bak',
        resultText:
            'Üç kablo oynattın, dördüncüde çalıştı. Bunu yıllarca '
            'anlattın.',
        happiness: 4,
        intelligence: 2,
      ),
    ],
  ),

  // =====================================================================
  // İleri yaş (55+): ölçümdeki asıl boşluk
  // =====================================================================
  GameEvent(
    id: 'sabah_yuruyusu',
    category: EventCategory.kisisel,
    text:
        'Sabah altıda uyandın ve bir daha uyuyamadın. Dışarısı daha yeni '
        'aydınlanıyor.',
    requirement: EventRequirement(minAge: 58),
    repeatable: true,
    minAgeGap: 6,
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'yuru',
        label: 'Yürüyüşe çık',
        resultText:
            'Park boştu, sadece iki kişi vardı ve ikisi de senin gibi '
            'erken kalkmıştı. Dönüşte nefesin düzelmişti.',
        health: 4,
        happiness: 3,
      ),
      EventChoice(
        id: 'cay',
        label: 'Çay koy, pencereye otur',
        resultText:
            'Sokağın uyanmasını izledin. Acelesi olan herkesi '
            'tanıyordun.',
        happiness: 4,
      ),
    ],
  ),
  GameEvent(
    id: 'telefonla_dolandirici',
    category: EventCategory.kisisel,
    text:
        'Telefon çaldı. Karşıdaki kendini resmî bir kurumdan tanıttı ve '
        'acele etmeni istiyor.',
    requirement: EventRequirement(minAge: 55),
    repeatable: true,
    minAgeGap: 9,
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'kapat',
        label: 'Telefonu kapat',
        resultText:
            'Kapattın. Bir süre elinde tuttun, sonra kendi kendine '
            'güldün.',
        intelligence: 3,
        happiness: 2,
        addFlags: <String>{ExtraFlags.dolandiriciyaKanmadi},
      ),
      EventChoice(
        id: 'sor',
        label: 'Yakınına sor',
        resultText: 'Anlattığın ilk cümlede "kapat" dediler. Kapattın.',
        happiness: 3,
        bond: 3,
        addFlags: <String>{ExtraFlags.dolandiriciyaKanmadi},
      ),
      EventChoice(
        id: 'dinle',
        label: 'Söylediklerini yap',
        resultText:
            'İşlem tamamlandığında hattaki ses gitmişti. Parayı geri '
            'alamadın; anlatması da kolay olmadı.',
        money: -24000,
        happiness: -8,
      ),
    ],
  ),
  GameEvent(
    id: 'hastane_kuyrugu',
    category: EventCategory.kisisel,
    text:
        'Randevu saatin geçti, sıra ilerlemiyor. Koridordaki sandalyeler '
        'dolu.',
    requirement: EventRequirement(minAge: 62),
    repeatable: true,
    minAgeGap: 7,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'bekle',
        label: 'Sabırla bekle',
        resultText:
            'Üç saat sonra sıra geldi. Muayene beş dakika sürdü ama '
            'tahliller istendi ve sen onları yaptırdın.',
        health: 3,
        happiness: -1,
      ),
      EventChoice(
        id: 'cik',
        label: 'Vazgeç, eve dön',
        resultText:
            'Evde çayını içerken "geçer" dedin. Geçti de; ne olduğunu '
            'öğrenemedin.',
        health: -3,
        happiness: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'kis_hazirligi',
    category: EventCategory.aile,
    text:
        'Havalar döndü. Balkondaki kutular, kışlıklar, soba borusu... '
        'hepsi seni bekliyor.',
    requirement: EventRequirement(minAge: 50),
    repeatable: true,
    minAgeGap: 8,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'hazirlan',
        label: 'Bir günde hallet',
        resultText:
            'Akşam beliniz ağrıyordu ama ev kışa hazırdı. İlk soğukta '
            'bunun kıymetini bildin.',
        health: -2,
        happiness: 4,
      ),
      EventChoice(
        id: 'erteleme',
        label: 'Hafta sonuna bırak',
        resultText: 'Hafta sonu yağmur yağdı. Kutular balkonda ıslandı.',
        happiness: -2,
        money: -1800,
      ),
    ],
  ),
  GameEvent(
    id: 'gozluk_numarasi',
    category: EventCategory.kisisel,
    text:
        'Gazetenin yazıları bugün nedense daha küçük. Kolunu biraz daha '
        'uzatınca okunuyor.',
    requirement: EventRequirement(minAge: 45),
    repeatable: true,
    minAgeGap: 14,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'gozlukcu',
        label: 'Gözlükçüye git',
        resultText:
            'Numara çıktı. Camın arkasından dünya biraz daha net, '
            'aynada yüzün biraz daha farklı.',
        money: -5500,
        health: 2,
        happiness: 2,
      ),
      EventChoice(
        id: 'idare',
        label: 'Kolunu uzatmaya devam et',
        resultText: 'Altı ay idare ettin. Sonra yazılar iyice küçüldü.',
        happiness: -1,
        health: -1,
      ),
    ],
  ),
  GameEvent(
    id: 'fotograf_kutusu',
    category: EventCategory.aile,
    text:
        'Dolabın altından bir ayakkabı kutusu çıktı. İçi, tarihleri '
        'arkasına yazılmış fotoğraflarla dolu.',
    requirement: EventRequirement(minAge: 60),
    repeatable: true,
    minAgeGap: 11,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'ayir',
        label: 'Tek tek ayır',
        resultText:
            'Bazılarının arkasındaki yazıyı sen yazmışsın, bazılarını '
            'tanımadın bile. Kutu yeniden kapandığında akşam olmuştu.',
        happiness: 6,
      ),
      EventChoice(
        id: 'cerceve',
        label: 'Birini çerçeveletip as',
        resultText:
            'Duvarda artık bir fotoğraf var. Her geçişte bir saniye '
            'duruyorsun.',
        money: -1200,
        happiness: 7,
      ),
    ],
  ),
  GameEvent(
    id: 'bahcedeki_saksi',
    category: EventCategory.kisisel,
    text:
        'Balkondaki saksı kurumak üzere. Toprağı sertleşmiş, yaprakları '
        'sararmış.',
    requirement: EventRequirement(minAge: 52),
    repeatable: true,
    minAgeGap: 7,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'ilgilen',
        label: 'Toprağını değiştir',
        resultText:
            'Üç hafta sonra yeni bir sürgün verdi. Sabah ilk oraya '
            'bakıyorsun.',
        happiness: 4,
        health: 1,
      ),
      EventChoice(
        id: 'birak',
        label: 'Kendi hâline bırak',
        resultText:
            'Saksı bir süre daha dayandı. Sonra balkonun köşesine '
            'kaldırıldı.',
        happiness: -1,
      ),
    ],
  ),
  GameEvent(
    id: 'eski_dostun_haberi',
    category: EventCategory.kisisel,
    text:
        'Uzun zamandır görüşmediğin birinin adı, hiç beklemediğin bir '
        'konuşmada geçti. İyi olduğunu söylediler.',
    requirement: EventRequirement(minAge: 65),
    repeatable: true,
    minAgeGap: 8,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'ara',
        label: 'Numarasını bul, ara',
        resultText:
            'İlk beş saniye yabancıydı, sonra yıllar kapandı. '
            'Konuşma bittiğinde kulağın sıcaktı.',
        happiness: 7,
        charisma: 2,
      ),
      EventChoice(
        id: 'birak',
        label: 'İyi olduğunu bilmek yeter',
        resultText: 'Aramadın. Yine de o gün daha iyi geçti.',
        happiness: 3,
      ),
    ],
  ),
  GameEvent(
    id: 'komsu_kapisi_calmadi',
    category: EventCategory.mahalle,
    text:
        'Karşı daireden iki gündür ses yok. Kapının önündeki gazeteler '
        'birikmiş.',
    requirement: EventRequirement(minAge: 60),
    repeatable: true,
    minAgeGap: 10,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'cal',
        label: 'Kapıyı çal',
        resultText:
            'Kapı açıldı: grip olmuş, çorbayı sen götürdün. '
            'Ertesi gün gazeteler de alınmıştı.',
        happiness: 5,
        charisma: 3,
      ),
      EventChoice(
        id: 'yonetim',
        label: 'Yöneticiye haber ver',
        resultText:
            'Yönetici baktı, her şey yolundaydı. Yine de birinin fark '
            'etmiş olması konuşuldu.',
        happiness: 3,
      ),
    ],
  ),
  GameEvent(
    id: 'unutulan_isim',
    category: EventCategory.kisisel,
    text:
        'Karşındaki yüzü tanıyorsun ama adı bir türlü gelmiyor. '
        'Konuşma sürüyor ve o adını biliyor.',
    requirement: EventRequirement(minAge: 70),
    repeatable: true,
    minAgeGap: 6,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'soyle',
        label: 'Açıkça söyle',
        resultText:
            '"Adını bir türlü çıkaramadım" dedin. Güldü, söyledi, '
            'konuşma kaldığı yerden devam etti.',
        happiness: 3,
        charisma: 2,
      ),
      EventChoice(
        id: 'idare',
        label: 'İdare etmeye çalış',
        resultText:
            'Beş dakika boyunca hiç isim kullanmadın. Zor bir '
            'beş dakikaydı.',
        happiness: -2,
        intelligence: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'radyo_ve_sessizlik',
    category: EventCategory.kisisel,
    text: 'Ev sessiz. Radyoyu açtın, ilk çalan şarkı tanıdık çıktı.',
    requirement: EventRequirement(
      minAge: 72,
      requiredPossessions: <String>{'radyo'},
    ),
    repeatable: true,
    minAgeGap: 5,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'dinle',
        label: 'Sonuna kadar dinle',
        resultText:
            'Şarkı bitti, sen bir süre daha oturdun. Sessizlik artık '
            'daha katlanılır.',
        happiness: 5,
      ),
      EventChoice(
        id: 'kapat',
        label: 'Kapat',
        resultText: 'Sessizliği seçtin. Bazı günler o da iyi geliyor.',
        happiness: 2,
      ),
    ],
  ),
  GameEvent(
    id: 'yillarin_hesabi',
    category: EventCategory.kisisel,
    text:
        'Bugün kimse aramadı, kimse gelmedi. Akşam erken çöktü ve sen '
        'geçen yılları saymaya başladın.',
    requirement: EventRequirement(minAge: 78),
    repeatable: true,
    minAgeGap: 5,
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'yaz',
        label: 'Bir deftere yaz',
        resultText:
            'Yazdıkça sıraya girdi: kimler, nereler, hangi yıl. '
            'Defteri kapattığında içinde bir ağırlık azalmıştı.',
        happiness: 4,
        intelligence: 2,
      ),
      EventChoice(
        id: 'ara',
        label: 'Birini ara',
        resultText:
            'Telefonda uzun uzun konuştunuz. Kapatırken yarın yine '
            'arayacağını söyledin ve arayacaktın.',
        happiness: 6,
        bond: 4,
      ),
      EventChoice(
        id: 'uyu',
        label: 'Erken yat',
        resultText: 'Işığı kapattın. Yarın daha iyi olur.',
        happiness: 1,
        health: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'kapidaki_yardim',
    category: EventCategory.mahalle,
    text:
        'Market poşetleri ağır, merdiven uzun. Alt kattan biri "ben '
        'çıkarayım" diye seslendi.',
    requirement: EventRequirement(minAge: 74),
    repeatable: true,
    minAgeGap: 6,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'kabul',
        label: 'Teşekkür ederek kabul et',
        resultText:
            'Poşetler kapının önüne kadar geldi. Kapıyı kapatırken '
            'içinde iyi bir şey kaldı.',
        happiness: 5,
        health: 2,
      ),
      EventChoice(
        id: 'kendim',
        label: 'Kendin çıkar',
        resultText:
            'Üç molada çıktın. Kapıda soluklanırken "hâlâ '
            'yapabiliyorum" dedin.',
        health: -2,
        happiness: 3,
      ),
    ],
  ),
  GameEvent(
    id: 'evin_anahtari',
    category: EventCategory.aile,
    text:
        'Evin yedek anahtarı kimde dursun sorusu bugün açıldı. '
        'Konuşmayı sen başlatmadın.',
    requirement: EventRequirement(
      minAge: 75,
      livingRelations: <RelationType>{RelationType.cocuk, RelationType.kardes},
      personMinAge: 18,
    ),
    repeatable: true,
    minAgeGap: 9,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'ver',
        label: 'Anahtarı {kisi} alsın',
        resultText:
            'Anahtar el değiştirdi. Bunun bir kolaylık mı yoksa bir '
            'işaret mi olduğunu ikiniz de söylemediniz.',
        bond: 6,
        happiness: 2,
      ),
      EventChoice(
        id: 'bende',
        label: 'Anahtar bende kalsın',
        resultText:
            '"Daha vakit var" dedin. Konu kapandı ama tamamen '
            'kapanmadı.',
        happiness: 2,
        bond: -2,
      ),
    ],
  ),

  // =====================================================================
  // Gündelik hayat (her yaş)
  // =====================================================================
  GameEvent(
    id: 'market_kuyrugu',
    category: EventCategory.mahalle,
    text:
        'Kasada uzun bir kuyruk var. Arkandaki kişinin elinde iki parça, '
        'senin sepetin dolu.',
    requirement: EventRequirement(minAge: 16),
    repeatable: true,
    minAgeGap: 12,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'gecir',
        label: 'Öne al',
        resultText:
            'Teşekkür etti, kasiyer de gülümsedi. Sıra sana '
            'geldiğinde bir dakika kaybetmiştin, o kadar.',
        charisma: 3,
        happiness: 2,
      ),
      EventChoice(
        id: 'bekle',
        label: 'Sıranı koru',
        resultText: 'Herkes sırasını bekledi. Kuyruk normal hızında ilerledi.',
        happiness: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'asansor_arizasi',
    category: EventCategory.mahalle,
    text:
        'Asansör iki kat arasında durdu. Işık yanıyor, telefon çekiyor, '
        'ama kapı açılmıyor.',
    requirement: EventRequirement(minAge: 14),
    repeatable: true,
    minAgeGap: 17,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'sakin',
        label: 'Sakin ol, yardım çağır',
        resultText:
            'Yirmi dakika sonra kapı açıldı. Çıkarken kendi '
            'sakinliğine şaşırdın.',
        happiness: 2,
        intelligence: 2,
      ),
      EventChoice(
        id: 'panik',
        label: 'Kapıya vur, bağır',
        resultText:
            'Sesini duydular ama bekleme süresi değişmedi. Çıktığında '
            'ellerin titriyordu.',
        happiness: -3,
        health: -1,
      ),
    ],
  ),
  GameEvent(
    id: 'mahalle_dugunu',
    category: EventCategory.mahalle,
    text:
        'Sokağın başına düğün kurulmuş. Ses, ışık ve herkesin bildiği '
        'şarkılar.',
    requirement: EventRequirement(minAge: 10),
    repeatable: true,
    minAgeGap: 16,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'katil',
        label: 'Halkaya gir',
        resultText:
            'Adımları bilmiyordun, yanındaki öğretti. Gece geç '
            'bitti, ayakların ağrıdı.',
        happiness: 6,
        charisma: 3,
        health: -1,
      ),
      EventChoice(
        id: 'izle',
        label: 'Balkondan izle',
        resultText:
            'Yukarıdan bakmak da bir tür katılmaktı. Müzik bitince '
            'sokak sessizleşti.',
        happiness: 3,
      ),
    ],
  ),
  GameEvent(
    id: 'kaybolan_esya',
    category: EventCategory.kisisel,
    text:
        'Evde bir şey kayboldu ve tam olarak nereye koyduğunu '
        'hatırlamıyorsun. Aramak bütün günü aldı.',
    requirement: EventRequirement(minAge: 20),
    repeatable: true,
    minAgeGap: 14,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'topla',
        label: 'Aramışken her yeri topla',
        resultText:
            'Aradığını bulamadın ama ev yıllardır olmadığı kadar '
            'düzenli. İki gün sonra kayıp şey ceketin cebinden çıktı.',
        happiness: 3,
        intelligence: 1,
      ),
      EventChoice(
        id: 'vazgec',
        label: 'Aramayı bırak',
        resultText: 'Kendi kendine çıkar dedin. Çıktı da, tam altı ay sonra.',
        happiness: -1,
      ),
    ],
  ),
];
