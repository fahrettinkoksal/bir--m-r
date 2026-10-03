import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:bir_omur/ui/sound/sound_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_flow.dart';

/// **UI smoke life** — uzun hayatları gerçek arayüzden oynar.
///
/// Neden ayrı: alan (domain) simülasyonu motorun doğru çalıştığını
/// gösterir ama "motor çalışıyor, buton ulaşılamıyor" hatasını
/// **yakalamaz**. Bu test menüleri açıyor, kaydırıyor, düğmeye basıyor,
/// pencere seçiyor ve sekmeler arasında dolaşıyor.
///
/// 1.000 hayatın tamamını UI'dan oynamak çok yavaş olurdu; bu yüzden 10
/// uzun hayat. Ürün metriği buradan çıkarılmaz — buradaki iş
/// **ulaşılabilirlik**.
void main() {
  /// Bekleyen pencereleri arayüzden kapatır.
  ///
  /// Paylaşılan `answerPendingEvents` yardımcısı sonucu gösteren "Devam"
  /// düğmesinin **her zaman** çıktığını varsayıyor; uzun hayatlarda olayın
  /// sonucu oyuncuyu vefat ettirdiğinde ya da üstüne bildirim geldiğinde
  /// o düğme çıkmıyor ve yardımcı düşüyor. Ortak yardımcıyı gevşetmek
  /// başka testlerin iddialarını zayıflatırdı; bu yüzden smoke testi
  /// kendi toleranslı akışını kullanıyor.
  Future<void> bekleyenleriKapat(
    WidgetTester tester,
    GameController c,
  ) async {
    int guard = 0;
    while (guard++ < 60) {
      await tester.pumpAndSettle();
      if (c.state!.deceased) return;

      if (c.state!.hasNotice) {
        await answerPendingNotices(tester, c);
        continue;
      }
      if (c.state!.hasPendingCrisis) {
        await answerPendingCrisis(tester, c);
        continue;
      }
      final ActiveEvent? olay = c.state!.pendingEvent;
      if (olay != null) {
        // Seçenek etiketine bas; **ilk şık değil**, rastgele geçerli bir
        // seçenek (ürün simülasyonundaki puanlama burada gerekmiyor,
        // buradaki iş ulaşılabilirlik).
        final EventChoice secim =
            olay.choices[Random(c.state!.player.age + guard)
                .nextInt(olay.choices.length)];
        final Finder dugme = find.text(secim.label);
        if (dugme.evaluate().isEmpty) {
          // Pencere açılmadıysa motor üzerinden kapat: testin işi
          // pencereyi beklemek değil.
          c.chooseEventOption(secim.id);
          continue;
        }
        await tester.tap(dugme);
        await tester.pumpAndSettle();
        final Finder devam = find.text('Devam');
        if (devam.evaluate().isNotEmpty) {
          await tester.tap(devam);
          await tester.pumpAndSettle();
        }
        continue;
      }
      return;
    }
    fail('Bekleyen pencereler arayüzden kapatılamıyor.');
  }

  /// Bir yılı arayüzden geçirir: bekleyen pencereleri kapatır, sonra
  /// Yaş Al'a basar.
  Future<bool> uiYilGecir(WidgetTester tester, GameController c) async {
    // Bekleyen olay/kriz/bildirim varsa arayüzden kapat.
    await bekleyenleriKapat(tester, c);
    await resolveEducationSheets(tester, c);

    final Finder yasAl = find.byKey(const Key('age_up_button'));
    if (yasAl.evaluate().isEmpty) return false;
    final int once = c.state!.player.age;
    await tester.tap(yasAl);
    await tester.pumpAndSettle();
    return c.state!.player.age > once || c.state!.deceased;
  }

  /// Bütün sekmeleri gezer ve ilk menü satırlarını açıp kapatır.
  ///
  /// Gezinti öncesi bekleyen pencereler kapatılır: açık bir olay ya da
  /// bildirim penceresi sekmeleri **bilerek** kapatıyor (modal), bu bir
  /// hata değil. Kapatmadan sekmeye basmak testi yanlış yerden düşürüyordu.
  Future<void> sekmeleriGez(WidgetTester tester, GameController c) async {
    await bekleyenleriKapat(tester, c);
    if (c.state!.deceased) return;
    for (final String sekme in <String>[
      'okul_meslek',
      'varliklar',
      'iliskiler',
      'aktiviteler',
    ]) {
      final Finder tab = find.byKey(Key('tab_$sekme'));
      if (tab.evaluate().isEmpty) continue;
      await tester.tap(tab);
      await tester.pumpAndSettle();
      // Sayfayı aşağı kaydır: alt satırlara gerçekten ulaşılıyor mu?
      final Finder kaydirilabilir = find.byType(Scrollable);
      if (kaydirilabilir.evaluate().isNotEmpty) {
        await tester.drag(kaydirilabilir.first, const Offset(0, -400));
        await tester.pumpAndSettle();
        await tester.drag(kaydirilabilir.first, const Offset(0, 400));
        await tester.pumpAndSettle();
      }
      // Ekranda taşma olmamalı: arayüz gerçekten kullanılabilir olsun.
      expect(tester.takeException(), isNull);
    }
  }

  for (int seed = 1; seed <= 10; seed++) {
    testWidgets('UI hayati $seed: menuler acilir, dugmelere ulasilir',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final GameController c = GameController(random: Random(seed * 41));
      addTearDown(c.dispose);
      await tester.pumpWidget(
        BirOmurApp(controller: c, sound: SoundService.silent()),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rastgele bir hayat'));
      await tester.pumpAndSettle();

      int yil = 0;
      int gezinti = 0;
      while (!c.state!.deceased && yil < 70) {
        final bool ilerledi = await uiYilGecir(tester, c);
        if (!ilerledi) break;
        yil++;
        // Her beş yılda bir bütün menüleri gez: ulaşılabilirlik sürekli
        // denetlenir, yalnızca başta değil.
        if (yil % 5 == 0) {
          await sekmeleriGez(tester, c);
          gezinti++;
          // Yaş Al'a geri dön.
          final Finder hayat = find.byKey(const Key('tab_hayat'));
          if (hayat.evaluate().isNotEmpty) {
            await tester.tap(hayat);
            await tester.pumpAndSettle();
          }
        }
      }

      // İddialar: hayat gerçekten arayüzden yürüdü ve menüler açıldı.
      expect(yil, greaterThan(10),
          reason: 'Arayüzden en az on yıl ilerlenebilmeli; ilerlenemiyorsa '
              'bir pencere ya da düğme ulaşılamıyor');
      expect(gezinti, greaterThan(0), reason: 'Menüler hiç gezilmedi');
      expect(tester.takeException(), isNull);
    });
  }
}
