import 'dart:math';

import 'package:bir_omur/data/education_tracks.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/education/education_path.dart';
import 'package:bir_omur/domain/models/education.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:bir_omur/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Lise alan seçimi (D-094).
///
/// Liseye geçilen yıl alan seçimi zorunludur: seçim yapılmadan yaş
/// atlanamaz ve sessizce varsayılan alan seçilmez.
void main() {
  GameController liseyeGecmisOyuncu({int seed = 7}) {
    final GameController controller = GameController(random: Random(seed));
    controller.startNewLife(mode: StartMode.tamamenRastgele, seed: seed);
    final GameState state = controller.state!;
    controller.debugSetState(
      state.copyWith(
        education: const EducationState(
          enrolled: true,
          grade: 9,
          startedAtAge: 6,
          placementScore: 80,
        ),
        pendingEvent: null,
      ),
    );
    return controller;
  }

  test('lise alanı seçilmeden yaş atlanamaz', () {
    final GameController controller = liseyeGecmisOyuncu();
    expect(controller.needsTrackChoice, isTrue);

    final int onceki = controller.state!.player.age;
    controller.ageUp();
    expect(
      controller.state!.player.age,
      onceki,
      reason: 'Alan seçilmeden yaş ilerlememeli.',
    );
  });

  test('alan seçildikten sonra yaş yeniden ilerler', () {
    final GameController controller = liseyeGecmisOyuncu();
    final int onceki = controller.state!.player.age;

    final EducationOutcome? sonuc =
        controller.chooseTrack(EducationTrack.fenBilim);
    expect(sonuc?.applied, isTrue);
    expect(controller.needsTrackChoice, isFalse);
    expect(controller.state!.education.track, EducationTrack.fenBilim);

    controller.ageUp();
    expect(controller.state!.player.age, onceki + 1);
  });

  test('seçim hayat günlüğüne yazılır ve sonuç metni döner', () {
    final GameController controller = liseyeGecmisOyuncu();
    final int oncekiSatir = controller.state!.log.length;

    final EducationOutcome? sonuc =
        controller.chooseTrack(EducationTrack.bilisim);
    expect(sonuc, isNotNull);
    expect(sonuc!.text, contains('Bilişim'));
    expect(
      controller.state!.log.length,
      greaterThan(oncekiSatir),
      reason: 'Seçim günlüğe işlenmeli.',
    );
  });

  test('puanı yetmeyen alan seçilemez, seçim beklemeye devam eder', () {
    final GameController controller = liseyeGecmisOyuncu();
    controller.debugSetState(
      controller.state!.copyWith(
        education: controller.state!.education.copyWith(placementScore: 10),
      ),
    );
    // Puan eşiği en yüksek alan.
    final EducationTrackInfo zor = kEducationTracks.reduce(
      (EducationTrackInfo a, EducationTrackInfo b) =>
          a.minScore >= b.minScore ? a : b,
    );
    expect(zor.minScore, greaterThan(10));

    final EducationOutcome? sonuc = controller.chooseTrack(zor.track);
    expect(sonuc?.applied, isFalse);
    expect(controller.state!.education.track, isNull);
    expect(controller.needsTrackChoice, isTrue);

    // Puan ne olursa olsun seçilebilecek en az bir alan vardır.
    expect(controller.availableTracks(), isNotEmpty);
  });

  test('seçilen alan kayıt açılıp kapandığında korunur', () {
    final GameController controller = liseyeGecmisOyuncu();
    controller.chooseTrack(EducationTrack.guzelSanatlar);

    final GameState geri = decodeGameState(encodeGameState(controller.state!));
    expect(geri.education.track, EducationTrack.guzelSanatlar);
    expect(geri.education.awaitingTrackChoice, isFalse);
  });

  testWidgets('Yaş Al alan seçimi bekliyorken seçim ekranını açar',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 4800);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final GameController controller = GameController(random: Random(3));
    addTearDown(controller.dispose);
    await tester.pumpWidget(BirOmurApp(controller: controller));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rastgele bir hayat'));
    await tester.pumpAndSettle();

    final GameState state = controller.state!;
    controller.debugSetState(
      state.copyWith(
        education: const EducationState(
          enrolled: true,
          grade: 9,
          startedAtAge: 6,
          placementScore: 80,
        ),
        pendingEvent: null,
      ),
    );
    await tester.pumpAndSettle();
    final int onceki = controller.state!.player.age;

    await tester.tap(find.byKey(const Key('age_up_button')));
    await tester.pumpAndSettle();

    // Yaş ilerlemedi, bunun yerine seçim penceresi açıldı.
    expect(controller.state!.player.age, onceki);
    expect(find.byKey(const Key('track_choice_title')), findsOneWidget);

    await tester.tap(find.byKey(const Key('track_choice_fenBilim')));
    await tester.pumpAndSettle();
    expect(controller.state!.education.track, EducationTrack.fenBilim);

    // Sonuç aynı pencerede gösterilir; oyuncu ne olduğunu görmeden kapanmaz.
    expect(find.byKey(const Key('track_choice_close')), findsOneWidget);
    await tester.tap(find.byKey(const Key('track_choice_close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('track_choice_title')), findsNothing);
  });
}
