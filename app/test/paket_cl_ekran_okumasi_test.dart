// Paket CL — dökümün okuduğu iki kusur.
//
// **Nereden çıktı.** Ekran dökümüne (üçüncü tur dosyası) bu oturumun
// iki yeni kartı eklendi: `YAŞLILIKTA BAKIM` (Paket CJ) ve
// `ARKADAŞ GRUBU` (Paket CI). İkisi de kendi testlerinde anahtar ve
// metin düzeyinde denetleniyordu ama **bütün ekran** olarak hiç
// basılmamıştı. Çıktı gözle okununca iki şey yanlış görünüyordu:
//
// 1. Bakım kartı, kapının gerekçesini **durum satırında da** yazıyordu:
//    kimsesiz bir hayatta "Yanında olabilecek kimse yok." cümlesi üst
//    üste iki kez çıkıyordu.
// 2. Grubu süren bir hayatta (57 yaş, dökümde bulundu) İlişkiler
//    ekranının üst düzeyinde grubun **tek izi yoktu**: grup kartı
//    yalnızca Arkadaşlar alt sayfasında duruyor. Aynı ekranda hayvan
//    satırı "Leblebi seninle yaşıyor" diye özet veriyor; yani kalıp
//    zaten vardı ve arkadaş satırı ondan geri kalıyordu.
//
// Durum kurulmuyor: kareler bot hayatlarında bulunuyor.
library;

import 'dart:math';

import 'package:bir_omur/domain/features/feature_catalog.dart';
import 'package:bir_omur/domain/interaction/elder_support.dart';
import 'package:bir_omur/domain/interaction/friend_circles.dart';
import 'package:bir_omur/domain/models/friend_circle.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:bir_omur/state/game_scope.dart';
import 'package:bir_omur/ui/screens/sections/relationships_screen.dart';
import 'package:bir_omur/ui/theme/bir_omur_theme.dart';
import 'package:bir_omur/ui/widgets/elder_support_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/player_bot.dart';

/// Bot hayatlarında koşula uyan **ilk** kareyi bulur.
GameState? _ara(
  bool Function(GameState) kosul, {
  BotOverrides overrides = BotOverrides.none,
  int tohum = 101,
}) {
  GameState? bulunan;
  for (final PlayerArchetype a in <PlayerArchetype>[
    PlayerArchetype.risky,
    PlayerArchetype.family,
    PlayerArchetype.casual,
  ]) {
    for (int seed = 1; seed <= 40; seed++) {
      if (bulunan != null) return bulunan;
      playBotLife(
        archetype: a,
        seed: seed * tohum + a.index,
        overrides: overrides,
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
  Widget govde,
) async {
  tester.view.physicalSize = const Size(1000, 9000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final GameController c = GameController(random: Random(5151))
    ..debugSetState(durum);
  addTearDown(c.dispose);
  await tester.pumpWidget(GameScope(
    controller: c,
    child: MaterialApp(
      theme: BirOmurTheme.light(),
      home: Scaffold(body: govde),
    ),
  ));
  await tester.pumpAndSettle();
  return c;
}

void main() {
  testWidgets('bakım kartı kapının gerekçesini iki kez yazmıyor',
      (WidgetTester tester) async {
    final GameState? kare = _ara(
      (GameState s) =>
          ElderSupport.needsSupport(s) &&
          !ElderSupport.decidedThisYear(s) &&
          ElderSupport.helpers(s).isEmpty,
      overrides: const BotOverrides(noElderSupport: true),
    );
    expect(kare, isNotNull, reason: 'kimsesiz bakım karesi bulunamadı');

    final GameController c =
        await _ekranaGetir(tester, kare!, const ElderSupportCard());
    final Text satir =
        tester.widget<Text>(find.byKey(const Key('elder_support_line')));
    final String engel =
        c.elderSupportBlockReason(ElderSupportChoice.aileyeYuklen);

    expect(engel, isNotEmpty,
        reason: 'kimsesiz karede aile kapısı açık görünüyor');
    // **Karşılaştırma büyük/küçük harfe ve son noktaya takılmamalı.**
    // İlk yazımda `contains(engel)` kullanmıştım ve bekçi kendi
    // iddiasını kaçırdı: eski cümle "… ve yanında olabilecek kimse
    // yok." diyordu, gerekçe ise "Yanında olabilecek kimse yok." —
    // tek fark baştaki harf. Bekçinin ısırdığı ancak bu normalleştirme
    // ile doğrulandı.
    String sade(String t) =>
        t.toLowerCase().replaceAll('.', '').replaceAll('  ', ' ').trim();
    expect(sade(satir.data!), isNot(contains(sade(engel))),
        reason: 'durum satırı kapının gerekçesini tekrarlıyor: '
            '"${satir.data}"');
    // Gerekçe yine ekranda; yalnızca tek yerde.
    final Text gerekce = tester.widget<Text>(find.byKey(
      Key('elder_support_block_${ElderSupportChoice.aileyeYuklen.name}'),
    ));
    expect(gerekce.data, engel);
  });

  testWidgets('grubu süren oyuncu İlişkiler ekranının üstünde grubu görüyor',
      (WidgetTester tester) async {
    final GameState? kare = _ara(
      (GameState s) =>
          FriendCircles.activeOf(s) != null &&
          FriendCircles.membersOf(s, FriendCircles.activeOf(s)!).isNotEmpty,
      tohum: 101,
    );
    expect(kare, isNotNull, reason: 'grubu süren kare bulunamadı');
    final FriendCircle grup = FriendCircles.activeOf(kare!)!;

    await _ekranaGetir(tester, kare, RelationshipsScreen(onBack: () {}));

    final Finder satir = find.byKey(const Key('relationships_friends_row'));
    expect(satir, findsOneWidget,
        reason: 'arkadaşı olan karede Arkadaşlar satırı yok');
    // Satırın alt metni grubu söylüyor: ad, kişi sayısı ve başlangıç.
    expect(
      find.descendant(of: satir, matching: find.text(
        '${grup.name} · '
        '${FriendCircles.membersOf(kare, grup).length} kişi · '
        '${grup.formedAtAge} yaşından beri',
      )),
      findsOneWidget,
      reason: 'grup üst düzeyde görünmüyor; oyuncu alt sayfaya girmeden '
          'grubunun olduğunu bilemiyor',
    );
  });

  testWidgets('modül kapalıyken arkadaş satırı eski alt metnine dönüyor',
      (WidgetTester tester) async {
    final GameState? kare = _ara(
      (GameState s) => FriendCircles.activeOf(s) != null,
      tohum: 101,
    );
    expect(kare, isNotNull);
    final GameState kapali = kare!.copyWith(
      settings: kare.settings.copyWith(
        features:
            kare.settings.features.toggled(FeatureId.arkadasGrubu, false),
      ),
    );

    await _ekranaGetir(tester, kapali, RelationshipsScreen(onBack: () {}));

    final Finder satir = find.byKey(const Key('relationships_friends_row'));
    expect(satir, findsOneWidget);
    expect(
      find.descendant(
          of: satir, matching: find.text('Okul ve hayat arkadaşların')),
      findsOneWidget,
      reason: 'modül kapalıyken satır grup metnini taşımaya devam ediyor',
    );
    final FriendCircle grup = FriendCircles.activeOf(kare)!;
    expect(find.descendant(of: satir, matching: find.textContaining(grup.name)),
        findsNothing);
  });

  testWidgets('bakım kartı yardımcısı olanın adını yazıyor',
      (WidgetTester tester) async {
    final GameState? kare = _ara(
      (GameState s) =>
          ElderSupport.needsSupport(s) &&
          !ElderSupport.decidedThisYear(s) &&
          ElderSupport.helpers(s).isNotEmpty,
      overrides: const BotOverrides(noElderSupport: true),
    );
    expect(kare, isNotNull, reason: 'yardımcısı olan bakım karesi yok');

    await _ekranaGetir(tester, kare!, const ElderSupportCard());
    final Text satir =
        tester.widget<Text>(find.byKey(const Key('elder_support_line')));
    final Person ilk = ElderSupport.helpers(kare).first;
    expect(satir.data, contains(ilk.firstName));
    expect(satir.data, contains('Yanında'));
  });
}
