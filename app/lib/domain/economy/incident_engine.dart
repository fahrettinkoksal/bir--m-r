/// Şirket ve piyasa olayları motoru (Paket AC).
///
/// **Neden var.** Yıllık rejim tek başına yetmiyordu: ölçümde yatırım
/// uzun vadede neredeyse garanti kazanıyordu, çünkü kaybettirecek bir
/// olay yoktu. Bu motor rejimin üstüne **tek tek olaylar** koyar:
/// konkordato, iflas, kayyum, işlem sırasının kapanması, fon tasfiyesi,
/// sermaye artırımı, sektör krizi.
///
/// **Kurallar:**
/// * Olaylar **her yıl olmaz.** Çoğu yıl sessiz geçer.
/// * Tek bir şirketin batışı sepeti **sıfırlamaz** (§9): etki şirketin
///   sepetteki payı kadardır ve üstünde sert bir tavan vardır.
/// * Aynı olay **iki kez uygulanmaz**: kayıt `MarketState.incidents`
///   içinde durur ve şirket durumu ilerler.
/// * Şirket durumu **kademeli** ilerler: normal → inceleme/sıkıntı →
///   konkordato/kayyum → kapandı. Hiçbir şirket tek yılda sağlıklıdan
///   iflasa gitmez; oyuncu haberleri görür.
/// * Zar **piyasanın kendi akışından** gelir (`InvestmentEngine
///   .marketSeed`), oyunun ana akışından değil. Aynı hayatın aynı yılı
///   her zaman aynı olayı verir; kayıt geri yüklenerek olay yeniden
///   çevrilemez.
/// * Hiçbir metin **yatırım tavsiyesi vermez** ve gerçek şirket, banka,
///   kurum ya da kişi adı geçmez.
///
/// Bütün ihtimaller ve oranlar `prototypeOnly`'dir (Q-168).
library;

import 'dart:math';

import '../../data/company_catalog.dart';
import '../models/market_incident.dart';
import '../models/market_state.dart';

/// Bir yılın olay sonucu.
class IncidentOutcome {
  IncidentOutcome({
    required this.incidents,
    required this.companyStatus,
    required this.halts,
    required this.multipliers,
    required this.cashDelta,
  });

  /// Bu yıl gerçekleşen olaylar.
  final List<MarketIncident> incidents;

  /// Güncellenmiş şirket durumları.
  final Map<String, String> companyStatus;

  /// Yürüyen işlem durmaları (biten temizlenmiş).
  final List<TradingHalt> halts;

  /// Varlık kimliği -> pozisyona uygulanacak **ek** çarpan (1,0 = etkisiz).
  ///
  /// Yılın normal getirisinin **üstüne** uygulanır. Ayrı tutulmasının
  /// sebebi şu: getiri endeksi bütün oyuncular için ortaktır, olay etkisi
  /// ise portföye uygulanır — endeksi olayla oynatmak, portföyü olmayan
  /// oyuncunun da fiyatını kaydırırdı ve iki kez sayılırdı.
  final Map<String, double> multipliers;

  /// Cüzdana giren/çıkan net tutar (temettü, tasfiye). ₺.
  final int cashDelta;

  bool get isEmpty => incidents.isEmpty;
}

abstract final class IncidentEngine {
  // -------------------------------------------------------------------
  // Kalibrasyon — hepsi prototypeOnly, ölçümle seçildi (Q-168)
  // -------------------------------------------------------------------

  /// prototypeOnly: bir yılda **herhangi bir** şirket olayı çıkma ihtimali.
  ///
  /// Rejimle ölçeklenir: kriz yılında belirgin biçimde artar. Sayı
  /// ölçümle seçildi; ölçüm 10.000+ piyasa yılında batış oranını ve
  /// portföy dağılımını raporluyor.
  static const double prototypeOnlyCompanyEventChance = 0.16;

  /// prototypeOnly: rejime göre olay ihtimali çarpanı.
  static const Map<MarketRegime, double> prototypeOnlyRegimeEventFactor =
      <MarketRegime, double>{
    MarketRegime.durgun: 1.15,
    MarketRegime.normal: 0.85,
    MarketRegime.guclu: 0.55,
    MarketRegime.kriz: 2.40,
    MarketRegime.toparlanma: 1.30,
  };

  /// prototypeOnly: fon olayı çıkma ihtimali (yıllık).
  ///
  /// Fon hisseden **daha güvenli ama güvenli değil**: olay ihtimali daha
  /// düşük ve etkileri daha ılımlı.
  static const double prototypeOnlyFundEventChance = 0.055;

  /// prototypeOnly: piyasa geneli olay ihtimali (panik, ani yükseliş).
  static const double prototypeOnlyMarketEventChance = 0.07;

  /// prototypeOnly: şirket durumunun bir kademe **kötüleşme** ihtimali,
  /// kırılganlıkla ölçeklenir.
  static const double prototypeOnlyEscalateChance = 0.42;

  /// prototypeOnly: sıkıntıdaki şirketin **toparlanma** ihtimali.
  ///
  /// Sıfır değil: her kötü haber iflasla bitmez, bazı şirketler düzelir.
  static const double prototypeOnlyRecoverChance = 0.30;

  /// prototypeOnly: olay başına sepete yansıyan oranlar.
  static const Map<IncidentKind, double> prototypeOnlyBasketImpact =
      <IncidentKind, double>{
    IncidentKind.regulatorIncelemesi: -0.015,
    IncidentKind.yonetimSkandali: -0.035,
    IncidentKind.maliSikinti: -0.045,
    IncidentKind.konkordato: -0.075,
    IncidentKind.kayyum: -0.060,
    // İflasın etkisi şirketin payından hesaplanır; buradaki değer
    // yalnızca taban.
    IncidentKind.iflas: -0.030,
    IncidentKind.sermayeArtirimi: -0.028,
    IncidentKind.temettu: 0.0,
    IncidentKind.satinAlma: 0.055,
    IncidentKind.sektorKrizi: -0.055,
    IncidentKind.sektorPatlamasi: 0.050,
  };

  /// prototypeOnly: fon olaylarının etkisi.
  static const Map<IncidentKind, double> prototypeOnlyFundImpact =
      <IncidentKind, double>{
    IncidentKind.fonYoneticiDegisti: -0.012,
    IncidentKind.fonYanlisYatirim: -0.065,
    IncidentKind.fonStratejiDegisti: -0.008,
    IncidentKind.fonBirlesti: -0.005,
    // Tasfiye pozisyonu nakde çevirir; ayrıca değer kaybı yazılmaz.
    IncidentKind.fonTasfiye: 0.0,
  };

  /// prototypeOnly: piyasa geneli olayların etkisi (bütün riskli varlıklar).
  static const double prototypeOnlyPanicImpact = -0.085;
  static const double prototypeOnlySurgeImpact = 0.075;

  /// prototypeOnly: temettünün pozisyona oranı.
  static const double prototypeOnlyDividendRate = 0.022;

  /// prototypeOnly: panikte işlem durma ihtimali.
  static const double prototypeOnlyPanicHaltChance = 0.35;

  // -------------------------------------------------------------------
  // Yılı işlemek
  // -------------------------------------------------------------------

  /// Bu yılın olaylarını çeker ve etkilerini hesaplar.
  ///
  /// [basketValue] oyuncunun `hisse` pozisyonunun değeri, [fundValue] ise
  /// `fon` pozisyonunun değeri — temettü ve tasfiye tutarları buradan
  /// çıkar. Portföyü olmayan oyuncuda şirket durumu **yine ilerler**
  /// (dünya oyuncuyu beklemez) ama nakit hareketi olmaz.
  static IncidentOutcome advance({
    required MarketState state,
    required MarketRegime regime,
    required int newAge,
    required int basketValue,
    required int fundValue,
    required Random rng,
  }) {
    final List<MarketIncident> olaylar = <MarketIncident>[];
    final Map<String, String> durumlar = <String, String>{...state.companyStatus};
    final Map<String, double> carpanlar = <String, double>{};
    int nakit = 0;

    // Biten durmaları temizle; sürenler kalsın.
    final List<TradingHalt> durmalar = state.halts
        .where((TradingHalt h) => h.activeAt(newAge))
        .toList(growable: true);

    void carp(String typeId, double oran) {
      final double mevcut = carpanlar[typeId] ?? 1.0;
      carpanlar[typeId] = mevcut * (1 + oran);
    }

    final double rejimCarpani = prototypeOnlyRegimeEventFactor[regime] ?? 1.0;

    // ---- 1) Şirket olayları -------------------------------------------
    if (rng.nextDouble() < prototypeOnlyCompanyEventChance * rejimCarpani) {
      final Company? sirket = _pickCompany(state, rng);
      if (sirket != null) {
        final CompanyStatus mevcut = state.statusOf(sirket.id);
        final ({IncidentKind kind, CompanyStatus next}) adim =
            _nextCompanyStep(mevcut, sirket, regime, rng);
        durumlar[sirket.id] = adim.next.name;

        double etki = prototypeOnlyBasketImpact[adim.kind] ?? 0;
        int olayNakit = 0;

        if (adim.kind == IncidentKind.iflas) {
          // **Sepet sıfırlanmaz (§9).** Etki şirketin payı kadardır;
          // üstünde sert bir tavan var.
          final double paydan =
              sirket.basketWeight * kFailureWeightPassThrough;
          etki = -(paydan < kSingleFailureBasketCap
              ? paydan
              : kSingleFailureBasketCap);
        } else if (adim.kind == IncidentKind.temettu) {
          olayNakit = (basketValue * prototypeOnlyDividendRate).round();
          nakit += olayNakit;
        }

        if (etki != 0) carp('hisse', etki);

        // Kayyum ve konkordato işlemi durdurur: oyuncu satmak istese de
        // satamaz (§4, §5).
        if (adim.kind == IncidentKind.kayyum ||
            adim.kind == IncidentKind.konkordato) {
          durmalar.add(TradingHalt(
            typeId: 'hisse',
            untilAge: newAge +
                kHaltMinYears +
                rng.nextInt(kHaltMaxYears - kHaltMinYears + 1),
            reason: '${sirket.name} için işlemler geçici olarak durduruldu.',
          ));
        }

        olaylar.add(MarketIncident(
          kind: adim.kind,
          age: newAge,
          companyId: sirket.id,
          typeId: 'hisse',
          impact: etki,
          cashDelta: olayNakit,
        ));
      }
    }

    // ---- 2) Sektör olayları -------------------------------------------
    if (rng.nextDouble() < prototypeOnlyCompanyEventChance * 0.45 * rejimCarpani) {
      final CompanySector sektor =
          CompanySector.values[rng.nextInt(CompanySector.values.length)];
      final bool kriz = regime == MarketRegime.kriz ||
          regime == MarketRegime.durgun ||
          rng.nextDouble() < 0.55;
      final IncidentKind tur =
          kriz ? IncidentKind.sektorKrizi : IncidentKind.sektorPatlamasi;
      // Sektörün sepetteki toplam payı kadar etki.
      final double pay = companiesInSector(sektor)
          .where((Company c) => state.statusOf(c.id).isActive)
          .fold<double>(0, (double t, Company c) => t + c.basketWeight);
      if (pay > 0) {
        final double taban = prototypeOnlyBasketImpact[tur] ?? 0;
        final double etki = taban * (pay / 0.20).clamp(0.4, 1.8);
        carp('hisse', etki);
        olaylar.add(MarketIncident(
          kind: tur,
          age: newAge,
          typeId: 'hisse',
          impact: etki,
        ));
      }
    }

    // ---- 3) Fon olayları ----------------------------------------------
    if (rng.nextDouble() < prototypeOnlyFundEventChance) {
      final List<IncidentKind> havuz = <IncidentKind>[
        IncidentKind.fonYoneticiDegisti,
        IncidentKind.fonYoneticiDegisti,
        IncidentKind.fonStratejiDegisti,
        IncidentKind.fonYanlisYatirim,
        IncidentKind.fonBirlesti,
        IncidentKind.fonTasfiye,
      ];
      final IncidentKind tur = havuz[rng.nextInt(havuz.length)];
      final double etki = prototypeOnlyFundImpact[tur] ?? 0;
      if (etki != 0) carp('fon', etki);
      olaylar.add(MarketIncident(
        kind: tur,
        age: newAge,
        typeId: 'fon',
        impact: etki,
        // Tasfiyede pozisyon nakde döner; tutarı motor uygular.
        cashDelta: tur == IncidentKind.fonTasfiye ? fundValue : 0,
      ));
    }

    // ---- 4) Piyasa geneli ---------------------------------------------
    if (rng.nextDouble() < prototypeOnlyMarketEventChance * rejimCarpani) {
      final bool panik = regime == MarketRegime.kriz ||
          regime == MarketRegime.toparlanma ||
          rng.nextDouble() < 0.5;
      if (panik) {
        carp('hisse', prototypeOnlyPanicImpact);
        carp('fon', prototypeOnlyPanicImpact * 0.6);
        olaylar.add(MarketIncident(
          kind: IncidentKind.piyasaPanigi,
          age: newAge,
          impact: prototypeOnlyPanicImpact,
        ));
        // Devre kesici: işlemler kısa süre durabilir (§15).
        if (rng.nextDouble() < prototypeOnlyPanicHaltChance) {
          durmalar.add(TradingHalt(
            typeId: 'hisse',
            untilAge: newAge + kHaltMinYears,
            reason: 'Sert satış sonrası işlemlere ara verildi.',
          ));
        }
      } else {
        carp('hisse', prototypeOnlySurgeImpact);
        carp('fon', prototypeOnlySurgeImpact * 0.6);
        olaylar.add(MarketIncident(
          kind: IncidentKind.aniYukselis,
          age: newAge,
          impact: prototypeOnlySurgeImpact,
        ));
      }
    }

    return IncidentOutcome(
      incidents: olaylar,
      companyStatus: durumlar,
      halts: durmalar,
      multipliers: carpanlar,
      cashDelta: nakit,
    );
  }

  /// Olaya konu olacak şirketi seçer.
  ///
  /// Zaten kapanmış şirketler elenir. Ağırlık **kırılganlık × sepet payı**:
  /// büyük ve kırılgan şirketin haberi daha olası, ama küçük şirket de
  /// haber olabilir.
  static Company? _pickCompany(MarketState state, Random rng) {
    final List<Company> acik = kCompanyCatalog
        .where((Company c) => state.statusOf(c.id).isActive)
        .toList(growable: false);
    if (acik.isEmpty) return null;
    final List<double> agirliklar = acik
        .map((Company c) => c.fragility * (0.4 + c.basketWeight))
        .toList(growable: false);
    final double toplam = agirliklar.fold<double>(0, (double a, double b) => a + b);
    if (toplam <= 0) return acik[rng.nextInt(acik.length)];
    double zar = rng.nextDouble() * toplam;
    for (int i = 0; i < acik.length; i++) {
      zar -= agirliklar[i];
      if (zar <= 0) return acik[i];
    }
    return acik.last;
  }

  /// Şirketin durumunun bir sonraki adımı.
  ///
  /// **Kademeli ilerler.** Sağlıklı şirket tek yılda iflas etmez: önce
  /// inceleme ya da sıkıntı, sonra konkordato/kayyum, ancak ondan sonra
  /// faaliyetin durması. Oyuncu yolda haberleri görür ve çıkma şansı
  /// olur — ama işlem durmuşsa çıkamaz.
  static ({IncidentKind kind, CompanyStatus next}) _nextCompanyStep(
    CompanyStatus current,
    Company company,
    MarketRegime regime,
    Random rng,
  ) {
    final bool baskili =
        regime == MarketRegime.kriz || regime == MarketRegime.durgun;
    final double kotulesme = prototypeOnlyEscalateChance *
        (0.5 + company.fragility) *
        (baskili ? 1.35 : 0.85);

    switch (current) {
      case CompanyStatus.normal:
        // Sağlıklı şirkette iyi haber de olur.
        final double zar = rng.nextDouble();
        if (zar < 0.16) {
          return (kind: IncidentKind.satinAlma, next: CompanyStatus.normal);
        }
        if (zar < 0.34) {
          return (kind: IncidentKind.temettu, next: CompanyStatus.normal);
        }
        if (zar < 0.50) {
          return (
            kind: IncidentKind.sermayeArtirimi,
            next: CompanyStatus.normal
          );
        }
        if (zar < 0.72) {
          return (
            kind: IncidentKind.regulatorIncelemesi,
            next: CompanyStatus.inceleme
          );
        }
        return (
          kind: IncidentKind.yonetimSkandali,
          next: CompanyStatus.inceleme
        );

      case CompanyStatus.inceleme:
        if (rng.nextDouble() < prototypeOnlyRecoverChance) {
          // İnceleme temize çıktı.
          return (
            kind: IncidentKind.regulatorIncelemesi,
            next: CompanyStatus.normal
          );
        }
        return rng.nextDouble() < kotulesme
            ? (kind: IncidentKind.maliSikinti, next: CompanyStatus.sikinti)
            : (
                kind: IncidentKind.yonetimSkandali,
                next: CompanyStatus.inceleme
              );

      case CompanyStatus.sikinti:
        if (rng.nextDouble() < prototypeOnlyRecoverChance) {
          return (
            kind: IncidentKind.sermayeArtirimi,
            next: CompanyStatus.inceleme
          );
        }
        if (rng.nextDouble() < kotulesme) {
          return rng.nextDouble() < 0.62
              ? (kind: IncidentKind.konkordato, next: CompanyStatus.konkordato)
              : (kind: IncidentKind.kayyum, next: CompanyStatus.kayyum);
        }
        return (kind: IncidentKind.maliSikinti, next: CompanyStatus.sikinti);

      case CompanyStatus.konkordato:
      case CompanyStatus.kayyum:
        if (rng.nextDouble() < prototypeOnlyRecoverChance * 0.7) {
          // Süreçten çıktı; hâlâ kırılgan.
          return (kind: IncidentKind.maliSikinti, next: CompanyStatus.sikinti);
        }
        return rng.nextDouble() < kotulesme
            ? (kind: IncidentKind.iflas, next: CompanyStatus.kapandi)
            : (kind: IncidentKind.konkordato, next: current);

      case CompanyStatus.kapandi:
        // Kapanmış şirket seçilmez; savunma amaçlı.
        return (kind: IncidentKind.iflas, next: CompanyStatus.kapandi);
    }
  }
}
