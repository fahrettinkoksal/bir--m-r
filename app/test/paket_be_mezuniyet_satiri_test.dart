// "Mezuniyet sonrası" satırı kapanmayı biliyor.
//
// **Nasıl bulundu.** Bot dökümü (`ekran_dokumu_bot_test.dart`) 35
// yaşında, 13 yıldır CNC operatörü olarak çalışan, "Üretim şefi"
// unvanlı, yıllık 1,17 milyon ₺ kazanan oyuncunun Meslek ekranında şu
// satırı bastı:
//
//     Bu yıl yapabileceklerin
//     Mezuniyet sonrası · Üniversiteye başvur veya iş hayatına gir
//
// Aynı satır 55 ve 70 yaşta da duruyordu.
//
// **Kök neden.** Arayüz `EducationState.awaitingAfterSchoolChoice`
// bayrağını okuyordu. O bayrak "lise bitti, üniversite kaydı yok"
// demekten ibarettir ve **hiç kapanmaz**: ne oyuncu üniversiteye
// gitmemeye karar verince, ne de yaş ilerleyince. Motor aynı durumu
// doğru biliyor — `EducationPath.needsAfterSchoolChoice` üç koşula
// bakıyor (bayrak + yaş ≤ 30 + "üniversiteye gitmedim" izi yok) ve yıl
// kilidini ona göre açıyor. Yani iki yerde iki ayrı doğru vardı ve
// ekranda yanlış olan görünüyordu. Üstelik `skipUniversity`'nin kendi
// açıklaması "mezuniyet sonrası ekranı kapanır" diyor; kapanan yalnızca
// kilitti.
//
// Üç kullanım yeri de artık motorun kapısını okuyor: menü satırı,
// başlığın görünürlüğü ve D-142'nin otomatik sayfa açılışı.
library;

import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/domain/education/education_path.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/career.dart';
import 'package:bir_omur/domain/models/education.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late GameController controller;
  setUp(() => controller = GameController(random: Random(13)));
  tearDown(() => controller.dispose());

  /// Liseyi bitirmiş, üniversiteye kaydı olmayan bir hayat.
  GameState liseMezunu({
    required int age,
    bool calisiyor = false,
    Set<String> storyFlags = const <String>{},
  }) {
    final GameState temel =
        LifeGenerator.seeded(77).generate(mode: StartMode.tamamenRastgele);
    return temel.copyWith(
      pendingEvent: null,
      player: temel.player.copyWith(age: age, wallet: 500000),
      education: const EducationState(finished: true, startedAtAge: 6),
      career: calisiyor
          ? CareerState(
              jobId: 'magaza_calisani',
              startedAtAge: 22,
              lastPaidAge: age,
              salary: 400000,
              jobCity: temel.player.currentCity,
            )
          : const CareerState.none(),
      storyFlags: storyFlags,
    );
  }

  Future<void> meslegiAc(WidgetTester tester, GameState durum) async {
    tester.view.physicalSize = const Size(1200, 8000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(BirOmurApp(controller: controller));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rastgele bir hayat'));
    await tester.pumpAndSettle();
    controller.debugSetState(durum);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tab_okul_meslek')));
    await tester.pumpAndSettle();
  }

  testWidgets('19 yaşında karar bekleyen oyuncuda satır görünür',
      (WidgetTester tester) async {
    final GameState durum = liseMezunu(age: 19);
    expect(EducationPath.needsAfterSchoolChoice(durum), isTrue,
        reason: 'Testin kurulumu geçersiz: motor karar beklemiyor.');
    await meslegiAc(tester, durum);
    expect(find.text('Mezuniyet sonrası'), findsOneWidget,
        reason: 'Karar gerçekten bekliyorken satır gizlenmemeli.');
  });

  testWidgets('üniversiteye gitmemeye karar verince satır kapanır',
      (WidgetTester tester) async {
    final GameState durum = liseMezunu(
      age: 19,
      storyFlags: <String>{EducationPath.universiteyeGitmediFlag},
    );
    await meslegiAc(tester, durum);
    expect(find.text('Mezuniyet sonrası'), findsNothing,
        reason: 'Oyuncu kararını verdi; satır kapanmalı. '
            '`skipUniversity`in kendi açıklaması da bunu söylüyor.');
  });

  testWidgets('35 yaşında 13 yıldır çalışan oyuncuda satır yok',
      (WidgetTester tester) async {
    // Dökümdeki durumun birebir karşılığı.
    final GameState durum = liseMezunu(age: 35, calisiyor: true);
    expect(EducationPath.needsAfterSchoolChoice(durum), isFalse,
        reason: 'Motor bu yaşta karar beklemiyor (yaş > 30).');
    await meslegiAc(tester, durum);
    expect(find.text('Mezuniyet sonrası'), findsNothing,
        reason: 'Kıdemli bir çalışana "mezuniyet sonrası" sorulmaz.');
  });

  testWidgets('70 yaşında satır yok', (WidgetTester tester) async {
    await meslegiAc(tester, liseMezunu(age: 70));
    expect(find.text('Mezuniyet sonrası'), findsNothing);
  });

  test('arayüz ile motor aynı kapıyı okuyor', () {
    // Kapının kendisi: üç koşulun her biri satırı kapatabilmeli.
    expect(
      EducationPath.needsAfterSchoolChoice(liseMezunu(age: 19)),
      isTrue,
    );
    expect(
      EducationPath.needsAfterSchoolChoice(
        liseMezunu(
          age: 19,
          storyFlags: <String>{EducationPath.universiteyeGitmediFlag},
        ),
      ),
      isFalse,
      reason: 'Karar izi kapıyı kapatmalı.',
    );
    expect(
      EducationPath.needsAfterSchoolChoice(
        liseMezunu(
          age: EducationPath.prototypeOnlyAfterSchoolMaxAge + 1,
        ),
      ),
      isFalse,
      reason: 'Yaş sınırı kapıyı kapatmalı (D-111).',
    );
    expect(
      EducationPath.needsAfterSchoolChoice(
        liseMezunu(age: EducationPath.prototypeOnlyAfterSchoolMaxAge),
      ),
      isTrue,
      reason: 'Sınır yaşın kendisi hâlâ açık olmalı; yoksa sınır bir yaş '
          'erken işliyor demektir.',
    );
  });
}
