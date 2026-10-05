// Paket AY/3 — futbol kariyeri hayatın geri kalanına bağlı mı?
//
// AY ve AY/2'de iki kez aynı sınıf hata buldum: "sistem var, futbol ona
// bağlanmamış". Bu dosya kalan üç bağlantıyı kalıcı olarak korur:
//
//   1. Hayatın hükmü (`LifeVerdict`) futbolu sayıyor mu,
//   2. Ömür sonu özeti futbol kariyerini gösteriyor mu,
//   3. Hayat hedefleri profesyonel futbolu tanıyor mu.
//
// **Yıl değerlendirmesi (`YearReview`) bilerek dışarıda:** D-096 gereği
// o özet sistem adı saymaz, yılın başındaki fotoğrafla bugünün farkını
// yazar. Futbol sezonu oraya cüzdan, Ün ve sağlık farkı olarak zaten
// düşüyor; futbolu adıyla eklemek o tasarımı bozardı.
library;

import 'package:bir_omur/data/life_goal_catalog.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/life/life_verdict.dart';
import 'package:bir_omur/domain/combat/combat_career_engine.dart';
import 'package:bir_omur/domain/models/combat_career.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/sports/football_career.dart';
import 'package:bir_omur/domain/sports/football_pro_engine.dart';
import 'package:flutter_test/flutter_test.dart';

GameState _hayat(int seed, {int age = 40}) {
  final GameState base =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  return base.copyWith(
    pendingEvent: null,
    player: base.player.copyWith(age: age),
  );
}

/// Uzun, gerçek bir futbol kariyeri kurar.
FootballCareer _kariyer({
  int seasons = 15,
  int appearances = 300,
  int goals = 31,
  bool active = false,
}) {
  return FootballCareer(
    startedAtAge: 19,
    position: FootballPosition.forvet,
    active: active,
    retiredAtAge: active ? null : 34,
    lastSeasonAge: 34,
    exitReason: active ? null : FootballExit.yas,
    careerEarnings: 35000000,
    seasonHistory: <FootballSeason>[
      for (int i = 0; i < seasons; i++)
        FootballSeason(
          age: 19 + i,
          appearances: appearances ~/ seasons,
          goals: goals ~/ seasons,
          rating: 60,
          earned: 35000000 ~/ seasons,
        ),
    ],
  );
}

void main() {
  group('Hayatın hükmü futbolu sayıyor (Paket AY/3)', () {
    test('futbolcunun Emek puanı hiç oynamamış birinden yüksek', () {
      // ÖLÇÜLEN HATA: 15 sezon oynamış, 300 maç çıkmış, 35 milyon ₺
      // kazanmış bir oyuncu bu eksende SIFIR alıyordu, çünkü futbol
      // kJobCatalog işi değil ve career.history boş kalıyor.
      final GameState futbolsuz = _hayat(1);
      final GameState futbolcu =
          futbolsuz.copyWith(footballCareer: _kariyer());

      final VerdictAxis a = LifeVerdictBuilder.build(futbolsuz).axes
          .firstWhere((VerdictAxis x) => x.id == 'emek');
      final VerdictAxis b = LifeVerdictBuilder.build(futbolcu).axes
          .firstWhere((VerdictAxis x) => x.id == 'emek');

      expect(b.value, greaterThan(a.value),
          reason: 'Futbol kariyeri Emek eksenine hiç katkı vermiyor');
    });

    test('uzun kariyer kısa kariyerden çok sayıyor', () {
      final GameState kisa = _hayat(2).copyWith(
        footballCareer: _kariyer(seasons: 3, appearances: 40, goals: 2),
      );
      final GameState uzun = _hayat(2).copyWith(footballCareer: _kariyer());
      int emek(GameState s) => LifeVerdictBuilder.build(s).axes
          .firstWhere((VerdictAxis x) => x.id == 'emek')
          .value;
      expect(emek(uzun), greaterThan(emek(kisa)));
    });

    test('aynı sezonda çok gol atan daha çok sayıyor', () {
      // ÖLÇÜLEN HATA (düzeltildi): sezon ağırlığı 2 iken 15 sezonluk
      // kariyer tek başına tavanı dolduruyordu ve 200 gol atan ile hiç
      // gol atmayan aynı puanı alıyordu.
      int emek(GameState s) => LifeVerdictBuilder.build(s).axes
          .firstWhere((VerdictAxis x) => x.id == 'emek')
          .value;
      final GameState golsuz = _hayat(10).copyWith(
        footballCareer: _kariyer(goals: 0),
      );
      final GameState golcu = _hayat(10).copyWith(
        footballCareer: _kariyer(goals: 200),
      );
      expect(emek(golcu), greaterThan(emek(golsuz)),
          reason: 'Gol katkısı tavanın altında kalıp görünmez olmuş');
    });

    test('aynı sezonda çok maç oynayan daha çok sayıyor', () {
      int emek(GameState s) => LifeVerdictBuilder.build(s).axes
          .firstWhere((VerdictAxis x) => x.id == 'emek')
          .value;
      final GameState yedek = _hayat(11).copyWith(
        footballCareer: _kariyer(appearances: 30),
      );
      final GameState asKadro = _hayat(11).copyWith(
        footballCareer: _kariyer(appearances: 420),
      );
      expect(emek(asKadro), greaterThan(emek(yedek)));
    });

    test('futbol tek başına Emek eksenini doldurmuyor', () {
      // Tavan var: o eksende okul, iş, birikim ve askerlik de var.
      final GameState s = _hayat(3).copyWith(
        footballCareer: _kariyer(seasons: 20, appearances: 600, goals: 200),
      );
      final VerdictAxis emek = LifeVerdictBuilder.build(s).axes
          .firstWhere((VerdictAxis x) => x.id == 'emek');
      expect(emek.value, lessThan(100));
    });

    test('futbolcuya "hiç çalışmadın" denmiyor', () {
      // İş geçmişi boş ama hayat boyu futbol oynanmış.
      final GameState s = _hayat(4).copyWith(footballCareer: _kariyer());
      final VerdictAxis emek = LifeVerdictBuilder.build(s).axes
          .firstWhere((VerdictAxis x) => x.id == 'emek');
      expect(emek.note, contains('profesyonel futbol'));
      expect(emek.note.contains('Hiç bir işte çalışmadın'), isFalse);
    });

    test('futbol oynamamış hayatın notu değişmedi', () {
      // Bu düzeltme futbolsuz hayatları etkilememeli.
      final GameState s = _hayat(5);
      final VerdictAxis emek = LifeVerdictBuilder.build(s).axes
          .firstWhere((VerdictAxis x) => x.id == 'emek');
      expect(emek.note.contains('futbol'), isFalse);
    });

    test('sezon oynanmamış kariyer puan vermiyor', () {
      // Deneme kabul edilmiş ama hiç sezon oynanmamışsa emek yok.
      final GameState s = _hayat(6).copyWith(
        footballCareer: const FootballCareer(
          startedAtAge: 19,
          position: FootballPosition.defans,
        ),
      );
      int emek(GameState g) => LifeVerdictBuilder.build(g).axes
          .firstWhere((VerdictAxis x) => x.id == 'emek')
          .value;
      expect(emek(s), emek(_hayat(6)));
    });
  });

  group('Hayatın hükmü dövüş REKABETİNİ sayıyor (Faho onayı)', () {
    // ÖNEMLİ AYRIM: dövüş **eğitimi** zaten sayılıyordu — `_dovusPuani`
    // state.martialArts basamaklarını okuyup Deneyim eksenine katkı
    // veriyor. Sayılmayan şey **rekabetin kendisiydi**: maçlar,
    // şampiyonluklar, kademe ve ringde geçen yıllar Emek ekseninde
    // sıfır ediyordu.
    CombatCareer kariyer({
      int startedAtAge = 18,
      int proWins = 20,
      int proLosses = 5,
      int championships = 0,
      int tier = 2,
      int? retiredAtAge = 34,
    }) =>
        CombatCareer(
          artId: 'boks',
          startedCompetitiveAtAge: startedAtAge,
          proWins: proWins,
          proLosses: proLosses,
          championships: championships,
          tier: tier,
          retiredAtAge: retiredAtAge,
        );

    int emek(GameState s) => LifeVerdictBuilder.build(s).axes
        .firstWhere((VerdictAxis x) => x.id == 'emek')
        .value;

    test('dövüşçünün Emek puanı hiç dövüşmemiş birinden yüksek', () {
      final GameState yok = _hayat(20);
      final GameState dovuscu = yok.copyWith(
        combatCareers: <CombatCareer>[kariyer()],
      );
      expect(emek(dovuscu), greaterThan(emek(yok)));
    });

    test('şampiyonluk fark yaratıyor', () {
      final GameState kemersiz = _hayat(21).copyWith(
        combatCareers: <CombatCareer>[kariyer()],
      );
      final GameState kemerli = _hayat(21).copyWith(
        combatCareers: <CombatCareer>[kariyer(championships: 3)],
      );
      expect(emek(kemerli), greaterThan(emek(kemersiz)));
    });

    test('hiç maç yapmamış lisanslı dövüşçü maç yapandan az sayıyor', () {
      final GameState macsiz = _hayat(22).copyWith(
        combatCareers: <CombatCareer>[
          kariyer(proWins: 0, proLosses: 0, startedAtAge: 33),
        ],
      );
      final GameState macli = _hayat(22).copyWith(
        combatCareers: <CombatCareer>[kariyer()],
      );
      expect(emek(macli), greaterThan(emek(macsiz)));
    });

    test('dövüş tek başına Emek eksenini doldurmuyor', () {
      final GameState s = _hayat(23).copyWith(
        combatCareers: <CombatCareer>[
          kariyer(proWins: 90, proLosses: 2, championships: 8, tier: 3,
              startedAtAge: 16),
        ],
      );
      expect(emek(s), lessThan(100));
    });

    test('iki dalda dövüşmek ekseni ikiye katlamıyor', () {
      final GameState tek = _hayat(24).copyWith(
        combatCareers: <CombatCareer>[
          kariyer(proWins: 60, championships: 5, tier: 3, startedAtAge: 16),
        ],
      );
      final GameState cift = _hayat(24).copyWith(
        combatCareers: <CombatCareer>[
          kariyer(proWins: 60, championships: 5, tier: 3, startedAtAge: 16),
          kariyer(proWins: 60, championships: 5, tier: 3, startedAtAge: 16),
        ],
      );
      // Tavan paylaşılıyor: ikinci kariyer puanı katlamaz.
      expect(emek(cift), lessThanOrEqualTo(emek(tek) + 1));
    });

    test('dövüşçüye "hiç çalışmadın" denmiyor, şampiyonluk anılıyor', () {
      final GameState s = _hayat(25).copyWith(
        combatCareers: <CombatCareer>[kariyer(championships: 2)],
      );
      final VerdictAxis eksen = LifeVerdictBuilder.build(s).axes
          .firstWhere((VerdictAxis x) => x.id == 'emek');
      expect(eksen.note.contains('Hiç bir işte çalışmadın'), isFalse);
      expect(eksen.note, contains('şampiyonluk'));
    });

    test('dövüşmemiş hayatın notu değişmedi', () {
      final VerdictAxis eksen = LifeVerdictBuilder.build(_hayat(26)).axes
          .firstWhere((VerdictAxis x) => x.id == 'emek');
      expect(eksen.note.contains('müsabaka'), isFalse);
      expect(eksen.note.contains('şampiyonluk'), isFalse);
    });
  });

  group('Hayat hedefi: profesyonel futbol (Paket AY/3)', () {
    test('katalogda futbol hedefi var ve dövüş hedefinin eşi', () {
      // Katalogda dövüş için dovus_ust_basamak vardı, futbolun
      // karşılığı yoktu.
      final LifeGoal futbol = kLifeGoals
          .firstWhere((LifeGoal g) => g.id == 'profesyonel_futbol');
      final LifeGoal dovus = kLifeGoals
          .firstWhere((LifeGoal g) => g.id == 'dovus_ust_basamak');
      expect(futbol.area, dovus.area);
      expect(futbol.label, isNotEmpty);
      expect(futbol.description, isNotEmpty);
    });

    test('hedef yalnızca gerçekten sezon oynanınca tamamlanıyor', () {
      final LifeGoal hedef = kLifeGoals
          .firstWhere((LifeGoal g) => g.id == 'profesyonel_futbol');

      // Futbol yok: tamamlanmadı.
      expect(hedef.reached(_hayat(7)), isFalse);

      // Kariyer var ama sezon oynanmamış: hâlâ tamamlanmadı.
      expect(
        hedef.reached(
          _hayat(7).copyWith(
            footballCareer: const FootballCareer(
              startedAtAge: 19,
              position: FootballPosition.kaleci,
            ),
          ),
        ),
        isFalse,
      );

      // Bir sezon oynanmış: tamamlandı.
      expect(
        hedef.reached(_hayat(7).copyWith(footballCareer: _kariyer())),
        isTrue,
      );
    });

    test('dövüş şampiyonluk hedefi var ve unvan istiyor (D-143)', () {
      final LifeGoal hedef = kLifeGoals
          .firstWhere((LifeGoal g) => g.id == 'dovus_sampiyonluk');
      expect(hedef.area, GoalArea.kendin);

      // Dövüş yok: tamamlanmadı.
      expect(hedef.reached(_hayat(30)), isFalse);

      // Rekabet var ama unvan yok: hâlâ tamamlanmadı.
      final GameState unvansiz = _hayat(30).copyWith(
        combatCareers: <CombatCareer>[
          const CombatCareer(
            artId: 'boks',
            startedCompetitiveAtAge: 18,
            proWins: 30,
            tier: 3,
          ),
        ],
      );
      expect(hedef.reached(unvansiz), isFalse);

      // Bir şampiyonluk: tamamlandı.
      final GameState kemerli = _hayat(30).copyWith(
        combatCareers: <CombatCareer>[
          const CombatCareer(
            artId: 'boks',
            startedCompetitiveAtAge: 18,
            proWins: 30,
            championships: 1,
            tier: 3,
          ),
        ],
      );
      expect(hedef.reached(kemerli), isTrue);
    });

    test('iki spor aynı Ün tavanını paylaşıyor (D-141 / D-148)', () {
      // Aynı sayıyı paylaşmak bilinçli bir tutarlılık tercihi; biri
      // değişirse diğeri de konuşulmalı, sessizce ayrılmamalı.
      expect(
        FootballProEngine.footballFameCap,
        CombatCareerEngine.sportFameCap,
        reason: 'Futbol ve dövüşün Ün tavanı ayrışmış; D-148 ikisinin '
            'aynı tavanı görmesini kural sayıyor.',
      );
      expect(FootballProEngine.footballFameCap, lessThan(100),
          reason: 'Spor tek başına Ün 100 yapmamalı.');
    });

    test('hedef kimlikleri tekil kalıyor', () {
      final Set<String> idler = kLifeGoals.map((LifeGoal g) => g.id).toSet();
      expect(idler.length, kLifeGoals.length);
    });
  });
}
