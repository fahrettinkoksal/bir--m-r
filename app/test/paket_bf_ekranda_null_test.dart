// Ekranda ham `null` görünmez.
//
// **Nasıl bulundu.** Bot dökümü (`ekran_dokumu_bot_test.dart`) eğitim
// odaklı hayatı 21 yaşında — üniversitenin 4. sınıfında — bastı ve
// Okul ekranında şu satır çıktı:
//
//     Okul
//     Sınıf
//     null. sınıf
//
// **Kök neden.** `_SchoolView` hem 1-12. sınıf hem **üniversite**
// öğrencisine gösteriliyor (`EducationState.isStudent = enrolled ||
// isUniversityStudent`). Kartın satırları K-12 için yazılmış ve
// komşularının hepsinde `!= null` koruması var — eksik olan tek satır
// "Sınıf"tı: `'${egitim.grade}. sınıf'` koşulsuz kuruluyordu ve
// üniversitede `grade` boş. Aynı sebeple "Son sınıfa kalan" da
// `?? 12` ile "0 yıl" yazıyordu; o sayı 12. sınıfa kalan yılı anlatır,
// üniversite öğrencisi için anlamı yok. İkisi de koşula alındı.
//
// Üniversite öğrencisine K-12 kartının gösterilmesi ayrı bir konu;
// karar Faho'ya bırakıldı (Q-198 EKİ). Burada düzeltilen şey oyuncunun
// ekranında **ham bir `null`** görmesi.
//
// Bu dosya iki şey yapar: (1) üniversite öğrencisinin ekranında o
// satırların çıkmadığını, K-12 öğrencisinde çıktığını sınar,
// (2) **bütün** ekranlardaki görünür metni tarayıp hiçbir yerde "null"
// geçmediğini güvenceye alır — yani aynı desen başka bir satırda
// doğarsa burada yakalanır.
library;

import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/data/university_catalog.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/education.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late GameController controller;

  /// Uygulama bu testte açıldı mı? Her test kendi kontrolcüsüyle
  /// başladığı için sıfırlanır. İlk yazımda her okumada baştan açıp
  /// "Rastgele bir hayat"a basıyordum; ikinci çağrıda o düğme ekranda
  /// olmadığı için test düşüyordu (aynı hatayı bot dökümünde de
  /// yapmıştım).
  bool acildi = false;

  setUp(() {
    controller = GameController(random: Random(19));
    acildi = false;
  });
  tearDown(() => controller.dispose());

  GameState temelHayat() =>
      LifeGenerator.seeded(91).generate(mode: StartMode.tamamenRastgele);

  /// Üniversitede okuyan bir oyuncu.
  GameState universiteli() {
    final GameState s = temelHayat();
    final UniversityProgram bolum = kUniversityPrograms.first;
    return s.copyWith(
      pendingEvent: null,
      player: s.player.copyWith(age: 21),
      education: EducationState(
        finished: true,
        startedAtAge: 6,
        universityProgramId: bolum.id,
        universityYear: 4,
        gradeAverage: 71,
        placementScore: 48,
      ),
    );
  }

  /// 1-12. sınıf öğrencisi.
  GameState liseli() {
    final GameState s = temelHayat();
    return s.copyWith(
      pendingEvent: null,
      player: s.player.copyWith(age: 16),
      education: const EducationState(
        enrolled: true,
        grade: 11,
        startedAtAge: 6,
        gradeAverage: 71,
      ),
    );
  }

  List<String> metinler(WidgetTester tester) {
    final List<String> out = <String>[];
    for (final Text w in tester.widgetList<Text>(find.byType(Text))) {
      final String? d = w.data ?? w.textSpan?.toPlainText();
      if (d == null) continue;
      final String t = d.trim();
      if (t.isNotEmpty) out.add(t);
    }
    return out;
  }

  Future<void> ac(WidgetTester tester, GameState durum) async {
    if (!acildi) {
      tester.view.physicalSize = const Size(1200, 10000);
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

  Future<List<String>> ekraniOku(
    WidgetTester tester,
    GameState durum, {
    String? sekme,
  }) async {
    await ac(tester, durum);
    if (sekme != null) {
      final Finder f = find.byKey(Key(sekme));
      if (f.evaluate().isNotEmpty) {
        await tester.tap(f);
        await tester.pumpAndSettle();
      }
    }
    return metinler(tester);
  }

  testWidgets('üniversite öğrencisinde "null. sınıf" satırı yok',
      (WidgetTester tester) async {
    final List<String> satirlar =
        await ekraniOku(tester, universiteli(), sekme: 'tab_okul_meslek');

    expect(satirlar, isNot(contains('null. sınıf')));
    expect(satirlar.where((String s) => s.contains('null')), isEmpty,
        reason: 'Ekranda ham null: '
            '${satirlar.where((String s) => s.contains("null")).toList()}');
    // "Son sınıfa kalan" da üniversite öğrencisine yazılmaz.
    expect(satirlar, isNot(contains('Son sınıfa kalan')),
        reason: '12. sınıfa kalan yıl üniversite öğrencisi için anlamsız.');
  });

  testWidgets('1-12. sınıf öğrencisinde sınıf satırı yerinde duruyor',
      (WidgetTester tester) async {
    final List<String> satirlar =
        await ekraniOku(tester, liseli(), sekme: 'tab_okul_meslek');

    expect(satirlar, contains('11. sınıf'),
        reason: 'Koruma eklenirken gerçek sınıf satırı da kaybolmamalı.');
    expect(satirlar, contains('Son sınıfa kalan'));
  });

  testWidgets('beş ekranın hiçbirinde "null" geçmiyor (üniversiteli)',
      (WidgetTester tester) async {
    for (final String? sekme in <String?>[
      null,
      'tab_okul_meslek',
      'tab_varliklar',
      'tab_iliskiler',
      'tab_aktiviteler',
    ]) {
      final List<String> satirlar =
          await ekraniOku(tester, universiteli(), sekme: sekme);
      final List<String> kotu =
          satirlar.where((String s) => s.contains('null')).toList();
      expect(kotu, isEmpty,
          reason: '${sekme ?? "Hayat"} ekranında ham null: $kotu');
    }
  });
}
