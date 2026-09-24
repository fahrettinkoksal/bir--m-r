import 'dart:math';

import 'package:bir_omur/data/activity_catalog.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/domain/activities/activity_engine.dart';
import 'package:bir_omur/domain/activities/outing.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/interaction/bond_decay.dart';
import 'package:bir_omur/domain/interaction/divorce_settlement.dart';
import 'package:bir_omur/domain/models/applied_effect.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/owned_item.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:flutter_test/flutter_test.dart';

/// Aktivite bildirimleri, kişilerin kendi keyfi ve boşanmada mal
/// paylaşımı (D-074, D-075).
///
/// Faho'nun isteği: "parka git, sinemaya git dediğimde bildirim olarak
/// karşıma çıksın; bana 5, kızıma 5 mutluluk, onunla aramdaki ilişki
/// iyileşti gibi" ve "boşandığımda ... mal varlığından şu kadar ona
/// gitti, ev ona gitti vb gibi yazmalı".
void main() {
  ActivityAction eylem(String id) =>
      kActivityActions.firstWhere((ActivityAction a) => a.id == id);

  Person kiz(String id, {int bond = 70, int happiness = 60, int age = 12}) =>
      Person(
        id: id,
        firstName: 'Elif',
        lastName: 'Demir',
        gender: Gender.kadin,
        relation: RelationType.cocuk,
        age: age,
        isAlive: true,
        inPlayerHousehold: true,
        employment: EmploymentStatus.ogrenci,
        wealth: null,
        bond: bond,
        happiness: happiness,
      );

  GameState hayat(int seed, {List<Person> ek = const <Person>[]}) {
    final GameState base =
        LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
    return base.copyWith(
      player: base.player.copyWith(age: 40, wallet: 900000),
      people: List<Person>.unmodifiable(<Person>[...base.people, ...ek]),
    );
  }

  group('Aktivite bildirimi', () {
    test('birlikte gidilen eğlence ekranda bildirim üretir', () {
      final GameState state = hayat(1, ek: <Person>[kiz('cocuk-1')]);
      final Person cocuk = state.personById('cocuk-1')!;

      final ActivityResult r = const ActivityEngine().perform(
        state: state,
        action: eylem('parkta_yuruyus'),
        rng: Random(1),
        companion: cocuk,
      );

      expect(r.outcome.applied, isTrue);
      final PendingNotice? bildirim = r.state.nextNotice;
      expect(bildirim, isNotNull, reason: 'Bildirim kuyruğa girmeli');
      expect(bildirim!.kind, NoticeKind.aktivite);
      expect(bildirim.personId, 'cocuk-1');
      expect(bildirim.effects, isNotEmpty);
    });

    test('bildirimde hem oyuncunun hem yoldaşın kazancı yazar', () {
      final GameState state = hayat(2, ek: <Person>[kiz('cocuk-2')]);
      final Person cocuk = state.personById('cocuk-2')!;

      final ActivityResult r = const ActivityEngine().perform(
        state: state,
        action: eylem('parkta_yuruyus'),
        rng: Random(2),
        companion: cocuk,
      );

      final List<String> etiketler = r.state.nextNotice!.effects
          .map((AppliedEffect e) => e.label)
          .toList(growable: false);

      expect(
        etiketler.any((String e) => e == 'Mutluluk'),
        isTrue,
        reason: 'Oyuncunun mutluluğu yazmalı: $etiketler',
      );
      expect(
        etiketler.any((String e) => e.contains('Elif için keyif')),
        isTrue,
        reason: 'Yoldaşın keyfi yazmalı: $etiketler',
      );
      expect(
        etiketler.any((String e) => e.contains('Elif ile yakınlık')),
        isTrue,
        reason: 'Yakınlık değişimi yazmalı: $etiketler',
      );
    });

    test('yoldaşın keyfi gerçekten yükselir', () {
      final GameState state = hayat(3, ek: <Person>[kiz('cocuk-3')]);
      final Person once = state.personById('cocuk-3')!;

      final ActivityResult r = const ActivityEngine().perform(
        state: state,
        action: eylem('sinema'),
        rng: Random(3),
        companion: once,
      );

      final Person sonra = r.state.personById('cocuk-3')!;
      expect(sonra.happiness, greaterThan(once.happiness));
      expect(sonra.bond, greaterThan(once.bond));
    });

    test('eğlence dışı eylem bildirim üretmez', () {
      final GameState state = hayat(4);
      final ActivityResult r = const ActivityEngine().perform(
        state: state,
        action: eylem('sac_kestir'),
        rng: Random(4),
      );
      expect(r.outcome.applied, isTrue);
      expect(r.state.notices, isEmpty,
          reason: 'Berber ekranı kesmemeli; kartındaki sonuç yeterli');
    });

    test('bildirim kapat-aç ile kaybolmaz ve etkileri korunur', () {
      final GameState state = hayat(5, ek: <Person>[kiz('cocuk-5')]);
      final ActivityResult r = const ActivityEngine().perform(
        state: state,
        action: eylem('kafede_otur'),
        rng: Random(5),
        companion: state.personById('cocuk-5')!,
      );

      final GameState geri = decodeGameState(encodeGameState(r.state));
      expect(geri.nextNotice, isNotNull);
      expect(geri.nextNotice!.kind, NoticeKind.aktivite);
      expect(
        geri.nextNotice!.effects.length,
        r.state.nextNotice!.effects.length,
      );
      expect(geri.nextNotice!.effects.first.label,
          r.state.nextNotice!.effects.first.label);
    });
  });

  group('Davet reddi (D-059)', () {
    test('keyfi düşük kişi daveti reddedebilir ve para gitmez', () {
      final GameState state =
          hayat(6, ek: <Person>[kiz('cocuk-6', happiness: 2, bond: 20)]);
      final Person cocuk = state.personById('cocuk-6')!;

      expect(
        Outing.refusalChance(state, eylem('sinema'), cocuk),
        greaterThan(0.3),
        reason: 'Keyfi çok düşük ve bağı zayıf kişide ret ihtimali olmalı',
      );

      final ActivityResult r = const ActivityEngine().perform(
        state: state,
        action: eylem('sinema'),
        rng: Random(6),
        companion: cocuk,
      );
      if (!r.outcome.applied) {
        expect(r.state.player.wallet, state.player.wallet,
            reason: 'Gerçekleşmeyen program ücretlendirilmez');
        expect(r.state.notices, isEmpty);
      }
    });

    test('bağı ve keyfi yerinde kişi ilk davette reddetmez', () {
      final GameState state =
          hayat(7, ek: <Person>[kiz('cocuk-7', happiness: 80, bond: 85)]);
      final Person cocuk = state.personById('cocuk-7')!;
      expect(Outing.refusalChance(state, eylem('sinema'), cocuk), 0.0);
      expect(
        Outing.refusalReason(state, eylem('sinema'), cocuk),
        isNull,
      );
    });

    test('ret kararı aynı yıl sabittir; tekrar tıklayarak zar atılamaz', () {
      final GameState state =
          hayat(8, ek: <Person>[kiz('cocuk-8', happiness: 5, bond: 15)]);
      final Person cocuk = state.personById('cocuk-8')!;
      final String? ilk = Outing.refusalReason(state, eylem('sinema'), cocuk);
      for (int i = 0; i < 25; i++) {
        expect(
          Outing.refusalReason(state, eylem('sinema'), cocuk),
          ilk,
          reason: 'Aynı yıl aynı cevap gelmeli',
        );
      }
    });

    test('ret ihtimali tavanı geçmez: kapı hiç kapanmaz', () {
      final GameState state =
          hayat(9, ek: <Person>[kiz('cocuk-9', happiness: 0, bond: 0)]);
      Person cocuk = state.personById('cocuk-9')!;
      GameState s = state;
      // Aynı yıl üst üste çağrılmış gibi sayaç şişirilir.
      s = s.copyWith(
        interactionCounts: <String, int>{
          GameState.interactionKey('birlikte-cocuk-9', 'sinema'): 20,
        },
      );
      cocuk = s.personById('cocuk-9')!;
      expect(
        Outing.refusalChance(s, eylem('sinema'), cocuk),
        lessThanOrEqualTo(Outing.prototypeOnlyMaxRefusal),
      );
    });
  });

  group('Keyif nötre kayar', () {
    test('yükselen keyif zamanla geri iner, düşen keyif toparlanır', () {
      const int notr = Person.prototypeOnlyDefaultHappiness;
      GameState state = hayat(10, ek: <Person>[
        kiz('mutlu', happiness: notr + 20),
        kiz('kederli', happiness: notr - 20),
      ]);

      for (int i = 0; i < 5; i++) {
        final BondDecayResult r = BondDecay.applyYear(state);
        state = state.copyWith(people: r.people);
      }

      expect(state.personById('mutlu')!.happiness, lessThan(notr + 20));
      expect(state.personById('kederli')!.happiness, greaterThan(notr - 20));
    });

    test('nötrdeki keyif yerinde durur', () {
      const int notr = Person.prototypeOnlyDefaultHappiness;
      GameState state = hayat(11, ek: <Person>[kiz('notr', happiness: notr)]);
      for (int i = 0; i < 5; i++) {
        final BondDecayResult r = BondDecay.applyYear(state);
        state = state.copyWith(people: r.people);
      }
      expect(state.personById('notr')!.happiness, notr);
    });

    test('eski kayıtta keyif yoktur; nötr okunur', () {
      final GameState state = hayat(12, ek: <Person>[kiz('eski')]);
      final Map<String, Object?> json = encodeGameState(state);
      final List<Object?> kisiler = json['people']! as List<Object?>;
      for (final Object? k in kisiler) {
        (k! as Map<String, Object?>).remove('happiness');
      }
      final GameState geri = decodeGameState(json);
      expect(
        geri.personById('eski')!.happiness,
        Person.prototypeOnlyDefaultHappiness,
      );
    });
  });

  group('Boşanmada mal paylaşımı (D-075)', () {
    OwnedItem esya(
      String id,
      String typeId, {
      required int acquiredAtAge,
      ItemSource source = ItemSource.satinAlma,
    }) =>
        OwnedItem(
          id: id,
          typeId: typeId,
          acquiredAtAge: acquiredAtAge,
          source: source,
        );

    test('evlilikten önce alınan eşya paylaşıma girmez', () {
      expect(
        DivorceSettlement.isMaritalProperty(
          esya('a', 'kucuk_daire', acquiredAtAge: 24),
          30,
        ),
        isFalse,
      );
    });

    test('miras ve hediye kişisel maldır', () {
      for (final ItemSource kaynak in <ItemSource>[
        ItemSource.miras,
        ItemSource.hediye,
        ItemSource.olay,
      ]) {
        expect(
          DivorceSettlement.isMaritalProperty(
            esya('a', 'villa', acquiredAtAge: 35, source: kaynak),
            30,
          ),
          isFalse,
          reason: '${kaynak.label} paylaşıma girmemeli',
        );
      }
    });

    test('evlilik içinde satın alınan eşya paylaşıma girer', () {
      expect(
        DivorceSettlement.isMaritalProperty(
          esya('a', 'standart_daire', acquiredAtAge: 35),
          30,
        ),
        isTrue,
      );
    });

    test('paylaşım iki tarafı yaklaşık eşitler', () {
      final DivorceSettlement p = DivorceSettlement.compute(
        items: <OwnedItem>[
          esya('a', 'villa', acquiredAtAge: 35),
          esya('b', 'mustakil_ev', acquiredAtAge: 36),
          esya('c', 'standart_daire', acquiredAtAge: 37),
          esya('d', 'kucuk_daire', acquiredAtAge: 38),
        ],
        marriedAtAge: 30,
        wallet: 1000000,
        cashShare: 0.25,
      );

      int deger(List<OwnedItem> l) =>
          l.fold(0, (int t, OwnedItem i) => t + DivorceSettlement.valueOf(i));
      final int oyuncu = deger(p.kept);
      final int es = deger(p.toSpouse);
      expect(es, greaterThan(0), reason: 'Eşe bir şey kalmalı');
      // Bölünemeyen eşyalarda tam eşitlik olmaz; makul bir bantta olmalı.
      final double oran = es / (oyuncu + es);
      expect(oran, greaterThan(0.25));
      expect(oran, lessThan(0.75));
    });

    test('tek ev evlilik içinde alındıysa bir tarafa gider', () {
      final DivorceSettlement p = DivorceSettlement.compute(
        items: <OwnedItem>[esya('a', 'standart_daire', acquiredAtAge: 35)],
        marriedAtAge: 30,
        wallet: 0,
        cashShare: 0.25,
      );
      expect(p.kept.length + p.toSpouse.length, 1);
    });

    test('paylaşım kararlıdır: aynı girdi aynı sonucu verir', () {
      List<OwnedItem> girdi() => <OwnedItem>[
            esya('a', 'kucuk_daire', acquiredAtAge: 35),
            esya('b', 'kucuk_daire', acquiredAtAge: 36),
            esya('c', 'kucuk_daire', acquiredAtAge: 37),
          ];
      final List<String> ilk = DivorceSettlement.compute(
        items: girdi(),
        marriedAtAge: 30,
        wallet: 0,
        cashShare: 0.25,
      ).toSpouse.map((OwnedItem i) => i.id).toList(growable: false);
      for (int i = 0; i < 5; i++) {
        expect(
          DivorceSettlement.compute(
            items: girdi(),
            marriedAtAge: 30,
            wallet: 0,
            cashShare: 0.25,
          ).toSpouse.map((OwnedItem i) => i.id).toList(growable: false),
          ilk,
        );
      }
    });

    test('nakit payı cüzdanı eksiye düşürmez', () {
      final DivorceSettlement p = DivorceSettlement.compute(
        items: const <OwnedItem>[],
        marriedAtAge: 30,
        wallet: 0,
        cashShare: 0.25,
      );
      expect(p.cashToSpouse, 0);
    });

    test('özet satırı yalnızca gerçekten olanı yazar', () {
      final DivorceSettlement bos = DivorceSettlement.compute(
        items: const <OwnedItem>[],
        marriedAtAge: 30,
        wallet: 100,
        cashShare: 0.25,
      );
      expect(bos.summaryLines('Ayşe'), isEmpty);
      expect(bos.sharesProperty, isFalse);
    });
  });
}
