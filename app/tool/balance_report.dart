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
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/generation/life_progression.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';

/// Tek bir hayatı ölümüne kadar simüle eder.
({int deathAge, int parentLossBefore18, int familyDeaths}) _simulateLife(
  int seed,
) {
  GameState state =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  final LifeProgression progression = LifeProgression(Random(seed));

  int ebeveynKaybi = 0;
  int aileKaybi = 0;

  while (!state.deceased && state.player.age < 130) {
    final Set<String> oncekiOlu = <String>{
      for (final Person p in state.people)
        if (!p.isAlive) p.id,
    };

    // Ekrandaki olay yaş ilerlemesini durdurur; ilk seçenekle çözülür.
    state = state.copyWith(pendingEvent: null);
    state = progression.advanceOneYear(state);

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
  );
}

String _yuzde(int sayi, int toplam) =>
    '${(sayi / toplam * 100).toStringAsFixed(1)}%';

void main() {
  test('denge raporu', _rapor, timeout: const Timeout(Duration(minutes: 10)));
}

void _rapor() {
  const int hayatSayisi = 500;

  // ===================================================================
  // 1) Ölüm yaşı dağılımı (Q-058)
  // ===================================================================
  final List<int> yaslar = <int>[];
  int ebeveynKaybiOlanHayat = 0;
  int toplamAileKaybi = 0;

  for (int seed = 0; seed < hayatSayisi; seed++) {
    final ({int deathAge, int parentLossBefore18, int familyDeaths}) sonuc =
        _simulateLife(seed);
    yaslar.add(sonuc.deathAge);
    if (sonuc.parentLossBefore18 > 0) ebeveynKaybiOlanHayat++;
    toplamAileKaybi += sonuc.familyDeaths;
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
  // 2) Ekonomi ölçeği (Q-055)
  // ===================================================================
  print('');
  print('=== EKONOMİ ÖLÇEĞİ: KAÇ YILLIK MAAŞ? ===');
  const List<String> hedefler = <String>[
    'bisiklet',
    'telefon',
    'motosiklet_ekonomik',
    'otomobil_ikinci_el',
    'otomobil_ekonomik',
    'kucuk_daire',
    'standart_daire',
  ];

  // Gider yok (bugünkü durum) ve giderin maaşın %50'si / %70'i olduğu
  // iki örnek senaryo. Gider sistemi henüz yazılmadı; bu yalnızca ölçüm.
  for (final double giderOrani in <double>[0.0, 0.5, 0.7]) {
    print('');
    print('--- Yillik gider: maasin yuzde '
        '${(giderOrani * 100).round()} kadari ---');
    final StringBuffer baslik = StringBuffer('Meslek'.padRight(22));
    for (final String id in hedefler) {
      baslik.write(itemTypeOrFallback(id).name.padLeft(20));
    }
    print(baslik);

    for (final JobType job in kJobCatalog) {
      final double birikim = job.yearlySalary * (1 - giderOrani);
      final StringBuffer satir = StringBuffer(job.name.padRight(22));
      for (final String id in hedefler) {
        final int fiyat = itemTypeOrFallback(id).baseValue;
        final String deger = birikim <= 0
            ? 'ulaşılamaz'
            : '${(fiyat / birikim).toStringAsFixed(1)} yıl';
        satir.write(deger.padLeft(20));
      }
      print(satir);
    }
  }

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
