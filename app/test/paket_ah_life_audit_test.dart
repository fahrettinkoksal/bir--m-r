// Paket AH — tam yaşam ürün denetimi.
//
// **Bu dosya denge değiştirmez.** AD + AE + AF + AG paketlerinden sonra
// oyunun doğumdan ölüme bütün döngüsünü yeniden ölçer ve sayıları basar;
// kararı Faho ile ChatGPT verir.
//
// `product_simulation_test.dart` ile farkı: o dosya 1500 hayatlık
// **dondurulmuş** ürün ölçümüdür ve kendi bekçileri vardır. Bu dosya
// AH'nin sorduğu yeni soruları ekler — işletme yönetimi (fiyat, reklam,
// bakım, personel), yatırımın düşüş kademeleri, işsiz geçen yıl, sağlık
// ve hukuk sayıları, servet basamakları ve **baskın hayat yolu** taraması.
//
// Ağır sürüm (§1'in istediği 3000 hayat) `BIR_OMUR_FULL_MEASURE=1` ile
// açılır. Varsayılan hafif sürüm aynı şeyleri ölçer, daha az hayatla:
// tam suite her koşuda yarım saat sürmesin.
// ignore_for_file: avoid_print
library;

import 'dart:io';

import 'package:bir_omur/data/business_catalog.dart';
import 'package:bir_omur/data/event_pool.dart';
import 'package:bir_omur/data/hobby_catalog.dart';
import 'package:bir_omur/data/investment_catalog.dart';
import 'package:bir_omur/data/job_catalog.dart';
import 'package:bir_omur/data/martial_arts_catalog.dart';
import 'package:bir_omur/data/university_catalog.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/player_bot.dart';

bool get _tamOlcum => Platform.environment['BIR_OMUR_FULL_MEASURE'] == '1';

/// §1: arketip başına hayat (tam ölçümde 200) ve ek rastgele hayat (1000).
int get _arketipBasina => _tamOlcum ? 200 : 25;
int get _rastgeleEk => _tamOlcum ? 1000 : 125;

double _oran(List<BotLifeResult> l, bool Function(BotLifeResult) f) =>
    l.isEmpty ? 0 : l.where(f).length / l.length * 100;

double _ort(List<BotLifeResult> l, num Function(BotLifeResult) f) => l.isEmpty
    ? 0
    : l.fold<num>(0, (num t, BotLifeResult r) => t + f(r)) / l.length;

int _p(List<int> l, double q) {
  if (l.isEmpty) return 0;
  final List<int> s = List<int>.from(l)..sort();
  return s[(s.length * q).floor().clamp(0, s.length - 1)];
}

String _m(num v) {
  final double x = v.toDouble();
  if (x.abs() >= 1e9) return '${(x / 1e9).toStringAsFixed(1)}B';
  if (x.abs() >= 1e6) return '${(x / 1e6).toStringAsFixed(1)}M';
  if (x.abs() >= 1e3) return '${(x / 1e3).round()}k';
  return x.round().toString();
}

/// Bir kümenin en sık görülen üyesinin payı: baskınlık taraması (§11).
({String ad, double pay}) _baskin(Map<String, int> sayac) {
  if (sayac.isEmpty) return (ad: '—', pay: 0);
  final int toplam = sayac.values.fold(0, (int a, int b) => a + b);
  final MapEntry<String, int> en = sayac.entries
      .reduce((MapEntry<String, int> a, MapEntry<String, int> b) =>
          a.value >= b.value ? a : b);
  return (ad: en.key, pay: toplam == 0 ? 0 : en.value / toplam);
}

void main() {
  test('Paket AH — 3000 tam hayat ürün denetimi', () {
    final Map<PlayerArchetype, List<BotLifeResult>> gruplar =
        <PlayerArchetype, List<BotLifeResult>>{};
    final List<BotLifeResult> hepsi = <BotLifeResult>[];

    // §1 — 10 arketip x N. Her arketip kendi tohum bandında: aynı
    // hayatlar iki kez oynanmasın.
    for (final PlayerArchetype a in PlayerArchetype.values) {
      final List<BotLifeResult> liste = <BotLifeResult>[];
      final int taban = 2600000 + a.index * 40000;
      for (int i = 0; i < _arketipBasina; i++) {
        liste.add(playBotLife(archetype: a, seed: taban + i));
      }
      gruplar[a] = liste;
      hepsi.addAll(liste);
    }
    // §1 — ek rastgele-geçerli hayatlar, ayrı tohum bandında.
    final List<BotLifeResult> rastgele = <BotLifeResult>[];
    for (int i = 0; i < _rastgeleEk; i++) {
      rastgele.add(
        playBotLife(archetype: PlayerArchetype.randomValid, seed: 3300000 + i),
      );
    }
    hepsi.addAll(rastgele);

    print('');
    print(_tamOlcum
        ? '=== PAKET AH — TAM OLCUM: ${hepsi.length} tam hayat ==='
        : '=== PAKET AH — HAFIF BEKCI: ${hepsi.length} hayat. Tam olcum '
            'icin BIR_OMUR_FULL_MEASURE=1 ===');
    print('10 arketip x $_arketipBasina + $_rastgeleEk rastgele-gecerli');

    // =================================================================
    // §1 — takılan hayat var mı
    // =================================================================
    final List<BotLifeResult> olenler =
        hepsi.where((BotLifeResult r) => r.endedByDeath).toList();
    final List<BotLifeResult> takilanlar =
        hepsi.where((BotLifeResult r) => !r.endedByDeath).toList();
    final Map<String, int> takilma = <String, int>{};
    for (final BotLifeResult r in takilanlar) {
      final String k = r.stuckReason ?? 'bilinmiyor';
      takilma[k] = (takilma[k] ?? 0) + 1;
    }
    final List<int> yaslar =
        olenler.map((BotLifeResult r) => r.deathAge).toList();
    print('');
    print('-- 1) HAYAT DONGUSU --');
    print('olumle biten ${olenler.length}/${hepsi.length} · '
        'takilan ${takilanlar.length} $takilma');
    print('olum yasi: medyan ${_p(yaslar, 0.50)} · '
        'ortalama ${_ort(olenler, (BotLifeResult r) => r.deathAge)
            .toStringAsFixed(1)} · '
        'kotu%10 ${_p(yaslar, 0.10)} · iyi%10 ${_p(yaslar, 0.90)} · '
        'en genc ${yaslar.isEmpty ? 0 : yaslar.reduce(
            (int a, int b) => a < b ? a : b)} · '
        'en yasli ${yaslar.isEmpty ? 0 : yaslar.reduce(
            (int a, int b) => a > b ? a : b)}');

    // =================================================================
    // §3 — ekonomi son durum
    // =================================================================
    final List<int> servet =
        hepsi.map((BotLifeResult r) => r.finalNetWorth).toList();
    int esik(int v) => hepsi.where((BotLifeResult r) => r.finalNetWorth >= v)
        .length;
    print('');
    print('-- 3) EKONOMI --');
    print('olum serveti: medyan ${_m(_p(servet, 0.50))} · '
        'kotu%10 ${_m(_p(servet, 0.10))} · iyi%10 ${_m(_p(servet, 0.90))} · '
        'en yuksek ${_m(servet.reduce((int a, int b) => a > b ? a : b))}');
    print('basamaklar: 50M+ %${(esik(50000000) / hepsi.length * 100)
            .toStringAsFixed(1)} · '
        '100M+ %${(esik(100000000) / hepsi.length * 100).toStringAsFixed(1)} · '
        '250M+ %${(esik(250000000) / hepsi.length * 100).toStringAsFixed(1)} · '
        '500M+ %${(esik(500000000) / hepsi.length * 100).toStringAsFixed(1)} · '
        '1B+ %${(esik(1000000000) / hepsi.length * 100).toStringAsFixed(2)}');
    print('negatif net servet %${_oran(hepsi,
            (BotLifeResult r) => r.finalNetWorth < 0).toStringAsFixed(1)} · '
        'borclu olen %${_oran(hepsi, (BotLifeResult r) => r.finalDebt > 0)
            .toStringAsFixed(1)} · '
        'borc medyani ${_m(_p(hepsi.where((BotLifeResult r) => r.finalDebt > 0)
            .map((BotLifeResult r) => r.finalDebt).toList(), 0.50))}');
    // Servetin nereden geldiği: yalnızca pozitif servetli hayatlarda.
    final List<BotLifeResult> zengin =
        hepsi.where((BotLifeResult r) => r.finalNetWorth > 0).toList();
    print('servet payi (pozitif servetli ${zengin.length} hayatta): '
        'portfoy %${(_ort(zengin, (BotLifeResult r) => r.diag.portfolioShare)
            * 100).toStringAsFixed(1)} · '
        'gayrimenkul %${(_ort(zengin,
                (BotLifeResult r) => r.diag.realEstateShare) * 100)
            .toStringAsFixed(1)} · '
        'miras %${(_ort(zengin, (BotLifeResult r) => r.diag.inheritanceShare)
            * 100).toStringAsFixed(1)}');
    print('isletme kari toplami ${_m(hepsi.fold<int>(0,
            (int t, BotLifeResult r) => t + r.diag.bizProfit))} · '
        'isletme sermayesi ${_m(hepsi.fold<int>(0,
            (int t, BotLifeResult r) => t + r.diag.bizCapital))}');

    // =================================================================
    // §4 — işletme
    // =================================================================
    final List<BotLifeResult> isSahibi =
        hepsi.where((BotLifeResult r) => r.ownedBusiness).toList();
    final Map<String, int> turDagilim = <String, int>{};
    for (final BotLifeResult r in hepsi) {
      for (final String t in r.businessTypes) {
        turDagilim[t] = (turDagilim[t] ?? 0) + 1;
      }
    }
    final int isYili =
        hepsi.fold<int>(0, (int t, BotLifeResult r) => t + r.diag.bizYears);
    final int zararYili =
        hepsi.fold<int>(0, (int t, BotLifeResult r) => t + r.diag.bizLossYears);
    final int reklamYili =
        hepsi.fold<int>(0, (int t, BotLifeResult r) => t + r.diag.bizAdYears);
    final int viralYili = hepsi.fold<int>(
        0, (int t, BotLifeResult r) => t + r.diag.bizViralYears);
    print('');
    print('-- 4) ISLETME --');
    print('isletme acan %${_oran(hepsi, (BotLifeResult r) => r.ownedBusiness)
            .toStringAsFixed(1)} (${isSahibi.length} hayat) · '
        'toplam isletme-yili $isYili');
    print('acanlarda kapanan %${_oran(isSahibi,
            (BotLifeResult r) => r.diag.bizClosed > 0).toStringAsFixed(1)} · '
        'zarar yili %${isYili == 0 ? 0 : (zararYili / isYili * 100)
            .toStringAsFixed(1)} · '
        'reklamli yil %${isYili == 0 ? 0 : (reklamYili / isYili * 100)
            .toStringAsFixed(1)} · '
        'viral yil $viralYili');
    print('bot eylemleri (isletmesi olan hayat basina): '
        'ilgilen ${_ort(isSahibi, (BotLifeResult r) => r.diag.bizTend)
            .toStringAsFixed(1)} · '
        'fiyat ${_ort(isSahibi, (BotLifeResult r) => r.diag.bizPriceChanges)
            .toStringAsFixed(1)} · '
        'reklam ${_ort(isSahibi, (BotLifeResult r) => r.diag.bizAdSet)
            .toStringAsFixed(1)} · '
        'bakim ${_ort(isSahibi, (BotLifeResult r) => r.diag.bizMaintain)
            .toStringAsFixed(1)} · '
        'personel ${_ort(isSahibi, (BotLifeResult r) => r.diag.bizStaff)
            .toStringAsFixed(1)}');
    print('fiyat degistiren %${_oran(isSahibi,
            (BotLifeResult r) => r.diag.bizPriceChanges > 0)
            .toStringAsFixed(1)} · '
        'reklam veren %${_oran(isSahibi,
            (BotLifeResult r) => r.diag.bizAdSet > 0).toStringAsFixed(1)} · '
        'bakim yapan %${_oran(isSahibi,
            (BotLifeResult r) => r.diag.bizMaintain > 0).toStringAsFixed(1)} · '
        'personele dokunan %${_oran(isSahibi,
            (BotLifeResult r) => r.diag.bizStaff > 0).toStringAsFixed(1)}');
    final List<int> isKari =
        isSahibi.map((BotLifeResult r) => r.diag.bizProfit).toList();
    print('isletme kari: medyan ${_m(_p(isKari, 0.50))} · '
        'kotu%10 ${_m(_p(isKari, 0.10))} · iyi%10 ${_m(_p(isKari, 0.90))} · '
        'isten servet yapan (kar > 10M) %${_oran(isSahibi,
            (BotLifeResult r) => r.diag.bizProfit > 10000000)
            .toStringAsFixed(1)}');
    final List<MapEntry<String, int>> turSirali = turDagilim.entries.toList()
      ..sort((MapEntry<String, int> a, MapEntry<String, int> b) =>
          b.value.compareTo(a.value));
    print('tur dagilimi: ${turSirali.map(
        (MapEntry<String, int> e) => '${e.key.replaceFirst('is_', '')} '
            '${e.value}').join(', ')}');

    // =================================================================
    // §5 — yatırım
    // =================================================================
    final List<BotLifeResult> yatirimci =
        hepsi.where((BotLifeResult r) => r.investedEver).toList();
    print('');
    print('-- 5) YATIRIM --');
    print('yatirim yapan %${_oran(hepsi,
            (BotLifeResult r) => r.investedEver).toStringAsFixed(1)} '
        '(${yatirimci.length} hayat) · '
        'ortalama alim ${_ort(yatirimci,
            (BotLifeResult r) => r.diag.investBuys).toStringAsFixed(1)} · '
        'ortalama kendi satisi ${_ort(yatirimci,
            (BotLifeResult r) => r.diag.investSells).toStringAsFixed(1)}');
    print('tek varlikta tek yilda dusus goren: '
        '>=%20 ${_oran(yatirimci, (BotLifeResult r) => r.diag.drop20 > 0)
            .toStringAsFixed(1)}% · '
        '>=%30 ${_oran(yatirimci, (BotLifeResult r) => r.diag.drop30 > 0)
            .toStringAsFixed(1)}% · '
        '>=%40 ${_oran(yatirimci, (BotLifeResult r) => r.diag.drop40 > 0)
            .toStringAsFixed(1)}%');
    // **Not:** bu ölçü satışı da içeriyor. Portföyü bilerek bozduran ya
    // da oyunun zorunlu sattırdığı hayatta "zirveden düşüş" %100'e
    // kadar çıkar; saf piyasa hareketi yukarıdaki varlık bazlı düşüş.
    print('portfoy zirveden dusus (satis dahil): medyan %${(_p(yatirimci
            .map((BotLifeResult r) => (r.diag.worstDrawdown * 100).round())
            .toList(), 0.50))} · '
        'iyi%10 %${_p(yatirimci.map((BotLifeResult r) =>
            (r.diag.worstDrawdown * 100).round()).toList(), 0.90)}');
    print('skandal/regulator goren %${_oran(yatirimci,
            (BotLifeResult r) => r.diag.sawScandal).toStringAsFixed(1)} · '
        'konkordato/kayyum/kapanma goren %${_oran(yatirimci,
            (BotLifeResult r) => r.diag.sawCompanyFailure)
            .toStringAsFixed(1)}');
    print('zorunlu satis yasayan %${_oran(yatirimci,
            (BotLifeResult r) => r.diag.forcedSales > 0).toStringAsFixed(1)} · '
        'yatirimi zararla biten %${_oran(yatirimci,
            (BotLifeResult r) => r.diag.investEndedInLoss)
            .toStringAsFixed(1)}');
    final Set<String> gorulenYatirim = <String>{};
    final Set<String> gorulenOlayTuru = <String>{};
    for (final BotLifeResult r in hepsi) {
      gorulenYatirim.addAll(r.investmentTypes);
      gorulenOlayTuru.addAll(r.diag.marketIncidentKinds);
    }
    print('yatirim turu ${gorulenYatirim.length}/${kInvestmentTypes.length} · '
        'gorulen piyasa olayi turu: ${gorulenOlayTuru.join(', ')}');

    // =================================================================
    // §6 — kariyer
    // =================================================================
    final Set<String> gorulenIs = <String>{};
    final Map<String, int> isSayac = <String, int>{};
    for (final BotLifeResult r in hepsi) {
      for (final String id in r.jobIds) {
        gorulenIs.add(id);
        isSayac[id] = (isSayac[id] ?? 0) + 1;
      }
    }
    final Set<String> hicGirilmeyenIs = kJobCatalog
        .map((JobType j) => j.id)
        .where((String id) => !gorulenIs.contains(id))
        .toSet();
    print('');
    print('-- 6) KARIYER --');
    print('calisan %${_oran(hepsi, (BotLifeResult r) => r.everEmployed)
            .toStringAsFixed(1)} · '
        'emekli %${_oran(hepsi, (BotLifeResult r) => r.retired)
            .toStringAsFixed(1)} · '
        'ortalama calisilan yil ${_ort(hepsi,
            (BotLifeResult r) => r.diag.employedYears).toStringAsFixed(1)} · '
        'ortalama issiz yetiskin yil ${_ort(hepsi,
            (BotLifeResult r) => r.diag.unemployedAdultYears)
            .toStringAsFixed(1)}');
    print('ortalama farkli meslek ${_ort(hepsi,
            (BotLifeResult r) => r.jobIds.length).toStringAsFixed(2)} · '
        'ortalama is degisimi ${_ort(hepsi,
            (BotLifeResult r) => r.jobChanges).toStringAsFixed(2)} · '
        'meslek itibari ${_ort(hepsi,
            (BotLifeResult r) => r.masteryReputation).toStringAsFixed(1)}/100');
    print('meslek coverage ${gorulenIs.length}/${kJobCatalog.length} · '
        'hic girilmeyen (${hicGirilmeyenIs.length}): '
        '${hicGirilmeyenIs.join(', ')}');
    final List<BotLifeResult> maasli = hepsi
        .where((BotLifeResult r) => r.everEmployed && !r.ownedBusiness)
        .toList();
    final List<BotLifeResult> girisimci = hepsi
        .where((BotLifeResult r) => r.ownedBusiness)
        .toList();
    print('maasli kariyer (${maasli.length}): servet medyani ${_m(_p(maasli
            .map((BotLifeResult r) => r.finalNetWorth).toList(), 0.50))} · '
        'isletmeli (${girisimci.length}): ${_m(_p(girisimci
            .map((BotLifeResult r) => r.finalNetWorth).toList(), 0.50))}');

    // =================================================================
    // §7 — ilişki
    // =================================================================
    print('');
    print('-- 7) ILISKI --');
    print('partneri olan %${_oran(hepsi, (BotLifeResult r) => r.everPartner)
            .toStringAsFixed(1)} · '
        'evlenen %${_oran(hepsi, (BotLifeResult r) => r.married)
            .toStringAsFixed(1)} · '
        'bosanan %${_oran(hepsi, (BotLifeResult r) => r.divorced)
            .toStringAsFixed(1)} · '
        'dul kalan %${_oran(hepsi,
            (BotLifeResult r) => r.diag.separationKind == 'dulluk')
            .toStringAsFixed(1)} · '
        'tekrar evlenen %${_oran(hepsi, (BotLifeResult r) => r.remarried)
            .toStringAsFixed(1)}');
    print('cocuklu %${_oran(hepsi, (BotLifeResult r) => r.childCount > 0)
            .toStringAsFixed(1)} · '
        'ortalama cocuk ${_ort(hepsi, (BotLifeResult r) => r.childCount)
            .toStringAsFixed(2)} · '
        'torun goren %${_oran(hepsi, (BotLifeResult r) => r.sawGrandchild)
            .toStringAsFixed(1)}');
    print('arkadasi olan %${_oran(hepsi,
            (BotLifeResult r) => r.friendCount > 0).toStringAsFixed(1)} · '
        'ortalama arkadas ${_ort(hepsi,
            (BotLifeResult r) => r.friendCount).toStringAsFixed(2)} · '
        'yakin arkadas ${_ort(hepsi,
            (BotLifeResult r) => r.closeFriendCount).toStringAsFixed(2)} · '
        'kuslik %${_oran(hepsi, (BotLifeResult r) => r.estranged)
            .toStringAsFixed(1)}');
    // Yakın arkadaşlık hunisi: hangi basamakta tıkanıyor?
    final Map<String, int> cfEngel = <String, int>{};
    for (final BotLifeResult r in hepsi) {
      final String k = r.diag.closeFriendBlockReason;
      if (k.isEmpty) continue;
      // Yakınlık sayısı gerekçenin içinde geçiyor; basamağı sabitlemek
      // için sayıyı atıyoruz.
      final String kisa = k.startsWith('Yakınlık') ? 'yakinlik yetmedi' : k;
      cfEngel[kisa] = (cfEngel[kisa] ?? 0) + 1;
    }
    print('yakin arkadaslik hunisi: tanisikligi olan %${_oran(hepsi,
            (BotLifeResult r) => r.diag.sawAcquaintance)
            .toStringAsFixed(1)} · '
        'en yuksek tanisiklik yakinligi medyan ${_p(hepsi.where(
            (BotLifeResult r) => r.diag.sawAcquaintance)
            .map((BotLifeResult r) => r.diag.bestAcquaintanceBond).toList(),
            0.50)} · '
        'sarti saglayan %${_oran(hepsi,
            (BotLifeResult r) => r.diag.closeFriendEligibleYears > 0)
            .toStringAsFixed(1)} · '
        'teklif eden %${_oran(hepsi,
            (BotLifeResult r) => r.diag.closeFriendAttempts > 0)
            .toStringAsFixed(1)} · '
        'kabul alan %${_oran(hepsi,
            (BotLifeResult r) => r.diag.closeFriendAccepted > 0)
            .toStringAsFixed(1)}');
    print('  engel gerekceleri: $cfEngel');

    // =================================================================
    // §8 — sağlık
    // =================================================================
    print('');
    print('-- 8) SAGLIK --');
    print('olum yasi medyan ${_p(yaslar, 0.50)} · '
        'kronik yasayan %${_oran(hepsi, (BotLifeResult r) => r.chronic)
            .toStringAsFixed(1)} · '
        'ortalama kronik tani ${_ort(hepsi,
            (BotLifeResult r) => r.diag.chronicCount).toStringAsFixed(2)}');
    print('check-up yapan %${_oran(hepsi, (BotLifeResult r) => r.checkup)
            .toStringAsFixed(1)} · '
        'spor yapan %${_oran(hepsi, (BotLifeResult r) => r.didSport)
            .toStringAsFixed(1)} · '
        'saglik krizi yasayan %${_oran(hepsi,
            (BotLifeResult r) => r.diag.healthCrises > 0)
            .toStringAsFixed(1)} · '
        'ortalama kriz ${_ort(hepsi,
            (BotLifeResult r) => r.diag.healthCrises).toStringAsFixed(2)}');
    print('olum aninda saglik medyani ${_p(hepsi
        .map((BotLifeResult r) => r.finalHealth).toList(), 0.50)}');

    // =================================================================
    // §9 — suç / hukuk
    // =================================================================
    final List<BotLifeResult> suclu =
        hepsi.where((BotLifeResult r) => r.diag.caseCount > 0).toList();
    print('');
    print('-- 9) SUC / HUKUK --');
    print('dosyasi olan %${_oran(hepsi,
            (BotLifeResult r) => r.diag.caseCount > 0).toStringAsFixed(1)} · '
        'sabikali %${_oran(hepsi, (BotLifeResult r) => r.hasRecord)
            .toStringAsFixed(1)} · '
        'sorusturma gecirilen %${_oran(hepsi,
            (BotLifeResult r) => r.diag.investigations > 0)
            .toStringAsFixed(1)}');
    print('davaya giden %${_oran(hepsi,
            (BotLifeResult r) => r.diag.trials > 0).toStringAsFixed(1)} · '
        'mahkum olan %${_oran(hepsi,
            (BotLifeResult r) => r.diag.convictions > 0).toStringAsFixed(1)} · '
        'hapis yatan %${_oran(hepsi, (BotLifeResult r) => r.imprisoned)
            .toStringAsFixed(1)} · '
        'denetimli %${_oran(hepsi,
            (BotLifeResult r) => r.diag.probationYears > 0)
            .toStringAsFixed(1)}');
    print('birden fazla dosyasi olan (yeniden suc) %${_oran(suclu,
            (BotLifeResult r) => r.diag.caseCount > 1).toStringAsFixed(1)} '
        '(dosyasi olanlarin icinde) · '
        'ortalama hapis yili ${_ort(suclu,
            (BotLifeResult r) => r.diag.prisonYears).toStringAsFixed(2)}');

    // =================================================================
    // §10 — içerik kapsamı
    // =================================================================
    final Set<String> gorulenOlay = <String>{};
    final Set<String> gorulenBolum = <String>{};
    final Set<String> gorulenIsletme = <String>{};
    final Set<String> gorulenHobi = <String>{};
    final Set<String> gorulenSanat = <String>{};
    for (final BotLifeResult r in hepsi) {
      gorulenOlay.addAll(r.seenEvents);
      if (r.programId != null) gorulenBolum.add(r.programId!);
      gorulenIsletme.addAll(r.businessTypes);
      gorulenHobi.addAll(r.hobbies);
      gorulenSanat.addAll(r.martialArts);
    }
    final Set<String> hicGorulmeyenOlay = kEventPool
        .map((GameEvent e) => e.id)
        .where((String id) => !gorulenOlay.contains(id))
        .toSet();
    final Set<String> hicAcilmayanIsletme = kBusinessCatalog
        .map((BusinessType t) => t.id)
        .where((String id) => !gorulenIsletme.contains(id))
        .toSet();
    final Set<String> hicOkunmayanBolum = kUniversityPrograms
        .map((UniversityProgram p) => p.id)
        .where((String id) => !gorulenBolum.contains(id))
        .toSet();
    print('');
    print('-- 10) ICERIK KAPSAMI --');
    print('olay ${gorulenOlay.length}/${kEventPool.length} '
        '(%${(gorulenOlay.length / kEventPool.length * 100)
            .toStringAsFixed(1)}) · '
        'meslek ${gorulenIs.length}/${kJobCatalog.length} · '
        'isletme ${gorulenIsletme.length}/${kBusinessCatalog.length} · '
        'bolum ${gorulenBolum.length}/${kUniversityPrograms.length} · '
        'hobi ${gorulenHobi.length}/${HobbyKind.values.length} · '
        'dovus ${gorulenSanat.length}/${MartialArt.values.length}');
    print('');
    print('-- 12) HIC ERISILMEYEN ICERIK --');
    print('olay (${hicGorulmeyenOlay.length}): '
        '${hicGorulmeyenOlay.join(', ')}');
    print('meslek (${hicGirilmeyenIs.length}): ${hicGirilmeyenIs.join(', ')}');
    print('isletme (${hicAcilmayanIsletme.length}): '
        '${hicAcilmayanIsletme.join(', ')}');
    print('bolum (${hicOkunmayanBolum.length}): '
        '${hicOkunmayanBolum.join(', ')}');

    // =================================================================
    // §11 — aşırı davranış / baskın hayat yolu
    // =================================================================
    final Map<String, int> yatirimSayac = <String, int>{};
    for (final BotLifeResult r in hepsi) {
      for (final String t in r.investmentTypes) {
        yatirimSayac[t] = (yatirimSayac[t] ?? 0) + 1;
      }
    }
    final ({String ad, double pay}) enSikIs = _baskin(turDagilim);
    final ({String ad, double pay}) enSikYatirim = _baskin(yatirimSayac);
    final ({String ad, double pay}) enSikMeslek = _baskin(isSayac);
    print('');
    print('-- 11) BASKINLIK TARAMASI --');
    print('en sik isletme ${enSikIs.ad} (secimlerin '
        '%${(enSikIs.pay * 100).toStringAsFixed(1)}\'i) · '
        'en sik yatirim ${enSikYatirim.ad} '
        '(%${(enSikYatirim.pay * 100).toStringAsFixed(1)}) · '
        'en sik meslek ${enSikMeslek.ad} '
        '(%${(enSikMeslek.pay * 100).toStringAsFixed(1)})');
    // "Aynı optimal hayat" oluşuyor mu: en zengin %10 ne yapmış?
    final List<BotLifeResult> tepe = List<BotLifeResult>.from(hepsi)
      ..sort((BotLifeResult a, BotLifeResult b) =>
          b.finalNetWorth.compareTo(a.finalNetWorth));
    final List<BotLifeResult> ilkYuzde10 =
        tepe.take((hepsi.length * 0.1).round()).toList();
    print('en zengin %10 profili: universite '
        '%${_oran(ilkYuzde10, (BotLifeResult r) => r.wentToUniversity)
            .toStringAsFixed(0)} · '
        'isletme %${_oran(ilkYuzde10, (BotLifeResult r) => r.ownedBusiness)
            .toStringAsFixed(0)} · '
        'yatirim %${_oran(ilkYuzde10, (BotLifeResult r) => r.investedEver)
            .toStringAsFixed(0)} · '
        'ev %${_oran(ilkYuzde10, (BotLifeResult r) => r.ownedHome)
            .toStringAsFixed(0)} · '
        'kiraya veren %${_oran(ilkYuzde10, (BotLifeResult r) => r.letProperty)
            .toStringAsFixed(0)} · '
        'evli %${_oran(ilkYuzde10, (BotLifeResult r) => r.married)
            .toStringAsFixed(0)}');
    print('butun hayatlarda ayni olculer: universite '
        '%${_oran(hepsi, (BotLifeResult r) => r.wentToUniversity)
            .toStringAsFixed(0)} · '
        'isletme %${_oran(hepsi, (BotLifeResult r) => r.ownedBusiness)
            .toStringAsFixed(0)} · '
        'yatirim %${_oran(hepsi, (BotLifeResult r) => r.investedEver)
            .toStringAsFixed(0)} · '
        'ev %${_oran(hepsi, (BotLifeResult r) => r.ownedHome)
            .toStringAsFixed(0)} · '
        'kiraya veren %${_oran(hepsi, (BotLifeResult r) => r.letProperty)
            .toStringAsFixed(0)} · '
        'evli %${_oran(hepsi, (BotLifeResult r) => r.married)
            .toStringAsFixed(0)}');

    // ---- Arketip tablosu --------------------------------------------
    print('');
    print('-- ARKETIP BAZLI --');
    print('arketip      | omur | takil | uni | calis | ev  | is  | evli '
        '| sabika | servet');
    print('-' * 90);
    for (final PlayerArchetype a in PlayerArchetype.values) {
      final List<BotLifeResult> g = gruplar[a]!;
      final List<BotLifeResult> go =
          g.where((BotLifeResult r) => r.endedByDeath).toList();
      print('${a.name.padRight(12)} | '
          '${_ort(go, (BotLifeResult r) => r.deathAge).toStringAsFixed(0)
              .padLeft(4)} | '
          '${(g.length - go.length).toString().padLeft(5)} | '
          '${_oran(g, (BotLifeResult r) => r.wentToUniversity)
              .toStringAsFixed(0).padLeft(3)} | '
          '${_oran(g, (BotLifeResult r) => r.everEmployed).toStringAsFixed(0)
              .padLeft(5)} | '
          '${_oran(g, (BotLifeResult r) => r.ownedHome).toStringAsFixed(0)
              .padLeft(3)} | '
          '${_oran(g, (BotLifeResult r) => r.ownedBusiness)
              .toStringAsFixed(0).padLeft(3)} | '
          '${_oran(g, (BotLifeResult r) => r.married).toStringAsFixed(0)
              .padLeft(4)} | '
          '${_oran(g, (BotLifeResult r) => r.hasRecord).toStringAsFixed(0)
              .padLeft(6)} | '
          '${_m(_p(g.map((BotLifeResult r) => r.finalNetWorth).toList(), 0.50))
              .padLeft(6)}');
    }

    // =================================================================
    // Bekçiler — ölçümün kendisi anlamlı mı?
    //
    // Bu tur **teşhis**; denge bekçisi koymuyoruz. Buradakiler yalnızca
    // "ölçüm hayatı temsil ediyor mu" sorusunu koruyor.
    // =================================================================
    expect(takilanlar.length, 0,
        reason: '§1: takılan hayat olmamalı. Takılma sebepleri: $takilma');
    expect(_p(yaslar, 0.50), greaterThan(40),
        reason: 'Botlar erken ölüyorsa ölçüm hayatı temsil etmiyor.');
    // §2: bot AE'nin işletme ekranlarını gerçekten kullanıyor mu?
    expect(isSahibi.where((BotLifeResult r) => r.diag.bizPriceChanges > 0)
        .isNotEmpty, isTrue,
        reason: '§2: bot fiyat ekranını hiç açmıyor.');
    expect(isSahibi.where((BotLifeResult r) => r.diag.bizAdSet > 0).isNotEmpty,
        isTrue, reason: '§2: bot reklam ekranını hiç açmıyor.');
    expect(isSahibi.where((BotLifeResult r) => r.diag.bizMaintain > 0)
        .isNotEmpty, isTrue, reason: '§2: bot bakım ekranını hiç açmıyor.');
    expect(isSahibi.where((BotLifeResult r) => r.diag.bizStaff > 0).isNotEmpty,
        isTrue, reason: '§2: bot personel ekranını hiç açmıyor.');
    expect(yatirimci.where((BotLifeResult r) => r.diag.investSells > 0)
        .isNotEmpty, isTrue, reason: '§2: bot yatırım satmıyor.');
  }, timeout: const Timeout(Duration(minutes: 90)));
}
