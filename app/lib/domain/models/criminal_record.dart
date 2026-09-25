/// Adli durum kaydı (D-128).
///
/// **Kayıt silinmez** — bu projenin genel kuralı burada da geçerlidir.
/// Kapanan dosya listede kalır, "tamamlandı" işaretiyle durur. Sabıka
/// geçmişi hayat boyunca okunabilir.
library;

import 'package:flutter/foundation.dart';

import '../../data/crime_catalog.dart';
import '../../data/lawyer_catalog.dart';

/// Bir dosyanın hangi aşamada olduğu.
///
/// Yeni değerler listenin **sonuna** eklenir; eski kayıtlar bozulmasın.
enum CaseStage {
  /// İdari ceza kesildi, iş orada bitti. Sabıka açılmaz.
  idariCeza('İdari ceza'),

  /// Hakkında soruşturma var; henüz dava değil.
  sorusturma('Soruşturma'),

  /// Dosya mahkemeye gitti, duruşma bekleniyor.
  dava('Dava'),

  /// Soruşturma kapandı, işlem yapılmadı.
  takipsizlik('Takipsizlik'),

  /// Mahkeme karar verdi.
  karar('Karar verildi');

  const CaseStage(this.label);

  final String label;
}

/// Mahkemenin kararı.
enum Verdict {
  yok('—'),
  beraat('Beraat'),
  uyari('Uyarı'),
  paraCezasi('Para cezası'),
  erteleme('Hükmün ertelenmesi'),
  hapis('Hapis');

  const Verdict(this.label);

  final String label;

  /// Bu karar sabıka kaydı bırakır mı?
  ///
  /// Beraat ve uyarı bırakmaz; erteleme "kayıtta durur ama ceza infaz
  /// edilmez" anlamında sayılır.
  bool get leavesRecord =>
      this == Verdict.paraCezasi ||
      this == Verdict.erteleme ||
      this == Verdict.hapis;
}

/// Tek bir adli dosya.
@immutable
class CriminalCase {
  const CriminalCase({
    required this.id,
    required this.crimeId,
    required this.ageAtIncident,
    required this.stage,
    this.verdict = Verdict.yok,
    this.fine = 0,
    this.finePaid = false,
    this.prisonYears = 0,
    this.lawyerId,
    this.decidedAtAge,
    this.closedAtAge,
    this.note,
  });

  final String id;

  /// [CrimeType.id].
  final String crimeId;

  /// Olayın yaşandığı yaş.
  final int ageAtIncident;

  final CaseStage stage;
  final Verdict verdict;

  /// Kesilen para cezası (₺). **Bir kez** tahsil edilir.
  final int fine;

  /// Ceza gerçekten cüzdandan düştü mü? Aynı ceza iki kez kesilmez.
  final bool finePaid;

  /// Verilen hapis cezası (oyun yılı).
  final int prisonYears;

  /// Duruşmada tutulan avukat ([LawyerTier.id]); yoksa `null`.
  final String? lawyerId;

  /// Kararın verildiği yaş.
  final int? decidedAtAge;

  /// Cezanın tamamen bittiği yaş (para ödendi ya da tahliye oldu).
  final int? closedAtAge;

  /// Ekranda gösterilen kısa açıklama.
  final String? note;

  CrimeType? get crime => crimeTypeById(crimeId);

  LawyerTier? get lawyer => lawyerId == null ? null : lawyerTierById(lawyerId!);

  /// Dosya hâlâ sürüyor mu?
  bool get isOpen =>
      stage == CaseStage.sorusturma || stage == CaseStage.dava;

  /// Bu dosya sabıka kaydı bıraktı mı?
  bool get leavesRecord =>
      stage == CaseStage.karar && verdict.leavesRecord;

  /// Ceza tarafı tamamlandı mı?
  bool get isFinished => closedAtAge != null;

  CriminalCase copyWith({
    CaseStage? stage,
    Verdict? verdict,
    int? fine,
    bool? finePaid,
    int? prisonYears,
    Object? lawyerId = _unset,
    Object? decidedAtAge = _unset,
    Object? closedAtAge = _unset,
    Object? note = _unset,
  }) {
    return CriminalCase(
      id: id,
      crimeId: crimeId,
      ageAtIncident: ageAtIncident,
      stage: stage ?? this.stage,
      verdict: verdict ?? this.verdict,
      fine: fine ?? this.fine,
      finePaid: finePaid ?? this.finePaid,
      prisonYears: prisonYears ?? this.prisonYears,
      lawyerId: lawyerId == _unset ? this.lawyerId : lawyerId as String?,
      decidedAtAge:
          decidedAtAge == _unset ? this.decidedAtAge : decidedAtAge as int?,
      closedAtAge:
          closedAtAge == _unset ? this.closedAtAge : closedAtAge as int?,
      note: note == _unset ? this.note : note as String?,
    );
  }
}

/// Oyuncunun adli durumu.
@immutable
class LegalState {
  const LegalState({
    this.cases = const <CriminalCase>[],
    this.imprisonedSinceAge,
    this.releaseAtAge,
    this.probationUntilAge,
    this.caseCounter = 0,
  });

  /// Bütün dosyalar, açılış sırasıyla. **Silinmez.**
  final List<CriminalCase> cases;

  /// Hapse girilen yaş; içeride değilse `null`.
  final int? imprisonedSinceAge;

  /// Tahliye yaşı; içeride değilse `null`.
  final int? releaseAtAge;

  /// Tahliye sonrası denetim dönemi bu yaşa kadar sürer.
  final int? probationUntilAge;

  /// Dosya kimlikleri için sayaç; kimlikler çakışmaz.
  final int caseCounter;

  bool get isImprisoned => releaseAtAge != null;

  /// Sabıka kaydı bırakmış dosyalar.
  List<CriminalCase> get record =>
      cases.where((CriminalCase c) => c.leavesRecord).toList(growable: false);

  bool get hasRecord => record.isNotEmpty;

  /// Şu an süren dosya (soruşturma ya da dava); yoksa `null`.
  CriminalCase? get openCase {
    for (final CriminalCase c in cases) {
      if (c.isOpen) return c;
    }
    return null;
  }

  /// Sabıkada bu ağırlıkta bir kayıt var mı?
  bool hasRecordOfSeverity(CrimeSeverity severity) => record.any(
        (CriminalCase c) => c.crime?.severity == severity,
      );

  /// Sabıkadaki en ağır kayıt; temizse `null`.
  CrimeSeverity? get worstSeverity {
    CrimeSeverity? enAgir;
    for (final CriminalCase c in record) {
      final CrimeSeverity? s = c.crime?.severity;
      if (s == null) continue;
      if (enAgir == null || s.index > enAgir.index) enAgir = s;
    }
    return enAgir;
  }

  /// Hiç mahkemeye çıkılmış mı? (Beraat de sayılır.)
  bool get everTried =>
      cases.any((CriminalCase c) => c.stage == CaseStage.karar);

  CriminalCase? caseById(String id) {
    for (final CriminalCase c in cases) {
      if (c.id == id) return c;
    }
    return null;
  }

  LegalState copyWith({
    List<CriminalCase>? cases,
    Object? imprisonedSinceAge = _unset,
    Object? releaseAtAge = _unset,
    Object? probationUntilAge = _unset,
    int? caseCounter,
  }) {
    return LegalState(
      cases: cases == null
          ? this.cases
          : List<CriminalCase>.unmodifiable(cases),
      imprisonedSinceAge: imprisonedSinceAge == _unset
          ? this.imprisonedSinceAge
          : imprisonedSinceAge as int?,
      releaseAtAge:
          releaseAtAge == _unset ? this.releaseAtAge : releaseAtAge as int?,
      probationUntilAge: probationUntilAge == _unset
          ? this.probationUntilAge
          : probationUntilAge as int?,
      caseCounter: caseCounter ?? this.caseCounter,
    );
  }
}

const Object _unset = Object();
