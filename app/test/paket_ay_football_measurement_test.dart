// Paket AY — profesyonel futbol kariyerinin ölçümü.
//
// AW'nin 500 okul odaklı hayatı yalnızca **6** profesyonel kariyer
// üretti: kapı dar (iyi, brief öyle istiyor) ama bu da kariyerin
// kendisini ölçmek için fazla küçük bir örneklem. Bu dosya futbolu
// gerçekten yaşayan bir kohort kurar: tamamı spor odaklı bot.
//
// **Bu bir ÖLÇÜMDÜR.** "ORANLARI GÜZELLEŞTİRME. ÖLÇ." kuralı gereği
// hiçbir sayı burada güzelleştirilmedi; eşikler yalnızca sistemin ölü
// olmadığını ve açık saçmalığı yakalar. Kalibrasyon kararı Faho'nun
// (Q-193).
// ignore_for_file: avoid_print
library;

import 'package:bir_omur/data/economy.dart';
import 'package:bir_omur/domain/sports/football_career.dart';
import 'package:bir_omur/domain/sports/football_pro_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/player_bot.dart';

/// prototypeOnly: ölçülen hayat sayısı. Spor odaklı bot futbol kapısına
/// en çok yaklaşan arketip; kariyer örneklemi buradan çıkar.
const int kOlcumHayati = 1200;

String _yuzde(int sayi, int toplam) =>
    toplam == 0 ? '-' : '%${(sayi * 100 / toplam).toStringAsFixed(1)}';

int _medyan(List<int> liste) {
  if (liste.isEmpty) return 0;
  final List<int> s = List<int>.of(liste)..sort();
  return s[s.length ~/ 2];
}

int _enAz(List<int> liste) =>
    liste.isEmpty ? 0 : (List<int>.of(liste)..sort()).first;

int _enCok(List<int> liste) =>
    liste.isEmpty ? 0 : (List<int>.of(liste)..sort()).last;

void main() {
  test('ÖLÇÜM: $kOlcumHayati spor odaklı hayat — profesyonel futbol', () {
    int kapiAcilan = 0;
    int denemeyeGiren = 0;
    int kabulEdilen = 0;
    int toplamRet = 0;
    int sakatlikYasayan = 0;
    int kariyeriBiten = 0;

    final List<int> proSezonlari = <int>[];
    final List<int> proMaclari = <int>[];
    final List<int> proGolleri = <int>[];
    final List<int> kazanclar = <int>[];
    final List<int> sezonBasiKazanc = <int>[];
    final List<int> birakmaYaslari = <int>[];
    final Map<String, int> bitisSebepleri = <String, int>{};
    // Paket AY/2: futbol kamuoyu ününe dönüşüyor mu, sonra soluyor mu?
    final List<int> zirveUnler = <int>[];
    final List<int> emeklilikUnleri = <int>[];
    final List<int> sonUnler = <int>[];
    int unHicGelmeyen = 0;

    final List<String> sorunlar = <String>[];

    for (int i = 0; i < kOlcumHayati; i++) {
      final BotLifeResult r = playBotLife(
        archetype: PlayerArchetype.sport,
        seed: 41000 + i,
      );

      if (r.footballEligibleEver) kapiAcilan++;
      if (r.footballTrialAttempted) denemeyeGiren++;
      toplamRet += r.footballTrialRejections;
      if (!r.footballTrialAccepted) continue;

      kabulEdilen++;
      proSezonlari.add(r.footballProSeasons);
      proMaclari.add(r.footballProAppearances);
      proGolleri.add(r.footballProGoals);
      kazanclar.add(r.footballEarnings);
      if (r.footballProSeasons > 0) {
        sezonBasiKazanc.add(r.footballEarnings ~/ r.footballProSeasons);
      }
      if (r.footballInjurySeasons > 0) sakatlikYasayan++;
      zirveUnler.add(r.footballPeakFame);
      sonUnler.add(r.footballFameAtDeath);
      if (r.footballPeakFame == 0) unHicGelmeyen++;
      final int? emeklilikUnu = r.footballFameAtRetirement;
      if (emeklilikUnu != null) emeklilikUnleri.add(emeklilikUnu);

      final String? sebep = r.footballExitReason;
      if (sebep != null) {
        kariyeriBiten++;
        bitisSebepleri[sebep] = (bitisSebepleri[sebep] ?? 0) + 1;
      }
      final int? birakmaYasi = r.footballRetireAge;
      if (birakmaYasi != null) birakmaYaslari.add(birakmaYasi);

      // --- Bekçiler: ölçüm değil, bozulma denetimi ------------------
      if (!r.footballEligibleEver) {
        sorunlar.add('seed ${r.seed}: kapı açılmadan profesyonel oldu');
      }
      if (r.footballProSeasons > 0 && r.footballProAppearances == 0) {
        sorunlar.add('seed ${r.seed}: sezon oynadı ama hiç maç yok');
      }
      if (r.footballEarnings > 0 && r.footballProSeasons == 0) {
        sorunlar.add('seed ${r.seed}: sezon yok ama futboldan para var');
      }
      final int? yas = r.footballRetireAge;
      if (yas != null && yas > FootballProEngine.prototypeOnlyHardRetireAge) {
        sorunlar.add('seed ${r.seed}: $yas yaşında hâlâ profesyonel');
      }
    }

    print('');
    print('=' * 70);
    print('PAKET AY — $kOlcumHayati SPOR ODAKLI HAYAT');
    print('=' * 70);
    print('Tamami sport arketipi. AW kohortu (5 arketip, 500 hayat)');
    print('yalnizca 6 kariyer uretmisti; burada amac kariyerin kendisini');
    print('olcecek kadar ornek toplamak.');
    print('');
    print('HUNI');
    print('Profesyonel kapi acilan $kapiAcilan  ${_yuzde(kapiAcilan, kOlcumHayati)}');
    print('Denemeye giren          $denemeyeGiren  ${_yuzde(denemeyeGiren, kOlcumHayati)}');
    print('Kabul edilen            $kabulEdilen  ${_yuzde(kabulEdilen, kOlcumHayati)}'
        '  (denemeye girenlerin ${_yuzde(kabulEdilen, denemeyeGiren)})');
    print('Toplam ret              $toplamRet');
    print('');
    print('KARIYER');
    print('Pro sezon   medyan ${_medyan(proSezonlari)} · en az '
        '${_enAz(proSezonlari)} · en fazla ${_enCok(proSezonlari)}');
    print('Mac         medyan ${_medyan(proMaclari)} · en fazla '
        '${_enCok(proMaclari)}');
    print('Gol         medyan ${_medyan(proGolleri)} · en fazla '
        '${_enCok(proGolleri)}');
    print('Sakatlik yasayan ${_yuzde(sakatlikYasayan, kabulEdilen)}');
    print('Kariyeri biten   ${_yuzde(kariyeriBiten, kabulEdilen)}');
    print('Birakma yasi medyan ${_medyan(birakmaYaslari)} · en az '
        '${_enAz(birakmaYaslari)} · en fazla ${_enCok(birakmaYaslari)}');
    print('');
    print('BITIS SEBEPLERI');
    if (bitisSebepleri.isEmpty) {
      print('  (hic kariyer bitmedi)');
    }
    for (final FootballExit e in FootballExit.values) {
      final int sayi = bitisSebepleri[e.name] ?? 0;
      print('  ${e.name.padRight(22)} $sayi  ${_yuzde(sayi, kariyeriBiten)}');
    }
    print('');
    print('UN — FUTBOL SONRASI HAYATIN SERMAYESI (Paket AY/2)');
    print('Un hic gelmeyen        $unHicGelmeyen  ${_yuzde(unHicGelmeyen, kabulEdilen)}');
    print('Zirve Un    medyan ${_medyan(zirveUnler)} · en az ${_enAz(zirveUnler)}'
        ' · en fazla ${_enCok(zirveUnler)} (tavan '
        '${FootballProEngine.prototypeOnlyFootballFameCap})');
    print('Emeklilikte medyan ${_medyan(emeklilikUnleri)}');
    print('Hayat sonu  medyan ${_medyan(sonUnler)}  (emeklilikten sonra solar)');
    print('Medya/sponsorluk katalogu minFame 3-78 bandinda.');
    print('');
    print('KAZANC (2026 alim gucu, net yillik asgari ucret '
        '${Economy.netYearlyMinimumWage} TL)');
    print('Kariyer toplami medyan ${_medyan(kazanclar)} TL');
    print('  = ${(_medyan(kazanclar) / Economy.netYearlyMinimumWage).toStringAsFixed(1)} '
        'yillik asgari ucret');
    print('Kariyer toplami en yuksek ${_enCok(kazanclar)} TL');
    print('Sezon basi medyan ${_medyan(sezonBasiKazanc)} TL');
    print('  = ${(_medyan(sezonBasiKazanc) / Economy.netYearlyMinimumWage).toStringAsFixed(1)} '
        'yillik asgari ucret · bant '
        '${FootballProEngine.prototypeOnlyMinSalaryInYearlyWages}-'
        '${FootballProEngine.prototypeOnlyMaxSalaryInYearlyWages}');
    print('');
    print('Bu bir OLCUM. Hangi sayinin degisecegine Faho karar verir');
    print('(Q-193). Hicbir oran bu dosyada guzellestirilmedi.');
    print('=' * 70);

    expect(sorunlar, isEmpty, reason: sorunlar.join('\n'));

    // Sistem ölü olmamalı: en az bir kariyer kurulmalı ve bitmeli.
    expect(
      kabulEdilen,
      greaterThan(0),
      reason: 'Profesyonel futbol kariyeri 1200 spor odaklı hayatta hiç '
          'kurulamadı. Kapı dar olabilir, kapalı olamaz.',
    );
    expect(
      kariyeriBiten,
      greaterThan(0),
      reason: 'Hiçbir kariyer bitmedi: 39 yaş sert sınırı çalışmıyor.',
    );

    // Kapıdan geçmeyen profesyonel olamaz — bu kural, ölçüm değil.
    expect(kabulEdilen, lessThanOrEqualTo(denemeyeGiren));
    expect(denemeyeGiren, lessThanOrEqualTo(kapiAcilan));

    // Paket AY/2 bekçisi: futbol kamuoyu ününe dönüşmeli.
    //
    // ÖLÇÜLEN HATA: futbol fame alanına hiç dokunmuyordu ve 300 maç
    // oynamış bir profesyonel tanınmamış kalıyordu. Bu bir daha
    // sessizce geri gelmesin.
    expect(
      unHicGelmeyen,
      0,
      reason: 'Profesyonel futbol oynayıp Ün hiç kazanmayan hayat var: '
          'futbol kamuoyu ününe bağlanmamış.',
    );
    expect(
      _medyan(zirveUnler),
      greaterThan(20),
      reason: 'Futbolcunun zirve Ünü sponsorluk bandının altında kalıyor.',
    );
    expect(
      _enCok(zirveUnler),
      lessThanOrEqualTo(FootballProEngine.prototypeOnlyFootballFameCap),
      reason: 'Futbol tek başına Ün tavanını aşıyor.',
    );

    // Sezon başı kazanç bandın dışına taşmamalı.
    if (sezonBasiKazanc.isNotEmpty) {
      expect(
        _enCok(sezonBasiKazanc),
        lessThanOrEqualTo(
          FootballProEngine.prototypeOnlyMaxSalaryInYearlyWages *
              Economy.netYearlyMinimumWage,
        ),
        reason: 'Sezon başı kazanç bandın tavanını aştı.',
      );
    }
  }, timeout: const Timeout(Duration(minutes: 30)));
}
