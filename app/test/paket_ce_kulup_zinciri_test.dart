/// Paket CE — kulüp zincirinin derinliği pencereye sığmıyor.
///
/// **Ölçüm (150 spor hayatı, `choiceCoverage` açık).** Paket CD'nin
/// iki modlu taraması, iki modda da kaçan altı olay bıraktı; dördü
/// futbol kulübü zincirinin halkalarıydı. Huni şöyle ayrıştı:
///
/// | Ölçü | Değer |
/// | --- | --- |
/// | Futbol takımına giren hayat | 29/150 (karışık arketipte 16/150) |
/// | En uzun üyelik (ortalama) | **3,9 yıl** |
/// | O hayatlarda görülen futbol olayı (ortalama) | **1,6** (en çok 5) |
/// | Futbol havuzundaki olay sayısı | 14 |
///
/// Görülen dağılım: `ilk_antrenman` 14, `takim_arkadasi` 8, `turnuva` 6,
/// `sakatlik` 6, `antrenor_tartismasi` 5, `ders_catismasi` 5,
/// `ilk_on_bir` 2, `scout` 1.
///
/// **Sonuç: bu bir hata değil, bir yoğunluk uyuşmazlığı.** Zincirin
/// ikinci halkaları (`kulup_futbol_antrenor_barisma`,
/// `kulup_futbol_kritik_gol`, `kulup_futbol_penalti_sonrasi`) hem ilk
/// halkanın izini hem **aynı üyelik penceresinde ikinci bir çekilişi**
/// istiyor. Üyelik 3,9 yıl sürüyor ve o süre boyunca 1,6 kulüp olayı
/// çıkıyor; iki adımlı bir zincir bu yoğunlukta matematik gereği
/// nadir. Paket BX'in öncelik katsayısı (6×) tek halkayı öne çekti ama
/// yoğunluğu değiştirmiyor.
///
/// Çözüm bir **ürün kararı**: üyelik sürerken kulüp olayı genel
/// havuzdan çekilmek yerine **yılda bir** garanti edilsin mi?
/// `docs/DESIGN_REVIEW_QUEUE.md` Q-224'te Faho'nun kararını bekliyor.
/// Bu dosya karar verilene kadar **ölçümün yöntemini ve havuzun
/// bütünlüğünü** korur; kırmızı yanmasın diye gevşetilmiş bir iddia
/// taşımaz.
library;

import 'package:bir_omur/data/event_pool.dart';
import 'package:bir_omur/data/event_pool_school_clubs.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/school_club_progress.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/player_bot.dart';

void main() {
  group('Paket CE — kulüp zinciri', () {
    test('her kulüp halkasının istediği izi yazan bir halka var', () {
      // Yetim halka olmasın: bir olay iz istiyorsa o izi bırakan bir
      // olay bulunmalı. Paket AR'nin "sessiz iz" dersi, ters yönde.
      final Set<String> yazilan = <String>{
        for (final GameEvent e in kEventPool)
          for (final EventChoice c in e.choices) ...c.addFlags,
      };
      for (final GameEvent e in kSchoolClubEvents) {
        for (final String iz in e.requirement.requiredFlags) {
          expect(
            yazilan.contains(iz),
            isTrue,
            reason: '${e.id} "$iz" izini istiyor ama hiçbir olay '
                'o izi bırakmıyor',
          );
        }
      }
    });

    test('üyelik penceresi gerçekten var: ortalama en az iki yıl', () {
      const int n = 40;
      final List<int> uyelikler = <int>[];
      for (int i = 0; i < n; i++) {
        int enUzun = 0;
        playBotLife(
          archetype: PlayerArchetype.sport,
          seed: 10300 + i,
          onYear: (GameState s) {
            final SchoolClubProgress? uyelik =
                s.schoolClubs.activeFor('futbol_takimi');
            if (uyelik != null && uyelik.yearsActive > enUzun) {
              enUzun = uyelik.yearsActive;
            }
          },
        );
        if (enUzun > 0) uyelikler.add(enUzun);
      }
      expect(uyelikler, isNotEmpty,
          reason: '$n spor hayatında kimse futbol takımına girmedi');
      final double ortalama =
          uyelikler.reduce((int a, int b) => a + b) / uyelikler.length;
      expect(
        ortalama,
        greaterThanOrEqualTo(2.0),
        reason: 'Futbol üyeliği ortalama ${ortalama.toStringAsFixed(1)} '
            'yıl sürüyor. Pencere bu kadar kısaysa zincir hiç '
            'tamamlanamaz (ölçülen: 3,9).',
      );
    }, timeout: const Timeout(Duration(minutes: 15)));

    test('kulüp içeriği üyeye gerçekten ulaşıyor', () {
      // Yoğunluk sorusu Q-224'te; burada korunan şey daha temel:
      // futbol takımına giren oyuncu kulüp olaylarını **görüyor**.
      const int n = 40;
      int uye = 0;
      int olayGoren = 0;
      for (int i = 0; i < n; i++) {
        bool futbol = false;
        final BotLifeResult r = playBotLife(
          archetype: PlayerArchetype.sport,
          seed: 10300 + i,
          choiceCoverage: true,
          onYear: (GameState s) {
            if (s.schoolClubs.activeFor('futbol_takimi') != null) {
              futbol = true;
            }
          },
        );
        if (!futbol) continue;
        uye++;
        if (r.seenEvents.any((String id) => id.startsWith('kulup_futbol'))) {
          olayGoren++;
        }
      }
      expect(uye, greaterThanOrEqualTo(3),
          reason: '$n spor hayatında futbol takımına giren $uye');
      expect(
        olayGoren * 2,
        greaterThanOrEqualTo(uye),
        reason: 'Futbol takımına giren $uye hayattan yalnızca '
            '$olayGoren tanesi kulüp olayı gördü; kulüp içeriği üyeye '
            'ulaşmıyor demektir',
      );
    }, timeout: const Timeout(Duration(minutes: 15)));
  });
}
