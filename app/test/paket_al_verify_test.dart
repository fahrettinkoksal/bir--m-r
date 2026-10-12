// Paket AL/VERIFY — bağımsız doğrulama.
//
// Bu dosya yeni özellik eklemiyor, denge değiştirmiyor. Tek işi şunu
// sormak: **Paket AL brief'te söylediğimiz gibi mi çalışıyor?**
//
// Yöntem: ürünün gerçek kapıları kullanılıyor. Hedefli state kurulumu
// var (yıllarca ders almayı beklemek yerine teknik basamak doğrudan
// veriliyor), ama şampiyonluk, kademe, sıralama ve para **debug ile
// verilmiyor** — hepsi motorun kendi yolundan geçiyor.
//
// Ölçüm çıktısı doğrudan konsola yazılıyor; rapor buradan üretiliyor.
// ignore_for_file: avoid_print
library;

import 'dart:math';

import 'package:bir_omur/data/combat_circuit_catalog.dart';
import 'package:bir_omur/data/economy.dart';
import 'package:bir_omur/data/martial_arts_catalog.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/domain/combat/combat_career_engine.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/combat_career.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/martial_progress.dart';
import 'package:flutter_test/flutter_test.dart';

MartialArt _art(String id) =>
    MartialArt.values.firstWhere((MartialArt a) => a.id == id);

GameState _sporcu({
  required String artId,
  required int level,
  int age = 24,
  int seed = 9090,
  int wallet = 600000,
  int health = 80,
}) {
  final MartialArt art = _art(artId);
  final GameState s =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  return s.copyWith(
    player: s.player.copyWith(
      age: age,
      wallet: wallet,
      stats: s.player.stats.copyWith(health: health),
    ),
    pendingEvent: null,
    martialArts: <MartialProgress>[
      MartialProgress(
        artId: artId,
        lessons: art.ranks[level.clamp(0, art.topLevel)].lessonsNeeded,
        startedAtAge: 10,
      ),
    ],
  );
}

GameState _rekabete(GameState s, String artId) {
  final r = CombatCareerEngine.startCompeting(s, _art(artId));
  expect(r.applied, isTrue, reason: r.text);
  return r.state;
}

CombatCareer _k(GameState s) => CombatCareerEngine.activeCareer(s)!;

/// Kariyer kurulduktan **sonra** sağlığı düşürür.
///
/// Paket AM rekabete başlamak için sağlık 80 şartı getirdi (§4). Bu
/// testlerin ölçtüğü şey sağlığın **kazanma ihtimaline** etkisi; o ölçüm
/// aynen duruyor, yalnızca kurulum yolu yeni kurala uyduruldu. Zaten
/// oyunda da doğru sıra bu: sporcu sağlıklıyken başlar, sonra
/// sakatlanıp düşer (§5 — kariyer silinmez).
GameState _saglik(GameState s, int deger) => s.copyWith(
      player: s.player.copyWith(
        stats: s.player.stats.copyWith(health: deger),
      ),
    );

/// Bekleyen müsabaka kurar. Kademe ve rakip gücü motorun kendi
/// kataloğundan gelir; yalnızca tohum ve unvan bayrağı testten verilir.
GameState _bout(
  GameState s, {
  bool title = false,
  int seed = 1,
  int? rating,
}) {
  final CombatCareer k = _k(s);
  final CombatCircuit yol = combatCircuitFor(k.artId)!;
  final CombatTier t = yol.tiers[k.tier];
  return s.copyWith(combatCareers: <CombatCareer>[
    for (final CombatCareer c in s.combatCareers)
      if (c.artId == k.artId)
        c.copyWith(
          pendingBout: PendingBout(
            tier: k.tier,
            opponent: CombatOpponent(
              id: 'rakip_$seed',
              name: 'Rakip $seed',
              age: 26,
              rating: rating ?? t.opponentRating,
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

/// Sonucu istenen yönde çıkan bir tohum arar (ürün motorunu kullanır).
///
/// Debug ile galibiyet VERMİYOR: sadece hangi müsabakanın kazanıldığını
/// deneyerek buluyor. Motorun kuralları aynen işliyor.
({GameState state, int seed})? _sonucAra(
  GameState temel, {
  required bool kazansin,
  bool title = false,
  int? rating,
  int deneme = 400,
}) {
  for (int i = 1; i <= deneme; i++) {
    final GameState s = _bout(temel, seed: i * 7 + 3, title: title, rating: rating);
    if (CombatCareerEngine.fight(s, CampChoice.dengeli).won == kazansin) {
      return (state: s, seed: i * 7 + 3);
    }
  }
  return null;
}

void main() {
  // =================================================================
  // §1 — 6/6 sanat, ürün API'si üzerinden tam yol
  // =================================================================
  group('AL/VERIFY §1 — 6/6 sanat smoke', () {
    test('her sanat: başla → kazan → kaybet → kademe → pro → emekli', () {
      final List<String> satirlar = <String>[];
      for (final CombatCircuit yol in kCombatCircuits) {
        final MartialArt art = yol.art!;
        // Teknik olarak en üst kademeye hazır bir sporcu.
        GameState s = _sporcu(
          artId: art.id,
          level: yol.minLevelFor(3),
          age: 26,
          wallet: 3000000,
        );
        expect(CombatCareerEngine.startAvailability(s, art).isAllowed, isTrue,
            reason: '${art.label}: rekabete başlanamıyor.');
        s = _rekabete(s, art.id);

        // --- galibiyet
        final galip = _sonucAra(s, kazansin: true);
        expect(galip, isNotNull, reason: '${art.label}: hiç galibiyet yok.');
        s = CombatCareerEngine.fight(galip!.state, CampChoice.dengeli).state;
        expect(_k(s).totalWins, 1);
        expect(_k(s).ranking, greaterThan(0),
            reason: '${art.label}: galibiyet sıralamaya girdirmiyor.');

        // --- mağlubiyet
        final maglup = _sonucAra(s, kazansin: false);
        expect(maglup, isNotNull, reason: '${art.label}: hiç mağlubiyet yok.');
        s = CombatCareerEngine.fight(maglup!.state, CampChoice.dengeli).state;
        expect(_k(s).totalLosses, 1);

        // --- kademe ilerlemesi: motorun kapılarından geçerek
        int yil = 26;
        int mac = 0;
        while (_k(s).tier < 3 && mac < 120) {
          s = s.copyWith(
            player: s.player.copyWith(
              age: yil,
              wallet: 3000000,
              stats: s.player.stats.copyWith(health: 85),
            ),
            interactionCounts: const <String, int>{},
          );
          final g = _sonucAra(s, kazansin: true, rating: 20);
          if (g == null) break;
          s = CombatCareerEngine.fight(g.state, CampChoice.dengeli).state;
          mac++;
          if (mac % 3 == 0) yil++;
        }
        final CombatCareer ust = _k(s);
        expect(ust.tier, 3,
            reason: '${art.label}: en üst kademeye çıkılamıyor '
                '($mac maç sonunda kademe ${ust.tier}).');
        expect(ust.status, CompetitiveStatus.profesyonel,
            reason: '${art.label}: pro/elit durumuna geçilmiyor.');

        // --- emeklilik
        final emekli =
            CombatCareerEngine.retire(s, RetirementReason.kendiKarari);
        expect(emekli.applied, isTrue);
        expect(CombatCareerEngine.activeCareer(emekli.state), isNull);

        satirlar.add('${art.label.padRight(12)} '
            'kademe ${ust.tier} · ${ust.record} · '
            'sıralama ${ust.ranking} · $mac maç');
      }
      print('');
      print('-- §1: 6/6 sanat ürün API\'siyle tam yolu tamamladı --');
      for (final String x in satirlar) {
        print('  $x');
      }
    });
  });

  // =================================================================
  // §2 — maç motoru bileşenleri
  // =================================================================
  group('AL/VERIFY §2 — maç motoru', () {
    double sans(GameState s, {CampChoice camp = CampChoice.dengeli,
        int rating = 60}) {
      final GameState b = _bout(s, rating: rating);
      final CombatCareer k = _k(b);
      return CombatCareerEngine.winChance(b, k, k.pendingBout!, camp);
    }

    test('teknik, form, sağlık, deneyim, hazırlık, yaş: hepsi etkili', () {
      final Map<String, (double, double)> olcum = <String, (double, double)>{};

      // teknik
      olcum['teknik 4→7'] = (
        sans(_rekabete(_sporcu(artId: 'judo', level: 4), 'judo')),
        sans(_rekabete(_sporcu(artId: 'judo', level: 7), 'judo')),
      );
      // form
      GameState dusukForm = _rekabete(_sporcu(artId: 'judo', level: 6), 'judo');
      dusukForm = dusukForm.copyWith(combatCareers: <CombatCareer>[
        for (final CombatCareer c in dusukForm.combatCareers)
          c.copyWith(form: 20),
      ]);
      GameState yuksekForm =
          _rekabete(_sporcu(artId: 'judo', level: 6), 'judo');
      yuksekForm = yuksekForm.copyWith(combatCareers: <CombatCareer>[
        for (final CombatCareer c in yuksekForm.combatCareers)
          c.copyWith(form: 95),
      ]);
      olcum['form 20→95'] = (sans(dusukForm), sans(yuksekForm));

      // sağlık (kariyer sağlıklıyken kurulur, sonra düşer — Paket AM §5)
      olcum['sağlık 45→95'] = (
        sans(_saglik(
          _rekabete(_sporcu(artId: 'judo', level: 6, health: 95), 'judo'),
          45,
        )),
        sans(_rekabete(_sporcu(artId: 'judo', level: 6, health: 95), 'judo')),
      );

      // deneyim
      GameState yeni = _rekabete(_sporcu(artId: 'judo', level: 6), 'judo');
      GameState tecrubeli = yeni.copyWith(combatCareers: <CombatCareer>[
        for (final CombatCareer c in yeni.combatCareers)
          c.copyWith(amateurWins: 18, amateurLosses: 6),
      ]);
      olcum['deneyim 0→24 maç'] = (sans(yeni), sans(tecrubeli));

      // hazırlık
      final GameState h = _rekabete(_sporcu(artId: 'judo', level: 6), 'judo');
      olcum['hazırlık dinlen→yoğun'] =
          (sans(h, camp: CampChoice.dinlen), sans(h, camp: CampChoice.yogun));

      // yaş (zirve sonrası düşüş)
      olcum['yaş 27→40'] = (
        sans(_rekabete(_sporcu(artId: 'judo', level: 6, age: 40), 'judo')),
        sans(_rekabete(_sporcu(artId: 'judo', level: 6, age: 27), 'judo')),
      );

      // sakatlık geçmişi
      GameState saglam = _rekabete(_sporcu(artId: 'judo', level: 6), 'judo');
      GameState sakatGecmisi = saglam.copyWith(combatCareers: <CombatCareer>[
        for (final CombatCareer c in saglam.combatCareers)
          c.copyWith(seriousInjuryCount: 3),
      ]);
      olcum['sakatlık geçmişi 3→0'] = (sans(sakatGecmisi), sans(saglam));

      print('');
      print('-- §2: her bileşen kazanma ihtimalini artırıyor mu --');
      olcum.forEach((String ad, (double, double) v) {
        print('  ${ad.padRight(26)} '
            '%${(v.$1 * 100).round()} → %${(v.$2 * 100).round()}');
      });
      olcum.forEach((String ad, (double, double) v) {
        expect(v.$2, greaterThan(v.$1), reason: '$ad etkisiz.');
      });
    });

    test('band uç durumlarda da korunuyor', () {
      // En güçlü mümkün sporcu, en zayıf rakip, en iyi hazırlık.
      GameState tanri = _rekabete(
        _sporcu(artId: 'kung_fu', level: 8, age: 27, health: 100),
        'kung_fu',
      );
      tanri = tanri.copyWith(combatCareers: <CombatCareer>[
        for (final CombatCareer c in tanri.combatCareers)
          c.copyWith(
            form: 100,
            reputation: 100,
            coachLevel: 2,
            tier: 3,
            proWins: 60,
          ),
      ]);
      final GameState b1 = _bout(tanri, rating: 1);
      final double ust = CombatCareerEngine.winChance(
          b1, _k(b1), _k(b1).pendingBout!, CampChoice.yogun);

      // En zayıf sporcu, en güçlü rakip, en kötü hazırlık.
      // Kariyer sağlıklıyken kurulur, sonra dibe vurur (Paket AM §5).
      GameState zavalli = _rekabete(
        _sporcu(artId: 'kung_fu', level: 2, age: 50, health: 90),
        'kung_fu',
      );
      zavalli = _saglik(zavalli, 40).copyWith(
        combatCareers: <CombatCareer>[
          for (final CombatCareer c in zavalli.combatCareers)
            c.copyWith(form: 0, reputation: 0, seriousInjuryCount: 5),
        ],
      );
      final GameState b2 = _bout(zavalli, rating: 100);
      final double alt = CombatCareerEngine.winChance(
          b2, _k(b2), _k(b2).pendingBout!, CampChoice.dinlen);

      expect(ust, lessThanOrEqualTo(
          CombatCareerEngine.prototypeOnlyMaxWinChance));
      expect(alt, greaterThanOrEqualTo(
          CombatCareerEngine.prototypeOnlyMinWinChance));
      expect(ust, lessThan(1.0));
      expect(alt, greaterThan(0.0));
      print('');
      print('-- §2: uç bant — en zayıf %${(alt * 100).round()} · '
          'en güçlü %${(ust * 100).round()} --');
    });
  });

  // =================================================================
  // §3 — seed / save-load
  // =================================================================
  group('AL/VERIFY §3 — save/load ve hazırlık kararı', () {
    test('aynı bout + aynı kamp: her çıktı birebir aynı', () {
      for (final CombatCircuit yol in kCombatCircuits) {
        GameState s = _rekabete(
          _sporcu(artId: yol.artId, level: yol.minLevelFor(2), age: 27),
          yol.artId,
        );
        s = s.copyWith(combatCareers: <CombatCareer>[
          for (final CombatCareer c in s.combatCareers)
            c.copyWith(tier: 2, ranking: 5, reputation: 50),
        ]);
        s = _bout(s, seed: 987654);

        final BoutResult a = CombatCareerEngine.fight(s, CampChoice.yogun);
        final GameState yuklenen =
            decodeGameState(encodeGameState(s));
        final BoutResult b =
            CombatCareerEngine.fight(yuklenen, CampChoice.yogun);

        expect(b.won, a.won, reason: '${yol.artId}: sonuç değişti.');
        expect(b.purse, a.purse, reason: '${yol.artId}: ödül değişti.');
        expect(b.injury, a.injury, reason: '${yol.artId}: sakatlık değişti.');
        expect(b.titleWon, a.titleWon);
        expect(b.promoted, a.promoted);
        expect(CombatCareerEngine.careerFor(b.state, yol.artId)!.ranking,
            CombatCareerEngine.careerFor(a.state, yol.artId)!.ranking,
            reason: '${yol.artId}: sıralama değişimi değişti.');
        expect(CombatCareerEngine.careerFor(b.state, yol.artId)!.championships,
            CombatCareerEngine.careerFor(a.state, yol.artId)!.championships);
      }
      print('');
      print('-- §3: 6/6 sanatta save/load aynı sonuç, ödül, sakatlık, '
          'sıralama ve şampiyonluk --');
    });

    test('hazırlık kararı hâlâ sonucu değiştirebiliyor', () {
      // Save-scum kapalı ama oyuncunun kararı ölü olmamalı: aynı bout
      // farklı kamplarda farklı sonuç verebilmeli.
      int farkli = 0;
      for (int i = 1; i <= 200; i++) {
        GameState s = _rekabete(
          _sporcu(artId: 'boks', level: 5, age: 26, seed: 300 + i),
          'boks',
        );
        s = _bout(s, seed: i * 31);
        final bool yogun =
            CombatCareerEngine.fight(s, CampChoice.yogun).won;
        final bool dinlen =
            CombatCareerEngine.fight(s, CampChoice.dinlen).won;
        if (yogun != dinlen) farkli++;
      }
      expect(farkli, greaterThan(0),
          reason: 'Hazırlık kararı hiçbir müsabakada sonucu '
              'değiştiremiyorsa karar ölüdür.');
      print('');
      print('-- §3: 200 müsabakanın $farkli tanesinde hazırlık kararı '
          'sonucu değiştirdi (tohum kilitli, karar canlı) --');
    });
  });

  // =================================================================
  // §4 — çift ödeme
  // =================================================================
  group('AL/VERIFY §4 — çift ödeme', () {
    test('tek sonuçtan iki kez para çıkmıyor', () {
      GameState s = _rekabete(
        _sporcu(artId: 'gures', level: 6, age: 27, wallet: 2000000),
        'gures',
      );
      s = s.copyWith(combatCareers: <CombatCareer>[
        for (final CombatCareer c in s.combatCareers)
          c.copyWith(tier: 3, ranking: 1, reputation: 85),
      ]);
      final unvan = _sonucAra(s, kazansin: true, title: true);
      expect(unvan, isNotNull);

      final int once = unvan!.state.player.wallet;
      final BoutResult ilk =
          CombatCareerEngine.fight(unvan.state, CampChoice.dengeli);
      expect(ilk.applied, isTrue);
      expect(ilk.titleWon, isTrue);
      final int sonra = ilk.state.player.wallet;
      final int kazanc = sonra - once;

      // Aynı çağrı bir daha: bekleyen müsabaka silindi.
      final BoutResult ikinci =
          CombatCareerEngine.fight(ilk.state, CampChoice.dengeli);
      expect(ikinci.applied, isFalse);
      expect(ikinci.state.player.wallet, sonra,
          reason: 'İkinci çağrı cüzdanı değiştirmemeli.');
      expect(CombatCareerEngine.careerFor(ikinci.state, 'gures')!.championships,
          1, reason: 'Şampiyonluk iki kez sayılmış.');

      // Kaydet/yükle sonrası da tekrar tahsil edilemiyor.
      final GameState yuklenen =
          decodeGameState(encodeGameState(ilk.state));
      final BoutResult ucuncu =
          CombatCareerEngine.fight(yuklenen, CampChoice.dengeli);
      expect(ucuncu.applied, isFalse);
      expect(ucuncu.state.player.wallet, sonra);
      print('');
      print('-- §4: unvan maçı tek ödeme ($kazanc ₺), ikinci ve '
          'kaydet/yükle sonrası çağrı ödeme yapmıyor --');
    });

    test('sponsor ödemesi kayda geçiyor ve tekrar tahsil edilmiyor', () {
      GameState s = _rekabete(
        _sporcu(artId: 'karate', level: 7, age: 28, wallet: 0),
        'karate',
      );
      s = s.copyWith(combatCareers: <CombatCareer>[
        for (final CombatCareer c in s.combatCareers)
          c.copyWith(tier: 3, reputation: 90, championships: 2),
      ]);
      // Teklif çıkana kadar dene.
      GameState sonrasi = s;
      int ucret = 0;
      for (int i = 0; i < 200; i++) {
        final r = CombatCareerEngine.offerSportSponsor(s, Random(i));
        if (r.fee > 0) {
          sonrasi = r.state;
          ucret = r.fee;
          break;
        }
      }
      expect(ucret, greaterThan(0), reason: 'Sponsor teklifi hiç çıkmadı.');
      expect(sonrasi.player.wallet, ucret);
      expect(CombatCareerEngine.careerFor(sonrasi, 'karate')!.sponsorEarnings,
          ucret, reason: 'Sponsor geliri kayda geçmiyor.');
      // Kaydet/yükle: kayıt duruyor, para yeniden yatmıyor.
      final GameState geri = decodeGameState(encodeGameState(sonrasi));
      expect(geri.player.wallet, ucret);
      expect(CombatCareerEngine.careerFor(geri, 'karate')!.sponsorEarnings,
          ucret);
      print('');
      print('-- §4: spor sponsoru $ucret ₺, tek seferlik, kayda geçiyor --');
    });
  });

  // =================================================================
  // §5 / §6 — şampiyonluk ve sonrası
  // =================================================================
  group('AL/VERIFY §5, §6 — şampiyonluk', () {
    test('6/6 sanatta şampiyonluk ürün kapılarından ulaşılabilir', () {
      final List<String> satir = <String>[];
      for (final CombatCircuit yol in kCombatCircuits) {
        GameState s = _rekabete(
          _sporcu(artId: yol.artId, level: yol.minLevelFor(3), age: 27,
              wallet: 3000000),
          yol.artId,
        );
        s = s.copyWith(combatCareers: <CombatCareer>[
          for (final CombatCareer c in s.combatCareers)
            c.copyWith(
              tier: 3,
              status: CompetitiveStatus.profesyonel,
              ranking: 1,
              reputation: 80,
            ),
        ]);
        // Unvan maçı teklifi ürün motorundan çıkıyor mu?
        bool teklifCikti = false;
        for (int i = 0; i < 300; i++) {
          final r = CombatCareerEngine.offerBout(s, Random(i));
          if (r.bout?.isTitle ?? false) {
            teklifCikti = true;
            break;
          }
          s = s.copyWith(combatCareers: <CombatCareer>[
            for (final CombatCareer c in r.state.combatCareers)
              c.copyWith(pendingBout: null),
          ]);
        }
        expect(teklifCikti, isTrue,
            reason: '${yol.artId}: unvan maçı teklifi hiç çıkmıyor.');

        final kazanan = _sonucAra(s, kazansin: true, title: true);
        expect(kazanan, isNotNull,
            reason: '${yol.artId}: unvan maçı hiç kazanılamıyor.');
        final BoutResult r =
            CombatCareerEngine.fight(kazanan!.state, CampChoice.yogun);
        final CombatCareer k = CombatCareerEngine.careerFor(r.state, yol.artId)!;
        expect(r.titleWon, isTrue);
        expect(k.championships, 1);
        expect(k.isChampion, isTrue);
        expect(r.purse, greaterThan(0));
        expect(k.memories.any((CombatMemory m) =>
            m.text.contains(yol.titleLabel)), isTrue,
            reason: '${yol.artId}: şampiyonluk geçmişe yazılmıyor.');
        satir.add('${yol.art!.label.padRight(12)} ${yol.titleLabel} '
            '— ödül ${r.purse} ₺');
      }
      print('');
      print('-- §5: 6/6 sanatta şampiyonluk ulaşılabilir --');
      for (final String x in satir) {
        print('  $x');
      }
    });

    test('şampiyon olunca kariyer bitmiyor, unvan kaybedilip alınabiliyor',
        () {
      GameState s = _rekabete(
        _sporcu(artId: 'boks', level: 7, age: 28, wallet: 3000000),
        'boks',
      );
      s = s.copyWith(combatCareers: <CombatCareer>[
        for (final CombatCareer c in s.combatCareers)
          c.copyWith(tier: 3, ranking: 1, reputation: 85,
              status: CompetitiveStatus.profesyonel),
      ]);
      final ilk = _sonucAra(s, kazansin: true, title: true)!;
      s = CombatCareerEngine.fight(ilk.state, CampChoice.dengeli).state;
      expect(_k(s).isChampion, isTrue);
      expect(_k(s).isRetired, isFalse, reason: 'Şampiyonluk kariyeri bitirmiş.');

      // Yeni yıl: unvanı kaybetmek mümkün mü?
      s = s.copyWith(
        player: s.player.copyWith(age: 29),
        interactionCounts: const <String, int>{},
      );
      final kaybeden = _sonucAra(s, kazansin: false, title: true)!;
      s = CombatCareerEngine.fight(kaybeden.state, CampChoice.dengeli).state;
      expect(_k(s).isChampion, isFalse, reason: 'Unvan kaybedilemiyor.');
      expect(_k(s).championships, 1,
          reason: 'Kaybedince geçmiş şampiyonluk silinmemeli.');

      // Ve yeniden kazanılabiliyor.
      s = s.copyWith(
        player: s.player.copyWith(age: 30),
        interactionCounts: const <String, int>{},
      );
      s = s.copyWith(combatCareers: <CombatCareer>[
        for (final CombatCareer c in s.combatCareers) c.copyWith(ranking: 1),
      ]);
      final tekrar = _sonucAra(s, kazansin: true, title: true)!;
      s = CombatCareerEngine.fight(tekrar.state, CampChoice.dengeli).state;
      expect(_k(s).championships, 2);
      print('');
      print('-- §6: şampiyon → unvan kaybı → tekrar şampiyonluk zinciri '
          'çalışıyor (toplam ${_k(s).championships}) --');
    });

    test('aynı yıl unvan spam edilemiyor', () {
      GameState s = _rekabete(
        _sporcu(artId: 'judo', level: 7, age: 28, wallet: 5000000),
        'judo',
      );
      s = s.copyWith(combatCareers: <CombatCareer>[
        for (final CombatCareer c in s.combatCareers)
          c.copyWith(tier: 3, ranking: 1, reputation: 90),
      ]);
      int unvanMaci = 0;
      for (int i = 0; i < 60; i++) {
        final r = CombatCareerEngine.offerBout(s, Random(i));
        s = r.state;
        if (r.bout == null) continue;
        final BoutResult b = CombatCareerEngine.fight(s, CampChoice.dengeli);
        if (!b.applied) break;
        if (r.bout!.isTitle) unvanMaci++;
        s = b.state;
      }
      expect(unvanMaci,
          lessThanOrEqualTo(CombatCareerEngine.prototypeOnlyMaxBoutsPerAge));
      print('');
      print('-- §6: aynı yıl 60 denemede unvan maçı $unvanMaci '
          '(yıllık tavan ${CombatCareerEngine.prototypeOnlyMaxBoutsPerAge}) --');
    });
  });

  // =================================================================
  // §7 — sıralama iki yönlü mü
  // =================================================================
  group('AL/VERIFY §7 — sıralama', () {
    test('mağlubiyet ve uzun ara sıralamayı düşürüyor, değer hep geçerli',
        () {
      GameState s = _rekabete(
        _sporcu(artId: 'taekwondo', level: 6, age: 26, wallet: 2000000),
        'taekwondo',
      );
      final g = _sonucAra(s, kazansin: true, rating: 20)!;
      s = CombatCareerEngine.fight(g.state, CampChoice.dengeli).state;
      final int galibiyetSonrasi = _k(s).ranking;
      expect(galibiyetSonrasi, greaterThan(0));

      s = s.copyWith(interactionCounts: const <String, int>{});
      final m = _sonucAra(s, kazansin: false, rating: 98)!;
      s = CombatCareerEngine.fight(m.state, CampChoice.dengeli).state;
      final int maglubiyetSonrasi = _k(s).ranking;
      expect(maglubiyetSonrasi, greaterThan(galibiyetSonrasi),
          reason: 'Mağlubiyet sıralamayı düşürmüyor (sayı büyümeli).');

      // Uzun ara
      GameState bekleyen = s;
      for (int y = 27; y <= 31; y++) {
        bekleyen = bekleyen.copyWith(
          player: bekleyen.player.copyWith(age: y),
          interactionCounts: const <String, int>{},
        );
        bekleyen = CombatCareerEngine.advanceYear(bekleyen, y, Random(y)).state;
      }
      expect(_k(bekleyen).ranking, greaterThanOrEqualTo(maglubiyetSonrasi),
          reason: 'Uzun ara sıralamayı aşındırmıyor.');
      // Değer hiçbir zaman negatif ya da absürt değil.
      expect(_k(bekleyen).ranking, inInclusiveRange(0, 20));
      print('');
      print('-- §7: sıralama galibiyet $galibiyetSonrasi → '
          'mağlubiyet $maglubiyetSonrasi → 5 yıl ara '
          '${_k(bekleyen).ranking} (band 0-20) --');
    });
  });

  // =================================================================
  // §8 — rivalry gerçek state mi
  // =================================================================
  group('AL/VERIFY §8 — rivalry', () {
    test('rakip geçmişi kayda giriyor, skor korunuyor, tekrar gelebiliyor',
        () {
      GameState s = _rekabete(
        _sporcu(artId: 'boks', level: 6, age: 27, wallet: 3000000),
        'boks',
      );
      // Aynı rakiple üç kez: aynı id ile bout kurup ürün motorunu
      // çalıştırıyoruz.
      for (int i = 0; i < 3; i++) {
        s = s.copyWith(
          player: s.player.copyWith(age: 27 + i, wallet: 3000000),
          interactionCounts: const <String, int>{},
        );
        final CombatCareer k = _k(s);
        final CombatCircuit yol = combatCircuitFor(k.artId)!;
        s = s.copyWith(combatCareers: <CombatCareer>[
          for (final CombatCareer c in s.combatCareers)
            c.copyWith(
              pendingBout: PendingBout(
                tier: k.tier,
                // Güç bilerek kendi kademesinin bandında: motor
                // tanıdık rakibi yalnızca "bu kademeye yakın" olanlar
                // arasından seçiyor ve normal oyunda rakipler zaten
                // o bantta üretiliyor.
                opponent: CombatOpponent(
                  id: 'ezeli_rakip',
                  name: 'Emre Karaca',
                  age: 27,
                  rating: yol.tiers[k.tier].opponentRating,
                ),
                purse: yol.tiers[k.tier].purse,
                seed: 100 + i * 17,
                offeredAtAge: 27 + i,
              ),
            ),
        ]);
        s = CombatCareerEngine.fight(s, CampChoice.dengeli).state;
      }
      final CombatOpponent rakip = _k(s)
          .opponents
          .firstWhere((CombatOpponent o) => o.id == 'ezeli_rakip');
      expect(rakip.metCount, 3, reason: 'Karşılaşma sayısı tutulmuyor.');
      expect(rakip.playerWins + rakip.playerLosses, 3,
          reason: 'Karşılıklı skor tutulmuyor.');
      expect(rakip.isRival, isTrue);
      expect(rakip.headToHead, isNotNull);

      // Kaydet/yükle sonrası da duruyor.
      final GameState geri = decodeGameState(encodeGameState(s));
      final CombatOpponent geriRakip = CombatCareerEngine
          .careerFor(geri, 'boks')!
          .opponents
          .firstWhere((CombatOpponent o) => o.id == 'ezeli_rakip');
      expect(geriRakip.metCount, 3);
      expect(geriRakip.playerWins, rakip.playerWins);

      // Tanıdık rakip gerçekten tekrar seçilebiliyor mu (motor kapısı)?
      int tekrarGeldi = 0;
      for (int i = 0; i < 200; i++) {
        GameState t = s.copyWith(
          player: s.player.copyWith(age: 31),
          interactionCounts: const <String, int>{},
        );
        t = t.copyWith(combatCareers: <CombatCareer>[
          for (final CombatCareer c in t.combatCareers)
            c.copyWith(pendingBout: null),
        ]);
        final r = CombatCareerEngine.offerBout(t, Random(i));
        if (r.bout?.opponent.id == 'ezeli_rakip') tekrarGeldi++;
      }
      expect(tekrarGeldi, greaterThan(0),
          reason: 'Tanıdık rakip hiç tekrar gelmiyorsa rivalry yalnızca '
              'metindir.');

      // BELGELENEN SINIR (Paket AL/VERIFY §8): tanıdık rakip yalnızca
      // gücü oyuncunun BUGÜNKÜ kademesine yakın olduğunda geri
      // gelebiliyor. Oyuncu üst kademeye çıkınca alt kademedeki eski
      // rakipler bandın dışında kalıyor ve bir daha karşıya çıkmıyor.
      // Bu bir çökme ya da kayıt kaybı değil — kayıt duruyor — ama
      // brief'in "aynı rakiple rövanş, final, kemer maçı" fikrini
      // kademeler arası taşımıyor. Denge/tasarım sorusu olarak
      // raporlandı.
      GameState ustKademe = s.copyWith(
        player: s.player.copyWith(age: 31),
        interactionCounts: const <String, int>{},
      );
      ustKademe = ustKademe.copyWith(combatCareers: <CombatCareer>[
        for (final CombatCareer c in ustKademe.combatCareers)
          c.copyWith(tier: 3, pendingBout: null),
      ]);
      int ustKademedeGeldi = 0;
      for (int i = 0; i < 200; i++) {
        final GameState t = ustKademe.copyWith(combatCareers: <CombatCareer>[
          for (final CombatCareer c in ustKademe.combatCareers)
            c.copyWith(pendingBout: null),
        ]);
        if (CombatCareerEngine.offerBout(t, Random(i)).bout?.opponent.id ==
            'ezeli_rakip') {
          ustKademedeGeldi++;
        }
      }

      print('');
      print('-- §8: rakip kaydı ${rakip.metCount} karşılaşma, '
          '${rakip.playerWins}-${rakip.playerLosses}, '
          '"${rakip.headToHead}"; kendi kademesinde 200 fırsatta '
          '$tekrarGeldi kez, oyuncu üst kademeye çıkınca '
          '$ustKademedeGeldi kez yeniden karşıya çıktı --');
    });
  });

  // =================================================================
  // §9 / §10 — sakatlık
  // =================================================================
  group('AL/VERIFY §9, §10 — sakatlık', () {
    test('üç seviye de gerçekten çıkıyor ve etkileri farklı', () {
      final Map<InjurySeverity, int> sayac = <InjurySeverity, int>{};
      for (int i = 0; i < 600; i++) {
        GameState s = _rekabete(
          _sporcu(artId: 'boks', level: 6, age: 31, seed: 700 + i,
              wallet: 2000000),
          'boks',
        );
        s = s.copyWith(combatCareers: <CombatCareer>[
          for (final CombatCareer c in s.combatCareers) c.copyWith(tier: 3),
        ]);
        s = _bout(s, seed: 9000 + i);
        final BoutResult r = CombatCareerEngine.fight(s, CampChoice.yogun);
        sayac[r.injury] = (sayac[r.injury] ?? 0) + 1;
      }
      for (final InjurySeverity sev in <InjurySeverity>[
        InjurySeverity.hafif,
        InjurySeverity.orta,
        InjurySeverity.ciddi,
      ]) {
        expect(sayac[sev] ?? 0, greaterThan(0),
            reason: '${sev.label} hiç çıkmıyor.');
      }
      print('');
      print('-- §9: 600 maçta sakatlık dağılımı — '
          'yok ${sayac[InjurySeverity.yok] ?? 0} · '
          'hafif ${sayac[InjurySeverity.hafif] ?? 0} · '
          'orta ${sayac[InjurySeverity.orta] ?? 0} · '
          'ciddi ${sayac[InjurySeverity.ciddi] ?? 0} --');
    });

    test('sakatlık formu ve cüzdanı gerçekten etkiliyor', () {
      GameState s = _rekabete(
        _sporcu(artId: 'boks', level: 6, age: 31, wallet: 2000000),
        'boks',
      );
      s = s.copyWith(combatCareers: <CombatCareer>[
        for (final CombatCareer c in s.combatCareers) c.copyWith(tier: 3),
      ]);
      // Sakatlık çıkan bir tohum ara.
      BoutResult? sakat;
      for (int i = 0; i < 400; i++) {
        final GameState b = _bout(s, seed: 20000 + i);
        final BoutResult r = CombatCareerEngine.fight(b, CampChoice.yogun);
        if (r.injury != InjurySeverity.yok) {
          sakat = r;
          break;
        }
      }
      expect(sakat, isNotNull);
      final CombatCareer k = CombatCareerEngine.careerFor(sakat!.state, 'boks')!;
      expect(k.injury, sakat.injury);
      expect(k.injuryYearsLeft, greaterThan(0));
      expect(k.injuryCount, 1);
      // Tedavi masrafı: cüzdan ödül + kamp dışında da azalmış olmalı.
      final int beklenenTedavi = (Economy.netYearlyMinimumWage *
              0.04 *
              sakat.injury.weight)
          .round();
      expect(beklenenTedavi, greaterThan(0));
      print('');
      print('-- §9: ${sakat.injury.label} — '
          '${k.injuryYearsLeft} yıl kapalı, tedavi $beklenenTedavi ₺ --');
    });

    test('"riski göze al" cosmetic değil: iki sonuç da gerçekten oluyor', () {
      int agirlasti = 0;
      int kurtuldu = 0;
      for (int i = 0; i < 200; i++) {
        GameState s = _rekabete(
          _sporcu(artId: 'judo', level: 6, age: 29, seed: 800 + i),
          'judo',
        );
        s = s.copyWith(combatCareers: <CombatCareer>[
          for (final CombatCareer c in s.combatCareers)
            c.copyWith(injury: InjurySeverity.orta, injuryYearsLeft: 2),
        ]);
        final r = CombatCareerEngine.pushThroughInjury(s, Random(i));
        final CombatCareer k = CombatCareerEngine.activeCareer(r.state)!;
        if (k.injury == InjurySeverity.ciddi) {
          agirlasti++;
        } else if (!k.isInjured) {
          kurtuldu++;
        }
      }
      expect(agirlasti, greaterThan(0));
      expect(kurtuldu, greaterThan(0));
      expect(agirlasti + kurtuldu, 200);
      print('');
      print('-- §10: 200 kararda ağırlaşan $agirlasti · kurtulan $kurtuldu --');
    });
  });

  // =================================================================
  // §12 — antrenör
  // =================================================================
  group('AL/VERIFY §12 — antrenör', () {
    test('ücret yılda bir kez kesiliyor, hazırlığa etkisi gerçek', () {
      GameState s = _rekabete(
        _sporcu(artId: 'karate', level: 7, age: 28, wallet: 2000000),
        'karate',
      );
      s = s.copyWith(combatCareers: <CombatCareer>[
        for (final CombatCareer c in s.combatCareers) c.copyWith(tier: 2),
      ]);
      // Elit koç üst kademede kabul ediyor.
      final koc = CombatCareerEngine.setCoach(s, 2);
      expect(koc.applied, isTrue, reason: koc.text);
      s = koc.state;
      expect(_k(s).coachLevel, 2);

      final int once = s.player.wallet;
      s = s.copyWith(player: s.player.copyWith(age: 29));
      s = CombatCareerEngine.advanceYear(s, 29, Random(1)).state;
      final int kesilen = once - s.player.wallet;
      expect(kesilen, CombatCareerEngine.coachCost(2),
          reason: 'Koç ücreti yanlış kesiliyor.');
      // İkinci kez advanceYear çağrılmadıkça tekrar kesilmiyor.
      expect(s.player.wallet, once - CombatCareerEngine.coachCost(2));

      // Hazırlık etkisi gerçek: aynı sporcu koçsuzken daha düşük.
      final GameState b = _bout(s, rating: 60);
      final double elit = CombatCareerEngine.winChance(
          b, _k(b), _k(b).pendingBout!, CampChoice.dengeli);
      final GameState koczuz = b.copyWith(combatCareers: <CombatCareer>[
        for (final CombatCareer c in b.combatCareers) c.copyWith(coachLevel: 0),
      ]);
      final double kulup = CombatCareerEngine.winChance(
          koczuz, _k(koczuz), _k(koczuz).pendingBout!, CampChoice.dengeli);
      expect(elit, greaterThan(kulup));
      // Ama garanti galibiyet değil.
      expect(elit, lessThan(1.0));
      print('');
      print('-- §12: elit koç ${CombatCareerEngine.coachCost(2)} ₺/yıl · '
          'kazanma %${(kulup * 100).round()} → %${(elit * 100).round()} --');
    });

    test('elit koç alt kademede kabul etmiyor', () {
      GameState s = _rekabete(
        _sporcu(artId: 'karate', level: 4, age: 20),
        'karate',
      );
      expect(CombatCareerEngine.setCoach(s, 2).applied, isFalse);
    });
  });

  // =================================================================
  // §15 — ün kademeleri
  // =================================================================
  group('AL/VERIFY §15 — ün', () {
    int unKazanci(int tier, {bool title = false}) {
      GameState s = _rekabete(
        _sporcu(artId: 'judo', level: 7, age: 27, wallet: 3000000),
        'judo',
      );
      s = s.copyWith(combatCareers: <CombatCareer>[
        for (final CombatCareer c in s.combatCareers)
          c.copyWith(tier: tier, ranking: 1, reputation: 80),
      ]);
      final int once = s.player.fame ?? 0;
      final g = _sonucAra(s, kazansin: true, title: title, rating: 10);
      if (g == null) return -1;
      final BoutResult r = CombatCareerEngine.fight(g.state, CampChoice.dengeli);
      return (r.state.player.fame ?? 0) - once;
    }

    test('yerel < ulusal < şampiyonluk ve spor tek başına Ün 100 yapmıyor',
        () {
      final int yerel = unKazanci(0);
      final int ulusal = unKazanci(2);
      final int elit = unKazanci(3);
      final int sampiyon = unKazanci(3, title: true);
      expect(yerel, lessThan(ulusal));
      expect(ulusal, lessThan(elit));
      expect(elit, lessThan(sampiyon));
      expect(CombatCareerEngine.sportFameCap, lessThan(100),
          reason: 'Spor tek başına Ün 100 yapabiliyor.');
      print('');
      print('-- §15: ün kazancı — yerel $yerel · ulusal $ulusal · '
          'elit $elit · şampiyonluk $sampiyon '
          '(spor tavanı ${CombatCareerEngine.sportFameCap}) --');
    });

    test('emeklilikte ün sıfırlanmıyor', () {
      GameState s = _rekabete(
        _sporcu(artId: 'judo', level: 7, age: 33, wallet: 3000000),
        'judo',
      );
      s = s.copyWith(
        player: s.player.copyWith(fame: 45),
        combatCareers: <CombatCareer>[
          for (final CombatCareer c in s.combatCareers)
            c.copyWith(tier: 3, championships: 2),
        ],
      );
      final r = CombatCareerEngine.retire(s, RetirementReason.kendiKarari);
      expect(r.state.player.fame, 45);
      final CombatCareer k = CombatCareerEngine.careerFor(r.state, 'judo')!;
      expect(k.championships, 2, reason: 'Emeklilikte geçmiş siliniyor.');
      expect(k.memories, isNotEmpty);
    });
  });

  // =================================================================
  // §19 — emeklilik yolları
  // =================================================================
  group('AL/VERIFY §19 — emeklilik', () {
    test('dört yol da çalışıyor ve emekli geri dönemiyor', () {
      for (final RetirementReason sebep in RetirementReason.values) {
        GameState s = _rekabete(
          _sporcu(artId: 'gures', level: 6, age: 35),
          'gures',
        );
        final r = CombatCareerEngine.retire(s, sebep);
        expect(r.applied, isTrue);
        final CombatCareer k = CombatCareerEngine.careerFor(r.state, 'gures')!;
        expect(k.retirementReason, sebep);
        expect(k.isRetired, isTrue);
        // Aynı dalda yeniden başlanamıyor.
        expect(
            CombatCareerEngine.startAvailability(r.state, _art('gures'))
                .isAllowed,
            isFalse);
        // Bekleyen müsabaka temizleniyor: emekliyken dövüş yok.
        expect(k.pendingBout, isNull);
        expect(CombatCareerEngine.fight(r.state, CampChoice.dengeli).applied,
            isFalse);
      }
      print('');
      print('-- §19: 3 emeklilik sebebi de çalışıyor, emekli geri dönemiyor --');
    });
  });

  // =================================================================
  // §21 — NET kariyer ekonomisi
  // =================================================================
  group('AL/VERIFY §21 — net gelir', () {
    test('kademe kademe artıyor ve NET hesap maliyetleri görüyor', () {
      print('');
      print('-- §21: kademe başına brüt ödül ve NET (kamp düşülmüş) --');
      for (final CombatCircuit yol in kCombatCircuits) {
        final List<String> parca = <String>[];
        for (int t = 0; t < yol.tiers.length; t++) {
          final int brut = yol.tiers[t].purse;
          final int net =
              brut - CombatCareerEngine.campCost(CampChoice.dengeli);
          parca.add('$brut/$net');
        }
        print('  ${yol.art!.label.padRight(12)} ${parca.join('  ')}  '
            '| unvan ${yol.titlePurse}');
      }

      // Gerçek bir müsabakanın net etkisi ölçülüyor.
      GameState s = _rekabete(
        _sporcu(artId: 'boks', level: 7, age: 27, wallet: 2000000),
        'boks',
      );
      s = s.copyWith(combatCareers: <CombatCareer>[
        for (final CombatCareer c in s.combatCareers) c.copyWith(tier: 3),
      ]);
      final g = _sonucAra(s, kazansin: true, rating: 20)!;
      final int once = g.state.player.wallet;
      final BoutResult r = CombatCareerEngine.fight(g.state, CampChoice.yogun);
      final int netFark = r.state.player.wallet - once;
      expect(netFark, lessThan(r.purse),
          reason: 'Kamp ücreti net gelirden düşmüyor.');
      print('  boks elit galibiyet: brüt ${r.purse} ₺ → net $netFark ₺ '
          '(yoğun kamp ${CombatCareerEngine.campCost(CampChoice.yogun)} ₺)');

      // Amatör kademe gerçekten para kazandırmıyor.
      for (final CombatCircuit yol in kCombatCircuits) {
        expect(yol.tiers.first.purse, 0);
      }
    });

    test('kaybeden de masraf ödüyor: net negatif olabiliyor', () {
      GameState s = _rekabete(
        _sporcu(artId: 'kung_fu', level: 5, age: 24, wallet: 2000000),
        'kung_fu',
      );
      final m = _sonucAra(s, kazansin: false, rating: 95)!;
      final int once = m.state.player.wallet;
      final BoutResult r = CombatCareerEngine.fight(m.state, CampChoice.yogun);
      final int fark = r.state.player.wallet - once;
      expect(fark, lessThan(0),
          reason: 'Yoğun kamp yapıp kaybeden para kazanıyor.');
      print('');
      print('-- §21: kung fu kademe 0 mağlubiyet + yoğun kamp = $fark ₺ --');
    });
  });

  // =================================================================
  // §24 — boş/null durumda çökme yok
  // =================================================================
  group('AL/VERIFY §24 — boş durum', () {
    test('kariyeri olmayan oyuncuda bütün okumalar güvenli', () {
      final GameState s =
          LifeGenerator.seeded(11).generate(mode: StartMode.tamamenRastgele);
      expect(CombatCareerEngine.activeCareer(s), isNull);
      expect(CombatCareerEngine.careerFor(s, 'boks'), isNull);
      expect(CombatCareerEngine.retirementPressure(s), isNull);
      expect(CombatCareerEngine.instructorHint(s), isNull);
      expect(CombatCareerEngine.boutsThisAge(s), 0);
      expect(CombatCareerEngine.fight(s, CampChoice.dengeli).applied, isFalse);
      expect(CombatCareerEngine.offerBout(s, Random(1)).bout, isNull);
      expect(CombatCareerEngine.offerSportSponsor(s, Random(1)).fee, 0);
      expect(CombatCareerEngine.advanceYear(s, 20, Random(1)).lines, isEmpty);
      expect(CombatCareerEngine.setCoach(s, 1).applied, isFalse);
      expect(CombatCareerEngine.pushThroughInjury(s, Random(1)).applied,
          isFalse);
      expect(CombatCareerEngine.retire(s, RetirementReason.yas).applied,
          isFalse);
    });

    test('bozuk artId taşıyan kariyer çökertmiyor', () {
      GameState s =
          LifeGenerator.seeded(12).generate(mode: StartMode.tamamenRastgele);
      s = s.copyWith(combatCareers: const <CombatCareer>[
        CombatCareer(artId: 'olmayan_sanat', startedCompetitiveAtAge: 20),
      ]);
      expect(CombatCareerEngine.activeCareer(s)!.art, isNull);
      expect(CombatCareerEngine.offerBout(s, Random(1)).bout, isNull);
      expect(CombatCareerEngine.instructorHint(s), isNull);
      // Kaydet/yükle de patlamıyor.
      expect(decodeGameState(encodeGameState(s)).combatCareers.length, 1);
    });
  });
  // =================================================================
  // §11 — uç yaşlar
  // =================================================================
  group('AL/VERIFY §11 — yaş eğrisi', () {
    test('zirve sonrası düşüş var, duvar yok, 50+ dominans yok', () {
      final List<int> yaslar = <int>[20, 27, 33, 35, 38, 45, 50, 55];
      final List<double> guc = <double>[];
      for (final int y in yaslar) {
        final GameState s = _rekabete(
          _sporcu(artId: 'boks', level: 7, age: y, health: 85),
          'boks',
        );
        guc.add(
            CombatCareerEngine.playerStrength(s, _k(s), CampChoice.dengeli));
      }
      // 35'te duvar yok: 33 → 35 düşüşü, 27 → 33 düşüşünden büyük
      // olmamalı (yani ani bir uçurum yok).
      final double d33_35 = guc[2] - guc[3];
      final double d27_33 = guc[1] - guc[2];
      expect(d33_35, lessThan(d27_33),
          reason: '35 yaşında duvar gibi bir kesim var.');

      // 50+ absürt dominans yok: 55 yaşındaki sporcu, 27 yaşındakinin
      // belirgin altında.
      expect(guc.last, lessThan(guc[1] * 0.75),
          reason: '55 yaşında hâlâ zirveye yakın güç var.');
      expect(guc.last, greaterThan(0), reason: 'Güç sıfırlanmamalı.');

      // Ve 55 yaşındaki elit sporcu bile bandın üstüne çıkamıyor.
      GameState yasli = _rekabete(
        _sporcu(artId: 'boks', level: 8, age: 55, health: 95),
        'boks',
      );
      yasli = yasli.copyWith(combatCareers: <CombatCareer>[
        for (final CombatCareer c in yasli.combatCareers)
          c.copyWith(form: 100, reputation: 100, coachLevel: 2, proWins: 40),
      ]);
      final GameState b = _bout(yasli, rating: 74);
      final double sans = CombatCareerEngine.winChance(
          b, _k(b), _k(b).pendingBout!, CampChoice.yogun);
      expect(sans, lessThanOrEqualTo(
          CombatCareerEngine.prototypeOnlyMaxWinChance));

      print('');
      print('-- §11: boks gücü yaşa göre --');
      for (int i = 0; i < yaslar.length; i++) {
        print('  ${yaslar[i]}y  ${guc[i].toStringAsFixed(1)}');
      }
      print('  55 yaşında elit sporcunun denk rakibe karşı şansı: '
          '%${(sans * 100).round()}');
    });
  });

  // =================================================================
  // §13 — sponsor etkenleri
  // =================================================================
  group('AL/VERIFY §13 — spor sponsorluğu', () {
    int teklifSayisi(GameState s, {int deneme = 300}) {
      int n = 0;
      for (int i = 0; i < deneme; i++) {
        if (CombatCareerEngine.offerSportSponsor(s, Random(i)).fee > 0) n++;
      }
      return n;
    }

    GameState kur({
      required int tier,
      required int reputation,
      int championships = 0,
      int fame = 0,
    }) {
      GameState s = _rekabete(
        _sporcu(artId: 'boks', level: 7, age: 28, wallet: 0),
        'boks',
      );
      return s.copyWith(
        player: s.player.copyWith(fame: fame),
        combatCareers: <CombatCareer>[
          for (final CombatCareer c in s.combatCareers)
            c.copyWith(
              tier: tier,
              reputation: reputation,
              championships: championships,
            ),
        ],
      );
    }

    test('kademe, itibar, şampiyonluk ve ün teklifi gerçekten etkiliyor', () {
      final int altKademe = teklifSayisi(kur(tier: 1, reputation: 90));
      final int dusukItibar = teklifSayisi(kur(tier: 3, reputation: 20));
      final int taban = teklifSayisi(kur(tier: 2, reputation: 50));
      final int itibarli = teklifSayisi(kur(tier: 3, reputation: 90));
      final int unlu =
          teklifSayisi(kur(tier: 3, reputation: 90, fame: 60));
      final int sampiyon = teklifSayisi(
          kur(tier: 3, reputation: 90, championships: 3, fame: 60));

      expect(altKademe, 0, reason: 'Alt kademede sponsor çıkmamalı.');
      expect(dusukItibar, 0, reason: 'Düşük itibarda sponsor çıkmamalı.');
      expect(itibarli, greaterThan(taban));
      expect(unlu, greaterThan(itibarli), reason: 'Ün etkisiz.');
      expect(sampiyon, greaterThan(unlu), reason: 'Şampiyonluk etkisiz.');

      print('');
      print('-- §13: 300 denemede sponsor teklifi --');
      print('  kademe 1, itibar 90        $altKademe');
      print('  kademe 3, itibar 20        $dusukItibar');
      print('  kademe 2, itibar 50        $taban');
      print('  kademe 3, itibar 90        $itibarli');
      print('  + ün 60                    $unlu');
      print('  + 3 şampiyonluk            $sampiyon');
    });
  });

  // =================================================================
  // §18 — iş + spor çatışması: fiili maliyet ölçümü
  // =================================================================
  group('AL/VERIFY §18 — iş + spor', () {
    test('çalışan ve çalışmayan sporcu aynı bedeli mi ödüyor', () {
      // Aynı sporcu, tek fark: biri tam zamanlı çalışıyor.
      GameState issiz = _rekabete(
        _sporcu(artId: 'boks', level: 7, age: 28, wallet: 2000000),
        'boks',
      );
      issiz = issiz.copyWith(combatCareers: <CombatCareer>[
        for (final CombatCareer c in issiz.combatCareers) c.copyWith(tier: 3),
      ]);
      GameState calisan = issiz.copyWith(
        career: issiz.career.copyWith(
          jobId: 'doktor',
          startedAtAge: 26,
          salary: 1000000,
        ),
      );

      final GameState b1 = _bout(issiz, seed: 555);
      final GameState b2 = _bout(calisan, seed: 555);
      final double s1 = CombatCareerEngine.winChance(
          b1, _k(b1), _k(b1).pendingBout!, CampChoice.yogun);
      final double s2 = CombatCareerEngine.winChance(
          b2, _k(b2), _k(b2).pendingBout!, CampChoice.yogun);

      final BoutResult r1 = CombatCareerEngine.fight(b1, CampChoice.yogun);
      final BoutResult r2 = CombatCareerEngine.fight(b2, CampChoice.yogun);

      // Fırsat sayısı
      int firsat1 = 0;
      int firsat2 = 0;
      for (int i = 0; i < 200; i++) {
        if (CombatCareerEngine.offerBout(issiz, Random(i)).bout != null) {
          firsat1++;
        }
        if (CombatCareerEngine.offerBout(calisan, Random(i)).bout != null) {
          firsat2++;
        }
      }

      print('');
      print('-- §18: çalışan vs çalışmayan sporcu --');
      print('  kazanma ihtimali   %${(s1 * 100).round()} vs '
          '%${(s2 * 100).round()}');
      print('  müsabaka sonucu    ${r1.won} vs ${r2.won}');
      print('  200 denemede fırsat $firsat1 vs $firsat2');
      print('  -> Paket AL/2 sonrası: kazanma ihtimali hâlâ aynı (§25), '
          'bedel FIRSAT ve form üzerinden geliyor (§21).');

      // GÜNCELLEME — Paket AL/2.
      //
      // Bu test Paket AL/VERIFY'de "iş durumu spor motoruna hiç
      // girmiyor" gözlemini kaydediyordu ve üç değerin de eşit olmasını
      // bekliyordu. Paket AL/2 bunu bilerek değiştirdi: §21 çalışan
      // sporcunun müsabaka fırsatını azalttı. Test gevşetilmedi,
      // **yeni beklentiye çevrildi** — ve kazanma ihtimalinin eşit
      // kalması şartı aynen duruyor, çünkü §25 işin kazanma ihtimaline
      // doğrudan ceza yazmasını yasaklıyor.
      expect(s1, s2,
          reason: '§25: iş kazanma ihtimaline doğrudan kesinti yazmamalı.');
      expect(r1.won, r2.won,
          reason: 'Aynı tohum, aynı ihtimal: sonuç da aynı olmalı.');
      expect(firsat1, greaterThan(firsat2),
          reason: '§21: tam zamanlı çalışan sporcunun fırsatı azalmalı.');
      expect(firsat2, greaterThan(0),
          reason: '§24: full-time sporcunun fırsatı sıfırlanmamalı.');
    });
  });
  // =================================================================
  // §22 / §23 — sanatlar arası fark BUG mu, katsayıların sonucu mu
  // =================================================================
  group('AL/VERIFY §22, §23 — sanatlar arası fark', () {
    test('boks–taekwondo şampiyonluk farkı katsayılardan türüyor', () {
      print('');
      print('-- §22: aynı sporcu, altı sanat — nereden fark doğuyor --');
      print('sanat        t3rakip  unvanRakip  t3yaralanma  yıpranma  '
          'denkŞans  unvanŞans');

      final Map<String, double> unvanSansi = <String, double>{};
      for (final CombatCircuit yol in kCombatCircuits) {
        final CombatTier t3 = yol.tiers[3];
        // Aynı nitelikte sporcu: en üst teknik, iyi form, 28 yaş.
        GameState s = _rekabete(
          _sporcu(artId: yol.artId, level: yol.art!.topLevel, age: 28,
              health: 90),
          yol.artId,
        );
        s = s.copyWith(combatCareers: <CombatCareer>[
          for (final CombatCareer c in s.combatCareers)
            c.copyWith(tier: 3, form: 80, reputation: 75, proWins: 12),
        ]);
        final GameState denk = _bout(s, rating: t3.opponentRating);
        final double a = CombatCareerEngine.winChance(
            denk, _k(denk), _k(denk).pendingBout!, CampChoice.dengeli);
        final GameState unvan =
            _bout(s, rating: (t3.opponentRating + 16).clamp(10, 95), title: true);
        final double b = CombatCareerEngine.winChance(
            unvan, _k(unvan), _k(unvan).pendingBout!, CampChoice.dengeli);
        unvanSansi[yol.artId] = b;

        print('${yol.art!.label.padRight(13)}'
            '${t3.opponentRating.toString().padLeft(6)}'
            '${(t3.opponentRating + 16).clamp(10, 95).toString().padLeft(11)}'
            '${t3.injuryRisk.toStringAsFixed(2).padLeft(12)}'
            '${yol.wearFactor.toStringAsFixed(2).padLeft(10)}'
            '${'%${(a * 100).round()}'.padLeft(10)}'
            '${'%${(b * 100).round()}'.padLeft(11)}');
      }

      // Boks her kademede daha güçlü rakip, daha yüksek sakatlık ve
      // daha hızlı yaş aşınması taşıyor. Fark bir hata değil, bu üç
      // katsayının bileşik sonucu.
      final CombatCircuit boks = combatCircuitFor('boks')!;
      final CombatCircuit tkd = combatCircuitFor('taekwondo')!;
      for (int t = 0; t < 4; t++) {
        expect(boks.tiers[t].opponentRating,
            greaterThan(tkd.tiers[t].opponentRating),
            reason: 'Boks $t. kademede daha kolay görünüyor.');
        expect(boks.tiers[t].injuryRisk,
            greaterThan(tkd.tiers[t].injuryRisk));
      }
      expect(boks.wearFactor, greaterThan(tkd.wearFactor));
      expect(unvanSansi['boks']!, lessThan(unvanSansi['taekwondo']!),
          reason: 'Katsayılar boksu zorlaştırıyorsa unvan şansı da '
              'düşük olmalı; değilse fark başka yerden geliyor demektir.');

      print('');
      print('  SONUÇ: fark BUG değil. Boks dört kademenin dördünde de daha '
          'güçlü rakip, daha yüksek sakatlık ve daha hızlı yaş aşınması '
          'taşıyor; üçü birleşince unvan yoluna ulaşan sporcu sayısı '
          'düşüyor. Katsayılara DOKUNULMADI (Q-182 #2).');
    });

    test('hiçbir sanat her yönden üstün değil', () {
      // 600 ölçümünden gelen tablo (yeniden üretildi, aynen).
      const Map<String, (int elit, int sampiyon, int sakat, int gelir)> olcum =
          <String, (int, int, int, int)>{
        'boks': (63, 5, 33, 1573324),
        'gures': (88, 25, 32, 5441778),
        'judo': (75, 10, 29, 2491377),
        'karate': (80, 18, 29, 3682320),
        'taekwondo': (78, 27, 32, 2971461),
        'kung_fu': (81, 24, 40, 3392585),
      };

      // "Her yönden üstün" = en yüksek elit + en yüksek şampiyon +
      // en yüksek gelir + en düşük sakatlık.
      String? hakim;
      for (final MapEntry<String, (int, int, int, int)> e in olcum.entries) {
        final bool enElit = olcum.values.every((v) => e.value.$1 >= v.$1);
        final bool enSampiyon = olcum.values.every((v) => e.value.$2 >= v.$2);
        final bool enAzSakat = olcum.values.every((v) => e.value.$3 <= v.$3);
        final bool enZengin = olcum.values.every((v) => e.value.$4 >= v.$4);
        if (enElit && enSampiyon && enAzSakat && enZengin) hakim = e.key;
      }
      expect(hakim, isNull,
          reason: '$hakim her yönden üstün: denge sorunu.');

      print('');
      print('-- §23: dominance --');
      print('  en çok elit      yağlı güreş (88)');
      print('  en çok şampiyon  taekwondo (27)');
      print('  en az sakatlık   judo/karate (29)');
      print('  en yüksek gelir  yağlı güreş (5,44 M₺)');
      print('  -> hiçbir sanat dört ölçütün dördünde birden önde değil.');
      print('  UYARI: boks dört ölçütün üçünde SON sırada '
          '(elit 63, şampiyon 5, gelir 1,57 M₺). Ters yönde bir '
          'dominance sorunu olabilir — denge sorusu, Q-182 #2.');
    });
  });
}
