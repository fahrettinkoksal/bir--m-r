import 'dart:math';

import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/domain/generation/generation_continuation.dart';
import 'package:bir_omur/domain/life/inheritance.dart';
import 'package:bir_omur/domain/life/will.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/owned_item.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/generation_fixtures.dart';
import 'support/invariants.dart';

/// Yaşayan, iki çocuklu bir oyuncu.
GameState yasayan({int wallet = 400000}) => olenOyuncu(wallet: wallet).copyWith(
      deceased: false,
      player: olenOyuncu(wallet: wallet).player.copyWith(age: 60),
    );

void main() {
  group('Mirasçı seçimi', () {
    test('çocuğu olmayan oyuncuya vasiyet açılmaz', () {
      final GameState cocuksuz = yasayan().copyWith(
        people: yasayan()
            .people
            .where((Person p) => p.relation != RelationType.cocuk)
            .toList(growable: false),
      );
      expect(Will.blockReason(cocuksuz), isNotEmpty);
      expect(Will.effectiveHeirId(cocuksuz), isNull);
    });

    test('mirasçı seçilir, değiştirilir ve kaldırılır', () {
      GameState state = yasayan();
      expect(Will.blockReason(state), isEmpty);
      expect(Will.effectiveHeirId(state), isNull);

      final ({GameState state, String text, bool applied}) sec =
          Will.choose(state, 'cocuk-1');
      expect(sec.applied, isTrue);
      state = sec.state;
      expect(Will.effectiveHeirId(state), 'cocuk-1');
      expect(state.log.last.text, contains('mirasçı'));

      // Aynı çocuğu yeniden seçmek bir şey değiştirmez.
      expect(Will.choose(state, 'cocuk-1').applied, isFalse);

      // Değiştirilebilir.
      state = Will.choose(state, 'cocuk-2').state;
      expect(Will.effectiveHeirId(state), 'cocuk-2');

      // Kaldırılabilir.
      final ({GameState state, String text, bool applied}) kaldir =
          Will.clear(state);
      expect(kaldir.applied, isTrue);
      expect(Will.effectiveHeirId(kaldir.state), isNull);
      expect(Will.clear(kaldir.state).applied, isFalse);
    });

    test('çocuk olmayan kişi mirasçı yapılamaz', () {
      final GameState state = yasayan();
      expect(Will.choose(state, 'kardes-1').applied, isFalse);
      expect(Will.choose(state, 'yok').applied, isFalse);
    });

    test('vefat eden mirasçı seçimi düşer, miras eşit bölünür', () {
      GameState state = Will.choose(yasayan(), 'cocuk-1').state;
      expect(Will.effectiveHeirId(state), 'cocuk-1');

      state = state.copyWith(
        people: state.people
            .map((Person p) =>
                p.id == 'cocuk-1' ? p.copyWith(isAlive: false) : p)
            .toList(growable: false),
      );
      // Kayıt silinmez ama seçim geçersizdir.
      expect(state.heirChildId, 'cocuk-1');
      expect(Will.effectiveHeirId(state), isNull);
      expect(Will.effectiveHeir(state), isNull);
    });
  });

  group('Pay hesabı', () {
    test('seçim yoksa çocuklar eşit alır', () {
      final GameState state = yasayan();
      final List<Person> cocuklar = state.livingChildren;
      expect(Will.cashShareFor(state, cocuklar.first, 100000), 50000);
      expect(Will.cashShareFor(state, cocuklar.last, 100000), 50000);
    });

    test('mirasçı büyük payı alır, diğer çocuk dışlanmaz', () {
      final GameState state = Will.choose(yasayan(), 'cocuk-1').state;
      final Person mirasci = state.personById('cocuk-1')!;
      final Person digeri = state.personById('cocuk-2')!;

      final int mirasciPayi = Will.cashShareFor(state, mirasci, 100000);
      final int digerPay = Will.cashShareFor(state, digeri, 100000);
      expect(mirasciPayi, 60000);
      expect(digerPay, 40000);
      expect(digerPay, greaterThan(0), reason: 'Kimse tamamen dışlanmaz');
      expect(mirasciPayi + digerPay, lessThanOrEqualTo(100000));
    });

    test('tek çocukta seçim payı değiştirmez', () {
      final GameState tek = yasayan().copyWith(
        people: yasayan()
            .people
            .where((Person p) => p.id != 'cocuk-2')
            .toList(growable: false),
      );
      final GameState state = Will.choose(tek, 'cocuk-1').state;
      expect(
        Will.cashShareFor(state, state.personById('cocuk-1')!, 100000),
        100000,
      );
    });
  });

  group('Kuşak devamı', () {
    test('mirasçı çocukla devam edince payı daha büyük olur', () {
      final GameState vasiyetli = Will.choose(
        olenOyuncu(wallet: 400000, esHayatta: false),
        'cocuk-1',
      ).state;
      final GameState vasiyetsiz = olenOyuncu(
        wallet: 400000,
        esHayatta: false,
      );

      final GameState mirasciDevam =
          GenerationContinuation.continueAs(vasiyetli, 'cocuk-1', Random(1))
              .state!;
      final GameState esitDevam =
          GenerationContinuation.continueAs(vasiyetsiz, 'cocuk-1', Random(1))
              .state!;

      expect(mirasciDevam.player.wallet, 240000);
      expect(esitDevam.player.wallet, 200000);
      expect(checkInvariants(mirasciDevam), isEmpty);
    });

    test('mirasçı olmayan çocukla devam edilebilir, payı küçülür', () {
      final GameState vasiyetli = Will.choose(
        olenOyuncu(wallet: 400000, esHayatta: false),
        'cocuk-1',
      ).state;
      final GameState devam =
          GenerationContinuation.continueAs(vasiyetli, 'cocuk-2', Random(1))
              .state!;
      // Vasiyet, kiminle devam edileceğini belirlemez.
      expect(devam.player.firstName, 'Kerem');
      expect(devam.player.wallet, 160000);
    });

    test('eşin payı vasiyetten etkilenmez', () {
      final GameState vasiyetli =
          Will.choose(olenOyuncu(wallet: 400000), 'cocuk-1').state;
      final GameState devam =
          GenerationContinuation.continueAs(vasiyetli, 'cocuk-1', Random(1))
              .state!;
      final int esPayi =
          (400000 * Inheritance.prototypeOnlySpouseShare).round();
      // Çocuklara kalan havuz eşin payından sonra hesaplanır.
      expect(devam.player.wallet, ((400000 - esPayi) * 0.6).round());
    });

    test('eşya paylaşımında mirasçı ilk sıradadır', () {
      final GameState temel = olenOyuncu(
        esHayatta: false,
        items: <OwnedItem>[
          const OwnedItem(
            id: 'esya-1',
            typeId: 'kucuk_daire',
            acquiredAtAge: 40,
            source: ItemSource.satinAlma,
          ),
          const OwnedItem(
            id: 'esya-2',
            typeId: 'ikinci_el_otomobil',
            acquiredAtAge: 40,
            source: ItemSource.satinAlma,
          ),
        ],
      );
      // Vasiyet cocuk-2'yi mirasçı yapınca ilk eşya ona geçer.
      final GameState vasiyetli = Will.choose(temel, 'cocuk-2').state;
      final GameState devam =
          GenerationContinuation.continueAs(vasiyetli, 'cocuk-2', Random(1))
              .state!;
      expect(devam.items.single.id, 'esya-1');
    });
  });

  test('vasiyet kaydedilip geri okunur', () {
    final GameState state = Will.choose(yasayan(), 'cocuk-2').state;
    final GameState geri = decodeGameState(encodeGameState(state));
    expect(geri.heirChildId, 'cocuk-2');
    expect(Will.effectiveHeirId(geri), 'cocuk-2');
  });
}
