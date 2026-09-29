// Profesyonel dövüş/spor kariyeri (Paket AL).
//
// **Neden ayrı bir model.** `MartialProgress` teknik ilerlemeyi tutuyor:
// kaç ders alındı, hangi kuşak. O dokunulmadı. Rekabet ise başka bir
// şey — müsabaka, rakip, sıralama, sakatlık, ödül, emeklilik. İkisini
// tek modele sıkıştırmak ders almayı da rekabeti de bozardı.
//
// Bir oyuncu birden fazla sanatta rekabet edebilir; bu yüzden liste
// hâlinde tutulur ve `artId` ile eşleşir.
//
// Kayıt eklemesi **toplamsal**: eski kayıtlarda bu liste yok, boş
// olarak yüklenir ve hiçbir eski hayat bozulmaz.
library;

import 'package:flutter/foundation.dart';

import '../../data/martial_arts_catalog.dart';

/// Sporcunun rekabetteki durumu.
enum CompetitiveStatus {
  /// Ders alıyor olabilir ama müsabakaya girmiyor.
  yok('Müsabakaya çıkmıyor'),

  /// Amatör müsabakalarda.
  amator('Amatör'),

  /// Bokta profesyonel, turnuva sporlarında elit seviye.
  profesyonel('Profesyonel'),

  /// Spordan çekildi.
  emekli('Emekli');

  const CompetitiveStatus(this.label);

  final String label;
}

/// Sakatlığın ağırlığı.
enum InjurySeverity {
  yok('Sakatlık yok', 0),
  hafif('Hafif sakatlık', 1),
  orta('Orta sakatlık', 2),
  ciddi('Ciddi sakatlık', 3);

  const InjurySeverity(this.label, this.weight);

  final String label;
  final int weight;
}

/// Müsabaka öncesi hazırlık tercihi (§10).
enum CampChoice {
  dengeli('Dengeli hazırlan'),
  yogun('Yoğun kamp yap'),
  dinlen('Dinlenmeye öncelik ver');

  const CampChoice(this.label);

  final String label;
}

/// Spordan çekilme sebebi.
enum RetirementReason {
  kendiKarari('Kendi kararı'),
  sakatlik('Ciddi sakatlık'),
  yas('Yaş ve düşen performans');

  const RetirementReason(this.label);

  final String label;
}

/// Bir rakip. Kurgusaldır; gerçek bir sporcuya dayanmaz.
@immutable
class CombatOpponent {
  const CombatOpponent({
    required this.id,
    required this.name,
    required this.age,
    required this.rating,
    this.wins = 0,
    this.losses = 0,
    this.metCount = 0,
    this.playerWins = 0,
    this.playerLosses = 0,
  });

  final String id;
  final String name;
  final int age;

  /// Rakibin gücü (0-100).
  final int rating;

  final int wins;
  final int losses;

  /// Oyuncuyla kaç kez karşılaşıldı (§9).
  final int metCount;

  /// Bu karşılaşmalarda oyuncunun galibiyet/mağlubiyet sayısı.
  final int playerWins;
  final int playerLosses;

  /// Aralarında gerçek bir rekabet oluştu mu?
  bool get isRival => metCount >= 2;

  /// "İkiniz de birer kez kazandınız" gibi bir özet; yoksa `null`.
  String? get headToHead {
    if (metCount == 0) return null;
    if (playerWins == playerLosses) {
      return playerWins == 0
          ? null
          : 'İkiniz de $playerWins kez kazandınız.';
    }
    return playerWins > playerLosses
        ? 'Aranızda $playerWins-$playerLosses öndesin.'
        : 'Aranızda $playerLosses-$playerWins geridesin.';
  }

  CombatOpponent copyWith({
    int? wins,
    int? losses,
    int? metCount,
    int? playerWins,
    int? playerLosses,
    int? age,
    int? rating,
  }) =>
      CombatOpponent(
        id: id,
        name: name,
        age: age ?? this.age,
        rating: rating ?? this.rating,
        wins: wins ?? this.wins,
        losses: losses ?? this.losses,
        metCount: metCount ?? this.metCount,
        playerWins: playerWins ?? this.playerWins,
        playerLosses: playerLosses ?? this.playerLosses,
      );
}

/// Önüne çıkmış, henüz oynanmamış bir müsabaka fırsatı.
///
/// **Sonuç tohumu burada duruyor** (§44). Fırsat üretildiği anda
/// `seed` yazılır ve kayda girer; aynı müsabakayı kaydedip yükleyip
/// tekrar oynamak aynı temel sonucu verir. Bu çözüm yalnızca spor
/// kariyerine uygulanır — oyunun genel rastgelelik mimarisine
/// dokunulmadı.
@immutable
class PendingBout {
  const PendingBout({
    required this.tier,
    required this.opponent,
    required this.purse,
    required this.seed,
    required this.offeredAtAge,
    this.isTitle = false,
  });

  /// Hangi kademede (bkz. `CombatCircuit.tiers`).
  final int tier;

  final CombatOpponent opponent;

  /// Kazanılırsa ödenecek tutar (₺); kaybedilirse payı düşer.
  final int purse;

  /// Sonucun tohumu.
  final int seed;

  final int offeredAtAge;

  /// Şampiyonluk/kemer müsabakası mı?
  final bool isTitle;
}

/// Kariyer geçmişine düşen önemli an (§27).
@immutable
class CombatMemory {
  const CombatMemory({required this.age, required this.text});

  final int age;
  final String text;
}

/// Bir dövüş sanatındaki **rekabet** kariyeri.
@immutable
class CombatCareer {
  const CombatCareer({
    required this.artId,
    required this.startedCompetitiveAtAge,
    this.status = CompetitiveStatus.amator,
    this.tier = 0,
    this.amateurWins = 0,
    this.amateurLosses = 0,
    this.proWins = 0,
    this.proLosses = 0,
    this.championships = 0,
    this.isChampion = false,
    this.ranking = 0,
    this.lastBoutAge,
    this.form = 50,
    this.reputation = 0,
    this.careerEarnings = 0,
    this.sponsorEarnings = 0,
    this.injuryCount = 0,
    this.seriousInjuryCount = 0,
    this.injury = InjurySeverity.yok,
    this.injuryYearsLeft = 0,
    this.retiredAtAge,
    this.retirementReason,
    this.coachLevel = 0,
    this.opponents = const <CombatOpponent>[],
    this.pendingBout,
    this.memories = const <CombatMemory>[],
  });

  final String artId;

  /// Rekabete başlanan yaş.
  final int startedCompetitiveAtAge;

  final CompetitiveStatus status;

  /// Ulaşılan kademe (0 = kulüp/amatör … 3 = elit/profesyonel).
  final int tier;

  final int amateurWins;
  final int amateurLosses;
  final int proWins;
  final int proLosses;

  /// Kazanılmış şampiyonluk sayısı.
  final int championships;

  /// Şu anda unvan elde mi?
  final bool isChampion;

  /// Kademe içi sıralama; 0 = sıralama dışı, 1 en iyi.
  final int ranking;

  final int? lastBoutAge;

  /// Güncel form (0-100).
  final int form;

  /// Kariyer itibarı (0-100). Ünden ayrıdır: itibar spor çevresinde,
  /// ün kamuoyunda.
  final int reputation;

  final int careerEarnings;
  final int sponsorEarnings;

  final int injuryCount;
  final int seriousInjuryCount;

  /// Şu anki sakatlık.
  final InjurySeverity injury;

  /// Sakatlığın kaç yıl daha müsabakayı kapattığı.
  final int injuryYearsLeft;

  final int? retiredAtAge;
  final RetirementReason? retirementReason;

  /// Antrenör kalitesi: 0 kulüp hocası, 1 deneyimli koç, 2 elit koç.
  final int coachLevel;

  /// Tanınan rakipler (§8). Liste bilerek kısa tutulur.
  final List<CombatOpponent> opponents;

  final PendingBout? pendingBout;

  final List<CombatMemory> memories;

  MartialArt? get art => martialArtById(artId);

  bool get isRetired => retiredAtAge != null;

  bool get isInjured => injury != InjurySeverity.yok && injuryYearsLeft > 0;

  int get totalWins => amateurWins + proWins;
  int get totalLosses => amateurLosses + proLosses;
  int get totalBouts => totalWins + totalLosses;

  /// "12G - 2M" gibi kısa rekor (§25).
  String get record => '${totalWins}G - ${totalLosses}M';

  /// Profesyonel/elit rekoru ayrı gösterilir.
  String get proRecord => '${proWins}G - ${proLosses}M';

  CombatCareer copyWith({
    CompetitiveStatus? status,
    int? tier,
    int? amateurWins,
    int? amateurLosses,
    int? proWins,
    int? proLosses,
    int? championships,
    bool? isChampion,
    int? ranking,
    int? lastBoutAge,
    int? form,
    int? reputation,
    int? careerEarnings,
    int? sponsorEarnings,
    int? injuryCount,
    int? seriousInjuryCount,
    InjurySeverity? injury,
    int? injuryYearsLeft,
    int? retiredAtAge,
    RetirementReason? retirementReason,
    int? coachLevel,
    List<CombatOpponent>? opponents,
    Object? pendingBout = _unset,
    List<CombatMemory>? memories,
  }) =>
      CombatCareer(
        artId: artId,
        startedCompetitiveAtAge: startedCompetitiveAtAge,
        status: status ?? this.status,
        tier: tier ?? this.tier,
        amateurWins: amateurWins ?? this.amateurWins,
        amateurLosses: amateurLosses ?? this.amateurLosses,
        proWins: proWins ?? this.proWins,
        proLosses: proLosses ?? this.proLosses,
        championships: championships ?? this.championships,
        isChampion: isChampion ?? this.isChampion,
        ranking: ranking ?? this.ranking,
        lastBoutAge: lastBoutAge ?? this.lastBoutAge,
        form: (form ?? this.form).clamp(0, 100),
        reputation: (reputation ?? this.reputation).clamp(0, 100),
        careerEarnings: careerEarnings ?? this.careerEarnings,
        sponsorEarnings: sponsorEarnings ?? this.sponsorEarnings,
        injuryCount: injuryCount ?? this.injuryCount,
        seriousInjuryCount: seriousInjuryCount ?? this.seriousInjuryCount,
        injury: injury ?? this.injury,
        injuryYearsLeft: injuryYearsLeft ?? this.injuryYearsLeft,
        retiredAtAge: retiredAtAge ?? this.retiredAtAge,
        retirementReason: retirementReason ?? this.retirementReason,
        coachLevel: coachLevel ?? this.coachLevel,
        opponents: opponents ?? this.opponents,
        pendingBout:
            pendingBout == _unset ? this.pendingBout : pendingBout as PendingBout?,
        memories: memories ?? this.memories,
      );

  /// Kariyer geçmişine bir an ekler; sıradan antrenman yazılmaz (§27).
  CombatCareer remember(int age, String text) => copyWith(
        memories: List<CombatMemory>.unmodifiable(<CombatMemory>[
          ...memories,
          CombatMemory(age: age, text: text),
        ]),
      );
}

const Object _unset = Object();
