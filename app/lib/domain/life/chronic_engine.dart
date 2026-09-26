/// Kronik sağlık durumlarının motoru (D-153).
///
/// Üç şey yapar:
/// 1. **Başlangıç:** atlatılan bir krizin ardından kalıcı bir durum
///    kalabilir; ayrıca ileri yaşta kontrolle ortaya çıkabilir.
/// 2. **Yıllık etki:** takip edilmeyen durum sağlıktan düşürür, takip
///    edilen daha az düşürür — ama hiç düşürmemek yok: takip durumu
///    **yönetir**, ortadan kaldırmaz.
/// 3. **Kriz riski:** taşınan durumlar yıllık kriz ihtimalini yükseltir.
///
/// **Tıbbi tavsiye değildir.** Hiçbir metin ilaç, doz ya da tedavi
/// tarifi içermez; oyunun söylediği tek şey "bu rahatsızlık var, takip
/// edilmezse sağlık düşer"dir.
///
/// Bütün sayılar `prototypeOnly`'dir (Q-156).
library;

import 'dart:math';

import '../../data/chronic_catalog.dart';
import '../models/chronic_condition.dart';
import '../models/game_state.dart';
import '../models/life_log.dart';
import '../models/pending_notice.dart';
import 'notices.dart';

/// Bir yıllık kronik bakımın sonucu.
class ChronicCareOutcome {
  const ChronicCareOutcome({
    required this.applied,
    required this.text,
    this.cost = 0,
  });

  final bool applied;
  final String text;
  final int cost;
}

class ChronicCareResult {
  const ChronicCareResult({required this.state, required this.outcome});

  final GameState state;
  final ChronicCareOutcome outcome;
}

abstract final class ChronicEngine {
  /// prototypeOnly: atlatılan krizin ardından kalıcı durum bırakma şansı.
  static const double prototypeOnlyAfterCrisisChance = 0.42;

  /// prototypeOnly: yaşla gelen durumun yıllık ortaya çıkma şansı.
  static const double prototypeOnlyAgeOnsetChance = 0.022;

  /// prototypeOnly: yaşla gelen durumun şansını sağlık düşüklüğünün
  /// yükselttiği en yüksek çarpan.
  static const double prototypeOnlyLowHealthFactor = 2.2;

  /// prototypeOnly: bir oyuncunun aynı anda taşıyabileceği en fazla durum.
  ///
  /// Sınır var, çünkü altı durumu birden taşıyan oyuncunun sağlığı her
  /// yıl çöker ve oyun cezalandırmaya dönüşür.
  static const int prototypeOnlyMaxActive = 3;

  /// Takip sayacının kapsamı (yılda bir kez ödenir).
  static const String careCounterScope = 'kronik';

  // -------------------------------------------------------------------
  // 1) Başlangıç
  // -------------------------------------------------------------------

  /// Atlatılan krizin ardından kalıcı bir durum bırakır (bırakacaksa).
  ///
  /// Dönen kayıt yeni durumun **türü**; hiçbir şey kalmadıysa `null`.
  /// Durum zaten varsa yeniden eklenmez: aynı rahatsızlık iki satır olmaz.
  static ({GameState state, String? typeId}) afterCrisis({
    required GameState state,
    required String crisisId,
    required int age,
    required Random rng,
  }) {
    final List<ChronicConditionType> olasi = chronicAfterCrisis(crisisId)
        .where((ChronicConditionType t) => !state.hasChronic(t.id))
        .toList(growable: false);
    if (olasi.isEmpty) return (state: state, typeId: null);
    if (state.activeChronic.length >= prototypeOnlyMaxActive) {
      return (state: state, typeId: null);
    }
    if (rng.nextDouble() >= prototypeOnlyAfterCrisisChance) {
      return (state: state, typeId: null);
    }
    final ChronicConditionType tur = olasi[rng.nextInt(olasi.length)];
    return (state: _ekle(state, tur, age), typeId: tur.id);
  }

  /// Yaşla gelen durumu bu yıl açar (açacaksa).
  ///
  /// Kriz gibi ekranı kesmez: sessiz bir bildirim ve günlük satırıyla
  /// duyurulur, çünkü oyuncunun vereceği bir karar yoktur.
  static GameState advanceYear({
    required GameState state,
    required int newAge,
    required Random rng,
  }) {
    GameState sonuc = _applyYearlyDrain(state, newAge);
    sonuc = _maybeAgeOnset(sonuc, newAge, rng);
    return sonuc;
  }

  static GameState _maybeAgeOnset(GameState state, int age, Random rng) {
    if (state.activeChronic.length >= prototypeOnlyMaxActive) return state;
    final List<ChronicConditionType> olasi = chronicByAge(age)
        .where((ChronicConditionType t) => !state.hasChronic(t.id))
        .toList(growable: false);
    if (olasi.isEmpty) return state;

    // Sağlık düştükçe ihtimal artar; yüksek sağlık tamamen korumaz.
    final double carpan =
        (1.0 + (100 - state.player.stats.health) / 100 * 1.2)
            .clamp(1.0, prototypeOnlyLowHealthFactor);
    if (rng.nextDouble() >= prototypeOnlyAgeOnsetChance * carpan) return state;

    final ChronicConditionType tur = olasi[rng.nextInt(olasi.length)];
    return _ekle(state, tur, age, bildir: true);
  }

  static GameState _ekle(
    GameState state,
    ChronicConditionType tur,
    int age, {
    bool bildir = false,
  }) {
    final GameState next = state.copyWith(
      chronicConditions: List<ChronicCondition>.unmodifiable(
        <ChronicCondition>[
          ...state.chronicConditions,
          ChronicCondition(typeId: tur.id, startedAtAge: age),
        ],
      ),
      log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
        ...state.log,
        LifeLogEntry(
          age: age,
          text: '${tur.label} kaydına girdi. ${tur.description}',
          category: LogCategory.kisisel,
        ),
      ]),
    );
    if (!bildir) return next;
    return next.copyWith(
      notices: List<PendingNotice>.unmodifiable(<PendingNotice>[
        ...next.notices,
        Notices.chronicStarted(
          playerAge: age,
          typeId: tur.id,
          label: tur.label,
          description: tur.description,
        ),
      ]),
    );
  }

  // -------------------------------------------------------------------
  // 2) Yıllık etki
  // -------------------------------------------------------------------

  /// Bu yıl kronik durumların sağlıktan düşüreceği toplam puan.
  ///
  /// Takip edilen durumun düşüşü azdır ama sıfır değildir.
  static int yearlyDrain(GameState state, int age) {
    int toplam = 0;
    for (final ChronicCondition c in state.activeChronic) {
      final ChronicConditionType? tur = c.type;
      if (tur == null) continue;
      // Takip **geçen yıl** ödenmişse bu yılın düşüşü hafifler: bakım
      // yılın içinde yapılır, etkisi bir sonraki yıla taşınır.
      final bool takipli = c.lastCaredAtAge != null &&
          age - c.lastCaredAtAge! <= 1;
      toplam += takipli ? tur.managedDrain : tur.yearlyHealthDrain;
    }
    return toplam;
  }

  static GameState _applyYearlyDrain(GameState state, int age) {
    final int dusus = yearlyDrain(state, age);
    if (dusus <= 0) return state;
    return state.copyWith(
      player: state.player.copyWith(
        stats: state.player.stats.gain(health: -dusus),
      ),
    );
  }

  /// Kronik durumların kriz ihtimaline uyguladığı çarpan.
  ///
  /// Çarpanlar çarpılır ama bir tavanla sınırlanır; üç durum taşıyan
  /// oyuncunun her yıl krize girmesi oyunu cezaya çevirirdi.
  static double crisisRiskFactor(GameState state) {
    double carpan = 1;
    for (final ChronicCondition c in state.activeChronic) {
      carpan *= c.type?.crisisRiskFactor ?? 1.0;
    }
    return carpan.clamp(1.0, 2.5);
  }

  // -------------------------------------------------------------------
  // 3) Takip (bakım)
  // -------------------------------------------------------------------

  /// Bu durum bu yıl takip edilebilir mi? Edilemiyorsa gerekçe.
  ///
  /// Gerekçe **boş metindir** engel yoksa; `null` dönmez (motor kuralı).
  static String careBlockReason(GameState state, ChronicCondition c) {
    final ChronicConditionType? tur = c.type;
    if (tur == null) return 'Bu kaydın türü okunamadı.';
    if (!c.isActive) return 'Bu durum artık sürmüyor.';
    if (c.lastCaredAtAge == state.player.age) {
      return 'Bu yılın takibini zaten yaptın.';
    }
    if (state.player.wallet < tur.yearlyCareCost) {
      return 'Bu yılın takibi için yeterli paran yok.';
    }
    return '';
  }

  /// Bir yıllık takibi yapar: bedel düşer, kayıt güncellenir.
  static ChronicCareResult care({
    required GameState state,
    required String typeId,
  }) {
    final int age = state.player.age;
    ChronicCondition? hedef;
    for (final ChronicCondition c in state.chronicConditions) {
      if (c.typeId == typeId && c.isActive) hedef = c;
    }
    if (hedef == null) {
      return ChronicCareResult(
        state: state,
        outcome: const ChronicCareOutcome(
          applied: false,
          text: 'Böyle süren bir kaydın yok.',
        ),
      );
    }
    final String engel = careBlockReason(state, hedef);
    if (engel.isNotEmpty) {
      return ChronicCareResult(
        state: state,
        outcome: ChronicCareOutcome(applied: false, text: engel),
      );
    }

    final ChronicConditionType tur = hedef.type!;
    final ChronicCondition guncel = hedef.copyWith(
      lastCaredAtAge: age,
      careYears: hedef.careYears + 1,
    );
    final String metin = '${tur.label} için bu yılın takibini yaptın.';

    final GameState next = state.copyWith(
      player: state.player.copyWith(
        wallet: state.player.wallet - tur.yearlyCareCost,
      ),
      chronicConditions: List<ChronicCondition>.unmodifiable(
        state.chronicConditions.map((ChronicCondition c) =>
            c.typeId == typeId && c.isActive ? guncel : c),
      ),
      log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
        ...state.log,
        LifeLogEntry(age: age, text: metin, category: LogCategory.kisisel),
      ]),
    );

    return ChronicCareResult(
      state: next,
      outcome: ChronicCareOutcome(
        applied: true,
        text: metin,
        cost: tur.yearlyCareCost,
      ),
    );
  }
}
