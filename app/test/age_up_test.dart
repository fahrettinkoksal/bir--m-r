import 'dart:math';

import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/life_log.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_flow.dart';

/// **Yaş Al** (D-018) bu aşamada yalnızca zamanı ilerletir; olay motoru
/// (Aşama 3) henüz yazılmadı.
void main() {
  GameController controllerWithLife({int seed = 5}) {
    final GameController controller = GameController(random: Random(seed));
    controller.startNewLife(mode: StartMode.tamamenRastgele, seed: seed);
    return controller;
  }

  /// Ekranda olay varken yaş ilerlemez (D-021); olay çözülür.
  void olayiKapat(GameController controller) {
    while (controller.state!.hasPendingEvent) {
      controller.chooseEventOption(
        controller.state!.pendingEvent!.choices.first.id,
      );
    }
  }

  test('yaş al bir yaş ilerletir', () {
    final GameController controller = controllerWithLife();
    expect(controller.state!.player.age, 0);
    // Lise alanı seçilmeden yaş atlanmaz (D-094).
    resolveTrackChoice(controller);
    controller.ageUp();
    expect(controller.state!.player.age, 1);
    // Bebeklik olayları eklendiğinden (Paket 4) ilk yaşlarda da olay
    // çıkabilir; yaş ilerlemesi için olayın çözülmesi gerekir.
    olayiKapat(controller);
    // Lise alanı seçilmeden yaş atlanmaz (D-094).
    resolveTrackChoice(controller);
    controller.ageUp();
    olayiKapat(controller);
    // Lise alanı seçilmeden yaş atlanmaz (D-094).
    resolveTrackChoice(controller);
    controller.ageUp();
    expect(controller.state!.player.age, 3);
  });

  test('hayattaki herkes birlikte yaşlanır, vefat edenin yaşı sabit kalır', () {
    for (int seed = 0; seed < 60; seed++) {
      final GameController controller = controllerWithLife(seed: seed);
      final GameState before = controller.state!;
      final Map<String, int> agesBefore = <String, int>{
        for (final Person p in before.people) p.id: p.age,
      };
      final Map<String, bool> aliveBefore = <String, bool>{
        for (final Person p in before.people) p.id: p.isAlive,
      };

      // Lise alanı seçilmeden yaş atlanmaz (D-094).
      resolveTrackChoice(controller);
      controller.ageUp();
      final GameState after = controller.state!;

      expect(after.people.length, before.people.length,
          reason: 'Vefat eden kişinin kaydı silinmez');
      for (final Person p in after.people) {
        final int previous = agesBefore[p.id]!;
        if (p.isAlive) {
          expect(p.age, previous + 1);
        } else if (aliveBefore[p.id]!) {
          // Bu yıl vefat etti: o yaşı yaşadı, sonra vefat etti.
          expect(p.age, previous + 1);
        } else {
          // Zaten vefat etmişti: yaşı sabit kalır.
          expect(p.age, previous);
        }
      }
    }
  });

  test('kişi kimlikleri yaş almada korunur', () {
    final GameController controller = controllerWithLife(seed: 9);
    final List<String> ids =
        controller.state!.people.map((Person p) => p.id).toList();
    advanceToAge(controller, 20);

    // Hayat ilerledikçe yeni kişiler (örneğin sevgili) eklenebilir; mevcut
    // kişilerin kimlikleri ve sırası değişmez, hiçbiri silinmez.
    final List<String> sonra =
        controller.state!.people.map((Person p) => p.id).toList();
    expect(sonra.length, greaterThanOrEqualTo(ids.length));
    expect(sonra.sublist(0, ids.length), ids);
  });

  test('her yaş almada günlüğe tam bir satır eklenir ve olay yağmuru olmaz', () {
    final GameController controller = controllerWithLife(seed: 3);
    final int before = controller.state!.log.length;
    // Lise alanı seçilmeden yaş atlanmaz (D-094).
    resolveTrackChoice(controller);
    controller.ageUp();
    final List<LifeLogEntry> log = controller.state!.log;
    expect(log.length, before + 1);
    expect(log.last.category, LogCategory.yasDegisimi);
    expect(log.last.age, 1);
  });

  test('yaş alma kendiliğinden Ün açmaz', () {
    final GameController controller = controllerWithLife(seed: 12);
    advanceToAge(controller, 25);
    expect(controller.state!.player.fame, isNull);
  });

  test('yaşa bağlı tutarlılık korunur: çalışmayana meslek atanmaz', () {
    for (int seed = 0; seed < 40; seed++) {
      final GameController controller = controllerWithLife(seed: seed);
      advanceToAge(controller, 30);
      for (final Person p in controller.state!.people) {
        if (p.employment == EmploymentStatus.calisiyor) {
          expect(p.occupation, isNotNull);
        } else {
          expect(p.occupation, isNull);
        }
        if (p.isAlive && p.age >= 6 && p.age < 18) {
          expect(p.employment, EmploymentStatus.ogrenci);
        }
      }
    }
  });

  test('okul öncesi kardeş zamanla öğrenci olur', () {
    // Küçük kardeşi olan bir tohum bul.
    GameController? controller;
    for (int seed = 0; seed < 200 && controller == null; seed++) {
      final GameController candidate = controllerWithLife(seed: seed);
      final bool hasYoungChild = candidate.state!.people
          .any((Person p) => p.isAlive && p.age < 6);
      if (hasYoungChild) controller = candidate;
    }
    expect(controller, isNotNull, reason: 'Okul öncesi kişi içeren örnek bulunmalı');

    final String id = controller!.state!.people
        .firstWhere((Person p) => p.isAlive && p.age < 6)
        .id;
    advanceToAge(controller, controller.state!.player.age + 8);
    final Person after = controller.state!.personById(id)!;
    expect(after.age, greaterThanOrEqualTo(6));
    expect(after.employment, isNot(EmploymentStatus.cocuk));
  });

  test('ekranda olay varken yaş ilerlemez', () {
    final GameController controller = controllerWithLife(seed: 5);
    advanceToAge(controller, 5);
    // Olay çıkana kadar ilerle.
    int guard = 0;
    while (!controller.state!.hasPendingEvent && guard++ < 40) {
      // Lise alanı seçilmeden yaş atlanmaz (D-094).
      resolveTrackChoice(controller);
      controller.ageUp();
    }
    expect(controller.state!.hasPendingEvent, isTrue,
        reason: 'Yaşa uygun bir olay çıkmalı');

    final int age = controller.state!.player.age;
    // Lise alanı seçilmeden yaş atlanmaz (D-094).
    resolveTrackChoice(controller);
    controller.ageUp();
    expect(controller.state!.player.age, age,
        reason: 'Olay çözülmeden yaş ilerlememeli');

    resolvePendingEvents(controller);
    // Lise alanı seçilmeden yaş atlanmaz (D-094).
    resolveTrackChoice(controller);
    controller.ageUp();
    expect(controller.state!.player.age, age + 1);
  });

  test('yeni hayat başlatmak önceki durumu değiştirmez, temizlemek sıfırlar', () {
    final GameController controller = controllerWithLife(seed: 21);
    // Lise alanı seçilmeden yaş atlanmaz (D-094).
    resolveTrackChoice(controller);
    controller.ageUp();
    final String firstName = controller.state!.player.fullName;

    controller.startNewLife(mode: StartMode.tamamenRastgele, seed: 22);
    expect(controller.state!.player.age, 0);
    expect(controller.state!.player.fullName, isNot(equals(firstName)));

    controller.clearLife();
    expect(controller.hasLife, isFalse);
    expect(controller.state, isNull);
  });
}
