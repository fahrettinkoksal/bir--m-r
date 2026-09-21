import 'dart:math';

import 'package:bir_omur/data/event_pool.dart';
import 'package:bir_omur/data/event_pool_infancy.dart';
import 'package:bir_omur/domain/events/event_engine.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:flutter_test/flutter_test.dart';

/// İlk yılların olayları (Paket 13).
void main() {
  const EventEngine motor = EventEngine();

  GameState bebek({int age = 2, int seed = 141}) {
    final GameState base =
        LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
    return base.copyWith(
      pendingEvent: null,
      player: base.player.copyWith(age: age),
    );
  }

  Set<String> cikanOlaylar(GameState state, {int deneme = 400}) {
    final Set<String> sonuc = <String>{};
    for (int i = 0; i < deneme; i++) {
      final ActiveEvent? olay =
          motor.openingEvent(state.copyWith(pendingEvent: null), Random(i));
      if (olay != null) sonuc.add(olay.eventId);
    }
    return sonuc;
  }

  test('ilk yıllar olayları havuzda ve kimlikleri benzersiz', () {
    expect(kInfancyEvents, isNotEmpty);
    final Set<String> havuz =
        kEventPool.map((GameEvent e) => e.id).toSet();
    for (final GameEvent e in kInfancyEvents) {
      expect(havuz, contains(e.id));
      expect(e.choices.length, greaterThanOrEqualTo(2));
    }
    // Mevcut olaylar tekrar yazılmadı.
    for (final String eski in <String>[
      'ilk_adim',
      'ilk_kelime',
      'asi_gunu',
      'ilk_oyuncak_paylasimi',
    ]) {
      expect(
        kInfancyEvents.where((GameEvent e) => e.id == eski),
        isEmpty,
        reason: '$eski zaten event_pool_stages.dart içinde var',
      );
    }
  });

  test('0-4 yaşta gerçekten olay çıkıyor', () {
    for (int yas = 0; yas <= 4; yas++) {
      expect(
        cikanOlaylar(bebek(age: yas)),
        isNotEmpty,
        reason: '$yas yaşında hiç olay çıkmıyor',
      );
    }
  });

  test('ilk yıl olayları yalnızca küçük yaşta çıkar', () {
    final Set<String> yetiskin = cikanOlaylar(bebek(age: 30));
    for (final GameEvent e in kInfancyEvents) {
      if (e.requirement.maxAge >= 12) continue;
      expect(yetiskin, isNot(contains(e.id)));
    }
  });

  test('ebeveyni olmayan bebeğe ebeveynli olay çıkmaz', () {
    final GameState oksuz = bebek(age: 1).copyWith(
      people: bebek(age: 1)
          .people
          .where((Person p) =>
              p.relation != RelationType.anne &&
              p.relation != RelationType.baba)
          .toList(growable: false),
    );
    final Set<String> cikanlar = cikanOlaylar(oksuz);
    for (final GameEvent e in kInfancyEvents) {
      if (e.requirement.livingRelations.isEmpty) continue;
      expect(cikanlar, isNot(contains(e.id)),
          reason: '${e.id} ebeveynsiz çıkmamalı');
    }
  });

  test('bebeklik anısı yalnızca iz bırakıldıysa çıkar', () {
    final GameState izsiz = bebek(age: 20);
    expect(cikanOlaylar(izsiz), isNot(contains('bebeklik_hikayesi')));

    final GameState izli = izsiz.copyWith(
      storyFlags: <String>{InfancyFlags.merakli},
    );
    expect(cikanOlaylar(izli), contains('bebeklik_hikayesi'));
  });

  test('metinlerde doldurulmamış yer tutucu kalmaz', () {
    for (int yas = 0; yas <= 5; yas++) {
      for (int i = 0; i < 60; i++) {
        final ActiveEvent? olay = motor.openingEvent(
          bebek(age: yas).copyWith(pendingEvent: null),
          Random(i),
        );
        if (olay == null) continue;
        expect(olay.text, isNot(contains('{')));
        for (final EventChoice c in olay.choices) {
          expect(c.label, isNot(contains('{')));
        }
      }
    }
  });
}
