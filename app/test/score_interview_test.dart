import 'dart:convert';
import 'dart:math';

import 'package:bir_omur/data/education_tracks.dart';
import 'package:bir_omur/data/interview_catalog.dart';
import 'package:bir_omur/data/job_catalog.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/data/save/save_format.dart';
import 'package:bir_omur/data/save/save_service.dart';
import 'package:bir_omur/data/save/save_store.dart';
import 'package:bir_omur/data/university_catalog.dart';
import 'package:bir_omur/domain/career/job_market.dart';
import 'package:bir_omur/domain/education/education_path.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/generation/life_progression.dart';
import 'package:bir_omur/domain/models/career.dart';
import 'package:bir_omur/domain/models/education.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/interaction.dart';
import 'package:bir_omur/domain/models/pending_interview.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_flow.dart';

const EducationPath path = EducationPath();
const JobMarket market = JobMarket();

/// Lise mezunu, puanları belli bir oyuncu.
GameState mezun(
  int seed, {
  EducationTrack? track,
  int placement = 70,
  int? exam,
  int age = 20,
  int intelligence = 75,
  int charisma = 70,
  bool universityFinished = false,
  String? programId,
}) {
  final GameState base =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  return base.copyWith(
    player: base.player.copyWith(
      age: age,
      stats: base.player.stats.copyWith(
        intelligence: intelligence,
        charisma: charisma,
      ),
    ),
    education: EducationState(
      startedAtAge: 6,
      finished: true,
      placementScore: placement,
      universityExamScore: exam ?? placement,
      track: track,
      universityProgramId: programId,
      universityFinished: universityFinished,
    ),
  );
}

/// Kayıt yolunun tamamını kullanarak durumu geri okur.
Future<GameState> roundTrip(GameState state) async {
  final SaveService service = SaveService(MemorySaveStore());
  await service.save(state);
  final SaveLoadResult result = await service.load();
  expect(result.isLoaded, isTrue, reason: result.message);
  return result.state!;
}

void main() {
  // ===================================================================
  // 1) Üniversite puanının görünürlüğü
  // ===================================================================
  group('Üniversite sınav puanı görünür ve saklanır', () {
    test('lise bitince puan bir kez hesaplanıp kaydedilir', () {
      final GameController c = GameController(random: Random(5));
      c.startNewLife(mode: StartMode.tamamenRastgele, seed: 5);
      advanceToAge(c, LifeProgression.prototypeOnlySchoolStartAge + 13);
      resolvePendingEvents(c);

      final GameState state = c.state!;
      expect(state.education.finished, isTrue, reason: 'Lise bitmiş olmalı');
      final int? puan = state.education.universityExamScore;
      expect(puan, isNotNull, reason: 'Sınav puanı saklanmalı');
      expect(puan, inInclusiveRange(0, 100));
      expect(c.universityExamScore, puan,
          reason: 'Ekranın okuduğu puan kayıttaki puanla aynı olmalı');
      expect(
        state.log.any((dynamic e) => e.text.contains('Üniversite sınavından')),
        isTrue,
        reason: 'Puan hayat günlüğüne yazılmalı',
      );

      // Bir yıl daha geçince puan yeniden hesaplanmaz.
      advanceToAge(c, c.state!.player.age + 1);
      resolvePendingEvents(c);
      expect(c.state!.education.universityExamScore, puan);
    });

    test('lise yerleştirme puanı ile üniversite puanı ayrı alanlardır', () {
      final GameState state = mezun(6, placement: 62, exam: 78);
      expect(state.education.placementScore, 62);
      expect(state.education.universityExamScore, 78);
      expect(path.universityExamScore(state), 78,
          reason: 'Başvuru ekranı üniversite puanını göstermeli');
    });

    test('ekranda gösterilen puan başvuruda kullanılan puandır', () {
      final UniversityProgram bilgisayar = universityProgramById('bilgisayar')!;
      final GameState state =
          mezun(7, track: EducationTrack.bilisim, placement: 60, exam: 60);

      final int gosterilen = path.effectiveScore(state, bilgisayar);
      expect(gosterilen, path.effectiveScore(state, bilgisayar),
          reason: 'Puan rastgele değişmemeli');
      expect(
        gosterilen,
        60 + path.trackBonusFor(state, bilgisayar),
        reason: 'Gösterilen puan = sınav puanı + alan katkısı',
      );

      final EducationResult sonuc =
          path.applyToUniversity(state, bilgisayar, Random(3));
      expect(gosterilen >= bilgisayar.minScore, sonuc.outcome.accepted,
          reason: 'Kabul, ekranda yazan karşılaştırmanın sonucu olmalı');
    });

    test('puan yetmeyince gerekçe açıkça yazılır', () {
      final UniversityProgram muhendislik =
          universityProgramById('muhendislik')!;
      final GameState dusuk =
          mezun(8, track: EducationTrack.elSanatlari, placement: 30, exam: 30);

      final String gerekce = path.eligibilityReason(dusuk, muhendislik);
      expect(gerekce, contains('Puanın yetmiyor'));
      expect(gerekce, contains('${muhendislik.minScore}'),
          reason: 'Taban puan gerekçede görünmeli');

      final EducationResult sonuc =
          path.applyToUniversity(dusuk, muhendislik, Random(1));
      expect(sonuc.outcome.accepted, isFalse);
      expect(sonuc.state.education.universityProgramId, isNull);
    });

    test('kayıtlı puan yeniden hesaplanmaz', () {
      final GameState state = mezun(9, exam: 55);
      final GameState sonra = path.ensureUniversityExamScore(state, Random(2));
      expect(sonra.education.universityExamScore, 55);
    });

    test('puan kaydedilip geri okunur', () async {
      final GameState state = mezun(10, placement: 64, exam: 81);
      final GameState geri = await roundTrip(state);
      expect(geri.education.placementScore, 64);
      expect(geri.education.universityExamScore, 81);
    });

    test('desteklenen en eski sürümün kaydı üniversite puanı olmadan açılır', () async {
      final GameState orijinal = mezun(11, placement: 70, exam: 70);
      final Map<String, Object?> body = encodeGameState(orijinal);
      // Sürüm 6'da bu alanlar yoktu.
      (body['education']! as Map<String, Object?>)
          .remove('universityExamScore');
      body.remove('pendingInterview');

      final SaveLoadResult result = await SaveService(
        MemorySaveStore(
          initial: jsonEncode(
            <String, Object?>{'formatVersion': kMinReadableSaveVersion, 'state': body},
          ),
        ),
      ).load();
      expect(result.isLoaded, isTrue, reason: result.message);
      expect(result.state!.education.universityExamScore, isNull);
      expect(result.state!.education.placementScore, 70);
      expect(result.state!.pendingInterview, isNull);
    });
  });

  // ===================================================================
  // 2) Mülakat soruları
  // ===================================================================
  group('Mülakat soru havuzu', () {
    test('her mesleğin kendi soruları vardır', () {
      for (final JobType job in kJobCatalog) {
        final List<InterviewQuestion> sorular = questionsForJob(job.id);
        expect(sorular.length, greaterThanOrEqualTo(3),
            reason: '${job.name} için en az 3 soru olmalı');
        expect(sorular.length, lessThanOrEqualTo(5),
            reason: '${job.name} için en fazla 5 soru olmalı');
      }
    });

    test('sorular tek doğru cevaplı ve benzersiz kimliklidir', () {
      final Set<String> idler = <String>{};
      for (final InterviewQuestion soru in kInterviewQuestions) {
        expect(idler.add(soru.id), isTrue, reason: 'Tekrarlı id: ${soru.id}');
        expect(soru.options.length, greaterThanOrEqualTo(3));
        expect(soru.options.toSet().length, soru.options.length,
            reason: '${soru.id}: seçenekler birbirinden farklı olmalı');
        expect(soru.correctIndex, inInclusiveRange(0, soru.options.length - 1));
        expect(soru.explanation.trim(), isNotEmpty,
            reason: '${soru.id}: yanlış cevaptan sonra açıklama gösterilmeli');
      }
    });

    test('farklı mesleklere aynı soru sorulmaz', () {
      final Map<String, String> metinler = <String, String>{};
      for (final InterviewQuestion soru in kInterviewQuestions) {
        final String? oncekiIs = metinler[soru.text];
        expect(oncekiIs, isNull,
            reason: 'Aynı soru iki meslekte: ${soru.text}');
        metinler[soru.text] = soru.jobId;
      }
    });
  });

  // ===================================================================
  // 3) Başvuru ve mülakat akışı
  // ===================================================================
  group('İş başvurusu mülakatla sonuçlanır', () {
    final JobType magaza = jobById('magaza_calisani')!;
    final JobType yazilim = jobById('yazilim_gelistirici')!;

    test('başvuru doğrudan işe almaz, soru açar', () {
      final JobResult r = market.apply(mezun(20), magaza, Random(1));
      expect(r.outcome.applied, isTrue);
      expect(r.outcome.interviewStarted, isTrue);
      expect(r.outcome.accepted, isFalse);
      expect(r.state.career.isEmployed, isFalse);

      final PendingInterview? bekleyen = r.state.pendingInterview;
      expect(bekleyen, isNotNull);
      expect(bekleyen!.jobId, magaza.id);
      expect(bekleyen.question, isNotNull);
      expect(bekleyen.askedAtAge, r.state.player.age);
    });

    test('doğru cevap işe alır ve günlüğe yazılır', () {
      final JobResult basvuru = market.apply(mezun(21), magaza, Random(1));
      final InterviewQuestion soru = basvuru.state.pendingInterview!.question!;
      final JobResult sonuc =
          market.answerInterview(basvuru.state, soru.correctIndex);

      expect(sonuc.outcome.accepted, isTrue);
      expect(sonuc.state.career.jobId, magaza.id);
      expect(sonuc.state.pendingInterview, isNull,
          reason: 'Cevap verilince mülakat kapanmalı');
      expect(sonuc.state.log.last.text, contains('işe alındın'));
    });

    test('yanlış cevap işe almaz, doğru cevabı ve açıklamayı gösterir', () {
      final JobResult basvuru = market.apply(mezun(22), magaza, Random(1));
      final InterviewQuestion soru = basvuru.state.pendingInterview!.question!;
      final int yanlis = (soru.correctIndex + 1) % soru.options.length;
      final JobResult sonuc = market.answerInterview(basvuru.state, yanlis);

      expect(sonuc.outcome.accepted, isFalse);
      expect(sonuc.state.career.isEmployed, isFalse);
      expect(sonuc.outcome.correctAnswer, soru.correctOption);
      expect(sonuc.outcome.explanation, soru.explanation);
      expect(sonuc.state.pendingInterview, isNull);
      expect(sonuc.state.log.last.text, contains('olumsuz'));
    });

    test('cevap iki kez uygulanmaz', () {
      final JobResult basvuru = market.apply(mezun(23), magaza, Random(1));
      final InterviewQuestion soru = basvuru.state.pendingInterview!.question!;
      final JobResult ilk =
          market.answerInterview(basvuru.state, soru.correctIndex);
      expect(ilk.outcome.accepted, isTrue);

      final JobResult ikinci =
          market.answerInterview(ilk.state, soru.correctIndex);
      expect(ikinci.outcome.applied, isFalse);
      expect(ikinci.state.career.startedAtAge, ilk.state.career.startedAtAge);
      expect(ikinci.state.log.length, ilk.state.log.length,
          reason: 'İkinci cevap günlüğe yeniden yazılmamalı');
    });

    test('doğru cevap nitelik şartının yerine geçmez', () {
      final JobType ogretmen = jobById('ogretmen')!;
      final GameState hazir = mezun(
        24,
        universityFinished: true,
        programId: 'egitim',
        age: 23,
      );
      expect(market.meetsRequirements(hazir, ogretmen), isTrue);
      final JobResult basvuru = market.apply(hazir, ogretmen, Random(1));
      expect(basvuru.outcome.interviewStarted, isTrue);

      // Mülakat açıkken eğitim koşulu kaybolursa doğru cevap da işe almaz.
      final GameState bozulmus = basvuru.state.copyWith(
        education: basvuru.state.education.copyWith(
          universityFinished: false,
        ),
      );
      final InterviewQuestion soru = basvuru.state.pendingInterview!.question!;
      final JobResult sonuc =
          market.answerInterview(bozulmus, soru.correctIndex);

      expect(sonuc.outcome.accepted, isFalse);
      expect(sonuc.state.career.isEmployed, isFalse);
      expect(sonuc.state.pendingInterview, isNull);
    });

    test('eğitimi olmayan uzman işe başvuramaz', () {
      final GameState lise = mezun(25, track: EducationTrack.elSanatlari);
      expect(market.meetsRequirements(lise, yazilim), isFalse);
      final JobResult r = market.apply(lise, yazilim, Random(1));
      expect(r.outcome.applied, isFalse);
      expect(r.state.pendingInterview, isNull);
    });

    test('mülakat sürerken yeni başvuru açılmaz', () {
      final JobResult basvuru = market.apply(mezun(26), magaza, Random(1));
      final InteractionAvailability durum =
          market.applicationAvailability(basvuru.state, jobById('garson')!);
      expect(durum.isAllowed, isFalse);
      expect(durum.reason, contains('mülakat'));
    });

    test('vazgeçmek başvuru hakkını geri vermez', () {
      final JobResult basvuru = market.apply(mezun(27), magaza, Random(1));
      final JobResult iptal = market.cancelInterview(basvuru.state);
      expect(iptal.state.pendingInterview, isNull);
      expect(
        iptal.state.interactionCount(magaza.id, 'isBasvurusu'),
        1,
        reason: 'Yarıda bırakmak sayacı sıfırlamamalı',
      );
    });
  });

  // ===================================================================
  // 4) Tekrar başvuru ve soru ezberi
  // ===================================================================
  group('Aynı yaşta sınırsız başvuru yapılamaz', () {
    final JobType magaza = jobById('magaza_calisani')!;

    test('başvuru sayısı sınırlıdır ve sorular tekrarlanmaz', () {
      GameState state = mezun(30);
      final List<String> sorulan = <String>[];

      for (int i = 0; i < 5; i++) {
        final JobResult r = market.apply(state, magaza, Random(i));
        if (!r.outcome.applied) break;
        final InterviewQuestion soru = r.state.pendingInterview!.question!;
        sorulan.add(soru.id);
        final int yanlis = (soru.correctIndex + 1) % soru.options.length;
        state = market.answerInterview(r.state, yanlis).state;
      }

      expect(sorulan.length, JobMarket.prototypeOnlyMaxApplicationsPerAge);
      expect(sorulan.toSet().length, sorulan.length,
          reason: 'Aynı yaşta aynı soru tekrar sorulmamalı');

      final InteractionAvailability durum =
          market.applicationAvailability(state, magaza);
      expect(durum.isAllowed, isFalse);
      // D-091: gerekçe artık işin adını ve ne zaman açılacağını yazıyor.
      expect(durum.reason, contains('gelecek yılı'));
      expect(durum.reason, contains(magaza.name));
      // Başka mesleklere başvuru kapanmaz.
      expect(durum.reason, contains('Başka mesleklere'));
    });

    test('bir mülakat kaybedince aynı iş o yıl kapanır, diğerleri açık kalır',
        () {
      // Faho'nun isteği: "mülakatta başarısız olduysam aynı yıl aynı işe
      // yeniden başvuramayayım".
      GameState state = mezun(30);
      final JobResult r = market.apply(state, magaza, Random(1));
      expect(r.outcome.applied, isTrue);
      final InterviewQuestion soru = r.state.pendingInterview!.question!;
      final int yanlis = (soru.correctIndex + 1) % soru.options.length;
      state = market.answerInterview(r.state, yanlis).state;

      expect(
        market.applicationAvailability(state, magaza).isAllowed,
        isFalse,
        reason: 'Kaybedilen iş o yıl kapanmalı',
      );

      // Başka bir iş hâlâ açık olmalı.
      final List<JobType> digerleri = market
          .openJobs(state)
          .where((JobType j) => j.id != magaza.id)
          .toList(growable: false);
      expect(digerleri, isNotEmpty);
      expect(
        market.applicationAvailability(state, digerleri.first).isAllowed,
        isTrue,
        reason: 'Başka mesleklere başvuru kapanmamalı',
      );
    });

    test('kilit kapat-aç ile korunur ve yeni yaşta açılır', () {
      GameState state = mezun(30);
      final JobResult r = market.apply(state, magaza, Random(2));
      final InterviewQuestion soru = r.state.pendingInterview!.question!;
      final int yanlis = (soru.correctIndex + 1) % soru.options.length;
      state = market.answerInterview(r.state, yanlis).state;

      final GameState geri = decodeGameState(encodeGameState(state));
      expect(
        market.applicationAvailability(geri, magaza).isAllowed,
        isFalse,
        reason: 'Kilit kayıtta korunmalı',
      );

      // Yeni yaşta sayaç sıfırlanır.
      final GameState yeniYas = geri.copyWith(
        player: geri.player.copyWith(age: geri.player.age + 1),
        interactionCounts: const <String, int>{},
      );
      expect(
        market.applicationAvailability(yeniYas, magaza).isAllowed,
        isTrue,
      );
    });
  });

  // ===================================================================
  // 5) Kaydet / yükle ve maaş
  // ===================================================================
  group('Mülakat kaydı ve maaş', () {
    final JobType magaza = jobById('magaza_calisani')!;

    test('oyun kapatılıp açılınca soru değişmez', () async {
      final JobResult basvuru = market.apply(mezun(40), magaza, Random(4));
      final PendingInterview once = basvuru.state.pendingInterview!;

      final GameState geri = await roundTrip(basvuru.state);
      final PendingInterview? sonra = geri.pendingInterview;
      expect(sonra, isNotNull);
      expect(sonra!.jobId, once.jobId);
      expect(sonra.questionId, once.questionId);
      expect(sonra.askedAtAge, once.askedAtAge);
      expect(sonra.question!.text, once.question!.text);
      expect(sonra.question!.options, once.question!.options);

      // Yükledikten sonra verilen cevap normal şekilde sonuçlanır.
      final JobResult sonuc =
          market.answerInterview(geri, sonra.question!.correctIndex);
      expect(sonuc.outcome.accepted, isTrue);
      expect(sonuc.state.career.jobId, magaza.id);
    });

    test('işe girilen yıl maaş ödenmez, sonraki yıl bir kez ödenir', () {
      final JobResult basvuru = market.apply(mezun(41, age: 20), magaza,
          Random(1));
      final InterviewQuestion soru = basvuru.state.pendingInterview!.question!;
      final GameState ise =
          market.answerInterview(basvuru.state, soru.correctIndex).state;

      final CareerState career = ise.career;
      expect(career.lastPaidAge, 20, reason: 'İşe girilen yıl maaş ödenmez');

      final int cuzdan = ise.player.wallet;
      final ({GameState state, String? logText}) ayniYil =
          market.paySalaryFor(ise, 20);
      expect(ayniYil.logText, isNull);
      expect(ayniYil.state.player.wallet, cuzdan);

      final ({GameState state, String? logText}) sonrakiYil =
          market.paySalaryFor(ise, 21);
      expect(sonrakiYil.logText, isNotNull);
      expect(sonrakiYil.state.player.wallet, cuzdan + magaza.yearlySalary);

      // Aynı yaş ikinci kez ödenmez.
      final ({GameState state, String? logText}) tekrar =
          market.paySalaryFor(sonrakiYil.state, 21);
      expect(tekrar.logText, isNull);
      expect(tekrar.state.player.wallet, sonrakiYil.state.player.wallet);
    });

    test('mülakatı geçmek aynı yıl çift maaş ödetmez', () {
      final GameController c = GameController(random: Random(42));
      c.startNewLife(mode: StartMode.tamamenRastgele, seed: 42);
      final JobResult basvuru = market.apply(mezun(42, age: 22), magaza,
          Random(1));
      final InterviewQuestion soru = basvuru.state.pendingInterview!.question!;
      final GameState ise =
          market.answerInterview(basvuru.state, soru.correctIndex).state;

      c.debugSetState(ise);
      final int cuzdan = c.state!.player.wallet;
      advanceToAge(c, 23);
      resolvePendingEvents(c);

      final int kazanc = c.state!.player.wallet - cuzdan;
      expect(kazanc, lessThan(magaza.yearlySalary * 2),
          reason: 'Bir yılda iki kez maaş ödenmemeli');
      expect(c.state!.career.lastPaidAge, 23);
    });
  });
}
