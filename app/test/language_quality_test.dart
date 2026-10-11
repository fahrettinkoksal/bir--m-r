import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Metin kalitesi denetimi (D-127).
///
/// Faho bildirdi: oyundaki birçok metin "yapay zekâ yazmış gibi"
/// duruyor. `docs/WRITING_STYLE_TR.md` bu kalıpları yasakladı.
///
/// Bu test bir **ölçüm aracıdır**, kelime polisi değil. Kalıpların
/// tamamen yok olmasını şart koşmaz; sayıyı raporlar ve **artışa karşı**
/// bir tavan koyar. Böylece yeni yazılan metinler eski robotik dile geri
/// dönemez.
void main() {
  /// Oyuncunun gördüğü metinleri taşıyan dosyalar.
  final List<String> hedefler = <String>[
    'lib/data',
    'lib/domain',
  ];

  /// `docs/WRITING_STYLE_TR.md` yasak listesi.
  const Map<String, String> yasak = <String, String>{
    'olumlu yönde': 'rapor dili',
    'olumsuz yönde': 'rapor dili',
    'bu deneyim': 'rapor dili',
    'aranızdaki bağ güçlendi': 'klişe',
    'önemli bir karar verdin': 'klişe',
    'duygusal açıdan': 'rapor dili',
    'katkı sağladı': 'rapor dili',
    'hayatında yeni bir dönem': 'klişe',
    'kendini daha iyi hissettin': 'klişe',
    'bu durum seni': 'rapor dili',
    'kaliteli vakit': 'klişe',
    'etkiledi.': 'rapor dili',
  };

  List<File> dartFiles() {
    final List<File> out = <File>[];
    for (final String dir in hedefler) {
      final Directory d = Directory(dir);
      if (!d.existsSync()) continue;
      for (final FileSystemEntity f in d.listSync(recursive: true)) {
        if (f is File && f.path.endsWith('.dart')) out.add(f);
      }
    }
    return out;
  }

  test('robotik kalıplar ölçülür ve artmaz', () {
    final Map<String, List<String>> bulunan = <String, List<String>>{};
    for (final File f in dartFiles()) {
      final String icerik = f.readAsStringSync();
      for (final String kalip in yasak.keys) {
        if (!icerik.toLowerCase().contains(kalip.toLowerCase())) continue;
        for (final String satir in icerik.split('\n')) {
          if (satir.trimLeft().startsWith('//')) continue;
          if (satir.trimLeft().startsWith('///')) continue;
          if (!satir.toLowerCase().contains(kalip.toLowerCase())) continue;
          bulunan
              .putIfAbsent(kalip, () => <String>[])
              .add('${f.path}: ${satir.trim()}');
        }
      }
    }

    int toplam = 0;
    for (final MapEntry<String, List<String>> e in bulunan.entries) {
      toplam += e.value.length;
      // ignore: avoid_print
      print('DIL "${e.key}" (${yasak[e.key]}): ${e.value.length} yerde');
      for (final String yer in e.value.take(4)) {
        // ignore: avoid_print
        print('DIL    $yer');
      }
    }
    // ignore: avoid_print
    print('DIL TOPLAM robotik kalıp: $toplam');

    // Tavan: bugünkü sayının üstüne çıkılamaz. Test yeni robotik metin
    // eklenmesini engeller; mevcutları temizlemek ayrı iştir.
    expect(
      toplam,
      lessThanOrEqualTo(prototypeOnlyRobotikTavan),
      reason: 'Robotik kalıp sayısı arttı. docs/WRITING_STYLE_TR.md oku: '
          'olay anlatımında rapor dili kullanılmaz.',
    );
  });

  test('yeni çocukluk olaylarında robotik kalıp yok', () {
    final File f = File('lib/data/event_pool_childhood.dart');
    expect(f.existsSync(), isTrue);
    final String icerik = f.readAsStringSync();
    for (final String kalip in yasak.keys) {
      for (final String satir in icerik.split('\n')) {
        if (satir.trimLeft().startsWith('//')) continue;
        if (satir.trimLeft().startsWith('///')) continue;
        expect(
          satir.toLowerCase().contains(kalip.toLowerCase()),
          isFalse,
          reason: 'Çocukluk havuzunda robotik kalıp: "$kalip" -> $satir',
        );
      }
    }
  });

  test('seçenek etiketleri kısa ve eylem gibi', () {
    // "Bu konuda onunla konuşmayı tercih et" gibi uzun, robotik
    // etiketler yasak (WRITING_STYLE_TR §8).
    final File f = File('lib/data/event_pool_childhood.dart');
    final RegExp etiket = RegExp(r"label: '([^']{1,200})'");
    final List<String> uzunlar = <String>[];
    for (final RegExpMatch m in etiket.allMatches(f.readAsStringSync())) {
      final String l = m.group(1)!;
      if (l.length > 34) uzunlar.add(l);
    }
    expect(
      uzunlar,
      isEmpty,
      reason: 'Seçenek etiketi çok uzun: ${uzunlar.join(" | ")}',
    );
  });
}

/// prototypeOnly: bugün ölçülen robotik kalıp sayısı.
///
/// Sayı **düşürülmek** içindir; yükseltilmesi metin kalitesinin
/// gerilediği anlamına gelir.
const int prototypeOnlyRobotikTavan = 40;
