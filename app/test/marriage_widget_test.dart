import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/interaction/romance.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Evlilik ve çocuk akışının arayüzde gerçekten çalıştığını sınar:
/// İlişkiler → sevgili → Evlen → eş kartı → Çocuk sahibi olun → Çocuklar.
void main() {
  late GameController controller;

  setUp(() => controller = GameController(random: Random(31)));
  tearDown(() => controller.dispose());

  /// Sevgilisi olan, evlenmeye uygun bir hayat.
  ({GameState state, Person partner}) sevgili({
    int age = 28,
    int wallet = 500000,
    int bond = 85,
  }) {
    final GameState base =
        LifeGenerator.seeded(31).generate(mode: StartMode.tamamenRastgele);
    final ({GameState state, Person partner}) r = const Romance().start(
      base.copyWith(
        player: base.player.copyWith(age: age, wallet: wallet),
      ),
      Random(4),
    );
    final GameState state = r.state.copyWith(
      people: r.state.people
          .map((Person p) => p.id == r.partner.id ? p.copyWith(bond: bond) : p)
          .toList(growable: false),
    );
    return (state: state, partner: state.personById(r.partner.id)!);
  }

  Future<void> pumpApp(WidgetTester tester, GameState state) async {
    tester.view.physicalSize = const Size(1200, 3600);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(BirOmurApp(controller: controller));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rastgele bir hayat'));
    await tester.pumpAndSettle();
    controller.debugSetState(state);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tab_iliskiler')));
    await tester.pumpAndSettle();
  }

  /// Açık kişi kartını kapatır (kip dışına dokunarak).
  Future<void> sheetKapat(WidgetTester tester) async {
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
  }

  /// Alt sayfadan İlişkiler ana listesine döner.
  Future<void> iliskilereDon(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.chevron_left).first);
    await tester.pumpAndSettle();
  }

  Future<void> kisiyiAc(WidgetTester tester, String adSoyad) async {
    await tester.tap(find.text('Romantik bağlar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(adSoyad));
    await tester.pumpAndSettle();
  }

  testWidgets('evlenme düğmesi koşul sağlanmadan gösterilmez',
      (WidgetTester tester) async {
    final ({GameState state, Person partner}) veri = sevgili(wallet: 1000);
    await pumpApp(tester, veri.state);
    await kisiyiAc(tester, veri.partner.fullName);

    expect(find.byKey(const Key('person_marry_button')), findsNothing);
    expect(find.textContaining('Evlenmek için:'), findsOneWidget);
    expect(controller.state!.isMarried, isFalse);
  });

  testWidgets('sevgiliyle evlenilir ve aynı kişi eş olarak görünür',
      (WidgetTester tester) async {
    final ({GameState state, Person partner}) veri = sevgili();
    await pumpApp(tester, veri.state);
    await kisiyiAc(tester, veri.partner.fullName);

    await tester.tap(find.byKey(const Key('person_marry_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Evlen'));
    await tester.pumpAndSettle();

    expect(controller.state!.isMarried, isTrue);
    expect(controller.state!.spouse!.id, veri.partner.id);

    // Kişi listesinde eş en üstte, aynı ad ve aynı kimlikle görünür.
    await sheetKapat(tester);
    await iliskilereDon(tester);
    expect(find.text(veri.partner.fullName), findsOneWidget);
    expect(find.textContaining('Eş ·'), findsOneWidget);
  });

  testWidgets('evlendikten sonra çocuk sahibi olunur ve listede görünür',
      (WidgetTester tester) async {
    final ({GameState state, Person partner}) veri = sevgili();
    await pumpApp(tester, veri.state);
    await kisiyiAc(tester, veri.partner.fullName);
    await tester.tap(find.byKey(const Key('person_marry_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Evlen'));
    await tester.pumpAndSettle();

    // Eş kartından çocuk sahibi olunur.
    await tester.tap(find.byKey(const Key('person_child_button')));
    await tester.pumpAndSettle();
    expect(controller.state!.children.length, 1);

    final Person cocuk = controller.state!.children.single;
    await sheetKapat(tester);
    await iliskilereDon(tester);
    await tester.tap(find.byKey(const Key('relationships_children_row')));
    await tester.pumpAndSettle();
    expect(find.text(cocuk.fullName), findsOneWidget);
  });

  testWidgets('boşanınca kişi eski eş olarak kayıtta kalır',
      (WidgetTester tester) async {
    final ({GameState state, Person partner}) veri = sevgili();
    await pumpApp(tester, veri.state);
    await kisiyiAc(tester, veri.partner.fullName);
    await tester.tap(find.byKey(const Key('person_marry_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Evlen'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('person_divorce_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Boşan'));
    await tester.pumpAndSettle();

    expect(controller.state!.isMarried, isFalse);
    expect(
      controller.state!.personById(veri.partner.id)!.relation,
      RelationType.eskiEs,
    );

    await sheetKapat(tester);
    await iliskilereDon(tester);
    await tester.tap(find.text('Romantik bağlar'));
    await tester.pumpAndSettle();
    expect(find.text(veri.partner.fullName), findsOneWidget);
    expect(find.textContaining('Eski eş ·'), findsOneWidget);
  });
}
