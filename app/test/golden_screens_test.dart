import 'dart:io';
import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/life/life_verdict.dart';
import 'package:bir_omur/domain/models/career.dart';
import 'package:bir_omur/domain/models/education.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/marriage.dart';
import 'package:bir_omur/domain/models/trip.dart';
import 'package:bir_omur/domain/models/gift_record.dart';
import 'package:bir_omur/domain/models/life_log.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/player_character.dart';
import 'package:bir_omur/domain/models/stats.dart';
import 'package:bir_omur/ui/theme/bir_omur_theme.dart';
import 'package:bir_omur/ui/widgets/character_face.dart';
import 'package:bir_omur/ui/widgets/comic.dart';
import 'package:bir_omur/ui/widgets/life_verdict_panel.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:bir_omur/ui/sound/sound_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_flow.dart';

/// Ekranların gerçek görüntüsünü üretir (`test/goldens/`).
///
/// Görüntü karşılaştırması yazı tipine ve platforma duyarlı olduğu için bu
/// dosya normal `flutter test` koşusunda **atlanır**. Çalıştırmak için:
///
/// ```
/// BIR_OMUR_SCREENSHOTS=1 flutter test --update-goldens test/golden_screens_test.dart
/// ```
const String _kSwitch = 'BIR_OMUR_SCREENSHOTS';

/// Ekran görüntüleri gerçek uygulamaya benzesin diye Flutter'ın kendi
/// Roboto ve Material Icons dosyaları yüklenir. Aksi halde yazılar tek tip
/// kalınlıkta, ikonlar ise boş kare olarak çıkıyordu ve tasarım
/// değerlendirilemiyordu.
const String _flutterFonts =
    '/opt/flutter/bin/cache/artifacts/material_fonts';

const List<String> _fallbackFonts = <String>[
  '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
  '/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf',
  '/System/Library/Fonts/Supplemental/Arial.ttf',
];

Future<bool> _loadFamily(String family, Map<String, String> files) async {
  final FontLoader loader = FontLoader(family);
  bool any = false;
  for (final MapEntry<String, String> entry in files.entries) {
    final File file = File(entry.value);
    if (!file.existsSync()) continue;
    any = true;
    final Uint8List bytes = await file.readAsBytes();
    loader.addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
  }
  if (!any) return false;
  await loader.load();
  return true;
}

Future<void> _loadReadableFont() async {
  // Material ikon yazı tipi: menü ve düğme ikonları görünsün diye.
  await _loadFamily('MaterialIcons', <String, String>{
    'regular': '$_flutterFonts/MaterialIcons-Regular.otf',
  });

  // Oyunun kendi yazı tipleri (Paket 19). Bunlar yüklenmezse ekran
  // görüntülerinde bütün yazılar boş kutu çıkıyor ve tasarım
  // değerlendirilemiyor.
  final bool baloo = await _loadFamily('Baloo2', <String, String>{
    'w400': 'assets/fonts/Baloo2-400.ttf',
    'w500': 'assets/fonts/Baloo2-500.ttf',
    'w600': 'assets/fonts/Baloo2-600.ttf',
    'w700': 'assets/fonts/Baloo2-700.ttf',
    'w800': 'assets/fonts/Baloo2-800.ttf',
  });
  await _loadFamily('PatrickHand', <String, String>{
    'regular': 'assets/fonts/PatrickHand-Regular.ttf',
  });
  if (baloo) return;

  // Yazı tipleri bulunamazsa okunabilir bir yedek yüklenir.
  for (final String path in _fallbackFonts) {
    if (await _loadFamily('Baloo2', <String, String>{'regular': path})) return;
  }
}

void main() {
  final bool enabled = Platform.environment[_kSwitch] == '1';

  late GameController controller;

  setUpAll(() async {
    if (enabled) await _loadReadableFont();
  });

  setUp(() {
    controller = GameController(random: Random(7));
  });

  tearDown(() => controller.dispose());

  // Denetleyici değiştirilip yeniden pump edildiğinde Flutter aynı
  // State'i koruyor ve yeni denetleyici hiç kullanılmıyordu; anahtar
  // denemeye göre değişir.
  int pumpDeneme = 0;

  Future<void> pumpPhone(
    WidgetTester tester, {
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      BirOmurApp(
        key: ValueKey<int>(pumpDeneme++),
        controller: controller,
        themeMode: themeMode,
        // Ekran görüntüsü alırken ses eklentisi yok; sessiz servis
        // verilmezse oynatıcı kurulmaya çalışılıyor.
        sound: SoundService.silent(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> startLife(
    WidgetTester tester, {
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    await pumpPhone(tester, themeMode: themeMode);
    await tester.tap(find.text('Rastgele bir hayat'));
    await tester.pumpAndSettle();
  }

  Future<void> shot(WidgetTester tester, String name) =>
      expectLater(find.byType(BirOmurApp), matchesGoldenFile('goldens/$name'));

  Future<void> openTab(WidgetTester tester, String id) async {
    await tester.tap(find.byKey(Key('tab_$id')));
    await tester.pumpAndSettle();
  }

  /// Belirli bir bağdan hayattaki ilk kişi.
  Person? personWith(RelationType relation) {
    for (final Person p in controller.state!.people) {
      if (p.isAlive && p.relation == relation) return p;
    }
    return null;
  }

  /// Hedefe ulaşana kadar tercih edilen seçeneklerle ilerler.
  Future<void> advanceUntil(
    WidgetTester tester,
    bool Function() done, {
    required List<String> prefer,
    int maxAges = 45,
  }) async {
    int guard = 0;
    while (!done() && guard++ < maxAges) {
      // Sağlık krizi olay penceresinden önce gelir (D-044); kriz açıkken
      // olay düğmeleri ekranda olmaz. Bildirimler de olaydan önce gelir
      // (D-050).
      await answerPendingCrisis(tester, controller);
      await answerPendingNotices(tester, controller);
      while (controller.state!.hasPendingEvent) {
        if (controller.state!.deceased) return;
        await answerPendingCrisis(tester, controller);
        await answerPendingNotices(tester, controller);
        await tester.pumpAndSettle();
        final ActiveEvent event = controller.state!.pendingEvent!;
        final EventChoice choice = event.choices.firstWhere(
          (EventChoice c) => prefer.contains(c.id),
          orElse: () => event.choices.first,
        );
        await tester.tap(find.text(choice.label));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Devam'));
        await tester.pumpAndSettle();
        if (done()) return;
      }
      if (done()) return;
      if (controller.state!.deceased) return;
      await tester.tap(find.byKey(const Key('age_up_button')));
      await tester.pumpAndSettle();
    }
  }

  testWidgets('başlangıç ekranı', (WidgetTester tester) async {
    await pumpPhone(tester);
    await shot(tester, '01_baslangic.png');
  }, skip: !enabled);

  testWidgets('ana ekran: üst özet, günlük, alt menü ve Yaş Al',
      (WidgetTester tester) async {
    await startLife(tester);
    await ageTo(tester, controller, 9);
    await shot(tester, '02_hayat.png');
  }, skip: !enabled);

  testWidgets('İlişkiler: anne-baba üstte, alt menüler', (WidgetTester tester) async {
    await startLife(tester);
    await ageTo(tester, controller, 9);
    await openTab(tester, 'iliskiler');
    await shot(tester, '03_iliskiler.png');
  }, skip: !enabled);

  testWidgets('Varlıklar: cüzdan ve sahip olunanlar', (WidgetTester tester) async {
    await startLife(tester);
    await ageTo(tester, controller, 9);
    await openTab(tester, 'varliklar');
    await shot(tester, '04_varliklar.png');
  }, skip: !enabled);

  testWidgets('Okul: kademe paneli, sınav yılı ve okul arkadaşları',
      (WidgetTester tester) async {
    await startLife(tester);
    // 13 yaş = ortaokulun son sınıfı: hem kademe paneli hem de sınav yılı
    // paneli (Paket 17) ekranda olur. Eskiden "arkadaş edinilene kadar
    // ilerle" deniyordu; olay havuzu büyüdükçe bu bazen 45 yaşa kadar
    // gidiyor ve okul ekranı hiç görünmüyordu.
    await ageTo(tester, controller, 13);
    await openTab(tester, 'okul_meslek');
    await shot(tester, '05_okul.png');
  }, skip: !enabled);

  testWidgets('Aktiviteler: iç içe menü', (WidgetTester tester) async {
    await startLife(tester);
    await ageTo(tester, controller, 9);
    await openTab(tester, 'aktiviteler');
    await shot(tester, '06_aktiviteler.png');
  }, skip: !enabled);

  testWidgets('Yaş alınca çıkan tek olay', (WidgetTester tester) async {
    await startLife(tester);
    int guard = 0;
    while (!controller.state!.hasPendingEvent && guard++ < 30) {
      await tester.tap(find.byKey(const Key('age_up_button')));
      await tester.pumpAndSettle();
    }
    expect(controller.state!.hasPendingEvent, isTrue);
    await shot(tester, '07_olay.png');
  }, skip: !enabled);

  testWidgets('kişi detayında ortak geçmiş', (WidgetTester tester) async {
    await startLife(tester);
    await ageTo(tester, controller, 14);
    // Ortak geçmiş gerçek kayıtlardan doğar; bu ekran için hediye ve
    // günlük satırı eklenir.
    final Person anne = personWith(RelationType.anne)!;
    controller.debugSetState(
      controller.state!.copyWith(
        gifts: <GiftRecord>[
          GiftRecord(
            itemId: 'yoyo',
            fromId: anne.id,
            toId: GiftRecord.playerId,
            age: 6,
          ),
        ],
        log: <LifeLogEntry>[
          ...controller.state!.log,
          LifeLogEntry(
            age: 9,
            text: '${anne.firstName} ile pazara gittiniz; '
                'dönüşte poşetleri sen taşıdın.',
            category: LogCategory.aile,
            personId: anne.id,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await openTab(tester, 'iliskiler');
    await tapMenuRow(tester, anne.fullName);
    await shot(tester, '11_ortak_gecmis.png');
  }, skip: !enabled);

  testWidgets('kişi detayı ve etkileşim sonucu', (WidgetTester tester) async {
    await startLife(tester);
    await ageTo(tester, controller, 9);
    await openTab(tester, 'iliskiler');

    final Person anne = personWith(RelationType.anne)!;
    await tapMenuRow(tester, anne.fullName);
    await tester.tap(find.text('Vakit Geçir'));
    await tester.pumpAndSettle();
    await shot(tester, '08_etkilesim.png');
  }, skip: !enabled);

  testWidgets('karanlık mod: ana ekran okunaklı kalır',
      (WidgetTester tester) async {
    await startLife(tester, themeMode: ThemeMode.dark);
    await ageTo(tester, controller, 9);
    await shot(tester, '10_karanlik_mod.png');
  }, skip: !enabled);

  testWidgets('ayrılıktan sonra aynı kişi eski sevgili olarak kalır',
      (WidgetTester tester) async {
    // Bu ekran romantik zincirin tamamlandığı bir hayat ister. Olay
    // havuzu her büyüdüğünde aynı tohumdaki akış değiştiği için tohum
    // sabitlenmez: zinciri tamamlayan ilk tohum kullanılır.
    Person? partner;
    for (int deneme = 0; deneme < 25 && partner == null; deneme++) {
      controller.dispose();
      controller = GameController(random: Random(12 + deneme));
      await startLife(tester);
      await advanceUntil(
        tester,
        () => personWith(RelationType.sevgili) != null,
        prefer: <String>['selam', 'teklif'],
        maxAges: 60,
      );
      partner = personWith(RelationType.sevgili);
    }
    expect(partner, isNotNull, reason: 'Hiçbir tohumda sevgili edinilemedi.');

    await openTab(tester, 'iliskiler');
    // İlişkiler menüsü büyüdü; satırlar kaydırılarak açılır.
    await tapMenuRow(tester, 'Romantik bağlar');
    await tapMenuRow(tester, partner!.fullName);
    // Kişi kartı ortak geçmişle birlikte uzadı; eylem satırı
    // kaydırılarak açılır.
    await tapMenuRow(tester, 'Ayrıl');
    await tester.tap(find.widgetWithText(FilledButton, 'Ayrıl').last);
    await tester.pumpAndSettle();

    await shot(tester, '09_eski_sevgili.png');
  }, skip: !enabled);

  testWidgets('karakter yüzü: yaşa, cinsiyete ve ruh haline göre',
      (WidgetTester tester) async {
    // Yüz koddan çizilir; bu ekran görüntüsü yaşa, saç stiline, mutluluğa
    // ve sağlığa göre gerçekten değiştiğini gözle doğrulamak içindir.
    tester.view.physicalSize = const Size(1080, 1620);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    PlayerCharacter yuz({
      required int age,
      required Gender gender,
      int happiness = 70,
      int health = 75,
      String? hair,
    }) =>
        PlayerCharacter(
          id: 'x',
          firstName: 'Deniz',
          lastName: 'Yılmaz',
          gender: gender,
          age: age,
          birthCity: 'Gaziantep',
          hairStyle: hair,
          stats: Stats(
            appearance: 50,
            happiness: happiness,
            health: health,
            intelligence: 50,
            charisma: 50,
          ),
        );

    final List<({String etiket, PlayerCharacter kisi})> ornekler =
        <({String etiket, PlayerCharacter kisi})>[
      (etiket: '1 yaş', kisi: yuz(age: 1, gender: Gender.kadin)),
      (etiket: '7 yaş', kisi: yuz(age: 7, gender: Gender.erkek)),
      (
        etiket: '16 · dağınık',
        kisi: yuz(age: 16, gender: Gender.erkek, hair: 'Dağınık')
      ),
      (
        etiket: '25 · uzun',
        kisi: yuz(age: 25, gender: Gender.kadin, hair: 'Uzun ve toplu')
      ),
      (etiket: 'mutsuz', kisi: yuz(age: 30, gender: Gender.kadin, happiness: 5)),
      (etiket: 'hasta', kisi: yuz(age: 34, gender: Gender.erkek, health: 10)),
      (etiket: '60 yaş', kisi: yuz(age: 60, gender: Gender.erkek)),
      (etiket: '78 yaş', kisi: yuz(age: 78, gender: Gender.kadin)),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: BirOmurTheme.light(),
        home: PaperBackground(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Wrap(
                spacing: 18,
                runSpacing: 18,
                alignment: WrapAlignment.center,
                children: <Widget>[
                  for (final ({String etiket, PlayerCharacter kisi}) o
                      in ornekler)
                    SizedBox(
                      width: 148,
                      child: ComicCard(
                        padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            CharacterFace(player: o.kisi, size: 92),
                            const SizedBox(height: 6),
                            Text(
                              o.etiket,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: BirOmurTheme.yaziTipi,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/12_karakter_yuzu.png'),
    );
  }, skip: !enabled);

  testWidgets('13 — hayat sonu değerlendirmesi', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 3400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Dolu bir hayat: evlilik, çocuk, iş, gezi ve okul kaydı olsun ki
    // değerlendirme gerçekten anlatacak bir şey bulsun.
    final GameState temel =
        LifeGenerator.seeded(8).generate(mode: StartMode.tamamenRastgele);
    final Person es = temel.people.first.copyWith(
      firstName: 'Nurten',
      relation: RelationType.es,
      bond: 82,
      age: 76,
    );
    final GameState hayat = temel.copyWith(
      player: temel.player.copyWith(age: 79, wallet: 320000),
      people: <Person>[
        es,
        ...temel.people.skip(1).map((Person p) => p.copyWith(bond: 55)),
      ],
      marriage: Marriage(
        spouseId: es.id,
        marriedAtAge: 26,
        status: MarriageStatus.evli,
      ),
      education: const EducationState(finished: true, startedAtAge: 6),
      career: CareerState(
        pastJobIds: const <String>['ogretmen'],
        history: <JobHistoryEntry>[
          const JobHistoryEntry(
            jobId: 'ogretmen',
            startedAtAge: 23,
            endedAtAge: 61,
          ),
        ],
        retiredAtAge: 61,
      ),
      trips: <TripRecord>[
        const TripRecord(
          id: 'g1',
          city: 'Trabzon',
          age: 34,
          mode: TravelMode.otobus,
          cost: 2200,
        ),
        const TripRecord(
          id: 'g2',
          city: 'Antalya',
          age: 52,
          mode: TravelMode.ucak,
          cost: 7800,
        ),
      ],
      deceased: true,
      deathAge: 79,
      deathCause: 'yaşlılığa bağlı nedenler',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: BirOmurTheme.light(),
        home: Scaffold(
          body: PaperBackground(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: LifeVerdictPanel(
                verdict: LifeVerdictBuilder.build(hayat),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/13_hayat_degerlendirmesi.png'),
    );
  }, skip: !enabled);


  testWidgets('14 — aktiviteler menüsü (yetişkin, tam liste)',
      (WidgetTester tester) async {
    // Menü uzundur; gruplanmış hâli bir bakışta görünmeli.
    tester.view.physicalSize = const Size(1080, 4200);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      BirOmurApp(
        key: ValueKey<int>(pumpDeneme++),
        controller: controller,
        sound: SoundService.silent(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rastgele bir hayat'));
    await tester.pumpAndSettle();

    final GameState temel = controller.state!;
    controller.debugSetState(
      temel.copyWith(
        pendingEvent: null,
        notices: const <PendingNotice>[],
        player: temel.player.copyWith(age: 30, wallet: 250000),
        licenses: <String>{'otomobil_ehliyeti'},
      ),
    );
    await tester.pumpAndSettle();
    await openTab(tester, 'aktiviteler');
    await shot(tester, '14_aktiviteler_menu.png');
  }, skip: !enabled);
}
