import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:bir_omur/ui/sound/sound_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_flow.dart';

/// Dar ekran, büyük yazı ve uzun isim taraması (Paket 45).
///
/// Taşma sessiz bir hatadır: içerik çizilmez, yalnızca hata şeridi görünür.
/// Bu paket üç ekseni birlikte zorlar:
/// - **Genişlik:** 320 (küçük Android), 360 (yaygın Android), 390 (iPhone).
/// - **Yazı ölçeği:** 1,0 · 1,3 · 1,5 (cihaz erişilebilirlik ayarı).
/// - **Uzun kullanıcı verisi:** uzun ad, uzun soyad, uzun meslek.
///
/// Uzun isimler **yalnızca testte** kullanılır; oyunun isim havuzuna
/// eklenmez.
const String kUzunAd = 'Abdülmuttalip';
const String kUzunSoyad = 'Canberk';
const String kUzunKisiAdi = 'Şehrazat';
const String kUzunKisiSoyadi = 'Nurhayatoğulları';
const String kUzunMeslek = 'kıdemli tekstil kalite kontrol uzmanı';

const List<double> kGenislikler = <double>[320, 360, 390];
const List<double> kYaziOlcekleri = <double>[1.0, 1.3, 1.5];

Person uzunIsimliKisi({
  required String id,
  required RelationType relation,
  required Gender gender,
  int age = 40,
  bool hane = true,
}) =>
    Person(
      id: id,
      firstName: kUzunKisiAdi,
      lastName: kUzunKisiSoyadi,
      gender: gender,
      relation: relation,
      age: age,
      isAlive: true,
      inPlayerHousehold: hane,
      employment: EmploymentStatus.calisiyor,
      occupation: kUzunMeslek,
      wealth: WealthTier.cokVarlikli,
      bond: 75,
    );

void main() {
  late List<String> hatalar;
  late void Function(FlutterErrorDetails)? eskiHandler;

  void yakala() {
    hatalar = <String>[];
    eskiHandler = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails d) {
      final String metin = d.exceptionAsString();
      if (metin.contains('overflowed')) {
        final StringBuffer satir = StringBuffer(metin.split('\n').first);
        for (final DiagnosticsNode n
            in d.informationCollector?.call() ?? const <DiagnosticsNode>[]) {
          final String t = n.toStringDeep();
          if (t.contains('debugCreator')) satir.write('\n      $t');
        }
        hatalar.add(satir.toString());
        return;
      }
      eskiHandler?.call(d);
    };
  }

  void birak() => FlutterError.onError = eskiHandler;

  /// Uzun isimli, varlıklı, yetişkin bir hayat kurar ve ekrana getirir.
  Future<GameController> hazirla(
    WidgetTester tester, {
    required double genislik,
    required double yaziOlcegi,
    int yas = 35,
    int cuzdan = 4000000,
    int seed = 21,
  }) async {
    final GameController controller = GameController(random: Random(seed));
    addTearDown(controller.dispose);
    tester.view.physicalSize = Size(genislik * 3, 2600);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = yaziOlcegi;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      BirOmurApp(controller: controller, sound: SoundService.silent()),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Rastgele bir hayat'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rastgele bir hayat'));
    await tester.pumpAndSettle();

    final GameState temel = controller.state!;
    controller.debugSetState(
      temel.copyWith(
        pendingEvent: null,
        notices: const <PendingNotice>[],
        player: temel.player.copyWith(
          firstName: kUzunAd,
          lastName: kUzunSoyad,
          age: yas,
          wallet: cuzdan,
        ),
        licenses: <String>{'otomobil_ehliyeti', 'motosiklet_ehliyeti'},
        people: <Person>[
          ...temel.people.map((Person p) => p.copyWith(
                firstName: kUzunKisiAdi,
                lastName: kUzunKisiSoyadi,
              )),
          uzunIsimliKisi(
            id: 'sevgili-1',
            relation: RelationType.sevgili,
            gender: temel.player.gender == Gender.erkek
                ? Gender.kadin
                : Gender.erkek,
            age: 33,
            hane: false,
          ),
          uzunIsimliKisi(
            id: 'cocuk-1',
            relation: RelationType.cocuk,
            gender: Gender.kadin,
            age: 9,
          ),
          uzunIsimliKisi(
            id: 'arkadas-1',
            relation: RelationType.arkadas,
            gender: Gender.erkek,
            age: 35,
            hane: false,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  /// Bir listeyi sonuna kadar kaydırır: alttaki satırlar da kurulur.
  Future<void> sonunaKaydir(WidgetTester tester, {int adim = 14}) async {
    final Finder liste = find.byType(Scrollable);
    if (liste.evaluate().isEmpty) return;
    for (int i = 0; i < adim; i++) {
      await tester.drag(liste.first, const Offset(0, -320));
      await tester.pumpAndSettle();
    }
  }

  void temiz() {
    expect(
      hatalar,
      isEmpty,
      reason: 'Düzen taşması:\n${hatalar.join('\n')}',
    );
  }

  // =================================================================
  // 1) Bütün ana sekmeler: 3 genişlik × 3 yazı ölçeği
  // =================================================================
  for (final double genislik in kGenislikler) {
    for (final double olcek in kYaziOlcekleri) {
      testWidgets(
          'ana sekmeler ${genislik.toInt()} px / yazı ×$olcek taşmaz',
          (WidgetTester tester) async {
        yakala();
        addTearDown(birak);
        await hazirla(tester, genislik: genislik, yaziOlcegi: olcek);

        for (final String sekme in <String>[
          'hayat',
          'okul_meslek',
          'varliklar',
          'iliskiler',
          'aktiviteler',
        ]) {
          final Finder f = find.byKey(Key('tab_$sekme'));
          if (f.evaluate().isEmpty) continue;
          await tester.tap(f);
          await tester.pumpAndSettle();
          await sonunaKaydir(tester);
        }
        temiz();
      });
    }
  }

  // =================================================================
  // 2) Aktiviteler alt sayfaları — en zor bileşimde (320 px, ×1.5)
  // =================================================================
  const List<({String anahtar, String ad})> altSayfalar =
      <({String anahtar, String ad})>[
    (anahtar: 'activity_eglence', ad: 'Eğlence'),
    (anahtar: 'activity_kurs', ad: 'Kurslar'),
    (anahtar: 'activity_saglik', ad: 'Sağlık Merkezi'),
    (anahtar: 'activity_fal', ad: 'Fal ve Tarot'),
    (anahtar: 'activity_piyango', ad: 'Piyango'),
    (anahtar: 'activity_finger', ad: 'Finger'),
    (anahtar: 'activity_hayvan', ad: 'Evcil hayvanlar'),
  ];

  for (final double genislik in <double>[320, 390]) {
    for (final ({String anahtar, String ad}) sayfa in altSayfalar) {
      testWidgets(
          '${sayfa.ad} sayfası ${genislik.toInt()} px / yazı ×1.5 taşmaz',
          (WidgetTester tester) async {
        yakala();
        addTearDown(birak);
        await hazirla(tester, genislik: genislik, yaziOlcegi: 1.5);

        await tester.tap(find.byKey(const Key('tab_aktiviteler')));
        await tester.pumpAndSettle();
        await scrollToFinder(tester, find.byKey(Key(sayfa.anahtar)));
        await tester.tap(find.byKey(Key(sayfa.anahtar)));
        await tester.pumpAndSettle();
        await sonunaKaydir(tester, adim: 18);
        temiz();
      });
    }
  }

  // =================================================================
  // 3) Menüden iki adım içerideki sayfalar
  // =================================================================
  testWidgets('dövüş sanatları sayfası 320 px / yazı ×1.5 taşmaz',
      (WidgetTester tester) async {
    yakala();
    addTearDown(birak);
    await hazirla(tester, genislik: 320, yaziOlcegi: 1.5);

    await tester.tap(find.byKey(const Key('tab_aktiviteler')));
    await tester.pumpAndSettle();
    await tapMenuRow(tester, 'Spor salonu');
    await tester.tap(find.byKey(const Key('spor_dovus')));
    await tester.pumpAndSettle();
    // Bütün basamak listelerini aç; dar ekranda dokunuş ıskalarsa sonsuz
    // döngüye girmesin diye sayaçla sınırlı.
    for (int i = 0; i < 6; i++) {
      final Finder baslik = find.text('Basamaklar');
      if (baslik.evaluate().isEmpty) break;
      await scrollToFinder(tester, baslik.first);
      await tester.tap(baslik.first, warnIfMissed: false);
      await tester.pumpAndSettle();
    }
    await sonunaKaydir(tester, adim: 22);
    temiz();
  });

  testWidgets('tatil sayfası 320 px / yazı ×1.5 taşmaz',
      (WidgetTester tester) async {
    yakala();
    addTearDown(birak);
    await hazirla(tester, genislik: 320, yaziOlcegi: 1.5);
    await tester.tap(find.byKey(const Key('tab_aktiviteler')));
    await tester.pumpAndSettle();
    await tapMenuRow(tester, 'Tatil yap');
    // D-083 ile sayfaya tur paketleri eklendi; liste uzadığı için daha
    // çok kaydırma gerekiyor.
    await sonunaKaydir(tester, adim: 34);
    temiz();
  });

  // D-088: Finger profil düzenleyicisi dar ekranda taşıyordu; artık
  // sınanıyor.
  testWidgets('Finger profil düzenleyici 320 px / yazı ×1.5 taşmaz',
      (WidgetTester tester) async {
    yakala();
    addTearDown(birak);
    await hazirla(tester, genislik: 320, yaziOlcegi: 1.5);
    await tester.tap(find.byKey(const Key('tab_aktiviteler')));
    await tester.pumpAndSettle();
    await tapMenuRow(tester, 'Finger');
    await sonunaKaydir(tester, adim: 12);
    final Finder ac = find.byKey(const Key('finger_profil_ac'));
    if (ac.evaluate().isNotEmpty) {
      await tester.tap(ac.first);
      await tester.pumpAndSettle();
      await sonunaKaydir(tester, adim: 30);
    }
    temiz();
  });

  // D-083: taşınma ayrı bir sayfa oldu; o da dar ekranda sınanır.
  testWidgets('taşınma sayfası 320 px / yazı ×1.5 taşmaz',
      (WidgetTester tester) async {
    yakala();
    addTearDown(birak);
    await hazirla(tester, genislik: 320, yaziOlcegi: 1.5);
    await tester.tap(find.byKey(const Key('tab_aktiviteler')));
    await tester.pumpAndSettle();
    await tapMenuRow(tester, 'Taşın');
    await sonunaKaydir(tester, adim: 20);
    temiz();
  });

  testWidgets('evlat edinme sayfası 320 px / yazı ×1.5 taşmaz',
      (WidgetTester tester) async {
    yakala();
    addTearDown(birak);
    await hazirla(tester, genislik: 320, yaziOlcegi: 1.5);
    await tester.tap(find.byKey(const Key('tab_aktiviteler')));
    await tester.pumpAndSettle();
    await tapMenuRow(tester, 'Evlat Edinme');
    await sonunaKaydir(tester, adim: 16);
    temiz();
  });

  testWidgets('ehliyet işlemleri 320 px / yazı ×1.5 taşmaz',
      (WidgetTester tester) async {
    yakala();
    addTearDown(birak);
    await hazirla(tester, genislik: 320, yaziOlcegi: 1.5);
    await tester.tap(find.byKey(const Key('tab_aktiviteler')));
    await tester.pumpAndSettle();
    await tapMenuRow(tester, 'Ehliyet İşlemleri');
    await sonunaKaydir(tester, adim: 16);
    temiz();
  });

  // =================================================================
  // 4) Kişi detayı ve evlilik akışı — uzun isimle
  // =================================================================
  testWidgets('kişi detayı 320 px / yazı ×1.5 taşmaz ve geri düğmesi '
      'erişilebilir kalır', (WidgetTester tester) async {
    yakala();
    addTearDown(birak);
    final GameController controller =
        await hazirla(tester, genislik: 320, yaziOlcegi: 1.5);

    await tester.tap(find.byKey(const Key('tab_iliskiler')));
    await tester.pumpAndSettle();
    await scrollToFinder(
      tester,
      find.text('$kUzunKisiAdi $kUzunKisiSoyadi').first,
    );
    await tester.tap(find.text('$kUzunKisiAdi $kUzunKisiSoyadi').first);
    await tester.pumpAndSettle();
    await sonunaKaydir(tester, adim: 16);
    temiz();

    // Sayfa kapatılabiliyor: modal kilitli kalmıyor.
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
    expect(controller.state, isNotNull);
  });

  testWidgets('evlilik teklifi ve düğün ekranı 320 px / yazı ×1.5 taşmaz',
      (WidgetTester tester) async {
    yakala();
    addTearDown(birak);
    await hazirla(tester, genislik: 320, yaziOlcegi: 1.5);

    await tester.tap(find.byKey(const Key('tab_iliskiler')));
    await tester.pumpAndSettle();
    await scrollToFinder(
      tester,
      find.text('$kUzunKisiAdi $kUzunKisiSoyadi').first,
    );
    await tester.tap(find.text('$kUzunKisiAdi $kUzunKisiSoyadi').first);
    await tester.pumpAndSettle();

    final Finder teklif = find.byKey(const Key('person_marry_button'));
    if (teklif.evaluate().isNotEmpty) {
      await scrollToFinder(tester, teklif);
      await tester.tap(teklif);
      await tester.pumpAndSettle();
      await sonunaKaydir(tester, adim: 14);
    }
    temiz();
  });

  // =================================================================
  // 5) Hayat sonu: ölüm ekranı ve değerlendirme
  // =================================================================
  testWidgets('hayat sonu değerlendirmesi 320 px / yazı ×1.5 taşmaz',
      (WidgetTester tester) async {
    yakala();
    addTearDown(birak);
    final GameController controller =
        await hazirla(tester, genislik: 320, yaziOlcegi: 1.5, yas: 70);

    int guard = 0;
    while (!controller.state!.deceased) {
      if (guard++ > 120) break;
      resolvePendingEvents(controller);
      // Lise alanı seçilmeden yaş atlanmaz (D-094).
      resolveTrackChoice(controller);
      controller.ageUp();
    }
    resolvePendingEvents(controller);
    await tester.pumpAndSettle();
    if (!controller.state!.deceased) return;

    await sonunaKaydir(tester, adim: 25);
    temiz();
  });

  // =================================================================
  // 6) Ayarlar
  // =================================================================
  testWidgets('ayarlar 320 px / yazı ×1.5 taşmaz',
      (WidgetTester tester) async {
    yakala();
    addTearDown(birak);
    await hazirla(tester, genislik: 320, yaziOlcegi: 1.5);

    final Finder ayarlar = find.byIcon(Icons.settings_rounded);
    if (ayarlar.evaluate().isEmpty) return;
    await tester.tap(ayarlar.first);
    await tester.pumpAndSettle();
    await sonunaKaydir(tester, adim: 12);
    temiz();
  });

  // =================================================================
  // 7) Başlangıç ekranı: düğmeye her genişlikte ulaşılabilmeli
  // =================================================================
  for (final double genislik in kGenislikler) {
    for (final double olcek in kYaziOlcekleri) {
      testWidgets(
          'başlangıç ekranında düğmeye ulaşılabiliyor '
          '(${genislik.toInt()} px / ×$olcek)', (WidgetTester tester) async {
        yakala();
        addTearDown(birak);
        final GameController controller = GameController(random: Random(7));
        addTearDown(controller.dispose);
        tester.view.physicalSize = Size(genislik * 3, 2000);
        tester.view.devicePixelRatio = 3;
        tester.platformDispatcher.textScaleFactorTestValue = olcek;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        await tester.pumpWidget(
          BirOmurApp(controller: controller, sound: SoundService.silent()),
        );
        await tester.pumpAndSettle();

        // Ekrana sığmıyorsa bile kaydırılarak ulaşılabilmeli.
        await tester.ensureVisible(find.text('Rastgele bir hayat'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Rastgele bir hayat'));
        await tester.pumpAndSettle();
        expect(controller.state, isNotNull,
            reason: 'Düğmeye ulaşılamadı; hayat başlamadı');
        temiz();
      });
    }
  }
}
