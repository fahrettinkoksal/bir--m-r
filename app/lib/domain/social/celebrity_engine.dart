/// Ünlülerle temas: yorum, mesaj ve iş birliği (Faho'nun isteği).
///
/// Kurallar:
/// - **Ret gerçektir.** Çoğu deneme karşılıksız kalır; "her zaman evet"
///   diyen sahte bir akış yoktur. Büyük isme yazmak, küçük isme yazmaktan
///   belirgin olarak zordur.
/// - Ünlü kataloğu kurgusaldır; gerçek kişi kullanılmaz.
/// - Ünlü **kendiliğinden** İlişkiler ekranına girmez. Ancak geri takip
///   ettiğinde kalıcı bir kişi kaydı açılır: o an gerçekten bir bağ
///   kurulmuştur.
/// - Bir ünlüye **yılda en fazla iki kez** yazılabilir. Üst üste yazmak
///   "ısrarcı" sayılır ve karşılık ihtimalini düşürür.
/// - Kazanılan takipçi uydurulmaz: oyuncunun mevcut kitlesine ve ünlünün
///   büyüklüğüne bağlı hesaplanır, cüzdana ve kitleye **gerçekten**
///   işlenir.
///
/// Sayısal değerler `prototypeOnly`'dir
/// (`docs/DESIGN_REVIEW_QUEUE.md`, Q-115).
library;

import 'dart:math';

import '../../data/celebrity_catalog.dart';
import '../../text/turkish_text.dart';
import '../models/celebrity_contact.dart';
import '../models/game_state.dart';
import '../models/interaction.dart';
import '../models/life_log.dart';
import '../models/person.dart';
import '../models/relation.dart';
import '../models/social_account.dart';
import '../models/wealth.dart';

/// Ünlüyle kurulabilecek temas türü.
enum CelebrityAction {
  yorum(
    'Paylaşımına yorum yap',
    'Binlerce yorumun arasında bir tane daha. Ucuz ama zayıf.',
  ),
  mesaj('Mesaj at', 'Doğrudan kutusuna yaz. Görülmesi kitlene bağlı.'),
  isBirligi(
    'İş birliği teklif et',
    'Birlikte içerik üretmeyi öner. Büyük karşılık, büyük ret.',
  );

  const CelebrityAction(this.label, this.description);

  final String label;
  final String description;
}

/// Bir temasın sonucu.
enum CelebrityOutcomeKind {
  gorulmedi,
  begendi,
  cevapVerdi,
  geriTakip,
  isBirligi,
  tersCevap,
}

class CelebrityResult {
  const CelebrityResult({
    required this.state,
    required this.applied,
    required this.text,
    this.kind,
    this.followerDelta = 0,
    this.earned = 0,
  });

  final GameState state;
  final bool applied;
  final String text;
  final CelebrityOutcomeKind? kind;
  final int followerDelta;
  final int earned;
}

abstract final class CelebrityEngine {
  /// prototypeOnly: bir ünlüye yılda kaç kez yazılabilir.
  ///
  /// Faho'nun Q-115 kararı: yılda **bir** azdı, **iki** oldu. Israrın
  /// bedeli duruyor: ikinci deneme birinciden belirgin olarak zor
  /// (D-106).
  static const int prototypeOnlyTriesPerAge = 2;

  /// prototypeOnly: eylemin taban karşılık çarpanı.
  ///
  /// Yorum ucuzdur ama zayıftır; iş birliği en zorudur.
  static const Map<CelebrityAction, double> prototypeOnlyActionFactor =
      <CelebrityAction, double>{
        CelebrityAction.yorum: 0.55,
        CelebrityAction.mesaj: 1.0,
        CelebrityAction.isBirligi: 0.45,
      };

  /// prototypeOnly: karizmanın karşılık ihtimaline katkısı.
  static const double prototypeOnlyCharismaWeight = 0.25;

  /// prototypeOnly: Ünün karşılık ihtimaline katkısı.
  static const double prototypeOnlyFameWeight = 0.30;

  /// prototypeOnly: ısrarcı denemelerin her biri için uygulanan azaltma.
  static const double prototypeOnlyPersistencePenalty = 0.12;

  /// prototypeOnly: en yüksek karşılık ihtimali. Hiçbir zaman garanti yok.
  static const double prototypeOnlyMaxChance = 0.85;

  /// prototypeOnly: iş birliği için gereken en az Ün.
  static const int prototypeOnlyCollabMinFame = 25;

  /// prototypeOnly: ünlünün kitlesinden oyuncuya geçen pay.
  static const double prototypeOnlyReachShare = 0.0016;

  /// prototypeOnly: sonuç türüne göre kazanç çarpanı.
  static const Map<CelebrityOutcomeKind, double> prototypeOnlyGainFactor =
      <CelebrityOutcomeKind, double>{
        CelebrityOutcomeKind.begendi: 0.25,
        CelebrityOutcomeKind.cevapVerdi: 0.60,
        CelebrityOutcomeKind.geriTakip: 1.30,
        CelebrityOutcomeKind.isBirligi: 2.40,
      };

  /// prototypeOnly: ters cevabın kitleye verdiği kayıp oranı.
  static const double prototypeOnlyBacklashRatio = 0.05;

  /// prototypeOnly: iş birliğinin getirdiği ücret, ünlü büyüklüğüne göre.
  static const double prototypeOnlyCollabFeePerFollower = 0.06;

  // -------------------------------------------------------------------
  // Uygunluk
  // -------------------------------------------------------------------

  /// Bu yıl bu ünlüye kaç kez yazıldı?
  static int triesThisAge(GameState state, Celebrity celebrity) =>
      state.interactionCount('unlu', celebrity.id);

  /// Temasa engel; engel yoksa boş metin.
  static String blockReason(
    GameState state,
    Celebrity celebrity,
    CelebrityAction action,
  ) {
    final SocialAccount? hesap = state.accountFor(celebrity.platform);
    if (hesap == null) {
      return '${celebrity.firstName} ${celebrity.platform.label} '
          'kullanıyor; önce orada hesabın olması gerekiyor.';
    }
    if (triesThisAge(state, celebrity) >= prototypeOnlyTriesPerAge) {
      return 'Bu yıl ${celebrity.firstName} ile '
          '$prototypeOnlyTriesPerAge kez iletişime geçtin; bu yıllık '
          'hakkın. Üst üste yazmak işe yaramıyor.';
    }
    if (action == CelebrityAction.isBirligi) {
      final int un = state.player.fame ?? 0;
      if (un < prototypeOnlyCollabMinFame) {
        return 'İş birliği teklif etmek için tanınman gerekiyor: '
            'en az $prototypeOnlyCollabMinFame Ün.';
      }
      final CelebrityContact? temas = state.contactWith(celebrity.id);
      if (temas == null || !temas.replied) {
        return '${celebrity.firstName} seni henüz tanımıyor. Önce '
            'cevap alman gerekiyor.';
      }
    }
    return '';
  }

  static InteractionAvailability availability(
    GameState state,
    Celebrity celebrity,
    CelebrityAction action,
  ) {
    final String engel = blockReason(state, celebrity, action);
    return engel.isEmpty
        ? const InteractionAvailability.allowed()
        : InteractionAvailability.blocked(engel);
  }

  /// Bu temasın karşılık bulma ihtimali.
  ///
  /// Oyuncuya **yaklaşık** olarak gösterilebilir; gizlenmez.
  static double replyChance(
    GameState state,
    Celebrity celebrity,
    CelebrityAction action,
  ) {
    final SocialAccount? hesap = state.accountFor(celebrity.platform);
    if (hesap == null) return 0;

    // Kitlesi eşiğin çok altında olan fark edilmez; eşiğe yaklaştıkça
    // ihtimal açılır.
    final double gorunurluk =
        (hesap.followers / celebrity.prototypeOnlyNoticeThreshold).clamp(
          0.0,
          1.0,
        );

    final double karizma =
        state.player.stats.charisma / 100 * prototypeOnlyCharismaWeight;
    final double un = (state.player.fame ?? 0) / 100 * prototypeOnlyFameWeight;

    final CelebrityContact? temas = state.contactWith(celebrity.id);
    final int israr = temas?.attempts ?? 0;
    final double israrCezasi = (1 - israr * prototypeOnlyPersistencePenalty)
        .clamp(0.25, 1.0);

    // Daha önce cevap almışsa kapı aralık kalır.
    final double tanisiklik = (temas?.followsBack ?? false)
        ? 0.35
        : (temas?.replied ?? false)
        ? 0.18
        : 0.0;

    final double taban =
        celebrity.prototypeOnlyApproachability *
        (prototypeOnlyActionFactor[action] ?? 1.0);

    return ((taban * gorunurluk + karizma + un + tanisiklik) * israrCezasi)
        .clamp(0.0, prototypeOnlyMaxChance);
  }

  static int displayChancePercent(
    GameState state,
    Celebrity celebrity,
    CelebrityAction action,
  ) => (replyChance(state, celebrity, action) * 100).round();

  // -------------------------------------------------------------------
  // Temas
  // -------------------------------------------------------------------

  /// Ünlüyle temas kurar.
  static CelebrityResult contact({
    required GameState state,
    required Celebrity celebrity,
    required CelebrityAction action,
    required Random rng,
  }) {
    final String engel = blockReason(state, celebrity, action);
    if (engel.isNotEmpty) {
      return CelebrityResult(state: state, applied: false, text: engel);
    }

    final SocialAccount hesap = state.accountFor(celebrity.platform)!;
    final CelebrityContact onceki =
        state.contactWith(celebrity.id) ??
        CelebrityContact(celebrityId: celebrity.id);

    final double sans = replyChance(state, celebrity, action);
    final double zar = rng.nextDouble();

    final CelebrityOutcomeKind sonuc = _outcomeFor(
      action: action,
      onceki: onceki,
      sans: sans,
      zar: zar,
      rng: rng,
    );

    // Takipçi değişimi: ünlünün kitlesinden bir pay, sonuç türüne göre.
    int delta = 0;
    if (sonuc == CelebrityOutcomeKind.tersCevap) {
      delta = -(hesap.followers * prototypeOnlyBacklashRatio).round();
    } else {
      final double carpan = prototypeOnlyGainFactor[sonuc] ?? 0;
      delta = (celebrity.followers * prototypeOnlyReachShare * carpan).round();
    }

    final int yeniTakipci = (hesap.followers + delta).clamp(0, 1 << 30);
    final int gercekDelta = yeniTakipci - hesap.followers;

    final int ucret = sonuc == CelebrityOutcomeKind.isBirligi
        ? (celebrity.followers * prototypeOnlyCollabFeePerFollower).round()
        : 0;

    GameState next = state.copyWith(
      socialAccounts: List<SocialAccount>.unmodifiable(
        state.socialAccounts
            .map(
              (SocialAccount a) => a.platform == celebrity.platform
                  ? a.copyWith(followers: yeniTakipci)
                  : a,
            )
            .toList(growable: false),
      ),
      interactionCounts: Map<String, int>.unmodifiable(<String, int>{
        ...state.interactionCounts,
        GameState.interactionKey('unlu', celebrity.id):
            triesThisAge(state, celebrity) + 1,
      }),
    );

    if (ucret > 0) {
      next = next.copyWith(
        player: next.player.copyWith(wallet: next.player.wallet + ucret),
      );
    }

    final CelebrityContact guncel = onceki.copyWith(
      attempts: onceki.attempts + 1,
      replied:
          onceki.replied ||
          sonuc == CelebrityOutcomeKind.cevapVerdi ||
          sonuc == CelebrityOutcomeKind.geriTakip ||
          sonuc == CelebrityOutcomeKind.isBirligi,
      followsBack:
          onceki.followsBack ||
          sonuc == CelebrityOutcomeKind.geriTakip ||
          sonuc == CelebrityOutcomeKind.isBirligi,
      collaborated:
          onceki.collaborated || sonuc == CelebrityOutcomeKind.isBirligi,
      firstContactAge: onceki.firstContactAge ?? state.player.age,
      lastContactAge: state.player.age,
    );

    next = next.copyWith(
      celebrityContacts: List<CelebrityContact>.unmodifiable(<CelebrityContact>[
        for (final CelebrityContact c in next.celebrityContacts)
          if (c.celebrityId != celebrity.id) c,
        guncel,
      ]),
    );

    // Geri takip ettiği an gerçek bir bağ kurulmuştur: kişi kaydı açılır.
    if (guncel.followsBack && !_hasPerson(next, celebrity)) {
      next = next.copyWith(
        people: List<Person>.unmodifiable(<Person>[
          ...next.people,
          _personFor(celebrity, state.player.age, rng),
        ]),
      );
    }

    final String metin = _text(
      celebrity: celebrity,
      action: action,
      sonuc: sonuc,
      delta: gercekDelta,
      ucret: ucret,
      platform: celebrity.platform.audienceWord,
    );

    // Günlüğe yalnızca gerçekten bir şey olduysa yazılır; karşılıksız
    // denemeler günlüğü doldurmaz.
    if (sonuc != CelebrityOutcomeKind.gorulmedi) {
      next = _log(next, metin);
    }

    return CelebrityResult(
      state: next,
      applied: true,
      text: metin,
      kind: sonuc,
      followerDelta: gercekDelta,
      earned: ucret,
    );
  }

  static CelebrityOutcomeKind _outcomeFor({
    required CelebrityAction action,
    required CelebrityContact onceki,
    required double sans,
    required double zar,
    required Random rng,
  }) {
    // Israrcı olup hâlâ karşılık alamayan, bir noktada alenen ters
    // cevap alabilir. Bu nadirdir ve yalnızca çok denemişte olur.
    if (zar >= sans) {
      final bool israrci = onceki.attempts >= 3 && !onceki.replied;
      if (israrci && rng.nextDouble() < 0.18) {
        return CelebrityOutcomeKind.tersCevap;
      }
      return CelebrityOutcomeKind.gorulmedi;
    }

    if (action == CelebrityAction.isBirligi) {
      return CelebrityOutcomeKind.isBirligi;
    }

    // Karşılık geldi; derecesi zarın eşiğe ne kadar uzak düştüğüne bağlı.
    final double oran = sans <= 0 ? 0 : (sans - zar) / sans;
    if (oran > 0.7) return CelebrityOutcomeKind.geriTakip;
    if (oran > 0.35) return CelebrityOutcomeKind.cevapVerdi;
    return CelebrityOutcomeKind.begendi;
  }

  static bool _hasPerson(GameState state, Celebrity celebrity) =>
      state.people.any((Person p) => p.id == _personId(celebrity));

  static String _personId(Celebrity celebrity) => 'unlu-${celebrity.id}';

  /// Ünlünün kalıcı kişi kaydı.
  ///
  /// Yaşı ve durumu uydurma değil, makul bir aralıktan seçilir; kimlik
  /// katalogdan gelir ve değişmez.
  static Person _personFor(Celebrity celebrity, int playerAge, Random rng) {
    return Person(
      id: _personId(celebrity),
      firstName: celebrity.firstName,
      lastName: celebrity.lastName,
      gender: celebrity.gender,
      relation: RelationType.unlu,
      isAlive: true,
      inPlayerHousehold: false,
      employment: EmploymentStatus.calisiyor,
      wealth: WealthTier.cokVarlikli,
      age: (playerAge - 6 + rng.nextInt(16)).clamp(22, 70),
      bond: 30,
      occupation: celebrity.field.label,
    );
  }

  static String _text({
    required Celebrity celebrity,
    required CelebrityAction action,
    required CelebrityOutcomeKind sonuc,
    required int delta,
    required int ucret,
    required String platform,
  }) {
    final String ad = celebrity.firstName;
    switch (sonuc) {
      case CelebrityOutcomeKind.gorulmedi:
        return action == CelebrityAction.yorum
            ? 'Yorumun binlercesinin arasında kaldı. $ad görmedi.'
            : '$ad okumadı bile. Kutusu senin gibi yüzlerce mesajla dolu.';
      case CelebrityOutcomeKind.begendi:
        return '$ad yazdığını beğendi. Küçük bir şey ama gördü: '
            '$delta $platform kazandın.';
      case CelebrityOutcomeKind.cevapVerdi:
        return '$ad cevap yazdı. Uzun değil, ama gerçek: '
            '$delta $platform kazandın.';
      case CelebrityOutcomeKind.geriTakip:
        return '$ad seni geri takip etti. Bildirim geldiğinde iki kez '
            'baktın. $delta $platform kazandın.';
      case CelebrityOutcomeKind.isBirligi:
        return '$ad ile birlikte iş yaptınız. ${trMoney(ucret)} kazandın '
            've $delta $platform geldi.';
      case CelebrityOutcomeKind.tersCevap:
        return '$ad ısrarını herkese açık biçimde yazdı. Altına yorumlar '
            'yağdı; ${-delta} $platform kaybettin.';
    }
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
