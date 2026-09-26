/// Üvey anne ve üvey baba (D-141).
///
/// Faho'nun isteği: "üvey anne baba olabilsin."
///
/// **Ne yapar:** oyuncunun ebeveynlerinden biri vefat ettiyse, hayatta
/// kalan ebeveyn bir süre sonra yeniden evlenebilir; gelen kişi kalıcı
/// kimliğiyle aile listesine **üvey anne** ya da **üvey baba** olarak
/// girer. Bağ düşük başlar ve ancak vakit geçirilerek büyür — üvey
/// ebeveyn "hazır aile" değildir.
///
/// **Ne yapmaz:** ebeveyni evlenmeye zorlamaz, oyuncuya onay sormaz
/// (çocuğun karar hakkı yoktur), kimseyi listeden silmez ve vefat eden
/// ebeveyni geçmişten kaldırmaz. Üvey kardeş bu sürümde gelmiyor
/// (`docs/DESIGN_REVIEW_QUEUE.md`, Q-149).
///
/// Ebeveynlerin **boşanması** henüz modellenmiyor; bu yüzden tek tetik
/// vefattır. Boşanma eklendiğinde aynı kapı kullanılacak.
///
/// Bütün sayılar `prototypeOnly`'dir.
library;

import 'dart:math';

import '../../data/name_pool.dart';
import '../models/game_state.dart';
import '../models/gender.dart';
import '../models/life_log.dart';
import '../models/pending_notice.dart';
import '../models/person.dart';
import '../models/relation.dart';
import '../models/wealth.dart';
import 'random_util.dart';

abstract final class StepParents {
  /// prototypeOnly: vefattan sonra en az kaç yıl geçmeli.
  static const int prototypeOnlyMourningYears = 2;

  /// prototypeOnly: uygun bir yılda yeniden evlenme ihtimali.
  static const double prototypeOnlyRemarryChance = 0.12;

  /// prototypeOnly: bu yaştan sonra ebeveyn yeniden evlenmez.
  static const int prototypeOnlyMaxParentAge = 72;

  /// prototypeOnly: üvey ebeveynin başlangıç yakınlığı.
  ///
  /// Düşük başlar: tanışmakla aile olunmuyor.
  static const int prototypeOnlyStartBond = 18;

  /// Bu yıl bir üvey ebeveyn gelir mi? Gelirse kaydı ekler.
  ///
  /// Koşullar sağlanmıyorsa durum **aynen** döner.
  static GameState maybeRemarry(GameState state, int newAge, Random rng) {
    if (state.deceased) return state;
    // Çok küçük yaşta bu haber anlatılamaz; ayrıca yas süresi gerekiyor.
    if (newAge < prototypeOnlyMourningYears + 1) return state;

    final Person? anne = _parent(state, RelationType.anne);
    final Person? baba = _parent(state, RelationType.baba);

    // Yeniden evlenebilecek ebeveyn: kendisi hayatta, eşi yok (vefat etti
    // ya da hiç kayıtlı değil) ve o taraftan üvey ebeveyn henüz gelmemiş.
    final Person? evlenecek = _remarryCandidate(
      state: state,
      parent: anne,
      counterpart: baba,
      stepType: RelationType.uveyBaba,
      newAge: newAge,
    ) ??
        _remarryCandidate(
          state: state,
          parent: baba,
          counterpart: anne,
          stepType: RelationType.uveyAnne,
          newAge: newAge,
        );
    if (evlenecek == null) return state;
    if (rng.nextDouble() >= prototypeOnlyRemarryChance) return state;

    final RelationType tur = evlenecek.relation == RelationType.anne
        ? RelationType.uveyBaba
        : RelationType.uveyAnne;
    final Person uvey = _makeStepParent(
      state: state,
      parent: evlenecek,
      stepType: tur,
      rng: rng,
    );

    final String etiket = tur == RelationType.uveyBaba ? 'baba' : 'anne';
    final String metin =
        '${trUpperFirstLocal(evlenecek.possessiveFor(newAge))} yeniden '
        'evlendi. ${uvey.firstName} artık üvey $etiket.';

    GameState next = state.copyWith(
      people: List<Person>.unmodifiable(<Person>[...state.people, uvey]),
      player: state.player.copyWith(
        // Alışmak zaman alır; küçük yaşta daha zor.
        stats: state.player.stats.gain(happiness: newAge < 18 ? -3 : -1),
      ),
      log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
        ...state.log,
        LifeLogEntry(
          age: newAge,
          text: metin,
          category: LogCategory.aile,
          personId: uvey.id,
        ),
      ]),
    );
    next = next.queueNotice(
      PendingNotice(
        id: 'uvey-${uvey.id}',
        kind: NoticeKind.aileDonum,
        age: newAge,
        title: 'Evde yeni biri var',
        text: '$metin\n\n'
            '${uvey.firstName} ile aranız kendiliğinden kurulmayacak: '
            'yakınlık düşük başlıyor, vakit geçirdikçe değişir.',
        personId: uvey.id,
      ),
    );
    return next;
  }

  static Person? _parent(GameState state, RelationType tur) {
    for (final Person p in state.people) {
      if (p.relation == tur) return p;
    }
    return null;
  }

  /// [parent] yeniden evlenebilir mi?
  static Person? _remarryCandidate({
    required GameState state,
    required Person? parent,
    required Person? counterpart,
    required RelationType stepType,
    required int newAge,
  }) {
    if (parent == null || !parent.isAlive) return null;
    if (parent.age > prototypeOnlyMaxParentAge) return null;
    // Eşi hâlâ hayattaysa yeniden evlenmez.
    if (counterpart != null && counterpart.isAlive) return null;
    // O taraftan üvey ebeveyn zaten geldiyse ikincisi gelmez.
    if (state.people.any((Person p) => p.relation == stepType)) return null;
    // Yas süresi: vefat yılı kayıttan okunur, uydurulmaz. Kayıt yoksa
    // (hayat başlarken vefat etmiş biri) süre geçmiş sayılır.
    if (counterpart != null) {
      final int? vefatYasi = _deathAge(state, counterpart.id);
      if (vefatYasi != null &&
          newAge - vefatYasi < prototypeOnlyMourningYears) {
        return null;
      }
    }
    return parent;
  }

  /// Bu kişinin vefatının yazıldığı oyuncu yaşı; kayıt yoksa `null`.
  static int? _deathAge(GameState state, String personId) {
    for (final LifeLogEntry e in state.log.reversed) {
      if (e.personId == personId && e.text.contains('vefat')) return e.age;
    }
    return null;
  }

  static Person _makeStepParent({
    required GameState state,
    required Person parent,
    required RelationType stepType,
    required Random rng,
  }) {
    final Set<String> isimler = <String>{
      for (final Person p in state.people) p.firstName,
      state.player.firstName,
    };
    final Gender cinsiyet =
        stepType == RelationType.uveyAnne ? Gender.kadin : Gender.erkek;
    final List<String> havuz =
        cinsiyet == Gender.kadin ? kadinIsimleri : erkekIsimleri;
    String ad = rng.pick(havuz);
    for (int deneme = 0; deneme < 30 && isimler.contains(ad); deneme++) {
      ad = rng.pick(havuz);
    }
    final Set<String> kimlikler = <String>{
      for (final Person p in state.people) p.id,
    };
    String id = 'uvey-${stepType.name}';
    int ek = 0;
    while (kimlikler.contains(id)) {
      ek++;
      id = 'uvey-${stepType.name}-$ek';
    }

    final bool calisiyor = rng.chance(0.7);
    return Person(
      id: id,
      firstName: ad,
      // Soyadı ebeveynin değil kendisinindir; evlilikle kimsenin soyadı
      // zorla değişmez.
      lastName: rng.pick(soyisimler),
      gender: cinsiyet,
      relation: stepType,
      age: (parent.age + rng.nextInt(9) - 4).clamp(25, 85),
      isAlive: true,
      // Ebeveyn oyuncunun hanesindeyse üvey ebeveyn de aynı hanede olur.
      inPlayerHousehold: parent.inPlayerHousehold,
      employment: calisiyor
          ? EmploymentStatus.calisiyor
          : EmploymentStatus.issiz,
      // İşsiz kişiye uydurma meslek yazılmaz (`docs/FAMILY_SYSTEM.md`).
      occupation: calisiyor ? rng.pick(meslekler) : null,
      wealth: parent.wealth ?? WealthTier.ortaHalli,
      bond: prototypeOnlyStartBond,
      city: parent.city ?? state.player.currentCity,
    );
  }

  /// İlk harfi büyüten yerel yardımcı: metin katmanına bağımlılık
  /// yaratmadan cümle başı düzeltilir.
  static String trUpperFirstLocal(String input) =>
      input.isEmpty ? input : input[0].toUpperCase() + input.substring(1);
}
