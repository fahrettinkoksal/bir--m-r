import '../../data/city_neighbours.dart';
import '../models/game_state.dart';
import '../models/life_log.dart';
import '../models/owned_item.dart';
import '../models/rental.dart';
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

  // Not: yıllık kira getirisi (0,045) ve boşluk ihtimali (0,12) burada
  // tutuluyordu ve hiçbiri okunmuyordu. Kirayı Paket AB'den beri
  // `RentalEngine` hesaplıyor; onun kendi sayıları var ve getiri oranı
  // **farklı** (0,042). İki ayrı sayıdan biri sessizce ölüydü.


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

  /// Kiraya verilebilecek konutlar: sahip olunan, oturulmayan, kiracısı
  /// olmayan evler.
  ///
  /// "Kirada mı" sorusunun cevabı **sözleşmeden** gelir (D-163), eşyanın
  /// üstündeki eski `rentedOut` bayrağından değil.
  static List<OwnedItem> rentableHomes(GameState state) => state.items
      .where((OwnedItem i) =>
          i.isProperty &&
          state.leaseOf(i.id) == null &&
          i.id != state.residenceItemId)
      .toList(growable: false);

  /// Kiraya verilmiş konutların toplam yıllık kira geliri (₺).
  ///
  /// Sözleşmede **gerçekten yazılı** kira toplanır. Eskiden bu sayı
  /// katalog değerinden türetiliyordu ve oyuncunun belirlediği kirayı ya da
  /// şehri hiç görmüyordu.
  static int yearlyRentIncome(GameState state) => state.leases
      .fold<int>(0, (int toplam, Lease l) => toplam + l.yearlyRent);

  // =====================================================================
  // Taşınma
  // =====================================================================

  /// İçerideyken taşınma işine bakılamaz (Paket CG).
  ///
  /// **Nasıl bulundu.** Ekran dökümünün yeni turunda cezaevindeki hayat
  /// okundu: Varlıklar ekranı "Yaşadığın yer: Ailesinin yanında" diyor
  /// ve **"Kiralık eve çık" düğmesi açık** duruyordu. Aktivite
  /// (`activity_engine`), iş (`job_market`) ve işletme
  /// (`business_engine`) motorları hükümlülüğe bakıyordu; konut motoru
  /// hiçbir yerde bakmıyordu. Yani oyuncu içeriden ev değiştirebiliyordu.
  static String imprisonedBlockReason(GameState state) {
    if (!state.isImprisoned) return '';
    final int? tahliye = state.legal.releaseAtAge;
    return tahliye == null
        ? 'Cezaevindesin; taşınma işine şimdi bakamazsın.'
        : 'Cezaevindesin; taşınma işine tahliyeden ($tahliye yaş) sonra '
            'bakabilirsin.';
  }

  /// Bu eve taşınılabilir mi?
  String moveBlockReason(GameState state, OwnedItem home) {
    final String icerde = imprisonedBlockReason(state);
    if (icerde.isNotEmpty) return icerde;
    if (!home.isProperty) return 'Burası bir konut değil.';
    if (state.itemById(home.id) == null) return 'Bu mülk artık sende değil.';
    if (state.player.age < prototypeOnlyMinAge) {
      return '$prototypeOnlyMinAge yaşından itibaren taşınabilirsin.';
    }
    if (state.residenceItemId == home.id) return 'Zaten burada yaşıyorsun.';
    if (state.leaseOf(home.id) != null) {
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

  /// prototypeOnly: başka şehre taşınmanın ek masrafı (D-083).
  ///
  /// Şehir değiştirmek, aynı şehirde ev değiştirmekten pahalıdır:
  /// nakliye uzar, iş ve okul düzeni değişir.
  static const int prototypeOnlyIntercityExtraCost = 65000;

  /// Oyuncunun şu an taşınabileceği şehirler (D-083).
  ///
  /// Faho'nun isteği: "taşınmada yaşadığım ilin yakınındaki iller olsun;
  /// her taşındığımda yakınındaki iller çıksın". Ülkenin tamamı yerine
  /// **yaşanan ilin komşuları** listelenir; taşındıkça liste yenilenir.
  List<String> relocationTargets(GameState state) =>
      neighboursOf(state.player.currentCity);

  /// Kiraya çıkar (kendi evinden veya aile evinden ayrılır).
  ///
  /// [city] verilirse **başka bir şehre** taşınılır; şehir yaşanan ilin
  /// komşusu olmak zorundadır ve ek masraf alınır.
  HousingResult moveToRental(GameState state, {String? city}) {
    final String icerde = imprisonedBlockReason(state);
    if (icerde.isNotEmpty) return _blocked(state, icerde);
    if (state.player.age < prototypeOnlyMinAge) {
      return _blocked(
        state,
        '$prototypeOnlyMinAge yaşından itibaren taşınabilirsin.',
      );
    }
    final bool sehirDegisiyor =
        city != null && city != state.player.currentCity;
    if (!sehirDegisiyor && residenceOf(state) == ResidenceKind.kirada) {
      return _blocked(state, 'Zaten kirada yaşıyorsun.');
    }
    if (sehirDegisiyor && !areNeighbours(state.player.currentCity, city)) {
      return _blocked(
        state,
        '$city buradan taşınılacak kadar yakın değil. Önce aradaki bir '
        'ile taşınman gerekiyor.',
      );
    }

    final int masraf = prototypeOnlyMoveCost +
        (sehirDegisiyor ? prototypeOnlyIntercityExtraCost : 0);
    if (state.player.wallet < masraf) {
      return _blocked(
        state,
        'Taşınma masrafı ${trMoney(masraf)}; cüzdanında yeterli para yok.',
      );
    }

    final String metin = sehirDegisiyor
        ? '$city\'e taşındın; kiralık bir eve yerleştin.'
        : 'Kiralık bir eve taşındın.';
    final GameState next = state.copyWith(
      player: state.player.copyWith(
        wallet: state.player.wallet - masraf,
        currentCity: sehirDegisiyor ? city : null,
      ),
      residenceItemId: null,
      movedOut: true,
    );
    return HousingResult(
      state: _log(next, metin),
      outcome: HousingOutcome(applied: true, text: metin),
    );
  }

  /// Ailesinin yanına döner.
  HousingResult moveBackToFamily(GameState state) {
    final String icerde = imprisonedBlockReason(state);
    if (icerde.isNotEmpty) return _blocked(state, icerde);
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

  /// Kiraya vermeye engel; engel yoksa boş metin.
  ///
  /// Kiraya verme akışının kendisi D-163 ile `RentalEngine`'e taşındı:
  /// kira bedeli belirlenir, adaylar gelir, oyuncu kiracıyı seçer. Burada
  /// yalnızca **kapı** duruyor, çünkü taşınma ekranı da aynı kapıya bakar.
  String rentOutBlockReason(GameState state, OwnedItem home) {
    if (!home.isProperty) return 'Burası bir konut değil.';
    if (state.itemById(home.id) == null) return 'Bu mülk artık sende değil.';
    if (state.leaseOf(home.id) != null) return 'Bu evde kiracı var.';
    if (state.residenceItemId == home.id) {
      return 'Oturduğun evi kiraya veremezsin; önce taşınman gerekir.';
    }
    return '';
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
