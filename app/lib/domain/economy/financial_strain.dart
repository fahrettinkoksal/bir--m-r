/// Oyuncunun **gerçek** mali durumu (D-092).
///
/// **Neden var:** Faho bildirdi — cüzdanında 3.000.000 ₺ varken
/// "ay sonunu çok zor getirdin" gibi olaylar çıkıyordu. Finans olayları
/// mutlak bir işarete ya da eski geçmişe bakıyordu; paranın kendisine
/// bakmıyordu.
///
/// Burada durum **hesaplanır**: eldeki nakit ve düzenli gelir bir yanda,
/// yaşam gideri ve kredi taksitleri öte yanda. Varlıklı oyuncuya
/// yoksulluk metni çıkmaz; parasız oyuncuya da "her şey yolunda" denmez.
///
/// Eşikler `prototypeOnly` (Q-122).
library;

import '../models/game_state.dart';
import 'banking.dart';
import 'living_costs.dart';

/// Mali durumun kaba kademesi.
///
/// Sıra **anlamlıdır**: küçükten büyüğe rahatlık artar. Olay koşulları
/// bu sırayı kullanır (`index` karşılaştırmasıyla).
enum FinancialComfort {
  /// Gideri karşılayamıyor.
  sikinti('Geçim sıkıntısı'),

  /// Ay sonunu zor getiriyor.
  zor('Ay sonu zor'),

  /// İdare ediyor.
  idare('İdare ediyor'),

  /// Rahat; birikim yapabiliyor.
  rahat('Rahat'),

  /// Varlıklı; para bir sorun değil.
  varlikli('Varlıklı');

  const FinancialComfort(this.label);

  final String label;

  /// Bu kademe yoksulluk anlatan bir olayı hak ediyor mu?
  bool get isStrained =>
      this == FinancialComfort.sikinti || this == FinancialComfort.zor;
}

abstract final class FinancialStrain {
  /// prototypeOnly: kademe eşikleri (yıllık gidere oran).
  ///
  /// Oran = (nakit + yıllık gelir) / (yıllık gider + yıllık taksit).
  /// 1,0 demek "gelir gideri tam karşılıyor" demektir.
  static const double prototypeOnlySikintiBelow = 1.0;
  static const double prototypeOnlyZorBelow = 1.6;
  static const double prototypeOnlyIdareBelow = 3.0;
  static const double prototypeOnlyRahatBelow = 8.0;

  /// Bankanın da saydığı düzenli yıllık gelir.
  static int yearlyIncome(GameState state) => Banking.assessedIncome(state);

  /// Yıllık zorunlu çıkış: yaşam gideri + kredi taksitleri.
  static int yearlyOutgoings(GameState state) =>
      LivingCosts.yearlyCost(state) + Banking.annualBurden(state);

  /// Rahatlık oranı.
  ///
  /// Gideri olmayan (ailesinin yanında yaşayan, borçsuz) oyuncuda bölme
  /// yapılamaz; o durumda nakit tek başına bakılır.
  static double ratio(GameState state) {
    final int gider = yearlyOutgoings(state);
    final int giris = state.player.wallet + yearlyIncome(state);
    if (gider <= 0) {
      // Gideri yoksa sıkıntı da yok; nakitsizse yine de rahat sayılmaz.
      return giris > 0 ? prototypeOnlyRahatBelow : prototypeOnlyZorBelow;
    }
    return giris / gider;
  }

  /// Oyuncunun mali kademesi.
  static FinancialComfort comfortOf(GameState state) {
    // Geçim sıkıntısı zaten ölçülmüş bir durumdur; ona güvenilir.
    if (state.hardshipYears > 0) return FinancialComfort.sikinti;

    final double oran = ratio(state);
    if (oran < prototypeOnlySikintiBelow) return FinancialComfort.sikinti;
    if (oran < prototypeOnlyZorBelow) return FinancialComfort.zor;
    if (oran < prototypeOnlyIdareBelow) return FinancialComfort.idare;
    if (oran < prototypeOnlyRahatBelow) return FinancialComfort.rahat;
    return FinancialComfort.varlikli;
  }

  /// Oyuncu para sıkıntısı çekiyor mu?
  static bool isStrained(GameState state) => comfortOf(state).isStrained;
}
