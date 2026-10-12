import 'dart:io';
import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/data/job_catalog.dart';
import 'package:bir_omur/domain/career/job_market.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/interaction.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/player_bot.dart';

/// **Paket DP — İş ara sayfasındaki cümle tekrarı.**
///
/// `sections/` dökümü İş ara karesini ilk kez bastı ve kare şunu
/// gösterdi: 59 yaşındaki oyuncunun mülakatı sürüyordu ve listedeki
/// **21 iş kartının 20'sinin** altında birebir aynı cümle vardı —
/// "Devam eden bir mülakatın var."
///
/// Kök neden `applicationAvailability`ın her iş için **ayrı**
/// çağrılması: o fonksiyonun iki engeli (hâlâ çalışıyor olmak, mülakatın
/// sürmesi) işe hiç bakmıyor, dolayısıyla her kart aynı gerekçeyi
/// alıyor. Kart da gerekçeyi kendi bilgisinin (eğitim kademesi · yaş
/// kapısı) **yerine** yazdığı için satır hem tekrarlıyor hem de o işe
/// dair tek bilgiyi kaybediyordu.
///
/// Düzeltme: engel `JobMarket.globalBlockReason` ile işten bağımsız
/// olarak okunuyor, sayfanın başında **bir kez** yazılıyor; kartın
/// gerekçesi onunla birebir aynıysa kart kendi satırına dönüyor. Düğme
/// yine kapalı: tekrarı kaldırmak engeli gizlemek değil.
///
/// Aynı sınıf Paket CL'de bir kez düzeltilmişti (aynı cümlenin üst üste
/// iki kez yazılması). Kalıcı bekçi bu yüzden tek sayfaya değil
/// **bütün dökümüne** kondu: `ekran_dokumu_bolumler_test.dart` artık her
/// karede cümle tekrarını sayıyor (ölçülen meşru tavan 4).
void main() {
  const JobMarket pazar = JobMarket();

  /// Yorum satırları atılmış kaynak (Paket DH dersi).
  String kodu(String yol) => File(yol)
      .readAsLinesSync()
      .where((String l) {
        final String t = l.trimLeft();
        return !t.startsWith('//') && !t.startsWith('///');
      })
      .join('\n');

  /// **Durum kurulmuyor, aranıyor.** Mülakatı süren, çalışmayan ve
  /// listesinde çok sayıda açık iş olan temiz bir kare bot hayatlarından
  /// bulunuyor.
  GameState? kareBul() {
    GameState? bulunan;
    const List<PlayerArchetype> arketipler = <PlayerArchetype>[
      PlayerArchetype.casual,
      PlayerArchetype.career,
      PlayerArchetype.family,
      PlayerArchetype.social,
      PlayerArchetype.investor,
      PlayerArchetype.sport,
      PlayerArchetype.entrepreneur,
      PlayerArchetype.risky,
    ];
    for (final PlayerArchetype a in arketipler) {
      for (int tohum = 0; tohum < 40; tohum++) {
        if (bulunan != null) return bulunan;
        void bak(GameState s) {
          if (bulunan != null || s.deceased) return;
          if (s.hasNotice || s.pendingEvent != null || s.hasPendingCrisis) {
            return;
          }
          if (!s.hasPendingInterview) return;
          if (s.career.isEmployed || s.education.isStudent) return;
          if (s.career.isRetired || s.player.age < 18) return;
          if (pazar.openJobs(s).length < 5) return;
          bulunan = s;
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

  GameState? kare;
  setUpAll(() => kare = kareBul());

  test('§1 engel işten bağımsız: aynı cümle bütün kartlara düşüyor', () {
    final GameState? s = kare;
    expect(s, isNotNull,
        reason: 'Mülakatı süren, çalışmayan ve 5+ açık işi olan kare '
            'bulunamadı; §1 bu koşuda sınanamaz.');

    final List<JobType> acik = pazar.openJobs(s!);
    final Set<String> gerekceler = <String>{
      for (final JobType j in acik)
        if (!pazar.applicationAvailability(s, j).isAllowed)
          pazar.applicationAvailability(s, j).reason!,
    };

    // Kusurun **neden** doğduğunu sabitler: açık işlerin neredeyse
    // tamamı aynı gerekçeyi taşıyor (ölçülen karede 21'in 20'si), yani
    // gerekçe satıra ait değil. "Hepsi" denmiyor: bu yıl başvurulmuş
    // bir iş kendi cümlesini taşır ve §3 onu ayrıca arıyor.
    expect(
      gerekceler,
      contains(JobMarket.blockedWhileInterviewing),
      reason: 'Beklenen engel bu karede görünmüyor: $gerekceler',
    );
    expect(
      pazar.globalBlockReason(s),
      JobMarket.blockedWhileInterviewing,
      reason: 'İşten bağımsız engel, kartların aldığı gerekçeyle aynı '
          'cümle olmalı; yoksa sayfa başındaki panel başka bir şey '
          'söyler.',
    );

    final int ayniyi = acik
        .where(
          (JobType j) =>
              pazar.applicationAvailability(s, j).reason ==
              JobMarket.blockedWhileInterviewing,
        )
        .length;
    // ignore: avoid_print
    print('İŞ ARA ölçümü: ${s.player.age} yaş · açık iş ${acik.length} · '
        'aynı gerekçeyi taşıyan $ayniyi');
    expect(ayniyi, greaterThanOrEqualTo(5));
  });

  test('§2 engel yokken hiçbir şey bastırılmıyor', () {
    // Düzeltmenin kapsamı: `sharedReason` boşken kart eskisi gibi kendi
    // gerekçesini yazar. Bunu kaynakta **koşulun kendisi** garanti
    // ediyor; koşul gevşerse (ör. yalnızca `isNotEmpty`) işe özel
    // gerekçeler de gizlenir.
    final String sayfa =
        kodu('lib/ui/screens/sections/education_career_pages.dart');
    expect(
      sayfa,
      contains('gerekce == sharedReason'),
      reason: 'Tekrar kararı birebir eşitlikten başka bir şeye '
          'dayanıyorsa işe özel gerekçe de gizlenebilir.',
    );
    expect(sayfa, contains('sharedReason.isNotEmpty'));
    expect(
      sayfa,
      contains('controller.jobApplicationGlobalBlockReason()'),
      reason: 'Sayfa engeli işten bağımsız olarak okumuyor.',
    );
    expect(
      sayfa.contains(': (availability.reason as String? ?? \'\')'),
      isFalse,
      reason: 'Kart yine ham gerekçeyi basıyor; tekrar geri gelir.',
    );
  });

  testWidgets('§3 cümle ekranda bir kez yazılıyor, düğme yine kapalı',
      (WidgetTester tester) async {
    final GameState? s = kare;
    if (s == null) {
      // ignore: avoid_print
      print('UYARI: kare BULUNAMADI; §3 bu koşuda sınanmadı.');
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
    controller.debugSetState(s);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('tab_okul_meslek')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('İş ara'));
    await tester.pumpAndSettle();

    // 1) Cümle **bir** kez.
    expect(
      find.text(JobMarket.blockedWhileInterviewing),
      findsOneWidget,
      reason: 'Engel cümlesi ya hiç yazılmıyor ya da yine her kartta '
          'tekrarlıyor.',
    );
    expect(find.byKey(const Key('is_ara_genel_engel')), findsOneWidget);

    // 2) Kartlar kendi bilgisine döndü: en az beş kartta "yaş+" satırı.
    final int yasSatiri = tester
        .widgetList<Text>(find.byType(Text))
        .where((Text w) => (w.data ?? '').contains(' yaş+'))
        .length;
    expect(
      yasSatiri,
      greaterThanOrEqualTo(5),
      reason: 'Kartlar kendi satırını (eğitim kademesi · yaş kapısı) '
          'yazmıyor; tekrar kalkınca satır boş kalmış olabilir.',
    );

    // 3) **İşe özel gerekçe gizlenmedi.** Bastırma birebir eşitliğe
    //    dayanıyor; bu karede açık işlerden birinin gerekçesi farklı
    //    ("Bu yıl Kuaför işine başvurdun ve kabul edilmedin…") ve o
    //    satırda yazılmaya devam ediyor. Ölçülmüş bir iddia: küme
    //    boşsa test uyarı basar, sessizce geçmez.
    final Set<String> ozelGerekceler = <String>{
      for (final JobType j in pazar.openJobs(s))
        if (!pazar.applicationAvailability(s, j).isAllowed &&
            pazar.applicationAvailability(s, j).reason !=
                JobMarket.blockedWhileInterviewing)
          pazar.applicationAvailability(s, j).reason!,
    };
    if (ozelGerekceler.isEmpty) {
      // ignore: avoid_print
      print('UYARI: bu karede işe özel gerekçe yok; §3ün üçüncü '
          'iddiası sınanmadı.');
    }
    for (final String g in ozelGerekceler) {
      expect(
        find.text(g),
        findsOneWidget,
        reason: 'İşe özel gerekçe ekranda yok; bastırma fazla geniş: '
            '"$g"',
      );
    }

    // 4) Engel gizlenmedi: başvuru düğmeleri kapalı.
    final List<FilledButton> dugmeler = tester
        .widgetList<FilledButton>(find.byType(FilledButton))
        .where((FilledButton b) {
          final Widget? c = b.child;
          return c is Text && c.data == 'Başvur';
        })
        .toList(growable: false);
    expect(dugmeler.length, greaterThanOrEqualTo(5),
        reason: 'Başvuru düğmeleri çizilmedi.');
    expect(
      dugmeler.every((FilledButton b) => b.onPressed == null),
      isTrue,
      reason: 'Tekrar kaldırıldı ama düğme açık kaldı: engel gizlenmiş '
          'olur.',
    );
  });

  test('§4 işten bağımsız engel listesi, sıralamayı bozmadan tek kaynak',
      () {
    // `applicationAvailability` sırası korunuyor: işe özel iki engel
    // (bu yıl bu işe başvurdun, mülakat sorusu yazılmadı) araya giriyor
    // ve `globalBlockReason` onları **iddia etmiyor**.
    final String kaynak = kodu('lib/domain/career/job_market.dart');
    expect(kaynak, contains('String globalBlockReason(GameState state)'));
    expect(
      kaynak,
      contains(
        'InteractionAvailability.blocked(blockedWhileInterviewing)',
      ),
      reason: 'Cümle iki yerde ayrı ayrı yazılırsa biri değişip öteki '
          'kalır ve panel kartla çelişir.',
    );
    expect(
      kaynak.contains("blocked(\n        'Devam eden bir mülakatın var.',"),
      isFalse,
      reason: 'Ham cümle geri gelmiş.',
    );

    // Sabitin kendisi de bir iddiadır: panel bu metni yazıyor.
    expect(JobMarket.blockedWhileInterviewing, 'Devam eden bir mülakatın var.');
    expect(
      JobMarket.blockedWhileEmployed,
      'Önce mevcut işinden ayrılman gerekiyor.',
    );
  });

  test('§5 ikinci tetikleyici: çalışan oyuncu "İş değiştir" sayfasında', () {
    // Aynı kusurun **iki** tetikleyicisi var. Meslek sayfasındaki satır
    // çalışan oyuncuya "İş değiştir" diye görünüyor ve aynı sayfayı
    // açıyor; o durumda bütün kartlar "Önce mevcut işinden ayrılman
    // gerekiyor." yazar. Düzeltme iki dalı birlikte kapsıyor, bu yüzden
    // ikinci dal da ölçülüyor.
    GameState? calisan;
    for (final PlayerArchetype a in <PlayerArchetype>[
      PlayerArchetype.career,
      PlayerArchetype.casual,
    ]) {
      for (int tohum = 0; tohum < 20 && calisan == null; tohum++) {
        void bak(GameState s) {
          if (calisan != null || s.deceased) return;
          if (!s.career.isEmployed || s.career.isRetired) return;
          if (pazar.openJobs(s).length < 5) return;
          calisan = s;
        }

        playBotLife(
          archetype: a,
          seed: 61000 + tohum,
          onYear: bak,
          onPreAge: bak,
        );
      }
    }
    if (calisan == null) {
      // ignore: avoid_print
      print('UYARI: çalışan ve 5+ açık işi olan kare BULUNAMADI; §5 bu '
          'koşuda sınanmadı.');
      return;
    }
    expect(
      pazar.globalBlockReason(calisan!),
      JobMarket.blockedWhileEmployed,
      reason: 'Çalışan oyuncuda işten bağımsız engel bu cümle olmalı.',
    );
    final Set<String> gerekceler = <String>{
      for (final JobType j in pazar.openJobs(calisan!))
        pazar.applicationAvailability(calisan!, j).reason ?? '',
    };
    // ignore: avoid_print
    print('İŞ DEĞİŞTİR ölçümü: ${calisan!.player.age} yaş · açık iş '
        '${pazar.openJobs(calisan!).length} · ayrı gerekçe '
        '${gerekceler.length}');
    expect(
      gerekceler,
      <String>{JobMarket.blockedWhileEmployed},
      reason: 'Çalışan oyuncuda bütün kartlar aynı cümleyi taşıyor; '
          'panel bu yüzden ikinci dalı da kapsıyor.',
    );
  });

  test('§6 kart gerekçesi InteractionAvailability sözleşmesine uyuyor', () {
    // `_JobCard.availability` `dynamic`; alanların adı değişse kart
    // sessizce boş satır çizer. Sözleşme burada sabitlenir.
    const InteractionAvailability engelli =
        InteractionAvailability.blocked('x');
    expect(engelli.isAllowed, isFalse);
    expect(engelli.reason, 'x');
    const InteractionAvailability acik = InteractionAvailability.allowed();
    expect(acik.isAllowed, isTrue);
    expect(acik.reason, isNull);
  });
}
