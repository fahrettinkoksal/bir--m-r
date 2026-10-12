/// Piyasa ve şirket olayları (Paket AC).
///
/// **Neden var.** V1'de piyasanın tek anlatısı yıllık rejimdi: "bu yıl
/// hisse −%20". Ölçüm bunun yetmediğini gösterdi — yatırım uzun vadede
/// neredeyse garanti kazanıyordu, çünkü **kaybettirecek bir olay yoktu**.
/// Bu katman rejimin üstüne tek tek olaylar koyar: şirket batışı,
/// konkordato, işlem sırasının kapanması, fon tasfiyesi, sermaye artırımı.
///
/// Olaylar **her yıl olmaz**. Çoğu yıl sessiz geçer; bazı yıllarda tek bir
/// haber portföyün bir kısmını siler ve oyuncu satmak istese bile
/// satamaz.
///
/// Bütün oranlar ve ihtimaller `prototypeOnly`'dir (Q-168).
library;

import 'package:flutter/foundation.dart';

/// Bir piyasa/şirket olayının türü.
enum IncidentKind {
  // ---- Şirket tarafı -------------------------------------------------
  /// Regülatör/denetim incelemesi başladı. Fiyat baskılanır.
  regulatorIncelemesi('Regülatör incelemesi'),

  /// Bilançoda beklenmeyen açık; yönetici istifası.
  yonetimSkandali('Yönetim krizi'),

  /// Borçlarını çevirmekte zorlanıyor.
  maliSikinti('Mali sıkıntı'),

  /// Konkordato süreci başladı.
  konkordato('Konkordato'),

  /// Yönetime geçici müdahale; işlem durur.
  kayyum('Geçici yönetim'),

  /// Faaliyet durdu. Şirketin sepetteki payı silinir.
  iflas('Faaliyet durdu'),

  /// Şirket para toplamak için sermaye artırdı; değer baskılanır.
  sermayeArtirimi('Sermaye artırımı'),

  /// Beklenmedik temettü: küçük bir nakit girişi.
  temettu('Temettü'),

  /// Satın alma haberi: fiyat yukarı zıplar.
  satinAlma('Satın alma haberi'),

  /// Sektör geneli daralma.
  sektorKrizi('Sektör krizi'),

  /// Sektör geneli açılma.
  sektorPatlamasi('Sektör atağı'),

  // ---- Fon tarafı ----------------------------------------------------
  /// Fon yöneticisi değişti; kısa süreli belirsizlik.
  fonYoneticiDegisti('Fon yöneticisi değişti'),

  /// Fonun büyük yatırımı yanlış çıktı.
  fonYanlisYatirim('Fonun yatırımı ters gitti'),

  /// Fon stratejisini değiştirdi.
  fonStratejiDegisti('Fon stratejisi değişti'),

  /// Fon başka bir fonla birleşti.
  fonBirlesti('Fon birleşti'),

  /// Fon tasfiye ediliyor: pozisyon piyasa değerinden nakde döner.
  fonTasfiye('Fon tasfiye ediliyor'),

  // ---- Piyasa geneli -------------------------------------------------
  /// Sert satış; işlemler kısa süre durabilir.
  piyasaPanigi('Piyasa paniği'),

  /// Faiz sert yükseldi.
  faizSoku('Faiz şoku'),

  /// Kur sert hareket etti.
  kurSoku('Kur şoku'),

  /// Ani yükseliş dalgası.
  aniYukselis('Ani yükseliş'),

  /// Kapanan şirketin yerine sepete **yeni** bir şirket girdi (§5).
  ///
  /// Değer listenin **sonuna** eklendi: eski kayıtlarda enum sırası
  /// bozulmamalı. Kapanan şirketin dirilmesi değil — yeni bir ad.
  yeniSirket('Sepete yeni şirket girdi');

  const IncidentKind(this.label);

  final String label;

  /// Bu olay bir **şirkete** mi bağlı?
  bool get isCompanyEvent => switch (this) {
        IncidentKind.regulatorIncelemesi ||
        IncidentKind.yonetimSkandali ||
        IncidentKind.maliSikinti ||
        IncidentKind.konkordato ||
        IncidentKind.kayyum ||
        IncidentKind.iflas ||
        IncidentKind.sermayeArtirimi ||
        IncidentKind.temettu ||
        IncidentKind.satinAlma ||
        IncidentKind.yeniSirket =>
          true,
        _ => false,
      };

  /// Bu olay **fona** mı bağlı?
  bool get isFundEvent => switch (this) {
        IncidentKind.fonYoneticiDegisti ||
        IncidentKind.fonYanlisYatirim ||
        IncidentKind.fonStratejiDegisti ||
        IncidentKind.fonBirlesti ||
        IncidentKind.fonTasfiye =>
          true,
        _ => false,
      };

  /// Oyuncuya bildirim penceresi açılmalı mı?
  ///
  /// Küçük haberler günlüğe yazılır, pencere açmaz: yılda üç pencere
  /// açmak oyunu yorar.
  bool get opensNotice => switch (this) {
        IncidentKind.iflas ||
        IncidentKind.konkordato ||
        IncidentKind.kayyum ||
        IncidentKind.fonTasfiye ||
        IncidentKind.piyasaPanigi =>
          true,
        _ => false,
      };
}

/// Gerçekleşmiş bir olay kaydı.
///
/// **Kayda girer**: oyuncu ekranı kapatıp açarak olayı yeniden çeviremez
/// ve aynı olay iki kez uygulanmaz.
@immutable
class MarketIncident {
  const MarketIncident({
    required this.kind,
    required this.age,
    this.companyId,
    this.typeId,
    this.impact = 0,
    this.cashDelta = 0,
  });

  final IncidentKind kind;

  /// Olayın yaşandığı oyuncu yaşı.
  final int age;

  /// Şirket olaylarında kurgusal şirketin kimliği.
  final String? companyId;

  /// Etkilenen yatırım türü (`hisse`, `fon`, `doviz`…).
  final String? typeId;

  /// Pozisyona uygulanan oran (−0,12 = −%12). Bilgi amaçlı saklanır.
  final double impact;

  /// Cüzdana giren/çıkan tutar (temettü, tasfiye). ₺.
  final int cashDelta;
}

/// Bir yatırım türünde geçici işlem durması.
///
/// **Oyuncu satmak istese de satamaz.** Gerçek yatırım risklerinden
/// biridir (§5). Süre sonsuz değildir: [untilAge] geldiğinde yeniden
/// açılır.
@immutable
class TradingHalt {
  const TradingHalt({
    required this.typeId,
    required this.untilAge,
    required this.reason,
  });

  final String typeId;

  /// Bu yaşa gelindiğinde işlem yeniden açılır (bu yaş **dahil** açık).
  final int untilAge;

  /// Ekranda gösterilecek kısa gerekçe.
  final String reason;

  bool activeAt(int age) => age < untilAge;
}

/// prototypeOnly: işlem durmasının en kısa ve en uzun süresi (yıl).
const int kHaltMinYears = 1;
const int kHaltMaxYears = 2;
