/// Banka ve kredi (D-080).
///
/// **Neden var:** Faho istedi — "banka sistemi ekleyelim, kredi
/// çekebilelim, faizi ile ödenebilir şekilde olsun; 2 adet banka ekle,
/// Fakbank ve Bankavrupa; biri daha az faiz versin ama krediyi
/// onaylamayabilir, biri daha çok faiz ama onaylasın".
///
/// **Oranlar uydurma değildir.** 2026 Türkiye'sinde ihtiyaç kredisi aylık
/// faizi çoğu bankada **%2,89 – %5,50** aralığında seyrediyor. Fakbank bu
/// bandın alt ucunda (%2,95), Bankavrupa üst ucuna yakın (%4,60) durur.
/// Yıllık bileşik karşılıkları sırasıyla yaklaşık **%42** ve **%72**'dir;
/// yüksek görünen bu sayılar oyunun abartısı değil, ülkenin gerçeğidir.
///
/// **Vade en fazla üç yıldır**, çünkü Türkiye'de ihtiyaç kredisi vadeleri
/// pratikte 36 ayla sınırlı. Daha uzun vade, bu faizle, geri ödenemeyecek
/// bir borç üretirdi.
///
/// Kurallar:
/// - Kredi **gerçekten değerlendirilir**: gelir, mevcut borç, yaş ve
///   ödeme geçmişi bakılır. Zengin olmak tek başına onay değildir;
///   geliri olmayana da otomatik ret verilmez, tutar küçülür.
/// - Taksit her yıl **gerçekten** cüzdandan düşer. Ödenemezse taksit
///   kaçar, borç faiziyle büyür ve sonraki başvurular zorlaşır.
/// - Kredi **erken kapatılabilir**: kalan borç ödenir.
/// - Bütün sayılar `prototypeOnly` (Q-120).
library;

import '../../data/economy.dart';
import '../models/game_state.dart';
import 'business_engine.dart';
import '../models/loan.dart';

/// Bir başvurunun sonucu.
class LoanDecision {
  const LoanDecision({
    required this.approved,
    required this.reason,
    this.offeredAmount = 0,
    this.annualPayment = 0,
  });

  final bool approved;

  /// Ret ya da kısmi onay gerekçesi; tam onayda kısa bir olumlu cümle.
  final String reason;

  /// Bankanın vermeye razı olduğu tutar.
  final int offeredAmount;

  /// O tutar için yıllık taksit.
  final int annualPayment;
}

/// Oyuncunun kredi karnesi (D-108).
///
/// Faho'nun isteği: "basit bir kredi durumu olsun". Karmaşık bir skor
/// değil, **dört kademeli** ve gerekçesi okunabilir bir durum. İcra ve
/// haciz bu sürümde **yoktur**; zemin bırakıldı (Q-127).
enum CreditStanding {
  iyi('İyi', 'Ödemelerin düzenli, yükün hafif.'),
  orta('Orta', 'Ödemelerin düzenli ama yükün ağırlaşıyor.'),
  riskli('Riskli', 'Taksit kaçırdın ya da yükün gelirini zorluyor.'),
  cokRiskli('Çok riskli', 'Birden fazla taksit kaçtı; kapılar kapanıyor.');

  const CreditStanding(this.label, this.description);

  final String label;
  final String description;
}

abstract final class Banking {
  /// prototypeOnly: ihtiyaç kredisinde en kısa ve en uzun vade (yıl).
  static const int minTermYears = 1;
  static const int maxTermYears = 3;

  /// prototypeOnly: konut kredisinde en uzun vade (yıl) — D-108.
  ///
  /// Türkiye'de konut kredisi vadeleri 120 aya kadar çıkabiliyor; oyun
  /// on yılda tutar.
  static const int maxHousingTermYears = 10;

  /// Verilen amaca göre en uzun vade.
  static int maxTermFor(LoanPurpose purpose) =>
      purpose == LoanPurpose.konut ? maxHousingTermYears : maxTermYears;

  /// prototypeOnly: konut kredisinin en küçük tutarı.
  ///
  /// Konut kredisi ihtiyaç kredisi gibi küçük tutarlar için açılmaz.
  static int get minHousingAmount => Economy.netYearlyMinimumWage * 2;

  /// Verilen amaca göre en küçük tutar.
  static int minAmountFor(LoanPurpose purpose) =>
      purpose == LoanPurpose.konut ? minHousingAmount : minAmount;

  /// prototypeOnly: konut kredisinde taksite ayrılabilen gelir payı.
  ///
  /// Ev teminat olduğu için banka daha cömert davranır.
  static const double prototypeOnlyHousingPaymentShare = 0.60;

  /// Amaca göre taksit payı tavanı.
  static double paymentShareFor(LoanPurpose purpose) =>
      purpose == LoanPurpose.konut
          ? prototypeOnlyHousingPaymentShare
          : prototypeOnlyMaxPaymentShare;

  /// prototypeOnly: "orta" kademeye geçilen taksit yükü oranı.
  static const double prototypeOnlyModerateBurden = 0.25;

  /// prototypeOnly: "riskli" kademeye geçilen taksit yükü oranı.
  static const double prototypeOnlyRiskyBurden = 0.45;

  /// Oyuncunun kredi durumu (D-108).
  ///
  /// Uydurma bir puan değil: **kaçan taksit sayısı** ile **taksit
  /// yükünün gelire oranı** okunur. Hiç kredisi olmayan oyuncu iyidir.
  static CreditStanding standingOf(GameState state) {
    final int kacan = missedPayments(state);
    if (kacan >= 2) return CreditStanding.cokRiskli;
    if (kacan == 1) return CreditStanding.riskli;

    final int gelir = assessedIncome(state);
    final int yuk = annualBurden(state);
    if (yuk <= 0) return CreditStanding.iyi;
    if (gelir <= 0) return CreditStanding.riskli;

    final double oran = yuk / gelir;
    if (oran >= prototypeOnlyRiskyBurden) return CreditStanding.riskli;
    if (oran >= prototypeOnlyModerateBurden) return CreditStanding.orta;
    return CreditStanding.iyi;
  }

  /// prototypeOnly: kredi çekilebilecek en küçük yaş.
  static const int prototypeOnlyMinAge = 18;

  /// prototypeOnly: aynı anda açık olabilecek kredi sayısı.
  static const int prototypeOnlyMaxActiveLoans = 2;

  /// prototypeOnly: en küçük kredi tutarı.
  ///
  /// Net aylık asgari ücretin yarısı: bunun altındaki tutar için banka
  /// dosya açmaz.
  static int get minAmount => Economy.netMonthlyMinimumWage ~/ 2;

  /// prototypeOnly: yıllık taksitin gelire oranı üst sınırı.
  ///
  /// Gelirin bu kadarından fazlasını taksite ayıran başvuru onaylanmaz;
  /// banka da oyuncuyu geri ödeyemeyeceği bir borcun altına sokmaz.
  static const double prototypeOnlyMaxPaymentShare = 0.45;

  /// prototypeOnly: geliri olmayan başvurana tanınan taban.
  ///
  /// Geliri olmayan herkese ret vermek kapıyı tamamen kapatırdı; bunun
  /// yerine çok küçük bir tutar teklif edilir.
  static int get prototypeOnlyNoIncomeCeiling => Economy.netYearlyMinimumWage ~/ 4;

  /// prototypeOnly: kaçırılan her taksitin tavanı düşürme oranı.
  static const double prototypeOnlyMissPenalty = 0.25;

  /// Oyuncunun kredi değerlendirmesinde kullanılan yıllık geliri.
  ///
  /// Maaş, emekli aylığı ve kira geliri sayılır; piyango ya da miras
  /// gibi tek seferlik şeyler **sayılmaz** — banka da saymaz.
  static int assessedIncome(GameState state) {
    int gelir = 0;
    if (state.career.isEmployed) gelir += state.career.salary ?? 0;
    gelir += state.career.pension ?? 0;
    // Kendi işinin kârı da gelirdir (D-132). Banka **zarar eden işi**
    // gelir saymaz: eksi kâr gelire eklenmez, sıfır sayılır.
    final int isKari = BusinessEngine.yearlyBusinessIncome(state);
    if (isKari > 0) gelir += isKari;
    return gelir;
  }

  /// Şu an açık olan krediler.
  static List<Loan> activeLoans(GameState state) =>
      state.loans.where((Loan l) => !l.isClosed).toList(growable: false);

  /// Yıllık taksit yükünün toplamı.
  static int annualBurden(GameState state) => activeLoans(state)
      .fold(0, (int t, Loan l) => t + l.annualPayment);

  /// Toplam kalan borç.
  static int totalDebt(GameState state) =>
      activeLoans(state).fold(0, (int t, Loan l) => t + l.outstanding);

  /// Kaçırılmış taksit sayısı.
  static int missedPayments(GameState state) =>
      state.loans.fold(0, (int t, Loan l) => t + l.missedPayments);

  /// Verilen tutar ve vade için yıllık taksit.
  ///
  /// Eşit taksitli (anüite) hesap: her yıl aynı tutar ödenir.
  static int annualPaymentFor({
    required int amount,
    required int termYears,
    required Bank bank,
    LoanPurpose purpose = LoanPurpose.ihtiyac,
  }) {
    final double r = bank.yearlyRateFor(purpose);
    if (termYears <= 0) return amount;
    if (r <= 0) return (amount / termYears).ceil();
    double carpan = 1.0;
    for (int i = 0; i < termYears; i++) {
      carpan *= 1 + r;
    }
    // A = P * r * (1+r)^n / ((1+r)^n - 1)
    final double taksit = amount * r * carpan / (carpan - 1);
    return taksit.ceil();
  }

  /// Bu başvuru neden hiç değerlendirilemez? Engel yoksa `null`.
  static String? blockReason(
    GameState state, {
    required int amount,
    LoanPurpose purpose = LoanPurpose.ihtiyac,
  }) {
    if (state.player.age < prototypeOnlyMinAge) {
      return 'Kredi başvurusu için $prototypeOnlyMinAge yaşını doldurman '
          'gerekiyor.';
    }
    if (activeLoans(state).length >= prototypeOnlyMaxActiveLoans) {
      return 'Aynı anda en fazla $prototypeOnlyMaxActiveLoans kredin '
          'olabilir. Önce birini kapatman gerekiyor.';
    }
    if (amount < minAmountFor(purpose)) {
      return purpose == LoanPurpose.konut
          ? 'Konut kredisi en az ${minHousingAmount ~/ 1000} bin ₺ için '
              'açılıyor; daha küçük tutarda ihtiyaç kredisi kullanılır.'
          : 'Banka bu kadar küçük bir tutar için dosya açmıyor.';
    }
    return null;
  }

  /// Bankanın bu başvuruya vereceği karar.
  ///
  /// Karar **rastgele değildir**: aynı koşullarda aynı cevap gelir.
  /// Oyuncu aynı başvuruyu tekrar tekrar deneyerek "evet" çıkarana kadar
  /// zar atamaz; tutarı düşürmesi ya da durumunu düzeltmesi gerekir.
  static LoanDecision evaluate(
    GameState state, {
    required Bank bank,
    required int amount,
    required int termYears,
    LoanPurpose purpose = LoanPurpose.ihtiyac,
  }) {
    final String? engel =
        blockReason(state, amount: amount, purpose: purpose);
    if (engel != null) {
      return LoanDecision(approved: false, reason: engel);
    }

    final int gelir = assessedIncome(state);
    final int mevcutYuk = annualBurden(state);

    // Bankanın taksite ayırmaya razı olduğu yıllık pay. Konut kredisinde
    // ev teminat olduğu için pay daha yüksektir (D-108).
    final double pay = paymentShareFor(purpose) * bank.approvalEase;
    final int taksitTavani = gelir > 0
        ? (gelir * pay).round() - mevcutYuk
        : (prototypeOnlyNoIncomeCeiling * bank.approvalEase).round() -
            mevcutYuk;

    // Kaçırılmış taksitler tavanı düşürür.
    final int kacan = missedPayments(state);
    final double cezaCarpani =
        (1 - kacan * prototypeOnlyMissPenalty).clamp(0.0, 1.0);
    final int gercekTavan = (taksitTavani * cezaCarpani).round();

    if (gercekTavan <= 0) {
      return LoanDecision(
        approved: false,
        reason: kacan > 0
            ? '${bank.label} ödeme geçmişine baktı ve yeni kredi '
                'vermedi.'
            : gelir > 0
                ? '${bank.label} mevcut taksit yükünü fazla buldu.'
                : '${bank.label} düzenli bir gelirin olmadığı için '
                    'başvuruyu kabul etmedi.',
      );
    }

    final int istenenTaksit = annualPaymentFor(
      amount: amount,
      termYears: termYears,
      bank: bank,
      purpose: purpose,
    );

    if (istenenTaksit <= gercekTavan) {
      return LoanDecision(
        approved: true,
        reason: '${bank.label} krediyi onayladı.',
        offeredAmount: amount,
        annualPayment: istenenTaksit,
      );
    }

    // Kısmi onay: bankanın verebileceği en büyük tutar bulunur.
    final int teklif = _maxAmountFor(
      payment: gercekTavan,
      termYears: termYears,
      bank: bank,
      purpose: purpose,
    );
    if (teklif < minAmountFor(purpose)) {
      return LoanDecision(
        approved: false,
        reason: '${bank.label} bu tutarı geri ödeyemeyeceğini düşündü ve '
            'başvuruyu kabul etmedi.',
      );
    }

    return LoanDecision(
      approved: false,
      reason: '${bank.label} istediğin tutarı vermedi. Bu koşullarda en '
          'fazla ${teklif ~/ 1000} bin ₺ verebiliyor.',
      offeredAmount: teklif,
      annualPayment: annualPaymentFor(
        amount: teklif,
        termYears: termYears,
        bank: bank,
        purpose: purpose,
      ),
    );
  }

  /// Krediyi açar ve parayı cüzdana geçirir.
  ///
  /// Onaylanmamış başvuru **hiçbir şeyi değiştirmez**: para girmez,
  /// kayıt açılmaz.
  static ({GameState state, LoanDecision decision}) borrow(
    GameState state, {
    required Bank bank,
    required int amount,
    required int termYears,
    LoanPurpose purpose = LoanPurpose.ihtiyac,
  }) {
    final int vade = termYears.clamp(minTermYears, maxTermFor(purpose));
    final LoanDecision karar = evaluate(
      state,
      bank: bank,
      amount: amount,
      termYears: vade,
      purpose: purpose,
    );
    if (!karar.approved) return (state: state, decision: karar);

    final Loan kredi = Loan(
      id: 'kredi-${bank.name}-${state.player.age}-${state.loans.length}',
      bank: bank,
      purpose: purpose,
      principal: karar.offeredAmount,
      annualPayment: karar.annualPayment,
      termYears: vade,
      remainingPayments: vade,
      outstanding: karar.annualPayment * vade,
      takenAtAge: state.player.age,
    );

    return (
      state: state.copyWith(
        player: state.player.copyWith(
          wallet: state.player.wallet + karar.offeredAmount,
        ),
        loans: List<Loan>.unmodifiable(<Loan>[...state.loans, kredi]),
      ),
      decision: karar,
    );
  }

  /// Krediyi erken kapatır.
  ///
  /// Kalan borcun tamamı ödenir. Parası yetmiyorsa **hiçbir şey olmaz**.
  static ({GameState state, String message}) payOff(
    GameState state,
    String loanId,
  ) {
    final Loan? kredi = state.loans
        .where((Loan l) => l.id == loanId && !l.isClosed)
        .firstOrNull;
    if (kredi == null) {
      return (state: state, message: 'Böyle açık bir kredin yok.');
    }
    if (state.player.wallet < kredi.outstanding) {
      return (
        state: state,
        message: 'Kalan borcu kapatmaya cüzdanın yetmiyor.',
      );
    }
    return (
      state: state.copyWith(
        player: state.player.copyWith(
          wallet: state.player.wallet - kredi.outstanding,
        ),
        loans: List<Loan>.unmodifiable(
          state.loans.map((Loan l) => l.id == loanId
              ? l.copyWith(outstanding: 0, remainingPayments: 0)
              : l),
        ),
      ),
      message: '${kredi.bank.label} kredisini kapattın.',
    );
  }

  /// Bir yılın taksitlerini uygular.
  ///
  /// Ödenebilen taksit cüzdandan düşer. Ödenemeyen taksit **kaçar**:
  /// kalan borç bir yıllık faiziyle büyür ve kaçan taksit sayacı artar.
  /// Cüzdan **eksiye düşmez**.
  static ({GameState state, List<String> messages, List<String> missed})
      advanceYear(GameState state) {
    if (state.loans.isEmpty) {
      return (
        state: state,
        messages: const <String>[],
        missed: const <String>[],
      );
    }

    final List<String> satirlar = <String>[];
    // Kaçan taksitler ayrı tutulur: oyuncunun kaçırmaması gereken kritik
    // haberdir, yalnızca günlüğe yazılıp geçilmez (D-097).
    final List<String> kacanlar = <String>[];
    int cuzdan = state.player.wallet;
    final List<Loan> guncel = <Loan>[];

    for (final Loan l in state.loans) {
      if (l.isClosed) {
        guncel.add(l);
        continue;
      }
      if (cuzdan >= l.annualPayment) {
        cuzdan -= l.annualPayment;
        final int kalanBorc = (l.outstanding - l.annualPayment).clamp(0, 1 << 62);
        final int kalanTaksit = l.remainingPayments - 1;
        guncel.add(l.copyWith(
          outstanding: kalanBorc,
          remainingPayments: kalanTaksit,
        ));
        if (kalanTaksit <= 0 || kalanBorc <= 0) {
          satirlar.add('${l.bank.label} kredisinin son taksitini ödedin.');
        }
      } else {
        // Ödenmeyen taksit: borç bir yıllık faiziyle büyür.
        final int buyumus =
            (l.outstanding * (1 + l.bank.yearlyRate)).round();
        guncel.add(l.copyWith(
          outstanding: buyumus,
          missedPayments: l.missedPayments + 1,
        ));
        final String metin =
            '${l.bank.label} taksitini ödeyemedin; borç faiziyle büyüdü.';
        satirlar.add(metin);
        kacanlar.add(metin);
      }
    }

    return (
      state: state.copyWith(
        player: state.player.copyWith(wallet: cuzdan),
        loans: List<Loan>.unmodifiable(guncel),
      ),
      messages: List<String>.unmodifiable(satirlar),
      missed: List<String>.unmodifiable(kacanlar),
    );
  }

  /// Verilen taksitle çekilebilecek en büyük anapara.
  static int _maxAmountFor({
    required int payment,
    required int termYears,
    required Bank bank,
    LoanPurpose purpose = LoanPurpose.ihtiyac,
  }) {
    final double r = bank.yearlyRateFor(purpose);
    if (r <= 0) return payment * termYears;
    double carpan = 1.0;
    for (int i = 0; i < termYears; i++) {
      carpan *= 1 + r;
    }
    // P = A * ((1+r)^n - 1) / (r * (1+r)^n)
    final double anapara = payment * (carpan - 1) / (r * carpan);
    // Bin liraya yuvarlanır: banka da küsuratlı kredi vermez.
    return (anapara ~/ 1000) * 1000;
  }
}
