// Paket BQ — görünüm seçimi (açık / koyu / cihaza göre).
//
// **Ölçülen sorun.** Oyunda koyu tema baştan beri vardı
// (`BirOmurTheme.dark()`, golden testleri iki temayı da çekiyor) ama
// oyuncu seçemiyordu: uygulamanın kökünde `themeMode` sabit
// `ThemeMode.system`'di. Yani telefonun ayarı neyse oyun onu kullanıyor,
// "ben koyu istiyorum" diyen oyuncunun yapabileceği hiçbir şey yoktu.
//
// Bu dosya dört şeyi bekçiler:
//   1. Seçim kayda giriyor ve geri okunuyor; eski kayıt bozulmuyor.
//   2. Ayarlardan seçilince uygulama gerçekten o temaya geçiyor.
//   3. Seçim kaydedilip yeniden yüklenince korunuyor.
//   4. Testlerin tema zorlaması (golden kareleri) kayıttan güçlü.
library;

import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/game_settings.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:bir_omur/ui/sound/sound_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Paket BQ — kayıt', () {
    test('seçim kayda girer ve geri okunur', () {
      final GameController c = GameController(random: Random(3));
      addTearDown(c.dispose);
      c.startNewLife(mode: StartMode.tamamenRastgele, seed: 3);
      c.updateSettings(
        c.state!.settings.copyWith(themeChoice: AppThemeChoice.koyu),
      );

      final Map<String, Object?> json = encodeGameState(c.state!);
      final GameState geri = decodeGameState(json);
      expect(geri.settings.themeChoice, AppThemeChoice.koyu);
    });

    test('eski kayıtta alan yok: cihazın ayarı geçerli', () {
      final GameController c = GameController(random: Random(5));
      addTearDown(c.dispose);
      c.startNewLife(mode: StartMode.tamamenRastgele, seed: 5);
      final Map<String, Object?> json = encodeGameState(c.state!);
      // Eski sürümün kaydını taklit et: alan hiç yok.
      (json['settings']! as Map<String, Object?>).remove('themeChoice');
      expect(
        decodeGameState(json).settings.themeChoice,
        AppThemeChoice.sistem,
      );
    });

    test('tanınmayan anahtar sessizce cihaz ayarına döner', () {
      // Silinmiş ya da ileri sürümden gelen bir seçim kaydı çökertmez.
      expect(AppThemeChoice.byKey('mor'), AppThemeChoice.sistem);
      expect(AppThemeChoice.byKey(null), AppThemeChoice.sistem);
      expect(AppThemeChoice.byKey('koyu'), AppThemeChoice.koyu);
    });

    test('her seçimin kayıt anahtarı ve adı benzersiz', () {
      final Set<String> anahtarlar =
          AppThemeChoice.values.map((AppThemeChoice c) => c.saveKey).toSet();
      final Set<String> adlar =
          AppThemeChoice.values.map((AppThemeChoice c) => c.label).toSet();
      expect(anahtarlar.length, AppThemeChoice.values.length);
      expect(adlar.length, AppThemeChoice.values.length);
    });
  });

  group('Paket BQ — ayarlardan seçim', () {
    late GameController controller;

    setUp(() => controller = GameController(random: Random(61)));
    tearDown(() => controller.dispose());

    Future<void> ac(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 4200);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        BirOmurApp(controller: controller, sound: SoundService.silent()),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rastgele bir hayat'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('open_settings')));
      await tester.pumpAndSettle();
    }

    ThemeMode kip(WidgetTester tester) =>
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode!;

    testWidgets('üç seçenek de ekranda ve varsayılan cihaz ayarı',
        (WidgetTester tester) async {
      await ac(tester);
      for (final AppThemeChoice secim in AppThemeChoice.values) {
        expect(find.byKey(Key('settings_theme_${secim.saveKey}')),
            findsOneWidget,
            reason: '${secim.label} seçeneği ekranda yok');
      }
      expect(controller.state!.settings.themeChoice, AppThemeChoice.sistem);
      expect(kip(tester), ThemeMode.system);
    });

    testWidgets('koyu seçilince uygulama koyuya geçiyor',
        (WidgetTester tester) async {
      await ac(tester);
      await tester.tap(find.byKey(const Key('settings_theme_koyu')));
      await tester.pumpAndSettle();

      expect(controller.state!.settings.themeChoice, AppThemeChoice.koyu);
      expect(kip(tester), ThemeMode.dark);
      // Ekran gerçekten koyu çiziliyor: ayar sayfası kipi takip ediyor.
      final BuildContext ctx = tester.element(find.text('Görünüm'));
      expect(Theme.of(ctx).brightness, Brightness.dark);
    });

    testWidgets('açık seçilince cihaz koyu olsa da açık kalıyor',
        (WidgetTester tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await ac(tester);
      await tester.tap(find.byKey(const Key('settings_theme_acik')));
      await tester.pumpAndSettle();

      expect(kip(tester), ThemeMode.light);
      final BuildContext ctx = tester.element(find.text('Görünüm'));
      expect(Theme.of(ctx).brightness, Brightness.light);
    });

    testWidgets('seçim kayıttan geri yüklenince korunuyor',
        (WidgetTester tester) async {
      await ac(tester);
      await tester.tap(find.byKey(const Key('settings_theme_koyu')));
      await tester.pumpAndSettle();

      // Kaydı yaz, yeni bir denetleyiciye oku: oyuncu oyunu kapatıp
      // açtığında seçimi duruyor mu?
      final Map<String, Object?> json = encodeGameState(
        controller.state!,
      );
      final GameController ikinci = GameController(random: Random(7));
      addTearDown(ikinci.dispose);
      ikinci.debugSetState(decodeGameState(json));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        BirOmurApp(controller: ikinci, sound: SoundService.silent()),
      );
      await tester.pumpAndSettle();

      expect(ikinci.state!.settings.themeChoice, AppThemeChoice.koyu);
      expect(kip(tester), ThemeMode.dark);
    });

    testWidgets('test zorlaması kayıttan güçlü (golden kareleri)',
        (WidgetTester tester) async {
      await ac(tester);
      await tester.tap(find.byKey(const Key('settings_theme_acik')));
      await tester.pumpAndSettle();
      // Kayıt "açık" diyor; golden testi aynı kareyi koyu çekmek için
      // kipi zorluyor. Zorlama kazanmalı, yoksa koyu kareler kaybolur.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        BirOmurApp(
          controller: controller,
          sound: SoundService.silent(),
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pumpAndSettle();

      expect(controller.state!.settings.themeChoice, AppThemeChoice.acik);
      expect(kip(tester), ThemeMode.dark);
    });
  });
}
