import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/interaction/marriage_engine.dart';
import 'package:bir_omur/domain/interaction/parenthood.dart';
import 'package:bir_omur/domain/interaction/romance.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Eş ve çocuk kartlarının arayüzde gerçekten çalıştığını sınar.
void main() {
  late GameController controller;

  setUp(() => controller = GameController(random: Random(51)));
  tearDown(() => controller.dispose());

  GameState aileliHayat({int cocukYasi = 8}) {
    final GameState base =
        LifeGenerator.seeded(51).generate(mode: StartMode.tamamenRastgele);
    final ({GameState state, Person partner}) r = const Romance().start(
      base.copyWith(
        player: base.player.copyWith(age: 34, wallet: 900000),
      ),
      Random(2),
    );
    GameState state = r.state.copyWith(
      people: r.state.people
          .map((Person p) => p.id == r.partner.id ? p.copyWith(bond: 90) : p)
          .toList(growable: false),
    );
    state = const MarriageEngine().marry(state, r.partner.id).state;
    state = const Parenthood().haveChild(state, Random(3)).state;
    return state.copyWith(
      people: state.people
          .map((Person p) => p.relation == RelationType.cocuk
              ? p.copyWith(
                  age: cocukYasi,
                  schoolLevel: Parenthood.schoolLevelForAge(cocukYasi),
                  // Yaş ilerletme motoru gerçek oyunda bunu kendisi yapar.
                  employment: cocukYasi >= 6
                      ? EmploymentStatus.ogrenci
                      : EmploymentStatus.cocuk,
                )
              : p)
          .toList(growable: false),
    );
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

  testWidgets('çocuk kartı okul evresiyle listelenir ve etkileşim çalışır',
      (WidgetTester tester) async {
    final GameState state = aileliHayat();
    await pumpApp(tester, state);

    await tester.tap(find.byKey(const Key('relationships_children_row')));
    await tester.pumpAndSettle();

    final Person cocuk = state.children.single;
    expect(find.text(cocuk.fullName), findsOneWidget);

    await tester.tap(find.text(cocuk.fullName));
    await tester.pumpAndSettle();

    // Kademe kayıttan okunur; yaştan uydurulmaz.
    expect(find.textContaining('İlkokul öğrencisi'), findsWidgets);

    final int yakinlikOnce =
        controller.state!.personById(cocuk.id)!.bond;
    expect(find.text('Para İste'), findsNothing,
        reason: 'Çocuktan para isteme düğmesi olmamalı');

    await tester.tap(find.text('Vakit Geçir'));
    await tester.pumpAndSettle();

    final int yakinlikSonra =
        controller.state!.personById(cocuk.id)!.bond;
    expect(yakinlikSonra, greaterThanOrEqualTo(yakinlikOnce));
    // Sonuç metni ekranda gerçekten görünür.
    expect(find.textContaining(cocuk.firstName), findsWidgets);
  });

  testWidgets('yetişkin çocuk ilkokul öğrencisi olarak görünmez',
      (WidgetTester tester) async {
    final GameState state = aileliHayat(cocukYasi: 22);
    await pumpApp(tester, state);
    await tester.tap(find.byKey(const Key('relationships_children_row')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(state.children.single.fullName));
    await tester.pumpAndSettle();

    expect(find.textContaining('İlkokul'), findsNothing);
    expect(find.textContaining('Ortaokul'), findsNothing);
    expect(find.textContaining('Lise'), findsNothing);
  });
}
