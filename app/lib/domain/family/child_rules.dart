/// Evde konulan kural (Paket BK/3).
///
/// "Kural Koy" eylemi çocuğa bir sınır çizer: ders saati, akşam eve
/// dönüş, ekran süresi. Bedeli de faydası da **gerçektir**:
///
/// * Çocuğun keyfi düşer ve yakınlık bir miktar geri gider — kural
///   sevilmez.
/// * Karşılığında okul sorununun çıkma ihtimali bir süre azalır
///   (`ChildSchoolIssue.chanceFor`). Yani kural bir **ihtimal**
///   kaydırır, sonucu dikte etmez — `ChildAdvice` ile aynı felsefe.
/// * Etki söner (üç yıl) ve tekrar konulabilir; ama aynı yıl üst üste
///   kural koymanın getirisi `FamilyInteractions`'ın azalan fayda
///   eğrisiyle erir.
///
/// Yeni bir kayıt alanı eklenmedi: kuralın yılı `lastInteractionAge`
/// içinde duruyor — `ChildAdvice` tavsiyenin yılını zaten orada
/// tutuyor.
///
/// Sayısal değerler `prototypeOnly`'dir (Q-203).
library;

import '../models/game_state.dart';
import '../models/person.dart';

abstract final class ChildRules {
  /// prototypeOnly: kuralın anlam kazandığı en küçük yaş.
  ///
  /// Okul sorunu da 7 yaşında başlıyor (`ChildSchoolIssue`); kural ondan
  /// önce konulacak bir şey değil.
  static const int prototypeOnlyMinAge = 7;

  /// prototypeOnly: kuralın sözünün geçtiği en büyük yaş.
  ///
  /// 18'inden sonra çocuk kendi kararını veriyor; ona kural koymak
  /// prototipte bir şey yapmaz, o yüzden kapı da açılmaz.
  static const int prototypeOnlyMaxAge = 17;

  /// prototypeOnly: etkinin tamamen söndüğü yıl sayısı.
  static const int prototypeOnlyFadeYears = 3;

  /// prototypeOnly: taze bir kuralın okul sorunu ihtimaline çarpanı.
  ///
  /// 0,5 = ihtimal yarıya iner. Sıfır değil: kural çocuğu garantiye
  /// almaz.
  static const double prototypeOnlyRelief = 0.5;

  /// prototypeOnly: bu yakınlığın altında kural dinlenmez.
  ///
  /// `ChildAdvice.prototypeOnlyDeafBond` ile aynı eşik: arası kopuk
  /// çocuk ne tavsiyeyi ne kuralı dinler.
  static const int prototypeOnlyDeafBond = 12;

  /// Kural kaydının anahtarı.
  static String ruleKey(String personId) => 'cocuk-kural:$personId';

  /// Bu çocuğa kural konulabilir mi; konulamıyorsa gerekçesi (D-095).
  static String? blockReason(GameState state, Person child) {
    if (child.age < prototypeOnlyMinAge) {
      return '${child.firstName} kural koyulacak yaşta değil.';
    }
    if (child.age > prototypeOnlyMaxAge) {
      return '${child.firstName} artık kendi kararlarını veriyor.';
    }
    if (child.development?.isStudent != true) {
      return '${child.firstName} okula gitmiyor; bu kuralın karşılığı '
          'olmaz.';
    }
    return null;
  }

  /// Kuralın bu yıl kaç yaşında konulduğu; konulmadıysa `null`.
  static int? setAtAge(GameState state, String personId) =>
      state.lastInteractionAge[ruleKey(personId)];

  /// Okul sorunu ihtimaline uygulanacak çarpan.
  ///
  /// Hiç kural konulmadıysa **tam olarak 1,0** döner: hiçbir hesap
  /// değişmez ve aynı tohum aynı hayatı verir.
  static double reliefFor(GameState state, Person child) {
    final int? son = setAtAge(state, child.id);
    if (son == null) return 1.0;
    final int gecenYil = state.player.age - son;
    if (gecenYil < 0 || gecenYil >= prototypeOnlyFadeYears) return 1.0;
    // Arası kopuk çocuk kuralı dinlemez.
    if (child.bond < prototypeOnlyDeafBond) return 1.0;

    // Yıl geçtikçe söner: taze kuralda tam indirim, son yılda neredeyse
    // hiç.
    final double sonmeOrani =
        (prototypeOnlyFadeYears - gecenYil) / prototypeOnlyFadeYears;
    final double indirim = (1 - prototypeOnlyRelief) * sonmeOrani;
    return (1 - indirim).clamp(prototypeOnlyRelief, 1.0);
  }

  /// Şu an etkili bir kural var mı? (ekranda yazmak için)
  static bool activeFor(GameState state, Person child) =>
      reliefFor(state, child) < 1.0;
}
