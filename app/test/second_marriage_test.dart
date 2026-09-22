import 'dart:math';

import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/data/wedding_catalog.dart';
import 'package:bir_omur/domain/interaction/marriage_engine.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/marriage.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:flutter_test/flutter_test.dart';

const MarriageEngine motor = MarriageEngine();

Person sevgili(String id, String ad, {int age = 30}) => Person(
      id: id,
      firstName: ad,
      lastName: 'Yaman',
      gender: Gender.kadin,
      relation: RelationType.sevgili,
      age: age,
      isAlive: true,
      inPlayerHousehold: false,
      employment: EmploymentStatus.calisiyor,
      occupation: 'öğretmen',
      wealth: WealthTier.ortaHalli,
      bond: 85,
    );

/// Erkek oyuncu, yanında bir sevgiliyle.
GameState hayat({int age = 30, int wallet = 1000000}) {
  for (int seed = 0; seed < 200; seed++) {
    final GameState taban =
        LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
    if (taban.player.gender != Gender.erkek) continue;
    final List<Person> kisiler = taban.people
        .where((Person p) =>
            p.relation != RelationType.sevgili && p.relation != RelationType.es)
        .toList(growable: true)
      ..add(sevgili('sevgili-1', 'Elif'));
    return taban.copyWith(
      pendingEvent: null,
      notices: const <PendingNotice>[],
      people: List<Person>.unmodifiable(kisiler),
      player: taban.player.copyWith(age: age, wallet: wallet),
    );
  }
  throw StateError('Uygun hayat bulunamadı');
}

/// Evlendirir, sonra boşar.
GameState evlenVeBosan(GameState s) {
  final GameState evli = motor.marry(s, 'sevgili-1').state;
  expect(evli.isMarried, isTrue);
  final GameState bosanmis = motor.divorce(evli).state;
  expect(bosanmis.isMarried, isFalse);
  return bosanmis;
}

void main() {
  group('İkinci evlilik açıldı', () {
    test('yürüyen evlilikte ikinci evlilik hâlâ engelli', () {
      final GameState evli = motor.marry(hayat(), 'sevgili-1').state;
      final GameState ikinci = evli.copyWith(
        people: <Person>[...evli.people, sevgili('sevgili-2', 'Derya')],
      );
      final String engel = motor.marryBlockReason(
        ikinci,
        ikinci.personById('sevgili-2')!,
      );
      expect(engel, 'Zaten evlisin.');
    });

    test('boşanan yeniden evlenebilir', () {
      GameState s = evlenVeBosan(hayat());
      s = s.copyWith(
        people: <Person>[...s.people, sevgili('sevgili-2', 'Derya')],
      );
      expect(
        motor.marryBlockReason(s, s.personById('sevgili-2')!),
        isEmpty,
      );
      final FamilyResult r = motor.marry(s, 'sevgili-2');
      expect(r.outcome.applied, isTrue);
      expect(r.state.isMarried, isTrue);
      expect(r.state.marriage!.spouseId, 'sevgili-2');
    });

    test('dul kalan yeniden evlenebilir', () {
      GameState s = motor.marry(hayat(), 'sevgili-1').state;
      // Eş vefat eder; kayıt "dul" olur.
      s = s.copyWith(
        people: s.people
            .map((Person p) =>
                p.id == 'sevgili-1' ? p.copyWith(isAlive: false) : p)
            .toList(growable: false),
        marriage: s.marriage!.copyWith(
          status: MarriageStatus.dul,
          endedAtAge: s.player.age,
        ),
      );
      expect(s.isMarried, isFalse);
      s = s.copyWith(
        people: <Person>[...s.people, sevgili('sevgili-2', 'Derya')],
      );
      expect(
        motor.marryBlockReason(s, s.personById('sevgili-2')!),
        isEmpty,
      );
      expect(motor.marry(s, 'sevgili-2').state.isMarried, isTrue);
    });
  });

  group('Eski kayıt silinmez', () {
    GameState ikiEvlilik() {
      GameState s = evlenVeBosan(hayat());
      s = s.copyWith(
        people: <Person>[...s.people, sevgili('sevgili-2', 'Derya')],
      );
      return motor.marry(s, 'sevgili-2').state;
    }

    test('ilk evlilik geçmişe taşınır, üzerine yazılmaz', () {
      final GameState s = ikiEvlilik();
      expect(s.pastMarriages, hasLength(1));
      expect(s.pastMarriages.first.spouseId, 'sevgili-1');
      expect(s.pastMarriages.first.status, MarriageStatus.bosandi);
      expect(s.marriage!.spouseId, 'sevgili-2');
      expect(s.marriageCount, 2);
    });

    test('eski eşin evlilik kaydı hâlâ okunabilir', () {
      final GameState s = ikiEvlilik();
      expect(s.marriageWith('sevgili-1'), isNotNull);
      expect(s.marriageWith('sevgili-1')!.status, MarriageStatus.bosandi);
      expect(s.marriageWith('sevgili-2')!.status, MarriageStatus.evli);
      expect(s.marriageWith('yok-boyle-biri'), isNull);
    });

    test('eski eş kişi listesinde eski eş olarak kalır', () {
      final GameState s = ikiEvlilik();
      final Person eski = s.personById('sevgili-1')!;
      expect(eski.relation, RelationType.eskiEs);
      expect(s.personById('sevgili-2')!.relation, RelationType.es);
    });

    test('üçüncü evlilikte geçmiş birikir', () {
      GameState s = ikiEvlilik();
      s = motor.divorce(s).state;
      s = s.copyWith(
        people: <Person>[...s.people, sevgili('sevgili-3', 'Nehir')],
      );
      s = motor.marry(s, 'sevgili-3').state;
      expect(s.pastMarriages, hasLength(2));
      expect(s.marriageCount, 3);
      expect(
        s.pastMarriages.map((Marriage m) => m.spouseId),
        <String>['sevgili-1', 'sevgili-2'],
      );
    });

    test('yürüyen evlilik hiçbir zaman arşive girmez', () {
      final GameState s = motor.marry(hayat(), 'sevgili-1').state;
      expect(s.pastMarriages, isEmpty);
    });

    test('geçmiş evlilikler kayda girer', () {
      final GameState s = ikiEvlilik();
      final GameState geri = decodeGameState(encodeGameState(s));
      expect(geri.pastMarriages, hasLength(1));
      expect(geri.pastMarriages.first.spouseId, 'sevgili-1');
      expect(geri.pastMarriages.first.marriedAtAge,
          s.pastMarriages.first.marriedAtAge);
      expect(geri.pastMarriages.first.endedAtAge,
          s.pastMarriages.first.endedAtAge);
      expect(geri.marriage!.spouseId, 'sevgili-2');
    });

    test('eski kayıtta alan yoksa boş okunur', () {
      final Map<String, Object?> json =
          Map<String, Object?>.from(encodeGameState(hayat()));
      json.remove('pastMarriages');
      expect(decodeGameState(json).pastMarriages, isEmpty);
    });
  });

  group('Miras ve aile durumu bozulmaz', () {
    test('ikinci evlilikte mirasçı yeni eştir, boşanılan değil', () {
      GameState s = evlenVeBosan(hayat());
      s = s.copyWith(
        people: <Person>[...s.people, sevgili('sevgili-2', 'Derya')],
      );
      s = motor.marry(s, 'sevgili-2').state;

      // D-037: boşanılan eş mirasçı değildir. Kayıt "evli" ve yeni eşi
      // gösteriyorsa bu kural doğru işler.
      expect(s.marriage!.status, MarriageStatus.evli);
      expect(s.spouse!.id, 'sevgili-2');
    });

    test('boşandıktan sonra tekrar evlenmeden eş yok', () {
      final GameState s = evlenVeBosan(hayat());
      expect(s.isMarried, isFalse);
      expect(s.marriage!.status, MarriageStatus.bosandi);
    });
  });

  test('ikinci evlilik de düğün seçimiyle yapılabilir', () {
    GameState s = evlenVeBosan(hayat());
    s = s.copyWith(
      people: <Person>[...s.people, sevgili('sevgili-2', 'Derya')],
    );
    final ({bool kabul, GameState state}) teklif = (
      kabul: true,
      state: motor.propose(s, 'sevgili-2', Random(1)).state,
    );
    // Teklif kabul edilmediyse bu testin konusu değil; kabul edilene kadar ara.
    GameState aday = teklif.state;
    for (int seed = 0; !aday.hasPendingWedding && seed < 60; seed++) {
      aday = motor.propose(s, 'sevgili-2', Random(seed)).state;
    }
    expect(aday.hasPendingWedding, isTrue, reason: 'Teklif hiç kabul edilmedi');

    final FamilyResult dugun = motor.holdWedding(aday, kFreeWedding.id);
    expect(dugun.outcome.applied, isTrue);
    expect(dugun.state.isMarried, isTrue);
    expect(dugun.state.pastMarriages, hasLength(1));
  });
}
