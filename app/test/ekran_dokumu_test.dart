// Ekranlarda ne yazdığını oku: metin dökümü.
//
// **Neden var.** Oyun hiçbir cihazda çalıştırılmadı; 3.360 test kodun
// kendi içinde tutarlı olduğunu söylüyor ama **oyuncunun ne gördüğünü**
// söylemiyor. 54 widget testi var ve hepsi belirli bir satırı arıyor
// ("zam satırı görünüyor mu"); hiçbiri ekranın tamamını okumuyor. Bu
// yüzden "ekranda hiçbir şey yok", "aynı etiket iki kez", "boş durumda
// oyuncuya ne yapacağı söylenmiyor" gibi şeyler testlerden kaçıyor.
//
// Bu dosya bir **bekçi değil, dürbün**: hayat evrelerine göre Hayat
// ekranının ve dört menünün görünür metnini sırayla basar. Çıktısı gözle
// okunur. Kalıcı denetimi yalnızca bir şey yapar: hiçbir ekran **boş**
// kalmamalı — boş ekran oyuncuya hiçbir şey anlatmaz.
//
// Üç ölçülmüş hata, kurulumu buraya getirdi:
//
// 1. **Hayat zorlama yaşla kurulmaz.** İlk yazımda evreyi
//    `player.copyWith(age: 8)` ile kurmuştum. Oyuncu yaşlandı ama dünya
//    yaşlanmadı: 8 yaşındaki çocuğun annesi 22 göründü, yani doğumda
//    14'müş. Bunu hata sanıp raporlayacaktım; 400 hayatlık ölçüm gerçeği
//    söyledi — annenin doğumdaki yaşı en küçük **17**, medyan 30. Hata
//    üretimde değil, benim kurduğum imkânsız durumdaydı.
// 2. **Yaş almanın beş kapısı var.** `ageUp()` bekleyen olay, ölüm,
//    sağlık krizi, lise alanı (D-094) ve lise sonrası yol (D-111)
//    kapılarında durur. İlk yazımda yalnızca ilk ikisini karşılıyordum;
//    17/30/70 evrelerinin üçü de **14 yaşında** takılı kaldı.
// 3. **Durumu koddan değiştirmek pencereyi kapatmaz.** Olayları
//    `controller.chooseEventOption` ile cevaplayınca ekranda açık kalan
//    `EventDialog` modal olduğu için sekme dokunuşları bariyere çarptı;
//    dört evrenin hepsinde beş ekran da **aynı** metni verdi
//    (54/54/54/54). Bunu "sekmeler çalışmıyor" sanacaktım; sebep ürün
//    değil kurulumdu.
//
// Üçünün ortak dersi: döküm **gerçek oyuncunun yolundan** alınmalı. Bu
// yüzden hayat, UI smoke testinin kullandığı ortak arayüz akışı
// yardımcılarıyla büyütülüyor — düğmelere basılarak.
library;

import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_flow.dart';

/// Alt çubuktaki **dört** menü, ekrandaki sırasıyla (NAV-001).
///
/// Hayat burada yok: `bottom_action_bar.dart` dört sekme bekliyor
/// (`assert(tabs.length == 4)`) ve Hayat ekranı hiçbir sekme seçili
/// değilken (`selectedId == null`) görünen varsayılan ekran. İlk yazımda
/// `tab_hayat` anahtarını arıyordum; döküm "sekme yok" dedi — ürün hatası
/// değil, benim yanlış varsayımımdı. Hayat ekranı artık hiçbir sekmeye
/// dokunmadan, en başta dökülüyor.
const List<(String, String)> kSekmeler = <(String, String)>[
  ('tab_okul_meslek', 'Okul / Meslek'),
  ('tab_varliklar', 'Varlıklar'),
  ('tab_iliskiler', 'İlişkiler'),
  ('tab_aktiviteler', 'Aktiviteler'),
];

void main() {
  late GameController controller;
  setUp(() => controller = GameController(random: Random(7)));
  tearDown(() => controller.dispose());

  /// Görünür metinleri ağaç sırasıyla toplar.
  List<String> metinler(WidgetTester tester) {
    final List<String> out = <String>[];
    for (final Text w in tester.widgetList<Text>(find.byType(Text))) {
      final String? d = w.data ?? w.textSpan?.toPlainText();
      if (d == null) continue;
      final String t = d.trim().replaceAll(RegExp(r'\s+'), ' ');
      if (t.isEmpty) continue;
      out.add(t);
    }
    return out;
  }

  /// Uygulamayı açar ve rastgele bir hayat başlatır.
  ///
  /// **Görüş alanı bilerek telefon ölçüsünden çok yüksek.** Döküm
  /// yalnızca **çizilmiş** metni okuyor; uzun listelerde ekranın altına
  /// düşen satırlar hiç kurulmuyor. 6400 piksel yükseklikle ilk
  /// okumada Aktiviteler'de "Hayat işleri" başlığını **boş** gördüm ve
  /// ürün hatası sanacaktım; yükseklik 14000'e çıkınca altındaki
  /// Sosyal medya, Banka, Ehliyet, Evlat Edinme ve Son Kararlar
  /// satırları göründü. Bu bir yerleşim testi değil döküm: amacı
  /// metnin tamamını görmek, gerçek telefonu taklit etmek değil.
  /// Yerleşimi `ui_smoke_life_test.dart` gerçek ölçüde sınıyor.
  Future<void> ac(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 14000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(BirOmurApp(controller: controller));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rastgele bir hayat'));
    await tester.pumpAndSettle();
  }

  /// Ekranda bekleyen **ne varsa** arayüzden kapatır: bildirim, sağlık
  /// krizi, olay ve eğitim kararı pencereleri.
  ///
  /// Hepsi düğmeye basılarak kapatılır; durumu koddan değiştirmek açık
  /// pencereyi bırakıyor ve sonraki dokunuşları yutuyor (yukarıdaki 3.
  /// ölçülmüş hata).
  Future<void> ekraniTemizle(WidgetTester tester) async {
    for (int tur = 0; tur < 60; tur++) {
      await tester.pumpAndSettle();
      if (controller.state!.deceased) return;
      if (controller.state!.hasNotice) {
        await answerPendingNotices(tester, controller);
        continue;
      }
      if (controller.state!.hasPendingCrisis) {
        await answerPendingCrisis(tester, controller);
        continue;
      }
      final ActiveEvent? olay = controller.state!.pendingEvent;
      if (olay != null) {
        final EventChoice secim = olay.choices[
            Random(controller.state!.player.age + tur)
                .nextInt(olay.choices.length)];
        final Finder dugme = find.text(secim.label);
        if (dugme.evaluate().isEmpty) {
          controller.chooseEventOption(secim.id);
          continue;
        }
        await tester.tap(dugme);
        await tester.pumpAndSettle();
        final Finder devam = find.text('Devam');
        if (devam.evaluate().isNotEmpty) {
          await tester.tap(devam);
          await tester.pumpAndSettle();
        }
        continue;
      }
      if (controller.needsEducationChoice) {
        await resolveEducationSheets(tester, controller);
        continue;
      }
      return;
    }
  }

  /// Hayatı **arayüzden** yaşayarak hedef yaşa getirir.
  ///
  /// Her yıl: bekleyenler kapatılır, sonra gerçek **Yaş Al** düğmesine
  /// basılır. Tur sayısı sınırlı: kilitlenirse test donmaz, olduğu yaşta
  /// döker ve döküm başlığı gerçek yaşı yazar.
  Future<void> buyut(WidgetTester tester, int hedefYas) async {
    for (int tur = 0; tur < hedefYas * 3 + 30; tur++) {
      if (controller.state!.player.age >= hedefYas) return;
      if (controller.state!.deceased) return;
      await ekraniTemizle(tester);
      if (controller.state!.deceased) return;
      final Finder yasAl = find.byKey(const Key('age_up_button'));
      if (yasAl.evaluate().isEmpty) return;
      final int once = controller.state!.player.age;
      await tester.tap(yasAl);
      await tester.pumpAndSettle();
      if (controller.state!.player.age == once &&
          !controller.state!.hasPendingEvent &&
          !controller.state!.hasNotice &&
          !controller.state!.hasPendingCrisis &&
          !controller.needsEducationChoice) {
        return; // İlerleyemiyoruz: olduğu yaşta dök.
      }
    }
  }

  const Map<String, int> evreler = <String, int>{
    '8 yaşında çocuk': 8,
    '17 yaşında lise çağı': 17,
    '30 yaşında yetişkin': 30,
    '70 yaşında yaşlı': 70,
  };

  for (final MapEntry<String, int> evre in evreler.entries) {
    testWidgets('EKRAN DÖKÜMÜ — ${evre.key}', (WidgetTester tester) async {
      await ac(tester);
      await buyut(tester, evre.value);
      await ekraniTemizle(tester);
      final GameState son = controller.state!;
      final StringBuffer rapor = StringBuffer()
        ..writeln('\n${'=' * 68}')
        ..writeln('EKRAN DÖKÜMÜ · ${evre.key} '
            '(gerçek yaş: ${son.player.age}, '
            'bekleyen olay: ${son.hasPendingEvent}, '
            'bildirim: ${son.hasNotice})')
        ..writeln('=' * 68);

      final List<String> bosEkranlar = <String>[];

      // Hayat ekranı: hiçbir sekme seçili değilken görünen varsayılan.
      final List<String> hayat = metinler(tester);
      rapor.writeln('\n--- Hayat (varsayılan ekran) --- '
          '(${hayat.length} metin)');
      for (final String s in hayat) {
        rapor.writeln('   $s');
      }
      if (hayat.length < 3) bosEkranlar.add('Hayat');

      for (final (String anahtar, String ad) in kSekmeler) {
        final Finder sekme = find.byKey(Key(anahtar));
        if (sekme.evaluate().isEmpty) {
          rapor.writeln('\n--- $ad --- (SEKME YOK)');
          bosEkranlar.add('$ad (sekme yok)');
          continue;
        }
        await tester.tap(sekme);
        await tester.pumpAndSettle();
        final List<String> satirlar = metinler(tester);
        rapor.writeln('\n--- $ad --- (${satirlar.length} metin)');
        for (final String s in satirlar) {
          rapor.writeln('   $s');
        }
        if (satirlar.length < 3) bosEkranlar.add(ad);
      }
      // ignore: avoid_print
      print(rapor);

      // Tek kalıcı denetim: boş ekran olmamalı.
      expect(bosEkranlar, isEmpty,
          reason: '${evre.key} için şu ekranlar neredeyse boş: '
              '${bosEkranlar.join(", ")}. Boş ekran oyuncuya hiçbir şey '
              'anlatmaz; en azından ne olduğunu ve ne zaman açılacağını '
              'yazması gerekir (D-063).');
    });
  }
}
