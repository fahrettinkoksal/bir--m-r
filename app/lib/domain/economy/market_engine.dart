/// Piyasa rejimi motoru (D-162).
///
/// **Neden var:** Her varlık bağımsız zar atsaydı aynı yılda "hisse -%20,
/// fon +%40, döviz -%30, altın -%25" gibi birbiriyle alakasız sonuçlar
/// çıkardı. Bunun yerine yılın bir **rejimi** var (durgun / normal / güçlü /
/// kriz) ve iki gizli parametresi (enflasyon baskısı, piyasa güveni).
/// Rejim iki ortak etken üretir:
///
/// * **risk iştahı** — hisse ve fonu sürükler,
/// * **korunma talebi** — altın ve dövizi sürükler.
///
/// Varlıklar bu etkenlere kendi ağırlıklarıyla (`MarketSensitivity`) tepki
/// verir, üstüne küçük bir kendi gürültüsünü ekler. Böylece kriz yılında
/// hisse sert düşerken altın portföyü tutabilir — **ama her kriz aynı
/// sonucu vermez**, çünkü etkenler bantlı rastgeledir.
///
/// **Determinizm:** piyasa yaş başına **bir kez** ilerler ve endeks kayda
/// yazılır. Oyuncu ekranı kapatıp açarak, al-sat yaparak ya da kaydı geri
/// yükleyerek fiyatı yeniden çeviremez.
///
/// Bütün sayılar `prototypeOnly`'dir (Q-165).
library;

import 'dart:math';

import '../../data/investment_catalog.dart';
import '../models/market_state.dart';

abstract final class MarketEngine {
  // -------------------------------------------------------------------
  // Rejim geçişleri
  // -------------------------------------------------------------------

  /// prototypeOnly: rejimden rejime geçiş ağırlıkları.
  ///
  /// Kriz seyrek ve kısa; normal yıl en olası. Krizden sonra doğrudan
  /// "güçlü" yıla atlamak mümkün ama zor — toparlanma genelde durgun ya
  /// da normal yıldan geçer.
  static const Map<MarketRegime, Map<MarketRegime, double>>
      prototypeOnlyTransitions = <MarketRegime, Map<MarketRegime, double>>{
    MarketRegime.durgun: <MarketRegime, double>{
      MarketRegime.durgun: 0.34,
      MarketRegime.normal: 0.46,
      MarketRegime.guclu: 0.13,
      MarketRegime.kriz: 0.07,
    },
    MarketRegime.normal: <MarketRegime, double>{
      MarketRegime.durgun: 0.22,
      MarketRegime.normal: 0.50,
      MarketRegime.guclu: 0.22,
      MarketRegime.kriz: 0.06,
    },
    MarketRegime.guclu: <MarketRegime, double>{
      MarketRegime.durgun: 0.20,
      MarketRegime.normal: 0.42,
      MarketRegime.guclu: 0.28,
      MarketRegime.kriz: 0.10,
    },
    MarketRegime.kriz: <MarketRegime, double>{
      MarketRegime.durgun: 0.42,
      MarketRegime.normal: 0.34,
      MarketRegime.guclu: 0.06,
      MarketRegime.kriz: 0.18,
    },
  };

  /// prototypeOnly: rejimin **risk iştahı** etkeni bandı (taban, genlik).
  /// Tabanlar **ortalaması sıfıra çekilmiş** biçimde yazıldı, bilerek:
  /// yoksa rejim tabanının artı ortalaması `drift`'in üstüne biner ve
  /// beklenen getiri yazdığından yüksek çıkar. İlk ölçümde tam bu oldu —
  /// hisse `drift` %14 yazılmışken 10.000 yılda %20,1 ölçüldü.
  static const Map<MarketRegime, ({double base, double spread})>
      prototypeOnlyRiskFactor = <MarketRegime, ({double base, double spread})>{
    MarketRegime.durgun: (base: -0.053, spread: 0.13),
    MarketRegime.normal: (base: 0.017, spread: 0.14),
    MarketRegime.guclu: (base: 0.137, spread: 0.16),
    MarketRegime.kriz: (base: -0.273, spread: 0.18),
  };

  /// prototypeOnly: rejimin **korunma talebi** etkeni bandı.
  static const Map<MarketRegime, ({double base, double spread})>
      prototypeOnlyHedgeFactor = <MarketRegime, ({double base, double spread})>{
    MarketRegime.durgun: (base: -0.022, spread: 0.10),
    MarketRegime.normal: (base: -0.002, spread: 0.10),
    // Güçlü yılda korunma talebi hafif geriler: ortalık iyiyken kimse
    // altına sığınmaz.
    MarketRegime.guclu: (base: -0.012, spread: 0.11),
    MarketRegime.kriz: (base: 0.108, spread: 0.14),
  };

  /// prototypeOnly: enflasyon baskısının ve güvenin yıllık kayma adımı.
  static const int prototypeOnlyDriftStep = 12;

  /// prototypeOnly: gizli parametrelerin her yıl 50'ye çekilme payı.
  static const double prototypeOnlyMeanReversion = 0.25;

  /// prototypeOnly: tek yılda bir varlığın düşebileceği en dip oran.
  ///
  /// Tavan yok: iyi yıl serbest. Taban var, çünkü bir yılda varlığın
  /// tamamını silmek oyunu anlatısızlaştırır.
  static const double prototypeOnlyFloorReturn = -0.55;

  // -------------------------------------------------------------------
  // Yılı ilerletmek
  // -------------------------------------------------------------------

  /// Bir sonraki rejimi seçer.
  static MarketRegime nextRegime(MarketRegime current, Random rng) {
    final Map<MarketRegime, double> agirliklar =
        prototypeOnlyTransitions[current]!;
    final double zar = rng.nextDouble();
    double toplam = 0;
    for (final MapEntry<MarketRegime, double> e in agirliklar.entries) {
      toplam += e.value;
      if (zar < toplam) return e.key;
    }
    return MarketRegime.normal;
  }

  /// -1 ile +1 arasında üçgene yakın bir gürültü.
  ///
  /// İki düzgün rastgele sayının ortalaması: uçlar seyrek, orta yoğun.
  /// Böylece aşırı yıllar olur ama her yıl olmaz.
  static double _noise(Random rng) =>
      (rng.nextDouble() - 0.5) + (rng.nextDouble() - 0.5);

  /// Bu yılın getirilerini hesaplar.
  ///
  /// [state] yılın **başındaki** piyasa durumudur; dönen `MarketYear` yeni
  /// rejimi ve varlık başına getiriyi taşır.
  static ({MarketState state, MarketYear year}) advance({
    required MarketState state,
    required int newAge,
    required Random rng,
  }) {
    final MarketRegime yeniRejim = nextRegime(state.regime, rng);

    // Gizli parametreler yavaş kayar; kriz enflasyonu ve güvensizliği
    // besler, güçlü yıl güveni toparlar.
    int enflasyon = state.inflationPressure;
    int guven = state.confidence;
    switch (yeniRejim) {
      case MarketRegime.kriz:
        enflasyon += rng.nextInt(prototypeOnlyDriftStep + 1);
        guven -= rng.nextInt(prototypeOnlyDriftStep + 1);
      case MarketRegime.guclu:
        enflasyon -= rng.nextInt(prototypeOnlyDriftStep ~/ 2 + 1);
        guven += rng.nextInt(prototypeOnlyDriftStep + 1);
      case MarketRegime.durgun:
        enflasyon += rng.nextInt(5) - 2;
        guven -= rng.nextInt(5);
      case MarketRegime.normal:
        enflasyon += rng.nextInt(7) - 3;
        guven += rng.nextInt(7) - 3;
    }
    // **Ortalamaya dönüş.** Bu olmadan iki parametre rastgele yürüyüşle
    // sınıra dayanıyordu: ölçümde enflasyon baskısı 0'a çakılıyor ve
    // altının beklenen getirisi yazdığı %7 yerine %5'e düşüyordu. Artık
    // her yıl 50'ye doğru bir miktar çekiliyor; rejimle hareket etmeye
    // devam ediyor ama duvara yapışmıyor.
    enflasyon += ((50 - enflasyon) * prototypeOnlyMeanReversion).round();
    guven += ((50 - guven) * prototypeOnlyMeanReversion).round();
    enflasyon = enflasyon.clamp(0, 100);
    guven = guven.clamp(0, 100);

    // Ortak etkenler: yılın tek bir risk iştahı ve tek bir korunma talebi
    // vardır. Varlıkların korelasyonu buradan gelir.
    final ({double base, double spread}) riskBandi =
        prototypeOnlyRiskFactor[yeniRejim]!;
    final ({double base, double spread}) hedgeBandi =
        prototypeOnlyHedgeFactor[yeniRejim]!;

    // Güven risk iştahını, enflasyon korunma talebini kaydırır.
    final double guvenKaymasi = (guven - 50) / 100 * 0.08;
    final double enflasyonKaymasi = (enflasyon - 50) / 100 * 0.08;

    final double riskEtkeni =
        riskBandi.base + guvenKaymasi + riskBandi.spread * _noise(rng) * 2;
    final double hedgeEtkeni =
        hedgeBandi.base + enflasyonKaymasi + hedgeBandi.spread * _noise(rng) * 2;
    final double enflasyonEtkeni = (enflasyon - 50) / 100;

    final Map<String, double> getiriler = <String, double>{};
    final Map<String, int> yeniEndeks = <String, int>{...state.priceIndex};

    for (final InvestmentType tur in kMarketInvestmentTypes) {
      final MarketSensitivity h = tur.sensitivity;
      final double ham = tur.drift +
          h.risk * riskEtkeni +
          h.hedge * hedgeEtkeni +
          h.inflation * enflasyonEtkeni * 0.10 +
          h.idiosyncratic * _noise(rng) * 2;
      final double getiri = ham < prototypeOnlyFloorReturn
          ? prototypeOnlyFloorReturn
          : ham;
      getiriler[tur.id] = getiri;

      final int eski = state.indexOf(tur.id);
      final int yeni = (eski * (1 + getiri)).round();
      // Endeks sıfırın altına inmez ve tamamen sıfırlanmaz.
      yeniEndeks[tur.id] = yeni < 1 ? 1 : yeni;
    }

    return (
      state: state.copyWith(
        regime: yeniRejim,
        inflationPressure: enflasyon,
        confidence: guven,
        priceIndex: Map<String, int>.unmodifiable(yeniEndeks),
        advancedAtAge: newAge,
      ),
      year: MarketYear(
        regime: yeniRejim,
        returns: Map<String, double>.unmodifiable(getiriler),
      ),
    );
  }

  /// Bu yaşta piyasa **zaten** ilerletildi mi?
  ///
  /// Yaş başına bir kezin bekçisi budur. Karşılaştırma `>=` değil `==`:
  /// kuşak devrinde yeni oyuncu 25 yaşında başlarken devrolan endeks
  /// "78 yaşında ilerletildi" diye işaretliyse `>=` piyasayı **bir daha
  /// hiç ilerletmezdi**. Yaş yalnızca ileri gittiği için `==` aynı yıl
  /// yeniden çevirmeyi de aynı biçimde engeller.
  static bool alreadyAdvancedAt(MarketState state, int age) =>
      state.advancedAtAge == age;
}
