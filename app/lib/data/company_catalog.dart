/// Kurgusal şirketler ve sektörler (Paket AC).
///
/// **Hiçbiri gerçek değildir.** Ne ad, ne sektör payı, ne de olay örgüsü
/// gerçek bir şirketten, borsadan, bankadan ya da kişiden alınmadı.
/// Gerçek bir şirketle benzerlik kurulmaz ve kurulmamalıdır. Oyun canlı
/// fiyat çekmez, gerçek tarihsel veri kullanmaz.
///
/// **Neden var.** V1'de "Karma Hisse Sepeti" tek bir soyut endeksti:
/// sepetin içinde ne olduğu belli değildi, dolayısıyla "bir şirket battı"
/// anlatısı kurulamıyordu. Ölçümde çıkan sorun tam buydu — yatırım
/// risksiz bir servet makinesiydi, çünkü **kaybettirecek bir olayı
/// yoktu**. Sepet artık isimli kurgusal şirketlerden oluşuyor; biri
/// batınca sepet kendi payı kadar etkilenir, **sıfırlanmaz** (§9).
///
/// Sektör iki işe yarar: aynı sektördeki şirketler birlikte hareket eder
/// (sektör krizi / sektör patlaması olayları) ve haber metni sektörün
/// diliyle yazılır.
///
/// Bütün ağırlıklar ve paylar `prototypeOnly`'dir (Q-168).
library;

import 'package:flutter/foundation.dart';

/// Kurgusal sektör.
enum CompanySector {
  teknoloji('Teknoloji'),
  enerji('Enerji'),
  insaat('İnşaat'),
  gida('Gıda'),
  lojistik('Lojistik'),
  perakende('Perakende'),
  sanayi('Sanayi'),
  medya('Medya'),
  finans('Finans'),
  turizm('Turizm');

  const CompanySector(this.label);

  final String label;
}

/// Şirketin o andaki durumu.
///
/// Sıra **tek yönlü değildir**: konkordatodan çıkıp normale dönen şirket
/// olur. Yalnızca [kapandi] geri dönüşsüzdür.
enum CompanyStatus {
  /// Olağan.
  normal('Normal'),

  /// Denetim/regülatör incelemesi sürüyor; haber akışı gergin.
  inceleme('İnceleme altında'),

  /// Borçlarını çevirmekte zorlanıyor.
  sikinti('Mali sıkıntıda'),

  /// Konkordato süreci başladı.
  konkordato('Konkordato'),

  /// Yönetime geçici müdahale edildi.
  kayyum('Geçici yönetim'),

  /// Faaliyet durdu; sepetten çıktı. **Geri dönüşü yok.**
  kapandi('Faaliyet durdu');

  const CompanyStatus(this.label);

  final String label;

  /// Şirket hâlâ sepette değer üretiyor mu?
  bool get isActive => this != CompanyStatus.kapandi;

  /// Bu durumdan doğrudan iflasa gidilebilir mi?
  bool get canFail =>
      this == CompanyStatus.sikinti ||
      this == CompanyStatus.konkordato ||
      this == CompanyStatus.kayyum;
}

/// Kurgusal bir şirket.
@immutable
class Company {
  const Company({
    required this.id,
    required this.name,
    required this.sector,
    required this.basketWeight,
    required this.fragility,
  });

  final String id;

  /// Kurgusal ticari ad.
  final String name;

  final CompanySector sector;

  /// prototypeOnly: "Karma Hisse Sepeti" içindeki payı (0-1).
  ///
  /// Toplam 1,00 olacak biçimde yazıldı; [kCompanyBasketWeightSum] bunu
  /// testle sabitliyor. Bir şirketin batışının sepete etkisi bu paydır —
  /// en büyük pay bile sepetin beşte birinden azdır, çünkü tek bir haber
  /// sepetin çoğunu silmemeli (§9).
  final double basketWeight;

  /// prototypeOnly: kötü habere yatkınlık (0-1).
  ///
  /// Borçlu/çevrimsel sektörler daha kırılgan. Olay ihtimalini ölçekler;
  /// tek başına kader değildir.
  final double fragility;
}

/// prototypeOnly: oyundaki kurgusal şirketler.
///
/// On iki şirket, sekiz sektör. Paylar kasten eşit değil: sepette büyük
/// ve küçük şirketler var, böylece "hangi şirket battı" fark eder.
const List<Company> kCompanyCatalog = <Company>[
  Company(
    id: 'anka_teknoloji',
    name: 'Anka Teknoloji',
    sector: CompanySector.teknoloji,
    basketWeight: 0.14,
    fragility: 0.55,
  ),
  Company(
    id: 'pusula_yazilim',
    name: 'Pusula Yazılım',
    sector: CompanySector.teknoloji,
    basketWeight: 0.07,
    fragility: 0.60,
  ),
  Company(
    id: 'kuzey_enerji',
    name: 'Kuzey Enerji',
    sector: CompanySector.enerji,
    basketWeight: 0.13,
    fragility: 0.40,
  ),
  Company(
    id: 'bozkir_holding',
    name: 'Bozkır Holding',
    sector: CompanySector.finans,
    basketWeight: 0.12,
    fragility: 0.70,
  ),
  Company(
    id: 'doruk_yapi',
    name: 'Doruk Yapı',
    sector: CompanySector.insaat,
    basketWeight: 0.10,
    fragility: 0.80,
  ),
  Company(
    id: 'marmara_gida',
    name: 'Marmara Gıda',
    sector: CompanySector.gida,
    basketWeight: 0.10,
    fragility: 0.25,
  ),
  Company(
    id: 'atlas_lojistik',
    name: 'Atlas Lojistik',
    sector: CompanySector.lojistik,
    basketWeight: 0.08,
    fragility: 0.45,
  ),
  Company(
    id: 'vadi_perakende',
    name: 'Vadi Perakende',
    sector: CompanySector.perakende,
    basketWeight: 0.08,
    fragility: 0.35,
  ),
  Company(
    id: 'anadolu_makine',
    name: 'Anadolu Makine',
    sector: CompanySector.sanayi,
    basketWeight: 0.07,
    fragility: 0.40,
  ),
  Company(
    id: 'zirve_medya',
    name: 'Zirve Medya',
    sector: CompanySector.medya,
    basketWeight: 0.05,
    fragility: 0.65,
  ),
  Company(
    id: 'deniz_turizm',
    name: 'Deniz Turizm',
    sector: CompanySector.turizm,
    basketWeight: 0.04,
    fragility: 0.75,
  ),
  Company(
    id: 'ege_insaat',
    name: 'Ege İnşaat',
    sector: CompanySector.insaat,
    basketWeight: 0.02,
    fragility: 0.85,
  ),
];

/// Payların toplamı. Testle 1,00'de sabitlenir.
const double kCompanyBasketWeightSum = 1.0;

Company? companyById(String id) {
  for (final Company c in kCompanyCatalog) {
    if (c.id == id) return c;
  }
  return null;
}

/// Bu sektördeki şirketler.
List<Company> companiesInSector(CompanySector sector) => kCompanyCatalog
    .where((Company c) => c.sector == sector)
    .toList(growable: false);

/// prototypeOnly: tek bir şirketin batışının sepete verebileceği en büyük
/// zarar oranı.
///
/// Şirketin payı doğrudan uygulanmaz; batış zaten fiyata yayılmış olur ve
/// sepet o şirketi çıkarıp yerine başkasını alır. Bu yüzden etki payın bir
/// katsayısıdır ve üstüne bir tavan konur: **hiçbir tek haber sepetin
/// beşte birinden fazlasını silmez** (§9).
const double kSingleFailureBasketCap = 0.20;

/// prototypeOnly: batışın sepete yansıma katsayısı (payın kaçı).
const double kFailureWeightPassThrough = 0.85;
