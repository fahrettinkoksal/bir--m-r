/// Kefalet, tutukluluktan çıkış ve cezaevi hayatı (D-139, D-140).
///
/// Faho'nun isteği: "para ile çıkabilelim, kefalet ücretiymiydi neydi;
/// aileden ödemesini isteyebilelim veya paramız var ise biz ödeyelim;
/// avukat tutabilelim; içeride hapishanede arkadaşlar edinebilelim;
/// ileride çete eklicez, onun ilk adımları gibi düşün."
///
/// **Ne yapar:** tutuklu oyuncunun kefaletini kendi yatırmasını ya da
/// aileden istemesini sağlar; içerideki yılları koğuş arkadaşlığı, iyi hâl
/// ve "sözü geçen gruba yakın durma" ile doldurur.
///
/// **Ne yapmaz:** kaçış, saklanma, içeride suç işleme, gardiyan atlatma,
/// yasak madde ya da herhangi bir yöntem **anlatmaz ve modellemez**.
/// Seçenekler yüksek seviyede insan tutumlarıdır: konuşmak, sakin durmak,
/// bir gruba yakın durmak ya da uzak durmak.
///
/// Kefalet **teminattır**: tutukluluğu kaldırır, verilmiş bir hapis
/// cezasını satın almaz. Duruşmaya çıkılınca geri verilir
/// ([LegalEngine] içinde).
///
/// Çete tarafı bilinçli olarak **sayaçta** bırakıldı: `crewStanding`
/// yükselir, cezaevi metinleri değişir ve koşullu salıverilme kapanır.
/// Dışarıda örgüt kurma bu sürümde yoktur (`docs/DESIGN_REVIEW_QUEUE.md`,
/// Q-148).
///
/// Bütün sayılar `prototypeOnly`'dir.
library;

import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../data/name_pool.dart';
import '../../text/turkish_text.dart';
import '../generation/random_util.dart';
import '../models/applied_effect.dart';
import '../models/criminal_record.dart';
import '../models/game_state.dart';
import '../models/gender.dart';
import '../models/life_log.dart';
import '../models/pending_notice.dart';
import '../models/person.dart';
import '../models/relation.dart';
import '../models/wealth.dart';

/// Cezaevinde yapılabilecek şeyler.
enum PrisonAction {
  kogustaSohbet(
    'Koğuşta sohbet et',
    'Aynı koridorda yıllar geçiyor; birileriyle konuşmadan olmuyor.',
  ),
  iyiHalGoster(
    'Kurallara uy, sakin dur',
    'Tartışmanın kenarından dolaşırsın. İyi hâl dosyana yazılır.',
  ),
  grubaYaklas(
    'Sözü geçen gruba yakın dur',
    'Koğuşta ağırlığı olan bir grup var. Yanlarında durmak seni bazı '
        'şeylerden korur, bazı şeylere de bağlar.',
  ),
  gruptanUzakDur(
    'Gruptan uzaklaş',
    'Selamı kesersin. Kolay değil ama dosyan temizlenir.',
  );

  const PrisonAction(this.label, this.description);

  final String label;
  final String description;
}

/// Bir cezaevi eyleminin ya da kefalet işleminin sonucu.
@immutable
class PrisonOutcome {
  const PrisonOutcome({
    required this.applied,
    required this.text,
    this.effects = const <AppliedEffect>[],
  });

  /// İşlem gerçekten uygulandı mı? Uygulanmadıysa [text] gerekçedir.
  final bool applied;

  final String text;
  final List<AppliedEffect> effects;
}

abstract final class PrisonLife {
  /// prototypeOnly: aynı yaşta bir eylem kaç kez anlamlı sonuç verir.
  static const int prototypeOnlyMaxPerAge = 2;

  /// prototypeOnly: cezaevi eylemlerinin sayaç kapsamı.
  ///
  /// `interactionCounts` her yaşta sıfırlanır; ayrı bir kayıt alanı
  /// açmaya gerek yoktur.
  static const String counterScope = 'cezaevi';

  /// prototypeOnly: bir hükümlülükte tanışılabilecek en fazla kişi.
  static const int prototypeOnlyMaxCellmates = 3;

  /// prototypeOnly: koğuş arkadaşlığının başlangıç yakınlığı.
  ///
  /// İçeride tanışmak yakın arkadaş olmak değildir; düşük başlar.
  static const int prototypeOnlyStartBond = 30;

  /// prototypeOnly: aileden kefalet isteğinin reddedilme ihtimalinin
  /// tabanı. Yakınlık ve karşı tarafın hâli bunu aşağı çeker.
  static const double prototypeOnlyRefusalBase = 0.55;

  // =====================================================================
  // Kefalet
  // =====================================================================

  /// Kefaleti **kendi** yatırmak şu an mümkün mü? Değilse gerekçe döner.
  static String selfBailBlockReason(GameState state) {
    final LegalState hukuk = state.legal;
    if (!hukuk.isDetained) return 'Şu an tutuklu değilsin.';
    if (hukuk.bailPaid) return 'Kefalet zaten yatırıldı.';
    final int? kefalet = hukuk.bailAmount;
    if (kefalet == null || kefalet <= 0) {
      return 'Bu dosyada kefalet belirlenmedi.';
    }
    if (state.player.wallet < kefalet) {
      return 'Kefalet ${trMoney(kefalet)}; cüzdanında '
          '${trMoney(state.player.wallet)} var.';
    }
    return '';
  }

  /// Kefaleti oyuncu kendi cüzdanından yatırır.
  static ({GameState state, PrisonOutcome outcome}) payBailSelf(
    GameState state,
  ) {
    final String engel = selfBailBlockReason(state);
    if (engel.isNotEmpty) {
      return (
        state: state,
        outcome: PrisonOutcome(applied: false, text: engel),
      );
    }
    final int kefalet = state.legal.bailAmount!;
    GameState next = state.copyWith(
      player: state.player.copyWith(
        wallet: state.player.wallet - kefalet,
        stats: state.player.stats.gain(happiness: 6),
      ),
      legal: state.legal.copyWith(
        detainedSinceAge: null,
        bailPaidBy: LegalState.selfPaidBail,
      ),
    );
    const String metin = 'Kefaleti yatırdın. Kapıdan çıktın; dosya '
        'kapanmadı, yargılama dışarıda sürecek.';
    next = _log(next, 'Kefaleti kendin yatırdın ve tahliye edildin.');
    next = _notice(
      next,
      id: 'kefalet-odendi-${next.player.age}',
      title: 'Kefaletle çıktın',
      text: '$metin\n\n'
          'Yatırdığın ${trMoney(kefalet)} teminattır: duruşmaya '
          'çıktığında geri verilir.',
      money: -kefalet,
    );
    return (
      state: next,
      outcome: PrisonOutcome(
        applied: true,
        text: metin,
        effects: <AppliedEffect>[
          AppliedEffect(label: 'Kefalet', delta: -kefalet, unit: ' ₺'),
          const AppliedEffect(label: 'Tutukluluk', delta: null),
        ],
      ),
    );
  }

  /// Kefaleti isteyebileceğin kişiler.
  ///
  /// Kendi parasını kazanan, hayatta ve yeterince yakın olan yetişkinler.
  /// Liste **boş dönebilir**: kimsesi olmayan oyuncuya sahte bir kapı
  /// gösterilmez.
  static List<Person> bailHelpers(GameState state) {
    if (!state.legal.isDetained || state.legal.bailPaid) {
      return const <Person>[];
    }
    return state.people
        .where(
          (Person p) =>
              p.isAlive &&
              p.age >= 18 &&
              p.wealth != null &&
              p.bond >= _minBond &&
              _canBeAsked(p.relation),
        )
        .toList(growable: false);
  }

  static const int _minBond = 30;

  static bool _canBeAsked(RelationType relation) => switch (relation) {
        RelationType.anne ||
        RelationType.baba ||
        RelationType.uveyAnne ||
        RelationType.uveyBaba ||
        RelationType.kardes ||
        RelationType.es ||
        RelationType.anneanne ||
        RelationType.babaanne ||
        RelationType.anneTarafiDede ||
        RelationType.babaTarafiDede ||
        RelationType.teyze ||
        RelationType.dayi ||
        RelationType.hala ||
        RelationType.amca ||
        RelationType.cocuk =>
          true,
        _ => false,
      };

  /// Aileden kefaleti ödemesini ister.
  ///
  /// Sonuç garanti değildir: yakınlık ve karşı tarafın ekonomik hâli
  /// belirler. Aynı yıl ikinci kez istenmez — israr bir mekanik değildir.
  static ({GameState state, PrisonOutcome outcome}) askFamilyForBail({
    required GameState state,
    required String personId,
    required Random rng,
  }) {
    final LegalState hukuk = state.legal;
    if (!hukuk.isDetained) {
      return (
        state: state,
        outcome: const PrisonOutcome(
          applied: false,
          text: 'Şu an tutuklu değilsin.',
        ),
      );
    }
    if (hukuk.bailPaid) {
      return (
        state: state,
        outcome: const PrisonOutcome(
          applied: false,
          text: 'Kefalet zaten yatırıldı.',
        ),
      );
    }
    if (hukuk.bailAskedAtAge == state.player.age) {
      return (
        state: state,
        outcome: const PrisonOutcome(
          applied: false,
          text: 'Bu yıl zaten istedin. Israr etmenin faydası yok.',
        ),
      );
    }
    final Person? kisi = state.personById(personId);
    final int? kefalet = hukuk.bailAmount;
    if (kisi == null || kefalet == null || kefalet <= 0) {
      return (
        state: state,
        outcome: const PrisonOutcome(
          applied: false,
          text: 'Bu kişiden kefalet istenemez.',
        ),
      );
    }

    // Red ihtimali: yakınlık ve karşı tarafın hâli. Zengin bir yakın
    // "olur" der, dar gelirli bir yakın isteyip de yapamaz.
    final double varlik = switch (kisi.wealth) {
      WealthTier.cokVarlikli => 0.35,
      WealthTier.varlikli => 0.25,
      WealthTier.ortaHalli => 0.10,
      WealthTier.yoksul => -0.10,
      WealthTier.cokYoksul => -0.20,
      null => -0.20,
    };
    final double red = (prototypeOnlyRefusalBase -
            (kisi.bond - _minBond) / 140 -
            varlik)
        .clamp(0.05, 0.9);
    final bool kabul = rng.nextDouble() >= red;

    GameState next = state.copyWith(
      legal: hukuk.copyWith(bailAskedAtAge: state.player.age),
    );

    if (!kabul) {
      next = _withBond(next, personId, -2);
      final String metin = '${kisi.firstName} telefonu kapatmadı ama '
          '"o kadar param yok" dedi. Sesinde utanma vardı.';
      next = _log(next, '${kisi.firstName} kefaleti ödeyemedi.');
      next = _notice(
        next,
        id: 'kefalet-red-$personId-${next.player.age}',
        title: 'Kefalet çıkmadı',
        text: metin,
        personId: personId,
      );
      return (
        state: next,
        outcome: PrisonOutcome(applied: true, text: metin),
      );
    }

    next = next.copyWith(
      legal: next.legal.copyWith(
        detainedSinceAge: null,
        bailPaidBy: personId,
      ),
      player: next.player.copyWith(
        // Çıkmak iyi geldi, borçlu olmak iyi gelmedi.
        stats: next.player.stats.gain(happiness: 4),
      ),
    );
    next = _withBond(next, personId, 4);
    final String metin = '${kisi.firstName} kefaleti yatırdı. Kapıda '
        'bekliyordu; ikiniz de az konuştunuz.';
    next = _log(next, '${kisi.firstName} kefaleti yatırdı, tahliye edildin.');
    next = _notice(
      next,
      id: 'kefalet-aile-$personId-${next.player.age}',
      title: 'Kefaletle çıktın',
      text: '$metin\n\n'
          'Yatırılan ${trMoney(kefalet)} teminattır: duruşmaya '
          'çıktığında geri ödenir ve parayı ${kisi.firstName}\'a geri '
          'verirsin.',
      personId: personId,
    );
    return (
      state: next,
      outcome: PrisonOutcome(
        applied: true,
        text: metin,
        effects: <AppliedEffect>[
          const AppliedEffect(label: 'Tutukluluk', delta: null),
          AppliedEffect(label: '${kisi.firstName} ile yakınlık', delta: 4),
        ],
      ),
    );
  }

  // =====================================================================
  // Cezaevi hayatı
  // =====================================================================

  /// İçeride tanışılmış kişiler.
  static List<Person> cellmates(GameState state) => state.people
      .where((Person p) => p.relation == RelationType.kogusArkadasi)
      .toList(growable: false);

  /// Bu eylem bu yıl kaç kez yapıldı?
  static int timesDone(GameState state, PrisonAction action) =>
      state.interactionCount(counterScope, action.name);

  /// Eylem şu an yapılabilir mi? Yapılamıyorsa gerekçe döner.
  static String blockReason(GameState state, PrisonAction action) {
    if (!state.isImprisoned) return 'Bu yalnızca içerideyken yapılabilir.';
    if (timesDone(state, action) >= prototypeOnlyMaxPerAge) {
      return 'Bu yıl için yeterince yaptın; seneye yeniden açılır.';
    }
    switch (action) {
      case PrisonAction.kogustaSohbet:
        return '';
      case PrisonAction.iyiHalGoster:
        return '';
      case PrisonAction.grubaYaklas:
        // Tutuklu koğuşunda böyle bir yapı kurulmaz; hükümlülükte olur.
        if (!state.legal.isSentenced) {
          return 'Tutukluluk koğuşunda böyle bir şey yok.';
        }
        return '';
      case PrisonAction.gruptanUzakDur:
        if (state.legal.crewStanding <= 0) {
          return 'Uzaklaşacak bir grup yok.';
        }
        return '';
    }
  }

  /// Bir cezaevi eylemini uygular.
  static ({GameState state, PrisonOutcome outcome}) perform({
    required GameState state,
    required PrisonAction action,
    required Random rng,
  }) {
    final String engel = blockReason(state, action);
    if (engel.isNotEmpty) {
      return (
        state: state,
        outcome: PrisonOutcome(applied: false, text: engel),
      );
    }

    final ({GameState state, PrisonOutcome outcome}) sonuc = switch (action) {
      PrisonAction.kogustaSohbet => _talk(state, rng),
      PrisonAction.iyiHalGoster => _behave(state, rng),
      PrisonAction.grubaYaklas => _joinCrew(state, rng),
      PrisonAction.gruptanUzakDur => _leaveCrew(state),
    };
    if (!sonuc.outcome.applied) return sonuc;
    return (state: _countUse(sonuc.state, action), outcome: sonuc.outcome);
  }

  /// Koğuşta sohbet: yeni biriyle tanışılır ya da tanışıklık derinleşir.
  static ({GameState state, PrisonOutcome outcome}) _talk(
    GameState state,
    Random rng,
  ) {
    final List<Person> mevcut = cellmates(state);
    final bool yeniTanisma = mevcut.length < prototypeOnlyMaxCellmates &&
        rng.nextDouble() < 0.6;

    if (!yeniTanisma) {
      if (mevcut.isEmpty) {
        const String metin = 'Kimse konuşmak istemedi. Avluda bir tur '
            'attın, içeri girdin.';
        return (
          state: _log(state, metin),
          outcome: const PrisonOutcome(applied: true, text: metin),
        );
      }
      final Person kisi = mevcut[rng.nextInt(mevcut.length)];
      GameState next = _withBond(state, kisi.id, 6);
      next = next.copyWith(
        player: next.player.copyWith(
          stats: next.player.stats.gain(happiness: 3),
        ),
      );
      final String metin = '${kisi.firstName} ile uzun uzun konuştunuz. '
          'İkinizin de anlatacak şeyi varmış.';
      next = _log(next, metin);
      return (
        state: next,
        outcome: PrisonOutcome(
          applied: true,
          text: metin,
          effects: <AppliedEffect>[
            AppliedEffect(label: '${kisi.firstName} ile yakınlık', delta: 6),
            const AppliedEffect(label: 'Mutluluk', delta: 3),
          ],
        ),
      );
    }

    final Person yeni = _makeCellmate(state, rng);
    GameState next = state.copyWith(
      people: List<Person>.unmodifiable(<Person>[...state.people, yeni]),
      player: state.player.copyWith(
        stats: state.player.stats.gain(happiness: 4),
      ),
    );
    final String metin = 'Koğuşta ${yeni.firstName} ile tanıştın. '
        'Neden içeride olduğunu sormadın, o da sormadı.';
    next = _log(next, metin);
    next = _notice(
      next,
      id: 'kogus-${yeni.id}',
      title: 'Koğuşta tanıştın',
      text: '$metin\n\n'
          'Bu tanışıklık kayda girdi: tahliye olsan da ${yeni.firstName} '
          'listende kalacak.',
      personId: yeni.id,
    );
    return (
      state: next,
      outcome: PrisonOutcome(
        applied: true,
        text: metin,
        effects: <AppliedEffect>[
          AppliedEffect(label: '${yeni.firstName} tanıdın', delta: null),
          const AppliedEffect(label: 'Mutluluk', delta: 4),
        ],
      ),
    );
  }

  /// Kurallara uymak: iyi hâl yükselir, grubun yanındaki itibar düşer.
  static ({GameState state, PrisonOutcome outcome}) _behave(
    GameState state,
    Random rng,
  ) {
    final int artis = 12 + rng.nextInt(7);
    final int dusus = state.legal.crewStanding > 0 ? 6 : 0;
    GameState next = state.copyWith(
      legal: state.legal.copyWith(
        goodBehaviour: state.legal.goodBehaviour + artis,
        crewStanding: state.legal.crewStanding - dusus,
      ),
      player: state.player.copyWith(
        // Sıkıcı ama işe yarıyor.
        stats: state.player.stats.gain(happiness: -1, health: 1),
      ),
    );
    final String metin = state.legal.crewStanding > 0
        ? 'Tartışmanın kenarından dolaştın. Koğuşta birileri bunu '
            'not etti; memur da not etti.'
        : 'Sayımda hazır, tartışmada yoksun. İyi hâl dosyana yazıldı.';
    next = _log(next, metin);
    return (
      state: next,
      outcome: PrisonOutcome(
        applied: true,
        text: metin,
        effects: <AppliedEffect>[
          AppliedEffect(label: 'İyi hâl', delta: artis),
          if (dusus > 0)
            AppliedEffect(label: 'Koğuştaki itibar', delta: -dusus),
        ],
      ),
    );
  }

  /// Sözü geçen gruba yakın durmak (çeteleşmenin ilk adımı).
  ///
  /// Metin bilinçli olarak **yöntemsizdir**: ne yapıldığı anlatılmaz,
  /// yalnızca yanlarında durmanın karşılığı ve bedeli yazılır.
  static ({GameState state, PrisonOutcome outcome}) _joinCrew(
    GameState state,
    Random rng,
  ) {
    final int artis = 14 + rng.nextInt(7);
    final int iyiHalKaybi = 10;
    GameState next = state.copyWith(
      legal: state.legal.copyWith(
        crewStanding: state.legal.crewStanding + artis,
        goodBehaviour: state.legal.goodBehaviour - iyiHalKaybi,
      ),
      player: state.player.copyWith(
        // Korunuyorsun; kimse sana bulaşmıyor. Karşılığını da biliyorsun.
        stats: state.player.stats.gain(happiness: 3, health: -1),
      ),
    );
    final String metin = state.legal.crewStanding == 0
        ? 'Koğuşta sözü geçenlerin masasına oturdun. Kimse bir şey '
            'sormadı, herkes anladı.'
        : 'Aranız daha da yakınlaştı. Artık seni sayıyorlar; bu iş '
            'karşılıklı.';
    next = _log(next, metin);
    next = _notice(
      next,
      id: 'kogus-grup-${next.player.age}-${next.legal.crewStanding}',
      title: 'Koğuşta taraf oldun',
      text: '$metin\n\n'
          'İçeride rahatsın. Ama iyi hâl dosyan bundan hoşlanmadı: '
          'koşullu salıverilme bu yolla kapanır.',
    );
    return (
      state: next,
      outcome: PrisonOutcome(
        applied: true,
        text: metin,
        effects: <AppliedEffect>[
          AppliedEffect(label: 'Koğuştaki itibar', delta: artis),
          AppliedEffect(label: 'İyi hâl', delta: -iyiHalKaybi),
        ],
      ),
    );
  }

  /// Gruptan uzaklaşmak: itibar düşer, iyi hâl toparlanır.
  static ({GameState state, PrisonOutcome outcome}) _leaveCrew(
    GameState state,
  ) {
    final int dusus = 18;
    const int iyiHal = 8;
    GameState next = state.copyWith(
      legal: state.legal.copyWith(
        crewStanding: state.legal.crewStanding - dusus,
        goodBehaviour: state.legal.goodBehaviour + iyiHal,
      ),
      player: state.player.copyWith(
        stats: state.player.stats.gain(happiness: -2),
      ),
    );
    const String metin = 'Masadan kalktın. Selam kesildi, omuz döndü. '
        'Zor oldu ama dosyan toparlanıyor.';
    next = _log(next, metin);
    return (
      state: next,
      outcome: PrisonOutcome(
        applied: true,
        text: metin,
        effects: <AppliedEffect>[
          AppliedEffect(label: 'Koğuştaki itibar', delta: -dusus),
          const AppliedEffect(label: 'İyi hâl', delta: iyiHal),
        ],
      ),
    );
  }

  // =====================================================================
  // Yardımcılar
  // =====================================================================

  static Person _makeCellmate(GameState state, Random rng) {
    final Set<String> isimler = <String>{
      for (final Person p in state.people) p.firstName,
      state.player.firstName,
    };
    final Set<String> kimlikler = <String>{
      for (final Person p in state.people) p.id,
    };
    // Koğuş arkadaşı oyuncuyla aynı cinsiyettedir: kadın ve erkek
    // cezaevleri ayrıdır.
    final Gender cinsiyet = state.player.gender;
    final List<String> havuz =
        cinsiyet == Gender.kadin ? kadinIsimleri : erkekIsimleri;
    String ad = rng.pick(havuz);
    for (int deneme = 0; deneme < 30 && isimler.contains(ad); deneme++) {
      ad = rng.pick(havuz);
    }
    String id = 'kogus-${state.people.length}';
    int ek = 0;
    while (kimlikler.contains(id)) {
      ek++;
      id = 'kogus-${state.people.length}-$ek';
    }
    final int yas = rng
        .triangular(20, state.player.age, state.player.age + 14)
        .clamp(18, 70);
    return Person(
      id: id,
      firstName: ad,
      lastName: rng.pick(soyisimler),
      gender: cinsiyet,
      relation: RelationType.kogusArkadasi,
      age: yas,
      isAlive: true,
      inPlayerHousehold: false,
      employment: EmploymentStatus.issiz,
      wealth: WealthTier.yoksul,
      bond: prototypeOnlyStartBond,
      city: state.player.currentCity,
    );
  }

  static GameState _countUse(GameState state, PrisonAction action) {
    final String anahtar =
        GameState.interactionKey(counterScope, action.name);
    return state.copyWith(
      interactionCounts: Map<String, int>.unmodifiable(<String, int>{
        ...state.interactionCounts,
        anahtar: (state.interactionCounts[anahtar] ?? 0) + 1,
      }),
    );
  }

  static GameState _withBond(GameState state, String personId, int delta) =>
      state.copyWith(
        people: List<Person>.unmodifiable(
          state.people
              .map(
                (Person p) => p.id == personId
                    ? p.copyWith(bond: (p.bond + delta).clamp(0, 100))
                    : p,
              )
              .toList(growable: false),
        ),
      );

  static GameState _log(GameState state, String metin) => state.copyWith(
        log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
          ...state.log,
          LifeLogEntry(
            age: state.player.age,
            text: metin,
            category: LogCategory.kisisel,
          ),
        ]),
      );

  static GameState _notice(
    GameState state, {
    required String id,
    required String title,
    required String text,
    int money = 0,
    String? personId,
  }) =>
      state.queueNotice(
        PendingNotice(
          id: id,
          kind: NoticeKind.adli,
          age: state.player.age,
          title: title,
          text: text,
          money: money,
          personId: personId,
        ),
      );
}
