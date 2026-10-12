// Ekran dökümü, sekizinci tur: **bölüm sayfalarının içi**.
//
// **Neden var — dürbünün kendi kapsamı.** Paket DH "hangi ekran hiç
// okunmadı?" sorusunu sordu ve dokuz ekranın dokuzunda da bir test yolu
// bulduğunu yazdı. O denetim `lib/ui/screens/**/*_screen.dart`
// dosyalarını saymıştı; oyunun içeriğinin büyük bölümü ise
// `sections/` altındaki **26 `*_page.dart`** dosyasında ve o dosyalar
// denetimin kapsamına hiç girmemişti. Paket DJ'nin dersi aynen
// geçerliydi: **ölçümün kapsamını da ölç.**
//
// Ölçüm (12 Ekim 2026): `sections/` altındaki 30 dosyanın
// `SectionScaffold` başlıkları çıkarıldı ve bütün test kaynağında
// arandı. Sekizinin başlığı hiçbir testte geçmiyordu:
//
//   bank_page · eye_exam_page · furnishing_page · hobbies_page ·
//   insurance_page · marriage_history_page · media_page · military_page
//
// Başlık taraması **zayıf bir vekildir** (DH'nin kendi uyarısı):
// başlığı hiçbir testte geçmeyen sayfa yine de çizilmiş olabilir. Bu
// yüzden bu döküm vekille yetinmiyor, sayfaları gerçekten **açıyor ve
// metnini basıyor**. Ölçü, okunan karedir.
//
// **Durum kurulmuyor, aranıyor.** Sekiz sayfanın her birinin bir kapısı
// var (18 yaş, hobisi olmak, kendi hanesini kurmuş olmak, Ün eşiği,
// evlilik kaydı…). Bu kapıları `copyWith` ile açmak bu dürbünün ilk
// turunda yanlış bulguya yol açmıştı; burada bot hayatları oynuyor ve
// kapının **gerçekten** açık olduğu temiz bir kare yakalanıyor. Kare
// bulunamazsa test "BULUNAMADI" yazar ve geçer: bulunamamak ürün hatası
// değil, ama "okundu" da sayılmaz.
library;

import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/player_bot.dart';
import 'support/section_pages.dart';

/// Taranan kareler; bir kez doldurulur, bütün testler aynı kümeyi okur.
final Map<String, GameState> _kareler = <String, GameState>{};
bool _tarandi = false;

/// Bot hayatları oynatıp her bölümün kapısının açık olduğu **temiz** bir
/// kare bulur.
///
/// Temiz kare: bekleyen olay, bildirim veya kriz yok. Bekleyen bir şey
/// varken `debugSetState` edilen durumda modal pencere açılıyor ve
/// sekmeler kilitleniyor (Paket CG'nin ölçtüğü tuzak).
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
      if (_kareler.length == kBolumler.length) return;
      void bak(GameState s) {
        if (s.deceased) return;
        if (s.hasNotice || s.pendingEvent != null || s.hasPendingCrisis) {
          return;
        }
        for (final Bolum b in kBolumler) {
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
  /// `scrollToFinder` ağacın **ilk** `Scrollable`'ını kaydırıyor. Okul
  /// / Meslek sekmesinde o ilk alan sayfanın gövdesi değil; "Kendi
  /// İşim" satırı 24000 px görüş alanıyla bile kurulmuyor ve
  /// `scrollUntilVisible` "No element" atıyordu. Döküm bu yüzden
  /// alanları sırayla deniyor.
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
        // Bu alan hedefi taşımıyor; sıradakini dene.
        continue;
      }
    }
    return hedef.evaluate().isNotEmpty;
  }

  Future<void> ac(WidgetTester tester, GameState durum) async {
    if (!acildi) {
      // Görüş alanı bilerek telefon ölçüsünden yüksek: döküm yalnızca
      // **çizilmiş** metni okur (bkz. ekran_dokumu_test.dart).
      // **24000 px (Paket DN).** 14000 ile Okul/Meslek sekmesi
      // işletmesi olan oyuncuda sonuna kadar kurulmuyordu: "Kendi
      // İşim" satırı listenin dışında kalıyor ve `scrollUntilVisible`
      // "No element" atıyordu. Bu bir yerleşim testi değil döküm;
      // amacı metnin tamamını görmek (yerleşimi gerçek ölçüde
      // `ui_smoke_life_test.dart` sınıyor).
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

  for (final Bolum b in kBolumler) {
    testWidgets('bölüm dökümü: ${b.ad}', (WidgetTester tester) async {
      _tara();
      final GameState? durum = _kareler[b.ad];
      if (durum == null) {
        // ignore: avoid_print
        print('\n===== ${b.ad} =====\nBULUNAMADI (taranan kareler '
            've kapı için dosya başlığına bak).');
        return;
      }

      await ac(tester, durum);
      final Finder sekme = find.byKey(Key(b.sekme));
      expect(sekme, findsOneWidget, reason: '${b.sekme} sekmesi yok.');
      await tester.tap(sekme);
      await tester.pumpAndSettle();

      // **Araç yalan söylemez (Paket CV dersi).** Yol üstündeki bir
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
        // **Dokunmanın işe yaradığı genel olarak denetlenir.** Kapalı
        // bir satıra dokunmak hiçbir şey yapmaz ve döküm eski kareyi
        // basıp "okudum" sayar (Paket DM'de tam bu oldu). Kare
        // değişmediyse yol kırılmıştır; işaret denetimi bunun
        // üstüne ikinci bir kilittir.
        final List<String> onceki = metinler(tester);
        await tester.tap(hedef.first);
        await tester.pumpAndSettle();
        final List<String> sonraki = metinler(tester);
        expect(
          sonraki.join('|') == onceki.join('|'),
          isFalse,
          reason: '${b.ad}: yolun ${i + 1}. adımına dokunuldu ama ekran '
              'hiç değişmedi. Satır kapalı olabilir; kapıyı daralt ya '
              'da eylem düğmesine dokun.',
        );
      }

      final List<String> ekran = metinler(tester);
      // ignore: avoid_print
      print('\n===== ${b.ad} · ${durum.player.age} yaş · '
          '${ekran.length} metin =====');
      // ignore: avoid_print
      print(ekran.join('\n'));

      // **Sayfanın gerçekten açıldığı kanıtlanır.** Dokunmanın işe
      // yaramadığı durumda (kapalı satır) eski ekran basılıyor ve
      // döküm yanlış şeyi "okudum" sayıyordu.
      expect(
        ekran.any((String t) => t.contains(b.isaret)),
        isTrue,
        reason: '${b.ad}: beklenen işaret ("${b.isaret}") ekranda yok. '
            'Basılan kare başka bir sayfa olabilir — yukarıdaki dökümü '
            'oku.',
      );
      expect(
        ekran.length,
        greaterThan(3),
        reason: '${b.ad} sayfası neredeyse boş çizildi.',
      );

      // **Ayraçsız sayı taraması (Paket DN).** Döküm 18 sayfanın
      // metnini zaten basıyor; aynı metin bir biçim bekçisi olarak da
      // okunabilir. Beş haneden uzun bir sayı bloğu ekranda ayraç
      // beklediğimiz bir sayıdır. Ölçüldü: bu tarama iki gerçek yer
      // buldu — Hayat Hedefleri'nde "100000 takipçiye ulaş" ve
      // piyango oranlarında "1/500000". Dört hane sınırın dışında
      // bırakıldı: kurgusal araç modeli "Sarp 1100 Tur" gibi adlar
      // sayı değil **ad**.
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
    });
  }
}
