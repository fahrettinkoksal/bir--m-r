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
import 'package:bir_omur/data/investment_catalog.dart';
import 'package:bir_omur/data/lottery_catalog.dart';
import 'package:bir_omur/domain/career/military_service.dart';
import 'package:bir_omur/domain/economy/banking.dart';
import 'package:bir_omur/domain/economy/furnishing.dart';
import 'package:bir_omur/domain/features/feature_catalog.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/military.dart';
import 'package:bir_omur/domain/models/owned_item.dart';
import 'package:bir_omur/domain/models/school_club_progress.dart';
import 'package:bir_omur/domain/activities/travel.dart';
import 'package:bir_omur/domain/interaction/intimacy.dart';
import 'package:bir_omur/domain/interaction/parenthood.dart';
import 'package:bir_omur/domain/social/media_opportunities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Dökümü alınan bir bölüm sayfası.
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
];



/// Dökümün dışındaki sayfalar ve **onları çizen** test.
///
/// Değer, `app/test/` altındaki dosya adıdır. Bekçi yalnızca adın
/// varlığına bakmakla kalmaz: o testin, sayfanın `SectionScaffold`
/// başlıklarından en az birini gerçekten andığını da doğrular. Böylece
/// kayıt "okunuyor" diye yazıp okumayan bir satır taşıyamaz.
const Map<String, String> kBaskaTestle = <String, String>{
  'activities_screen.dart': 'content_reachability_test.dart',
  'assets_screen.dart': 'ekran_dokumu_test.dart',
  'casino_pages.dart': 'casino_widget_test.dart',
  'education_career_pages.dart': 'career_widget_test.dart',
  'license_pages.dart': 'license_widget_test.dart',
  'martial_arts_page.dart': 'martial_arts_widget_test.dart',
  'pets_page.dart': 'pet_widget_test.dart',
  'relationships_screen.dart': 'ekran_dokumu_test.dart',
  'school_career_screen.dart': 'after_school_widget_test.dart',
  'social_pages.dart': 'social_widget_test.dart',
};
