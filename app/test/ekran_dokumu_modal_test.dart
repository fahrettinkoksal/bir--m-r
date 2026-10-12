// Ekran dökümü, dokuzuncu tur: **modal sayfalar ve paneller**.
//
// **Neden var.** Paket DM-DQ `lib/ui/screens/sections/` altındaki 30
// sayfanın hepsini okudu (28 bölüm karesi + 4 sekme kökü) ve dokuz
// gerçek kusur çıktı. Bir katman aşağıda `lib/ui/widgets/` duruyor ve
// oyuncuya dönük metnin önemli bir kısmı orada: ölçtüm, dosya başına
// cümle sayısı (kaynaktaki 18+ karakterlik, boşluk içeren dizgiler,
// yorumlar atılmış):
//
//   person_detail_sheet 65 · item_detail_sheet 20 · settings_sheet 14 ·
//   character_header 13 · elder_support_card 11 · notice_sheet 11 ·
//   pet_detail_sheet 10 · prison_life_panel 7 · license_exam_sheet 6 ·
//   track_choice_sheet 5
//
// `person_detail_sheet.dart` tek başına 65 cümle taşıyor — okuduğum
// hiçbir bölüm sayfasından yoğun. Karesi **hiç basılmamıştı**: modal
// bir sayfa sekmede görünmüyor, bölüm dökümü oraya giremiyor.
//
// **Durum kurulmuyor, aranıyor** (Paket DM'nin dersi): her modalın bir
// kapısı var (ebeveyn kaydı, sahip olunan eşya, evcil hayvan) ve bu
// kapılar bot hayatlarından bulunuyor. Kare bulunamazsa test
// "BULUNAMADI" yazar ve geçer: bulunamamak ürün hatası değil, ama
// "okundu" da sayılmaz.
library;

import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/player_bot.dart';
import 'support/section_pages.dart';

/// Taranan kareler; bir kez doldurulur.
final Map<String, GameState> _kareler = <String, GameState>{};
bool _tarandi = false;

void _tara() {
  if (_tarandi) return;
  _tarandi = true;
  const List<PlayerArchetype> arketipler = <PlayerArchetype>[
    PlayerArchetype.casual,
    PlayerArchetype.family,
    PlayerArchetype.social,
    PlayerArchetype.investor,
    PlayerArchetype.sport,
    PlayerArchetype.entrepreneur,
    PlayerArchetype.risky,
  ];
  for (final PlayerArchetype a in arketipler) {
    for (int tohum = 0; tohum < 40; tohum++) {
      if (_kareler.length == kModalKareleri.length) return;
      void bak(GameState s) {
        if (s.deceased) return;
        // Bekleyen bir şey varken `debugSetState` edilen durumda modal
        // pencere açılıyor ve sekmeler kilitleniyor (Paket CG tuzağı).
        if (s.hasNotice || s.pendingEvent != null || s.hasPendingCrisis) {
          return;
        }
        for (final Bolum b in kModalKareleri) {
          if (_kareler.containsKey(b.ad)) continue;
          if (b.kosul(s)) _kareler[b.ad] = s;
        }
      }

      playBotLife(
        archetype: a,
        seed: 61000 + tohum,
        onYear: bak,
        onPreAge: bak,
      );
    }
  }
}

void main() {
  late GameController controller;
  bool acildi = false;

  setUp(() {
    controller = GameController(random: Random(77));
    acildi = false;
  });
  tearDown(() => controller.dispose());

  List<String> metinler(WidgetTester tester) {
    final List<String> out = <String>[];
    for (final Text w in tester.widgetList<Text>(find.byType(Text))) {
      final String? d = w.data ?? w.textSpan?.toPlainText();
      if (d == null) continue;
      final String t = d.trim().replaceAll(RegExp(r'\s+'), ' ');
      if (t.isNotEmpty) out.add(t);
    }
    return out;
  }

  /// Hedefi görünür kılar; **her** kaydırılabilir alanı dener.
  ///
  /// Modal açıldıktan sonra ağaçta iki kaydırılabilir alan oluyor
  /// (sayfanın gövdesi ve sayfanın kendisi); `scrollToFinder` yalnızca
  /// ilkini kaydırıyor (Paket DN dersi).
  Future<bool> kaydir(WidgetTester tester, Finder hedef) async {
    if (hedef.evaluate().isNotEmpty) {
      await tester.ensureVisible(hedef.first);
      await tester.pumpAndSettle();
      return true;
    }
    final int alanSayisi = find.byType(Scrollable).evaluate().length;
    for (int i = 0; i < alanSayisi; i++) {
      try {
        await tester.scrollUntilVisible(
          hedef,
          240,
          scrollable: find.byType(Scrollable).at(i),
          maxScrolls: 60,
        );
        await tester.pumpAndSettle();
        if (hedef.evaluate().isNotEmpty) return true;
      } on StateError {
        continue;
      }
    }
    return hedef.evaluate().isNotEmpty;
  }

  Future<void> ac(WidgetTester tester, GameState durum) async {
    if (!acildi) {
      tester.view.physicalSize = const Size(1200, 24000);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(BirOmurApp(controller: controller));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rastgele bir hayat'));
      await tester.pumpAndSettle();
      acildi = true;
    }
    controller.debugSetState(durum);
    await tester.pumpAndSettle();
  }

  for (final Bolum b in kModalKareleri) {
    testWidgets('modal dökümü: ${b.ad}', (WidgetTester tester) async {
      _tara();
      final GameState? durum = _kareler[b.ad];
      if (durum == null) {
        // ignore: avoid_print
        print('\n===== ${b.ad} =====\nBULUNAMADI (kapı için '
            '`kModalKareleri` kaydına bak).');
        return;
      }

      await ac(tester, durum);
      final Finder sekme = find.byKey(Key(b.sekme));
      expect(sekme, findsOneWidget, reason: '${b.sekme} sekmesi yok.');
      await tester.tap(sekme);
      await tester.pumpAndSettle();

      // **Araç yalan söylemez (Paket CV/DM dersi).** Yol üstündeki bir
      // hedef bulunamazsa döküm sıradan bir ekranı basıp "okundu"
      // demez; nerede takıldığını yazar ve düşer.
      for (int i = 0; i < b.yol.length; i++) {
        final Finder hedef = b.yol[i];
        final bool goruldu = await kaydir(tester, hedef);
        expect(
          goruldu,
          isTrue,
          reason: '${b.ad}: yolun ${i + 1}. adımı ekranda bulunamadı. '
              'Kapı açık (${durum.player.age} yaşındaki kare) ama satır '
              'yok — bu bir kapı/satır tutarsızlığıdır.',
        );
        final List<String> onceki = metinler(tester);
        await tester.tap(hedef.first);
        await tester.pumpAndSettle();
        final List<String> sonraki = metinler(tester);
        expect(
          sonraki.join('|') == onceki.join('|'),
          isFalse,
          reason: '${b.ad}: yolun ${i + 1}. adımına dokunuldu ama ekran '
              'hiç değişmedi. Satır kapalı olabilir.',
        );
      }

      final List<String> ekran = metinler(tester);
      // ignore: avoid_print
      print('\n===== ${b.ad} · ${durum.player.age} yaş · '
          '${ekran.length} metin =====');
      // ignore: avoid_print
      print(ekran.join('\n'));

      expect(
        ekran.any((String t) => t.contains(b.isaret)),
        isTrue,
        reason: '${b.ad}: beklenen işaret ("${b.isaret}") ekranda yok. '
            'Basılan kare başka bir sayfa olabilir — yukarıdaki dökümü '
            'oku.',
      );
      expect(
        ekran.length,
        greaterThan(5),
        reason: '${b.ad} karesi neredeyse boş çizildi.',
      );

      // **Ayraçsız sayı taraması (Paket DN).**
      final RegExp uzunSayi = RegExp(r'\d{5,}');
      final List<String> ayracsiz = ekran
          .where((String t) => uzunSayi.hasMatch(t))
          .toList(growable: false);
      expect(
        ayracsiz,
        isEmpty,
        reason: '${b.ad}: ekranda ayraçsız uzun sayı var; `trNumber` '
            'kullan:\n${ayracsiz.join("\n")}',
      );

      // **Tekrar bekçisi (Paket DP).** Ölçü cümle: boşluk içeren ve
      // nokta/ünlem/soru ile biten metin. Düğme ve durum etiketleri
      // meşru biçimde tekrarlıyor, onlar sayılmıyor. Tavan bölüm
      // dökümünde 28 kare üzerinden ölçülmüştü (meşru en yüksek 4).
      const int tekrarTavani = 4;
      final Map<String, int> cumleSayimi = <String, int>{};
      for (final String t in ekran) {
        if (!t.contains(' ')) continue;
        if (!t.endsWith('.') && !t.endsWith('!') && !t.endsWith('?')) {
          continue;
        }
        cumleSayimi[t] = (cumleSayimi[t] ?? 0) + 1;
      }
      final List<String> cokTekrar = <String>[
        for (final MapEntry<String, int> e in cumleSayimi.entries)
          if (e.value > tekrarTavani) '${e.value}× "${e.key}"',
      ];
      expect(
        cokTekrar,
        isEmpty,
        reason: '${b.ad}: aynı cümle bu karede $tekrarTavani defadan '
            'fazla yazılıyor:\n${cokTekrar.join("\n")}',
      );
    });
  }
}
