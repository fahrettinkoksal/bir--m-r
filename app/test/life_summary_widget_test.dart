import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Oyuncu vefat ettiğinde hayat özetinin gerçekten göründüğünü sınar.
void main() {
  late GameController controller;

  setUp(() => controller = GameController(random: Random(41)));
  tearDown(() => controller.dispose());

  GameState tamamlanmisHayat() {
    final GameState base =
        LifeGenerator.seeded(41).generate(mode: StartMode.tamamenRastgele);
    return base.copyWith(
      player: base.player.copyWith(age: 81, wallet: 125000),
      deceased: true,
      deathAge: 81,
      deathCause: 'yaşlılığa bağlı nedenler',
    );
  }

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

  testWidgets('ölümden sonra hayat özeti gösterilir',
      (WidgetTester tester) async {
    final GameState state = tamamlanmisHayat();
    await pumpApp(tester, state);

    expect(find.text('Bir ömür tamamlandı'), findsOneWidget);
    expect(find.byKey(const Key('life_summary_card')), findsOneWidget);
    expect(find.textContaining('81'), findsWidgets);
    expect(find.textContaining('yaşlılığa bağlı nedenler'), findsOneWidget);
    expect(find.text(state.player.fullName), findsWidgets);
    expect(find.text('Ailesi'), findsOneWidget);

    // Yaş Al ve ana menüler kapanır.
    expect(find.byKey(const Key('age_up_button')), findsNothing);
    expect(find.byKey(const Key('tab_varliklar')), findsNothing);
  });

  testWidgets('ölümden sonra yaş ilerlemez', (WidgetTester tester) async {
    await pumpApp(tester, tamamlanmisHayat());
    controller.ageUp();
    await tester.pumpAndSettle();
    expect(controller.state!.player.age, 81);
    expect(find.text('Bir ömür tamamlandı'), findsOneWidget);
  });

  testWidgets('yeni hayat ancak onayla başlar', (WidgetTester tester) async {
    await pumpApp(tester, tamamlanmisHayat());

    await tester.tap(find.byKey(const Key('life_summary_new_life')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Devam edilsin mi?'), findsOneWidget);

    // Vazgeçilince hayat özeti durur, kayıt silinmez.
    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();
    expect(find.text('Bir ömür tamamlandı'), findsOneWidget);
    expect(controller.state, isNotNull);
    expect(controller.state!.deceased, isTrue);

    // Onaylanınca yeni hayat ekranına dönülür.
    await tester.tap(find.byKey(const Key('life_summary_new_life')));
    await tester.pumpAndSettle();
    // Başlık ile düğme aynı metni taşıyor; düğmeye basılır.
    await tester.tap(find.widgetWithText(FilledButton, 'Yeni hayat').last);
    await tester.pumpAndSettle();
    expect(find.text('Rastgele bir hayat'), findsOneWidget);
  });
}
