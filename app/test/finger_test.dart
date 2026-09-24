import 'dart:math';

import 'package:bir_omur/data/finger_catalog.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/domain/interaction/finger.dart';
import 'package:bir_omur/domain/interaction/romance.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/finger_profile.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:flutter_test/flutter_test.dart';

GameState hayat({int age = 25, int appearance = 50, int charisma = 50}) {
  final GameState taban =
      LifeGenerator.seeded(12).generate(mode: StartMode.tamamenRastgele);
  return taban.copyWith(
    pendingEvent: null,
    notices: const <PendingNotice>[],
    player: taban.player.copyWith(
      age: age,
      stats: taban.player.stats.copyWith(
        appearance: appearance,
        charisma: charisma,
      ),
    ),
  );
}

/// Sevgilisi olmayan bir hayat bulur.
GameState bekarHayat({int age = 25}) {
  const Romance romance = Romance();
  GameState s = hayat(age: age);
  if (romance.hasPartner(s)) {
    s = s.copyWith(
      people: s.people
          .where((Person p) => p.relation != RelationType.sevgili)
          .toList(growable: false),
    );
  }
  return s;
}

void main() {
  group('Deste', () {
    test('ekran açılınca deste dolar', () {
      final GameState s = Finger.ensureDeck(hayat(), Random(1));
      expect(s.fingerDeck, hasLength(kFingerDeckSize));
      for (final FingerProfile p in s.fingerDeck) {
        expect(p.firstName, isNotEmpty);
        expect(p.bio, isNotEmpty);
        expect(p.interests, isNotEmpty);
        expect(p.age, greaterThanOrEqualTo(18));
      }
    });

    test('deste doluyken yeniden karılmaz', () {
      final GameState s = Finger.ensureDeck(hayat(), Random(1));
      final GameState tekrar = Finger.ensureDeck(s, Random(2));
      expect(identical(tekrar, s), isTrue);
      expect(tekrar.fingerDeck.first.id, s.fingerDeck.first.id);
    });

    test('profil kimlikleri çakışmaz', () {
      GameState s = Finger.ensureDeck(hayat(), Random(3));
      for (int i = 0; i < 12; i++) {
        s = Finger.pass(s, s.fingerDeck.first.id, Random(i)).state;
      }
      final Set<String> kimlikler = <String>{
        for (final FingerProfile p in s.fingerDeck) p.id,
        for (final FingerProfile p in s.fingerMatches) p.id,
      };
      expect(
        kimlikler.length,
        s.fingerDeck.length + s.fingerMatches.length,
      );
    });

    test('18 yaşından küçüğe açılmaz', () {
      final GameState s = hayat(age: 16);
      expect(Finger.availability(s).isAllowed, isFalse);
      expect(Finger.ensureDeck(s, Random(1)).fingerDeck, isEmpty);
    });
  });

  group('Kaydırma', () {
    test('geçilen profil desteden çıkar ve yerine yenisi gelir', () {
      final GameState s = Finger.ensureDeck(hayat(), Random(4));
      final String ilk = s.fingerDeck.first.id;
      final FingerResult r = Finger.pass(s, ilk, Random(5));

      expect(r.outcome.applied, isTrue);
      expect(r.state.fingerDeck.any((FingerProfile p) => p.id == ilk), isFalse);
      expect(r.state.fingerDeck, hasLength(kFingerDeckSize));
      expect(Finger.swipesThisAge(r.state), 1);
    });

    test('yıllık kaydırma sınırı vardır', () {
      GameState s = Finger.ensureDeck(hayat(), Random(6));
      for (int i = 0; i < kFingerMaxSwipesPerAge; i++) {
        s = Finger.pass(s, s.fingerDeck.first.id, Random(i)).state;
      }
      expect(Finger.swipeAvailability(s).isAllowed, isFalse);
      final FingerResult r = Finger.pass(s, s.fingerDeck.first.id, Random(1));
      expect(r.outcome.applied, isFalse);
      expect(r.outcome.text, contains('seneye'));
    });

    test('beğeni her zaman karşılık bulmaz', () {
      int eslesme = 0;
      for (int seed = 0; seed < 60; seed++) {
        final GameState s = Finger.ensureDeck(hayat(), Random(seed));
        final FingerResult r =
            Finger.like(s, s.fingerDeck.first.id, Random(seed));
        if (r.outcome.matched) eslesme++;
      }
      expect(eslesme, greaterThan(0), reason: 'Hiç eşleşme olmadı');
      expect(eslesme, lessThan(60), reason: 'Her beğeni tutuyor');
    });

    test('görünüş ve karizma eşleşme ihtimalini yükseltir', () {
      final double dusuk =
          Finger.matchChance(hayat(appearance: 10, charisma: 10));
      final double yuksek =
          Finger.matchChance(hayat(appearance: 95, charisma: 95));
      expect(yuksek, greaterThan(dusuk));
      expect(dusuk, greaterThan(0), reason: 'Kimse sıfır ihtimalle kalmaz');
      expect(yuksek, lessThan(1), reason: 'Kimse kesin eşleşmez');
    });

    test('eşleşen profil eşleşme listesine düşer', () {
      for (int seed = 0; seed < 60; seed++) {
        final GameState s =
            Finger.ensureDeck(hayat(appearance: 95, charisma: 95), Random(seed));
        final String id = s.fingerDeck.first.id;
        final FingerResult r = Finger.like(s, id, Random(seed));
        if (!r.outcome.matched) continue;
        expect(r.state.fingerMatches.map((FingerProfile p) => p.id), contains(id));
        expect(r.state.fingerMatches.first.matchedAtAge, s.player.age);
        return;
      }
      fail('Hiç eşleşme olmadı');
    });
  });

  group('Tanışmak', () {
    GameState eslesmisHayat({bool bekar = true}) {
      GameState s = Finger.ensureDeck(
        bekar ? bekarHayat() : hayat(),
        Random(9),
      );
      for (int seed = 0; seed < 200; seed++) {
        final FingerResult r =
            Finger.like(s, s.fingerDeck.first.id, Random(seed));
        s = r.state;
        if (s.fingerMatches.isNotEmpty) return s;
      }
      fail('Eşleşme kurulamadı');
    }

    test('eşleşmeden önce kimse hayata girmez', () {
      final GameState s = Finger.ensureDeck(bekarHayat(), Random(10));
      final int once = s.people.length;
      Finger.pass(s, s.fingerDeck.first.id, Random(1));
      expect(s.people.length, once);
    });

    test('bekârsa tanışılan kişi flört olur, sevgili olmaz (D-107)', () {
      GameState s = eslesmisHayat();
      // Niyet "arkadaşlık" değilse buluşma flörtle sonuçlanır.
      s = s.copyWith(fingerIntent: FingerIntent.ciddi);
      s = s.copyWith(
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
                  intent: FingerIntent.ciddi,
                  wealth: p.wealth,
                  matchedAtAge: p.matchedAtAge,
                  metPersonId: p.metPersonId,
                ))
            .toList(growable: false),
      );
      final FingerResult r =
          Finger.meet(s, s.fingerMatches.first.id, Random(2));

      expect(r.outcome.applied, isTrue);
      expect(r.outcome.person, isNotNull);
      expect(r.outcome.person!.relation, RelationType.flort);
      expect(r.state.people.length, s.people.length + 1);
      expect(r.state.fingerMatches.first.isMet, isTrue);
      expect(r.state.log.last.text, contains('Finger'));
    });

    test('sevgilisi olan biri eşleşmeyle yeni sevgili edinmez', () {
      GameState s = eslesmisHayat();
      // Önce biriyle tanışıp flört ol, sonra sevgili yap.
      final FingerResult ilk =
          Finger.meet(s, s.fingerMatches.first.id, Random(3));
      s = ilk.state;
      if (ilk.outcome.person!.relation == RelationType.flort) {
        s = s.copyWith(
          people: s.people
              .map((Person p) => p.id == ilk.outcome.person!.id
                  ? p.copyWith(relation: RelationType.sevgili, bond: 70)
                  : p)
              .toList(growable: false),
        );
      }
      // D-081 ile bir yılda atılabilecek beğeni sayısı sınırlandı.
      // Bu test tanışma kuralını sınıyor, beğeni kotasını değil; bu
      // yüzden ikinci eşleşmeyi kurmak için premium üyelik kullanılır
      // (oyunda da açık olan yol).
      s = s.copyWith(fingerPremiumUntilAge: s.player.age);
      // Sonra ikinci bir eşleşme kur.
      for (int seed = 0; seed < 200 && s.fingerMatches.length < 2; seed++) {
        s = Finger.like(s, s.fingerDeck.first.id, Random(seed)).state;
        s = Finger.ensureDeck(s, Random(seed));
      }
      final FingerProfile ikinci =
          s.fingerMatches.firstWhere((FingerProfile p) => !p.isMet);
      final FingerResult r = Finger.meet(s, ikinci.id, Random(4));

      expect(r.outcome.person!.relation, RelationType.arkadas,
          reason: 'Uygulama var olan ilişkiyi kendiliğinden bitirmemeli');
    });

    test('aynı eşleşmeyle iki kez tanışılmaz', () {
      GameState s = eslesmisHayat();
      final String id = s.fingerMatches.first.id;
      s = Finger.meet(s, id, Random(5)).state;
      final int kisiSayisi = s.people.length;

      final FingerResult tekrar = Finger.meet(s, id, Random(6));
      expect(tekrar.outcome.applied, isFalse);
      expect(tekrar.state.people.length, kisiSayisi);
    });

    test('eşleşilmeyen profille tanışılmaz', () {
      final GameState s = Finger.ensureDeck(bekarHayat(), Random(11));
      final FingerResult r =
          Finger.meet(s, s.fingerDeck.first.id, Random(1));
      expect(r.outcome.applied, isFalse);
      expect(r.state.people.length, s.people.length);
    });

    test('tanışılan kişi kişi listesinde kalıcıdır', () {
      final GameState s = eslesmisHayat();
      final FingerResult r =
          Finger.meet(s, s.fingerMatches.first.id, Random(7));
      final String id = r.outcome.person!.id;
      final GameState geri = decodeGameState(encodeGameState(r.state));
      expect(geri.personById(id), isNotNull);
    });
  });

  test('deste ve eşleşmeler kayda girer', () {
    final GameState s = Finger.ensureDeck(hayat(), Random(13));
    final GameState geri = decodeGameState(encodeGameState(s));
    expect(geri.fingerDeck, hasLength(s.fingerDeck.length));
    expect(geri.fingerDeck.first.id, s.fingerDeck.first.id);
    expect(geri.fingerDeck.first.bio, s.fingerDeck.first.bio);
    expect(geri.fingerDeck.first.interests, s.fingerDeck.first.interests);
  });

  test('eski kayıtta Finger alanı yoksa boş okunur', () {
    final Map<String, Object?> json =
        Map<String, Object?>.from(encodeGameState(hayat()));
    json.remove('fingerDeck');
    json.remove('fingerMatches');
    final GameState geri = decodeGameState(json);
    expect(geri.fingerDeck, isEmpty);
    expect(geri.fingerMatches, isEmpty);
  });

  test('profil metinleri özgün havuzdan gelir', () {
    final GameState s = Finger.ensureDeck(hayat(), Random(14));
    for (final FingerProfile p in s.fingerDeck) {
      expect(kFingerBios, contains(p.bio));
      for (final String i in p.interests) {
        expect(kFingerInterests, contains(i));
      }
    }
  });
}
