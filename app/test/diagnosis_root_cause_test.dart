/// **Teşhis turu: ürün simülasyonunun kök neden analizi.**
///
/// Son PlayerBot ölçümü altı aşırı sayı üretti:
///
/// 1. ölüm anı medyan net servet ~134M ₺
/// 2. partneri olan %94,9 iken evlenen yalnızca %22
/// 3. tekrar evlenen %0
/// 4. hiç girilmeyen 5 meslek
/// 5. hiç kurulmayan 4 işletme türü
/// 6. hiç görülmeyen 12 olay
///
/// Bu dosya o sayıları **düzeltmeye çalışmaz**. Dengeye hiç dokunmaz:
/// tek bir oyun sabiti, şart, fiyat, getiri ya da eşik değişmiyor.
/// Yaptığı tek şey ölçmek — "bu sayı nereden geliyor?"
///
/// **Ürün kararını Faho ve ChatGPT verir.** Buradaki her bulgu, altında
/// "oyun sorunu mu, bot sorunu mu" ayrımıyla raporlanır; hiçbiri karar
/// değildir.
///
/// **Bu testler iddia yerine rapor üretir.** Birkaç yerde `expect` var,
/// ama hepsi *teşhisin kendi doğruluğunu* koruyan iddialar (örneğin
/// servet bileşenlerinin toplamı oyunun net servet hesabıyla tutmalı).
/// Hiçbiri oyun dengesine dair bir eşik değil: denge eşiği koymak bu
/// turda yasak.
///
/// Ölçüm bütünlüğü:
/// * `debugSetState` ile para/stat/ilişki/ev/iş **verilmiyor**. Bütün
///   hayatlar üretim kurallarından geçiyor.
/// * Teşhis botun rastgele akışına dokunmuyor: bu dosya eklendikten
///   sonra `product_simulation_test.dart` çıktısı **satır satır aynı**
///   kaldı (yalnızca geçen süre satırı değişti). Ölçüm eskiyle
///   karşılaştırılabilir.
/// * Karşılaştırmalı senaryolarda (D bölümü) yalnızca **botun
///   tercihleri** kapanıyor (`BotOverrides`); oyunun sayıları değişmiyor.
library;

// Teşhis raporu konsola basılır: bu dosyanın ürünü rapordur.
// ignore_for_file: avoid_print

import 'dart:math';

import 'package:bir_omur/data/business_catalog.dart';
import 'package:bir_omur/data/event_pool.dart';
import 'package:bir_omur/data/finger_catalog.dart';
import 'package:bir_omur/domain/interaction/finger.dart';
import 'package:bir_omur/data/job_catalog.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/data/item_catalog.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/interaction/marriage_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/player_bot.dart';

// =====================================================================
// Korpus
// =====================================================================

/// Arketip başına hayat sayısı. 10 arketip × 100 = 1000 hayat.
const int kArchetypeLives = 100;

/// Teşhis tohum tabanı. Ürün simülasyonundan **ayrı** bir tabandan
/// başlıyor ki iki ölçüm aynı hayatları tekrar etmesin.
const int kSeedBase = 770000;

/// D bölümü: senaryo başına hayat sayısı (5 senaryo × 200 = 1000 hayat).
const int kScenarioLives = 200;

/// L bölümü: hedefli ayrılık sonrası hayat sayısı.
const int kSeparationLives = 500;

/// Paylaşılan korpus: bir kez koşulur, bütün bölümler aynı hayatları
/// okur. Böylece A'daki servet ile G'deki evlilik aynı hayatlardan
/// gelir ve bulgular birbiriyle tutarlı olur.
final List<BotLifeResult> _korpus = <BotLifeResult>[];

void main() {
  setUpAll(() {
    final Stopwatch sure = Stopwatch()..start();
    for (final PlayerArchetype tip in PlayerArchetype.values) {
      for (int i = 0; i < kArchetypeLives; i++) {
        _korpus.add(playBotLife(
          archetype: tip,
          // Arketip başına **farklı** tohum ailesi: on arketip aynı
          // hayatı on kez yaşamasın.
          seed: kSeedBase + tip.index * 10007 + i,
          scanEventEligibility: true,
        ));
      }
    }
    sure.stop();
    print('');
    print('=' * 70);
    print('TESHIS KORPUSU: ${_korpus.length} hayat, '
        '${(sure.elapsedMilliseconds / 1000).toStringAsFixed(1)} sn');
    final int olen = _korpus.where((BotLifeResult r) => r.endedByDeath).length;
    final int takilan =
        _korpus.where((BotLifeResult r) => r.stuckReason != null).length;
    print('olumle biten $olen/${_korpus.length} · takilan $takilan');
    print('=' * 70);
  });

  group('Teshis', () {
    test('A — olum ani servet bilesenleri', _bolumA);
    test('B — yasa gore servet egrisi', _bolumB);
    test('C — arketip bazli servet', _bolumC);
    test('E — yatirim getirisi mi gider korumasi mi', _bolumE);
    test('F — miras etkisi', _bolumF);
    test('G — evlilik hunisi', _bolumG);
    test('H — evlilik blocker raporu', _bolumH);
    test('G-EK — sevgili kapisinin mekanigi', _bolumGEk);
    test('I — family arketipi ozel inceleme', _bolumI);
    test('J/K — tekrar evlenme hunisi ve engelleri', _bolumJK);
    test('M — hic girilmeyen meslekler', _bolumM);
    test('N — hic kurulmayan isletmeler', _bolumN);
    test('O — hic gorulmeyen olaylar', _bolumO);
    test('P/Q — botun kendi mekanikligi', _bolumPQ);
  });

  test('D — karsilastirmali servet senaryolari', _bolumD);
  test('L — hedefli ayrilik sonrasi hayatlar', _bolumL);
}

// =====================================================================
// A — servet 134M nereden geliyor?
// =====================================================================

void _bolumA() {
  final List<BotLifeResult> olenler = _olenler();
  _baslik('A — OLUM ANI SERVET BILESENLERI (${olenler.length} hayat)');

  // Teşhisin kendi doğruluğu: bileşenlerin toplamı oyunun net servet
  // hesabıyla **tutmak zorunda**. Tutmuyorsa çift sayım ya da eksik
  // kalem var ve aşağıdaki bütün oranlar yanlış olur.
  for (final BotLifeResult r in olenler) {
    expect(
      r.diag.componentSum,
      r.diag.netWorth,
      reason: 'Servet bileseni toplami oyunun NetWorth hesabiyla tutmuyor '
          '(${r.archetype.name} tohum ${r.seed}). Cift sayim ya da eksik '
          'kalem var.',
    );
  }

  print('Kural: netWorth = cuzdan + portfoy + gayrimenkul + arac + diger '
      '- borc');
  print('Isletme bu toplamin DISINDA: oyunun net servet hesabi isletmeyi');
  print('varlik saymiyor. Ayri raporlanir (asagida).');
  print('');
  print('Bilesen             medyan        ort.      servetteki pay');
  _bilesenSatiri('cuzdan', olenler, (BotDiag d) => d.wallet);
  _bilesenSatiri('portfoy', olenler, (BotDiag d) => d.portfolio);
  _bilesenSatiri('gayrimenkul', olenler, (BotDiag d) => d.realEstate);
  _bilesenSatiri('arac', olenler, (BotDiag d) => d.vehicles);
  _bilesenSatiri('diger esya', olenler, (BotDiag d) => d.otherAssets);
  _bilesenSatiri('borc (-)', olenler, (BotDiag d) => d.debt);
  print('');
  print('NET SERVET medyan ${_k(_medyan(
    olenler.map((BotLifeResult r) => r.diag.netWorth).toList(),
  ))}');
  print('');
  print('Isletme (net servetin disinda):');
  print('  konan sermaye medyan '
      '${_k(_medyan(olenler.map((BotLifeResult r) => r.diag.businessInvested).toList()))}'
      ' · toplam kar medyan '
      '${_k(_medyan(olenler.map((BotLifeResult r) => r.diag.businessProfit).toList()))}');
  print('');
  print('Omur boyu akislar (medyan):');
  print('  yaklasik toplam maas   ${_k(_medyan(
    olenler.map((BotLifeResult r) => r.diag.lifetimeSalary).toList(),
  ))}');
  print('  toplanan kira          ${_k(_medyan(
    olenler.map((BotLifeResult r) => r.diag.lifetimeRent).toList(),
  ))}');
  print('  gayrimenkul bakimi     ${_k(_medyan(
    olenler.map((BotLifeResult r) => r.diag.lifetimeMaintenance).toList(),
  ))}');
  print('  isletme kari           ${_k(_medyan(
    olenler.map((BotLifeResult r) => r.diag.businessProfit).toList(),
  ))}');
  print('  mirastan gelen nakit   ${_k(_medyan(
    olenler.map((BotLifeResult r) => r.diag.inheritanceMoney).toList(),
  ))}');
  print('  odenen yasam gideri    ${_k(_medyan(
    olenler.map((BotLifeResult r) => r.diag.lifetimeLivingCostPaid).toList(),
  ))}');
  print('  portfoye konan anapara ${_k(_medyan(
    olenler.map((BotLifeResult r) => r.diag.investedPrincipalEver).toList(),
  ))}');
  print('  gerceklesmemis kar     ${_k(_medyan(
    olenler.map((BotLifeResult r) => r.diag.portfolioUnrealizedAtDeath).toList(),
  ))}');
  print('');
  print('Yorum icin onemli: maas + kira + isletme + miras toplami');
  print('serveti aciklamiyorsa fark BILESIK PORTFOY BUYUMESIDIR.');
}

void _bilesenSatiri(
  String ad,
  List<BotLifeResult> hayatlar,
  int Function(BotDiag) oku,
) {
  final List<int> degerler =
      hayatlar.map((BotLifeResult r) => oku(r.diag)).toList();
  final int toplamServet =
      hayatlar.fold<int>(0, (int t, BotLifeResult r) => t + max(0, r.diag.netWorth));
  final int toplamBilesen = degerler.fold<int>(0, (int t, int v) => t + v);
  final String pay = toplamServet <= 0
      ? '-'
      : '%${(100 * toplamBilesen / toplamServet).toStringAsFixed(1)}';
  print('${ad.padRight(18)} ${_k(_medyan(degerler)).padLeft(12)} '
      '${_k(_ortalama(degerler)).padLeft(12)}   $pay');
}

// =====================================================================
// B — yaşa göre servet eğrisi
// =====================================================================

void _bolumB() {
  _baslik('B — YASA GORE SERVET EGRISI (medyan, o yasa ulasan hayatlar)');
  print('yas   ulasan   medyan net servet   medyan portfoy   x(onceki yas)');
  int oncekiMedyan = 0;
  for (final int yas in kWealthCurveAges) {
    final List<int> servetler = <int>[];
    final List<int> portfoyler = <int>[];
    for (final BotLifeResult r in _korpus) {
      final int? s = r.diag.netWorthAtAge[yas];
      if (s == null) continue;
      servetler.add(s);
      portfoyler.add(r.diag.portfolioAtAge[yas] ?? 0);
    }
    if (servetler.isEmpty) {
      print('${yas.toString().padLeft(3)}        0   (o yasa ulasan yok)');
      continue;
    }
    final int medyan = _medyan(servetler);
    final String kat = oncekiMedyan <= 0
        ? '-'
        : '${(medyan / oncekiMedyan).toStringAsFixed(2)}x';
    print('${yas.toString().padLeft(3)}   '
        '${servetler.length.toString().padLeft(6)}   '
        '${_k(medyan).padLeft(17)}   ${_k(_medyan(portfoyler)).padLeft(14)}   '
        '$kat');
    oncekiMedyan = medyan;
  }
  print('');
  print('Soru: servet belli bir yasta mi patliyor, yoksa her 5 yilda');
  print('benzer katsayiyla mi buyuyor? Sabit katsayi = bilesik buyume,');
  print('tek bir yasta ziplama = sistem kirilmasi.');
}

// =====================================================================
// C — arketip bazlı servet
// =====================================================================

void _bolumC() {
  _baslik('C — ARKETIP BAZLI SERVET (medyan)');
  print('arketip        servet     portfoy    gayrimen.  isletme    '
      'borc     miras    anapara   portfoy x');
  for (final PlayerArchetype tip in PlayerArchetype.values) {
    final List<BotLifeResult> grup = _olenler()
        .where((BotLifeResult r) => r.archetype == tip)
        .toList(growable: false);
    if (grup.isEmpty) continue;
    final List<double> katlar = grup
        .map((BotLifeResult r) => r.diag.portfolioMultiple)
        .where((double x) => x > 0)
        .toList();
    print('${tip.name.padRight(14)} '
        '${_k(_medyan(grup.map((BotLifeResult r) => r.diag.netWorth).toList())).padLeft(9)} '
        '${_k(_medyan(grup.map((BotLifeResult r) => r.diag.portfolio).toList())).padLeft(10)} '
        '${_k(_medyan(grup.map((BotLifeResult r) => r.diag.realEstate).toList())).padLeft(10)} '
        '${_k(_medyan(grup.map((BotLifeResult r) => r.diag.businessInvested).toList())).padLeft(9)} '
        '${_k(_medyan(grup.map((BotLifeResult r) => r.diag.debt).toList())).padLeft(8)} '
        '${_k(_medyan(grup.map((BotLifeResult r) => r.diag.inheritanceMoney).toList())).padLeft(8)} '
        '${_k(_medyan(grup.map((BotLifeResult r) => r.diag.investedPrincipalEver).toList())).padLeft(9)} '
        '${katlar.isEmpty ? '-' : '${_medyanDouble(katlar).toStringAsFixed(1)}x'}');
  }
  print('');
  print('"portfoy x" = olum ani portfoy / elde duran pozisyonlarin');
  print('maliyet bedeli. 1,0 hic buyumedi; 20,0 yirmi katina cikti.');
}

// =====================================================================
// D — karşılaştırmalı servet testi
// =====================================================================

void _bolumD() {
  _baslik('D — KARSILASTIRMALI SERVET SENARYOLARI');
  print('Ayni tohumlar, ayni oyun sayilari. Kapanan tek sey BOTUN');
  print('TERCIHI (BotOverrides). Oyunun fiyatlari, getirileri ve');
  print('sartlari degismiyor. Senaryo basina $kScenarioLives hayat.');
  print('');
  print('NOT: bir politika kapaninca bot daha az eylem yapiyor, bu');
  print('yuzden rastgele akis senaryolar arasinda birebir ayni kalmiyor.');
  print('Niyet zarlari ayni sirada atiliyor (kapatirken bile atiliyor),');
  print('ama karsilastirma yine de ISTATISTIKI: tek hayat degil medyan.');
  print('');

  const Map<String, BotOverrides> senaryolar = <String, BotOverrides>{
    'normal': BotOverrides.none,
    'yatirimsiz': BotOverrides(noInvesting: true),
    'gayrimenkulsuz': BotOverrides(noProperty: true),
    'isletmesiz': BotOverrides(noBusiness: true),
    'yatirim+evsiz': BotOverrides(noInvesting: true, noProperty: true),
  };

  // Arketipleri dolasarak tohum dagitiyoruz: tek arketibin servet
  // profili senaryoyu yanlis yonlendirmesin.
  final List<(PlayerArchetype, int)> plan = <(PlayerArchetype, int)>[];
  for (int i = 0; i < kScenarioLives; i++) {
    final PlayerArchetype tip =
        PlayerArchetype.values[i % PlayerArchetype.values.length];
    plan.add((tip, 880000 + i * 13));
  }

  print('senaryo          medyan servet   medyan portfoy   medyan gayrimen.'
      '   ev sahibi   yatirim yapan');
  final Map<String, int> medyanlar = <String, int>{};
  senaryolar.forEach((String ad, BotOverrides kisit) {
    final List<BotLifeResult> sonuclar = <BotLifeResult>[];
    for (final (PlayerArchetype tip, int tohum) in plan) {
      sonuclar.add(playBotLife(
        archetype: tip,
        seed: tohum,
        overrides: kisit,
      ));
    }
    final List<BotLifeResult> olen =
        sonuclar.where((BotLifeResult r) => r.endedByDeath).toList();
    final int medyan =
        _medyan(olen.map((BotLifeResult r) => r.diag.netWorth).toList());
    medyanlar[ad] = medyan;
    final int evli = olen.where((BotLifeResult r) => r.ownedHome).length;
    final int yat = olen.where((BotLifeResult r) => r.investedEver).length;
    print('${ad.padRight(16)} ${_k(medyan).padLeft(13)}   '
        '${_k(_medyan(olen.map((BotLifeResult r) => r.diag.portfolio).toList())).padLeft(14)}   '
        '${_k(_medyan(olen.map((BotLifeResult r) => r.diag.realEstate).toList())).padLeft(16)}   '
        '${_yuzde(evli, olen.length).padLeft(9)}   '
        '${_yuzde(yat, olen.length).padLeft(13)}');
  });

  print('');
  final int normal = medyanlar['normal'] ?? 0;
  if (normal > 0) {
    print('Normale gore (medyan servetin kac katina dusuyor):');
    medyanlar.forEach((String ad, int v) {
      if (ad == 'normal') return;
      print('  ${ad.padRight(16)} ${(v / normal).toStringAsFixed(3)}x  '
          '(${_k(v)} / ${_k(normal)})');
    });
  }
  print('');
  print('Bu bir TESHIS. En buyuk dususu yapan sistem, serveti en cok');
  print('buyuten sistemdir. Hangi sayinin degisecegine Faho + ChatGPT');
  print('karar verir.');

  // Senaryoların gerçekten kapandığını doğrula: teşhisin kendi
  // doğruluğu. Kapanmadıysa yukarıdaki karşılaştırma anlamsız olurdu.
  final List<BotLifeResult> yatirimsiz = <BotLifeResult>[
    for (final (PlayerArchetype tip, int tohum) in plan.take(40))
      playBotLife(
        archetype: tip,
        seed: tohum,
        overrides: const BotOverrides(noInvesting: true),
      ),
  ];
  expect(
    yatirimsiz.every((BotLifeResult r) => r.diag.investBuys == 0),
    isTrue,
    reason: 'noInvesting senaryosunda bot hala yatirim aliyor; '
        'karsilastirma anlamsiz olurdu.',
  );
  final List<BotLifeResult> evsiz = <BotLifeResult>[
    for (final (PlayerArchetype tip, int tohum) in plan.take(40))
      playBotLife(
        archetype: tip,
        seed: tohum,
        overrides: const BotOverrides(noProperty: true),
      ),
  ];
  // Ev satın alma **niyeti** kapanıyor; olay ya da miras yoluyla gelen
  // konut hâlâ mümkün, o yüzden "hiç ev yok" iddia edilmiyor. İddia
  // edilen: bot artık kendi kararıyla ev almıyor.
  print('');
  print('Dogrulama: noInvesting senaryosunda 40/40 hayatta hic yatirim');
  print('alimi yok. noProperty senaryosunda ev sahibi orani '
      '${_yuzde(evsiz.where((BotLifeResult r) => r.ownedHome).length, evsiz.length)}'
      ' (kalanlar miras/olay yoluyla).');
}

// =====================================================================
// E — yatırım sorunu mu, gider sorunu mu?
// =====================================================================

void _bolumE() {
  final List<BotLifeResult> olenler = _olenler();
  _baslik('E — YATIRIM GETIRISI MI, GIDERDEN KORUNMA MI?');

  final List<BotLifeResult> yatiranlar = olenler
      .where((BotLifeResult r) => r.diag.investedPrincipalEver > 0)
      .toList(growable: false);

  print('Yatirim yapan ${yatiranlar.length}/${olenler.length} hayat.');
  print('');
  print('Portfoy buyumesi (yatirim yapanlarda, medyan):');
  print('  omur boyu konan anapara       ${_k(_medyan(
    yatiranlar.map((BotLifeResult r) => r.diag.investedPrincipalEver).toList(),
  ))}');
  print('  olum ani portfoy degeri       ${_k(_medyan(
    yatiranlar.map((BotLifeResult r) => r.diag.portfolio).toList(),
  ))}');
  print('  elde duran pozisyon maliyeti  ${_k(_medyan(
    yatiranlar.map((BotLifeResult r) => r.diag.portfolioInvestedAtDeath).toList(),
  ))}');
  print('  gerceklesmemis kar            ${_k(_medyan(
    yatiranlar.map((BotLifeResult r) => r.diag.portfolioUnrealizedAtDeath).toList(),
  ))}');
  print('  gerceklesen kar               ${_k(_medyan(
    yatiranlar.map((BotLifeResult r) => r.diag.portfolioRealizedAtDeath).toList(),
  ))}');
  final List<double> katlar = yatiranlar
      .map((BotLifeResult r) => r.diag.portfolioMultiple)
      .where((double x) => x > 0)
      .toList();
  print('  portfoy / maliyet (medyan)    '
      '${katlar.isEmpty ? '-' : '${_medyanDouble(katlar).toStringAsFixed(1)}x'}');
  print('');
  print('Yasam gideri (butun olen hayatlarda, medyan):');
  print('  tahakkuk eden toplam gider    ${_k(_medyan(
    olenler.map((BotLifeResult r) => r.diag.lifetimeLivingCostAccrued).toList(),
  ))}');
  print('  gercekten odenen              ${_k(_medyan(
    olenler.map((BotLifeResult r) => r.diag.lifetimeLivingCostPaid).toList(),
  ))}');
  final int tahakkuk = olenler.fold<int>(
      0, (int t, BotLifeResult r) => t + r.diag.lifetimeLivingCostAccrued);
  final int odenen = olenler.fold<int>(
      0, (int t, BotLifeResult r) => t + r.diag.lifetimeLivingCostPaid);
  print('  odenmeyen pay (toplamda)      '
      '${tahakkuk <= 0 ? '-' : '%${(100 * (tahakkuk - odenen) / tahakkuk).toStringAsFixed(1)}'}');
  print('');
  print('Q-165/5 ACIK SORUSUNUN OLCUSU');
  print('LivingCosts.apply yalnizca cuzdana dokunuyor: para yetmezse');
  print('cuzdan sifirlaniyor, BORC YAZILMIYOR ve PORTFOY SATILMIYOR.');
  print('Yani portfoy giderden korunuyor ve bilesik buyumeye devam');
  print('ediyor. Bu kodda boyle; onaylanmis bir kural DEGIL (Q-165/5');
  print('hala acik). Olcu:');
  final List<BotLifeResult> korunan = olenler
      .where((BotLifeResult r) => r.diag.protectedYears > 0)
      .toList(growable: false);
  print('  cuzdan gideri karsilamadigi halde portfoyu dolu olan hayat: '
      '${_yuzde(korunan.length, olenler.length)} (${korunan.length})');
  print('  bu hayatlarda korunan yil sayisi (medyan) ${_medyan(
    korunan.map((BotLifeResult r) => r.diag.protectedYears).toList(),
  )}');
  print('  butun hayatlarda korunan yil (medyan) ${_medyan(
    olenler.map((BotLifeResult r) => r.diag.protectedYears).toList(),
  )}');
  print('  korunan yillarda ortalama portfoy ${_k(korunan.isEmpty ? 0 : _ortalama(
    korunan
        .map((BotLifeResult r) =>
            r.diag.protectedYearsPortfolioSum ~/ max(1, r.diag.protectedYears))
        .toList(),
  ))}');
  print('');
  print('Ayrim: 134M nin ne kadari gercek getiri, ne kadari korunma?');
  print('Korunan yil sayisi omrun kucuk bir kismiysa ve portfoy/maliyet');
  print('kati buyukse, ana surukleyici GETIRIDIR; korunma ikincil.');
  print('Korunan yil cok ve servet yuksekse, korunma asil neden olur.');
  print('Iki sayiyi da yukarida birakiyorum; karari Faho + ChatGPT verir.');
}

// =====================================================================
// F — miras etkisi
// =====================================================================

void _bolumF() {
  final List<BotLifeResult> olenler = _olenler();
  _baslik('F — MIRAS ETKISI');

  final List<BotLifeResult> zenginler = olenler
      .where((BotLifeResult r) => r.diag.netWorth > 50000000)
      .toList(growable: false);
  print('Butun hayatlarda:');
  print('  miras alan ${_yuzde(
    olenler.where((BotLifeResult r) => r.diag.inheritanceCount > 0).length,
    olenler.length,
  )}');
  print('  miras sayisi (medyan) ${_medyan(
    olenler.map((BotLifeResult r) => r.diag.inheritanceCount).toList(),
  )} · en fazla ${olenler.fold<int>(0, (int t, BotLifeResult r) => max(t, r.diag.inheritanceCount))}');
  print('  gelen toplam nakit (medyan) ${_k(_medyan(
    olenler.map((BotLifeResult r) => r.diag.inheritanceMoney).toList(),
  ))}');
  print('');
  print('Serveti 50M ustu olan ${zenginler.length} hayatta:');
  if (zenginler.isEmpty) {
    print('  (yok)');
  } else {
    print('  miras alan ${_yuzde(
      zenginler.where((BotLifeResult r) => r.diag.inheritanceCount > 0).length,
      zenginler.length,
    )}');
    print('  miras sayisi (medyan) ${_medyan(
      zenginler.map((BotLifeResult r) => r.diag.inheritanceCount).toList(),
    )}');
    print('  gelen toplam miras (medyan) ${_k(_medyan(
      zenginler.map((BotLifeResult r) => r.diag.inheritanceMoney).toList(),
    ))}');
    final List<double> paylar = zenginler
        .map((BotLifeResult r) => r.diag.inheritanceShare)
        .toList(growable: false);
    print('  mirasin servetteki payi: medyan '
        '%${(100 * _medyanDouble(paylar)).toStringAsFixed(2)} · '
        'en yuksek %${(100 * paylar.reduce(max)).toStringAsFixed(2)}');
    print('  mirasla gelen esya adedi (medyan) ${_medyan(
      zenginler.map((BotLifeResult r) => r.diag.inheritanceItems).toList(),
    )}');
  }
  print('');
  print('Sorunun cevabi: aile zinciri serveti patlatiyor mu? Mirasin');
  print('servetteki payi kucukse (yuzde birler), hayir. Inheritance');
  print('sinifinda en zengin kademede bile nakit 3,5M ile sinirli');
  print('(prototypeOnlyEstateMoney); miras tek basina 134M yapamaz.');
}

// =====================================================================
// G — evlilik hunisi
// =====================================================================

void _bolumG() {
  _baslik('G — EVLILIK HUNISI (${_korpus.length} hayat)');
  print('Esik: teklif icin yakinlik >= '
      '${MarriageEngine.prototypeOnlyMinBond}, iki tarafta yas >= '
      '${MarriageEngine.prototypeOnlyMinAge}.');
  print('');
  // Huni **monoton** basamaklardan kuruluyor. İlk yazımda "bot
  // evlenmek istedi" ve "flort etti" satirlarini da huniye koymustum;
  // ikisi de monoton degil (evlenmek istemeyen de aday gorur, Finger
  // eslesmesi flort basamagi gorunmeden sevgiliye donebilir) ve tablo
  // eksi kayip yuzdesi basiyordu. Ikisi huninin **yanina** ayri bilgi
  // olarak tasindi.
  _huni(_korpus, <(String, bool Function(BotDiag))>[
    ('toplam hayat', (BotDiag d) => true),
    ('romantik yasa geldi (18+)', (BotDiag d) => d.reachedRomanceAge),
    ('partner adayi gordu', (BotDiag d) => d.sawCandidate),
    ('sevgilisi oldu', (BotDiag d) => d.hadPartner),
    ('yakinlik 30+', (BotDiag d) => d.bond30),
    ('yakinlik 45+ (teklif esigi)', (BotDiag d) => d.bond45),
    ('teklif edilebilir hale geldi', (BotDiag d) => d.proposalEligible),
    ('teklif etti', (BotDiag d) => d.proposed),
    ('teklif kabul edildi', (BotDiag d) => d.proposalAccepted),
    ('bekleyen dugun olustu', (BotDiag d) => d.pendingWeddingSeen),
    ('dugun yapildi', (BotDiag d) => d.weddingHeld),
  ]);
  print('');
  print('Huni disi iki bilgi (monoton degil, ayri duruyor):');
  print('  BOT evlenmek istedi        ${_yuzde(
    _korpus.where((BotLifeResult r) => r.diag.wantedMarriage).length,
    _korpus.length,
  )}  <- bir BOT parametresi (familyDesire), oyun kapisi degil');
  print('  flort basamagi gorundu     ${_yuzde(
    _korpus.where((BotLifeResult r) => r.diag.flirted).length,
    _korpus.length,
  )}  <- sevgili oranindan dusuk: cogu sevgili flort');
  print('                                  basamagi gorunmeden olusuyor');
  print('');
  print('En yuksek gorulen sevgili yakinligi (medyan) ${_medyan(
    _korpus
        .where((BotLifeResult r) => r.diag.hadPartner)
        .map((BotLifeResult r) => r.diag.bestPartnerBond)
        .toList(),
  )}');
  print('Teklif denemesi (teklif edenlerde, medyan) ${_medyan(
    _korpus
        .where((BotLifeResult r) => r.diag.proposed)
        .map((BotLifeResult r) => r.diag.proposalAttempts)
        .toList(),
  )}');
  print('');
  print('Ayni huni, YALNIZCA EVLENMEK ISTEYEN hayatlarda:');
  print('(Bekar kalmak gecerli bir hayat; isteyenle istemeyeni');
  print('ayirmadan huni yaniltici olur.)');
  print('');
  final List<BotLifeResult> isteyenler = _korpus
      .where((BotLifeResult r) => r.diag.wantedMarriage)
      .toList(growable: false);
  _huni(isteyenler, <(String, bool Function(BotDiag))>[
    ('evlenmek isteyen', (BotDiag d) => true),
    ('partner adayi gordu', (BotDiag d) => d.sawCandidate),
    ('sevgilisi oldu', (BotDiag d) => d.hadPartner),
    ('yakinlik 30+', (BotDiag d) => d.bond30),
    ('yakinlik 45+', (BotDiag d) => d.bond45),
    ('teklif edilebilir', (BotDiag d) => d.proposalEligible),
    ('teklif etti', (BotDiag d) => d.proposed),
    ('kabul edildi', (BotDiag d) => d.proposalAccepted),
    ('dugun yapildi', (BotDiag d) => d.weddingHeld),
  ]);
  print('');
  print('DAR KAPI: iki basamak arasindaki en buyuk dusus nerede?');
}

// =====================================================================
// H — evlilik blocker raporu
// =====================================================================

void _bolumH() {
  _baslik('H — EVLILIK BLOCKER RAPORU');
  print('Bot teklif etmek istedigi halde oyun izin vermediginde');
  print('kaydedilen gerekce (oyunun kendi metninden, tahmin degil).');
  print('Ayni hayatta ayni gerekce birden cok yil sayilabilir.');
  print('');
  final Map<String, int> sayim = <String, int>{};
  int toplam = 0;
  for (final BotLifeResult r in _korpus) {
    for (final String s in r.diag.marriageBlockers) {
      sayim[s] = (sayim[s] ?? 0) + 1;
      toplam++;
    }
  }
  if (sayim.isEmpty) {
    print('(Hic engel kaydedilmedi.)');
  } else {
    final List<String> sirali = sayim.keys.toList()
      ..sort((String a, String b) => sayim[b]!.compareTo(sayim[a]!));
    print('En sik ${min(10, sirali.length)} engel (toplam $toplam kayit):');
    for (final String s in sirali.take(10)) {
      print('  ${s.padRight(28)} ${sayim[s]!.toString().padLeft(7)}  '
          '%${(100 * sayim[s]! / toplam).toStringAsFixed(1)}');
    }
  }
  print('');
  print('Ayrica: engele hic takilmayan ama yine de evlenmeyen hayatlar');
  print('var mi? (Teklif edilebilir hale geldi, ama teklif etmedi ya da');
  print('teklif reddedildi.)');
  // **Yalnizca evlenmek isteyen hayatlarda.** İlk yazımda bunu butun
  // korpusta olcmustum ve "uygun ama teklif etmeyen %48,6" cikmisti;
  // oysa o sayinin neredeyse tamami hic evlenmek istememis hayatlardi.
  // Yaniltici bir metrikti.
  final List<BotLifeResult> isteyen = _korpus
      .where((BotLifeResult r) => r.diag.wantedMarriage)
      .toList(growable: false);
  final int n = isteyen.length;
  final int sevgilisizKaldi =
      isteyen.where((BotLifeResult r) => !r.diag.hadPartner).length;
  final int uygunAmaTeklifsiz = isteyen
      .where((BotLifeResult r) =>
          r.diag.proposalEligible && !r.diag.proposed)
      .length;
  final int teklifAmaRet = isteyen
      .where((BotLifeResult r) => r.diag.proposed && !r.diag.proposalAccepted)
      .length;
  final int kabulAmaDugunsuz = isteyen
      .where((BotLifeResult r) =>
          r.diag.proposalAccepted && !r.diag.weddingHeld)
      .length;
  print('Evlenmek isteyen $n hayatta:');
  print('  hic sevgilisi olmayan     ${_yuzde(sevgilisizKaldi, n)}'
      ' ($sevgilisizKaldi)  <- ASIL DAR KAPI');
  print('  uygun ama teklif etmeyen  ${_yuzde(uygunAmaTeklifsiz, n)}'
      ' ($uygunAmaTeklifsiz)  <- BOT davranisi (0,7 ihtimal)');
  print('  teklif edip reddedilen    ${_yuzde(teklifAmaRet, n)}'
      ' ($teklifAmaRet)  <- OYUN (kabul ihtimali)');
  print('  kabul alip dugunsuz kalan ${_yuzde(kabulAmaDugunsuz, n)}'
      ' ($kabulAmaDugunsuz)  <- olursa GERCEK HATA');
}

// =====================================================================
// G-EK — "aday gördü" ile "sevgilisi oldu" arasındaki kapı
// =====================================================================

/// G hunisinde evlenmek isteyen hayatların **%49'u hiç sevgili
/// edinemiyor** ve bütün kayıp orada. Bu bölüm o kapının mekaniğini
/// ölçüyor: oyunun eşiği mi, botun davranışı mı?
void _bolumGEk() {
  _baslik('G-EK — "ADAY GORDU" ILE "SEVGILISI OLDU" ARASINDAKI KAPI');
  print('G hunisi: evlenmek isteyen 471 hayatta aday goren %99,4 ama');
  print('sevgilisi olan %51,0. Butun kayip bu iki basamak arasinda.');
  print('Yakinlik 45 esigi kayip uretmiyor (%50,1 -> %49,7).');
  print('');
  print('Kapinin uc parcasi var:');
  print('');
  print('1) PROFILIN NIYETI (oyun tarafi, gorunur bilgi)');
  kFingerIntentWeights.forEach((FingerIntent i, double w) {
    print('   ${i.name.padRight(12)} ${(100 * w).toStringAsFixed(0)}%  '
        '${i.label}');
  });
  print('   `arkadaslik` niyetli profille tanismak FLORT DEGIL ARKADAS');
  print('   uretiyor (finger.dart:448 `arkadasKalir`). Yani her dorder');
  print('   adaydan biri bastan romantik yola girmiyor.');
  print('   Bu bir oyun kurali (D-107) ve ekranda YAZIYOR. Bot ise');
  print('   desteden DUZ RASTGELE profil seciyor, niyete hic bakmiyor:');
  print('   gercek oyuncu profilde yazan niyeti okur. BOT EKSIGI.');
  print('');
  print('2) FLORTUN BASLANGIC YAKINLIGI ILE RESMILESTIRME ESIGI');
  print('   Yeni flortun yakinligi: rng.between(45, 62) '
      '(finger.dart:476)');
  print('   Resmilestirme esigi: yakinlik >= '
      '${Finger.prototypeOnlyOfficialBond} (finger.dart:561)');
  const int alt = 45;
  const int ust = 62;
  const int aralik = ust - alt;
  final int gecen = ust - Finger.prototypeOnlyOfficialBond + 1;
  print('   Yani yeni bir flort DOGRUDAN resmilestirilebilir olma');
  print('   ihtimali: $gecen/${aralik + 1} = '
      '%${(100 * gecen / (aralik + 1)).toStringAsFixed(1)}');
  print('   Kalan %${(100 * (aralik + 1 - gecen) / (aralik + 1)).toStringAsFixed(1)}'
      ' icin flortle VAKIT GECIRIP yakinligi');
  print('   yukseltmek gerekiyor.');
  print('');
  print('3) BOT FLORTLE HIC VAKIT GECIRMIYOR — ASIL SEBEP');
  print('   `_handleRelationships` flort dalinda yalnizca');
  print('   `officialAvailability` acikSA resmilestiriyor; acik degilse');
  print('   HICBIR SEY YAPMIYOR ve `break` ile cikiyor.');
  print('   `_spendTimeWithFamily` da yalnizca es/cocuk/anne/baba/');
  print('   sevgili ile ilgileniyor — FLORT LISTEDE YOK.');
  print('   Ustune Paket R kurali var: ilgilenilmeyen flort biter.');
  print('   Sonuc: bot flort ediniyor, yakinligi 60a cikmiyorsa hic');
  print('   ugrasmiyor, flort soneip bitiyor, dongu bastan.');
  print('   Bu OYUN kapisi degil, BOT eksigi: oyunda flortle vakit');
  print('   gecirmek mumkun (`availableKindsFor` aciktir).');
  print('');
  print('Olcum: botun flort edindigi ama sevgiliye cevirEMEdigi hayatlar');
  final List<BotLifeResult> isteyen = _korpus
      .where((BotLifeResult r) => r.diag.wantedMarriage)
      .toList(growable: false);
  final int flortEdinen =
      isteyen.where((BotLifeResult r) => r.diag.flirted).length;
  final int flortAmaSevgilisiz = isteyen
      .where((BotLifeResult r) => r.diag.flirted && !r.diag.hadPartner)
      .length;
  print('  evlenmek isteyen                       ${isteyen.length}');
  print('  bunlardan flort basamagi goruleni      $flortEdinen');
  print('  flortu olup sevgilisi HIC olmayani     $flortAmaSevgilisiz'
      '  ${_yuzde(flortAmaSevgilisiz, flortEdinen)}');
  print('');
  print('AYRIM');
  print('  OYUN tarafi : 45-62 baslangic yakinligi ile 60 resmilestirme');
  print('                esiginin ortusmesi dar bir kapi birakiyor;');
  print('                ayrica adaylarin %25i bastan arkadaslik istiyor.');
  print('  BOT tarafi  : flortle hic vakit gecirmiyor ve desteden niyete');
  print('                bakmadan profil seciyor. Gercek oyuncu ikisini de');
  print('                yapar. ASIL KAYNAK BURASI.');
  print('');
  print('Bu turda hicbiri degistirilmedi. Q kaydina gidiyor.');
}

// =====================================================================
// I — family arketipi özel inceleme
// =====================================================================

void _bolumI() {
  _baslik('I — ARKETIP BAZINDA EVLILIK HUNISI');
  print('Aile odakli bot bile evlenemiyorsa sorun oyun kapisinda;');
  print('yalnizca diger arketiplerde dusukse bu bir davranis tercihi.');
  print('');
  print('arketip        istedi   aday   sevgili   b30    b45    uygun  '
      'teklif  kabul  DUGUN');
  for (final PlayerArchetype tip in PlayerArchetype.values) {
    final List<BotLifeResult> grup = _korpus
        .where((BotLifeResult r) => r.archetype == tip)
        .toList(growable: false);
    final int n = grup.length;
    print('${tip.name.padRight(14)} '
        '${_yuzde(grup.where((BotLifeResult r) => r.diag.wantedMarriage).length, n).padLeft(6)} '
        '${_yuzde(grup.where((BotLifeResult r) => r.diag.sawCandidate).length, n).padLeft(6)} '
        '${_yuzde(grup.where((BotLifeResult r) => r.diag.hadPartner).length, n).padLeft(9)} '
        '${_yuzde(grup.where((BotLifeResult r) => r.diag.bond30).length, n).padLeft(6)} '
        '${_yuzde(grup.where((BotLifeResult r) => r.diag.bond45).length, n).padLeft(6)} '
        '${_yuzde(grup.where((BotLifeResult r) => r.diag.proposalEligible).length, n).padLeft(6)} '
        '${_yuzde(grup.where((BotLifeResult r) => r.diag.proposed).length, n).padLeft(6)} '
        '${_yuzde(grup.where((BotLifeResult r) => r.diag.proposalAccepted).length, n).padLeft(6)} '
        '${_yuzde(grup.where((BotLifeResult r) => r.diag.weddingHeld).length, n).padLeft(6)}');
  }
  print('');
  final List<BotLifeResult> aile = _korpus
      .where((BotLifeResult r) => r.archetype == PlayerArchetype.family)
      .toList(growable: false);
  final List<BotLifeResult> aileIsteyen =
      aile.where((BotLifeResult r) => r.diag.wantedMarriage).toList();
  print('FAMILY arketipi, yalnizca evlenmek isteyen '
      '${aileIsteyen.length} hayatta:');
  _huni(aileIsteyen, <(String, bool Function(BotDiag))>[
    ('evlenmek isteyen', (BotDiag d) => true),
    ('sevgilisi oldu', (BotDiag d) => d.hadPartner),
    ('yakinlik 45+', (BotDiag d) => d.bond45),
    ('teklif edilebilir', (BotDiag d) => d.proposalEligible),
    ('teklif etti', (BotDiag d) => d.proposed),
    ('kabul edildi', (BotDiag d) => d.proposalAccepted),
    ('dugun yapildi', (BotDiag d) => d.weddingHeld),
  ]);
}

// =====================================================================
// J/K — tekrar evlenme hunisi ve engelleri
// =====================================================================

void _bolumJK() {
  _baslik('J/K — AYRILIK SONRASI VE TEKRAR EVLENME');

  final List<BotLifeResult> ayrilanlar = _korpus
      .where((BotLifeResult r) => r.diag.separationAge != null)
      .toList(growable: false);
  print('Ayrilan (bosanma ya da dulluk) ${_yuzde(ayrilanlar.length, _korpus.length)}'
      ' (${ayrilanlar.length}/${_korpus.length})');
  final int bosanan =
      ayrilanlar.where((BotLifeResult r) => r.diag.separationKind == 'bosanma').length;
  print('  bunlardan bosanma $bosanan · dulluk ${ayrilanlar.length - bosanan}');
  if (ayrilanlar.isEmpty) {
    print('Ayrilan hayat yok: bu korpusta tekrar evlenme olcumu yapilamaz.');
    print('L bolumu hedefli korpusla tekrar deniyor.');
    return;
  }
  print('  ayrilik yasi (medyan) ${_medyan(
    ayrilanlar.map((BotLifeResult r) => r.diag.separationAge!).toList(),
  )}');
  print('  ayriliktan sonra yasanan yil (medyan) ${_medyan(
    ayrilanlar.map((BotLifeResult r) => r.diag.yearsAfterSeparation).toList(),
  )}');
  print('');
  print('KAYIT DOGRU KAPANDI MI? (K bolumunun ilk sorusu)');
  print('  eski es kaydi korundu (kimlik listede) ${_yuzde(
    ayrilanlar.where((BotLifeResult r) => r.diag.exSpouseRecordKept).length,
    ayrilanlar.length,
  )}');
  final List<BotLifeResult> bosananlar = ayrilanlar
      .where((BotLifeResult r) => r.diag.separationKind == 'bosanma')
      .toList(growable: false);
  print('  bosanmada bag `es` olmaktan cikti ${_yuzde(
    bosananlar.where((BotLifeResult r) => r.diag.exSpouseRelationUpdated).length,
    bosananlar.length,
  )} (${bosananlar.length} bosanma)');
  print('  oyun yeniden bekar kabul ediyor ${_yuzde(
    ayrilanlar.where((BotLifeResult r) => r.diag.treatedAsSingleAfter).length,
    ayrilanlar.length,
  )}');
  print('');
  print('AYRILIK SONRASI HUNI:');
  _huni(ayrilanlar, <(String, bool Function(BotDiag))>[
    ('ayrilan', (BotDiag d) => true),
    ('yeniden bekar sayiliyor', (BotDiag d) => d.treatedAsSingleAfter),
    ('yeni partner adayi gordu', (BotDiag d) => d.postSepCandidate),
    ('yeni flort', (BotDiag d) => d.postSepFlirt),
    ('yeni sevgili', (BotDiag d) => d.postSepPartner),
    ('yeni sevgilide yakinlik 45+', (BotDiag d) => d.postSepBond45),
    ('teklif edilebilir', (BotDiag d) => d.postSepEligible),
    ('teklif etti', (BotDiag d) => d.postSepProposed),
    ('kabul edildi', (BotDiag d) => d.postSepAccepted),
    ('YENIDEN EVLENDI', (BotDiag d) => d.postSepMarried),
  ]);
  print('');
  final Map<String, int> engeller = <String, int>{};
  for (final BotLifeResult r in ayrilanlar) {
    for (final String s in r.diag.postSepBlockers) {
      engeller[s] = (engeller[s] ?? 0) + 1;
    }
  }
  print('Ayrilik sonrasi teklif engelleri:');
  if (engeller.isEmpty) {
    print('  (kayit yok)');
  } else {
    final List<String> sirali = engeller.keys.toList()
      ..sort((String a, String b) => engeller[b]!.compareTo(engeller[a]!));
    for (final String s in sirali.take(10)) {
      print('  ${s.padRight(28)} ${engeller[s]}');
    }
  }
  print('');
  print('MOTOR SEVIYESINDE ZATEN KANITLI: second_marriage_test.dart');
  print('"bosanan yeniden evlenebilir" ve "dul kalan yeniden evlenebilir"');
  print('testleri geciyor. Yani marryBlockReason ikinci evliligi');
  print('engellemiyor. %0 bir motor kilidi DEGIL; huninin neresinde');
  print('kirildigi yukaridaki tabloda.');
}

// =====================================================================
// L — hedefli ayrılık sonrası hayatlar
// =====================================================================

void _bolumL() {
  _baslik('L — HEDEFLI AYRILIK SONRASI HAYATLAR ($kSeparationLives hayat)');
  print('Dogal korpusta ayrilan hayat sayisi az. Burada evlenme');
  print('egilimi en yuksek arketiplerle ($kSeparationLives hayat) kosuyoruz:');
  print('family (familyDesire 0,95) ve casual (0,60).');
  print('');
  print('DEBUG HILESI YOK: karaktere es, para, stat ya da ilisiki');
  print('verilmiyor. Hayat normal PlayerBot olarak dogumdan olume');
  print('oynaniyor; ayrilan hayatlar sonradan suzuluyor.');
  print('');

  final List<BotLifeResult> hedefli = <BotLifeResult>[];
  for (int i = 0; i < kSeparationLives; i++) {
    hedefli.add(playBotLife(
      archetype: i.isEven
          ? PlayerArchetype.family
          : PlayerArchetype.casual,
      seed: 950000 + i * 17,
    ));
  }
  final List<BotLifeResult> evlenen =
      hedefli.where((BotLifeResult r) => r.diag.weddingHeld).toList();
  final List<BotLifeResult> ayrilan = hedefli
      .where((BotLifeResult r) => r.diag.separationAge != null)
      .toList(growable: false);

  print('${hedefli.length} hayat kosuldu.');
  print('  evlenen  ${_yuzde(evlenen.length, hedefli.length)} (${evlenen.length})');
  print('  ayrilan  ${_yuzde(ayrilan.length, hedefli.length)} (${ayrilan.length})');
  if (ayrilan.isEmpty) {
    print('Ayrilan hayat yok; huni cikarilamiyor.');
    return;
  }
  final int bosanma =
      ayrilan.where((BotLifeResult r) => r.diag.separationKind == 'bosanma').length;
  print('  bosanma $bosanma · dulluk ${ayrilan.length - bosanma}');
  print('  ayrilik yasi (medyan) ${_medyan(
    ayrilan.map((BotLifeResult r) => r.diag.separationAge!).toList(),
  )}');
  print('  ayriliktan sonra yasanan yil (medyan) ${_medyan(
    ayrilan.map((BotLifeResult r) => r.diag.yearsAfterSeparation).toList(),
  )} · en fazla ${ayrilan.fold<int>(0, (int t, BotLifeResult r) => max(t, r.diag.yearsAfterSeparation))}');
  print('');
  _huni(ayrilan, <(String, bool Function(BotDiag))>[
    ('ayrilan', (BotDiag d) => true),
    ('yeniden bekar sayiliyor', (BotDiag d) => d.treatedAsSingleAfter),
    ('yeni partner adayi', (BotDiag d) => d.postSepCandidate),
    ('yeni flort', (BotDiag d) => d.postSepFlirt),
    ('yeni sevgili', (BotDiag d) => d.postSepPartner),
    ('yakinlik 45+', (BotDiag d) => d.postSepBond45),
    ('teklif edilebilir', (BotDiag d) => d.postSepEligible),
    ('teklif etti', (BotDiag d) => d.postSepProposed),
    ('kabul edildi', (BotDiag d) => d.postSepAccepted),
    ('YENIDEN EVLENDI', (BotDiag d) => d.postSepMarried),
  ]);
  final List<BotLifeResult> yeniden =
      ayrilan.where((BotLifeResult r) => r.diag.postSepMarried).toList();
  if (yeniden.isNotEmpty) {
    print('');
    print('Yeniden evlenenlerde ayriliktan sonra gecen yil (medyan) '
        '${_medyan(yeniden
            .map((BotLifeResult r) =>
                r.diag.remarriageAge! - r.diag.separationAge!)
            .toList())}');
  }
  print('');
  final Map<String, int> engeller = <String, int>{};
  for (final BotLifeResult r in ayrilan) {
    for (final String s in r.diag.postSepBlockers) {
      engeller[s] = (engeller[s] ?? 0) + 1;
    }
  }
  print('Ayrilik sonrasi teklif engelleri (hedefli korpus):');
  if (engeller.isEmpty) {
    print('  (kayit yok — bot teklif etmek isteyip engellenmedi)');
  } else {
    final List<String> sirali = engeller.keys.toList()
      ..sort((String a, String b) => engeller[b]!.compareTo(engeller[a]!));
    for (final String s in sirali.take(10)) {
      print('  ${s.padRight(28)} ${engeller[s]}');
    }
  }
}

// =====================================================================
// M — hiç girilmeyen meslekler
// =====================================================================

void _bolumM() {
  _baslik('M — MESLEK ERISIMI');

  final Set<String> gorulen = <String>{};
  for (final BotLifeResult r in _korpus) {
    gorulen.addAll(r.jobIds);
  }
  final List<JobType> hicGirilmeyen = kJobCatalog
      .where((JobType j) => !gorulen.contains(j.id))
      .toList(growable: false);
  print('Katalog ${kJobCatalog.length} meslek · girilen ${gorulen.length} · '
      'hic girilmeyen ${hicGirilmeyen.length}');
  print('');

  // Toplu sayaçlar.
  final Map<String, int> acikYil = <String, int>{};
  final Map<String, int> basvuru = <String, int>{};
  final Map<String, int> basarisiz = <String, int>{};
  final Map<String, String> kilit = <String, String>{};
  for (final BotLifeResult r in _korpus) {
    r.diag.jobOpenYears.forEach((String k, int v) {
      acikYil[k] = (acikYil[k] ?? 0) + v;
    });
    r.diag.jobApplied.forEach((String k, int v) {
      basvuru[k] = (basvuru[k] ?? 0) + v;
    });
    r.diag.jobFailed.forEach((String k, int v) {
      basarisiz[k] = (basarisiz[k] ?? 0) + v;
    });
    r.diag.jobLockReason.forEach((String k, String v) => kilit[k] = v);
  }

  for (final JobType j in hicGirilmeyen) {
    print('--- ${j.id} (${j.name}) ---');
    print('  yillik maas ${_k(j.yearlySalary)} · yarim zamanli ${j.partTime}');
    print('  sart: ${_jobSart(j)}');
    final int acik = acikYil[j.id] ?? 0;
    final int bas = basvuru[j.id] ?? 0;
    print('  isyiz botun ACIK ILANDA gordugu yil sayisi: $acik');
    print('  botun basvurdugu: $bas · sonuc vermeyen: ${basarisiz[j.id] ?? 0}');
    final String? sebep = kilit[j.id];
    if (sebep != null && sebep.isNotEmpty) {
      print('  kapaliyken oyunun gerekcesi: $sebep');
    }
    print('  SINIF: ${_jobSinif(acik, bas)}');
  }
  if (hicGirilmeyen.isEmpty) print('(Hepsi en az bir kez gorulmus.)');

  print('');
  print('SINIFLAR');
  print('  A) icerik erisilebilir ama bot secmiyor  '
      '(ilan acildi, bot basvurmadi ya da az basvurdu)');
  print('  B) kapi cok dar  (ilan neredeyse hic acilmadi)');
  print('  C) imkansiz/bug  (ilan hic acilmadi, sart saglanmis olsa bile)');
  print('  D) dogal olarak cok nadir  (ilan acildi ama cok az yil)');
  print('');
  print('EHLIYET BOSLUGU (bot tarafi): PlayerBot hic ehliyet almiyor —');
  print('`applyForLicense` hicbir yerde cagrilmiyor. Ehliyet isteyen');
  print('her meslek bu yuzden ILANDA HIC ACILMIYOR. Bu bir OYUN kapisi');
  print('degil, BOT eksigi: ehliyet oyunda alinabilir bir sey.');
  print('');
  print('Botun is secme kurali bir tarafi cok etkiliyor: issizken');
  print('acik isleri MAASA gore siraliyor ve %70 ihtimalle UST UCTE');
  print('BIRDEN seciyor. Maasi dusuk bir meslek acik olsa bile ust');
  print('ucte bire girmedigi surece neredeyse hic secilmiyor. Bu bir');
  print('BOT davranisi; oyun kapisi degil.');
  print('');
  print('En sik goruldugu 12 meslek (acik ilan yili):');
  final List<String> sirali = acikYil.keys.toList()
    ..sort((String a, String b) => acikYil[b]!.compareTo(acikYil[a]!));
  for (final String id in sirali.take(12)) {
    final int bas = basvuru[id] ?? 0;
    print('  ${id.padRight(24)} ilan ${acikYil[id]!.toString().padLeft(6)} · '
        'basvuru ${bas.toString().padLeft(5)} · '
        'basvuru/ilan %${(100 * bas / acikYil[id]!).toStringAsFixed(1)}');
  }
}

String _jobSart(JobType j) {
  final List<String> parcalar = <String>[
    'min yas ${j.minAge}',
    'egitim: ${j.education.name}',
    if (j.programs.isNotEmpty) 'bolum: ${j.programs.join("/")}',
    if (j.requiredLicenses.isNotEmpty)
      'ehliyet: ${j.requiredLicenses.join("/")}',
    if (j.martialArtId != null) 'dovus sanati ${j.martialArtId}',
    if (j.hobbyId != null) 'hobi ${j.hobbyId} (basamak ${j.minHobbyStage})',
    if (j.maxAge != null) 'max yas ${j.maxAge}',
    if (j.minIntelligence > 0) 'zeka ${j.minIntelligence}',
    if (j.minCharisma > 0) 'karizma ${j.minCharisma}',
    if (j.minAppearance > 0) 'gorunus ${j.minAppearance}',
  ];
  return parcalar.join(', ');
}

String _jobSinif(int acikYil, int basvuru) {
  if (acikYil == 0) return 'C veya B — ilan HIC acilmadi (kapi kapali)';
  if (basvuru == 0 && acikYil > 200) {
    return 'A — ilan cokca acildi ama bot hic basvurmadi (bot davranisi)';
  }
  if (basvuru == 0) return 'D/A — ilan az acildi ve bot basvurmadi';
  return 'A — bot basvurdu ama ise girmedi';
}

// =====================================================================
// N — hiç kurulmayan işletmeler
// =====================================================================

void _bolumN() {
  _baslik('N — ISLETME ERISIMI');
  final Set<String> kurulan = <String>{};
  for (final BotLifeResult r in _korpus) {
    kurulan.addAll(r.businessTypes);
  }
  print('Katalog ${kBusinessCatalog.length} tur · kurulan ${kurulan.length}');
  print('');

  final Map<String, int> acikYil = <String, int>{};
  final Map<String, int> karsilanabilir = <String, int>{};
  final Map<String, int> deneme = <String, int>{};
  final Map<String, String> kilit = <String, String>{};
  for (final BotLifeResult r in _korpus) {
    r.diag.bizAllowedYears.forEach((String k, int v) {
      acikYil[k] = (acikYil[k] ?? 0) + v;
    });
    r.diag.bizAffordableYears.forEach((String k, int v) {
      karsilanabilir[k] = (karsilanabilir[k] ?? 0) + v;
    });
    r.diag.bizAttempted.forEach((String k, int v) {
      deneme[k] = (deneme[k] ?? 0) + v;
    });
    r.diag.bizLockReason.forEach((String k, String v) => kilit[k] = v);
  }

  final List<BotLifeResult> girisimciler = _korpus
      .where((BotLifeResult r) => r.archetype == PlayerArchetype.entrepreneur)
      .toList(growable: false);
  final Set<String> girisimciKurdu = <String>{};
  for (final BotLifeResult r in girisimciler) {
    girisimciKurdu.addAll(r.businessTypes);
  }

  print('tur                   sermaye     sart acik  sermaye yeter  '
      'deneme  kuruldu  girisimci kurdu');
  for (final BusinessType t in kBusinessCatalog) {
    final bool kur = kurulan.contains(t.id);
    print('${t.id.padRight(21)} ${_k(t.setupCost).padLeft(10)} '
        '${(acikYil[t.id] ?? 0).toString().padLeft(10)} '
        '${(karsilanabilir[t.id] ?? 0).toString().padLeft(14)} '
        '${(deneme[t.id] ?? 0).toString().padLeft(7)} '
        '${(kur ? 'EVET' : 'hayir').padLeft(8)} '
        '${(girisimciKurdu.contains(t.id) ? 'EVET' : 'hayir').padLeft(16)}');
  }
  print('');
  for (final BusinessType t in kBusinessCatalog) {
    if (kurulan.contains(t.id)) continue;
    print('--- ${t.id} (${t.name}) HIC KURULMADI ---');
    print('  sermaye ${_k(t.setupCost)}');
    final int acik = acikYil[t.id] ?? 0;
    final int yeter = karsilanabilir[t.id] ?? 0;
    print('  sart acik gecen yil: $acik · sermaye de yeten yil: $yeter');
    final String? sebep = kilit[t.id];
    if (sebep != null && sebep.isNotEmpty) {
      print('  kapaliyken oyunun gerekcesi: $sebep');
    }
    if (acik == 0) {
      print('  SINIF: kapi kapali — sart hic saglanmadi');
    } else if (yeter == 0) {
      print('  SINIF: SERMAYE — sart aciktı ama bot hic o parayi bulamadi');
    } else {
      print('  SINIF: SECIM — sart ve sermaye vardi, bot rastgele baska');
      print('         turu secti (bot uygunlar arasindan duz rastgele');
      print('         seciyor ve hayatta en fazla bir isletme kuruyor)');
    }
  }
  print('');
  print('Botun kurali onemli: `wantsBusiness` niyeti olan bot, isletmesi');
  print('yokken 3 yilda bir deniyor ve UYGUNLAR ARASINDAN DUZ RASTGELE');
  print('birini seciyor. Hayat boyunca genelde tek isletme kuruluyor.');
  print('Yani nadir gorulen tur illa dar kapi degil; bot davranisi da');
  print('olabilir. Yukaridaki "sermaye yeter" sutunu ikisini ayirir.');
  print('');
  print('Girisimci arketipinin ${girisimciler.length} hayatinda kurulan '
      'tur sayisi: ${girisimciKurdu.length}/${kBusinessCatalog.length}');
  print('');
  print('IKI AYRI SEBEP, KARISTIRILMAMALI:');
  print('  1) EHLIYET: is_nakliye otomobil ehliyeti istiyor ve bot hic');
  print('     ehliyet almiyor (`applyForLicense` cagrilmiyor). Meslek');
  print('     tarafindaki kurye/yz_kurye ile ayni bot eksigi.');
  print('  2) SERMAYE: 2M+ sermayeli turlerde "sart acik gecen yil 0"');
  print('     cikiyor. Sebep oyunun sermaye sarti DEGIL, botun para');
  print('     politikasi: bot artan parayi her firsatta portfoye');
  print('     koyuyor (yatirim/firsat 1,00, P/Q bolumu), bu yuzden');
  print('     cuzdanda hic 2M birikmiyor. Botun "isletme kurmak icin');
  print('     yatirim sat" ya da "isletme kredisi cek" yolu yok.');
}

// =====================================================================
// O — hiç görülmeyen olaylar
// =====================================================================

void _bolumO() {
  _baslik('O — OLAY ERISIMI');
  final Set<String> gorulen = <String>{};
  final Set<String> uygunOlan = <String>{};
  for (final BotLifeResult r in _korpus) {
    gorulen.addAll(r.seenEvents);
    uygunOlan.addAll(r.diag.eligibleEvents);
  }
  final List<GameEvent> hicGorulmeyen = kEventPool
      .where((GameEvent e) => !gorulen.contains(e.id))
      .toList(growable: false);

  print('Havuz ${kEventPool.length} olay · gorulen ${gorulen.length} '
      '(%${(100 * gorulen.length / kEventPool.length).toStringAsFixed(1)})');
  print('Bir kez bile UYGUN hale gelen ${uygunOlan.length}');
  print('Hic gorulmeyen ${hicGorulmeyen.length}');
  print('');
  print('Ayrim: "uygun hale geldi ama gorulmedi" = havuz rekabetinde');
  print('kaybetti. "Hic uygun olmadi" = prerequisite hic olusmadi.');
  print('');
  print('NOT: uygunluk taramasi kisi gerektiren olaylarda kendi ayri');
  print('zariyla kisi cozuyor; o yuzden kisi gerektiren bir olay');
  print('"uygun" gorunup oyunun kendi cekilisinde cikmamis olabilir.');
  print('');

  final List<GameEvent> uygunAmaGorulmeyen = hicGorulmeyen
      .where((GameEvent e) => uygunOlan.contains(e.id))
      .toList(growable: false);
  final List<GameEvent> hicUygunOlmayan = hicGorulmeyen
      .where((GameEvent e) => !uygunOlan.contains(e.id))
      .toList(growable: false);

  print('SINIF 3 — uygun oldu ama havuzda secilmedi '
      '(${uygunAmaGorulmeyen.length}):');
  for (final GameEvent e in uygunAmaGorulmeyen) {
    print('  ${e.id.padRight(34)} yas ${e.requirement.minAge}-'
        '${e.requirement.maxAge} · agirlik ${e.weight} · '
        'oncelik ${e.priority}');
  }
  print('');
  print('SINIF 1/2/4 — hic uygun hale gelmedi (${hicUygunOlmayan.length}):');
  for (final GameEvent e in hicUygunOlmayan) {
    print('  ${e.id}');
    print('      yas ${e.requirement.minAge}-${e.requirement.maxAge} · '
        'agirlik ${e.weight} · tekrar ${e.repeatable}');
    print('      sart: ${_eventSart(e)}');
    print('      ${_eventSinif(e)}');
  }
  if (hicGorulmeyen.isEmpty) print('(Butun olaylar gorulmus.)');
  print('');
  print('Kisi cozumu hakkinda bilinen kirilganlik (EKSIKLER 6): '
      'EventEngine._pick');
  print('yas kapisindan ONCE _resolvePerson cagiriyor, yani kisi');
  print('gerektiren olay eklemek butun yaslarda rastgele akisi kaydiriyor.');
  print('Bu turda motor DEGISTIRILMEDI; bulgu olarak duruyor.');
}

String _eventSart(GameEvent e) {
  final EventRequirement r = e.requirement;
  final List<String> p = <String>[
    if (r.livingRelations.isNotEmpty)
      'hayatta bag: ${r.livingRelations.map((RelationType x) => x.name).join("/")}',
    if (r.personRole != null) 'kisi rolu ${r.personRole}',
    if (r.requiredFlags.isNotEmpty) 'flag: ${r.requiredFlags.join("+")}',
    if (r.forbiddenFlags.isNotEmpty) 'yasakli flag: ${r.forbiddenFlags.join("+")}',
    if (r.requiredPossessions.isNotEmpty)
      'esya: ${r.requiredPossessions.join("+")}',
    if (r.requiredPossessionKinds.isNotEmpty)
      'esya turu: ${r.requiredPossessionKinds.map((ItemKind x) => x.name).join("+")}',
    if (r.requiredLicenses.isNotEmpty) 'ehliyet: ${r.requiredLicenses.join("+")}',
    if (r.requiresEmployed) 'calisiyor olmali',
    if (r.requiresRetired) 'emekli olmali',
    if (r.requiresMinYearsInJob > 0) 'iste ${r.requiresMinYearsInJob} yil',
    if (r.requiresSchoolStudent) 'okul ogrencisi',
    if (r.minGrade != null) 'min sinif ${r.minGrade}',
    if (r.maxGrade != null) 'max sinif ${r.maxGrade}',
    if (r.requiresSocialAccount) 'sosyal medya hesabi',
    if (r.minFame > 0) 'un ${r.minFame}',
    if (r.requiresLivingPet) 'yasayan evcil hayvan',
    if (r.minPetAge > 0) 'hayvan yasi ${r.minPetAge}',
    if (r.minPetYearsTogether > 0) 'hayvanla ${r.minPetYearsTogether} yil',
    if (r.requiredHobbyId != null) 'hobi ${r.requiredHobbyId}',
    if (r.minHobbyYears > 0) 'hobi ${r.minHobbyYears} yil',
    if (r.minHobbyStage > 0) 'hobi basamak ${r.minHobbyStage}',
    if (r.requiresActiveHobby) 'hobi hala suruyor',
    if (r.requiresPortfolio) 'portfoy olmali',
    if (r.forbidsPortfolio) 'portfoy OLMAMALI',
    if (r.requiresLetProperty) 'kiracisi olan ev',
    if (r.requiresVacantProperty) 'bos yatirim evi',
    if (r.requiresTenant) 'kiracı olmali',
    if (r.forbidsProperty) 'konutu OLMAMALI',
    if (r.forbidsVehicle) 'araci OLMAMALI',
    if (r.requiresOpenCase) 'acik adli dosya',
    if (r.requiresRecord) 'sabika kaydi',
    if (r.requiresReleased) 'hapisten cikmis',
    if (r.requiresTripMemory) 'seyahat animsi',
    if (r.requiresNeglectedRelative) 'ihmal edilmis yakin',
    if (r.requireSameHousehold) 'ayni hanede',
    if (r.requireOutsideHousehold) 'hane disinda',
    if (r.requireReachable) 'ulasilabilir',
    if (r.minComfort != null) 'min mali kademe ${r.minComfort!.name}',
    if (r.maxComfort != null) 'max mali kademe ${r.maxComfort!.name}',
    if (r.personMinAge != null) 'kisi yas >= ${r.personMinAge}',
    if (r.personMaxAge != null) 'kisi yas <= ${r.personMaxAge}',
  ];
  return p.isEmpty ? '(yalnizca yas)' : p.join(' · ');
}

String _eventSinif(GameEvent e) {
  final EventRequirement r = e.requirement;
  final int pencere = r.maxAge - r.minAge;
  final int sartSayisi = _eventSart(e) == '(yalnizca yas)'
      ? 0
      : _eventSart(e).split(' · ').length;
  if (sartSayisi >= 3) {
    return 'SINIF 1 — cok sartin USTUSTE gelmesi gerekiyor '
        '($sartSayisi sart); prerequisite hic olusmadi';
  }
  if (pencere <= 5 && sartSayisi >= 1) {
    return 'SINIF 2 — pencere cok dar ($pencere yil) ve sart var';
  }
  if (pencere <= 3) {
    return 'SINIF 2 — pencere cok dar ($pencere yil)';
  }
  if (sartSayisi == 0) {
    return 'SINIF 3/4 — sart yok, yas penceresi $pencere yil; '
        'havuz rekabeti ya da tarama kapsami';
  }
  return 'SINIF 1/2 — $sartSayisi sart, pencere $pencere yil';
}

// =====================================================================
// P/Q — botun kendi mekanikliği
// =====================================================================

void _bolumPQ() {
  _baslik('P/Q — BOTUN KENDI MEKANIKLIGI');
  print('Her asiri metrikte once sorulan soru: bu OYUN sorunu mu, BOT');
  print('davranisi mi? Botun eylem sikliklarini yetiskin yil basina');
  print('veriyoruz.');
  print('');
  print('arketip        yetiskin  aktivite/yil  yatirim/firsat  '
      'basvuru/yil  etkilesim/yil  olay/yil');
  for (final PlayerArchetype tip in PlayerArchetype.values) {
    final List<BotLifeResult> grup = _korpus
        .where((BotLifeResult r) => r.archetype == tip)
        .toList(growable: false);
    final int yil =
        grup.fold<int>(0, (int t, BotLifeResult r) => t + r.diag.adultYears);
    if (yil == 0) continue;
    final int firsat = grup.fold<int>(
        0, (int t, BotLifeResult r) => t + r.diag.investOpportunityYears);
    final int alim =
        grup.fold<int>(0, (int t, BotLifeResult r) => t + r.diag.investBuys);
    print('${tip.name.padRight(14)} '
        '${(yil ~/ grup.length).toString().padLeft(8)}  '
        '${_oran(grup.fold<int>(0, (int t, BotLifeResult r) => t + r.diag.activityActions), yil).padLeft(12)}  '
        '${(firsat == 0 ? '-' : (alim / firsat).toStringAsFixed(2)).padLeft(14)}  '
        '${_oran(grup.fold<int>(0, (int t, BotLifeResult r) => t + r.diag.jobApplications), yil).padLeft(11)}  '
        '${_oran(grup.fold<int>(0, (int t, BotLifeResult r) => t + r.diag.interactions), yil).padLeft(13)}  '
        '${_oran(grup.fold<int>(0, (int t, BotLifeResult r) => t + r.diag.eventsAnswered), yil).padLeft(8)}');
  }
  print('');
  print('"yatirim/firsat" = bot yatirim yapabilecek durumdayken');
  print('(18+, serbest para >= asgari alim) gercekten yaptigi oran.');
  print('1,00 her firsatta aliyor demektir — gercek oyuncu boyle');
  print('degildir; bu bir MEKANIKLIK isareti olur.');
  print('');
  print('Arketipler birbirinden gercekten farkli mi? (ayni optimuma');
  print('yakinsiyorlar mi?)');
  print('');
  print('arketip        uni     calisan  yatirim  ev     isyeri  evli   '
      'sabika');
  for (final PlayerArchetype tip in PlayerArchetype.values) {
    final List<BotLifeResult> grup = _korpus
        .where((BotLifeResult r) => r.archetype == tip)
        .toList(growable: false);
    final int n = grup.length;
    print('${tip.name.padRight(14)} '
        '${_yuzde(grup.where((BotLifeResult r) => r.wentToUniversity).length, n).padLeft(6)} '
        '${_yuzde(grup.where((BotLifeResult r) => r.everEmployed).length, n).padLeft(8)} '
        '${_yuzde(grup.where((BotLifeResult r) => r.investedEver).length, n).padLeft(7)} '
        '${_yuzde(grup.where((BotLifeResult r) => r.ownedHome).length, n).padLeft(6)} '
        '${_yuzde(grup.where((BotLifeResult r) => r.ownedBusiness).length, n).padLeft(6)} '
        '${_yuzde(grup.where((BotLifeResult r) => r.married).length, n).padLeft(6)} '
        '${_yuzde(grup.where((BotLifeResult r) => r.hasRecord).length, n).padLeft(6)}');
  }
  print('');
  print('SPOR VE CHECKUP BURADA "BIR KEZ YAPTI MI" DIYE OLCULMUYOR.');
  print('Ilk yazimda oyle olcmustum ve on arketipte de %95-100 cikti;');
  print('"bot fazla mekanik" diye yorumlamaya hazirdim. Yaniltici bir');
  print('metrikti: bot sporu YILDA BIR, profile bagli zarla deniyor');
  print('(rng < sportDesire). Girisimcide bile sportDesire 0,20; 57');
  print('yetiskin yilda 1-(0,80)^57 ~ %100 eder. Yani doygunluk botun');
  print('degil METRIGIN sorunuydu. Dogru olcu YILLIK SIKLIK:');
  print('');
  print('arketip        sportDesire  spor/yil   healthCare  checkup/yil');
  for (final PlayerArchetype tip in PlayerArchetype.values) {
    final List<BotLifeResult> grup = _korpus
        .where((BotLifeResult r) => r.archetype == tip)
        .toList(growable: false);
    final int yil =
        grup.fold<int>(0, (int t, BotLifeResult r) => t + r.diag.adultYears);
    if (yil == 0) continue;
    final BotProfile pr = kBotProfiles[tip]!;
    print('${tip.name.padRight(14)} '
        '${pr.sportDesire.toStringAsFixed(2).padLeft(11)}  '
        '${_oran(grup.fold<int>(0, (int t, BotLifeResult r) => t + r.diag.sportActions), yil).padLeft(8)}   '
        '${pr.healthCare.toStringAsFixed(2).padLeft(10)}  '
        '${_oran(grup.fold<int>(0, (int t, BotLifeResult r) => t + r.diag.checkupActions), yil).padLeft(11)}');
  }
  print('');
  print('Okuma kilavuzu: bir sutunda BUTUN arketipler ayni degere');
  print('yakinsiyorsa o davranis arketipten degil BOTUN ORTAK');
  print('KURALINDAN geliyor.');
  print('');
  print('Fark olcusu (en yuksek - en dusuk arketip yuzdesi):');
  _farkSatiri('universite', (BotLifeResult r) => r.wentToUniversity);
  _farkSatiri('yatirim', (BotLifeResult r) => r.investedEver);
  _farkSatiri('ev sahibi', (BotLifeResult r) => r.ownedHome);
  _farkSatiri('isletme', (BotLifeResult r) => r.ownedBusiness);
  _farkSatiri('evli', (BotLifeResult r) => r.married);
  _farkSatiri('sabika', (BotLifeResult r) => r.hasRecord);
  _farkSatiri('calisan', (BotLifeResult r) => r.everEmployed);
  print('');
  print('Kucuk fark = arketipler o boyutta ayrisMIyor. "calisan" bu');
  print('durumda: on arketipin hepsi %98-100 calisiyor. Bu OYUN degil');
  print('BOT: is bulma kurali arketipe hic bakmiyor, issiz kalmayi');
  print('secen bir oyuncu profili yok.');
}

void _farkSatiri(String ad, bool Function(BotLifeResult) kosul) {
  double enAz = 1.0;
  double enCok = 0.0;
  String azTip = '';
  String cokTip = '';
  for (final PlayerArchetype tip in PlayerArchetype.values) {
    final List<BotLifeResult> grup = _korpus
        .where((BotLifeResult r) => r.archetype == tip)
        .toList(growable: false);
    if (grup.isEmpty) continue;
    final double oran = grup.where(kosul).length / grup.length;
    if (oran < enAz) {
      enAz = oran;
      azTip = tip.name;
    }
    if (oran > enCok) {
      enCok = oran;
      cokTip = tip.name;
    }
  }
  print('  ${ad.padRight(14)} '
      '${(100 * (enCok - enAz)).toStringAsFixed(1).padLeft(5)} puan  '
      '(en cok $cokTip %${(100 * enCok).toStringAsFixed(0)} · '
      'en az $azTip %${(100 * enAz).toStringAsFixed(0)})');
}

// =====================================================================
// Yardımcılar
// =====================================================================

List<BotLifeResult> _olenler() =>
    _korpus.where((BotLifeResult r) => r.endedByDeath).toList(growable: false);

void _baslik(String s) {
  print('');
  print('=' * 70);
  print(s);
  print('=' * 70);
}

void _huni(
  List<BotLifeResult> hayatlar,
  List<(String, bool Function(BotDiag))> basamaklar,
) {
  if (hayatlar.isEmpty) {
    print('(hayat yok)');
    return;
  }
  final int taban = hayatlar.length;
  int onceki = taban;
  for (final (String ad, bool Function(BotDiag) kosul) in basamaklar) {
    final int adet = hayatlar.where((BotLifeResult r) => kosul(r.diag)).length;
    final String dusus = onceki == 0 || adet == onceki
        ? ''
        : '  (-${onceki - adet}, bu basamakta %'
            '${(100 * (onceki - adet) / onceki).toStringAsFixed(1)} kayip)';
    print('  ${ad.padRight(30)} ${adet.toString().padLeft(6)}  '
        '${_yuzde(adet, taban).padLeft(7)}$dusus');
    onceki = adet;
  }
}

String _yuzde(int adet, int toplam) =>
    toplam == 0 ? '-' : '%${(100 * adet / toplam).toStringAsFixed(1)}';

String _oran(int adet, int payda) =>
    payda == 0 ? '-' : (adet / payda).toStringAsFixed(2);

/// Binlik ₺ kısaltması: ölçüm çıktısı okunabilir olsun.
String _k(int v) {
  if (v == 0) return '0';
  final int bin = v ~/ 1000;
  return '${bin}k';
}

int _medyan(List<int> v) {
  if (v.isEmpty) return 0;
  final List<int> s = List<int>.of(v)..sort();
  return s[s.length ~/ 2];
}

double _medyanDouble(List<double> v) {
  if (v.isEmpty) return 0;
  final List<double> s = List<double>.of(v)..sort();
  return s[s.length ~/ 2];
}

int _ortalama(List<int> v) =>
    v.isEmpty ? 0 : v.fold<int>(0, (int t, int x) => t + x) ~/ v.length;
