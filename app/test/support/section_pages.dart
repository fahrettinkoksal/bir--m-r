// Bölüm sayfalarının kapsam kaydı (Paket DM).
//
// **Neden ayrı dosya.** İki test aynı listeyi okuyor:
// `ekran_dokumu_bolumler_test.dart` sayfaları açıp metnini basıyor,
// `paket_dm_bolum_kapsami_test.dart` ise `lib/ui/screens/sections/`
// altındaki **her** sayfanın bir okuyucusu olduğunu denetliyor. Liste
// tek yerde durmazsa ikisi sessizce ayrışır.
library;

import 'package:bir_omur/data/activity_catalog.dart';
import 'package:bir_omur/data/finger_catalog.dart';
import 'package:bir_omur/data/social_catalog.dart';
import 'package:bir_omur/data/license_catalog.dart';
import 'package:bir_omur/data/investment_catalog.dart';
import 'package:bir_omur/data/lottery_catalog.dart';
import 'package:bir_omur/domain/career/military_service.dart';
import 'package:bir_omur/domain/casino/casino_rules.dart';
import 'package:bir_omur/domain/pets/pet_care.dart';
import 'package:bir_omur/domain/economy/banking.dart';
import 'package:bir_omur/domain/economy/furnishing.dart';
import 'package:bir_omur/domain/features/feature_catalog.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/military.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/ui/widgets/person_card.dart';
import 'package:bir_omur/domain/models/owned_item.dart';
import 'package:bir_omur/domain/models/school_club_progress.dart';
import 'package:bir_omur/domain/activities/travel.dart';
import 'package:bir_omur/domain/interaction/intimacy.dart';
import 'package:bir_omur/domain/interaction/parenthood.dart';
import 'package:bir_omur/domain/social/media_opportunities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Dökümü alınan bir bölüm sayfası.
/// Sekme kökü: `ekran_dokumu_test.dart` her birini açıp **metnini
/// basıyor**.
///
/// **Neden burada (Paket DQ).** Bu dört sayfanın kapsam iddiası
/// `kBaskaTestle` kaydında metin benzerliğiyle tutuluyordu ve biri
/// (`activities_screen.dart` → `content_reachability_test.dart`)
/// yalnızca bir `group('Aktiviteler')` **etiketi** sayesinde geçiyordu;
/// o test hiç widget kurmuyor. Liste artık iki yerden **aynı kaynak**
/// olarak okunuyor: döküm onu dolaşıp kareyi basıyor, kapsam bekçisi de
/// kapsamı ondan sayıyor. İddia ad çakışmasına değil yapıya dayanıyor.
class SekmeKaresi {
  const SekmeKaresi(this.sekme, this.ad, this.dosya);

  /// Sekme anahtarı (`Key('tab_…')`).
  final String sekme;

  /// Dökümde görünen ad.
  final String ad;

  /// `lib/ui/screens/sections/` altındaki dosya adı.
  final String dosya;
}

/// Dökümün dolaştığı sekme kökleri.
const List<SekmeKaresi> kSekmeKareleri = <SekmeKaresi>[
  SekmeKaresi('tab_okul_meslek', 'Okul / Meslek', 'school_career_screen.dart'),
  SekmeKaresi('tab_varliklar', 'Varlıklar', 'assets_screen.dart'),
  SekmeKaresi('tab_iliskiler', 'İlişkiler', 'relationships_screen.dart'),
  SekmeKaresi('tab_aktiviteler', 'Aktiviteler', 'activities_screen.dart'),
];

class Bolum {
  const Bolum(
    this.ad,
    this.dosya,
    this.kosul,
    this.sekme,
    this.yol,
    this.isaret,
  );

  /// Dökümde görünen ad.
  final String ad;

  /// `lib/ui/screens/sections/` altındaki dosya adı.
  final String dosya;

  /// Sayfanın kapısı; bu koşulu sağlayan temiz bir kare aranır.
  final bool Function(GameState) kosul;

  /// Hangi sekmeden girilir.
  final String sekme;

  /// Sekmeden sonra basılacak hedefler, sırayla.
  final List<Finder> yol;

  /// Sayfanın **gerçekten açıldığını** kanıtlayan metin.
  ///
  /// **Neden var (Paket DM'nin kendi hatası, iki kez).** İlk yazımda
  /// döküm yolun son adımına dokunup ekranı basıyordu. "GÖZ MUAYENESİ"
  /// karesi böyle 52 metin bastı ve test geçti; oysa basılan kare
  /// **Sağlık Merkezi**'ydi (satır "Şu an kapalı" olduğu için dokunma
  /// hiçbir şey yapmamıştı). İşaret ekleyince de ilk seçtiğim metin
  /// (`Duvardaki harfler`) satırın **üst sayfadaki** tanıtımıydı ve
  /// döküm bir tur daha yanılttı. İşaret yalnızca hedef sayfada
  /// bulunan bir metin olmalı. Paket CV'nin dersi: **araç yalan
  /// söylemez.**
  final String isaret;
}

/// Dökümün açtığı sayfalar.
///
/// Bu sekizi Paket DM'den önce **hiçbir testte** okunmuyordu; ölçüm
/// yöntemi ve sonucu `ekran_dokumu_bolumler_test.dart` başlığında.
final List<Bolum> kBolumler = <Bolum>[
  Bolum(
    'BANKA',
    'bank_page.dart',
    (GameState s) => s.player.age >= Banking.prototypeOnlyMinAge,
    'tab_aktiviteler',
    <Finder>[find.byKey(const Key('activities_banka'))],
    'Kredi durumun',
  ),
  Bolum(
    'SİGORTA',
    'insurance_page.dart',
    (GameState s) => s.featureOn(FeatureId.sigorta) && s.player.age >= 18,
    'tab_aktiviteler',
    <Finder>[find.byKey(const Key('activities_sigorta'))],
    'Sigorta kazanç getirmez',
  ),
  Bolum(
    'HOBİLERİM',
    'hobbies_page.dart',
    (GameState s) => s.hobbies.isNotEmpty,
    'tab_aktiviteler',
    <Finder>[find.byKey(const Key('aktivite_hobiler'))],
    'Kayıt silinmez: bıraktığın uğraş da burada durur.',
  ),
  Bolum(
    'ÜN VE MEDYA FIRSATLARI',
    'media_page.dart',
    MediaOpportunities.sectionVisible,
    'tab_aktiviteler',
    <Finder>[find.text('Ün ve Medya Fırsatları')],
    'Markalar kurgusaldır',
  ),
  Bolum(
    // Kapı yalnızca yaş değil **para**: muayene 1.400 ₺ ve parası
    // olmayan oyuncuda satır "Şu an kapalı" kalıyor.
    'GÖZ MUAYENESİ',
    'eye_exam_page.dart',
    (GameState s) => s.player.age >= 18 && s.player.wallet >= 20000,
    'tab_aktiviteler',
    <Finder>[
      find.byKey(const Key('activity_saglik')),
      // Satırın **başlığına** dokunmak sayfayı açmıyor; eylem
      // düğmesine dokunmak gerekiyor.
      find.byKey(const Key('aktivite_goz_muayenesi_yap')),
    ],
    'Okuyamadığın satırda da bir seçim yapman gerekiyor',
  ),
  Bolum(
    'EVİNİN HÂLİ (DÖŞEME)',
    'furnishing_page.dart',
    Furnishing.appliesTo,
    'tab_varliklar',
    <Finder>[find.byKey(const Key('assets_furnishing_row'))],
    'Temel ihtiyaçlar',
  ),
  Bolum(
    'EVLİLİK GEÇMİŞİ',
    'marriage_history_page.dart',
    (GameState s) => s.marriageCount > 0,
    'tab_iliskiler',
    <Finder>[find.byKey(const Key('iliskiler_evlilik_gecmisi'))],
    'Kayıt silinmez: biten evlilik de burada durur.',
  ),
  Bolum(
    'ASKERLİK',
    'military_page.dart',
    // **Sekme içeriği duruma göre değişiyor (Paket DN).**
    // `SchoolCareerScreen` öğrenciye okul görünümünü, diğerlerine
    // kariyer görünümünü çiziyor. Bu satırlar kariyer görünümünde;
    // satırın kendi kapısı açık olsa bile öğrenci karede ekranda
    // yoklar. İlk yazımda bunu atlamıştım ve "kapı açık ama satır
    // yok" diye bir ürün hatası sanacaktım.
    (GameState s) =>
        !s.education.isStudent &&
        (s.player.age >= MilitaryService.prototypeOnlyMinAge ||
            s.military.status != MilitaryStatus.yok),
    'tab_okul_meslek',
    <Finder>[find.byKey(const Key('career_military_row'))],
    'Katılma yolları',
  ),

  // ---- Paket DN: kalan sayfalar ------------------------------------
  //
  // Paket DM sekiz sayfayı açıp **üç** gerçek kusur buldu; oran sayfa
  // başına 0,38. Kalan 22 sayfanın "başka testle okunuyor" kaydı
  // başlık düzeyindeydi: o testler anahtar ve tek tek metin
  // denetliyor, kareyi gözle okumuyor. Bu on sayfa aynı yöntemle
  // açıldı.
  Bolum(
    'FINGER',
    'finger_page.dart',
    (GameState s) => s.player.age >= kFingerMinAge,
    'tab_aktiviteler',
    <Finder>[find.byKey(const Key('activity_finger'))],
    'profile daha bakabilirsin',
  ),
  Bolum(
    'MİLLİ PİYANGO',
    'lottery_page.dart',
    (GameState s) =>
        s.settings.casinoEnabled && s.player.age >= kLotteryMinAge,
    'tab_aktiviteler',
    <Finder>[find.byKey(const Key('activity_piyango'))],
    'Çekiliş yıl sonunda yapılır.',
  ),
  Bolum(
    'HAYAT HEDEFLERİ',
    'life_goals_page.dart',
    (GameState s) => s.player.age >= 25,
    'tab_aktiviteler',
    <Finder>[find.byKey(const Key('aktivite_hedefler'))],
    'hedefe ulaştın',
  ),
  Bolum(
    'SAĞLIK GEÇMİŞİ',
    'health_history_page.dart',
    (GameState s) =>
        s.chronicConditions.isNotEmpty || s.healthHistory.isNotEmpty,
    'tab_aktiviteler',
    <Finder>[
      find.byKey(const Key('activity_saglik')),
      find.byKey(const Key('saglik_gecmis')),
    ],
    // İlk işaretim ("Kayıt silinmez: atlattığın kriz de burada
    // durur.") koşullu bir cümleydi ve süren durumu olan karede
    // çizilmiyordu; sayfa doğru açılmıştı. Kare değişimi denetimi
    // gezinmeyi zaten kanıtlıyor, işaret sayfanın başlığı olabilir.
    'Sağlık Geçmişi',
  ),
  Bolum(
    'KENDİ İŞİM',
    'business_page.dart',
    (GameState s) => !s.education.isStudent && s.businesses.isNotEmpty,
    'tab_okul_meslek',
    <Finder>[find.byKey(const Key('career_business_row'))],
    'Kendi İşim',
  ),
  Bolum(
    'ADLİ GEÇMİŞ',
    'legal_record_page.dart',
    (GameState s) => !s.education.isStudent && s.player.age >= 18,
    'tab_okul_meslek',
    <Finder>[find.byKey(const Key('career_legal_row'))],
    // Aynı hata: o cümle yalnızca kaydı olan oyuncuda çiziliyor,
    // temiz kayıtta "Adli kaydın temiz." yazıyor.
    'Adli Geçmiş',
  ),
  Bolum(
    'SPOR KARİYERİ',
    'sports_career_page.dart',
    (GameState s) => !s.education.isStudent && s.footballCareer != null,
    'tab_okul_meslek',
    <Finder>[find.byKey(const Key('career_sports_row'))],
    'Spor Kariyeri',
  ),
  Bolum(
    'KULÜPLER',
    'school_clubs_page.dart',
    // Kulüpler okul görünümünde: kapı **öğrenci** olmayı gerektirir.
    (GameState s) =>
        s.education.isStudent && s.schoolClubs.activeOnes.isNotEmpty,
    'tab_okul_meslek',
    <Finder>[find.byKey(const Key('school_clubs_row'))],
    'Kulüpler',
  ),
  Bolum(
    'YATIRIMLAR',
    'investments_page.dart',
    (GameState s) =>
        s.player.age >= kInvestmentMinAge && s.portfolioValue > 0,
    'tab_varliklar',
    <Finder>[find.text('Yatırımlar')],
    'Yatırımlar',
  ),
  Bolum(
    'EVLERİM',
    'properties_page.dart',
    (GameState s) => s.items.any((OwnedItem i) => i.isProperty),
    'tab_varliklar',
    <Finder>[find.text('Evlerim')],
    'Evlerim',
  ),

  // ---- Paket DO: `activity_pages.dart` içindeki ayrı sayfalar ------
  //
  // Bu dosya altı ayrı sayfa barındırıyor (`VenuePage`, `LibraryPage`,
  // `AdoptionPage`, `WillPage`, `TravelPage`, `RelocationPage`) ve
  // hiçbirinin metni dökümde basılmamıştı. Kayıt dosya başına tek
  // satır tuttuğu için bu sayfalar "okunuyor" sayılıyordu; ölçü dosya
  // değil **kare** olmalı.
  Bolum(
    'KÜTÜPHANE',
    'activity_pages.dart',
    (GameState s) => booksFor(s.player.age).isNotEmpty,
    'tab_aktiviteler',
    <Finder>[find.byKey(const Key('activity_kutuphane'))],
    // İlk işaretim ("Bitirdiğin kitap") yine koşulluydu: hiç kitap
    // bitirmemiş 6 yaşındaki karede çizilmiyor.
    'Yaşına uygun',
  ),
  Bolum(
    'SON KARARLAR',
    'activity_pages.dart',
    (GameState s) => s.livingChildren.isNotEmpty,
    'tab_aktiviteler',
    <Finder>[find.byKey(const Key('activity_son_kararlar'))],
    'Mirasçı seçimi ve hayatının sonuna dair kararlar',
  ),
  Bolum(
    'TATİL YAP',
    'activity_pages.dart',
    (GameState s) => s.player.age >= Travel.prototypeOnlyMinAge,
    'tab_aktiviteler',
    <Finder>[find.byKey(const Key('activity_tatil'))],
    'Tatil, taşınma değildir',
  ),
  Bolum(
    'TAŞIN',
    'activity_pages.dart',
    (GameState s) => s.player.age >= 18,
    'tab_aktiviteler',
    <Finder>[find.byKey(const Key('activity_tasin'))],
    'şehrinde yaşıyorsun',
  ),
  Bolum(
    'TÜP BEBEK TEDAVİSİ',
    'fertility_page.dart',
    (GameState s) =>
        Intimacy.partnerOf(s) != null &&
        s.player.age >= Parenthood.prototypeOnlyMinAge,
    'tab_aktiviteler',
    <Finder>[
      find.byKey(const Key('activity_saglik')),
      find.byKey(const Key('saglik_tup_bebek')),
    ],
    'Tedavi bir garanti değildir',
  ),

  // ---- Paket DP: kalan kareler --------------------------------------
  //
  // DM/DN/DO 23 kare okudu ve 7 kusur çıktı. Bunlar kalan ayrı
  // sayfalar; kayıt "başka testle okunuyor" diyordu ve o iddia
  // yanlış değil: beş testin beşi de ağacı kuruyor ve satıra
  // dokunuyor (`pumpWidget` 1-3, `tester.tap` 4-14). Eksik olan
  // başka bir şey — o testler **anahtar ve tek tek cümle**
  // denetliyor, kareyi baştan sona gözle okumuyor. Kusur tam orada
  // duruyordu.
  Bolum(
    'KUMARHANE',
    'casino_pages.dart',
    (GameState s) =>
        s.settings.casinoEnabled &&
        s.player.age >= CasinoRules.prototypeOnlyMinAge,
    'tab_aktiviteler',
    <Finder>[find.text('Kumarhane')],
    'bu yılki bahis bütçen',
  ),
  Bolum(
    'EHLİYET İŞLEMLERİ',
    'license_pages.dart',
    (GameState s) =>
        s.player.age >= LicenseType.motosiklet.prototypeOnlyMinAge,
    'tab_aktiviteler',
    <Finder>[find.text('Ehliyet İşlemleri')],
    'Sınav kısa bir soruyla yapılır',
  ),
  Bolum(
    'EVCİL HAYVANLAR',
    'pets_page.dart',
    (GameState s) =>
        s.pets.isNotEmpty || s.player.age >= PetCare.prototypeOnlyMinAge,
    'tab_iliskiler',
    <Finder>[find.byKey(const Key('relationships_pets_row'))],
    'Bakım gideri her yıl bir kez alınır',
  ),
  Bolum(
    'İŞ ARA',
    'education_career_pages.dart',
    (GameState s) =>
        !s.education.isStudent &&
        !s.career.isRetired &&
        !s.career.isEmployed &&
        s.player.age >= 18,
    'tab_okul_meslek',
    <Finder>[find.text('İş ara')],
    'Koşullarını sağladığın işlere başvurabilirsin',
  ),
  Bolum(
    'DÖVÜŞ SANATLARI',
    'martial_arts_page.dart',
    (GameState s) => s.player.age >= 18,
    'tab_aktiviteler',
    <Finder>[
      find.byKey(const Key('activity_spor')),
      find.text('Dövüş sanatları'),
    ],
    'Ders ucuz, ustalık pahalı',
  ),

  // ---- Paket DQ: son okunmamış kare ---------------------------------
  //
  // `social_pages.dart` kaydı `social_widget_test.dart`'ı gösteriyordu
  // ve o test sayfaya **giriyor** (pumpWidget 1, tap 5) ama kareyi
  // basmıyor (print 0). Ölçüldü: beş kayıttan yalnızca ikisi (döküm
  // basan `ekran_dokumu_test.dart`) kareyi gerçekten yazıyor. Dosya iki
  // kare barındırıyor ve ikincisinin başlığı **dinamik**
  // (`platform.label`), yani başlık taramasına hiç görünmüyordu.
  Bolum(
    'SOSYAL MEDYA',
    'social_pages.dart',
    (GameState s) => s.player.age >= kSocialMinAge,
    'tab_aktiviteler',
    <Finder>[find.text('Sosyal medya')],
    'Mesajlaşma henüz yazılmadı',
  ),
  Bolum(
    'SOSYAL PLATFORM',
    'social_pages.dart',
    (GameState s) =>
        s.player.age >= kSocialMinAge && s.socialAccounts.isNotEmpty,
    'tab_aktiviteler',
    <Finder>[
      find.text('Sosyal medya'),
      // Anahtar yalnızca **hesabı olan** platform kartında var; kapalı
      // kartı tıklamak kareyi değiştirmez ve araç yanlış sayfayı basar.
      find.byWidgetPredicate(
        (Widget w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('sosyal_platform_'),
        description: 'hesabı olan platform kartı',
      ),
    ],
    'bu yıl kalan:',
  ),
];



/// **Paket DR — modal ve panel kareleri.**
///
/// Bölüm sayfalarının hepsi okundu (Paket DM-DQ). Bir katman aşağıda
/// `lib/ui/widgets/` duruyor ve oyuncuya dönük metnin önemli bir kısmı
/// orada: ölçtüm, dosya başına cümle sayısı (kaynaktaki 18+ karakterlik
/// ve boşluk içeren dizgiler, yorumlar atılmış):
///
///   person_detail_sheet 65 · item_detail_sheet 20 · settings_sheet 14 ·
///   character_header 13 · elder_support_card 11 · notice_sheet 11 ·
///   pet_detail_sheet 10 · prison_life_panel 7 · license_exam_sheet 6 ·
///   track_choice_sheet 5
///
/// Bunların karesi **hiç basılmamıştı**: modal bir sayfa sekmeden
/// görünmüyor, bölüm dökümü oraya giremiyor. `notice_sheet` ve
/// `character_header` istisna (başka döküm basıyor).
///
/// Bu liste `ekran_dokumu_modal_test.dart` tarafından dolaşılıyor.
/// `Bolum` kaydının aynısı kullanılıyor; `dosya` alanı burada
/// `lib/ui/widgets/` altındaki dosyayı gösteriyor.
final List<Bolum> kModalKareleri = <Bolum>[
  Bolum(
    'KİŞİ KARTI',
    'person_detail_sheet.dart',
    (GameState s) => s.people.any(
      (Person p) =>
          p.relation == RelationType.anne || p.relation == RelationType.baba,
    ),
    'tab_iliskiler',
    <Finder>[find.byType(PersonCard)],
    'Cinsiyet',
  ),
  // **Aynı modalın üç karesi.** 0 yaşındaki kare `person_detail_sheet`in
  // yalnızca üst kısmını çiziyor: etkileşimler 4 yaşından itibaren
  // açılıyor, bakım kararları yaşlılıkta, çocuğa özel satırlar yalnızca
  // çocukta. Dosyanın 65 cümlesini okumak için üç ayrı kapı gerekiyor.
  Bolum(
    'KİŞİ KARTI · ÇOCUK',
    'person_detail_sheet.dart',
    (GameState s) => s.people.any(
      (Person p) => p.relation == RelationType.cocuk && p.age >= 4 && p.isAlive,
    ),
    'tab_iliskiler',
    <Finder>[
      find.byKey(const Key('relationships_children_row')),
      find.byType(PersonCard),
    ],
    'Cinsiyet',
  ),
  Bolum(
    'KİŞİ KARTI · YAŞLI ANNE',
    'person_detail_sheet.dart',
    (GameState s) => s.people.any(
      (Person p) =>
          p.relation == RelationType.anne && p.age >= 70 && p.isAlive,
    ),
    'tab_iliskiler',
    <Finder>[find.byType(PersonCard)],
    'Cinsiyet',
  ),
  Bolum(
    'VARLIK DETAYI',
    'item_detail_sheet.dart',
    (GameState s) => s.items.isNotEmpty,
    'tab_varliklar',
    <Finder>[
      find.byWidgetPredicate(
        (Widget w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('varlik_'),
        description: 'varlık satırı',
      ),
    ],
    'Edinildiği yaş',
  ),
  Bolum(
    'EVCİL HAYVAN DETAYI',
    'pet_detail_sheet.dart',
    (GameState s) => s.pets.isNotEmpty,
    'tab_iliskiler',
    <Finder>[
      find.byKey(const Key('relationships_pets_row')),
      find.byWidgetPredicate(
        (Widget w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('pet_detail_'),
        description: 'hayvan satırı',
      ),
    ],
    'Olağan ömür',
  ),
  Bolum(
    'AYARLAR',
    'settings_sheet.dart',
    (GameState s) => s.player.age >= 1,
    'tab_aktiviteler',
    <Finder>[find.byKey(const Key('open_settings'))],
    'Görünüm',
  ),
  // **Paket DS.** `prison_life_panel.dart` (7 cümle) "bekleyen durum
  // istiyor" diye bekleme listesinde duruyordu. Ölçüm başka bir şey
  // söyledi: kapı bekleyen bir şey değil, `isImprisoned`; panel
  // Aktiviteler sekmesindeki **bir satırın arkasında** duruyor
  // (`aktivite_cezaevi`). Özel durum dökümü o satırı **basıyor** ama
  // hiç **dokunmuyor**; bu yüzden panelin kendisi hiç çizilmedi.
  // Kayıt yanlış değil, eksikti: liste bekleme değil kapı sorunuydu.
  Bolum(
    'CEZAEVİ KOĞUŞU',
    'prison_life_panel.dart',
    (GameState s) => s.isImprisoned,
    'tab_aktiviteler',
    <Finder>[find.byKey(const Key('aktivite_cezaevi'))],
    'Koğuş hayatı',
  ),
];

/// Metin taşıyan ama karesi **henüz** basılmayan modal/panel dosyaları.
///
/// **Paket DS — liste yanlıştı ve kimse denetlemiyordu.** Paket DR bu
/// üç kaydı yazdı ama hiçbir test onları okumuyordu (ölçtüm:
/// `kModalBekleyen` ve `kModalBaskaTestle` depoda **sıfır** yerden
/// çağrılıyordu). Denetlenmeyen kayıt hemen eskidi: yedi "bekleyen"
/// dosyadan beşi aslında basılıyordu ya da basılabiliyordu.
///
/// Ölçüm (`ekran_dokumu_ozel_durum_test.dart` çıktısında her dosyanın
/// kendi cümlesi arandı):
///
///   elder_support_card   "Bu yıl kim yanında?"                1 kez
///   health_crisis_sheet  "Ne yapacağına sen karar veriyorsun." 1 kez
///   trial_sheet          "Avukat sonucu garanti etmez"         1 kez
///   pregnancy_notice     "Bebek yolda"                         2 kez
///   person_card          "vefat etti"                         37 kez
///   interview_sheet      "Karşındaki kişi bir soru soruyor."   0 kez
///   prison_life_panel    "Koğuş hayatı"                        0 kez
///   license_exam_sheet   "Geçmek için en az"                   0 kez
///   track_choice_sheet   "seçtiğin alan eğitim"                0 kez
///
/// Mülakat karesinin neden basılmadığı da ölçüldü ve **ürün hatası**
/// çıktı: dökümün açıcısı `career_mulakat_devam` satırını arıyordu, o
/// satır yalnızca kariyer görünümünde vardı ve bulunan kare 17
/// yaşındaki bir **lise öğrencisiydi**. Öğrencinin mülakata devam etme
/// yolu hiç yoktu (Paket DS, `school_career_screen.dart`). Satır
/// eklendi, açıcı iki anahtarı da deniyor, kare artık basılıyor.
///
/// Kalan iki dosya gerçekten bekliyor ve ikisi de **akış içi** modal:
/// ekranda bir satırın arkasında değil, bir eylemin ortasında
/// açılıyorlar. Liste yalnızca **küçülür**; yeni bir metin taşıyan
/// widget eklenirse `paket_ds_modal_kapsami_test.dart` düşer.
const List<String> kModalBekleyen = <String>[
  // 13 cümle · **DR'nin kaydı yanlıştı.** "Başka döküm basıyor"
  // deniyordu; ölçtüm: `ekran_dokumu_bildirim_pencereleri_test.dart`
  // bildirim penceresini çiziyor ama bastığı metin bildirimin
  // **içeriği** ("Biletin tutmadı. Numaran 021952 idi."), pencerenin
  // kendi cümleleri değil. Pencerenin 13 cümlesi cenaze seçenekleri ve
  // bebeğe ad verme dallarında duruyor ve o dallar üç dökümün
  // hiçbirinde çizilmedi (ölçüm: "Cenazeye katıl" 0, "Bebeğin adını
  // sen koyabilirsin" 0).
  'notice_sheet.dart',
  // 8 cümle · ehliyet sınavı akışının ortasında açılıyor: Aktiviteler →
  // Ehliyet → sınava gir. Dökümün tek adımlı yol kalıbına girmiyor.
  'license_exam_sheet.dart',
  // 8 cümle · ortaokul bitince gelen **bekleyen karar**; temiz kare
  // tanımı gereği (Paket CG/CR) bölüm dökümü o kareyi dışarıda
  // bırakıyor.
  'track_choice_sheet.dart',
];

/// Karesi **başka bir döküm** tarafından basılan modal/panel dosyası.
///
/// **İddia nasıl denetleniyor (Paket DS).** Üç halka da ölçülüyor:
///
/// 1. `isaret` o widget'ın **kendi kaynağında** geçiyor mu (kayıt
///    uydurma değil mi),
/// 2. adı yazılan test var mı, `pumpWidget` ve `print` çağırıyor mu
///    (kareyi gerçekten çiziyor ve basıyor mu),
/// 3. `isaret` o testin **kaynağında** bir ölçü olarak duruyor mu
///    (yani o test kareyi bastığını kendi iddia ediyor mu).
///
/// Üçüncü halka Paket DQ'nun dersinden geliyor: metin benzerliği bir
/// kapsam kanıtı değil. Özel durum dökümünde bu ölçüler `Durum`
/// kayıtlarının `isaret` alanı olarak duruyor ve o test kendi karesini
/// onlara göre denetliyor.
class ModalKaydi {
  const ModalKaydi(this.dosya, this.test, this.isaret);

  /// `lib/ui/widgets/` altındaki dosya adı.
  final String dosya;

  /// `app/test/` altındaki, kareyi basan test dosyası.
  final String test;

  /// O dosyanın kendi kaynağındaki, **çizilen** metin.
  final String isaret;
}

const List<ModalKaydi> kModalBaskaTestle = <ModalKaydi>[
  ModalKaydi(
    'character_header.dart',
    'ekran_dokumu_test.dart',
    'Evde seninle',
  ),
  ModalKaydi(
    'elder_support_card.dart',
    'ekran_dokumu_ozel_durum_test.dart',
    'Bu yıl kim yanında?',
  ),
  ModalKaydi(
    'health_crisis_sheet.dart',
    'ekran_dokumu_ozel_durum_test.dart',
    'Ne yapacağına sen karar veriyorsun.',
  ),
  ModalKaydi(
    'trial_sheet.dart',
    'ekran_dokumu_ozel_durum_test.dart',
    'Avukat sonucu garanti etmez',
  ),
  ModalKaydi(
    'pregnancy_notice.dart',
    'ekran_dokumu_ozel_durum_test.dart',
    'Bebek yolda',
  ),
  ModalKaydi(
    'person_card.dart',
    'ekran_dokumu_ozel_durum_test.dart',
    'vefat etti',
  ),
  // Paket DS'nin kendi testi: öğrencinin mülakat penceresini açıyor ve
  // basıyor. Özel durum dökümü de artık basıyor ama asıl kanıt burada:
  // o test pencerenin başlığını ve cümlesini ölçü olarak tutuyor.
  ModalKaydi(
    'interview_sheet.dart',
    'paket_ds_ogrenci_is_kapisi_test.dart',
    'Karşındaki kişi bir soru soruyor.',
  ),
];

/// Kaydı **çalışma zamanında** doğrular: basılan karelerde işaret var mı?
///
/// **Neden böyle (Paket DS).** "Bu dosyanın karesi şu test tarafından
/// basılıyor" cümlesi kaynak taramasıyla doğrulanamıyor: dökümün
/// bastığı metin kaynağında yazmaz, çalışırken oluşur. Paket DR'nin iki
/// kaydının ikisi de bu yüzden yanlıştı ve kimse görmedi
/// (`notice_sheet.dart` için "başka döküm basıyor" deniyordu; o döküm
/// bildirimin içeriğini basıyor, pencerenin cümlelerini değil).
///
/// Çözüm: kaydı **iddia eden** değil **basan** test doğruluyor. Her
/// döküm bastığı bütün metinleri toplayıp bu işlevi çağırıyor; işlev
/// kendisine ait kayıtları süzüp işaretleri arıyor. Kayıt eskirse o
/// dökümün kendisi düşer.
void modalKapsamDenetle(String testDosyasi, Iterable<String> basilan) {
  final List<ModalKaydi> benim = <ModalKaydi>[
    for (final ModalKaydi k in kModalBaskaTestle)
      if (k.test == testDosyasi) k,
  ];
  if (benim.isEmpty) return;
  final String hepsi = basilan.join('\n');
  final List<String> eksik = <String>[
    for (final ModalKaydi k in benim)
      if (!hepsi.contains(k.isaret)) '${k.dosya} → "${k.isaret}"',
  ];
  // ignore: avoid_print
  print('MODAL KAPSAM ($testDosyasi): ${benim.length} kayıt · '
      'eksik ${eksik.length}');
  expect(
    eksik,
    isEmpty,
    reason: 'Bu dosyaların karesi "$testDosyasi tarafından basılıyor" '
        'diye kayıtlı ama bu koşuda işaretleri hiç çizilmedi:\n'
        '${eksik.join("\n")}\n\n'
        'Ya kayıt eskidi (işaret değişti, kare artık basılmıyor) ya da '
        'döküm o kareyi kaybetti. Kaydı `kModalBaskaTestle` içinde '
        'düzelt ya da dosyayı `kModalBekleyen` kuyruğuna al — ölçmeden '
        '"okunuyor" yazma.',
  );
}

/// Dökümün dışındaki sayfalar ve **onları çizen** test.
///
/// Değer, `app/test/` altındaki dosya adıdır. Bekçi yalnızca adın
/// varlığına bakmakla kalmaz: o testin, sayfanın `SectionScaffold`
/// başlıklarından en az birini gerçekten andığını da doğrular. Böylece
/// kayıt "okunuyor" diye yazıp okumayan bir satır taşıyamaz.
const Map<String, String> kBaskaTestle = <String, String>{
};
