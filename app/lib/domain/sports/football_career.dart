/// Profesyonel futbol kariyeri — minimal model ve uygunluk kapısı
/// (Paket AU).
///
/// **Bu paket bütün futbol oyununu bitirmez.** Sezon simülasyonu, lig
/// tablosu, kontrat ve transfer sonraki paketlerin işi (AV/AW/AX/AY).
/// Buradaki model yalnızca o paketlerin üzerine kurulacağı doğru temeli
/// atar — ve **henüz kullanılmayacak alan doldurulmaz.**
///
/// **En önemli kural:** profesyonel futbola 18-25 yaşında bir düğmeyle
/// girilmez. Kapı çocukluk/gençlik döneminde kurulmuş gerçek bir futbol
/// geçmişi ister. `FootballEligibility` tam olarak bunu ölçer ve
/// `footballSkill = 0` + hiç okul takımı olmayan bir oyuncuya kapıyı
/// açmaz.
///
/// **Futbolculuk normal bir meslek değildir:** `kJobCatalog` içine
/// eklenmez. Kendi kariyer durumunu taşır, çünkü ileride kulüp, lig,
/// sezon, kontrat, transfer ve istatistik taşıyacak.
library;

import 'package:flutter/foundation.dart';

import '../../data/school_club_catalog.dart';
import '../models/game_state.dart';
import '../models/school_club_progress.dart';

/// Sahadaki mevki. İlk sürümde dört ana mevki; sağ bek / 10 numara gibi
/// on beş mevkiye bölünmedi.
enum FootballPosition {
  kaleci('Kaleci'),
  defans('Defans'),
  ortaSaha('Orta saha'),
  forvet('Forvet');

  const FootballPosition(this.label);

  final String label;
}

/// Bir profesyonel sezonun özeti. Sezon simülasyonu AV'de gelecek;
/// burada yalnızca taşınacak kabuk var.
@immutable
class FootballSeason {
  const FootballSeason({
    required this.age,
    required this.clubId,
    required this.leagueId,
    this.appearances = 0,
    this.goals = 0,
    this.rating = 0,
  });

  final int age;
  final String clubId;
  final String leagueId;
  final int appearances;
  final int goals;
  final int rating;
}

/// Profesyonel futbol kariyeri durumu.
@immutable
class FootballCareer {
  const FootballCareer({
    required this.startedAtAge,
    required this.position,
    this.active = true,
    this.retiredAtAge,
    this.currentClubId,
    this.currentLeagueId,
    this.form = 50,
    this.reputation = 0,
    this.seasonHistory = const <FootballSeason>[],
  });

  final bool active;
  final int startedAtAge;
  final int? retiredAtAge;

  /// Şu anki kulüp ve lig. Kulüp kataloğu gelene kadar `null` kalabilir.
  final String? currentClubId;
  final String? currentLeagueId;

  final FootballPosition position;

  /// Form (0-100). Sezon performansını AV'de besleyecek.
  final int form;

  /// Futbol dünyasındaki itibar. Ün (`fame`) ile aynı şey değildir ve
  /// okul futbolu ün açmaz.
  final int reputation;

  final List<FootballSeason> seasonHistory;

  /// Kariyerin genel seviyesi `footballSkill`ten okunur; burada kopyası
  /// tutulmaz ki iki yerde farklı değer oluşmasın.
  int overallFrom(GameState state) =>
      state.schoolClubs.bestSkillInSport(kFootballSportId);

  FootballCareer copyWith({
    bool? active,
    int? retiredAtAge,
    String? currentClubId,
    String? currentLeagueId,
    FootballPosition? position,
    int? form,
    int? reputation,
    List<FootballSeason>? seasonHistory,
  }) =>
      FootballCareer(
        startedAtAge: startedAtAge,
        position: position ?? this.position,
        active: active ?? this.active,
        retiredAtAge: retiredAtAge ?? this.retiredAtAge,
        currentClubId: currentClubId ?? this.currentClubId,
        currentLeagueId: currentLeagueId ?? this.currentLeagueId,
        form: form ?? this.form,
        reputation: reputation ?? this.reputation,
        seasonHistory: seasonHistory ?? this.seasonHistory,
      );
}

/// Spor kariyeri ekranında futbolun hangi aşamada olduğu.
enum FootballStage {
  /// Hiç futbol geçmişi yok.
  gecmisYok,

  /// Futbol oynanıyor/oynandı ama profesyonel deneme için yetmiyor.
  gelisiyor,

  /// Profesyonel deneme kapısı açık.
  denemeyeUygun,

  /// Aktif profesyonel.
  aktifProfesyonel,

  /// Emekli.
  emekli,
}

/// Profesyonel futbol uygunluğunun **deterministik** değerlendirmesi.
///
/// Kura yok: aynı geçmiş her zaman aynı sonucu verir. Böylece "11 yaşında
/// başlayıp 7 yıl oynayan" ile "17 yaşında başlayıp 1 yıl oynayan"
/// karşılaştırması tek testte kurasız ölçülebilir.
@immutable
class FootballEligibility {
  const FootballEligibility({
    required this.eligible,
    required this.stage,
    required this.reason,
    required this.score,
    required this.seasons,
    required this.skill,
    required this.startedAtAge,
    required this.wasCaptain,
  });

  final bool eligible;
  final FootballStage stage;

  /// Oyuncuya gösterilecek gerekçe. **Kuru "uygun değilsin" yazılmaz.**
  final String reason;

  /// Hazırlık puanı (0-100). Karşılaştırmalı test bunu ölçer.
  final int score;

  final int seasons;
  final int skill;
  final int? startedAtAge;
  final bool wasCaptain;
}

/// Uygunluk kuralları. Eşiklerin hepsi `prototypeOnly` — Q-192.
abstract final class FootballPath {
  /// Profesyonel denemeye girilebilecek en küçük yaş (`prototypeOnly`).
  static const int prototypeOnlyMinTrialAge = 16;

  /// Profesyonel denemeye **ilk** girilebilecek en büyük yaş
  /// (`prototypeOnly`).
  ///
  /// 45 yaşında ilk kez profesyonel futbola giriş olmamalı. Gerçek
  /// transfer/emeklilik eğrisi AV'nin işi; burada makul bir genç
  /// yetişkin penceresi var.
  static const int prototypeOnlyMaxFirstTrialAge = 23;

  /// En az kaç sezon okul/gençlik futbolu (`prototypeOnly`).
  static const int prototypeOnlyMinSeasons = 3;

  /// En az futbol becerisi (`prototypeOnly`).
  static const int prototypeOnlyMinSkill = 45;

  /// Profesyonel deneme için en az sağlık (`prototypeOnly`).
  static const int prototypeOnlyMinHealth = 55;

  /// Geçme eşiği (`prototypeOnly`).
  static const int prototypeOnlyMinScore = 55;

  /// Scout ilgisinin başlayabileceği en küçük yaş (`prototypeOnly`).
  static const int prototypeOnlyScoutMinAge = 15;

  /// Scout ilgisi için en az hazırlık puanı (`prototypeOnly`).
  static const int prototypeOnlyScoutMinScore = 48;

  /// Oyuncunun futbol geçmişini değerlendirir.
  static FootballEligibility evaluate(GameState state) {
    final int seasons = state.schoolClubs.seasonsInSport(kFootballSportId);
    final int skill = state.schoolClubs.bestSkillInSport(kFootballSportId);
    final int? startedAt =
        state.schoolClubs.firstStartAgeInSport(kFootballSportId);
    final bool captain =
        state.schoolClubs.wasCaptainInSport(kFootballSportId);
    final int age = state.player.age;
    final int health = state.player.stats.health;

    final FootballCareer? kariyer = state.footballCareer;
    if (kariyer != null) {
      if (kariyer.active) {
        return FootballEligibility(
          eligible: false,
          stage: FootballStage.aktifProfesyonel,
          reason: 'Profesyonel futbol kariyerin sürüyor.',
          score: 100,
          seasons: seasons,
          skill: skill,
          startedAtAge: startedAt,
          wasCaptain: captain,
        );
      }
      return FootballEligibility(
        eligible: false,
        stage: FootballStage.emekli,
        reason: 'Futbolu bıraktın.',
        score: 0,
        seasons: seasons,
        skill: skill,
        startedAtAge: startedAt,
        wasCaptain: captain,
      );
    }

    // Hazırlık puanı: geçmiş + çalışma + yetenek + sağlık birlikte.
    // Atletik potansiyel burada **küçük** paya sahip; tek başına kapıyı
    // açmaz.
    final int erkenBaslama = startedAt == null
        ? 0
        : (14 - startedAt).clamp(0, 6) * 3; // 11'de başlamak 9 puan
    final int score = (seasons * 7).clamp(0, 35) +
        skill * 35 ~/ 100 +
        erkenBaslama +
        health * 10 ~/ 100 +
        state.player.athleticPotential * 10 ~/ 100 +
        (captain ? 4 : 0);

    if (seasons == 0) {
      return FootballEligibility(
        eligible: false,
        stage: FootballStage.gecmisYok,
        reason: 'Profesyonel futbol için gençlik döneminden gelen düzenli '
            'futbol geçmişin yok.',
        score: score.clamp(0, 100),
        seasons: seasons,
        skill: skill,
        startedAtAge: startedAt,
        wasCaptain: captain,
      );
    }
    if (age < prototypeOnlyMinTrialAge) {
      return FootballEligibility(
        eligible: false,
        stage: FootballStage.gelisiyor,
        reason: 'Profesyonel deneme için henüz çok erken; şimdilik '
            'oynamaya devam.',
        score: score.clamp(0, 100),
        seasons: seasons,
        skill: skill,
        startedAtAge: startedAt,
        wasCaptain: captain,
      );
    }
    if (age > prototypeOnlyMaxFirstTrialAge) {
      return FootballEligibility(
        eligible: false,
        stage: FootballStage.gelisiyor,
        reason: 'Profesyonel futbola ilk giriş için yaş penceresi kapandı.',
        score: score.clamp(0, 100),
        seasons: seasons,
        skill: skill,
        startedAtAge: startedAt,
        wasCaptain: captain,
      );
    }
    if (health < prototypeOnlyMinHealth) {
      return FootballEligibility(
        eligible: false,
        stage: FootballStage.gelisiyor,
        reason: 'Sağlığın profesyonel deneme için yeterli değil.',
        score: score.clamp(0, 100),
        seasons: seasons,
        skill: skill,
        startedAtAge: startedAt,
        wasCaptain: captain,
      );
    }
    if (seasons < prototypeOnlyMinSeasons ||
        skill < prototypeOnlyMinSkill ||
        score < prototypeOnlyMinScore) {
      return FootballEligibility(
        eligible: false,
        stage: FootballStage.gelisiyor,
        reason: 'Futbol geçmişin var ancak şu an profesyonel deneme için '
            'yeterli seviyede değilsin.',
        score: score.clamp(0, 100),
        seasons: seasons,
        skill: skill,
        startedAtAge: startedAt,
        wasCaptain: captain,
      );
    }
    return FootballEligibility(
      eligible: true,
      stage: FootballStage.denemeyeUygun,
      reason: 'Gençlik futbolundan gelen geçmişin profesyonel deneme için '
          'yeterli. Garanti değil; deneme denemedir.',
      score: score.clamp(0, 100),
      seasons: seasons,
      skill: skill,
      startedAtAge: startedAt,
      wasCaptain: captain,
    );
  }

  /// Scout ilgisi doğabilir mi? **Teklif garantisi değildir.**
  ///
  /// Yılda beş scout, sekiz kulüp olmaz: ilk scout kilometre taşı olsun
  /// diye koşullar dar tutuldu.
  static bool scoutInterest(GameState state) {
    final FootballEligibility u = evaluate(state);
    if (u.stage == FootballStage.aktifProfesyonel ||
        u.stage == FootballStage.emekli) {
      return false;
    }
    if (state.player.age < prototypeOnlyScoutMinAge) return false;
    if (u.seasons < 2) return false;
    final SchoolClubProgress? aktif =
        state.schoolClubs.activeFor(footballClub.id);
    // Scout izlemek için sahada olmak gerekir: ilk 11 ya da üstü.
    if (aktif == null || !aktif.role.isAtLeastFirstEleven) return false;
    return u.score >= prototypeOnlyScoutMinScore;
  }

  /// Oyuncunun gençlik futbolu özeti (Spor Kariyeri ekranı için).
  ///
  /// "Ortaokul futbol takımı — 3 yıl" gibi satırlar; iç sayılar
  /// gösterilmez.
  static List<String> youthSummary(GameState state) {
    final List<SchoolClubProgress> kayitlar =
        state.schoolClubs.forSport(kFootballSportId);
    if (kayitlar.isEmpty) return const <String>[];
    final List<String> out = <String>[];
    for (final SchoolClubProgress p in kayitlar) {
      final String kademe = _kademeAdi(p.joinedAtGrade);
      out.add('$kademe futbol takımı — ${p.yearsActive} yıl');
    }
    final int kaptanYil = kayitlar
        .where((SchoolClubProgress p) => p.wasCaptain)
        .length;
    if (kaptanYil > 0) out.add('Kaptanlık yapıldı');
    return out;
  }

  static String _kademeAdi(int grade) {
    if (grade <= 4) return 'İlkokul';
    if (grade <= 8) return 'Ortaokul';
    return 'Lise';
  }
}
