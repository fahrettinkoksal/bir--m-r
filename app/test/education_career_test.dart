import 'dart:convert';
import 'dart:math';

import 'package:bir_omur/data/education_tracks.dart';
import 'package:bir_omur/data/hobby_catalog.dart';
import 'package:bir_omur/domain/hobby/hobby_tracker.dart';
import 'package:bir_omur/data/interview_catalog.dart';
import 'package:bir_omur/data/job_catalog.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/data/save/save_format.dart';
import 'package:bir_omur/data/save/save_service.dart';
import 'package:bir_omur/data/save/save_store.dart';
import 'package:bir_omur/data/university_catalog.dart';
import 'package:bir_omur/domain/career/job_market.dart';
import 'package:bir_omur/domain/economy/living_costs.dart';
import 'package:bir_omur/domain/education/education_path.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/generation/life_progression.dart';
import 'package:bir_omur/domain/models/career.dart';
import 'package:bir_omur/domain/models/education.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/life_log.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_flow.dart';

const EducationPath path = EducationPath();
const JobMarket market = JobMarket();

GameState life(
  int seed, {
  int age = 14,
  int wallet = 0,
  int intelligence = 60,
}) {
  final GameState state = LifeGenerator.seeded(
    seed,
  ).generate(mode: StartMode.tamamenRastgele);
  return state.copyWith(
    player: state.player.copyWith(
      age: age,
      wallet: wallet,
      stats: state.player.stats.copyWith(intelligence: intelligence),
    ),
  );
}

/// Lise çağında, puanı belli bir öğrenci.
GameState highSchooler(
  int seed, {
  int grade = 9,
  int score = 80,
  int age = 14,
  EducationTrack? track,
}) {
  return life(seed, age: age).copyWith(
    education: EducationState(
      enrolled: true,
      grade: grade,
      startedAtAge: 6,
      placementScore: score,
      track: track,
    ),
  );
}

/// Lise mezunu.
GameState graduate(
  int seed, {
  EducationTrack? track,
  int score = 80,
  int age = 18,
  int intelligence = 70,
  int charisma = 60,
  int? examScore,
}) {
  final GameState base = life(seed, age: age, intelligence: intelligence);
  return base.copyWith(
    player: base.player.copyWith(
      stats: base.player.stats.copyWith(charisma: charisma),
    ),
    education: EducationState(
      startedAtAge: 6,
      finished: true,
      placementScore: score,
      universityExamScore: examScore ?? score,
      track: track,
    ),
  );
}

/// Mülakatı doğru cevaplayarak işe girer; başaramazsa `null` döner.
GameState? hire(GameState state, JobType job) {
  final JobResult basvuru = market.apply(state, job, Random(1));
  if (!basvuru.outcome.interviewStarted) return null;
  final InterviewQuestion soru = basvuru.state.pendingInterview!.question!;
  final JobResult cevap = market.answerInterview(
    basvuru.state,
    soru.correctIndex,
  );
  return cevap.outcome.accepted ? cevap.state : null;
}

void main() {
  // ===================================================================
  // Lise tercihi
  // ===================================================================
  group('Lise tercihi', () {
    test('8. sınıftan 9. sınıfa geçince yerleştirme puanı oluşur', () {
      final GameController c = GameController(random: Random(5));
      c.startNewLife(mode: StartMode.tamamenRastgele, seed: 5);
      advanceToAge(c, LifeProgression.prototypeOnlySchoolStartAge + 7);
      resolvePendingEvents(c);
      expect(c.state!.education.grade, 8);
      expect(c.state!.education.placementScore, isNull);

      advanceToAge(c, LifeProgression.prototypeOnlySchoolStartAge + 8);
      resolvePendingEvents(c);
      expect(c.state!.education.grade, 9);
      expect(c.state!.education.placementScore, isNotNull);
      expect(c.state!.education.placementScore, inInclusiveRange(0, 100));
      expect(c.state!.education.awaitingTrackChoice, isTrue);
      expect(
        c.state!.log.any(
          (dynamic e) => (e.text as String).contains('Yerleştirme puanın'),
        ),
        isTrue,
      );
    });

    test('puan düşük olsa bile en az üç alan açık kalır', () {
      for (final int puan in <int>[0, 10, 30, 50, 100]) {
        final List<EducationTrackInfo> acik = tracksFor(puan);
        expect(
          acik.length,
          greaterThanOrEqualTo(3),
          reason: '$puan puanla seçenek kalmamalı değil',
        );
      }
      expect(tracksFor(100).length, kEducationTracks.length);
    });

    test('puanı yetmeyen alan seçilemez', () {
      final GameState state = highSchooler(6, score: 20);
      final EducationResult r = path.chooseTrack(
        state,
        EducationTrack.fenBilim,
      );
      expect(r.outcome.applied, isFalse);
      expect(r.state.education.track, isNull);
    });

    test('seçilen alan kalıcı olarak kaydedilir', () {
      final GameState state = highSchooler(7, score: 90);
      final EducationResult r = path.chooseTrack(state, EducationTrack.bilisim);
      expect(r.outcome.accepted, isTrue);
      expect(r.state.education.track, EducationTrack.bilisim);
      expect(r.state.education.awaitingTrackChoice, isFalse);
      expect(r.state.log.last.text, contains('Bilişim'));

      // İkinci kez seçilemez.
      final EducationResult ikinci = path.chooseTrack(
        r.state,
        EducationTrack.muzik,
      );
      expect(ikinci.outcome.applied, isFalse);
      expect(ikinci.state.education.track, EducationTrack.bilisim);
    });

    test('lise alanı mezuniyette de korunur', () {
      GameState state = highSchooler(8, grade: 12, score: 90, age: 17);
      state = path.chooseTrack(state, EducationTrack.tasarim).state;
      final EducationState mezun = state.education.asFinished();
      expect(mezun.track, EducationTrack.tasarim);
      expect(mezun.placementScore, 90);
    });

    test('lise alanı yıllık küçük kazanç verir', () {
      final GameState state = highSchooler(
        9,
        grade: 9,
        score: 95,
        track: EducationTrack.fenBilim,
        age: 14,
      );
      final int zekaOnce = state.player.stats.intelligence;
      final GameState sonra = LifeProgression(Random(1)).advanceOneYear(state);
      expect(sonra.player.stats.intelligence, greaterThan(zekaOnce));
    });
  });

  // ===================================================================
  // Üniversite
  // ===================================================================
  group('Üniversite', () {
    test('12. sınıftan sonra otomatik üniversiteye gidilmez', () {
      final GameController c = GameController(random: Random(11));
      c.startNewLife(mode: StartMode.tamamenRastgele, seed: 11);
      advanceToAge(c, LifeProgression.prototypeOnlySchoolStartAge + 12);
      resolvePendingEvents(c);

      expect(c.state!.education.finished, isTrue);
      expect(
        c.state!.education.universityProgramId,
        isNull,
        reason: 'Kimse otomatik üniversiteye yazılmaz',
      );
      expect(c.state!.education.awaitingAfterSchoolChoice, isTrue);
    });

    test('bölüme kabul eğitim geçmişine bağlıdır', () {
      final UniversityProgram muh = universityProgramById('muhendislik')!;
      final GameState uygun = graduate(
        12,
        track: EducationTrack.fenBilim,
        score: 85,
        intelligence: 85,
      );
      final GameState uygunsuz = graduate(
        12,
        track: EducationTrack.elSanatlari,
        score: 20,
        intelligence: 30,
      );

      // Etkin puan rastgelelik içermez: ekranda görünen puan ile başvuruda
      // kullanılan puan aynıdır.
      expect(
        path.effectiveScore(uygun, muh),
        greaterThan(path.effectiveScore(uygunsuz, muh)),
      );
      expect(path.effectiveScore(uygun, muh), path.effectiveScore(uygun, muh));

      final EducationResult red = path.applyToUniversity(
        uygunsuz,
        muh,
        Random(1),
      );
      expect(red.outcome.accepted, isFalse);
      expect(red.state.education.universityProgramId, isNull);

      final EducationResult kabul = path.applyToUniversity(
        uygun,
        muh,
        Random(1),
      );
      expect(kabul.outcome.accepted, isTrue);
      expect(kabul.state.education.universityProgramId, 'muhendislik');
      expect(kabul.state.education.universityYear, 1);
    });

    test('düşük puanlı öğrenciye de açık bölüm bulunur', () {
      final GameState zayif = graduate(
        13,
        track: EducationTrack.elSanatlari,
        score: 35,
        intelligence: 40,
      );
      final UniversityProgram isletme = universityProgramById('isletme')!;
      final EducationResult r = path.applyToUniversity(
        zayif,
        isletme,
        Random(3),
      );
      expect(r.outcome.applied, isTrue);
    });

    test('üniversite yılları ilerler ve mezuniyetle biter', () {
      GameState state = graduate(
        14,
        track: EducationTrack.fenBilim,
        score: 90,
        intelligence: 90,
      );
      state = path
          .applyToUniversity(
            state,
            universityProgramById('muhendislik')!,
            Random(1),
          )
          .state;
      expect(state.education.isUniversityStudent, isTrue);

      final LifeProgression ilerleme = LifeProgression(Random(2));
      for (int i = 0; i < 4; i++) {
        state = ilerleme.advanceOneYear(state);
        state = state.copyWith(pendingEvent: null);
      }
      expect(state.education.universityFinished, isTrue);
      expect(state.education.isUniversityStudent, isFalse);
      expect(state.education.label, contains('mezunu'));
    });

    test('üniversiteye gitmeyen oyuncu oyuna devam eder', () {
      final GameState state = graduate(15, track: EducationTrack.teknikMeslek);
      final EducationResult r = path.skipUniversity(state);
      expect(r.outcome.accepted, isTrue);
      expect(
        r.state.storyFlags,
        contains(EducationPath.universiteyeGitmediFlag),
      );
      expect(r.state.education.universityProgramId, isNull);
      // İş aramaya devam edebilir.
      expect(market.openJobs(r.state), isNotEmpty);
    });
  });

  // ===================================================================
  // Meslek
  // ===================================================================
  group('Meslek', () {
    test('yaşı veya eğitimi yetmeyen işe başvurulamaz', () {
      final GameState cocuk = life(21, age: 12);
      expect(market.openJobs(cocuk), isEmpty);

      final GameState mezun = graduate(21, track: EducationTrack.genelAkademik);
      final JobType yazilim = jobById('yazilim_gelistirici')!;
      expect(
        market.meetsRequirements(mezun, yazilim),
        isFalse,
        reason: 'Bilişim geçmişi olmadan yazılımcı olunmaz',
      );
      expect(market.requirementReason(mezun, yazilim), isNotEmpty);

      final JobType magaza = jobById('magaza_calisani')!;
      expect(market.meetsRequirements(mezun, magaza), isTrue);
    });

    test('öğrenciyken tam zamanlı işe başvurulmaz', () {
      final GameState ogrenci = highSchooler(22, grade: 11, age: 17);
      // D-131'den sonra öğrenciye **yarım zamanlı** işler açık; testin
      // iddiası aynı kaldı ve daraltıldı: tam zamanlı hiçbir iş açık
      // olmamalı.
      final List<JobType> acik = market.openJobs(ogrenci);
      expect(
        acik.where((JobType j) => !j.partTime),
        isEmpty,
        reason: 'Öğrenciye tam zamanlı iş açılmamalı.',
      );
      // Karşı iddia: yarım zamanlı kapı gerçekten açık.
      expect(acik.where((JobType j) => j.partTime), isNotEmpty);
    });

    test('başvuru doğrudan kabulle sonuçlanmaz, mülakat açılır', () {
      final GameState mezun = graduate(
        23,
        track: EducationTrack.bilisim,
        intelligence: 80,
        age: 21,
      );
      final JobType yazilim = jobById('yazilim_gelistirici')!;
      expect(market.meetsRequirements(mezun, yazilim), isTrue);

      final JobResult r = market.apply(mezun, yazilim, Random(1));
      expect(r.outcome.interviewStarted, isTrue);
      expect(
        r.outcome.accepted,
        isFalse,
        reason: 'Başvuru tek başına işe almaz',
      );
      expect(r.state.career.isEmployed, isFalse);
      expect(r.state.pendingInterview, isNotNull);
    });

    test('mülakat doğru cevaplanınca iş kaydı oluşur', () {
      final GameState mezun = graduate(
        24,
        track: EducationTrack.bilisim,
        intelligence: 85,
        age: 21,
      );
      final JobType yazilim = jobById('yazilim_gelistirici')!;
      final GameState? ise = hire(mezun, yazilim);
      expect(ise, isNotNull);

      final CareerState career = ise!.career;
      expect(career.jobId, 'yazilim_gelistirici');
      expect(career.startedAtAge, 21);
      expect(career.lastPaidAge, 21, reason: 'İşe girilen yıl maaş ödenmez');
      expect(ise.log.last.text, contains('işe alındın'));
      expect(ise.pendingInterview, isNull);
    });

    test('aynı yaşta sınırsız başvuru yapılamaz', () {
      GameState state = graduate(25, track: EducationTrack.genelAkademik);
      final JobType magaza = jobById('magaza_calisani')!;
      int basarili = 0;
      for (int i = 0; i < 10; i++) {
        final JobResult r = market.apply(state, magaza, Random(100 + i));
        if (!r.outcome.applied) break;
        basarili++;
        // Yanlış cevap vererek başvuruyu tüket.
        final InterviewQuestion soru = r.state.pendingInterview!.question!;
        final int yanlis = (soru.correctIndex + 1) % soru.options.length;
        state = market.answerInterview(r.state, yanlis).state;
      }
      expect(
        basarili,
        lessThanOrEqualTo(JobMarket.prototypeOnlyMaxApplicationsPerAge),
      );
    });

    test('işten ayrılma geçmişi korur', () {
      GameState state = graduate(26, track: EducationTrack.genelAkademik)
          .copyWith(
            career: const CareerState(
              jobId: 'magaza_calisani',
              startedAtAge: 18,
              lastPaidAge: 18,
            ),
          );
      final JobResult r = market.quit(state);
      expect(r.outcome.applied, isTrue);
      expect(r.state.career.isEmployed, isFalse);
      expect(r.state.career.pastJobIds, contains('magaza_calisani'));

      // Ayrıldıktan sonra yeniden başvurabilir.
      state = r.state;
      expect(market.openJobs(state), isNotEmpty);
    });
  });

  // ===================================================================
  // Maaş
  // ===================================================================
  group('Maaş', () {
    GameState employed(int seed, {int age = 20, int lastPaid = 20}) =>
        graduate(seed, age: age, track: EducationTrack.genelAkademik).copyWith(
          career: CareerState(
            jobId: 'magaza_calisani',
            startedAtAge: age,
            lastPaidAge: lastPaid,
          ),
        );

    test('maaş yaş alınca bir kez ödenir', () {
      final GameState state = employed(31);
      final int cuzdanOnce = state.player.wallet;
      final int maas = jobById('magaza_calisani')!.yearlySalary;

      final GameState sonra = LifeProgression(Random(1)).advanceOneYear(state);
      // Maaş bir kez ödenir; yıllık geçim gideri (D-033) bir kez düşer.
      final int gider = LivingCosts.yearlyCost(sonra);
      expect(sonra.player.wallet, cuzdanOnce + maas - gider);
      expect(sonra.career.lastPaidAge, 21);
      expect(
        sonra.log.any((dynamic e) => (e.text as String).contains('cüzdanına')),
        isTrue,
      );
    });

    test('aynı dönem maaşı iki kez ödenmez', () {
      final GameState state = employed(32);
      final ({GameState state, String? logText}) ilk = market.paySalaryFor(
        state.copyWith(player: state.player.copyWith(age: 21)),
        21,
      );
      expect(ilk.logText, isNotNull);

      final ({GameState state, String? logText}) ikinci = market.paySalaryFor(
        ilk.state,
        21,
      );
      expect(ikinci.logText, isNull);
      expect(
        ikinci.state.player.wallet,
        ilk.state.player.wallet,
        reason: 'İkinci ödeme yapılmamalı',
      );
    });

    test('işsizken maaş ödenmez', () {
      final GameState state = graduate(33);
      final int cuzdan = state.player.wallet;
      final GameState sonra = LifeProgression(Random(1)).advanceOneYear(state);
      expect(sonra.player.wallet, cuzdan);
    });

    test('yaşayan ailenin parası oyuncunun cüzdanına geçmez', () {
      final GameState state = graduate(34);
      expect(state.player.wallet, 0);
      final GameState sonra = LifeProgression(Random(2)).advanceOneYear(state);

      // Cüzdan yalnızca gerçekten gerçekleşmiş bir olayla (miras) değişir;
      // hayatta olan ailenin varlığı sessizce oyuncuya geçmez. Geçim gideri
      // cüzdanı eksiye düşürmez (D-033).
      expect(sonra.player.wallet, greaterThanOrEqualTo(0));
      final bool mirasSatiri = sonra.log.any(
        (LifeLogEntry e) => e.text.contains('miras'),
      );
      if (!mirasSatiri) {
        expect(
          sonra.player.wallet,
          0,
          reason: 'Miras yoksa cüzdan kendiliğinden dolmamalı',
        );
      } else {
        expect(
          sonra.player.wallet,
          greaterThan(0),
          reason: 'Günlükte miras varsa cüzdana gerçekten girmeli',
        );
      }
    });
  });

  // ===================================================================
  // Kayıt uyumu ve okul kişileri
  // ===================================================================
  group('Kayıt ve okul kişileri', () {
    test(
      'desteklenen en eski sürümün kaydı eğitim/meslek alanları eklenerek açılır',
      () async {
        final GameController c = GameController(random: Random(41));
        c.startNewLife(mode: StartMode.tamamenRastgele, seed: 41);
        advanceToAge(c, LifeProgression.prototypeOnlySchoolStartAge + 2);
        resolvePendingEvents(c);
        final GameState orijinal = c.state!;

        // Paket 12'den beri geriye dönük yalnızca son beş sürüm taşınır;
        // eğitim/meslek alanlarının hiç olmadığı sürümler artık
        // desteklenmiyor. Bu test desteklenen en eski sürümü sınar.
        final SaveLoadResult result = await SaveService(
          MemorySaveStore(
            initial: jsonEncode(<String, Object?>{
              'formatVersion': kMinReadableSaveVersion,
              'state': encodeGameState(orijinal),
            }),
          ),
        ).load();
        expect(result.isLoaded, isTrue, reason: result.message);

        final GameState yuklenen = result.state!;
        expect(yuklenen.player.id, orijinal.player.id);
        expect(yuklenen.player.age, orijinal.player.age);
        expect(yuklenen.people.length, orijinal.people.length);
        expect(
          yuklenen.currentClassmates.length,
          orijinal.currentClassmates.length,
        );
        expect(yuklenen.education.track, isNull);
        expect(yuklenen.career.isEmployed, isFalse);
        expect(yuklenen.items.length, orijinal.items.length);
      },
    );

    test('eğitim ve meslek kaydedilip geri okunur', () async {
      GameState state = graduate(42, track: EducationTrack.bilisim, age: 22);
      state = path
          .applyToUniversity(
            state,
            universityProgramById('bilgisayar')!,
            Random(1),
          )
          .state;
      state = state.copyWith(
        career: const CareerState(
          jobId: 'magaza_calisani',
          startedAtAge: 20,
          lastPaidAge: 21,
          pastJobIds: <String>['garson'],
        ),
      );

      final MemorySaveStore store = MemorySaveStore();
      final SaveService service = SaveService(store);
      await service.save(state);
      final SaveLoadResult result = await service.load();
      expect(result.isLoaded, isTrue);

      final GameState sonra = result.state!;
      expect(sonra.education.track, EducationTrack.bilisim);
      expect(sonra.education.placementScore, state.education.placementScore);
      expect(
        sonra.education.universityProgramId,
        state.education.universityProgramId,
      );
      expect(sonra.education.universityYear, state.education.universityYear);
      expect(sonra.career.jobId, 'magaza_calisani');
      expect(sonra.career.lastPaidAge, 21);
      expect(sonra.career.pastJobIds, <String>['garson']);
    });

    test('lise boyunca okul kişileri korunur', () {
      final GameController c = GameController(random: Random(43));
      c.startNewLife(mode: StartMode.tamamenRastgele, seed: 43);
      advanceToAge(c, LifeProgression.prototypeOnlySchoolStartAge + 8);
      resolvePendingEvents(c);
      final Set<String> liseliler = c.state!.currentClassmates
          .map((Person p) => p.id)
          .toSet();
      expect(liseliler, isNotEmpty);

      advanceToAge(c, LifeProgression.prototypeOnlySchoolStartAge + 12);
      resolvePendingEvents(c);
      for (final String id in liseliler) {
        expect(c.state!.personById(id), isNotNull, reason: 'Kayıt silinmez');
      }
      final List<String> ids = c.state!.people.map((Person p) => p.id).toList();
      expect(ids.toSet().length, ids.length, reason: 'İkinci NPC üretilmez');
    });

    test('kayıt sürümü yükseltildi', () {
      expect(kSaveFormatVersion, greaterThanOrEqualTo(4));
    });
  });

  // -------------------------------------------------------------------
  // Görünüş ve hobiyle açılan meslekler
  //
  // Faho mankenlik ve yazarlık istedi. Bu işlere diplomayla değil,
  // görünüşle ya da yıllarca sürdürülmüş bir uğraşla giriliyor —
  // dövüş eğitmenliğiyle (Paket 32) aynı mantık.
  // -------------------------------------------------------------------
  group('Görünüş ve hobiyle açılan meslekler', () {
    /// Lise mezunu, işsiz, istenen yaşta bir hayat.
    GameState calisabilir(int seed, {int age = 22}) {
      final GameState s = life(seed, age: age);
      return s.copyWith(
        pendingEvent: null,
        education: const EducationState(finished: true, startedAtAge: 6),
      );
    }

    GameState gorunus(GameState s, int deger) => s.copyWith(
      player: s.player.copyWith(
        stats: s.player.stats.copyWith(appearance: deger),
      ),
    );

    /// Hobiye [kez] kadar deneyim yazar.
    GameState hobiVer(GameState s, HobbyKind hobi, int kez) {
      GameState next = s;
      for (int i = 0; i < kez; i++) {
        next = HobbyTracker.credit(next, hobi);
      }
      return next;
    }

    test('mankenlik görünüşü yetmeyene kapalı, gerekçesi yazılı', () {
      final JobType manken = jobById('manken')!;
      GameState s = gorunus(calisabilir(11), manken.minAppearance - 1);
      s = s.copyWith(
        player: s.player.copyWith(stats: s.player.stats.copyWith(charisma: 90)),
      );
      final String engel = market.requirementReason(s, manken);
      expect(engel, isNotEmpty);
      expect(engel, contains('görünüş'));
      expect(market.openJobs(s), isNot(contains(manken)));
    });

    test('mankenlik görünüşü yetene açılır', () {
      final JobType manken = jobById('manken')!;
      GameState s = gorunus(calisabilir(11), 95);
      s = s.copyWith(
        player: s.player.copyWith(stats: s.player.stats.copyWith(charisma: 90)),
      );
      expect(market.requirementReason(s, manken), isEmpty);
      expect(market.openJobs(s), contains(manken));
    });

    test('yazarlık hiç kitap bitirmemişe kapalı', () {
      final JobType yazar = jobById('yazar')!;
      final GameState s = calisabilir(12);
      final String engel = market.requirementReason(s, yazar);
      expect(engel, isNotEmpty);
      expect(engel, contains('Okumak'));
    });

    test('yazarlık okuma basamağı gelince açılır', () {
      final JobType yazar = jobById('yazar')!;
      GameState s = calisabilir(12);
      s = s.copyWith(
        player: s.player.copyWith(
          stats: s.player.stats.copyWith(intelligence: 80),
        ),
      );
      final HobbyKind okuma = hobbyById('okuma')!;
      s = hobiVer(s, okuma, okuma.stages[yazar.minHobbyStage].experience);
      expect(market.requirementReason(s, yazar), isEmpty);
      expect(market.openJobs(s), contains(yazar));
    });

    test('müzisyenlik müzik basamağı gelince açılır', () {
      final JobType muzisyen = jobById('muzisyen')!;
      GameState s = calisabilir(13);
      s = s.copyWith(
        player: s.player.copyWith(stats: s.player.stats.copyWith(charisma: 80)),
      );
      expect(market.requirementReason(s, muzisyen), isNotEmpty);

      final HobbyKind muzik = hobbyById('muzik')!;
      s = hobiVer(s, muzik, muzik.stages[muzisyen.minHobbyStage].experience);
      expect(market.requirementReason(s, muzisyen), isEmpty);
    });

    test('bir basamak eksikken iş hâlâ kapalı', () {
      final JobType muzisyen = jobById('muzisyen')!;
      GameState s = calisabilir(13);
      s = s.copyWith(
        player: s.player.copyWith(stats: s.player.stats.copyWith(charisma: 80)),
      );
      final HobbyKind muzik = hobbyById('muzik')!;
      // Eşiğin bir eksiği: basamak henüz çıkmamış olmalı.
      s = hobiVer(
        s,
        muzik,
        muzik.stages[muzisyen.minHobbyStage].experience - 1,
      );
      expect(market.requirementReason(s, muzisyen), isNotEmpty);
    });

    test('yeni mesleklerin hepsine gerçekten başvurulabiliyor', () {
      // İlan panosunda görünüp başvurulamayan iş kalmasın: her yeni
      // işin mülakatı açılabilmeli.
      const List<String> yeniler = <String>[
        'asci',
        'kuafor',
        'muhasebeci',
        'manken',
        'yazar',
        'muzisyen',
      ];
      for (final String id in yeniler) {
        final JobType job = jobById(id)!;
        expect(
          questionsForJob(job.id),
          isNotEmpty,
          reason: '$id için mülakat sorusu yok',
        );
      }
    });

    test('manken mülakatı açılıp cevaplanabiliyor', () {
      final JobType manken = jobById('manken')!;
      GameState s = gorunus(calisabilir(11), 95);
      s = s.copyWith(
        player: s.player.copyWith(stats: s.player.stats.copyWith(charisma: 90)),
      );
      expect(market.applicationAvailability(s, manken).isAllowed, isTrue);

      final JobResult basvuru = market.apply(s, manken, Random(1));
      expect(basvuru.outcome.interviewStarted, isTrue);

      final int dogru = basvuru.state.pendingInterview!.question!.correctIndex;
      final JobResult cevap = market.answerInterview(
        basvuru.state,
        dogru,
        Random(1),
      );
      expect(cevap.outcome.accepted, isTrue);
      expect(cevap.state.career.jobId, 'manken');
    });
  });
}
