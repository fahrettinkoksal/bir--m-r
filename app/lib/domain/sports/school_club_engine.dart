/// Okul kulüplerinin motoru: katılım, seçme, antrenman, sezon (Paket AU).
///
/// **Ayrı motor, çünkü ayrı iş.** `CombatCareerEngine` bireysel bir
/// rekabet kariyerini yürütür (rakip, unvan, sıralama). Okul kulübü başka
/// bir şeydir: takıma girilir, kadroda yer kazanılır, sezon geçer. İkisi
/// zorla aynı modele sokulmadı — `combat/` kendi klasöründe olduğu gibi
/// `sports/` de kendi klasöründe durur.
///
/// **Bu motor rastgeleliğe tek başına dayanmaz.** Seçme sonucu sağlık,
/// yaş, geçmiş deneyim ve atletik potansiyelden gelir; rastgelelik yalnızca
/// kenar paydır. Ama hiçbir girdi bileşimi **kesin kabul** vermez: 100
/// sağlık + yüksek potansiyel bile garanti değildir.
library;

import 'dart:math';

import '../../data/school_club_catalog.dart';
import '../models/education.dart';
import '../models/game_state.dart';
import '../models/school_club_progress.dart';

/// Seçme/katılım sonucunun gerekçeli hali.
class ClubJoinOutcome {
  const ClubJoinOutcome({
    required this.accepted,
    required this.reason,
    this.state,
  });

  final bool accepted;

  /// Oyuncuya gösterilecek **gerekçe**. Kuru "olmadı" yazılmaz.
  final String reason;

  /// Kabul edildiyse güncellenmiş durum.
  final GameState? state;
}

/// Bir kulübe katılma engeli (yoksa `null`).
class ClubBlock {
  const ClubBlock(this.reason);

  final String reason;
}

class SchoolClubEngine {
  const SchoolClubEngine();

  /// Aynı anda sürdürülebilecek en fazla aktif kulüp (`prototypeOnly`).
  ///
  /// Bir öğrenci on üç kulübün hepsinde aktif olmasın; ama iki kulüp
  /// (ör. futbol + satranç) makul. Sayı **Q-192**'de tartışılıyor, kesin
  /// kural değildir.
  static const int prototypeOnlyMaxActiveClubs = 2;

  /// Seçmede geçmiş sezonun payı (`prototypeOnly`).
  static const int prototypeOnlyExperienceWeight = 4;

  /// Tek sezonda becerinin çıkabileceği en büyük artış (`prototypeOnly`).
  static const int prototypeOnlyMaxSkillGainPerSeason = 9;

  /// Seçmenin geçme eşiği (`prototypeOnly`).
  static const int prototypeOnlyTryoutPass = 55;

  /// Seçme kurasının genişliği (`prototypeOnly`).
  ///
  /// Yeterince geniş tutuldu ki **düşük puanlı** aday da matematiksel
  /// olarak elenmiş olmasın: 20 puanlı birinin de küçük bir şansı kalır.
  static const int prototypeOnlyTryoutLuckSpan = 40;

  /// Puan ne olursa olsun elenme payı, yüzde (`prototypeOnly`).
  ///
  /// Brief'in açık kuralı: "health 100 + yüksek yatkınlık = kesin kabul
  /// olmasın." İlk yazımda `puan + kura >= eşik` biçimindeydi ve yüksek
  /// puanlı oyuncuda kabul **kesinleşiyordu**; test bunu yakaladı. Kadro
  /// dar, antrenörün tercihi var: en hazır aday bile bazen listeye
  /// giremez.
  static const int prototypeOnlyTryoutUpsetPercent = 8;

  /// Bedensel kulüp için en az sağlık (`prototypeOnly`, Paket AQ uyumlu).
  static const int prototypeOnlyMinHealthForPhysical = 25;

  // -----------------------------------------------------------------
  // Uygunluk
  // -----------------------------------------------------------------

  /// Oyuncu şu an bu kulübe başvurabilir mi? Engel varsa gerekçesi.
  ClubBlock? blockFor(GameState state, SchoolClub club) {
    final EducationState e = state.education;
    if (!e.enrolled || e.grade == null) {
      return const ClubBlock('Kulüpler yalnızca okula devam ederken açık.');
    }
    final int grade = e.grade!;
    if (!club.openForGrade(grade)) {
      return ClubBlock('${club.name} bu sınıfta açılmıyor '
          '(${club.minGrade}-${club.maxGrade}. sınıf).');
    }
    final String? schoolId = e.schoolId;
    if (schoolId == null) {
      return const ClubBlock('Okul kaydı görünmüyor.');
    }
    if (state.schoolClubs.activeFor(club.id) != null) {
      return ClubBlock('${club.name} zaten üyesisin.');
    }
    if (state.schoolClubs.activeOnes.length >= prototypeOnlyMaxActiveClubs) {
      return ClubBlock('Aynı anda en fazla $prototypeOnlyMaxActiveClubs '
          'kulüpte aktif olabilirsin. Birinden ayrılman gerekiyor.');
    }
    if (club.physical &&
        state.player.stats.health < prototypeOnlyMinHealthForPhysical) {
      return const ClubBlock(
        'Sağlığın şu an bedensel bir takıma dayanmaz; önce toparlanman '
        'gerekiyor.',
      );
    }
    return null;
  }

  // -----------------------------------------------------------------
  // Katılım ve seçme
  // -----------------------------------------------------------------

  /// Seçme **puanı** (0-100). Deterministik: karşılaştırmalı test bunu
  /// ölçer, kuraya bağlanmaz.
  ///
  /// Girdiler: bedensel kulüpte atletik potansiyel + sağlık, zihinsel
  /// kulüpte karizma + zekâ; üstüne o spordaki geçmiş sezon ve beceri.
  int tryoutScore(GameState state, SchoolClub club) {
    final int health = state.player.stats.health;
    final int potential = state.player.athleticPotential;
    final String? sport = club.associatedSportId;
    final int seasons =
        sport == null ? 0 : state.schoolClubs.seasonsInSport(sport);
    final int bestSkill =
        sport == null ? 0 : state.schoolClubs.bestSkillInSport(sport);

    final int taban = club.physical
        ? (potential * 45 + health * 35) ~/ 100
        : (state.player.stats.charisma * 45 +
                state.player.stats.intelligence * 35) ~/
            100;

    final int deneyim =
        (seasons * prototypeOnlyExperienceWeight + bestSkill ~/ 4)
            .clamp(0, 30);
    return (taban + deneyim).clamp(0, 100);
  }

  /// Kulübe katıl ya da seçmeye gir.
  ClubJoinOutcome join(GameState state, SchoolClub club, Random rng) {
    final ClubBlock? engel = blockFor(state, club);
    if (engel != null) {
      return ClubJoinOutcome(accepted: false, reason: engel.reason);
    }
    final EducationState e = state.education;
    final int grade = e.grade!;
    final String schoolId = e.schoolId!;

    if (!club.requiresTryout) {
      return ClubJoinOutcome(
        accepted: true,
        reason: '${club.name} listesine adını yazdırdın.',
        state: _withNewMembership(state, club, schoolId, grade),
      );
    }

    final int puan = tryoutScore(state, club);
    // İki ayrı kura. Birincisi puana eklenen kenar pay: düşük puanlı
    // adayın da küçük bir şansı kalsın. İkincisi puandan **bağımsız**
    // elenme payı: en hazır aday bile kesin kabul almasın.
    final int zar = rng.nextInt(prototypeOnlyTryoutLuckSpan);
    final bool surpriz = rng.nextInt(100) < prototypeOnlyTryoutUpsetPercent;
    final bool kabul = !surpriz && puan + zar >= prototypeOnlyTryoutPass;

    if (!kabul) {
      final String neden = surpriz
          ? (club.physical
              ? 'Kadro dar çıktı. Antrenör "sen iyisin ama kontenjan '
                  'bitti" dedi.'
              : 'Liste doldu. "Seneye ilk sen" dediler.')
          : (club.physical
              ? 'Seçmede istenen tempoyu tutamadın. Antrenör "seneye yine '
                  'gel" dedi.'
              : 'Seçmede bu sefer olmadı. Liste kısa, aday çok.');
      return ClubJoinOutcome(accepted: false, reason: neden);
    }
    return ClubJoinOutcome(
      accepted: true,
      reason: '${club.name} kadrosuna girdin. Şimdilik yedeksin.',
      state: _withNewMembership(state, club, schoolId, grade),
    );
  }

  GameState _withNewMembership(
    GameState state,
    SchoolClub club,
    String schoolId,
    int grade,
  ) {
    final SchoolClubProgress yeni = SchoolClubProgress(
      clubId: club.id,
      schoolId: schoolId,
      joinedAtAge: state.player.age,
      joinedAtGrade: grade,
      skill: _tasinanBeceri(state, club),
    );
    return state.copyWith(
      schoolClubs: <SchoolClubProgress>[...state.schoolClubs, yeni],
    );
  }

  /// Okul değişince aynı spordaki beceri kısmen korunur.
  ///
  /// Üyelik taşınmaz (yeniden başvurulur) ama kazanılan beceri kişiyle
  /// kalır; sıfırlamak gerçeğe de oyuna da aykırı olurdu.
  int _tasinanBeceri(GameState state, SchoolClub club) {
    final String? sport = club.associatedSportId;
    if (sport == null) return 0;
    return state.schoolClubs.bestSkillInSport(sport);
  }

  // -----------------------------------------------------------------
  // Antrenman ve ayrılma
  // -----------------------------------------------------------------

  /// Bu yıl bu kulüpte daha antrenman yapılabilir mi?
  ///
  /// Yılda bir kez: bir yaşta antrenmana iki yüz kez basıp beceriyi 100
  /// yapmak mümkün olmasın.
  bool canTrain(GameState state, String clubId) {
    final SchoolClubProgress? p = state.schoolClubs.activeFor(clubId);
    if (p == null) return false;
    return p.lastPracticedAge != state.player.age;
  }

  /// Antrenmana git. Beceri azalan getiriyle artar.
  GameState train(GameState state, String clubId, Random rng) {
    final SchoolClubProgress? p = state.schoolClubs.activeFor(clubId);
    if (p == null || !canTrain(state, clubId)) return state;

    // Azalan getiri: beceri yükseldikçe aynı antrenman daha az katıyor.
    final int potansiyelPayi = state.player.athleticPotential ~/ 25;
    final int kalan = (100 - p.skill).clamp(0, 100);
    final int hamArtis = (1 + potansiyelPayi + rng.nextInt(2)) * kalan ~/ 100;
    final int yeniBeceri = (p.skill + hamArtis.clamp(0, 4)).clamp(0, 100);

    return _replace(
      state,
      p.copyWith(skill: yeniBeceri, lastPracticedAge: state.player.age),
    );
  }

  /// Kulüpten ayrıl. Kayıt **silinmez**, `active` kapanır.
  GameState leave(GameState state, String clubId) {
    final SchoolClubProgress? p = state.schoolClubs.activeFor(clubId);
    if (p == null) return state;
    return _replace(
      state,
      p.copyWith(active: false, leftAtAge: state.player.age),
    );
  }

  /// Okul değişti: aktif üyelikler kapanır, geçmiş korunur.
  ///
  /// Yeni okulda üyelik **otomatik taşınmaz**; oyuncu yeniden başvurur.
  GameState onSchoolChanged(GameState state, String? newSchoolId) {
    if (state.schoolClubs.isEmpty) return state;
    final List<SchoolClubProgress> guncel = <SchoolClubProgress>[
      for (final SchoolClubProgress p in state.schoolClubs)
        if (p.active && p.schoolId != newSchoolId)
          p.copyWith(active: false, leftAtAge: state.player.age)
        else
          p,
    ];
    return state.copyWith(schoolClubs: guncel);
  }

  GameState _replace(GameState state, SchoolClubProgress guncel) {
    final List<SchoolClubProgress> liste = <SchoolClubProgress>[
      for (final SchoolClubProgress p in state.schoolClubs)
        if (p.clubId == guncel.clubId &&
            p.schoolId == guncel.schoolId &&
            p.joinedAtAge == guncel.joinedAtAge)
          guncel
        else
          p,
    ];
    return state.copyWith(schoolClubs: liste);
  }

  // -----------------------------------------------------------------
  // Sezon
  // -----------------------------------------------------------------

  /// Yaş geçişinde aktif kulüplerin sezonunu işler.
  ///
  /// Her sezon devasa bir popup üretmez: `log` günlüğe yazılır,
  /// `milestones` bildirime çıkar (kaptanlık gibi).
  ({GameState state, List<String> log, List<String> milestones}) advanceSeason(
    GameState state,
    Random rng,
  ) {
    if (state.schoolClubs.activeOnes.isEmpty) {
      return (
        state: state,
        log: const <String>[],
        milestones: const <String>[],
      );
    }
    final List<String> log = <String>[];
    final List<String> milestones = <String>[];
    final List<SchoolClubProgress> guncel = <SchoolClubProgress>[];

    for (final SchoolClubProgress p in state.schoolClubs) {
      final SchoolClub? club = p.club;
      if (!p.active || club == null) {
        guncel.add(p);
        continue;
      }

      // Sezon performansı: beceri ağır basar, sağlık ve potansiyel küçük
      // pay, biraz da kura. Potansiyel tek başına domine etmez.
      final int perf = ((p.skill * 55 +
                      state.player.stats.health * 20 +
                      state.player.athleticPotential * 10) ~/
                  100 +
              rng.nextInt(16))
          .clamp(0, 100);

      // Beceri gelişimi: yaşa uygun, tek yılda sıçramayan.
      final int kalan = (100 - p.skill).clamp(0, 100);
      final int temel =
          (state.player.athleticPotential ~/ 20) + (perf >= 60 ? 2 : 1);
      final int artis =
          (temel * kalan ~/ 100).clamp(0, prototypeOnlyMaxSkillGainPerSeason);
      final int yeniBeceri = (p.skill + artis).clamp(0, 100);
      final int yeniYil = p.yearsActive + 1;

      SquadRole yeniRol = p.role;
      int? kaptanlik = p.captainSinceAge;
      if (club.competitive) {
        yeniRol = _roleFor(
          skill: yeniBeceri,
          years: yeniYil,
          performance: perf,
          charisma: state.player.stats.charisma,
          current: p.role,
        );
        if (yeniRol == SquadRole.kaptan && kaptanlik == null) {
          kaptanlik = state.player.age;
          milestones.add('${club.name} kaptanı oldun.');
        } else if (yeniRol.index > p.role.index) {
          log.add('${club.name}: artık ${yeniRol.label.toLowerCase()}sın.');
        }
      }

      log.add(_seasonLine(club, yeniRol, perf));

      guncel.add(p.copyWith(
        yearsActive: yeniYil,
        skill: yeniBeceri,
        performance: perf,
        role: yeniRol,
        captainSinceAge: kaptanlik,
        competitions: p.competitions + (club.competitive ? 1 : 0),
        awards: p.awards + (perf >= 85 && club.competitive ? 1 : 0),
      ));
    }
    return (
      state: state.copyWith(schoolClubs: guncel),
      log: log,
      milestones: milestones,
    );
  }

  /// Kadro rolü yalnızca beceri eşiğiyle belirlenmez.
  ///
  /// Yıllar, sezon performansı ve küçük bir karizma payı birlikte çalışır:
  /// bir yıl iyi oynayan çocuk kaptan olmaz; yıllarca takımda kalan ve
  /// performansı tutan olur.
  SquadRole _roleFor({
    required int skill,
    required int years,
    required int performance,
    required int charisma,
    required SquadRole current,
  }) {
    final int puan = skill * 45 ~/ 100 +
        (years * 6).clamp(0, 30) +
        performance * 20 ~/ 100 +
        charisma * 5 ~/ 100;
    SquadRole hedef;
    if (puan >= 78 && years >= 3) {
      hedef = SquadRole.kaptan;
    } else if (puan >= 62) {
      hedef = SquadRole.onemliOyuncu;
    } else if (puan >= 45) {
      hedef = SquadRole.ilkOnBir;
    } else if (puan >= 28) {
      hedef = SquadRole.rotasyon;
    } else {
      hedef = SquadRole.yedek;
    }
    // Rol tek sezonda iki kademe atlamasın; düşüş de kademeli olsun.
    if (hedef.index > current.index + 1) {
      return SquadRole.values[current.index + 1];
    }
    if (hedef.index < current.index - 1) {
      return SquadRole.values[current.index - 1];
    }
    return hedef;
  }

  String _seasonLine(SchoolClub club, SquadRole role, int performance) {
    if (!club.competitive) {
      return '${club.name}: bu yıl da devam ettin.';
    }
    if (role == SquadRole.yedek) {
      return '${club.name}: sezonu çoğunlukla kenarda geçirdin.';
    }
    if (performance >= 80) {
      return '${club.name}: iyi bir sezon oldu, hocanın güveni arttı.';
    }
    if (performance >= 55) {
      return '${club.name}: düzenli oynadın.';
    }
    return '${club.name}: sezon ortalamaydı.';
  }
}
