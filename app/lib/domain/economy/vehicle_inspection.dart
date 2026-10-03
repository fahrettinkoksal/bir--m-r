/// Araç muayenesi (D-157).
///
/// **Neden var:** Araç satın alındıktan sonra masraf çıkarıyordu (D-079)
/// ve yıllık sigorta/vergi geliyordu (D-148), ama **muayene** hiç yoktu.
/// Türkiye'de otomobil ve motosiklet muayenesi iki yılda bir zorunludur;
/// aracı yıpranmış bırakan oyuncu bunu hiç hissetmiyordu.
///
/// **Yeni bir araç sistemi değildir.** Mevcut `VehicleTroubles` ve
/// `LivingCosts` aynen duruyor; burası yalnızca iki yılda bir gelen
/// muayeneyi ve muayenesiz araç taşımanın bedelini ekler.
///
/// Kurallar:
/// - Muayene **iki yılda bir** gelir; her araç için ayrı takip edilir.
/// - Kondisyonu eşiğin altındaki araç **geçmez**: ücret yine ödenir,
///   araç muayenesiz kalır. Geçmek için bakım gerekir (mevcut
///   `ItemActions.bakim`).
/// - Parası yetmeyen oyuncunun cüzdanı **eksiye düşmez**; muayene
///   yapılmamış sayılır.
/// - Muayenesi geciken araç için yıllık bir idari bedel çıkar. Bu bir
///   ceza anlatımı değildir: yalnızca gecikmenin bir karşılığı vardır.
///
/// Bütün sayılar `prototypeOnly`'dir (Q-160).
library;

import '../../data/item_catalog.dart';
import '../models/game_state.dart';
import '../models/life_log.dart';
import '../models/owned_item.dart';
import '../models/pending_notice.dart';
import '../../text/turkish_text.dart';
import '../life/notices.dart';

/// Bir aracın o yılki muayene sonucu.
class InspectionOutcome {
  const InspectionOutcome({
    required this.itemId,
    required this.passed,
    required this.cost,
    required this.text,
  });

  final String itemId;

  /// Muayeneden geçti mi?
  final bool passed;

  /// Gerçekten ödenen tutar (₺).
  final int cost;

  final String text;
}

abstract final class VehicleInspection {
  /// prototypeOnly: muayene aralığı (yıl).
  static const int prototypeOnlyPeriodYears = 2;

  /// prototypeOnly: muayeneden geçmek için gereken en az kondisyon.
  static const int prototypeOnlyPassCondition = 40;

  /// prototypeOnly: otomobil muayene ücreti (₺, 2026 ölçeği).
  static const int prototypeOnlyCarFee = 3200;

  /// prototypeOnly: motosiklet muayene ücreti (₺).
  static const int prototypeOnlyBikeFee = 1900;

  /// prototypeOnly: muayenesi geciken araç için yıllık idari bedel (₺).
  static const int prototypeOnlyOverdueFee = 2400;

  /// prototypeOnly: gecikme bedelinin başlaması için geçmesi gereken yıl.
  static const int prototypeOnlyOverdueAfter = 1;

  /// Bu eşya muayeneye tabi mi? Bisiklet değildir.
  static bool applies(OwnedItem item) =>
      item.type.kind == ItemKind.otomobil ||
      item.type.kind == ItemKind.motosiklet;

  /// Muayeneye tabi araçlar.
  static List<OwnedItem> vehiclesOf(GameState state) =>
      state.items.where(applies).toList(growable: false);

  /// Bu aracın muayene ücreti.
  static int feeFor(OwnedItem item) =>
      item.type.kind == ItemKind.motosiklet
          ? prototypeOnlyBikeFee
          : prototypeOnlyCarFee;

  /// Bu araç [age] yaşında muayeneye geliyor mu?
  ///
  /// Hiç muayene edilmemiş araç **edinildiği yıl** gelmez: sıfır ya da
  /// yeni alınmış aracın muayenesi vardır. İlk muayene edinmeden
  /// [prototypeOnlyPeriodYears] yıl sonra gelir.
  static bool isDue(GameState state, OwnedItem item, int age) {
    if (!applies(item)) return false;
    final int? son = state.vehicleInspectionAt[item.id];
    final int baslangic = son ?? item.acquiredAtAge;
    return age - baslangic >= prototypeOnlyPeriodYears;
  }

  /// Bu aracın muayenesi kaç yıl gecikmiş? Gecikme yoksa 0.
  static int overdueYears(GameState state, OwnedItem item, int age) {
    if (!applies(item)) return 0;
    final int? son = state.vehicleInspectionAt[item.id];
    final int baslangic = son ?? item.acquiredAtAge;
    final int gecen = age - baslangic;
    final int gecikme = gecen - prototypeOnlyPeriodYears;
    return gecikme <= 0 ? 0 : gecikme;
  }

  /// Bir yılı işletir: gelen muayeneleri yapar, gecikenlerin bedelini
  /// alır.
  ///
  /// Sonuçlar **gerçekten uygulanır**: ücret cüzdandan düşer, geçen araç
  /// kayda yazılır, bildirim açılır.
  static GameState advanceYear({
    required GameState state,
    required int newAge,
  }) {
    GameState sonuc = state;
    final List<String> satirlar = <String>[];
    final List<PendingNotice> bildirimler = <PendingNotice>[];

    for (final OwnedItem arac in vehiclesOf(state)) {
      // 1) Gecikme bedeli: muayenesi geçmiş araç taşımanın karşılığı.
      final int gecikme = overdueYears(sonuc, arac, newAge);
      if (gecikme >= prototypeOnlyOverdueAfter) {
        final int odenen = prototypeOnlyOverdueFee
            .clamp(0, sonuc.player.wallet.clamp(0, 1 << 31));
        if (odenen > 0) {
          sonuc = sonuc.copyWith(
            player: sonuc.player.copyWith(
              wallet: sonuc.player.wallet - odenen,
            ),
          );
          satirlar.add(
            '${arac.name}: muayene gecikti, ${trMoney(odenen)} idari '
            'bedel çıktı.',
          );
        }
      }

      // 2) Muayene zamanı geldiyse yapılır.
      if (!isDue(sonuc, arac, newAge)) continue;
      final InspectionOutcome? sonucu = _inspect(sonuc, arac, newAge);
      if (sonucu == null) continue;

      sonuc = sonuc.copyWith(
        player: sonuc.player.copyWith(
          wallet: sonuc.player.wallet - sonucu.cost,
        ),
        vehicleInspectionAt: sonucu.passed
            ? Map<String, int>.unmodifiable(<String, int>{
                ...sonuc.vehicleInspectionAt,
                arac.id: newAge,
              })
            : sonuc.vehicleInspectionAt,
      );
      satirlar.add(sonucu.text);
      bildirimler.add(
        Notices.vehicleInspection(
          playerAge: newAge,
          itemId: arac.id,
          vehicleName: arac.name,
          passed: sonucu.passed,
          text: sonucu.text,
        ),
      );
    }

    if (satirlar.isEmpty) return sonuc;

    return sonuc.copyWith(
      log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
        ...sonuc.log,
        for (final String s in satirlar)
          LifeLogEntry(age: newAge, text: s, category: LogCategory.kisisel),
      ]),
      notices: List<PendingNotice>.unmodifiable(<PendingNotice>[
        ...sonuc.notices,
        ...bildirimler,
      ]),
    );
  }

  /// Tek bir aracın muayenesi; parası yetmiyorsa `null`.
  static InspectionOutcome? _inspect(
    GameState state,
    OwnedItem item,
    int age,
  ) {
    final int ucret = feeFor(item);
    if (state.player.wallet < ucret) {
      // Cüzdan eksiye düşmez; muayene yapılmamış sayılır ve gelecek yıl
      // gecikme bedeli işler.
      return null;
    }
    final bool gecti = item.condition >= prototypeOnlyPassCondition;
    return InspectionOutcome(
      itemId: item.id,
      passed: gecti,
      cost: ucret,
      text: gecti
          ? '${item.name}: muayeneden geçti. ${trMoney(ucret)} ödedin.'
          : '${item.name}: muayeneden geçemedi, kusur çıktı. '
              '${trMoney(ucret)} ödedin; geçmesi için bakım gerekiyor.',
    );
  }
}
