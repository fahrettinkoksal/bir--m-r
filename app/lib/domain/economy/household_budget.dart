/// Hane bütçesi, nafaka ve velayet (D-160).
///
/// **Neden var:** Tek cüzdan vardı; evlilik ekonomik olarak hiçbir şeyi
/// değiştirmiyordu. Eşin kendi geliri "kendi giderini karşılar"
/// varsayılıyordu ve boşanmanın çocuklara ya da paraya dair hiçbir
/// sonucu yoktu.
///
/// **Q-118'in kararını değiştirir.** O soruda "nafaka ve velayet şimdilik
/// yazılmasın" denmişti; Faho'nun açık isteğiyle eklendi. Hâlâ bir hukuk
/// simülasyonu değildir: yoksulluk nafakası ile iştirak nafakası ayrı
/// modellenmez, mal rejimi sözleşmesi ve katkı payı yoktur (D-075 bunları
/// bilerek dışarıda bırakıyor).
///
/// Üç şey yapar:
/// 1. **Ortak bütçe:** çalışan eş her yıl gelirinin bir bölümünü haneye
///    koyar. Ayrı bir hesap alanı açılmaz — para doğrudan cüzdana girer
///    ve günlüğe yazılır, çünkü oyunda tek cüzdan var ve ikinci bir
///    bakiye bütün ekranları ikiye bölerdi.
/// 2. **Velayet:** boşanmada 18 yaş altı çocukların hangi hanede kalacağı
///    belirlenir. Kayıt silinmez; çocuk yine İlişkiler'de durur.
/// 3. **Nafaka:** çocuk kendisinde kalmayan taraf yıllık bir tutar öder.
///    Tutar boşanmada **bir kez** hesaplanır.
///
/// Bütün sayılar `prototypeOnly`'dir (Q-163).
library;

import '../models/game_state.dart';
import '../models/household.dart';
import '../models/life_log.dart';
import '../models/person.dart';
import '../models/person_development.dart';
import '../models/relation.dart';
import '../../text/turkish_text.dart';

abstract final class HouseholdBudget {
  /// prototypeOnly: çalışan eşin yıllık gelirinden haneye koyduğu pay.
  ///
  /// Tamamı değil: eşin kendi gideri, kendi birikimi ve kendi harcaması
  /// var. Kalanı kendi kaydında birikmeye devam eder.
  static const double prototypeOnlySpouseShare = 0.35;

  /// prototypeOnly: nafakanın ödeyen tarafın yıllık gelirine oranı.
  static const double prototypeOnlyAlimonyRate = 0.18;

  /// prototypeOnly: çocuk başına eklenen pay.
  static const double prototypeOnlyAlimonyPerChild = 0.06;

  /// prototypeOnly: nafakanın en yüksek oranı.
  static const double prototypeOnlyAlimonyMaxRate = 0.4;

  /// prototypeOnly: nafakanın işlediği en büyük çocuk yaşı.
  static const int prototypeOnlyChildSupportUntil = 18;

  // -------------------------------------------------------------------
  // 1) Ortak bütçe
  // -------------------------------------------------------------------

  /// Çalışan eşin bu yıl haneye koyduğu tutar; katkı yoksa 0.
  ///
  /// Yalnızca **yürüyen** evlilikte ve eşin gerçekten bir işi varsa
  /// hesaplanır; uydurma gelir yazılmaz.
  static int spouseContribution(GameState state) {
    final Person? es = state.spouse;
    if (es == null || !es.isAlive) return 0;
    if (state.marriage == null || !state.marriage!.isActive) return 0;
    final PersonDevelopment? gelisim = es.development;
    if (gelisim == null || !gelisim.isEmployed) return 0;
    final int maas = gelisim.job?.yearlySalary ?? 0;
    if (maas <= 0) return 0;
    return (maas * prototypeOnlySpouseShare).round();
  }

  /// Eşin katkısını cüzdana yazar (yılda bir kez).
  static GameState applySpouseContribution({
    required GameState state,
    required int newAge,
  }) {
    final int katki = spouseContribution(state);
    if (katki <= 0) return state;
    final Person es = state.spouse!;
    return state.copyWith(
      player: state.player.copyWith(
        wallet: state.player.wallet + katki,
      ),
      log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
        ...state.log,
        LifeLogEntry(
          age: newAge,
          text: '${es.firstName} bu yıl haneye ${trMoney(katki)} koydu.',
          category: LogCategory.aile,
        ),
      ]),
    );
  }

  // -------------------------------------------------------------------
  // 2) Velayet
  // -------------------------------------------------------------------

  /// Boşanmada hanede bakılan (18 yaş altı) çocuklar.
  static List<Person> minorChildren(GameState state) => state.people
      .where((Person p) =>
          p.relation == RelationType.cocuk &&
          p.isAlive &&
          p.age < prototypeOnlyChildSupportUntil)
      .toList(growable: false);

  // Not: velayet için 50'lik tek bir yakınlık eşiği tutuluyordu ve hiç
  // okunmuyordu. `decideCustody` gerçekte aşağıdaki 40/60 bandını
  // kullanıyor: altı eski eşe, üstü oyuncuya, arası ortak.


  /// prototypeOnly: ortak düzen için yakınlık aralığı.
  static const int prototypeOnlyJointBandLow = 40;
  static const int prototypeOnlyJointBandHigh = 60;

  /// Boşanmada velayet düzeni.
  static Custody decideCustody(GameState state) {
    final List<Person> cocuklar = minorChildren(state);
    if (cocuklar.isEmpty) return Custody.oyuncuda;
    final int ortalama = cocuklar.fold<int>(0, (int t, Person p) => t + p.bond) ~/
        cocuklar.length;
    if (ortalama >= prototypeOnlyJointBandHigh) return Custody.oyuncuda;
    if (ortalama <= prototypeOnlyJointBandLow) return Custody.eskiEste;
    return Custody.ortak;
  }

  // -------------------------------------------------------------------
  // 3) Nafaka
  // -------------------------------------------------------------------

  /// Boşanmada nafaka kaydı; gerekmiyorsa `null`.
  ///
  /// Kimin ödediği **velayete** bağlıdır: çocuk kendisinde kalmayan taraf
  /// öder. Ortak düzende kimse ödemez. Çocuk yoksa nafaka yoktur — bu
  /// sürümde yoksulluk nafakası modellenmiyor (Q-163).
  static Alimony? computeAlimony({
    required GameState state,
    required Custody custody,
    required String exSpouseId,
  }) {
    final List<Person> cocuklar = minorChildren(state);
    if (cocuklar.isEmpty) return null;
    if (custody == Custody.ortak) return null;

    final bool oyuncuOder = custody == Custody.eskiEste;

    // Ödeyen tarafın geliri: oyuncu ödüyorsa oyuncunun maaşı, eski eş
    // ödüyorsa onun kendi kaydındaki maaşı. Bilinmiyorsa nafaka yoktur;
    // uydurma gelir üretilmez.
    final int gelir;
    if (oyuncuOder) {
      gelir = state.career.yearlySalary;
    } else {
      final Person? es = state.personById(exSpouseId);
      gelir = es?.development?.job?.yearlySalary ?? 0;
    }
    if (gelir <= 0) return null;

    final double oran = (prototypeOnlyAlimonyRate +
            cocuklar.length * prototypeOnlyAlimonyPerChild)
        .clamp(0.0, prototypeOnlyAlimonyMaxRate);
    final int tutar = (gelir * oran).round();
    if (tutar <= 0) return null;

    // En küçük çocuk 18'ini doldurunca biter.
    int enKucukYas = cocuklar.first.age;
    for (final Person c in cocuklar) {
      if (c.age < enKucukYas) enKucukYas = c.age;
    }
    final int kalanYil = prototypeOnlyChildSupportUntil - enKucukYas;

    return Alimony(
      otherPersonId: exSpouseId,
      yearlyAmount: tutar,
      startedAtAge: state.player.age,
      untilAge: state.player.age + kalanYil,
      playerPays: oyuncuOder,
      custody: custody,
    );
  }

  /// Nafakayı bir yıl işletir.
  ///
  /// Ödeyen oyuncuysa cüzdandan **ne varsa o kadar** düşer; bakiye eksiye
  /// inmez ve borç yazılmaz (D-039 ile aynı ilke). Süresi dolan kayıt
  /// silinmez, kapanır.
  static GameState advanceYear({
    required GameState state,
    required int newAge,
  }) {
    final Alimony? kayit = state.alimony;
    if (kayit == null || !kayit.isActive) return state;

    if (!kayit.runsAt(newAge)) {
      return state.copyWith(
        alimony: kayit.copyWith(endedAtAge: newAge),
        log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
          ...state.log,
          LifeLogEntry(
            age: newAge,
            text: 'Nafaka yükümlülüğü sona erdi.',
            category: LogCategory.aile,
          ),
        ]),
      );
    }

    final String metin;
    GameState next;
    if (kayit.playerPays) {
      final int odenen = kayit.yearlyAmount
          .clamp(0, state.player.wallet.clamp(0, 1 << 31));
      if (odenen <= 0) return state;
      next = state.copyWith(
        player: state.player.copyWith(
          wallet: state.player.wallet - odenen,
        ),
      );
      metin = odenen >= kayit.yearlyAmount
          ? 'Nafaka olarak ${trMoney(odenen)} ödedin.'
          : 'Nafakayı tam ödeyemedin; elindeki ${trMoney(odenen)} gitti.';
    } else {
      next = state.copyWith(
        player: state.player.copyWith(
          wallet: state.player.wallet + kayit.yearlyAmount,
        ),
      );
      metin = 'Nafaka olarak ${trMoney(kayit.yearlyAmount)} aldın.';
    }

    return next.copyWith(
      alimony: kayit.copyWith(paidYears: kayit.paidYears + 1),
      log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
        ...next.log,
        LifeLogEntry(age: newAge, text: metin, category: LogCategory.aile),
      ]),
    );
  }
}
