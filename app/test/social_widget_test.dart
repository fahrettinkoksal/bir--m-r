import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/data/social_catalog.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/social_account.dart';
import 'package:bir_omur/domain/models/sponsorship.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sosyal medya ekranındaki sponsorluk akışı (Paket 10).
void main() {
  late GameController controller;

  setUp(() => controller = GameController(random: Random(12)));
  tearDown(() => controller.dispose());

  const SponsorOffer teklif = SponsorOffer(
    id: 'sponsor-test-1',
    categoryId: 'mahalle_kafe',
    platform: SocialPlatform.video,
    fee: 9000,
    offeredAtAge: 25,
  );

  GameState yayinci({SponsorOffer? offer}) {
    final GameState base =
        LifeGenerator.seeded(61).generate(mode: StartMode.tamamenRastgele);
    return base.copyWith(
      pendingEvent: null,
      player: base.player.copyWith(age: 25, wallet: 5000),
      socialAccounts: <SocialAccount>[
        const SocialAccount(
          platform: SocialPlatform.video,
          createdAtAge: 20,
          followers: 4000,
        ),
      ],
      sponsorOffer: offer,
    );
  }

  Future<void> pumpApp(WidgetTester tester, GameState state) async {
    tester.view.physicalSize = const Size(1200, 4200);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(BirOmurApp(controller: controller));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rastgele bir hayat'));
    await tester.pumpAndSettle();
    controller.debugSetState(state);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tab_aktiviteler')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sosyal medya'));
    await tester.pumpAndSettle();
  }

  testWidgets('teklif yoksa sponsorluk kartı görünmez',
      (WidgetTester tester) async {
    await pumpApp(tester, yayinci());
    expect(find.byKey(const Key('sponsor_accept')), findsNothing);
    expect(find.text('Sponsorluk teklifi'), findsNothing);
  });

  testWidgets('teklif kabul edilince yükümlülük görünür, para ödenmez',
      (WidgetTester tester) async {
    await pumpApp(tester, yayinci(offer: teklif));

    expect(find.text('Sponsorluk teklifi'), findsOneWidget);
    // Gerçek marka adı değil, kurgusal iş kolu yazılır.
    expect(find.textContaining('mahalle kafe zinciri'), findsWidgets);

    final int cuzdan = controller.state!.player.wallet;
    await tester.tap(find.byKey(const Key('sponsor_accept')));
    await tester.pumpAndSettle();

    expect(controller.state!.player.wallet, cuzdan,
        reason: 'Ücret paylaşım yapılınca ödenir');
    expect(controller.state!.openDeals, hasLength(1));
    expect(find.textContaining('paylaşım yapınca ödenecek'), findsOneWidget);
    expect(find.byKey(const Key('sponsor_accept')), findsNothing);
  });

  testWidgets('teklif reddedilince hiçbir gelir oluşmaz',
      (WidgetTester tester) async {
    await pumpApp(tester, yayinci(offer: teklif));
    final int cuzdan = controller.state!.player.wallet;

    await tester.tap(find.byKey(const Key('sponsor_decline')));
    await tester.pumpAndSettle();

    expect(controller.state!.player.wallet, cuzdan);
    expect(controller.state!.sponsorDeals, isEmpty);
    expect(controller.state!.sponsorOffer, isNull);
    expect(find.byKey(const Key('sponsor_accept')), findsNothing);
  });

  testWidgets('kazanç özeti yalnızca gerçekten kazanılmışsa görünür',
      (WidgetTester tester) async {
    await pumpApp(tester, yayinci());
    expect(find.textContaining('bugüne kadar'), findsNothing);

    controller.debugSetState(
      controller.state!.copyWith(
        socialAccounts: <SocialAccount>[
          SocialAccount(
            platform: SocialPlatform.video,
            createdAtAge: 20,
            followers: 4000,
            posts: const <SocialPost>[
              SocialPost(
                contentId: 'vlog',
                age: 24,
                followerDelta: 120,
                earned: 7500,
              ),
            ],
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('bugüne kadar'), findsOneWidget);
  });
}
