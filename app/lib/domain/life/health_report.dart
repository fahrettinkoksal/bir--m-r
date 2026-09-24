/// Sağlık işlemlerinin **anlamlı sonucu** (D-076).
///
/// **Neden var:** Faho bildirdi — "bir uzmanla konuş diyorum, direkt
/// sadece uzmanla konuştun çıkıyor", "aşı olduğumuzda falan da bildirim
/// olarak ekrana vermeliyiz, kullanıcı ne olduğunu gelen bildirim ile
/// anlamalı", "genel sağlık kontrolünde mesela checkup'a girmişim gibi
/// bildirim gelsin, durumum yazsın işte ciğerlerin iyi, kalp iyi vb".
///
/// Sağlık merkezindeki işlemler yalnızca bir sayıyı artırıyordu; ne
/// olduğunu anlatan bir çıktı yoktu.
///
/// **Sonuç uydurulmaz.** Her satır oyuncunun **gerçek** sağlık değerine,
/// yaşına ve bakım geçmişine bakar. Aynı yıl tekrar bakıldığında aynı
/// sonuç çıkar: rapor rastgele sayıdan değil, durumdan türer.
///
/// **Tıbbi tavsiye değildir.** Sistem adları ve yorumlar oyun içi
/// kurgudur; gerçek bir tetkik listesi ya da teşhis değildir.
library;

import '../models/game_state.dart';
import 'aging.dart';

/// Bir vücut sisteminin kontroldeki durumu.
enum OrganStatus {
  iyi('iyi'),
  normal('normal'),
  takip('takip gerekiyor'),
  sorunlu('sorun görünüyor');

  const OrganStatus(this.label);

  final String label;

  /// Bu durum tahlile yönlendirmeyi gerektirir mi?
  bool get needsFollowUp =>
      this == OrganStatus.takip || this == OrganStatus.sorunlu;
}

/// Raporun tek bir satırı.
class HealthLine {
  const HealthLine({required this.system, required this.status});

  final String system;
  final OrganStatus status;

  String get text => '$system: ${status.label}';
}

/// Bir kontrolün tam sonucu.
class HealthReport {
  const HealthReport({
    required this.lines,
    required this.summary,
    required this.needsLabTest,
  });

  final List<HealthLine> lines;

  /// Oyuncuya söylenen tek cümlelik özet.
  final String summary;

  /// Tahlile yönlendirildi mi?
  final bool needsLabTest;

  /// Bildirimde gösterilecek tam metin.
  String get noticeText => <String>[
        summary,
        '',
        for (final HealthLine l in lines) '• ${l.text}',
        if (needsLabTest) ...<String>[
          '',
          'Hekim seni tahlile yönlendirdi. Sağlık Merkezi\'nden '
              '"Tahlile git" ile sonucu öğrenebilirsin.',
        ],
      ].join('\n');
}

abstract final class HealthChecks {
  /// Tahlile yönlendirildiğini tutan hikâye izi.
  static const String labTestFlag = 'tahlile_yonlendirildi';

  /// Bir sistemin 0-100 arası puanından durumu.
  static OrganStatus statusOf(int score) {
    if (score >= 75) return OrganStatus.iyi;
    if (score >= 55) return OrganStatus.normal;
    if (score >= 35) return OrganStatus.takip;
    return OrganStatus.sorunlu;
  }

  /// Genel sağlık kontrolü raporu.
  ///
  /// Puanlar sağlıktan başlar; yaş ve bakım geçmişi sistem sistem
  /// değiştirir. Spor yapanın kalbi ve ciğerleri, okuyanın değil,
  /// **gerçekten** daha iyi çıkar.
  static HealthReport checkup(GameState state) {
    final int saglik = state.player.stats.health;
    final int yas = state.player.age;
    final int? sporsuz = state.yearsSinceSport;

    // Spor etkisi: son iki yılda spor varsa artı, uzun süredir yoksa eksi.
    final int sporEtkisi = sporsuz == null
        ? -8
        : sporsuz <= StatAging.prototypeOnlyFreshYears
            ? 10
            : sporsuz >= StatAging.prototypeOnlyNeglectYears
                ? -8
                : 0;

    int yasCezasi(int baslangic, double hiz) =>
        yas <= baslangic ? 0 : ((yas - baslangic) * hiz).round();

    final List<HealthLine> satirlar = <HealthLine>[
      HealthLine(
        system: 'Kalp ve tansiyon',
        status: statusOf(
          _sinirla(saglik + sporEtkisi - yasCezasi(45, 0.7) + _sapma(state, 1)),
        ),
      ),
      HealthLine(
        system: 'Akciğerler',
        status: statusOf(
          _sinirla(saglik + sporEtkisi - yasCezasi(50, 0.6) + _sapma(state, 2)),
        ),
      ),
      HealthLine(
        system: 'Kan değerleri',
        status: statusOf(
          _sinirla(saglik - yasCezasi(40, 0.5) + _sapma(state, 3)),
        ),
      ),
      HealthLine(
        system: 'Kemik ve eklemler',
        status: statusOf(
          _sinirla(saglik +
              (sporEtkisi ~/ 2) -
              yasCezasi(40, 0.8) +
              _sapma(state, 4)),
        ),
      ),
      HealthLine(
        system: 'Görme',
        status: statusOf(
          _sinirla(saglik - yasCezasi(40, 1.0) + _sapma(state, 5)),
        ),
      ),
      HealthLine(
        system: 'İşitme',
        status: statusOf(
          _sinirla(saglik - yasCezasi(55, 0.9) + _sapma(state, 6)),
        ),
      ),
    ];

    final bool tahlil =
        satirlar.any((HealthLine l) => l.status.needsFollowUp);
    final int iyiSayisi =
        satirlar.where((HealthLine l) => l.status == OrganStatus.iyi).length;

    final String ozet;
    if (!tahlil && iyiSayisi >= 4) {
      ozet = 'Check-up bitti. Hekim "yaşına göre gayet iyisin" dedi.';
    } else if (!tahlil) {
      ozet = 'Check-up bitti. Ciddi bir şey yok, birkaç değer sınırda.';
    } else {
      ozet = 'Check-up bitti. Hekimin dikkatini çeken birkaç değer var.';
    }

    return HealthReport(
      lines: List<HealthLine>.unmodifiable(satirlar),
      summary: ozet,
      needsLabTest: tahlil,
    );
  }

  /// Ruh sağlığı görüşmesinin sonucu.
  ///
  /// "Uzmanla konuştun" demek yeterli değildi: konuşmanın nereye
  /// vardığı mutluluğa ve son yıllarda yaşananlara bakar.
  static String therapyOutcome(GameState state) {
    final int mutluluk = state.player.stats.happiness;
    if (state.grief > 0) {
      return 'Kırk beş dakika boyunca kaybından konuştun. Uzman '
          'acele etmemeni söyledi; yas kendi hızında geçiyor.';
    }
    if (mutluluk >= 70) {
      return 'Uzman seni dinledi ve "burada tutman gereken bir şey '
          'yok, iyi görünüyorsun" dedi. Bazı seanslar böyledir.';
    }
    if (mutluluk >= 40) {
      return 'Uzunca konuştunuz. Uzman son aylarda seni yoran şeyin '
          'ne olduğunu sordu ve iki hafta sonra tekrar görüşmeyi '
          'önerdi.';
    }
    return 'Konuşurken sesin birkaç kez titredi. Uzman bunu tek '
        'seansta çözmenin mümkün olmadığını, düzenli gelmen '
        'gerektiğini söyledi.';
  }

  /// Aşının sonucu.
  static String vaccineOutcome(GameState state) {
    final int yas = state.player.age;
    if (yas >= 65) {
      return 'Aşı yapıldı. Kolun bir gün ağrıyacak. Yaş grubun için '
          'her yıl tekrarlanması öneriliyor.';
    }
    if (yas < 12) {
      return 'Aşı yapıldı. Ağlamadın; hemşire şeker verdi.';
    }
    return 'Aşı yapıldı. Kolun bir gün ağrıyacak, kış biraz daha '
        'kolay geçecek.';
  }

  /// Diş kontrolünün sonucu.
  static String dentalOutcome(GameState state) {
    final int saglik = state.player.stats.health;
    if (saglik >= 70) {
      return 'Diş hekimi "temiz" dedi, taş temizliği yaptı ve seni '
          'gönderdi.';
    }
    if (saglik >= 45) {
      return 'İki dişte küçük çürük çıktı; dolgu yapıldı.';
    }
    return 'Diş eti çekilmesi var. Hekim düzenli kontrol istedi.';
  }

  /// Tahlil sonucunun metni.
  ///
  /// Tahlil **kötü haber getirmek zorunda değildir**: çoğu zaman bir şey
  /// çıkmaz. Çıkarsa erken çıkar, ki kontrolün amacı da budur.
  static String labResult(GameState state, {required bool clean}) {
    if (clean) {
      return 'Tahlil sonuçları geldi. Hekimin işaretlediği değerler '
          'normal çıktı; takip gerekmiyor.';
    }
    return 'Tahlil sonuçları geldi. Birkaç değer sınırda; hekim '
        'beslenme ve hareket için öneri verdi, altı ay sonra tekrar '
        'görmek istiyor. Erken yakalandığı için işin kolay.';
  }

  static int _sinirla(int v) => v.clamp(0, 100);

  /// Sisteme özgü küçük sabit sapma.
  ///
  /// Rastgele değildir: aynı yaşta aynı oyuncu aynı raporu alır, ama
  /// bütün sistemler aynı anda aynı sayıyı göstermez.
  static int _sapma(GameState state, int sistem) {
    final String anahtar = '${state.player.id}|${state.player.age}|$sistem';
    int h = 0x811c9dc5;
    for (final int kod in anahtar.codeUnits) {
      h = (h ^ kod) * 0x01000193 & 0x7fffffff;
    }
    return (h % 13) - 6;
  }
}
