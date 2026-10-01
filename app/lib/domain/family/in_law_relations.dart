import 'dart:math';

import '../generation/random_util.dart';
import '../models/family_drama.dart';
import '../models/family_issue.dart';
import '../models/game_state.dart';
import '../models/life_log.dart';
import '../models/pending_notice.dart';
import '../models/person.dart';
import '../models/relation.dart';
import '../../text/turkish_text.dart';

/// Kayın aile ve gelin/damat ile ilişkiler (Paket AP §24-§27).
///
/// Bu dosyanın en önemli kuralı bir **yasak**: §26 "kayınvalide =
/// sürekli sorun" stereotipini açıkça reddediyor. Bu yüzden:
///
/// * Olay havuzunda iyi ve kötü olaylar **aynı ağırlıkta**. Kalıcı bir
///   test bunu ölçüyor; "kayınvalide olayı" denince akla kavga
///   gelmiyor.
/// * Gelin/damat ne otomatik iyi ne otomatik kötü karakter (§24).
///   Başlangıç yakınlığı ortanın altında ve bağ zamanla kurulur —
///   oyuncunun ne yaptığına göre iki yöne de gider.
/// * Çatışmada (§27) **bedava seçenek yok**: eşinin tarafını tutmak da,
///   anne-babanın tarafını tutmak da, karışmamak da bir şeye mal olur.
///
/// NPC-NPC tam sosyal graph kurulmuyor (§25): kayın aile ile oyuncunun
/// kendi ailesi arasında yalnızca **oyuncunun gördüğü** çatışma var.
///
/// Sayısal değerler `prototypeOnly`'dir (Q-133).
abstract final class InLawRelations {
  /// prototypeOnly: kayın aile olayının yıllık taban ihtimali.
  static const double prototypeOnlyEventChance = 0.12;

  /// prototypeOnly: ihtimalin üst sınırı.
  static const double prototypeOnlyMaxEventChance = 0.26;

  /// prototypeOnly: aynı kişiyle iki olay arasında geçmesi gereken yıl.
  static const int prototypeOnlyEventCooldown = 3;

  /// prototypeOnly: olayın yakınlığa etkisi.
  static const int prototypeOnlyBondStep = 4;

  /// prototypeOnly: çatışmanın yıllık taban ihtimali (§27).
  static const double prototypeOnlyConflictChance = 0.07;

  /// prototypeOnly: çatışma için iki kişi arasında gereken en yüksek
  /// yakınlık farkı — taraflar birbirine çok yakınsa kavga çıkmaz.
  static const int prototypeOnlyConflictCooldown = 6;

  /// Kişinin ekranda görünen bağ adı.
  ///
  /// `relationLabel` yaşa ve cinsiyete bakıyor (abi/abla gibi); etiket
  /// iki yerde ayrı ayrı kurulmasın diye tek yerden okunuyor.
  static String _etiket(GameState state, Person person) => relationLabel(
        relation: person.relation,
        gender: person.gender,
        personAge: person.age,
        playerAge: state.player.age,
      );

  /// Kayın aile olayının soğuma anahtarı.
  static String eventKey(String personId) => 'kayin-olay:$personId';

  /// Çatışmanın soğuma anahtarı.
  static String conflictKey() => 'kayin-catisma';

  // =================================================================
  // §26 — kayın aile olayları: iyi de olur, kötü de
  // =================================================================

  /// Olay havuzu: **yarısı iyi, yarısı kötü**.
  ///
  /// Liste bilinçli olarak dengeli; stereotip buradan doğmuyor.
  /// Metinler `docs/WRITING_STYLE_TR.md`'ye uygun: yargılamıyor,
  /// anlatıyor.
  static const List<({String text, bool good})> prototypeOnlyEvents =
      <({String text, bool good})>[
    (
      text: 'bu sabah kapıyı çaldı, elinde bir tencere yemek vardı.',
      good: true,
    ),
    (
      text: 'çocuklara baktı; ikiniz de uzun zamandır dinlenmemiştiniz.',
      good: true,
    ),
    (
      text: 'hastalandığında seni aradı; gidip yanında kaldın, iyi geldi.',
      good: true,
    ),
    (
      text: 'bayramda bütün aileyi topladı, kalabalık bir sofra kurdu.',
      good: true,
    ),
    (
      text: 'evin düzeni hakkında söyledikleri seni kırdı.',
      good: false,
    ),
    (
      text: 'telefonda uzun bir tartışma oldu; ikiniz de kapatırken '
          'gergindiniz.',
      good: false,
    ),
    (
      text: 'bir aile meselesinde sana sormadan karar verdi.',
      good: false,
    ),
    (
      text: 'uzun süredir aramıyor; aranızda bir soğukluk var.',
      good: false,
    ),
  ];

  /// Olay çıkabilecek kişiler: kayın aile ve gelin/damat.
  static Iterable<Person> candidates(GameState state) =>
      state.people.where((Person p) =>
          p.isAlive &&
          (p.relation == RelationType.kayinvalide ||
              p.relation == RelationType.kayinpeder ||
              p.relation == RelationType.cocugunEsi));

  static bool offCooldown(GameState state, Person person, int newAge) {
    final int? son = state.lastInteractionAge[eventKey(person.id)];
    if (son == null) return true;
    return newAge - son >= prototypeOnlyEventCooldown;
  }

  /// Bu yıl bir kayın aile olayı çıkar mı?
  static ({GameState state, PendingNotice? notice, String? logText})
      maybeEvent(GameState state, int newAge, Random rng) {
    final double ihtimal = state.familyDrama.scale(
      prototypeOnlyEventChance,
      FamilyDramaArea.kayin,
      cap: prototypeOnlyMaxEventChance,
    );
    for (final Person kisi in candidates(state)) {
      if (!offCooldown(state, kisi, newAge)) continue;
      if (!rng.chance(ihtimal)) continue;

      final ({String text, bool good}) olay =
          rng.pick(prototypeOnlyEvents);
      final String metin =
          '${_etiket(state, kisi)} ${kisi.firstName} ${olay.text}';
      final int bagDegisimi =
          olay.good ? prototypeOnlyBondStep : -prototypeOnlyBondStep;

      GameState next = state.copyWith(
        people: List<Person>.unmodifiable(<Person>[
          for (final Person p in state.people)
            if (p.id == kisi.id)
              p.copyWith(bond: (p.bond + bagDegisimi).clamp(0, 100))
            else
              p,
        ]),
        lastInteractionAge: <String, int>{
          ...state.lastInteractionAge,
          eventKey(kisi.id): newAge,
        },
      );
      next = next.copyWith(
        log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
          ...next.log,
          LifeLogEntry(
            age: newAge,
            text: metin,
            category: LogCategory.aile,
          ),
        ]),
      );
      return (
        state: next,
        notice: PendingNotice(
          id: 'kayin-olay-${kisi.id}-$newAge',
          kind: NoticeKind.aileDonum,
          age: newAge,
          title: olay.good ? 'Aileden güzel bir haber' : 'Ailede bir gerginlik',
          text: metin,
          personId: kisi.id,
        ),
        logText: metin,
      );
    }
    return (state: state, notice: null, logText: null);
  }

  // =================================================================
  // §27 — eş ile kendi ailen arasındaki çatışma
  // =================================================================

  /// Çatışma çıkabilir mi: hem eş hem oyuncunun bir ebeveyni hayatta
  /// olmalı.
  ///
  /// Taraflar gerçek kişiler; "ev kavgası" uydurulmuyor (§27).
  static ({Person spouse, Person parent})? conflictSides(GameState state) {
    final Person? es = state.spouse;
    if (es == null || !es.isAlive) return null;
    for (final Person p in state.people) {
      if (!p.isAlive) continue;
      if (p.relation != RelationType.anne &&
          p.relation != RelationType.baba) {
        continue;
      }
      return (spouse: es, parent: p);
    }
    return null;
  }

  static bool conflictOffCooldown(GameState state, int newAge) {
    final int? son = state.lastInteractionAge[conflictKey()];
    if (son == null) return true;
    return newAge - son >= prototypeOnlyConflictCooldown;
  }

  /// Bu yıl bir çatışma açar.
  static ({GameState state, PendingNotice? notice}) maybeConflict(
    GameState state,
    int newAge,
    Random rng,
  ) {
    if (!state.canOpenFamilyDecision) return (state: state, notice: null);
    if (!conflictOffCooldown(state, newAge)) {
      return (state: state, notice: null);
    }
    final ({Person spouse, Person parent})? taraflar = conflictSides(state);
    if (taraflar == null) return (state: state, notice: null);
    final double ihtimal = state.familyDrama.scale(
      prototypeOnlyConflictChance,
      FamilyDramaArea.kayin,
      cap: 0.18,
    );
    if (!rng.chance(ihtimal)) return (state: state, notice: null);

    // Mesele **ebeveynin** kimliğine açılıyor: oyuncunun ailesi tarafı
    // zaman içinde değişmeyen taraf.
    final GameState acik = state.openFamilyIssue(
      kind: FamilyIssueKind.kayinGerginlik,
      personId: taraflar.parent.id,
    );
    if (acik.familyIssues.length == state.familyIssues.length) {
      return (state: state, notice: null);
    }

    final String metin = '${taraflar.spouse.firstName} ile '
        '${trLower(_etiket(state, taraflar.parent))} arasında bir '
        'mesele çıktı. İkisi de haklı olduğunu düşünüyor ve ikisi de '
        'senin ne diyeceğini bekliyor.';
    GameState next = acik.copyWith(
      lastInteractionAge: <String, int>{
        ...acik.lastInteractionAge,
        conflictKey(): newAge,
      },
      log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
        ...acik.log,
        LifeLogEntry(age: newAge, text: metin, category: LogCategory.aile),
      ]),
    );
    return (
      state: next,
      notice: PendingNotice(
        id: 'kayin-catisma-$newAge',
        kind: NoticeKind.aileDonum,
        age: newAge,
        title: 'Arada kaldın',
        text: metin,
        personId: taraflar.parent.id,
      ),
    );
  }

  /// Oyuncuya sorulmayı bekleyen çatışma; yoksa `null`.
  static FamilyIssue? pendingConflict(GameState state) {
    for (final FamilyIssue mesele in state.familyIssues) {
      if (!mesele.isOpen) continue;
      if (mesele.kind != FamilyIssueKind.kayinGerginlik) continue;
      if (mesele.response != null) continue;
      return mesele;
    }
    return null;
  }

  static bool isConflictPending(GameState state) =>
      pendingConflict(state) != null;

  /// Oyuncunun çatışmada verdiği karar.
  ///
  /// Üç cevabın hepsi bir şeye mal olur; bedava seçenek yok (§27).
  static ({GameState state, String text}) resolveConflict(
    GameState state,
    FamilyIssueResponse cevap,
  ) {
    final FamilyIssue? mesele = pendingConflict(state);
    if (mesele == null) return (state: state, text: '');
    final Person? ebeveyn = state.personById(mesele.personId);
    final Person? es = state.spouse;
    if (ebeveyn == null) {
      return (
        state: state.updateFamilyIssue(
          mesele.id,
          status: FamilyIssueStatus.kapandi,
          resolvedAtAge: state.player.age,
        ),
        text: '',
      );
    }

    // Tarafını tuttuğun kazanır, diğeri kaybeder; karışmazsan ikisi de
    // biraz kaybeder. Hiçbir seçenek iki tarafı da memnun etmiyor.
    final int esEtkisi = switch (cevap) {
      FamilyIssueResponse.destekOldu => 5,
      FamilyIssueResponse.reddetti => -5,
      _ => -2,
    };
    final int ebeveynEtkisi = switch (cevap) {
      FamilyIssueResponse.destekOldu => -5,
      FamilyIssueResponse.reddetti => 5,
      _ => -2,
    };

    GameState next = state.copyWith(
      people: List<Person>.unmodifiable(<Person>[
        for (final Person p in state.people)
          if (es != null && p.id == es.id)
            p.copyWith(bond: (p.bond + esEtkisi).clamp(0, 100))
          else if (p.id == ebeveyn.id)
            p.copyWith(bond: (p.bond + ebeveynEtkisi).clamp(0, 100))
          else
            p,
      ]),
    );

    final String etiket = _etiket(state, ebeveyn);
    final String metin = switch (cevap) {
      FamilyIssueResponse.destekOldu =>
        'Eşinin yanında durdun; ${trLower(etiket)} bunu hoş karşılamadı.',
      FamilyIssueResponse.reddetti =>
        '$etiket haklı dedin; eşin bunu uzun süre unutmadı.',
      _ => 'Bu meselede taraf tutmadın. İkisi de senden bekliyordu.',
    };

    next = next.updateFamilyIssue(
      mesele.id,
      response: cevap,
      lastEventAge: next.player.age,
      status: FamilyIssueStatus.cozuldu,
      resolvedAtAge: next.player.age,
    );
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
