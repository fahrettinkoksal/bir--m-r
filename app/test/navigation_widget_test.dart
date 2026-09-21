import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:bir_omur/ui/turkish_text.dart';
import 'package:bir_omur/ui/widgets/person_detail_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_flow.dart';

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
    expect(find.byKey(const Key('age_up_button')), findsOneWidget);
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

  testWidgets('dört ana menü arasında gezinilir ve Yaş Al ortada durur',
      (WidgetTester tester) async {
    await startRandomLife(tester);

    // Alt çubukta soldan sağa: Okul/Meslek, Varlıklar, [Yaş Al], İlişkiler,
    // Aktiviteler (NAV-001).
    for (final String id in <String>[
      'tab_okul_meslek',
      'tab_varliklar',
      'tab_iliskiler',
      'tab_aktiviteler',
    ]) {
      expect(find.byKey(Key(id)), findsOneWidget, reason: '$id bulunmalı');
    }
    expect(find.byKey(const Key('age_up_button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('tab_iliskiler')));
    await tester.pumpAndSettle();
    expect(find.text('İlişkiler'), findsWidgets);

    await tester.tap(find.byKey(const Key('tab_varliklar')));
    await tester.pumpAndSettle();
    expect(find.text('Cüzdan'), findsOneWidget);

    await tester.tap(find.byKey(const Key('tab_aktiviteler')));
    await tester.pumpAndSettle();
    expect(find.text('Aktiviteler'), findsWidgets);

    // Seçili menüye tekrar dokunmak hayat ekranına döndürür.
    await tester.tap(find.byKey(const Key('tab_aktiviteler')));
    await tester.pumpAndSettle();
    expect(find.text(trUpper('Hayat günlüğü')), findsOneWidget);
  });

  testWidgets('soldaki menü öğrenciyken Okul, değilken Meslek olur',
      (WidgetTester tester) async {
    await startRandomLife(tester);

    // Doğumda okula başlanmamıştır: Meslek görünür.
    expect(controller.state!.education.isStudent, isFalse);
    expect(find.text('Meslek'), findsOneWidget);
    expect(find.text('Okul'), findsNothing);

    await ageTo(tester, controller, 7);
    expect(controller.state!.education.isStudent, isTrue);
    expect(find.text('Okul'), findsOneWidget);
    expect(find.text('Meslek'), findsNothing);
  });

  testWidgets('üst özet beş değeri gösterir, ayrıntıda Ün yoktur',
      (WidgetTester tester) async {
    await startRandomLife(tester);

    // Üst şeritte kısa etiketler.
    for (final String label in <String>[
      'Görünüş',
      'Mutluluk',
      'Sağlık',
      'Zekâ',
      'Karizma',
    ]) {
      expect(find.text(label), findsOneWidget, reason: '$label görünmeli');
    }

    // Şeride dokununca tam adlarıyla ayrıntı açılır.
    await tester.tap(find.text('Mutluluk'));
    await tester.pumpAndSettle();
    expect(find.text('Karakter değerleri'), findsOneWidget);
    expect(find.text('Dış görünüş'), findsOneWidget);
    // Ün açılmadığı sürece hiç gösterilmez (D-027).
    expect(find.text('Ün'), findsNothing);
  });

  testWidgets('Yaş Al ekrandaki yaşı ilerletir', (WidgetTester tester) async {
    await startRandomLife(tester);
    expect(find.textContaining('0 yaşında'), findsOneWidget);

    await tester.tap(find.byKey(const Key('age_up_button')));
    await tester.pumpAndSettle();
    await answerPendingEvents(tester, controller);

    expect(find.textContaining('1 yaşında'), findsOneWidget);
    expect(find.text('1 yaşına girdin.'), findsOneWidget);
  });

  testWidgets('Aile ekranında kişiye dokununca gerçek ayrıntı açılır',
      (WidgetTester tester) async {
    await startRandomLife(tester);
    await tester.tap(find.byKey(const Key('tab_iliskiler')));
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

    await tester.tap(find.byKey(const Key('new_life_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Yeni hayat'));
    await tester.pumpAndSettle();

    expect(find.text('Rastgele bir hayat'), findsOneWidget);
  });
}
