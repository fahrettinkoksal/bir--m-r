// Geçmiş Hayatlar arşivi — hiç okunmamış ekran (Paket DH).
//
// **Neden yazıldı.** `lib/ui/screens/past_lives_screen.dart` testlerde
// **hiç geçmiyor**: ne bir döküm, ne bir widget testi, ne bir anahtar
// arandı. Oysa oyuncunun ilk hayatından sonra en çok göreceği ekran bu
// — oyunun kupa rafı. Paket CT, CU ve DF'in dersi: okunmayan ekranda
// gerçek hata birikir ve DF'in bulduğu kusurun ikinci kopyası tam bu
// yolda duruyor (arşive yazılan `careerLabel`).
//
// Bu dosya arşivi **kurmaz**: bot hayatlarını ölüme kadar oynatır,
// uygulamanın kendi `clearLife()` akışıyla arşive yazdırır ve çizilen
// metni basar. Üç kare basılıyor:
//   A) ilk ölümden hemen sonra açılan arşiv (oyuncunun kendi hayatı
//      listede mi?),
//   B) üç gerçek hayat arşivlendikten sonraki arşiv,
//   C) B'nin "Meslek:" satırlarının kaynağı (kayıtta ne yazılı).
// ignore_for_file: avoid_print
library;

import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/life_summary.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/player_bot.dart';

/// Ölen bir bot hayatının son karesini arar (kurmaz).
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

List<String> _ekrandakiMetinler(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((Text t) => t.data ?? '')
    .where((String s) => s.trim().isNotEmpty)
    .toList();

void main() {
  testWidgets('GEÇMİŞ HAYATLAR — arşiv ekranı ilk kez basılıyor',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 16000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Paket DA'nın tuzağı: her açılışta yeni ValueKey, yoksa ikinci
    // açılışta "Rastgele bir hayat" düğmesi bulunmaz.
    int acilis = 0;
    Future<GameController> uygulamaAc() async {
      final GameController c = GameController(random: Random(7));
      acilis++;
      await tester.pumpWidget(
        BirOmurApp(key: ValueKey<int>(acilis), controller: c),
      );
      await tester.pumpAndSettle();
      final Finder baslat = find.text('Rastgele bir hayat');
      expect(baslat, findsOneWidget,
          reason: 'Açılış $acilis: başlangıç ekranı gelmedi.');
      await tester.tap(baslat);
      await tester.pumpAndSettle();
      return c;
    }

    // ---------------------------------------------------------------
    // KARE A — ilk ölümden hemen sonra arşiv
    // ---------------------------------------------------------------
    final GameState? ilk = _olenHayat(PlayerArchetype.career, 777000);
    expect(ilk, isNotNull, reason: 'Ölen hayat bulunamadı.');

    GameController c = await uygulamaAc();
    c.debugSetState(ilk!);
    await tester.pumpAndSettle();

    final Finder arsivDugmesi = find.byKey(const Key('life_summary_archive'));
    expect(arsivDugmesi, findsOneWidget,
        reason: 'Ömür sonu özetinde arşiv düğmesi yok.');
    final String dugmeYazisi =
        tester.widget<OutlinedButton>(arsivDugmesi).child is Text
            ? (tester.widget<OutlinedButton>(arsivDugmesi).child! as Text)
                .data!
            : '(okunamadı)';
    await tester.tap(arsivDugmesi);
    await tester.pumpAndSettle();

    print('\n${'=' * 70}');
    print('KARE A · İLK ÖLÜMDEN HEMEN SONRA AÇILAN ARŞİV');
    print('Hayat: ${ilk.player.fullName} · ${ilk.deathAge ?? ilk.player.age}'
        ' yaşında · arşiv düğmesi: "$dugmeYazisi"');
    print('=' * 70);
    for (final String m in _ekrandakiMetinler(tester)) {
      print('   $m');
    }
    c.dispose();

    // ---------------------------------------------------------------
    // KARE B — üç gerçek hayat arşivlendikten sonra
    // ---------------------------------------------------------------
    // Arşiv uygulamanın KENDİ akışıyla yazılır: her hayat için
    // debugSetState + clearLife(). Özet elle kurulmuyor.
    final List<LifeSummary> arsiv = <LifeSummary>[];
    final List<(PlayerArchetype, int)> hayatlar = <(PlayerArchetype, int)>[
      (PlayerArchetype.career, 777000),
      (PlayerArchetype.family, 778000),
      (PlayerArchetype.risky, 779000),
    ];
    for (final (PlayerArchetype a, int tohum) in hayatlar) {
      final GameState? olu = _olenHayat(a, tohum);
      if (olu == null) continue;
      final GameController gecici = GameController(random: Random(11));
      gecici.debugSetState(olu.copyWith(pastLives: arsiv));
      gecici.clearLife();
      arsiv
        ..clear()
        ..addAll(gecici.pastLives);
      gecici.dispose();
    }
    expect(arsiv.length, greaterThanOrEqualTo(2),
        reason: 'Arşiv dolmadı: ${arsiv.length} kayıt.');

    final GameState? sonuncu = _olenHayat(PlayerArchetype.investor, 780000);
    expect(sonuncu, isNotNull);
    c = await uygulamaAc();
    c.debugSetState(sonuncu!.copyWith(pastLives: arsiv));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('life_summary_archive')));
    await tester.pumpAndSettle();

    print('\n${'=' * 70}');
    print('KARE B · ${arsiv.length} HAYAT ARŞİVLENDİKTEN SONRA');
    print('=' * 70);
    for (final String m in _ekrandakiMetinler(tester)) {
      print('   $m');
    }

    // ---------------------------------------------------------------
    // KARE C — kayıtta ne yazılı (ekranın kaynağı)
    // ---------------------------------------------------------------
    print('\n${'=' * 70}');
    print('KARE C · ARŞİV KAYDININ KENDİSİ');
    print('=' * 70);
    for (final LifeSummary l in arsiv) {
      print('   ${l.fullName} · ${l.deathAge} yaş · kuşak ${l.generation}');
      print('      eğitim : ${l.educationLabel}');
      print('      meslek : ${l.careerLabel}');
      print('      anahtar: past_life_${l.fullName}_${l.deathAge}');
    }
    c.dispose();
  }, timeout: const Timeout(Duration(minutes: 15)));
}
