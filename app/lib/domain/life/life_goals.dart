/// Hayat hedeflerinin motoru (D-156).
///
/// Tek işi var: her yıl hedeflere bakıp **yeni ulaşılanı o yılın
/// yaşıyla** kaydetmek. Sonradan hesaplama yapmaz, ödül vermez, hiçbir
/// değeri değiştirmez.
///
/// Kayıt silinmez: bir kez ulaşılan hedefin yaşı bir daha değişmez. Bu
/// bilerek böyledir — ev satılsa bile "otuz beşinde ev sahibi oldun"
/// gerçekten yaşanmış bir andır.
library;

import '../../data/life_goal_catalog.dart';
import '../models/game_state.dart';
import '../models/pending_notice.dart';
import 'notices.dart';

abstract final class LifeGoals {
  /// prototypeOnly: bir yılda en fazla kaç hedef bildirimi gösterilir.
  ///
  /// Bir yılda beş hedef birden tamamlanırsa beş pencere üst üste
  /// açılmaz; kalanı yine kaydedilir, yalnızca bildirimi yazılmaz.
  static const int prototypeOnlyMaxNoticesPerYear = 2;

  /// Bu yıl yeni ulaşılan hedefleri kaydeder.
  ///
  /// [newAge] bu yılın yaşıdır. Zaten ulaşılmış hedefe tekrar bakılmaz.
  static GameState advanceYear({
    required GameState state,
    required int newAge,
  }) {
    final Map<String, int> yeni = <String, int>{};
    for (final LifeGoal hedef in kLifeGoals) {
      if (state.goalReached(hedef.id)) continue;
      if (!hedef.reached(state)) continue;
      yeni[hedef.id] = newAge;
    }
    if (yeni.isEmpty) return state;

    final List<PendingNotice> bildirimler = <PendingNotice>[];
    for (final String id in yeni.keys) {
      if (bildirimler.length >= prototypeOnlyMaxNoticesPerYear) break;
      final LifeGoal? hedef = lifeGoalById(id);
      if (hedef == null) continue;
      bildirimler.add(
        Notices.goalReached(
          playerAge: newAge,
          goalId: id,
          label: hedef.label,
        ),
      );
    }

    return state.copyWith(
      goalsReachedAt: Map<String, int>.unmodifiable(<String, int>{
        ...state.goalsReachedAt,
        ...yeni,
      }),
      notices: List<PendingNotice>.unmodifiable(<PendingNotice>[
        ...state.notices,
        ...bildirimler,
      ]),
    );
  }

  /// Ulaşılan hedef sayısı.
  static int reachedCount(GameState state) => kLifeGoals
      .where((LifeGoal g) => state.goalReached(g.id))
      .length;

  /// Ulaşılan hedefler, ulaşıldıkları yaşa göre sıralı.
  static List<({LifeGoal goal, int age})> reachedInOrder(GameState state) {
    final List<({LifeGoal goal, int age})> liste =
        <({LifeGoal goal, int age})>[];
    for (final LifeGoal g in kLifeGoals) {
      final int? yas = state.goalsReachedAt[g.id];
      if (yas != null) liste.add((goal: g, age: yas));
    }
    liste.sort((({LifeGoal goal, int age}) a, ({LifeGoal goal, int age}) b) =>
        a.age.compareTo(b.age));
    return List<({LifeGoal goal, int age})>.unmodifiable(liste);
  }
}
