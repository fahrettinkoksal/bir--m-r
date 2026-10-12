import 'package:flutter/foundation.dart';

import '../features/feature_catalog.dart';
import '../models/applied_effect.dart';
import '../models/game_state.dart';
import '../models/person.dart';
import '../models/person_development.dart';
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
    this.childMarks = const <String, ChildMark>{},
  });

  /// Fotoğrafın alındığı yaş (yılın başı).
  final int age;

  final Stats stats;
  final int wallet;
  final int? fame;

  /// Çocukların yılın başındaki fotoğrafı (Paket BK/5).
  ///
  /// Anahtar çocuğun kimliği. Yıl içinde doğan bebek bu haritada
  /// **yoktur** ve özetinde "her şey yeni" diye görünmez: doğumun
  /// kendisi zaten bildirimle ve günlükle duyuruluyor.
  final Map<String, ChildMark> childMarks;

  /// Oyuncunun ve çocuklarının o anki hâlinden fotoğraf alır.
  static YearMark of(GameState state) => YearMark(
        age: state.player.age,
        stats: state.player.stats,
        wallet: state.player.wallet,
        fame: state.player.fame,
        childMarks: <String, ChildMark>{
          for (final Person c in state.children)
            if (c.isAlive && c.development != null) c.id: ChildMark.of(c),
        },
      );
}

/// Bir çocuğun yılın başındaki fotoğrafı (Paket BK/5).
///
/// Oyuncunun fotoğrafıyla aynı mantık: yıl sonunda "ne değişti"
/// sorusu **uydurmadan** yanıtlanabilsin. Ebeveynliğin bir işe
/// yarayıp yaramadığı ancak önce/sonra farkıyla söylenebilir.
@immutable
class ChildMark {
  const ChildMark({
    required this.stats,
    required this.money,
    required this.interests,
    required this.bond,
    required this.happiness,
    required this.milestones,
  });

  final Stats stats;
  final int money;

  /// Edinilmiş ilgi alanları (yeni uğraşı adıyla yazabilmek için).
  final List<String> interests;

  /// Oyuncuyla yakınlık.
  final int bond;

  /// Çocuğun kendi keyfi (D-074).
  final int happiness;

  /// Dönüm noktası sayısı: yıl içinde eklenenler kuyruktan okunur.
  final int milestones;

  static ChildMark of(Person child) {
    final PersonDevelopment dev = child.development!;
    return ChildMark(
      stats: dev.stats,
      money: dev.money,
      interests: List<String>.unmodifiable(dev.interests),
      bond: child.bond,
      happiness: child.happiness,
      milestones: dev.milestones.length,
    );
  }
}

/// Bir çocuğun biten yıl özeti (Paket BK/5).
@immutable
class ChildYearSummary {
  const ChildYearSummary({
    required this.childId,
    required this.name,
    required this.age,
    required this.effects,
    required this.milestones,
  });

  final String childId;

  /// Çocuğun adı: özet kaydedildiği için ekran kişiyi aramak zorunda
  /// kalmasın.
  final String name;

  /// Çocuğun yılın sonundaki yaşı.
  final int age;

  /// Yıl boyunca **gerçekten** değişenler.
  final List<AppliedEffect> effects;

  /// Yıl içinde eklenen dönüm noktalarının metni.
  final List<String> milestones;

  bool get isEmpty => effects.isEmpty && milestones.isEmpty;
}

/// Biten yılın özeti (D-096).
///
/// Oyuncu ne olduğunu anlamak için hayat günlüğünü taramak zorunda
/// kalmasın diye, yıl bittiğinde **gerçekten değişmiş** değerler tek bir
/// kartta toplanır.
@immutable
class YearSummary {
  const YearSummary({
    required this.age,
    required this.effects,
    this.children = const <ChildYearSummary>[],
  });

  /// Özetlenen yaş (biten yıl).
  final int age;

  /// Yıl boyunca **gerçekten uygulanmış** değişimler.
  final List<AppliedEffect> effects;

  /// Çocukların aynı yıldaki özetleri (Paket BK/5).
  ///
  /// Boş olabilir: çocuğu olmayan ya da o yıl çocuğunda bir şey
  /// değişmeyen oyuncuda satır çıkmaz.
  final List<ChildYearSummary> children;

  bool get isEmpty => effects.isEmpty && children.isEmpty;
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

    // Çocukların aynı yıl özeti (Paket BK/5).
    final List<ChildYearSummary> cocuklar = _summarizeChildren(mark, state);

    // Oyuncuda da çocukta da bir şey değişmediyse özet üretilmez.
    if (etkiler.isEmpty && cocuklar.isEmpty) return null;
    return YearSummary(
      age: mark.age,
      effects: List<AppliedEffect>.unmodifiable(etkiler),
      children: List<ChildYearSummary>.unmodifiable(cocuklar),
    );
  }

  /// Çocukların biten yıl özetleri (Paket BK/5).
  ///
  /// **Ebeveynliğin karşılığı burada görünür.** Oyuncunun yaptığı şey
  /// (ödev, harçlık, kurs, kural) çocuğun kaydını değiştiriyorsa fark
  /// buraya düşer. Niyet yazılmaz, yalnızca ölçülen fark.
  ///
  /// Yıl içinde doğan bebek fotoğrafta yoktur: onun özeti çıkmaz,
  /// çünkü "ne değişti" diye karşılaştırılacak bir öncesi yok.
  static List<ChildYearSummary> _summarizeChildren(
    YearMark mark,
    GameState state,
  ) {
    // Modül anahtarı (Paket BL): kapalıyken yıl özetinde çocuk bloğu
    // hiç kurulmaz. Çocuğun kendi kartı etkilenmez.
    if (!state.featureOn(FeatureId.cocukYilOzeti)) {
      return const <ChildYearSummary>[];
    }
    final List<ChildYearSummary> ozetler = <ChildYearSummary>[];
    for (final Person cocuk in state.children) {
      if (!cocuk.isAlive) continue;
      final PersonDevelopment? dev = cocuk.development;
      final ChildMark? once = mark.childMarks[cocuk.id];
      if (dev == null || once == null) continue;

      final List<AppliedEffect> etkiler = <AppliedEffect>[];
      final List<StatEntry> oncekiler = once.stats.entries;
      final List<StatEntry> sonrakiler = dev.stats.entries;
      for (int i = 0; i < sonrakiler.length; i++) {
        final int fark = sonrakiler[i].value - oncekiler[i].value;
        if (fark != 0) {
          etkiler.add(AppliedEffect(label: sonrakiler[i].label, delta: fark));
        }
      }
      final int bagFarki = cocuk.bond - once.bond;
      if (bagFarki != 0) {
        etkiler.add(AppliedEffect(label: 'Yakınlık', delta: bagFarki));
      }
      final int paraFarki = dev.money - once.money;
      if (paraFarki.abs() >= prototypeOnlyWalletFloor) {
        etkiler.add(
          AppliedEffect(label: 'Birikimi', delta: paraFarki, unit: ' ₺'),
        );
      }
      for (final String ilgi in dev.interests) {
        if (!once.interests.contains(ilgi)) {
          etkiler.add(AppliedEffect(label: 'Yeni uğraş: $ilgi'));
        }
      }

      // Yıl içinde eklenen dönüm noktaları: kuyruktan okunur, yaştan
      // tahmin edilmez.
      final List<String> yeniAnlar = dev.milestones.length > once.milestones
          ? dev.milestones
              .sublist(once.milestones)
              .map((LifeMilestone m) => m.text)
              .toList(growable: false)
          : const <String>[];

      if (etkiler.isEmpty && yeniAnlar.isEmpty) continue;
      ozetler.add(
        ChildYearSummary(
          childId: cocuk.id,
          name: cocuk.firstName,
          age: cocuk.age,
          effects: List<AppliedEffect>.unmodifiable(etkiler),
          milestones: List<String>.unmodifiable(yeniAnlar),
        ),
      );
    }
    return ozetler;
  }
}
