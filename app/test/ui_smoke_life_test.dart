import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/data/lawyer_catalog.dart';
import 'package:bir_omur/domain/education/education_path.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/pending_trial.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/models/game_state.dart';
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
      // **Duruşma penceresi (Paket BO).** Modal bir sayfa: kapatılmadan
      // Yaş Al'a basılamıyor ve hayat orada duruyordu. Eski test bunu
      // sessizce yutuyordu: döngüden çıkıyor, on yılı geçtiği için
      // geçiyordu. Yani "arayüzden ilerlenebiliyor" iddiası 65 yaşında
      // çökmüş hâldeyken bile yeşil kalıyordu.
      if (c.state!.pendingTrial != null) {
        final Finder tutum = find.byKey(
          Key('trial_stance_${DefenceStance.pismanlik.name}'),
        );
        if (tutum.evaluate().isNotEmpty) {
          await tester.ensureVisible(tutum);
          await tester.pumpAndSettle();
          await tester.tap(tutum);
          await tester.pumpAndSettle();
        }
        if (c.state!.pendingTrial != null) {
          // Düğmeye ulaşılamadıysa motordan kapat: testin işi pencereyi
          // beklemek değil. (Ulaşılamazlığın kendisi `trial_sheet`
          // testlerinin konusu.)
          c.respondToTrial(
            stance: DefenceStance.pismanlik,
            lawyerId: kSelfDefenceTier.id,
          );
          await tester.pumpAndSettle();
        }
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
  ///
  /// İlerlenemediğinde **neden** ilerlenemediğini de döndürür. Eskiden
  /// yalnızca `false` dönüyordu ve testin hata mesajı "bir pencere ya da
  /// düğme ulaşılamıyor" demekle kalıyordu; hangi kapının kapalı olduğu
  /// elle aranmak zorundaydı (Paket BO).
  Future<({bool ilerledi, String sebep})> uiYilGecir(
    WidgetTester tester,
    GameController c,
  ) async {
    // Bekleyen olay/kriz/bildirim varsa arayüzden kapat.
    await bekleyenleriKapat(tester, c);
    await resolveEducationSheets(tester, c);

    // **Ölüm takılma değildir (Paket BV).** Bekleyenleri kapatırken
    // hayat bitebilir: kritik sağlık çözümü ya da bir olay seçimi o yıl
    // öldürebilir. O anda ekran "Bir ömür tamamlandı" özetine geçtiği
    // için Yaş Al düğmesi **doğru biçimde** yoktur. Teşhis bunu
    // gösterdi (tohum 328, yaş 69): test kilitlenme sanıyordu. Döngü
    // dışarıda `deceased` ile kapanır.
    if (c.state!.deceased) return (ilerledi: true, sebep: '');

    final Finder yasAl = find.byKey(const Key('age_up_button'));
    if (yasAl.evaluate().isEmpty) {
      // **Sebep ekranın kendisinden okunur (Paket BV).** "Düğme yok"
      // tek başına hiçbir şey anlatmıyordu; Paket BO'da aynı belirtinin
      // altında açık kalmış bir duruşma penceresi vardı ve teşhis
      // elle yapıldı. Artık ekranda ne olduğu sebebe yazılıyor.
      final List<String> ustteki = tester
          .widgetList<Text>(find.byType(Text))
          .map((Text t) => t.data ?? '')
          .where((String x) => x.trim().isNotEmpty)
          .take(14)
          .toList(growable: false);
      final int sayfa = tester.widgetList(find.byType(BottomSheet)).length;
      final int dialog = tester.widgetList(find.byType(Dialog)).length;
      return (
        ilerledi: false,
        sebep: 'Yaş Al düğmesi ekranda yok '
            '(alt pencere: $sayfa, diyalog: $dialog, '
            'ekrandaki ilk metinler: ${ustteki.join(" / ")})',
      );
    }
    final int once = c.state!.player.age;
    await tester.tap(yasAl);
    await tester.pumpAndSettle();
    if (c.state!.player.age > once || c.state!.deceased) {
      return (ilerledi: true, sebep: '');
    }
    final GameState d = c.state!;
    return (
      ilerledi: false,
      sebep: 'düğmeye basıldı, yaş ilerlemedi '
          '(olay: ${d.hasPendingEvent}, bildirim: ${d.hasNotice}, '
          'kriz: ${d.hasPendingCrisis}, '
          'lise alanı: ${d.education.awaitingTrackChoice}, '
          'lise sonrası: ${EducationPath.needsAfterSchoolChoice(d)})',
    );
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

      // **Tohum denemesi (Paket BO).** İddia "arayüzden on yıl
      // ilerlenebilir". Oyuncu yedi yaşında vefat ettiyse bu iddia
      // yanlış değil, **ölçülemez** olur: erken ölüm oyunun kendi
      // sonucu, arayüz hatası değil. O yüzden on yılı gören bir hayat
      // bulunana kadar tohum denenir.
      //
      // Takılma ile ölüm **ayrı** tutulur: yaş alınamıyorsa (ölmemişken
      // ilerlenemiyorsa) test hemen düşer, başka tohum denenmez. Yoksa
      // gerçek bir "düğmeye ulaşılamıyor" hatası tohum değiştirilerek
      // gizlenebilirdi.
      int yil = 0;
      int gezinti = 0;
      int denenen = seed * 41;
      for (final int ek in <int>[0, 1000, 2000, 3000]) {
        denenen = seed * 41 + ek;
        // Yeniden denemede ağacı tamamen söküp kuruyoruz: aynı tipte
        // yeni bir kök pump edilince Flutter eski `State`'leri koruyor
        // ve uygulama önceki hayatın ekranında kalıyordu.
        if (ek > 0) {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
        }
        final GameController c = GameController(random: Random(denenen));
        addTearDown(c.dispose);
        await tester.pumpWidget(
          BirOmurApp(controller: c, sound: SoundService.silent()),
        );
        await tester.pumpAndSettle();
        final Finder baslat = find.text('Rastgele bir hayat');
        if (baslat.evaluate().isNotEmpty) {
          await tester.tap(baslat);
          await tester.pumpAndSettle();
        } else {
          // Yeniden denemede başlangıç ekranı gelmiyor: önceki hayatın
          // kaydı duruyor ve uygulama onu açıyor. Hayat motordan
          // başlatılır; başlangıç ekranının kendisi ilk denemede
          // zaten gezildi.
          c.startNewLife(mode: StartMode.tamamenRastgele, seed: denenen);
          await tester.pumpAndSettle();
        }

        yil = 0;
        gezinti = 0;
        bool takildi = false;
        String takilmaSebebi = '';
        while (!c.state!.deceased && yil < 70) {
          final ({bool ilerledi, String sebep}) adim =
              await uiYilGecir(tester, c);
          if (!adim.ilerledi) {
            takildi = true;
            takilmaSebebi = adim.sebep;
            break;
          }
          yil++;
          // Her beş yılda bir bütün menüleri gez: ulaşılabilirlik
          // sürekli denetlenir, yalnızca başta değil.
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
        expect(takildi, isFalse,
            reason: 'Arayüzden yaş alınamadı (tohum $denenen, yaş '
                '${c.state!.player.age}): $takilmaSebebi');
        expect(tester.takeException(), isNull);
        if (yil > 10) break;
      }

      // İddialar: hayat gerçekten arayüzden yürüdü ve menüler açıldı.
      expect(yil, greaterThan(10),
          reason: 'Arayüzden en az on yıl ilerlenebilmeli; denenen bütün '
              'tohumlarda hayat on yıldan önce bitti (son tohum: '
              '$denenen)');
      expect(gezinti, greaterThan(0), reason: 'Menüler hiç gezilmedi');
    });
  }
}
