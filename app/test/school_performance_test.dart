import 'dart:math';

import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/data/save/save_format.dart';
import 'package:bir_omur/domain/education/education_path.dart';
import 'package:bir_omur/domain/education/school_performance.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/generation/life_progression.dart';
import 'package:bir_omur/domain/models/education.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/invariants.dart';

/// Belirli bir sınıfta, belirli bir ortalamayla okuyan öğrenci.
GameState ogrenci({
  int seed = 131,
  int age = 16,
  int grade = 10,
  int? average,
  int intelligence = 60,
  int wallet = 0,
}) {
  final GameState base =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  return base.copyWith(
    pendingEvent: null,
    player: base.player.copyWith(
      age: age,
      wallet: wallet,
      stats: base.player.stats.copyWith(intelligence: intelligence),
    ),
    education: EducationState(
      enrolled: true,
      grade: grade,
      startedAtAge: 6,
      gradeAverage: average,
    ),
  );
}

void main() {
  // ===================================================================
  // Ders çalışma
  // ===================================================================
  group('Ders çalışma', () {
    test('okula gitmeyen ders çalışamaz', () {
      final GameState calisan = ogrenci().copyWith(
        education: const EducationState(finished: true, startedAtAge: 6),
      );
      expect(SchoolPerformance.studyAvailability(calisan).isAllowed, isFalse);
      final StudyResult r = SchoolPerformance.study(calisan, Random(1));
      expect(r.applied, isFalse);
      expect(r.state.education.gradeAverage, isNull);
    });

    test('ders çalışmak ortalamayı ve zekâyı artırır', () {
      final GameState s = ogrenci(average: 50);
      final StudyResult r = SchoolPerformance.study(s, Random(2));

      expect(r.applied, isTrue);
      expect(r.state.education.gradeAverage, greaterThan(50));
      expect(
        r.state.player.stats.intelligence,
        greaterThan(s.player.stats.intelligence),
      );
      // Çalışmak biraz yorar.
      expect(
        r.state.player.stats.happiness,
        lessThan(s.player.stats.happiness),
      );
      expect(checkInvariants(r.state), isEmpty);
    });

    test('bir yılda sınırsız çalışılamaz', () {
      GameState s = ogrenci(average: 50);
      for (int i = 0; i < SchoolPerformance.prototypeOnlyStudyPerYear; i++) {
        s = SchoolPerformance.study(s, Random(i)).state;
      }
      final StudyResult fazladan = SchoolPerformance.study(s, Random(9));
      expect(fazladan.applied, isFalse);
      // Yeni yılda hak yenilenir.
      final GameState yeniYil =
          s.copyWith(interactionCounts: const <String, int>{});
      expect(SchoolPerformance.studyAvailability(yeniYil).isAllowed, isTrue);
    });

    test('ortalama 100 sınırını aşmaz', () {
      GameState s = ogrenci(average: 99);
      for (int i = 0; i < 6; i++) {
        s = SchoolPerformance.study(
          s.copyWith(interactionCounts: const <String, int>{}),
          Random(i),
        ).state;
      }
      expect(s.education.gradeAverage, lessThanOrEqualTo(100));
    });
  });

  // ===================================================================
  // Not ortalaması ve sınıfta kalma
  // ===================================================================
  group('Not ortalaması', () {
    test('okula başlayan öğrencinin ortalaması oluşur', () {
      final GameState bebek =
          LifeGenerator.seeded(132).generate(mode: StartMode.tamamenRastgele);
      GameState s = bebek.copyWith(
        pendingEvent: null,
        player: bebek.player.copyWith(age: 5),
      );
      s = LifeProgression(Random(3)).advanceOneYear(s);

      expect(s.education.enrolled, isTrue);
      expect(s.education.gradeAverage, isNotNull);
      expect(s.education.gradeAverage, inInclusiveRange(0, 100));
    });

    test('ilkokulda düşük not sınıfta bırakmaz', () {
      GameState s = ogrenci(age: 8, grade: 2, average: 10, intelligence: 10);
      s = LifeProgression(Random(4)).advanceOneYear(s);

      expect(s.education.grade, 3, reason: 'İlkokulda sınıf tekrarı yok');
      expect(s.education.repeatedYears, 0);
      expect(s.education.droppedOut, isFalse);
    });

    test('lisede düşük not sınıfta bırakır', () {
      GameState s = ogrenci(age: 16, grade: 10, average: 10, intelligence: 8);
      final int sinif = s.education.grade!;
      s = LifeProgression(Random(5)).advanceOneYear(s);

      expect(s.education.grade, sinif, reason: 'Sınıf ilerlememeli');
      expect(s.education.repeatedYears, 1);
      expect(
        s.log.any((dynamic e) => (e.text as String).contains('sınıfta kaldın')),
        isTrue,
      );
    });

    test('üst üste kalan öğrencinin okulla yolları ayrılır', () {
      GameState s = ogrenci(age: 16, grade: 10, average: 5, intelligence: 5)
          .copyWith(
        education: ogrenci(age: 16, grade: 10, average: 5).education.copyWith(
              repeatedYears: SchoolPerformance.prototypeOnlyMaxRepeats,
            ),
      );
      s = LifeProgression(Random(6)).advanceOneYear(s);

      expect(s.education.droppedOut, isTrue);
      expect(s.education.enrolled, isFalse);
      // Geçmiş silinmez.
      expect(s.education.startedAtAge, isNotNull);
      expect(
        s.log.any((dynamic e) =>
            (e.text as String).contains('yolların ayrıldı')),
        isTrue,
      );
    });

    test('çalışan öğrenci kazandığını korur', () {
      GameState s = ogrenci(age: 16, grade: 10, average: 50, intelligence: 50);
      s = SchoolPerformance.study(s, Random(7)).state;
      final int calismali = s.education.gradeAverage!;
      expect(calismali, greaterThan(50));

      // Yıl sonunda ortalama zekâya doğru kayar ama sıfırlanmaz.
      s = LifeProgression(Random(8)).advanceOneYear(s);
      expect(s.education.gradeAverage, greaterThan(30));
    });
  });

  // ===================================================================
  // Burs
  // ===================================================================
  group('Burs', () {
    test('ortalaması düşük öğrenci burs almaz', () {
      final GameState s = ogrenci(age: 16, grade: 10, average: 60);
      expect(SchoolPerformance.deservesScholarship(s.education), isFalse);
      expect(SchoolPerformance.payScholarship(s, 17), isNull);
    });

    test('ortaokulda yüksek not burs getirmez', () {
      final GameState s = ogrenci(age: 13, grade: 7, average: 95);
      expect(SchoolPerformance.deservesScholarship(s.education), isFalse);
    });

    test('lisede yüksek not burs getirir ve cüzdana girer', () {
      final GameState s = ogrenci(age: 16, grade: 10, average: 90, wallet: 0);
      expect(SchoolPerformance.deservesScholarship(s.education), isTrue);

      final ({GameState state, String logText})? burs =
          SchoolPerformance.payScholarship(s, 17);
      expect(burs, isNotNull);
      expect(
        burs!.state.player.wallet,
        SchoolPerformance.prototypeOnlyScholarshipAmount,
      );
      expect(burs.state.education.scholarshipSinceAge, 17);
      expect(burs.logText, contains('burs'));
    });

    test('burs yaş alma akışında yılda bir kez ödenir', () {
      GameState s = ogrenci(age: 16, grade: 10, average: 95,
          intelligence: 95, wallet: 0);
      s = LifeProgression(Random(9)).advanceOneYear(s);

      final Iterable<String> satirlar =
          s.log.map((dynamic e) => e.text as String);
      expect(
        satirlar.where((String t) => t.contains('burs')),
        hasLength(1),
      );
      expect(s.player.wallet, greaterThan(0));
    });

    test('okuldan ayrılan burs almaz', () {
      final GameState s = ogrenci(age: 17, grade: 11, average: 95).copyWith(
        education: ogrenci(age: 17, grade: 11, average: 95)
            .education
            .copyWith(droppedOut: true, enrolled: false),
      );
      expect(SchoolPerformance.deservesScholarship(s.education), isFalse);
    });
  });

  // ===================================================================
  // Sınav puanlarına etkisi ve kayıt
  // ===================================================================
  group('Sınavlar ve kayıt', () {
    test('not ortalaması yerleştirme puanını etkiler', () {
      const EducationPath path = EducationPath();
      final GameState iyi =
          ogrenci(age: 14, grade: 8, average: 95, intelligence: 60);
      final GameState kotu =
          ogrenci(age: 14, grade: 8, average: 30, intelligence: 60);

      expect(
        path.placementScore(iyi, Random(1)),
        greaterThan(path.placementScore(kotu, Random(1))),
      );
    });

    test('not ortalaması üniversite sınav puanını etkiler', () {
      const EducationPath path = EducationPath();
      final GameState iyi = ogrenci(age: 18, grade: 12, average: 95)
          .copyWith(
        education: ogrenci(age: 18, grade: 12, average: 95)
            .education
            .copyWith(placementScore: 60),
      );
      final GameState kotu = ogrenci(age: 18, grade: 12, average: 30)
          .copyWith(
        education: ogrenci(age: 18, grade: 12, average: 30)
            .education
            .copyWith(placementScore: 60),
      );

      expect(
        path.computeUniversityExamScore(iyi, Random(1)),
        greaterThan(path.computeUniversityExamScore(kotu, Random(1))),
      );
    });

    test('okul başarısı kapat-aç ile korunur', () {
      final GameState s = ogrenci(age: 17, grade: 11, average: 84).copyWith(
        education: ogrenci(age: 17, grade: 11, average: 84).education.copyWith(
              repeatedYears: 1,
              scholarshipSinceAge: 16,
            ),
      );
      final GameState geri = decodeGameState(encodeGameState(s));

      expect(geri.education.gradeAverage, 84);
      expect(geri.education.repeatedYears, 1);
      expect(geri.education.scholarshipSinceAge, 16);
      expect(geri.education.droppedOut, isFalse);
    });

    test('kayıt sürümü 29 ve eski kayıtta not ortalaması yoktur', () {
      expect(kSaveFormatVersion, 29);
      final GameState s = ogrenci(age: 17, grade: 11, average: 70);
      final Map<String, Object?> body =
          Map<String, Object?>.from(encodeGameState(s));
      final Map<String, Object?> egitim =
          Map<String, Object?>.from(body['education']! as Map<String, Object?>)
            ..remove('gradeAverage')
            ..remove('repeatedYears')
            ..remove('droppedOut')
            ..remove('scholarshipSinceAge');
      body['education'] = egitim;

      final GameState geri =
          decodeGameState(SaveMigrations.migrate(body, 26));
      // Geriye dönük not uydurulmaz.
      expect(geri.education.gradeAverage, isNull);
      expect(geri.education.repeatedYears, 0);
      expect(geri.education.droppedOut, isFalse);
      expect(geri.education.grade, 11);
    });

    test('mezuniyette not ortalaması ve burs geçmişi korunur', () {
      final EducationState mezun = ogrenci(age: 18, grade: 12, average: 88)
          .education
          .copyWith(scholarshipSinceAge: 15)
          .asFinished();

      expect(mezun.finished, isTrue);
      expect(mezun.gradeAverage, 88);
      expect(mezun.scholarshipSinceAge, 15);
    });
  });
}
