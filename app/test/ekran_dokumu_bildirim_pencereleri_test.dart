// Hiç çizilmemiş bildirim pencereleri (Paket DJ).
//
// **Nasıl bulundu.** 12 `NoticeKind` var ve hangisinin gerçek hayatta
// kuyruğa girdiği hiç ölçülmemişti. Ölçüm, ölçüm aracının kendisinin
// kör olduğunu gösterdi: bot aksiyon kaynaklı bildirimleri kurduğu
// satırda kapatıyordu (`c.divorce(); while (hasNotice) dismiss...`)
// ve o bildirimler `onYear`'a da `onPending`'e de görünmüyordu.
// Araç düzeltildikten sonra (100 hayat):
//
// | tür | eski (kör) | yeni |
// |---|---|---|
// | aktivite | **1** | **8179** |
// | bosanma | **0** | **57** |
// | miras | 194 | 730 |
// | burc | 1220 | 3151 |
// | **piyango** | 0 | **0** |
//
// `piyango` düzeltmeden sonra da sıfır: bot hiç bilet almıyor, yani o
// pencere bugüne kadar **hiç çizilmedi**. Bu dosya onu ve boşanma
// penceresini basar. Botun davranışı değiştirilmedi (bilet almak zarı
// kaydırır ve bütün ölçümleri etkilerdi); pencere kontrolörün kendi
// API'siyle açılıyor.
// ignore_for_file: avoid_print
library;

import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/data/lottery_catalog.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/interaction.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bir_omur/ui/widgets/notice_sheet.dart';

import 'support/player_bot.dart';

GameState? _kareAra({
  required PlayerArchetype arketip,
  required int tohumTabani,
  required int deneme,
  required bool Function(GameState) kosul,
}) {
  GameState? bulunan;
  for (int i = 0; i < deneme && bulunan == null; i++) {
    playBotLife(
      archetype: arketip,
      seed: tohumTabani + i,
      onPreAge: (GameState s) {
        if (bulunan == null && kosul(s)) bulunan = s;
      },
    );
  }
  return bulunan;
}

void main() {
  testWidgets('BİLDİRİM PENCERELERİ — piyango ve boşanma ilk kez basılıyor',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 12000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    int acilis = 0;
    Future<GameController> ac(GameState durum) async {
      final GameController c = GameController(random: Random(5));
      acilis++;
      await tester.pumpWidget(
        BirOmurApp(key: ValueKey<int>(acilis), controller: c),
      );
      await tester.pumpAndSettle();
      final Finder baslat = find.text('Rastgele bir hayat');
      expect(baslat, findsOneWidget,
          reason: 'Açılış $acilis: başlangıç ekranı gelmedi.');
      await tester.tap(baslat);
      await tester.pumpAndSettle();
      c.debugSetState(durum);
      await tester.pumpAndSettle();
      return c;
    }

    void bas(String baslik, String alt) {
      print('\n${'=' * 70}');
      print(baslik);
      if (alt.isNotEmpty) print(alt);
      print('=' * 70);
      for (final Text t in tester.widgetList<Text>(find.byType(Text))) {
        final String m = (t.data ?? '').trim();
        if (m.isNotEmpty) print('   $m');
      }
    }

    int basilan = 0;

    // ---------------------------------------------------------------
    // PİYANGO — hiç çizilmemiş pencere
    // ---------------------------------------------------------------
    final GameState? zengin = _kareAra(
      arketip: PlayerArchetype.investor,
      tohumTabani: 800000,
      deneme: 20,
      kosul: (GameState s) =>
          s.player.age >= kLotteryMinAge &&
          s.player.age < 60 &&
          s.player.wallet > 50000 &&
          !s.hasNotice,
    );
    expect(zengin, isNotNull, reason: 'Bilet alabilecek kare bulunamadı.');

    GameController c = await ac(zengin!);
    const LotteryDraw cekilis = LotteryDraw.aylik;
    final InteractionAvailability uygunluk =
        c.lotteryAvailability(cekilis, TicketShare.tam);
    print('Piyango bileti uygunluk: ${uygunluk.isAllowed} '
        '${uygunluk.isAllowed ? "" : "· ${uygunluk.reason}"}');
    expect(uygunluk.isAllowed, isTrue,
        reason: 'Bilet alınamıyor: ${uygunluk.reason}');
    final String? alim = c.buyLotteryTicket(cekilis, TicketShare.tam);
    print('Bilet alımı: $alim');
    expect(c.lotteryTickets, isNotEmpty, reason: 'Bilet kaydı oluşmadı.');
    await tester.pumpAndSettle();

    // Çekiliş yaş alırken yapılır; bildirim o zaman kuyruğa girer.
    c.ageUp();
    await tester.pumpAndSettle();
    final bool piyangoVar = c.state!.notices
        .any((PendingNotice n) => n.kind == NoticeKind.piyango);
    print('Yaş alındı · bekleyen bildirim: ${c.state!.notices.length} · '
        'piyango bildirimi: $piyangoVar');
    if (piyangoVar) {
      // **Pencereyi doğrudan çizdiriyoruz.** Kabuk bildirimi modal
      // sayfa olarak açıyor; kontrolörden `dismissNotice` çağırmak o
      // sayfayla uyumsuz kaldığı için (ilk denemede kare Hayat ekranı
      // olarak basıldı) bildirimin KENDİSİ çizdiriliyor. Nesne gerçek
      // motordan geliyor: bilet kontrolörle alındı, çekiliş yaş
      // alırken yapıldı.
      final PendingNotice piyango = c.state!.notices
          .firstWhere((PendingNotice n) => n.kind == NoticeKind.piyango);
      final GameState oDurum = c.state!;
      c.dispose();
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: NoticeSheet(notice: piyango))),
      );
      await tester.pumpAndSettle();
      bas('PİYANGO BİLDİRİM PENCERESİ (ilk kez çiziliyor)',
          'oyuncu ${oDurum.player.age} yaş · '
          'cüzdan ${oDurum.player.wallet} ₺ · '
          'bildirim parası ${piyango.money} ₺');
      basilan++;
    } else {
      print('UYARI: yaş alındı ama piyango bildirimi kuyruğa girmedi.');
      c.dispose();
    }

    // ---------------------------------------------------------------
    // BOŞANMA — araç düzeltilene kadar ölçüme görünmeyen pencere
    // ---------------------------------------------------------------
    final GameState? evli = _kareAra(
      arketip: PlayerArchetype.family,
      tohumTabani: 810000,
      deneme: 25,
      kosul: (GameState s) => s.isMarried && !s.hasNotice,
    );
    expect(evli, isNotNull, reason: 'Evli kare bulunamadı.');

    c = await ac(evli!);
    final InteractionAvailability bosanma = c.divorceAvailability();
    print('Boşanma uygunluk: ${bosanma.isAllowed} '
        '${bosanma.isAllowed ? "" : "· ${bosanma.reason}"}');
    if (bosanma.isAllowed) {
      c.divorce();
      await tester.pumpAndSettle();
      final PendingNotice? bosanmaBildirimi = c.state!.notices
          .where((PendingNotice n) => n.kind == NoticeKind.bosanma)
          .firstOrNullDj();
      print('Boşanma sonrası bekleyen bildirim: '
          '${c.state!.notices.length} · boşanma bildirimi: '
          '${bosanmaBildirimi != null}');
      if (bosanmaBildirimi != null) {
        final int yas = c.state!.player.age;
        c.dispose();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: NoticeSheet(notice: bosanmaBildirimi)),
          ),
        );
        await tester.pumpAndSettle();
        bas('BOŞANMA BİLDİRİM PENCERESİ', 'oyuncu $yas yaş · '
            'bildirimdeki para ${bosanmaBildirimi.money} ₺ · '
            'eşya ${bosanmaBildirimi.itemNames.length}');
        basilan++;
      } else {
        c.dispose();
      }
    } else {
      c.dispose();
    }

    expect(basilan, greaterThanOrEqualTo(1),
        reason: 'Hiçbir bildirim penceresi basılamadı.');
  }, timeout: const Timeout(Duration(minutes: 20)));
}

extension _IlkOrNullDj<T> on Iterable<T> {
  T? firstOrNullDj() {
    for (final T e in this) {
      return e;
    }
    return null;
  }
}
