// Paket AY — profesyonel futbol hayatının ekranı.
//
// AV ekranı kurdu ama ekranda yalnızca "kapı açık/kapalı" vardı.
// AY'den sonra oyuncu şunları görmeli: kariyer kartı, sezon listesi,
// denemeye girme sonucu, futbolu bırakma ve bıraktıktan sonra da duran
// kayıt.
//
// **Bu testler gerçek cihazda oynandığı anlamına gelmez.**
library;

import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/education.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:bir_omur/domain/models/school_club_progress.dart';
import 'package:bir_omur/domain/sports/football_career.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:bir_omur/ui/sound/sound_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late GameController controller;

  setUp(() => controller = GameController(random: Random(23)));
  tearDown(() => controller.dispose());

  GameState hayat({
    int age = 17,
    int grade = 11,
    int health = 85,
    int seasons = 6,
    int skill = 72,
    FootballCareer? kariyer,
  }) {
    final GameState base =
        LifeGenerator.seeded(5).generate(mode: StartMode.tamamenRastgele);
    return base.copyWith(
      pendingEvent: null,
      notices: const <PendingNotice>[],
      player: base.player.copyWith(
        age: age,
        stats: base.player.stats.copyWith(health: health),
      ),
      education: EducationState(
        enrolled: true,
        grade: grade,
        startedAtAge: 6,
        schoolId: 'okul-lise-1',
      ),
      schoolClubs: <SchoolClubProgress>[
        SchoolClubProgress(
          clubId: 'futbol_takimi',
          schoolId: 'okul-lise-1',
          joinedAtAge: 11,
          joinedAtGrade: 5,
          active: false,
          leftAtAge: 11 + seasons,
          yearsActive: seasons,
          skill: skill,
          performance: 70,
          role: SquadRole.kaptan,
          captainSinceAge: 15,
        ),
      ],
      footballCareer: kariyer,
    );
  }

  Future<void> sporAc(WidgetTester tester, GameState state) async {
    tester.view.physicalSize = const Size(1080, 7200);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      BirOmurApp(controller: controller, sound: SoundService.silent()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rastgele bir hayat'));
    await tester.pumpAndSettle();
    controller.debugSetState(state);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tab_okul_meslek')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('school_sports_career_row')));
    await tester.pumpAndSettle();
  }

  testWidgets('denemeye girme düğmesi var ve sonucu ekranda yazıyor', (
    WidgetTester tester,
  ) async {
    await sporAc(tester, hayat());
    final Finder deneme = find.byKey(const Key('futbol_deneme'));
    expect(deneme, findsOneWidget);
    await tester.tap(deneme);
    await tester.pumpAndSettle();

    // Kabul ya da ret — ikisi de bir cümleyle yazılır, sessiz kalmaz.
    final bool kabul = controller.state!.footballCareer != null;
    if (kabul) {
      expect(find.text('Profesyonel futbolcu'), findsOneWidget);
      // Kapı kapandı: ikinci kez denemeye girilmiyor.
      expect(find.byKey(const Key('futbol_deneme')), findsNothing);
    } else {
      expect(find.byKey(const Key('futbol_deneme')), findsOneWidget);
    }
    expect(
      find.descendant(
        of: find.byType(Scaffold),
        matching: find.textContaining(RegExp('deneme|kadro|Kabul|kaldın')),
      ),
      findsWidgets,
    );
  });

  testWidgets('aktif kariyerde kart mevkii, sezonu ve maçı yazıyor', (
    WidgetTester tester,
  ) async {
    await sporAc(
      tester,
      hayat(
        age: 24,
        grade: 12,
        kariyer: FootballCareer(
          startedAtAge: 19,
          position: FootballPosition.forvet,
          form: 66,
          reputation: 41,
          careerEarnings: 2400000,
          lastSeasonAge: 23,
          seasonHistory: const <FootballSeason>[
            FootballSeason(
              age: 22,
              appearances: 28,
              goals: 11,
              rating: 64,
              earned: 1200000,
            ),
            FootballSeason(
              age: 23,
              appearances: 14,
              goals: 3,
              rating: 38,
              earned: 1200000,
              injury: 'Diz sakatlığı',
            ),
          ],
        ),
      ),
    );

    expect(find.text('Profesyonel futbolcu'), findsOneWidget);
    expect(find.text(FootballPosition.forvet.label), findsOneWidget);
    expect(find.text('Sezon'), findsOneWidget);
    // Toplamlar kartta: 2 sezon, 42 maç, 14 gol.
    expect(find.text('2'), findsWidgets);
    expect(find.text('42'), findsOneWidget);
    expect(find.text('14'), findsOneWidget);
    // Kazanç gizlenmiyor.
    expect(find.text('Futboldan kazanç'), findsOneWidget);
    // Sezon listesi ve sakatlık satırı okunuyor.
    expect(find.text('Sezonlar'), findsOneWidget);
    expect(find.textContaining('22 yaş — 28 maç, 11 gol'), findsOneWidget);
    expect(find.textContaining('Diz sakatlığı'), findsOneWidget);
    // Aktif kariyerde uygunluk kapısı kartı gösterilmiyor.
    expect(find.text('Profesyonel denemeye girebilirsin'), findsNothing);
    expect(find.byKey(const Key('futbol_deneme')), findsNothing);
  });

  testWidgets('futbolu bırakma kaydı silmiyor, sebebi yazıyor', (
    WidgetTester tester,
  ) async {
    await sporAc(
      tester,
      hayat(
        age: 29,
        kariyer: const FootballCareer(
          startedAtAge: 19,
          position: FootballPosition.ortaSaha,
          careerEarnings: 900000,
          lastSeasonAge: 28,
          seasonHistory: <FootballSeason>[
            FootballSeason(
              age: 28,
              appearances: 30,
              goals: 5,
              rating: 61,
              earned: 900000,
            ),
          ],
        ),
      ),
    );

    final Finder birak = find.byKey(const Key('futbol_birak'));
    expect(birak, findsOneWidget);
    await tester.tap(birak);
    await tester.pumpAndSettle();

    expect(find.text('Futbol kariyeri bitti'), findsOneWidget);
    expect(find.text('Bitiş sebebi'), findsOneWidget);
    expect(find.text(FootballExit.kendiKarari.label), findsOneWidget);
    expect(find.text('Bıraktığın yaş'), findsOneWidget);
    // Kayıt duruyor: sezon listesi silinmedi.
    expect(find.textContaining('28 yaş — 30 maç'), findsOneWidget);
    // Bırakma düğmesi kalkar; yeniden denemeye de girilmez.
    expect(find.byKey(const Key('futbol_birak')), findsNothing);
    expect(find.byKey(const Key('futbol_deneme')), findsNothing);
  });

  testWidgets('ekran artık yazılmamış şeyi doğru söylüyor', (
    WidgetTester tester,
  ) async {
    await sporAc(tester, hayat());
    // Sezon akışı YAZILDI; ekran onu "yok" diye göstermemeli.
    expect(
      find.textContaining('sezon akışı henüz yazılmadı'),
      findsNothing,
    );
    expect(find.textContaining('transfer pazarı'), findsOneWidget);
  });
}
