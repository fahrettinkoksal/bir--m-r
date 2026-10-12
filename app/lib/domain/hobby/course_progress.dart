// Kurs ilerleme ve ücret kademeleri.
//
// **Neden var.** Paket AI'nın ölçümü şunu gösterdi: 60 tam hayatta tek
// bir ücretli kursa girilemedi. Oyunun gerekçesi hep aynıydı —
// "cüzdanında yeterli para yok". Hiç yatırım ve alışveriş yapmayan
// kontrol grubu bile kursa giremedi. Sonuç: 12 hobinin 10'u ve onlara
// bağlı bütün içerik (yazarlık mesleği dahil) oyuncunun görüş alanının
// dışındaydı.
//
// Bu dosya kapıyı açıyor ama bedava stat çeşmesi kurmuyor:
//
// * **İlk beş ders ücretsiz.** Tanışma dönemi: oyuncu hobiyi deneyebilsin.
// * **Ücretsiz ders büyük stat vermez.** Ana ilerleme hobinin kendi
//   basamakları; statlar kilometre taşlarına bağlı.
// * **Yıllık ücretsiz ders tavanı var.** Aynı yıl bütün kursları dolaşıp
//   bedava stat toplamak mümkün olmasın.
// * **Sonra ücret kademeleri gelir.** 6-10 düşük, 11-20 normal, 20+
//   profesyonel.
library;

import '../../data/activity_catalog.dart';
import '../../data/hobby_catalog.dart';
import '../../data/job_catalog.dart';
import '../models/game_state.dart';
import '../models/hobby_progress.dart';
import 'hobby_tracker.dart';

/// Kursun hangi kademesinde olunduğu.
enum CourseTier {
  /// İlk beş ders: ücretsiz tanışma dönemi.
  tanisma('Tanışma dersleri', 0.0, 'Deneme dersi. Kayıt ücreti yok.'),

  /// 6-10: düşük ücret.
  baslangic('Başlangıç', 0.40, 'Kalabalık grup dersi, malzeme kurstan.'),

  /// 11-20: normal ücret. Katalogdaki fiyat bu kademeyi anlatır.
  normal('Normal', 1.0, 'Küçük grup, kendi malzemenle çalışıyorsun.'),

  /// 20+: özel hoca, ileri ekipman, yarışma hazırlığı (§12).
  profesyonel(
    'İleri seviye',
    2.2,
    'Özel hoca, ileri ekipman ve yarışma hazırlığı bu ücrete dahil.',
  );

  const CourseTier(this.label, this.feeMultiplier, this.note);

  final String label;

  /// Ücretin karşılığında ne alındığı. İleri seviyenin pahalı olmasının
  /// gerekçesi ekranda görünsün diye var (§12): oyuncu zammı sebepsiz
  /// bir sayı olarak görmesin.
  final String note;

  /// Katalog ücretinin kaç katı.
  ///
  /// Kademeler **oyunun kendi ekonomik ölçeğinden** üretiliyor: katalog
  /// fiyatı "normal" kademeyi anlatıyor, ötekiler onun katı. Böylece
  /// asgari ücret çıpası değişince kademeler de birlikte kayar.
  final double feeMultiplier;
}

/// Bir kursun oyuncudaki bugünkü durumu.
class CourseStanding {
  const CourseStanding({
    required this.hobby,
    required this.lessonsTaken,
    required this.tier,
    required this.fee,
    required this.freeLessonsLeft,
    required this.yearlyFreeLeft,
    required this.milestone,
  });

  /// Kursun beslediği hobi.
  final HobbyKind hobby;

  /// Bugüne kadar bu hobide alınan ders (hobi deneyimi).
  final int lessonsTaken;

  final CourseTier tier;

  /// **Bu dersin** ücreti (₺). Tanışma döneminde 0.
  final int fee;

  /// Tanışma döneminden kaç ders kaldı (0-5).
  final int freeLessonsLeft;

  /// Bu yıl kaç ücretsiz ders hakkı kaldı (bütün kurslar toplamı).
  final int yearlyFreeLeft;

  /// Bu ders bir kilometre taşıysa kaçıncı taş (5, 10, 20, 35); değilse 0.
  final int milestone;

  bool get isFree => fee == 0;
}

/// Bir hobinin götürdüğü hayat yolu (Paket AJ, §13).
///
/// Uydurma bir bağ değil: meslek kataloğunda `hobbyId` ile o hobiye
/// bağlanmış işlerden türetiliyor. Katalog değişince bu liste de
/// kendiliğinden değişir; ikinci bir eşleme tablosu tutulmuyor.
class CourseLifePath {
  const CourseLifePath({
    required this.jobId,
    required this.jobName,
    required this.stageLabel,
    required this.lessonsNeeded,
    required this.lessonsLeft,
  });

  final String jobId;
  final String jobName;

  /// Mesleğin istediği hobi basamağının adı ("Düzenli" gibi).
  final String stageLabel;

  /// O basamağa çıkmak için gereken toplam ders.
  final int lessonsNeeded;

  /// Bugünden itibaren kaç ders kaldı; 0 ise yol açık.
  final int lessonsLeft;

  bool get isOpen => lessonsLeft == 0;
}

/// Kurs ilerlemesinin kuralları.
abstract final class CourseProgress {
  /// prototypeOnly: ücretsiz tanışma dersi sayısı.
  static const int prototypeOnlyFreeLessons = 5;

  /// prototypeOnly: **bütün kurslar toplamında** yıllık ücretsiz ders
  /// tavanı.
  ///
  /// Bu tavan olmadan oyuncu aynı yıl on kursun hepsine girip yirmi
  /// bedava ders toplayabilirdi. Tavan, tanışma dönemini gerçek bir
  /// deneme hakkı olarak bırakıyor ama bedava stat turuna çevirmiyor.
  static const int prototypeOnlyYearlyFreeLessons = 6;

  /// prototypeOnly: burs/ücretsiz kontenjan izi (Paket AJ, §7).
  ///
  /// Belediye atölyesi, okul kulübü, öğretmen ya da akraba desteği bu
  /// izi bırakır. İz varken dersler yıl içinde belli bir sayıya kadar
  /// ücretsizdir: sonsuz bedava ders değil, bir yıl açık kalan kapı.
  static const String scholarshipFlag = 'kurs_destegi';

  /// prototypeOnly: burs izi varken yıllık ücretsiz ders hakkı.
  static const int prototypeOnlyScholarshipLessons = 4;

  static const String scholarshipCounterId = 'kursBursu';

  /// prototypeOnly: kilometre taşları.
  static const List<int> prototypeOnlyMilestones = <int>[5, 10, 20, 35];

  /// Sayaç anahtarları `interactionCounts` içinde tutuluyor; o harita
  /// her yaş başında sıfırlanıyor (`LifeProgression`), yani bunlar
  /// **yıllık** sayaçlardır.
  static const String yearlyFreeCounterId = 'kursBedavaDers';
  static const String counterKind = 'kurs';

  /// Bu aktivite bir kurs mu (hobi besleyen, ücretli mekân)?
  static bool isCourse(ActivityAction action) =>
      action.venue == ActivityVenue.kurs &&
      hobbyForActivity(action.id) != null;

  /// Bu yıl kaç ücretsiz ders kullanıldı?
  static int yearlyFreeUsed(GameState state) =>
      state.interactionCount(yearlyFreeCounterId, counterKind);

  /// Bir kursun bugünkü durumu; kurs değilse `null`.
  static CourseStanding? standingFor(GameState state, ActivityAction action) {
    final HobbyKind? hobi = hobbyForActivity(action.id);
    if (hobi == null || action.venue != ActivityVenue.kurs) return null;

    final HobbyProgress? ilerleme = HobbyTracker.progressOf(state, hobi);
    final int alinan = ilerleme?.experience ?? 0;
    final int bedavaKalan =
        (prototypeOnlyFreeLessons - alinan).clamp(0, prototypeOnlyFreeLessons);
    final int yillikKalan =
        (prototypeOnlyYearlyFreeLessons - yearlyFreeUsed(state))
            .clamp(0, prototypeOnlyYearlyFreeLessons);

    final CourseTier kademe = alinan < prototypeOnlyFreeLessons
        ? CourseTier.tanisma
        : alinan < 10
            ? CourseTier.baslangic
            : alinan < 20
                ? CourseTier.normal
                : CourseTier.profesyonel;

    // Burs izi: aile ödeyemediğinde kursu sonsuza kapatmayan yol.
    final int bursKalan = state.storyFlags.contains(scholarshipFlag)
        ? (prototypeOnlyScholarshipLessons -
                state.interactionCount(scholarshipCounterId, counterKind))
            .clamp(0, prototypeOnlyScholarshipLessons)
        : 0;

    // Tanışma dersi ancak yıllık hak varken ücretsiz. Hak bittiyse aynı
    // ders başlangıç kademesinden ücretlenir: kapı kapanmaz, bedava
    // olmaktan çıkar.
    final bool bedava =
        (kademe == CourseTier.tanisma && yillikKalan > 0) || bursKalan > 0;
    final int ucret = bedava
        ? 0
        : (action.cost *
                (kademe == CourseTier.tanisma
                        ? CourseTier.baslangic
                        : kademe)
                    .feeMultiplier)
            .round();

    final int sonrakiDers = alinan + 1;
    final int tas = prototypeOnlyMilestones.contains(sonrakiDers)
        ? sonrakiDers
        : 0;

    return CourseStanding(
      hobby: hobi,
      lessonsTaken: alinan,
      tier: kademe,
      fee: ucret,
      freeLessonsLeft: bedavaKalan,
      yearlyFreeLeft: yillikKalan,
      milestone: tas,
    );
  }

  /// Ekranda gösterilecek kısa durum satırı.
  ///
  /// Örnek: "Tanışma dersleri 3 / 5 · Ücretsiz".
  static String label(CourseStanding s) {
    if (s.tier == CourseTier.tanisma && s.isFree) {
      return 'Tanışma dersleri '
          '${CourseProgress.prototypeOnlyFreeLessons - s.freeLessonsLeft} / '
          '${CourseProgress.prototypeOnlyFreeLessons} · Ücretsiz';
    }
    if (s.tier == CourseTier.tanisma) {
      return 'Bu yılki ücretsiz ders hakkın doldu';
    }
    return '${s.tier.label} · ${s.lessonsTaken}. dersi bitirdin';
  }

  /// Ücretsiz ders sayacını bir artırır.
  ///
  /// Burs izi varken önce burs hakkı harcanır; tanışma hakkı
  /// tüketilmez. Böylece burslu bir yıl, tanışma dersi hakkını
  /// yemez.
  static GameState countFreeLesson(GameState state) {
    final bool burslu = state.storyFlags.contains(scholarshipFlag) &&
        state.interactionCount(scholarshipCounterId, counterKind) <
            prototypeOnlyScholarshipLessons;
    return state.copyWith(interactionCounts: <String, int>{
      ...state.interactionCounts,
      if (burslu)
        GameState.interactionKey(scholarshipCounterId, counterKind):
            state.interactionCount(scholarshipCounterId, counterKind) + 1
      else
        GameState.interactionKey(yearlyFreeCounterId, counterKind):
            yearlyFreeUsed(state) + 1,
    });
  }

  /// Bu hobinin açtığı meslek yolları (§13).
  ///
  /// Kurs bir stat kuyusu değil, bir hayat yolunun başlangıcı olmalı.
  /// Bağlantı meslek kataloğundan okunuyor: `hobbyId` ve
  /// `minHobbyStage` alanları zaten işe giriş koşulu. Burada yalnızca
  /// aynı koşul oyuncunun göreceği hâle çevriliyor; yeni bir kilit
  /// eklenmiyor.
  static List<CourseLifePath> lifePathsFor(
    GameState state,
    HobbyKind hobby,
  ) {
    final HobbyProgress? ilerleme = HobbyTracker.progressOf(state, hobby);
    final int alinan = ilerleme?.experience ?? 0;
    final List<CourseLifePath> yollar = <CourseLifePath>[];

    for (final JobType meslek in kJobCatalog) {
      if (meslek.hobbyId != hobby.id) continue;
      final int basamak = meslek.minHobbyStage.clamp(0, hobby.topStage);
      final int gereken = hobby.stages[basamak].experience;
      yollar.add(CourseLifePath(
        jobId: meslek.id,
        jobName: meslek.name,
        stageLabel: hobby.stages[basamak].label,
        lessonsNeeded: gereken,
        lessonsLeft: (gereken - alinan).clamp(0, gereken),
      ));
    }
    return yollar;
  }

  /// Kartta gösterilecek yol satırı; yol yoksa `null`.
  ///
  /// Meslek bağı olmayan hobi için uydurma bir vaat yazılmıyor: o
  /// durumda satır hiç görünmez.
  static String? lifePathLabel(GameState state, ActivityAction action) {
    final HobbyKind? hobi = hobbyForActivity(action.id);
    if (hobi == null) return null;
    final List<CourseLifePath> yollar = lifePathsFor(state, hobi);
    if (yollar.isEmpty) return null;

    final List<String> parcalar = <String>[];
    for (final CourseLifePath yol in yollar) {
      parcalar.add(yol.isOpen
          ? '${yol.jobName} yolu açık'
          : '${yol.jobName} için ${yol.lessonsLeft} ders daha '
              '(${yol.stageLabel} basamağı)');
    }
    return parcalar.join(' · ');
  }
}
