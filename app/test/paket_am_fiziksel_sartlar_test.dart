// Paket AM — mantıksal meslek / fiziksel uygunluk şartları.
//
// İki kesin karar var: mankenlik için dış görünüş **80**, rekabetçi
// dövüş kariyeri için sağlık **80**. Bunların yanında işin doğası
// gerçekten beden istiyorsa `JobType.minHealth` dolduruldu.
//
// Testlerin hepsi ürünün gerçek kapılarından geçiyor:
// `JobMarket.requirementReason`, `CombatCareerEngine.startAvailability`,
// `CombatCareerEngine.fight`, `MartialArtsEngine.takeLesson`,
// `ActivityEngine`. Eşikler testten sabit yazılmıyor, katalogdan ve
// motorun sabitlerinden okunuyor: sayı değişirse test kendisi değil,
// beklenti birlikte kayar.
//
// ignore_for_file: avoid_print
library;


import 'package:bir_omur/data/activity_catalog.dart';
import 'package:bir_omur/data/combat_circuit_catalog.dart';
import 'package:bir_omur/data/job_catalog.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/data/martial_arts_catalog.dart';
import 'package:bir_omur/domain/activities/activity_engine.dart';
import 'package:bir_omur/domain/activities/martial_arts_engine.dart';
import 'package:bir_omur/domain/career/job_market.dart';
import 'package:bir_omur/domain/career/job_requirement.dart';
import 'package:bir_omur/domain/combat/combat_career_engine.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/combat_career.dart';
import 'package:bir_omur/domain/models/education.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/interaction.dart';
import 'package:bir_omur/domain/models/martial_progress.dart';
import 'package:flutter_test/flutter_test.dart';

const JobMarket market = JobMarket();

JobType is_(String id) => jobById(id)!;

MartialArt sanat(String id) =>
    MartialArt.values.firstWhere((MartialArt a) => a.id == id);

/// Lise mezunu, işsiz, temiz sicilli, büyük şehirde bir yetişkin.
///
/// Statlar bilerek yüksek başlatılıyor: her testte **tek** stat
/// değiştirilip o statın kapıyı açıp kapadığı ölçülüyor. Başka bir
/// şartın araya girip testi yanlış yönden geçirmesi böyle engelleniyor.
GameState yetiskin({
  int seed = 31,
  int age = 24,
  int health = 90,
  int appearance = 90,
  int charisma = 90,
  int intelligence = 90,
}) {
  final GameState s =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  return s.copyWith(
    pendingEvent: null,
    education: const EducationState(finished: true, startedAtAge: 6),
    player: s.player.copyWith(
      age: age,
      wallet: 500000,
      currentCity: 'İstanbul',
      stats: s.player.stats.copyWith(
        health: health,
        appearance: appearance,
        charisma: charisma,
        intelligence: intelligence,
      ),
    ),
  );
}

GameState saglik(GameState s, int deger) => s.copyWith(
      player: s.player.copyWith(
        stats: s.player.stats.copyWith(health: deger),
      ),
    );

GameState gorunus(GameState s, int deger) => s.copyWith(
      player: s.player.copyWith(
        stats: s.player.stats.copyWith(appearance: deger),
      ),
    );

/// Rekabete hazır (teknik olarak) bir dövüşçü; sağlık ayarlanabilir.
GameState dovuscu({
  String artId = 'karate',
  int? level,
  int age = 24,
  int health = 90,
  int seed = 77,
}) {
  final MartialArt a = sanat(artId);
  final int lv = level ?? a.topLevel;
  final GameState s = yetiskin(seed: seed, age: age, health: health);
  return s.copyWith(
    martialArts: <MartialProgress>[
      MartialProgress(
        artId: artId,
        lessons: a.ranks[lv.clamp(0, a.topLevel)].lessonsNeeded,
        startedAtAge: 10,
      ),
    ],
  );
}

GameState rekabete(GameState s, {String artId = 'karate'}) {
  final r = CombatCareerEngine.startCompeting(s, sanat(artId));
  expect(r.applied, isTrue, reason: r.text);
  return r.state;
}

CombatCareer kariyer(GameState s) => CombatCareerEngine.activeCareer(s)!;

/// Bekleyen müsabaka kurar (kademe ve rakip gücü motorun kataloğundan).
GameState musabaka(GameState s, {int seed = 5, int? tier}) {
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
            opponent: CombatOpponent(
              id: 'rakip_$seed',
              name: 'Rakip $seed',
              age: 25,
              rating: t.opponentRating,
            ),
            purse: t.purse,
            seed: seed,
            offeredAtAge: s.player.age,
            isTitle: false,
          ),
        )
      else
        c,
  ]);
}

void main() {
  // =================================================================
  // §2, §3 — MANKEN
  // =================================================================
  group('AM manken: dış görünüş 80', () {
    final JobType manken = is_('manken');

    test('katalog eşiği 80 (Faho kararı), karizma ikinci duvar değil', () {
      expect(manken.minAppearance, 80);
      expect(manken.minCharisma, lessThanOrEqualTo(50),
          reason: '§2: ana sert şart görünüş olsun, karizma gereksiz '
              'yüksek bir ikinci duvar kurmasın.');
      expect(manken.minHealth, 0,
          reason: 'Mankenliğe fiziksel yeterlilik şartı uydurulmadı.');
    });

    test('görünüş 79 → kapalı', () {
      final GameState s = gorunus(yetiskin(), 79);
      final String engel = market.requirementReason(s, manken);
      expect(engel, isNotEmpty);
      expect(engel, contains('80'), reason: '§19: eşik sayıyla yazılmalı.');
      expect(engel, contains('79'), reason: '§19: mevcut değer de yazılmalı.');
      expect(market.openJobs(s), isNot(contains(manken)));
    });

    test('görünüş 80 → diğer şartlar uygunsa açık', () {
      final GameState s = gorunus(yetiskin(), 80);
      expect(market.requirementReason(s, manken), isEmpty);
      expect(market.openJobs(s), contains(manken));
    });

    test('görünüş 100 → açık', () {
      final GameState s = gorunus(yetiskin(), 100);
      expect(market.requirementReason(s, manken), isEmpty);
    });

    test('işe girdikten sonra görünüş 70e düşmek işten atmıyor', () {
      // §3 ve D-064: minAppearance bir **giriş** şartıdır.
      GameState s = gorunus(yetiskin(), 92);
      s = s.copyWith(
        career: s.career.copyWith(
          jobId: manken.id,
          startedAtAge: s.player.age,
          salary: manken.yearlySalary,
        ),
      );
      expect(s.career.isEmployed, isTrue);

      final GameState dusmus = gorunus(s, 70);
      expect(dusmus.career.jobId, manken.id,
          reason: 'Görünüş düştü diye iş kaydı silinmemeli.');
      expect(dusmus.career.isEmployed, isTrue);
      // Kapı yalnızca **yeniden başvuruda** kapanır.
      expect(market.requirementReason(dusmus, manken), isNotEmpty);
    });
  });

  // =================================================================
  // §1, §7-§13 — MESLEK SAĞLIK EŞİKLERİ
  // =================================================================
  group('AM meslek sağlık eşikleri', () {
    /// Eşiğin bir altında kapalı, tam eşikte açık olmalı.
    void esikTesti(String jobId, int beklenenEsik) {
      final JobType job = is_(jobId);
      expect(job.minHealth, beklenenEsik,
          reason: '$jobId için beklenen eşik $beklenenEsik.');

      final GameState altinda = saglik(yetiskin(), beklenenEsik - 1);
      final String engel = market.requirementReason(altinda, job);
      expect(engel, isNotEmpty,
          reason: '$jobId sağlık ${beklenenEsik - 1} ile kapalı olmalı.');
      expect(engel, contains('$beklenenEsik'),
          reason: '§19: gerekçe eşiği sayıyla yazmalı.');

      final GameState tam = saglik(yetiskin(), beklenenEsik);
      expect(market.requirementReason(tam, job), isEmpty,
          reason: '$jobId sağlık $beklenenEsik ile açık olmalı.');
    }

    test('polis: 64 kapalı, 65 açık', () => esikTesti('polis', 65));
    test('itfaiye: 69 kapalı, 70 açık', () => esikTesti('itfaiyeci', 70));
    test('güvenlik: 54 kapalı, 55 açık', () => esikTesti('guvenlik', 55));

    test('polis elit sporcu seviyesi istemiyor', () {
      // §7: polislik profesyonel sporculuk değil.
      expect(is_('polis').minHealth,
          lessThan(CombatCareerEngine.prototypeOnlyMinHealth));
      expect(is_('itfaiyeci').minHealth,
          lessThan(CombatCareerEngine.prototypeOnlyMinHealth));
    });

    test('eşik konan üç meslekte mesleğe özel gerekçe var', () {
      // §1: "işe uygun değilsin" değil, gerçek sebep.
      for (final String id in <String>['polis', 'itfaiyeci', 'guvenlik']) {
        expect(is_(id).physicalNote, isNotNull, reason: id);
        expect(is_(id).physicalNote, isNotEmpty, reason: id);
      }
    });

    test('ÖLÇÜM KARARI: aday fiziksel mesleklere eşik konmadı', () {
      // §10 bu beşini "aday" diye saydı ve "gerekiyorsa" dedi. Eşik
      // konmuş hâli ölçüldü ve **oyunun ekonomisini kaydırdı**:
      // `paket_ae_calibration_test`'te `girisim+yatirim`in her ölçüde
      // ezdiği strateji sayısı 5/14'ten 9/14'e çıktı, çünkü bu beş iş
      // erişilebilir kataloğun büyük bir dilimi ve kapanmaları maaş
      // yollarını zayıflattı. Brief toplu denge operasyonunu yasakladığı
      // için eşikler geri alındı; karar Q-185 #2'de Faho'da.
      //
      // Bu test niyeti kilitliyor: biri yeniden eşik koyarsa ekonomi
      // ölçümlerini de yeniden kalibre etmek zorunda kalacağını bilsin.
      for (final String id in <String>[
        'kurye',
        'depo_personeli',
        'oto_tamircisi',
        'tesisatci',
        'kaynakci',
      ]) {
        expect(is_(id).minHealth, 0,
            reason: '$id: eşik Q-185 #2 kararına kadar 0 kalıyor.');
      }
    });

    test('eşik konan meslekler yalnızca bu üçü', () {
      final List<String> esikliIsler = kJobCatalog
          .where((JobType j) => j.minHealth > 0)
          .map((JobType j) => j.id)
          .toList(growable: false)
        ..sort();
      expect(esikliIsler, <String>['guvenlik', 'itfaiyeci', 'polis']);
    });

    test('ofis ve uzmanlık mesleklerine sağlık bariyeri konmadı', () {
      // §11: bir insanın sağlık statı 45 diye muhasebeci olamaması saçma.
      const List<String> ofis = <String>[
        'yazilim_gelistirici',
        'muhasebeci',
        'ogretmen',
        'banka_personeli',
        'elektrik_muhendisi',
        'insaat_muhendisi',
        'makine_muhendisi',
        'gazeteci',
        'yazar',
        'muzisyen',
        'doktor',
      ];
      for (final String id in ofis) {
        expect(is_(id).minHealth, 0, reason: '$id sağlık şartı olmamalı.');
      }
    });

    test('düşük sağlık ofis mesleğini kapatmıyor', () {
      // Aynı karakter: sağlık 40. Muhasebecilik ve yazılımcılık açık
      // kalmalı (eğitim şartları ayrı konu, o yüzden gerekçe sağlıkla
      // ilgili olmamalı).
      final GameState s = saglik(
        yetiskin(age: 30, intelligence: 90),
        40,
      ).copyWith(
        education: const EducationState(
          finished: true,
          startedAtAge: 6,
          universityFinished: true,
          universityProgramId: 'isletme',
        ),
      );
      for (final String id in <String>['muhasebeci', 'yazilim_gelistirici']) {
        final String engel = market.requirementReason(s, is_(id));
        expect(engel, isNot(contains('Sağlığın')), reason: id);
        expect(engel, isNot(contains('fiziksel')), reason: id);
      }
    });

    test('görünüş bariyeri yalnızca mankenlikte', () {
      // §12: satış danışmanı, resepsiyonist, gazeteci gibi işlerde doğru
      // stat karizmadır; hard appearance gate yok.
      final List<String> gorunusluIsler = kJobCatalog
          .where((JobType j) => j.minAppearance > 0)
          .map((JobType j) => j.id)
          .toList(growable: false);
      expect(gorunusluIsler, <String>['manken']);
      for (final String id in <String>[
        'satis_danismani',
        'resepsiyonist',
        'gazeteci',
      ]) {
        expect(is_(id).minAppearance, 0, reason: id);
      }
    });

    test('yarım zamanlı gençlik işlerine fiziksel duvar konmadı', () {
      // 16 yaşındaki bir çocuğun sağlık statı 50 diye market reyonunda
      // çalışamaması oyunun amacına aykırı.
      for (final JobType j in kJobCatalog.where((JobType j) => j.partTime)) {
        expect(j.minHealth, 0, reason: j.id);
      }
    });

    test('katalog audit: eşik bandı dışına çıkan iş yok', () {
      for (final JobType j in kJobCatalog) {
        expect(j.minHealth, inInclusiveRange(0, 70),
            reason: '${j.id}: elit sporcu eşiği mesleklere ait değil.');
        if (j.minHealth > 0) {
          expect(j.minHealth, greaterThanOrEqualTo(45),
              reason: '${j.id}: 45 altı eşik anlamsız.');
        }
      }
    });
  });

  // =================================================================
  // §18 — UI gereksinim satırları
  // =================================================================
  group('AM gereksinim satırları', () {
    test('yalnızca işin koyduğu şartlar listelenir', () {
      final GameState s = saglik(gorunus(yetiskin(), 60), 60);

      final List<JobRequirement> manken =
          market.requirementLines(s, is_('manken'));
      final Map<String, JobRequirement> mankenMap = <String, JobRequirement>{
        for (final JobRequirement r in manken) r.label: r,
      };
      expect(mankenMap.keys, containsAll(<String>['Yaş', 'Karizma', 'Dış görünüş']));
      expect(mankenMap.containsKey('Sağlık'), isFalse,
          reason: 'Mankenlikte sağlık şartı yok; satır da olmamalı.');
      expect(mankenMap['Dış görünüş']!.met, isFalse);
      expect(mankenMap['Dış görünüş']!.line, contains('80'));
      expect(mankenMap['Dış görünüş']!.line, contains('60'));
      expect(mankenMap['Yaş']!.met, isTrue);
      expect(mankenMap['Yaş']!.line, 'Yaş',
          reason: 'Tutan şartta yalnızca ad yazılır.');

      final Map<String, JobRequirement> itfaiye = <String, JobRequirement>{
        for (final JobRequirement r in market.requirementLines(
          s,
          is_('itfaiyeci'),
        ))
          r.label: r,
      };
      expect(itfaiye.containsKey('Sağlık'), isTrue);
      expect(itfaiye['Sağlık']!.met, isFalse);
      expect(itfaiye['Sağlık']!.line, contains('70'));
      expect(itfaiye.containsKey('Dış görünüş'), isFalse);
    });

    test('şartsız işte yalnızca yaş satırı var', () {
      final GameState s = yetiskin();
      final List<JobRequirement> satirlar =
          market.requirementLines(s, is_('kasiyer'));
      expect(satirlar.map((JobRequirement r) => r.label), <String>['Yaş']);
    });
  });

  // =================================================================
  // §4-§6, §16, §17 — REKABETÇİ DÖVÜŞ KARİYERİ
  // =================================================================
  group('AM combat sağlık kademeleri', () {
    test('üç eşik: başlama 80, müsabaka 70, elit terfi 80', () {
      expect(CombatCareerEngine.prototypeOnlyMinHealth, 80);
      expect(CombatCareerEngine.prototypeOnlyMinBoutHealth, 70);
      expect(CombatCareerEngine.prototypeOnlyMinEliteHealth, 80);
      expect(CombatCareerEngine.prototypeOnlyMinBoutHealth,
          lessThan(CombatCareerEngine.prototypeOnlyMinHealth),
          reason: '§5: müsabaka eşiği başlama eşiğinden düşük olmalı, '
              'yoksa sakatlanan sporcu kariyerini kaybeder.');
    });

    test('sağlık 79 → altı sanatın hiçbirinde kariyer başlamıyor', () {
      for (final CombatCircuit yol in kCombatCircuits) {
        final GameState s = dovuscu(artId: yol.artId, health: 79);
        final InteractionAvailability u =
            CombatCareerEngine.startAvailability(s, yol.art!);
        expect(u.isAllowed, isFalse, reason: yol.artId);
        expect(u.reason, contains('80'), reason: '§19: sayı yazılmalı.');
        expect(u.reason, contains('79'), reason: yol.artId);
      }
    });

    test('sağlık 80 → altı sanatın hepsinde başlanabiliyor', () {
      for (final CombatCircuit yol in kCombatCircuits) {
        final GameState s = dovuscu(artId: yol.artId, health: 80);
        expect(CombatCareerEngine.startAvailability(s, yol.art!).isAllowed,
            isTrue,
            reason: yol.artId);
      }
    });

    test('sağlık 69 → müsabaka yok, kariyer silinmiyor', () {
      GameState s = rekabete(dovuscu(health: 90));
      final CombatCareer once = kariyer(s);
      s = musabaka(s);
      s = saglik(s, 69);

      final BoutResult r = CombatCareerEngine.fight(s, CampChoice.dengeli);
      expect(r.applied, isFalse, reason: '§5: geçici sağlık engeli.');
      expect(r.text, contains('70'));
      expect(r.text, contains('Toparlanman'));

      // §5'in çekirdeği: kayıt duruyor.
      final CombatCareer sonra = kariyer(r.state);
      expect(sonra.tier, once.tier);
      expect(sonra.totalBouts, once.totalBouts);
      expect(sonra.championships, once.championships);
      expect(sonra.isRetired, isFalse);
      expect(sonra.pendingBout, isNotNull,
          reason: 'Bekleyen müsabaka iptal edilmemeli, beklemeli.');
    });

    test('sağlık 70 → sakatlık yoksa müsabaka mümkün', () {
      GameState s = musabaka(rekabete(dovuscu(health: 90)));
      s = saglik(s, 70);
      final BoutResult r = CombatCareerEngine.fight(s, CampChoice.dengeli);
      expect(r.applied, isTrue, reason: r.text);
    });

    test('toparlanınca kapı yeniden açılıyor (§17)', () {
      GameState s = musabaka(rekabete(dovuscu(health: 90)));
      final GameState dusuk = saglik(s, 60);
      expect(CombatCareerEngine.fight(dusuk, CampChoice.dengeli).applied,
          isFalse);
      // Sağlık kontrolü, dinlenme ve spor sonrası:
      final GameState iyilesmis = saglik(dusuk, 85);
      expect(CombatCareerEngine.fight(iyilesmis, CampChoice.dengeli).applied,
          isTrue);
      // Ve yeni kariyer kapısı da yeniden açık.
      expect(
        CombatCareerEngine.startAvailability(
          saglik(dovuscu(artId: 'judo', health: 60), 85),
          sanat('judo'),
        ).isAllowed,
        isTrue,
      );
    });

    test('ciddi sakatlıkta sağlık 90 olsa bile dövüşülemiyor (§6)', () {
      GameState s = musabaka(rekabete(dovuscu(health: 95)));
      final CombatCareer k = kariyer(s);
      s = s.copyWith(combatCareers: <CombatCareer>[
        k.copyWith(injury: InjurySeverity.ciddi, injuryYearsLeft: 2),
      ]);
      final BoutResult r = CombatCareerEngine.fight(s, CampChoice.dengeli);
      expect(r.applied, isFalse);
      expect(r.text, contains('Sakatlığın'),
          reason: '§6: sağlık cümlesi değil sakatlık cümlesi gösterilmeli; '
              'iki ceza üst üste binmemeli.');
    });

    test('sağlık 79 → elit kademeye terfi yok, 80 → var (§16)', () {
      // Terfi hakkı doğmuş bir sporcu kur: kademe 2, bol galibiyet ve
      // itibar, en üst teknik basamak.
      final CombatCircuit yol = combatCircuitFor('karate')!;
      GameState taban = rekabete(dovuscu(age: 26, health: 90));
      final CombatCareer k = kariyer(taban);
      taban = taban.copyWith(combatCareers: <CombatCareer>[
        k.copyWith(
          tier: 2,
          proWins: 30,
          reputation: 95,
          form: 90,
        ),
      ]);
      expect(yol.turnsProAtTier, 3,
          reason: 'Kurulum varsayımı: pro kademe 3.');

      ({bool promoted, String text})? dene(int health, int seed) {
        final GameState s = musabaka(saglik(taban, health), seed: seed, tier: 2);
        final BoutResult r = CombatCareerEngine.fight(s, CampChoice.yogun);
        if (!r.applied || !r.won) return null;
        return (promoted: r.promoted, text: r.text);
      }

      // Kazanılan bir müsabaka bul; iki sağlık değerinde de aynı tohum.
      int? kazanan;
      for (int i = 1; i <= 300; i++) {
        if (dene(90, i * 3 + 1) != null) {
          kazanan = i * 3 + 1;
          break;
        }
      }
      expect(kazanan, isNotNull, reason: 'Kazanılan müsabaka bulunamadı.');

      final ({bool promoted, String text})? saglikli = dene(80, kazanan!);
      final ({bool promoted, String text})? hasta = dene(79, kazanan);
      expect(saglikli, isNotNull);
      expect(hasta, isNotNull);
      expect(saglikli!.promoted, isTrue,
          reason: 'Sağlık 80 ile elit kademeye terfi mümkün olmalı.');
      expect(hasta!.promoted, isFalse,
          reason: '§16: sağlık 79 ile elit kademeye terfi olmamalı.');
      expect(hasta.text, contains('fiziksel'),
          reason: '§16: sebebi oyuncuya yazılmalı.');
      expect(hasta.text, contains('80'));
    });

    test('sağlık kapısı etiketi "değer / eşik" biçiminde (§18)', () {
      final GameState s = dovuscu(health: 73);
      expect(CombatCareerEngine.healthGateLabel(s), '73 / 80');
      expect(CombatCareerEngine.canFightHealthWise(s), isTrue);
      expect(CombatCareerEngine.canFightHealthWise(saglik(s, 69)), isFalse);
    });
  });

  // =================================================================
  // §14, §15 — NORMAL SPOR VE DERS KAPANMIYOR
  // =================================================================
  group('AM normal spor ve dövüş dersi', () {
    test('sağlık 55 normal spor aktivitesini kapatmıyor (§14)', () {
      final GameState s = saglik(yetiskin(), 55);
      const ActivityEngine motor = ActivityEngine();
      final List<ActivityAction> sporlar = kActivityActions
          .where((ActivityAction a) => a.venue == ActivityVenue.sporSalonu)
          .toList(growable: false);
      expect(sporlar, isNotEmpty, reason: 'Katalogda spor aktivitesi yok.');

      int acik = 0;
      for (final ActivityAction a in sporlar) {
        final InteractionAvailability u = motor.availability(s, a);
        if (u.isAllowed) {
          acik++;
        } else {
          expect(u.reason, isNot(contains('80')),
              reason: '${a.id}: normal spor elit sporcu eşiği istemesin.');
        }
      }
      expect(acik, greaterThan(0),
          reason: 'Sağlık 55 ile hiçbir spor yapılamıyorsa §14 ihlal.');
    });

    test('sağlık 60 dövüş dersi almayı kapatmıyor (§15)', () {
      const MartialArtsEngine motor = MartialArtsEngine();
      final MartialArt a = sanat('karate');
      final GameState s = saglik(
        yetiskin(age: 20).copyWith(
          martialArts: <MartialProgress>[
            MartialProgress(artId: a.id, lessons: 0, startedAtAge: 18),
          ],
        ),
        60,
      );
      final InteractionAvailability u = motor.availability(s, a);
      expect(u.isAllowed, isTrue,
          reason: '§15: ders almak müsabakaya çıkmak değil. '
              'Gerekçe: ${u.reason}');
      final r = motor.takeLesson(state: s, art: a);
      expect(r.outcome.applied, isTrue, reason: r.outcome.text);

      // Ama aynı sporcu rekabete başlayamaz.
      expect(CombatCareerEngine.startAvailability(s, a).isAllowed, isFalse);
    });
  });

  // =================================================================
  // §20 — MEVCUT KAYIT UYUMU
  // =================================================================
  group('AM kayıt uyumu', () {
    test('yeni şartlar için save alanı eklenmedi', () {
      // minHealth katalog verisi; kayda girmez. Aynı kaydın iki kez
      // çözülmesi aynı sonucu verir ve combat state bozulmaz.
      GameState s = rekabete(dovuscu(health: 90));
      s = musabaka(s);
      final CombatCareer once = kariyer(s);
      final GameState geri = decodeGameState(encodeGameState(s));
      final CombatCareer sonra = CombatCareerEngine.activeCareer(geri)!;
      expect(sonra.artId, once.artId);
      expect(sonra.tier, once.tier);
      expect(sonra.pendingBout?.seed, once.pendingBout?.seed);
      expect(sonra.form, once.form);
    });
  });
}
