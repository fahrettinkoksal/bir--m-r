import 'package:flutter/foundation.dart';

import '../models/applied_effect.dart';
import '../models/game_state.dart';
import '../models/stats.dart';

/// Bir yılın başında alınan fotoğraf (D-096).
///
/// Yıl sonunda "ne değişti" sorusunu **uydurmadan** yanıtlayabilmek için
/// yılın başındaki değerler saklanır. Özet, niyetten değil bu fotoğrafla
/// bugünün farkından üretilir.
@immutable
class YearMark {
  const YearMark({
    required this.age,
    required this.stats,
    required this.wallet,
    this.fame,
  });

  /// Fotoğrafın alındığı yaş (yılın başı).
  final int age;

  final Stats stats;
  final int wallet;
  final int? fame;

  /// Oyuncunun o anki hâlinden fotoğraf alır.
  static YearMark of(GameState state) => YearMark(
        age: state.player.age,
        stats: state.player.stats,
        wallet: state.player.wallet,
        fame: state.player.fame,
      );
}

/// Biten yılın özeti (D-096).
///
/// Oyuncu ne olduğunu anlamak için hayat günlüğünü taramak zorunda
/// kalmasın diye, yıl bittiğinde **gerçekten değişmiş** değerler tek bir
/// kartta toplanır.
@immutable
class YearSummary {
  const YearSummary({required this.age, required this.effects});

  /// Özetlenen yaş (biten yıl).
  final int age;

  /// Yıl boyunca **gerçekten uygulanmış** değişimler.
  final List<AppliedEffect> effects;

  bool get isEmpty => effects.isEmpty;
}

/// Yıl özetini üreten kurallar (D-096).
abstract final class YearReview {
  /// prototypeOnly: cüzdan değişimi bu tutarın altındaysa özete girmez.
  ///
  /// Her yıl birkaç liralık oynama olur; özet gürültüye boğulmasın.
  static const int prototypeOnlyWalletFloor = 1;

  /// Yılın başındaki fotoğraf ile bugünkü durumu karşılaştırır.
  ///
  /// Yalnızca **oyuncunun kendi** değerleri özetlenir: beş temel değer,
  /// cüzdan ve (açıldıysa) Ün. Kişilerle yakınlık ve eşyalar kendi
  /// bildirimlerinde zaten görünür; özet onlarla doldurulmaz.
  static YearSummary? summarize(YearMark? mark, GameState state) {
    if (mark == null) return null;
    // Fotoğraf başka bir yıla aitse özet üretilmez; uydurma yıl olmaz.
    if (mark.age != state.player.age) return null;

    final List<AppliedEffect> etkiler = <AppliedEffect>[];

    final List<StatEntry> once = mark.stats.entries;
    final List<StatEntry> simdi = state.player.stats.entries;
    for (int i = 0; i < simdi.length; i++) {
      final int fark = simdi[i].value - once[i].value;
      if (fark != 0) {
        etkiler.add(AppliedEffect(label: simdi[i].label, delta: fark));
      }
    }

    final int paraFarki = state.player.wallet - mark.wallet;
    if (paraFarki.abs() >= prototypeOnlyWalletFloor) {
      etkiler.add(
        AppliedEffect(label: 'Cüzdan', delta: paraFarki, unit: ' ₺'),
      );
    }

    // Ün yalnızca açıldıktan sonra görünür (D-027).
    final int? simdikiUn = state.player.fame;
    if (simdikiUn != null && simdikiUn != (mark.fame ?? 0)) {
      etkiler.add(
        AppliedEffect(label: 'Ün', delta: simdikiUn - (mark.fame ?? 0)),
      );
    }

    if (etkiler.isEmpty) return null;
    return YearSummary(
      age: mark.age,
      effects: List<AppliedEffect>.unmodifiable(etkiler),
    );
  }
}
