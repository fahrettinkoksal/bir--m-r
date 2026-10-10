// Ekran dökümü, ikinci hayat: botun yaşadığı **dolu** hayat.
//
// **Neden ayrı bir dosya.** `ekran_dokumu_test.dart` hayatı arayüzden
// kendisi yaşıyor ama yalnızca "Yaş Al"a basıyor: iş aramıyor, evlenmiyor,
// ev almıyor. Çıkan hayat yoksul, işsiz ve hiç evlenmemiş bir adam oldu —
// yani o döküm şu ekranları **hiç göstermedi**:
//
//   · Meslek ekranı bir **işi varken** (unvan, maaş, zam, terfi, ustalık)
//   · İlişkiler ekranı **eş ve çocuk** varken
//   · Varlıklar ekranı **ev, araba ve yatırım** varken
//
// Oyunun en çok kod barındıran ekranları bunlar. Bu dosya aynı dürbünü
// oraya çeviriyor.
//
// **Hayat nasıl kuruluyor.** `playBotLife` bütün kararları veren botu
// doğumdan ölüme oynatıyor (iş, evlilik, çocuk, konut, yatırım,
// işletme). `onYear` her yılın sonunda çağrıldığı için hedef yaşların
// durumu oradan **fotoğraflanıyor**; sonra o durum bir kontrolcüye
// yüklenip ekranlar basılıyor.
//
// **Bu, daha önce yanlış bulgu üreten "zorlama durum" değil.** O hata
// `copyWith(age: 70)` ile oyuncuyu yaşlandırıp dünyayı yerinde
// bırakmaktı; buradaki durum gerçekten yaşanmış bir hayatın o yılki
// kaydı — anne gerçekten yaşlandı, çocuk gerçekten doğdu, iş gerçekten
// bulundu. Ekran basılmadan önce bekleyen pencereler **arayüzden**
// kapatılıyor (modal pencere dokunuşları yutuyor).
// **Hâlâ okunmamış ekranlar (uydurmuyorum, eksik olarak yazıyorum).**
// "Riskli hayat" arketipi seçildiği tohumda suç işlemedi — ekranda
// "Adli kaydın temiz" yazdı — yani **cezaevi, duruşma ve denetim
// dönemi ekranları bu dökümde de görünmedi.** Aynı şekilde kritik
// sağlık ekranı, gebelik/doğum ve emeklilik sonrası da bu beş karede
// yok. Bunları görmek için ya durumu kurmak (kurulu durum, dolu hayat
// değil) ya da tohum taramak gerekiyor; ikisi de ayrı iş.
//
// Görünen ekranlar: işi olan Meslek (unvan, maaş, ustalık, itibar,
// kariyer geçmişi), eş ve çocuklu İlişkiler (kayın aile, evlilik
// geçmişi, aile kararları), ev-araç-yatırım dolu Varlıklar, üniversite
// yılları ve işletme sahibi bir hayat.
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

void main() {
  late GameController controller;

  /// Uygulama bu testte açıldı mı? Her test kendi kontrolcüsüyle
  /// başladığı için sıfırlanır.
  bool acildi = false;

  setUp(() {
    controller = GameController(random: Random(21));
    acildi = false;
  });
  tearDown(() => controller.dispose());

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

  /// Botun yaşadığı hayattan hedef yaşların fotoğrafını çeker.
  ///
  /// Hayat **bir kez** oynanıyor; istenen yaşların hepsi aynı hayattan
  /// geliyor, böylece ekranlar arasında süreklilik var.
  ///
  /// **Ölü kare alınmaz (Paket BS/0).** `onYear` hayatın son yılında da
  /// çağrılıyor; o karede oyun bilerek "Bir ömür tamamlandı" özetini
  /// gösterir ve alt sekmeler yoktur. Eski yazımda o kare de
  /// fotoğraflanıyordu: aile arketipi 40 yaşında öldüğü bir tohumda
  /// "dört sekme yok" diye düştü — ekran değil kare yanlıştı.
  ///
  /// **Tohum sabit değil, hedef sabit.** Bot her pakette biraz değişiyor
  /// (zar akışı kayıyor) ve sabitlenmiş tohum bir gün ölü/boş bir hayata
  /// düşüyor. Hedef yaşlara **canlı** ulaşan ve arketipin okumak istediği
  /// ekranı gerçekten dolduran bir hayat bulunana kadar tohum ilerler.
  /// Sabitlenmiş tohum işini yapıyorsa ilk denemede döner, döküm aynı
  /// kalır.
  ({Map<int, GameState> kareler, int tohum}) botHayati({
    required PlayerArchetype arketip,
    required int seed,
    required Set<int> yaslar,
    bool Function(GameState)? gerek,
  }) {
    for (int deneme = 0; deneme < 24; deneme++) {
      final int tohum = seed + deneme * 101;
      final Map<int, GameState> kareler = <int, GameState>{};
      playBotLife(
        archetype: arketip,
        seed: tohum,
        onYear: (GameState s) {
          if (s.deceased) return;
          if (yaslar.contains(s.player.age)) {
            kareler.putIfAbsent(s.player.age, () => s);
          }
        },
      );
      if (kareler.length < yaslar.length) continue;
      final GameState son = kareler[yaslar.reduce(max)]!;
      if (gerek != null && !gerek(son)) continue;
      return (kareler: kareler, tohum: tohum);
    }
    return (kareler: <int, GameState>{}, tohum: seed);
  }

  /// Arketipin dökümden beklediği hayat.
  ///
  /// Aile dökümünün amacı eş/çocuk/torun ekranını okumak; hiç evlenmemiş
  /// bir hayatta o ekran yine boş kalır. Diğer arketiplerin sabit
  /// tohumları zaten istenen hayatı veriyor, onlara koşul koymuyorum —
  /// koşul ancak tohum işini yapmazsa devreye girer.
  bool Function(GameState)? arketipGeregi(PlayerArchetype a) =>
      switch (a) {
        PlayerArchetype.family => (GameState s) => s.people.any(
            (Person p) => p.relation == RelationType.cocuk && p.isAlive),
        _ => null,
      };

  /// Uygulama **bir kez** açılır.
  ///
  /// İlk yazımda her yaş için yeniden açıp "Rastgele bir hayat"a
  /// basıyordum; ikinci çağrıda hayat zaten başladığı için o düğme
  /// ekranda yok ve test düşüyordu. Açılış ayrı, durum yükleme ayrı.
  Future<void> ac(WidgetTester tester, GameState durum) async {
    if (!acildi) {
      // Görüş alanı bilerek yüksek: döküm yalnızca **çizilmiş** metni
      // okur, kısa ekranda listenin altı hiç kurulmaz.
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

  /// Bekleyen pencereleri arayüzden kapatır (yaş ilerletmez).
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
        final EventChoice secim =
            olay.choices[Random(controller.state!.player.age + tur)
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

  /// Bir durumun beş ekranını basar ve boş ekranları döner.
  Future<List<String>> dok(
    WidgetTester tester,
    String baslik,
    GameState durum,
  ) async {
    await ac(tester, durum);
    await ekraniTemizle(tester);
    final GameState s = controller.state!;
    final StringBuffer rapor = StringBuffer()
      ..writeln('\n${'=' * 68}')
      ..writeln('BOT HAYATI · $baslik')
      ..writeln('yaş ${s.player.age} · cüzdan ${s.player.wallet} ₺ · '
          'iş ${s.career.jobId ?? "yok"} · '
          'eşya ${s.items.length} · kişi ${s.people.length}')
      ..writeln('=' * 68);

    final List<String> bos = <String>[];
    // Seçili sekme kareler arasında kalıcı (`anaEkrana`).
    if (!await anaEkrana(tester)) {
      rapor.writeln('\n!!! ANA EKRANA DÖNÜLEMEDİ — aşağıdaki "Hayat" '
          'bölümü başka bir ekran olabilir.');
    }
    final List<String> hayat = metinler(tester);
    rapor.writeln('\n--- Hayat (varsayılan) --- (${hayat.length} metin)');
    for (final String x in hayat) {
      rapor.writeln('   $x');
    }
    if (hayat.length < 3) bos.add('Hayat');

    for (final (String anahtar, String ad) in kSekmeler) {
      final Finder sekme = find.byKey(Key(anahtar));
      if (sekme.evaluate().isEmpty) {
        rapor.writeln('\n--- $ad --- (SEKME YOK)');
        bos.add('$ad (sekme yok)');
        continue;
      }
      await tester.tap(sekme);
      await tester.pumpAndSettle();
      final List<String> satirlar = metinler(tester);
      rapor.writeln('\n--- $ad --- (${satirlar.length} metin)');
      for (final String x in satirlar) {
        rapor.writeln('   $x');
      }
      if (satirlar.length < 3) bos.add(ad);
    }
    // ignore: avoid_print
    print(rapor);
    return bos;
  }

  /// Hangi arketip hangi yaşlarda dökülecek.
  ///
  /// Kariyer odaklı: iş, unvan, maaş, ustalık. Aile odaklı: eş, çocuk,
  /// torun. Yatırımcı: ev, araç, portföy.
  const Map<PlayerArchetype, (int, List<int>)> plan =
      <PlayerArchetype, (int, List<int>)>{
    PlayerArchetype.career: (31, <int>[35, 55]),
    PlayerArchetype.family: (47, <int>[40, 65]),
    PlayerArchetype.investor: (53, <int>[45]),
    // Üniversite yılları: eğitim ekranının hiç okunmamış hâli.
    PlayerArchetype.education: (67, <int>[21, 26]),
    // İşletme ekranı: sermaye, personel, reklam, yıllık rapor.
    PlayerArchetype.entrepreneur: (71, <int>[38, 58]),
    // Adli süreç ve cezaevi: suç/hukuk ekranları.
    PlayerArchetype.risky: (73, <int>[28, 50]),
  };

  for (final MapEntry<PlayerArchetype, (int, List<int>)> girdi
      in plan.entries) {
    final PlayerArchetype arketip = girdi.key;
    final int seed = girdi.value.$1;
    final List<int> yaslar = girdi.value.$2;

    testWidgets('EKRAN DÖKÜMÜ (bot) — ${arketip.label}',
        (WidgetTester tester) async {
      final ({Map<int, GameState> kareler, int tohum}) hayat = botHayati(
        arketip: arketip,
        seed: seed,
        yaslar: yaslar.toSet(),
        gerek: arketipGeregi(arketip),
      );
      final Map<int, GameState> kareler = hayat.kareler;
      expect(kareler.length, yaslar.length,
          reason: '${arketip.label}: 24 tohumun hiçbirinde '
              '${yaslar.join("/")} yaşlarına canlı ulaşan bir hayat '
              'bulunamadı. Dökülecek bir şey yok.');

      final List<String> bosEkranlar = <String>[];
      for (final int yas in yaslar) {
        // Yukarıdaki iddia geçtiyse her hedef yaşın canlı karesi var;
        // eskiden ulaşılmayan yaş sessizce atlanıyordu.
        final GameState durum = kareler[yas]!;
        bosEkranlar.addAll(
          await dok(
          tester,
          '${arketip.label} · $yas yaş · tohum ${hayat.tohum}',
          durum,
        ),
        );
      }

      expect(bosEkranlar, isEmpty,
          reason: 'Şu ekranlar neredeyse boş: ${bosEkranlar.join(", ")}. '
              'Boş ekran oyuncuya hiçbir şey anlatmaz (D-063).');
    });
  }
}
