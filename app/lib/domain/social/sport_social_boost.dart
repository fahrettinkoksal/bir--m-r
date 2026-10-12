// Spor başarısının sosyal medya performansına etkisi
// (Paket AL/2, §10-§14, §18).
//
// **Sorun.** Paket AL/VERIFY ölçtü: aktif şampiyon sporcu ile aynı
// takipçiye sahip sıradan oyuncunun paylaşım performansı **birebir
// aynıydı**. Ringde kazandığın hiçbir şey ekranda karşılığını
// bulmuyordu.
//
// **Nasıl bağlandı.** Yeni bir paylaşım motoru kurulmadı (§11): spor
// başarısı, mevcut `SocialEngine` erişim hesabına giren bir **çarpan**
// olarak giriyor. İçeriğin spora ne kadar yakın olduğu kataloğa eklenen
// `SocialContent.sportRelevance` alanından okunuyor; yemek tarifi
// videosunda şampiyonluk hiçbir şey değiştirmiyor.
//
// **Tazelik** (§12). Geçen yıl kazanılan kemer ile on yıl önce
// kazanılan kemer aynı ilgiyi görmez. Yakın dönem başarı tam,
// eski başarı yalnızca küçük bir legacy payı taşır.
//
// **Para exploit'i yok** (§13). Bu modül yalnızca **erişimi**
// büyütüyor; paylaşım başına para üretmiyor. Sıradan paylaşımın kazancı
// D-117 gereği zaten sıfır; gelir yine sponsorluk ve mevcut gelir
// sisteminden geliyor.
library;

import '../../data/social_catalog.dart';
import '../combat/sport_rivalry.dart';
import '../models/combat_career.dart';
import '../models/game_state.dart';

/// Spor başarısının sosyal medyaya yansıması.
abstract final class SportSocialBoost {
  /// prototypeOnly: tam spor içeriğinde erişime eklenebilecek en
  /// yüksek pay.
  ///
  /// Üst sınır bilerek ölçülü: §11'in kuralı "her post viral olmasın".
  static const double prototypeOnlyMaxGain = 0.60;

  /// prototypeOnly: başarının tazeliğini yitirdiği süre (yıl).
  static const int prototypeOnlyFreshnessYears = 5;

  /// prototypeOnly: tazeliği geçmiş başarının kalıcı payı (§12).
  static const double prototypeOnlyLegacyShare = 0.25;

  /// prototypeOnly: puanın bileşen ağırlıkları.
  static const double prototypeOnlyReputationWeight = 0.40;
  static const double prototypeOnlyTitleWeight = 0.45;
  static const double prototypeOnlyActiveChampionBonus = 0.15;

  /// prototypeOnly: unvan bileşeninin doyduğu şampiyonluk sayısı.
  static const int prototypeOnlyTitleSaturation = 3;

  /// Spor başarısının ham puanı (0-1), tazelik uygulanmadan.
  static double rawScore(CombatCareer career) {
    final double itibar =
        (career.reputation / 100).clamp(0.0, 1.0) * prototypeOnlyReputationWeight;
    final double unvan =
        (career.championships / prototypeOnlyTitleSaturation).clamp(0.0, 1.0) *
            prototypeOnlyTitleWeight;
    final double aktif =
        career.isChampion ? prototypeOnlyActiveChampionBonus : 0.0;
    return (itibar + unvan + aktif).clamp(0.0, 1.0);
  }

  /// Bu kariyerin tazelik uygulanmış puanı (0-1).
  static double scoreOf(CombatCareer career, int age) {
    final double ham = rawScore(career);
    if (ham <= 0) return 0;

    // Tazelik son unvandan ya da son müsabakadan, hangisi daha yeniyse.
    final int son = <int>[
      career.lastTitleAge ?? -999,
      career.lastBoutAge ?? -999,
    ].reduce((int a, int b) => a > b ? a : b);
    if (son <= -999) return ham * prototypeOnlyLegacyShare;

    final int gecen = age - son;
    final double tazelik =
        (1 - gecen / prototypeOnlyFreshnessYears).clamp(0.0, 1.0);

    // Yakın başarı tam etkili; eski başarı yalnızca legacy payı kadar.
    return ham *
        (prototypeOnlyLegacyShare +
            (1 - prototypeOnlyLegacyShare) * tazelik);
  }

  /// Oyuncunun en güçlü spor başarısı puanı (0-1).
  static double achievementScore(GameState state) {
    double en = 0;
    for (final CombatCareer c in state.combatCareers) {
      final double p = scoreOf(c, state.player.age);
      if (p > en) en = p;
    }
    return en;
  }

  /// Açık bir rekabetin kattığı ek ilgi (§18).
  static double rivalryInterest(GameState state) {
    double en = 0;
    for (final CombatCareer c in state.combatCareers) {
      if (c.isRetired) continue;
      final double p = SportRivalry.socialInterest(c, state.player.age);
      if (p > en) en = p;
    }
    return en;
  }

  /// Başarı ve rekabetin **birlikte** yarattığı ilgi (0-1).
  ///
  /// Toplama değil: iki etki lineer toplanırsa şampiyon + rekabet
  /// kombinasyonu takipçiyi patlatır (§18). Bunun yerine tamamlayıcı
  /// olasılık kuralıyla birleşiyorlar; ikisi de yüksekken bile sonuç
  /// 1'i aşmıyor ve doyuma gidiyor.
  static double interest(GameState state) {
    final double basari = achievementScore(state);
    final double rekabet = rivalryInterest(state);
    if (basari <= 0 && rekabet <= 0) return 0;
    return (1 - (1 - basari) * (1 - rekabet)).clamp(0.0, 1.0);
  }

  /// Bu içeriğin erişim çarpanı.
  ///
  /// Spor ile ilgisi olmayan içerikte **tam olarak 1.0** döner: şampiyon
  /// olmak yemek tarifini daha çok izletmez (§11).
  static double multiplierFor(GameState state, SocialContent content) {
    if (content.sportRelevance <= 0) return 1.0;
    final double ilgi = interest(state);
    if (ilgi <= 0) return 1.0;
    return 1.0 + ilgi * content.sportRelevance * prototypeOnlyMaxGain;
  }

  /// Ekranda gösterilecek kısa açıklama; etki yoksa `null`.
  ///
  /// Yüzde göstermez.
  static String? note(GameState state) {
    final double ilgi = interest(state);
    if (ilgi < 0.15) return null;
    return ilgi >= 0.5
        ? 'Spor başarın konuşuluyor; spor içeriklerin daha çok ilgi '
            'görüyor.'
        : 'Spor tarafındaki adın spor içeriklerine biraz ilgi '
            'getiriyor.';
  }
}
