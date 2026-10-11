/// 2026 Türkiye alım gücü kalibrasyonunun denetimi.
///
/// Bu testler denge tartışmaz; kalibrasyonun **kendi içinde tutarlı**
/// kalmasını korur. Bir maaş bandının dışına çıkarsa, bir kategori
/// diğerine göre anlamsız bir yere düşerse burada yakalanır.
library;

import 'package:bir_omur/data/activity_catalog.dart';
import 'package:bir_omur/data/economy.dart';
import 'package:bir_omur/data/item_catalog.dart';
import 'package:bir_omur/data/job_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Çıpalar', () {
    test('net yıllık asgari ücret aylığın on iki katı', () {
      expect(Economy.netYearlyMinimumWage, Economy.netMonthlyMinimumWage * 12);
      expect(Economy.netYearlyMinimumWage, 336900);
    });

    test('brüt asgari ücret netten büyük', () {
      expect(
        Economy.grossMonthlyMinimumWage,
        greaterThan(Economy.netMonthlyMinimumWage),
      );
    });

    test('harcama kademeleri artan sırada', () {
      final List<int> kademeler = <int>[
        Economy.tierCokUfak,
        Economy.tierUfak,
        Economy.tierOrta,
        Economy.tierBuyuk,
        Economy.tierDayanikli,
      ];
      for (int i = 1; i < kademeler.length; i++) {
        expect(kademeler[i], greaterThan(kademeler[i - 1]));
      }
    });
  });

  group('Maaş kuralı', () {
    test('sabit maaşlı hiçbir iş asgari ücretin altında değil', () {
      // Faho'nun kesin kararı: tam zamanlı normal bir işin yıllık geliri,
      // özel gerekçe yoksa 12 aylık net asgari ücretin altında kalamaz.
      for (final JobType job in kJobCatalog) {
        if (!job.band.sabitMaasli) continue;
        expect(
          job.yearlySalary,
          greaterThanOrEqualTo(Economy.netYearlyMinimumWage),
          reason:
              '${job.id} (${job.name}) asgari ücretin altında: '
              '${job.yearlySalary} < ${Economy.netYearlyMinimumWage}',
        );
      }
    });

    test('her işin maaşı kendi bandının içinde', () {
      for (final JobType job in kJobCatalog) {
        expect(
          job.band.icerir(job.yearlySalary),
          isTrue,
          reason:
              '${job.id}: ${job.yearlySalary} ₺ '
              '"${job.band.label}" bandının (${job.band.minYearly}-'
              '${job.band.maxYearly}) dışında',
        );
      }
    });

    test('aynı bantta iki iş aynı parayı vermiyor', () {
      // Faho'nun kararı: "Aynı kategorideki işler tamamen aynı para
      // vermesin."
      for (final SalaryBand bant in SalaryBand.values) {
        final List<JobType> bantta = kJobCatalog
            .where((JobType j) => j.band == bant)
            .toList(growable: false);
        final Set<int> maaslar = bantta
            .map((JobType j) => j.yearlySalary)
            .toSet();
        expect(
          maaslar.length,
          bantta.length,
          reason:
              '${bant.label} bandında aynı maaşı veren işler var: '
              '${bantta.map((JobType j) => '${j.id}=${j.yearlySalary}')}',
        );
      }
    });

    test('bantlar arası sıralama bozulmamış', () {
      // Giriş bandının tavanı, yüksek uzmanlığın tabanının altında
      // kalmalı: sınıflar birbirinin içine geçmemeli.
      expect(
        SalaryBand.giris.maxYearly,
        lessThan(SalaryBand.yuksekUzmanlik.minYearly),
      );
      expect(
        SalaryBand.nitelikliHizmet.minYearly,
        greaterThanOrEqualTo(SalaryBand.giris.maxYearly),
      );
      expect(
        SalaryBand.profesyonel.maxYearly,
        greaterThan(SalaryBand.ofisUzmanlik.maxYearly),
      );
    });

    test('aylık gösterim yıllığın on ikide biri', () {
      for (final JobType job in kJobCatalog) {
        expect(
          job.monthlySalary,
          (job.yearlySalary / 12).round(),
          reason: job.id,
        );
      }
    });

    test('en yüksek maaş asgari ücretin makul bir katı', () {
      // Uçurum açılmasın: en yüksek iş, asgari ücretin on katını aşmasın.
      final int enYuksek = kJobCatalog
          .map((JobType j) => j.yearlySalary)
          .reduce((int a, int b) => a > b ? a : b);
      expect(
        enYuksek / Economy.netYearlyMinimumWage,
        lessThan(10),
        reason:
            'En yüksek maaş asgari ücretin ${enYuksek / Economy.netYearlyMinimumWage} katı',
      );
    });
  });

  group('Kategoriler arası oran', () {
    /// Bir eşyanın kaç aylık asgari ücrete denk geldiği.
    double ay(int tutar) => Economy.inMinimumWages(tutar);

    test('sinema bileti bir aylık asgari ücretin küçük bir kısmı', () {
      final ActivityAction sinema = kActivityActions.firstWhere(
        (ActivityAction a) => a.id == 'sinema',
        orElse: () => kActivityActions.first,
      );
      expect(ay(sinema.cost), lessThan(0.1), reason: 'sinema=${sinema.cost}');
    });

    test('otomobil ile konut arasındaki oran korunuyor', () {
      final int enUcuzAraba = kItemTypes
          .where((ItemType t) => t.kind == ItemKind.otomobil)
          .map((ItemType t) => t.baseValue)
          .reduce((int a, int b) => a < b ? a : b);
      final int enUcuzKonut = kItemTypes
          .where((ItemType t) => t.kind == ItemKind.konut)
          .map((ItemType t) => t.baseValue)
          .reduce((int a, int b) => a < b ? a : b);
      expect(
        enUcuzKonut,
        greaterThan(enUcuzAraba * 2),
        reason: 'En ucuz konut en ucuz arabanın iki katından ucuz olamaz',
      );
    });

    test('en ucuz konut bir ömürde alınabilir', () {
      // Ortalama bir maaşla, bütün geliri biriktirse kaç yıl?
      final int enUcuzKonut = kItemTypes
          .where((ItemType t) => t.kind == ItemKind.konut)
          .map((ItemType t) => t.baseValue)
          .reduce((int a, int b) => a < b ? a : b);
      final int ortaMaas = SalaryBand.ofisUzmanlik.minYearly;
      expect(
        enUcuzKonut / ortaMaas,
        lessThan(20),
        reason: 'En ucuz konut ${enUcuzKonut / ortaMaas} yıllık maaş eder',
      );
    });

    test('her eşya kategorisinde fiyat sıfırdan büyük', () {
      for (final ItemType t in kItemTypes) {
        expect(t.baseValue, greaterThan(0), reason: t.id);
      }
    });
  });
}
