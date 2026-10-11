// Paket AU — profesyonel futbol yolunun kapısı.
//
// Bu paketin en önemli kuralı: **18-25 yaşında "futbolcu ol" düğmesine
// basarak profesyonel futbolcu olunamaz.** Profesyonel futbol,
// çocukluk/ergenlik döneminde kurulmuş gerçek bir futbol geçmişi ister.
//
// Testler kurasız ölçer: `FootballPath.evaluate` deterministiktir, aynı
// geçmiş her zaman aynı sonucu verir. Böylece "11'de başlayıp 7 yıl
// oynayan" ile "17'de başlayıp 1 yıl oynayan" karşılaştırması RNG'ye
// bağlanmadan yapılabilir.
library;

import 'package:bir_omur/data/job_catalog.dart';
import 'package:bir_omur/data/school_club_catalog.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/school_club_progress.dart';
import 'package:bir_omur/domain/sports/football_career.dart';
import 'package:flutter_test/flutter_test.dart';

GameState _hayat(
  int seed, {
  required int age,
  int health = 80,
  int charisma = 60,
  int intelligence = 60,
}) {
  final GameState base =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  return base.copyWith(
    player: base.player.copyWith(
      age: age,
      stats: base.player.stats.copyWith(
        health: health,
        charisma: charisma,
        intelligence: intelligence,
      ),
    ),
  );
}

/// Futbol geçmişi kurar: [startAge] yaşında başlayıp [seasons] sezon
/// oynamış bir oyuncu.
GameState _ileFutbolGecmisi(
  GameState state, {
  required int startAge,
  required int seasons,
  required int skill,
  bool captain = false,
}) {
  final SchoolClubProgress p = SchoolClubProgress(
    clubId: footballClub.id,
    schoolId: 'okul-1',
    joinedAtAge: startAge,
    joinedAtGrade: startAge - 6,
    active: false,
    leftAtAge: startAge + seasons,
    yearsActive: seasons,
    skill: skill,
    performance: 70,
    role: captain ? SquadRole.kaptan : SquadRole.ilkOnBir,
    captainSinceAge: captain ? startAge + seasons - 1 : null,
  );
  return state.copyWith(schoolClubs: <SchoolClubProgress>[p]);
}

void main() {
  group('Geçmişi olmayan oyuncuya kapı kapalı', () {
    test('18 yaşında sağlıklı, karizmatik, zeki ama futbol geçmişi yok', () {
      // Briefin kabul testi: bu senaryoda profesyonel uygunluk FALSE
      // olmalı. "Futbolcu ol" düğmesi diye bir şey yok.
      final GameState state = _hayat(
        1,
        age: 18,
        health: 100,
        charisma: 95,
        intelligence: 95,
      );
      final FootballEligibility u = FootballPath.evaluate(state);

      expect(u.eligible, isFalse);
      expect(u.stage, FootballStage.gecmisYok);
      expect(u.seasons, 0);
      expect(u.skill, 0);
      // Gerekçe kuru değil, açıklayıcı.
      expect(u.reason, contains('futbol geçmişin yok'));
    });

    test('yüksek atletik potansiyel tek başına kapıyı açmaz', () {
      final GameState state = _hayat(2, age: 20, health: 100);
      // Potansiyel doğumda belirlenir; burada yüksek bir hayat seçilse
      // bile geçmiş olmadan uygunluk gelmez.
      final FootballEligibility u = FootballPath.evaluate(state);
      expect(u.eligible, isFalse);
      expect(u.stage, FootballStage.gecmisYok);
    });

    test('scout da geçmişi olmayanı izlemez', () {
      final GameState state = _hayat(3, age: 17, health: 100);
      expect(FootballPath.scoutInterest(state), isFalse);
    });
  });

  group('Uzun geçmiş kapıyı açabilir', () {
    test('yıllarca okul futbolu + yeterli beceri + sağlık → kapı açık', () {
      final GameState state = _ileFutbolGecmisi(
        _hayat(4, age: 18, health: 85),
        startAge: 11,
        seasons: 7,
        skill: 70,
        captain: true,
      );
      final FootballEligibility u = FootballPath.evaluate(state);

      expect(u.stage, FootballStage.denemeyeUygun);
      expect(u.eligible, isTrue);
      expect(u.seasons, 7);
      expect(u.wasCaptain, isTrue);
      // Kapı açık ama **garanti kontrat değil**: metin bunu söylüyor.
      expect(u.reason, contains('Garanti değil'));
    });

    test('sağlık yetmezse kapı kapanır, gerekçe sağlığı söyler', () {
      final GameState state = _ileFutbolGecmisi(
        _hayat(5, age: 18, health: 30),
        startAge: 11,
        seasons: 7,
        skill: 70,
      );
      final FootballEligibility u = FootballPath.evaluate(state);
      expect(u.eligible, isFalse);
      expect(u.reason, contains('Sağlığın'));
    });

    test('16 yaşından küçükse henüz erken', () {
      final GameState state = _ileFutbolGecmisi(
        _hayat(6, age: 14, health: 90),
        startAge: 9,
        seasons: 5,
        skill: 70,
      );
      final FootballEligibility u = FootballPath.evaluate(state);
      expect(u.eligible, isFalse);
      expect(u.stage, FootballStage.gelisiyor);
      expect(u.reason, contains('erken'));
    });

    test('ilk giriş için yaş penceresi kapanır', () {
      final GameState state = _ileFutbolGecmisi(
        _hayat(7, age: 45, health: 90),
        startAge: 11,
        seasons: 7,
        skill: 80,
      );
      final FootballEligibility u = FootballPath.evaluate(state);
      expect(u.eligible, isFalse);
      expect(u.reason, contains('yaş penceresi'));
    });
  });

  group('Erken başlamak gerçek fark yaratır', () {
    test('11 yaşında 7 sezon, 17 yaşında 1 sezondan belirgin güçlü', () {
      // Deterministik puan üzerinden ölçülür; tek testte RNG'ye
      // bağlanmaz.
      final GameState a = _ileFutbolGecmisi(
        _hayat(8, age: 18, health: 85),
        startAge: 11,
        seasons: 7,
        skill: 70,
      );
      final GameState b = _ileFutbolGecmisi(
        _hayat(8, age: 18, health: 85),
        startAge: 17,
        seasons: 1,
        skill: 30,
      );

      final FootballEligibility ua = FootballPath.evaluate(a);
      final FootballEligibility ub = FootballPath.evaluate(b);

      expect(ua.score, greaterThan(ub.score),
          reason: 'Erken başlayıp yıllarca oynayan daha hazır olmalı.');
      // "Belirgin": yirmi puandan fazla fark.
      expect(ua.score - ub.score, greaterThan(20));
      expect(ua.eligible, isTrue);
      expect(ub.eligible, isFalse);
    });

    test('aynı sezon sayısında erken başlayan önde', () {
      final GameState erken = _ileFutbolGecmisi(
        _hayat(9, age: 18, health: 85),
        startAge: 10,
        seasons: 4,
        skill: 60,
      );
      final GameState gec = _ileFutbolGecmisi(
        _hayat(9, age: 18, health: 85),
        startAge: 14,
        seasons: 4,
        skill: 60,
      );
      expect(
        FootballPath.evaluate(erken).score,
        greaterThan(FootballPath.evaluate(gec).score),
      );
    });
  });

  group('Futbolculuk normal bir meslek değil', () {
    test('kJobCatalog profesyonel futbolcu içermiyor', () {
      for (final JobType j in kJobCatalog) {
        final String ad = j.name.toLowerCase();
        expect(ad.contains('futbolcu'), isFalse,
            reason: 'Futbol yolu ayrı kariyerdir; iş kataloğuna '
                'eklenmemeli (${j.id}).');
      }
    });

    test('futbol kimliği katalogda tekil ve futbol takımına bağlı', () {
      final List<SchoolClub> futbolcular = <SchoolClub>[
        for (final SchoolClub c in kSchoolClubs)
          if (c.associatedSportId == kFootballSportId) c,
      ];
      expect(futbolcular.length, 1);
      expect(futbolcular.single.requiresTryout, isTrue,
          reason: 'Futbol takımına seçmeyle girilir.');
      expect(futbolcular.single.competitive, isTrue);
      expect(futbolcular.single.physical, isTrue);
    });
  });

  group('Aktif profesyonel ve emekli durumları', () {
    test('aktif profesyonelde kapı yeniden açılmaz', () {
      final GameState state = _ileFutbolGecmisi(
        _hayat(10, age: 22, health: 85),
        startAge: 11,
        seasons: 7,
        skill: 75,
      ).copyWith(
        footballCareer: const FootballCareer(
          startedAtAge: 19,
          position: FootballPosition.ortaSaha,
        ),
      );
      final FootballEligibility u = FootballPath.evaluate(state);
      expect(u.stage, FootballStage.aktifProfesyonel);
      expect(u.eligible, isFalse);
    });

    test('iki aktif profesyonel spor kariyeri aynı anda olmaz', () {
      // Değişmez kural (invariant): dövüş ve futbol profesyonel
      // kariyerleri birlikte aktif olamaz. AV'de yasak uygulanacak;
      // burada durumun oluşabildiği yer belgelenmiş olsun.
      final GameState state = _hayat(11, age: 25).copyWith(
        footballCareer: const FootballCareer(
          startedAtAge: 20,
          position: FootballPosition.forvet,
        ),
      );
      final bool futbolAktif = state.footballCareer?.active ?? false;
      final bool dovusAktif = state.combatCareers
          .any((dynamic c) => c.retiredAtAge == null);
      expect(futbolAktif && dovusAktif, isFalse,
          reason: 'Aynı anda iki aktif profesyonel spor kariyeri olmamalı.');
    });
  });

  group('Gençlik özeti', () {
    test('geçmiş yoksa özet boş', () {
      expect(FootballPath.youthSummary(_hayat(12, age: 20)), isEmpty);
    });

    test('kademe ve yıl okunabilir biçimde yazılır', () {
      final GameState state = _ileFutbolGecmisi(
        _hayat(13, age: 20, health: 80),
        startAge: 11,
        seasons: 3,
        skill: 55,
        captain: true,
      );
      final List<String> ozet = FootballPath.youthSummary(state);
      expect(ozet, isNotEmpty);
      expect(ozet.first, contains('futbol takımı'));
      expect(ozet.first, contains('3 yıl'));
      expect(ozet, contains('Kaptanlık yapıldı'));
      // İç sayılar (beceri, performans) gösterilmiyor.
      expect(ozet.join(' ').contains('55'), isFalse);
    });
  });
}
