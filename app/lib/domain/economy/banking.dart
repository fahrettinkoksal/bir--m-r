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
import '../../text/turkish_text.dart';
import '../interaction/divorce_settlement.dart';
import '../models/game_state.dart';
import '../models/owned_item.dart';
import 'business_engine.dart';
import 'investment_engine.dart';
import 'rental_engine.dart';
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

  // -------------------------------------------------------------------
  // Borç yaşam döngüsü (Paket AD, §8-§11) — hepsi prototypeOnly
  // -------------------------------------------------------------------
  //
  // **Bu bölüm bir bug düzeltmesi.** Öncesinde ödenmeyen taksit şunu
  // yapıyordu: borç her yıl faiziyle büyüyor, `remainingPayments` hiç
  // azalmıyor ve hiçbir tahsil/yapılandırma/kapanış yolu yok. Yani kredi
  // ölümsüzdü. Ölçtüm: ₺200.000 ihtiyaç kredisi, cüzdan sıfır, 60 yıl —
  // borç 20. yılda 9,7 milyar, 40. yılda 474 trilyon, 60. yılda
  // **9.223.372.036.854.775.807**, yani `int`in tepesine oturuyor. Bu bir
  // taşma; net servet istatistiklerini de anlamsız yapıyordu.
  //
  // Gerçek hukuk süreci taklit edilmiyor (§8 bunu açıkça yasakladı).
  // Oyunlaştırılmış beş durak: normal -> gecikme -> ciddi gecikme ->
  // yapılandırma / tahsil -> kapanış.

  /// prototypeOnly: kaçıncı üst üste kaçak taksitten sonra banka tahsile
  /// geçer (oyuncunun portföyüne ve oturmadığı malına uzanır).
  static const int prototypeOnlyCollectionAfterMissed = 2;

  /// prototypeOnly: kaçıncı üst üste kaçak taksitten sonra yapılandırma.
  static const int prototypeOnlyRestructureAfterMissed = 3;

  /// prototypeOnly: en fazla kaç kez yapılandırılabilir.
  ///
  /// Sınırlı olmak zorunda: sonsuz yapılandırma "hiç ödemem, her
  /// seferinde vade uzasın" exploitine dönerdi.
  static const int prototypeOnlyMaxRestructures = 2;

  /// prototypeOnly: yapılandırmada vadeye eklenen yıl.
  static const int prototypeOnlyRestructureExtraYears = 5;

  /// prototypeOnly: kaçıncı üst üste kaçaktan sonra borç zarar yazılıp
  /// kapatılır.
  ///
  /// Bu sayı **sonsuz kuyruğu kesen** şeydir (§10). Üst sınır böylece
  /// belirli: en kötü durumda
  /// `maxRestructures × restructureAfterMissed + writeOffAfterMissed`
  /// yıllık faiz büyümesi olabilir, daha fazlası olamaz.
  static const int prototypeOnlyWriteOffAfterMissed = 6;

  /// prototypeOnly: gecikme faizinin borcu şişirebileceği en büyük kat.
  ///
  /// Ölçümle geldi. Yalnızca "yapılandır, sonra kapat" zinciri kurduğumda
  /// borç artık sonsuza gitmiyordu ama **hâlâ saçmaydı**: 1000 borçlu
  /// hayatta görülen en büyük borç **₺180.502.538** çıktı. Sebebi basit —
  /// kapanışa kadar en fena yolda on iki yıl geçiyor ve yıllık %72 bileşik
  /// faiz on iki yılda ~1.200 kat ediyor.
  ///
  /// Bu yüzden gecikme faizi **anaparanın katı olarak** sınırlı: borç bu
  /// katı geçtikten sonra büyümeyi keser, süreç (yapılandırma, tahsil,
  /// kapanış) işlemeye devam eder. Çıpa `Loan.debtBase`: anapara değil,
  /// **baştan borçlanılan toplam tutar** — sebebi orada yazılı. Yapay bir "zenginden para sil" tavanı
  /// değil, gecikme faizine konan bir üst sınır — bu oyunun kendi kuralı.
  static const double prototypeOnlyMaxDebtMultiple = 2.0;

  /// prototypeOnly: zorla satılan malın değerinden kaybedilen pay.
  ///
  /// Aceleyle satmak pahalıdır; borç yüzünden mal satmak oyuncuya
  /// **maliyetli** olmalı, yoksa "malı sat, borcu kapat" bedava bir çıkış
  /// yolu olurdu.
  static const double prototypeOnlyForcedSaleDiscount = 0.25;

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
  /// prototypeOnly: kapanmış kredinin kredi notundaki izinin ömrü (yıl).
  ///
  /// §11 açık: "ömür boyu kredi yasağı yapma." Kapanan kredinin kaçan
  /// taksitleri kayıtta kalır (geçmiş silinmez) ama bu süre geçtikten
  /// sonra **yeni başvuruda sayılmaz**. Açık kredinin izi her zaman sayılır.
  static const int prototypeOnlyRecordYears = 10;

  /// Kredi notunda **şu an sayılan** kaçan taksit sayısı.
  ///
  /// Açık kredilerin hepsi, kapanmış kredilerin yalnızca son
  /// [prototypeOnlyRecordYears] yıl içinde kapananları sayılır.
  static int missedPayments(GameState state) {
    int toplam = 0;
    for (final Loan l in state.loans) {
      if (!l.isClosed) {
        toplam += l.missedPayments;
        continue;
      }
      final int? kapanis = l.closedAtAge;
      // Kapanış yaşı bilinmeyen eski kayıt: izini sayıyoruz, çünkü
      // bilmediğimiz için affetmek oyuncuyu kayıt sürümüne göre
      // ödüllendirirdi.
      if (kapanis == null ||
          state.player.age - kapanis < prototypeOnlyRecordYears) {
        toplam += l.missedPayments;
      }
    }
    return toplam;
  }

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
      // Gecikme faizi tavanının çıpası (§10).
      originalDebt: karar.annualPayment * vade,
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

  /// Bir yılın taksitlerini uygular ve borcun yaşam döngüsünü yürütür.
  ///
  /// Sıra (Paket AD, §8-§11):
  ///
  /// 1. Taksit cüzdandan çıkıyorsa öder, kaçak serisi sıfırlanır.
  /// 2. Çıkmıyorsa ve ödemeler bir süredir aksıyorsa banka **tahsile**
  ///    geçer: önce portföyden, sonra oturulmayan maldan (§9). Tek yılın
  ///    taksiti kadar tahsil eder, hepsini birden silmez.
  /// 3. Yine yetmiyorsa cüzdanda ne varsa borca sayılır (**kısmi ödeme**)
  ///    ve kalan borç kendi faiziyle büyür.
  /// 4. Aksama sürerse kredi **yapılandırılır**: vade uzar, taksit düşer.
  ///    Sınırlı sayıda.
  /// 5. Yapılandırma hakkı bittiyse borç **zarar yazılıp kapatılır** —
  ///    sonsuz kuyruk burada kesiliyor (§10).
  ///
  /// Cüzdan **eksiye düşmez**. Oturulan ev asla satılmaz.
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
    // Durum boyunca taşınıyor: tahsil portföye ve mala dokunduğu için
    // artık yalnızca bir `int cuzdan` yetmiyor.
    GameState s = state;
    final List<Loan> guncel = <Loan>[];

    for (final Loan l in state.loans) {
      if (l.isClosed) {
        guncel.add(l);
        continue;
      }

      // ---- 1. Cüzdandan ödeme --------------------------------------
      if (s.player.wallet >= l.annualPayment) {
        s = s.copyWith(
          player: s.player.copyWith(wallet: s.player.wallet - l.annualPayment),
        );
        guncel.add(_paid(l, satirlar));
        continue;
      }

      // ---- 2. Tahsil (§9) ------------------------------------------
      //
      // Bankanın malvarlığına uzanması için ödemelerin **bir süredir**
      // aksaması gerekiyor: ilk gecikmede kimse eve gelmez.
      if (l.missedStreak + 1 >= prototypeOnlyCollectionAfterMissed) {
        final int eksik = l.annualPayment - s.player.wallet;
        final ({GameState state, int raised, List<String> notes}) tahsil =
            _collect(state: s, loan: l, needed: eksik);
        s = tahsil.state;
        for (final String n in tahsil.notes) {
          satirlar.add(n);
          kacanlar.add(n);
        }
      }

      // Tahsil taksiti kurtardıysa ödeme yapılır.
      if (s.player.wallet >= l.annualPayment) {
        s = s.copyWith(
          player: s.player.copyWith(wallet: s.player.wallet - l.annualPayment),
        );
        guncel.add(_paid(l, satirlar));
        continue;
      }

      // ---- 3. Kısmi ödeme + gecikme --------------------------------
      //
      // **Eski davranış buradaki gerçek hatanın bir parçasıydı:** taksitin
      // %90'ı cüzdanda olsa bile hiç ödeme yapılmıyor, bütün borç
      // büyüyordu. Artık elde ne varsa borca sayılıyor.
      final int kismi = s.player.wallet > 0 ? s.player.wallet : 0;
      if (kismi > 0) {
        s = s.copyWith(player: s.player.copyWith(wallet: 0));
      }
      // Faiz **kredinin kendi oranıyla** işliyor. Eski kod `bank.yearlyRate`
      // kullanıyordu ve bu `purpose`'u yok sayıyordu: ödenmeyen bir konut
      // kredisi ihtiyaç kredisi oranıyla (%72 yerine %49 olması gerekirken)
      // büyüyordu. Ayrı bir hataydı, aynı satırda duruyordu.
      final double oran = l.bank.yearlyRateFor(l.purpose);
      final int kalanAnapara = (l.outstanding - kismi).clamp(0, 1 << 52);
      // Gecikme faizi anaparanın katıyla sınırlı (§10). Sınıra gelen borç
      // büyümeyi keser; süreç yapılandırma/tahsil/kapanış olarak devam eder.
      final int tavan = (l.debtBase * prototypeOnlyMaxDebtMultiple).round();
      final int faizli = (kalanAnapara * (1 + oran)).round();
      final int buyumus = faizli > tavan
          ? (kalanAnapara > tavan ? kalanAnapara : tavan)
          : faizli;
      Loan sonraki = l.copyWith(
        outstanding: buyumus,
        missedPayments: l.missedPayments + 1,
        missedStreak: l.missedStreak + 1,
      );
      final String gecikmeMetni = kismi > 0
          ? '${l.bank.label} taksitini tamamlayamadın; '
              '${trMoney(kismi)} yatırdın, kalan borç faiziyle büyüdü.'
          : '${l.bank.label} taksitini ödeyemedin; borç faiziyle büyüdü.';
      satirlar.add(gecikmeMetni);
      kacanlar.add(gecikmeMetni);

      // ---- 4. Yapılandırma (§8) ------------------------------------
      if (sonraki.missedStreak >= prototypeOnlyRestructureAfterMissed &&
          sonraki.restructures < prototypeOnlyMaxRestructures) {
        sonraki = _restructure(sonraki);
        final String metin = '${l.bank.label} borcu yapılandırdı: vade '
            'uzadı, yıllık taksit ${trMoney(sonraki.annualPayment)} oldu.';
        satirlar.add(metin);
        kacanlar.add(metin);
      } else if (sonraki.missedStreak >= prototypeOnlyWriteOffAfterMissed) {
        // ---- 5. Zarar yazarak kapatma (§10) ------------------------
        //
        // Sonsuz kuyruk burada kesiliyor. Bedavaya kurtulmak değil:
        // tahsil zaten portföyü ve malı almış olur, kredi notundaki iz de
        // on yıl kalır.
        sonraki = sonraki.copyWith(
          outstanding: 0,
          remainingPayments: 0,
          writtenOff: true,
          closedAtAge: s.player.age,
        );
        final String metin = '${l.bank.label} borcu takibe düştü ve '
            'kapatıldı. Ödeme geçmişinde izi kalıyor.';
        satirlar.add(metin);
        kacanlar.add(metin);
      }
      guncel.add(sonraki);
    }

    return (
      state: s.copyWith(loans: List<Loan>.unmodifiable(guncel)),
      messages: List<String>.unmodifiable(satirlar),
      missed: List<String>.unmodifiable(kacanlar),
    );
  }

  /// Taksiti ödenmiş krediyi ilerletir. Kaçak serisi sıfırlanır.
  static Loan _paid(Loan l, List<String> satirlar) {
    final int kalanBorc = (l.outstanding - l.annualPayment).clamp(0, 1 << 52);
    final int kalanTaksit = l.remainingPayments - 1;
    final bool kapandi = kalanTaksit <= 0 || kalanBorc <= 0;
    if (kapandi) {
      satirlar.add('${l.bank.label} kredisinin son taksitini ödedin.');
    }
    return l.copyWith(
      outstanding: kalanBorc,
      remainingPayments: kalanTaksit,
      missedStreak: 0,
    );
  }

  /// Krediyi yapılandırır: vade uzar, **taksit düşer**.
  ///
  /// Taksit `annualPaymentFor` ile hesaplanmıyor; bilerek. İlk kurulumda
  /// öyle yapmıştım ve ölçümde yapılandırma **rahatlatmak yerine
  /// hızlandırıyordu**: şişmiş borca yeniden yıllık %72 bileşik faiz
  /// bindiği için taksit ₺90.000'den önce ₺725.651'e, sonra ₺3.647.779'a
  /// çıkıyordu. Oyuncuya "yapılandırıldı" yazıp taksiti kırk katına
  /// çıkarmak yapılandırma değil.
  ///
  /// Doğrusu, oyuncunun bu kelimeden anladığı şey: **borç donar ve taksite
  /// bölünür.** Yapılandırılan tutara yeni faiz eklenmiyor; kalan borç yeni
  /// vadeye eşit bölünüyor. Ödenmezse borç yine büyümeye başlar, ama o
  /// zamana kadar yapılandırma hakkı tükenmiş olur ve kapanış gelir.
  static Loan _restructure(Loan l) {
    final int yeniVade = (l.remainingPayments > 0 ? l.remainingPayments : 1) +
        prototypeOnlyRestructureExtraYears;
    final int yeniTaksit = (l.outstanding / yeniVade).ceil();
    return l.copyWith(
      termYears: l.termYears + prototypeOnlyRestructureExtraYears,
      remainingPayments: yeniVade,
      annualPayment: yeniTaksit,
      restructures: l.restructures + 1,
      // Seri sıfırlanır: yapılandırma yeni bir başlangıçtır. Kredi
      // notundaki iz (`missedPayments`) silinmez.
      missedStreak: 0,
    );
  }

  /// Bankanın zorunlu tahsili (§9).
  ///
  /// Sıra: **likit yatırım -> oturulmayan mal.** Tek yılın taksiti kadar
  /// toplar; "tek seferde her şeyi yok etme" kuralı bu yüzden var.
  /// **Oturulan ev hiçbir koşulda satılmaz** — oyuncuyu evsiz bırakmak
  /// bu paketin işi değil ve §9 ayrıca dikkat edilmesini istedi.
  static ({GameState state, int raised, List<String> notes}) _collect({
    required GameState state,
    required Loan loan,
    required int needed,
  }) {
    if (needed <= 0) {
      return (state: state, raised: 0, notes: const <String>[]);
    }
    GameState s = state;
    final List<String> notlar = <String>[];
    final int basla = s.player.wallet;

    // a) Likit yatırım. AC'de gelen yardımcı aynen kullanılıyor: işlem
    //    durması, komisyon ve kazanç kesintisi orada zaten işliyor.
    final ({GameState state, int raised}) portfoy =
        InvestmentEngine.raiseCashForExpense(state: s, needed: needed);
    s = portfoy.state;
    if (portfoy.raised > 0) {
      notlar.add('${loan.bank.label} borcu için yatırımlarından '
          '${trMoney(portfoy.raised)} çözüldü.');
    }

    // b) Hâlâ eksikse mal satılır. Oturulan ev listeye hiç girmiyor.
    int kalan = needed - (s.player.wallet - basla);
    if (kalan > 0) {
      final List<OwnedItem> satilabilir = s.items
          .where((OwnedItem i) => i.id != s.residenceItemId)
          .where((OwnedItem i) => DivorceSettlement.valueOf(i) > 0)
          .toList(growable: true)
        // En küçüğünden başla: borcu kapatmak için villayı satmak yerine
        // yetiyorsa saati satmak oyuncunun hayatını daha az bozar.
        ..sort((OwnedItem a, OwnedItem b) => DivorceSettlement.valueOf(a)
            .compareTo(DivorceSettlement.valueOf(b)));

      for (final OwnedItem item in satilabilir) {
        if (kalan <= 0) break;
        final int deger = DivorceSettlement.valueOf(item);
        final int eleGecen =
            (deger * (1 - prototypeOnlyForcedSaleDiscount)).round();
        if (eleGecen <= 0) continue;
        // Kiracısı varsa sözleşme önce kapanır (D-163): yoksa elinde
        // olmayan evden kira gelmeye devam ederdi.
        if (s.leaseOf(item.id) != null) {
          final RentalResult kapanis = RentalEngine.endLease(
            state: s,
            propertyItemId: item.id,
            reasonText: '${item.name} borç yüzünden satıldı; kiracıyla '
                'sözleşme kapandı.',
          );
          if (kapanis.outcome.applied) s = kapanis.state;
        }
        s = s.removeItem(item.id).copyWith(
              player: s.player.copyWith(wallet: s.player.wallet + eleGecen),
            );
        notlar.add('${loan.bank.label} borcu yüzünden ${item.name} '
            'elden çıktı; ${trMoney(eleGecen)} borca gitti.');
        kalan = needed - (s.player.wallet - basla);
      }
    }

    return (
      state: s,
      raised: s.player.wallet - basla,
      notes: List<String>.unmodifiable(notlar),
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
