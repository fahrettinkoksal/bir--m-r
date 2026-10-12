// Paket DH — Geçmiş Hayatlar arşivinin bekçisi.
//
// **Nasıl bulundu.** `past_lives_screen.dart` testlerde hiç geçmiyordu
// (ne döküm, ne widget testi, ne anahtar). İlk döküm
// (`ekran_dokumu_gecmis_hayatlar_test.dart`) iki gerçek hata gösterdi:
//
//   1. Arşive üç hayatın üçünde de "Meslek: Son iş: **Çalışmıyor**"
//      yazılmıştı — hem de kayıt dosyasına kalıcı olarak. Paket DF aynı
//      kusuru ömür sonu ekranında düzeltmişti ama zincirin **ikinci
//      kopyası** `GameController._archiveWithCurrentLife()` içindeydi.
//      Kök neden yazım hatası değil **kopyaydı**; zincir
//      `CareerSummaryLabel`e taşındı.
//   2. Oyuncu 78 yıllık hayatını bitirip "Geçmiş Hayatlar"a bastığında
//      **"Henüz tamamlanmış bir hayat yok."** okuyordu — hemen
//      altındaki panel "Bu hayatın özeti ... arşivde saklanır" derken.
//      Biten hayat arşive ancak yeni hayata başlanınca yazılıyordu.
// ignore_for_file: avoid_print
library;

import 'dart:io';
import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/domain/life/career_summary_label.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/life_summary.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:bir_omur/ui/screens/past_lives_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/player_bot.dart';

/// Ölen bir bot hayatının son karesini **arar** (kurmaz).
GameState? _olenHayat(PlayerArchetype a, int tohum) {
  GameState? son;
  for (int i = 0; i < 8 && son == null; i++) {
    playBotLife(
      archetype: a,
      seed: tohum + i * 37,
      onYear: (GameState s) {
        if (s.deceased) son = s;
      },
    );
  }
  return son;
}

/// Uygulamanın kendi akışıyla arşive yazdırır.
LifeSummary? _arsivKaydi(GameState olu) {
  final GameController c = GameController(random: Random(11));
  c.debugSetState(olu);
  c.clearLife();
  final List<LifeSummary> arsiv = c.pastLives;
  c.dispose();
  return arsiv.isEmpty ? null : arsiv.last;
}

void main() {
  group('Paket DH — arşiv', () {
    // ---------------------------------------------------------------
    // §1 Arşive "Çalışmıyor" yazılmaz
    // ---------------------------------------------------------------
    test('§1 arşivdeki meslek satırı ölü oyuncunun bugününü sormaz', () {
      const List<(PlayerArchetype, int)> hayatlar = <(PlayerArchetype, int)>[
        (PlayerArchetype.career, 777000),
        (PlayerArchetype.family, 778000),
        (PlayerArchetype.risky, 779000),
        (PlayerArchetype.investor, 780000),
        (PlayerArchetype.casual, 781000),
        (PlayerArchetype.randomValid, 782000),
      ];
      final List<String> satirlar = <String>[];
      final List<String> sorunlar = <String>[];
      int calismisHayat = 0;

      for (final (PlayerArchetype a, int tohum) in hayatlar) {
        final GameState? olu = _olenHayat(a, tohum);
        if (olu == null) continue;
        final LifeSummary? kayit = _arsivKaydi(olu);
        if (kayit == null) {
          sorunlar.add('${a.name}: ölü hayat arşive hiç yazılmadı.');
          continue;
        }
        satirlar.add('${a.name.padRight(13)} ${kayit.careerLabel}');
        // "Çalışmıyor" **bugünkü** işin yokluğunu söyler; ölmüş bir
        // oyuncuda hiçbir zaman doğru cevap değildir.
        if (kayit.careerLabel.contains('Çalışmıyor')) {
          sorunlar.add('${a.name}: arşivde "${kayit.careerLabel}".');
        }
        final bool calisti = olu.career.pastJobIds.isNotEmpty ||
            olu.career.history.isNotEmpty;
        if (calisti) {
          calismisHayat++;
          // Çalışmış bir hayat "Çalışmadı" diye arşivlenemez.
          if (kayit.careerLabel == CareerSummaryLabel.calismadi) {
            sorunlar.add('${a.name}: çalışmış hayat "Çalışmadı" yazıldı.');
          }
        }
      }

      print('ARŞİVE YAZILAN MESLEK SATIRLARI');
      for (final String s in satirlar) {
        print('  $s');
      }
      print('İş geçmişi olan hayat: $calismisHayat / ${satirlar.length}');

      expect(satirlar.length, greaterThanOrEqualTo(4),
          reason: 'Ölen hayat bulunamadı; ölçüm boş kaldı.');
      expect(calismisHayat, greaterThan(0),
          reason: 'Hiçbir hayatta iş geçmişi yok: araç ölü olabilir.');
      expect(sorunlar, isEmpty, reason: sorunlar.join('\n'));
    }, timeout: const Timeout(Duration(minutes: 15)));

    // ---------------------------------------------------------------
    // §2 Zincir tek yerde
    // ---------------------------------------------------------------
    test('§2 meslek satırının zinciri ikinci bir yerde yazılmıyor', () {
      // Kusurun kökü kopyaydı: DF bir kopyayı düzeltti, arşivdeki kopya
      // kaldı. Bu tarama kopyanın geri gelmesini yakalar.
      const List<String> dosyalar = <String>[
        'lib/state/game_controller.dart',
        'lib/ui/screens/life_summary_screen.dart',
        'lib/ui/screens/past_lives_screen.dart',
      ];
      final List<String> sorunlar = <String>[];
      for (final String yol in dosyalar) {
        // **Yorumlar atlanır.** İlk hâli bütün dosyayı tarıyordu ve üç
        // bulgusunun üçü de bu kusuru ANLATAN yorumlardı. Kural koda
        // dairdir; gerekçeyi yazmak yasak değil.
        final String kaynak = File(yol)
            .readAsLinesSync()
            .where((String l) => !l.trimLeft().startsWith('//'))
            .join('\n');
        // "Son iş:" metnini kuran tek yer CareerSummaryLabel olmalı.
        if (kaynak.contains("'Son iş: ")) {
          sorunlar.add('$yol: "Son iş:" metnini kendisi kuruyor; '
              'CareerSummaryLabel kullanılmalı.');
        }
        // `career.label` **yaşayan** oyuncuda doğru alandır; burada
        // yasak olan onu ömür sonu satırında okumak. Tarama bu yüzden
        // alanı tek başına değil, ömür sonu metniyle aynı ifadede
        // arıyor.
        if (RegExp(r"Son iş[^\n]*career\.label|career\.label[^\n]*Son iş")
            .hasMatch(kaynak)) {
          sorunlar.add('$yol: ömür sonu satırında `career.label` okuyor; '
              'o alan BUGÜNKÜ işi söyler, ölü oyuncuda "Çalışmıyor".');
        }
      }
      final String tekKaynak =
          File('lib/domain/life/career_summary_label.dart').readAsStringSync();
      expect(tekKaynak.contains("'Son iş: \$sonIs'"), isTrue,
          reason: 'Tek kaynak "Son iş:" önekini artık kurmuyor; '
              'Paket DF o öneki bilerek koymuştu.');
      expect(tekKaynak.contains('lastJobLabel'), isTrue,
          reason: 'Tek kaynak son işi geçmişten okumuyor.');
      expect(sorunlar, isEmpty, reason: sorunlar.join('\n'));
    });

    // ---------------------------------------------------------------
    // §3 Biten hayat arşivde görünür
    // ---------------------------------------------------------------
    testWidgets('§3 ömür sonu karesinde arşiv biten hayatı da gösterir',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 10000);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final GameState? olu = _olenHayat(PlayerArchetype.career, 777000);
      expect(olu, isNotNull, reason: 'Ölen hayat bulunamadı.');

      final GameController c = GameController(random: Random(7));
      await tester.pumpWidget(
        BirOmurApp(key: const ValueKey<int>(1), controller: c),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rastgele bir hayat'));
      await tester.pumpAndSettle();
      c.debugSetState(olu!);
      await tester.pumpAndSettle();

      // **Paket DD dersi, buraya da düştüm.** Özet uzun bir tembel
      // liste: arşiv düğmesi kaydırılmadan ağaçta bile olmuyor.
      final Finder arsivDugmesi =
          find.byKey(const Key('life_summary_archive'));
      await tester.scrollUntilVisible(arsivDugmesi, 300);
      await tester.pumpAndSettle();

      // Düğme sayısı listeyle aynı olmalı.
      expect(find.text('Geçmiş Hayatlar (1)'), findsOneWidget,
          reason: 'Arşiv düğmesi biten hayatı saymıyor.');

      await tester.tap(arsivDugmesi);
      await tester.pumpAndSettle();

      expect(find.text('Henüz tamamlanmış bir hayat yok.'), findsNothing,
          reason: 'Hayat bitti ama arşiv boş diyor (Paket DH, Kare A).');
      expect(find.text('1 tamamlanmış hayat'), findsOneWidget,
          reason: 'Arşiv biten hayatı listelemiyor.');
      expect(find.text(olu.player.fullName), findsOneWidget,
          reason: 'Biten hayatın adı arşivde yok.');
      c.dispose();
    }, timeout: const Timeout(Duration(minutes: 10)));

    // ---------------------------------------------------------------
    // §4 Çakışan anahtar — ölçüldü, kusur değil
    // ---------------------------------------------------------------
    testWidgets('§4 aynı ad ve yaşlı iki kayıt ekranı düşürmüyor',
        (WidgetTester tester) async {
      // Kart anahtarı `past_life_<ad>_<yaş>`. İki hayatın adı ve ölüm
      // yaşı aynı olursa anahtar çakışır — kuşak devamında soyadı
      // miras kaldığı için akla yakın bir şüpheydi. ÖLÇÜLDÜ: 400
      // rastgele hayatın **250'si ölüyor ve 250 anahtarın hepsi
      // farklı** (0 çakışma). Üstelik çakışsa bile ekran hata vermiyor.
      // Yani bu bir kusur değil; iddia, Flutter bir gün çakışmayı sert
      // hata yaparsa haber vermek için duruyor.
      LifeSummary ozet(String ad, int yas) => LifeSummary(
            fullName: ad,
            birthCity: 'Ankara',
            deathAge: yas,
            deathCause: 'yaşlılığa bağlı nedenler',
            educationLabel: 'Liseyi bitirdi',
            careerLabel: 'Son iş: Aşçı',
            wallet: 1000,
            itemCount: 1,
            licenseCount: 0,
            highlights: const <String>[],
          );
      await tester.pumpWidget(MaterialApp(
        home: PastLivesScreen(
          lives: <LifeSummary>[ozet('Ali Veli', 70), ozet('Ali Veli', 70)],
          onBack: () {},
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull,
          reason: 'Çakışan kart anahtarı ekranı düşürdü.');
      expect(find.text('2 tamamlanmış hayat'), findsOneWidget);
    });
  });
}
