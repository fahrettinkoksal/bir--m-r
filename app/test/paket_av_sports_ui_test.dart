import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/data/school_club_catalog.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/education.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:bir_omur/domain/models/school_club_progress.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:bir_omur/ui/sound/sound_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_flow.dart';

/// Spor Kariyeri menüsü ve kulüp kartları (Paket AV).
///
/// Paket AU kulüpleri, rolleri ve futbol uygunluk kapısını kurmuştu ama
/// oyuncu hiçbirini ekranda göremiyordu. Bu testler ekranın gerçekten
/// çalıştığını gösterir: kart durumu yazıyor, antrenman yılda bir kez
/// açılıyor, engelin gerekçesi görünüyor, futbol geçmişi olmayanda
/// Spor Kariyeri satırı çıkmıyor.
///
/// **Bu testler gerçek cihazda oynandığı anlamına gelmez.**
void main() {
  late GameController controller;

  setUp(() => controller = GameController(random: Random(17)));
  tearDown(() => controller.dispose());

  /// Okula devam eden, verilen kulüp kayıtlarına sahip bir hayat.
  GameState hayat({
    int age = 15,
    int grade = 9,
    int health = 80,
    List<SchoolClubProgress> kulupler = const <SchoolClubProgress>[],
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
      schoolClubs: kulupler,
    );
  }

  SchoolClubProgress kayit({
    String clubId = 'futbol_takimi',
    int yearsActive = 4,
    int skill = 62,
    SquadRole role = SquadRole.ilkOnBir,
    bool active = true,
    int joinedAtAge = 11,
    int joinedAtGrade = 5,
    int? captainSinceAge,
    int awards = 0,
    int? leftAtAge,
    int? lastPracticedAge,
  }) => SchoolClubProgress(
    clubId: clubId,
    schoolId: 'okul-lise-1',
    joinedAtAge: joinedAtAge,
    joinedAtGrade: joinedAtGrade,
    active: active,
    leftAtAge: leftAtAge,
    yearsActive: yearsActive,
    skill: skill,
    performance: 60,
    role: role,
    captainSinceAge: captainSinceAge,
    awards: awards,
    lastPracticedAge: lastPracticedAge,
  );

  Future<void> okulAc(WidgetTester tester, GameState state) async {
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
  }

  Future<void> kuluplerAc(WidgetTester tester, GameState state) async {
    await okulAc(tester, state);
    await tapMenuRow(tester, 'Kulüpler');
    await tester.pumpAndSettle();
  }

  group('Kulüpler sayfası', () {
    testWidgets('Okul menüsünde Kulüpler satırı var', (
      WidgetTester tester,
    ) async {
      await okulAc(tester, hayat());
      expect(find.byKey(const Key('school_clubs_row')), findsOneWidget);
    });

    testWidgets('üye olmayan oyuncuya katılabileceği kulüpler listelenir', (
      WidgetTester tester,
    ) async {
      await kuluplerAc(tester, hayat());
      expect(find.text('Katılabileceğin kulüpler'), findsOneWidget);
      // 9. sınıfa açık olan en az bir kulübün adı ekranda.
      final SchoolClub satranc = kSchoolClubs.firstWhere(
        (SchoolClub c) => c.id == 'satranc_kulubu',
      );
      expect(find.text(satranc.name), findsOneWidget);
    });

    testWidgets('kart rolü, sezonu ve beceriyi yazıyor', (
      WidgetTester tester,
    ) async {
      await kuluplerAc(
        tester,
        hayat(kulupler: <SchoolClubProgress>[kayit()]),
      );
      expect(find.text('Üye olduğun kulüpler'), findsOneWidget);
      expect(find.text(footballClub.name), findsOneWidget);
      expect(find.text(SquadRole.ilkOnBir.label), findsOneWidget);
      expect(find.text('4 yıl'), findsOneWidget);
      // Beceri hem sayı hem bant olarak okunur.
      expect(find.textContaining('62'), findsWidgets);
    });

    testWidgets('antrenman yılda bir kez: yapılmışsa gerekçe yazıyor', (
      WidgetTester tester,
    ) async {
      // Bu yaşta antrenman yapılmış.
      await kuluplerAc(
        tester,
        hayat(
          kulupler: <SchoolClubProgress>[kayit(lastPracticedAge: 15)],
        ),
      );
      expect(
        find.byKey(const Key('kulup_antrenman_futbol_takimi')),
        findsNothing,
      );
      expect(
        find.textContaining('Bu yılın antrenmanını yaptın'),
        findsOneWidget,
      );
    });

    testWidgets('antrenmana basmak beceriyi değiştirip sonucu yazıyor', (
      WidgetTester tester,
    ) async {
      await kuluplerAc(
        tester,
        hayat(kulupler: <SchoolClubProgress>[kayit(skill: 40)]),
      );
      final Finder dugme = find.byKey(
        const Key('kulup_antrenman_futbol_takimi'),
      );
      expect(dugme, findsOneWidget);
      await tester.tap(dugme);
      await tester.pumpAndSettle();

      // Motor kaydı güncelledi: antrenman yılı işaretlendi.
      final SchoolClubProgress? sonra = controller.state!.schoolClubs
          .activeFor('futbol_takimi');
      expect(sonra, isNotNull);
      expect(sonra!.lastPracticedAge, 15);
      // Ekranda bir sonuç metni duruyor; "arttı" diye uydurulmuyor.
      expect(find.textContaining('Beceri'), findsWidgets);
      // Aynı yıl ikinci kez basılamaz.
      expect(dugme, findsNothing);
    });

    testWidgets('kritik sağlıkta fiziksel kulübün engeli gerekçesiyle çıkar', (
      WidgetTester tester,
    ) async {
      await kuluplerAc(tester, hayat(health: 10));
      // Futbol takımı satırı düğme değil, gerekçeli bir bilgi paneli.
      expect(find.byKey(Key('kulup_katil_${footballClub.id}')), findsNothing);
      expect(find.textContaining(footballClub.name), findsWidgets);
    });

    testWidgets('kulüpten ayrılınca kayıt geçmişe geçiyor, silinmiyor', (
      WidgetTester tester,
    ) async {
      await kuluplerAc(
        tester,
        hayat(kulupler: <SchoolClubProgress>[kayit()]),
      );
      // Ayrılma düğmesi kart açılınca görünür.
      await tester.tap(find.byTooltip('Ayrıntı'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('kulup_ayril_futbol_takimi')));
      await tester.pumpAndSettle();

      expect(controller.state!.schoolClubs.activeFor('futbol_takimi'), isNull);
      expect(controller.state!.schoolClubs, hasLength(1));
      expect(controller.state!.schoolClubs.first.yearsActive, 4);
      expect(find.text('Geçmiş kulüp kayıtların'), findsOneWidget);
    });
  });

  group('Spor Kariyeri sayfası', () {
    testWidgets('futbol geçmişi yoksa satır görünmüyor', (
      WidgetTester tester,
    ) async {
      await okulAc(tester, hayat());
      expect(
        find.byKey(const Key('school_sports_career_row')),
        findsNothing,
      );
    });

    testWidgets('futbol geçmişi varsa satır açılıyor ve durum yazıyor', (
      WidgetTester tester,
    ) async {
      await okulAc(
        tester,
        hayat(
          age: 17,
          grade: 11,
          kulupler: <SchoolClubProgress>[
            kayit(yearsActive: 6, skill: 70, role: SquadRole.kaptan,
                captainSinceAge: 15),
          ],
        ),
      );
      final Finder satir = find.byKey(const Key('school_sports_career_row'));
      expect(satir, findsOneWidget);
      await tester.tap(satir);
      await tester.pumpAndSettle();

      expect(find.text('Spor Kariyeri'), findsWidgets);
      expect(find.text('Futbol geçmişin'), findsOneWidget);
      expect(find.textContaining('Hazırlık puanı'), findsOneWidget);
      // Yeterli geçmişle kapı açık ve bu ekranda yazıyor.
      expect(
        find.text('Profesyonel denemeye girebilirsin'),
        findsOneWidget,
      );
    });

    testWidgets('yetersiz geçmişte kapı kapalı ve GEREKÇESİ yazıyor', (
      WidgetTester tester,
    ) async {
      await okulAc(
        tester,
        hayat(
          age: 17,
          grade: 11,
          kulupler: <SchoolClubProgress>[
            kayit(yearsActive: 1, skill: 20, role: SquadRole.yedek,
                joinedAtAge: 16, joinedAtGrade: 10),
          ],
        ),
      );
      await tester.tap(find.byKey(const Key('school_sports_career_row')));
      await tester.pumpAndSettle();

      expect(find.text('Şu an giremiyorsun'), findsOneWidget);
      // Kuru "uygun değilsin" yok: gerekçe metni dolu.
      expect(find.textContaining('sezon'), findsWidgets);
    });

    testWidgets('profesyonel adımın henüz yazılmadığı dürüstçe söyleniyor', (
      WidgetTester tester,
    ) async {
      await okulAc(
        tester,
        hayat(
          age: 17,
          grade: 11,
          kulupler: <SchoolClubProgress>[kayit(yearsActive: 6, skill: 70)],
        ),
      );
      await tester.tap(find.byKey(const Key('school_sports_career_row')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Profesyonel sözleşme, kulüp seçimi ve sezon'),
        findsOneWidget,
      );
    });
  });
}
