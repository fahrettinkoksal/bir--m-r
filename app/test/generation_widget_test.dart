import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/generation_fixtures.dart';

/// Kuşak devamının arayüzde gerçekten çalıştığını sınar.
///
/// Sahte düğme olmaz (D-038): çocuğu olmayan hayatta seçenek hiç
/// görünmez, görünen düğme ise gerçekten yeni kuşağı başlatır.
void main() {
  late GameController controller;

  setUp(() => controller = GameController(random: Random(11)));
  tearDown(() => controller.dispose());

  Future<void> pumpApp(WidgetTester tester, GameState state) async {
    // Hayat özeti değerlendirme paneliyle birlikte uzadı (Paket 22);
    // `findsNothing` beklentileri anlamını korusun diye bütün ekran
    // görünür alana sığdırılır.
    tester.view.physicalSize = const Size(1200, 7200);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(BirOmurApp(controller: controller));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rastgele bir hayat'));
    await tester.pumpAndSettle();
    controller.debugSetState(state);
    await tester.pumpAndSettle();
  }

  testWidgets('hayatta çocuk yoksa devam düğmesi gösterilmez',
      (WidgetTester tester) async {
    await pumpApp(tester, olenOyuncu(cocuklarHayatta: false));

    expect(find.byKey(const Key('life_summary_card')), findsOneWidget);
    expect(
      find.byKey(const Key('life_summary_continue_generation')),
      findsNothing,
    );
    expect(find.byKey(const Key('life_summary_new_life')), findsOneWidget);
  });

  testWidgets('tek çocuk varsa düğme çocuğun adını taşır',
      (WidgetTester tester) async {
    final GameState state = olenOyuncu();
    await pumpApp(
      tester,
      state.copyWith(
        people: state.people
            .map((Person p) =>
                p.id == 'cocuk-2' ? p.copyWith(isAlive: false) : p)
            .toList(growable: false),
      ),
    );

    expect(
      find.byKey(const Key('life_summary_continue_generation')),
      findsOneWidget,
    );
    expect(find.text('Elif olarak devam et'), findsOneWidget);
  });

  testWidgets('devam düğmesi seçilen çocukla yeni kuşağı başlatır',
      (WidgetTester tester) async {
    await pumpApp(tester, olenOyuncu());

    await tester.tap(
      find.byKey(const Key('life_summary_continue_generation')),
    );
    await tester.pumpAndSettle();

    // İki çocuk da listelenir.
    expect(find.byKey(const Key('continue_child_cocuk-1')), findsOneWidget);
    expect(find.byKey(const Key('continue_child_cocuk-2')), findsOneWidget);

    await tester.tap(find.byKey(const Key('continue_child_cocuk-2')));
    await tester.pumpAndSettle();

    final GameState yeni = controller.state!;
    expect(yeni.generation, 2);
    expect(yeni.player.firstName, 'Kerem');
    expect(yeni.deceased, isFalse);
    // Tamamlanan hayat arşive yazıldı, silinmedi.
    expect(yeni.pastLives.length, 1);
    expect(yeni.pastLives.single.fullName, 'Mehmet Yılmaz');
    expect(yeni.pastLives.single.generation, 1);
    // Hayat özeti ekranı kapandı; oyun devam ediyor.
    expect(find.byKey(const Key('life_summary_card')), findsNothing);
  });

  testWidgets('vazgeçilirse hayat özeti olduğu gibi kalır',
      (WidgetTester tester) async {
    await pumpApp(tester, olenOyuncu());

    await tester.tap(
      find.byKey(const Key('life_summary_continue_generation')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();

    expect(controller.state!.generation, 1);
    expect(controller.state!.deceased, isTrue);
    expect(find.byKey(const Key('life_summary_card')), findsOneWidget);
  });

  testWidgets('ikinci kuşakta özet ve arşiv kuşağı gösterir',
      (WidgetTester tester) async {
    await pumpApp(tester, olenOyuncu());
    await tester.tap(
      find.byKey(const Key('life_summary_continue_generation')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('continue_child_cocuk-1')));
    await tester.pumpAndSettle();

    // İkinci kuşağın hayatı da bir gün biter: özet ekranında kuşak görünür.
    controller.debugSetState(
      controller.state!.copyWith(
        deceased: true,
        deathAge: controller.state!.player.age,
        deathCause: 'yaşlılık',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('2. kuşak'), findsOneWidget);

    await tester.tap(find.byKey(const Key('life_summary_archive')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Mehmet Yılmaz'), findsWidgets);
  });
}
