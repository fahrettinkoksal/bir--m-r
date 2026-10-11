/// İlkokul yılları: 7-11 yaş (Paket DG).
///
/// **Neden var.** `docs/EKSIKLER.md` §7'nin 2. maddesi: "Çocukluk ve
/// ergenlik olayları — oyunun en fakir ve en duygusal dönemi." Paket CX
/// 0-2'yi, Paket DE 3-6'yı doldurdu. Bant bant ölçüm (160 bot hayatı,
/// `BotLifeResult.eventsByAge`) sırada bu bandı gösteriyor:
///
/// | bant | yıl | yıl başına olay | farklı olay | **bant yılı başına farklı** |
/// |---|---|---|---|---|
/// | **7-11 ilkokul** | 5 | 1,47 | 103 | **20,6** |
/// | 21-29 genç yetişkin | 9 | 1,76 | 197 | 21,9 |
/// | 30-39 otuzlar | 10 | 1,81 | 259 | 25,9 |
/// | 12-15 ergenlik | 4 | 1,57 | 130 | 32,5 |
/// | 16-20 eşik | 5 | 1,67 | 166 | 33,2 |
///
/// Yani yıl başına olay sayısı ortalamaya yakın ama **çeşitlilik en
/// düşük**: oyuncu beş yıl boyunca aynı yirmi olayın içinde dönüyor.
/// Bu dosyanın işi o sayıyı değil, **tekrarı** azaltmak.
///
/// **Bu yaşta çocuk karar verir ama bedelini ödemez.** Seçimler çocuğun
/// kendi tercihi olabilir (bu yaş 0-6'dan farklı), ama sonuçları
/// yetişkin ölçeğinde yazılmaz: ne para ne kariyer. Okul olayları
/// `requiresSchoolStudent` ile kapılı — okula gitmeyen çocuğa okul
/// koridoru anlatılmaz.
///
/// Modül anahtarı: `FeatureId.ilkokulYillari`. Kapatma tarifi:
/// `docs/FEATURE_FLAGS.md`.
library;

import '../domain/models/game_event.dart';
import '../domain/models/relation.dart';

/// İlkokul yıllarının bıraktığı, sonradan okunan izler.
///
/// Her izin bu dosyada bir okuyanı var (Paket AR/CZ kuralı).
abstract final class PrimarySchoolFlags {
  /// Sıra arkadaşıyla kalıcı bir bağ kurdu.
  static const String siraArkadasi = 'ilkokul_sira_arkadasi';

  /// Kopya teklifini reddetti.
  static const String kopyayiReddetti = 'ilkokul_kopyayi_reddetti';

  /// Takım seçiminde en sona kaldı.
  static const String sonaKaldi = 'ilkokul_takimda_sona_kaldi';

  /// Törende sahneye çıktı.
  static const String torendeSahne = 'ilkokul_torende_sahne';

  /// Öğretmeninin bir cümlesi aklında kaldı.
  static const String ogretmeninCumlesi = 'ilkokul_ogretmenin_cumlesi';

  /// Kütüphaneden ilk kitabını aldı.
  static const String ilkKitap = 'ilkokul_ilk_kitap';
}

const List<GameEvent> kPrimarySchoolEvents = <GameEvent>[
  // -------------------------------------------------------------------
  // Okul içi
  // -------------------------------------------------------------------
  GameEvent(
    id: 'ilkokul_sira_arkadasi',
    category: EventCategory.okul,
    text: 'Sıralar yeniden dizildi. Yanına oturan kişiyle bütün yıl '
        'aynı masayı paylaşacaksın.',
    requirement: EventRequirement(
      minAge: 7,
      maxAge: 11,
      requiresSchoolStudent: true,
    ),
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'anlastin',
        label: 'Hemen anlaş',
        resultText: 'Silgi ortak, matara ortak, şakalar ortak oldu. '
            'Öğretmen ikinizi iki kez ayırmak zorunda kaldı.',
        happiness: 5,
        charisma: 3,
        addFlags: <String>{PrimarySchoolFlags.siraArkadasi},
      ),
      EventChoice(
        id: 'kendi_isine',
        label: 'Kendi işine bak',
        resultText: 'Masanın ortasına görünmez bir çizgi çekildi. Yıl '
            'sessiz ama düzenli geçti.',
        happiness: 1,
        intelligence: 2,
      ),
    ],
  ),
  GameEvent(
    id: 'ilkokul_tahtaya_kalkma',
    category: EventCategory.okul,
    text: 'Öğretmen sınıfa baktı ve adını okudu. Tahta kocaman, '
        'tebeşir elinde.',
    requirement: EventRequirement(
      minAge: 7,
      maxAge: 11,
      requiresSchoolStudent: true,
    ),
    repeatable: true,
    minAgeGap: 2,
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'cozdu',
        label: 'Tahtaya çık, dene',
        resultText: 'Yarısında tıkandın, öğretmen bir ipucu verdi, '
            'gerisi geldi. Yerine otururken kulakların yanıyordu.',
        happiness: 3,
        intelligence: 3,
        charisma: 2,
      ),
      EventChoice(
        id: 'sustu',
        label: 'Yerinde kal, sesini çıkarma',
        resultText: 'Başka birine soruldu. Konu kapandı ama o soru '
            'akşama kadar aklından çıkmadı.',
        happiness: -1,
        intelligence: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'ilkokul_karne_gunu',
    category: EventCategory.okul,
    text: 'Karne günü. Sıra sırayla yaklaşıyor, kâğıt elden ele '
        'geçiyor.',
    requirement: EventRequirement(
      minAge: 7,
      maxAge: 11,
      requiresSchoolStudent: true,
      livingRelations: <RelationType>{RelationType.anne, RelationType.baba},
    ),
    repeatable: true,
    minAgeGap: 2,
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'gosterdi',
        label: 'Eve koşup göster',
        resultText: 'Buzdolabının kapağına asıldı. Haftalarca orada '
            'durdu; misafir gelince yine gösterildi.',
        happiness: 5,
        bond: 4,
      ),
      EventChoice(
        id: 'cantada',
        label: 'Çantada kalsın',
        resultText: 'Akşam sorulunca çıkardın. Kimse bağırmadı ama '
            'konuşma uzun sürdü.',
        happiness: 1,
        bond: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'ilkokul_kopya_teklifi',
    category: EventCategory.okul,
    text: 'Sınav kâğıdı önünde. Yan sıradan bir fısıltı geliyor: '
        '"kaydır şunu".',
    requirement: EventRequirement(
      minAge: 9,
      maxAge: 11,
      requiresSchoolStudent: true,
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'reddetti',
        label: 'Kâğıdı kapat',
        resultText: 'Kâğıdını kapattın. O gün teneffüste yalnız '
            'kaldın; akşam vicdanın rahattı.',
        happiness: 1,
        intelligence: 2,
        charisma: -1,
        addFlags: <String>{PrimarySchoolFlags.kopyayiReddetti},
      ),
      EventChoice(
        id: 'kaydirdi',
        label: 'Kaydır',
        resultText: 'Kaydırdın. İkinizin de notu aynı çıktı, '
            'öğretmen bir şey demedi ama uzun uzun baktı.',
        happiness: 2,
        charisma: 2,
        intelligence: -1,
      ),
    ],
  ),
  GameEvent(
    id: 'ilkokul_beden_takim_secimi',
    category: EventCategory.okul,
    text: 'Beden dersi. İki kaptan seçildi, sıra sırayla eriyor ve '
        'sen hâlâ bekliyorsun.',
    requirement: EventRequirement(
      minAge: 7,
      maxAge: 11,
      requiresSchoolStudent: true,
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'sona_kaldi',
        label: 'Sırt dön, oralı olma',
        resultText: 'En sona kaldın. Oyun başlayınca iki gol attın ve '
            'bir dahaki sefere erken seçildin.',
        happiness: -1,
        health: 2,
        addFlags: <String>{PrimarySchoolFlags.sonaKaldi},
      ),
      EventChoice(
        id: 'kendini_soyledi',
        label: '"Ben varım" de',
        resultText: 'Sesini çıkardın ve seçildin. Kaptanlık sırası '
            'bir gün sana da geldi.',
        happiness: 3,
        charisma: 3,
      ),
    ],
  ),
  GameEvent(
    id: 'ilkokul_toren_gunu',
    category: EventCategory.okul,
    text: 'Bayram töreni hazırlığı. Bir şiir, bir de arka sırada '
        'sessizce durmak var. Öğretmen gönüllü arıyor.',
    requirement: EventRequirement(
      minAge: 7,
      maxAge: 11,
      requiresSchoolStudent: true,
    ),
    repeatable: true,
    minAgeGap: 3,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'sahneye',
        label: 'Elini kaldır',
        resultText: 'Mikrofon boyundan yüksekti, eğildiler. Bitince '
            'alkış uzun sürdü ve birkaç fotoğraf çekildi.',
        happiness: 5,
        charisma: 4,
        addFlags: <String>{PrimarySchoolFlags.torendeSahne},
      ),
      EventChoice(
        id: 'arka_sira',
        label: 'Arka sırada dur',
        resultText: 'Sırada durdun, bayrağı tuttun. Töreni oradan '
            'izlemek de iyiydi.',
        happiness: 2,
      ),
    ],
  ),
  GameEvent(
    id: 'ilkokul_ogretmenin_cumlesi',
    category: EventCategory.okul,
    text: 'Defterini kapatırken öğretmen yanından geçti ve kısa bir '
        'şey söyledi. Kimse duymadı, sen duydun.',
    requirement: EventRequirement(
      minAge: 8,
      maxAge: 11,
      requiresSchoolStudent: true,
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'tuttu',
        label: 'Aklında tut',
        resultText: '"Sen bunu yaparsın" dedi, yürüdü gitti. O cümle '
            'yıllarca aklında kaldı.',
        happiness: 4,
        intelligence: 3,
        addFlags: <String>{PrimarySchoolFlags.ogretmeninCumlesi},
      ),
      EventChoice(
        id: 'unuttu',
        label: 'Omuz silk',
        resultText: 'Zil çaldı, bahçeye koştun. Cümle o gün bahçede '
            'kaldı.',
        happiness: 2,
      ),
    ],
  ),
  GameEvent(
    id: 'ilkokul_kantin_parasi',
    category: EventCategory.okul,
    text: 'Cebinde teneffüs parası var. Kantinin önünde sıra uzun ve '
        'herkes aynı şeyi istiyor.',
    requirement: EventRequirement(
      minAge: 7,
      maxAge: 11,
      requiresSchoolStudent: true,
    ),
    repeatable: true,
    minAgeGap: 2,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'paylasti',
        label: 'Parayı paylaş',
        resultText: 'İki kişiye yetti, üçe bölündü. O gün kimse aç '
            'kalmadı ve sen hep hatırlandın.',
        happiness: 4,
        charisma: 3,
      ),
      EventChoice(
        id: 'biriktirdi',
        label: 'Harcamayıp biriktir',
        resultText: 'Cebinde durdu. Hafta sonunda tam istediğin şeye '
            'yetti.',
        happiness: 3,
        intelligence: 2,
        money: 120,
      ),
    ],
  ),
  GameEvent(
    id: 'ilkokul_sinif_fotografi',
    category: EventCategory.okul,
    text: 'Sınıf fotoğrafı çekilecek. Sıralar bahçeye taşındı, '
        'herkes yerini arıyor.',
    requirement: EventRequirement(
      minAge: 7,
      maxAge: 11,
      requiresSchoolStudent: true,
    ),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'one',
        label: 'Öne geç',
        resultText: 'En öne oturdun. Yıllar sonra o fotoğrafta ilk '
            'bulunan sen olacaksın.',
        happiness: 4,
        appearance: 1,
      ),
      EventChoice(
        id: 'arkaya',
        label: 'Arkaya karış',
        resultText: 'Arka sırada, yarı görünür bir yerde durdun. '
            'Fotoğrafta gülüyorsun.',
        happiness: 2,
      ),
    ],
  ),

  // -------------------------------------------------------------------
  // Okul dışı: ev, mahalle, kütüphane
  // -------------------------------------------------------------------
  GameEvent(
    id: 'ilkokul_kirtasiye',
    category: EventCategory.aile,
    text: 'Okul açılıyor. Kırtasiyenin önü kalabalık; liste elde, '
        'defterlerin kabı seçilecek.',
    requirement: EventRequirement(
      minAge: 7,
      maxAge: 11,
      livingRelations: <RelationType>{RelationType.anne, RelationType.baba},
      requireSameHousehold: true,
    ),
    repeatable: true,
    minAgeGap: 3,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'kendi_sectin',
        label: 'Kabı kendin seç',
        resultText: 'Seçtiğin kaplar evdeki herkesin diline düştü. '
            'Defterleri akşam birlikte kapladınız.',
        happiness: 4,
        bond: 3,
      ),
      EventChoice(
        id: 'ucuz',
        label: 'En uygun olanı al',
        resultText: 'Liste eksiksiz tamamlandı, hesap da şişmedi. '
            'Çantayı sen taşıdın.',
        happiness: 2,
        intelligence: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'ilkokul_harclik_pazarligi',
    category: EventCategory.aile,
    text: 'Harçlık konusunu açmanın tam zamanı. Hazırlanmış bir '
        'cümlen bile var.',
    requirement: EventRequirement(
      minAge: 9,
      maxAge: 11,
      livingRelations: <RelationType>{RelationType.anne, RelationType.baba},
      requireSameHousehold: true,
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'isi_yaparak',
        label: 'Karşılığında iş teklif et',
        resultText: 'Masayı toplamak sana kaldı ama harçlık arttı. '
            'Anlaşmanın şartlarını kimse unutmadı.',
        happiness: 3,
        intelligence: 2,
        charisma: 2,
      ),
      EventChoice(
        id: 'israr',
        label: 'Israr et',
        resultText: 'Konu kapandı, harçlık aynı kaldı. İki gün sonra '
            'sessizce biraz arttı.',
        happiness: 2,
      ),
    ],
  ),
  GameEvent(
    id: 'ilkokul_kutuphane_ilk_kitap',
    category: EventCategory.kisisel,
    text: 'Rafların arasında kaldın. Birini seçmen gerekiyor ve '
        'hepsinin sırtı aynı derecede merak uyandırıyor.',
    requirement: EventRequirement(
      minAge: 8,
      maxAge: 11,
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'aldi',
        label: 'Kalın olanı al',
        resultText: 'Yarısında kaldı ama bitirdiğin gün kapağı '
            'kapatıp bir süre öyle durdun.',
        happiness: 4,
        intelligence: 4,
        addFlags: <String>{PrimarySchoolFlags.ilkKitap},
      ),
      EventChoice(
        id: 'resimli',
        label: 'Resimli olanı al',
        resultText: 'Bir oturuşta bitti. Ertesi gün bir tane daha '
            'aldın.',
        happiness: 3,
        intelligence: 2,
        addFlags: <String>{PrimarySchoolFlags.ilkKitap},
      ),
    ],
  ),
  GameEvent(
    id: 'ilkokul_mahalle_maci',
    category: EventCategory.mahalle,
    text: 'Sokakta kadro kuruluyor. Kaleler çanta, saha iki araba '
        'arası.',
    requirement: EventRequirement(
      minAge: 7,
      maxAge: 11,
    ),
    repeatable: true,
    minAgeGap: 2,
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'oynadi',
        label: 'Sahaya gir',
        resultText: 'Diz sıyrıldı, pantolon yırtıldı, maç uzadı. '
            'Akşam çağrılana kadar çıkmadın.',
        happiness: 5,
        health: 3,
      ),
      EventChoice(
        id: 'hakem',
        label: 'Hakemlik yap',
        resultText: 'İki kez itiraz yedin, bir kez haklı çıktın. '
            'Kimse oyundan çıkmadı.',
        happiness: 3,
        charisma: 3,
      ),
    ],
  ),
  GameEvent(
    id: 'ilkokul_kavga_ve_barisma',
    category: EventCategory.okul,
    text: 'Bahçede iş büyüdü. Bir itiş, bir bağırış ve etrafta '
        'toplanan kalabalık.',
    requirement: EventRequirement(
      minAge: 8,
      maxAge: 11,
      requiresSchoolStudent: true,
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'baristi',
        label: 'Elini uzat',
        resultText: 'Zil çaldı, ikiniz de tozlu. Elini uzatan sen '
            'oldun ve o çocuk yıllarca bunu anlattı.',
        happiness: 3,
        charisma: 4,
      ),
      EventChoice(
        id: 'kustu',
        label: 'Konuşma',
        resultText: 'Haftalarca selam vermediniz. Sonra bir maçta '
            'aynı takıma düştünüz ve konu kendiliğinden kapandı.',
        happiness: 1,
        charisma: -1,
      ),
    ],
  ),
  GameEvent(
    id: 'ilkokul_kardesine_goz_kulak',
    category: EventCategory.aile,
    text: 'Senden küçük biri var ve bugün ona göz kulak olma sırası '
        'sende.',
    requirement: EventRequirement(
      minAge: 9,
      maxAge: 11,
      livingRelations: <RelationType>{RelationType.kardes},
      requireSameHousehold: true,
    ),
    repeatable: true,
    minAgeGap: 2,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'ustlendi',
        label: 'Yanından ayrılma',
        resultText: 'Elini bırakmadın, iki kere su verdin, bir kere '
            'kızdın. Akşam "iyi iş" dendi.',
        happiness: 3,
        bond: 5,
        charisma: 2,
      ),
      EventChoice(
        id: 'kendi_oyunu',
        label: 'Kendi oyununa dön',
        resultText: 'Oyuna daldın. Kimse kaybolmadı ama akşam konu '
            'açıldı.',
        happiness: 2,
        bond: -1,
      ),
    ],
  ),
  GameEvent(
    id: 'ilkokul_yaz_tatili_bitti',
    category: EventCategory.kisisel,
    text: 'Yaz bitiyor. Çanta hazır, defterler kaplı ve içinde iki '
        'his birden var.',
    requirement: EventRequirement(
      minAge: 7,
      maxAge: 11,
      requiresSchoolStudent: true,
    ),
    repeatable: true,
    minAgeGap: 3,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'hevesli',
        label: 'Erken yat, hazır ol',
        resultText: 'Sabah ilk kalkan sen oldun. Kapıda ayakkabın '
            'çoktan bağlıydı.',
        happiness: 3,
        intelligence: 2,
      ),
      EventChoice(
        id: 'isteksiz',
        label: 'Son geceyi uzat',
        resultText: 'Gece geç yattın, sabah zor kalktın. İlk gün '
            'gözlerin yarı kapalı geçti.',
        happiness: 2,
        health: -1,
      ),
    ],
  ),

  // -------------------------------------------------------------------
  // Karşılık olayları: yukarıdaki her iz burada okunuyor
  // -------------------------------------------------------------------
  GameEvent(
    id: 'ilkokul_iz_sira_arkadasi',
    category: EventCategory.kisisel,
    text: 'Bir kalabalıkta tanıdık bir yüz: ilkokulda aynı masayı '
        'paylaştığın kişi. İkiniz de bir an duruyorsunuz.',
    requirement: EventRequirement(
      minAge: 20,
      requiredFlags: <String>{PrimarySchoolFlags.siraArkadasi},
    ),
    repeatable: true,
    minAgeGap: 20,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'konustu',
        label: 'Yanına git',
        resultText: 'On dakika konuştunuz, yirmi yıl anlatıldı. '
            'Numaralar yazıldı, bir daha aranmadı; yine iyi geldi.',
        happiness: 4,
        charisma: 2,
      ),
      EventChoice(
        id: 'gecti',
        label: 'Tanımamış gibi geç',
        resultText: 'Geçtin. Akşam o masa, o silgi ve o şakalar '
            'aklına geldi.',
        happiness: 2,
      ),
    ],
  ),
  GameEvent(
    id: 'ilkokul_iz_kopya',
    category: EventCategory.kisisel,
    text: 'Önünde bir kolaylık var: kimse görmez, kimse sormaz. '
        'İlkokulda kapattığın o kâğıt aklına geliyor.',
    requirement: EventRequirement(
      minAge: 16,
      requiredFlags: <String>{PrimarySchoolFlags.kopyayiReddetti},
    ),
    repeatable: true,
    minAgeGap: 16,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'yine_reddetti',
        label: 'Yine kapat',
        resultText: 'Kolay yolu almadın. Kimse görmedi, sen '
            'biliyorsun.',
        happiness: 3,
        intelligence: 2,
      ),
      EventChoice(
        id: 'bu_kez',
        label: 'Bu kez al',
        resultText: 'Aldın. İşe yaradı ve o çocuğun kâğıdı kapatışı '
            'bir süre aklından çıkmadı.',
        happiness: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'ilkokul_iz_sona_kalmak',
    category: EventCategory.kisisel,
    text: 'Bir takım, bir kadro, bir seçim listesi. Adının en sonda '
        'okunmasını bekleme hissi geri geldi.',
    requirement: EventRequirement(
      minAge: 15,
      requiredFlags: <String>{PrimarySchoolFlags.sonaKaldi},
    ),
    repeatable: true,
    minAgeGap: 15,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'kendini_soyledi',
        label: 'Bu kez önce söyle',
        resultText: '"Ben varım" demek on yıl sürdü ama söylendi.',
        happiness: 4,
        charisma: 3,
      ),
      EventChoice(
        id: 'bekledi',
        label: 'Yine bekle',
        resultText: 'Bekledin ve yine seçildin. Bekleme kısmı artık '
            'daha az sürüyor.',
        happiness: 2,
      ),
    ],
  ),
  GameEvent(
    id: 'ilkokul_iz_sahne',
    category: EventCategory.kisisel,
    text: 'Kalabalığa konuşman gerekiyor. İçinde eski bir şey '
        'kıpırdıyor: boyundan yüksek o mikrofon.',
    requirement: EventRequirement(
      minAge: 17,
      requiredFlags: <String>{PrimarySchoolFlags.torendeSahne},
    ),
    repeatable: true,
    minAgeGap: 17,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'konustu',
        label: 'Çık, konuş',
        resultText: 'Sesin titredi ama cümleler yerine oturdu. '
            'Mikrofon bu kez boyundaydı.',
        happiness: 4,
        charisma: 4,
      ),
      EventChoice(
        id: 'biri_baska',
        label: 'Başkası konuşsun',
        resultText: 'Konuşmadın. Dinlerken aklından kendi cümlelerin '
            'geçti.',
        happiness: 2,
      ),
    ],
  ),
  GameEvent(
    id: 'ilkokul_iz_ogretmenin_cumlesi',
    category: EventCategory.kisisel,
    text: 'Zor bir işin eşiğindesin ve yıllar önce koridorda '
        'duyduğun o kısa cümle aklına geliyor.',
    requirement: EventRequirement(
      minAge: 18,
      requiredFlags: <String>{PrimarySchoolFlags.ogretmeninCumlesi},
    ),
    repeatable: true,
    minAgeGap: 18,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'denedi',
        label: 'Dene',
        resultText: 'Denedin. Olmasa bile o cümle yüzünden '
            'denemiştin.',
        happiness: 4,
        intelligence: 3,
      ),
      EventChoice(
        id: 'vazgecti',
        label: 'Vazgeç',
        resultText: 'Geri çekildin. Cümle yerinde durmaya devam '
            'etti.',
        happiness: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'ilkokul_iz_ilk_kitap',
    category: EventCategory.kisisel,
    text: 'Bir rafta o kitabın yeni baskısını gördün. Kapağı '
        'değişmiş, içindeki aynı.',
    requirement: EventRequirement(
      minAge: 16,
      requiredFlags: <String>{PrimarySchoolFlags.ilkKitap},
    ),
    repeatable: true,
    minAgeGap: 16,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'aldi',
        label: 'Al',
        resultText: 'Aldın. İlk sayfada hatırladığından başka bir '
            'şey yazıyordu.',
        happiness: 4,
        intelligence: 2,
        money: -180,
      ),
      EventChoice(
        id: 'elledi',
        label: 'Eline al, yerine koy',
        resultText: 'Kapağını çevirdin, yerine koydun. O kitabı '
            'zaten biliyorsun.',
        happiness: 3,
      ),
    ],
  ),
];
