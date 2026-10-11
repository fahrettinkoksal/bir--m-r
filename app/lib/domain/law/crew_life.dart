/// Çevre: çeteleşmenin dışarıya taşması (D-161).
///
/// **Neden var:** Koğuşta kurulan bağ (D-140) yalnızca içeride sayılıyordu;
/// tahliyeden sonra hiçbir karşılığı yoktu. `crewStanding` kayıtta duruyor
/// ama dışarıda hiçbir kapı açmıyordu (Q-148'de soruldu).
///
/// **İçerik sınırı — bu dosyanın en önemli kuralı.** Oyun hiçbir suçun
/// **nasıl** işlendiğini anlatmaz. Ne yöntem, ne plan, ne kaçma, ne
/// saklanma, ne iz gizleme, ne yakalanmaktan kurtulma. Oyuncunun gördüğü
/// tek şey **yüksek seviyeli bir seçim**: "çevreden bir teklif geldi,
/// karıştın mı karışmadın mı". Teklifin içeriği bilerek belirsizdir ve
/// oyuncu da ayrıntısını sormaz.
///
/// **Karışmak serbest bir kazanç yolu değildir:** para geliyor ama dosya
/// açılma ihtimali yüksek ve mevcut adli süreç (D-128) olduğu gibi
/// işliyor. Hiçbir yeni "yakalanmama" mekanizması yok.
///
/// Bütün sayılar `prototypeOnly`'dir (Q-164).
library;

import 'dart:math';

import '../models/game_state.dart';
import '../models/interaction.dart';
import '../models/life_log.dart';
import '../../text/turkish_text.dart';
import 'legal_engine.dart';

/// Çevreden gelen teklifin sonucu.
class CrewOutcome {
  const CrewOutcome({
    required this.applied,
    required this.text,
    this.money = 0,
    this.caseOpened = false,
  });

  final bool applied;
  final String text;

  /// Eline geçen tutar (₺).
  final int money;

  /// Bu seçimden bir adli dosya açıldı mı?
  final bool caseOpened;
}

class CrewResult {
  const CrewResult({required this.state, required this.outcome});

  final GameState state;
  final CrewOutcome outcome;
}

abstract final class CrewLife {
  /// prototypeOnly: dışarıda teklif gelmesi için gereken en az itibar.
  static const int prototypeOnlyMinStanding = 40;

  /// prototypeOnly: iki teklif arasında geçmesi gereken yıl.
  static const int prototypeOnlyCooldownYears = 3;

  /// prototypeOnly: karışmanın getirdiği tutar aralığı (₺, 2026 ölçeği).
  static const int prototypeOnlyMinPay = 45000;
  static const int prototypeOnlyMaxPay = 260000;

  /// prototypeOnly: karışınca dosya açılma ihtimali.
  ///
  /// Yüksek tutuldu bilerek: bu kolay para değil.
  static const double prototypeOnlyCaseChance = 0.45;

  /// prototypeOnly: karışmanın itibara kattığı puan.
  static const int prototypeOnlyAcceptStanding = 8;

  /// prototypeOnly: reddetmenin itibardan düşürdüğü puan.
  static const int prototypeOnlyDeclineStanding = 12;

  /// prototypeOnly: karışmanın mutluluğa etkisi (huzursuzluk).
  static const int prototypeOnlyAcceptHappiness = -4;

  /// prototypeOnly: karışınca açılabilecek dosyanın suç kimliği.
  ///
  /// Kataloğa yeni bir "organize suç" eklenmedi: mevcut suçlardan biri
  /// kullanılıyor, çünkü yeni bir ağır suç türü yazmak oyunun içerik
  /// sınırını zorlar ve anlatacak bir yöntem gerektirirdi.
  static const String prototypeOnlyCrimeId = 'kucuk_hirsizlik';

  /// Çevreden teklif gelebilir mi? Gelmiyorsa gerekçesi.
  static InteractionAvailability offerAvailability(GameState state) {
    final int yas = state.player.age;
    if (state.legal.isImprisoned) {
      return const InteractionAvailability.blocked(
        'İçerideyken dışarıdan teklif gelmez.',
      );
    }
    if (state.legal.crewStanding < prototypeOnlyMinStanding) {
      return const InteractionAvailability.blocked(
        'Dışarıda seni arayan bir çevre yok.',
      );
    }
    final int? son = state.legal.crewOfferAtAge;
    if (son != null && yas - son < prototypeOnlyCooldownYears) {
      final int kalan = prototypeOnlyCooldownYears - (yas - son);
      return InteractionAvailability.blocked(
        'Şimdilik sessizler; $kalan yıl daha bir şey gelmez.',
      );
    }
    return const InteractionAvailability.allowed();
  }

  /// Teklife karışır.
  ///
  /// Para eline geçer; dosya açılırsa mevcut adli süreç (D-128) devreye
  /// girer. Hiçbir metin yöntem anlatmaz.
  static CrewResult accept(GameState state, Random rng) {
    final InteractionAvailability uygunluk = offerAvailability(state);
    if (!uygunluk.isAllowed) {
      return CrewResult(
        state: state,
        outcome: CrewOutcome(applied: false, text: uygunluk.reason!),
      );
    }

    final int yas = state.player.age;
    final int tutar = prototypeOnlyMinPay +
        rng.nextInt(prototypeOnlyMaxPay - prototypeOnlyMinPay + 1);

    GameState next = state.copyWith(
      player: state.player.copyWith(
        wallet: state.player.wallet + tutar,
        stats: state.player.stats.gain(
          happiness: prototypeOnlyAcceptHappiness,
        ),
      ),
      legal: state.legal.copyWith(
        crewOfferAtAge: yas,
        crewJobs: state.legal.crewJobs + 1,
        crewStanding: state.legal.crewStanding + prototypeOnlyAcceptStanding,
      ),
    );

    final String metin =
        'Çevreden gelen işe karıştın. Ayrıntısını sormadın; eline '
        '${trMoney(tutar)} geçti.';
    next = _log(next, metin, yas);

    // Dosya açılabilir. Açılırsa olağan adli süreç işler; yeni bir
    // "yakalanmama" yolu yoktur.
    final bool dosya = rng.nextDouble() < prototypeOnlyCaseChance;
    if (dosya) {
      next = LegalEngine.openCase(next, prototypeOnlyCrimeId, rng);
    }

    return CrewResult(
      state: next,
      outcome: CrewOutcome(
        applied: true,
        text: dosya
            ? '$metin Ama iş sessiz kapanmadı.'
            : '$metin Bu sefer kimse kapına gelmedi.',
        money: tutar,
        caseOpened: dosya,
      ),
    );
  }

  /// Teklifi reddeder. İtibar düşer, başka bir şey olmaz.
  static CrewResult decline(GameState state) {
    final InteractionAvailability uygunluk = offerAvailability(state);
    if (!uygunluk.isAllowed) {
      return CrewResult(
        state: state,
        outcome: CrewOutcome(applied: false, text: uygunluk.reason!),
      );
    }
    final int yas = state.player.age;
    const String metin =
        'Çevreden gelen işe karışmadın. Sesini yükseltmeden geri çekildin.';
    final GameState next = _log(
      state.copyWith(
        legal: state.legal.copyWith(
          crewOfferAtAge: yas,
          crewStanding:
              state.legal.crewStanding - prototypeOnlyDeclineStanding,
        ),
      ),
      metin,
      yas,
    );
    return CrewResult(
      state: next,
      outcome: const CrewOutcome(applied: true, text: metin),
    );
  }

  static GameState _log(GameState state, String text, int age) =>
      state.copyWith(
        log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
          ...state.log,
          LifeLogEntry(age: age, text: text, category: LogCategory.kisisel),
        ]),
      );
}
