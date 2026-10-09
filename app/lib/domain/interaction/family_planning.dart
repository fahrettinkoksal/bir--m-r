/// Çocuk planı: çiftin niyetinin kaydı (Paket BK/2).
///
/// **Q-201'in cevabı.** Oyuncunun çocuk sahibi olma yolu tekti ve
/// görünmezdi: eş/sevgili kartından yakınlaşıp "korunmadan" demek. Niyet
/// hiçbir yere yazılmıyor, ertesi yıl hatırlanmıyor ve ekranda
/// görünmüyordu. Faho'nun Paket 25 kararı yerinde duruyor — **"çocuk
/// yap" düğmesi yok, çocuk bir ihtimal** — değişen şey niyetin artık
/// açıkça seçilebilmesi.
///
/// Bu motor **gebelik ihtimaline dokunmaz**. Bütün sayılar `Intimacy`
/// içinde kalır ve `prototypeOnly`'dir; burada yalnızca kimin ne
/// istediği kayda girer.
library;

import '../models/game_state.dart';
import '../models/life_log.dart';
import '../models/person.dart';
import '../models/pregnancy.dart';
import 'intimacy.dart';
import 'marriage_engine.dart';

class FamilyPlanning {
  const FamilyPlanning();

  /// Planı konuşmaya engel; engel yoksa boş metin.
  ///
  /// Engeller yakınlaşmanın engelleriyle **aynı**: plan eş ya da
  /// sevgiliyle konuşulur, yetişkinlikten itibaren. Ayrı bir kural
  /// uydurulmadı.
  String blockReason(GameState state, Person person) =>
      Intimacy.blockReason(state, person);

  /// Çiftin planını yazar.
  ///
  /// Aynı plan yeniden seçilirse kayıt **değişmez**: günlüğe her
  /// dokunuşta satır düşmesin.
  FamilyResult setPlan(GameState state, String personId, FamilyPlan plan) {
    final Person? person = state.personById(personId);
    if (person == null) {
      return FamilyResult(
        state: state,
        outcome: const FamilyOutcome(
          applied: false,
          text: 'Bu kişi kayıtlarda yok.',
        ),
      );
    }
    final String engel = blockReason(state, person);
    if (engel.isNotEmpty) {
      return FamilyResult(
        state: state,
        outcome: FamilyOutcome(applied: false, text: engel),
      );
    }
    if (state.familyPlanFor(personId) == plan) {
      return FamilyResult(
        state: state,
        outcome: FamilyOutcome(
          applied: false,
          text: 'Bu konuda zaten anlaşmışsınız: ${plan.description}',
        ),
      );
    }

    final String satir = switch (plan) {
      FamilyPlan.istiyor =>
        '${person.firstName} ile çocuk sahibi olmaya karar verdiniz.',
      FamilyPlan.istemiyor =>
        '${person.firstName} ile şimdilik çocuk düşünmemeye karar '
            'verdiniz.',
      FamilyPlan.belirsiz =>
        '${person.firstName} ile çocuk konusunu açık bıraktınız.',
    };

    return FamilyResult(
      state: state.copyWith(
        familyPlan: plan,
        familyPlanPartnerId: personId,
        log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
          ...state.log,
          LifeLogEntry(
            age: state.player.age,
            text: satir,
            category: LogCategory.aile,
            personId: personId,
          ),
        ]),
      ),
      outcome: FamilyOutcome(applied: true, text: plan.description),
    );
  }
}
