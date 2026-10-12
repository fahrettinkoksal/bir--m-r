// İş + spor çatışması (Paket AL/2, §20-§25, §29).
//
// **Sorun.** Paket AL/VERIFY ölçtü: tam zamanlı çalışan sporcu ile hiç
// çalışmayan sporcu aynı kazanma ihtimaline, aynı müsabaka fırsatına ve
// aynı sonuca sahipti. Çalışmak bedelsizdi.
//
// **Ne yapmıyor.** Yeni bir stamina/yorgunluk motoru kurmuyor (Paket AL
// §36 hâlâ geçerli). Mesleğe göre ayrı fatigue tablosu da yok (§23):
// tam zamanlı iş tek sınıf.
//
// **Bedel nereden geliyor.** İki yerden, ikisi de zaman üzerinden:
//
// 1. **Fırsat** — çalışan sporcu antrenmana ve müsabaka takvimine daha
//    az yetişir; yıllık müsabaka fırsatı ihtimali düşer
//    (`CombatCareerEngine.offerBout`).
// 2. **Form** — işten artan zamanla kondisyonu korumak zorlaşır; yıllık
//    form telafisi azalır (`CombatCareerEngine.advanceYear`).
//
// **Kazanma ihtimaline doğrudan ceza yok** (§25). "Tam zamanlı iş =
// -%20 kazanma şansı" gibi kaba bir kesinti bilerek yazılmadı. İşin
// etkisi forma, formdan da güce yansır; yani dolaylıdır ve oyuncu
// dinlenerek, kamp yaparak, koç tutarak telafi edebilir.
library;

import '../../data/job_catalog.dart';
import '../models/game_state.dart';

/// Sporcunun üzerindeki iş yükü (§22).
enum SportWorkLoad {
  /// İşsiz, öğrenci ya da emekli: iş kaynaklı bedel yok.
  yok('Çalışmıyor'),

  /// Yarım zamanlı iş: çok küçük bedel.
  yariZamanli('Yarım zamanlı iş'),

  /// Tam zamanlı iş: anlamlı ama kariyeri öldürmeyen bedel.
  tamZamanli('Tam zamanlı iş');

  const SportWorkLoad(this.label);

  final String label;
}

/// İşin spor kariyerine zaman maliyeti.
abstract final class SportWorkload {
  /// prototypeOnly: müsabaka fırsatı ihtimalinin iş yüküne göre çarpanı.
  ///
  /// Tam zamanlı iş fırsatı **azaltır, sıfırlamaz** (§24). En kötü
  /// durumda bile çarpan pozitiftir; çalışan sporcunun kariyeri kapanmaz.
  ///
  /// **Ölçümle kalibre edildi.** İlk yazımda tam zamanlı çarpan 0,72
  /// idi. 200 çalışan sporcu ölçümünde bu, tek yıllık %28'lik bir
  /// kesinti gibi görünmesine rağmen kariyer boyunca %55 fırsat
  /// kaybına ve kariyer sonu formun 3,8'e çökmesine yol açtı: az maç →
  /// az form telafisi → düşük form → daha az fırsat sarmalı. §21 "anlamlı
  /// ama kariyeri öldürmeyen" diyor; bu onu öldürüyordu. Katsayı
  /// yumuşatıldı.
  static const Map<SportWorkLoad, double> prototypeOnlyOpportunityFactor =
      <SportWorkLoad, double>{
    SportWorkLoad.yok: 1.00,
    SportWorkLoad.yariZamanli: 0.94,
    SportWorkLoad.tamZamanli: 0.84,
  };

  /// prototypeOnly: yıllık form telafisinden düşülen pay.
  ///
  /// `CombatCareerEngine.advanceYear` içindeki telafi (ders + müsabaka +
  /// zirve bakımı) bu kadar azalır. Telafi zaten 0'ın altına inmiyor;
  /// yani iş formu doğrudan eritmez, korumayı zorlaştırır.
  ///
  /// Bu da yukarıdakiyle birlikte yumuşatıldı (tam zamanlı 4 → 2):
  /// fırsat kaybı ile form kaybı birbirini besliyor, ikisi birden
  /// yüksek olunca kariyer kapanıyor.
  static const Map<SportWorkLoad, int> prototypeOnlyFormUpkeepCost =
      <SportWorkLoad, int>{
    SportWorkLoad.yok: 0,
    SportWorkLoad.yariZamanli: 1,
    SportWorkLoad.tamZamanli: 2,
  };

  /// Oyuncunun şu anki iş yükü.
  ///
  /// Emekli ya da işsiz oyuncu `yok` sayılır. Mesleğin kendisi
  /// bakılmaz, yalnızca `JobType.partTime` bayrağı okunur (§23).
  static SportWorkLoad of(GameState state) {
    final String? isId = state.career.jobId;
    if (isId == null) return SportWorkLoad.yok;
    final JobType? meslek = jobById(isId);
    if (meslek == null) return SportWorkLoad.yok;
    return meslek.partTime
        ? SportWorkLoad.yariZamanli
        : SportWorkLoad.tamZamanli;
  }

  /// Müsabaka fırsatı ihtimalinin çarpanı (§21, §24).
  static double opportunityFactor(GameState state) =>
      prototypeOnlyOpportunityFactor[of(state)] ?? 1.0;

  /// Yıllık form telafisinden düşülen pay (§21).
  static int formUpkeepCost(GameState state) =>
      prototypeOnlyFormUpkeepCost[of(state)] ?? 0;

  /// Spor ekranında gösterilecek açıklama; bedel yoksa `null` (§29).
  ///
  /// Yüzde göstermez: oyuncuya matematik değil durum anlatılır.
  static String? note(GameState state) => switch (of(state)) {
        SportWorkLoad.yok => null,
        SportWorkLoad.yariZamanli =>
          'Yarım zamanlı işin hazırlığından biraz zaman götürüyor.',
        SportWorkLoad.tamZamanli =>
          'Tam zamanlı işin hazırlık için ayırabildiğin zamanı azaltıyor.',
      };
}
