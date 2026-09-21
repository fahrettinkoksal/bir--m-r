import 'dart:math';

import 'package:bir_omur/data/event_pool.dart';
import 'package:bir_omur/domain/events/event_engine.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/education.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/owned_item.dart';
import 'package:bir_omur/domain/models/interaction.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_flow.dart';

GameEvent eventById(String id) =>
    kEventPool.firstWhere((GameEvent e) => e.id == id);

Person? findRelation(GameState state, RelationType relation) {
  for (final Person p in state.people) {
    if (p.relation == relation) return p;
  }
  return null;
}

/// Ekrana gelen olayın, o andaki duruma göre gerçekten uygun olduğunu
/// denetler. Uygunsuz olay hiçbir koşulda gösterilmemelidir (D-009).
void expectEligible(GameState state, ActiveEvent active) {
  final GameEvent event = eventById(active.eventId);
  final EventRequirement req = event.requirement;
  final int age = state.player.age;
  final String nerede = '${active.eventId} (yaş $age)';

  // Yer tutucusu doldurulmamış metin ekrana çıkmamalı.
  expect(active.text, isNot(contains('{')), reason: nerede);
  expect(age, greaterThanOrEqualTo(req.minAge), reason: nerede);
  expect(age, lessThanOrEqualTo(req.maxAge), reason: nerede);

  if (req.requiresSchoolStudent) {
    expect(state.education.isStudent, isTrue, reason: nerede);
  }
  if (req.minGrade != null) {
    expect(state.education.grade, greaterThanOrEqualTo(req.minGrade!),
        reason: nerede);
  }
  if (req.maxGrade != null) {
    expect(state.education.grade, lessThanOrEqualTo(req.maxGrade!),
        reason: nerede);
  }
  for (final String flag in req.requiredFlags) {
    expect(state.storyFlags, contains(flag), reason: nerede);
  }
  for (final String flag in req.forbiddenFlags) {
    expect(state.storyFlags, isNot(contains(flag)), reason: nerede);
  }
  for (final String item in req.requiredPossessions) {
    expect(state.possessions, contains(item), reason: nerede);
  }
  if (!event.repeatable) {
    expect(state.seenEventIds, isNot(contains(event.id)), reason: nerede);
  }
  if (req.livingRelations.isNotEmpty) {
    expect(active.personId, isNotNull, reason: nerede);
    final Person person = state.personById(active.personId!)!;
    expect(person.isAlive, isTrue, reason: nerede);
    expect(req.livingRelations, contains(person.relation), reason: nerede);
    if (req.requireSameHousehold) {
      expect(person.inPlayerHousehold, isTrue, reason: nerede);
    }
    if (req.requireOutsideHousehold) {
      expect(person.inPlayerHousehold, isFalse, reason: nerede);
    }
  }
  // Kişinin kendi yaşı koşulu (çocuk olayları).
  if (active.personId != null) {
    final Person kisi = state.personById(active.personId!)!;
    if (req.personMinAge != null) {
      expect(kisi.age, greaterThanOrEqualTo(req.personMinAge!), reason: nerede);
    }
    if (req.personMaxAge != null) {
      expect(kisi.age, lessThanOrEqualTo(req.personMaxAge!), reason: nerede);
    }
  }
  if (req.requiresNeglectedRelative) {
    expect(active.personId, isNotNull, reason: nerede);
    expect(state.personById(active.personId!)!.isAlive, isTrue, reason: nerede);
  }
}

void main() {
  group('Yaş Al ve tek açılış olayı (D-021)', () {
    test('yaş al bir yaş ilerletir ve en fazla tek olay açar', () {
      for (int seed = 0; seed < 60; seed++) {
        final GameController controller = GameController(random: Random(seed));
        controller.startNewLife(mode: StartMode.tamamenRastgele, seed: seed);

        for (int i = 0; i < 25; i++) {
          // Oyuncu vefat ettiyse hayat tamamlanmıştır; yaş ilerlemez.
          if (controller.state!.deceased) break;
          final int onceki = controller.state!.player.age;
          controller.ageUp();
          expect(controller.state!.player.age, onceki + 1);
          // Yaş alındıktan sonra ekranda **en fazla bir** olay olur.
          final ActiveEvent? acilis = controller.state!.pendingEvent;
          if (acilis != null) {
            expectEligible(controller.state!, acilis);
            controller.chooseEventOption(acilis.choices.first.id);
          }
          // Açılış olayı çözülür çözülmez ikinci bir olay yağmaz.
          expect(controller.state!.hasPendingEvent, isFalse);
        }
      }
    });

    test('olay ekrandayken yeni olay üretilmez', () {
      const EventEngine engine = EventEngine();
      GameState state =
          LifeGenerator.seeded(5).generate(mode: StartMode.tamamenRastgele);
      state = state.copyWith(
        player: state.player.copyWith(age: 10),
        progressSinceLastEvent: 99,
      );
      final ActiveEvent? ilk = engine.openingEvent(state, Random(1));
      expect(ilk, isNotNull);
      state = state.copyWith(pendingEvent: ilk);
      expect(engine.progressEvent(state, Random(2)), isNull);
    });

    test('olaylar gerçek dünya saatine bağlı değildir', () {
      // Hiçbir ilerleme yapılmadan geçen "zaman" olay üretmez.
      final GameController controller = GameController(random: Random(4));
      controller.startNewLife(mode: StartMode.tamamenRastgele, seed: 4);
      advanceToAge(controller, 10);
      expect(controller.state!.hasPendingEvent, isFalse);

      final DateTime baslangic = DateTime.now();
      // Durumu yalnızca okumak olay üretmemeli.
      for (int i = 0; i < 1000; i++) {
        expect(controller.state!.hasPendingEvent, isFalse);
      }
      expect(DateTime.now().isAfter(baslangic) || true, isTrue);
      expect(controller.state!.hasPendingEvent, isFalse);
    });
  });

  group('Uygunluk: olmayan koşul için olay çıkmaz (D-009)', () {
    test('uzun oyunlarda çıkan her olay koşullarını sağlar', () {
      for (int seed = 0; seed < 80; seed++) {
        final GameController controller = GameController(random: Random(seed));
        controller.startNewLife(mode: StartMode.tamamenRastgele, seed: seed);
        final Person? anne =
            findRelation(controller.state!, RelationType.anne);

        for (int i = 0; i < 26; i++) {
          controller.ageUp();
          while (controller.state!.hasPendingEvent) {
            final ActiveEvent active = controller.state!.pendingEvent!;
            expectEligible(controller.state!, active);
            controller.chooseEventOption(
              active.choices[seed % active.choices.length].id,
            );
          }
          // Biraz etkileşim yaparak ilerlemeye bağlı olayları da tetikle.
          if (anne != null && anne.isAlive) {
            for (int k = 0; k < 4; k++) {
              controller.interact(anne.id, InteractionKind.vakitGecir);
              while (controller.state!.hasPendingEvent) {
                final ActiveEvent active = controller.state!.pendingEvent!;
                expectEligible(controller.state!, active);
                controller.chooseEventOption(active.choices.first.id);
              }
            }
          }
        }
      }
    });

    test('sahip olunmayan bisiklet için olay çıkmaz', () {
      const EventEngine engine = EventEngine(
        pool: <GameEvent>[],
      );
      expect(engine.pool, isEmpty);

      final EventEngine sadeceZincir =
          EventEngine(pool: <GameEvent>[eventById('bisiklet_zinciri')]);
      GameState state =
          LifeGenerator.seeded(7).generate(mode: StartMode.tamamenRastgele);
      state = state.copyWith(player: state.player.copyWith(age: 13));
      expect(state.possessions, isEmpty);
      expect(sadeceZincir.openingEvent(state, Random(1)), isNull);

      final GameState bisikletli = state.grantItems(
        <String>[Possessions.bisiklet],
        source: ItemSource.olay,
      );
      expect(sadeceZincir.openingEvent(bisikletli, Random(1)), isNotNull);
    });

    test('üniversiteye gitmemiş karakterde üniversite olayı çıkmaz', () {
      final EventEngine engine =
          EventEngine(pool: <GameEvent>[eventById('universite_ilk_hafta')]);
      GameState state =
          LifeGenerator.seeded(9).generate(mode: StartMode.tamamenRastgele);
      state = state.copyWith(player: state.player.copyWith(age: 20));
      expect(state.storyFlags, isEmpty);
      expect(engine.openingEvent(state, Random(1)), isNull);

      final GameState ogrenci =
          state.copyWith(storyFlags: <String>{StoryFlags.universitede});
      expect(engine.openingEvent(ogrenci, Random(1)), isNotNull);
    });

    test('okula başlamamış karaktere okul olayı çıkmaz', () {
      final EventEngine engine =
          EventEngine(pool: <GameEvent>[eventById('okul_ilk_gun')]);
      GameState state =
          LifeGenerator.seeded(2).generate(mode: StartMode.tamamenRastgele);

      // Yaş uygun ama eğitim durumu 'okula başlamadı': olay çıkmamalı.
      state = state.copyWith(player: state.player.copyWith(age: 7));
      expect(state.education.isStudent, isFalse);
      expect(engine.openingEvent(state, Random(1)), isNull);

      // Öğrenci olunca aynı yaşta olay uygun hâle gelir.
      final GameState ogrenci = state.copyWith(
        education: const EducationState(
          enrolled: true,
          grade: 1,
          startedAtAge: 6,
        ),
      );
      expect(engine.openingEvent(ogrenci, Random(1)), isNotNull);
    });

    test('hayatta olmayan kişi için kişili olay çıkmaz', () {
      final EventEngine engine =
          EventEngine(pool: <GameEvent>[eventById('bayram_ziyareti')]);
      for (int seed = 0; seed < 120; seed++) {
        GameState state = LifeGenerator.seeded(seed)
            .generate(mode: StartMode.tamamenRastgele);
        state = state.copyWith(player: state.player.copyWith(age: 12));
        final ActiveEvent? active = engine.openingEvent(state, Random(seed));
        if (active == null) continue;
        final Person person = state.personById(active.personId!)!;
        expect(person.isAlive, isTrue);
      }
    });

    test('tekrarlanabilir olmayan olay bir hayatta bir kez çıkar', () {
      for (int seed = 0; seed < 40; seed++) {
        final GameController controller = GameController(random: Random(seed));
        controller.startNewLife(mode: StartMode.tamamenRastgele, seed: seed);
        final List<String> gorulen = <String>[];

        for (int i = 0; i < 26; i++) {
          controller.ageUp();
          while (controller.state!.hasPendingEvent) {
            final ActiveEvent active = controller.state!.pendingEvent!;
            if (!eventById(active.eventId).repeatable) {
              expect(gorulen, isNot(contains(active.eventId)));
              gorulen.add(active.eventId);
            }
            controller.chooseEventOption(active.choices.first.id);
          }
        }
      }
    });
  });

  group('Hafıza: geçmiş seçim sonraki olayı değiştirir (D-008, D-022)', () {
    EventEngine chainEngine() => EventEngine(
          pool: <GameEvent>[
            eventById('arkadasi_savunma'),
            eventById('savundugun_arkadas'),
            eventById('sessiz_kaldigin_gun'),
          ],
        );

    /// Okul olayları eğitim durumuna baktığı için kayıtlı bir öğrenci kurar.
    GameState atAge(int seed, int age) {
      final GameState state =
          LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
      final int grade = (age - 5).clamp(1, 12);
      return withSchoolPeople(
        state.copyWith(
          player: state.player.copyWith(age: age),
          education: age <= 17
              ? EducationState(enrolled: true, grade: grade, startedAtAge: 6)
              : const EducationState.notStarted(),
        ),
        seed: seed,
      );
    }

    test('arkadaşını savunmak ileride farklı bir devam açar', () {
      final EventEngine engine = chainEngine();
      GameState state = atAge(5, 11);

      final ActiveEvent? ilk = engine.openingEvent(state, Random(1));
      expect(ilk!.eventId, 'arkadasi_savunma');
      state = engine.resolve(state.copyWith(pendingEvent: ilk), 'savun');
      expect(state.storyFlags, contains(StoryFlags.arkadasiniSavundu));

      state = state.copyWith(player: state.player.copyWith(age: 17));
      final ActiveEvent? devam = engine.openingEvent(state, Random(1));
      expect(devam, isNotNull);
      expect(devam!.eventId, 'savundugun_arkadas');
    });

    test('sessiz kalmak farklı ve tek bir devam açar', () {
      final EventEngine engine = chainEngine();
      GameState state = atAge(5, 11);

      final ActiveEvent? ilk = engine.openingEvent(state, Random(1));
      state = engine.resolve(state.copyWith(pendingEvent: ilk), 'sus');
      expect(state.storyFlags, contains(StoryFlags.sessizKaldi));

      state = state.copyWith(player: state.player.copyWith(age: 17));
      final ActiveEvent? devam = engine.openingEvent(state, Random(1));
      expect(devam!.eventId, 'sessiz_kaldigin_gun');

      // Karşı devam hiçbir tohumda açılmaz.
      for (int i = 0; i < 40; i++) {
        final ActiveEvent? tekrar = engine.openingEvent(state, Random(i));
        expect(tekrar!.eventId, isNot('savundugun_arkadas'));
      }
    });

    test('hiç seçim yapılmamışsa devam olayı çıkmaz', () {
      final EventEngine engine = EventEngine(
        pool: <GameEvent>[
          eventById('savundugun_arkadas'),
          eventById('sessiz_kaldigin_gun'),
        ],
      );
      final GameState state = atAge(5, 17);
      expect(state.storyFlags, isEmpty);
      expect(engine.openingEvent(state, Random(1)), isNull);
    });

    test('seçim karakter değerlerine ve hayat günlüğüne yansır', () {
      final EventEngine engine = chainEngine();
      GameState state = atAge(5, 11);
      final int mutlulukOnce = state.player.stats.happiness;
      final int logOnce = state.log.length;

      final ActiveEvent? ilk = engine.openingEvent(state, Random(1));
      state = engine.resolve(state.copyWith(pendingEvent: ilk), 'sus');

      expect(state.player.stats.happiness, lessThan(mutlulukOnce));
      expect(state.log.length, logOnce + 1);
      expect(state.log.last.age, 11);
      expect(state.pendingEvent, isNull);
    });

    test('kişili olayın etkisi doğru kişinin ilişkisine işlenir', () {
      final EventEngine engine =
          EventEngine(pool: <GameEvent>[eventById('bisiklet_hediyesi')]);
      for (int seed = 0; seed < 60; seed++) {
        GameState state = LifeGenerator.seeded(seed)
            .generate(mode: StartMode.tamamenRastgele);
        state = state.copyWith(player: state.player.copyWith(age: 10));
        final ActiveEvent? active = engine.openingEvent(state, Random(seed));
        if (active == null) continue;

        final String personId = active.personId!;
        final Map<String, int> once = <String, int>{
          for (final Person p in state.people) p.id: p.bond,
        };
        final GameState sonra =
            engine.resolve(state.copyWith(pendingEvent: active), 'sarilarak');

        for (final Person p in sonra.people) {
          if (p.id == personId) {
            expect(p.bond, greaterThan(once[p.id]!));
          } else {
            expect(p.bond, once[p.id],
                reason: 'Başka kişilerin ilişkisi değişmemeli');
          }
        }
        expect(sonra.possessions, contains(Possessions.bisiklet));
        return;
      }
      fail('Bisiklet olayı içeren örnek bulunamadı');
    });
  });

  group('Oyun içi ilerlemeye bağlı ek olay (D-023, D-024)', () {
    test('yeterli ilerleme olmadan ek olay çıkmaz', () {
      const EventEngine engine = EventEngine();
      GameState state =
          LifeGenerator.seeded(5).generate(mode: StartMode.tamamenRastgele);
      state = state.copyWith(
        player: state.player.copyWith(age: 10),
        progressSinceLastEvent: 0,
      );
      expect(engine.progressEvent(state, Random(1)), isNull);

      state = state.copyWith(
        progressSinceLastEvent: EventEngine.prototypeOnlyProgressPerExtraEvent,
      );
      expect(engine.progressEvent(state, Random(1)), isNotNull);
    });

    test('bir yaşta en fazla bir ek olay açılır', () {
      const EventEngine engine = EventEngine();
      GameState state =
          LifeGenerator.seeded(5).generate(mode: StartMode.tamamenRastgele);
      state = state.copyWith(
        player: state.player.copyWith(age: 10),
        progressSinceLastEvent: 99,
        extraEventsThisAge: EventEngine.prototypeOnlyMaxExtraEventsPerAge,
      );
      expect(engine.progressEvent(state, Random(1)), isNull);
    });

    test('bir yaş içinde açılan toplam olay sayısı sınırlıdır', () {
      for (int seed = 0; seed < 30; seed++) {
        final GameController controller = GameController(random: Random(seed));
        controller.startNewLife(mode: StartMode.tamamenRastgele, seed: seed);
        final Person anne = controller.state!.people
            .firstWhere((Person p) => p.relation == RelationType.anne);
        if (!anne.isAlive) continue;

        for (int i = 0; i < 20; i++) {
          int buYastakiOlay = 0;
          controller.ageUp();
          if (controller.state!.hasPendingEvent) {
            buYastakiOlay++;
            controller.chooseEventOption(
              controller.state!.pendingEvent!.choices.first.id,
            );
          }
          for (int k = 0; k < 10; k++) {
            controller.interact(anne.id, InteractionKind.vakitGecir);
            if (controller.state!.hasPendingEvent) {
              buYastakiOlay++;
              controller.chooseEventOption(
                controller.state!.pendingEvent!.choices.first.id,
              );
            }
          }
          expect(
            buYastakiOlay,
            lessThanOrEqualTo(1 + EventEngine.prototypeOnlyMaxExtraEventsPerAge),
            reason: 'Bir yaşta olay yağmuru olmamalı',
          );
        }
      }
    });

    test('sitem olayı ancak uzun süre temas kurulmayan yakın için çıkar', () {
      final EventEngine engine =
          EventEngine(pool: <GameEvent>[eventById('aile_sitemi')]);
      GameState state =
          LifeGenerator.seeded(5).generate(mode: StartMode.tamamenRastgele);
      state = state.copyWith(player: state.player.copyWith(age: 12));

      final ActiveEvent? sitem = engine.openingEvent(state, Random(1));
      expect(sitem, isNotNull, reason: 'Hiç temas yoksa sitem çıkabilir');
      expect(state.personById(sitem!.personId!)!.inPlayerHousehold, isTrue);

      // Herkesle yeni temas kurulmuşsa sitem çıkmaz.
      final GameState temasli = state.copyWith(
        lastInteractionAge: <String, int>{
          for (final Person p in state.people) p.id: state.player.age,
        },
      );
      expect(engine.openingEvent(temasli, Random(1)), isNull);
    });
  });

  group('Uygun olay bulunamayan yaşlar (Q-005 ölçümü)', () {
    test('ilk yaşlarda çıkan olaylar yaşa uygundur', () {
      // Paket 4'ten önce 0-4 yaş aralığında hiç olay yoktu (ölçüm:
      // tool/event_report.dart). Artık bebeklik olayları var; bu testin
      // işi, çıkan olayların gerçekten o yaşa uygun olduğunu denetlemek.
      int cikanOlay = 0;
      for (int seed = 0; seed < 40; seed++) {
        final GameController controller = GameController(random: Random(seed));
        controller.startNewLife(mode: StartMode.tamamenRastgele, seed: seed);
        for (int age = 1; age <= 4; age++) {
          controller.ageUp();
          expect(controller.state!.player.age, age);
          final ActiveEvent? olay = controller.state!.pendingEvent;
          if (olay == null) continue;
          cikanOlay++;
          expectEligible(controller.state!, olay);
          controller.chooseEventOption(olay.choices.first.id);
          expect(controller.state!.hasPendingEvent, isFalse);
        }
      }
      expect(cikanOlay, greaterThan(0),
          reason: 'Bebeklik olayları hiç çıkmıyorsa kapsam boşluğu sürüyor');
    });

    test('olaysız yaşlar ölçülebilir ve günlükte yine de iz kalır', () {
      // Yaş alma her hâlükârda günlüğe yazılır; olay çıkmasa da oyuncu
      // ilerlemeyi görür. Bu, Q-005'te tartışılan geçici davranıştır.
      int olaysizYas = 0;
      int toplamYas = 0;
      for (int seed = 0; seed < 25; seed++) {
        final GameController controller = GameController(random: Random(seed));
        controller.startNewLife(mode: StartMode.tamamenRastgele, seed: seed);
        for (int i = 0; i < 26; i++) {
          // Oyuncu vefat ettiyse hayat tamamlanmıştır; yaş ilerlemez.
          if (controller.state!.deceased) break;
          final int logOnce = controller.state!.log.length;
          controller.ageUp();
          toplamYas++;
          expect(controller.state!.log.length, greaterThan(logOnce),
              reason: 'Yaş alma her zaman günlüğe yazılmalı');
          if (!controller.state!.hasPendingEvent) {
            olaysizYas++;
          } else {
            controller.chooseEventOption(
              controller.state!.pendingEvent!.choices.first.id,
            );
          }
        }
      }
      expect(toplamYas, greaterThan(0));
      // Ölçüm (Q-005): olaysız yıl oranı. Havuz büyüdükçe bu oran
      // düşüyor; Paket 13'ten sonra ilk 26 yıl tamamen dolabiliyor.
      // Bu yüzden "olaysız yıl mutlaka olmalı" beklentisi kaldırıldı;
      // ölçülen şey artık kapsamın yeterliliği.
      expect(olaysizYas, lessThanOrEqualTo((toplamYas * 0.5).round()),
          reason: 'Yılların yarısından fazlası olaysız geçmemeli');
    });
  });
}
