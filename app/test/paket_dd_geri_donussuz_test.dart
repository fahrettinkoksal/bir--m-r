// Paket DD — geri dönüşsüz kararların taraması.
//
// **Neden tarandı.** Paket DC'de çıkan hata bir sınıfın örneğiydi:
// okulu bırakmak 30 işi **ömür boyu** kapatıyordu ve kapıyı kimse
// bilerek kapatmamıştı — geri dönüş yolu yazılmamıştı, o kadar. Aynı
// soruyu bütün kalıcı durumlara sordum: **"bunu geri alan bir yol var
// mı, yoksa yalnızca ekran mı kapatıyor?"**
//
// | Kalıcı durum | Motor ne diyor | Ekran ne yapıyor | Hüküm |
// |---|---|---|---|
// | Diploma yok (`droppedOut`) | 13 işe izin | 0 satır | Paket DC'de düzeltildi |
// | "Üniversiteye gitmedim" izi | **88/88 hayatta en az bir bölüme izin** | satır ömür boyu gizli | **HATA — bu paket** |
// | Emekli (`isRetired`) | 20/55 işe izin verir | iş arama satırı gizli | Kuyrukta (**Q-237**): emekli maaşı + maaş sömürüsü riski var, tek başıma açmıyorum |
// | İşletme kapanmış | yeni işletme kurulabilir | satır açık | Sorun yok |
//
// **Ölçüm (197 hayat, 32 yaşında bakıldı).** 88 hayatta (%45)
// `universiteye_gitmedi` izi var, lise diploması var, üniversite kaydı
// yok. `EducationPath.eligibilityReason` o izi **hiç okumuyor**: 88'in
// hepsinde en az bir bölüm uygun (örneklerde 20/20 puanı 93 olan bir
// hayat da var). Ama ekran üniversite kapısını karar kilidine
// (`needsAfterSchoolChoice`) bağlıyordu ve o kilit izi okuyor — yani
// 18'inde "gitmeyeceğim" diyen oyuncu bir daha hiç başvuramıyordu.
// Her birine 11-13 iş "Üniversite mezuniyeti gerekiyor." diye kapalı
// kalıyordu.
//
// **Önceki düzeltmeyle gerilim ve çözümü.** Aynı dosyada kayıtlı bir
// düzeltme var: satır eskiden `awaitingAfterSchoolChoice`'a bağlıydı ve
// 35/55/70 yaşındaki oyuncuya "Mezuniyet sonrası" diye **bayat**
// duruyordu. O düzeltme yerinde duruyor: karar satırı yine karar
// kilidine bağlı. Yeni satır ayrı ve adı eylemin kendisi
// ("Üniversiteye başvur"), çerçeve değil.
library;

import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/data/job_catalog.dart';
import 'package:bir_omur/data/university_catalog.dart';
import 'package:bir_omur/domain/career/job_market.dart';
import 'package:bir_omur/domain/education/education_path.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/player_bot.dart';

/// Ekranın gerçekten açılabildiği **sessiz** kare mi?
///
/// Paket DE'de öğrenildi: aranan karede bekleyen bir iş varsa (kriz,
/// duruşma, mülakat, düğün, yarış, ehliyet sınavı ya da lise alanı
/// seçimi) uygulama bir alt sayfa açıyor ve sekme düğmesi tıklanamıyor
/// hâle geliyor. Oyuncu da o karede meslek ekranına bakmıyor; önce
/// bekleyen işi kapatıyor.
///
/// **Kanca da bu yüzden `onPreAge`** (Paket CR'nin ayrımı): `onYear`
/// yılın olayı henüz cevaplanmadan çalışıyor, yani orada
/// `hasPendingEvent` neredeyse her zaman doluydu ve bu süzgeç hiçbir
/// kare bırakmıyordu. `onPreAge` bütün bekleyen işler kapandıktan
/// sonra, yaş almadan önce çalışır — oyuncunun ekranlara baktığı an.
bool _sessizKare(GameState s) =>
    !s.hasPendingEvent &&
    !s.hasPendingCrisis &&
    !s.hasPendingTrial &&
    !s.hasPendingInterview &&
    !s.hasPendingWedding &&
    !s.hasPendingRace &&
    !s.hasPendingLicenseExam &&
    !s.education.awaitingTrackChoice &&
    !s.deceased;

/// "Üniversiteye gitmedim" demiş, lise mezunu, üniversite kaydı olmayan
/// bir kare **arar**. Kurulmaz.
GameState? _kararVermisAra({int enAzYas = 24, int tohumSayisi = 25}) {
  for (final PlayerArchetype a in PlayerArchetype.values) {
    for (int i = 0; i < tohumSayisi; i++) {
      GameState? bulunan;
      playBotLife(
        archetype: a,
        seed: 51000 + a.index * 811 + i * 37,
        onPreAge: (GameState s) {
          if (bulunan != null) return;
          if (s.player.age >= enAzYas &&
              _sessizKare(s) &&
              s.storyFlags.contains(EducationPath.universiteyeGitmediFlag) &&
              s.education.finished &&
              s.education.universityProgramId == null &&
              !s.education.universityFinished) {
            bulunan = s;
          }
        },
      );
      if (bulunan != null) return bulunan;
    }
  }
  return null;
}

void main() {
  test('§1 motor "gitmedim" izini hiç okumuyor; kapı açık', () {
    final GameState? s = _kararVermisAra();
    expect(s, isNotNull, reason: 'Kararı vermiş hayat bulunamadı.');
    const EducationPath yol = EducationPath();

    // Karar kilidi kapalı: soru sorulmuyor (D-111 yerinde).
    expect(EducationPath.needsAfterSchoolChoice(s!), isFalse);
    // Ama kapı açık: motor en az bir bölüme izin veriyor.
    final List<UniversityProgram> acik = yol.availablePrograms(s);
    expect(acik, isNotEmpty,
        reason: 'availablePrograms izi okumamalı; boş döndü.');
    final List<UniversityProgram> uygun = acik
        .where((UniversityProgram p) => yol.eligibilityReason(s, p).isEmpty)
        .toList();
    expect(uygun, isNotEmpty,
        reason: 'Motorun uygun bulduğu bölüm yok; ölçümde 88/88 vardı.');
    expect(EducationPath.canApplyToUniversity(s), isTrue);

    // Kapalı kalan işler gerçekten üniversite istiyor.
    const JobMarket pazar = JobMarket();
    final int uniIsi = kJobCatalog
        .where((JobType j) =>
            pazar.requirementReason(s, j) ==
            'Üniversite mezuniyeti gerekiyor.')
        .length;
    expect(uniIsi, greaterThanOrEqualTo(8),
        reason: 'Ölçümde 11-13 iş kapalıydı; şimdi $uniIsi.');
  });

  test('§2 kararı vermemiş oyuncuda iki yüklem de doğru', () {
    // Lise yeni bitmiş, karar henüz verilmemiş bir kare ara.
    //
    // **Kanca bilerek `onYear`** (§1/§4'ten farklı): karar bekliyor
    // olmak bir **kilittir** ve bot onu yaş almadan önce kapatıyor,
    // yani `onPreAge` karelerinde hiç görünmüyor. Bu test ekran
    // sürmüyor, yalnızca iki yüklemi karşılaştırıyor; bekleyen olayın
    // açık olması sorun değil.
    GameState? yeniMezun;
    for (final PlayerArchetype a in PlayerArchetype.values) {
      for (int i = 0; i < 15 && yeniMezun == null; i++) {
        playBotLife(
          archetype: a,
          seed: 51000 + a.index * 811 + i * 37,
          onYear: (GameState s) {
            if (yeniMezun == null &&
                EducationPath.needsAfterSchoolChoice(s)) {
              yeniMezun = s;
            }
          },
        );
      }
    }
    expect(yeniMezun, isNotNull);
    // Karar bekliyor **ve** kapı açık: ikisi birlikte de olabilir.
    expect(EducationPath.needsAfterSchoolChoice(yeniMezun!), isTrue);
    expect(EducationPath.canApplyToUniversity(yeniMezun!), isTrue);
  });

  test('§3 üniversiteye kaydolan ya da bitiren için kapı kapanır', () {
    GameState? kayitli;
    GameState? mezun;
    for (final PlayerArchetype a in PlayerArchetype.values) {
      for (int i = 0; i < 15; i++) {
        playBotLife(
          archetype: a,
          seed: 51000 + a.index * 811 + i * 37,
          onPreAge: (GameState s) {
            if (kayitli == null && s.education.isUniversityStudent) {
              kayitli = s;
            }
            if (mezun == null && s.education.universityFinished) mezun = s;
          },
        );
        if (kayitli != null && mezun != null) break;
      }
      if (kayitli != null && mezun != null) break;
    }
    expect(kayitli, isNotNull);
    expect(mezun, isNotNull);
    // Zaten okuyan ya da bitirmiş olana "başvur" denmez.
    expect(EducationPath.canApplyToUniversity(kayitli!), isFalse);
    expect(EducationPath.canApplyToUniversity(mezun!), isFalse);
  });

  testWidgets('§4 ekran kararı vermiş oyuncuya başvuru yolunu gösteriyor',
      (WidgetTester tester) async {
    final GameState? bulunan = _kararVermisAra();
    expect(bulunan, isNotNull);

    final GameController controller = GameController(random: Random(3));
    addTearDown(controller.dispose);
    tester.view.physicalSize = const Size(1200, 6400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(BirOmurApp(controller: controller));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rastgele bir hayat'));
    await tester.pumpAndSettle();
    controller.debugSetState(bulunan!.copyWith(pendingEvent: null));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tab_okul_meslek')));
    await tester.pumpAndSettle();

    // **Kaydırma gerekiyor (Paket DE'de öğrenildi).** Meslek ekranı
    // uzun ve liste tembel kuruluyor: aranan kare çalışan ya da
    // işletme sahibi bir oyuncuysa satır görüş alanının altına düşüyor
    // ve `find.byKey` onu bulamıyor. Paket DE 22 olay ekleyip zar
    // akışını kaydırınca aranan kare değişti ve bu test o yüzden
    // kırmızıya döndü — iddia doğruydu, **arama yöntemi** eksikti.
    final Finder satir = find.byKey(const Key('career_universiteye_basvur'));
    if (satir.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        satir,
        300,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 60,
      );
      await tester.pumpAndSettle();
    }

    // ISIRMA DENEMESİ: eski hâlde bu satır hiç kurulmuyordu (kapı
    // karar kilidine bağlıydı ve kilit "gitmedim" izini okuyor).
    expect(
      satir,
      findsOneWidget,
      reason: 'Kararı vermiş oyuncu üniversite başvuru yolunu görmüyor; '
          'kapı yine karar kilidine bağlanmış.',
    );
    // Önceki düzeltme yerinde: bayat "Mezuniyet sonrası" çerçevesi
    // kararı vermiş oyuncuya gösterilmiyor.
    expect(find.text('Mezuniyet sonrası'), findsNothing);
    // Yüklem de doğrudan denetlenir: ekran kaydırmasından bağımsız.
    expect(EducationPath.canApplyToUniversity(controller.state!), isTrue);
    expect(
      EducationPath.needsAfterSchoolChoice(controller.state!),
      isFalse,
    );

    // Satır gerçekten başvuru ekranını açıyor ve bölüm listesi geliyor.
    //
    // Not: "iş hayatına gir" düğmesi (`after_school_skip`) 20 bölüm
    // kartının altında ve liste tembel kuruluyor, yani kaydırılmadan
    // ağaçta olmuyor. Bu yüzden iddia listenin **başlığına** bakar;
    // düğmenin kendisi `after_school_widget_test.dart`'ın konusu.
    await tester.tap(find.byKey(const Key('career_universiteye_basvur')));
    await tester.pumpAndSettle();
    expect(find.text('Mezuniyet sonrası'), findsWidgets);
    expect(
      find.text('Üniversite başvurusu'),
      findsOneWidget,
      reason: 'Başvuru ekranı açıldı ama bölüm listesi yok.',
    );
  });
}
