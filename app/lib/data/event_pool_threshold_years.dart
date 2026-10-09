/// Eşikteki yıllar: 16-20 yaş olayları (Paket BN).
///
/// **Ölçülen sorun.** Oyuncunun o yıl gerçekten karşılaşabileceği olay
/// sayısı, oynanan 40 hayatta yaşa göre ölçüldü
/// (`EventEngine.debugEligibleIds`): 25 yaşında 67, 30'da 77, 40'ta 80
/// — ama **16'da 41, 18'de 34, 20'de 44**. Yani çocukluktan sonra en
/// ince bant, hayatın en çok şey olan yıllarıydı: sınav sonucu,
/// tercih listesi, ilk iş, ilk maaş, evden çıkma, dağılan arkadaş
/// grubu. Katalogda bu bandın tamamına sıkı sıkıya bağlı yalnızca beş
/// olay vardı (`lise_sonrasi`, `universite_ilk_hafta`, `ilk_maas`,
/// `yaz_isi`, `zincir_emanet_1`).
///
/// **Bu dosya yeni mekanik getirmez.** O boşluğa içerik koyar.
/// Kurallar:
///
/// - 18 yaşından önce masrafı hane öder; olay metni masrafı anlatır ama
///   oyuncunun cüzdanına dokunmaz. 18'den sonra para gerçekten
///   oyuncunun cüzdanından çıkar ve girer (ECO-001).
/// - Gerçek üniversite, şirket, marka ve kişi adı geçmez; siyasi
///   tercih, askerlik yükümlülüğü ve din konuları bu havuzun dışında
///   (ikisi de ayrı sistem ve ayrı karar).
/// - Ağır konu (sağlık ihmali, ayrılık) sade anlatılır; espri yok
///   (`docs/WRITING_STYLE_TR.md` §7).
/// - Bırakılan her iz **okunur**: dosyanın sonundaki dört olay kendi
///   izlerinin karşılığıdır. Karşılığı olmayan iz bırakmak Paket AR'nin
///   ölçtüğü "sessiz iz" hatasını yeniden üretirdi.
///
/// Bütün sayılar `prototypeOnly`'dir.
///
/// Modül: `FeatureId.esiktekiYillar` — kapatılınca bu havuz hiç
/// listelenmez (`docs/FEATURE_FLAGS.md`).
library;

import '../domain/models/game_event.dart';
import '../domain/models/relation.dart';
import 'event_pool.dart';

/// Eşikteki yılların hikâye izleri.
abstract final class ThresholdFlags {
  /// Genç yaşta direksiyon başına geçti.
  static const String ehliyetiGenc = 'esik_ehliyet_genc';

  /// Çıraklık yolunu seçti.
  static const String cirakOldu = 'esik_cirak';

  /// Evden erken çıktı.
  static const String evdenCiktiGenc = 'esik_evden_cikti';

  /// Lise sonrası arkadaş grubu dağıldı.
  static const String arkadaslarDagildi = 'esik_arkadaslar_dagildi';

  /// Karşılık olaylarının kapanış izleri.
  static const String ehliyetKarsiligi = 'esik_ehliyet_karsiligi';
  static const String cirakKarsiligi = 'esik_cirak_karsiligi';
  static const String evdenCikmaKarsiligi = 'esik_evden_cikma_karsiligi';
  static const String arkadasKarsiligi = 'esik_arkadas_karsiligi';
}

/// İlişki başlatan olayların kapı yasakları.
///
/// Zaten ilişkisi olan ya da evli oyuncuya tanışma olayı çıkmaz; katalog
/// bekçisi (`romance_reach_test.dart`) bunu şart koşuyor.
const Set<String> _tanismaYasaklari = <String>{
  StoryFlags.romantikIliskide,
  StoryFlags.evlendi,
};

const List<GameEvent> kThresholdYearsEvents = <GameEvent>[
  // ---------------------------------------------------------------
  // Tanışma: ilk ilişki çoğu hayatta bu bantta kuruluyor
  //
  // **Ölçülmüş sebep.** Paket BN'nin ilk hâli 16-20 bandına 29 olay
  // ekledi ve rastgele seçen oyuncunun ilişki kurma oranı 150 hayatta
  // %65,3'ten %52,7'ye düştü: yılda bir olay yuvası var, havuz
  // büyüdükçe tanışma olayı kurayı daha az kazanıyor. Üstüne
  // katalogdaki yetişkin tanışma olayları **24 yaşında** başlıyordu,
  // yani ilk ilişkinin en doğal yaşı boştu. Bu üç olay seyreltmeyi
  // tersine çevirir: bandın kendi tanışma kapısı.
  GameEvent(
    id: 'esik_mahallede_tanisma',
    category: EventCategory.kisisel,
    text:
        'Arkadaş grubuna yeni biri katıldı. Aynı masada iki kez oturdunuz '
        've üçüncüsünde adını sen sordun.',
    requirement: EventRequirement(
      minAge: 17,
      maxAge: 20,
      forbiddenFlags: _tanismaYasaklari,
    ),
    weight: 12,
    choices: <EventChoice>[
      EventChoice(
        id: 'numarasini_aldi',
        label: 'Numarasını al',
        resultText:
            'İki gün sonra buluştunuz. Artık birliktesiniz; İlişkiler '
            'bölümünde {kisi} görünüyor.',
        happiness: 8,
        charisma: 3,
        startsRomance: true,
      ),
      EventChoice(
        id: 'arkadas_kaldi',
        label: 'Arkadaş kal',
        resultText:
            'Grup aynı kaldı, siz de öyle. Bir süre sonra o başka biriyle '
            'geldi.',
        happiness: -1,
        charisma: 1,
      ),
    ],
  ),

  GameEvent(
    id: 'esik_kampuste_tanisma',
    category: EventCategory.okul,
    text:
        'Sınıfta yanına oturan biri notlarını istedi. Kütüphanede '
        'buluşmaya karar verdiniz ve ders bir saatte bitti, sohbet '
        'bitmedi.',
    requirement: EventRequirement(
      minAge: 18,
      maxAge: 20,
      requiresSchoolStudent: true,
      forbiddenFlags: _tanismaYasaklari,
    ),
    weight: 12,
    choices: <EventChoice>[
      EventChoice(
        id: 'devam_etti',
        label: 'Buluşmaya devam et',
        resultText:
            'Kütüphane bahaneydi ve ikiniz de biliyordunuz. Artık '
            'birliktesiniz; İlişkiler bölümünde {kisi} görünüyor.',
        happiness: 8,
        charisma: 2,
        intelligence: 1,
        startsRomance: true,
      ),
      EventChoice(
        id: 'ders_kaldi',
        label: 'Dersi derste bırak',
        resultText:
            'Notları verdin, vize geçti. Kütüphanede bir daha '
            'karşılaşmadınız.',
        intelligence: 2,
      ),
    ],
  ),

  GameEvent(
    id: 'esik_iste_tanisma',
    category: EventCategory.yetiskinlik,
    text:
        'İlk işinde vardiya arkadaşınla mola saatleri aynı. Bugün '
        '"çıkışta bir şey içelim mi" diye soruyor.',
    requirement: EventRequirement(
      minAge: 18,
      maxAge: 20,
      requiresEmployed: true,
      forbiddenFlags: _tanismaYasaklari,
    ),
    weight: 12,
    choices: <EventChoice>[
      EventChoice(
        id: 'cikti',
        label: 'Çıkışta buluş',
        resultText:
            'Bir saatlik mola üç saate döndü. Artık birliktesiniz; '
            'İlişkiler bölümünde {kisi} görünüyor.',
        happiness: 8,
        charisma: 3,
        startsRomance: true,
      ),
      EventChoice(
        id: 'isi_iste_birakti',
        label: 'İşi işte bırak',
        resultText:
            'Teşekkür edip servise bindin. Vardiya arkadaşlığı vardiya '
            'arkadaşlığı olarak kaldı.',
        happiness: -1,
      ),
    ],
  ),

  // ---------------------------------------------------------------
  // 16-18: okulun son yılları, kararın ağırlığı
  // ---------------------------------------------------------------
  GameEvent(
    id: 'esik_hazirlik_kursu',
    category: EventCategory.okul,
    text:
        'Sınava hazırlık kursu konuşuluyor. Taksitli bir rakam ve haftanın '
        'altı günü.',
    requirement: EventRequirement(
      minAge: 16,
      maxAge: 18,
      requiresSchoolStudent: true,
      livingRelations: <RelationType>{RelationType.anne},
    ),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'kursa_yazildi',
        label: 'Kursa yazıl',
        resultText:
            'Hafta sonların kursa gitti. Deneme sınavlarında sıralaman '
            'yükselirken uykun azaldı.',
        intelligence: 6,
        health: -2,
        happiness: -1,
      ),
      EventChoice(
        id: 'kendi_basina',
        label: 'Kendi başına çalış',
        resultText:
            'Masanın başında kendi programını kurdun. Kimse kontrol '
            'etmedi; her şey sana kaldı.',
        intelligence: 3,
        charisma: 2,
      ),
      EventChoice(
        id: 'vazgecildi',
        label: 'Bu yıl boş geç',
        resultText:
            'Ders dışında kalan vakit arkadaşlara ve maça gitti. Deneme '
            'sonuçların yerinde saydı.',
        happiness: 3,
        intelligence: -2,
      ),
    ],
  ),

  GameEvent(
    id: 'esik_ailenin_plani',
    category: EventCategory.aile,
    text:
        'Evde senin adına bir plan yapılmış: hangi bölüm, hangi şehir, '
        'hangi meslek. Sana soran olmadı.',
    requirement: EventRequirement(
      minAge: 16,
      maxAge: 19,
      livingRelations: <RelationType>{RelationType.anne},
      requireSameHousehold: true,
    ),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'kendi_karari',
        label: 'Kendi kararını söyle',
        resultText:
            'Sofrada uzun bir sessizlik oldu. Sonunda "sen bilirsin" '
            'dendi; ses tonu ikna olmuş değildi.',
        happiness: 2,
        charisma: 4,
        bond: -3,
      ),
      EventChoice(
        id: 'uydu',
        label: 'Plana uy',
        resultText:
            'Tartışma çıkmadı. İçinden "ben bunu istemiyordum" demeyi '
            'uzun süre sürdürdün.',
        happiness: -3,
        bond: 4,
      ),
      EventChoice(
        id: 'ortada_bulustu',
        label: 'Ortasını bul',
        resultText:
            'Bölümü sen seçtin, şehri onlar. İki taraf da yarım razı '
            'oldu.',
        happiness: 1,
        charisma: 2,
        bond: 2,
      ),
    ],
  ),

  GameEvent(
    id: 'esik_mezuniyet_gecesi',
    category: EventCategory.okul,
    text:
        'Mezuniyet gecesi. Salonda müzik, masalarda on iki yıl boyunca '
        'aynı sırayı paylaştığın yüzler var.',
    requirement: EventRequirement(
      minAge: 17,
      maxAge: 19,
    ),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'sabaha_kadar',
        label: 'Sabaha kadar kal',
        resultText:
            'Son şarkıya kadar kaldın. Sabah eve dönerken şehir boştu ve '
            'kimse konuşmuyordu.',
        happiness: 5,
        health: -2,
        charisma: 3,
      ),
      EventChoice(
        id: 'erken_cikti',
        label: 'Erken çık',
        resultText:
            'Fotoğraflar çekilince çıktın. Gecenin kalanını başkalarının '
            'anlattığı kadar bildin.',
        happiness: 1,
        health: 1,
      ),
    ],
  ),

  GameEvent(
    id: 'esik_tercih_listesi',
    category: EventCategory.okul,
    text:
        'Tercih listesi önünde. Üstteki sıralar başka bir şehir, alttakiler '
        'evden çıkmamak demek.',
    requirement: EventRequirement(minAge: 17, maxAge: 20),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'baska_sehir',
        label: 'Başka şehri yaz',
        resultText:
            'Listenin başına uzak bir şehri yazdın. Yazdığın anda içinde '
            'hem korku hem merak vardı.',
        happiness: 2,
        charisma: 3,
        intelligence: 2,
      ),
      EventChoice(
        id: 'evde_kal',
        label: 'Yakını yaz',
        resultText:
            'Evden çıkmayan bir liste yaptın. Masraf azaldı, gözün '
            'uzaklarda kaldı.',
        happiness: 1,
        bond: 3,
      ),
    ],
  ),

  GameEvent(
    id: 'esik_sonuc_bekleme',
    category: EventCategory.kisisel,
    text:
        'Sonuçlar bu gece açıklanacak. Telefonu elinden bırakmıyorsun, '
        'evde kimse yüksek sesle konuşmuyor.',
    requirement: EventRequirement(minAge: 17, maxAge: 20),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'ekranda_bekledi',
        label: 'Ekranın başında bekle',
        resultText:
            'Sayfayı kırk kez yeniledin. Sonuç geldiğinde elin titriyordu.',
        happiness: -1,
        health: -1,
      ),
      EventChoice(
        id: 'uyudu',
        label: 'Yat, sabah bak',
        resultText:
            'Uyumayı başardın. Sabah ilk işin ekrana bakmak oldu ve ev '
            'senden önce uyanmıştı.',
        happiness: 2,
        health: 2,
      ),
    ],
  ),

  GameEvent(
    id: 'esik_usta_cirak',
    category: EventCategory.mahalle,
    text:
        'Mahallenin ustası "yanımda dursan iyi olur" dedi. Okul var, '
        'tezgâh var, ikisi aynı saatte.',
    requirement: EventRequirement(minAge: 16, maxAge: 19),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'tezgaha_gecti',
        label: 'Tezgâhın başına geç',
        resultText:
            'Elin işe alıştı, avucun nasır tuttu. Akşamları yorgun ama '
            'kendi parasını kazanan biri olarak eve döndün.',
        happiness: 3,
        intelligence: 2,
        money: 9000,
        addFlags: <String>{ThresholdFlags.cirakOldu},
      ),
      EventChoice(
        id: 'okula_odaklandi',
        label: 'Okula odaklan',
        resultText:
            'Teşekkür edip reddettin. Usta kırılmadı: "kapı açık" dedi.',
        intelligence: 3,
        charisma: 1,
      ),
    ],
  ),

  GameEvent(
    id: 'esik_ehliyet_kursu',
    category: EventCategory.kisisel,
    text:
        'Ehliyet kursu için yaş geldi. Ücreti var, sınavı var, bir de '
        'direksiyon korkusu var.',
    requirement: EventRequirement(minAge: 17, maxAge: 20),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'kursa_basladi',
        label: 'Kursa başla',
        resultText:
            'Direksiyon dersinde ilk kez şehir içine çıktın. Eller '
            'terliyordu ama araç gidiyordu.',
        happiness: 3,
        charisma: 2,
        addFlags: <String>{ThresholdFlags.ehliyetiGenc},
      ),
      EventChoice(
        id: 'sonra',
        label: 'Sonraya bırak',
        resultText:
            'Bu yıl olmadı. Yolculuklarda hep yan koltukta oturdun.',
        happiness: -1,
      ),
    ],
  ),

  GameEvent(
    id: 'esik_part_time',
    category: EventCategory.yetiskinlik,
    text:
        'Ders dışı saatlerde çalışacak birini arıyorlar: hafta sonu ve '
        'akşam vardiyası.',
    requirement: EventRequirement(minAge: 16, maxAge: 20),
    repeatable: true,
    minAgeGap: 2,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'calisti',
        label: 'İşe gir',
        resultText:
            'İlk haftanın sonunda cebinde kendi kazandığın para vardı. '
            'Ders notların biraz geriledi.',
        money: 6500,
        charisma: 3,
        intelligence: -1,
        health: -1,
      ),
      EventChoice(
        id: 'calismadi',
        label: 'Girme',
        resultText:
            'Vaktini derse ve arkadaşlara ayırdın. Harçlık yine eve '
            'bağlı kaldı.',
        happiness: 1,
      ),
    ],
  ),

  GameEvent(
    id: 'esik_saglik_ihmali',
    category: EventCategory.kisisel,
    text:
        'Son haftalarda üç saat uyuyup ayakta yemek yiyorsun. Baş ağrısı '
        'artık sabahtan başlıyor.',
    requirement: EventRequirement(minAge: 16, maxAge: 20),
    repeatable: true,
    minAgeGap: 3,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'durdu',
        label: 'Bir gün dur',
        resultText:
            'Bir günü hiçbir şey yapmadan geçirdin. Ertesi sabah kafan '
            'daha iyi çalıştı.',
        health: 4,
        happiness: 2,
        intelligence: 1,
      ),
      EventChoice(
        id: 'devam',
        label: 'Aynı tempoyu sürdür',
        resultText:
            'Programı bozmadın. Bedeli uykudan ve mideden çıktı.',
        health: -4,
        intelligence: 2,
      ),
    ],
  ),

  GameEvent(
    id: 'esik_ilk_randevu_hesabi',
    category: EventCategory.yetiskinlik,
    text:
        'Hesap masaya geldi. İkiniz de cüzdanınıza bakıyorsunuz.',
    requirement: EventRequirement(
      minAge: 17,
      maxAge: 20,
      livingRelations: <RelationType>{RelationType.sevgili},
    ),
    repeatable: true,
    minAgeGap: 2,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'sen_odedin',
        label: 'Sen öde',
        resultText:
            'Hesabı sen kapattın. {sahip} itiraz etti ama ısrar etmedi.',
        money: -900,
        bond: 4,
        charisma: 2,
      ),
      EventChoice(
        id: 'bolustunuz',
        label: 'Bölüşün',
        resultText:
            'Ortadan böldünüz. İkiniz de rahatladınız ve aynı akşam '
            'yürüyüşe devam ettiniz.',
        money: -450,
        bond: 3,
        intelligence: 1,
      ),
    ],
  ),

  // ---------------------------------------------------------------
  // 18-20: kendi ayakları, kendi parası
  // ---------------------------------------------------------------
  GameEvent(
    id: 'esik_ilk_basvuru',
    category: EventCategory.yetiskinlik,
    text:
        'İlk iş başvurusunu yazıyorsun. Özgeçmişte doldurulacak yer çok, '
        'yazacak şey az.',
    requirement: EventRequirement(minAge: 18, maxAge: 20),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'durustce',
        label: 'Olduğu gibi yaz',
        resultText:
            'Kısa ama doğru bir özgeçmiş oldu. İki yerden dönüş geldi, '
            'biri görüşmeye çağırdı.',
        charisma: 3,
        intelligence: 2,
      ),
      EventChoice(
        id: 'sisirdi',
        label: 'Biraz şişir',
        resultText:
            'Görüşmede yazdığın bir satır soruldu ve cevabın yetmedi. '
            'Odadan çıkarken yüzün yanıyordu.',
        charisma: -2,
        intelligence: 1,
      ),
    ],
  ),

  GameEvent(
    id: 'esik_evden_cikma',
    category: EventCategory.aile,
    text:
        'Kendi başına yaşamak konuşuluyor: bir oda, bir kira, bir de '
        'evdekilerin endişesi.',
    requirement: EventRequirement(
      minAge: 18,
      maxAge: 20,
      livingRelations: <RelationType>{RelationType.anne},
      requireSameHousehold: true,
    ),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'cikti',
        label: 'Çık',
        resultText:
            'İki valiz ve bir koli eşyayla taşındın. İlk gece sessizlik '
            'hem iyi hem tuhaf geldi.',
        happiness: 3,
        charisma: 4,
        money: -12000,
        bond: -2,
        addFlags: <String>{ThresholdFlags.evdenCiktiGenc},
      ),
      EventChoice(
        id: 'kaldi',
        label: 'Evde kal',
        resultText:
            'Şimdilik aynı evde kaldın. Para birikti, oda küçük kaldı.',
        money: 4000,
        bond: 3,
      ),
    ],
  ),

  GameEvent(
    id: 'esik_arkadaslar_dagildi',
    category: EventCategory.kisisel,
    text:
        'Lise bitti ve grup dağıldı: biri başka şehirde, biri işte, biri '
        'hiç yazmıyor.',
    requirement: EventRequirement(minAge: 18, maxAge: 20),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'arayan_sen_oldu',
        label: 'Arayan sen ol',
        resultText:
            'Grubu sen topladın. Dördü geldi, ikisi gelemedi; gelenler '
            'gece yarısına kadar kaldı.',
        happiness: 3,
        charisma: 3,
        addFlags: <String>{ThresholdFlags.arkadaslarDagildi},
      ),
      EventChoice(
        id: 'biraktin',
        label: 'Kendi akışına bırak',
        resultText:
            'Kimse ilk adımı atmadı. Yazışma bir süre sonra tamamen '
            'durdu.',
        happiness: -2,
        addFlags: <String>{ThresholdFlags.arkadaslarDagildi},
      ),
    ],
  ),

  GameEvent(
    id: 'esik_ilk_kira',
    category: EventCategory.yetiskinlik,
    text:
        'Ayın başı geldi. Kira, fatura ve market aynı haftaya denk '
        'düştü.',
    requirement: EventRequirement(
      minAge: 18,
      maxAge: 20,
      requiredFlags: <String>{ThresholdFlags.evdenCiktiGenc},
    ),
    repeatable: true,
    minAgeGap: 2,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'kendi_odedi',
        label: 'Kendin öde',
        resultText:
            'Hepsini kendi kazandığından ödedin. Hesap bitti, cep '
            'incelmiş ama sırtın dik.',
        money: -8000,
        charisma: 3,
        happiness: 2,
      ),
      EventChoice(
        id: 'eve_haber',
        label: 'Evden destek iste',
        resultText:
            'Bir telefon ettin, para aynı gün geldi. Soru sorulmadı ama '
            'bir şey söylenmedi de.',
        money: 3000,
        bond: 2,
        happiness: -1,
      ),
    ],
  ),

  GameEvent(
    id: 'esik_gece_donusu',
    category: EventCategory.mahalle,
    text:
        'Son otobüsü kaçırdın. Şehir gece bambaşka görünüyor ve cebinde '
        'taksiye yetecek kadar yok.',
    requirement: EventRequirement(minAge: 18, maxAge: 20),
    repeatable: true,
    minAgeGap: 2,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'yurudu',
        label: 'Yürü',
        resultText:
            'Kırk dakika yürüdün. Yolda kimse yoktu; eve varınca ayakların '
            'ağrıyordu ama şehir aklında kaldı.',
        health: -1,
        happiness: 2,
        charisma: 1,
      ),
      EventChoice(
        id: 'arkadasta_kaldi',
        label: 'Arkadaşta kal',
        resultText:
            'Bir koltuk ve bir battaniye bulundu. Sabah kahvaltısı '
            'ikinize yetti.',
        happiness: 3,
        bond: 3,
      ),
    ],
  ),

  GameEvent(
    id: 'esik_ilk_hesap',
    category: EventCategory.yetiskinlik,
    text:
        'Bankada kendi adına bir hesap açtırıyorsun. Kart, şifre, bir de '
        'imzalanacak kâğıtlar.',
    requirement: EventRequirement(minAge: 18, maxAge: 20),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'birikim_hesabi',
        label: 'Birikim için aç',
        resultText:
            'Her ay küçük bir tutar ayırmaya karar verdin. İlk ay '
            'tuttun.',
        intelligence: 3,
        money: -500,
        happiness: 1,
      ),
      EventChoice(
        id: 'gunluk_hesap',
        label: 'Gündelik kullan',
        resultText:
            'Kart cebe girdi, bakiye hep sıfıra yakın gezdi.',
        happiness: 2,
        intelligence: -1,
      ),
    ],
  ),

  GameEvent(
    id: 'esik_kendi_telefonu',
    category: EventCategory.kisisel,
    text:
        'Telefonun ekranı çatladı. Tamir mi, taksitli yeni mi, yoksa '
        'böyle mi devam?',
    requirement: EventRequirement(minAge: 17, maxAge: 20),
    repeatable: true,
    minAgeGap: 3,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'tamir',
        label: 'Tamir ettir',
        resultText:
            'Ekran değişti, telefon iki yıl daha dayandı.',
        money: -2500,
        intelligence: 2,
      ),
      EventChoice(
        id: 'taksit',
        label: 'Taksitli yeni al',
        resultText:
            'Kutusundan çıkan kokuyu sevdin. Taksitler aylarca cebini '
            'yokladı.',
        money: -9000,
        happiness: 3,
      ),
      EventChoice(
        id: 'boyle_devam',
        label: 'Böyle kullan',
        resultText:
            'Çatlağın üstünden okumayı öğrendin. Parmağın bir iki kez '
            'kesildi.',
        happiness: -1,
        health: -1,
      ),
    ],
  ),

  GameEvent(
    id: 'esik_ilk_yolculuk',
    category: EventCategory.kisisel,
    text:
        'İlk kez tek başına şehirlerarası yola çıkıyorsun. Bilet elde, '
        'çanta omuzda.',
    requirement: EventRequirement(minAge: 17, maxAge: 20),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'pencere_kenari',
        label: 'Pencere kenarı',
        resultText:
            'Yol boyunca dışarı baktın. İndiğinde kendini bir yere ait '
            'olmaktan çok yolda hissettin.',
        happiness: 3,
        intelligence: 2,
      ),
      EventChoice(
        id: 'tanistin',
        label: 'Yanındakiyle tanış',
        resultText:
            'Dört saat konuştunuz. İsmini sonradan hatırlamadın ama '
            'anlattıklarını hatırladın.',
        charisma: 4,
        happiness: 2,
      ),
    ],
  ),

  GameEvent(
    id: 'esik_universite_ilk_ay',
    category: EventCategory.okul,
    text:
        'Yeni okulun ilk ayı: kalabalık koridorlar, tanımadığın yüzler ve '
        'kimsenin seni tanımadığı bir sıra.',
    requirement: EventRequirement(
      minAge: 18,
      maxAge: 20,
      requiresSchoolStudent: true,
    ),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'one_oturdu',
        label: 'Ön sıraya otur',
        resultText:
            'Hocanın adını ilk sen öğrendin. İlk vizede bu işe yaradı.',
        intelligence: 4,
        charisma: 1,
      ),
      EventChoice(
        id: 'arkada_kaldi',
        label: 'Arkada kal',
        resultText:
            'İlk ayı kimseyle konuşmadan geçirdin. Sonra sıra arkadaşın '
            'kendisi geldi.',
        happiness: -1,
        charisma: 2,
      ),
    ],
  ),

  GameEvent(
    id: 'esik_kampus_kantin',
    category: EventCategory.okul,
    text:
        'Kantinde aynı masada iki grup var: biri ders çalışıyor, biri '
        'akşam planı yapıyor.',
    requirement: EventRequirement(
      minAge: 18,
      maxAge: 20,
      requiresSchoolStudent: true,
    ),
    repeatable: true,
    minAgeGap: 2,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'ders_masasi',
        label: 'Ders masasına otur',
        resultText:
            'Not paylaşıldı, soru çözüldü. Akşamı kaçırdın, vizeyi '
            'kaçırmadın.',
        intelligence: 4,
        happiness: -1,
      ),
      EventChoice(
        id: 'aksam_plani',
        label: 'Akşam planına katıl',
        resultText:
            'Gece uzadı, sabah dersi kaçtı. O akşam kurulan iki '
            'arkadaşlık yıllarca sürdü.',
        charisma: 4,
        happiness: 3,
        intelligence: -2,
      ),
    ],
  ),

  GameEvent(
    id: 'esik_okulu_birakma',
    category: EventCategory.okul,
    text:
        'Okul istediğin gibi gitmiyor. "Bırakıp çalışsam mı?" sorusu '
        'aklından çıkmıyor.',
    requirement: EventRequirement(
      minAge: 18,
      maxAge: 20,
      requiresSchoolStudent: true,
    ),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'devam_etti',
        label: 'Devam et',
        resultText:
            'Bir dönem daha dişini sıktın. İkinci dönem not ortalaman '
            'toparlandı.',
        intelligence: 3,
        happiness: -1,
      ),
      EventChoice(
        id: 'ara_verdi',
        label: 'Bir dönem ara ver',
        resultText:
            'Bir dönem çalıştın, para biriktirdin ve kafan dağıldı. '
            'Dönüş kararı seni bekliyordu.',
        money: 14000,
        happiness: 2,
        intelligence: -1,
      ),
    ],
  ),

  GameEvent(
    id: 'esik_mahalleden_ayrilma',
    category: EventCategory.mahalle,
    text:
        'Mahalleden ayrılıyorsun. Bakkal, kuaför ve karşı komşu tek tek '
        '"hayırlı olsun" diyor.',
    requirement: EventRequirement(
      minAge: 18,
      maxAge: 20,
      requiredFlags: <String>{ThresholdFlags.evdenCiktiGenc},
    ),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'tek_tek_vedalasti',
        label: 'Tek tek vedalaş',
        resultText:
            'Bütün kapıları çaldın. Birkaçı sarıldı, biri eline poşet '
            'tutuşturdu.',
        happiness: 3,
        charisma: 3,
      ),
      EventChoice(
        id: 'sessizce',
        label: 'Sessizce çık',
        resultText:
            'Bir sabah kamyonet geldi ve gitti. Yıllar sonra o sokaktan '
            'geçerken boğazın düğümlendi.',
        happiness: -1,
        intelligence: 1,
      ),
    ],
  ),

  GameEvent(
    id: 'esik_ilk_maas_paylasimi',
    category: EventCategory.aile,
    text:
        'İlk maaşın hesaba geçti. Evdekiler bir şey istemiyor ama mutfakta '
        'eksikler sayılıyor.',
    requirement: EventRequirement(
      minAge: 18,
      maxAge: 20,
      requiresEmployed: true,
      livingRelations: <RelationType>{RelationType.anne},
    ),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'eve_verdi',
        label: 'Bir kısmını eve ver',
        resultText:
            'Mutfak doldu. Kimse teşekkür etmedi ama o akşam sofra uzun '
            'sürdü.',
        money: -5000,
        bond: 6,
        happiness: 2,
      ),
      EventChoice(
        id: 'kendine',
        label: 'Kendine ayır',
        resultText:
            'Aylardır istediğin şeyi aldın. Eve girerken poşeti biraz '
            'arkada tuttun.',
        happiness: 3,
        bond: -2,
      ),
    ],
  ),

  GameEvent(
    id: 'esik_eski_ogretmen',
    category: EventCategory.okul,
    text:
        'Eski okulunun önünden geçerken öğretmeninle karşılaştın. "Ne '
        'yapıyorsun şimdi?" diye soruyor.',
    requirement: EventRequirement(
      minAge: 18,
      maxAge: 20,
      livingRelations: <RelationType>{RelationType.ogretmen},
    ),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'anlatti',
        label: 'Anlat',
        resultText:
            'Yarım saat konuştunuz. Gitmeden "bana haber ver" dedi ve '
            'telefonunu yazdı.',
        happiness: 3,
        bond: 5,
        charisma: 2,
      ),
      EventChoice(
        id: 'kisa_kesti',
        label: 'Kısa kes',
        resultText:
            '"İyiyim" deyip yürüdün. Köşeyi dönerken keşke daha çok '
            'anlatsaydım diye düşündün.',
        happiness: -1,
      ),
    ],
  ),

  GameEvent(
    id: 'esik_akran_karsilastirmasi',
    category: EventCategory.kisisel,
    text:
        'Sınıf arkadaşlarının kimi okulda, kimi işte, kimi çoktan '
        'kazanıyor. Sen kendini hepsiyle ayrı ayrı karşılaştırıyorsun.',
    requirement: EventRequirement(minAge: 18, maxAge: 20),
    repeatable: true,
    minAgeGap: 2,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'kendi_yolu',
        label: 'Kendi yoluna bak',
        resultText:
            'Listeyi kapattın. Kendi haftana bir plan yazdın ve ona '
            'uydun.',
        happiness: 3,
        intelligence: 2,
      ),
      EventChoice(
        id: 'kiyaslamaya_devam',
        label: 'Kıyaslamaya devam et',
        resultText:
            'Gece geç saatlere kadar başkalarının hayatını okudun. Sabah '
            'kendi işine isteksiz başladın.',
        happiness: -3,
        health: -1,
      ),
    ],
  ),

  // ---------------------------------------------------------------
  // Karşılıklar: eşikteki kararlar yıllar sonra geri döner
  // ---------------------------------------------------------------
  GameEvent(
    id: 'esik_karsilik_ehliyet',
    category: EventCategory.kisisel,
    text:
        'Uzun bir yol planı var ve direksiyonu kim alacak diye '
        'bakıyorlar. Sen gençken öğrenmiştin.',
    requirement: EventRequirement(
      minAge: 21,
      maxAge: 35,
      requiredFlags: <String>{ThresholdFlags.ehliyetiGenc},
      forbiddenFlags: <String>{ThresholdFlags.ehliyetKarsiligi},
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'direksiyona_gecti',
        label: 'Direksiyona geç',
        resultText:
            'Yolun tamamını sen sürdün. Molalarda uyuyanlara bakıp '
            'gülümsedin.',
        happiness: 4,
        charisma: 3,
        health: -1,
        addFlags: <String>{ThresholdFlags.ehliyetKarsiligi},
      ),
      EventChoice(
        id: 'siraya_girdi',
        label: 'Sırayla sürün',
        resultText:
            'Dönüşümlü sürdünüz. Kimse yorulmadı, yol uzun gelmedi.',
        happiness: 2,
        charisma: 2,
        addFlags: <String>{ThresholdFlags.ehliyetKarsiligi},
      ),
    ],
  ),

  GameEvent(
    id: 'esik_karsilik_usta',
    category: EventCategory.yetiskinlik,
    text:
        'Elinle iş yapmayı gençken öğrenmiştin. Şimdi aynı işi yapacak '
        'birini arıyorlar ve ücreti konuşuluyor.',
    requirement: EventRequirement(
      minAge: 21,
      maxAge: 40,
      requiredFlags: <String>{ThresholdFlags.cirakOldu},
      forbiddenFlags: <String>{ThresholdFlags.cirakKarsiligi},
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'isi_aldi',
        label: 'İşi al',
        resultText:
            'İki günde bitirdin, parası peşin ödendi. Adını üç kişiye '
            'daha verdiler.',
        money: 22000,
        charisma: 3,
        happiness: 3,
        addFlags: <String>{ThresholdFlags.cirakKarsiligi},
      ),
      EventChoice(
        id: 'ogretti',
        label: 'Yapmayı öğret',
        resultText:
            'Bir öğleden sonra anlattın. Karşılığında para almadın, '
            'ustalığın konuşuldu.',
        charisma: 5,
        happiness: 2,
        addFlags: <String>{ThresholdFlags.cirakKarsiligi},
      ),
    ],
  ),

  GameEvent(
    id: 'esik_karsilik_evden_cikma',
    category: EventCategory.yetiskinlik,
    text:
        'Yeni taşınan biri "ilk kez tek yaşayacağım" diyor. Sen o işi on '
        'yıl önce yaptın.',
    requirement: EventRequirement(
      minAge: 22,
      maxAge: 45,
      requiredFlags: <String>{ThresholdFlags.evdenCiktiGenc},
      forbiddenFlags: <String>{ThresholdFlags.evdenCikmaKarsiligi},
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'yardim_etti',
        label: 'Taşınmasına yardım et',
        resultText:
            'Koliyi birlikte taşıdınız, ilk akşam yemeğini sen aldın. '
            'Kendi ilk gecen aklına geldi.',
        money: -1500,
        charisma: 4,
        happiness: 3,
        addFlags: <String>{ThresholdFlags.evdenCikmaKarsiligi},
      ),
      EventChoice(
        id: 'akil_verdi',
        label: 'Bildiklerini anlat',
        resultText:
            'Kirayı, faturayı, komşuyu anlattın. "İyi ki konuştum" dedi.',
        charisma: 2,
        happiness: 2,
        addFlags: <String>{ThresholdFlags.evdenCikmaKarsiligi},
      ),
    ],
  ),

  GameEvent(
    id: 'esik_karsilik_arkadaslar',
    category: EventCategory.kisisel,
    text:
        'Lise grubundan bir mesaj geldi: "buluşalım mı?" Aradan yıllar '
        'geçti.',
    requirement: EventRequirement(
      minAge: 25,
      maxAge: 50,
      requiredFlags: <String>{ThresholdFlags.arkadaslarDagildi},
      forbiddenFlags: <String>{ThresholdFlags.arkadasKarsiligi},
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'gitti',
        label: 'Buluşmaya git',
        resultText:
            'Masada altı kişi vardı. İlk yarım saat yabancılık, sonrası '
            'eski sıraya oturmak gibiydi.',
        happiness: 5,
        charisma: 3,
        addFlags: <String>{ThresholdFlags.arkadasKarsiligi},
      ),
      EventChoice(
        id: 'gitmedi',
        label: 'Gitme',
        resultText:
            'O akşam evde kaldın. Ertesi gün paylaşılan fotoğrafa uzun '
            'uzun baktın.',
        happiness: -2,
        addFlags: <String>{ThresholdFlags.arkadasKarsiligi},
      ),
    ],
  ),
];
