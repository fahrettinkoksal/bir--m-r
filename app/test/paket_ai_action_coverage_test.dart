// Paket AI — oyuncu aksiyonu kapsamı (§1, §2).
//
// **Soru:** oyuncunun yapabildiği her şey gerçekten test ediliyor mu?
//
// Olay kapsamıyla karıştırılmamalı: 391 olayın 381'ini görmek, oyuncu
// aksiyonlarının denendiği anlamına gelmez. Buradaki payda
// `GameController`'ın **durumu değiştirebilen** üyeleri; envanter
// koddan üretiliyor (`support/action_inventory.dart`), elle tutulan bir
// liste yok.
// ignore_for_file: avoid_print
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/action_inventory.dart';
import 'support/coverage_bot.dart';

bool get _tamOlcum => Platform.environment['BIR_OMUR_FULL_MEASURE'] == '1';

/// Plan başına hayat. Kapsam hayatları pahalı: her yıl bütün menüler
/// taranıyor.
int get _planBasina => _tamOlcum ? 40 : 6;

void main() {
  test('Paket AI — aksiyon envanteri koddan üretiliyor (§1)', () {
    final List<ControllerMember> hepsi = controllerInventory();
    final Map<ActionKind, int> say = <ActionKind, int>{};
    for (final ControllerMember m in hepsi) {
      say[m.kind] = (say[m.kind] ?? 0) + 1;
    }
    print('');
    print('-- §1 ENVANTER (game_controller.dart okunarak) --');
    print('toplam public uye ${hepsi.length} · '
        'oyuncu aksiyonu ${say[ActionKind.action] ?? 0} · '
        'sorgu ${say[ActionKind.query] ?? 0} · '
        'oyun disi ${say[ActionKind.outOfGame] ?? 0}');
    print('oyun disi sayilanlar ve gerekcesi:');
    for (final MapEntry<String, String> e in kOutOfGameMembers.entries) {
      print('  ${e.key.padRight(26)} ${e.value}');
    }
    // Envanterin gerçekten koddan geldiğini sabitle: elle yazılmış bir
    // liste olsaydı bu sayı dosya değişince eskir ve sessizce yalan
    // söylerdi.
    expect(hepsi.length, greaterThan(150),
        reason: 'Envanter boş çıkıyorsa kaynak dosya okunamamış demektir.');
    expect(playerActions().length, greaterThan(80));
  });

  test('Paket AI — CoverageBot aksiyon kapsamı (§2)', () {
    final ActionLog toplam = ActionLog();
    final List<CoverageResult> hayatlar = <CoverageResult>[];
    for (final CoveragePlan plan in CoveragePlan.values) {
      for (int i = 0; i < _planBasina; i++) {
        final CoverageResult r = runCoverageLife(
          plan: plan,
          seed: 5100000 + plan.index * 7717 + i * 31,
        );
        hayatlar.add(r);
        toplam.merge(r.log);
      }
    }

    final List<String> aksiyonlar = playerActions();
    final Set<String> kapsanan =
        toplam.covered.where(aksiyonlar.contains).toSet();
    final Set<String> denenenAmaOlmayan =
        toplam.attemptedOnly.where(aksiyonlar.contains).toSet();
    final Set<String> hicDenenmeyen = aksiyonlar
        .where((String a) => !toplam.records.containsKey(a))
        .toSet();

    print('');
    print(_tamOlcum
        ? '=== PAKET AI — TAM KAPSAM: ${hayatlar.length} hedefli hayat ==='
        : '=== PAKET AI — HAFIF BEKCI: ${hayatlar.length} hayat. Tam olcum '
            'icin BIR_OMUR_FULL_MEASURE=1 ===');
    print('${CoveragePlan.values.length} plan x $_planBasina hayat');
    print('');
    print('-- §2 ACTION COVERAGE --');
    print('toplam oyuncu aksiyonu      ${aksiyonlar.length}');
    print('CoverageBot ile calisan     ${kapsanan.length}');
    print('denendi ama kosulu olusmadi ${denenenAmaOlmayan.length}');
    print('hic denenmedi               ${hicDenenmeyen.length}');
    print('ACTION COVERAGE             '
        '%${(kapsanan.length / aksiyonlar.length * 100).toStringAsFixed(1)}');
    print('');
    if (denenenAmaOlmayan.isNotEmpty) {
      print('denendi ama hic uygulanmadi:');
      for (final String a in denenenAmaOlmayan.toList()..sort()) {
        final ActionRecord kayit = toplam.records[a]!;
        print('  ${a.padRight(26)} deneme ${kayit.attempts}'
            '${kayit.lastBlock.isEmpty ? '' : '  engel: ${kayit.lastBlock}'}');
      }
      print('');
    }
    if (hicDenenmeyen.isNotEmpty) {
      print('CoverageBot hic denemedi (bot eksigi):');
      for (final String a in hicDenenmeyen.toList()..sort()) {
        print('  $a');
      }
      print('');
    }

    // ---- Takılma ------------------------------------------------------
    final List<CoverageResult> takilan = hayatlar
        .where((CoverageResult r) => !r.endedByDeath)
        .toList(growable: false);
    final Map<String, int> sebep = <String, int>{};
    for (final CoverageResult r in takilan) {
      final String k = r.stuckReason ?? 'bilinmiyor';
      sebep[k] = (sebep[k] ?? 0) + 1;
    }
    print('takilan hayat ${takilan.length}/${hayatlar.length} $sebep');

    // ---- İçerik kapsamı ------------------------------------------------
    Set<String> topla(Set<String> Function(CoverageResult) f) => <String>{
          for (final CoverageResult r in hayatlar) ...f(r),
        };
    print('');
    print('-- CoverageBot icerik --');
    print('isletme turu  ${topla((CoverageResult r) => r.businessTypes).length}'
        ' · hobi ${topla((CoverageResult r) => r.hobbies).length}'
        ' · dovus ${topla((CoverageResult r) => r.martialArts).length}'
        ' · kitap ${topla((CoverageResult r) => r.books).length}'
        ' · meslek ${topla((CoverageResult r) => r.jobIds).length}'
        ' · bolum ${topla((CoverageResult r) => r.programIds).length}'
        ' · hayvan ${topla((CoverageResult r) => r.petSpecies).length}'
        ' · platform ${topla((CoverageResult r) => r.socialPlatforms).length}'
        ' · yatirim ${topla((CoverageResult r) => r.investmentTypes).length}'
        ' · esya ${topla((CoverageResult r) => r.itemTypeIds).length}');
    print('olay-secenek kolu ${topla((CoverageResult r) => r.eventChoices).length}');
    // Hobi kapsamı düşükse sebebi oyunun kendi cümlesiyle yazılsın.
    final Set<String> gorulenHobi = topla((CoverageResult r) => r.hobbies);
    final Map<String, String> engeller = <String, String>{};
    for (final CoverageResult r in hayatlar) {
      engeller.addAll(r.blockedActivities);
    }
    print('hobi ilerleyen: ${gorulenHobi.join(', ')}');
    print('acilamayan aktivite (${engeller.length}):');
    for (final MapEntry<String, String> e in engeller.entries) {
      print('  ${e.key.padRight(22)} ${e.value}');
    }

    // ---- Bekçiler -----------------------------------------------------
    //
    // Bu tur teşhis; buradaki tek sabit, kapsamın **geriye gitmemesi**.
    // Ölçülen değer dondurulmuyor, taban konuyor.
    expect(takilan, isEmpty,
        reason: 'Kapsam hayatı takıldıysa ölçüm güvenilmez: $sebep');
    expect(kapsanan.length / aksiyonlar.length, greaterThan(0.5),
        reason: 'Oyuncu aksiyonlarının yarısına bile dokunulmuyorsa '
            'kapsam ölçümü anlamını yitirir.');
  }, timeout: const Timeout(Duration(minutes: 60)));
}
