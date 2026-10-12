/// Lise sonrası üniversite başvurusu (D-111, D-142) testleri.
///
/// Faho ekran görüntüsüyle bildirdi: "lise bittikten sonra direkt yaş aldım
/// ve hiç bir üniversiteye başvuramıyorum". Açılan pencerede "Taban puan 72 ·
/// senin puanın 99" yazıyordu ama düğme kapalıydı ve gerekçe satırı boştu.
///
/// **Gerçek sebep:** pencerenin kart bileşeni engeli `String?` tutuyor ve
/// açıklığı `blockReason == null` ile ölçüyordu; motor ise engel yokken
/// **boş dize** döndürüyor. Yani hiçbir bölüm hiçbir zaman açılmıyordu.
/// Okul ekranındaki aynı kart baştan beri `isEmpty` kullandığı için oradan
/// başvurulabiliyordu — Faho'nun "okul içerisine girip başvurabildim"
/// gözlemi tam olarak bu.
///
/// D-142 ile pencere kaldırıldı: karar artık Okul/Meslek ekranının
/// "Mezuniyet sonrası" sayfasında veriliyor. Bu dosya o yolu sınar.
library;

import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/data/education_tracks.dart';
import 'package:bir_omur/data/university_catalog.dart';
import 'package:bir_omur/domain/education/education_path.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/education.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late GameController controller;

  setUp(() => controller = GameController(random: Random(7)));
  tearDown(() => controller.dispose());

  /// Liseyi bitirmiş, sınav puanı verilen oyuncu.
  GameState mezun({
    int puan = 99,
    EducationTrack? alan = EducationTrack.fenBilim,
  }) {
    final GameState base =
        LifeGenerator.seeded(31).generate(mode: StartMode.tamamenRastgele);
    return base.copyWith(
      pendingEvent: null,
      player: base.player.copyWith(age: 18, wallet: 10000),
      education: EducationState(
        finished: true,
        startedAtAge: 6,
        track: alan,
        universityExamScore: puan,
      ),
    );
  }

  Future<void> pumpApp(WidgetTester tester, GameState state) async {
    tester.view.physicalSize = const Size(1200, 5200);
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

  test('puanı yeten bölümde engel metni BOŞ DİZEDİR, null değil', () {
    // Motorun sözleşmesi. Arayüz bunu `isEmpty` ile okumak zorunda;
    // `== null` ile okuyan her kart bütün bölümleri kapalı gösterir.
    const EducationPath yol = EducationPath();
    final GameState s = mezun();
    final UniversityProgram kolay = kUniversityPrograms.reduce(
      (UniversityProgram a, UniversityProgram b) =>
          a.minScore <= b.minScore ? a : b,
    );
    final String engel = yol.eligibilityReason(s, kolay);
    expect(engel, isEmpty);
    expect(engel, isNotNull);
    expect(yol.effectiveScore(s, kolay), greaterThanOrEqualTo(kolay.minScore));
  });

  testWidgets('yaş almaya çalışınca başvuru sayfasına düşülür (D-142)',
      (WidgetTester tester) async {
    await pumpApp(tester, mezun());

    await tester.tap(find.text('Yaş Al'));
    await tester.pumpAndSettle();

    // Pencere değil, sayfa: başlık ve puan kartı görünür.
    expect(find.text('Mezuniyet sonrası'), findsWidgets);
    expect(find.textContaining('Senin puanın'), findsWidgets);
    // Karar verilmeden yaş geçmedi.
    expect(controller.state!.player.age, 18);
  });

  testWidgets('puanı yeten bölüme başvuru düğmesi AÇIK olur',
      (WidgetTester tester) async {
    await pumpApp(tester, mezun());
    await tester.tap(find.text('Yaş Al'));
    await tester.pumpAndSettle();

    const EducationPath yol = EducationPath();
    final GameState s = controller.state!;
    final List<UniversityProgram> uygun = kUniversityPrograms
        .where((UniversityProgram p) => yol.eligibilityReason(s, p).isEmpty)
        .toList(growable: false);
    expect(
      uygun,
      isNotEmpty,
      reason: '99 puanla hiçbir bölüm açılmıyorsa kurulum yanlış',
    );

    for (final UniversityProgram p in uygun) {
      final Finder dugme = find.byKey(Key('after_school_apply_${p.id}'));
      await tester.scrollUntilVisible(
        dugme,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      final FilledButton w = tester.widget<FilledButton>(dugme);
      expect(
        w.onPressed,
        isNotNull,
        reason: '${p.name}: taban ${p.minScore}, puan '
            '${yol.effectiveScore(s, p)} — düğme açık olmalı',
      );
    }
  });

  testWidgets('puanı yetmeyen bölümde gerekçe yazılır, düğme kapalı kalır',
      (WidgetTester tester) async {
    // 10 puanla hiçbir bölüm açılmaz; gerekçe görünür olmalı (D-063).
    await pumpApp(tester, mezun(puan: 10, alan: null));
    await tester.tap(find.text('Yaş Al'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Puanın yetmiyor'), findsWidgets);
    expect(find.text('Uygun değil'), findsWidgets);
    // Kilitlenme yok: üniversiteye gitmeme kapısı hep açık.
    final Finder cikis = find.byKey(const Key('after_school_skip'));
    await tester.scrollUntilVisible(
      cikis,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.widget<OutlinedButton>(cikis).onPressed, isNotNull);
  });

  testWidgets('başvuru gerçekten kayda geçer ve karar kapanır',
      (WidgetTester tester) async {
    await pumpApp(tester, mezun());
    await tester.tap(find.text('Yaş Al'));
    await tester.pumpAndSettle();

    const EducationPath yol = EducationPath();
    final UniversityProgram hedef = kUniversityPrograms.firstWhere(
      (UniversityProgram p) =>
          yol.eligibilityReason(controller.state!, p).isEmpty,
    );
    final Finder dugme = find.byKey(Key('after_school_apply_${hedef.id}'));
    await tester.scrollUntilVisible(
      dugme,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(dugme);
    await tester.pumpAndSettle();

    expect(controller.state!.education.universityProgramId, hedef.id);
    expect(controller.needsAfterSchoolChoice, isFalse);
  });
}
