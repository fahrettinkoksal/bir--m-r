import '../models/game_state.dart';
import '../models/owned_item.dart';
import '../models/person.dart';

/// Yıllık temel yaşam gideri (D-033).
///
/// Barınma, beslenme ve faturalar gibi kalemler **karakterin gerçekten
/// yaşadığı hane ve yaşam koşullarına** göre hesaplanır:
/// - Çocuğa yetişkin gideri yüklenmez.
/// - Ailesiyle yaşayan yetişkin ile bağımsız yaşayanın gideri aynı değildir.
/// - Kendi evi olan bağımsız yetişkin kira ödemez.
///
/// Giderler cüzdanı **sessizce eksiye düşürmez**: para yetmezse cüzdan
/// sıfırda kalır, açık bir sonuç yazılır ve **geçim sıkıntısı** sayacı
/// artar. Bütün tutarlar `prototypeOnly`'dir (Q-055).
abstract final class LivingCosts {
  /// prototypeOnly: giderin başladığı yaş.
  static const int prototypeOnlyAdultAge = 18;

  /// prototypeOnly: ailesinin yanında yaşayan yetişkinin katkısı.
  static const int prototypeOnlyWithFamily = 45000;

  /// prototypeOnly: bağımsız yaşayan, kirada oturan yetişkinin gideri.
  static const int prototypeOnlyIndependent = 140000;

  /// prototypeOnly: kendi evinde oturan bağımsız yetişkinin gideri.
  ///
  /// Kira kalemi düşer; beslenme, fatura ve bakım kalır.
  static const int prototypeOnlyOwnHome = 90000;

  /// Oyuncu bu yaşta hane içinde bir yetişkinle mi yaşıyor?
  static bool livesWithFamily(GameState state) => state.people.any(
        (Person p) =>
            p.isAlive && p.inPlayerHousehold && p.age >= prototypeOnlyAdultAge,
      );

  /// Oyuncunun kendi konutu var mı?
  static bool ownsHome(GameState state) =>
      state.items.any((OwnedItem i) => i.isProperty);

  /// Bu yaş için yıllık gider.
  static int yearlyCost(GameState state) {
    if (state.player.age < prototypeOnlyAdultAge) return 0;
    if (livesWithFamily(state)) return prototypeOnlyWithFamily;
    return ownsHome(state) ? prototypeOnlyOwnHome : prototypeOnlyIndependent;
  }

  /// Giderin ekranda görünen kısa açıklaması.
  static String labelFor(GameState state) {
    if (state.player.age < prototypeOnlyAdultAge) {
      return 'Bu yaşta geçim giderin yok.';
    }
    if (livesWithFamily(state)) return 'Ailenin yanında yaşıyorsun.';
    return ownsHome(state)
        ? 'Kendi evinde yaşıyorsun; kira ödemiyorsun.'
        : 'Kirada, kendi başına yaşıyorsun.';
  }

  /// Gideri uygular.
  ///
  /// Cüzdan eksiye düşmez; ödenemeyen kısım **geçim sıkıntısı** olarak
  /// kaydedilir ve günlüğe açık bir satır yazılır.
  static ({GameState state, String? logText}) apply(GameState state) {
    final int gider = yearlyCost(state);
    if (gider <= 0) {
      return (
        state: state.hardshipYears == 0
            ? state
            : state.copyWith(hardshipYears: 0),
        logText: null,
      );
    }

    final int cuzdan = state.player.wallet;
    if (cuzdan >= gider) {
      return (
        state: state.copyWith(
          player: state.player.copyWith(wallet: cuzdan - gider),
          hardshipYears: 0,
        ),
        logText: 'Yıllık geçim giderin $gider ₺ cüzdanından çıktı.',
      );
    }

    // Para yetmiyor: cüzdan sıfırlanır, borç oluşmaz, durum açıkça yazılır.
    final int eksik = gider - cuzdan;
    return (
      state: state.copyWith(
        player: state.player.copyWith(wallet: 0),
        hardshipYears: state.hardshipYears + 1,
      ),
      logText: 'Geçim giderin $gider ₺ tuttu, cüzdanında $cuzdan ₺ vardı. '
          '$eksik ₺ açık kaldı; bu yıl geçim sıkıntısı çektin.',
    );
  }
}
