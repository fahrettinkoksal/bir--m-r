// Paket AQ — 500 tam hayat ölçümü. ÖLÇÜM; oran güzelleştirmesi yok.
//
// Brief açıkça "ORANLARI GÜZELLEŞTİRME. SADECE ÖLÇ." dedi. Bu dosya
// **rapor** yazıyor; eşikler yalnızca bozulmayı yakalayacak kadar sert:
//
//   * sağlık 0 iken normal yaşayan karakter sayısı **0** olmalı,
//   * kritik durum bypass sayısı **0** olmalı,
//   * aynı yılda çifte ölüm **0** olmalı,
//   * parasız karakter kilitlenmemeli (soft lock **0**),
//   * oyunun kendi değişmezleri kırılmamalı.
//
// Ortalama ölüm yaşı, bant dağılımı ve sağlık 0 sıklığı **raporlanıyor**;
// "güzel" olup olmadığına Faho ve ChatGPT karar verir (Q-189).
// ignore_for_file: avoid_print
library;

import 'dart:math';

import 'package:bir_omur/data/activity_catalog.dart';
import 'package:bir_omur/data/health_crisis_catalog.dart';
import 'package:bir_omur/domain/activities/activity_engine.dart';
import 'package:bir_omur/domain/events/event_engine.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/generation/life_progression.dart';
import 'package:bir_omur/domain/life/critical_health.dart';
import 'package:bir_omur/domain/life/health_crisis_engine.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/life_log.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/invariants.dart';

/// prototypeOnly: ölçülen hayat sayısı.
const int kOlcumHayati = 500;

const HealthCrisisEngine kKriz = HealthCrisisEngine();
const ActivityEngine kAktivite = ActivityEngine();
const EventEngine kOlay = EventEngine();

int _yuzdelik(List<int> sirali, int yuzde) => sirali.isEmpty
    ? -1
    : sirali[((sirali.length - 1) * yuzde / 100).round()];

void main() {
  test('ÖLÇÜM: $kOlcumHayati tam hayat — kritik sağlık', () {
    // --- Sayaçlar ----------------------------------------------------
    int sifirGorenHayat = 0;
    int sifirGorulmeSayisi = 0;
    int sifirSonrasiKurtulma = 0;
    int sifirSonrasiOlum = 0;
    int sifirdaNormalYil = 0; // HEDEF 0
    int bypassSayisi = 0; // HEDEF 0
    int ciftOlum = 0; // HEDEF 0
    int softLock = 0; // HEDEF 0
    int sifirdaAktivite = 0; // HEDEF 0
    int kaybolanKritik = 0; // HEDEF 0
    final List<int> olumYaslari = <int>[];
    final List<int> ilkSifirYaslari = <int>[];
    final List<String> sorunlar = <String>[];

    // Bant dağılımı: yaşanan yılların kaçı hangi bantta geçti.
    final Map<HealthBand, int> bantYili = <HealthBand, int>{
      for (final HealthBand b in HealthBand.values) b: 0,
    };
    int toplamYil = 0;

    // Düşük sağlıkta iş/hastalık etkisi.
    int dusukSaglikYili = 0;
    int dusukSaglikHastalikYili = 0;
    int iyiSaglikYili = 0;
    int iyiSaglikHastalikYili = 0;

    // Stat 0 görülme oranları.
    final Map<String, int> statSifir = <String, int>{
      'mutluluk': 0,
      'karizma': 0,
      'gorunus': 0,
      'zeka': 0,
    };

    for (int seed = 0; seed < kOlcumHayati; seed++) {
      GameState s = LifeGenerator.seeded(seed)
          .generate(mode: StartMode.tamamenRastgele);
      // Üç farklı oyuncu tutumu: en iyi tedavi / parasız yol / umursamaz.
      final int tutum = seed % 3;
      // Bir kısım hayat bilerek **parasız** oynanıyor; soft-lock bu
      // koşulda çıkar.
      if (seed % 5 == 0) {
        s = s.copyWith(player: s.player.copyWith(wallet: 0));
      }

      final LifeProgression motor = LifeProgression(Random(seed + 101));
      final Random secim = Random(seed * 37 + 3);
      bool buHayattaSifir = false;
      int olumGecisi = 0;
      int guard = 0;

      while (!s.deceased && guard++ < 160) {
        final int saglikOnce = s.player.stats.health;

        // 1) Bekleyen kritik/olağan kriz: üretim motoruyla çözülür.
        if (s.hasPendingCrisis) {
          final bool kritik = CriticalHealth.isPending(s);
          final HealthCrisis? kriz = s.pendingCrisis!.crisis;
          if (kriz == null) {
            sorunlar.add('tohum $seed: kriz kaydı okunamadı');
            break;
          }
          final List<CrisisChoice> acik = kriz.choices
              .where((CrisisChoice c) => kKriz.canChoose(s, c))
              .toList(growable: false);
          if (acik.isEmpty) {
            softLock++;
            sorunlar.add('tohum $seed yaş ${s.player.age}: '
                'kriz ${kriz.id} — seçilebilir seçenek yok (soft lock)');
            break;
          }

          // Sağlık 0 iken aktivite denemesi: açık kalmamalı.
          if (kritik) {
            for (final ActivityAction a in <ActivityAction>[
              kActivityActions.firstWhere((ActivityAction a) => a.id == 'esneme'),
              kActivityActions.firstWhere((ActivityAction a) => a.id == 'kosu'),
            ]) {
              if (kAktivite.availability(s, a).isAllowed) {
                sifirdaAktivite++;
                sorunlar.add('tohum $seed: kritik durumda ${a.id} açık');
              }
            }
            // Bypass denemesi: yaş almayı zorla.
            final GameState zorla = motor.advanceOneYear(s);
            if (zorla.player.age != s.player.age) {
              bypassSayisi++;
              sorunlar.add('tohum $seed yaş ${s.player.age}: '
                  'kritik durum çözülmeden yaş ilerledi');
            }
          }

          final CrisisChoice secilen = switch (tutum) {
            // En iyi tedaviyi arar.
            0 => acik.reduce((CrisisChoice a, CrisisChoice b) =>
                a.survivalBonus >= b.survivalBonus ? a : b),
            // Parasını korur: bedelsiz yolu seçer.
            1 => acik.firstWhere((CrisisChoice c) => c.cost == 0,
                orElse: () => acik.first),
            // Rastgele.
            _ => acik[secim.nextInt(acik.length)],
          };
          final CrisisResult r = kKriz.respond(s, secilen.id, secim);
          s = r.state;
          if (kritik) {
            if (r.outcome.survived) {
              sifirSonrasiKurtulma++;
            } else {
              sifirSonrasiOlum++;
            }
          }
          if (s.deceased) olumGecisi++;
          expect(checkInvariants(s, where: 'tohum $seed kriz sonrası'), isEmpty);
          continue;
        }

        // 2) Bekleyen olay: üretim motoruyla çözülür.
        final ActiveEvent? olay = s.pendingEvent;
        if (olay != null) {
          s = kOlay.resolve(
            s,
            olay.choices[secim.nextInt(olay.choices.length)].id,
            rng: secim,
          );
          // Olay seçimi sağlığı acil banda indirdiyse kritik durum
          // açılmış olmalı.
          if (s.player.stats.health <= 0 &&
              !s.deceased &&
              !s.hasPendingCrisis) {
            sorunlar.add('tohum $seed: olay sonrası sağlık 0, kritik yok');
          }
          continue;
        }

        // 3) Yaş al.
        final int yasOnce = s.player.age;
        s = motor.advanceOneYear(s);
        if (s.player.age == yasOnce) {
          if (!s.hasPendingCrisis && !s.hasPendingEvent) break;
          continue;
        }
        toplamYil++;
        if (s.deceased) olumGecisi++;

        final int saglikSonra = s.player.stats.health;
        final HealthBand bant = CriticalHealth.bandOf(saglikSonra);
        bantYili[bant] = bantYili[bant]! + 1;

        // Sağlık 0 iken "normal" yaşanan yıl: kritik durum da ölüm de
        // yoksa bu bir hata.
        // "Normal yaşanan yıl": sağlık 0, oyuncu hayatta ve ekranda
        // çözülmesi gereken **hiçbir** sağlık durumu yok. Bekleyen
        // olağan kriz de sayılır: oyuncu ilerleyemez ve kriz kapanınca
        // kritik durum devralır.
        if (saglikSonra <= 0 && !s.deceased && !s.hasPendingCrisis) {
          sifirdaNormalYil++;
          sorunlar.add('tohum $seed yaş ${s.player.age}: '
              'sağlık 0, bekleyen sağlık durumu yok, hayat devam ediyor');
        }
        if (saglikSonra <= 0 && !buHayattaSifir) {
          buHayattaSifir = true;
          ilkSifirYaslari.add(s.player.age);
        }
        if (saglikSonra <= 0) sifirGorulmeSayisi++;

        // Düşük sağlıkta hastalık/iş etkisi: rapor alınan yıl mı?
        final bool hastaOldu = s.log.any((LifeLogEntry e) =>
            e.age == s.player.age &&
            (e.text.contains('hasta yattın') ||
                e.text.contains('yatakta kaldın')));
        if (saglikOnce <= 25) {
          dusukSaglikYili++;
          if (hastaOldu) dusukSaglikHastalikYili++;
        } else if (saglikOnce >= 70) {
          iyiSaglikYili++;
          if (hastaOldu) iyiSaglikHastalikYili++;
        }

        // Stat 0 görülmesi.
        if (s.player.stats.happiness == 0) statSifir['mutluluk'] = statSifir['mutluluk']! + 1;
        if (s.player.stats.charisma == 0) statSifir['karizma'] = statSifir['karizma']! + 1;
        if (s.player.stats.appearance == 0) statSifir['gorunus'] = statSifir['gorunus']! + 1;
        if (s.player.stats.intelligence == 0) statSifir['zeka'] = statSifir['zeka']! + 1;

        expect(checkInvariants(s, where: 'tohum $seed yaş ${s.player.age}'),
            isEmpty);
      }

      if (buHayattaSifir) sifirGorenHayat++;
      if (olumGecisi > 1) {
        ciftOlum++;
        sorunlar.add('tohum $seed: $olumGecisi ölüm geçişi');
      }
      if (s.deceased) {
        olumYaslari.add(s.deathAge ?? s.player.age);
        // Vefat eden oyuncuda bekleyen kritik durum kalmaz.
        if (s.hasPendingCrisis) {
          kaybolanKritik++;
          sorunlar.add('tohum $seed: vefat sonrası bekleyen kriz var');
        }
      }
    }

    // --- Rapor -------------------------------------------------------
    olumYaslari.sort();
    ilkSifirYaslari.sort();
    final double ortOlum = olumYaslari.isEmpty
        ? -1
        : olumYaslari.reduce((int a, int b) => a + b) / olumYaslari.length;

    print('================ PAKET AQ ÖLÇÜM ================');
    print('hayat sayısı                     : $kOlcumHayati');
    print('tamamlanan (ölümle biten) hayat  : ${olumYaslari.length}');
    print('yaşanan toplam yıl               : $toplamYil');
    print('');
    print('--- sağlık 0 ---');
    print('sağlık 0 gören hayat             : $sifirGorenHayat '
        '(%${(sifirGorenHayat * 100 / kOlcumHayati).toStringAsFixed(1)})');
    print('sağlık 0 görülme sayısı (yıl)    : $sifirGorulmeSayisi');
    print('ilk 0 yaşı p25/medyan/p75        : '
        '${_yuzdelik(ilkSifirYaslari, 25)} / '
        '${_yuzdelik(ilkSifirYaslari, 50)} / '
        '${_yuzdelik(ilkSifirYaslari, 75)}');
    print('kritik durumdan kurtulma         : $sifirSonrasiKurtulma');
    print('kritik durumdan ölüm             : $sifirSonrasiOlum');
    final int kritikToplam = sifirSonrasiKurtulma + sifirSonrasiOlum;
    if (kritikToplam > 0) {
      print('kurtulma oranı                   : '
          '%${(sifirSonrasiKurtulma * 100 / kritikToplam).toStringAsFixed(1)}');
    }
    print('');
    print('--- HEDEF 0 olan sayaçlar ---');
    print('sağlık 0 iken normal yaşanan yıl : $sifirdaNormalYil');
    print('kritik durum bypass              : $bypassSayisi');
    print('aynı hayatta çifte ölüm          : $ciftOlum');
    print('parasız soft lock                : $softLock');
    print('sağlık 0 iken açık aktivite      : $sifirdaAktivite');
    print('vefat sonrası kalan kritik durum : $kaybolanKritik');
    print('');
    print('--- bant dağılımı (yaşanan yıl) ---');
    for (final HealthBand b in HealthBand.values) {
      final int n = bantYili[b]!;
      print('  ${b.name.padRight(16)}: $n '
          '(%${toplamYil == 0 ? 0 : (n * 100 / toplamYil).toStringAsFixed(1)})');
    }
    print('');
    print('--- ölüm yaşı ---');
    print('ortalama                         : ${ortOlum.toStringAsFixed(1)}');
    print('p25 / medyan / p75               : '
        '${_yuzdelik(olumYaslari, 25)} / ${_yuzdelik(olumYaslari, 50)} / '
        '${_yuzdelik(olumYaslari, 75)}');
    if (olumYaslari.isNotEmpty) {
      print('60 yaş öncesi ölüm               : '
          '${olumYaslari.where((int a) => a < 60).length} '
          '(%${(olumYaslari.where((int a) => a < 60).length * 100 / olumYaslari.length).toStringAsFixed(1)})');
      print('80+ yaşayan                      : '
          '${olumYaslari.where((int a) => a >= 80).length} '
          '(%${(olumYaslari.where((int a) => a >= 80).length * 100 / olumYaslari.length).toStringAsFixed(1)})');
    }
    print('');
    print('--- düşük sağlıkta iş/hastalık ---');
    if (dusukSaglikYili > 0) {
      print('sağlık<=25 yılında rapor oranı   : '
          '%${(dusukSaglikHastalikYili * 100 / dusukSaglikYili).toStringAsFixed(1)} '
          '($dusukSaglikHastalikYili / $dusukSaglikYili)');
    }
    if (iyiSaglikYili > 0) {
      print('sağlık>=70 yılında rapor oranı   : '
          '%${(iyiSaglikHastalikYili * 100 / iyiSaglikYili).toStringAsFixed(1)} '
          '($iyiSaglikHastalikYili / $iyiSaglikYili)');
    }
    print('');
    print('--- stat 0 görülen yıl sayısı ---');
    statSifir.forEach((String k, int v) => print('  ${k.padRight(10)}: $v'));
    print('');
    if (sorunlar.isEmpty) {
      print('Bulgu yok.');
    } else {
      print('--- bulgular (ilk 15) ---');
      for (final String b in sorunlar.take(15)) {
        print('  $b');
      }
      print('  toplam bulgu: ${sorunlar.length}');
    }
    print('================================================');

    // --- Sert eşikler: yalnızca değişmez ihlalleri ------------------
    expect(sifirdaNormalYil, 0,
        reason: 'sağlık 0 iken hiçbir şey olmamış gibi yaşanan yıl olmamalı');
    expect(bypassSayisi, 0, reason: 'kritik durum bypass edilemez');
    expect(ciftOlum, 0, reason: 'bir kişi bir kez ölür');
    expect(softLock, 0, reason: 'parasız oyuncu ekranda kilitlenemez');
    expect(sifirdaAktivite, 0,
        reason: 'kritik durum çözülmeden aktivite açık kalmamalı');
    expect(kaybolanKritik, 0,
        reason: 'vefat eden oyuncuda bekleyen kriz kalmaz');

    // Sağlık 0 **görülebilmeli**: sıfıra indirmek hedef değil.
    expect(sifirGorenHayat, greaterThan(0),
        reason: 'sağlık 0 hiç görülmüyorsa mekanizma ölçülemez');
    // Ama her hayatın varış noktası da olmamalı.
    expect(sifirGorenHayat, lessThan(kOlcumHayati),
        reason: 'her hayat ölümün eşiğine geliyorsa denge yanlış');

    // Kritik durum hem kurtulmayla hem ölümle bitebilmeli.
    expect(sifirSonrasiKurtulma, greaterThan(0));
    expect(sifirSonrasiOlum, greaterThan(0));
  }, timeout: const Timeout(Duration(minutes: 30)));
}
