// Profesyonel dövüş/spor kariyeri motoru (Paket AL).
//
// **Ana tasarım kuralı.** "En iyi antrenmanı yaptım, o zaman kesin
// kazanmalıyım" değil: "Doğru kararlarla şansımı yükselttim, ama
// karşımda başka bir insan var." Bu yüzden kazanma ihtimali hiçbir
// zaman 0 ya da 1 olmuyor; tavan ve taban var (§37).
//
// **Ne yapmıyor.** İkinci bir ders sistemi kurmuyor: teknik gelişim
// yine `MartialArtsEngine` derslerinden geliyor (§5). Yeni bir stamina
// motoru yok (§36); zaman maliyeti kampın parasında, sağlığında ve
// sakatlık riskinde duruyor.
//
// **Save-scum.** Müsabaka fırsatı üretildiği anda sonucun tohumu
// kayda yazılıyor (`PendingBout.seed`). Aynı müsabakayı kaydedip
// yükleyip tekrar oynamak aynı temel sonucu veriyor (§44). Oyunun
// genel rastgelelik mimarisine dokunulmadı.
//
// Bütün sayılar `prototypeOnly`'dir.
library;

import 'dart:math';

import '../../data/combat_circuit_catalog.dart';
import '../../data/economy.dart';
import '../../data/martial_arts_catalog.dart';
import '../../data/name_pool.dart';
import '../models/combat_career.dart';
import '../models/game_state.dart';
import '../models/interaction.dart';
import '../models/martial_progress.dart';
import 'martial_lesson_counter.dart';
import 'sport_family_support.dart';
import 'sport_rivalry.dart';
import 'sport_workload.dart';

/// Bir müsabakanın sonucu.
class BoutResult {
  const BoutResult({
    required this.state,
    required this.applied,
    required this.text,
    this.won = false,
    this.purse = 0,
    this.injury = InjurySeverity.yok,
    this.titleWon = false,
    this.promoted = false,
  });

  final GameState state;
  final bool applied;
  final String text;
  final bool won;
  final int purse;
  final InjurySeverity injury;
  final bool titleWon;
  final bool promoted;
}

abstract final class CombatCareerEngine {
  // =================================================================
  // Sayılar
  // =================================================================

  /// prototypeOnly: rekabete **başlamak** için gereken en az sağlık.
  ///
  /// Faho'nun kararı (Paket AM, §4): **80**. Eskiden 40'tı ve bu,
  /// sağlığı kötü bir karakterin profesyonel dövüş sporcusu olmasına
  /// izin veriyordu. Altı sanatın hepsinde geçerli.
  ///
  /// **Bu eşik yalnızca rekabetçi kariyere aittir.** Normal spor
  /// aktiviteleri (yürüyüş, esneme) ve dövüş sanatı **dersleri** bu
  /// eşikten etkilenmez (§14, §15): sağlığı 55 olan biri yürüyüşe
  /// çıkabilir, 60 olan biri teknik ders alabilir.
  static const int prototypeOnlyMinHealth = 80;

  /// prototypeOnly: **müsabakaya çıkmak** için gereken en az sağlık.
  ///
  /// Başlama eşiğinden bilerek düşük (§5): 85 sağlıkla kariyere başlayan
  /// sporcu sakatlanıp 72'ye düştü diye kariyerini kaybetmez, dövüşmeye
  /// devam eder. 70'in altına inerse **geçici** olarak müsabakaya
  /// çıkamaz; toparlanınca kapı yeniden açılır. Kayıt hiçbir durumda
  /// silinmez.
  static const int prototypeOnlyMinBoutHealth = 70;

  /// prototypeOnly: **pro/elit kademeye çıkmak** için gereken en az
  /// sağlık.
  ///
  /// §16: tekniği yetse bile fiziksel olarak o seviyeye çıkacak durumda
  /// olmayan sporcu terfi etmez. Kalıcı kilit değil — sağlık yeniden
  /// 80'e gelince kapı açılır.
  static const int prototypeOnlyMinEliteHealth = 80;

  /// prototypeOnly: bir yılda çıkılabilecek en fazla müsabaka.
  ///
  /// Kademenin kendi `yearlyChances` sınırı da var; bu genel tavan
  /// sanat değiştirerek sınırsız maç yapmayı engelliyor (§42).
  static const int prototypeOnlyMaxBoutsPerAge = 4;

  /// prototypeOnly: kamp tercihlerinin maliyeti (asgari ücret payı).
  static const Map<CampChoice, double> prototypeOnlyCampCost =
      <CampChoice, double>{
    CampChoice.dengeli: 0.05,
    CampChoice.yogun: 0.16,
    CampChoice.dinlen: 0.02,
  };

  /// prototypeOnly: kampın hazırlık payına katkısı.
  static const Map<CampChoice, double> prototypeOnlyCampPrep =
      <CampChoice, double>{
    CampChoice.dengeli: 0.0,
    CampChoice.yogun: 0.10,
    CampChoice.dinlen: -0.05,
  };

  /// prototypeOnly: yoğun kampın sakatlık riskine kattığı pay.
  static const double prototypeOnlyHardCampInjury = 0.06;

  /// prototypeOnly: dinlenmenin sakatlık riskinden düşürdüğü pay.
  static const double prototypeOnlyRestInjuryRelief = 0.04;

  /// prototypeOnly: antrenör kalitesinin hazırlığa katkısı.
  static const List<double> prototypeOnlyCoachPrep = <double>[0.0, 0.05, 0.10];

  /// prototypeOnly: antrenörün yıllık ücreti (asgari ücret payı).
  static const List<double> prototypeOnlyCoachCost = <double>[0.0, 0.10, 0.28];

  /// prototypeOnly: kazanma ihtimalinin tabanı ve tavanı.
  ///
  /// Hayat ortalama değildir: çok iyi sporcu da kaybedebilir,
  /// underdog da kazanabilir (§7, §37).
  static const double prototypeOnlyMinWinChance = 0.10;
  static const double prototypeOnlyMaxWinChance = 0.85;

  /// prototypeOnly: performansın en yüksek olduğu yaş ve düşüş hızı.
  static const int prototypeOnlyPeakAge = 27;
  static const double prototypeOnlyDeclinePerYear = 0.016;

  /// prototypeOnly: formun yıllık doğal kaybı.
  static const int prototypeOnlyFormDecayPerYear = 8;

  /// prototypeOnly: bir dersin forma katkısı.
  ///
  /// [prototypeOnlyFormDecayPerYear] ile birlikte okunur: yalnızca
  /// derslerden başabaş noktası `8 / 1,6 = 5` ders/yıl. Müsabakalar ve
  /// zirve kondisyonu da telafi ettiği için gerçek başabaş daha aşağıda.
  static const double prototypeOnlyFormPerLesson = 1.6;

  /// prototypeOnly: en üst teknik basamaktaki sporcunun sürdürdüğü
  /// kondisyonun forma katkısı.
  ///
  /// Öğrenecek ders kalmamış olmak çalışmayı bırakmak demek değil.
  static const int prototypeOnlyTopRankUpkeep = 7;

  /// prototypeOnly: mağlubiyette kaybedilen sıralama payı.
  static const int prototypeOnlyRankLossOnDefeat = 2;

  /// prototypeOnly: kademe atlamak için gereken galibiyet.
  static const int prototypeOnlyWinsToPromote = 3;

  /// prototypeOnly: kademe atlamak için gereken itibar (kademe başına).
  static const int prototypeOnlyReputationToPromote = 18;

  /// prototypeOnly: şampiyonluk maçına çağrılmak için gereken sıralama.
  ///
  /// Paket AN'de 2'den **1**'e çekildi. Sebep ölçüm: Q-184 #1'deki
  /// anahtar hatası düzeltilince form ayakta kaldı, sporcular daha çok
  /// maç yaptı ve adanmış 600 sporcu kohortunda şampiyonluk %18,2'den
  /// **%33,8**'e çıktı — "nadir ama imkânsız değil" bandının üstü.
  ///
  /// Kemer maçına kemerin **bir numaralı** rakibi çağrılıyor. Sıralama
  /// zincirin gerçekten çalışan tek halkası: rank ≤ 2'ye 600 sporcunun
  /// 363'ü, rank 1'e 290'ı ulaşıyor.
  static const int prototypeOnlyTitleShotRank = 1;

  /// prototypeOnly: şampiyonluk maçına çağrılmak için gereken itibar.
  ///
  /// **Bu eşik fiilen filtre değil ve yükseltilerek filtre yapılamaz.**
  /// Paket AN ölçümü: 600 adanmış sporcunun 575'i itibar 70'i, **530'u
  /// 100'ü** görüyor. İtibar yalnızca yukarı gidiyor (galibiyette
  /// +3+fameGain, mağlubiyette −2) ve 40 maçlık bir kariyerde 100'e
  /// doyuyor; eşiği 100 yapmak bile 600'ün 530'unu geçirir.
  ///
  /// Bu yüzden Paket AN sayıyı **değiştirmedi**: 90 yazmak filtre
  /// kurmuş gibi görünüp hiçbir şey yapmaz. Şart "spor çevresinde ad
  /// yapmış olmak" anlamını koruyor (acemi sporcu kemer maçına
  /// çağrılmıyor), ama seçici halka sıralama. İtibarın bir aşınması
  /// olmadığı için doyduğu gerçeği Q-186 #2'de Faho'da.
  static const int prototypeOnlyTitleShotReputation = 70;

  /// prototypeOnly: şartlar tuttuğunda unvan maçı çıkma ihtimali.
  ///
  /// Paket AN'de 0,40'tan **0,30**'a çekildi. Tek başına bir sayı
  /// düşürmek değil (§8): sıralama şartıyla birlikte çalışıyor. Kapı
  /// açık bir sporcu kariyeri boyunca ortalama birkaç fırsat gördüğü
  /// için 0,40 pratikte "kapı açıldıysa kemer maçı kesin" demeye
  /// yaklaşıyordu.
  static const double prototypeOnlyTitleShotChance = 0.30;

  /// D-148: sporun getirebileceği en yüksek Ün.
  ///
  /// Spor tek başına oyuncuyu Ün 100 yapmaz (§17); kamuoyu ünü için
  /// sosyal medya da gerekir. **Futbol aynı tavanı paylaşır** (D-141):
  /// iki sporun aynı sayıyı görmesi tutarlılıktır, kopya değil.
  /// Faho onayladı (5 Ekim 2026).
  static const int sportFameCap = 70;

  /// Sayaç anahtarları (`interactionCounts` her yıl sıfırlanır).
  static const String boutCounterKind = 'musabaka';
  static const String campCounterKind = 'kamp';

  // =================================================================
  // Okuma
  // =================================================================

  static CombatCareer? careerFor(GameState state, String artId) {
    for (final CombatCareer c in state.combatCareers) {
      if (c.artId == artId) return c;
    }
    return null;
  }

  /// Şu an rekabet eden (emekli olmamış) kariyer; yoksa `null`.
  static CombatCareer? activeCareer(GameState state) {
    for (final CombatCareer c in state.combatCareers) {
      if (!c.isRetired) return c;
    }
    return null;
  }

  static MartialProgress _progress(GameState state, String artId) {
    for (final MartialProgress p in state.martialArts) {
      if (p.artId == artId) return p;
    }
    return MartialProgress(artId: artId, lessons: 0);
  }

  static int boutsThisAge(GameState state) {
    int toplam = 0;
    for (final CombatCircuit c in kCombatCircuits) {
      toplam += state.interactionCount(c.artId, boutCounterKind);
    }
    return toplam;
  }

  // =================================================================
  // §3 — rekabete başlama
  // =================================================================

  /// Bu sanatta rekabete başlanabilir mi?
  static InteractionAvailability startAvailability(
    GameState state,
    MartialArt art,
  ) {
    final CombatCircuit? yol = combatCircuitFor(art.id);
    if (yol == null) {
      return const InteractionAvailability.blocked(
        'Bu dalda müsabaka yolu yok.',
      );
    }
    final CombatCareer? mevcut = careerFor(state, art.id);
    if (mevcut != null && !mevcut.isRetired) {
      return const InteractionAvailability.blocked(
        'Zaten bu dalda müsabakalara çıkıyorsun.',
      );
    }
    if (mevcut != null && mevcut.isRetired) {
      return InteractionAvailability.blocked(
        '${art.label} kariyerini bitirdin.',
      );
    }
    final CombatCareer? baska = activeCareer(state);
    if (baska != null) {
      return InteractionAvailability.blocked(
        'Zaten ${baska.art?.label ?? 'bir dalda'} müsabakalara çıkıyorsun. '
        'İki dalda birden rekabet edilmiyor.',
      );
    }
    final CombatTier ilk = yol.tiers.first;
    if (state.player.age < ilk.minAge) {
      return InteractionAvailability.blocked(
        '${ilk.minAge} yaşından itibaren müsabakaya çıkabilirsin.',
      );
    }
    final MartialProgress p = _progress(state, art.id);
    final int gereken = yol.minLevelFor(0);
    if (p.level < gereken) {
      return InteractionAvailability.blocked(
        'Önce tekniğini ilerletmelisin: en az "${art.ranks[gereken].name}" '
        'basamağı gerekiyor.',
      );
    }
    if (state.player.stats.health < prototypeOnlyMinHealth) {
      return InteractionAvailability.blocked(
        'Rekabetçi spor kariyerine başlamak için sağlığının en az '
        '$prototypeOnlyMinHealth olması gerekiyor; şu an '
        '${state.player.stats.health}.',
      );
    }
    return const InteractionAvailability.allowed();
  }

  /// Rekabetçi kariyer kapısının sağlık durumu — "73 / 80" gibi (§18).
  ///
  /// Ekranda gösterilir; oyuncu eksiğinin ne kadar olduğunu görsün.
  static String healthGateLabel(GameState state) =>
      '${state.player.stats.health} / $prototypeOnlyMinHealth';

  /// Sağlık şu an müsabakaya çıkmaya yetiyor mu (§5)?
  static bool canFightHealthWise(GameState state) =>
      state.player.stats.health >= prototypeOnlyMinBoutHealth;

  /// Rekabete başlar.
  static ({GameState state, bool applied, String text}) startCompeting(
    GameState state,
    MartialArt art,
  ) {
    final InteractionAvailability check = startAvailability(state, art);
    if (!check.isAllowed) {
      return (state: state, applied: false, text: check.reason!);
    }
    final CombatCircuit yol = combatCircuitFor(art.id)!;
    final CombatCareer yeni = CombatCareer(
      artId: art.id,
      startedCompetitiveAtAge: state.player.age,
      form: (40 + state.player.stats.health ~/ 4).clamp(0, 100),
    ).remember(
      state.player.age,
      '${yol.tiers.first.label} ile rekabete başladın.',
    );
    final String metin =
        'Salon hocan seni kenara çağırdı.\n\n'
        '"Artık sadece antrenman yapmanın zamanı geçti. Seni '
        '${yol.tiers.first.label.toLowerCase()} listesine yazdırmak '
        'istiyorum."';
    return (
      state: state.copyWith(
        combatCareers: List<CombatCareer>.unmodifiable(
          <CombatCareer>[...state.combatCareers, yeni],
        ),
      ),
      applied: true,
      text: metin,
    );
  }

  // =================================================================
  // §8 — rakipler
  // =================================================================

  static CombatOpponent _makeOpponent(
    CombatCareer career,
    CombatTier tier,
    int playerAge,
    Random rng,
  ) {
    final String ad = erkekIsimleri[rng.nextInt(erkekIsimleri.length)];
    final String soy = soyisimler[rng.nextInt(soyisimler.length)];
    final int guc =
        (tier.opponentRating + rng.nextInt(21) - 10).clamp(10, 98);
    final int yas = (playerAge + rng.nextInt(9) - 4).clamp(16, 44);
    return CombatOpponent(
      id: 'r${career.artId}_${career.opponents.length}_$playerAge',
      name: '$ad $soy',
      age: yas,
      rating: guc,
      wins: rng.nextInt(18),
      losses: rng.nextInt(9),
    );
  }

  /// Rakip seçer: bazen tanıdık bir yüz, bazen yeni biri (§8, §9).
  static CombatOpponent _pickOpponent(
    CombatCareer career,
    CombatTier tier,
    int playerAge,
    Random rng,
  ) {
    // Daha önce karşılaşılmış ve gücü bu kademeye yakın rakipler.
    //
    // Rakip de yaşlanıyor ve bir yaştan sonra havuzdan düşüyor
    // (Paket AL/2, §19); önemli rakipler ise oyuncuyla birlikte
    // güçlendiği için üst kademede de eşleşme bandına giriyor.
    final List<CombatOpponent> tanidik = career.opponents
        .where((CombatOpponent o) =>
            (o.rating - tier.opponentRating).abs() <= 18 &&
            o.metCount > 0 &&
            SportRivalry.isSelectable(o))
        .toList(growable: false);
    if (tanidik.isNotEmpty && rng.nextDouble() < 0.35) {
      return tanidik[rng.nextInt(tanidik.length)];
    }
    return _makeOpponent(career, tier, playerAge, rng);
  }

  // =================================================================
  // §43 — fırsat
  // =================================================================

  /// Bu yıl bu sporcuya müsabaka fırsatı çıkar mı? Çıkarsa üretir.
  ///
  /// Fırsat garanti değil: kademenin yıllık kontenjanı, yıllık tavan,
  /// sakatlık ve emeklilik kapatabilir (§43).
  static ({GameState state, PendingBout? bout, String? text}) offerBout(
    GameState state,
    Random rng,
  ) {
    final CombatCareer? kariyer = activeCareer(state);
    if (kariyer == null) return (state: state, bout: null, text: null);
    if (kariyer.pendingBout != null) {
      return (state: state, bout: kariyer.pendingBout, text: null);
    }
    if (kariyer.isInjured) return (state: state, bout: null, text: null);
    if (boutsThisAge(state) >= prototypeOnlyMaxBoutsPerAge) {
      return (state: state, bout: null, text: null);
    }
    final CombatCircuit? yol = combatCircuitFor(kariyer.artId);
    if (yol == null) return (state: state, bout: null, text: null);

    final int kademe = kariyer.tier.clamp(0, yol.tiers.length - 1);
    final CombatTier tier = yol.tiers[kademe];
    if (state.interactionCount(kariyer.artId, boutCounterKind) >=
        tier.yearlyChances) {
      return (state: state, bout: null, text: null);
    }
    if (state.player.age < tier.minAge) {
      return (state: state, bout: null, text: null);
    }

    // Fırsat her yıl çıkmaz: itibar ve form yükseldikçe daha sık çıkar.
    //
    // Tam zamanlı çalışan sporcu antrenmana ve müsabaka takvimine daha
    // az yetişir; fırsat ihtimali düşer ama **sıfırlanmaz**
    // (Paket AL/2, §21, §24). Kazanma ihtimaline doğrudan dokunulmadı
    // (§25): işin bedeli fırsattan ve formdan geliyor.
    final double sans =
        (0.45 + kariyer.reputation / 300 + kariyer.form / 400).clamp(0.3, 0.9) *
            SportWorkload.opportunityFactor(state);
    if (rng.nextDouble() > sans) {
      return (state: state, bout: null, text: null);
    }

    // Şampiyonluk maçı: en üst kademede, sıralaması yeterliyse.
    // Şampiyonluk maçına çağrılmak yalnızca sıralamayla olmuyor:
    // spor çevresinde gerçekten bir ad yapmak da gerekiyor. 600
    // sporcu ölçümünde tek başına sıralama şartı, kendini adamış
    // sporcuların dörtte birini şampiyon yapıyordu — §41'in istediği
    // "nadir ama imkânsız değil" bandının çok üstü.
    final bool unvan = kademe >= kTitleTier &&
        kariyer.ranking > 0 &&
        kariyer.ranking <= prototypeOnlyTitleShotRank &&
        kariyer.reputation >= prototypeOnlyTitleShotReputation &&
        rng.nextDouble() < prototypeOnlyTitleShotChance;

    final CombatOpponent rakip = _pickOpponent(
      kariyer,
      unvan
          ? CombatTier(
              label: tier.label,
              levelRatio: tier.levelRatio,
              minAge: tier.minAge,
              opponentRating: (tier.opponentRating + 16).clamp(10, 95),
              purseShare: tier.purseShare,
              yearlyChances: tier.yearlyChances,
              fameGain: tier.fameGain,
              injuryRisk: tier.injuryRisk,
            )
          : tier,
      state.player.age,
      rng,
    );

    final PendingBout bout = PendingBout(
      tier: kademe,
      // Unvan maçında rakip kaydına kademe yazılır: rekabetin gücü
      // hesabında "bir kez kemer için karşılaştık" bileşeni buradan
      // okunuyor (Paket AL/2, §16).
      opponent: unvan ? rakip.copyWith(tier: kTitleTier) : rakip,
      purse: unvan ? yol.titlePurse : tier.purse,
      seed: rng.nextInt(1 << 31),
      offeredAtAge: state.player.age,
      isTitle: unvan,
    );

    final String baslik = unvan ? yol.titleLabel : tier.label;
    final String tanidik = rakip.headToHead == null
        ? ''
        : ' ${rakip.name} tanıdık bir isim. ${rakip.headToHead}';
    final String metin = unvan
        ? 'Sıralaman tuttu: ${yol.titleLabel} için seni çağırdılar. '
            'Karşında ${rakip.name} var.$tanidik'
        : '$baslik için bir eşleşme çıktı: ${rakip.name}.$tanidik';

    return (
      state: _replace(state, kariyer.copyWith(pendingBout: bout)),
      bout: bout,
      text: metin,
    );
  }

  // =================================================================
  // §7 — müsabaka motoru
  // =================================================================

  /// Oyuncunun bu müsabakadaki gücü (0-100 ölçeğinde).
  ///
  /// Sonuç ne yalnızca zar ne yalnızca stat karşılaştırması: teknik,
  /// form, sağlık, deneyim, yaş ve hazırlık birlikte hesaplanıyor.
  static double playerStrength(
    GameState state,
    CombatCareer career,
    CampChoice camp,
  ) {
    final MartialArt? art = career.art;
    if (art == null) return 0;
    final MartialProgress p = _progress(state, career.artId);

    // Teknik: basamak merdivenindeki yer (en ağırlıklı bileşen).
    final double teknik = art.topLevel == 0
        ? 0
        : (p.level / art.topLevel).clamp(0.0, 1.0);

    final double form = career.form / 100;
    final double saglik = (state.player.stats.health / 100).clamp(0.0, 1.0);

    // Deneyim: ilk maçlar en çok şeyi öğretir, sonra doygunluk.
    final double deneyim = (career.totalBouts / 25).clamp(0.0, 1.0);

    // Yaş eğrisi: zirveden sonra yavaş düşüş, sanatın yıpratıcılığına
    // göre biraz farklı (§21). Sert kesim yok.
    final CombatCircuit? yol = combatCircuitFor(career.artId);
    final double yipranma = yol?.wearFactor ?? 1.0;
    final int yasFarki = state.player.age - prototypeOnlyPeakAge;
    final double yasPayi = yasFarki <= 0
        ? (1 + yasFarki * 0.010).clamp(0.72, 1.0)
        : (1 - yasFarki * prototypeOnlyDeclinePerYear * yipranma)
            .clamp(0.30, 1.0);

    // Hazırlık: kamp tercihi, antrenör ve (18 yaş altında) ekipman.
    //
    // Ekipman/turnuva yolu parası yetmeyen genç sporcu müsabakadan
    // men edilmiyor (Paket AL/2, §4): eskimiş ekipmanla ve uzun
    // yolculuktan sonra çıkıyor, hazırlığı bir miktar eksik kalıyor.
    final double hazirlik = 1 +
        (prototypeOnlyCampPrep[camp] ?? 0) +
        prototypeOnlyCoachPrep[career.coachLevel.clamp(0, 2)] -
        SportFamilySupport.gearPenalty(state, campCost(camp));

    // Sakatlık gölgesi: iyileşmiş ama izi kalmış olabilir.
    final double sakatlik = 1 - career.seriousInjuryCount * 0.05;

    final double ham = (teknik * 0.42 +
            form * 0.24 +
            saglik * 0.16 +
            deneyim * 0.10 +
            career.reputation / 100 * 0.08) *
        yasPayi *
        hazirlik *
        sakatlik.clamp(0.6, 1.0);

    return (ham * 100).clamp(1.0, 100.0);
  }

  /// Kazanma ihtimali. Asla 0 ya da 1 olmaz (§37).
  static double winChance(
    GameState state,
    CombatCareer career,
    PendingBout bout,
    CampChoice camp,
  ) {
    final double benim = playerStrength(state, career, camp);
    final double rakip = bout.opponent.rating.toDouble();
    // Lojistik eğri: fark büyüdükçe doygunluğa gider ama uçlara vurmaz.
    final double fark = (benim - rakip) / 18;
    final double ham = 1 / (1 + exp(-fark));
    return ham.clamp(prototypeOnlyMinWinChance, prototypeOnlyMaxWinChance);
  }

  /// Kamp tercihinin ücreti (₺).
  static int campCost(CampChoice camp) =>
      (Economy.netYearlyMinimumWage * (prototypeOnlyCampCost[camp] ?? 0))
          .round();

  /// Bekleyen müsabakayı oynar.
  static BoutResult fight(
    GameState state,
    CampChoice camp,
  ) {
    final CombatCareer? kariyer = activeCareer(state);
    if (kariyer == null) {
      return BoutResult(
        state: state,
        applied: false,
        text: 'Şu an bir müsabaka kariyerin yok.',
      );
    }
    final PendingBout? bout = kariyer.pendingBout;
    if (bout == null) {
      return BoutResult(
        state: state,
        applied: false,
        text: 'Bekleyen bir müsabaka yok.',
      );
    }
    // Sakatlık önce bakılır (§6): ciddi sakatlığı olan oyuncu sağlığı
    // 90 olsa bile dövüşemez ve bu durumda oyuncuya sağlık cümlesi
    // değil sakatlık cümlesi gösterilir. Sakatlık sisteminin üstüne
    // ikinci bir anlamsız ceza binmez; iki kapı ayrı ayrı durur.
    if (kariyer.isInjured) {
      return BoutResult(
        state: state,
        applied: false,
        text: 'Sakatlığın geçmeden müsabakaya çıkamazsın.',
      );
    }
    // Geçici sağlık engeli (§5). Kariyer **durur, silinmez**: kademe,
    // rekor, sıralama ve şampiyonluklar yerinde kalır.
    if (state.player.stats.health < prototypeOnlyMinBoutHealth) {
      return BoutResult(
        state: state,
        applied: false,
        text: 'Sağlığın şu an müsabakaya çıkacak durumda değil. '
            'Toparlanman gerekiyor: en az $prototypeOnlyMinBoutHealth '
            'sağlık gerekiyor, şu an ${state.player.stats.health}.',
      );
    }
    final int ucret = campCost(camp);

    // 18 yaş altında aile kampın bir kısmını üstlenmiş olabilir
    // (Paket AL/2, §1). Kredi varsa cepten çıkacak tutar azalır; yoksa
    // hiçbir şey değişmez. Yetişkinde kredi hiç oluşmadığı için bu
    // satırlar sessizce geçilir.
    final int cepten = SportFamilySupport.outOfPocketCamp(state, ucret);
    if (state.player.wallet < cepten) {
      return BoutResult(
        state: state,
        applied: false,
        text: '${camp.label} için $cepten ₺ gerekiyor; cüzdanın yetmiyor.',
      );
    }

    // Ekipman ve turnuva yolu: önce aile kredisi, sonra cüzdan.
    // Karşılanamıyorsa hiçbir şey alınmaz ve müsabaka yine yapılır;
    // bedel `playerStrength` içindeki hazırlık kesintisine yansımıştır.
    final ({GameState state, int paid}) ekipman =
        SportFamilySupport.chargeGear(state, ucret);
    final ({GameState state, int remaining}) kampOdeme =
        SportFamilySupport.spendCredit(
      ekipman.state,
      SportExpense.kamp,
      ucret,
    );
    final GameState taban = kampOdeme.state;

    // Sonuç tohumu fırsat üretilirken yazıldı: kaydet/yükle aynı
    // sonucu verir (§44). Hazırlık tercihi ihtimali değiştirir, zarı
    // değiştirmez.
    final Random rng = Random(bout.seed);
    final double sans = winChance(state, kariyer, bout, camp);
    final double zar = rng.nextDouble();
    final bool kazandi = zar < sans;
    final bool yakin = (zar - sans).abs() < 0.12;

    final CombatCircuit yol = combatCircuitFor(kariyer.artId)!;
    final CombatTier tier = yol.tiers[bout.tier.clamp(0, yol.tiers.length - 1)];

    // --- sakatlık (§18) --------------------------------------------
    final double sakatlikRiski = (tier.injuryRisk +
            (camp == CampChoice.yogun ? prototypeOnlyHardCampInjury : 0) -
            (camp == CampChoice.dinlen ? prototypeOnlyRestInjuryRelief : 0) +
            (state.player.age > 30 ? (state.player.age - 30) * 0.004 : 0) -
            kariyer.form / 1000)
        .clamp(0.02, 0.45);
    InjurySeverity sakatlik = InjurySeverity.yok;
    if (rng.nextDouble() < sakatlikRiski) {
      final double d = rng.nextDouble();
      sakatlik = d < 0.60
          ? InjurySeverity.hafif
          : d < 0.90
              ? InjurySeverity.orta
              : InjurySeverity.ciddi;
    }

    // --- kayıt güncelle --------------------------------------------
    final bool pro = kariyer.status == CompetitiveStatus.profesyonel;
    CombatCareer yeni = kariyer.copyWith(
      amateurWins: kariyer.amateurWins + (!pro && kazandi ? 1 : 0),
      amateurLosses: kariyer.amateurLosses + (!pro && !kazandi ? 1 : 0),
      proWins: kariyer.proWins + (pro && kazandi ? 1 : 0),
      proLosses: kariyer.proLosses + (pro && !kazandi ? 1 : 0),
      lastBoutAge: state.player.age,
      pendingBout: null,
    );

    // Form: kazanmak biraz taşır, yenilmek biraz düşürür.
    yeni = yeni.copyWith(
      form: (yeni.form + (kazandi ? 6 : -8) - (sakatlik.weight * 6))
          .clamp(0, 100),
      reputation: (yeni.reputation +
              (kazandi ? 3 + tier.fameGain : -2) +
              (bout.isTitle && kazandi ? 10 : 0))
          .clamp(0, 100),
    );

    // Sıralama: sadece yukarı giden merdiven değil (§22).
    //
    // İlk yazımda listeye 12. sıradan girip her galibiyette bir basamak
    // çıkılıyordu. 600 sporcu ölçümünde bu, şampiyonluğu pratikte
    // kapatıyordu: **tek** şampiyon çıktı. Sebep aritmetik — en zor
    // kademede kazanma oranı zaten düşükken 12'den 3'e inmek için
    // dokuz net galibiyet gerekiyordu ve her mağlubiyet iki basamak
    // geri atıyordu. Şimdi listeye 10. sıradan giriliyor ve alt
    // sıralarda galibiyet iki basamak kazandırıyor; zirveye yaklaştıkça
    // yine birer basamak. Şampiyonluk hâlâ nadir, ama imkânsız değil
    // (§41).
    int siralama = yeni.ranking;
    if (kazandi) {
      siralama = siralama == 0
          ? 10
          : (siralama - (siralama > 6 ? 2 : 1)).clamp(1, 20);
    } else {
      siralama = siralama == 0
          ? 0
          : (siralama + prototypeOnlyRankLossOnDefeat).clamp(1, 20);
    }
    yeni = yeni.copyWith(ranking: siralama);

    // --- para (§13) -------------------------------------------------
    // Kaybeden de eli boş dönmez ama payı küçüktür.
    final int odul = kazandi ? bout.purse : (bout.purse * 0.25).round();
    int cuzdan = taban.player.wallet - kampOdeme.remaining + odul;
    // Sakatlık masrafı: ciddi olan cepten de yakar.
    final int tedavi = sakatlik == InjurySeverity.yok
        ? 0
        : (Economy.netYearlyMinimumWage * 0.04 * sakatlik.weight).round();
    cuzdan -= tedavi;
    yeni = yeni.copyWith(careerEarnings: yeni.careerEarnings + odul);

    // --- sakatlık kaydı ---------------------------------------------
    if (sakatlik != InjurySeverity.yok) {
      yeni = yeni.copyWith(
        injury: sakatlik,
        injuryYearsLeft: sakatlik.weight,
        injuryCount: yeni.injuryCount + 1,
        seriousInjuryCount:
            yeni.seriousInjuryCount + (sakatlik == InjurySeverity.ciddi ? 1 : 0),
      );
    }

    // --- şampiyonluk (§23) ------------------------------------------
    bool unvanAlindi = false;
    if (bout.isTitle && kazandi) {
      unvanAlindi = true;
      yeni = yeni
          .copyWith(
            championships: yeni.championships + 1,
            isChampion: true,
            // Başarının tazeliği buradan okunuyor (Paket AL/2, §12).
            lastTitleAge: state.player.age,
          )
          .remember(
            state.player.age,
            '${yol.titleLabel} kazandın: ${bout.opponent.name}.',
          );
    } else if (bout.isTitle && !kazandi && yeni.isChampion) {
      yeni = yeni.copyWith(isChampion: false).remember(
            state.player.age,
            'Unvanını ${bout.opponent.name} karşısında kaybettin.',
          );
    }

    // --- kademe atlama ----------------------------------------------
    bool yukseldi = false;
    String? terfiEngeli;
    if (kazandi && bout.tier == yeni.tier && yeni.tier < yol.tiers.length - 1) {
      final int kademeGalibiyeti = yeni.totalWins;
      final MartialProgress p = _progress(state, kariyer.artId);
      final int gerekenSeviye = yol.minLevelFor(yeni.tier + 1);
      final CombatTier sonraki = yol.tiers[yeni.tier + 1];
      // Kademe atlamak yalnızca galibiyet saymakla olmuyor: o
      // kademede gerçekten iz bırakmak gerekiyor. İtibar galibiyetle
      // artıp mağlubiyetle düştüğü için bu, "kolay rakip topla"maya
      // karşı doğal bir süzgeç.
      final bool sporculukTuttu = kademeGalibiyeti >=
              prototypeOnlyWinsToPromote * (yeni.tier + 1) &&
          yeni.reputation >= prototypeOnlyReputationToPromote * (yeni.tier + 1) &&
          p.level >= gerekenSeviye &&
          state.player.age >= sonraki.minAge;

      // Pro/elit kademeye fiziksel uygunluk (§16). Bu kapı **kalıcı
      // değil**: sağlık yeniden eşiğe gelince terfi yolu açılır ve
      // kariyer kaydına hiç dokunulmaz.
      final bool elitKademe = yeni.tier + 1 >= yol.turnsProAtTier;
      final bool fizikselTuttu = !elitKademe ||
          state.player.stats.health >= prototypeOnlyMinEliteHealth;
      if (sporculukTuttu && !fizikselTuttu) {
        terfiEngeli = 'Teknik seviyen yeterli ama fiziksel olarak bu '
            'seviyeye çıkacak durumda değilsin: ${sonraki.label} için '
            'en az $prototypeOnlyMinEliteHealth sağlık gerekiyor, şu an '
            '${state.player.stats.health}.';
      }
      if (sporculukTuttu && fizikselTuttu) {
        yeni = yeni.copyWith(tier: yeni.tier + 1, ranking: 0).remember(
              state.player.age,
              '${sonraki.label} kademesine çıktın.',
            );
        yukseldi = true;
        if (yeni.tier >= yol.turnsProAtTier &&
            yeni.status != CompetitiveStatus.profesyonel) {
          yeni = yeni
              .copyWith(status: CompetitiveStatus.profesyonel)
              .remember(state.player.age, '${yol.proLabel} oldun.');
        }
      }
    }

    // --- rakip kaydı (§9) -------------------------------------------
    yeni = _rememberOpponent(yeni, bout.opponent, kazandi);

    // --- rekabetin üne katkısı (Paket AL/2, §17) --------------------
    //
    // Yalnızca **kazanılan** ve gerçekten **önemli** rekabet maçları
    // sayılır. Aynı rakibe tekrar çıkmak her seferinde daha az ün
    // getirir (azalan getiri) ve yıllık bir tavan var; böylece tek bir
    // rakiple ün çiftliği kurulamıyor.
    int rekabetUnu = 0;
    final CombatOpponent? guncelRakip = _opponentById(yeni, bout.opponent.id);
    if (guncelRakip != null) {
      rekabetUnu = SportRivalry.fameBonus(
        state: state,
        career: yeni,
        opponent: guncelRakip,
        won: kazandi,
      );
      if (rekabetUnu > 0) {
        yeni = _markFameAward(yeni, guncelRakip.id).remember(
          state.player.age,
          '${guncelRakip.name} ile rekabetiniz konuşulur oldu.',
        );
      }
    }

    // İlk galibiyet/mağlubiyet kariyer geçmişine yazılır (§27).
    if (kazandi && yeni.totalWins == 1) {
      yeni = yeni.remember(state.player.age, 'İlk galibiyetini aldın.');
    } else if (!kazandi && yeni.totalLosses == 1) {
      yeni = yeni.remember(state.player.age, 'İlk mağlubiyetini gördün.');
    }
    if (sakatlik == InjurySeverity.ciddi) {
      yeni = yeni.remember(state.player.age, 'Ciddi bir sakatlık geçirdin.');
    }

    // --- durum -------------------------------------------------------
    GameState next = _replace(taban, yeni).copyWith(
      player: taban.player.copyWith(
        wallet: cuzdan,
        stats: taban.player.stats.gain(
          happiness: kazandi ? 5 : -4,
          health: -sakatlik.weight * 3,
        ),
      ),
      interactionCounts: <String, int>{
        ...taban.interactionCounts,
        GameState.interactionKey(kariyer.artId, boutCounterKind):
            taban.interactionCount(kariyer.artId, boutCounterKind) + 1,
      },
    );
    next = _applySportFame(
      next,
      (kazandi ? tier.fameGain : 0) + rekabetUnu,
      bout.isTitle,
    );
    // Yıllık rekabet ünü tavanının sayacı.
    next = SportRivalry.markFame(next, rekabetUnu);

    return BoutResult(
      state: next,
      applied: true,
      text: _boutStory(
        bout: bout,
        won: kazandi,
        close: yakin,
        injury: sakatlik,
        titleWon: unvanAlindi,
        promoted: yukseldi,
        circuit: yol,
        promotionBlocked: terfiEngeli,
      ),
      won: kazandi,
      purse: odul,
      injury: sakatlik,
      titleWon: unvanAlindi,
      promoted: yukseldi,
    );
  }

  // =================================================================
  // §11 — sonucu anlatan metin
  // =================================================================

  static String _boutStory({
    required PendingBout bout,
    required bool won,
    required bool close,
    required InjurySeverity injury,
    required bool titleWon,
    required bool promoted,
    required CombatCircuit circuit,
    String? promotionBlocked,
  }) {
    final StringBuffer b = StringBuffer();
    b.writeln('Rakibin ${bout.opponent.name}.');
    b.writeln();
    if (won && close) {
      b.writeln('Maç başa baş gitti. Son bölümde bir adım önde bitirdin.');
    } else if (won) {
      b.writeln(
        'İlk bölümde tempoyu sen kurdun. Rakibin toparlanamadı.',
      );
    } else if (close) {
      b.writeln('Maç başa baş gitti. Son bölümde kontrolü kaybettin.');
    } else {
      b.writeln(
        'Rakibin senden daha hazırdı. Geriye düştün ve açığı kapatamadın.',
      );
    }
    b.writeln();
    b.writeln(won ? 'Sonuç: kazandın.' : 'Sonuç: kaybettin.');
    if (titleWon) {
      b.writeln();
      b.writeln('${circuit.titleLabel} artık senin.');
    }
    if (promoted) {
      b.writeln();
      b.writeln('Bir üst kademeye çıktın.');
    }
    // §16: terfi hakkı doğdu ama sağlık yetmedi. Oyuncu sessizce
    // bekletilmez, sebebi yazılır.
    if (promotionBlocked != null) {
      b.writeln();
      b.writeln(promotionBlocked);
    }
    if (injury != InjurySeverity.yok) {
      b.writeln();
      b.writeln(
        injury == InjurySeverity.hafif
            ? 'Küçük bir sakatlıkla çıktın; birkaç hafta ağrıyacak.'
            : injury == InjurySeverity.orta
                ? 'Sakatlandın. Doktor bir süre dinlenmeni söyledi.'
                : 'Ciddi bir sakatlık aldın. Bu, bir süre müsabaka '
                    'demek değil.',
      );
    }
    return b.toString().trim();
  }

  // =================================================================
  // Yardımcılar
  // =================================================================

  static CombatCareer _rememberOpponent(
    CombatCareer career,
    CombatOpponent rakip,
    bool playerWon,
  ) {
    final List<CombatOpponent> liste = <CombatOpponent>[];
    bool bulundu = false;
    for (final CombatOpponent o in career.opponents) {
      if (o.id == rakip.id) {
        bulundu = true;
        liste.add(o.copyWith(
          metCount: o.metCount + 1,
          playerWins: o.playerWins + (playerWon ? 1 : 0),
          playerLosses: o.playerLosses + (playerWon ? 0 : 1),
          wins: o.wins + (playerWon ? 0 : 1),
          losses: o.losses + (playerWon ? 1 : 0),
        ));
      } else {
        liste.add(o);
      }
    }
    if (!bulundu) {
      liste.add(rakip.copyWith(
        metCount: 1,
        playerWins: playerWon ? 1 : 0,
        playerLosses: playerWon ? 0 : 1,
      ));
    }
    // Liste şişmesin: en çok karşılaşılan on rakip tutulur.
    liste.sort((CombatOpponent a, CombatOpponent b) =>
        b.metCount.compareTo(a.metCount));
    return career.copyWith(
      opponents: List<CombatOpponent>.unmodifiable(liste.take(10)),
    );
  }

  static CombatOpponent? _opponentById(CombatCareer career, String id) {
    for (final CombatOpponent o in career.opponents) {
      if (o.id == id) return o;
    }
    return null;
  }

  /// Bu rekabetten ün alındığını rakibin kaydına yazar.
  ///
  /// Sayaç oyuncunun değil **rakibin** kaydında durur; azalan getiri
  /// böylece rekabete özgü olur ve kaydet/yükle ile sıfırlanamaz.
  static CombatCareer _markFameAward(CombatCareer career, String id) =>
      career.copyWith(
        opponents: List<CombatOpponent>.unmodifiable(<CombatOpponent>[
          for (final CombatOpponent o in career.opponents)
            if (o.id == id) o.copyWith(fameAwards: o.fameAwards + 1) else o,
        ]),
      );

  static GameState _replace(GameState state, CombatCareer career) =>
      state.copyWith(
        combatCareers: List<CombatCareer>.unmodifiable(<CombatCareer>[
          for (final CombatCareer c in state.combatCareers)
            if (c.artId == career.artId) career else c,
        ]),
      );

  /// Spor başarısının üne katkısı (§17).
  ///
  /// Ün tavanı var: üç amatör maçla Ün 100 olmaz ve spor tek başına
  /// kamuoyu ününü doldurmaz.
  static GameState _applySportFame(GameState state, int gain, bool title) {
    final int toplam = gain + (title ? 12 : 0);
    if (toplam <= 0) return state;
    final int mevcut = state.player.fame ?? 0;
    final int yeni = (mevcut + toplam).clamp(0, sportFameCap);
    if (yeni <= mevcut) return state;
    return state.copyWith(player: state.player.copyWith(fame: yeni));
  }
  // =================================================================
  // §5 — antrenör
  // =================================================================

  /// Antrenör kalitesinin yıllık ücreti (₺).
  static int coachCost(int level) => (Economy.netYearlyMinimumWage *
          prototypeOnlyCoachCost[level.clamp(0, 2)])
      .round();

  static const List<String> coachLabels = <String>[
    'Kulüp hocası',
    'Deneyimli koç',
    'Elit koç',
  ];

  /// Antrenör değiştirir. Daha iyi koç daha iyi hazırlık demek, garanti
  /// galibiyet demek değil (§28).
  static ({GameState state, bool applied, String text}) setCoach(
    GameState state,
    int level,
  ) {
    final CombatCareer? kariyer = activeCareer(state);
    if (kariyer == null) {
      return (state: state, applied: false, text: 'Müsabaka kariyerin yok.');
    }
    final int yeni = level.clamp(0, 2);
    if (yeni == kariyer.coachLevel) {
      return (
        state: state,
        applied: false,
        text: 'Zaten ${coachLabels[yeni].toLowerCase()} ile çalışıyorsun.'
      );
    }
    // Elit koç ancak üst kademede kabul eder: para tek başına yetmez.
    if (yeni == 2 && kariyer.tier < 2) {
      return (
        state: state,
        applied: false,
        text: 'Elit koçlar bu seviyedeki sporcularla çalışmıyor.'
      );
    }
    return (
      state: _replace(state, kariyer.copyWith(coachLevel: yeni)),
      applied: true,
      text: '${coachLabels[yeni]} ile çalışmaya başladın. '
          'Yıllık ücreti maçlarından kesilecek.',
    );
  }

  // =================================================================
  // §19 — sakatken devam kararı
  // =================================================================

  /// Sakatken riski göze alıp müsabakaya devam eder.
  ///
  /// Karar gerçekten anlamlı: kapı açılır ama ciddi sakatlık ihtimali
  /// belirgin biçimde artar ve bu, kayda ciddi sakatlık olarak geçer.
  static ({GameState state, bool applied, String text}) pushThroughInjury(
    GameState state,
    Random rng,
  ) {
    final CombatCareer? kariyer = activeCareer(state);
    if (kariyer == null || !kariyer.isInjured) {
      return (state: state, applied: false, text: 'Geçmeyen bir sakatlığın yok.');
    }
    final double risk = 0.18 + kariyer.injury.weight * 0.12;
    if (rng.nextDouble() < risk) {
      final CombatCareer kotu = kariyer
          .copyWith(
            injury: InjurySeverity.ciddi,
            injuryYearsLeft: InjurySeverity.ciddi.weight,
            seriousInjuryCount: kariyer.seriousInjuryCount + 1,
            form: kariyer.form - 20,
          )
          .remember(
            state.player.age,
            'Sakatken devam ettin ve durum ağırlaştı.',
          );
      return (
        state: _replace(state, kotu).copyWith(
          player: state.player.copyWith(
            stats: state.player.stats.gain(health: -8, happiness: -6),
          ),
        ),
        applied: true,
        text: 'Riski göze aldın ve sakatlık ağırlaştı. '
            'Bu sezon senin için bitti.',
      );
    }
    return (
      state: _replace(
        state,
        kariyer.copyWith(injury: InjurySeverity.yok, injuryYearsLeft: 0),
      ),
      applied: true,
      text: 'Riski göze aldın ve tuttu. Ağrıyla da olsa çalışmaya '
          'devam ediyorsun.',
    );
  }

  // =================================================================
  // §31 — emeklilik
  // =================================================================

  /// Emeklilik teklifi çıkmalı mı, çıkacaksa gerekçesi ne?
  static RetirementReason? retirementPressure(GameState state) {
    final CombatCareer? k = activeCareer(state);
    if (k == null) return null;
    if (k.seriousInjuryCount >= 2 && k.injury == InjurySeverity.ciddi) {
      return RetirementReason.sakatlik;
    }
    final int yas = state.player.age;
    if (yas >= 34 && k.form < 45) return RetirementReason.yas;
    if (yas >= 40) return RetirementReason.yas;
    return null;
  }

  /// Spordan çekilir.
  static ({GameState state, bool applied, String text}) retire(
    GameState state,
    RetirementReason reason,
  ) {
    final CombatCareer? kariyer = activeCareer(state);
    if (kariyer == null) {
      return (state: state, applied: false, text: 'Müsabaka kariyerin yok.');
    }
    final CombatCircuit? yol = combatCircuitFor(kariyer.artId);
    final CombatCareer emekli = kariyer
        .copyWith(
          status: CompetitiveStatus.emekli,
          retiredAtAge: state.player.age,
          retirementReason: reason,
          pendingBout: null,
        )
        .remember(
          state.player.age,
          'Kariyerini bitirdin: ${kariyer.record}'
          '${kariyer.championships > 0 ? ', ${kariyer.championships} şampiyonluk' : ''}.',
        );
    final String metin = 'Yıllardır çıktığın ${yol?.artId == 'boks' ? 'ringe' : 'alana'} '
        'bu kez seyirci olarak baktın.\n\n'
        '${yol?.proLabel ?? 'Sporcu'} kariyerini bitirdin. '
        'Rekorun: ${kariyer.record}.';
    return (
      state: _replace(state, emekli),
      applied: true,
      text: metin,
    );
  }

  // =================================================================
  // Yıllık akış
  // =================================================================

  /// Yaş ilerlerken kariyeri güncelle: form, sakatlık, koç ücreti,
  /// sıralama aşınması.
  ///
  /// Hayat günlüğüne yazılacak satırlar döner.
  static ({GameState state, List<String> lines}) advanceYear(
    GameState state,
    int newAge,
    Random rng,
  ) {
    final CombatCareer? kariyer = activeCareer(state);
    if (kariyer == null) return (state: state, lines: const <String>[]);

    final List<String> satirlar = <String>[];
    CombatCareer k = kariyer;
    GameState next = state;

    // Sakatlık iyileşmesi (§20).
    if (k.injuryYearsLeft > 0) {
      final int kalan = k.injuryYearsLeft - 1;
      k = k.copyWith(injuryYearsLeft: kalan);
      if (kalan == 0) {
        satirlar.add('${k.injury.label} geçti, yeniden çalışmaya başladın.');
        k = k.copyWith(injury: InjurySeverity.yok, form: k.form - 5);
      } else {
        satirlar.add('Sakatlığın sürüyor; bu yıl müsabakaya çıkamadın.');
      }
    }

    // Form: doğal kayıp; çalışmak telafi eder.
    //
    // İlk yazımda telafi **yalnızca** o yıl alınan derslerden geliyordu.
    // 600 sporcu ölçümü bunun yan etkisini gösterdi: en üst teknik
    // basamağa çıkan sporcuya `MartialArtsEngine` artık ders vermiyor
    // ("öğrenecek ders kalmadı"), dolayısıyla telafi sıfırlanıyor, form
    // çöküyor ve sporcu otuzlu yaşların başında emekliliğe itiliyordu.
    // Gerçekte teknik öğrenmeyi bitiren sporcu çalışmayı bırakmaz.
    // Artık iki şey daha telafi ediyor: o yıl çıkılan müsabakalar ve
    // zirvedeki sporcunun sürdürdüğü kondisyon.
    //
    // PAKET AN — ANAHTAR HATASI DÜZELTİLDİ.
    //
    // Burası `interactionCount(artId, 'dovus')` diye okuyordu; yazan
    // taraf `interactionKey('dovus', artId)` yazıyordu. Anahtar sırası
    // ters olduğu için `dersler` her yıl 0 dönüyor ve "çalışan sporcu
    // formunu daha iyi korur" kuralı Paket AL'den beri hiç işlemiyordu.
    // Artık iki taraf da [MartialLessonCounter] kullanıyor; anahtar tek
    // yerde kuruluyor, elle tekrar yazılmıyor (§1).
    final int dersler = MartialLessonCounter.read(state, k.artId);
    final int macSayisi = state.interactionCount(k.artId, boutCounterKind);
    final MartialProgress teknik = _progress(state, k.artId);
    final int zirveBakimi = teknik.isTopRank ? prototypeOnlyTopRankUpkeep : 0;
    //
    // Çalışan sporcunun telafisi daha az: işten artan zamanla
    // kondisyonu korumak zorlaşıyor (Paket AL/2, §21). Telafi 0'ın
    // altına inmiyor; yani iş formu doğrudan eritmiyor, korumayı
    // zorlaştırıyor. Kazanma ihtimaline doğrudan bir kesinti yok (§25).
    final int isYuku = SportWorkload.formUpkeepCost(state);
    // Ders katsayısı Paket AN'de 1,2'den **1,6**'ya çıkarıldı.
    //
    // Sebep ölçüm. Q-184 #1'deki anahtar hatası düzeltilince telafi ilk
    // defa gerçekten çalıştı ve 150 sporcu × 4 bandında şu çıktı:
    //
    //   ders/yıl      0     2     4     8
    //   kariyer sonu form   2,0   3,3  14,7  60,2
    //
    // Bu azalan getiri değil, **eşik etkisi**: yıllık kayıp 8 olduğu için
    // telafi 8'i geçene kadar form çöküyor, geçtiği anda tırmanıyor.
    // 1,2 katsayısında yalnızca derslerden başabaş noktası 8/1,2 ≈ 6,7
    // derse denk geliyordu; yılda 4 ders alan sporcu "aktif biçimde
    // antrenman yapıyor" olmasına rağmen formunu tutamıyordu (§4'ün ilk
    // cümlesi). 1,6'da başabaş 5 derse iniyor ve uçurum yumuşuyor.
    //
    // Tavan yerinde: telafi 18'i geçmiyor, o yüzden ders sayısını
    // artırmak formu 100'e kilitlemiyor (§4, §12).
    final int telafi =
        ((dersler * prototypeOnlyFormPerLesson).round() +
                macSayisi * 4 +
                zirveBakimi -
                isYuku)
            .clamp(0, 18);
    int yeniForm = k.form - prototypeOnlyFormDecayPerYear + telafi;
    if (state.player.stats.health < 50) yeniForm -= 5;
    k = k.copyWith(form: yeniForm.clamp(0, 100));

    // Koç ücreti: seçilen kalite her yıl para ister (§28).
    //
    // 18 yaş altında aile bu kalemi üstlenmiş olabilir; kredi varsa
    // önce o harcanır (Paket AL/2, §1, §3).
    if (k.coachLevel > 0) {
      final ({GameState state, int remaining}) kocOdeme =
          SportFamilySupport.spendCredit(
        next,
        SportExpense.koc,
        coachCost(k.coachLevel),
      );
      next = kocOdeme.state;
      final int ucret = kocOdeme.remaining;
      if (next.player.wallet >= ucret) {
        next = next.copyWith(
          player: next.player.copyWith(wallet: next.player.wallet - ucret),
        );
      } else {
        k = k.copyWith(coachLevel: 0);
        satirlar.add('Koçunun ücretini karşılayamadın; kulüp hocasına '
            'geri döndün.');
      }
    }

    // Uzun ara sıralamayı aşındırır (§22).
    final int sonMac = k.lastBoutAge ?? k.startedCompetitiveAtAge;
    if (newAge - sonMac >= 2 && k.ranking > 0) {
      k = k.copyWith(ranking: (k.ranking + 3).clamp(1, 20));
      if (k.ranking >= 20 && k.isChampion) {
        k = k.copyWith(isChampion: false);
        satirlar.add('Uzun süre müsabakaya çıkmadığın için unvanın '
            'boşa düştü.');
      }
    }

    // Rakipler de yaşlanır; önemli rakipler oyuncuyla birlikte
    // güçlenir (Paket AL/2, §19).
    k = SportRivalry.advanceRivals(k, rng);

    return (state: _replace(next, k), lines: satirlar);
  }

  // =================================================================
  // §15 — sponsorluk
  // =================================================================

  /// Spor sponsorluğu teklifi gelir mi?
  ///
  /// Bedava para değil: başarı, kademe, itibar ve kitle birlikte
  /// aranıyor. Yalnızca ün ya da yalnızca galibiyet yetmiyor.
  static ({GameState state, int fee, String? text}) offerSportSponsor(
    GameState state,
    Random rng,
  ) {
    final CombatCareer? k = activeCareer(state);
    if (k == null || k.isRetired) return (state: state, fee: 0, text: null);
    if (k.tier < 2) return (state: state, fee: 0, text: null);
    if (k.reputation < 35) return (state: state, fee: 0, text: null);

    final int un = state.player.fame ?? 0;
    final double sans =
        (k.reputation / 260 + un / 400 + k.championships * 0.08).clamp(0.0, 0.5);
    if (rng.nextDouble() > sans) return (state: state, fee: 0, text: null);

    final int ucret = (Economy.netYearlyMinimumWage *
            (0.12 + k.tier * 0.10 + k.championships * 0.15))
        .round();
    final CombatCareer yeni = k
        .copyWith(sponsorEarnings: k.sponsorEarnings + ucret)
        .remember(state.player.age, 'Bir spor markası seninle anlaştı.');
    return (
      state: _replace(state, yeni).copyWith(
        player: state.player.copyWith(
          wallet: state.player.wallet + ucret,
        ),
      ),
      fee: ucret,
      text: 'Bir spor markası seninle anlaşmak istedi. '
          'Sözleşme karşılığında $ucret ₺ aldın.',
    );
  }

  // =================================================================
  // §30 — eğitmenliğe geçiş
  // =================================================================

  /// Emekli sporcu eğitmenliğe doğal geçiş yapabiliyor mu?
  ///
  /// Mevcut `instructorFromLevel` şartı **bozulmadı**: teknik basamak
  /// yine aranıyor. Kariyer yalnızca "bu kapı sana açık" bilgisini
  /// gösteriyor.
  static String? instructorHint(GameState state) {
    final CombatCareer? k = state.combatCareers.isEmpty
        ? null
        : state.combatCareers.firstWhere(
            (CombatCareer c) => c.isRetired,
            orElse: () => state.combatCareers.first,
          );
    if (k == null || !k.isRetired) return null;
    final MartialArt? art = k.art;
    if (art == null) return null;
    final MartialProgress p = _progress(state, k.artId);
    if (p.level < art.instructorFromLevel) return null;
    return '${art.label} eğitmenliğine başvurabilirsin.';
  }
}
