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
import '../../text/turkish_text.dart';
import '../models/business.dart';
import '../models/game_state.dart';
import '../models/interaction.dart';
import '../models/life_log.dart';
import '../models/pending_notice.dart';

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
  static int yearlyBusinessIncome(GameState state) {
    final Business? is_ = openBusiness(state);
    if (is_ == null) return 0;
    return expectedProfit(is_);
  }

  /// İşin durumuna göre beklenen yıllık kâr/zarar.
  ///
  /// Durum 100'de tam kâr, 50'de kârın beşte biri, 25'in altında
  /// **zarar**. Eşikler `prototypeOnly`.
  static int expectedProfit(Business business) {
    final BusinessType? tur = business.type;
    if (tur == null) return 0;
    final int d = business.condition;
    if (d >= 50) {
      // 50 → %20, 100 → %100 arası doğrusal.
      final double oran = 0.2 + (d - 50) / 50 * 0.8;
      return (tur.baseYearlyProfit * oran).round();
    }
    // 50 → %20 kâr, 25 → 0, 0 → tam kârın yarısı kadar zarar.
    final double oran = (d - 25) / 25 * 0.2;
    return (tur.baseYearlyProfit * oran).round();
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
  // 5) Yıllık ilerleme
  // ===================================================================

  /// İşin yılını işler: kâr/zarar cüzdana yazılır, durum kayar, batabilir.
  ///
  /// Kâr/zarar bir yılda **bir kez** işlenir ([Business.lastSettledAge]).
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

    // 1) Durum kayar: ilgilenilmediyse düşer, ilgilenildiyse yerinde
    // durur. Üstüne oynaklık biner.
    final bool ilgilenildi =
        is_.lastTendedAge != null && is_.lastTendedAge! >= newAge - 1;
    int durum = is_.condition;
    if (!ilgilenildi) durum -= prototypeOnlyNeglectDrop;
    // Cezaevindeyken iş kendi başına daha hızlı bozulur.
    if (state.isImprisoned) durum -= prototypeOnlyNeglectDrop;
    // Oynaklık: türün volatility'si kadar yukarı ya da aşağı.
    final int salinim = ((rng.nextDouble() * 2 - 1) * tur.volatility * 18)
        .round();
    durum = (durum + salinim).clamp(0, 100);

    final Business durumGuncel = is_.copyWith(condition: durum);
    final int kar = expectedProfit(durumGuncel);

    GameState next = state;
    // 2) Kâr/zarar cüzdana. **Cüzdan eksiye düşmez** (ECO-001): zarar
    // cüzdanı boşaltabilir ama borç yazmaz.
    next = next.copyWith(
      player: next.player.copyWith(
        wallet: (next.player.wallet + kar).clamp(0, 1 << 31),
      ),
    );

    // 3) Battı mı?
    if (durum <= 0) {
      final Business batan = durumGuncel.copyWith(
        closedAtAge: newAge,
        endReason: BusinessEndReason.batti,
        totalProfit: is_.totalProfit + kar,
        lastSettledAge: newAge,
      );
      next = _replace(next, batan);
      final String metin = '${tur.name} battı. Kepenk indi, '
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
          title: 'İşin battı',
          text: metin,
          money: kar,
        ),
      );
    }

    final Business guncel = durumGuncel.copyWith(
      totalProfit: is_.totalProfit + kar,
      lastSettledAge: newAge,
    );
    next = _replace(next, guncel);
    final String metin = _yilMetni(tur, guncel, kar);
    next = _log(next, metin, age: newAge);
    next = next.queueNotice(
      PendingNotice(
        id: 'is-yil-${is_.id}-$newAge',
        kind: NoticeKind.kendiIsi,
        age: newAge,
        title: kar >= 0 ? 'İşin yılı kapandı' : 'İşin zarar etti',
        text: metin,
        money: kar,
      ),
    );
    return _maybeEmployerComplaint(next, tur, newAge, rng);
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
