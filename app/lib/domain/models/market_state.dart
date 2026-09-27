/// Piyasanın o yıldaki hâli (D-162).
library;

import 'package:flutter/foundation.dart';

import '../../data/company_catalog.dart';
import 'market_incident.dart';

/// Yıllık piyasa rejimi.
///
/// Her varlık kendi başına zar atmaz; yılın rejimi ortak etkenleri belirler
/// ve varlıklar o etkenlere kendi ağırlıklarıyla tepki verir.
enum MarketRegime {
  durgun('Durgun'),
  normal('Normal'),
  guclu('Güçlü'),
  kriz('Kriz'),

  /// Krizin ardından gelen **toparlanma** (Paket AC, §11).
  ///
  /// V1'de kriz tek yıllıktı ve ertesi yıl doğrudan "güçlü" olabiliyordu;
  /// bu "krizde al, ertesi yıl kesin toparlar" exploitini üretiyordu.
  /// Artık kriz 1-3 yıl sürüyor ve çıkışı bu rejimden geçiyor:
  /// toparlanma yukarı eğilimli ama **hâlâ oynak**, garanti değil.
  toparlanma('Toparlanma');

  const MarketRegime(this.label);

  final String label;

  /// Oyuncuya gösterilebilecek kadar belirgin bir yıl mı?
  bool get isNotable =>
      this == MarketRegime.kriz ||
      this == MarketRegime.guclu ||
      this == MarketRegime.toparlanma;

  /// Kriz baskısı sürüyor mu?
  bool get isStressed => this == MarketRegime.kriz;

  /// Ekranda yazılan gözlem cümlesi.
  ///
  /// Bilerek **sayı vermiyor ve tavsiye etmiyor**: yılın havasını anlatır,
  /// "şunu al" demez. Dil sokak Türkçesi (`docs/WRITING_STYLE_TR.md`).
  String get mood => switch (this) {
        MarketRegime.durgun => 'Piyasa bu aralar uyuşuk, kimse acele etmiyor.',
        MarketRegime.normal => 'Piyasa olağan hâlinde, iniş çıkış normal.',
        MarketRegime.guclu => 'Piyasada hareket var, herkes iyimser.',
        MarketRegime.kriz => 'Piyasa karışık, ortalık gergin.',
        MarketRegime.toparlanma =>
          'Piyasa toparlanmaya çalışıyor; kimse emin değil.',
      };
}

/// Piyasanın kalıcı durumu.
///
/// **Kayda girer.** Böylece oyuncu ekranı kapatıp açarak fiyatı yeniden
/// çeviremez ve kayıt geri yüklenince aynı fiyatlar döner.
///
/// [priceIndex] her varlık türü için **baz puan** tutar: 10.000 = 1,00.
/// Tamsayı tutuluyor, çünkü kayıt tarafında kesir yuvarlama kaymasına
/// açıktır ve bu oyunda paranın doğrusu tamsayıdır.
@immutable
class MarketState {
  const MarketState({
    this.regime = MarketRegime.normal,
    this.inflationPressure = 50,
    this.confidence = 50,
    this.priceIndex = const <String, int>{},
    this.advancedAtAge,
    this.lastNoticeAge,
    this.regimeYearsLeft = 0,
    this.companyStatus = const <String, String>{},
    this.halts = const <TradingHalt>[],
    this.incidents = const <MarketIncident>[],
  });

  /// Baz puan ölçeği: 10.000 = 1,00.
  static const int basis = 10000;

  final MarketRegime regime;

  /// Gizli parametre (0-100): enflasyon baskısı.
  ///
  /// Oyuncuya sayı olarak gösterilmez; yalnızca varlıkların davranışını
  /// kaydırır.
  final int inflationPressure;

  /// Gizli parametre (0-100): piyasa güveni.
  final int confidence;

  /// Varlık kimliği -> fiyat endeksi (baz puan). Eksik anahtar 1,00 sayılır.
  final Map<String, int> priceIndex;

  /// Piyasanın **en son ilerletildiği** yaş.
  ///
  /// Yaş başına bir kez ilerler; aynı yıl içinde ekran açıp kapamak fiyatı
  /// değiştirmez.
  final int? advancedAtAge;

  /// En son piyasa bildirimi verilen yaş; her yıl pencere açılmaz.
  final int? lastNoticeAge;

  /// Yürüyen rejimin **kalan zorunlu yılı** (Paket AC, §11).
  ///
  /// Kriz başlarken 1-3 arası çekilir ve her yıl bir azalır; sıfıra
  /// gelmeden rejim değişmez. Böylece kriz tek yıllık olmaktan çıkar ve
  /// "krizde al, ertesi yıl toparlar" garantisi kalkar.
  final int regimeYearsLeft;

  /// Kurgusal şirket kimliği -> [CompanyStatus.name].
  ///
  /// Enum değil **metin** tutuluyor: kayıt ileri sürümlerde tanımadığı
  /// bir durumla karşılaşırsa çökmek yerine `normal` okur.
  final Map<String, String> companyStatus;

  /// Yürüyen işlem durmaları.
  final List<TradingHalt> halts;

  /// Yaşanmış olayların kaydı. Aynı olay iki kez uygulanmaz.
  final List<MarketIncident> incidents;

  /// Bu şirketin durumu; kayıtta yoksa ya da tanınmıyorsa `normal`.
  CompanyStatus statusOf(String companyId) {
    final String? ad = companyStatus[companyId];
    if (ad == null) return CompanyStatus.normal;
    for (final CompanyStatus d in CompanyStatus.values) {
      if (d.name == ad) return d;
    }
    return CompanyStatus.normal;
  }

  /// Bu türde [age] yaşında işlem durmuş mu?
  TradingHalt? haltFor(String typeId, int age) {
    for (final TradingHalt h in halts) {
      if (h.typeId == typeId && h.activeAt(age)) return h;
    }
    return null;
  }

  /// Faaliyeti duran şirketler.
  Set<String> get closedCompanies => <String>{
        for (final String id in companyStatus.keys)
          if (statusOf(id) == CompanyStatus.kapandi) id,
      };

  /// Bu varlığın endeksi (baz puan). Hiç işlem görmemişse 1,00.
  int indexOf(String typeId) => priceIndex[typeId] ?? basis;

  MarketState copyWith({
    MarketRegime? regime,
    int? inflationPressure,
    int? confidence,
    Map<String, int>? priceIndex,
    int? advancedAtAge,
    int? lastNoticeAge,
    int? regimeYearsLeft,
    Map<String, String>? companyStatus,
    List<TradingHalt>? halts,
    List<MarketIncident>? incidents,
  }) =>
      MarketState(
        regime: regime ?? this.regime,
        inflationPressure:
            (inflationPressure ?? this.inflationPressure).clamp(0, 100),
        confidence: (confidence ?? this.confidence).clamp(0, 100),
        priceIndex: priceIndex ?? this.priceIndex,
        advancedAtAge: advancedAtAge ?? this.advancedAtAge,
        lastNoticeAge: lastNoticeAge ?? this.lastNoticeAge,
        regimeYearsLeft:
            (regimeYearsLeft ?? this.regimeYearsLeft) < 0 ? 0 : (regimeYearsLeft ?? this.regimeYearsLeft),
        companyStatus: companyStatus ?? this.companyStatus,
        halts: halts ?? this.halts,
        incidents: incidents ?? this.incidents,
      );
}

/// Bir yılın varlık başına getirisi (oran: 0,12 = +%12).
@immutable
class MarketYear {
  const MarketYear({
    required this.regime,
    required this.returns,
    this.incidents = const <MarketIncident>[],
  });

  final MarketRegime regime;

  /// Bu yıl gerçekleşen olaylar (Paket AC).
  final List<MarketIncident> incidents;

  /// Varlık kimliği -> o yılın getirisi.
  final Map<String, double> returns;

  /// Endeksle hareket eden varlıkların ortalama getirisi.
  double get average {
    if (returns.isEmpty) return 0;
    double toplam = 0;
    for (final double d in returns.values) {
      toplam += d;
    }
    return toplam / returns.length;
  }
}
