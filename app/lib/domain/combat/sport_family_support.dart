// 18 yaş altı sporcunun spor masraflarında aile desteği
// (Paket AL/2, §1-§5, §26).
//
// **Sıfırdan yazılmadı.** Paket AJ'nin kurs desteği (`CourseSupport`)
// aynı soruyu zaten çözmüştü: çocuk bir masrafı karşılayamıyorsa
// aileden isteyebilir, aile varlığına ve ilişkiye göre kabul eder ya da
// etmez, ve verdiği para **kendi yıllık bütçesinden** düşer. Bu modül o
// mantığı spora taşıyor ve **aynı ebeveyn bütçesini** kullanıyor:
// `CourseSupport.budgetKind`. Yani anne bu yıl kurs ücretini ödediyse
// spor kampına ayıracak parası o kadar azalır. İki sistem birbirinden
// habersiz iki ayrı cüzdan yaratmıyor (§3).
//
// **Para yoktan yaratılmıyor.** Destek kabul edilince tutar ebeveynin
// yıllık kapasitesinden düşülür ve masrafa özel bir **kredi** olarak
// yazılır. Masraf ödenirken önce kredi harcanır. Aynı masraf için anne,
// baba ve cüzdandan üç kez ödeme yapılamaz: kredi masrafı karşıladığı
// anda yeni destek istemenin yolu kapanır (§3).
//
// **18 yaş sonrası.** Spor gideri oyuncunun kendisine aittir; bu ekran
// 18 yaşından sonra hiç görünmez (§5). Yetişkinin genel aile
// yardımı istemesi ayrı bir sistemdir ve buraya karışmaz.
//
// **Ret kariyeri bitirmez.** Ebeveyn hayır derse daha ucuz antrenör,
// normal hazırlık, turnuvayı kaçırmak ve seneye yeniden sormak açık
// kalır (§4).
library;

import 'dart:math';

import '../../data/economy.dart';
import '../../data/martial_arts_catalog.dart';
import '../hobby/course_support.dart';
import '../models/combat_career.dart';
import '../models/game_state.dart';
import '../models/life_log.dart';
import '../models/person.dart';
import '../models/wealth.dart';

/// Desteği istenebilecek spor masrafı (§1).
///
/// Kasıtlı olarak kısa tutuldu: Paket AL §10'un kuralı burada da
/// geçerli, yirmi mikro kalem yerine oyuncunun gerçekten karar
/// verdiği dört başlık.
enum SportExpense {
  /// Kulüp aidatı ve ders ücreti.
  ders('Kulüp ve ders ücreti'),

  /// Ekipman ve turnuva yol masrafı.
  ekipman('Ekipman ve turnuva yolu'),

  /// Müsabaka öncesi hazırlık kampı.
  kamp('Müsabaka kampı'),

  /// Özel antrenör ücreti.
  koc('Özel antrenör');

  const SportExpense(this.label);

  final String label;
}

/// Bir destek isteğinin sonucu.
class SportSupportOutcome {
  const SportSupportOutcome({
    required this.applied,
    required this.accepted,
    required this.text,
    this.amount = 0,
  });

  /// İstek işleme alındı mı (önünde engel yoktu)?
  final bool applied;

  /// Ebeveyn kabul etti mi?
  final bool accepted;

  final String text;

  /// Ailenin üstlendiği tutar (₺).
  final int amount;
}

class SportSupportResult {
  const SportSupportResult({required this.state, required this.outcome});

  final GameState state;
  final SportSupportOutcome outcome;
}

/// Spor masraflarında aile desteği kuralları.
abstract final class SportFamilySupport {
  /// prototypeOnly: ekipman ve turnuva yolunun yıllık maliyeti
  /// (yıllık net asgari ücrete oran).
  ///
  /// Gerçek bir TL değeri yazılmadı; oyunun kendi ekonomik çıpasından
  /// türetiliyor.
  static const double prototypeOnlyGearShare = 0.03;

  /// prototypeOnly: ekipmanı/yolu karşılayamayan genç sporcunun
  /// hazırlık payından düşen kesinti.
  ///
  /// **Müsabakayı kapatmaz** (§4): eskimiş ekipmanla ve uzun yolculuk
  /// sonrası da müsabakaya çıkılır, ama hazırlık bir miktar eksik olur.
  /// Bedel kazanma ihtimaline doğrudan değil, hazırlık üzerinden
  /// yansır.
  static const double prototypeOnlyGearPenalty = 0.06;

  /// Spor kredisinin `interactionCounts` türü.
  static const String creditKind = 'sporKredi';

  /// Bu yıl bu masraf için bu kişinin verdiği ret.
  static const String refusalKind = 'sporRet';

  /// Oyuncunun yetişkin sayıldığı yaş (Paket AJ ile aynı çıpa).
  static int get adultAge => CourseSupport.kAdultAge;

  /// Destek istenebilecek ebeveynler.
  ///
  /// Paket AJ'nin listesi aynen kullanılır: yaşayan ve kendi parası
  /// olan anne/baba/üvey anne/üvey baba. Ebeveyn yoksa liste boştur ve
  /// ekranda sahte seçenek gösterilmez (§26).
  static List<Person> sponsorsFor(GameState state) =>
      CourseSupport.sponsorsFor(state);

  /// Rekabet eden, emekli olmamış kariyer; yoksa `null`.
  ///
  /// `CombatCareerEngine` bu modülü kullandığı için buradan ona geri
  /// bağlanmamak adına küçük bir kopya tutuluyor.
  static CombatCareer? _career(GameState state) {
    for (final CombatCareer c in state.combatCareers) {
      if (!c.isRetired) return c;
    }
    return null;
  }

  /// Bu masrafın varsayılan tutarı (₺).
  ///
  /// Hiçbiri yeni bir fiyat icat etmiyor: ders ücreti sanatın kendi
  /// `lessonCost` değeri, kamp ve koç motorun mevcut ücretleri,
  /// ekipman ise asgari ücret çıpasından türetiliyor.
  static int defaultCost(GameState state, SportExpense expense) {
    final CombatCareer? k = _career(state);
    switch (expense) {
      case SportExpense.ders:
        final MartialArt? sanat = k?.art;
        return sanat?.lessonCost ?? 0;
      case SportExpense.ekipman:
        return gearCost;
      case SportExpense.kamp:
        // Dengeli kampın ücreti; oyuncu daha ucuzunu seçebilir (§4).
        return (Economy.netYearlyMinimumWage * 0.05).round();
      case SportExpense.koc:
        // Bir üst kalite antrenörün yıllık ücreti.
        final int seviye = ((k?.coachLevel ?? 0) + 1).clamp(1, 2);
        return (Economy.netYearlyMinimumWage *
                <double>[0.0, 0.10, 0.28][seviye])
            .round();
    }
  }

  /// Ekipman ve turnuva yolunun yıllık tutarı (₺).
  static int get gearCost =>
      (Economy.netYearlyMinimumWage * prototypeOnlyGearShare).round();

  // =================================================================
  // Kredi — para yoktan yaratılmaz (§3)
  // =================================================================

  static String _creditKey(SportExpense e) => 'spor_${e.name}';

  /// Bu masraf için bu yıl elde edilmiş, henüz harcanmamış kredi (₺).
  static int creditFor(GameState state, SportExpense expense) =>
      state.interactionCount(_creditKey(expense), creditKind);

  /// Bu yıl bu kişi bu masraf için reddetti mi?
  static bool refusedThisYear(
    GameState state,
    SportExpense expense,
    Person person,
  ) =>
      state.interactionCount(
        '${_creditKey(expense)}@${person.id}',
        refusalKind,
      ) >
      0;

  /// Masraf ödenirken krediyi harcar; cüzdandan çıkacak tutarı döner.
  ///
  /// Kredi bir kez harcanır; ikinci çağrı aynı parayı yeniden
  /// vermez (§31).
  static ({GameState state, int remaining}) spendCredit(
    GameState state,
    SportExpense expense,
    int fee,
  ) {
    if (fee <= 0) return (state: state, remaining: fee);
    final int kredi = creditFor(state, expense);
    if (kredi <= 0) return (state: state, remaining: fee);
    final int kullanilan = kredi >= fee ? fee : kredi;
    return (
      state: state.copyWith(interactionCounts: <String, int>{
        ...state.interactionCounts,
        GameState.interactionKey(_creditKey(expense), creditKind):
            kredi - kullanilan,
      }),
      remaining: fee - kullanilan,
    );
  }

  // =================================================================
  // Ekipman — hazırlığa yansıyan bedel
  // =================================================================

  /// Kamp ücretinin cepten çıkacak kısmı (aile kredisi düşülmüş).
  static int outOfPocketCamp(GameState state, int campCost) =>
      (campCost - creditFor(state, SportExpense.kamp)).clamp(0, campCost);

  /// Genç sporcunun ekipman/yol parası bu kamp tercihinden sonra
  /// yetiyor mu?
  ///
  /// 18 yaşından büyük oyuncuda her zaman `true`: bu, çocuk sporcuya
  /// özgü bir masraf başlığıdır (§5).
  static bool gearCovered(GameState state, int campCost) {
    if (state.player.age >= adultAge) return true;
    if (_career(state) == null) return true;
    final int kalan = state.player.wallet - outOfPocketCamp(state, campCost);
    return kalan + creditFor(state, SportExpense.ekipman) >= gearCost;
  }

  /// Ekipman/yol parası yetmeyen genç sporcunun hazırlık kesintisi.
  static double gearPenalty(GameState state, int campCost) =>
      gearCovered(state, campCost) ? 0 : prototypeOnlyGearPenalty;

  /// Ekipman/yol masrafını tahsil eder: önce aile kredisi, sonra cüzdan.
  ///
  /// Karşılanamıyorsa **hiçbir şey alınmaz** ve müsabaka yine yapılır;
  /// bedel `gearPenalty` üzerinden hazırlığa yansımıştır.
  static ({GameState state, int paid}) chargeGear(
    GameState state,
    int campCost,
  ) {
    if (state.player.age >= adultAge) return (state: state, paid: 0);
    if (_career(state) == null) return (state: state, paid: 0);
    if (!gearCovered(state, campCost)) return (state: state, paid: 0);

    final ({GameState state, int remaining}) sonuc =
        spendCredit(state, SportExpense.ekipman, gearCost);
    if (sonuc.remaining <= 0) {
      return (state: sonuc.state, paid: gearCost);
    }
    return (
      state: sonuc.state.copyWith(
        player: sonuc.state.player.copyWith(
          wallet: sonuc.state.player.wallet - sonuc.remaining,
        ),
      ),
      paid: gearCost,
    );
  }

  // =================================================================
  // İstek
  // =================================================================

  /// Destek istemenin engeli; yoksa boş metin.
  static String blockReason({
    required GameState state,
    required SportExpense expense,
    required Person person,
    required int amount,
  }) {
    if (_career(state) == null) {
      return 'Henüz rekabet eden bir spor kariyerin yok.';
    }
    if (state.player.age >= adultAge) {
      // §5: yetişkin sporcunun gideri kendisine aittir.
      return 'Artık kendi spor masrafını kendin karşılıyorsun.';
    }
    if (amount <= 0) return 'Bu masraf için para gerekmiyor.';
    if (!person.isAlive) return 'Artık mümkün değil.';
    if (person.wealth == null) {
      return '${person.firstName} kendi parasını kazanmıyor.';
    }
    if (person.bond < CourseSupport.prototypeOnlyMinBond) {
      return 'Aranız bunu isteyecek kadar yakın değil.';
    }
    if (refusedThisYear(state, expense, person)) {
      return '${person.firstName} bu yıl için kararını verdi; '
          'seneye yeniden sorabilirsin.';
    }
    if (creditFor(state, expense) >= amount) {
      // §3: aynı masraf ikinci kez istenemez.
      return '${expense.label} zaten karşılandı.';
    }
    return '';
  }

  /// Kabul ihtimali (0-1).
  ///
  /// §2'nin altı ölçütü ayrı ayrı okunabilsin diye açık yazıldı.
  /// Tek antrenman yapmış çocuk pahalı elit koç parasını kolay kolay
  /// alamaz; yıllardır müsabakaya çıkan başarılı sporcu ise çok daha
  /// kolay alır.
  static double acceptChance({
    required GameState state,
    required SportExpense expense,
    required Person person,
    required int amount,
  }) {
    final int butce = CourseSupport.yearlyBudget(person);
    if (butce <= 0) return 0;
    final int kalan =
        (butce - CourseSupport.usedThisYear(state, person.id)).clamp(0, butce);
    if (kalan < amount) return 0;

    final CombatCareer? k = _career(state);
    if (k == null) return 0;

    // 1) Masrafın aile bütçesine oranı. En ağır bileşen: küçük istek
    //    kolay kabul edilir, bütçeyi zorlayan istek zor.
    final double yuk = amount / butce;
    double sans = 0.40 - yuk * 0.55;

    // 2) Yakınlık.
    sans += ((person.bond - CourseSupport.prototypeOnlyMinBond) / 80)
            .clamp(0.0, 1.0) *
        0.20;

    // 3) Devamlılık: kaç yıldır bu işin içinde ve kaç kez müsabakaya
    //    çıktı. §2'nin çekirdeği burası.
    final int yil = state.player.age - k.startedCompetitiveAtAge;
    sans += (yil / 5).clamp(0.0, 1.0) * 0.18;
    sans += (k.totalBouts / 12).clamp(0.0, 1.0) * 0.10;

    // Hiç müsabakaya çıkmamış çocuk için aile temkinlidir.
    if (k.totalBouts == 0) sans -= 0.18;

    // 4) Kariyer seviyesi: gerçek bir yere gidiyor mu?
    sans += (k.tier / 3).clamp(0.0, 1.0) * 0.12;
    sans += (k.reputation / 100).clamp(0.0, 1.0) * 0.10;
    sans += (k.championships.clamp(0, 2) / 2) * 0.08;

    // 5) Ailenin varlık seviyesi (Paket AJ ile aynı basamaklar).
    sans += switch (person.wealth!) {
      WealthTier.cokYoksul => -0.18,
      WealthTier.yoksul => -0.10,
      WealthTier.ortaHalli => 0.0,
      WealthTier.varlikli => 0.14,
      WealthTier.cokVarlikli => 0.22,
    };

    return sans.clamp(0.02, 0.95);
  }

  /// Aileden spor masrafı için destek ister.
  static SportSupportResult ask({
    required GameState state,
    required SportExpense expense,
    required Person person,
    required int amount,
    required Random rng,
  }) {
    final String engel = blockReason(
      state: state,
      expense: expense,
      person: person,
      amount: amount,
    );
    if (engel.isNotEmpty) {
      return SportSupportResult(
        state: state,
        outcome: SportSupportOutcome(
          applied: false,
          accepted: false,
          text: engel,
        ),
      );
    }

    final double sans = acceptChance(
      state: state,
      expense: expense,
      person: person,
      amount: amount,
    );
    final bool kabul = rng.nextDouble() < sans;

    if (!kabul) {
      final String metin = _redMetni(state, person, expense);
      return SportSupportResult(
        state: _log(
          state.copyWith(interactionCounts: <String, int>{
            ...state.interactionCounts,
            GameState.interactionKey(
              '${_creditKey(expense)}@${person.id}',
              refusalKind,
            ): 1,
          }),
          metin,
        ),
        outcome: SportSupportOutcome(
          applied: true,
          accepted: false,
          text: metin,
        ),
      );
    }

    final String metin = _kabulMetni(state, person, expense);
    final GameState next = _log(
      state.copyWith(interactionCounts: <String, int>{
        ...state.interactionCounts,
        // Ebeveynin **ortak** yıllık bütçesinden düşer: kurs desteği
        // ile aynı kese (§3).
        GameState.interactionKey(person.id, CourseSupport.budgetKind):
            CourseSupport.usedThisYear(state, person.id) + amount,
        GameState.interactionKey(_creditKey(expense), creditKind):
            creditFor(state, expense) + amount,
      }),
      metin,
    );

    return SportSupportResult(
      state: next,
      outcome: SportSupportOutcome(
        applied: true,
        accepted: true,
        text: metin,
        amount: amount,
      ),
    );
  }

  /// Ret sonrası oyuncuya kalan yollar (§4).
  static String refusalAdvice(SportExpense expense) => switch (expense) {
        SportExpense.ders => 'Bu yıl daha az ders alıp kendi başına '
            'çalışabilirsin.',
        SportExpense.ekipman => 'Eldeki ekipmanla da müsabakaya '
            'çıkabilirsin; hazırlığın biraz eksik kalır.',
        SportExpense.kamp => 'Daha ucuz bir hazırlık seçebilir ya da bu '
            'turnuvayı kaçırıp seneye çıkabilirsin.',
        SportExpense.koc => 'Kulüp hocasıyla devam edebilir, seneye '
            'yeniden sorabilirsin.',
      };

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
    GameState state,
    Person person,
    SportExpense expense,
  ) {
    final CombatCareer? k = _career(state);
    final int yil = k == null ? 0 : state.player.age - k.startedCompetitiveAtAge;
    if (yil >= 3 && (k?.totalWins ?? 0) >= 3) {
      return '${person.firstName} bu işin ciddiyetini artık görüyor. '
          '${expense.label} için parayı çıkardı.';
    }
    return '${person.firstName} bir süre düşündü. '
        '"Peki, bu seferlik." ${expense.label} karşılandı.';
  }

  static String _redMetni(
    GameState state,
    Person person,
    SportExpense expense,
  ) {
    final CombatCareer? k = _career(state);
    if ((k?.totalBouts ?? 0) == 0) {
      return '${person.firstName} temkinli. "Daha bir müsabakaya '
          'çıkmadın. Önce bir gör bakalım sevecek misin."';
    }
    return '${person.firstName} hesabı yaptı. '
        '"Bu ay olmaz." ${refusalAdvice(expense)}';
  }
}
