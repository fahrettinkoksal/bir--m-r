import 'dart:math';

import 'package:bir_omur/data/event_pool.dart';
import 'package:bir_omur/data/event_pool_exam.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/data/save/save_format.dart';
import 'package:bir_omur/domain/education/education_path.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/generation/life_progression.dart';
import 'package:bir_omur/domain/life/notices.dart';
import 'package:bir_omur/domain/models/education.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/invariants.dart';

/// Belirli bir sınıfta okuyan öğrenci.
GameState ogrenci({
  int seed = 91,
  int age = 13,
  int grade = 8,
  int? average = 70,
  int intelligence = 60,
  Set<String> flags = const <String>{},
}) {
  final GameState base =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  return base.copyWith(
    pendingEvent: null,
    notices: const <PendingNotice>[],
    storyFlags: flags,
    player: base.player.copyWith(
      age: age,
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

/// Bildirimler arasında verilen kimliği arar.
PendingNotice? bildirim(GameState state, String id) {
  for (final PendingNotice n in state.notices) {
    if (n.id == id) return n;
  }
  return null;
}

void main() {
  // ===================================================================
  // Okul dönüm noktası bildirimleri
  // ===================================================================
  group('Okul bildirimleri', () {
    test('okula başlayınca bildirim çıkar', () {
      final GameState base =
          LifeGenerator.seeded(5).generate(mode: StartMode.tamamenRastgele);
      GameState s = base.copyWith(
        pendingEvent: null,
        notices: const <PendingNotice>[],
        player: base.player.copyWith(age: 5),
        education: const EducationState.notStarted(),
      );

      s = LifeProgression(Random(5)).advanceOneYear(s);

      expect(s.education.enrolled, isTrue);
      final PendingNotice? n = bildirim(s, Notices.schoolStartNoticeId);
      expect(n, isNotNull, reason: 'Okula başlama bildirilmeli.');
      expect(n!.kind, NoticeKind.okul);
      expect(n.text, contains('birinci sınıf'));
      checkInvariants(s);
    });

    test('liseye geçişte bildirim çıkar ve yerleştirme puanını yazar', () {
      GameState s = ogrenci(age: 13, grade: 8);

      s = LifeProgression(Random(11)).advanceOneYear(s);

      expect(s.education.grade, 9);
      final PendingNotice? n = bildirim(s, Notices.highSchoolStartNoticeId);
      expect(n, isNotNull, reason: 'Liseye geçiş bildirilmeli.');
      expect(s.education.placementScore, isNotNull);
      expect(n!.text, contains('${s.education.placementScore}'));
      checkInvariants(s);
    });

    test('lise bitince bildirim çıkar ve sınav puanını yazar', () {
      GameState s = ogrenci(age: 17, grade: 12);

      s = LifeProgression(Random(13)).advanceOneYear(s);

      expect(s.education.finished, isTrue);
      final PendingNotice? n = bildirim(s, Notices.highSchoolEndNoticeId);
      expect(n, isNotNull, reason: 'Lise bitişi bildirilmeli.');
      expect(s.education.universityExamScore, isNotNull);
      expect(n!.text, contains('${s.education.universityExamScore}'));
      checkInvariants(s);
    });

    test('aynı bildirim iki kez kuyruğa girmez', () {
      final GameState s = ogrenci(age: 13, grade: 8);
      final GameState bir = LifeProgression(Random(11)).advanceOneYear(s);
      final GameState iki = Notices.enqueue(bir, <PendingNotice>[
        Notices.highSchoolStart(playerAge: 14, placementScore: 50),
      ]);

      final int sayi = iki.notices
          .where((PendingNotice n) => n.id == Notices.highSchoolStartNoticeId)
          .length;
      expect(sayi, 1);
    });

    test('ilkokuldan ortaokula geçişte bildirim çıkmaz', () {
      // Faho yalnızca üç dönüm noktası istedi: okula başlama, liseye
      // geçiş ve lise bitişi. 4 → 5. sınıf günlükte kalır.
      GameState s = ogrenci(age: 9, grade: 4);
      s = LifeProgression(Random(17)).advanceOneYear(s);

      expect(s.education.grade, 5);
      expect(
        s.notices.where((PendingNotice n) => n.kind == NoticeKind.okul),
        isEmpty,
      );
    });

    test('okul bildirimi kayıt turunda kaybolmaz', () {
      GameState s = ogrenci(age: 17, grade: 12);
      s = LifeProgression(Random(13)).advanceOneYear(s);
      expect(bildirim(s, Notices.highSchoolEndNoticeId), isNotNull);

      final Map<String, Object?> json = encodeGameState(s);
      final GameState geri = decodeGameState(
        SaveMigrations.migrate(json, kSaveFormatVersion),
      );

      final PendingNotice? n = bildirim(geri, Notices.highSchoolEndNoticeId);
      expect(n, isNotNull);
      expect(n!.kind, NoticeKind.okul);
      expect(n.text, contains('Lise bitti'));
    });

    test('bildirim metni uydurma puan yazmaz', () {
      final PendingNotice n = Notices.highSchoolEnd(playerAge: 18);
      expect(n.text, isNot(contains('puan')));
      final PendingNotice m = Notices.highSchoolStart(playerAge: 14);
      expect(m.text, isNot(contains('Yerleştirme puanın')));
    });
  });

  // ===================================================================
  // Sınav dönemi olayları
  // ===================================================================
  group('Sınav dönemi', () {
    test('olay kimlikleri benzersiz ve havuzda kayıtlı', () {
      final Set<String> kimlikler = <String>{};
      for (final GameEvent e in kExamEvents) {
        expect(kimlikler.add(e.id), isTrue, reason: 'Tekrar eden kimlik: ${e.id}');
      }
      for (final GameEvent e in kExamEvents) {
        expect(
          kEventPool.where((GameEvent a) => a.id == e.id).length,
          1,
          reason: '${e.id} ana havuzda tam olarak bir kez olmalı.',
        );
      }
    });

    test('her olay yalnızca sınav sınıflarında çıkar', () {
      for (final GameEvent e in kExamEvents) {
        final EventRequirement r = e.requirement;
        expect(r.requiresSchoolStudent, isTrue, reason: e.id);
        expect(r.minGrade, r.maxGrade, reason: '${e.id} tek sınıfa bağlı olmalı');
        expect(
          ExamYear.isExamGrade(r.minGrade),
          isTrue,
          reason: '${e.id} sınav sınıfına bağlı değil',
        );
      }
    });

    test('her seçenek özgün bir sonuç metni taşır', () {
      final Set<String> metinler = <String>{};
      for (final GameEvent e in kExamEvents) {
        expect(e.choices.length, greaterThanOrEqualTo(2), reason: e.id);
        for (final EventChoice c in e.choices) {
          expect(
            metinler.add(c.resultText),
            isTrue,
            reason: 'Aynı sonuç metni iki kez: ${e.id}/${c.id}',
          );
        }
      }
    });

    test('iki olay önceki kararı hatırlar', () {
      final List<GameEvent> hatirlayan = kExamEvents
          .where((GameEvent e) => e.requirement.requiredFlags.isNotEmpty)
          .toList();
      expect(hatirlayan.length, greaterThanOrEqualTo(2));
    });

    test('sınav sınıfı yalnızca 8 ve 12', () {
      expect(ExamYear.isExamGrade(8), isTrue);
      expect(ExamYear.isExamGrade(12), isTrue);
      expect(ExamYear.isExamGrade(7), isFalse);
      expect(ExamYear.isExamGrade(11), isFalse);
      expect(ExamYear.isExamGrade(null), isFalse);
    });
  });

  // ===================================================================
  // Sınav kararlarının puana etkisi
  // ===================================================================
  group('Sınav hazırlığının puana etkisi', () {
    test('odaklanmak dengeli çalışmadan, o da savsaklamaktan iyidir', () {
      int etki(String bayrak) => EducationPath.prototypeOnlyExamPrep(
            <String>{bayrak},
            university: false,
          );

      expect(etki(ExamFlags.ortaokulOdaklandi),
          greaterThan(etki(ExamFlags.ortaokulDengeli)));
      expect(etki(ExamFlags.ortaokulDengeli), greaterThan(0));
      expect(etki(ExamFlags.ortaokulSavsakladi), lessThan(0));
      expect(etki(ExamFlags.ortaokulKaygi), lessThan(0));
    });

    test('ortaokul izi üniversite sınavını etkilemez', () {
      final Set<String> ortaokul = <String>{
        ExamFlags.ortaokulOdaklandi,
        ExamFlags.ortaokulDestek,
      };
      expect(
        EducationPath.prototypeOnlyExamPrep(ortaokul, university: true),
        0,
      );
      expect(
        EducationPath.prototypeOnlyExamPrep(ortaokul, university: false),
        greaterThan(0),
      );
    });

    test('kararsız oyuncuda etki sıfırdır', () {
      expect(
        EducationPath.prototypeOnlyExamPrep(
          const <String>{'alakasiz_bayrak'},
          university: false,
        ),
        0,
      );
    });

    test('yerleştirme puanı sınav yılı kararıyla gerçekten değişir', () {
      const EducationPath yol = EducationPath();
      final GameState notr = ogrenci(age: 13, grade: 8);
      final GameState calisan = ogrenci(
        age: 13,
        grade: 8,
        flags: <String>{ExamFlags.ortaokulOdaklandi},
      );
      final GameState savsaklayan = ogrenci(
        age: 13,
        grade: 8,
        flags: <String>{ExamFlags.ortaokulSavsakladi},
      );

      // Aynı tohum: fark yalnızca sınav yılı kararından gelir.
      final int a = yol.placementScore(notr, Random(4));
      final int b = yol.placementScore(calisan, Random(4));
      final int c = yol.placementScore(savsaklayan, Random(4));

      expect(b, greaterThan(a));
      expect(c, lessThan(a));
    });

    test('üniversite sınav puanı lise son kararıyla gerçekten değişir', () {
      const EducationPath yol = EducationPath();
      final GameState notr = ogrenci(age: 17, grade: 12);
      final GameState calisan = ogrenci(
        age: 17,
        grade: 12,
        flags: <String>{ExamFlags.liseOdaklandi},
      );
      final GameState savsaklayan = ogrenci(
        age: 17,
        grade: 12,
        flags: <String>{ExamFlags.liseSavsakladi},
      );

      final int a = yol.computeUniversityExamScore(notr, Random(6));
      final int b = yol.computeUniversityExamScore(calisan, Random(6));
      final int c = yol.computeUniversityExamScore(savsaklayan, Random(6));

      expect(b, greaterThan(a));
      expect(c, lessThan(a));
    });

    test('puan 0-100 dışına çıkmaz', () {
      const EducationPath yol = EducationPath();
      final GameState kotu = ogrenci(
        age: 17,
        grade: 12,
        average: 0,
        intelligence: 1,
        flags: <String>{
          ExamFlags.liseSavsakladi,
          ExamFlags.liseKaygi,
        },
      );
      final GameState iyi = ogrenci(
        age: 17,
        grade: 12,
        average: 100,
        intelligence: 100,
        flags: <String>{
          ExamFlags.liseOdaklandi,
          ExamFlags.liseDengeli,
          ExamFlags.liseDestek,
        },
      );
      expect(yol.computeUniversityExamScore(kotu, Random(7)), inInclusiveRange(0, 100));
      expect(yol.computeUniversityExamScore(iyi, Random(7)), inInclusiveRange(0, 100));
    });
  });
}
