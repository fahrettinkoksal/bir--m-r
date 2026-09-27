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
import 'package:bir_omur/data/health_crisis_catalog.dart';
import 'package:bir_omur/data/investment_catalog.dart';
import 'package:bir_omur/data/item_catalog.dart';
import 'package:bir_omur/data/shop_catalog.dart';
import 'package:bir_omur/domain/economy/banking.dart';
import 'package:bir_omur/domain/economy/investment_engine.dart';
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
  girisimVeYatirim('girisim + yatirim');

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
StrategyResult playStrategy({
  required InvestStrategy strategy,
  required int seed,
  required int years,
}) {
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
      _buyAll(c, <String>['hisse', 'fon'], rng, sonuc);
  }
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

void _tryOpenBusiness(GameController c, Random rng) {
  if (c.state!.businesses.isNotEmpty) {
    if (c.businessTendAvailability().isAllowed) c.tendBusiness();
    return;
  }
  if (c.state!.player.age < 24) return;
  final List<BusinessType> uygun = kBusinessCatalog
      .where((BusinessType t) => c.businessOpenAvailability(t).isAllowed)
      .toList(growable: false);
  if (uygun.isEmpty) return;
  c.openBusinessOf(uygun[rng.nextInt(uygun.length)]);
}
