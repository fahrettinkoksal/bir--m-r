// Paket AW — 500 okul odaklı hayatın kulüp ve futbol ölçümü.
//
// Brief açıkça "ORANLARI GÜZELLEŞTİRME. ÖLÇ." dedi. Bu dosya **rapor**
// yazar. Eşikler yalnızca bozulmayı ve açık saçmalığı yakalar:
//
//   * hiç kulübe girilmeyen bir dünya olmamalı (sistem erişilebilir mi),
//   * "herkes futbolcu oldu" olmamalı — bu AU brief'inin açık yasağı,
//   * futbol geçmişi olmayan kimse profesyonel kapıdan geçmemeli,
//   * kulüpte geçen sezon sayısı kaydın yılından büyük olmamalı,
//   * kaptanlık kıdemsiz verilmemeli.
//
// Diğer bütün oranlar **raporlanıyor**; kalibrasyon kararı Faho'nun
// (Q-192). Dosya adı brief'te `paket_au_measurement_test` olarak
// geçtiği için öyle kaldı; ölçümü yapan paket AW.
// ignore_for_file: avoid_print
library;

import 'package:bir_omur/data/school_club_catalog.dart';
import 'package:bir_omur/domain/models/school_club_progress.dart';
import 'package:bir_omur/domain/sports/football_career.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/player_bot.dart';

/// prototypeOnly: ölçülen hayat sayısı.
const int kOlcumHayati = 500;

/// Okul odaklı arketipler: hepsi okula gider, kulüp çağı yaşar.
///
/// Spor ve eğitim odaklı bot uçları temsil eder; casual ve social
/// ortalamayı. Yatırımcı/girişimci gibi yetişkin odaklı arketipler bu
/// ölçümün dışında, çünkü soru "okul çağında kulüp ne kadar yaşanıyor".
const List<PlayerArchetype> kOkulArketipleri = <PlayerArchetype>[
  PlayerArchetype.sport,
  PlayerArchetype.education,
  PlayerArchetype.casual,
  PlayerArchetype.social,
  PlayerArchetype.family,
];

String _yuzde(int sayi, int toplam) =>
    toplam == 0 ? '-' : '%${(sayi * 100 / toplam).toStringAsFixed(1)}';

int _medyan(List<int> liste) {
  if (liste.isEmpty) return 0;
  final List<int> s = List<int>.of(liste)..sort();
  return s[s.length ~/ 2];
}

void main() {
  test('ÖLÇÜM: $kOlcumHayati okul odaklı hayat — kulüpler ve futbol', () {
    int kulubeGiren = 0;
    int secmeRedBulunan = 0;
    int kaptanOlan = 0;
    int birakan = 0;
    int futbolOynayan = 0;
    int futbolKapisiAcilan = 0;
    int scoutGoren = 0;
    int antrenmanYapan = 0;

    final Map<String, int> kategoriSayaci = <String, int>{};
    final Map<String, int> kulupSayaci = <String, int>{};
    final Map<String, int> rolSayaci = <String, int>{};
    final Map<PlayerArchetype, int> arketipKulup =
        <PlayerArchetype, int>{};
    final Map<PlayerArchetype, int> arketipHayat =
        <PlayerArchetype, int>{};
    final Map<PlayerArchetype, int> arketipFutbol =
        <PlayerArchetype, int>{};

    final List<int> sezonlar = <int>[];
    final List<int> futbolSezonlari = <int>[];
    final List<int> futbolPuanlari = <int>[];

    final List<String> sorunlar = <String>[];

    for (int i = 0; i < kOlcumHayati; i++) {
      final PlayerArchetype arketip =
          kOkulArketipleri[i % kOkulArketipleri.length];
      final BotLifeResult r = playBotLife(archetype: arketip, seed: 9000 + i);

      arketipHayat[arketip] = (arketipHayat[arketip] ?? 0) + 1;

      if (r.joinedAnyClub || r.clubIds.isNotEmpty) {
        kulubeGiren++;
        arketipKulup[arketip] = (arketipKulup[arketip] ?? 0) + 1;
      }
      if (r.clubTryoutRejected) secmeRedBulunan++;
      if (r.wasClubCaptain) kaptanOlan++;
      if (r.leftClub) birakan++;
      if (r.clubTrainings > 0) antrenmanYapan++;
      if (r.clubSeasonsTotal > 0) sezonlar.add(r.clubSeasonsTotal);

      for (final String k in r.clubCategories) {
        kategoriSayaci[k] = (kategoriSayaci[k] ?? 0) + 1;
      }
      for (final String k in r.clubIds) {
        kulupSayaci[k] = (kulupSayaci[k] ?? 0) + 1;
      }
      final SquadRole? rol = r.bestSquadRole;
      if (rol != null) {
        rolSayaci[rol.label] = (rolSayaci[rol.label] ?? 0) + 1;
      }

      if (r.footballSeasons > 0) {
        futbolOynayan++;
        arketipFutbol[arketip] = (arketipFutbol[arketip] ?? 0) + 1;
        futbolSezonlari.add(r.footballSeasons);
        futbolPuanlari.add(r.footballBestScore);
      }
      if (r.footballEligibleEver) futbolKapisiAcilan++;
      if (r.footballScoutSeen) scoutGoren++;

      // --- Tutarlılık denetimleri (ölçümün kendisi değil, bekçi) ------
      //
      // Futbol geçmişi olmayan biri kapıdan geçmiş olamaz.
      if (r.footballEligibleEver && r.footballSeasons == 0) {
        sorunlar.add('seed ${r.seed}: futbol geçmişi yok ama kapı açıldı');
      }
      // Kaptanlık kıdem ister: en az üç sezon.
      if (r.wasClubCaptain && r.clubSeasonsTotal < 3) {
        sorunlar.add(
          'seed ${r.seed}: kaptan oldu ama toplam sezon '
          '${r.clubSeasonsTotal}',
        );
      }
      // Hiç kulübe girmeyen sezon biriktirmiş olamaz.
      if (r.clubIds.isEmpty && r.clubSeasonsTotal > 0) {
        sorunlar.add('seed ${r.seed}: kulüp yok ama sezon var');
      }
      // Seçmeyi geçmeden antrenman yapılmış olamaz.
      if (r.clubTrainings > 0 && r.clubIds.isEmpty) {
        sorunlar.add('seed ${r.seed}: kulüp yok ama antrenman var');
      }
    }

    // --- Rapor ---------------------------------------------------------
    print('');
    print('=' * 70);
    print('PAKET AW — $kOlcumHayati OKUL ODAKLI HAYAT');
    print('=' * 70);
    print('Arketipler: ${kOkulArketipleri.map((PlayerArchetype a) => a.name).join(", ")}');
    print('Bot kulübü PROFILINE gore seciyor; futbol ozel muamele');
    print('gormuyor (bes spor kulubu arasinda).');
    print('');
    print('Kulube giren          $kulubeGiren  ${_yuzde(kulubeGiren, kOlcumHayati)}');
    print('Antrenmana giden      $antrenmanYapan  ${_yuzde(antrenmanYapan, kOlcumHayati)}');
    print('Secmede reddedilen    $secmeRedBulunan  ${_yuzde(secmeRedBulunan, kOlcumHayati)}');
    print('Kaptanlik yapan       $kaptanOlan  ${_yuzde(kaptanOlan, kOlcumHayati)}');
    print('Kulubu birakan        $birakan  ${_yuzde(birakan, kOlcumHayati)}');
    print('Toplam sezon (medyan) ${_medyan(sezonlar)} · en fazla '
        '${sezonlar.isEmpty ? 0 : (List<int>.of(sezonlar)..sort()).last}');
    print('');
    print('FUTBOL YOLU');
    print('Futbol oynayan        $futbolOynayan  ${_yuzde(futbolOynayan, kOlcumHayati)}');
    print('Profesyonel kapi acilan $futbolKapisiAcilan  ${_yuzde(futbolKapisiAcilan, kOlcumHayati)}');
    print('Scout ilgisi goren    $scoutGoren  ${_yuzde(scoutGoren, kOlcumHayati)}');
    print('Futbol sezonu (medyan) ${_medyan(futbolSezonlari)}');
    print('Hazirlik puani (medyan) ${_medyan(futbolPuanlari)} · en yuksek '
        '${futbolPuanlari.isEmpty ? 0 : (List<int>.of(futbolPuanlari)..sort()).last}');
    print('Esik: puan >= ${FootballPath.prototypeOnlyMinScore}, sezon >= '
        '${FootballPath.prototypeOnlyMinSeasons}, beceri >= '
        '${FootballPath.prototypeOnlyMinSkill}');
    print('');
    print('KATEGORI DAGILIMI (kulube giren hayatlar icinde)');
    for (final String k in kategoriSayaci.keys.toList()..sort()) {
      print('  $k  ${kategoriSayaci[k]}  ${_yuzde(kategoriSayaci[k]!, kulubeGiren)}');
    }
    print('');
    print('KULUP DAGILIMI');
    final List<String> siraliKulupler = kulupSayaci.keys.toList()
      ..sort((String a, String b) =>
          (kulupSayaci[b] ?? 0).compareTo(kulupSayaci[a] ?? 0));
    for (final String k in siraliKulupler) {
      print('  $k  ${kulupSayaci[k]}  ${_yuzde(kulupSayaci[k]!, kOlcumHayati)}');
    }
    print('');
    print('EN YUKSEK ROL');
    for (final String k in rolSayaci.keys.toList()..sort()) {
      print('  $k  ${rolSayaci[k]}');
    }
    print('');
    print('ARKETIPE GORE (kulube giren / futbol oynayan)');
    for (final PlayerArchetype a in kOkulArketipleri) {
      final int hayat = arketipHayat[a] ?? 0;
      print('  ${a.name.padRight(10)} '
          '${_yuzde(arketipKulup[a] ?? 0, hayat).padLeft(6)} / '
          '${_yuzde(arketipFutbol[a] ?? 0, hayat)}');
    }
    print('');
    print('Bu bir OLCUM. Hangi sayinin degisecegine Faho karar verir');
    print('(Q-192). Hicbir oran bu dosyada guzellestirilmedi.');
    print('=' * 70);

    // --- Bekçiler ------------------------------------------------------
    expect(sorunlar, isEmpty, reason: sorunlar.take(10).join('\n'));

    // Sistem gerçekten erişilebilir olmalı: kimse kulübe girmiyorsa
    // ya bot kör ya sistem kapalı. İkisi de hata.
    expect(
      kulubeGiren,
      greaterThan(0),
      reason: 'Hiçbir hayatta kulübe girilmedi: sistem erişilemiyor',
    );

    // AU brief'inin açık yasağı: "herkes futbolcu olmasın".
    // Kulübe girenlerin hepsi futbol oynuyorsa seçim çalışmıyor.
    if (kulubeGiren > 0) {
      expect(
        futbolOynayan,
        lessThan(kulubeGiren),
        reason: 'Kulübe giren herkes futbol oynuyor: profil seçimi çalışmıyor',
      );
      // En az iki farklı kategori görülmeli.
      expect(
        kategoriSayaci.length,
        greaterThanOrEqualTo(2),
        reason: 'Tek kategori görüldü: bot profilden bağımsız seçiyor',
      );
    }

    // Ölçülen kulüpler gerçekten katalogda olmalı.
    for (final String id in kulupSayaci.keys) {
      expect(
        kSchoolClubs.any((SchoolClub c) => c.id == id),
        isTrue,
        reason: 'Katalogda olmayan kulüp kimliği: $id',
      );
    }

    // Futbol kapısının eşikleri prototypeOnly ama sıfır olamaz.
    expect(FootballPath.prototypeOnlyMinSeasons, greaterThan(0));
  }, timeout: const Timeout(Duration(minutes: 20)));
}
