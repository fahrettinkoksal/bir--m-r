// Kodda atıf verilen her karar numarası DECISIONS.md'de tanımlı olsun.
//
// **Bu testin varlık sebebi gerçek bir hata — ve hatayı ben yaptım.**
// Paket AY'de Faho'nun onayladığı on iki kararı `DECISIONS.md`'ye
// **D-137…D-148** diye yazdım. Oysa kod tabanı o numaraları **zaten**
// başka kurallar için kullanıyordu: `D-139` kefalet ve cezaevi hayatını
// gösteriyordu (altı dosyada), ben onu "futbol kazancı asgari ücret
// çıpasından türer" yaptım. `D-146` evcil hayvan sayfasında, `D-147`
// kayıt kodeğinde geçiyordu. Yani kodun yetki diye gösterdiği numaralar
// bir gecede başka kurallara işaret eder oldu.
//
// Numaralarım D-164…D-175'e taşındı (içerik aynı, yalnızca etiket).
//
// Tarama ayrıca şunu gösterdi: **D-137…D-163 arası 27 numara kodda
// yetki olarak kullanılıyordu ama `DECISIONS.md`'de hiç tanımlı
// değildi.** Kural metinleri koddan yeniden kuruldu — çoğunun yorumunda
// Faho'nun kendi cümlesi alıntılıydı — ve Faho'nun onayıyla (6 Ekim
// 2026, Q-196) `DECISIONS.md`'ye girdi. Muafiyet listesi bu yüzden
// **boş**: artık kodda atıf verilen her numaranın yazılı bir karşılığı
// var.
//
// Bu dosya o sınıf hatayı anında yakalar: tanımsız bir numaraya atıf
// verildiği anda test kırılır.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Kodda geçen ama `DECISIONS.md`'de tanımı **olmayan** numaralar.
///
/// Boş olması iyidir. Buraya bir numara yalnızca **gerekçesiyle**
/// eklenir. Hiçbiri Claude tarafından uydurulmaz: kararın metnini Faho
/// yazar ya da onaylar (Q-196).
const Map<String, String> kTanimsizKararlar = <String, String>{};

void main() {
  test('kodda atıf verilen her karar DECISIONS.md\'de tanımlı', () {
    final String kararlar = File('../DECISIONS.md').readAsStringSync();

    // Tanım satırı: `- **D-NNN — ...`
    final Set<String> tanimli = RegExp(r'^- \*\*(D-\d{3})', multiLine: true)
        .allMatches(kararlar)
        .map((RegExpMatch m) => m.group(1)!)
        .toSet();

    expect(tanimli.length, greaterThan(100),
        reason: 'Tanım kalıbı bozulmuş olabilir: ${tanimli.length} karar '
            'bulundu.');

    final RegExp atif = RegExp(r'\bD-(\d{3})\b');
    final Map<String, Set<String>> eksik = <String, Set<String>>{};
    for (final Directory kok in <Directory>[Directory('lib'), Directory('test')]) {
      for (final File f in kok
          .listSync(recursive: true)
          .whereType<File>()
          .where((File f) => f.path.endsWith('.dart'))) {
        // Bu dosyanın kendisi tanımsız numaraları **listeliyor**;
        // listelemek atıf değildir.
        if (f.path.endsWith('decision_reference_test.dart')) continue;
        for (final RegExpMatch m in atif.allMatches(f.readAsStringSync())) {
          final String no = 'D-${m.group(1)}';
          if (tanimli.contains(no)) continue;
          if (kTanimsizKararlar.containsKey(no)) continue;
          eksik.putIfAbsent(no, () => <String>{}).add(f.path);
        }
      }
    }

    expect(eksik, isEmpty,
        reason: 'Bu karar numaralarına kodda atıf veriliyor ama '
            'DECISIONS.md\'de tanımları yok. Bir numara yetki gibi '
            'görünüyorsa arkasında yazılı bir karar olmalı:\n  '
            '${eksik.entries.map((MapEntry<String, Set<String>> e) => "${e.key}: ${e.value.join(", ")}").join("\n  ")}');
  });

  test('her tanımsız kararın yazılı gerekçesi var', () {
    for (final MapEntry<String, String> e in kTanimsizKararlar.entries) {
      expect(e.value.trim().length, greaterThan(20),
          reason: '${e.key} gerekçesiz bekliyor.');
    }
  });
}
