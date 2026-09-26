/// Bakım geçmişinin tek kayıt noktası (D-072).
///
/// **Neden ayrı bir dosya:** Aktivite tekrar sayaçları her yaş
/// sıfırlanır, bu yüzden "kaç yıldır spor yapmıyor" sorusunu
/// cevaplayamazlar. Bakım geçmişi ayrıca ve **yalnızca buradan** yazılır;
/// böylece hangi eylemin hangi bakıma saydığı tek yerde durur ve iki ayrı
/// akış aynı soruya iki farklı cevap veremez.
library;

import '../../data/activity_catalog.dart';
import '../life/aging.dart';
import '../models/game_state.dart';

abstract final class UpkeepTracker {
  /// Spor sayılan mekânlar.
  static const Set<ActivityVenue> sportVenues = <ActivityVenue>{
    ActivityVenue.sporSalonu,
  };

  /// Bakım sayılan mekânlar.
  static const Set<ActivityVenue> groomingVenues = <ActivityVenue>{
    ActivityVenue.berber,
  };

  /// Zihin çalıştırmak sayılan mekânlar.
  static const Set<ActivityVenue> learningVenues = <ActivityVenue>{
    ActivityVenue.kurs,
  };

  /// Bu eylem hangi bakıma sayılıyorsa onu bugüne yazar.
  ///
  /// Hiçbirine saymıyorsa durum **değişmez**; boş `copyWith` üretilmez.
  static GameState credit(GameState state, ActivityAction action) {
    if (sportVenues.contains(action.venue)) return recordSport(state);
    if (groomingVenues.contains(action.venue)) return recordGrooming(state);
    if (learningVenues.contains(action.venue)) return recordLearning(state);
    return state;
  }

  static GameState recordSport(GameState state) =>
      state.copyWith(lastSportAge: state.player.age);

  static GameState recordGrooming(GameState state) =>
      state.copyWith(lastGroomingAge: state.player.age);

  static GameState recordLearning(GameState state) =>
      state.copyWith(lastLearningAge: state.player.age);

  /// Durumdan okunan bakım özeti.
  static UpkeepStatus statusOf(GameState state) => UpkeepStatus(
        yearsSinceSport: state.yearsSinceSport,
        yearsSinceGrooming: state.yearsSinceGrooming,
        yearsSinceLearning: state.yearsSinceLearning,
      );

  /// Son yıllarda bakım yapıldı mı? (Saç dökülmesi yumuşatması için.)
  static bool groomedRecently(GameState state) {
    final int? yil = state.yearsSinceGrooming;
    return yil != null && yil <= StatAging.prototypeOnlyFreshYears;
  }
}
