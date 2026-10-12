import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/section_pages.dart';

/// **Paket DS — modal kapsam kaydının bekçisi.**
///
/// Paket DR `lib/ui/widgets/` altındaki dosyaları üç listeye ayırdı:
/// dökümün açtıkları (`kModalKareleri`), bekleyenler (`kModalBekleyen`)
/// ve "başka testle okunanlar" (`kModalBaskaTestle`). Sonra ölçtüm:
/// son iki liste depoda **sıfır** yerden çağrılıyordu. Yani kayıt
/// yazılmış, bekçisi yazılmamıştı — ve denetlenmeyen kayıt hemen
/// eskidi:
///
///   · `notice_sheet.dart` "başka döküm basıyor" diye kayıtlıydı; o
///     döküm bildirimin **içeriğini** basıyor, pencerenin kendi 13
///     cümlesini değil (cenaze seçenekleri, bebeğe ad verme). Ölçüm:
///     "Cenazeye katıl" 0, "Bebeğin adını sen koyabilirsin" 0.
///   · `elder_support_card`, `health_crisis_sheet`, `trial_sheet`,
///     `pregnancy_notice` ve `person_card` "bekliyor" diye kayıtlıydı;
///     beşi de özel durum dökümünde **basılıyordu**.
///   · `prison_life_panel` gerçekten basılmıyordu ama nedeni "bekleyen
///     durum" değildi: panel bir menü satırının arkasındaydı ve döküm
///     o satırı basıp hiç **dokunmuyordu**. Kare eklendi.
///   · `interview_sheet` basılmıyordu ve nedeni **ürün hatasıydı**
///     (öğrencinin mülakata devam etme yolu yoktu).
///
/// Bu test üç şeyi tutar: her metin taşıyan dosyanın bir kaydı var,
/// kayıtlar gerçek dosyaları gösteriyor, ve bir dosya iki listede
/// birden durmuyor. Dördüncü halka — "o test gerçekten basıyor mu" —
/// burada değil, **basan testin içinde**: her döküm
/// `modalKapsamDenetle` çağırıp kendi kayıtlarının işaretlerini
/// bastığı karelerde arıyor. Kaynak taraması bunu yapamaz, çünkü
/// dökümün bastığı metin kaynağında yazmaz.
void main() {
  const String widgetYolu = 'lib/ui/widgets';

  List<String> widgetDosyalari() => Directory(widgetYolu)
      .listSync()
      .whereType<File>()
      .map((File f) => f.uri.pathSegments.last)
      .where((String ad) => ad.endsWith('.dart'))
      .toList()
    ..sort();

  /// Dosyanın **çizdiği** cümle sayısı.
  ///
  /// Ölçü üç kez daraltıldı, her daraltma bir yanlış saymayı
  /// düzeltti:
  ///
  /// 1. Yorum satırları atılıyor (Paket DH dersi).
  /// 2. `assert(...)` satırları atılıyor — `bottom_action_bar.dart`ın
  ///    tek "cümlesi" bir assert mesajıydı ("Alt gezinmede dört ana
  ///    menü olmalı (NAV-001)."), oyuncuya dönük metin değil.
  /// 3. Karşılaştırmaya giren dizgiler atılıyor — `character_face.dart`
  ///    bir saç modeli **adını arıyor** (`contains('Yana ayrılmış')`),
  ///    yazmıyor.
  /// 4. İnterpolasyon çıkarıldıktan sonra 12 karakterden kısa kalan
  ///    dizgiler sayılmıyor: `'${horse.lane}. ${horse.name}'` bir
  ///    etiket, cümle değil.
  int cumleSayisi(String dosya) {
    final List<String> satirlar = File('$widgetYolu/$dosya')
        .readAsLinesSync()
        .where((String l) {
          final String t = l.trimLeft();
          return !t.startsWith('//') && !t.startsWith('///') &&
              !l.contains('assert(');
        })
        .toList(growable: false);
    String govde = satirlar.join('\n');
    govde = govde.replaceAll(
      RegExp(r"(contains|startsWith|endsWith)\(\s*'[^'\n]*'"),
      r"$1('')",
    );
    govde = govde.replaceAll(RegExp(r"==\s*'[^'\n]*'"), "== ''");
    int n = 0;
    for (final RegExpMatch m
        in RegExp(r"'([^'\n]{8,})'").allMatches(govde)) {
      String sade = m.group(1)!;
      sade = sade.replaceAll(RegExp(r'\$\{[^}]*\}'), '');
      sade = sade.replaceAll(RegExp(r'\$\w+'), '').trim();
      if (sade.contains(' ') && sade.length >= 12) n++;
    }
    return n;
  }

  test('§1 metin taşıyan her widget dosyasının bir kaydı var', () {
    final List<String> dosyalar = widgetDosyalari();
    final Set<String> dokumde = <String>{
      for (final Bolum b in kModalKareleri) b.dosya,
    };
    final Set<String> baskaTestle = <String>{
      for (final ModalKaydi k in kModalBaskaTestle) k.dosya,
    };
    final Set<String> bekleyen = kModalBekleyen.toSet();

    final List<String> kapsamsiz = <String>[];
    final List<String> tablo = <String>[];
    for (final String d in dosyalar) {
      final int n = cumleSayisi(d);
      if (n == 0) continue;
      final String nerede = dokumde.contains(d)
          ? 'döküm'
          : baskaTestle.contains(d)
              ? 'başka test'
              : bekleyen.contains(d)
                  ? 'bekliyor'
                  : 'KAYIT YOK';
      tablo.add('${n.toString().padLeft(3)} cümle · $d · $nerede');
      if (nerede == 'KAYIT YOK') kapsamsiz.add('$d ($n cümle)');
    }
    // ignore: avoid_print
    print('MODAL KAPSAMI (${dosyalar.length} dosya · '
        '${tablo.length} metin taşıyor)\n${tablo.join("\n")}');

    expect(
      kapsamsiz,
      isEmpty,
      reason: 'Bu widget dosyaları oyuncuya metin yazıyor ama kapsam '
          'kaydında hiç yok:\n${kapsamsiz.join("\n")}\n\n'
          'Ya `kModalKareleri` listesine bir kare ekle, ya karesini '
          'basan testi `kModalBaskaTestle` kaydına yaz (o test '
          '`modalKapsamDenetle` çağırmalı), ya da ölçülmüş bir '
          'gerekçeyle `kModalBekleyen` kuyruğuna al. Kapsam beyanla '
          'değil basılan kareyle kapanır.',
    );
  });

  test('§2 kayıtlar gerçek dosyaları gösteriyor', () {
    final List<String> dosyalar = widgetDosyalari();
    final List<String> sorunlar = <String>[];

    for (final Bolum b in kModalKareleri) {
      if (!dosyalar.contains(b.dosya)) {
        sorunlar.add('kModalKareleri["${b.ad}"] var olmayan bir dosyayı '
            'gösteriyor: ${b.dosya}');
      }
    }
    for (final String d in kModalBekleyen) {
      if (!dosyalar.contains(d)) {
        sorunlar.add('kModalBekleyen var olmayan bir dosyayı '
            'gösteriyor: $d');
      }
    }
    for (final ModalKaydi k in kModalBaskaTestle) {
      if (!dosyalar.contains(k.dosya)) {
        sorunlar.add('kModalBaskaTestle var olmayan bir dosyayı '
            'gösteriyor: ${k.dosya}');
      }
      if (!File('test/${k.test}').existsSync()) {
        sorunlar.add('${k.dosya} için yazılan test dosyası yok: '
            '${k.test}');
      }
    }
    expect(sorunlar, isEmpty, reason: sorunlar.join('\n'));
  });

  test('§3 "başka testle okunuyor" iddiasının üç halkası', () {
    // **Paket DQ'nun dersi burada da geçerli:** ad benzerliği kapsam
    // kanıtı değil. Üç halka:
    //
    // 1. İşaret o widget'ın **kendi kaynağında** geçiyor (kayıt
    //    uydurma değil). DR'nin `notice_sheet` kaydı tam burada
    //    düştü: yazdığım işaret dosyada hiç yoktu.
    // 2. Adı yazılan test ağacı **kuruyor** ve kareyi **basıyor**
    //    (`pumpWidget` + `print`).
    // 3. O test `modalKapsamDenetle` çağırıyor, yani iddiayı kendi
    //    çalışmasında doğruluyor.
    final List<String> sorunlar = <String>[];
    for (final ModalKaydi k in kModalBaskaTestle) {
      expect(k.isaret.trim().length, greaterThan(5),
          reason: '${k.dosya}: işaret ayırt edemeyecek kadar kısa.');

      final File widgetDosyasi = File('$widgetYolu/${k.dosya}');
      if (widgetDosyasi.existsSync() &&
          !widgetDosyasi.readAsStringSync().contains(k.isaret)) {
        sorunlar.add('${k.dosya}: işaret ("${k.isaret}") bu dosyanın '
            'kaynağında hiç geçmiyor. Kayıt uydurma ya da metin '
            'değişti.');
      }

      final File test = File('test/${k.test}');
      if (!test.existsSync()) continue; // §2 bunu ayrıca bildiriyor.
      final String kaynak = test.readAsStringSync();
      if (!kaynak.contains('pumpWidget')) {
        sorunlar.add('${k.dosya}: ${k.test} hiç `pumpWidget` '
            'çağırmıyor, yani o kareyi çizmiyor.');
      }
      if (!kaynak.contains('print(')) {
        sorunlar.add('${k.dosya}: ${k.test} kareyi basmıyor; '
            '"okunuyor" iddiası basılan kareye dayanır.');
      }
      if (!kaynak.contains('modalKapsamDenetle')) {
        sorunlar.add('${k.dosya}: ${k.test} `modalKapsamDenetle` '
            'çağırmıyor. İddiayı basan taraf doğrulamalı; yoksa kayıt '
            'sessizce eskir (Paket DR tam böyle eskidi).');
      }
    }
    expect(sorunlar, isEmpty, reason: sorunlar.join('\n'));
    // ignore: avoid_print
    print('BAŞKA TESTLE OKUNAN: ${kModalBaskaTestle.length} dosya · '
        'hepsinin işareti kaynağında ve basan testinde doğrulanıyor');
  });

  test('§4 bir dosya iki listede durmuyor', () {
    final List<String> hepsi = <String>[
      for (final Bolum b in kModalKareleri) b.dosya,
      ...kModalBekleyen,
      for (final ModalKaydi k in kModalBaskaTestle) k.dosya,
    ];
    final Map<String, int> sayim = <String, int>{};
    for (final String d in hepsi) {
      sayim[d] = (sayim[d] ?? 0) + 1;
    }
    // `kModalKareleri` aynı dosyanın birkaç karesini taşıyabilir
    // (kişi kartının üç kapısı); ölçü **liste sayısı**.
    final Set<String> dokumde = <String>{
      for (final Bolum b in kModalKareleri) b.dosya,
    };
    final List<String> cakisan = <String>[
      for (final String d in <String>{...hepsi})
        if (<bool>[
              dokumde.contains(d),
              kModalBekleyen.contains(d),
              kModalBaskaTestle.any((ModalKaydi k) => k.dosya == d),
            ].where((bool x) => x).length >
            1)
          d,
    ];
    expect(
      cakisan,
      isEmpty,
      reason: 'Bu dosyalar birden fazla kapsam listesinde; kapsam tek '
          'yerden okunmalı:\n${cakisan.join("\n")}',
    );

    // Kare adları tekrarsız (Paket DO'nun ölçüsü: dosya değil **kare**).
    final List<String> adlar = <String>[
      for (final Bolum b in kModalKareleri) b.ad,
    ];
    expect(adlar.toSet().length, adlar.length,
        reason: 'Aynı kare modal listesinde iki kez: $adlar');
    for (final Bolum b in kModalKareleri) {
      expect(b.isaret.trim().length, greaterThan(5),
          reason: '${b.ad}: işaret, kareyi ayırt edemeyecek kadar kısa.');
      expect(b.yol, isNotEmpty, reason: '${b.ad}: yol boş.');
      expect(b.sekme.startsWith('tab_'), isTrue,
          reason: '${b.ad}: sekme anahtarı `tab_` ile başlamıyor.');
    }
  });

  test('§5 bekleme kuyruğu yalnızca küçülür', () {
    // Paket DS'de ölçülen hâli: iki dosya. Kuyruk büyüyorsa ya yeni
    // bir metin taşıyan widget okunmadan eklendi ya da basılan bir
    // kare kaybedildi — ikisi de bildirilmeli.
    expect(
      kModalBekleyen.length,
      lessThanOrEqualTo(3),
      reason: 'Bekleme kuyruğu büyümüş: ${kModalBekleyen.join(", ")}\n'
          'Paket DS ölçümünde üç dosya vardı (notice_sheet, '
          'license_exam_sheet, track_choice_sheet). Yeni bir dosya '
          'okunmadan kuyruğa atılıyorsa kareyi yaz; basılan bir kare '
          'kaybedildiyse nedenini bul.',
    );
    // ignore: avoid_print
    print('BEKLEME KUYRUĞU: ${kModalBekleyen.length} dosya · '
        '${kModalBekleyen.join(" · ")}');
  });
}
