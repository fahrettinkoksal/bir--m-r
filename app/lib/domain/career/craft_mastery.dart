/// Meslekte **ustalık** ve **itibar** (D-155).
///
/// **Neden var:** Kariyer, iş kimliği artı yıl sayısıydı. Aynı işte otuz
/// yıl çalışan biriyle üç yıl çalışan biri arasında, maaş dışında hiçbir
/// fark yoktu: ne ekranda, ne zam masasında, ne hayat sonu
/// değerlendirmesinde.
///
/// **Yeni kayıt alanı eklenmedi.** İkisi de var olan kayıttan türetilir:
/// - **Ustalık** işe aittir: `CareerState.yearsInJob`. İş değişince
///   sıfırdan başlar, çünkü yeni işte usta olmak yeniden kazanılır.
/// - **İtibar** kariyere aittir: toplam çalışma yılı, ulaşılan en yüksek
///   görev basamağı ve işten çıkarılma sayısı. İş değişince **kaybolmaz**;
///   bir ömrün emeği tek bir işverene bağlı değildir.
///
/// Basamak adları Türkçe zanaat düzeninden geliyor: çırak → kalfa → usta.
/// Üstündeki iki basamak günlük dilden (**başusta**, **duayen**).
///
/// Bütün sayılar `prototypeOnly`'dir (Q-158).
library;

import '../models/career.dart';
import '../models/game_state.dart';

/// Bir işteki ustalık basamağı.
enum MasteryStage {
  cirak('Çırak', 0),
  kalfa('Kalfa', 3),
  usta('Usta', 8),
  basusta('Başusta', 16),
  duayen('Duayen', 28);

  const MasteryStage(this.label, this.yearsNeeded);

  final String label;

  /// prototypeOnly: bu basamağa çıkmak için **aynı işte** geçmesi gereken
  /// yıl.
  final int yearsNeeded;
}

abstract final class CraftMastery {
  /// prototypeOnly: her ustalık basamağının zam/terfi şansına kattığı pay.
  static const double prototypeOnlyStagePerRaiseBonus = 0.06;

  /// prototypeOnly: her ustalık basamağının işten çıkarılma ihtimaline
  /// uyguladığı indirim.
  ///
  /// Ustayı kolay göndermezler; ama tamamen dokunulmaz da değildir.
  static const double prototypeOnlyStageLayoffRelief = 0.12;

  /// prototypeOnly: işten çıkarılma ihtimalinin en az kalacağı oran.
  static const double prototypeOnlyMinLayoffFactor = 0.45;

  /// prototypeOnly: itibarın her çalışma yılından kazandığı puan.
  static const double prototypeOnlyReputationPerYear = 1.6;

  /// prototypeOnly: ulaşılan her görev basamağının itibara kattığı puan.
  static const double prototypeOnlyReputationPerLevel = 6;

  /// prototypeOnly: her işten çıkarılmanın itibardan düşürdüğü puan.
  static const double prototypeOnlyReputationPerLayoff = 9;

  /// prototypeOnly: itibarın zam/terfi şansına kattığı en fazla pay.
  static const double prototypeOnlyReputationRaiseBonus = 0.14;

  /// Bu işte kaç yıl geçtiyse hangi basamaktasın?
  static MasteryStage stageForYears(int years) {
    MasteryStage sonuc = MasteryStage.cirak;
    for (final MasteryStage s in MasteryStage.values) {
      if (years >= s.yearsNeeded) sonuc = s;
    }
    return sonuc;
  }

  /// Oyuncunun şu anki işindeki ustalık basamağı; işsizse `null`.
  static MasteryStage? stageOf(GameState state) {
    final CareerState k = state.career;
    if (!k.isEmployed) return null;
    return stageForYears(k.yearsInJob(state.player.age));
  }

  /// Bir sonraki basamağa kaç yıl kaldı? En üstteyse `null`.
  static int? yearsToNextStage(GameState state) {
    final CareerState k = state.career;
    if (!k.isEmployed) return null;
    final int yil = k.yearsInJob(state.player.age);
    for (final MasteryStage s in MasteryStage.values) {
      if (s.yearsNeeded > yil) return s.yearsNeeded - yil;
    }
    return null;
  }

  /// Kariyer boyu **itibar** (0-100).
  ///
  /// Uydurma bir sayı değil: toplam çalışma yılı, ulaşılan en yüksek
  /// basamak ve işten çıkarılma sayısından türetilir. İş değişince
  /// sıfırlanmaz.
  static int reputationOf(GameState state) {
    final CareerState k = state.career;
    final int yil = k.totalWorkYears(state.player.age);

    int enYuksekBasamak = k.level;
    int cikarilma = 0;
    for (final JobHistoryEntry e in k.history) {
      if (e.level > enYuksekBasamak) enYuksekBasamak = e.level;
      if (e.endReason == JobEndReason.cikarildi) cikarilma++;
    }

    final double puan = yil * prototypeOnlyReputationPerYear +
        enYuksekBasamak * prototypeOnlyReputationPerLevel -
        cikarilma * prototypeOnlyReputationPerLayoff;
    return puan.clamp(0, 100).round();
  }

  /// İtibarın okunur etiketi.
  ///
  /// Hiç çalışmamış oyuncuya "kötü itibar" denmez: itibar **yokluktur**,
  /// ceza değildir.
  static String reputationLabel(GameState state) {
    if (state.career.totalWorkYears(state.player.age) <= 0) {
      return 'Henüz iş hayatı yok';
    }
    final int p = reputationOf(state);
    if (p >= 80) return 'Adı iyi bilinir';
    if (p >= 60) return 'Güvenilir';
    if (p >= 40) return 'Bilinen bir isim';
    if (p >= 20) return 'Yeni tanınıyor';
    return 'Henüz iz bırakmadı';
  }

  /// Ustalık ve itibarın zam/terfi şansına kattığı toplam pay.
  static double requestBonus(GameState state) {
    final MasteryStage? basamak = stageOf(state);
    if (basamak == null) return 0;
    final double ustalik = basamak.index * prototypeOnlyStagePerRaiseBonus;
    final double itibar =
        reputationOf(state) / 100 * prototypeOnlyReputationRaiseBonus;
    return ustalik + itibar;
  }

  /// İşten çıkarılma ihtimaline uygulanan çarpan.
  ///
  /// Çarpan bir tabanla sınırlanır: usta olmak **dokunulmazlık değildir**,
  /// küçülme herkese uğrar.
  static double layoffFactor(GameState state) {
    final MasteryStage? basamak = stageOf(state);
    if (basamak == null) return 1;
    final double carpan = 1 - basamak.index * prototypeOnlyStageLayoffRelief;
    return carpan.clamp(prototypeOnlyMinLayoffFactor, 1.0);
  }

  /// Bu yıl yeni bir ustalık basamağına çıkıldı mı?
  ///
  /// Yıl ilerletilirken çağrılır: `newYears` yeni yaştaki yıl sayısıdır.
  /// Çıkıldıysa yeni basamak, çıkılmadıysa `null`.
  static MasteryStage? stageReachedAt(int newYears) {
    for (final MasteryStage s in MasteryStage.values) {
      if (s.yearsNeeded == newYears && s != MasteryStage.cirak) return s;
    }
    return null;
  }
}
