/// Kurgusal şirketlerin **yıldan yıla yaşaması** (Paket AD, §AD/2).
///
/// Bu motorun tek işi şirketlerin gizli göstergelerini ve sektörlerin
/// gücünü her yıl yürütmek. Olayları o üretmiyor — olayları
/// `IncidentEngine` üretiyor, ama artık **buradan gelen duruma bakarak**.
/// Yani şirket olayları rastgele haber olmaktan çıkıp bir hikâyenin
/// sonucu oluyor (§4: "olaylar state'ten doğsun").
///
/// Tasarımın üç kuralı:
///
/// 1. **Durum her yıl değişmek zorunda değil.** İyi şirket yıllarca iyi
///    kalabilir, kötü şirket toparlanabilir (§1).
/// 2. **Sektör ve şirket birlikte çalışır.** Enerji sektörü kriz görürse
///    enerji şirketleri baskılanır, ama aynı sektördeki iki şirket aynı
///    biçimde hareket etmez — kendi göstergeleri farklı (§2).
/// 3. **Yönetim kalitesi yavaş değişir** ve kötü haberi yumuşatır (§3).
///
/// Bütün sabitler `prototypeOnly` (Q-171).
library;

import 'dart:math';

import '../../data/company_catalog.dart';
import '../models/company_vitals.dart';
import '../models/market_state.dart';

abstract final class CompanyEngine {
  /// prototypeOnly: göstergelerin yıllık en büyük rastgele adımı (puan).
  static const int prototypeOnlyStep = 7;

  /// prototypeOnly: yönetim kalitesinin yıllık adımı — bilerek küçük.
  static const int prototypeOnlyManagementStep = 3;

  /// prototypeOnly: göstergelerin kendi taban değerine çekilme payı.
  ///
  /// Küçük: bir şirket yıllarca kötü gidebilsin. Büyük olsa her şirket
  /// hemen ortalamaya döner ve "yıllardır zorlanıyor" hissi oluşmaz.
  static const double prototypeOnlyReversion = 0.12;

  /// prototypeOnly: yönetim kalitesinin tabanına çekilme payı.
  static const double prototypeOnlyManagementReversion = 0.06;

  /// prototypeOnly: sektör gücünün yıllık adımı ve çekilme payı.
  static const int prototypeOnlySectorStep = 6;
  static const double prototypeOnlySectorReversion = 0.14;

  /// prototypeOnly: rejimin göstergelere yıllık baskısı (puan).
  ///
  /// Kriz yılında mali sağlık ve güven düşer, borç baskısı artar. Güçlü
  /// yılda tersi. Rejim tek başına şirketi batırmaz; yalnızca kaydırır.
  static const Map<MarketRegime, int> prototypeOnlyRegimePressure =
      <MarketRegime, int>{
    MarketRegime.durgun: -2,
    MarketRegime.normal: 0,
    MarketRegime.guclu: 3,
    MarketRegime.kriz: -9,
    MarketRegime.toparlanma: 2,
  };

  /// prototypeOnly: sektör gücünün şirket göstergelerine geçiş payı.
  static const double prototypeOnlySectorInfluence = 0.16;

  /// prototypeOnly: baskısı geçen şirketin **sessizce** bir kademe
  /// düzelme ihtimali.
  ///
  /// **Bu sabit bir ölçüm bulgusundan doğdu ve yapısal bir kusuru
  /// kapatıyor.** Paket AC'de şirketin durumu yalnızca **olaya konu
  /// olduğunda** değişiyordu. Olay ihtimali yılda %16 ve on iki şirkete
  /// dağılıyor, yani bir şirket ortalama yetmiş yılda bir seçiliyor.
  /// Kötüleşme ihtimali tam iyileşmeden yüksek olduğu için durumlar
  /// neredeyse **yutucu** hâle geliyordu: 14.213 şirket-yılı ölçtüğümde
  /// şirketlerin yalnızca **%31'i normal**, %68'i kalıcı olarak sıkıntılı
  /// çıktı. Oyun kuşaklar arası devam ettiği için bu, ilerleyen kayıtlarda
  /// "bütün şirketler hasta" demek.
  ///
  /// Çözüm §1'in kendi kuralı: "kötü şirket toparlanabilir." Toparlanma
  /// artık habere bağlı değil — göstergeleri düzelen şirket sessizce bir
  /// kademe iyileşebilir. **Asimetri bilerek:** kötü haber her zaman
  /// duyurulur (olay üretir, oyuncu görür), iyi haber sessiz olabilir.
  /// Bir şirketin düzeldiğini oyuncu er ya da geç haberlerden anlar.
  static const double prototypeOnlyQuietRecoveryChance = 0.22;

  /// prototypeOnly: sessiz düzelme için gereken en yüksek baskı.
  static const double prototypeOnlyQuietRecoveryStress = 0.44;

  /// Bir şirketin göstergelerinin **taban** değeri.
  ///
  /// Katalogdaki `fragility` burada işe yarıyor: kırılgan şirket daha düşük
  /// mali sağlık, daha yüksek borç baskısı ve daha kötü yönetim tabanına
  /// sahip. Yani katalog hâlâ anlam taşıyor, göstergeler onun etrafında
  /// salınıyor — paralel bir ikinci sistem kurulmuş olmuyor.
  static CompanyVitals baselineFor(Company c) {
    final double k = c.fragility; // 0-1, yüksek = kırılgan
    return CompanyVitals(
      financialHealth: (50 + (0.5 - k) * 44).round().clamp(0, 100),
      debtPressure: (50 + (k - 0.5) * 44).round().clamp(0, 100),
      growth: (50 + (0.5 - k) * 18).round().clamp(0, 100),
      management: (50 + (0.5 - k) * 34).round().clamp(0, 100),
      confidence: (50 + (0.5 - k) * 26).round().clamp(0, 100),
    );
  }

  /// Kayıtta göstergesi olmayan şirketler için başlangıç tablosu.
  static Map<String, CompanyVitals> initialVitals() =>
      <String, CompanyVitals>{
        for (final Company c in kCompanyCatalog) c.id: baselineFor(c),
      };

  /// Bir yılı yürütür: göstergeler ve sektör gücü.
  ///
  /// Durumu (`CompanyStatus`) **değiştirmez** — o `IncidentEngine`'in işi.
  /// Burada yalnızca zemin hareket eder.
  static ({
    Map<String, CompanyVitals> vitals,
    Map<String, int> sectorStrength,
    Map<String, String> statusChanges,
  }) advance({
    required MarketState state,
    required MarketRegime regime,
    required Random rng,
  }) {
    final int rejimBaskisi = prototypeOnlyRegimePressure[regime] ?? 0;

    // ---- Sektör gücü ------------------------------------------------
    final Map<String, int> yeniSektor = <String, int>{};
    for (final CompanySector s in CompanySector.values) {
      final int mevcut = state.sectorStrengthOf(s);
      int yeni = mevcut +
          (rng.nextInt(2 * prototypeOnlySectorStep + 1) -
              prototypeOnlySectorStep) +
          (rejimBaskisi * 0.4).round();
      yeni += ((50 - yeni) * prototypeOnlySectorReversion).round();
      yeniSektor[s.name] = yeni.clamp(0, 100);
    }

    // ---- Şirket göstergeleri ----------------------------------------
    final Map<String, CompanyVitals> yeniVitals = <String, CompanyVitals>{};
    for (final Company c in kCompanyCatalog) {
      final CompanyVitals mevcut = state.vitalsOf(c.id);
      final CompanyVitals taban = baselineFor(c);
      // Sektör gücünün sapması: zayıf sektör şirketi aşağı çeker.
      final double sektorSapmasi =
          ((yeniSektor[c.sector.name] ?? 50) - 50) * prototypeOnlySectorInfluence;
      // Yönetim kalitesi kötü haberi yumuşatır (§3): iyi yönetim baskının
      // bir kısmını emer.
      final double yonetimKalkani = (mevcut.management - 50) / 100.0;
      final int baski = (rejimBaskisi * (1 - yonetimKalkani * 0.5)).round();

      int adim(int mevcutDeger, int tabanDeger, {int yon = 1}) {
        int v = mevcutDeger +
            (rng.nextInt(2 * prototypeOnlyStep + 1) - prototypeOnlyStep) +
            (yon * (baski + sektorSapmasi)).round();
        v += ((tabanDeger - v) * prototypeOnlyReversion).round();
        return v.clamp(0, 100);
      }

      // Yönetim kalitesi ayrı: küçük adım, zayıf çekiliş, rejimden
      // etkilenmez. Şirketin yönetimi kriz olduğu için kötüleşmez.
      int yonetim = mevcut.management +
          (rng.nextInt(2 * prototypeOnlyManagementStep + 1) -
              prototypeOnlyManagementStep);
      yonetim +=
          ((taban.management - yonetim) * prototypeOnlyManagementReversion)
              .round();

      yeniVitals[c.id] = CompanyVitals(
        financialHealth: adim(mevcut.financialHealth, taban.financialHealth),
        // Borç baskısında yön ters: kötü yıl borcu **artırır**.
        debtPressure: adim(mevcut.debtPressure, taban.debtPressure, yon: -1),
        growth: adim(mevcut.growth, taban.growth),
        management: yonetim.clamp(0, 100),
        confidence: adim(mevcut.confidence, taban.confidence),
      );
    }

    // ---- Sessiz toparlanma (§1) --------------------------------------
    //
    // Göstergeleri düzelen şirket, haber çıkmasını beklemeden bir kademe
    // iyileşebilir. Kapanmış şirket **asla** geri dönmez (§5).
    final Map<String, String> durumDegisimi = <String, String>{};
    for (final Company c in kCompanyCatalog) {
      final CompanyStatus durum = state.statusOf(c.id);
      if (durum == CompanyStatus.normal || durum == CompanyStatus.kapandi) {
        continue;
      }
      final CompanyVitals v = yeniVitals[c.id] ?? state.vitalsOf(c.id);
      if (v.stress > prototypeOnlyQuietRecoveryStress) continue;
      // İyi yönetim toparlanmayı hızlandırır (§3).
      final double sans = prototypeOnlyQuietRecoveryChance *
          (0.5 + (v.management / 100.0));
      if (rng.nextDouble() >= sans) continue;
      final CompanyStatus sonraki = switch (durum) {
        CompanyStatus.inceleme => CompanyStatus.normal,
        CompanyStatus.sikinti => CompanyStatus.inceleme,
        CompanyStatus.konkordato => CompanyStatus.sikinti,
        CompanyStatus.kayyum => CompanyStatus.sikinti,
        CompanyStatus.normal || CompanyStatus.kapandi => durum,
      };
      if (sonraki != durum) durumDegisimi[c.id] = sonraki.name;
    }

    return (
      vitals: Map<String, CompanyVitals>.unmodifiable(yeniVitals),
      sectorStrength: Map<String, int>.unmodifiable(yeniSektor),
      statusChanges: Map<String, String>.unmodifiable(durumDegisimi),
    );
  }
}
