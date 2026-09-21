import 'dart:convert';
import 'dart:math';

import 'package:bir_omur/data/health_crisis_catalog.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/data/save/save_service.dart';
import 'package:bir_omur/data/save/save_store.dart';
import 'package:bir_omur/data/shop_catalog.dart';
import 'package:bir_omur/domain/economy/housing.dart';
import 'package:bir_omur/domain/economy/living_costs.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/generation/life_progression.dart';
import 'package:bir_omur/domain/interaction/family_interactions.dart';
import 'package:bir_omur/domain/interaction/item_actions.dart';
import 'package:bir_omur/domain/interaction/marriage_engine.dart';
import 'package:bir_omur/domain/interaction/parenthood.dart';
import 'package:bir_omur/domain/interaction/romance.dart';
import 'package:bir_omur/domain/life/health_crisis_engine.dart';
import 'package:bir_omur/domain/life/inheritance.dart';
import 'package:bir_omur/domain/life/mortality.dart';
import 'package:bir_omur/domain/models/life_log.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/marriage.dart';
import 'package:bir_omur/domain/models/owned_item.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/life_summary.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/invariants.dart';

const MarriageEngine evlilik = MarriageEngine();
const Parenthood ebeveynlik = Parenthood();
const ItemActions esyalar = ItemActions();
const FamilyInteractions etkilesim = FamilyInteractions();

/// Bir yıl ilerletir: ekrandaki olay ve kriz kapatılır, her adımda
/// tutarlılık kuralları sınanır.
GameState yilIlerlet(GameState state, Random rng, {String nerede = ''}) {
  GameState next = state.copyWith(pendingEvent: null);
  next = LifeProgression(rng).advanceOneYear(next);
  if (next.hasPendingCrisis) {
    const HealthCrisisEngine motor = HealthCrisisEngine();
    final HealthCrisis kriz = next.pendingCrisis!.crisis!;
    final CrisisChoice secim = kriz.choices.firstWhere(
      (CrisisChoice c) => motor.canChoose(next, c),
      orElse: () => kriz.choices.last,
    );
    next = motor.respond(next, secim.id, rng).state;
  }
  expect(checkInvariants(next, where: nerede), isEmpty);
  return next;
}

GameState yillarIlerlet(GameState state, Random rng, int yil,
    {String nerede = ''}) {
  GameState next = state;
  for (int i = 0; i < yil && !next.deceased; i++) {
    next = yilIlerlet(next, rng, nerede: nerede);
  }
  return next;
}

/// Sevgilisi olan, evlenmeye uygun bir hayat kurar.
({GameState state, Person partner}) sevgiliyle(int seed,
    {int age = 26, int wallet = 6000000}) {
  final GameState base =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  final ({GameState state, Person partner}) r = const Romance().start(
    base.copyWith(player: base.player.copyWith(age: age, wallet: wallet)),
    Random(seed + 1),
  );
  final GameState state = r.state.copyWith(
    people: r.state.people
        .map((Person p) => p.id == r.partner.id ? p.copyWith(bond: 85) : p)
        .toList(growable: false),
  );
  return (state: state, partner: state.personById(r.partner.id)!);
}

GameState kisiyiOldur(GameState state, String id, {WealthTier? wealth}) =>
    state.copyWith(
      people: state.people
          .map((Person p) => p.id == id
              ? p.copyWith(
                  isAlive: false,
                  inPlayerHousehold: false,
                  wealth: wealth ?? p.wealth,
                )
              : p)
          .toList(growable: false),
    );

void main() {
  // ===================================================================
  // Bütün zincir
  // ===================================================================
  test('tanışma → evlilik → çocuk → ev → ölüm → miras zinciri tutarlı kalır',
      () async {
    final Random rng = Random(4242);
    final ({GameState state, Person partner}) baslangic = sevgiliyle(101);
    GameState state = baslangic.state;
    expect(checkInvariants(state, where: 'başlangıç'), isEmpty);

    // 1) Evlilik: aynı kimlik, yeni kişi yok.
    final int kisiSayisi = state.people.length;
    state = evlilik.marry(state, baslangic.partner.id).state;
    expect(state.people.length, kisiSayisi, reason: 'İkinci NPC üretilmemeli');
    expect(state.isMarried, isTrue);
    expect(state.spouse!.inPlayerHousehold, isTrue);
    expect(checkInvariants(state, where: 'evlilik'), isEmpty);

    // 2) Çocuk: gerçek kişi kaydı.
    state = ebeveynlik.haveChild(state, rng).state;
    final String cocukId = state.children.single.id;
    expect(checkInvariants(state, where: 'çocuk'), isEmpty);

    // 3) Ev alıp taşınma.
    final ItemActionResult alim = esyalar.buy(
      state: state,
      product: shopProductByTypeId('kucuk_daire')!,
    );
    expect(alim.outcome.applied, isTrue, reason: alim.outcome.text);
    state = alim.state;
    final OwnedItem ev = state.items.last;
    state = const Housing().moveInto(state, ev).state;
    expect(Housing.residenceOf(state), ResidenceKind.kendiEvinde);
    expect(checkInvariants(state, where: 'taşınma'), isEmpty);

    // 4) Yıllar: çocuk büyür, herkes birlikte yaşlanır.
    final int cocukYasi = state.personById(cocukId)!.age;
    final int oyuncuYasi = state.player.age;
    state = yillarIlerlet(state, rng, 10, nerede: 'on yıl');
    if (!state.deceased) {
      expect(state.player.age, oyuncuYasi + 10);
      expect(state.personById(cocukId)!.age, cocukYasi + 10);
      expect(state.personById(cocukId)!.inPlayerHousehold, isTrue);
      // Eş hâlâ eş; ilişkiler listesinden kaybolmadı.
      expect(state.personById(state.marriage!.spouseId), isNotNull);
    }

    // 5) Eşin vefatı: kayıt dul olur, miras bir kez gelir.
    final String esId = state.marriage!.spouseId;
    state = kisiyiOldur(state, esId, wealth: WealthTier.ortaHalli);
    final int cuzdanOnce = state.player.wallet;
    state = yilIlerlet(state, rng, nerede: 'eşin vefatı');
    expect(state.marriage!.status, MarriageStatus.dul);
    expect(state.personById(esId), isNotNull, reason: 'Kayıt silinmez');
    expect(state.settledEstates.contains(esId), isTrue);
    expect(state.player.wallet, greaterThan(cuzdanOnce - 1000000));

    // Miras ikinci kez dağıtılmaz.
    final int cuzdanSonra = state.player.wallet;
    final GameState tekrar =
        Inheritance.settle(state, state.personById(esId)!).state;
    expect(tekrar.player.wallet, cuzdanSonra);

    // 6) Vefat etmiş eşle etkileşim açılmaz.
    expect(
      etkilesim.availability(state, state.personById(esId)!).isAllowed,
      isFalse,
    );
    expect(etkilesim.availableKinds(state, state.personById(esId)!), isEmpty);

    // 7) Kayıt: bütün zincir kaydedilip geri okunur.
    final SaveService service = SaveService(MemorySaveStore());
    await service.save(state);
    final GameState geri = (await service.load()).state!;
    expect(checkInvariants(geri, where: 'kayıt'), isEmpty);
    expect(geri.marriage!.status, MarriageStatus.dul);
    expect(geri.children.length, state.children.length);
    expect(geri.residenceItemId, state.residenceItemId);
    expect(geri.player.wallet, state.player.wallet);
  });

  // ===================================================================
  // Tek tek hata sınıfları
  // ===================================================================
  group('Evlilik ve hane', () {
    test('kendi evinde yaşayan evlenince kiracıya dönüşmez', () {
      final ({GameState state, Person partner}) v = sevgiliyle(102);
      final ItemActionResult alim = esyalar.buy(
        state: v.state,
        product: shopProductByTypeId('kucuk_daire')!,
      );
      expect(alim.outcome.applied, isTrue, reason: alim.outcome.text);
      GameState state =
          const Housing().moveInto(alim.state, alim.state.items.last).state;
      expect(Housing.residenceOf(state), ResidenceKind.kendiEvinde);
      final int giderOnce = LivingCosts.yearlyCost(state);

      state = evlilik.marry(state, v.partner.id).state;

      expect(Housing.residenceOf(state), ResidenceKind.kendiEvinde,
          reason: 'Evlenmek kendi evini elinden almaz');
      expect(LivingCosts.situationOf(state), LivingSituation.kendiEvinde);
      expect(LivingCosts.yearlyCost(state), giderOnce);
      expect(state.residenceItemId, isNotNull);
    });

    test('ailesinin yanında evlenen kendi hanesini kurar', () {
      final ({GameState state, Person partner}) v = sevgiliyle(103);
      expect(Housing.residenceOf(v.state), ResidenceKind.aileYaninda);

      final GameState state = evlilik.marry(v.state, v.partner.id).state;
      expect(Housing.residenceOf(state), ResidenceKind.kirada);
      expect(state.movedOut, isTrue);
      // Eşin kendisi "ailenin yanındaki yetişkin" sayılmaz: eş hanedeyken
      // bile oyuncu ailesinin yanında görünmez.
      final GameState ebeveynsiz = state.copyWith(
        people: state.people
            .map((Person p) => p.relation.haneBagi
                ? p
                : p.copyWith(inPlayerHousehold: false))
            .toList(growable: false),
      );
      expect(Housing.hasAdultAtFamilyHome(ebeveynsiz), isFalse);
    });

    test('boşanınca hane, ilişki ve miras verileri birlikte güncellenir', () {
      final ({GameState state, Person partner}) v = sevgiliyle(104);
      GameState state = evlilik.marry(v.state, v.partner.id).state;
      state = evlilik.divorce(state).state;

      final Person eskiEs = state.personById(v.partner.id)!;
      expect(eskiEs.relation, RelationType.eskiEs);
      expect(eskiEs.inPlayerHousehold, isFalse);
      expect(state.isMarried, isFalse);
      expect(state.marriage!.status, MarriageStatus.bosandi);
      expect(checkInvariants(state), isEmpty);

      // Boşanmış eşin mirası oyuncuya gelmez.
      final GameState olum =
          kisiyiOldur(state, eskiEs.id, wealth: WealthTier.cokVarlikli);
      final int cuzdan = olum.player.wallet;
      expect(
        Inheritance.settle(olum, olum.personById(eskiEs.id)!)
            .state
            .player
            .wallet,
        cuzdan,
      );
    });

    test('eş vefat edince yeni evlilik kaydı eskisini ezmez', () {
      final ({GameState state, Person partner}) v = sevgiliyle(105);
      GameState state = evlilik.marry(v.state, v.partner.id).state;
      final Marriage ilk = state.marriage!;
      state = kisiyiOldur(state, ilk.spouseId);
      state = evlilik.settleWidowhood(state, state.player.age);

      final ({GameState state, Person partner}) yeni =
          const Romance().start(state, Random(9));
      expect(
        evlilik.marry(yeni.state, yeni.partner.id).outcome.applied,
        isFalse,
        reason: 'İkinci evlilik ilk kaydı ezmemeli',
      );
      expect(state.marriage!.spouseId, ilk.spouseId);
      expect(state.marriage!.status, MarriageStatus.dul);
    });
  });

  group('Çocuklar ve hane', () {
    test('çocuk yıllar boyunca doğru yaşlanır ve ilişkilerde kalır', () {
      final Random rng = Random(77);
      final ({GameState state, Person partner}) v = sevgiliyle(106, age: 25);
      GameState state = evlilik.marry(v.state, v.partner.id).state;
      state = ebeveynlik.haveChild(state, rng).state;
      final String id = state.children.single.id;

      for (int i = 1; i <= 20 && !state.deceased; i++) {
        state = yilIlerlet(state, rng, nerede: 'çocuk $i. yıl');
        final Person cocuk = state.personById(id)!;
        if (!cocuk.isAlive) break;
        expect(cocuk.age, i, reason: 'Çocuk yılda bir yaş almalı');
        expect(state.children.map((Person p) => p.id), contains(id),
            reason: 'Çocuk ilişkiler listesinden kaybolmamalı');
        if (cocuk.age < Parenthood.prototypeOnlyLeaveHomeAge) {
          expect(cocuk.inPlayerHousehold, isTrue);
        }
      }
    });

    test('çocuk gideri yılda bir kez kesilir', () {
      final Random rng = Random(78);
      final ({GameState state, Person partner}) v = sevgiliyle(107, age: 30);
      GameState state = evlilik.marry(v.state, v.partner.id).state;
      state = ebeveynlik.haveChild(state, rng).state;
      state = state.copyWith(
        player: state.player.copyWith(wallet: 3000000),
        pendingEvent: null,
      );

      final int beklenenGider = LivingCosts.yearlyCost(state);
      final int cuzdan = state.player.wallet;
      final GameState sonra = LifeProgression(Random(5)).advanceOneYear(state);

      // Maaş yok, kira geliri yok: tek para çıkışı geçim gideridir.
      expect(sonra.player.wallet, cuzdan - beklenenGider);
      expect(
        sonra.log
            .where((LifeLogEntry e) =>
                e.age == sonra.player.age && e.text.contains('geçim giderin'))
            .length,
        1,
        reason: 'Gider satırı yılda bir kez yazılmalı',
      );
    });

    test('vefat eden çocuğun mirası iki kez dağıtılmaz', () {
      final ({GameState state, Person partner}) v = sevgiliyle(108, age: 40);
      GameState state = evlilik.marry(v.state, v.partner.id).state;
      state = ebeveynlik.haveChild(state, Random(3)).state;
      final String id = state.children.single.id;
      state = state.copyWith(
        people: state.people
            .map((Person p) => p.id == id
                ? p.copyWith(
                    age: 25,
                    // Çocuk kendi hayatında birikim yaptı (D-045); miras
                    // bu gerçek paradan dağıtılır.
                    development: p.development!.copyWith(money: 300000),
                  )
                : p)
            .toList(growable: false),
      );
      state = kisiyiOldur(state, id, wealth: WealthTier.ortaHalli);

      final int cuzdan = state.player.wallet;
      final GameState ilk =
          Inheritance.settle(state, state.personById(id)!).state;
      expect(ilk.player.wallet, greaterThan(cuzdan));
      final GameState ikinci =
          Inheritance.settle(ilk, ilk.personById(id)!).state;
      expect(ikinci.player.wallet, ilk.player.wallet);
      expect(checkInvariants(ikinci), isEmpty);
    });

    test('vefat eden çocukla etkileşim açılmaz', () {
      final ({GameState state, Person partner}) v = sevgiliyle(109, age: 40);
      GameState state = evlilik.marry(v.state, v.partner.id).state;
      state = ebeveynlik.haveChild(state, Random(3)).state;
      final Person cocuk = state.children.single;
      state = kisiyiOldur(state, cocuk.id);

      final Person olen = state.personById(cocuk.id)!;
      expect(etkilesim.availability(state, olen).isAllowed, isFalse);
      expect(etkilesim.availableKinds(state, olen), isEmpty);
    });
  });

  group('Hayat özeti ve arşiv', () {
    test('tamamlanan hayatın arşivinde eş ve çocuk bilgisi kalır', () async {
      final ({GameState state, Person partner}) v = sevgiliyle(111, age: 45);
      GameState state = evlilik.marry(v.state, v.partner.id).state;
      state = ebeveynlik.haveChild(state, Random(3)).state;
      state = state.copyWith(deceased: true, deathAge: 80, deathCause: 'yaşlılık');

      final GameController controller = GameController();
      addTearDown(controller.dispose);
      controller.debugSetState(state);
      controller.clearLife();

      final List<LifeSummary> arsiv = controller.pastLives;
      expect(arsiv, hasLength(1));
      expect(arsiv.single.familyLine, isNotNull);
      expect(arsiv.single.familyLine, contains(v.partner.firstName));
      expect(arsiv.single.familyLine, contains('1 çocuk'));

      // Arşiv yeni hayata taşınır ve kaydedilip geri okunur.
      final GameState yeni = state.copyWith(pastLives: arsiv);
      final SaveService service = SaveService(MemorySaveStore());
      await service.save(yeni);
      final GameState geri = (await service.load()).state!;
      expect(geri.pastLives.single.familyLine, arsiv.single.familyLine);
    });

    test('hiç evlenmemiş hayatın arşivinde uydurma aile satırı olmaz', () {
      final GameState state = LifeGenerator.seeded(112)
          .generate(mode: StartMode.tamamenRastgele)
          .copyWith(deceased: true, deathAge: 70, deathCause: 'yaşlılık');

      final GameController controller = GameController();
      addTearDown(controller.dispose);
      controller.debugSetState(state);
      controller.clearLife();

      expect(controller.pastLives.single.familyLine, isNull);
    });

    test('sürüm 15 arşivi aile satırı olmadan açılır', () async {
      final ({GameState state, Person partner}) v = sevgiliyle(113, age: 40);
      final GameState state = evlilik.marry(v.state, v.partner.id).state;
      final Map<String, Object?> body = encodeGameState(
        state.copyWith(
          pastLives: <LifeSummary>[
            const LifeSummary(
              fullName: 'Eski Hayat',
              birthCity: 'Sivas',
              deathAge: 66,
              deathCause: 'yaşlılık',
              educationLabel: 'Lise',
              careerLabel: 'Çalışmadı',
              wallet: 1000,
              itemCount: 2,
              licenseCount: 0,
              highlights: <String>['20: bir şey oldu'],
              familyLine: 'Eşi: Birisi · 1 çocuk',
            ),
          ],
        ),
      );
      for (final Object? e in body['pastLives']! as List<Object?>) {
        (e! as Map<String, Object?>).remove('familyLine');
      }

      final SaveLoadResult result = await SaveService(
        MemorySaveStore(
          initial: jsonEncode(
            <String, Object?>{'formatVersion': 15, 'state': body},
          ),
        ),
      ).load();
      expect(result.isLoaded, isTrue, reason: result.message);
      expect(result.state!.pastLives.single.familyLine, isNull);
      expect(result.state!.pastLives.single.fullName, 'Eski Hayat');
      expect(result.state!.marriage, isNotNull,
          reason: 'Evlilik kaydı korunur');
    });

    test('eşi kayıtlarda olmayan bozuk kayıt sessizce yüklenmez', () async {
      final ({GameState state, Person partner}) v = sevgiliyle(114, age: 40);
      final GameState state = evlilik.marry(v.state, v.partner.id).state;
      final Map<String, Object?> body = encodeGameState(state);
      (body['marriage']! as Map<String, Object?>)['spouseId'] = 'olmayan-kisi';

      final SaveLoadResult result = await SaveService(
        MemorySaveStore(
          initial: jsonEncode(
            <String, Object?>{'formatVersion': 16, 'state': body},
          ),
        ),
      ).load();
      expect(result.isLoaded, isFalse);
      expect(result.message, isNotNull);
    });
  });

  group('Kayıp ve duygusal etki', () {
    test('eş ve çocuk kaybı uzak bir tanıdıktan daha ağır hissedilir', () {
      final ({GameState state, Person partner}) v = sevgiliyle(110, age: 35);
      GameState state = evlilik.marry(v.state, v.partner.id).state;
      state = ebeveynlik.haveChild(state, Random(3)).state;

      final Person es = state.spouse!;
      final Person cocuk = state.children.single.copyWith(bond: es.bond);
      // Karşılaştırma, yalnızca bağ türünü değiştirerek yapılır: yakınlık
      // ve yaş aynı kalır, böylece ölçülen şey kayıp tablosudur.
      final int esKaybi = Mortality.prototypeOnlyHappinessLoss(es);
      final int cocukKaybi = Mortality.prototypeOnlyHappinessLoss(cocuk);
      final int uzakKayip = Mortality.prototypeOnlyHappinessLoss(
        es.copyWith(relation: RelationType.arkadas),
      );
      final int anneKaybi = Mortality.prototypeOnlyHappinessLoss(
        es.copyWith(relation: RelationType.anne),
      );

      expect(esKaybi, greaterThan(uzakKayip));
      expect(cocukKaybi, greaterThan(uzakKayip));
      // Eş ve çocuk kaybı en az anne kaybı kadar ağır olmalı.
      expect(esKaybi, greaterThanOrEqualTo(anneKaybi));
      expect(cocukKaybi, greaterThanOrEqualTo(anneKaybi));
    });
  });
}
