import 'dart:math';

import '../models/family_issue.dart';
import '../models/game_state.dart';
import '../models/person.dart';
import 'adult_child_support.dart';
import 'child_school_issue.dart';
import 'family_disputes.dart';
import 'in_law_relations.dart';

/// Oyuncunun karşısına çıkan **tek** aile kararı (Paket AP §56-§60).
///
/// Paket AP yedi ayrı aile kararı getirdi: çocuğun okul meselesi,
/// yetişkin çocuğun para isteği, eve dönüşü, kayın aile çatışması,
/// kardeşin para isteği, yaşlı bakımı ve miras itirazı. Ekranda bunların
/// her biri için ayrı bir kart yazmak yedi kez aynı şeyi yazmak olurdu.
///
/// Bu yüzden ekran tek bir soru görüyor: başlık, metin, kişi ve
/// seçenekler. Hangi motorun sorduğu burada çözülüyor.
///
/// Paket AO'da üç motorun hiçbir ekrandan ulaşılamadığı görülmüştü;
/// `kinds` listesi o yüzden kalıcı bir testle denetleniyor: yeni bir
/// aile kararı eklenip ekrana bağlanmazsa test kırılır.
class FamilyDecision {
  const FamilyDecision({
    required this.kind,
    required this.title,
    required this.text,
    required this.options,
    this.personId,
  });

  /// Hangi mesele.
  final FamilyIssueKind kind;

  /// Ekranda görünen başlık.
  final String title;

  /// Oyuncuya anlatılan durum — doğal Türkçe, iç sayı göstermez (§58).
  final String text;

  /// İlgili kişi; yoksa `null`.
  final String? personId;

  /// Seçenekler. [FamilyDecisionOption.blockedReason] doluysa seçenek
  /// ekranda **görünür** ama seçilemez (D-095).
  final List<FamilyDecisionOption> options;
}

/// Bir aile kararının tek seçeneği.
class FamilyDecisionOption {
  const FamilyDecisionOption({
    required this.response,
    required this.label,
    this.blockedReason,
  });

  final FamilyIssueResponse response;

  /// Düğme metni.
  final String label;

  /// Seçilemiyorsa gerekçesi; seçilebiliyorsa `null`.
  final String? blockedReason;

  bool get isAllowed => blockedReason == null;
}

/// Bekleyen aile kararlarını tek kapıdan okur ve uygular.
abstract final class FamilyDecisions {
  /// Ekrana bağlanmış mesele türleri.
  ///
  /// Kalıcı test bu listeyi `FamilyIssueKind.values` ile karşılaştırıyor:
  /// ekrana bağlanmayan bir mesele türü sessizce kalmasın.
  static const Set<FamilyIssueKind> wiredKinds = <FamilyIssueKind>{
    FamilyIssueKind.cocukOkul,
    FamilyIssueKind.cocukPara,
    FamilyIssueKind.kardesPara,
    FamilyIssueKind.bakim,
    FamilyIssueKind.kayinGerginlik,
    FamilyIssueKind.miras,
    // Çocuğun evlilik meselesi oyuncuya karar sormuyor: çocuğun kendi
    // hayatı (§1). Bildirimle duyurulur, listede karar olarak çıkmaz.
    FamilyIssueKind.cocukEvlilik,
  };

  /// Oyuncuya karar sorulan meseleler.
  ///
  /// `cocukEvlilik` burada yok: oyuncunun vereceği bir karar değil.
  static const Set<FamilyIssueKind> askedKinds = <FamilyIssueKind>{
    FamilyIssueKind.cocukOkul,
    FamilyIssueKind.cocukPara,
    FamilyIssueKind.kardesPara,
    FamilyIssueKind.bakim,
    FamilyIssueKind.kayinGerginlik,
    FamilyIssueKind.miras,
  };

  /// Şu an bekleyen karar; yoksa `null`.
  ///
  /// Sıra sabit: aynı durumda hep aynı soru çıkar.
  static FamilyDecision? pending(GameState state) {
    final FamilyDecision? okul = _school(state);
    if (okul != null) return okul;
    final FamilyDecision? cocukPara = _childMoney(state);
    if (cocukPara != null) return cocukPara;
    final FamilyDecision? eveDonus = _moveBack(state);
    if (eveDonus != null) return eveDonus;
    final FamilyDecision? bakim = _care(state);
    if (bakim != null) return bakim;
    final FamilyDecision? miras = _estate(state);
    if (miras != null) return miras;
    final FamilyDecision? kardes = _siblingMoney(state);
    if (kardes != null) return kardes;
    return _conflict(state);
  }

  /// Oyuncunun cevabını ilgili motora iletir.
  ///
  /// Dönen metin ekranda gösterilir; boşsa bir şey olmadı.
  static ({GameState state, String text}) answer(
    GameState state,
    FamilyIssueResponse cevap,
    Random rng,
  ) {
    final FamilyDecision? karar = pending(state);
    if (karar == null) return (state: state, text: '');
    switch (karar.kind) {
      case FamilyIssueKind.cocukOkul:
        return ChildSchoolIssue.choose(state, cevap, rng);
      case FamilyIssueKind.cocukPara:
        // Eve dönüş de aynı mesele üzerinden soruluyor; hangisi
        // bekliyorsa ona gider.
        if (AdultChildSupport.pendingRequest(state) != null) {
          return AdultChildSupport.respond(state, cevap);
        }
        return AdultChildSupport.answerMoveBack(
          state,
          cevap == FamilyIssueResponse.destekOldu,
        );
      case FamilyIssueKind.kardesPara:
        return FamilyDisputes.respondSiblingAsk(state, cevap);
      case FamilyIssueKind.bakim:
        return FamilyDisputes.respondCare(state, cevap);
      case FamilyIssueKind.miras:
        return FamilyDisputes.respondEstateDispute(state, cevap);
      case FamilyIssueKind.kayinGerginlik:
        return InLawRelations.resolveConflict(state, cevap);
      case FamilyIssueKind.cocukEvlilik:
        return (state: state, text: '');
    }
  }

  // =================================================================
  // §59 — kişi kartındaki aile sorunu satırı
  // =================================================================

  /// Bu kişinin süren meselesini anlatan **tek** satır; yoksa `null`.
  ///
  /// İç sayı göstermez (§58): "aşama 2" ya da "ihtimal 0,45" yazmaz;
  /// kaç yıldır sürdüğünü ve ne olduğunu söyler.
  static String? statusLineFor(GameState state, Person person) {
    final FamilyIssue? mesele = state.openFamilyIssueFor(person.id);
    if (mesele == null) return _estrangementLine(state, person);
    final int yil = mesele.yearsOpen(state.player.age);
    final String sure = yil <= 0
        ? 'bu yıl'
        : yil == 1
            ? 'bir yıldır'
            : '$yil yıldır';
    final String konu = switch (mesele.kind) {
      FamilyIssueKind.cocukOkul => 'okul meselesi',
      FamilyIssueKind.cocukPara => 'para sıkıntısı',
      FamilyIssueKind.cocukEvlilik => 'evliliğinde sorun',
      FamilyIssueKind.kardesPara => 'para meselesi',
      FamilyIssueKind.bakim => 'bakım meselesi',
      FamilyIssueKind.kayinGerginlik => 'aradaki gerginlik',
      FamilyIssueKind.miras => 'miras anlaşmazlığı',
    };
    return '$sure $konu sürüyor';
  }

  /// §60: küslüğün **sebebi** uydurulmaz.
  ///
  /// Kayıtta yalnızca ne zaman küs düşüldüğü var; o yüzden satır
  /// yalnızca süreyi söyler. "Çünkü şöyle oldu" diye bir cümle
  /// yazılmıyor.
  static String? _estrangementLine(GameState state, Person person) {
    if (!person.isEstranged) return null;
    final int yil = state.player.age - person.estrangedSinceAge!;
    if (yil <= 0) return 'Bu yıl araya bir soğukluk girdi';
    if (yil == 1) return 'Bir yıldır konuşmuyorsunuz';
    return '$yil yıldır konuşmuyorsunuz';
  }

  // =================================================================
  // Tek tek meseleler
  // =================================================================

  static FamilyDecision? _school(GameState state) {
    final FamilyIssue? mesele = ChildSchoolIssue.pendingIssue(state);
    if (mesele == null) return null;
    final Person? cocuk = state.personById(mesele.personId);
    if (cocuk == null) return null;
    return FamilyDecision(
      kind: FamilyIssueKind.cocukOkul,
      personId: cocuk.id,
      title: '${cocuk.firstName} ve okul',
      text: 'Öğretmeni ${cocuk.firstName} için seninle görüşmek istedi. '
          'Ne yapacağına sen karar vereceksin; sonucu kimse garanti '
          'edemez.',
      options: <FamilyDecisionOption>[
        FamilyDecisionOption(
          response: FamilyIssueResponse.destekOldu,
          label: 'Birlikte ders çalış',
          blockedReason: ChildSchoolIssue.blockReason(
            state,
            FamilyIssueResponse.destekOldu,
          ),
        ),
        FamilyDecisionOption(
          response: FamilyIssueResponse.paraVerdi,
          label: 'Özel ders tut',
          blockedReason: ChildSchoolIssue.blockReason(
            state,
            FamilyIssueResponse.paraVerdi,
          ),
        ),
        const FamilyDecisionOption(
          response: FamilyIssueResponse.konustu,
          label: 'Konuş, kararı ona bırak',
        ),
        const FamilyDecisionOption(
          response: FamilyIssueResponse.karismadi,
          label: 'Karışma',
        ),
      ],
    );
  }

  static FamilyDecision? _childMoney(GameState state) {
    final FamilyIssue? mesele = AdultChildSupport.pendingRequest(state);
    if (mesele == null) return null;
    final Person? cocuk = state.personById(mesele.personId);
    if (cocuk == null) return null;
    final int tam = AdultChildSupport.amountFor(
      state,
      FamilyIssueResponse.paraVerdi,
    );
    final int yarim = AdultChildSupport.amountFor(
      state,
      FamilyIssueResponse.destekOldu,
    );
    return FamilyDecision(
      kind: FamilyIssueKind.cocukPara,
      personId: cocuk.id,
      title: '${cocuk.firstName} para istiyor',
      text: '${cocuk.firstName} zor geçiniyor ve senden borç istedi.',
      options: <FamilyDecisionOption>[
        FamilyDecisionOption(
          response: FamilyIssueResponse.paraVerdi,
          label: 'İstediği kadarını ver (${_bin(tam)} bin ₺)',
          blockedReason: AdultChildSupport.blockReason(
            state,
            FamilyIssueResponse.paraVerdi,
          ),
        ),
        FamilyDecisionOption(
          response: FamilyIssueResponse.destekOldu,
          label: 'Elinden geleni ver (${_bin(yarim)} bin ₺)',
          blockedReason: AdultChildSupport.blockReason(
            state,
            FamilyIssueResponse.destekOldu,
          ),
        ),
        const FamilyDecisionOption(
          response: FamilyIssueResponse.konustu,
          label: 'Konuş ama para verme',
        ),
        const FamilyDecisionOption(
          response: FamilyIssueResponse.reddetti,
          label: 'Veremeyeceğini söyle',
        ),
      ],
    );
  }

  static FamilyDecision? _moveBack(GameState state) {
    final FamilyIssue? mesele = AdultChildSupport.pendingMoveBack(state);
    if (mesele == null) return null;
    final Person? cocuk = state.personById(mesele.personId);
    if (cocuk == null) return null;
    return FamilyDecision(
      kind: FamilyIssueKind.cocukPara,
      personId: cocuk.id,
      title: '${cocuk.firstName} eve dönmek istiyor',
      text: '${cocuk.firstName} kendi başına idare edemiyor ve bir süre '
          'eve dönmek istiyor. Eve dönerse hane gideri artar.',
      options: const <FamilyDecisionOption>[
        FamilyDecisionOption(
          response: FamilyIssueResponse.destekOldu,
          label: 'Gelsin',
        ),
        FamilyDecisionOption(
          response: FamilyIssueResponse.reddetti,
          label: 'Olmaz',
        ),
      ],
    );
  }

  static FamilyDecision? _siblingMoney(GameState state) {
    final FamilyIssue? mesele = FamilyDisputes.pendingSiblingAsk(state);
    if (mesele == null) return null;
    final Person? kardes = state.personById(mesele.personId);
    if (kardes == null) return null;
    return FamilyDecision(
      kind: FamilyIssueKind.kardesPara,
      personId: kardes.id,
      title: '${kardes.firstName} borç istiyor',
      text: '${kardes.firstName} para sıkıntısında ve senden yardım '
          'istedi.',
      options: <FamilyDecisionOption>[
        FamilyDecisionOption(
          response: FamilyIssueResponse.paraVerdi,
          label: 'Ver '
              '(${_bin(FamilyDisputes.prototypeOnlySiblingAsk)} bin ₺)',
          blockedReason: FamilyDisputes.siblingAskBlockReason(
            state,
            FamilyIssueResponse.paraVerdi,
          ),
        ),
        const FamilyDecisionOption(
          response: FamilyIssueResponse.destekOldu,
          label: 'Para yerine iş bulmasına yardım et',
        ),
        const FamilyDecisionOption(
          response: FamilyIssueResponse.reddetti,
          label: 'Veremeyeceğini söyle',
        ),
      ],
    );
  }

  static FamilyDecision? _care(GameState state) {
    final FamilyIssue? mesele = FamilyDisputes.pendingCareDispute(state);
    if (mesele == null) return null;
    final Person? ebeveyn = state.personById(mesele.personId);
    if (ebeveyn == null) return null;
    return FamilyDecision(
      kind: FamilyIssueKind.bakim,
      personId: ebeveyn.id,
      title: '${ebeveyn.firstName} için bakım',
      text: '${ebeveyn.firstName} artık tek başına idare edemiyor. '
          'Bu yükü nasıl karşılayacağına karar vermen gerekiyor.',
      options: <FamilyDecisionOption>[
        FamilyDecisionOption(
          response: FamilyIssueResponse.destekOldu,
          label: 'Bakımı ben üstlenirim',
          blockedReason: FamilyDisputes.careBlockReason(
            state,
            FamilyIssueResponse.destekOldu,
          ),
        ),
        FamilyDecisionOption(
          response: FamilyIssueResponse.paraVerdi,
          label: 'Ücretli bakıma katkı ver',
          blockedReason: FamilyDisputes.careBlockReason(
            state,
            FamilyIssueResponse.paraVerdi,
          ),
        ),
        const FamilyDecisionOption(
          response: FamilyIssueResponse.konustu,
          label: 'Kardeşlerinle konuş',
        ),
        const FamilyDecisionOption(
          response: FamilyIssueResponse.reddetti,
          label: 'Üstlenemeyeceğini söyle',
        ),
      ],
    );
  }

  static FamilyDecision? _estate(GameState state) {
    final FamilyIssue? mesele = FamilyDisputes.pendingEstateDispute(state);
    if (mesele == null) return null;
    final Person? kardes = state.personById(mesele.personId);
    if (kardes == null) return null;
    final int tutar = FamilyDisputes.contestedAmount(state);
    return FamilyDecision(
      kind: FamilyIssueKind.miras,
      personId: kardes.id,
      title: 'Miras anlaşmazlığı',
      text: '${kardes.firstName} paylaşıma itiraz ediyor ve '
          '${_bin(tutar)} bin ₺ hakkı olduğunu söylüyor.',
      options: <FamilyDecisionOption>[
        FamilyDecisionOption(
          response: FamilyIssueResponse.paraVerdi,
          label: 'Hakkını ver',
          blockedReason: FamilyDisputes.estateBlockReason(
            state,
            FamilyIssueResponse.paraVerdi,
          ),
        ),
        const FamilyDecisionOption(
          response: FamilyIssueResponse.konustu,
          label: 'Konuş ama verme',
        ),
        const FamilyDecisionOption(
          response: FamilyIssueResponse.reddetti,
          label: 'Hakkı olmadığını söyle',
        ),
      ],
    );
  }

  static FamilyDecision? _conflict(GameState state) {
    final FamilyIssue? mesele = InLawRelations.pendingConflict(state);
    if (mesele == null) return null;
    final Person? ebeveyn = state.personById(mesele.personId);
    final Person? es = state.spouse;
    if (ebeveyn == null || es == null) return null;
    return FamilyDecision(
      kind: FamilyIssueKind.kayinGerginlik,
      personId: ebeveyn.id,
      title: 'Arada kaldın',
      text: '${es.firstName} ile ${ebeveyn.firstName} arasında bir mesele '
          'var. İkisi de senin ne diyeceğini bekliyor.',
      options: const <FamilyDecisionOption>[
        FamilyDecisionOption(
          response: FamilyIssueResponse.destekOldu,
          label: 'Eşinin yanında dur',
        ),
        FamilyDecisionOption(
          response: FamilyIssueResponse.reddetti,
          label: 'Ailenin yanında dur',
        ),
        FamilyDecisionOption(
          response: FamilyIssueResponse.karismadi,
          label: 'Taraf tutma',
        ),
      ],
    );
  }

  static String _bin(int tutar) => (tutar / 1000).round().toString();
}
