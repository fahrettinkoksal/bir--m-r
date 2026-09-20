import 'dart:math';

import '../models/game_state.dart';
import '../models/interaction.dart';
import '../models/life_log.dart';
import 'blackjack.dart';
import '../../text/turkish_text.dart';

/// Rulette oynanabilen bahis türleri.
enum RouletteBetType {
  kirmizi('Kırmızı', 1),
  siyah('Siyah', 1),
  tek('Tek', 1),
  cift('Çift', 1),
  sayi('Sayıya', 35);

  const RouletteBetType(this.label, this.payoutRatio);

  final String label;

  /// Kazanınca bahsin kaç katı **ek** ödeme yapılır (bahis ayrıca geri gelir).
  final int payoutRatio;
}

/// Bir rulet çevirmesinin sonucu.
class RouletteSpin {
  const RouletteSpin({
    required this.number,
    required this.won,
    required this.payout,
  });

  /// Gelen sayı (0-36).
  final int number;
  final bool won;

  /// Cüzdana dönen toplam (bahis dâhil); kaybedilince 0.
  final int payout;

  bool get isZero => number == 0;
  bool get isRed => kRouletteRedNumbers.contains(number);
  String get colorLabel => number == 0 ? 'Yeşil' : (isRed ? 'Kırmızı' : 'Siyah');
  String get label => '$number ($colorLabel)';
}

/// Avrupa ruletinde kırmızı sayılar. 0 yeşildir.
const Set<int> kRouletteRedNumbers = <int>{
  1, 3, 5, 7, 9, 12, 14, 16, 18, 19, 21, 23, 25, 27, 30, 32, 34, 36,
};

/// Tek sıfırlı (Avrupa) rulet.
///
/// Sonuç oyuncunun kazanmasını veya kaybetmesini sağlamak için gizlice
/// değiştirilmez: sayı tek bir `rng.nextInt(37)` çağrısıyla belirlenir ve
/// ödeme açık orana göre hesaplanır.
class Roulette {
  const Roulette();

  /// Çarkta kaç bölme var (0-36).
  static const int pockets = 37;

  InteractionAvailability spinAvailability(GameState state, int bet) {
    final InteractionAvailability temel = CasinoAccess.check(state);
    if (!temel.isAllowed) return temel;
    return CasinoAccess.checkBet(state, bet);
  }

  /// Bahsi oynar ve çarkı çevirir.
  ///
  /// [number] yalnızca [RouletteBetType.sayi] için gereklidir.
  CasinoResult spin(
    GameState state,
    RouletteBetType type,
    int bet,
    Random rng, {
    int? number,
  }) {
    final InteractionAvailability check = spinAvailability(state, bet);
    if (!check.isAllowed) return _blocked(state, check.reason!);
    if (type == RouletteBetType.sayi &&
        (number == null || number < 0 || number > 36)) {
      return _blocked(state, '0 ile 36 arasında bir sayı seçmen gerekiyor.');
    }

    final int gelen = rng.nextInt(pockets);
    final bool kazandi = _wins(type, number, gelen);
    final int odeme = kazandi ? bet + bet * type.payoutRatio : 0;

    // Bahis düşer ve kazanç eklenir: cüzdan bir kez etkilenir.
    GameState next = state.copyWith(
      player: state.player.copyWith(
        wallet: state.player.wallet - bet + odeme,
      ),
      wagerThisAge: state.wagerThisAge + bet,
    );

    final int net = odeme - bet;
    final String sonucMetni = 'Rulet: çark ${_numberLabel(gelen)} '
        'üzerinde durdu. '
        '${net > 0 ? '${trMoney(net)} kazandın.' : '${trMoney(bet)} kaybettin.'}';
    next = _log(next, sonucMetni);

    return CasinoResult(
      state: next,
      outcome: CasinoOutcome(
        applied: true,
        text: '${_betLabel(type, number)} · $sonucMetni',
        walletDelta: net,
      ),
    );
  }

  /// Bahsin kazanıp kazanmadığı.
  ///
  /// 0 geldiğinde renk ve tek/çift bahisleri kaybeder; yalnızca 0'a
  /// oynanan sayı bahsi kazanır.
  bool _wins(RouletteBetType type, int? number, int gelen) {
    switch (type) {
      case RouletteBetType.sayi:
        return number == gelen;
      case RouletteBetType.kirmizi:
        return gelen != 0 && kRouletteRedNumbers.contains(gelen);
      case RouletteBetType.siyah:
        return gelen != 0 && !kRouletteRedNumbers.contains(gelen);
      case RouletteBetType.tek:
        return gelen != 0 && gelen.isOdd;
      case RouletteBetType.cift:
        return gelen != 0 && gelen.isEven;
    }
  }

  String _numberLabel(int gelen) {
    if (gelen == 0) return '0 (yeşil)';
    return '$gelen (${kRouletteRedNumbers.contains(gelen) ? 'kırmızı' : 'siyah'})';
  }

  String _betLabel(RouletteBetType type, int? number) =>
      type == RouletteBetType.sayi
          ? '$number sayısına bahis'
          : '${type.label} bahsi';

  CasinoResult _blocked(GameState state, String reason) => CasinoResult(
        state: state,
        outcome: CasinoOutcome(applied: false, text: reason),
      );

  GameState _log(GameState state, String text) => state.copyWith(
        log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
          ...state.log,
          LifeLogEntry(
            age: state.player.age,
            text: text,
            category: LogCategory.kisisel,
          ),
        ]),
      );
}
