import 'dart:math';

import 'package:bir_omur/data/economy.dart';
import 'package:bir_omur/data/interview_catalog.dart';
import 'package:bir_omur/data/job_catalog.dart';
import 'package:bir_omur/domain/career/job_market.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/career.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_flow.dart';

const JobMarket pazar = JobMarket();

/// Lise öğrencisi bir durum kurar.
GameState ogrenci(int seed, {int age = 16}) {
  final GameState s =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  return s.copyWith(
    player: s.player.copyWith(age: age),
    education: s.education.copyWith(
      enrolled: true,
      grade: 10,
      startedAtAge: 6,
    ),
    pendingEvent: null,
  );
}

List<JobType> get yarimZamanlilar =>
    kJobCatalog.where((JobType j) => j.partTime).toList(growable: false);

void main() {
  test('katalogda yarım zamanlı iş var', () {
    expect(yarimZamanlilar, isNotEmpty);
    expect(yarimZamanlilar.length, greaterThanOrEqualTo(6));
  });

  test('yarım zamanlı işlerin hepsi yarım zamanlı bandında', () {
    for (final JobType j in yarimZamanlilar) {
      expect(
        j.band,
        SalaryBand.yarimZamanli,
        reason: '${j.id} yanlış bantta.',
      );
      // Tam zamanlı en düşük işten az kazandırır: yarım gün, yarım para.
      expect(
        j.yearlySalary,
        lessThan(SalaryBand.giris.minYearly),
        reason: '${j.id} yarım zamanlı için fazla kazandırıyor.',
      );
    }
  });

  test('yarım zamanlı banda asgari ücret tabanı uygulanmaz', () {
    // Tam ay çalışılmadığı için sabit maaş kuralı bu banda işlemez.
    expect(SalaryBand.yarimZamanli.sabitMaasli, isFalse);
  });

  test('her yarım zamanlı işin mülakat sorusu var', () {
    for (final JobType j in yarimZamanlilar) {
      final Iterable<InterviewQuestion> sorular =
          kInterviewQuestions.where((InterviewQuestion q) => q.jobId == j.id);
      expect(sorular, isNotEmpty, reason: '${j.id} için soru yok.');
    }
  });

  group('öğrenci ve iş', () {
    test('öğrenci yarım zamanlı işe başvurabilir', () {
      final GameState s = ogrenci(1);
      final JobType market = jobById('yz_market_reyon')!;
      expect(
        pazar.requirementReason(s, market),
        isEmpty,
        reason: 'Öğrenciye yarım zamanlı iş kapalı kalmamalı.',
      );
    });

    test('öğrenci tam zamanlı işe başvuramaz ve gerekçe yazılır', () {
      final GameState s = ogrenci(2);
      final JobType garson = jobById('garson')!;
      final String gerekce = pazar.requirementReason(s, garson);
      expect(gerekce, isNotEmpty);
      // Gerekçe yolu da gösterir (D-063).
      expect(gerekce, contains('Yarım zamanlı'));
    });

    test('yaşı küçük olan yarım zamanlı işe de başvuramaz', () {
      final GameState s = ogrenci(3, age: 13);
      final JobType market = jobById('yz_market_reyon')!;
      expect(pazar.requirementReason(s, market), isNotEmpty);
    });

    test('mezun da yarım zamanlı iş yapabilir', () {
      // Yarım zamanlı iş yalnızca öğrenciye ait değil.
      final GameState s = ogrenci(4, age: 20).copyWith(
        education: ogrenci(4).education.copyWith(
              enrolled: false,
              finished: true,
            ),
      );
      final JobType market = jobById('yz_market_reyon')!;
      expect(pazar.requirementReason(s, market), isEmpty);
    });

    test('ehliyet isteyen yarım zamanlı iş ehliyetsize kapalı', () {
      final GameState s = ogrenci(5, age: 18);
      final JobType kurye = jobById('yz_kurye')!;
      expect(pazar.requirementReason(s, kurye), isNotEmpty);
    });
  });

  group('okurken çalışmanın bedeli', () {
    test('yarım zamanlı çalışan öğrenci yılda sağlık kaybeder', () {
      final GameController c = GameController(random: Random(9));
      c.startNewLife(mode: StartMode.tamamenRastgele, seed: 9);
      c.debugSetState(
        ogrenci(9, age: 16).copyWith(
          career: const CareerState(
            jobId: 'yz_market_reyon',
            startedAtAge: 16,
            salary: 132000,
          ),
          player: ogrenci(9, age: 16).player.copyWith(),
        ),
      );
      final int oncekiSaglik = c.state!.player.stats.health;
      resolveEducationChoices(c);
      c.ageUp();
      resolvePendingEvents(c);
      // Yaşlanmanın kendi etkisi de var; burada aranan şey günlükte
      // bedelin **gerçekten yazılmış** olması.
      expect(
        c.state!.log.any(
          (dynamic e) => (e.text as String).contains('Okul ve iş bir arada'),
        ),
        isTrue,
        reason: 'Okurken çalışmanın bedeli günlüğe yazılmadı.',
      );
      expect(c.state!.player.stats.health, lessThanOrEqualTo(oncekiSaglik));
      c.dispose();
    });

    test('çalışmayan öğrenciye bedel yazılmaz', () {
      final GameController c = GameController(random: Random(10));
      c.startNewLife(mode: StartMode.tamamenRastgele, seed: 10);
      c.debugSetState(ogrenci(10, age: 16));
      resolveEducationChoices(c);
      c.ageUp();
      resolvePendingEvents(c);
      expect(
        c.state!.log.any(
          (dynamic e) => (e.text as String).contains('Okul ve iş bir arada'),
        ),
        isFalse,
      );
      c.dispose();
    });
  });

  test('yarım zamanlı iş gerçekten para kazandırır', () {
    // Maaş ödemesi mevcut sistemden geçer; ayrı bir yol kurulmadı.
    final JobType market = jobById('yz_market_reyon')!;
    expect(market.yearlySalary, greaterThan(0));
    expect(market.monthlySalary, Economy.monthlyOf(market.yearlySalary));
  });
}
