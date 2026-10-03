import 'dart:math';

import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/domain/generation/child_marriage.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/interaction/finger.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/person_development.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/stats.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:flutter_test/flutter_test.dart';

/// Paket R: flörtün sonu ve ailedeki dönüm noktaları (D-121, D-122).
void main() {
  GameState taban({int seed = 21, int age = 50}) {
    final GameState base =
        LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
    return base.copyWith(
      pendingEvent: null,
      player: base.player.copyWith(age: age),
    );
  }

  Person cocuk({
    String id = 'c1',
    int age = 26,
    int bond = 70,
    bool evli = false,
  }) =>
      Person(
        id: id,
        firstName: 'Ece',
        lastName: 'Yılmaz',
        gender: Gender.kadin,
        relation: RelationType.cocuk,
        age: age,
        isAlive: true,
        inPlayerHousehold: false,
        employment: EmploymentStatus.calisiyor,
        wealth: WealthTier.ortaHalli,
        bond: bond,
        development: PersonDevelopment(
          stats: const Stats(
            appearance: 50,
            happiness: 50,
            health: 50,
            intelligence: 50,
            charisma: 50,
          ),
          tracksLife: true,
          marriedAtAge: evli ? age - 1 : null,
          spouseName: evli ? 'Kaan' : null,
        ),
      );

  group('Çocuğun evlenmesi (D-121)', () {
    test('yaşı tutmayan çocuk evlenmez', () {
      expect(
        ChildMarriage.eligible(
          cocuk(age: ChildMarriage.prototypeOnlyMinAge - 1),
        ),
        isFalse,
      );
    });

    test('zaten evli çocuk yeniden evlenmez', () {
      expect(ChildMarriage.eligible(cocuk(evli: true)), isFalse);
    });

    test('evlenince kayıt ve dönüm noktası oluşur', () {
      for (int seed = 0; seed < 80; seed++) {
        final ChildMarriageResult? r = ChildMarriage.maybeMarry(
          child: cocuk(),
          playerAge: 50,
          rng: Random(seed),
        );
        if (r == null) continue;
        expect(r.person.development!.isMarried, isTrue);
        expect(r.person.development!.spouseName, isNotEmpty);
        expect(r.person.development!.marriedAtAge, 26);
        expect(
          r.person.development!.milestones.any(
            (dynamic m) => (m.text as String).contains('evlendi'),
          ),
          isTrue,
        );
        return;
      }
      fail('Hiç evlilik olmadı');
    });

    test('aran iyiyse davetiye, kötüyse sadece haber gelir', () {
      ChildMarriageResult? yakin;
      ChildMarriageResult? uzak;
      for (int seed = 0; seed < 200; seed++) {
        yakin ??= ChildMarriage.maybeMarry(
          child: cocuk(id: 'y1', bond: 90),
          playerAge: 50,
          rng: Random(seed),
        );
        uzak ??= ChildMarriage.maybeMarry(
          child: cocuk(id: 'u1', bond: 10),
          playerAge: 50,
          rng: Random(seed),
        );
        if (yakin != null && uzak != null) break;
      }
      expect(yakin, isNotNull);
      expect(uzak, isNotNull);

      // Faho: "aram kötü ise sadece düğününün olduğunu, iyi ise direkt
      // davetiye gibi gelsin".
      expect(yakin!.notice.title, 'Düğün davetiyesi');
      expect(yakin.notice.text, contains('davetiye'));
      expect(uzak!.notice.title, 'Çocuğun evlendi');
      expect(uzak.notice.text, contains('sonradan'));
    });

    test('bildirim doğum bildirimi değildir: isim alanı açılmaz', () {
      for (int seed = 0; seed < 80; seed++) {
        final ChildMarriageResult? r = ChildMarriage.maybeMarry(
          child: cocuk(),
          playerAge: 50,
          rng: Random(seed),
        );
        if (r == null) continue;
        expect(r.notice.kind, NoticeKind.aileDonum);
        expect(r.notice.kind, isNot(NoticeKind.dogum));
        return;
      }
      fail('Hiç evlilik olmadı');
    });

    test('evlilik kaydı kapat-aç ile korunur', () {
      GameState s = taban();
      s = s.copyWith(people: <Person>[...s.people, cocuk(evli: true)]);
      final GameState geri = decodeGameState(encodeGameState(s));
      final Person geriCocuk = geri.personById('c1')!;
      expect(geriCocuk.development!.isMarried, isTrue);
      expect(geriCocuk.development!.spouseName, 'Kaan');
    });

    test('yaş büyüdükçe evlenme ihtimali artar', () {
      expect(
        ChildMarriage.chanceFor(35),
        greaterThan(ChildMarriage.chanceFor(23)),
      );
      expect(ChildMarriage.chanceFor(20), 0);
    });
  });

  group('İlgilenilmeyen flört biter (D-122)', () {
    Person flort({int bond = 20, String id = 'f1'}) => Person(
          id: id,
          firstName: 'Deniz',
          lastName: 'Ak',
          gender: Gender.kadin,
          relation: RelationType.flort,
          age: 28,
          isAlive: true,
          inPlayerHousehold: false,
          employment: EmploymentStatus.calisiyor,
          wealth: WealthTier.ortaHalli,
          bond: bond,
        );

    GameState ile(Person p, {int? sonTemas, int age = 30}) {
      final GameState s = taban(age: age);
      return s.copyWith(
        people: <Person>[...s.people, p],
        lastInteractionAge: <String, int>{
          if (sonTemas != null) p.id: sonTemas,
        },
      );
    }

    test('yakınlık düşük ve uzun süre görüşülmediyse biter', () {
      final GameState s = ile(flort(), sonTemas: 26, age: 30);
      final ({GameState state, List<PendingNotice> notices}) r =
          Finger.endNeglectedFlirts(s, 30);
      expect(r.notices, hasLength(1));
      expect(r.notices.single.title, 'Flörtün bitti');
      // Kayıt silinmez: kişi arkadaş olarak kalır.
      expect(r.state.personById('f1')!.relation, RelationType.arkadas);
    });

    test('yakınlık yüksekse bitmez', () {
      final GameState s = ile(flort(bond: 70), sonTemas: 20, age: 30);
      final ({GameState state, List<PendingNotice> notices}) r =
          Finger.endNeglectedFlirts(s, 30);
      expect(r.notices, isEmpty);
      expect(r.state.personById('f1')!.relation, RelationType.flort);
    });

    test('yeni görüşülmüşse bitmez', () {
      final GameState s = ile(flort(), sonTemas: 30, age: 30);
      final ({GameState state, List<PendingNotice> notices}) r =
          Finger.endNeglectedFlirts(s, 30);
      expect(r.notices, isEmpty);
      expect(r.state.personById('f1')!.relation, RelationType.flort);
    });

    test('sevgili ve eş bu kuraldan etkilenmez', () {
      final Person sevgili = flort(id: 's1').copyWith(
        relation: RelationType.sevgili,
      );
      final GameState s = ile(sevgili, sonTemas: 20, age: 30);
      final ({GameState state, List<PendingNotice> notices}) r =
          Finger.endNeglectedFlirts(s, 30);
      expect(r.notices, isEmpty);
      expect(r.state.personById('s1')!.relation, RelationType.sevgili);
    });
  });
}
