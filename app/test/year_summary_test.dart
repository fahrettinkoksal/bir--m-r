import 'dart:math';

import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/life/year_review.dart';
import 'package:bir_omur/domain/models/applied_effect.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/stats.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:bir_omur/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_flow.dart';

/// Yıl sonu özeti (D-096).
///
/// Özet **gerçekten uygulanmış** değişimlerden üretilir; uydurma satır
/// yazılmaz ve eski yılın özeti ekranda bırakılmaz.
void main() {
  GameController yeniHayat({int seed = 12}) {
    final GameController controller = GameController(random: Random(seed));
    controller.startNewLife(mode: StartMode.tamamenRastgele, seed: seed);
    return controller;
  }

  test('yeni hayat yılın başındaki fotoğrafla başlar', () {
    final GameController controller = yeniHayat();
    expect(controller.state!.yearMark, isNotNull);
    expect(controller.state!.yearMark!.age, controller.state!.player.age);
    // Henüz bir yıl geçmediği için özet yoktur.
    expect(controller.state!.lastYearSummary, isNull);
  });

  test('yaş alınca biten yılın özeti üretilir', () {
    final GameController controller = yeniHayat();
    final int yas = controller.state!.player.age;
    resolveEducationChoices(controller);
    controller.ageUp();

    final GameState sonra = controller.state!;
    // Özet **biten** yıla aittir.
    if (sonra.lastYearSummary != null) {
      expect(sonra.lastYearSummary!.age, yas);
      expect(sonra.lastYearSummary!.effects, isNotEmpty);
    }
    // Yeni yıl için yeni fotoğraf alınır.
    expect(sonra.yearMark, isNotNull);
    expect(sonra.yearMark!.age, sonra.player.age);
  });

  test('özet satırları gerçekten uygulanmış değişimdir', () {
    final GameController controller = yeniHayat();
    final GameState once = controller.state!;
    final YearMark mark = once.yearMark!;

    // Mutluluğu elle değiştirip özeti hesaplat: fark ne ise satır odur.
    final GameState degisen = once.copyWith(
      player: once.player.copyWith(
        stats: once.player.stats.copyWith(
          happiness: once.player.stats.happiness - 7,
        ),
      ),
    );
    final YearSummary? ozet = YearReview.summarize(mark, degisen);
    expect(ozet, isNotNull);
    final AppliedEffect mutluluk = ozet!.effects.firstWhere(
      (AppliedEffect e) => e.label == 'Mutluluk',
    );
    expect(
      mutluluk.delta,
      degisen.player.stats.happiness - once.player.stats.happiness,
    );
  });

  test('tavana dayanmış değer için sahte artış yazılmaz', () {
    final GameController controller = yeniHayat();
    final GameState once = controller.state!;
    final GameState tavan = once.copyWith(
      player: once.player.copyWith(
        stats: const Stats(
          appearance: 100,
          happiness: 100,
          health: 100,
          intelligence: 100,
          charisma: 100,
        ),
      ),
    );
    // Fotoğraf da tavandaysa hiçbir satır çıkmaz.
    final YearSummary? ozet = YearReview.summarize(
      YearMark.of(tavan),
      tavan.copyWith(
        player: tavan.player.copyWith(
          stats: tavan.player.stats.copyWith(happiness: 120),
        ),
      ),
    );
    expect(ozet, isNull);
  });

  test('başka yıla ait fotoğraftan özet üretilmez', () {
    final GameController controller = yeniHayat();
    final GameState state = controller.state!;
    final YearMark eski = YearMark(
      age: state.player.age + 3,
      stats: state.player.stats,
      wallet: state.player.wallet,
    );
    expect(YearReview.summarize(eski, state), isNull);
  });

  test('özet kayıt açılıp kapandığında korunur', () {
    final GameController controller = yeniHayat();
    resolveEducationChoices(controller);
    controller.ageUp();

    final GameState geri = decodeGameState(encodeGameState(controller.state!));
    expect(geri.yearMark, isNotNull);
    expect(geri.yearMark!.age, controller.state!.yearMark!.age);
    expect(
      geri.lastYearSummary?.effects.length,
      controller.state!.lastYearSummary?.effects.length,
    );
  });

  test('uzun hayatta her yıl kendi özetini taşır', () {
    final GameController controller = yeniHayat(seed: 31);
    advanceToAge(controller, 30);
    final GameState state = controller.state!;
    if (state.deceased) return;
    final YearSummary? ozet = state.lastYearSummary;
    if (ozet != null) {
      expect(ozet.age, state.player.age - 1);
      // Yalnızca oyuncunun kendi değerleri: kişi adı içeren satır olmaz.
      for (final AppliedEffect e in ozet.effects) {
        expect(
          e.label,
          anyOf(
            'Dış görünüş',
            'Mutluluk',
            'Sağlık',
            'Zekâ',
            'Karizma',
            'Cüzdan',
            'Ün',
          ),
        );
      }
    }
  });

  testWidgets('yıl özeti kartı ana ekranda görünür', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 4800);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final GameController controller = GameController(random: Random(9));
    addTearDown(controller.dispose);
    await tester.pumpWidget(BirOmurApp(controller: controller));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rastgele bir hayat'));
    await tester.pumpAndSettle();

    // Henüz yıl geçmedi: kart yok.
    expect(find.byKey(const Key('year_summary_card')), findsNothing);

    final GameState state = controller.state!;
    controller.debugSetState(
      state.copyWith(
        pendingEvent: null,
        lastYearSummary: YearSummary(
          age: state.player.age,
          effects: const <AppliedEffect>[
            AppliedEffect(label: 'Mutluluk', delta: -6),
            AppliedEffect(label: 'Cüzdan', delta: 1200, unit: ' ₺'),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('year_summary_card')), findsOneWidget);
    expect(
      find.text('${state.player.age} yaşın böyle geçti'),
      findsOneWidget,
    );
    expect(find.text('Mutluluk -6'), findsOneWidget);
    expect(find.text('Cüzdan +1200 ₺'), findsOneWidget);
    // Günlük başlığı kartın altında durmaya devam eder.
    expect(find.text('Hayat günlüğü'), findsOneWidget);
  });
}
