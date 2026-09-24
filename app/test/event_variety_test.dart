import 'dart:math';

import 'package:bir_omur/data/event_pool.dart';
import 'package:bir_omur/data/event_pool_midlife.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/data/save/save_format.dart';
import 'package:bir_omur/domain/events/event_engine.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/pending_crisis.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_flow.dart';

/// Olay çeşitliliği (Paket 20).
///
/// Ölçüm, 30-49 yaş arasında bir yılda ortalama yalnızca 1-2 uygun olay
/// bulunduğunu ve aynı olayın bir hayatta üç dört kez çıktığını
/// göstermişti. Bu testler iki şeyi birden korur: **tekrar sönümü**
/// çalışıyor mu ve **orta yaş artık boş mu değil mi**.
GameState hayat({int seed = 3, int age = 35}) {
  final GameState base =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  return base.copyWith(
    pendingEvent: null,
    player: base.player.copyWith(age: age),
  );
}

/// Bir hayatı sonuna kadar oynar ve olay sayaçlarını döndürür.
Map<String, int> hayatOyna(int seed, {int maxAge = 95}) {
  final GameController c = GameController(random: Random(seed));
  c.startNewLife(mode: StartMode.tamamenRastgele);
  final Map<String, int> gorulen = <String, int>{};
  while (!c.state!.deceased && c.state!.player.age < maxAge) {
    int guard = 0;
    while (c.state!.hasPendingEvent && guard++ < 10) {
      final String id = c.state!.pendingEvent!.eventId;
      gorulen[id] = (gorulen[id] ?? 0) + 1;
      c.chooseEventOption(c.state!.pendingEvent!.choices.first.id);
    }
    while (c.state!.hasNotice) {
      c.dismissNotice();
    }
    if (c.state!.hasPendingCrisis) {
      final PendingCrisis k = c.state!.pendingCrisis!;
      c.respondToCrisis(k.crisis!.choices.first.id);
    }
    // Lise alanı seçilmeden yaş atlanmaz (D-094).
    resolveEducationChoices(c);
    c.ageUp();
  }
  c.dispose();
  return gorulen;
}

void main() {
  // ===================================================================
  // Tekrar sönümü
  // ===================================================================
  group('Tekrar sönümü', () {
    test('görülmemiş olay tam ağırlığıyla yarışır', () {
      final GameState s = hayat();
      final GameEvent e =
          kEventPool.firstWhere((GameEvent e) => e.priority == 0);
      expect(
        EventEngine.prototypeOnlyEffectiveWeight(s, e),
        e.weight.toDouble(),
      );
    });

    test('her tekrarda ağırlık düşer ama sıfırlanmaz', () {
      final GameEvent e = kEventPool.firstWhere((GameEvent e) => e.weight >= 5 && e.priority == 0);
      final double taban = e.weight * EventEngine.prototypeOnlyMinWeightRatio;
      double onceki = e.weight.toDouble();
      for (int kez = 1; kez <= 5; kez++) {
        final GameState s = hayat().copyWith(
          eventSeenCounts: <String, int>{e.id: kez},
        );
        final double simdi = EventEngine.prototypeOnlyEffectiveWeight(s, e);
        // Taban orana inene kadar her tekrar ağırlığı düşürür; tabanda
        // sabitlenir ve olay tamamen kaybolmaz.
        if (onceki > taban) {
          expect(simdi, lessThan(onceki), reason: '$kez. tekrar');
        } else {
          expect(simdi, taban, reason: '$kez. tekrarda taban korunmalı');
        }
        expect(simdi, greaterThanOrEqualTo(taban));
        onceki = simdi;
      }
      // İlk iki tekrar gerçekten belirgin bir düşüş yaratmalı.
      final double birKez = EventEngine.prototypeOnlyEffectiveWeight(
        hayat().copyWith(eventSeenCounts: <String, int>{e.id: 1}),
        e,
      );
      expect(birKez, lessThan(e.weight * 0.5));
    });

    test('ağırlık taban oranın altına inmez', () {
      final GameEvent e = kEventPool.firstWhere((GameEvent e) => e.weight >= 5 && e.priority == 0);
      final GameState s = hayat().copyWith(
        eventSeenCounts: <String, int>{e.id: 40},
      );
      expect(
        EventEngine.prototypeOnlyEffectiveWeight(s, e),
        e.weight * EventEngine.prototypeOnlyMinWeightRatio,
      );
    });

    test('tekrar aralığı her görülmede büyür ve bir tavanla sınırlıdır', () {
      final GameEvent e =
          kEventPool.firstWhere((GameEvent e) => e.repeatable && e.priority == 0);
      int onceki = EventEngine.prototypeOnlyEffectiveGap(
        hayat().copyWith(eventSeenCounts: const <String, int>{}),
        e,
      );
      expect(onceki, e.minAgeGap);
      for (int kez = 1; kez <= 4; kez++) {
        final int simdi = EventEngine.prototypeOnlyEffectiveGap(
          hayat().copyWith(eventSeenCounts: <String, int>{e.id: kez}),
          e,
        );
        expect(simdi, greaterThan(onceki));
        onceki = simdi;
      }
      final int tavan = EventEngine.prototypeOnlyEffectiveGap(
        hayat().copyWith(eventSeenCounts: <String, int>{e.id: 99}),
        e,
      );
      expect(tavan, EventEngine.prototypeOnlyMaxRepeatGap);
    });

    test('olay çıkınca sayaç gerçekten artar', () {
      final GameController c = GameController(random: Random(5));
      c.startNewLife(mode: StartMode.tamamenRastgele);
      int guard = 0;
      while (!c.state!.hasPendingEvent && guard++ < 20) {
        // Lise alanı seçilmeden yaş atlanmaz (D-094).
        resolveEducationChoices(c);
        c.ageUp();
      }
      expect(c.state!.hasPendingEvent, isTrue);
      final String id = c.state!.pendingEvent!.eventId;
      expect(c.state!.eventSeenCount(id), 0);

      c.chooseEventOption(c.state!.pendingEvent!.choices.first.id);
      expect(c.state!.eventSeenCount(id), 1);
      c.dispose();
    });

    test('sayaç kayıt turunda korunur', () {
      final GameState s = hayat().copyWith(
        eventSeenCounts: const <String, int>{'orta_kira_zammi': 3},
      );
      final GameState geri = decodeGameState(
        SaveMigrations.migrate(encodeGameState(s), kSaveFormatVersion),
      );
      expect(geri.eventSeenCount('orta_kira_zammi'), 3);
    });

    test('eski kayıtta görülen olaylar bir kez görülmüş sayılır', () {
      final GameState s = hayat().copyWith(
        seenEventIds: const <String>{'a', 'b'},
        eventSeenCounts: const <String, int>{},
      );
      final Map<String, Object?> body =
          Map<String, Object?>.from(encodeGameState(s))
            ..remove('eventSeenCounts');
      final GameState geri = decodeGameState(SaveMigrations.migrate(body, 27));

      expect(geri.eventSeenCount('a'), 1);
      expect(geri.eventSeenCount('b'), 1);
      expect(geri.eventSeenCount('c'), 0);
    });
  });

  // ===================================================================
  // Orta yaş içeriği
  // ===================================================================
  group('Orta yaş', () {
    test('olay kimlikleri benzersiz ve havuzda kayıtlı', () {
      final Set<String> kimlikler = <String>{};
      for (final GameEvent e in kMidlifeEvents) {
        expect(kimlikler.add(e.id), isTrue, reason: 'Tekrar eden: ${e.id}');
        expect(
          kEventPool.where((GameEvent a) => a.id == e.id).length,
          1,
          reason: '${e.id} ana havuzda tam olarak bir kez olmalı',
        );
      }
    });

    test('her olayın en az iki özgün seçeneği var', () {
      final Set<String> metinler = <String>{};
      for (final GameEvent e in kMidlifeEvents) {
        expect(e.choices.length, greaterThanOrEqualTo(2), reason: e.id);
        for (final EventChoice c in e.choices) {
          expect(metinler.add(c.resultText), isTrue,
              reason: 'Aynı sonuç metni iki kez: ${e.id}/${c.id}');
        }
      }
    });

    test('çoğu olay koşulsuzdur: eş, iş veya eşya gerektirmez', () {
      final int kosulsuz = kMidlifeEvents.where((GameEvent e) {
        final EventRequirement r = e.requirement;
        return r.livingRelations.isEmpty &&
            !r.requiresEmployed &&
            r.requiredPossessions.isEmpty &&
            r.requiredPossessionKinds.isEmpty &&
            !r.requiresSocialAccount;
      }).length;
      // Bu paketin amacı, nasıl bir hayat yaşanırsa yaşansın orta yaşın
      // dolu geçmesi. D-085 ile eşin ev/araba beklentisi eklendi; bunlar
      // doğaları gereği koşulludur. Kural artık mutlak sayı değil
      // **oran**: havuzun büyük çoğunluğu koşulsuz kalmalı ki bekâr,
      // işsiz ve mülksüz bir hayat da dolu geçsin.
      expect(
        kosulsuz / kMidlifeEvents.length,
        greaterThanOrEqualTo(0.75),
        reason: '$kosulsuz / ${kMidlifeEvents.length} koşulsuz',
      );
      // Koşulsuz olayların mutlak sayısı da bir tabanın altına inemez.
      expect(kosulsuz, greaterThanOrEqualTo(20));
    });

    test('iki olay önceki kararı hatırlar', () {
      final int hatirlayan = kMidlifeEvents
          .where((GameEvent e) => e.requirement.requiredFlags.isNotEmpty)
          .length;
      expect(hatirlayan, greaterThanOrEqualTo(2));
    });

    test('30-55 yaş aralığında bir yılda birden çok olay uygun olur', () {
      const EventEngine motor = EventEngine();
      for (final int yas in <int>[32, 38, 45, 52]) {
        final GameState s = hayat(age: yas);
        final int uygun = kEventPool
            .where((GameEvent e) => motor.debugMatches(s, e))
            .length;
        // Ölçümde bu bant yılda 1-2 olaya düşüyordu.
        expect(uygun, greaterThanOrEqualTo(8), reason: '$yas yaşında $uygun');
      }
    });
  });

  // ===================================================================
  // Gerçek hayatlarda sonuç
  // ===================================================================
  group('Gerçek hayatta çeşitlilik', () {
    test('bir hayatta aynı olay dörtten fazla çıkmaz', () {
      for (int seed = 1; seed <= 6; seed++) {
        final Map<String, int> gorulen = hayatOyna(seed * 7);
        for (final MapEntry<String, int> e in gorulen.entries) {
          expect(e.value, lessThanOrEqualTo(4),
              reason: 'Tohum ${seed * 7}: ${e.key} ${e.value} kez çıktı');
        }
      }
    });

    test('bir hayat en az kırk farklı olay gösterir', () {
      for (int seed = 1; seed <= 4; seed++) {
        final Map<String, int> gorulen = hayatOyna(seed * 11);
        expect(gorulen.length, greaterThanOrEqualTo(40),
            reason: 'Tohum ${seed * 11}: yalnızca ${gorulen.length} farklı olay');
      }
    });
  });
}
