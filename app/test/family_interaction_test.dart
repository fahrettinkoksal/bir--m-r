import 'dart:math';

import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/interaction/family_interactions.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/interaction.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_flow.dart';

/// Aşama 2 kabulü: tekrar eden aynı etkinlik sonsuza kadar kazandırmaz,
/// ret ve kabul yolları çalışır, farklı kişilerin sayaçları karışmaz ve
/// **genel bir etkileşim kotası yoktur**.
void main() {
  /// Etkileşimlerin açık olduğu bir yaşa gelmiş, sabit tohumlu hayat.
  GameController livingController({int seed = 5, int age = 8}) {
    final GameController controller = GameController(random: Random(seed));
    controller.startNewLife(mode: StartMode.tamamenRastgele, seed: seed);
    advanceToAge(controller, age);
    return controller;
  }

  Person motherOf(GameController c) => c.state!.people
      .firstWhere((Person p) => p.relation == RelationType.anne);

  group('Uygunluk', () {
    test('etkileşimler yaşa uygun olmadan açılmaz', () {
      final GameController controller = GameController(random: Random(3));
      controller.startNewLife(mode: StartMode.tamamenRastgele, seed: 3);
      expect(controller.state!.player.age, 0);

      final Person anne = motherOf(controller);
      expect(controller.availabilityFor(anne).isAllowed, isFalse);

      // Uygun değilken çağrılırsa durum değişmez.
      final GameState before = controller.state!;
      final InteractionOutcome? outcome =
          controller.interact(anne.id, InteractionKind.vakitGecir);
      expect(outcome!.accepted, isFalse);
      expect(outcome.hasAnyEffect, isFalse);
      expect(controller.state!.people.first.bond, before.people.first.bond);
      expect(controller.state!.log.length, before.log.length);
    });

    test('vefat etmiş kişiyle etkileşim açılmaz', () {
      // Vefat etmiş bir yakını olan bir hayat bul.
      GameController? controller;
      Person? olen;
      for (int seed = 0; seed < 200 && controller == null; seed++) {
        final GameController candidate = livingController(seed: seed);
        for (final Person p in candidate.state!.people) {
          if (!p.isAlive) {
            controller = candidate;
            olen = p;
            break;
          }
        }
      }
      expect(controller, isNotNull, reason: 'Vefat etmiş kişi içeren örnek bulunmalı');
      expect(controller!.availabilityFor(olen!).isAllowed, isFalse);

      final int logBefore = controller.state!.log.length;
      final InteractionOutcome? outcome =
          controller.interact(olen.id, InteractionKind.vakitGecir);
      expect(outcome!.accepted, isFalse);
      expect(controller.state!.log.length, logBefore,
          reason: 'Yapılamayan etkileşim günlüğe yazılmaz');
    });

    test('hayatta olan ve yaşı uygun kişide etkileşim açıktır', () {
      final GameController controller = livingController();
      expect(controller.availabilityFor(motherOf(controller)).isAllowed, isTrue);
    });
  });

  group('Azalan etki (D-019, D-026)', () {
    test('aynı kişiyle aynı etkinliğin getirisi azalır ve sıfıra iner', () {
      // Reti devre dışı bırakmak için doğrudan motoru kullan: rastgelelik
      // yerine sabit bir akış istiyoruz.
      const FamilyInteractions engine = FamilyInteractions();
      GameState state = LifeGenerator.seeded(5)
          .generate(mode: StartMode.tamamenRastgele);
      // Yaşı uygun hâle getir.
      for (int i = 0; i < 10; i++) {
        state = state.copyWith(player: state.player.copyWith(age: i + 1));
      }
      final Person anne =
          state.people.firstWhere((Person p) => p.relation == RelationType.anne);

      final List<int> bondGains = <int>[];
      // nextDouble() hep 1.0'a yakın olsun ki ret yolu hiç seçilmesin.
      final Random noRefusal = _FixedRandom(doubleValue: 0.999);
      for (int i = 0; i < 5; i++) {
        final InteractionResult result = engine.perform(
          state: state,
          personId: anne.id,
          kind: InteractionKind.vakitGecir,
          rng: noRefusal,
        );
        state = result.state;
        expect(result.outcome.accepted, isTrue);
        bondGains.add(result.outcome.bondDelta);
      }

      expect(bondGains.first, greaterThan(0));
      for (int i = 1; i < bondGains.length; i++) {
        expect(bondGains[i], lessThanOrEqualTo(bondGains[i - 1]),
            reason: 'Getiri artmamalı: $bondGains');
      }
      expect(bondGains.last, 0, reason: 'Aynı yaşta ek fayda sıfıra inmeli');
      expect(bondGains.where((int g) => g == 0).length, greaterThanOrEqualTo(2));
    });

    test('fayda bittikten sonra etkinlik kilitlenmez, sonuç yine gelir', () {
      const FamilyInteractions engine = FamilyInteractions();
      GameState state = LifeGenerator.seeded(8)
          .generate(mode: StartMode.tamamenRastgele)
          .copyWith();
      state = state.copyWith(player: state.player.copyWith(age: 10));
      final Person anne =
          state.people.firstWhere((Person p) => p.relation == RelationType.anne);
      final Random noRefusal = _FixedRandom(doubleValue: 0.999);

      for (int i = 0; i < 6; i++) {
        final InteractionResult r = engine.perform(
          state: state,
          personId: anne.id,
          kind: InteractionKind.vakitGecir,
          rng: noRefusal,
        );
        state = r.state;
        expect(r.outcome.accepted, isTrue,
            reason: 'Etkinlik kapanmamalı, yalnızca getirisi bitmeli');
        expect(r.outcome.text, isNotEmpty);
      }
      final InteractionOutcome son = engine
          .perform(
            state: state,
            personId: anne.id,
            kind: InteractionKind.vakitGecir,
            rng: noRefusal,
          )
          .outcome;
      expect(son.noNewBenefit, isTrue);
      expect(son.hasAnyEffect, isFalse);
    });

    test('bir kişinin sayacı başka kişiyi kilitlemez', () {
      const FamilyInteractions engine = FamilyInteractions();
      GameState state = LifeGenerator.seeded(5)
          .generate(mode: StartMode.tamamenRastgele);
      state = state.copyWith(player: state.player.copyWith(age: 10));
      final Person anne =
          state.people.firstWhere((Person p) => p.relation == RelationType.anne);
      final Person baba =
          state.people.firstWhere((Person p) => p.relation == RelationType.baba);
      final Random noRefusal = _FixedRandom(doubleValue: 0.999);

      for (int i = 0; i < 5; i++) {
        state = engine
            .perform(
              state: state,
              personId: anne.id,
              kind: InteractionKind.vakitGecir,
              rng: noRefusal,
            )
            .state;
      }
      expect(state.interactionCount(anne.id, InteractionKind.vakitGecir.name),
          greaterThanOrEqualTo(4));
      expect(state.interactionCount(baba.id, InteractionKind.vakitGecir.name), 0);

      final InteractionOutcome babaIlk = engine
          .perform(
            state: state,
            personId: baba.id,
            kind: InteractionKind.vakitGecir,
            rng: noRefusal,
          )
          .outcome;
      expect(babaIlk.bondDelta, greaterThan(0),
          reason: 'Babayla ilk etkileşim tam fayda vermeli');
    });

    test('bir etkinliğin bitmesi diğer etkinliği kapatmaz', () {
      const FamilyInteractions engine = FamilyInteractions();
      GameState state = LifeGenerator.seeded(11)
          .generate(mode: StartMode.tamamenRastgele);
      state = state.copyWith(player: state.player.copyWith(age: 12));
      final Person anne =
          state.people.firstWhere((Person p) => p.relation == RelationType.anne);
      final Random noRefusal = _FixedRandom(doubleValue: 0.999);

      for (int i = 0; i < 5; i++) {
        state = engine
            .perform(
              state: state,
              personId: anne.id,
              kind: InteractionKind.vakitGecir,
              rng: noRefusal,
            )
            .state;
      }
      final InteractionOutcome sohbet = engine
          .perform(
            state: state,
            personId: anne.id,
            kind: InteractionKind.sohbet,
            rng: noRefusal,
          )
          .outcome;
      expect(sohbet.accepted, isTrue);
      expect(sohbet.bondDelta, greaterThan(0),
          reason: 'Farklı etkinlik küresel olarak kilitlenmemeli');
    });

    test('yaş alınca aynı etkinlik yeniden fayda verir', () {
      final GameController controller = livingController(seed: 5, age: 8);
      final Person anne = motherOf(controller);
      for (int i = 0; i < 6; i++) {
        resolvePendingEvents(controller);
        controller.interact(anne.id, InteractionKind.vakitGecir);
      }
      resolvePendingEvents(controller);
      expect(
        controller.state!.interactionCount(anne.id, InteractionKind.vakitGecir.name),
        greaterThan(0),
      );

      // Lise alanı seçilmeden yaş atlanmaz (D-094).
      resolveEducationChoices(controller);
      controller.ageUp();
      resolvePendingEvents(controller);
      expect(controller.state!.interactionCounts, isEmpty,
          reason: 'Tekrar sayaçları yaşa aittir');

      const FamilyInteractions engine = FamilyInteractions();
      final InteractionOutcome yeniYas = engine
          .perform(
            state: controller.state!,
            personId: anne.id,
            kind: InteractionKind.vakitGecir,
            rng: _FixedRandom(doubleValue: 0.999),
          )
          .outcome;
      expect(yeniYas.bondDelta, greaterThan(0));
    });

    test('yakınlık 100 üstüne çıkmaz', () {
      final GameController controller = livingController(seed: 5, age: 6);
      final Person anne = motherOf(controller);
      for (int yas = 0; yas < 40; yas++) {
        for (int i = 0; i < 4; i++) {
          resolvePendingEvents(controller);
          controller.interact(anne.id, InteractionKind.vakitGecir);
          resolvePendingEvents(controller);
          controller.interact(anne.id, InteractionKind.sohbet);
        }
        resolvePendingEvents(controller);
        // Lise alanı seçilmeden yaş atlanmaz (D-094).
        resolveEducationChoices(controller);
        controller.ageUp();
      }
      resolvePendingEvents(controller);
      final Person son = controller.state!.personById(anne.id)!;
      expect(son.bond, lessThanOrEqualTo(100));
      expect(controller.state!.player.stats.happiness, lessThanOrEqualTo(100));
      expect(controller.state!.player.stats.charisma, lessThanOrEqualTo(100));
    });
  });

  group('Doğal ret (D-020)', () {
    test('ilk istek asla reddedilmez', () {
      const FamilyInteractions engine = FamilyInteractions();
      for (int seed = 0; seed < 80; seed++) {
        GameState state =
            LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
        state = state.copyWith(player: state.player.copyWith(age: 9));
        final Person anne = state.people
            .firstWhere((Person p) => p.relation == RelationType.anne);
        if (!anne.isAlive) continue;
        final InteractionOutcome outcome = engine
            .perform(
              state: state,
              personId: anne.id,
              kind: InteractionKind.vakitGecir,
              rng: Random(seed),
            )
            .outcome;
        expect(outcome.accepted, isTrue);
      }
    });

    test('yakın tekrarda hem kabul hem ret yolu görülebilir', () {
      int ret = 0;
      int kabul = 0;
      const FamilyInteractions engine = FamilyInteractions();

      for (int seed = 0; seed < 150; seed++) {
        GameState state =
            LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
        state = state.copyWith(player: state.player.copyWith(age: 9));
        final Person anne = state.people
            .firstWhere((Person p) => p.relation == RelationType.anne);
        if (!anne.isAlive) continue;
        final Random rng = Random(seed + 1000);

        // İlk istek kabul edilir; hemen ardından tekrar istenir.
        state = engine
            .perform(
              state: state,
              personId: anne.id,
              kind: InteractionKind.vakitGecir,
              rng: rng,
            )
            .state;
        final InteractionOutcome ikinci = engine
            .perform(
              state: state,
              personId: anne.id,
              kind: InteractionKind.vakitGecir,
              rng: rng,
            )
            .outcome;
        if (ikinci.accepted) {
          kabul++;
        } else {
          ret++;
        }
      }
      expect(ret, greaterThan(0), reason: 'Ret yolu çalışmalı');
      expect(kabul, greaterThan(0), reason: 'Ret zorunlu değildir');
    });

    test('ret her seferinde mutluluk cezası getirmez', () {
      int cezali = 0;
      int cezasiz = 0;
      const FamilyInteractions engine = FamilyInteractions();

      for (int seed = 0; seed < 400; seed++) {
        GameState state =
            LifeGenerator.seeded(seed % 120).generate(mode: StartMode.tamamenRastgele);
        state = state.copyWith(player: state.player.copyWith(age: 9));
        final Person anne = state.people
            .firstWhere((Person p) => p.relation == RelationType.anne);
        if (!anne.isAlive) continue;
        final Random rng = Random(seed * 31 + 7);

        state = engine
            .perform(
              state: state,
              personId: anne.id,
              kind: InteractionKind.vakitGecir,
              rng: rng,
            )
            .state;
        for (int i = 0; i < 3; i++) {
          final InteractionOutcome o = engine
              .perform(
                state: state,
                personId: anne.id,
                kind: InteractionKind.vakitGecir,
                rng: rng,
              )
              .outcome;
          if (!o.accepted) {
            if (o.happinessDelta < 0) {
              cezali++;
            } else {
              cezasiz++;
            }
          }
        }
      }
      expect(cezali, greaterThan(0), reason: 'Ret bazen mutluluğu düşürebilir');
      expect(cezasiz, greaterThan(0), reason: 'Her ret ceza değildir');
    });

    test('ret sayacı artırmaz', () {
      const FamilyInteractions engine = FamilyInteractions();
      GameState state =
          LifeGenerator.seeded(4).generate(mode: StartMode.tamamenRastgele);
      state = state.copyWith(player: state.player.copyWith(age: 9));
      final Person anne =
          state.people.firstWhere((Person p) => p.relation == RelationType.anne);

      // Her zaman ret: nextDouble() hep 0.0.
      final Random alwaysRefuse = _FixedRandom(doubleValue: 0.0);
      state = engine
          .perform(
            state: state,
            personId: anne.id,
            kind: InteractionKind.vakitGecir,
            rng: _FixedRandom(doubleValue: 0.999),
          )
          .state;
      final int oncesi =
          state.interactionCount(anne.id, InteractionKind.vakitGecir.name);

      for (int i = 0; i < 4; i++) {
        final InteractionResult r = engine.perform(
          state: state,
          personId: anne.id,
          kind: InteractionKind.vakitGecir,
          rng: alwaysRefuse,
        );
        state = r.state;
        expect(r.outcome.accepted, isFalse);
      }
      expect(state.interactionCount(anne.id, InteractionKind.vakitGecir.name),
          oncesi);
    });
  });

  group('Hayat günlüğü', () {
    test('yalnızca anlamlı sonuçlar günlüğe yazılır', () {
      final GameController controller = livingController(seed: 5, age: 8);
      final Person anne = motherOf(controller);

      resolvePendingEvents(controller);
      int onceki = controller.state!.log.length;
      final InteractionOutcome ilk =
          controller.interact(anne.id, InteractionKind.vakitGecir)!;
      expect(ilk.accepted, isTrue);
      expect(controller.state!.log.length, onceki + 1);

      // Faydası bitene kadar tekrarla; sıfır kazançlı tekrar günlüğe yazılmaz.
      for (int i = 0; i < 12; i++) {
        resolvePendingEvents(controller);
        onceki = controller.state!.log.length;
        final InteractionOutcome o =
            controller.interact(anne.id, InteractionKind.vakitGecir)!;
        // Etkileşim bir ek olay tetiklediyse günlük sayımını bozmasın diye
        // olay çözülmeden bakılır.
        final int simdiki = controller.state!.log.length;
        if (o.worthLogging) {
          expect(simdiki, onceki + 1);
        } else {
          expect(simdiki, onceki,
              reason: 'Sıfır kazançlı tekrar günlüğü şişirmemeli');
        }
      }
    });

    test('etkileşim sonucu kişi kimliğini bozmaz', () {
      final GameController controller = livingController(seed: 5, age: 8);
      final List<String> ids =
          controller.state!.people.map((Person p) => p.id).toList();
      final Person anne = motherOf(controller);
      for (int i = 0; i < 6; i++) {
        resolvePendingEvents(controller);
        controller.interact(anne.id, InteractionKind.vakitGecir);
        resolvePendingEvents(controller);
        controller.interact(anne.id, InteractionKind.sohbet);
      }
      resolvePendingEvents(controller);
      expect(controller.state!.people.map((Person p) => p.id).toList(), ids);
      expect(controller.state!.personById(anne.id)!.relation, RelationType.anne);
    });
  });
}

/// Testlerde ret/kabul yolunu kesin seçebilmek için sabit değerli Random.
class _FixedRandom implements Random {
  _FixedRandom({required this.doubleValue});

  final double doubleValue;
  final Random _inner = Random(1);

  @override
  bool nextBool() => _inner.nextBool();

  @override
  double nextDouble() => doubleValue;

  @override
  int nextInt(int max) => _inner.nextInt(max);
}
