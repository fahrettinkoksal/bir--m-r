/// Anne ve babanın ayrılması (Paket AO, §1-§6).
///
/// Paket AO öncesinde oyuncunun çocukluk ailesi **sonsuza kadar birlikte
/// kalıyordu**: `ParentalStatus.evli` bir kez kurulduktan sonra hiçbir
/// kod onu değiştirmiyordu. `step_parents.dart` kendi yorumunda bunu
/// açıkça söylüyordu — "ebeveynlerin boşanması henüz modellenmiyor".
///
/// **Ne yapar:** her ailenin kendi **birliktelik dayanıklılığı** vardır;
/// bazı ailelerde ayrılık yaşanır, çoğunda yaşanmaz. Ayrılık gerçek bir
/// durum değişikliğidir: [ParentalStatus.bosanmis] yazılır, hane ayrılır,
/// oyuncu bir ebeveynle kalır.
///
/// **Ne yapmaz:** kimseyi listeden silmez (iki ebeveyn de kalır ve anne/
/// baba olmaya devam eder — akrabalık boşanmayla silinmez, §2), her yıl
/// zar atıp her aileyi dağıtmaz, ve düz bir "%10 boşanma" oranı
/// uygulamaz (§1).
///
/// Bütün sayılar `prototypeOnly`'dir.
library;

import 'dart:math';

import '../models/game_state.dart';
import '../models/life_log.dart';
import '../models/parental_status.dart';
import '../models/pending_notice.dart';
import '../models/person.dart';
import '../models/relation.dart';
import '../models/wealth.dart';

/// Ayrılıktan sonra oyuncunun hangi ebeveynle kalacağı sorulduğunda
/// bekleyen karar.
enum DivorceHouseholdChoice { anne, baba }

abstract final class ParentDivorce {
  /// prototypeOnly: ayrılığın görülebileceği en küçük oyuncu yaşı.
  ///
  /// Daha küçük yaşta olan bir ayrılık oyuncunun hatırlayabileceği bir
  /// şey değil; hikâye olarak anlatılamaz.
  static const int prototypeOnlyMinAge = 4;

  /// prototypeOnly: bu yaştan sonra çocukluk ailesinin ayrılması artık
  /// oyuncunun hayatının konusu olmaktan çıkar.
  static const int prototypeOnlyMaxAge = 45;

  /// prototypeOnly: oyuncuya "kiminle kalacaksın?" sorulan en küçük yaş.
  ///
  /// Altında mantıklı bir hane kendiliğinden seçilir (§4): küçük çocuğa
  /// bu karar sorulmaz.
  static const int prototypeOnlyChoiceAge = 12;

  /// prototypeOnly: bu yaştan sonra oyuncu zaten kendi hayatını kurmuş
  /// sayılır; hane sorusu sorulmaz.
  static const int prototypeOnlyOwnHouseholdAge = 24;

  /// prototypeOnly: en dayanıksız ailede bile yıllık ayrılık ihtimalinin
  /// üst sınırı.
  ///
  /// Düz oran **değildir**: her ailenin kendi dayanıklılığı bu tavanı
  /// aşağı çeker ([resilience]).
  static const double prototypeOnlyMaxYearlyChance = 0.055;

  /// prototypeOnly: ayrılığın oyuncuya mutluluk etkisinin tabanı.
  ///
  /// Sabit bir sayı değil: yaşa ve ebeveynle olan yakınlığa göre
  /// ölçeklenir (§5).
  static const int prototypeOnlyBaseHappinessHit = 18;

  // =================================================================
  // §1 — birliktelik dayanıklılığı
  // =================================================================

  /// Bu ailenin **birliktelik dayanıklılığı** (0..1). Yüksekse ayrılmaz.
  ///
  /// Hayat başında bir kez üretilip kayda yazılmaz; ebeveynlerin kalıcı
  /// kimliklerinden **türetilir**. Böylece aynı hayatta hep aynı değeri
  /// verir, kayıt dosyasına yeni alan eklemeye gerek kalmaz ve eski
  /// kayıtlar da sorunsuz çalışır (§47).
  ///
  /// Etkileyenler (§1): ailenin ekonomik baskısı, ebeveynlerin kendi
  /// mutluluğu, oyuncuyla aralarındaki bağ ve kimlikten gelen küçük bir
  /// rastgelelik. Gereksiz bir evlilik simülasyonu kurulmaz.
  static double resilience(GameState state) {
    final Person? anne = _parent(state, RelationType.anne);
    final Person? baba = _parent(state, RelationType.baba);
    if (anne == null || baba == null) return 1;

    double taban = 0.50;

    // Ekonomik baskı: dar gelirli hanede ayrılık daha sık, varlıklıda
    // daha seyrek. Bu bir yargı değil, baskının modellenmesi.
    final WealthTier? refah = anne.wealth ?? baba.wealth;
    taban += switch (refah) {
      WealthTier.cokYoksul => -0.16,
      WealthTier.yoksul => -0.10,
      WealthTier.ortaHalli => 0.0,
      WealthTier.varlikli => 0.07,
      WealthTier.cokVarlikli => 0.10,
      null => 0.0,
    };

    // Ebeveynlerin kendi mutluluğu.
    final double mutlulukOrt = (anne.happiness + baba.happiness) / 2;
    taban += (mutlulukOrt - 50) / 250; // ±0,2

    // Evde huzur: oyuncuyla araları çok bozuksa ev de gergindir.
    final double bagOrt = (anne.bond + baba.bond) / 2;
    taban += (bagOrt - 50) / 500; // ±0,1

    // Aileye özgü sabit rastgelelik: aynı hayat hep aynı ailedir.
    //
    // DİKKAT — burada önce **kimlikler** kullanıldı ve bu bir hataydı:
    // kişi kimlikleri hayattan hayata değişmiyor ('anne-0', 'baba-0'),
    // dolayısıyla terim her hayatta aynı değeri veriyordu ve hiçbir şey
    // katmıyordu. Test bunu yakaladı (25 ailede tek bir dayanıklılık
    // değeri çıktı).
    //
    // Ad havuzdan hayat başında çekiliyor ve hayat boyunca değişmiyor:
    // hem hayattan hayata **gerçekten** değişen hem de kayıt/yükleme
    // sonrası aynı kalan bir kaynak.
    final int tohum =
        ('${anne.firstName}|${anne.lastName}|${baba.firstName}|'
                '${baba.lastName}')
            .hashCode
            .abs();
    taban += ((tohum % 41) - 20) / 100; // ±0,2

    return taban.clamp(0.05, 0.95);
  }

  /// Bu yıl ayrılık olur mu?
  static bool _rollsThisYear(GameState state, int newAge, Random rng) {
    final double sans =
        prototypeOnlyMaxYearlyChance * (1 - resilience(state));
    return rng.nextDouble() < sans;
  }

  // =================================================================
  // §2, §3 — ayrılığın kendisi
  // =================================================================

  /// Bu yıl anne ve baba ayrılır mı? Ayrılırsa durumu günceller.
  ///
  /// Koşullar tutmuyorsa durum **aynen** döner.
  static GameState maybeDivorce(GameState state, int newAge, Random rng) {
    if (state.deceased) return state;
    if (newAge < prototypeOnlyMinAge || newAge > prototypeOnlyMaxAge) {
      return state;
    }
    // Zaten ayrılmışlarsa bir daha ayrılmazlar.
    if (!state.parentalStatus.birlikteMi) return state;

    final Person? anne = _parent(state, RelationType.anne);
    final Person? baba = _parent(state, RelationType.baba);
    // İkisi de hayatta olmalı: vefat ayrı bir yol (StepParents).
    if (anne == null || baba == null) return state;
    if (!anne.isAlive || !baba.isAlive) return state;

    if (!_rollsThisYear(state, newAge, rng)) return state;

    return _applyDivorce(state, newAge, rng);
  }

  static GameState _applyDivorce(GameState state, int newAge, Random rng) {
    final Person anne = _parent(state, RelationType.anne)!;
    final Person baba = _parent(state, RelationType.baba)!;

    // §4: oyuncu yeterince büyükse seçim sorulur, değilse mantıklı hane
    // kendiliğinden belirlenir.
    final bool secimSorulur = newAge >= prototypeOnlyChoiceAge &&
        newAge < prototypeOnlyOwnHouseholdAge;
    final DivorceHouseholdChoice varsayilan = _defaultHousehold(
      anne: anne,
      baba: baba,
      rng: rng,
    );

    GameState next = state.copyWith(
      // §2: durum gerçekten değişiyor; iki ebeveyn de listede kalıyor.
      parentalStatus: ParentalStatus.bosanmis,
    );

    // Hane ayrılır. Oyuncu kendi hanesini kurmuş olsa bile ebeveynler
    // artık aynı evde değildir; ama **oyuncunun** hane durumu boşanma
    // yüzünden kötüleşmez (aşağıdaki nota bakınız).
    next = _splitHousehold(
      next,
      stayWith: varsayilan,
      // Boşanma **öncesi** ölçülüyor: oyuncu aile evinde miydi?
      playerAtFamilyHome: _atFamilyHome(state),
    );

    final String metin = '${anne.firstName} ile ${baba.firstName} '
        'ayrıldı.';
    next = next.copyWith(
      player: next.player.copyWith(
        stats: next.player.stats.gain(
          happiness: -_happinessHit(newAge, anne, baba),
        ),
      ),
      log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
        ...next.log,
        LifeLogEntry(
          age: newAge,
          text: newAge >= prototypeOnlyOwnHouseholdAge
              ? 'Annenle baban ayrıldı.'
              : 'Annenle baban ayrıldı; '
                  '${varsayilan == DivorceHouseholdChoice.anne ? 'annenle' : 'babanla'} '
                  'kaldın.',
          category: LogCategory.aile,
        ),
      ]),
    );

    next = next.queueNotice(
      PendingNotice(
        id: 'ebeveyn-bosanma-$newAge',
        kind: NoticeKind.aileDonum,
        age: newAge,
        title: 'Evdeki hava',
        text: 'Bir süredir evdeki hava değişikti.\n\n'
            'Annenle baban artık birlikte yaşamayacaklarını söyledi. '
            '$metin\n\n'
            '${_noticeTail(newAge, secimSorulur, varsayilan)}',
      ),
    );

    if (secimSorulur) {
      // Seçim bir sonraki adımda soruluyor; varsayılan hane şimdiden
      // kurulduğu için oyuncu "hiçbir şey seçmezse" de tutarlı bir
      // durumda kalır.
      next = next.copyWith(
        storyFlags: <String>{...next.storyFlags, pendingChoiceFlag},
      );
    }
    return next;
  }

  /// Oyuncuya hane seçimi sorulacağını işaretleyen iz.
  static const String pendingChoiceFlag = 'aile_hane_secimi_bekliyor';

  /// Oyuncuya "kiminle kalacaksın?" sorusu bekliyor mu?
  static bool isPending(GameState state) =>
      state.storyFlags.contains(pendingChoiceFlag);

  /// §4: oyuncu hangi ebeveynle kalacağını seçti.
  static GameState choose(GameState state, DivorceHouseholdChoice secim) {
    if (!isPending(state)) return state;
    // Boşanma anında ayrılan taraf zaten haneden çıkarıldı; oyuncunun
    // aile evinde olup olmadığı **kalan** taraftan okunuyor, yeni bir
    // kayıt alanı eklemeye gerek kalmıyor.
    GameState next = _splitHousehold(
      state,
      stayWith: secim,
      playerAtFamilyHome: _atFamilyHome(state),
    );
    next = next.copyWith(
      storyFlags: <String>{...next.storyFlags}..remove(pendingChoiceFlag),
      log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
        ...next.log,
        LifeLogEntry(
          age: next.player.age,
          text: secim == DivorceHouseholdChoice.anne
              ? 'Annenle kalmayı seçtin.'
              : 'Babanla kalmayı seçtin.',
          category: LogCategory.aile,
        ),
      ]),
    );
    return next;
  }

  // =================================================================
  // §3, §4 — hane
  // =================================================================

  /// Haneyi ayırır: seçilen ebeveyn oyuncuyla kalır, diğeri çıkar.
  /// **Kimse silinmez**, ikisi de anne/baba olarak listede durur.
  ///
  /// DİKKAT — kalan ebeveyn kendi hane durumunu **korur**, `true`
  /// yazılmaz. Sebebi bir ölçüm: ilk yazımda 24 yaş üstü oyuncuda iki
  /// ebeveyn de haneden çıkarılıyordu ve bu, **hâlâ ailesinin yanında
  /// yaşayan** bir yetişkini bir anda "kendi evinde" sayıyordu.
  /// `LivingCosts.livesWithFamily` buna bakıyor, dolayısıyla yaşam gideri
  /// ve işletme geri ödeme dağılımı kayıyordu (`paket_ag_payback` ve
  /// `paket_ae_calibration` kırıldı).
  ///
  /// Doğrusu şu: boşanma iki ebeveyni **birbirinden** ayırır, oyuncuyu
  /// evsiz bırakmaz. Bu yüzden kural tek yönlü — bir ebeveynin hane
  /// üyeliği ya aynı kalır ya da `false` olur, hiçbir zaman `false`'tan
  /// `true`'ya dönmez.
  static GameState _splitHousehold(
    GameState state, {
    required DivorceHouseholdChoice stayWith,
    required bool playerAtFamilyHome,
  }) {
    final List<Person> yeni = <Person>[];
    for (final Person p in state.people) {
      final bool kalan = switch (p.relation) {
        RelationType.anne => stayWith == DivorceHouseholdChoice.anne,
        RelationType.baba => stayWith == DivorceHouseholdChoice.baba,
        // Üvey ebeveyn kendi eşinin yanındadır.
        RelationType.uveyAnne => stayWith == DivorceHouseholdChoice.baba,
        RelationType.uveyBaba => stayWith == DivorceHouseholdChoice.anne,
        _ => false,
      };
      final bool ilgili = p.relation == RelationType.anne ||
          p.relation == RelationType.baba ||
          p.relation == RelationType.uveyAnne ||
          p.relation == RelationType.uveyBaba;
      if (!ilgili) {
        yeni.add(p);
        continue;
      }
      // Kalan taraf oyuncuyla kalır — ama yalnızca oyuncu zaten aile
      // evinde yaşıyorsa. Kendi evini kurmuş oyuncuya boşanma yüzünden
      // ebeveyn taşınmaz.
      yeni.add(p.copyWith(
        inPlayerHousehold: kalan && playerAtFamilyHome,
      ));
    }
    return state.copyWith(people: List<Person>.unmodifiable(yeni));
  }

  /// §4: küçük yaşta mantıklı hane. Hukuk simülasyonu değildir.
  ///
  /// Bakan: oyuncuyla olan bağ, ebeveynin ekonomik durumu ve küçük bir
  /// rastgelelik.
  static DivorceHouseholdChoice _defaultHousehold({
    required Person anne,
    required Person baba,
    required Random rng,
  }) {
    double annePuan = anne.bond.toDouble();
    double babaPuan = baba.bond.toDouble();
    annePuan += _wealthScore(anne.wealth);
    babaPuan += _wealthScore(baba.wealth);
    // Hayatta olmayan ebeveyn zaten seçilemez.
    if (!anne.isAlive) return DivorceHouseholdChoice.baba;
    if (!baba.isAlive) return DivorceHouseholdChoice.anne;
    annePuan += rng.nextInt(15);
    babaPuan += rng.nextInt(15);
    return annePuan >= babaPuan
        ? DivorceHouseholdChoice.anne
        : DivorceHouseholdChoice.baba;
  }

  static double _wealthScore(WealthTier? tier) => switch (tier) {
        WealthTier.cokYoksul => -8,
        WealthTier.yoksul => -4,
        WealthTier.ortaHalli => 0,
        WealthTier.varlikli => 5,
        WealthTier.cokVarlikli => 8,
        null => 0,
      };

  // =================================================================
  // §5 — çocuk üzerindeki etki
  // =================================================================

  /// Ayrılığın mutluluğa etkisi. Sabit değildir (§5).
  ///
  /// Yaş: küçük çocuk için kafa karıştırıcı ve ağır; ergen için farklı;
  /// kendi hayatını kurmuş yetişkin için hâlâ bir olaydır ama çocukluk
  /// kadar sarsıcı değildir.
  ///
  /// Bağ: anne babasıyla arası zaten uzak olan biri daha az sarsılır.
  static int _happinessHit(int age, Person anne, Person baba) {
    final double yasKatsayi = switch (age) {
      < 8 => 1.0,
      < 13 => 0.9,
      < 18 => 0.75,
      < 25 => 0.5,
      _ => 0.35,
    };
    final double bagOrt = (anne.bond + baba.bond) / 2;
    // Yakınlık 100'de tam, 0'da yarım etki.
    final double bagKatsayi = 0.5 + (bagOrt / 200);
    return (prototypeOnlyBaseHappinessHit * yasKatsayi * bagKatsayi)
        .round()
        .clamp(2, prototypeOnlyBaseHappinessHit);
  }

  static String _noticeTail(
    int age,
    bool secimSorulur,
    DivorceHouseholdChoice varsayilan,
  ) {
    if (age >= prototypeOnlyOwnHouseholdAge) {
      return 'Kendi hayatını kurmuştun; yine de bu haber bir yere oturdu.';
    }
    if (secimSorulur) {
      return 'Kiminle yaşayacağına karar vermen gerekiyor.';
    }
    return varsayilan == DivorceHouseholdChoice.anne
        ? 'Annenle kalıyorsun. Babanı görmeye devam edeceksin.'
        : 'Babanla kalıyorsun. Anneni görmeye devam edeceksin.';
  }

  /// Oyuncu (bu anda) anne ya da babasıyla aynı hanede mi?
  static bool _atFamilyHome(GameState state) => state.people.any((Person p) =>
      (p.relation == RelationType.anne || p.relation == RelationType.baba) &&
      p.inPlayerHousehold);

  static Person? _parent(GameState state, RelationType tur) {
    for (final Person p in state.people) {
      if (p.relation == tur) return p;
    }
    return null;
  }
}
