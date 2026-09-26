/// Oyundaki eşya **türleri**.
///
/// Envanterdeki her eşya bir örnektir (`OwnedItem`) ve türünü buradan alır.
/// Ad, simge, temel değer ve hangi eylemlerin anlamlı olduğu tek yerde
/// tutulur; hediye kataloğu, mağaza ve Varlıklar ekranı aynı kaynağı
/// kullanır, ikinci bir envanter sistemi yoktur.
///
/// Değerler `prototypeOnly`'dir; onaylanmış ekonomi dengesi değildir
/// (`docs/DESIGN_REVIEW_QUEUE.md`, Q-041).
library;

import 'package:flutter/material.dart';

/// Eşyanın türü. Hangi eylemlerin anlamlı olduğunu belirler.
enum ItemKind {
  bisiklet,
  motosiklet,
  otomobil,

  /// Konut: daire, müstakil ev, villa.
  konut,
  saat,
  oyuncak,
  spor,
  kitap,
  kiyafet,
  elektronik,
  evEsyasi,
  kirtasiye,

  /// Başka bir eşyaya takılan parça.
  aksesuar,

  /// Takı ve kıymetli maden (D-134). Hediye sisteminde ayrı bir sınıf:
  /// çeyrek altın ile tavla aynı şey değildir.
  ///
  /// Yeni değerler listenin **sonuna** eklenir; eski kayıtlar bozulmasın.
  taki,

  /// Çiçek, kutu çikolata gibi **tüketilen** hediyeler.
  hediyelik,

  /// Masa oyunu: tavla, dama, satranç.
  masaOyunu,
}

/// Eşya üzerinde yapılabilecek eylem türleri.
enum ItemActionKind {
  /// Kullanmak: bisiklete binmek, saati takmak, oyuncakla oynamak.
  kullan,

  /// Temizlik: yalnızca kiri giderir, mekanik hasarı onarmaz.
  temizle,

  /// Bakım: ücretlidir ve kondisyonu sınırlı ölçüde iyileştirir.
  bakim,

  /// Uyumlu bir aksesuar takmak.
  aksesuarTak,

  /// Satmak.
  sat,
}

/// Bir eşya türü.
@immutable
class ItemType {
  const ItemType({
    required this.id,
    required this.name,
    required this.icon,
    required this.kind,
    required this.baseValue,
    this.fitsOn = const <ItemKind>{},
    this.special = false,
    this.segment,
  });

  /// Kalıcı tür kimliği (envanterde ve kayıtta kullanılır).
  final String id;
  final String name;
  final IconData icon;
  final ItemKind kind;

  /// prototypeOnly: sıfır hâldeki yaklaşık piyasa değeri (₺).
  final int baseValue;

  /// Aksesuarsa hangi eşya türlerine takılabildiği.
  final Set<ItemKind> fitsOn;

  /// Özel/antika nitelik. Değerlemede çarpan uygulanır; geniş bir antika
  /// kataloğu henüz yok, altyapı hazır.
  final bool special;

  /// Adı kurgusal bir model adı olan eşyalarda **sınıf/segment** satırı
  /// (D-136): "Foros Kent 1.4" adının altında "İkinci el otomobil" yazar.
  ///
  /// Faho'nun isteği: araç adları günümüz araçlarını çağrıştırsın ama
  /// gerçek marka olmasın. Ad kurgusal, segment bilgisi ayrı alanda
  /// duruyor; oyuncu neyi aldığını hâlâ görüyor.
  final String? segment;

  bool get isAccessory => kind == ItemKind.aksesuar;

  /// Bu aksesuar verilen türe takılabilir mi?
  bool canAttachTo(ItemType target) =>
      isAccessory && fitsOn.contains(target.kind);
}

const List<ItemType> kItemTypes = <ItemType>[
  // --- Araçlar ----------------------------------------------------------
  ItemType(
    id: 'bisiklet',
    name: 'Bisiklet',
    icon: Icons.pedal_bike_outlined,
    kind: ItemKind.bisiklet,
    baseValue: 28000,
  ),

  // --- Bisiklet aksesuarları --------------------------------------------
  ItemType(
    id: 'bisiklet_zili',
    name: 'Bisiklet zili',
    icon: Icons.notifications_active_outlined,
    kind: ItemKind.aksesuar,
    baseValue: 350,
    fitsOn: <ItemKind>{ItemKind.bisiklet},
  ),
  ItemType(
    id: 'bisiklet_kornasi',
    name: 'Bisiklet kornası',
    icon: Icons.campaign_outlined,
    kind: ItemKind.aksesuar,
    baseValue: 500,
    fitsOn: <ItemKind>{ItemKind.bisiklet},
  ),
  ItemType(
    id: 'bisiklet_reflektoru',
    name: 'Reflektör',
    icon: Icons.brightness_low_outlined,
    kind: ItemKind.aksesuar,
    baseValue: 300,
    fitsOn: <ItemKind>{ItemKind.bisiklet},
  ),
  ItemType(
    id: 'bisiklet_susu',
    name: 'Gidon süsü',
    icon: Icons.auto_awesome_outlined,
    kind: ItemKind.aksesuar,
    baseValue: 220,
    fitsOn: <ItemKind>{ItemKind.bisiklet},
  ),

  // --- Bakım malzemesi ---------------------------------------------------
  ItemType(
    id: 'bisiklet_bakim_seti',
    name: 'Bisiklet bakım seti',
    icon: Icons.build_outlined,
    kind: ItemKind.evEsyasi,
    baseValue: 1400,
  ),

  // --- Saatler ------------------------------------------------------------
  ItemType(
    id: 'kol_saati',
    name: 'Kol saati',
    icon: Icons.watch_outlined,
    kind: ItemKind.saat,
    baseValue: 6500,
  ),
  ItemType(
    id: 'antika_saat',
    name: 'Antika cep saati',
    icon: Icons.history_toggle_off_outlined,
    kind: ItemKind.saat,
    baseValue: 28000,
    special: true,
  ),

  // --- Oyuncaklar ---------------------------------------------------------
  ItemType(
    id: 'yoyo',
    name: 'Yo-yo',
    icon: Icons.sports_baseball_outlined,
    kind: ItemKind.oyuncak,
    baseValue: 180,
  ),
  ItemType(
    id: 'oyuncak_araba',
    name: 'Oyuncak araba',
    icon: Icons.toys_outlined,
    kind: ItemKind.oyuncak,
    baseValue: 450,
  ),
  ItemType(
    id: 'oyuncak_bebek',
    name: 'Oyuncak bebek',
    icon: Icons.child_friendly_outlined,
    kind: ItemKind.oyuncak,
    baseValue: 450,
  ),
  ItemType(
    id: 'bilye',
    name: 'Bilye torbası',
    icon: Icons.circle_outlined,
    kind: ItemKind.oyuncak,
    baseValue: 90,
  ),
  ItemType(
    id: 'ucurtma',
    name: 'Uçurtma',
    icon: Icons.air_outlined,
    kind: ItemKind.oyuncak,
    baseValue: 250,
  ),
  ItemType(
    id: 'pelus_oyuncak',
    name: 'Pelüş oyuncak',
    icon: Icons.pets_outlined,
    kind: ItemKind.oyuncak,
    baseValue: 650,
  ),
  ItemType(
    id: 'kutu_oyunu',
    name: 'Kutu oyunu',
    icon: Icons.casino_outlined,
    kind: ItemKind.oyuncak,
    baseValue: 1500,
  ),

  // --- Spor ---------------------------------------------------------------
  ItemType(
    id: 'futbol_topu',
    name: 'Futbol topu',
    icon: Icons.sports_soccer_outlined,
    kind: ItemKind.spor,
    baseValue: 1400,
  ),
  ItemType(
    id: 'spor_ayakkabi',
    name: 'Spor ayakkabı',
    icon: Icons.directions_run_outlined,
    kind: ItemKind.spor,
    baseValue: 4200,
  ),

  // --- Kitap ve kırtasiye --------------------------------------------------
  ItemType(
    id: 'boyama_kitabi',
    name: 'Boyama kitabı',
    icon: Icons.palette_outlined,
    kind: ItemKind.kirtasiye,
    baseValue: 180,
  ),
  ItemType(
    id: 'cizim_seti',
    name: 'Çizim seti',
    icon: Icons.draw_outlined,
    kind: ItemKind.kirtasiye,
    baseValue: 1100,
  ),
  ItemType(
    id: 'defter',
    name: 'Hatıra defteri',
    icon: Icons.book_outlined,
    kind: ItemKind.kirtasiye,
    baseValue: 350,
  ),
  ItemType(
    id: 'hikaye_kitabi',
    name: 'Hikâye kitabı',
    icon: Icons.menu_book_outlined,
    kind: ItemKind.kitap,
    baseValue: 420,
  ),
  ItemType(
    id: 'roman',
    name: 'Roman',
    icon: Icons.auto_stories_outlined,
    kind: ItemKind.kitap,
    baseValue: 700,
  ),

  // --- Kıyafet -------------------------------------------------------------
  ItemType(
    id: 'kiyafet',
    name: 'Yeni kıyafet',
    icon: Icons.checkroom_outlined,
    kind: ItemKind.kiyafet,
    baseValue: 2600,
  ),

  // --- Elektronik ----------------------------------------------------------
  ItemType(
    id: 'kulaklik',
    name: 'Kulaklık',
    icon: Icons.headphones_outlined,
    kind: ItemKind.elektronik,
    baseValue: 3400,
  ),
  ItemType(
    id: 'radyo',
    name: 'Küçük radyo',
    icon: Icons.radio_outlined,
    kind: ItemKind.elektronik,
    baseValue: 2600,
  ),

  // --- Ev eşyası ------------------------------------------------------------
  ItemType(
    id: 'cay_takimi',
    name: 'Çay takımı',
    icon: Icons.emoji_food_beverage_outlined,
    kind: ItemKind.evEsyasi,
    baseValue: 2400,
  ),

  // --- Elektronik -------------------------------------------------------
  ItemType(
    id: 'telefon',
    name: 'Akıllı telefon',
    icon: Icons.smartphone_outlined,
    kind: ItemKind.elektronik,
    baseValue: 45000,
  ),
  ItemType(
    id: 'bilgisayar',
    name: 'Dizüstü bilgisayar',
    icon: Icons.laptop_mac_outlined,
    kind: ItemKind.elektronik,
    baseValue: 65000,
  ),
  ItemType(
    id: 'oyun_konsolu',
    name: 'Oyun konsolu',
    icon: Icons.sports_esports_outlined,
    kind: ItemKind.elektronik,
    baseValue: 38000,
  ),
  ItemType(
    id: 'akilli_saat',
    name: 'Akıllı saat',
    icon: Icons.watch_outlined,
    kind: ItemKind.saat,
    baseValue: 17000,
  ),

  // --- Spor ve hobi -----------------------------------------------------
  ItemType(
    id: 'gitar',
    name: 'Gitar',
    icon: Icons.music_note_outlined,
    kind: ItemKind.spor,
    baseValue: 13000,
  ),
  ItemType(
    id: 'kamp_cadiri',
    name: 'Kamp çadırı',
    icon: Icons.cabin_outlined,
    kind: ItemKind.spor,
    baseValue: 9000,
  ),
  ItemType(
    id: 'agirlik_seti',
    name: 'Ağırlık seti',
    icon: Icons.fitness_center_outlined,
    kind: ItemKind.spor,
    baseValue: 8000,
  ),

  // --- Motosikletler ----------------------------------------------------
  ItemType(
    id: 'motosiklet_ekonomik',
    name: 'Rüzgâr 250',
    segment: 'Ekonomik motosiklet',
    icon: Icons.two_wheeler_outlined,
    kind: ItemKind.motosiklet,
    baseValue: 190000,
  ),
  ItemType(
    id: 'motosiklet_guclu',
    name: 'Sarp 750',
    segment: 'Güçlü motosiklet',
    icon: Icons.two_wheeler,
    kind: ItemKind.motosiklet,
    baseValue: 420000,
  ),
  // D-079: galeriler ayrıldığı için her kademede birden fazla seçenek
  // gerekiyor; tek modelli bir galeri raf değil, vitrin olurdu.
  ItemType(
    id: 'motosiklet_scooter',
    name: 'Rüzgâr Scoot 125',
    segment: 'Scooter',
    icon: Icons.electric_scooter_outlined,
    kind: ItemKind.motosiklet,
    baseValue: 96000,
  ),
  ItemType(
    id: 'motosiklet_tur',
    name: 'Sarp 1100 Tur',
    segment: 'Tur motosikleti',
    icon: Icons.motorcycle_outlined,
    kind: ItemKind.motosiklet,
    baseValue: 780000,
  ),

  // --- Motosiklet aksesuarları -----------------------------------------
  ItemType(
    id: 'kask',
    name: 'Motosiklet kaskı',
    icon: Icons.sports_motorsports_outlined,
    kind: ItemKind.aksesuar,
    baseValue: 9500,
    fitsOn: <ItemKind>{ItemKind.motosiklet},
  ),
  ItemType(
    id: 'motosiklet_cantasi',
    name: 'Motosiklet çantası',
    icon: Icons.work_outline,
    kind: ItemKind.aksesuar,
    baseValue: 6500,
    fitsOn: <ItemKind>{ItemKind.motosiklet},
  ),
  ItemType(
    id: 'motosiklet_cami',
    name: 'Rüzgâr siperi',
    icon: Icons.shield_outlined,
    kind: ItemKind.aksesuar,
    baseValue: 5200,
    fitsOn: <ItemKind>{ItemKind.motosiklet},
  ),

  // --- Otomobiller ------------------------------------------------------
  ItemType(
    id: 'otomobil_ikinci_el',
    name: 'Foros Kent 1.4',
    segment: 'İkinci el otomobil',
    icon: Icons.directions_car_filled_outlined,
    kind: ItemKind.otomobil,
    baseValue: 850000,
  ),
  ItemType(
    id: 'otomobil_ekonomik',
    name: 'Tunca Ege 1.2',
    segment: 'Ekonomik otomobil',
    icon: Icons.directions_car_outlined,
    kind: ItemKind.otomobil,
    baseValue: 1650000,
  ),
  ItemType(
    id: 'otomobil_orta',
    name: 'Veran Sedan 1.6',
    segment: 'Orta sınıf otomobil',
    icon: Icons.directions_car,
    kind: ItemKind.otomobil,
    baseValue: 2600000,
  ),
  ItemType(
    id: 'otomobil_luks',
    name: 'Alvera Salon 2.0',
    segment: 'Lüks otomobil',
    icon: Icons.car_rental_outlined,
    kind: ItemKind.otomobil,
    baseValue: 6800000,
  ),
  // D-079: üç galeri için üç kademe.
  //
  // D-136: adlar artık kurgusal marka+model adları (Foros, Tunca, Veran,
  // Doruk, Alvera, Sarp, Rüzgâr). Hiçbiri gerçek bir marka veya model
  // değildir; lisans sorunu doğurmaz. Sınıf bilgisi [ItemType.segment]
  // alanında ayrı durur, böylece oyuncu "Foros Kent 1.4"ün ikinci el bir
  // otomobil olduğunu ekranda görür.
  ItemType(
    id: 'otomobil_hurdaya_yakin',
    name: 'Foros 1.0',
    segment: 'Çok yıpranmış otomobil',
    icon: Icons.no_crash_outlined,
    kind: ItemKind.otomobil,
    baseValue: 320000,
  ),
  ItemType(
    id: 'otomobil_aile',
    name: 'Tunca Ferah 1.6',
    segment: 'Aile otomobili',
    icon: Icons.airport_shuttle_outlined,
    kind: ItemKind.otomobil,
    baseValue: 2050000,
  ),
  ItemType(
    id: 'otomobil_arazi',
    name: 'Doruk Yayla 4x4',
    segment: 'Arazi aracı',
    icon: Icons.terrain_outlined,
    kind: ItemKind.otomobil,
    baseValue: 3400000,
  ),
  ItemType(
    id: 'otomobil_spor',
    name: 'Sarp Coupe 3.0',
    segment: 'Spor otomobil',
    icon: Icons.sports_score_outlined,
    kind: ItemKind.otomobil,
    baseValue: 9500000,
  ),
  ItemType(
    id: 'otomobil_prestij',
    name: 'Alvera Prestij 4.0',
    segment: 'Prestij otomobili',
    icon: Icons.workspace_premium_outlined,
    kind: ItemKind.otomobil,
    baseValue: 14500000,
  ),

  // --- Otomobil aksesuarları -------------------------------------------
  ItemType(
    id: 'arac_kamerasi',
    name: 'Araç kamerası',
    icon: Icons.videocam_outlined,
    kind: ItemKind.aksesuar,
    baseValue: 7000,
    fitsOn: <ItemKind>{ItemKind.otomobil},
  ),
  ItemType(
    id: 'bebek_koltugu',
    name: 'Bebek koltuğu',
    icon: Icons.child_friendly_outlined,
    kind: ItemKind.aksesuar,
    baseValue: 11000,
    fitsOn: <ItemKind>{ItemKind.otomobil},
  ),
  ItemType(
    id: 'tavan_bagaji',
    name: 'Tavan bagajı',
    icon: Icons.luggage_outlined,
    kind: ItemKind.aksesuar,
    baseValue: 15000,
    fitsOn: <ItemKind>{ItemKind.otomobil},
  ),

  // --- Konutlar ---------------------------------------------------------
  ItemType(
    id: 'kucuk_daire',
    name: 'Küçük daire',
    icon: Icons.apartment_outlined,
    kind: ItemKind.konut,
    baseValue: 3200000,
  ),
  ItemType(
    id: 'standart_daire',
    name: 'Standart daire',
    icon: Icons.apartment,
    kind: ItemKind.konut,
    baseValue: 5400000,
  ),
  ItemType(
    id: 'mustakil_ev',
    name: 'Müstakil ev',
    icon: Icons.house_outlined,
    kind: ItemKind.konut,
    baseValue: 8800000,
  ),
  ItemType(
    id: 'villa',
    name: 'Büyük ev / villa',
    icon: Icons.villa_outlined,
    kind: ItemKind.konut,
    baseValue: 16000000,
  ),
  // --- Takı ve hediyelik (D-134) -----------------------------------------
  //
  // Faho'nun istediği hediyeler: tavla, buket çiçek, çeyrek altın, bilezik.
  // Fiyatlar 2026 Türkiye'sine göre `prototypeOnly`'dir (Q-148).
  ItemType(
    id: 'ceyrek_altin',
    name: 'Çeyrek altın',
    icon: Icons.stars_rounded,
    kind: ItemKind.taki,
    // 2026'da çeyrek altın beş haneli tutarlara yaklaştı; sayı onay
    // bekliyor.
    baseValue: 11500,
  ),
  ItemType(
    id: 'gram_altin',
    name: 'Gram altın',
    icon: Icons.circle_outlined,
    kind: ItemKind.taki,
    baseValue: 6800,
  ),
  ItemType(
    id: 'bilezik',
    name: 'Altın bilezik',
    icon: Icons.brightness_1_outlined,
    kind: ItemKind.taki,
    baseValue: 42000,
  ),
  ItemType(
    id: 'kolye',
    name: 'Kolye',
    icon: Icons.diamond_outlined,
    kind: ItemKind.taki,
    baseValue: 9500,
  ),
  ItemType(
    id: 'kupe',
    name: 'Küpe',
    icon: Icons.blur_circular_outlined,
    kind: ItemKind.taki,
    baseValue: 5200,
  ),
  ItemType(
    id: 'cicek_buketi',
    name: 'Buket çiçek',
    icon: Icons.local_florist_outlined,
    kind: ItemKind.hediyelik,
    baseValue: 900,
  ),
  ItemType(
    id: 'kutu_cikolata',
    name: 'Kutu çikolata',
    icon: Icons.cake_outlined,
    kind: ItemKind.hediyelik,
    baseValue: 650,
  ),
  ItemType(
    id: 'parfum',
    name: 'Parfüm',
    icon: Icons.air_outlined,
    kind: ItemKind.hediyelik,
    baseValue: 3800,
  ),
  ItemType(
    id: 'tavla',
    name: 'Tavla',
    icon: Icons.grid_view_rounded,
    kind: ItemKind.masaOyunu,
    baseValue: 1400,
  ),
  ItemType(
    id: 'satranc',
    name: 'Satranç takımı',
    icon: Icons.castle_outlined,
    kind: ItemKind.masaOyunu,
    baseValue: 1100,
  ),
  ItemType(
    id: 'kasmir_atki',
    name: 'Kaşmir atkı',
    icon: Icons.dry_cleaning_outlined,
    kind: ItemKind.kiyafet,
    baseValue: 2400,
  ),
  ItemType(
    id: 'seccade',
    name: 'Seccade',
    icon: Icons.texture_outlined,
    kind: ItemKind.evEsyasi,
    baseValue: 1800,
  ),
  ItemType(
    id: 'kahve_makinesi',
    name: 'Kahve makinesi',
    icon: Icons.coffee_maker_outlined,
    kind: ItemKind.elektronik,
    baseValue: 7200,
  ),

];

ItemType? itemTypeById(String id) {
  for (final ItemType t in kItemTypes) {
    if (t.id == id) return t;
  }
  return null;
}

/// Tanınmayan tür için kullanılan yedek tanım; kayıt bozulsa bile arayüz
/// çökmez, eşya "bilinmeyen" olarak görünür.
ItemType itemTypeOrFallback(String id) =>
    itemTypeById(id) ??
    ItemType(
      id: id,
      name: id,
      icon: Icons.inventory_2_outlined,
      kind: ItemKind.evEsyasi,
      baseValue: 0,
    );

/// Bir tür üzerinde anlamlı olan eylemler.
///
/// Yanlış türde eylem hiç gösterilmez: kol saatine korna takılmaz, kitap
/// sürülmez.
Set<ItemActionKind> actionsFor(ItemKind kind) {
  switch (kind) {
    case ItemKind.bisiklet:
    case ItemKind.motosiklet:
    case ItemKind.otomobil:
      return <ItemActionKind>{
        ItemActionKind.kullan,
        ItemActionKind.temizle,
        ItemActionKind.bakim,
        ItemActionKind.aksesuarTak,
        ItemActionKind.sat,
      };
    case ItemKind.konut:
      // Konutta sürme/aksesuar yok; ilk sürümde sahiplik ve satış çalışır.
      return <ItemActionKind>{ItemActionKind.sat};
    case ItemKind.saat:
    case ItemKind.elektronik:
      return <ItemActionKind>{
        ItemActionKind.kullan,
        ItemActionKind.temizle,
        ItemActionKind.bakim,
        ItemActionKind.sat,
      };
    case ItemKind.oyuncak:
    case ItemKind.spor:
    case ItemKind.kiyafet:
    // Masa oyunu oynanır, temizlenir, satılır (D-134).
    case ItemKind.masaOyunu:
      return <ItemActionKind>{
        ItemActionKind.kullan,
        ItemActionKind.temizle,
        ItemActionKind.sat,
      };
    // Takı takılır, temizlenir, satılır; bakımı yoktur (D-134).
    case ItemKind.taki:
      return <ItemActionKind>{
        ItemActionKind.kullan,
        ItemActionKind.temizle,
        ItemActionKind.sat,
      };
    // Çiçek ve çikolata tüketilir: satılmaz, bakımı yapılmaz.
    case ItemKind.hediyelik:
      return <ItemActionKind>{ItemActionKind.kullan};
    case ItemKind.evEsyasi:
    case ItemKind.kirtasiye:
      return <ItemActionKind>{ItemActionKind.temizle, ItemActionKind.sat};
    case ItemKind.kitap:
      // Kitap okuma Aktiviteler paketinde gelecek (Q-043); burada
      // yazılmamış bir eylem düğme olarak gösterilmez.
      return <ItemActionKind>{ItemActionKind.sat};
    case ItemKind.aksesuar:
      return <ItemActionKind>{ItemActionKind.sat};
  }
}

/// Eylem düğmesinin türe göre okunaklı adı.
String actionLabel(ItemActionKind action, ItemKind kind) {
  switch (action) {
    case ItemActionKind.kullan:
      switch (kind) {
        case ItemKind.bisiklet:
          return 'Bisiklete bin';
        case ItemKind.motosiklet:
          return 'Motosikleti sür';
        case ItemKind.otomobil:
          return 'Otomobili sür';
        case ItemKind.saat:
          return 'Tak';
        case ItemKind.oyuncak:
          return 'Oyna';
        case ItemKind.spor:
          return 'Spor yap';
        case ItemKind.kiyafet:
          return 'Giy';
        case ItemKind.elektronik:
          return 'Kullan';
        default:
          return 'Kullan';
      }
    case ItemActionKind.temizle:
      switch (kind) {
        case ItemKind.saat:
          return 'Parlat';
        case ItemKind.kiyafet:
          return 'Yıka';
        default:
          return 'Temizle';
      }
    case ItemActionKind.bakim:
      return 'Bakım yap';
    case ItemActionKind.aksesuarTak:
      return 'Aksesuar tak';
    case ItemActionKind.sat:
      return 'Sat';
  }
}
