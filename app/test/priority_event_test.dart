import 'dart:math';

import 'package:bir_omur/data/event_pool.dart';
import 'package:bir_omur/data/event_pool_exam.dart';
import 'package:bir_omur/domain/events/event_engine.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/education.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/pending_crisis.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// Dönüm noktası önceliği (Paket 21).
///
/// Ölçüm, tek bir yıla bağlı olayların bütün havuzla yarıştıkları için
/// çoğu hayatta hiç çıkmadığını göstermişti: sınav yılı olayları
/// oyuncuların ancak %38'inde görülüyordu. Bu testler hem mekanizmayı
/// hem de **gerçek hayatlardaki sonucu** korur.
GameState ogrenci({int age = 13, int grade = 8, int seed = 9}) {
  final GameState base =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  return base.copyWith(
    pendingEvent: null,
    player: base.player.copyWith(age: age),
    education: EducationState(
      enrolled: true,
      grade: grade,
      startedAtAge: 6,
      gradeAverage: 70,
    ),
  );
}

void main() {
  group('Öncelik mekanizması', () {
    const GameEvent sirali = GameEvent(
      id: 'test_siradan',
      category: EventCategory.kisisel,
      text: 'Sıradan bir gün.',
      requirement: EventRequirement(),
      repeatable: true,
      weight: 100,
      choices: <EventChoice>[
        EventChoice(id: 'a', label: 'A', resultText: 'A oldu.'),
        EventChoice(id: 'b', label: 'B', resultText: 'B oldu.'),
      ],
    );
    const GameEvent donumNoktasi = GameEvent(
      id: 'test_donum',
      category: EventCategory.kisisel,
      text: 'Bugün özel bir gün.',
      requirement: EventRequirement(),
      weight: 1,
      priority: 1,
      choices: <EventChoice>[
        EventChoice(id: 'a', label: 'A', resultText: 'Dönüm A.'),
        EventChoice(id: 'b', label: 'B', resultText: 'Dönüm B.'),
      ],
    );

    test('öncelikli olay, ağırlığı düşük olsa bile çoğu zaman öne geçer', () {
      const EventEngine motor =
          EventEngine(pool: <GameEvent>[sirali, donumNoktasi]);
      final GameState s = ogrenci();
      // Ham ağırlık 1'e karşı 100; öncelik olmasaydı yüzde bir çıkardı.
      int donum = 0;
      const int deneme = 200;
      for (int tohum = 0; tohum < deneme; tohum++) {
        if (motor.openingEvent(s, Random(tohum))?.eventId == 'test_donum') {
          donum++;
        }
      }
      expect(donum, greaterThan((deneme * 0.4).round()),
          reason: '$deneme denemede yalnızca $donum kez çıktı');
    });

    test('öncelik havuzun kalanını tamamen boğmaz', () {
      // Geniş pencereli bir dönüm noktası, yıllarca başka hiçbir olayın
      // çıkmamasına yol açmamalı.
      const EventEngine motor =
          EventEngine(pool: <GameEvent>[sirali, donumNoktasi]);
      final GameState s = ogrenci();
      final Set<String> gorulenler = <String>{};
      for (int tohum = 0; tohum < 400; tohum++) {
        final ActiveEvent? o = motor.openingEvent(s, Random(tohum));
        if (o != null) gorulenler.add(o.eventId);
      }
      expect(gorulenler, contains('test_donum'));
      expect(gorulenler, contains('test_siradan'));
    });

    test('öncelikli olay uygun değilse sıradan olaylar yine çıkar', () {
      // Dönüm noktası yalnızca 40 yaşta uygun.
      const GameEvent dar = GameEvent(
        id: 'test_dar',
        category: EventCategory.kisisel,
        text: 'Yalnızca bir yıl.',
        requirement: EventRequirement(minAge: 40, maxAge: 40),
        weight: 1,
        priority: 1,
        choices: <EventChoice>[
          EventChoice(id: 'a', label: 'A', resultText: 'Dar A.'),
          EventChoice(id: 'b', label: 'B', resultText: 'Dar B.'),
        ],
      );
      const EventEngine motor = EventEngine(pool: <GameEvent>[sirali, dar]);

      // 30 yaşında dar olay hiç aday değil.
      for (int tohum = 0; tohum < 30; tohum++) {
        expect(motor.openingEvent(ogrenci(age: 30), Random(tohum))?.eventId,
            'test_siradan');
      }

      // 40 yaşında öne geçer.
      int sayac = 0;
      for (int tohum = 0; tohum < 100; tohum++) {
        if (motor.openingEvent(ogrenci(age: 40), Random(tohum))?.eventId ==
            'test_dar') {
          sayac++;
        }
      }
      expect(sayac, greaterThan(40), reason: '100 denemede $sayac');
    });

    test('öncelik çıkmayı garanti etmez: koşul tutmazsa elenir', () {
      const GameEvent imkansiz = GameEvent(
        id: 'test_imkansiz',
        category: EventCategory.kisisel,
        text: 'Hiç olmayacak.',
        requirement: EventRequirement(
          requiredFlags: <String>{'hicbir_zaman'},
        ),
        weight: 1,
        priority: 5,
        choices: <EventChoice>[
          EventChoice(id: 'a', label: 'A', resultText: 'A.'),
          EventChoice(id: 'b', label: 'B', resultText: 'B.'),
        ],
      );
      const EventEngine motor =
          EventEngine(pool: <GameEvent>[sirali, imkansiz]);
      expect(motor.openingEvent(ogrenci(), Random(1))?.eventId,
          'test_siradan');
    });

    test('öncelik yalnızca dar pencereli olaylara verilir', () {
      // Geniş pencereli bir dönüm noktasına öncelik vermek o yılları
      // boğuyor: 18-32 yaş arasına yayılan olaylar denendiğinde romantik
      // zincir hiç sıra bulamadı. Kural burada korunur.
      for (final GameEvent e in kEventPool) {
        if (e.priority == 0) continue;
        final EventRequirement r = e.requirement;
        final bool tekSinif =
            r.minGrade != null && r.minGrade == r.maxGrade;
        final int pencere = r.maxAge - r.minAge;
        expect(
          tekSinif || pencere <= 3,
          isTrue,
          reason: '${e.id}: öncelikli ama penceresi $pencere yıl '
              '(${r.minAge}-${r.maxAge})',
        );
      }
    });

    test('varsayılan öncelik sıfırdır', () {
      expect(sirali.priority, 0);
      for (final GameEvent e in kEventPool) {
        expect(e.priority, greaterThanOrEqualTo(0), reason: e.id);
      }
    });
  });

  group('Sınav yılı gerçekten görülüyor', () {
    test('sekizinci ve on ikinci sınıfa ulaşan herkes sınav olayı görür', () {
      final Set<String> sinavIdleri =
          kExamEvents.map((GameEvent e) => e.id).toSet();
      int ulasan8 = 0, goren8 = 0, ulasan12 = 0, goren12 = 0;

      for (int t = 0; t < 20; t++) {
        final GameController c = GameController(random: Random(t * 13 + 3));
        c.startNewLife(mode: StartMode.tamamenRastgele);
        bool v8 = false, v12 = false, g8 = false, g12 = false;
        while (!c.state!.deceased && c.state!.player.age < 20) {
          final int sinif = c.state!.education.grade ?? 0;
          if (sinif == 8) v8 = true;
          if (sinif == 12) v12 = true;
          int guard = 0;
          while (c.state!.hasPendingEvent && guard++ < 10) {
            final String id = c.state!.pendingEvent!.eventId;
            if (sinavIdleri.contains(id)) {
              if (id.startsWith('sinav8')) g8 = true;
              if (id.startsWith('sinav12')) g12 = true;
            }
            c.chooseEventOption(c.state!.pendingEvent!.choices.first.id);
          }
          while (c.state!.hasNotice) {
            c.dismissNotice();
          }
          if (c.state!.hasPendingCrisis) {
            final PendingCrisis k = c.state!.pendingCrisis!;
            c.respondToCrisis(k.crisis!.choices.first.id);
          }
          c.ageUp();
        }
        if (v8) ulasan8++;
        if (v12) ulasan12++;
        if (g8) goren8++;
        if (g12) goren12++;
        c.dispose();
      }

      expect(ulasan8, greaterThan(0));
      expect(ulasan12, greaterThan(0));
      // Ölçümde bu oran %38 ve %28'di; öncelikle birlikte herkes görmeli.
      expect(goren8, ulasan8, reason: '8. sınıfa ulaşan herkes görmeli');
      expect(goren12, ulasan12, reason: '12. sınıfa ulaşan herkes görmeli');
    });
  });
}
