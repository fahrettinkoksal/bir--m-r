/// Kiracı adaylarının üretimi (D-163).
///
/// **Belirlenimli:** aday listesi (mülk kimliği, yaş, istenen kira) üçlüsünden
/// türer. Oyuncu Yatırımlar gibi ekranı kapatıp açarak yeni aday çeviremez,
/// kaydı geri yükleyince de aynı adaylar gelir.
///
/// İsim havuzu oyunun kendi havuzudur (`name_pool.dart`); gerçek bir kişiye
/// gönderme yapmaz. Meslekler gündelik hayattan, iddialı olmayan işler.
///
/// Bütün sayılar `prototypeOnly`'dir (Q-166).
library;

import 'dart:math';

import '../domain/models/owned_item.dart';
import '../domain/models/rental.dart';
import 'name_pool.dart';

/// prototypeOnly: bir ilanda gelebilecek en çok aday.
///
/// Alt sınır **yok**, bilerek: bazı yıllar hiç kimse aramaz. Piyasa
/// kirasında ortalama üç aday gelir (Poisson), fahiş kirada çoğu yıl
/// kimse aramaz.
const int kTenantMaxCandidates = 5;

/// Kiracı adaylarının meslek havuzu.
///
/// Gündelik işler; "CEO" ya da "cerrah" yok — oyuncunun dairesine başvuran
/// insanlar bunlar.
const List<String> kTenantOccupations = <String>[
  'çağrı merkezi çalışanı',
  'market kasiyeri',
  'kurye',
  'öğretmen',
  'hemşire',
  'sanayi ustası',
  'kamyon şoförü',
  'muhasebe elemanı',
  'kuaför',
  'garson',
  'güvenlik görevlisi',
  'tezgâhtar',
  'elektrik teknikeri',
  'lojistik görevlisi',
  'aşçı',
  'memur',
  'tekniker',
  'satış temsilcisi',
  'depo sorumlusu',
  'berber',
];

/// Kira bandının dışına çıkmanın aday sayısına etkisini hesaplarken
/// kullanılan ölçek; [tenantCandidates] içinde açıklandı.
double prototypeOnlyDemandFactor(double askRatio) {
  // 1,0 = piyasa kirası. Yukarı çıkınca talep hızlı düşer, aşağı inince
  // yavaş artar: gerçek hayatta da ucuz daireye kuyruk olur ama pahalı
  // daireye kimse bakmaz.
  if (askRatio <= 0.85) return 1.35;
  if (askRatio <= 0.95) return 1.15;
  if (askRatio <= 1.05) return 1.0;
  if (askRatio <= 1.20) return 0.65;
  if (askRatio <= 1.40) return 0.35;
  return 0.12;
}

/// Bu mülk için bu yıl başvuran adaylar.
///
/// [seed] mülk kimliği + yaş + istenen kiradan türer; aynı üçlü her zaman
/// aynı listeyi verir. [demand] şehir talebi ve istenen kiranın piyasaya
/// oranından gelen çarpandır: 1'in altında az aday, üstünde çok aday.
List<TenantRecord> tenantCandidates({
  required String propertyId,
  required int age,
  required int askingRent,
  required double demand,
}) {
  final Random rng = Random(_seedOf(propertyId, age, askingRent));

  // **Aday sayısı Poisson çekiliyor.** Tek mekanizma: ortalama talebe
  // bağlı, sıfır da doğal bir sonuç. İki ara model denendi ve ölçümle
  // elendi:
  //
  // 1. `beklenen.floor()` + kesirli yuvarlama: piyasa kirasında ortalama
  //    tam 3 çıkıyordu ve **hiç sıfır gelmiyordu**; 10.000 konut-yılında
  //    doluluk %100 ölçüldü, ev bir yıl bile boş kalmadı.
  // 2. Ayrı bir "kimse aramadı" zarı + en az bir aday: bu kez piyasanın
  //    2,2 katı kira isteyen eve bile %55 ihtimalle aday geliyordu.
  //
  // Poisson ikisini de tek formülle çözüyor: ortalama 3 iken sıfır
  // ihtimali ~%5 (ev bazı yıllar boş kalır), ortalama 0,36'ya inince
  // ~%70 (fahiş kira isteyen eve kimse bakmaz).
  final double ortalama = 3.0 * demand;
  final int sayi = _poisson(ortalama, rng).clamp(0, kTenantMaxCandidates);
  if (sayi == 0) return const <TenantRecord>[];

  return <TenantRecord>[
    for (int i = 0; i < sayi; i++) _candidate(rng, propertyId, age, i),
  ];
}

TenantRecord _candidate(Random rng, String propertyId, int age, int index) {
  final bool kadin = rng.nextBool();
  final String ad = kadin
      ? kadinIsimleri[rng.nextInt(kadinIsimleri.length)]
      : erkekIsimleri[rng.nextInt(erkekIsimleri.length)];
  final String soyad = soyisimler[rng.nextInt(soyisimler.length)];
  final int yas = 22 + rng.nextInt(38);
  final String meslek = kTenantOccupations[rng.nextInt(
    kTenantOccupations.length,
  )];

  final TenantHousehold hane = _household(rng, yas);
  final TenantIncome gelir = _income(rng);

  // **Gizli güvenilirlik görünen geçmişle birebir aynı değil, bilerek.**
  // Gelir bandı ve hane durumu ortalamayı kaydırır ama sonucu belirlemez:
  // "İyi" görünen aday sıkışabilir, "Karışık" görünen aday yıllarca
  // düzenli ödeyebilir. Oyuncu kiracıyı seçerken risk alır.
  final int taban = switch (gelir) {
    TenantIncome.iyi => 68,
    TenantIncome.orta => 58,
    TenantIncome.dusuk => 46,
  };
  final int guvenilirlik = (taban + rng.nextInt(45) - 20).clamp(5, 98);
  final int kollama = (52 + rng.nextInt(50) - 22).clamp(5, 98);

  return TenantRecord(
    id: 'kiraci-$propertyId-$age-$index',
    firstName: ad,
    lastName: soyad,
    age: yas,
    occupation: meslek,
    household: hane,
    income: gelir,
    track: _track(guvenilirlik, rng),
    reliability: guvenilirlik,
    care: kollama,
  );
}

TenantHousehold _household(Random rng, int yas) {
  if (yas < 26) {
    return rng.nextDouble() < 0.45
        ? TenantHousehold.ogrenciler
        : TenantHousehold.tekBasina;
  }
  final double d = rng.nextDouble();
  if (d < 0.30) return TenantHousehold.tekBasina;
  if (d < 0.58) return TenantHousehold.cift;
  return TenantHousehold.cocukluAile;
}

TenantIncome _income(Random rng) {
  final double d = rng.nextDouble();
  if (d < 0.28) return TenantIncome.dusuk;
  if (d < 0.78) return TenantIncome.orta;
  return TenantIncome.iyi;
}

/// Görünen ödeme geçmişi: gizli güvenilirliğin **bulanık** yansıması.
TenantTrack _track(int guvenilirlik, Random rng) {
  final int gorunen = (guvenilirlik + rng.nextInt(31) - 15).clamp(0, 100);
  if (gorunen >= 68) return TenantTrack.iyi;
  if (gorunen >= 42) return TenantTrack.belirsiz;
  return TenantTrack.zayif;
}

/// Eski kayıttan (yalnızca `rentedOut` bayrağı olan) devralınan kiracı.
///
/// Kayıt göçünde kullanılır: bayrağı taşıyan konut için mülk kimliğinden
/// türeyen tek bir kiracı üretilir. Aynı kayıt her açılışta aynı kiracıyı
/// verir; oyuncunun kirası kesilmez.
TenantRecord migratedTenantFor(String propertyId) {
  final Random rng = Random(_seedOf(propertyId, 0, 0));
  return _candidate(rng, propertyId, 0, 0);
}

/// FNV-1a: `String.hashCode` Dart sürümleri arasında değişebilir, bu sayı
/// sabit kalır. Kayıt geri yüklenince aynı adayların gelmesi buna bağlı.
int _seedOf(String propertyId, int age, int askingRent) {
  int h = 0x811c9dc5;
  void karistir(String metin) {
    for (final int kod in metin.codeUnits) {
      h = (h ^ kod) & 0xffffffff;
      h = (h * 0x01000193) & 0xffffffff;
    }
  }

  karistir(propertyId);
  for (final int sayi in <int>[age, askingRent]) {
    h = (h ^ sayi) & 0xffffffff;
    h = (h * 0x01000193) & 0xffffffff;
  }
  return h;
}

/// prototypeOnly: eski kayıttan devralınan sözleşmenin yıllık kirası.
///
/// D-163'ten önceki tek formül buydu: katalog değerinin %4,5'i. Yeni
/// formül şehri ve kondisyonu da görüyor (`RentalEngine.marketRent`) ama
/// **göçte eski sayı korunuyor**: oyuncunun yürüyen sözleşmesini yükleme
/// sırasında zamlamak ya da indirmek olmaz. Sözleşme yenilenince yeni
/// formüle geçer.
int legacyYearlyRent(OwnedItem home) =>
    (home.type.baseValue * 0.045).round();

/// Poisson çekilişi (Knuth). Küçük ortalamalarda yeterli ve hızlı.
int _poisson(double mean, Random rng) {
  if (mean <= 0) return 0;
  final double limit = exp(-mean);
  double p = 1;
  int k = 0;
  while (true) {
    p *= rng.nextDouble();
    if (p <= limit) return k;
    k++;
    if (k > 40) return k; // güvenlik: sonsuz döngü olmasın
  }
}
