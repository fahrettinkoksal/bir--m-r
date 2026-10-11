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
  /// prototypeOnly: bir yılda en fazla kaç hedefin adı bildirimde anılır.
  ///
  /// Bir yılda beş hedef birden tamamlanırsa beş pencere üst üste
  /// açılmaz; kalanı yine kaydedilir, yalnızca bildirimi yazılmaz.
  ///
  /// Bir yılda kaç hedef tamamlanırsa tamamlansın **tek pencere** açılır:
  /// aynı başlıklı iki pencere üst üste açmak bildirim yağmuru sayılıyor
  /// (D-162). Ölçüm: 100 hayatta en kötü yıl dokuz pencereydi ve bunun
  /// ikisi aynı başlıklı hedef bildirimiydi; birleştirmeyle sekize indi
  /// (`critical_notice_test`).
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

    // Anılacak hedefler: en fazla sabitteki kadar, sırası korunur.
    final List<String> anilanIdler = <String>[];
    final List<String> etiketler = <String>[];
    for (final String id in yeni.keys) {
      if (etiketler.length >= prototypeOnlyMaxNoticesPerYear) break;
      final LifeGoal? hedef = lifeGoalById(id);
      if (hedef == null) continue;
      anilanIdler.add(id);
      etiketler.add(hedef.label);
    }

    // Tek hedefte eski metin aynen kalır; birden fazlasında tek pencere.
    final List<PendingNotice> bildirimler = <PendingNotice>[
      if (etiketler.length == 1)
        Notices.goalReached(
          playerAge: newAge,
          goalId: anilanIdler.first,
          label: etiketler.first,
        )
      else if (etiketler.length > 1)
        Notices.goalsReached(playerAge: newAge, labels: etiketler),
    ];

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
