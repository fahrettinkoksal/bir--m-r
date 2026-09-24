/// İlgisizlikten zayıflayan bağlar (Paket 24).
///
/// **Neden var:** Bağlar yalnızca **yükseliyordu**. Bir kişiyle bir kez
/// güzel bir an yaşandıktan sonra oyuncu onu ömrünün geri kalanında hiç
/// aramasa bile yakınlık olduğu yerde duruyordu. Bu yüzden İlişkiler
/// ekranındaki listeyi düzenli ziyaret etmenin bir karşılığı yoktu:
/// bir kez yükselen bağ bedava kalıcıydı.
///
/// Artık uzun süre görüşülmeyen kişiyle yakınlık **yavaşça** düşer.
/// Kurallar bilerek ihtiyatlı:
///
/// * **Yalnızca erişilebilir kişiler** zayıflar. Yıllar önceki ilkokul
///   öğretmeni ya da başka şehirdeki eski bir sınıf arkadaşı zaten
///   aranamıyor; oyuncuyu elinden gelmeyen bir şey için cezalandırmayız.
/// * **Aynı evde yaşayan yakınlar zayıflamaz** — bir istisnayla.
///   Her gün görülen anneyle "görüşmemek" diye bir şey yok. Ama
///   **eş ve sevgili** için bu doğru değildi: Faho yıllarca hiç
///   ilgilenmediği eşle yakınlığının hâlâ tam olduğunu bildirdi.
///   Aynı evde yaşamak ilgi göstermek değildir; evlilik ilgisizlikten
///   soğur. Bu yüzden eş ve sevgili, hanede olsa bile **daha yavaş ve
///   daha yüksek bir tabanla** zayıflar.
/// * **Kan bağı daha yavaş zayıflar.** Anne annedir; uzaklaşır ama
///   yabancıya dönmez. Bu yüzden kan bağında bir **taban** vardır ve
///   yakınlık onun altına ilgisizlikten düşmez.
/// * Sayıların hiçbiri kesin oyun kuralı değildir (`prototypeOnly`,
///   Q-092).
library;

import '../models/game_state.dart';
import '../models/person.dart';
import '../models/relation.dart';

/// Bir yılın ihmal etkisi.
class BondDecayResult {
  const BondDecayResult({
    required this.people,
    required this.weakened,
    required this.lastInteractionAge,
  });

  final List<Person> people;

  /// Bu yıl yakınlığı düşen kişilerin kimlikleri.
  final List<String> weakened;

  /// Güncellenmiş son temas kayıtları.
  ///
  /// Hiç teması olmayan kişiler için **sayaç başlatılır** (bkz.
  /// [BondDecay.applyYear]); geriye dönük geçmiş uydurulmaz.
  final Map<String, int> lastInteractionAge;

  bool get changed => weakened.isNotEmpty;
}

abstract final class BondDecay {
  /// İhmal sayılmadan önce geçmesi gereken yıl.
  ///
  /// Bir yıl görüşmemek ihmal değildir; hayat böyle.
  static const int prototypeOnlyGraceYears = 3;

  /// Erişilebilir ama görüşülmeyen kişide yıllık kayıp.
  static const int prototypeOnlyYearlyLoss = 3;

  /// Kan bağında yıllık kayıp (daha yavaş).
  static const int prototypeOnlyBloodLoss = 2;

  /// Kan bağında ilgisizliğin indirebileceği **en düşük** yakınlık.
  ///
  /// Anne annedir: uzaklaşır ama yabancıya dönmez. Olay veya seçim
  /// kaynaklı düşüşler bu tabana takılmaz; yalnızca ilgisizlik takılır.
  static const int prototypeOnlyBloodFloor = 20;

  /// Kan bağı dışında ilgisizliğin indirebileceği en düşük yakınlık.
  static const int prototypeOnlyFloor = 0;

  /// Hanedeki eş/sevgilinin ihmal sayılması için geçmesi gereken yıl.
  ///
  /// Aynı evde yaşandığı için hoşgörü daha uzun; ama sonsuz değil.
  static const int prototypeOnlyPartnerGraceYears = 4;

  /// Hanedeki eş/sevgilide yıllık kayıp.
  ///
  /// Kan bağından da yavaş: birlikte yaşamak bir şeydir. Ama on yıl hiç
  /// ilgilenmemek yakınlığı tam bırakmaz.
  static const int prototypeOnlyPartnerLoss = 2;

  /// Hanedeki eş/sevgilide ilgisizliğin indirebileceği en düşük yakınlık.
  ///
  /// Evlilik soğur ama yabancılaşmaz; bu taban onu korur.
  static const int prototypeOnlyPartnerFloor = 35;

  /// Bu kişi hanede yaşayan eş ya da sevgili mi?
  static bool isHouseholdPartner(Person person) =>
      person.inPlayerHousehold &&
      (person.relation == RelationType.es ||
          person.relation == RelationType.sevgili);

  /// Bu kişi ilgisizlikten zayıflayabilir mi?
  static bool decays(GameState state, Person person) {
    if (!person.isAlive) return false;
    // Hanedeki eş ve sevgili istisnadır: aynı evde yaşamak ilgi
    // göstermek değildir (Faho'nun bildirdiği durum).
    if (isHouseholdPartner(person)) return true;
    // Her gün görülen diğer yakınlarla "görüşmemek" diye bir şey yok.
    if (person.inPlayerHousehold) return false;
    // Aranamayan kişi için oyuncu suçlanmaz.
    if (!state.isReachable(person)) return false;
    return true;
  }

  /// Bu kişinin ilgisizlik tabanı.
  static int floorFor(Person person) {
    if (isHouseholdPartner(person)) return prototypeOnlyPartnerFloor;
    return person.relation.kanBagi
        ? prototypeOnlyBloodFloor
        : prototypeOnlyFloor;
  }

  /// Bu kişinin yıllık kaybı.
  static int lossFor(Person person) {
    if (isHouseholdPartner(person)) return prototypeOnlyPartnerLoss;
    return person.relation.kanBagi
        ? prototypeOnlyBloodLoss
        : prototypeOnlyYearlyLoss;
  }

  /// Bu kişide ihmal sayılmadan önce geçmesi gereken yıl.
  static int graceFor(Person person) => isHouseholdPartner(person)
      ? prototypeOnlyPartnerGraceYears
      : prototypeOnlyGraceYears;

  /// Kaç yıldır görüşülmediğini döndürür.
  ///
  /// Hiç temas kurulmamışsa `null` döner: geriye dönük bir geçmiş
  /// uydurulmaz. Sayaç, kişi haneden ayrıldığı (ya da oyuncu evden
  /// çıktığı) ilk yıl [applyYear] tarafından başlatılır.
  static int? yearsSinceContact(GameState state, Person person) {
    final int? son = state.lastInteractionAge[person.id];
    if (son == null) return null;
    final int fark = state.player.age - son;
    return fark < 0 ? 0 : fark;
  }

  /// Bir yıllık ilgisizliği uygular.
  ///
  /// İki iş yapar:
  ///
  /// 1. **Sayacı başlatır.** Artık aynı evde yaşamayan ama hâlâ
  ///    erişilebilen bir kişinin hiç temas kaydı yoksa, o yılın yaşı son
  ///    temas sayılır. Bu uydurma bir geçmiş değildir: aynı evde
  ///    yaşanırken zaten her gün görülüyordu, sayaç ayrılıkla başlar.
  ///    Böylece evden çıkan oyuncunun annesiyle bağı da, hiç
  ///    aranmadığında zamanla zayıflar.
  /// 2. **Yakınlığı düşürür.** Hoşgörü yılları geçtiyse kayıp uygulanır.
  static BondDecayResult applyYear(GameState state) {
    final List<String> zayiflayan = <String>[];
    final Map<String, int> temas =
        Map<String, int>.from(state.lastInteractionAge);

    final List<Person> guncel = state.people.map((Person p) {
      // Keyif her yıl kendi nötrüne doğru bir adım kayar (D-074). Böylece
      // keyif **birikimli bir puan değil, o anki hâl** olur: güzel bir
      // yılın etkisi zamanla söner, kötü bir yıl kalıcı ceza olmaz.
      p = _keyifKay(p);
      if (!decays(state, p)) return p;
      if (!temas.containsKey(p.id)) {
        // Sayaç bu yıl başlıyor; bu yıl kayıp yok.
        temas[p.id] = state.player.age;
        return p;
      }
      final int gecen = (state.player.age - temas[p.id]!).clamp(0, 200);
      if (gecen <= graceFor(p)) return p;

      final int taban = floorFor(p);
      if (p.bond <= taban) return p;
      final int yeni = (p.bond - lossFor(p)).clamp(taban, 100);
      if (yeni == p.bond) return p;
      zayiflayan.add(p.id);
      return p.copyWith(bond: yeni);
    }).toList(growable: false);

    return BondDecayResult(
      people: List<Person>.unmodifiable(guncel),
      weakened: List<String>.unmodifiable(zayiflayan),
      lastInteractionAge: Map<String, int>.unmodifiable(temas),
    );
  }

  /// prototypeOnly: keyfin her yıl nötre doğru kaydığı adım.
  static const int prototypeOnlyHappinessDrift = 1;

  /// Kişinin keyfini bir adım nötre yaklaştırır.
  static Person _keyifKay(Person p) {
    if (!p.isAlive) return p;
    const int notr = Person.prototypeOnlyDefaultHappiness;
    if (p.happiness == notr) return p;
    final int yon = p.happiness > notr ? -1 : 1;
    return p.copyWith(
      happiness: p.happiness + yon * prototypeOnlyHappinessDrift,
    );
  }

  /// Günlüğe yazılacak satır; yazılacak bir şey yoksa `null`.
  ///
  /// Her yıl tek tek kişi adı sayılmaz — günlük dolup taşar. Yalnızca
  /// **ilk kez** belirgin biçimde uzaklaşıldığında tek bir satır yazılır.
  static String? logLineFor(GameState before, BondDecayResult result) {
    if (!result.changed) return null;
    // Yalnızca bu yıl tabana ya da belirgin bir düşüklüğe inen kişiler
    // anlatılmaya değer.
    final List<Person> belirgin = <Person>[];
    for (final String id in result.weakened) {
      final Person? onceki = before.personById(id);
      final Person? sonraki =
          result.people.where((Person p) => p.id == id).firstOrNull;
      if (onceki == null || sonraki == null) continue;
      if (onceki.bond > prototypeOnlyNoticeBond &&
          sonraki.bond <= prototypeOnlyNoticeBond) {
        belirgin.add(sonraki);
      }
    }
    if (belirgin.isEmpty) return null;
    if (belirgin.length == 1) {
      final Person k = belirgin.single;
      return '${k.fullName} ile araya mesafe girdi; uzun zamandır '
          'görüşmüyorsunuz.';
    }
    return 'Uzun zamandır görüşmediğin birkaç kişiyle araya mesafe girdi.';
  }

  /// Günlüğe yazmaya değer sayılan eşik.
  static const int prototypeOnlyNoticeBond = 30;
}
