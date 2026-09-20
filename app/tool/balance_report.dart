// Denge ölçüm aracı.
//
// Oyunun içine **yeni bir sistem eklemez**; yalnızca mevcut kurallarla
// çok sayıda hayat simüle edip ölüm yaşı dağılımını ve ekonomi ölçeğini
// raporlar. Q-055 ve Q-058 kararları için ölçüm sağlar.
//
// Çalıştırma: app dizininde
//   flutter test tool/balance_report.dart
// Bu dosya `test/` altında değildir; normal test koşusunda çalışmaz.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:bir_omur/data/item_catalog.dart';
import 'package:bir_omur/data/job_catalog.dart';
import 'package:bir_omur/data/health_crisis_catalog.dart';
import 'package:bir_omur/domain/casino/casino_rules.dart';
import 'package:bir_omur/domain/life/health_crisis_engine.dart';
import 'package:bir_omur/domain/economy/living_costs.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/interaction/marriage_engine.dart';
import 'package:bir_omur/domain/interaction/parenthood.dart';
import 'package:bir_omur/domain/generation/life_progression.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';

/// Tek bir hayatı ölümüne kadar simüle eder.
({
  int deathAge,
  int parentLossBefore18,
  int familyDeaths,
  int crises,
  int crisisDeaths,
}) _simulateLife(int seed) {
  GameState state =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  final LifeProgression progression = LifeProgression(Random(seed));

  int ebeveynKaybi = 0;
  int aileKaybi = 0;
  int krizSayisi = 0;
  int krizOlumu = 0;

  while (!state.deceased && state.player.age < 130) {
    final Set<String> oncekiOlu = <String>{
      for (final Person p in state.people)
        if (!p.isAlive) p.id,
    };

    // Ekrandaki olay yaş ilerlemesini durdurur; ilk seçenekle çözülür.
    state = state.copyWith(pendingEvent: null);
    state = progression.advanceOneYear(state);

    // Sağlık krizi çıktıysa ödenebilir bir seçenekle yanıtlanır (D-044).
    if (state.hasPendingCrisis) {
      krizSayisi++;
      const HealthCrisisEngine motor = HealthCrisisEngine();
      final HealthCrisis kriz = state.pendingCrisis!.crisis!;
      final CrisisChoice secim = kriz.choices.firstWhere(
        (CrisisChoice c) => motor.canChoose(state, c),
        orElse: () => kriz.choices.last,
      );
      final CrisisResult sonuc =
          motor.respond(state, secim.id, Random(seed * 31 + krizSayisi));
      state = sonuc.outcome.applied
          ? sonuc.state
          : state.copyWith(pendingCrisis: null);
      if (state.deceased) krizOlumu++;
    }

    for (final Person p in state.people) {
      if (p.isAlive || oncekiOlu.contains(p.id)) continue;
      if (p.relation.kanBagi) aileKaybi++;
      final bool ebeveyn = p.relation == RelationType.anne ||
          p.relation == RelationType.baba;
      if (ebeveyn && state.player.age < 18) ebeveynKaybi++;
    }
  }

  return (
    deathAge: state.deathAge ?? state.player.age,
    parentLossBefore18: ebeveynKaybi,
    familyDeaths: aileKaybi,
    crises: krizSayisi,
    crisisDeaths: krizOlumu,
  );
}

String _yuzde(int sayi, int toplam) =>
    '${(sayi / toplam * 100).toStringAsFixed(1)}%';

void main() {
  test('denge raporu', _rapor, timeout: const Timeout(Duration(minutes: 10)));
}

void _rapor() {
  const int hayatSayisi = 5000;

  // ===================================================================
  // 1) Ölüm yaşı dağılımı (Q-058)
  // ===================================================================
  final List<int> yaslar = <int>[];
  int ebeveynKaybiOlanHayat = 0;
  int toplamAileKaybi = 0;
  int toplamKriz = 0;
  int krizOlumu = 0;

  for (int seed = 0; seed < hayatSayisi; seed++) {
    final ({
      int deathAge,
      int parentLossBefore18,
      int familyDeaths,
      int crises,
      int crisisDeaths,
    }) sonuc = _simulateLife(seed);
    yaslar.add(sonuc.deathAge);
    if (sonuc.parentLossBefore18 > 0) ebeveynKaybiOlanHayat++;
    toplamAileKaybi += sonuc.familyDeaths;
    toplamKriz += sonuc.crises;
    krizOlumu += sonuc.crisisDeaths;
  }
  yaslar.sort();

  int sayimAralik(int alt, int ust) =>
      yaslar.where((int y) => y >= alt && y < ust).length;

  final double ortalama =
      yaslar.reduce((int a, int b) => a + b) / yaslar.length;

  print('=== ÖLÜM YAŞI DAĞILIMI ($hayatSayisi hayat) ===');
  print('Ortalama ölüm yaşı : ${ortalama.toStringAsFixed(1)}');
  print('Medyan             : ${yaslar[yaslar.length ~/ 2]}');
  print('En küçük / en büyük: ${yaslar.first} / ${yaslar.last}');
  print('');
  for (final List<int> aralik in <List<int>>[
    <int>[0, 18],
    <int>[18, 40],
    <int>[40, 60],
    <int>[60, 70],
    <int>[70, 80],
    <int>[80, 90],
    <int>[90, 100],
    <int>[100, 200],
  ]) {
    final int sayi = sayimAralik(aralik[0], aralik[1]);
    print('${aralik[0].toString().padLeft(3)}-'
        '${aralik[1].toString().padLeft(3)} yaş : '
        '${sayi.toString().padLeft(5)}  ${_yuzde(sayi, hayatSayisi)}');
  }
  print('');
  print('18 yaşından önce ebeveyn kaybı yaşayan hayat: '
      '$ebeveynKaybiOlanHayat (${_yuzde(ebeveynKaybiOlanHayat, hayatSayisi)})');
  print('Hayat başına ortalama yakın aile kaybı      : '
      '${(toplamAileKaybi / hayatSayisi).toStringAsFixed(1)}');
  print('Hayat başına ortalama sağlık krizi          : '
      '${(toplamKriz / hayatSayisi).toStringAsFixed(2)}');
  print('Krizle sonuçlanan ölüm oranı                : '
      '${_yuzde(krizOlumu, hayatSayisi)}');

  // ===================================================================
  // 1b) Kuşak farkları (Q-058: NPC yaşları tutarlı olmalı)
  // ===================================================================
  final List<int> ebeveynFarki = <int>[];
  final List<int> buyukEbeveynFarki = <int>[];
  int tutarsizEbeveyn = 0;
  int tutarsizBuyuk = 0;

  for (int seed = 0; seed < hayatSayisi; seed++) {
    final GameState dogum =
        LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
    final int oyuncuYas = dogum.player.age;
    for (final Person p in dogum.people) {
      final int fark = p.age - oyuncuYas;
      switch (p.relation) {
        case RelationType.anne:
        case RelationType.baba:
          ebeveynFarki.add(fark);
          // 16 yaşından küçükken çocuk sahibi olmak tutarsız sayılır.
          if (fark < 16) tutarsizEbeveyn++;
        case RelationType.anneanne:
        case RelationType.babaanne:
        case RelationType.anneTarafiDede:
        case RelationType.babaTarafiDede:
          buyukEbeveynFarki.add(fark);
          if (fark < 32) tutarsizBuyuk++;
        default:
          break;
      }
    }
  }

  int enKucuk(List<int> l) => l.reduce(min);
  int enBuyuk(List<int> l) => l.reduce(max);
  double ort(List<int> l) => l.reduce((int a, int b) => a + b) / l.length;

  print('');
  print('=== KUŞAK FARKLARI (doğum anı, $hayatSayisi hayat) ===');
  print('Ebeveyn - oyuncu yaş farkı      : '
      'en az ${enKucuk(ebeveynFarki)}, ortalama '
      '${ort(ebeveynFarki).toStringAsFixed(1)}, en çok '
      '${enBuyuk(ebeveynFarki)}');
  print('16 yaşından küçükken ebeveyn olan kayıt: $tutarsizEbeveyn');
  if (buyukEbeveynFarki.isNotEmpty) {
    print('Büyükebeveyn - oyuncu yaş farkı : '
        'en az ${enKucuk(buyukEbeveynFarki)}, ortalama '
        '${ort(buyukEbeveynFarki).toStringAsFixed(1)}, en çok '
        '${enBuyuk(buyukEbeveynFarki)}');
    print('32 yıldan küçük iki kuşak farkı        : $tutarsizBuyuk');
  }

  // ===================================================================
  // 2) Ekonomi: gider sonrası birikim ve erişim süresi (Q-055, D-039)
  // ===================================================================
  print('');
  print('=== YILLIK GIDER VE BIRIKIM (D-039) ===');
  print('Durum'.padRight(22) +
      'taban'.padLeft(10) +
      'gelir payı'.padLeft(12));
  for (final LivingSituation durum in LivingSituation.values) {
    final List<CostItem> kalemler = LivingCosts.prototypeOnlyItems[durum]!;
    final int taban =
        kalemler.fold(0, (int t, CostItem k) => t + k.base);
    final double oran =
        kalemler.fold(0.0, (double t, CostItem k) => t + k.incomeShare);
    print(durum.label.padRight(22) +
        '$taban ₺'.padLeft(10) +
        '${(oran * 100).toStringAsFixed(0)}%'.padLeft(12));
  }

  int giderFor(LivingSituation durum, int gelir) =>
      LivingCosts.prototypeOnlyItems[durum]!
          .fold(0, (int t, CostItem k) => t + k.amountFor(gelir));

  print('');
  print('Meslek'.padRight(22) +
      'ailede'.padLeft(14) +
      'kirada'.padLeft(14) +
      'kendi evinde'.padLeft(16));
  for (final JobType job in kJobCatalog) {
    final int ailede =
        job.yearlySalary - giderFor(LivingSituation.aileYaninda, job.yearlySalary);
    final int kirada =
        job.yearlySalary - giderFor(LivingSituation.kirada, job.yearlySalary);
    final int kendi = job.yearlySalary -
        giderFor(LivingSituation.kendiEvinde, job.yearlySalary);
    print(job.name.padRight(22) +
        '$ailede ₺'.padLeft(14) +
        '$kirada ₺'.padLeft(14) +
        '$kendi ₺'.padLeft(16));
  }

  // Evlilik ve çocuk: kendi hanesini kuran karakterin yükü (Q-063, Q-064).
  print('');
  print('=== AİLE EKONOMİSİ: EVLİLİK VE ÇOCUK (Paket E1-E2) ===');
  print('Nikâh masrafı: ${MarriageEngine.prototypeOnlyWeddingCost} ₺ · '
      'doğum masrafı: ${Parenthood.prototypeOnlyBirthCost} ₺ · '
      'boşanmada nakit payı: '
      '%${(MarriageEngine.prototypeOnlyDivorceShare * 100).toStringAsFixed(0)}');
  print('Evli karakter kendi hanesini kurar; aşağıdaki birikim '
      '"kirada" düzenine göredir.');
  print('');
  print('Meslek'.padRight(22) +
      'çocuksuz'.padLeft(14) +
      '1 çocuk'.padLeft(14) +
      '2 çocuk'.padLeft(14) +
      '3 çocuk'.padLeft(14));
  for (final JobType job in kJobCatalog) {
    final int taban =
        job.yearlySalary - giderFor(LivingSituation.kirada, job.yearlySalary);
    final int cocukGideri =
        LivingCosts.prototypeOnlyChildCost.amountFor(job.yearlySalary);
    print(job.name.padRight(22) +
        '$taban ₺'.padLeft(14) +
        '${taban - cocukGideri} ₺'.padLeft(14) +
        '${taban - cocukGideri * 2} ₺'.padLeft(14) +
        '${taban - cocukGideri * 3} ₺'.padLeft(14));
  }

  print('');
  print('=== KAÇ YILLIK BIRIKIMLE? (bisiklet / ikinci el oto / küçük daire) ===');
  const List<String> hedefler = <String>[
    'bisiklet',
    'otomobil_ikinci_el',
    'kucuk_daire',
  ];
  for (final LivingSituation durum in <LivingSituation>[
    LivingSituation.aileYaninda,
    LivingSituation.kirada,
    LivingSituation.kendiEvinde,
  ]) {
    print('');
    print('--- ${durum.label} ---');
    final StringBuffer baslik = StringBuffer('Meslek'.padRight(22));
    for (final String id in hedefler) {
      baslik.write(itemTypeOrFallback(id).name.padLeft(22));
    }
    print(baslik);
    for (final JobType job in kJobCatalog) {
      final int birikim =
          job.yearlySalary - giderFor(durum, job.yearlySalary);
      final StringBuffer satir = StringBuffer(job.name.padRight(22));
      for (final String id in hedefler) {
        final int fiyat = itemTypeOrFallback(id).baseValue;
        final String deger = birikim <= 0
            ? 'birikim yok'
            : '${(fiyat / birikim).toStringAsFixed(1)} yıl';
        satir.write(deger.padLeft(22));
      }
      print(satir);
    }
  }

  // ===================================================================
  // 2c) Bahis bütçesi (D-040)
  // ===================================================================
  print('');
  print('=== YILLIK BAHIS BÜTÇESI (D-040) ===');
  print('Durum'.padRight(34) +
      'bütçe'.padLeft(12) +
      'tek bahis'.padLeft(12) +
      'adımlar'.padLeft(30));
  void butceSatiri(String etiket, int kullanilabilirGelir, int cuzdan) {
    final int butce = CasinoRules.prototypeOnlyYearlyBudget(
      disposableIncome: kullanilabilirGelir,
      wallet: cuzdan,
    );
    final int enFazla = CasinoRules.prototypeOnlyMaxBet(butce);
    final List<int> adimlar = CasinoRules.prototypeOnlyBetSteps(enFazla);
    print(etiket.padRight(34) +
        '$butce ₺'.padLeft(12) +
        '$enFazla ₺'.padLeft(12) +
        adimlar.join('/').padLeft(30));
  }

  for (final JobType job in kJobCatalog) {
    final int kirada =
        job.yearlySalary - giderFor(LivingSituation.kirada, job.yearlySalary);
    butceSatiri('${job.name} (kirada, cüzdan 20k)', kirada, 20000);
  }
  butceSatiri('İşsiz, cüzdan 5.000 ₺', 0, 5000);
  butceSatiri('İşsiz mirasçı, cüzdan 500.000 ₺', 0, 500000);
  butceSatiri('İşsiz mirasçı, cüzdan 3.000.000 ₺', 0, 3000000);

  // ===================================================================
  // 3) Meslekler arası fark (Q-055)
  // ===================================================================
  print('');
  print('=== MESLEKLER ARASI GELİR FARKI ===');
  final List<int> maaslar =
      kJobCatalog.map((JobType j) => j.yearlySalary).toList()..sort();
  print('En düşük: ${maaslar.first} ₺/yıl · En yüksek: ${maaslar.last} ₺/yıl '
      '· Oran: ${(maaslar.last / maaslar.first).toStringAsFixed(1)}x');
}
