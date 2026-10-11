import 'package:flutter/foundation.dart';

import 'gender.dart';
import 'stats.dart';
import 'zodiac.dart';
import '../../text/turkish_text.dart';

/// Ana karakter.
@immutable
class PlayerCharacter {
  const PlayerCharacter({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.age,
    required this.birthCity,
    String? currentCity,
    required this.stats,
    this.fame,
    this.wallet = 0,
    this.hairStyle,
    this.infertile = false,
    this.birthDate,
    this.hairLossStage = 0,
    this.storedAthleticPotential,
  }) : currentCity = currentCity ?? birthCity;

  /// Atletik potansiyel (0-100) — **doğumda bir kez** belirlenir.
  ///
  /// Sağlık değildir, karizma değildir, futbol becerisi de değildir.
  /// Yalnızca bedensel/sportif gelişime yatkınlıktır: aynı antrenmanla
  /// kimin daha hızlı ilerlediğini belirler.
  ///
  /// **Oyuncuya sayı olarak gösterilmez.** Spor yapmaya başlayınca
  /// kabaca bir fikir edinilir ("Zorlanıyor", "Yetenekli" gibi).
  ///
  /// **Save/load sonrası yeniden çekilmez:** değer kayda yazılır ve
  /// [storedAthleticPotential] olarak geri okunur.
  ///
  /// Yüksek potansiyel kendiliğinden profesyonellik getirmez; düşük
  /// potansiyel de matematiksel olarak imkânsız kılmaz. Belirleyici olan
  /// **geçmiş + çalışma + yetenek + sağlık** birlikte.
  int get athleticPotential =>
      storedAthleticPotential ?? _turetilmisAtletikPotansiyel(id);

  /// Kayda yazılan potansiyel. Alanı taşımayan **eski kayıtlarda** `null`
  /// olur ve kimlikten deterministik olarak türetilir — her yüklemede aynı
  /// değer çıkar, rastgele yeniden atılmaz.
  final int? storedAthleticPotential;

  final String id;
  final String firstName;
  final String lastName;
  final Gender gender;
  final int age;

  /// Doğum şehri rastgele belirlenir (D-004). Doğum **yılı** yoktur (D-003).
  final String birthCity;

  /// Oyuncunun **şu an yaşadığı** şehir (D-043).
  ///
  /// Taşınana kadar doğum şehridir.
  final String currentCity;
  final Stats stats;

  /// Ün (D-027). `null` ise Ün henüz **açılmamıştır** ve arayüzde gösterilmez.
  final int? fame;

  /// Oyuncunun **kendi** cüzdanı (ECO-001).
  ///
  /// Ailenin ekonomik durumundan ve ebeveynlerin mal varlığından tamamen
  /// ayrıdır; aile varlığı oyuncunun harcanabilir parası değildir. Bu
  /// sürümde kazanma/harcama akışları yoktur, yalnızca bakiye tutulur ve
  /// olay etkileriyle değişebilir. Para birimi ve başlangıç bakiyesi henüz
  /// kararlaştırılmadı (prototypeOnly: 0 ile başlar).
  final int wallet;

  /// Oyuncu kısır mı? (Paket 25)
  ///
  /// Hayat başında **gizlice** belirlenir ve oyuncuya söylenmez; ancak
  /// denedikçe anlaşılır. Sağlık menüsündeki tedaviler (tüp bebek)
  /// henüz tasarlanmadı (Q-093).
  final bool infertile;

  /// Doğum ayı ve günü (Paket 27). **Yıl yoktur** (D-003).
  ///
  /// Burç bundan hesaplanır. Eski kayıtlarda boştur; o zaman hayatın
  /// tohumundan **deterministik** olarak türetilir, böylece aynı hayat
  /// her açılışta aynı burcu gösterir.
  final BirthDate? birthDate;

  /// Berberde seçilen saç stili. Görsel karakter sistemi henüz yok;
  /// seçim metin olarak saklanır ve Ben ekranında görünür.
  final String? hairStyle;

  /// Erkeklerde yaşa bağlı saç dökülmesinin basamağı (D-073).
  ///
  /// `0` hiç dökülme yok, `1` seyrelme, `2` belirgin açılma, `3` ileri
  /// derecede dökülme. Basamak **geri gitmez**; yalnızca saç ektirmek
  /// gibi bir işlem düşürebilir. Dış görünüş ve karizma etkisi basamak
  /// **ilerlediği yıl bir kez** uygulanır, her yıl tekrar tekrar değil.
  final int hairLossStage;

  /// Saçı dökülmeye başlamış mı?
  bool get hasHairLoss => hairLossStage > 0;

  /// Ekranda gösterilecek bakiye metni.
  String get walletLabel => trMoney(wallet);

  bool get fameUnlocked => fame != null;

  String get fullName => '$firstName $lastName';

  PlayerCharacter copyWith({
    String? firstName,
    String? lastName,
    int? age,
    Stats? stats,
    int? fame,
    int? wallet,
    String? hairStyle,
    String? currentCity,
    bool? infertile,
    BirthDate? birthDate,
    int? hairLossStage,
  }) {
    return PlayerCharacter(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      gender: gender,
      age: age ?? this.age,
      birthCity: birthCity,
      currentCity: currentCity ?? this.currentCity,
      stats: stats ?? this.stats,
      fame: fame ?? this.fame,
      wallet: wallet ?? this.wallet,
      hairStyle: hairStyle ?? this.hairStyle,
      infertile: infertile ?? this.infertile,
      birthDate: birthDate ?? this.birthDate,
      hairLossStage: hairLossStage ?? this.hairLossStage,
      // Doğumda belirlenir ve bir daha değişmez: `copyWith` parametresi
      // bilerek yoktur, değer olduğu gibi taşınır.
      storedAthleticPotential: storedAthleticPotential,
    );
  }
}

/// Alanı taşımayan eski kayıtlar için kimlikten türetilen potansiyel.
///
/// Rastgele değil **deterministik**: aynı kayıt her yüklemede aynı değeri
/// alır. Geçmiş uydurmak değil; eksik alanı kararlı biçimde doldurmaktır.
int _turetilmisAtletikPotansiyel(String id) {
  int h = 0;
  for (final int kod in id.codeUnits) {
    h = (h * 31 + kod) & 0x7fffffff;
  }
  // 25-85: oyuncu statlarıyla aynı prototypeOnly bant.
  return 25 + (h % 61);
}
