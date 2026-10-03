// Paket AR — hikâye izlerinin denetimi.
//
// `EKSIKLER.md` §7'nin birinci maddesi: "Ölü hikâye izlerini araştır —
// 10 iz hiç konmuyor. Yeni içerik yazmadan önce yazılmış içeriğin
// çalıştığından emin olmak gerekir."
//
// Hikâye izi (D-008, D-022) bir seçimin geleceğe bıraktığı işarettir:
// `EventChoice.addFlags` izi koyar, `EventRequirement.requiredFlags` onu
// arar. Bir iz üç şekilde ölü olabilir:
//
//   1. ARANIYOR AMA HİÇ KONMUYOR — o olay hiçbir hayatta açılamaz.
//      Bu bir üretim hatasıdır ve testle kalıcı olarak yasaklanır.
//   2. KONUYOR AMA HİÇ OKUNMUYOR — yazılmış iz boşa gidiyor. Hata
//      değil ama yarım kalmış hikâye; ölçülür ve büyümesi engellenir.
//   3. TANIMLI AMA HİÇ KULLANILMIYOR — ölü sabit.
//
// Ayrıca izin **gerçekten konup konmadığı** oynanarak ölçülür: katalog
// izi koyabiliyor olabilir ama ona giden yol pratikte kapalıysa içerik
// yine ölüdür.
library;

import 'dart:io';

import 'package:bir_omur/data/event_pool.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/coverage_bot.dart';

/// Motor tarafında (katalog dışında) konan izler **kaynaktan okunur**.
///
/// Elle tutulan bir liste bayatlıyor: ilk denemede `evlendi` unutulmuştu
/// ve test, evlilik motorunun koyduğu bir izi "hiç konmuyor" sanıp yanlış
/// hata verdi. Bu yüzden liste yazılmıyor, `lib/` taranıyor.
Set<String> _motordanKonanIzler() {
  final RegExp atama = RegExp(r'storyFlags\s*:\s*<String>\{(.*?)\}',
      dotAll: true);
  final RegExp ekleme = RegExp(r'\.add\(\s*StoryFlags\.(\w+)');
  final RegExp sabit = RegExp(r'StoryFlags\.(\w+)');
  final RegExp metin = RegExp(r"'([^'\n]+)'");

  // StoryFlags sabitlerinin değerleri (ad -> 'deger').
  final Map<String, String> deger = <String, String>{};
  final File tanim = File('lib/data/event_pool.dart');
  for (final RegExpMatch m in RegExp(r"static const String (\w+)\s*=\s*'([^']+)'")
      .allMatches(tanim.readAsStringSync())) {
    deger[m.group(1)!] = m.group(2)!;
  }

  final Set<String> out = <String>{};
  void topla(String govde) {
    for (final RegExpMatch m in sabit.allMatches(govde)) {
      out.add(deger[m.group(1)!] ?? m.group(1)!);
    }
    for (final RegExpMatch m in metin.allMatches(govde)) {
      out.add(m.group(1)!);
    }
  }

  for (final FileSystemEntity f in Directory('lib').listSync(recursive: true)) {
    if (f is! File || !f.path.endsWith('.dart')) continue;
    if (f.path.replaceAll(r'\', '/').contains('/data/')) continue;
    final String kaynak = f.readAsStringSync();
    for (final RegExpMatch m in atama.allMatches(kaynak)) {
      topla(m.group(1)!);
    }
    for (final RegExpMatch m in ekleme.allMatches(kaynak)) {
      out.add(deger[m.group(1)!] ?? m.group(1)!);
    }
  }
  return out;
}

/// Bütün `static const String` iz sabitleri: ad -> **değer kümesi**.
///
/// Küme olmak zorunda: `lib/` içinde aynı Dart adını taşıyan ama farklı
/// değere sahip sabitler var (`ChainFlags.borcVerdi` =
/// 'zincir_borclu_arkadas', `MidlifeFlags.borcVerdi` = 'orta_borc_verdi',
/// `CrimeFlags.borcVerdi` = 'suc_borclu'). İlk denemede bu harita
/// ad -> tek değer olarak kurulmuştu; çakışan ad kendini eziyordu ve
/// çakışmayı bildiren test **0** basıyordu — yani yanlış güven veriyordu.
Map<String, Set<String>> _izSabitleri() {
  final Map<String, Set<String>> out = <String, Set<String>>{};
  for (final FileSystemEntity f in Directory('lib').listSync(recursive: true)) {
    if (f is! File || !f.path.endsWith('.dart')) continue;
    for (final RegExpMatch m
        in RegExp("static const String (\\w+)\\s*=\\s*'([^']+)'")
            .allMatches(f.readAsStringSync())) {
      out.putIfAbsent(m.group(1)!, () => <String>{}).add(m.group(2)!);
    }
  }
  return out;
}

/// Motorun **okuduğu** izler — katalog dışında kalan bütün kontroller.
///
/// AR/1 "sessiz iz" derken yalnızca katalog olaylarının
/// `requiredFlags`/`forbiddenFlags` listesine bakıyordu ve bu sayıyı
/// **abartıyordu**: `sinav8_kaygi` hiçbir olay tarafından aranmıyor ama
/// `EducationPath` onu okuyup sınav puanına −4 veriyor. Yani iz sessiz
/// değil; yalnızca hikâye karşılığı yok. İki durum ayrı şeydir:
///
///   MEKANİK          — motor okuyor, etkisi var, anlatısı yok.
///   GERÇEKTEN SESSİZ — hiçbir yer okumuyor; yazılan iz boşa gidiyor.
///
/// `storyFlags`/`flags` üzerindeki `contains` çağrıları taranır. Sabit adı
/// hem `Sinif.sabit` hem **noktasız** `sabit` biçiminde geçebilir; ilk
/// denemede yalnızca noktalı biçim aranıyordu ve
/// `storyFlags.contains(flagSorumlulukAldi)` gözden kaçmıştı.
///
/// **Belirsiz ad okunmuş sayılmaz.** Bir ad birden fazla değere
/// gösteriyorsa hangi izin okunduğu bu taramayla bilinemez; o izi
/// "okunuyor" kabul etmek denetimi gevşetir ve ölü içeriği saklar. Bu
/// yüzden belirsiz adlar atlanır ve [belirsiz] listesine yazılır.
Set<String> _motordanOkunanIzler(
  Map<String, Set<String>> sabitler, {
  required Set<String> belirsiz,
}) {
  final RegExp cagri =
      RegExp(r'(?:storyFlags|flags)\s*\.\s*contains\(\s*([^)]+?)\s*\)');
  final RegExp ad = RegExp(r'\b(?:\w+\.)?(\w+)\b');
  final RegExp metin = RegExp(r"'([^'\n]+)'");
  final Set<String> out = <String>{};
  for (final FileSystemEntity f in Directory('lib').listSync(recursive: true)) {
    if (f is! File || !f.path.endsWith('.dart')) continue;
    if (f.path.replaceAll(r'\', '/').contains('/data/')) continue;
    final String kaynak = f.readAsStringSync();
    for (final RegExpMatch m in cagri.allMatches(kaynak)) {
      final String arg = m.group(1)!;
      for (final RegExpMatch k in ad.allMatches(arg)) {
        final Set<String>? v = sabitler[k.group(1)!];
        if (v == null) continue;
        if (v.length > 1) {
          belirsiz.add('${k.group(1)} -> ${(v.toList()..sort()).join(" | ")}');
          continue;
        }
        out.add(v.single);
      }
      for (final RegExpMatch k in metin.allMatches(arg)) {
        out.add(k.group(1)!);
      }
    }
  }
  return out;
}

Set<String> _katalogdanKonan() {
  final Set<String> out = <String>{};
  for (final GameEvent e in kEventPool) {
    for (final EventChoice c in e.choices) {
      out.addAll(c.addFlags);
    }
  }
  return out;
}

Set<String> _katalogdanAranan() {
  final Set<String> out = <String>{};
  for (final GameEvent e in kEventPool) {
    out.addAll(e.requirement.requiredFlags);
    out.addAll(e.requirement.forbiddenFlags);
  }
  return out;
}

Set<String> _katalogdanSilinen() {
  final Set<String> out = <String>{};
  for (final GameEvent e in kEventPool) {
    for (final EventChoice c in e.choices) {
      out.addAll(c.removeFlags);
    }
  }
  return out;
}

void main() {
  final Set<String> motorIzleri = _motordanKonanIzler();
  final Set<String> konan = <String>{
    ..._katalogdanKonan(),
    ...motorIzleri,
  };
  final Set<String> aranan = _katalogdanAranan();
  final Set<String> silinen = _katalogdanSilinen();

  group('Hikâye izleri — statik denetim', () {
    test('motor izleri kaynaktan okunabiliyor', () {
      // Tarama bozulursa bütün denetim sessizce yanlış sonuç verir.
      expect(motorIzleri, isNotEmpty,
          reason: 'lib/ taraması hiç motor izi bulamadı; '
              'desen bozulmuş olabilir.');
      // ignore: avoid_print
      print('Motor tarafında konan izler: '
          '${(motorIzleri.toList()..sort()).join(", ")}');
    });

    test('aranan her izin bir üreticisi var (ölü iz yok)', () {
      final List<String> olu = (aranan.difference(konan)).toList()..sort();
      final Map<String, List<String>> nerede = <String, List<String>>{};
      for (final String iz in olu) {
        for (final GameEvent e in kEventPool) {
          if (e.requirement.requiredFlags.contains(iz) ||
              e.requirement.forbiddenFlags.contains(iz)) {
            nerede.putIfAbsent(iz, () => <String>[]).add(e.id);
          }
        }
      }
      expect(
        olu,
        isEmpty,
        reason: 'Şu izleri arayan olay var ama hiçbir seçim onları '
            'koymuyor; o olaylar hiçbir hayatta açılamaz:\n'
            '${nerede.entries.map((MapEntry<String, List<String>> e) =>
                '  ${e.key} <- ${e.value.join(", ")}').join("\n")}',
      );
    });

    test('hiçbir yerin okumadığı iz sayısı artmıyor', () {
      // Katalogda aranmayan izler. Bir kısmını motor okuyor olabilir — o
      // zaman iz sessiz değil, yalnızca anlatısı yok. Ayrım AS/1'de
      // ölçülmeye başladı; eski 38 sayısı yanlış şeyi sayıyordu.
      final Set<String> katalogsuz =
          konan.difference(aranan).difference(silinen);
      final Set<String> belirsiz = <String>{};
      final Set<String> motorOkur =
          _motordanOkunanIzler(_izSabitleri(), belirsiz: belirsiz);
      final List<String> mekanik = katalogsuz.intersection(motorOkur).toList()
        ..sort();
      final List<String> sessiz = katalogsuz.difference(motorOkur).toList()
        ..sort();

      // ignore: avoid_print
      print('\n'
          '======================================================\n'
          'İZİN KARŞILIĞI VAR MI?\n'
          '======================================================\n'
          'Katalogda aranmayan iz             : ${katalogsuz.length}\n'
          '  MEKANİK (motor okuyor)           : ${mekanik.length}\n'
          '  GERÇEKTEN SESSİZ (kimse okumuyor): ${sessiz.length}');

      // ignore: avoid_print
      print('\nMEKANİK — etkisi var, hikâyesi yok:');
      for (final String iz in mekanik) {
        // ignore: avoid_print
        print('  $iz');
      }

      // ignore: avoid_print
      print('\nGERÇEKTEN SESSİZ — yazılan iz boşa gidiyor:');
      for (final String iz in sessiz) {
        final List<String> koyan = <String>[];
        for (final GameEvent e in kEventPool) {
          for (final EventChoice c in e.choices) {
            if (c.addFlags.contains(iz)) koyan.add('${e.id}/${c.id}');
          }
        }
        // ignore: avoid_print
        print('  $iz  <- ${koyan.isEmpty ? "motor" : koyan.join(", ")}');
      }

      if (belirsiz.isNotEmpty) {
        // Belirsiz ad okunmuş sayılmadı; burada görünür kalsın ki elle
        // bakılabilsin.
        // ignore: avoid_print
        print('\nBelirsiz sabit adı (okunmuş SAYILMADI):');
        for (final String b in (belirsiz.toList()..sort())) {
          // ignore: avoid_print
          print('  $b');
        }
      }

      // 3 Ekim 2026'da ölçülen durum (AS/1). Bağımsız bir taramayla da
      // doğrulandı: 6 mekanik, 32 sessiz. Hata değil, eksik: yazılmış bir
      // iz hiçbir yerde okunmuyor. Sayı **artmamalı** — yeni iz koyan bir
      // seçim yazıldıysa onu okuyan bir olay ya da motor kuralı da
      // yazılmalı.
      const int olculenSessiz = 32;
      expect(
        sessiz.length,
        lessThanOrEqualTo(olculenSessiz),
        reason: 'Hiçbir yerin okumadığı iz sayısı $olculenSessiz idi, '
            'şimdi ${sessiz.length}. Yeni iz koyan seçim yazıldıysa onu '
            'okuyan olay ya da motor kuralı da yazılmalı.\n'
            'Sessiz izler: ${sessiz.join(", ")}',
      );

      // Tarama bozulursa sayı sahte biçimde düşer ve test boşa geçer.
      expect(motorOkur, isNotEmpty,
          reason: 'Motorun okuduğu hiç iz bulunamadı; contains taraması '
              'bozulmuş olabilir.');
    });

    test('aynı Dart adını paylaşan iz sabitleri belgelenmiş', () {
      // `ChainFlags.borcVerdi` = 'zincir_borclu_arkadas',
      // `MidlifeFlags.borcVerdi` = 'orta_borc_verdi' ve
      // `CrimeFlags.borcVerdi` = 'suc_borclu' üç ayrı izdir. Ada güvenen
      // bir denetim bunları tek iz sanar ve "bu iz okunuyor" diye yanlış
      // rapor verir. Bu test tuzağı görünür tutar.
      final Map<String, Set<String>> sabitler = _izSabitleri();
      final List<String> cakisan = sabitler.entries
          .where((MapEntry<String, Set<String>> e) => e.value.length > 1)
          .map((MapEntry<String, Set<String>> e) =>
              '${e.key} -> ${(e.value.toList()..sort()).join(" | ")}')
          .toList()
        ..sort();
      // ignore: avoid_print
      print('\nAynı Dart adını paylaşan iz sabitleri (${cakisan.length}):');
      for (final String c in cakisan) {
        // ignore: avoid_print
        print('  $c');
      }
      // Tuzağın hâlâ var olduğunu sabitle: çakışma **sıfıra düşerse** bu
      // testin varlık sebebi kalkar, ama o zamana kadar denetimlerin
      // değer üzerinden çalışması zorunludur.
      expect(sabitler, isNotEmpty, reason: 'İz sabitleri taraması boş.');
      expect(cakisan, isNotEmpty,
          reason: 'Çakışan ad bulunamadı. Tarama ad -> **küme** kurmuyorsa '
              'çakışma kendini ezer ve bu test yanlış güven verir; '
              '_izSabitleri() gerçekten küme döndürüyor mu?');
    });
    test('her izin en az bir koyan ya da arayan tarafı var', () {
      // Katalogda geçen ama ne konan ne aranan bir iz kalmamalı; böyle
      // bir iz yalnızca yazım hatası olabilir.
      final Set<String> hepsi = <String>{...konan, ...aranan, ...silinen};
      expect(hepsi, isNotEmpty);
      for (final String iz in silinen) {
        expect(
          konan.contains(iz) || aranan.contains(iz),
          isTrue,
          reason: '"$iz" yalnızca removeFlags içinde geçiyor; '
              'ne konuyor ne aranıyor.',
        );
      }
    });
  });

  group('Hikâye izleri — oynanarak ölçüm', () {
    test('katalogdaki izler gerçekten konuyor', () {
      final Set<String> gorulen = <String>{};
      final Set<String> cikanOlay = <String>{};
      int hayat = 0;

      for (final CoveragePlan plan in CoveragePlan.values) {
        for (int tohum = 0; tohum < 4; tohum++) {
          final CoverageResult r = runCoverageLife(
            plan: plan,
            seed: plan.index * 1000 + tohum * 37 + 11,
          );
          gorulen.addAll(r.storyFlags);
          cikanOlay.addAll(r.firedEvents);
          hayat++;
        }
      }

      final List<String> konmayan =
          (_katalogdanKonan().difference(gorulen)).toList()..sort();
      final List<String> izliOlaylar = <String>[
        for (final GameEvent e in kEventPool)
          if (e.requirement.requiredFlags.isNotEmpty) e.id,
      ]..sort();
      final List<String> cikmayanIzli =
          izliOlaylar.where((String id) => !cikanOlay.contains(id)).toList();

      // ignore: avoid_print
      print('\n'
          '======================================================\n'
          'HİKÂYE İZİ ÖLÇÜMÜ — $hayat kapsam hayatı\n'
          '======================================================\n'
          'Katalogda iz koyan seçim        : ${_katalogdanKonan().length}\n'
          'Oynarken gerçekten konan iz     : '
          '${_katalogdanKonan().difference(konmayan.toSet()).length}\n'
          'Hiç konmayan iz                 : ${konmayan.length}\n'
          'İz arayan olay                  : ${izliOlaylar.length}\n'
          'Bunlardan ekrana hiç gelmeyen   : ${cikmayanIzli.length}\n'
          'Toplam ekrana gelen farklı olay : ${cikanOlay.length}');
      if (konmayan.isNotEmpty) {
        // ignore: avoid_print
        print('\nHiç konmayan izler:');
        for (final String iz in konmayan) {
          final List<String> koyan = <String>[];
          for (final GameEvent e in kEventPool) {
            for (final EventChoice c in e.choices) {
              if (c.addFlags.contains(iz)) {
                koyan.add('${e.id} (${e.requirement.minAge}-'
                    '${e.requirement.maxAge} yaş)');
              }
            }
          }
          // ignore: avoid_print
          print('  $iz  <- ${koyan.join(", ")}');
        }
      }
      if (cikmayanIzli.isNotEmpty) {
        // ignore: avoid_print
        print('\nİz arayan ama hiç çıkmayan olaylar:');
        for (final String id in cikmayanIzli) {
          final GameEvent e =
              kEventPool.firstWhere((GameEvent x) => x.id == id);
          // ignore: avoid_print
          print('  $id  (${e.requirement.minAge}-${e.requirement.maxAge} yaş, '
              'ister: ${e.requirement.requiredFlags.join("+")})');
        }
      }

      // Bu bir **teşhistir**: sayı bir ürün kuralı değil, ölçümdür.
      // Tek sert iddia, ölçümün çalıştığı: hayatlar gerçekten oynandı ve
      // izler gerçekten kondu.
      expect(hayat, CoveragePlan.values.length * 4);
      expect(gorulen, isNotEmpty,
          reason: 'Hiçbir hayatta hiçbir iz konmadıysa ölçüm bozuktur.');
      expect(cikanOlay.length, greaterThan(50),
          reason: 'Kapsam hayatları olay görmüyorsa ölçüm bozuktur.');
    }, timeout: const Timeout(Duration(minutes: 10)));
  });
}
