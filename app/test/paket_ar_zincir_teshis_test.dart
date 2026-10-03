// Paket AR/2 — iz arayan olaylar neden çıkmıyor? Teşhis.
//
// AR/1 ölçtü: iz arayan 67 olayın 13'ü 40 hayatta hiç ekrana gelmedi.
// Bu test o 13'ün **nedenini** ayırıyor. Üç sınıf var ve üçü ayrı şey:
//
//   OYUN   — zincir gerçekten kırık. İz ya hiç konmuyor ya da olayın
//            yaş penceresi kapandıktan sonra konuyor. Oyuncu da göremez.
//   BOT    — izi koyan seçimi bot hiç seçmiyor. Yol açık, gerçek oyuncu
//            ulaşır; eksik olan simülasyon.
//   NORMAL — iz zamanında konuyor, pencere açık, olay aday havuza
//            giriyor ama ağırlık kurasını kaybediyor. Nadir, hata değil.
//
// Ayrım ölçümle yapılıyor: izin **ilk konduğu yaş** kaydediliyor ve
// olayın yaş penceresiyle karşılaştırılıyor.
library;

import 'package:bir_omur/data/event_pool.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/coverage_bot.dart';

/// Bir ölü halkanın teşhisi.
class Teshis {
  Teshis(this.event, this.izler);

  final GameEvent event;
  final Set<String> izler;

  /// İz hiç konmadı mı?
  final Set<String> hicKonmayan = <String>{};

  /// İz kondu ama olayın penceresi o yaşta zaten kapanmıştı.
  final Map<String, int> gecKonan = <String, int>{};

  /// İz pencere açıkken kondu — yol gerçekten açıktı.
  final Map<String, int> zamanindaKonan = <String, int>{};

  /// Olay hiç olmazsa bir kez **aday havuza girdi mi**?
  ///
  /// Bu ölçülür, çıkarsanmaz: `EventEngine.debugEligibleIds` her yıl
  /// çağrılıyor. "Aday oldu ama seçilmedi" ile "hiç aday olamadı" ayrı
  /// şeylerdir; ikincisinin önünde iz dışında bir kapı vardır
  /// (kişi rolü, sahiplik, ekonomik durum…).
  bool adayOldu = false;

  String get sinif {
    if (adayOldu) return 'NORMAL';
    if (hicKonmayan.isNotEmpty) return 'BOT';
    return 'OYUN';
  }

  String get gerekce {
    if (adayOldu) {
      return 'olay aday havuza girdi ama ağırlık kurasını kaybetti';
    }
    if (hicKonmayan.isNotEmpty) {
      return 'gereken iz (${hicKonmayan.join(", ")}) hiçbir hayatta '
          'konmadı; izi koyan seçimi bot hiç seçmemiş';
    }
    final String yas = gecKonan.isNotEmpty
        ? 'iz ancak ${gecKonan.values.join(", ")} yaşında kondu, '
            'pencere ${event.requirement.minAge}-${event.requirement.maxAge}'
        : 'iz ${zamanindaKonan.values.join(", ")} yaşında kondu ve '
            'pencere ${event.requirement.minAge}-${event.requirement.maxAge} '
            'açıktı';
    return '$yas; buna rağmen olay bir kez bile aday havuza giremedi — '
        'önünde iz dışında bir kapı var';
  }
}

void main() {
  test('iz arayan ama çıkmayan olayların nedeni ayrıştırılıyor', () {
    final Set<String> cikanOlay = <String>{};
    final Set<String> adayOlan = <String>{};
    final Set<String> konanIz = <String>{};
    // İz -> onu ilk koyan en küçük yaş (bütün hayatlar birlikte).
    final Map<String, int> enErkenIz = <String, int>{};
    int hayat = 0;

    for (final CoveragePlan plan in CoveragePlan.values) {
      for (int tohum = 0; tohum < 4; tohum++) {
        final CoverageResult r = runCoverageLife(
          plan: plan,
          seed: plan.index * 1000 + tohum * 37 + 11,
        );
        cikanOlay.addAll(r.firedEvents);
        adayOlan.addAll(r.eligibleEvents);
        konanIz.addAll(r.storyFlags);
        r.flagAges.forEach((String iz, int yas) {
          final int? onceki = enErkenIz[iz];
          if (onceki == null || yas < onceki) enErkenIz[iz] = yas;
        });
        hayat++;
      }
    }

    final List<Teshis> olu = <Teshis>[];
    for (final GameEvent e in kEventPool) {
      if (e.requirement.requiredFlags.isEmpty) continue;
      if (cikanOlay.contains(e.id)) continue;
      final Teshis t = Teshis(e, e.requirement.requiredFlags);
      for (final String iz in t.izler) {
        final int? yas = enErkenIz[iz];
        if (yas == null) {
          t.hicKonmayan.add(iz);
        } else if (yas > e.requirement.maxAge) {
          t.gecKonan[iz] = yas;
        } else {
          t.zamanindaKonan[iz] = yas;
        }
      }
      t.adayOldu = adayOlan.contains(e.id);
      olu.add(t);
    }

    final Map<String, List<Teshis>> gruplu = <String, List<Teshis>>{};
    for (final Teshis t in olu) {
      gruplu.putIfAbsent(t.sinif, () => <Teshis>[]).add(t);
    }

    final StringBuffer b = StringBuffer()
      ..writeln('\n======================================================')
      ..writeln('ZİNCİR TEŞHİSİ — $hayat kapsam hayatı')
      ..writeln('======================================================')
      ..writeln('İz arayan olay            : '
          '${kEventPool.where((GameEvent e) => e.requirement.requiredFlags.isNotEmpty).length}')
      ..writeln('Bunlardan hiç çıkmayan    : ${olu.length}')
      ..writeln('  OYUN   (aday bile olamadı) : ${gruplu["OYUN"]?.length ?? 0}')
      ..writeln('  BOT    (iz hiç konmadı)    : ${gruplu["BOT"]?.length ?? 0}')
      ..writeln('  NORMAL (aday oldu, seçilmedi): '
          '${gruplu["NORMAL"]?.length ?? 0}')
      ..writeln('Aday havuza giren farklı olay : ${adayOlan.length}');
    for (final String sinif in <String>['OYUN', 'BOT', 'NORMAL']) {
      final List<Teshis> liste = gruplu[sinif] ?? <Teshis>[];
      if (liste.isEmpty) continue;
      b.writeln('\n--- $sinif ---');
      for (final Teshis t in liste) {
        b.writeln('${t.event.id}  (${t.event.requirement.minAge}-'
            '${t.event.requirement.maxAge} yaş)');
        b.writeln('    ister : ${t.izler.join(" + ")}');
        b.writeln('    neden : ${t.gerekce}');
      }
    }
    // ignore: avoid_print
    print(b.toString());

    // Teşhis testi: sert iddia yalnızca ölçümün çalıştığı.
    expect(hayat, CoveragePlan.values.length * 4);
    expect(konanIz, isNotEmpty);
    expect(enErkenIz, isNotEmpty,
        reason: 'İz yaşları toplanamadıysa teşhis anlamsızdır.');
    expect(adayOlan, isNotEmpty,
        reason: 'Aday havuz hiç ölçülemediyse sınıflandırma anlamsızdır.');
  }, timeout: const Timeout(Duration(minutes: 10)));
}
