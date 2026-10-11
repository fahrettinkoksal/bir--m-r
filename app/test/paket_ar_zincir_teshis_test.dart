// Paket AR/2 — iz arayan olaylar neden çıkmıyor? Teşhis.
//
// AR/1 ölçtü: iz arayan 67 olayın 13'ü 40 hayatta hiç ekrana gelmedi.
// Bu test o 13'ün **nedenini** ayırıyor. Üç sınıf var ve üçü ayrı şey:
//
//   OYUN   — zincir gerçekten kırık. İz ya hiç konmuyor ya da olayın
//            yaş penceresi kapandıktan sonra konuyor. Oyuncu da göremez.
//   ZİNCİR — izi koyacak **olay** hiç ekrana gelmedi. Yani sorun botun
//            seçimi değil, zincirin derinliği: önceki halka kendi
//            kurasını kazanmadığı için sonraki halkaya hiç sıra
//            gelmiyor. Her halka bir çarpım; dört adımlı zincirin son
//            adımı pratikte çok seyrek görülür.
//   BOT    — izi koyacak olay **geldi** ama bot başka kolu seçti. Yol
//            açık, gerçek oyuncu ulaşır; eksik olan simülasyon.
//   NORMAL — iz zamanında konuyor, pencere açık, olay aday havuza
//            giriyor ama ağırlık kurasını kaybediyor. Nadir, hata değil.
//
// Ayrımların hepsi ölçüm: izin **ilk konduğu yaş**, izi koyabilen
// olayların **ekrana gelip gelmediği** ve olayın **aday havuza girip
// girmediği** ayrı ayrı kaydediliyor. Hiçbiri çıkarsanmıyor — ilk
// denemede "iz zamanında kondu, demek ki kurayı kaybetti" diye
// varsaymıştım ve sonuç yanlış çıkmıştı.
library;

import 'dart:math';

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

  /// Hiç konmayan izler için: o izi koyabilecek olay ekrana geldi mi?
  ///
  /// Geldiyse eksik olan botun seçimi (BOT). Gelmediyse sorun daha
  /// yukarıda: önceki halka hiç çıkmamış (ZİNCİR).
  final Map<String, bool> uretenOlayCikti = <String, bool>{};

  /// Hiç konmayan izi koyabilecek olayların kimlikleri.
  final Map<String, List<String>> ureten = <String, List<String>>{};

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
    if (hicKonmayan.isEmpty) return 'OYUN';
    // İzi koyabilecek olay hiç ekrana gelmediyse sorun zincirin
    // derinliğinde; geldiyse botun seçimindedir.
    final bool hepsiGelmedi = hicKonmayan
        .every((String iz) => uretenOlayCikti[iz] == false);
    return hepsiGelmedi ? 'ZİNCİR' : 'BOT';
  }

  String get gerekce {
    if (adayOldu) {
      return 'olay aday havuza girdi ama ağırlık kurasını kaybetti';
    }
    if (hicKonmayan.isNotEmpty) {
      final String iz = hicKonmayan.first;
      final List<String> kaynak = ureten[iz] ?? const <String>[];
      if (sinif == 'ZİNCİR') {
        return 'gereken iz (${hicKonmayan.join(", ")}) hiç konmadı çünkü '
            'onu koyabilecek olay (${kaynak.join(", ")}) bir kez bile '
            'ekrana gelmedi; önceki halka kendi kurasını kazanmıyor';
      }
      return 'gereken iz (${hicKonmayan.join(", ")}) hiç konmadı; onu '
          'koyabilecek olay (${kaynak.join(", ")}) ekrana geldi ama bot '
          'o kolu hiç seçmedi';
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

double _ortanca(List<double> v) {
  if (v.isEmpty) return 0;
  final List<double> s = v.toList()..sort();
  return s[s.length ~/ 2];
}

void main() {
  test('iz arayan ama çıkmayan olayların nedeni ayrıştırılıyor', () {
    final Set<String> cikanOlay = <String>{};
    final Set<String> adayOlan = <String>{};
    final Set<String> konanIz = <String>{};
    // İz -> onu ilk koyan en küçük yaş (bütün hayatlar birlikte).
    final Map<String, int> enErkenIz = <String, int>{};
    // Her yılın aday havuz boyutu ve toplam etkin ağırlığı.
    final List<int> adaySayilari = <int>[];
    final List<double> agirlikToplamlari = <double>[];
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
        adaySayilari.addAll(r.eligibleCounts);
        agirlikToplamlari.addAll(r.eligibleWeightSums);
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
          // Bu izi hangi olaylar koyabilir ve onlar ekrana geldi mi?
          final List<String> kaynak = <String>[
            for (final GameEvent k in kEventPool)
              if (k.choices.any((EventChoice c) => c.addFlags.contains(iz)))
                k.id,
          ];
          t.ureten[iz] = kaynak;
          t.uretenOlayCikti[iz] =
              kaynak.any((String id) => cikanOlay.contains(id));
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
      ..writeln('  OYUN   (aday bile olamadı)      : '
          '${gruplu["OYUN"]?.length ?? 0}')
      ..writeln('  ZİNCİR (önceki halka hiç çıkmadı): '
          '${gruplu["ZİNCİR"]?.length ?? 0}')
      ..writeln('  BOT    (olay geldi, kol seçilmedi): '
          '${gruplu["BOT"]?.length ?? 0}')
      ..writeln('  NORMAL (aday oldu, seçilmedi)   : '
          '${gruplu["NORMAL"]?.length ?? 0}')
      ..writeln('Aday havuza giren farklı olay : ${adayOlan.length}');
    if (adaySayilari.isNotEmpty) {
      final List<int> sirali = adaySayilari.toList()..sort();
      final int toplam = sirali.reduce((int a, int b) => a + b);
      b
        ..writeln('Ölçülen yıl                   : ${sirali.length}')
        ..writeln('Yıllık aday havuz boyutu      : '
            'ortalama ${(toplam / sirali.length).toStringAsFixed(1)}, '
            'ortanca ${sirali[sirali.length ~/ 2]}, '
            'en az ${sirali.first}, en çok ${sirali.last}')
        ..writeln('Yıllık toplam etkin ağırlık   : '
            'ortanca ${_ortanca(agirlikToplamlari).toStringAsFixed(0)}');
    }

    // Zincir halkalarının gerçek çıkma ihtimali: kura **ağırlıkla**
    // yapılıyor, o yüzden halkanın payı kendi ağırlığı bölü yıllık
    // toplam. Pencere boyunca birikimli ihtimal bundan çıkıyor.
    final double ortancaToplam = _ortanca(agirlikToplamlari);
    if (ortancaToplam > 0) {
      b
        ..writeln('\n--- HALKA ÇIKMA İHTİMALİ (ölçülen ağırlık tabanına '
            'göre) ---')
        ..writeln('Bir halkanın yıllık payı = etkin ağırlığı / '
            '${ortancaToplam.toStringAsFixed(0)}');
      for (final Teshis t in olu) {
        final GameEvent e = t.event;
        final int pencere = e.requirement.maxAge - e.requirement.minAge + 1;
        final double yillik = e.weight / ortancaToplam;
        final double birikimli = 1 - pow(1 - yillik, pencere).toDouble();
        b.writeln('${e.id.padRight(34)} ağırlık ${e.weight}, '
            'pencere $pencere yıl → yıllık '
            '${(yillik * 100).toStringAsFixed(2)}%, '
            'pencere boyunca ${(birikimli * 100).toStringAsFixed(1)}%');
      }
      b.writeln('Not: bu üst sınır. Halka ancak önceki halka çıkıp doğru '
          'kol seçilirse yarışa girer; zincir derinleştikçe ihtimaller '
          'çarpılır.');
    }
    for (final String sinif in <String>[
      'OYUN',
      'ZİNCİR',
      'BOT',
      'NORMAL',
    ]) {
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
