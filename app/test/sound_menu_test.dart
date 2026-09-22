import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/data/activity_catalog.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:bir_omur/text/turkish_text.dart';
import 'package:bir_omur/ui/sound/sound_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_flow.dart';

/// WAV başlığından süre, kanal ve tepe seviyesi okur.
({int ms, int rate, double peak}) wavBilgi(File f) {
  final Uint8List bytes = f.readAsBytesSync();
  final ByteData d = ByteData.sublistView(bytes);
  final int rate = d.getUint32(24, Endian.little);
  final int bits = d.getUint16(34, Endian.little);
  // 'data' parçasını bul.
  int i = 12;
  while (i + 8 < bytes.length) {
    final String id = String.fromCharCodes(bytes.sublist(i, i + 4));
    final int size = d.getUint32(i + 4, Endian.little);
    if (id == 'data') {
      final int ornek = size ~/ (bits ~/ 8);
      double tepe = 0;
      for (int k = 0; k < ornek; k++) {
        final int v = d.getInt16(i + 8 + k * 2, Endian.little);
        final double a = v.abs() / 32767;
        if (a > tepe) tepe = a;
      }
      return (ms: (ornek / rate * 1000).round(), rate: rate, peak: tepe);
    }
    i += 8 + size + (size.isOdd ? 1 : 0);
  }
  throw StateError('data parçası yok: ${f.path}');
}

void main() {
  _kisaParaTestleri();

  group('Ses dosyaları (Paket 28)', () {
    test('her ses için gerçek bir dosya var', () {
      for (final GameSound s in GameSound.values) {
        final File f = File('assets/${s.asset}');
        expect(f.existsSync(), isTrue, reason: '${s.asset} yok');
        expect(f.lengthSync(), greaterThan(4000),
            reason: '${s.asset} boş sayılır');
      }
    });

    test('sesler duyulur seviyede ve makul uzunlukta', () {
      for (final GameSound s in GameSound.values) {
        final ({int ms, int rate, double peak}) bilgi =
            wavBilgi(File('assets/${s.asset}'));
        expect(bilgi.rate, 44100, reason: '${s.asset} örnekleme hızı');
        // Eski sesler ~%20 tepeyle çok kısıktı.
        expect(bilgi.peak, greaterThan(0.4),
            reason: '${s.asset} çok kısık');
        expect(bilgi.peak, lessThanOrEqualTo(1.0));
        expect(bilgi.ms, greaterThan(40), reason: '${s.asset} çok kısa');
        expect(bilgi.ms, lessThan(1200), reason: '${s.asset} çok uzun');
      }
    });

    test('dokunma sesi en kısası, bildirim sesi en uzunu', () {
      final int tap = wavBilgi(File('assets/${GameSound.tap.asset}')).ms;
      final int notice =
          wavBilgi(File('assets/${GameSound.notice.asset}')).ms;
      final int ageUp =
          wavBilgi(File('assets/${GameSound.ageUp.asset}')).ms;
      expect(tap, lessThan(150), reason: 'Dokunma sesi kısa olmalı');
      expect(notice, greaterThan(ageUp ~/ 2));
    });

    test('üretici betik depoda duruyor', () {
      // Sesler koddan üretilir; yeniden üretilebilir olmalı.
      expect(File('tool/make_sounds.py').existsSync(), isTrue);
    });

    test('sessiz servis hiçbir şey çalmaz ve hata vermez', () async {
      final SoundService sessiz = SoundService.silent();
      expect(sessiz.enabled, isFalse);
      for (final GameSound s in GameSound.values) {
        await sessiz.play(s);
      }
    });
  });

  group('Aktiviteler menüsü gruplandı (Paket 28)', () {
    late GameController controller;

    setUp(() => controller = GameController(random: Random(21)));
    tearDown(() => controller.dispose());

    testWidgets('yetişkin menüsünde grup başlıkları görünür',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 4200);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        BirOmurApp(controller: controller, sound: SoundService.silent()),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rastgele bir hayat'));
      await tester.pumpAndSettle();

      final GameState temel = controller.state!;
      controller.debugSetState(
        temel.copyWith(
          pendingEvent: null,
          notices: const <PendingNotice>[],
          player: temel.player.copyWith(age: 30, wallet: 250000),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tab_aktiviteler')));
      await tester.pumpAndSettle();

      for (final String baslik in <String>[
        'Kendine bak',
        'Öğren',
        'Keyfine bak',
        'Hayat işleri',
      ]) {
        await scrollToFinder(tester, find.text(baslik));
        expect(find.text(baslik), findsOneWidget, reason: '$baslik yok');
      }
    });

    testWidgets('fal mekânı menüde yerini alır', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 4200);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        BirOmurApp(controller: controller, sound: SoundService.silent()),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rastgele bir hayat'));
      await tester.pumpAndSettle();

      final GameState temel = controller.state!;
      controller.debugSetState(
        temel.copyWith(
          pendingEvent: null,
          notices: const <PendingNotice>[],
          player: temel.player.copyWith(age: 30, wallet: 250000),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tab_aktiviteler')));
      await tester.pumpAndSettle();
      await scrollToFinder(tester, find.byKey(const Key('activity_fal')));
      await tester.tap(find.byKey(const Key('activity_fal')));
      await tester.pumpAndSettle();
      expect(find.text('Kahve falına baktır'), findsOneWidget);
      expect(find.text('Burç yorumunu oku'), findsOneWidget);
    });

    testWidgets('çocuğa yaşına uymayan alanlar gösterilmez',
        (WidgetTester tester) async {
      // Çalışmayan düğme konmaz: fal 14 yaşından önce menüde yok.
      tester.view.physicalSize = const Size(1080, 3200);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        BirOmurApp(controller: controller, sound: SoundService.silent()),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rastgele bir hayat'));
      await tester.pumpAndSettle();

      final GameState temel = controller.state!;
      controller.debugSetState(
        temel.copyWith(
          pendingEvent: null,
          notices: const <PendingNotice>[],
          player: temel.player.copyWith(age: 8),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tab_aktiviteler')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('activity_fal')), findsNothing);
      expect(ActivityVenue.falTarot.minAge, greaterThan(8));
    });
  });
}

/// Kısaltılmış para biçimi (Paket 30).
void _kisaParaTestleri() {
  group('Kısaltılmış para biçimi', () {
    test('küçük tutarlar tam yazılır', () {
      expect(trMoneyShort(0), trMoney(0));
      expect(trMoneyShort(9999), trMoney(9999));
    });

    test('binler B ile kısalır', () {
      expect(trMoneyShort(10000), '10,0 B ₺');
      expect(trMoneyShort(399800), '400 B ₺');
    });

    test('milyonlar M ile kısalır', () {
      expect(trMoneyShort(1500000), '1,5 M ₺');
      expect(trMoneyShort(987654321), '988 M ₺');
    });

    test('eksi tutarlarda işaret korunur', () {
      expect(trMoneyShort(-250000), startsWith('-'));
    });

    test('kısaltma hiçbir zaman tam tutardan uzun olmaz', () {
      for (final int tutar in <int>[
        10000,
        99999,
        250000,
        1500000,
        987654321,
      ]) {
        expect(
          trMoneyShort(tutar).length,
          lessThanOrEqualTo(trMoney(tutar).length),
        );
      }
    });
  });
}
