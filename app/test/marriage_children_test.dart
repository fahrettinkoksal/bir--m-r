import 'dart:convert';
import 'dart:math';

import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/data/save/save_service.dart';
import 'package:bir_omur/data/save/save_store.dart';
import 'package:bir_omur/domain/economy/housing.dart';
import 'package:bir_omur/domain/economy/living_costs.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/generation/life_progression.dart';
import 'package:bir_omur/domain/interaction/family_interactions.dart';
import 'package:bir_omur/domain/interaction/marriage_engine.dart';
import 'package:bir_omur/domain/interaction/parenthood.dart';
import 'package:bir_omur/domain/interaction/romance.dart';
import 'package:bir_omur/domain/life/inheritance.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/marriage.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:flutter_test/flutter_test.dart';

const MarriageEngine evlilik = MarriageEngine();
const Parenthood ebeveynlik = Parenthood();
const FamilyInteractions etkilesim = FamilyInteractions();

GameState oyuncu(int seed, {int age = 30, int wallet = 2000000}) {
  final GameState state =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  return state.copyWith(
    player: state.player.copyWith(age: age, wallet: wallet),
  );
}

/// Sevgili ekler ve yakınlığı testte belirli hâle getirir.
({GameState state, Person partner}) sevgiliEkle(
  GameState state, {
  int seed = 1,
  int bond = 80,
}) {
  final ({GameState state, Person partner}) sonuc =
      const Romance().start(state, Random(seed));
  final GameState guncel = sonuc.state.copyWith(
    people: sonuc.state.people
        .map((Person p) =>
            p.id == sonuc.partner.id ? p.copyWith(bond: bond) : p)
        .toList(growable: false),
  );
  return (state: guncel, partner: guncel.personById(sonuc.partner.id)!);
}

/// Evli bir hayat kurar.
GameState evlen(GameState state, {int seed = 1, int bond = 80}) {
  final ({GameState state, Person partner}) s =
      sevgiliEkle(state, seed: seed, bond: bond);
  final FamilyResult r = evlilik.marry(s.state, s.partner.id);
  expect(r.outcome.applied, isTrue, reason: r.outcome.text);
  return r.state;
}

/// Çocukları bir yaş büyütür (aynı yıl ikinci bebek olmaz kuralı için).
GameState cocuklariBuyut(GameState state) => state.copyWith(
      people: state.people
          .map((Person p) => p.relation == RelationType.cocuk
              ? p.copyWith(age: p.age + 1)
              : p)
          .toList(growable: false),
    );

void main() {
  // ===================================================================
  // Evlilik
  // ===================================================================
  group('Evlilik (Paket E1)', () {
    test('sevgili olmadan evlenilemez', () {
      final GameState state = oyuncu(1);
      final Person anne =
          state.people.firstWhere((Person p) => p.relation == RelationType.anne);
      expect(evlilik.marryBlockReason(state, anne), isNotEmpty);
      expect(evlilik.marry(state, anne.id).outcome.applied, isFalse);
      expect(state.isMarried, isFalse);
    });

    test('yaş, yakınlık ve para koşulu sağlanmadan evlenilemez', () {
      final ({GameState state, Person partner}) genc =
          sevgiliEkle(oyuncu(2, age: 16));
      expect(
        evlilik.marryBlockReason(genc.state, genc.partner),
        contains('${MarriageEngine.prototypeOnlyMinAge}'),
      );

      final ({GameState state, Person partner}) uzak =
          sevgiliEkle(oyuncu(3), bond: 30);
      expect(
        evlilik.marryBlockReason(uzak.state, uzak.partner),
        contains('yakın değil'),
      );

      final ({GameState state, Person partner}) parasiz =
          sevgiliEkle(oyuncu(4, wallet: 100));
      expect(
        evlilik.marryBlockReason(parasiz.state, parasiz.partner),
        contains('para yok'),
      );
      expect(parasiz.state.isMarried, isFalse);
    });

    test('evlenince kişi aynı kimlikle eş olur, yeni kişi üretilmez', () {
      final ({GameState state, Person partner}) s = sevgiliEkle(oyuncu(5));
      final int kisiSayisi = s.state.people.length;

      final GameState evli = evlilik.marry(s.state, s.partner.id).state;

      expect(evli.people.length, kisiSayisi, reason: 'Yeni kişi üretilmemeli');
      final Person es = evli.personById(s.partner.id)!;
      expect(es.relation, RelationType.es);
      expect(es.fullName, s.partner.fullName);
      expect(evli.marriage!.spouseId, s.partner.id);
      expect(evli.marriage!.status, MarriageStatus.evli);
      expect(evli.marriage!.marriedAtAge, evli.player.age);
      expect(evli.isMarried, isTrue);
      expect(evli.spouse!.id, s.partner.id);
    });

    test('nikâh masrafı bir kez düşer ve kendi hanen kurulur', () {
      final ({GameState state, Person partner}) s = sevgiliEkle(oyuncu(6));
      final int cuzdan = s.state.player.wallet;

      final GameState evli = evlilik.marry(s.state, s.partner.id).state;

      expect(
        evli.player.wallet,
        cuzdan - MarriageEngine.prototypeOnlyWeddingCost,
      );
      expect(evli.spouse!.inPlayerHousehold, isTrue);
      expect(evli.movedOut, isTrue);
      expect(Housing.residenceOf(evli), ResidenceKind.kirada,
          reason: 'Evlenmek ailenin yanından ayrılmaktır');

      // İkinci kez evlenilemez; masraf ikinci kez alınmaz.
      final FamilyResult ikinci = evlilik.marry(evli, s.partner.id);
      expect(ikinci.outcome.applied, isFalse);
      expect(ikinci.state.player.wallet, evli.player.wallet);
    });

    test('boşanma kaydı silmez, aynı kimlik eski eş olur', () {
      final GameState evli = evlen(oyuncu(7));
      final String esId = evli.marriage!.spouseId;
      final int kisiSayisi = evli.people.length;

      final FamilyResult r = evlilik.divorce(evli);
      expect(r.outcome.applied, isTrue);
      final GameState sonra = r.state;

      expect(sonra.people.length, kisiSayisi);
      expect(sonra.personById(esId)!.relation, RelationType.eskiEs);
      expect(sonra.personById(esId)!.inPlayerHousehold, isFalse);
      expect(sonra.marriage!.status, MarriageStatus.bosandi);
      expect(sonra.marriage!.endedAtAge, sonra.player.age);
      expect(sonra.isMarried, isFalse);
    });

    test('boşanma payı bir kez uygulanır, cüzdan eksiye düşmez', () {
      final GameState evli = evlen(oyuncu(8));
      final int cuzdan = evli.player.wallet;
      final int beklenen =
          (cuzdan * MarriageEngine.prototypeOnlyDivorceShare).round();

      final GameState sonra = evlilik.divorce(evli).state;
      expect(sonra.player.wallet, cuzdan - beklenen);
      expect(sonra.player.wallet, greaterThanOrEqualTo(0));

      // İkinci boşanma yok: pay ikinci kez kesilmez.
      final FamilyResult tekrar = evlilik.divorce(sonra);
      expect(tekrar.outcome.applied, isFalse);
      expect(tekrar.state.player.wallet, sonra.player.wallet);
    });

    test('boşandıktan sonra ikinci evlilik kaydı ezmez', () {
      final GameState bosandi = evlilik.divorce(evlen(oyuncu(25))).state;
      final Marriage ilkKayit = bosandi.marriage!;

      final ({GameState state, Person partner}) yeni =
          sevgiliEkle(bosandi, seed: 9);
      expect(evlilik.marryBlockReason(yeni.state, yeni.partner), isNotEmpty);

      final FamilyResult r = evlilik.marry(yeni.state, yeni.partner.id);
      expect(r.outcome.applied, isFalse);
      expect(r.state.marriage!.spouseId, ilkKayit.spouseId,
          reason: 'İlk evlilik kaydı korunur');
      expect(r.state.marriage!.marriedAtAge, ilkKayit.marriedAtAge);
    });

    test('eski eşle etkileşim gerekçesiyle kapalıdır', () {
      final GameState sonra = evlilik.divorce(evlen(oyuncu(9))).state;
      final Person eskiEs = sonra.personById(sonra.marriage!.spouseId)!;
      expect(etkilesim.availability(sonra, eskiEs).isAllowed, isFalse);
      expect(etkilesim.availableKinds(sonra, eskiEs), isEmpty);
    });

    test('eş vefat edince kayıt dul olur, kişi silinmez', () {
      final GameState evli = evlen(oyuncu(10), seed: 3);
      final String esId = evli.marriage!.spouseId;
      final GameState olum = evli.copyWith(
        people: evli.people
            .map((Person p) =>
                p.id == esId ? p.copyWith(isAlive: false) : p)
            .toList(growable: false),
      );

      final GameState sonra = evlilik.settleWidowhood(olum, olum.player.age);
      expect(sonra.marriage!.status, MarriageStatus.dul);
      expect(sonra.personById(esId), isNotNull);
      expect(sonra.isMarried, isFalse);
    });
  });

  // ===================================================================
  // Miras
  // ===================================================================
  group('Evlilik ve miras (D-037)', () {
    GameState esiOldur(GameState state, WealthTier tier) => state.copyWith(
          people: state.people
              .map((Person p) => p.id == state.marriage!.spouseId
                  ? p.copyWith(isAlive: false, wealth: tier)
                  : p)
              .toList(growable: false),
        );

    test('çocuksuz evlilikte miras eşe kalır ve bir kez dağıtılır', () {
      final GameState olum =
          esiOldur(evlen(oyuncu(11)), WealthTier.ortaHalli);
      final Person es = olum.personById(olum.marriage!.spouseId)!;
      final int cuzdan = olum.player.wallet;
      final int miras = Inheritance.prototypeOnlyEstateMoney(es.wealth);

      final ({GameState state, List<String> logLines}) ilk =
          Inheritance.settle(olum, es);
      expect(ilk.state.player.wallet, cuzdan + miras);

      final ({GameState state, List<String> logLines}) ikinci =
          Inheritance.settle(ilk.state, es);
      expect(ikinci.state.player.wallet, ilk.state.player.wallet,
          reason: 'Aynı miras iki kez dağıtılmaz');
    });

    test('çocuk varsa eş payı alır, kalanı çocuklara kalır', () {
      GameState state = evlen(oyuncu(12));
      state = ebeveynlik.haveChild(state, Random(1)).state;
      final GameState olum = esiOldur(state, WealthTier.ortaHalli);
      final Person es = olum.personById(olum.marriage!.spouseId)!;

      final InheritanceShare pay = Inheritance.shareFor(olum, es);
      final int toplam = Inheritance.prototypeOnlyEstateMoney(es.wealth);
      expect(
        pay.money,
        (toplam * Inheritance.prototypeOnlySpouseShare).round(),
      );
      expect(pay.money, lessThan(toplam));
      expect(pay.heirCount, 2);
    });

    test('boşanmış eşten miras gelmez', () {
      final GameState bosandi = evlilik.divorce(evlen(oyuncu(13))).state;
      final GameState olum = bosandi.copyWith(
        people: bosandi.people
            .map((Person p) => p.id == bosandi.marriage!.spouseId
                ? p.copyWith(isAlive: false, wealth: WealthTier.cokVarlikli)
                : p)
            .toList(growable: false),
      );
      final Person eskiEs = olum.personById(olum.marriage!.spouseId)!;

      expect(Inheritance.shareFor(olum, eskiEs).isEmpty, isTrue);
      final int cuzdan = olum.player.wallet;
      expect(Inheritance.settle(olum, eskiEs).state.player.wallet, cuzdan);
    });

    test('çocuğun mirası anne-baba arasında bölünür', () {
      GameState state = evlen(oyuncu(14));
      state = ebeveynlik.haveChild(state, Random(2)).state;
      final Person cocuk = state.children.single;
      // Çocuğun kendi hayatı izlendiği için miras **gerçekten
      // biriktirdiği** paradan dağıtılır (D-045); ekonomik durum tahmini
      // yalnızca kaydı olmayan kişiler içindir.
      const int birikim = 240000;
      final GameState olum = state.copyWith(
        people: state.people
            .map((Person p) => p.id == cocuk.id
                ? p.copyWith(
                    isAlive: false,
                    age: 30,
                    wealth: WealthTier.ortaHalli,
                    development: p.development!.copyWith(money: birikim),
                  )
                : p)
            .toList(growable: false),
      );

      final InheritanceShare pay =
          Inheritance.shareFor(olum, olum.personById(cocuk.id)!);
      expect(pay.heirCount, 2, reason: 'Oyuncu ve eşi');
      expect(pay.money, birikim ~/ 2);
    });
  });

  // ===================================================================
  // Çocuklar
  // ===================================================================
  group('Çocuklar (Paket E2)', () {
    test('evlilik dışı çocuk mümkündür ama ilişki gerçek olmalıdır (D-047)',
        () {
      // Yakın bir ilişkide evlilik şart değildir.
      final GameState yakin = sevgiliEkle(oyuncu(15), bond: 80).state;
      expect(ebeveynlik.blockReason(yakin), isEmpty);
      final FamilyResult olumlu = ebeveynlik.haveChild(yakin, Random(1));
      expect(olumlu.outcome.applied, isTrue);
      expect(olumlu.state.children.length, 1);
      // Evlilik kaydı **oluşmaz**: sevgili kendiliğinden eş yapılmaz.
      expect(olumlu.state.marriage, isNull);
      expect(olumlu.state.isMarried, isFalse);

      // Yeni başlamış, yakınlığı düşük ilişkide olmaz.
      final GameState uzak = sevgiliEkle(oyuncu(15), bond: 30).state;
      expect(ebeveynlik.blockReason(uzak), contains('yakın değil'));
      expect(ebeveynlik.haveChild(uzak, Random(1)).outcome.applied, isFalse);
    });

    test('sevgili de eş de yoksa çocuk sahibi olunamaz', () {
      final GameState yalniz = oyuncu(15);
      expect(ebeveynlik.blockReason(yalniz), contains('sevgilin'));
      expect(
        ebeveynlik.haveChild(yalniz, Random(1)).outcome.applied,
        isFalse,
      );
    });

    test('çocuk gerçek ve kalıcı bir kişi kaydıdır', () {
      final GameState evli = evlen(oyuncu(16));
      final int cuzdan = evli.player.wallet;

      final FamilyResult r = ebeveynlik.haveChild(evli, Random(3));
      expect(r.outcome.applied, isTrue);
      final Person cocuk = r.state.children.single;

      expect(cocuk.age, 0);
      expect(cocuk.relation, RelationType.cocuk);
      expect(cocuk.isAlive, isTrue);
      expect(cocuk.inPlayerHousehold, isTrue);
      // Soyadı babadan gelir (prototypeOnly, Q-063).
      final Person es = r.state.spouse!;
      expect(
        cocuk.lastName,
        r.state.player.gender == Gender.erkek
            ? r.state.player.lastName
            : es.lastName,
      );
      expect(cocuk.wealth, isNull, reason: 'Çocuğa uydurma servet yazılmaz');
      expect(cocuk.occupation, isNull);
      expect(cocuk.relation.kanBagi, isTrue);
      expect(
        r.state.player.wallet,
        cuzdan - Parenthood.prototypeOnlyBirthCost,
      );
      expect(
        r.state.log.last.text,
        contains(cocuk.firstName),
      );
    });

    test('aynı yıl ikinci bebek olmaz, en fazla dört çocuk olur', () {
      GameState state = evlen(oyuncu(17));
      state = ebeveynlik.haveChild(state, Random(4)).state;

      expect(ebeveynlik.blockReason(state), contains('Bu yıl'));
      expect(ebeveynlik.haveChild(state, Random(5)).outcome.applied, isFalse);

      for (int i = 1; i < Parenthood.prototypeOnlyMaxChildren; i++) {
        state = cocuklariBuyut(state);
        final FamilyResult r = ebeveynlik.haveChild(state, Random(10 + i));
        expect(r.outcome.applied, isTrue, reason: r.outcome.text);
        state = r.state;
      }

      expect(state.children.length, Parenthood.prototypeOnlyMaxChildren);
      state = cocuklariBuyut(state);
      expect(
        ebeveynlik.blockReason(state),
        contains('${Parenthood.prototypeOnlyMaxChildren}'),
      );
      expect(ebeveynlik.haveChild(state, Random(9)).outcome.applied, isFalse);

      // Kimlikler çakışmaz: her çocuk ayrı bir kayıttır.
      final Set<String> kimlikler =
          state.children.map((Person p) => p.id).toSet();
      expect(kimlikler.length, state.children.length);
    });

    test('ileri yaşta çocuk yolu kapalıdır ve gerekçesi yazılır', () {
      final GameState evli = evlen(oyuncu(18, age: 55), seed: 6);
      expect(ebeveynlik.blockReason(evli), isNotEmpty);
      expect(ebeveynlik.haveChild(evli, Random(1)).outcome.applied, isFalse);
    });

    test('çocuk gideri gerçek çocuk sayısına bağlıdır', () {
      final GameState evli = evlen(oyuncu(19));
      final int cocuksuz = LivingCosts.yearlyCost(evli);

      final GameState tekCocuk = ebeveynlik.haveChild(evli, Random(6)).state;
      final int birCocukla = LivingCosts.yearlyCost(tekCocuk);
      expect(birCocukla, greaterThan(cocuksuz));

      final GameState ikiCocuk = ebeveynlik
          .haveChild(cocuklariBuyut(tekCocuk), Random(7))
          .state;
      expect(LivingCosts.yearlyCost(ikiCocuk), greaterThan(birCocukla));
      expect(
        LivingCosts.breakdownFor(ikiCocuk)
            .items
            .where((({String label, int amount}) e) =>
                e.label.startsWith('Çocuk gideri'))
            .length,
        1,
        reason: 'Çocuk gideri tek kalemde toplanır',
      );

      // Evden çıkan çocuk gider kalemine girmez.
      final GameState buyudu = ikiCocuk.copyWith(
        people: ikiCocuk.people
            .map((Person p) => p.relation == RelationType.cocuk
                ? p.copyWith(age: 30, inPlayerHousehold: false)
                : p)
            .toList(growable: false),
      );
      expect(LivingCosts.yearlyCost(buyudu), cocuksuz);
    });

    test('çocuk yaş aldıkça büyür ve zamanı gelince evden çıkar', () {
      GameState state = evlen(oyuncu(20, age: 40));
      state = ebeveynlik.haveChild(state, Random(8)).state;
      final String cocukId = state.children.single.id;
      state = state.copyWith(
        people: state.people
            .map((Person p) => p.id == cocukId
                ? p.copyWith(age: Parenthood.prototypeOnlyLeaveHomeAge - 1)
                : p)
            .toList(growable: false),
      );

      final GameState sonra = LifeProgression(Random(5)).advanceOneYear(state);
      final Person cocuk = sonra.personById(cocukId)!;

      expect(cocuk.age, Parenthood.prototypeOnlyLeaveHomeAge);
      expect(cocuk.inPlayerHousehold, isFalse);
      expect(sonra.personById(cocukId), isNotNull,
          reason: 'Evden çıkan çocuğun kaydı silinmez');
      expect(sonra.isReachable(cocuk), isTrue);
    });

    test('yıllık gider çocukla birlikte yine bir kez uygulanır', () {
      GameState state = evlen(oyuncu(21, age: 40));
      state = ebeveynlik.haveChild(state, Random(9)).state;
      state = state.copyWith(
        player: state.player.copyWith(wallet: 900000),
        pendingEvent: null,
      );

      final int cuzdan = state.player.wallet;
      final GameState sonra = LifeProgression(Random(11)).advanceOneYear(state);
      final int gider = LivingCosts.yearlyCost(state);
      // Maaş, miras ve kira yoksa tek çıkış geçim gideridir.
      expect(sonra.player.wallet, cuzdan - gider);
    });
  });

  // ===================================================================
  // Kayıt
  // ===================================================================
  group('Evlilik ve çocuk kaydı', () {
    test('evlilik ve çocuklar kaydedilip geri okunur', () async {
      GameState state = evlen(oyuncu(22));
      state = ebeveynlik.haveChild(state, Random(12)).state;

      final SaveService service = SaveService(MemorySaveStore());
      await service.save(state);
      final SaveLoadResult result = await service.load();
      expect(result.isLoaded, isTrue, reason: result.message);

      final GameState geri = result.state!;
      expect(geri.marriage!.spouseId, state.marriage!.spouseId);
      expect(geri.marriage!.status, MarriageStatus.evli);
      expect(geri.marriage!.marriedAtAge, state.marriage!.marriedAtAge);
      expect(geri.isMarried, isTrue);
      expect(geri.children.length, 1);
      expect(geri.children.single.id, state.children.single.id);
      expect(geri.children.single.firstName, state.children.single.firstName);
      expect(geri.player.wallet, state.player.wallet,
          reason: 'Yükleme masrafları yeniden kesmemeli');
    });

    test('boşanmış kayıt da olduğu gibi geri okunur', () async {
      final GameState state = evlilik.divorce(evlen(oyuncu(23))).state;

      final SaveService service = SaveService(MemorySaveStore());
      await service.save(state);
      final GameState geri = (await service.load()).state!;

      expect(geri.marriage!.status, MarriageStatus.bosandi);
      expect(geri.marriage!.endedAtAge, state.marriage!.endedAtAge);
      expect(
        geri.personById(geri.marriage!.spouseId)!.relation,
        RelationType.eskiEs,
      );
    });

    test('desteklenen en eski sürümün kaydı bekâr olarak açılır, kişiler korunur', () async {
      final GameState state = sevgiliEkle(oyuncu(24)).state;
      final Map<String, Object?> body = encodeGameState(state)
        ..remove('marriage');

      final SaveLoadResult result = await SaveService(
        MemorySaveStore(
          initial: jsonEncode(
            <String, Object?>{'formatVersion': 21, 'state': body},
          ),
        ),
      ).load();
      expect(result.isLoaded, isTrue, reason: result.message);

      final GameState geri = result.state!;
      expect(geri.marriage, isNull);
      expect(geri.isMarried, isFalse);
      expect(geri.children, isEmpty);
      expect(geri.people.length, state.people.length,
          reason: 'Kişiler korunur');
      expect(geri.player.wallet, state.player.wallet);
    });
  });
}
