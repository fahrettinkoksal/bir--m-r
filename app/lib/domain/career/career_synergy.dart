// Hobi → kariyer sinerjisi (Paket AK).
//
// **Neden var.** Paket AJ'den sonra 12 hobinin hepsi erişilebilir, ama
// katalogda hobiye bağlı yalnızca iki meslek vardı: Yazar (okuma) ve
// Müzisyen (müzik). İkisi de **zorunlu şart**. Yani on hobinin kariyer
// tarafında hiçbir karşılığı yoktu; çocukken başlanan fotoğraf kursu
// hayatın geri kalanında hiçbir kapı açmıyordu.
//
// **Bu katman kilit koymuyor.** Faho'nun kararı açık: kurs/hobi
// yapmamış oyuncunun bugün girebildiği mesleklerin hiçbiri
// kapanmayacak. Bu yüzden sinerji `JobType.hobbyId` / `minHobbyStage`
// sert şartından **ayrı** bir alanda duruyor ve
// `JobMarket.requirementReason` içine hiç girmiyor: sinerjisi olmayan
// oyuncu aynı işe aynı koşullarla başvurabiliyor.
//
// **Avantaj nereden geliyor.** Üç yerden, üçü de sınırlı:
//
// * **Mülakat** — cevap tutmazsa iş bitmiyor; güçlü bir geçmiş ikinci
//   bir şans veriyor. Garanti değil: en yüksek sinerjide bile zar
//   atılıyor (bkz. `prototypeOnlyMaxInterviewRescue`).
// * **Başlangıç ustalığı** — on yıldır fotoğraf çeken biri işe sıfır
//   çırak olarak başlamıyor; ama usta olarak da başlamıyor. En fazla
//   beş yıllık bir baş­langıç payı veriliyor, o da Kalfa basamağına
//   denk (Usta 8 yıl ister).
// * **Terfi** — hobi işe girdikten sonra da sürüyorsa çok küçük bir
//   devam payı. Hobiyi spamlamak bunu büyütmüyor; pay hobinin
//   **basamağından** geliyor, o yılki ders sayısından değil.
//
// **Maaşa dokunmuyor.** Katalog maaşı ve gelir bandı bu dosyadan hiç
// etkilenmiyor (§3).
//
// Bütün sayılar `prototypeOnly`'dir.
library;

import '../../data/hobby_catalog.dart';
import '../../data/job_catalog.dart';
import '../models/game_state.dart';
import '../models/hobby_progress.dart';
import '../hobby/hobby_tracker.dart';

/// Bir hobinin bir mesleğe kattığı ağırlık.
enum SynergyStrength {
  /// Yan yana duran, doğal ama küçük bir katkı.
  kucuk('küçük', 0.35),

  /// Anlamlı ama mesleğin özü değil.
  orta('orta', 0.65),

  /// Hobi pratikte mesleğin kendisi.
  guclu('güçlü', 1.0);

  const SynergyStrength(this.label, this.weight);

  final String label;

  /// prototypeOnly: bu bağın taşıdığı ağırlık.
  final double weight;
}

/// Bir mesleğin bir hobiden aldığı avantaj (kilit değil).
class CareerSynergy {
  const CareerSynergy(this.hobbyId, this.strength);

  final String hobbyId;
  final SynergyStrength strength;
}

/// Oyuncunun bir meslekteki sinerji durumu.
class SynergyStanding {
  const SynergyStanding({
    required this.hobby,
    required this.strength,
    required this.stageLabel,
    required this.score,
    required this.isActive,
  });

  final HobbyKind hobby;
  final SynergyStrength strength;

  /// Oyuncunun o hobideki basamağının adı ("Düzenli" gibi).
  final String stageLabel;

  /// 0-1 arası katkı payı.
  final double score;

  /// Hobi hâlâ sürüyor mu (son üç yıl içinde uğraşıldı mı)?
  final bool isActive;
}

abstract final class CareerSynergyRules {
  /// prototypeOnly: hobi basamağının katkı payı.
  ///
  /// Sıra `HobbyKind.stages` ile aynı: Hevesli, Meraklı, Düzenli,
  /// Tutkulu, Usta. Hevesli **sıfır**: bir ders alıp kariyer avantajı
  /// toplamak yok (§22).
  static const List<double> prototypeOnlyStageWeight = <double>[
    0.0,
    0.25,
    0.55,
    0.80,
    1.00,
  ];

  /// prototypeOnly: yıllardır yapılmayan hobinin kalan payı.
  ///
  /// Geçmiş silinmiyor: on yıl önce usta olan biri hâlâ o işi bilir.
  /// Ama aktif olanla aynı da değil (§20).
  static const double prototypeOnlyLapsedFactor = 0.55;

  /// prototypeOnly: ikinci uygun hobinin katkısı.
  ///
  /// Toplama değil: en güçlü bağ esas alınır, ikincisi yalnızca küçük
  /// bir pay ekler. Böylece aynı yıl beş kursa yazılıp avantajları
  /// çarpmak mümkün olmuyor (§22), ama hem çok okuyup hem düzenli
  /// yazan oyuncu gerçekten daha hazırlıklı oluyor (§8).
  static const double prototypeOnlySecondBestShare = 0.25;

  /// prototypeOnly: mülakatta cevabı tutmayan adaya verilen ikinci
  /// şansın **en yüksek** ihtimali.
  ///
  /// Tavan bilinçli olarak yarımın altında: en yüksek sinerjide bile
  /// işe girmek zar atmaya bağlı. "Usta = kesin işe girer" yok (§2).
  static const double prototypeOnlyMaxInterviewRescue = 0.45;

  /// prototypeOnly: işe başlarken verilen en fazla ustalık yılı.
  ///
  /// Beş yıl Kalfa'ya (3 yıl) yetiyor, Usta'ya (8 yıl) yetmiyor: işe
  /// hazırlıklı başlanıyor, usta olarak başlanmıyor (§18).
  static const int prototypeOnlyMaxHeadStartYears = 5;

  /// prototypeOnly: hobi sürüyorsa zam/terfi şansına eklenen en fazla
  /// pay.
  ///
  /// Kasten küçük: terfiyi hobi değil iş belirler (§19).
  static const double prototypeOnlyMaxPromotionBonus = 0.05;

  /// Bu meslekle oyuncunun hobileri arasındaki bağlar.
  ///
  /// Yalnızca oyuncunun **gerçekten** ilerlettiği hobiler döner; kayıt
  /// uydurulmaz. Payı sıfır olan (Hevesli) basamak da dışarıda kalır:
  /// ekranda "avantajın var" yazıp hiçbir şey vermek olmaz.
  static List<SynergyStanding> standingsFor(GameState state, JobType job) {
    final List<SynergyStanding> sonuc = <SynergyStanding>[];
    for (final CareerSynergy bag in job.synergies) {
      final HobbyKind? hobi = hobbyById(bag.hobbyId);
      if (hobi == null) continue;
      final HobbyProgress? ilerleme = HobbyTracker.progressOf(state, hobi);
      if (ilerleme == null) continue;

      final int basamak =
          ilerleme.stage.clamp(0, prototypeOnlyStageWeight.length - 1);
      final bool aktif = ilerleme.isActiveAt(state.player.age);
      final double pay = prototypeOnlyStageWeight[basamak] *
          bag.strength.weight *
          (aktif ? 1.0 : prototypeOnlyLapsedFactor);
      if (pay <= 0) continue;

      sonuc.add(SynergyStanding(
        hobby: hobi,
        strength: bag.strength,
        stageLabel: ilerleme.stageLabel,
        score: pay,
        isActive: aktif,
      ));
    }
    sonuc.sort((SynergyStanding a, SynergyStanding b) =>
        b.score.compareTo(a.score));
    return sonuc;
  }

  /// Bu meslekteki toplam sinerji payı (0-1).
  static double scoreFor(GameState state, JobType job) {
    final List<SynergyStanding> baglar = standingsFor(state, job);
    if (baglar.isEmpty) return 0;
    double toplam = baglar.first.score;
    if (baglar.length > 1) {
      toplam += baglar[1].score * prototypeOnlySecondBestShare;
    }
    return toplam.clamp(0.0, 1.0);
  }

  /// Mülakatta cevabı tutmayan adayın yine de işe alınma ihtimali.
  static double interviewRescueChance(GameState state, JobType job) =>
      scoreFor(state, job) * prototypeOnlyMaxInterviewRescue;

  /// İşe başlarken verilen ustalık yılı payı.
  static int headStartYears(GameState state, JobType job) =>
      (scoreFor(state, job) * prototypeOnlyMaxHeadStartYears).round();

  /// Süren işte hobi de sürüyorsa zam/terfi şansına eklenen pay.
  ///
  /// Hobi bırakılmışsa **sıfır**: geçmiş ustalığı işe başlarken
  /// sayıldı, terfi masasında da ikinci kez sayılmıyor.
  static double promotionBonus(GameState state) {
    final JobType? is_ = state.career.job;
    if (is_ == null) return 0;
    final List<SynergyStanding> baglar = standingsFor(state, is_)
        .where((SynergyStanding s) => s.isActive)
        .toList(growable: false);
    if (baglar.isEmpty) return 0;
    return baglar.first.score * prototypeOnlyMaxPromotionBonus;
  }

  /// Ekranda kullanılacak avantaj sözcüğü; matematik gösterilmez (§16).
  static String label(double score) {
    if (score >= 0.75) return 'güçlü avantaj';
    if (score >= 0.45) return 'anlamlı avantaj';
    if (score >= 0.20) return 'orta avantaj';
    return 'küçük avantaj';
  }

  /// İş ilanında gösterilecek tek satır; avantaj yoksa `null` (§16).
  static String? applicationNote(GameState state, JobType job) {
    final List<SynergyStanding> baglar = standingsFor(state, job);
    if (baglar.isEmpty) return null;
    final SynergyStanding en = baglar.first;
    final String ek = en.isActive
        ? ''
        : ' Uzun zamandır uğraşmıyorsun, eskisi kadar değil.';
    return '${en.hobby.label} hobin bu başvuruda sana '
        '${label(scoreFor(state, job))} sağlıyor.$ek';
  }
}
