import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/combat_career.dart';
import 'package:bir_omur/domain/sports/football_career.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_flow.dart';

/// Oyuncu vefat ettiğinde hayat özetinin gerçekten göründüğünü sınar.
void main() {
  late GameController controller;

  setUp(() => controller = GameController(random: Random(41)));
  tearDown(() => controller.dispose());

  GameState tamamlanmisHayat() {
    final GameState base =
        LifeGenerator.seeded(41).generate(mode: StartMode.tamamenRastgele);
    return base.copyWith(
      player: base.player.copyWith(age: 81, wallet: 125000),
      deceased: true,
      deathAge: 81,
      deathCause: 'yaşlılığa bağlı nedenler',
    );
  }

  Future<void> pumpApp(WidgetTester tester, GameState state) async {
    // Hayat özeti değerlendirme paneliyle birlikte uzadı (Paket 22);
    // `findsNothing` beklentileri anlamını korusun diye bütün ekran
    // görünür alana sığdırılır.
    tester.view.physicalSize = const Size(1200, 7200);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(BirOmurApp(controller: controller));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rastgele bir hayat'));
    await tester.pumpAndSettle();
    controller.debugSetState(state);
    await tester.pumpAndSettle();
  }

  testWidgets('futbol kariyeri ömür özetinde görünür (Paket AY/3)',
      (WidgetTester tester) async {
    // ÖLÇÜLEN HATA: 15 sezon, 300 maçlık bir profesyonel kariyer ömür
    // sonunda hiç yazılmıyordu ve "Meslek: Çalışmadı" deniyordu.
    final GameState state = tamamlanmisHayat().copyWith(
      footballCareer: FootballCareer(
        startedAtAge: 19,
        position: FootballPosition.forvet,
        active: false,
        retiredAtAge: 34,
        lastSeasonAge: 34,
        exitReason: FootballExit.yas,
        careerEarnings: 35000000,
        seasonHistory: <FootballSeason>[
          for (int i = 0; i < 15; i++)
            FootballSeason(
              age: 19 + i,
              appearances: 20,
              goals: 2,
              rating: 60,
              earned: 2000000,
            ),
        ],
      ),
    );
    await pumpApp(tester, state);

    expect(find.text('Futbol'), findsOneWidget);
    expect(find.textContaining('15 sezon'), findsWidgets);
    expect(find.textContaining('300 maç'), findsWidgets);
    // Futbolcuya "Çalışmadı" yazılmaz.
    expect(find.text('Çalışmadı'), findsNothing);
    expect(find.text('Profesyonel futbolcu'), findsOneWidget);
  });

  testWidgets('dövüş kariyeri ömür özetinde görünür (Paket AY/5)',
      (WidgetTester tester) async {
    // AY/3'te futbol satırını eklediğimde tutarsızlık doğdu:
    // futbolcunun kariyeri ömür sonunda yazılıyor, kemer kazanmış
    // dövüşçünün yazılmıyordu.
    final GameState state = tamamlanmisHayat().copyWith(
      combatCareers: <CombatCareer>[
        const CombatCareer(
          artId: 'boks',
          startedCompetitiveAtAge: 18,
          proWins: 24,
          proLosses: 6,
          championships: 2,
          tier: 3,
          retiredAtAge: 34,
          retirementReason: RetirementReason.yas,
        ),
      ],
    );
    await pumpApp(tester, state);

    expect(find.textContaining('30 maç'), findsWidgets);
    expect(find.textContaining('24 galibiyet'), findsWidgets);
    expect(find.textContaining('2 şampiyonluk'), findsWidgets);
    // Dövüşçüye "Çalışmadı" yazılmaz.
    expect(find.text('Çalışmadı'), findsNothing);
    expect(find.text('Dövüş sporcusu'), findsOneWidget);
  });

  testWidgets('hiç dövüşmemiş lisanslı kayıt özeti şişirmiyor (AY/5)',
      (WidgetTester tester) async {
    final GameState state = tamamlanmisHayat().copyWith(
      combatCareers: <CombatCareer>[
        const CombatCareer(artId: 'boks', startedCompetitiveAtAge: 30),
      ],
    );
    await pumpApp(tester, state);
    expect(find.textContaining('galibiyet'), findsNothing);
    expect(find.text('Çalışmadı'), findsOneWidget);
  });

  testWidgets('futbol oynamamış hayatta futbol satırı yok (Paket AY/3)',
      (WidgetTester tester) async {
    await pumpApp(tester, tamamlanmisHayat());
    expect(find.text('Futbol'), findsNothing);
  });

  testWidgets('ölümden sonra hayat özeti gösterilir',
      (WidgetTester tester) async {
    final GameState state = tamamlanmisHayat();
    await pumpApp(tester, state);

    expect(find.text('Bir ömür tamamlandı'), findsOneWidget);
    expect(find.byKey(const Key('life_summary_card')), findsOneWidget);
    expect(find.textContaining('81'), findsWidgets);
    expect(find.textContaining('yaşlılığa bağlı nedenler'), findsOneWidget);
    expect(find.text(state.player.fullName), findsWidgets);
    expect(find.text('Ailesi'), findsOneWidget);

    // Yaş Al ve ana menüler kapanır.
    expect(find.byKey(const Key('age_up_button')), findsNothing);
    expect(find.byKey(const Key('tab_varliklar')), findsNothing);
  });

  testWidgets('ölümden sonra yaş ilerlemez', (WidgetTester tester) async {
    await pumpApp(tester, tamamlanmisHayat());
    // Lise alanı seçilmeden yaş atlanmaz (D-094).
    resolveEducationChoices(controller);
    controller.ageUp();
    await tester.pumpAndSettle();
    expect(controller.state!.player.age, 81);
    expect(find.text('Bir ömür tamamlandı'), findsOneWidget);
  });

  testWidgets('yeni hayat ancak onayla başlar', (WidgetTester tester) async {
    await pumpApp(tester, tamamlanmisHayat());

    await tester.tap(find.byKey(const Key('life_summary_new_life')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Devam edilsin mi?'), findsOneWidget);

    // Vazgeçilince hayat özeti durur, kayıt silinmez.
    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();
    expect(find.text('Bir ömür tamamlandı'), findsOneWidget);
    expect(controller.state, isNotNull);
    expect(controller.state!.deceased, isTrue);

    // Onaylanınca yeni hayat ekranına dönülür.
    await tester.tap(find.byKey(const Key('life_summary_new_life')));
    await tester.pumpAndSettle();
    // Başlık ile düğme aynı metni taşıyor; düğmeye basılır.
    await tester.tap(find.widgetWithText(FilledButton, 'Yeni hayat').last);
    await tester.pumpAndSettle();
    expect(find.text('Rastgele bir hayat'), findsOneWidget);
  });
}
