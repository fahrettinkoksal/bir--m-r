import 'dart:math';

import 'package:bir_omur/data/activity_catalog.dart';
import 'package:bir_omur/data/event_pool.dart';
import 'package:bir_omur/data/event_pool_hobby.dart';
import 'package:bir_omur/data/hobby_catalog.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/domain/activities/activity_engine.dart';
import 'package:bir_omur/domain/events/event_engine.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/hobby/hobby_tracker.dart';
import 'package:bir_omur/domain/life/life_verdict.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/hobby_progress.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:flutter_test/flutter_test.dart';

const ActivityEngine motor = ActivityEngine();

GameState hayat({int age = 12, int wallet = 5000000}) {
  final GameState taban =
      LifeGenerator.seeded(4).generate(mode: StartMode.tamamenRastgele);
  return taban.copyWith(
    pendingEvent: null,
    notices: const <PendingNotice>[],
    player: taban.player.copyWith(age: age, wallet: wallet),
  );
}

ActivityAction eylem(String id) =>
    kActivityActions.firstWhere((ActivityAction a) => a.id == id);

/// Bir eylemi yıllara yayarak [kez] defa yapar (yıllık kota gerçektir).
GameState tekrarla(GameState state, String actionId, int kez) {
  GameState s = state;
  final ActivityAction a = eylem(actionId);
  for (int i = 0; i < kez; i++) {
    if (motor.timesDone(s, a) >= a.maxPerAge) {
      s = s.copyWith(
        player: s.player.copyWith(age: s.player.age + 1),
        interactionCounts: const <String, int>{},
      );
    }
    final ActivityResult r =
        motor.perform(state: s, action: a, rng: Random(i));
    expect(r.outcome.applied, isTrue, reason: r.outcome.text);
    s = r.state;
  }
  return s;
}

void main() {
  group('Hobi geçmişi mevcut aktivitelerden beslenir', () {
    test('müzik kursu müzik hobisini başlatır', () {
      final GameState s = tekrarla(hayat(), 'muzik_kursu', 1);
      final HobbyProgress? h = HobbyTracker.progressOf(s, HobbyKind.muzik);
      expect(h, isNotNull);
      expect(h!.startedAtAge, 12);
      expect(h.experience, 1);
      expect(h.lastPracticedAge, 12);
    });

    test('resim atölyesi resim hobisini besler', () {
      final GameState s = tekrarla(hayat(), 'resim_atolyesi', 3);
      expect(HobbyTracker.progressOf(s, HobbyKind.resim)!.experience, 3);
    });

    test('spor salonu eylemleri aynı spor hobisini besler', () {
      GameState s = tekrarla(hayat(age: 15), 'kosu', 2);
      s = tekrarla(s, 'agirlik', 2);
      expect(HobbyTracker.progressOf(s, HobbyKind.spor)!.experience, 4);
    });

    test('hobi beslemeyen eylem hiçbir şey yazmaz', () {
      final GameState s = tekrarla(hayat(age: 20), 'sac_kestir', 2);
      expect(s.hobbies, isEmpty);
    });

    test('başlama yaşı ilk uğraşta sabitlenir, sonra değişmez', () {
      GameState s = tekrarla(hayat(age: 10), 'muzik_kursu', 1);
      s = s.copyWith(
        player: s.player.copyWith(age: 25),
        interactionCounts: const <String, int>{},
      );
      s = tekrarla(s, 'muzik_kursu', 1);
      final HobbyProgress h = HobbyTracker.progressOf(s, HobbyKind.muzik)!;
      expect(h.startedAtAge, 10);
      expect(h.lastPracticedAge, 25);
      expect(h.years, 15);
    });

    test('yıllık kota aşılamaz: hobi sınırsız kasılamaz', () {
      // Aynı yaşta eylem kotası dolunca eylem kapanır; hobi de artmaz.
      GameState s = hayat(age: 14);
      final ActivityAction a = eylem('muzik_kursu');
      for (int i = 0; i < a.maxPerAge; i++) {
        s = motor.perform(state: s, action: a, rng: Random(i)).state;
      }
      final int once =
          HobbyTracker.progressOf(s, HobbyKind.muzik)!.experience;
      final ActivityResult r =
          motor.perform(state: s, action: a, rng: Random(99));
      expect(r.outcome.applied, isFalse);
      expect(
        HobbyTracker.progressOf(r.state, HobbyKind.muzik)!.experience,
        once,
      );
    });
  });

  group('Basamaklar ve anılar', () {
    test('basamak yükselince gerçek yaşla anı yazılır', () {
      final GameState s = tekrarla(hayat(age: 10), 'muzik_kursu', 8);
      final HobbyProgress h = HobbyTracker.progressOf(s, HobbyKind.muzik)!;
      expect(h.stage, greaterThan(0));
      expect(h.memories, isNotEmpty);
      for (final HobbyMemory m in h.memories) {
        expect(m.age, greaterThanOrEqualTo(10));
        expect(m.text, isNotEmpty);
      }
      // İlk anı başlangıç yaşını metne yazar.
      expect(h.memories.first.text, contains('10'));
    });

    test('her basamak için en fazla bir anı yazılır', () {
      final GameState s = tekrarla(hayat(age: 10), 'muzik_kursu', 30);
      final HobbyProgress h = HobbyTracker.progressOf(s, HobbyKind.muzik)!;
      expect(h.memories.length, h.stage + 1);
      expect(
        h.memories.map((HobbyMemory m) => m.text).toSet().length,
        h.memories.length,
        reason: 'Aynı anı iki kez yazılmamalı',
      );
    });

    test('bütün hobilerin basamakları artan eşikli', () {
      for (final HobbyKind h in HobbyKind.values) {
        expect(h.stages.first.experience, 0);
        for (int i = 1; i < h.stages.length; i++) {
          expect(h.stages[i].experience,
              greaterThan(h.stages[i - 1].experience),
              reason: '${h.label}: ${h.stages[i].label}');
        }
      }
    });
  });

  group('Sürüyor mu / ciddi mi', () {
    test('uzun süre uğraşılmayan hobi silinmez ama sürüyor sayılmaz', () {
      final GameState s = tekrarla(hayat(age: 10), 'resim_atolyesi', 2);
      final HobbyProgress h = HobbyTracker.progressOf(s, HobbyKind.resim)!;
      expect(h.isActiveAt(12), isTrue);
      expect(h.isActiveAt(40), isFalse);
      expect(s.hobbies, hasLength(1), reason: 'Kayıt silinmemeli');
    });

    test('kısa denemeler ciddi sayılmaz', () {
      final GameState s = tekrarla(hayat(age: 20), 'resim_atolyesi', 2);
      expect(HobbyTracker.progressOf(s, HobbyKind.resim)!.isSerious, isFalse);
    });

    test('en uzun sürdürülen hobi ana hobidir', () {
      GameState s = tekrarla(hayat(age: 10), 'muzik_kursu', 10);
      s = tekrarla(s, 'resim_atolyesi', 2);
      expect(HobbyTracker.mainHobby(s)!.hobbyId, HobbyKind.muzik.id);
    });

    test('hiç hobisi olmayanda ana hobi yok', () {
      expect(HobbyTracker.mainHobby(hayat()), isNull);
    });
  });

  group('Olaylar', () {
    test('en az altı hobi olayı var ve kimlikleri benzersiz', () {
      expect(kHobbyEvents.length, greaterThanOrEqualTo(6));
      final Set<String> idler =
          kHobbyEvents.map((GameEvent e) => e.id).toSet();
      expect(idler.length, kHobbyEvents.length);
    });

    test('hobi olayları ana havuza kayıtlı', () {
      for (final GameEvent e in kHobbyEvents) {
        expect(
          kEventPool.any((GameEvent x) => x.id == e.id),
          isTrue,
          reason: '${e.id} havuzda yok',
        );
      }
    });

    test('her hobi olayı gerçek bir hobi şartı taşır', () {
      for (final GameEvent e in kHobbyEvents) {
        final String? id = e.requirement.requiredHobbyId;
        expect(id, isNotNull, reason: e.id);
        expect(hobbyById(id!), isNotNull,
            reason: '${e.id}: bilinmeyen hobi $id');
      }
    });

    test('en az iki olay geçmişi hatırlar', () {
      // Geçmişi hatırlayan olay = uzun süre ya da ileri basamak arayan.
      final int hatirlayan = kHobbyEvents
          .where((GameEvent e) =>
              e.requirement.minHobbyYears >= 3 ||
              e.requirement.minHobbyStage >= 2)
          .length;
      expect(hatirlayan, greaterThanOrEqualTo(2));
    });

    test('her olayın en az iki seçeneği var', () {
      for (final GameEvent e in kHobbyEvents) {
        expect(e.choices.length, greaterThanOrEqualTo(2), reason: e.id);
      }
    });

    test('hobi olayı hobisi olmayana çıkmaz', () {
      const EventEngine olayMotoru = EventEngine();
      final Set<String> hobiIdleri =
          kHobbyEvents.map((GameEvent e) => e.id).toSet();
      for (int yas = 15; yas <= 70; yas += 5) {
        final Set<String> cikabilir =
            olayMotoru.debugEligibleIds(hayat(age: yas), Random(yas));
        expect(
          cikabilir.intersection(hobiIdleri),
          isEmpty,
          reason: '$yas yaşında hobisiz oyuncuya hobi olayı çıktı',
        );
      }
    });

    test('hobi olayı doğru hobiye bakar', () {
      const EventEngine olayMotoru = EventEngine();
      GameState s = tekrarla(hayat(age: 20), 'muzik_kursu', 8);
      // Olay çalışan olmayı şart koşuyor; mevcut kayıttan iş durumu
      // değişmeden yalnızca yaş ilerletilirse şart sağlanmaz.
      expect(
        HobbyTracker.progressOf(s, HobbyKind.muzik)!.years,
        greaterThanOrEqualTo(2),
      );
      s = s.copyWith(seenEventIds: const <String>{});
      final bool sartUyuyor = olayMotoru.debugMatches(
        s,
        kHobbyEvents.firstWhere(
          (GameEvent e) => e.id == 'hobi_mahalle_maci',
        ),
      );
      // Mahalle maçı sporla ilgili; müzikçiye çıkmaz.
      expect(sartUyuyor, isFalse);

      GameState sporcu = tekrarla(hayat(age: 20), 'kosu', 9);
      sporcu = sporcu.copyWith(seenEventIds: const <String>{});
      expect(
        olayMotoru.debugMatches(
          sporcu,
          kHobbyEvents.firstWhere(
            (GameEvent e) => e.id == 'hobi_mahalle_maci',
          ),
        ),
        isTrue,
        reason: 'Yıllardır spor yapana mahalle maçı çıkmalı',
      );
    });

    test('bırakılmış hobi olayı hâlâ uğraşana çıkmaz', () {
      const EventEngine olayMotoru = EventEngine();
      final GameEvent donus = kHobbyEvents.firstWhere(
        (GameEvent e) => e.id == 'hobi_yillar_sonra_donus',
      );
      GameState hep = tekrarla(hayat(age: 30), 'resim_atolyesi', 20);
      hep = hep.copyWith(seenEventIds: const <String>{});
      // Hobisi süren oyuncuya da çıkabilir (şart "bırakmış olmak" değil),
      // ama hiç resim yapmamış olana asla çıkmaz.
      expect(olayMotoru.debugMatches(hayat(age: 45), donus), isFalse);
      expect(olayMotoru.debugMatches(hep, donus), isTrue);
    });
  });

  group('Hayat sonu değerlendirmesi', () {
    test('yıllarca sürdürülen hobi Deneyim puanını yükseltir', () {
      final GameState hobisiz = hayat(age: 60);
      GameState hobili = tekrarla(hayat(age: 10), 'muzik_kursu', 25);
      hobili = hobili.copyWith(player: hobili.player.copyWith(age: 60));

      int deneyim(GameState s) => LifeVerdictBuilder.build(s)
          .axes
          .firstWhere((VerdictAxis a) => a.id == 'deneyim')
          .value;

      expect(deneyim(hobili), greaterThan(deneyim(hobisiz)));
    });

    test('ciddi hobi "ilkler" listesine girer', () {
      GameState s = tekrarla(hayat(age: 10), 'muzik_kursu', 25);
      s = s.copyWith(player: s.player.copyWith(age: 60));
      final List<VerdictFirst> ilkler = LifeVerdictBuilder.build(s).firsts;
      expect(
        ilkler.any((VerdictFirst f) => f.text.contains('Müzik')),
        isTrue,
      );
    });

    test('bir kez denenen hobi ilklere girmez', () {
      GameState s = tekrarla(hayat(age: 30), 'muzik_kursu', 1);
      s = s.copyWith(player: s.player.copyWith(age: 60));
      expect(
        LifeVerdictBuilder.build(s)
            .firsts
            .any((VerdictFirst f) => f.text.contains('Müzik')),
        isFalse,
      );
    });
  });

  test('hobi geçmişi kayda girer ve geri yüklenir', () {
    final GameState s = tekrarla(hayat(age: 10), 'muzik_kursu', 10);
    final GameState geri = decodeGameState(encodeGameState(s));
    final HobbyProgress once = HobbyTracker.progressOf(s, HobbyKind.muzik)!;
    final HobbyProgress sonra =
        HobbyTracker.progressOf(geri, HobbyKind.muzik)!;

    expect(sonra.startedAtAge, once.startedAtAge);
    expect(sonra.experience, once.experience);
    expect(sonra.lastPracticedAge, once.lastPracticedAge);
    expect(sonra.memories.length, once.memories.length);
    expect(sonra.memories.first.text, once.memories.first.text);
    expect(sonra.memories.first.age, once.memories.first.age);
  });

  test('eski kayıtta hobi alanı yoksa boş okunur', () {
    final Map<String, Object?> json =
        Map<String, Object?>.from(encodeGameState(hayat()));
    json.remove('hobbies');
    expect(decodeGameState(json).hobbies, isEmpty);
  });
}
