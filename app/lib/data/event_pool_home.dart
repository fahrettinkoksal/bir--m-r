/// Oturduğun ev: kendi evinde yaşayan oyuncunun olayları (Paket BP).
///
/// **Ölçülen sorun.** Katalogda konut olayları vardı ama hepsi
/// *başkasının* evi üzerineydi. 524 olayın kapıları sayıldı: kiracı
/// kapısı 11, kiraya veren kapısı 14, boş ev kapısı 8 — **oturulan evin
/// kapısı sıfır.** Oyun motorunda böyle bir koşul bile yoktu. Sonuç
/// ölçüldü: kendi evinde oturan oyuncunun konut havuzundan aday olayı
/// 30, 40, 50 ve 60 yaşında **0**; kiracının 8. Toplam aday olay sayısı
/// da kiracıda daha yüksekti (40 yaşında 67'ye karşı 56). Yani oyuncu
/// hayatının en büyük alışverişini yapıp evine çıkınca hayatı
/// **sessizleşiyordu**.
///
/// Bu dosya o boşluğa içerik koyar. Kurallar:
///
/// - Kapı tek: `requiresOwnedResidence`. Mülk sahibi olmak yetmez,
///   oyuncunun **o evde oturuyor** olması gerekir. Evini kiraya verip
///   kirada oturana bu olaylar çıkmaz; onun için kiracı ve kiraya veren
///   havuzları var.
/// - Para gerçekten cüzdandan çıkar (ECO-001) ve tutarlar mevcut konut
///   havuzuyla aynı ölçekte kalır: usta 9.000, kombi 26.000, taşınma
///   45.000 çıpaları (hepsi `prototypeOnly`).
/// - Gerçek marka, firma, site ve kişi adı geçmez. Kentsel dönüşüm,
///   hırsızlık ve sağlık gibi ağır konular sade anlatılır; espri yok
///   (`docs/WRITING_STYLE_TR.md` §7).
/// - Komşu ve apartman **metinde** yaşar; yeni kişi kaydı açılmaz.
///   Komşunun kalıcı kişi olması ayrı bir paket (yeni bağ türü, ekran
///   listeleri ve erişilebilirlik gerekir).
/// - Bırakılan her iz **okunur**: dosyanın sonundaki yedi olay kendi
///   izlerinin karşılığıdır. Karşılığı olmayan iz bırakmak Paket AR'nin
///   ölçtüğü "sessiz iz" hatasını yeniden üretirdi.
///
/// Modül: `FeatureId.oturulanEv` — kapatılınca bu havuz hiç listelenmez
/// (`docs/FEATURE_FLAGS.md`).
library;

import '../domain/models/game_event.dart';
import 'item_catalog.dart';

/// Oturulan evin hikâye izleri.
abstract final class HomeFlags {
  /// Kombiyi yenilemek yerine yamayla idare etti.
  static const String kombiYamali = 'ev_kombi_yamali';

  /// Çatı masrafını erteledi.
  static const String catiErtelendi = 'ev_cati_ertelendi';

  /// Eski tesisatı olduğu gibi bıraktı.
  static const String tesisatEski = 'ev_tesisat_eski';

  /// Konut sigortası yaptırdı.
  static const String evSigortali = 'ev_sigortali';

  /// Kapıyı ve kilidi güçlendirdi.
  static const String kapiGuclendi = 'ev_kapi_guclendi';

  /// Komşusuna anahtar işinde yardım etti.
  static const String komsuyaYardim = 'ev_komsuya_yardim';

  /// Binanın dönüşüm kararına katıldı.
  static const String donusumeGirdi = 'ev_donusume_girdi';

  /// Karşılık olaylarının kapanış izleri.
  static const String kombiKarsiligi = 'ev_kombi_karsiligi';
  static const String catiKarsiligi = 'ev_cati_karsiligi';
  static const String tesisatKarsiligi = 'ev_tesisat_karsiligi';
  static const String sigortaKarsiligi = 'ev_sigorta_karsiligi';
  static const String kapiKarsiligi = 'ev_kapi_karsiligi';
  static const String komsuKarsiligi = 'ev_komsu_karsiligi';
  static const String donusumKarsiligi = 'ev_donusum_karsiligi';
}

/// Oturulan evin olayları.
const List<GameEvent> kHomeEvents = <GameEvent>[
  // ===================================================================
  // 1) Ev bir şeydir ve yıpranır
  // ===================================================================
  GameEvent(
    id: 'ev_kombi_gitti',
    category: EventCategory.kisisel,
    text: 'Kombi ocak ayının ortasında sustu.\n\n'
        'Usta baktı: "Bu artık yamayla gider ama ne kadar gider '
        'bilinmez."',
    requirement: EventRequirement(minAge: 20, requiresOwnedResidence: true),
    repeatable: true,
    minAgeGap: 8,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'yenile',
        label: 'Yenisini taktır',
        resultText: 'Akşama kadar yeni kombi takıldı. Gece evin sıcaklığı '
            'ilk kez tek seferde oturdu.',
        money: -28000,
        happiness: 2,
      ),
      EventChoice(
        id: 'yamala',
        label: 'Yamayla idare et',
        resultText: 'Usta bir parça değiştirdi, kombi çalıştı. Fişi '
            'buzdolabının kapağına astın: "gelecek yıl bakılacak."',
        money: -7000,
        happiness: -1,
        addFlags: <String>{HomeFlags.kombiYamali},
      ),
    ],
  ),
  GameEvent(
    id: 'ev_mutfak_sizintisi',
    category: EventCategory.kisisel,
    text: 'Mutfak dolabının altı ıslak. Alt kattan da "tavanda leke var" '
        'diye haber geldi.',
    requirement: EventRequirement(minAge: 20, requiresOwnedResidence: true),
    repeatable: true,
    minAgeGap: 6,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'ikisini_birlikte',
        label: 'İkisini birlikte yaptır',
        resultText: 'Boruyu değiştirdin, alt katın tavanını da boyattın. '
            'Mesele aynı hafta kapandı.',
        money: -22000,
        happiness: 1,
      ),
      EventChoice(
        id: 'sadece_kendi',
        label: 'Önce kendi borunu yaptır',
        resultText: 'Boru değişti ama alt kat beklemede kaldı. '
            'Merdivende selamlaşma kısaldı.',
        money: -11000,
        happiness: -2,
      ),
    ],
  ),
  GameEvent(
    id: 'ev_tesisat_eskidi',
    category: EventCategory.kisisel,
    text: 'Elektrikli ısıtıcıyı çalıştırınca sigorta attı. Elektrikçi '
        'kabloların yaşını söyledi, sonra da "bu bina bu tesisatla ne '
        'kadar gider" diye ekledi.',
    requirement: EventRequirement(minAge: 22, requiresOwnedResidence: true),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'yenile',
        label: 'Tesisatı yenile',
        resultText: 'Duvarlar açıldı, kablolar değişti, iki gün toz '
            'içinde yaşadın. Sonunda bütün prizler aynı anda çalışıyor.',
        money: -65000,
        happiness: 1,
      ),
      EventChoice(
        id: 'simdilik_boyle',
        label: 'Şimdilik böyle kalsın',
        resultText: 'Sigortayı kaldırdın, ısıtıcıyı başka prize taktın. '
            'Ev idare ediyor.',
        money: -2000,
        addFlags: <String>{HomeFlags.tesisatEski},
      ),
    ],
  ),
  GameEvent(
    id: 'ev_cati_akiyor',
    category: EventCategory.kisisel,
    text: 'Çatı akıyor. Yönetim payına düşen tutarı yazdı: yapılırsa '
        'bu yaz, yapılmazsa gelecek kış daha pahalı.',
    requirement: EventRequirement(minAge: 24, requiresOwnedResidence: true),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'payini_ode',
        label: 'Payını hemen öde',
        resultText: 'Çatı ağustosta yenilendi. Kasım yağmurunda evin '
            'içinde hiçbir şey olmadı.',
        money: -30000,
        happiness: 1,
      ),
      EventChoice(
        id: 'ertele',
        label: 'Bu yıl olmaz, ertele',
        resultText: 'Çatı olduğu gibi kaldı. Kiremitlerin arası daha da '
            'açıldı.',
        happiness: -1,
        addFlags: <String>{HomeFlags.catiErtelendi},
      ),
    ],
  ),
  GameEvent(
    id: 'ev_pencereler_usutuyor',
    category: EventCategory.kisisel,
    text: 'Pencere kenarına elini götürünce soğuk hava çarpıyor. '
        'Faturalar da aynı şeyi söylüyor.',
    requirement: EventRequirement(minAge: 22, requiresOwnedResidence: true),
    repeatable: true,
    minAgeGap: 10,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'pencere_degistir',
        label: 'Pencereleri değiştir',
        resultText: 'Yeni pencereler takıldı. Sokağın gürültüsü de '
            'yarıya indi, bunu beklemiyordun.',
        money: -42000,
        happiness: 3,
      ),
      EventChoice(
        id: 'bant_perde',
        label: 'Bantla, kalın perde as',
        resultText: 'Bant ve perde işi gördü. Yine de sabahları '
            'kalorifere yakın oturuyorsun.',
        money: -3000,
        health: -1,
      ),
    ],
  ),
  GameEvent(
    id: 'ev_banyoda_kuf',
    category: EventCategory.kisisel,
    text: 'Banyonun köşesinde küf lekesi büyüyor. Havalandırma '
        'yetmiyor.',
    requirement: EventRequirement(minAge: 21, requiresOwnedResidence: true),
    repeatable: true,
    minAgeGap: 7,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'kokten_cozum',
        label: 'Havalandırmayı yaptır',
        resultText: 'Aspiratör takıldı, duvar yeniden yapıldı. Banyo '
            'artık duştan yarım saat sonra kuruyor.',
        money: -14000,
        health: 1,
      ),
      EventChoice(
        id: 'silip_gec',
        label: 'Sil, üstünü boya',
        resultText: 'Leke kapandı. İki ay sonra aynı köşede yeniden '
            'göründü.',
        money: -1500,
        health: -2,
      ),
    ],
  ),
  GameEvent(
    id: 'ev_boya_zamani',
    category: EventCategory.kisisel,
    text: 'Duvarlar soluk. Bir hafta izin alıp kendin yapmak da var, '
        'usta tutmak da.',
    requirement: EventRequirement(minAge: 22, requiresOwnedResidence: true),
    repeatable: true,
    minAgeGap: 9,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'usta_tut',
        label: 'Usta tut',
        resultText: 'İki günde bitti, hiçbir yere boya damlamadı. '
            'Eve girince insan bir an duruyor.',
        money: -35000,
        happiness: 2,
      ),
      EventChoice(
        id: 'kendin_boya',
        label: 'Kendin boya',
        resultText: 'Rulo, merdiven, bel ağrısı. Sonunda duvarlar '
            'bembeyaz ve "bunu ben yaptım" demek başka.',
        money: -9000,
        happiness: 3,
        health: -2,
      ),
    ],
  ),

  // ===================================================================
  // 2) Apartman: ev bir binanın içinde
  // ===================================================================
  GameEvent(
    id: 'ev_aidat_zammi_oylama',
    category: EventCategory.mahalle,
    text: 'Apartman toplantısında aidata zam konuşuluyor: giriş '
        'yenilenecek, bahçe düzenlenecek.',
    requirement: EventRequirement(minAge: 22, requiresOwnedResidence: true),
    repeatable: true,
    minAgeGap: 8,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'destek',
        label: 'Destekle',
        resultText: 'Zam geçti. Altı ay sonra giriş kapısı ve bahçe '
            'gerçekten değişti; binanın havası düzeldi.',
        money: -12000,
        happiness: 2,
      ),
      EventChoice(
        id: 'karsi_cik',
        label: 'Karşı çık',
        resultText: 'Teklif bu yıl düştü. Giriş aynı kaldı, aidat da '
            'aynı kaldı.',
        happiness: -1,
      ),
    ],
  ),
  GameEvent(
    id: 'ev_yonetici_arayisi',
    category: EventCategory.mahalle,
    text: 'Apartmanda yönetici arıyorlar. Kimse istemiyor, herkes '
        'birbirine bakıyor.',
    requirement: EventRequirement(minAge: 25, requiresOwnedResidence: true),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'ben_yapayim',
        label: 'Bir yıl ben yaparım',
        resultText: 'Defteri aldın. Yıl boyunca telefonun sustuğu gün '
            'olmadı ama bina ilk kez borcunu kapattı.',
        happiness: -1,
        charisma: 2,
      ),
      EventChoice(
        id: 'bu_yil_olmaz',
        label: 'Bu yıl bende olmaz',
        resultText: 'Görev başka daireye geçti. Toplantıdan erken '
            'çıktın.',
        happiness: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'ev_ust_kat_gurultusu',
    category: EventCategory.mahalle,
    text: 'Üst kat gece on ikide mobilya çekiyor. Üç gündür aynı saatte '
        'aynı ses.',
    requirement: EventRequirement(minAge: 21, requiresOwnedResidence: true),
    repeatable: true,
    minAgeGap: 5,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'kapiyi_cal',
        label: 'Çık, kapısını çal',
        resultText: 'Kapıyı açan adam şaşırdı, sonra özür diledi. '
            'Ertesi gece ses yok.',
        happiness: 2,
        charisma: 1,
      ),
      EventChoice(
        id: 'yonetime_yaz',
        label: 'Yönetime yaz',
        resultText: 'Panoya "saat 22.00\'den sonra sessizlik" notu '
            'asıldı. Ses azaldı ama merdivende kimse kimseye bakmıyor.',
        happiness: -1,
      ),
      EventChoice(
        id: 'kulak_tikaci',
        label: 'Kulak tıkacı al, uyu',
        resultText: 'Tıkaç işe yarıyor. Sabahları biraz daha yorgun '
            'kalkıyorsun.',
        money: -500,
        health: -1,
      ),
    ],
  ),
  GameEvent(
    id: 'ev_komsu_anahtari',
    category: EventCategory.mahalle,
    text: 'Yan daire tatilde. Apartman görevlisi aradı: "Sizin katta su '
        'var, onların kapısı kapalı, anahtarı sizde mi?"',
    requirement: EventRequirement(minAge: 23, requiresOwnedResidence: true),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'ilgilen',
        label: 'İşi üstlen, ustayı çağır',
        resultText: 'Vanayı kapattın, ustayı bekledin, akşamına kadar '
            'kapıda durdun. Dönüşlerinde ne yapacaklarını bilemediler.',
        happiness: 1,
        charisma: 1,
        addFlags: <String>{HomeFlags.komsuyaYardim},
      ),
      EventChoice(
        id: 'karismam',
        label: 'Benim dairem değil, karışmam',
        resultText: 'Telefonu kapattın. Su iki saat daha aktı, mesele '
            'yönetime kaldı.',
        happiness: -1,
      ),
    ],
  ),
  GameEvent(
    id: 'ev_otopark_yeri',
    category: EventCategory.mahalle,
    text: 'Apartmanın önündeki yer meselesi büyüdü: iki daire aynı '
        'noktaya park ediyor.',
    requirement: EventRequirement(
      minAge: 24,
      requiresOwnedResidence: true,
      requiredPossessionKinds: <ItemKind>{ItemKind.otomobil},
    ),
    repeatable: true,
    minAgeGap: 6,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'sira_onerisi',
        label: 'Sıra usulü öner',
        resultText: 'Haftalık sıra listesi panoya asıldı. Kimse memnun '
            'değil ama kimse de kavga etmiyor.',
        charisma: 1,
        happiness: 1,
      ),
      EventChoice(
        id: 'sokaga_cek',
        label: 'Arabanı sokağa çek',
        resultText: 'Arabayı sokağa çektin. Sabah buzunu kazımak '
            'alışkanlık oldu.',
        happiness: -1,
      ),
    ],
  ),

  // ===================================================================
  // 3) Yuva: evin içi
  // ===================================================================
  GameEvent(
    id: 'ev_ilk_kis',
    category: EventCategory.kisisel,
    text: 'Kendi evinde ilk kış. Kalorifer sesi, mutfaktan gelen koku, '
        'kapıyı arkandan kapatınca içeride kalan sessizlik.',
    requirement: EventRequirement(minAge: 20, requiresOwnedResidence: true),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'ev_davet',
        label: 'Eve davet ver',
        resultText: 'Mutfak küçük geldi, sandalye yetmedi, gece yarısına '
            'kadar oturuldu. Ev ilk kez kalabalık gördü.',
        money: -4000,
        happiness: 4,
        charisma: 1,
      ),
      EventChoice(
        id: 'kendi_basina',
        label: 'Tek başına otur, tadını çıkar',
        resultText: 'Işığı kısıp pencere kenarına oturdun. Aşağıda '
            'sokak lambası, içeride sadece senin sesin.',
        happiness: 3,
      ),
    ],
  ),
  GameEvent(
    id: 'ev_misafir_odasi',
    category: EventCategory.aile,
    text: 'Akrabalar şehre gelecek. "Otelde kalmayalım" diyorlar; '
        'evdeki oda da tam oda değil.',
    requirement: EventRequirement(minAge: 23, requiresOwnedResidence: true),
    repeatable: true,
    minAgeGap: 6,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'kalsinlar',
        label: 'Kalsınlar, hallederiz',
        resultText: 'Odayı boşalttın, çekyat açıldı. Beş gün ev kalabalık '
            'oldu; gidişlerinde ev bir tuhaf sessizleşti.',
        money: -6000,
        happiness: 2,
      ),
      EventChoice(
        id: 'otel_bak',
        label: 'Yakında otel bakalım',
        resultText: 'Otel buldun, bir gece parasını da sen verdin. '
            'Kimse bir şey demedi ama akşam yemeği kısa sürdü.',
        money: -9000,
        happiness: -1,
      ),
    ],
  ),
  GameEvent(
    id: 'ev_mutfak_yenileme',
    category: EventCategory.kisisel,
    text: 'Mutfak dolapları on yıl önceden kalma. Bir hesap yaptırdın, '
        'tutar belli: ciddi para.',
    requirement: EventRequirement(minAge: 26, requiresOwnedResidence: true),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'yenile',
        label: 'Mutfağı yenile',
        resultText: 'Üç hafta sonra mutfak değişti. Kahvaltı masası '
            'artık pencerenin önünde.',
        money: -220000,
        happiness: 5,
      ),
      EventChoice(
        id: 'kapak_degistir',
        label: 'Sadece kapakları değiştir',
        resultText: 'Kapaklar yenilendi, tezgâh eski kaldı. Uzaktan '
            'bakınca fark etmiyor.',
        money: -45000,
        happiness: 2,
      ),
    ],
  ),
  GameEvent(
    id: 'ev_balkon_karari',
    category: EventCategory.kisisel,
    text: 'Balkon şu an depo gibi: kutu, bisiklet, bir kırık sandalye.',
    requirement: EventRequirement(minAge: 22, requiresOwnedResidence: true),
    repeatable: true,
    minAgeGap: 8,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'oturma_yeri',
        label: 'Oturma yerine çevir',
        resultText: 'Kutular gitti, iki sandalye ve bir masa geldi. '
            'Yazın akşam yemekleri artık orada.',
        money: -8000,
        happiness: 3,
      ),
      EventChoice(
        id: 'duzenli_depo',
        label: 'Düzenli bir depo yap',
        resultText: 'Raf taktın, kutuları etiketledin. Ev içinde yer '
            'açıldı, balkon kapısı yine kapalı kaldı.',
        money: -4000,
        happiness: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'ev_bayram_temizligi',
    category: EventCategory.aile,
    text: 'Bayram yaklaşıyor, ev üstten aşağı temizlenecek. Tek başına '
        'iki gün sürer.',
    requirement: EventRequirement(minAge: 22, requiresOwnedResidence: true),
    repeatable: true,
    minAgeGap: 5,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'yardim_tut',
        label: 'Yardım tut',
        resultText: 'Bir günde bitti. Akşam yorgun değilsin, bu da bir '
            'lüks.',
        money: -5000,
        happiness: 2,
      ),
      EventChoice(
        id: 'kendin_yap',
        label: 'Kendin yap',
        resultText: 'Perdeler yıkandı, camlar silindi, sırtın ağrıdı. '
            'Ev bayram sabahı ışıl ışıl.',
        happiness: 2,
        health: -1,
      ),
    ],
  ),

  // ===================================================================
  // 4) Sahiplik kararları
  // ===================================================================
  GameEvent(
    id: 'ev_sigorta_teklifi',
    category: EventCategory.kisisel,
    text: 'Konut sigortası teklifi geldi: yangın, su basması, hırsızlık. '
        'Yıllık tutar belli, "bir şey olmazsa" diye bir cümle de var.',
    requirement: EventRequirement(minAge: 23, requiresOwnedResidence: true),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'yaptir',
        label: 'Sigortayı yaptır',
        resultText: 'Poliçe dosyaya girdi. Aklın bir parça rahat.',
        money: -9000,
        happiness: 1,
        addFlags: <String>{HomeFlags.evSigortali},
      ),
      EventChoice(
        id: 'gerek_yok',
        label: 'Şimdilik gerek yok',
        resultText: 'Teklifi kaldırdın. Zaten yıllardır bir şey '
            'olmamıştı.',
        happiness: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'ev_kapi_guvenligi',
    category: EventCategory.kisisel,
    text: 'Alt katın kapısıyla oynanmış. Polis geldi, apartman bir hafta '
        'bunu konuştu.',
    requirement: EventRequirement(minAge: 23, requiresOwnedResidence: true),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'kilit_yenile',
        label: 'Kilidi ve kapıyı güçlendir',
        resultText: 'Çelik kapı kaldı ama kilit göbeği ve menteşeler '
            'değişti. Kapı kapanınca sesi bile farklı.',
        money: -18000,
        happiness: 1,
        addFlags: <String>{HomeFlags.kapiGuclendi},
      ),
      EventChoice(
        id: 'zaten_saglam',
        label: 'Bizim kapı zaten sağlam',
        resultText: 'Hiçbir şey yapmadın. Birkaç gün kapıyı iki kez '
            'kontrol ettin, sonra alıştın; yine de akşam eve girerken '
            'o hafta aklına geldi.',
        happiness: -1,
      ),
    ],
  ),
  GameEvent(
    id: 'ev_yandaki_daire_satilik',
    category: EventCategory.kisisel,
    text: 'Yan daire satılık. Fiyat piyasanın altında; sahibi şehirden '
        'taşınıyor ve işi hızlı bitirmek istiyor.',
    requirement: EventRequirement(
      minAge: 28,
      requiresOwnedResidence: true,
      minNetWorth: 4000000,
    ),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'ilgilen',
        label: 'Ciddi ciddi hesap yap',
        resultText: 'Hesabı yaptın, bankayla konuştun. İş olmadı ama '
            'kafanda "ikinci daire" diye bir fikir açıldı.',
        happiness: 1,
        intelligence: 1,
      ),
      EventChoice(
        id: 'bana_gore_degil',
        label: 'Bana göre değil',
        resultText: 'Teklifi geçtin. Daire iki ay sonra senden yüksek '
            'bir fiyata satıldı.',
        happiness: -1,
      ),
    ],
  ),
  GameEvent(
    id: 'ev_kentsel_donusum',
    category: EventCategory.kisisel,
    text: 'Bina için dönüşüm konuşuluyor. Kat sahiplerinin bir kısmı '
        'istekli, bir kısmı "ben evimden çıkamam" diyor. Süreç yıllar '
        'alabilir, kararın ise şimdi isteniyor.',
    requirement: EventRequirement(minAge: 30, requiresOwnedResidence: true),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'katil',
        label: 'Karara katıl',
        resultText: 'İmzayı attın. Bir süre kira yardımıyla başka evde '
            'oturulacak, sonrası belli değil.',
        happiness: -1,
        addFlags: <String>{HomeFlags.donusumeGirdi},
      ),
      EventChoice(
        id: 'simdi_olmaz',
        label: 'Şimdi olmaz',
        resultText: 'Karşı çıktın. Toplantıdan sonra iki komşu seninle '
            'aynı tarafta olduğunu söyledi.',
        happiness: 1,
      ),
    ],
  ),

  // ===================================================================
  // 5) Karşılık olayları: bırakılan izler okunuyor
  // ===================================================================
  GameEvent(
    id: 'ev_yamali_kombi_dondu',
    category: EventCategory.kisisel,
    text: 'Yamalı kombi yine durdu. Bu kez usta tek cümle söyledi: '
        '"Geçen yıl değiştirseydiniz."',
    requirement: EventRequirement(
      minAge: 23,
      requiresOwnedResidence: true,
      requiredFlags: <String>{HomeFlags.kombiYamali},
      forbiddenFlags: <String>{HomeFlags.kombiKarsiligi},
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'artik_yenile',
        label: 'Artık yenisini al',
        resultText: 'Yeni kombi takıldı. Hesap yapınca iki yılın toplamı, '
            'ilk gün yenisini almaktan pahalıya geldi.',
        money: -31000,
        happiness: 1,
        addFlags: <String>{HomeFlags.kombiKarsiligi},
        removeFlags: <String>{HomeFlags.kombiYamali},
      ),
      EventChoice(
        id: 'bir_kis_daha',
        label: 'Bir kış daha idare et',
        resultText: 'Soba kuruldu, kombi köşede kaldı. Ev ısınıyor ama '
            'sabahları el yüz yıkamak başka bir iş.',
        money: -6000,
        health: -2,
        happiness: -2,
        addFlags: <String>{HomeFlags.kombiKarsiligi},
      ),
    ],
  ),
  GameEvent(
    id: 'ev_cati_bedeli',
    category: EventCategory.kisisel,
    text: 'Ertelenen çatı kışı çıkarmadı. Su en üst kattan başlayıp '
        'aşağı indi; masraf artık eski payın iki katı.',
    requirement: EventRequirement(
      minAge: 26,
      requiresOwnedResidence: true,
      requiredFlags: <String>{HomeFlags.catiErtelendi},
      forbiddenFlags: <String>{HomeFlags.catiKarsiligi},
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'simdi_ode',
        label: 'Payını öde, bitsin',
        resultText: 'Çatı yenilendi, tavanlar boyandı. Toplantıda kimse '
            '"geçen yıl" demedi ama herkes biliyordu.',
        money: -58000,
        happiness: -1,
        addFlags: <String>{HomeFlags.catiKarsiligi},
        removeFlags: <String>{HomeFlags.catiErtelendi},
      ),
      EventChoice(
        id: 'taksit_iste',
        label: 'Taksit iste',
        resultText: 'Yönetim üç taksit kabul etti. İlk taksit bu ay, '
            'tavan lekesi de yerinde duruyor.',
        money: -22000,
        happiness: -2,
        addFlags: <String>{HomeFlags.catiKarsiligi},
      ),
    ],
  ),
  GameEvent(
    id: 'ev_tesisat_kisa_devre',
    category: EventCategory.kisisel,
    text: 'Eski tesisat kendini hatırlattı: priz yandı, duvarda is '
        'lekesi var. Yangın çıkmadı, bu sefer.',
    requirement: EventRequirement(
      minAge: 26,
      requiresOwnedResidence: true,
      requiredFlags: <String>{HomeFlags.tesisatEski},
      forbiddenFlags: <String>{HomeFlags.tesisatKarsiligi},
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'hepsini_yenile',
        label: 'Bütün tesisatı yenile',
        resultText: 'İki gün elektriksiz kaldın, duvarlar yeniden '
            'kapatıldı. Artık ısıtıcı ile makine aynı anda çalışıyor.',
        money: -72000,
        happiness: 1,
        addFlags: <String>{HomeFlags.tesisatKarsiligi},
        removeFlags: <String>{HomeFlags.tesisatEski},
      ),
      EventChoice(
        id: 'o_prizi_kapat',
        label: 'O prizi kapat, devam et',
        resultText: 'Priz kapatıldı, üstüne dolap çekildi. Ev '
            'kullanılıyor ama akşamları koku siniyor.',
        money: -2500,
        health: -2,
        addFlags: <String>{HomeFlags.tesisatKarsiligi},
      ),
    ],
  ),
  GameEvent(
    id: 'ev_sigorta_ise_yaradi',
    category: EventCategory.kisisel,
    text: 'Üst kattan su bastı: parke şişti, duvar kabardı. Poliçeyi '
        'dosyadan çıkardın.',
    requirement: EventRequirement(
      minAge: 26,
      requiresOwnedResidence: true,
      requiredFlags: <String>{HomeFlags.evSigortali},
      forbiddenFlags: <String>{HomeFlags.sigortaKarsiligi},
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'dosya_ac',
        label: 'Hasar dosyası aç',
        resultText: 'Eksper geldi, dosya kabul edildi. Parke yenilendi, '
            'cebinden sadece muafiyet tutarı çıktı.',
        money: -4000,
        happiness: 3,
        addFlags: <String>{HomeFlags.sigortaKarsiligi},
      ),
      EventChoice(
        id: 'kendim_yapayim',
        label: 'Uğraşmayayım, kendim yapayım',
        resultText: 'Dosya açmadın, ustayı kendin çağırdın. Poliçe '
            'dururken ödediğin paraya akşam yine takıldın.',
        money: -26000,
        happiness: -2,
        addFlags: <String>{HomeFlags.sigortaKarsiligi},
      ),
    ],
  ),
  GameEvent(
    id: 'ev_kapi_isini_gordu',
    category: EventCategory.kisisel,
    text: 'Apartmanda gece iki daireye girilmeye çalışılmış. Senin '
        'kapının menteşelerinde iz var ama kapı açılmamış.',
    requirement: EventRequirement(
      minAge: 26,
      requiresOwnedResidence: true,
      requiredFlags: <String>{HomeFlags.kapiGuclendi},
      forbiddenFlags: <String>{HomeFlags.kapiKarsiligi},
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'komsulara_anlat',
        label: 'Komşulara kilidi anlat',
        resultText: 'İki daire aynı kilidi taktı, bir daire de kamera. '
            'Apartman o yıl ilk kez ortak bir iş yaptı.',
        happiness: 2,
        charisma: 1,
        addFlags: <String>{HomeFlags.kapiKarsiligi},
      ),
      EventChoice(
        id: 'sessiz_kal',
        label: 'Kimseye bir şey söyleme',
        resultText: 'Menteşeleri sıktırdın, konuyu kapattın. Yine de '
            'birkaç hafta her sesi dinledin.',
        money: -1500,
        happiness: 1,
        addFlags: <String>{HomeFlags.kapiKarsiligi},
      ),
    ],
  ),
  GameEvent(
    id: 'ev_komsu_iyiligi_dondu',
    category: EventCategory.mahalle,
    text: 'Tatilden döndüğünde kapının altında not var: "Su kesildi, '
        'çamaşırını içeri aldım, çiçekleri suladım. Zil çalarsın."',
    requirement: EventRequirement(
      minAge: 26,
      requiresOwnedResidence: true,
      requiredFlags: <String>{HomeFlags.komsuyaYardim},
      forbiddenFlags: <String>{HomeFlags.komsuKarsiligi},
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'zile_bas',
        label: 'Zile bas, teşekkür et',
        resultText: 'Çay içtiniz, bir saat oturdunuz. Artık aynı '
            'apartmanda iki kişi birbirinin anahtarını biliyor.',
        happiness: 3,
        charisma: 1,
        addFlags: <String>{HomeFlags.komsuKarsiligi},
      ),
      EventChoice(
        id: 'not_birak',
        label: 'Kapısına not bırak',
        resultText: 'Teşekkür notunu bıraktın. Karşılaştığınızda ikiniz '
            'de gülümsüyorsunuz, o kadar.',
        happiness: 1,
        addFlags: <String>{HomeFlags.komsuKarsiligi},
      ),
    ],
  ),
  GameEvent(
    id: 'ev_donusum_tamamlandi',
    category: EventCategory.kisisel,
    text: 'Dönüşüm bitti. Aynı adrese, yeni bir binaya taşınıyorsun; '
        'kapı numarası bile aynı.',
    requirement: EventRequirement(
      minAge: 33,
      requiresOwnedResidence: true,
      requiredFlags: <String>{HomeFlags.donusumeGirdi},
      forbiddenFlags: <String>{HomeFlags.donusumKarsiligi},
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'tasin',
        label: 'Taşın, yerleş',
        resultText: 'Yeni daire eskisinden ferah. İlk akşam boş odada '
            'oturup tavana baktın: bu bekleyişe değdi.',
        money: -20000,
        happiness: 5,
        addFlags: <String>{HomeFlags.donusumKarsiligi},
      ),
      EventChoice(
        id: 'eski_esyayla',
        label: 'Eski eşyalarla idare et',
        resultText: 'Eski koltuk, eski dolap, yeni duvarlar. Ev ferah '
            'ama içerisi hâlâ önceki daireden kalma.',
        money: -4000,
        happiness: 2,
        addFlags: <String>{HomeFlags.donusumKarsiligi},
      ),
    ],
  ),
];
