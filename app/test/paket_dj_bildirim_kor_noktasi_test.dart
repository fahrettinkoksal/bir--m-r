// Paket DJ — bildirim kör noktası ve çift yazılan kayıp.
//
// ÖLÇÜLEN İKİ KUSUR:
//
// 1. **Ölçüm aracı aksiyon kaynaklı bildirimleri yutuyordu.** Bot
//    `c.divorce()` gibi bir aksiyondan sonra bildirimi kurduğu satırda
//    kapatıyordu (`while (hasNotice) dismissNotice();`, on yerde) ve o
//    bildirim döngünün başına hiç dönmediği için ne `onYear`'a ne Paket
//    CR'ın eklediği `onPending`'e görünüyordu. 100 hayat:
//
//    | tür | eski (kör) | yeni |
//    |---|---|---|
//    | aktivite | **1** | **8179** |
//    | bosanma | **0** | **57** |
//    | miras | 194 | 730 |
//    | burc | 1220 | 3151 |
//    | piyango | 0 | **0** (bot hiç bilet almıyor) |
//
//    Düzeltme: `botBildirimleriKapat` kapatmadan önce ölçüme veriyor.
//
// 2. **Bildirim penceresi aynı kaybı iki kez yazıyordu.** Boşanma
//    penceresi ilk kez basıldığında "Mutluluk -15" alt alta iki kez
//    çıktı: bildirim hem `happinessDelta` taşıyor hem `effects`
//    içinde mutluluk kalemi var, sayfa ikisini de çiziyordu.
// ignore_for_file: avoid_print
library;

import 'dart:io';
import 'dart:math';

import 'package:bir_omur/data/lottery_catalog.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/interaction.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:bir_omur/ui/widgets/notice_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
  group('Paket DJ — bildirim kör noktası', () {
    // ---------------------------------------------------------------
    // §1 Araç kör değil
    // ---------------------------------------------------------------
    test('§1 aksiyon kaynaklı bildirim ölçüme görünür', () {
      final Map<String, int> sayac = <String, int>{};
      for (int i = 0; i < 25; i++) {
        playBotLife(
          archetype: PlayerArchetype.family,
          seed: 700000 + i,
          onPending: (GameState s) {
            for (final PendingNotice n in s.notices) {
              sayac[n.kind.name] = (sayac[n.kind.name] ?? 0) + 1;
            }
          },
        );
      }
      print('25 family hayatı · bildirim türleri: $sayac');
      // Boşanma bildirimi yalnızca bir aksiyondan doğar ve bot onu
      // kurduğu satırda kapatır. Kör araçta bu sayı 0'dı.
      expect(sayac['bosanma'] ?? 0, greaterThan(0),
          reason: 'Aksiyon kaynaklı bildirim yine ölçüme görünmüyor: '
              'botun kapatma yolu `botBildirimleriKapat`den geçmiyor olabilir.');
      expect(sayac['aktivite'] ?? 0, greaterThan(0),
          reason: 'Aktivite bildirimleri yine görünmüyor.');
    }, timeout: const Timeout(Duration(minutes: 25)));

    // ---------------------------------------------------------------
    // §2 Kapatma yolu tek
    // ---------------------------------------------------------------
    test('§2 bot bildirimleri yalnızca ölçen yardımcıyla kapatır', () {
      final String kaynak =
          File('test/support/player_bot.dart').readAsStringSync();
      // Yorumlar atlanır (Paket DH dersi): kural koda dairdir.
      final String kod = kaynak
          .split('\n')
          .where((String l) => !l.trimLeft().startsWith('//'))
          .join('\n');
      // `playBotLife` akışında doğrudan kapatma döngüsü kalmamalı.
      expect(
        RegExp(r'while \(c\.state!\.hasNotice\) \{\s*\n\s*c\.dismissNotice\(\);')
            .hasMatch(kod),
        isFalse,
        reason: 'Doğrudan kapatma döngüsü geri geldi; o bildirimler '
            'yine kör noktada kalır.',
      );
      expect(kod.contains('void botBildirimleriKapat('), isTrue,
          reason: 'Ölçen kapatma yardımcısı silinmiş.');
    });

    // ---------------------------------------------------------------
    // §3 Pencere aynı kaybı iki kez yazmaz
    // ---------------------------------------------------------------
    testWidgets('§3 boşanma penceresi "Mutluluk" satırını bir kez yazar',
        (WidgetTester tester) async {
      final GameState? evli = _kareAra(
        arketip: PlayerArchetype.family,
        tohumTabani: 810000,
        deneme: 25,
        kosul: (GameState s) => s.isMarried && !s.hasNotice,
      );
      expect(evli, isNotNull, reason: 'Evli kare bulunamadı.');

      final GameController c = GameController(random: Random(5));
      c.debugSetState(evli!);
      final InteractionAvailability uygun = c.divorceAvailability();
      expect(uygun.isAllowed, isTrue, reason: uygun.reason ?? '');
      c.divorce();
      final PendingNotice bildirim = c.state!.notices
          .firstWhere((PendingNotice n) => n.kind == NoticeKind.bosanma);
      c.dispose();

      // Bildirim ikisini de taşıyor olmalı — kusur taşımakta değil,
      // ikisini de ÇİZMEKTE. İddia bunu da sabitliyor.
      expect(bildirim.happinessDelta, lessThan(0));
      expect(bildirim.effects, isNotEmpty);

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: NoticeSheet(notice: bildirim))),
      );
      await tester.pumpAndSettle();

      final List<String> mutlulukSatirlari = tester
          .widgetList<Text>(find.byType(Text))
          .map((Text t) => t.data ?? '')
          .where((String m) => m.startsWith('Mutluluk'))
          .toList(growable: false);
      print('Boşanma penceresindeki "Mutluluk" satırları: '
          '$mutlulukSatirlari');
      expect(mutlulukSatirlari.length, 1,
          reason: 'Aynı kayıp ${mutlulukSatirlari.length} kez yazıldı: '
              '$mutlulukSatirlari');
    }, timeout: const Timeout(Duration(minutes: 15)));

    // ---------------------------------------------------------------
    // §4 Piyango penceresi çizilebiliyor
    // ---------------------------------------------------------------
    testWidgets('§4 piyango bildirimi kuyruğa girer ve okunur',
        (WidgetTester tester) async {
      // Bot hiç bilet almıyor (ÖLÇÜM: 100 hayatta piyango bildirimi 0),
      // bu yüzden pencere kontrolörün kendi API'siyle açılıyor. Botun
      // davranışı **değiştirilmedi**: bilet almak oyunun zarını kaydırır
      // ve bütün ölçümleri etkilerdi.
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

      final GameController c = GameController(random: Random(5));
      c.debugSetState(zengin!);
      expect(c.lotteryAvailability(LotteryDraw.aylik, TicketShare.tam)
          .isAllowed, isTrue);
      c.buyLotteryTicket(LotteryDraw.aylik, TicketShare.tam);
      expect(c.lotteryTickets, isNotEmpty);
      c.ageUp();
      final PendingNotice piyango = c.state!.notices.firstWhere(
          (PendingNotice n) => n.kind == NoticeKind.piyango,
          orElse: () => throw StateError(
              'Bilet alındı, yaş alındı ama piyango bildirimi yok.'));
      c.dispose();

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: NoticeSheet(notice: piyango))),
      );
      await tester.pumpAndSettle();
      final List<String> metinler = tester
          .widgetList<Text>(find.byType(Text))
          .map((Text t) => t.data ?? '')
          .toList(growable: false);
      print('Piyango penceresi: $metinler');
      // Bilet numarası yazılmalı: oyuncu neyi kaybettiğini/kazandığını
      // görebilsin (Paket I ilkesi).
      expect(metinler.any((String m) => m.contains('Numaran')), isTrue,
          reason: 'Piyango penceresi bilet numarasını yazmıyor.');
      expect(tester.takeException(), isNull);
    }, timeout: const Timeout(Duration(minutes: 15)));
  });
}
