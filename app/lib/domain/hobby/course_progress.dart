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
import '../models/game_state.dart';
import '../models/hobby_progress.dart';
import 'hobby_tracker.dart';

/// Kursun hangi kademesinde olunduğu.
enum CourseTier {
  /// İlk beş ders: ücretsiz tanışma dönemi.
  tanisma('Tanışma dersleri', 0.0),

  /// 6-10: düşük ücret.
  baslangic('Başlangıç', 0.40),

  /// 11-20: normal ücret. Katalogdaki fiyat bu kademeyi anlatır.
  normal('Normal', 1.0),

  /// 20+: özel hoca, ileri ekipman, yarışma hazırlığı.
  profesyonel('İleri seviye', 2.2);

  const CourseTier(this.label, this.feeMultiplier);

  final String label;

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

    // Tanışma dersi ancak yıllık hak varken ücretsiz. Hak bittiyse aynı
    // ders başlangıç kademesinden ücretlenir: kapı kapanmaz, bedava
    // olmaktan çıkar.
    final bool bedava = kademe == CourseTier.tanisma && yillikKalan > 0;
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
  static GameState countFreeLesson(GameState state) =>
      state.copyWith(interactionCounts: <String, int>{
        ...state.interactionCounts,
        GameState.interactionKey(yearlyFreeCounterId, counterKind):
            yearlyFreeUsed(state) + 1,
      });
}
