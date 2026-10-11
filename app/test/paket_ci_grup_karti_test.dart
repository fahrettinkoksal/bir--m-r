// Paket CI — arkadaş grubu kartı ekranda çiziliyor mu?
//
// **Neden ayrı dosya.** Grup kartı İlişkiler → Arkadaşlar alt
// sayfasının başında duruyor ve o alt sayfaya hiçbir mevcut test
// girmiyordu: ekran dökümü ana sekmeleri geziyor, düzen testi kişi
// kartlarını ve Aktiviteler alt sayfalarını geziyor. Yani kart
// **oyuncunun göreceği ama hiçbir testin çizmediği** bir parçaydı —
// Paket BD'nin yakaladığı "duruşma penceresi çöküyor" hatası tam bu
// boşlukta durmuştu.
//
// Durum kurulmuyor: kareler bot hayatları oynanarak bulunuyor.
library;

import 'dart:math';

import 'package:bir_omur/domain/features/feature_catalog.dart';
import 'package:bir_omur/domain/interaction/friend_circles.dart';
import 'package:bir_omur/domain/models/friend_circle.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:bir_omur/state/game_scope.dart';
import 'package:bir_omur/ui/screens/sections/relationships_screen.dart';
import 'package:bir_omur/ui/theme/bir_omur_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/player_bot.dart';

/// Oyuncunun yaşayan arkadaşı var mı? (Arkadaşlar satırının koşulu)
bool _arkadasiVar(GameState s) => s.people.any((Person p) =>
    p.isAlive && p.relation == RelationType.arkadas);

/// Bot hayatlarında koşula uyan **ilk** kareyi bulur.
GameState? _ara(bool Function(GameState) kosul, {int tohum = 29}) {
  GameState? bulunan;
  for (final PlayerArchetype a in PlayerArchetype.values) {
    for (int seed = 1; seed <= 40; seed++) {
      if (bulunan != null) return bulunan;
      playBotLife(
        archetype: a,
        seed: seed * tohum + a.index,
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
      home: Scaffold(body: RelationshipsScreen(onBack: () {})),
    ),
  ));
  await tester.pumpAndSettle();

  // Arkadaşlar alt sayfası: kart orada duruyor. **Satır yalnızca en az
  // bir arkadaş varken çiziliyor** (`arkadasSayisi > 0`), bu yüzden
  // taranan kareler o koşulu da taşıyor.
  final Finder satir = find.byKey(const Key('relationships_friends_row'));
  expect(satir, findsOneWidget,
      reason: 'Arkadaşlar satırı ekranda yok; kareyi tarayan koşul '
          'arkadaş şartını taşımıyor olabilir');
  await tester.tap(satir);
  await tester.pumpAndSettle();
  return c;
}

void main() {
  testWidgets('grubu olmayan oyuncuya kurma düğmesi ve gerekçe çıkıyor',
      (WidgetTester tester) async {
    final GameState? kare = _ara((GameState s) =>
        s.player.age >= 14 &&
        _arkadasiVar(s) &&
        FriendCircles.activeOf(s) == null);
    expect(kare, isNotNull,
        reason: 'arkadaşı olan ama grubu olmayan kare bulunamadı');

    final GameController c = await _ekranaGetir(tester, kare!);

    expect(find.byKey(const Key('friend_circle_title')), findsOneWidget,
        reason: 'grup kartı çizilmedi');
    expect(find.byKey(const Key('friend_circle_form')), findsOneWidget,
        reason: 'kurma düğmesi yok');

    // Engel varsa gerekçesi ekranda duruyor (D-038: çalışmayan kapı
    // gösterilmez ama **sebebi yazılı** kapı gösterilir).
    final String engel = c.friendCircleBlockReason;
    if (engel.isNotEmpty) {
      expect(find.byKey(const Key('friend_circle_block')), findsOneWidget,
          reason: 'engel var ama gerekçe satırı çizilmedi');
      final Text metin = tester
          .widget<Text>(find.byKey(const Key('friend_circle_block')));
      expect(metin.data, engel);
    }
  });

  testWidgets('grubu olan oyuncuya ad, üyeler ve başlangıç yazılıyor',
      (WidgetTester tester) async {
    final GameState? kare =
        _ara((GameState s) => FriendCircles.activeOf(s) != null, tohum: 13);
    expect(kare, isNotNull,
        reason: 'taranan hayatlarda grubu olan kare bulunamadı');

    await _ekranaGetir(tester, kare!);

    final FriendCircle grup = FriendCircles.activeOf(kare)!;
    final Text baslik =
        tester.widget<Text>(find.byKey(const Key('friend_circle_title')));
    expect(baslik.data, grup.name,
        reason: 'kart grubun adını göstermiyor');

    final Text satir =
        tester.widget<Text>(find.byKey(const Key('friend_circle_line')));
    expect(satir.data, contains('${grup.formedAtAge} yaşından beri'));
    for (final Person uye in FriendCircles.membersOf(kare, grup)) {
      expect(satir.data, contains(uye.firstName),
          reason: '${uye.firstName} kartta görünmüyor');
    }
    // Grubu olana kurma düğmesi çıkmaz.
    expect(find.byKey(const Key('friend_circle_form')), findsNothing);
  });

  testWidgets('modül kapalıyken kart hiç çizilmiyor',
      (WidgetTester tester) async {
    final GameState? kare =
        _ara((GameState s) => s.player.age >= 14 && _arkadasiVar(s));
    expect(kare, isNotNull, reason: 'arkadaşı olan kare bulunamadı');
    final GameState kapali = kare!.copyWith(
      settings: kare.settings.copyWith(
        features:
            kare.settings.features.toggled(FeatureId.arkadasGrubu, false),
      ),
    );

    await _ekranaGetir(tester, kapali);

    expect(find.byKey(const Key('friend_circle_title')), findsNothing,
        reason: 'modül kapalıyken grup kartı çizildi');
    expect(find.byKey(const Key('friend_circle_form')), findsNothing);
  });
}
