// Gebelik, yeni doğan bebek ve denetim dönemi — hiç okunmamış üç kare
// (Paket DI).
//
// **Neden yazıldı.** PR takip rutini bu üçünü "HÂLÂ OKUNMAMIŞ" diye
// taşıyordu ve biri için "120 hayatta BULUNAMADI" yazıyordu. Huni
// yeniden ölçüldü (4 arketip × 60 hayat, `onPreAge`):
//
// | arketip | çocuğu olan | gebelik karesi | 0 yaşında çocuk | denetim |
// |---|---|---|---|---|
// | family | 43 | 43 (123 kare) | **43** | 3 |
// | casual | 19 | 19 (55 kare) | **19** | 2 |
// | risky | 10 | 10 (24 kare) | **10** | **13** |
// | randomValid | 20 | 20 (57 kare) | **20** | 4 |
//
// Yani üç kare de kolayca bulunuyor; bulunamama **aramanın** sorunuydu,
// oyunun değil. Bu dosya hiçbirini kurmaz: bot hayatlarını oynatır,
// kareyi arar ve uygulamaya verip çizilen metni basar.
// ignore_for_file: avoid_print
library;

import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/player_bot.dart';

/// Aranan kareyi **bulur**; kurmaz. Bulamazsa `null`.
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
  testWidgets('GEBELİK · YENİ DOĞAN · DENETİM — üç kare ilk kez basılıyor',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 16000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    int acilis = 0;
    Future<GameController> ac(GameState durum) async {
      final GameController c = GameController(random: Random(9));
      acilis++;
      // Paket DA tuzağı: her açılışta yeni ValueKey.
      await tester.pumpWidget(
        BirOmurApp(key: ValueKey<int>(acilis), controller: c),
      );
      await tester.pumpAndSettle();
      final Finder baslat = find.text('Rastgele bir hayat');
      expect(baslat, findsOneWidget,
          reason: 'Açılış $acilis: başlangıç ekranı gelmedi.');
      await tester.tap(baslat);
      await tester.pumpAndSettle();
      c.debugSetState(durum);
      await tester.pumpAndSettle();
      return c;
    }

    void bas(String baslik, String altBaslik) {
      print('\n${'=' * 70}');
      print(baslik);
      print(altBaslik);
      print('=' * 70);
      for (final Text t in tester.widgetList<Text>(find.byType(Text))) {
        final String m = (t.data ?? '').trim();
        if (m.isNotEmpty) print('   $m');
      }
    }

    Future<void> sekme(String anahtar) async {
      final Finder f = find.byKey(Key(anahtar));
      if (f.evaluate().isEmpty) return;
      await tester.tap(f);
      await tester.pumpAndSettle();
    }

    int basilan = 0;

    // ---------------------------------------------------------------
    // KARE A — gebelik
    // ---------------------------------------------------------------
    final GameState? gebe = _kareAra(
      arketip: PlayerArchetype.family,
      tohumTabani: 600000,
      deneme: 25,
      kosul: (GameState s) => s.isExpecting,
    );
    if (gebe != null) {
      final GameController c = await ac(gebe);
      bas('KARE A · GEBELİK',
          '${gebe.player.fullName} · ${gebe.player.age} yaş · '
          'cinsiyet ${gebe.player.gender.name}');
      await sekme('tab_iliskiler');
      bas('KARE A/2 · GEBELİKTE İLİŞKİLER SEKMESİ', '');
      basilan++;
      c.dispose();
    } else {
      print('KARE A bulunamadı.');
    }

    // ---------------------------------------------------------------
    // KARE B — yeni doğan bebek (0 yaşında canlı çocuk)
    // ---------------------------------------------------------------
    final GameState? bebekli = _kareAra(
      arketip: PlayerArchetype.family,
      tohumTabani: 600000,
      deneme: 25,
      kosul: (GameState s) =>
          _canliCocuklar(s).any((Person p) => p.age == 0),
    );
    if (bebekli != null) {
      final GameController c = await ac(bebekli);
      final Person bebek =
          _canliCocuklar(bebekli).firstWhere((Person p) => p.age == 0);
      bas('KARE B · YENİ DOĞAN BEBEK',
          '${bebekli.player.fullName} · ${bebekli.player.age} yaş · '
          'bebek: ${bebek.fullName} (${bebek.gender.name})');
      await sekme('tab_iliskiler');
      bas('KARE B/2 · BEBEKLE İLİŞKİLER SEKMESİ', '');
      basilan++;
      c.dispose();
    } else {
      print('KARE B bulunamadı.');
    }

    // ---------------------------------------------------------------
    // KARE C — denetim dönemi (tahliye sonrası)
    // ---------------------------------------------------------------
    final GameState? denetimli = _kareAra(
      arketip: PlayerArchetype.risky,
      tohumTabani: 600000 + PlayerArchetype.risky.index * 911,
      deneme: 40,
      kosul: (GameState s) =>
          s.legal.probationUntilAge != null && !s.legal.isImprisoned,
    );
    if (denetimli != null) {
      final GameController c = await ac(denetimli);
      bas('KARE C · DENETİM DÖNEMİ',
          '${denetimli.player.fullName} · ${denetimli.player.age} yaş · '
          'denetim bitişi ${denetimli.legal.probationUntilAge}');
      await sekme('tab_okul_meslek');
      bas('KARE C/2 · DENETİMDE OKUL/MESLEK SEKMESİ', '');
      basilan++;
      c.dispose();
    } else {
      print('KARE C bulunamadı.');
    }

    expect(basilan, greaterThanOrEqualTo(2),
        reason: 'Üç karenin en az ikisi basılamadı ($basilan).');
  }, timeout: const Timeout(Duration(minutes: 25)));
}
