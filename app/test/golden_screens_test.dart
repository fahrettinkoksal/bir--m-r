import 'dart:io';
import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/models/gift_record.dart';
import 'package:bir_omur/domain/models/life_log.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:bir_omur/ui/sound/sound_service.dart';
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
const String _kSwitch = 'BIR_OMUR_SCREENSHOTS';

/// Ekran görüntüleri gerçek uygulamaya benzesin diye Flutter'ın kendi
/// Roboto ve Material Icons dosyaları yüklenir. Aksi halde yazılar tek tip
/// kalınlıkta, ikonlar ise boş kare olarak çıkıyordu ve tasarım
/// değerlendirilemiyordu.
const String _flutterFonts =
    '/opt/flutter/bin/cache/artifacts/material_fonts';

const List<String> _fallbackFonts = <String>[
  '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
  '/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf',
  '/System/Library/Fonts/Supplemental/Arial.ttf',
];

Future<bool> _loadFamily(String family, Map<String, String> files) async {
  final FontLoader loader = FontLoader(family);
  bool any = false;
  for (final MapEntry<String, String> entry in files.entries) {
    final File file = File(entry.value);
    if (!file.existsSync()) continue;
    any = true;
    final Uint8List bytes = await file.readAsBytes();
    loader.addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
  }
  if (!any) return false;
  await loader.load();
  return true;
}

Future<void> _loadReadableFont() async {
  // Material ikon yazı tipi: menü ve düğme ikonları görünsün diye.
  await _loadFamily('MaterialIcons', <String, String>{
    'regular': '$_flutterFonts/MaterialIcons-Regular.otf',
  });

  // Roboto'nun tüm kalınlıkları: w400 ile w800 arasındaki fark ekranda
  // gerçekten görünsün.
  final bool roboto = await _loadFamily('Roboto', <String, String>{
    'light': '$_flutterFonts/Roboto-Light.ttf',
    'regular': '$_flutterFonts/Roboto-Regular.ttf',
    'medium': '$_flutterFonts/Roboto-Medium.ttf',
    'bold': '$_flutterFonts/Roboto-Bold.ttf',
    'black': '$_flutterFonts/Roboto-Black.ttf',
  });
  if (roboto) return;

  for (final String path in _fallbackFonts) {
    if (await _loadFamily('Roboto', <String, String>{'regular': path})) return;
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

  Future<void> pumpPhone(
    WidgetTester tester, {
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      BirOmurApp(
        controller: controller,
        themeMode: themeMode,
        // Ekran görüntüsü alırken ses eklentisi yok; sessiz servis
        // verilmezse oynatıcı kurulmaya çalışılıyor.
        sound: SoundService.silent(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> startLife(
    WidgetTester tester, {
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    await pumpPhone(tester, themeMode: themeMode);
    await tester.tap(find.text('Rastgele bir hayat'));
    await tester.pumpAndSettle();
  }

  Future<void> shot(WidgetTester tester, String name) =>
      expectLater(find.byType(BirOmurApp), matchesGoldenFile('goldens/$name'));

  Future<void> openTab(WidgetTester tester, String id) async {
    await tester.tap(find.byKey(Key('tab_$id')));
    await tester.pumpAndSettle();
  }

  /// Belirli bir bağdan hayattaki ilk kişi.
  Person? personWith(RelationType relation) {
    for (final Person p in controller.state!.people) {
      if (p.isAlive && p.relation == relation) return p;
    }
    return null;
  }

  /// Hedefe ulaşana kadar tercih edilen seçeneklerle ilerler.
  Future<void> advanceUntil(
    WidgetTester tester,
    bool Function() done, {
    required List<String> prefer,
    int maxAges = 45,
  }) async {
    int guard = 0;
    while (!done() && guard++ < maxAges) {
      // Sağlık krizi olay penceresinden önce gelir (D-044); kriz açıkken
      // olay düğmeleri ekranda olmaz. Bildirimler de olaydan önce gelir
      // (D-050).
      await answerPendingCrisis(tester, controller);
      await answerPendingNotices(tester, controller);
      while (controller.state!.hasPendingEvent) {
        if (controller.state!.deceased) return;
        await answerPendingCrisis(tester, controller);
        await answerPendingNotices(tester, controller);
        await tester.pumpAndSettle();
        final ActiveEvent event = controller.state!.pendingEvent!;
        final EventChoice choice = event.choices.firstWhere(
          (EventChoice c) => prefer.contains(c.id),
          orElse: () => event.choices.first,
        );
        await tester.tap(find.text(choice.label));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Devam'));
        await tester.pumpAndSettle();
        if (done()) return;
      }
      if (done()) return;
      if (controller.state!.deceased) return;
      await tester.tap(find.byKey(const Key('age_up_button')));
      await tester.pumpAndSettle();
    }
  }

  testWidgets('başlangıç ekranı', (WidgetTester tester) async {
    await pumpPhone(tester);
    await shot(tester, '01_baslangic.png');
  }, skip: !enabled);

  testWidgets('ana ekran: üst özet, günlük, alt menü ve Yaş Al',
      (WidgetTester tester) async {
    await startLife(tester);
    await ageTo(tester, controller, 9);
    await shot(tester, '02_hayat.png');
  }, skip: !enabled);

  testWidgets('İlişkiler: anne-baba üstte, alt menüler', (WidgetTester tester) async {
    await startLife(tester);
    await ageTo(tester, controller, 9);
    await openTab(tester, 'iliskiler');
    await shot(tester, '03_iliskiler.png');
  }, skip: !enabled);

  testWidgets('Varlıklar: cüzdan ve sahip olunanlar', (WidgetTester tester) async {
    await startLife(tester);
    await ageTo(tester, controller, 9);
    await openTab(tester, 'varliklar');
    await shot(tester, '04_varliklar.png');
  }, skip: !enabled);

  testWidgets('Okul: kademe paneli ve okul arkadaşları',
      (WidgetTester tester) async {
    await startLife(tester);
    await advanceUntil(
      tester,
      () => personWith(RelationType.arkadas) != null,
      prefer: <String>['tanis'],
    );
    await openTab(tester, 'okul_meslek');
    await shot(tester, '05_okul.png');
  }, skip: !enabled);

  testWidgets('Aktiviteler: iç içe menü', (WidgetTester tester) async {
    await startLife(tester);
    await ageTo(tester, controller, 9);
    await openTab(tester, 'aktiviteler');
    await shot(tester, '06_aktiviteler.png');
  }, skip: !enabled);

  testWidgets('Yaş alınca çıkan tek olay', (WidgetTester tester) async {
    await startLife(tester);
    int guard = 0;
    while (!controller.state!.hasPendingEvent && guard++ < 30) {
      await tester.tap(find.byKey(const Key('age_up_button')));
      await tester.pumpAndSettle();
    }
    expect(controller.state!.hasPendingEvent, isTrue);
    await shot(tester, '07_olay.png');
  }, skip: !enabled);

  testWidgets('kişi detayında ortak geçmiş', (WidgetTester tester) async {
    await startLife(tester);
    await ageTo(tester, controller, 14);
    // Ortak geçmiş gerçek kayıtlardan doğar; bu ekran için hediye ve
    // günlük satırı eklenir.
    final Person anne = personWith(RelationType.anne)!;
    controller.debugSetState(
      controller.state!.copyWith(
        gifts: <GiftRecord>[
          GiftRecord(
            itemId: 'yoyo',
            fromId: anne.id,
            toId: GiftRecord.playerId,
            age: 6,
          ),
        ],
        log: <LifeLogEntry>[
          ...controller.state!.log,
          LifeLogEntry(
            age: 9,
            text: '${anne.firstName} ile pazara gittiniz; '
                'dönüşte poşetleri sen taşıdın.',
            category: LogCategory.aile,
            personId: anne.id,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await openTab(tester, 'iliskiler');
    await tapMenuRow(tester, anne.fullName);
    await shot(tester, '11_ortak_gecmis.png');
  }, skip: !enabled);

  testWidgets('kişi detayı ve etkileşim sonucu', (WidgetTester tester) async {
    await startLife(tester);
    await ageTo(tester, controller, 9);
    await openTab(tester, 'iliskiler');

    final Person anne = personWith(RelationType.anne)!;
    await tapMenuRow(tester, anne.fullName);
    await tester.tap(find.text('Vakit Geçir'));
    await tester.pumpAndSettle();
    await shot(tester, '08_etkilesim.png');
  }, skip: !enabled);

  testWidgets('karanlık mod: ana ekran okunaklı kalır',
      (WidgetTester tester) async {
    await startLife(tester, themeMode: ThemeMode.dark);
    await ageTo(tester, controller, 9);
    await shot(tester, '10_karanlik_mod.png');
  }, skip: !enabled);

  testWidgets('ayrılıktan sonra aynı kişi eski sevgili olarak kalır',
      (WidgetTester tester) async {
    // Bu ekran romantik zincirin tamamlandığı bir hayat ister. 7 numaralı
    // tohumda hayat kriz yüzünden erken bitiyor; bu tek test için sabit
    // başka bir tohum kullanılır.
    controller.dispose();
    controller = GameController(random: Random(11));
    await startLife(tester);
    await advanceUntil(
      tester,
      () => personWith(RelationType.sevgili) != null,
      prefer: <String>['selam', 'teklif'],
      maxAges: 60,
    );
    final Person? partner = personWith(RelationType.sevgili);
    expect(partner, isNotNull);

    await openTab(tester, 'iliskiler');
    // İlişkiler menüsü büyüdü; satırlar kaydırılarak açılır.
    await tapMenuRow(tester, 'Romantik bağlar');
    await tapMenuRow(tester, partner!.fullName);
    // Kişi kartı ortak geçmişle birlikte uzadı; eylem satırı
    // kaydırılarak açılır.
    await tapMenuRow(tester, 'Ayrıl');
    await tester.tap(find.widgetWithText(FilledButton, 'Ayrıl').last);
    await tester.pumpAndSettle();

    await shot(tester, '09_eski_sevgili.png');
  }, skip: !enabled);
}
