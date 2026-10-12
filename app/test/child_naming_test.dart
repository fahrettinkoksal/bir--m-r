import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/domain/interaction/child_naming.dart';
import 'package:bir_omur/domain/life/notices.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Doğumda çocuğa isim verme (D-095).
void main() {
  Person bebek({String id = 'bebek-1', int age = 0}) => Person(
        id: id,
        firstName: 'Deniz',
        lastName: 'Yılmaz',
        gender: Gender.kadin,
        age: age,
        relation: RelationType.cocuk,
        isAlive: true,
        inPlayerHousehold: true,
        employment: EmploymentStatus.cocuk,
        wealth: null,
        bond: 60,
      );

  GameController oyuncuVeBebek({int age = 0}) {
    final GameController controller = GameController(random: Random(4));
    controller.startNewLife(mode: StartMode.tamamenRastgele, seed: 4);
    final GameState state = controller.state!;
    controller.debugSetState(
      state.copyWith(
        people: List<Person>.unmodifiable(<Person>[
          ...state.people,
          bebek(age: age),
        ]),
        pendingEvent: null,
      ),
    );
    return controller;
  }

  group('isim doğrulaması', () {
    test('baştaki/sondaki boşluk atılır, ilk harf büyür', () {
      expect(ChildNaming.normalize('  ali  '), 'Ali');
      expect(ChildNaming.normalize('ırmak'), 'Irmak');
      expect(ChildNaming.normalize('işıl'), 'İşıl');
      expect(ChildNaming.normalize('ayşe  nur'), 'Ayşe Nur');
    });

    test('çok kısa, çok uzun ve rakamlı isimler kabul edilmez', () {
      expect(ChildNaming.normalize('a'), isNull);
      expect(ChildNaming.normalize(''), isNull);
      expect(ChildNaming.normalize('a' * (ChildNaming.maxLength + 1)), isNull);
      expect(ChildNaming.normalize('Ali123'), isNull);
      expect(ChildNaming.normalize('<script>'), isNull);
    });
  });

  test('yeni doğan bebeğin adı değiştirilebilir ve günlüğe işlenir', () {
    final GameController controller = oyuncuVeBebek();
    expect(controller.canNameChild('bebek-1'), isTrue);
    final int oncekiSatir = controller.state!.log.length;

    final ({bool applied, String message}) sonuc =
        controller.nameChild('bebek-1', 'çınar');
    expect(sonuc.applied, isTrue);
    expect(
      controller.state!.personById('bebek-1')!.firstName,
      'Çınar',
    );
    expect(controller.state!.log.length, oncekiSatir + 1);
    expect(controller.state!.log.last.text, contains('Çınar'));
  });

  test('soyadı değişmez', () {
    final GameController controller = oyuncuVeBebek();
    controller.nameChild('bebek-1', 'Umut');
    expect(controller.state!.personById('bebek-1')!.lastName, 'Yılmaz');
  });

  test('bebek büyüdükten sonra isim değiştirilemez', () {
    final GameController controller = oyuncuVeBebek(age: 3);
    expect(controller.canNameChild('bebek-1'), isFalse);

    final ({bool applied, String message}) sonuc =
        controller.nameChild('bebek-1', 'Umut');
    expect(sonuc.applied, isFalse);
    expect(controller.state!.personById('bebek-1')!.firstName, 'Deniz');
  });

  test('geçersiz isim uygulanmaz, sebebi döner', () {
    final GameController controller = oyuncuVeBebek();
    final ({bool applied, String message}) sonuc =
        controller.nameChild('bebek-1', '7');
    expect(sonuc.applied, isFalse);
    expect(sonuc.message, isNotEmpty);
    expect(controller.state!.personById('bebek-1')!.firstName, 'Deniz');
  });

  testWidgets('doğum bildiriminde isim alanı çıkar ve isim uygulanır',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 4800);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final GameController controller = GameController(random: Random(6));
    addTearDown(controller.dispose);
    await tester.pumpWidget(BirOmurApp(controller: controller));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rastgele bir hayat'));
    await tester.pumpAndSettle();

    final GameState state = controller.state!;
    controller.debugSetState(
      state.copyWith(
        people: List<Person>.unmodifiable(<Person>[...state.people, bebek()]),
        pendingEvent: null,
        notices: List<PendingNotice>.unmodifiable(<PendingNotice>[
          Notices.birth(
            playerAge: state.player.age,
            childId: 'bebek-1',
            childName: 'Deniz',
            isGirl: true,
          ),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    // Bildirim önerilen adı taşır ve isim alanı hazır gelir.
    expect(find.byKey(const Key('birth_name_field')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('birth_name_field')), 'Nehir');
    await tester.tap(find.byKey(const Key('birth_name_save')));
    await tester.pumpAndSettle();

    expect(controller.state!.personById('bebek-1')!.firstName, 'Nehir');
    expect(find.byKey(const Key('birth_name_note')), findsOneWidget);

    await tester.tap(find.byKey(const Key('notice_close')));
    await tester.pumpAndSettle();
    expect(controller.state!.hasNotice, isFalse);
  });
}
