/// Kiralama kayıtları: kiracı, sözleşme, mülk defteri ve ev sahibi (D-163).
///
/// **Neden ayrı bir kiracı modeli var:** kiracıyı tam [Person] yapmak
/// İlişkiler ekranını yıllar içinde yüzlerce kişiyle doldururdu — oyuncunun
/// hiç tanışmadığı, adını bile hatırlamayacağı insanlar. Kiracı bu yüzden
/// **hafif** bir kayıt: adı, yaşı, mesleği ve hane durumu kalıcı, ama soy
/// ağacına, yakınlığa ve etkileşim sistemine girmiyor.
///
/// Kalıcılık kasıtlı: aynı kiracı her yıl başka isimle görünmez. Sözleşme
/// bitene kadar aynı kişi oturur, geçmişi de onunla birlikte taşınır.
///
/// Bütün sayılar `prototypeOnly`'dir (Q-166).
library;

import 'package:flutter/foundation.dart';

/// Kiracının gelir bandı. Ekranda yazar; kirayı ödeyebilme ihtimalini
/// etkiler ama **belirlemez** — yüksek gelirli de sorun çıkarabilir.
enum TenantIncome {
  dusuk('Düşük'),
  orta('Orta'),
  iyi('İyi');

  const TenantIncome(this.label);

  final String label;
}

/// Kiracının hane durumu.
enum TenantHousehold {
  tekBasina('Tek başına yaşayacak'),
  cift('Eşiyle birlikte'),
  cocukluAile('Evli, çocuklu'),
  ogrenciler('Öğrenci, ev arkadaşıyla');

  const TenantHousehold(this.label);

  final String label;

  /// Evi daha çok yıpratan hane mi? Çocuklu ve kalabalık ev daha çok
  /// yıpratır; bu bir yargı değil, kullanım yoğunluğu.
  double get wearFactor => switch (this) {
        TenantHousehold.tekBasina => 0.8,
        TenantHousehold.cift => 1.0,
        TenantHousehold.cocukluAile => 1.3,
        TenantHousehold.ogrenciler => 1.2,
      };
}

/// Kiracının **görünen** ödeme geçmişi.
///
/// Bilerek belirsizlik bırakıyor: "Belirsiz" bir aday iyi de çıkabilir.
/// Oyuncu kiracıyı kendi seçer ve sonucu önceden bilmez.
enum TenantTrack {
  iyi('İyi'),
  belirsiz('Belirsiz'),
  zayif('Karışık');

  const TenantTrack(this.label);

  final String label;
}

/// Bir kiracı. Person değil; hafif ve kalıcı bir kayıt.
@immutable
class TenantRecord {
  const TenantRecord({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.age,
    required this.occupation,
    required this.household,
    required this.income,
    required this.track,
    required this.reliability,
    required this.care,
  });

  final String id;
  final String firstName;
  final String lastName;
  final int age;

  /// "Çağrı merkezi çalışanı" gibi kısa meslek satırı.
  final String occupation;

  final TenantHousehold household;
  final TenantIncome income;

  /// Ekranda yazan ödeme geçmişi.
  final TenantTrack track;

  /// prototypeOnly: **gizli** ödeme güvenilirliği (0-100).
  ///
  /// Ekranda sayı olarak gösterilmez. [track] bunun kaba bir yansımasıdır
  /// ama birebir değil: "İyi" görünen bir kiracı da sıkışabilir.
  final int reliability;

  /// prototypeOnly: **gizli** evi kollama eğilimi (0-100).
  final int care;

  String get fullName => '$firstName $lastName';

  TenantRecord copyWith({int? age}) => TenantRecord(
        id: id,
        firstName: firstName,
        lastName: lastName,
        age: age ?? this.age,
        occupation: occupation,
        household: household,
        income: income,
        track: track,
        reliability: reliability,
        care: care,
      );
}

/// Yürüyen bir kira sözleşmesi.
///
/// Bir mülkte en fazla bir sözleşme olur. Sözleşmenin varlığı "bu ev
/// kirada" demenin **tek** yoludur; `OwnedItem.rentedOut` artık yalnızca
/// eski kayıtları açmak için duruyor (D-163).
@immutable
class Lease {
  const Lease({
    required this.propertyItemId,
    required this.tenant,
    required this.yearlyRent,
    required this.deposit,
    required this.startedAtAge,
    this.onTimeYears = 0,
    this.lateYears = 0,
    this.unpaidYears = 0,
    this.lastRenewedAtAge,
    this.graceGivenAtAge,
  });

  final String propertyItemId;
  final TenantRecord tenant;

  /// Yıllık kira (₺). Ekranda aylığı gösterilir, motor yıllık çalışır.
  final int yearlyRent;

  /// Alınan depozito (₺). **Gelir değildir**; çıkışta iade edilir.
  final int deposit;

  final int startedAtAge;

  /// Zamanında ödenen yıl sayısı.
  final int onTimeYears;

  /// Gecikmeli ya da eksik ödenen yıl sayısı.
  final int lateYears;

  /// Hiç ödenmeyen yıl sayısı.
  final int unpaidYears;

  final int? lastRenewedAtAge;

  /// Oyuncunun "süre ver" dediği son yaş.
  final int? graceGivenAtAge;

  /// Aylık kira (₺) — yalnızca gösterim için.
  int get monthlyRent => (yearlyRent / 12).round();

  int yearsIn(int age) => age - startedAtAge;

  /// Sorun çıkmış yıl sayısı.
  int get troubleYears => lateYears + unpaidYears;

  Lease copyWith({
    int? yearlyRent,
    int? onTimeYears,
    int? lateYears,
    int? unpaidYears,
    int? lastRenewedAtAge,
    int? graceGivenAtAge,
    TenantRecord? tenant,
  }) =>
      Lease(
        propertyItemId: propertyItemId,
        tenant: tenant ?? this.tenant,
        yearlyRent: yearlyRent ?? this.yearlyRent,
        deposit: deposit,
        startedAtAge: startedAtAge,
        onTimeYears: onTimeYears ?? this.onTimeYears,
        lateYears: lateYears ?? this.lateYears,
        unpaidYears: unpaidYears ?? this.unpaidYears,
        lastRenewedAtAge: lastRenewedAtAge ?? this.lastRenewedAtAge,
        graceGivenAtAge: graceGivenAtAge ?? this.graceGivenAtAge,
      );
}

/// Bir mülkün ömür boyu defteri.
///
/// Kiracı değişse de durur: oyuncu "bu ev bana ne kazandırdı" sorusunun
/// cevabını görebilsin. Sözleşmeden ayrı tutuluyor, çünkü sözleşme biter,
/// defter bitmez.
@immutable
class PropertyLedger {
  const PropertyLedger({
    required this.propertyItemId,
    this.rentCollected = 0,
    this.maintenanceSpent = 0,
    this.depositHeld = 0,
    this.vacantYears = 0,
    this.tenantCount = 0,
    this.lastMaintenanceAge,
    this.valueBasis,
  });

  final String propertyItemId;

  /// Bugüne kadar tahsil edilen kira (₺).
  final int rentCollected;

  /// Bakım ve tadilata harcanan (₺).
  final int maintenanceSpent;

  /// Elde tutulan depozito (₺). Kiracı çıkarken iade edilir.
  final int depositHeld;

  /// Kirada olmadığı (ve kiraya verilmeye çalışıldığı) yıl sayısı.
  final int vacantYears;

  /// Bu evde kaç kiracı oturdu?
  final int tenantCount;

  final int? lastMaintenanceAge;

  /// prototypeOnly: evin güncel tahmini değeri (₺).
  ///
  /// Boşsa alış fiyatı (ya da katalog değeri) esas alınır. Değer **sert
  /// bir piyasa motoruyla** değil; şehir, kondisyon ve geçen zamanla
  /// sınırlı biçimde hareket eder (D-163).
  final int? valueBasis;

  int get netCash => rentCollected - maintenanceSpent;

  PropertyLedger copyWith({
    int? rentCollected,
    int? maintenanceSpent,
    int? depositHeld,
    int? vacantYears,
    int? tenantCount,
    int? lastMaintenanceAge,
    int? valueBasis,
  }) =>
      PropertyLedger(
        propertyItemId: propertyItemId,
        rentCollected: rentCollected ?? this.rentCollected,
        maintenanceSpent: maintenanceSpent ?? this.maintenanceSpent,
        depositHeld: depositHeld ?? this.depositHeld,
        vacantYears: vacantYears ?? this.vacantYears,
        tenantCount: tenantCount ?? this.tenantCount,
        lastMaintenanceAge: lastMaintenanceAge ?? this.lastMaintenanceAge,
        valueBasis: valueBasis ?? this.valueBasis,
      );
}

/// Oyuncu kiradaysa **ev sahibi** kaydı.
///
/// İlişkiler ekranını doldurmamak için Person değil. Tek işi: yıllar
/// boyunca aynı kişinin kalması. Her olayda başka bir ev sahibi adı
/// çıkmasın diye kayda yazılır.
@immutable
class LandlordRecord {
  const LandlordRecord({
    required this.firstName,
    required this.lastName,
    required this.sinceAge,
    required this.temperament,
  });

  final String firstName;
  final String lastName;

  /// Oyuncunun bu ev sahibiyle tanıştığı yaş.
  final int sinceAge;

  final LandlordTemperament temperament;

  /// "Nihat Bey" gibi hitap.
  String get polite => '$firstName Bey';

  String get fullName => '$firstName $lastName';
}

/// Ev sahibinin huyu. Olay metinlerinin tonunu belirler.
enum LandlordTemperament {
  anlayisli('Anlayışlı'),
  olculu('Ölçülü'),
  sikistiran('Sıkıştıran');

  const LandlordTemperament(this.label);

  final String label;
}
