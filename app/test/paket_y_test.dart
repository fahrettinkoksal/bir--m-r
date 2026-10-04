import 'dart:math';

import 'package:bir_omur/data/chronic_catalog.dart';
import 'package:bir_omur/data/health_crisis_catalog.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/data/job_catalog.dart';
import 'package:bir_omur/domain/generation/life_progression.dart';
import 'package:bir_omur/data/life_goal_catalog.dart';
import 'package:bir_omur/domain/career/craft_mastery.dart';
import 'package:bir_omur/domain/life/life_goals.dart';
import 'package:bir_omur/domain/generation/spouse_life.dart';
import 'package:bir_omur/domain/models/career.dart';
import 'package:bir_omur/domain/life/chronic_engine.dart';
import 'package:bir_omur/domain/life/health_crisis_engine.dart';
import 'package:bir_omur/domain/life/health_report.dart';
import 'package:bir_omur/domain/models/chronic_condition.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/health_history.dart';
import 'package:bir_omur/domain/models/life_log.dart';
import 'package:bir_omur/domain/models/marriage.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/person_development.dart';
import 'package:bir_omur/domain/models/stats.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:bir_omur/domain/models/pending_crisis.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:flutter_test/flutter_test.dart';

/// Paket Y — B grubu: kronik durumlar ve sağlık geçmişi (D-153).
void main() {
  GameState hayat({int seed = 8, int age = 50, int wallet = 900000}) {
    final GameState base =
        LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
    return base.copyWith(
      pendingEvent: null,
      notices: const <PendingNotice>[],
      player: base.player.copyWith(age: age, wallet: wallet),
      movedOut: true,
    );
  }

  GameState kronikli(
    GameState s,
    String typeId, {
    int? startedAtAge,
    int? lastCaredAtAge,
  }) =>
      s.copyWith(
        chronicConditions: <ChronicCondition>[
          ...s.chronicConditions,
          ChronicCondition(
            typeId: typeId,
            startedAtAge: startedAtAge ?? s.player.age - 5,
            lastCaredAtAge: lastCaredAtAge,
          ),
        ],
      );

  group('Katalog (D-153)', () {
    test('kronik kimlikleri benzersiz, sayılar tutarlı', () {
      final List<String> kimlikler =
          kChronicConditions.map((ChronicConditionType t) => t.id).toList();
      expect(kimlikler.toSet(), hasLength(kimlikler.length));
      for (final ChronicConditionType t in kChronicConditions) {
        expect(t.label, isNotEmpty);
        expect(t.description, isNotEmpty);
        expect(t.yearlyHealthDrain, greaterThan(0), reason: t.id);
        // Takip **yönetir**, ortadan kaldırmaz: yönetilen düşüş
        // yönetilmeyenden küçük olmalı ama mutlaka olmalı değil.
        expect(t.managedDrain, lessThan(t.yearlyHealthDrain), reason: t.id);
        expect(t.managedDrain, greaterThanOrEqualTo(0), reason: t.id);
        expect(t.yearlyCareCost, greaterThan(0), reason: t.id);
        expect(t.crisisRiskFactor, greaterThanOrEqualTo(1.0), reason: t.id);
      }
    });

    test('kriz sonrası durumlar gerçek bir krize bağlı', () {
      for (final ChronicConditionType t in kChronicConditions) {
        if (t.origin == ChronicOrigin.krizSonrasi) {
          expect(t.afterCrisisIds, isNotEmpty, reason: t.id);
          for (final String id in t.afterCrisisIds) {
            expect(
              kHealthCrises.any((HealthCrisis c) => c.id == id),
              isTrue,
              reason: '${t.id} olmayan bir krize ($id) bağlanmış',
            );
          }
        } else {
          // Yaşla gelen durumun yaş eşiği olmalı; sıfırdan başlayan
          // "yaşla gelen" durum yanlış olurdu.
          expect(t.onsetMinAge, greaterThan(0), reason: t.id);
        }
      }
    });
  });

  group('Yıllık etki', () {
    test('takip edilmeyen durum her yıl sağlıktan düşürür', () {
      final GameState s = kronikli(hayat(), 'tansiyon');
      final int dusus = ChronicEngine.yearlyDrain(s, s.player.age);
      expect(dusus, chronicTypeById('tansiyon')!.yearlyHealthDrain);
    });

    test('takip edilen durum daha az düşürür', () {
      final GameState s = hayat();
      final GameState takipli =
          kronikli(s, 'kalp_takibi', lastCaredAtAge: s.player.age);
      final GameState takipsiz = kronikli(s, 'kalp_takibi');
      expect(
        ChronicEngine.yearlyDrain(takipli, s.player.age),
        lessThan(ChronicEngine.yearlyDrain(takipsiz, s.player.age)),
      );
    });

    test('yıl ilerleyince sağlık gerçekten düşer', () {
      final GameState s = kronikli(
        hayat().copyWith(
          player: hayat().player.copyWith(age: 50),
        ),
        'kan_sekeri',
      );
      final int once = s.player.stats.health;
      final GameState sonra = ChronicEngine.advanceYear(
        state: s,
        newAge: 51,
        rng: Random(3),
      );
      expect(sonra.player.stats.health, lessThan(once));
    });

    test('geçmiş (bitmiş) durum artık sağlıktan düşürmez', () {
      GameState s = kronikli(hayat(), 'tansiyon');
      s = s.copyWith(
        chronicConditions: s.chronicConditions
            .map((ChronicCondition c) => c.copyWith(endedAtAge: 49))
            .toList(growable: false),
      );
      expect(ChronicEngine.yearlyDrain(s, 50), 0);
      expect(s.activeChronic, isEmpty);
      expect(s.chronicConditions, hasLength(1), reason: 'Kayıt silinmez');
    });

    test('kriz riski yükselir ama tavanı var', () {
      expect(ChronicEngine.crisisRiskFactor(hayat()), 1.0);
      GameState s = kronikli(hayat(), 'kalp_takibi');
      expect(ChronicEngine.crisisRiskFactor(s), greaterThan(1.0));
      s = kronikli(s, 'tansiyon');
      s = kronikli(s, 'kan_sekeri');
      expect(ChronicEngine.crisisRiskFactor(s), lessThanOrEqualTo(2.5));
    });
  });

  group('Takip (bakım)', () {
    test('takip bedeli düşer ve kayıt güncellenir', () {
      final GameState s = kronikli(hayat(), 'kalp_takibi');
      final int once = s.player.wallet;
      final ChronicCareResult r =
          ChronicEngine.care(state: s, typeId: 'kalp_takibi');
      expect(r.outcome.applied, isTrue);
      expect(
        r.state.player.wallet,
        once - chronicTypeById('kalp_takibi')!.yearlyCareCost,
      );
      final ChronicCondition c = r.state.chronicConditions.single;
      expect(c.lastCaredAtAge, s.player.age);
      expect(c.careYears, 1);
      expect(r.state.log.last.text, contains('takibini yaptın'));
    });

    test('aynı yıl ikinci takip yapılamaz', () {
      final GameState s = kronikli(hayat(), 'kalp_takibi');
      final ChronicCareResult ilk =
          ChronicEngine.care(state: s, typeId: 'kalp_takibi');
      final ChronicCareResult ikinci =
          ChronicEngine.care(state: ilk.state, typeId: 'kalp_takibi');
      expect(ikinci.outcome.applied, isFalse);
      expect(ikinci.outcome.text, contains('zaten'));
      expect(ikinci.state.player.wallet, ilk.state.player.wallet);
    });

    test('parası yetmeyen takip edemez ve cüzdan bozulmaz', () {
      final GameState s =
          kronikli(hayat(wallet: 100), 'kalp_takibi');
      final ChronicCareResult r =
          ChronicEngine.care(state: s, typeId: 'kalp_takibi');
      expect(r.outcome.applied, isFalse);
      expect(r.state.player.wallet, 100);
    });

    test('olmayan durumun takibi istenirse hiçbir şey değişmez', () {
      final GameState s = hayat();
      final ChronicCareResult r =
          ChronicEngine.care(state: s, typeId: 'tansiyon');
      expect(r.outcome.applied, isFalse);
      expect(r.state.player.wallet, s.player.wallet);
    });

    test('engel gerekçesi boş metinle bildirilir, null dönmez', () {
      final GameState s = kronikli(hayat(), 'tansiyon');
      final ChronicCondition c = s.chronicConditions.single;
      expect(ChronicEngine.careBlockReason(s, c), isEmpty);
    });
  });

  group('Kriz sonrası iz', () {
    test('atlatılan kriz sağlık geçmişine yazılır', () {
      GameState s = hayat(age: 55);
      s = s.copyWith(
        pendingCrisis: const PendingCrisis(crisisId: 'kalp_uyarisi', age: 55),
      );
      final CrisisResult r = const HealthCrisisEngine()
          .respond(s, 'tedavi', Random(1));
      if (!r.outcome.survived) return; // Atlatamadıysa bu test konusu değil.
      expect(r.state.healthHistory, hasLength(1));
      final HealthHistoryEntry k = r.state.healthHistory.single;
      expect(k.crisisId, 'kalp_uyarisi');
      expect(k.age, 55);
      expect(k.choiceId, 'tedavi');
    });

    test('kalp uyarısı bazen kalıcı bir durum bırakır, bıraktığı doğru tür',
        () {
      int izli = 0;
      int izsiz = 0;
      for (int seed = 0; seed < 300; seed++) {
        GameState s = hayat(age: 55);
        s = s.copyWith(
          pendingCrisis: const PendingCrisis(crisisId: 'kalp_uyarisi', age: 55),
        );
        final CrisisResult r = const HealthCrisisEngine()
            .respond(s, 'tedavi', Random(seed));
        if (!r.outcome.survived) continue;
        if (r.state.activeChronic.isEmpty) {
          izsiz++;
        } else {
          izli++;
          // Kalp uyarısından yalnızca kalp takibi kalabilir.
          expect(r.state.activeChronic.single.typeId, 'kalp_takibi');
          expect(r.state.healthHistory.single.chronicTypeId, 'kalp_takibi');
        }
      }
      expect(izli, greaterThan(0), reason: 'Hiç iz kalmadıysa bağlantı kopuk');
      expect(izsiz, greaterThan(0), reason: 'Her kriz iz bırakmamalı');
    });

    test('aynı durum ikinci kez eklenmez', () {
      GameState s = kronikli(hayat(age: 55), 'kalp_takibi');
      final ({GameState state, String? typeId}) r = ChronicEngine.afterCrisis(
        state: s,
        crisisId: 'kalp_uyarisi',
        age: 55,
        rng: Random(1),
      );
      expect(r.typeId, isNull);
      expect(r.state.chronicConditions, hasLength(1));
    });

    test('en fazla üç süren durum taşınır', () {
      GameState s = hayat(age: 60);
      s = kronikli(s, 'tansiyon');
      s = kronikli(s, 'kan_sekeri');
      s = kronikli(s, 'solunum');
      expect(s.activeChronic, hasLength(ChronicEngine.prototypeOnlyMaxActive));
      final ({GameState state, String? typeId}) r = ChronicEngine.afterCrisis(
        state: s,
        crisisId: 'dusme',
        age: 60,
        rng: Random(1),
      );
      expect(r.typeId, isNull, reason: 'Sınır aşılmamalı');
    });
  });

  group('Yaşla gelen durum', () {
    test('ileri yaşta ortaya çıkıyor, bildirim ve günlük yazılıyor', () {
      int cikan = 0;
      for (int seed = 0; seed < 600 && cikan == 0; seed++) {
        final GameState s = hayat(age: 49);
        final GameState sonra = ChronicEngine.advanceYear(
          state: s,
          newAge: 50,
          rng: Random(seed),
        );
        if (sonra.chronicConditions.isEmpty) continue;
        cikan++;
        final ChronicCondition c = sonra.chronicConditions.single;
        expect(chronicTypeById(c.typeId)!.origin, ChronicOrigin.yasla);
        expect(c.startedAtAge, 50);
        expect(
          sonra.notices.any((PendingNotice n) => n.id.startsWith('kronik-')),
          isTrue,
        );
        expect(sonra.log.last.text, contains('kaydına girdi'));
      }
      expect(cikan, 1, reason: '600 denemede hiç çıkmadıysa bağlantı kopuk');
    });

    test('yaş eşiğinin altında yaşla gelen durum çıkmaz', () {
      for (int seed = 0; seed < 200; seed++) {
        final GameState s = hayat(age: 20);
        final GameState sonra = ChronicEngine.advanceYear(
          state: s,
          newAge: 21,
          rng: Random(seed),
        );
        expect(sonra.chronicConditions, isEmpty);
      }
    });
  });

  group('Kayıt', () {
    test('kronik durum ve sağlık geçmişi kaydedilip geri okunur', () {
      GameState s = kronikli(hayat(), 'kalp_takibi', lastCaredAtAge: 49);
      s = s.copyWith(
        healthHistory: const <HealthHistoryEntry>[
          HealthHistoryEntry(
            crisisId: 'kalp_uyarisi',
            age: 48,
            choiceId: 'tedavi',
            chronicTypeId: 'kalp_takibi',
          ),
        ],
      );
      final GameState geri = decodeGameState(encodeGameState(s));
      expect(geri.chronicConditions, hasLength(1));
      expect(geri.chronicConditions.single.typeId, 'kalp_takibi');
      expect(geri.chronicConditions.single.lastCaredAtAge, 49);
      expect(geri.healthHistory, hasLength(1));
      expect(geri.healthHistory.single.chronicTypeId, 'kalp_takibi');
    });

    test('eski kayıtta bu alanlar yoksa boş okunur, kayıt bozulmaz', () {
      final Map<String, Object?> json = encodeGameState(hayat());
      json.remove('chronicConditions');
      json.remove('healthHistory');
      final GameState geri = decodeGameState(json);
      expect(geri.chronicConditions, isEmpty);
      expect(geri.healthHistory, isEmpty);
    });
  });

  group('Yıl akışına bağlı', () {
    test('bir ömür boyunca kronik durum gerçekten yaşanıyor', () {
      int kronikGoren = 0;
      for (int seed = 0; seed < 40; seed++) {
        GameState s = hayat(seed: seed, age: 30);
        final LifeProgression motor = LifeProgression(Random(seed + 500));
        for (int i = 0; i < 50 && !s.deceased; i++) {
          s = motor.advanceOneYear(s);
          s = s.copyWith(
            pendingEvent: null,
            pendingCrisis: null,
            notices: const <PendingNotice>[],
          );
        }
        if (s.chronicConditions.isNotEmpty) kronikGoren++;
      }
      expect(
        kronikGoren,
        greaterThan(0),
        reason: '40 hayatta hiç kronik durum çıkmadıysa bağlantı kopuk',
      );
    });
  });

  group('Check-up raporu kronik durumu görüyor', () {
    test('her kronik durumun rapor satırı gerçekten raporda var', () {
      final Set<String> satirlar = HealthChecks.checkup(hayat())
          .lines
          .map((HealthLine l) => l.system)
          .toSet();
      for (final ChronicConditionType t in kChronicConditions) {
        expect(
          satirlar,
          contains(t.reportSystem),
          reason: '${t.id} olmayan bir rapor satırına bağlanmış',
        );
      }
    });

    test('taşınan durum ilgili satırı aşağı çeker', () {
      final GameState saglikli = hayat(age: 45).copyWith(
        player: hayat(age: 45).player.copyWith(
              stats: hayat().player.stats.gain(health: 100),
            ),
      );
      final GameState kalpli = kronikli(saglikli, 'kalp_takibi');

      OrganStatus durum(GameState s, String sistem) => HealthChecks.checkup(s)
          .lines
          .firstWhere((HealthLine l) => l.system == sistem)
          .status;

      expect(
        durum(kalpli, 'Kalp ve tansiyon').index,
        greaterThan(durum(saglikli, 'Kalp ve tansiyon').index),
        reason: 'Kalp rahatsızlığı kalp satırını etkilemedi',
      );
      // Alakasız satır etkilenmez.
      expect(
        durum(kalpli, 'Görme'),
        durum(saglikli, 'Görme'),
      );
    });

    test('takip edilen durumun etkisi daha az', () {
      final GameState s = hayat(age: 45);
      final GameState takipsiz = kronikli(s, 'kalp_takibi');
      final GameState takipli =
          kronikli(s, 'kalp_takibi', lastCaredAtAge: s.player.age);
      expect(
        HealthChecks.prototypeOnlyManagedChronicPenalty,
        lessThan(HealthChecks.prototypeOnlyChronicPenalty),
      );
      final int takipsizIndex = HealthChecks.checkup(takipsiz)
          .lines
          .firstWhere((HealthLine l) => l.system == 'Kalp ve tansiyon')
          .status
          .index;
      final int takipliIndex = HealthChecks.checkup(takipli)
          .lines
          .firstWhere((HealthLine l) => l.system == 'Kalp ve tansiyon')
          .status
          .index;
      expect(takipliIndex, lessThanOrEqualTo(takipsizIndex));
    });
  });

  group('Eşin kendi hayatı (D-154)', () {
    Person es({int age = 45, WealthTier? wealth = WealthTier.ortaHalli}) =>
        Person(
          id: 'es-1',
          firstName: 'Eren',
          lastName: 'Yıldız',
          gender: Gender.erkek,
          relation: RelationType.es,
          age: age,
          isAlive: true,
          inPlayerHousehold: true,
          employment: EmploymentStatus.calisiyor,
          wealth: wealth,
          bond: 80,
        );

    GameState evli({int playerAge = 45, int spouseAge = 45}) {
      final GameState base = hayat(age: playerAge);
      final Person e = es(age: spouseAge);
      return base.copyWith(
        people: List<Person>.unmodifiable(<Person>[...base.people, e]),
        marriage: Marriage(
          spouseId: e.id,
          marriedAtAge: playerAge - 10,
          status: MarriageStatus.evli,
        ),
      );
    }

    test('yürüyen evliliğin eşi bulunur, boşanmış eş bulunmaz', () {
      expect(SpouseLife.spouseOf(evli())?.id, 'es-1');
      final GameState bosanmis = evli().copyWith(
        marriage: const Marriage(
          spouseId: 'es-1',
          marriedAtAge: 35,
          status: MarriageStatus.bosandi,
          endedAtAge: 44,
        ),
      );
      // Boşanmış kayıtta kişi hâlâ `es` bağıyla dursa bile ilerletme
      // yalnızca yürüyen evlilik için yapılır; motor tarafı bunu
      // `marriage.isActive` ile ayırır.
      expect(bosanmis.marriage!.isActive, isFalse);
    });

    test('eşin kaydı açılırken serveti sıfırlanmaz', () {
      // Finger'daki "çok varlıklı kişi orta halli göründü" hatasının
      // aynısı burada da olabilirdi: [_sync] ekonomik durumu birikimden
      // yeniden yazıyor.
      final Person zengin = es(wealth: WealthTier.cokVarlikli);
      final SpouseYear yil = SpouseLife.advance(
        spouse: zengin,
        playerAge: 45,
        rng: Random(1),
      );
      expect(yil.person.wealth, WealthTier.cokVarlikli);
    });

    test('çalışan eş yaşı gelince emekli oluyor', () {
      // Gerçekten bir işi olmalı: eski kayıtta mesleği serbest metin
      // olan kişinin iş kimliği yoktur ve "emekli oldu" haberi çıkmaz.
      final JobType is_ = kJobCatalog.first;
      final Person yasli = es(age: 65).copyWith(
        occupation: is_.name,
        development: PersonDevelopment(
          tracksLife: true,
          stats: const Stats(
            appearance: 50,
            happiness: 60,
            health: 60,
            intelligence: 60,
            charisma: 60,
          ),
          finishedSchool: true,
          jobId: is_.id,
          jobStartedAtAge: 30,
        ),
      );
      final SpouseYear yil = SpouseLife.advance(
        spouse: yasli,
        playerAge: 65,
        rng: Random(1),
      );
      expect(yil.person.employment, EmploymentStatus.emekli);
      expect(
        yil.news.any((String h) => h.contains('emekli oldu')),
        isTrue,
      );
      expect(yil.noticeTexts, isNotEmpty, reason: 'Hane haberi bildirime çıkar');
    });

    test('eş bazı yıllarda hastalanıyor ve oyuncu bunu hissediyor', () {
      int hasta = 0;
      for (int seed = 0; seed < 400; seed++) {
        final SpouseYear yil = SpouseLife.advance(
          spouse: es(age: 60),
          playerAge: 60,
          rng: Random(seed),
        );
        if (yil.news.any((String h) => h.contains('hastalandı'))) {
          hasta++;
          expect(yil.playerHappiness, lessThan(0));
          expect(yil.noticeTexts, isNotEmpty);
        }
      }
      expect(hasta, greaterThan(0), reason: 'Hiç hastalanmadıysa bağlantı kopuk');
      expect(hasta, lessThan(200), reason: 'Her yıl hastalanmamalı');
    });

    test('hane haberi ile günlük haberi ayrılıyor', () {
      expect(SpouseLife.isHouseholdNews('Eren emekli oldu.'), isTrue);
      expect(
        SpouseLife.isHouseholdNews('Eren müzik ile ilgilenmeye başladı.'),
        isFalse,
      );
    });
  });

  group('Eşin hastalığı oyuncuya uygulanıyor', () {
    test('yıl akışında eşin hastalığı oyuncunun mutluluğunu düşürüyor', () {
      // Etkinin **gerçekten uygulandığı** aranıyor: metinde kalması
      // yetmez.
      int hastaYil = 0;
      for (int seed = 0; seed < 200 && hastaYil == 0; seed++) {
        final GameState base = hayat(seed: 3, age: 60);
        final Person e = Person(
          id: 'es-1',
          firstName: 'Eren',
          lastName: 'Yıldız',
          gender: Gender.erkek,
          relation: RelationType.es,
          age: 62,
          isAlive: true,
          inPlayerHousehold: true,
          employment: EmploymentStatus.emekli,
          wealth: WealthTier.ortaHalli,
          bond: 80,
        );
        final GameState s = base.copyWith(
          people: List<Person>.unmodifiable(<Person>[...base.people, e]),
          marriage: const Marriage(
            spouseId: 'es-1',
            marriedAtAge: 30,
            status: MarriageStatus.evli,
          ),
        );
        final GameState sonra = LifeProgression(Random(seed)).advanceOneYear(s);
        final bool hasta = sonra.log.any(
          (LifeLogEntry l) => l.text.contains('Eren bir süre hastalandı'),
        );
        if (!hasta) continue;
        hastaYil++;
        expect(
          sonra.notices.any((PendingNotice n) => n.id.startsWith('es-haber-')),
          isTrue,
          reason: 'Eşin hastalığı bildirime çıkmalı',
        );
      }
      expect(hastaYil, 1, reason: '200 yılda hiç hastalanmadıysa bağlantı kopuk');
    });
  });

  group('Aile dönüm noktaları ekrana ulaşıyor (D-154 düzeltmesi)', () {
    // Paket AP §23 bu testin iddiasını daralttı.
    //
    // Testin yakaladığı asıl hata (AC/0) şuydu: çocuğun evliliği kayda
    // geçmediği için **aynı çocuk her yıl yeniden evleniyordu**. O hata
    // hâlâ yakalanmalı.
    //
    // Ama Paket AP'de çocuk gerçekten boşanabiliyor ve dul kalabiliyor;
    // §23 bundan sonra yeniden evlenmeyi açıkça istiyor. Yani "hayatta
    // bir kez düğün" artık yanlış kural. Doğru kural şudur ve test bunu
    // ölçüyor: **evli bir çocuk tekrar evlenemez** ve her ek düğünün
    // karşılığında kapanmış bir evlilik kaydı olmalı.
    test('evli çocuk tekrar evlenmiyor; ek düğünün kapanmış kaydı var', () {
      int evliykenEvlenen = 0;
      int kayitsizDugun = 0;
      int bildirimGelen = 0;
      for (int seed = 0; seed < 25; seed++) {
        GameState s = hayat(seed: seed, age: 55);
        s = s.copyWith(
          people: List<Person>.unmodifiable(<Person>[
            ...s.people,
            Person(
              id: 'cocuk-1',
              firstName: 'Deniz',
              lastName: 'Yıldız',
              gender: Gender.kadin,
              relation: RelationType.cocuk,
              age: 26,
              isAlive: true,
              inPlayerHousehold: false,
              employment: EmploymentStatus.calisiyor,
              wealth: null,
              bond: 70,
            ),
          ]),
        );
        final LifeProgression motor = LifeProgression(Random(seed + 9));
        // **Yalnızca bu çocuğun** düğünleri sayılır. D-158'den sonra
        // kardeşler de evlendiği için "evleniyor" geçen bütün satırları
        // saymak yanlış ölçüm olurdu; aranan şey aynı kişinin ikinci kez
        // evlenmemesi.
        int dugunBildirimi = 0;
        for (int i = 0; i < 12 && !s.deceased; i++) {
          // Yıl başlarken evli miydi? Düğün o yıl gelirse bu "evliyken
          // ikinci kez evlenme" demek olur — AC/0'ın hatası tam buydu.
          final bool yilBasindaEvli =
              s.personById('cocuk-1')?.development?.isMarried ?? false;
          s = motor.advanceOneYear(s);
          final int buYil = s.notices
              .where((PendingNotice n) =>
                  n.id.startsWith('cocuk-evlilik-cocuk-1-'))
              .length;
          if (buYil > 0 && yilBasindaEvli) evliykenEvlenen++;
          dugunBildirimi += buYil;
          s = s.copyWith(
            pendingEvent: null,
            pendingCrisis: null,
            notices: const <PendingNotice>[],
          );
        }
        // Her ek düğünün arkasında kapanmış (boşanma/dulluk) bir evlilik
        // kaydı olmalı: kayıt tutulmadan yeniden evlenilmiyor.
        final int kapanmisEvlilik = s
                .personById('cocuk-1')
                ?.development
                ?.pastMarriages
                .length ??
            0;
        if (dugunBildirimi > kapanmisEvlilik + 1) kayitsizDugun++;
        if (dugunBildirimi > 0) bildirimGelen++;
      }
      expect(
        evliykenEvlenen,
        0,
        reason: 'Evli çocuk ikinci kez evlenemez; evlilik kayda geçmeli',
      );
      expect(
        kayitsizDugun,
        0,
        reason: 'Her ek düğünün kapanmış bir evlilik kaydı olmalı (§23)',
      );
      expect(
        bildirimGelen,
        greaterThan(0),
        reason: 'Düğün bildirimi ekrana hiç ulaşmıyorsa bağlantı kopuk',
      );
    });
  });

  group('Meslekte ustalık ve itibar (D-155)', () {
    GameState calisan({
      int age = 40,
      int startedAtAge = 30,
      int level = 0,
      List<JobHistoryEntry> gecmis = const <JobHistoryEntry>[],
    }) {
      final JobType is_ = kJobCatalog.first;
      final GameState base = hayat(age: age);
      return base.copyWith(
        career: CareerState(
          jobId: is_.id,
          startedAtAge: startedAtAge,
          level: level,
          history: gecmis,
        ),
      );
    }

    test('basamaklar artan yılla sıralı ve ilki sıfır', () {
      expect(MasteryStage.values.first.yearsNeeded, 0);
      for (int i = 1; i < MasteryStage.values.length; i++) {
        expect(
          MasteryStage.values[i].yearsNeeded,
          greaterThan(MasteryStage.values[i - 1].yearsNeeded),
        );
      }
    });

    test('ustalık aynı işte geçen yıldan türetilir', () {
      expect(CraftMastery.stageForYears(0), MasteryStage.cirak);
      expect(CraftMastery.stageForYears(3), MasteryStage.kalfa);
      expect(CraftMastery.stageForYears(8), MasteryStage.usta);
      expect(CraftMastery.stageForYears(16), MasteryStage.basusta);
      expect(CraftMastery.stageForYears(28), MasteryStage.duayen);
      expect(CraftMastery.stageForYears(99), MasteryStage.duayen);
    });

    test('işsizde ustalık yok, gerekçesiz sayı üretilmez', () {
      final GameState s = hayat().copyWith(career: const CareerState.none());
      expect(CraftMastery.stageOf(s), isNull);
      expect(CraftMastery.yearsToNextStage(s), isNull);
      expect(CraftMastery.requestBonus(s), 0);
      expect(CraftMastery.layoffFactor(s), 1);
      expect(CraftMastery.reputationLabel(s), 'Henüz iş hayatı yok');
    });

    test('sonraki basamağa kalan yıl doğru, en üstte null', () {
      expect(CraftMastery.yearsToNextStage(calisan(age: 30, startedAtAge: 30)),
          MasteryStage.kalfa.yearsNeeded);
      expect(
        CraftMastery.yearsToNextStage(calisan(age: 70, startedAtAge: 30)),
        isNull,
      );
    });

    test('ustalık zam şansına, işten çıkarılma ihtimaline etki eder', () {
      final GameState yeni = calisan(age: 30, startedAtAge: 30);
      final GameState kidemli = calisan(age: 60, startedAtAge: 30);
      expect(
        CraftMastery.requestBonus(kidemli),
        greaterThan(CraftMastery.requestBonus(yeni)),
      );
      expect(
        CraftMastery.layoffFactor(kidemli),
        lessThan(CraftMastery.layoffFactor(yeni)),
      );
      // Usta olmak dokunulmazlık değildir: çarpan bir tabanın altına
      // inmez.
      expect(
        CraftMastery.layoffFactor(kidemli),
        greaterThanOrEqualTo(CraftMastery.prototypeOnlyMinLayoffFactor),
      );
    });

    test('itibar çalışma yılıyla artar, işten çıkarılmayla düşer', () {
      final GameState az = calisan(age: 32, startedAtAge: 30);
      final GameState cok = calisan(age: 60, startedAtAge: 30);
      expect(
        CraftMastery.reputationOf(cok),
        greaterThan(CraftMastery.reputationOf(az)),
      );

      final GameState cikarilmis = calisan(
        age: 60,
        startedAtAge: 55,
        gecmis: <JobHistoryEntry>[
          JobHistoryEntry(
            jobId: kJobCatalog.first.id,
            startedAtAge: 30,
            endedAtAge: 50,
            endReason: JobEndReason.cikarildi,
          ),
          JobHistoryEntry(
            jobId: kJobCatalog.first.id,
            startedAtAge: 50,
            endedAtAge: 55,
            endReason: JobEndReason.cikarildi,
          ),
        ],
      );
      final GameState temiz = calisan(
        age: 60,
        startedAtAge: 55,
        gecmis: <JobHistoryEntry>[
          JobHistoryEntry(
            jobId: kJobCatalog.first.id,
            startedAtAge: 30,
            endedAtAge: 50,
            endReason: JobEndReason.istifa,
          ),
          JobHistoryEntry(
            jobId: kJobCatalog.first.id,
            startedAtAge: 50,
            endedAtAge: 55,
            endReason: JobEndReason.istifa,
          ),
        ],
      );
      expect(
        CraftMastery.reputationOf(cikarilmis),
        lessThan(CraftMastery.reputationOf(temiz)),
      );
    });

    test('itibar iş değişince sıfırlanmaz', () {
      final GameState s = calisan(
        age: 60,
        startedAtAge: 58,
        gecmis: <JobHistoryEntry>[
          JobHistoryEntry(
            jobId: kJobCatalog.first.id,
            startedAtAge: 25,
            endedAtAge: 58,
            endReason: JobEndReason.istifa,
            level: 2,
          ),
        ],
      );
      expect(CraftMastery.reputationOf(s), greaterThan(40));
    });

    test('itibar 0-100 arasında kalır', () {
      for (final GameState s in <GameState>[
        calisan(age: 18, startedAtAge: 18),
        calisan(age: 95, startedAtAge: 18, level: 5),
      ]) {
        expect(CraftMastery.reputationOf(s), inInclusiveRange(0, 100));
      }
    });

    test('basamak atlanan yıl kaydedilir ve bildirim gelir', () {
      // Kalfa eşiği 3 yıl: 30'da başlayan 33'te kalfa olur.
      GameState s = calisan(age: 32, startedAtAge: 30).copyWith(
        pendingEvent: null,
        notices: const <PendingNotice>[],
      );
      s = LifeProgression(Random(5)).advanceOneYear(s);
      expect(
        s.notices.any((PendingNotice n) => n.id.startsWith('ustalik-kalfa-')),
        isTrue,
        reason: 'Kalfa olunan yıl bildirime çıkmalı',
      );
      expect(
        s.log.any((LifeLogEntry l) => l.text.contains('kalfa')),
        isTrue,
      );
    });

    test('aynı basamak iki kez kutlanmaz', () {
      GameState s = calisan(age: 33, startedAtAge: 30).copyWith(
        pendingEvent: null,
        notices: const <PendingNotice>[],
      );
      s = LifeProgression(Random(5)).advanceOneYear(s);
      expect(
        s.notices.any((PendingNotice n) => n.id.startsWith('ustalik-kalfa-')),
        isFalse,
        reason: '34 yaşında 4. yıl: eşik yılı değil',
      );
    });
  });

  group('Hayat hedefleri (D-156)', () {
    test('hedef kimlikleri benzersiz, metinleri dolu', () {
      final List<String> kimlikler =
          kLifeGoals.map((LifeGoal g) => g.id).toList();
      expect(kimlikler.toSet(), hasLength(kimlikler.length));
      for (final LifeGoal g in kLifeGoals) {
        expect(g.label, isNotEmpty, reason: g.id);
        expect(g.description, isNotEmpty, reason: g.id);
      }
    });

    test('her alanda en az bir hedef var', () {
      for (final GoalArea a in GoalArea.values) {
        expect(lifeGoalsIn(a), isNotEmpty, reason: a.label);
      }
    });

    test('yeni hayatta hiçbir hedefe ulaşılmamış olabilir', () {
      // "Bir hedefe doğuştan ulaşılmış" gibi bir durum olmamalı; yeni
      // hayatın hedef kaydı boş başlar.
      final GameState s = hayat(age: 0);
      expect(s.goalsReachedAt, isEmpty);
      expect(LifeGoals.reachedCount(s), 0);
    });

    test('ulaşılan hedef o yılın yaşıyla kaydedilir', () {
      // Cüzdanı bir milyonu geçen oyuncu "ilk milyon" hedefine ulaşır.
      final GameState s = hayat(age: 44, wallet: kGoalMillion + 5);
      final GameState sonra =
          LifeGoals.advanceYear(state: s, newAge: s.player.age);
      expect(sonra.goalsReachedAt['ilk_milyon'], 44);
      expect(sonra.goalReached('ilk_milyon'), isTrue);
    });

    test('ulaşılan hedefin yaşı sonradan değişmez', () {
      GameState s = hayat(age: 44, wallet: kGoalMillion + 5);
      s = LifeGoals.advanceYear(state: s, newAge: 44);
      // Sonraki yıllarda tekrar bakılsa bile yaş 44 kalır.
      s = LifeGoals.advanceYear(state: s, newAge: 50);
      expect(s.goalsReachedAt['ilk_milyon'], 44);
    });

    test('para harcanınca kayıt silinmez', () {
      GameState s = hayat(age: 44, wallet: kGoalMillion + 5);
      s = LifeGoals.advanceYear(state: s, newAge: 44);
      s = s.copyWith(player: s.player.copyWith(wallet: 10));
      s = LifeGoals.advanceYear(state: s, newAge: 45);
      expect(
        s.goalsReachedAt['ilk_milyon'],
        44,
        reason: 'Yaşanmış an silinmez',
      );
    });

    test('bir yılda birden fazla hedef tek pencerede toplanır', () {
      // Aynı anda birçok hedefi sağlayan bir durum kur.
      GameState s = hayat(age: 40, wallet: kGoalMillion + 5);
      s = s.copyWith(
        career: CareerState(
          jobId: kJobCatalog.first.id,
          startedAtAge: 20,
        ),
        education: s.education,
      );
      final GameState sonra =
          LifeGoals.advanceYear(state: s, newAge: 40);
      expect(sonra.goalsReachedAt.length, greaterThan(2));
      final List<PendingNotice> hedefPencereleri = sonra.notices
          .where((PendingNotice n) => n.id.startsWith('hedefler-'))
          .toList();
      expect(
        hedefPencereleri,
        hasLength(1),
        reason: 'Aynı başlıklı pencere üst üste açılmaz; kayıt yine tutulur',
      );
      // Tek pencere, sabitteki kadar hedefin adını anıyor.
      final List<String> anilan = kLifeGoals
          .where((LifeGoal g) => sonra.goalsReachedAt.containsKey(g.id))
          .map((LifeGoal g) => g.label)
          .where((String l) => hedefPencereleri.first.text.contains(l))
          .toList();
      expect(anilan, hasLength(LifeGoals.prototypeOnlyMaxNoticesPerYear));
      // Tek hedefte eski tekil pencere korunuyor.
      GameState tek = hayat(age: 44, wallet: kGoalMillion + 5);
      tek = LifeGoals.advanceYear(state: tek, newAge: 44);
      expect(
        tek.notices.where((PendingNotice n) => n.id.startsWith('hedef-')),
        hasLength(1),
      );
    });

    test('ulaşılanlar yaşa göre sıralı döner', () {
      GameState s = hayat(age: 30);
      s = s.copyWith(
        goalsReachedAt: const <String, int>{
          'emekli_ol': 65,
          'ilk_is': 22,
          'evlen': 30,
        },
      );
      final List<({LifeGoal goal, int age})> sirali =
          LifeGoals.reachedInOrder(s);
      expect(sirali.map((({LifeGoal goal, int age}) e) => e.age).toList(),
          <int>[22, 30, 65]);
    });

    test('hedef kaydı kaydedilip geri okunur, eski kayıt bozulmaz', () {
      final GameState s = hayat().copyWith(
        goalsReachedAt: const <String, int>{'ilk_is': 22},
      );
      final GameState geri = decodeGameState(encodeGameState(s));
      expect(geri.goalsReachedAt['ilk_is'], 22);

      final Map<String, Object?> json = encodeGameState(s);
      json.remove('goalsReachedAt');
      expect(decodeGameState(json).goalsReachedAt, isEmpty);
    });

    test('yıl akışında hedef gerçekten kaydediliyor', () {
      GameState s = hayat(age: 40, wallet: kGoalMillion + 5).copyWith(
        pendingEvent: null,
        notices: const <PendingNotice>[],
      );
      s = LifeProgression(Random(4)).advanceOneYear(s);
      expect(
        s.goalsReachedAt['ilk_milyon'],
        40,
        reason: 'Yaş artmadan önce bakıldığı için 40 yazılmalı',
      );
    });
  });
}
