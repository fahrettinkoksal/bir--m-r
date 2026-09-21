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
/// * **Aynı evde yaşayanlar zayıflamaz.** Her gün görülen biriyle
///   "görüşmemek" diye bir şey yok.
/// * **Kan bağı daha yavaş zayıflar.** Anne annedir; uzaklaşır ama
///   yabancıya dönmez. Bu yüzden kan bağında bir **taban** vardır ve
///   yakınlık onun altına ilgisizlikten düşmez.
/// * Sayıların hiçbiri kesin oyun kuralı değildir (`prototypeOnly`,
///   Q-092).
library;

import '../models/game_state.dart';
import '../models/person.dart';

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

  /// Bu kişi ilgisizlikten zayıflayabilir mi?
  static bool decays(GameState state, Person person) {
    if (!person.isAlive) return false;
    // Her gün görülen biriyle "görüşmemek" diye bir şey yok.
    if (person.inPlayerHousehold) return false;
    // Aranamayan kişi için oyuncu suçlanmaz.
    if (!state.isReachable(person)) return false;
    return true;
  }

  /// Bu kişinin ilgisizlik tabanı.
  static int floorFor(Person person) =>
      person.relation.kanBagi ? prototypeOnlyBloodFloor : prototypeOnlyFloor;

  /// Bu kişinin yıllık kaybı.
  static int lossFor(Person person) =>
      person.relation.kanBagi ? prototypeOnlyBloodLoss : prototypeOnlyYearlyLoss;

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
      if (!decays(state, p)) return p;
      if (!temas.containsKey(p.id)) {
        // Sayaç bu yıl başlıyor; bu yıl kayıp yok.
        temas[p.id] = state.player.age;
        return p;
      }
      final int gecen = (state.player.age - temas[p.id]!).clamp(0, 200);
      if (gecen <= prototypeOnlyGraceYears) return p;

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
