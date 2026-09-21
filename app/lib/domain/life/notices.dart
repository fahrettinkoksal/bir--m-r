import '../../text/turkish_text.dart';
import '../models/game_state.dart';
import '../models/life_log.dart';
import '../models/pending_notice.dart';
import '../models/person.dart';
import '../models/relation.dart';

/// Cenaze katkısı seçenekleri.
enum FuneralChoice {
  /// Tam katkı.
  tamKatki,

  /// Elden geldiğince (cüzdanın yarısı kadar) katkı.
  kismiKatki,

  /// Bu sefer katkıda bulunmamak.
  katkiYok,
}

/// Ölüm, miras ve cenaze bildirimleri (D-050).
///
/// Kurallar:
/// - Bildirimde kişinin **adı ve gerçek bağı** yazar.
/// - Miras bildirimi yalnızca oyuncuya **gerçekten bir şey kaldıysa**
///   çıkar; kazanılmamış miras kazanılmış gibi gösterilmez.
/// - Cenaze katkısı bir **seçimdir**: zorunlu borç değildir, mirasın ön
///   koşulu değildir ve cüzdanı eksiye düşürmez.
/// - Aynı bildirim iki kez kuyruğa girmez, bekleyen bildirim kayıtla
///   birlikte saklanır.
///
/// Tutarlar `prototypeOnly`'dir (Q-074).
abstract final class Notices {
  /// prototypeOnly: cenaze masrafına önerilen katkı (₺).
  static const int prototypeOnlyFuneralCost = 25000;

  /// prototypeOnly: katkıda bulunmanın mutluluk etkisi.
  static const int prototypeOnlyContributionHappiness = 3;

  /// Ölümü bildirilecek bağlar.
  static const Set<RelationType> noticeRelations = <RelationType>{
    RelationType.es,
    RelationType.anne,
    RelationType.baba,
    RelationType.cocuk,
    RelationType.kardes,
    RelationType.anneanne,
    RelationType.babaanne,
    RelationType.anneTarafiDede,
    RelationType.babaTarafiDede,
  };

  /// Cenaze katkısı sorulan bağlar.
  static const Set<RelationType> funeralRelations = <RelationType>{
    RelationType.es,
    RelationType.anne,
    RelationType.baba,
    RelationType.cocuk,
    RelationType.kardes,
  };

  static String deathNoticeId(String personId) => 'olum-$personId';
  static String funeralNoticeId(String personId) => 'cenaze-$personId';
  static String inheritanceNoticeId(String personId) => 'miras-$personId';

  /// Vefat bildirimi.
  static PendingNotice death({
    required Person person,
    required int playerAge,
    required String cause,
    required int happinessDelta,
  }) {
    final String bag = person.labelFor(playerAge);
    return PendingNotice(
      id: deathNoticeId(person.id),
      kind: NoticeKind.olum,
      age: playerAge,
      personId: person.id,
      title: 'Bir kaybın var',
      text: '$bag ${person.fullName}, ${person.age} yaşında $cause '
          'nedeniyle hayatını kaybetti.',
      happinessDelta: happinessDelta,
    );
  }

  /// Cenaze katkısı bildirimi.
  static PendingNotice funeral({
    required Person person,
    required int playerAge,
  }) {
    final String bag = person.labelFor(playerAge);
    return PendingNotice(
      id: funeralNoticeId(person.id),
      kind: NoticeKind.cenaze,
      age: playerAge,
      personId: person.id,
      title: 'Cenaze masrafları',
      text: '$bag ${person.firstName} için cenaze hazırlıkları yapılıyor. '
          'Cenazeye katılıyorsun; masraflara katkıda bulunmak ister misin?',
      funeralCost: prototypeOnlyFuneralCost,
    );
  }

  /// Miras bildirimi; oyuncuya bir şey kalmadıysa `null`.
  static PendingNotice? inheritance({
    required Person person,
    required int playerAge,
    required int money,
    required List<String> itemNames,
  }) {
    if (money <= 0 && itemNames.isEmpty) return null;
    final String bag = person.labelFor(playerAge);
    final StringBuffer metin = StringBuffer(
      '$bag ${person.fullName} vefatının ardından mirastan payına ',
    );
    if (money > 0 && itemNames.isNotEmpty) {
      metin.write('${trMoney(money)} ve ${itemNames.join(', ')} düştü.');
    } else if (money > 0) {
      metin.write('${trMoney(money)} düştü.');
    } else {
      metin.write('${itemNames.join(', ')} düştü.');
    }
    return PendingNotice(
      id: inheritanceNoticeId(person.id),
      kind: NoticeKind.miras,
      age: playerAge,
      personId: person.id,
      title: 'Miras',
      text: metin.toString(),
      money: money,
      itemNames: List<String>.unmodifiable(itemNames),
    );
  }

  /// Bildirimleri kuyruğa ekler.
  ///
  /// Aynı kimlikli bildirim zaten kuyruktaysa **tekrar eklenmez**; mevcut
  /// kuyruk ezilmez, yeni bildirimler sona eklenir.
  static GameState enqueue(GameState state, Iterable<PendingNotice> yeni) {
    final Set<String> mevcut = <String>{
      for (final PendingNotice n in state.notices) n.id,
    };
    final List<PendingNotice> kuyruk = <PendingNotice>[...state.notices];
    for (final PendingNotice n in yeni) {
      if (mevcut.add(n.id)) kuyruk.add(n);
    }
    if (kuyruk.length == state.notices.length) return state;
    return state.copyWith(notices: List<PendingNotice>.unmodifiable(kuyruk));
  }

  /// Kuyruktaki ilk bildirimi kaldırır.
  static GameState dismissFirst(GameState state) {
    if (state.notices.isEmpty) return state;
    return state.copyWith(
      notices: List<PendingNotice>.unmodifiable(state.notices.sublist(1)),
    );
  }

  /// Cenaze katkısı için gerçekten ödenebilecek tutar.
  ///
  /// Cüzdan **eksiye düşmez**: para yetmiyorsa kısmi katkı önerilir,
  /// o da yoksa katkı seçeneği hiç açılmaz.
  static int amountFor(GameState state, PendingNotice notice, FuneralChoice choice) {
    final int cuzdan = state.player.wallet;
    switch (choice) {
      case FuneralChoice.tamKatki:
        return cuzdan >= notice.funeralCost ? notice.funeralCost : 0;
      case FuneralChoice.kismiKatki:
        return cuzdan <= 0 ? 0 : (cuzdan ~/ 2).clamp(0, notice.funeralCost);
      case FuneralChoice.katkiYok:
        return 0;
    }
  }

  /// Bu seçenek şu an sunulabilir mi?
  static bool canChoose(GameState state, PendingNotice notice, FuneralChoice choice) {
    switch (choice) {
      case FuneralChoice.tamKatki:
        return state.player.wallet >= notice.funeralCost;
      case FuneralChoice.kismiKatki:
        return state.player.wallet < notice.funeralCost &&
            amountFor(state, notice, choice) > 0;
      case FuneralChoice.katkiYok:
        return true;
    }
  }

  /// Cenaze katkısı seçimini uygular.
  ///
  /// Ödeme cüzdandan **bir kez** düşer ve günlüğe yazılır. Katkıda
  /// bulunmamak cenazeye katılmayı engellemez ve mirası etkilemez.
  static ({GameState state, String text}) respondToFuneral(
    GameState state,
    FuneralChoice choice,
  ) {
    if (state.notices.isEmpty ||
        state.notices.first.kind != NoticeKind.cenaze) {
      return (state: state, text: 'Bekleyen bir cenaze bildirimi yok.');
    }
    final PendingNotice notice = state.notices.first;
    final Person? kisi =
        notice.personId == null ? null : state.personById(notice.personId!);
    final String ad = kisi?.firstName ?? 'yakının';

    final int tutar = amountFor(state, notice, choice);
    final String metin = tutar > 0
        ? '$ad için cenaze masraflarına ${trMoney(tutar)} katkıda bulundun.'
        : '$ad için cenaze masraflarına katkıda bulunamadın; '
            'cenazedeydin.';

    GameState next = dismissFirst(state);
    if (tutar > 0) {
      next = next.copyWith(
        player: next.player.copyWith(
          wallet: next.player.wallet - tutar,
          stats: next.player.stats.copyWith(
            happiness:
                next.player.stats.happiness + prototypeOnlyContributionHappiness,
          ),
        ),
      );
    }

    next = next.copyWith(
      log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
        ...next.log,
        LifeLogEntry(
          age: next.player.age,
          text: metin,
          category: LogCategory.aile,
        ),
      ]),
    );
    return (state: next, text: metin);
  }
}
