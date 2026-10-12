import 'dart:io';
import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/data/activity_catalog.dart';
import 'package:bir_omur/data/job_catalog.dart';
import 'package:bir_omur/domain/law/prison_life.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/player_bot.dart';
import 'support/section_pages.dart';

/// **Paket DS — öğrencinin iş kapısı kapalıydı.**
///
/// D-131 aynen şöyle diyor: *"Öğrenci artık İş ara ekranını görür; ekran
/// yarım zamanlı ve tam zamanlı işleri **ayrı gruplar**."* Sayfa o karara
/// göre yazılmış — `education_career_pages.dart` yarım zamanlı işleri
/// kendi başlığı altında listeliyor. Ama sayfaya giden tek kapı
/// `_CareerView` içindeydi ve `SchoolCareerScreen.build`, `_CareerView`'i
/// yalnızca **öğrenci olmayana** çiziyor:
///
/// ```
/// if (egitim.isStudent) return _SchoolView(...);
/// return _CareerView(...);
/// ```
///
/// Yani sekiz yarım zamanlı iş, kendi maaş bandı ve on altı mülakat
/// sorusu tam olarak yazıldığı kitleye kapalıydı. Kanıt kodun kendi
/// içinde duruyordu: kariyer görünümündeki satırın alt yazısında
/// `egitim.isSchoolStudent ? 'Okurken yapılabilecek yarım zamanlı işler'`
/// dalı vardı ve `isStudent = enrolled || isUniversityStudent`,
/// `isSchoolStudent = enrolled` olduğu için o dal **hiç** çalışamazdı.
///
/// Durum kurgusal değil: bot taraması öğrencinin çalıştığı ve mülakatı
/// sürdüğü kareleri buluyor (§1'in ölçümü). Motor izin veriyordu, ekran
/// göstermiyordu.
void main() {
  /// Yorum satırları atılmış kaynak (Paket DH dersi: yorum gören tarama
  /// yanlış alarm veriyor).
  String kodu(String yol) => File(yol)
      .readAsLinesSync()
      .where((String l) {
        final String t = l.trimLeft();
        return !t.startsWith('//') && !t.startsWith('///');
      })
      .join('\n');

  /// **Durum kurulmuyor, aranıyor.**
  GameState? kareBul(bool Function(GameState) kosul, {int tohumSayisi = 14}) {
    GameState? bulunan;
    for (final PlayerArchetype a in PlayerArchetype.values) {
      for (int tohum = 0; tohum < tohumSayisi; tohum++) {
        if (bulunan != null) return bulunan;
        void bak(GameState s) {
          if (bulunan != null || s.deceased) return;
          // Bekleyen bir şey varken `debugSetState` edilen durumda modal
          // pencere açılıyor ve sekmeler kilitleniyor (Paket CG tuzağı).
          if (s.hasNotice || s.pendingEvent != null || s.hasPendingCrisis) {
            return;
          }
          if (kosul(s)) bulunan = s;
        }

        playBotLife(
          archetype: a,
          seed: 70000 + tohum,
          onYear: bak,
          onPreAge: bak,
        );
      }
    }
    return bulunan;
  }

  List<String> ekranMetni(WidgetTester tester) => <String>[
        for (final Text w in tester.widgetList<Text>(find.byType(Text)))
          (w.data ?? w.textSpan?.toPlainText() ?? '')
              .trim()
              .replaceAll(RegExp(r'\s+'), ' '),
      ].where((String t) => t.isNotEmpty).toList();

  Future<void> okulEkraniAc(WidgetTester tester, GameState durum) async {
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
    controller.debugSetState(durum);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tab_okul_meslek')));
    await tester.pumpAndSettle();
  }

  test('§1 ÖLÇÜM: kapalı kapının arkasındaki kareler gerçekten oluyor', () {
    // Ölçüm, iddianın tamamını taşıyor: "öğrenci iş bulabiliyor ama
    // ekranda göremiyor" demek için önce o karenin oyunda gerçekten
    // oluştuğunu göstermek gerekiyor.
    int ogrenci16 = 0;
    int ogrenciCalisan = 0;
    int ogrenciMulakat = 0;
    final Set<String> isler = <String>{};
    for (final PlayerArchetype a in PlayerArchetype.values) {
      for (int tohum = 0; tohum < 12; tohum++) {
        void bak(GameState s) {
          if (s.deceased || !s.education.isStudent) return;
          if (s.player.age >= 16) ogrenci16++;
          if (s.career.isEmployed) {
            ogrenciCalisan++;
            isler.add(s.career.label);
          }
          if (s.hasPendingInterview) ogrenciMulakat++;
        }

        playBotLife(
          archetype: a,
          seed: 70000 + tohum,
          onYear: bak,
          onPreAge: bak,
        );
      }
    }
    // ignore: avoid_print
    print('ÖĞRENCİ KARELERİ · 16 yaş+: $ogrenci16 · çalışan: '
        '$ogrenciCalisan · mülakatı süren: $ogrenciMulakat');
    // ignore: avoid_print
    print('ÇALIŞAN ÖĞRENCİNİN İŞLERİ: ${isler.join(" · ")}');

    expect(
      ogrenci16,
      greaterThan(0),
      reason: 'Çalışma çağındaki öğrenci karesi bulunamadı; ölçüm aracı '
          'bozulmuş olabilir.',
    );
    expect(
      ogrenciCalisan,
      greaterThan(0),
      reason: 'Motor öğrencinin çalışmasına izin veriyordu; ölçüm bunu '
          'artık göstermiyorsa ya motor ya bot değişti.',
    );
    expect(
      ogrenciMulakat,
      greaterThan(0),
      reason: 'Mülakatı süren öğrenci karesi bulunamadı.',
    );
  });

  test('§2 kaynak kilidi: iş sayfasının okul tarafında da kapısı var', () {
    final String ekran = kodu('lib/ui/screens/sections/school_career_screen.dart');
    expect(
      ekran,
      contains('case _SchoolPage.isArama:'),
      reason: 'Okul görünümünün iş arama sayfası yine yok; D-131 '
          '"Öğrenci artık İş ara ekranını görür" diyor.',
    );
    expect(
      ekran,
      contains("Key('school_is_ara_row')"),
      reason: 'Öğrencinin "İş ara" satırı kaldırılmış.',
    );
    expect(
      ekran,
      contains("Key('school_mulakat_devam')"),
      reason: 'Öğrencinin mülakata devam satırı kaldırılmış.',
    );
    // Ölü dal geri gelmesin: `_CareerView` yalnızca öğrenci olmayana
    // çiziliyor, orada `isSchoolStudent` daima false.
    expect(
      ekran.contains('egitim.isSchoolStudent'),
      isFalse,
      reason: 'Kariyer görünümünde hiç çalışmayan öğrenci dalı geri '
          'gelmiş; o cümlenin yeri okul görünümü.',
    );
  });

  test('§3 ÖLÇÜM + kilit: yaş kapısı katalogdan okunuyor', () {
    final List<JobType> yarim =
        kJobCatalog.where((JobType j) => j.partTime).toList();
    final int enKucuk = yarim
        .map((JobType j) => j.minAge)
        .reduce((int a, int b) => a < b ? a : b);
    // ignore: avoid_print
    print('YARIM ZAMANLI KATALOG · ${yarim.length} iş · en küçük yaş '
        '$enKucuk · tam zamanlı ${kJobCatalog.length - yarim.length} iş');
    for (final JobType j in yarim) {
      // ignore: avoid_print
      print('  ${j.name} · ${j.minAge} yaş+');
    }
    expect(yarim.length, 8);
    expect(enKucuk, 16);

    // Ekran bu sayıyı **tekrar yazmıyor**: Paket DS öncesinde
    // `const int _enKucukYarimZamanliYas = 16;` vardı ve yorumu
    // "katalogdaki en küçük minAge ile aynı" diyordu — hiçbir yerde
    // sınanmayan bir iddia. Artık kapı kataloğu okuyor.
    final String ekran =
        kodu('lib/ui/screens/sections/school_career_screen.dart');
    expect(
      ekran,
      contains('int get _enKucukYarimZamanliYas => kJobCatalog'),
      reason: 'Yaş kapısı yine elle yazılmış bir sayı; katalog '
          'değişince ekran yanlış yaşı söyler.',
    );
    expect(
      ekran.contains('_enKucukYarimZamanliYas = 16'),
      isFalse,
      reason: 'Sihirli sayı geri gelmiş.',
    );
  });

  test('§3b koğuş karesinde iki sistem aynı cümleyi yazmıyor', () {
    // **Nasıl çıktı.** Paket DS `prison_life_panel.dart` karesini ilk
    // kez bastı (modal dökümüne eklendi) ve ekranda iki satır yan yana
    // durdu:
    //
    //   Kurallara uy, sakin dur · Tartışmanın kenarından dolaşırsın.
    //                             İyi hâl dosyana yazılır.
    //   Sakin kal · Ücretsiz · Tartışmanın kenarından dolaş. En zor
    //                          olanı bu.
    //
    // İki ayrı sistem (`PrisonAction` ve `ActivityAction`), iki ayrı
    // karşılık, **aynı cümle**. Oyuncu ikisini metinden ayırt
    // edemiyordu.
    final List<String> cezaeviAktiviteleri = <String>[
      for (final ActivityAction a in kActivityActions)
        if (a.onlyInPrison) a.description,
    ];
    final List<String> kogusEylemleri = <String>[
      for (final PrisonAction e in PrisonAction.values) e.description,
    ];
    // ignore: avoid_print
    print('KOĞUŞ METİNLERİ · aktivite ${cezaeviAktiviteleri.length} · '
        'koğuş eylemi ${kogusEylemleri.length}');

    /// 20 karakterlik ortak parça: tesadüf değil, kopya.
    String sade(String t) =>
        t.toLowerCase().replaceAll(RegExp(r'[^a-zçğıöşü ]'), '');
    final List<String> cakisan = <String>[];
    for (final String a in cezaeviAktiviteleri) {
      final String sa = sade(a);
      for (final String k in kogusEylemleri) {
        final String sk = sade(k);
        for (int i = 0; i + 20 <= sa.length; i++) {
          final String parca = sa.substring(i, i + 20);
          if (sk.contains(parca)) {
            cakisan.add('"$parca" · aktivite: "$a" · koğuş: "$k"');
            break;
          }
        }
      }
    }
    expect(
      cakisan,
      isEmpty,
      reason: 'Koğuş karesinde iki satır aynı cümleyi yazıyor; oyuncu '
          'hangisinin ne verdiğini metinden anlayamaz:\n'
          '${cakisan.join("\n")}',
    );
  });

  testWidgets('§4 öğrenci iş arama sayfasını açabiliyor',
      (WidgetTester tester) async {
    final GameState? durum = kareBul(
      (GameState s) =>
          s.education.isStudent &&
          s.player.age >= 16 &&
          !s.career.isEmployed &&
          !s.hasPendingInterview,
    );
    if (durum == null) {
      // ignore: avoid_print
      print('UYARI: 16 yaş+ işsiz öğrenci karesi BULUNAMADI; §4 '
          'sınanmadı.');
      return;
    }
    await okulEkraniAc(tester, durum);

    final Finder satir = find.byKey(const Key('school_is_ara_row'));
    expect(
      satir,
      findsOneWidget,
      reason: '${durum.player.age} yaşındaki öğrencinin ekranında "İş '
          'ara" satırı yok:\n${ekranMetni(tester).join("\n")}',
    );
    await tester.ensureVisible(satir);
    await tester.pumpAndSettle();
    await tester.tap(satir);
    await tester.pumpAndSettle();

    final List<String> ekran = ekranMetni(tester);
    // ignore: avoid_print
    print('\n===== ÖĞRENCİ İŞ ARAMA · ${durum.player.age} yaş · '
        '${ekran.length} metin =====');
    // ignore: avoid_print
    print(ekran.join('\n'));

    // Sayfa gerçekten açıldı mı? D-131'in ayrı grubu burada görünür.
    expect(
      ekran.any((String t) => t.contains('Yarım zamanlı')),
      isTrue,
      reason: 'İş arama sayfası açıldı ama D-131in "Yarım zamanlı" '
          'grubu görünmüyor:\n${ekran.join("\n")}',
    );
    // Sahte sayfa değil: en az bir yarım zamanlı işin adı yazıyor.
    final List<String> gorunenIsler = <String>[
      for (final JobType j in kJobCatalog.where((JobType j) => j.partTime))
        if (ekran.any((String t) => t.contains(j.name))) j.name,
    ];
    // ignore: avoid_print
    print('GÖRÜNEN YARIM ZAMANLI İŞLER: ${gorunenIsler.join(" · ")}');
    expect(
      gorunenIsler,
      isNotEmpty,
      reason: 'Yarım zamanlı grup başlığı var ama altında hiç iş yok.',
    );
  });

  testWidgets('§5 çalışan öğrenci işini ve ayrılma yolunu görüyor',
      (WidgetTester tester) async {
    final GameState? durum = kareBul(
      (GameState s) => s.education.isStudent && s.career.isEmployed,
    );
    if (durum == null) {
      // ignore: avoid_print
      print('UYARI: çalışan öğrenci karesi BULUNAMADI; §5 sınanmadı.');
      return;
    }
    await okulEkraniAc(tester, durum);
    final List<String> ekran = ekranMetni(tester);
    // ignore: avoid_print
    print('\n===== ÇALIŞAN ÖĞRENCİ · ${durum.player.age} yaş · '
        '${durum.career.label} · ${ekran.length} metin =====');
    // ignore: avoid_print
    print(ekran.join('\n'));

    expect(
      find.byKey(const Key('school_is_karti')),
      findsOneWidget,
      reason: 'Öğrencinin işi ekranda hiç yazmıyor; maaşını da '
          'göremiyor.',
    );
    expect(
      ekran.any((String t) => t.contains(durum.career.title)),
      isTrue,
      reason: 'İş kartı var ama görevin adı ("${durum.career.title}") '
          'yazmıyor.',
    );
    expect(
      find.byKey(const Key('school_isten_ayril')),
      findsOneWidget,
      reason: 'Öğrenci işe girdiğinde ayrılma yolu yoktu; tek yönlü '
          'kapı bırakılmaz.',
    );
    // Çalışan öğrencide satır kariyer görünümüyle aynı dili konuşur.
    expect(
      ekran.any((String t) => t == 'İş değiştir'),
      isTrue,
      reason: 'Çalışan öğrencide satır yine "İş ara" diyor.',
    );

    // **Ayrılma gerçekten çalışıyor ve karşılığı dokunulan yerde
    // görünüyor.** İlk yazımda düğme `_sonuc` alanını dolduruyordu; o
    // panel sayfanın altında, altı menü satırının ardında duruyor —
    // oyuncu dokunduğu yerde hiçbir karşılık görmezdi. Ayrı alan
    // (`_isSonucu`) düğmenin hemen altına yazıyor.
    final Finder ayril = find.byKey(const Key('school_isten_ayril'));
    await tester.ensureVisible(ayril);
    await tester.pumpAndSettle();
    await tester.tap(ayril);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('school_is_karti')),
      findsNothing,
      reason: 'İşten ayrıldıktan sonra iş kartı hâlâ duruyor.',
    );
    final List<String> sonra = ekranMetni(tester);
    // ignore: avoid_print
    print('AYRILMA SONRASI · ${sonra.length} metin · '
        'sonuç paneli: ${find.byKey(const Key("school_is_sonucu"))
            .evaluate().isNotEmpty}');
    expect(
      find.byKey(const Key('school_is_sonucu')),
      findsOneWidget,
      reason: 'İşten ayrıldın ama ekran bunu söylemiyor:\n'
          '${sonra.join("\n")}',
    );
    // Satır artık yeniden "İş ara" diyor: durum tutarlı.
    expect(
      sonra.any((String t) => t == 'İş ara'),
      isTrue,
      reason: 'Ayrıldıktan sonra satır hâlâ "İş değiştir" diyor.',
    );
  });

  testWidgets('§6 mülakatı süren öğrenci devam edebiliyor',
      (WidgetTester tester) async {
    final GameState? durum = kareBul(
      (GameState s) => s.education.isStudent && s.hasPendingInterview,
    );
    if (durum == null) {
      // ignore: avoid_print
      print('UYARI: mülakatı süren öğrenci karesi BULUNAMADI; §6 '
          'sınanmadı.');
      return;
    }
    await okulEkraniAc(tester, durum);

    final Finder satir = find.byKey(const Key('school_mulakat_devam'));
    expect(
      satir,
      findsOneWidget,
      reason: 'Mülakatı süren öğrencinin devam satırı yok. Bu kare '
          'kilitliydi: bütün başvurular "Devam eden bir mülakatın var." '
          'diye kapanıyor, devam etme yolu da bulunmuyordu.\n'
          '${ekranMetni(tester).join("\n")}',
    );
    await tester.ensureVisible(satir);
    await tester.pumpAndSettle();
    await tester.tap(satir);
    await tester.pumpAndSettle();

    final List<String> ekran = ekranMetni(tester);
    // ignore: avoid_print
    print('\n===== ÖĞRENCİ MÜLAKATI · ${durum.player.age} yaş · '
        '${durum.pendingInterview?.job?.name} · ${ekran.length} metin '
        '=====');
    // ignore: avoid_print
    print(ekran.join('\n'));
    // **İşaret gevşek bırakılmaz.** İlk yazdığımda ölçü "soru"
    // içeriyordu; o dizge ekranın başka bir yerinde de geçebilir ve
    // döküm açılmamış bir pencereyi "okundu" diye yazabilirdi. Ölçü
    // artık pencerenin kendi başlığı ve kendi cümlesi.
    final String isinAdi = durum.pendingInterview?.job?.name ?? '';
    expect(
      ekran.any((String t) => t == '$isinAdi mülakatı'),
      isTrue,
      reason: 'Mülakat penceresinin başlığı yok:\n${ekran.join("\n")}',
    );
    expect(
      ekran.any((String t) => t.contains('Karşındaki kişi bir soru soruyor')),
      isTrue,
      reason: 'Mülakat penceresi açılmadı:\n${ekran.join("\n")}',
    );
    // Soru gerçekten bir seçim sunuyor mu? Cevapsız mülakat olmaz.
    expect(
      ekran.where((String t) => t == 'Görüşmeden vazgeç').length,
      1,
      reason: 'Vazgeçme yolu yok ya da iki kez yazılıyor.',
    );

    // **Modal kapsam kaydı (Paket DS).** `interview_sheet.dart`
    // Paket DR'nin bekleme kuyruğundaydı; karesini ilk kez bu test
    // bastı. Kayıt `kModalBaskaTestle` içinde duruyor ve iddiayı
    // basan taraf — yani burası — doğruluyor.
    modalKapsamDenetle('paket_ds_ogrenci_is_kapisi_test.dart', ekran);
  });
}
