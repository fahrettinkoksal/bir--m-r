/// Paket BZ — eşikteki yılların dört olayı yanlış kapıdaydı.
///
/// **Ölçülen sorun.** Paket BN'in 16-20 yaş havuzundaki dört olay
/// (`esik_universite_ilk_ay`, `esik_kampuste_tanisma`,
/// `esik_kampus_kantin`, `esik_okulu_birakma`) 1.000 hayatlık denetimde
/// hiç görülmüyordu. Sebep havuz rekabeti değildi: dördü de
/// `requiresSchoolStudent: true` istiyordu ve o kapı
/// `EducationState.isSchoolStudent => enrolled`, yani **yalnızca 1-12.
/// sınıf**. 18-20 yaşındaki oyuncu ya üniversitede (`enrolled` kapalı)
/// ya da çalışıyor; kampüs metni taşıyan olay bu yüzden hedef kitlesine
/// asla çıkmıyordu.
///
/// Ölçüm (150 hayat): 18-20 arasında **74 hayat üniversiteli**. Olayların
/// uygun hale gelmesi 7-8 hayattan 75-81'e çıktı ve dördü de ilk kez
/// göründü (0 → 3/14/5/3).
///
/// Düzeltme yeni bir kural değil: `requiresStudent` (1-12 **ya da**
/// üniversite) eklendi ve bu dört olay ona bağlandı.
library;

import 'package:bir_omur/data/event_pool.dart';
import 'package:bir_omur/domain/events/event_engine.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/player_bot.dart';

const Set<String> _kampusOlaylari = <String>{
  'esik_universite_ilk_ay',
  'esik_kampuste_tanisma',
  'esik_kampus_kantin',
  'esik_okulu_birakma',
};

void main() {
  group('Paket BZ — öğrencilik kapısı', () {
    test('kampüs olayları 1-12 kapısını kullanmıyor', () {
      for (final GameEvent olay in kEventPool) {
        if (!_kampusOlaylari.contains(olay.id)) continue;
        expect(olay.requirement.requiresSchoolStudent, isFalse,
            reason: '${olay.id} hâlâ yalnızca 1-12 kapısını istiyor; '
                'üniversiteliye çıkmaz');
        expect(olay.requirement.requiresStudent, isTrue,
            reason: '${olay.id} öğrencilik kapısı istemiyor');
      }
    });

    test('kampüs/üniversite metni taşıyan hiçbir olay 1-12 kapısında '
        'kalmasın', () {
      // Bu bekçi hatayı **kaynağında** yakalar: kimliğinde ya da
      // metninde kampüs/üniversite geçen bir olay 1-12 öğrenciliği
      // isterse hedef kitlesine hiç çıkmaz.
      final RegExp desen = RegExp(r'kamp[uü]s|[uü]niversite', caseSensitive: false);
      final List<String> hatali = <String>[];
      for (final GameEvent olay in kEventPool) {
        if (!olay.requirement.requiresSchoolStudent) continue;
        if (!desen.hasMatch('${olay.id} ${olay.text}')) continue;
        // 12. sınıf olayları bölüm/üniversite tercihini konuşabilir;
        // onları sınıf aralığı ayırır.
        if (olay.requirement.minGrade != null) continue;
        hatali.add(olay.id);
      }
      expect(hatali, isEmpty,
          reason: 'kampüs metni taşıyan olaylar 1-12 kapısında: $hatali');
    });

    test('üniversiteli oyuncuda dört olay uygun hale geliyor', () {
      // **Durum kurulmuyor, aranıyor:** 18-20 arasında üniversiteli bir
      // kare gerçek bot hayatlarından bulunur.
      GameState? kare;
      for (int i = 0; i < 40 && kare == null; i++) {
        GameState? aday;
        playBotLife(
          archetype: PlayerArchetype.education,
          seed: 6600 + i,
          onYear: (GameState s) {
            if (aday != null) return;
            if (s.player.age < 18 || s.player.age > 20) return;
            if (s.education.isUniversityStudent) aday = s;
          },
        );
        kare = aday;
      }
      expect(kare, isNotNull,
          reason: '40 hayatta 18-20 arası üniversiteli kare bulunamadı');

      final Set<String> uygun = const EventEngine().debugEligibleIds(kare!);
      // Dördü de aynı anda uygun olmak zorunda değil (tanışma olayının
      // kendi yasak bayrakları var); en az üçü uygun olmalı.
      final int sayi = _kampusOlaylari.where(uygun.contains).length;
      expect(sayi, greaterThanOrEqualTo(3),
          reason: 'üniversiteli karede yalnızca $sayi kampüs olayı uygun: '
              '${_kampusOlaylari.where(uygun.contains)}');
    }, timeout: const Timeout(Duration(minutes: 20)));

    test('oynanan hayatlarda gerçekten çıkıyor (120 hayat)', () {
      int goren = 0;
      final Set<String> gorulenler = <String>{};
      for (int i = 0; i < 120; i++) {
        final BotLifeResult r = playBotLife(
          archetype: PlayerArchetype.values[i % PlayerArchetype.values.length],
          seed: 5500 + i,
        );
        final Set<String> kesisim = r.seenEvents.intersection(_kampusOlaylari);
        if (kesisim.isNotEmpty) goren++;
        gorulenler.addAll(kesisim);
      }
      // Ölçüm: 150 hayatta 25 görülme, dört olayın hepsi çıktı.
      // Düzeltme öncesi bu sayı **sıfırdı**; taban onun çok üstünde ama
      // dalgalanmaya yer bırakıyor.
      expect(goren, greaterThanOrEqualTo(6),
          reason: '120 hayatta yalnızca $goren hayat kampüs olayı gördü');
      expect(gorulenler.length, greaterThanOrEqualTo(2),
          reason: 'dört olaydan yalnızca ${gorulenler.length} ayrı olay '
              'göründü: $gorulenler');
    }, timeout: const Timeout(Duration(minutes: 30)));
  });
}
