import 'dart:math';

import '../../data/health_crisis_catalog.dart';
import '../models/game_state.dart';
import '../models/life_log.dart';
import '../../domain/economy/vehicle_trouble.dart';
import '../models/health_history.dart';
import '../models/owned_item.dart';
import '../models/pending_crisis.dart';
import 'chronic_engine.dart';
import 'critical_health.dart';

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

    // Taşınan kronik durumlar riski yükseltir (D-153). Çarpan tavanlıdır;
    // üç durum taşıyan oyuncunun her yıl krize girmesi oyunu cezaya
    // çevirirdi.
    final double sans =
        prototypeOnlyCrisisChance(age, state.player.stats.health) *
            ChronicEngine.crisisRiskFactor(state);
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
    // Kritik sağlık krizinde (Paket AQ) atlatma ihtimali katalogdan
    // gelmez: yaş, taşınan rahatsızlıklar ve daha önce kaç kez aynı
    // eşiğe gelindiği hesaba katılır. Rastgele bir yarı yarıya zar yok.
    final double sansEsigi = kriz.isCritical
        ? CriticalHealth.survivalChance(state: state, choice: secim)
        : (kriz.baseSurvival + secim.survivalBonus).clamp(0.05, 0.99);
    final bool atlatti = rng.nextDouble() < sansEsigi;

    GameState next = state.copyWith(
      pendingCrisis: null,
      player: state.player.copyWith(wallet: state.player.wallet - bedel),
    );

    if (!atlatti) {
      // Hayat, olağan ölüm yolundan tamamlanır; kayıtlar silinmez.
      final String gerekce = kriz.isCritical
          // Sebep kayıtta varsa yazılır; yoksa uydurulmaz.
          ? CriticalHealth.deathCauseFor(bekleyen)
          : kriz.kind == CrisisKind.kaza
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

    if (kriz.isCritical) {
      // Kurtulan karakter ne 100 sağlıkla ne 1 sağlıkla kalır: düşük ama
      // oynanabilir bir bantta açılır (`CriticalHealth`). Değer `gain`
      // ile yazılır, D-099 ihlal edilmez.
      final int hedef =
          CriticalHealth.recoveredHealth(state: next, choice: secim);
      next = next.copyWith(
        player: next.player.copyWith(
          stats: next.player.stats.gain(
            health: hedef - next.player.stats.health,
          ),
        ),
        // Bant düzeldiği için uyarı bayrakları yeniden konuşabilir.
        healthDangerWarned: false,
      );
      // Uzun süre işe gidemeyen çalışanın durumu iş yerinde konuşulur.
      // Yeni bir devamsızlık sistemi kurulmadı: mevcut işveren uyarısı
      // (D-078) kullanılıyor ve uyarı tek başına kimseyi işten atmıyor.
      if (next.career.isEmployed) {
        next = next.copyWith(
          career: next.career.copyWith(
            employerWarnings: next.career.employerWarnings + 1,
          ),
        );
      }
    } else {
      next = next.copyWith(
        player: next.player.copyWith(
          stats: next.player.stats.gain(
            health: secim.healthChange,
          ),
        ),
      );
    }

    // Trafik kazasında araç da hasar görür (D-157). Kaza zaten iki yerde
    // yaşanıyordu ama araç kaydına hiç dokunulmuyordu.
    if (kriz.id == 'trafik_kazasi') {
      final ({List<OwnedItem> items, String? text}) hasar =
          VehicleTroubles.damageInAccident(next.items);
      if (hasar.text != null) {
        next = _log(
          next.copyWith(
            items: List<OwnedItem>.unmodifiable(hasar.items),
          ),
          hasar.text!,
        );
      }
    }

    // Atlatılan kriz **iz bırakır** (D-153): kalıcı bir rahatsızlık
    // kalabilir ve kriz her hâlde sağlık geçmişine yazılır. Önceden
    // yalnızca son krizin yaşı tutuluyordu.
    final ({GameState state, String? typeId}) kronik =
        ChronicEngine.afterCrisis(
      state: next,
      crisisId: kriz.id,
      age: state.player.age,
      rng: rng,
    );
    next = kronik.state.copyWith(
      healthHistory: List<HealthHistoryEntry>.unmodifiable(
        <HealthHistoryEntry>[
          ...kronik.state.healthHistory,
          HealthHistoryEntry(
            crisisId: kriz.id,
            age: state.player.age,
            choiceId: secim.id,
            chronicTypeId: kronik.typeId,
          ),
        ],
      ),
    );

    // Küçük yaştaki oyuncuya yetişkin tedavi metni kopyalanmaz.
    final String sonucMetni = kriz.isCritical
        ? CriticalHealth.resultTextFor(state: next, choice: secim)
        : secim.resultText;

    final String metin = kronik.typeId == null
        ? sonucMetni
        : '$sonucMetni Ama bu bir iz bıraktı.';

    next = _log(next, sonucMetni);

    // Hayati tehlikenin oyuncunun hayatından silinmemesi için iz kalır
    // (§: "hayati tehlike atlattı" kaybolmasın). Okul/iş tarafındaki
    // somut sonuç da buradan yazılır.
    if (kriz.isCritical) {
      final String? iz = CriticalHealth.afterEffectLine(next);
      if (iz != null) next = _log(next, iz);
    }

    // Olağan krizi atlatan oyuncunun sağlığı acil banda indiyse zorunlu
    // çözüm **aynı anda** açılır; "atlattı ama sağlığı 0" diye sessiz
    // bir durum kalmaz. Kritik krizin kendisi için bu çağrı etkisizdir:
    // kurtulma sağlığı acil bandın üstüne çıkarıyor.
    next = CriticalHealth.enforce(
      state: next,
      age: next.player.age,
      cause: CriticalHealthCause.kriz,
    );

    return CrisisResult(
      state: next,
      outcome: CrisisOutcome(
        applied: true,
        text: metin,
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
