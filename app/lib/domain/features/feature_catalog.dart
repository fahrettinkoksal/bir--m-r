import 'package:flutter/foundation.dart';

/// Çıkarılabilir özellik kataloğu — **modül anahtarları**.
///
/// Amaç: Claude'un eklediği her yeni özellik, beğenilmezse genel yapı
/// bozulmadan çıkarılabilsin. Kumarhane bunu zaten tek bir özellik için
/// yapıyordu (D-032: kapalıyken menüde hiç görünmez); bu katalog aynı
/// kalıbı **kurala** çeviriyor.
///
/// Sözleşme (bkz. `docs/FEATURE_FLAGS.md`):
///
/// 1. Her yeni özellik buraya bir satır olarak girer ve koddaki **tek bir
///    kapı noktasından** anahtara bakar.
/// 2. Anahtar kapalıyken özellik hem ekranda görünmez hem de motor
///    tarafından reddedilir (fail-closed). Yarı açık hâl yoktur.
/// 3. Anahtar kapalıyken oyunun geri kalanı çalışmaya devam eder; bunu
///    `test/paket_bl_modul_izolasyon_test.dart` her anahtar için ölçer.
/// 4. Tamamen silinecekse: anahtarı kapat, `FeatureId.<ad>` araması yap,
///    [removableFiles] içindeki dosyaları sil, sonra enum satırını sil —
///    kalan bütün bağları derleyici gösterir.
///
/// Katalogdaki hiçbir satır kalıcı oyun kuralı değildir; `DECISIONS.md`
/// yalnızca Faho'nun sohbette onayladığı kararları tutar.
enum FeatureId {
  /// Paket BK/1 — gebeliğin ekranda görünmesi.
  gebelikGorunurlugu(
    saveKey: 'gebelik_gorunurlugu',
    title: 'Gebelik bildirimi',
    lostWhenOff:
        'Bekleyen doğum hayat ve ilişkiler ekranında yazmaz; bebek yine '
        'doğar ama önceden haber verilmez.',
    paket: 'Paket BK — ebeveynlik',
    removableFiles: <String>[
      'app/lib/ui/widgets/pregnancy_notice.dart',
      'app/test/pregnancy_visibility_test.dart',
    ],
  ),

  /// Paket BK/2 — çiftin çocuk planı ve "çocuk deneme" yolu.
  cocukPlani(
    saveKey: 'cocuk_plani',
    title: 'Çocuk planı',
    lostWhenOff:
        'Eşinle çocuk konusunu konuşma seçeneği kalkar; çocuk yalnızca '
        'korunmasız birlikte olmakla gelir.',
    paket: 'Paket BK — ebeveynlik',
    removableFiles: <String>[
      'app/lib/domain/interaction/family_planning.dart',
      'app/test/paket_bk_cocuk_plani_test.dart',
    ],
  ),

  /// Paket BK/3 — çocuğa özel eylemler (ödev, harçlık, hobiye yazdırma).
  ebeveynlikEylemleri(
    saveKey: 'ebeveynlik_eylemleri',
    title: 'Çocuğa özel eylemler',
    lostWhenOff:
        'Ödevine oturma, harçlık verme ve hobiye yazdırma satırları '
        'çocuğun kartında çıkmaz; sohbet, vakit geçirme ve hediye kalır.',
    paket: 'Paket BK — ebeveynlik',
    removableFiles: <String>[
      'app/test/paket_bk_cocuk_eylemleri_test.dart',
    ],
  ),

  /// Paket BK/3 — kural koyma ve kuralın okul sorununa etkisi.
  cocukKurallari(
    saveKey: 'cocuk_kurallari',
    title: 'Çocuğa kural koyma',
    lostWhenOff:
        'Kural koyma satırı kalkar; okul sorunlarının ihtimali yalnızca '
        'çocuğun kendi kaydına bakar.',
    paket: 'Paket BK — ebeveynlik',
    removableFiles: <String>[
      'app/lib/domain/family/child_rules.dart',
    ],
  ),

  /// Paket BK/5 — çocuğun yıl özeti.
  cocukYilOzeti(
    saveKey: 'cocuk_yil_ozeti',
    title: 'Çocuğun yıl özeti',
    lostWhenOff:
        'Yıl özetinde çocuğun o yıl ne yaşadığı ayrı bir blok olarak '
        'görünmez; kendi kartından yine okunur.',
    paket: 'Paket BK — ebeveynlik',
    removableFiles: <String>[
      'app/test/paket_bk_cocuk_yil_ozeti_test.dart',
    ],
  ),

  /// Paket BM — 0-7 yaş olay havuzu ve ilk yılların karşılıkları.
  ilkYillarOlaylari(
    saveKey: 'ilk_yillar_olaylari',
    title: 'İlk yıllar olayları',
    lostWhenOff:
        'Bebeklik ve okul öncesi yıllarında çıkan yeni olaylar kalkar; '
        'ilk yıllar daha sessiz geçer.',
    paket: 'Paket BM — ilk yıllar',
    removableFiles: <String>[
      'app/lib/data/event_pool_early_years.dart',
      'app/test/paket_bm_ilk_yillar_test.dart',
    ],
  ),

  /// Paket BN — 16-20 yaş olay havuzu ve eşikteki yılların karşılıkları.
  esiktekiYillar(
    saveKey: 'esikteki_yillar',
    title: 'Eşikteki yıllar',
    lostWhenOff:
        'Lise sonu, tercih, ilk iş, evden çıkma ve dağılan arkadaş '
        'grubu olayları kalkar; 16-20 yaş daha sessiz geçer.',
    paket: 'Paket BN — eşikteki yıllar',
    removableFiles: <String>[
      'app/lib/data/event_pool_threshold_years.dart',
      'app/test/paket_bn_esikteki_yillar_test.dart',
    ],
  ),

  /// Paket BP — oturulan evin olayları.
  oturulanEv(
    saveKey: 'oturulan_ev',
    title: 'Oturduğun ev',
    lostWhenOff:
        'Kombi, çatı, küf, apartman toplantısı, komşu ve dönüşüm '
        'olayları kalkar; kendi evinde oturmak yine sessiz geçer.',
    paket: 'Paket BP — oturduğun ev',
    removableFiles: <String>[
      'app/lib/data/event_pool_home.dart',
      'app/test/paket_bp_oturulan_ev_test.dart',
    ],
  ),

  /// Paket BT — evini döşemek: ev eşyası yuvaları, döşeme seviyesi,
  /// yıllık yıpranma ve "Evinin hâli" ekranı.
  evDosemesi(
    saveKey: 'ev_dosemesi',
    title: 'Evini döşemek',
    lostWhenOff:
        'Evinin hâli ekranı ve döşeme seviyesi kalkar; ev eşyası yine '
        'alınır ama evin dolu olup olmadığı hiçbir şeyi değiştirmez.',
    paket: 'Paket BT — evini döşemek',
    removableFiles: <String>[
      'app/lib/domain/economy/furnishing.dart',
      'app/lib/ui/screens/sections/furnishing_page.dart',
      'app/test/paket_bt_ev_dosemesi_test.dart',
    ],
  ),

  /// Paket BU — komşular: oturulan eve bağlı, adı olan kişiler.
  komsular(
    saveKey: 'komsular',
    title: 'Komşular',
    lostWhenOff:
        'Apartmanda adı olan komşu olmaz; ilişkiler ekranındaki Komşular '
        'bölümü ve komşu olayları çıkmaz. Kendi evinde oturmak Paket '
        'BP\'nin olaylarıyla devam eder.',
    paket: 'Paket BU — komşular',
    removableFiles: <String>[
      'app/lib/domain/generation/neighbours.dart',
      'app/lib/data/event_pool_neighbour.dart',
      'app/test/paket_bu_komsular_test.dart',
    ],
  ),

  /// Paket BX — sürdürülen uğraşa öncelik: oyuncunun şu an içinde olduğu
  /// okul kulübü ya da hobinin olayları yıllık çekilişte öne geçer.
  ugrasOnceligi(
    saveKey: 'ugras_onceligi',
    title: 'Sürdürülen uğraşa öncelik',
    lostWhenOff:
        'Kulüp ve hobi olayları yıllık çekilişte genel havuzla aynı '
        'ağırlıkta yarışır. İçerik kaybolmaz ama ölçümde görüldüğü gibi '
        'okul yıllarında neredeyse hiç çıkmaz.',
    paket: 'Paket BX — sürdürülen uğraşa öncelik',
    removableFiles: <String>[
      'app/test/paket_bx_ugras_onceligi_test.dart',
    ],
  );

  const FeatureId({
    required this.saveKey,
    required this.title,
    required this.lostWhenOff,
    required this.paket,
    this.removableFiles = const <String>[],
  });

  /// Kayıtta duran kalıcı anahtar. **Değiştirilmez**: eski kayıtlar bu
  /// metni arar. Enum adını değiştirsen bile bunu koru.
  final String saveKey;

  /// Ayarlar ekranında görünen ad.
  final String title;

  /// Kapatınca neyin kaybolduğu. Ayarlar ekranında aynen gösterilir, bu
  /// yüzden oyuncu diliyle yazılır (`docs/WRITING_STYLE_TR.md`).
  final String lostWhenOff;

  /// Özelliği getiren paket; ayarlar ekranı buna göre gruplar.
  final String paket;

  /// Yalnızca bu özellik için var olan, silinince başka hiçbir şeyi
  /// bozmayan dosyalar (depo köküne göre). Katalog bekçisi bu yolların
  /// gerçekten durduğunu her koşuda doğrular.
  final List<String> removableFiles;

  /// Yeni hayatta açık mı gelir?
  ///
  /// Bugün katalogdaki her özellik açık gelir. Kapalı başlaması gereken
  /// deneysel bir modül çıktığında bu, kurucu parametresine geri
  /// çevrilir; kayıt biçimi değişmez çünkü kayıtta yalnızca
  /// varsayılandan **sapmalar** durur.
  bool get defaultOn => true;

  /// Kayıttaki anahtardan özelliği bul; tanınmayan anahtar `null`.
  static FeatureId? byKey(String key) {
    for (final FeatureId id in FeatureId.values) {
      if (id.saveKey == key) return id;
    }
    return null;
  }

  /// Paket başlığına göre sıralı gruplar (ayarlar ekranı için).
  static Map<String, List<FeatureId>> get byPaket {
    final Map<String, List<FeatureId>> gruplar = <String, List<FeatureId>>{};
    for (final FeatureId id in FeatureId.values) {
      gruplar.putIfAbsent(id.paket, () => <FeatureId>[]).add(id);
    }
    return gruplar;
  }
}

/// Oyuncunun modül anahtarları.
///
/// Yalnızca **varsayılandan farklı** olanlar saklanır: katalog büyüdükçe
/// kayıt büyümez ve eski kayıtlar yeni özelliği varsayılan hâliyle açar.
/// Kayıtta tanınmayan bir anahtar kalmışsa (özellik tamamen silinmişse)
/// sessizce yok sayılır; eski kayıt yine açılır.
@immutable
class FeatureSwitches {
  const FeatureSwitches([this._overrides = const <String, bool>{}]);

  /// Katalog varsayılanı: her özellik kendi [FeatureId.defaultOn] hâlinde.
  static const FeatureSwitches defaults = FeatureSwitches();

  final Map<String, bool> _overrides;

  /// Kayda yazılacak hâli (yalnızca varsayılandan sapmalar).
  Map<String, bool> get overrides => Map<String, bool>.unmodifiable(
        _overrides,
      );

  /// Kayıttan oku. Tanınmayan anahtarlar atılır.
  factory FeatureSwitches.fromMap(Map<String, Object?> json) {
    final Map<String, bool> temiz = <String, bool>{};
    json.forEach((String key, Object? value) {
      if (value is! bool) return;
      final FeatureId? id = FeatureId.byKey(key);
      if (id == null) return;
      if (value == id.defaultOn) return;
      temiz[key] = value;
    });
    return FeatureSwitches(temiz);
  }

  bool isOn(FeatureId id) => _overrides[id.saveKey] ?? id.defaultOn;

  bool isOff(FeatureId id) => !isOn(id);

  /// Tek anahtarı değiştirilmiş yeni kayıt. Varsayılana dönen anahtar
  /// kayıttan tamamen düşer.
  FeatureSwitches toggled(FeatureId id, bool on) {
    final Map<String, bool> yeni = Map<String, bool>.of(_overrides);
    if (on == id.defaultOn) {
      yeni.remove(id.saveKey);
    } else {
      yeni[id.saveKey] = on;
    }
    return FeatureSwitches(yeni);
  }

  /// Hepsini varsayılana döndür.
  FeatureSwitches resetAll() => defaults;

  /// Test ve ölçüm için: katalogdaki her özelliği kapat.
  static FeatureSwitches get allOff => FeatureSwitches(<String, bool>{
        for (final FeatureId id in FeatureId.values)
          if (id.defaultOn) id.saveKey: false,
      });

  /// Test ve ölçüm için: katalogdaki her özelliği aç.
  static FeatureSwitches get allOn => FeatureSwitches(<String, bool>{
        for (final FeatureId id in FeatureId.values)
          if (!id.defaultOn) id.saveKey: true,
      });

  /// Varsayılandan sapma yok mu?
  bool get allDefault => _overrides.isEmpty;

  /// Kapalı özellikler (ayarlar ekranı ve rapor için).
  List<FeatureId> get offFeatures => FeatureId.values
      .where((FeatureId id) => isOff(id))
      .toList(growable: false);
}
