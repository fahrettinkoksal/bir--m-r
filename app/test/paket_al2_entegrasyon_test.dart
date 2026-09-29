// Paket AL/2 — spor kariyeri entegrasyonları.
//
// Paket AL/VERIFY beş brief maddesinin yazıldığı ama uygulanmadığını
// tespit etmişti. Bu dosya o beş maddenin **gerçekten** çalıştığını
// ürünün kendi API'leri üzerinden doğruluyor (§32): aile desteği
// `SportFamilySupport.ask`, okul kararı `SportSchoolConflict.chooseX`,
// paylaşım `SocialEngine.post`, müsabaka `CombatCareerEngine.fight`,
// fırsat `CombatCareerEngine.offerBout` çağrısından geçiyor.
//
// State kurulumu testten yapılıyor (on yıl ders almayı beklemek yerine
// teknik basamak doğrudan veriliyor), ama sonucu üreten son adım her
// zaman motorun kendisi.
//
// ignore_for_file: avoid_print
library;

import 'dart:math';

import 'package:bir_omur/data/combat_circuit_catalog.dart';
import 'package:bir_omur/data/economy.dart';
import 'package:bir_omur/data/job_catalog.dart';
import 'package:bir_omur/data/martial_arts_catalog.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/data/social_catalog.dart';
import 'package:bir_omur/domain/activities/martial_arts_engine.dart';
import 'package:bir_omur/domain/combat/combat_career_engine.dart';
import 'package:bir_omur/domain/combat/sport_family_support.dart';
import 'package:bir_omur/domain/combat/sport_rivalry.dart';
import 'package:bir_omur/domain/combat/sport_school_conflict.dart';
import 'package:bir_omur/domain/combat/sport_workload.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/hobby/course_support.dart';
import 'package:bir_omur/domain/models/career.dart';
import 'package:bir_omur/domain/models/combat_career.dart';
import 'package:bir_omur/domain/models/education.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/martial_progress.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/social_account.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:bir_omur/domain/social/social_engine.dart';
import 'package:bir_omur/domain/social/sport_social_boost.dart';
import 'package:flutter_test/flutter_test.dart';

MartialArt sanat(String id) =>
    MartialArt.values.firstWhere((MartialArt a) => a.id == id);

/// Rekabete başlamış bir sporcu kurar.
GameState sporcu({
  String artId = 'karate',
  int level = 3,
  int age = 15,
  int seed = 4242,
  int wallet = 400000,
  int health = 85,
}) {
  final MartialArt a = sanat(artId);
  final GameState s =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  final GameState hazir = s.copyWith(
    player: s.player.copyWith(
      age: age,
      wallet: wallet,
      stats: s.player.stats.copyWith(health: health),
    ),
    pendingEvent: null,
    martialArts: <MartialProgress>[
      MartialProgress(
        artId: artId,
        lessons: a.ranks[level.clamp(0, a.topLevel)].lessonsNeeded,
        startedAtAge: 8,
      ),
    ],
  );
  final r = CombatCareerEngine.startCompeting(hazir, a);
  expect(r.applied, isTrue, reason: r.text);
  return r.state;
}

CombatCareer kariyer(GameState s) => CombatCareerEngine.activeCareer(s)!;

/// Yaşayan, kendi parası olan bir anne ve baba yerleştirir.
GameState aileKur(
  GameState s, {
  WealthTier? anne = WealthTier.ortaHalli,
  WealthTier? baba = WealthTier.ortaHalli,
  int bond = 75,
}) {
  final List<Person> kisiler = <Person>[];
  for (final Person p in s.people) {
    if (p.relation == RelationType.anne) {
      kisiler.add(
        p.copyWith(isAlive: anne != null, wealth: anne, bond: bond),
      );
    } else if (p.relation == RelationType.baba) {
      kisiler.add(
        p.copyWith(isAlive: baba != null, wealth: baba, bond: bond),
      );
    } else if (p.relation == RelationType.uveyAnne ||
        p.relation == RelationType.uveyBaba) {
      // Ölçüm sade kalsın: üvey ebeveyn bu testlerde yok sayılır.
      kisiler.add(p.copyWith(isAlive: false));
    } else {
      kisiler.add(p);
    }
  }
  return s.copyWith(people: List<Person>.unmodifiable(kisiler));
}

Person? ebeveyn(GameState s, RelationType r) {
  for (final Person p in s.people) {
    if (p.relation == r && p.isAlive) return p;
  }
  return null;
}

/// Bekleyen müsabaka kurar; kademe ve rakip gücü motorun kataloğundan.
GameState musabaka(
  GameState s, {
  bool title = false,
  int seed = 11,
  CombatOpponent? rakip,
  int? tier,
}) {
  final CombatCareer k = kariyer(s);
  final CombatCircuit yol = combatCircuitFor(k.artId)!;
  final int kademe = tier ?? k.tier;
  final CombatTier t = yol.tiers[kademe];
  return s.copyWith(combatCareers: <CombatCareer>[
    for (final CombatCareer c in s.combatCareers)
      if (c.artId == k.artId)
        c.copyWith(
          pendingBout: PendingBout(
            tier: kademe,
            opponent: rakip ??
                CombatOpponent(
                  id: 'rakip_$seed',
                  name: 'Rakip $seed',
                  age: 24,
                  rating: t.opponentRating,
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

/// Okula kayıtlı öğrenci yapar.
GameState okulda(GameState s, {int grade = 10, int ortalama = 70}) =>
    s.copyWith(
      education: EducationState(
        enrolled: true,
        grade: grade,
        startedAtAge: 6,
        gradeAverage: ortalama,
      ),
    );

/// İşe sokar.
GameState iste(GameState s, String jobId) => s.copyWith(
      career: s.career.copyWith(
        jobId: jobId,
        startedAtAge: s.player.age,
        salary: 40000,
      ),
    );

String tamZamanliIs() =>
    kJobCatalog.firstWhere((JobType j) => !j.partTime).id;

String yariZamanliIs() =>
    kJobCatalog.firstWhere((JobType j) => j.partTime).id;

void main() {
  // =================================================================
  // §1-§5 — aile desteği
  // =================================================================
  group('AL/2 aile desteği', () {
    test('18 yaş altı sporcu anneden destek alabiliyor', () {
      final GameState s = aileKur(
        sporcu(age: 15, wallet: 0),
        anne: WealthTier.cokVarlikli,
        baba: null,
      );
      final Person anne = ebeveyn(s, RelationType.anne)!;
      expect(
        SportFamilySupport.blockReason(
          state: s,
          expense: SportExpense.ders,
          person: anne,
          amount: SportFamilySupport.defaultCost(s, SportExpense.ders),
        ),
        isEmpty,
        reason: 'Çok varlıklı anneden ders desteği istemenin önü açık olmalı.',
      );

      // Kabul çıkan bir tohum ara: karar zar değil, ama zar da var.
      GameState? kabul;
      for (int i = 0; i < 80; i++) {
        final SportSupportResult r = SportFamilySupport.ask(
          state: s,
          expense: SportExpense.ders,
          person: anne,
          amount: SportFamilySupport.defaultCost(s, SportExpense.ders),
          rng: Random(i),
        );
        expect(r.outcome.applied, isTrue);
        if (r.outcome.accepted) {
          kabul = r.state;
          break;
        }
      }
      expect(kabul, isNotNull,
          reason: 'Çok varlıklı ve yakın anne hiçbir tohumda kabul etmiyorsa '
              'kapı fiilen kapalı demektir.');
      expect(
        SportFamilySupport.creditFor(kabul!, SportExpense.ders),
        greaterThan(0),
        reason: 'Kabul kredi olarak yazılmalı.',
      );
    });

    test('babadan destek de ayrı bir yol', () {
      final GameState s = aileKur(
        sporcu(age: 15, wallet: 0),
        anne: null,
        baba: WealthTier.cokVarlikli,
      );
      final Person? baba = ebeveyn(s, RelationType.baba);
      expect(baba, isNotNull);
      expect(SportFamilySupport.sponsorsFor(s).map((Person p) => p.id),
          contains(baba!.id));
      expect(
        SportFamilySupport.blockReason(
          state: s,
          expense: SportExpense.kamp,
          person: baba,
          amount: SportFamilySupport.defaultCost(s, SportExpense.kamp),
        ),
        isEmpty,
      );
    });

    test('ebeveyn yoksa sahte seçenek üretilmiyor', () {
      final GameState s = aileKur(
        sporcu(age: 15, wallet: 0),
        anne: null,
        baba: null,
      );
      expect(SportFamilySupport.sponsorsFor(s), isEmpty,
          reason: '§26: olmayan ebeveyn ekranda gösterilmez.');
    });

    test('fakir aile pahalı koç için çok daha az kabul ediyor', () {
      final GameState fakir = aileKur(
        sporcu(age: 16, wallet: 0),
        anne: WealthTier.cokYoksul,
        baba: null,
      );
      final GameState varlikli = aileKur(
        sporcu(age: 16, wallet: 0),
        anne: WealthTier.cokVarlikli,
        baba: null,
      );
      final int ucret =
          SportFamilySupport.defaultCost(fakir, SportExpense.koc);
      final double fakirSans = SportFamilySupport.acceptChance(
        state: fakir,
        expense: SportExpense.koc,
        person: ebeveyn(fakir, RelationType.anne)!,
        amount: ucret,
      );
      final double varlikliSans = SportFamilySupport.acceptChance(
        state: varlikli,
        expense: SportExpense.koc,
        person: ebeveyn(varlikli, RelationType.anne)!,
        amount: ucret,
      );
      print('-- AİLE: koç kabul ihtimali — çok yoksul '
          '${(fakirSans * 100).toStringAsFixed(1)}% / çok varlıklı '
          '${(varlikliSans * 100).toStringAsFixed(1)}% --');
      expect(fakirSans, lessThan(varlikliSans),
          reason: '§2: varlık seviyesi kararı değiştirmeli.');
    });

    test('yıllardır başarılı sporcu yeni başlayandan daha kolay alıyor', () {
      final GameState yeni = aileKur(
        sporcu(age: 16, wallet: 0),
        anne: WealthTier.varlikli,
        baba: null,
      );
      // Aynı aile, aynı masraf; tek fark sporcunun geçmişi.
      final CombatCareer k = kariyer(yeni);
      final GameState kidemli = yeni.copyWith(combatCareers: <CombatCareer>[
        k.copyWith(
          amateurWins: 9,
          amateurLosses: 3,
          tier: 1,
          reputation: 45,
        ),
      ]).copyWith(
        combatCareers: <CombatCareer>[
          CombatCareer(
            artId: k.artId,
            startedCompetitiveAtAge: 10,
            amateurWins: 9,
            amateurLosses: 3,
            tier: 1,
            reputation: 45,
          ),
        ],
      );
      final int ucret = SportFamilySupport.defaultCost(yeni, SportExpense.koc);
      final double yeniSans = SportFamilySupport.acceptChance(
        state: yeni,
        expense: SportExpense.koc,
        person: ebeveyn(yeni, RelationType.anne)!,
        amount: ucret,
      );
      final double kidemliSans = SportFamilySupport.acceptChance(
        state: kidemli,
        expense: SportExpense.koc,
        person: ebeveyn(kidemli, RelationType.anne)!,
        amount: ucret,
      );
      print('-- AİLE: devamlılık — yeni başlayan '
          '${(yeniSans * 100).toStringAsFixed(1)}% / kıdemli '
          '${(kidemliSans * 100).toStringAsFixed(1)}% --');
      expect(kidemliSans, greaterThan(yeniSans),
          reason: '§2: tek antrenman yapmış çocuk elit koç parasını kolay '
              'almamalı.');
    });

    test('destek ebeveynin ortak yıllık bütçesinden düşüyor', () {
      GameState s = aileKur(
        sporcu(age: 15, wallet: 0),
        anne: WealthTier.cokVarlikli,
        baba: null,
      );
      final Person anne = ebeveyn(s, RelationType.anne)!;
      final int once = CourseSupport.usedThisYear(s, anne.id);
      expect(once, 0);

      final int tutar = SportFamilySupport.defaultCost(s, SportExpense.kamp);
      for (int i = 0; i < 80; i++) {
        final SportSupportResult r = SportFamilySupport.ask(
          state: s,
          expense: SportExpense.kamp,
          person: anne,
          amount: tutar,
          rng: Random(i),
        );
        if (r.outcome.accepted) {
          s = r.state;
          break;
        }
      }
      expect(CourseSupport.usedThisYear(s, anne.id), tutar,
          reason: '§3: para yoktan yaratılmıyor; kurs desteğiyle **aynı** '
              'ebeveyn bütçesinden düşüyor.');
    });

    test('aynı masraf için ikinci kez destek alınamıyor', () {
      GameState s = aileKur(
        sporcu(age: 15, wallet: 0),
        anne: WealthTier.cokVarlikli,
        baba: WealthTier.cokVarlikli,
      );
      final Person anne = ebeveyn(s, RelationType.anne)!;
      final Person baba = ebeveyn(s, RelationType.baba)!;
      final int tutar = SportFamilySupport.defaultCost(s, SportExpense.ders);

      for (int i = 0; i < 80; i++) {
        final SportSupportResult r = SportFamilySupport.ask(
          state: s,
          expense: SportExpense.ders,
          person: anne,
          amount: tutar,
          rng: Random(i),
        );
        if (r.outcome.accepted) {
          s = r.state;
          break;
        }
      }
      expect(SportFamilySupport.creditFor(s, SportExpense.ders), tutar);

      // Aynı masraf için babadan da istemek kapalı olmalı (§3).
      expect(
        SportFamilySupport.blockReason(
          state: s,
          expense: SportExpense.ders,
          person: baba,
          amount: tutar,
        ),
        isNotEmpty,
        reason: 'Anne + baba + cüzdan üçlü ödeme yapılamamalı.',
      );

      // Kredi bir kez harcanır; ikinci harcama aynı parayı vermez.
      final ({GameState state, int remaining}) ilk =
          SportFamilySupport.spendCredit(s, SportExpense.ders, tutar);
      expect(ilk.remaining, 0);
      final ({GameState state, int remaining}) ikinci =
          SportFamilySupport.spendCredit(ilk.state, SportExpense.ders, tutar);
      expect(ikinci.remaining, tutar,
          reason: '§31: aynı destek iki kez kullanılamaz.');
    });

    test('ders ücreti ödenirken kredi gerçekten harcanıyor', () {
      GameState s = aileKur(
        sporcu(artId: 'karate', level: 3, age: 15, wallet: 400000),
        anne: WealthTier.cokVarlikli,
        baba: null,
      );
      final MartialArt a = sanat('karate');
      final Person anne = ebeveyn(s, RelationType.anne)!;
      for (int i = 0; i < 80; i++) {
        final SportSupportResult r = SportFamilySupport.ask(
          state: s,
          expense: SportExpense.ders,
          person: anne,
          amount: a.lessonCost,
          rng: Random(i),
        );
        if (r.outcome.accepted) {
          s = r.state;
          break;
        }
      }
      expect(SportFamilySupport.creditFor(s, SportExpense.ders), a.lessonCost);

      final int cuzdanOnce = s.player.wallet;
      final r = const MartialArtsEngine().takeLesson(state: s, art: a);
      expect(r.outcome.applied, isTrue, reason: r.outcome.text);
      expect(r.state.player.wallet, cuzdanOnce,
          reason: 'Ders ücreti aile kredisinden karşılandığı için cüzdan '
              'değişmemeli.');
      expect(SportFamilySupport.creditFor(r.state, SportExpense.ders), 0,
          reason: 'Kredi harcanmış olmalı; yoksa sınırsız bedava ders.');
    });

    test('18 yaşında çocuk spor desteği ekranı kapanıyor', () {
      final GameState s = aileKur(
        sporcu(age: 18, wallet: 0),
        anne: WealthTier.cokVarlikli,
        baba: null,
      );
      final Person anne = ebeveyn(s, RelationType.anne)!;
      expect(
        SportFamilySupport.blockReason(
          state: s,
          expense: SportExpense.ders,
          person: anne,
          amount: 5000,
        ),
        isNotEmpty,
        reason: '§5: 18 yaş sonrası spor gideri oyuncuya ait.',
      );
      expect(SportFamilySupport.gearCovered(s, 0), isTrue,
          reason: 'Yetişkinde ekipman kalemi hiç oluşmamalı.');
    });

    test('ekipman parası yetmeyen genç müsabakadan men edilmiyor', () {
      // Kamp parası var, ekipmana yetmiyor.
      final int kamp = CombatCareerEngine.campCost(CampChoice.dengeli);
      final GameState fakir = musabaka(
        aileKur(sporcu(age: 15, wallet: kamp), anne: null, baba: null),
        seed: 5,
      );
      expect(SportFamilySupport.gearCovered(fakir, kamp), isFalse);
      final BoutResult r = CombatCareerEngine.fight(fakir, CampChoice.dengeli);
      expect(r.applied, isTrue,
          reason: '§4: ret ya da parasızlık kariyeri kapatmamalı.');

      // Bedel hazırlıkta: aynı sporcu, aynı tohum, parası olan hâli
      // daha güçlü.
      final GameState varlikli = musabaka(
        aileKur(sporcu(age: 15, wallet: kamp + SportFamilySupport.gearCost),
            anne: null, baba: null),
        seed: 5,
      );
      final double zayif = CombatCareerEngine.playerStrength(
          fakir, kariyer(fakir), CampChoice.dengeli);
      final double guclu = CombatCareerEngine.playerStrength(
          varlikli, kariyer(varlikli), CampChoice.dengeli);
      expect(guclu, greaterThan(zayif),
          reason: 'Ekipman/yol parası hazırlığa yansımalı.');
    });
  });

  // =================================================================
  // §6-§9 — okul + spor
  // =================================================================
  group('AL/2 okul + spor çatışması', () {
    GameState ogrenciSporcu({int grade = 10, int ortalama = 70}) => musabaka(
          okulda(sporcu(age: 16, level: 4), grade: grade, ortalama: ortalama),
          tier: 1,
          seed: 21,
        );

    test('çatışma gerçekten oluşuyor', () {
      int cikan = 0;
      for (int i = 0; i < 200; i++) {
        final GameState s = ogrenciSporcu();
        final r = SportSchoolConflict.maybeRaise(s, kariyer(s), Random(i));
        if (r.text != null) cikan++;
      }
      print('-- OKUL: 200 denemede $cikan çatışma --');
      expect(cikan, greaterThan(0), reason: '§6: çatışma hiç çıkmıyorsa '
          'mekanik yok demektir.');
      expect(cikan, lessThan(200),
          reason: '§8: her yıl çıkmamalı, nadir olmalı.');
    });

    test('okul dışındaki sporcuya çatışma çıkmıyor', () {
      final GameState s = musabaka(sporcu(age: 25, level: 4), tier: 1, seed: 7);
      for (int i = 0; i < 60; i++) {
        expect(SportSchoolConflict.maybeRaise(s, kariyer(s), Random(i)).text,
            isNull);
      }
    });

    test('turnuvayı seçmek gerçek state üretiyor', () {
      GameState s = ogrenciSporcu(ortalama: 70);
      s = _catismaKur(s);
      final SchoolConflictResult r = SportSchoolConflict.chooseSport(s);
      expect(r.outcome.applied, isTrue);
      expect(r.state.education.gradeAverage, lessThan(70),
          reason: '§7: okul performansına gerçek maliyet.');
      expect(kariyer(r.state).pendingBout, isNotNull,
          reason: '§7: spor fırsatı korunmalı.');
    });

    test('okulu seçmek farklı ve gerçek bir state üretiyor', () {
      GameState s = ogrenciSporcu(ortalama: 70);
      s = _catismaKur(s);
      final SchoolConflictResult r = SportSchoolConflict.chooseSchool(s);
      expect(r.outcome.applied, isTrue);
      expect(r.state.education.gradeAverage, greaterThanOrEqualTo(70),
          reason: '§7: okul korunmalı.');
      expect(kariyer(r.state).pendingBout, isNull,
          reason: '§7: o spor fırsatı kaçırılmalı.');
      expect(kariyer(r.state).form, lessThan(kariyer(s).form),
          reason: '§7: küçük form/momentum kaybı.');
    });

    test('kritik yılda bedel daha ağır', () {
      final GameState normal = _catismaKur(ogrenciSporcu(grade: 10));
      final GameState kritik = _catismaKur(ogrenciSporcu(grade: 12));
      final int normalDusus = 70 -
          SportSchoolConflict.chooseSport(normal).state.education.gradeAverage!;
      final int kritikDusus = 70 -
          SportSchoolConflict.chooseSport(kritik).state.education.gradeAverage!;
      print('-- OKUL: ortalama kaybı — normal yıl $normalDusus / '
          'kritik yıl $kritikDusus --');
      expect(kritikDusus, greaterThan(normalDusus), reason: '§9');
    });

    test('aynı çatışma iki kez uygulanmıyor', () {
      final GameState s = _catismaKur(ogrenciSporcu(ortalama: 70));
      final SchoolConflictResult ilk = SportSchoolConflict.chooseSport(s);
      expect(ilk.outcome.applied, isTrue);
      final SchoolConflictResult ikinci =
          SportSchoolConflict.chooseSport(ilk.state);
      expect(ikinci.outcome.applied, isFalse,
          reason: '§31: çözülmüş çatışma yeniden uygulanamaz.');
      expect(ikinci.state.education.gradeAverage,
          ilk.state.education.gradeAverage);

      // Aynı yıl yeni çatışma da üretilemez.
      final GameState tekrar = musabaka(ilk.state, seed: 33, tier: 1);
      for (int i = 0; i < 40; i++) {
        expect(
          SportSchoolConflict.maybeRaise(tekrar, kariyer(tekrar), Random(i))
              .text,
          isNull,
          reason: '§8: yılda bir kez.',
        );
      }
    });
  });

  // =================================================================
  // §10-§14 — spor başarısı → sosyal medya
  // =================================================================
  group('AL/2 spor başarısı ve sosyal medya', () {
    SocialContent icerik(String id) =>
        kSocialContents.firstWhere((SocialContent c) => c.id == id);

    GameState sosyalTaban({int age = 30}) {
      final GameState s =
          LifeGenerator.seeded(777).generate(mode: StartMode.tamamenRastgele);
      return s.copyWith(
        player: s.player.copyWith(age: age),
        pendingEvent: null,
        socialAccounts: <SocialAccount>[
          const SocialAccount(
            platform: SocialPlatform.video,
            followers: 20000,
            createdAtAge: 20,
          ),
          const SocialAccount(
            platform: SocialPlatform.foto,
            followers: 20000,
            createdAtAge: 20,
          ),
        ],
      );
    }

    GameState sampiyon(GameState s, {int unvanYasi = 29}) =>
        s.copyWith(combatCareers: <CombatCareer>[
          CombatCareer(
            artId: 'karate',
            startedCompetitiveAtAge: 18,
            tier: 3,
            proWins: 20,
            proLosses: 4,
            championships: 2,
            isChampion: true,
            reputation: 85,
            lastBoutAge: unvanYasi,
            lastTitleAge: unvanYasi,
          ),
        ]);

    test('şampiyon sporcu spor içeriğinde avantajlı', () {
      final GameState normal = sosyalTaban();
      final GameState usta = sampiyon(sosyalTaban());
      const SocialEngine motor = SocialEngine();
      final SocialContent vlog = icerik('vlog');

      int normalToplam = 0;
      int ustaToplam = 0;
      int ustaKazandi = 0;
      for (int i = 0; i < 120; i++) {
        final int a = motor.post(normal, vlog, Random(i)).outcome.followerDelta;
        final int b = motor.post(usta, vlog, Random(i)).outcome.followerDelta;
        normalToplam += a;
        ustaToplam += b;
        if (b > a) ustaKazandi++;
      }
      print('-- SOSYAL: vlog ortalama takipçi — sıradan '
          '${(normalToplam / 120).toStringAsFixed(1)} / şampiyon '
          '${(ustaToplam / 120).toStringAsFixed(1)} '
          '($ustaKazandi/120 seed üstün) --');
      expect(ustaToplam, greaterThan(normalToplam), reason: '§14');
    });

    test('spor ile ilgisi olmayan içerikte bonus çalışmıyor', () {
      final GameState normal = sosyalTaban();
      final GameState usta = sampiyon(sosyalTaban());
      const SocialEngine motor = SocialEngine();
      final SocialContent tarif = icerik('bilgi_videosu');
      expect(tarif.sportRelevance, 0.0);
      expect(SportSocialBoost.multiplierFor(usta, tarif), 1.0);

      for (int i = 0; i < 40; i++) {
        expect(
          motor.post(usta, tarif, Random(i)).outcome.followerDelta,
          motor.post(normal, tarif, Random(i)).outcome.followerDelta,
          reason: '§11: şampiyonluk bilgi videosunu büyütmemeli.',
        );
      }
    });

    test('eski başarı yeni başarıdan zayıf', () {
      final GameState yeni = sampiyon(sosyalTaban(age: 30), unvanYasi: 29);
      final GameState eski = sampiyon(sosyalTaban(age: 45), unvanYasi: 29);
      final double yeniPuan = SportSocialBoost.achievementScore(yeni);
      final double eskiPuan = SportSocialBoost.achievementScore(eski);
      print('-- SOSYAL: tazelik — 1 yıl önce '
          '${yeniPuan.toStringAsFixed(3)} / 16 yıl önce '
          '${eskiPuan.toStringAsFixed(3)} --');
      expect(eskiPuan, lessThan(yeniPuan), reason: '§12');
      expect(eskiPuan, greaterThan(0),
          reason: '§12: küçük bir legacy etkisi kalmalı.');
    });

    test('spor bonusu doğrudan para üretmiyor', () {
      final GameState usta = sampiyon(sosyalTaban());
      const SocialEngine motor = SocialEngine();
      for (int i = 0; i < 40; i++) {
        expect(motor.post(usta, icerik('vlog'), Random(i)).outcome.earned, 0,
            reason: '§13: kazanç yolu sponsorluk; paylaşım başına para yok.');
      }
    });

    test('şampiyon sporcu spam ile Ün 100 olmuyor', () {
      GameState s = sampiyon(sosyalTaban());
      const SocialEngine motor = SocialEngine();
      for (int i = 0; i < 60; i++) {
        final SocialResult r = motor.post(s, icerik('vlog'), Random(i));
        if (r.outcome.applied) s = r.state;
      }
      print('-- SOSYAL: 60 paylaşım sonrası Ün ${s.player.fame ?? 0} --');
      expect(s.player.fame ?? 0, lessThanOrEqualTo(100));
    });
  });

  // =================================================================
  // §15-§19 — rivalry
  // =================================================================
  group('AL/2 rivalry', () {
    CombatOpponent rakip({
      int metCount = 3,
      int playerWins = 2,
      int playerLosses = 1,
      int rating = 70,
      int age = 26,
      int tier = 0,
      int fameAwards = 0,
    }) =>
        CombatOpponent(
          id: 'rakip_sabit',
          name: 'Emre Karaca',
          age: age,
          rating: rating,
          metCount: metCount,
          playerWins: playerWins,
          playerLosses: playerLosses,
          tier: tier,
          fameAwards: fameAwards,
        );

    CombatCareer temelKariyer({
      List<CombatOpponent> rakipler = const <CombatOpponent>[],
      int reputation = 70,
      int tier = 2,
    }) =>
        CombatCareer(
          artId: 'karate',
          startedCompetitiveAtAge: 18,
          tier: tier,
          proWins: 12,
          proLosses: 5,
          reputation: reputation,
          lastBoutAge: 28,
          opponents: rakipler,
        );

    test('her ikinci karşılaşma büyük rekabet sayılmıyor', () {
      final CombatCareer k = temelKariyer(reputation: 10);
      final RivalStanding zayif = SportRivalry.standingFor(
        k,
        rakip(metCount: 2, playerWins: 2, playerLosses: 0, rating: 30),
      );
      expect(zayif.isMajor, isFalse, reason: '§16');
      expect(zayif.label, isNull, reason: '§28: anlamsız rekabet gösterilmez.');
    });

    test('tekrar ve skor yakınlığı rekabeti güçlendiriyor', () {
      final CombatCareer k = temelKariyer();
      final double az = SportRivalry.strengthOf(
          k, rakip(metCount: 2, playerWins: 2, playerLosses: 0));
      final double cok = SportRivalry.strengthOf(
          k, rakip(metCount: 4, playerWins: 2, playerLosses: 2));
      print('-- RIVALRY: güç — 2-0 ${az.toStringAsFixed(3)} / '
          '2-2 dört karşılaşma ${cok.toStringAsFixed(3)} --');
      expect(cok, greaterThan(az), reason: '§16');
    });

    test('önemli rekabeti kazanmak ün getiriyor', () {
      final GameState s = sporcu(age: 28, level: 6, artId: 'karate');
      final CombatOpponent r = rakip(metCount: 3, rating: 70, tier: 3);
      final CombatCareer k = temelKariyer(rakipler: <CombatOpponent>[r]);
      final int bonus = SportRivalry.fameBonus(
        state: s,
        career: k,
        opponent: r,
        won: true,
      );
      print('-- RIVALRY: rövanş ün katkısı $bonus --');
      expect(bonus, greaterThan(0), reason: '§17');
      expect(
        SportRivalry.fameBonus(state: s, career: k, opponent: r, won: false),
        0,
        reason: '§17: kaybedilen maç ün getirmez.',
      );
    });

    test('ün katkısı azalan getiri ve yıllık tavanla sınırlı', () {
      final GameState s = sporcu(age: 28, level: 6);
      final CombatOpponent ilk = rakip(metCount: 3, rating: 70, tier: 3);
      final CombatOpponent cokKez =
          rakip(metCount: 3, rating: 70, tier: 3, fameAwards: 4);
      final CombatCareer k1 = temelKariyer(rakipler: <CombatOpponent>[ilk]);
      final CombatCareer k2 = temelKariyer(rakipler: <CombatOpponent>[cokKez]);
      final int a =
          SportRivalry.fameBonus(state: s, career: k1, opponent: ilk, won: true);
      final int b = SportRivalry.fameBonus(
          state: s, career: k2, opponent: cokKez, won: true);
      print('-- RIVALRY: azalan getiri — ilk ödül $a / beşinci ödül $b --');
      expect(b, lessThan(a), reason: '§17');

      // Yıllık tavan: sayaç dolunca sıfırlanır.
      final GameState dolu =
          SportRivalry.markFame(s, SportRivalry.prototypeOnlyYearlyFameCap);
      expect(
        SportRivalry.fameBonus(
            state: dolu, career: k1, opponent: ilk, won: true),
        0,
        reason: '§17: aynı rakibe yirmi kez çıkarak Ün 100 olunmamalı.',
      );
    });

    test('rekabet sosyal medyada da ilgi yaratıyor ve zamanla sönüyor', () {
      final CombatCareer taze = temelKariyer(
        rakipler: <CombatOpponent>[rakip(metCount: 4, tier: 3)],
      );
      final double yakin = SportRivalry.socialInterest(taze, 28);
      final double uzak = SportRivalry.socialInterest(taze, 40);
      print('-- RIVALRY: sosyal ilgi — maç yılı '
          '${yakin.toStringAsFixed(3)} / 12 yıl sonra '
          '${uzak.toStringAsFixed(3)} --');
      expect(yakin, greaterThan(0), reason: '§18');
      expect(uzak, 0, reason: '§18: eski husumet konuşulmaz.');
      expect(yakin,
          lessThanOrEqualTo(SportRivalry.prototypeOnlyMaxSocialInterest));
    });

    test('önemli rakip oyuncuyla birlikte ilerleyebiliyor', () {
      final CombatCircuit yol = combatCircuitFor('karate')!;
      // Alt kademede tanışılmış güçlü bir rekabet; oyuncu üst kademede.
      final CombatOpponent eski = rakip(
        metCount: 4,
        playerWins: 2,
        playerLosses: 2,
        rating: yol.tiers[0].opponentRating,
        age: 24,
        tier: 3,
      );
      CombatCareer k = temelKariyer(
        rakipler: <CombatOpponent>[eski],
        tier: 3,
      );
      expect(SportRivalry.standingFor(k, eski).isMajor, isTrue);

      final int baslangic = eski.rating;
      for (int yil = 0; yil < 6; yil++) {
        k = SportRivalry.advanceRivals(k, Random(yil));
      }
      final CombatOpponent son = k.opponents.first;
      print('-- RIVALRY: rakip gücü $baslangic → ${son.rating} '
          '(oyuncu kademesi ${yol.tiers[3].opponentRating}) --');
      expect(son.rating, greaterThan(baslangic), reason: '§19');
      expect(son.rating, lessThanOrEqualTo(yol.tiers[3].opponentRating + 8),
          reason: '§19: mantıklı bir tavan olmalı.');
      expect(son.age, eski.age + 6, reason: 'Rakip de yaşlanmalı.');
    });

    test('üst kademeye çıkan oyuncu eski rakibiyle yeniden eşleşebiliyor', () {
      // Paket AL/VERIFY'in belgelediği sınır buydu: tanıdık rakip
      // yalnızca kendi kademesinde dönüyordu, oyuncu üst kademeye
      // çıkınca 200 fırsatta **0 kez** geri geliyordu. §19 bunu
      // istiyor. Test uçtan uca: rakip yıllar içinde ilerliyor, sonra
      // eşleşme ürünün kendi `offerBout` kapısından aranıyor.
      final CombatCircuit yol = combatCircuitFor('karate')!;
      GameState s = sporcu(age: 26, level: 6, artId: 'karate');
      CombatCareer k = kariyer(s).copyWith(
        tier: 3,
        reputation: 60,
        form: 70,
        proWins: 10,
        opponents: <CombatOpponent>[
          CombatOpponent(
            id: 'eski_rakip',
            name: 'Emre Karaca',
            age: 25,
            // Alt kademede tanışıldı: üst kademenin eşleşme bandının
            // dışında.
            rating: yol.tiers[0].opponentRating,
            metCount: 4,
            playerWins: 2,
            playerLosses: 2,
            tier: 3,
          ),
        ],
      );
      s = s.copyWith(combatCareers: <CombatCareer>[k]);

      int oncekiEslesme = 0;
      for (int i = 0; i < 200; i++) {
        final r = CombatCareerEngine.offerBout(s, Random(i));
        if (r.bout?.opponent.id == 'eski_rakip') oncekiEslesme++;
      }

      // Rakip kendi kariyerinde ilerliyor (yıllık akış).
      for (int yil = 0; yil < 8; yil++) {
        k = SportRivalry.advanceRivals(k, Random(yil));
      }
      s = s.copyWith(combatCareers: <CombatCareer>[k]);

      int sonrakiEslesme = 0;
      for (int i = 0; i < 200; i++) {
        final r = CombatCareerEngine.offerBout(s, Random(i));
        if (r.bout?.opponent.id == 'eski_rakip') sonrakiEslesme++;
      }

      print('-- RIVALRY: 200 fırsatta eski rakiple eşleşme — '
          'ilerlemeden önce $oncekiEslesme / sonra $sonrakiEslesme --');
      expect(oncekiEslesme, 0,
          reason: 'Kurulum doğru olsun: rakip başta bandın dışında.');
      expect(sonrakiEslesme, greaterThan(0),
          reason: '§19: önemli rakip oyuncuyla birlikte yükselip ileride '
              'yeniden karşısına çıkabilmeli.');
    });

    test('rakip sonsuza kadar zirvede tutulmuyor', () {
      CombatCareer k = temelKariyer(
        rakipler: <CombatOpponent>[
          rakip(metCount: 4, playerWins: 2, playerLosses: 2, age: 40, tier: 3),
        ],
        tier: 3,
      );
      final int once = k.opponents.first.rating;
      for (int yil = 0; yil < 5; yil++) {
        k = SportRivalry.advanceRivals(k, Random(yil));
      }
      final CombatOpponent son = k.opponents.first;
      expect(son.rating, lessThan(once), reason: '§19: yaşlanan rakip düşer.');
      expect(SportRivalry.isSelectable(son), isFalse,
          reason: '§19: 45 yaşındaki rakip havuzda kalmamalı.');
    });
  });

  // =================================================================
  // §20-§25 — iş + spor
  // =================================================================
  group('AL/2 iş + spor', () {
    test('işsiz > part-time > full-time fırsat sayısı', () {
      final GameState issiz = sporcu(age: 26, level: 5);
      final GameState yarim = iste(issiz, yariZamanliIs());
      final GameState tam = iste(issiz, tamZamanliIs());
      expect(SportWorkload.of(issiz), SportWorkLoad.yok);
      expect(SportWorkload.of(yarim), SportWorkLoad.yariZamanli);
      expect(SportWorkload.of(tam), SportWorkLoad.tamZamanli);

      int say(GameState s) {
        int n = 0;
        for (int i = 0; i < 500; i++) {
          if (CombatCareerEngine.offerBout(s, Random(i)).bout != null) n++;
        }
        return n;
      }

      final int a = say(issiz);
      final int b = say(yarim);
      final int c = say(tam);
      print('-- İŞ: 500 fırsat denemesi — işsiz $a / part-time $b / '
          'full-time $c --');
      expect(a, greaterThan(b), reason: '§24');
      expect(b, greaterThan(c), reason: '§22, §24');
      expect(c, greaterThan(0), reason: '§24: full-time sıfıra düşmemeli.');
    });

    test('iş kazanma ihtimaline doğrudan ceza yazmıyor', () {
      final GameState issiz = musabaka(sporcu(age: 26, level: 5), seed: 9);
      final GameState tam = iste(issiz, tamZamanliIs());
      final CombatCareer k1 = kariyer(issiz);
      final CombatCareer k2 = kariyer(tam);
      expect(
        CombatCareerEngine.winChance(
            tam, k2, k2.pendingBout!, CampChoice.dengeli),
        CombatCareerEngine.winChance(
            issiz, k1, k1.pendingBout!, CampChoice.dengeli),
        reason: '§25: bedel forma ve fırsata yansımalı, win chance\'e '
            'doğrudan değil.',
      );
    });

    test('çalışan sporcunun formu korumak daha zor', () {
      // Bedel **telafi** üzerinden geliyor: çalışan sporcunun aynı
      // çalışmadan elde ettiği form karşılığı daha az. Bu yüzden ölçüm
      // gerçekten çalışan bir sporcuda yapılıyor — hiç ders almayan
      // sporcuda telafi zaten 0 olduğu için iki durum eşittir ve bu
      // bilinçli: yapmadığın antrenmanı iş senden alamaz.
      final MartialArt a = sanat('karate');
      final GameState calisan = sporcu(age: 26, level: 5).copyWith(
        interactionCounts: <String, int>{
          // Motorun okuduğu anahtar (bkz. aşağıdaki BİLİNEN BUG testi).
          GameState.interactionKey(a.id, 'dovus'): 4,
        },
      );
      final GameState issiz = calisan;
      final GameState tam = iste(calisan, tamZamanliIs());
      final GameState yarim = iste(calisan, yariZamanliIs());

      final int formIssiz =
          kariyer(CombatCareerEngine.advanceYear(issiz, 27, Random(1)).state)
              .form;
      final int formYarim =
          kariyer(CombatCareerEngine.advanceYear(yarim, 27, Random(1)).state)
              .form;
      final int formTam =
          kariyer(CombatCareerEngine.advanceYear(tam, 27, Random(1)).state)
              .form;
      print('-- İŞ: yıl sonu form — işsiz $formIssiz / part-time '
          '$formYarim / full-time $formTam --');
      expect(formTam, lessThan(formIssiz), reason: '§21');
      expect(formYarim, lessThan(formIssiz), reason: '§22');
      expect(formTam, lessThan(formYarim),
          reason: '§22: part-time ile full-time aynı ceza olmamalı.');
      expect(SportWorkload.note(tam), isNotNull, reason: '§29');
      expect(SportWorkload.note(issiz), isNull);
    });

    test('BİLİNEN BUG: ders telafisi sayacı iki tarafta ters yazılmış', () {
      // Bu test bir düzeltmeyi değil, **bulunan ve bilerek
      // düzeltilmeyen** bir hatayı kilitliyor (Q-184 #1).
      //
      // `MartialArtsEngine` ders sayacını 'dovus|<artId>' anahtarıyla
      // yazıyor; `CombatCareerEngine.advanceYear` ise onu
      // '<artId>|dovus' diye okuyor. İki anahtar farklı olduğu için
      // "çalışmak formu telafi eder" kuralı Paket AL'den beri hiç
      // işlemiyor.
      //
      // Düzeltme denendi ve 600 sporcu ölçümünün medyan gelirini
      // 4,04 M₺'den 6,51 M₺'ye çıkardı; brief §0 bu paketin dengeye
      // dokunmasını yasakladığı için geri alındı. Karar Faho'da.
      //
      // Test, hatanın **hangi yönde** durduğunu belgeliyor: düzeltme
      // yapıldığı gün bu test kırılır ve o zaman bilinçli olarak
      // güncellenir.
      final MartialArt a = sanat('karate');
      final GameState taban = sporcu(age: 26, level: 5);
      final GameState motorunOkudugu = taban.copyWith(
        interactionCounts: <String, int>{
          GameState.interactionKey(a.id, 'dovus'): 4,
        },
      );
      final GameState motorunYazdigi = taban.copyWith(
        interactionCounts: <String, int>{
          GameState.interactionKey('dovus', a.id): 4,
        },
      );
      final int yok =
          kariyer(CombatCareerEngine.advanceYear(taban, 27, Random(2)).state)
              .form;
      final int okunan = kariyer(
              CombatCareerEngine.advanceYear(motorunOkudugu, 27, Random(2))
                  .state)
          .form;
      final int yazilan = kariyer(
              CombatCareerEngine.advanceYear(motorunYazdigi, 27, Random(2))
                  .state)
          .form;
      print('-- BUG: form — sayaçsız $yok / motorun OKUDUĞU anahtar '
          '$okunan / ürünün YAZDIĞI anahtar $yazilan --');
      expect(okunan, greaterThan(yok),
          reason: 'Motor telafiyi hesaplayabiliyor...');
      expect(yazilan, yok,
          reason: '...ama ürünün gerçekte yazdığı anahtarı okumuyor. '
              'Bu eşitlik bozulursa hata düzeltilmiş demektir; Q-184 #1 '
              'kararıyla birlikte bu test güncellenmeli.');
    });

    test('işten ayrılınca ceza da kalkıyor', () {
      final GameState tam = iste(sporcu(age: 26, level: 5), tamZamanliIs());
      final GameState ayrildi = tam.copyWith(
        career: const CareerState(),
      );
      expect(SportWorkload.of(ayrildi), SportWorkLoad.yok,
          reason: '§31: iş değişince ceza doğru güncellenmeli.');
      expect(SportWorkload.opportunityFactor(ayrildi), 1.0);
    });
  });

  // =================================================================
  // §30 — kayıt / yükleme
  // =================================================================
  group('AL/2 kayıt', () {
    test('yeni alanlar roundtrip ile korunuyor', () {
      GameState s = _catismaKur(musabaka(
        okulda(sporcu(age: 16, level: 4)),
        tier: 1,
        seed: 31,
      ));
      final CombatCareer k = kariyer(s);
      s = s.copyWith(combatCareers: <CombatCareer>[
        k.copyWith(
          lastTitleAge: 15,
          opponents: <CombatOpponent>[
            const CombatOpponent(
              id: 'r1',
              name: 'Emre Karaca',
              age: 27,
              rating: 66,
              metCount: 3,
              playerWins: 2,
              playerLosses: 1,
              fameAwards: 2,
              tier: 3,
            ),
          ],
        ),
      ]);

      final GameState geri = decodeGameState(encodeGameState(s));
      final CombatCareer gk = CombatCareerEngine.activeCareer(geri)!;
      expect(gk.lastTitleAge, 15);
      expect(gk.schoolConflictAge, 16);
      expect(gk.opponents.first.fameAwards, 2);
      expect(gk.opponents.first.tier, 3);
    });

    test('eski kayıt (yeni alanlar yok) bozulmadan yükleniyor', () {
      final GameState s = sporcu(age: 20, level: 4);
      final Map<String, Object?> json = encodeGameState(s);
      final List<Object?> kariyerler =
          json['combatCareers']! as List<Object?>;
      final Map<String, Object?> ilk =
          Map<String, Object?>.from(kariyerler.first! as Map<String, Object?>)
            ..remove('lastTitleAge')
            ..remove('schoolConflictAge');
      json['combatCareers'] = <Object?>[ilk];

      final GameState geri = decodeGameState(json);
      final CombatCareer gk = CombatCareerEngine.activeCareer(geri)!;
      expect(gk.lastTitleAge, isNull);
      expect(gk.schoolConflictAge, isNull);
      expect(gk.artId, kariyer(s).artId);
    });
  });

  // =================================================================
  // §34 — hedefli entegrasyon simülasyonu (200 + 200 + 200)
  //
  // Genel 3000 hayat YOK. Yalnızca bu paketin dokunduğu üç kesişim
  // ölçülüyor ve sayılar konsola basılıyor; rapor buradan üretiliyor.
  // =================================================================
  group('AL/2 §34 hedefli entegrasyon ölçümü', () {
    test('200 genç sporcu — aile desteği ve okul çatışması', () {
      const List<WealthTier> basamaklar = <WealthTier>[
        WealthTier.cokYoksul,
        WealthTier.yoksul,
        WealthTier.ortaHalli,
        WealthTier.varlikli,
        WealthTier.cokVarlikli,
      ];
      final Map<WealthTier, int> istek = <WealthTier, int>{};
      final Map<WealthTier, int> kabul = <WealthTier, int>{};
      int catismaSayisi = 0;
      int sporSecildi = 0;
      int okulSecildi = 0;
      int butceAsimi = 0;
      int krediAsimi = 0;
      int toplamMac = 0;
      int kademeYukselen = 0;

      for (int i = 0; i < 200; i++) {
        final WealthTier varlik = basamaklar[i % basamaklar.length];
        final Random rng = Random(7000 + i);
        // Küçüklükten beri çalışan bir genç: kademe 2'nin teknik şartını
        // karşılıyor, ama kademe atlamayı yine galibiyet ve itibar
        // belirliyor. Yoksa ölçüm teknik darlığında tıkanıyor ve
        // okul/spor çatışmasının hiç çıkmadığı yanlış sonucu veriyor.
        final CombatCircuit yol = combatCircuitFor('karate')!;
        GameState s = aileKur(
          okulda(sporcu(
            age: 14,
            level: yol.minLevelFor(2),
            seed: 3000 + i,
            wallet: 120000,
          )),
          anne: varlik,
          baba: varlik,
        );

        // Lise (15-18) ve üniversite (19-22): okul/spor çatışmasının
        // gerçekten yaşanabildiği pencerenin tamamı. Aile desteği
        // yalnızca 18 yaş altında açık.
        for (int yas = 15; yas <= 22; yas++) {
          final CombatCareer? kOnce = CombatCareerEngine.activeCareer(s);
          if (kOnce == null || kOnce.isRetired) break;
          s = s.copyWith(
            player: s.player.copyWith(age: yas),
            // Yıl dönümü: sayaçlar sıfırlanır (oyunun kendi davranışı).
            interactionCounts: <String, int>{
              // Düzenli çalışan genç sporcu.
              GameState.interactionKey('dovus', kOnce.artId): 3,
            },
            education: yas <= 18
                ? s.education.copyWith(grade: min(12, yas - 5))
                : EducationState(
                    finished: true,
                    universityProgramId: 'genel',
                    universityYear: yas - 18,
                    gradeAverage: s.education.gradeAverage ?? 70,
                  ),
          );
          final CombatCareer? k = CombatCareerEngine.activeCareer(s);
          if (k == null || k.isRetired) break;

          // Harçlık/burs: kamp parası her yıl tükenip ölçümü
          // parasızlığa kilitlemesin.
          s = s.copyWith(
            player: s.player.copyWith(
              wallet: max(s.player.wallet, 120000),
            ),
          );
          s = CombatCareerEngine.advanceYear(s, yas, rng).state;

          // Kamp masrafı için aileden destek istenir (18 yaş altıysa).
          final List<Person> destekciler =
              SportFamilySupport.sponsorsFor(s);
          if (yas < SportFamilySupport.adultAge && destekciler.isNotEmpty) {
            final Person ebv = destekciler[rng.nextInt(destekciler.length)];
            final int tutar =
                SportFamilySupport.defaultCost(s, SportExpense.kamp);
            if (SportFamilySupport.blockReason(
              state: s,
              expense: SportExpense.kamp,
              person: ebv,
              amount: tutar,
            ).isEmpty) {
              istek[varlik] = (istek[varlik] ?? 0) + 1;
              final SportSupportResult r = SportFamilySupport.ask(
                state: s,
                expense: SportExpense.kamp,
                person: ebv,
                amount: tutar,
                rng: rng,
              );
              s = r.state;
              if (r.outcome.accepted) {
                kabul[varlik] = (kabul[varlik] ?? 0) + 1;
              }
              // EXPLOIT: ebeveynin verdiği toplam, kapasitesini aşamaz.
              if (CourseSupport.usedThisYear(s, ebv.id) >
                  CourseSupport.yearlyBudget(ebv)) {
                butceAsimi++;
              }
              // EXPLOIT: kredi masraftan büyük olamaz.
              if (SportFamilySupport.creditFor(s, SportExpense.kamp) > tutar) {
                krediAsimi++;
              }
            }
          }

          // Müsabaka fırsatı.
          final firsat = CombatCareerEngine.offerBout(s, rng);
          s = firsat.state;
          if (firsat.bout == null) continue;

          // Okul çatışması.
          final catisma = SportSchoolConflict.maybeRaise(
            s,
            CombatCareerEngine.activeCareer(s)!,
            rng,
          );
          s = catisma.state;
          if (catisma.text != null) {
            catismaSayisi++;
            if (rng.nextBool()) {
              sporSecildi++;
              s = SportSchoolConflict.chooseSport(s).state;
            } else {
              okulSecildi++;
              s = SportSchoolConflict.chooseSchool(s).state;
            }
          }

          final CombatCareer? guncel = CombatCareerEngine.activeCareer(s);
          if (guncel?.pendingBout == null) continue;
          final BoutResult b =
              CombatCareerEngine.fight(s, CampChoice.dengeli);
          if (b.applied) {
            s = b.state;
            toplamMac++;
          }
        }
        if ((CombatCareerEngine.activeCareer(s)?.tier ?? 0) >= 1) {
          kademeYukselen++;
        }
      }

      print('');
      print('-- §34/A: 200 GENÇ SPORCU --');
      for (final WealthTier t in basamaklar) {
        final int i = istek[t] ?? 0;
        final int ka = kabul[t] ?? 0;
        print('  ${t.name.padRight(13)} istek ${i.toString().padLeft(3)}  '
            'kabul ${ka.toString().padLeft(3)}  '
            'oran ${i == 0 ? "-" : "${(ka * 100 / i).toStringAsFixed(0)}%"}');
      }
      print('  toplam müsabaka: $toplamMac, '
          'kademe 1+ ulaşan: $kademeYukselen/200');
      print('  okul çatışması: $catismaSayisi kez '
          '(turnuva $sporSecildi / okul $okulSecildi)');
      print('  EXPLOIT — bütçe aşımı: $butceAsimi, kredi aşımı: $krediAsimi');

      // Dar gelirli ailenin %0'ı bir kapanma değil, bütçe gerçeği:
      // istenen kalem (dengeli kamp) onun yıllık kapasitesinin
      // üstünde. Daha ucuz kalem sorulduğunda kapı açık (§4).
      int ucuzKabul = 0;
      int ucuzIstek = 0;
      for (int i = 0; i < 40; i++) {
        final GameState s = aileKur(
          sporcu(age: 15, level: 3, seed: 4100 + i, wallet: 0),
          anne: WealthTier.yoksul,
          baba: null,
        );
        final Person? ebv = ebeveyn(s, RelationType.anne);
        if (ebv == null) continue;
        final int ucuz =
            (Economy.netYearlyMinimumWage * 0.02).round();
        if (SportFamilySupport.blockReason(
          state: s,
          expense: SportExpense.kamp,
          person: ebv,
          amount: ucuz,
        ).isNotEmpty) {
          continue;
        }
        ucuzIstek++;
        if (SportFamilySupport.ask(
          state: s,
          expense: SportExpense.kamp,
          person: ebv,
          amount: ucuz,
          rng: Random(i),
        ).outcome.accepted) {
          ucuzKabul++;
        }
      }
      print('  yoksul aile, EN UCUZ hazırlık: $ucuzKabul/$ucuzIstek kabul');
      expect(ucuzIstek, greaterThan(0),
          reason: '§4: dar gelirli ailede ucuz seçenek kapalı olmamalı.');

      expect(butceAsimi, 0, reason: '§3: para yoktan yaratılmamalı.');
      expect(krediAsimi, 0, reason: '§3: kredi masraftan büyük olamaz.');
      expect(catismaSayisi, greaterThan(0), reason: '§6');
      // Varlıklı aile dar gelirli aileden daha çok kabul etmeli.
      final double fakirOran =
          (kabul[WealthTier.cokYoksul] ?? 0) / max(1, istek[WealthTier.cokYoksul] ?? 1);
      final double zenginOran = (kabul[WealthTier.cokVarlikli] ?? 0) /
          max(1, istek[WealthTier.cokVarlikli] ?? 1);
      expect(zenginOran, greaterThan(fakirOran), reason: '§2');
    });

    test('200 çalışan sporcu — iş + spor', () {
      final Map<SportWorkLoad, int> firsat = <SportWorkLoad, int>{};
      final Map<SportWorkLoad, int> mac = <SportWorkLoad, int>{};
      final Map<SportWorkLoad, int> formToplam = <SportWorkLoad, int>{};
      final Map<SportWorkLoad, int> kisi = <SportWorkLoad, int>{};

      for (int i = 0; i < 200; i++) {
        final SportWorkLoad yuk =
            SportWorkLoad.values[i % SportWorkLoad.values.length];
        final Random rng = Random(8000 + i);
        GameState s = sporcu(age: 22, level: 5, seed: 5000 + i);
        s = switch (yuk) {
          SportWorkLoad.yok => s,
          SportWorkLoad.yariZamanli => iste(s, yariZamanliIs()),
          SportWorkLoad.tamZamanli => iste(s, tamZamanliIs()),
        };
        expect(SportWorkload.of(s), yuk);
        kisi[yuk] = (kisi[yuk] ?? 0) + 1;

        for (int yas = 23; yas <= 32; yas++) {
          final CombatCareer? k = CombatCareerEngine.activeCareer(s);
          if (k == null || k.isRetired) break;
          s = s.copyWith(
            player: s.player.copyWith(age: yas),
            interactionCounts: <String, int>{
              // Her yıl düzenli çalışan sporcu. Anahtar bilerek motorun
              // OKUDUĞU sırada yazılıyor: ürünün yazdığı sıra bilinen
              // bir hata yüzünden okunmuyor (Q-184 #1) ve bu ölçüm o
              // hatanın gölgesinde kalmasın.
              GameState.interactionKey(k.artId, 'dovus'): 4,
            },
          );
          s = CombatCareerEngine.advanceYear(s, yas, rng).state;
          for (int t = 0; t < 4; t++) {
            final r = CombatCareerEngine.offerBout(s, rng);
            s = r.state;
            if (r.bout == null) break;
            firsat[yuk] = (firsat[yuk] ?? 0) + 1;
            final BoutResult b =
                CombatCareerEngine.fight(s, CampChoice.dengeli);
            if (!b.applied) break;
            s = b.state;
            mac[yuk] = (mac[yuk] ?? 0) + 1;
          }
        }
        final CombatCareer son = s.combatCareers.first;
        formToplam[yuk] = (formToplam[yuk] ?? 0) + son.form;
      }

      print('');
      print('-- §34/B: 200 ÇALIŞAN SPORCU --');
      for (final SportWorkLoad y in SportWorkLoad.values) {
        final int n = kisi[y] ?? 1;
        print('  ${y.label.padRight(18)} '
            'fırsat/kişi ${((firsat[y] ?? 0) / n).toStringAsFixed(2)}  '
            'maç/kişi ${((mac[y] ?? 0) / n).toStringAsFixed(2)}  '
            'son form ${((formToplam[y] ?? 0) / n).toStringAsFixed(1)}');
      }
      final double a = (firsat[SportWorkLoad.yok] ?? 0) /
          max(1, kisi[SportWorkLoad.yok] ?? 1);
      final double c = (firsat[SportWorkLoad.tamZamanli] ?? 0) /
          max(1, kisi[SportWorkLoad.tamZamanli] ?? 1);
      print('  full-time fırsat kaybı: '
          '${((1 - c / a) * 100).toStringAsFixed(1)}%');
      expect(a, greaterThan(c), reason: '§21');
      expect(c, greaterThan(0), reason: '§24: full-time sıfıra düşmemeli.');
    });

    test('200 sosyal sporcu — başarı, rekabet ve sosyal medya', () {
      const SocialEngine motor = SocialEngine();
      final SocialContent vlog =
          kSocialContents.firstWhere((SocialContent c) => c.id == 'vlog');
      // DİKKAT: karşılaştırma içeriği **aynı platformda** olmalı.
      // İlk yazımda 'yemek_tarifi_videosu' kullanılmıştı; o kısa video
      // platformunda ve bu ölçümde oyuncunun o platformda hesabı yok,
      // dolayısıyla iki taraf da 0 dönüyor ve test hiçbir şeyi
      // kanıtlamıyordu (always-pass). 'oyun_videosu' aynı video
      // platformunda ve spor ilgisi 0.
      final SocialContent tarif = kSocialContents
          .firstWhere((SocialContent c) => c.id == 'oyun_videosu');
      expect(tarif.platform, vlog.platform);
      expect(tarif.sportRelevance, 0.0);

      int sporcuToplam = 0;
      int sadeToplam = 0;
      int sporcuTarif = 0;
      int sadeTarif = 0;
      int unTavaniAsan = 0;
      int rekabetUnu = 0;
      int yillikTavanAsan = 0;

      for (int i = 0; i < 200; i++) {
        final Random rng = Random(9000 + i);
        // Sade oyuncu: aynı yaş, aynı takipçi, spor kariyeri yok.
        GameState taban = LifeGenerator.seeded(6000 + i)
            .generate(mode: StartMode.tamamenRastgele)
            .copyWith(
              pendingEvent: null,
              socialAccounts: <SocialAccount>[
                const SocialAccount(
                  platform: SocialPlatform.video,
                  followers: 15000,
                  createdAtAge: 20,
                ),
              ],
            );
        taban = taban.copyWith(player: taban.player.copyWith(age: 29));

        final GameState sporcuHal = taban.copyWith(
          combatCareers: <CombatCareer>[
            CombatCareer(
              artId: 'karate',
              startedCompetitiveAtAge: 18,
              tier: 3,
              proWins: 18,
              proLosses: 5,
              championships: 1 + i % 2,
              isChampion: i % 3 != 0,
              reputation: 60 + i % 35,
              lastBoutAge: 28,
              lastTitleAge: 28,
              opponents: <CombatOpponent>[
                CombatOpponent(
                  id: 'r$i',
                  name: 'Rakip $i',
                  age: 28,
                  rating: 74,
                  metCount: 3,
                  playerWins: 2,
                  playerLosses: 1,
                  tier: 3,
                ),
              ],
            ),
          ],
        );

        final int seed = rng.nextInt(1 << 20);
        sporcuToplam +=
            motor.post(sporcuHal, vlog, Random(seed)).outcome.followerDelta;
        sadeToplam +=
            motor.post(taban, vlog, Random(seed)).outcome.followerDelta;
        sporcuTarif +=
            motor.post(sporcuHal, tarif, Random(seed)).outcome.followerDelta;
        sadeTarif +=
            motor.post(taban, tarif, Random(seed)).outcome.followerDelta;

        // Rekabetin ün katkısı ve yıllık tavan.
        final CombatCareer k = sporcuHal.combatCareers.first;
        final int bonus = SportRivalry.fameBonus(
          state: sporcuHal,
          career: k,
          opponent: k.opponents.first,
          won: true,
        );
        rekabetUnu += bonus;
        if (bonus > SportRivalry.prototypeOnlyYearlyFameCap) {
          yillikTavanAsan++;
        }

        // Ün tavanı: spam ile 100 olunmuyor.
        GameState spam = sporcuHal;
        for (int t = 0; t < 25; t++) {
          final SocialResult r = motor.post(spam, vlog, Random(t));
          if (r.outcome.applied) spam = r.state;
        }
        if ((spam.player.fame ?? 0) > 100) unTavaniAsan++;
      }

      print('');
      print('-- §34/C: 200 SOSYAL SPORCU --');
      print('  spor içeriği (vlog) ortalama takipçi — '
          'şampiyon ${(sporcuToplam / 200).toStringAsFixed(1)} / '
          'sade ${(sadeToplam / 200).toStringAsFixed(1)} '
          '(fark ${((sporcuToplam / max(1, sadeToplam) - 1) * 100).toStringAsFixed(1)}%)');
      print('  spor dışı içerik (oyun videosu) — '
          'şampiyon ${(sporcuTarif / 200).toStringAsFixed(1)} / '
          'sade ${(sadeTarif / 200).toStringAsFixed(1)}');
      print('  rekabet ün katkısı: ortalama '
          '${(rekabetUnu / 200).toStringAsFixed(2)} '
          '(yıllık tavan ${SportRivalry.prototypeOnlyYearlyFameCap})');
      print('  EXPLOIT — yıllık ün tavanını aşan: $yillikTavanAsan, '
          'Ün 100 üstü: $unTavaniAsan');

      expect(sporcuToplam, greaterThan(sadeToplam), reason: '§14');
      expect(sporcuTarif, sadeTarif,
          reason: '§11: spor dışı içerikte fark olmamalı.');
      expect(sporcuTarif, greaterThan(0),
          reason: 'Karşılaştırma anlamlı olsun: içerik gerçekten '
              'paylaşılabilmiş olmalı (always-pass koruması).');
      expect(yillikTavanAsan, 0, reason: '§17');
      expect(unTavaniAsan, 0, reason: '§17');
    });
  });
}


/// Çatışmayı kesin olarak kurar (tohum aramadan).
///
/// Motor kendi şartlarını kontrol etsin diye tohum taranıyor; state
/// elle yazılmıyor.
GameState _catismaKur(GameState s) {
  for (int i = 0; i < 400; i++) {
    final r = SportSchoolConflict.maybeRaise(
      s,
      CombatCareerEngine.activeCareer(s)!,
      Random(i),
    );
    if (r.text != null) return r.state;
  }
  fail('Okul/spor çatışması hiçbir tohumda çıkmadı.');
}
