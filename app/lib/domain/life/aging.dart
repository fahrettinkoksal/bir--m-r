import 'dart:math';

import 'package:flutter/foundation.dart';

import '../generation/random_util.dart';
import '../models/stats.dart';

/// Yaşlanmanın dış görünüşe etkisi (D-051).
///
/// Kurallar:
/// - Bebeklikten ve çocukluktan itibaren **her yıl otomatik ceza yoktur**;
///   etki yetişkinlikte başlar.
/// - Etki **kademeli, hafif ve değişkendir**: her karakter aynı yaşta aynı
///   görünüşe düşmez.
/// - Sağlık ve bakım koşulları etkiyi değiştirebilir; sağlığı iyi olan
///   daha yavaş yıpranır.
/// - Yaşlanma tek başına mutluluğu veya zekâyı düşürmez.
/// - Değer 0-100 sınırında kalır ve belirli bir tabanın altına inmez;
///   görünüşün düşmesi yalnızca **karakterin yaşlandığı** anlamına gelir.
///
/// Bütün yaş aralıkları ve miktarlar `prototypeOnly`'dir (Q-075).
abstract final class Aging {
  /// prototypeOnly: etkinin başladığı yaş. Öncesinde hiç düşüş olmaz.
  static const int prototypeOnlyStartAge = 30;

  /// prototypeOnly: görünüşün inebileceği taban.
  ///
  /// Yaşlanma karakteri sıfıra indirmez; bu bir yargı değil, ölçek
  /// tabanıdır.
  static const int prototypeOnlyFloor = 15;

  /// prototypeOnly: yaş aralığına göre **yıllık düşüş olasılığı**.
  ///
  /// Faho'nun Q-116 kararı: görünüş düşüşü **yumuşatıldı**. Eski eğri
  /// (0,25 / 0,45 / 0,60 / 0,70) yaşlanmayı hissettiriyordu ama orta
  /// yaşta görünüşü fazla hızlı eritiyordu. Yaklaşık dörtte bir
  /// azaltıldı; yön aynı, tempo daha yavaş.
  static double prototypeOnlyChance(int age) {
    if (age < prototypeOnlyStartAge) return 0;
    if (age < 45) return 0.18;
    if (age < 60) return 0.34;
    if (age < 75) return 0.46;
    return 0.55;
  }

  /// prototypeOnly: düşüşün iki puan olma olasılığı (ileri yaşta).
  static double prototypeOnlyDoubleChance(int age) {
    if (age < 60) return 0;
    if (age < 75) return 0.15;
    return 0.25;
  }

  /// Bu yılın görünüş değişimi (0 veya negatif).
  ///
  /// Sağlığı yüksek karakter daha yavaş yıpranır; sağlığı düşük olan
  /// biraz daha hızlı. Sonuç her yıl aynı değildir.
  static int yearlyDelta({
    required int age,
    required int appearance,
    required int health,
    required Random rng,
  }) {
    if (age < prototypeOnlyStartAge) return 0;
    if (appearance <= prototypeOnlyFloor) return 0;

    // Sağlık 50 nötrdür: yüksek sağlık ihtimali azaltır, düşük artırır.
    final double saglikEtkisi = ((50 - health) / 100) * 0.3;
    final double sans =
        (prototypeOnlyChance(age) + saglikEtkisi).clamp(0.0, 0.9);
    if (!rng.chance(sans)) return 0;

    final int dusus = rng.chance(prototypeOnlyDoubleChance(age)) ? 2 : 1;
    final int yeni = (appearance - dusus).clamp(prototypeOnlyFloor, 100);
    return yeni - appearance;
  }

  /// Belirgin bir yıpranma bu yıl yaşandı mı? (Günlüğe yazmak için.)
  ///
  /// Her yıl günlüğe satır yazılmaz; yalnızca iki puanlık düşüşlerde
  /// kısa bir satır çıkar ve satır **gerçekten uygulanan** değişimi
  /// anlatır.
  static bool worthLogging(int delta) => delta <= -2;
}

/// Bir yılda bütün değerlerde yaşanan sürüklenme (D-072).
@immutable
class StatDrift {
  const StatDrift({
    this.appearance = 0,
    this.charisma = 0,
    this.health = 0,
    this.intelligence = 0,
    this.happiness = 0,
    this.notes = const <String>[],
  });

  final int appearance;
  final int charisma;
  final int health;
  final int intelligence;
  final int happiness;

  /// Günlüğe ve bildirime yazılabilecek kısa cümleler.
  final List<String> notes;

  bool get isEmpty =>
      appearance == 0 &&
      charisma == 0 &&
      health == 0 &&
      intelligence == 0 &&
      happiness == 0;
}

/// Bakımın ihmal edilip edilmediğini anlatan yıl sayıları.
///
/// `null`, "hiç yapılmadı" demektir. Hiç yapılmamış olmak, bir kez yapılıp
/// sonra bırakılmış olmaktan **daha ağır** sayılmaz: ikisi de aynı
/// "uzun süredir yok" kovasına düşer. Küçük yaştaki oyuncu bakımsızlıktan
/// cezalandırılmaz (bkz. [StatAging.prototypeOnlyUpkeepFromAge]).
@immutable
class UpkeepStatus {
  const UpkeepStatus({
    this.yearsSinceSport,
    this.yearsSinceGrooming,
    this.yearsSinceLearning,
  });

  final int? yearsSinceSport;
  final int? yearsSinceGrooming;
  final int? yearsSinceLearning;
}

/// Yaşa bağlı değer sürüklenmesi ve bakımın etkisi (D-072).
///
/// **Neden var:** Faho bildirdi — "zekâ 100 olarak başladım 100 olarak
/// bitirdim", "kullanıcı sene atlayınca statlar aynı kalmasın", "bakım
/// yapmayınca kendime görünüşüm ve karizmam düşsün". Değerler yalnızca
/// yükseliyordu; yaş almanın bedeli yoktu, bakımın karşılığı yoktu.
///
/// Kurallar:
/// - Her değerin **kendi başlangıç yaşı** vardır; hepsi aynı anda
///   düşmeye başlamaz. Otuzunda zekâsı azalan karakter olmaz.
/// - Düşüş **ihtimallidir**: aynı yaştaki iki karakter aynı yılı aynı
///   şekilde geçirmez.
/// - **Bakım gerçekten işe yarar.** Son yıllarda spor yapan karakterin
///   karizma ve sağlık kaybı belirgin biçimde azalır; berbere giden
///   görünüşünü daha yavaş kaybeder; okuyan/kurs alan zekâsını korur.
/// - Her değerin bir **tabanı** vardır: yaşlanmak kimseyi sıfıra
///   indirmez. Taban yalnızca *ilgisizlik ve yaş* için geçerlidir;
///   olaylar ve hastalıklar kendi kurallarıyla daha aşağı indirebilir.
/// - Bütün sayılar `prototypeOnly`'dir (Q-116).
abstract final class StatAging {
  /// Bakımsızlığın sayılmaya başladığı yaş.
  ///
  /// Çocuğun berbere kendi gitmesi ya da spor salonuna yazılması
  /// beklenmez; bakım borcu yetişkinlikle başlar.
  static const int prototypeOnlyUpkeepFromAge = 18;

  /// Bakımın "taze" sayıldığı yıl sayısı.
  ///
  /// Bu kadar yıl içinde yapılmışsa koruyucu etkisi tam çalışır.
  static const int prototypeOnlyFreshYears = 2;

  /// Bakımın "ihmal" sayıldığı yıl sayısı.
  static const int prototypeOnlyNeglectYears = 5;

  /// Taze bakımın düşüş ihtimalini çarptığı katsayı.
  static const double prototypeOnlyFreshFactor = 0.45;

  /// Uzun süredir bakım yoksa ihtimali çarpan katsayı.
  static const double prototypeOnlyNeglectFactor = 1.4;

  // --- Başlangıç yaşları ------------------------------------------------
  static const int prototypeOnlyAppearanceFromAge = Aging.prototypeOnlyStartAge;
  static const int prototypeOnlyCharismaFromAge = 35;
  static const int prototypeOnlyHealthFromAge = 45;
  static const int prototypeOnlyIntelligenceFromAge = 60;
  static const int prototypeOnlyHappinessFromAge = 65;

  // --- Tabanlar ---------------------------------------------------------
  static const int prototypeOnlyAppearanceFloor = Aging.prototypeOnlyFloor;
  static const int prototypeOnlyCharismaFloor = 15;
  static const int prototypeOnlyHealthFloor = 30;
  static const int prototypeOnlyIntelligenceFloor = 30;
  static const int prototypeOnlyHappinessFloor = 25;

  /// Bakım durumunun düşüş ihtimaline etkisi.
  ///
  /// [years] `null` ise hiç yapılmamıştır. Yetişkinlik yaşının altındaki
  /// oyuncuda bakım aranmaz; nötr (1.0) döner.
  static double upkeepFactor(int? years, int age) {
    if (age < prototypeOnlyUpkeepFromAge) return 1.0;
    if (years == null) return prototypeOnlyNeglectFactor;
    if (years <= prototypeOnlyFreshYears) return prototypeOnlyFreshFactor;
    if (years >= prototypeOnlyNeglectYears) return prototypeOnlyNeglectFactor;
    return 1.0;
  }

  /// Karizmanın yıllık düşüş ihtimali (bakım öncesi ham değer).
  static double prototypeOnlyCharismaChance(int age) {
    if (age < prototypeOnlyCharismaFromAge) return 0;
    if (age < 50) return 0.18;
    if (age < 65) return 0.28;
    return 0.38;
  }

  /// Sağlığın yıllık düşüş ihtimali (bakım öncesi ham değer).
  static double prototypeOnlyHealthChance(int age) {
    if (age < prototypeOnlyHealthFromAge) return 0;
    if (age < 55) return 0.22;
    if (age < 70) return 0.34;
    return 0.46;
  }

  /// Zekânın yıllık düşüş ihtimali (bakım öncesi ham değer).
  ///
  /// Bilerek küçük: zekâ yaşla çökmez, biraz aşınır.
  static double prototypeOnlyIntelligenceChance(int age) {
    if (age < prototypeOnlyIntelligenceFromAge) return 0;
    if (age < 75) return 0.14;
    return 0.22;
  }

  /// Mutluluğun yıllık düşüş ihtimali.
  ///
  /// Yaşın kendisi değil, **yaşla gelen yıpranma** düşürür: sağlığı iyi
  /// olan yaşlı karakterin mutluluğu belirgin biçimde daha az erir.
  static double prototypeOnlyHappinessChance(int age, int health) {
    if (age < prototypeOnlyHappinessFromAge) return 0;
    final double taban = age < 80 ? 0.16 : 0.24;
    if (health >= 70) return taban * 0.5;
    if (health < 40) return taban * 1.6;
    return taban;
  }

  /// Bir yılın bütün sürüklenmesini hesaplar.
  ///
  /// Değerler **birlikte** hesaplanır ki tek bir yılda üst üste binen
  /// kayıplar ölçülebilsin ve tek bir bildirimde anlatılabilsin.
  static StatDrift yearlyDrift({
    required int age,
    required Stats stats,
    required UpkeepStatus upkeep,
    required Random rng,
  }) {
    final List<String> notlar = <String>[];

    // --- Görünüş: mevcut eğri + bakım etkisi ----------------------------
    int gorunus = 0;
    if (age >= prototypeOnlyAppearanceFromAge &&
        stats.appearance > prototypeOnlyAppearanceFloor) {
      final double saglikEtkisi = ((50 - stats.health) / 100) * 0.3;
      final double sans = ((Aging.prototypeOnlyChance(age) + saglikEtkisi) *
              upkeepFactor(upkeep.yearsSinceGrooming, age))
          .clamp(0.0, 0.92);
      if (rng.chance(sans)) {
        final int dusus =
            rng.chance(Aging.prototypeOnlyDoubleChance(age)) ? 2 : 1;
        gorunus = -_kalan(stats.appearance, dusus, prototypeOnlyAppearanceFloor);
      }
    }

    // --- Karizma: spor ve bakım birlikte korur --------------------------
    int karizma = 0;
    if (age >= prototypeOnlyCharismaFromAge &&
        stats.charisma > prototypeOnlyCharismaFloor) {
      // Spor daha belirleyici, bakım destekleyici.
      final double carpan = upkeepFactor(upkeep.yearsSinceSport, age) * 0.7 +
          upkeepFactor(upkeep.yearsSinceGrooming, age) * 0.3;
      final double sans =
          (prototypeOnlyCharismaChance(age) * carpan).clamp(0.0, 0.85);
      if (rng.chance(sans)) {
        karizma = -_kalan(stats.charisma, 1, prototypeOnlyCharismaFloor);
      }
    }

    // --- Sağlık: sporun asıl karşılığı ----------------------------------
    int saglik = 0;
    if (age >= prototypeOnlyHealthFromAge &&
        stats.health > prototypeOnlyHealthFloor) {
      final double sans = (prototypeOnlyHealthChance(age) *
              upkeepFactor(upkeep.yearsSinceSport, age))
          .clamp(0.0, 0.85);
      if (rng.chance(sans)) {
        saglik = -_kalan(stats.health, 1, prototypeOnlyHealthFloor);
      }
    }

    // --- Zekâ: okumak ve kurs korur -------------------------------------
    int zeka = 0;
    if (age >= prototypeOnlyIntelligenceFromAge &&
        stats.intelligence > prototypeOnlyIntelligenceFloor) {
      final double sans = (prototypeOnlyIntelligenceChance(age) *
              upkeepFactor(upkeep.yearsSinceLearning, age))
          .clamp(0.0, 0.85);
      if (rng.chance(sans)) {
        zeka = -_kalan(stats.intelligence, 1, prototypeOnlyIntelligenceFloor);
      }
    }

    // --- Mutluluk: sağlığa bağlı, hafif ---------------------------------
    int mutluluk = 0;
    if (age >= prototypeOnlyHappinessFromAge &&
        stats.happiness > prototypeOnlyHappinessFloor) {
      if (rng.chance(prototypeOnlyHappinessChance(age, stats.health))) {
        mutluluk = -_kalan(stats.happiness, 1, prototypeOnlyHappinessFloor);
      }
    }

    // --- Anlatım ---------------------------------------------------------
    // Her yıl satır yazılmaz; yalnızca oyuncunun anlamlı bulacağı kadarı.
    if (gorunus <= -2) {
      notlar.add('Aynada bu yıl birkaç yeni çizgi gördün.');
    }
    final bool bakimsiz = age >= prototypeOnlyUpkeepFromAge &&
        (upkeep.yearsSinceGrooming == null ||
            upkeep.yearsSinceGrooming! >= prototypeOnlyNeglectYears);
    if (bakimsiz && (gorunus < 0 || karizma < 0)) {
      notlar.add('Uzun zamandır kendine bakmıyorsun; belli oluyor.');
    }
    final bool sporsuz = age >= prototypeOnlyUpkeepFromAge &&
        (upkeep.yearsSinceSport == null ||
            upkeep.yearsSinceSport! >= prototypeOnlyNeglectYears);
    if (sporsuz && saglik < 0) {
      notlar.add('Yıllardır hareketsizsin; nefesin eskisi gibi değil.');
    }
    if (zeka < 0) {
      notlar.add('Bir şeyleri eskisi kadar çabuk toparlayamıyorsun.');
    }

    return StatDrift(
      appearance: gorunus,
      charisma: karizma,
      health: saglik,
      intelligence: zeka,
      happiness: mutluluk,
      notes: List<String>.unmodifiable(notlar),
    );
  }

  /// Tabanı aşmayacak gerçek düşüş miktarı.
  static int _kalan(int deger, int istenen, int taban) {
    final int mumkun = deger - taban;
    if (mumkun <= 0) return 0;
    return istenen < mumkun ? istenen : mumkun;
  }
}
