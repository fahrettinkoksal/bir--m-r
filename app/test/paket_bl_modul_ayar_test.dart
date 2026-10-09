// Paket BL — modül anahtarının **oyuncu tarafı**.
//
// İzolasyon testi motoru ölçüyor; bu dosya gerçek dokunuşu ölçer:
// Ayarlar → Modüller'den anahtarı kapatan oyuncu, çocuğunun kartında o
// satırı bir daha görmemeli. Kapatma kayda da girmeli, yoksa oyun bir
// sonraki açılışta özelliği geri getirir.
import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/domain/features/feature_catalog.dart';
import 'package:bir_omur/domain/generation/child_progression.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/interaction/marriage_engine.dart';
import 'package:bir_omur/domain/interaction/parenthood.dart';
import 'package:bir_omur/domain/interaction/romance.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/person_development.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ayarlar sayfasındaki hedefi görünür yap.
///
/// `scrollUntilVisible` kullanılmıyor: sayfada birden fazla kaydırılabilir
/// alan var ve hangisinin kaydırılacağı belirsiz kalıyor.
Future<void> _ayarlardaGoster(WidgetTester tester, Finder hedef) async {
  if (tester.any(hedef)) {
    await tester.ensureVisible(hedef);
    await tester.pumpAndSettle();
    return;
  }
  throw TestFailure('Ayarlar sayfasında bulunamadı: $hedef');
}

void main() {
  late GameController controller;

  setUp(() => controller = GameController(random: Random(51)));
  tearDown(() => controller.dispose());

  GameState aileliHayat({int cocukYasi = 10}) {
    final GameState base =
        LifeGenerator.seeded(51).generate(mode: StartMode.tamamenRastgele);
    final ({GameState state, Person partner}) r = const Romance().start(
      base.copyWith(player: base.player.copyWith(age: 34, wallet: 900000)),
      Random(2),
    );
    GameState state = r.state.copyWith(
      people: r.state.people
          .map((Person p) => p.id == r.partner.id ? p.copyWith(bond: 90) : p)
          .toList(growable: false),
    );
    state = const MarriageEngine().marry(state, r.partner.id).state;
    state = const Parenthood().haveChild(state, Random(3)).state;
    // Çocuğun okul kaydını motorun kendisi kursun: "öğrenci mi" sorusu
    // Person'ın `employment` alanından değil gelişim kaydından okunuyor
    // ve kural koyma onu şart koşuyor.
    final Random rng = Random(4);
    return state.copyWith(
      people: state.people.map((Person p) {
        if (p.relation != RelationType.cocuk) return p;
        final Person yasli = p.copyWith(age: cocukYasi, development: null);
        final PersonDevelopment kayit =
            ChildProgression.ensureRecord(yasli, rng);
        return yasli.copyWith(
          development: kayit,
          schoolLevel: kayit.schoolLevel ??
              Parenthood.schoolLevelForAge(cocukYasi),
          employment: EmploymentStatus.ogrenci,
        );
      }).toList(growable: false),
    );
  }

  Future<void> pumpApp(WidgetTester tester, GameState state) async {
    // Uzun pencere: liste tembel kurulduğu için ekrana sığmayan satır
    // ağaçta hiç olmuyor. Ölçülecek şey kaydırma değil, modülün
    // görünüp görünmediği.
    tester.view.physicalSize = const Size(1200, 10800);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(BirOmurApp(controller: controller));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rastgele bir hayat'));
    await tester.pumpAndSettle();
    controller.debugSetState(state);
    await tester.pumpAndSettle();
  }

  Future<void> cocugunKartiniAc(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('tab_iliskiler')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('relationships_children_row')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.text(controller.state!.children.single.fullName).first,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('modül açıkken çocuğun kartında satırlar duruyor',
      (WidgetTester tester) async {
    await pumpApp(tester, aileliHayat());
    await cocugunKartiniAc(tester);

    // Paket BK/3'ün dört satırı: üçü bir modül, kural ayrı modül.
    expect(find.text('Ödevine Otur'), findsOneWidget);
    expect(find.text('Harçlık Ver'), findsOneWidget);
    expect(find.text('Kural Koy'), findsOneWidget);
    // Modüllerden önce de vardı; karşılaştırma için.
    expect(find.text('Vakit Geçir'), findsOneWidget);
  });

  testWidgets('ayarlardan kapatılan modül çocuğun kartından kalkıyor',
      (WidgetTester tester) async {
    await pumpApp(tester, aileliHayat());

    // Ayarlar → Modüller: ebeveynlik eylemlerini kapat.
    await tester.tap(find.byKey(const Key('open_settings')));
    await tester.pumpAndSettle();
    final Finder anahtar = find.byKey(
      Key('settings_feature_${FeatureId.ebeveynlikEylemleri.saveKey}'),
    );
    await _ayarlardaGoster(tester, anahtar);
    await tester.tap(anahtar);
    await tester.pumpAndSettle();
    expect(controller.featureOn(FeatureId.ebeveynlikEylemleri), isFalse);
    // Kapatınca ne kaybolduğu oyuncuya yazılı görünüyor.
    expect(
      find.textContaining('Ödevine oturma'),
      findsOneWidget,
      reason: 'Kapatınca ne kaybolduğu ekranda yazmalı.',
    );
    await tester.tap(find.text('Kapat'));
    await tester.pumpAndSettle();

    // Satırlar gitti; kartın geri kalanı yerinde.
    await cocugunKartiniAc(tester);
    expect(find.text('Ödevine Otur'), findsNothing);
    expect(find.text('Harçlık Ver'), findsNothing);
    expect(find.text('Hobiye Yazdır'), findsNothing);
    // Ayrı anahtar: kural koyma kapanmadı.
    expect(find.text('Kural Koy'), findsOneWidget);
    expect(find.text('Vakit Geçir'), findsOneWidget);
  });

  testWidgets('hepsini aç düğmesi modülleri geri getiriyor',
      (WidgetTester tester) async {
    await pumpApp(tester, aileliHayat());

    await tester.tap(find.byKey(const Key('open_settings')));
    await tester.pumpAndSettle();
    for (final FeatureId modul in <FeatureId>[
      FeatureId.ebeveynlikEylemleri,
      FeatureId.cocukKurallari,
    ]) {
      final Finder anahtar =
          find.byKey(Key('settings_feature_${modul.saveKey}'));
      await _ayarlardaGoster(tester, anahtar);
      await tester.tap(anahtar);
      await tester.pumpAndSettle();
    }
    expect(controller.state!.settings.features.offFeatures.length, 2);

    final Finder sifirla = find.byKey(const Key('settings_features_reset'));
    await _ayarlardaGoster(tester, sifirla);
    await tester.tap(sifirla);
    await tester.pumpAndSettle();

    expect(controller.state!.settings.features.allDefault, isTrue);
    for (final FeatureId modul in FeatureId.values) {
      expect(controller.featureOn(modul), isTrue, reason: modul.saveKey);
    }
  });

  test('kapalı modül kayıtta duruyor ve geri yüklenince kapalı geliyor', () {
    final GameState state = aileliHayat();
    final GameState kapali = state.copyWith(
      settings: state.settings.copyWith(
        features: state.settings.features
            .toggled(FeatureId.cocukYilOzeti, false)
            .toggled(FeatureId.gebelikGorunurlugu, false),
      ),
    );

    final GameState geri = decodeGameState(encodeGameState(kapali));

    expect(geri.featureOn(FeatureId.cocukYilOzeti), isFalse);
    expect(geri.featureOn(FeatureId.gebelikGorunurlugu), isFalse);
    expect(geri.featureOn(FeatureId.cocukPlani), isTrue);
    expect(geri.settings.features.overrides.length, 2);
  });
}
