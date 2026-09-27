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
    // **Krize giriş ihtimali yarıya indirildi (Paket AC).** Bu ölçümden
    // çıktı: krizi çok yıllı yapmak (§11) giriş ihtimalini
    // değiştirmeden kriz yıllarının payını %8'den **%17,8'e** çıkardı.
    // Sonuç risk merdivenini tersine çevirdi — hissenin gerçekleşen
    // ortalaması yazdığı %10 yerine %6,4'e düştü ve altının %7,9'unun
    // **altında** kaldı. Yüksek riskli varlığın beklenen getirisi düşük
    // riskliden az olamaz. Amaç daha çok kriz değil, **daha uzun** kriz:
    // giriş seyreldi, süre uzadı, toplam pay korundu.
    MarketRegime.durgun: <MarketRegime, double>{
      MarketRegime.durgun: 0.35,
      MarketRegime.normal: 0.48,
      MarketRegime.guclu: 0.13,
      MarketRegime.kriz: 0.04,
    },
    MarketRegime.normal: <MarketRegime, double>{
      MarketRegime.durgun: 0.23,
      MarketRegime.normal: 0.51,
      MarketRegime.guclu: 0.23,
      MarketRegime.kriz: 0.03,
    },
    MarketRegime.guclu: <MarketRegime, double>{
      MarketRegime.durgun: 0.21,
      MarketRegime.normal: 0.43,
      MarketRegime.guclu: 0.31,
      MarketRegime.kriz: 0.05,
    },
    // **Krizin çıkışı toparlanmadan geçer (Paket AC, §11).** V1'de kriz
    // yılından doğrudan "güçlü" yıla %6 ihtimalle atlanıyordu ve kriz
    // tek yıllıktı; bu "krizde al, ertesi yıl kesin toparlar" exploitini
    // besliyordu. Artık krizin zorunlu süresi var
    // (`prototypeOnlyCrisisYears`) ve bittiğinde ezici ihtimalle
    // toparlanmaya geçilir: yukarı eğilimli ama **hâlâ oynak** bir yıl.
    MarketRegime.kriz: <MarketRegime, double>{
      MarketRegime.toparlanma: 0.64,
      MarketRegime.durgun: 0.28,
      MarketRegime.normal: 0.05,
      MarketRegime.kriz: 0.03,
    },
    // Toparlanmadan sonra hayat normale döner; yeniden krize düşmek de
    // mümkün (çift dipli kriz).
    MarketRegime.toparlanma: <MarketRegime, double>{
      MarketRegime.normal: 0.50,
      MarketRegime.durgun: 0.23,
      MarketRegime.guclu: 0.21,
      MarketRegime.kriz: 0.06,
    },
  };

  /// prototypeOnly: kriz başladığında kaç yıl **zorunlu** sürer.
  ///
  /// Alt sınır dahil, üst sınır dahil. 1-3 yıl: bazı krizler tek yılda
  /// biter, bazıları üç yıl sürer. Oyuncu krize girdiğinde ne zaman
  /// çıkacağını bilemez — bilse "dibi al" garanti bir strateji olurdu.
  static const int prototypeOnlyCrisisMinYears = 1;
  static const int prototypeOnlyCrisisMaxYears = 3;

  /// prototypeOnly: toparlanmanın zorunlu süresi (yıl).
  static const int prototypeOnlyRecoveryYears = 1;

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
    // Toparlanma: tabanı artı ama genliği geniş. Yukarı eğilimli, garanti
    // değil — bazı toparlanma yılları eksi kapanır.
    MarketRegime.toparlanma: (base: 0.092, spread: 0.19),
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
    // **Toparlanmada panik primi geri verilir.** Krizin ilk yılında
    // korunma tarafı +0,108 taban alıyor; ortalık düzelmeye başlayınca
    // para riskli tarafa döner ve altın/döviz o primin bir kısmını geri
    // verir. V1'de böyle bir geri verme yoktu ve ölçümde sonuç şuydu:
    // **Döviz Sepeti'nde 1.000 yirmi yıllık yolun hiçbiri anaparanın
    // altında bitmiyordu.** "Risk etiketi yazıp risksiz davranmak olmaz."
    MarketRegime.toparlanma: (base: -0.105, spread: 0.13),
  };

  /// prototypeOnly: rejim tabanlarının üstüne eklenen **risk primi**.
  ///
  /// Yukarıdaki rejim tabanları rejimler arası *farkı* yazar ve ağırlıklı
  /// ortalaması sıfıra yakındır (o biçim `drift` çağından kalma: taban
  /// ortalaması drift'in üstüne binmesin diye böyle yazılmıştı). Drift
  /// kalkınca (§2) bu, riskli tarafı **beklentisi sıfır** bıraktı;
  /// ölçümde hisse geometrik %-0,2 çıktı ve "sadece vadeli" her şeyi
  /// yendi. Yani her kararın yanlış cevabı olan bir oyun oldu.
  ///
  /// Bu pay o eksiği kapatıyor ve **sabit bir varlık drift'i değil**:
  /// risk iştahına ekleniyor, yani yalnızca riske duyarlı varlıklara
  /// (`sensitivity.risk`) ve **rejimin izin verdiği ölçüde** geçiyor.
  /// Kaynağı da uydurma değil, ölçülmüş bir oyun gerçeği: rejim
  /// paylarında iyi yıllar kriz yıllarından çok (durgun %24,5 · normal
  /// %45,3 · güçlü %20,8 · kriz %7,1 · toparlanma %2,3). Krizi çok gören
  /// bir hayatta bu prim **hiç gerçekleşmez** — kriz tabanı primi fazlasıyla
  /// yiyor.
  static const double prototypeOnlyRiskPremium = 0.056;

  /// prototypeOnly: rejim tabanlarının üstüne eklenen korunma tabanı.
  ///
  /// AC'de korunma tarafındaki "her zaman kazanan" sorununu düzeltirken
  /// (toparlanmada prim geri verme + uzayan krizde prim erimesi) korunma
  /// etkeninin uzun vadeli ortalaması **eksiye** kaydı: ölçümde -0,006.
  /// Bu da altını/dövizi sistematik kaybettiren bir varlığa çevirdi
  /// (altın 20 yılda medyan 0,81x). Bu pay ortalamayı sıfıra getiriyor:
  /// **korunma tarafı bir döngü boyunca kazandığını geri verir** —
  /// ne kazandırır ne kaybettirir. Altının/dövizin artı beklentisi
  /// korunma talebinden değil, aşağıdaki değer saklama payından gelir.
  static const double prototypeOnlyHedgeBaseline = 0.006;

  /// prototypeOnly: sert varlıkların yıllık **değer saklama** payı.
  ///
  /// Altın ve döviz hiçbir şey üretmez (`carry` sıfır), ama oyunun kendi
  /// parası yıllar içinde alım gücü kaybeder ve sert varlıkların nominal
  /// fiyatı bunu yansıtır. `sensitivity.inflation` ağırlığıyla geçer,
  /// yani en çok altına/dövize, en az hisseye (hissede eksi ağırlık:
  /// yüksek enflasyon hisseyi baskılar).
  ///
  /// **Bu tam bir enflasyon motoru değildir** ve öyle sunulmuyor: maaşlar,
  /// fiyatlar ve giderler bu paketle birlikte oynamıyor. Kapsamlı
  /// enflasyon mimarisi Q-168'de karar bekliyor. Buradaki tek iş, sert
  /// varlıkların beklentisini eksi olmaktan kurtarmak.
  static const double prototypeOnlyStoreOfValueDrift = 0.115;

  // -------------------------------------------------------------------
  // Çağ gelgiti (§4-§5) — hepsi prototypeOnly
  // -------------------------------------------------------------------

  /// prototypeOnly: gelgitin yıllık en büyük adımı (puan).
  static const int prototypeOnlyTideStep = 8;

  /// prototypeOnly: gelgitin 50'ye çekilme payı — **bilerek çok küçük**.
  ///
  /// 0,06 yarı ömrü on bir yıl demek. Rejimin `prototypeOnlyMeanReversion`
  /// payı 0,25 (yarı ömrü ~2,5 yıl): rejim yılların havası, gelgit çağın
  /// havası. İkisi ayrı hızda çalışmalı, yoksa uzun vade yine daralır.
  static const double prototypeOnlyTideReversion = 0.06;

  /// prototypeOnly: gelgitin risk iştahına/korunma talebine geçiş genliği.
  ///
  /// Gelgit uçtayken (0 ya da 100) ortak etkene eklenen/çıkarılan en büyük
  /// pay. Rejim tabanlarıyla kıyaslanabilir büyüklükte: güçlü rejimin
  /// tabanı 0,137, kriz -0,273. Yani kötü bir çağ, iyi rejimlerin bir
  /// kısmını yiyebilir — ama hiçbir yılı tek başına belirlemez.
  ///
  /// **Genlik ölçümle büyütüldü (0,13 → 0,20).** İlk değerde 40 yıllık
  /// hisse yolunun en kötü %10'u hâlâ 1,86 kat yapıyordu. Nedeni ölçümde
  /// çıktı: ısı mekanizması (§6) yıllık getirilere **eksi otokorelasyon**
  /// veriyor — pahalı yılı ucuz yıl izliyor — ve bu, uzun vadeli
  /// ortalamanın dağılımını bağımsız yılların altına *sıkıştırıyor*
  /// (40 yıllık log ortalamanın standart sapması bağımsız varsayımla
  /// %3,87 olmalıyken %2,39 ölçüldü). Yani §6 ile §4 birbirine çalışıyor:
  /// balon mekaniği uzun vadeyi istikrarlı yapıyor. Gelgit bu sıkışmayı
  /// dengeleyecek kadar geniş olmak zorunda.
  static const double prototypeOnlyRiskTideAmplitude = 0.20;

  /// prototypeOnly: korunma tarafının gelgit genliği.
  ///
  /// Risk tarafından küçük: altının çağı da kötü geçebilir (§10), ama
  /// altın oynaklığı zaten hissenin yarısı; aynı genlik altını hisseden
  /// riskli yapardı.
  static const double prototypeOnlyHedgeTideAmplitude = 0.08;

  /// prototypeOnly: enflasyon baskısının ve güvenin yıllık kayma adımı.
  static const int prototypeOnlyDriftStep = 12;

  /// prototypeOnly: gizli parametrelerin her yıl 50'ye çekilme payı.
  static const double prototypeOnlyMeanReversion = 0.25;

  /// prototypeOnly: **uzayan** kriz yılında korunma priminin kalan payı.
  ///
  /// Bu sabit bir ölçüm bulgusundan doğdu. Krizi çok yıllı yapınca
  /// (§11) korunma tarafı sistematik olarak zenginleşti: kriz artık
  /// ortalama iki yıl sürüyor ve her yıl `+0,108` korunma tabanı
  /// uygulanıyordu, yani bir krizin toplam korunma primi ikiye katlandı.
  /// Sonuç ölçümde görüldü — **Döviz Sepeti'nde 1.000 yirmi yıllık yolun
  /// hiçbiri anaparanın altında bitmiyordu.** "Risk etiketi yazıp risksiz
  /// davranmak olmaz" diyen bekçi haklı olarak kırıldı.
  ///
  /// Düzeltme uydurma değil, mekanizmaya uygun: **güvenli limana kaçış
  /// krizin başında olur.** İlk yıl panik primi tamdır; kriz uzadıkça o
  /// prim erir, çünkü herkes çoktan pozisyon almıştır. Uzayan kriz
  /// yılında korunma tabanı bu katsayıyla çarpılır.
  static const double prototypeOnlyProlongedCrisisHedgeShare = 0.30;

  /// prototypeOnly: faiz şokunun yıllık ihtimali ve büyüklüğü (§16).
  static const double prototypeOnlyRateShockChance = 0.05;
  static const double prototypeOnlyRateShockRiskHit = 0.11;
  static const double prototypeOnlyRateShockHedgeLift = 0.05;

  /// prototypeOnly: kur şokunun yıllık ihtimali ve büyüklüğü (§17).
  ///
  /// İki yönlü uygulanır: %58 yukarı, %42 aşağı. Böylece döviz/altın
  /// tarafı "her zaman kazanan" olmaz.
  static const double prototypeOnlyFxShockChance = 0.07;
  static const double prototypeOnlyFxShockSize = 0.14;

  // -------------------------------------------------------------------
  // Değerleme ısısı ve balon (Paket AD, §5-§6) — hepsi prototypeOnly
  // -------------------------------------------------------------------

  /// prototypeOnly: değerleme çekişinin gücü.
  ///
  /// Isı en uçtayken (0 ya da 100) getiriye eklenen/çıkarılan en büyük
  /// pay. Sabit eğilimin yerini bu alıyor: uzun yükseliş kendi frenini
  /// üretiyor, uzun düşüş kendi zeminini.
  static const double prototypeOnlyValuationPull = 0.075;

  /// prototypeOnly: getirinin ısıya dönüşme katsayısı.
  ///
  /// `fazlaGetiri` (carry üstü getiri) bu katsayıyla ısıya eklenir.
  /// %20 fazla getiri ısıyı ~9 puan yükseltir.
  static const double prototypeOnlyHeatGain = 45.0;

  /// prototypeOnly: ısının her yıl 50'ye doğru sönümlenme payı.
  ///
  /// Küçük tutuldu: balon birkaç yıl sürebilsin. Büyük olsa ısı hemen
  /// normale döner ve döngü hissedilmez.
  static const double prototypeOnlyHeatDecay = 0.18;

  /// prototypeOnly: en sıcak noktada balonun kırılma ihtimali.
  ///
  /// Isı sapmasının **karesiyle** ölçeklenir: hafif pahalıda neredeyse
  /// hiç, tepede belirgin. Oyuncu zirveyi önceden bilemez.
  static const double prototypeOnlyBubbleBurstChance = 0.30;

  /// prototypeOnly: kırılmanın büyüklüğü (en sıcak noktada).
  static const double prototypeOnlyBubbleBurstSize = 0.30;

  /// prototypeOnly: en soğuk noktada sert toparlanmanın ihtimali/büyüklüğü.
  ///
  /// **Bu, balon kırılmasının aynadaki eşi ve ölçümden doğdu.** İlk
  /// kurulumda yalnızca kırılma vardı, yani ısı mekanizması tek yönlü bir
  /// vergiydi: her varlık zaman zaman sert düşüyor ama hiç sert
  /// toparlanmıyordu. 60.000 yıllık ölçümde sonuç şu çıktı — altın yıllık
  /// ortalama **%-0,3**, hisse geometrik **%-0,2**; yani "uzun vadede
  /// kesin zengin olma" sorununu "uzun vadede kesin batma" sorununa
  /// çevirmiştim. Simetri hem beklentiyi düzeltiyor hem de oyunu
  /// zenginleştiriyor: çöküşün dibi gerçek bir fırsat olur, ama **garanti
  /// olmaz** — dipte de zar atılır, oyuncu dibi de zirve gibi önceden
  /// bilemez.
  static const double prototypeOnlyPanicRallyChance = 0.30;
  static const double prototypeOnlyPanicRallySize = 0.30;

  /// prototypeOnly: tek yılda bir varlığın düşebileceği en dip oran.
  ///
  /// Tavan yok: iyi yıl serbest. Taban var, çünkü bir yılda varlığın
  /// tamamını silmek oyunu anlatısızlaştırır.
  static const double prototypeOnlyFloorReturn = -0.55;

  // -------------------------------------------------------------------
  // Yılı ilerletmek
  // -------------------------------------------------------------------

  /// Bir sonraki rejimi seçer (**süreye bakmaz**; bkz. [nextPhase]).
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

  /// Bu rejim başladığında kaç yıl zorunlu sürer?
  ///
  /// Kriz ve toparlanma dışındaki rejimler süresizdir (her yıl yeniden
  /// zar atılır); onlarda 0 döner.
  /// Dönen sayı **bu yıldan sonraki** kilitli yıl sayısıdır: toplam süre
  /// 1 + dönen değerdir.
  ///
  /// İlk yazımda toplam süreyi döndürüyordum ve `nextPhase` üstüne bir yıl
  /// daha ekliyordu; ölçümde kriz ortalaması 3,13 yıl, en uzunu 11 yıl
  /// çıktı — hedeflenen 1-3 yılın çok üstünde. Bire bir kaydırma hatasıydı.
  static int lockYearsFor(MarketRegime regime, Random rng) => switch (regime) {
        MarketRegime.kriz => prototypeOnlyCrisisMinYears -
            1 +
            rng.nextInt(
              prototypeOnlyCrisisMaxYears - prototypeOnlyCrisisMinYears + 1,
            ),
        MarketRegime.toparlanma => prototypeOnlyRecoveryYears - 1,
        _ => 0,
      };

  /// Rejimin bir sonraki adımı: süre kilidi varsa rejim **değişmez**.
  ///
  /// Dönen `yearsLeft` yeni yılın **kalan** zorunlu yılıdır.
  static ({MarketRegime regime, int yearsLeft}) nextPhase({
    required MarketRegime current,
    required int yearsLeft,
    required Random rng,
  }) {
    if (yearsLeft > 0) {
      // Kilit sürüyor: aynı rejim bir yıl daha.
      return (regime: current, yearsLeft: yearsLeft - 1);
    }
    final MarketRegime yeni = nextRegime(current, rng);
    return (regime: yeni, yearsLeft: lockYearsFor(yeni, rng));
  }

  /// Bir varlığın **yapısal** yıllık eğilimi: ısının sıfır noktası.
  ///
  /// Isı "bu varlık kendi normalinin ne kadar üstünde/altında" demektir.
  /// Referans olarak yalnızca `carry` kullanınca ölçümde ısının uzun vadeli
  /// ortalaması 50 değil **55-58** çıktı: beklenen getiri artı olduğu için
  /// her varlık sistematik olarak "pahalı" işaretleniyor ve değerleme çekişi
  /// primin bir kısmını kalıcı olarak yiyordu. Referans varlığın sabitlerden
  /// gelen koşulsuz beklentisi olunca ısı yeniden 50'de merkezleniyor ve
  /// çekiş yalnızca **döngüsel** sapmayı cezalandırıyor.
  ///
  /// Bu bir getiri bileşeni **değildir**; getiri formülüne girmez, yalnızca
  /// ısının nereye göre ölçüldüğünü söyler.
  static double structuralReturn(InvestmentType t) =>
      t.carry -
      t.annualFee +
      t.sensitivity.risk * prototypeOnlyRiskPremium +
      t.sensitivity.hedge * prototypeOnlyHedgeBaseline +
      t.sensitivity.inflation * prototypeOnlyStoreOfValueDrift;

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
    final ({MarketRegime regime, int yearsLeft}) faz = nextPhase(
      current: state.regime,
      yearsLeft: state.regimeYearsLeft,
      rng: rng,
    );
    final MarketRegime yeniRejim = faz.regime;

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
      case MarketRegime.toparlanma:
        // Toparlanmada güven yavaş yavaş geri gelir, enflasyon baskısı
        // gevşer ama bir yılda normale dönmez.
        enflasyon -= rng.nextInt(prototypeOnlyDriftStep ~/ 2 + 1);
        guven += rng.nextInt(prototypeOnlyDriftStep ~/ 2 + 1);
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

    // ---- Çağ gelgiti (§4-§5) ------------------------------------------
    //
    // Yılda küçük bir adım, 50'ye çok zayıf çekiliş. Ortalaması sıfır
    // olduğu için beklenen getiriyi değiştirmez; yaptığı tek şey uzun
    // vadeli sonucun **dağılımını genişletmek**. Bir hayat kötü bir çağa
    // denk gelebilir ve bu oyuncunun hatası olmaz.
    int riskGelgiti = state.riskTide +
        (rng.nextInt(2 * prototypeOnlyTideStep + 1) - prototypeOnlyTideStep);
    int korunmaGelgiti = state.hedgeTide +
        (rng.nextInt(2 * prototypeOnlyTideStep + 1) - prototypeOnlyTideStep);
    riskGelgiti +=
        ((50 - riskGelgiti) * prototypeOnlyTideReversion).round();
    korunmaGelgiti +=
        ((50 - korunmaGelgiti) * prototypeOnlyTideReversion).round();
    riskGelgiti = riskGelgiti.clamp(0, 100);
    korunmaGelgiti = korunmaGelgiti.clamp(0, 100);
    final double riskGelgitPayi =
        (riskGelgiti - 50) / 50.0 * prototypeOnlyRiskTideAmplitude;
    final double korunmaGelgitPayi =
        (korunmaGelgiti - 50) / 50.0 * prototypeOnlyHedgeTideAmplitude;

    double riskEtkeni = riskBandi.base +
        prototypeOnlyRiskPremium +
        riskGelgitPayi +
        guvenKaymasi +
        riskBandi.spread * _noise(rng) * 2;
    // **Korunma primi krizin başında tamdır, uzayınca erir.** Bkz.
    // `prototypeOnlyProlongedCrisisHedgeShare`.
    final bool uzayanKriz =
        yeniRejim == MarketRegime.kriz && state.regime == MarketRegime.kriz;
    final double hedgeTabani = prototypeOnlyHedgeBaseline +
        (uzayanKriz
            ? hedgeBandi.base * prototypeOnlyProlongedCrisisHedgeShare
            : hedgeBandi.base);
    double hedgeEtkeni = hedgeTabani +
        korunmaGelgitPayi +
        enflasyonKaymasi +
        hedgeBandi.spread * _noise(rng) * 2;
    final double enflasyonEtkeni = (enflasyon - 50) / 100;

    // ---- Faiz şoku (§16) ----------------------------------------------
    // Nadir. Faiz sert yükseldiğinde riskli taraf baskılanır; vadeli
    // hesabın cazibesi bu pakette **kur/faiz oranı olarak değil**,
    // yalnızca hisse/fon üzerindeki baskı olarak modellendi — vadeli
    // oranını yıl içinde oynatmak bütün mevcut vadeli kayıtlarını
    // yeniden hesaplamayı gerektirirdi ve o mimari değişiklik onay
    // bekliyor (Q-168).
    final bool faizSoku = rng.nextDouble() < prototypeOnlyRateShockChance;
    if (faizSoku) {
      riskEtkeni -= prototypeOnlyRateShockRiskHit;
      hedgeEtkeni += prototypeOnlyRateShockHedgeLift;
    }

    // ---- Kur şoku (§17) -----------------------------------------------
    // İki yönlü: bazı yıllarda korunma tarafı sert yukarı, bazı yıllarda
    // sert geri çekilir. **"Döviz her zaman kazanır" kuralı yok.**
    final bool kurSoku = rng.nextDouble() < prototypeOnlyFxShockChance;
    if (kurSoku) {
      final bool yukari = rng.nextDouble() < 0.58;
      hedgeEtkeni += yukari
          ? prototypeOnlyFxShockSize
          : -prototypeOnlyFxShockSize * 0.85;
    }

    final Map<String, double> getiriler = <String, double>{};
    final Map<String, int> yeniEndeks = <String, int>{...state.priceIndex};
    final Map<String, int> yeniIsi = <String, int>{...state.valuationHeat};

    for (final InvestmentType tur in kMarketInvestmentTypes) {
      final MarketSensitivity h = tur.sensitivity;
      final int isi = state.heatOf(tur.id);

      // ---- Değerleme çekişi (Paket AD, §5-§6) ------------------------
      //
      // Sabit pozitif eğilimin (`drift`) yerini alan mekanizma. Isı
      // 50'nin üstündeyse varlık pahalı sayılır ve beklenen getirisi
      // **aşağı** çekilir; altındaysa yukarı. Uzun yükseliş kendi
      // frenini üretir, uzun düşüş kendi toparlanma zeminini hazırlar —
      // ama hiçbir geçiş garanti değil, çünkü çekiş gürültünün yanında
      // yalnızca bir bileşen.
      final double isiSapmasi = (isi - 50) / 50.0; // -1 .. +1
      final double degerlemeCekisi =
          -isiSapmasi * prototypeOnlyValuationPull * tur.heatSensitivity;

      // ---- Balon kırılması (§6) --------------------------------------
      //
      // Isı yükseldikçe sert düzeltme ihtimali artar. Oyuncu zirveyi
      // önceden bilemez: kırılma bir zar, ısı yalnızca ihtimali büyütür.
      // Aynısı aşağı uçta da geçerlidir (`prototypeOnlyPanicRallyChance`):
      // uzun süre dipte kalan varlık bir yıl sert toparlanabilir. Tek yönlü
      // bırakılırsa ısı mekanizması sistematik bir vergiye dönüşüyor.
      double balonKirilmasi = 0;
      if (isiSapmasi > 0) {
        final double kirilmaSansi = isiSapmasi *
            isiSapmasi *
            prototypeOnlyBubbleBurstChance *
            tur.heatSensitivity;
        if (rng.nextDouble() < kirilmaSansi) {
          balonKirilmasi = -prototypeOnlyBubbleBurstSize *
              isiSapmasi *
              tur.heatSensitivity;
        }
      } else if (isiSapmasi < 0) {
        final double raliSansi = isiSapmasi *
            isiSapmasi *
            prototypeOnlyPanicRallyChance *
            tur.heatSensitivity;
        if (rng.nextDouble() < raliSansi) {
          balonKirilmasi = -prototypeOnlyPanicRallySize *
              isiSapmasi *
              tur.heatSensitivity;
        }
      }

      // **`carry` bir garanti değil, varlığın ürettiği akıştır.** Altın
      // ve dövizde sıfır: onlar hiçbir şey üretmez. Onların artı beklentisi
      // `prototypeOnlyStoreOfValueDrift` payından gelir; döngüsel kazancı
      // (korunma talebi) ise ortalamada geri verilir.
      //
      // `annualFee` fonun yıllık yönetim ücretidir: her yıl, kâr olsun
      // olmasın kesilir. Fonun brüt carry'sinin büyük kısmını yiyor —
      // "profesyonel yönetim bedava değil" (§12: hiçbir seçenek doğru
      // cevap olmasın).
      final double ham = tur.carry -
          tur.annualFee +
          degerlemeCekisi +
          balonKirilmasi +
          h.risk * riskEtkeni +
          h.hedge * hedgeEtkeni +
          h.inflation *
              (prototypeOnlyStoreOfValueDrift + enflasyonEtkeni * 0.10) +
          h.idiosyncratic * _noise(rng) * 2;
      final double getiri = ham < prototypeOnlyFloorReturn
          ? prototypeOnlyFloorReturn
          : ham;
      getiriler[tur.id] = getiri;

      final int eski = state.indexOf(tur.id);
      final int yeni = (eski * (1 + getiri)).round();
      // Endeks sıfırın altına inmez ve tamamen sıfırlanmaz.
      yeniEndeks[tur.id] = yeni < 1 ? 1 : yeni;

      // ---- Isıyı güncelle --------------------------------------------
      //
      // Fiyat carry'nin üstünde arttıysa varlık ısınır, altında kaldıysa
      // soğur. Üstüne her yıl 50'ye doğru bir sönümleme var: ısı sonsuza
      // gitmez, ama hızlı da düşmez — balon birkaç yıl sürebilir.
      final double fazlaGetiri = getiri - structuralReturn(tur);
      final int isiDegisimi =
          (fazlaGetiri * prototypeOnlyHeatGain * tur.heatSensitivity).round();
      final int sonumleme =
          ((50 - isi) * prototypeOnlyHeatDecay).round();
      yeniIsi[tur.id] = (isi + isiDegisimi + sonumleme).clamp(0, 100);
    }

    return (
      state: state.copyWith(
        regime: yeniRejim,
        regimeYearsLeft: faz.yearsLeft,
        inflationPressure: enflasyon,
        confidence: guven,
        priceIndex: Map<String, int>.unmodifiable(yeniEndeks),
        valuationHeat: Map<String, int>.unmodifiable(yeniIsi),
        riskTide: riskGelgiti,
        hedgeTide: korunmaGelgiti,
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
