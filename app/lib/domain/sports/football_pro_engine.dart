import 'dart:math';

import '../../data/economy.dart';
import '../../data/school_club_catalog.dart';
import '../models/game_state.dart';
import '../models/school_club_progress.dart';
import 'football_career.dart';

/// Profesyonel futbol hayatı (Paket AY).
///
/// AU kapıyı kurdu ama kapıdan geçilmiyordu: uygunluk hesaplanıyor,
/// sonra hiçbir şey olmuyordu. Bu motor o eksiği kapatır — deneme,
/// sezon, form, sakatlık, kazanç, kariyer sonu ve futbol sonrası hayat.
///
/// **Bu pakette YAPILMAYANLAR** (bilerek): maç maç simülasyon, lig
/// tablosu, fikstür, transfer pazarı, sözleşme ve maaş pazarlığı,
/// Avrupa kupaları, millî takım, yurt dışına gitme. Gerçek kulüp ve lig
/// adları da **yok** — katalog ağ erişimi gerektirdiği için yazılmadı,
/// uydurma kulüp adı üretilmiyor. Kulüp alanları `null` kalıyor ve
/// katalog geldiğinde dolacak.
///
/// Sezon **yaş başına bir kez** işlenir; oyunun başka yerlerindeki
/// kuralın aynısı.
class FootballProEngine {
  const FootballProEngine();

  // --- prototypeOnly sayılar (Q-193) ---------------------------------

  /// Denemenin geçme eşiği. Hazırlık puanı + zar bu eşiği geçmeli.
  ///
  /// **ÖLÇÜLEN HATA (düzeltildi):** eşik 62 iken deneme dekoratifti.
  /// Kapıdan geçmenin alt sınırı zaten hazırlık puanı
  /// `FootballPath.prototypeOnlyMinScore` (55) ve sağlık
  /// `prototypeOnlyMinHealth` (55); en zayıf aday bile
  /// 55 + 55*15/100 = 63 puanla geliyor, yani zarsız dahi 62'yi
  /// geçiyordu. 1200 spor odaklı hayatta kapıya gelen 49 kişinin
  /// 49'u (%100) profesyonel oldu; tek retler %10'luk sürprizdi.
  /// Eşik, sınırdaki adayın gerçekten takılacağı yere taşındı.
  static const int prototypeOnlyTrialPass = 78;

  /// Denemedeki kura aralığı. Geniş tutuldu ki yüksek puan bile
  /// garanti olmasın, düşük puan da matematiksel olarak imkânsız
  /// olmasın.
  static const int prototypeOnlyTrialLuckSpan = 34;

  /// Puandan bağımsız sürpriz ret payı (%). Deneme saf kura değildir
  /// ama kesinlik de yoktur.
  static const int prototypeOnlyTrialUpsetPercent = 10;

  /// Bir sezonda çıkılabilecek en çok maç.
  static const int prototypeOnlyMaxAppearances = 34;

  /// Kariyerin kendiliğinden bitmeye başladığı yaş.
  static const int prototypeOnlyDeclineAge = 31;

  /// Bu yaşta kariyer her hâlükârda biter.
  static const int prototypeOnlyHardRetireAge = 39;

  /// Üst üste bu kadar zayıf sezon geçerse sözleşme yenilenmez.
  static const int prototypeOnlyWeakSeasonsToRelease = 3;

  /// Zayıf sezon sayılan puan eşiği.
  static const int prototypeOnlyWeakRating = 42;

  /// Sakatlığın kariyeri bitirdiği sağlık eşiği.
  static const int prototypeOnlyCareerEndingHealth = 32;

  /// Sıradan bir sezon sakatlığının sağlık bedeli.
  ///
  /// **ÖLÇÜLEN HATA (düzeltildi):** sakatlık sağlığa hiç dokunmuyordu.
  /// 49 kariyerin %91,8'i sakatlık yaşadı ama `FootballExit.sakatlik`
  /// bir kez bile olmadı: futbol sağlığı düşürmediği için
  /// [prototypeOnlyCareerEndingHealth] eşiğine futboldan hiç
  /// inilemiyordu. Yol ölü koddu.
  static const int prototypeOnlyInjuryHealthCost = 4;

  /// Ağır sakatlığın sağlık bedeli.
  static const int prototypeOnlySevereInjuryHealthCost = 16;

  /// Bir sakatlığın ağır olma payı (%).
  static const int prototypeOnlySevereInjuryPercent = 22;

  /// Ağır bir sakatlığın kariyeri **doğrudan** bitirme payı (%).
  ///
  /// **ÖLÇÜLEN HATA (ikinci tur):** sakatlığa sağlık bedeli eklendikten
  /// sonra bile `FootballExit.sakatlik` 49 kariyerde 0 kez çıktı.
  /// Sebep modelin kendisiydi: kariyeri bitiren sakatlık, sağlığın
  /// yıllar içinde 32'nin altına inmesine bağlanmıştı. Oysa sağlıklı bir
  /// futbolcu 14 sezonda o seviyeye inmiyor. Gerçekte kariyeri bitiren
  /// şey tek bir ağır sakatlıktır: 27 yaşındaki bir diz, yılların
  /// birikimi değil. Bu yüzden ağır sakatlık artık kendi başına bir
  /// bitirme ihtimali taşıyor; yaş ilerledikçe artıyor.
  static const int prototypeOnlySevereInjuryCareerEndPercent = 16;

  /// Ağır sakatlığın bitirme payına yaş başına eklenen pay (%).
  ///
  /// [prototypeOnlyDeclineAge] üstündeki her yıl için eklenir: aynı
  /// sakatlık 34 yaşında 24 yaşından daha çok kariyer bitirir.
  static const int prototypeOnlySevereInjuryAgeBonus = 5;

  /// Yıllık kazancın **yıllık asgari ücret** cinsinden tabanı ve tavanı.
  ///
  /// Sözleşme pazarlığı YOK; tutar seviyeden türetilir. Alt ligde
  /// futbolculuk zengin etmez (taban 1 = asgari ücret seviyesi); üst
  /// seviyede ciddi para vardır (tavan 40). Gerçek kulüp kataloğu
  /// gelince lig kademesi bu bandı daraltacak.
  static const int prototypeOnlyMinSalaryInYearlyWages = 1;
  static const int prototypeOnlyMaxSalaryInYearlyWages = 40;

  // --- Deneme ---------------------------------------------------------

  /// Deneme puanı: hazırlık puanı + o anki sağlık payı.
  ///
  /// Saf kura değil; ama `FootballPath.evaluate` zaten kapıyı açmışsa
  /// bile kabul **garanti değildir**.
  int trialScore(GameState state) {
    final FootballEligibility u = FootballPath.evaluate(state);
    return (u.score + state.player.stats.health * 15 ~/ 100).clamp(0, 120);
  }

  /// Profesyonel denemeye girer.
  ///
  /// Kapı kapalıysa gerekçesiyle reddeder (uydurma bir sebep yazılmaz).
  ({GameState state, bool accepted, String reason}) attemptTrial(
    GameState state,
    Random rng,
  ) {
    final FootballEligibility u = FootballPath.evaluate(state);
    if (!u.eligible) {
      return (state: state, accepted: false, reason: u.reason);
    }
    if (state.footballCareer != null) {
      return (
        state: state,
        accepted: false,
        reason: 'Profesyonel futbol kariyerin sürüyor.',
      );
    }
    // Deneme yılda bir kez. Bu kontrol olmadan oyuncu aynı yıl içinde
    // kabul alana kadar düğmeye basabiliyordu; deneme bir fırsat
    // olmaktan çıkıp kura makinesine dönüyordu.
    if (state.footballTrialAge == state.player.age) {
      return (
        state: state,
        accepted: false,
        reason: 'Bu yılın denemesine girdin. Kadrolar sezon başında '
            'kurulur; gelecek yıl yeniden denenebilir.',
      );
    }

    final int puan = trialScore(state);
    final int zar = rng.nextInt(prototypeOnlyTrialLuckSpan);
    final bool surpriz = rng.nextInt(100) < prototypeOnlyTrialUpsetPercent;
    final bool kabul = !surpriz && puan + zar >= prototypeOnlyTrialPass;

    // Girildiği yıl, sonuç ne olursa olsun kayda geçer.
    final GameState denendi =
        state.copyWith(footballTrialAge: state.player.age);

    if (!kabul) {
      return (
        state: denendi,
        accepted: false,
        reason: surpriz
            ? 'Deneme iyi geçti ama kadro doldu. Bu sefer olmadı; '
                'gelecek yıl yeniden denenebilir.'
            : 'Hocalar seni izledi, yeterli bulmadılar. Bir sezon daha '
                'oynayıp beceriyi yükseltmek şansı artırır.',
      );
    }

    final FootballCareer kariyer = FootballCareer(
      startedAtAge: state.player.age,
      position: _mevkiSec(state, rng),
      form: (45 + u.score ~/ 4).clamp(30, 75),
    );
    return (
      state: denendi.copyWith(footballCareer: kariyer),
      accepted: true,
      reason: 'Sözleşme imzalandı. ${kariyer.position.label} olarak '
          'profesyonel kadroya alındın.',
    );
  }

  /// Mevki: oyuncunun geçmişinden ve yatkınlığından türetilir.
  FootballPosition _mevkiSec(GameState state, Random rng) {
    final int yatkinlik = state.player.athleticPotential;
    final int zar = rng.nextInt(100);
    // Yatkınlığı yüksek olan daha çok hücumda, kalecilik her zaman
    // küçük bir pay. Bu bir eğilimdir, kural değil.
    if (zar < 10) return FootballPosition.kaleci;
    if (yatkinlik >= 65) {
      return zar < 55 ? FootballPosition.forvet : FootballPosition.ortaSaha;
    }
    if (zar < 45) return FootballPosition.defans;
    return FootballPosition.ortaSaha;
  }

  // --- Sezon ----------------------------------------------------------

  /// Bu yıl sezon işlenebilir mi?
  bool canAdvance(GameState state) {
    final FootballCareer? k = state.footballCareer;
    if (k == null || !k.active) return false;
    return k.lastSeasonAge != state.player.age;
  }

  /// Bir profesyonel sezonu işler.
  ///
  /// Dönen `log` günlüğe, `notices` bildirime gider. Para **gerçekten**
  /// cüzdana yazılır.
  ({GameState state, List<String> log, String? milestone}) advanceSeason(
    GameState state,
    Random rng,
  ) {
    if (!canAdvance(state)) {
      return (state: state, log: const <String>[], milestone: null);
    }
    final FootballCareer k = state.footballCareer!;
    final int yas = state.player.age;
    final int saglik = state.player.stats.health;
    final int beceri = state.schoolClubs.bestSkillInSport(kFootballSportId);

    // --- Sakatlık: yaş ve maç yükü arttıkça olasılık artar -----------
    final int sakatlikSansi =
        (8 + (yas - 20).clamp(0, 20) + (100 - saglik) ~/ 6).clamp(5, 55);
    final bool sakatlandi = rng.nextInt(100) < sakatlikSansi;
    final bool agir = sakatlandi &&
        rng.nextInt(100) < prototypeOnlySevereInjuryPercent;
    final String? sakatlik = sakatlandi
        ? (agir ? 'ağır ${_sakatlikAdi(rng)}' : _sakatlikAdi(rng))
        : null;
    // Sakatlık sağlığa gerçekten dokunur; yoksa kariyeri sakatlıktan
    // bitiren yol ölü kalır.
    final int saglikBedeli = !sakatlandi
        ? 0
        : (agir
            ? prototypeOnlySevereInjuryHealthCost
            : prototypeOnlyInjuryHealthCost);
    final int sezonSonuSaglik = (saglik - saglikBedeli).clamp(1, 100);

    // --- Sezon puanı: beceri ağır basar, form ve sağlık pay verir ----
    final int yasEtkisi = yas <= prototypeOnlyDeclineAge
        ? 0
        : -((yas - prototypeOnlyDeclineAge) * 4);
    final int puan = (beceri * 45 ~/ 100 +
            k.form * 25 ~/ 100 +
            saglik * 15 ~/ 100 +
            state.player.athleticPotential * 10 ~/ 100 +
            yasEtkisi +
            rng.nextInt(14) -
            (sakatlandi ? 12 : 0))
        .clamp(0, 100);

    // --- Maç ve gol ---------------------------------------------------
    final int mac = sakatlandi
        ? (prototypeOnlyMaxAppearances * puan ~/ 220).clamp(0, 20)
        : (prototypeOnlyMaxAppearances * (55 + puan) ~/ 160)
            .clamp(0, prototypeOnlyMaxAppearances);
    final int gol = _gol(k.position, mac, puan, rng);

    // --- Kazanç: seviyeden türetilir, pazarlık yok -------------------
    final int kazanc = _yillikKazanc(puan: puan, itibar: k.reputation);

    // --- Form ve itibar -----------------------------------------------
    final int yeniForm = ((k.form * 55 + puan * 45) ~/ 100 -
            (sakatlandi ? 10 : 0))
        .clamp(10, 100);
    final int yeniItibar =
        (k.reputation + (puan - 50) ~/ 6 + gol ~/ 3).clamp(0, 100);

    final FootballSeason sezon = FootballSeason(
      age: yas,
      appearances: mac,
      goals: gol,
      rating: puan,
      injury: sakatlik,
      earned: kazanc,
    );

    final bool zayif = puan < prototypeOnlyWeakRating;
    FootballCareer guncel = k.copyWith(
      form: yeniForm,
      reputation: yeniItibar,
      lastSeasonAge: yas,
      weakSeasons: zayif ? k.weakSeasons + 1 : 0,
      careerEarnings: k.careerEarnings + kazanc,
      seasonHistory: <FootballSeason>[...k.seasonHistory, sezon],
    );

    final List<String> log = <String>[
      _sezonCumlesi(position: k.position, mac: mac, gol: gol, puan: puan),
      if (sakatlik != null)
        'Sezon ortasında $sakatlik. Saha dışında kaldın'
            '${agir ? '; toparlanmak uzun sürdü' : ''}.',
    ];

    // --- Kariyer sonu kontrolü ----------------------------------------
    final FootballExit? cikis = _cikisSebebi(
      yas: yas,
      saglik: sezonSonuSaglik,
      sakatlandi: sakatlandi,
      agirSakatlik: agir,
      zayifSezon: guncel.weakSeasons,
      rng: rng,
    );
    String? donum;
    if (cikis != null) {
      guncel = guncel.copyWith(
        active: false,
        retiredAtAge: yas,
        exitReason: cikis,
      );
      log.add(_bitisCumlesi(cikis, guncel));
      donum = 'Futbol kariyerin bitti: ${cikis.label.toLowerCase()}. '
          '${guncel.proSeasons} sezon, ${guncel.totalAppearances} maç, '
          '${guncel.totalGoals} gol.';
    } else if (guncel.proSeasons == 1) {
      donum = 'İlk profesyonel sezonunu tamamladın: $mac maç, $gol gol.';
    }

    // Para gerçekten cüzdana yazılır.
    final GameState yeni = state.copyWith(
      footballCareer: guncel,
      player: state.player.copyWith(
        wallet: state.player.wallet + kazanc,
        stats: state.player.stats.copyWith(health: sezonSonuSaglik),
      ),
    );
    return (state: yeni, log: log, milestone: donum);
  }

  /// Oyuncunun kendi kararıyla futbolu bırakması.
  GameState retire(GameState state) {
    final FootballCareer? k = state.footballCareer;
    if (k == null || !k.active) return state;
    return state.copyWith(
      footballCareer: k.copyWith(
        active: false,
        retiredAtAge: state.player.age,
        exitReason: FootballExit.kendiKarari,
      ),
    );
  }

  // --- Yardımcılar ------------------------------------------------------

  FootballExit? _cikisSebebi({
    required int yas,
    required int saglik,
    required bool sakatlandi,
    required bool agirSakatlik,
    required int zayifSezon,
    required Random rng,
  }) {
    if (yas >= prototypeOnlyHardRetireAge) return FootballExit.yas;
    // Düşen sağlık yolu: yıllar içinde yıpranan oyuncu.
    if (sakatlandi && saglik < prototypeOnlyCareerEndingHealth) {
      return FootballExit.sakatlik;
    }
    // Tek olay yolu: bir ağır sakatlık kariyeri kapatabilir.
    if (agirSakatlik) {
      final int sans = prototypeOnlySevereInjuryCareerEndPercent +
          (yas - prototypeOnlyDeclineAge).clamp(0, 8) *
              prototypeOnlySevereInjuryAgeBonus;
      if (rng.nextInt(100) < sans) return FootballExit.sakatlik;
    }
    if (zayifSezon >= prototypeOnlyWeakSeasonsToRelease) {
      return FootballExit.sozlesmeYenilenmedi;
    }
    if (yas > prototypeOnlyDeclineAge) {
      // Yaş ilerledikçe bırakma ihtimali artar; keskin bir duvar yok.
      final int sans = (yas - prototypeOnlyDeclineAge) * 12;
      if (rng.nextInt(100) < sans) return FootballExit.yas;
    }
    return null;
  }

  int _gol(FootballPosition mevki, int mac, int puan, Random rng) {
    if (mac == 0) return 0;
    final int pay = switch (mevki) {
      FootballPosition.kaleci => 0,
      FootballPosition.defans => 4,
      FootballPosition.ortaSaha => 12,
      FootballPosition.forvet => 30,
    };
    if (pay == 0) return 0;
    final int taban = mac * pay * (40 + puan) ~/ 10000;
    return (taban + (rng.nextInt(3) - 1)).clamp(0, mac);
  }

  /// Yıllık kazanç: seviyeden türetilir, pazarlık yok.
  ///
  /// Alt ligde futbolculuk zengin etmez; üst seviyede ciddi para vardır.
  /// Eğri bilinçli olarak **üstel değil kademeli**: puan 50'den 90'a
  /// çıkınca kazanç katlanır ama uçmaz.
  int _yillikKazanc({required int puan, required int itibar}) {
    final int seviye = (puan * 65 + itibar * 35) ~/ 100;
    // Kare eğri: seviye yükseldikçe kazanç hızlanır ama tavanı aşmaz.
    final int katsayi = prototypeOnlyMinSalaryInYearlyWages +
        (prototypeOnlyMaxSalaryInYearlyWages -
                prototypeOnlyMinSalaryInYearlyWages) *
            seviye *
            seviye ~/
            10000;
    return katsayi * Economy.netYearlyMinimumWage;
  }

  String _sakatlikAdi(Random rng) {
    const List<String> liste = <String>[
      'bilek burkulması',
      'kas yırtığı',
      'diz sakatlığı',
      'kaburga çatlağı',
      'omuz çıkığı',
    ];
    return liste[rng.nextInt(liste.length)];
  }

  String _sezonCumlesi({
    required FootballPosition position,
    required int mac,
    required int gol,
    required int puan,
  }) {
    if (mac == 0) {
      return 'Sezon boyunca kadroya giremedin. Zor bir yıl oldu.';
    }
    final String nasil = puan >= 75
        ? 'Sezon çok iyi geçti'
        : puan >= 58
            ? 'İyi bir sezondu'
            : puan >= 42
                ? 'Ortalama bir sezon'
                : 'Zor bir sezon';
    if (position == FootballPosition.kaleci) {
      return '$nasil: $mac maçta kaleyi korudun.';
    }
    return gol > 0
        ? '$nasil: $mac maç, $gol gol.'
        : '$nasil: $mac maça çıktın, gol atamadın.';
  }

  String _bitisCumlesi(FootballExit cikis, FootballCareer k) =>
      switch (cikis) {
        FootballExit.yas =>
          'Ayaklar eskisi gibi değil. Kramponları astın; '
              '${k.proSeasons} sezon arkanda kaldı.',
        FootballExit.sakatlik =>
          'Sakatlık geçmedi. Doktorlar devam etmeni önermedi; '
              'kariyer burada bitti.',
        FootballExit.sozlesmeYenilenmedi =>
          'Sözleşme yenilenmedi ve yeni bir kulüp çıkmadı. '
              'Futbol bu noktada bitti.',
        FootballExit.kendiKarari =>
          'Futbolu bırakmaya kendin karar verdin.',
      };
}
