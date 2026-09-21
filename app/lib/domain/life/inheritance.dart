import '../../data/item_catalog.dart';
import '../models/game_state.dart';
import '../models/marriage.dart';
import '../models/owned_item.dart';
import '../models/person.dart';
import '../models/person_development.dart';
import '../models/relation.dart';
import '../models/wealth.dart';
import '../../text/turkish_text.dart';

/// Bir vefatın ardından oyuncuya düşen pay.
class InheritanceShare {
  const InheritanceShare({
    required this.money,
    required this.itemTypeIds,
    required this.heirCount,
  });

  /// Oyuncunun payına düşen nakit.
  final int money;

  /// Oyuncuya kalan eşya türleri.
  final List<String> itemTypeIds;

  /// Toplam mirasçı sayısı (oyuncu dâhil); 0 ise oyuncu mirasçı değildir.
  final int heirCount;

  bool get isEmpty => money == 0 && itemTypeIds.isEmpty;
}

/// **Oyun içi basitleştirilmiş** miras modeli.
///
/// Gerçek hukuk kuralları değildir ve öyle sunulmaz; ilk sürüm için
/// anlaşılır, genişletilebilir bir modeldir. Bütün oranlar ve tutarlar
/// `prototypeOnly`'dir (`docs/DESIGN_REVIEW_QUEUE.md`, Q-059).
///
/// Kurallar:
/// - Mirasçılar önce **eş ve çocuklar**, yoksa **anne-baba**, yoksa
///   **kardeşler** arasından belirlenir.
/// - Eş payı yalnızca **gerçek bir birliktelik kaydı** varsa uygulanır
///   (D-037): ayrı yaşayan veya boşanmış ebeveyn eş sayılmaz, sevgili de
///   hiçbir durumda eş sayılmaz.
/// - Eş varsa nakdin dörtte birini alır, kalanı çocuklara eşit bölünür.
/// - Eşya ve araçlar **bölünmez**: her biri tek bir mirasçıya gider.
/// - Aynı miras iki kez dağıtılmaz ([GameState.settledEstates]).
abstract final class Inheritance {
  /// prototypeOnly: ekonomik duruma göre geride kalan nakit (₺).
  static int prototypeOnlyEstateMoney(WealthTier? wealth) {
    switch (wealth) {
      case WealthTier.cokYoksul:
        return 0;
      case WealthTier.yoksul:
        return 25000;
      case WealthTier.ortaHalli:
        return 180000;
      case WealthTier.varlikli:
        return 900000;
      case WealthTier.cokVarlikli:
        return 3500000;
      case null:
        return 0;
    }
  }

  /// prototypeOnly: eşin nakitten aldığı pay.
  static const double prototypeOnlySpouseShare = 0.25;

  /// Vefat edenin mirasçısı olabilecek **hayattaki** kişiler.
  ///
  /// Oyuncu listede `null` kimlikle değil, [playerIsHeir] ile temsil edilir.
  static ({List<Person> others, bool playerIsHeir}) heirsFor(
    GameState state,
    Person deceased,
  ) {
    final List<Person> yasayanlar = state.people
        .where((Person p) => p.isAlive && p.id != deceased.id)
        .toList(growable: false);

    List<Person> ara(Set<RelationType> turler) => yasayanlar
        .where((Person p) => turler.contains(p.relation))
        .toList(growable: false);

    switch (deceased.relation) {
      // Anne veya babanın mirası: sağ kalan eş (diğer ebeveyn) ve çocuklar
      // (oyuncu ve kardeşleri).
      case RelationType.anne:
      case RelationType.baba:
        final List<Person> digerEbeveyn = ara(<RelationType>{
          deceased.relation == RelationType.anne
              ? RelationType.baba
              : RelationType.anne,
        });
        final List<Person> kardesler = ara(<RelationType>{RelationType.kardes});
        return (
          others: <Person>[...digerEbeveyn, ...kardesler],
          playerIsHeir: true,
        );

      // Kardeşin mirası: önce anne-baba, yoksa diğer kardeşler (ve oyuncu).
      case RelationType.kardes:
        final List<Person> ebeveynler =
            ara(<RelationType>{RelationType.anne, RelationType.baba});
        if (ebeveynler.isNotEmpty) {
          return (others: ebeveynler, playerIsHeir: false);
        }
        return (
          others: ara(<RelationType>{RelationType.kardes}),
          playerIsHeir: true,
        );

      // Büyükanne/büyükbabanın mirası: önce kendi çocukları (oyuncunun
      // ebeveyni), onlar hayatta değilse torunlar.
      case RelationType.anneanne:
      case RelationType.anneTarafiDede:
        final List<Person> anne = ara(<RelationType>{RelationType.anne});
        if (anne.isNotEmpty) return (others: anne, playerIsHeir: false);
        return (
          others: ara(<RelationType>{RelationType.kardes}),
          playerIsHeir: true,
        );
      case RelationType.babaanne:
      case RelationType.babaTarafiDede:
        final List<Person> baba = ara(<RelationType>{RelationType.baba});
        if (baba.isNotEmpty) return (others: baba, playerIsHeir: false);
        return (
          others: ara(<RelationType>{RelationType.kardes}),
          playerIsHeir: true,
        );

      // Eşin mirası: sağ kalan eş (oyuncu) ve çocuklar.
      case RelationType.es:
        return (
          others: ara(<RelationType>{RelationType.cocuk}),
          playerIsHeir: true,
        );

      // Çocuğun mirası: anne-baba, yani oyuncu ve (hayattaysa) eşi.
      case RelationType.cocuk:
        return (
          others: ara(<RelationType>{RelationType.es}),
          playerIsHeir: true,
        );

      // Diğer bağlarda (arkadaş, öğretmen, uzak akraba, **eski eş**)
      // miras yoktur: boşanmış eş mirasçı değildir (D-037).
      default:
        return (others: const <Person>[], playerIsHeir: false);
    }
  }

  /// Oyuncunun payını hesaplar.
  ///
  /// Hesap yalnızca vefat edenin **gerçekten sahip olduğu** varlıklara
  /// dayanır: nakit ekonomik durumundan, eşyalar [Person.estate]'ten gelir.
  static InheritanceShare shareFor(GameState state, Person deceased) {
    final ({List<Person> others, bool playerIsHeir}) mirascilar =
        heirsFor(state, deceased);
    if (!mirascilar.playerIsHeir) {
      return InheritanceShare(
        money: 0,
        itemTypeIds: const <String>[],
        heirCount: mirascilar.others.length,
      );
    }

    // Kendi hayatı izlenen kişilerde (oyuncunun çocukları, D-045) miras
    // **gerçekten biriktirdiği** paradan dağıtılır; ekonomik durumdan
    // tahmin edilen tutar yalnızca kaydı olmayan kişiler içindir.
    final PersonDevelopment? gelisim = deceased.development;
    final int toplamNakit = gelisim != null && gelisim.tracksLife
        ? gelisim.money
        : prototypeOnlyEstateMoney(deceased.wealth);

    // Eşin mirası: yalnızca **gerçek evlilik kaydı** varsa pay verilir
    // (D-037). Boşanmış eş mirasçı değildir.
    if (deceased.relation == RelationType.es) {
      final Marriage? kayit = state.marriage;
      final bool gercekEvlilik = kayit != null &&
          kayit.spouseId == deceased.id &&
          kayit.status != MarriageStatus.bosandi;
      if (!gercekEvlilik) {
        return InheritanceShare(
          money: 0,
          itemTypeIds: const <String>[],
          heirCount: mirascilar.others.length,
        );
      }

      final int cocukSayisi = mirascilar.others
          .where((Person p) => p.relation == RelationType.cocuk)
          .length;
      // Çocuk yoksa mirasın tamamı eşe kalır; varsa eş payını alır,
      // kalanı çocuklar arasında bölünür.
      final int oyuncununPayi = cocukSayisi == 0
          ? toplamNakit
          : (toplamNakit * prototypeOnlySpouseShare).round();

      return InheritanceShare(
        money: oyuncununPayi,
        itemTypeIds: _splitItems(deceased.estate, 1 + cocukSayisi),
        heirCount: 1 + cocukSayisi,
      );
    }

    // Çocuğun mirası: anne-baba arasında eşit bölünür.
    if (deceased.relation == RelationType.cocuk) {
      final int mirasciSayisi = 1 + mirascilar.others.length;
      return InheritanceShare(
        money: (toplamNakit / mirasciSayisi).floor(),
        itemTypeIds: _splitItems(deceased.estate, mirasciSayisi),
        heirCount: mirasciSayisi,
      );
    }

    // Eş payı yalnızca ebeveynler **gerçekten birlikteyse** uygulanır:
    // ayrı yaşayan veya boşanmış ebeveyn eş gibi değerlendirilmez (D-037).
    final bool ebeveynMirasi = deceased.relation == RelationType.anne ||
        deceased.relation == RelationType.baba;
    final bool sagKalanEs = ebeveynMirasi &&
        state.parentalStatus.birlikteMi &&
        mirascilar.others.any((Person p) =>
            p.relation == RelationType.anne ||
            p.relation == RelationType.baba);
    final bool esVar = sagKalanEs;

    // Oyuncu + diğer çocuklar.
    final int cocukSayisi = 1 +
        mirascilar.others
            .where((Person p) => p.relation == RelationType.kardes)
            .length;

    final int oyuncuNakit;
    if (esVar) {
      final int esPayi = (toplamNakit * prototypeOnlySpouseShare).round();
      oyuncuNakit = ((toplamNakit - esPayi) / cocukSayisi).floor();
    } else {
      final int mirasciSayisi =
          1 + mirascilar.others.where((Person p) => p.relation != RelationType.anne && p.relation != RelationType.baba).length;
      oyuncuNakit = (toplamNakit / mirasciSayisi).floor();
    }

    // Eşyalar bölünmez: sırayla mirasçılara dağıtılır, oyuncu ilk sıradadır.
    final int esyaMirasciSayisi = 1 +
        mirascilar.others
            .where((Person p) => p.relation == RelationType.kardes)
            .length;
    return InheritanceShare(
      money: oyuncuNakit,
      itemTypeIds: _splitItems(deceased.estate, esyaMirasciSayisi),
      heirCount: 1 + mirascilar.others.length,
    );
  }

  /// Eşyaları mirasçılara sırayla dağıtır; oyuncu ilk sıradadır.
  ///
  /// Eşyalar **bölünmez**: her biri tek bir mirasçıya gider.
  static List<String> _splitItems(List<String> estate, int heirCount) {
    if (heirCount < 1) return const <String>[];
    final List<String> oyuncuyaKalan = <String>[];
    for (int i = 0; i < estate.length; i++) {
      if (i % heirCount == 0) oyuncuyaKalan.add(estate[i]);
    }
    return List<String>.unmodifiable(oyuncuyaKalan);
  }

  /// Mirası **bir kez** uygular ve günlük satırlarını döndürür.
  ///
  /// Aynı kişinin mirası daha önce dağıtıldıysa hiçbir şey yapılmaz.
  static ({GameState state, List<String> logLines}) settle(
    GameState state,
    Person deceased,
  ) {
    if (state.settledEstates.contains(deceased.id)) {
      return (state: state, logLines: const <String>[]);
    }

    final InheritanceShare pay = shareFor(state, deceased);
    final List<String> satirlar = <String>[];
    GameState next = state.copyWith(
      settledEstates: Set<String>.unmodifiable(
        <String>{...state.settledEstates, deceased.id},
      ),
    );

    if (pay.isEmpty) return (state: next, logLines: satirlar);

    final String kisi = deceased.possessiveFor(state.player.age);
    if (pay.money > 0) {
      next = next.copyWith(
        player: next.player.copyWith(
          wallet: next.player.wallet + pay.money,
        ),
      );
      satirlar.add(
        '${trUpperFirst(kisi)} '
        '${deceased.fullName} mirasından payına ${trMoney(pay.money)} düştü.',
      );
    }

    if (pay.itemTypeIds.isNotEmpty) {
      next = next.grantItems(
        pay.itemTypeIds,
        source: ItemSource.miras,
        fromPersonId: deceased.id,
        condition: OwnedItem.migratedCondition,
      );
      for (final String typeId in pay.itemTypeIds) {
        satirlar.add(
          '${trUpperFirst(kisi)} '
          '${deceased.fullName} vefatının ardından sana '
          '${itemTypeOrFallback(typeId).name} miras kaldı.',
        );
      }
    }

    return (state: next, logLines: satirlar);
  }
}
