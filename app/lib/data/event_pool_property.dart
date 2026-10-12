/// Konut, kiracı ve ev sahibi olayları (D-163).
///
/// İki taraf var ve ikisi de ayrı kapıdan geçiyor:
///
/// * **Ev sahibi tarafı** (`requiresLetProperty`, `requiresVacantProperty`):
///   kiracının kirayı geciktirmesi, evin bozulması, apartman yöneticisi,
///   kiracının çıkması, boş kalan ev.
/// * **Kiracı tarafı** (`requiresTenant`): ev sahibinin zam istemesi,
///   tesisatın patlaması, depozito, evin satılacak olması.
///
/// İki taraf **zorla aynı motora sokulmadı**: kiracı tarafı oyuncunun
/// kendi hayatı, ev sahibi tarafı yatırımının hayatı. Ortak olan yalnızca
/// olay havuzu.
///
/// Dil `docs/WRITING_STYLE_TR.md`: doğal, kısa, yer yer esprili. Karaktere
/// göre değişiyor — genç kiracı rahat, yaşlı kiracı geleneksel, apartman
/// yöneticisi yarı samimi, emlakçı satışçı. **Her cümleye "abi/oğlum/aga"
/// basılmıyor**; sokak hissi tonda, tikte değil.
///
/// Hiçbir metin hukuki yol göstermiyor: "şunu yaparsan kiracıyı hemen
/// çıkarırsın" gibi bir cümle yok, tahliye ve icra anlatılmıyor.
///
/// Ağırlıklar ve tutarlar `prototypeOnly`'dir (Q-166).
library;

import 'insurance_catalog.dart';
import '../domain/models/game_event.dart';

const List<GameEvent> kPropertyEvents = <GameEvent>[
  // =====================================================================
  // Ev sahibi tarafı: kiracıyla ilişki
  // =====================================================================
  GameEvent(
    id: 'konut_kiraci_gecikme',
    category: EventCategory.kisisel,
    text: 'Kiracıdan mesaj geldi.\n\n'
        '"Abi bu ay biraz dağıldım. Birkaç gün idare eder misin?"',
    requirement: EventRequirement(minAge: 20, requiresLetProperty: true),
    repeatable: true,
    minAgeGap: 3,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'sure_ver',
        label: 'Süre ver',
        resultText: 'On gün sonra yattı. Bir daha da gecikmedi.',
        happiness: 2,
      ),
      EventChoice(
        id: 'bir_kismi',
        label: 'Bir kısmını şimdi iste',
        resultText: 'Yarısını o gün yatırdı, kalanı ay sonunda. '
            'İkisi de rahatladı sayılır.',
        money: 3000,
      ),
      EventChoice(
        id: 'yenilemem',
        label: 'Sözleşmeyi yenilemeyeceğini söyle',
        resultText: 'Sesi değişti. "Anladım abi" dedi, telefonu kapattı. '
            'Kalan süreyi sessiz geçirdiniz.',
        happiness: -3,
      ),
    ],
  ),
  GameEvent(
    id: 'konut_kiraci_duzenli',
    category: EventCategory.kisisel,
    text: 'Kira yine günü gününe yattı. Üç yıl oldu, bir kere bile '
        'aramadın.',
    requirement: EventRequirement(minAge: 22, requiresLetProperty: true),
    repeatable: true,
    minAgeGap: 5,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'ara',
        label: 'Bir ara, hâlini sor',
        resultText: 'Şaşırdı. "Bir sorun mu var abi?" dedi. '
            '"Yok" dedin, "sadece sordum." Gülüştünüz.',
        happiness: 4,
      ),
      EventChoice(
        id: 'karistirma',
        label: 'Karıştırma, iyi gidiyor',
        resultText: 'Doğru: bozulmayan şeye dokunmaya gerek yok.',
        happiness: 2,
      ),
    ],
  ),
  GameEvent(
    id: 'konut_kiraci_kucuk_masraf',
    category: EventCategory.kisisel,
    text: 'Kiracı aradı ama isteği yok.\n\n'
        '"Abi musluk damlıyordu, tamirciyi kendim çağırdım. '
        'Zaten ufak bir şeydi."',
    requirement: EventRequirement(minAge: 22, requiresLetProperty: true),
    repeatable: true,
    minAgeGap: 6,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'kiradan_dus',
        label: 'Parasını kiradan düş',
        resultText: 'Israr ettin. "Gerek yoktu" dedi ama kabul etti. '
            'Böyle kiracı zor bulunur.',
        money: -1500,
        happiness: 4,
      ),
      EventChoice(
        id: 'tesekkur',
        label: 'Teşekkür et, geç',
        resultText: 'Teşekkür ettin. Sonra aklına geldi: aslında parasını '
            'vermeliydin.',
        happiness: -1,
      ),
    ],
  ),
  GameEvent(
    id: 'konut_kiraci_evleniyor',
    category: EventCategory.kisisel,
    text: 'Kiracı haber verdi: evleniyor. Daha büyük bir yere bakıyorlar.',
    requirement: EventRequirement(minAge: 24, requiresLetProperty: true),
    repeatable: true,
    minAgeGap: 8,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'tebrik',
        label: 'Tebrik et',
        resultText: 'Düğüne davet etti. Gitmedin ama tebrik ettin, '
            'anahtarı gülerek teslim aldı.',
        happiness: 3,
      ),
      EventChoice(
        id: 'indirim_teklif',
        label: 'Kalması için kirayı biraz indir',
        resultText: 'Düşündüler ama olmadı: ev onlara küçük kalıyordu. '
            'Yine de teklifin hoşuna gitti.',
        happiness: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'konut_kiraci_cocuk',
    category: EventCategory.kisisel,
    text: 'Kiracının çocuğu olmuş. Apartmanın girişinde bebek arabası var.',
    requirement: EventRequirement(minAge: 24, requiresLetProperty: true),
    repeatable: true,
    minAgeGap: 9,
    weight: 2,
    choices: <EventChoice>[
      EventChoice(
        id: 'hayirli',
        label: 'Hayırlı olsun de',
        resultText: 'Kısa bir mesaj attın. Uzun uzun teşekkür etti.',
        happiness: 3,
      ),
      EventChoice(
        id: 'sessiz',
        label: 'Karışmadan geç',
        resultText: 'Senin işin ev, dedin. Yine de aklında kaldı.',
        happiness: -1,
      ),
    ],
  ),
  GameEvent(
    id: 'konut_kiraci_kotu_kullanim',
    category: EventCategory.kisisel,
    text: 'Kiracı çıktıktan sonra eve girdin.\n\n'
        'Duvarlar pek bıraktığın gibi değil.',
    requirement: EventRequirement(minAge: 24, requiresVacantProperty: true),
    repeatable: true,
    minAgeGap: 10,
    weight: 2,
    choices: <EventChoice>[
      EventChoice(
        id: 'boya',
        label: 'Boyacıyı çağır',
        resultText: 'İki günde toparlandı. Parası cebinden çıktı ama ev '
            'yeniden kiralanabilir hâlde.',
        money: -18000,
        happiness: -1,
      ),
      EventChoice(
        id: 'boyle_kirala',
        label: 'Böyle kiraya ver',
        resultText: 'Gelenlerin yüzü düştü. Sonunda istediğinden düşüğe '
            'anlaştın.',
        happiness: -3,
      ),
    ],
  ),

  // =====================================================================
  // Ev sahibi tarafı: evin kendisi
  // =====================================================================
  GameEvent(
    id: 'konut_su_borusu',
    category: EventCategory.kisisel,
    text: 'Kiracı aradı.\n\n'
        '"Abi mutfaktan su geliyor."\n\n'
        'Telefonu kapatınca insan ister istemez tavana bakıyor.',
    requirement: EventRequirement(minAge: 22, requiresLetProperty: true),
    repeatable: true,
    minAgeGap: 5,
    // Paket CA: ani hasar, konut poliçesinin kapsamında.
    insuredRisk: InsuranceKind.konut,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'tesisatci',
        label: 'Tesisatçıyı hemen yolla',
        resultText: 'Aynı gün geldi, boruyu değiştirdi. Alt komşuya iş '
            'düşmeden kapandı.',
        money: -9000,
        happiness: 1,
      ),
      EventChoice(
        id: 'beklet',
        label: 'Hafta sonunu bekle',
        resultText: 'Beklerken alt komşunun tavanı da lekelendi. '
            'Masraf ikiye katlandı.',
        money: -19000,
        happiness: -3,
      ),
    ],
  ),
  GameEvent(
    id: 'konut_kombi',
    category: EventCategory.kisisel,
    text: 'Kombi kışın ortasında teslim oldu. Kiracı üşüyor.',
    requirement: EventRequirement(minAge: 22, requiresLetProperty: true),
    repeatable: true,
    minAgeGap: 7,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'yeni_kombi',
        label: 'Yenisini al',
        resultText: 'Yeni kombi takıldı. Kiracı "sağ ol abi" dedi, '
            'ertesi ay kirayı bir gün önceden yatırdı.',
        money: -26000,
        happiness: 2,
      ),
      EventChoice(
        id: 'tamir_ettir',
        label: 'Tamir ettir, idare etsin',
        resultText: 'Usta bir şeyler yaptı, çalıştı. Mart\'ta yine bozuldu.',
        money: -6000,
        happiness: -1,
      ),
    ],
  ),
  GameEvent(
    id: 'konut_ust_komsu_su',
    category: EventCategory.kisisel,
    text: 'Üst komşudan su akmış. Kiracı fotoğraf atmış, tavanda leke var.',
    requirement: EventRequirement(minAge: 22, requiresLetProperty: true),
    repeatable: true,
    minAgeGap: 8,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'komsu_ile_konus',
        label: 'Üst komşuyla konuş',
        resultText: 'Adam kabul etti, masrafı paylaştınız. Uzamadı.',
        money: -4000,
        charisma: 2,
      ),
      EventChoice(
        id: 'kendin_yap',
        label: 'Uğraşmayayım, kendim yaptırayım',
        resultText: 'Tavanı boyattın. Komşu bir teşekkür bile etmedi.',
        money: -8000,
        happiness: -2,
      ),
    ],
  ),
  GameEvent(
    id: 'konut_yonetici_aradi',
    category: EventCategory.kisisel,
    text: 'Apartman yöneticisi aradı.\n\n'
        '"Abi 3 numaradan yine şikâyet var. Bir konuşsan iyi olur."',
    requirement: EventRequirement(minAge: 22, requiresLetProperty: true),
    repeatable: true,
    minAgeGap: 6,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'kiraciyi_ara',
        label: 'Kiracıyı ara, dinle',
        resultText: 'Meselenin çöp saatiyle ilgili olduğu çıktı. '
            'İki cümleyle kapandı.',
        charisma: 2,
        happiness: 1,
      ),
      EventChoice(
        id: 'benim_isim_degil',
        label: '"Aralarında çözsünler"',
        resultText: 'Çözmediler. Bir sonraki toplantıda konu senin '
            'daireye döndü.',
        happiness: -2,
      ),
    ],
  ),
  GameEvent(
    id: 'konut_aidat_zammi',
    category: EventCategory.kisisel,
    text: 'Apartman aidatı zamlandı. Yönetici "asansör bakımı" diyor, '
        'kimse itiraz edemiyor.',
    requirement: EventRequirement(minAge: 22, requiresVacantProperty: true),
    repeatable: true,
    minAgeGap: 7,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'ode',
        label: 'Öde, uzatma',
        resultText: 'Ödedin. Boş dairenin de aidatı çıkıyor, orası ayrı.',
        money: -5000,
      ),
      EventChoice(
        id: 'hesap_sor',
        label: 'Hesabını sor',
        resultText: 'Defteri istedin. Yönetici bozuldu ama iki kalem '
            'gerçekten fazlaydı.',
        money: -3000,
        charisma: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'konut_bos_kaliyor',
    category: EventCategory.kisisel,
    text: 'Daire üç aydır boş. İlan duruyor, telefon çalmıyor.',
    requirement: EventRequirement(minAge: 22, requiresVacantProperty: true),
    repeatable: true,
    minAgeGap: 5,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'fiyat_dusur',
        label: 'Rakamı biraz aşağı çek',
        resultText: 'İki gün sonra iki kişi aradı. Rakam inince telefon '
            'çalıyor, basit.',
        intelligence: 1,
      ),
      EventChoice(
        id: 'bekle',
        label: 'Bekle, düşürmem',
        resultText: 'Bekledin. Daire boş kaldı, aidat ise her ay çıktı.',
        money: -6000,
        happiness: -2,
      ),
    ],
  ),
  GameEvent(
    id: 'konut_cok_basvuru',
    category: EventCategory.kisisel,
    text: 'Kira piyasanın altında kalmış. Telefon susmuyor, on kişi '
        'daireyi görmek istiyor.',
    requirement: EventRequirement(minAge: 22, requiresVacantProperty: true),
    repeatable: true,
    minAgeGap: 7,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'secici_ol',
        label: 'Acele etme, seçici ol',
        resultText: 'Beş kişiyi gezdirdin. Aralarından düzgün birini '
            'seçmek kolay oldu.',
        intelligence: 1,
        happiness: 2,
      ),
      EventChoice(
        id: 'ilk_gelene',
        label: 'İlk gelene ver, uğraşmayayım',
        resultText: 'Hızlı oldu. İyi mi kötü mü, birkaç yıl sonra '
            'anlaşılacak.',
        happiness: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'konut_boya_masrafi',
    category: EventCategory.kisisel,
    text: 'Yeni kiracı gelmeden daireyi bir elden geçirmek lazım. '
        'Boya, priz, bir de mutfak dolabının kapağı.',
    requirement: EventRequirement(minAge: 22, requiresVacantProperty: true),
    repeatable: true,
    minAgeGap: 6,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'hepsini_yap',
        label: 'Hepsini yaptır',
        resultText: 'Daire pırıl pırıl oldu. Gelenler girer girmez '
            '"tamam" dedi.',
        money: -22000,
        happiness: 2,
      ),
      EventChoice(
        id: 'sadece_boya',
        label: 'Sadece boya yeter',
        resultText: 'Boya yetti sayılır. Dolabın kapağı ilk kiracıda '
            'tamamen koptu.',
        money: -9000,
      ),
    ],
  ),
  GameEvent(
    id: 'konut_emlakci_teklifi',
    category: EventCategory.kisisel,
    text: 'Emlakçı aradı, sesi fazla neşeli.\n\n'
        '"Beyefendi tam sizin daireyi arayan bir müşterim var, '
        'bugün bağlayalım mı?"',
    requirement: EventRequirement(minAge: 24, requiresVacantProperty: true),
    repeatable: true,
    minAgeGap: 8,
    weight: 2,
    choices: <EventChoice>[
      EventChoice(
        id: 'bir_gorusem',
        label: 'Bir görüşeyim',
        resultText: 'Müşteri gerçekti ama teklif düşüktü. Emlakçının '
            '"tam sizin daire" dediği şey buydu.',
        intelligence: 1,
      ),
      EventChoice(
        id: 'tesekkur_gec',
        label: 'Teşekkür et, kapat',
        resultText: 'Kapattın. İki gün sonra yine aradı, aynı cümleyle.',
        happiness: -1,
      ),
    ],
  ),
  GameEvent(
    id: 'konut_yillardir_oturan',
    category: EventCategory.kisisel,
    text: 'Kiracı beş yılı doldurdu. Kira piyasanın epey altında kaldı '
        'ama adam hiç sorun çıkarmadı.',
    requirement: EventRequirement(minAge: 28, requiresLetProperty: true),
    repeatable: true,
    minAgeGap: 9,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'makul_zam',
        label: 'Oturup konuş, makul bir rakamda anlaş',
        resultText: 'Yüz yüze konuştunuz. Ortada bir sayıda anlaştınız, '
            'ikisi de rahat.',
        charisma: 2,
        happiness: 3,
      ),
      EventChoice(
        id: 'dokunma',
        label: 'Dokunma, böyle devam',
        resultText: 'Kira aynı kaldı. Kaybettiğin para var ama uykun '
            'düzgün.',
        happiness: 2,
      ),
    ],
  ),
  GameEvent(
    id: 'konut_yasli_kiraci',
    category: EventCategory.kisisel,
    text: 'Kiracı yaşlı bir amca. Kirayı elden vermek istiyor, '
        '"banka işlerine aklım ermiyor" diyor.',
    requirement: EventRequirement(minAge: 26, requiresLetProperty: true),
    repeatable: true,
    minAgeGap: 10,
    weight: 2,
    choices: <EventChoice>[
      EventChoice(
        id: 'ugra',
        label: 'Ayda bir uğra, elden al',
        resultText: 'Her ay bir çay içiyorsun. Kira hiç gecikmiyor, '
            'sohbet uzuyor.',
        happiness: 4,
      ),
      EventChoice(
        id: 'ogret',
        label: 'Bankayı göster, öğret',
        resultText: 'Yarım saat uğraştınız. Üçüncü ay kendi yatırdı, '
            'telefonda sesi gururluydu.',
        happiness: 3,
        charisma: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'konut_genc_kiraci',
    category: EventCategory.kisisel,
    text: 'Kiracı yeni mezun, mesaj atıyor:\n\n'
        '"Selam, wifi modemi bizde mi kalıyor yoksa sizde miydi?"',
    requirement: EventRequirement(minAge: 24, requiresLetProperty: true),
    repeatable: true,
    minAgeGap: 9,
    weight: 2,
    choices: <EventChoice>[
      EventChoice(
        id: 'sende_kalsin',
        label: '"Sende kalsın"',
        resultText: 'Kısa cevap verdin. Bir daha da ufak şeyler için '
            'aramadı.',
        happiness: 1,
      ),
      EventChoice(
        id: 'hepsini_yaz',
        label: 'Evdeki her şeyin listesini yaz, gönder',
        resultText: 'Liste uzun oldu ama iki taraf da rahat: çıkışta '
            'tartışılacak bir şey kalmadı.',
        intelligence: 2,
      ),
    ],
  ),
  GameEvent(
    id: 'konut_depozito_tartismasi',
    category: EventCategory.kisisel,
    text: 'Kiracı çıkıyor. Depozito konusunda anlaşamıyorsunuz: '
        'sen "kapı çizilmiş" diyorsun, o "öyle teslim aldım" diyor.',
    requirement: EventRequirement(minAge: 24, requiresLetProperty: true),
    repeatable: true,
    minAgeGap: 8,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'ortada_bulus',
        label: 'Ortada buluş',
        resultText: 'Yarısında anlaştınız. İkisi de tam istediğini '
            'alamadı, ikisi de rahatladı.',
        charisma: 1,
      ),
      EventChoice(
        id: 'tamamini_kes',
        label: 'Tamamını kes',
        resultText: 'Kestin. Adam bir daha selam vermedi; apartmanda '
            'konu bir süre konuşuldu.',
        money: 6000,
        happiness: -3,
      ),
    ],
  ),
  GameEvent(
    id: 'konut_tadilat_karari',
    category: EventCategory.kisisel,
    text: 'Daire yaşlanmış. Tadilat yaptırsan hem kira artar hem değer, '
        'ama önce cepten çıkacak.',
    requirement: EventRequirement(minAge: 26, requiresVacantProperty: true),
    repeatable: true,
    minAgeGap: 10,
    weight: 2,
    choices: <EventChoice>[
      EventChoice(
        id: 'hesapla',
        label: 'Kâğıt kalemle hesapla',
        resultText: 'Kaç yılda geri döneceğini gördün. Karar vermek '
            'kolaylaştı.',
        intelligence: 2,
      ),
      EventChoice(
        id: 'sonraya',
        label: 'Sonraya bıraksın',
        resultText: 'Erteledin. Gelen kiracılar hep aynı şeyi söyledi: '
            '"mutfak biraz eski."',
        happiness: -1,
      ),
    ],
  ),
  GameEvent(
    id: 'konut_vergi_yazisi',
    category: EventCategory.kisisel,
    text: 'Posta kutusunda resmî bir yazı: emlakla ilgili bir bildirim. '
        'İnsanın içi bir hoş oluyor.',
    requirement: EventRequirement(minAge: 24, requiresVacantProperty: true),
    repeatable: true,
    minAgeGap: 9,
    weight: 2,
    choices: <EventChoice>[
      EventChoice(
        id: 'hemen_bak',
        label: 'Hemen aç, oku',
        resultText: 'Rutin bir yazıydı. Gereğini yaptın, kapandı.',
        money: -3500,
        intelligence: 1,
      ),
      EventChoice(
        id: 'kenara_koy',
        label: 'Kenara koy, sonra',
        resultText: 'İki ay kenarda kaldı. Gecikme farkıyla birlikte '
            'ödedin.',
        money: -5200,
        happiness: -1,
      ),
    ],
  ),
  GameEvent(
    id: 'konut_ikinci_ev_hayali',
    category: EventCategory.kisisel,
    text: 'Bir kiracın var, kira düzenli geliyor. Aklına şu giriyor: '
        '"bir tane daha alsam?"',
    requirement: EventRequirement(minAge: 26, requiresLetProperty: true),
    repeatable: true,
    minAgeGap: 9,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'hesabini_yap',
        label: 'Önce bu evin hesabını çıkar',
        resultText: 'Kira, aidat, boş kalan aylar, bakım… Rakam '
            'düşündüğünden düşük çıktı. Yine de fena değil.',
        intelligence: 2,
      ),
      EventChoice(
        id: 'hayal_kur',
        label: 'Hayalini kurmakla yetin',
        resultText: 'Akşam boyunca ilan karıştırdın. Hiçbirini aramadın.',
        happiness: 2,
      ),
    ],
  ),

  // =====================================================================
  // Kiracı tarafı: oyuncunun kendi hayatı
  // =====================================================================
  GameEvent(
    id: 'konut_ev_sahibi_zam',
    category: EventCategory.kisisel,
    text: 'Ev sahibi aradı. Uzun uzun hâl hatır sordu, sonra konuya geldi: '
        'kira artışı.',
    requirement: EventRequirement(minAge: 20, requiresTenant: true),
    repeatable: true,
    minAgeGap: 4,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'pazarlik',
        label: 'Pazarlık et',
        resultText: 'Biraz aşağı çektin. "Sen de haklısın" dedi, '
            'ortada anlaştınız.',
        charisma: 2,
        happiness: 1,
      ),
      EventChoice(
        id: 'kabul',
        label: 'Kabul et',
        resultText: 'Kabul ettin. Taşınmanın masrafı zaten daha çok '
            'tutuyordu.',
        money: -8000,
      ),
      EventChoice(
        id: 'ev_ara',
        label: 'Yeni ev aramaya başla',
        resultText: 'İki hafta ilan karıştırdın. Gördüklerin yanında '
            'buradaki kira makul geldi.',
        happiness: -2,
        intelligence: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'konut_kiracidayken_tesisat',
    category: EventCategory.kisisel,
    text: 'Banyoda gider tıkandı. Ev sahibine haber verdin, '
        '"bakarım" dedi ve üç gün geçti.',
    requirement: EventRequirement(minAge: 20, requiresTenant: true),
    repeatable: true,
    minAgeGap: 6,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'kendin_cagir',
        label: 'Kendin tamirci çağır',
        resultText: 'Yarım saatte açıldı. Parasını ev sahibinden almak '
            'ayrı bir mesele oldu.',
        money: -2500,
        happiness: 1,
      ),
      EventChoice(
        id: 'israr',
        label: 'Israrla ara',
        resultText: 'Dördüncü gün geldi. "Bu kadar acele etmeye ne '
            'gerek var" dedi.',
        happiness: -2,
      ),
    ],
  ),
  GameEvent(
    id: 'konut_komsu_sikayet',
    category: EventCategory.kisisel,
    text: 'Kapı çaldı, alt komşu. Akşam sesin fazla geldiğini söylüyor. '
        'Ses senden değildi ama tartışacak hâlin yok.',
    requirement: EventRequirement(minAge: 18, requiresTenant: true),
    repeatable: true,
    minAgeGap: 6,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'ozur',
        label: 'Özür dile, kapat',
        resultText: 'Kapandı. Ertesi hafta aynı ses yine geldi, '
            'yine senin kapı çaldı.',
        happiness: -1,
      ),
      EventChoice(
        id: 'benden_degil',
        label: '"Ses benden değil"',
        resultText: 'Beraber dinlediniz: ses üst kattan geliyordu. '
            'Komşu mahcup oldu, sonra iyi anlaştınız.',
        charisma: 2,
      ),
    ],
  ),
  GameEvent(
    id: 'konut_ev_sahibi_satiyor',
    category: EventCategory.kisisel,
    text: 'Ev sahibi söyledi: daireyi satmak istiyor. '
        '"Sen rahat ol" diyor ama insan rahat olamıyor.',
    requirement: EventRequirement(minAge: 20, requiresTenant: true),
    repeatable: true,
    minAgeGap: 8,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'ev_bak',
        label: 'Şimdiden ev bakmaya başla',
        resultText: 'Hazırlıklı olmak iyi geldi. Satış gerçekleşince '
            'panik yaşamadın.',
        intelligence: 1,
        happiness: -1,
      ),
      EventChoice(
        id: 'ben_alsam',
        label: '"Ben alabilir miyim?" diye sor',
        resultText: 'Rakamı söyledi. Şu an cebin yetmiyor ama kafanda '
            'bir hesap açıldı.',
        happiness: 2,
      ),
    ],
  ),
  GameEvent(
    id: 'konut_depozito_geri',
    category: EventCategory.kisisel,
    text: 'Taşınıyorsun. Ev sahibi depozitoyu "bir bakalım" diye '
        'bekletiyor.',
    requirement: EventRequirement(minAge: 20, requiresTenant: true),
    repeatable: true,
    minAgeGap: 8,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'fotograf',
        label: 'Taşınırken çektiğin fotoğrafları göster',
        resultText: 'Fotoğraflar işe yaradı. Aynı gün yatırdı.',
        money: 12000,
        intelligence: 2,
      ),
      EventChoice(
        id: 'bekle_gor',
        label: 'Bekle, halleder',
        resultText: 'İki ay sürdü, eksik yattı. Uğraşmak istemedin.',
        money: 6000,
        happiness: -2,
      ),
    ],
  ),
  GameEvent(
    id: 'konut_tasinma_gunu',
    category: EventCategory.kisisel,
    text: 'Taşınma günü. Nakliyeci "asansör yok muydu abi?" diyor, '
        'sen de "yok" diyorsun. Fiyat orada değişiyor.',
    requirement: EventRequirement(minAge: 20, requiresTenant: true),
    repeatable: true,
    minAgeGap: 7,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'kabul_et',
        label: 'Kabul et, bitsin',
        resultText: 'Akşama kadar bitti. Sırtın ağrımadı, cebin ağrıdı.',
        money: -7000,
      ),
      EventChoice(
        id: 'arkadas_cagir',
        label: 'Arkadaşları çağır',
        resultText: 'Üç kişi geldi, akşam pizza söylediniz. Dolap bir '
            'yerinden çizildi ama olsun.',
        money: -1500,
        happiness: 3,
      ),
    ],
  ),
  GameEvent(
    id: 'konut_ev_sahibi_iyi',
    category: EventCategory.kisisel,
    text: 'Ev sahibi arayıp sordu: "Bir eksik var mı, kışa girerken?" '
        'Böylesi az bulunur.',
    requirement: EventRequirement(minAge: 20, requiresTenant: true),
    repeatable: true,
    minAgeGap: 9,
    weight: 2,
    choices: <EventChoice>[
      EventChoice(
        id: 'soyle',
        label: 'Eksikleri söyle',
        resultText: 'Pencerenin contasını değiştirdi. Ev bu kış çok daha '
            'sıcak.',
        happiness: 4,
      ),
      EventChoice(
        id: 'yok_de',
        label: '"Yok, her şey iyi"',
        resultText: 'Demeye demedin ama contayı kendin yaptın.',
        money: -900,
        happiness: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'konut_aidat_kiracida',
    category: EventCategory.kisisel,
    text: 'Yönetici kapıya not bırakmış: aidat iki ay birikmiş. '
        'Halbuki sen ödediğini biliyorsun.',
    requirement: EventRequirement(minAge: 20, requiresTenant: true),
    repeatable: true,
    minAgeGap: 8,
    weight: 2,
    choices: <EventChoice>[
      EventChoice(
        id: 'makbuz',
        label: 'Makbuzları çıkar, göster',
        resultText: 'Hata yöneticinin defterindeydi. "Kusura bakma abi" '
            'dedi.',
        intelligence: 1,
        happiness: 1,
      ),
      EventChoice(
        id: 'tekrar_ode',
        label: 'Uğraşmayayım, tekrar öde',
        resultText: 'Ödedin. Sonra makbuzu buldun; içine oturdu.',
        money: -2800,
        happiness: -2,
      ),
    ],
  ),
];
