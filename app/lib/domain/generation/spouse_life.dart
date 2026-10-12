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
import '../models/relation.dart';
import 'child_progression.dart';
import 'npc_illness.dart';

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
  /// prototypeOnly: eşin hastalığının oyuncunun mutluluğuna etkisi.
  ///
  /// Hastalığın kendi sayıları (olasılık, sağlık/keyif düşüşü, iki
  /// hastalık arası en az yıl) Paket CN'de `NpcIllness`'a taşındı:
  /// aynı kuralın iki kopyası kalmasın. Değerler değişmedi.
  static const int prototypeOnlyPlayerWorry = -4;

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
  /// **Kural Paket CN'de paylaşıldı** (`NpcIllness`): sayılar, üç
  /// yıllık ara ve izin dönüm noktasından okunması aynı kaldı,
  /// yalnızca tek kopya oldu. Eş **ana zarı** kullanmaya devam ediyor;
  /// çocuk tarafı kendi türetilmiş tohumunu kullanır, böylece eski
  /// ölçümler bit bit aynı kalır.
  static ({Person person, String? text}) _maybeIllness(
    Person spouse,
    Random rng,
  ) {
    final NpcIllnessYear sonuc = NpcIllness.maybe(spouse, rng);
    return (person: sonuc.person, text: sonuc.text);
  }
}
