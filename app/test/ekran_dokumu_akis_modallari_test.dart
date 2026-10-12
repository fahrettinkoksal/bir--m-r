// Ekran dökümü, onuncu tur: **akış içi modallar**.
//
// **Neden var.** Paket DS modal kapsam kaydını denetlenir hâle getirdi
// ve kuyrukta üç dosya kaldı: `notice_sheet.dart` (13 cümle),
// `license_exam_sheet.dart` (8), `track_choice_sheet.dart` (8). Üçü de
// ekranda bir satırın arkasında değil, **bir akışın ortasında**
// açılıyor; bölüm ve modal dökümlerinin "temiz kare + yol" kalıbına
// girmiyorlar.
//
// **Kapılar ölçüldü** (8 arketip × 10 tohum, `onYear` + `onPreAge` +
// `onPending`):
//
//   lise alanı seçimi bekliyor   359 kare
//   cenaze bildirimi             887 kare
//   doğum bildirimi (ad verme)   179 kare
//   ehliyet sınavı bekliyor        **0 kare**
//
// Son satır bir **araç bulgusu**, ürün hatası değil: ehliyet sınavı
// başvuruyla aynı adımda çözülüyor, bu yüzden hiçbir kanca onu
// "bekliyor" hâlinde göremiyor (Paket CR'nin ölçtüğü kör noktanın aynısı).
// Oyun günlüğünde sınav satırları bolca var ("Motosiklet ehliyeti
// sınavını geçemedin: 0/3 doğru"), yani akış çalışıyor. O kare bu
// yüzden **oynanarak** açılıyor: döküm Aktiviteler → Ehliyet
// İşlemleri'ne gidip başvuruyor. Durum kurmak değil, oyunu arayüzden
// oynamak (`ekran_dokumu_test.dart`ın kalıbı).
//
// **Durum kurulmuyor, aranıyor.** Üç kapı bot hayatlarından bulunuyor;
// bulunamazsa test "BULUNAMADI" yazar ve geçer — bulunamamak ürün
// hatası değil, ama "okundu" da sayılmaz.
library;

import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/data/license_catalog.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/player_bot.dart';
import 'support/section_pages.dart';
import 'support/test_flow.dart';

void main() {
  /// Bütün karelerin basılan metni; kapsam kaydı bunun üzerinde
  /// denetleniyor (Paket DS'nin `modalKapsamDenetle` kalıbı).
  final List<String> basilan = <String>[];

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

  void bas(String ad, GameState durum, List<String> ekran) {
    basilan.addAll(ekran);
    // ignore: avoid_print
    print('\n${'=' * 68}\nAKIŞ MODALI · $ad · ${durum.player.age} yaş · '
        '${ekran.length} metin\n${'=' * 68}');
    // ignore: avoid_print
    print(ekran.map((String t) => '   $t').join('\n'));
  }

  /// Bildirim kuyruğunu **hedefe kadar** yürütür.
  ///
  /// **Ölçülen tuzak (Paket DT).** `home_shell` her karede yalnızca
  /// `state.nextNotice`i (yani kuyruğun **ilk** öğesini) gösteriyor.
  /// Aradığım kare kuyruğun ortasında olabiliyor: bulunan hayatta
  /// kuyruk şöyleydi —
  ///
  ///   aileDonum/Bir hedefe ulaştın | olum/Bir kaybın var |
  ///   **cenaze/Cenaze masrafları** | miras/Miras |
  ///   aileDonum/Miras anlaşmazlığı
  ///
  /// İlk yazımda "pencere açılmadı" diye rapor edecektim; pencere
  /// açılıyordu, **başka bir bildirimi** gösteriyordu. Oyuncu da aynı
  /// şeyi yapar: sırayla kapatır. Döngü kaç pencere kapattığını yazar.
  Future<int> hedefeKadarKapat(WidgetTester tester, Finder hedef) async {
    int kapatilan = 0;
    for (int i = 0; i < 12; i++) {
      if (hedef.evaluate().isNotEmpty) return kapatilan;
      final Finder kapat = find.byKey(const Key('notice_close'));
      if (kapat.evaluate().isEmpty) return kapatilan;
      await tester.tap(kapat.first, warnIfMissed: false);
      await tester.pumpAndSettle();
      kapatilan++;
    }
    return kapatilan;
  }

  /// **Durum kurulmuyor, aranıyor.**
  GameState? kareBul(bool Function(GameState) kosul, {int tohumSayisi = 10}) {
    GameState? bulunan;
    for (final PlayerArchetype a in PlayerArchetype.values) {
      for (int tohum = 0; tohum < tohumSayisi; tohum++) {
        if (bulunan != null) return bulunan;
        void bak(GameState s) {
          if (bulunan != null || s.deceased) return;
          if (kosul(s)) bulunan = s;
        }

        playBotLife(
          archetype: a,
          seed: 80000 + tohum,
          onYear: bak,
          onPreAge: bak,
          onPending: bak,
        );
      }
    }
    return bulunan;
  }

  Future<GameController> uygulamaAc(
    WidgetTester tester,
    GameState? durum,
  ) async {
    tester.view.physicalSize = const Size(1200, 14000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final GameController controller = GameController(random: Random(53));
    addTearDown(controller.dispose);
    await tester.pumpWidget(BirOmurApp(controller: controller));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rastgele bir hayat'));
    await tester.pumpAndSettle();
    if (durum != null) {
      controller.debugSetState(durum);
      await tester.pumpAndSettle();
    }
    return controller;
  }

  testWidgets('AKIŞ MODALI — lise alanı seçimi', (WidgetTester tester) async {
    // **Süzgeç iki kez ölçümle düzeltildi.**
    //
    // 1. İlk yazımda "temiz kare" koşulu (`!hasNotice`) vardı ve kare
    //    BULUNAMADI çıkıyordu — oysa bot taraması 359 kare ölçmüştü.
    // 2. Bildirim koşulunu kaldırdım, yine BULUNAMADI. Ölçtüm:
    //
    //      alan seçimi karesi 359 · **olaysız 0** · krizsiz 359 ·
    //      bildirimsiz 100
    //
    //    Yani `awaitingTrackChoice`in açık olduğu her karede bekleyen
    //    bir **olay** da var. Sebebi yapısal: alan seçimi `ageUp`in
    //    beş kapısından biri (D-094), bot onu gördüğü anda yanıtlıyor
    //    ve kare yalnızca `onPending` kancasında — yani oyuncunun
    //    yılın başındaki şeyleri yanıtlamadığı anda — görünüyor.
    //
    // Çözüm durumu kurmak değil, **oynamak**: bekleyen olay ve
    // bildirimler arayüzden yanıtlanıyor (`answerPendingEvents`,
    // oyuncunun yaptığının aynısı). Alan seçimi bunlarla kapanmıyor,
    // kendi kapısı ayrı.
    final GameState? durum = kareBul(
      (GameState s) => s.education.awaitingTrackChoice,
    );
    if (durum == null) {
      // ignore: avoid_print
      print('\nLİSE ALANI SEÇİMİ: BULUNAMADI (kapı '
          '`education.awaitingTrackChoice`).');
      return;
    }
    final GameController controller = await uygulamaAc(tester, durum);
    await answerPendingEvents(tester, controller);
    // ignore: avoid_print
    print('LİSE ALANI SEÇİMİ · bekleyenler yanıtlandı · alan seçimi '
        'hâlâ açık: ${controller.state!.education.awaitingTrackChoice}');
    expect(
      controller.state!.education.awaitingTrackChoice,
      isTrue,
      reason: 'Bekleyenleri yanıtlamak alan seçimini de kapatmış; kare '
          'bu yolla okunamaz.',
    );
    await tester.tap(find.byKey(const Key('tab_okul_meslek')));
    await tester.pumpAndSettle();

    final Finder satir = find.byKey(const Key('school_track_choice_row'));
    expect(
      satir,
      findsOneWidget,
      reason: 'Alan seçimi bekleyen oyuncunun ekranında "Lise alanını '
          'seç" satırı yok:\n${metinler(tester).join("\n")}',
    );
    await tester.ensureVisible(satir);
    await tester.pumpAndSettle();
    await tester.tap(satir);
    await tester.pumpAndSettle();

    final List<String> ekran = metinler(tester);
    bas('LİSE ALANI SEÇİMİ', durum, ekran);

    // **İşaret:** pencerenin kendi uyarısı (geri dönüşsüz karar).
    expect(
      ekran.any((String t) => t.contains('seçtiğin alan eğitim')),
      isTrue,
      reason: 'Alan seçimi penceresi açılmadı:\n${ekran.join("\n")}',
    );
    // Seçenek kartları gerçekten var mı? Puanı yetmeyen de yazılı olmalı.
    expect(
      find.byKey(const Key('track_choice_title')),
      findsOneWidget,
      reason: 'Pencere başlığı yok.',
    );
  });

  testWidgets('AKIŞ MODALI — cenaze bildirimi (iki adım)',
      (WidgetTester tester) async {
    final GameState? durum = kareBul(
      (GameState s) => s.notices.any(
        (PendingNotice n) => n.kind == NoticeKind.cenaze,
      ),
    );
    if (durum == null) {
      // ignore: avoid_print
      print('\nCENAZE BİLDİRİMİ: BULUNAMADI (kapı `NoticeKind.cenaze`).');
      return;
    }
    await uygulamaAc(tester, durum);
    final int kapanan = await hedefeKadarKapat(
      tester,
      find.byKey(const Key('funeral_attend_katildi')),
    );
    // ignore: avoid_print
    print('CENAZE · kuyrukta $kapanan bildirim kapatıldı · kuyruk: '
        '${durum.notices.map((PendingNotice n) => n.kind.name).join(" | ")}');

    final List<String> birinci = metinler(tester);
    bas('CENAZE BİLDİRİMİ · 1. adım (katılım)', durum, birinci);
    expect(
      birinci.any((String t) => t.contains('Cenazeye katıl')),
      isTrue,
      reason: 'Cenaze penceresi açılmadı:\n${birinci.join("\n")}',
    );
    // D-050: akış iki adımlı ve ikisi **ayrı ayrı** seçiliyor.
    expect(
      birinci.any(
        (String t) => t.contains('ikisini de ayrı ayrı seçeceksin'),
      ),
      isTrue,
      reason: 'İki adımlı olduğunu söyleyen cümle yok.',
    );
    // **Paket DT'nin bulduğu kusur, bekçisi burada.** Birinci adımda
    // metin oyuncunun yerine karar vermiş olmaz: düğmeler hâlâ
    // katılımı soruyorken "Cenazeye katılıyorsun" yazamaz.
    expect(
      birinci.where((String t) => t.contains('Cenazeye katılıyorsun')),
      isEmpty,
      reason: 'Katılım daha sorulmamışken metin katıldığını söylüyor; '
          'altındaki iki düğme ile çelişiyor:\n${birinci.join("\n")}',
    );

    await tester.tap(find.byKey(const Key('funeral_attend_katildi')));
    await tester.pumpAndSettle();
    final List<String> ikinci = metinler(tester);
    bas('CENAZE BİLDİRİMİ · 2. adım (katkı)', durum, ikinci);
    expect(
      ikinci.any((String t) => t.contains('Katkı bir borç değildir')),
      isTrue,
      reason: 'Katkı adımı açılmadı:\n${ikinci.join("\n")}',
    );
    // İkinci adımda katkı sorusu **bir kez** yazılır. Eskiden bildirim
    // metni de aynı soruyu taşıyordu ve ekranda iki kez duruyordu.
    expect(
      ikinci
          .where((String t) => t.contains('katkıda bulunmak ister misin'))
          .length,
      1,
      reason: 'Katkı sorusu ekranda bir kezden fazla yazılıyor:\n'
          '${ikinci.where((String t) => t.contains("katkıda bulunmak")).join("\n")}',
    );
  });

  testWidgets('AKIŞ MODALI — bebeğe ad verme', (WidgetTester tester) async {
    final GameState? durum = kareBul(
      (GameState s) => s.notices.any(
        (PendingNotice n) => n.kind == NoticeKind.dogum,
      ),
    );
    if (durum == null) {
      // ignore: avoid_print
      print('\nBEBEĞE AD VERME: BULUNAMADI (kapı `NoticeKind.dogum`).');
      return;
    }
    await uygulamaAc(tester, durum);
    // Bulunan karede doğum bildirimi şans eseri kuyruğun başındaydı;
    // güvenmeyip yürütüyoruz (cenazede tam bu yüzden düşmüştü).
    final int kapanan = await hedefeKadarKapat(
      tester,
      find.byKey(const Key('birth_name_field')),
    );
    // ignore: avoid_print
    print('DOĞUM · kuyrukta $kapanan bildirim kapatıldı');

    final List<String> ekran = metinler(tester);
    bas('BEBEĞE AD VERME', durum, ekran);
    expect(
      ekran.any((String t) => t.contains('Bebeğin adını sen koyabilirsin')),
      isTrue,
      reason: 'Doğum bildiriminde ad verme alanı yok:\n'
          '${ekran.join("\n")}',
    );
    expect(
      find.byKey(const Key('birth_name_field')),
      findsOneWidget,
      reason: 'Ad alanı çizilmemiş.',
    );
  });

  testWidgets('AKIŞ MODALI — ehliyet sınavı (oynanarak açılıyor)',
      (WidgetTester tester) async {
    // **Bu kare aranmıyor, oynanıyor.** Ölçüm: `hasPendingLicenseExam`
    // bot taramasında 0 kare — sınav başvuruyla aynı adımda çözülüyor.
    // Bu yüzden döküm başvuruyu kendisi yapıyor.
    //
    // Aranan tek şey **başvurabilecek** bir kare: yaşı yeten, parası
    // olan, ehliyeti olmayan ve temiz ekranlı bir oyuncu.
    final int enKucukYas = LicenseType.motosiklet.prototypeOnlyMinAge;
    final GameState? durum = kareBul(
      (GameState s) =>
          s.player.age >= enKucukYas &&
          s.licenses.isEmpty &&
          !s.hasPendingLicenseExam &&
          s.player.wallet > 100000 &&
          !s.hasNotice &&
          s.pendingEvent == null &&
          !s.hasPendingCrisis &&
          !s.isImprisoned,
      tohumSayisi: 14,
    );
    if (durum == null) {
      // ignore: avoid_print
      print('\nEHLİYET SINAVI: başvurabilecek kare BULUNAMADI '
          '($enKucukYas yaş+, ehliyetsiz, parası olan).');
      return;
    }
    await uygulamaAc(tester, durum);
    await hedefeKadarKapat(tester, find.byKey(const Key('tab_aktiviteler')));
    await tester.tap(find.byKey(const Key('tab_aktiviteler')));
    await tester.pumpAndSettle();

    final Finder ehliyet = find.byKey(const Key('aktivite_ehliyet'));
    expect(
      ehliyet,
      findsOneWidget,
      reason: '${durum.player.age} yaşındaki oyuncunun Aktiviteler '
          'ekranında "Ehliyet İşlemleri" satırı yok.',
    );
    await scrollToFinder(tester, ehliyet);
    await tester.tap(ehliyet);
    await tester.pumpAndSettle();

    final Finder basvur =
        find.byKey(Key('license_apply_${LicenseType.motosiklet.name}'));
    expect(
      basvur,
      findsOneWidget,
      reason: 'Motosiklet ehliyeti başvuru düğmesi yok:\n'
          '${metinler(tester).join("\n")}',
    );
    await scrollToFinder(tester, basvur);
    await tester.tap(basvur);
    await tester.pumpAndSettle();

    final List<String> ekran = metinler(tester);
    bas('EHLİYET SINAVI', durum, ekran);
    expect(
      ekran.any((String t) => t.contains('Geçmek için en az')),
      isTrue,
      reason: 'Sınav penceresi açılmadı. Düğme kapalı olabilir ya da '
          'başvuru reddedilmiş olabilir — yukarıdaki dökümü oku:\n'
          '${ekran.join("\n")}',
    );
  });

  tearDownAll(() {
    // **Kapsam kaydı bu dökümün üzerine kurulu (Paket DS kalıbı).**
    // `kModalBaskaTestle` dört dosya için "karesi bu döküm tarafından
    // basılıyor" diyor; iddiayı basan taraf doğruluyor.
    modalKapsamDenetle('ekran_dokumu_akis_modallari_test.dart', basilan);
  });
}
