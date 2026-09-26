import 'dart:math';

import 'package:bir_omur/data/gift_catalog.dart';
import 'package:bir_omur/data/item_catalog.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/interaction/family_interactions.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/interaction.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:flutter_test/flutter_test.dart';

const FamilyInteractions etkilesim = FamilyInteractions();

GameState hayat(int seed, {int age = 28, int wallet = 500000}) {
  final GameState s =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  return s.copyWith(
    player: s.player.copyWith(age: age, wallet: wallet),
    pendingEvent: null,
  );
}

Person kisi({
  required String id,
  required RelationType relation,
  int age = 55,
  int bond = 60,
}) =>
    Person(
      id: id,
      firstName: 'Sevim',
      lastName: 'Tan',
      gender: Gender.kadin,
      relation: relation,
      age: age,
      isAlive: true,
      inPlayerHousehold: false,
      employment: EmploymentStatus.calisiyor,
      wealth: WealthTier.ortaHalli,
      bond: bond,
    );

GameState ile(GameState s, Person p) => s.copyWith(
      people: List<Person>.unmodifiable(<Person>[...s.people, p]),
    );

void main() {
  // ===================================================================
  // 1) Katalog
  // ===================================================================
  group('katalog', () {
    test('her hediyenin bir sınıfı ve gerçek bir eşya karşılığı var', () {
      for (final GiftItem g in kGiftCatalog) {
        expect(
          itemTypeById(g.id),
          isNotNull,
          reason: '${g.id} eşya kataloğunda yok.',
        );
        expect(g.value, greaterThan(0), reason: g.id);
      }
    });

    test('Faho\'nun istediği hediyeler katalogda', () {
      for (final String id in <String>[
        'tavla',
        'cicek_buketi',
        'ceyrek_altin',
        'bilezik',
      ]) {
        expect(giftById(id), isNotNull, reason: '$id yok.');
      }
    });

    test('her sınıftan en az bir hediye var', () {
      for (final GiftCategory k in GiftCategory.values) {
        expect(
          kGiftCatalog.any((GiftItem g) => g.category == k),
          isTrue,
          reason: '${k.label} sınıfında hediye yok.',
        );
      }
    });

    test('pahalı takı yoksul veren için kapalı', () {
      final GiftItem bilezik = giftById('bilezik')!;
      expect(bilezik.affordableBy(WealthTier.yoksul), isFalse);
      expect(bilezik.affordableBy(WealthTier.varlikli), isTrue);
    });
  });

  // ===================================================================
  // 2) Beğeni
  // ===================================================================
  group('beğeni', () {
    test('anneye tavla beğenilmez, çeyrek altın sevilir', () {
      // Faho'nun örneği.
      expect(
        giftReactionFor(
          gift: giftById('tavla')!,
          relation: RelationType.anne,
          receiverAge: 55,
        ),
        GiftReaction.begenmedi,
      );
      expect(
        giftReactionFor(
          gift: giftById('ceyrek_altin')!,
          relation: RelationType.anne,
          receiverAge: 55,
        ),
        GiftReaction.sevindi,
      );
    });

    test('dede tavlayı sever', () {
      expect(
        giftReactionFor(
          gift: giftById('tavla')!,
          relation: RelationType.anneTarafiDede,
          receiverAge: 74,
        ),
        GiftReaction.sevindi,
      );
    });

    test('çocuğa altın anlamsız, oyuncak sevinç', () {
      expect(
        giftReactionFor(
          gift: giftById('ceyrek_altin')!,
          relation: RelationType.cocuk,
          receiverAge: 8,
        ),
        GiftReaction.begenmedi,
      );
      expect(
        giftReactionFor(
          gift: giftById('oyuncak_araba')!,
          relation: RelationType.cocuk,
          receiverAge: 8,
        ),
        GiftReaction.sevindi,
      );
    });

    test('ergene ev eşyası değil, elektronik', () {
      expect(
        giftReactionFor(
          gift: giftById('seccade')!,
          relation: RelationType.kardes,
          receiverAge: 15,
        ),
        GiftReaction.begenmedi,
      );
      expect(
        giftReactionFor(
          gift: giftById('kulaklik')!,
          relation: RelationType.kardes,
          receiverAge: 15,
        ),
        GiftReaction.sevindi,
      );
    });

    test('zevki tanımlı olmayan bağda idare eder', () {
      expect(
        giftReactionFor(
          gift: giftById('tavla')!,
          relation: RelationType.yegen,
          receiverAge: 30,
        ),
        GiftReaction.idare,
      );
    });
  });

  // ===================================================================
  // 3) Seçim gerçekten uygulanır
  // ===================================================================
  group('seçim', () {
    test('seçilen hediye alınır ve bedeli o hediyenin bedelidir', () {
      final GameState s = ile(hayat(1), kisi(id: 'anne-x', relation: RelationType.anne));
      final GiftItem secim = giftById('ceyrek_altin')!;
      final InteractionResult r = etkilesim.perform(
        state: s,
        personId: 'anne-x',
        kind: InteractionKind.hediyeVer,
        rng: Random(1),
        giftId: secim.id,
      );
      expect(r.outcome.accepted, isTrue);
      expect(r.outcome.givenPossession, secim.id);
      expect(r.state.player.wallet, s.player.wallet - secim.value);
    });

    test('beğenilen hediye yakınlığı daha çok artırır', () {
      final GameState s =
          ile(hayat(2), kisi(id: 'anne-x', relation: RelationType.anne));
      final InteractionResult iyi = etkilesim.perform(
        state: s,
        personId: 'anne-x',
        kind: InteractionKind.hediyeVer,
        rng: Random(2),
        giftId: 'ceyrek_altin',
      );
      final InteractionResult kotu = etkilesim.perform(
        state: s,
        personId: 'anne-x',
        kind: InteractionKind.hediyeVer,
        rng: Random(2),
        giftId: 'tavla',
      );
      expect(iyi.outcome.bondDelta, greaterThan(kotu.outcome.bondDelta));
      // Beğenilmeyen hediye yakınlığı geri götürür.
      expect(kotu.outcome.bondDelta, lessThan(0));
      // Para yine gitmiştir: yanlış hediye bedava değil.
      expect(kotu.state.player.wallet, lessThan(s.player.wallet));
    });

    test('tepki sonuç metninde yazar', () {
      final GameState s =
          ile(hayat(3), kisi(id: 'anne-x', relation: RelationType.anne));
      final InteractionResult r = etkilesim.perform(
        state: s,
        personId: 'anne-x',
        kind: InteractionKind.hediyeVer,
        rng: Random(3),
        giftId: 'tavla',
      );
      // Anlatının arkasına tepki eklenir (D-127 §3).
      expect(r.outcome.text.split('\n\n').length, greaterThanOrEqualTo(2));
    });

    test('seçim listede yoksa sahte hediye uydurulmaz', () {
      // Parası yetmeyen bir hediye seçilse bile uygunlardan biri alınır
      // ve cüzdan eksiye düşmez.
      final GameState s = ile(
        hayat(4, wallet: 2000),
        kisi(id: 'anne-x', relation: RelationType.anne),
      );
      final InteractionResult r = etkilesim.perform(
        state: s,
        personId: 'anne-x',
        kind: InteractionKind.hediyeVer,
        rng: Random(4),
        giftId: 'bilezik',
      );
      expect(r.outcome.givenPossession, isNot('bilezik'));
      expect(r.state.player.wallet, greaterThanOrEqualTo(0));
    });

    test('seçim verilmezse eski davranış sürer', () {
      final GameState s =
          ile(hayat(5), kisi(id: 'anne-x', relation: RelationType.anne));
      final InteractionResult r = etkilesim.perform(
        state: s,
        personId: 'anne-x',
        kind: InteractionKind.hediyeVer,
        rng: Random(5),
      );
      expect(r.outcome.accepted, isTrue);
      expect(r.outcome.givenPossession, isNotNull);
    });

    test('seçenek listesi cüzdana ve yaşa göre daralır', () {
      final GameState zengin =
          ile(hayat(6), kisi(id: 'anne-x', relation: RelationType.anne));
      final GameState yoksul = ile(
        hayat(7, wallet: 1500),
        kisi(id: 'anne-x', relation: RelationType.anne),
      );
      final List<GiftItem> a =
          etkilesim.giftOptions(zengin, zengin.personById('anne-x')!);
      final List<GiftItem> b =
          etkilesim.giftOptions(yoksul, yoksul.personById('anne-x')!);
      expect(a.length, greaterThan(b.length));
      for (final GiftItem g in b) {
        expect(g.value, lessThanOrEqualTo(1500));
      }
    });
  });
}
