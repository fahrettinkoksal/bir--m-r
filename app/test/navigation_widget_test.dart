import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:bir_omur/ui/turkish_text.dart';
import 'package:bir_omur/ui/widgets/person_detail_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Üç sekme arasında gerçekten gezinilebildiğini ve ekranların gerçek
/// durumu gösterdiğini sınar.
void main() {
  late GameController controller;

  setUp(() {
    controller = GameController(random: Random(7));
  });

  tearDown(() => controller.dispose());

  /// Dikey telefon ölçüsüne yakın, uzun bir test yüzeyi: liste içeriğinin
  /// tamamı çizilsin diye.
  void useTallPhoneSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 3600);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> pumpApp(WidgetTester tester) async {
    useTallPhoneSurface(tester);
    await tester.pumpWidget(BirOmurApp(controller: controller));
    await tester.pumpAndSettle();
  }

  Future<void> startRandomLife(WidgetTester tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Rastgele bir hayat'));
    await tester.pumpAndSettle();
  }

  testWidgets('açılışta iki başlangıç modu sunulur', (WidgetTester tester) async {
    await pumpApp(tester);
    expect(find.text('Bir Ömür'), findsOneWidget);
    expect(find.text('Rastgele bir hayat'), findsOneWidget);
    expect(find.text('İsmimi ve cinsiyetimi seçeyim'), findsOneWidget);
  });

  testWidgets('rastgele mod hayatı başlatır ve Hayat ekranı açılır',
      (WidgetTester tester) async {
    await startRandomLife(tester);
    expect(find.text('Yaş Al'), findsOneWidget);
    expect(find.textContaining('0 yaşında'), findsOneWidget);
    expect(find.text(trUpper('Hayat günlüğü')), findsOneWidget);
  });

  testWidgets('isim/cinsiyet modunda seçilen isim oyuna geçer',
      (WidgetTester tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('İsmimi ve cinsiyetimi seçeyim'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Nergis');
    await tester.tap(find.text('Kadın'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hayata başla'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Nergis'), findsWidgets);
    expect(controller.state!.player.firstName, 'Nergis');
  });

  testWidgets('üç sekme arasında gezinilir', (WidgetTester tester) async {
    await startRandomLife(tester);

    await tester.tap(find.byIcon(Icons.groups_outlined));
    await tester.pumpAndSettle();
    expect(find.text(trUpper('Çekirdek aile')), findsOneWidget);

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    expect(find.text(trUpper('Karakter değerleri')), findsOneWidget);

    await tester.tap(find.byIcon(Icons.auto_stories_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Yaş Al'), findsOneWidget);
  });

  testWidgets('Ben ekranı beş değeri gösterir, Ün gösterilmez',
      (WidgetTester tester) async {
    await startRandomLife(tester);
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();

    for (final String label in <String>[
      'Dış görünüş',
      'Mutluluk',
      'Sağlık',
      'Zekâ',
      'Karizma',
    ]) {
      expect(find.text(label), findsOneWidget, reason: '$label görünmeli');
    }
    // Ün açılmadığı sürece hiç gösterilmez (D-027).
    expect(find.text('Ün'), findsNothing);
  });

  testWidgets('Yaş Al ekrandaki yaşı ilerletir', (WidgetTester tester) async {
    await startRandomLife(tester);
    expect(find.textContaining('0 yaşında'), findsOneWidget);

    await tester.tap(find.text('Yaş Al'));
    await tester.pumpAndSettle();

    expect(find.textContaining('1 yaşında'), findsOneWidget);
    expect(find.text('1 yaşına girdin.'), findsOneWidget);
  });

  testWidgets('Aile ekranında kişiye dokununca gerçek ayrıntı açılır',
      (WidgetTester tester) async {
    await startRandomLife(tester);
    await tester.tap(find.byIcon(Icons.groups_outlined));
    await tester.pumpAndSettle();

    final Person anne = controller.state!.people
        .firstWhere((Person p) => p.relation.name == 'anne');

    await tester.tap(find.text(anne.fullName).first);
    await tester.pumpAndSettle();

    expect(find.byType(PersonDetailSheet), findsOneWidget);
    expect(find.text('Anne'), findsWidgets);
    expect(find.text('Hane'), findsOneWidget);
  });

  testWidgets('yeni hayat düğmesi başlangıç ekranına döner',
      (WidgetTester tester) async {
    await startRandomLife(tester);

    await tester.tap(find.byIcon(Icons.restart_alt));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Yeni hayat'));
    await tester.pumpAndSettle();

    expect(find.text('Rastgele bir hayat'), findsOneWidget);
  });
}
