// Bildirilmiş ama hiç okunmayan `prototypeOnly` sabiti kalmasın.
//
// **Bu testin varlık sebebi gerçek hatalar.** Paket BA taramasında 869
// `prototypeOnly` bildiriminden **19'u** hiçbir yerde okunmuyordu. Bunlar
// zararsız ölü kod değildi; çoğu, yanında duran belge yorumu yüzünden
// **yürürlükteki kural gibi okunuyordu**:
//
// * `JobMarket` dört sabitle (taban %50, eğitim payı %25, stat payı %15,
//   tavan %90) eksiksiz bir "işe alım olasılığı" modeli bildiriyordu.
//   Oysa işe alım deterministik: mülakat sorusu doğru cevaplanır ve
//   koşullar sağlanırsa iş verilir. Dosyayı okuyan (ben dahil) eğitimin
//   işe alım şansına %25 kattığını sanıyordu; böyle bir şey yoktu.
// * `Housing.prototypeOnlyYearlyRentYield` 0,045 diyordu; kirayı
//   hesaplayan `RentalEngine` ise kendi 0,042'sini kullanıyordu. İki
//   **farklı** sayı, biri tamamen ölü.
// * `MarriageEngine` düğün masrafı/mutluluğu/yakınlığı için üç sabit
//   tutuyordu; gerçek sayılar `kWeddingStyles` kataloğundan geliyordu.
// * `HouseholdBudget.prototypeOnlyCustodyBond` 50 diyordu; velayet
//   gerçekte 40/60 bandıyla veriliyordu.
// * `Parenthood.prototypeOnlyUnmarriedMinBond` yorumunda "bu eşikle
//   aranır" yazıyordu; 15 satır aşağıdaki yorum ise aynı eşiğin Paket
//   25'te **kaldırıldığını** söylüyordu. Kod tabanı kendisiyle
//   çelişiyordu.
//
// Bu dosya o sınıf hatayı anında yakalar: bir sabit bildirilip hiç
// okunmazsa test kırılır. Yöntem kaynak taramasıdır, çünkü Flutter'da
// çalışma anı yansıması (`dart:mirrors`) yok — aynı yöntem
// `save_field_coverage_test` ve `stat_gain_test` içinde de kullanılıyor.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Bilerek okunmayan sabitler.
///
/// Boş olması iyidir. Buraya bir sabit yalnızca **gerekçesiyle** eklenir:
/// henüz bağlanmamış bir mekaniğin sayısı burada bekleyebilir, ama bu bir
/// tercih olmalı, unutulmuş bir eksik değil. Gerekçe, kuyruktaki soruya
/// ya da karara işaret etmelidir.
const Map<String, String> kOkunmayanSabitler = <String, String>{};

/// `static const`/`static final` bildirimi.
final RegExp _statikKalibi = RegExp(
  r'^\s*static\s+(?:const|final)\s+[\w<>?,\s]+\s+(prototypeOnly\w+)\s*=',
);

/// Örnek alanı: `final int prototypeOnlyX;`
final RegExp _alanKalibi = RegExp(
  r'^\s*final\s+[\w<>?,\s]+\s+(prototypeOnly\w+)\s*;',
);

final RegExp _sinifKalibi = RegExp(
  r'^(?:abstract\s+)?(?:final\s+)?(?:class|enum|extension|mixin)\s+(\w+)',
);

/// Bu satır sabiti **okuyor** mu? Bildirim, kurucu parametresi ve adlı
/// argüman okuma sayılmaz: `prototypeOnlyBond: 3` bir değer **verir**,
/// o değeri kullanmaz.
bool _okuyor(String satir, String ad) {
  if (!RegExp('\\b$ad\\b').hasMatch(satir)) return false;
  if (_statikKalibi.hasMatch(satir) || _alanKalibi.hasMatch(satir)) {
    return false;
  }
  if (RegExp('\\bthis\\.$ad\\b').hasMatch(satir)) return false;
  if (RegExp('^\\s*$ad\\s*:').hasMatch(satir)) return false;
  return true;
}

void main() {
  test('her prototypeOnly sabiti bir yerde okunuyor', () {
    // Okuma yüzeyi `lib` **ve** `test`.
    //
    // İlk hâli yalnızca `lib`e bakıyordu ve bu yanlış sonuç verdi:
    // `BusinessIncidents.prototypeOnlyShopOnlyTags` ölü sanıldı, oysa
    // onu bilerek **test** okuyor (motorda süzgeç uygulanmıyor, güvence
    // katalog tarafında; `paket_ae_business_test.dart` kümeyi oradan
    // denetliyor). Bir sabitin tek okuyucusu bir test olabilir; bu onu
    // ölü yapmaz, çünkü değiştirildiğinde bir şey kırılır.
    final List<File> dosyalar = <Directory>[Directory('lib'), Directory('test')]
        .expand((Directory d) => d.listSync(recursive: true))
        .whereType<File>()
        .where((File f) => f.path.endsWith('.dart'))
        .toList(growable: false);
    final Map<String, List<String>> satirlar = <String, List<String>>{
      for (final File f in dosyalar) f.path: f.readAsLinesSync(),
    };
    final Map<String, String> tamMetin = <String, String>{
      for (final String p in satirlar.keys) p: satirlar[p]!.join('\n'),
    };

    // Bildirimler: (ad, dosya, sınıf, satır no, statik mi)
    final List<({String ad, String dosya, String? sinif, int no, bool statik})>
        bildirimler = <({
      String ad,
      String dosya,
      String? sinif,
      int no,
      bool statik
    })>[];
    for (final String p in satirlar.keys) {
      // Bildirimler yalnızca `lib`ten toplanır: testlerin kendi
      // yardımcı sabitleri bu denetimin konusu değil.
      if (!p.startsWith('lib')) continue;
      String? sinif;
      final List<String> ls = satirlar[p]!;
      for (int i = 0; i < ls.length; i++) {
        final RegExpMatch? s = _sinifKalibi.firstMatch(ls[i]);
        if (s != null) sinif = s.group(1);
        final RegExpMatch? st = _statikKalibi.firstMatch(ls[i]);
        final RegExpMatch? al = _alanKalibi.firstMatch(ls[i]);
        if (st != null) {
          bildirimler.add((
            ad: st.group(1)!,
            dosya: p,
            sinif: sinif,
            no: i + 1,
            statik: true
          ));
        } else if (al != null) {
          bildirimler.add((
            ad: al.group(1)!,
            dosya: p,
            sinif: sinif,
            no: i + 1,
            statik: false
          ));
        }
      }
    }

    // Kalıp bozulup az sayıda bildirim bulursa test sessizce geçmesin.
    expect(bildirimler.length, greaterThan(700),
        reason: 'Bildirim kalıbı bozulmuş olabilir: '
            '${bildirimler.length} sabit bulundu, oysa kod tabanı çok '
            'daha fazlasını taşıyor.');

    final List<String> olu = <String>[];
    for (final ({String ad, String dosya, String? sinif, int no, bool statik})
        b in bildirimler) {
      final String anahtar = '${b.sinif ?? '?'}.${b.ad}';
      if (kOkunmayanSabitler.containsKey(anahtar)) continue;

      bool okundu = false;
      if (b.statik) {
        // Statik sabit ya kendi dosyasında çıplak adıyla ya da başka bir
        // dosyada `Sınıf.ad` diye okunur. Ad çakışması yüzünden küresel
        // arama yapılmaz: `prototypeOnlyBaseChance` beş ayrı sınıfta var.
        final List<String> kendi = satirlar[b.dosya]!;
        for (int i = 0; i < kendi.length; i++) {
          if (i + 1 == b.no) continue;
          if (_okuyor(kendi[i], b.ad)) {
            okundu = true;
            break;
          }
        }
        if (!okundu && b.sinif != null) {
          okundu = tamMetin.values
              .any((String m) => m.contains('${b.sinif}.${b.ad}'));
        }
      } else {
        // Örnek alanı herhangi bir değişken üzerinden okunabilir:
        // `stil.prototypeOnlyHappiness`.
        okundu = satirlar.values.any((List<String> ls) =>
            ls.any((String l) => RegExp('\\.${b.ad}\\b').hasMatch(l)));
      }
      if (!okundu) {
        olu.add('$anahtar (${b.dosya.replaceFirst('lib/', '')}:${b.no})');
      }
    }

    expect(olu, isEmpty,
        reason: 'Bu sabitler bildirilmiş ama hiç okunmuyor. Yanında duran '
            'belge yorumu yüzünden yürürlükteki kural gibi görünüyorlar. '
            'Ya bağlayın, ya silin, ya da gerekçesiyle '
            'kOkunmayanSabitler listesine ekleyin:\n  '
            '${olu.join('\n  ')}');
  });

  test('her muafiyetin yazılı gerekçesi var', () {
    for (final MapEntry<String, String> e in kOkunmayanSabitler.entries) {
      expect(e.value.trim().length, greaterThan(25),
          reason: '${e.key} muafiyeti gerekçesiz: bir sabitin okunmadan '
              'durmasi bir tercih olmali, unutulmus bir eksik degil.');
    }
  });
}
