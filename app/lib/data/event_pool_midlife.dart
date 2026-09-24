/// Orta yetişkinlik olayları: yaklaşık 28-58 yaş (Paket 20).
///
/// **Neden bu dosya var:** Ölçüm, 30-49 yaş arasında bir yılda ortalama
/// yalnızca **1-2** uygun olay bulunduğunu gösterdi; üstelik çoğu daha
/// önce görülmüştü. Hayatın en uzun bölümü içerik olarak boştu ve aynı
/// birkaç olay tekrar tekrar çıkıyordu. Ağırlık ayarı bunu çözmedi,
/// çünkü sorun ağırlık değil **seçenek yokluğuydu**.
///
/// Bu dosyadaki olayların çoğu **koşulsuzdur**: eş, çocuk, iş veya eşya
/// gerektirmez. Böylece nasıl bir hayat yaşanırsa yaşansın bu yıllar dolu
/// geçer. Para tutarları ve etkiler `prototypeOnly`'dir (Q-088).
library;

import '../domain/models/game_event.dart';

/// Orta yaş izleri.
abstract final class MidlifeFlags {
  static const String biriktirdi = 'orta_biriktirdi';
  static const String harcadi = 'orta_harcadi';
  static const String borcVerdi = 'orta_borc_verdi';
  static const String saglikErteledi = 'orta_saglik_erteledi';
  static const String yeniUgras = 'orta_yeni_ugras';
  static const String gonulluOldu = 'orta_gonullu';
}

const List<GameEvent> kMidlifeEvents = <GameEvent>[
  GameEvent(
    id: 'orta_kira_zammi',
    category: EventCategory.yetiskinlik,
    text:
        'Ev sahibi aradı. "Bu sene biraz ayarlama yapmamız lazım" '
        'dedi ve bir rakam söyledi. Telefonu kapattıktan sonra bir süre '
        'ekrana baktın.',
    // Faho'nun bildirdiği hata: bu olay kendi evinde oturan oyuncuya da
    // çıkıyordu. Ev sahibi olayı yalnızca kiracıya çıkar.
    requirement: EventRequirement(
      minAge: 26,
      maxAge: 58,
      requiresTenant: true,
    ),
    repeatable: true,
    minAgeGap: 6,
    weight: 8,
    choices: <EventChoice>[
      EventChoice(
        id: 'pazarlik',
        label: 'Pazarlık etmeyi dene',
        resultText:
            'Uzun uzun konuştunuz. Rakam biraz indi; ev sahibinin '
            'sesindeki soğukluk inmedi.',
        money: -9000,
        happiness: -1,
        charisma: 2,
      ),
      EventChoice(
        id: 'kabul',
        label: 'İtiraz etme, kabul et',
        resultText:
            'Kabul ettin. O ay sonunda hesap biraz daha zor '
            'kapandı ama tartışma da olmadı.',
        money: -18000,
        happiness: -2,
      ),
      EventChoice(
        id: 'tasinmayi_dusun',
        label: 'Taşınmayı düşünmeye başla',
        resultText:
            'O akşam ilanlara baktın. Hiçbirine gitmedin ama '
            'buranın sonsuza kadar sürmeyeceğini ilk kez düşündün.',
        happiness: -3,
        intelligence: 1,
      ),
    ],
  ),

  GameEvent(
    id: 'orta_borc_isteyen_tanidik',
    category: EventCategory.mahalle,
    text:
        'Yıllardır görüşmediğin biri aradı. Hâl hatır faslı kısa sürdü, '
        'sonra sesi değişti: bir miktar paraya ihtiyacı varmış.',
    requirement: EventRequirement(minAge: 24, maxAge: 60),
    repeatable: true,
    minAgeGap: 8,
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'ver',
        label: 'İstediği kadarını ver',
        resultText:
            'Parayı gönderdin. "Bir ay içinde" dedi. Bir ay '
            'geçti, iki ay geçti.',
        money: -24000,
        happiness: -1,
        addFlags: <String>{MidlifeFlags.borcVerdi},
      ),
      EventChoice(
        id: 'az_ver',
        label: 'Elinden geldiği kadarını ver',
        resultText:
            'Azını verdin ve sebebini açıkça söyledin. '
            'Teşekkür etti; ikiniz de rahatladınız.',
        money: -8000,
        happiness: 1,
        charisma: 1,
      ),
      EventChoice(
        id: 'veremem',
        label: 'Veremeyeceğini söyle',
        resultText:
            '"Kusura bakma" demek sandığından zor oldu. '
            'Telefondan sonra bir süre camdan dışarı baktın.',
        happiness: -3,
      ),
    ],
  ),

  GameEvent(
    id: 'orta_beklenmedik_masraf',
    category: EventCategory.yetiskinlik,
    text:
        'Kombi sabaha karşı sustu. Usta öğleden sonra geldi, baktı, '
        'kaşlarını kaldırdı ve bir rakam söyledi.',
    requirement: EventRequirement(minAge: 25, maxAge: 70),
    repeatable: true,
    minAgeGap: 7,
    weight: 7,
    choices: <EventChoice>[
      EventChoice(
        id: 'yaptir',
        label: 'Hemen yaptır',
        resultText: 'Akşama sıcak su vardı. Hesap da o kadar sıcaktı.',
        money: -21000,
        happiness: 1,
      ),
      EventChoice(
        id: 'idare',
        label: 'Bu kış idare etmeye çalış',
        resultText:
            'Battaniye ve elektrikli ısıtıcı. İdare etti, '
            'ama her sabah biraz daha zor kalkıldı.',
        money: -4500,
        health: -3,
        happiness: -2,
      ),
    ],
  ),

  GameEvent(
    id: 'orta_birikim_karari',
    category: EventCategory.yetiskinlik,
    text:
        'Bu ay beklediğinden fazlası kaldı. Küçük bir tutar ama '
        'hesapta duruyor ve ne yapacağını sen seçeceksin.',
    requirement: EventRequirement(minAge: 24, maxAge: 60),
    repeatable: true,
    minAgeGap: 6,
    weight: 7,
    choices: <EventChoice>[
      EventChoice(
        id: 'biriktir',
        label: 'Dokunma, biriksin',
        resultText:
            'Hesaptan çıkarmadın. Rakam küçük ama ilk kez '
            '"birikimim var" diyebildin.',
        happiness: -1,
        addFlags: <String>{MidlifeFlags.biriktirdi},
      ),
      EventChoice(
        id: 'kendine_harca',
        label: 'Kendine bir şey al',
        resultText:
            'Uzun zamandır istediğin şeyi aldın. Eve dönerken '
            'poşeti boşuna iki kez elini değiştirdin.',
        money: -12000,
        happiness: 6,
        addFlags: <String>{MidlifeFlags.harcadi},
      ),
      EventChoice(
        id: 'eve_harca',
        label: 'Evin eksiklerine harca',
        resultText:
            'Eksik olan şeyleri tamamladın. Kimse fark etmedi '
            'ama ev biraz daha ev oldu.',
        money: -9000,
        happiness: 3,
      ),
    ],
  ),

  // Önceki kararı hatırlar: yalnızca biriktiren oyuncuda çıkar.
  GameEvent(
    id: 'orta_birikimin_karsiligi',
    category: EventCategory.yetiskinlik,
    text:
        'Yıllardır dokunmadığın hesaba baktın. Rakam, her ay bir '
        'kenara koyduğun küçük tutarların toplamından ibaret — ama '
        'artık küçük değil.',
    requirement: EventRequirement(
      minAge: 34,
      maxAge: 62,
      requiredFlags: <String>{MidlifeFlags.biriktirdi},
    ),
    weight: 9,
    choices: <EventChoice>[
      EventChoice(
        id: 'dokunma',
        label: 'Hâlâ dokunma',
        resultText:
            'Ekranı kapattın. Bir gün lazım olacak; o gün '
            'geldiğinde hazır olacaksın.',
        happiness: 4,
        money: 45000,
      ),
      EventChoice(
        id: 'bir_kismini_kullan',
        label: 'Bir kısmını kullan',
        resultText:
            'Yıllardır ertelediğin şeyi yaptın. Para azaldı, '
            'aklındaki liste de.',
        money: 18000,
        happiness: 9,
      ),
    ],
  ),

  GameEvent(
    id: 'orta_sinif_bulusmasi',
    category: EventCategory.kisisel,
    text:
        'Bir grup mesajı: eski sınıf arkadaşların buluşuyor. Listede '
        'hatırladığın isimler de var, hiç tanımadığın isimler de.',
    requirement: EventRequirement(minAge: 30, maxAge: 55),
    repeatable: true,
    minAgeGap: 12,
    weight: 7,
    choices: <EventChoice>[
      EventChoice(
        id: 'git',
        label: 'Git',
        resultText:
            'Herkes değişmişti ama masaya oturulunca sesler '
            'aynıydı. Gece yarısı çıkarken yüzün ağrıyordu.',
        happiness: 7,
        charisma: 2,
      ),
      EventChoice(
        id: 'gitme',
        label: 'Gitme',
        resultText:
            'O akşam evde kaldın. Ertesi gün fotoğrafları '
            'gördün ve bir süre baktın.',
        happiness: -2,
      ),
    ],
  ),

  GameEvent(
    id: 'orta_uyku_kacan_gece',
    category: EventCategory.kisisel,
    text:
        'Saat üç. Uyku yok, sebep de belli değil. Tavanda hiçbir şey '
        'yazmıyor ama bakmaya devam ediyorsun.',
    requirement: EventRequirement(minAge: 28, maxAge: 62),
    repeatable: true,
    minAgeGap: 6,
    weight: 8,
    choices: <EventChoice>[
      EventChoice(
        id: 'kalk',
        label: 'Kalk, bir şeyler yap',
        resultText:
            'Mutfakta ışığı yakmadan su içtin. Dördü geçe '
            'uyumuşsun; sabah zor oldu ama kafan boşalmıştı.',
        health: -2,
        happiness: 2,
      ),
      EventChoice(
        id: 'liste_yap',
        label: 'Aklındakileri yaz',
        resultText:
            'Telefona madde madde yazdın. Sabah baktığında '
            'çoğu o kadar da büyük değildi.',
        happiness: 4,
        intelligence: 1,
      ),
      EventChoice(
        id: 'zorla_uyu',
        label: 'Gözlerini kapat ve bekle',
        resultText:
            'Beş buçukta uyudun, yedide kalktın. Gün boyunca '
            'kimse fark etmedi.',
        health: -3,
        happiness: -1,
      ),
    ],
  ),

  GameEvent(
    id: 'orta_ayna_ve_yillar',
    category: EventCategory.kisisel,
    text:
        'Sabah aynada, daha önce orada olmayan bir şey gördün. '
        'Yaklaşıp baktın, sonra geri çekildin.',
    requirement: EventRequirement(minAge: 33, maxAge: 58),
    repeatable: true,
    minAgeGap: 10,
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'gulumse',
        label: 'Gülümse ve geç',
        resultText: 'Omuz silktin. Zaten hep buraya gidiyordu.',
        happiness: 4,
      ),
      EventChoice(
        id: 'bakim',
        label: 'Kendine biraz daha bak',
        resultText:
            'O haftadan itibaren daha düzenli oldun. Ayna '
            'değişmedi ama sen değiştin.',
        appearance: 4,
        health: 2,
        money: -6000,
      ),
      EventChoice(
        id: 'takil',
        label: 'Gün boyu aklından çıkarma',
        resultText: 'Bütün gün camlara bakarken kendini yakaladın.',
        happiness: -4,
      ),
    ],
  ),

  GameEvent(
    id: 'orta_kirk_yas_kararlari',
    category: EventCategory.kisisel,
    text:
        'Merdivenleri çıkarken durdun. Eskiden durmuyordun. Aklından '
        '"artık bir şey yapsam mı" cümlesi geçti.',
    requirement: EventRequirement(minAge: 36, maxAge: 56),
    weight: 8,
    choices: <EventChoice>[
      EventChoice(
        id: 'basla',
        label: 'Yarından itibaren başla',
        resultText:
            'İlk hafta her yerin ağrıdı. Üçüncü hafta '
            'merdivenlerde durmadın.',
        health: 7,
        appearance: 3,
        happiness: 2,
      ),
      EventChoice(
        id: 'sonra',
        label: 'Sonra, daha uygun bir zamanda',
        resultText: '"Daha uygun zaman" o yıl bir daha gelmedi.',
        health: -2,
      ),
    ],
  ),

  GameEvent(
    id: 'orta_yeni_bir_sey',
    category: EventCategory.kisisel,
    text:
        'Camında ilan: akşam kursu. Yıllardır merak ettiğin ama hiç '
        'başlamadığın şey.',
    requirement: EventRequirement(
      minAge: 30,
      maxAge: 58,
      forbiddenFlags: <String>{MidlifeFlags.yeniUgras},
    ),
    weight: 7,
    choices: <EventChoice>[
      EventChoice(
        id: 'yazil',
        label: 'Yazıl',
        resultText:
            'İlk derste en acemi sendin ve kimse umursamadı. '
            'Haftada bir akşamın artık bir adı var.',
        money: -11000,
        happiness: 8,
        intelligence: 2,
        charisma: 1,
        addFlags: <String>{MidlifeFlags.yeniUgras},
      ),
      EventChoice(
        id: 'gec',
        label: 'Bu yaştan sonra olmaz',
        resultText:
            'İlanın önünden birkaç kez daha geçtin. Sonra '
            'ilan indi.',
        happiness: -3,
      ),
    ],
  ),

  GameEvent(
    id: 'orta_tanidik_dugunu',
    category: EventCategory.mahalle,
    text:
        'Davetiye geldi. Gideceğin kişiyi iyi tanımıyorsun ama '
        'gitmemek de tuhaf kaçacak.',
    requirement: EventRequirement(minAge: 26, maxAge: 58),
    repeatable: true,
    minAgeGap: 8,
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'git',
        label: 'Git ve takıl',
        resultText:
            'Masada hiç tanımadığın insanlarla gülüştün. '
            'Dönüşte "iyi ki gitmişim" dedin.',
        money: -8000,
        happiness: 5,
        charisma: 2,
      ),
      EventChoice(
        id: 'takdim_gonder',
        label: 'Gitme, hediyeni gönder',
        resultText:
            'Hediyeyi gönderdin, kimse alınmadı. O akşam '
            'evde sessizdi.',
        money: -4500,
      ),
    ],
  ),

  GameEvent(
    id: 'orta_daralan_cevre',
    category: EventCategory.kisisel,
    text:
        'Telefonu açtın ve arayacak birini ararken fark ettin: '
        'liste eskisi kadar uzun değil.',
    requirement: EventRequirement(minAge: 32, maxAge: 62),
    repeatable: true,
    minAgeGap: 9,
    weight: 7,
    choices: <EventChoice>[
      EventChoice(
        id: 'ara',
        label: 'Birini ara',
        resultText:
            'İlk otuz saniye tuhaftı, sonrası hiç tuhaf '
            'değildi. Bir buçuk saat konuştunuz.',
        happiness: 7,
        charisma: 1,
      ),
      EventChoice(
        id: 'birak',
        label: 'Telefonu bırak',
        resultText: 'Ekranı kapattın. Akşam uzun sürdü.',
        happiness: -4,
      ),
    ],
  ),

  GameEvent(
    id: 'orta_komsu_tasiniyor',
    category: EventCategory.mahalle,
    text:
        'Karşı daire boşalıyor. Kamyonet sabahtan beri aşağıda; '
        'yıllardır kapı önünde selamlaştığınız insanlar gidiyor.',
    requirement: EventRequirement(minAge: 22, maxAge: 70),
    repeatable: true,
    minAgeGap: 9,
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'yardim',
        label: 'Aşağı in, yardım et',
        resultText:
            'İki koli taşıdın ve numaralarınızı verdiniz. '
            'Bir daha aramadınız ama iyi ayrıldınız.',
        happiness: 4,
        health: -1,
        charisma: 1,
      ),
      EventChoice(
        id: 'pencereden',
        label: 'Pencereden izle',
        resultText:
            'Kamyonet öğlen gitti. Akşam merdivende ilk kez '
            'kimseyle karşılaşmadın.',
        happiness: -2,
      ),
    ],
  ),

  GameEvent(
    id: 'orta_cocukluk_esyasi',
    category: EventCategory.kisisel,
    text:
        'Dolabın üstündeki kutudan, yıllardır unuttuğun bir şey '
        'çıktı. Elinde tutunca nerede olduğunu hatırladın.',
    requirement: EventRequirement(minAge: 28, maxAge: 65),
    repeatable: true,
    minAgeGap: 11,
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'sakla',
        label: 'Görünür bir yere koy',
        resultText:
            'Rafın üstüne koydun. Artık her gün görüyorsun ve '
            'her gün bir saniye duruyorsun.',
        happiness: 5,
      ),
      EventChoice(
        id: 'geri_koy',
        label: 'Kutuya geri koy',
        resultText:
            'Kutuyu kapattın. Yeri belli, bir gün yine '
            'çıkarsın.',
        happiness: 2,
      ),
      EventChoice(
        id: 'at',
        label: 'Artık gerek yok',
        resultText: 'Çöpe attın. Akşam bir ara aklına geldi.',
        happiness: -3,
      ),
    ],
  ),

  GameEvent(
    id: 'orta_dogum_gunun_unutuldu',
    category: EventCategory.kisisel,
    text:
        'Gün bitti ve kimse hatırlamadı. Telefon sessiz kaldı, sen '
        'de kimseye söylemedin.',
    requirement: EventRequirement(minAge: 28, maxAge: 70),
    repeatable: true,
    minAgeGap: 14,
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'kendine_kutla',
        label: 'Kendin kutla',
        resultText:
            'Kendine bir şey aldın ve tek başına yedin. '
            'Fena değildi; hatta iyiydi.',
        money: -2500,
        happiness: 5,
      ),
      EventChoice(
        id: 'sessiz',
        label: 'Hiçbir şey söyleme',
        resultText:
            'Ertesi gün birkaç kişi geç fark etti. "Neden '
            'söylemedin" dediler. Cevap vermedin.',
        happiness: -5,
      ),
    ],
  ),

  GameEvent(
    id: 'orta_uzak_taziye',
    category: EventCategory.mahalle,
    text:
        'Haber mesajla geldi: uzaktan tanıdığın biri vefat etmiş. '
        'Adını duyunca yüzü gözünün önüne geldi.',
    requirement: EventRequirement(minAge: 30, maxAge: 75),
    repeatable: true,
    minAgeGap: 10,
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'git',
        label: 'Taziyeye git',
        resultText:
            'Kalabalıkta kimseyi tanımadın. Yine de gittiğin '
            'için içine sinen bir şey oldu.',
        money: -1500,
        happiness: -1,
        charisma: 1,
      ),
      EventChoice(
        id: 'mesaj',
        label: 'Bir mesaj yaz',
        resultText:
            'Üç kez sildin, dördüncüde gönderdin. Kısa oldu '
            'ama gerçekti.',
        happiness: -2,
      ),
    ],
  ),

  GameEvent(
    id: 'orta_saglik_erteleme',
    category: EventCategory.kisisel,
    text:
        'Bir süredir devam eden küçük bir şey var. Ciddi değil '
        'gibi — ama "gibi" kelimesi aklından çıkmıyor.',
    requirement: EventRequirement(minAge: 33, maxAge: 65),
    repeatable: true,
    minAgeGap: 8,
    weight: 7,
    choices: <EventChoice>[
      EventChoice(
        id: 'git',
        label: 'Randevu al, git',
        resultText:
            'Doktor baktı, birkaç şey sordu, "önemli değil '
            'ama takip edelim" dedi. İçin rahatladı.',
        money: -3600,
        health: 4,
        happiness: 4,
      ),
      EventChoice(
        id: 'ertele',
        label: 'Geçer, ertele',
        resultText:
            'Ertelemek kolaydı. Bir süre sonra düşünmeyi de '
            'bıraktın.',
        health: -4,
        addFlags: <String>{MidlifeFlags.saglikErteledi},
      ),
    ],
  ),

  // Önceki kararı hatırlar: yalnızca sağlığını erteleyen oyuncuda çıkar.
  GameEvent(
    id: 'orta_ertelemenin_bedeli',
    category: EventCategory.kisisel,
    text:
        'Yıllar önce "geçer" dediğin şey geçmemiş. Bu sefer kendi '
        'kendine karar verecek durumda değilsin.',
    requirement: EventRequirement(
      minAge: 40,
      maxAge: 72,
      requiredFlags: <String>{MidlifeFlags.saglikErteledi},
    ),
    weight: 9,
    choices: <EventChoice>[
      EventChoice(
        id: 'tedavi',
        label: 'Ne gerekiyorsa yap',
        resultText:
            'Uzun bir süreç oldu ve pahalıya mal oldu. Sonunda '
            'toparladın; erken gitseydin daha kolay olacaktı.',
        money: -55000,
        health: 6,
        happiness: -2,
        removeFlags: <String>{MidlifeFlags.saglikErteledi},
      ),
      EventChoice(
        id: 'yine_ertele',
        label: 'Yine sonraya bırak',
        resultText:
            'Bir kez daha erteledin. Bu sefer kendine bile '
            'inandıramadın.',
        health: -7,
        happiness: -4,
      ),
    ],
  ),

  GameEvent(
    id: 'orta_gonullu_cagri',
    category: EventCategory.mahalle,
    text:
        'Mahalledeki bir çalışma için gönüllü arıyorlar. Cumartesi '
        'sabahı, birkaç saat.',
    requirement: EventRequirement(
      minAge: 26,
      maxAge: 70,
      forbiddenFlags: <String>{MidlifeFlags.gonulluOldu},
    ),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'katil',
        label: 'Katıl',
        resultText:
            'Sabah erken kalktın ve hiç pişman olmadın. '
            'Tanımadığın insanlarla aynı işi yapmak tuhaf biçimde iyi '
            'geldi.',
        happiness: 8,
        charisma: 3,
        health: -1,
        addFlags: <String>{MidlifeFlags.gonulluOldu},
      ),
      EventChoice(
        id: 'katilma',
        label: 'Bu hafta olmaz',
        resultText:
            'Cumartesi sabahı uyudun. Öğleden sonra '
            'fotoğrafları gördün.',
        happiness: 1,
      ),
    ],
  ),

  GameEvent(
    id: 'orta_teknoloji_gerisi',
    category: EventCategory.yetiskinlik,
    text:
        'Bir işlemi yapmaya çalışırken takıldın. Gençken bu tür '
        'şeyleri anında çözerdin; şimdi ekrana bakıp duruyorsun.',
    requirement: EventRequirement(minAge: 38, maxAge: 75),
    repeatable: true,
    minAgeGap: 10,
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'ogren',
        label: 'Otur ve öğren',
        resultText:
            'Yarım saat uğraştın ve çözdün. Bir sonraki sefere '
            'daha hızlı olacak.',
        intelligence: 3,
        happiness: 3,
      ),
      EventChoice(
        id: 'birine_sor',
        label: 'Birinden yardım iste',
        resultText:
            'İki dakikada halletti. "Kolaymış" dedin; o '
            '"kolay zaten" dedi.',
        happiness: 1,
        charisma: 1,
      ),
      EventChoice(
        id: 'vazgec',
        label: 'Vazgeç',
        resultText:
            'Ekranı kapattın. O iş bir süre daha yapılmadan '
            'kaldı.',
        happiness: -3,
      ),
    ],
  ),

  GameEvent(
    id: 'orta_ev_sahibi_satiyor',
    category: EventCategory.yetiskinlik,
    text:
        'Ev sahibi daireyi satmaya karar vermiş. "Acelen yok ama '
        'haberin olsun" dedi.',
    requirement: EventRequirement(minAge: 26, maxAge: 62),
    repeatable: true,
    minAgeGap: 14,
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'hemen_ara',
        label: 'Hemen yeni yer aramaya başla',
        resultText:
            'Haftalarca ilan baktın, birkaç yer gezdin. '
            'Yorucuydu ama hazırlıksız yakalanmadın.',
        happiness: -3,
        intelligence: 2,
        money: -3000,
      ),
      EventChoice(
        id: 'bekle',
        label: 'Olacağı zaman düşünürsün',
        resultText:
            'Konuyu kapattın. Aylarca aklının bir köşesinde '
            'durdu.',
        happiness: -4,
      ),
    ],
  ),

  GameEvent(
    id: 'orta_hafta_sonu_bos',
    category: EventCategory.kisisel,
    text:
        'Cumartesi sabahı hiçbir planın yok. Uzun zamandır ilk kez '
        'gün tamamen senin.',
    requirement: EventRequirement(minAge: 24, maxAge: 70),
    repeatable: true,
    minAgeGap: 7,
    weight: 7,
    choices: <EventChoice>[
      EventChoice(
        id: 'disari',
        label: 'Hedefsizce dışarı çık',
        resultText:
            'Bilmediğin bir sokaktan geçtin, tanımadığın bir '
            'yerde oturdun. Akşam eve yorgun ama hafif döndün.',
        money: -1800,
        happiness: 7,
      ),
      EventChoice(
        id: 'evde_kal',
        label: 'Evde hiçbir şey yapma',
        resultText:
            'Gün nasıl geçti anlamadın. Akşam "hiçbir şey '
            'yapmadım" dedin — kötü bir tonla değil.',
        happiness: 4,
        health: 2,
      ),
      EventChoice(
        id: 'is_yap',
        label: 'Biriken işleri bitir',
        resultText:
            'Listeyi bitirdin. Pazar sabahı ev gerçekten '
            'düzenliydi.',
        happiness: 2,
        health: -1,
      ),
    ],
  ),

  GameEvent(
    id: 'orta_yarim_kalan_kitap',
    category: EventCategory.kisisel,
    text:
        'Başucunda aylardır aynı sayfada duran bir kitap var. '
        'Ayracı çıkardığında sayfa sarıydı.',
    requirement: EventRequirement(minAge: 24, maxAge: 75),
    repeatable: true,
    minAgeGap: 9,
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'bastan',
        label: 'Baştan başla',
        resultText:
            'İlk bölümü hiç hatırlamıyormuşsun. Bu sefer '
            'bitirdin.',
        intelligence: 3,
        happiness: 4,
      ),
      EventChoice(
        id: 'kaldir',
        label: 'Rafa kaldır',
        resultText: 'Rafa koydun. Yerini biliyorsun; bir gün belki.',
        happiness: -1,
      ),
    ],
  ),

  GameEvent(
    id: 'orta_sabah_yolu',
    category: EventCategory.yetiskinlik,
    text:
        'Her sabah aynı yol, aynı durak, aynı yüzler. Bu sabah '
        'birden farkına vardın.',
    requirement: EventRequirement(minAge: 24, maxAge: 62),
    repeatable: true,
    minAgeGap: 8,
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'degistir',
        label: 'Yolu değiştir',
        resultText:
            'Bir durak önce indin ve kalanını yürüdün. On beş '
            'dakika uzadı, gün kısaldı.',
        happiness: 5,
        health: 3,
      ),
      EventChoice(
        id: 'ayni',
        label: 'Aynı yoldan devam et',
        resultText: 'Aynı yerde, aynı saatte, aynı camdan baktın.',
        happiness: -1,
      ),
    ],
  ),

  GameEvent(
    id: 'orta_ek_is_teklifi',
    category: EventCategory.yetiskinlik,
    text:
        'Bir tanıdık, akşamları yapılabilecek küçük bir iş '
        'önerdi. Para fena değil ama zaman senin zamanın.',
    requirement: EventRequirement(minAge: 22, maxAge: 58),
    repeatable: true,
    minAgeGap: 10,
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'kabul',
        label: 'Kabul et',
        resultText:
            'Birkaç ay akşamların doldu. Hesap rahatladı, sen '
            'biraz yoruldun.',
        money: 42000,
        health: -4,
        happiness: -2,
      ),
      EventChoice(
        id: 'reddet',
        label: 'Akşamlarım bana lazım',
        resultText: '"Kusura bakma" dedin. Akşamların senin kaldı.',
        happiness: 4,
      ),
    ],
  ),
];
