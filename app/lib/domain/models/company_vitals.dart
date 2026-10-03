/// Bir kurgusal şirketin **gizli** sağlık göstergeleri (Paket AD, §AD/2).
///
/// **Neden var.** Paket AC'de şirket olayları vardı ama şirketlerin bir
/// *hâli* yoktu: kim batacağını yalnızca kataloğa yazılı sabit bir
/// `fragility` sayısı ile o yılın rejimi belirliyordu. Sonuç, oyuncunun
/// gözünden bakınca "rastgele kötü haber"di — bir şirketin yıllardır
/// borç çevirmekte zorlandığını, yönetiminin kötü olduğunu ya da
/// sektörünün zayıfladığını fark etme imkânı yoktu, çünkü öyle bir şey
/// gerçekten yoktu.
///
/// Artık her şirketin yıllar boyunca **değişen ve kayda giren** beş
/// göstergesi var. Olaylar bunlardan doğuyor: borcu yüksek + yönetimi
/// kötü + sektörü zayıf şirketin incelemeye düşme, bilanço şoku yaşama,
/// konkordatoya gitme ve kapanma riski gerçekten daha yüksek.
///
/// **Hiçbiri oyuncuya sayı olarak gösterilmez** (§3). Oyuncu bunu
/// haberlerden hisseder: "yeni fabrika yatırımı" ile "borç çevirmekte
/// zorlanıyor" aynı şirketin iki farklı yılı olabilir.
///
/// Hepsi 0-100, 50 nötr. Bütün sayılar `prototypeOnly` (Q-171).
library;

import 'package:flutter/foundation.dart';

@immutable
class CompanyVitals {
  const CompanyVitals({
    this.financialHealth = 50,
    this.debtPressure = 50,
    this.growth = 50,
    this.management = 50,
    this.confidence = 50,
  });

  /// Mali sağlık. Yüksek iyi.
  final int financialHealth;

  /// Borç baskısı. **Yüksek kötü.**
  final int debtPressure;

  /// Büyüme potansiyeli. Yüksek iyi.
  final int growth;

  /// Yönetim kalitesi. Yüksek iyi; **yavaş değişir**, çünkü yapısal bir
  /// niteliktir. Kötü haberin etkisini ve krizden çıkma ihtimalini
  /// belirler (§3).
  final int management;

  /// Şirkete duyulan piyasa güveni. Yüksek iyi.
  final int confidence;

  /// Şirketin **baskı altında olma** derecesi (0-1).
  ///
  /// Beş göstergenin bileşimi. Ağırlıklar `prototypeOnly`: mali sağlık ve
  /// borç baskısı en belirleyici, yönetim kalitesi tamponluk yapıyor.
  /// Tek bir gösterge kötü diye şirket batmaz; bu yüzden ortalama alınıyor,
  /// en kötüsü değil.
  double get stress {
    final double kotuluk = (100 - financialHealth) * 0.30 +
        debtPressure * 0.28 +
        (100 - growth) * 0.14 +
        (100 - management) * 0.16 +
        (100 - confidence) * 0.12;
    return (kotuluk / 100).clamp(0.0, 1.0);
  }

  /// Şirket **iyi durumda** mı? Yalnızca metin seçimi için.
  bool get isThriving => stress < 0.38;

  /// Şirket **zorda** mı? Yalnızca metin seçimi için.
  bool get isStrained => stress > 0.58;

  CompanyVitals copyWith({
    int? financialHealth,
    int? debtPressure,
    int? growth,
    int? management,
    int? confidence,
  }) =>
      CompanyVitals(
        financialHealth:
            (financialHealth ?? this.financialHealth).clamp(0, 100),
        debtPressure: (debtPressure ?? this.debtPressure).clamp(0, 100),
        growth: (growth ?? this.growth).clamp(0, 100),
        management: (management ?? this.management).clamp(0, 100),
        confidence: (confidence ?? this.confidence).clamp(0, 100),
      );
}
