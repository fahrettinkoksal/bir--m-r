/// Kendi işi motoru (D-132).
///
/// **Maaş garantidir, kendi işi değildir.** Bu motorun tek işi bunu
/// hissettirmek: sermaye peşin gider, kâr işin durumuna bağlıdır, zarar
/// gerçekten cüzdandan çıkar ve ilgilenilmeyen iş batar.
///
/// Bütün sayılar `prototypeOnly`'dir (Q-146).
library;

import 'dart:math';

import '../../data/business_catalog.dart';
import '../../data/license_catalog.dart';
import 'business_incidents.dart';
import 'business_market.dart';
import '../../text/turkish_text.dart';
import '../models/business.dart';
import '../models/game_state.dart';
import '../models/interaction.dart';
import '../models/life_log.dart';
import '../models/pending_notice.dart';

/// Personelle ilgili oyuncu hamlesi (Paket AE, §7).
enum StaffAction {
  /// Zam yap: memnuniyet yükselir, personel gideri kalıcı olarak artar.
  zam,

  /// Yerine birini bul: eksik kadro tamamlanır, bulma bedeli çıkar.
  iseAl,

  /// Kendin daha fazla ilgilen: memnuniyet ve nitelik biraz toparlar.
  ilgilen,
}

/// Bir iş hamlesinin sonucu.
class BusinessOutcome {
  const BusinessOutcome({
    required this.applied,
    required this.text,
    this.money = 0,
  });

  final bool applied;
  final String text;

  /// Cüzdandaki değişim (eksi = ödeme).
  final int money;
}

class BusinessResult {
  const BusinessResult({required this.state, required this.outcome});

  final GameState state;
  final BusinessOutcome outcome;
}

abstract final class BusinessEngine {
  /// prototypeOnly: aynı anda açık tutulabilecek en fazla iş.
  ///
  /// Bir işi ayakta tutmak zor; ikisini birden tutmak bu sürümün konusu
  /// değil.
  static const int prototypeOnlyMaxOpenBusinesses = 1;

  /// prototypeOnly: işle ilgilenmenin durumu yükseltme payı.
  static const int prototypeOnlyTendGain = 12;

  /// prototypeOnly: çalışırken ilgilenmenin payı (zaman bölünüyor).
  static const int prototypeOnlyTendGainEmployed = 6;

  /// prototypeOnly: bir yaşta kaç kez ilgilenilebilir.
  static const int prototypeOnlyTendPerAge = 2;

  /// prototypeOnly: ilgilenilmeyen yılda durumun düşüşü.
  static const int prototypeOnlyNeglectDrop = 9;

  /// prototypeOnly: para yatırmanın her asgari ücret katı için payı.
  static const int prototypeOnlyInvestGainPerWage = 10;

  // ===================================================================
  // Sorgular
  // ===================================================================

  /// Şu an açık olan iş; yoksa `null`.
  static Business? openBusiness(GameState state) {
    for (final Business b in state.businesses) {
      if (b.isOpen) return b;
    }
    return null;
  }

  /// İşten gelen yıllık gelir (zarar eksi döner).
  ///
  /// Gelir hesaplarında maaşla aynı kefeye girer (D-033).
  ///
  /// **Paket AE:** yıl gerçekten kapandıysa **o yılın net sonucu**
  /// döner; tahmin değil, olan. Henüz bir yıl kapanmadıysa
  /// [expectedProfit] tahmini kullanılır — banka da kredi verirken ancak
  /// buna bakabilir.
  static int yearlyBusinessIncome(GameState state) {
    final Business? is_ = openBusiness(state);
    if (is_ == null) return 0;
    final BusinessYear? sonYil = is_.lastYear;
    if (sonYil != null) return sonYil.net;
    return expectedProfit(is_);
  }

  /// İşin durumuna göre **beklenen** yıllık kâr/zarar (tahmin).
  ///
  /// Gerçek sonuç yıl sonunda talep motorundan çıkar ([advanceYear]);
  /// bu yalnızca bir kestirimdir: işi yeni kurulmuş oyuncunun kredi
  /// başvurusunda ve ekrandaki beklenti satırında kullanılır.
  ///
  /// Durum 100'de tam kâr, 50'de kârın beşte biri, 25'in altında
  /// **zarar**. Üstüne itibar, bakım ve personel notu bir çarpan bindirir:
  /// aynı durumdaki iki dükkândan bakımlı ve adı iyi olanı daha çok
  /// bırakır. Çarpan işareti değiştirmez — zarar eden iş kâra geçmez.
  static int expectedProfit(Business business) {
    final BusinessType? tur = business.type;
    if (tur == null) return 0;
    final int d = business.condition;
    final double taban;
    if (d >= 50) {
      // 50 → %20, 100 → %100 arası doğrusal.
      taban = tur.baseYearlyProfit * (0.2 + (d - 50) / 50 * 0.8);
    } else {
      // 50 → %20 kâr, 25 → 0, 0 → tam kârın yarısı kadar zarar.
      taban = tur.baseYearlyProfit * ((d - 25) / 25 * 0.2);
    }
    // İtibar, bakım ve hizmet notu: 0,60 ile 1,40 arası bir çarpan.
    final double not = business.reputation * 0.42 +
        BusinessMarket.serviceScore(business, tur) * 0.58;
    final double carpan = (0.60 + not / 50 * 0.40).clamp(0.60, 1.40);
    return (taban * carpan).round();
  }

  // ===================================================================
  // 1) İş kurma
  // ===================================================================

  /// Bu iş şu an kurulabilir mi? Gerekçe boşsa kurulabilir (D-063).
  static InteractionAvailability openAvailability(
    GameState state,
    BusinessType tur,
  ) {
    if (state.isImprisoned) {
      return const InteractionAvailability.blocked(
        'Cezaevindeyken iş kurulmaz.',
      );
    }
    if (openBusiness(state) != null) {
      return const InteractionAvailability.blocked(
        'Zaten açık bir işin var. Bir işi ayakta tutmak yeterince zor.',
      );
    }
    if (state.education.isSchoolStudent) {
      return const InteractionAvailability.blocked(
        'Okula devam ederken iş kurulmaz.',
      );
    }
    if (state.player.age < tur.minAge) {
      return InteractionAvailability.blocked(
        '${tur.minAge} yaşından itibaren kurulabilir.',
      );
    }
    if (state.player.stats.intelligence < tur.minIntelligence) {
      return InteractionAvailability.blocked(
        'Bu iş için zekâ ${tur.minIntelligence} gerekiyor, '
        'şu an ${state.player.stats.intelligence}.',
      );
    }
    if (state.player.stats.charisma < tur.minCharisma) {
      return InteractionAvailability.blocked(
        'Bu iş müşteriyle yürür: karizma ${tur.minCharisma} gerekiyor, '
        'şu an ${state.player.stats.charisma}.',
      );
    }
    for (final String ehliyet in tur.requiredLicenses) {
      if (!state.hasLicense(ehliyet)) {
        final LicenseType? l = licenseTypeById(ehliyet);
        return InteractionAvailability.blocked(
          '${l?.label ?? 'Ehliyet'} gerekiyor.',
        );
      }
    }
    if (state.player.wallet < tur.setupCost) {
      return InteractionAvailability.blocked(
        'Sermaye ${trMoney(tur.setupCost)}; cüzdanında '
        '${trMoney(state.player.wallet)} var. Banka kredisi bir yol '
        'olabilir.',
      );
    }
    return const InteractionAvailability.allowed();
  }

  /// İşi kurar. Sermaye **peşin** gider.
  static BusinessResult open({
    required GameState state,
    required BusinessType tur,
  }) {
    final InteractionAvailability uygun = openAvailability(state, tur);
    if (!uygun.isAllowed) {
      return BusinessResult(
        state: state,
        outcome: BusinessOutcome(
          applied: false,
          text: uygun.reason ?? 'Şu an mümkün değil.',
        ),
      );
    }
    final int yas = state.player.age;
    final Business is_ = Business(
      id: 'is-${state.businesses.length + 1}',
      typeId: tur.id,
      startedAtAge: yas,
      totalInvested: tur.setupCost,
    );
    final String metin = '${tur.name} açtın. Sermaye '
        '${trMoney(tur.setupCost)} çıktı.\n\n'
        'İlk gün kimse gelmedi. İkinci gün üç kişi geldi.';
    GameState next = state.copyWith(
      player: state.player.copyWith(
        wallet: (state.player.wallet - tur.setupCost).clamp(0, 1 << 31),
      ),
      businesses: <Business>[...state.businesses, is_],
    );
    next = _log(next, '${tur.name} açtın.');
    next = next.queueNotice(
      PendingNotice(
        id: 'is-acildi-${is_.id}',
        kind: NoticeKind.kendiIsi,
        age: yas,
        title: 'İşini açtın',
        text: metin,
        money: -tur.setupCost,
      ),
    );
    return BusinessResult(
      state: next,
      outcome: BusinessOutcome(
        applied: true,
        text: metin,
        money: -tur.setupCost,
      ),
    );
  }

  // ===================================================================
  // 2) İşle ilgilenmek
  // ===================================================================

  /// Bu yıl işle ilgilenilebilir mi?
  static InteractionAvailability tendAvailability(GameState state) {
    final Business? is_ = openBusiness(state);
    if (is_ == null) {
      return const InteractionAvailability.blocked('Açık bir işin yok.');
    }
    if (state.isImprisoned) {
      return const InteractionAvailability.blocked(
        'Cezaevindesin; işine bakamıyorsun.',
      );
    }
    if (_tendedThisAge(state, is_) >= prototypeOnlyTendPerAge) {
      return const InteractionAvailability.blocked(
        'Bu yıl işine yeterince baktın; seneye yeniden açılır.',
      );
    }
    return const InteractionAvailability.allowed();
  }

  /// İşle ilgilenir: durumu yükseltir, seni yorar.
  static BusinessResult tend({required GameState state}) {
    final InteractionAvailability uygun = tendAvailability(state);
    if (!uygun.isAllowed) {
      return BusinessResult(
        state: state,
        outcome: BusinessOutcome(
          applied: false,
          text: uygun.reason ?? 'Şu an mümkün değil.',
        ),
      );
    }
    final Business is_ = openBusiness(state)!;
    // Maaşlı işte de çalışıyorsan zaman bölünüyor.
    final int pay = state.career.isEmployed
        ? prototypeOnlyTendGainEmployed
        : prototypeOnlyTendGain;
    final Business guncel = is_.copyWith(
      condition: (is_.condition + pay).clamp(0, 100),
      lastTendedAge: state.player.age,
    );
    final String metin = state.career.isEmployed
        ? 'İşten çıkıp dükkâna geçtin. Yapabildiğin kadarını yaptın.'
        : 'Bütün gün dükkândaydın. Akşam ayakların ağrıyordu ama '
            'kasa düne göre iyiydi.';
    GameState next = _replace(state, guncel).copyWith(
      player: state.player.copyWith(
        stats: state.player.stats.gain(health: -1, happiness: -1),
      ),
    );
    next = _countTend(_log(next, metin), is_);
    return BusinessResult(
      state: next,
      outcome: BusinessOutcome(applied: true, text: metin),
    );
  }

  // ===================================================================
  // 3) Para yatırmak
  // ===================================================================

  static InteractionAvailability investAvailability(
    GameState state,
    int tutar,
  ) {
    final Business? is_ = openBusiness(state);
    if (is_ == null) {
      return const InteractionAvailability.blocked('Açık bir işin yok.');
    }
    if (tutar <= 0) {
      return const InteractionAvailability.blocked('Tutar girilmedi.');
    }
    if (state.player.wallet < tutar) {
      return InteractionAvailability.blocked(
        'Cüzdanında ${trMoney(state.player.wallet)} var.',
      );
    }
    return const InteractionAvailability.allowed();
  }

  /// İşe para koyar. Para **gerçekten** çıkar, durum yükselir.
  static BusinessResult invest({
    required GameState state,
    required int tutar,
  }) {
    final InteractionAvailability uygun = investAvailability(state, tutar);
    if (!uygun.isAllowed) {
      return BusinessResult(
        state: state,
        outcome: BusinessOutcome(
          applied: false,
          text: uygun.reason ?? 'Şu an mümkün değil.',
        ),
      );
    }
    final Business is_ = openBusiness(state)!;
    // Asgari ücretin her yıllık katı için sabit bir pay; para tek başına
    // işi kurtarmaz ama yardım eder.
    final int pay = (tutar / 336906 * prototypeOnlyInvestGainPerWage)
        .round()
        .clamp(1, 35);
    final Business guncel = is_.copyWith(
      condition: (is_.condition + pay).clamp(0, 100),
      totalInvested: is_.totalInvested + tutar,
      // İşe konan para zarar sayacını bir yıl geri alır (§32): kötü
      // giden işi ayakta tutmanın yolu var ama bedava değil.
      lossStreak: (is_.lossStreak - 1).clamp(0, 1 << 30),
    );
    final String metin = 'İşe ${trMoney(tutar)} koydun. '
        '${is_.type?.name ?? 'Dükkân'} biraz toparlandı.';
    GameState next = _replace(state, guncel).copyWith(
      player: state.player.copyWith(
        wallet: (state.player.wallet - tutar).clamp(0, 1 << 31),
      ),
    );
    next = _log(next, metin);
    return BusinessResult(
      state: next,
      outcome: BusinessOutcome(applied: true, text: metin, money: -tutar),
    );
  }

  // ===================================================================
  // 4) İşi kapatmak
  // ===================================================================

  /// İşi devreder/kapatır. Sermayenin bir kısmı geri gelir.
  static BusinessResult close({required GameState state}) {
    final Business? is_ = openBusiness(state);
    if (is_ == null) {
      return BusinessResult(
        state: state,
        outcome: const BusinessOutcome(
          applied: false,
          text: 'Açık bir işin yok.',
        ),
      );
    }
    final BusinessType? tur = is_.type;
    final int yas = state.player.age;
    // Durumu iyi olan iş daha iyi devredilir.
    final int bedel = tur == null
        ? 0
        : (tur.salvageValue * (0.4 + is_.condition / 100 * 0.6)).round();
    final Business kapanan = is_.copyWith(
      closedAtAge: yas,
      endReason: BusinessEndReason.satildi,
      totalProfit: is_.totalProfit + bedel,
    );
    final String metin = bedel > 0
        ? '${tur?.name ?? 'İşini'} devrettin. Elinde '
            '${trMoney(bedel)} kaldı.'
        : '${tur?.name ?? 'İşini'} kapattın. Geriye pek bir şey kalmadı.';
    GameState next = _replace(state, kapanan).copyWith(
      player: state.player.copyWith(wallet: state.player.wallet + bedel),
    );
    next = _log(next, metin);
    next = next.queueNotice(
      PendingNotice(
        id: 'is-kapandi-${is_.id}',
        kind: NoticeKind.kendiIsi,
        age: yas,
        title: 'İşini devrettin',
        text: metin,
        money: bedel,
      ),
    );
    return BusinessResult(
      state: next,
      outcome: BusinessOutcome(applied: true, text: metin, money: bedel),
    );
  }

  // ===================================================================
  // 5) Fiyat, reklam, bakım ve personel (Paket AE, §4, §7, §8, §10)
  // ===================================================================

  /// prototypeOnly: oyuncunun yazabileceği fiyatın bölge ortalamasına
  /// göre alt ve üst sınırı (§4).
  ///
  /// Sınır **exploit kapatmak için değil**, saçma sayıları elemek için
  /// var: talep eğrisi zaten uçlarda düzleşiyor. Bir halı sahayı saati
  /// 10 ₺'ye ya da 90.000 ₺'ye vermek bir karar değil, bir yazım
  /// hatasıdır.
  static const double prototypeOnlyPriceFloor = 0.35;
  static const double prototypeOnlyPriceCeiling = 2.60;

  /// prototypeOnly: hazır fiyat seçeneklerinin ortalamaya oranı.
  static const double prototypeOnlyCheapRatio = 0.78;
  static const double prototypeOnlyExpensiveRatio = 1.32;

  /// prototypeOnly: bakımın ekipmana kattığı.
  static const int prototypeOnlyMaintenanceGain = 34;

  /// prototypeOnly: bakımın **taban ciroya** oranla bedeli.
  static const double prototypeOnlyMaintenanceCostShare = 0.085;

  /// prototypeOnly: rutin (zorunlu) bakımın taban ciroya oranı.
  static const double prototypeOnlyRoutineUpkeepShare = 0.022;

  /// prototypeOnly: personelle ilgilenmenin memnuniyete katkısı.
  static const int prototypeOnlyStaffCareMorale = 9;

  /// prototypeOnly: zammın memnuniyete katkısı ve ücret düzeyine eki.
  static const int prototypeOnlyRaiseMorale = 20;
  static const int prototypeOnlyRaiseWageStep = 11;

  /// prototypeOnly: ücret düzeyinin tavanı. Zam sonsuz değil.
  static const int prototypeOnlyMaxWageLevel = 160;

  /// prototypeOnly: yeni çalışan bulmanın taban ciroya oranla bedeli.
  static const double prototypeOnlyHireCostShare = 0.030;

  /// prototypeOnly: reklamın azalan marjinal etki katsayısı (§8, §35).
  ///
  /// Üst üste aynı kampanya her yıl daha az iş yapar: 1., 2. ve 3. yılda
  /// kabaca %100, %74 ve %59. Üçüncü yılın sonunda kampanya kendiliğinden
  /// biter ([BusinessAd.prototypeOnlyRunYears]); oyuncu yenisini kurmak
  /// zorundadır. Her yıl en pahalı reklamı vermek garanti para üretmez.
  static const double prototypeOnlyAdFatigue = 0.35;

  /// prototypeOnly: en kötü ihtimalle reklamın talebe zararı.
  ///
  /// Tutmayan kampanya parayı yer ama dükkânı batırmaz.
  static const double prototypeOnlyAdWorstCase = -0.14;

  /// Fiyatın yazılabileceği aralık (₺).
  static ({int min, int max}) priceRange(GameState state, Business business) {
    final BusinessType? tur = business.type;
    if (tur == null) return (min: 1, max: 1);
    final int ort =
        BusinessMarket.averagePrice(state, tur, state.player.age);
    return (
      min: (ort * prototypeOnlyPriceFloor).round().clamp(1, 1 << 30),
      max: (ort * prototypeOnlyPriceCeiling).round(),
    );
  }

  /// Fiyatı belirler. Yıl içinde değiştirmek **gelir üretmez**: hesap
  /// yalnızca yaş alırken bir kez kapanır (§36).
  static BusinessResult setPrice({
    required GameState state,
    required int fiyat,
  }) {
    final Business? is_ = openBusiness(state);
    if (is_ == null) {
      return BusinessResult(
        state: state,
        outcome: const BusinessOutcome(
          applied: false,
          text: 'Açık bir işin yok.',
        ),
      );
    }
    final ({int min, int max}) aralik = priceRange(state, is_);
    if (fiyat < aralik.min || fiyat > aralik.max) {
      return BusinessResult(
        state: state,
        outcome: BusinessOutcome(
          applied: false,
          text: 'Fiyat ${trMoney(aralik.min)} ile ${trMoney(aralik.max)} '
              'arasında olmalı.',
        ),
      );
    }
    final BusinessType? tur = is_.type;
    final int ort =
        BusinessMarket.averagePrice(state, tur!, state.player.age);
    final String metin = fiyat > ort
        ? '${tur.priceLabel}: ${trMoney(fiyat)}. Bölgenin üstündesin; '
            'gelen daha az gelir ama her gelenden daha çok kalır.'
        : fiyat < ort
            ? '${tur.priceLabel}: ${trMoney(fiyat)}. Bölgenin altındasın; '
                'kalabalık olur, kasada az kalır.'
            : '${tur.priceLabel}: ${trMoney(fiyat)}. Bölgeyle aynısın.';
    final GameState next = _log(_replace(state, is_.copyWith(price: fiyat)),
        '${tur.name}: ${tur.priceLabel.toLowerCase()} '
        '${trMoney(fiyat)} oldu.');
    return BusinessResult(
      state: next,
      outcome: BusinessOutcome(applied: true, text: metin),
    );
  }

  /// Reklam kampanyası başlatır ya da keser (§8).
  ///
  /// Kampanyanın bedeli **yıl sonunda** gider satırına yazılır; aynı yıl
  /// tekrar tekrar seçmek masrafı katlamaz, yalnızca seçimi değiştirir.
  static BusinessResult setAd({
    required GameState state,
    required BusinessAd reklam,
  }) {
    final Business? is_ = openBusiness(state);
    if (is_ == null) {
      return BusinessResult(
        state: state,
        outcome: const BusinessOutcome(
          applied: false,
          text: 'Açık bir işin yok.',
        ),
      );
    }
    if (is_.ad == reklam) {
      return BusinessResult(
        state: state,
        outcome: BusinessOutcome(
          applied: false,
          text: reklam == BusinessAd.yok
              ? 'Zaten reklam vermiyorsun.'
              : 'Bu kampanya zaten yürüyor.',
        ),
      );
    }
    // Kampanya değişince yorgunluk sayacı sıfırlanır: yeni kampanya
    // yeni bir hikâye. Aynı kampanyayı sürdürmek yorar (§35).
    final Business guncel = is_.copyWith(ad: reklam, adStreak: 0);
    final String metin = reklam == BusinessAd.yok
        ? 'Reklamı kestin. Kasaya giren para artık yalnızca işin kendi '
            'işi.'
        : '${reklam.label} başlattın. Bedeli yıl sonunda hesaba yazılır; '
            'tutup tutmayacağını kimse söyleyemez.';
    return BusinessResult(
      state: _log(_replace(state, guncel), metin),
      outcome: BusinessOutcome(applied: true, text: metin),
    );
  }

  /// Bakımın bu yılki bedeli (₺).
  static int maintenanceCost(Business business) {
    final BusinessType? tur = business.type;
    if (tur == null) return 0;
    // Ne kadar yıprandıysa o kadar masraf: yılında yapılan bakım ucuz,
    // dökülene kadar bekleyen pahalı.
    final double eksik = (100 - business.upkeep) / 100;
    return (tur.baseRevenue *
            prototypeOnlyMaintenanceCostShare *
            (0.35 + eksik * 1.30))
        .round();
  }

  static InteractionAvailability maintenanceAvailability(GameState state) {
    final Business? is_ = openBusiness(state);
    if (is_ == null) {
      return const InteractionAvailability.blocked('Açık bir işin yok.');
    }
    if (is_.type?.equipmentLabel == null) {
      return const InteractionAvailability.blocked(
        'Bu işin bakım isteyen bir ekipmanı yok.',
      );
    }
    if (is_.lastMaintenanceAge != null &&
        is_.lastMaintenanceAge! >= state.player.age) {
      return const InteractionAvailability.blocked(
        'Bu yılın bakımını yaptırdın.',
      );
    }
    if (is_.upkeep >= 96) {
      return const InteractionAvailability.blocked(
        'Ortada bakılacak bir şey yok; her şey yerli yerinde.',
      );
    }
    final int bedel = maintenanceCost(is_);
    if (state.player.wallet < bedel) {
      return InteractionAvailability.blocked(
        'Bakım ${trMoney(bedel)} tutuyor; cüzdanında '
        '${trMoney(state.player.wallet)} var.',
      );
    }
    return const InteractionAvailability.allowed();
  }

  /// Bakım yaptırır: para **o an** çıkar, ekipman toparlanır (§10).
  static BusinessResult doMaintenance({required GameState state}) {
    final InteractionAvailability uygun = maintenanceAvailability(state);
    if (!uygun.isAllowed) {
      return BusinessResult(
        state: state,
        outcome: BusinessOutcome(
          applied: false,
          text: uygun.reason ?? 'Şu an mümkün değil.',
        ),
      );
    }
    final Business is_ = openBusiness(state)!;
    final int bedel = maintenanceCost(is_);
    final Business guncel = is_.copyWith(
      upkeep: (is_.upkeep + prototypeOnlyMaintenanceGain).clamp(0, 100),
      lastMaintenanceAge: state.player.age,
      yearMaintenanceSpend: is_.yearMaintenanceSpend + bedel,
    );
    final String metin =
        '${is_.type?.equipmentLabel ?? 'Ekipman'} elden geçti. '
        '${trMoney(bedel)} çıktı.\n\n'
        'Bir süre daha sorun çıkarmaz.';
    GameState next = _replace(state, guncel).copyWith(
      player: state.player.copyWith(
        wallet: (state.player.wallet - bedel).clamp(0, 1 << 31),
      ),
    );
    next = _log(next, '${is_.type?.name ?? 'İşin'} bakımı yapıldı.');
    return BusinessResult(
      state: next,
      outcome: BusinessOutcome(applied: true, text: metin, money: -bedel),
    );
  }

  /// Personel hamlesi (§7).
  static InteractionAvailability staffAvailability(
    GameState state,
    StaffAction hamle,
  ) {
    final Business? is_ = openBusiness(state);
    if (is_ == null) {
      return const InteractionAvailability.blocked('Açık bir işin yok.');
    }
    final BusinessType? tur = is_.type;
    if (tur == null || tur.staffSlots <= 0) {
      return const InteractionAvailability.blocked(
        'Bu işi tek başına yürütüyorsun; kadro yok.',
      );
    }
    switch (hamle) {
      case StaffAction.zam:
        if (is_.wageLevel >= prototypeOnlyMaxWageLevel) {
          return const InteractionAvailability.blocked(
            'Ücretler zaten piyasanın belirgin üstünde.',
          );
        }
      case StaffAction.iseAl:
        if (is_.staffGap <= 0) {
          return const InteractionAvailability.blocked('Kadro tamam.');
        }
        final int bedel = (tur.baseRevenue * prototypeOnlyHireCostShare)
            .round();
        if (state.player.wallet < bedel) {
          return InteractionAvailability.blocked(
            'Yeni birini işe almak ${trMoney(bedel)} tutuyor.',
          );
        }
      case StaffAction.ilgilen:
        break;
    }
    if (is_.lastStaffCareAge != null &&
        is_.lastStaffCareAge! >= state.player.age) {
      return const InteractionAvailability.blocked(
        'Bu yıl personelle bir kez ilgilendin; seneye yeniden açılır.',
      );
    }
    return const InteractionAvailability.allowed();
  }

  /// Personelle ilgilenir: zam yapar, yerine birini bulur ya da kendisi
  /// daha çok ilgilenir (§7).
  static BusinessResult staff({
    required GameState state,
    required StaffAction hamle,
  }) {
    final InteractionAvailability uygun = staffAvailability(state, hamle);
    if (!uygun.isAllowed) {
      return BusinessResult(
        state: state,
        outcome: BusinessOutcome(
          applied: false,
          text: uygun.reason ?? 'Şu an mümkün değil.',
        ),
      );
    }
    final Business is_ = openBusiness(state)!;
    final BusinessType tur = is_.type!;
    Business guncel;
    String metin;
    int para = 0;
    switch (hamle) {
      case StaffAction.zam:
        guncel = is_.copyWith(
          wageLevel: (is_.wageLevel + prototypeOnlyRaiseWageStep)
              .clamp(100, prototypeOnlyMaxWageLevel),
          staffMorale: (is_.staffMorale + prototypeOnlyRaiseMorale)
              .clamp(0, 100),
          lastStaffCareAge: state.player.age,
        );
        metin = 'Zam yaptın. Yüzler güldü.\n\n'
            'Bu para her ay çıkacak; kâr satırı bunu hissedecek.';
      case StaffAction.iseAl:
        para = -(tur.baseRevenue * prototypeOnlyHireCostShare).round();
        // Yeni gelenin niteliği kadronun ortalamasına yakın: iyi işletme
        // iyi eleman çeker, adı kötü olan işletme kimseyi çekemez.
        final int yeniNitelik =
            ((is_.staffQuality * 0.55 + is_.reputation * 0.45)).round();
        final int yeniKadro = is_.effectiveStaff + 1;
        guncel = is_.copyWith(
          staffCount: yeniKadro.clamp(0, tur.staffSlots),
          staffQuality: ((is_.staffQuality * is_.effectiveStaff +
                      yeniNitelik) /
                  yeniKadro)
              .round()
              .clamp(0, 100),
          lastStaffCareAge: state.player.age,
        );
        metin = 'Yerine birini buldun. İlk günler el yordamıyla geçecek.';
      case StaffAction.ilgilen:
        guncel = is_.copyWith(
          staffMorale: (is_.staffMorale + prototypeOnlyStaffCareMorale)
              .clamp(0, 100),
          staffQuality: (is_.staffQuality + 4).clamp(0, 100),
          lastStaffCareAge: state.player.age,
        );
        metin = 'Kapanıştan sonra oturup konuştunuz.\n\n'
            'Büyük bir şey değişmedi ama kimse kırgın kalmadı.';
    }
    GameState next = _replace(state, guncel).copyWith(
      player: state.player.copyWith(
        wallet: (state.player.wallet + para).clamp(0, 1 << 31),
        stats: hamle == StaffAction.ilgilen
            ? state.player.stats.gain(happiness: -1)
            : state.player.stats,
      ),
    );
    next = _log(next, metin.split('\n').first);
    return BusinessResult(
      state: next,
      outcome: BusinessOutcome(applied: true, text: metin, money: para),
    );
  }

  // ===================================================================
  // 6) Yıllık ilerleme
  // ===================================================================

  /// prototypeOnly: zarar eden yılın işin durumuna vurduğu en çok pay.
  ///
  /// **Neden var.** AE öncesinde durum yalnızca ilgilenmemekle düşüyordu;
  /// yani üst üste zarar eden bir iş, sahibi "işine bak"a bastığı sürece
  /// sonsuza kadar para yiyebiliyordu. Artık zarar işin kendisini de
  /// yıpratıyor: kötü yönetilen iş gerçekten batıyor.
  static const int prototypeOnlyLossConditionHit = 16;

  /// prototypeOnly: üst üste kaç zarar yılından sonra iş kapanır (§32).
  ///
  /// **Neden var (ölçümde yakalandı).** AE'nin ilk hâlinde işine bakan
  /// bir sahibin işi **hiç** kapanmıyordu: 45 hayat × ~35 yıl ölçümünde
  /// aktif sahibin kapanma oranı %0 çıktı ve `isletme aktif` oyunun en
  /// güvenli stratejisi oldu (kötü %10'u bütün yatırım stratejilerinin
  /// üstünde). §32 tam bunu yasaklıyor: "İşletmenin kendi risk, masraf,
  /// yönetim zamanı, **başarısızlık**, beklenmedik gider bedeli olsun."
  ///
  /// Eksik olan şey şuydu: durum (`condition`) ilgilenmekle yükseliyordu,
  /// yani kötü giden bir işi ayakta tutmanın bedeli yoktu. Artık **zarar
  /// yılları sayılıyor**. İşini iyi yöneten biri bile üst üste kötü
  /// yılları sonsuza kadar finanse edemez; kepenk iner.
  ///
  /// Sayaç kâr eden yılda sıfırlanır ve işe para koymak bir yıl geri
  /// alır ([invest]): "işe para koy" böylece gerçek bir kurtarma hamlesi
  /// olur.
  static const int prototypeOnlyLossStreakLimit = 3;

  /// İşin yılını işler: talep doğar, ciro ve giderler hesaplanır, sonuç
  /// cüzdana yazılır, durum kayar ve iş batabilir.
  ///
  /// Kâr/zarar bir yılda **bir kez** işlenir ([Business.lastSettledAge]).
  ///
  /// Zar **kendi akışından** gelir ([BusinessMarket.seed]): kayıt geri
  /// yüklenip aynı yıl yeniden çevrilemez ve ana oyun akışından çekiliş
  /// çalmaz. [rng] yalnızca işverenin laf etmesi gibi ana akışa ait
  /// yan olaylarda kullanılır.
  static GameState advanceYear(GameState state, int newAge, Random rng) {
    final Business? is_ = openBusiness(state);
    if (is_ == null) return state;
    final BusinessType? tur = is_.type;
    if (tur == null) return state;
    if (is_.lastSettledAge != null && is_.lastSettledAge! >= newAge) {
      return state;
    }
    // Kurulduğu yıl hesap kapatılmaz: ilk yıl sonunda ödenir.
    if (newAge <= is_.startedAtAge) {
      return _replace(state, is_.copyWith(lastSettledAge: newAge));
    }

    final Random zar = Random(BusinessMarket.seed(state, is_.id, newAge));
    final int oncekiYogunluk = is_.lastYear?.demandIndex ?? 100;

    // -----------------------------------------------------------------
    // 1) Yıpranma: ekipman, personel, itibar ve işin durumu kayar.
    // -----------------------------------------------------------------
    Business b = _wear(is_, tur, state, newAge, oncekiYogunluk, zar);

    // -----------------------------------------------------------------
    // 2) Olaylar: arıza, personel ayrılığı, denetim, afet (§11-24).
    // -----------------------------------------------------------------
    final BusinessIncidentOutcome olay = BusinessIncidents.advance(
      state: state,
      business: b,
      tur: tur,
      newAge: newAge,
      rng: zar,
      lastDemandIndex: oncekiYogunluk,
    );
    b = olay.business;

    // -----------------------------------------------------------------
    // 3) Reklam: etkisi ve bedeli (§8).
    // -----------------------------------------------------------------
    final ({double lift, bool viral}) reklam = _adLift(b, zar);
    final double reklamEtkisi = reklam.lift;
    if (reklam.viral) {
      // Tutan kampanya bir iki yıl süren kalıcı baskı bırakır (§11).
      b = b.copyWith(
        demandPressure: (b.demandPressure * prototypeOnlyViralLasting).clamp(
          BusinessMarket.prototypeOnlyPressureFloor,
          BusinessMarket.prototypeOnlyPressureCeiling,
        ),
      );
    }

    // -----------------------------------------------------------------
    // 4) Talep ve hesap (§5, §6).
    // -----------------------------------------------------------------
    final BusinessDemand talep = BusinessMarket.demand(
      state: state,
      business: b,
      tur: tur,
      age: newAge,
      rng: zar,
      adLift: reklamEtkisi,
    );
    final int yogunluk =
        (talep.index * olay.demandShift).round().clamp(0, 400);

    final double adet = tur.baseUnits * yogunluk / 100;
    final int ciro = (adet * talep.price).round();

    // Tedarik **adede** bağlıdır, ciroya değil: fiyatı yükseltmek birim
    // maliyeti yükseltmez. Fiyat kararının anlamı buradan gelir.
    final int tedarik =
        (adet * talep.marketPrice * tur.supplyShare).round();
    // Kira ve sabit gider ne fiyata ne müşteriye bakar; her hâlükârda
    // ödenir. Boş geçen yılın acısı buradan gelir.
    final int sabit =
        (tur.baseUnits * talep.marketPrice * tur.fixedShare).round();
    // Personel gideri kadroyla, ücret düzeyiyle ve bir miktar da
    // yoğunlukla artar: kalabalık gün fazla mesaidir.
    final double kadroOrani = tur.staffSlots <= 0
        ? 0.0
        : b.effectiveStaff / tur.staffSlots;
    final int personel = (tur.baseUnits *
            talep.marketPrice *
            tur.staffShare *
            kadroOrani *
            (b.wageLevel / 100) *
            (0.70 + 0.30 * (yogunluk / 100)))
        .round();
    // Rutin bakım: oyuncu bakım yaptırmasa da mecburi olan asgari
    // masraf. Oyuncunun kendi yaptırdığı bakım cüzdandan zaten çıktı;
    // burada yalnızca rapora yazılır, ikinci kez tahsil edilmez.
    final int rutinBakim = (tur.baseRevenue *
            prototypeOnlyRoutineUpkeepShare *
            (tur.wearRate / 9))
        .round();
    final int reklamBedeli = b.ad == BusinessAd.yok
        ? 0
        : (tur.baseRevenue * b.ad.costShare).round();

    // Oyuncunun kendi yaptırdığı bakım cüzdandan **o an** çıkmıştı;
    // burada yalnızca yılın gerçek sonucuna yazılır.
    //
    // **Gerçek hata (kendi diff'imi okurken yakalandı).** İlk yazımda bu
    // tutar `BusinessYear.maintenanceCost` satırına giriyor ama `net`ten
    // düşülmüyordu: oyuncu raporda "Ciro − giderler ≠ Net" görüyordu.
    // Artık yılın **ekonomik** sonucu bakımı da içeriyor; cüzdana ise
    // yalnızca yıl sonunda kapanan kısım yazılıyor, yani para iki kez
    // çıkmıyor.
    final int gider = personel +
        tedarik +
        sabit +
        rutinBakim +
        b.yearMaintenanceSpend +
        reklamBedeli +
        olay.cost;
    final int net = ciro - gider;
    // Cüzdana giren/çıkan: bakım zaten ödendiği için geri eklenir.
    final int cuzdanEtkisi = net + b.yearMaintenanceSpend;

    // -----------------------------------------------------------------
    // 5) Kayıt: cüzdan, durum, geçmiş.
    // -----------------------------------------------------------------
    GameState next = state.copyWith(
      player: state.player.copyWith(
        wallet: (state.player.wallet + cuzdanEtkisi).clamp(0, 1 << 31),
      ),
    );

    int zararSerisi = net < 0 ? b.lossStreak + 1 : 0;
    int durum = b.condition;
    if (net < 0) {
      // Zararın büyüklüğüne göre durum düşer: küçük zarar yıpratır,
      // taban cironun yarısı kadar zarar işi sarsar.
      final double siddet =
          (-net / (tur.baseRevenue * 0.5)).clamp(0.0, 1.0).toDouble();
      durum -= (prototypeOnlyLossConditionHit * siddet).round();
    } else if (net > tur.baseYearlyProfit * 0.5) {
      // İyi giden yıl işi toparlar: kasada para varken her şey kolaydır.
      durum += 4;
    }
    durum = durum.clamp(0, 100);

    final BusinessYear yil = BusinessYear(
      age: newAge,
      revenue: ciro,
      staffCost: personel,
      supplyCost: tedarik,
      fixedCost: sabit,
      maintenanceCost: rutinBakim + b.yearMaintenanceSpend,
      adCost: reklamBedeli,
      incidentCost: olay.cost,
      net: net,
      price: talep.price,
      marketPrice: talep.marketPrice,
      demandIndex: yogunluk,
    );
    final List<BusinessYear> gecmis = <BusinessYear>[...b.history, yil];
    while (gecmis.length > Business.prototypeOnlyHistoryYears) {
      gecmis.removeAt(0);
    }

    if (zararSerisi > prototypeOnlyLossStreakLimit) {
      zararSerisi = prototypeOnlyLossStreakLimit;
    }
    b = b.copyWith(
      condition: durum,
      lossStreak: zararSerisi,
      totalProfit: b.totalProfit + net,
      lastSettledAge: newAge,
      history: gecmis,
      yearMaintenanceSpend: 0,
      adStreak: b.ad == BusinessAd.yok ? 0 : b.adStreak + 1,
    );
    // Süresi dolan kampanya kendiliğinden biter (§8, §35).
    if (b.ad != BusinessAd.yok &&
        b.adStreak >= BusinessAd.prototypeOnlyRunYears) {
      b = b.copyWith(ad: BusinessAd.yok, adStreak: 0);
    }

    // -----------------------------------------------------------------
    // 6) Battı mı?
    // -----------------------------------------------------------------
    final bool zararlaBatti = zararSerisi >= prototypeOnlyLossStreakLimit;
    if (durum <= 0 || zararlaBatti) {
      final Business batan = b.copyWith(
        closedAtAge: newAge,
        endReason: BusinessEndReason.batti,
      );
      next = _replace(next, batan);
      final String metin = zararlaBatti
          ? '${tur.name} kapandı.\n\n'
              'Üç yıl üst üste açığı sen kapattın. '
              'Bu yıl kapatmayacağını anladın.\n\n'
              'Oraya koyduğun ${trMoney(batan.totalInvested)} gitti.'
          : '${tur.name} battı. Kepenk indi, '
              'borçlar kaldı.\n\nOraya koyduğun '
              '${trMoney(batan.totalInvested)} gitti.';
      next = _log(next, '${tur.name} battı.', age: newAge);
      next = next.copyWith(
        player: next.player.copyWith(
          stats: next.player.stats.gain(happiness: -14, health: -3),
        ),
      );
      return next.queueNotice(
        PendingNotice(
          id: 'is-batti-${is_.id}-$newAge',
          kind: NoticeKind.kendiIsi,
          age: newAge,
          title: zararlaBatti ? 'İşini kapattın' : 'İşin battı',
          text: metin,
          money: cuzdanEtkisi,
        ),
      );
    }

    next = _replace(next, b);
    for (final String satir in olay.logs) {
      next = _log(next, satir, age: newAge);
    }
    for (final PendingNotice bildirim in olay.notices) {
      next = next.queueNotice(bildirim);
    }
    next = _log(next, _yilMetni(tur, b, net), age: newAge);
    // Rutin yıl penceresi açmaz (§25, §31): yalnızca gerçekten
    // anlatılacak bir şey olduğunda bildirim çıkar.
    // **Hikâye bildirimi (§12, §13).** Kozmetik değil: ölçü, geçen yıla
    // göre **gerçekleşen ciro**. Hikâye varsa yılın penceresi odur;
    // ikisi birden açılmaz (§25 bildirim yağmuru kuralı).
    final String? hikaye = _yilHikayesi(b, yil, reklam.viral);
    if (hikaye != null) {
      next = next.queueNotice(
        PendingNotice(
          id: 'is-hikaye-${is_.id}-$newAge',
          kind: NoticeKind.kendiIsi,
          age: newAge,
          title: reklam.viral
              ? 'Reklam tuttu'
              : yil.revenue >= (b.history.length > 1
                      ? b.history[b.history.length - 2].revenue
                      : 0)
                  ? 'Bu sene işler başka'
                  : 'Dükkân eskisi gibi değil',
          text: '$hikaye\n\n${yearReport(tur, yil)}',
          money: cuzdanEtkisi,
        ),
      );
    } else if (_yilBildirimiGerekli(tur, yil, olay)) {
      next = next.queueNotice(
        PendingNotice(
          id: 'is-yil-${is_.id}-$newAge',
          kind: NoticeKind.kendiIsi,
          age: newAge,
          title: net >= 0 ? 'İşin yılı kapandı' : 'İşin zarar etti',
          text: yearReport(tur, yil),
          money: cuzdanEtkisi,
        ),
      );
    }
    return _maybeEmployerComplaint(next, tur, newAge, rng);
  }

  /// prototypeOnly: başarı hikâyesi için gereken ciro sıçraması (§12).
  static const double prototypeOnlySuccessStoryRatio = 1.55;

  /// prototypeOnly: başarısızlık hikâyesi için gereken ciro düşüşü (§13).
  static const double prototypeOnlyFailureStoryRatio = 0.66;

  /// Bu yılın hikâyesi; sıradan yılda `null`.
  ///
  /// **Ölçü gerçekleşen cirodur** (§12: "sadece kozmetik değil, gerçek
  /// ciro artışıyla uyumlu olsun"). Geçen yılın cirosu yoksa hikâye
  /// anlatılmaz: ilk yılın karşılaştırması olmaz.
  static String? _yilHikayesi(Business b, BusinessYear yil, bool viral) {
    if (viral) {
      return 'Kampanya beklediğinden başka tuttu.\n\n'
          'Bir hafta boyunca gelen herkes aynı şeyi söyledi: '
          '"Gördüm de geldim."';
    }
    if (b.history.length < 2) return null;
    final BusinessYear onceki = b.history[b.history.length - 2];
    if (onceki.revenue <= 0) return null;
    final double oran = yil.revenue / onceki.revenue;
    if (oran >= prototypeOnlySuccessStoryRatio) {
      return 'Bu sene işler başka.\n\n'
          'Akşam kapıyı kapatırken kasaya bir daha baktın.\n\n'
          'Geçen yılın neredeyse iki katı.';
    }
    if (oran <= prototypeOnlyFailureStoryRatio) {
      return 'Bu yıl dükkân eskisi gibi değil.\n\n'
          'Kapı açılıyor ama alışveriş yapan yok.\n\n'
          'Akşam kasayı sayarken iki kere saydın.';
    }
    return null;
  }

  /// prototypeOnly: yıl penceresinin açılması için zararın taban kâra
  /// oranı (§25, §28).
  static const double prototypeOnlyNoticeLossShare = 0.35;

  /// prototypeOnly: yıl penceresinin açılması için kârın taban kâra
  /// oranı.
  static const double prototypeOnlyNoticeProfitShare = 1.60;

  /// Bu yılın penceresi açılmalı mı?
  ///
  /// **Bildirim yağmuru istemiyoruz** (§25): rutin yıl yalnızca hayat
  /// günlüğüne ve işletme ekranındaki geçmişe yazılır. Pencere, ciddi
  /// zarar, olağandışı iyi yıl ya da pencere açacak bir olay varsa çıkar.
  static bool _yilBildirimiGerekli(
    BusinessType tur,
    BusinessYear yil,
    BusinessIncidentOutcome olay,
  ) {
    if (olay.opensNotice) return true;
    if (yil.net < -tur.baseYearlyProfit * prototypeOnlyNoticeLossShare) {
      return true;
    }
    if (yil.net > tur.baseYearlyProfit * prototypeOnlyNoticeProfitShare) {
      return true;
    }
    return false;
  }

  /// Yıl sonu raporunun sade metni (§31).
  static String yearReport(BusinessType tur, BusinessYear yil) {
    final StringBuffer b = StringBuffer()
      ..writeln('${tur.name} bu yılı kapattı.')
      ..writeln()
      ..writeln('Ciro: ${trMoney(yil.revenue)}');
    if (yil.staffCost > 0) b.writeln('Personel: -${trMoney(yil.staffCost)}');
    if (yil.supplyCost > 0) b.writeln('Tedarik: -${trMoney(yil.supplyCost)}');
    if (yil.fixedCost > 0) {
      b.writeln('Kira ve sabit gider: -${trMoney(yil.fixedCost)}');
    }
    if (yil.maintenanceCost > 0) {
      b.writeln('Bakım: -${trMoney(yil.maintenanceCost)}');
    }
    if (yil.adCost > 0) b.writeln('Reklam: -${trMoney(yil.adCost)}');
    if (yil.incidentCost > 0) {
      b.writeln('Diğer gider: -${trMoney(yil.incidentCost)}');
    }
    b
      ..writeln()
      ..write(yil.net >= 0
          ? 'Net: ${trMoney(yil.net)}'
          : 'Net: -${trMoney(-yil.net)}');
    return b.toString();
  }

  /// prototypeOnly: kampanyanın **tutma** ihtimali (Paket AG, §10, §11).
  ///
  /// Reklam her zaman aynı getiriyi vermez. Nadiren beklenmedik biçimde
  /// tutar ve bir iki yıl süren talep sıçraması bırakır. Büyük kampanya
  /// hem daha pahalı hem daha oynak: tutma ihtimali de yüksek.
  ///
  /// Oranlar **ölçümle doğrulandı**, kafadan sabitlenmedi: AG ölçümü
  /// gerçekleşen viral sıklığını ve kampanyaların dağılımını raporluyor.
  static double viralChanceFor(BusinessAd ad) => switch (ad) {
        BusinessAd.yok => 0.0,
        BusinessAd.mahalle => 0.040,
        BusinessAd.sosyalMedya => 0.090,
        BusinessAd.buyuk => 0.140,
      };

  /// prototypeOnly: tutan kampanyanın o yılki katkı çarpanı.
  static const double prototypeOnlyViralMultiplier = 3.6;

  /// prototypeOnly: tutan kampanyanın bıraktığı kalıcı talep baskısı.
  ///
  /// Sonsuz buff değil: [BusinessMarket.prototypeOnlyPressureRecovery]
  /// her yıl 1,0'a doğru çekiyor, yani etkisi bir iki yılda sönüyor.
  static const double prototypeOnlyViralLasting = 1.24;

  /// Reklamın bu yılki talep katkısı; ölçüm testleri için açık kapı.
  static double adLiftForTest(Business business, Random rng) =>
      _adLift(business, rng).lift;

  /// Reklamın bu yılki talep katkısı (§8, §35) ve tutup tutmadığı (§11).
  static ({double lift, bool viral}) _adLift(
    Business business,
    Random rng,
  ) {
    if (business.ad == BusinessAd.yok) return (lift: 0.0, viral: false);
    final BusinessAd r = business.ad;
    // Azalan marjinal etki: aynı kampanyanın ikinci, üçüncü yılı daha az
    // iş yapar.
    final double yorgunluk = 1 / (1 + prototypeOnlyAdFatigue * business.adStreak);
    final double sans = 1 + (rng.nextDouble() * 2 - 1) * r.variance;
    // **Tutma** zarı ayrı atılır ki kampanya kademesine göre değişsin.
    final bool tuttu = rng.nextDouble() < viralChanceFor(r);
    final double ham =
        r.lift * yorgunluk * sans * (tuttu ? prototypeOnlyViralMultiplier : 1);
    return (
      lift: ham.clamp(prototypeOnlyAdWorstCase, 3.0).toDouble(),
      viral: tuttu,
    );
  }

  /// Yılın yıpranması: ekipman, personel, itibar ve işin durumu.
  static Business _wear(
    Business is_,
    BusinessType tur,
    GameState state,
    int newAge,
    int oncekiYogunluk,
    Random zar,
  ) {
    // --- İşin durumu -------------------------------------------------
    final bool ilgilenildi =
        is_.lastTendedAge != null && is_.lastTendedAge! >= newAge - 1;
    int durum = is_.condition;
    if (!ilgilenildi) durum -= prototypeOnlyNeglectDrop;
    if (state.isImprisoned) durum -= prototypeOnlyNeglectDrop;
    final int salinim =
        ((zar.nextDouble() * 2 - 1) * tur.volatility * 18).round();
    durum = (durum + salinim).clamp(0, 100);

    // --- Ekipman (§10) -----------------------------------------------
    // Yoğun geçen yıl ekipmanı daha çok yıpratır: ucuz fiyatla kalabalık
    // toplamanın bedeli buradan çıkar (§4).
    final double yuk = 0.70 + 0.50 * (oncekiYogunluk / 100);
    final int bakim =
        (is_.upkeep - (tur.wearRate * yuk).round()).clamp(0, 100);

    // --- Personel (§7) -----------------------------------------------
    int moral = is_.staffMorale;
    int nitelik = is_.staffQuality;
    if (tur.staffSlots > 0) {
      final int hedefMoral = (50 +
              (is_.wageLevel - 100) * 0.9 -
              (oncekiYogunluk - 110).clamp(0, 300) * 0.22 -
              is_.staffGap * 9 +
              (is_.condition - 50) * 0.12)
          .round()
          .clamp(0, 100);
      moral = (moral + (hedefMoral - moral) * 0.30).round().clamp(0, 100);
      // Nitelik deneyimle yavaşça artar, huzursuz kadroda geriler.
      nitelik = (nitelik + (moral >= 45 ? 2 : -3)).clamp(0, 100);
    }

    // --- Kalıcı talep baskısı (§11-24) -------------------------------
    // Rakibin açılması, sözleşmenin iptali ya da mahallenin canlanması
    // yıllar boyu sürer; her yıl bir miktar 1,0'a doğru toparlanır.
    final double baski = is_.demandPressure +
        (1 - is_.demandPressure) * BusinessMarket.prototypeOnlyPressureRecovery;

    // --- İtibar (§9) -------------------------------------------------
    final int ortalama = BusinessMarket.averagePrice(state, tur, newAge);
    final int fiyat =
        BusinessMarket.effectivePrice(state, is_, tur, newAge);
    final double fiyatOrani = fiyat / ortalama;
    final double hizmet = BusinessMarket.serviceScore(
      is_.copyWith(upkeep: bakim, condition: durum, staffMorale: moral,
          staffQuality: nitelik),
      tur,
    );
    // Ucuz olmak tek başına itibarı yüzde yüze çıkarmaz (§9): fiyatın
    // payı sınırlı, hizmetin payı büyük.
    final double hedef = (50 +
            (hizmet - 50) * 0.55 -
            (fiyatOrani - 1) * 26 +
            (oncekiYogunluk - 100) * 0.05)
        .clamp(0, 100)
        .toDouble();
    final int itibar =
        (is_.reputation + (hedef - is_.reputation) * 0.25).round().clamp(0, 100);

    return is_.copyWith(
      condition: durum,
      upkeep: bakim,
      staffMorale: moral,
      staffQuality: nitelik,
      reputation: itibar,
      demandPressure: baski,
    );
  }

  /// prototypeOnly: maaşlı işte çalışırken kendi işi de olan oyuncuya
  /// işverenin laf etme ihtimali (D-143).
  ///
  /// Faho'nun isteği: "hem kendi işimi kurup hem de bir işte çalıştığımda
  /// iş verenim beni fazla ilgilenmemekle falan suçlasın, kendi işimi
  /// kurduğumda rastgele gelebilsin bu durum."
  static const double prototypeOnlyEmployerComplaintChance = 0.28;

  /// İşveren, ikinci işi olan çalışanına laf eder.
  ///
  /// Uyarı **tek başına kimseyi işten atmaz** (D-078 ile aynı kural);
  /// yalnızca işten çıkarılma ihtimalini bir miktar yükseltir. Yılda en
  /// çok bir kez gelir ve yalnızca gerçekten iki işi olan oyuncuya gelir.
  static GameState _maybeEmployerComplaint(
    GameState state,
    BusinessType tur,
    int newAge,
    Random rng,
  ) {
    if (!state.career.isEmployed) return state;
    if (state.career.isRetired) return state;
    if (state.isImprisoned) return state;
    if (rng.nextDouble() >= prototypeOnlyEmployerComplaintChance) {
      return state;
    }

    final String isAdi = state.career.job?.name ?? 'işin';
    GameState next = state.copyWith(
      career: state.career.copyWith(
        employerWarnings: state.career.employerWarnings + 1,
      ),
      player: state.player.copyWith(
        stats: state.player.stats.gain(happiness: -3),
      ),
    );
    final String metin = 'Yöneticin ${tur.name} için laf etti: '
        '"Kafan burada değil, dükkânda."\n\n'
        'Uyarı tek başına işten çıkarmaz ama birikirse iş masaya '
        'yatırılır.';
    next = _log(next, '$isAdi işinde ikinci iş için uyarı aldın.',
        age: newAge);
    return next.queueNotice(
      PendingNotice(
        id: 'is-uyari-$newAge',
        kind: NoticeKind.kariyer,
        age: newAge,
        title: 'İş yerinden uyarı',
        text: metin,
      ),
    );
  }

  static String _yilMetni(BusinessType tur, Business is_, int kar) {
    if (kar > 0) {
      return '${tur.name} bu yıl ${trMoney(kar)} bıraktı.\n\n'
          'Durum: ${is_.conditionLabel}.';
    }
    if (kar == 0) {
      return '${tur.name} bu yıl ne kâr ne zarar. Ayakta durdu, '
          'o kadar.\n\nDurum: ${is_.conditionLabel}.';
    }
    return '${tur.name} bu yıl ${trMoney(-kar)} zarar etti. '
        'Kiralar, personel, faturalar.\n\nDurum: ${is_.conditionLabel}.';
  }

  // ===================================================================
  // Yardımcılar
  // ===================================================================

  /// Bu yıl işe kaç kez bakıldı.
  ///
  /// **Gerçek hata (Faho bildirdi):** burası `lastTendedAge` alanına
  /// bakıyordu ve en çok **1** döndürebiliyordu. Sınır ise 2 idi; yani
  /// `1 >= 2` hiçbir zaman doğru olmuyor, kapı hiç kapanmıyordu. Faho'nun
  /// gözlemi: "kendi işimde işine bak seçeneğine sonsuz tıklayabiliyorum
  /// ve kara geçene kadar tıkladım". Sayaç artık gerçekten sayılıyor.
  ///
  /// Sayaç `interactionCounts` içinde tutulur; bu harita her yaşta
  /// sıfırlandığı için ayrı bir kayıt alanı açmaya gerek yok.
  static int _tendedThisAge(GameState state, Business is_) =>
      state.interactionCount(tendCounterScope, is_.id);

  /// Cezaevi/aktivite sayaçlarıyla çakışmayan kapsam adı.
  static const String tendCounterScope = 'kendiIsi';

  /// Sayaca bir vuruş ekler.
  static GameState _countTend(GameState state, Business is_) {
    final String anahtar = GameState.interactionKey(tendCounterScope, is_.id);
    return state.copyWith(
      interactionCounts: Map<String, int>.unmodifiable(<String, int>{
        ...state.interactionCounts,
        anahtar: (state.interactionCounts[anahtar] ?? 0) + 1,
      }),
    );
  }

  static GameState _replace(GameState state, Business is_) => state.copyWith(
        businesses: state.businesses
            .map((Business b) => b.id == is_.id ? is_ : b)
            .toList(growable: false),
      );

  static GameState _log(GameState state, String metin, {int? age}) =>
      state.copyWith(
        log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
          ...state.log,
          LifeLogEntry(
            age: age ?? state.player.age,
            text: metin,
            category: LogCategory.kisisel,
          ),
        ]),
      );
}
