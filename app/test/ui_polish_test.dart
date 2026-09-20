import 'package:bir_omur/domain/models/life_log.dart';
import 'package:bir_omur/text/turkish_text.dart';
import 'package:bir_omur/ui/widgets/life_log_view.dart';
import 'package:bir_omur/ui/widgets/stat_bar.dart';
import 'package:bir_omur/ui/theme/bir_omur_theme.dart';
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
      // En yeni yaş "bu yıl" diye işaretlenir.
      expect(find.text('bu yıl'), findsOneWidget);
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

      expect(statColor(theme, 10), theme.colorScheme.error);
      expect(statColor(theme, 45), BirOmurColors.pirinc);
      expect(statColor(theme, 90), BirOmurColors.cini);
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
      expect(yuksek, BirOmurColors.geceCini);
    });
  });
}
