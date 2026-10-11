// Paket CO — **telefon boyutunda yerleşim.**
//
// **Ölçülen kör nokta.** Depodaki pencere testleri mantıksal olarak
// 360-400 px *genişlikte* koşuyor (fiziksel 1080-1200, dpr 3) ama
// *yükseklik* 3600 ile 14000 px arasında: gerçek telefonun 5-15 katı.
// Yani "içerik telefona sığmıyor" sınıfı bir kusur **hiçbir testte
// görünmüyordu**; ekran dökümü de 1000x9000'lik tek parça kâğıda
// basıyor.
//
// **Bulunan kusur.** 360x640'lık ekranda (720x1280'lik Android
// tabanı) açılış ekranı ölçüldü: "Rastgele bir hayat" düğmesinin alt
// kenarı 630, **"İsmimi ve cinsiyetimi seçeyim" 720.** İkinci
// başlangıç modu katlanmanın altında kalıyordu; oyuncu kaydırmadan
// oyunun iki modundan birini hiç görmüyordu. Düğme ekranda *vardı*
// ama dokunulabilir değildi (`hitTestable` 0) — bu yüzden bu dosyanın
// ilk yazımında yoklama testi "hayat başlatılamadı" diye düştü.
//
// Düzeltme içerik silmiyor: 730 px'den kısa ekranlarda "Nasıl
// oynanır" kartı **katlanıyor** ve tek dokunuşla açılıyor. Uzun
// ekranda yerleşim hiç değişmiyor.
//
// **Ölçüm (düzeltmeden sonra).** 600 · 640 · 700 · 720 · 730 · 760 ·
// 820 px yüksekliklerin **hepsinde** iki başlangıç modu da
// katlanmanın üstünde. Dipnot ("Her iki modda da doğum şehri…")
// 730-820 arasında altta kalıyor; bu, o ekranlar için zaten böyleydi
// ve dipnot bir eylem değil.
//
// **Oyunun geri kalanı temiz.** 360x640'ta 8/17/30/45/70 yaşlarında
// dört sekme ve o hayatta açık olan bütün satır kapıları gezildi (16
// sayfa): **sıfır taşma**. Aynı tarama 200x300'lük saçma bir ekranda
// da sıfır veriyor — yerleşim kaydırma görünümleri ve esnek metinlerle
// kurulduğu için dayanıyor.
//
// **Aracın kendisi ayrıca sınandı** (yoksa dördüncü madde hiçbir şeyi
// koruyamayan yeşil bir test olurdu): bilerek taşan bir `Row`
// basıldığında `takeException` "A RenderFlex overflowed by 640 pixels
// on the right" veriyor, yani tarama taşmayı gerçekten görüyor.
// Dördüncü madde bu yüzden bugünü değil **yarını** bekçiliyor: yeni
// bir ekran telefonda taşarsa test kırmızıya döner.
library;

import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/data/save/save_service.dart';
import 'package:bir_omur/data/save/save_store.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_flow.dart';

/// Oyunun dört sekmesi (NAV-001: `tab_hayat` yoktur).
const List<String> kSekmeler = <String>[
  'tab_okul_meslek',
  'tab_varliklar',
  'tab_iliskiler',
  'tab_aktiviteler',
];

/// Sekme sayfalarındaki alt sayfa kapıları.
const List<String> kSatirlar = <String>[
  'assets_furnishing_row',
  'career_business_row',
  'career_history_row',
  'career_legal_row',
  'career_military_row',
  'career_promotion_row',
  'career_raise_row',
  'career_retire_row',
  'career_sports_row',
  'relationships_children_row',
  'relationships_friends_row',
  'relationships_grandchildren_row',
  'relationships_inlaws_row',
  'relationships_neighbours_row',
  'relationships_pets_row',
  'relationships_relatives_row',
  'relationships_siblings_row',
];

/// Gerçek bir telefonun mantıksal ölçüsü (720x1280 / dpr 2 tabanı).
const Size kTelefon = Size(360, 640);

void _ekran(WidgetTester tester, Size mantiksal) {
  tester.view.physicalSize = Size(mantiksal.width * 3, mantiksal.height * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Kayıt **açık** bir denetleyici: gerçek cihazda açılış ekranında
/// "kayıt klasörü açılamadı" uyarısı yoktur, o uyarı yerleşimi 122 px
/// uzatıyor ve ölçümü yanıltıyordu.
GameController _denetleyici(WidgetTester tester) {
  final GameController c = GameController(
    random: Random(31),
    saveService: SaveService(MemorySaveStore()),
  );
  addTearDown(c.dispose);
  return c;
}

/// Metnin alt kenarı (mantıksal px).
double _altKenar(WidgetTester tester, Finder f) {
  final RenderBox b = tester.renderObject<RenderBox>(f.first);
  return b.localToGlobal(Offset.zero).dy + b.size.height;
}

void main() {
  testWidgets('360x640 telefonda iki başlangıç modu da kaydırmadan görünür',
      (WidgetTester tester) async {
    _ekran(tester, kTelefon);
    await tester.pumpWidget(BirOmurApp(controller: _denetleyici(tester)));
    await tester.pumpAndSettle();

    for (final String etiket in <String>[
      'Rastgele bir hayat',
      'İsmimi ve cinsiyetimi seçeyim',
    ]) {
      final Finder f = find.text(etiket);
      expect(f, findsOneWidget, reason: '"$etiket" ekranda yok');
      expect(_altKenar(tester, f), lessThanOrEqualTo(kTelefon.height),
          reason: '"$etiket" katlanmanın altında kaldı '
              '(alt kenar ${_altKenar(tester, f)}, ekran '
              '${kTelefon.height}); oyuncu kaydırmadan göremiyor');
      expect(f.hitTestable(), findsOneWidget,
          reason: '"$etiket" görünüyor ama dokunulamıyor');
    }
  });

  testWidgets('kısa ekranda nasıl oynanır tek dokunuşla açılıyor',
      (WidgetTester tester) async {
    _ekran(tester, kTelefon);
    await tester.pumpWidget(BirOmurApp(controller: _denetleyici(tester)));
    await tester.pumpAndSettle();

    final Finder kapi = find.byKey(const Key('start_how_to_expand'));
    expect(kapi, findsOneWidget,
        reason: 'kısa ekranda katlanmış kart yok');
    expect(find.text('Her yaş bir karar getirir.'), findsNothing,
        reason: 'kart katlı olmalı');
    await tester.tap(kapi);
    await tester.pumpAndSettle();
    // İçerik silinmedi: üç satırın hepsi geliyor.
    expect(find.text('Her yaş bir karar getirir.'), findsOneWidget);
    expect(find.text('Kararların ilişkilerini ve geleceğini değiştirir.'),
        findsOneWidget);
    expect(find.text('Hiçbir kayıt silinmez; hayatın arşivde kalır.'),
        findsOneWidget);
  });

  testWidgets('uzun ekranda yerleşim değişmiyor: kart açık duruyor',
      (WidgetTester tester) async {
    _ekran(tester, const Size(360, 900));
    await tester.pumpWidget(BirOmurApp(controller: _denetleyici(tester)));
    await tester.pumpAndSettle();

    expect(find.text('Her yaş bir karar getirir.'), findsOneWidget,
        reason: 'uzun ekranda kart açık olmalı');
    expect(find.byKey(const Key('start_how_to_expand')), findsNothing,
        reason: 'uzun ekranda katlama düğmesi görünmemeli');
  });

  testWidgets('telefon boyutunda hiçbir ekran taşmıyor',
      (WidgetTester tester) async {
    _ekran(tester, kTelefon);
    final GameController c = _denetleyici(tester);
    final List<String> tasmalar = <String>[];
    final List<String> digerHatalar = <String>[];
    void topla(String nerede) {
      final Object? e = tester.takeException();
      if (e == null) return;
      final String m = e.toString();
      (m.contains('overflowed') ? tasmalar : digerHatalar)
          .add('$nerede → ${m.split("\n").first}');
    }

    await tester.pumpWidget(BirOmurApp(controller: c));
    await tester.pumpAndSettle();
    topla('açılış');
    await tester.tap(find.text('Rastgele bir hayat'));
    await tester.pumpAndSettle();
    topla('yeni hayat');
    expect(c.state, isNotNull, reason: 'hayat başlatılamadı');

    int gezilen = 0;
    for (final int yas in <int>[8, 17, 30, 45, 70]) {
      await ageTo(tester, c, yas);
      await tester.pumpAndSettle();
      topla('yaş $yas · Hayat');
      if (c.state!.deceased) break;
      for (final String sekme in kSekmeler) {
        final Finder f = find.byKey(Key(sekme));
        if (f.evaluate().isEmpty) continue;
        await tester.tap(f);
        await tester.pumpAndSettle();
        topla('yaş $yas · $sekme');
        gezilen++;
        for (final String satir in kSatirlar) {
          final Finder r = find.byKey(Key(satir));
          if (r.evaluate().isEmpty) continue;
          await tester.tap(r, warnIfMissed: false);
          await tester.pumpAndSettle();
          topla('yaş $yas · $sekme · $satir');
          gezilen++;
          final Finder geri = find.byType(BackButton);
          if (geri.evaluate().isNotEmpty) {
            await tester.tap(geri.first);
            await tester.pumpAndSettle();
            topla('yaş $yas · $sekme · $satir geri');
          }
        }
        final Finder geri = find.byType(BackButton);
        if (geri.evaluate().isNotEmpty) {
          await tester.tap(geri.first);
          await tester.pumpAndSettle();
          topla('yaş $yas · $sekme geri');
        }
      }
    }

    // Ölçüm: bu tohumda 16 sayfa geziliyor (beş yaş × dört sekme ve
    // o hayatta açık olan satır kapıları). Taban altında.
    expect(gezilen, greaterThanOrEqualTo(12),
        reason: 'gezilen sayfa sayısı az: $gezilen — tarama temsil etmiyor');
    expect(tasmalar, isEmpty,
        reason: 'telefon boyutunda taşan yerleşim: $tasmalar');
    expect(digerHatalar, isEmpty,
        reason: 'telefon boyutunda ekran hatası: $digerHatalar');
  });
}
