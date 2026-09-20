import 'dart:math';

import '../models/person.dart';
import '../models/relation.dart';

/// Ölüm ihtimalleri ve ölüm metinleri.
///
/// Amaç, hayatın sonlu olduğunu hissettirmek; her yıl birinin ölmesi değil.
/// Küçük yaşlarda ölüm çok seyrektir. Ölüm gerekçeleri kısadır ve ayrıntılı
/// ya da rahatsız edici biçimde anlatılmaz.
///
/// Bütün sayılar `prototypeOnly`'dir (`docs/DESIGN_REVIEW_QUEUE.md`, Q-058).
abstract final class Mortality {
  /// prototypeOnly: yaşa göre yıllık ölüm ihtimali.
  ///
  /// Eğri kabaca gerçek hayattaki eğilimi izler: çocuklukta çok düşük,
  /// orta yaşta yavaş yükselen, ileri yaşta belirgin artan.
  static double prototypeOnlyYearlyChance(int age, {int? health}) {
    double temel;
    if (age < 1) {
      temel = 0.004;
    } else if (age < 15) {
      temel = 0.0004;
    } else if (age < 40) {
      temel = 0.0012;
    } else if (age < 55) {
      temel = 0.004;
    } else if (age < 65) {
      temel = 0.011;
    } else if (age < 75) {
      temel = 0.028;
    } else if (age < 85) {
      temel = 0.075;
    } else if (age < 95) {
      temel = 0.17;
    } else if (age < 105) {
      temel = 0.32;
    } else {
      temel = 0.55;
    }

    // Sağlık yalnızca oyuncuda ölçülür; NPC'lerde sağlık değeri yoktur ve
    // uydurulmaz.
    if (health != null) {
      // 50 sağlık nötr; düşük sağlık riski en çok iki katına çıkarır.
      final double carpan = (1.5 - health / 100).clamp(0.5, 2.0);
      temel *= carpan;
    }
    return temel.clamp(0.0, 0.95);
  }

  /// Bu yıl bu kişi vefat eder mi?
  static bool diesThisYear(int age, Random rng, {int? health}) =>
      rng.nextDouble() < prototypeOnlyYearlyChance(age, health: health);

  /// Yaşa uygun, kısa ölüm gerekçesi.
  ///
  /// Ayrıntılı ya da rahatsız edici tasvir kullanılmaz.
  static String causeFor(int age, Random rng) {
    final List<String> secenekler;
    if (age < 40) {
      secenekler = <String>[
        'beklenmedik bir rahatsızlık',
        'ani bir sağlık sorunu',
      ];
    } else if (age < 70) {
      secenekler = <String>[
        'uzun süren bir hastalık',
        'sağlık sorunları',
      ];
    } else {
      secenekler = <String>[
        'yaşlılığa bağlı nedenler',
        'uykusunda, sakin bir şekilde',
        'uzun bir ömrün ardından',
      ];
    }
    return secenekler[rng.nextInt(secenekler.length)];
  }

  /// Kaybın oyuncunun mutluluğuna etkisi (eksi değer).
  ///
  /// Yakınlık derecesine ve bağ puanına göre değişir; uzak bir tanıdığın
  /// kaybı aynı ağırlıkta değildir.
  static int prototypeOnlyHappinessLoss(Person person) {
    final int temel;
    switch (person.relation) {
      case RelationType.anne:
      case RelationType.baba:
        temel = 22;
      case RelationType.kardes:
        temel = 16;
      case RelationType.anneanne:
      case RelationType.babaanne:
      case RelationType.anneTarafiDede:
      case RelationType.babaTarafiDede:
        temel = 10;
      case RelationType.sevgili:
        temel = 18;
      case RelationType.arkadas:
        temel = 8;
      default:
        temel = 4;
    }
    // Bağ puanı yüksekse kayıp daha ağır hissedilir.
    final double bagCarpani = 0.6 + (person.bond / 100) * 0.8;
    return (temel * bagCarpani).round().clamp(1, 30);
  }
}
