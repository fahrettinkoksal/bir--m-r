import 'dart:math';

import 'package:bir_omur/data/health_crisis_catalog.dart';
import 'package:bir_omur/data/shop_catalog.dart';
import 'package:bir_omur/domain/economy/housing.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/generation/life_progression.dart';
import 'package:bir_omur/domain/interaction/item_actions.dart';
import 'package:bir_omur/domain/interaction/marriage_engine.dart';
import 'package:bir_omur/domain/interaction/parenthood.dart';
import 'package:bir_omur/domain/interaction/romance.dart';
import 'package:bir_omur/domain/life/health_crisis_engine.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/marriage.dart';
import 'package:bir_omur/domain/models/owned_item.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/invariants.dart';

/// Aile hayatını **gerçek motorlarla** oynayan toplu simülasyon.
///
/// Amaç sayı üretmek değil: evlilik, çocuk, hane, taşınma, ölüm ve miras
/// birlikte çalışırken tutarsızlık çıkıyor mu, onu aramak. Her yıl
/// [checkInvariants] çalışır; tek bir ihlal bile testi düşürür.
({
  int deathAge,
  bool married,
  int children,
  List<String> issues,
}) _oynat(int seed) {
  final Random rng = Random(seed);
  GameState state =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  const MarriageEngine evlilik = MarriageEngine();
  const Parenthood ebeveynlik = Parenthood();
  const ItemActions esyalar = ItemActions();
  const Housing konut = Housing();
  const HealthCrisisEngine krizler = HealthCrisisEngine();

  final List<String> sorunlar = <String>[];
  bool evlendi = false;

  while (!state.deceased && state.player.age < 130) {
    state = state.copyWith(pendingEvent: null);
    state = LifeProgression(rng).advanceOneYear(state);

    if (state.hasPendingCrisis) {
      final HealthCrisis kriz = state.pendingCrisis!.crisis!;
      final CrisisChoice secim = kriz.choices.firstWhere(
        (CrisisChoice c) => krizler.canChoose(state, c),
        orElse: () => kriz.choices.last,
      );
      state = krizler.respond(state, secim.id, rng).state;
    }
    if (state.deceased) break;

    final int yas = state.player.age;

    // Gerçekçi bir hayat için gelir gerekir: 24 yaşında bir işe girilmiş
    // sayılır (mülakat akışı ayrı testlerde sınanıyor).
    if (yas == 24 && !state.career.isEmployed) {
      const List<String> isler = <String>[
        'magaza_calisani',
        'garson',
        'teknik_servis',
        'ressam_tasarimci',
        'yazilim_gelistirici',
        'ogretmen',
      ];
      state = state.copyWith(
        career: state.career.copyWith(
          jobId: isler[seed % isler.length],
          startedAtAge: yas,
          lastPaidAge: yas,
        ),
      );
    }

    // Hayatın normal akışı: tanışma, evlilik, çocuk, ev.
    if (yas == 22 && !const Romance().hasPartner(state) && !state.isMarried) {
      state = const Romance().start(state, rng).state;
      // Yakınlık evlilik eşiğine gelsin diye ilişki sürdürülüyor sayılır.
      state = state.copyWith(
        people: state.people
            .map((Person p) => p.relation == RelationType.sevgili
                ? p.copyWith(bond: 80)
                : p)
            .toList(growable: false),
      );
    }
    if (yas >= 25 && !evlendi) {
      final Person? sevgili = const Romance().partnerOf(state);
      if (sevgili != null) {
        // Nikâh parası olsun diye maaş beklenmez; eksikse evlenilmez.
        final MarriageEngine motor = evlilik;
        if (motor.marryBlockReason(state, sevgili).isEmpty) {
          state = motor.marry(state, sevgili.id).state;
          evlendi = true;
        }
      }
    }
    if (evlendi && state.isMarried && (yas == 28 || yas == 31 || yas == 34)) {
      final FamilyResult r = ebeveynlik.haveChild(state, rng);
      if (r.outcome.applied) state = r.state;
    }
    if (yas == 40 && state.items.every((OwnedItem i) => !i.isProperty)) {
      final ItemActionResult alim = esyalar.buy(
        state: state,
        product: shopProductByTypeId('kucuk_daire')!,
      );
      if (alim.outcome.applied) {
        state = konut.moveInto(alim.state, alim.state.items.last).state;
      }
    }

    sorunlar.addAll(checkInvariants(state, where: 'tohum $seed / yaş $yas'));
    if (sorunlar.length > 5) break;
  }

  sorunlar.addAll(checkInvariants(state, where: 'tohum $seed / ölüm'));
  return (
    deathAge: state.deathAge ?? state.player.age,
    married: state.marriage != null,
    children: state.children.length,
    issues: sorunlar,
  );
}

void main() {
  test('200 aile hayatı tutarsızlık üretmez', () {
    final List<String> sorunlar = <String>[];
    int evlenen = 0;
    int cocukluHayat = 0;
    int toplamCocuk = 0;
    int ulasilanYas = 0;

    for (int seed = 1; seed <= 200; seed++) {
      final ({
        int deathAge,
        bool married,
        int children,
        List<String> issues,
      }) sonuc = _oynat(seed);
      sorunlar.addAll(sonuc.issues);
      if (sonuc.married) evlenen++;
      if (sonuc.children > 0) cocukluHayat++;
      toplamCocuk += sonuc.children;
      ulasilanYas += sonuc.deathAge;
      if (sorunlar.length > 20) break;
    }

    // Simülasyonun gerçekten aile hayatını oynadığını doğrula: evlilik hiç
    // kurulmuyorsa test bir şey ölçmüyor demektir.
    expect(evlenen, greaterThan(100), reason: 'Evlilik akışı oynanmalı');
    expect(cocukluHayat, greaterThan(80), reason: 'Çocuk akışı oynanmalı');
    expect(toplamCocuk, greaterThan(150));
    expect(ulasilanYas ~/ 200, greaterThan(40));
    expect(sorunlar, isEmpty);
  }, timeout: const Timeout(Duration(minutes: 5)));

  test('evlilik kaydı olan hayatta eş bağı hep tek kalır', () {
    for (int seed = 300; seed < 320; seed++) {
      final Random rng = Random(seed);
      GameState state =
          LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
      state = state.copyWith(
        player: state.player.copyWith(age: 26, wallet: 1000000),
      );
      final ({GameState state, Person partner}) r =
          const Romance().start(state, rng);
      state = r.state.copyWith(
        people: r.state.people
            .map((Person p) =>
                p.id == r.partner.id ? p.copyWith(bond: 90) : p)
            .toList(growable: false),
      );
      state = const MarriageEngine().marry(state, r.partner.id).state;

      for (int i = 0; i < 30 && !state.deceased; i++) {
        state = state.copyWith(pendingEvent: null);
        state = LifeProgression(rng).advanceOneYear(state);
        if (state.hasPendingCrisis) {
          state = const HealthCrisisEngine()
              .respond(state, state.pendingCrisis!.crisis!.choices.last.id, rng)
              .state;
        }
        expect(
          state.people
              .where((Person p) => p.relation == RelationType.es)
              .length,
          1,
          reason: 'Tohum $seed: eş bağı tek olmalı',
        );
        final Marriage kayit = state.marriage!;
        final Person es = state.personById(kayit.spouseId)!;
        if (!es.isAlive) {
          expect(kayit.status, MarriageStatus.dul,
              reason: 'Tohum $seed: vefat eden eş hâlâ "evli" görünüyor');
        }
      }
    }
  }, timeout: const Timeout(Duration(minutes: 3)));
}
