import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/player_character.dart';
import 'package:bir_omur/domain/models/stats.dart';
import 'package:bir_omur/ui/theme/bir_omur_theme.dart';
import 'package:bir_omur/ui/widgets/character_face.dart';
import 'package:bir_omur/ui/widgets/comic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Çizgi roman arayüzünün kuralları (Paket 19).
///
/// Testler renk kodu ezberlemez; **kuralı** sınar: degrade yok, her
/// yüzeyin konturu var, gölge bulanık değil, düğme basınca çöküyor.
PlayerCharacter oyuncu({
  int age = 20,
  Gender gender = Gender.kadin,
  int happiness = 60,
  int health = 70,
  String? hairStyle,
}) {
  return PlayerCharacter(
    id: 'p1',
    firstName: 'Deniz',
    lastName: 'Yılmaz',
    gender: gender,
    age: age,
    birthCity: 'Gaziantep',
    hairStyle: hairStyle,
    stats: Stats(
      appearance: 50,
      happiness: happiness,
      health: health,
      intelligence: 50,
      charisma: 50,
    ),
  );
}

Future<void> pump(WidgetTester tester, Widget child,
    {Brightness brightness = Brightness.light}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: brightness == Brightness.dark
          ? BirOmurTheme.dark()
          : BirOmurTheme.light(),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  // ===================================================================
  // Tasarım kuralları
  // ===================================================================
  group('Çizgi roman kuralları', () {
    testWidgets('kartın konturu ve keskin gölgesi vardır',
        (WidgetTester tester) async {
      await pump(tester, const ComicCard(child: Text('merhaba')));

      final Container kart = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(ComicCard),
              matching: find.byType(Container),
            )
            .first,
      );
      final BoxDecoration d = kart.decoration! as BoxDecoration;
      expect(d.gradient, isNull, reason: 'Kartta degrade olmamalı.');
      expect(d.border, isNotNull, reason: 'Kartın konturu olmalı.');
      expect(d.boxShadow, isNotNull);
      // Gölge bulanık değil, kaydırılmıştır.
      expect(d.boxShadow!.single.blurRadius, 0);
      expect(d.boxShadow!.single.offset.dy, greaterThan(0));
    });

    testWidgets('gölge rengi mürekkeptir, siyahın yumuşatılmışı değil',
        (WidgetTester tester) async {
      late List<BoxShadow> golge;
      await pump(
        tester,
        Builder(
          builder: (BuildContext context) {
            golge = comicShadow(context);
            return const SizedBox();
          },
        ),
      );
      expect(golge.single.color, BirOmurColors.murekkep);
      expect(golge.single.color.a, 1.0);
    });

    testWidgets('koyu temada kontur karttan daha koyudur',
        (WidgetTester tester) async {
      late Color kontur;
      late Color kart;
      await pump(
        tester,
        Builder(
          builder: (BuildContext context) {
            kontur = Comic.konturOf(context);
            kart = Theme.of(context).colorScheme.surfaceContainerHighest;
            return const SizedBox();
          },
        ),
        brightness: Brightness.dark,
      );
      // Çizgi koyu zeminde de görünmeli.
      expect(
        kontur.computeLuminance(),
        lessThan(kart.computeLuminance()),
      );
    });

    testWidgets('çıkartma düğmesi basınca çöker ve gölgesini bırakır',
        (WidgetTester tester) async {
      int sayac = 0;
      await pump(
        tester,
        StickerButton(
          sound: null,
          onPressed: () => sayac++,
          child: const Text('Bas'),
        ),
      );

      BoxDecoration govde() {
        final AnimatedContainer c = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer),
        );
        return c.decoration! as BoxDecoration;
      }

      expect(govde().boxShadow, isNotNull);

      final TestGesture parmak =
          await tester.startGesture(tester.getCenter(find.text('Bas')));
      await tester.pump(const Duration(milliseconds: 100));
      expect(govde().boxShadow, isNull, reason: 'Basılıyken gölge kalkmalı.');

      await parmak.up();
      await tester.pumpAndSettle();
      expect(govde().boxShadow, isNotNull);
      expect(sayac, 1);
    });

    testWidgets('kapalı düğme ne çöker ne de çalışır',
        (WidgetTester tester) async {
      await pump(
        tester,
        const StickerButton(
          sound: null,
          onPressed: null,
          child: Text('Kapalı'),
        ),
      );

      await tester.tap(find.text('Kapalı'));
      await tester.pumpAndSettle();
      final AnimatedContainer c =
          tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
      expect((c.decoration! as BoxDecoration).boxShadow, isNull);
    });

    testWidgets('rozet eğik durabilir ama metnini kaybetmez',
        (WidgetTester tester) async {
      await pump(tester, const ComicTag(text: '12 yaş', tilt: -3));
      expect(find.text('12 yaş'), findsOneWidget);
      expect(find.byType(Transform), findsWidgets);
    });
  });

  // ===================================================================
  // Karakter yüzü
  // ===================================================================
  group('Karakter yüzü', () {
    testWidgets('çizilir ve oyuncunun verisini kullanır',
        (WidgetTester tester) async {
      await pump(tester, CharacterFace(player: oyuncu(), size: 80));
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('mutluluk değişince yeniden çizilir',
        (WidgetTester tester) async {
      await pump(
        tester,
        CharacterFace(player: oyuncu(happiness: 10), size: 80),
      );
      final CustomPaint ilk = tester.widget<CustomPaint>(
        find
            .descendant(
              of: find.byType(CharacterFace),
              matching: find.byType(CustomPaint),
            )
            .first,
      );

      await pump(
        tester,
        CharacterFace(player: oyuncu(happiness: 95), size: 80),
      );
      final CustomPaint ikinci = tester.widget<CustomPaint>(
        find
            .descendant(
              of: find.byType(CharacterFace),
              matching: find.byType(CustomPaint),
            )
            .first,
      );

      expect(ikinci.painter!.shouldRepaint(ilk.painter!), isTrue);
    });

    testWidgets('yaş, saç stili ve cinsiyet değişimi yeni çizim ister',
        (WidgetTester tester) async {
      Future<CustomPainter> ciz(PlayerCharacter p) async {
        await pump(tester, CharacterFace(player: p, size: 80));
        return tester
            .widget<CustomPaint>(
              find
                  .descendant(
                    of: find.byType(CharacterFace),
                    matching: find.byType(CustomPaint),
                  )
                  .first,
            )
            .painter!;
      }

      final CustomPainter taban = await ciz(oyuncu());
      expect((await ciz(oyuncu(age: 70))).shouldRepaint(taban), isTrue);
      expect(
        (await ciz(oyuncu(hairStyle: 'Dağınık'))).shouldRepaint(taban),
        isTrue,
      );
      expect(
        (await ciz(oyuncu(gender: Gender.erkek))).shouldRepaint(taban),
        isTrue,
      );
      expect((await ciz(oyuncu())).shouldRepaint(taban), isFalse);
    });

    testWidgets('her yaşta hata vermeden çizilir', (WidgetTester tester) async {
      for (final int yas in <int>[0, 1, 3, 6, 12, 18, 30, 55, 65, 70, 95]) {
        await pump(
          tester,
          CharacterFace(player: oyuncu(age: yas), size: 72),
        );
        expect(tester.takeException(), isNull, reason: '$yas yaşında hata');
      }
    });

    testWidgets('hayat tamamlandığında yüz sakinleşir',
        (WidgetTester tester) async {
      await pump(
        tester,
        CharacterFace(player: oyuncu(), size: 80, deceased: true),
      );
      expect(tester.takeException(), isNull);
    });
  });

  // ===================================================================
  // Yazı tipi
  // ===================================================================
  group('Yazı tipi', () {
    testWidgets('arayüz oyunun kendi yazı tipini kullanır',
        (WidgetTester tester) async {
      late ThemeData theme;
      await pump(
        tester,
        Builder(
          builder: (BuildContext context) {
            theme = Theme.of(context);
            return const SizedBox();
          },
        ),
      );
      expect(theme.textTheme.titleMedium?.fontFamily, BirOmurTheme.yaziTipi);
      expect(theme.textTheme.bodyMedium?.fontFamily, BirOmurTheme.yaziTipi);
    });

    testWidgets('el yazısı yalnızca aksanlarda kullanılır',
        (WidgetTester tester) async {
      await pump(tester, const HandwrittenText('Bir Ömür'));
      final Text yazi = tester.widget<Text>(find.text('Bir Ömür'));
      expect(yazi.style?.fontFamily, BirOmurTheme.elYazisi);
    });
  });
}
