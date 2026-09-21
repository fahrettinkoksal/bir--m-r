import '../models/game_state.dart';
import '../models/life_log.dart';
import '../models/person.dart';
import '../models/relation.dart';

/// Vasiyet: **mirasçı çocuk seçimi** (D-052).
///
/// Kurallar:
/// - Seçim **isteğe bağlıdır**. Hiç seçim yapılmazsa miras bugünkü gibi
///   çocuklar arasında eşit bölünür.
/// - Seçim istendiği zaman **değiştirilebilir veya kaldırılabilir**; her
///   değişiklik hayat günlüğüne yazılır.
/// - Seçilen çocuk nakitten **daha büyük bir pay** alır ve eşya
///   paylaşımında **ilk sıradadır**; diğer çocuklar mirastan tamamen
///   dışlanmaz.
/// - Eşin payı (D-037) korunur; vasiyet onu azaltmaz.
/// - Evlat edinilen ve evlilik dışı doğan çocuk da seçilebilir.
/// - Seçilen çocuk vefat ederse seçim **kendiliğinden düşer**; vefat etmiş
///   kişi mirasçı olarak gösterilmez.
/// - Vasiyet, "Çocuğum olarak devam et" seçimini zorunlu kılmaz.
///
/// Oran ve koşullar `prototypeOnly`'dir (Q-076).
abstract final class Will {
  /// prototypeOnly: mirasçı çocuğun, çocuklara kalan nakitten aldığı pay.
  static const double prototypeOnlyHeirShare = 0.6;

  /// Vasiyet yazmaya engel; engel yoksa boş metin.
  static String blockReason(GameState state) {
    if (state.livingChildren.isEmpty) {
      return 'Vasiyet için hayatta bir çocuğun olmalı.';
    }
    return '';
  }

  /// **Gerçekten geçerli** mirasçı kimliği.
  ///
  /// Seçilen çocuk vefat ettiyse ya da kayıttan düştüyse `null` döner:
  /// ölmüş kişi mirasçı olarak gösterilmez.
  static String? effectiveHeirId(GameState state) {
    final String? secim = state.heirChildId;
    if (secim == null) return null;
    final Person? cocuk = state.personById(secim);
    if (cocuk == null || !cocuk.isAlive) return null;
    if (cocuk.relation != RelationType.cocuk) return null;
    return cocuk.id;
  }

  /// Geçerli mirasçı kişi kaydı; yoksa `null`.
  static Person? effectiveHeir(GameState state) {
    final String? id = effectiveHeirId(state);
    return id == null ? null : state.personById(id);
  }

  /// Mirasçı olarak bir çocuk seçer.
  static ({GameState state, String text, bool applied}) choose(
    GameState state,
    String childId,
  ) {
    final Person? cocuk = state.personById(childId);
    if (cocuk == null) {
      return (state: state, text: 'Bu kayıt bulunamadı.', applied: false);
    }
    if (cocuk.relation != RelationType.cocuk) {
      return (
        state: state,
        text: '${cocuk.firstName} senin çocuğun değil.',
        applied: false,
      );
    }
    if (!cocuk.isAlive) {
      return (
        state: state,
        text: '${cocuk.firstName} hayatta değil.',
        applied: false,
      );
    }
    if (state.heirChildId == childId) {
      return (
        state: state,
        text: '${cocuk.firstName} zaten mirasçın.',
        applied: false,
      );
    }

    final String metin = 'Vasiyetinde mirasçı olarak ${cocuk.fullName} '
        'yazıldı.';
    return (
      state: _log(state.copyWith(heirChildId: childId), metin),
      text: metin,
      applied: true,
    );
  }

  /// Mirasçı seçimini kaldırır: miras olağan kurala döner.
  static ({GameState state, String text, bool applied}) clear(GameState state) {
    if (state.heirChildId == null) {
      return (
        state: state,
        text: 'Vasiyetinde mirasçı seçimi yok.',
        applied: false,
      );
    }
    const String metin = 'Vasiyetindeki mirasçı seçimini kaldırdın; miras '
        'çocukların arasında eşit bölünecek.';
    return (
      state: _log(state.copyWith(heirChildId: null), metin),
      text: metin,
      applied: true,
    );
  }

  /// Bir çocuğun, çocuklara kalan nakitten alacağı pay.
  ///
  /// Mirasçı seçimi yoksa eşit bölünür. Seçim varsa mirasçı daha büyük
  /// payı alır, kalan diğer çocuklar arasında eşit bölünür: kimse
  /// tamamen dışlanmaz.
  static int cashShareFor(GameState state, Person child, int pool) {
    final List<Person> cocuklar = state.livingChildren;
    if (cocuklar.length <= 1 || pool <= 0) return pool;

    final String? mirasci = effectiveHeirId(state);
    if (mirasci == null) return (pool / cocuklar.length).floor();

    final int mirasciPayi = (pool * prototypeOnlyHeirShare).round();
    if (child.id == mirasci) return mirasciPayi;
    return ((pool - mirasciPayi) / (cocuklar.length - 1)).floor();
  }

  static GameState _log(GameState state, String text) => state.copyWith(
        log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
          ...state.log,
          LifeLogEntry(
            age: state.player.age,
            text: text,
            category: LogCategory.aile,
          ),
        ]),
      );
}
