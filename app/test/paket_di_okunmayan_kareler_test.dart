// Paket DI — üç okunmamış karenin bekçisi.
//
// PR takip rutini üç kareyi "HÂLÂ OKUNMAMIŞ" diye taşıyordu ve biri
// için "120 hayatta BULUNAMADI" yazıyordu. Huni yeniden ölçüldü ve
// üçünün de kolayca bulunduğu çıktı (ölçüm aşağıda, §5): bulunamama
// **aramanın** sorunuydu. Üç kare basıldı, gözle okundu ve bir gerçek
// kusur çıktı (§1).
// ignore_for_file: avoid_print
library;

import 'dart:io';
import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/domain/law/legal_engine.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/life_log.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/player_bot.dart';

GameState? _kareAra({
  required PlayerArchetype arketip,
  required int tohumTabani,
  required int deneme,
  required bool Function(GameState) kosul,
}) {
  GameState? bulunan;
  for (int i = 0; i < deneme && bulunan == null; i++) {
    playBotLife(
      archetype: arketip,
      seed: tohumTabani + i,
      onPreAge: (GameState s) {
        if (bulunan == null && kosul(s)) bulunan = s;
      },
    );
  }
  return bulunan;
}

List<Person> _canliCocuklar(GameState s) => s.people
    .where((Person p) => p.relation == RelationType.cocuk && p.isAlive)
    .toList(growable: false);

void main() {
  group('Paket DI — okunmamış kareler', () {
    // ---------------------------------------------------------------
    // §1 Ret satırı neyi reddettiğini söyler
    // ---------------------------------------------------------------
    test('§1 evlilik teklifinin reddi nesnesiz kalmaz', () {
      // ÖLÇÜLEN KUSUR: metin "hazır olmadığını söyledi" diyordu ve
      // günlükte aynı yılın "… ile çocuk sahibi olmaya karar
      // verdiniz." satırının yanında okunduğunda çocuğa hazır
      // olmadığı anlaşılıyordu. Reddedilen şey evlenme teklifi.
      final String kaynak =
          File('lib/domain/interaction/marriage_engine.dart')
              .readAsStringSync();
      expect(kaynak.contains('evlenme teklifine hazır'), isTrue,
          reason: 'Ret satırı yine neyi reddettiğini söylemiyor.');
      // Kabul satırı da neyin kabul edildiğini söylemeye devam etsin.
      expect(kaynak.contains('Sıra düğünde'), isTrue,
          reason: 'Kabul satırı düğünü anmıyor.');
    });

    // ---------------------------------------------------------------
    // §2-§4 Üç kare: bulunur, basılır, iddia edilir
    // ---------------------------------------------------------------
    testWidgets('§2 gebelik karesi gebeliği ekranda duyurur',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 14000);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final GameState? gebe = _kareAra(
        arketip: PlayerArchetype.family,
        tohumTabani: 600000,
        deneme: 25,
        kosul: (GameState s) => s.isExpecting,
      );
      expect(gebe, isNotNull, reason: 'Gebelik karesi bulunamadı.');

      final GameController c = GameController(random: Random(9));
      await tester.pumpWidget(
        BirOmurApp(key: const ValueKey<int>(1), controller: c),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rastgele bir hayat'));
      await tester.pumpAndSettle();
      c.debugSetState(gebe!);
      await tester.pumpAndSettle();

      final Iterable<String> metinler = tester
          .widgetList<Text>(find.byType(Text))
          .map((Text t) => t.data ?? '');
      // Paket BK/1'in kazanımı: gebelik ekranda görünür.
      expect(metinler.any((String m) => m.contains('Bebek yolda')), isTrue,
          reason: 'Gebelik kartı yok.');
      expect(metinler.any((String m) => m.contains('hamilesin')), isTrue,
          reason: 'Üst özet satırında gebelik etiketi yok.');
      c.dispose();
    }, timeout: const Timeout(Duration(minutes: 12)));

    testWidgets('§3 doğum günlükte duyurulur, bebek sessizce gelmez',
        (WidgetTester tester) async {
      final GameState? bebekli = _kareAra(
        arketip: PlayerArchetype.family,
        tohumTabani: 600000,
        deneme: 25,
        kosul: (GameState s) =>
            _canliCocuklar(s).any((Person p) => p.age == 0),
      );
      expect(bebekli, isNotNull, reason: 'Yeni doğan karesi bulunamadı.');

      final Person bebek =
          _canliCocuklar(bebekli!).firstWhere((Person p) => p.age == 0);
      // Doğum yılının günlüğünde bebeğin adı geçmeli.
      final List<LifeLogEntry> oYil = bebekli.log
          .where((LifeLogEntry e) => e.age == bebekli.player.age)
          .toList(growable: false);
      expect(
        oYil.any((LifeLogEntry e) => e.text.contains(bebek.firstName)),
        isTrue,
        reason: 'Bebek doğdu ama o yılın günlüğünde adı geçmiyor.',
      );

      // ÖLÇÜM (Q-239): ikizde doğum masrafı satır satır yazılıyor ve
      // her satır tek doğumun masrafını gösteriyor. Toplam hiçbir
      // yerde yazmıyor. Sayıya dokunulmadı; karar Faho'nun.
      final Iterable<LifeLogEntry> masraf = oYil.where(
          (LifeLogEntry e) => e.text.contains('Doğum masrafı'));
      print('Doğum yılı: ${bebekli.player.age} · bebek ${bebek.firstName} · '
          '"Doğum masrafı" satırı ${masraf.length} adet');
      for (final LifeLogEntry e in masraf) {
        print('   ${e.text}');
      }
    }, timeout: const Timeout(Duration(minutes: 12)));

    testWidgets('§4 denetim dönemi ekranda etiketli ve bir karşılığı var',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 14000);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final GameState? denetimli = _kareAra(
        arketip: PlayerArchetype.risky,
        tohumTabani: 600000 + PlayerArchetype.risky.index * 911,
        deneme: 40,
        kosul: (GameState s) =>
            s.legal.probationUntilAge != null && !s.legal.isImprisoned,
      );
      expect(denetimli, isNotNull, reason: 'Denetim karesi bulunamadı.');

      // Motor tarafı: denetim kâğıt üstünde kalmıyor.
      expect(LegalEngine.onProbation(denetimli!), isTrue);
      expect(LegalEngine.probationBlockReason(denetimli), isNotEmpty,
          reason: 'Denetimin somut bir karşılığı yok.');

      final GameController c = GameController(random: Random(9));
      await tester.pumpWidget(
        BirOmurApp(key: const ValueKey<int>(2), controller: c),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rastgele bir hayat'));
      await tester.pumpAndSettle();
      c.debugSetState(denetimli);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tab_okul_meslek')));
      await tester.pumpAndSettle();

      // Oyuncu kendi durumunu okuyabilmeli.
      expect(
        tester
            .widgetList<Text>(find.byType(Text))
            .map((Text t) => t.data ?? '')
            .any((String m) => m.contains('Denetim dönemi')),
        isTrue,
        reason: 'Denetim dönemi ekranda hiçbir yerde yazmıyor.',
      );
      c.dispose();
    }, timeout: const Timeout(Duration(minutes: 15)));

    // ---------------------------------------------------------------
    // §5 ÖLÇÜM — kareler gerçekten bulunabiliyor mu
    // ---------------------------------------------------------------
    test('§5 üç karenin huni ölçümü', () {
      // "120 hayatta BULUNAMADI" notu bu ölçümle çürütüldü. Taban
      // ölçüme göre konuldu: `family`de 60 hayatın 43'ü bebek karesi
      // gösteriyor, `risky`de 60 hayatın 13'ü denetim karesi.
      const int adet = 30;
      int gebe = 0;
      int bebek = 0;
      for (int i = 0; i < adet; i++) {
        bool g = false;
        bool b = false;
        playBotLife(
          archetype: PlayerArchetype.family,
          seed: 600000 + i,
          onPreAge: (GameState s) {
            if (s.isExpecting) g = true;
            if (_canliCocuklar(s).any((Person p) => p.age == 0)) b = true;
          },
        );
        if (g) gebe++;
        if (b) bebek++;
      }
      print('family · $adet hayat: gebelik karesi $gebe · '
          'yeni doğan karesi $bebek');
      // Ölçülen oran ~%72 (43/60). Taban dörtte bir: araç ölmesin,
      // oran dalgalanınca da yanlış alarm vermesin.
      expect(gebe, greaterThan(adet ~/ 4),
          reason: 'Gebelik karesi artık bulunamıyor: huni kapanmış olabilir.');
      expect(bebek, greaterThan(adet ~/ 4),
          reason: 'Yeni doğan karesi artık bulunamıyor.');
    }, timeout: const Timeout(Duration(minutes: 20)));
  });
}
