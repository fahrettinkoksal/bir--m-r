// Rekabet (rivalry) — ün, ilgi ve rakibin kendi kariyeri
// (Paket AL/2, §15-§19, §28).
//
// **Sorun.** Paket AL rekabetin *kaydını* tutuyordu: kaç kez
// karşılaşıldı, kim kaç kez kazandı. Ama bunun hiçbir sonucu yoktu —
// aynı rakiple üçüncü kez dövüşmek, tanımadığın biriyle dövüşmekle
// birebir aynıydı. Ayrıca oyuncu üst kademeye çıkınca eski rakip
// eşleşme bandının dışında kalıyor ve bir daha hiç görünmüyordu.
//
// **Bu modül üç şey yapar:**
//
// 1. Rekabetin **gücünü** ölçer: her ikinci karşılaşma "büyük rekabet"
//    değildir (§16).
// 2. Güçlü rekabetin **üne** ve **sosyal medya ilgisine** küçük bir
//    katkı vermesini sağlar — azalan getiri ve yıllık tavanla, ün
//    çiftliği kurulamayacak biçimde (§17, §18).
// 3. Önemli rakibin oyuncuyla birlikte **kendi kariyerinde
//    ilerlemesine** izin verir; ama yaş ve kariyer sınırıyla (§19).
library;

import 'dart:math';

import '../../data/combat_circuit_catalog.dart';
import '../models/combat_career.dart';
import '../models/game_state.dart';

/// Bir rakiple aradaki rekabetin durumu.
class RivalStanding {
  const RivalStanding({required this.opponent, required this.strength});

  final CombatOpponent opponent;

  /// Rekabetin gücü (0-1).
  final double strength;

  /// Gerçekten anlamlı bir rekabet mi (§16)?
  bool get isMajor =>
      opponent.metCount >= 2 && strength >= SportRivalry.prototypeOnlyMajor;

  /// Ekranda gösterilecek kısa etiket; anlamsız rekabette `null` (§28).
  String? get label {
    if (!isMajor) return null;
    if (strength >= 0.72) return 'Baş rakip';
    return 'Önemli rakip';
  }
}

/// Rekabet kuralları. Bütün sayılar `prototypeOnly`.
abstract final class SportRivalry {
  /// prototypeOnly: "önemli rekabet" sayılmak için gereken güç.
  ///
  /// Bilerek yüksek: iki kez karşılaşmak tek başına yetmesin (§16).
  static const double prototypeOnlyMajor = 0.50;

  /// prototypeOnly: rekabet gücünün bileşen ağırlıkları.
  static const double prototypeOnlyRepeatWeight = 0.40;
  static const double prototypeOnlyClosenessWeight = 0.25;
  static const double prototypeOnlyStandingWeight = 0.20;
  static const double prototypeOnlyTitleWeight = 0.15;

  /// prototypeOnly: tekrar bileşeninin doyduğu karşılaşma sayısı.
  static const int prototypeOnlyRepeatSaturation = 4;

  /// prototypeOnly: tek bir rövanşın verebileceği en yüksek ün katkısı.
  static const int prototypeOnlyMaxFamePerBout = 6;

  /// prototypeOnly: bir yılda rekabetten kazanılabilecek en yüksek ün.
  ///
  /// §17'nin istediği tavan: aynı rakibe yirmi kez çıkarak Ün 100
  /// olunamaz.
  static const int prototypeOnlyYearlyFameCap = 6;

  /// prototypeOnly: rekabetin sosyal medya ilgisine katkısının tavanı.
  static const double prototypeOnlyMaxSocialInterest = 0.35;

  /// prototypeOnly: rekabet ilgisinin sönmesi için geçmesi gereken yıl.
  static const int prototypeOnlyInterestFadeYears = 3;

  /// prototypeOnly: rakibin bir yılda yaklaşabileceği en yüksek güç payı.
  static const int prototypeOnlyRivalCatchUp = 6;

  /// prototypeOnly: rakibin kendi kariyerinde ilerlemeyi bıraktığı yaş.
  ///
  /// §19: acemi rakip altmışında dünya şampiyonu diye zorla tutulmaz.
  static const int prototypeOnlyRivalPeakAge = 34;

  /// prototypeOnly: rakibin eşleşme havuzundan tamamen düştüğü yaş.
  static const int prototypeOnlyRivalRetireAge = 42;

  /// Yıllık ün sayacının anahtarı.
  static const String fameCounterKind = 'rivalryUn';

  /// Bu rakiple aradaki rekabetin durumu.
  static RivalStanding standingFor(
    CombatCareer career,
    CombatOpponent opponent,
  ) =>
      RivalStanding(
        opponent: opponent,
        strength: strengthOf(career, opponent),
      );

  /// Rekabetin gücü (0-1).
  ///
  /// Dört bileşen (§16). Tek bir sihirli sayı yok; her biri ayrı ayrı
  /// okunabilsin diye açık yazıldı.
  static double strengthOf(CombatCareer career, CombatOpponent opponent) {
    if (opponent.metCount < 2) return 0;

    // 1) Tekrar: kaç kez karşılaşıldı.
    final double tekrar =
        (opponent.metCount / prototypeOnlyRepeatSaturation).clamp(0.0, 1.0);

    // 2) Skor yakınlığı: 3-3 bir rekabettir, 4-0 değildir.
    final int fark = (opponent.playerWins - opponent.playerLosses).abs();
    final double yakinlik =
        (1 - fark / max(1, opponent.metCount)).clamp(0.0, 1.0);

    // 3) İki tarafın da ağırlığı: sıradan iki sporcunun inatlaşması
    //    kamuoyu için rekabet değildir.
    final double agirlik =
        ((career.reputation + opponent.rating) / 200).clamp(0.0, 1.0);

    // 4) Unvan/final karşılaşması: bir kez kemer için karşılaşmak
    //    rekabeti kalıcı yapar.
    final double unvan = opponent.tier >= kTitleTier ? 1.0 : 0.0;

    return (tekrar * prototypeOnlyRepeatWeight +
            yakinlik * prototypeOnlyClosenessWeight +
            agirlik * prototypeOnlyStandingWeight +
            unvan * prototypeOnlyTitleWeight)
        .clamp(0.0, 1.0);
  }

  /// Kariyerdeki en güçlü rekabet; yoksa `null`.
  static RivalStanding? majorRival(CombatCareer career) {
    RivalStanding? en;
    for (final CombatOpponent o in career.opponents) {
      final RivalStanding d = standingFor(career, o);
      if (!d.isMajor) continue;
      if (en == null || d.strength > en.strength) en = d;
    }
    return en;
  }

  /// Ekranda gösterilecek rekabetler (§28).
  ///
  /// Her rakibi yığmaz: yalnızca gerçekten anlamlı olanlar, en
  /// güçlüden başlayarak.
  static List<RivalStanding> visibleRivals(CombatCareer career, {int max = 2}) {
    final List<RivalStanding> hepsi = career.opponents
        .map((CombatOpponent o) => standingFor(career, o))
        .where((RivalStanding d) => d.isMajor)
        .toList(growable: false)
      ..sort((RivalStanding a, RivalStanding b) =>
          b.strength.compareTo(a.strength));
    return hepsi.take(max).toList(growable: false);
  }

  // =================================================================
  // §17 — ün
  // =================================================================

  /// Bu yıl rekabetten şimdiye kadar kazanılmış ün.
  static int fameUsedThisYear(GameState state) =>
      state.interactionCount('rivalry', fameCounterKind);

  /// Bu rövanşın ün katkısı (§17).
  ///
  /// Üç ayrı fren var:
  /// - yalnızca **kazanılan** ve **önemli** rekabet maçları sayılır,
  /// - aynı rekabetten her ödül bir öncekinden küçüktür (azalan getiri),
  /// - yıllık tavan aşılamaz.
  static int fameBonus({
    required GameState state,
    required CombatCareer career,
    required CombatOpponent opponent,
    required bool won,
  }) {
    if (!won) return 0;
    final RivalStanding durum = standingFor(career, opponent);
    if (!durum.isMajor) return 0;

    // Azalan getiri: ilk rövanş tam, ikincisi yarısı, üçüncüsü üçte
    // biri... Aynı rakibe çıkmayı ün kaynağına çeviremezsin.
    final double ham = durum.strength * prototypeOnlyMaxFamePerBout;
    final int azalan = (ham / (1 + opponent.fameAwards)).floor();
    if (azalan <= 0) return 0;

    final int kalan = prototypeOnlyYearlyFameCap - fameUsedThisYear(state);
    return azalan.clamp(0, kalan.clamp(0, prototypeOnlyYearlyFameCap));
  }

  /// Yıllık ün sayacını ilerletir.
  static GameState markFame(GameState state, int amount) {
    if (amount <= 0) return state;
    return state.copyWith(
      interactionCounts: <String, int>{
        ...state.interactionCounts,
        GameState.interactionKey('rivalry', fameCounterKind):
            fameUsedThisYear(state) + amount,
      },
    );
  }

  // =================================================================
  // §18 — sosyal medya ilgisi
  // =================================================================

  /// Açık bir rekabetin sosyal medyada yarattığı ek ilgi (0-1).
  ///
  /// Maç üstünden yıllar geçtikçe söner: kimse on yıl önceki husumeti
  /// konuşmaz.
  static double socialInterest(CombatCareer career, int age) {
    final RivalStanding? en = majorRival(career);
    if (en == null) return 0;
    final int sonMac = career.lastBoutAge ?? career.startedCompetitiveAtAge;
    final int gecen = age - sonMac;
    if (gecen >= prototypeOnlyInterestFadeYears) return 0;
    final double tazelik =
        (1 - gecen / prototypeOnlyInterestFadeYears).clamp(0.0, 1.0);
    return (en.strength * tazelik * prototypeOnlyMaxSocialInterest)
        .clamp(0.0, prototypeOnlyMaxSocialInterest);
  }

  // =================================================================
  // §19 — rakibin kendi kariyeri
  // =================================================================

  /// Rakip listesini bir yıl ilerletir.
  ///
  /// Herkes yaşlanır; ama yalnızca **önemli** rakipler oyuncuyla
  /// birlikte güçlenir. Böylece üst kademeye çıkan oyuncu eski
  /// rakibini bir daha hiç görmemek yerine, onu ileride finalde
  /// karşısında bulabilir.
  ///
  /// Sınırlar açık: belli bir yaştan sonra rakip de düşüşe geçer,
  /// ilerlemesi oyuncunun kademesinin biraz üstünde durur ve emeklilik
  /// yaşını geçen rakip artık güçlenmez.
  static CombatCareer advanceRivals(
    CombatCareer career,
    Random rng,
  ) {
    if (career.opponents.isEmpty) return career;
    final CombatCircuit? yol = combatCircuitFor(career.artId);
    if (yol == null) return career;

    final int kademe = career.tier.clamp(0, yol.tiers.length - 1);
    final int hedef = yol.tiers[kademe].opponentRating;

    final List<CombatOpponent> yeni = <CombatOpponent>[];
    for (final CombatOpponent o in career.opponents) {
      CombatOpponent r = o.copyWith(age: o.age + 1);
      final RivalStanding durum = standingFor(career, o);

      if (durum.isMajor && r.age <= prototypeOnlyRivalPeakAge) {
        // Oyuncunun kademesine doğru yaklaşır; bir yılda atabileceği
        // adım sınırlı, tavanı da oyuncunun kademesinin biraz üstü.
        final int tavan = (hedef + 8).clamp(10, 98);
        if (r.rating < tavan) {
          final int adim = 2 + rng.nextInt(prototypeOnlyRivalCatchUp - 1);
          r = r.copyWith(
            rating: (r.rating + adim).clamp(10, tavan),
            tier: max(r.tier, career.tier),
            wins: r.wins + (rng.nextDouble() < 0.6 ? 1 : 0),
          );
        }
      } else if (r.age > prototypeOnlyRivalPeakAge) {
        // Rakip de yaşlanır. Zorla zirvede tutulmaz (§19).
        r = r.copyWith(rating: (r.rating - 2).clamp(10, 98));
      }
      yeni.add(r);
    }
    return career.copyWith(
      opponents: List<CombatOpponent>.unmodifiable(yeni),
    );
  }

  /// Bu rakip hâlâ eşleşme havuzunda mı?
  static bool isSelectable(CombatOpponent o) =>
      o.age < prototypeOnlyRivalRetireAge;
}
