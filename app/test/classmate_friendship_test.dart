import 'dart:math';

import 'package:bir_omur/data/event_pool.dart';
import 'package:bir_omur/domain/events/event_engine.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/generation/life_progression.dart';
import 'package:bir_omur/domain/interaction/friendship.dart';
import 'package:bir_omur/domain/models/education.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_flow.dart';

/// Sınıf arkadaşlığı ile yakın arkadaşlığın ayrılması.
///
/// Hata: sınıf arkadaşı yakın arkadaşa dönüşünce [Person.relation] alanı
/// `sinifArkadasi` → `arkadas` oluyordu ve sınıf listesi bu alana baktığı
/// için kişi **aynı sınıfta okumaya devam ettiği hâlde** Sınıf Arkadaşları
/// listesinden kayboluyordu.
///
/// Çözüm: okul bağı ([Person.schoolTie]) yakınlık derecesinden ayrıldı.
void main() {
  GameEvent eventById(String id) =>
      kEventPool.firstWhere((GameEvent e) => e.id == id);

  GameState studentAt({required int seed, required int age, required int grade}) {
    final GameState state =
        LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
    return withSchoolPeople(
      state.copyWith(
        player: state.player.copyWith(age: age),
        education: EducationState(enrolled: true, grade: grade, startedAtAge: 6),
      ),
      seed: seed,
    );
  }

  List<Person> closeFriends(GameState state) => state.people
      .where((Person p) => p.isAlive && p.relation == RelationType.arkadas)
      .toList(growable: false);

  group('Sınıf arkadaşı yakın arkadaş olunca', () {
    test('aynı sınıftaki kişi Sınıf Arkadaşları listesinde kalır', () {
      for (int seed = 0; seed < 15; seed++) {
        final GameState state = studentAt(seed: seed, age: 9, grade: 4);
        final Person sinifArkadasi = state.currentClassmates.first;
        final int sinifSayisiOnce = state.currentClassmates.length;

        final ({GameState state, Person friend}) sonuc =
            const Friendship().promoteToFriend(state, sinifArkadasi.id);

        // Hata buradaydı: kişi sınıf listesinden düşüyordu.
        expect(
          sonuc.state.currentClassmates.map((Person p) => p.id),
          contains(sinifArkadasi.id),
          reason: 'Aynı sınıfta okuyan yakın arkadaş sınıf listesinde kalmalı',
        );
        expect(sonuc.state.currentClassmates.length, sinifSayisiOnce,
            reason: 'Sınıf mevcudu değişmemeli');

        // Aynı kişi yakın arkadaş listesinde de görünür.
        expect(
          closeFriends(sonuc.state).map((Person p) => p.id),
          contains(sinifArkadasi.id),
        );
      }
    });

    test('ikinci bir NPC oluşmaz, kimlik ve okul bağı korunur', () {
      final GameState state = studentAt(seed: 5, age: 9, grade: 4);
      final Person once = state.currentClassmates.first;

      final ({GameState state, Person friend}) sonuc =
          const Friendship().promoteToFriend(state, once.id);
      final Person sonra = sonuc.state.personById(once.id)!;

      expect(sonuc.state.people.length, state.people.length,
          reason: 'Yeni kişi kaydı açılmamalı');
      expect(sonra.id, once.id);
      expect(sonra.firstName, once.firstName);
      expect(sonra.lastName, once.lastName);
      expect(sonra.schoolTie, SchoolTie.sinifArkadasi,
          reason: 'Okul bağı değişmez');
      expect(sonra.schoolLevel, once.schoolLevel);
      expect(sonra.relation, RelationType.arkadas,
          reason: 'Yakınlık derecesi yükselir');
      expect(sonra.bond, greaterThan(once.bond));
    });

    test('öğretmenler etkilenmez', () {
      final GameState state = studentAt(seed: 6, age: 9, grade: 4);
      final Person sinifArkadasi = state.currentClassmates.first;
      final List<String> ogretmenlerOnce =
          state.currentTeachers.map((Person p) => p.id).toList(growable: false);

      final GameState sonra =
          const Friendship().promoteToFriend(state, sinifArkadasi.id).state;

      expect(
        sonra.currentTeachers.map((Person p) => p.id),
        ogretmenlerOnce,
      );
    });

    test('tanışma olayı üzerinden de sınıf listesi korunur', () {
      final EventEngine engine =
          EventEngine(pool: <GameEvent>[eventById('okul_sira_arkadasi')]);
      final GameState state = studentAt(seed: 15, age: 8, grade: 3);
      final ActiveEvent? olay = engine.openingEvent(state, Random(15));
      expect(olay, isNotNull);
      final String kisiId = olay!.personId!;

      final GameState sonra = engine.resolve(
        state.copyWith(pendingEvent: olay),
        'tanis',
        rng: Random(15),
      );

      expect(sonra.people.length, state.people.length);
      expect(
        sonra.currentClassmates.map((Person p) => p.id),
        contains(kisiId),
        reason: 'Olayla yakınlaşan sınıf arkadaşı sınıfta kalmalı',
      );
      expect(closeFriends(sonra).map((Person p) => p.id), contains(kisiId));
    });
  });

  group('Kademe değişince', () {
    test('yakın arkadaş olmuş sınıf arkadaşı güncel sınıfta görünmez ama '
        'kaydı silinmez', () {
      final GameController controller = GameController(random: Random(31));
      controller.startNewLife(mode: StartMode.tamamenRastgele, seed: 31);
      advanceToAge(controller, LifeProgression.prototypeOnlySchoolStartAge);
      resolvePendingEvents(controller);

      final Person sinifArkadasi = controller.state!.currentClassmates.first;
      final GameState yakinlasmis = const Friendship()
          .promoteToFriend(controller.state!, sinifArkadasi.id)
          .state;
      expect(
        yakinlasmis.currentClassmates.map((Person p) => p.id),
        contains(sinifArkadasi.id),
      );

      // Ortaokula geç.
      final GameState ortaokul = yakinlasmis.copyWith(
        player: yakinlasmis.player.copyWith(age: 11),
        education: const EducationState(
          enrolled: true,
          grade: 5,
          startedAtAge: 6,
        ),
      );

      expect(ortaokul.education.level, SchoolLevel.ortaokul);
      expect(
        ortaokul.currentClassmates.map((Person p) => p.id),
        isNot(contains(sinifArkadasi.id)),
        reason: 'Artık aynı sınıfta değil',
      );
      expect(ortaokul.personById(sinifArkadasi.id), isNotNull,
          reason: 'Kayıt silinmez (D-029)');
      expect(
        ortaokul.pastSchoolPeople.map((Person p) => p.id),
        contains(sinifArkadasi.id),
        reason: 'Geçmiş yılların tanıdığı olarak görünmeli',
      );
      // Yakın arkadaşlık kademeyle bitmez.
      expect(
        closeFriends(ortaokul).map((Person p) => p.id),
        contains(sinifArkadasi.id),
      );
    });

    test('gerçek oyun akışında eski kademe kişileri korunur', () {
      final GameController controller = GameController(random: Random(32));
      controller.startNewLife(mode: StartMode.tamamenRastgele, seed: 32);
      advanceToAge(controller, LifeProgression.prototypeOnlySchoolStartAge);
      resolvePendingEvents(controller);

      final List<String> ilkokullular = controller.state!.people
          .where((Person p) => p.schoolLevel == SchoolLevel.ilkokul)
          .map((Person p) => p.id)
          .toList(growable: false);
      expect(ilkokullular, isNotEmpty);

      advanceToAge(controller, LifeProgression.prototypeOnlySchoolStartAge + 4);
      final GameState state = controller.state!;
      expect(state.education.level, SchoolLevel.ortaokul);

      for (final String id in ilkokullular) {
        expect(state.personById(id), isNotNull);
      }
      for (final Person p in state.currentClassmates) {
        expect(p.schoolLevel, SchoolLevel.ortaokul);
        expect(p.schoolTie, SchoolTie.sinifArkadasi);
      }
      for (final Person p in state.currentTeachers) {
        expect(p.schoolLevel, SchoolLevel.ortaokul);
        expect(p.schoolTie, SchoolTie.ogretmen);
      }
    });
  });
}
