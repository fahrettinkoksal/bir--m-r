import '../../data/hobby_catalog.dart';
import '../models/game_state.dart';
import '../models/hobby_progress.dart';

/// Hobi geçmişini yazan katman (Paket 39 — Issue #67).
///
/// **Yeni bir aktivite sistemi değildir.** Oyuncu yine mevcut eylemleri
/// yapar; burası yalnızca o eylemlerin kalıcı izini tutar. Hiçbir eylemin
/// ücreti, yaş sınırı ya da yıllık kotası burada değişmez — dolayısıyla
/// bu katman **sınırsız stat ya da para kasılmasına yol açamaz**: deneyim
/// ancak zaten izin verilen bir eylem yapıldığında artar.
///
/// Sayısal değerler `prototypeOnly`'dir
/// (`docs/DESIGN_REVIEW_QUEUE.md`, Q-106).
abstract final class HobbyTracker {
  /// Bu hobideki ilerleme; hiç başlanmadıysa `null`.
  static HobbyProgress? progressOf(GameState state, HobbyKind hobby) {
    for (final HobbyProgress p in state.hobbies) {
      if (p.hobbyId == hobby.id) return p;
    }
    return null;
  }

  /// Oyuncunun bu hobiyle uğraşmışlığı var mı?
  static bool has(GameState state, HobbyKind hobby) =>
      progressOf(state, hobby) != null;

  /// Şu an (oyuncunun yaşında) sürüyor sayılan hobiler.
  static List<HobbyProgress> activeHobbies(GameState state) => state.hobbies
      .where((HobbyProgress p) => p.isActiveAt(state.player.age))
      .toList(growable: false);

  /// En uzun sürdürülen hobi; hiç yoksa `null`.
  static HobbyProgress? mainHobby(GameState state) {
    HobbyProgress? enIyi;
    for (final HobbyProgress p in state.hobbies) {
      if (enIyi == null ||
          p.experience > enIyi.experience ||
          (p.experience == enIyi.experience && p.years > enIyi.years)) {
        enIyi = p;
      }
    }
    return enIyi;
  }

  /// Bir aktivite yapıldığında hobi geçmişini işler.
  ///
  /// Aktivite hiçbir hobiyi beslemiyorsa durum **aynen** döner.
  static GameState creditActivity(GameState state, String activityId) {
    final HobbyKind? hobi = hobbyForActivity(activityId);
    if (hobi == null) return state;
    return credit(state, hobi);
  }

  /// Bir hobiye bir birim deneyim yazar.
  ///
  /// Basamak yükselirse hobi geçmişine bir anı düşer. Anı yalnızca
  /// gerçekten çıkılan basamak için ve gerçek yaşla yazılır.
  static GameState credit(GameState state, HobbyKind hobby) {
    final int yas = state.player.age;
    final HobbyProgress? onceki = progressOf(state, hobby);

    final HobbyProgress yeni;
    final int oncekiBasamak;
    if (onceki == null) {
      oncekiBasamak = -1;
      yeni = HobbyProgress(
        hobbyId: hobby.id,
        startedAtAge: yas,
        experience: 1,
        lastPracticedAge: yas,
      );
    } else {
      oncekiBasamak = onceki.stage;
      yeni = onceki.copyWith(
        experience: onceki.experience + 1,
        lastPracticedAge: yas,
      );
    }

    final HobbyProgress kayit = yeni.stage > oncekiBasamak
        ? yeni.copyWith(
            memories: List<HobbyMemory>.unmodifiable(<HobbyMemory>[
              ...yeni.memories,
              HobbyMemory(
                age: yas,
                text: hobby.stages[yeni.stage].memory
                    .replaceAll('{yas}', '$yas'),
              ),
            ]),
          )
        : yeni;

    return state.copyWith(
      hobbies: List<HobbyProgress>.unmodifiable(<HobbyProgress>[
        for (final HobbyProgress p in state.hobbies)
          if (p.hobbyId != hobby.id) p,
        kayit,
      ]),
    );
  }
}
