/// Çocukluk ve ergenlik havuzu (D-126).
///
/// `docs/EKSIKLER.md` ölçtü: hayatın ilk on sekiz yılı en fakir dönemdi.
/// Gerçek oynanışta 0-5 yaşta yalnızca **11**, 6-12'de **25** farklı olay
/// görülüyordu; oysa 40-59'da 52, 60-79'da 60 vardı. Kimliğin kurulduğu
/// dönem, oyunun en boş kısmıydı.
///
/// Metinler `docs/WRITING_STYLE_TR.md` üslubuna göre yazıldı: anlatı
/// yaşanmış gibi okunur, sistem sonucu ayrı satırda durur, robotik
/// kalıplar ("bu durum seni mutlu etti") kullanılmaz.
///
/// Koşullar gerçeği gözetir: kardeşi olmayana kardeş olayı, babası
/// ölmüşe baba olayı çıkmaz.
library;

import '../domain/models/game_event.dart';
import '../domain/models/relation.dart';


/// Bu havuzun kullandığı hikâye izleri.
abstract final class ChildhoodFlags {
  static const String ilkKelime = 'cocukluk_ilk_kelime';
  static const String ilkKelimeAnne = 'cocukluk_ilk_kelime_anne';
  static const String ilkKelimeBaba = 'cocukluk_ilk_kelime_baba';
  static const String kresSevdi = 'cocukluk_kres_sevdi';
  static const String kresZorlandi = 'cocukluk_kres_zorlandi';
  static const String bisikletOgrendi = 'cocukluk_bisiklet_ogrendi';
  static const String camKirdi = 'cocukluk_cam_kirdi';
  static const String camIItirafEtti = 'cocukluk_cam_itiraf';
  static const String harclikBiriktirdi = 'cocukluk_harclik_biriktirdi';
  static const String karneSakladi = 'cocukluk_karne_sakladi';
  static const String sinifBaskani = 'cocukluk_sinif_baskani';
  static const String ilkHoslanma = 'ergen_ilk_hoslanma';
  static const String cesaretEdemedi = 'ergen_cesaret_edemedi';
  static const String reddedildi = 'ergen_reddedildi';
  static const String grubaGirdi = 'ergen_gruba_girdi';
  static const String dislandi = 'ergen_dislandi';
  static const String ilkYalan = 'ergen_ilk_yalan';
  static const String yazIsiIstedi = 'ergen_yaz_isi_istedi';
  static const String sigarayaHayir = 'ergen_sigaraya_hayir';
  static const String ogretmenleTers = 'ergen_ogretmenle_ters';
}

/// Bu havuzun kilitlediği kişi rolleri.
abstract final class ChildhoodRoles {
  static const String cocuklukArkadasi = 'cocukluk_arkadasi';
  static const String ilkHoslandigi = 'ergen_ilk_hoslandigi';
}

/// 0-17 yaş olayları.
const List<GameEvent> kChildhoodEvents = <GameEvent>[
  // =================================================================
  // 0-5 YAŞ
  // =================================================================
  GameEvent(
    id: 'cocukluk_ilk_kelime',
    category: EventCategory.aile,
    text: 'Bütün gün "ba-ba-ba" deyip durdun. Sonra bir ara odada '
        'sessizlik oldu ve ağzından tek bir düzgün kelime çıktı.\n\n'
        'Evdekiler donup kaldı.',
    requirement: EventRequirement(
      minAge: 1,
      maxAge: 2,
      forbiddenFlags: <String>{ChildhoodFlags.ilkKelime},
    ),
    weight: 9,
    choices: <EventChoice>[
      EventChoice(
        id: 'anne',
        label: '"Anne"',
        resultText: 'Annen mutfaktan koşarak geldi. O günü yıllarca '
            'anlatacak.',
        happiness: 3,
        bond: 5,
        addFlags: <String>{
          ChildhoodFlags.ilkKelime,
          ChildhoodFlags.ilkKelimeAnne,
        },
      ),
      EventChoice(
        id: 'baba',
        label: '"Baba"',
        resultText: 'Baban telefonu kapattı, seni havaya kaldırdı. '
            '"Duydunuz mu, duydunuz mu?"',
        happiness: 3,
        bond: 5,
        addFlags: <String>{
          ChildhoodFlags.ilkKelime,
          ChildhoodFlags.ilkKelimeBaba,
        },
      ),
      EventChoice(
        id: 'hayir',
        label: '"Hayır"',
        resultText: 'İlk kelimen "hayır" oldu. Evde kimse şaşırmadı.',
        happiness: 2,
        charisma: 2,
        addFlags: <String>{ChildhoodFlags.ilkKelime},
      ),
    ],
  ),

  GameEvent(
    id: 'cocukluk_ilk_adim',
    category: EventCategory.aile,
    text: 'Koltuğa tutunarak doğruldun. Karşıda annen elini uzatmış '
        'bekliyor, aranızda bir buçuk metre var.',
    requirement: EventRequirement(minAge: 1, maxAge: 2),
    weight: 8,
    choices: <EventChoice>[
      EventChoice(
        id: 'yuru',
        label: 'Bırak, yürü',
        resultText: 'Üç adım attın, dördüncüde oturdun. Ama attın.',
        happiness: 3,
        health: 2,
        bond: 4,
      ),
      EventChoice(
        id: 'emekle',
        label: 'Emeklemek daha garanti',
        resultText: 'Emekleyerek gittin. Hızlıydı, kabul.',
        happiness: 2,
      ),
    ],
  ),

  GameEvent(
    id: 'cocukluk_oyuncak_kavgasi',
    category: EventCategory.aile,
    text: 'Misafir geldi, çocuğu da geldi. Ve doğrudan senin kırmızı '
        'arabana el attı.',
    requirement: EventRequirement(minAge: 3, maxAge: 5),
    weight: 7,
    choices: <EventChoice>[
      EventChoice(
        id: 'ver',
        label: 'Ver, oynasın',
        resultText: 'Uzattın. Annen gururla baktı, sen biraz içerledin.',
        happiness: -1,
        charisma: 3,
      ),
      EventChoice(
        id: 'cek',
        label: 'Elinden çek',
        resultText: 'Arabayı kaptın. Ortalık karıştı, sonra tost geldi, '
            'herkes unuttu.',
        happiness: 1,
        charisma: -1,
      ),
      EventChoice(
        id: 'takas',
        label: 'Başka oyuncak ver',
        resultText: 'Ona ayıyı verdin, arabayı kendine sakladın. '
            'Küçük yaşta pazarlık.',
        happiness: 2,
        intelligence: 2,
      ),
    ],
  ),

  GameEvent(
    id: 'cocukluk_kardes_kiskanclik',
    category: EventCategory.aile,
    text: 'Herkes {kisi} ile ilgileniyor. Sen tam ortada duruyorsun ve '
        'kimse fark etmiyor.',
    requirement: EventRequirement(
      minAge: 3,
      maxAge: 6,
      livingRelations: <RelationType>{RelationType.kardes},
      requireSameHousehold: true,
    ),
    weight: 7,
    choices: <EventChoice>[
      EventChoice(
        id: 'agla',
        label: 'Ağla',
        resultText: 'İşe yaradı. Kucağa alındın.',
        happiness: 2,
        bond: -1,
      ),
      EventChoice(
        id: 'katil',
        label: 'Sen de yanına git',
        resultText: 'Yanına oturdun. İkinize birden bakmaya başladılar.',
        happiness: 2,
        bond: 4,
      ),
      EventChoice(
        id: 'kos',
        label: 'Odana kaç',
        resultText: 'Odaya gittin. Beş dakika sonra baban kapıda bitti.',
        happiness: -1,
        bond: 1,
      ),
    ],
  ),

  GameEvent(
    id: 'cocukluk_ilk_kres',
    category: EventCategory.okul,
    text: 'Kreşin kapısında annenin elini bırakmıyorsun. İçeriden '
        'bağıra çağıra oynayan çocuk sesleri geliyor.',
    requirement: EventRequirement(
      minAge: 4,
      maxAge: 5,
      forbiddenFlags: <String>{
        ChildhoodFlags.kresSevdi,
        ChildhoodFlags.kresZorlandi,
      },
    ),
    weight: 8,
    choices: <EventChoice>[
      EventChoice(
        id: 'gir',
        label: 'Bırak elini, gir',
        resultText: 'İçeri girdin. Yarım saat sonra annen dışarıda '
            'ağlıyordu, sen içeride kule yapıyordun.',
        happiness: 2,
        charisma: 3,
        addFlags: <String>{ChildhoodFlags.kresSevdi},
      ),
      EventChoice(
        id: 'birakma',
        label: 'Bırakma',
        resultText: 'Kapıda yirmi dakika geçti. Sonunda girdin ama '
            'o gün pek konuşmadın.',
        happiness: -1,
        bond: 2,
        addFlags: <String>{ChildhoodFlags.kresZorlandi},
      ),
    ],
  ),

  GameEvent(
    id: 'cocukluk_gece_korkusu',
    category: EventCategory.aile,
    text: 'Işık kapandıktan sonra dolabın gölgesi bir şeye benzedi. '
        'Yorganı çeneye kadar çektin.',
    requirement: EventRequirement(minAge: 3, maxAge: 7),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'cagir',
        label: 'Seslen',
        resultText: 'Baban geldi, dolabı açıp gösterdi: "Bak, mont." '
            'İkna olmadın ama uyudun.',
        happiness: 1,
        bond: 3,
      ),
      EventChoice(
        id: 'sakla',
        label: 'Yorganın altına gir',
        resultText: 'Sabaha kadar yorganın altında kaldın. Sabah '
            'kimseye söylemedin.',
        happiness: -1,
        health: -1,
      ),
    ],
  ),

  GameEvent(
    id: 'cocukluk_parkta_dustu',
    category: EventCategory.mahalle,
    text: 'Kaydıraktan ters indin. Diz kanıyor, etraf bakıyor.',
    requirement: EventRequirement(minAge: 3, maxAge: 7),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'agla',
        label: 'Bas ağlamayı',
        resultText: 'Bütün park duydu. Dizine üflendi, eve gidildi.',
        happiness: -1,
        bond: 2,
      ),
      EventChoice(
        id: 'kalk',
        label: 'Kalk, devam et',
        resultText: 'Tozunu silkeledin, tekrar merdivene yürüdün. '
            'Yandaki teyze "aferin" dedi.',
        happiness: 1,
        health: -1,
        charisma: 2,
      ),
    ],
  ),

  GameEvent(
    id: 'cocukluk_dededen_seker',
    category: EventCategory.aile,
    text: '{sahip} {kisi} seni mutfağa çekti, parmağını dudağına '
        'götürdü: "Annene yok."',
    requirement: EventRequirement(
      minAge: 3,
      maxAge: 8,
      livingRelations: <RelationType>{
        RelationType.anneanne,
        RelationType.babaanne,
        RelationType.anneTarafiDede,
        RelationType.babaTarafiDede,
      },
    ),
    weight: 7,
    choices: <EventChoice>[
      EventChoice(
        id: 'al',
        label: 'Al, ye',
        resultText: 'İki tane aldın. Akşam iştahın yoktu, annen '
            'sebebini biliyordu.',
        happiness: 3,
        health: -1,
        bond: 5,
      ),
      EventChoice(
        id: 'soyle',
        label: 'Annene söyle',
        resultText: 'Söyledin. {kisi} sana uzun uzun baktı. '
            '"Sen de bir tanesin ha."',
        happiness: 1,
        bond: -2,
      ),
    ],
  ),

  GameEvent(
    id: 'cocukluk_duvara_resim',
    category: EventCategory.aile,
    text: 'Salonun duvarı kocaman ve bomboş. Elinde de yepyeni bir '
        'keçeli kalem var.',
    requirement: EventRequirement(minAge: 3, maxAge: 6),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'ciz',
        label: 'Çiz',
        resultText: 'Bir ev, bir güneş, üç çöp adam. Annen duvara '
            'baktı, sonra sana baktı, sonra derin bir nefes aldı.',
        happiness: 3,
        charisma: 1,
      ),
      EventChoice(
        id: 'kagit',
        label: 'Kâğıt bul',
        resultText: 'Kâğıda çizdin. Buzdolabına asıldı, yıllarca orada '
            'kaldı.',
        happiness: 2,
        intelligence: 2,
        bond: 2,
      ),
    ],
  ),

  GameEvent(
    id: 'cocukluk_hayvanla_ilk_temas',
    category: EventCategory.mahalle,
    text: 'Apartman girişinde bir kedi oturmuş, sana bakıyor. '
        'Kaçmıyor da.',
    requirement: EventRequirement(minAge: 3, maxAge: 8),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'sev',
        label: 'Uzat elini',
        resultText: 'Başını eline sürdü. O gün eve geç gittin.',
        happiness: 3,
        charisma: 1,
      ),
      EventChoice(
        id: 'mama',
        label: 'İçeriden bir şey getir',
        resultText: 'Mutfaktan ne bulduysan getirdin. Kedi ertesi gün '
            'de aynı yerdeydi.',
        happiness: 2,
        charisma: 2,
      ),
      EventChoice(
        id: 'kork',
        label: 'Uzak dur',
        resultText: 'Duvara yaslanıp geçtin. Kedi arkandan baktı.',
        happiness: -1,
      ),
    ],
  ),

  GameEvent(
    id: 'cocukluk_bayram_harcligi',
    category: EventCategory.aile,
    text: 'Bayram sabahı. El öpüldü, cebe bir şeyler girdi. Toplam '
        'ne kadar olduğunu sayman yarım saat sürdü.',
    requirement: EventRequirement(minAge: 4, maxAge: 12),
    weight: 7,
    choices: <EventChoice>[
      EventChoice(
        id: 'harca',
        label: 'Hepsini bakkalda bitir',
        resultText: 'Akşama kadar dayanmadı. Ama o gün çok mutluydun.',
        happiness: 4,
        money: -200,
        health: -1,
      ),
      EventChoice(
        id: 'kumbara',
        label: 'Kumbaraya at',
        resultText: 'Kumbaraya attın. Sallayınca çıkan ses hoşuna gitti.',
        happiness: 1,
        money: 600,
        intelligence: 1,
      ),
      EventChoice(
        id: 'anneye',
        label: 'Anneme vereyim',
        resultText: '"Sende dursun" dedin. Annen aldı, "senin için '
            'saklıyorum" dedi. Saklandı mı, orası meçhul.',
        happiness: 1,
        bond: 4,
      ),
    ],
  ),

  GameEvent(
    id: 'cocukluk_bir_sey_kirdi',
    category: EventCategory.aile,
    text: 'Salonda koşuyordun. Sehpanın üstündeki vazo artık yerde ve '
        'üç parça.',
    requirement: EventRequirement(minAge: 3, maxAge: 9),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'itiraf',
        label: 'Koşup söyle',
        resultText: '"Ben kırdım." Annen bir an durdu. "Kesik var mı '
            'elinde?" Vazoyu sormadı bile.',
        happiness: 1,
        bond: 5,
        intelligence: 1,
      ),
      EventChoice(
        id: 'sakla',
        label: 'Parçaları sakla',
        resultText: 'Parçaları koltuğun altına ittin. Üç gün boyunca '
            'o koltuğa oturan herkesi izledin.',
        happiness: -2,
        charisma: 1,
      ),
      EventChoice(
        id: 'kedi',
        label: '"Kedi yaptı"',
        resultText: 'Evde kedi yok. Bunu sen de fark ettin ama '
            'söyledikten sonra.',
        happiness: -1,
        bond: -3,
      ),
    ],
  ),

  // =================================================================
  // 6-12 YAŞ
  // =================================================================
  // İlk kelime seçimi yıllar sonra hatırlanır: seçim gerçekten iz
  // bırakıyor (D-126).
  GameEvent(
    id: 'cocukluk_ilk_kelime_anisi_anne',
    category: EventCategory.aile,
    text: 'Misafir var. Annen yine o hikâyeyi anlatıyor: "Bunun ilk '
        'kelimesi \'anne\'ydi." Baban arkadan seslendi: "Ben de '
        'oradaydım ama neyse."',
    requirement: EventRequirement(
      minAge: 6,
      maxAge: 11,
      requiredFlags: <String>{ChildhoodFlags.ilkKelimeAnne},
      livingRelations: <RelationType>{RelationType.anne},
    ),
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'utan',
        label: 'Kızarıp sus',
        resultText: 'Yastığın arkasına saklandın. Hikâye yine de bitti '
            've herkes güldü.',
        happiness: 1,
        bond: 1,
      ),
      EventChoice(
        id: 'sahiplen',
        label: '"Doğru, öyleydi"',
        resultText: 'Başını kaldırıp onayladın. Annenin yüzü güldü, '
            'baban kafasını salladı.',
        happiness: 2,
        charisma: 2,
        bond: 3,
      ),
    ],
  ),
  GameEvent(
    id: 'cocukluk_ilk_kelime_anisi_baba',
    category: EventCategory.aile,
    text: 'Baban yine anlatıyor: "İlk lafı \'baba\'ydı, ben duydum." '
        'Annen mutfaktan "Öyle mi acaba" diye seslendi.',
    requirement: EventRequirement(
      minAge: 6,
      maxAge: 11,
      requiredFlags: <String>{ChildhoodFlags.ilkKelimeBaba},
      livingRelations: <RelationType>{RelationType.baba},
    ),
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'babani_tut',
        label: 'Babanı tut',
        resultText: '"Babam duydu" dedin. Baban koltukta bir karış '
            'yükseldi.',
        happiness: 2,
        bond: 3,
      ),
      EventChoice(
        id: 'anneyi_tut',
        label: 'Anneni tut',
        resultText: '"Bence annemdi" dedin. Mutfaktan bir kahkaha geldi, '
            'baban gazeteye gömüldü.',
        happiness: 2,
        charisma: 2,
        bond: -1,
      ),
    ],
  ),
  GameEvent(
    id: 'cocukluk_mahallede_top',
    category: EventCategory.mahalle,
    text: 'Sokakta takım kuruluyor. İki kaptan sırayla isim sayıyor ve '
        'sen hâlâ kenarda bekliyorsun.',
    requirement: EventRequirement(minAge: 7, maxAge: 13),
    weight: 8,
    choices: <EventChoice>[
      EventChoice(
        id: 'bekle',
        label: 'Bekle, sıra gelir',
        resultText: 'Son seçildin ama seçildin. İki gol attın, kimse '
            'nasıl seçildiğini hatırlamadı.',
        happiness: 3,
        health: 2,
        charisma: 2,
      ),
      EventChoice(
        id: 'kaleye',
        label: '"Ben kaleye geçerim"',
        resultText: 'Kaleye geçtin. Kimse kaleci olmak istemediği için '
            'o günden sonra hep senindi.',
        happiness: 2,
        health: 2,
        charisma: 3,
      ),
      EventChoice(
        id: 'git',
        label: 'Eve git',
        resultText: 'Yürüdün. Arkandan "nereye ya" diye seslendiler ama '
            'dönmedin.',
        happiness: -2,
      ),
    ],
  ),

  GameEvent(
    id: 'cocukluk_bisiklet',
    category: EventCategory.mahalle,
    text: 'Baban arkadan tutuyor, sen pedal çeviriyorsun. Bir ara '
        'arkaya baktın — kimse yok.',
    requirement: EventRequirement(
      minAge: 6,
      maxAge: 11,
      forbiddenFlags: <String>{ChildhoodFlags.bisikletOgrendi},
    ),
    weight: 8,
    choices: <EventChoice>[
      EventChoice(
        id: 'devam',
        label: 'Bakma, devam et',
        resultText: 'Otuz metre daha gittin. Sonra düştün. Ama artık '
            'biliyorsun.',
        happiness: 4,
        health: 1,
        bond: 3,
        addFlags: <String>{ChildhoodFlags.bisikletOgrendi},
      ),
      EventChoice(
        id: 'fren',
        label: 'Panikle, fren yap',
        resultText: 'Ayağını yere bastın, duruldu. Baban koşarak geldi: '
            '"Gidiyordun be!"',
        happiness: 1,
        bond: 2,
      ),
    ],
  ),

  GameEvent(
    id: 'cocukluk_okul_gezisi',
    category: EventCategory.okul,
    text: 'Yarın gezi var. Formu imzalatman ve parayı götürmen lazım. '
        'Form üç gündür çantada.',
    requirement: EventRequirement(
      minAge: 7,
      maxAge: 13,
      requiresSchoolStudent: true,
    ),
    weight: 7,
    choices: <EventChoice>[
      EventChoice(
        id: 'ver',
        label: 'Akşam söyle',
        resultText: 'Söyledin. Biraz homurdanma oldu ama sabah para '
            'masadaydı.',
        happiness: 3,
        money: -400,
        intelligence: 1,
      ),
      EventChoice(
        id: 'sus',
        label: 'Hiç söyleme',
        resultText: 'Gezi günü sınıf boşaldı, sen kütüphanede oturdun. '
            'Kimse sebebini sormadı.',
        happiness: -3,
        intelligence: 2,
      ),
    ],
  ),

  GameEvent(
    id: 'cocukluk_ogretmenden_azar',
    category: EventCategory.okul,
    text: 'Arka sırada konuşurken yakalandın. Öğretmen tebeşiri bıraktı '
        've sınıf sessizleşti.',
    requirement: EventRequirement(
      minAge: 7,
      maxAge: 14,
      requiresSchoolStudent: true,
    ),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'ozur',
        label: 'Özür dile',
        resultText: '"Özür dilerim hocam." Konu kapandı. Teneffüste '
            'arkadaşların "korktun" dedi.',
        happiness: -1,
        charisma: 1,
        intelligence: 1,
      ),
      EventChoice(
        id: 'inkar',
        label: '"Ben konuşmuyordum"',
        resultText: 'Bütün sınıf sana baktı. Öğretmen de. Kimse '
            'inanmadı.',
        happiness: -2,
        charisma: -1,
      ),
    ],
  ),

  GameEvent(
    id: 'cocukluk_ogretmenden_ovgu',
    category: EventCategory.okul,
    text: 'Öğretmen defterini kaldırdı: "Arkadaşlar, bakın bu nasıl '
        'yapılmış."',
    requirement: EventRequirement(
      minAge: 7,
      maxAge: 14,
      requiresSchoolStudent: true,
    ),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'gurur',
        label: 'Gururlan',
        resultText: 'Kulakların kızardı ama iyi geldi. O defteri uzun '
            'süre özenerek tuttun.',
        happiness: 3,
        intelligence: 3,
      ),
      EventChoice(
        id: 'utan',
        label: 'Sıranın altına gir',
        resultText: 'Övülmek de bir tuhaf geliyor. Başını kaldırmadın.',
        happiness: 1,
        intelligence: 2,
        charisma: -1,
      ),
    ],
  ),

  GameEvent(
    id: 'cocukluk_sira_arkadasi',
    category: EventCategory.okul,
    text: 'Yeni dönem, yeni oturma düzeni. Yanına hiç konuşmadığın biri '
        'oturdu ve kalemini düşürdü.',
    requirement: EventRequirement(
      minAge: 7,
      maxAge: 14,
      requiresSchoolStudent: true,
    ),
    weight: 7,
    choices: <EventChoice>[
      EventChoice(
        id: 'al',
        label: 'Kalemi al, uzat',
        resultText: '"Sağ ol." O gün teneffüste beraber çıktınız. '
            'Bazı arkadaşlıklar böyle başlıyor.',
        happiness: 2,
        charisma: 2,
        startsSchoolFriendship: true,
        rememberPersonAs: ChildhoodRoles.cocuklukArkadasi,
      ),
      EventChoice(
        id: 'bakma',
        label: 'Görmezden gel',
        resultText: 'Kendi aldı. İkiniz de bir şey demediniz.',
        happiness: -1,
      ),
    ],
  ),

  GameEvent(
    id: 'cocukluk_arkadasla_kusme',
    category: EventCategory.okul,
    text: '{kisi} ile bir hiç yüzünden tartıştınız. Şimdi teneffüste '
        'ikiniz de ayrı köşelerde duruyorsunuz.',
    requirement: EventRequirement(
      minAge: 8,
      maxAge: 15,
      livingRelations: <RelationType>{
        RelationType.arkadas,
        RelationType.sinifArkadasi,
      },
    ),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'barisik',
        label: 'İlk sen git',
        resultText: 'Yanına gittin. "Ya boş ver." O da "boş ver" dedi. '
            'Konu kapandı.',
        happiness: 3,
        bond: 6,
        charisma: 2,
      ),
      EventChoice(
        id: 'bekle',
        label: 'O gelsin',
        resultText: 'İki gün kimse adım atmadı. Üçüncü gün zaten '
            'unutuldu, ama arada bir şey eksildi.',
        happiness: -1,
        bond: -4,
      ),
    ],
  ),

  GameEvent(
    id: 'cocukluk_kantinde_para',
    category: EventCategory.okul,
    text: 'Kantin sırasındasın, sıra sana geldi. Cebini yokladın — '
        'para yok.',
    requirement: EventRequirement(
      minAge: 7,
      maxAge: 15,
      requiresSchoolStudent: true,
    ),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'arkadas',
        label: 'Arkadaşından iste',
        resultText: '"Yarın veririm." Verdi. Yarın da unuttun, o da '
            'hiç hatırlatmadı.',
        happiness: 1,
        bond: 2,
        charisma: 1,
      ),
      EventChoice(
        id: 'cik',
        label: 'Sıradan çık',
        resultText: 'Sessizce çıktın. O gün tenefüsler uzun geçti.',
        happiness: -2,
      ),
    ],
  ),

  GameEvent(
    id: 'cocukluk_karne_gunu',
    category: EventCategory.okul,
    text: 'Karne dağıtıldı. Katlayıp cebe soktun, eve kadar bir kere '
        'bile açmadın.',
    requirement: EventRequirement(
      minAge: 7,
      maxAge: 14,
      requiresSchoolStudent: true,
      forbiddenFlags: <String>{ChildhoodFlags.karneSakladi},
    ),
    weight: 7,
    choices: <EventChoice>[
      EventChoice(
        id: 'goster',
        label: 'Eve girer girmez göster',
        resultText: 'Uzattın. Baban tek tek okudu, sonunda "eh" dedi. '
            'O "eh" iyiydi.',
        happiness: 2,
        bond: 3,
        intelligence: 1,
      ),
      EventChoice(
        id: 'sakla',
        label: 'Çantada kalsın',
        resultText: 'Üç gün sordular, üç gün "vermediler" dedin. '
            'Dördüncü gün öğretmen aradı.',
        happiness: -3,
        bond: -4,
        addFlags: <String>{ChildhoodFlags.karneSakladi},
      ),
    ],
  ),

  GameEvent(
    id: 'cocukluk_kardes_kavgasi',
    category: EventCategory.aile,
    text: 'Kumanda yüzünden {sahipk} {kisi} ile itişiyorsunuz. '
        'Annen mutfaktan "susun!" diye bağırdı.',
    requirement: EventRequirement(
      minAge: 6,
      maxAge: 15,
      livingRelations: <RelationType>{RelationType.kardes},
      requireSameHousehold: true,
    ),
    weight: 7,
    choices: <EventChoice>[
      EventChoice(
        id: 'birak',
        label: 'Bırak, izlesin',
        resultText: 'Kumandayı bıraktın. Yarım saat sonra yanına '
            'oturdu, ikiniz de aynı şeyi izlediniz.',
        happiness: 1,
        bond: 5,
      ),
      EventChoice(
        id: 'cek',
        label: 'Çek elinden',
        resultText: 'Kaptın. Kumanda sende, akşam boyunca konuşan yok.',
        happiness: 1,
        bond: -4,
      ),
      EventChoice(
        id: 'anneye',
        label: 'Anneye şikâyet et',
        resultText: 'İkiniz de ceza aldınız. Kimse televizyon '
            'izleyemedi.',
        happiness: -2,
        bond: -2,
      ),
    ],
  ),

  GameEvent(
    id: 'cocukluk_komsunun_cami',
    category: EventCategory.mahalle,
    text: 'Top fena kalktı. Sonra cam sesi geldi. Sokakta bir anda '
        'kimse kalmadı — bir sen duruyorsun.',
    requirement: EventRequirement(
      minAge: 7,
      maxAge: 13,
      forbiddenFlags: <String>{ChildhoodFlags.camKirdi},
    ),
    weight: 7,
    choices: <EventChoice>[
      EventChoice(
        id: 'zile_bas',
        label: 'Zile bas, söyle',
        resultText: 'Kapıyı çaldın. Adam önce kızdı, sonra sustu: '
            '"Sen söyledin ya, tamam." Camı baban ödedi ama sana '
            'kızmadı.',
        happiness: 1,
        charisma: 4,
        money: -300,
        addFlags: <String>{
          ChildhoodFlags.camKirdi,
          ChildhoodFlags.camIItirafEtti,
        },
      ),
      EventChoice(
        id: 'kac',
        label: 'Kaç',
        resultText: 'Nefes nefese eve girdin. Üç gün o sokaktan '
            'geçmedin.',
        happiness: -2,
        health: 1,
        addFlags: <String>{ChildhoodFlags.camKirdi},
      ),
    ],
  ),

  GameEvent(
    id: 'cocukluk_harclik_biriktirme',
    category: EventCategory.kisisel,
    text: 'Vitrinde gözüne kestirdiğin bir şey var. Fiyatı, bir '
        'haftalık harçlığının üç katı.',
    requirement: EventRequirement(
      minAge: 8,
      maxAge: 15,
      forbiddenFlags: <String>{ChildhoodFlags.harclikBiriktirdi},
    ),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'biriktir',
        label: 'Biriktir',
        resultText: 'Üç hafta bakkala uğramadın. Aldığın gün elinde '
            'taşırken bir tuhaf gurur vardı.',
        happiness: 3,
        intelligence: 3,
        money: -1200,
        addFlags: <String>{ChildhoodFlags.harclikBiriktirdi},
      ),
      EventChoice(
        id: 'vazgec',
        label: 'Vazgeç',
        resultText: 'Bir hafta sonra aklından çıkmıştı zaten.',
        happiness: -1,
        money: 400,
      ),
    ],
  ),

  GameEvent(
    id: 'cocukluk_musamere',
    category: EventCategory.okul,
    text: '23 Nisan müsameresi için öğretmen rol dağıtıyor. Elini '
        'kaldıranlar var.',
    requirement: EventRequirement(
      minAge: 7,
      maxAge: 12,
      requiresSchoolStudent: true,
    ),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'kaldir',
        label: 'Elini kaldır',
        resultText: 'Şiir sana düştü. Sahnede iki satır unuttun ama '
            'kimse fark etmedi; alkış aynı alkıştı.',
        happiness: 3,
        charisma: 4,
      ),
      EventChoice(
        id: 'kaldirma',
        label: 'Kaldırma',
        resultText: 'Perdeyi çeken sen oldun. O da bir görev.',
        happiness: 1,
        charisma: -1,
      ),
    ],
  ),

  GameEvent(
    id: 'cocukluk_sinif_baskanligi',
    category: EventCategory.okul,
    text: 'Sınıf başkanlığı için aday olanlar tahtaya çıkıyor. '
        'Öğretmen "başka?" diye soruyor.',
    requirement: EventRequirement(
      minAge: 8,
      maxAge: 14,
      requiresSchoolStudent: true,
      forbiddenFlags: <String>{ChildhoodFlags.sinifBaskani},
    ),
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'aday',
        label: 'Aday ol',
        resultText: 'Çıktın, üç cümle kurdun. Oy sayımında iki fark '
            'kazandın.',
        happiness: 3,
        charisma: 5,
        intelligence: 1,
        addFlags: <String>{ChildhoodFlags.sinifBaskani},
      ),
      EventChoice(
        id: 'destekle',
        label: 'Arkadaşını destekle',
        resultText: 'Onun için oy topladın. Kazandı, ilk işi seni '
            'yardımcı yapmak oldu.',
        happiness: 2,
        charisma: 2,
        bond: 4,
      ),
      EventChoice(
        id: 'ilgilenme',
        label: 'İlgilenme',
        resultText: 'Sıranda oturdun. Kim başkan oldu, hatırlamıyorsun '
            'bile.',
        happiness: -1,
        charisma: -1,
      ),
    ],
  ),

  GameEvent(
    id: 'cocukluk_ilk_market',
    category: EventCategory.mahalle,
    text: 'Annen eline bir liste ve para tutuşturdu: "Yalnız git, '
        'karşıdan karşıya dikkat."',
    requirement: EventRequirement(minAge: 7, maxAge: 11),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'tam',
        label: 'Listeyi harfiyen uygula',
        resultText: 'Her şeyi aldın, para üstünü de getirdin. Annen '
            'saydı, sonra sana baktı: "Aferin."',
        happiness: 3,
        intelligence: 3,
        bond: 3,
      ),
      EventChoice(
        id: 'ekstra',
        label: 'Bir de kendine bir şey al',
        resultText: 'Listeye olmayan bir şey de geldi. Annen gördü, '
            'bir şey demedi ama gördü.',
        happiness: 3,
        money: -150,
        bond: -1,
      ),
    ],
  ),

  GameEvent(
    id: 'cocukluk_aile_pikniği',
    category: EventCategory.aile,
    text: 'Sabah erken kalkıldı, bagaj dolduruldu. Yolda hep aynı '
        'kaset çaldı.',
    requirement: EventRequirement(
      minAge: 5,
      maxAge: 14,
      livingRelations: <RelationType>{RelationType.anne, RelationType.baba},
      requireSameHousehold: true,
    ),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'kos',
        label: 'Bütün gün koş',
        resultText: 'Akşam arabada uyuyakaldın. Eve nasıl girdiğini '
            'hatırlamıyorsun.',
        happiness: 4,
        health: 2,
        bond: 3,
      ),
      EventChoice(
        id: 'yanlarinda',
        label: 'Büyüklerin yanında otur',
        resultText: 'Konuşulanların yarısını anlamadın ama dinlemek '
            'hoşuna gitti.',
        happiness: 2,
        intelligence: 2,
        bond: 4,
      ),
    ],
  ),

  GameEvent(
    id: 'cocukluk_dusuk_not',
    category: EventCategory.okul,
    text: 'Sınav kâğıdı geldi. Sayıyı görünce kâğıdı hemen ters '
        'çevirdin.',
    requirement: EventRequirement(
      minAge: 8,
      maxAge: 15,
      requiresSchoolStudent: true,
    ),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'goster',
        label: 'Eve götür, göster',
        resultText: '"Neden böyle olmuş?" diye sordular. Cevabını sen '
            'de bilmiyordun ama konuşunca rahatladın.',
        happiness: -1,
        bond: 3,
        intelligence: 2,
      ),
      EventChoice(
        id: 'imza',
        label: 'İmzayı kendin at',
        resultText: 'Babanın imzasını taklit ettin. Benzemedi. '
            'Öğretmen baktı, bir şey demedi — sadece baktı.',
        happiness: -2,
        charisma: 1,
        bond: -3,
      ),
      EventChoice(
        id: 'calis',
        label: 'Kimseye söyleme, telafi et',
        resultText: 'Sonraki sınava çalıştın. Notu kimse sormadı ama '
            'sen biliyorsun.',
        happiness: 1,
        intelligence: 4,
      ),
    ],
  ),

  // =================================================================
  // 13-17 YAŞ
  // =================================================================
  GameEvent(
    id: 'ergen_ilk_hoslanma',
    category: EventCategory.okul,
    text: 'Sınıfta biri var. Adını duyunca kulağın kabarıyor, ama '
        'bunu kimseye söylemedin.',
    requirement: EventRequirement(
      minAge: 13,
      maxAge: 17,
      requiresSchoolStudent: true,
      livingRelations: <RelationType>{RelationType.sinifArkadasi},
      forbiddenFlags: <String>{ChildhoodFlags.ilkHoslanma},
    ),
    weight: 8,
    choices: <EventChoice>[
      EventChoice(
        id: 'konus',
        label: 'Bir şey söyle',
        resultText: 'İki cümle kurdun, ikisi de saçmaydı. Ama güldü.',
        happiness: 3,
        charisma: 3,
        bond: 4,
        addFlags: <String>{ChildhoodFlags.ilkHoslanma},
        rememberPersonAs: ChildhoodRoles.ilkHoslandigi,
      ),
      EventChoice(
        id: 'bekle',
        label: 'Şimdilik kendine sakla',
        resultText: 'Defterin arkasına bir şeyler karaladın, sonra '
            'sildin.',
        happiness: 1,
        addFlags: <String>{
          ChildhoodFlags.ilkHoslanma,
          ChildhoodFlags.cesaretEdemedi,
        },
        rememberPersonAs: ChildhoodRoles.ilkHoslandigi,
      ),
    ],
  ),

  GameEvent(
    id: 'ergen_cesaret',
    category: EventCategory.okul,
    text: 'Koridorda karşılaştınız. Tam bir şey söyleyecektin, zil '
        'çaldı.',
    requirement: EventRequirement(
      minAge: 13,
      maxAge: 18,
      requiredFlags: <String>{ChildhoodFlags.cesaretEdemedi},
      personRole: ChildhoodRoles.ilkHoslandigi,
    ),
    weight: 7,
    choices: <EventChoice>[
      EventChoice(
        id: 'soyle',
        label: 'Zile aldırma, söyle',
        resultText: 'Söyledin. {kisi} bir an durdu, sonra gülümsedi: '
            '"Tamam da derse geç kalıyoruz."',
        happiness: 4,
        charisma: 4,
        bond: 6,
        removeFlags: <String>{ChildhoodFlags.cesaretEdemedi},
      ),
      EventChoice(
        id: 'vazgec',
        label: 'Yine erteledin',
        resultText: 'Sınıfa girdin. Ders boyunca aynı cümleyi kafanda '
            'kurdun.',
        happiness: -2,
        addFlags: <String>{ChildhoodFlags.reddedildi},
      ),
    ],
  ),

  GameEvent(
    id: 'ergen_reddedilme',
    category: EventCategory.kisisel,
    text: 'Sonunda söyledin. Karşındaki biraz düşündü ve "seni '
        'arkadaş olarak görüyorum" dedi.',
    requirement: EventRequirement(
      minAge: 14,
      maxAge: 19,
      requiredFlags: <String>{ChildhoodFlags.ilkHoslanma},
      forbiddenFlags: <String>{ChildhoodFlags.reddedildi},
    ),
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'idare',
        label: '"Tamam, sorun değil"',
        resultText: 'Sorun değildi tabii. Eve yürürken kulaklık takıp '
            'sesi sonuna kadar açtın.',
        happiness: -3,
        charisma: 2,
        addFlags: <String>{ChildhoodFlags.reddedildi},
      ),
      EventChoice(
        id: 'uzaklas',
        label: 'Bir süre uzak dur',
        resultText: 'İki hafta selam vermedin. Sonra normale döndünüz, '
            'ama o konu bir daha açılmadı.',
        happiness: -2,
        bond: -3,
        addFlags: <String>{ChildhoodFlags.reddedildi},
      ),
    ],
  ),

  GameEvent(
    id: 'ergen_gruba_girme',
    category: EventCategory.okul,
    text: 'Okulun arkasında toplanan bir grup var. Bugün biri sana '
        'döndü: "Gelsene."',
    requirement: EventRequirement(
      minAge: 13,
      maxAge: 17,
      requiresSchoolStudent: true,
      forbiddenFlags: <String>{
        ChildhoodFlags.grubaGirdi,
        ChildhoodFlags.dislandi,
      },
    ),
    weight: 7,
    choices: <EventChoice>[
      EventChoice(
        id: 'gir',
        label: 'Katıl',
        resultText: 'Katıldın. Konuşulanların yarısı abartıydı ama '
            'orada olmak iyi geliyordu.',
        happiness: 3,
        charisma: 4,
        intelligence: -1,
        addFlags: <String>{ChildhoodFlags.grubaGirdi},
      ),
      EventChoice(
        id: 'gecme',
        label: '"Kalsın"',
        resultText: 'Geçtin gittin. Ertesi gün kimse seni çağırmadı.',
        happiness: -1,
        intelligence: 2,
        addFlags: <String>{ChildhoodFlags.dislandi},
      ),
    ],
  ),

  GameEvent(
    id: 'ergen_dislanma',
    category: EventCategory.okul,
    text: 'Hafta sonu bir şeyler yapmışlar. Sen pazartesi fotoğraflardan '
        'öğrendin.',
    requirement: EventRequirement(
      minAge: 13,
      maxAge: 18,
      requiresSchoolStudent: true,
    ),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'sor',
        label: 'Açıkça sor',
        resultText: '"Niye haber vermediniz?" Cevap tam gelmedi ama '
            'sonraki sefer aradılar.',
        happiness: 1,
        charisma: 3,
        bond: 2,
      ),
      EventChoice(
        id: 'sus',
        label: 'Belli etme',
        resultText: 'Hiçbir şey demedin. O gün kimseyle pek '
            'konuşmadın da.',
        happiness: -3,
      ),
    ],
  ),

  GameEvent(
    id: 'ergen_sinav_kaygisi',
    category: EventCategory.okul,
    text: 'Gece yarısı. Masada açık kitap, kafanda tek bir cümle: '
        '"Yetişmeyecek."',
    requirement: EventRequirement(
      minAge: 14,
      maxAge: 18,
      requiresSchoolStudent: true,
    ),
    weight: 7,
    choices: <EventChoice>[
      EventChoice(
        id: 'uyu',
        label: 'Kapat, uyu',
        resultText: 'Uyudun. Sabah kalktığında kafan daha berraktı.',
        happiness: 2,
        health: 2,
        intelligence: 1,
      ),
      EventChoice(
        id: 'devam',
        label: 'Sabaha kadar devam',
        resultText: 'Saat dörde kadar çalıştın. Sınavda ilk soruda '
            'esnedin.',
        happiness: -2,
        health: -3,
        intelligence: 3,
      ),
      EventChoice(
        id: 'konus',
        label: 'Anneni uyandır, konuş',
        resultText: 'Mutfakta çay koydu. Ders çalışmadınız ama '
            'rahatladın.',
        happiness: 3,
        bond: 5,
      ),
    ],
  ),

  GameEvent(
    id: 'ergen_eve_gelis_saati',
    category: EventCategory.aile,
    text: 'Saat on biri geçti. Telefon çalıyor ve arayan belli.',
    requirement: EventRequirement(
      minAge: 14,
      maxAge: 18,
      livingRelations: <RelationType>{RelationType.anne, RelationType.baba},
      requireSameHousehold: true,
    ),
    weight: 7,
    choices: <EventChoice>[
      EventChoice(
        id: 'ac',
        label: 'Aç, "geliyorum" de',
        resultText: 'Açtın. "Yarım saate evdeyim." Kapıda beklerken '
            'kızmaktan vazgeçmişler.',
        happiness: 1,
        bond: 3,
      ),
      EventChoice(
        id: 'acma',
        label: 'Açma',
        resultText: 'Eve girdiğinde salonun ışığı açıktı ve kimse '
            'uyumamıştı.',
        happiness: -2,
        bond: -5,
      ),
    ],
  ),

  GameEvent(
    id: 'ergen_ilk_yalan',
    category: EventCategory.aile,
    text: '"Nereye gidiyorsun?" diye sordular. Doğrusunu söylesen '
        'göndermezler.',
    requirement: EventRequirement(
      minAge: 13,
      maxAge: 18,
      livingRelations: <RelationType>{RelationType.anne, RelationType.baba},
      forbiddenFlags: <String>{ChildhoodFlags.ilkYalan},
    ),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'yalan',
        label: '"Ders çalışmaya"',
        resultText: 'İnandılar. Bütün akşam telefonun titremesinden '
            'korktun.',
        happiness: 1,
        charisma: 2,
        bond: -2,
        addFlags: <String>{ChildhoodFlags.ilkYalan},
      ),
      EventChoice(
        id: 'dogru',
        label: 'Doğrusunu söyle',
        resultText: 'Söyledin. Uzun bir sessizlik oldu, sonra '
            '"on birde evde ol" dendi.',
        happiness: 2,
        bond: 5,
      ),
    ],
  ),

  GameEvent(
    id: 'ergen_harclik_yetmiyor',
    category: EventCategory.kisisel,
    text: 'Ayın on beşi ve cep boş. Herkes bir şeyler yapmaya gidiyor.',
    requirement: EventRequirement(minAge: 14, maxAge: 18),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'iste',
        label: 'Ailenden iste',
        resultText: '"Daha yeni verdik ama." Verdiler yine de.',
        happiness: 1,
        money: 500,
        bond: -1,
      ),
      EventChoice(
        id: 'gitme',
        label: 'Gitme',
        resultText: '"Canım istemiyor" dedin. Kimse üstelemedi.',
        happiness: -2,
      ),
      EventChoice(
        id: 'idare',
        label: 'Olanla idare et',
        resultText: 'Bir çay parasıyla üç saat oturdun. Kimse fark '
            'etmedi.',
        happiness: 1,
        intelligence: 2,
      ),
    ],
  ),

  GameEvent(
    id: 'ergen_yaz_isi_istegi',
    category: EventCategory.kisisel,
    text: 'Yaz tatili başladı. Mahallede bazıları bir yerlerde '
        'çalışmaya başladı bile.',
    requirement: EventRequirement(
      minAge: 15,
      maxAge: 18,
      forbiddenFlags: <String>{ChildhoodFlags.yazIsiIstedi},
    ),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'calis',
        label: 'Sen de bir şey ara',
        resultText: 'Bir yerde iki ay çalıştın. Para azdı, ama kendi '
            'paran olması başka şeymiş.\n\nMeslek bölümünde artık '
            'yarım zamanlı işler de açık.',
        happiness: 2,
        money: 8000,
        charisma: 3,
        intelligence: 2,
        addFlags: <String>{ChildhoodFlags.yazIsiIstedi},
      ),
      EventChoice(
        id: 'tatil',
        label: 'Tatil tatildir',
        resultText: 'Üç ay boyunca hiçbir şey yapmadın. İyi de geldi.',
        happiness: 3,
        health: 1,
      ),
    ],
  ),

  GameEvent(
    id: 'ergen_sosyal_baski',
    category: EventCategory.okul,
    text: 'Okulun arkasında biri sana bir şey uzattı. "Herkes '
        'deniyor," dedi.\n\nÜç kişi sana bakıyor.',
    requirement: EventRequirement(
      minAge: 14,
      maxAge: 18,
      requiresSchoolStudent: true,
      forbiddenFlags: <String>{ChildhoodFlags.sigarayaHayir},
    ),
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'hayir',
        label: '"İstemiyorum"',
        resultText: 'İki saniye sessizlik oldu, sonra konu değişti. '
            'Kimse üstelemedi.',
        happiness: 1,
        charisma: 3,
        health: 1,
        addFlags: <String>{ChildhoodFlags.sigarayaHayir},
      ),
      EventChoice(
        id: 'uzaklas',
        label: 'Kalk, git',
        resultText: 'Çantanı aldın, yürüdün. Arkandan bir şeyler '
            'söylediler, dönmedin.',
        happiness: -1,
        charisma: 1,
        addFlags: <String>{ChildhoodFlags.sigarayaHayir},
      ),
    ],
  ),

  GameEvent(
    id: 'ergen_ogretmenle_ters',
    category: EventCategory.okul,
    text: 'Öğretmen tahtada bir şey söyledi, sen "yanlış" dedin. '
        'Sınıf sustu.',
    requirement: EventRequirement(
      minAge: 14,
      maxAge: 18,
      requiresSchoolStudent: true,
      forbiddenFlags: <String>{ChildhoodFlags.ogretmenleTers},
    ),
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'kaynak',
        label: 'Kaynağını göster',
        resultText: 'Kitabı açıp gösterdin. Öğretmen baktı: '
            '"Haklısın." O gün sınıfta bir şey değişti.',
        happiness: 3,
        intelligence: 4,
        charisma: 3,
      ),
      EventChoice(
        id: 'geri_al',
        label: 'Geri al',
        resultText: '"Yok, karıştırmışım." Ders devam etti ama sen '
            'haklı olduğunu biliyordun.',
        happiness: -2,
        intelligence: 1,
        addFlags: <String>{ChildhoodFlags.ogretmenleTers},
      ),
    ],
  ),

  GameEvent(
    id: 'ergen_gelecek_kaygisi',
    category: EventCategory.kisisel,
    text: 'Bir akrabanız sordu: "Büyüyünce ne olacaksın?"\n\n'
        'Herkes cevabını bekliyor ve senin gerçekten bir fikrin yok.',
    requirement: EventRequirement(minAge: 14, maxAge: 18),
    weight: 7,
    choices: <EventChoice>[
      EventChoice(
        id: 'uydur',
        label: 'Bir şey uydur',
        resultText: '"Mühendis." Masa memnun oldu. Sen de bir an '
            'inandın.',
        happiness: 1,
        charisma: 2,
      ),
      EventChoice(
        id: 'bilmiyorum',
        label: '"Bilmiyorum"',
        resultText: '"Bilmiyorum." Tuhaf bir sessizlik oldu ama '
            'doğruydu.',
        happiness: -1,
        intelligence: 2,
      ),
      EventChoice(
        id: 'dusun',
        label: 'O akşam gerçekten düşün',
        resultText: 'Gece tavana baktın. Cevabı bulamadın ama soruyu '
            'ciddiye aldın.',
        happiness: 1,
        intelligence: 4,
      ),
    ],
  ),

  GameEvent(
    id: 'ergen_aile_baskisi',
    category: EventCategory.aile,
    text: 'Baban akşam yemeğinde konuyu yine açtı: "Bu gidişle olmaz."',
    requirement: EventRequirement(
      minAge: 15,
      maxAge: 18,
      livingRelations: <RelationType>{RelationType.baba},
      requireSameHousehold: true,
    ),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'tartis',
        label: 'Karşılık ver',
        resultText: 'Sesler yükseldi. İkiniz de sonradan pişman '
            'oldunuz, ikiniz de söylemediniz.',
        happiness: -2,
        bond: -4,
        charisma: 1,
      ),
      EventChoice(
        id: 'dinle',
        label: 'Sessizce dinle',
        resultText: 'Tabağına baktın. Konuşma bitti, konu kapandı ama '
            'içinde kaldı.',
        happiness: -1,
        bond: 1,
      ),
      EventChoice(
        id: 'anlat',
        label: 'Ne düşündüğünü anlat',
        resultText: 'Uzun uzun anlattın. Baban bir şey demedi ama '
            'sonuna kadar dinledi.',
        happiness: 2,
        bond: 5,
        charisma: 3,
      ),
    ],
  ),

  GameEvent(
    id: 'ergen_arkadasla_barisma',
    category: EventCategory.kisisel,
    text: 'Aylardır konuşmuyorsunuz. Bugün otobüs durağında yan yana '
        'kaldınız.',
    requirement: EventRequirement(
      minAge: 14,
      maxAge: 19,
      livingRelations: <RelationType>{RelationType.arkadas},
    ),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'selam',
        label: 'Selam ver',
        resultText: '"Naber." Otobüs gelene kadar konuştunuz. On '
            'dakikada aylar kapandı.',
        happiness: 3,
        bond: 7,
        charisma: 2,
      ),
      EventChoice(
        id: 'bakma',
        label: 'Telefona bak',
        resultText: 'İkiniz de telefona baktınız. Otobüs geldi, ayrı '
            'kapılardan bindiniz.',
        happiness: -2,
        bond: -3,
      ),
    ],
  ),

  GameEvent(
    id: 'ergen_alan_kararsizligi',
    category: EventCategory.okul,
    text: 'Alan seçimi yaklaşıyor. Herkesin bir fikri var: annenin, '
        'babanın, dayının, hatta komşunun.',
    requirement: EventRequirement(
      minAge: 13,
      maxAge: 16,
      requiresSchoolStudent: true,
    ),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'kendi',
        label: 'Kendi kafana göre karar ver',
        resultText: 'Kimseye danışmadan karar verdin. Masa biraz '
            'karıştı ama karar seninki oldu.',
        happiness: 2,
        intelligence: 3,
        charisma: 2,
        bond: -2,
      ),
      EventChoice(
        id: 'aile',
        label: 'Ailenin dediğini yap',
        resultText: 'Onların istediği oldu. Evde huzur var, sende bir '
            'soru işareti.',
        happiness: -1,
        bond: 4,
        intelligence: 1,
      ),
      EventChoice(
        id: 'ogretmen',
        label: 'Öğretmenine danış',
        resultText: 'Öğretmen yarım saat konuştu. Kafan biraz daha '
            'netleşti.',
        happiness: 1,
        intelligence: 4,
      ),
    ],
  ),

  GameEvent(
    id: 'ergen_okuldan_kacma',
    category: EventCategory.okul,
    text: 'İlk ders matematik. Bahçe kapısı açık ve iki arkadaşın '
        'sana bakıyor.',
    requirement: EventRequirement(
      minAge: 14,
      maxAge: 18,
      requiresSchoolStudent: true,
    ),
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'gir',
        label: 'Derse gir',
        resultText: 'Girdin. O gün yoklama alındı ve iki kişi eksikti.',
        happiness: -1,
        intelligence: 3,
      ),
      EventChoice(
        id: 'kac',
        label: 'Onlarla git',
        resultText: 'Üç saat çay ocağında oturdunuz. Ertesi gün '
            'müdür yardımcısı seni çağırdı.',
        happiness: 1,
        intelligence: -2,
        charisma: 1,
        bond: 2,
      ),
    ],
  ),

  GameEvent(
    id: 'ergen_ilk_ayrilik',
    category: EventCategory.kisisel,
    text: '"Böyle olmuyor." Cümle kısaydı ve ikiniz de bir süre bir '
        'şey söylemediniz.',
    requirement: EventRequirement(
      minAge: 15,
      maxAge: 19,
      requiredFlags: <String>{ChildhoodFlags.ilkHoslanma},
    ),
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'kabul',
        label: 'Kabul et',
        resultText: '"Tamam." Eve yürürken hava bir tuhaf soğuktu.',
        happiness: -3,
        charisma: 2,
      ),
      EventChoice(
        id: 'sor',
        label: '"Neden?" diye sor',
        resultText: 'Cevap net değildi. Konuştukça daha da '
            'anlaşılmaz oldu.',
        happiness: -4,
        intelligence: 1,
      ),
    ],
  ),

  GameEvent(
    id: 'ergen_kiskanclik',
    category: EventCategory.okul,
    text: 'Arkadaşın senin girmek istediğin yere girdi, senin '
        'istediğin şeyi aldı. Tebrik etmen gerekiyor.',
    requirement: EventRequirement(
      minAge: 14,
      maxAge: 19,
      livingRelations: <RelationType>{
        RelationType.arkadas,
        RelationType.sinifArkadasi,
      },
    ),
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'tebrik',
        label: 'Gerçekten tebrik et',
        resultText: 'Sarıldın. İçinde bir şey burkuldu ama söylediğin '
            'doğruydu.',
        happiness: 1,
        charisma: 4,
        bond: 5,
      ),
      EventChoice(
        id: 'soguk',
        label: 'Kısa kes',
        resultText: '"Hayırlı olsun." O kadar. İkiniz de fark ettiniz.',
        happiness: -2,
        bond: -4,
      ),
    ],
  ),

  GameEvent(
    id: 'ergen_okul_basarisi',
    category: EventCategory.okul,
    text: 'Bir yarışmaya sınıftan iki kişi gidiyor ve öğretmen '
        'listeye senin adını yazdı.',
    requirement: EventRequirement(
      minAge: 13,
      maxAge: 18,
      requiresSchoolStudent: true,
    ),
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'hazirlan',
        label: 'Ciddiye al, hazırlan',
        resultText: 'İki hafta çalıştın. Derece gelmedi ama öğretmen '
            'omzuna vurdu: "İyiydin."',
        happiness: 3,
        intelligence: 5,
        charisma: 2,
      ),
      EventChoice(
        id: 'gitme',
        label: 'Adını sildir',
        resultText: 'Yerine başkası gitti. Sonucu duyunca biraz '
            'burkuldun.',
        happiness: -1,
        intelligence: -1,
      ),
    ],
  ),
];
