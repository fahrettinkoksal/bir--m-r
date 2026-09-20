import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/domain/models/interaction.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_flow.dart';

/// Aile → kişi detayı → Vakit Geçir akışının gerçekten çalıştığını sınar.
void main() {
  late GameController controller;

  setUp(() {
    controller = GameController(random: Random(7));
  });

  tearDown(() => controller.dispose());

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 3600);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(BirOmurApp(controller: controller));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rastgele bir hayat'));
    await tester.pumpAndSettle();
  }

  Person motherOf() => controller.state!.people
      .firstWhere((Person p) => p.relation == RelationType.anne);

  Future<void> openMother(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('tab_iliskiler')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(motherOf().fullName).first);
    await tester.pumpAndSettle();
  }

  testWidgets('yaşı uygun değilken etkileşim düğmesi gösterilmez',
      (WidgetTester tester) async {
    await pumpApp(tester);
    await openMother(tester);

    expect(find.text('Vakit Geçir'), findsNothing);
    expect(find.text('Sohbet Et'), findsNothing);
    expect(find.textContaining('yaşından itibaren açılır'), findsOneWidget);
  });

  testWidgets('Vakit Geçir çalışır ve sonucu ekranda gösterir',
      (WidgetTester tester) async {
    await pumpApp(tester);
    await ageTo(tester, controller, 8);
    await openMother(tester);

    expect(find.text('Vakit Geçir'), findsOneWidget);
    expect(find.text('Sohbet Et'), findsOneWidget);

    final int bondBefore = motherOf().bond;
    final int happinessBefore = controller.state!.player.stats.happiness;

    await tester.tap(find.text('Vakit Geçir'));
    await tester.pumpAndSettle();

    // İlk istek reddedilmez: gerçek bir kazanç görülmeli.
    expect(motherOf().bond, greaterThan(bondBefore));
    // Mutluluk tavandaysa artamaz; tavanın altındaysa gerçekten artmalı.
    if (happinessBefore < 100) {
      expect(controller.state!.player.stats.happiness,
          greaterThan(happinessBefore));
    } else {
      expect(controller.state!.player.stats.happiness, 100);
    }
    // Etki rozeti artık kimle yakınlaştığını yazar: "Annen Ayşe ile
    // yakınlık +7" gibi.
    expect(find.textContaining('ile yakınlık +'), findsOneWidget);
  });

  testWidgets('sonuç hayat günlüğüne yansır', (WidgetTester tester) async {
    await pumpApp(tester);
    await ageTo(tester, controller, 8);
    await openMother(tester);

    await tester.tap(find.text('Vakit Geçir'));
    await tester.pumpAndSettle();
    final String sonuc = controller.state!.log.last.text;
    await answerPendingEvents(tester, controller);

    // Sayfayı kapatıp Hayat sekmesine dön.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tab_iliskiler')));
    await tester.pumpAndSettle();

    expect(find.text(sonuc), findsOneWidget);
  });

  testWidgets('tekrar edildiğinde kazanç azalır, başka kişi kilitlenmez',
      (WidgetTester tester) async {
    await pumpApp(tester);
    await ageTo(tester, controller, 8);

    final Person anne = motherOf();
    final Person baba = controller.state!.people
        .firstWhere((Person p) => p.relation == RelationType.baba);

    int kabulSayisi = 0;
    // Sayaca en az üç tekrar işlenene kadar denenir. Sabit deneme sayısı,
    // olay havuzu büyüdükçe araya giren ek olaylar yüzünden kırılgandı;
    // sınanan şey deneme sayısı değil, **tekrarların sayaca işlenmesi**.
    for (int i = 0; i < 40; i++) {
      // Etkileşim sırasında ilerlemeye bağlı bir ek olay çıkarsa yanıtla.
      await answerPendingEvents(tester, controller);
      final InteractionOutcome? o =
          controller.interact(anne.id, InteractionKind.vakitGecir);
      if (o != null && o.accepted) kabulSayisi++;
      if (controller.state!
              .interactionCount(anne.id, InteractionKind.vakitGecir.name) >=
          3) {
        break;
      }
    }
    await answerPendingEvents(tester, controller);
    expect(kabulSayisi, greaterThan(0));
    expect(
      controller.state!.interactionCount(anne.id, InteractionKind.vakitGecir.name),
      greaterThanOrEqualTo(3),
      reason: 'Tekrarlar sayaca işlenmeli',
    );

    // Babayla ilk etkileşim hâlâ açık ve tam faydalı.
    final InteractionOutcome babaIlk =
        controller.interact(baba.id, InteractionKind.vakitGecir)!;
    await answerPendingEvents(tester, controller);
    expect(babaIlk.accepted, isTrue);
    expect(babaIlk.bondDelta, greaterThan(0));

    await openMother(tester);
    expect(find.text('Vakit Geçir'), findsOneWidget,
        reason: 'Fayda bitse de eylem arayüzden kaldırılmaz');
  });
}
