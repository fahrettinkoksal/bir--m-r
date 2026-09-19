import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/data/event_pool.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:bir_omur/ui/turkish_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// `docs/PROTOTYPE_UI.md` §4'teki temsilî test yolu:
/// Aile → "… — Kız Arkadaş" → kişi detayı → ayrılık → Aile → "… — Eski Kız
/// Arkadaş". Aynı kişi kaydı korunur.
void main() {
  late GameController controller;

  setUp(() {
    controller = GameController(random: Random(7));
  });

  tearDown(() => controller.dispose());

  Person? partnerOf(RelationType relation) {
    for (final Person p in controller.state!.people) {
      if (p.relation == relation) return p;
    }
    return null;
  }

  /// Romantik zinciri seçerek sevgili edinilene kadar ilerler.
  Future<void> reachRomance(WidgetTester tester) async {
    int guard = 0;
    while (partnerOf(RelationType.sevgili) == null) {
      if (guard++ > 60) fail('Sevgili edinilemedi.');
      while (controller.state!.hasPendingEvent) {
        final ActiveEvent event = controller.state!.pendingEvent!;
        final EventChoice choice = event.choices.firstWhere(
          (EventChoice c) => <String>['selam', 'teklif'].contains(c.id),
          orElse: () => event.choices.first,
        );
        await tester.tap(find.text(choice.label));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Devam'));
        await tester.pumpAndSettle();
        if (partnerOf(RelationType.sevgili) != null) return;
      }
      await tester.tap(find.text('Yaş Al'));
      await tester.pumpAndSettle();
    }
  }

  testWidgets(
      'sevgili → Aile listesi → ayrılık → aynı kişi eski sevgili olarak kalır',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 3600);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(BirOmurApp(controller: controller));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rastgele bir hayat'));
    await tester.pumpAndSettle();

    await reachRomance(tester);

    final Person sevgili = partnerOf(RelationType.sevgili)!;
    final String kimlik = sevgili.id;
    final String adSoyad = sevgili.fullName;
    final int yakinlik = sevgili.bond;

    // Aile listesinde sevgili statüsüyle görünür. İlişkiler bölümü listenin
    // sonunda olduğu için oraya kaydırılır.
    Future<void> scrollTo(Finder finder) async {
      await tester.scrollUntilVisible(
        finder,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
    }

    await tester.tap(find.byIcon(Icons.groups_outlined));
    await tester.pumpAndSettle();
    await scrollTo(find.text(trUpper('İlişkiler')));
    expect(find.text(trUpper('İlişkiler')), findsOneWidget);
    expect(find.text(adSoyad), findsOneWidget);
    final String sevgiliEtiketi =
        sevgili.gender == Gender.kadin ? 'Kız arkadaş' : 'Erkek arkadaş';
    expect(find.textContaining(sevgiliEtiketi), findsWidgets);

    // Kişi detayında ayrılma seçeneği var.
    await tester.tap(find.text(adSoyad));
    await tester.pumpAndSettle();
    expect(find.text('Ayrıl'), findsOneWidget);

    await tester.tap(find.text('Ayrıl'));
    await tester.pumpAndSettle();
    expect(find.text('Ayrılmak istiyor musun?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Ayrıl'));
    await tester.pumpAndSettle();

    // Aynı kayıt, yeni statü.
    final Person eski = controller.state!.personById(kimlik)!;
    expect(eski.relation, RelationType.eskiSevgili);
    // Hikâye izleri de güncellenmeli; yoksa eski sevgili karşılaşma olayının
    // önkoşulu bu yoldan hiç sağlanmaz.
    expect(controller.state!.storyFlags, contains(StoryFlags.romantikBitti));
    expect(
      controller.state!.storyFlags,
      isNot(contains(StoryFlags.romantikIliskide)),
    );
    expect(eski.fullName, adSoyad);
    expect(eski.bond, yakinlik);
    expect(partnerOf(RelationType.sevgili), isNull);

    // Sevgiliye özel eylem artık sunulmaz.
    expect(find.text('Ayrıl'), findsNothing);
    expect(find.text('Vakit Geçir'), findsNothing);

    // Sayfayı kapat ve listede eski sevgili olarak gör.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await scrollTo(find.text(adSoyad));
    expect(find.text(adSoyad), findsOneWidget);
    final String eskiEtiket = eski.gender == Gender.kadin
        ? 'Eski kız arkadaş'
        : 'Eski erkek arkadaş';
    expect(find.textContaining(eskiEtiket), findsWidgets);

    // Diğer aile üyeleri etkilenmedi.
    expect(
      controller.state!.people
          .where((Person p) => p.relation == RelationType.eskiSevgili)
          .length,
      1,
    );
  });
}
