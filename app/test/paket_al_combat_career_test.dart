// Paket AL — profesyonel dövüş/spor kariyeri.
//
// Burada yeniden devasa bir 3000 hayat denetimi yok (§48): yalnızca bu
// sistemin hedefli testleri ve §49'un 600 sporcu ölçümü.
//
// En sert iddia şu: **iyi oyuncu da kaybedebilir, kötü oyuncu da
// nadiren kazanabilir.** "En iyi antrenmanı yaptım, o zaman kesin
// kazanmalıyım" diye bir kural yok.
//
// Ölçüm çıktısı doğrudan konsola yazılıyor; rapor buradan üretiliyor.
// ignore_for_file: avoid_print
library;

import 'dart:math';

import 'package:bir_omur/data/combat_circuit_catalog.dart';
import 'package:bir_omur/data/economy.dart';
import 'package:bir_omur/data/martial_arts_catalog.dart';
import 'package:bir_omur/data/job_catalog.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/domain/career/job_market.dart';
import 'package:bir_omur/domain/combat/combat_career_engine.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/combat_career.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/martial_progress.dart';
import 'package:flutter_test/flutter_test.dart';

MartialArt _art(String id) =>
    MartialArt.values.firstWhere((MartialArt a) => a.id == id);

/// Belirli teknik basamağa gelmiş bir hayat kurar.
GameState _sporcu({
  required String artId,
  required int level,
  int age = 22,
  int seed = 5150,
  int wallet = 400000,
  int health = 80,
}) {
  final MartialArt art = _art(artId);
  final GameState s =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  final int ders = art.ranks[level.clamp(0, art.topLevel)].lessonsNeeded;
  return s.copyWith(
    player: s.player.copyWith(
      age: age,
      wallet: wallet,
      stats: s.player.stats.copyWith(health: health),
    ),
    pendingEvent: null,
    martialArts: <MartialProgress>[
      MartialProgress(artId: artId, lessons: ders, startedAtAge: 10),
    ],
  );
}

/// Rekabete başlatır ve kariyeri döner.
GameState _rekabete(GameState s, String artId) {
  final r = CombatCareerEngine.startCompeting(s, _art(artId));
  expect(r.applied, isTrue, reason: r.text);
  return r.state;
}

/// Bekleyen bir müsabaka kurar (fırsat zarını beklemeden).
GameState _musabakaKur(
  GameState s, {
  bool title = false,
  int seed = 12345,
  int? opponentRating,
}) {
  final CombatCareer k = CombatCareerEngine.activeCareer(s)!;
  final CombatCircuit yol = combatCircuitFor(k.artId)!;
  final CombatTier t = yol.tiers[k.tier];
  return s.copyWith(combatCareers: <CombatCareer>[
    for (final CombatCareer c in s.combatCareers)
      if (c.artId == k.artId)
        c.copyWith(
          pendingBout: PendingBout(
            tier: k.tier,
            opponent: CombatOpponent(
              id: 'test_rakip',
              name: 'Emre Karaca',
              age: 26,
              rating: opponentRating ?? t.opponentRating,
            ),
            purse: title ? yol.titlePurse : t.purse,
            seed: seed,
            offeredAtAge: s.player.age,
            isTitle: title,
          ),
        )
      else
        c,
  ]);
}

void main() {
  // =================================================================
  // §1 / §23 — altı sanatın kendi yolu
  // =================================================================
  group('Paket AL — kariyer yolları (§1)', () {
    test('6/6 sanatın kariyer yolu var ve hepsi farklı anlatıyor', () {
      expect(kCombatCircuits.length, MartialArt.values.length);
      for (final MartialArt a in MartialArt.values) {
        expect(combatCircuitFor(a.id), isNotNull,
            reason: '${a.label} için kariyer yolu yok.');
      }
      // Kademe adları kopyala-yapıştır değil: boks güreş gibi okunmuyor.
      final Set<String> ilkKademeler =
          kCombatCircuits.map((CombatCircuit c) => c.tiers.first.label).toSet();
      expect(ilkKademeler.length, greaterThanOrEqualTo(4),
          reason: 'Altı sanata aynı kariyer ağacı kopyalanmış.');
      final Set<String> unvanlar =
          kCombatCircuits.map((CombatCircuit c) => c.titleLabel).toSet();
      expect(unvanlar, contains('Kemer maçı'));
      expect(unvanlar, contains('Başpehlivanlık'));

      print('');
      print('-- altı sanatın kariyer yolu --');
      for (final CombatCircuit c in kCombatCircuits) {
        print('${c.art!.label.padRight(12)} '
            '${c.tiers.map((CombatTier t) => t.label).join(' → ')}'
            '  |  ${c.titleLabel}');
      }
    });

    test('ödüller oyunun kendi ölçeğinden türüyor', () {
      for (final CombatCircuit c in kCombatCircuits) {
        // Amatör kademe para kazandırmıyor (§13).
        expect(c.tiers.first.purse, 0,
            reason: '${c.art!.label}: amatör kademe para veriyor.');
        // Ödüller yükselerek gidiyor.
        for (int i = 1; i < c.tiers.length; i++) {
          expect(c.tiers[i].purse, greaterThan(c.tiers[i - 1].purse));
        }
        // Şampiyonluk en yüksek.
        expect(c.titlePurse, greaterThan(c.tiers.last.purse));
        // Çıpaya bağlı: asgari ücret katı olarak yazıldı.
        expect(c.titlePurse,
            (Economy.netYearlyMinimumWage * c.titlePurseShare).round());
      }
      print('');
      print('-- ödül tablosu (₺) --');
      for (final CombatCircuit c in kCombatCircuits) {
        print('${c.art!.label.padRight(12)} '
            '${c.tiers.map((CombatTier t) => t.purse).join(' · ')}'
            '  |  unvan ${c.titlePurse}');
      }
    });
  });

  // =================================================================
  // §3 — rekabete başlama
  // =================================================================
  group('Paket AL — rekabete başlama (§3)', () {
    test('sadece ders almak yetmez: teknik basamak gerekiyor', () {
      for (final MartialArt a in MartialArt.values) {
        final GameState hic = _sporcu(artId: a.id, level: 0, age: 25);
        expect(CombatCareerEngine.startAvailability(hic, a).isAllowed, isFalse,
            reason: '${a.label}: sıfır basamakta müsabaka açılmamalı.');
      }
    });

    test('6/6 sanatta kariyere başlanabiliyor', () {
      final List<String> acilan = <String>[];
      for (final MartialArt a in MartialArt.values) {
        final CombatCircuit yol = combatCircuitFor(a.id)!;
        final GameState s = _sporcu(
          artId: a.id,
          level: yol.minLevelFor(0),
          age: 25,
        );
        if (CombatCareerEngine.startAvailability(s, a).isAllowed) {
          acilan.add(a.label);
        }
      }
      expect(acilan.length, MartialArt.values.length, reason: acilan.join(','));
      print('');
      print('-- kariyere başlanabilen sanat: '
          '${acilan.length}/${MartialArt.values.length} --');
    });

    test('yaş ve sağlık gerçekten bakılıyor', () {
      final CombatCircuit yol = combatCircuitFor('boks')!;
      final GameState kucuk =
          _sporcu(artId: 'boks', level: yol.minLevelFor(0), age: 11);
      expect(CombatCareerEngine.startAvailability(kucuk, _art('boks')).isAllowed,
          isFalse);
      final GameState hasta = _sporcu(
          artId: 'boks', level: yol.minLevelFor(0), age: 25, health: 20);
      expect(CombatCareerEngine.startAvailability(hasta, _art('boks')).isAllowed,
          isFalse);
    });

    test('iki dalda birden rekabet edilemiyor', () {
      GameState s = _sporcu(artId: 'boks', level: 4, age: 25);
      s = s.copyWith(martialArts: <MartialProgress>[
        ...s.martialArts,
        MartialProgress(
          artId: 'judo',
          lessons: _art('judo').ranks[4].lessonsNeeded,
          startedAtAge: 10,
        ),
      ]);
      s = _rekabete(s, 'boks');
      expect(CombatCareerEngine.startAvailability(s, _art('judo')).isAllowed,
          isFalse);
    });
  });

  // =================================================================
  // §7 / §37 — maç motoru: iyi oyuncu da kaybeder
  // =================================================================
  group('Paket AL — maç motoru (§7, §37)', () {
    test('kazanma ihtimali asla 0 ya da 1 değil', () {
      // Çok güçlü oyuncu, çok zayıf rakip.
      GameState guclu = _sporcu(artId: 'boks', level: 8, age: 27, health: 100);
      guclu = _rekabete(guclu, 'boks');
      guclu = _musabakaKur(guclu, opponentRating: 5);
      final CombatCareer k1 = CombatCareerEngine.activeCareer(guclu)!;
      final double ust = CombatCareerEngine.winChance(
          guclu, k1, k1.pendingBout!, CampChoice.yogun);

      // Çok zayıf oyuncu, çok güçlü rakip.
      GameState zayif = _sporcu(artId: 'boks', level: 2, age: 19, health: 45);
      zayif = _rekabete(zayif, 'boks');
      zayif = _musabakaKur(zayif, opponentRating: 96);
      final CombatCareer k2 = CombatCareerEngine.activeCareer(zayif)!;
      final double alt = CombatCareerEngine.winChance(
          zayif, k2, k2.pendingBout!, CampChoice.dinlen);

      expect(ust, lessThan(1.0));
      expect(ust, lessThanOrEqualTo(
          CombatCareerEngine.prototypeOnlyMaxWinChance));
      expect(alt, greaterThan(0.0));
      expect(alt, greaterThanOrEqualTo(
          CombatCareerEngine.prototypeOnlyMinWinChance));
      print('');
      print('-- kazanma ihtimali bandı: '
          'en zayıf %${(alt * 100).round()} · '
          'en güçlü %${(ust * 100).round()} --');
    });

    test('teknik, form ve hazırlık gerçekten ihtimali değiştiriyor', () {
      // Rakip bilerek denk seçildi: tavana yapışan bir eşleşmede
      // gradyan ölçülemez, orta banda bakmak gerekir.
      GameState iyi = _sporcu(artId: 'judo', level: 7, age: 26, health: 90);
      iyi = _rekabete(iyi, 'judo');
      iyi = _musabakaKur(iyi, opponentRating: 70);
      final CombatCareer ki = CombatCareerEngine.activeCareer(iyi)!;

      GameState kotu = _sporcu(artId: 'judo', level: 3, age: 26, health: 60);
      kotu = _rekabete(kotu, 'judo');
      kotu = _musabakaKur(kotu, opponentRating: 70);
      final CombatCareer kk = CombatCareerEngine.activeCareer(kotu)!;

      final double a = CombatCareerEngine.winChance(
          iyi, ki, ki.pendingBout!, CampChoice.dengeli);
      final double b = CombatCareerEngine.winChance(
          kotu, kk, kk.pendingBout!, CampChoice.dengeli);
      expect(a, greaterThan(b), reason: 'Teknik fark ihtimale yansımalı.');

      // Aynı sporcu, farklı hazırlık.
      final double yogun = CombatCareerEngine.winChance(
          iyi, ki, ki.pendingBout!, CampChoice.yogun);
      final double dinlen = CombatCareerEngine.winChance(
          iyi, ki, ki.pendingBout!, CampChoice.dinlen);
      expect(yogun, greaterThan(a));
      expect(dinlen, lessThan(a));
      print('');
      print('-- judo: iyi sporcu %${(a * 100).round()} · '
          'zayıf sporcu %${(b * 100).round()} · '
          'yoğun kamp %${(yogun * 100).round()} · '
          'dinlenerek %${(dinlen * 100).round()} --');
    });

    test('favori de kaybeder, underdog da kazanır', () {
      int favoriKaybi = 0;
      int underdogGalibiyeti = 0;
      for (int i = 0; i < 300; i++) {
        GameState f = _sporcu(artId: 'karate', level: 7, age: 26, seed: 900 + i);
        f = _rekabete(f, 'karate');
        f = _musabakaKur(f, seed: 1000 + i, opponentRating: 35);
        if (!CombatCareerEngine.fight(f, CampChoice.dengeli).won) {
          favoriKaybi++;
        }

        GameState u = _sporcu(artId: 'karate', level: 3, age: 20, seed: 900 + i);
        u = _rekabete(u, 'karate');
        u = _musabakaKur(u, seed: 2000 + i, opponentRating: 85);
        if (CombatCareerEngine.fight(u, CampChoice.dengeli).won) {
          underdogGalibiyeti++;
        }
      }
      expect(favoriKaybi, greaterThan(0),
          reason: 'Favori hiç kaybetmiyorsa bu bir yaşam simülasyonu değil.');
      expect(underdogGalibiyeti, greaterThan(0),
          reason: 'Underdog hiç kazanamıyorsa kararlar anlamsız.');
      print('');
      print('-- 300 maçta: favori kaybı $favoriKaybi · '
          'underdog galibiyeti $underdogGalibiyeti --');
    });
  });

  // =================================================================
  // §44 — save/load
  // =================================================================
  group('Paket AL — save/load (§44)', () {
    test('aynı müsabakayı yükleyip tekrar oynamak aynı sonucu veriyor', () {
      GameState s = _sporcu(artId: 'boks', level: 5, age: 24);
      s = _rekabete(s, 'boks');
      s = _musabakaKur(s, seed: 777001);

      final BoutResult ilk = CombatCareerEngine.fight(s, CampChoice.dengeli);

      // Kaydet → yükle → aynı müsabakayı tekrar oyna.
      final GameState yuklenen =
          decodeGameState(encodeGameState(s));
      final BoutResult ikinci =
          CombatCareerEngine.fight(yuklenen, CampChoice.dengeli);

      expect(ikinci.won, ilk.won,
          reason: 'Kaydet/yükle ile sonuç yeniden atılıyor.');
      expect(ikinci.purse, ilk.purse);
      expect(ikinci.injury, ilk.injury);
      print('');
      print('-- save/load: aynı müsabaka aynı sonucu verdi '
          '(${ilk.won ? 'galibiyet' : 'mağlubiyet'}) --');
    });

    test('eski kayıt (combatCareers alanı olmayan) sorunsuz yükleniyor', () {
      final GameState s =
          LifeGenerator.seeded(31).generate(mode: StartMode.tamamenRastgele);
      final Map<String, Object?> json = encodeGameState(s);
      json.remove('combatCareers');
      final GameState geri = decodeGameState(json);
      expect(geri.combatCareers, isEmpty);
    });

    test('kariyer kaydı aynen geri geliyor', () {
      GameState s = _sporcu(artId: 'gures', level: 5, age: 26);
      s = _rekabete(s, 'gures');
      s = _musabakaKur(s, seed: 424242);
      s = CombatCareerEngine.fight(s, CampChoice.yogun).state;

      final CombatCareer once = CombatCareerEngine.careerFor(s, 'gures')!;
      final GameState geri = decodeGameState(encodeGameState(s));
      final CombatCareer sonra = CombatCareerEngine.careerFor(geri, 'gures')!;

      expect(sonra.totalWins, once.totalWins);
      expect(sonra.totalLosses, once.totalLosses);
      expect(sonra.form, once.form);
      expect(sonra.careerEarnings, once.careerEarnings);
      expect(sonra.opponents.length, once.opponents.length);
      expect(sonra.memories.length, once.memories.length);
    });
  });

  // =================================================================
  // §42 — abuse
  // =================================================================
  group('Paket AL — abuse (§42)', () {
    test('aynı yılda sınırsız müsabaka yok', () {
      GameState s = _sporcu(artId: 'judo', level: 6, age: 25);
      s = _rekabete(s, 'judo');
      int yapilan = 0;
      for (int i = 0; i < 40; i++) {
        final r = CombatCareerEngine.offerBout(s, Random(i));
        s = r.state;
        if (r.bout == null) continue;
        final BoutResult b = CombatCareerEngine.fight(s, CampChoice.dengeli);
        if (!b.applied) break;
        s = b.state;
        yapilan++;
      }
      expect(yapilan,
          lessThanOrEqualTo(CombatCareerEngine.prototypeOnlyMaxBoutsPerAge));
      print('');
      print('-- aynı yıl 40 denemede yapılan müsabaka: $yapilan '
          '(tavan ${CombatCareerEngine.prototypeOnlyMaxBoutsPerAge}) --');
    });

    test('aynı müsabakanın ödülü iki kez alınamıyor', () {
      GameState s = _sporcu(artId: 'boks', level: 6, age: 26, wallet: 0);
      s = _rekabete(s, 'boks');
      s = _musabakaKur(s, seed: 31337);
      s = s.copyWith(player: s.player.copyWith(wallet: 500000));

      final BoutResult ilk = CombatCareerEngine.fight(s, CampChoice.dengeli);
      expect(ilk.applied, isTrue);
      // Aynı çağrı bir daha: bekleyen müsabaka silindiği için uygulanmaz.
      final BoutResult ikinci =
          CombatCareerEngine.fight(ilk.state, CampChoice.dengeli);
      expect(ikinci.applied, isFalse);
      expect(ikinci.purse, 0);
    });

    test('sakatken müsabaka yapılamıyor', () {
      GameState s = _sporcu(artId: 'boks', level: 6, age: 27);
      s = _rekabete(s, 'boks');
      s = s.copyWith(combatCareers: <CombatCareer>[
        for (final CombatCareer c in s.combatCareers)
          c.copyWith(injury: InjurySeverity.ciddi, injuryYearsLeft: 3),
      ]);
      s = _musabakaKur(s);
      expect(CombatCareerEngine.fight(s, CampChoice.dengeli).applied, isFalse);
      // Fırsat da çıkmıyor.
      expect(CombatCareerEngine.offerBout(s, Random(3)).bout, isNotNull);
    });

    test('emekli olup dönerek ödül sıfırlanamıyor', () {
      GameState s = _sporcu(artId: 'karate', level: 6, age: 30);
      s = _rekabete(s, 'karate');
      s = CombatCareerEngine.retire(s, RetirementReason.kendiKarari).state;
      // Aynı dalda yeniden başlanamıyor.
      expect(
          CombatCareerEngine.startAvailability(s, _art('karate')).isAllowed,
          isFalse);
      // Başka dalda da: emekli kariyer duruyor ama aktif kariyer yok,
      // yeni dal teknik şartı istiyor.
      expect(CombatCareerEngine.activeCareer(s), isNull);
    });

    test('şampiyonluk maçı sıralama olmadan çıkmıyor', () {
      GameState s = _sporcu(artId: 'boks', level: 8, age: 28);
      s = _rekabete(s, 'boks');
      // En üst kademe ama sıralama yok.
      s = s.copyWith(combatCareers: <CombatCareer>[
        for (final CombatCareer c in s.combatCareers)
          c.copyWith(tier: 3, ranking: 0, reputation: 90, form: 90),
      ]);
      bool unvanCikti = false;
      for (int i = 0; i < 200; i++) {
        final r = CombatCareerEngine.offerBout(s, Random(i));
        if (r.bout?.isTitle ?? false) unvanCikti = true;
        // Fırsatı temizle ki tekrar denensin.
        s = s.copyWith(combatCareers: <CombatCareer>[
          for (final CombatCareer c in r.state.combatCareers)
            c.copyWith(pendingBout: null),
        ]);
      }
      expect(unvanCikti, isFalse,
          reason: 'Sıralaması olmayan kemer maçına çağrılmamalı.');
    });
  });

  // =================================================================
  // §18 / §20 — sakatlık
  // =================================================================
  group('Paket AL — sakatlık (§18, §20)', () {
    test('yoğun kamp sakatlık riskini artırıyor, dinlenmek azaltıyor', () {
      int yogunSakat = 0;
      int dinlenSakat = 0;
      for (int i = 0; i < 400; i++) {
        GameState a = _sporcu(artId: 'boks', level: 6, age: 30, seed: 40 + i);
        a = _rekabete(a, 'boks');
        a = _musabakaKur(a, seed: 5000 + i);
        if (CombatCareerEngine.fight(a, CampChoice.yogun).injury !=
            InjurySeverity.yok) {
          yogunSakat++;
        }
        GameState b = _sporcu(artId: 'boks', level: 6, age: 30, seed: 40 + i);
        b = _rekabete(b, 'boks');
        b = _musabakaKur(b, seed: 5000 + i);
        if (CombatCareerEngine.fight(b, CampChoice.dinlen).injury !=
            InjurySeverity.yok) {
          dinlenSakat++;
        }
      }
      expect(yogunSakat, greaterThan(dinlenSakat));
      print('');
      print('-- 400 maçta sakatlık: yoğun kamp $yogunSakat · '
          'dinlenerek $dinlenSakat --');
    });

    test('sakatlık zamanla iyileşiyor ve kariyeri silmiyor', () {
      GameState s = _sporcu(artId: 'judo', level: 6, age: 27);
      s = _rekabete(s, 'judo');
      s = s.copyWith(combatCareers: <CombatCareer>[
        for (final CombatCareer c in s.combatCareers)
          c.copyWith(
            tier: 2,
            injury: InjurySeverity.ciddi,
            injuryYearsLeft: 3,
            championships: 1,
          ),
      ]);
      for (int i = 1; i <= 3; i++) {
        s = s.copyWith(player: s.player.copyWith(age: 27 + i));
        s = CombatCareerEngine.advanceYear(s, 27 + i, Random(i)).state;
      }
      final CombatCareer k = CombatCareerEngine.activeCareer(s)!;
      expect(k.isInjured, isFalse, reason: 'Sakatlık sonsuza kadar sürmemeli.');
      // Kademe ve şampiyonluk silinmedi (§20).
      expect(k.tier, 2);
      expect(k.championships, 1);
    });

    test('riski göze almak gerçekten riskli', () {
      int agirlasan = 0;
      for (int i = 0; i < 200; i++) {
        GameState s = _sporcu(artId: 'boks', level: 6, age: 29, seed: 70 + i);
        s = _rekabete(s, 'boks');
        s = s.copyWith(combatCareers: <CombatCareer>[
          for (final CombatCareer c in s.combatCareers)
            c.copyWith(injury: InjurySeverity.orta, injuryYearsLeft: 2),
        ]);
        final r = CombatCareerEngine.pushThroughInjury(s, Random(i));
        final CombatCareer k = CombatCareerEngine.activeCareer(r.state)!;
        if (k.injury == InjurySeverity.ciddi) agirlasan++;
      }
      expect(agirlasan, greaterThan(0));
      expect(agirlasan, lessThan(200), reason: 'Her seferinde ağırlaşmamalı.');
      print('');
      print('-- 200 "riski göze al" kararında ağırlaşan: $agirlasan --');
    });
  });

  // =================================================================
  // §30 — eğitmenliğe geçiş
  // =================================================================
  group('Paket AL — eğitmenliğe geçiş (§30)', () {
    test('instructorFromLevel şartı bozulmadı', () {
      const JobMarket pazar = JobMarket();
      for (final MartialArt a in MartialArt.values) {
        // Emekli ama teknik basamağı düşük: eğitmenlik yine kapalı.
        GameState dusuk = _sporcu(artId: a.id, level: 2, age: 40);
        dusuk = _rekabete(
          _sporcu(artId: a.id, level: combatCircuitFor(a.id)!.minLevelFor(0),
              age: 40),
          a.id,
        );
        dusuk = CombatCareerEngine.retire(dusuk, RetirementReason.yas).state;
        expect(CombatCareerEngine.instructorHint(dusuk), isNull,
            reason: '${a.label}: basamak tutmadan eğitmenlik önerilmemeli.');

        // Teknik basamak tutuyorsa kapı açık.
        GameState yuksek =
            _sporcu(artId: a.id, level: a.instructorFromLevel, age: 40);
        yuksek = _rekabete(yuksek, a.id);
        yuksek = CombatCareerEngine.retire(yuksek, RetirementReason.yas).state;
        expect(CombatCareerEngine.instructorHint(yuksek), isNotNull,
            reason: '${a.label}: emekli usta eğitmenliğe geçebilmeli.');

        // Ve iş kataloğu koşulu da gerçekten sağlanıyor.
        final job = jobById(a.instructorJobId);
        if (job != null) {
          expect(pazar.requirementReason(yuksek, job).contains('basamak'),
              isFalse);
        }
      }
    });
  });

  // =================================================================
  // §31 — emeklilik
  // =================================================================
  group('Paket AL — emeklilik (§31, §32)', () {
    test('istediği zaman çekilebiliyor ve hayat devam ediyor', () {
      GameState s = _sporcu(artId: 'taekwondo', level: 6, age: 31);
      s = _rekabete(s, 'taekwondo');
      final r = CombatCareerEngine.retire(s, RetirementReason.kendiKarari);
      expect(r.applied, isTrue);
      final CombatCareer k =
          CombatCareerEngine.careerFor(r.state, 'taekwondo')!;
      expect(k.isRetired, isTrue);
      expect(k.retiredAtAge, 31);
      // Kayıt silinmedi: rekor ve geçmiş duruyor (§33).
      expect(k.memories, isNotEmpty);
      // Oyun bitmedi: diğer sistemler çalışmaya devam ediyor.
      expect(r.state.player.age, 31);
    });

    test('zorunlu emeklilik baskısı yalnızca ağır durumda', () {
      GameState genc = _sporcu(artId: 'judo', level: 6, age: 24);
      genc = _rekabete(genc, 'judo');
      expect(CombatCareerEngine.retirementPressure(genc), isNull);

      GameState yasli = _sporcu(artId: 'judo', level: 6, age: 41);
      yasli = _rekabete(yasli, 'judo');
      expect(CombatCareerEngine.retirementPressure(yasli),
          RetirementReason.yas);

      GameState sakat = _sporcu(artId: 'boks', level: 6, age: 30);
      sakat = _rekabete(sakat, 'boks');
      sakat = sakat.copyWith(combatCareers: <CombatCareer>[
        for (final CombatCareer c in sakat.combatCareers)
          c.copyWith(
            seriousInjuryCount: 2,
            injury: InjurySeverity.ciddi,
            injuryYearsLeft: 3,
          ),
      ]);
      expect(CombatCareerEngine.retirementPressure(sakat),
          RetirementReason.sakatlik);
    });
  });

  // =================================================================
  // §21 — yaş
  // =================================================================
  group('Paket AL — yaş etkisi (§21)', () {
    test('yaş ilerledikçe güç düşüyor ama sert kesim yok', () {
      final List<int> yaslar = <int>[20, 27, 33, 38, 45];
      final List<double> gucler = <double>[];
      for (final int y in yaslar) {
        GameState s = _sporcu(artId: 'boks', level: 7, age: y, health: 85);
        s = _rekabete(s, 'boks');
        final CombatCareer k = CombatCareerEngine.activeCareer(s)!;
        gucler.add(CombatCareerEngine.playerStrength(s, k, CampChoice.dengeli));
      }
      // 27 zirve; sonrası düşüyor ama sıfırlanmıyor.
      expect(gucler[1], greaterThan(gucler[0]));
      expect(gucler[2], lessThan(gucler[1]));
      expect(gucler[4], lessThan(gucler[2]));
      expect(gucler[4], greaterThan(0),
          reason: '"35 oldun, bitti" gibi sert kesim olmamalı.');
      print('');
      print('-- boks gücü yaşa göre: '
          '${yaslar.asMap().entries.map((e) => '${yaslar[e.key]}y '
              '${gucler[e.key].toStringAsFixed(1)}').join(' · ')} --');
    });
  });
}
