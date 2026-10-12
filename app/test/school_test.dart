import 'dart:math';

import 'package:bir_omur/data/event_pool.dart';
import 'package:bir_omur/domain/events/event_engine.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/generation/life_progression.dart';
import 'package:bir_omur/domain/models/education.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_flow.dart';

GameEvent eventById(String id) =>
    kEventPool.firstWhere((GameEvent e) => e.id == id);

/// Okul paketini kullanan küçük bir motor.
EventEngine schoolEngine(List<String> ids) =>
    EventEngine(pool: ids.map(eventById).toList(growable: false));

GameState studentAt({required int seed, required int age, required int grade}) {
  final GameState state = LifeGenerator.seeded(
    seed,
  ).generate(mode: StartMode.tamamenRastgele);
  // Gerçek oyunda okul kişileri kademe geçişinde üretilir; olayların
  // gerçek kişiye bağlanabilmesi için testte de eklenir.
  return withSchoolPeople(
    state.copyWith(
      player: state.player.copyWith(age: age),
      education: EducationState(enrolled: true, grade: grade, startedAtAge: 6),
    ),
    seed: seed,
  );
}

void main() {
  group('Eğitim durumu veride tutulur', () {
    test('doğumda okula başlanmamıştır ve öğrenci değildir', () {
      for (int seed = 0; seed < 30; seed++) {
        final GameState state = LifeGenerator.seeded(
          seed,
        ).generate(mode: StartMode.tamamenRastgele);
        expect(state.education.enrolled, isFalse);
        expect(state.education.isStudent, isFalse);
        expect(state.education.grade, isNull);
        expect(state.education.finished, isFalse);
        expect(state.education.label, 'Okula başlamadı');
      }
    });

    test('okula başlama yaşında kayıt olunur ve günlüğe yazılır', () {
      final GameController controller = GameController(random: Random(5));
      controller.startNewLife(mode: StartMode.tamamenRastgele, seed: 5);

      // Başlama yaşından önce öğrenci değil.
      advanceToAge(controller, LifeProgression.prototypeOnlySchoolStartAge - 1);
      expect(controller.state!.education.isStudent, isFalse);

      advanceToAge(controller, LifeProgression.prototypeOnlySchoolStartAge);
      final EducationState egitim = controller.state!.education;
      expect(egitim.isStudent, isTrue);
      expect(egitim.grade, 1);
      expect(egitim.startedAtAge, LifeProgression.prototypeOnlySchoolStartAge);
      expect(egitim.level, SchoolLevel.ilkokul);
      expect(
        controller.state!.log.any(
          (dynamic e) => (e.text as String).contains('Okula başladın'),
        ),
        isTrue,
      );
    });

    test('notu yeterli öğrenci her yaşta bir sınıf ilerler', () {
      final GameController controller = GameController(random: Random(3));
      controller.startNewLife(mode: StartMode.tamamenRastgele, seed: 3);
      // Paket 13'ten beri lisede sınıfta kalmak mümkün; bu test sınıf
      // ilerleyişini sınadığı için notu yüksek bir öğrenci kurulur.
      controller.debugSetState(
        controller.state!.copyWith(
          player: controller.state!.player.copyWith(
            stats: controller.state!.player.stats.copyWith(intelligence: 90),
          ),
        ),
      );

      const int baslangic = LifeProgression.prototypeOnlySchoolStartAge;
      for (int sinif = 1; sinif <= LifeProgression.lastGrade; sinif++) {
        advanceToAge(controller, baslangic + sinif - 1);
        expect(
          controller.state!.education.grade,
          sinif,
          reason: '${baslangic + sinif - 1} yaşında $sinif. sınıf olmalı',
        );
      }

      expect(SchoolLevel.forGrade(4), SchoolLevel.ilkokul);
      expect(SchoolLevel.forGrade(5), SchoolLevel.ortaokul);
      expect(SchoolLevel.forGrade(8), SchoolLevel.ortaokul);
      expect(SchoolLevel.forGrade(9), SchoolLevel.lise);
    });

    test('son sınıftan sonra okul biter, öğrencilik sona erer', () {
      final GameController controller = GameController(random: Random(3));
      controller.startNewLife(mode: StartMode.tamamenRastgele, seed: 3);
      // Sınıfta kalma bu testin konusu değil; notu yüksek öğrenci.
      controller.debugSetState(
        controller.state!.copyWith(
          player: controller.state!.player.copyWith(
            stats: controller.state!.player.stats.copyWith(intelligence: 90),
          ),
        ),
      );

      const int bitisYasi =
          LifeProgression.prototypeOnlySchoolStartAge +
          LifeProgression.lastGrade;
      advanceToAge(controller, bitisYasi);

      final EducationState egitim = controller.state!.education;
      expect(egitim.finished, isTrue);
      expect(egitim.isStudent, isFalse);
      expect(egitim.grade, isNull);
      expect(egitim.label, 'Liseyi bitirdi');

      // Okul bitince geri dönülmez.
      advanceToAge(controller, bitisYasi + 5);
      expect(controller.state!.education.finished, isTrue);
      expect(controller.state!.education.isStudent, isFalse);
    });

    test('eğitim durumu yaştan türetilmez', () {
      // Okul çağında ama kaydı olmayan karakter öğrenci sayılmaz.
      final GameState state = LifeGenerator.seeded(1)
          .generate(mode: StartMode.tamamenRastgele)
          .copyWith(
            player: LifeGenerator.seeded(1)
                .generate(mode: StartMode.tamamenRastgele)
                .player
                .copyWith(age: 10),
          );
      expect(state.player.age, 10);
      expect(state.education.isStudent, isFalse);
    });
  });

  group('Okul olaylarının uygunluğu', () {
    test('okula başlamamış karaktere hiçbir okul olayı çıkmaz', () {
      final EventEngine engine = schoolEngine(<String>[
        'okul_sira_arkadasi',
        'teneffus_oyun_daveti',
        'arkadas_odev_yardimi',
        'ogretmen_sorusu',
        'yardimin_karsiligi',
      ]);
      for (int seed = 0; seed < 30; seed++) {
        for (final int age in <int>[3, 7, 12, 20]) {
          final GameState state = LifeGenerator.seeded(
            seed,
          ).generate(mode: StartMode.tamamenRastgele);
          final GameState yasli = state.copyWith(
            player: state.player.copyWith(age: age),
          );
          expect(yasli.education.isStudent, isFalse);
          expect(
            engine.openingEvent(yasli, Random(seed)),
            isNull,
            reason: '$age yaşında, okula başlamamışken olay çıkmamalı',
          );
        }
      }
    });

    test('okulu bitirmiş karaktere okul olayı çıkmaz', () {
      final EventEngine engine = schoolEngine(<String>['ogretmen_sorusu']);
      final GameState ogrenci = studentAt(seed: 4, age: 12, grade: 7);
      expect(engine.openingEvent(ogrenci, Random(1)), isNotNull);

      final GameState mezun = ogrenci.copyWith(
        education: ogrenci.education.asFinished(),
      );
      expect(engine.openingEvent(mezun, Random(1)), isNull);
    });

    test('sınıf aralığı dışında olay çıkmaz', () {
      final EventEngine engine = schoolEngine(<String>['okul_sira_arkadasi']);
      // 1-8. sınıf aralığı.
      expect(
        engine.openingEvent(studentAt(seed: 6, age: 9, grade: 4), Random(1)),
        isNotNull,
      );
      expect(
        engine.openingEvent(studentAt(seed: 6, age: 13, grade: 8), Random(1)),
        isNotNull,
      );
      expect(
        engine.openingEvent(studentAt(seed: 6, age: 14, grade: 9), Random(1)),
        isNull,
      );
    });

    test('arkadaşı olmayan karaktere arkadaş olayı çıkmaz', () {
      final EventEngine engine = schoolEngine(<String>[
        'teneffus_oyun_daveti',
        'arkadas_odev_yardimi',
      ]);
      final GameState state = studentAt(seed: 8, age: 11, grade: 6);
      expect(
        state.people.any((Person p) => p.relation == RelationType.arkadas),
        isFalse,
      );
      expect(engine.openingEvent(state, Random(1)), isNull);
    });
  });

  group('Okul arkadaşı kalıcı bir kişidir', () {
    ({GameState state, String friendId}) withFriend(int seed) {
      final EventEngine engine = schoolEngine(<String>['okul_sira_arkadasi']);
      final GameState state = studentAt(seed: seed, age: 8, grade: 3);
      final ActiveEvent? tanisma = engine.openingEvent(state, Random(seed));
      expect(tanisma, isNotNull);
      final GameState sonra = engine.resolve(
        state.copyWith(pendingEvent: tanisma),
        'tanis',
        rng: Random(seed),
      );
      final Person friend = sonra.people.firstWhere(
        (Person p) => p.relation == RelationType.arkadas,
      );
      return (state: sonra, friendId: friend.id);
    }

    test('tanışma seçimi gerçek bir kişi kaydı oluşturur', () {
      for (int seed = 0; seed < 20; seed++) {
        final ({GameState state, String friendId}) sonuc = withFriend(seed);
        final Person friend = sonuc.state.personById(sonuc.friendId)!;

        expect(friend.firstName, isNotEmpty);
        expect(friend.lastName, isNotEmpty);
        expect(friend.isAlive, isTrue);
        expect(friend.relation, RelationType.arkadas);
        expect(
          friend.relation.kanBagi,
          isFalse,
          reason: 'Arkadaş akraba değil',
        );
        expect(
          friend.inPlayerHousehold,
          isFalse,
          reason: 'Arkadaş otomatik hanede sayılmaz',
        );
        expect(friend.bond, greaterThan(0));
        expect(
          sonuc.state.storyFlags,
          contains(StoryFlags.okuldaArkadasEdindi),
        );
      }
    });

    test('arkadaşın adı sonuç metnine ve günlüğe geçer', () {
      final ({GameState state, String friendId}) sonuc = withFriend(5);
      final Person friend = sonuc.state.personById(sonuc.friendId)!;
      expect(sonuc.state.log.last.text, contains(friend.firstName));
      expect(sonuc.state.log.last.text, isNot(contains('{kisi}')));
    });

    test('tanışılmazsa arkadaş oluşmaz ve olay bir daha çıkmaz', () {
      final EventEngine engine = schoolEngine(<String>['okul_sira_arkadasi']);
      final GameState state = studentAt(seed: 7, age: 8, grade: 3);
      final ActiveEvent? tanisma = engine.openingEvent(state, Random(7));
      final GameState sonra = engine.resolve(
        state.copyWith(pendingEvent: tanisma),
        'cekin',
        rng: Random(7),
      );

      expect(
        sonra.people.any((Person p) => p.relation == RelationType.arkadas),
        isFalse,
      );
      expect(sonra.storyFlags, contains(StoryFlags.okuldaCekingen));
      expect(engine.openingEvent(sonra, Random(7)), isNull);
    });

    test('arkadaşın kimliği yaş alındıkça ve olaylar boyunca korunur', () {
      // Bu test tek bir tohuma (11) bağlıydı: "o hayatta 40 yaş içinde
      // arkadaş edinilir". Havuza yeni olay eklendiğinde rastgelelik
      // kayıyor ve o tohum arkadaşsız kalabiliyor; ölçtüm, mekanizma
      // aynı kalsa da hangi tohumun tuttuğu değişiyor (30 tohumda 20
      // başarı, havuza dokunmadan önce de sonra da).
      //
      // Testin asıl iddiası tohum değil: **arkadaş edinildikten sonra
      // kimliğin korunması**. Bu yüzden arkadaş veren bir hayat
      // bulunana kadar tohum deneniyor, iddia o hayatta sınanıyor.
      GameController? controller;
      String? friendId;
      String? friendName;

      for (int seed = 11; seed < 60 && friendId == null; seed++) {
        final GameController aday = GameController(random: Random(seed));
        aday.startNewLife(mode: StartMode.tamamenRastgele, seed: seed);
        for (int i = 0; i < 40 && friendId == null; i++) {
          resolvePendingEvents(aday, preferChoiceId: 'tanis');
          // Lise alanı seçilmeden yaş atlanmaz (D-094).
          resolveEducationChoices(aday);
          aday.ageUp();
          resolvePendingEvents(aday, preferChoiceId: 'tanis');
          if (aday.state == null || aday.state!.deceased) break;
          for (final Person p in aday.state!.people) {
            if (p.relation == RelationType.arkadas) {
              friendId = p.id;
              friendName = p.firstName;
              controller = aday;
            }
          }
        }
      }
      expect(friendId, isNotNull, reason: 'Okulda arkadaş edinilebilmeli');
      expect(controller, isNotNull);

      final GameController c = controller!;
      final int bondOnce = c.state!.personById(friendId!)!.bond;
      for (int i = 0; i < 10; i++) {
        resolvePendingEvents(c, preferChoiceId: 'tanis');
        // Lise alanı seçilmeden yaş atlanmaz (D-094).
        resolveEducationChoices(c);
        c.ageUp();
      }
      resolvePendingEvents(c, preferChoiceId: 'tanis');

      final Person sonra = c.state!.personById(friendId)!;
      expect(sonra.id, friendId, reason: 'Kimlik değişmez');
      expect(sonra.firstName, friendName, reason: 'İsim değişmez');
      expect(sonra.relation, RelationType.arkadas);
      expect(sonra.bond, greaterThanOrEqualTo(0));
      expect(bondOnce, greaterThan(0));
      // Okul bitse bile kişi silinmez.
      expect(c.state!.personById(friendId), isNotNull);
    });

    test('yalnızca bir okul arkadaşı oluşur, kimlikler çakışmaz', () {
      final ({GameState state, String friendId}) sonuc = withFriend(9);
      final List<Person> arkadaslar = sonuc.state.people
          .where((Person p) => p.relation == RelationType.arkadas)
          .toList();
      expect(arkadaslar.length, 1);
      final Set<String> ids = sonuc.state.people
          .map((Person p) => p.id)
          .toSet();
      expect(ids.length, sonuc.state.people.length);
    });
  });

  group('Seçimler hatırlanır', () {
    ({GameState state, String friendId}) friendAtGrade(int seed, int grade) {
      final EventEngine engine = schoolEngine(<String>['okul_sira_arkadasi']);
      final GameState state = studentAt(seed: seed, age: 8, grade: 3);
      final ActiveEvent? tanisma = engine.openingEvent(state, Random(seed));
      GameState sonra = engine.resolve(
        state.copyWith(pendingEvent: tanisma),
        'tanis',
        rng: Random(seed),
      );
      sonra = sonra.copyWith(
        player: sonra.player.copyWith(age: 5 + grade),
        education: sonra.education.copyWith(grade: grade),
      );
      final Person friend = sonra.people.firstWhere(
        (Person p) => p.relation == RelationType.arkadas,
      );
      return (state: sonra, friendId: friend.id);
    }

    test('yardım etmek ileride ayrı bir olay açar', () {
      final EventEngine yardimEngine = schoolEngine(<String>[
        'arkadas_odev_yardimi',
      ]);
      final EventEngine karsilikEngine = schoolEngine(<String>[
        'yardimin_karsiligi',
      ]);

      final ({GameState state, String friendId}) baslangic = friendAtGrade(
        5,
        5,
      );
      // Yardım olayı çıkmadan önce karşılık olayı açılmaz.
      expect(karsilikEngine.openingEvent(baslangic.state, Random(1)), isNull);

      final ActiveEvent? yardim = yardimEngine.openingEvent(
        baslangic.state,
        Random(1),
      );
      expect(yardim!.eventId, 'arkadas_odev_yardimi');
      expect(
        yardim.personId,
        baslangic.friendId,
        reason: 'Olay gerçek arkadaşla kurulmalı',
      );

      final int bondOnce = baslangic.state.personById(baslangic.friendId)!.bond;
      final GameState yardimEtti = yardimEngine.resolve(
        baslangic.state.copyWith(pendingEvent: yardim),
        'yardim',
        rng: Random(1),
      );

      expect(yardimEtti.storyFlags, contains(StoryFlags.arkadasaYardimEtti));
      expect(
        yardimEtti.personById(baslangic.friendId)!.bond,
        greaterThan(bondOnce),
        reason: 'Yardım arkadaşlığı güçlendirmeli',
      );

      final ActiveEvent? karsilik = karsilikEngine.openingEvent(
        yardimEtti,
        Random(1),
      );
      expect(karsilik, isNotNull, reason: 'Geçmiş seçim hatırlanmalı');
      expect(karsilik!.eventId, 'yardimin_karsiligi');
      expect(
        karsilik.personId,
        baslangic.friendId,
        reason: 'Karşılık aynı arkadaştan gelmeli',
      );
      expect(
        karsilik.text,
        contains(yardimEtti.personById(baslangic.friendId)!.firstName),
      );
    });

    test('yardım etmemek o devamı açmaz ve ilişkiyi zayıflatır', () {
      final EventEngine yardimEngine = schoolEngine(<String>[
        'arkadas_odev_yardimi',
      ]);
      final EventEngine karsilikEngine = schoolEngine(<String>[
        'yardimin_karsiligi',
      ]);

      final ({GameState state, String friendId}) baslangic = friendAtGrade(
        5,
        5,
      );
      final int bondOnce = baslangic.state.personById(baslangic.friendId)!.bond;
      final ActiveEvent? yardim = yardimEngine.openingEvent(
        baslangic.state,
        Random(1),
      );
      final GameState reddetti = yardimEngine.resolve(
        baslangic.state.copyWith(pendingEvent: yardim),
        'reddet',
        rng: Random(1),
      );

      expect(reddetti.storyFlags, contains(StoryFlags.arkadasaYardimEtmedi));
      expect(
        reddetti.storyFlags,
        isNot(contains(StoryFlags.arkadasaYardimEtti)),
      );
      expect(reddetti.personById(baslangic.friendId)!.bond, lessThan(bondOnce));

      // Aynı arkadaş, daha ileri sınıflarda bile karşılık olayını açmaz.
      for (int grade = 4; grade <= 12; grade++) {
        final GameState ileri = reddetti.copyWith(
          player: reddetti.player.copyWith(age: 5 + grade),
          education: reddetti.education.copyWith(grade: grade),
        );
        expect(karsilikEngine.openingEvent(ileri, Random(grade)), isNull);
      }
    });

    test('yardım olayı bir kez sorulur', () {
      final EventEngine engine = schoolEngine(<String>['arkadas_odev_yardimi']);
      final ({GameState state, String friendId}) baslangic = friendAtGrade(
        5,
        5,
      );
      final ActiveEvent? ilk = engine.openingEvent(baslangic.state, Random(1));
      final GameState sonra = engine.resolve(
        baslangic.state.copyWith(pendingEvent: ilk),
        'yardim',
        rng: Random(1),
      );
      expect(engine.openingEvent(sonra, Random(2)), isNull);
    });

    test('derste söz almak karakter değerlerini değiştirir', () {
      final EventEngine engine = schoolEngine(<String>['ogretmen_sorusu']);
      final GameState state = studentAt(seed: 2, age: 11, grade: 6);
      final ActiveEvent? soru = engine.openingEvent(state, Random(1));
      expect(soru, isNotNull);

      final GameState sonra = engine.resolve(
        state.copyWith(pendingEvent: soru),
        'kaldir',
        rng: Random(1),
      );
      expect(
        sonra.player.stats.intelligence,
        greaterThan(state.player.stats.intelligence),
      );
      expect(
        sonra.player.stats.charisma,
        greaterThan(state.player.stats.charisma),
      );
      expect(sonra.storyFlags, contains(StoryFlags.dersteSozAldi));
    });
  });

  group('Diğer sistemler bozulmadı', () {
    test('aile, romantik ilişki ve yaş alma birlikte çalışır', () {
      for (int seed = 0; seed < 15; seed++) {
        final GameController controller = GameController(random: Random(seed));
        controller.startNewLife(mode: StartMode.tamamenRastgele, seed: seed);
        final int kisiOnce = controller.state!.people.length;

        for (int i = 0; i < 25; i++) {
          final int yasOnce = controller.state!.player.age;
          resolvePendingEvents(controller);
          // Hayat bu tohumda erken bitebilir; vefat edenin yaşı ilerlemez.
          if (controller.state!.deceased) break;
          // Lise alanı seçilmeden yaş atlanmaz (D-094).
          resolveEducationChoices(controller);
          controller.ageUp();
          expect(controller.state!.player.age, yasOnce + 1);
        }
        resolvePendingEvents(controller);

        // Aile kayıtları duruyor, kimse silinmemiş.
        expect(controller.state!.people.length, greaterThanOrEqualTo(kisiOnce));
        final Person anne = controller.state!.people.firstWhere(
          (Person p) => p.relation == RelationType.anne,
        );
        expect(anne.relation, RelationType.anne);
        // Arkadaş ve romantik kişiler akraba sayılmaz.
        for (final Person p in controller.state!.people) {
          if (p.relation == RelationType.arkadas) {
            expect(p.relation.kanBagi, isFalse);
            expect(p.inPlayerHousehold, isFalse);
          }
        }
      }
    });
  });
}
