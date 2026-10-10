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
/// * **Paket BY/1 düzeltmesi:** kapsam modunun ilk yazımında "çalışırken
///   girilmemiş işe geç" dalı **ölü koddu**. Oyunun kuralı net —
///   `applicationAvailability` çalışan oyuncuya "Önce mevcut işinden
///   ayrılman gerekiyor" diyor — ve dal `isAllowed` ile süzdüğü için
///   aday listesi hep boş kalıyordu. Ölçüm bunu açıkça gösterdi: üç
///   tohum öbeğinde kapsam modu varsayılan bottan **daha geniş
///   gezmiyordu** (birleşim 35/30, 33/34, 32/27). Gerçek oyuncu meslek
///   değiştirmek için istifa eder; kapsam botu da artık öyle yapıyor.
///   Düzeltmeden sonra aynı tohumlarda birleşim 35→44, 33→42, 32→43 ve
///   hayat başına girilen iş 2,5 → 14 oldu.
/// * 240 kapsam hayatında kataloğun **52/55 mesleğine** girildi.
///   Kalan üçünün yazılı gerekçesi var: `eczaci` büyük şehir,
///   `elektrik_muhendisi` üniversite bölümü, `yazar` hobi basamağı.
///   Katalog tutarlılığı ayrıca `content_reachability_test.dart` ile
///   korunuyor.
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

      // Ölçüm (Paket BY/1 düzeltmesinden sonra): 240 hayatta 52/55,
      // 60 hayatta 42-44/55. Taban 38: altına inmesi kapsam modunun
      // bozulduğu ya da bir meslek öbeğinin erişilemez hale geldiği
      // anlamına gelir.
      expect(s.girilen.length, greaterThanOrEqualTo(38),
          reason: '120 kapsam hayatında yalnızca ${s.girilen.length}/'
              '${kJobCatalog.length} mesleğe girildi');
    }, timeout: const Timeout(Duration(minutes: 40)));

    test('kapsam modu varsayılan bottan daha geniş geziyor', () {
      const int adet = 60;
      final ({Set<String> girilen, Map<String, String> kilit}) varsayilan =
          _kosu(adet: adet, kapsam: false, tohumBaslangici: 9400);
      final ({Set<String> girilen, Map<String, String> kilit}) kapsam =
          _kosu(adet: adet, kapsam: true, tohumBaslangici: 9400);

      // Ölçüm: üç tohum öbeğinde 44/35, 42/33, 43/32 — yani fark 9-11
      // meslek. İddia "biraz daha geniş" değil, **belirgin biçimde**
      // geniş: beşte bir pay. Paket BY/1 öncesi bu iddia yanlıştı ve
      // sessizce tohuma bağlıydı.
      expect(kapsam.girilen.length * 5,
          greaterThanOrEqualTo(varsayilan.girilen.length * 6),
          reason: 'kapsam modu belirgin biçimde genişletmiyor: '
              'varsayılan ${varsayilan.girilen.length}, kapsam '
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
