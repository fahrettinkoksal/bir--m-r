import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:bir_omur/ui/sound/sound_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_flow.dart';

/// Finger ekranı (Paket 34).
void main() {
  late GameController controller;

  setUp(() => controller = GameController(random: Random(19)));
  tearDown(() => controller.dispose());

  GameState hayat({int age = 25}) {
    final GameState base =
        LifeGenerator.seeded(97).generate(mode: StartMode.tamamenRastgele);
    return base.copyWith(
      pendingEvent: null,
      notices: const <PendingNotice>[],
      people: base.people
          .where((Person p) => p.relation != RelationType.sevgili)
          .toList(growable: false),
      player: base.player.copyWith(age: age),
    );
  }

  Future<void> fingeriAc(WidgetTester tester, GameState state) async {
    tester.view.physicalSize = const Size(1080, 5600);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      BirOmurApp(controller: controller, sound: SoundService.silent()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rastgele bir hayat'));
    await tester.pumpAndSettle();
    controller.debugSetState(state);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tab_aktiviteler')));
    await tester.pumpAndSettle();
    await scrollToFinder(tester, find.byKey(const Key('activity_finger')));
    await tester.tap(find.byKey(const Key('activity_finger')));
    await tester.pumpAndSettle();
  }

  testWidgets('uygulama açılır ve bir profil gösterir',
      (WidgetTester tester) async {
    await fingeriAc(tester, hayat());

    expect(find.byKey(const Key('finger_profil')), findsOneWidget);
    expect(find.byKey(const Key('finger_begen')), findsOneWidget);
    expect(find.byKey(const Key('finger_gec')), findsOneWidget);
    expect(controller.fingerDeck, isNotEmpty);
  });

  testWidgets('geçince sıradaki profil gelir', (WidgetTester tester) async {
    await fingeriAc(tester, hayat());
    final String ilk = controller.fingerDeck.first.id;

    await scrollToFinder(tester, find.byKey(const Key('finger_gec')));
    await tester.tap(find.byKey(const Key('finger_gec')));
    await tester.pumpAndSettle();

    expect(controller.fingerDeck.first.id, isNot(ilk));
    expect(controller.fingerSwipesThisAge, 1);
    expect(find.byKey(const Key('finger_profil')), findsOneWidget);
  });

  testWidgets('beğenip eşleşince eşleşme listesi görünür',
      (WidgetTester tester) async {
    await fingeriAc(tester, hayat());

    // Eşleşme ihtimalli: eşleşene kadar beğen.
    for (int i = 0; i < 20 && controller.fingerMatches.isEmpty; i++) {
      await scrollToFinder(tester, find.byKey(const Key('finger_begen')));
      await tester.tap(find.byKey(const Key('finger_begen')));
      await tester.pumpAndSettle();
    }

    expect(controller.fingerMatches, isNotEmpty,
        reason: '20 beğenide hiç eşleşme olmadı');
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.text('Eşleşmelerin'), findsOneWidget);
  });

  testWidgets('tanışınca kişi gerçekten hayata girer',
      (WidgetTester tester) async {
    await fingeriAc(tester, hayat());
    for (int i = 0; i < 20 && controller.fingerMatches.isEmpty; i++) {
      await scrollToFinder(tester, find.byKey(const Key('finger_begen')));
      await tester.tap(find.byKey(const Key('finger_begen')));
      await tester.pumpAndSettle();
    }
    expect(controller.fingerMatches, isNotEmpty);

    final int once = controller.state!.people.length;
    final Key tanis =
        Key('finger_tanis_${controller.fingerMatches.first.id}');
    await scrollToFinder(tester, find.byKey(tanis));
    await tester.tap(find.byKey(tanis));
    await tester.pumpAndSettle();

    expect(controller.state!.people.length, once + 1);
    // Tanışmak sevgili olmak değildir (D-107): sonuç, iki tarafın
    // niyetine göre flört ya da arkadaşlıktır — ama asla doğrudan
    // sevgililik değildir.
    expect(
      controller.state!.people.last.relation,
      anyOf(RelationType.flort, RelationType.arkadas),
    );
    expect(
      controller.state!.people.last.relation,
      isNot(RelationType.sevgili),
    );
  });

  testWidgets('18 yaşından küçüğe menüde görünmez',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 5600);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      BirOmurApp(controller: controller, sound: SoundService.silent()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rastgele bir hayat'));
    await tester.pumpAndSettle();
    controller.debugSetState(hayat(age: 15));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tab_aktiviteler')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('activity_finger')), findsNothing);
  });

  // D-088: profil düzenleyicide RadioMenuButton kullanılmıştı. O bir
  // menü bileşeni ve etiketini sınırsız genişlikte yerleştiriyor; uzun
  // tanıtım cümleleri satırı 271-325 piksel taşırıyordu. Faho'nun
  // "Finger ekranına girince oyun donuyor" bildiriminin sebebi buydu.
  testWidgets('profil düzenleyici açılır ve taşma üretmez',
      (WidgetTester tester) async {
    await fingeriAc(tester, hayat());
    await scrollToFinder(tester, find.byKey(const Key('finger_profil_ac')));
    await tester.tap(find.byKey(const Key('finger_profil_ac')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('finger_profil_kaydet')), findsOneWidget);
    // Seçim satırları gerçekten gösteriliyor ve metni sarıyor.
    expect(find.byKey(const Key('finger_bio_0')), findsOneWidget);
  });

  testWidgets('profil kaydedilince kayıt gerçekten değişir',
      (WidgetTester tester) async {
    await fingeriAc(tester, hayat());
    expect(controller.state!.hasFingerProfile, isFalse);

    await scrollToFinder(tester, find.byKey(const Key('finger_profil_ac')));
    await tester.tap(find.byKey(const Key('finger_profil_ac')));
    await tester.pumpAndSettle();
    await scrollToFinder(tester, find.byKey(const Key('finger_bio_0')));
    await tester.tap(find.byKey(const Key('finger_bio_0')));
    await tester.pumpAndSettle();
    await scrollToFinder(
      tester,
      find.byKey(const Key('finger_profil_kaydet')),
    );
    await tester.tap(find.byKey(const Key('finger_profil_kaydet')));
    await tester.pumpAndSettle();

    expect(controller.state!.hasFingerProfile, isTrue);
    expect(controller.state!.fingerBio, isNotNull);
  });
}
