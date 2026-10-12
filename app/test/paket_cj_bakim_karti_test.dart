// Paket CJ — yaşlılıkta bakım kartı ekranda çiziliyor mu?
//
// **Neden ayrı dosya.** Kart Hayat ekranının en üstünde, günlüğün
// üzerinde duruyor ve yalnızca 70 yaşından sonra düşük sağlık bandında
// çiziliyor. Ekran dökümü (`ekran_dokumu_test`) 8/17/30/70 yaşlarında
// ekran basıyor ama 70 yaşındaki karesinin bandı iyi olabiliyor; yani
// kart **oyuncunun göreceği ama hiçbir testin çizmediği** bir parça
// olarak kalırdı — Paket BD'nin yakaladığı "duruşma penceresi çöküyor"
// hatası tam bu boşlukta durmuştu.
//
// Durum kurulmuyor: kareler bot hayatları oynanarak **bulunuyor**;
// botun kendi kararı `BotOverrides` ile kapatılıyor, yoksa taranan her
// karede yılın kararı zaten verilmiş oluyor.
library;

import 'dart:math';

import 'package:bir_omur/domain/features/feature_catalog.dart';
import 'package:bir_omur/domain/interaction/elder_support.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:bir_omur/state/game_scope.dart';
import 'package:bir_omur/ui/screens/life_screen.dart';
import 'package:bir_omur/ui/theme/bir_omur_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/player_bot.dart';

/// Bot hayatlarında koşula uyan **ilk** kareyi bulur.
GameState? _ara(bool Function(GameState) kosul, {int tohum = 31}) {
  GameState? bulunan;
  for (final PlayerArchetype a in PlayerArchetype.values) {
    for (int seed = 1; seed <= 20; seed++) {
      if (bulunan != null) return bulunan;
      playBotLife(
        archetype: a,
        seed: seed * tohum + a.index,
        overrides: const BotOverrides(noElderSupport: true),
        onPreAge: (GameState s) {
          if (bulunan != null) return;
          if (kosul(s)) bulunan = s;
        },
      );
    }
  }
  return bulunan;
}

Future<GameController> _ekranaGetir(
  WidgetTester tester,
  GameState durum,
) async {
  tester.view.physicalSize = const Size(1000, 9000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final GameController c = GameController(random: Random(4242))
    ..debugSetState(durum);
  addTearDown(c.dispose);

  await tester.pumpWidget(GameScope(
    controller: c,
    child: MaterialApp(
      theme: BirOmurTheme.light(),
      home: const Scaffold(body: LifeScreen()),
    ),
  ));
  await tester.pumpAndSettle();
  return c;
}

void main() {
  testWidgets('bakıma ihtiyacı olan oyuncuya kart ve üç kapı çıkıyor',
      (WidgetTester tester) async {
    final GameState? kare = _ara((GameState s) =>
        ElderSupport.needsSupport(s) &&
        ElderSupport.helpers(s).isNotEmpty);
    expect(kare, isNotNull, reason: 'yardımcısı olan bakım yılı bulunamadı');

    final GameController c = await _ekranaGetir(tester, kare!);

    expect(find.byKey(const Key('life_elder_support_card')), findsOneWidget,
        reason: 'kart Hayat ekranında çizilmedi');
    expect(find.byKey(const Key('elder_support_title')), findsOneWidget);

    // Durum satırı yılın gerçeğini yazar: yardımcının adı ve masraf.
    final Text satir = tester
        .widget<Text>(find.byKey(const Key('elder_support_line')));
    final Person ilk = ElderSupport.helpers(kare).first;
    expect(satir.data, contains(ilk.firstName),
        reason: 'yanında olabilecek kişinin adı kartta yok');

    // Üç kapı da ekranda; açık olan basılabilir, kapalı olanın gerekçesi
    // yazılı (D-038).
    for (final ElderSupportChoice secim in ElderSupportChoice.values) {
      final Finder dugme = find.byKey(Key('elder_support_${secim.name}'));
      expect(dugme, findsOneWidget, reason: '${secim.name} kapısı yok');
      final String engel = c.elderSupportBlockReason(secim);
      final OutlinedButton w = tester.widget<OutlinedButton>(dugme);
      expect(w.onPressed == null, engel.isNotEmpty,
          reason: '${secim.name}: düğmenin hâli gerekçeyle uyuşmuyor');
      if (engel.isNotEmpty) {
        final Text gerekce = tester.widget<Text>(
            find.byKey(Key('elder_support_block_${secim.name}')));
        expect(gerekce.data, engel);
      }
    }
  });

  testWidgets('karar verilince kapılar kalkıyor, sonuç ekranda kalıyor',
      (WidgetTester tester) async {
    final GameState? kare = _ara((GameState s) =>
        ElderSupport.needsSupport(s) &&
        ElderSupport.helpers(s).isNotEmpty);
    expect(kare, isNotNull);

    await _ekranaGetir(tester, kare!);
    await tester.tap(find.byKey(
      Key('elder_support_${ElderSupportChoice.aileyeYuklen.name}'),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('elder_support_result')), findsOneWidget,
        reason: 'kararın sonucu ekranda yazılmadı');
    for (final ElderSupportChoice secim in ElderSupportChoice.values) {
      expect(find.byKey(Key('elder_support_${secim.name}')), findsNothing,
          reason: 'karar verildikten sonra ${secim.name} kapısı duruyor');
    }
  });

  testWidgets('kimsesi olmayana kart çıkar ama aile kapısı pasif',
      (WidgetTester tester) async {
    final GameState? kare = _ara((GameState s) =>
        ElderSupport.needsSupport(s) && ElderSupport.helpers(s).isEmpty);
    expect(kare, isNotNull, reason: 'kimsesiz bakım yılı bulunamadı');

    await _ekranaGetir(tester, kare!);

    expect(find.byKey(const Key('elder_support_title')), findsOneWidget);
    final OutlinedButton aile = tester.widget<OutlinedButton>(find.byKey(
      Key('elder_support_${ElderSupportChoice.aileyeYuklen.name}'),
    ));
    expect(aile.onPressed, isNull,
        reason: 'kimsesi yokken aile kapısı basılabilir kaldı');
    final Text gerekce = tester.widget<Text>(find.byKey(
      Key('elder_support_block_${ElderSupportChoice.aileyeYuklen.name}'),
    ));
    expect(gerekce.data, 'Yanında olabilecek kimse yok.');
    // Son kapı her zaman açık: oyuncu yılı çevirebilir.
    final OutlinedButton kendi = tester.widget<OutlinedButton>(find.byKey(
      Key('elder_support_${ElderSupportChoice.kendiIdareEt.name}'),
    ));
    expect(kendi.onPressed, isNotNull);
  });

  testWidgets('modül kapalıyken kart hiç çizilmiyor',
      (WidgetTester tester) async {
    final GameState? kare = _ara(ElderSupport.needsSupport);
    expect(kare, isNotNull);
    final GameState kapali = kare!.copyWith(
      settings: kare.settings.copyWith(
        features:
            kare.settings.features.toggled(FeatureId.yaslilikBakimi, false),
      ),
    );

    await _ekranaGetir(tester, kapali);

    expect(find.byKey(const Key('life_elder_support_card')), findsNothing,
        reason: 'modül kapalıyken kart çizildi');
    expect(find.byKey(const Key('elder_support_title')), findsNothing);
  });
}
