import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testler için ortak akış yardımcıları.
///
/// Yaş alınca tek bir olay çıktığı için, arayüz testlerinde ilerlemeden önce
/// ekrandaki olayın yanıtlanması gerekir.

/// Ekranda olay varsa ilk seçeneği seçerek kapatır; art arda olay varsa
/// hepsini yanıtlar.
Future<void> answerPendingEvents(
  WidgetTester tester,
  GameController controller, {
  String? preferChoiceId,
}) async {
  await tester.pumpAndSettle();
  int guard = 0;
  while (controller.state!.hasPendingEvent) {
    if (guard++ > 20) {
      fail('Olaylar kapanmıyor: sonsuz döngü koruması devreye girdi.');
    }
    final ActiveEvent event = controller.state!.pendingEvent!;
    final EventChoice choice = event.choices.firstWhere(
      (EventChoice c) => c.id == preferChoiceId,
      orElse: () => event.choices.first,
    );
    await tester.tap(find.text(choice.label));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Devam'));
    await tester.pumpAndSettle();
  }
}

/// Hedef yaşa, yol boyunca çıkan olayları yanıtlayarak ilerler.
Future<void> ageTo(
  WidgetTester tester,
  GameController controller,
  int targetAge, {
  String? preferChoiceId,
}) async {
  int guard = 0;
  while (controller.state!.player.age < targetAge) {
    if (guard++ > 200) fail('Yaş ilerlemiyor.');
    await answerPendingEvents(tester, controller, preferChoiceId: preferChoiceId);
    await tester.tap(find.text('Yaş Al'));
    await tester.pumpAndSettle();
  }
  await answerPendingEvents(tester, controller, preferChoiceId: preferChoiceId);
}

/// Arayüzsüz (domain) testler için: ekranda olay varsa seçim yaparak kapatır.
void resolvePendingEvents(GameController controller, {String? preferChoiceId}) {
  int guard = 0;
  while (controller.state!.hasPendingEvent) {
    if (guard++ > 50) {
      throw StateError('Olaylar kapanmıyor: sonsuz döngü koruması.');
    }
    final ActiveEvent event = controller.state!.pendingEvent!;
    final EventChoice choice = event.choices.firstWhere(
      (EventChoice c) => c.id == preferChoiceId,
      orElse: () => event.choices.first,
    );
    controller.chooseEventOption(choice.id);
  }
}

/// Hedef yaşa ilerler; yol boyunca çıkan olayları seçim yaparak çözer.
void advanceToAge(
  GameController controller,
  int targetAge, {
  String? preferChoiceId,
}) {
  int guard = 0;
  while (controller.state!.player.age < targetAge) {
    if (guard++ > 500) throw StateError('Yaş ilerlemiyor.');
    resolvePendingEvents(controller, preferChoiceId: preferChoiceId);
    controller.ageUp();
  }
  resolvePendingEvents(controller, preferChoiceId: preferChoiceId);
}
