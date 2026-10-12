import 'dart:math';

import 'package:bir_omur/data/finger_catalog.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/interaction/finger.dart';
import 'package:bir_omur/domain/interaction/romance.dart';
import 'package:bir_omur/domain/models/finger_profile.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:flutter_test/flutter_test.dart';

/// Paket L: Finger'da niyet, flört ve süzgeç (D-107).
void main() {
  GameState bekar({int age = 25}) {
    final GameState taban =
        LifeGenerator.seeded(12).generate(mode: StartMode.tamamenRastgele);
    final GameState s = taban.copyWith(
      pendingEvent: null,
      notices: const <PendingNotice>[],
      player: taban.player.copyWith(age: age),
    );
    return s.copyWith(
      people: s.people
          .where((Person p) => p.relation != RelationType.sevgili)
          .toList(growable: false),
    );
  }

  /// Verilen niyetle bir eşleşme kurar.
  GameState eslesmis({
    required FingerIntent oyuncu,
    required FingerIntent karsi,
  }) {
    GameState s = Finger.ensureDeck(
      bekar().copyWith(fingerIntent: oyuncu),
      Random(9),
    );
    for (int seed = 0; seed < 300; seed++) {
      s = Finger.like(s, s.fingerDeck.first.id, Random(seed)).state;
      s = Finger.ensureDeck(s, Random(seed));
      if (s.fingerMatches.isNotEmpty) break;
    }
    expect(s.fingerMatches, isNotEmpty, reason: 'Eşleşme kurulamadı');
    return s.copyWith(
      fingerMatches: s.fingerMatches
          .map((FingerProfile p) => FingerProfile(
                id: p.id,
                firstName: p.firstName,
                lastName: p.lastName,
                gender: p.gender,
                age: p.age,
                city: p.city,
                bio: p.bio,
                interests: p.interests,
                occupation: p.occupation,
                intent: karsi,
                wealth: p.wealth,
                matchedAtAge: p.matchedAtAge,
                metPersonId: p.metPersonId,
              ))
          .toList(growable: false),
    );
  }

  group('Tanışmak sevgili olmak değildir (D-107)', () {
    test('iki taraf da ciddiyse flört başlar', () {
      final GameState s = eslesmis(
        oyuncu: FingerIntent.ciddi,
        karsi: FingerIntent.ciddi,
      );
      final FingerResult r = Finger.meet(s, s.fingerMatches.first.id, Random(2));
      expect(r.outcome.person!.relation, RelationType.flort);
      expect(r.outcome.text, contains('sevgili'));
      // Flört romantik ilişki işareti koymaz.
      expect(const Romance().hasPartner(r.state), isFalse);
    });

    test('karşı taraf arkadaşlık arıyorsa arkadaş kalınır', () {
      final GameState s = eslesmis(
        oyuncu: FingerIntent.ciddi,
        karsi: FingerIntent.arkadaslik,
      );
      final FingerResult r = Finger.meet(s, s.fingerMatches.first.id, Random(2));
      expect(r.outcome.person!.relation, RelationType.arkadas);
      expect(r.outcome.text, contains('arkadaş'));
    });

    test('oyuncu arkadaşlık arıyorsa flört başlamaz', () {
      final GameState s = eslesmis(
        oyuncu: FingerIntent.arkadaslik,
        karsi: FingerIntent.ciddi,
      );
      final FingerResult r = Finger.meet(s, s.fingerMatches.first.id, Random(2));
      expect(r.outcome.person!.relation, RelationType.arkadas);
    });
  });

  group('Flörtten sevgiliye (D-107)', () {
    GameState flortluHayat() {
      final GameState s = eslesmis(
        oyuncu: FingerIntent.ciddi,
        karsi: FingerIntent.ciddi,
      );
      return Finger.meet(s, s.fingerMatches.first.id, Random(2)).state;
    }

    test('yakınlık yetmezse teklif geri çevrilir ve sebebi yazar', () {
      GameState s = flortluHayat();
      final Person flort =
          s.people.firstWhere((Person p) => p.relation == RelationType.flort);
      s = s.copyWith(
        people: s.people
            .map((Person p) => p.id == flort.id ? p.copyWith(bond: 20) : p)
            .toList(growable: false),
      );
      final FingerResult r = Finger.makeOfficial(s, flort.id);
      expect(r.outcome.applied, isFalse);
      expect(r.outcome.text, contains('yakınlık'));
      expect(
        r.state.personById(flort.id)!.relation,
        RelationType.flort,
      );
    });

    test('yakınlık yeterliyse sevgili olunur', () {
      GameState s = flortluHayat();
      final Person flort =
          s.people.firstWhere((Person p) => p.relation == RelationType.flort);
      s = s.copyWith(
        people: s.people
            .map((Person p) => p.id == flort.id
                ? p.copyWith(bond: Finger.prototypeOnlyOfficialBond)
                : p)
            .toList(growable: false),
      );
      final FingerResult r = Finger.makeOfficial(s, flort.id);
      expect(r.outcome.applied, isTrue);
      expect(r.state.personById(flort.id)!.relation, RelationType.sevgili);
      expect(const Romance().hasPartner(r.state), isTrue);
      expect(r.state.log.last.text, contains('sevgili'));
    });

    test('hayatında biri varken flört sevgiliye dönmez', () {
      GameState s = flortluHayat();
      final Person flort =
          s.people.firstWhere((Person p) => p.relation == RelationType.flort);
      // Başka bir sevgili ekle.
      s = s.copyWith(
        people: List<Person>.unmodifiable(<Person>[
          ...s.people.map((Person p) => p.id == flort.id
              ? p.copyWith(bond: 90)
              : p),
          flort.copyWith(relation: RelationType.sevgili),
        ]),
      );
      final FingerResult r = Finger.makeOfficial(s, flort.id);
      expect(r.outcome.applied, isFalse);
      expect(r.outcome.text, contains('zaten'));
    });
  });

  group('Ekonomik durum süzgeci (D-107)', () {
    test('süzgeç açıkken yalnızca o kademeden aday çıkar', () {
      for (final WealthTier tier in WealthTier.values) {
        final GameState s = Finger.ensureDeck(
          bekar().copyWith(fingerWealthFilter: tier),
          Random(4),
        );
        expect(s.fingerDeck, isNotEmpty, reason: '${tier.label} için aday yok');
        for (final FingerProfile p in s.fingerDeck) {
          expect(p.wealth, tier);
        }
      }
    });

    test('süzgeç kapalıyken farklı kademeler görünür', () {
      GameState s = bekar();
      final Set<WealthTier> gorulen = <WealthTier>{};
      for (int i = 0; i < 40; i++) {
        s = Finger.ensureDeck(s, Random(i));
        gorulen.addAll(s.fingerDeck.map((FingerProfile p) => p.wealth));
        s = Finger.pass(s, s.fingerDeck.first.id, Random(i)).state;
      }
      expect(gorulen.length, greaterThan(1));
    });

    test('süzgeç değişince eski deste elenir', () {
      final GameState acik = Finger.ensureDeck(bekar(), Random(7));
      final GameState suzulmus = Finger.ensureDeck(
        acik.copyWith(fingerWealthFilter: WealthTier.cokVarlikli),
        Random(7),
      );
      for (final FingerProfile p in suzulmus.fingerDeck) {
        expect(p.wealth, WealthTier.cokVarlikli);
      }
    });
  });

  test('beğeni kotası 12, premiumda 30 (Q-121 kararı)', () {
    expect(kFingerMaxLikesPerAge, 12);
    expect(kFingerPremiumLikesPerAge, 30);
    final GameState s = bekar();
    expect(Finger.likeLimit(s), 12);
    expect(
      Finger.likeLimit(s.copyWith(fingerPremiumUntilAge: s.player.age)),
      30,
    );
  });

  test('niyet, süzgeç ve flört kayıt açılıp kapandığında korunur', () {
    GameState s = eslesmis(
      oyuncu: FingerIntent.ciddi,
      karsi: FingerIntent.ciddi,
    );
    s = Finger.meet(s, s.fingerMatches.first.id, Random(2)).state;
    s = s.copyWith(fingerWealthFilter: WealthTier.varlikli);

    final GameState geri = decodeGameState(encodeGameState(s));
    expect(geri.fingerIntent, FingerIntent.ciddi);
    expect(geri.fingerWealthFilter, WealthTier.varlikli);
    expect(
      geri.people.any((Person p) => p.relation == RelationType.flort),
      isTrue,
    );
    expect(geri.fingerDeck.first.intent, s.fingerDeck.first.intent);
    expect(geri.fingerDeck.first.wealth, s.fingerDeck.first.wealth);
  });

  test('flört romantik bölümde listelenir, arkadaş bölümünde değil', () {
    expect(RelationType.flort.group, RelationGroup.romantik);
    expect(RelationType.flort.kanBagi, isFalse);
  });
}
