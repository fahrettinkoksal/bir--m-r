import 'dart:math';

import '../models/person.dart';
import '../models/person_development.dart';
import '../models/stats.dart';
import 'random_util.dart';

/// Doğumda **özellik aktarımı** (D-046).
///
/// Biyolojik çocuğun başlangıç değerleri ebeveynlerin değerlerinden kısmen
/// etkilenir; bu kesin ve değişmez bir kader değildir:
/// - İki ebeveynin zekâsı düşükse çocuk **genel olarak** daha düşük
///   değerlere eğilim gösterir, ama daha yüksek doğma ihtimali durur.
/// - Yüksek özellikli ebeveynlerin çocuğu da mutlaka yüksek doğmaz.
///
/// Bu, gerçek dünyaya ilişkin bir genetik iddia değil, oyunun
/// **basitleştirilmiş karakter üretim mekaniğidir**. Değerler doğumda
/// **bir kez** çizilir ve kaydedilir; oyun kapatılıp açılınca veya kuşak
/// değişince yeniden rastgele belirlenmez. Sonradan eğitim, spor, kitap,
/// sağlık olayları ve aile etkileşimleriyle değişebilir.
///
/// Bütün ağırlıklar ve aralıklar `prototypeOnly`'dir (Q-070).
abstract final class TraitInheritance {
  /// prototypeOnly: karışımda ebeveyn ortalamasının ağırlığı.
  static const double prototypeOnlyParentWeight = 0.6;

  /// prototypeOnly: ebeveyn bilgisinin çekildiği nötr orta değer.
  static const int prototypeOnlyNeutral = 55;

  /// prototypeOnly: karışımın üstüne binen rastgele sapma (± bu kadar).
  static const int prototypeOnlySpread = 18;

  /// prototypeOnly: tek ebeveyn biliniyorsa sapma bu kadar genişler.
  static const int prototypeOnlySingleParentExtraSpread = 5;

  /// prototypeOnly: başlangıç değerlerinin alt ve üst sınırı.
  ///
  /// Uçlara sabitlenmiş bir çocuk üretilmez; gelişim için yer bırakılır.
  static const int prototypeOnlyMin = 10;
  static const int prototypeOnlyMax = 92;

  /// prototypeOnly: hiçbir ebeveyn bilgisi yokken kullanılan aralık.
  static const int prototypeOnlyUnknownMin = 25;
  static const int prototypeOnlyUnknownMax = 85;

  /// prototypeOnly: yeni doğanın mutluluğu (aktarılmaz).
  ///
  /// Mutluluk anlık bir ruh hâlidir; ebeveynden devralınması ayrı bir
  /// tasarım sorusudur (Q-070).
  static const int prototypeOnlyNewbornHappinessMin = 55;
  static const int prototypeOnlyNewbornHappinessMax = 85;

  /// Tek bir özelliğin doğum değeri.
  ///
  /// [first] ve [second] bilinen ebeveyn değerleridir; ikisi de yoksa
  /// **uydurma bir ebeveyn üretilmez**, nötr aralıktan çizilir.
  static int blend(int? first, int? second, Random rng) {
    final List<int> bilinen = <int>[
      if (first != null) first,
      if (second != null) second,
    ];
    if (bilinen.isEmpty) {
      return rng.between(prototypeOnlyUnknownMin, prototypeOnlyUnknownMax);
    }

    final double ortalama =
        bilinen.reduce((int a, int b) => a + b) / bilinen.length;
    final double taban = ortalama * prototypeOnlyParentWeight +
        prototypeOnlyNeutral * (1 - prototypeOnlyParentWeight);
    final int sapma = prototypeOnlySpread +
        (bilinen.length == 1 ? prototypeOnlySingleParentExtraSpread : 0);

    final int deger = taban.round() + rng.between(-sapma, sapma);
    return deger.clamp(prototypeOnlyMin, prototypeOnlyMax);
  }

  /// Yeni doğanın başlangıç değerleri.
  ///
  /// Zekâ, görünüş, sağlık ve karizma ebeveynlerden **kısmen** etkilenir;
  /// mutluluk aktarılmaz.
  static Stats newbornStats({
    required Random rng,
    Stats? first,
    Stats? second,
  }) {
    return Stats(
      appearance: blend(first?.appearance, second?.appearance, rng),
      happiness: rng.between(
        prototypeOnlyNewbornHappinessMin,
        prototypeOnlyNewbornHappinessMax,
      ),
      health: blend(first?.health, second?.health, rng),
      intelligence: blend(first?.intelligence, second?.intelligence, rng),
      charisma: blend(first?.charisma, second?.charisma, rng),
    );
  }

  /// Bir kişinin bilinen özellikleri; kaydı yoksa `null`.
  ///
  /// **Olmayan veri uydurulmaz**: kaydı olmayan ebeveyn karışıma girmez.
  static Stats? statsOf(Person? person) => person?.development?.stats;

  /// Çocuğun diğer ebeveyninin özellik kaydını **bir kez** oluşturur.
  ///
  /// Kişi kaydı zaten varsa dokunulmaz. Üretilen değerler kalıcı olarak
  /// saklanır; yeniden çizilmez (D-046).
  static Person ensureTraits(Person person, Random rng) {
    if (person.development != null) return person;
    return person.copyWith(
      development: PersonDevelopment(
        stats: Stats(
          appearance: rng.between(
            prototypeOnlyUnknownMin,
            prototypeOnlyUnknownMax,
          ),
          happiness: rng.between(45, 85),
          health: rng.between(40, 90),
          intelligence: rng.between(
            prototypeOnlyUnknownMin,
            prototypeOnlyUnknownMax,
          ),
          charisma: rng.between(
            prototypeOnlyUnknownMin,
            prototypeOnlyUnknownMax,
          ),
        ),
      ),
    );
  }
}
