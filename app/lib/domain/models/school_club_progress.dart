/// Bir okul kulübündeki kalıcı geçmiş (Paket AU).
///
/// **Bu kaydın varlık sebebi:** oyuncu 11 yaşında futbol takımına girdiyse,
/// 15 yaşında hâlâ oynuyorsa, 17 yaşında kaptansa — bu geçmiş 20 yaşında
/// yok olmamalı. Profesyonel futbol kapısı tam olarak bu kayda bakacak.
///
/// Okul değişince kayıt **silinmez**: `schoolId` hangi okulda yaşandığını
/// tutar, `active` o üyeliğin sürüp sürmediğini. Yeni okulda yeniden
/// başvurulur; geçmiş deneyim kabul ihtimaline yardım eder ama üyelik
/// kendiliğinden taşınmaz.
library;

import 'package:flutter/foundation.dart';

import '../../data/school_club_catalog.dart';

/// Takım sporlarında kadrodaki yer.
///
/// Sırası anlamlıdır: `index` büyüdükçe rol büyür. Rol yalnızca beceri
/// eşiğiyle değil; yıllar, performans ve biraz karizma ile ilerler.
enum SquadRole {
  yedek('Yedek'),
  rotasyon('Rotasyon'),
  ilkOnBir('İlk 11'),
  onemliOyuncu('Önemli oyuncu'),
  kaptan('Kaptan');

  const SquadRole(this.label);

  final String label;

  bool get isAtLeastFirstEleven => index >= SquadRole.ilkOnBir.index;
}

/// Bir kulüpteki ilerleme ve geçmiş.
@immutable
class SchoolClubProgress {
  const SchoolClubProgress({
    required this.clubId,
    required this.schoolId,
    required this.joinedAtAge,
    required this.joinedAtGrade,
    this.active = true,
    this.leftAtAge,
    this.yearsActive = 0,
    this.skill = 0,
    this.performance = 50,
    this.role = SquadRole.yedek,
    this.captainSinceAge,
    this.competitions = 0,
    this.awards = 0,
    this.lastPracticedAge,
  });

  final String clubId;

  /// Bu üyeliğin yaşandığı okul. Okul değişince yeni kayıt açılır.
  final String schoolId;

  final int joinedAtAge;
  final int joinedAtGrade;

  /// Üyelik sürüyor mu? Geçmiş kayıt `false` olarak **kalır**, silinmez.
  final bool active;

  /// Ayrılınan yaş (ayrıldıysa).
  final int? leftAtAge;

  /// Bu kulüpte geçirilen sezon sayısı.
  final int yearsActive;

  /// Kulübe özgü beceri (0-100).
  ///
  /// Atletik potansiyelden **farklıdır**: yetenekli olup hiç oynamamış biri
  /// yüksek potansiyele ve düşük beceriye sahip olabilir. Beceri yıllarla,
  /// antrenmanla ve sağlıkla yükselir; tek yılda sıçramaz.
  final int skill;

  /// Son sezonun performansı (0-100).
  final int performance;

  final SquadRole role;

  /// Kaptanlığa geçilen yaş (geçildiyse). Kalıcı geçmiş.
  final int? captainSinceAge;

  /// Katılınan turnuva sayısı.
  final int competitions;

  /// Kazanılan derece/ödül sayısı.
  final int awards;

  /// En son antrenman/çalışma yapılan yaş (yılda bir kez sayaç için).
  final int? lastPracticedAge;

  SchoolClub? get club => schoolClubById(clubId);

  /// Kaptanlık yapıldı mı (şu an ya da geçmişte)?
  bool get wasCaptain => captainSinceAge != null;

  /// Oyuncuya gösterilecek beceri bandı. **Yüzde gösterilmez.**
  String get skillBand {
    if (skill >= 80) return 'Çok iyi';
    if (skill >= 60) return 'İyi';
    if (skill >= 40) return 'Orta';
    if (skill >= 20) return 'Gelişiyor';
    return 'Yeni';
  }

  SchoolClubProgress copyWith({
    bool? active,
    int? leftAtAge,
    int? yearsActive,
    int? skill,
    int? performance,
    SquadRole? role,
    int? captainSinceAge,
    int? competitions,
    int? awards,
    int? lastPracticedAge,
  }) =>
      SchoolClubProgress(
        clubId: clubId,
        schoolId: schoolId,
        joinedAtAge: joinedAtAge,
        joinedAtGrade: joinedAtGrade,
        active: active ?? this.active,
        leftAtAge: leftAtAge ?? this.leftAtAge,
        yearsActive: yearsActive ?? this.yearsActive,
        skill: skill ?? this.skill,
        performance: performance ?? this.performance,
        role: role ?? this.role,
        captainSinceAge: captainSinceAge ?? this.captainSinceAge,
        competitions: competitions ?? this.competitions,
        awards: awards ?? this.awards,
        lastPracticedAge: lastPracticedAge ?? this.lastPracticedAge,
      );
}

/// Kulüp geçmişi üzerinde okuma yardımcıları.
///
/// Motorun ve uygunluk kontrolünün aynı soruyu iki ayrı yerde farklı
/// hesaplamasını önlemek için tek yerde durur.
extension SchoolClubHistory on List<SchoolClubProgress> {
  /// Belirli kulüpteki **aktif** kayıt (yoksa `null`).
  SchoolClubProgress? activeFor(String clubId) {
    for (final SchoolClubProgress p in this) {
      if (p.clubId == clubId && p.active) return p;
    }
    return null;
  }

  /// Şu an aktif olan bütün üyelikler.
  List<SchoolClubProgress> get activeOnes =>
      <SchoolClubProgress>[for (final SchoolClubProgress p in this) if (p.active) p];

  /// Belirli spor kimliğine ait bütün kayıtlar (geçmiş dahil).
  List<SchoolClubProgress> forSport(String sportId) => <SchoolClubProgress>[
        for (final SchoolClubProgress p in this)
          if (p.club?.associatedSportId == sportId) p,
      ];

  /// Bir spora ayrılan toplam sezon.
  int seasonsInSport(String sportId) {
    int toplam = 0;
    for (final SchoolClubProgress p in forSport(sportId)) {
      toplam += p.yearsActive;
    }
    return toplam;
  }

  /// Bir spordaki en yüksek beceri.
  int bestSkillInSport(String sportId) {
    int enIyi = 0;
    for (final SchoolClubProgress p in forSport(sportId)) {
      if (p.skill > enIyi) enIyi = p.skill;
    }
    return enIyi;
  }

  /// Bir sporda kaptanlık yapıldı mı?
  bool wasCaptainInSport(String sportId) {
    for (final SchoolClubProgress p in forSport(sportId)) {
      if (p.wasCaptain) return true;
    }
    return false;
  }

  /// Bir spora **ilk** başlanan yaş (hiç başlanmadıysa `null`).
  int? firstStartAgeInSport(String sportId) {
    int? ilk;
    for (final SchoolClubProgress p in forSport(sportId)) {
      if (ilk == null || p.joinedAtAge < ilk) ilk = p.joinedAtAge;
    }
    return ilk;
  }
}
