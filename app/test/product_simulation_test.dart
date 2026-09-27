// ignore_for_file: avoid_print
import 'package:bir_omur/data/business_catalog.dart';
import 'package:bir_omur/data/event_pool.dart';
import 'package:bir_omur/data/hobby_catalog.dart';
import 'package:bir_omur/data/investment_catalog.dart';
import 'package:bir_omur/data/job_catalog.dart';
import 'package:bir_omur/data/martial_arts_catalog.dart';
import 'package:bir_omur/data/university_catalog.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/player_bot.dart';

/// **Ürün simülasyonu** — gerçek oyuncu davranışıyla yaşam ölçümü.
///
/// Bu dosya **unit/regresyon testi değildir** ve raporu onlarla
/// karıştırılmaz:
///
/// * **Unit / regresyon** (`test/*_test.dart` geri kalanı): belirli bir
///   sistemi doğrular, hızlıdır, ilk açık seçeneği kullanabilir.
/// * **Ürün simülasyonu** (bu dosya): gerçek oyuncuya benzeyen
///   `PlayerBot` ile oynar, sistemler arası etkileşimi ölçer ve
///   **yalnızca** ürün dengesi tartışması için kullanılır.
///
/// Ölçüm hiçbir dengeyi değiştirmez; sayıları basar, kararı Faho ve
/// ChatGPT verir.
void main() {
  test('OLCUM: 10 arketip x 100 hayat + 500 rastgele hayat', () {
    const int perArchetype = 100;
    const int randomExtra = 500;

    final Map<PlayerArchetype, List<BotLifeResult>> gruplar =
        <PlayerArchetype, List<BotLifeResult>>{};
    final List<BotLifeResult> hepsi = <BotLifeResult>[];

    for (final PlayerArchetype a in PlayerArchetype.values) {
      final List<BotLifeResult> liste = <BotLifeResult>[];
      // Her arketip **farklı tohum bandı** kullanır: aynı hayatları
      // tekrar oynamasın.
      final int taban = 100000 + a.index * 10000;
      for (int i = 0; i < perArchetype; i++) {
        liste.add(playBotLife(archetype: a, seed: taban + i));
      }
      gruplar[a] = liste;
      hepsi.addAll(liste);
    }

    // Ek keşif: 500 rastgele-geçerli hayat, ayrı tohum bandında.
    final List<BotLifeResult> rastgele = <BotLifeResult>[];
    for (int i = 0; i < randomExtra; i++) {
      rastgele.add(
        playBotLife(archetype: PlayerArchetype.randomValid, seed: 900000 + i),
      );
    }
    hepsi.addAll(rastgele);

    // ---- Yardımcılar -------------------------------------------------
    double oran(List<BotLifeResult> l, bool Function(BotLifeResult) f) =>
        l.isEmpty ? 0 : l.where(f).length / l.length * 100;
    double ortalama(List<BotLifeResult> l, num Function(BotLifeResult) f) =>
        l.isEmpty ? 0 : l.fold<num>(0, (num t, BotLifeResult r) => t + f(r)) / l.length;
    int medyan(List<int> l) {
      if (l.isEmpty) return 0;
      final List<int> s = List<int>.from(l)..sort();
      return s[s.length ~/ 2];
    }

    int yuzde(List<int> l, double p) {
      if (l.isEmpty) return 0;
      final List<int> s = List<int>.from(l)..sort();
      return s[(s.length * p).floor().clamp(0, s.length - 1)];
    }

    String k(num v) => '${(v / 1000).round()}k';

    print('=== ${hepsi.length} TAM HAYAT (PlayerBot) ===');
    print('10 arketip x $perArchetype + $randomExtra rastgele-gecerli');

    // ---- Yaşam -------------------------------------------------------
    // **Yalnızca gerçekten ölümle biten hayatlar** ömür ortalamasına
    // girer. Simülasyonun takıldığı hayat (karşılanamayan kriz, yaş
    // ilerlemiyor) ölüm sayılmaz; ayrı raporlanır.
    final List<BotLifeResult> olenler =
        hepsi.where((BotLifeResult r) => r.endedByDeath).toList();
    final List<BotLifeResult> takilanlar =
        hepsi.where((BotLifeResult r) => !r.endedByDeath).toList();
    final Map<String, int> takilmaSebepleri = <String, int>{};
    for (final BotLifeResult r in takilanlar) {
      final String k = r.stuckReason ?? 'bilinmiyor';
      takilmaSebepleri[k] = (takilmaSebepleri[k] ?? 0) + 1;
    }
    final List<int> yaslar =
        olenler.map((BotLifeResult r) => r.deathAge).toList();
    print('\n-- YASAM --');
    print('olumle biten ${olenler.length}/${hepsi.length} · '
        'takilan ${takilanlar.length} $takilmaSebepleri');
    print('ortalama olum yasi ${ortalama(olenler, (BotLifeResult r) => r.deathAge).toStringAsFixed(1)} · '
        'medyan ${medyan(yaslar)} · '
        'kotu%10 ${yuzde(yaslar, 0.10)} · iyi%10 ${yuzde(yaslar, 0.90)}');

    // ---- Eğitim ------------------------------------------------------
    final Set<String> gorulenBolumler = <String>{};
    for (final BotLifeResult r in hepsi) {
      if (r.programId != null) gorulenBolumler.add(r.programId!);
    }
    print('\n-- EGITIM --');
    print('universiteye giden %${oran(hepsi, (BotLifeResult r) => r.wentToUniversity).toStringAsFixed(1)} · '
        'mezun %${oran(hepsi, (BotLifeResult r) => r.graduatedUniversity).toStringAsFixed(1)} · '
        'lise bitiren %${oran(hepsi, (BotLifeResult r) => r.finishedHighSchool).toStringAsFixed(1)}');
    print('bolum cesitliligi: ${gorulenBolumler.length}/${kUniversityPrograms.length}');

    // ---- Kariyer -----------------------------------------------------
    final Set<String> gorulenIsler = <String>{};
    final Map<String, int> isSayilari = <String, int>{};
    for (final BotLifeResult r in hepsi) {
      for (final String id in r.jobIds) {
        gorulenIsler.add(id);
        isSayilari[id] = (isSayilari[id] ?? 0) + 1;
      }
    }
    final List<String> enSik = isSayilari.keys.toList()
      ..sort((String a, String b) => isSayilari[b]!.compareTo(isSayilari[a]!));
    final Set<String> hicGirilmeyen = kJobCatalog
        .map((JobType j) => j.id)
        .where((String id) => !gorulenIsler.contains(id))
        .toSet();
    print('\n-- KARIYER --');
    print('calisan %${oran(hepsi, (BotLifeResult r) => r.everEmployed).toStringAsFixed(1)} · '
        'emekli %${oran(hepsi, (BotLifeResult r) => r.retired).toStringAsFixed(1)} · '
        'genclikte yarim zamanli %${oran(hepsi, (BotLifeResult r) => r.partTime).toStringAsFixed(1)}');
    print('ortalama farkli is ${ortalama(hepsi, (BotLifeResult r) => r.jobIds.length).toStringAsFixed(2)} · '
        'ortalama is degisimi ${ortalama(hepsi, (BotLifeResult r) => r.jobChanges).toStringAsFixed(2)}');
    print('zam istegi ${ortalama(hepsi, (BotLifeResult r) => r.raiseAttempts).toStringAsFixed(1)} · '
        'terfi ${ortalama(hepsi, (BotLifeResult r) => r.promotions).toStringAsFixed(2)} · '
        'meslek itibari ${ortalama(hepsi, (BotLifeResult r) => r.masteryReputation).toStringAsFixed(1)}/100');
    print('gorulen is: ${gorulenIsler.length}/${kJobCatalog.length}');
    print('en sik 10: ${enSik.take(10).join(', ')}');
    print('hic girilmeyen (${hicGirilmeyen.length}): '
        '${hicGirilmeyen.take(20).join(', ')}');

    // ---- Para --------------------------------------------------------
    final List<int> servetler =
        hepsi.map((BotLifeResult r) => r.finalNetWorth).toList();
    final Set<String> gorulenYatirim = <String>{};
    final Set<String> gorulenIsletme = <String>{};
    for (final BotLifeResult r in hepsi) {
      gorulenYatirim.addAll(r.investmentTypes);
      gorulenIsletme.addAll(r.businessTypes);
    }
    print('\n-- PARA --');
    print('olum ani net servet: medyan ${k(medyan(servetler))} · '
        'kotu%10 ${k(yuzde(servetler, 0.10))} · '
        'iyi%10 ${k(yuzde(servetler, 0.90))} · '
        'en yuksek ${k(servetler.reduce((int a, int b) => a > b ? a : b))}');
    print('borclu olen %${oran(hepsi, (BotLifeResult r) => r.finalDebt > 0).toStringAsFixed(1)} · '
        'kredi kullanan %${oran(hepsi, (BotLifeResult r) => r.usedLoan).toStringAsFixed(1)}');
    print('yatirim yapan %${oran(hepsi, (BotLifeResult r) => r.investedEver).toStringAsFixed(1)} · '
        'ev sahibi %${oran(hepsi, (BotLifeResult r) => r.ownedHome).toStringAsFixed(1)} · '
        'yatirim evi %${oran(hepsi, (BotLifeResult r) => r.ownedRental).toStringAsFixed(1)} · '
        'kiraya veren %${oran(hepsi, (BotLifeResult r) => r.letProperty).toStringAsFixed(1)}');
    print('arac sahibi %${oran(hepsi, (BotLifeResult r) => r.ownedVehicle).toStringAsFixed(1)} · '
        'is sahibi %${oran(hepsi, (BotLifeResult r) => r.ownedBusiness).toStringAsFixed(1)}');
    print('yatirim turu ${gorulenYatirim.length}/${kInvestmentTypes.length} · '
        'isletme turu ${gorulenIsletme.length}/${kBusinessCatalog.length}');

    // ---- Aile --------------------------------------------------------
    print('\n-- AILE --');
    print('partneri olan %${oran(hepsi, (BotLifeResult r) => r.everPartner).toStringAsFixed(1)} · '
        'evlenen %${oran(hepsi, (BotLifeResult r) => r.married).toStringAsFixed(1)} · '
        'bosanan %${oran(hepsi, (BotLifeResult r) => r.divorced).toStringAsFixed(1)} · '
        'tekrar evlenen %${oran(hepsi, (BotLifeResult r) => r.remarried).toStringAsFixed(1)}');
    print('cocuklu %${oran(hepsi, (BotLifeResult r) => r.childCount > 0).toStringAsFixed(1)} · '
        'ortalama cocuk ${ortalama(hepsi, (BotLifeResult r) => r.childCount).toStringAsFixed(2)} · '
        'torun goren %${oran(hepsi, (BotLifeResult r) => r.sawGrandchild).toStringAsFixed(1)}');

    // ---- Sosyal ------------------------------------------------------
    print('\n-- SOSYAL --');
    print('arkadasi olan %${oran(hepsi, (BotLifeResult r) => r.friendCount > 0).toStringAsFixed(1)} · '
        'ortalama arkadas ${ortalama(hepsi, (BotLifeResult r) => r.friendCount).toStringAsFixed(2)} · '
        'kuslik yasayan %${oran(hepsi, (BotLifeResult r) => r.estranged).toStringAsFixed(1)}');
    print('sosyal medya acan %${oran(hepsi, (BotLifeResult r) => r.openedSocial).toStringAsFixed(1)} · '
        'acanlarda takipci medyan ${medyan(hepsi.where((BotLifeResult r) => r.openedSocial).map((BotLifeResult r) => r.finalFame).toList())} · '
        'finger kullanan %${oran(hepsi, (BotLifeResult r) => r.usedFinger).toStringAsFixed(1)}');

    // ---- Sağlık ve spor ---------------------------------------------
    final Set<String> gorulenHobi = <String>{};
    final Set<String> gorulenSanat = <String>{};
    for (final BotLifeResult r in hepsi) {
      gorulenHobi.addAll(r.hobbies);
      gorulenSanat.addAll(r.martialArts);
    }
    print('\n-- SAGLIK / SPOR --');
    print('kronik yasayan %${oran(hepsi, (BotLifeResult r) => r.chronic).toStringAsFixed(1)} · '
        'check-up yapan %${oran(hepsi, (BotLifeResult r) => r.checkup).toStringAsFixed(1)} · '
        'spor yapan %${oran(hepsi, (BotLifeResult r) => r.didSport).toStringAsFixed(1)}');
    print('hobi ${gorulenHobi.length}/${HobbyKind.values.length} · '
        'dovus sanati ${gorulenSanat.length}/${MartialArt.values.length} · '
        'evcil hayvan %${oran(hepsi, (BotLifeResult r) => r.hadPet).toStringAsFixed(1)} · '
        'tatil %${oran(hepsi, (BotLifeResult r) => r.traveled).toStringAsFixed(1)}');

    // ---- Suç ---------------------------------------------------------
    final Set<String> gorulenSuc = <String>{};
    for (final BotLifeResult r in hepsi) {
      gorulenSuc.addAll(r.crimeIds);
    }
    print('\n-- SUC --');
    print('sabikali %${oran(hepsi, (BotLifeResult r) => r.hasRecord).toStringAsFixed(1)} · '
        'mahkemeye cikan %${oran(hepsi, (BotLifeResult r) => r.wentToTrial).toStringAsFixed(1)} · '
        'hapis yatan %${oran(hepsi, (BotLifeResult r) => r.imprisoned).toStringAsFixed(1)} · '
        'kumar %${oran(hepsi, (BotLifeResult r) => r.gambled).toStringAsFixed(1)}');
    print('gorulen suc turu ${gorulenSuc.length}');

    // ---- İçerik ------------------------------------------------------
    final Set<String> gorulenOlay = <String>{};
    final Set<String> gorulenSehir = <String>{};
    for (final BotLifeResult r in hepsi) {
      gorulenOlay.addAll(r.seenEvents);
      gorulenSehir.addAll(r.cities);
    }
    final Set<String> hicGorulmeyenOlay = kEventPool
        .map((GameEvent e) => e.id)
        .where((String id) => !gorulenOlay.contains(id))
        .toSet();
    print('\n-- ICERIK --');
    print('olay havuzundan gorulen ${gorulenOlay.length}/${kEventPool.length} '
        '(%${(gorulenOlay.length / kEventPool.length * 100).toStringAsFixed(1)})');
    print('hic gorulmeyen olay (${hicGorulmeyenOlay.length}): '
        '${hicGorulmeyenOlay.take(30).join(', ')}');
    print('yasanan sehir ${gorulenSehir.length}');

    // ---- Arketip bazlı rapor ----------------------------------------
    print('\n-- ARKETIP BAZLI --');
    for (final PlayerArchetype a in PlayerArchetype.values) {
      final List<BotLifeResult> g = gruplar[a]!;
      final List<int> gs =
          g.map((BotLifeResult r) => r.finalNetWorth).toList();
      final List<BotLifeResult> go =
          g.where((BotLifeResult r) => r.endedByDeath).toList();
      print('${a.name.padRight(13)} '
          'omur ${ortalama(go, (BotLifeResult r) => r.deathAge).toStringAsFixed(0)} · '
          'takilan ${g.length - go.length} · '
          'uni %${oran(g, (BotLifeResult r) => r.wentToUniversity).toStringAsFixed(0)} · '
          'calisan %${oran(g, (BotLifeResult r) => r.everEmployed).toStringAsFixed(0)} · '
          'ev %${oran(g, (BotLifeResult r) => r.ownedHome).toStringAsFixed(0)} · '
          'kira %${oran(g, (BotLifeResult r) => r.letProperty).toStringAsFixed(0)} · '
          'isyeri %${oran(g, (BotLifeResult r) => r.ownedBusiness).toStringAsFixed(0)} · '
          'evli %${oran(g, (BotLifeResult r) => r.married).toStringAsFixed(0)} · '
          'cocuk ${ortalama(g, (BotLifeResult r) => r.childCount).toStringAsFixed(1)} · '
          'sabika %${oran(g, (BotLifeResult r) => r.hasRecord).toStringAsFixed(0)} · '
          'servet ${k(medyan(gs))}');
    }

    // ---- Bekçiler ----------------------------------------------------
    // Ölçüm anlamlı olsun: bot gerçekten yaşamış olmalı.
    expect(hepsi.length, greaterThanOrEqualTo(1500));
    expect(ortalama(olenler, (BotLifeResult r) => r.deathAge), greaterThan(40),
        reason: 'Botlar erken ölüyorsa ölçüm hayatı temsil etmiyor');
    expect(takilanlar.length / hepsi.length, lessThan(0.10),
        reason: 'Hayatların %10\'undan fazlası takılıyorsa ya oyunda '
            'kilit var ya bot yanlış oynuyor; ölçüm güvenilmez');
    expect(oran(hepsi, (BotLifeResult r) => r.everEmployed), greaterThan(50),
        reason: 'Botların çoğu çalışmalı');
    expect(gorulenIsler.length, greaterThan(20),
        reason: 'Bot tek işe saplanmamalı');
    expect(gorulenOlay.length / kEventPool.length, greaterThan(0.5),
        reason: 'Olay havuzunun yarısından fazlası görülmeli');
  }, timeout: const Timeout(Duration(minutes: 30)));
}
