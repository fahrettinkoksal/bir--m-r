// Olay kataloğu ölçüm aracı (Paket 4).
//
// Oyuna yeni bir şey eklemez: çok sayıda hayatı gerçek motorlarla oynatır
// ve olay kataloğunun kapsamını ölçer. Hangi yaşlarda olay çıkmıyor,
// hangi olaylar çok tekrarlanıyor, hangileri hiç görünmüyor?
//
// Çalıştırma: app dizininde
//   flutter test tool/event_report.dart
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:bir_omur/data/event_pool.dart';
import 'package:bir_omur/data/health_crisis_catalog.dart';
import 'package:bir_omur/data/shop_catalog.dart';
import 'package:bir_omur/domain/economy/housing.dart';
import 'package:bir_omur/domain/events/event_engine.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/generation/life_progression.dart';
import 'package:bir_omur/domain/interaction/item_actions.dart';
import 'package:bir_omur/domain/interaction/marriage_engine.dart';
import 'package:bir_omur/domain/interaction/parenthood.dart';
import 'package:bir_omur/domain/interaction/romance.dart';
import 'package:bir_omur/domain/life/health_crisis_engine.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/owned_item.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/social/social_engine.dart';
import 'package:bir_omur/data/social_catalog.dart';

const int kHayatSayisi = 300;

void main() {
  test('olay raporu', _rapor, timeout: const Timeout(Duration(minutes: 10)));
}

void _rapor() {
  final Map<String, int> olayAdedi = <String, int>{};
  final Map<int, int> yasBasinaOlay = <int, int>{};
  final Map<int, int> yasBasinaAdim = <int, int>{};
  final Map<String, int> ayniHayattaTekrar = <String, int>{};
  int toplamAdim = 0;
  int toplamOlay = 0;

  for (int seed = 1; seed <= kHayatSayisi; seed++) {
    final Random rng = Random(seed);
    GameState state =
        LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
    final Map<String, int> buHayatta = <String, int>{};
    bool evlendi = false;

    while (!state.deceased && state.player.age < 120) {
      state = state.copyWith(pendingEvent: null);
      state = LifeProgression(rng).advanceOneYear(state);
      final int yas = state.player.age;
      toplamAdim++;
      yasBasinaAdim[yas] = (yasBasinaAdim[yas] ?? 0) + 1;

      if (state.hasPendingCrisis) {
        final HealthCrisis kriz = state.pendingCrisis!.crisis!;
        const HealthCrisisEngine motor = HealthCrisisEngine();
        final CrisisChoice secim = kriz.choices.firstWhere(
          (CrisisChoice c) => motor.canChoose(state, c),
          orElse: () => kriz.choices.last,
        );
        state = motor.respond(state, secim.id, rng).state;
      }
      if (state.deceased) break;

      // Açılış olayı: kaydet ve ilk seçenekle çöz.
      final ActiveEvent? olay = state.pendingEvent;
      if (olay != null) {
        toplamOlay++;
        olayAdedi[olay.eventId] = (olayAdedi[olay.eventId] ?? 0) + 1;
        buHayatta[olay.eventId] = (buHayatta[olay.eventId] ?? 0) + 1;
        yasBasinaOlay[yas] = (yasBasinaOlay[yas] ?? 0) + 1;
        state = const EventEngine()
            .resolve(state, olay.choices.first.id, rng: rng);
      }

      // Hayatın olağan akışı: iş, evlilik, çocuk, ev.
      if (yas == 24 && !state.career.isEmployed) {
        state = state.copyWith(
          career: state.career.copyWith(
            jobId: <String>[
              'magaza_calisani',
              'garson',
              'teknik_servis',
              'ressam_tasarimci',
              'yazilim_gelistirici',
              'ogretmen',
            ][seed % 6],
            startedAtAge: yas,
            lastPaidAge: yas,
            jobCity: state.player.currentCity,
          ),
          storyFlags: <String>{
            ...state.storyFlags,
            StoryFlags.calismaHayati,
          },
        );
      }
      // Hayatların bir bölümünde sosyal medya ve araç da olsun; bu
      // olayların ölçüme girmesi için gerekir.
      if (yas == 20 && seed.isEven && state.socialAccounts.isEmpty) {
        state = const SocialEngine()
            .openAccount(state, SocialPlatform.values.first)
            .state;
      }
      if (yas == 30 && seed % 3 == 0) {
        state = state
            .copyWith(licenses: <String>{'otomobil_ehliyeti'})
            .grantItems(<String>['otomobil_ikinci_el'],
                source: ItemSource.satinAlma);
      }
      if (yas == 22 && !const Romance().hasPartner(state)) {
        state = const Romance().start(state, rng).state;
        state = state.copyWith(
          people: state.people
              .map((Person p) => p.relation == RelationType.sevgili
                  ? p.copyWith(bond: 80)
                  : p)
              .toList(growable: false),
        );
      }
      if (yas >= 26 && !evlendi) {
        final Person? sevgili = const Romance().partnerOf(state);
        if (sevgili != null &&
            const MarriageEngine().marryBlockReason(state, sevgili).isEmpty) {
          state = const MarriageEngine().marry(state, sevgili.id).state;
          evlendi = true;
        }
      }
      if (state.isMarried && (yas == 29 || yas == 32)) {
        final FamilyResult r = const Parenthood().haveChild(state, rng);
        if (r.outcome.applied) state = r.state;
      }
      if (yas == 42 && state.items.every((OwnedItem i) => !i.isProperty)) {
        final ItemActionResult alim = const ItemActions().buy(
          state: state,
          product: shopProductByTypeId('kucuk_daire')!,
        );
        if (alim.outcome.applied) {
          state = const Housing().moveInto(alim.state, alim.state.items.last).state;
        }
      }
    }

    for (final MapEntry<String, int> e in buHayatta.entries) {
      if (e.value > 1) {
        ayniHayattaTekrar[e.key] =
            (ayniHayattaTekrar[e.key] ?? 0) + e.value - 1;
      }
    }
  }

  print('=== OLAY KAPSAMI ($kHayatSayisi hayat) ===');
  print('Katalogdaki olay sayısı : ${kEventPool.length}');
  print('Toplam yaş adımı        : $toplamAdim');
  print('Toplam gösterilen olay  : $toplamOlay');
  print('Yaş başına olay oranı   : '
      '%${(toplamOlay * 100 / toplamAdim).toStringAsFixed(1)}');
  print('');

  print('--- Yaş aralığına göre olay çıkma oranı ---');
  for (int start = 0; start <= 95; start += 5) {
    int adim = 0;
    int olay = 0;
    for (int a = start; a < start + 5; a++) {
      adim += yasBasinaAdim[a] ?? 0;
      olay += yasBasinaOlay[a] ?? 0;
    }
    if (adim == 0) continue;
    final double oran = olay * 100 / adim;
    final String bar = '#' * (oran / 4).round();
    print('${start.toString().padLeft(3)}-${(start + 4).toString().padLeft(3)}: '
        '${oran.toStringAsFixed(0).padLeft(3)}%  $bar');
  }
  print('');

  print('--- En sık gösterilen olaylar ---');
  final List<MapEntry<String, int>> sirali = olayAdedi.entries.toList()
    ..sort((MapEntry<String, int> a, MapEntry<String, int> b) =>
        b.value.compareTo(a.value));
  for (final MapEntry<String, int> e in sirali.take(12)) {
    print('${e.key.padRight(32)} ${e.value.toString().padLeft(5)} '
        '(hayat başına ${(e.value / kHayatSayisi).toStringAsFixed(2)})');
  }
  print('');

  print('--- Aynı hayatta tekrarlananlar ---');
  final List<MapEntry<String, int>> tekrar = ayniHayattaTekrar.entries.toList()
    ..sort((MapEntry<String, int> a, MapEntry<String, int> b) =>
        b.value.compareTo(a.value));
  if (tekrar.isEmpty) {
    print('(yok)');
  }
  for (final MapEntry<String, int> e in tekrar.take(10)) {
    print('${e.key.padRight(32)} ${e.value} fazladan gösterim');
  }
  print('');

  print('--- Hiç gösterilmeyen olaylar ---');
  final List<String> hic = <String>[
    for (final GameEvent e in kEventPool)
      if (!olayAdedi.containsKey(e.id)) e.id,
  ];
  print(hic.isEmpty ? '(yok)' : hic.join(', '));
}
