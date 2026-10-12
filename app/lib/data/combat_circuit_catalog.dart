// Altı dövüş sanatının **kariyer yolu** (Paket AL, §1).
//
// Ortak motor, farklı anlatı. Boksun basamakları güreşin basamakları
// gibi okunmaz; turnuva sporlarının ödül modeli boksun maç gelirine
// benzemez. Bu dosya o farkı tutar, motor değil.
//
// **Gerçek kurum adı yok.** Organizasyonlar kurgusaldır ve hiçbir
// federasyon, lig ya da şirket verisine bağlı değildir (§1).
//
// **Ödüller oyunun kendi ölçeğinden türer** (§14): hepsi net yıllık
// asgari ücretin katı olarak yazılır, gerçek güncel fiyat hardcode
// edilmez. Çıpa kayarsa ödüller birlikte kayar.
//
// Bütün sayılar `prototypeOnly`'dir.
library;

import 'economy.dart';
import 'martial_arts_catalog.dart';

/// Bir kariyer kademesi.
class CombatTier {
  const CombatTier({
    required this.label,
    required this.levelRatio,
    required this.minAge,
    required this.opponentRating,
    required this.purseShare,
    required this.yearlyChances,
    required this.fameGain,
    required this.injuryRisk,
  });

  /// Ekranda görünen ad ("Bölgesel maçlar", "Boy müsabakaları"…).
  final String label;

  /// Bu kademeye girmek için sanatın kendi basamak merdiveninde
  /// gereken oran (0-1). Sanatların basamak sayısı farklı olduğu için
  /// sabit sayı değil oran tutulur.
  final double levelRatio;

  final int minAge;

  /// Bu kademedeki tipik rakip gücü (0-100 ortalaması).
  final int opponentRating;

  /// Galibiyet ödülü: net yıllık asgari ücretin kaç katı.
  ///
  /// Amatör kademede sıfıra yakındır (§13): spor otomatik zenginlik
  /// makinesi değil.
  final double purseShare;

  /// Bir yılda **en fazla** kaç müsabaka fırsatı çıkabilir (§43).
  /// Fırsatın çıkacağı garanti değildir.
  final int yearlyChances;

  /// Bu kademede kazanmanın üne katkısı (§17).
  final int fameGain;

  /// Bu kademenin taban sakatlık riski (0-1 ölçeğinde pay).
  final double injuryRisk;

  /// Galibiyet ödülü (₺).
  int get purse => (Economy.netYearlyMinimumWage * purseShare).round();
}

/// Bir sanatın kariyer yolu.
class CombatCircuit {
  const CombatCircuit({
    required this.artId,
    required this.tiers,
    required this.titleLabel,
    required this.proLabel,
    required this.turnsProAtTier,
    required this.titlePurseShare,
    required this.wearFactor,
  });

  final String artId;

  /// Dört kademe: kulüp → bölge → ulusal → elit/profesyonel.
  final List<CombatTier> tiers;

  /// Şampiyonluğun adı ("Kemer maçı", "Başpehlivanlık"…).
  final String titleLabel;

  /// En üst kademedeki sporcunun adı ("Profesyonel boksör", "Elit
  /// sporcu"…).
  final String proLabel;

  /// Bu kademeye çıkınca durum `profesyonel` olur.
  final int turnsProAtTier;

  /// Şampiyonluk ödülü: net yıllık asgari ücretin kaç katı.
  final double titlePurseShare;

  /// Sanatın yıpratıcılığı (sakatlık ve yaş eğrisini ölçekler).
  ///
  /// Boks en yüksek, judo/karate/taekwondo orta, kung fu en düşük.
  final double wearFactor;

  MartialArt? get art => martialArtById(artId);

  int get titlePurse => (Economy.netYearlyMinimumWage * titlePurseShare).round();

  /// Bu kademeye girmek için gereken teknik basamak.
  int minLevelFor(int tier) {
    final MartialArt? a = art;
    if (a == null) return 0;
    final double oran = tiers[tier.clamp(0, tiers.length - 1)].levelRatio;
    return (a.topLevel * oran).ceil().clamp(1, a.topLevel);
  }
}

/// prototypeOnly: altı sanatın kariyer yolu.
const List<CombatCircuit> kCombatCircuits = <CombatCircuit>[
  // --- BOKS: amatör ring → profesyonelliğe geçiş → kemer -------------
  CombatCircuit(
    artId: 'boks',
    titleLabel: 'Kemer maçı',
    proLabel: 'Profesyonel boksör',
    turnsProAtTier: 3,
    titlePurseShare: 4.5,
    wearFactor: 1.15,
    tiers: <CombatTier>[
      CombatTier(
        label: 'Amatör maçlar',
        levelRatio: 0.25,
        minAge: 14,
        opponentRating: 32,
        purseShare: 0.0,
        yearlyChances: 3,
        fameGain: 0,
        injuryRisk: 0.10,
      ),
      CombatTier(
        label: 'Bölgesel maçlar',
        levelRatio: 0.45,
        minAge: 16,
        opponentRating: 48,
        purseShare: 0.12,
        yearlyChances: 3,
        fameGain: 1,
        injuryRisk: 0.14,
      ),
      CombatTier(
        label: 'Ulusal amatör',
        levelRatio: 0.62,
        minAge: 18,
        opponentRating: 62,
        purseShare: 0.35,
        yearlyChances: 2,
        fameGain: 3,
        injuryRisk: 0.17,
      ),
      CombatTier(
        label: 'Profesyonel ring',
        levelRatio: 0.80,
        minAge: 19,
        opponentRating: 76,
        purseShare: 1.10,
        yearlyChances: 2,
        fameGain: 6,
        injuryRisk: 0.22,
      ),
    ],
  ),

  // --- YAĞLI GÜREŞ: yerel → boy → bölgesel → büyük organizasyon ------
  CombatCircuit(
    artId: 'gures',
    titleLabel: 'Başpehlivanlık',
    proLabel: 'Başaltı pehlivan',
    turnsProAtTier: 3,
    titlePurseShare: 3.8,
    wearFactor: 1.10,
    tiers: <CombatTier>[
      CombatTier(
        label: 'Yerel güreş',
        levelRatio: 0.25,
        minAge: 12,
        opponentRating: 30,
        purseShare: 0.0,
        yearlyChances: 3,
        fameGain: 0,
        injuryRisk: 0.08,
      ),
      CombatTier(
        label: 'Boy müsabakaları',
        levelRatio: 0.45,
        minAge: 15,
        opponentRating: 46,
        purseShare: 0.10,
        yearlyChances: 3,
        fameGain: 1,
        injuryRisk: 0.12,
      ),
      CombatTier(
        label: 'Bölgesel organizasyon',
        levelRatio: 0.62,
        minAge: 17,
        opponentRating: 60,
        purseShare: 0.30,
        yearlyChances: 3,
        fameGain: 3,
        injuryRisk: 0.15,
      ),
      CombatTier(
        label: 'Büyük organizasyon',
        levelRatio: 0.80,
        minAge: 19,
        opponentRating: 74,
        purseShare: 0.85,
        yearlyChances: 2,
        fameGain: 6,
        injuryRisk: 0.18,
      ),
    ],
  ),

  // --- JUDO: kulüp → bölge → ulusal → elit ---------------------------
  CombatCircuit(
    artId: 'judo',
    titleLabel: 'Uluslararası şampiyonluk',
    proLabel: 'Elit judocu',
    turnsProAtTier: 3,
    titlePurseShare: 3.2,
    wearFactor: 1.00,
    tiers: <CombatTier>[
      CombatTier(
        label: 'Kulüp müsabakası',
        levelRatio: 0.25,
        minAge: 11,
        opponentRating: 30,
        purseShare: 0.0,
        yearlyChances: 4,
        fameGain: 0,
        injuryRisk: 0.07,
      ),
      CombatTier(
        label: 'Bölge turnuvası',
        levelRatio: 0.45,
        minAge: 14,
        opponentRating: 46,
        purseShare: 0.08,
        yearlyChances: 3,
        fameGain: 1,
        injuryRisk: 0.10,
      ),
      CombatTier(
        label: 'Ulusal turnuva',
        levelRatio: 0.62,
        minAge: 17,
        opponentRating: 60,
        purseShare: 0.28,
        yearlyChances: 3,
        fameGain: 3,
        injuryRisk: 0.13,
      ),
      CombatTier(
        label: 'Elit turnuva',
        levelRatio: 0.80,
        minAge: 19,
        opponentRating: 75,
        purseShare: 0.75,
        yearlyChances: 2,
        fameGain: 6,
        injuryRisk: 0.16,
      ),
    ],
  ),

  // --- KARATE: kulüp → bölge → ulusal → elit kumite -------------------
  CombatCircuit(
    artId: 'karate',
    titleLabel: 'Ulusal şampiyonluk',
    proLabel: 'Elit karateci',
    turnsProAtTier: 3,
    titlePurseShare: 3.0,
    wearFactor: 0.95,
    tiers: <CombatTier>[
      CombatTier(
        label: 'Kulüp müsabakası',
        levelRatio: 0.25,
        minAge: 11,
        opponentRating: 30,
        purseShare: 0.0,
        yearlyChances: 4,
        fameGain: 0,
        injuryRisk: 0.06,
      ),
      CombatTier(
        label: 'Bölge turnuvası',
        levelRatio: 0.45,
        minAge: 14,
        opponentRating: 45,
        purseShare: 0.08,
        yearlyChances: 3,
        fameGain: 1,
        injuryRisk: 0.09,
      ),
      CombatTier(
        label: 'Ulusal turnuva',
        levelRatio: 0.62,
        minAge: 17,
        opponentRating: 59,
        purseShare: 0.26,
        yearlyChances: 3,
        fameGain: 3,
        injuryRisk: 0.12,
      ),
      CombatTier(
        label: 'Elit kumite turnuvası',
        levelRatio: 0.80,
        minAge: 19,
        opponentRating: 74,
        purseShare: 0.70,
        yearlyChances: 2,
        fameGain: 6,
        injuryRisk: 0.14,
      ),
    ],
  ),

  // --- TAEKWONDO: kulüp → bölge → ulusal → elit -----------------------
  CombatCircuit(
    artId: 'taekwondo',
    titleLabel: 'Ulusal şampiyonluk',
    proLabel: 'Elit taekwondocu',
    turnsProAtTier: 3,
    titlePurseShare: 3.0,
    wearFactor: 0.95,
    tiers: <CombatTier>[
      CombatTier(
        label: 'Kulüp müsabakası',
        levelRatio: 0.25,
        minAge: 11,
        opponentRating: 30,
        purseShare: 0.0,
        yearlyChances: 4,
        fameGain: 0,
        injuryRisk: 0.06,
      ),
      CombatTier(
        label: 'Bölge turnuvası',
        levelRatio: 0.45,
        minAge: 14,
        opponentRating: 45,
        purseShare: 0.08,
        yearlyChances: 3,
        fameGain: 1,
        injuryRisk: 0.09,
      ),
      CombatTier(
        label: 'Ulusal turnuva',
        levelRatio: 0.62,
        minAge: 17,
        opponentRating: 59,
        purseShare: 0.26,
        yearlyChances: 3,
        fameGain: 3,
        injuryRisk: 0.12,
      ),
      CombatTier(
        label: 'Elit turnuva',
        levelRatio: 0.80,
        minAge: 19,
        opponentRating: 74,
        purseShare: 0.70,
        yearlyChances: 2,
        fameGain: 6,
        injuryRisk: 0.14,
      ),
    ],
  ),

  // --- KUNG FU: okul içi → açık turnuva → bölgesel → ulusal -----------
  CombatCircuit(
    artId: 'kung_fu',
    titleLabel: 'Ulusal şampiyonluk',
    proLabel: 'Usta yarışmacı',
    turnsProAtTier: 3,
    titlePurseShare: 2.6,
    wearFactor: 0.85,
    tiers: <CombatTier>[
      CombatTier(
        label: 'Okul içi müsabaka',
        levelRatio: 0.25,
        minAge: 12,
        opponentRating: 28,
        purseShare: 0.0,
        yearlyChances: 4,
        fameGain: 0,
        injuryRisk: 0.05,
      ),
      CombatTier(
        label: 'Açık turnuva',
        levelRatio: 0.45,
        minAge: 15,
        opponentRating: 44,
        purseShare: 0.07,
        yearlyChances: 3,
        fameGain: 1,
        injuryRisk: 0.08,
      ),
      CombatTier(
        label: 'Bölgesel yarışma',
        levelRatio: 0.62,
        minAge: 17,
        opponentRating: 58,
        purseShare: 0.22,
        yearlyChances: 3,
        fameGain: 2,
        injuryRisk: 0.10,
      ),
      CombatTier(
        label: 'Ulusal yarışma',
        levelRatio: 0.80,
        minAge: 19,
        opponentRating: 72,
        purseShare: 0.60,
        yearlyChances: 2,
        fameGain: 5,
        injuryRisk: 0.12,
      ),
    ],
  ),
];

CombatCircuit? combatCircuitFor(String artId) {
  for (final CombatCircuit c in kCombatCircuits) {
    if (c.artId == artId) return c;
  }
  return null;
}

/// Şampiyonluk müsabakasına çıkmak için gereken kademe.
const int kTitleTier = 3;
