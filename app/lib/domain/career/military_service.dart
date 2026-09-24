/// Askerlik: yükümlülük, bedelli ve rütbeli yollar (Paket 29).
///
/// **Faho'nun kararı:** 18 yaşından sonra gönüllü katılınabilir; okumayan
/// erkek 20 yaşında zorunlu askerlik için çağrılır; bedelli ödenebilir ve
/// bedelli ücreti **aileden istenebilir** — ailede varlıklı biri varsa ve
/// arası iyiyse ödeyebilir. Dileyen subay/astsubay gibi rütbeli yollara
/// başvurabilir.
///
/// Kurallar:
/// - Çağrı **sessizce** gelmez: ekranda bildirim olur (D-050).
/// - Hiçbir yol zorla uygulanmaz; oyuncu seçer. Yükümlülük kapanmadan da
///   hayat sürer, yalnızca "askerlik yapılmadı" olarak kalır.
/// - Aileden bedelli istemek **gerçek bir ret** alabilir; sahte bir
///   "her zaman evet" yoktur.
/// - Bütün sayılar `prototypeOnly` (Q-097).
library;

import 'dart:math';

import '../../data/military_catalog.dart';
import '../../text/turkish_text.dart';
import '../life/notices.dart';
import '../models/game_state.dart';
import '../models/gender.dart';
import '../models/interaction.dart';
import '../models/life_log.dart';
import '../models/military.dart';
import '../models/pending_notice.dart';
import '../models/person.dart';
import '../models/relation.dart';
import '../models/wealth.dart';

/// Askerlik işleminin sonucu.
class MilitaryResult {
  const MilitaryResult({
    required this.state,
    required this.applied,
    required this.text,
  });

  final GameState state;

  /// İşlem gerçekten uygulandı mı? `false` ise [text] gerekçedir.
  final bool applied;
  final String text;
}

abstract final class MilitaryService {
  /// prototypeOnly: gönüllü katılım için en küçük yaş.
  static const int prototypeOnlyMinAge = 18;

  /// prototypeOnly: okumayan yükümlünün çağrıldığı yaş.
  static const int prototypeOnlyCallAge = 20;

  /// prototypeOnly: yükümlülüğün düştüğü yaş.
  ///
  /// Bu yaştan sonra celp gelmez; askerlik yapılmadıysa yapılmamış kalır.
  static const int prototypeOnlyExemptAge = 41;

  /// prototypeOnly: bedelli askerlik ücreti (₺).
  static const int prototypeOnlyBedelliCost = 550000;

  /// prototypeOnly: kaç kez tecil hakkı var (Paket 31).
  static const int prototypeOnlyMaxDeferrals = 2;

  /// prototypeOnly: bir tecil kaç yıl sürer.
  static const int prototypeOnlyDeferralYears = 2;

  /// prototypeOnly: bakaya kalanın bir yılda yakalanma ihtimali.
  ///
  /// Her geçen yıl artar: saklanmak zamanla zorlaşır.
  static const double prototypeOnlyCatchChance = 0.30;
  static const double prototypeOnlyCatchGrowth = 0.10;

  /// prototypeOnly: bakaya cezasının **günlük** tutarı (₺).
  ///
  /// Türkiye'de idari para cezası günlük hesaplanır ve **yakalananlara
  /// iki katı** uygulanır; kendiliğinden başvuran daha azını öder.
  /// Buradaki tutarlar oyunun ekonomisine göre seçildi, gerçek mevzuat
  /// tutarı değildir (Q-099).
  static const int prototypeOnlyDailyFineSelf = 180;
  static const int prototypeOnlyDailyFineCaught = 360;

  /// prototypeOnly: bakaya kalanın bedelliye eklenen **ek bedeli**
  /// (kaçtığı her yıl için).
  static const int prototypeOnlyLateBedelliPerYear = 120000;

  /// prototypeOnly: aileden bedelli istemek için gereken en az yakınlık.
  static const int prototypeOnlyFamilyMinBond = 55;

  /// prototypeOnly: aileden istendiğinde kabul ihtimalinin tabanı.
  static const double prototypeOnlyFamilyBaseChance = 0.20;

  /// prototypeOnly: hizmet süresince yıllık etkiler.
  static const int prototypeOnlyServiceHealth = 4;
  static const int prototypeOnlyServiceCharisma = 3;
  static const int prototypeOnlyServiceHappiness = -3;

  /// prototypeOnly: terhiste uygulanan etki.
  static const int prototypeOnlyDischargeHappiness = 8;

  // -----------------------------------------------------------------
  // Yükümlülük
  // -----------------------------------------------------------------

  /// Bu hayatta askerlik **zorunlu** mu?
  ///
  /// Bu prototipte zorunluluk erkekler içindir; kadın oyuncu **gönüllü**
  /// olarak rütbeli yollara başvurabilir. Bu bir tasarım sadeleştirmesi
  /// ve Q-097'de sorulmuştur.
  static bool isObliged(GameState state) => state.player.gender == Gender.erkek;

  /// Ekranda gösterilecek durum etiketi.
  ///
  /// Yükümlü olmayan oyuncuda ham durum [MilitaryStatus.yok] kalır ve
  /// etiketi "Yapılmadı"dır. Bu, kadın oyuncuda **yerine getirilmemiş
  /// bir yükümlülük** varmış gibi okunuyordu; oysa zorunlu askerliği
  /// yoktur, dolayısıyla yapılmamış bir şey de yoktur.
  ///
  /// Durumun kendisi bilerek değiştirilmez: kayda [MilitaryStatus
  /// .yukumluDegil] yazmak [MilitaryStatus.kapandi] anlamına geldiği için
  /// gönüllü subay/astsubay başvurusunu da kapatırdı.
  static String statusLabel(GameState state) {
    if (!isObliged(state) && state.military.status == MilitaryStatus.yok) {
      return 'Yükümlü değil';
    }
    return state.military.label;
  }

  /// Meslek menüsündeki askerlik satırının alt yazısı.
  static String menuSubtitle(GameState state) {
    if (state.military.isCalled) {
      return 'Celbin geldi; bir karar vermen gerekiyor';
    }
    if (!isObliged(state) && state.military.status == MilitaryStatus.yok) {
      return 'Yükümlü değil · gönüllü başvurabilirsin';
    }
    return state.military.label;
  }

  /// Yaşı geldi ve yükümlülük hâlâ açık mı?
  ///
  /// **Okuyan öğrenci de çağrılır** ama çağrı otomatik tecile dönüşür
  /// (Paket 31): oyuncu ekranda "askerliğin geldi, okulun tecil ettirdi"
  /// bildirimini görür.
  static bool canBeCalled(GameState state) {
    if (!isObliged(state)) return false;
    if (state.military.status != MilitaryStatus.yok) return false;
    if (state.player.age < prototypeOnlyCallAge) return false;
    if (state.player.age >= prototypeOnlyExemptAge) return false;
    return true;
  }

  /// Tecil hakkı kaldı mı?
  static bool canDefer(GameState state) {
    final MilitaryState a = state.military;
    if (a.status != MilitaryStatus.cagrildi) return false;
    return a.deferralsUsed < prototypeOnlyMaxDeferrals;
  }

  /// Kalan tecil hakkı.
  static int remainingDeferrals(GameState state) =>
      (prototypeOnlyMaxDeferrals - state.military.deferralsUsed).clamp(
        0,
        prototypeOnlyMaxDeferrals,
      );

  /// Yıllık ilerlemede celbi uygular.
  ///
  /// Çağrı ekranda bildirimle duyurulur; sessizce durum değiştirmez.
  static GameState applyCallUp(GameState state, int newAge) {
    if (!canBeCalled(state)) return state;

    // Okuyan öğrenci **otomatik** tecil edilir; ama bu sessizce olmaz,
    // ekranda bildirilir (Paket 31).
    if (state.education.isStudent) {
      final PendingNotice bildirim = Notices.militaryStudentDeferral(
        playerAge: newAge,
      );
      if (state.notices.any((PendingNotice n) => n.id == bildirim.id)) {
        return state;
      }
      return state.copyWith(
        military: state.military.copyWith(
          status: MilitaryStatus.tecilli,
          calledAtAge: newAge,
          studentDeferral: true,
          deferredUntilAge: null,
        ),
        notices: List<PendingNotice>.unmodifiable(<PendingNotice>[
          ...state.notices,
          bildirim,
        ]),
        log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
          ...state.log,
          LifeLogEntry(
            age: newAge,
            text: 'Askerlik celbin geldi; okuduğun için tecil edildi.',
            category: LogCategory.kisisel,
          ),
        ]),
      );
    }

    final PendingNotice bildirim = Notices.militaryCall(playerAge: newAge);
    if (state.notices.any((PendingNotice n) => n.id == bildirim.id)) {
      return state;
    }
    return state.copyWith(
      military: state.military.copyWith(
        status: MilitaryStatus.cagrildi,
        calledAtAge: newAge,
      ),
      notices: List<PendingNotice>.unmodifiable(<PendingNotice>[
        ...state.notices,
        bildirim,
      ]),
      log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
        ...state.log,
        LifeLogEntry(
          age: newAge,
          text: 'Askerlik celbin geldi.',
          category: LogCategory.kisisel,
        ),
      ]),
    );
  }

  /// Tecili biten ya da okulu biten yükümlüyü yeniden çağırır.
  static GameState applyDeferralEnd(GameState state, int newAge) {
    final MilitaryState a = state.military;
    if (a.status != MilitaryStatus.tecilli) return state;
    if (newAge >= prototypeOnlyExemptAge) return state;

    final bool bitti = a.studentDeferral
        ? !state.education.isStudent
        : (a.deferredUntilAge != null && newAge >= a.deferredUntilAge!);
    if (!bitti) return state;

    final PendingNotice bildirim = Notices.militaryCall(
      playerAge: newAge,
      afterDeferral: true,
    );
    if (state.notices.any((PendingNotice n) => n.id == bildirim.id)) {
      return state;
    }
    return state.copyWith(
      military: a.copyWith(
        status: MilitaryStatus.cagrildi,
        calledAtAge: newAge,
        studentDeferral: false,
        deferredUntilAge: null,
      ),
      notices: List<PendingNotice>.unmodifiable(<PendingNotice>[
        ...state.notices,
        bildirim,
      ]),
      log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
        ...state.log,
        LifeLogEntry(
          age: newAge,
          text: a.studentDeferral
              ? 'Okulun bitti; askerlik tecilin sona erdi.'
              : 'Askerlik tecilin sona erdi.',
          category: LogCategory.kisisel,
        ),
      ]),
    );
  }

  /// Tecil ettirir (Paket 31).
  ///
  /// Hak bitince bir daha ertelenemez.
  static MilitaryResult defer(GameState state) {
    if (state.military.status != MilitaryStatus.cagrildi) {
      return MilitaryResult(
        state: state,
        applied: false,
        text: 'Şu an tecil edilecek bir çağrın yok.',
      );
    }
    if (!canDefer(state)) {
      return MilitaryResult(
        state: state,
        applied: false,
        text:
            'Tecil hakkın kalmadı; $prototypeOnlyMaxDeferrals kez '
            'kullandın.',
      );
    }
    final int bitis = state.player.age + prototypeOnlyDeferralYears;
    final String metin =
        'Askerliğini $prototypeOnlyDeferralYears yıl '
        'tecil ettirdin; $bitis yaşında yeniden çağrılacaksın.';
    return MilitaryResult(
      state: _log(
        state.copyWith(
          military: state.military.copyWith(
            status: MilitaryStatus.tecilli,
            deferralsUsed: state.military.deferralsUsed + 1,
            deferredUntilAge: bitis,
            studentDeferral: false,
          ),
        ),
        metin,
      ),
      applied: true,
      text: metin,
    );
  }

  // -----------------------------------------------------------------
  // Bakaya (askerden kaçmak)
  // -----------------------------------------------------------------

  /// Kaçmaya engel; engel yoksa boş metin.
  static String fleeBlockReason(GameState state) {
    final MilitaryState a = state.military;
    if (a.isFugitive) return 'Zaten bakayasın.';
    if (a.status != MilitaryStatus.cagrildi) {
      return 'Kaçılacak bir çağrın yok.';
    }
    return '';
  }

  /// Çağrıya gitmez: bakaya kalır.
  static MilitaryResult flee(GameState state) {
    final String engel = fleeBlockReason(state);
    if (engel.isNotEmpty) {
      return MilitaryResult(state: state, applied: false, text: engel);
    }
    const String metin =
        'Sevk tarihinde gitmedin; bakaya kaldın. '
        'Ceza her geçen yıl büyüyor ve yakalanabilirsin.';
    return MilitaryResult(
      state: _log(
        state.copyWith(
          military: state.military.copyWith(
            status: MilitaryStatus.kacak,
            fugitiveSinceAge: state.player.age,
          ),
        ),
        metin,
      ),
      applied: true,
      text: metin,
    );
  }

  /// Kaçılan yıl sayısı.
  static int fugitiveYears(GameState state) {
    final int? bas = state.military.fugitiveSinceAge;
    if (bas == null) return 0;
    return (state.player.age - bas).clamp(0, 120);
  }

  /// Şu ana kadar birikmiş ceza.
  ///
  /// Kendiliğinden başvuran günlük düşük tutarı, yakalanan iki katını
  /// öder.
  static int prototypeOnlyFineFor(GameState state, {required bool caught}) {
    final int yil = fugitiveYears(state);
    final int gunluk = caught
        ? prototypeOnlyDailyFineCaught
        : prototypeOnlyDailyFineSelf;
    return yil * 365 * gunluk;
  }

  /// Bakaya kalanın bu yıl yakalanma ihtimali.
  static double prototypeOnlyCatchChanceFor(GameState state) {
    final int yil = fugitiveYears(state);
    return (prototypeOnlyCatchChance + yil * prototypeOnlyCatchGrowth).clamp(
      0.0,
      0.95,
    );
  }

  /// Kendiliğinden teslim olur: ceza daha az olur ve yeniden çağrılır.
  static MilitaryResult surrender(GameState state) {
    if (!state.military.isFugitive) {
      return MilitaryResult(
        state: state,
        applied: false,
        text: 'Bakaya değilsin.',
      );
    }
    final int ceza = prototypeOnlyFineFor(state, caught: false);
    final int odenen = ceza.clamp(0, state.player.wallet.clamp(0, 1 << 31));
    final String metin =
        'Kendin başvurdun. İdari para cezan '
        '${trMoney(ceza)}; ${trMoney(odenen)} ödedin. Yeniden '
        'çağrıldın.';
    return MilitaryResult(
      state: _log(
        state.copyWith(
          player: state.player.copyWith(wallet: state.player.wallet - odenen),
          military: state.military.copyWith(
            status: MilitaryStatus.cagrildi,
            fugitiveSinceAge: null,
            fineTotal: state.military.fineTotal + odenen,
          ),
        ),
        metin,
      ),
      applied: true,
      text: metin,
    );
  }

  /// Yıllık ilerlemede bakaya durumunu işler.
  static GameState advanceFugitive(GameState state, int newAge, Random rng) {
    if (!state.military.isFugitive) return state;
    if (newAge >= prototypeOnlyExemptAge) {
      // Yükümlülük yaşı geçti: dosya kapanır ama kayıt kalır.
      return _log(
        state.copyWith(
          military: state.military.copyWith(
            status: MilitaryStatus.yukumluDegil,
            fugitiveSinceAge: null,
            finishedAtAge: newAge,
          ),
        ),
        'Askerlik yaşın geçti; bakaya dosyan kapandı.',
      );
    }
    if (rng.nextDouble() >= prototypeOnlyCatchChanceFor(state)) return state;

    final int ceza = prototypeOnlyFineFor(state, caught: true);
    final int odenen = ceza.clamp(0, state.player.wallet.clamp(0, 1 << 31));
    final GameState yakalandi = state.copyWith(
      player: state.player.copyWith(wallet: state.player.wallet - odenen),
      military: state.military.copyWith(
        status: MilitaryStatus.cagrildi,
        fugitiveSinceAge: null,
        fineTotal: state.military.fineTotal + odenen,
        caughtCount: state.military.caughtCount + 1,
      ),
      notices: List<PendingNotice>.unmodifiable(<PendingNotice>[
        ...state.notices,
        Notices.militaryCaught(playerAge: newAge, fine: odenen),
      ]),
    );
    return _log(
      yakalandi,
      'Bakaya olduğun için yakalandın. ${trMoney(odenen)} idari para '
      'cezası ödedin ve yeniden çağrıldın.',
    );
  }

  // -----------------------------------------------------------------
  // Katılma
  // -----------------------------------------------------------------

  /// Bu yola başvurmaya engel; engel yoksa boş metin.
  static String blockReason(GameState state, MilitaryTrack track) {
    final MilitaryState askerlik = state.military;
    if (askerlik.isServing) return 'Zaten görevdesin.';
    if (askerlik.status.kapandi) {
      return 'Askerlik meselen kapandı: ${askerlik.status.label}.';
    }
    // Bakaya kalan da gidip yükümlülüğünü kapatabilir; cezası ayrıca
    // hesaplanır (Paket 31).
    if (state.player.age < prototypeOnlyMinAge) {
      return '$prototypeOnlyMinAge yaşından itibaren katılabilirsin.';
    }
    if (state.education.isStudent) {
      return 'Okurken katılamazsın; okulun bitmesi gerekiyor.';
    }
    switch (track) {
      case MilitaryTrack.er:
        if (!isObliged(state)) {
          return 'Er olarak yükümlülük bu hayatta yok; subay ya da '
              'astsubay olarak başvurabilirsin.';
        }
      case MilitaryTrack.astsubay:
        if (!state.education.finished) {
          return 'Astsubaylık için lise mezunu olman gerekiyor.';
        }
      case MilitaryTrack.subay:
        if (!state.education.universityFinished) {
          return 'Subaylık için üniversite mezunu olman gerekiyor.';
        }
    }
    return '';
  }

  static InteractionAvailability availability(
    GameState state,
    MilitaryTrack track,
  ) {
    final String engel = blockReason(state, track);
    return engel.isEmpty
        ? const InteractionAvailability.allowed()
        : InteractionAvailability.blocked(engel);
  }

  /// prototypeOnly: rütbeli yola kabul ihtimali.
  ///
  /// Zekâ ve sağlık yukarı çeker; er yolunda başvuru yoktur.
  static double prototypeOnlyAcceptChance(
    GameState state,
    MilitaryTrack track,
  ) {
    if (track == MilitaryTrack.er) return 1;
    final double zeka = state.player.stats.intelligence / 100;
    final double saglik = state.player.stats.health / 100;
    return (track.prototypeOnlyBaseChance + zeka * 0.35 + saglik * 0.20).clamp(
      0.05,
      0.95,
    );
  }

  /// Askerliğe katılır ya da rütbeli yola başvurur.
  ///
  /// Rütbeli yollarda başvuru **reddedilebilir**; ret gerçek bir
  /// sonuçtur ve kayda girer.
  static MilitaryResult enlist(
    GameState state,
    MilitaryTrack track,
    Random rng,
  ) {
    final String engel = blockReason(state, track);
    if (engel.isNotEmpty) {
      return MilitaryResult(state: state, applied: false, text: engel);
    }

    if (track != MilitaryTrack.er &&
        rng.nextDouble() >= prototypeOnlyAcceptChance(state, track)) {
      const String metin =
          'Başvurun kabul edilmedi. Sınav ve sağlık '
          'şartlarını bu sefer geçemedin.';
      return MilitaryResult(
        state: _log(state, metin),
        applied: true,
        text: metin,
      );
    }

    final MilitaryRank ilkRutbe = track.ranks.first;
    final String metin = track == MilitaryTrack.er
        ? 'Askere gittin. ${track.prototypeOnlyYears} yıl sürecek.'
        : '${track.label.replaceAll(' ol', '')} olarak kabul edildin: '
              '${ilkRutbe.label}.';

    return MilitaryResult(
      state: _log(
        state.copyWith(
          military: state.military.copyWith(
            status: MilitaryStatus.gorevde,
            trackName: track.name,
            rankId: ilkRutbe.id,
            startedAtAge: state.player.age,
          ),
        ),
        metin,
      ),
      applied: true,
      text: metin,
    );
  }

  // -----------------------------------------------------------------
  // Bedelli
  // -----------------------------------------------------------------

  /// Bedelli ödemeye engel; engel yoksa boş metin.
  static String bedelliBlockReason(GameState state) {
    final MilitaryState askerlik = state.military;
    if (askerlik.isServing) return 'Görevdeyken bedelli ödenmez.';
    if (askerlik.status.kapandi) {
      return 'Askerlik meselen kapandı: ${askerlik.status.label}.';
    }
    if (!isObliged(state)) return 'Bu hayatta askerlik yükümlülüğü yok.';
    // Bakaya kalan da bedelli ödeyebilir; ek bedelle (Paket 31).
    if (state.player.age < prototypeOnlyMinAge) {
      return '$prototypeOnlyMinAge yaşından itibaren ödenebilir.';
    }
    return '';
  }

  /// Bu oyuncunun ödeyeceği bedelli ücreti.
  ///
  /// Bakaya kalanlar **ek bedel** öder: kaçtıkları her yıl için ayrı
  /// bir tutar eklenir (Paket 31).
  static int bedelliCostFor(GameState state) =>
      prototypeOnlyBedelliCost +
      fugitiveYears(state) * prototypeOnlyLateBedelliPerYear;

  /// Bedelliyi **kendi cebinden** öder.
  static MilitaryResult payBedelli(GameState state) {
    final String engel = bedelliBlockReason(state);
    if (engel.isNotEmpty) {
      return MilitaryResult(state: state, applied: false, text: engel);
    }
    final int ucret = bedelliCostFor(state);
    if (state.player.wallet < ucret) {
      return MilitaryResult(
        state: state,
        applied: false,
        text:
            'Bedelli ücreti ${trMoney(ucret)}; '
            'cüzdanında yeterli para yok. Ailenden isteyebilirsin.',
      );
    }
    final String metin =
        'Bedelli askerlik ücretini ödedin: '
        '${trMoney(ucret)}.';
    return MilitaryResult(
      state: _log(
        state.copyWith(
          player: state.player.copyWith(wallet: state.player.wallet - ucret),
          military: state.military.copyWith(
            status: MilitaryStatus.bedelli,
            finishedAtAge: state.player.age,
            fugitiveSinceAge: null,
          ),
        ),
        metin,
      ),
      applied: true,
      text: metin,
    );
  }

  /// Bedelliyi ödeyebilecek yakınlar.
  ///
  /// Uydurma bir hami üretilmez: yalnızca **gerçekten var olan**,
  /// hayatta, varlıklı ve arası iyi olan yakınlar listelenir.
  static List<Person> possiblePayers(GameState state) => state.people
      .where(
        (Person p) =>
            p.isAlive &&
            (p.relation.kanBagi || p.relation == RelationType.es) &&
            p.bond >= prototypeOnlyFamilyMinBond &&
            (p.wealth == WealthTier.varlikli ||
                p.wealth == WealthTier.cokVarlikli),
      )
      .toList(growable: false);

  /// prototypeOnly: bu kişinin ödemeyi kabul etme ihtimali.
  static double prototypeOnlyPayChance(Person person) {
    final double yakinlik = ((person.bond - prototypeOnlyFamilyMinBond) / 45)
        .clamp(0.0, 1.0);
    final double servet = person.wealth == WealthTier.cokVarlikli ? 0.30 : 0.15;
    return (prototypeOnlyFamilyBaseChance + yakinlik * 0.45 + servet).clamp(
      0.05,
      0.95,
    );
  }

  /// Bedelli ücretini bir yakından ister.
  ///
  /// **Ret gerçektir.** Kabul edilirse oyuncunun cüzdanından para
  /// çıkmaz; ödeyen kişi kayda geçer.
  static MilitaryResult askFamilyForBedelli(
    GameState state,
    String personId,
    Random rng,
  ) {
    final String engel = bedelliBlockReason(state);
    if (engel.isNotEmpty) {
      return MilitaryResult(state: state, applied: false, text: engel);
    }
    final Person? kisi = state.personById(personId);
    if (kisi == null || !kisi.isAlive) {
      return MilitaryResult(
        state: state,
        applied: false,
        text: 'Bu kişi kayıtlarda yok.',
      );
    }
    if (!possiblePayers(state).any((Person p) => p.id == personId)) {
      return MilitaryResult(
        state: state,
        applied: false,
        text:
            '${kisi.firstName} bu ücreti karşılayabilecek durumda değil '
            've aranız bunu isteyecek kadar yakın değil.',
      );
    }

    if (rng.nextDouble() >= prototypeOnlyPayChance(kisi)) {
      final String metin =
          '${kisi.firstName} bu sefer yardımcı olamadı. '
          '"Elim sıkışık" dedi, konu kapandı.';
      return MilitaryResult(
        state: _log(state, metin),
        applied: true,
        text: metin,
      );
    }

    final String metin =
        '${kisi.firstName} bedelli ücretini ödedi: '
        '${trMoney(bedelliCostFor(state))}. Cebinden tek kuruş çıkmadı.';
    return MilitaryResult(
      state: _log(
        state.copyWith(
          military: state.military.copyWith(
            status: MilitaryStatus.bedelli,
            finishedAtAge: state.player.age,
            paidByPersonId: personId,
            fugitiveSinceAge: null,
          ),
        ),
        metin,
      ),
      applied: true,
      text: metin,
    );
  }

  // -----------------------------------------------------------------
  // Hizmet süresi
  // -----------------------------------------------------------------

  /// Görevdeyken bir yılı işler; süre dolduysa terhis eder.
  static GameState advanceYear(GameState state, int newAge) {
    final MilitaryState askerlik = state.military;
    if (!askerlik.isServing) return state;
    final MilitaryTrack? yol = askerlik.track;
    final int? baslangic = askerlik.startedAtAge;
    if (yol == null || baslangic == null) return state;

    final int gecen = newAge - baslangic;

    // Hizmet etkileri her yıl uygulanır.
    GameState next = state.copyWith(
      player: state.player.copyWith(
        stats: state.player.stats.copyWith(
          health: state.player.stats.health + prototypeOnlyServiceHealth,
          charisma: state.player.stats.charisma + prototypeOnlyServiceCharisma,
          happiness:
              state.player.stats.happiness + prototypeOnlyServiceHappiness,
        ),
        // Meslek olarak askerlikte maaş yıllık yatar.
        wallet: state.player.wallet + yol.prototypeOnlySalary,
      ),
    );

    // Rütbe zamanla yükselir.
    final int basamak = (gecen ~/ 2).clamp(0, yol.ranks.length - 1);
    final MilitaryRank yeniRutbe = yol.ranks[basamak];
    if (yeniRutbe.id != askerlik.rankId) {
      next = _log(
        next.copyWith(military: next.military.copyWith(rankId: yeniRutbe.id)),
        '${yeniRutbe.label} oldun.',
      );
    }

    if (gecen < yol.prototypeOnlyYears) return next;

    // Süre doldu: terhis.
    final String metin = yol == MilitaryTrack.er
        ? 'Askerliğin bitti, terhis oldun.'
        : '${next.military.rank?.label ?? 'Subay'} olarak görev süren '
              'tamamlandı.';
    return _log(
      next.copyWith(
        military: next.military.copyWith(
          status: MilitaryStatus.tamamlandi,
          finishedAtAge: newAge,
        ),
        player: next.player.copyWith(
          stats: next.player.stats.copyWith(
            happiness:
                next.player.stats.happiness + prototypeOnlyDischargeHappiness,
          ),
        ),
        notices: List<PendingNotice>.unmodifiable(<PendingNotice>[
          ...next.notices,
          Notices.militaryDischarge(
            playerAge: newAge,
            rankLabel: next.military.rank?.label,
          ),
        ]),
      ),
      metin,
    );
  }

  static GameState _log(GameState state, String text) => state.copyWith(
    log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
      ...state.log,
      LifeLogEntry(
        age: state.player.age,
        text: text,
        category: LogCategory.kisisel,
      ),
    ]),
  );
}
