// Duruşma penceresi: kendi rotası kapandıktan sonra kapanmaya çalışmaz.
//
// **Nasıl bulundu.** Ekran dökümü testi (`ekran_dokumu_test.dart`) 30 ve
// 70 yaş evrelerinde Flutter çerçevesinin iddiasıyla düştü:
//
//     'package:flutter/src/widgets/routes.dart': Failed assertion:
//     line 1984 pos 12: 'scope != null': is not true.
//     #4 _TrialSheetState.build.<anonymous closure>
//        (package:bir_omur/ui/widgets/trial_sheet.dart:48:44)
//
// **Kök neden.** `TrialSheet.build`, duruşma kapandığında (`pendingTrial
// == null`) kareden sonra çalışan bir geri çağrıyla kendini kapatıyordu
// ve yalnızca `mounted` kontrolü yapıyordu. `home_shell` ise bekleyen
// olay, bildirim ve kriz pencerelerini açarken **önce bütün rotaları
// kapatıyor** (`navigator.popUntil(route.isFirst)`, `home_shell.dart`
// içinde dört yerde). Duruşmanın sonucu bir bildirim ya da olay
// ürettiğinde iki geri çağrı aynı karede sıraya giriyor: kabuk sayfayı
// kapatıyor, ardından sayfanın kendi geri çağrısı **kapanmış rota**
// üzerinde `maybePop()` çağırıyor. `ModalRoute.willPop` rotanın kapsamı
// yok diye iddiada düşüyor — oyuncunun ekranında kırmızı hata.
//
// Oyuncuya bakan yolu: duruşmada bir tutum seçtikten sonra kararın
// bildirimi geldiği an. TrialSheet'in **hiç** arayüz testi yoktu; bu
// yüzden 3.360 testin hiçbiri bunu görmedi.
//
// Bu dosya iki şeyi sınar: (1) rota önceden kapanmışsa pencere sessizce
// vazgeçer, (2) normal yolda pencere yine kendini kapatır.
library;

import 'dart:math';

import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/criminal_record.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/pending_trial.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:bir_omur/state/game_scope.dart';
import 'package:bir_omur/ui/widgets/trial_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Dosyayı duruşmaya oturmuş bir hayat kurar.
GameState durusmadaHayat(GameController controller) {
  final GameState temel =
      LifeGenerator.seeded(11).generate(mode: StartMode.tamamenRastgele);
  const String dosyaId = 'dosya-bd';
  return temel.copyWith(
    pendingEvent: null,
    player: temel.player.copyWith(age: 30, wallet: 500000),
    legal: temel.legal.copyWith(
      cases: <CriminalCase>[
        CriminalCase(
          id: dosyaId,
          crimeId: 'hirsizlik',
          ageAtIncident: 30,
          stage: CaseStage.dava,
        ),
      ],
      caseCounter: 1,
    ),
    pendingTrial: const PendingTrial(
      caseId: dosyaId,
      age: 30,
      text: 'Dosyan mahkemeye çıktı.',
    ),
  );
}

void main() {
  late GameController controller;
  setUp(() => controller = GameController(random: Random(5)));
  tearDown(() => controller.dispose());

  /// Duruşma penceresini açar ve kök bağlamı döner.
  Future<BuildContext> pencereyiAc(WidgetTester tester) async {
    controller.debugSetState(durusmadaHayat(controller));
    late BuildContext kok;
    await tester.pumpWidget(
      GameScope(
        controller: controller,
        child: MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              kok = context;
              return const Scaffold(body: Text('ana ekran'));
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    TrialSheet.show(kok);
    await tester.pumpAndSettle();
    expect(find.text('Duruşma'), findsOneWidget,
        reason: 'Duruşma penceresi açılmadı; testin kurulumu geçersiz.');
    return kok;
  }

  testWidgets('rota kabuk tarafından önceden kapatılmışsa çökmez',
      (WidgetTester tester) async {
    final BuildContext kok = await pencereyiAc(tester);

    // `home_shell`in yaptığının aynısı: bekleyen pencere açılmadan önce
    // bütün rotalar kapatılır, sonra yeni pencere açılır (dört açıcının
    // hepsi böyle). Geri çağrı pencerenin kendi geri çağrısından **önce**
    // sıraya giriyor; gerçek sıra bu.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(kok, rootNavigator: true)
          .popUntil((Route<dynamic> route) => route.isFirst);
      showDialog<void>(
        context: kok,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (BuildContext _) =>
            const Dialog(child: Text('bekleyen pencere')),
      );
    });

    // Duruşma kapanıyor: pencere yeniden kurulurken kendini kapatmak
    // isteyecek, ama rotası o an çoktan kapanmış olacak.
    controller.debugSetState(
      controller.state!.copyWith(pendingTrial: null),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull,
        reason: 'Kapanmış rota üzerinde maybePop() çağrılıyor; oyuncu '
            'duruşmadan sonra kırmızı hata ekranı görüyor.');
    expect(find.text('Duruşma'), findsNothing);
    expect(find.text('bekleyen pencere'), findsOneWidget,
        reason: 'Kabuğun açtığı pencere ayakta kalmalı: duruşma sayfası '
            'onu kapatmamalı.');
  });

  testWidgets('normal yolda pencere kendini kapatır',
      (WidgetTester tester) async {
    await pencereyiAc(tester);

    controller.debugSetState(
      controller.state!.copyWith(pendingTrial: null),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Duruşma'), findsNothing,
        reason: 'Duruşma bitince pencere kendi kendine kapanmalı.');
    expect(find.text('ana ekran'), findsOneWidget);
  });
}
