import 'dart:io';
import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/data/celebrity_catalog.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/social_account.dart';
import 'package:bir_omur/domain/social/celebrity_engine.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/player_bot.dart';

/// **Paket DQ — sosyal medyanın iki karesi ilk kez okundu.**
///
/// `social_pages.dart` kapsam kaydında "başka testle okunuyor" diye
/// duruyordu. Ölçtüm: o test (`social_widget_test.dart`) sayfaya
/// **giriyor** (`pumpWidget` 1, `tester.tap` 5) ama kareyi **basmıyor**
/// (`print` 0). Beş kayıttan yalnızca ikisi kareyi gerçekten yazıyordu.
/// Dosya iki kare barındırıyor ve ikincisinin başlığı **dinamik**
/// (`platform.label`), yani başlık taramasına hiç görünmüyordu.
///
/// Döküm iki kareyi açtı ve platform karesinde şu satır çıktı:
///
/// > İş birliği teklif et: İş birliği teklif etmek için tanınman
/// > gerekiyor: en az 25 Ün.
///
/// Eylemin adı **aynı satırda iki kez** yazılıyor, üstüne iki nokta üst
/// üste iki kez geliyor ve satır üç ünlü kartında birebir tekrarlıyor.
/// Kök neden: gerekçe eylemin adını kendi içinde taşıyor, ekran da
/// başına `'${eylem.label}: '` ekliyor. Gerekçe artık yalnızca kapıyı
/// yazıyor; adı çağıran yer ekliyor ve ayraç açık satırla aynı (`·`).
void main() {
  /// Yorum satırları atılmış kaynak (Paket DH dersi).
  String kodu(String yol) => File(yol)
      .readAsLinesSync()
      .where((String l) {
        final String t = l.trimLeft();
        return !t.startsWith('//') && !t.startsWith('///');
      })
      .join('\n');

  /// **Durum kurulmuyor, aranıyor.**
  GameState? kareBul(bool Function(GameState) kosul, {int tohumSayisi = 40}) {
    GameState? bulunan;
    const List<PlayerArchetype> arketipler = <PlayerArchetype>[
      PlayerArchetype.social,
      PlayerArchetype.casual,
      PlayerArchetype.career,
      PlayerArchetype.sport,
      PlayerArchetype.family,
      PlayerArchetype.investor,
      PlayerArchetype.entrepreneur,
      PlayerArchetype.risky,
    ];
    for (final PlayerArchetype a in arketipler) {
      for (int tohum = 0; tohum < tohumSayisi; tohum++) {
        if (bulunan != null) return bulunan;
        void bak(GameState s) {
          if (bulunan != null || s.deceased) return;
          if (s.hasNotice || s.pendingEvent != null || s.hasPendingCrisis) {
            return;
          }
          if (kosul(s)) bulunan = s;
        }

        playBotLife(
          archetype: a,
          seed: 61000 + tohum,
          onYear: bak,
          onPreAge: bak,
        );
      }
    }
    return bulunan;
  }

  test('§1 gerekçe eylemin adını tekrar etmiyor', () {
    final String motor = kodu('lib/domain/social/celebrity_engine.dart');
    expect(
      motor,
      contains("'Tanınman gerekiyor: en az \$prototypeOnlyCollabMinFame Ün.'"),
      reason: 'İş birliği kapısı artık kapıyı yazıyor, eylemin adını '
          'değil.',
    );
    expect(
      motor.contains('İş birliği teklif etmek için tanınman gerekiyor'),
      isFalse,
      reason: 'Eylemin adını tekrar eden gerekçe geri geldi; satır '
          '"İş birliği teklif et · İş birliği teklif etmek için…" diye '
          'okunur.',
    );

    final String ekran = kodu('lib/ui/screens/sections/social_pages.dart');
    expect(
      ekran,
      contains(r"'${eylem.label} · ${uygunluk.reason}'"),
      reason: 'Kapalı satır, açık satırla aynı ayracı kullanmalı.',
    );
    expect(
      ekran.contains(r"'${eylem.label}: ${uygunluk.reason}'"),
      isFalse,
      reason: 'İki nokta geri geldi; gerekçenin kendi iki noktasıyla '
          'üst üste biniyor.',
    );
  });

  test('§2 ölçüm: 0 takipçide gösterilen ihtimal ünlüden bağımsız', () {
    // **Kuyruğa yazılan ölçüm (Q-243).** Platform karesinde üç ünlünün
    // altında da "karşılık ihtimali ~%19" yazıyordu; takipçi sayıları
    // 2,1 M / 3,2 M / 5,4 M olmasına rağmen **aynı** sayı. Neden:
    // görünürlük terimi `takipçi / eşik` ile çarpılıyor ve hesap yeni
    // açıldığında 0; kalan terimler (karizma, ün, tanışıklık) ünlüden
    // ve eylemden bağımsız. Sayı **doğru**, ama yeni oyuncuya üç ünlüyü
    // eşit erişilebilir gösteriyor.
    final GameState? sifir = kareBul(
      (GameState s) =>
          s.socialAccounts.isNotEmpty &&
          s.socialAccounts.every((SocialAccount h) => h.followers == 0),
    );
    if (sifir == null) {
      // ignore: avoid_print
      print('UYARI: 0 takipçili hesap karesi BULUNAMADI; §2 sınanmadı.');
      return;
    }
    final GameState s = sifir;
    final SocialAccount hesap = s.socialAccounts.first;
    final List<Celebrity> unluler = kCelebrities
        .where((Celebrity c) => c.platform == hesap.platform)
        .toList(growable: false);
    expect(unluler.length, greaterThanOrEqualTo(2),
        reason: 'Bu platformda karşılaştırmaya yetecek ünlü yok.');

    final Set<int> yuzdeler = <int>{
      for (final Celebrity c in unluler)
        for (final CelebrityAction e in CelebrityAction.values)
          CelebrityEngine.displayChancePercent(s, c, e),
    };
    // ignore: avoid_print
    print('SIFIR TAKİPÇİ: ${s.player.age} yaş · karizma '
        '${s.player.stats.charisma} · ün ${s.player.fame ?? 0} · '
        '${unluler.length} ünlü × ${CelebrityAction.values.length} eylem '
        '→ ayrı yüzde ${yuzdeler.length} ($yuzdeler)');
    expect(
      yuzdeler.length,
      1,
      reason: 'Ölçüm değişti: 0 takipçide yüzdeler artık ayrışıyor. '
          'Q-243 bu ölçüme dayanıyordu, kuyruğu güncelle.',
    );
  });

  test('§3 eşiği geçen kitlede ihtimal ünlüye göre ayrışıyor', () {
    // Sayının **süs olmadığını** sabitler: kitle en küçük eşiği (150)
    // geçtiğinde ünlünün kendi yaklaşılabilirliği devreye giriyor ve
    // yüzdeler ayrışıyor.
    //
    // **Ama ölçüm abartmaya izin vermiyor:** bulunan karede 302
    // takipçiyle mesaj ihtimalleri %20 / %19 / %19 çıktı — ayrışma
    // var, oyuncunun göreceği fark **1 puan**. O platformun
    // ünlülerinin eşikleri 4.000 / 6.000 / 12.000 takipçi; 302 takipçi
    // görünürlük terimini neredeyse hiç açmıyor. Bu test mekanizmanın
    // bağlı olduğunu kanıtlar, "oyuncu farkı görüyor" demez; o tartışma
    // Q-243'te.
    final int enKucukEsik = kCelebrities
        .map((Celebrity c) => c.prototypeOnlyNoticeThreshold)
        .reduce(min);
    final GameState? bulunanBuyuk = kareBul(
      (GameState s) => s.socialAccounts.any(
        (SocialAccount h) => h.followers >= enKucukEsik,
      ),
    );
    if (bulunanBuyuk == null) {
      // ignore: avoid_print
      print('UYARI: $enKucukEsik takipçiyi geçen hesap BULUNAMADI; '
          '§3 sınanmadı.');
      return;
    }
    final GameState buyuk = bulunanBuyuk;
    final SocialAccount hesap = buyuk.socialAccounts.firstWhere(
      (SocialAccount h) => h.followers >= enKucukEsik,
    );
    final List<Celebrity> unluler = kCelebrities
        .where((Celebrity c) => c.platform == hesap.platform)
        .toList(growable: false);
    final Map<String, int> olcum = <String, int>{
      for (final Celebrity c in unluler)
        c.fullName: CelebrityEngine.displayChancePercent(
          buyuk,
          c,
          CelebrityAction.mesaj,
        ),
    };
    // ignore: avoid_print
    print('EŞİĞİ GEÇEN KİTLE: ${hesap.followers} takipçi · mesaj '
        'ihtimalleri $olcum');
    expect(
      olcum.values.toSet().length,
      greaterThan(1),
      reason: 'Kitle eşiği geçtiği hâlde bütün ünlüler aynı yüzdeyi '
          'gösteriyor; o zaman sayı gerçekten süs olurdu.',
    );
  });

  testWidgets('§4 platform karesinde satır bir kez ve tekrarsız yazılıyor',
      (WidgetTester tester) async {
    final GameState? durum = kareBul(
      (GameState s) =>
          s.socialAccounts.isNotEmpty && (s.player.fame ?? 0) < 25,
    );
    if (durum == null) {
      // ignore: avoid_print
      print('UYARI: hesabı olan ve ünü 25in altında olan kare '
          'BULUNAMADI; §4 sınanmadı.');
      return;
    }

    tester.view.physicalSize = const Size(1200, 24000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final GameController controller = GameController(random: Random(77));
    addTearDown(controller.dispose);
    await tester.pumpWidget(BirOmurApp(controller: controller));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rastgele bir hayat'));
    await tester.pumpAndSettle();
    controller.debugSetState(durum);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('tab_aktiviteler')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Sosyal medya'), 240,
        maxScrolls: 60);
    await tester.tap(find.text('Sosyal medya'));
    await tester.pumpAndSettle();
    final Finder kart = find.byWidgetPredicate(
      (Widget w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('sosyal_platform_'),
    );
    expect(kart, findsWidgets, reason: 'Hesabı olan platform kartı yok.');
    await tester.ensureVisible(kart.first);
    await tester.pumpAndSettle();
    await tester.tap(kart.first);
    await tester.pumpAndSettle();

    final List<String> ekran = <String>[
      for (final Text w in tester.widgetList<Text>(find.byType(Text)))
        (w.data ?? w.textSpan?.toPlainText() ?? '').trim(),
    ].where((String t) => t.isNotEmpty).toList();

    // Kare gerçekten platform sayfası mı?
    expect(
      ekran.any((String t) => t.contains('bu yıl kalan:')),
      isTrue,
      reason: 'Platform karesi açılmadı:\n${ekran.join("\n")}',
    );

    final List<String> kekemeler = ekran
        .where((String t) => t.contains('İş birliği teklif etmek için'))
        .toList(growable: false);
    expect(
      kekemeler,
      isEmpty,
      reason: 'Eylemin adı satırda iki kez yazılıyor:\n'
          '${kekemeler.join("\n")}',
    );

    final List<String> kapiSatirlari = ekran
        .where((String t) => t.startsWith('İş birliği teklif et ·'))
        .toList(growable: false);
    if (kapiSatirlari.isEmpty) {
      // ignore: avoid_print
      print('UYARI: iş birliği kapısı bu karede çizilmedi; satırın '
          'biçimi sınanmadı (kekeme taraması yine koştu).');
      return;
    }
    for (final String satir in kapiSatirlari) {
      expect(
        satir,
        contains('Tanınman gerekiyor'),
        reason: 'Kapı gerekçesi beklenen biçimde değil: "$satir"',
      );
      expect(satir.split(':').length - 1, lessThanOrEqualTo(1),
          reason: 'Satırda birden fazla iki nokta var: "$satir"');
    }
    // ignore: avoid_print
    print('PLATFORM KARESİ: ${durum.player.age} yaş · '
        '${ekran.length} metin · iş birliği satırı '
        '${kapiSatirlari.length} kez');
  });
}
