// Bölüm sayfalarının kapsam kaydı (Paket DM).
//
// **Neden ayrı dosya.** İki test aynı listeyi okuyor:
// `ekran_dokumu_bolumler_test.dart` sayfaları açıp metnini basıyor,
// `paket_dm_bolum_kapsami_test.dart` ise `lib/ui/screens/sections/`
// altındaki **her** sayfanın bir okuyucusu olduğunu denetliyor. Liste
// tek yerde durmazsa ikisi sessizce ayrışır.
library;

import 'package:bir_omur/domain/career/military_service.dart';
import 'package:bir_omur/domain/economy/banking.dart';
import 'package:bir_omur/domain/economy/furnishing.dart';
import 'package:bir_omur/domain/features/feature_catalog.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/military.dart';
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
    (GameState s) =>
        s.player.age >= MilitaryService.prototypeOnlyMinAge ||
        s.military.status != MilitaryStatus.yok,
    'tab_okul_meslek',
    <Finder>[find.byKey(const Key('career_military_row'))],
    'Katılma yolları',
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
  'activity_pages.dart': 'activities_test.dart',
  'assets_screen.dart': 'ekran_dokumu_test.dart',
  'business_page.dart': 'business_widget_test.dart',
  'casino_pages.dart': 'casino_widget_test.dart',
  'education_career_pages.dart': 'career_widget_test.dart',
  'fertility_page.dart': 'fertility_widget_test.dart',
  'finger_page.dart': 'finger_test.dart',
  'health_history_page.dart': 'paket_y_widget_test.dart',
  'investments_page.dart': 'paket_aa_widget_test.dart',
  'legal_record_page.dart': 'bail_prison_widget_test.dart',
  'license_pages.dart': 'license_widget_test.dart',
  'life_goals_page.dart': 'paket_y_widget_test.dart',
  'lottery_page.dart': 'lottery_widget_test.dart',
  'martial_arts_page.dart': 'martial_arts_widget_test.dart',
  'pets_page.dart': 'pet_widget_test.dart',
  'properties_page.dart': 'paket_ab_widget_test.dart',
  'relationships_screen.dart': 'ekran_dokumu_test.dart',
  'school_career_screen.dart': 'after_school_widget_test.dart',
  'school_clubs_page.dart': 'paket_av_sports_ui_test.dart',
  'social_pages.dart': 'social_widget_test.dart',
  'sports_career_page.dart': 'paket_av_sports_ui_test.dart',
};
