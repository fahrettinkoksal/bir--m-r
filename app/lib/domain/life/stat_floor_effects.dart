import '../models/game_state.dart';

/// Mutluluk, karizma, görünüş ve zekânın **çok düşük** seviyelerindeki
/// gameplay sonuçları (Paket AQ).
///
/// **Neden var:** sınır değerinin bir anlamı olmalı. Sağlık 0 için
/// `CriticalHealth` kuruldu; öteki değerlerde ise tablo karışıktı.
/// Denetlendi:
///
/// | değer | zaten tüketen sistemler | boşluk |
/// |---|---|---|
/// | karizma | meslek koşulu (`minCharisma`), Finger eşleşmesi, terfi talebi, sosyal medya, askerlik | **mülakatın kendisi** karizmaya hiç bakmıyordu |
/// | zekâ | okul ortalaması, meslek koşulu, terfi talebi, kurslar, sınavlar | boşluk yok |
/// | görünüş | meslek koşulu (mankenlik 80), Finger eşleşmesi, bakım sistemi | boşluk yok |
/// | mutluluk | hayat değerlendirmesi, sağlık raporu | **hiçbir sistem girdi olarak kullanmıyordu** |
///
/// Bu yüzden burada **yalnızca iki boşluk** kapatılıyor: mutluluğun
/// gerçek bir sonucu ve mülakatta karizmanın rolü. Zaten statı kullanan
/// sistemlere ikinci bir ceza eklenmedi.
///
/// **Kurallar:**
/// - Hiçbir değerin 0 olması ölüm ya da kendine zarar üretmez.
/// - Negatif sarmal yok: düşük mutluluk mutluluğu daha da düşürmez.
///   Tersine, en alt bantta eğlencenin getirisi **artar** — insan dipten
///   çıkarken küçük şeylere daha çok sevinir.
/// - Çapraz saçmalık yok: görünüş düşük diye kredi reddedilmez, karizma
///   düşük diye anne kayıtlardan silinmez.
///
/// Bütün sayılar `prototypeOnly`'dir (Q-189).
enum StatLowBand {
  /// 26-100: olağan.
  normal,

  /// 11-25: düşük.
  dusuk,

  /// 0-10: çok düşük.
  cokDusuk,
}

abstract final class StatFloorEffects {
  /// prototypeOnly: "çok düşük" bandın üst sınırı.
  static const int prototypeOnlyVeryLowUpTo = 10;

  /// prototypeOnly: "düşük" bandın üst sınırı.
  static const int prototypeOnlyLowUpTo = 25;

  static StatLowBand bandOf(int value) {
    if (value <= prototypeOnlyVeryLowUpTo) return StatLowBand.cokDusuk;
    if (value <= prototypeOnlyLowUpTo) return StatLowBand.dusuk;
    return StatLowBand.normal;
  }

  // -------------------------------------------------------------------
  // Mutluluk
  // -------------------------------------------------------------------

  /// prototypeOnly: düşük mutluluğun iş/okul performansına çarpanı.
  ///
  /// Mutsuz insan işini de okulunu da aynı istekle yapmıyor. Çarpan
  /// bilerek ölçülü: mutluluk 0 olan karakter işini kaybetmiyor, terfi
  /// talebi ve not ortalaması biraz daha zor yürüyor.
  static const double prototypeOnlyLowMotivation = 0.85;
  static const double prototypeOnlyVeryLowMotivation = 0.70;

  /// Mutluluğun iş ve okul performansına çarpanı.
  static double motivationFactor(int happiness) {
    switch (bandOf(happiness)) {
      case StatLowBand.cokDusuk:
        return prototypeOnlyVeryLowMotivation;
      case StatLowBand.dusuk:
        return prototypeOnlyLowMotivation;
      case StatLowBand.normal:
        return 1.0;
    }
  }

  /// prototypeOnly: en alt bantta eğlencenin fazladan getirisi.
  ///
  /// Sarmalın **karşı ağırlığı**: dipteki karakter çıkış yolunu daha
  /// kolay bulsun. Tek yönlü bir çöküş kurmamanın mekaniği bu.
  static const int prototypeOnlyVeryLowReliefBonus = 3;
  static const int prototypeOnlyLowReliefBonus = 1;

  /// Eğlence kaynaklı mutluluk kazancına eklenen pay.
  ///
  /// Yalnızca kazanç **pozitifse** eklenir; kayıpları büyütmez.
  static int reliefBonus({required int happiness, required int gain}) {
    if (gain <= 0) return 0;
    switch (bandOf(happiness)) {
      case StatLowBand.cokDusuk:
        return prototypeOnlyVeryLowReliefBonus;
      case StatLowBand.dusuk:
        return prototypeOnlyLowReliefBonus;
      case StatLowBand.normal:
        return 0;
    }
  }

  // -------------------------------------------------------------------
  // Karizma
  // -------------------------------------------------------------------

  /// prototypeOnly: çok düşük karizmanın mülakattaki ikinci şansa
  /// çarpanı.
  ///
  /// Mülakat sonucu bir bilgi sorusuna dayanıyor; karizma oraya hiç
  /// girmiyordu. Tek **mevcut** karar noktası, cevabı tutmayan adayın
  /// geçmişiyle kurtulma ihtimali (`CareerSynergyRules`). Karizma o
  /// ihtimali ölçeklendiriyor — yeni bir mülakat motoru kurulmadı ve
  /// doğru cevap veren aday hiçbir bantta reddedilmiyor.
  static const double prototypeOnlyVeryLowCharismaRescue = 0.35;
  static const double prototypeOnlyLowCharismaRescue = 0.7;

  /// Karizmanın mülakattaki ikinci şans çarpanı.
  static double interviewRescueFactor(int charisma) {
    switch (bandOf(charisma)) {
      case StatLowBand.cokDusuk:
        return prototypeOnlyVeryLowCharismaRescue;
      case StatLowBand.dusuk:
        return prototypeOnlyLowCharismaRescue;
      case StatLowBand.normal:
        return 1.0;
    }
  }

  // -------------------------------------------------------------------
  // Ekranda gösterilecek durum satırları
  // -------------------------------------------------------------------

  /// Oyuncuya gösterilecek, teknik terim içermeyen durum cümleleri.
  ///
  /// Yalnızca **gerçekten düşük** değerler için satır üretir; her değer
  /// için satır yazılmaz. Alakasız çapraz etki iddia edilmez: her satır
  /// yalnızca o değerin kendi alanından konuşur.
  static List<String> statusLines(GameState state) {
    final List<String> satirlar = <String>[];
    final int mutluluk = state.player.stats.happiness;
    final int karizma = state.player.stats.charisma;
    final int gorunus = state.player.stats.appearance;
    final int zeka = state.player.stats.intelligence;

    if (bandOf(mutluluk) != StatLowBand.normal) {
      satirlar.add(
        'Mutluluğun çok düşük; işe ve okula eskisi gibi asılamıyorsun. '
        'Hoşuna giden şeyler şu an sana daha çok iyi geliyor.',
      );
    }
    if (bandOf(karizma) != StatLowBand.normal) {
      satirlar.add(
        'Karizman çok düşük; kendini anlatman gereken yerlerde — '
        'mülakat, tanışma — zorlanıyorsun.',
      );
    }
    if (bandOf(gorunus) != StatLowBand.normal) {
      satirlar.add(
        'Dış görünüşün çok düşük; görünüşün sayıldığı işlerde ve yeni '
        'tanışmalarda bu önüne çıkıyor.',
      );
    }
    if (bandOf(zeka) != StatLowBand.normal) {
      satirlar.add(
        'Zekân çok düşük; okul, sınav ve nitelik isteyen işler şu an '
        'sana kapalı sayılır.',
      );
    }
    return satirlar;
  }
}
