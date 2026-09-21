import 'dart:math';

import 'package:bir_omur/data/activity_catalog.dart';
import 'package:bir_omur/domain/activities/activity_engine.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/interaction.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/invariants.dart';

/// Paket 18'de eklenen alanlar: Sağlık Merkezi, Eğlence, Kurslar.
const ActivityEngine activities = ActivityEngine();

GameState hayat({int age = 20, int wallet = 20000, int seed = 61}) {
  final GameState state =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  return state.copyWith(
    pendingEvent: null,
    player: state.player.copyWith(age: age, wallet: wallet),
  );
}

ActivityAction eylem(String id) => activityActionById(id)!;

const List<ActivityVenue> yeniMekanlar = <ActivityVenue>[
  ActivityVenue.saglikMerkezi,
  ActivityVenue.eglence,
  ActivityVenue.kurs,
];

void main() {
  // ===================================================================
  // Katalog
  // ===================================================================
  group('Katalog', () {
    test('eylem kimlikleri benzersiz', () {
      final Set<String> kimlikler = <String>{};
      for (final ActivityAction a in kActivityActions) {
        expect(kimlikler.add(a.id), isTrue, reason: 'Tekrar eden: ${a.id}');
      }
    });

    test('her yeni mekânda en az üç eylem var', () {
      for (final ActivityVenue v in yeniMekanlar) {
        expect(actionsAt(v).length, greaterThanOrEqualTo(3), reason: v.label);
      }
    });

    test('her eylemin ücreti, yaşı ve sınırı makul', () {
      for (final ActivityAction a in kActivityActions) {
        expect(a.cost, greaterThanOrEqualTo(0), reason: a.id);
        expect(a.minAge, greaterThanOrEqualTo(0), reason: a.id);
        expect(a.maxPerAge, greaterThanOrEqualTo(1), reason: a.id);
        expect(a.label.trim(), isNotEmpty, reason: a.id);
        expect(a.description.trim(), isNotEmpty, reason: a.id);
      }
    });

    test('her eylemin açıklaması özgün', () {
      final Set<String> metinler = <String>{};
      for (final ActivityAction a in kActivityActions) {
        expect(metinler.add(a.description), isTrue, reason: a.id);
      }
    });

    test('mekânın en küçük yaşı eylemlerinden okunur', () {
      for (final ActivityVenue v in ActivityVenue.values) {
        final List<ActivityAction> eylemler = actionsAt(v);
        if (eylemler.isEmpty) continue;
        final int beklenen = eylemler
            .map((ActivityAction a) => a.minAge)
            .reduce((int a, int b) => a < b ? a : b);
        expect(v.minAge, beklenen, reason: v.label);
      }
    });

    test('eğlence her yaşa açılmaz ama ücretsiz bir seçeneği var', () {
      final List<ActivityAction> eglence = actionsAt(ActivityVenue.eglence);
      expect(eglence.any((ActivityAction a) => a.cost == 0), isTrue);
      expect(ActivityVenue.eglence.minAge, greaterThan(0));
    });
  });

  // ===================================================================
  // Sağlık Merkezi
  // ===================================================================
  group('Sağlık Merkezi', () {
    test('kontrol ücreti düşer ve sağlık gerçekten artar', () {
      final GameState s = hayat(age: 30, wallet: 5000).copyWith(
        player: hayat(age: 30, wallet: 5000)
            .player
            .copyWith(stats: hayat().player.stats.copyWith(health: 50)),
      );
      final ActivityAction a = eylem('genel_kontrol');

      final ActivityResult r =
          activities.perform(state: s, action: a, rng: Random(1));

      expect(r.outcome.applied, isTrue);
      expect(r.state.player.wallet, 5000 - a.cost);
      expect(r.state.player.stats.health, greaterThan(50));
      expect(r.state.log.last.text, contains(a.label));
      checkInvariants(r.state);
    });

    test('parası yetmeyen işlem hiçbir şeyi değiştirmez', () {
      final GameState s = hayat(age: 30, wallet: 10);
      final ActivityAction a = eylem('ruh_sagligi');

      expect(activities.availability(s, a).isAllowed, isFalse);
      final ActivityResult r =
          activities.perform(state: s, action: a, rng: Random(1));

      expect(r.outcome.applied, isFalse);
      expect(r.state.player.wallet, 10);
      expect(r.state.player.stats, s.player.stats);
      expect(r.state.log.length, s.log.length);
    });

    test('yaşı tutmayan eylem kapalıdır', () {
      final GameState cocuk = hayat(age: 8);
      final InteractionAvailability uygunluk =
          activities.availability(cocuk, eylem('ruh_sagligi'));
      expect(uygunluk.isAllowed, isFalse);
      expect(uygunluk.reason, contains('12'));
    });
  });

  // ===================================================================
  // Eğlence
  // ===================================================================
  group('Eğlence', () {
    test('ücretsiz yürüyüş parasız oyuncuda da açıktır', () {
      final GameState s = hayat(age: 10, wallet: 0);
      final ActivityAction a = eylem('parkta_yuruyus');

      expect(a.cost, 0);
      expect(activities.availability(s, a).isAllowed, isTrue);

      final ActivityResult r =
          activities.perform(state: s, action: a, rng: Random(2));
      expect(r.outcome.applied, isTrue);
      expect(r.state.player.wallet, 0);
      checkInvariants(r.state);
    });

    test('yıllık sınır dolunca eylem kapanır', () {
      GameState s = hayat(age: 20, wallet: 20000);
      final ActivityAction a = eylem('konsere_git');

      for (int i = 0; i < a.maxPerAge; i++) {
        final ActivityResult r =
            activities.perform(state: s, action: a, rng: Random(3));
        expect(r.outcome.applied, isTrue, reason: '$i. deneme');
        s = r.state;
      }

      final InteractionAvailability uygunluk = activities.availability(s, a);
      expect(uygunluk.isAllowed, isFalse);
      expect(uygunluk.reason, contains('seneye'));
    });

    test('aynı yaşta tekrar edilen eylemin kazancı azalır', () {
      GameState s = hayat(age: 20, wallet: 20000).copyWith(
        player: hayat(age: 20, wallet: 20000)
            .player
            .copyWith(stats: hayat().player.stats.copyWith(happiness: 10)),
      );
      final ActivityAction a = eylem('sinema');

      final int once = s.player.stats.happiness;
      s = activities.perform(state: s, action: a, rng: Random(4)).state;
      final int ilkKazanc = s.player.stats.happiness - once;

      final int ikiOnce = s.player.stats.happiness;
      s = activities.perform(state: s, action: a, rng: Random(4)).state;
      final int ikinciKazanc = s.player.stats.happiness - ikiOnce;

      expect(ilkKazanc, greaterThan(0));
      expect(ikinciKazanc, lessThan(ilkKazanc));
    });

    test('mutluluk 100 iken sahte artış yazılmaz', () {
      final GameState tam = hayat(age: 20, wallet: 20000);
      final GameState s = tam.copyWith(
        player: tam.player.copyWith(
          stats: tam.player.stats.copyWith(happiness: 100),
        ),
      );
      final ActivityResult r = activities.perform(
        state: s,
        action: eylem('sinema'),
        rng: Random(5),
      );
      expect(r.state.player.stats.happiness, 100);
      expect(
        r.outcome.effects.where((dynamic e) => '$e'.contains('Mutluluk')),
        isEmpty,
      );
    });
  });

  // ===================================================================
  // Kurslar
  // ===================================================================
  group('Kurslar', () {
    test('dil kursu zekâyı gerçekten artırır', () {
      final GameState taban = hayat(age: 20, wallet: 20000);
      final GameState s = taban.copyWith(
        player: taban.player.copyWith(
          stats: taban.player.stats.copyWith(intelligence: 40),
        ),
      );
      final ActivityAction a = eylem('dil_kursu');
      expect(a.intelligence, greaterThan(0));

      final ActivityResult r =
          activities.perform(state: s, action: a, rng: Random(6));

      expect(r.state.player.stats.intelligence, 40 + a.intelligence);
      expect(r.state.player.wallet, 20000 - a.cost);
      checkInvariants(r.state);
    });

    test('zekâsı olmayan eylemler zekâya dokunmaz', () {
      final GameState taban = hayat(age: 20, wallet: 20000);
      final GameState s = taban.copyWith(
        player: taban.player.copyWith(
          stats: taban.player.stats.copyWith(intelligence: 40),
        ),
      );
      final ActivityResult r = activities.perform(
        state: s,
        action: eylem('kafede_otur'),
        rng: Random(7),
      );
      expect(r.state.player.stats.intelligence, 40);
    });

    test('yeni yaşta sayaç sıfırlanır, eylem yeniden açılır', () {
      GameState s = hayat(age: 20, wallet: 20000);
      final ActivityAction a = eylem('bilgisayar_kursu');

      for (int i = 0; i < a.maxPerAge; i++) {
        s = activities.perform(state: s, action: a, rng: Random(8)).state;
      }
      expect(activities.availability(s, a).isAllowed, isFalse);

      // Yaş alınca tekrar sayaçları sıfırlanır (D-023).
      s = s.copyWith(interactionCounts: const <String, int>{});
      expect(activities.availability(s, a).isAllowed, isTrue);
    });
  });

  // ===================================================================
  // Mekân listesi
  // ===================================================================
  group('Mekânda açık eylemler', () {
    test('yaşa uymayan eylem listeye girmez', () {
      final GameState cocuk = hayat(age: 6, wallet: 20000);
      final List<ActivityAction> acik =
          activities.availableActions(cocuk, ActivityVenue.kurs);

      expect(acik, isNotEmpty);
      for (final ActivityAction a in acik) {
        expect(a.minAge, lessThanOrEqualTo(6), reason: a.id);
      }
      expect(acik.any((ActivityAction a) => a.id == 'bilgisayar_kursu'), isFalse);
    });

    test('parası olmayan oyuncuya yalnızca ücretsiz eylem açık kalır', () {
      final GameState parasiz = hayat(age: 20, wallet: 0);
      final List<ActivityAction> acik =
          activities.availableActions(parasiz, ActivityVenue.eglence);

      expect(acik, isNotEmpty);
      for (final ActivityAction a in acik) {
        expect(a.cost, 0, reason: a.id);
      }
    });
  });
}
