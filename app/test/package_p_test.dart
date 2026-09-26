
import 'package:bir_omur/data/job_catalog.dart';
import 'package:bir_omur/data/martial_arts_catalog.dart';
import 'package:bir_omur/domain/activities/activity_engine.dart';
import 'package:bir_omur/domain/activities/martial_arts_engine.dart';
import 'package:bir_omur/domain/career/job_market.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/life/aging.dart';
import 'package:bir_omur/domain/life/sick_leave.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:flutter_test/flutter_test.dart';

/// Paket P: statların gerçekten hissedilmesi (D-113 … D-116).
void main() {
  GameState taban({int seed = 7, int age = 30, int wallet = 5000000}) {
    final GameState base =
        LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
    return base.copyWith(
      pendingEvent: null,
      player: base.player.copyWith(age: age, wallet: wallet),
    );
  }

  group('Dövüş dersinin yıllık stat tavanı (D-115)', () {
    test('yirmi ders bir yılda ham kırk sağlık veremez', () {
      // Faho bildirdi: "20 dersi birden aldığımda mutluluğum ve sağlığım
      // çok fazla artıyor". Ders sayısı sınırlıydı, kazancın toplamı değil.
      const MartialArtsEngine motor = MartialArtsEngine();
      final MartialArt sanat = MartialArt.values.first;
      GameState s = taban();
      final int oncekiSaglik = s.player.stats.health;
      final int oncekiMutluluk = s.player.stats.happiness;

      for (int i = 0; i < kMaxMartialLessonsPerAge; i++) {
        final ActivityResult r = motor.takeLesson(state: s, art: sanat);
        if (!r.outcome.applied) break;
        s = r.state;
      }

      final int saglikArtisi = s.player.stats.health - oncekiSaglik;
      final int mutlulukArtisi = s.player.stats.happiness - oncekiMutluluk;

      // Basamak atlama ödülü tavanın dışındadır; onunla birlikte bile
      // eski 40 ham puanın çok altında kalmalı.
      expect(
        saglikArtisi,
        lessThanOrEqualTo(MartialArtsEngine.prototypeOnlyLessonYearlyHealthCap +
            MartialArtsEngine.prototypeOnlyRankHealth * 3),
      );
      expect(
        mutlulukArtisi,
        lessThanOrEqualTo(
            MartialArtsEngine.prototypeOnlyLessonYearlyHappinessCap +
                MartialArtsEngine.prototypeOnlyRankHappiness * 3),
      );
      // Tamamen kapanmadı: ilk dersler yine bir şey kattı.
      expect(saglikArtisi, greaterThan(0));
    });

    test('ders almak engellenmez, yalnızca stat kazancı sınırlanır', () {
      const MartialArtsEngine motor = MartialArtsEngine();
      final MartialArt sanat = MartialArt.values.first;
      GameState s = taban();
      int alinan = 0;
      for (int i = 0; i < kMaxMartialLessonsPerAge; i++) {
        final ActivityResult r = motor.takeLesson(state: s, art: sanat);
        if (!r.outcome.applied) break;
        s = r.state;
        alinan++;
      }
      // Yıllık ders hakkının tamamı kullanılabiliyor: basamak ilerlemesi
      // engellenmedi, yalnızca stat damlası kesildi.
      expect(alinan, kMaxMartialLessonsPerAge);
    });
  });

  group('Hastalık ciddiyete göre yıpratır (D-116)', () {
    test('en hafif hastalık bile en az on sağlık götürür', () {
      // Faho bildirdi: "-1-2-3 değil de en az -10 sağlık düşmeli".
      expect(
        SickLeaves.healthCostFor(days: 3, health: 80),
        greaterThanOrEqualTo(10),
      );
    });

    test('ciddiyet arttıkça kayıp artar', () {
      final int hafif = SickLeaves.healthCostFor(days: 3, health: 80);
      final int orta = SickLeaves.healthCostFor(days: 5, health: 80);
      final int agir = SickLeaves.healthCostFor(days: 7, health: 80);
      expect(orta, greaterThan(hafif));
      expect(agir, greaterThan(orta));
    });

    test('sağlığı düşük olan daha ağır etkilenir', () {
      expect(
        SickLeaves.healthCostFor(days: 5, health: 30),
        greaterThan(SickLeaves.healthCostFor(days: 5, health: 80)),
      );
    });

    test('ciddiyet etiketi gün sayısından okunur', () {
      expect(SickLeaves.severityLabel(3), 'hafif');
      expect(SickLeaves.severityLabel(5), 'orta');
      expect(SickLeaves.severityLabel(7), 'ağır');
    });
  });

  group('Hastalıktan toparlanma (D-116)', () {
    test('hasta olunmayan yılda sağlık tavana doğru toparlanır', () {
      final int pay = SickLeaves.recoveryFor(age: 30, health: 50, ceiling: 90);
      expect(pay, greaterThan(0));
    });

    test('toparlanma tavanı aşmaz', () {
      expect(SickLeaves.recoveryFor(age: 30, health: 89, ceiling: 90), 1);
      expect(SickLeaves.recoveryFor(age: 30, health: 90, ceiling: 90), 0);
      expect(SickLeaves.recoveryFor(age: 30, health: 95, ceiling: 90), 0);
    });

    test('tavan yaşla düşer: yaşlanmanın kalıcı kaybı geri verilmez', () {
      final int genc = StatAging.prototypeOnlyHealthCeilingFor(25);
      final int orta = StatAging.prototypeOnlyHealthCeilingFor(50);
      final int yasli = StatAging.prototypeOnlyHealthCeilingFor(65);
      expect(genc, greaterThan(orta));
      expect(orta, greaterThan(yasli));
    });

    test('ileri yaşta toparlanma yoktur', () {
      expect(
        SickLeaves.recoveryFor(
          age: SickLeaves.prototypeOnlyRecoveryMaxAge + 1,
          health: 20,
          ceiling: 90,
        ),
        0,
      );
    });
  });

  group('İşe girişte üst yaş sınırı (D-113)', () {
    JobType isi(String id) => kJobCatalog.firstWhere((JobType j) => j.id == id);

    test('polis ve itfaiyeci için üst sınır 30', () {
      expect(isi('polis').maxAge, 30);
      expect(isi('itfaiyeci').maxAge, 30);
    });

    test('elli yaşında polis olunamaz, sebebi yazar', () {
      final GameState s = taban(age: 50);
      final String engel = const JobMarket().requirementReason(s, isi('polis'));
      expect(engel, isNotEmpty);
      expect(engel, contains('30'));
      expect(engel, contains('50'));
    });

    test('yaşı tutan aday için bu engel çıkmaz', () {
      final GameState s = taban(age: 25);
      final String engel = const JobMarket().requirementReason(s, isi('polis'));
      // Başka bir sebeple kapalı olabilir; ama yaş sebebiyle değil.
      expect(engel, isNot(contains('artık başvuramazsın')));
    });

    test('üst sınırı olmayan mesleklere yaş engeli konmaz', () {
      // Türkiye'de merkezi memur alımlarında üst yaş sınırı yoktur;
      // oyun uydurma bir sınır koymaz.
      expect(isi('memur').maxAge, isNull);
      expect(isi('ogretmen').maxAge, isNull);
      expect(isi('doktor').maxAge, isNull);
      final GameState s = taban(age: 55);
      final String engel = const JobMarket().requirementReason(s, isi('memur'));
      expect(engel, isNot(contains('artık başvuramazsın')));
    });
  });

  group('Karizma gerçekten yıpranır (D-124)', () {
    test('düşüş ihtimali her yaş bandında artırıldı', () {
      // Faho bildirdi: "sağlık ve karizma asla düşmüyor neredeyse".
      // Ölçüm: 100 hayatta karizma 20 yaşta 52,6 · 70 yaşta 38,4 idi.
      expect(StatAging.prototypeOnlyCharismaChance(40), greaterThanOrEqualTo(0.30));
      expect(StatAging.prototypeOnlyCharismaChance(55), greaterThanOrEqualTo(0.45));
      expect(StatAging.prototypeOnlyCharismaChance(70), greaterThanOrEqualTo(0.60));
    });

    test('düşüş yaşla birlikte hızlanır', () {
      expect(
        StatAging.prototypeOnlyCharismaChance(70),
        greaterThan(StatAging.prototypeOnlyCharismaChance(40)),
      );
      expect(
        StatAging.prototypeOnlyCharismaStepFor(65),
        greaterThan(StatAging.prototypeOnlyCharismaStepFor(40)),
      );
    });

    test('gençlikte karizma yıpranmaz', () {
      expect(
        StatAging.prototypeOnlyCharismaChance(
          StatAging.prototypeOnlyCharismaFromAge - 1,
        ),
        0,
      );
    });

    test('karizma tabanın altına inmez', () {
      expect(StatAging.prototypeOnlyCharismaFloor, greaterThan(0));
    });
  });
}
