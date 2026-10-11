/// **Evini döşemek** (Paket BT): evin içindeki eşyanın okunur hâli.
///
/// **Neden var.** Oyunda konut alınıyor, taşınılıyor, kiraya veriliyor;
/// ama evin **içi** boştu. Katalogda ev eşyası diye yalnızca çay takımı,
/// seccade ve bisiklet bakım seti vardı; buzdolabı olmayan bir evde
/// yaşamak hiçbir şey ifade etmiyordu
/// (`docs/NEXT_DEVELOPMENT_OPTIONS.md` §6).
///
/// **Model: eşya senin, binanın değil.** Döşeme, oturduğun evin değil,
/// **sahip olduğun ev eşyasının** hâli. Böylece taşınınca eşya seninle
/// gelir — oyun bunu zaten söylüyordu ("eşyalarını taşıdın",
/// `Housing.moveInto`) — ve eski kayıtlara yeni bir alan eklemek
/// gerekmez. İkinci bir evi ayrı döşemek (yazlığın kendi eşyası) ayrı
/// bir pakettir; soru ve gerekçe `docs/DESIGN_REVIEW_QUEUE.md` Q-216'da.
///
/// **Yuvalar.** Her yuva bir ihtiyaç: buzdolabı yuvası ya dolu ya boş.
/// Temel yuvalar evin yaşanabilir olmasını, konfor yuvaları iyi
/// olmasını anlatır. Seviye 0-100 arası ve `prototypeOnly`.
library;

import '../../data/item_catalog.dart';
import '../features/feature_catalog.dart';
import '../models/game_state.dart';
import '../models/owned_item.dart';
import 'housing.dart';

/// Bir döşeme yuvası: tek bir ihtiyaç ve onu karşılayan eşya türü.
class FurnishingSlot {
  const FurnishingSlot({
    required this.typeId,
    required this.need,
    required this.essential,
  });

  /// Katalogdaki eşya türü ([kItemTypes]).
  final String typeId;

  /// Yuvanın ne işe yaradığı; ekranda eşyanın altında yazar.
  final String need;

  /// Temel yuva mı? Temel yuva evin **yaşanabilir** olmasıyla ilgilidir.
  final bool essential;

  ItemType get type => itemTypeOrFallback(typeId);

  String get name => type.name;

  /// Sıfır fiyatı (katalogdan; ikinci bir fiyat tablosu yok).
  int get price => type.baseValue;
}

/// Döşeme hesabı. Hiçbir sayı `DECISIONS.md`'de değil: hepsi
/// `prototypeOnly` (Q-216).
class Furnishing {
  const Furnishing._();

  /// prototypeOnly: temel yuvaların seviyedeki toplam payı (%).
  ///
  /// Buzdolabısız ama televizyonlu bir ev "yarı döşenmiş" sayılmaz;
  /// temel yuvalar ağırlığın üçte ikisini taşır.
  static const int prototypeOnlyEssentialShare = 65;

  /// prototypeOnly: bir eşyanın yuvayı doldurması için gereken en küçük
  /// kondisyon. Altına düşen eşya **sayılmaz**: bozuk buzdolabı
  /// buzdolabı yerine geçmiyor. Tamir mevcut eylemle yapılır.
  static const int prototypeOnlyUsableCondition = 40;

  /// prototypeOnly: ev eşyasının yıllık yıpranması (en az / en çok).
  ///
  /// Yalnızca **oturulan evdeki** eşya yıpranır; kullanılmayan eşya
  /// eskimez. Sayılar küçük: bir buzdolabı on yılda bir tamir ister.
  static const int prototypeOnlyMinYearlyWear = 1;
  static const int prototypeOnlyMaxYearlyWear = 3;

  /// prototypeOnly: iyi döşenmiş evin yıllık mutluluk katkısı ve eşiği.
  ///
  /// Tek kademe, küçük sayı: ev döşemek bir strateji değil, paranın
  /// hayata dönüştüğü yerlerden biri. Düşük döşemeye **ceza yok**;
  /// parası olmayan oyuncu cezalandırılmaz.
  static const int prototypeOnlyComfortThreshold = 65;
  static const int prototypeOnlyComfortHappiness = 1;

  /// Yuvalar: önce temel, sonra konfor. Sıra ekranda da bu.
  static const List<FurnishingSlot> slots = <FurnishingSlot>[
    FurnishingSlot(
      typeId: 'buzdolabi',
      need: 'Yemek saklamak',
      essential: true,
    ),
    FurnishingSlot(
      typeId: 'camasir_makinesi',
      need: 'Çamaşır',
      essential: true,
    ),
    FurnishingSlot(
      typeId: 'firin_ocak',
      need: 'Yemek yapmak',
      essential: true,
    ),
    FurnishingSlot(
      typeId: 'yatak_odasi',
      need: 'Uyumak',
      essential: true,
    ),
    FurnishingSlot(
      typeId: 'koltuk_takimi',
      need: 'Oturmak',
      essential: true,
    ),
    FurnishingSlot(
      typeId: 'yemek_masasi',
      need: 'Sofra',
      essential: true,
    ),
    FurnishingSlot(
      typeId: 'televizyon',
      need: 'Akşamlar',
      essential: false,
    ),
    FurnishingSlot(
      typeId: 'klima',
      need: 'Yaz',
      essential: false,
    ),
    FurnishingSlot(
      typeId: 'bulasik_makinesi',
      need: 'Bulaşık',
      essential: false,
    ),
    FurnishingSlot(
      typeId: 'hali',
      need: 'Zemin',
      essential: false,
    ),
    FurnishingSlot(
      typeId: 'perde',
      need: 'Pencere',
      essential: false,
    ),
    FurnishingSlot(
      typeId: 'kitaplik',
      need: 'Kitaplar',
      essential: false,
    ),
    FurnishingSlot(
      typeId: 'elektrikli_supurge',
      need: 'Temizlik',
      essential: false,
    ),
    FurnishingSlot(
      typeId: 'mikrodalga',
      need: 'Isıtmak',
      essential: false,
    ),
    FurnishingSlot(
      typeId: 'su_isiticisi',
      need: 'Çay',
      essential: false,
    ),
    FurnishingSlot(
      typeId: 'utu',
      need: 'Ütü',
      essential: false,
    ),
    FurnishingSlot(
      typeId: 'avize',
      need: 'Aydınlatma',
      essential: false,
    ),
    FurnishingSlot(
      typeId: 'nevresim',
      need: 'Yatak takımı',
      essential: false,
    ),
  ];

  /// Modül anahtarı açık mı? (Paket BL sözleşmesi: tek kapı noktası.)
  static bool isOn(GameState state) =>
      state.settings.features.isOn(FeatureId.evDosemesi);

  /// Döşeme oyuncunun kendi hanesi için anlamlı mı?
  ///
  /// Ailesinin yanında yaşayan oyuncunun evini **o** döşemiyor; ekran da
  /// ondan bir şey istemez. Kirada ya da kendi evinde oturan herkes için
  /// anlamlıdır (kiralık ev de döşenir).
  static bool appliesTo(GameState state) =>
      isOn(state) &&
      Housing.residenceOf(state) != ResidenceKind.aileYaninda;

  /// Yuvayı dolduran eşya; yoksa `null`.
  ///
  /// Aynı türden iki eşya varsa **kondisyonu en iyi** olan sayılır.
  static OwnedItem? itemFor(GameState state, FurnishingSlot slot) {
    OwnedItem? enIyi;
    for (final OwnedItem i in state.items) {
      if (i.typeId != slot.typeId) continue;
      if (i.condition < prototypeOnlyUsableCondition) continue;
      if (enIyi == null || i.condition > enIyi.condition) enIyi = i;
    }
    return enIyi;
  }

  /// Yuva dolu mu?
  static bool filled(GameState state, FurnishingSlot slot) =>
      itemFor(state, slot) != null;

  /// Dolu temel yuva sayısı.
  static int essentialsFilled(GameState state) => slots
      .where((FurnishingSlot s) => s.essential && filled(state, s))
      .length;

  /// Toplam temel yuva sayısı.
  static int get essentialCount =>
      slots.where((FurnishingSlot s) => s.essential).length;

  /// Dolu konfor yuvası sayısı.
  static int comfortsFilled(GameState state) => slots
      .where((FurnishingSlot s) => !s.essential && filled(state, s))
      .length;

  /// Toplam konfor yuvası sayısı.
  static int get comfortCount =>
      slots.where((FurnishingSlot s) => !s.essential).length;

  /// 0-100 arası döşeme seviyesi.
  ///
  /// Temel yuvalar ağırlığın [prototypeOnlyEssentialShare] kadarını,
  /// konfor yuvaları kalanını taşır. Anahtar kapalıysa **sıfır**:
  /// kapalı modül hiçbir şeyi etkilemez (fail-closed).
  static int level(GameState state) {
    if (!isOn(state)) return 0;
    final int temel = essentialsFilled(state);
    final int konfor = comfortsFilled(state);
    final double temelPay =
        essentialCount == 0 ? 0 : temel / essentialCount;
    final double konforPay = comfortCount == 0 ? 0 : konfor / comfortCount;
    final double puan = temelPay * prototypeOnlyEssentialShare +
        konforPay * (100 - prototypeOnlyEssentialShare);
    return puan.round().clamp(0, 100);
  }

  /// Seviyenin okunaklı karşılığı (oyuncu diliyle).
  static String levelLabel(GameState state) {
    final int seviye = level(state);
    if (seviye == 0) return 'Ev bomboş';
    if (seviye < 30) return 'Daha çok eksik var';
    if (seviye < prototypeOnlyComfortThreshold) return 'İdare eder';
    if (seviye < 90) return 'Yaşanacak bir ev';
    return 'Her şeyi tamam';
  }

  /// Eksik yuvalar: önce temel olanlar, katalogdaki sıra korunur.
  static List<FurnishingSlot> missing(GameState state) => slots
      .where((FurnishingSlot s) => !filled(state, s))
      .toList(growable: false);

  /// Kondisyonu eşiğin altına düşmüş, yuvayı artık doldurmayan eşyalar.
  static List<OwnedItem> wornOut(GameState state) => state.items
      .where((OwnedItem i) =>
          i.condition < prototypeOnlyUsableCondition &&
          slots.any((FurnishingSlot s) => s.typeId == i.typeId))
      .toList(growable: false);

  /// Bu yılın mutluluk katkısı (0 ya da küçük bir artı).
  ///
  /// Ceza yoktur: döşeme eksikse katkı sıfırdır, mutluluk düşmez.
  static int yearlyHappiness(GameState state) {
    if (!appliesTo(state)) return 0;
    return level(state) >= prototypeOnlyComfortThreshold
        ? prototypeOnlyComfortHappiness
        : 0;
  }
}
