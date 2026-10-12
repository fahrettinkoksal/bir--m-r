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
    final Set<String> sekmeKokleri = <String>{
      for (final SekmeKaresi k in kSekmeKareleri) k.dosya,
    };
    for (final String d in dosyalar) {
      if (dokumde.contains(d)) continue;
      // Sekme kökleri: `ekran_dokumu_test.dart` aynı listeyi dolaşıp
      // metnini basıyor (Paket DQ, §5 bunu denetler).
      if (sekmeKokleri.contains(d)) continue;
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
        'döküm ${dokumde.length} · sekme kökü ${sekmeKokleri.length} · '
        'başka testle ${kBaskaTestle.length}');
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
    // **Paket DQ — iddia neden sıkıştırıldı.** Beş kaydın beşini
    // ölçtüm: `pumpWidget`, `tester.tap` ve `print` sayıları ile
    // başlığın kaynakta **nerede** geçtiği. Sonuç:
    //
    //   sayfa                      test                          pump tap print
    //   activities_screen          content_reachability_test        0   0    0
    //   assets_screen              ekran_dokumu_test                2   5    1
    //   relationships_screen       ekran_dokumu_test                2   5    1
    //   school_career_screen       after_school_widget_test         1   6    0
    //   social_pages               social_widget_test               1   5    0
    //
    // `content_reachability_test.dart` **hiç widget kurmuyor**; bu
    // iddiayı yalnızca `group('Aktiviteler')` adıyla geçiyordu. Yani
    // bekçi bir ad çakışmasıyla tatmin oluyordu — tam olarak bu
    // yöntemin reddettiği şey. İki ek koşul geldi:
    //
    // 1. Adı yazılan test **ağacı kurmalı** (`pumpWidget`).
    // 2. Başlık, `group`/`test`/`testWidgets` **etiketi dışında**
    //    geçmeli.
    //
    // (`social_pages.dart` artık kayıtta değil: dökümün kendisi iki
    // karesini basıyor.)
    final List<String> sorunlar = <String>[];
    for (final MapEntry<String, String> e in kBaskaTestle.entries) {
      final File t = File('test/${e.value}');
      if (!t.existsSync()) continue; // §2 bunu ayrıca bildiriyor.
      final String kaynak = t.readAsStringSync();
      if (!kaynak.contains('pumpWidget')) {
        sorunlar.add('${e.key}: ${e.value} hiç `pumpWidget` çağırmıyor, '
            'yani o sayfayı **çizmiyor**. Kayıt yanlış ya da sayfa '
            'döküme girmeli.');
        continue;
      }
      // Etiket metinlerini boşalt: `group('Aktiviteler', …)` bir
      // kapsam kanıtı değildir.
      final String govde = kaynak.replaceAll(
        RegExp(r"(group|test|testWidgets)\(\s*'[^']*'"),
        r"$1('')",
      );
      final List<String> bas = basliklar(e.key);
      if (bas.isEmpty) {
        // Başlığı dinamik olan sayfa (ör. `widget.action.label`); bu
        // iddia metinle doğrulanamaz, döküme girmesi gerekir.
        sorunlar.add('${e.key}: `SectionScaffold` başlığı sabit değil, '
            'bu yüzden "başka testle okunuyor" iddiası '
            'doğrulanamıyor — döküme ekle.');
        continue;
      }
      if (!bas.any((String b) => govde.contains("'$b'"))) {
        sorunlar.add('${e.key}: ${e.value} bu sayfanın başlıklarından '
            'hiçbirini **gövdesinde** anmıyor (${bas.join(" · ")}). '
            'Kayıt yanlış, test artık o kareyi çizmiyor ya da ad '
            'yalnızca bir `group`/`test` etiketinde geçiyor.');
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

  test('§5 sekme kökü iddiası yapısal (Paket DQ)', () {
    // Dört sekme kökünün karesi `ekran_dokumu_test.dart` tarafından
    // basılıyor. Bu iddia **metin benzerliğiyle** tutulamaz: o testin
    // gövdesinde bu sayfaların hiçbir `SectionScaffold` başlığı
    // geçmiyor (ölçtüm: `school_career_screen.dart`'ın 30 başlığından
    // sıfırı). Bunun yerine iki taraf **aynı listeyi** okuyor.
    final List<String> dosyalar = bolumDosyalari();
    for (final SekmeKaresi k in kSekmeKareleri) {
      expect(dosyalar, contains(k.dosya),
          reason: '${k.ad}: kayıt var olmayan bir dosyayı gösteriyor '
              '(${k.dosya}).');
      expect(k.sekme.startsWith('tab_'), isTrue,
          reason: '${k.ad}: sekme anahtarı `tab_` ile başlamıyor.');
    }

    final File dokum = File('test/ekran_dokumu_test.dart');
    expect(dokum.existsSync(), isTrue);
    final String kaynak = dokum.readAsStringSync();
    expect(
      kaynak,
      contains('kSekmeKareleri'),
      reason: 'Döküm artık paylaşılan listeyi okumuyor; kapsam iddiası '
          'yapısal olmaktan çıktı.',
    );
    expect(kaynak, contains('pumpWidget'));
    expect(
      kaynak,
      contains('print('),
      reason: 'Sekme kökü iddiası "kare basılıyor" demek; basmayan bir '
          'test bu iddiayı taşıyamaz.',
    );
    // ignore: avoid_print
    print('SEKME KÖKÜ: ${kSekmeKareleri.length} kare · '
        'ekran_dokumu_test.dart basıyor');
  });
}
