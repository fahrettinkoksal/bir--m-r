import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/section_pages.dart';

/// **Paket DM — bölüm sayfalarının kapsam bekçisi.**
///
/// Paket DH'nin ekran denetimi `*_screen.dart` dosyalarını saymıştı;
/// oyunun içeriğinin büyük bölümü `sections/` altındaki `*_page.dart`
/// dosyalarında ve o dosyalar denetime hiç girmemişti. Ölçüm sekizinin
/// hiçbir testte okunmadığını gösterdi; döküm o sekizini açtı ve üç
/// gerçek kusur çıktı (ayrıntı `PROJECT_STATUS.md` Paket DM).
///
/// Bu test kapsamı **ileri doğru** tutar: `sections/` altına yeni bir
/// sayfa eklendiğinde ya döküme girer ya da onu çizen testin adı
/// kayda yazılır. Kayıt beyan değil **denetlenen** bir iddiadır: adı
/// yazılan testin o sayfanın başlıklarından birini gerçekten andığı
/// doğrulanır.
void main() {
  const String sectionsYolu = 'lib/ui/screens/sections';

  List<String> bolumDosyalari() => Directory(sectionsYolu)
      .listSync()
      .whereType<File>()
      .map((File f) => f.uri.pathSegments.last)
      .where((String ad) => ad.endsWith('.dart'))
      .toList()
    ..sort();

  /// Dosyadaki `SectionScaffold` başlıkları.
  List<String> basliklar(String dosya) {
    final String kaynak = File('$sectionsYolu/$dosya').readAsStringSync();
    return RegExp(r"title:\s*'([^']{3,40})'")
        .allMatches(kaynak)
        .map((RegExpMatch m) => m.group(1)!)
        .toSet()
        .toList();
  }

  test('§1 her bölüm sayfasının bir okuyucusu var', () {
    final List<String> dosyalar = bolumDosyalari();
    final Set<String> dokumde = <String>{
      for (final Bolum b in kBolumler) b.dosya,
    };
    final List<String> kapsamsiz = <String>[];
    for (final String d in dosyalar) {
      if (dokumde.contains(d)) continue;
      if (kBaskaTestle.containsKey(d)) continue;
      kapsamsiz.add(d);
    }

    expect(
      kapsamsiz,
      isEmpty,
      reason: 'Bu bölüm sayfalarını hiçbir test okumuyor:\n'
          '${kapsamsiz.join("\n")}\n\n'
          'Ya `test/support/section_pages.dart` içindeki kBolumler '
          'listesine ekleyip `ekran_dokumu_bolumler_test.dart` ile '
          'metnini bas, ya da onu çizen testin adını kBaskaTestle '
          'kaydına yaz. Kapsam **beyanla** değil okunan kareyle '
          'kapanır.',
    );
    // ignore: avoid_print
    print('BÖLÜM KAPSAMI: ${dosyalar.length} sayfa · '
        'döküm ${dokumde.length} · başka testle ${kBaskaTestle.length}');
  });

  test('§2 kayıt gerçek dosyaları gösterir', () {
    final List<String> dosyalar = bolumDosyalari();
    final List<String> sorunlar = <String>[];

    for (final Bolum b in kBolumler) {
      if (!dosyalar.contains(b.dosya)) {
        sorunlar.add('kBolumler["${b.ad}"] artık var olmayan bir dosyayı '
            'gösteriyor: ${b.dosya}');
      }
    }
    for (final MapEntry<String, String> e in kBaskaTestle.entries) {
      if (!dosyalar.contains(e.key)) {
        sorunlar.add('kBaskaTestle artık var olmayan bir sayfayı '
            'gösteriyor: ${e.key}');
      }
      if (!File('test/${e.value}').existsSync()) {
        sorunlar.add('${e.key} için yazılan test dosyası yok: ${e.value}');
      }
    }
    expect(sorunlar, isEmpty, reason: sorunlar.join('\n'));
  });

  test('§3 "başka testle okunuyor" iddiası denetlenir', () {
    final List<String> sorunlar = <String>[];
    for (final MapEntry<String, String> e in kBaskaTestle.entries) {
      final File t = File('test/${e.value}');
      if (!t.existsSync()) continue; // §2 bunu ayrıca bildiriyor.
      final String kaynak = t.readAsStringSync();
      final List<String> bas = basliklar(e.key);
      if (bas.isEmpty) {
        // Başlığı dinamik olan sayfa (ör. `widget.action.label`); bu
        // iddia metinle doğrulanamaz, döküme girmesi gerekir.
        sorunlar.add('${e.key}: `SectionScaffold` başlığı sabit değil, '
            'bu yüzden "başka testle okunuyor" iddiası '
            'doğrulanamıyor — döküme ekle.');
        continue;
      }
      if (!bas.any((String b) => kaynak.contains("'$b'"))) {
        sorunlar.add('${e.key}: ${e.value} bu sayfanın başlıklarından '
            'hiçbirini anmıyor (${bas.join(" · ")}). Kayıt yanlış ya da '
            'test artık o kareyi çizmiyor.');
      }
    }
    expect(sorunlar, isEmpty, reason: sorunlar.join('\n'));
  });

  test('§4 döküm kaydı tekrarsız', () {
    // **Paket DO.** Ölçü dosya değil **kare**: `activity_pages.dart`
    // altı ayrı sayfa barındırıyor, hepsinin kendi karesi var. Bu
    // yüzden tekrarsızlık dosyada değil **adda** aranıyor.
    final List<String> adlar = <String>[
      for (final Bolum b in kBolumler) b.ad,
    ];
    expect(
      adlar.toSet().length,
      adlar.length,
      reason: 'Aynı kare döküm listesinde iki kez: $adlar',
    );
    for (final Bolum b in kBolumler) {
      expect(
        kBaskaTestle.containsKey(b.dosya),
        isFalse,
        reason: '${b.dosya} hem dökümde hem kBaskaTestle kaydında; '
            'kapsam tek yerden okunmalı.',
      );
      expect(b.isaret.trim().length, greaterThan(5),
          reason: '${b.ad}: işaret, sayfayı ayırt edemeyecek kadar kısa.');
      expect(b.yol, isNotEmpty, reason: '${b.ad}: yol boş.');
    }
  });
}
