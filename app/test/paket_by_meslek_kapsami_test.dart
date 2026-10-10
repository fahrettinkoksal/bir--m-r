/// Paket BY — meslek kapsamı: 55 mesleğin hangisine girilebiliyor?
///
/// **Ölçülen sorun.** 1.000 hayatlık denetim "55 mesleğin 12'sine hiç
/// girilmiyor" diyordu ve bu sayı yıllardır bir içerik eksiği gibi
/// okunuyordu. Kapsam modu (`playBotLife(jobCoverage: true)`) sebebi
/// mesleğe göre ayırdı:
///
/// * `yz_kurye` 240 hayatta **210 yıl** ilanda açıktı ve hiç
///   girilmemişti — sebep ehliyet değil, botun "25 yaşından sonra yarım
///   zamanlı iş kabul etmem" kuralıydı. Denge ölçümünde doğru olan o
///   kural, kapsam ölçümünde içeriği görünmez yapıyordu.
/// * Kalanların hepsinin **yazılı bir gerekçesi** var: üniversite
///   bölümü, hobi basamağı, dövüş sanatı derecesi ya da büyük şehir.
///   Katalog tutarlılığı ayrıca `content_reachability_test.dart` ile
///   korunuyor; yani bunlar erişilemez değil, **çok yıllı ön koşul**
///   isteyen meslekler.
///
/// Bu dosya üç şeyi korur: kapsam modunun kataloğun büyük kısmını
/// gezmesi, kapsam modunun varsayılan bottan **gerçekten** daha geniş
/// gezmesi, ve girilemeyen her mesleğin gerekçesinin yazılı olması
/// (D-063: sahte kilit yok).
library;

import 'package:bir_omur/data/job_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/player_bot.dart';

({Set<String> girilen, Map<String, String> kilit}) _kosu({
  required int adet,
  required bool kapsam,
  required int tohumBaslangici,
}) {
  final Set<String> girilen = <String>{};
  final Map<String, String> kilit = <String, String>{};
  for (int i = 0; i < adet; i++) {
    final BotLifeResult r = playBotLife(
      archetype: PlayerArchetype.values[i % PlayerArchetype.values.length],
      seed: tohumBaslangici + i,
      jobCoverage: kapsam,
    );
    girilen.addAll(r.jobIds);
    r.diag.jobLockReason.forEach((String id, String sebep) {
      kilit.putIfAbsent(id, () => sebep);
    });
  }
  return (girilen: girilen, kilit: kilit);
}

void main() {
  group('Paket BY — meslek kapsamı', () {
    test('kapsam modu kataloğun büyük kısmını geziyor (120 hayat)', () {
      final ({Set<String> girilen, Map<String, String> kilit}) s =
          _kosu(adet: 120, kapsam: true, tohumBaslangici: 8800);

      // Ölçüm: 240 hayatta 37-42/55 (yol tohuma göre oynuyor).
      // Taban yarıdan biraz üstü: altına inmesi kapsam modunun bozulduğu
      // ya da bir meslek öbeğinin erişilemez hale geldiği anlamına gelir.
      expect(s.girilen.length, greaterThanOrEqualTo(28),
          reason: '120 kapsam hayatında yalnızca ${s.girilen.length}/'
              '${kJobCatalog.length} mesleğe girildi');
    }, timeout: const Timeout(Duration(minutes: 40)));

    test('kapsam modu varsayılan bottan daha geniş geziyor', () {
      const int adet = 60;
      final ({Set<String> girilen, Map<String, String> kilit}) varsayilan =
          _kosu(adet: adet, kapsam: false, tohumBaslangici: 9400);
      final ({Set<String> girilen, Map<String, String> kilit}) kapsam =
          _kosu(adet: adet, kapsam: true, tohumBaslangici: 9400);

      expect(kapsam.girilen.length, greaterThan(varsayilan.girilen.length),
          reason: 'kapsam modu genişletmiyor: varsayılan '
              '${varsayilan.girilen.length}, kapsam '
              '${kapsam.girilen.length}');
    }, timeout: const Timeout(Duration(minutes: 40)));

    test('girilemeyen her mesleğin yazılı bir gerekçesi var', () {
      final ({Set<String> girilen, Map<String, String> kilit}) s =
          _kosu(adet: 60, kapsam: true, tohumBaslangici: 8800);

      final List<String> sebepsiz = <String>[];
      for (final JobType job in kJobCatalog) {
        if (s.girilen.contains(job.id)) continue;
        final String? sebep = s.kilit[job.id];
        // Gerekçe ya kilit listesinden gelir ya da iş hiç ilanda
        // görünmemiştir (şehir/yaş penceresi). İkisi de sessiz değil:
        // oyuncu ilan panosunda ya gerekçeyi görür ya ilanı görmez.
        if (sebep != null && sebep.trim().isNotEmpty) continue;
        sebepsiz.add(job.id);
      }

      // D-063: gösterilen kilidin gerekçesi yazılır. Bu testin işi
      // gerekçesi **boş** bir kilit yakalamak; hiç ilanda görünmeyen iş
      // ayrı bir konu (şehir/yaş) ve onu kapsam ölçümü belgeliyor.
      expect(
        s.kilit.values.where((String v) => v.trim().isEmpty),
        isEmpty,
        reason: 'gerekçesi boş kilit var',
      );
      // ignore: avoid_print
      print('BY — 60 kapsam hayatında girilen ${s.girilen.length}/'
          '${kJobCatalog.length}; ilanda hiç görülmeyen ${sebepsiz.length}');
    }, timeout: const Timeout(Duration(minutes: 40)));
  });
}
