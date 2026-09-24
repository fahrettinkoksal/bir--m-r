import 'dart:math';

import '../../data/item_catalog.dart';
import '../../data/license_catalog.dart';
import '../../data/name_pool.dart';
import '../../text/turkish_text.dart';
import '../generation/random_util.dart';
import '../models/game_state.dart';
import '../models/interaction.dart';
import '../models/life_log.dart';
import '../models/owned_item.dart';
import '../models/person.dart';
import '../models/relation.dart';
import '../../data/tour_catalog.dart';
import '../models/trip.dart';

/// Bir gezi denemesinin sonucu.
class TripOutcome {
  const TripOutcome({
    required this.applied,
    required this.text,
    this.trip,
  });

  final bool applied;
  final String text;
  final TripRecord? trip;
}

class TripResult {
  const TripResult({required this.state, required this.outcome});

  final GameState state;
  final TripOutcome outcome;
}

/// Kısa seyahat ve yakınlarla gezi (Paket 11).
///
/// Bu sistem **kalıcı taşınmadan ayrıdır**: gezi, oyuncunun yaşadığı ya
/// da doğduğu şehri değiştirmez, Yaş Al akışına dokunmaz ve gerçek
/// dünyada bekleme gerektirmez.
///
/// Sayılar `prototypeOnly`'dir (Q-080).
abstract final class Travel {
  /// prototypeOnly: gezi için en küçük yaş.
  ///
  /// Daha küçük yaşta çocuk tek başına şehir dışına çıkmaz; ailesiyle
  /// gitmesi ayrı bir tasarım konusudur (Q-080).
  static const int prototypeOnlyMinAge = 16;

  /// prototypeOnly: bir yaşta yapılabilecek en fazla gezi.
  static const int prototypeOnlyMaxTripsPerAge = 2;

  /// prototypeOnly: yanına biri alındığında ücretin çarpanı.
  static const double prototypeOnlyCompanionCostFactor = 1.8;

  /// prototypeOnly: geziden gelen mutluluk aralığı.
  static const int prototypeOnlyMinHappiness = 4;
  static const int prototypeOnlyMaxHappiness = 9;

  /// prototypeOnly: birlikte gidilen kişinin yakınlık kazancı.
  static const int prototypeOnlyBondGain = 7;

  /// prototypeOnly: yol yorgunluğu (sağlık).
  static const int prototypeOnlyHealthCost = -1;

  /// prototypeOnly: kendi arabasıyla gidince araçtan düşen kondisyon.
  static const int prototypeOnlyCarWear = 3;

  /// prototypeOnly: kendi arabasıyla yola çıkmak için gereken en düşük
  /// araç kondisyonu.
  static const int prototypeOnlyMinCarCondition = 25;

  /// prototypeOnly: birlikte gidilebilecek çocuğun en küçük yaşı.
  static const int prototypeOnlyMinCompanionAge = 7;

  /// Gidilebilecek şehirler: oyuncunun yaşadığı şehir hariç hepsi.
  static List<String> destinations(GameState state) => sehirler
      .where((String s) => s != state.player.currentCity)
      .toList(growable: false);

  /// Bu yaşta kaç gezi yapıldı?
  static int tripsThisAge(GameState state) =>
      state.trips.where((TripRecord t) => t.age == state.player.age).length;

  /// Oyuncunun kendi arabasıyla gidebileceği durum var mı?
  ///
  /// Gerçek araç sahipliği, otomobil ehliyeti ve aracın kondisyonu
  /// birlikte aranır; biri eksikse bu seçenek **hiç gösterilmez**.
  static OwnedItem? usableCar(GameState state) {
    if (!state.licenses.contains(LicenseType.otomobil.id)) return null;
    for (final OwnedItem item in state.items) {
      if (itemTypeOrFallback(item.typeId).kind != ItemKind.otomobil) continue;
      if (item.condition < prototypeOnlyMinCarCondition) continue;
      return item;
    }
    return null;
  }

  /// Şu an açık olan yolculuk türleri.
  static List<TravelMode> availableModes(GameState state) => <TravelMode>[
        TravelMode.otobus,
        TravelMode.tren,
        TravelMode.ucak,
        if (usableCar(state) != null) TravelMode.kendiArabasi,
      ];

  /// Geziye katılabilecek yakınlar.
  ///
  /// Hayatta olmak, erişilebilir olmak ve yaşı uygun olmak aranır:
  /// vefat etmiş anneyle gezi yapılamaz, bebek çocuk yola çıkarılmaz,
  /// başka şehirdeki arkadaş oyuncunun evindeymiş gibi gösterilmez.
  static List<Person> companions(GameState state) => state.people
      .where((Person p) =>
          p.isAlive &&
          _companionRelations.contains(p.relation) &&
          p.age >= prototypeOnlyMinCompanionAge &&
          state.isReachable(p))
      .toList(growable: false);

  static const Set<RelationType> _companionRelations = <RelationType>{
    RelationType.es,
    RelationType.sevgili,
    RelationType.cocuk,
    RelationType.arkadas,
    RelationType.anne,
    RelationType.baba,
  };

  /// Gezinin ücreti.
  static int costOf(TravelMode mode, {required bool withCompanion}) {
    final int taban = mode.prototypeOnlyCost;
    if (!withCompanion) return taban;
    return (taban * prototypeOnlyCompanionCostFactor).round();
  }

  /// Gezi şu an mümkün mü?
  static InteractionAvailability availability(
    GameState state, {
    required TravelMode mode,
    required String city,
    String? companionId,
  }) {
    if (state.player.age < prototypeOnlyMinAge) {
      return InteractionAvailability.blocked(
        'Tek başına şehir dışına çıkmak için $prototypeOnlyMinAge yaşında '
        'olman gerekiyor.',
      );
    }
    if (city == state.player.currentCity) {
      return const InteractionAvailability.blocked(
        'Zaten bu şehirde yaşıyorsun.',
      );
    }
    if (tripsThisAge(state) >= prototypeOnlyMaxTripsPerAge) {
      return const InteractionAvailability.blocked(
        'Bu yıl yeterince yola çıktın; seneye devam.',
      );
    }
    if (mode == TravelMode.kendiArabasi && usableCar(state) == null) {
      return const InteractionAvailability.blocked(
        'Yola çıkacak durumda bir araban ve otomobil ehliyetin yok.',
      );
    }
    if (companionId != null) {
      final Person? kisi = state.personById(companionId);
      if (kisi == null) {
        return const InteractionAvailability.blocked('Bu kişi kayıtta yok.');
      }
      if (!kisi.isAlive) {
        return InteractionAvailability.blocked(
          '${kisi.firstName} vefat etti.',
        );
      }
      if (!companions(state).any((Person p) => p.id == companionId)) {
        return InteractionAvailability.blocked(
          '${kisi.firstName} şu an birlikte yola çıkabileceğin biri değil.',
        );
      }
    }
    final int ucret = costOf(mode, withCompanion: companionId != null);
    if (state.player.wallet < ucret) {
      return InteractionAvailability.blocked(
        'Bu yolculuk ${trMoney(ucret)} tutuyor; cüzdanında yeterli para yok.',
      );
    }
    return const InteractionAvailability.allowed();
  }

  /// Geziyi gerçekleştirir.
  ///
  /// Ücret cüzdandan **bir kez** düşer, gezi kalıcı kayda girer ve hayat
  /// günlüğüne şehir, yaş, kiminle gidildiği ve gerçek harcama yazılır.
  static TripResult take(
    GameState state, {
    required TravelMode mode,
    required String city,
    String? companionId,
    required Random rng,
  }) {
    final InteractionAvailability uygunluk = availability(
      state,
      mode: mode,
      city: city,
      companionId: companionId,
    );
    if (!uygunluk.isAllowed) {
      return TripResult(
        state: state,
        outcome: TripOutcome(applied: false, text: uygunluk.reason!),
      );
    }

    final int ucret = costOf(mode, withCompanion: companionId != null);
    final Person? yoldas =
        companionId == null ? null : state.personById(companionId);
    final int age = state.player.age;

    // Gezi anısı: şehir ve yoldaşa göre kısa bir sahne.
    final String ani = _memory(rng: rng, city: city, companion: yoldas);

    final TripRecord kayit = TripRecord(
      id: 'gezi-$age-$city-${state.trips.length + 1}',
      city: city,
      age: age,
      mode: mode,
      cost: ucret,
      companionId: companionId,
      note: ani,
    );

    final int mutluluk = rng.between(
      prototypeOnlyMinHappiness,
      prototypeOnlyMaxHappiness,
    );

    GameState next = state.copyWith(
      player: state.player.copyWith(
        // Cüzdan eksiye düşmez; ücret bir kez düşer.
        wallet: state.player.wallet - ucret,
        stats: state.player.stats.gain(
          happiness: mutluluk,
          health: prototypeOnlyHealthCost,
        ),
      ),
      trips: List<TripRecord>.unmodifiable(<TripRecord>[
        ...state.trips,
        kayit,
      ]),
    );

    // Kendi arabasıyla gidince araç yıpranır.
    if (mode == TravelMode.kendiArabasi) {
      final OwnedItem? araba = usableCar(state);
      if (araba != null) {
        next = next.copyWith(
          items: List<OwnedItem>.unmodifiable(
            next.items
                .map((OwnedItem i) => i.id == araba.id
                    ? i.copyWith(
                        condition:
                            (i.condition - prototypeOnlyCarWear).clamp(0, 100),
                      )
                    : i)
                .toList(growable: false),
          ),
        );
      }
    }

    // Birlikte gidilen kişinin yakınlığı artar; zaten 100 ise sahte puan
    // yazılmaz.
    if (yoldas != null) {
      final int yeni =
          (yoldas.bond + prototypeOnlyBondGain).clamp(0, 100);
      if (yeni != yoldas.bond) {
        next = next.copyWith(
          people: next.people
              .map((Person p) => p.id == yoldas.id ? p.copyWith(bond: yeni) : p)
              .toList(growable: false),
        );
      }
    }

    final String kimle = yoldas == null
        ? 'Yalnız gittin'
        : '${yoldas.firstName} ile gittin';
    final String satir = '$city gezisi: $kimle (${mode.label}), '
        '${trMoney(ucret)} harcadın. $ani';

    next = next.copyWith(
      log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
        ...next.log,
        LifeLogEntry(age: age, text: satir, category: LogCategory.kisisel),
      ]),
    );

    return TripResult(
      state: next,
      outcome: TripOutcome(applied: true, text: satir, trip: kayit),
    );
  }

  // =====================================================================
  // Tatil turları (D-083)
  // =====================================================================

  /// prototypeOnly: yoldaşla gidilen turda ücretin çarpanı.
  ///
  /// Tur paketinde ikinci kişi tam ücret öder; otobüs biletinden farklı
  /// olarak burada gerçekten iki kişilik konaklama satın alınır.
  static const double prototypeOnlyTourCompanionFactor = 2.0;

  /// prototypeOnly: turun mutluluğa kattığı taban.
  ///
  /// Gece sayısına göre artar: bir haftalık tur, üç gecelik turdan daha
  /// çok şey bırakır.
  static const int prototypeOnlyTourHappinessPerNight = 1;

  /// Turun ücreti.
  static int tourCostOf(TourPackage tour, {required bool withCompanion}) =>
      withCompanion
          ? (tour.prototypeOnlyCost * prototypeOnlyTourCompanionFactor).round()
          : tour.prototypeOnlyCost;

  /// Bu tura çıkılabilir mi?
  ///
  /// Yaş, yıllık gezi kotası, para ve yoldaş koşulları **tek tek**
  /// bakılır; kapalı düğmenin sebebi görünür olur (D-038).
  static InteractionAvailability tourAvailability(
    GameState state, {
    required TourPackage tour,
    String? companionId,
  }) {
    if (state.player.age < prototypeOnlyMinAge) {
      return InteractionAvailability.blocked(
        '$prototypeOnlyMinAge yaşından itibaren tura çıkabilirsin.',
      );
    }
    if (tripsThisAge(state) >= prototypeOnlyMaxTripsPerAge) {
      return const InteractionAvailability.blocked(
        'Bu yıl yeterince gezdin; seneye yeniden.',
      );
    }
    if (companionId != null) {
      final Person? yoldas = state.personById(companionId);
      if (yoldas == null || !yoldas.isAlive) {
        return const InteractionAvailability.blocked('Böyle biri yok.');
      }
      if (!state.isReachable(yoldas)) {
        return const InteractionAvailability.blocked(
          'Şu an gündelik hayatında görüştüğün biri değil.',
        );
      }
      if (yoldas.age < prototypeOnlyMinCompanionAge) {
        return InteractionAvailability.blocked(
          '${yoldas.firstName} bunun için çok küçük.',
        );
      }
    }
    final int ucret = tourCostOf(tour, withCompanion: companionId != null);
    if (state.player.wallet < ucret) {
      return InteractionAvailability.blocked(
        '${trMoney(ucret)} gerekiyor; cüzdanında yeterli para yok.',
      );
    }
    return const InteractionAvailability.allowed();
  }

  /// Tur paketini satın alır ve tatili yapar.
  ///
  /// Tur **bir gezidir**: yıllık gezi kotasını kullanır, gezi kaydına
  /// girer ve hayat günlüğüne yazılır. Taşınmadan ayrıdır; oyuncunun
  /// yaşadığı şehir değişmez.
  static TripResult takeTour(
    GameState state, {
    required TourPackage tour,
    String? companionId,
    required Random rng,
  }) {
    final InteractionAvailability uygunluk = tourAvailability(
      state,
      tour: tour,
      companionId: companionId,
    );
    if (!uygunluk.isAllowed) {
      return TripResult(
        state: state,
        outcome: TripOutcome(applied: false, text: uygunluk.reason!),
      );
    }

    final int ucret = tourCostOf(tour, withCompanion: companionId != null);
    final Person? yoldas =
        companionId == null ? null : state.personById(companionId);
    final int age = state.player.age;

    final TripRecord kayit = TripRecord(
      id: 'tur-$age-${tour.id}-${state.trips.length + 1}',
      city: tour.mainCity,
      age: age,
      // Paket turlar otobüsle yapılır; uydurma bir ulaşım türü eklenmez.
      mode: TravelMode.otobus,
      cost: ucret,
      companionId: companionId,
      note: '${tour.label}: ${tour.cities.join(', ')}.',
    );

    final int mutluluk = (rng.between(
              prototypeOnlyMinHappiness,
              prototypeOnlyMaxHappiness,
            ) +
            tour.nights * prototypeOnlyTourHappinessPerNight)
        .clamp(0, 20);

    GameState next = state.copyWith(
      player: state.player.copyWith(
        wallet: state.player.wallet - ucret,
        stats: state.player.stats.gain(
          happiness: mutluluk,
          health: prototypeOnlyHealthCost,
        ),
      ),
      trips: List<TripRecord>.unmodifiable(<TripRecord>[
        ...state.trips,
        kayit,
      ]),
    );

    if (yoldas != null) {
      final int yeni = (yoldas.bond + prototypeOnlyBondGain).clamp(0, 100);
      if (yeni != yoldas.bond) {
        next = next.copyWith(
          people: next.people
              .map((Person p) => p.id == yoldas.id ? p.copyWith(bond: yeni) : p)
              .toList(growable: false),
        );
      }
    }

    final String kimle = yoldas == null
        ? 'Yalnız gittin'
        : '${yoldas.firstName} ile gittin';
    final String satir = '${tour.label} (${tour.nights} gece): $kimle, '
        '${trMoney(ucret)} harcadın. ${tour.cities.join(', ')} gezildi.';

    next = next.copyWith(
      log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
        ...next.log,
        LifeLogEntry(age: age, text: satir, category: LogCategory.kisisel),
      ]),
    );

    return TripResult(
      state: next,
      outcome: TripOutcome(applied: true, text: satir, trip: kayit),
    );
  }

  /// Yıllar sonra hatırlanabilecek bir gezi bul.
  ///
  /// Yalnızca **birlikte gidilen** ve kişisi hâlâ hayatta olan geziler
  /// hatırlanır; vefat etmiş kişiyle yeni anı olayı üretilmez.
  static TripRecord? memorableTrip(GameState state, {int minYearsAgo = 5}) {
    for (final TripRecord t in state.trips.reversed) {
      if (t.companionId == null) continue;
      if (state.player.age - t.age < minYearsAgo) continue;
      final Person? kisi = state.personById(t.companionId!);
      if (kisi == null || !kisi.isAlive) continue;
      return t;
    }
    return null;
  }

  // -------------------------------------------------------------------
  // Anılar
  // -------------------------------------------------------------------

  /// prototypeOnly: gezide yaşanan kısa sahneler.
  ///
  /// Yalnızca şehir adı değişen aynı metin çoğaltılmaz; sahneler farklı
  /// şeyler anlatır.
  static String _memory({
    required Random rng,
    required String city,
    required Person? companion,
  }) {
    final String ad = companion?.firstName ?? '';
    final List<String> yalniz = <String>[
      'Otogarın karşısındaki lokantada tek başına yemek yedin; '
          'garson nereli olduğunu sordu.',
      'Akşamüstü bilmediğin bir sokakta yürüdün, kaybolmak iyi geldi.',
      'Dönüş biletini bir gün ertelemeyi düşündün ama ertelemedin.',
      'Meydanda bir bankta oturup insanları izledin; kimse seni tanımıyordu.',
      'Aldığın küçük hediyeyi kendine ayırdın.',
    ];
    final List<String> beraber = <String>[
      '$ad ile yolda hiç susmadınız.',
      '$ad fotoğraf çekmekte ısrar etti; sonradan hepsi iyi geldi.',
      'Dönüşte $ad otobüste uyuyakaldı, sen camdan dışarı baktın.',
      '$ad ile aynı türküyü mırıldandığınızı fark ettiniz.',
      '$ad ile küçük bir tartışma çıktı, akşam yemeğinde unutuldu.',
    ];
    return rng.pick(companion == null ? yalniz : beraber);
  }
}
