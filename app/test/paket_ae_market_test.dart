/// Paket AE — yatırım tarafı: önemli olay bildirimleri ve sert düşüş.
///
/// **Neden bu testler var.** §26-29 oyuncunun portföyünün **neden**
/// düştüğünü anlamasını istiyor. AC'den beri şirket olayları vardı ve
/// `IncidentKind.opensNotice` tanımlıydı, ama hiçbir yerde okunmuyordu:
/// konkordato da, kayyum da, şirket kapanması da sessizce geçiyordu.
///
/// §27 ayrıca tek yılda −%20, −%30, −%40 gibi sonuçların **mümkün**
/// olmasını istiyor — ama sebepsiz tokat olarak değil, motorun kendi
/// kriz/sektör/skandal/balon kombinasyonlarından doğarak.
library;


import 'package:bir_omur/data/company_catalog.dart';
import 'package:bir_omur/domain/economy/investment_engine.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/investment.dart';
import 'package:bir_omur/domain/models/market_incident.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:flutter_test/flutter_test.dart';

GameState portfoylu(int seed, {int age = 35, int hisse = 4000000}) {
  final GameState s =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  return s.copyWith(
    player: s.player.copyWith(age: age, wallet: 2000000),
    education: s.education.copyWith(enrolled: false, finished: true),
    pendingEvent: null,
    investments: <Holding>[
      Holding.opened(typeId: 'hisse', amount: hisse, atAge: age),
    ],
  );
}

void main() {
  // ===================================================================
  // 1) Önemli olay bildirimi (§26, §28, §29)
  // ===================================================================
  group('portföy olay bildirimi', () {
    test('metinlerde kurgusal şirket adı geçer ve tavsiye yok (§26, §29)', () {
      final Company sirket = kAllCompanies.first;
      final String metin = InvestmentEngine.incidentNoticeText(
        MarketIncident(
          kind: IncidentKind.yonetimSkandali,
          age: 40,
          companyId: sirket.id,
          typeId: 'hisse',
          impact: -0.18,
        ),
      );
      expect(metin, contains(sirket.name));
      for (final String yasak in <String>[
        'al ',
        'sat ',
        'tavsiye',
        'öneririz',
        'kesin kazanç',
      ]) {
        expect(
          metin.toLowerCase(),
          isNot(contains(yasak)),
          reason: 'Metin tavsiye vermemeli: $metin',
        );
      }
    });

    test('her olay türünün bir metni var', () {
      for (final IncidentKind k in IncidentKind.values) {
        final String metin = InvestmentEngine.incidentNoticeText(
          MarketIncident(kind: k, age: 40, typeId: 'hisse'),
        );
        expect(metin, isNotEmpty, reason: k.name);
        expect(metin.length, greaterThan(20), reason: k.name);
      }
    });

    test('ciddi olayda bildirim çıkıyor (§26)', () {
      // 60 hayat × 45 yıl: konkordato, kayyum, kapanma gibi olaylar
      // yaşandığında pencerenin gerçekten açıldığını gör.
      int olayBildirimi = 0;
      int ciddiOlay = 0;
      for (int seed = 1; seed <= 60; seed++) {
        GameState s = portfoylu(seed, age: 30);
        for (int yas = 31; yas <= 75; yas++) {
          s = s.copyWith(player: s.player.copyWith(age: yas));
          final int oncekiOlay = s.market.incidents.length;
          s = InvestmentEngine.advanceYear(state: s, newAge: yas);
          for (final MarketIncident o
              in s.market.incidents.skip(oncekiOlay)) {
            if (o.kind.opensNotice && o.typeId == 'hisse') ciddiOlay++;
          }
          olayBildirimi += s.notices
              .where((PendingNotice n) => n.id.startsWith('piyasa-olay-'))
              .length;
          s = s.copyWith(notices: const <PendingNotice>[]);
        }
      }
      expect(ciddiOlay, greaterThan(0), reason: 'Hiç ciddi olay çıkmadı.');
      expect(
        olayBildirimi,
        greaterThan(0),
        reason: 'Ciddi olaylar oldu ama oyuncuya hiç bildirim çıkmadı.',
      );
    });

    test('bildirim yağmuru yok: yılda en çok bir pencere (§28)', () {
      for (int seed = 1; seed <= 25; seed++) {
        GameState s = portfoylu(seed, age: 30);
        for (int yas = 31; yas <= 80; yas++) {
          s = s.copyWith(
            player: s.player.copyWith(age: yas),
            notices: const <PendingNotice>[],
          );
          s = InvestmentEngine.advanceYear(state: s, newAge: yas);
          final int piyasaPenceresi = s.notices
              .where((PendingNotice n) =>
                  n.id.startsWith('piyasa-') ||
                  n.id.startsWith('piyasa-olay-'))
              .length;
          expect(piyasaPenceresi, lessThanOrEqualTo(1),
              reason: 'seed=$seed yaş=$yas');
        }
      }
    });

    test('portföyü olmayan oyuncuya piyasa bildirimi gelmez', () {
      GameState s = portfoylu(3, age: 30)
          .copyWith(investments: const <Holding>[]);
      for (int yas = 31; yas <= 70; yas++) {
        s = s.copyWith(player: s.player.copyWith(age: yas));
        s = InvestmentEngine.advanceYear(state: s, newAge: yas);
      }
      expect(
        s.notices.where((PendingNotice n) => n.id.startsWith('piyasa')),
        isEmpty,
      );
    });
  });

  // ===================================================================
  // 2) Sert düşüş motordan doğuyor (§27)
  // ===================================================================
  group('sert düşüş', () {
    test('tek yılda ciddi negatif sonuçlar mümkün ama nadir', () {
      // Ölçü: portföyün **gerçekleşen** yıllık değişimi (getiri + olay).
      // Hardcoded "−%40 olayı" yok; sayı motorun kendi kombinasyonundan
      // çıkmak zorunda.
      final List<double> oranlar = <double>[];
      for (int seed = 1; seed <= 120; seed++) {
        GameState s = portfoylu(seed, age: 25);
        for (int yas = 26; yas <= 80; yas++) {
          s = s.copyWith(player: s.player.copyWith(age: yas));
          final int once = s.holdingOf('hisse')?.value ?? 0;
          if (once <= 0) break;
          s = InvestmentEngine.advanceYear(state: s, newAge: yas);
          final int sonra = s.holdingOf('hisse')?.value ?? 0;
          oranlar.add((sonra - once) / once);
          // Portföyü sabit ölçekte tut: bileşik büyüme dağılımı bozmasın.
          s = s.copyWith(investments: <Holding>[
            Holding.opened(typeId: 'hisse', amount: 4000000, atAge: 25),
          ]);
        }
      }
      int kac(double esik) =>
          oranlar.where((double o) => o <= esik).length;
      final int n = oranlar.length;
      // ignore: avoid_print
      print('AE §27 — $n hisse yılı (%100 hisse): '
          '≤-20% ${kac(-0.20)} (%${(kac(-0.20) / n * 100).toStringAsFixed(2)}), '
          '≤-30% ${kac(-0.30)} (%${(kac(-0.30) / n * 100).toStringAsFixed(2)}), '
          '≤-40% ${kac(-0.40)} (%${(kac(-0.40) / n * 100).toStringAsFixed(2)})');
      expect(kac(-0.20), greaterThan(0), reason: '−%20 hiç görülmedi.');
      expect(kac(-0.30), greaterThan(0), reason: '−%30 hiç görülmedi.');
      expect(kac(-0.40), greaterThan(0), reason: '−%40 hiç görülmedi.');

      // **Ölçülen değer dondurulmuştur, seçilmiş değildir.**
      //
      // Bu dağılım AE'nin getirdiği bir şey değil: AD/1'in onaylı
      // kalibrasyonundan (hisse için ısı + rejim + fikrî oynaklık)
      // doğuyor ve AD/6 aynı kalibrasyonun 60 yıllık servet dağılımını
      // zaten ölçüp kabul etti. Sayıyı burada değiştirmek AD dengesini
      // geri almak olurdu; o bir ürün kararıdır ve Faho'ya Q-175/2 olarak
      // soruldu. Sınır ölçülen değerin (%16,3) biraz üstünde tutuldu ki
      // gerçek bir kayma yakalansın, dalgalanma yakalanmasın.
      expect(
        kac(-0.20) / n,
        lessThan(0.22),
        reason: 'Sert düşüş sıklığı ölçülen banttan kaydı.',
      );
    });

    test('dağıtılmış portföyde sert düşüş belirgin olarak seyrek', () {
      // §27'nin sayısı **%100 hisse** içindir. Çeşitlendirme kazanç
      // garantisi vermez ama sert yılı yumuşatır (AC §24); bu test
      // yukarıdaki oranın bağlamını kurar.
      const List<Holding> baslangic = <Holding>[
        Holding.opened(typeId: 'hisse', amount: 1500000, atAge: 25),
        Holding.opened(typeId: 'altin', amount: 1500000, atAge: 25),
        Holding.opened(typeId: 'fon', amount: 1000000, atAge: 25),
      ];
      final List<double> oranlar = <double>[];
      for (int seed = 1; seed <= 120; seed++) {
        GameState s =
            portfoylu(seed, age: 25).copyWith(investments: baslangic);
        for (int yas = 26; yas <= 80; yas++) {
          s = s.copyWith(player: s.player.copyWith(age: yas));
          final int once = s.investments
              .fold<int>(0, (int t, Holding h) => t + h.value);
          if (once <= 0) break;
          s = InvestmentEngine.advanceYear(state: s, newAge: yas);
          final int sonra = s.investments
              .fold<int>(0, (int t, Holding h) => t + h.value);
          oranlar.add((sonra - once) / once);
          s = s.copyWith(investments: baslangic);
        }
      }
      final int n = oranlar.length;
      final int sert = oranlar.where((double o) => o <= -0.20).length;
      // ignore: avoid_print
      print('AE §27 — $n dağıtılmış yıl: '
          '≤-20% $sert (%${(sert / n * 100).toStringAsFixed(2)})');
      expect(
        sert / n,
        lessThan(0.10),
        reason: 'Çeşitlendirme sert yılı yumuşatmalı.',
      );
    });
  });
}
