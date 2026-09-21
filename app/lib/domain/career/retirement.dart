import '../../text/turkish_text.dart';
import '../models/career.dart';
import '../models/game_state.dart';
import '../models/interaction.dart';
import '../models/life_log.dart';

/// Emeklilik sonucu.
class RetirementResult {
  const RetirementResult({
    required this.state,
    required this.text,
    this.applied = false,
  });

  final GameState state;
  final String text;
  final bool applied;
}

/// Emeklilik ve emekli aylığı (Paket 12).
///
/// Şimdiye kadar oyuncu hiç emekli olamıyordu: 90 yaşında bile aynı işte
/// çalışmaya devam ediyordu. Artık emeklilik gerçek bir karar.
///
/// **Buradaki hiçbir sayı gerçek bir ülkenin emeklilik mevzuatını
/// anlatmaz**; oyun içi, geri alınabilir değerlerdir (`prototypeOnly`,
/// Q-081).
abstract final class Retirement {
  /// prototypeOnly: tam emeklilik yaşı.
  static const int prototypeOnlyFullAge = 65;

  /// prototypeOnly: erken emekli olunabilecek en küçük yaş.
  static const int prototypeOnlyEarlyAge = 60;

  /// prototypeOnly: aylık bağlanması için gereken toplam çalışma yılı.
  static const int prototypeOnlyMinWorkYears = 10;

  /// prototypeOnly: aylığın son maaşa oranının tabanı.
  static const double prototypeOnlyBaseRatio = 0.35;

  /// prototypeOnly: her çalışma yılının orana kattığı pay.
  static const double prototypeOnlyRatioPerYear = 0.01;

  /// prototypeOnly: oranın üst sınırı.
  static const double prototypeOnlyMaxRatio = 0.75;

  /// prototypeOnly: erken emekliliğin aylığa uyguladığı kesinti.
  static const double prototypeOnlyEarlyPenalty = 0.8;

  /// prototypeOnly: yeterli çalışma yılı olmayana bağlanan asgari aylık.
  ///
  /// Hiç çalışmamış oyuncunun ileri yaşta tamamen parasız kalmaması için
  /// konmuştur; gerçek bir sosyal yardım iddiası değildir.
  static const int prototypeOnlyMinimumPension = 60000;

  /// prototypeOnly: emekli olmanın mutluluk etkisi.
  static const int prototypeOnlyHappiness = 5;

  /// Emeklilik şu an mümkün mü?
  static InteractionAvailability availability(GameState state) {
    final CareerState career = state.career;
    if (career.isRetired) {
      return const InteractionAvailability.blocked('Zaten emeklisin.');
    }
    if (state.player.age < prototypeOnlyEarlyAge) {
      return InteractionAvailability.blocked(
        'Emeklilik en erken $prototypeOnlyEarlyAge yaşında konuşulur.',
      );
    }
    return const InteractionAvailability.allowed();
  }

  /// prototypeOnly: bu koşullarda bağlanacak yıllık aylık.
  ///
  /// Son maaş ve çalışılan toplam yıl belirleyicidir; erken emeklilikte
  /// kesinti uygulanır. Hiç çalışmamış oyuncuya asgari aylık bağlanır.
  static int prototypeOnlyPensionFor(GameState state) {
    final CareerState career = state.career;
    final int yil = career.totalWorkYears(state.player.age);
    if (yil < prototypeOnlyMinWorkYears) return prototypeOnlyMinimumPension;

    // Son maaş: süren iş varsa onun maaşı, yoksa en son kapanan kaydınki.
    final int sonMaas = career.isEmployed
        ? career.yearlySalary
        : (career.history.isEmpty
            ? 0
            : career.history.last.salary ?? 0);
    if (sonMaas <= 0) return prototypeOnlyMinimumPension;

    final double oran = (prototypeOnlyBaseRatio + yil * prototypeOnlyRatioPerYear)
        .clamp(prototypeOnlyBaseRatio, prototypeOnlyMaxRatio);
    final double erken = state.player.age < prototypeOnlyFullAge
        ? prototypeOnlyEarlyPenalty
        : 1.0;
    final int aylik = (sonMaas * oran * erken).round();
    return aylik < prototypeOnlyMinimumPension
        ? prototypeOnlyMinimumPension
        : aylik;
  }

  /// Emekli eder. Süren iş kariyer geçmişine yazılır, aylık bağlanır.
  static RetirementResult retire(GameState state) {
    final InteractionAvailability uygunluk = availability(state);
    if (!uygunluk.isAllowed) {
      return RetirementResult(state: state, text: uygunluk.reason!);
    }

    final int age = state.player.age;
    final int aylik = prototypeOnlyPensionFor(state);
    final bool erken = age < prototypeOnlyFullAge;
    final int yil = state.career.totalWorkYears(age);

    CareerState career = state.career;
    if (career.isEmployed) {
      career = career
          .withMilestone(age, 'Bu işten emekli oldun.')
          .closeCurrentJob(endedAtAge: age, reason: JobEndReason.emeklilik);
    }
    career = career.copyWith(
      retiredAtAge: age,
      pension: aylik,
      // Aylık, emekli olunan yıl için ödenmez; ilk ödeme sonraki yaşta.
      lastPaidAge: age,
    );

    final String metin = erken
        ? 'Erken emekli oldun. Toplam $yil yıl çalıştın; yıllık aylığın '
            '${trMoney(aylik)}. Erken ayrıldığın için aylık biraz düşük '
            'bağlandı.'
        : 'Emekli oldun. Toplam $yil yıl çalıştın; yıllık aylığın '
            '${trMoney(aylik)}.';

    final GameState next = state.copyWith(
      career: career,
      player: state.player.copyWith(
        stats: state.player.stats.copyWith(
          happiness: state.player.stats.happiness + prototypeOnlyHappiness,
        ),
      ),
    );

    return RetirementResult(
      state: _log(next, metin),
      text: metin,
      applied: true,
    );
  }

  /// Yeni yaşa geçerken emekli aylığını **bir kez** öder.
  ///
  /// [CareerState.lastPaidAge] maaşla aynı alanı kullanır; emekli olan
  /// oyuncu hem maaş hem aylık alamaz.
  static ({GameState state, String? logText}) payPension(
    GameState state,
    int newAge,
  ) {
    final CareerState career = state.career;
    if (!career.isRetired) return (state: state, logText: null);
    final int aylik = career.pension ?? 0;
    if (aylik <= 0) return (state: state, logText: null);
    final int? sonOdeme = career.lastPaidAge;
    if (sonOdeme != null && sonOdeme >= newAge) {
      return (state: state, logText: null);
    }

    return (
      state: state.copyWith(
        player: state.player.copyWith(
          wallet: state.player.wallet + aylik,
        ),
        career: career.copyWith(lastPaidAge: newAge),
      ),
      logText: 'Emekli aylığın yattı: ${trMoney(aylik)}.',
    );
  }

  static GameState _log(GameState state, String text) => state.copyWith(
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
