/// Hayat hedefleri (D-156).
///
/// **Neden var:** Hayat sonu değerlendirmesi (Q-090) hayatın **sonunda**
/// tek seferlik bir özet veriyordu. Oyun içinde oyuncuyu yönlendiren
/// hiçbir hedef yoktu; ikinci hayatın birincisinden farklı olmasını
/// sağlayan bir sebep de yoktu.
///
/// **Hedefler hayat başında seçilmez, yol boyunca açılır.** Bu prototipin
/// tercihidir, kesin karar değildir (Q-159): başta seçilen hedef oyuncuyu
/// tek bir yola kilitler ve "yanlış hedef seçtim" hissi doğurur.
///
/// **Hiçbir hedef ödül vermez.** Ne para, ne puan. Ulaşılan hedef
/// **kaydedilir** ve ekranda durur; hayat sonunda da anılır. Ödül
/// verilmesi ayrı bir tasarım kararıdır (Q-159).
///
/// **Hedef uydurulmaz:** her koşul oyunun gerçek kaydına bakar.
library;

import 'package:flutter/material.dart';

import '../domain/career/craft_mastery.dart';
import '../domain/models/book_progress.dart';
import '../domain/models/game_state.dart';
import '../domain/models/hobby_progress.dart';
import '../domain/models/martial_progress.dart';
import '../domain/models/owned_item.dart';
import '../domain/models/relation.dart';
import '../domain/models/combat_career.dart';
import '../domain/models/person.dart';
import 'hobby_catalog.dart';
import 'martial_arts_catalog.dart';

/// Hedefin hangi alana ait olduğu.
enum GoalArea {
  egitim('Eğitim', Icons.school_rounded),
  kariyer('Kariyer', Icons.badge_rounded),
  ekonomi('Ekonomi', Icons.savings_rounded),
  aile('Aile', Icons.family_restroom_rounded),
  kendin('Kendin', Icons.self_improvement_rounded);

  const GoalArea(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// Bir hayat hedefi.
@immutable
class LifeGoal {
  const LifeGoal({
    required this.id,
    required this.label,
    required this.description,
    required this.area,
    required this.reached,
  });

  final String id;
  final String label;

  /// Ne istendiği. Tek cümle, açık.
  final String description;

  final GoalArea area;

  /// Bu hedefe **şu an** ulaşılmış mı? Yalnızca gerçek kayda bakar.
  final bool Function(GameState state) reached;
}

/// prototypeOnly: "ilk milyon" hedefinin eşiği (₺).
const int kGoalMillion = 1000000;

/// prototypeOnly: takipçi hedefinin eşiği.
const int kGoalFollowers = 100000;

/// prototypeOnly: Ün hedefinin eşiği.
const int kGoalFame = 60;

/// Oyundaki hedefler.
///
/// Sıra ekranda korunur: alan alan, kolaydan zora.
final List<LifeGoal> kLifeGoals = <LifeGoal>[
  // --- Eğitim ----------------------------------------------------------
  LifeGoal(
    id: 'lise_bitir',
    label: 'Liseyi bitir',
    description: 'Lise diplomasını al.',
    area: GoalArea.egitim,
    reached: (GameState s) => s.education.finished,
  ),
  LifeGoal(
    id: 'universite_bitir',
    label: 'Üniversiteyi bitir',
    description: 'Bir bölümü kazan ve mezun ol.',
    area: GoalArea.egitim,
    reached: (GameState s) => s.education.universityFinished,
  ),

  // --- Kariyer ---------------------------------------------------------
  LifeGoal(
    id: 'ilk_is',
    label: 'İlk işine gir',
    description: 'Bir işe girip maaş almaya başla.',
    area: GoalArea.kariyer,
    reached: (GameState s) =>
        s.career.isEmployed || s.career.history.isNotEmpty,
  ),
  LifeGoal(
    id: 'usta_ol',
    label: 'Mesleğinde usta ol',
    description: 'Aynı işte ${MasteryStage.usta.yearsNeeded} yılı doldur.',
    area: GoalArea.kariyer,
    reached: (GameState s) {
      final MasteryStage? b = CraftMastery.stageOf(s);
      return b != null && b.index >= MasteryStage.usta.index;
    },
  ),
  LifeGoal(
    id: 'duayen_ol',
    label: 'Mesleğinde duayen ol',
    description: 'Aynı işte ${MasteryStage.duayen.yearsNeeded} yılı doldur.',
    area: GoalArea.kariyer,
    reached: (GameState s) {
      final MasteryStage? b = CraftMastery.stageOf(s);
      return b != null && b.index >= MasteryStage.duayen.index;
    },
  ),
  LifeGoal(
    id: 'emekli_ol',
    label: 'Emekli ol',
    description: 'Çalışma hayatını emeklilikle kapat.',
    area: GoalArea.kariyer,
    reached: (GameState s) => s.career.isRetired,
  ),

  // --- Ekonomi ---------------------------------------------------------
  LifeGoal(
    id: 'ilk_milyon',
    label: 'İlk milyonunu gör',
    description: 'Cüzdanında bir milyon lira birikmiş olsun.',
    area: GoalArea.ekonomi,
    reached: (GameState s) => s.player.wallet >= kGoalMillion,
  ),
  LifeGoal(
    id: 'ev_sahibi',
    label: 'Kendi evini al',
    description: 'Bir konut satın al.',
    area: GoalArea.ekonomi,
    reached: (GameState s) => s.items.any((OwnedItem i) => i.isProperty),
  ),
  LifeGoal(
    id: 'arac_sahibi',
    label: 'Kendi aracını al',
    description: 'Bir araç satın al.',
    area: GoalArea.ekonomi,
    reached: (GameState s) => s.items.any((OwnedItem i) => i.isVehicle),
  ),
  LifeGoal(
    id: 'kendi_isi',
    label: 'Kendi işini kur',
    description: 'Bir iş aç ve sahibi ol.',
    area: GoalArea.ekonomi,
    reached: (GameState s) => s.businesses.isNotEmpty,
  ),

  // --- Aile ------------------------------------------------------------
  LifeGoal(
    id: 'evlen',
    label: 'Evlen',
    description: 'Bir evlilik kaydın olsun.',
    area: GoalArea.aile,
    reached: (GameState s) => s.marriage != null || s.pastMarriages.isNotEmpty,
  ),
  LifeGoal(
    id: 'cocuk_sahibi',
    label: 'Çocuk sahibi ol',
    description: 'Bir çocuğun olsun.',
    area: GoalArea.aile,
    reached: (GameState s) => s.children.isNotEmpty,
  ),
  LifeGoal(
    id: 'torun_gor',
    label: 'Torununu gör',
    description: 'Bir torunun dünyaya gelsin.',
    area: GoalArea.aile,
    reached: (GameState s) =>
        s.people.any((Person p) => p.relation == RelationType.torun),
  ),

  // --- Kendin ----------------------------------------------------------
  LifeGoal(
    id: 'hobi_usta',
    label: 'Bir hobide ustalaş',
    description: 'Bir hobinin en üst basamağına çık.',
    area: GoalArea.kendin,
    reached: (GameState s) => s.hobbies.any((HobbyProgress h) {
      final HobbyKind? tur = hobbyById(h.hobbyId);
      if (tur == null) return false;
      return tur.stageFor(h.experience) >= tur.topStage;
    }),
  ),
  LifeGoal(
    id: 'dovus_ust_basamak',
    label: 'Bir dövüş dalında en üste çık',
    description: 'Bir dalın en üst basamağına ulaş.',
    area: GoalArea.kendin,
    reached: (GameState s) => s.martialArts.any((MartialProgress m) {
      final MartialArt? dal = martialArtById(m.artId);
      if (dal == null) return false;
      return dal.levelForLessons(m.lessons) >= dal.ranks.length - 1;
    }),
  ),
  // D-143: futbolun rekabet başarısının hedefi.
  //
  // Profesyonel futbola ulaşmak oyundaki en dar yollardan biri
  // (ölçümde okul odaklı hayatların %1,4'ü) ama hiçbir hedefe
  // dokunmuyordu. Eşik **tek sezon**: futbolda girmek zaten en üsttür.
  // Faho onayladı (5 Ekim 2026).
  LifeGoal(
    id: 'profesyonel_futbol',
    label: 'Profesyonel futbol oyna',
    description: 'Okul takımından başlayıp profesyonel bir sezon oyna.',
    area: GoalArea.kendin,
    reached: (GameState s) => (s.footballCareer?.proSeasons ?? 0) > 0,
  ),
  // D-143: dövüşün rekabet başarısının hedefi.
  //
  // Katalogda `dovus_ust_basamak` vardı ama o **eğitim basamağıyla**
  // ilgili ("bir dalın en üst basamağına ulaş"); unvan kazanmanın
  // karşılığı yoktu. Faho onayladı (5 Ekim 2026).
  LifeGoal(
    id: 'dovus_sampiyonluk',
    label: 'Bir dövüş dalında şampiyon ol',
    description: 'Rekabete gir ve bir unvan kazan.',
    area: GoalArea.kendin,
    reached: (GameState s) =>
        s.combatCareers.any((CombatCareer k) => k.championships > 0),
  ),
  LifeGoal(
    id: 'kitap_bitir',
    label: 'Bir kitabı bitir',
    description: 'Kütüphaneden aldığın bir kitabı sonuna kadar oku.',
    area: GoalArea.kendin,
    reached: (GameState s) => s.books.any((BookProgress b) => b.finished),
  ),
  LifeGoal(
    id: 'yurt_disi',
    label: 'Bir geziye çık',
    description: 'Bir yolculuk yap.',
    area: GoalArea.kendin,
    reached: (GameState s) => s.trips.isNotEmpty,
  ),
  LifeGoal(
    id: 'takipci',
    label: 'Kitlen olsun',
    description:
        'Sosyal medyada toplam $kGoalFollowers takipçiye ulaş.',
    area: GoalArea.kendin,
    reached: (GameState s) => s.totalFollowers >= kGoalFollowers,
  ),
  LifeGoal(
    id: 'un',
    label: 'Tanınan biri ol',
    description: 'Ün değerin $kGoalFame olsun.',
    area: GoalArea.kendin,
    reached: (GameState s) => (s.player.fame ?? 0) >= kGoalFame,
  ),
];

LifeGoal? lifeGoalById(String id) {
  for (final LifeGoal g in kLifeGoals) {
    if (g.id == id) return g;
  }
  return null;
}

/// Bir alandaki hedefler.
List<LifeGoal> lifeGoalsIn(GoalArea area) =>
    kLifeGoals.where((LifeGoal g) => g.area == area).toList(growable: false);
