import '../models/game_state.dart';
import '../models/life_log.dart';
import '../models/owned_item.dart';
import '../models/person.dart';
import '../../text/turkish_text.dart';

/// Oyuncunun nerede yaşadığı (D-043).
///
/// **Mülk sahipliği ile oturulan ev ayrıdır**: oyuncu evi olup ailesinin
/// yanında yaşayabilir, evini kiraya verip kirada oturabilir.
enum ResidenceKind {
  aileYaninda('Ailesinin yanında'),
  kirada('Kirada'),
  kendiEvinde('Kendi evinde');

  const ResidenceKind(this.label);

  final String label;
}

/// Bir taşınma veya kiralama işleminin sonucu.
class HousingOutcome {
  const HousingOutcome({required this.applied, required this.text});

  final bool applied;
  final String text;
}

class HousingResult {
  const HousingResult({required this.state, required this.outcome});

  final GameState state;
  final HousingOutcome outcome;
}

/// Taşınma, kiraya verme ve kira geliri (D-043).
///
/// Bütün tutar ve oranlar `prototypeOnly`'dir (Q-060).
class Housing {
  const Housing();

  /// prototypeOnly: taşınmanın yetişkinlik yaşı.
  static const int prototypeOnlyMinAge = 18;

  /// prototypeOnly: taşınmanın tek seferlik masrafı (nakliye, depozito).
  static const int prototypeOnlyMoveCost = 45000;

  /// prototypeOnly: konutun değerinin yıllık kira geliri oranı.
  static const double prototypeOnlyYearlyRentYield = 0.045;

  /// prototypeOnly: kiracının bulunamadığı, gelirin gelmediği yıl ihtimali.
  static const double prototypeOnlyVacancyChance = 0.12;

  /// Oyuncunun **aile evinde** hayatta bir yetişkin var mı?
  ///
  /// Eş ve çocuklar sayılmaz: onlarla kurulan hane, ailenin yanında
  /// yaşamak değil, oyuncunun kendi hanesidir.
  static bool hasAdultAtFamilyHome(GameState state) => state.people.any(
        (Person p) =>
            p.isAlive &&
            p.inPlayerHousehold &&
            !p.relation.haneBagi &&
            p.age >= prototypeOnlyMinAge,
      );

  /// Oyuncunun oturduğu ev (varsa).
  static OwnedItem? residenceHome(GameState state) {
    final String? id = state.residenceItemId;
    if (id == null) return null;
    final OwnedItem? item = state.itemById(id);
    if (item == null || !item.isProperty) return null;
    return item;
  }

  /// Oyuncunun yaşam düzeni.
  ///
  /// Kayıtta tutulan oturma bilgisi esastır; oturulan ev satıldıysa veya
  /// hane değiştiyse durum kendiliğinden tutarlı hâle gelir.
  static ResidenceKind residenceOf(GameState state) {
    if (residenceHome(state) != null) return ResidenceKind.kendiEvinde;
    if (state.movedOut) return ResidenceKind.kirada;
    return hasAdultAtFamilyHome(state)
        ? ResidenceKind.aileYaninda
        : ResidenceKind.kirada;
  }

  /// Oyuncunun şu an yaşadığı şehir.
  static String cityOf(GameState state) {
    final OwnedItem? ev = residenceHome(state);
    return ev?.location ?? state.player.currentCity;
  }

  /// Kiraya verilebilecek konutlar: sahip olunan, oturulmayan evler.
  static List<OwnedItem> rentableHomes(GameState state) => state.items
      .where((OwnedItem i) =>
          i.isProperty && !i.rentedOut && i.id != state.residenceItemId)
      .toList(growable: false);

  /// Bir konutun yıllık kira geliri.
  static int yearlyRentOf(OwnedItem home) =>
      (home.type.baseValue * prototypeOnlyYearlyRentYield).round();

  /// Kiraya verilmiş konutların toplam yıllık kira geliri.
  static int yearlyRentIncome(GameState state) => state.items
      .where((OwnedItem i) => i.isProperty && i.rentedOut)
      .fold(0, (int toplam, OwnedItem i) => toplam + yearlyRentOf(i));

  // =====================================================================
  // Taşınma
  // =====================================================================

  /// Bu eve taşınılabilir mi?
  String moveBlockReason(GameState state, OwnedItem home) {
    if (!home.isProperty) return 'Burası bir konut değil.';
    if (state.itemById(home.id) == null) return 'Bu mülk artık sende değil.';
    if (state.player.age < prototypeOnlyMinAge) {
      return '$prototypeOnlyMinAge yaşından itibaren taşınabilirsin.';
    }
    if (state.residenceItemId == home.id) return 'Zaten burada yaşıyorsun.';
    if (home.rentedOut) {
      return 'Bu ev kirada; önce kiracıyı çıkarman gerekiyor.';
    }
    if (state.player.wallet < prototypeOnlyMoveCost) {
      return 'Taşınma masrafı ${trMoney(prototypeOnlyMoveCost)}; cüzdanında yeterli '
          'para yok.';
    }
    return '';
  }

  /// Kendi evine taşınır.
  ///
  /// Mülk sahipliği değişmez; yalnızca **oturulan ev** değişir. Ev başka
  /// bir şehirdeyse oyuncunun şehri de güncellenir.
  HousingResult moveInto(GameState state, OwnedItem home) {
    final String engel = moveBlockReason(state, home);
    if (engel.isNotEmpty) return _blocked(state, engel);

    final String sehir = home.location ?? state.player.currentCity;
    final String metin = sehir == state.player.currentCity
        ? '${home.name} artık senin evin; eşyalarını taşıdın.'
        : '$sehir şehrindeki ${trLower(home.name)} evine taşındın.';

    final GameState next = state.copyWith(
      player: state.player.copyWith(
        wallet: state.player.wallet - prototypeOnlyMoveCost,
        currentCity: sehir,
      ),
      residenceItemId: home.id,
      movedOut: true,
    );
    return HousingResult(
      state: _log(next, metin),
      outcome: HousingOutcome(applied: true, text: metin),
    );
  }

  /// Kiraya çıkar (kendi evinden veya aile evinden ayrılır).
  HousingResult moveToRental(GameState state) {
    if (state.player.age < prototypeOnlyMinAge) {
      return _blocked(
        state,
        '$prototypeOnlyMinAge yaşından itibaren taşınabilirsin.',
      );
    }
    if (residenceOf(state) == ResidenceKind.kirada) {
      return _blocked(state, 'Zaten kirada yaşıyorsun.');
    }
    if (state.player.wallet < prototypeOnlyMoveCost) {
      return _blocked(
        state,
        'Taşınma masrafı ${trMoney(prototypeOnlyMoveCost)}; cüzdanında yeterli para yok.',
      );
    }

    const String metin = 'Kiralık bir eve taşındın.';
    final GameState next = state.copyWith(
      player: state.player.copyWith(
        wallet: state.player.wallet - prototypeOnlyMoveCost,
      ),
      residenceItemId: null,
      movedOut: true,
    );
    return HousingResult(
      state: _log(next, metin),
      outcome: const HousingOutcome(applied: true, text: metin),
    );
  }

  /// Ailesinin yanına döner.
  HousingResult moveBackToFamily(GameState state) {
    if (!hasAdultAtFamilyHome(state)) {
      return _blocked(
        state,
        'Ailenin yanında yaşayabileceğin bir yetişkin kalmadı.',
      );
    }
    if (residenceOf(state) == ResidenceKind.aileYaninda) {
      return _blocked(state, 'Zaten ailenin yanında yaşıyorsun.');
    }

    const String metin = 'Ailenin yanına geri taşındın.';
    final GameState next = state.copyWith(
      residenceItemId: null,
      movedOut: false,
    );
    return HousingResult(
      state: _log(next, metin),
      outcome: const HousingOutcome(applied: true, text: metin),
    );
  }

  // =====================================================================
  // Kiraya verme
  // =====================================================================

  String rentOutBlockReason(GameState state, OwnedItem home) {
    if (!home.isProperty) return 'Burası bir konut değil.';
    if (state.itemById(home.id) == null) return 'Bu mülk artık sende değil.';
    if (home.rentedOut) return 'Bu ev zaten kirada.';
    if (state.residenceItemId == home.id) {
      return 'Oturduğun evi kiraya veremezsin; önce taşınman gerekir.';
    }
    return '';
  }

  /// Konutu kiraya verir.
  HousingResult rentOut(GameState state, OwnedItem home) {
    final String engel = rentOutBlockReason(state, home);
    if (engel.isNotEmpty) return _blocked(state, engel);

    final int kira = yearlyRentOf(home);
    final String metin = '${home.name} kiraya verildi; yılda ${trMoney(kira)} kira '
        'geliri bekleniyor.';
    final GameState next =
        state.updateItem(home.copyWith(rentedOut: true));
    return HousingResult(
      state: _log(next, metin),
      outcome: HousingOutcome(applied: true, text: metin),
    );
  }

  /// Kiracıyı çıkarır.
  HousingResult endLease(GameState state, OwnedItem home) {
    if (!home.rentedOut) return _blocked(state, 'Bu ev kirada değil.');
    final String metin = '${home.name} için kira sözleşmesi sona erdi.';
    final GameState next =
        state.updateItem(home.copyWith(rentedOut: false));
    return HousingResult(
      state: _log(next, metin),
      outcome: HousingOutcome(applied: true, text: metin),
    );
  }

  HousingResult _blocked(GameState state, String reason) => HousingResult(
        state: state,
        outcome: HousingOutcome(applied: false, text: reason),
      );

  GameState _log(GameState state, String text) => state.copyWith(
        log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
          ...state.log,
          LifeLogEntry(
            age: state.player.age,
            text: text,
            category: LogCategory.kisisel,
          ),
        ]),
      );
}
