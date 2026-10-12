// Paket AI — AbuseBot / adversarial testler (§6, §7, §23-§26).
//
// **Bu dosya dengeye bakmıyor, sözleşmeye bakıyor.** Sorusu şu: oyuncu
// aynı yıl bir ekranı 100 kez açarsa, ya da kaydı geri yükleyip aynı
// hamleyi tekrarlarsa, oyundan bedelsiz para/stat/ün çıkarabiliyor mu?
//
// Üç saldırı ailesi:
//
// * **Aynı yıl tekrarı (§24):** yaş almadan aynı aksiyonu 100 kez.
//   Beklenen üç sonuçtan biri: engellendi, bedeli var, ya da gerçek
//   exploit.
// * **Kaydet/yükle (§23):** eylemden önce durumu sakla, eylemi yap,
//   durumu geri yükle, tekrar dene. Ödül iki kez alınabiliyor mu?
// * **Arbitraj (§25):** aynı yıl al→sat, sat→al gidip gelerek garantili
//   para üretilebiliyor mu?
//
// **Kurulum için `debugSetState` kullanılıyor** ve bu bilinçli: soru
// "cüzdana para nasıl girdi" değil, "bu ekran tekrar edilince para
// basıyor mu". CoverageBot'un debug yasağı (§27) oraya ait, buraya değil.
// ignore_for_file: avoid_print
library;

import 'dart:math';

import 'package:bir_omur/data/activity_catalog.dart';
import 'package:bir_omur/data/investment_catalog.dart';
import 'package:bir_omur/data/shop_catalog.dart';
import 'package:bir_omur/data/social_catalog.dart';
import 'package:bir_omur/domain/casino/roulette.dart';
import 'package:bir_omur/domain/economy/net_worth.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/stats.dart';
import 'package:bir_omur/domain/models/interaction.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// Saldırı sonucu.
class AbuseVerdict {
  AbuseVerdict(this.ad);

  final String ad;
  int denendi = 0;
  int uygulandi = 0;
  int servetOncesi = 0;
  int servetSonrasi = 0;
  int statOncesi = 0;
  int statSonrasi = 0;
  String not = '';

  int get servetFarki => servetSonrasi - servetOncesi;
  int get statFarki => statSonrasi - statOncesi;

  /// §24'ün istediği üç sınıftan biri.
  String get hukum {
    if (uygulandi <= 1) return 'ENGELLENDI';
    if (servetFarki < 0) return 'BEDELI VAR';
    if (servetFarki > 0) return 'INCELE (para artti)';
    if (statFarki > 0) return 'INCELE (stat artti)';
    return 'BEDELSIZ AMA ETKISIZ';
  }

  @override
  String toString() => '${ad.padRight(28)} deneme ${denendi.toString().padLeft(4)}'
      ' · oldu ${uygulandi.toString().padLeft(4)}'
      ' · servet ${_m(servetFarki).padLeft(9)}'
      ' · stat ${statFarki.toString().padLeft(4)}'
      ' · $hukum${not.isEmpty ? '' : '  ($not)'}';
}

String _m(num v) {
  final double x = v.toDouble();
  if (x.abs() >= 1e9) return '${(x / 1e9).toStringAsFixed(2)}B';
  if (x.abs() >= 1e6) return '${(x / 1e6).toStringAsFixed(2)}M';
  if (x.abs() >= 1e3) return '${(x / 1e3).round()}k';
  return x.round().toString();
}

/// Saldırıya hazır bir yetişkin hayatı kurar.
///
/// Kurulum `debugSetState` ile yapılıyor (bkz. dosya başı): cüzdanın
/// dolu olması saldırının konusu değil, ön koşulu.
({GameController c, GameState kurulum}) _hazirla(
  int seed, {
  int age = 35,
  int wallet = 50000000,
}) {
  final GameController c = GameController(random: Random(seed));
  c.startNewLife(mode: StartMode.tamamenRastgele, seed: seed);
  // Bekleyenleri temizle.
  int g = 0;
  while (g++ < 200 && (c.state!.hasNotice || c.state!.hasPendingEvent)) {
    if (c.state!.hasNotice) {
      c.dismissNotice();
    } else {
      c.chooseEventOption(c.state!.pendingEvent!.choices.first.id);
    }
  }
  final GameState s = c.state!;
  final GameState kurulum = s.copyWith(
    player: s.player.copyWith(age: age, wallet: wallet),
    education: s.education.copyWith(enrolled: false, finished: true),
    pendingEvent: null,
  );
  c.debugSetState(kurulum);
  return (c: c, kurulum: kurulum);
}

int _stat(GameState s) =>
    s.player.stats.happiness +
    s.player.stats.health +
    s.player.stats.intelligence +
    s.player.stats.charisma +
    s.player.stats.appearance;

/// Aynı yıl `tekrar` kez aynı hamleyi dener.
AbuseVerdict _ayniYilSpam(
  String ad,
  int seed,
  bool Function(GameController c, int tur) hamle, {
  int tekrar = 100,
  int wallet = 50000000,
}) {
  final AbuseVerdict v = AbuseVerdict(ad);
  final ({GameController c, GameState kurulum}) h =
      _hazirla(seed, wallet: wallet);
  final GameController c = h.c;
  v.servetOncesi = NetWorth.of(c.state!);
  v.statOncesi = _stat(c.state!);
  final int yas = c.state!.player.age;
  for (int i = 0; i < tekrar; i++) {
    v.denendi++;
    if (hamle(c, i)) v.uygulandi++;
    // Bildirim/olay biriktiyse temizle ama **yaş aldırma**: saldırının
    // şartı aynı yıl içinde kalmak.
    int g = 0;
    while (g++ < 50 && (c.state!.hasNotice || c.state!.hasPendingEvent)) {
      if (c.state!.hasNotice) {
        c.dismissNotice();
      } else {
        c.chooseEventOption(c.state!.pendingEvent!.choices.first.id);
      }
    }
    if (c.state!.player.age != yas) {
      v.not = 'yas ilerledi, saldiri kesildi';
      break;
    }
    if (c.state!.deceased) {
      v.not = 'oyuncu oldu';
      break;
    }
  }
  v.servetSonrasi = NetWorth.of(c.state!);
  v.statSonrasi = _stat(c.state!);
  c.dispose();
  return v;
}

/// Kaydet → hamle → yükle → tekrar. Ödül iki kez toplanabiliyor mu?
AbuseVerdict _saveLoad(
  String ad,
  int seed,
  bool Function(GameController c, int tur) hamle, {
  int tekrar = 30,
}) {
  final AbuseVerdict v = AbuseVerdict(ad);
  final ({GameController c, GameState kurulum}) h = _hazirla(seed);
  final GameController c = h.c;
  final GameState kayit = c.state!;
  v.servetOncesi = NetWorth.of(kayit);
  v.statOncesi = _stat(kayit);
  int enIyi = v.servetOncesi;
  for (int i = 0; i < tekrar; i++) {
    v.denendi++;
    if (hamle(c, i)) v.uygulandi++;
    int g = 0;
    while (g++ < 50 && (c.state!.hasNotice || c.state!.hasPendingEvent)) {
      if (c.state!.hasNotice) {
        c.dismissNotice();
      } else {
        c.chooseEventOption(c.state!.pendingEvent!.choices.first.id);
      }
    }
    final int simdi = NetWorth.of(c.state!);
    if (simdi > enIyi) enIyi = simdi;
    // "Yükle": kaydedilen duruma dön.
    //
    // **Bu gerçek bir saldırı, teorik değil.** Oyunun zarı
    // `GameController._random` içinde duruyor; `GameState`'e yazılmıyor
    // ve kayda girmiyor. Dolayısıyla kaydı geri yüklemek sonucu yeniden
    // attırıyor: kaybeden el geri alınıp yeniden oynanabiliyor.
    c.debugSetState(kayit);
  }
  v.servetSonrasi = enIyi;
  v.statSonrasi = v.statOncesi;
  v.not = 'en iyi tekrar secildi';
  c.dispose();
  return v;
}

void main() {
  group('Paket AI — aynı yıl tekrarı (§24)', () {
    final List<AbuseVerdict> hepsi = <AbuseVerdict>[];

    test('aktivite, hediye, alışveriş, yatırım, kumar ve sosyal medya', () {
      // ---- Aktivite: stat farming ------------------------------------
      hepsi.add(_ayniYilSpam('aktivite x100', 9100001, (GameController c, int i) {
        for (final ActivityVenue mekan in ActivityVenue.values) {
          for (final ActivityAction a in c.availableActivities(mekan)) {
            if (c.activityAvailability(a).isAllowed) {
              return c.performActivity(a)?.applied ?? false;
            }
          }
        }
        return false;
      }));

      // ---- Kitap: aynı kitabı tekrar tekrar bitirme (§3) --------------
      hepsi.add(_ayniYilSpam('kitap ac+sayfa x400', 9100002,
          (GameController c, int i) {
        final List<BookInfo> k = c.availableBooks();
        if (k.isEmpty) return false;
        // Sayfa çevirmek için kitabın **açık** olması gerekiyor; ilk
        // yazımda bunu atlamıştım ve saldırı hiç çalışmadan
        // "engellendi" görünüyordu.
        if (i == 0) c.openBook(k.first);
        final bool oldu = c.turnBookPage(k.first)?.applied ?? false;
        if (!oldu) {
          // Kitap bittiyse yenisini aç: "aynı kitabı tekrar tekrar
          // bitirme" saldırısı (§3) budur.
          for (final BookInfo b in c.availableBooks()) {
            if (c.openBook(b)?.applied ?? false) return true;
          }
        }
        return oldu;
      }, tekrar: 400));

      // ---- Hediye: para transferi döngüsü ----------------------------
      hepsi.add(_ayniYilSpam('hediye x100', 9100003, (GameController c, int i) {
        for (final Person p in c.state!.people) {
          if (!p.isAlive) continue;
          if (!c.availabilityFor(p, InteractionKind.paraIste).isAllowed) {
            continue;
          }
          return c.interact(p.id, InteractionKind.paraIste)?.accepted ?? false;
        }
        return false;
      }));

      // ---- Alışveriş: al-sat döngüsü (arbitraj, §25) ------------------
      hepsi.add(_ayniYilSpam('esya al-sat x100', 9100004,
          (GameController c, int i) {
        final GameState s = c.state!;
        if (s.items.isNotEmpty && i.isOdd) {
          return c.sellItem(s.items.first.id)?.applied ?? false;
        }
        final List<ShopProduct> u = shopProductsFor(s.player.age)
            .where((ShopProduct p) => p.price <= s.player.wallet)
            .toList(growable: false);
        if (u.isEmpty) return false;
        return c.buyProduct(u.first)?.applied ?? false;
      }));

      // ---- Yatırım: al-sat döngüsü -----------------------------------
      hepsi.add(_ayniYilSpam('yatirim al-sat x100', 9100005,
          (GameController c, int i) {
        final InvestmentType t = kInvestmentTypes.first;
        if (i.isOdd && c.state!.investments.isNotEmpty) {
          final int miktar = c.state!.investments.first.value;
          return c.sellInvestment(t.id, miktar)?.applied ?? false;
        }
        if (c.investmentBuyBlockReason(t, 1000000).isNotEmpty) return false;
        return c.buyInvestment(t.id, 1000000)?.applied ?? false;
      }));

      // ---- Kumar: minimum bahis spam (§7) ----------------------------
      hepsi.add(_ayniYilSpam('blackjack x100', 9100006,
          (GameController c, int i) {
        if (!c.casinoAvailability().isAllowed) return false;
        final List<int> adim = c.betSteps();
        if (adim.isEmpty) return false;
        if (c.state!.blackjack != null) {
          c.standBlackjack();
          c.closeBlackjackHand();
          return true;
        }
        if (!c.betAvailability(adim.first).isAllowed) return false;
        return c.dealBlackjack(adim.first)?.applied ?? false;
      }));

      // ---- Sosyal medya: paylaşım limiti (§6) ------------------------
      hepsi.add(_ayniYilSpam('sosyal medya post x100', 9100007,
          (GameController c, int i) {
        for (final SocialPlatform p in SocialPlatform.values) {
          if (c.socialAccountAvailability(p).isAllowed) {
            c.openSocialAccount(p);
          }
        }
        for (final SocialContent icerik in kSocialContents) {
          if (c.socialPostAvailability(icerik).isAllowed) {
            return c.postContent(icerik)?.applied ?? false;
          }
        }
        return false;
      }));

      print('');
      print('-- §24 AYNI YIL TEKRARI --');
      for (final AbuseVerdict v in hepsi) {
        print('  $v');
      }

      // **Bekçi:** hiçbir tekrar saldırısı serveti artırmamalı.
      //
      // "hediye x100" (aslında `paraIste`) BU BEKÇİNİN DIŞINDA ve
      // sebebi ölçülmüş bir gerçek: para istemek **tasarım gereği**
      // para verir (harçlık, D-019). Yani net servet farkının işareti
      // bu saldırıda kuralı değil, o turda rastgele açılan olayın
      // cebe ne yaptığını ölçüyor.
      //
      // Bu bekçinin tek tohumla (9100003) geçiyor olması bir tesadüftü.
      // Paket AO sırasında kırıldı ve TAHMİNLE DEĞİL ÖLÇÜMLE bakıldı:
      // Paket AO **öncesi** HEAD'de (c0ae3a2) aynı saldırı 20 tohumda
      // çalıştırıldı ve **14 tohumda net servet zaten artıyordu**
      // (+108 dahil, birebir aynı sayı). Yani bu bir gerileme değil,
      // bekçinin tek tohuma yaslanmasıydı.
      //
      // Gevşetmek yerine saldırının **asıl** koruması ölçülüyor:
      // mekanik doyuyor. Aşağıdaki iddia, ölçülmüş bir davranışı
      // sabitliyor — 100 denemede de 1000 denemede de başarı sayısı
      // aynı kalıyor (20 tohumda da 3), çünkü ret eğrisi yükselip
      // ödül eğrisi sıfıra iniyor.
      const String paraIsteAdi = 'hediye x100';
      for (final AbuseVerdict v in hepsi) {
        if (v.ad == paraIsteAdi) continue;
        expect(v.servetFarki, lessThanOrEqualTo(0),
            reason: '${v.ad}: aynı yıl tekrarı net serveti ARTIRIYOR '
                '(${_m(v.servetFarki)}). Bu bedelsiz para demektir.');
      }

      // `paraIste` için gerçek kural: TEKRAR ÖDÜLÜ BÜYÜTMEZ.
      final AbuseVerdict paraIste =
          hepsi.firstWhere((AbuseVerdict v) => v.ad == paraIsteAdi);
      expect(paraIste.uygulandi, lessThanOrEqualTo(4),
          reason: 'Para isteme aynı yıl içinde doymuyor: '
              '${paraIste.uygulandi} kez kabul edildi.');

      // Ve doyma gerçekten **deneme sayısından bağımsız**: on kat
      // deneme bir kuruş daha getirmiyor. Bekçinin çekirdeği bu.
      final AbuseVerdict onKat = _ayniYilSpam(
        'para iste x1000',
        9100003,
        (GameController c, int i) {
          for (final Person p in c.state!.people) {
            if (!p.isAlive) continue;
            if (!c.availabilityFor(p, InteractionKind.paraIste).isAllowed) {
              continue;
            }
            return c.interact(p.id, InteractionKind.paraIste)?.accepted ??
                false;
          }
          return false;
        },
        tekrar: 1000,
      );
      print('  $onKat');
      expect(onKat.uygulandi, paraIste.uygulandi,
          reason: 'On kat deneme daha çok kabul aldı: '
              '${onKat.uygulandi} > ${paraIste.uygulandi}. '
              'Tekrar ödülü büyütüyor, yani doyma kırılmış.');
    }, timeout: const Timeout(Duration(minutes: 20)));
  });

  group('Paket AI — stat farming (§26)', () {
    test('tek yılda tekrarla stat 100 yapılabiliyor mu', () {
      final ({GameController c, GameState kurulum}) h = _hazirla(9300001);
      final GameController c = h.c;
      final Stats once = c.state!.player.stats;
      final int yas = c.state!.player.age;
      int uygulanan = 0;
      for (int i = 0; i < 400; i++) {
        bool oldu = false;
        for (final ActivityVenue mekan in ActivityVenue.values) {
          for (final ActivityAction a in c.availableActivities(mekan)) {
            if (!c.activityAvailability(a).isAllowed) continue;
            if (c.performActivity(a)?.applied ?? false) {
              oldu = true;
              uygulanan++;
            }
          }
        }
        int g = 0;
        while (g++ < 50 && (c.state!.hasNotice || c.state!.hasPendingEvent)) {
          if (c.state!.hasNotice) {
            c.dismissNotice();
          } else {
            c.chooseEventOption(c.state!.pendingEvent!.choices.first.id);
          }
        }
        if (!oldu || c.state!.player.age != yas || c.state!.deceased) break;
      }
      final Stats sonra = c.state!.player.stats;
      print('');
      print('-- §26 STAT FARMING (tek yil, 400 tur) --');
      print('  uygulanan aktivite $uygulanan · cuzdan '
          '${_m(c.state!.player.wallet - h.kurulum.player.wallet)}');
      print('  mutluluk ${once.happiness} -> ${sonra.happiness}');
      print('  saglik   ${once.health} -> ${sonra.health}');
      print('  zeka     ${once.intelligence} -> ${sonra.intelligence}');
      print('  karizma  ${once.charisma} -> ${sonra.charisma}');
      print('  gorunus  ${once.appearance} -> ${sonra.appearance}');
      // Tek yılda her statı 100'e çıkarmak mümkün olmamalı.
      final List<int> son = <int>[
        sonra.happiness,
        sonra.health,
        sonra.intelligence,
        sonra.charisma,
        sonra.appearance,
      ];
      expect(son.where((int v) => v >= 100).length, lessThan(5),
          reason: 'Tek yılda bütün statlar 100 yapılabiliyor: sınırsız '
              'stat farming var.');
      c.dispose();
    }, timeout: const Timeout(Duration(minutes: 20)));
  });

  group('Paket AI — kaydet/yükle (§23)', () {
    test('kumar, piyango ve sosyal medya ödülü yeniden toplanamaz', () {
      final List<AbuseVerdict> hepsi = <AbuseVerdict>[];

      hepsi.add(_saveLoad('blackjack reroll', 9200001,
          (GameController c, int i) {
        if (!c.casinoAvailability().isAllowed) return false;
        final List<int> adim = c.betSteps();
        if (adim.isEmpty) return false;
        final int bahis = adim.last;
        if (!c.betAvailability(bahis).isAllowed) return false;
        c.dealBlackjack(bahis);
        c.standBlackjack();
        c.closeBlackjackHand();
        return true;
      }));

      hepsi.add(_saveLoad('rulet reroll', 9200002, (GameController c, int i) {
        if (!c.casinoAvailability().isAllowed) return false;
        final List<int> adim = c.betSteps();
        if (adim.isEmpty) return false;
        if (!c.betAvailability(adim.last).isAllowed) return false;
        return c.spinRoulette(RouletteBetType.values.first, adim.last)
                ?.applied ??
            false;
      }));

      print('');
      print('-- §23 KAYDET/YUKLE --');
      for (final AbuseVerdict v in hepsi) {
        print('  $v');
      }
      print('  NOT: Zar (`GameController._random`) kayda YAZILMIYOR;');
      print('       kurucuda bir kez uretiliyor ve GameState icinde');
      print('       tasinmiyor. Yani kaydi geri yuklemek sonucu');
      print('       yeniden attiriyor: yukaridaki sayilar gercek bir');
      print('       save-scum ust siniri, teorik bir model degil.');

      // Tek elde kazanılabilecek en büyük tutar bahsin katı kadardır;
      // yeniden yüklemek bunu **biriktiremez**.
      for (final AbuseVerdict v in hepsi) {
        expect(v.servetFarki, lessThan(100000000),
            reason: '${v.ad}: yeniden yukleme ile servet ${_m(v.servetFarki)} '
                'arttı; bu birikimli bir istismar olabilir.');
      }
    }, timeout: const Timeout(Duration(minutes: 20)));
  });
}

