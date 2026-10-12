// Paket CV — 1 yaşındaki oyuncuya berber, spor salonu ve kütüphane.
//
// **Nereden çıktı.** Ekran dökümünün sekizinci turu. Paket CR'nin
// `onPending` kancası dökümün tarayıcısına bağlandı ve üç yeni kare
// eklendi (MÜLAKAT, BEKLEYEN OLAY, GEÇİM SIKINTISI). BEKLEYEN OLAY
// karesi **1 yaşında** bir hayat yakaladı ve Aktiviteler ekranının
// dökümü şunu bastı:
//
//     Kendine bak
//     Berber / Kuaför      Saç kestir, stil değiştir, bakım yaptır
//     Spor salonu          Koşu, ağırlık ve temel egzersiz
//     Sağlık Merkezi       Kontroller, aşı ve bir uzmanla konuşmak
//     Öğren
//     Kütüphane            Yaşına uygun kitap seç ve oku
//
// Bir yaşındaki bebeğe saç stili, ağırlık antrenmanı ve kitap.
//
// **Kök neden.** `ActivityVenue.minAge` zaten var ve belgesi niyeti
// yazıyor: *"Menüde yaşına hiç uymayan bir alan gösterilmesin diye
// kullanılır: çalışmayan düğme konmaz."* Kapı **beş** satıra
// uygulanmıştı ama üçü açıkta kalmıştı. Ölçülen eşikler:
//
// | mekân | en küçük eylem yaşı | kapı var mıydı |
// |---|---|---|
// | `cezaevi` | 0 | (hükümlülük kapısı) |
// | `saglikMerkezi` | 1 | ✓ |
// | `berber` | **4** | **yok** |
// | `eglence` | 4 | ✓ |
// | `kurs` | 6 | ✓ |
// | `sporSalonu` | **8** | **yok** |
// | `falTarot` | 10 | ✓ |
// | `estetik` | 18 | ✓ |
//
// Kütüphanenin kendi eylemi yok (kitap akışıyla çalışır) ve `minAge`
// 0 dönüyor; oradaki doğru kapı kataloğun kendisi — `kBookCatalog`
// içindeki en küçük kitap yaşı **6**. Daha küçük oyuncuya açılan sayfa
// boştu.
//
// Üç satırın hiçbirinde `Key` de yoktu; bu yüzden hiçbir test onları
// aramıyordu. Anahtarlar da eklendi.

import 'dart:math';

import 'package:bir_omur/data/activity_catalog.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:bir_omur/state/game_scope.dart';
import 'package:bir_omur/ui/screens/sections/activities_screen.dart';
import 'package:bir_omur/ui/theme/bir_omur_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/player_bot.dart';

/// Dövüş sanatlarının en küçük başlama yaşı (`martial_arts_catalog`).
const int kDovusYasi = 7;

/// Kök menüdeki mekân satırları ve **gerçek** açılma yaşları.
///
/// Yaş `ActivityVenue.minAge` değil **etkin kapı**: bir mekân satırı,
/// sayfasının barındırdığı en erken şey ne zaman açılıyorsa o zaman
/// açılır. Spor salonunun eylemleri 8'de başlıyor ama sayfası dövüş
/// sanatları bölümünü de taşıyor ve o 7'de başlıyor; satırın kapısı bu
/// yüzden 7. İlk yazımda bu tablo `minAge`'i doğru kapı sanmış ve kendi
/// bekçim kodu haksız yere suçlamıştı.
List<(String, String, int)> get kKapiliSatirlar => <(String, String, int)>[
      ('activity_berber', ActivityVenue.berber.label,
          ActivityVenue.berber.minAge),
      ('activity_spor', ActivityVenue.sporSalonu.label,
          ActivityVenue.sporSalonu.minAge < kDovusYasi
              ? ActivityVenue.sporSalonu.minAge
              : kDovusYasi),
      ('activity_saglik', ActivityVenue.saglikMerkezi.label,
          ActivityVenue.saglikMerkezi.minAge),
      ('activity_estetik', ActivityVenue.estetik.label,
          ActivityVenue.estetik.minAge),
      ('activity_kurs', ActivityVenue.kurs.label,
          ActivityVenue.kurs.minAge),
      ('activity_eglence', ActivityVenue.eglence.label,
          ActivityVenue.eglence.minAge),
      ('activity_fal', ActivityVenue.falTarot.label,
          ActivityVenue.falTarot.minAge),
    ];

void main() {
  testWidgets('hiçbir mekân satırı yaşından önce görünmez', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 14000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Kareler **aranıyor**: bot gerçek hayatlar oynuyor ve her yaştan
    // birer kare toplanıyor. Durum elle kurulmuyor (DURUM KURMA, ARA).
    final Map<int, GameState> kareler = <int, GameState>{};
    for (int seed = 0; seed < 12 && kareler.length < 20; seed++) {
      playBotLife(
        archetype: PlayerArchetype.casual,
        seed: 50000 + seed,
        onPreAge: (GameState s) {
          final int y = s.player.age;
          if (y <= 20) kareler.putIfAbsent(y, () => s);
        },
      );
    }
    // 0-20 arası yaşların çoğu bulunmalı; yoksa test boşa geçerdi.
    expect(kareler.length, greaterThanOrEqualTo(18),
        reason: 'bulunan yaş karesi: ${kareler.keys.toList()..sort()}');

    final List<String> hatalar = <String>[];
    final List<String> eksikler = <String>[];

    for (final int yas in kareler.keys.toList()..sort()) {
      final GameController c = GameController(random: Random(900 + yas))
        ..debugSetState(kareler[yas]!);
      addTearDown(c.dispose);
      await tester.pumpWidget(GameScope(
        controller: c,
        child: MaterialApp(
          theme: BirOmurTheme.light(),
          home: Scaffold(body: ActivitiesScreen(onBack: () {})),
        ),
      ));
      await tester.pumpAndSettle();

      for (final (String anahtar, String ad, int kapi)
          in kKapiliSatirlar) {
        final bool goruluyor =
            find.byKey(Key(anahtar)).evaluate().isNotEmpty;
        final bool olmali = yas >= kapi;
        if (goruluyor && !olmali) {
          hatalar.add('$yas yaş: $ad görünüyor (en küçük $kapi)');
        }
        if (!goruluyor && olmali) {
          eksikler.add('$yas yaş: $ad görünmüyor (en küçük $kapi)');
        }
      }

      // Kütüphane: kapı kataloğun kendisi.
      final bool kutuphane =
          find.byKey(const Key('activity_kutuphane')).evaluate().isNotEmpty;
      final bool kitapVar = booksFor(yas).isNotEmpty;
      if (kutuphane && !kitapVar) {
        hatalar.add('$yas yaş: Kütüphane görünüyor ama o yaşa kitap yok');
      }
      if (!kutuphane && kitapVar) {
        eksikler.add('$yas yaş: Kütüphane görünmüyor ama kitap var');
      }
    }

    expect(hatalar, isEmpty,
        reason: 'yaşından önce açılan satır:\n${hatalar.join('\n')}');
    // Kapı fazla sıkılmasın: yaşı gelen satır gerçekten görünmeli.
    expect(eksikler, isEmpty,
        reason: 'yaşı geldiği hâlde görünmeyen satır:\n'
            '${eksikler.join('\n')}');
  });

  test('mekân satırı içindeki en erken şeye göre açılır', () {
    // **Paket CV'nin kendi gerilemesinin dersi.** Spor salonu satırına
    // ilk konan kapı `ActivityVenue.sporSalonu.minAge` (8) idi; oysa o
    // sayfa dövüş sanatları bölümünü de barındırıyor ve dövüş **7**
    // yaşında başlıyor. Sonuç: 7 yaşındaki oyuncu karateye hiç
    // ulaşamıyordu. `ActivityVenue.minAge` yalnızca o mekânın
    // **eylemlerine** bakar; sayfanın ek satırlarını görmez.
    //
    // Bu test o ilişkiyi kayda geçirir: dövüş yaşı spor salonunun
    // eylem yaşından küçük olduğu sürece satırın kapısı dövüş yaşı
    // olmalı. Biri yükselirse test yeniden ölçmeye zorlar.
    expect(kDovusYasi, lessThan(ActivityVenue.sporSalonu.minAge),
        reason: 'dövüş yaşı artık spor salonundan küçük değil: kapı '
            'yeniden ölçülmeli');
    // Spor salonu satırının bekçisi `martial_arts_widget_test.dart`
    // içinde: 4 yaşında satır yok, 7 yaşında satır **ve** dövüş bölümü
    // var.
  });

  test('ölçülen eşikler kayıtta sabit', () {
    // Katalog büyüdükçe eşik düşebilir; o zaman bu test, kapının hangi
    // sayıya dayandığını **yeniden ölçmeye** zorlar.
    expect(ActivityVenue.berber.minAge, 4);
    expect(ActivityVenue.sporSalonu.minAge, 8);
    expect(ActivityVenue.saglikMerkezi.minAge, 1);
    expect(ActivityVenue.eglence.minAge, 4);
    expect(ActivityVenue.kurs.minAge, 6);
    expect(ActivityVenue.falTarot.minAge, 10);
    expect(ActivityVenue.estetik.minAge, 18);
    // Kütüphanenin eylemi yok: 0 döner (eski hâli 120 dönüyordu).
    expect(ActivityVenue.kutuphane.minAge, 0);
    // Kitapların en küçük yaşı kütüphanenin gerçek kapısı.
    expect(booksFor(5), isEmpty);
    expect(booksFor(6), isNotEmpty);
  });
}
