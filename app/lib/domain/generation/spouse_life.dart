/// Eşin **kendi ilerleyen hayatı** (D-154).
///
/// **Neden var:** Çocuklar arka planda gerçekten büyüyordu (D-045) ama eş
/// donmuş bir kayıt gibi duruyordu: iş değiştirmiyor, emekli olmuyor,
/// hastalanmıyordu. Otuz yıllık evlilikte eşin hayatında hiçbir şey
/// olmuyordu.
///
/// **Paralel bir sistem kurulmadı.** Kariyer, emeklilik ve birikim
/// mevcut [ChildProgression] ile ilerler — aynı katalog, aynı kurallar.
/// Burada yalnızca eşe özgü iki şey var:
/// 1. Önemli haberler oyuncuya **bildirim** olarak gelir (eşin emekli
///    olması, işten ayrılması, işe başlaması oyuncunun hanesini
///    ilgilendirir).
/// 2. Eş bir yıl **hastalanabilir**: kendi sağlığı düşer, oyuncunun
///    mutluluğu bundan etkilenir.
///
/// Bütün sayılar `prototypeOnly`'dir (Q-157).
library;

import 'dart:math';

import '../models/game_state.dart';
import '../models/person.dart';
import '../models/person_development.dart';
import '../models/relation.dart';
import 'child_progression.dart';
import 'random_util.dart';

/// Bir yılın eşe dair sonucu.
class SpouseYear {
  const SpouseYear({
    required this.person,
    required this.news,
    required this.noticeTexts,
    this.playerHappiness = 0,
  });

  final Person person;

  /// Oyuncunun hayat günlüğüne yazılacak satırlar.
  final List<String> news;

  /// Ekranda bildirim olarak gösterilecek satırlar.
  final List<String> noticeTexts;

  /// Oyuncunun mutluluğuna uygulanacak değişim.
  final int playerHappiness;
}

abstract final class SpouseLife {
  /// prototypeOnly: eşin bir yılda hastalanma olasılığı.
  ///
  /// Yaşla artar; genç eş nadiren, yaşlı eş daha sık hastalanır.
  static double prototypeOnlyIllnessChance(int age) {
    if (age < 35) return 0.012;
    if (age < 50) return 0.022;
    if (age < 65) return 0.038;
    return 0.055;
  }

  /// prototypeOnly: hastalığın eşin sağlığından düşürdüğü puan.
  static const int prototypeOnlyIllnessHealth = -9;

  /// prototypeOnly: hastalığın eşin keyfinden düşürdüğü puan.
  static const int prototypeOnlyIllnessHappiness = -8;

  /// prototypeOnly: eşin hastalığının oyuncunun mutluluğuna etkisi.
  static const int prototypeOnlyPlayerWorry = -4;

  /// prototypeOnly: iki hastalık arasında geçmesi gereken en az yıl.
  static const int prototypeOnlyIllnessGap = 3;

  /// Oyuncunun **yürüyen** evliliğindeki eş; yoksa `null`.
  ///
  /// Boşanmış ya da vefat etmiş eş için hayat ilerletilmez: biri artık
  /// oyuncunun hanesinden değildir, diğeri hayatta değildir.
  static Person? spouseOf(GameState state) {
    final Person? es = state.spouse;
    if (es == null || !es.isAlive) return null;
    if (es.relation != RelationType.es) return null;
    return es;
  }

  /// Bu haber oyuncuya bildirimle duyurulacak kadar önemli mi?
  ///
  /// Eşin okul/ilgi alanı haberleri günlükte kalır; **hanenin gelirini**
  /// değiştiren haberler bildirime çıkar.
  static bool isHouseholdNews(String text) =>
      text.contains('emekli oldu') ||
      text.contains('işinden ayrılmak') ||
      text.contains('olarak işe başladı');

  /// Eşi **bir yıl** ilerletir.
  ///
  /// [spouse] yaşı zaten artırılmış olarak verilir.
  static SpouseYear advance({
    required Person spouse,
    required int playerAge,
    required Random rng,
  }) {
    if (!spouse.isAlive) {
      return SpouseYear(
        person: spouse,
        news: const <String>[],
        noticeTexts: const <String>[],
      );
    }

    // 1) Kariyer, emeklilik ve birikim: mevcut sistem.
    final ({Person person, List<String> news}) ilerleme =
        ChildProgression.advance(spouse, rng);
    Person kisi = ilerleme.person;
    final List<String> haberler = <String>[...ilerleme.news];
    final List<String> bildirimler = <String>[
      for (final String h in ilerleme.news)
        if (isHouseholdNews(h)) h,
    ];
    int oyuncuMutluluk = 0;

    // 2) Hastalık.
    final ({Person person, String? text}) hastalik =
        _maybeIllness(kisi, rng);
    kisi = hastalik.person;
    if (hastalik.text != null) {
      haberler.add(hastalik.text!);
      bildirimler.add(hastalik.text!);
      oyuncuMutluluk += prototypeOnlyPlayerWorry;
    }

    return SpouseYear(
      person: kisi,
      news: List<String>.unmodifiable(haberler),
      noticeTexts: List<String>.unmodifiable(bildirimler),
      playerHappiness: oyuncuMutluluk,
    );
  }

  /// Eş bu yıl hastalanır mı?
  ///
  /// İki hastalık arasında en az [prototypeOnlyIllnessGap] yıl geçer;
  /// hastalık kaydı eşin **kendi** dönüm noktalarından okunur, ayrı bir
  /// alan eklenmez.
  static ({Person person, String? text}) _maybeIllness(
    Person spouse,
    Random rng,
  ) {
    final PersonDevelopment? dev = spouse.development;
    if (dev == null) return (person: spouse, text: null);

    final int? sonHastalik = _lastIllnessAge(dev);
    if (sonHastalik != null &&
        spouse.age - sonHastalik < prototypeOnlyIllnessGap) {
      return (person: spouse, text: null);
    }
    if (!rng.chance(prototypeOnlyIllnessChance(spouse.age))) {
      return (person: spouse, text: null);
    }

    final String metin = '${spouse.firstName} bir süre hastalandı.';
    final PersonDevelopment yeni = dev
        .copyWith(
          stats: dev.stats.gain(
            health: prototypeOnlyIllnessHealth,
            happiness: prototypeOnlyIllnessHappiness,
          ),
        )
        .withMilestone(spouse.age, metin);

    return (
      person: spouse.copyWith(
        development: yeni,
        happiness:
            (spouse.happiness + prototypeOnlyIllnessHappiness).clamp(0, 100),
      ),
      text: metin,
    );
  }

  /// Eşin geçmişindeki en son hastalık yılı; hiç yoksa `null`.
  static int? _lastIllnessAge(PersonDevelopment dev) {
    int? son;
    for (final LifeMilestone m in dev.milestones) {
      if (m.text.contains('hastalandı')) son = m.age;
    }
    return son;
  }
}
