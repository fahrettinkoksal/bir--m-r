import 'package:bir_omur/domain/models/life_log.dart';
import 'package:bir_omur/text/turkish_text.dart';
import 'package:bir_omur/ui/widgets/life_log_view.dart';
import 'package:bir_omur/ui/widgets/stat_bar.dart';
import 'package:bir_omur/ui/theme/bir_omur_theme.dart';
import 'package:bir_omur/ui/widgets/comic.dart';
import 'package:bir_omur/ui/widgets/section_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Arayüz cilası (Paket F2): biçimlendirme ve gruplama kuralları.
void main() {
  group('Para biçimi', () {
    test('binlik ayırıcı Türkçe biçimde', () {
      expect(trNumber(0), '0');
      expect(trNumber(999), '999');
      expect(trNumber(1000), '1.000');
      expect(trNumber(20000), '20.000');
      expect(trNumber(163400), '163.400');
      expect(trNumber(3500000), '3.500.000');
    });

    test('eksi tutar ve para birimi', () {
      expect(trNumber(-2500), '-2.500');
      expect(trMoney(163400), '163.400 ₺');
      expect(trMoney(0), '0 ₺');
    });
  });

  group('Hayat günlüğü gruplaması', () {
    List<LifeLogEntry> satirlar() => <LifeLogEntry>[
          const LifeLogEntry(
            age: 0,
            text: 'Dünyaya geldin.',
            category: LogCategory.dogum,
          ),
          const LifeLogEntry(
            age: 1,
            text: '1 yaşına girdin.',
            category: LogCategory.yasDegisimi,
          ),
          const LifeLogEntry(
            age: 1,
            text: 'İlk adımını attın.',
            category: LogCategory.aile,
          ),
          const LifeLogEntry(
            age: 2,
            text: '2 yaşına girdin.',
            category: LogCategory.yasDegisimi,
          ),
        ];

    test('satırlar yaşa göre kümelenir, en yeni yaş başta', () {
      final List<LifeLogBlock> bloklar = groupLogByAge(satirlar());
      expect(bloklar.map((LifeLogBlock b) => b.age), <int>[2, 1, 0]);
      expect(bloklar.first.entries.length, 1);
      expect(bloklar[1].entries.length, 2);
      // Bir yaşın içinde de en yeni satır başta.
      expect(bloklar[1].entries.first.text, 'İlk adımını attın.');
    });

    test('boş günlükte blok üretilmez', () {
      expect(groupLogByAge(const <LifeLogEntry>[]), isEmpty);
    });

    testWidgets('her yaş tek başlık altında toplanır', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: BirOmurTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: LifeLogView(entries: satirlar()),
            ),
          ),
        ),
      );

      // Yaş başlığı yalnızca bir kez yazılır; eskiden her satırda
      // tekrarlanıyordu.
      expect(find.text('1 yaş'), findsOneWidget);
      expect(find.text('2 yaş'), findsOneWidget);
      expect(find.text('0 yaş'), findsOneWidget);
      // En yeni yaş "BU YIL" diye işaretlenir.
      expect(find.text('BU YIL'), findsOneWidget);
      expect(find.byKey(const Key('log_age_2')), findsOneWidget);
      // Metinler kaybolmaz.
      expect(find.text('İlk adımını attın.'), findsOneWidget);
      expect(find.text('Dünyaya geldin.'), findsOneWidget);
    });
  });

  group('Türkçe büyük harf', () {
    test('ilk harf Türkçe kurallarıyla büyür', () {
      // Dart'ın toUpperCase() çağrısı "işçi" kelimesini "Işçi" yapıyordu.
      expect(trUpperFirst('işçi'), 'İşçi');
      expect(trUpperFirst('ilkokul öğretmeni'), 'İlkokul öğretmeni');
      expect(trUpperFirst('eşin'), 'Eşin');
      expect(trUpperFirst('ırmak'), 'Irmak');
      expect(trUpperFirst(''), '');
    });

    test('kategori başlığı Türkçe büyür', () {
      expect(trUpper('Aile'), 'AİLE');
      expect(trUpper('Kişisel'), 'KİŞİSEL');
    });
  });

  group('Değer rengi', () {
    testWidgets('düşük değer uyarı, yüksek değer olumlu renk alır',
        (WidgetTester tester) async {
      late ThemeData theme;
      await tester.pumpWidget(
        MaterialApp(
          theme: BirOmurTheme.light(),
          home: Builder(
            builder: (BuildContext context) {
              theme = Theme.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      // Afiş renkleri iki temada da aynı okunur (Paket 19).
      expect(statColor(theme, 10), BirOmurColors.degerDusuk);
      expect(statColor(theme, 45), BirOmurColors.degerOrta);
      expect(statColor(theme, 90), BirOmurColors.degerYuksek);
    });

    testWidgets('karanlık temada renkler birbirinden ayırt edilebilir',
        (WidgetTester tester) async {
      late ThemeData koyu;
      await tester.pumpWidget(
        MaterialApp(
          theme: BirOmurTheme.dark(),
          home: Builder(
            builder: (BuildContext context) {
              koyu = Theme.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      final Color dusuk = statColor(koyu, 10);
      final Color orta = statColor(koyu, 45);
      final Color yuksek = statColor(koyu, 90);
      // Koyu temada "iyi" ile "orta" aynı sarıya düşüyordu.
      expect(yuksek, isNot(orta));
      expect(yuksek, isNot(dusuk));
      expect(orta, isNot(dusuk));
      expect(yuksek, BirOmurColors.degerYuksek);
    });
  });

  // ===================================================================
  // Menü görünümü (Paket 8): renkli, dokunması kolay satırlar.
  //
  // Renk değerleri `prototypeOnly` (Q-077); testler renk kodunu değil,
  // **davranışı** sınar: her satır kendi rengini taşıyor mu, açık ve
  // koyu temada farklı ton kullanılıyor mu, içerik yerinde mi.
  // ===================================================================
  group('Menü satırı', () {
    Future<void> pump(
      WidgetTester tester,
      Widget child, {
      Brightness brightness = Brightness.light,
    }) =>
        tester.pumpWidget(
          MaterialApp(
            theme: brightness == Brightness.dark
                ? BirOmurTheme.dark()
                : BirOmurTheme.light(),
            home: Scaffold(body: child),
          ),
        );

    testWidgets('başlık, açıklama ve sayaç birlikte görünür',
        (WidgetTester tester) async {
      await pump(
        tester,
        MenuRow(
          title: 'Kütüphane',
          subtitle: 'Yaşına uygun kitap seç',
          icon: Icons.local_library_outlined,
          trailingText: '7',
          accent: BirOmurAccents.mavi,
          onTap: () {},
        ),
      );

      expect(find.text('Kütüphane'), findsOneWidget);
      expect(find.text('Yaşına uygun kitap seç'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      expect(find.byType(ComicIconTile), findsOneWidget);
    });

    testWidgets('dokunma eylemi çalışır', (WidgetTester tester) async {
      int dokunma = 0;
      await pump(
        tester,
        MenuRow(
          title: 'Vasiyet',
          icon: Icons.history_edu_outlined,
          onTap: () => dokunma++,
        ),
      );

      await tester.tap(find.text('Vasiyet'));
      await tester.pumpAndSettle();
      expect(dokunma, 1);
    });

    testWidgets('her satır kendi rengini taşır', (WidgetTester tester) async {
      late Color mavi;
      late Color gul;
      await tester.pumpWidget(
        MaterialApp(
          theme: BirOmurTheme.light(),
          home: Builder(
            builder: (BuildContext context) {
              mavi = BirOmurAccents.mavi.of(context);
              gul = BirOmurAccents.gul.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(mavi, isNot(gul));
    });

    testWidgets('afiş rengi iki temada da aynı kalır',
        (WidgetTester tester) async {
      late Color acik;
      late Color koyu;
      await tester.pumpWidget(
        MaterialApp(
          theme: BirOmurTheme.light(),
          home: Builder(
            builder: (BuildContext context) {
              acik = BirOmurAccents.mor.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: BirOmurTheme.dark(),
          home: Builder(
            builder: (BuildContext context) {
              koyu = BirOmurAccents.mor.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      // MaterialApp tema geçişini animasyonla yapar; son kareyi bekle.
      await tester.pumpAndSettle();
      // Çizgi roman dilinde renkleri kontur çerçevelediği için afiş
      // tonları iki temada da okunur; ayrı bir gece paleti gerekmiyor
      // (Paket 19).
      expect(acik, koyu);
    });

    testWidgets('bölüm başlığında geri dönüş bulunur',
        (WidgetTester tester) async {
      bool geri = false;
      await pump(
        tester,
        SectionScaffold(
          title: 'Aktiviteler',
          subtitle: 'Bu yıl yapabileceklerin',
          backLabel: 'Hayat',
          accent: BirOmurAccents.turuncu,
          onBack: () => geri = true,
          children: const <Widget>[Text('içerik')],
        ),
      );

      expect(find.text('Aktiviteler'), findsOneWidget);
      expect(find.text('içerik'), findsOneWidget);
      await tester.tap(find.text('Hayat'));
      await tester.pumpAndSettle();
      expect(geri, isTrue);
    });
  });

  // ===================================================================
  // Görsel kimlik (Paket 16): canlı renkler, renksiz kartlar.
  //
  // Renk kodları `prototypeOnly` (Q-077/Q-084); testler tek tek ton
  // sınamaz, kuralı sınar: kart zemini vurgu rengiyle boyanmıyor mu,
  // başlık kartı gerçekten görünüyor mu, koyu başlıkta değerler
  // birbirinden ayrılıyor mu.
  // ===================================================================
  group('Paket 16 görsel kimlik', () {
    testWidgets('menü satırı çıkartma düğmesidir ve rengini ikonda taşır',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: BirOmurTheme.light(),
          home: Scaffold(
            body: MenuRow(
              title: 'Seyahat',
              icon: Icons.luggage_outlined,
              accent: BirOmurAccents.gul,
              onTap: () {},
            ),
          ),
        ),
      );

      // Satır basılabilir bir çıkartmadır; renk ikon kutusundadır.
      expect(find.byType(StickerButton), findsOneWidget);
      expect(find.byType(ComicIconTile), findsOneWidget);
      final ComicIconTile kutu =
          tester.widget<ComicIconTile>(find.byType(ComicIconTile));
      expect(kutu.accent.color, BirOmurAccents.gul.color);
    });

    testWidgets('kartlarda degrade kullanılmaz', (WidgetTester tester) async {
      // Degrade, iki kez reddedilen "genel uygulama" görüntüsünün en
      // belirgin işaretiydi; çizgi roman dilinde hiç kullanılmaz.
      await tester.pumpWidget(
        MaterialApp(
          theme: BirOmurTheme.light(),
          home: Scaffold(
            body: SectionScaffold(
              title: 'Seyahat',
              icon: Icons.luggage_rounded,
              accent: BirOmurAccents.mavi,
              children: <Widget>[
                MenuRow(
                  title: 'Otobüs',
                  icon: Icons.directions_bus_rounded,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      );

      for (final Element e in find.byType(Container).evaluate()) {
        final Decoration? d = (e.widget as Container).decoration;
        if (d is BoxDecoration) {
          expect(d.gradient, isNull, reason: 'Degrade bulundu.');
        }
      }
    });

    testWidgets('bölüm başlığı başlığı ve simgesini gösterir',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: BirOmurTheme.light(),
          home: Scaffold(
            body: SectionScaffold(
              title: 'Seyahat',
              subtitle: 'Kısa bir gezi',
              icon: Icons.luggage_rounded,
              accent: BirOmurAccents.mavi,
              children: const <Widget>[Text('içerik')],
            ),
          ),
        ),
      );

      expect(find.byType(SectionTitle), findsOneWidget);
      expect(find.text('Seyahat'), findsOneWidget);
      expect(find.text('Kısa bir gezi'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(SectionTitle),
          matching: find.byIcon(Icons.luggage_rounded),
        ),
        findsOneWidget,
      );
    });

    testWidgets('kart zemini sayfa zemininden ayrıdır',
        (WidgetTester tester) async {
      late ThemeData theme;
      await tester.pumpWidget(
        MaterialApp(
          theme: BirOmurTheme.light(),
          home: Builder(
            builder: (BuildContext context) {
              theme = Theme.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      // Kart ile zemin arasında gerçek bir fark olmalı; ayrıca her kartın
      // mürekkep konturu vardır.
      final Color zemin = theme.colorScheme.surface;
      final Color kart = theme.colorScheme.surfaceContainerHighest;
      expect(kart, isNot(zemin));
      expect(kart.computeLuminance(), greaterThan(zemin.computeLuminance()));
      expect(theme.colorScheme.outline, BirOmurColors.murekkep);
    });

    test('üç değer aralığı ayrı renk alır', () {
      final Color dusuk = statColorOnDark(10);
      final Color orta = statColorOnDark(45);
      final Color yuksek = statColorOnDark(90);
      expect(dusuk, isNot(orta));
      expect(orta, isNot(yuksek));
      expect(dusuk, isNot(yuksek));
    });
  });
}
