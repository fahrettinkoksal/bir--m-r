import 'dart:io';
import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/game_settings.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:bir_omur/ui/sound/sound_scope.dart';
import 'package:bir_omur/ui/sound/sound_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ses çalmayı kaydeden, gerçekten ses çıkarmayan sahte servis.
class KayitliSesServisi implements SoundService {
  final List<GameSound> calinanlar = <GameSound>[];

  @override
  bool enabled = true;

  @override
  Future<void> play(GameSound sound) async {
    if (!enabled) return;
    calinanlar.add(sound);
  }

  @override
  Future<void> dispose() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  // ===================================================================
  // Ses dosyaları
  // ===================================================================
  group('Ses dosyaları', () {
    test('her ses için gerçek bir dosya var ve boyutu makul', () {
      for (final GameSound s in GameSound.values) {
        final File f = File('assets/${s.asset}');
        expect(f.existsSync(), isTrue, reason: '${s.asset} yok');
        final int boyut = f.lengthSync();
        expect(boyut, greaterThan(1000), reason: '${s.asset} çok küçük');
        // Kısa efektler: yarım megabaytı geçmemeli.
        expect(boyut, lessThan(512 * 1024), reason: '${s.asset} çok büyük');
      }
    });

    test('ses varlıkları pubspec içinde tanımlı', () {
      final String pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('assets/sounds/'));
    });
  });

  // ===================================================================
  // Ayar
  // ===================================================================
  group('Ses ayarı', () {
    test('varsayılan olarak açık ve kayıtla saklanır', () {
      const GameSettings varsayilan = GameSettings();
      expect(varsayilan.soundEnabled, isTrue);

      final GameState s =
          LifeGenerator.seeded(171).generate(mode: StartMode.tamamenRastgele);
      final GameState sessiz = s.copyWith(
        settings: s.settings.copyWith(soundEnabled: false),
      );
      final GameState geri = decodeGameState(encodeGameState(sessiz));
      expect(geri.settings.soundEnabled, isFalse);
    });

    test('eski kayıtta ses ayarı yoksa açık kabul edilir', () {
      final GameState s =
          LifeGenerator.seeded(172).generate(mode: StartMode.tamamenRastgele);
      final Map<String, Object?> body =
          Map<String, Object?>.from(encodeGameState(s));
      final Map<String, Object?> ayarlar =
          Map<String, Object?>.from(body['settings']! as Map<String, Object?>)
            ..remove('soundEnabled');
      body['settings'] = ayarlar;

      expect(decodeGameState(body).settings.soundEnabled, isTrue);
    });

    test('kapalıyken servis hiç ses çalmaz', () async {
      final KayitliSesServisi servis = KayitliSesServisi()..enabled = false;
      await servis.play(GameSound.tap);
      await servis.play(GameSound.ageUp);
      expect(servis.calinanlar, isEmpty);
    });
  });

  // ===================================================================
  // Arayüzde tetiklenme
  // ===================================================================
  group('Arayüz sesleri', () {
    late GameController controller;
    late KayitliSesServisi ses;

    setUp(() {
      controller = GameController(random: Random(61));
      ses = KayitliSesServisi();
    });
    tearDown(() => controller.dispose());

    Future<void> pumpApp(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 4200);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        BirOmurApp(controller: controller, sound: ses),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rastgele bir hayat'));
      await tester.pumpAndSettle();
    }

    testWidgets('menü satırına dokununca tık sesi çalar',
        (WidgetTester tester) async {
      await pumpApp(tester);
      ses.calinanlar.clear();

      await tester.tap(find.byKey(const Key('tab_iliskiler')));
      await tester.pumpAndSettle();
      expect(ses.calinanlar, contains(GameSound.tap));
    });

    testWidgets('Yaş Al kendi sesini çalar', (WidgetTester tester) async {
      await pumpApp(tester);
      ses.calinanlar.clear();

      await tester.tap(find.byKey(const Key('age_up_button')));
      await tester.pumpAndSettle();
      expect(ses.calinanlar, contains(GameSound.ageUp));
    });

    testWidgets('ayarlardan kapatılınca ses çalınmaz',
        (WidgetTester tester) async {
      await pumpApp(tester);
      await tester.tap(find.byKey(const Key('open_settings')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('settings_sound_toggle')), findsOneWidget);
      await tester.tap(find.byKey(const Key('settings_sound_toggle')));
      await tester.pumpAndSettle();

      expect(controller.state!.settings.soundEnabled, isFalse);
      expect(ses.enabled, isFalse);

      // Ayar penceresini kapat ve normal bir menü satırına dokun:
      // kapalıyken hiçbir ses kaydedilmez.
      Navigator.of(tester.element(find.byType(SwitchListTile).first)).pop();
      await tester.pumpAndSettle();
      ses.calinanlar.clear();

      await tester.tap(find.byKey(const Key('tab_varliklar')));
      await tester.pumpAndSettle();
      expect(ses.calinanlar, isEmpty);
    });

    testWidgets('ses servisi olmadan da uygulama çalışır',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 4200);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Ses kapsamı olmayan bir ağaçta bile satırlar çalışmalı.
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              // Kapsam yoksa sessizce geçilir.
              SoundScope.play(context, GameSound.tap);
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
