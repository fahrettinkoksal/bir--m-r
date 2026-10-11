import 'package:flutter/foundation.dart';

/// Birden fazla yıl süren bir aile meselesinin türü (Paket AP §4).
///
/// **Sıraya ekleme kuralı:** yeni tür her zaman listenin **sonuna**
/// eklenir. Kayıt dosyası değeri adıyla yazıyor ama eski kayıtlarda
/// tanınmayan bir ad çıkabilir; o durumda mesele düşürülür, kayıt
/// bozulmaz.
enum FamilyIssueKind {
  /// Çocuğun okuldaki sorunu (§5).
  cocukOkul('Okul sorunu'),

  /// Yetişkin çocuğun para sıkıntısı (§8).
  cocukPara('Para sıkıntısı'),

  /// Çocuğun evliliğindeki sorun (§19).
  cocukEvlilik('Evlilik sorunu'),

  /// Kardeşle para meselesi (§28).
  kardesPara('Kardeşle para meselesi'),

  /// Yaşlı ebeveynin bakımı (§30).
  bakim('Bakım meselesi'),

  /// Gelin/damat ya da kayın aileyle gerginlik (§26).
  kayinGerginlik('Kayın aile gerginliği'),

  /// Miras anlaşmazlığı (§35).
  miras('Miras anlaşmazlığı');

  const FamilyIssueKind(this.label);

  /// Ekranda görünen ad.
  final String label;
}

/// Oyuncunun bir aile meselesine verdiği cevap.
///
/// **Tek** bir küme olarak tutuluyor: her mesele türü için ayrı bir
/// cevap enum'u yazmak §4'ün "gereksiz generic framework kurma"
/// kuralına ters düşerdi. Cevabın ne anlama geldiğini meselenin kendi
/// kodu yorumlar.
///
/// Yeni değer her zaman listenin **sonuna** eklenir.
enum FamilyIssueResponse {
  /// Yanında durdu: zaman ve ilgi verdi.
  destekOldu('Yanında oldu'),

  /// Konuştu, akıl verdi; karar karşı tarafta kaldı.
  konustu('Konuştu'),

  /// Para harcadı (özel ders, borç, destek).
  paraVerdi('Maddi destek verdi'),

  /// Karışmamayı seçti.
  karismadi('Karışmadı'),

  /// Açıkça reddetti.
  reddetti('Reddetti');

  const FamilyIssueResponse(this.label);

  final String label;
}

/// Bir aile meselesinin bugünkü durumu.
enum FamilyIssueStatus {
  /// Sürüyor; oyuncu bir şey yapabilir.
  acik('Sürüyor'),

  /// Çözüldü.
  cozuldu('Çözüldü'),

  /// Çözülmeden kapandı (kişi vefat etti, mesele anlamını yitirdi).
  kapandi('Kapandı');

  const FamilyIssueStatus(this.label);

  final String label;
}

/// Birden fazla yıl süren **tek** bir aile meselesi (Paket AP §4, §51).
///
/// Neden ayrı bir kayıt: AP'den önce çok yıllı aile durumları ya hiç
/// yoktu ya da `storyFlags` içine yazılıyordu. `storyFlags` yalnızca bir
/// metin kümesi; "kimin meselesi", "kaç yıldır sürüyor", "hangi aşamada"
/// sorularının cevabını taşıyamıyor. §4 bu yüzden "yalnızca storyFlag
/// ile yamama" dedi.
///
/// Kasten **küçük** tutuldu (§4: "gereksiz generic framework kurma"):
/// kimin meselesi, ne meselesi, kaçıncı yıl, hangi aşama, son ne zaman
/// konuşuldu. Metin, seçenek ve etki burada durmaz — onlar olayın kendi
/// kodunda durur.
@immutable
class FamilyIssue {
  const FamilyIssue({
    required this.id,
    required this.kind,
    required this.personId,
    required this.openedAtAge,
    required this.lastEventAge,
    this.status = FamilyIssueStatus.acik,
    this.stage = 0,
    this.resolvedAtAge,
    this.response,
  });

  /// Kayıt içinde tekil kimlik.
  ///
  /// Kişiden ve türden türetilir ki aynı mesele iki kez açılmasın.
  final String id;

  final FamilyIssueKind kind;

  /// Meselenin **gerçek** kişisi (§53: uydurma kimlik yazılmaz).
  final String personId;

  /// Meselenin açıldığı oyuncu yaşı.
  final int openedAtAge;

  /// Meselenin en son oyuncunun karşısına çıktığı yaş (§3 sayacı).
  final int lastEventAge;

  final FamilyIssueStatus status;

  /// Meselenin kaçıncı aşamada olduğu; her olay bir artırır.
  final int stage;

  /// Kapandığı yaş; hâlâ açıksa `null`.
  final int? resolvedAtAge;

  /// Oyuncunun bu meseleye verdiği **son** cevap; hiç sorulmadıysa
  /// `null`.
  ///
  /// Sonraki yıllar bunu okur: "geçen yıl ne yaptın" sorusunun cevabı
  /// burada durur. Oyuncunun seçimi karşı tarafın kararını belirlemez
  /// (§1), yalnızca ihtimali kaydırır.
  final FamilyIssueResponse? response;

  bool get isOpen => status == FamilyIssueStatus.acik;

  /// Kaç yıldır sürüyor (verilen yaşa göre).
  int yearsOpen(int currentAge) {
    final int fark = (resolvedAtAge ?? currentAge) - openedAtAge;
    return fark < 0 ? 0 : fark;
  }

  /// Bu mesele için kimlik üretir.
  static String idFor(FamilyIssueKind kind, String personId, int openedAtAge) =>
      '${kind.name}-$personId-$openedAtAge';

  FamilyIssue copyWith({
    FamilyIssueStatus? status,
    int? stage,
    int? lastEventAge,
    int? resolvedAtAge,
    FamilyIssueResponse? response,
  }) =>
      FamilyIssue(
        id: id,
        kind: kind,
        personId: personId,
        openedAtAge: openedAtAge,
        lastEventAge: lastEventAge ?? this.lastEventAge,
        status: status ?? this.status,
        stage: stage ?? this.stage,
        resolvedAtAge: resolvedAtAge ?? this.resolvedAtAge,
        response: response ?? this.response,
      );
}
