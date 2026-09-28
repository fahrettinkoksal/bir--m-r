/// Min-max yatırım stratejisi oyuncuları ve saldırgan oyuncu (Paket AC).
///
/// **Neden var.** §26 açık: *"'İnsan böyle oynamaz' deme. İnsan böyle
/// oynayabilir."* Bir strateji oyuncu tarafından uygulanabiliyorsa oyun
/// ekonomisi o stratejiye dayanmalı. Bu dosya PlayerBot'un "hayat yaşayan"
/// botundan **ayrıdır**: buradaki oyuncular tek bir şeyi en iyi yapmaya
/// çalışır ve hayatın geri kalanını umursamaz.
///
/// **Kurallar:**
/// * `debugSetState` ile para/stat/ilişki/ev/iş **verilmez**. Tek
///   istisna, ölçümün başlangıç koşulunu kurmak için yaş ve başlangıç
///   parası — o da her stratejide **aynı**, yani karşılaştırma adil.
/// * Bütün alım/satım `GameController`'ın gerçek public aksiyonlarından
///   geçer; işlem kapalıysa satış olmaz, komisyon ve kesinti ödenir.
/// * Yapay limit yok (§25): isteyen stratejiye parasının tamamını
///   yatırır.
///
/// Bu dosya **yalnızca test altyapısıdır**; ürün kodu değildir.
library;

import 'dart:math';

import 'package:bir_omur/data/business_catalog.dart';
import 'package:bir_omur/data/job_catalog.dart';
import 'package:bir_omur/data/license_catalog.dart';
import 'package:bir_omur/data/license_questions.dart';
import 'package:bir_omur/domain/models/pending_license_exam.dart';
import 'package:bir_omur/domain/economy/business_engine.dart';
import 'package:bir_omur/data/health_crisis_catalog.dart';
import 'package:bir_omur/data/investment_catalog.dart';
import 'package:bir_omur/data/item_catalog.dart';
import 'package:bir_omur/data/shop_catalog.dart';
import 'package:bir_omur/domain/economy/banking.dart';
import 'package:bir_omur/domain/economy/investment_engine.dart';
import 'package:bir_omur/domain/economy/living_costs.dart';
import 'package:bir_omur/domain/models/business.dart';
import 'package:bir_omur/domain/models/investment.dart';
import 'package:bir_omur/domain/economy/net_worth.dart';
import 'package:bir_omur/domain/interaction/divorce_settlement.dart';
import 'package:bir_omur/domain/interaction/item_actions.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/loan.dart';
import 'package:bir_omur/domain/models/market_incident.dart';
import 'package:bir_omur/domain/models/owned_item.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:bir_omur/state/game_controller.dart';

/// Ölçülen yatırım stratejileri (§26).
enum InvestStrategy {
  /// Her yıl yatırabileceği **en yüksek** tutarı yatırır.
  maksimum('her yil maksimum'),

  /// Tamamı hisse.
  tamHisse('%100 hisse'),

  /// Dört varlığa eşit dağıtılmış.
  dengeli('dengeli (4 varlik esit)'),

  /// Yalnızca vadeli hesap.
  sadeceVadeli('sadece vadeli'),

  /// Yalnızca altın.
  sadeceAltin('sadece altin'),

  /// Hiç yatırım yapmaz (kontrol grubu).
  yatirimYok('yatirim yok'),

  /// Ev + yatırım.
  evVeYatirim('ev + yatirim'),

  /// Girişim + yatırım.
  girisimVeYatirim('girisim + yatirim'),

  /// Yalnızca fon (Paket AD, §AD/6'nın istediği 10 stratejiden biri).
  sadeceFon('sadece fon'),

  /// **Pasif işletme sahibi** (Paket AE, §33/A).
  ///
  /// İşi açar ve bir daha dönüp bakmaz: fiyat koymaz, bakım yapmaz,
  /// personelle ilgilenmez, reklam vermez. "Otomatik kâr alan kişi"nin
  /// ne olduğunu ölçer.
  isletmePasif('isletme pasif'),

  /// **Aktif işletme sahibi** (Paket AE, §33/B).
  ///
  /// Fiyatı işletmenin hâline göre ayarlar, bakım yaptırır, kadroyu
  /// tamamlar, kampanya kurar ve işine bakar. Yatırım yapmaz: ölçülen
  /// şey işletme yönetiminin kendisi.
  isletmeAktif('isletme aktif'),

  /// **Mükemmel girişimci** (Paket AF, §1, §2).
  ///
  /// Oyunu ekonomik olarak **çözmeye çalışan** bot. İşletmeleri
  /// karşılaştırır, fiyatı geçmiş sonuçlardan öğrenerek optimize eder,
  /// reklamı ancak karşılığını gördüğünde verir, bakımı ekonomik
  /// optimumda yaptırır, kötü işletmeyi kapatıp daha iyisine geçer ve
  /// artan parayı yatırır. **Geleceği bilmez**; yalnızca oyuncunun
  /// ekranda görebileceği bilgiyi kullanır.
  mukemmelGirisimci('mukemmel girisimci'),

  /// **Maaşlı kariyer + yatırım** (Paket AF, §11/11).
  ///
  /// Diğer stratejilerde bot açık ilanlardan **rastgele** birine
  /// başvuruyor; bu strateji en yüksek maaşlıyı seçiyor ve her fırsatta
  /// zam istiyor. İşletme açmıyor.
  kariyerVeYatirim('kariyer + yatirim'),

  /// **Maaşlı kariyer + işletme + yatırım** (Paket AF, §11/12).
  ///
  /// Üçünü birden yapan oyuncu. §9'un sorusu bu: maaş da almak, dükkânı
  /// da kusursuz yönetmek bedava bir kombinasyon mu?
  kariyerIsletmeYatirim('kariyer + isletme + yatirim'),

  /// **Karma normal oyuncu.** Diğer dokuzu tek bir şeyi en iyi yapmaya
  /// çalışır; bu strateji "makul davranan insan"ı temsil eder: parasının
  /// bir kısmını yatırır, bir kısmını nakit tutar, dengesiz ama akıllıca
  /// olmayan bir dağılım yapar ve arada harcar. §AD/6 bunu ayrıca istedi
  /// çünkü hedef dağılım (§19) "normal oyuncu"ya göre yazıldı.
  karmaNormal('karma normal oyuncu');

  const InvestStrategy(this.label);

  final String label;
}

/// Bir strateji hayatının ölçümü.
class StrategyResult {
  StrategyResult({required this.strategy, required this.seed});

  final InvestStrategy strategy;
  final int seed;

  /// Ölçüm penceresi sonundaki net servet.
  int netWorth = 0;
  int portfolio = 0;
  int wallet = 0;
  int realEstate = 0;

  /// Araçların toplam değeri (₺) — §21.
  int vehicles = 0;

  /// İşletmelerin toplam değeri (₺) — §21.
  int business = 0;

  /// İşletmenin hayat boyu net sonucu (₺) — Paket AE, §33.
  int businessProfit = 0;

  /// İşletmenin açık kaldığı toplam yıl — Paket AE, §23 ölçümü.
  int businessYears = 0;

  /// Hiç işletme kuruldu mu?
  bool businessOpened = false;

  /// Bir işletme kapandı mı (devir ya da batış)?
  bool businessClosed = false;

  /// Bir işletme **battı** mı?
  bool businessBankrupt = false;

  /// Hayat boyu işletmeye konan sermaye (₺) — Paket AF, §12.
  int businessCapital = 0;

  /// Hayat boyu maaş geliri (₺) — Paket AF, §12.
  int salaryIncome = 0;

  /// Kaç ayrı işletme açıldı (geçiş zinciri uzunluğu) — §4.
  int businessCount = 0;

  /// Açılan işletmelerin kimlikleri, sırayla — §4 geçiş zinciri.
  final List<String> businessChain = <String>[];

  /// İşletmenin sermaye getirisi: toplam kâr / konan sermaye.
  double get businessRoi =>
      businessCapital <= 0 ? 0 : businessProfit / businessCapital;

  /// Lüks varlıkların (yazlık/tekne/koleksiyon) toplam değeri (₺) — §21.
  int luxury = 0;

  int debt = 0;

  /// Hayat boyu portföye konan anapara.
  int principal = 0;

  /// Ödenen komisyon + kazanç kesintisi (yaklaşık: satışlardan türer).
  int realizedProfit = 0;

  /// Zirveden en derin düşüş (0-1).
  double maxDrawdown = 0;

  /// Yıl yıl net servet (drawdown ve eğri için).
  final List<int> netWorthByYear = <int>[];

  /// **Zorunlu satış** yaşadı mı? (Geçim gideri portföyden karşılandı.)
  bool forcedSale = false;
  int forcedSaleYears = 0;

  /// İşlem kapalıyken satmak isteyip satamadığı yıl sayısı.
  int blockedSellYears = 0;

  /// Gördüğü olaylar.
  final Set<IncidentKind> incidents = <IncidentKind>{};
  int companyFailures = 0;
  bool fundLiquidated = false;

  /// Likidite krizi: cüzdan sıfır ve gider karşılanamadı.
  int hardshipYears = 0;

  bool endedByDeath = false;
  int endAge = 0;

  /// Başlangıç parasının altında mı bitti?
  ///
  /// **Bu ölçü strateji riskini göstermez** ve raporda öyle kullanılmaz.
  /// Sebebi: bu hayatlar 60 yıl boyunca maaş da alıyor, dolayısıyla son
  /// net servet 100k'lık başlangıcın çok üstünde oluyor ve "başlangıcın
  /// altında bitti" neredeyse hiç gerçekleşmiyor. İlk ölçümde bunu risk
  /// göstergesi sanıp "%100 hisse hiç kaybetmiyor" diye okumaya
  /// hazırdım; yanlış metrikti. Yatırımın kendi riski
  /// [investmentLostMoney] ile ölçülür.
  bool get belowStart => netWorth < kStrategyStartCash;

  /// **Yatırımın kendisi para kaybettirdi mi?**
  ///
  /// Portföye konan anapara ile elde kalan portföy + gerçekleşen kâr
  /// karşılaştırılır. Doğru risk ölçüsü budur: maaş geliri karışmaz.
  bool get investmentLostMoney =>
      principal > 0 && (portfolio + realizedProfit) < principal;

  /// Yatırımın anaparaya oranı (1,0 = başa baş).
  double get investmentMultiple =>
      principal <= 0 ? 0 : (portfolio + realizedProfit) / principal;

  /// **Ödeyemediği kredi yüzünden borcu kontrolsüz büyüdü mü?**
  ///
  /// Paket AC ölçümünde bulunan defekt: ödenmeyen taksitte borç her yıl
  /// faiziyle büyüyor, `remainingPayments` azalmıyor ve hiçbir tahsil /
  /// haciz / silme mekanizması yok. Uzun hayatlarda net servet eksi
  /// milyarlara gidiyor.
  bool get runawayDebt => debt > 100000000;
}

/// prototypeOnly: ölçümün başlangıç yaşı ve parası.
///
/// Her stratejide **aynı**: karşılaştırma bu yüzden adil. Bu tek
/// `debugSetState` kullanımı ölçüm penceresini kurmak içindir; hiçbir
/// stratejiye avantaj vermez.
const int kStrategyStartAge = 20;
const int kStrategyStartCash = 100000;

/// Bir stratejiyi [years] yıl boyunca oynar.
///
/// Oyuncu ölürse ölçüm o yaşta durur ve [StrategyResult.endedByDeath]
/// işaretlenir; ölüm anındaki servet raporlanır.
/// Ölçüm sırasında belirli bir işletme türünü zorlamak için (Paket AF, §3).
///
/// `null` ise bot kendi seçimini yapar. Ayarlandığında `_tryOpenBusiness`
/// ve çözücü yalnızca bu türü açar; 14 işletmeyi ayrı ayrı ölçmek için.
String? _forcedBusinessId;

StrategyResult playStrategy({
  required InvestStrategy strategy,
  required int seed,
  required int years,
  String? businessTypeId,
}) {
  _forcedBusinessId = businessTypeId;
  final GameController c = GameController(random: Random(seed));
  c.startNewLife(mode: StartMode.tamamenRastgele, seed: seed);
  final Random rng = Random(seed * 7907 + strategy.index * 6151 + 29);
  final StrategyResult sonuc = StrategyResult(strategy: strategy, seed: seed);

  // Ölçüm penceresi: aynı yaş, aynı para. Başka hiçbir şey verilmiyor.
  c.debugSetState(
    c.state!.copyWith(
      pendingEvent: null,
      notices: const <PendingNotice>[],
      player: c.state!.player.copyWith(
        age: kStrategyStartAge,
        wallet: kStrategyStartCash,
      ),
    ),
  );

  // **Çözücü hafızası her hayatta sıfırlanır (Paket AF, §5).**
  // Taşınsaydı bot önceki hayatlarda öğrendiği en iyi fiyatı bilirdi;
  // bu, oyuncunun sahip olamayacağı bir bilgi — yani gelecek bilgisi.
  _solverMemory.clear();

  int zirve = NetWorth.of(c.state!);
  int oncekiHardship = 0;

  for (int yil = 0; yil < years; yil++) {
    if (c.state!.deceased) break;
    _drainPending(c, rng);
    if (c.state!.deceased) break;

    _act(c, strategy, rng, sonuc);
    _drainPending(c, rng);
    if (c.state!.deceased) break;

    final int onceki = c.state!.player.age;
    c.ageUp();
    if (c.state!.player.age == onceki) {
      // İlerlemeyi engelleyen bir şey var; bekleyenleri boşalt ve dene.
      _drainPending(c, rng);
      c.ageUp();
      if (c.state!.player.age == onceki) break;
    }

    // ---- Ölçüm --------------------------------------------------------
    final GameState s = c.state!;
    // Maaş geliri yıl yıl birikir (Paket AF, §12).
    sonuc.salaryIncome += s.career.job?.yearlySalary ?? 0;
    final int servet = NetWorth.of(s);
    sonuc.netWorthByYear.add(servet);
    if (servet > zirve) zirve = servet;
    if (zirve > 0) {
      final double dusus = (zirve - servet) / zirve;
      if (dusus > sonuc.maxDrawdown) sonuc.maxDrawdown = dusus;
    }
    if (s.hardshipYears > oncekiHardship) {
      sonuc.hardshipYears++;
    }
    oncekiHardship = s.hardshipYears;
    for (final MarketIncident olay in s.market.incidents) {
      sonuc.incidents.add(olay.kind);
      if (olay.kind == IncidentKind.iflas) sonuc.companyFailures++;
      if (olay.kind == IncidentKind.fonTasfiye) sonuc.fundLiquidated = true;
    }
    // Zorunlu satış izi: günlükte "yatırımdan" geçen satır.
    if (s.log.any((dynamic e) => (e.text as String).contains('yatırımdan'))) {
      sonuc.forcedSale = true;
    }
  }

  final GameState son = c.state!;
  sonuc.endAge = son.player.age;
  sonuc.endedByDeath = son.deceased;
  sonuc.netWorth = NetWorth.of(son);
  sonuc.portfolio = son.portfolioValue;
  sonuc.wallet = son.player.wallet;
  sonuc.debt = NetWorth.debt(son);
  // Değer ölçüsü `NetWorth.itemsValue` ile **aynı yerden** gelir.
  sonuc.realEstate = son.items
      .where((OwnedItem i) =>
          itemTypeOrFallback(i.typeId).kind == ItemKind.konut)
      .fold<int>(0, (int t, OwnedItem i) => t + DivorceSettlement.valueOf(i));
  sonuc.vehicles = son.items
      .where((OwnedItem i) => LivingCosts.isMotorVehicle(i))
      .fold<int>(0, (int t, OwnedItem i) => t + DivorceSettlement.valueOf(i));
  sonuc.luxury = son.items
      .where((OwnedItem i) => <ItemKind>{
            ItemKind.yazlik,
            ItemKind.tekne,
            ItemKind.koleksiyon,
          }.contains(itemTypeOrFallback(i.typeId).kind))
      .fold<int>(0, (int t, OwnedItem i) => t + DivorceSettlement.valueOf(i));
  // İşletmenin "değeri" olarak yatırılan sermaye okunuyor: oyunda bir
  // işletme satış fiyatı yok, `NetWorth` de işletmeyi ayrıca saymıyor.
  // Bu satır §21'in bileşen dökümü için bilgi amaçlıdır.
  sonuc.business = son.businesses
      .fold<int>(0, (int t, Business b) => t + b.totalInvested);
  // Paket AE, §33: işletmenin **kendi** sonucu ayrı ölçülür.
  sonuc.businessProfit = son.businesses
      .fold<int>(0, (int t, Business b) => t + b.totalProfit);
  // Paket AF, §12: sermaye ve geçiş zinciri bütün stratejilerde **aynı
  // yerden** okunur; strateji içinde elle sayılmaz.
  sonuc.businessCapital = son.businesses
      .fold<int>(0, (int t, Business b) => t + b.totalInvested);
  sonuc.businessCount = son.businesses.length;
  sonuc.businessChain
    ..clear()
    ..addAll(son.businesses.map((Business b) => b.typeId));
  sonuc.businessYears = son.businesses.fold<int>(
    0,
    (int t, Business b) => t + b.yearsOpen(son.player.age),
  );
  sonuc.businessOpened = son.businesses.isNotEmpty;
  sonuc.businessClosed =
      son.businesses.any((Business b) => !b.isOpen);
  sonuc.businessBankrupt = son.businesses
      .any((Business b) => b.endReason == BusinessEndReason.batti);
  sonuc.principal = son.portfolioInvested;
  sonuc.realizedProfit = son.portfolioRealized;
  // `companyFailures` yıl yıl toplandığı için birikmiş sayıyı düzelt:
  // kayıt kümülatif, en son okunan değer doğrudur.
  sonuc.companyFailures = son.market.incidents
      .where((MarketIncident x) => x.kind == IncidentKind.iflas)
      .length;
  c.dispose();
  return sonuc;
}

/// Bekleyen pencereleri kapatır.
void _drainPending(GameController c, Random rng) {
  for (int guard = 0; guard < 60; guard++) {
    final GameState s = c.state!;
    if (s.deceased) return;
    if (s.hasNotice) {
      c.dismissNotice();
      continue;
    }
    if (s.pendingEvent != null) {
      // **`choices.first` kullanılmıyor**: rastgele geçerli seçenek.
      final List<EventChoice> secenekler = s.pendingEvent!.choices;
      c.chooseEventOption(secenekler[rng.nextInt(secenekler.length)].id);
      continue;
    }
    if (s.pendingCrisis != null) {
      final HealthCrisis? katalog = healthCrisisById(s.pendingCrisis!.crisisId);
      final List<CrisisChoice> acik = katalog == null
          ? const <CrisisChoice>[]
          : katalog.choices
              .where((CrisisChoice ch) => c.canChooseCrisis(ch))
              .toList(growable: false);
      if (acik.isEmpty) return;
      c.respondToCrisis(acik[rng.nextInt(acik.length)].id);
      continue;
    }
    if (s.pendingWedding != null) {
      c.holdWedding('nikah');
      continue;
    }
    if (s.pendingInterview != null) {
      c.answerInterview(rng.nextInt(2));
      continue;
    }
    if (c.needsTrackChoice) {
      final List<dynamic> alan = c.availableTracks();
      if (alan.isEmpty) return;
      c.chooseTrack((alan[rng.nextInt(alan.length)] as dynamic).track);
      continue;
    }
    if (c.needsAfterSchoolChoice) {
      c.skipUniversity();
      continue;
    }
    return;
  }
}

/// Stratejinin o yıldaki hamlesi.
void _act(
  GameController c,
  InvestStrategy strategy,
  Random rng,
  StrategyResult sonuc,
) {
  final GameState s = c.state!;
  if (s.player.age < kInvestmentMinAge) return;

  // Çalışmak ortak: gelir olmadan hiçbir strateji ölçülemez. Aynı kural
  // bütün stratejilerde geçerli, o yüzden karşılaştırmayı bozmuyor.
  if (!s.career.isEmployed) {
    final List<dynamic> acik = c.openJobs();
    if (acik.isNotEmpty) {
      final List<dynamic> uygun = acik
          .where((dynamic j) => c.jobApplicationAvailability(j).isAllowed)
          .toList(growable: false);
      if (uygun.isNotEmpty) {
        c.applyForJob(uygun[rng.nextInt(uygun.length)]);
      }
    }
  } else if (c.raiseAvailability().isAllowed && rng.nextDouble() < 0.5) {
    c.askForRaise();
  }

  switch (strategy) {
    case InvestStrategy.yatirimYok:
      return;

    case InvestStrategy.maksimum:
      // **Yatırabileceği her kuruşu yatırır.** Yapay limit yok (§25).
      _buyAll(c, <String>['hisse', 'fon', 'altin', 'doviz'], rng, sonuc);

    case InvestStrategy.tamHisse:
      _buyAll(c, <String>['hisse'], rng, sonuc);

    case InvestStrategy.dengeli:
      _buyBalanced(c, sonuc);

    case InvestStrategy.sadeceVadeli:
      _buyAll(c, <String>['vadeli'], rng, sonuc);

    case InvestStrategy.sadeceAltin:
      _buyAll(c, <String>['altin'], rng, sonuc);

    case InvestStrategy.evVeYatirim:
      _tryBuyHome(c, rng);
      _buyAll(c, <String>['hisse', 'fon'], rng, sonuc);

    case InvestStrategy.girisimVeYatirim:
      _tryOpenBusiness(c, rng);
      _manageBusiness(c);
      _buyAll(c, <String>['hisse', 'fon'], rng, sonuc);

    case InvestStrategy.isletmePasif:
      _tryOpenBusiness(c, rng, tend: false);

    case InvestStrategy.isletmeAktif:
      _tryOpenBusiness(c, rng);
      _manageBusiness(c);

    case InvestStrategy.sadeceFon:
      _buyAll(c, <String>['fon'], rng, sonuc);

    case InvestStrategy.mukemmelGirisimci:
      _actSolver(c, rng, sonuc);

    case InvestStrategy.kariyerVeYatirim:
      _applyBestJob(c);
      _buyAll(c, <String>['hisse', 'fon'], rng, sonuc);

    case InvestStrategy.kariyerIsletmeYatirim:
      _applyBestJob(c);
      _tryOpenBusiness(c, rng);
      _manageBusiness(c);
      _buyAll(c, <String>['hisse', 'fon'], rng, sonuc);

    case InvestStrategy.karmaNormal:
      _actNormalPlayer(c, rng, sonuc);
  }
}

/// **Karma normal oyuncu** (Paket AD, §AD/6).
///
/// Min-max değil: parasının **bir kısmını** yatırır, gerisini cüzdanda
/// tutar; dağılımı kabaca güvenli tarafa yatkın; ev almayı dener; arada
/// nakit harcar. Bot zayıflatılmıyor — bu **ayrı bir strateji**, diğer
/// dokuzu olduğu gibi duruyor (§19'un "min-max bot ayrı kalsın" kuralı).
void _actNormalPlayer(GameController c, Random rng, StrategyResult sonuc) {
  // Her yıl yatırmıyor: normal insan bazı yıllar atlar.
  if (rng.nextDouble() < 0.35) return;
  final int cuzdan = c.state!.player.wallet;
  if (cuzdan < kInvestmentMinBuy * 3) return;
  // Parasının yarısını nakit tutuyor.
  final int yatirilacak = cuzdan ~/ 2;
  if (yatirilacak < kInvestmentMinBuy) return;
  // Güvenliye yatkın dağılım: vadeli/altın daha olası.
  final List<String> havuz = <String>[
    'vadeli',
    'vadeli',
    'altin',
    'altin',
    'fon',
    'hisse',
  ];
  final String tur = havuz[rng.nextInt(havuz.length)];
  final InvestmentType? tip = investmentTypeById(tur);
  if (tip == null) return;
  final int enAz = tip.isTermDeposit ? kTermDepositMinAmount : kInvestmentMinBuy;
  if (yatirilacak < enAz) return;
  if (c.investmentBuyBlockReason(tip, yatirilacak).isNotEmpty) return;
  final InvestmentOutcome? r = c.buyInvestment(tur, yatirilacak);
  if (r?.applied ?? false) sonuc.principal += yatirilacak;
  // Otuz beşinden sonra ev almayı dener.
  if (c.state!.player.age >= 35) _tryBuyHome(c, rng);
}

/// Cüzdanda ne varsa (bir yıllık gideri bırakarak) yatırır.
void _buyAll(
  GameController c,
  List<String> types,
  Random rng,
  StrategyResult sonuc,
) {
  // Bir yıllık gideri bırakmak zorunlu değil ama bırakmayan strateji
  // her yıl zorunlu satışa düşer ve ölçüm yalnızca onu görür. Rezerv
  // bütün stratejilerde aynı.
  final int rezerv = 0;
  final int serbest = c.state!.player.wallet - rezerv;
  if (serbest < kInvestmentMinBuy) return;
  final String tur = types[rng.nextInt(types.length)];
  final InvestmentType? tip = investmentTypeById(tur);
  if (tip == null) return;
  // Komisyon payını bırak.
  int tutar = (serbest / (1 + InvestmentEngine.prototypeOnlyTradeCommission))
      .floor();
  if (tip.isTermDeposit && tutar < kTermDepositMinAmount) return;
  if (tutar < kInvestmentMinBuy) return;
  while (tutar >= kInvestmentMinBuy) {
    if (c.investmentBuyBlockReason(tip, tutar).isEmpty) {
      final InvestmentOutcome? r = c.buyInvestment(tur, tutar);
      if (r?.applied ?? false) sonuc.principal += tutar;
      return;
    }
    // Engel işlem durmasıysa bir daha denemenin anlamı yok.
    if (c.state!.market.haltFor(tur, c.state!.player.age) != null) {
      sonuc.blockedSellYears++;
      return;
    }
    tutar = (tutar * 0.9).floor();
  }
}

/// Dört varlığa eşit dağıtır (§24).
void _buyBalanced(GameController c, StrategyResult sonuc) {
  const List<String> sepet = <String>['vadeli', 'altin', 'fon', 'hisse'];
  final int serbest = c.state!.player.wallet;
  if (serbest < kTermDepositMinAmount * 4) return;
  final int pay = serbest ~/ 4;
  for (final String tur in sepet) {
    final InvestmentType? tip = investmentTypeById(tur);
    if (tip == null) continue;
    final int enAz =
        tip.isTermDeposit ? kTermDepositMinAmount : kInvestmentMinBuy;
    if (pay < enAz) continue;
    if (c.investmentBuyBlockReason(tip, pay).isNotEmpty) continue;
    final InvestmentOutcome? r = c.buyInvestment(tur, pay);
    if (r?.applied ?? false) sonuc.principal += pay;
  }
}

void _tryBuyHome(GameController c, Random rng) {
  if (c.state!.properties.isNotEmpty) return;
  if (c.state!.player.age < 25) return;
  final List<ShopProduct> evler = shopProductsFor(c.state!.player.age)
      .where((ShopProduct p) =>
          itemTypeOrFallback(p.typeId).kind == ItemKind.konut)
      .toList(growable: true)
    ..sort((ShopProduct a, ShopProduct b) => a.price.compareTo(b.price));
  if (evler.isEmpty) return;
  final ShopProduct hedef = evler.first;
  if (c.state!.player.wallet < hedef.price && c.state!.loans.isEmpty) {
    c.applyForLoan(
      bank: Bank.bankavrupa,
      amount: hedef.price - c.state!.player.wallet,
      termYears: Banking.maxTermFor(LoanPurpose.konut),
      purpose: LoanPurpose.konut,
    );
  }
  if (c.state!.player.wallet < hedef.price) return;
  final ItemOutcome? r =
      c.buyProduct(hedef, location: c.state!.player.currentCity);
  if ((r?.applied ?? false) && c.state!.properties.isNotEmpty) {
    final OwnedItem yeni = c.state!.properties.last;
    if (c.moveBlockReason(yeni).isEmpty) c.moveInto(yeni);
  }
}

/// Ölçülen işletme ehliyet istiyorsa botun ehliyeti almasını sağlar.
///
/// **Ölçüm boşluğuydu (Q-176/6).** AF'de nakliyecilik hiç açılmadı,
/// çünkü ehliyet istiyor ve strateji botu ehliyet almıyordu; tablo o
/// işletmeyi boş gösteriyordu. Bu bir oyun hatası değil, tezgâhın
/// eksiğiydi. Bot artık gerçek oyuncu yolundan (başvur → sınav) ehliyet
/// alıyor; debug ile ehliyet **verilmiyor**.
void _ensureLicensesFor(GameController c, BusinessType tur) {
  for (final String id in tur.requiredLicenses) {
    final LicenseType? tip = licenseTypeById(id);
    if (tip == null || c.hasLicense(tip)) continue;
    if (!c.licenseAvailability(tip).isAllowed) continue;
    c.applyForLicense(tip);
    // Sınav tek oturuşta bitirilir: yıllara yayılırsa bekleyen olaylar
    // cevabı düşürüyor (AD/6'da ölçülmüştü).
    //
    // **Soruyu okuyup cevaplıyor.** Sürekli ilk şıkkı işaretlemek 3
    // soruda 2 doğru barajını geçmiyordu ve nakliyecilik hiç
    // ölçülemiyordu. Trafik sorularını bilen bir oyuncunun yapacağı şey
    // bu; `debugSetState` ile ehliyet **verilmiyor**, sınav gerçekten
    // veriliyor.
    for (int guard = 0; guard < 12; guard++) {
      final PendingLicenseExam? sinav = c.pendingLicenseExam;
      final LicenseQuestion? soru = sinav?.currentQuestion;
      if (sinav == null || soru == null) break;
      c.answerLicenseExam(soru.correctIndex);
      while (c.state!.hasNotice) {
        c.dismissNotice();
      }
      if (c.state!.hasPendingEvent) break;
    }
  }
}

void _tryOpenBusiness(GameController c, Random rng, {bool tend = true}) {
  if (c.state!.businesses.any((Business b) => b.isOpen)) {
    // Pasif sahip işine **hiç** bakmaz: §33/A'nın ölçtüğü şey bu.
    if (tend && c.businessTendAvailability().isAllowed) c.tendBusiness();
    return;
  }
  if (c.state!.businesses.isNotEmpty) return;
  if (c.state!.player.age < 24) return;
  if (_forcedBusinessId != null) {
    final BusinessType? hedef = businessTypeById(_forcedBusinessId!);
    if (hedef != null) _ensureLicensesFor(c, hedef);
  }
  final List<BusinessType> uygun = kBusinessCatalog
      .where((BusinessType t) =>
          (_forcedBusinessId == null || t.id == _forcedBusinessId) &&
          c.businessOpenAvailability(t).isAllowed)
      .toList(growable: false);
  if (uygun.isEmpty) return;
  c.openBusinessOf(uygun[rng.nextInt(uygun.length)]);
}

/// **Aktif işletme yönetimi** (Paket AE, §33/B, §33/C).
///
/// Bot burada **zayıflatılmıyor, akıllandırılıyor**: sistemi anlayan bir
/// oyuncunun yapacağını yapar — fiyatı işletmenin hâline göre koyar,
/// bakımı geciktirmez, kadroyu tamamlar, kampanya kurar. §33'ün sorusu
/// "iyi yöneten ne kazanır?" olduğuna göre ölçüm iyi yönetimle yapılmalı.
///
/// Min-max ilkesi (kullanıcının "EN ÖNEMLİ KURAL"ı): ekonomi, botu
/// aptallaştırarak değil, akıllı oyuncuya dayanarak düzeltilir.
void _manageBusiness(GameController c) {
  final Business? is_ = c.openBusiness;
  if (is_ == null) return;
  final BusinessType? tur = is_.type;
  if (tur == null) return;

  // 1) Fiyat: adı iyi olan dükkân pahalıyı taşır, adı kötü olan taşımaz.
  //    Esneklik zaten itibara göre kayıyor; bot bunu okuyup karşılık
  //    veriyor.
  final int ortalama = c.businessMarketPrice();
  if (ortalama > 0) {
    final double oran = is_.reputation >= 65
        ? 1.15
        : is_.reputation <= 35
            ? 0.88
            : 1.0;
    final int hedef = (ortalama * oran).round();
    if ((hedef - c.businessPrice()).abs() > ortalama * 0.05) {
      c.setBusinessPrice(hedef);
    }
  }

  // 2) Bakım: yıpranmayı biriktirmek pahalıya patlıyor (bedel eksikle
  //    birlikte artıyor), o yüzden erken davran.
  if (is_.upkeep < 72 && c.businessMaintenanceAvailability().isAllowed) {
    c.maintainBusiness();
  }

  // 3) Personel: önce eksik kadro, sonra huzursuzluk, sonra ilgi.
  if (c.businessStaffAvailability(StaffAction.iseAl).isAllowed) {
    c.businessStaff(StaffAction.iseAl);
  } else if (is_.staffMorale < 45 &&
      c.businessStaffAvailability(StaffAction.zam).isAllowed) {
    c.businessStaff(StaffAction.zam);
  } else if (c.businessStaffAvailability(StaffAction.ilgilen).isAllowed) {
    c.businessStaff(StaffAction.ilgilen);
  }

  // 4) Reklam: kampanya bittiğinde yenisini kur. Min-max oyuncu en
  //    pahalısını seçer; §35 bunun garanti para olmadığını denetliyor.
  if (is_.ad == BusinessAd.yok) {
    c.setBusinessAd(BusinessAd.buyuk);
  }
}

// =====================================================================
// Paket AF — mükemmel girişimci (§1, §2, §5-§8)
// =====================================================================

/// prototypeOnly: botun denediği fiyat oranları (bölge ortalamasına göre).
///
/// Oyuncunun ekranda seçebileceği bantla aynı aralıkta; bot bunların
/// arasından **deneyerek** en iyisini bulmaya çalışır.
const List<double> kSolverPriceRatios = <double>[0.80, 0.92, 1.0, 1.10, 1.25];

/// Bir işletme türü için botun **kendi** hafızası.
///
/// Oyuncunun görebileceğinden fazlasını tutmaz: hangi fiyat oranını
/// denediğinde o yılın neti ne çıktı. Gelecek bilgisi yok.
class _SolverMemory {
  final Map<int, List<int>> fiyatSonuclari = <int, List<int>>{};
  final List<int> reklamliYillar = <int>[];
  final List<int> reklamsizYillar = <int>[];
  int denenenFiyatIndeksi = 2;
  bool reklamDeniyor = false;

  /// O ana kadarki en iyi fiyat indeksi; hiç veri yoksa piyasa (2).
  int get enIyiFiyat {
    int enIyi = 2;
    double enIyiOrt = -double.infinity;
    for (final MapEntry<int, List<int>> e in fiyatSonuclari.entries) {
      if (e.value.isEmpty) continue;
      final double ort =
          e.value.reduce((int a, int b) => a + b) / e.value.length;
      if (ort > enIyiOrt) {
        enIyiOrt = ort;
        enIyi = e.key;
      }
    }
    return enIyi;
  }

  /// Reklam karşılığını veriyor mu? Yeterli veri yoksa "bilmiyorum".
  bool? get reklamKarliMi {
    if (reklamliYillar.length < 2 || reklamsizYillar.length < 2) return null;
    final double a = reklamliYillar.reduce((int x, int y) => x + y) /
        reklamliYillar.length;
    final double b = reklamsizYillar.reduce((int x, int y) => x + y) /
        reklamsizYillar.length;
    return a > b;
  }
}

/// Her hayatta sıfırlanan çözücü hafızası.
final Map<String, _SolverMemory> _solverMemory = <String, _SolverMemory>{};

/// prototypeOnly: botun bakım eşiği (§7).
///
/// **Ölçümle seçildi ve ilk tahminimi çürüttü.** Bakım bedeli yıpranmayla
/// birlikte büyüdüğü ama kazanç 34 puanda tavanlandığı için "puan başına
/// en ucuz nokta" kabaca 66 çıkıyor; eşiği oraya koymuştum. Süpürme
/// (`paket_af_business_roi_test.dart` §7) bunun yanlış olduğunu gösterdi:
/// 95 → ₺316,2M, 66 → ₺282,0M, 0 → ₺171,6M. Sebep şu: ekipman durumu
/// talebi **her yıl** besliyor, yani yüksek tutmanın getirisi puan başına
/// maliyet farkını aşıyor.
///
/// 95 pratikte "yapılabildiği her yıl bakım yaptır" demek
/// ([BusinessEngine.maintenanceAvailability] 96'nın üstünde kapanıyor).
/// Geciktirme exploiti **yok**; tersine, geciktirmek kaybettiriyor.
/// **Hayat düzeyinde ölçüldü (§5-§8).** İşletme tezgâhında en iyi eşik 95
/// çıkıyordu (her yıl bakım), ama tam hayatta bakıma giden para borsada
/// kazanacağı getiriden vazgeçmek demek. 18 politikanın süpürmesinde
/// 66/reklamsız/zamsız medyan ₺104,4M ile birinci; 95 → ₺74,1M.
int kSolverMaintenanceThreshold = 66;

/// Çözücünün reklam kademesi (§6).
///
/// **Ölçüm sonucu: optimal oyuncu reklam vermiyor.** Hayat düzeyinde
/// süpürmede reklamsız her bakım eşiğinde reklamlıyı geçti
/// (66: reklamsız ₺104,4M, mahalle ₺69,7M, büyük ₺85,6M). Sebep işletme
/// tezgâhında da görülüyordu: kampanyanın kazancı x1,04-x1,28 bandında,
/// aynı para borsada daha çok getiriyor.
BusinessAd kSolverAdTier = BusinessAd.yok;

/// prototypeOnly: çözücü zam yapsın mı (§8). Ölçümde değiştirilir.
bool kSolverUsesRaise = false;

/// En yüksek maaşlı açık işe başvurur (§11/11, §11/12).
void _applyBestJob(GameController c) {
  final GameState s = c.state!;
  if (s.career.isEmployed) {
    if (c.raiseAvailability().isAllowed) c.askForRaise();
    return;
  }
  final List<JobType> uygun = c
      .openJobs()
      .where((JobType j) => c.jobApplicationAvailability(j).isAllowed)
      .toList(growable: false);
  if (uygun.isEmpty) return;
  JobType enIyi = uygun.first;
  for (final JobType j in uygun) {
    if (j.yearlySalary > enIyi.yearlySalary) enIyi = j;
  }
  c.applyForJob(enIyi);
}

/// İşletmenin **beklenen** yıllık kârının sermayesine oranı.
///
/// Oyuncunun kurulum ekranında görebildiği iki sayıdan (sermaye ve "iyi
/// giderse yılda") hesaplanıyor; gizli alan kullanılmıyor.
double _visibleRoi(BusinessType t) =>
    t.setupCost <= 0 ? 0 : t.baseYearlyProfit / t.setupCost;

/// Bot bu yıl hangi işletmeyi açardı?
///
/// Karşılayabildikleri arasından görünür ROI'si en yüksek olanı seçer.
BusinessType? _pickBestBusiness(GameController c) {
  final List<BusinessType> uygun = kBusinessCatalog
      .where((BusinessType t) =>
          (_forcedBusinessId == null || t.id == _forcedBusinessId) &&
          c.businessOpenAvailability(t).isAllowed)
      .toList(growable: false);
  if (uygun.isEmpty) return null;
  BusinessType enIyi = uygun.first;
  for (final BusinessType t in uygun) {
    if (_visibleRoi(t) > _visibleRoi(enIyi)) enIyi = t;
  }
  return enIyi;
}

/// **Mükemmel girişimci** bir yılını oynar (§1, §2).
void _actSolver(GameController c, Random rng, StrategyResult sonuc) {
  _applyBestJob(c);

  final Business? acik = c.openBusiness;
  if (acik == null) {
    // İş yok: karşılayabildiği en iyi ROI'li işi aç.
    final BusinessType? hedef = _pickBestBusiness(c);
    if (hedef != null) {
      c.openBusinessOf(hedef);
    } else {
      // Sermaye yetmiyorsa yatırımdan çekip sermaye toplar (§1).
      _fundBusinessFromPortfolio(c);
    }
  } else {
    _manageSolverBusiness(c, acik, sonuc);
    _maybeSwitchBusiness(c, acik, sonuc);
  }

  // Artan parayı yatırır; işletme için rezerv bırakır (§10).
  _investSurplus(c, sonuc);
}

/// İşletme rezervi: bir yıllık sabit gideri kadar nakit tutulur.
///
/// §10 "bütün kârı anında yatırıma çekmek optimal mi?" diye soruyor.
/// Bot **rezerv bırakan** tarafı oynuyor; rezervsiz oynayan sürüm
/// `paket_af_meta_test.dart` içinde ayrıca ölçülüyor.
int _businessReserve(GameController c) {
  final Business? b = c.openBusiness;
  final BusinessType? t = b?.type;
  if (t == null) return 0;
  return (t.baseRevenue * (t.fixedShare + t.staffShare * 0.7)).round();
}

void _investSurplus(GameController c, StrategyResult sonuc) {
  final int rezerv = _businessReserve(c);
  final int serbest = c.state!.player.wallet - rezerv;
  if (serbest < kInvestmentMinBuy) return;
  // Risk/getiri dengesi: yarısı hisse, yarısı fon + altın.
  const List<String> sepet = <String>['hisse', 'fon', 'altin'];
  final int pay = serbest ~/ sepet.length;
  if (pay < kInvestmentMinBuy) return;
  for (final String tur in sepet) {
    final InvestmentType? tip = investmentTypeById(tur);
    if (tip == null) continue;
    if (c.investmentBuyBlockReason(tip, pay).isNotEmpty) continue;
    final InvestmentOutcome? r = c.buyInvestment(tur, pay);
    if (r?.applied ?? false) sonuc.principal += pay;
  }
}

/// Sermaye için portföyden nakit çeker (§1: "gerekirse yatırım satarak").
void _fundBusinessFromPortfolio(GameController c) {
  final List<BusinessType> hepsi = kBusinessCatalog
      .where((BusinessType t) =>
          c.businessOpenAvailability(t).reason?.contains('Sermaye') ?? false)
      .toList(growable: false);
  if (hepsi.isEmpty) return;
  // En ucuz kurulabilir işi hedefle.
  BusinessType hedef = hepsi.first;
  for (final BusinessType t in hepsi) {
    if (t.setupCost < hedef.setupCost) hedef = t;
  }
  final int eksik = hedef.setupCost - c.state!.player.wallet;
  if (eksik <= 0) return;
  for (final Holding h in c.state!.investments) {
    if (h.isEmpty) continue;
    final int satilacak = h.value < eksik ? h.value : eksik;
    if (satilacak < kInvestmentMinBuy) continue;
    c.sellInvestment(h.typeId, satilacak);
    if (c.state!.player.wallet >= hedef.setupCost) return;
  }
}

/// İşletmeyi çözücü mantığıyla yönetir (§5-§8).
void _manageSolverBusiness(
  GameController c,
  Business b,
  StrategyResult sonuc,
) {
  final BusinessType? tur = b.type;
  if (tur == null) return;
  final _SolverMemory hafiza =
      _solverMemory.putIfAbsent(tur.id, () => _SolverMemory());

  // --- Geçen yılın sonucunu hafızaya yaz (§5, §6) --------------------
  final BusinessYear? sonYil = b.lastYear;
  if (sonYil != null) {
    hafiza.fiyatSonuclari
        .putIfAbsent(hafiza.denenenFiyatIndeksi, () => <int>[])
        .add(sonYil.net);
    if (hafiza.reklamDeniyor) {
      hafiza.reklamliYillar.add(sonYil.net);
    } else {
      hafiza.reklamsizYillar.add(sonYil.net);
    }
  }

  // --- Fiyat: keşfet, sonra en iyisinde kal (§5) ---------------------
  // İlk yıllarda bütün oranları sırayla dener; sonra ölçtüğü en iyisine
  // yerleşir. Geleceği bilmiyor, yalnızca kendi geçmişine bakıyor.
  final int denenmemis = kSolverPriceRatios
      .asMap()
      .keys
      .firstWhere(
        (int i) => (hafiza.fiyatSonuclari[i]?.length ?? 0) < 2,
        orElse: () => -1,
      );
  hafiza.denenenFiyatIndeksi =
      denenmemis >= 0 ? denenmemis : hafiza.enIyiFiyat;
  final int ortalama = c.businessMarketPrice();
  if (ortalama > 0) {
    final int hedef =
        (ortalama * kSolverPriceRatios[hafiza.denenenFiyatIndeksi]).round();
    if (hedef != c.businessPrice()) c.setBusinessPrice(hedef);
  }

  // --- Reklam: ancak karşılığını gördüyse (§6) -----------------------
  final bool? karli = hafiza.reklamKarliMi;
  if (karli == null) {
    // Henüz bilmiyor: dönüşümlü dener ki karşılaştırabilsin.
    hafiza.reklamDeniyor = !hafiza.reklamDeniyor;
  } else {
    hafiza.reklamDeniyor = karli;
  }
  if (hafiza.reklamDeniyor && b.ad == BusinessAd.yok) {
    // **Ölçümle seçildi (§6).** Süpürmede kademe bazında kazanan sayısı
    // mahalle 7, sosyal medya 5, büyük 1, hiç 1 çıktı: en pahalı kampanya
    // 14 işletmenin yalnızca birinde en iyisi. Çözücü ölçülen en yaygın
    // kazananı oynuyor.
    c.setBusinessAd(kSolverAdTier);
  } else if (!hafiza.reklamDeniyor && b.ad != BusinessAd.yok) {
    c.setBusinessAd(BusinessAd.yok);
  }

  // --- Bakım: ekonomik optimumda (§7) --------------------------------
  if (b.upkeep <= kSolverMaintenanceThreshold &&
      c.businessMaintenanceAvailability().isAllowed) {
    c.maintainBusiness();
  }

  // --- Personel (§8) -------------------------------------------------
  // **Ölçümle seçildi (§8).** Politika süpürmesi: sürekli ilgi ₺319,2M,
  // sürekli zam ₺244,6M, hiçbir şey ₺242,0M. Zam kalıcı gider getirdiği
  // için memnuniyet kazancını yiyor; verimli hamle "kendin ilgilen".
  // Kadro eksiği yine de önce kapatılıyor: eksik kadro talebi düşürüyor.
  if (c.businessStaffAvailability(StaffAction.iseAl).isAllowed) {
    c.businessStaff(StaffAction.iseAl);
  } else if (kSolverUsesRaise &&
      b.staffMorale < 45 &&
      c.businessStaffAvailability(StaffAction.zam).isAllowed) {
    c.businessStaff(StaffAction.zam);
  } else if (c.businessStaffAvailability(StaffAction.ilgilen).isAllowed) {
    c.businessStaff(StaffAction.ilgilen);
  }

  if (c.businessTendAvailability().isAllowed) c.tendBusiness();
}

/// Daha iyi bir işletme açılabiliyorsa geçer (§4).
void _maybeSwitchBusiness(
  GameController c,
  Business b,
  StrategyResult sonuc,
) {
  final BusinessType? mevcut = b.type;
  if (mevcut == null) return;
  // Belirli bir tür ölçülüyorsa geçiş yapılmaz (§3 tek tür ölçüyor).
  if (_forcedBusinessId != null) return;
  // En az beş yıl çalıştırmadan karar vermez: bir iki kötü yıl kanıt değil.
  if (c.state!.player.age - b.startedAtAge < 5) return;

  // Devir bedelinden sonra eline geçecek parayla hangi işi açabilir?
  final int tahminiNakit =
      c.state!.player.wallet + (mevcut.salvageValue * 0.7).round();
  BusinessType? hedef;
  for (final BusinessType t in kBusinessCatalog) {
    if (t.id == mevcut.id) continue;
    if (t.setupCost > tahminiNakit) continue;
    if (c.state!.player.age < t.minAge) continue;
    if (_visibleRoi(t) <= _visibleRoi(mevcut) * 1.15) continue;
    if (hedef == null || _visibleRoi(t) > _visibleRoi(hedef)) hedef = t;
  }
  if (hedef == null) return;
  c.closeBusiness();
  c.openBusinessOf(hedef);
}
