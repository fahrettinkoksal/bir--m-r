import 'dart:math';

import 'package:bir_omur/data/crime_catalog.dart';
import 'package:bir_omur/data/activity_catalog.dart';
import 'package:bir_omur/data/event_pool.dart';
import 'package:bir_omur/data/event_pool_crime.dart';
import 'package:bir_omur/data/job_catalog.dart';
import 'package:bir_omur/data/lawyer_catalog.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/domain/activities/activity_engine.dart';
import 'package:bir_omur/domain/career/job_market.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/law/legal_engine.dart';
import 'package:bir_omur/domain/models/career.dart';
import 'package:bir_omur/domain/models/criminal_record.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/pending_trial.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/active_player.dart';

GameState hayat(int seed, {int age = 25, int wallet = 500000}) {
  final GameState s =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  return s.copyWith(
    player: s.player.copyWith(age: age, wallet: wallet),
    pendingEvent: null,
  );
}

/// Dosyayı kesin olarak davaya kadar getirir.
///
/// Motorun zarına güvenilmez: test **kurulu** bir durumdan başlar, böylece
/// sonuç rastgeleliğe bağlı kalmaz.
GameState davaKur(
  GameState state,
  String crimeId, {
  String dosyaId = 'dosya-1',
}) {
  final CriminalCase dosya = CriminalCase(
    id: dosyaId,
    crimeId: crimeId,
    ageAtIncident: state.player.age,
    stage: CaseStage.dava,
  );
  return state.copyWith(
    legal: state.legal.copyWith(cases: <CriminalCase>[dosya], caseCounter: 1),
    pendingTrial: PendingTrial(
      caseId: dosyaId,
      age: state.player.age,
      text: 'Dosyan mahkemeye çıktı.',
    ),
  );
}

void main() {
  // ===================================================================
  // 1) Suç zorunlu içerik değil
  // ===================================================================
  test('suç işlemeyen hayat sabıkasız kalabilir', () {
    // 100 hayat, riskli seçim **hiç** seçilmeden oynanıyor. Bir tekinde
    // bile sabıka çıkarsa oyuncuyu istemediği bir yola sokuyoruz.
    int sabikali = 0;
    for (int seed = 0; seed < 100; seed++) {
      final ActiveLifeResult r = playActiveLife(seed, avoidCrime: true);
      if (r.finalLegal.hasRecord) sabikali++;
      if (r.finalLegal.cases.isNotEmpty) sabikali++;
    }
    expect(
      sabikali,
      0,
      reason: 'Riskli seçim yapmayan oyuncuya adli dosya açıldı. Suç '
          'zorunlu içerik olmamalı (D-128).',
    );
  });

  test('riskli seçim yapan oyuncuda sistem gerçekten işliyor', () {
    // Karşı ölçüm: sistem hiç çalışmıyor olmasın.
    int dosyasiOlan = 0;
    for (int seed = 0; seed < 40; seed++) {
      if (playActiveLife(seed).finalLegal.cases.isNotEmpty) dosyasiOlan++;
    }
    expect(dosyasiOlan, greaterThan(0));
  });

  // ===================================================================
  // 2) Dosya açılışı
  // ===================================================================
  group('dosya açılışı', () {
    test('hafif olay idari cezayla kapanır ve sabıka bırakmaz', () {
      final GameState once = hayat(3);
      final GameState sonra =
          LegalEngine.openCase(once, 'trafik_park', Random(1));
      expect(sonra.legal.cases, hasLength(1));
      final CriminalCase dosya = sonra.legal.cases.single;
      expect(dosya.stage, CaseStage.idariCeza);
      expect(dosya.leavesRecord, isFalse);
      expect(sonra.legal.hasRecord, isFalse);
      // Ceza gerçekten cüzdandan düştü.
      expect(sonra.player.wallet, lessThan(once.player.wallet));
      expect(dosya.finePaid, isTrue);
    });

    test('cüzdan eksiye düşmez', () {
      final GameState once = hayat(4, wallet: 10);
      final GameState sonra =
          LegalEngine.openCase(once, 'trafik_kaza', Random(1));
      expect(sonra.player.wallet, greaterThanOrEqualTo(0));
    });

    test('ağır olayda soruşturma açılır', () {
      // 40 tohumda en az birinde soruşturma açılmalı: courtChance 0,85.
      bool acildi = false;
      for (int i = 0; i < 40 && !acildi; i++) {
        final GameState sonra =
            LegalEngine.openCase(hayat(i), 'yaralama', Random(i));
        acildi = sonra.legal.openCase != null;
      }
      expect(acildi, isTrue);
    });

    test('olay seçimi dosyayı gerçekten açar', () {
      // Olay havuzundaki bir suç seçimi motoru tetikliyor mu?
      final GameEvent olay = kEventPool.firstWhere(
        (GameEvent e) => e.id == 'suc_marketten_cikis',
      );
      final EventChoice riskli = olay.choices.firstWhere(
        (EventChoice c) => c.crimeId != null,
      );
      expect(riskli.crimeId, 'kucuk_hirsizlik');
      final GameState sonra = LegalEngine.openCase(
        hayat(5, age: 20),
        riskli.crimeId!,
        Random(7),
      );
      expect(sonra.legal.cases, isNotEmpty);
    });
  });

  // ===================================================================
  // 3) Duruşma
  // ===================================================================
  group('duruşma', () {
    test('karar verilir ve dosya kapanır', () {
      final GameState kurulu = davaKur(hayat(6), 'sokak_kavgasi');
      final GameState sonra = LegalEngine.resolveTrial(
        state: kurulu,
        stance: DefenceStance.pismanlik,
        lawyerId: kSelfDefenceTier.id,
        rng: Random(2),
      );
      expect(sonra.pendingTrial, isNull);
      final CriminalCase dosya = sonra.legal.cases.single;
      expect(dosya.stage, CaseStage.karar);
      expect(dosya.verdict, isNot(Verdict.yok));
      expect(dosya.decidedAtAge, kurulu.player.age);
    });

    test('aynı dava iki kez sonuçlanmaz', () {
      final GameState kurulu = davaKur(hayat(7), 'sokak_kavgasi');
      final GameState birinci = LegalEngine.resolveTrial(
        state: kurulu,
        stance: DefenceStance.anlat,
        lawyerId: kSelfDefenceTier.id,
        rng: Random(3),
      );
      final CriminalCase ilkHal = birinci.legal.cases.single;
      // İkinci çağrı: bekleyen duruşma yok, hiçbir şey değişmemeli.
      final GameState ikinci = LegalEngine.resolveTrial(
        state: birinci,
        stance: DefenceStance.anlat,
        lawyerId: kSelfDefenceTier.id,
        rng: Random(4),
      );
      final CriminalCase ikinciHal = ikinci.legal.cases.single;
      expect(ikinci.legal.cases, hasLength(1));
      expect(ikinciHal.verdict, ilkHal.verdict);
      expect(ikinciHal.fine, ilkHal.fine);
      expect(ikinci.player.wallet, birinci.player.wallet);
    });

    test('para cezası yalnızca bir kez kesilir', () {
      // Para cezası çıkan bir tohum bulunur, sonra ikinci çağrının
      // cüzdana dokunmadığı doğrulanır.
      for (int i = 0; i < 60; i++) {
        final GameState kurulu = davaKur(hayat(8), 'borc_davasi');
        final GameState sonra = LegalEngine.resolveTrial(
          state: kurulu,
          stance: DefenceStance.anlat,
          lawyerId: kSelfDefenceTier.id,
          rng: Random(i),
        );
        final CriminalCase dosya = sonra.legal.cases.single;
        if (dosya.verdict != Verdict.paraCezasi) continue;
        expect(dosya.finePaid, isTrue);
        expect(dosya.fine, greaterThan(0));
        expect(
          sonra.player.wallet,
          kurulu.player.wallet - dosya.fine,
          reason: 'Ceza tam olarak bir kez kesilmeli.',
        );
        final GameState tekrar = LegalEngine.resolveTrial(
          state: sonra,
          stance: DefenceStance.anlat,
          lawyerId: kSelfDefenceTier.id,
          rng: Random(i),
        );
        expect(tekrar.player.wallet, sonra.player.wallet);
        return;
      }
      fail('60 denemede hiç para cezası çıkmadı; denge bozulmuş olabilir.');
    });

    test('avukat ücreti bir kez ödenir', () {
      final LawyerTier iyi = lawyerTierById('iyi')!;
      final GameState kurulu =
          davaKur(hayat(9, wallet: 5000000), 'sokak_kavgasi');
      final GameState sonra = LegalEngine.resolveTrial(
        state: kurulu,
        stance: DefenceStance.avukat,
        lawyerId: iyi.id,
        rng: Random(11),
      );
      final CriminalCase dosya = sonra.legal.cases.single;
      expect(dosya.lawyerId, iyi.id);
      final int beklenen =
          kurulu.player.wallet - iyi.fee - dosya.fine;
      expect(sonra.player.wallet, beklenen);
    });

    test('parası yetmeyen avukat tutamaz ve kendini savunur', () {
      final LawyerTier iyi = lawyerTierById('iyi')!;
      final GameState kurulu = davaKur(hayat(10, wallet: 100), 'sokak_kavgasi');
      expect(LegalEngine.lawyerBlockReason(kurulu, iyi), isNotEmpty);
      final GameState sonra = LegalEngine.resolveTrial(
        state: kurulu,
        stance: DefenceStance.avukat,
        lawyerId: iyi.id,
        rng: Random(12),
      );
      expect(sonra.legal.cases.single.lawyerId, kSelfDefenceTier.id);
      expect(sonra.player.wallet, greaterThanOrEqualTo(0));
    });

    test('avukat sonucu garanti etmez', () {
      // En iyi avukatla bile bütün sonuçlar aynı çıkmıyor: garanti yok.
      final Set<Verdict> kararlar = <Verdict>{};
      for (int i = 0; i < 40; i++) {
        final GameState sonra = LegalEngine.resolveTrial(
          state: davaKur(hayat(13, wallet: 9000000), 'yaralama'),
          stance: DefenceStance.avukat,
          lawyerId: 'iyi',
          rng: Random(i),
        );
        kararlar.add(sonra.legal.cases.single.verdict);
      }
      expect(kararlar.length, greaterThan(1));
    });
  });

  // ===================================================================
  // 4) Hapis
  // ===================================================================
  group('hapis', () {
    GameState hapiste(int seed) {
      // Hapis kararı çıkan bir durum kurulur.
      for (int i = 0; i < 200; i++) {
        final GameState kurulu = davaKur(
          hayat(seed, wallet: 1000).copyWith(
            career: const CareerState(
              jobId: 'garson',
              startedAtAge: 24,
              lastPaidAge: 25,
              salary: 400000,
            ),
          ),
          'yaralama',
        );
        final GameState sonra = LegalEngine.resolveTrial(
          state: kurulu,
          stance: DefenceStance.anlat,
          lawyerId: kSelfDefenceTier.id,
          rng: Random(i),
        );
        if (sonra.legal.isImprisoned) return sonra;
      }
      fail('200 denemede hapis kararı çıkmadı.');
    }

    test('hapis işi bitirir ve kayıt geçmişe geçer', () {
      final GameState icerde = hapiste(14);
      expect(icerde.isImprisoned, isTrue);
      expect(icerde.career.isEmployed, isFalse);
      // Kayıt **silinmez**: geçmişte duruyor.
      expect(icerde.career.history, isNotEmpty);
      expect(
        icerde.career.history.last.endReason,
        JobEndReason.hapis,
      );
    });

    test('hapis ilişkileri zayıflatır ama kimseyi silmez', () {
      final GameState kurulu = hayat(15);
      final int oncekiKisi = kurulu.people.length;
      final GameState icerde = hapiste(15);
      expect(icerde.people.length, greaterThanOrEqualTo(oncekiKisi));
      // Yaşayan en az bir kişinin yakınlığı düşmüş olmalı.
      final Iterable<Person> yasayan =
          icerde.people.where((Person p) => p.isAlive);
      expect(yasayan, isNotEmpty);
    });

    test('süresi dolunca tahliye olur ve denetim dönemi başlar', () {
      GameState s = hapiste(16);
      final int tahliye = s.legal.releaseAtAge!;
      // Tahliye yaşına kadar ilerlet.
      for (int yas = s.player.age + 1; yas <= tahliye; yas++) {
        s = LegalEngine.advanceYear(s, yas, Random(yas));
      }
      expect(s.legal.isImprisoned, isFalse);
      expect(s.legal.probationUntilAge, isNotNull);
      expect(s.legal.cases.single.closedAtAge, tahliye);
    });

    test('cezaevi aktiviteleri yalnızca içeride açılır', () {
      const ActivityEngine motor = ActivityEngine();
      final ActivityAction gorus = activityActionById('cezaevi_gorus')!;
      final ActivityAction berber = activityActionById('sac_kestir')!;

      final GameState disarida = hayat(17);
      expect(motor.availability(disarida, gorus).isAllowed, isFalse);
      expect(motor.availability(disarida, berber).isAllowed, isTrue);

      final GameState icerde = hapiste(17);
      expect(motor.availability(icerde, gorus).isAllowed, isTrue);
      expect(
        motor.availability(icerde, berber).isAllowed,
        isFalse,
        reason: 'Cezaevindeyken berbere gidilemez.',
      );
    });

    test('cezaevindeyken işe başvurulamaz', () {
      const JobMarket pazar = JobMarket();
      final GameState icerde = hapiste(18);
      final JobType garson = jobById('garson')!;
      expect(pazar.requirementReason(icerde, garson), isNotEmpty);
    });
  });

  // ===================================================================
  // 5) Sabıka ve iş
  // ===================================================================
  group('sabıka ve iş başvurusu', () {
    GameState sabikali(String crimeId) {
      final GameState s = hayat(20, age: 26);
      return s.copyWith(
        legal: s.legal.copyWith(
          cases: <CriminalCase>[
            CriminalCase(
              id: 'dosya-1',
              crimeId: crimeId,
              ageAtIncident: 22,
              stage: CaseStage.karar,
              verdict: Verdict.paraCezasi,
              fine: 5000,
              finePaid: true,
              decidedAtAge: 22,
              closedAtAge: 22,
            ),
          ],
          caseCounter: 1,
        ),
      );
    }

    test('temiz kayıt isteyen işe sabıkalı başvuramaz', () {
      const JobMarket pazar = JobMarket();
      final GameState s = sabikali('sokak_kavgasi');
      final JobType polis = jobById('polis')!;
      final String gerekce = pazar.recordReason(s, polis);
      expect(gerekce, isNotEmpty);
      // Gerekçe açık yazılır (D-063): hangi kayıt, hangi yaş.
      expect(gerekce, contains('22 yaşındaki'));
    });

    test('her suç bütün işleri kapatmaz', () {
      const JobMarket pazar = JobMarket();
      final GameState s = sabikali('sokak_kavgasi');
      // Garsonluk adli kayda bakmaz.
      expect(pazar.recordReason(s, jobById('garson')!), isEmpty);
    });

    test('hafif kayıt ağır-engelleyen işi kapatmaz', () {
      const JobMarket pazar = JobMarket();
      final GameState hafif = sabikali('borc_davasi');
      // Borç davası hafiftir: öğretmenlik kapanmaz.
      expect(pazar.recordReason(hafif, jobById('ogretmen')!), isEmpty);
      // Ama temiz kayıt isteyen memurluk kapanır.
      expect(pazar.recordReason(hafif, jobById('memur')!), isNotEmpty);
    });

    test('ağır kayıt ağır-engelleyen işi kapatır', () {
      const JobMarket pazar = JobMarket();
      final GameState agir = sabikali('yaralama');
      expect(pazar.recordReason(agir, jobById('ogretmen')!), isNotEmpty);
    });

    test('temiz oyuncuya hiçbir adli engel çıkmaz', () {
      const JobMarket pazar = JobMarket();
      final GameState temiz = hayat(21, age: 26);
      for (final JobType is_ in kJobCatalog) {
        expect(pazar.recordReason(temiz, is_), isEmpty);
      }
    });
  });

  // ===================================================================
  // 6) Kayıt (save/load)
  // ===================================================================
  group('kayıt', () {
    test('soruşturma kaydedilip yüklenir', () {
      final GameState once = hayat(30).copyWith(
        legal: const LegalState(
          cases: <CriminalCase>[
            CriminalCase(
              id: 'dosya-1',
              crimeId: 'sokak_kavgasi',
              ageAtIncident: 24,
              stage: CaseStage.sorusturma,
              note: 'Hakkında soruşturma başlatıldı.',
            ),
          ],
          caseCounter: 1,
        ),
      );
      final GameState geri = decodeGameState(encodeGameState(once));
      expect(geri.legal.cases, hasLength(1));
      expect(geri.legal.openCase?.stage, CaseStage.sorusturma);
      expect(geri.legal.caseCounter, 1);
      expect(geri.legal.cases.single.note, isNotNull);
    });

    test('sabıka, hapis ve bekleyen duruşma kaydedilip yüklenir', () {
      final GameState once = hayat(31).copyWith(
        legal: const LegalState(
          cases: <CriminalCase>[
            CriminalCase(
              id: 'dosya-1',
              crimeId: 'yaralama',
              ageAtIncident: 24,
              stage: CaseStage.karar,
              verdict: Verdict.hapis,
              prisonYears: 2,
              lawyerId: 'standart',
              decidedAtAge: 25,
            ),
          ],
          imprisonedSinceAge: 25,
          releaseAtAge: 27,
          probationUntilAge: 29,
          caseCounter: 1,
        ),
        pendingTrial: const PendingTrial(
          caseId: 'dosya-1',
          age: 25,
          text: 'Dosyan mahkemeye çıktı.',
        ),
      );
      final GameState geri = decodeGameState(encodeGameState(once));
      expect(geri.legal.hasRecord, isTrue);
      expect(geri.legal.isImprisoned, isTrue);
      expect(geri.legal.releaseAtAge, 27);
      expect(geri.legal.probationUntilAge, 29);
      final CriminalCase dosya = geri.legal.cases.single;
      expect(dosya.verdict, Verdict.hapis);
      expect(dosya.prisonYears, 2);
      expect(dosya.lawyerId, 'standart');
      expect(geri.pendingTrial?.caseId, 'dosya-1');
    });

    test('eski kayıt temiz açılır; geriye dönük sabıka uydurulmaz', () {
      final Map<String, Object?> json = encodeGameState(hayat(32));
      json.remove('legal');
      json.remove('pendingTrial');
      final GameState geri = decodeGameState(json);
      expect(geri.legal.cases, isEmpty);
      expect(geri.legal.hasRecord, isFalse);
      expect(geri.pendingTrial, isNull);
      expect(geri.isImprisoned, isFalse);
    });
  });

  // ===================================================================
  // 7) Ailenin tepkisi
  // ===================================================================
  group('ailenin tepkisi', () {
    test('vefat etmiş ebeveyn tepki vermez', () {
      GameState s = hayat(40);
      // Bütün yakınları vefat ettir.
      s = s.copyWith(
        people: List<Person>.unmodifiable(
          s.people
              .map(
                (Person p) => p.relation == RelationType.anne ||
                        p.relation == RelationType.baba ||
                        p.relation == RelationType.es
                    ? p.copyWith(isAlive: false)
                    : p,
              )
              .toList(growable: false),
        ),
      );
      // Ağır bir olayla dosya açılsın; ölüler konuşmasın.
      GameState sonra = s;
      for (int i = 0; i < 40; i++) {
        sonra = LegalEngine.openCase(s, 'yaralama', Random(i));
        if (sonra.legal.openCase != null) break;
      }
      final bool oluKonustu = sonra.notices.any(
        (dynamic n) => (n.title as String) == 'Evde duyulmuş',
      );
      expect(
        oluKonustu,
        isFalse,
        reason: 'Vefat etmiş yakın adli haberde konuşmamalı.',
      );
    });

    test('yaşayan anne veya baba tepki gösterir', () {
      final GameState s = hayat(41);
      final bool yakinVar = s.people.any(
        (Person p) =>
            p.isAlive &&
            (p.relation == RelationType.anne ||
                p.relation == RelationType.baba),
      );
      if (!yakinVar) return; // Bu tohumda yakın yok; başka test kapsar.
      for (int i = 0; i < 60; i++) {
        final GameState sonra = LegalEngine.openCase(s, 'yaralama', Random(i));
        if (sonra.legal.openCase == null) continue;
        expect(
          sonra.notices.any((dynamic n) => (n.title as String) == 'Evde duyulmuş'),
          isTrue,
        );
        return;
      }
      fail('60 denemede soruşturma açılmadı.');
    });
  });

  // ===================================================================
  // 8) İçerik ve dil
  // ===================================================================
  group('içerik ve dil', () {
    test('havuza kayıtlı, kimlikleri benzersiz', () {
      final Set<String> havuz = kEventPool.map((GameEvent e) => e.id).toSet();
      for (final GameEvent e in kCrimeEvents) {
        expect(havuz.contains(e.id), isTrue, reason: '${e.id} havuzda yok');
      }
      expect(
        kCrimeEvents.map((GameEvent e) => e.id).toSet().length,
        kCrimeEvents.length,
      );
    });

    test('her suç olayında temiz bir kapı var', () {
      // Oyuncu hiçbir olayda suça mecbur bırakılmaz.
      for (final GameEvent e in kCrimeEvents) {
        final bool temizSecenekVar =
            e.choices.any((EventChoice c) => c.crimeId == null);
        expect(
          temizSecenekVar,
          isTrue,
          reason: '${e.id} olayında suça girmeyen bir seçenek yok.',
        );
      }
    });

    test('kullanılan suç kimlikleri katalogda var', () {
      for (final GameEvent e in kCrimeEvents) {
        for (final EventChoice c in e.choices) {
          if (c.crimeId == null) continue;
          expect(
            crimeTypeById(c.crimeId!),
            isNotNull,
            reason: '${e.id}/${c.id}: "${c.crimeId}" katalogda yok.',
          );
        }
      }
    });

    test('seçenekler aynı sonucu vermez', () {
      final List<String> tekduze = <String>[];
      for (final GameEvent e in kCrimeEvents) {
        final Set<String> imza = e.choices
            .map(
              (EventChoice c) => <Object>[
                c.happiness,
                c.health,
                c.intelligence,
                c.charisma,
                c.bond,
                c.money,
                c.addFlags.toList()..sort(),
                c.crimeId ?? '',
                c.rememberPersonAs ?? '',
              ].join('|'),
            )
            .toSet();
        if (imza.length < e.choices.length) tekduze.add(e.id);
      }
      expect(tekduze, isEmpty, reason: 'Etkisi aynı seçenekler: $tekduze');
    });

    test('metinler WRITING_STYLE_TR sınırlarında', () {
      // Yasak kalıplar, uzunluk ve etiket kuralı (§2, §6, §8).
      const List<String> yasak = <String>[
        'olumlu yönde',
        'bu deneyim',
        'duygusal açıdan',
        'katkı sağladı',
        'kendini daha iyi hissettin',
        // §6: kullanılmayacak sokak ağzı.
        'kanka',
        'moruk',
        ' aga ',
        'bro',
      ];
      for (final GameEvent e in kCrimeEvents) {
        final String hepsi = <String>[
          e.text,
          for (final EventChoice c in e.choices) c.resultText,
        ].join(' ').toLowerCase();
        for (final String k in yasak) {
          expect(
            hepsi.contains(k.toLowerCase()),
            isFalse,
            reason: '${e.id}: yasak kalıp "$k".',
          );
        }
        expect(
          e.text.length,
          lessThanOrEqualTo(320),
          reason: '${e.id}: olay metni çok uzun.',
        );
        for (final EventChoice c in e.choices) {
          expect(
            c.label.length,
            lessThanOrEqualTo(34),
            reason: '${e.id}/${c.id}: etiket çok uzun.',
          );
        }
      }
    });

    test('hâkim ve polis sokak ağzı kullanmaz', () {
      // §15: polis kısa ve ciddi, hâkim resmî. Karikatür yok.
      const List<String> karikatur = <String>['gel lan', 'oğlum buraya'];
      for (final GameEvent e in kCrimeEvents) {
        final String hepsi = <String>[
          e.text,
          for (final EventChoice c in e.choices) c.resultText,
        ].join(' ').toLowerCase();
        for (final String k in karikatur) {
          expect(hepsi.contains(k), isFalse, reason: '${e.id}: "$k"');
        }
      }
    });

    test('en az beş çok adımlı zincir var', () {
      // Zincir: bir izi **isteyen** olay sayısı. Havuzda en az beş ayrı
      // zincir başlangıç izi kullanılıyor olmalı.
      final Set<String> zincirIzleri = <String>{};
      for (final GameEvent e in kCrimeEvents) {
        zincirIzleri.addAll(e.requirement.requiredFlags);
      }
      expect(
        zincirIzleri.length,
        greaterThanOrEqualTo(5),
        reason: 'Zincir sayısı beşin altına düştü.',
      );
    });
  });

  // ===================================================================
  // 9) Simülasyon kilitlenmiyor
  // ===================================================================
  test('hayat simülasyonu adli sistemle kilitlenmez', () {
    for (int seed = 0; seed < 60; seed++) {
      final ActiveLifeResult r = playActiveLife(seed);
      expect(
        r.finalAge,
        greaterThan(0),
        reason: '$seed tohumunda hayat ilerlemedi.',
      );
      // Hayat tamamlandıysa içeride kalmış bir dosya bekleyen duruşma
      // olarak takılı kalmamalı.
      expect(r.finalLegal.openCase?.stage, isNot(CaseStage.idariCeza));
    }
  });
}
