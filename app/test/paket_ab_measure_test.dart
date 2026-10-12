import 'dart:math';

import 'package:bir_omur/data/shop_catalog.dart';
import 'package:bir_omur/domain/models/career.dart';
import 'package:bir_omur/data/job_catalog.dart';
import 'package:bir_omur/domain/economy/banking.dart';
import 'package:bir_omur/domain/economy/net_worth.dart';
import 'package:bir_omur/domain/economy/rental_engine.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/interaction/item_actions.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/loan.dart';
import 'package:bir_omur/domain/models/owned_item.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:bir_omur/domain/models/rental.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_flow.dart';

/// Paket AB ölçümleri (D-163).
///
/// Ölçer ve **bekçilik eder**: gayrimenkul sahipliği oyunun ekonomisini
/// kırıyorsa buradan görülür. Sayılar ekrana yazılır; iddialar geniş ama
/// gerekçeli, çünkü amaç kalibrasyonu dondurmak değil, bozulduğunu fark
/// etmek.
void main() {
  const ItemActions islem = ItemActions();

  GameState hayat({int age = 30, int wallet = 20000000}) {
    final GameState base =
        LifeGenerator.seeded(8).generate(mode: StartMode.tamamenRastgele);
    return base.copyWith(
      pendingEvent: null,
      notices: const <PendingNotice>[],
      player: base.player.copyWith(age: age, wallet: wallet),
      movedOut: true,
    );
  }

  test('OLCUM: 10.000 konut-yılı', () {
    // Her yol bir konut, 25 yıl boyunca kiraya verilmeye çalışılıyor.
    // Kiracı çıkınca yenisi aranıyor; piyasa kirası isteniyor.
    const int yol = 400;
    const int yil = 25;

    int konutYili = 0;
    int doluYil = 0;
    int sorunluYil = 0;
    int hasarliYil = 0;
    int toplamKira = 0;
    int toplamGider = 0;
    int toplamDeger = 0;
    final List<int> kalmaSureleri = <int>[];
    final List<double> brutGetiri = <double>[];
    final List<double> netGetiri = <double>[];

    for (int p = 0; p < yol; p++) {
      final Random rng = Random(7000 + p);
      GameState s = evAl(islem, hayat(), p);
      final String evId = s.properties.single.id;
      final int alisDegeri = RentalEngine.valueOf(s, s.properties.single);
      int kira = 0;
      int gider = 0;
      int? sozlesmeBasi;

      for (int y = 0; y < yil; y++) {
        final int yas = 31 + y;
        final OwnedItem ev = s.itemById(evId)!;
        // Boşsa kiracı ara.
        if (s.leaseOf(evId) == null) {
          final int istenen = RentalEngine.marketRent(s, ev);
          final List<TenantRecord> adaylar = RentalEngine.candidates(
            state: s.copyWith(player: s.player.copyWith(age: yas)),
            home: ev,
            askingRent: istenen,
          );
          if (adaylar.isNotEmpty) {
            s = RentalEngine.signLease(
              state: s.copyWith(player: s.player.copyWith(age: yas)),
              home: ev,
              tenant: adaylar[rng.nextInt(adaylar.length)],
              yearlyRent: istenen,
            ).state;
            sozlesmeBasi = yas;
          }
        }
        final bool doluyduk = s.leaseOf(evId) != null;
        final int oncekiKondisyon = s.itemById(evId)!.condition;

        final ({GameState state, RentalYear year}) adim =
            RentalEngine.advanceYear(
          state: s.copyWith(player: s.player.copyWith(age: yas)),
          newAge: yas,
          rng: rng,
        );
        s = adim.state;

        konutYili++;
        if (doluyduk) doluYil++;
        kira += adim.year.collected;
        gider += adim.year.costs;
        final Lease? sonra = s.leaseOf(evId);
        if (doluyduk && adim.year.collected == 0) sorunluYil++;
        if (s.itemById(evId)!.condition < oncekiKondisyon - 6) hasarliYil++;
        if (doluyduk && sonra == null && sozlesmeBasi != null) {
          kalmaSureleri.add(yas - sozlesmeBasi + 1);
          sozlesmeBasi = null;
        }
      }

      toplamKira += kira;
      toplamGider += gider;
      toplamDeger += alisDegeri;
      brutGetiri.add(kira / (alisDegeri * yil));
      netGetiri.add((kira - gider) / (alisDegeri * yil));
    }

    double ort(List<double> l) =>
        l.reduce((double a, double b) => a + b) / l.length;

    // ignore: avoid_print
    print('=== $konutYili KONUT-YILI ===');
    // ignore: avoid_print
    print('doluluk: %${(doluYil / konutYili * 100).toStringAsFixed(1)}');
    // ignore: avoid_print
    print('kiracinin ortalama kalma suresi: '
        '${(kalmaSureleri.isEmpty ? 0 : kalmaSureleri.reduce((int a, int b) => a + b) / kalmaSureleri.length).toStringAsFixed(1)} yil');
    // ignore: avoid_print
    print('kira hic gelmeyen yil: '
        '%${(sorunluYil / doluYil * 100).toStringAsFixed(1)}');
    // ignore: avoid_print
    print('belirgin hasar yili: '
        '%${(hasarliYil / konutYili * 100).toStringAsFixed(1)}');
    // ignore: avoid_print
    print('ortalama yillik gider: '
        '${(toplamGider / konutYili / 1000).toStringAsFixed(1)}k');
    // ignore: avoid_print
    print('brut kira getirisi: %${(ort(brutGetiri) * 100).toStringAsFixed(2)}');
    // ignore: avoid_print
    print('net kira getirisi: %${(ort(netGetiri) * 100).toStringAsFixed(2)}');
    // ignore: avoid_print
    print('toplam kira ${(toplamKira / 1000000).toStringAsFixed(1)}M · '
        'toplam gider ${(toplamGider / 1000000).toStringAsFixed(1)}M · '
        'toplam deger ${(toplamDeger / 1000000).toStringAsFixed(1)}M');

    expect(konutYili, greaterThanOrEqualTo(10000),
        reason: 'Ölçüm en az 10.000 konut-yılı olmalı');

    // --- Bekçiler -----------------------------------------------------
    // **Ölçülen doluluk %97,7.** Yüksek, çünkü buradaki ev sahibi ideal
    // davranıyor: kiracı çıktığı yıl hemen piyasa kirasıyla yeniden ilan
    // veriyor, indirime de razı. Gerçek oyuncu böyle davranmayabilir ve
    // fahiş kira isteyince doluluk hızla düşüyor (aşağıdaki aday
    // ölçümleri). İlk ölçümde bu sayı **%100** çıkmıştı: kiracı arama
    // hiç başarısız olmuyordu, ev bir yıl bile boş kalmıyordu. Kiracı
    // arama artık başarısız olabiliyor. Sınır ölçülene göre konuldu;
    // %100'e dönmesi kiracı aramanın yine hiç başarısız olmadığı
    // anlamına gelir ve bu bekçi onu yakalar.
    expect(doluYil / konutYili, inInclusiveRange(0.70, 0.99));
    // Kiracı ortalama birkaç yıl kalıyor; her yıl değişmiyor.
    expect(
      kalmaSureleri.reduce((int a, int b) => a + b) / kalmaSureleri.length,
      greaterThan(2.0),
    );
    // Kiranın hiç gelmediği yıl seyrek: kiracılar karikatür kötü değil.
    expect(sorunluYil / doluYil, lessThan(0.12));
    // Net getiri brütün altında ve **anlamlı biçimde** altında: bakım,
    // boşluk ve gider gerçekten ısırıyor.
    expect(ort(netGetiri), lessThan(ort(brutGetiri)));
    // "Parayı koy sonsuza kadar bedava gelir al" olmasın: net getiri
    // yatırım portföyünün hisse tarafını (yıllık %10) geçmesin.
    expect(ort(netGetiri), lessThan(0.10));
    expect(ort(netGetiri), greaterThan(0.0),
        reason: 'Kiralamak tamamen zarar da olmamalı');
  }, timeout: const Timeout(Duration(minutes: 10)));

  test('OLCUM: mortgage ile alıp kiraya vermenin net nakit akışı', () {
    // Krediyle ev alıp kiraya vermek teknik olarak mümkün. Ölçüm: kira
    // taksidi **her zaman** karşılamıyor, "bedava ev" exploit'i yok.
    // Senaryo: **maaşlı** biri konut kredisiyle ikinci ev alıp kiraya
    // veriyor. Geliri olmayan oyuncuya banka kredi vermiyor (doğru
    // davranış), bu yüzden ölçüm gerçek bir işle kuruluyor.
    final JobType is_ = kJobCatalog.reduce(
      (JobType a, JobType b) => a.yearlySalary > b.yearlySalary ? a : b,
    );
    GameState s = hayat(wallet: 1500000).copyWith(
      career: CareerState(
        jobId: is_.id,
        startedAtAge: 25,
        salary: is_.yearlySalary,
      ),
    );
    final ({GameState state, LoanDecision decision}) kredi = Banking.borrow(
      s,
      bank: Bank.bankavrupa,
      amount: Banking.minAmountFor(LoanPurpose.konut) * 3,
      termYears: Banking.maxTermFor(LoanPurpose.konut),
      purpose: LoanPurpose.konut,
    );
    // ignore: avoid_print
    print('MORTGAGE: ${kredi.decision.reason}');
    expect(kredi.decision.approved, isTrue,
        reason: 'Maaşlı oyuncuya konut kredisi çıkmalı');
    s = kredi.state;
    s = evAl(islem, s, 1);
    final OwnedItem ev = s.properties.single;
    final int kira = RentalEngine.marketRent(s, ev);
    final int taksit = s.loans
        .fold<int>(0, (int t, Loan l) => t + l.annualPayment);
    final int bakim =
        (RentalEngine.valueOf(s, ev) * RentalEngine.prototypeOnlyLetCostRate)
            .round();

    // ignore: avoid_print
    print('=== MORTGAGE + KIRA ===');
    // ignore: avoid_print
    print('ev degeri ${(RentalEngine.valueOf(s, ev) / 1000).toStringAsFixed(0)}k · '
        'yillik kira ${(kira / 1000).toStringAsFixed(0)}k · '
        'yillik taksit ${(taksit / 1000).toStringAsFixed(0)}k · '
        'bakim ${(bakim / 1000).toStringAsFixed(0)}k');
    // ignore: avoid_print
    print('net nakit akisi: '
        '${((kira - taksit - bakim) / 1000).toStringAsFixed(0)}k');

    expect(
      kira - taksit - bakim,
      lessThan(0),
      reason: 'Kira mortgage taksidini karşılarsa "bedava ev" exploit\'i olur',
    );
  });

  test('OLCUM: 100 hayat x 3 senaryo servet karşılaştırması', () {
    // Üç senaryo: hiç yatırım evi almayan, bir ev alan, olabildiğince ev
    // alan. Gayrimenkul sahipliği maaşlı çalışmayı anlamsızlaştırıyor mu?
    ({
      List<int> servet,
      Map<int, int> dagilim,
      List<int> evSahibiServeti,
    }) senaryo(int enFazlaEv) {
      final List<int> servetler = <int>[];
      final List<int> evSahibiServeti = <int>[];
      final Map<int, int> dagilim = <int, int>{};
      for (int seed = 0; seed < 100; seed++) {
        final GameController c = GameController(random: Random(seed));
        c.startNewLife(mode: StartMode.tamamenRastgele, seed: seed);
        int guard = 0;
        while (!c.state!.deceased && guard++ < 120) {
          final int oncekiYas = c.state!.player.age;
          resolveEducationChoices(c);
          c.ageUp();
          if (c.state!.player.age == oncekiYas) break;
          int ng = 0;
          while (c.state!.hasNotice && ng++ < 30) {
            c.dismissNotice();
          }
          resolvePendingEvents(c);

          final GameState s = c.state!;
          if (s.deceased || s.player.age < 25) continue;

          // Parası yeterse ev al ve kiraya ver.
          final int yatirimEvi = s.properties
              .where((OwnedItem i) => i.id != s.residenceItemId)
              .length;
          if (yatirimEvi < enFazlaEv) {
            final ShopProduct? urun = shopProductByTypeId('kucuk_daire');
            if (urun != null) {
              GameState alim = s;
              // Nakit yetmiyorsa **konut kredisi** dene. İlk ölçümde bu
              // yoktu ve hiçbir hayat ev alamadı: üç senaryo birebir aynı
              // sayıyı verdi. Gerçek oyuncunun elindeki araç kredi.
              if (alim.player.wallet < urun.price) {
                final ({GameState state, LoanDecision decision}) kredi =
                    Banking.borrow(
                  alim,
                  bank: Bank.bankavrupa,
                  amount: urun.price,
                  termYears: Banking.maxTermFor(LoanPurpose.konut),
                  purpose: LoanPurpose.konut,
                );
                if (kredi.decision.approved) alim = kredi.state;
              }
              if (alim.player.wallet >= urun.price) {
                final ItemActionResult r = islem.buy(
                  state: alim,
                  product: urun,
                  location: alim.player.currentCity,
                );
                if (r.outcome.applied) c.debugSetState(r.state);
              }
            }
          }
          // Boş yatırım evlerini kiraya ver.
          for (final OwnedItem ev in c.state!.properties) {
            final GameState g = c.state!;
            if (ev.id == g.residenceItemId) continue;
            if (g.leaseOf(ev.id) != null) continue;
            final int istenen = RentalEngine.marketRent(g, ev);
            final List<TenantRecord> adaylar = RentalEngine.candidates(
              state: g,
              home: ev,
              askingRent: istenen,
            );
            if (adaylar.isEmpty) continue;
            final RentalResult sonuc = RentalEngine.signLease(
              state: g,
              home: ev,
              tenant: adaylar.first,
              yearlyRent: istenen,
            );
            if (sonuc.outcome.applied) c.debugSetState(sonuc.state);
          }
        }
        final GameState son = c.state!;
        servetler.add(NetWorth.of(son));
        final int yatirimlik = son.properties
            .where((OwnedItem i) => i.id != son.residenceItemId)
            .length;
        if (yatirimlik > 0) evSahibiServeti.add(NetWorth.of(son));
        final int evSayisi = son.properties.length;
        final int kova = evSayisi == 0
            ? 0
            : evSayisi == 1
                ? 1
                : evSayisi <= 3
                    ? 2
                    : 4;
        dagilim[kova] = (dagilim[kova] ?? 0) + 1;
        c.dispose();
      }
      servetler.sort();
      return (
        servet: servetler,
        dagilim: dagilim,
        evSahibiServeti: evSahibiServeti,
      );
    }

    final ({
      List<int> servet,
      Map<int, int> dagilim,
      List<int> evSahibiServeti,
    }) hic = senaryo(0);
    final ({
      List<int> servet,
      Map<int, int> dagilim,
      List<int> evSahibiServeti,
    }) bir = senaryo(1);
    final ({
      List<int> servet,
      Map<int, int> dagilim,
      List<int> evSahibiServeti,
    }) cok = senaryo(99);

    int medyan(List<int> l) => l[l.length ~/ 2];
    int yuzde(List<int> l, double p) => l[(l.length * p).floor()];

    void bas(
      String ad,
      ({
        List<int> servet,
        Map<int, int> dagilim,
        List<int> evSahibiServeti,
      }) s,
    ) {
      // ignore: avoid_print
      print('$ad: medyan ${(medyan(s.servet) / 1000).toStringAsFixed(0)}k · '
          'iyi%10 ${(yuzde(s.servet, 0.90) / 1000).toStringAsFixed(0)}k · '
          'en yuksek ${(s.servet.last / 1000).toStringAsFixed(0)}k · '
          'ev dagilimi 0:${s.dagilim[0] ?? 0} 1:${s.dagilim[1] ?? 0} '
          '2-3:${s.dagilim[2] ?? 0} 4+:${s.dagilim[4] ?? 0}');
      // Asıl soru: **ev sahibi olabilen** hayatlar ne durumda? Medyan
      // hayat zaten eve ulaşamıyor, bu yüzden toplam medyan üç senaryoda
      // da aynı çıkıyor.
      if (s.evSahibiServeti.isEmpty) {
        // ignore: avoid_print
        print('  ev sahibi olabilen hayat: 0');
      } else {
        final List<int> es = List<int>.from(s.evSahibiServeti)..sort();
        // ignore: avoid_print
        print('  ev sahibi olabilen hayat: ${es.length} · '
            'medyan servetleri ${(medyan(es) / 1000).toStringAsFixed(0)}k');
      }
    }

    // ignore: avoid_print
    print('=== 100 HAYAT x 3 SENARYO ===');
    bas('hic ev almayan', hic);
    bas('bir yatirim evi', bir);
    bas('olabildigince ev', cok);
    // ignore: avoid_print
    print('KIYAS: bir ev / hic = '
        '${(medyan(bir.servet) / medyan(hic.servet)).toStringAsFixed(2)}x · '
        'cok ev / hic = '
        '${(medyan(cok.servet) / medyan(hic.servet)).toStringAsFixed(2)}x');

    // --- Bekçiler -----------------------------------------------------
    // Normal maaşlı oyuncu kolayca 15 ev sahibi olmasın: "olabildiğince
    // ev al" senaryosunda bile 4+ ev ile ölen karakter azınlıkta kalsın.
    expect((cok.dagilim[4] ?? 0), lessThan(50),
        reason: 'Maaşlı oyuncu kolayca mülk imparatoru olmamalı');
    // Gayrimenkul sahipliği maaşlı çalışmayı anlamsızlaştırmasın: çok ev
    // alan hayatın medyanı, hiç ev almayanın 12 katını geçmesin.
    expect(
      medyan(cok.servet) / medyan(hic.servet),
      lessThan(12),
      reason: 'Gayrimenkul ekonomiyi eziyor; kalibre edilmeli',
    );
    // Ama ev almak tamamen anlamsız da olmasın.
    expect(medyan(bir.servet), greaterThan((medyan(hic.servet) * 0.5).round()));
  }, timeout: const Timeout(Duration(minutes: 20)));
}

/// Ölçüm için konut alır. [seed] şehir seçer, böylece ölçüm tek şehre
/// sıkışmaz.
GameState evAl(ItemActions islem, GameState state, int seed) {
  const List<String> sehirler = <String>[
    'İstanbul',
    'Ankara',
    'İzmir',
    'Samsun',
    'Amasya',
    'Kayseri',
  ];
  final ItemActionResult r = islem.buy(
    state: state,
    product: shopProductByTypeId('kucuk_daire')!,
    location: sehirler[seed % sehirler.length],
  );
  expect(r.outcome.applied, isTrue, reason: r.outcome.text);
  return r.state;
}
