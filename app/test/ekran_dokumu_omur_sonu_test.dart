// Ömür sonu özeti — hiç okunmamış ekran (Paket DF).
//
// **Neden yazıldı.** Üç ekran dökümünün üçü de ölümde geri dönüyor
// (`if (controller.state!.deceased) return;`) ve `ekran_dokumu_bot_test`
// bunu açıkça yazıyor: "o karede oyun bilerek 'Bir ömür tamamlandı'
// özetini" göstermeye başlıyor. Yani **her oyunun en son gördüğü
// ekran** bugüne kadar hiç basılmadı ve hiç gözle okunmadı. Paket CT ve
// CU'nun dersi: okunmayan ekranda gerçek hata birikir.
//
// Bu dosya özeti **kurmaz**: bot hayatlarını ölüme kadar oynatır, son
// durumu `debugSetState` ile uygulamaya verir ve `deceased` dalında
// çizilen metni basar.
library;

import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/player_bot.dart';

void main() {
  testWidgets('ÖMÜR SONU ÖZETİ — altı arketipin son ekranı',
      (WidgetTester tester) async {
    // Görüş alanı yüksek: özet uzun olabilir (aile listesi, eşyalar,
    // hayattan satırlar). Dökümün sınırı yine çizilmiş metin.
    tester.view.physicalSize = const Size(1200, 14000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const List<PlayerArchetype> arketipler = <PlayerArchetype>[
      PlayerArchetype.career,
      PlayerArchetype.family,
      PlayerArchetype.risky,
      PlayerArchetype.investor,
      PlayerArchetype.casual,
      PlayerArchetype.randomValid,
    ];

    // **Paket DA'nın tuzağı (buraya da düştüm).** `pumpWidget` aynı
    // ağacı koruduğu için uygulamayı ikinci kez açınca "Rastgele bir
    // hayat" düğmesi yok; `ValueKey` her açılışta ağacı tazeler.
    int acilisSayaci = 0;
    int basilan = 0;
    for (final PlayerArchetype a in arketipler) {
      GameState? son;
      for (int i = 0; i < 6 && son == null; i++) {
        final BotLifeResult r = playBotLife(
          archetype: a,
          seed: 111000 + a.index * 613 + i * 29,
          onYear: (GameState s) {
            if (s.deceased) son = s;
          },
        );
        if (son == null && r.endedByDeath) {
          // Ölüm `onYear`'dan sonra yazılmış olabilir; son kareyi
          // yine de arıyoruz.
          continue;
        }
      }
      if (son == null) continue;

      final GameController controller = GameController(random: Random(4));
      acilisSayaci++;
      await tester.pumpWidget(
        BirOmurApp(
          key: ValueKey<int>(acilisSayaci),
          controller: controller,
        ),
      );
      await tester.pumpAndSettle();
      final Finder baslat = find.text('Rastgele bir hayat');
      expect(baslat, findsOneWidget,
          reason: 'Açılış $acilisSayaci: başlangıç ekranı gelmedi.');
      await tester.tap(baslat);
      await tester.pumpAndSettle();
      controller.debugSetState(son!);
      await tester.pumpAndSettle();

      final List<String> metinler = tester
          .widgetList<Text>(find.byType(Text))
          .map((Text t) => t.data ?? '')
          .where((String s) => s.trim().isNotEmpty)
          .toList();

      // ignore: avoid_print
      print('\n${'=' * 68}\nÖMÜR SONU · ${a.name} · '
          'yaş ${son!.deathAge ?? son!.player.age} · '
          'kuşak ${son!.generation} · '
          'cüzdan ${son!.player.wallet} ₺\n${'=' * 68}');
      for (final String m in metinler) {
        // ignore: avoid_print
        print('   $m');
      }
      basilan++;
      controller.dispose();
    }

    expect(basilan, greaterThanOrEqualTo(4),
        reason: 'Ölen hayat bulunamadı; döküm boş kaldı ($basilan kare).');
  }, timeout: const Timeout(Duration(minutes: 12)));
}
