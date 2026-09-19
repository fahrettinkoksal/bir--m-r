import 'dart:io';
import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_flow.dart';

/// Ekranların gerçek görüntüsünü üretir (`test/goldens/`).
///
/// Görüntü karşılaştırması yazı tipine ve platforma duyarlı olduğu için bu
/// dosya normal `flutter test` koşusunda **atlanır**. Çalıştırmak için:
///
/// ```
/// BIR_OMUR_SCREENSHOTS=1 flutter test --update-goldens test/golden_screens_test.dart
/// ```
///
/// Sistemde bir TrueType yazı tipi bulunursa görüntüler okunaklı olur;
/// bulunmazsa test ortamının yer tutucu yazı tipi kullanılır.
const String _kSwitch = 'BIR_OMUR_SCREENSHOTS';

const List<String> _fontCandidates = <String>[
  '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
  '/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf',
  '/System/Library/Fonts/Supplemental/Arial.ttf',
];

Future<void> _loadReadableFont() async {
  for (final String path in _fontCandidates) {
    final File file = File(path);
    if (!file.existsSync()) continue;
    final Uint8List bytes = await file.readAsBytes();
    // Test ortamının varsayılan yazı tipi ailesinin yerine geçer.
    final FontLoader loader = FontLoader('Roboto')
      ..addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
    await loader.load();
    return;
  }
}

void main() {
  final bool enabled = Platform.environment[_kSwitch] == '1';

  late GameController controller;

  setUpAll(() async {
    if (enabled) await _loadReadableFont();
  });

  setUp(() {
    controller = GameController(random: Random(7));
  });

  tearDown(() => controller.dispose());

  Future<void> pumpPhone(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(BirOmurApp(controller: controller));
    await tester.pumpAndSettle();
  }

  testWidgets('başlangıç ekranı', (WidgetTester tester) async {
    await pumpPhone(tester);
    await expectLater(
      find.byType(BirOmurApp),
      matchesGoldenFile('goldens/01_baslangic.png'),
    );
  }, skip: !enabled);

  testWidgets('hayat, aile ve ben ekranları', (WidgetTester tester) async {
    await pumpPhone(tester);
    await tester.tap(find.text('Rastgele bir hayat'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(BirOmurApp),
      matchesGoldenFile('goldens/02_hayat.png'),
    );

    await tester.tap(find.byIcon(Icons.groups_outlined));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(BirOmurApp),
      matchesGoldenFile('goldens/03_aile.png'),
    );

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(BirOmurApp),
      matchesGoldenFile('goldens/04_ben.png'),
    );
  }, skip: !enabled);

  testWidgets('yaş alınca çıkan tek olay', (WidgetTester tester) async {
    await pumpPhone(tester);
    await tester.tap(find.text('Rastgele bir hayat'));
    await tester.pumpAndSettle();

    // Olay çıkana kadar yaş al.
    int guard = 0;
    while (!controller.state!.hasPendingEvent && guard++ < 30) {
      await tester.tap(find.text('Yaş Al'));
      await tester.pumpAndSettle();
    }
    expect(controller.state!.hasPendingEvent, isTrue);

    await expectLater(
      find.byType(BirOmurApp),
      matchesGoldenFile('goldens/06_olay.png'),
    );
  }, skip: !enabled);

  testWidgets('kişi detayı ve etkileşim sonucu', (WidgetTester tester) async {
    await pumpPhone(tester);
    await tester.tap(find.text('Rastgele bir hayat'));
    await tester.pumpAndSettle();

    // Etkileşimlerin açıldığı bir yaşa gel; yoldaki olayları yanıtla.
    await ageTo(tester, controller, 8);

    await tester.tap(find.byIcon(Icons.groups_outlined));
    await tester.pumpAndSettle();
    final Person anne = controller.state!.people
        .firstWhere((Person p) => p.relation == RelationType.anne);
    await tester.tap(find.text(anne.fullName).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Vakit Geçir'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(BirOmurApp),
      matchesGoldenFile('goldens/05_etkilesim.png'),
    );
  }, skip: !enabled);
}
