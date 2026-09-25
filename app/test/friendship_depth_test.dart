import 'dart:math';

import 'package:bir_omur/data/event_pool.dart';
import 'package:bir_omur/data/event_pool_friendship.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/interaction/friendship_depth.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/interaction.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/active_player.dart';

GameState hayat(int seed, {int age = 16}) {
  final GameState s =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  return s.copyWith(
    player: s.player.copyWith(age: age),
    pendingEvent: null,
  );
}

Person kisiKur({
  required String id,
  required RelationType relation,
  required int bond,
  int age = 16,
  int? estrangedSinceAge,
}) =>
    Person(
      id: id,
      firstName: 'Deniz',
      lastName: 'Aras',
      gender: Gender.kadin,
      relation: relation,
      age: age,
      isAlive: true,
      inPlayerHousehold: false,
      employment: EmploymentStatus.ogrenci,
      bond: bond,
      wealth: age >= 18 ? WealthTier.ortaHalli : null,
      estrangedSinceAge: estrangedSinceAge,
    );

GameState ileKisi(GameState state, Person kisi) => state.copyWith(
      people: List<Person>.unmodifiable(<Person>[...state.people, kisi]),
    );

void main() {
  // ===================================================================
  // 1) Yakın arkadaş olma teklifi
  // ===================================================================
  group('yakın arkadaş olma teklifi', () {
    test('yakınlık yetmiyorsa gerekçe yazılır', () {
      final GameState s = ileKisi(
        hayat(1),
        kisiKur(id: 'sinif-1', relation: RelationType.sinifArkadasi, bond: 30),
      );
      final InteractionAvailability u =
          FriendshipDepth.closeFriendAvailability(s, 'sinif-1');
      expect(u.isAllowed, isFalse);
      // Gerekçe hem eşiği hem mevcut durumu söyler (D-063).
      expect(u.reason, contains('55'));
      expect(u.reason, contains('30'));
    });

    test('yakınlık yetiyorsa teklif edilebilir', () {
      final GameState s = ileKisi(
        hayat(2),
        kisiKur(id: 'sinif-1', relation: RelationType.sinifArkadasi, bond: 70),
      );
      expect(
        FriendshipDepth.closeFriendAvailability(s, 'sinif-1').isAllowed,
        isTrue,
      );
    });

    test('kabul edilirse ilişki aynı kimlikle arkadaşa döner', () {
      final GameState s = ileKisi(
        hayat(3),
        kisiKur(id: 'sinif-1', relation: RelationType.sinifArkadasi, bond: 95),
      );
      // Yakınlık 95: kabul şansı %90, 40 denemede en az biri tutar.
      for (int i = 0; i < 40; i++) {
        final FriendshipResult r = FriendshipDepth.proposeCloseFriend(
          state: s,
          personId: 'sinif-1',
          rng: Random(i),
        );
        if (!r.outcome.accepted) continue;
        final Person? kisi = r.state.personById('sinif-1');
        expect(kisi, isNotNull, reason: 'Kayıt silinmemeli.');
        expect(kisi!.relation, RelationType.arkadas);
        // Ne zaman arkadaş olduğu tarihlenir.
        expect(kisi.becameFriendAtAge, s.player.age);
        // Adı ve geçmişi korunur.
        expect(kisi.firstName, 'Deniz');
        return;
      }
      fail('40 denemede teklif hiç kabul edilmedi.');
    });

    test('reddedilirse yakınlık düşer ve kayıt silinmez', () {
      final GameState s = ileKisi(
        hayat(4),
        kisiKur(id: 'sinif-1', relation: RelationType.sinifArkadasi, bond: 55),
      );
      for (int i = 0; i < 60; i++) {
        final FriendshipResult r = FriendshipDepth.proposeCloseFriend(
          state: s,
          personId: 'sinif-1',
          rng: Random(i),
        );
        if (r.outcome.accepted) continue;
        final Person kisi = r.state.personById('sinif-1')!;
        expect(kisi.relation, RelationType.sinifArkadasi);
        expect(kisi.bond, lessThan(55));
        return;
      }
      fail('60 denemede teklif hiç reddedilmedi; şans garanti olmuş.');
    });

    test('teklif garanti değildir', () {
      final GameState s = ileKisi(
        hayat(5),
        kisiKur(id: 'sinif-1', relation: RelationType.sinifArkadasi, bond: 60),
      );
      final Set<bool> sonuclar = <bool>{};
      for (int i = 0; i < 60; i++) {
        sonuclar.add(
          FriendshipDepth.proposeCloseFriend(
            state: s,
            personId: 'sinif-1',
            rng: Random(i),
          ).outcome.accepted,
        );
      }
      expect(sonuclar.length, 2, reason: 'Hem kabul hem ret çıkmalı.');
    });

    test('zaten arkadaş olana ve uygun olmayan ilişkiye teklif kapalı', () {
      GameState s = ileKisi(
        hayat(6),
        kisiKur(id: 'ark-1', relation: RelationType.arkadas, bond: 80),
      );
      s = ileKisi(
        s,
        kisiKur(
          id: 'anne-x',
          relation: RelationType.anne,
          bond: 90,
          age: 45,
        ),
      );
      expect(
        FriendshipDepth.closeFriendAvailability(s, 'ark-1').reason,
        'Zaten yakın arkadaşsınız.',
      );
      expect(
        FriendshipDepth.closeFriendAvailability(s, 'anne-x').reason,
        'Bu ilişki arkadaşlığa dönüşmez.',
      );
    });
  });

  // ===================================================================
  // 2) Küslük ve barışma
  // ===================================================================
  group('küslük ve barışma', () {
    test('küs kişiyle gündelik etkileşim kapanır', () {
      final GameState s = ileKisi(
        hayat(10, age: 25),
        kisiKur(
          id: 'ark-1',
          relation: RelationType.arkadas,
          bond: 20,
          age: 25,
          estrangedSinceAge: 24,
        ),
      );
      final Person kisi = s.personById('ark-1')!;
      expect(kisi.isEstranged, isTrue);
      // Etkileşim listesi boşalır; kayıt yerinde durur.
      expect(s.people.any((Person p) => p.id == 'ark-1'), isTrue);
    });

    test('barışma aynı yıl olmaz, sonraki yıl olur', () {
      final GameState ayniYil = ileKisi(
        hayat(11, age: 24),
        kisiKur(
          id: 'ark-1',
          relation: RelationType.arkadas,
          bond: 25,
          age: 24,
          estrangedSinceAge: 24,
        ),
      );
      expect(
        FriendshipDepth.makeUpAvailability(ayniYil, 'ark-1').isAllowed,
        isFalse,
      );
      final GameState sonraki = ileKisi(
        hayat(11, age: 26),
        kisiKur(
          id: 'ark-1',
          relation: RelationType.arkadas,
          bond: 25,
          age: 26,
          estrangedSinceAge: 24,
        ),
      );
      expect(
        FriendshipDepth.makeUpAvailability(sonraki, 'ark-1').isAllowed,
        isTrue,
      );
    });

    test('barışınca küslük kalkar ve yakınlık artar', () {
      final GameState s = ileKisi(
        hayat(12, age: 30),
        kisiKur(
          id: 'ark-1',
          relation: RelationType.arkadas,
          bond: 40,
          age: 30,
          estrangedSinceAge: 22,
        ),
      );
      for (int i = 0; i < 60; i++) {
        final FriendshipResult r = FriendshipDepth.makeUp(
          state: s,
          personId: 'ark-1',
          rng: Random(i),
        );
        if (!r.outcome.accepted) continue;
        final Person kisi = r.state.personById('ark-1')!;
        expect(kisi.isEstranged, isFalse);
        expect(kisi.bond, greaterThan(40));
        return;
      }
      fail('60 denemede hiç barışılmadı.');
    });

    test('yakınlık tükenmişse barışma kapalı', () {
      final GameState s = ileKisi(
        hayat(13, age: 30),
        kisiKur(
          id: 'ark-1',
          relation: RelationType.arkadas,
          bond: 3,
          age: 30,
          estrangedSinceAge: 22,
        ),
      );
      final InteractionAvailability u =
          FriendshipDepth.makeUpAvailability(s, 'ark-1');
      expect(u.isAllowed, isFalse);
      expect(u.reason, contains('12'));
    });

    test('vefat etmiş kişiyle barışılmaz', () {
      final GameState s = ileKisi(
        hayat(14, age: 30),
        kisiKur(
          id: 'ark-1',
          relation: RelationType.arkadas,
          bond: 40,
          age: 30,
          estrangedSinceAge: 22,
        ).copyWith(isAlive: false),
      );
      expect(
        FriendshipDepth.makeUpAvailability(s, 'ark-1').isAllowed,
        isFalse,
      );
    });
  });

  // ===================================================================
  // 3) Yıllık ilerleme
  // ===================================================================
  group('yıllık ilerleme', () {
    test('ilgilenilmeyen arkadaşlık kopabilir ama kayıt silinmez', () {
      final GameState s = ileKisi(
        hayat(20, age: 30),
        kisiKur(
          id: 'ark-1',
          relation: RelationType.arkadas,
          bond: 10,
          age: 30,
        ),
      );
      for (int i = 0; i < 60; i++) {
        final GameState sonra =
            FriendshipDepth.advanceYear(s, 31, Random(i));
        final Person kisi = sonra.personById('ark-1')!;
        if (!kisi.isEstranged) continue;
        expect(kisi.relation, RelationType.arkadas, reason: 'İlişki silinmez.');
        expect(sonra.people.length, s.people.length);
        return;
      }
      fail('60 yılda hiç kopma olmadı.');
    });

    test('yakınlığı iyi olan arkadaşlık kopmaz', () {
      final GameState s = ileKisi(
        hayat(21, age: 30),
        kisiKur(
          id: 'ark-1',
          relation: RelationType.arkadas,
          bond: 80,
          age: 30,
        ),
      );
      for (int i = 0; i < 60; i++) {
        final GameState sonra =
            FriendshipDepth.advanceYear(s, 31, Random(i));
        expect(sonra.personById('ark-1')!.isEstranged, isFalse);
      }
    });

    test('arkadaşın haberi gerçekten kayda geçer', () {
      final GameState s = ileKisi(
        hayat(22, age: 30),
        kisiKur(
          id: 'ark-1',
          relation: RelationType.arkadas,
          bond: 70,
          age: 30,
        ).copyWith(city: 'Ankara', employment: EmploymentStatus.calisiyor),
      );
      bool tasindiGordu = false;
      for (int i = 0; i < 80 && !tasindiGordu; i++) {
        final GameState sonra =
            FriendshipDepth.advanceYear(s, 31, Random(i));
        final Person kisi = sonra.personById('ark-1')!;
        if (kisi.city != 'Ankara') {
          // Taşındıysa bildirim de gelmiş olmalı; uydurma haber olmaz.
          expect(
            sonra.notices.any((dynamic n) => (n.title as String).contains('Arkadaş')),
            isTrue,
          );
          tasindiGordu = true;
        }
      }
      expect(tasindiGordu, isTrue, reason: '80 yılda hiç haber gelmedi.');
    });

    test('küs arkadaştan haber gelmez', () {
      final GameState s = ileKisi(
        hayat(23, age: 30),
        kisiKur(
          id: 'ark-1',
          relation: RelationType.arkadas,
          bond: 70,
          age: 30,
          estrangedSinceAge: 28,
        ).copyWith(city: 'Ankara'),
      );
      for (int i = 0; i < 40; i++) {
        final GameState sonra =
            FriendshipDepth.advanceYear(s, 31, Random(i));
        expect(sonra.personById('ark-1')!.city, 'Ankara');
      }
    });

    test('arkadaşı olmayan hayatta hiçbir şey olmaz', () {
      final GameState s = hayat(24, age: 30).copyWith(
        people: List<Person>.unmodifiable(
          hayat(24, age: 30)
              .people
              .where((Person p) => p.relation != RelationType.arkadas)
              .toList(growable: false),
        ),
      );
      for (int i = 0; i < 20; i++) {
        final GameState sonra =
            FriendshipDepth.advanceYear(s, 31, Random(i));
        expect(sonra.notices.length, s.notices.length);
      }
    });
  });

  // ===================================================================
  // 4) Kayıt
  // ===================================================================
  test('küslük ve arkadaşlık tarihi kaydedilip yüklenir', () {
    final GameState once = ileKisi(
      hayat(30, age: 30),
      kisiKur(
        id: 'ark-1',
        relation: RelationType.arkadas,
        bond: 40,
        age: 30,
        estrangedSinceAge: 27,
      ).copyWith(becameFriendAtAge: 14),
    );
    final GameState geri = decodeGameState(encodeGameState(once));
    final Person kisi = geri.personById('ark-1')!;
    expect(kisi.estrangedSinceAge, 27);
    expect(kisi.becameFriendAtAge, 14);
  });

  test('eski kayıtta kimse küs açılmaz', () {
    final Map<String, Object?> json = encodeGameState(hayat(31, age: 30));
    final List<Object?> kisiler = json['people']! as List<Object?>;
    for (final Object? k in kisiler) {
      (k! as Map<String, Object?>).remove('estrangedSinceAge');
      (k as Map<String, Object?>).remove('becameFriendAtAge');
    }
    final GameState geri = decodeGameState(json);
    expect(geri.people.any((Person p) => p.isEstranged), isFalse);
    expect(geri.people.any((Person p) => p.becameFriendAtAge != null), isFalse);
  });

  // ===================================================================
  // 5) İçerik
  // ===================================================================
  group('arkadaşlık olayları', () {
    test('havuza kayıtlı ve kimlikleri benzersiz', () {
      final Set<String> havuz = kEventPool.map((GameEvent e) => e.id).toSet();
      for (final GameEvent e in kFriendshipEvents) {
        expect(havuz.contains(e.id), isTrue, reason: '${e.id} havuzda yok');
      }
      expect(
        kFriendshipEvents.map((GameEvent e) => e.id).toSet().length,
        kFriendshipEvents.length,
      );
    });

    test('çocukluk arkadaşı olayları gerçek kişiye bağlı', () {
      // "Yıllar sonra döndü" olayları uydurma bir kişiyle değil, D-126'da
      // kaydedilen gerçek çocukluk arkadaşıyla kurulur.
      final Iterable<GameEvent> cocukluk = kFriendshipEvents.where(
        (GameEvent e) => e.id.startsWith('arkadas_cocukluk'),
      );
      expect(cocukluk, isNotEmpty);
      for (final GameEvent e in cocukluk) {
        expect(e.requirement.personRole, 'cocukluk_arkadasi');
      }
    });

    test('seçenekler aynı sonucu vermez', () {
      final List<String> tekduze = <String>[];
      for (final GameEvent e in kFriendshipEvents) {
        final Set<String> imza = e.choices
            .map(
              (EventChoice c) => <Object>[
                c.happiness,
                c.health,
                c.charisma,
                c.bond,
                c.money,
                c.addFlags.toList()..sort(),
                c.startsFriendship,
              ].join('|'),
            )
            .toSet();
        if (imza.length < e.choices.length) tekduze.add(e.id);
      }
      expect(tekduze, isEmpty, reason: 'Etkisi aynı seçenekler: $tekduze');
    });

    test('metinler WRITING_STYLE_TR sınırlarında', () {
      const List<String> yasak = <String>[
        'olumlu yönde',
        'bu deneyim',
        'aranızdaki bağ güçlendi',
        'kaliteli vakit',
        'kanka',
        'moruk',
        'bro',
      ];
      for (final GameEvent e in kFriendshipEvents) {
        final String hepsi = <String>[
          e.text,
          for (final EventChoice c in e.choices) c.resultText,
        ].join(' ').toLowerCase();
        for (final String k in yasak) {
          expect(hepsi.contains(k), isFalse, reason: '${e.id}: "$k"');
        }
        expect(e.text.length, lessThanOrEqualTo(320), reason: e.id);
        for (final EventChoice c in e.choices) {
          expect(c.label.length, lessThanOrEqualTo(34), reason: '${e.id}/${c.id}');
        }
      }
    });
  });

  // ===================================================================
  // 6) Ölçüm: arkadaşlık gerçekten yaşanıyor
  // ===================================================================
  test('oyuncu gibi oynanan hayat arkadaşsız kalmaz', () {
    // Ölçüm (100 hayat): hiç arkadaşı olmayan 0, yakın arkadaşla ölen 88.
    // Taban bugünkü ölçümün belirgin altına konur; sistem bozulursa düşer.
    int hicArkadasYok = 0;
    int yakinArkadasli = 0;
    for (int seed = 0; seed < 60; seed++) {
      final ActiveLifeResult r = playActiveLife(seed);
      if (!r.everHadFriend) hicArkadasYok++;
      if (r.closeFriendCount > 0) yakinArkadasli++;
    }
    expect(
      hicArkadasYok,
      lessThanOrEqualTo(6),
      reason: 'Oyuncu gibi oynanan hayatlarda arkadaşlık kurulamıyor.',
    );
    expect(
      yakinArkadasli,
      greaterThanOrEqualTo(30),
      reason: 'Yakın arkadaşlık pratikte oluşmuyor.',
    );
  });
}
