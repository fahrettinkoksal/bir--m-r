import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/data/event_pool.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_flow.dart';

/// `docs/PROTOTYPE_UI.md` §4'teki temsilî test yolu:
/// Aile → "… — Kız Arkadaş" → kişi detayı → ayrılık → Aile → "… — Eski Kız
/// Arkadaş". Aynı kişi kaydı korunur.
void main() {
  late GameController controller;

  // Tohum artık sabit **değil**: olay havuzu her büyüdüğünde rastgele akış
  // değişiyor ve sabit tohumla romantik zincir bazen hiç tamamlanmıyordu.
  // Bu test belirli bir hayatı değil **akışı** sınıyor, o yüzden zinciri
  // tamamlayan ilk tohum kullanılır. Tohumlar sırayla denendiği için
  // sonuç yine tekrarlanabilir.
  setUp(() => controller = GameController(random: Random(12)));

  tearDown(() => controller.dispose());

  Person? partnerOf(RelationType relation) {
    for (final Person p in controller.state!.people) {
      if (p.relation == relation) return p;
    }
    return null;
  }

  /// Tek bir tohumda romantik zinciri denemeye çalışır.
  Future<bool> tryRomance(WidgetTester tester) async {
    int guard = 0;
    while (partnerOf(RelationType.sevgili) == null) {
      if (guard++ > 60) return false;
      // Sağlık krizi olay penceresinden önce gelir (D-044); kriz açıkken
      // olay düğmeleri ekranda olmaz. Ortak yardımcı ikisini de yanıtlar.
      await answerPendingEvents(
        tester,
        controller,
        preferChoiceIds: <String>{'selam', 'teklif'},
      );
      if (partnerOf(RelationType.sevgili) != null) return true;
      // Hayat bu tohumda kriz yüzünden erken bitebilir.
      if (controller.state!.deceased) return false;
      // Eğitim kararı verilmeden yaş atlanmaz (D-094, D-111): karar
      // penceresi açıkken "Yaş Al" düğmesi zaten basılamaz.
      await resolveEducationSheets(tester, controller);
      await tester.tap(find.byKey(const Key('age_up_button')));
      await tester.pumpAndSettle();
      await resolveEducationSheets(tester, controller);
    }
    return true;
  }

  /// Sevgili edinilen bir hayat başlatır.
  ///
  /// Zinciri tamamlayan ilk tohum kullanılır; böylece olay havuzu
  /// büyüdüğünde testin tohumunu elle güncellemek gerekmez.
  Future<void> reachRomance(WidgetTester tester) async {
    for (int deneme = 0; deneme < 25; deneme++) {
      if (deneme > 0) {
        controller.dispose();
        controller = GameController(random: Random(12 + deneme));
        await tester.pumpWidget(
          BirOmurApp(key: ValueKey<int>(deneme), controller: controller),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Rastgele bir hayat'));
        await tester.pumpAndSettle();
      }
      if (await tryRomance(tester)) return;
    }
    fail('Hiçbir tohumda sevgili edinilemedi.');
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

    // İlişkiler → Romantik bağlar alt menüsünde sevgili statüsüyle görünür.
    await tester.tap(find.byKey(const Key('tab_iliskiler')));
    await tester.pumpAndSettle();
    expect(find.text('Romantik bağlar'), findsOneWidget);

    await tester.tap(find.text('Romantik bağlar'));
    await tester.pumpAndSettle();
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
    expect(eski.fullName, adSoyad);
    expect(eski.bond, yakinlik);
    expect(partnerOf(RelationType.sevgili), isNull);
    // Hikâye izleri de güncellenmeli; yoksa eski sevgili karşılaşma olayının
    // önkoşulu bu yoldan hiç sağlanmaz.
    expect(controller.state!.storyFlags, contains(StoryFlags.romantikBitti));
    expect(
      controller.state!.storyFlags,
      isNot(contains(StoryFlags.romantikIliskide)),
    );

    // Sevgiliye özel eylem artık sunulmaz.
    expect(find.text('Ayrıl'), findsNothing);
    expect(find.text('Vakit Geçir'), findsNothing);

    // Sayfayı kapat; listede eski sevgili olarak kalır.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
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
