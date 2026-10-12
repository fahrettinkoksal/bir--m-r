// Paket DC — okulu bırakanın ikinci şansı.
//
// **Nasıl bulundu.** Gebelik karesi okunurken (ekran dökümü, Riskli
// hayat tohum 4, yaş 35): karakter 18 yıldır aynı yarım zamanlı çıraklık
// işinde, yıllık maaşı 336.552 ₺, ve ekranın altında şu yazıyor —
// "Yarım zamanlı iş 16 yaşında, tam zamanlı iş liseyi bitirdikten sonra
// açılır." İş arama satırı hiç yok. Kayıttaki tek sebep: okulu bırakmış.
//
// **Ölçüm 1 — katalog (55 iş).** `JobEducation.yok` 25, `lise` 17,
// `universite` 13. Yani diplomasıza kataloğun **30 işi** kapalı.
//
// **Ölçüm 2 — bulunan durum.** 236 hayat 30 yaşında tarandı; diplomasız
// yetişkin 4 hayatta çıktı (%1,7), dördü de üç yıl sınıfta kaldıktan
// sonra ayrılmış. Bunlardan biri (investor, tohum 32504, yaş 30)
// alınıp motora soruldu:
//
// | | motor (`requirementReason`) | ekran (eski `isAranabilir`) |
// |---|---|---|
// | 30 yaş, okulu bırakmış | **13 işe izin** (6'sı tam zamanlı) | **0 satır** |
//
// Motorun engellediği 42 işin gerekçeleri de kendi kuralından geliyordu:
// "Lise mezuniyeti gerekiyor." ×17, "Üniversite mezuniyeti gerekiyor."
// ×13, ehliyet ×2, kuşak ×2, eğitim geçmişi ×1.
//
// **Sınıflandırma.** Kusur **yalnızca ekranda** ve bu yüzden hiçbir bot
// ölçümü onu göremezdi: bot `applyForJob`'u doğrudan çağırıyor,
// `isAranabilir`'den geçmiyor. Paket CT/CU'nun dersi burada da geçerli —
// ekranı okumadan bu bulunmuyor.
//
// §1 ekranın motorla çelişmesini kapatır, §2-§5 açık liseyi (dönüş
// yolunu) denetler.
library;

import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/data/job_catalog.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/domain/career/job_market.dart';
import 'package:bir_omur/domain/education/open_high_school.dart';
import 'package:bir_omur/domain/features/feature_catalog.dart';
import 'package:bir_omur/domain/generation/life_progression.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/life_log.dart';
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

/// Diplomasız, öğrenci olmayan bir yetişkin durumu **arar**.
///
/// Kurulmaz: bot hayatları taranır ve ilk uyan kare alınır. Kapı
/// değişirse bu arama da değişir; sabitlenmiş bir tohuma bağlı kalmaz.
GameState? _diplomasizYetiskinAra({int enAzYas = 25, int tohumSayisi = 60}) {
  for (final PlayerArchetype a in PlayerArchetype.values) {
    for (int i = 0; i < tohumSayisi; i++) {
      GameState? bulunan;
      playBotLife(
        archetype: a,
        seed: 31000 + a.index * 977 + i * 31,
        onPreAge: (GameState s) {
          if (bulunan != null) return;
          if (s.player.age >= enAzYas &&
              _sessizKare(s) &&
              !s.education.finished &&
              !s.education.universityFinished &&
              !s.education.isStudent) {
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
  // ——————————————————————————————————————————————————————————————
  // §1 — Ekran motorla çelişmesin.
  // ——————————————————————————————————————————————————————————————

  test('§1a motor diplomasız yetişkine en az bir iş açıyor', () {
    final GameState? s = _diplomasizYetiskinAra();
    expect(s, isNotNull, reason: 'Diplomasız yetişkin hayat bulunamadı.');
    const JobMarket pazar = JobMarket();
    final List<JobType> izinli = kJobCatalog
        .where((JobType j) => pazar.requirementReason(s!, j).isEmpty)
        .toList();
    final List<JobType> tamZamanli =
        izinli.where((JobType j) => !j.partTime).toList();

    // Ölçümde 13 / 6 çıktı. Taban ölçümün altında tutulur.
    expect(
      izinli.length,
      greaterThanOrEqualTo(6),
      reason: 'Motorun diplomasıza açtığı iş sayısı düştü: '
          '${izinli.length} (ölçüm 13).',
    );
    expect(
      tamZamanli.length,
      greaterThanOrEqualTo(3),
      reason: 'Diplomasıza açık tam zamanlı iş kalmadı: '
          '${tamZamanli.length} (ölçüm 6). Ekranın eski gerekçesi '
          '("tam zamanlı iş liseyi bitirdikten sonra açılır") hâlâ '
          'yanlış olmalı ki §1b anlamlı olsun.',
    );

    // Katalog kırılımı: kapalı kalan 30 iş bu paketin konusu.
    final int liseIsteyen = kJobCatalog
        .where((JobType j) => j.education == JobEducation.lise)
        .length;
    expect(liseIsteyen, greaterThanOrEqualTo(10),
        reason: 'Lise diploması isteyen iş sayısı ölçümde 17 idi.');
  });

  testWidgets('§1b ekran diplomasız yetişkiye iş arama yolunu gösteriyor',
      (WidgetTester tester) async {
    final GameState? bulunan = _diplomasizYetiskinAra();
    expect(bulunan, isNotNull);
    // İş arama satırı "İş değiştir" değil "İş ara" olsun diye işsiz
    // kare aranır; bulunamazsa mevcut iş bırakılır (motorun kendi yolu).
    GameState s = bulunan!;
    if (s.career.isEmployed) {
      s = s.copyWith(career: s.career.copyWith(jobId: null));
    }

    final GameController controller = GameController(random: Random(7));
    addTearDown(controller.dispose);
    tester.view.physicalSize = const Size(1200, 6400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(BirOmurApp(controller: controller));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rastgele bir hayat'));
    await tester.pumpAndSettle();
    controller.debugSetState(s.copyWith(pendingEvent: null));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tab_okul_meslek')));
    await tester.pumpAndSettle();

    // ISIRMA DENEMESİ: eski koşul (`finished || universityFinished ||
    // öğrenci`) bu karede üçünü de sağlamıyordu, yani satır yoktu ve
    // aşağıdaki iddia **başarısız olurdu**.
    expect(
      find.text('İş ara'),
      findsOneWidget,
      reason: 'Diplomasız yetişkin iş arama satırını görmüyor; '
          'ekran yine motordan ayrı bir kapı kurmuş.',
    );
    // Ve artık motorun kuralı olmayan gerekçe yazılmıyor.
    expect(
      find.textContaining('tam zamanlı iş liseyi bitirdikten sonra'),
      findsNothing,
    );
  });

  // ——————————————————————————————————————————————————————————————
  // §2 — Açık lise: kayıt, ilerleme, diploma.
  // ——————————————————————————————————————————————————————————————

  test('§2a kayıt bulunan durumdan açılıyor ve bırakılan sınıftan devam',
      () {
    final GameState? bulunan = _diplomasizYetiskinAra();
    expect(bulunan, isNotNull);
    final GameState s = bulunan!.copyWith(
      player: bulunan.player.copyWith(
        wallet: OpenHighSchool.prototypeOnlyYearlyFee * 6,
      ),
    );
    expect(OpenHighSchool.enrollAvailability(s).isAllowed, isTrue,
        reason: OpenHighSchool.enrollAvailability(s).reason ?? '');

    final ({GameState state, String text})? sonuc = OpenHighSchool.enroll(s);
    expect(sonuc, isNotNull);
    final GameState kayitli = sonuc!.state;
    expect(kayitli.education.isOpenHighSchoolStudent, isTrue);
    expect(
      kayitli.education.openHighSchoolGrade,
      OpenHighSchool.startGrade(s),
    );
    expect(
      kayitli.education.openHighSchoolGrade,
      greaterThanOrEqualTo(OpenHighSchool.prototypeOnlyFirstGrade),
    );
    // Kayıt hayat günlüğüne yazılır: sessiz değişiklik yok.
    expect(kayitli.log.last.text, contains('Açık lise'));
    // **Kritik:** açık lise öğrencisi okul öğrencisi sayılmaz, yoksa
    // tam zamanlı iş kapısı (D-131) kapanırdı.
    expect(kayitli.education.isSchoolStudent, isFalse);
    const JobMarket pazar = JobMarket();
    final JobType tamZamanli = kJobCatalog.firstWhere(
      (JobType j) => !j.partTime && j.education == JobEducation.yok,
    );
    expect(
      pazar.requirementReason(kayitli, tamZamanli),
      isNot(contains('Okula devam ederken')),
    );
  });

  test('§2b yıllar ilerliyor, ücret çıkıyor ve diploma geliyor', () {
    final GameState? bulunan = _diplomasizYetiskinAra();
    expect(bulunan, isNotNull);
    final GameState s = bulunan!.copyWith(
      player: bulunan.player.copyWith(
        wallet: OpenHighSchool.prototypeOnlyYearlyFee * 10,
      ),
    );
    GameState kayitli = OpenHighSchool.enroll(s)!.state;
    final int baslangicSinif = kayitli.education.openHighSchoolGrade!;
    final int beklenenYil =
        OpenHighSchool.prototypeOnlyLastGrade - baslangicSinif + 1;
    int cuzdan = kayitli.player.wallet;

    int yil = 0;
    while (!kayitli.education.finished && yil < 8) {
      final ({GameState state, List<String> logLines}) adim =
          OpenHighSchool.advanceYear(kayitli);
      kayitli = adim.state;
      expect(adim.logLines, isNotEmpty,
          reason: 'Açık lise yılı sessiz geçti.');
      expect(
        kayitli.player.wallet,
        cuzdan - OpenHighSchool.prototypeOnlyYearlyFee,
        reason: 'Yıllık ücret cüzdandan çıkmadı.',
      );
      cuzdan = kayitli.player.wallet;
      yil++;
    }

    expect(yil, beklenenYil,
        reason: 'Diploma $beklenenYil yılda alınmalıydı, $yil sürdü.');
    expect(kayitli.education.finished, isTrue);
    expect(kayitli.education.isOpenHighSchoolStudent, isFalse,
        reason: 'Diploma alındıktan sonra kayıt kapanmalı.');
    // Geçmiş silinmiyor: okulu bırakmış olmak kayıtta duruyor.
    expect(kayitli.education.droppedOut, bulunan.education.droppedOut);

    // Kapanan 17 iş gerçekten açıldı mı? "Lise mezuniyeti gerekiyor."
    // gerekçesi artık hiçbir işte çıkmamalı.
    const JobMarket pazar = JobMarket();
    final List<JobType> liseIsteyen = kJobCatalog
        .where((JobType j) => j.education == JobEducation.lise)
        .toList();
    for (final JobType j in liseIsteyen) {
      expect(
        pazar.requirementReason(kayitli, j),
        isNot(contains('Lise mezuniyeti gerekiyor')),
        reason: '${j.name} diploma sonrası hâlâ diploma istiyor.',
      );
    }
  });

  test('§2c ücret ödenemezse sınıf ilerlemez, kayıt da düşmez', () {
    final GameState? bulunan = _diplomasizYetiskinAra();
    expect(bulunan, isNotNull);
    final GameState s = bulunan!.copyWith(
      player: bulunan.player.copyWith(
        wallet: OpenHighSchool.prototypeOnlyYearlyFee,
      ),
    );
    final GameState kayitli = OpenHighSchool.enroll(s)!.state;
    final int sinif = kayitli.education.openHighSchoolGrade!;
    // Cüzdanı ücretin altına indir: kayıt yürürken para bitti.
    final GameState parasiz = kayitli.copyWith(
      player: kayitli.player.copyWith(
        wallet: OpenHighSchool.prototypeOnlyYearlyFee - 1,
      ),
    );
    final ({GameState state, List<String> logLines}) adim =
        OpenHighSchool.advanceYear(parasiz);
    expect(adim.state.education.openHighSchoolGrade, sinif,
        reason: 'Ücret ödenmeden sınıf ilerledi.');
    expect(adim.state.education.isOpenHighSchoolStudent, isTrue,
        reason: 'Ödeme yapılamayınca kayıt düşmemeli.');
    expect(adim.state.player.wallet, parasiz.player.wallet,
        reason: 'Ödenemeyen yılda para çıktı.');
    expect(adim.logLines.single, contains('ödeyemedin'));
  });

  test('§2d kayıt bırakılabiliyor ve kaldığı sınıf korunuyor', () {
    final GameState? bulunan = _diplomasizYetiskinAra();
    expect(bulunan, isNotNull);
    final GameState s = bulunan!.copyWith(
      player: bulunan.player.copyWith(
        wallet: OpenHighSchool.prototypeOnlyYearlyFee * 6,
      ),
    );
    GameState kayitli = OpenHighSchool.enroll(s)!.state;
    kayitli = OpenHighSchool.advanceYear(kayitli).state;
    final int gelinen = kayitli.education.openHighSchoolGrade!;

    final GameState birakilmis = OpenHighSchool.leave(kayitli)!.state;
    expect(birakilmis.education.isOpenHighSchoolStudent, isFalse);
    expect(birakilmis.education.grade, gelinen,
        reason: 'Bırakınca gelinen sınıf kayıttan silindi.');
    // Yeniden kaydolunca kaldığı yerden devam eder.
    final GameState yeniden = OpenHighSchool.enroll(birakilmis)!.state;
    expect(yeniden.education.openHighSchoolGrade, gelinen);
  });

  // ——————————————————————————————————————————————————————————————
  // §3 — Kapılar: yaş, diploma, öğrencilik, cezaevi, para.
  // ——————————————————————————————————————————————————————————————

  test('§3 uygun olmayan durumda gerekçe yazılıyor, sessiz ret yok', () {
    // Diploması olan: hiç gerek yok.
    GameState? mezun;
    playBotLife(
      archetype: PlayerArchetype.casual,
      seed: 31031,
      onYear: (GameState s) {
        if (mezun == null && s.education.finished && s.player.age >= 25) {
          mezun = s;
        }
      },
    );
    expect(mezun, isNotNull);
    expect(OpenHighSchool.enrollAvailability(mezun!).isAllowed, isFalse);
    expect(
      OpenHighSchool.enrollAvailability(mezun!).reason,
      contains('diploman'),
    );

    // Okuyan öğrenci: örgün okul sürüyor.
    GameState? ogrenci;
    playBotLife(
      archetype: PlayerArchetype.casual,
      seed: 31031,
      onYear: (GameState s) {
        if (ogrenci == null && s.education.isSchoolStudent) ogrenci = s;
      },
    );
    expect(ogrenci, isNotNull);
    expect(OpenHighSchool.enrollAvailability(ogrenci!).isAllowed, isFalse);

    // Diplomasız yetişkin ama parası yok.
    final GameState? diplomasiz = _diplomasizYetiskinAra();
    expect(diplomasiz, isNotNull);
    final GameState parasiz = diplomasiz!.copyWith(
      player: diplomasiz.player.copyWith(wallet: 0),
    );
    final String? gerekce =
        OpenHighSchool.enrollAvailability(parasiz).reason;
    expect(OpenHighSchool.enrollAvailability(parasiz).isAllowed, isFalse);
    expect(gerekce, contains('kayıt ücreti'));
  });

  // ——————————————————————————————————————————————————————————————
  // §4 — Kayıt dosyası: save/load ve eski kayıt.
  // ——————————————————————————————————————————————————————————————

  test('§4 açık lise kaydı save/load turunda korunuyor', () {
    final GameState? bulunan = _diplomasizYetiskinAra();
    expect(bulunan, isNotNull);
    final GameState s = bulunan!.copyWith(
      player: bulunan.player.copyWith(
        wallet: OpenHighSchool.prototypeOnlyYearlyFee * 6,
      ),
    );
    final GameState kayitli = OpenHighSchool.enroll(s)!.state;
    final GameState geri = decodeGameState(encodeGameState(kayitli));
    expect(
      geri.education.openHighSchoolGrade,
      kayitli.education.openHighSchoolGrade,
    );
    expect(geri.education.isOpenHighSchoolStudent, isTrue);

    // Eski kayıt (alan hiç yok): "kayıtlı değil" demektir, uydurma
    // sınıf yazılmaz.
    final Map<String, Object?> json = encodeGameState(kayitli);
    final Map<String, Object?> egitim =
        Map<String, Object?>.from(json['education']! as Map<String, Object?>)
          ..remove('openHighSchoolGrade');
    final Map<String, Object?> eski = Map<String, Object?>.from(json)
      ..['education'] = egitim;
    expect(decodeGameState(eski).education.openHighSchoolGrade, isNull);
  });

  // ——————————————————————————————————————————————————————————————
  // §5 — Modül kapalıyken: kayıt açılmaz, yürüyen kayıt donar.
  // ——————————————————————————————————————————————————————————————

  test('§5 anahtar kapalıyken kayıt açılmaz ve yürüyen kayıt donar', () {
    final GameState? bulunan = _diplomasizYetiskinAra();
    expect(bulunan, isNotNull);
    final GameState acik = bulunan!.copyWith(
      player: bulunan.player.copyWith(
        wallet: OpenHighSchool.prototypeOnlyYearlyFee * 6,
      ),
    );
    final GameState kayitli = OpenHighSchool.enroll(acik)!.state;

    final GameState kapali = kayitli.copyWith(
      settings: kayitli.settings.copyWith(
        features: kayitli.settings.features.toggled(
          FeatureId.acikLise,
          false,
        ),
      ),
    );
    expect(OpenHighSchool.isOn(kapali), isFalse);
    expect(OpenHighSchool.enrollAvailability(kapali).isAllowed, isFalse);

    // Yürüyen kayıt donar: ücret çıkmaz, sınıf ilerlemez, kayıt silinmez.
    final ({GameState state, List<String> logLines}) adim =
        OpenHighSchool.advanceYear(kapali);
    expect(adim.logLines, isEmpty);
    expect(adim.state.player.wallet, kapali.player.wallet);
    expect(
      adim.state.education.openHighSchoolGrade,
      kapali.education.openHighSchoolGrade,
    );

    // Anahtar kapalıyken bir yıl ilerletmek de hiçbir şey değiştirmez.
    final GameState yilSonra =
        LifeProgression(Random(5)).advanceOneYear(kapali);
    expect(
      yilSonra.education.openHighSchoolGrade,
      kapali.education.openHighSchoolGrade,
    );
    expect(yilSonra.education.finished, isFalse);
  });

  // ——————————————————————————————————————————————————————————————
  // §6 — Kanca doğru yerde mi? (Motorun yıllık adımından geçiyor mu?)
  //
  // §2 adımı doğrudan çağırıyor; §5 yalnızca **kapalı** hâli motorla
  // deniyor. İkisi de kancanın `advanceOneYear` içinde olduğunu
  // kanıtlamıyor: `OpenHighSchool.advanceYear` hiç çağrılmasa da o
  // testler geçerdi. Bu bölüm açık hâli motordan geçirir.
  // ——————————————————————————————————————————————————————————————

  test('§6 açıkken motorun yıllık adımı açık liseyi ilerletiyor', () {
    final GameState? bulunan = _diplomasizYetiskinAra();
    expect(bulunan, isNotNull);
    final GameState s = bulunan!.copyWith(
      pendingEvent: null,
      player: bulunan.player.copyWith(
        wallet: OpenHighSchool.prototypeOnlyYearlyFee * 20,
      ),
    );
    GameState kayitli = OpenHighSchool.enroll(s)!.state;
    final int baslangic = kayitli.education.openHighSchoolGrade!;

    bool ilerledi = false;
    for (int i = 0; i < 6 && !kayitli.deceased; i++) {
      kayitli = LifeProgression(Random(11 + i)).advanceOneYear(
        kayitli.copyWith(pendingEvent: null),
      );
      if (kayitli.education.finished ||
          (kayitli.education.openHighSchoolGrade ?? 0) > baslangic) {
        ilerledi = true;
        break;
      }
    }
    expect(
      ilerledi,
      isTrue,
      reason: 'Motorun yıllık adımı açık liseyi hiç ilerletmedi; '
          'kanca `advanceOneYear` içinde değil ya da yanlış yerde.',
    );
    // Günlüğe de yazılmış olmalı: sessiz ilerleme yok.
    expect(
      kayitli.log.any((LifeLogEntry e) => e.text.contains('Açık lise')),
      isTrue,
    );
  });
}
