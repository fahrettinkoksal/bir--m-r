import 'dart:math';

import 'package:bir_omur/data/health_crisis_catalog.dart';
import 'package:bir_omur/domain/generation/school_people.dart';
import 'package:bir_omur/domain/models/education.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter/widgets.dart';
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
  Set<String> preferChoiceIds = const <String>{},
}) async {
  await tester.pumpAndSettle();
  // Sağlık krizi olay penceresinden önce gelir (D-044); önce o yanıtlanır.
  await answerPendingCrisis(tester, controller);
  // Önemli haberler (ölüm, miras, cenaze) krizle olay arasında gelir.
  await answerPendingNotices(tester, controller);
  int guard = 0;
  while (controller.state!.hasPendingEvent) {
    // Hayat tamamlandıysa olay ekranı açılmaz; vefat eden oyuncuya olay
    // sorulmaz.
    if (controller.state!.deceased) return;
    if (guard++ > 20) {
      fail('Olaylar kapanmıyor: sonsuz döngü koruması devreye girdi.');
    }
    final ActiveEvent event = controller.state!.pendingEvent!;
    final EventChoice choice = event.choices.firstWhere(
      (EventChoice c) =>
          c.id == preferChoiceId || preferChoiceIds.contains(c.id),
      orElse: () => event.choices.first,
    );
    // Olay penceresi açılmadan düğme aranmaz; kriz penceresi kapandıktan
    // sonra açılması bir kare sürebiliyor.
    await tester.pumpAndSettle();
    if (find.text(choice.label).evaluate().isEmpty) {
      await answerPendingCrisis(tester, controller);
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text(choice.label));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Devam'));
    await tester.pumpAndSettle();
  }
}

/// Ekranda sağlık krizi varsa ilk seçilebilir seçeneği seçerek kapatır.
Future<void> answerPendingCrisis(
  WidgetTester tester,
  GameController controller,
) async {
  int guard = 0;
  while (controller.state!.hasPendingCrisis) {
    if (guard++ > 10) fail('Sağlık krizi kapanmıyor.');
    final HealthCrisis kriz = controller.pendingCrisis!.crisis!;
    final CrisisChoice secim = kriz.choices.firstWhere(
      controller.canChooseCrisis,
      orElse: () => kriz.choices.last,
    );

    // Kriz penceresi açıldıysa düğmeye basılır; henüz açılmadıysa yanıt
    // doğrudan verilir. İki yol da aynı sonucu uygular.
    final Finder secenek = find.byKey(Key('crisis_choice_${secim.id}'));
    if (secenek.evaluate().isNotEmpty) {
      await tester.tap(secenek);
      await tester.pumpAndSettle();
      final Finder kapat = find.text('Kapat');
      if (kapat.evaluate().isNotEmpty) {
        await tester.tap(kapat.last);
        await tester.pumpAndSettle();
      }
    } else {
      controller.respondToCrisis(secim.id);
      await tester.pumpAndSettle();
    }
  }
}

/// Ekranda bekleyen bildirim varsa kapatır (D-050).
///
/// Cenaze bildiriminde **katkıda bulunmama** seçeneği işaretlenir; böylece
/// testler cüzdanı beklenmedik şekilde değiştirmez.
Future<void> answerPendingNotices(
  WidgetTester tester,
  GameController controller,
) async {
  int guard = 0;
  while (controller.state!.hasNotice) {
    if (guard++ > 20) fail('Bildirimler kapanmıyor.');
    await tester.pumpAndSettle();
    final Finder katkisiz =
        find.byKey(const Key('funeral_choice_katkiYok'));
    final Finder kapat = find.byKey(const Key('notice_close'));
    if (katkisiz.evaluate().isNotEmpty) {
      await tester.tap(katkisiz);
      await tester.pumpAndSettle();
      // Seçimden sonra pencere "Tamam" ile kapanır.
      if (find.byKey(const Key('notice_close')).evaluate().isNotEmpty) {
        await tester.tap(find.byKey(const Key('notice_close')));
        await tester.pumpAndSettle();
      }
    } else if (kapat.evaluate().isNotEmpty) {
      await tester.tap(kapat);
      await tester.pumpAndSettle();
    } else {
      // Pencere henüz açılmadıysa doğrudan yanıtlanır.
      controller.dismissNotice();
      await tester.pumpAndSettle();
    }
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
    // Oyuncu vefat ettiyse hayat tamamlanmıştır; yaş ilerlemez.
    if (controller.state!.deceased) return;
    if (guard++ > 200) fail('Yaş ilerlemiyor.');
    await answerPendingEvents(tester, controller, preferChoiceId: preferChoiceId);
    await tester.tap(find.byKey(const Key('age_up_button')));
    await tester.pumpAndSettle();
  }
  await answerPendingEvents(tester, controller, preferChoiceId: preferChoiceId);
}

/// Arayüzsüz (domain) testler için: ekranda olay varsa seçim yaparak kapatır.
void resolvePendingEvents(GameController controller, {String? preferChoiceId}) {
  // Arayüzsüz testlerde bildirimler doğrudan kapatılır.
  int noticeGuard = 0;
  while (controller.state!.hasNotice) {
    if (noticeGuard++ > 30) fail('Bildirimler kapanmıyor.');
    controller.dismissNotice();
  }
  // Arayüzsüz testlerde sağlık krizi de doğrudan yanıtlanır.
  int crisisGuard = 0;
  while (controller.state!.hasPendingCrisis) {
    if (crisisGuard++ > 10) {
      throw StateError('Sağlık krizi kapanmıyor.');
    }
    final HealthCrisis kriz = controller.pendingCrisis!.crisis!;
    final CrisisChoice secim = kriz.choices.firstWhere(
      controller.canChooseCrisis,
      orElse: () => kriz.choices.last,
    );
    controller.respondToCrisis(secim.id);
  }

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
    // Oyuncu vefat ettiyse hayat tamamlanmıştır; yaş ilerlemez.
    if (controller.state!.deceased) return;
    if (guard++ > 500) throw StateError('Yaş ilerlemiyor.');
    resolvePendingEvents(controller, preferChoiceId: preferChoiceId);
    controller.ageUp();
  }
  resolvePendingEvents(controller, preferChoiceId: preferChoiceId);
}

/// Testte okul kişilerini (sınıf arkadaşları + öğretmen) duruma ekler.
///
/// Gerçek oyunda bu kişiler kademe geçişinde üretilir; elle kurulan test
/// durumlarında aynı gerçekliği sağlamak için kullanılır. Eğitim durumuna
/// okul/sınıf kimliği de yazılır, böylece güncel sınıf listeleri çalışır.
GameState withSchoolPeople(GameState state, {int seed = 1}) {
  final SchoolLevel? level = state.education.level;
  if (level == null) return state;
  final String classId = SchoolPeople.classIdFor(level);
  if (state.people.any((Person p) => p.classId == classId)) return state;

  final ClassRoster roster = const SchoolPeople().buildClass(
    state: state,
    level: level,
    rng: Random(seed),
  );
  return state.copyWith(
    people: List<Person>.unmodifiable(<Person>[
      ...state.people,
      ...roster.newPeople,
    ]),
    education: state.education.copyWith(
      schoolId: SchoolPeople.schoolIdFor(level),
      classId: classId,
    ),
  );
}
