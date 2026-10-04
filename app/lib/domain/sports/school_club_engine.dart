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

  /// D-136: tek sezonda becerinin çıkabileceği en büyük artış.
  ///
  /// **Faho onayladı (4 Ekim 2026).** 9'dan 12'ye çıktı. Tavan bir
  /// güvenlik sınırıdır: azalan getiri çarpanı (`kalan`) zaten erken
  /// yılların dışında bu tavana yaklaştırmıyor, ama tek yılda sıçrama
  /// olmasın diye duruyor.
  static const int maxSkillGainPerSeason = 12;

  /// D-136: atletik yatkınlığın sezon gelişimine katkı böleni.
  ///
  /// **Faho onayladı (4 Ekim 2026).** 20'den 10'a indi; küçük bölen =
  /// yatkınlığın payı büyük. Eski değerde yatkınlığı 55 olan oyuncu
  /// sezon başına yalnızca 2 puanlık taban alıyordu ve beceri 4 sezonda
  /// medyan 13'te kalıyordu — rol eşikleri (İlk 11 için 45, Kaptan için
  /// 70) beceri 60-80 varsaydığı için takımda yükselmek matematiksel
  /// olarak imkânsıza yakındı.
  ///
  /// **Yatkınlık yine tek başına yetmez:** performans payı ve azalan
  /// getiri çarpanı duruyor, yani çalışan ve uzun süre kalan oyuncu
  /// yatkın ama geç başlayanı geçmeye devam ediyor.
  static const int skillPotentialDivisor = 10;

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

  /// D-134: kaptanlık için gereken rol puanı eşiği.
  ///
  /// **Faho onayladı (4 Ekim 2026).** Eşik 78'den 70'e indi. Ölçülen
  /// sebep: 500 okul odaklı hayatta kaptanlık **hiç** olmuyordu. Rol
  /// puanı `beceri×45 + (sezon×6, en çok 30) + performans×20 +
  /// karizma×5` (÷100) ve okul çağında ulaşılabilir en iyi bileşim
  /// 69-79 arasında kalıyor; 78 tam sınırdaydı, yani yalnızca
  /// neredeyse kusursuz bir bileşim geçiyordu.
  ///
  /// **Kıdem şartı ve tek kademe sınırı aynen duruyor:** kaptanlık en az
  /// üç sezon ister ve rol bir sezonda yalnızca bir kademe değişir.
  /// Eşik düştü, kıdem gevşemedi.
  static const int captainScoreThreshold = 70;

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

    // Okul bittiyse üyelik de biter (Paket AW düzeltmesi).
    //
    // ÖLÇÜLEN HATA: bu kontrol yoktu. `blockFor` "kulüpler yalnızca
    // okula devam ederken açık" diyordu ama sezon ilerlemesi öğrenci
    // olup olmadığına bakmıyordu. Mezun olan oyuncunun üyeliği açık
    // kalıyor ve `yearsActive` ömür boyu artıyordu: 500 hayatlık
    // ölçümde toplam sezon medyanı 58, en fazlası 160 çıktı — yani
    // 70 yaşındaki karakter hâlâ "okul futbol takımında" sayılıyordu.
    // Kayıt silinmez, geçmiş korunur; yalnızca üyelik kapanır.
    if (!state.education.isStudent) {
      final List<SchoolClubProgress> kapanan = <SchoolClubProgress>[
        for (final SchoolClubProgress p in state.schoolClubs)
          if (p.active)
            p.copyWith(active: false, leftAtAge: state.player.age)
          else
            p,
      ];
      return (
        state: state.copyWith(
          schoolClubs: List<SchoolClubProgress>.unmodifiable(kapanan),
        ),
        log: <String>[
          'Okul bitti; kulüp üyeliğin de kapandı. Geçmişin duruyor.',
        ],
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

      // Beceri gelişimi: yaşa uygun, tek yılda sıçramayan ama okul
      // hayatı boyunca gerçekten bir yere varan.
      //
      // ÖLÇÜLEN HATA (Paket AX): eski katsayılarla beceri 4 sezon
      // sonunda medyan **13**'te kalıyordu. Rol eşikleri (İlk 11 için 45,
      // Kaptan için 70) beceri 60-80 varsayıyor; yani takımda yükselmek
      // matematiksel olarak imkânsıza yakındı. Üstelik döngüsel:
      // beceri düşük → performans düşük → `temel` küçük kalıyor →
      // beceri yine düşük. 500 hayatta kaptanlık %0 çıkmasının sebebi
      // eşikler değil **bu** idi.
      //
      // Azalan getiri korundu (`kalan` çarpanı): tavana yaklaşan oyuncu
      // yavaşlar, tek yılda sıçrama olmaz. Değişen yalnızca tabanın
      // büyüklüğü.
      final int kalan = (100 - p.skill).clamp(0, 100);
      final int temel = (state.player.athleticPotential ~/
              skillPotentialDivisor) +
          (perf >= 60 ? 3 : 2);
      final int artis =
          (temel * kalan ~/ 100).clamp(0, maxSkillGainPerSeason);
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
  /// Takımdaki yeri belirleyen rol puanı (0-100 ölçeğinde değil, ham).
  ///
  /// Tek kaynak: hem rol ataması hem ölçüm bunu kullanır, formül iki
  /// yere kopyalanmaz.
  static int roleScore({
    required int skill,
    required int years,
    required int performance,
    required int charisma,
  }) =>
      skill * 45 ~/ 100 +
      (years * 6).clamp(0, 30) +
      performance * 20 ~/ 100 +
      charisma * 5 ~/ 100;

  SquadRole _roleFor({
    required int skill,
    required int years,
    required int performance,
    required int charisma,
    required SquadRole current,
  }) {
    final int puan = roleScore(
      skill: skill,
      years: years,
      performance: performance,
      charisma: charisma,
    );
    SquadRole hedef;
    if (puan >= captainScoreThreshold && years >= 3) {
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
