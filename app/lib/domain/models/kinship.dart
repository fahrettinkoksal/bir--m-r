/// Aile bağlarının **tek doğru yeri** (Paket AO, §14, §16, §17).
///
/// Paket AO öncesinde akrabalık iki ayrı şeyden tahmin ediliyordu:
/// `RelationType.kanBagi` ve bağın adı. İkisi de Aile V2 için yetersiz:
///
/// * `kanBagi` **kalıtım** sorusunu cevaplıyor ("bu kişi biyolojik
///   akrabam mı?"). Üvey kardeşin kan bağı yoktur — ama onunla romantik
///   ilişki kurulması oyunda kabul edilemez. Yani romantik yasak,
///   kalıtımla aynı soru değildir.
/// * Bağın adı ("kardes") üvey ile yarım kardeşi ayırt edemez.
///
/// Bu dosya üç soruyu birbirinden ayırır:
///
/// 1. [isBloodRelative] — kalıtım ve biyolojik akrabalık.
/// 2. [isRomanceForbidden] — romantik havuza **asla** girmeyecek kişiler.
/// 3. [areSiblings] — iki kişi kardeş mi? (kayıtlı soy üzerinden)
library;

import 'person.dart';
import 'relation.dart';

abstract final class Kinship {
  /// Bu bağ **biyolojik** akrabalık mı?
  ///
  /// Miras ve kalıtım kuralları bunu kullanır (§17). Yarım kardeş
  /// biyolojik akrabadır; üvey kardeş, üvey çocuk, üvey ebeveyn, eş ve
  /// kayın aile değildir.
  static bool isBloodRelative(RelationType relation) => relation.kanBagi;

  /// Bu kişi romantik havuza girebilir mi? `true` ise **giremez**.
  ///
  /// §16'nın kuralı: yalnızca kan bağına bakmak yetmez. Üvey kardeşle
  /// aramızda biyolojik bağ olmayabilir ama aynı evde büyümüş insanları
  /// flört havuzuna atmak oyunun kabul edebileceği bir şey değil. Aynısı
  /// üvey ebeveyn, üvey çocuk ve kayın aile için de geçerli.
  ///
  /// Liste **kapsayıcı** yazıldı: yeni bir aile bağı eklenip buraya
  /// yazılmayı unutursa, `kanBagi` üzerinden gelen koruma yine devrede
  /// kalır.
  static bool isRomanceForbidden(RelationType relation) {
    // Biyolojik akrabanın tamamı (anne, baba, kardeş, yarım kardeş,
    // çocuk, torun, yeğen, teyze/dayı/hala/amca, dede/nine).
    if (relation.kanBagi) return true;
    switch (relation) {
      // Kan bağı olmayan ama aile olan bağlar.
      case RelationType.uveyAnne:
      case RelationType.uveyBaba:
      case RelationType.uveyKardes:
      case RelationType.uveyCocuk:
      case RelationType.kayinvalide:
      case RelationType.kayinpeder:
        return true;
      // Eş ve eski eş zaten romantik bağın kendisi; "yeni ilişki
      // havuzuna" alınmazlar ama bu bir akrabalık yasağı değildir, o
      // yüzden burada `false`. Romantik motor onları ayrıca eler.
      case RelationType.es:
      case RelationType.eskiEs:
      case RelationType.sevgili:
      case RelationType.eskiSevgili:
      case RelationType.flort:
      case RelationType.arkadas:
      case RelationType.isArkadasi:
      case RelationType.sinifArkadasi:
      case RelationType.ogretmen:
      case RelationType.kogusArkadasi:
      case RelationType.unlu:
        return false;
      // kanBagi true döndüğü için buraya düşmezler; derleyici bütün
      // dalları istediği için yazıldı.
      case RelationType.anne:
      case RelationType.baba:
      case RelationType.kardes:
      case RelationType.yariKardes:
      case RelationType.cocuk:
      case RelationType.torun:
      case RelationType.yegen:
      case RelationType.anneanne:
      case RelationType.babaanne:
      case RelationType.anneTarafiDede:
      case RelationType.babaTarafiDede:
      case RelationType.teyze:
      case RelationType.dayi:
      case RelationType.hala:
      case RelationType.amca:
        return true;
    }
  }

  /// [person] romantik havuza girebilir mi? `true` ise **giremez**.
  ///
  /// Bağ türüne ek olarak kayıtlı soya da bakar: bağ türü ne olursa olsun
  /// oyuncuyla bir biyolojik ebeveyni paylaşan kişi kardeştir.
  static bool isRomanceForbiddenFor(
    Person person, {
    required String playerId,
    String? playerMotherId,
    String? playerFatherId,
  }) {
    if (isRomanceForbidden(person.relation)) return true;
    // Oyuncunun çocuğu: kayıtta ebeveyn olarak oyuncunun kimliği yazar.
    if (person.motherId == playerId || person.fatherId == playerId) {
      return true;
    }
    // Oyuncuyla ortak biyolojik ebeveyn → kardeş (üvey ya da yarım
    // etiketi ne olursa olsun).
    for (final String? id in <String?>[playerMotherId, playerFatherId]) {
      if (id == null) continue;
      if (person.motherId == id || person.fatherId == id) return true;
    }
    return false;
  }

  /// [a] ile [b] kardeş mi? (En az bir biyolojik ebeveyn ortak.)
  ///
  /// Bağ adına değil **kayda** bakar; üvey kardeş burada `false` döner.
  static bool areSiblings(Person a, Person b) => a.sharesParentWith(b);
}
