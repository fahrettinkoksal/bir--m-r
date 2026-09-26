/// Kefalet, tutukluluk, cezaevi hayatı ve üvey ebeveyn testleri
/// (D-139, D-140, D-141).
library;

import 'dart:math';

import 'package:bir_omur/data/crime_catalog.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/generation/step_parents.dart';
import 'package:bir_omur/domain/interaction/family_interactions.dart';
import 'package:bir_omur/domain/law/legal_engine.dart';
import 'package:bir_omur/domain/law/prison_life.dart';
import 'package:bir_omur/domain/models/criminal_record.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/interaction.dart';
import 'package:bir_omur/domain/models/life_log.dart';
import 'package:bir_omur/domain/models/pending_trial.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:flutter_test/flutter_test.dart';

GameState hayat(int seed, {int age = 30, int wallet = 500000}) {
  final GameState s =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  return s.copyWith(
    player: s.player.copyWith(age: age, wallet: wallet),
    pendingEvent: null,
  );
}

/// Tutuklu bir durum kurar: dosya soruşturmada, kefalet belirlenmiş.
GameState tutukluKur(
  GameState state, {
  String crimeId = 'yaralama',
  int? kefalet,
}) {
  final CrimeType suc = crimeTypeById(crimeId)!;
  final CriminalCase dosya = CriminalCase(
    id: 'dosya-1',
    crimeId: crimeId,
    ageAtIncident: state.player.age,
    stage: CaseStage.sorusturma,
  );
  return state.copyWith(
    legal: state.legal.copyWith(
      cases: <CriminalCase>[dosya],
      caseCounter: 1,
      detainedSinceAge: state.player.age,
      bailAmount: kefalet ?? LegalEngine.bailFor(suc),
    ),
  );
}

/// Hükümlü bir durum kurar.
GameState hukumluKur(GameState state, {int yil = 4}) {
  final int yas = state.player.age;
  return state.copyWith(
    legal: state.legal.copyWith(
      cases: <CriminalCase>[
        CriminalCase(
          id: 'dosya-1',
          crimeId: 'yaralama',
          ageAtIncident: yas,
          stage: CaseStage.karar,
          verdict: Verdict.hapis,
          prisonYears: yil,
          decidedAtAge: yas,
        ),
      ],
      caseCounter: 1,
      imprisonedSinceAge: yas,
      releaseAtAge: yas + yil,
    ),
  );
}

/// Verilen kişiyi listeye ekleyerek yeni bir durum döner.
GameState kisiEkle(GameState state, Person kisi) => state.copyWith(
      people: List<Person>.unmodifiable(<Person>[...state.people, kisi]),
    );

Person zenginAnne({int bond = 80}) => Person(
      id: 'anne-test',
      firstName: 'Sevim',
      lastName: 'Koç',
      gender: Gender.kadin,
      relation: RelationType.anne,
      age: 58,
      isAlive: true,
      inPlayerHousehold: false,
      employment: EmploymentStatus.calisiyor,
      occupation: 'öğretmen',
      wealth: WealthTier.cokVarlikli,
      bond: bond,
    );

void main() {
  // ===================================================================
  // 1) Tutukluluk hükümlülük değildir
  // ===================================================================
  group('Tutukluluk (D-139)', () {
    test('tutuklu oyuncu içeridedir ama hükümlü değildir', () {
      final GameState s = tutukluKur(hayat(1));
      expect(s.legal.isDetained, isTrue);
      expect(s.legal.isSentenced, isFalse);
      expect(s.legal.isImprisoned, isTrue, reason: 'Tutukluluk da içeridir');
      expect(s.legal.hasRecord, isFalse, reason: 'Ceza verilmedi');
    });

    test('18 yaşından küçük tutuklanmaz', () {
      for (int seed = 0; seed < 40; seed++) {
        GameState s = hayat(seed, age: 15);
        s = LegalEngine.openCase(s, 'yaralama', Random(seed));
        expect(s.legal.isDetained, isFalse, reason: 'tohum $seed');
      }
    });

    test('ağır dosyada tutuklama kararı çıkabilir', () {
      int tutuklu = 0;
      for (int seed = 0; seed < 60; seed++) {
        GameState s = hayat(seed);
        s = LegalEngine.openCase(s, 'yaralama', Random(seed));
        if (s.legal.isDetained) tutuklu++;
      }
      expect(tutuklu, greaterThan(0), reason: 'Hiç tutuklama çıkmadı');
      expect(tutuklu, lessThan(60), reason: 'Her dosyada tutuklama olmamalı');
    });

    test('hafif trafik olayında tutuklama olmaz', () {
      for (int seed = 0; seed < 40; seed++) {
        GameState s = hayat(seed);
        s = LegalEngine.openCase(s, 'trafik_hiz', Random(seed));
        expect(s.legal.isDetained, isFalse, reason: 'tohum $seed');
      }
    });

    test('tutukluluk süresiz sürmez; süre dolunca kalkar, dosya kalır', () {
      GameState s = tutukluKur(hayat(2));
      final int giris = s.player.age;
      for (int i = 1; i <= LegalEngine.prototypeOnlyMaxDetentionYears; i++) {
        s = s.copyWith(player: s.player.copyWith(age: giris + i));
        s = LegalEngine.advanceYear(s, giris + i, Random(99));
      }
      expect(s.legal.isDetained, isFalse);
      // Dosya kapanmadıysa hâlâ açıktır; kapandıysa da takipsizlik/dava
      // olarak ilerlemiştir — hiçbir durumda "tutuklu ve dosyasız" olmaz.
      expect(s.legal.cases, isNotEmpty);
    });

    test('tutukluyken soruşturma ilerler', () {
      // Motor tutukluyken de dosyayı işletmezse oyuncu içeride kilitlenir.
      int ilerledi = 0;
      for (int seed = 0; seed < 30; seed++) {
        GameState s = tutukluKur(hayat(seed));
        final int yeni = s.player.age + 1;
        s = s.copyWith(player: s.player.copyWith(age: yeni));
        s = LegalEngine.advanceYear(s, yeni, Random(seed));
        if (s.legal.cases.first.stage != CaseStage.sorusturma ||
            s.pendingTrial != null) {
          ilerledi++;
        }
      }
      expect(ilerledi, greaterThan(0));
    });
  });

  // ===================================================================
  // 2) Kefalet
  // ===================================================================
  group('Kefalet (D-139)', () {
    test('kefaleti kendin yatırınca çıkarsın; para teminatta durur', () {
      final GameState s = tutukluKur(hayat(3, wallet: 3000000));
      final int kefalet = s.legal.bailAmount!;
      expect(PrisonLife.selfBailBlockReason(s), isEmpty);

      final ({GameState state, PrisonOutcome outcome}) r =
          PrisonLife.payBailSelf(s);
      expect(r.outcome.applied, isTrue, reason: r.outcome.text);
      expect(r.state.legal.isDetained, isFalse);
      expect(r.state.legal.bailPaidBy, LegalState.selfPaidBail);
      expect(r.state.player.wallet, s.player.wallet - kefalet);
      // Dosya kapanmaz: yargılama dışarıda sürer.
      expect(r.state.legal.openCase, isNotNull);
    });

    test('parası yetmeyen kefaleti yatıramaz ve durum değişmez', () {
      final GameState s = tutukluKur(hayat(4, wallet: 100));
      expect(PrisonLife.selfBailBlockReason(s), isNotEmpty);
      final ({GameState state, PrisonOutcome outcome}) r =
          PrisonLife.payBailSelf(s);
      expect(r.outcome.applied, isFalse);
      expect(r.state.legal.isDetained, isTrue);
      expect(r.state.player.wallet, s.player.wallet);
    });

    test('tutuklu değilken kefalet yatırılmaz', () {
      final GameState s = hayat(5);
      expect(PrisonLife.selfBailBlockReason(s), isNotEmpty);
      expect(PrisonLife.payBailSelf(s).outcome.applied, isFalse);
      expect(PrisonLife.bailHelpers(s), isEmpty);
    });

    test('aileden kefalet istenebilir ve yakın biri öder', () {
      final GameState s =
          kisiEkle(tutukluKur(hayat(6, wallet: 0)), zenginAnne());
      expect(
        PrisonLife.bailHelpers(s).map((Person p) => p.id),
        contains('anne-test'),
      );

      // Zar tutmayan tohumlarda red çıkabilir; kabul eden bir tohum
      // bulunmalı, yoksa kapı gerçekte kapalı demektir.
      GameState? kabulEden;
      for (int seed = 0; seed < 30; seed++) {
        final ({GameState state, PrisonOutcome outcome}) r =
            PrisonLife.askFamilyForBail(
          state: s,
          personId: 'anne-test',
          rng: Random(seed),
        );
        expect(r.outcome.applied, isTrue);
        if (r.state.legal.bailPaidBy == 'anne-test') {
          kabulEden = r.state;
          break;
        }
      }
      expect(kabulEden, isNotNull, reason: 'Hiçbir tohumda kabul çıkmadı');
      expect(kabulEden!.legal.isDetained, isFalse);
      // Para oyuncunun cüzdanından çıkmaz: ödeyen aileden biri.
      expect(kabulEden.player.wallet, s.player.wallet);
      expect(
        kabulEden.personById('anne-test')!.bond,
        greaterThan(s.personById('anne-test')!.bond),
      );
    });

    test('aynı yıl ikinci kez istenmez', () {
      final GameState s =
          kisiEkle(tutukluKur(hayat(7, wallet: 0)), zenginAnne());
      final GameState sonra = PrisonLife.askFamilyForBail(
        state: s,
        personId: 'anne-test',
        rng: Random(1),
      ).state;
      final ({GameState state, PrisonOutcome outcome}) ikinci =
          PrisonLife.askFamilyForBail(
        state: sonra,
        personId: 'anne-test',
        rng: Random(2),
      );
      // Kabul edilip çıkıldıysa "zaten yatırıldı", edilmediyse "bu yıl
      // zaten istedin" der; her iki hâlde de ikinci deneme çalışmaz.
      expect(ikinci.outcome.applied, isFalse);
    });

    test('yakınlığı az olandan istenemez', () {
      // Üretilen ailedeki yakınlar listeyi kirletmesin: kişi listesi
      // yalnızca aranın soğuk olduğu tek kişiden oluşuyor.
      final GameState s = tutukluKur(hayat(8, wallet: 0)).copyWith(
        people: List<Person>.unmodifiable(<Person>[zenginAnne(bond: 5)]),
      );
      expect(PrisonLife.bailHelpers(s), isEmpty);
    });

    test('duruşmaya çıkınca kefalet geri verilir', () {
      GameState s = tutukluKur(hayat(9, wallet: 3000000));
      final int kefalet = s.legal.bailAmount!;
      s = PrisonLife.payBailSelf(s).state;
      final int cuzdanKefaletSonrasi = s.player.wallet;

      // Dosya davaya gelsin ve duruşma görülsün.
      s = s.copyWith(
        legal: s.legal.copyWith(
          cases: <CriminalCase>[
            s.legal.cases.first.copyWith(stage: CaseStage.dava),
          ],
        ),
        pendingTrial: PendingTrial(
          caseId: 'dosya-1',
          age: s.player.age,
          text: 'Duruşma.',
        ),
      );
      s = LegalEngine.resolveTrial(
        state: s,
        stance: DefenceStance.pismanlik,
        lawyerId: 'kendim',
        rng: Random(4),
      );
      // Karar ne olursa olsun teminat geri döner; para cezası ayrıca
      // düşülebilir, bu yüzden cüzdan en az kefalet kadar artmış olmalı
      // ya da cezayla dengelenmiş olmalı — kefalet kaydı temizlenir.
      expect(s.legal.bailPaidBy, isNull);
      expect(s.legal.bailAmount, isNull);
      expect(s.legal.isDetained, isFalse);
      final int ceza = s.legal.cases.first.fine;
      expect(s.player.wallet, cuzdanKefaletSonrasi + kefalet - ceza);
    });

    test('tutuklulukta geçen süre cezadan düşülür', () {
      // Üç yıl tutuklu kalıp iki yıl ceza alan biri içeride kalmaz.
      GameState s = hayat(10, wallet: 0);
      s = tutukluKur(s);
      final int giris = s.player.age;
      s = s.copyWith(
        player: s.player.copyWith(age: giris + 3),
        legal: s.legal.copyWith(
          cases: <CriminalCase>[
            s.legal.cases.first.copyWith(stage: CaseStage.dava),
          ],
        ),
        pendingTrial: PendingTrial(
          caseId: 'dosya-1',
          age: giris + 3,
          text: 'Duruşma.',
        ),
      );
      s = LegalEngine.resolveTrial(
        state: s,
        stance: DefenceStance.pismanlik,
        lawyerId: 'kendim',
        rng: Random(11),
      );
      final CriminalCase dosya = s.legal.cases.first;
      if (dosya.verdict == Verdict.hapis && dosya.prisonYears <= 3) {
        expect(
          s.legal.isSentenced,
          isFalse,
          reason: 'Tutuklulukta yatılan süre cezayı karşılamalı',
        );
        expect(dosya.closedAtAge, isNotNull);
      }
    });
  });

  // ===================================================================
  // 3) Cezaevi hayatı
  // ===================================================================
  group('Cezaevi hayatı (D-140)', () {
    test('dışarıdayken cezaevi eylemleri kapalı', () {
      final GameState s = hayat(12);
      for (final PrisonAction a in PrisonAction.values) {
        expect(PrisonLife.blockReason(s, a), isNotEmpty, reason: a.name);
        expect(
          PrisonLife.perform(state: s, action: a, rng: Random(1))
              .outcome
              .applied,
          isFalse,
        );
      }
    });

    test('koğuşta arkadaş edinilir ve sayı sınırlıdır', () {
      GameState s = hukumluKur(hayat(13), yil: 12);
      int yas = s.player.age;
      for (int tur = 0; tur < 40; tur++) {
        if (PrisonLife.blockReason(s, PrisonAction.kogustaSohbet).isEmpty) {
          s = PrisonLife.perform(
            state: s,
            action: PrisonAction.kogustaSohbet,
            rng: Random(tur),
          ).state;
        } else {
          // Yıl geçsin: sayaç sıfırlanır.
          yas++;
          s = s.copyWith(
            player: s.player.copyWith(age: yas),
            interactionCounts: const <String, int>{},
          );
        }
      }
      final List<Person> kogus = PrisonLife.cellmates(s);
      expect(kogus, isNotEmpty);
      expect(
        kogus.length,
        lessThanOrEqualTo(PrisonLife.prototypeOnlyMaxCellmates),
      );
      for (final Person p in kogus) {
        expect(p.relation, RelationType.kogusArkadasi);
        expect(p.relation.group, RelationGroup.arkadaslar);
        expect(p.relation.kanBagi, isFalse);
        expect(p.gender, s.player.gender, reason: 'Koğuşlar ayrıdır');
      }
    });

    test('koğuş arkadaşı tahliyeden sonra listede kalır', () {
      GameState s = hukumluKur(hayat(14), yil: 2);
      s = PrisonLife.perform(
        state: s,
        action: PrisonAction.kogustaSohbet,
        rng: Random(0),
      ).state;
      final int once = PrisonLife.cellmates(s).length;
      final int tahliye = s.legal.releaseAtAge!;
      s = s.copyWith(player: s.player.copyWith(age: tahliye));
      s = LegalEngine.advanceYear(s, tahliye, Random(3));
      expect(s.legal.isImprisoned, isFalse);
      expect(PrisonLife.cellmates(s).length, once);
    });

    test('kurallara uymak iyi hâli yükseltir ve yıllık sınırı var', () {
      GameState s = hukumluKur(hayat(15), yil: 8);
      final int basta = s.legal.goodBehaviour;
      for (int i = 0; i < PrisonLife.prototypeOnlyMaxPerAge; i++) {
        final ({GameState state, PrisonOutcome outcome}) r =
            PrisonLife.perform(
          state: s,
          action: PrisonAction.iyiHalGoster,
          rng: Random(i),
        );
        expect(r.outcome.applied, isTrue);
        s = r.state;
      }
      expect(s.legal.goodBehaviour, greaterThan(basta));
      expect(
        PrisonLife.blockReason(s, PrisonAction.iyiHalGoster),
        isNotEmpty,
        reason: 'Yıllık sınır işlemeli',
      );
    });

    test('gruba yakın durmak itibarı yükseltir, iyi hâli düşürür', () {
      GameState s = hukumluKur(hayat(16), yil: 8).copyWith(
        legal: hukumluKur(hayat(16), yil: 8)
            .legal
            .copyWith(goodBehaviour: 50),
      );
      final ({GameState state, PrisonOutcome outcome}) r =
          PrisonLife.perform(
        state: s,
        action: PrisonAction.grubaYaklas,
        rng: Random(1),
      );
      expect(r.outcome.applied, isTrue);
      expect(r.state.legal.crewStanding, greaterThan(s.legal.crewStanding));
      expect(r.state.legal.goodBehaviour, lessThan(s.legal.goodBehaviour));
      s = r.state;

      // Uzaklaşmak tersini yapar.
      final ({GameState state, PrisonOutcome outcome}) u =
          PrisonLife.perform(
        state: s,
        action: PrisonAction.gruptanUzakDur,
        rng: Random(2),
      );
      expect(u.outcome.applied, isTrue);
      expect(u.state.legal.crewStanding, lessThan(s.legal.crewStanding));
      expect(u.state.legal.goodBehaviour, greaterThan(s.legal.goodBehaviour));
    });

    test('tutukluluk koğuşunda grup yoktur', () {
      final GameState s = tutukluKur(hayat(17));
      expect(
        PrisonLife.blockReason(s, PrisonAction.grubaYaklas),
        isNotEmpty,
      );
      // Sohbet ve sakin durmak tutuklulukta da olur.
      expect(
        PrisonLife.blockReason(s, PrisonAction.kogustaSohbet),
        isEmpty,
      );
    });

    test('grup yokken uzaklaşılacak bir şey yok', () {
      final GameState s = hukumluKur(hayat(18));
      expect(
        PrisonLife.blockReason(s, PrisonAction.gruptanUzakDur),
        isNotEmpty,
      );
    });

    test('iyi hâl koşullu salıverilmeyi getirir', () {
      final GameState kurulu = hukumluKur(hayat(19), yil: 6);
      final int giris = kurulu.player.age;
      final int yeni = giris + 3; // cezanın yarısı
      GameState s = kurulu.copyWith(
        player: kurulu.player.copyWith(age: yeni),
        legal: kurulu.legal.copyWith(goodBehaviour: 80, crewStanding: 10),
      );
      s = LegalEngine.advanceYear(s, yeni, Random(5));
      expect(s.legal.isSentenced, isFalse, reason: 'Koşullu salıverilmeli');
      expect(s.legal.probationUntilAge, isNotNull);
    });

    test('gruba yakın duran koşullu salıverilmez', () {
      final GameState kurulu = hukumluKur(hayat(20), yil: 6);
      final int yeni = kurulu.player.age + 3;
      GameState s = kurulu.copyWith(
        player: kurulu.player.copyWith(age: yeni),
        legal: kurulu.legal.copyWith(goodBehaviour: 80, crewStanding: 70),
      );
      s = LegalEngine.advanceYear(s, yeni, Random(5));
      expect(s.legal.isSentenced, isTrue);
    });

    test('içeride geçen yıl sayılır', () {
      final GameState kurulu = hukumluKur(hayat(21), yil: 5);
      final int yeni = kurulu.player.age + 1;
      GameState s = kurulu.copyWith(
        player: kurulu.player.copyWith(age: yeni),
      );
      s = LegalEngine.advanceYear(s, yeni, Random(6));
      expect(s.legal.yearsServed, 1);
    });
  });

  // ===================================================================
  // 4) Üvey anne / baba
  // ===================================================================
  group('Üvey ebeveyn (D-141)', () {
    Person anne({bool alive = true}) => Person(
          id: 'anne-1',
          firstName: 'Nurten',
          lastName: 'Aydın',
          gender: Gender.kadin,
          relation: RelationType.anne,
          age: 50,
          isAlive: alive,
          inPlayerHousehold: alive,
          employment: EmploymentStatus.calisiyor,
          occupation: 'terzi',
          wealth: WealthTier.ortaHalli,
          bond: 70,
        );

    Person baba({bool alive = true}) => Person(
          id: 'baba-1',
          firstName: 'Kemal',
          lastName: 'Aydın',
          gender: Gender.erkek,
          relation: RelationType.baba,
          age: 54,
          isAlive: alive,
          inPlayerHousehold: alive,
          employment: EmploymentStatus.calisiyor,
          occupation: 'şoför',
          wealth: WealthTier.ortaHalli,
          bond: 65,
        );

    GameState aile({
      required bool babaSag,
      int age = 20,
      List<LifeLogEntry> log = const <LifeLogEntry>[],
    }) {
      final GameState s = hayat(30, age: age);
      return s.copyWith(
        people: List<Person>.unmodifiable(<Person>[
          anne(),
          baba(alive: babaSag),
        ]),
        log: List<LifeLogEntry>.unmodifiable(log),
      );
    }

    test('iki ebeveyn de hayattaysa üvey ebeveyn gelmez', () {
      final GameState s = aile(babaSag: true);
      for (int seed = 0; seed < 60; seed++) {
        final GameState sonra =
            StepParents.maybeRemarry(s, s.player.age, Random(seed));
        expect(
          sonra.people.any((Person p) => p.relation == RelationType.uveyBaba),
          isFalse,
          reason: 'tohum $seed',
        );
      }
    });

    test('baba vefat ettiyse üvey baba gelebilir', () {
      final GameState s = aile(babaSag: false);
      GameState? geldi;
      for (int seed = 0; seed < 80; seed++) {
        final GameState sonra =
            StepParents.maybeRemarry(s, s.player.age, Random(seed));
        if (sonra.people.length > s.people.length) {
          geldi = sonra;
          break;
        }
      }
      expect(geldi, isNotNull, reason: 'Hiçbir tohumda üvey baba gelmedi');
      final Person uvey = geldi!.people.last;
      expect(uvey.relation, RelationType.uveyBaba);
      expect(uvey.gender, Gender.erkek);
      expect(uvey.isAlive, isTrue);
      expect(uvey.bond, StepParents.prototypeOnlyStartBond);
      expect(uvey.relation.group, RelationGroup.cekirdek);
      expect(
        uvey.relation.kanBagi,
        isFalse,
        reason: 'Üvey ebeveyn kan bağı değildir',
      );
      // Vefat eden baba listeden silinmez.
      expect(geldi.people.any((Person p) => p.id == 'baba-1'), isTrue);
    });

    test('bir taraftan yalnızca bir üvey ebeveyn gelir', () {
      GameState s = aile(babaSag: false);
      for (int seed = 0; seed < 200; seed++) {
        s = StepParents.maybeRemarry(s, s.player.age, Random(seed));
      }
      expect(
        s.people.where((Person p) => p.relation == RelationType.uveyBaba).length,
        lessThanOrEqualTo(1),
      );
    });

    test('yas süresi dolmadan üvey ebeveyn gelmez', () {
      // Baba bu yıl vefat etti: kayıt günlükte duruyor.
      final GameState s = aile(
        babaSag: false,
        age: 20,
        log: <LifeLogEntry>[
          const LifeLogEntry(
            age: 20,
            text: 'Baban Kemal Aydın vefat etti.',
            category: LogCategory.aile,
            personId: 'baba-1',
          ),
        ],
      );
      for (int seed = 0; seed < 80; seed++) {
        final GameState sonra = StepParents.maybeRemarry(s, 20, Random(seed));
        expect(sonra.people.length, s.people.length, reason: 'tohum $seed');
      }
      // Yas süresi geçtikten sonra kapı açılır.
      GameState sonraki = s;
      bool geldi = false;
      for (int seed = 0; seed < 120; seed++) {
        final GameState deneme = StepParents.maybeRemarry(
          sonraki,
          20 + StepParents.prototypeOnlyMourningYears,
          Random(seed),
        );
        if (deneme.people.length > sonraki.people.length) {
          geldi = true;
          break;
        }
      }
      expect(geldi, isTrue);
    });

    test('üvey ebeveynle aile etkileşimleri açılır', () {
      GameState s = aile(babaSag: false);
      for (int seed = 0; seed < 200 &&
              !s.people.any((Person p) => p.relation == RelationType.uveyBaba);
          seed++) {
        s = StepParents.maybeRemarry(s, s.player.age, Random(seed));
      }
      final Person uvey = s.people
          .firstWhere((Person p) => p.relation == RelationType.uveyBaba);
      const FamilyInteractions etkilesim = FamilyInteractions();
      final List<InteractionKind> turler =
          etkilesim.availableKinds(s, uvey);
      expect(turler, contains(InteractionKind.vakitGecir));
      expect(turler, contains(InteractionKind.sohbet));
    });

    test('çok yaşlı ebeveyn yeniden evlenmez', () {
      GameState s = aile(babaSag: false);
      s = s.copyWith(
        people: List<Person>.unmodifiable(<Person>[
          s.people.first.copyWith(age: StepParents.prototypeOnlyMaxParentAge + 5),
          s.people.last,
        ]),
      );
      for (int seed = 0; seed < 80; seed++) {
        final GameState sonra =
            StepParents.maybeRemarry(s, s.player.age, Random(seed));
        expect(sonra.people.length, s.people.length, reason: 'tohum $seed');
      }
    });
  });

  // ===================================================================
  // 5) Kayıt
  // ===================================================================
  test('yeni adli alanlar kayda girer ve geri okunur', () {
    GameState s = tutukluKur(hayat(40, wallet: 5000000));
    s = PrisonLife.payBailSelf(s).state;
    s = s.copyWith(
      legal: s.legal.copyWith(
        goodBehaviour: 44,
        crewStanding: 27,
        yearsServed: 3,
        bailAskedAtAge: s.player.age,
      ),
    );

    final GameState geri = decodeGameState(encodeGameState(s));
    expect(geri.legal.bailPaidBy, s.legal.bailPaidBy);
    expect(geri.legal.bailAmount, s.legal.bailAmount);
    expect(geri.legal.detainedSinceAge, s.legal.detainedSinceAge);
    expect(geri.legal.bailAskedAtAge, s.legal.bailAskedAtAge);
    expect(geri.legal.goodBehaviour, 44);
    expect(geri.legal.crewStanding, 27);
    expect(geri.legal.yearsServed, 3);
  });

  test('eski kayıtta yeni alanlar boş açılır; tutukluluk uydurulmaz', () {
    final GameState s = hayat(41);
    final Map<String, Object?> json = encodeGameState(s);
    final Map<String, Object?> hukuk =
        Map<String, Object?>.from(json['legal']! as Map<String, Object?>)
          ..remove('detainedSinceAge')
          ..remove('bailAmount')
          ..remove('bailPaidBy')
          ..remove('bailAskedAtAge')
          ..remove('goodBehaviour')
          ..remove('crewStanding')
          ..remove('yearsServed');
    json['legal'] = hukuk;

    final GameState geri = decodeGameState(json);
    expect(geri.legal.isDetained, isFalse);
    expect(geri.legal.bailPaid, isFalse);
    expect(geri.legal.goodBehaviour, 0);
    expect(geri.legal.crewStanding, 0);
    expect(geri.legal.yearsServed, 0);
  });
}
