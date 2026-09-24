import 'dart:math';

import '../../data/health_crisis_catalog.dart';
import '../models/game_state.dart';
import '../models/life_log.dart';
import '../models/pending_crisis.dart';

/// Bir krize verilen yanıtın sonucu.
class CrisisOutcome {
  const CrisisOutcome({
    required this.applied,
    required this.text,
    this.survived = true,
    this.cost = 0,
  });

  final bool applied;
  final String text;

  /// Oyuncu krizi atlattı mı?
  final bool survived;

  /// Ödenen bedel.
  final int cost;
}

class CrisisResult {
  const CrisisResult({required this.state, required this.outcome});

  final GameState state;
  final CrisisOutcome outcome;
}

/// Hastalık ve kaza kaynaklı sağlık krizleri (D-036, D-044).
///
/// - Krizler **seyrektir**: yaşa ve sağlığa bağlı düşük bir ihtimalle, en
///   fazla yılda bir kez ve aralarında en az birkaç yaş boşlukla çıkar.
/// - Oyuncunun seçimi sonucu etkiler; sonuç yine de garanti değildir.
/// - Kriz ölümle biterse hayat, olağan ölüm yolundan tamamlanır: kayıt
///   silinmez, hayat özeti ve arşiv çalışır.
///
/// Sayısal değerler `prototypeOnly`'dir (Q-061).
class HealthCrisisEngine {
  const HealthCrisisEngine();

  /// prototypeOnly: iki kriz arasında geçmesi gereken en az yaş farkı.
  static const int prototypeOnlyMinAgeGap = 4;

  /// prototypeOnly: krizin en erken çıkabileceği yaş.
  static const int prototypeOnlyMinAge = 3;

  /// prototypeOnly: yaşa göre yıllık kriz ihtimali.
  static double prototypeOnlyCrisisChance(int age, int health) {
    double temel;
    if (age < 16) {
      temel = 0.003;
    } else if (age < 40) {
      temel = 0.007;
    } else if (age < 60) {
      temel = 0.018;
    } else if (age < 75) {
      temel = 0.030;
    } else {
      temel = 0.040;
    }
    // Sağlık düştükçe risk artar; yüksek sağlık tamamen korumaz.
    final double carpan = (1.6 - health / 100).clamp(0.6, 2.0);
    return (temel * carpan).clamp(0.0, 0.2);
  }

  /// Bu yıl kriz çıkar mı? Çıkarsa hangisi?
  ///
  /// Ekranda başka bir kriz varsa veya son krizden bu yana yeterli yaş
  /// geçmediyse çıkmaz.
  HealthCrisis? rollCrisis(GameState state, int age, Random rng) {
    if (state.pendingCrisis != null) return null;
    if (age < prototypeOnlyMinAge) return null;
    final int? son = state.lastCrisisAge;
    if (son != null && age - son < prototypeOnlyMinAgeGap) return null;

    final double sans =
        prototypeOnlyCrisisChance(age, state.player.stats.health);
    if (rng.nextDouble() >= sans) return null;

    final List<HealthCrisis> uygun = crisesForAge(age);
    if (uygun.isEmpty) return null;
    return uygun[rng.nextInt(uygun.length)];
  }

  /// Krizi oyun durumuna yazar (ekranda gösterilmek üzere).
  GameState open(GameState state, HealthCrisis crisis, int age) => state.copyWith(
        pendingCrisis: PendingCrisis(crisisId: crisis.id, age: age),
        lastCrisisAge: age,
        log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
          ...state.log,
          LifeLogEntry(
            age: age,
            text: crisis.text,
            category: LogCategory.kisisel,
          ),
        ]),
      );

  /// Bu seçenek şu an seçilebilir mi?
  bool canChoose(GameState state, CrisisChoice choice) =>
      !choice.needsMoney || state.player.wallet >= choice.cost;

  /// Krize yanıt verir.
  ///
  /// Bedel **bir kez** düşer, sonuç **bir kez** uygulanır. Atlatılamazsa
  /// hayat tamamlanır.
  CrisisResult respond(GameState state, String choiceId, Random rng) {
    final PendingCrisis? bekleyen = state.pendingCrisis;
    if (bekleyen == null) {
      return _blocked(state, 'Bekleyen bir sağlık durumu yok.');
    }
    final HealthCrisis? kriz = bekleyen.crisis;
    if (kriz == null) {
      return CrisisResult(
        state: state.copyWith(pendingCrisis: null),
        outcome: const CrisisOutcome(
          applied: true,
          text: 'Sağlık kaydı okunamadı.',
        ),
      );
    }

    CrisisChoice? secim;
    for (final CrisisChoice c in kriz.choices) {
      if (c.id == choiceId) secim = c;
    }
    if (secim == null) return _blocked(state, 'Geçersiz seçenek.');
    if (!canChoose(state, secim)) {
      return _blocked(state, 'Bu seçenek için cüzdanında yeterli para yok.');
    }

    final int bedel = secim.cost.clamp(0, state.player.wallet);
    final double sansEsigi =
        (kriz.baseSurvival + secim.survivalBonus).clamp(0.05, 0.99);
    final bool atlatti = rng.nextDouble() < sansEsigi;

    GameState next = state.copyWith(
      pendingCrisis: null,
      player: state.player.copyWith(wallet: state.player.wallet - bedel),
    );

    if (!atlatti) {
      // Hayat, olağan ölüm yolundan tamamlanır; kayıtlar silinmez.
      final String gerekce = kriz.kind == CrisisKind.kaza
          ? 'geçirdiği kaza'
          : 'yakalandığı hastalık';
      final String metin =
          '${state.player.age} yaşında $gerekce nedeniyle hayatını kaybettin.';
      next = next.copyWith(
        deceased: true,
        deathAge: state.player.age,
        deathCause: gerekce,
        // Hayat tamamlandı: ekranda yanıtlanmamış olay kalmaz. Yaşa bağlı
        // ölümde (LifeProgression) zaten temizleniyordu; kriz yolunda
        // kalıyor ve vefat eden oyuncuya olay soruluyordu.
        pendingEvent: null,
      );
      return CrisisResult(
        state: _log(next, metin),
        outcome: CrisisOutcome(
          applied: true,
          text: metin,
          survived: false,
          cost: bedel,
        ),
      );
    }

    next = next.copyWith(
      player: next.player.copyWith(
        stats: next.player.stats.gain(
          health: secim.healthChange,
        ),
      ),
    );
    return CrisisResult(
      state: _log(next, secim.resultText),
      outcome: CrisisOutcome(
        applied: true,
        text: secim.resultText,
        cost: bedel,
      ),
    );
  }

  CrisisResult _blocked(GameState state, String reason) => CrisisResult(
        state: state,
        outcome: CrisisOutcome(applied: false, text: reason),
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
