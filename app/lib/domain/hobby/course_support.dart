// Kurs ücreti için aileden destek istemek.
//
// **Kural:** para yoktan yaratılmaz. Ebeveynin ödeyebileceği tutar
// onun varlık düzeyinden geliyor ve **yıllık bir bütçe** olarak
// tutuluyor; aynı yıl aynı anneden sınırsız destek alınamıyor. Bütçe
// `interactionCounts` içinde tutuluyor ve o harita her yaşta sıfırlandığı
// için destek hakkı da yıl başına yenileniyor.
//
// **Karar tek zar değil.** Kabul ihtimali ailenin varlığı, oyuncuyla
// yakınlık, ücretin aile bütçesine oranı, çocuğun o hobideki
// devamlılığı ve daha önce yarıda bıraktığı kurslar üzerinden kuruluyor.
// Zar yalnızca son küçük dokunuş.
library;

import 'dart:math';

import '../../data/activity_catalog.dart';
import '../../data/economy.dart';
import '../models/life_log.dart';
import '../models/game_state.dart';
import '../models/hobby_progress.dart';
import '../models/person.dart';
import '../models/relation.dart';
import '../models/wealth.dart';
import 'course_progress.dart';
import 'hobby_tracker.dart';

/// Desteğin sonucu.
class CourseSupportOutcome {
  const CourseSupportOutcome({
    required this.applied,
    required this.accepted,
    required this.text,
    this.amount = 0,
  });

  /// İşlem yapıldı mı (engel yoktu)?
  final bool applied;

  /// Ebeveyn kabul etti mi?
  final bool accepted;

  final String text;

  /// Ailenin ödediği tutar (₺).
  final int amount;
}

class CourseSupportResult {
  const CourseSupportResult({required this.state, required this.outcome});

  final GameState state;
  final CourseSupportOutcome outcome;
}

/// Kurs desteği kuralları.
abstract final class CourseSupport {
  /// prototypeOnly: bir ebeveynin **yıllık** kurs desteği kapasitesi,
  /// yıllık net asgari ücrete oran olarak.
  ///
  /// Oyunun kendi ekonomik ölçeğinden üretiliyor: asgari ücret çıpası
  /// değişirse aile bütçesi de birlikte kayar.
  static const Map<WealthTier, double> prototypeOnlyYearlyBudgetShare =
      <WealthTier, double>{
    WealthTier.cokYoksul: 0.01,
    WealthTier.yoksul: 0.03,
    WealthTier.ortaHalli: 0.10,
    WealthTier.varlikli: 0.35,
    WealthTier.cokVarlikli: 1.00,
  };

  /// prototypeOnly: destek istenebilmesi için gereken asgari yakınlık.
  static const int prototypeOnlyMinBond = 20;

  /// prototypeOnly: bir hobinin "yarıda bırakılmış" sayılması için
  /// üstünden geçmesi gereken yıl.
  static const int prototypeOnlyAbandonYears = 4;

  static const String budgetKind = 'kursDestek';
  static const String creditKind = 'kursKredi';
  static const String refusalKind = 'kursRet';

  /// Bu ebeveynin yıllık destek kapasitesi (₺).
  static int yearlyBudget(Person person) {
    final WealthTier? varlik = person.wealth;
    if (varlik == null) return 0;
    final double pay = prototypeOnlyYearlyBudgetShare[varlik] ?? 0;
    return (Economy.netYearlyMinimumWage * pay).round();
  }

  /// Bu yıl bu kişiden alınan destek (₺).
  static int usedThisYear(GameState state, String personId) =>
      state.interactionCount(personId, budgetKind);

  /// Bu hobi için bu yıl elde edilmiş, henüz harcanmamış kredi (₺).
  static int creditFor(GameState state, String hobbyId) =>
      state.interactionCount(hobbyId, creditKind);

  /// Bu yıl bu kişi bu hobi için reddetti mi?
  static bool refusedThisYear(
    GameState state,
    String hobbyId,
    String personId,
  ) =>
      state.interactionCount('$hobbyId@$personId', refusalKind) > 0;

  /// Destek istenebilecek kişiler.
  ///
  /// Ebeveyn yoksa liste boş döner; ekranda olmayan bir seçenek
  /// gösterilmez.
  static List<Person> sponsorsFor(GameState state) => state.people
      .where((Person p) =>
          p.isAlive &&
          (p.relation == RelationType.anne ||
              p.relation == RelationType.baba ||
              p.relation == RelationType.uveyAnne ||
              p.relation == RelationType.uveyBaba) &&
          p.wealth != null)
      .toList(growable: false);

  /// Destek istemenin engeli; yoksa boş metin.
  static String blockReason(
    GameState state,
    ActivityAction action,
    Person person,
  ) {
    final CourseStanding? durum = CourseProgress.standingFor(state, action);
    if (durum == null) return 'Bu bir kurs değil.';
    if (durum.fee == 0) return 'Bu ders zaten ücretsiz.';
    if (state.player.age >= kAdultAge) {
      return 'Artık kendi kursunu kendin karşılıyorsun.';
    }
    if (!person.isAlive) return 'Artık mümkün değil.';
    if (person.wealth == null) {
      return '${person.firstName} kendi parasını kazanmıyor.';
    }
    if (person.bond < prototypeOnlyMinBond) {
      return 'Aranız bunu isteyecek kadar yakın değil.';
    }
    if (refusedThisYear(state, durum.hobby.id, person.id)) {
      return '${person.firstName} bu yıl için kararını verdi; '
          'seneye yeniden sorabilirsin.';
    }
    if (creditFor(state, durum.hobby.id) >= durum.fee) {
      return 'Bu kursun ücreti zaten karşılandı.';
    }
    return '';
  }

  /// Oyuncunun yetişkin sayıldığı yaş.
  static const int kAdultAge = 18;

  /// Çocuğun yarıda bıraktığı hobi sayısı.
  ///
  /// Başlanmış, ilk basamağı geçmemiş ve uzun süredir dokunulmamış her
  /// hobi bir "bıraktı" sayılır. Ebeveyn bunu hatırlar.
  static int abandonedCount(GameState state) {
    int sayi = 0;
    for (final HobbyProgress p in state.hobbies) {
      final bool eski =
          state.player.age - p.lastPracticedAge >= prototypeOnlyAbandonYears;
      if (eski && p.stage <= 1) sayi++;
    }
    return sayi;
  }

  /// Kabul ihtimali (0-1).
  ///
  /// Her bileşen ayrı ayrı okunabilir olsun diye açık yazıldı; tek bir
  /// sihirli sayı yok.
  static double acceptChance({
    required GameState state,
    required ActivityAction action,
    required Person person,
    required CourseStanding standing,
  }) {
    final int butce = yearlyBudget(person);
    if (butce <= 0) return 0;
    final int kalan = (butce - usedThisYear(state, person.id)).clamp(0, butce);
    if (kalan < standing.fee) return 0;

    // Taban bilerek orta yerde: bileşenlerin oynayacak yeri kalsın.
    // İlk yazımda taban 0,85'ti ve orta hâlli aile ile varlıklı aile
    // arasındaki fark ölçümde kaybolmuştu (188 / 190) — hepsi tavana
    // yapışıyordu.
    //
    // 1) Ücretin aile bütçesine oranı: küçük istek kolay kabul edilir.
    final double yuk = standing.fee / butce;
    double sans = 0.42 - yuk * 0.55;

    // 2) Yakınlık: 20 eşiğinden 100'e doğru artan pay.
    sans += ((person.bond - prototypeOnlyMinBond) / 80).clamp(0.0, 1.0) * 0.22;

    // 3) Devamlılık: bu hobide ne kadar yol alındı? §6'nın istediği şey
    // burada: uzun süredir devam eden çocuğa aile daha kolay "peki" der.
    final HobbyProgress? ilerleme =
        HobbyTracker.progressOf(state, standing.hobby);
    final int yil = ilerleme?.years ?? 0;
    final int ders = ilerleme?.experience ?? 0;
    sans += (yil / 5).clamp(0.0, 1.0) * 0.22;
    sans += (ders / 20).clamp(0.0, 1.0) * 0.10;

    // 4) Yarıda bırakılan kurslar: her biri temkini artırır.
    sans -= abandonedCount(state) * 0.14;

    // 5) Varlıklı aile zaten rahat; dar gelirli aile zorlanır.
    sans += switch (person.wealth!) {
      WealthTier.cokYoksul => -0.18,
      WealthTier.yoksul => -0.10,
      WealthTier.ortaHalli => 0.0,
      WealthTier.varlikli => 0.14,
      WealthTier.cokVarlikli => 0.22,
    };

    return sans.clamp(0.02, 0.95);
  }

  /// Aileden kurs desteği ister.
  static CourseSupportResult ask({
    required GameState state,
    required ActivityAction action,
    required Person person,
    required Random rng,
  }) {
    final String engel = blockReason(state, action, person);
    if (engel.isNotEmpty) {
      return CourseSupportResult(
        state: state,
        outcome: CourseSupportOutcome(
          applied: false,
          accepted: false,
          text: engel,
        ),
      );
    }
    final CourseStanding durum = CourseProgress.standingFor(state, action)!;
    final double sans = acceptChance(
      state: state,
      action: action,
      person: person,
      standing: durum,
    );
    final bool kabul = rng.nextDouble() < sans;

    if (!kabul) {
      final String metin = _redMetni(person, durum, state);
      return CourseSupportResult(
        state: _log(
          state.copyWith(interactionCounts: <String, int>{
            ...state.interactionCounts,
            GameState.interactionKey(
              '${durum.hobby.id}@${person.id}',
              refusalKind,
            ): 1,
          }),
          metin,
        ),
        outcome: CourseSupportOutcome(
          applied: true,
          accepted: false,
          text: metin,
        ),
      );
    }

    final String metin = _kabulMetni(person, durum, state);
    final GameState next = _log(
      state.copyWith(interactionCounts: <String, int>{
        ...state.interactionCounts,
        // Ailenin yıllık bütçesinden düşülür: aynı yıl aynı kişiden
        // sınırsız destek alınamaz.
        GameState.interactionKey(person.id, budgetKind):
            usedThisYear(state, person.id) + durum.fee,
        // Kredi derste harcanır; iki kez kullanılamaz.
        GameState.interactionKey(durum.hobby.id, creditKind):
            creditFor(state, durum.hobby.id) + durum.fee,
      }),
      metin,
    );
    return CourseSupportResult(
      state: next,
      outcome: CourseSupportOutcome(
        applied: true,
        accepted: true,
        text: metin,
        amount: durum.fee,
      ),
    );
  }

  /// Ders yapılırken krediyi harcar; kalan tutarı döner.
  static ({GameState state, int remaining}) spendCredit(
    GameState state,
    String hobbyId,
    int fee,
  ) {
    final int kredi = creditFor(state, hobbyId);
    if (kredi <= 0) return (state: state, remaining: fee);
    final int kullanilan = kredi >= fee ? fee : kredi;
    return (
      state: state.copyWith(interactionCounts: <String, int>{
        ...state.interactionCounts,
        GameState.interactionKey(hobbyId, creditKind): kredi - kullanilan,
      }),
      remaining: fee - kullanilan,
    );
  }

  static GameState _log(GameState state, String text) => state.copyWith(
        log: <LifeLogEntry>[
          ...state.log,
          LifeLogEntry(
            age: state.player.age,
            text: text,
            category: LogCategory.aile,
          ),
        ],
      );

  static String _kabulMetni(
    Person person,
    CourseStanding standing,
    GameState state,
  ) {
    final HobbyProgress? ilerleme =
        HobbyTracker.progressOf(state, standing.hobby);
    final int yil = ilerleme?.years ?? 0;
    if (yil >= 3) {
      return '$yil yıldır aynı kursa gidiyorsun. '
          '${person.firstName} artık bunun geçici bir heves olmadığını '
          'biliyor. Ücreti üstlendi.';
    }
    return '${person.firstName} bir süre düşündü. '
        '"Madem bu kadar seviyorsun, devam et." Kayıt ücretini ödedi.';
  }

  static String _redMetni(
    Person person,
    CourseStanding standing,
    GameState state,
  ) {
    if (abandonedCount(state) >= 2) {
      return '${person.firstName} yarıda bıraktığın kursları hatırlattı. '
          '"Bir bitir de öyle konuşalım."';
    }
    return '${person.firstName} fiyatı görünce kaşlarını kaldırdı. '
        '"Bu ay olmaz."';
  }
}
