// Paket AL §49 — küçük simülasyon: 6 sanat × 100 hedefli sporcu hayatı.
//
// Bu tur **genel 3000 hayat denetimi değil** (§48-§49). Yalnızca yeni
// spor kariyerinin dağılımı ölçülüyor: kim rekabete başlıyor, kim elit
// seviyeye çıkıyor, kim şampiyon oluyor, kim erken bırakıyor, kim ciddi
// sakatlanıyor, gelir nasıl dağılıyor.
//
// Sporcu botu **hile yapmıyor**: debugSetState ile para/stat/basamak
// verilmiyor. Ders parası cüzdandan çıkıyor, teknik basamak gerçekten
// ders alarak kazanılıyor.
//
// Ölçüm çıktısı doğrudan konsola yazılıyor; rapor buradan üretiliyor.
// ignore_for_file: avoid_print
library;

import 'dart:math';

import 'package:bir_omur/data/combat_circuit_catalog.dart';
import 'package:bir_omur/data/economy.dart';
import 'package:bir_omur/data/martial_arts_catalog.dart';
import 'package:bir_omur/domain/activities/martial_arts_engine.dart';
import 'package:bir_omur/domain/combat/combat_career_engine.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/combat_career.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:flutter_test/flutter_test.dart';

const MartialArtsEngine _dersler = MartialArtsEngine();

/// Bir sporcu hayatının özeti.
class _Kariyer {
  _Kariyer(this.artId);

  final String artId;
  bool rekabeteBasladi = false;
  bool elitOldu = false;
  bool sampiyonOldu = false;
  bool erkenBirakti = false;
  bool ciddiSakatlandi = false;
  int galibiyet = 0;
  int maglubiyet = 0;
  int gelir = 0;
  int sonYas = 0;
  int sampiyonlukSayisi = 0;
}

/// Hedefli bir sporcu hayatı oynar.
///
/// Bot "oyunu çözmeye" çalışmıyor; sıradan bir sporcu gibi davranıyor:
/// parası yettiği kadar ders alıyor, fırsat çıkınca müsabakaya
/// çıkıyor, parası varsa kamp yapıyor, baskı gelince bırakıyor.
_Kariyer _hayatOyna(String artId, int seed) {
  final MartialArt art =
      MartialArt.values.firstWhere((MartialArt a) => a.id == artId);
  final CombatCircuit yol = combatCircuitFor(artId)!;
  final Random rng = Random(seed);
  final _Kariyer ozet = _Kariyer(artId);

  GameState s =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  // Sporcunun ders parası olmalı; bu bir gelir simülasyonu değil,
  // kariyer dağılımı simülasyonu. Harçlık gerçekçi bir bantta tutuluyor.
  final int yillikHarclik =
      (Economy.netYearlyMinimumWage * (0.10 + rng.nextDouble() * 0.25)).round();

  s = s.copyWith(
    player: s.player.copyWith(
      age: art.minAge,
      wallet: yillikHarclik,
      stats: s.player.stats.copyWith(
        health: 62 + rng.nextInt(30),
      ),
    ),
    pendingEvent: null,
  );

  for (int yas = art.minAge; yas <= 46; yas++) {
    s = s.copyWith(
      player: s.player.copyWith(age: yas, wallet: s.player.wallet + yillikHarclik),
      // Yıllık sayaçlar yaş başında sıfırlanır (oyunun kendi kuralı).
      interactionCounts: const <String, int>{},
    );

    // 1) Teknik çalışma: parası yettiği kadar.
    if (_dersler.availability(s, art).isAllowed) {
      s = _dersler.takeSeason(state: s, art: art).state;
    }

    // 2) Rekabete başla.
    final CombatCareer? kariyer = CombatCareerEngine.activeCareer(s);
    if (kariyer == null &&
        CombatCareerEngine.startAvailability(s, art).isAllowed) {
      s = CombatCareerEngine.startCompeting(s, art).state;
      ozet.rekabeteBasladi = true;
    }

    // 3) Yıllık akış: form, sakatlık, koç, sıralama.
    s = CombatCareerEngine.advanceYear(s, yas, rng).state;

    // 4) Müsabakalar: fırsat çıktıkça.
    for (int i = 0; i < 4; i++) {
      final k = CombatCareerEngine.activeCareer(s);
      if (k == null || k.isRetired) break;
      final firsat = CombatCareerEngine.offerBout(s, rng);
      s = firsat.state;
      if (firsat.bout == null) break;

      // Kamp tercihi: para varsa yoğun, sağlık düşükse dinlen.
      final CampChoice kamp = s.player.stats.health < 55
          ? CampChoice.dinlen
          : s.player.wallet >
                  CombatCareerEngine.campCost(CampChoice.yogun) * 2
              ? CampChoice.yogun
              : CampChoice.dengeli;
      final BoutResult r = CombatCareerEngine.fight(s, kamp);
      if (!r.applied) break;
      s = r.state;
      if (r.injury == InjurySeverity.ciddi) ozet.ciddiSakatlandi = true;
    }

    // 5) Sponsor.
    s = CombatCareerEngine.offerSportSponsor(s, rng).state;

    // 6) Emeklilik baskısı.
    final RetirementReason? baski = CombatCareerEngine.retirementPressure(s);
    if (baski != null) {
      s = CombatCareerEngine.retire(s, baski).state;
      if (yas < 30) ozet.erkenBirakti = true;
      break;
    }

    ozet.sonYas = yas;
  }

  final CombatCareer? k = CombatCareerEngine.careerFor(s, artId);
  if (k != null) {
    ozet.galibiyet = k.totalWins;
    ozet.maglubiyet = k.totalLosses;
    ozet.gelir = k.careerEarnings + k.sponsorEarnings;
    ozet.elitOldu = k.tier >= yol.turnsProAtTier;
    ozet.sampiyonOldu = k.championships > 0;
    ozet.sampiyonlukSayisi = k.championships;
    if (k.seriousInjuryCount > 0) ozet.ciddiSakatlandi = true;
  }
  return ozet;
}

int _medyan(List<int> v) {
  if (v.isEmpty) return 0;
  final List<int> s = List<int>.from(v)..sort();
  return s[s.length ~/ 2];
}

int _yuzdelik(List<int> v, double p) {
  if (v.isEmpty) return 0;
  final List<int> s = List<int>.from(v)..sort();
  return s[((s.length - 1) * p).round().clamp(0, s.length - 1)];
}

void main() {
  test('Paket AL §49 — 6 sanat x 100 sporcu = 600 kariyer', () {
    const int herSanat = 100;
    final Map<String, List<_Kariyer>> hepsi = <String, List<_Kariyer>>{};

    for (final CombatCircuit yol in kCombatCircuits) {
      final List<_Kariyer> liste = <_Kariyer>[];
      for (int i = 0; i < herSanat; i++) {
        liste.add(_hayatOyna(yol.artId, 70000 + i * 13 + yol.artId.hashCode));
      }
      hepsi[yol.artId] = liste;
    }

    print('');
    print('=' * 72);
    print('PAKET AL §49 — 600 SPORCU KARİYERİ');
    print('=' * 72);
    print('');
    print('sanat        rekabet  elit  şampiyon  erken  ciddi   medyan');
    print('               %       %       %      bırak  sakat   gelir');

    final List<int> tumGelirler = <int>[];
    final Map<String, int> sampiyonSayilari = <String, int>{};

    for (final CombatCircuit yol in kCombatCircuits) {
      final List<_Kariyer> l = hepsi[yol.artId]!;
      final int rekabet = l.where((_Kariyer k) => k.rekabeteBasladi).length;
      final int elit = l.where((_Kariyer k) => k.elitOldu).length;
      final int sampiyon = l.where((_Kariyer k) => k.sampiyonOldu).length;
      final int erken = l.where((_Kariyer k) => k.erkenBirakti).length;
      final int sakat = l.where((_Kariyer k) => k.ciddiSakatlandi).length;
      final List<int> gelirler =
          l.where((_Kariyer k) => k.rekabeteBasladi).map((_Kariyer k) => k.gelir).toList();
      tumGelirler.addAll(gelirler);
      sampiyonSayilari[yol.artId] = sampiyon;

      print('${yol.art!.label.padRight(13)}'
          '${rekabet.toString().padLeft(4)}  '
          '${elit.toString().padLeft(5)} '
          '${sampiyon.toString().padLeft(7)} '
          '${erken.toString().padLeft(7)} '
          '${sakat.toString().padLeft(6)} '
          '${_medyan(gelirler).toString().padLeft(9)}');
    }

    final int toplamRekabet =
        hepsi.values.expand((l) => l).where((_Kariyer k) => k.rekabeteBasladi).length;
    final int toplamSampiyon =
        hepsi.values.expand((l) => l).where((_Kariyer k) => k.sampiyonOldu).length;
    final int toplamElit =
        hepsi.values.expand((l) => l).where((_Kariyer k) => k.elitOldu).length;

    print('');
    print('TOPLAM 600 sporcu:');
    print('  rekabete başlayan  $toplamRekabet '
        '(%${(toplamRekabet / 6).toStringAsFixed(1)})');
    print('  elit/pro seviye    $toplamElit '
        '(%${(toplamElit / 6).toStringAsFixed(1)})');
    print('  şampiyon olan      $toplamSampiyon '
        '(%${(toplamSampiyon / 6).toStringAsFixed(1)})');
    print('');
    print('Kariyer geliri (rekabete başlayanlar, ₺):');
    print('  en kötü %10  ${_yuzdelik(tumGelirler, 0.10)}');
    print('  medyan       ${_medyan(tumGelirler)}');
    print('  en iyi %10   ${_yuzdelik(tumGelirler, 0.90)}');
    print('  en iyi       ${tumGelirler.isEmpty ? 0 : tumGelirler.reduce(max)}');
    print('  (net yıllık asgari ücret ${Economy.netYearlyMinimumWage} ₺)');
    print('');

    // --- İDDİALAR ---------------------------------------------------

    // §41: büyük başarı NADİR olsun ama imkânsız olmasın.
    //
    // DİKKAT — bu kohort sıradan bir hayat değil: bot her yıl
    // çalışıyor, her fırsatı değerlendiriyor ve yalnızca oyun zorlayınca
    // bırakıyor. Yani buradaki oranlar "kendini tamamen adamış
    // sporcular" için geçerli; rastgele bir oyuncunun oranı çok daha
    // düşüktür. Band bilerek geniş: regresyon yakalar, ince ayarı
    // dayatmaz. Ölçülen değer 18,2 ve bu sayının doğru his olup
    // olmadığı Q-182'de Faho'ya soruldu.
    expect(toplamSampiyon, greaterThan(6),
        reason: '600 adanmış sporcuda şampiyonluk pratikte kapalı.');
    expect(toplamSampiyon, lessThan(240),
        reason: 'Adanmış sporcuların %40\'ı şampiyon oluyorsa başarı ucuz.');

    // Rekabet gerçekten açılıyor.
    expect(toplamRekabet, greaterThan(300),
        reason: 'Sporcuların çoğu rekabete hiç başlayamıyor.');

    // §40: çoğu sporcu orta düzeyde kalıyor, bir kısmı çok kazanıyor.
    expect(_medyan(tumGelirler), lessThan(Economy.netYearlyMinimumWage * 12),
        reason: 'Spor otomatik zenginlik makinesine dönmüş.');
    expect(_yuzdelik(tumGelirler, 0.90),
        greaterThan(_medyan(tumGelirler)),
        reason: 'Gelir dağılımı düz; iyi sporcu ayrışmıyor.');

    // §1: tek sanat baskın olmasın.
    final List<int> sampiyonlar = sampiyonSayilari.values.toList()..sort();
    if (sampiyonlar.last > 0) {
      expect(sampiyonlar.first, greaterThan(0),
          reason: 'Bir sanatta hiç şampiyon çıkmıyor: yol tıkalı.');
      expect(sampiyonlar.last, lessThan(sampiyonlar.first * 8 + 10),
          reason: 'Tek sanat şampiyonlukta baskın.');
    }

    // Absürt sonuç yok: kimse negatif rekor ya da uçuk gelir taşımıyor.
    for (final _Kariyer k in hepsi.values.expand((l) => l)) {
      expect(k.galibiyet, greaterThanOrEqualTo(0));
      expect(k.maglubiyet, greaterThanOrEqualTo(0));
      expect(k.gelir, greaterThanOrEqualTo(0));
      expect(k.gelir, lessThan(Economy.netYearlyMinimumWage * 200),
          reason: 'Absürt kariyer geliri: ${k.artId} ${k.gelir}');
    }
  });
}
