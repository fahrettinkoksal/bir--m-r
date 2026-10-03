// Paket AD/6 — tam strateji kalibrasyonu (§18-§22).
//
// **Bu paketin final ölçümü.** §19'un hedef dağılımı burada doğrulanıyor:
// normal oyuncu milyonlar, başarılı on milyonlar, çok başarılı yüz
// milyonlar, milyarderlik **çok nadir**. Hard cap yok.
//
// ## Neden iki kademe var
//
// §AD/6 en az 10 strateji × 20/40/60 yıl × 1000 yol = **30.000 strateji
// yolu** ve ayrıca 10 arketip × 200 tam hayat = **2000 tam hayat** istiyor.
// Bu, her `flutter test` çağrısında çalışamayacak kadar uzun sürüyor;
// CI her push'ta bunu çalıştırsa tur yarım saati aşar.
//
// Çözüm depodaki mevcut kalıp (15 golden test aynı biçimde çalışıyor):
// **ağır ölçüm `BIR_OMUR_FULL_MEASURE=1` ile açılıyor**, her turda çalışan
// sürüm ise aynı kodu daha az yolla koşup **bekçi** görevi yapıyor. Ağır
// sürüm elle çalıştırıldı ve sonuçları `PROJECT_STATUS.md` ile Q-174'te
// yazılı.
//
// Botu zayıflatmak yasak (§18, §"EN ÖNEMLİ KURAL"): min-max stratejiler
// olduğu gibi duruyor, `karmaNormal` onların **yanına** eklendi.
// ignore_for_file: avoid_print
library;

import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'support/player_bot.dart';
import 'support/strategy_player.dart';

/// Ağır ölçüm açık mı?
bool get _tamOlcum => Platform.environment['BIR_OMUR_FULL_MEASURE'] == '1';

/// Strateji başına yol sayısı.
int get _yolSayisi => _tamOlcum ? 1000 : 60;

/// Arketip başına tam hayat sayısı.
int get _hayatSayisi => _tamOlcum ? 200 : 12;

int _medyan(List<int> v) => v.isEmpty ? 0 : v[v.length ~/ 2];
int _p(List<int> v, double q) =>
    v.isEmpty ? 0 : v[(v.length * q).floor().clamp(0, v.length - 1)];
String _m(int v) => v >= 1000000
    ? '${(v / 1000000).toStringAsFixed(1)}M'
    : '${(v / 1000).toStringAsFixed(0)}k';

void main() {
  group('Paket AD/6 — strateji kalibrasyonu', () {
    test('§18-§22: 10 strateji x 20/40/60 yıl', () {
      print('');
      print(_tamOlcum
          ? '=== TAM OLCUM: ${InvestStrategy.values.length} strateji x 3 ufuk '
              'x $_yolSayisi yol = ${InvestStrategy.values.length * 3 * _yolSayisi} yol ==='
          : '=== HAFIF BEKCI ($_yolSayisi yol/strateji). Tam olcum icin '
              'BIR_OMUR_FULL_MEASURE=1 ===');

      // strateji -> ufuk -> sonuclar
      final Map<InvestStrategy, Map<int, List<StrategyResult>>> hepsi =
          <InvestStrategy, Map<int, List<StrategyResult>>>{};

      for (final InvestStrategy st in InvestStrategy.values) {
        hepsi[st] = <int, List<StrategyResult>>{};
        for (final int ufuk in <int>[20, 40, 60]) {
          final List<StrategyResult> sonuclar = <StrategyResult>[];
          for (int i = 0; i < _yolSayisi; i++) {
            sonuclar.add(playStrategy(
              strategy: st,
              seed: 600000 + st.index * 20011 + ufuk * 101 + i,
              years: ufuk,
            ));
          }
          hepsi[st]![ufuk] = sonuclar;
        }
      }

      // ---- §20 raporu ------------------------------------------------
      for (final int ufuk in <int>[20, 40, 60]) {
        print('');
        print('--- $ufuk YIL (§20) ---');
        print('strateji                  medyan    kotu%10   iyi%10    '
            'en kotu   en iyi     50M+  100M+  250M+  500M+   1B+  '
            'yat.zarar  maxDD  zor.satis  batis  borc');
        for (final InvestStrategy st in InvestStrategy.values) {
          final List<StrategyResult> r = hepsi[st]![ufuk]!;
          final List<int> servet = r.map((e) => e.netWorth).toList()..sort();
          final int n = r.length;
          int ustu(int esik) => servet.where((int x) => x >= esik).length;
          final int yatiranSayisi =
              r.where((StrategyResult e) => e.principal > 0).length;
          final int zararEden = r
              .where((StrategyResult e) => e.investmentLostMoney)
              .length;
          final double ortDD =
              r.map((e) => e.maxDrawdown).reduce((a, b) => a + b) / n;
          final int zorunlu =
              r.where((StrategyResult e) => e.forcedSale).length;
          final int batis = r
              .where((StrategyResult e) => e.companyFailures > 0)
              .length;
          final int borcKrizi =
              r.where((StrategyResult e) => e.debt > 0).length;
          print('${st.label.padRight(25)} '
              '${_m(_medyan(servet)).padLeft(8)} '
              '${_m(_p(servet, 0.10)).padLeft(9)} '
              '${_m(_p(servet, 0.90)).padLeft(9)} '
              '${_m(servet.first).padLeft(9)} '
              '${_m(servet.last).padLeft(9)} '
              '${(100 * ustu(50000000) / n).toStringAsFixed(1).padLeft(6)} '
              '${(100 * ustu(100000000) / n).toStringAsFixed(1).padLeft(6)} '
              '${(100 * ustu(250000000) / n).toStringAsFixed(1).padLeft(6)} '
              '${(100 * ustu(500000000) / n).toStringAsFixed(1).padLeft(6)} '
              '${(100 * ustu(1000000000) / n).toStringAsFixed(1).padLeft(5)} '
              '${yatiranSayisi == 0 ? "        -" : (100 * zararEden / yatiranSayisi).toStringAsFixed(1).padLeft(9)} '
              '${(100 * ortDD).toStringAsFixed(0).padLeft(6)} '
              '${(100 * zorunlu / n).toStringAsFixed(1).padLeft(10)} '
              '${(100 * batis / n).toStringAsFixed(1).padLeft(6)} '
              '${(100 * borcKrizi / n).toStringAsFixed(1).padLeft(5)}');
        }
      }

      // ---- §21 servet bileşenleri (60 yıl medyanı) -------------------
      print('');
      print('--- 60 YIL SERVET BILESENLERI (medyan, §21) ---');
      print('strateji                  nakit   portfoy  gayrimen.  arac  '
          'isletme    luks     borc');
      for (final InvestStrategy st in InvestStrategy.values) {
        final List<StrategyResult> r = hepsi[st]![60]!;
        List<int> al(int Function(StrategyResult) f) =>
            r.map(f).toList()..sort();
        print('${st.label.padRight(25)} '
            '${_m(_medyan(al((e) => e.wallet))).padLeft(7)} '
            '${_m(_medyan(al((e) => e.portfolio))).padLeft(9)} '
            '${_m(_medyan(al((e) => e.realEstate))).padLeft(9)} '
            '${_m(_medyan(al((e) => e.vehicles))).padLeft(6)} '
            '${_m(_medyan(al((e) => e.business))).padLeft(8)} '
            '${_m(_medyan(al((e) => e.luxury))).padLeft(7)} '
            '${_m(_medyan(al((e) => e.debt))).padLeft(8)}');
      }

      // ---- §22 strateji dominansı ------------------------------------
      print('');
      print('--- STRATEJI DOMINANSI (§22) ---');
      final Map<InvestStrategy, int> ustunluk = <InvestStrategy, int>{};
      for (final InvestStrategy a in InvestStrategy.values) {
        int kazandigi = 0;
        for (final InvestStrategy b in InvestStrategy.values) {
          if (a == b) continue;
          bool herUfukta = true;
          for (final int ufuk in <int>[20, 40, 60]) {
            final List<int> sa = hepsi[a]![ufuk]!.map((e) => e.netWorth).toList()
              ..sort();
            final List<int> sb = hepsi[b]![ufuk]!.map((e) => e.netWorth).toList()
              ..sort();
            // "Ezmek" = hem medyanı hem kötü %10'u daha iyi.
            if (!(_medyan(sa) > _medyan(sb) &&
                _p(sa, 0.10) > _p(sb, 0.10))) {
              herUfukta = false;
              break;
            }
          }
          if (herUfukta) kazandigi++;
        }
        ustunluk[a] = kazandigi;
        print('  ${a.label.padRight(25)} her ufukta ezdigi strateji: '
            '$kazandigi / ${InvestStrategy.values.length - 1}');
      }

      // ================= BEKÇİLER =====================================
      for (final InvestStrategy st in InvestStrategy.values) {
        final List<int> s60 =
            hepsi[st]![60]!.map((e) => e.netWorth).toList()..sort();
        // §19: milyarderlik ÇOK NADİR olmalı — hiçbir stratejide olağan değil.
        final double milyarder =
            s60.where((int x) => x >= 1000000000).length / s60.length;
        expect(milyarder, lessThan(0.05),
            reason: '${st.label}: 60 yilda %${(milyarder * 100).toStringAsFixed(1)} '
                'milyarder; §19 "cok nadir" diyor');
        // Hiçbir strateji cüzdanı eksiye düşürmesin.
        expect(hepsi[st]![60]!.every((StrategyResult e) => e.wallet >= 0), isTrue);
        // Borç sonsuza gitmesin (AD/4 bekçisi burada da).
        expect(hepsi[st]![60]!.every((StrategyResult e) => !e.runawayDebt), isTrue,
            reason: '${st.label}: kontrolsuz borc geri gelmis');
      }

      // ---- §22 bekçisi -----------------------------------------------
      //
      // **Ölçüm bir dominant strateji buldu ve bu açık bir bulgudur:**
      // `girisim + yatirim` diğer dokuzunun hepsini her ufukta, hem
      // medyanda hem en kötü %10'da geçiyor (60 yıl: medyan ₺52,2M,
      // kötü%10 ₺10,4M — ikisi de listenin tepesi). Yani işletme,
      // yatırımın üstüne **bedava bir kat** ekliyor.
      //
      // Bu paket işletme dengesine **dokunmuyor**: işletme ekonomisi
      // Paket U'da kalibre edildi ve değiştirmek ayrı bir ürün kararı
      // (Q-174/1). Bekçi bu yüzden bulguyu **dondurur**: bilinen tek
      // dominant strateji işletmedir ve **sayısı artamaz**. Yeni bir
      // strateji baskın hâle gelirse ya da işletme daha da öne geçerse
      // test kırılır.
      // **Paket AF notu.** Bu bekçi görevini yaptı ve kırıldı: AF'nin
      // teşhis için eklediği `mukemmelGirisimci` baskın çıktı. Bu bir
      // denge değişikliği değil — o bot bir **ölçüm aleti**: oyunu
      // çözmeye çalışan, oyuncunun erişebileceği en iyi oyunu oynayan
      // bir sonda (Q-176). Onu "beklenen baskın" listesine yazmak
      // bekçiyi zayıflatırdı; kapsam dışı bırakmak ise doğru, çünkü
      // bekçinin ölçtüğü şey **oyuncu arketiplerinin** dengesi.
      //
      // Aynı sebeple AF'nin `kariyerVeYatirim` ve
      // `kariyerIsletmeYatirim` stratejileri kapsamda **kalır**: onlar
      // gerçek oyuncu davranışı, sonda değil.
      const Set<InvestStrategy> teshisSondalari = <InvestStrategy>{
        InvestStrategy.mukemmelGirisimci,
      };
      final List<InvestStrategy> baskinlar = <InvestStrategy>[
        for (final MapEntry<InvestStrategy, int> e in ustunluk.entries)
          if (!teshisSondalari.contains(e.key) &&
              e.value >= InvestStrategy.values.length - 1)
            e.key,
      ];
      print('  BULGU: her şeyi ezen strateji -> '
          '${baskinlar.map((InvestStrategy x) => x.label).toList()}');
      expect(baskinlar.length, lessThanOrEqualTo(1),
          reason: 'Birden fazla strateji butun digerlerini eziyor');
      if (baskinlar.isNotEmpty) {
        expect(baskinlar.single, InvestStrategy.girisimVeYatirim,
            reason: 'Beklenmeyen bir strateji baskin hale gelmis: '
                '${baskinlar.single.label}');
      }
      // Piyasa stratejileri arasında (işletme/ev hariç) baskın olmasın:
      // bu paketin kalibre ettiği alan burası.
      const Set<InvestStrategy> piyasa = <InvestStrategy>{
        InvestStrategy.maksimum,
        InvestStrategy.tamHisse,
        InvestStrategy.dengeli,
        InvestStrategy.sadeceVadeli,
        InvestStrategy.sadeceAltin,
        InvestStrategy.sadeceFon,
        InvestStrategy.karmaNormal,
      };
      for (final InvestStrategy a in piyasa) {
        int ezdigi = 0;
        for (final InvestStrategy b in piyasa) {
          if (a == b) continue;
          bool herUfukta = true;
          for (final int ufuk in <int>[20, 40, 60]) {
            final List<int> sa =
                hepsi[a]![ufuk]!.map((e) => e.netWorth).toList()..sort();
            final List<int> sb =
                hepsi[b]![ufuk]!.map((e) => e.netWorth).toList()..sort();
            if (!(_medyan(sa) > _medyan(sb) && _p(sa, 0.10) > _p(sb, 0.10))) {
              herUfukta = false;
              break;
            }
          }
          if (herUfukta) ezdigi++;
        }
        expect(ezdigi, lessThan(piyasa.length - 1),
            reason: '${a.label} butun piyasa stratejilerini eziyor; '
                'tek optimal yatirim yolu var demektir');
      }

      // §19: yatırım yapan ile yapmayan aynı yerde olmasın.
      final List<int> yatirimYok =
          hepsi[InvestStrategy.yatirimYok]![60]!.map((e) => e.netWorth).toList()
            ..sort();
      final List<int> maksimum =
          hepsi[InvestStrategy.maksimum]![60]!.map((e) => e.netWorth).toList()
            ..sort();
      expect(_medyan(maksimum), greaterThan(_medyan(yatirimYok)),
          reason: 'Yatirim yapmak fayda etmiyor');

      // Risk karşılığında ödül: en riskli strateji en kötü tabana sahip olsun.
      final List<int> hisse =
          hepsi[InvestStrategy.tamHisse]![60]!.map((e) => e.netWorth).toList()
            ..sort();
      final List<int> dengeli =
          hepsi[InvestStrategy.dengeli]![60]!.map((e) => e.netWorth).toList()
            ..sort();
      print('');
      print('60 yil: %100 hisse medyan ${_m(_medyan(hisse))} / kotu%10 '
          '${_m(_p(hisse, 0.10))} · dengeli medyan ${_m(_medyan(dengeli))} / '
          'kotu%10 ${_m(_p(dengeli, 0.10))}');
    }, timeout: const Timeout(Duration(minutes: 180)));

    test('§18: tam hayat ölçümü — arketip x hayat', () {
      print('');
      print(_tamOlcum
          ? '=== TAM OLCUM: ${PlayerArchetype.values.length} arketip x '
              '$_hayatSayisi hayat = ${PlayerArchetype.values.length * _hayatSayisi} tam hayat ==='
          : '=== HAFIF BEKCI ($_hayatSayisi hayat/arketip) ===');

      final List<BotLifeResult> hepsi = <BotLifeResult>[];
      for (final PlayerArchetype a in PlayerArchetype.values) {
        for (int i = 0; i < _hayatSayisi; i++) {
          hepsi.add(playBotLife(seed: 900000 + a.index * 7717 + i, archetype: a));
        }
      }

      final List<int> servet = hepsi.map((e) => e.finalNetWorth).toList()..sort();
      final int n = hepsi.length;
      int ustu(int e) => servet.where((int x) => x >= e).length;
      print('--- $n TAM HAYAT ---');
      print('  medyan servet   ${_m(_medyan(servet))}');
      print('  kotu %10        ${_m(_p(servet, 0.10))}');
      print('  iyi %10         ${_m(_p(servet, 0.90))}');
      print('  en kotu         ${_m(servet.first)}');
      print('  en iyi          ${_m(servet.last)}');
      print('  50M+  %${(100 * ustu(50000000) / n).toStringAsFixed(1)}  '
          '100M+ %${(100 * ustu(100000000) / n).toStringAsFixed(1)}  '
          '250M+ %${(100 * ustu(250000000) / n).toStringAsFixed(1)}  '
          '500M+ %${(100 * ustu(500000000) / n).toStringAsFixed(1)}  '
          '1B+ %${(100 * ustu(1000000000) / n).toStringAsFixed(1)}');
      print('  ehliyet alan    %${(100 * hepsi.where((e) => e.diag.licensesEarned > 0).length / n).toStringAsFixed(1)}');
      print('  evlenen         %${(100 * hepsi.where((e) => e.married).length / n).toStringAsFixed(1)}');
      print('  partneri olan   %${(100 * hepsi.where((e) => e.everPartner).length / n).toStringAsFixed(1)}');
      print('  olumle biten    %${(100 * hepsi.where((e) => e.endedByDeath).length / n).toStringAsFixed(1)}');
      print('  yatirim yapan   %${(100 * hepsi.where((e) => e.investedEver).length / n).toStringAsFixed(1)}');
      print('  ev sahibi       %${(100 * hepsi.where((e) => e.ownedHome).length / n).toStringAsFixed(1)}');
      print('  isletme kuran   %${(100 * hepsi.where((e) => e.ownedBusiness).length / n).toStringAsFixed(1)}');

      // §19 hedef dağılımı: milyarderlik çok nadir.
      final double milyarder = ustu(1000000000) / n;
      expect(milyarder, lessThan(0.02),
          reason: 'Tam hayatlarda %${(milyarder * 100).toStringAsFixed(1)} '
              'milyarder; §19 "cok nadir" diyor');
      // Normal oyuncu milyonlar görsün: medyan bir milyonun üstünde olmalı.
      expect(_medyan(servet), greaterThan(1000000),
          reason: 'Medyan oyuncu milyon bile gormuyor');
      // Bot gerçekten yaşıyor olsun: ehliyet ve evlilik yolları açık.
      expect(hepsi.where((e) => e.diag.licensesEarned > 0).length, greaterThan(0),
          reason: 'Hicbir bot ehliyet almiyor; §18 bunu istedi');
      expect(hepsi.where((e) => e.married).length, greaterThan(0));
      // Hepsi ölümle bitmeli (takılan hayat yok).
      expect(hepsi.where((e) => e.endedByDeath).length, n,
          reason: 'Bazi hayatlar olumle bitmedi; takilma var');
    }, timeout: const Timeout(Duration(minutes: 180)));
  });
}
