/// Geçmişin geri döndüğü anlar: hikâye izlerinin karşılığı (Paket CZ).
///
/// **Sorun.** Paket AR, bir seçimin geleceğe bıraktığı işaretleri saydı
/// ve **22'sinin hiç okunmadığını** buldu: oyuncu seçiyor, oyun not
/// alıyor, sonra hiçbir yer o notu açmıyor. Yazılmış ama karşılığı
/// olmayan içerik.
///
/// **Ölçüm (150 bot hayatı, `storyFlags` taraması).** Her izin kaç
/// hayatta ve hangi yaşta yazıldığı, bir de iz yazıldıktan sonra kaç yıl
/// yaşandığı ölçüldü; bu dosyadaki pencereler **o ölçümden** türetildi,
/// hedeften değil:
///
/// | iz | hayat/150 | yaş (min-ortanca-max) |
/// |---|---|---|
/// | `aile_sofrasina_katildi` | 87 | 8-28-73 |
/// | `orta_harcadi` | 84 | 24-39-60 |
/// | `aile_arasi_ara_buldu` | 74 | 19-35-64 |
/// | `evlilik_disi_cocuk` | 28 | 23-27-42 |
/// | `suc_direksiyon_uyarisi` | 27 | 32-59-81 |
/// | `gezide_tanisti` | 25 | 30-57-78 |
/// | `eski_is_yerine_ugradi` | 23 | 61-69-78 |
/// | `bebeklik_ilk_ayrilik` | 19 | 2-3-4 |
/// | `aile_bulusmasini_kacirdi` | 14 | 8-22-55 |
/// | `gezide_para_bitti` | 14 | 26-49-85 |
/// | `is_arkadasini_yalniz_birakti` | 14 | 18-33-47 |
/// | `bebeklik_atesli_gece` | 13 | 1-2-3 |
/// | `cocukluk_cam_itiraf` | 11 | 7-9-12 |
/// | `is_teklifi_reddetti` | 9 | 20-36-62 |
/// | `zor_musteri_sert` | 6 | 25-45-58 |
/// | `bekar_aileye_cevap` | 5 | 28-41-55 |
/// | `bebek_bakimi_paylasildi` | 3 | 30-30-41 |
/// | `cocuk_kendi_secti` | 3 | 51-52-68 |
/// | `sosyal_etkinlige_gitti` | 2 | 44-54-54 |
/// | `bebeklik_uykusuz_geceler` | 1 | 2 |
/// | `orta_arabaya_soz_verdi` | 1 | 31 |
/// | `sosyal_yorumlari_kapatti` | 0 | — |
///
/// Her iz yazıldıktan sonra en az 21, çoğunda 40-88 yıl yaşanıyor; bu
/// yüzden pencereler geniş tutuldu. Seyrek yazılan izler de dahil
/// edildi: botun seyrek seçmesi oyuncunun seyrek seçeceği anlamına
/// gelmez.
///
/// **Kural.** Her olay yalnızca izi olan karede çıkar
/// (`requiredFlags`), izi yorumlar ve yeni bir mekanik getirmez.
/// Metinler kimseyi adlandırmaz; "en az bir kişi" kapısı olan olay
/// belirli bir kişiyi ya da sayıyı varsaymaz (Paket CX dersi).
///
/// Modülü tamamen silme tarifi: `docs/FEATURE_FLAGS.md`.
library;

import '../domain/models/game_event.dart';
import 'event_pool.dart';
import 'event_pool_childhood.dart';
import 'event_pool_crime.dart';
import 'event_pool_elder.dart';
import 'event_pool_family_gathering.dart';
import 'event_pool_infancy.dart';
import 'event_pool_midlife.dart';
import 'event_pool_romance.dart';
import 'event_pool_social.dart';
import 'event_pool_travel.dart';
import 'event_pool_work.dart';

const List<GameEvent> kTraceEchoEvents = <GameEvent>[
  GameEvent(
    id: 'iz_sofranin_hatirlanmasi',
    category: EventCategory.aile,
    text: 'Eski bir kalabalık sofra anlatılıyor: kimin ne dediği, kimin '
        'erken kalktığı. Senin orada olduğun da anlatılanların '
        'içinde.',
    requirement: EventRequirement(
      minAge: 14,
      requiredFlags: <String>{FamilyGatheringFlags.sofrayaKatildi},
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'anlat',
        label: 'Sen de bir şey ekle',
        resultText: 'Hatırladığın bir ayrıntıyı ekledin. Masada kısa bir kahkaha '
            'oldu.',
        happiness: 4,
        bond: 3,
      ),
      EventChoice(
        id: 'dinle',
        label: 'Sadece dinle',
        resultText: 'Anlatılanı bozmadın. Kendi hatırladığın hâli sende kaldı.',
        happiness: 2,
      ),
    ],
  ),
  GameEvent(
    id: 'iz_gidilmeyen_sofra',
    category: EventCategory.aile,
    text: 'O gün gelmediğin bir buluşma yıllar sonra lafa karıştı: '
        '"sen yoktun" dendi, gülüşüldü ama cümle havada kaldı.',
    requirement: EventRequirement(
      minAge: 14,
      requiredFlags: <String>{FamilyGatheringFlags.bulusmayiKacirdi},
    ),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'aciklama',
        label: 'Sebebini söyle',
        resultText: 'Neden gelemediğini anlattın. Dinlendi; mesele kapandı.',
        happiness: 3,
        bond: 2,
      ),
      EventChoice(
        id: 'gec',
        label: 'Üstünde durma',
        resultText: 'Konuyu değiştirdin. Kimse ısrar etmedi, kimse de unutmadı.',
        happiness: -1,
      ),
    ],
  ),
  GameEvent(
    id: 'iz_arabulucu_cagrisi',
    category: EventCategory.aile,
    text: 'Ailede yeni bir anlaşmazlık var ve bu kez senin adın geçiyor: '
        'geçen sefer araya giren sendin.',
    requirement: EventRequirement(
      minAge: 24,
      requiredFlags: <String>{FamilyGatheringFlags.araBulduAile},
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'yine',
        label: 'Yine araya gir',
        resultText: 'İki tarafı ayrı ayrı dinledin. Mesele çözülmedi ama kimse '
            'kapıyı çarpmadı.',
        happiness: 3,
        bond: 4,
      ),
      EventChoice(
        id: 'bu_kez_hayir',
        label: 'Bu kez karışma',
        resultText: 'Kendi başlarına çözmelerini bekledin. Uzun sürdü; sana kimse '
            'kızmadı ama soran da olmadı.',
        happiness: -1,
      ),
    ],
  ),
  GameEvent(
    id: 'iz_atesli_gecenin_anlatimi',
    category: EventCategory.aile,
    text: 'Bebekliğinde geçirdiğin ateşli bir gece anlatılıyor. Anlatan '
        'hâlâ o geceyi dün gibi hatırlıyor.',
    requirement: EventRequirement(
      minAge: 9,
      requiredFlags: <String>{InfancyFlags.atesliGece},
    ),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'sor',
        label: 'Ayrıntısını sor',
        resultText: 'Hastane mi, ev mi, kaç saat sürdü — hepsini dinledin. '
            'Anlatanın sesi yumuşadı.',
        happiness: 4,
        bond: 3,
      ),
      EventChoice(
        id: 'utan',
        label: 'Konuyu kapat',
        resultText: '"Tamam, anladım" dedin. Anlatan yarısında kesti.',
        happiness: -1,
      ),
    ],
  ),
  GameEvent(
    id: 'iz_ilk_ayriligin_hikayesi',
    category: EventCategory.aile,
    text: 'İlk kez bırakıldığın gün hatırlatılıyor: kapıda ne yaptığın, '
        'dönüşte nasıl karşıladığın.',
    requirement: EventRequirement(
      minAge: 10,
      requiredFlags: <String>{InfancyFlags.ilkAyrilik},
    ),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'gul',
        label: 'Gülerek dinle',
        resultText: 'Anlatılan hâlini kendin de komik buldun. İki kere anlattırdın.',
        happiness: 4,
        bond: 2,
      ),
      EventChoice(
        id: 'inanma',
        label: 'İnanmadığını söyle',
        resultText: '"Ben öyle yapmam" dedin. Israr edildi, kanıt bulunamadı.',
        happiness: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'iz_uykusuz_gecelerin_bedeli',
    category: EventCategory.aile,
    text: 'Senin uyumadığın geceler anlatılıyor; anlatan hâlâ o yılların '
        'yorgunluğunu şakaya vuruyor.',
    requirement: EventRequirement(
      minAge: 20,
      requiredFlags: <String>{InfancyFlags.uykusuzGeceler},
    ),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'tesekkur',
        label: 'Teşekkür et',
        resultText: 'Teşekkür ettin. Beklenmedik bir cümleydi; konu değişti ama '
            'yüz değişmedi.',
        happiness: 5,
        bond: 5,
      ),
      EventChoice(
        id: 'saka',
        label: 'Şakayla karşıla',
        resultText: '"Demek huysuzdum" dedin. Gülüşüldü, mesele orada kaldı.',
        happiness: 2,
      ),
    ],
  ),
  GameEvent(
    id: 'iz_camin_sonu',
    category: EventCategory.mahalle,
    text: 'Yıllar önce kırılan bir cam ve kapıyı çalıp itiraf edişin '
        'mahallede hâlâ anlatılıyor.',
    requirement: EventRequirement(
      minAge: 15,
      requiredFlags: <String>{ChildhoodFlags.camIItirafEtti},
    ),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'sahiplen',
        label: 'Sahiplen',
        resultText: '"Bendim" dedin. Anlatan güldü: zaten biliniyordu.',
        happiness: 4,
        charisma: 2,
      ),
      EventChoice(
        id: 'inkar',
        label: 'Başkasıydı de',
        resultText: 'Üstüne almadın. Kimse düzeltmedi, kimse de inanmadı.',
        happiness: -1,
        charisma: -1,
      ),
    ],
  ),
  GameEvent(
    id: 'iz_yalniz_biraktigin_mesai',
    category: EventCategory.yetiskinlik,
    text: 'Bir zamanlar yardım istediğinde yanına gitmediğin biri '
        'yeniden karşına çıktı. İkiniz de hatırlıyorsunuz.',
    requirement: EventRequirement(
      minAge: 24,
      requiredFlags: <String>{WorkFlags.isArkadasiniYalniz},
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'ozur',
        label: 'Konuyu aç ve özür dile',
        resultText: 'Açtın, kısa tuttun. Karşılık soğuk değildi; eski mesele '
            'kapandı sayılır.',
        happiness: 4,
        bond: 3,
      ),
      EventChoice(
        id: 'davran',
        label: 'Hiç olmamış gibi davran',
        resultText: 'Nezaketle konuştunuz. İkinizin de hatırladığı şey masaya '
            'gelmedi.',
        happiness: -1,
      ),
    ],
  ),
  GameEvent(
    id: 'iz_reddedilen_teklifin_sonu',
    category: EventCategory.yetiskinlik,
    text: 'Yıllar önce reddettiğin iş teklifinin geldiği yer haberlere '
        'konu oldu. İyi ya da kötü, o yol başka bir yere gitmiş.',
    requirement: EventRequirement(
      minAge: 26,
      requiredFlags: <String>{WorkFlags.isTeklifiReddetti},
    ),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'dusun',
        label: 'Bir süre düşün',
        resultText: 'Kendi seçtiğin yolu bir kez daha tarttın. Kararın değişmedi '
            'ama rahatladın.',
        happiness: 3,
        intelligence: 1,
      ),
      EventChoice(
        id: 'bakma',
        label: 'Dönüp bakma',
        resultText: 'Haberi kapattın. Seçtiğin işin bugünkü hâli yeter.',
        happiness: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'iz_zor_musterinin_donusu',
    category: EventCategory.yetiskinlik,
    text: 'Bir zamanlar sert çıktığın müşteri yeniden karşında; bu kez '
        'masanın öbür tarafında.',
    requirement: EventRequirement(
      minAge: 30,
      requiredFlags: <String>{WorkFlags.zorMusteriSert},
    ),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'sakin',
        label: 'Sakin ol',
        resultText: 'Sesini yükseltmedin. İş yürüdü; eski gerginlik tekrarlanmadı.',
        happiness: 3,
        charisma: 3,
      ),
      EventChoice(
        id: 'yine_sert',
        label: 'Yine sert ol',
        resultText: 'Yine sertleştin. İş oldu ama bir daha aranmadın.',
        happiness: -2,
        charisma: -1,
      ),
    ],
  ),
  GameEvent(
    id: 'iz_eski_is_yerinin_hali',
    category: EventCategory.yetiskinlik,
    text: 'Uğradığın eski iş yerinden haber geldi: yer el değiştirmiş, '
        'tanıdıklardan birkaçı hâlâ orada.',
    requirement: EventRequirement(
      minAge: 64,
      requiredFlags: <String>{ElderFlags.eskiIsYeri},
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'arayin',
        label: 'Tanıdıkları ara',
        resultText: 'İki kişiyle konuştun. Uzun uzun eski günlerden bahsedildi.',
        happiness: 5,
        bond: 3,
      ),
      EventChoice(
        id: 'kalsin',
        label: 'Hatırası kalsın',
        resultText: 'Aramadın. Hatırladığın hâli bozulmadan kaldı.',
        happiness: 2,
      ),
    ],
  ),
  GameEvent(
    id: 'iz_yolda_tanisilan',
    category: EventCategory.kisisel,
    text: 'Bir gezide tanıştığın kişiden yıllar sonra haber geldi: '
        'seni hatırlıyor ve selam gönderiyor.',
    requirement: EventRequirement(
      minAge: 34,
      requiredFlags: <String>{TravelFlags.yoldaTanisti},
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'yaz',
        label: 'Karşılık yaz',
        resultText: 'Uzun bir cevap yazdın. Arada kalan yılları iki paragrafta '
            'toparladınız.',
        happiness: 5,
        charisma: 2,
      ),
      EventChoice(
        id: 'okuyup_birak',
        label: 'Okuyup bırak',
        resultText: 'Okudun, cevap yazmadın. Selam yerine ulaştı sayılır.',
        happiness: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'iz_parasiz_kalinan_gezi',
    category: EventCategory.kisisel,
    text: 'Parasının bittiği o geziyi anlatıyorsun; dinleyenler en çok '
        'nasıl idare ettiğini soruyor.',
    requirement: EventRequirement(
      minAge: 31,
      requiredFlags: <String>{TravelFlags.gezidePara},
    ),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'anlat',
        label: 'Bütün hâliyle anlat',
        resultText: 'Utanmadan anlattın. Hikâye en çok gülünen oldu.',
        happiness: 4,
        charisma: 3,
      ),
      EventChoice(
        id: 'kisalt',
        label: 'Kısa kes',
        resultText: 'Birkaç cümleyle geçtin. Ayrıntıyı kendine sakladın.',
        happiness: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'iz_harcanan_birikimin_hesabi',
    category: EventCategory.yetiskinlik,
    text: 'O yıl birikimi kendine harcamıştın. Şimdi aynı karar yeniden '
        'önünde: bir kenara mı, yoksa şimdiye mi.',
    requirement: EventRequirement(
      minAge: 32,
      requiredFlags: <String>{MidlifeFlags.harcadi},
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'bu_kez_biriktir',
        label: 'Bu kez bir kenara koy',
        resultText: 'Bu kez kenara koydun. Hesap küçük ama duruyor.',
        happiness: -1,
      ),
      EventChoice(
        id: 'yine_harca',
        label: 'Yine şimdiye harca',
        resultText: 'Yine şimdiye harcadın. Pişman değilsin; hesap da yine boş.',
        happiness: 4,
      ),
    ],
  ),
  GameEvent(
    id: 'iz_arabaya_verilen_soz',
    category: EventCategory.aile,
    text: '"Araştıracağım" demiştin ve konu kapanmıştı. Bugün o söz '
        'hatırlatıldı.',
    requirement: EventRequirement(
      minAge: 34,
      requiredFlags: <String>{MidlifeFlags.arabayaSozVerdi},
    ),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'tut',
        label: 'Sözünü tut',
        resultText: 'Gerçekten araştırdın; rakamları masaya koydun. Söz tutulmuş '
            'sayıldı.',
        happiness: 3,
        bond: 4,
      ),
      EventChoice(
        id: 'erteleme',
        label: 'Bir kez daha ertele',
        resultText: '"Bakıyorum" dedin. Aynı cümle ikinci kez inandırıcı olmadı.',
        happiness: -2,
        bond: -3,
      ),
    ],
  ),
  GameEvent(
    id: 'iz_aileye_verilen_net_cevap',
    category: EventCategory.aile,
    text: 'Evlilik konusunda aileye net cevabı vermiştin. O cevap bugün '
        'yeniden masada.',
    requirement: EventRequirement(
      minAge: 33,
      requiredFlags: <String>{SingleLifeFlags.ailenineCevapVerdi},
    ),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'ayni',
        label: 'Aynı cevabı ver',
        resultText: 'Aynı şeyi söyledin, aynı sakinlikle. Bu kez daha az '
            'tartışıldı.',
        happiness: 3,
        bond: 1,
      ),
      EventChoice(
        id: 'yumusa',
        label: 'Yumuşat',
        resultText: 'Kapıyı aralık bıraktın. Umutlandılar; sen emin değilsin.',
        happiness: -1,
        bond: 2,
      ),
    ],
  ),
  GameEvent(
    id: 'iz_cocugun_kendi_sectigi_yol',
    category: EventCategory.aile,
    text: 'Çocuğun kendi seçtiği işte bir dönüm noktasında. O gün '
        'karışmamıştın.',
    requirement: EventRequirement(
      minAge: 56,
      requiredFlags: <String>{StoryFlags.cocukKendiSecti},
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'arkasinda',
        label: 'Arkasında dur',
        resultText: 'Yanında olduğunu söyledin. Kararı yine kendisi verdi, bu kez '
            'daha rahat.',
        happiness: 5,
        bond: 5,
      ),
      EventChoice(
        id: 'soyle',
        label: 'Şimdi fikrini söyle',
        resultText: 'Fikrini söyledin. Dinlendi ama "o zaman karışmamıştın" da '
            'denildi.',
        happiness: -1,
        bond: -2,
      ),
    ],
  ),
  GameEvent(
    id: 'iz_paylasilan_bebek_bakimi',
    category: EventCategory.aile,
    text: 'Bebek bakımını sırayla paylaştığınız yıllar anlatılıyor. O '
        'düzen hatırlanıyor.',
    requirement: EventRequirement(
      minAge: 36,
      requiredFlags: <String>{StoryFlags.bebekBakimiPaylasildi},
    ),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'hatirla',
        label: 'Birlikte hatırla',
        resultText: 'O gecelerin sırasını birlikte hatırladınız. İkiniz de '
            'gülümsedi.',
        happiness: 4,
        bond: 4,
      ),
      EventChoice(
        id: 'yorgunluk',
        label: 'Yorgunluğunu hatırla',
        resultText: 'En çok yorgunluğu hatırladın. Doğru ama kısa bir cevaptı.',
        happiness: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'iz_evlilik_disi_cocugun_yolu',
    category: EventCategory.aile,
    text: 'Hayatına evlilik dışında gelen çocuk büyüdü ve kendi yolunu '
        'soruyor: nereden başlanmış, nasıl devam edilmiş.',
    requirement: EventRequirement(
      minAge: 30,
      requiredFlags: <String>{StoryFlags.evlilikDisiCocuk},
    ),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'dogruyu',
        label: 'Olduğu gibi anlat',
        resultText: 'Süslemeden anlattın. Soru soran dinledi; arada kalan yıllar '
            'kısaldı.',
        happiness: 4,
        bond: 4,
      ),
      EventChoice(
        id: 'kacin',
        label: 'Geçiştir',
        resultText: 'Kısa kestin. Soru bir daha sorulmadı.',
        happiness: -2,
        bond: -2,
      ),
    ],
  ),
  GameEvent(
    id: 'iz_etkinlikten_kalan_isim',
    category: EventCategory.kisisel,
    text: 'O küçük etkinlikte tanıştığın isimlerden biri bugün bir iş '
        'için adını anmış.',
    requirement: EventRequirement(
      minAge: 48,
      requiredFlags: <String>{SocialFlags.etkinligeGitti},
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'don',
        label: 'Dönüş yap',
        resultText: 'Dönüş yaptın. Konuşma kısa, sonucu belirsiz ama kapı açık.',
        happiness: 4,
        charisma: 2,
      ),
      EventChoice(
        id: 'bosver',
        label: 'Boş ver',
        resultText: 'Cevap vermedin. İsim listede kaldı.',
        happiness: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'iz_kapatilan_yorumlarin_sessizligi',
    category: EventCategory.kisisel,
    text: 'Yorumları kapattığından beri ortalık sessiz. Bu sessizliğin '
        'rahatlığı da var, eksikliği de.',
    requirement: EventRequirement(
      minAge: 30,
      requiredFlags: <String>{SocialFlags.yorumlariKapatti},
    ),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'ac',
        label: 'Yeniden aç',
        resultText: 'Açtın. İlk gün karışıktı; ikinci gün alıştın.',
        happiness: 2,
        charisma: 2,
      ),
      EventChoice(
        id: 'kapali',
        label: 'Kapalı kalsın',
        resultText: 'Kapalı kaldı. Kimsenin ne dediğini bilmemek işine geliyor.',
        happiness: 3,
      ),
    ],
  ),
  GameEvent(
    id: 'iz_direksiyon_uyarisinin_ardi',
    category: EventCategory.yetiskinlik,
    text: 'O gün yavaşlamıştın ve ceza yazılmamıştı. Aynı yol, aynı '
        'saat; bu kez acelen var.',
    requirement: EventRequirement(
      minAge: 36,
      requiredFlags: <String>{CrimeFlags.direksiyonUyarisi},
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'yine_yavasla',
        label: 'Yine yavaşla',
        resultText: 'Yine yavaşladın. Geç kaldın; başka bir şey olmadı.',
        happiness: 1,
        health: 1,
      ),
      EventChoice(
        id: 'bas',
        label: 'Bu kez bas',
        resultText: 'Bastın. Yol boştu, bir şey olmadı — bu kez.',
        happiness: 2,
        health: -1,
      ),
    ],
  ),
];
