// Ekran dökümü, üçüncü tur: **özel durumlar**.
//
// **Neden var.** İlk iki döküm (`ekran_dokumu_test.dart` ve
// `ekran_dokumu_bot_test.dart`) sıradan hayatların ekranlarını okudu ve
// yedi gerçek hata buldu. Ama bazı ekranlar hiçbirinde görünmedi,
// çünkü o duruma düşmek şans işi:
//
//   · cezaevi · bekleyen duruşma · kritik sağlık (cevap bekleyen kriz)
//   · yeni doğmuş bebek · emeklilik sonrası
//
// Bunları `copyWith` ile **kurmak** cazip ama tehlikeli: bu dürbünün
// ilk turunda tam o yüzden yanlış bulgu üretmiştim (oyuncuyu
// yaşlandırıp dünyayı yerinde bırakmak, 8 yaşındaki çocuğa 22 yaşında
// anne). Bu yüzden durum **kurulmuyor, aranıyor**: bot yüzlerce hayat
// oynuyor, her yıl kontrol ediliyor ve aranan koşul gerçekten
// oluştuğunda o yılın karesi fotoğraflanıyor.
//
// Bir koşul taranan tohumlarda hiç oluşmazsa test **"BULUNAMADI"**
// yazar ve geçer. Bu bilerek: bulunamamak bir ürün hatası değil, ama
// "okundu" da sayılmaz — çıktıda açıkça görünür.
//
// **ÖLÇÜLEN HATA (dördüncü tur).** İlk yazımda "YENİ DOĞAN BEBEK"
// BULUNAMADI çıkıyordu ve bunu oyunun bir eksiği sanmaya başlamıştım.
// Değildi: tarama kancası `onYear`, yani **yaş aldıktan sonra**
// çalışıyor; doğduğu yıl 0 yaşında olan bebeği `ageUp()` 1 yaşına
// taşıdığı için o kare hiç görünmüyordu. 60 hayatta ölçüm: yıl içinde
// 0 yaşında çocuk **77 kare**, yıl sonunda **0 kare**. Yıl içi durumlar
// bu yüzden `onPreAge` ile aranıyor. Ders yine aynı: aranan şey
// bulunamadığında önce dürbüne bak.
library;

import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/player_bot.dart';
import 'support/test_flow.dart';

/// Alt çubuktaki dört menü (NAV-001); Hayat varsayılan ekran.
const List<(String, String)> kSekmeler = <(String, String)>[
  ('tab_okul_meslek', 'Okul / Meslek'),
  ('tab_varliklar', 'Varlıklar'),
  ('tab_iliskiler', 'İlişkiler'),
  ('tab_aktiviteler', 'Aktiviteler'),
];

/// Aranan özel durum.
class Durum {
  const Durum(
    this.ad,
    this.kosul, {
    this.ekranTemizlenmesin = false,
    this.yilIci = false,
  });

  final String ad;
  final bool Function(GameState) kosul;

  /// Kritik sağlık ve duruşma gibi durumlarda bekleyen pencere
  /// **durumun kendisi**; onu kapatmak dökülecek şeyi yok eder.
  final bool ekranTemizlenmesin;

  /// Yalnızca **yıl içinde** var olan durum: yaş alma öncesinde aranır.
  ///
  /// Yeni doğan bebek böyledir; `onYear` ile hiç bulunamaz (dosya
  /// başlığındaki ölçüm).
  final bool yilIci;
}

void main() {
  late GameController controller;
  bool acildi = false;
  setUp(() {
    controller = GameController(random: Random(31));
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

  Future<void> ac(WidgetTester tester, GameState durum) async {
    if (!acildi) {
      tester.view.physicalSize = const Size(1200, 14000);
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

  Future<void> ekraniTemizle(WidgetTester tester) async {
    for (int tur = 0; tur < 40; tur++) {
      await tester.pumpAndSettle();
      if (controller.state!.deceased) return;
      // **Önceki kareden kalan kriz penceresi.** Kritik sağlık karesi
      // bilerek pencereyi açık bırakıyor; bir sonraki kare açıldığında
      // o pencere hâlâ gezinti yığınında duruyor ve yeni durumda kriz
      // olmadığı için boş sonuçla ("Durum kapandı.") görünüp sekmeleri
      // kilitliyor. Dördüncü turda bebek karesi tam bu yüzden yanlış
      // ekranı basmıştı.
      if (controller.state!.hasPendingCrisis ||
          find.byKey(const Key('crisis_result_title')).evaluate().isNotEmpty) {
        await answerPendingCrisis(tester, controller);
        continue;
      }
      if (controller.state!.hasNotice) {
        await answerPendingNotices(tester, controller);
        continue;
      }
      final ActiveEvent? olay = controller.state!.pendingEvent;
      if (olay != null) {
        final EventChoice secim = olay.choices.first;
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
      return;
    }
  }

  /// Taranan arketipler ve tohum aralığı.
  ///
  /// Riskli hayat suç/hukuk için, aile odaklı doğum için, rahat hayat
  /// kritik sağlık ve emeklilik için. Tohum sayısı bilerek ölçülü:
  /// amaç istatistik değil, **bir örnek bulmak**.
  const List<PlayerArchetype> arketipler = <PlayerArchetype>[
    PlayerArchetype.risky,
    PlayerArchetype.family,
    PlayerArchetype.casual,
  ];
  const int tohumSayisi = 40;

  final List<Durum> aranan = <Durum>[
    Durum('CEZAEVİ', (GameState s) => s.isImprisoned),
    Durum('BEKLEYEN DURUŞMA', (GameState s) => s.hasPendingTrial,
        ekranTemizlenmesin: true),
    Durum('KRİTİK SAĞLIK', (GameState s) => s.hasPendingCrisis,
        ekranTemizlenmesin: true),
    Durum(
      'YENİ DOĞAN BEBEK',
      (GameState s) => s.people.any((Person p) =>
          p.relation == RelationType.cocuk && p.isAlive && p.age == 0),
      yilIci: true,
    ),
    Durum('EMEKLİ', (GameState s) => s.career.isRetired),
  ];

  testWidgets('EKRAN DÖKÜMÜ — özel durumlar (taranarak bulundu)',
      (WidgetTester tester) async {
    // 1) Durumları ara. Her durum için **ilk** bulunan kare saklanır.
    final Map<String, (GameState durum, int seed, PlayerArchetype a)> kareler =
        <String, (GameState, int, PlayerArchetype)>{};
    int taranan = 0;
    for (final PlayerArchetype arketip in arketipler) {
      for (int seed = 1; seed <= tohumSayisi; seed++) {
        if (kareler.length == aranan.length) break;
        taranan++;
        playBotLife(
          archetype: arketip,
          seed: seed * 101 + arketip.index,
          onYear: (GameState s) {
            for (final Durum d in aranan) {
              if (d.yilIci || kareler.containsKey(d.ad)) continue;
              if (d.kosul(s)) {
                kareler[d.ad] = (s, seed, arketip);
              }
            }
          },
          onPreAge: (GameState s) {
            for (final Durum d in aranan) {
              if (!d.yilIci || kareler.containsKey(d.ad)) continue;
              if (d.kosul(s)) {
                kareler[d.ad] = (s, seed, arketip);
              }
            }
          },
        );
      }
    }

    final StringBuffer rapor = StringBuffer()
      ..writeln('\n${'=' * 68}')
      ..writeln('ÖZEL DURUM TARAMASI — $taranan hayat oynandı')
      ..writeln('=' * 68);
    for (final Durum d in aranan) {
      final kare = kareler[d.ad];
      rapor.writeln(kare == null
          ? '  ${d.ad}: BULUNAMADI (bu tohumlarda oluşmadı)'
          : '  ${d.ad}: bulundu — ${kare.$3.label}, tohum ${kare.$2}, '
              'yaş ${kare.$1.player.age}');
    }
    // ignore: avoid_print
    print(rapor);

    // 2) Bulunan her kareyi dök.
    for (final Durum d in aranan) {
      final kare = kareler[d.ad];
      if (kare == null) continue;
      final GameState baslangic = kare.$1;
      await ac(tester, baslangic);
      if (!d.ekranTemizlenmesin) {
        await ekraniTemizle(tester);
      } else {
        await tester.pumpAndSettle();
      }
      final GameState s = controller.state!;

      final StringBuffer dokum = StringBuffer()
        ..writeln('\n${'=' * 68}')
        ..writeln('ÖZEL DURUM · ${d.ad}')
        ..writeln('${kare.$3.label} · tohum ${kare.$2} · yaş '
            '${s.player.age} · cüzdan ${s.player.wallet} ₺ · '
            'cezaevi ${s.isImprisoned} · duruşma ${s.hasPendingTrial} · '
            'kriz ${s.hasPendingCrisis} · emekli ${s.career.isRetired}')
        ..writeln('=' * 68);

      // Bekleyen pencere varken geri çıkartması modal bariyerin
      // arkasında kalır; o durumlarda ana ekrana dönmek denenmez.
      if (!d.ekranTemizlenmesin && !await anaEkrana(tester)) {
        dokum.writeln('\n!!! ANA EKRANA DÖNÜLEMEDİ — aşağıdaki "Hayat" '
            'bölümü başka bir ekran olabilir.');
      }
      final List<String> hayat = metinler(tester);
      dokum.writeln('\n--- Hayat / açık pencere --- (${hayat.length} metin)');
      for (final String x in hayat) {
        dokum.writeln('   $x');
      }

      // Bekleyen pencere varken sekmeler modal bariyerin arkasında
      // kalır; o durumlarda sekme gezilmez (bu bir ürün hatası değil,
      // bilerek konmuş bir kilit).
      if (!d.ekranTemizlenmesin) {
        for (final (String anahtar, String ad) in kSekmeler) {
          final Finder sekme = find.byKey(Key(anahtar));
          if (sekme.evaluate().isEmpty) {
            dokum.writeln('\n--- $ad --- (SEKME YOK)');
            continue;
          }
          await tester.tap(sekme);
          await tester.pumpAndSettle();
          final List<String> satirlar = metinler(tester);
          dokum.writeln('\n--- $ad --- (${satirlar.length} metin)');
          for (final String x in satirlar) {
            dokum.writeln('   $x');
          }
        }
      }
      // ignore: avoid_print
      print(dokum);

      // Kalıcı denetim: ekranda ham `null` görünmez (Paket BF).
      final List<String> kotu =
          metinler(tester).where((String x) => x.contains('null')).toList();
      expect(kotu, isEmpty,
          reason: '${d.ad} ekranında ham null: $kotu');
    }

    // Tarama boşa çalışmasın: en az bir durum bulunmalı.
    expect(kareler, isNotEmpty,
        reason: '$taranan hayatta aranan beş durumdan hiçbiri oluşmadı; '
            'ya tarama bozuk ya koşullar yanlış yazılmış.');
  });
}
