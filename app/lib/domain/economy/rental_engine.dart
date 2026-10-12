/// Kiralama motoru: piyasa kirası, kiracı, tahsilat, bakım (D-163).
///
/// **Yeni bir konut sistemi kurmuyor.** Mülk hâlâ [OwnedItem]; oturulan ev
/// hâlâ `GameState.residenceItemId`; taşınma hâlâ [Housing]. Bu dosya eksik
/// olan tarafı ekliyor: evin **kiracısı**, kirası, defteri ve bakımı.
///
/// D-163'ten önce kiralama tek bir `rentedOut` bayrağıydı. Bulunan gerçek
/// eksikler:
///
/// * Kira **katalog değerinden** hesaplanıyordu (`type.baseValue * 0,045`).
///   İstanbul'da 6,6 milyona alınan daire ile Amasya'da 3 milyona alınan
///   daire **aynı** kirayı getiriyordu; şehir katsayısı (D-159) kirada hiç
///   görünmüyordu.
/// * Kiracı yoktu. Kira ya tam geliyordu ya hiç gelmiyordu; boşluk her yıl
///   %12'lik bağımsız bir zar atışıydı, hafızası yoktu.
/// * Depozito, sözleşme, ödeme geçmişi, kiracının çıkması yoktu.
/// * Konutun kondisyonu hiç değişmiyordu ve bakım diye bir şey yoktu
///   (araçta `vehicle_trouble.dart` vardı, konutta karşılığı yoktu).
/// * Boş evin hiçbir maliyeti yoktu.
/// * Evin değeri ömür boyu sabitti.
///
/// Bütün sayılar `prototypeOnly`'dir (Q-166).
library;

import 'dart:math';

import '../../data/city_catalog.dart';
import '../../data/name_pool.dart';
import '../../data/tenant_catalog.dart';
import '../../text/turkish_text.dart';
import '../interaction/divorce_settlement.dart';
import '../models/game_state.dart';
import '../models/life_log.dart';
import '../models/owned_item.dart';
import '../models/rental.dart';
import 'housing.dart';

/// Bir kiralama işleminin sonucu.
class RentalOutcome {
  const RentalOutcome({
    required this.applied,
    required this.text,
    this.amount = 0,
  });

  final bool applied;
  final String text;
  final int amount;
}

class RentalResult {
  const RentalResult({required this.state, required this.outcome});

  final GameState state;
  final RentalOutcome outcome;
}

/// Bir konutun kullanım durumu. Ekranda bu yazar.
enum PropertyUse {
  oturuluyor('Burada yaşıyorsun'),
  kirada('Kirada'),
  bos('Boş');

  const PropertyUse(this.label);

  final String label;
}

abstract final class RentalEngine {
  // -------------------------------------------------------------------
  // Kalibrasyon sabitleri
  // -------------------------------------------------------------------

  /// prototypeOnly: evin **değerine** oranla yıllık brüt kira.
  ///
  /// Türkiye'de konutun kendini kirayla amorti etme süresi uzundur; oyun
  /// bunu birebir taklit etmiyor ama "parayı koy sonsuza kadar bedava
  /// gelir al" da olmuyor. %4,2 brüt, bakım ve boşluk düşülünce net
  /// olarak belirgin biçimde aşağı iniyor — ölçümü
  /// `paket_ab_measure_test.dart` basıyor.
  static const double prototypeOnlyGrossYield = 0.042;

  /// prototypeOnly: kondisyonun kiraya etkisi bandı.
  ///
  /// 100 kondisyon +%10, 40 kondisyon −%14 civarı. Bakımsız daire daha az
  /// kira getirir; bu, bakımın karşılığıdır.
  static double conditionRentFactor(int condition) =>
      0.80 + (condition / 100) * 0.30;

  /// prototypeOnly: depozito = kaç aylık kira.
  static const int prototypeOnlyDepositMonths = 1;

  /// prototypeOnly: istenen kiranın piyasa bandına göre sınırı.
  ///
  /// Oyuncu bandın dışına çıkabilir ama sınırsız değil: 10 katı kira
  /// yazıp "kimse gelmiyor" diye oynamak oyun değil, arayüz istismarı.
  static const double prototypeOnlyMinAskRatio = 0.5;
  static const double prototypeOnlyMaxAskRatio = 2.5;

  /// prototypeOnly: boş evin yıllık gideri (aidat, vergi, temel bakım).
  ///
  /// Evin **değerinin** on binde biri değil, oranı: küçük ama sıfır değil.
  /// Mevcut `LivingCosts` yalnızca **oturulan** evin giderini kesiyor
  /// (denetlendi), bu yüzden burada ikinci kez kesilmiyor.
  static const double prototypeOnlyVacantCostRate = 0.006;

  /// prototypeOnly: kiradaki evin sahibine düşen yıllık gideri.
  ///
  /// Kiracı varken aidatı çoğu yerde kiracı öder; sahibine kalan kalem
  /// daha küçüktür.
  static const double prototypeOnlyLetCostRate = 0.003;

  /// prototypeOnly: kiracılı evin yıllık yıpranması (kondisyon puanı).
  static const double prototypeOnlyTenantWear = 2.6;

  /// prototypeOnly: boş evin yıllık yıpranması.
  static const double prototypeOnlyVacantWear = 1.4;

  /// prototypeOnly: bakımın maliyeti (değerin oranı) ve kazandırdığı puan.
  static const double prototypeOnlyUpkeepCostRate = 0.008;
  static const int prototypeOnlyUpkeepGain = 12;

  /// prototypeOnly: tadilatın maliyeti ve kazandırdığı puan.
  static const double prototypeOnlyRenovationCostRate = 0.035;
  static const int prototypeOnlyRenovationGain = 34;

  /// prototypeOnly: tadilatın evin değerine kalıcı katkısı.
  ///
  /// Sınırlı, bilerek: tadilat yaparak ev değerini istediği kadar şişirmek
  /// bir para basma makinesi olurdu.
  static const double prototypeOnlyRenovationValueGain = 0.012;

  /// prototypeOnly: büyük hasarın yıllık ihtimali ve kondisyon zararı.
  static const double prototypeOnlyDamageChance = 0.07;

  /// prototypeOnly: evin yıllık değer eğilimi.
  ///
  /// Yatırım portföyündeki gibi sert bir piyasa motoru **yok**: şehir,
  /// kondisyon ve geçen zaman üzerinden yavaş hareket. 100 binlik ev on
  /// yılda 100 milyon olmuyor.
  static const double prototypeOnlyValueDrift = 0.025;

  // -------------------------------------------------------------------
  // Okuma
  // -------------------------------------------------------------------

  /// Bir konutun bugünkü tahmini değeri (₺).
  ///
  /// Defterde yazılı değer varsa o; yoksa alış fiyatı, o da yoksa katalog
  /// değeri. Eşya değeri ölçüsü boşanma paylaşımıyla **aynı** yerden
  /// gelir, iki yerde iki farklı sayı olmasın diye.
  static int valueOf(GameState state, OwnedItem home) =>
      state.ledgerOf(home.id).valueBasis ?? DivorceSettlement.valueOf(home);

  /// Konutun kullanım durumu.
  static PropertyUse useOf(GameState state, OwnedItem home) {
    if (state.residenceItemId == home.id) return PropertyUse.oturuluyor;
    return state.leaseOf(home.id) != null
        ? PropertyUse.kirada
        : PropertyUse.bos;
  }

  /// Bu konutun **piyasa** yıllık kirası (₺).
  ///
  /// Üç şeye bakar: evin değeri, bulunduğu şehir (D-159) ve kondisyonu.
  /// Eski formül yalnızca katalog değerine bakıyordu.
  static int marketRent(GameState state, OwnedItem home) {
    final double sehirTalebi = rentDemandFactor(home.location);
    return (valueOf(state, home) *
            prototypeOnlyGrossYield *
            conditionRentFactor(home.condition) *
            sehirTalebi)
        .round();
  }

  /// Piyasa kirası bandı: oyuncuya "tahmini piyasa kirası" diye gösterilir.
  static ({int low, int high}) rentBand(GameState state, OwnedItem home) {
    final int orta = marketRent(state, home);
    return (low: (orta * 0.90).round(), high: (orta * 1.10).round());
  }

  /// prototypeOnly: şehrin **kiracı akışı** çarpanı (D-159 ile bağlı).
  ///
  /// Bu, kira **fiyatını** değil "kaç kişi arar"ı belirler. Ayrı tutuluyor,
  /// çünkü ikisi farklı şeyler: büyük şehirde kira da yüksek, talep de
  /// yüksek; küçük şehirde ev ucuz ama **kiracı bulmak uzun sürüyor**
  /// (görevin 19. maddesi). İlk ölçümde bu ayrım yoktu — fiyat çarpanı
  /// talebe de bindirilmişti ve bant 1,03-1,06 kadar dardı; doluluk her
  /// şehirde %99 çıkıyor, küçük il ile büyük il arasında hiçbir fark
  /// hissedilmiyordu.
  ///
  /// Ölçek: Amasya 0,55 (piyasa kirasında ortalama 1,7 başvuru, yılların
  /// ~%19'unda hiç kimse aramıyor), İstanbul 1,40 (ortalama 4,2 başvuru,
  /// ~%1,5 boş yıl).
  static double applicantFlowFactor(String? city) {
    if (city == null) return 1.0;
    final double f = cityProfile(city).housingFactor;
    return 0.55 + ((f - 1.0) / 1.2) * 0.85;
  }

  /// prototypeOnly: şehrin kira **fiyatı** çarpanı (D-159 ile bağlı).
  ///
  /// Konut fiyatı şehirle birlikte zaten değişiyor; bu çarpan **fiyatın
  /// üstüne** binen kira talebi farkı. Büyük şehirde kira getirisi biraz
  /// daha yüksek, küçük şehirde biraz daha düşük ve kiracı bulmak daha
  /// uzun sürer. Ölçek dar tutuldu: şehir farkı hissedilsin ama oyuncuyu
  /// tek şehre hapsetmesin.
  static double rentDemandFactor(String? city) {
    if (city == null) return 1.0;
    final double f = cityProfile(city).housingFactor;
    // housingFactor 1,0-2,2 bandında. Talep çarpanı 0,94-1,08 arasına
    // sıkıştırılıyor: fiyat farkı zaten kirayı taşıyor, ikinci kez
    // çarpmak İstanbul'u para makinesine çevirirdi.
    return 0.94 + ((f - 1.0) / 1.2) * 0.14;
  }

  /// Bu ilanda bu yıl başvuran adaylar. Deterministik.
  static List<TenantRecord> candidates({
    required GameState state,
    required OwnedItem home,
    required int askingRent,
  }) {
    final int piyasa = marketRent(state, home);
    if (piyasa <= 0) return const <TenantRecord>[];
    final double oran = askingRent / piyasa;
    final double talep =
        prototypeOnlyDemandFactor(oran) * applicantFlowFactor(home.location);
    return tenantCandidates(
      propertyId: home.id,
      age: state.player.age,
      askingRent: askingRent,
      demand: talep,
    );
  }

  /// Kiraya vermeye engel; engel yoksa boş metin.
  static String rentOutBlockReason({
    required GameState state,
    required OwnedItem home,
    required int askingRent,
  }) {
    if (!home.isProperty) return 'Burası bir konut değil.';
    if (state.itemById(home.id) == null) return 'Bu mülk artık sende değil.';
    if (state.residenceItemId == home.id) {
      return 'Oturduğun evi kiraya veremezsin; önce taşınman gerekir.';
    }
    if (state.leaseOf(home.id) != null) return 'Bu evde kiracı var.';
    if (state.player.age < Housing.prototypeOnlyMinAge) {
      return '${Housing.prototypeOnlyMinAge} yaşından itibaren ev '
          'kiraya verebilirsin.';
    }
    final int piyasa = marketRent(state, home);
    final int enAz = (piyasa * prototypeOnlyMinAskRatio).round();
    final int enCok = (piyasa * prototypeOnlyMaxAskRatio).round();
    if (askingRent < enAz) {
      return 'Yıllık ${trMoney(enAz)} altına kiraya vermek mantıklı değil.';
    }
    if (askingRent > enCok) {
      return 'Yıllık ${trMoney(enCok)} üstünde kira isteyen ev boş kalır.';
    }
    return '';
  }

  // -------------------------------------------------------------------
  // Sözleşme
  // -------------------------------------------------------------------

  /// Seçilen adayla sözleşme kurar. Depozito **gelir değildir**.
  static RentalResult signLease({
    required GameState state,
    required OwnedItem home,
    required TenantRecord tenant,
    required int yearlyRent,
  }) {
    final String engel = rentOutBlockReason(
      state: state,
      home: home,
      askingRent: yearlyRent,
    );
    if (engel.isNotEmpty) return _blocked(state, engel);

    final int depozito =
        (yearlyRent / 12 * prototypeOnlyDepositMonths).round();
    final int yas = state.player.age;
    final Lease sozlesme = Lease(
      propertyItemId: home.id,
      tenant: tenant,
      yearlyRent: yearlyRent,
      deposit: depozito,
      startedAtAge: yas,
    );
    final PropertyLedger defter = state.ledgerOf(home.id);

    final String metin = '${tenant.fullName} ${home.name} için sözleşmeyi '
        'imzaladı. Aylık ${trMoney(sozlesme.monthlyRent)}, depozito '
        '${trMoney(depozito)}.';

    final GameState next = _putLedger(
      state.copyWith(
        leases: List<Lease>.unmodifiable(<Lease>[...state.leases, sozlesme]),
        player: state.player.copyWith(
          wallet: state.player.wallet + depozito,
        ),
      ),
      defter.copyWith(
        depositHeld: defter.depositHeld + depozito,
        tenantCount: defter.tenantCount + 1,
      ),
    );

    return RentalResult(
      state: _log(next, metin, yas),
      outcome: RentalOutcome(applied: true, text: metin, amount: depozito),
    );
  }

  /// Sözleşmeyi sonlandırır.
  ///
  /// V1'de bu **soyut** bir aksiyon: mahkeme, icra ya da tahliye
  /// prosedürü yok ve oyun hiçbir yerde "şunu yaparsan kiracıyı hemen
  /// çıkarırsın" demiyor. Depozito evin durumuna göre iade edilir.
  static RentalResult endLease({
    required GameState state,
    required String propertyItemId,
    String? reasonText,
  }) {
    final Lease? sozlesme = state.leaseOf(propertyItemId);
    if (sozlesme == null) return _blocked(state, 'Bu evde kiracı yok.');
    final OwnedItem? ev = state.itemById(propertyItemId);
    if (ev == null) return _blocked(state, 'Bu mülk artık sende değil.');

    final int yas = state.player.age;
    final PropertyLedger defter = state.ledgerOf(propertyItemId);

    // Depozitodan kesinti: yalnızca **ciddi** hasar varsa. Kondisyon
    // düştüyse kesinti oranı zararla birlikte artar ama depozitoyu aşmaz.
    final int kesinti = ev.condition >= 55
        ? 0
        : ((55 - ev.condition) / 55 * sozlesme.deposit).round();
    final int iade = (sozlesme.deposit - kesinti).clamp(0, sozlesme.deposit);

    final String metin = <String>[
      reasonText ??
          '${sozlesme.tenant.fullName} ${ev.name} için sözleşmeyi bitirdi.',
      if (sozlesme.deposit > 0 && kesinti == 0)
        'Depozitosunu geri verdin: ${trMoney(iade)}.',
      if (kesinti > 0)
        'Evin durumu için depozitodan ${trMoney(kesinti)} kestin; '
            '${trMoney(iade)} geri verdin.',
    ].join(' ');

    final GameState next = _putLedger(
      state.copyWith(
        leases: List<Lease>.unmodifiable(<Lease>[
          for (final Lease l in state.leases)
            if (l.propertyItemId != propertyItemId) l,
        ]),
        player: state.player.copyWith(
          // Depozito iadesi cüzdandan çıkar; kesinti oyuncuda kalır.
          // Cüzdan eksiye düşmez: elde o kadar para yoksa kalan iade
          // edilemez ve bu açıkça yazılır.
          wallet: (state.player.wallet - iade)
              .clamp(0, state.player.wallet),
        ),
      ),
      defter.copyWith(depositHeld: defter.depositHeld - sozlesme.deposit),
    );

    return RentalResult(
      state: _log(next, metin, yas),
      outcome: RentalOutcome(applied: true, text: metin, amount: iade),
    );
  }

  /// Sözleşmeyi yeniler: kirayı değiştirir.
  ///
  /// Yüksek artış kiracının çıkma ihtimalini artırır; karar sonucunu
  /// [advanceYear] verir, burada yalnızca yeni kira yazılır.
  static RentalResult renewLease({
    required GameState state,
    required String propertyItemId,
    required int newYearlyRent,
  }) {
    final Lease? sozlesme = state.leaseOf(propertyItemId);
    if (sozlesme == null) return _blocked(state, 'Bu evde kiracı yok.');
    final OwnedItem? ev = state.itemById(propertyItemId);
    if (ev == null) return _blocked(state, 'Bu mülk artık sende değil.');

    final int piyasa = marketRent(state, ev);
    final int enCok = (piyasa * prototypeOnlyMaxAskRatio).round();
    if (newYearlyRent <= 0 || newYearlyRent > enCok) {
      return _blocked(
        state,
        'Yıllık ${trMoney(enCok)} üstünde kira isteyemezsin.',
      );
    }

    final int yas = state.player.age;
    final int fark = newYearlyRent - sozlesme.yearlyRent;
    final int yeniAylik = (newYearlyRent / 12).round();
    final String metin = fark == 0
        ? '${sozlesme.tenant.firstName} ile kirayı aynı bıraktın.'
        : fark > 0
            ? 'Kirayı ${trMoney(yeniAylik)} aylığa çıkardın.'
            : 'Kirayı ${trMoney(yeniAylik)} aylığa indirdin.';

    final GameState next = state.copyWith(
      leases: List<Lease>.unmodifiable(<Lease>[
        for (final Lease l in state.leases)
          if (l.propertyItemId != propertyItemId)
            l
          else
            l.copyWith(yearlyRent: newYearlyRent, lastRenewedAtAge: yas),
      ]),
    );
    return RentalResult(
      state: _log(next, metin, yas),
      outcome: RentalOutcome(applied: true, text: metin),
    );
  }

  // -------------------------------------------------------------------
  // Bakım ve tadilat
  // -------------------------------------------------------------------

  /// Bakım ya da tadilatın maliyeti (₺).
  static int upkeepCost(GameState state, OwnedItem home, {required bool major}) =>
      (valueOf(state, home) *
              (major
                  ? prototypeOnlyRenovationCostRate
                  : prototypeOnlyUpkeepCostRate))
          .round();

  static String upkeepBlockReason({
    required GameState state,
    required OwnedItem home,
    required bool major,
  }) {
    if (!home.isProperty) return 'Burası bir konut değil.';
    if (state.itemById(home.id) == null) return 'Bu mülk artık sende değil.';
    if (home.condition >= 100) return 'Evin durumu şimdilik iyi.';
    final int tutar = upkeepCost(state, home, major: major);
    if (state.player.wallet < tutar) {
      return '${major ? 'Tadilat' : 'Bakım'} ${trMoney(tutar)}; cüzdanında '
          'yeterli para yok.';
    }
    return '';
  }

  /// Bakım (ucuz, orta iyileştirme) ya da tadilat (pahalı, büyük
  /// iyileştirme + sınırlı değer artışı).
  static RentalResult upkeep({
    required GameState state,
    required OwnedItem home,
    required bool major,
  }) {
    final String engel =
        upkeepBlockReason(state: state, home: home, major: major);
    if (engel.isNotEmpty) return _blocked(state, engel);

    final int tutar = upkeepCost(state, home, major: major);
    final int kazanc =
        major ? prototypeOnlyRenovationGain : prototypeOnlyUpkeepGain;
    final int yas = state.player.age;
    final PropertyLedger defter = state.ledgerOf(home.id);
    final int mevcutDeger = valueOf(state, home);
    final int yeniDeger = major
        ? (mevcutDeger * (1 + prototypeOnlyRenovationValueGain)).round()
        : mevcutDeger;

    final String metin = major
        ? '${home.name} tadilattan geçti. ${trMoney(tutar)} gitti ama ev '
            'gözle görülür biçimde toparlandı.'
        : '${home.name} için ${trMoney(tutar)} bakım masrafı yaptın.';

    GameState next = state
        .updateItem(home.copyWith(condition: home.condition + kazanc))
        .copyWith(
          player: state.player.copyWith(
            wallet: state.player.wallet - tutar,
          ),
        );
    next = _putLedger(
      next,
      defter.copyWith(
        maintenanceSpent: defter.maintenanceSpent + tutar,
        lastMaintenanceAge: yas,
        valueBasis: yeniDeger,
      ),
    );

    return RentalResult(
      state: _log(next, metin, yas),
      outcome: RentalOutcome(applied: true, text: metin, amount: tutar),
    );
  }

  // -------------------------------------------------------------------
  // Ev sahibi (oyuncu kiradayken)
  // -------------------------------------------------------------------

  /// Oyuncu kiradaysa ev sahibi kaydını kurar ya da olduğu gibi bırakır.
  ///
  /// **Neden kayda yazılıyor:** ev sahibinin adı her olayda yeniden
  /// üretilse aynı evde yıllarca oturan oyuncunun ev sahibi her yıl başka
  /// biri olurdu. Kayıt Person değil; İlişkiler ekranını doldurmaması için
  /// hafif tutuldu. Oyuncu kendi evine geçince kayıt kapanır.
  static GameState syncLandlord({
    required GameState state,
    required int newAge,
    required Random rng,
  }) {
    final bool kirada = Housing.residenceOf(state) == ResidenceKind.kirada;
    if (!kirada) {
      return state.landlord == null ? state : state.copyWith(landlord: null);
    }
    if (state.landlord != null) return state;

    final bool erkek = rng.nextBool();
    return state.copyWith(
      landlord: LandlordRecord(
        firstName: erkek
            ? erkekIsimleri[rng.nextInt(erkekIsimleri.length)]
            : kadinIsimleri[rng.nextInt(kadinIsimleri.length)],
        lastName: soyisimler[rng.nextInt(soyisimler.length)],
        sinceAge: newAge,
        temperament: LandlordTemperament
            .values[rng.nextInt(LandlordTemperament.values.length)],
      ),
    );
  }

  // -------------------------------------------------------------------
  // Yıllık ilerleme
  // -------------------------------------------------------------------

  /// Bir yılın kiralama tarafı: tahsilat, yıpranma, hasar, boş ev gideri,
  /// kiracının çıkması ve değer değişimi.
  ///
  /// **Kira gelir, ev varlık.** Gelir cüzdana girer; evin kendisi
  /// `NetWorth` içinde eşya olarak sayılır. Kiranın bugünkü değeri diye
  /// ikinci bir varlık yazılmaz — aynı ev iki kez sayılmaz.
  ///
  /// Bildirim yağmuru yapmaz: normal tahsilat yalnızca günlüğe yazılır,
  /// ekran bildirimi sadece gerçekten anlatılacak bir şey olunca üretilir
  /// ([RentalYear.notable]).
  static ({GameState state, RentalYear year}) advanceYear({
    required GameState state,
    required int newAge,
    required Random rng,
  }) {
    final List<OwnedItem> konutlar = state.properties;
    if (konutlar.isEmpty) {
      return (state: state, year: const RentalYear());
    }

    GameState s = state;
    int tahsil = 0;
    int gider = 0;
    final List<String> onemli = <String>[];

    for (final OwnedItem konut in konutlar) {
      final OwnedItem? guncel = s.itemById(konut.id);
      if (guncel == null) continue;
      final bool oturuluyor = s.residenceItemId == guncel.id;
      final Lease? sozlesme = s.leaseOf(guncel.id);
      PropertyLedger defter = s.ledgerOf(guncel.id);
      int kondisyon = guncel.condition;

      if (sozlesme != null) {
        // ---- Tahsilat -------------------------------------------------
        final ({int paid, bool late, bool unpaid}) odeme =
            _collect(sozlesme, rng);
        tahsil += odeme.paid;
        defter = defter.copyWith(
          rentCollected: defter.rentCollected + odeme.paid,
        );
        Lease yeni = sozlesme.copyWith(
          onTimeYears: sozlesme.onTimeYears + (odeme.late ? 0 : 1),
          lateYears: sozlesme.lateYears + (odeme.late ? 1 : 0),
          unpaidYears: sozlesme.unpaidYears + (odeme.unpaid ? 1 : 0),
          tenant: sozlesme.tenant.copyWith(age: sozlesme.tenant.age + 1),
        );
        if (odeme.unpaid) {
          onemli.add('${guncel.name}: ${sozlesme.tenant.firstName} bu yıl '
              'kirayı hiç ödemedi.');
        } else if (odeme.late) {
          onemli.add('${guncel.name}: kira bu yıl zar zor, gecikmeli geldi.');
        }

        // ---- Yıpranma ve hasar ---------------------------------------
        kondisyon = _wear(
          condition: kondisyon,
          tenant: sozlesme.tenant,
          occupied: true,
          rng: rng,
        );
        if (rng.nextDouble() < _damageChanceFor(sozlesme.tenant)) {
          final int zarar = 8 + rng.nextInt(14);
          kondisyon = (kondisyon - zarar).clamp(0, 100);
          onemli.add('${guncel.name}: evde ciddi bir şey bozuldu.');
        }

        // ---- Sahibine kalan gider ------------------------------------
        final int sahipGideri =
            (valueOf(s, guncel) * prototypeOnlyLetCostRate).round();
        gider += sahipGideri;
        defter = defter.copyWith(
          maintenanceSpent: defter.maintenanceSpent + sahipGideri,
        );

        // ---- Kiracı çıkar mı? ----------------------------------------
        if (_tenantLeaves(lease: yeni, state: s, home: guncel, rng: rng)) {
          s = _applyItem(s, guncel, kondisyon);
          s = _putLedger(s, defter);
          final RentalResult cikis = endLease(
            state: s,
            propertyItemId: guncel.id,
            reasonText: _moveOutText(yeni, rng),
          );
          s = cikis.state;
          onemli.add(cikis.outcome.text);
          continue;
        }

        s = s.copyWith(
          leases: List<Lease>.unmodifiable(<Lease>[
            for (final Lease l in s.leases)
              if (l.propertyItemId == guncel.id) yeni else l,
          ]),
        );
      } else {
        // ---- Boş ya da oturulan ev -----------------------------------
        kondisyon = _wear(
          condition: kondisyon,
          tenant: null,
          occupied: oturuluyor,
          rng: rng,
        );
        if (!oturuluyor) {
          // Boş ev bedava beklemiyor. **Oturulan** evin gideri
          // `LivingCosts` içinde zaten kesiliyor (denetlendi); burada
          // yalnızca boş ev kesiliyor, ikinci kez kesme yok.
          final int bosGider =
              (valueOf(s, guncel) * prototypeOnlyVacantCostRate).round();
          gider += bosGider;
          defter = defter.copyWith(
            vacantYears: defter.vacantYears + 1,
            maintenanceSpent: defter.maintenanceSpent + bosGider,
          );
        }
      }

      // ---- Değer değişimi ---------------------------------------------
      defter = defter.copyWith(
        valueBasis: _nextValue(
          current: valueOf(s, guncel),
          condition: kondisyon,
          city: guncel.location,
          rng: rng,
        ),
      );

      s = _applyItem(s, guncel, kondisyon);
      s = _putLedger(s, defter);
    }

    // Para hareketi tek seferde uygulanır: cüzdan eksiye düşmez.
    final int net = tahsil - gider;
    if (net != 0) {
      s = s.copyWith(
        player: s.player.copyWith(
          wallet: (s.player.wallet + net).clamp(0, 1 << 62),
        ),
      );
    }
    if (tahsil > 0) {
      s = _log(
        s,
        'Kira gelirin bu yıl ${trMoney(tahsil)} oldu.',
        newAge,
      );
    }

    return (
      state: s,
      year: RentalYear(collected: tahsil, costs: gider, notes: onemli),
    );
  }

  /// Bu yılın kirası ne kadar geldi?
  ///
  /// Kiracıların çoğu düzenli öder. Gizli güvenilirlik ortalamayı kaydırır
  /// ama hiçbir kiracı "her yıl sorun çıkaran karikatür" değil: en zayıf
  /// kiracı bile yılların çoğunda ödüyor.
  static ({int paid, bool late, bool unpaid}) _collect(
    Lease lease,
    Random rng,
  ) {
    final double guven = lease.tenant.reliability / 100;
    // Sorun ihtimali: en iyi kiracıda ~%3, en zayıfta ~%28.
    final double sorun = 0.30 - guven * 0.27;
    final double d = rng.nextDouble();
    if (d >= sorun) {
      return (paid: lease.yearlyRent, late: false, unpaid: false);
    }
    // Sorun çıktı: çoğu kez kısmi/gecikmeli, seyrek olarak hiç ödenmiyor.
    if (rng.nextDouble() < 0.72) {
      final int kismi = (lease.yearlyRent * (0.5 + rng.nextDouble() * 0.4))
          .round();
      return (paid: kismi, late: true, unpaid: false);
    }
    return (paid: 0, late: false, unpaid: true);
  }

  /// prototypeOnly: bu kiracıda büyük hasar ihtimali.
  static double _damageChanceFor(TenantRecord tenant) {
    final double kollama = tenant.care / 100;
    return prototypeOnlyDamageChance *
        tenant.household.wearFactor *
        (1.4 - kollama * 0.9);
  }

  static int _wear({
    required int condition,
    required TenantRecord? tenant,
    required bool occupied,
    required Random rng,
  }) {
    final double taban = tenant != null
        ? prototypeOnlyTenantWear * tenant.household.wearFactor
        : (occupied ? prototypeOnlyTenantWear * 0.9 : prototypeOnlyVacantWear);
    final double kollamaEtkisi =
        tenant == null ? 1.0 : 1.35 - (tenant.care / 100) * 0.7;
    final int dusus = (taban * kollamaEtkisi + rng.nextDouble() * 1.5).round();
    return (condition - dusus).clamp(0, 100);
  }

  /// Kiracı bu yıl çıkıyor mu?
  ///
  /// Çıkma sebepleri gerçek: kira çok yükseldi, ev kötüleşti, kendi hayatı
  /// değişti (evlilik, çocuk, başka şehir, kendi evini aldı) ya da uzun
  /// süredir oturuyor. İyi kiracı kolay kolay çıkmaz.
  static bool _tenantLeaves({
    required Lease lease,
    required GameState state,
    required OwnedItem home,
    required Random rng,
  }) {
    final int piyasa = marketRent(state, home);
    final double kiraOrani = piyasa <= 0 ? 1 : lease.yearlyRent / piyasa;

    double sans = 0.09;
    // Piyasanın üstünde kira: kiracı başka yere bakar.
    if (kiraOrani > 1.10) sans += (kiraOrani - 1.10) * 0.85;
    // Ev kötüleştiyse çıkar.
    if (home.condition < 45) sans += (45 - home.condition) * 0.004;
    // Kendi hayatı: evlenme, çocuk, şehir değişikliği, kendi evi.
    sans += 0.03;
    // Ödeme sorunu yaşayan kiracı zaten zorlanıyor.
    if (lease.unpaidYears > 0) sans += 0.18;
    // İyi giden uzun sözleşme: kiracı yerleşmiş, kolay çıkmaz.
    if (lease.onTimeYears >= 3 && lease.troubleYears == 0) sans -= 0.03;

    return rng.nextDouble() < sans.clamp(0.02, 0.85);
  }

  static String _moveOutText(Lease lease, Random rng) {
    final String ad = lease.tenant.firstName;
    final List<String> secenekler = <String>[
      '$ad aradı. "Abi ev aldık, ay sonunda anahtarı bırakacağım." '
          'İyi kiracıydı.',
      '$ad taşınıyor: işi başka şehre düştü.',
      '$ad evleniyor, daha büyük bir yere geçecekmiş.',
      '$ad çıkmaya karar verdi. Uzun uzun sebep saymadı, "artık olmadı" dedi.',
    ];
    if (lease.onTimeYears >= 4 && lease.troubleYears == 0) {
      return '$ad ${lease.onTimeYears} yıl sonra çıkıyor. Bir kere bile '
          'kirayı geciktirmedi; biraz insan üzülüyor.';
    }
    return secenekler[rng.nextInt(secenekler.length)];
  }

  /// prototypeOnly: evin bir yıl sonraki değeri.
  ///
  /// Yavaş ve sınırlı: şehir eğilimi + kondisyonun etkisi + küçük gürültü.
  /// Yatırım portföyündeki rejim motoru burada **bilerek** kullanılmıyor;
  /// ev bir hisse senedi değil.
  static int _nextValue({
    required int current,
    required int condition,
    required String? city,
    required Random rng,
  }) {
    final double sehir = city == null
        ? 1.0
        : 0.9 + (cityProfile(city).housingFactor - 1.0) / 1.2 * 0.25;
    // Kondisyon 70'in altına inerse değer eğilimi aşağı kayar: bakımsız
    // ev değer kaybeder.
    final double bakim = (condition - 70) / 100 * 0.05;
    final double gurultu = (rng.nextDouble() - 0.5) * 0.03;
    final double oran = prototypeOnlyValueDrift * sehir + bakim + gurultu;
    return (current * (1 + oran)).round().clamp(1, 1 << 40);
  }

  static GameState _applyItem(GameState state, OwnedItem home, int condition) =>
      condition == home.condition
          ? state
          : state.updateItem(home.copyWith(condition: condition));

  static RentalResult _blocked(GameState state, String reason) => RentalResult(
        state: state,
        outcome: RentalOutcome(applied: false, text: reason),
      );

  static GameState _putLedger(GameState state, PropertyLedger ledger) {
    final bool varMi = state.propertyLedgers
        .any((PropertyLedger l) => l.propertyItemId == ledger.propertyItemId);
    return state.copyWith(
      propertyLedgers: List<PropertyLedger>.unmodifiable(<PropertyLedger>[
        if (!varMi) ...state.propertyLedgers,
        if (!varMi)
          ledger
        else
          for (final PropertyLedger l in state.propertyLedgers)
            if (l.propertyItemId == ledger.propertyItemId) ledger else l,
      ]),
    );
  }

  static GameState _log(GameState state, String text, int age) =>
      state.copyWith(
        log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
          ...state.log,
          LifeLogEntry(age: age, text: text, category: LogCategory.kisisel),
        ]),
      );
}

/// Bir yılın kiralama özeti. Yıl özetinde ve bildirim kararında kullanılır.
class RentalYear {
  const RentalYear({
    this.collected = 0,
    this.costs = 0,
    this.notes = const <String>[],
  });

  /// Tahsil edilen kira (₺).
  final int collected;

  /// Mülk giderleri (₺).
  final int costs;

  /// Gerçekten anlatılacak olaylar. Boşsa bildirim açılmaz.
  final List<String> notes;

  int get net => collected - costs;

  /// Ekran bildirimi hak ediyor mu?
  bool get notable => notes.isNotEmpty;
}
