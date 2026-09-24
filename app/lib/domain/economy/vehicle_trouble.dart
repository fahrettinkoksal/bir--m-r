/// Araç masrafı ve yolda kalma (D-079).
///
/// **Neden var:** Faho istedi — "ucuz araçlar sorun çıkartsın, onunla
/// uğraşmam gereksin, 'araban masraf çıkarttı' gibi bildirimler olsun".
/// Araç satın alındıktan sonra hiçbir şey yapmıyordu: ne yıpranıyordu ne
/// masraf çıkarıyordu.
///
/// **Kural eşyanın kendisine bakar, satın alındığı yere değil.** Ucuz
/// galeriden alınan araç zaten ucuz ve düşük kondisyonlu olduğu için
/// daha sık arızalanır; ama miras kalan yaşlı bir otomobil de arızalanır.
/// Böylece "hangi mağazadan alındı" diye ayrı bir kayıt tutmak gerekmez
/// ve kural her araca aynı biçimde uygulanır.
///
/// Masraf **gerçekten uygulanır**: cüzdandan düşer. Parası yetmeyen
/// oyuncunun cüzdanı eksiye düşmez; araç tamir edilmeden kalır ve
/// kondisyonu daha da düşer.
///
/// Bütün sayılar `prototypeOnly` (Q-120).
library;

import 'dart:math';

import '../../data/item_catalog.dart';
import '../generation/random_util.dart';
import '../models/owned_item.dart';

/// Bir aracın o yılki başına gelen.
class VehicleTrouble {
  const VehicleTrouble({
    required this.itemId,
    required this.cost,
    required this.paid,
    required this.conditionDelta,
    required this.text,
  });

  final String itemId;

  /// Tamirin tutarı (₺).
  final int cost;

  /// Ödenebildi mi?
  final bool paid;

  /// Kondisyona uygulanacak değişim.
  final int conditionDelta;

  final String text;
}

abstract final class VehicleTroubles {
  /// prototypeOnly: kondisyonu bu değerin altındaki araç arızalanabilir.
  static const int prototypeOnlyWatchCondition = 70;

  /// prototypeOnly: tamir tutarının araç değerine oranı.
  static const double prototypeOnlyRepairShare = 0.05;

  /// prototypeOnly: tamir edilemeyen araçta ek kondisyon kaybı.
  static const int prototypeOnlyUnrepairedLoss = 8;

  /// prototypeOnly: tamir edilen araçta kazanılan kondisyon.
  static const int prototypeOnlyRepairGain = 12;

  /// prototypeOnly: arıza ihtimalinin üst sınırı.
  static const double prototypeOnlyMaxChance = 0.55;

  /// Bu eşya motorlu bir araç mı? Bisiklet sayılmaz.
  static bool applies(OwnedItem item) =>
      item.type.kind == ItemKind.otomobil ||
      item.type.kind == ItemKind.motosiklet;

  /// Bu aracın bu yıl arızalanma ihtimali.
  ///
  /// İki şey belirler: **kondisyon** (yıpranmış araç daha sık bozulur) ve
  /// **değer kademesi** (ucuz araç daha sık bozulur). Bakımlı ve pahalı
  /// bir araç neredeyse hiç arızalanmaz; ikisi de düşükse sık arızalanır.
  static double chance(OwnedItem item) {
    if (!applies(item)) return 0;
    if (item.condition >= prototypeOnlyWatchCondition) return 0.03;

    // Kondisyon düştükçe artan taban.
    final double kondisyonPayi =
        (prototypeOnlyWatchCondition - item.condition) / 100 * 0.6;

    // Ucuz araç kademesi: 1.000.000 ₺ altındaki araçlarda ek pay.
    final int deger = item.type.baseValue;
    final double ucuzlukPayi = deger >= 2000000
        ? 0.0
        : deger >= 1000000
            ? 0.04
            : deger >= 500000
                ? 0.09
                : 0.15;

    return (kondisyonPayi + ucuzlukPayi).clamp(0.0, prototypeOnlyMaxChance);
  }

  /// Tamirin tutarı.
  static int repairCost(OwnedItem item) =>
      (item.type.baseValue * prototypeOnlyRepairShare).round();

  /// Bir yılı işletir; arıza yoksa `null`.
  static VehicleTrouble? roll({
    required OwnedItem item,
    required int wallet,
    required Random rng,
  }) {
    if (!rng.chance(chance(item))) return null;

    final int tutar = repairCost(item);
    final bool odenebilir = wallet >= tutar;
    final String ariza = _arizaAdi(item, rng);

    if (odenebilir) {
      return VehicleTrouble(
        itemId: item.id,
        cost: tutar,
        paid: true,
        conditionDelta: prototypeOnlyRepairGain,
        text: '${item.type.name}: $ariza. Tamir masrafı çıktı.',
      );
    }

    return VehicleTrouble(
      itemId: item.id,
      cost: tutar,
      paid: false,
      conditionDelta: -prototypeOnlyUnrepairedLoss,
      text: '${item.type.name}: $ariza. Tamire paran yetmedi; '
          'şimdilik öyle duruyor.',
    );
  }

  static String _arizaAdi(OwnedItem item, Random rng) {
    final List<String> liste = item.type.kind == ItemKind.motosiklet
        ? _motosiklet
        : _otomobil;
    return liste[rng.nextInt(liste.length)];
  }

  static const List<String> _otomobil = <String>[
    'yolda kaldı, çekiciyle gitti',
    'akü bitti, sabah çalışmadı',
    'debriyaj sıkıntı çıkardı',
    'fren balatası bitmiş',
    'rot ve balans bozulmuş',
    'radyatörden su kaçırdı',
    'egzozdan ses gelmeye başladı',
  ];

  static const List<String> _motosiklet = <String>[
    'zincir gevşedi',
    'lastik patladı',
    'marş basmadı',
    'yağ kaçırmaya başladı',
    'fren teli koptu',
  ];
}
