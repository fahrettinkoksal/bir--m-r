import '../../data/health_crisis_catalog.dart';
import '../models/game_state.dart';
import '../models/health_history.dart';
import '../models/life_log.dart';
import '../models/pending_crisis.dart';
import '../models/person.dart';

/// Sağlığın hangi bantta olduğu (Paket AQ).
///
/// **Neden var:** sağlık 0'a inebiliyor ve karakter hiçbir şey olmamış
/// gibi yaşamaya, spor yapmaya, seyahat etmeye ve yıllarca yaş almaya
/// devam ediyordu. Ölçüldü (200 hayat, 10.616 yıl): hayatların
/// **%60,5'inde** sağlık bir kez 0'a indi ve toplam **1.607 yıl** sağlık
/// 0 iken yaşandı — bütün yılların %15'i. Tek tüketici
/// `Mortality.prototypeOnlyYearlyChance`'ın en çok iki katına çıkan
/// çarpanıydı; otuz yaşında yıllık ölüm ihtimalini binde 1'den binde
/// 2'ye çıkarıyordu, yani hiçbir şey.
///
/// Bant **sınır değerinin gameplay anlamı** olsun diye var: her yere
/// `if (health < 10)` kopyalamak yerine tek yerden sorulur.
///
/// Bütün eşikler `prototypeOnly`'dir (Q-189).
enum HealthBand {
  /// 26-100: olağan davranış. Hiçbir ek kısıt yok.
  normal('iyi'),

  /// 11-25: kritik derecede düşük. Ağır fiziksel iş ve elektif işlem
  /// kapanır; hayat devam eder.
  kritikDusuk('kritik derecede düşük'),

  /// 1-10: hayati tehlike seviyesi. Yukarıdakilerin üstüne uzun seyahat
  /// ve riskli işlem de kapanır.
  hayatiTehlike('hayati tehlike seviyesinde'),

  /// 0: acil. Zorunlu çözüm açılır; oyuncu bunu çözmeden yaş alamaz.
  acil('acil');

  const HealthBand(this.label);

  /// Oyuncuya gösterilen doğal Türkçe etiket. Teknik terim yok.
  final String label;

  /// Bu bant olağan dışı mı? (Ekranda ayrı gösterilir.)
  bool get isLow => this != HealthBand.normal;

  /// Ağır fiziksel iş bu bantta kapalı mı?
  bool get blocksHeavyEffort => isLow;

  /// Uzun yolculuk ve riskli elektif işlem bu bantta kapalı mı?
  bool get blocksRiskyChoice =>
      this == HealthBand.hayatiTehlike || this == HealthBand.acil;

  /// Zorunlu çözüm gerektiriyor mu?
  bool get needsResolution => this == HealthBand.acil;
}

/// Sağlığın kritik seviyeye **neden** indiği.
///
/// Yalnızca oyunun gerçekten bildiği sebepler var; bilinmiyorsa
/// [bilinmiyor] kullanılır ve **sebep uydurulmaz**.
enum CriticalHealthCause {
  /// Ağır hastalık ve üst üste gelen raporlar (D-078, D-116).
  hastalik('hastalik'),

  /// Taşınan kalıcı rahatsızlığın ağırlaşması (D-153).
  rahatsizlik('rahatsizlik'),

  /// İleri yaşta bedenin çökmesi (D-072).
  yaslilik('yaslilik'),

  /// Sakatlık: spor, dövüş ya da kaza (D-155, D-157).
  sakatlik('sakatlik'),

  /// Atlatılan bir sağlık krizinin ardından (D-044).
  kriz('kriz'),

  /// Oyuncunun bir kararının sonucu.
  karar('karar'),

  /// Kayıtta sebep yok. Metinde sebep **yazılmaz**.
  bilinmiyor('bilinmiyor');

  const CriticalHealthCause(this.id);

  /// Kayda yazılan kimlik; enum sırası değişse de kayıt bozulmaz.
  final String id;

  static CriticalHealthCause? byId(String? id) {
    if (id == null) return null;
    for (final CriticalHealthCause c in CriticalHealthCause.values) {
      if (c.id == id) return c;
    }
    return null;
  }
}

/// Kritik sağlık durumu: bantlar, zorunlu çözüm ve kurtulma (Paket AQ).
///
/// **İkinci sistem kurulmadı.** Zorunlu çözüm mevcut
/// [HealthCrisisEngine]/[PendingCrisis] yolundan geçer: aynı pencere,
/// aynı kayıt alanı, aynı save/load, aynı ölüm geçişi. Buradaki tek yeni
/// şey, krizin **sağlığın kendisinden** doğması ve sonucunun yaşa,
/// geçmişe ve seçime bağlanması.
abstract final class CriticalHealth {
  /// Zorunlu çözüm krizinin katalog kimliği.
  static const String crisisId = 'kritik_saglik';

  // --- Bantlar ---------------------------------------------------------

  /// prototypeOnly: kritik derecede düşük bandın alt sınırı.
  static const int prototypeOnlyCriticalLowFrom = 11;

  /// prototypeOnly: olağan bandın alt sınırı.
  static const int prototypeOnlyNormalFrom = 26;

  /// Sağlık değerinin bandı.
  static HealthBand bandOf(int health) {
    if (health <= 0) return HealthBand.acil;
    if (health < prototypeOnlyCriticalLowFrom) return HealthBand.hayatiTehlike;
    if (health < prototypeOnlyNormalFrom) return HealthBand.kritikDusuk;
    return HealthBand.normal;
  }

  /// Oyuncunun şu andaki bandı.
  static HealthBand bandFor(GameState state) =>
      bandOf(state.player.stats.health);

  /// Oyuncunun önünde **çözülmesi zorunlu** bir kritik sağlık durumu var mı?
  static bool isPending(GameState state) =>
      state.pendingCrisis?.crisisId == crisisId;

  // --- Zorunlu çözümün açılması ---------------------------------------

  /// Sağlık acil banda indiyse zorunlu çözümü açar.
  ///
  /// Üretim yollarının **hepsinden** çağrılabilir: açık bir kriz varsa,
  /// oyuncu vefat ettiyse ya da sağlık acil bantta değilse durum aynen
  /// döner. Böylece aynı yıl iki kez çağrılmak sorun değil.
  ///
  /// Ölüm **burada uygulanmaz**: karakter krizi çözerken ölebilir. Böylece
  /// aynı yılda `Mortality` ile iki ayrı ölüm sonucu üretilmez.
  static GameState enforce({
    required GameState state,
    required int age,
    CriticalHealthCause cause = CriticalHealthCause.bilinmiyor,
  }) {
    if (state.deceased) return state;
    if (state.pendingCrisis != null) return state;
    if (!bandFor(state).needsResolution) return state;

    final HealthCrisis? kriz = healthCrisisById(crisisId);
    if (kriz == null) return state;

    return state.copyWith(
      pendingCrisis: PendingCrisis(
        crisisId: crisisId,
        age: age,
        causeId: cause == CriticalHealthCause.bilinmiyor ? null : cause.id,
      ),
      // Kriz aralığı sayacı olağan krizlerle paylaşılır: zorunlu çözümün
      // hemen ardından bir de olağan kriz çıkmasın.
      lastCrisisAge: age,
      log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
        ...state.log,
        LifeLogEntry(
          age: age,
          text: openingLine(cause),
          category: LogCategory.kisisel,
        ),
      ]),
    );
  }

  /// Günlüğe ve pencereye yazılan açılış cümlesi.
  ///
  /// Sebep biliniyorsa yazılır; bilinmiyorsa **uydurulmaz**.
  static String openingLine(CriticalHealthCause cause) {
    switch (cause) {
      case CriticalHealthCause.hastalik:
        return 'Üst üste gelen hastalıklar seni tükendi; sağlığın acil '
            'müdahale gerektiren bir noktaya indi.';
      case CriticalHealthCause.rahatsizlik:
        return 'Taşıdığın rahatsızlık ağırlaştı; sağlığın acil müdahale '
            'gerektiren bir noktaya indi.';
      case CriticalHealthCause.yaslilik:
        return 'Bedenin artık eskisi gibi toparlamıyor; sağlığın acil '
            'müdahale gerektiren bir noktaya indi.';
      case CriticalHealthCause.sakatlik:
        return 'Aldığın darbe beklediğinden ağır çıktı; sağlığın acil '
            'müdahale gerektiren bir noktaya indi.';
      case CriticalHealthCause.kriz:
        return 'Atlattığın sağlık sorunu arkasında ağır bir tablo bıraktı; '
            'sağlığın acil müdahale gerektiren bir noktaya indi.';
      case CriticalHealthCause.karar:
        return 'Verdiğin karar bedenine ağır geldi; sağlığın acil müdahale '
            'gerektiren bir noktaya indi.';
      case CriticalHealthCause.bilinmiyor:
        return 'Sağlığın acil müdahale gerektiren bir noktaya indi.';
    }
  }

  /// Pencerede krizin metninin altına yazılan sebep satırı.
  ///
  /// Sebep kayıtta yoksa `null` döner; ekranda uydurma sebep çıkmaz.
  static String? causeLine(PendingCrisis? pending) {
    if (pending == null || pending.crisisId != crisisId) return null;
    final CriticalHealthCause? sebep =
        CriticalHealthCause.byId(pending.causeId);
    if (sebep == null || sebep == CriticalHealthCause.bilinmiyor) return null;
    return openingLine(sebep);
  }

  // --- Kurtulma --------------------------------------------------------

  /// prototypeOnly: hiçbir şey yapılmazsa atlatma ihtimalinin tabanı.
  ///
  /// Rastgele bir %50 zarı değil: yaş, krizden önceki sağlık geçmişi ve
  /// taşınan rahatsızlıklar hesaba katılır (aşağıya bakınız).
  static const double prototypeOnlyBaseSurvival = 0.74;

  /// prototypeOnly: atlatma ihtimalinin alt ve üst sınırı.
  ///
  /// Üst sınır 1 değil: en iyi şartlarda bile garanti yoktur. Alt sınır
  /// 0 değil: en kötü şartlarda bile bir ihtimal kalır.
  static const double prototypeOnlyMinSurvival = 0.12;
  static const double prototypeOnlyMaxSurvival = 0.94;

  /// prototypeOnly: her kalıcı rahatsızlığın atlatma ihtimaline bedeli.
  static const double prototypeOnlyChronicPenalty = 0.09;

  /// prototypeOnly: daha önce atlatılmış her hayati tehlikenin bedeli.
  ///
  /// İkinci ve üçüncü kez aynı eşiğe gelmek aynı şey değildir.
  static const double prototypeOnlyRepeatPenalty = 0.11;

  /// Yaşın atlatma ihtimaline etkisi.
  ///
  /// `Mortality` zaten yaşı hesaba katıyor ama o **yıllık** ölüm
  /// eğrisidir; burada ölçülen şey başka bir soru: acil bir tabloyu
  /// atlatma şansı. İkinci bir yaş çarpanı eklenmedi, yaşın etkisi
  /// yalnızca bu kademelerden geliyor.
  static double prototypeOnlyAgeFactor(int age) {
    if (age < 12) return 0.02;
    if (age < 40) return 0.08;
    if (age < 55) return 0.0;
    if (age < 70) return -0.12;
    if (age < 80) return -0.24;
    return -0.34;
  }

  /// Bu seçimle acil tabloyu atlatma ihtimali.
  static double survivalChance({
    required GameState state,
    required CrisisChoice choice,
  }) {
    double sans = prototypeOnlyBaseSurvival + choice.survivalBonus;
    sans += prototypeOnlyAgeFactor(state.player.age);
    sans -= state.activeChronic.length * prototypeOnlyChronicPenalty;
    sans -= previousCriticalCount(state) * prototypeOnlyRepeatPenalty;
    return sans.clamp(prototypeOnlyMinSurvival, prototypeOnlyMaxSurvival);
  }

  /// Daha önce kaç kez hayati tehlike atlatıldı?
  ///
  /// Sağlık geçmişi (D-153) zaten tutuluyor; yeni bir kayıt alanı
  /// açılmadı.
  static int previousCriticalCount(GameState state) => state.healthHistory
      .where((HealthHistoryEntry e) => e.crisisId == crisisId)
      .length;

  // --- Kurtulma sonrası sağlık -----------------------------------------

  /// prototypeOnly: kurtulan karakterin sağlığının ineceği/çıkacağı bant.
  ///
  /// Ne 100 (hiçbir şey olmamış gibi), ne 1 (ertesi yıl aynı tablo).
  /// Üst sınır bilerek [prototypeOnlyNormalFrom]'un altında: kurtulan
  /// karakter bir süre **kritik derecede düşük** bantta kalır, yani ağır
  /// iş ve elektif işlem kapalı olur. Kalıcı bir ceza değil; toparlanma
  /// (D-116) normal yoldan işler.
  static const int prototypeOnlyRecoveryFloor = 10;
  static const int prototypeOnlyRecoveryCeiling = 25;

  /// prototypeOnly: ileri yaşta kurtulmanın bıraktığı tablo daha ağırdır.
  static const int prototypeOnlyElderRecoveryPenalty = 6;
  static const int prototypeOnlyElderAge = 70;

  /// Kurtulan karakterin yeni sağlık değeri.
  ///
  /// Değer `Stats.gain` ile yazılır (D-099): sağlık 0'dan 25'in altına
  /// çıkmak azalan getiri eşiğinin altında kaldığı için hedef birebir
  /// tutar, kural da ihlal edilmez.
  static int recoveredHealth({
    required GameState state,
    required CrisisChoice choice,
  }) {
    // Tedavinin karşılığı var: iyi seçim daha iyi bir tablo bırakır.
    // Ölçek seçimin kendi `healthChange`ından okunur; yeni bir sayı
    // uydurulmadı.
    final int katki = choice.healthChange.abs().clamp(0, 20);
    int hedef = prototypeOnlyRecoveryFloor + katki ~/ 2;
    if (state.player.age >= prototypeOnlyElderAge) {
      hedef -= prototypeOnlyElderRecoveryPenalty;
    }
    return hedef.clamp(
      prototypeOnlyRecoveryFloor,
      prototypeOnlyRecoveryCeiling,
    );
  }

  /// Kurtulma sonrası ekranda ve günlükte yazan metin.
  ///
  /// Küçük yaştaki oyuncuya yetişkin metni kopyalanmaz: hanede bakım
  /// veren varsa onun götürdüğü yazılır (mevcut hane kaydından okunur,
  /// yeni bir sistem kurulmadı).
  static String resultTextFor({
    required GameState state,
    required CrisisChoice choice,
  }) {
    final bool kucuk = state.player.age < kMinorAge;
    final bool bakimVeren = state.household.any(
      (Person p) => p.isAlive && p.age >= kMinorAge,
    );
    if (kucuk && bakimVeren) {
      return 'Ailen seni vakit kaybetmeden hastaneye götürdü. Tedavi '
          'tuttu; bir süre dinlenmen gerekiyor.';
    }
    return choice.resultText;
  }

  /// Oyuncu bu tabloyu atlatamadıysa ölüm gerekçesi.
  ///
  /// Kayıtta sebep yoksa **uydurulmaz**; genel ve kısa kalır.
  static String deathCauseFor(PendingCrisis? pending) {
    final CriticalHealthCause? sebep =
        CriticalHealthCause.byId(pending?.causeId);
    switch (sebep) {
      case CriticalHealthCause.hastalik:
        return 'uzun süren hastalığı';
      case CriticalHealthCause.rahatsizlik:
        return 'taşıdığı rahatsızlık';
      case CriticalHealthCause.yaslilik:
        return 'yaşlılığa bağlı nedenler';
      case CriticalHealthCause.sakatlik:
        return 'aldığı ağır darbe';
      case CriticalHealthCause.kriz:
      case CriticalHealthCause.karar:
      case CriticalHealthCause.bilinmiyor:
      case null:
        return 'ağır bir sağlık sorunu';
    }
  }

  /// Hayati tehlikeyi atlatan karakterin hayatında **iz kalır**.
  ///
  /// Öğrenciyse okula, çalışıyorsa işe bir süre gidemez. İkisi de mevcut
  /// kayıtlardan okunur; yeni bir devamsızlık sistemi kurulmadı.
  static String? afterEffectLine(GameState state) {
    if (state.education.isSchoolStudent || state.education.isUniversityStudent) {
      return 'Bir süre okula gidemedin; arkadaşların not tuttu.';
    }
    if (state.career.isEmployed) {
      return 'Uzun süre işe gidemedin; iş yerinde bu konuşuldu.';
    }
    return null;
  }

  /// prototypeOnly: yetişkinlik yaşı (bakım verenin aranma eşiği).
  static const int kMinorAge = 18;

  /// Kalıcı rahatsızlığı olan oyuncu için acil tablonun sebebi.
  ///
  /// Yıl içinde hangi sistemin sağlığı düşürdüğü biliniyorsa çağıran
  /// taraf kendi sebebini verir; bu yöntem yalnızca **durumdan okunabilen**
  /// bir sebep arar ve bulamazsa [CriticalHealthCause.bilinmiyor] döner.
  static CriticalHealthCause causeFromState(GameState state) {
    if (state.activeChronic.isNotEmpty) {
      return CriticalHealthCause.rahatsizlik;
    }
    if (state.player.age >= prototypeOnlyElderAge) {
      return CriticalHealthCause.yaslilik;
    }
    return CriticalHealthCause.bilinmiyor;
  }

  /// Yalnızca ölçüm ve test içindir: bir seçimin atlatma ihtimalini
  /// zar atmadan okur.
  static double prototypeOnlySurvivalOf(GameState state, String choiceId) {
    final HealthCrisis? kriz = healthCrisisById(crisisId);
    if (kriz == null) return 0;
    for (final CrisisChoice c in kriz.choices) {
      if (c.id == choiceId) {
        return survivalChance(state: state, choice: c);
      }
    }
    return 0;
  }
}
