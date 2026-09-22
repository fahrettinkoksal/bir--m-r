import 'package:bir_omur/data/job_catalog.dart';
import 'package:bir_omur/data/interview_catalog.dart';
import 'package:bir_omur/data/martial_arts_catalog.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/domain/activities/activity_engine.dart';
import 'package:bir_omur/domain/activities/martial_arts_engine.dart';
import 'package:bir_omur/domain/career/job_market.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/education.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/martial_progress.dart';
import 'package:flutter_test/flutter_test.dart';

const MartialArtsEngine motor = MartialArtsEngine();

GameState hayat({int age = 20, int wallet = 1000000}) {
  final GameState taban =
      LifeGenerator.seeded(7).generate(mode: StartMode.tamamenRastgele);
  return taban.copyWith(
    pendingEvent: null,
    education: const EducationState(finished: true, startedAtAge: 6),
    player: taban.player.copyWith(age: age, wallet: wallet),
  );
}

/// [art] dalında [hedef] basamağa çıkana kadar ders aldırır.
///
/// Yıl sınırı gerçek kuraldır; bu yüzden sınıra gelince yaş ilerletilir.
GameState seviyeyeCik(GameState state, MartialArt art, int hedef) {
  GameState s = state;
  int guvenlik = 0;
  while (motor.progressOf(s, art).level < hedef) {
    if (motor.lessonsThisAge(s, art) >= kMaxMartialLessonsPerAge) {
      s = s.copyWith(
        player: s.player.copyWith(age: s.player.age + 1),
        interactionCounts: const <String, int>{},
      );
      continue;
    }
    final ActivityResult r = motor.takeLesson(state: s, art: art);
    expect(r.outcome.applied, isTrue, reason: r.outcome.text);
    s = r.state;
    if (++guvenlik > 5000) fail('Basamak $hedef\'e ulaşılamadı');
  }
  return s;
}

void main() {
  group('Katalog', () {
    test('her dalın basamakları artan ders sayısıyla sıralı', () {
      for (final MartialArt art in MartialArt.values) {
        expect(art.ranks.first.lessonsNeeded, 0,
            reason: '${art.label} ilk basamağı ücretsiz başlamalı');
        for (int i = 1; i < art.ranks.length; i++) {
          expect(
            art.ranks[i].lessonsNeeded,
            greaterThan(art.ranks[i - 1].lessonsNeeded),
            reason: '${art.label}: ${art.ranks[i].name}',
          );
        }
      }
    });

    test('eğitmenlik eşiği gerçek bir basamağı gösterir', () {
      for (final MartialArt art in MartialArt.values) {
        expect(art.instructorFromLevel, greaterThan(0));
        expect(art.instructorFromLevel, lessThanOrEqualTo(art.topLevel));
        expect(art.instructorRankName, isNotEmpty);
      }
    });

    test('her eğitmenlik işi katalogda ve mülakat soruları var', () {
      for (final MartialArt art in MartialArt.values) {
        final JobType? is_ = jobById(art.instructorJobId);
        expect(is_, isNotNull, reason: art.instructorJobId);
        expect(is_!.martialArtId, art.id);
        expect(questionsForJob(is_.id), isNotEmpty,
            reason: '${is_.name} için mülakat sorusu yok, iş açılmaz');
      }
    });

    test('ders ücretleri düşük tutulur', () {
      for (final MartialArt art in MartialArt.values) {
        expect(art.lessonCost, lessThanOrEqualTo(250),
            reason: '${art.label} ders başı ücreti ucuz olmalı');
      }
    });

    test('basamak adları gerçek düzenlerden geliyor', () {
      expect(
        MartialArt.karate.ranks.map((MartialRank r) => r.name).join(' '),
        allOf(contains('kyu'), contains('Dan'), contains('Kahverengi')),
      );
      expect(
        MartialArt.kungFu.ranks.map((MartialRank r) => r.name).join(' '),
        allOf(contains('kuşak'), contains('Duan')),
      );
      expect(
        MartialArt.gures.ranks.map((MartialRank r) => r.name).join(' '),
        allOf(
          contains('Tozkoparan'),
          contains('Deste'),
          contains('Başaltı'),
          contains('Başpehlivan'),
        ),
      );
    });
  });

  group('Ders almak', () {
    test('ücret düşer, sağlık artar, ders sayılır', () {
      final GameState s = hayat(wallet: 10000);
      final ActivityResult r =
          motor.takeLesson(state: s, art: MartialArt.karate);

      expect(r.outcome.applied, isTrue);
      expect(
        r.state.player.wallet,
        s.player.wallet - MartialArt.karate.lessonCost,
      );
      expect(r.state.player.stats.health,
          greaterThan(s.player.stats.health));
      expect(motor.progressOf(r.state, MartialArt.karate).lessons, 1);
    });

    test('parası yetmeyen ders alamaz ve durum değişmez', () {
      final GameState s = hayat(wallet: 10);
      final ActivityResult r =
          motor.takeLesson(state: s, art: MartialArt.karate);
      expect(r.outcome.applied, isFalse);
      expect(r.state.player.wallet, 10);
      expect(r.state.martialArts, isEmpty);
    });

    test('yaşı tutmayan ders alamaz', () {
      final GameState s = hayat(age: 5);
      expect(
        motor.availability(s, MartialArt.karate).isAllowed,
        isFalse,
      );
    });

    test('bir yaşta ders sayısı sınırlı', () {
      GameState s = hayat(wallet: 10000000);
      for (int i = 0; i < kMaxMartialLessonsPerAge; i++) {
        s = motor.takeLesson(state: s, art: MartialArt.karate).state;
      }
      expect(motor.availability(s, MartialArt.karate).isAllowed, isFalse);
      final ActivityResult r =
          motor.takeLesson(state: s, art: MartialArt.karate);
      expect(r.outcome.applied, isFalse);
      expect(r.outcome.text, contains('seneye'));
    });

    test('farklı dallar birbirinin kotasını yemez', () {
      GameState s = hayat(wallet: 10000000);
      for (int i = 0; i < kMaxMartialLessonsPerAge; i++) {
        s = motor.takeLesson(state: s, art: MartialArt.karate).state;
      }
      expect(motor.availability(s, MartialArt.gures).isAllowed, isTrue);
    });

    test('basamak atlayınca günlüğe yazılır', () {
      GameState s = hayat(wallet: 10000000);
      final int oncekiKayit = s.log.length;
      s = seviyeyeCik(s, MartialArt.karate, 1);
      expect(s.log.length, greaterThan(oncekiKayit));
      expect(s.log.last.text, contains(MartialArt.karate.ranks[1].name));
    });

    test('en üst basamakta ders kapanır', () {
      GameState s = hayat(age: 10, wallet: 100000000);
      s = seviyeyeCik(s, MartialArt.gures, MartialArt.gures.topLevel);
      final MartialProgress p = motor.progressOf(s, MartialArt.gures);
      expect(p.isTopRank, isTrue);
      expect(p.rankName, 'Başpehlivan');
      expect(p.topRankAtAge, isNotNull);
      expect(motor.availability(s, MartialArt.gures).isAllowed, isFalse);
    });

    test('ustalık bir yılda satın alınamaz', () {
      GameState s = hayat(wallet: 100000000);
      final int baslangicYasi = s.player.age;
      s = seviyeyeCik(s, MartialArt.karate, MartialArt.karate.topLevel);
      expect(
        s.player.age - baslangicYasi,
        greaterThanOrEqualTo(5),
        reason: 'En üst basamak yıllar sürmeli',
      );
    });
  });

  group('Eğitmenlik işi', () {
    const JobMarket pazar = JobMarket();

    test('kuşağı olmayan eğitmenliğe başvuramaz', () {
      final GameState s = hayat(age: 25);
      for (final MartialArt art in MartialArt.values) {
        final JobType is_ = jobById(art.instructorJobId)!;
        expect(pazar.meetsRequirements(s, is_), isFalse);
        expect(
          pazar.requirementReason(s, is_),
          contains(art.instructorRankName),
        );
      }
    });

    test('eşiğe gelen başvurabilir', () {
      for (final MartialArt art in MartialArt.values) {
        GameState s = hayat(age: 10, wallet: 100000000);
        s = seviyeyeCik(s, art, art.instructorFromLevel);
        final GameState yetiskin =
            s.copyWith(player: s.player.copyWith(age: 25));
        final JobType is_ = jobById(art.instructorJobId)!;
        expect(
          pazar.meetsRequirements(yetiskin, is_),
          isTrue,
          reason: '${art.label}: ${art.instructorRankName}',
        );
      }
    });

    test('bir eşik altındaki basamak yetmez', () {
      final MartialArt art = MartialArt.karate;
      GameState s = hayat(age: 10, wallet: 100000000);
      s = seviyeyeCik(s, art, art.instructorFromLevel - 1);
      final GameState yetiskin =
          s.copyWith(player: s.player.copyWith(age: 25));
      expect(
        pazar.meetsRequirements(yetiskin, jobById(art.instructorJobId)!),
        isFalse,
      );
    });

    test('bir daldaki kuşak başka dalın eğitmenliğini açmaz', () {
      GameState s = hayat(age: 10, wallet: 100000000);
      s = seviyeyeCik(s, MartialArt.karate, MartialArt.karate.topLevel);
      final GameState yetiskin =
          s.copyWith(player: s.player.copyWith(age: 30));
      expect(
        pazar.meetsRequirements(
          yetiskin,
          jobById(MartialArt.gures.instructorJobId)!,
        ),
        isFalse,
      );
    });
  });

  test('ilerleme kayda girer ve geri yüklenir', () {
    GameState s = hayat(wallet: 10000000);
    s = seviyeyeCik(s, MartialArt.kungFu, 2);
    final MartialProgress once = motor.progressOf(s, MartialArt.kungFu);

    final GameState geri = decodeGameState(encodeGameState(s));
    final MartialProgress sonra = motor.progressOf(geri, MartialArt.kungFu);

    expect(sonra.lessons, once.lessons);
    expect(sonra.level, once.level);
    expect(sonra.rankName, once.rankName);
    expect(sonra.startedAtAge, once.startedAtAge);
  });

  test('eski kayıtta dövüş sanatı alanı yoksa boş okunur', () {
    final GameState s = hayat();
    final Map<String, Object?> json =
        Map<String, Object?>.from(encodeGameState(s));
    json.remove('martialArts');
    final GameState geri = decodeGameState(json);
    expect(geri.martialArts, isEmpty);
  });
}
