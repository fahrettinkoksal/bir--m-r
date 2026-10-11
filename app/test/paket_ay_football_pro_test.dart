// Paket AY — profesyonel futbol hayatı.
//
// AU kapıyı kurdu ama kapıdan geçilmiyordu: uygunluk hesaplanıyor,
// sonra hiçbir şey olmuyordu. Bu testler o zincirin gerçekten
// çalıştığını gösterir: deneme → sezon → form → sakatlık → kazanç →
// kariyer sonu → futbol sonrası hayat.
//
// **Bu pakette OLMAYANLAR da test edilir:** maç maç simülasyon yok,
// lig/kulüp adı yok (katalog ağ erişimi beklediği için), transfer ve
// maaş pazarlığı yok.
library;

import 'dart:math';

import 'package:bir_omur/data/economy.dart';
import 'package:bir_omur/data/job_catalog.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/data/school_club_catalog.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/school_club_progress.dart';
import 'package:bir_omur/domain/sports/football_career.dart';
import 'package:bir_omur/domain/sports/football_pro_engine.dart';
import 'package:flutter_test/flutter_test.dart';

const FootballProEngine kMotor = FootballProEngine();

GameState _hayat(int seed, {required int age, int health = 85}) {
  final GameState base =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  return base.copyWith(
    pendingEvent: null,
    player: base.player.copyWith(
      age: age,
      wallet: 0,
      stats: base.player.stats.copyWith(health: health),
    ),
  );
}

/// Kapıyı açmaya yeten bir futbol geçmişi kurar.
GameState _gucluGecmis(GameState state, {int seasons = 7, int skill = 72}) =>
    state.copyWith(
      schoolClubs: <SchoolClubProgress>[
        SchoolClubProgress(
          clubId: footballClub.id,
          schoolId: 'okul-1',
          joinedAtAge: 11,
          joinedAtGrade: 5,
          active: false,
          leftAtAge: 11 + seasons,
          yearsActive: seasons,
          skill: skill,
          performance: 72,
          role: SquadRole.kaptan,
          captainSinceAge: 16,
        ),
      ],
    );

/// Aktif profesyonel bir kariyer kurar.
GameState _profesyonel(
  GameState state, {
  int startedAtAge = 18,
  FootballPosition position = FootballPosition.forvet,
  int form = 60,
  int reputation = 20,
  int weakSeasons = 0,
  int? lastSeasonAge,
}) =>
    state.copyWith(
      footballCareer: FootballCareer(
        startedAtAge: startedAtAge,
        position: position,
        form: form,
        reputation: reputation,
        weakSeasons: weakSeasons,
        lastSeasonAge: lastSeasonAge,
      ),
    );

void main() {
  group('Deneme', () {
    test('geçmişi olmayan reddedilir ve gerekçe futbolu söyler', () {
      final GameState s = _hayat(1, age: 18);
      final ({GameState state, bool accepted, String reason}) r =
          kMotor.attemptTrial(s, Random(3));
      expect(r.accepted, isFalse);
      expect(r.reason, contains('futbol geçmişin yok'));
      expect(r.state.footballCareer, isNull);
    });

    test('güçlü geçmişte kabul olabilir ve kariyer gerçekten kurulur', () {
      final GameState s = _gucluGecmis(_hayat(2, age: 18, health: 90));
      // Kabul garanti değil; 40 tohumda en az biri kabul olmalı.
      GameState? kabulEdilen;
      for (int seed = 0; seed < 40 && kabulEdilen == null; seed++) {
        final ({GameState state, bool accepted, String reason}) r =
            kMotor.attemptTrial(s, Random(seed));
        if (r.accepted) kabulEdilen = r.state;
      }
      expect(kabulEdilen, isNotNull, reason: 'Hiçbir tohumda kabul olmadı');
      final FootballCareer k = kabulEdilen!.footballCareer!;
      expect(k.active, isTrue);
      expect(k.startedAtAge, 18);
      expect(k.proSeasons, 0);
      // Kulüp kataloğu yok: uydurma kulüp adı YAZILMAZ.
      expect(k.currentClubId, isNull);
      expect(k.currentLeagueId, isNull);
    });

    test('mükemmel geçmiş bile kesin kabul değil', () {
      final GameState s =
          _gucluGecmis(_hayat(3, age: 18, health: 100), seasons: 9, skill: 95);
      bool enAzBirRet = false;
      for (int seed = 0; seed < 60; seed++) {
        if (!kMotor.attemptTrial(s, Random(seed)).accepted) {
          enAzBirRet = true;
          break;
        }
      }
      expect(enAzBirRet, isTrue,
          reason: 'Her tohumda kabul: deneme kesinliğe dönmüş');
    });

    test('deneme yılda bir kez: aynı yıl ikinci deneme reddedilir', () {
      // Bu kontrol olmadan oyuncu kabul alana kadar düğmeye
      // basabiliyordu; 1200 hayatlık ölçümde kapıya gelenlerin %100'ü
      // profesyonel oluyordu.
      final GameState s = _gucluGecmis(_hayat(20, age: 18, health: 90));
      final ({GameState state, bool accepted, String reason}) bir =
          kMotor.attemptTrial(s, Random(0));
      expect(bir.state.footballTrialAge, 18);

      final ({GameState state, bool accepted, String reason}) iki =
          kMotor.attemptTrial(bir.state, Random(0));
      expect(iki.accepted, isFalse);
      expect(iki.reason, contains('Bu yılın denemesine girdin'));

      // Gelecek yıl kapı yeniden açılır.
      final GameState gelecekYil = bir.state.copyWith(
        player: bir.state.player.copyWith(age: 19),
      );
      expect(
        kMotor.attemptTrial(gelecekYil, Random(0)).reason,
        isNot(contains('Bu yılın denemesine girdin')),
      );
    });

    test('ret de kayda geçer: başarısız deneme yılı tüketir', () {
      // Zayıf geçmişle değil, kapıdan geçen ama eşiği aşamayan biriyle
      // ölçülür; ret bulana kadar tohum taranır.
      final GameState s = _gucluGecmis(
        _hayat(21, age: 18, health: 56),
        seasons: 3,
        skill: 46,
      );
      GameState? redEdilen;
      for (int seed = 0; seed < 60 && redEdilen == null; seed++) {
        final ({GameState state, bool accepted, String reason}) r =
            kMotor.attemptTrial(s, Random(seed));
        if (!r.accepted && r.state.footballTrialAge == 18) {
          redEdilen = r.state;
        }
      }
      expect(redEdilen, isNotNull,
          reason: 'Sınırdaki aday hiç reddedilmiyor: eşik dekoratif');
      expect(redEdilen!.footballCareer, isNull);
    });

    test('eşik kapının alt sınırının ÜSTÜNDE: sınırdaki aday takılır', () {
      // Kapıdan geçmenin alt sınırı: puan 55, sağlık 55.
      // En zayıf adayın deneme puanı = 55 + 55*15/100 = 63.
      const int enZayifAdayPuani = FootballPath.minScore +
          FootballPath.minHealth * 15 ~/ 100;
      expect(
        FootballProEngine.trialPass,
        greaterThan(enZayifAdayPuani),
        reason: 'Eşik en zayıf adayın puanının altındaysa deneme '
            'dekoratiftir: kapıdan geçen herkes kabul edilir.',
      );
    });

    test('kariyeri olan ikinci kez denemeye girmez', () {
      final GameState s = _profesyonel(_gucluGecmis(_hayat(4, age: 20)));
      final ({GameState state, bool accepted, String reason}) r =
          kMotor.attemptTrial(s, Random(1));
      expect(r.accepted, isFalse);
      expect(r.reason, contains('kariyerin sürüyor'));
    });
  });

  group('Sezon', () {
    test('sezon yaş başına bir kez işlenir', () {
      final GameState s = _profesyonel(_gucluGecmis(_hayat(5, age: 20)));
      final ({GameState state, List<String> log, String? milestone}) bir =
          kMotor.advanceSeason(s, Random(7));
      expect(bir.state.footballCareer!.proSeasons, 1);
      // Aynı yaşta ikinci kez: hiçbir şey olmaz.
      final ({GameState state, List<String> log, String? milestone}) iki =
          kMotor.advanceSeason(bir.state, Random(7));
      expect(iki.state.footballCareer!.proSeasons, 1);
      expect(iki.log, isEmpty);
    });

    test('sezon maç, puan ve kazanç üretir; para cüzdana yazılır', () {
      final GameState s = _profesyonel(_gucluGecmis(_hayat(6, age: 22)));
      final ({GameState state, List<String> log, String? milestone}) r =
          kMotor.advanceSeason(s, Random(11));
      final FootballSeason sezon = r.state.footballCareer!.seasonHistory.single;
      expect(sezon.age, 22);
      expect(sezon.rating, greaterThan(0));
      expect(sezon.earned, greaterThan(0));
      // Kazanç gerçekten cüzdana geçti.
      expect(r.state.player.wallet, sezon.earned);
      expect(r.state.footballCareer!.careerEarnings, sezon.earned);
      expect(r.log, isNotEmpty);
    });

    test('kaleci gol atmaz', () {
      final GameState s = _profesyonel(
        _gucluGecmis(_hayat(7, age: 23)),
        position: FootballPosition.kaleci,
      );
      for (int seed = 0; seed < 12; seed++) {
        final GameState sonra = kMotor
            .advanceSeason(_profesyonel(
              _gucluGecmis(_hayat(7, age: 23)),
              position: FootballPosition.kaleci,
            ), Random(seed))
            .state;
        expect(sonra.footballCareer!.seasonHistory.single.goals, 0);
      }
      expect(s.footballCareer!.position, FootballPosition.kaleci);
    });

    test('ilk sezon dönüm noktası bildirimi üretir', () {
      final GameState s = _profesyonel(_gucluGecmis(_hayat(8, age: 19)));
      final ({GameState state, List<String> log, String? milestone}) r =
          kMotor.advanceSeason(s, Random(5));
      expect(r.milestone, isNotNull);
      expect(r.milestone, contains('İlk profesyonel sezon'));
    });

    test('yaşlanınca sezon puanı düşer (aynı tohum, aynı geçmiş)', () {
      int puan(int yas) => kMotor
          .advanceSeason(
            _profesyonel(_gucluGecmis(_hayat(9, age: yas)), form: 70),
            Random(4),
          )
          .state
          .footballCareer!
          .seasonHistory
          .single
          .rating;
      expect(puan(36), lessThan(puan(24)),
          reason: '36 yaşında 24 yaşındaki kadar iyi oynanmıyor');
    });

    test('sakatlık bir sezonda yaşanabiliyor ve kayda geçiyor', () {
      bool sakatlikGoruldu = false;
      for (int seed = 0; seed < 40 && !sakatlikGoruldu; seed++) {
        final GameState sonra = kMotor
            .advanceSeason(
              _profesyonel(_gucluGecmis(_hayat(10, age: 28, health: 60))),
              Random(seed),
            )
            .state;
        if (sonra.footballCareer!.seasonHistory.single.injury != null) {
          sakatlikGoruldu = true;
        }
      }
      expect(sakatlikGoruldu, isTrue,
          reason: 'Hiç sakatlık olmuyorsa sistem ölü');
    });
  });

  group('Sakatlık sağlığa dokunur', () {
    test('sakat geçen sezon sağlığı düşürür', () {
      // Sakatlık bulunan ilk tohumda sağlık düşmüş olmalı.
      bool olculdu = false;
      for (int seed = 0; seed < 40 && !olculdu; seed++) {
        final GameState once =
            _profesyonel(_gucluGecmis(_hayat(30, age: 29, health: 70)));
        final GameState sonra = kMotor.advanceSeason(once, Random(seed)).state;
        final FootballSeason sezon = sonra.footballCareer!.seasonHistory.single;
        if (sezon.injury == null) {
          // Sakatlık yoksa sağlık futbol yüzünden düşmez.
          expect(sonra.player.stats.health, once.player.stats.health);
          continue;
        }
        olculdu = true;
        expect(sonra.player.stats.health, lessThan(once.player.stats.health));
      }
      expect(olculdu, isTrue, reason: 'Hiç sakatlık çıkmadı');
    });

    test('sakatlık kariyeri bitirebiliyor: yol ölü değil', () {
      // Sağlığı eşiğin hemen üstünde bir futbolcu; ağır sakatlık onu
      // eşiğin altına indirmeli ve kariyeri bitirmeli.
      bool sakatlikBitirdi = false;
      for (int seed = 0; seed < 300 && !sakatlikBitirdi; seed++) {
        final GameState once = _profesyonel(
          _gucluGecmis(
            _hayat(
              31,
              age: 27,
              health: FootballProEngine.careerEndingHealth + 10,
            ),
          ),
        );
        final FootballCareer k =
            kMotor.advanceSeason(once, Random(seed)).state.footballCareer!;
        if (k.exitReason == FootballExit.sakatlik) sakatlikBitirdi = true;
      }
      expect(
        sakatlikBitirdi,
        isTrue,
        reason: 'FootballExit.sakatlik hiç oluşmuyor. 49 kariyerlik '
            'ölçümde de %0 çıkmıştı: sakatlık sağlığa dokunmadığı için '
            'bu çıkış yolu ölü koddu.',
      );
    });

    test('sağlık hiç sıfıra inmez: futbol tek başına öldürmez', () {
      GameState s = _profesyonel(_gucluGecmis(_hayat(32, age: 20, health: 40)));
      for (int yas = 20; yas <= 38; yas++) {
        s = s.copyWith(player: s.player.copyWith(age: yas));
        s = kMotor.advanceSeason(s, Random(yas * 7)).state;
        expect(s.player.stats.health, greaterThan(0));
      }
    });
  });

  group('Kariyer sonu', () {
    test('39 yaşında kariyer her hâlükârda biter ve sebebi yazılır', () {
      final GameState s = _profesyonel(
        _gucluGecmis(_hayat(11, age: FootballProEngine.hardRetireAge)),
      );
      final GameState sonra = kMotor.advanceSeason(s, Random(2)).state;
      final FootballCareer k = sonra.footballCareer!;
      expect(k.active, isFalse);
      expect(k.exitReason, FootballExit.yas);
      expect(k.retiredAtAge, FootballProEngine.hardRetireAge);
    });

    test('üst üste zayıf sezon sözleşmeyi bitirir', () {
      // İki zayıf sezon birikmiş; bu sezon da zayıf geçerse biter.
      final GameState s = _profesyonel(
        _hayat(12, age: 26, health: 40).copyWith(
          schoolClubs: <SchoolClubProgress>[
            SchoolClubProgress(
              clubId: footballClub.id,
              schoolId: 'okul-1',
              joinedAtAge: 14,
              joinedAtGrade: 8,
              active: false,
              yearsActive: 3,
              skill: 20,
              performance: 30,
              role: SquadRole.yedek,
            ),
          ],
        ),
        form: 15,
        weakSeasons: FootballProEngine.weakSeasonsToRelease - 1,
      );
      final FootballCareer k = kMotor.advanceSeason(s, Random(1)).state
          .footballCareer!;
      expect(k.active, isFalse);
      expect(k.exitReason, FootballExit.sozlesmeYenilenmedi);
    });

    test('biten kariyer sezon geçmişini KORUR, silinmez', () {
      GameState s = _profesyonel(_gucluGecmis(_hayat(13, age: 30)));
      for (int yas = 30; yas <= 40; yas++) {
        s = s.copyWith(player: s.player.copyWith(age: yas));
        s = kMotor.advanceSeason(s, Random(yas)).state;
      }
      final FootballCareer k = s.footballCareer!;
      expect(k.active, isFalse);
      expect(k.seasonHistory, isNotEmpty);
      expect(k.proSeasons, k.seasonHistory.length);
      expect(k.careerEarnings, greaterThan(0));
    });

    test('kendi kararıyla bırakma kaydı korur ve sebebi yazar', () {
      final GameState s = _profesyonel(_gucluGecmis(_hayat(14, age: 27)));
      final GameState sonra = kMotor.retire(s);
      expect(sonra.footballCareer!.active, isFalse);
      expect(sonra.footballCareer!.exitReason, FootballExit.kendiKarari);
      expect(sonra.footballCareer!.retiredAtAge, 27);
    });

    test('biten kariyerde sezon artık işlenmez', () {
      final GameState s = kMotor.retire(
        _profesyonel(_gucluGecmis(_hayat(15, age: 28))),
      );
      expect(kMotor.canAdvance(s), isFalse);
      final GameState sonra = kMotor.advanceSeason(s, Random(1)).state;
      expect(sonra.footballCareer!.proSeasons, 0);
    });
  });

  group('Ün: futbol sonrası hayatın sermayesi (Paket AY/2)', () {
    test('profesyonel sezon Ün kazandırıyor', () {
      // ÖLÇÜLEN HATA: futbol fame alanına hiç dokunmuyordu; 300 maç
      // oynamış bir profesyonel tanınmamış kalıyordu.
      final GameState once = _profesyonel(_gucluGecmis(_hayat(40, age: 21)));
      expect(once.player.fame ?? 0, 0);
      final GameState sonra = kMotor.advanceSeason(once, Random(3)).state;
      expect(sonra.player.fame, isNotNull);
      expect(sonra.player.fame!, greaterThan(0));
    });

    test('uzun kariyer sponsorluk eşiklerine ulaşıyor', () {
      GameState s = _profesyonel(_gucluGecmis(_hayat(41, age: 20)));
      for (int yas = 20; yas <= 34; yas++) {
        s = s.copyWith(player: s.player.copyWith(age: yas));
        s = kMotor.advanceSeason(s, Random(yas * 3)).state;
      }
      // Katalogdaki medya/sponsorluk işleri minFame 3-78 bandında.
      // 15 sezonluk bir kariyer orta bandı açmalı.
      expect(s.player.fame, isNotNull);
      expect(s.player.fame!, greaterThan(20),
          reason: 'Uzun kariyer sonunda futbolcu hâlâ tanınmıyor');
    });

    test('Ün tavanı var: futbol tek başına 100 yapmaz', () {
      GameState s = _profesyonel(
        _gucluGecmis(_hayat(42, age: 18, health: 100), seasons: 9, skill: 95),
        form: 100,
        reputation: 100,
      );
      for (int yas = 18; yas <= 38; yas++) {
        s = s.copyWith(player: s.player.copyWith(age: yas));
        s = kMotor.advanceSeason(s, Random(yas * 5)).state;
      }
      expect(
        s.player.fame!,
        lessThanOrEqualTo(FootballProEngine.footballFameCap),
      );
      expect(s.player.fame!, lessThan(100));
    });

    test('kariyer sonu metni oyuncuya ne kaldığını söylüyor', () {
      final GameState s = _profesyonel(
        _gucluGecmis(_hayat(43, age: FootballProEngine.hardRetireAge)),
      );
      final ({GameState state, List<String> log, String? milestone}) r =
          kMotor.advanceSeason(s, Random(2));
      expect(r.milestone, isNotNull);
      // Kuru "bitti" değil: sonrasına dair bir cümle var.
      expect(
        r.milestone!,
        anyOf(
          contains('teklifler'),
          contains('tanınıyorsun'),
          contains('unutulur'),
        ),
      );
    });
  });

  group('Futbol sonrası hayat', () {
    test('futbolculuk hâlâ bir kJobCatalog işi DEĞİL', () {
      expect(
        kJobCatalog.any((JobType j) =>
            j.id.contains('futbol') ||
            j.name.toLowerCase().contains('futbolcu')),
        isFalse,
      );
    });

    test('kariyer bittikten sonra normal işe girmek engellenmiyor', () {
      // Futbol bir meslek kaydı tutmadığı için career alanı boş kalır;
      // yani emekli futbolcu normal iş başvurusu yapabilir.
      final GameState s = kMotor.retire(
        _profesyonel(_gucluGecmis(_hayat(16, age: 33))),
      );
      expect(s.career.jobId, isNull);
      expect(s.footballCareer!.active, isFalse);
    });
  });

  group('Kayıt', () {
    test('futbol kariyeri kaydedilip birebir geri okunuyor', () {
      GameState s = _profesyonel(
        _gucluGecmis(_hayat(17, age: 24)),
        reputation: 33,
        form: 71,
      );
      s = kMotor.advanceSeason(s, Random(6)).state;
      final GameState geri =
          decodeGameState(encodeGameState(s));
      final FootballCareer a = s.footballCareer!;
      final FootballCareer b = geri.footballCareer!;
      expect(b.startedAtAge, a.startedAtAge);
      expect(b.position, a.position);
      expect(b.form, a.form);
      expect(b.reputation, a.reputation);
      expect(b.lastSeasonAge, a.lastSeasonAge);
      expect(b.careerEarnings, a.careerEarnings);
      expect(b.proSeasons, a.proSeasons);
      expect(b.seasonHistory.single.rating, a.seasonHistory.single.rating);
      expect(b.seasonHistory.single.earned, a.seasonHistory.single.earned);
    });

    test('deneme yılı kaydedilip geri okunuyor', () {
      final GameState s = _gucluGecmis(_hayat(22, age: 18, health: 90));
      final GameState denendi = kMotor.attemptTrial(s, Random(0)).state;
      expect(denendi.footballTrialAge, 18);
      expect(decodeGameState(encodeGameState(denendi)).footballTrialAge, 18);
    });

    test('eski kayıtta deneme yılı yoksa null okunur', () {
      final Map<String, Object?> json =
          encodeGameState(_hayat(23, age: 20));
      json.remove('footballTrialAge');
      expect(decodeGameState(json).footballTrialAge, isNull);
    });

    test('eski kayıtta futbol alanı yoksa null okunur, uydurulmaz', () {
      final GameState s = _hayat(18, age: 30);
      final Map<String, Object?> json = encodeGameState(s);
      json.remove('footballCareer');
      expect(decodeGameState(json).footballCareer, isNull);
    });
  });

  group('Kazanç bandı', () {
    test('kazanç asgari ücret çıpasından türetiliyor ve tavanı var', () {
      // En iyi sezon bile tavanı aşmaz.
      GameState s = _profesyonel(
        _gucluGecmis(_hayat(19, age: 25, health: 100), seasons: 9, skill: 95),
        form: 100,
        reputation: 100,
      );
      s = kMotor.advanceSeason(s, Random(9)).state;
      final int kazanc = s.footballCareer!.seasonHistory.single.earned;
      expect(kazanc, greaterThan(Economy.netYearlyMinimumWage));
      expect(
        kazanc,
        lessThanOrEqualTo(
          FootballProEngine.maxSalaryInYearlyWages *
              Economy.netYearlyMinimumWage,
        ),
      );
    });
  });
}
