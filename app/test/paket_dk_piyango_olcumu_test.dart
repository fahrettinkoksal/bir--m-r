// Paket DK — piyangonun ölçümü ve kalıcı bekçisi.
//
// **Neden yazıldı.** Paket DJ'nin bildirim ölçümü piyangonun hiç
// oynanmadığını gösterdi: `player_bot.dart` içinde tek referans yok,
// yani piyangonun **ekonomisi hiç ölçülmemiş**. 1/500.000 ihtimalle
// 50.000.000 ₺ veren bir kalem, beklenen getirisi bilet fiyatını
// aşıyorsa servet motoru olur. Bu soru zar gerektirmez: katalogdan
// hesaplanır.
//
// ÖLÇÜM (katalogdan, zarsız):
//
// | çekiliş | bilet | beklenen getiri | getiri/fiyat | kasa payı |
// |---|---|---|---|---|
// | Olağan (aylik) | 500 ₺ | 281,25 ₺ | 0,5625 | **%43,75** |
// | Yılbaşı | 1.200 ₺ | 645,00 ₺ | 0,5375 | **%46,25** |
//
// Yani piyango oyuncuyu zengin etmiyor; gerçek piyangoların ödeme
// oranına da yakın. Kusur bulunmadı — bu dosya o sayıyı **sabitliyor**
// ki katalog ileride sessizce para basan bir kaleme dönüşmesin.
// ignore_for_file: avoid_print
library;

import 'dart:io';
import 'dart:math';

import 'package:bir_omur/data/lottery_catalog.dart';
import 'package:bir_omur/data/economy.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/life_log.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/player_bot.dart';
import 'support/test_flow.dart';

/// Bir çekilişin tam bilet için beklenen getirisi (katalogdan).
double _beklenenGetiri(LotteryDraw draw) => draw.prizes
    .fold<double>(0, (double acc, LotteryPrize p) => acc + p.chance * p.fullTicketAmount);

void main() {
  group('Paket DK — piyango', () {
    // ---------------------------------------------------------------
    // §1 Katalog: kasa kazanır, oyuncu zengin olmaz
    // ---------------------------------------------------------------
    test('§1 her çekilişin beklenen getirisi bilet fiyatının altında', () {
      print('ÇEKİLİŞ | BİLET | BEKLENEN GETİRİ | ORAN | KASA PAYI');
      for (final LotteryDraw draw in LotteryDraw.values) {
        final double ev = _beklenenGetiri(draw);
        final int fiyat = draw.fullTicketPrice;
        final double oran = ev / fiyat;
        print('  ${draw.id.padRight(8)} ${fiyat.toString().padLeft(6)} ₺  '
            '${ev.toStringAsFixed(2).padLeft(12)} ₺  '
            '${oran.toStringAsFixed(4)}  %${(100 * (1 - oran)).toStringAsFixed(2)}');
        // Bu iddia bir denge sayısı değil, bir **tür** iddiası:
        // piyango bir gider kalemidir, gelir kalemi değil.
        expect(oran, lessThan(1.0),
            reason: '${draw.id}: beklenen getiri bilet fiyatını aştı — '
                'piyango para basıyor.');
        // Ödeme oranı makul bir bantta kalsın: tamamen umutsuz da
        // olmasın (oyuncu hiç kazanmazsa kalem ölü içeriktir).
        expect(oran, greaterThan(0.25),
            reason: '${draw.id}: ödeme oranı %25 altına indi; kalem ölü '
                'içeriğe dönüşür.');
        // İhtimaller toplamı 1'i geçemez: eşik yürüyüşü bozulur.
        final double toplamIhtimal = draw.prizes
            .fold<double>(0, (double a, LotteryPrize p) => a + p.chance);
        expect(toplamIhtimal, lessThan(1.0),
            reason: '${draw.id}: ikramiye ihtimalleri toplamı 1\'i geçti; '
                'küçük ikramiyeler hiç çıkamaz.');
      }
    });

    // ---------------------------------------------------------------
    // §2 Yıllık tavan servet değiştirmez
    // ---------------------------------------------------------------
    test('§2 yılda alınabilecek bütün biletler servet değiştirmez', () {
      for (final LotteryDraw draw in LotteryDraw.values) {
        final double ev = _beklenenGetiri(draw);
        final int yillikGider = draw.fullTicketPrice * draw.maxTicketsPerAge;
        final double yillikBeklenenKayip =
            (draw.fullTicketPrice - ev) * draw.maxTicketsPerAge;
        print('${draw.id}: yılda en çok ${draw.maxTicketsPerAge} bilet · '
            'gider $yillikGider ₺ · beklenen kayıp '
            '${yillikBeklenenKayip.toStringAsFixed(0)} ₺');
        // Asgari ücretin küçük bir kısmı olmalı: piyango ne zengin
        // eder ne iflas ettirir (D-039'un yaşam gideri mantığı).
        expect(yillikGider, lessThan(Economy.netYearlyMinimumWage ~/ 10),
            reason: '${draw.id}: yıllık bilet gideri asgari ücretin '
                'onda birini aştı; bu bir denge kararı olur.');
      }
    });

    // ---------------------------------------------------------------
    // §3 Pay ölçeği: çeyrek bilet çeyrek ikramiye
    // ---------------------------------------------------------------
    test('§3 bilet payı fiyatı ve ikramiyeyi aynı oranda böler', () {
      for (final LotteryDraw draw in LotteryDraw.values) {
        for (final TicketShare pay in TicketShare.values) {
          expect(draw.priceFor(pay),
              (draw.fullTicketPrice * pay.ratio).round(),
              reason: '${draw.id}/${pay.name}: fiyat payla ölçeklenmiyor.');
        }
      }
      // Kaynak taraması: ikramiye de aynı oranla ölçeklenmeli. Bu satır
      // olmazsa çeyrek bilet tam ikramiye kazanır — piyango para basar.
      final String kaynak =
          File('lib/domain/casino/lottery.dart').readAsStringSync();
      expect(kaynak.contains('bilet.share.ratio'), isTrue,
          reason: 'İkramiye bilet payıyla ölçeklenmiyor.');
    });

    // ---------------------------------------------------------------
    // §4 Motor kataloğu gerçekten uyguluyor
    // ---------------------------------------------------------------
    test('§4 gerçek çekilişlerde amorti basamağı çıkıyor', () {
      // Amortinin ihtimali 1/10; yakınsaması hızlı olan tek basamak.
      // Büyük ikramiyeler milyonlarca çekiliş ister, onların iddiası
      // §1'de katalog üstünden kuruldu.
      GameState? baslangic;
      for (int i = 0; i < 20 && baslangic == null; i++) {
        playBotLife(
          archetype: PlayerArchetype.investor,
          seed: 800000 + i,
          onPreAge: (GameState s) {
            if (baslangic == null &&
                s.player.age >= kLotteryMinAge &&
                s.player.age < 45 &&
                s.player.wallet > 200000 &&
                !s.hasNotice) {
              baslangic = s;
            }
          },
        );
      }
      expect(baslangic, isNotNull, reason: 'Bilet alacak kare bulunamadı.');

      final GameController c = GameController(random: Random(3));
      c.debugSetState(baslangic!);
      int alinan = 0;
      int kazanan = 0;
      int cekilisSatiri = 0;
      // Her yıl tavan kadar bilet al, yaş al, sonucu oku.
      for (int yil = 0; yil < 25 && !c.state!.deceased; yil++) {
        for (int k = 0; k < LotteryDraw.aylik.maxTicketsPerAge; k++) {
          if (!c.lotteryAvailability(LotteryDraw.aylik, TicketShare.tam)
              .isAllowed) {
            break;
          }
          c.buyLotteryTicket(LotteryDraw.aylik, TicketShare.tam);
          alinan++;
        }
        final int yasOnce = c.state!.player.age;
        // **`ageUp()` beş kapılı.** İlk yazımda yalnızca bildirimleri
        // kapatıyordum; bekleyen olay/kriz/seçim kapanmadığı için yaş
        // ilerlemedi, yıllık bilet tavanı dolu kaldı ve 25 yılda
        // yalnızca **24** bilet alındı. Kapıları test yardımcıları
        // kapatıyor.
        resolvePendingEvents(c);
        resolvePendingCrisis(c);
        resolveEducationChoices(c);
        while (c.state!.hasNotice) {
          c.dismissNotice();
        }
        c.ageUp();
        while (c.state!.hasNotice) {
          c.dismissNotice();
        }
        if (c.state!.player.age == yasOnce) break; // kapı açılmadı
        // **İlk yazımda "cüzdan arttı mı" diye bakıyordum ve iddia
        // boşa çalışıyordu:** cüzdanı maaş, kira, temettü de artırır.
        // 25 yılın 25'i "kazandı" çıkıyordu, yani satır hiçbir şey
        // kanıtlamıyordu (Paket DG'nin §7 dersinin aynısı, bu kez
        // kendi testimde). Doğru kaynak oyunun **kendi kaydı**:
        // çekiliş satırı kaybı "tutmadı" diye yazıyor.
        for (final LifeLogEntry e in c.state!.log) {
          if (e.age != yasOnce + 1) continue;
          if (!e.text.startsWith('Piyango')) continue;
          cekilisSatiri++;
          if (!e.text.contains('tutmadı')) kazanan++;
        }
      }
      c.dispose();

      print('Gerçek çekiliş: $alinan bilet · $cekilisSatiri çekiliş satırı · '
          '$kazanan yılda en az bir bilet tuttu.');
      expect(alinan, greaterThan(100),
          reason: 'Bilet alınamadı; tavan ya da kapı değişmiş olabilir.');
      expect(cekilisSatiri, greaterThan(0),
          reason: 'Bilet alındı ama çekiliş günlüğe hiç yazılmadı.');
      // Amortinin ihtimali 1/10 ve yılda 12 bilet alınıyor: bir yılda
      // hiç tutmama ihtimali 0,9^12 ≈ %28, 25 yılın HEPSİNDE hiç
      // tutmaması 0,28^25 ≈ 10^-14. Çıkmıyorsa eşik yürüyüşü bozuktur.
      expect(kazanan, greaterThan(0),
          reason: '$alinan biletin hiçbiri tutmadı: ikramiye basamakları '
              'motorda uygulanmıyor olabilir.');
    }, timeout: const Timeout(Duration(minutes: 20)));
  });
}
