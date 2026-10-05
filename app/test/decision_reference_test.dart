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
// Tarama ayrıca şunu gösterdi: **D-149…D-163 kodda kullanılıyor ama
// `DECISIONS.md`'de hiç tanımlı değil.** On beş numara, yetki olarak
// gösteriliyor ve arkasında yazılı bir karar yok. Bunlar uydurulamaz:
// kuyruğa taşındı (Q-196) ve aşağıda **gerekçeleriyle** bekliyor.
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
const Map<String, String> kTanimsizKararlar = <String, String>{
  // Konular **atıf yerlerinden** türetildi; kararların metni yazılı
  // değil. Claude bunları uydurmaz (CLAUDE.md: kullanıcı onayı olmadan
  // DECISIONS.md'ye karar eklenmez). Hepsi Q-196'da bekliyor.
  'D-137': 'Araç ilanlarının yalnızca pazarda dolması (2. el araç '
      'pazarı, Paket V/4). Q-196.',
  'D-138': 'Mağazaların üç öbekte durması (Paket V/5). Q-196.',
  'D-139': 'Kefalet kartı ve kefaletle dışarıda olmak (Paket V/6). '
      'Q-196.',
  'D-140': 'Koğuş hayatı ve cezaevi eylemleri (Paket V/6). Q-196.',
  'D-141': 'Üvey anne ve üvey baba (Paket V/7). Q-196.',
  'D-142': 'Okul/kariyer ekranında gerekçeyle sorulmaması. Q-196.',
  'D-143': 'İşveren tarafının karşılığı (iş hayatı). Q-196.',
  'D-144': 'Sahiplenilmeyen hayvanın bakım giderinin oyuncudan '
      'çıkmaması (Paket N). Q-196.',
  'D-145': 'Pop-up çıkmama kuralı (bildirim eşiği). Q-196.',
  'D-146': 'İlişkiler menüsü ve kişi sayfası (Paket AO/8). Q-196.',
  'D-147': 'Bir yılda yapılabilecek toplam medya işi (Paket K/Q). '
      'Q-196.',
  'D-148': 'Araç giderleri (yaşam gideri dökümü, Paket S). Q-196.',
  'D-149': 'Arkadaş haberlerinin hangi yaşta geldiği ve tekrar '
      'sayacı. Q-196.',
  'D-150': 'Cümle bütünlüğü kuralı (Paket W). Q-196.',
  'D-151': 'İkiz gebelik: aynı doğumun ikinci bebeği (Paket X/1). '
      'Q-196.',
  'D-152': 'Birden çok dövüş dalı (Paket X/2-X/3). Q-196.',
  'D-153': 'Sağlık Geçmişi sayfası ve kronik hastalık (Paket Y/1). '
      'Q-196.',
  'D-154': 'Eşin kendi hayatının oyuncuyu da etkilemesi (Paket Y/2). '
      'Q-196.',
  'D-155': 'Meslekte ustalık ve itibar; zam talebinin yalnızca kıdeme '
      'bağlı olmaması (Paket Y/3). Q-196.',
  'D-156': 'Hayat Hedefleri sayfası (Paket Y/4). Q-196.',
  'D-157': 'Kazada sürücünün de aracın da hasar görmesi (Paket Z/1). '
      'Q-196.',
  'D-158': 'Çocuğun evlenmesi; kuralın tek yerde durması (Paket Z/2). '
      'Q-196.',
  'D-159': 'Şehirlerin kendi karakteri ve 0-1 katsayıları '
      '(Paket Z/3). Q-196.',
  'D-160': 'Boşanmada nafaka ve velayet (Paket Z/4). Q-196.',
  'D-161': 'Teklifin yalnızca gerçekten gelebiliyorsa görünmesi. '
      'Q-196.',
  'D-162': 'Yatırım türleri ve risk kademeleri (Paket AA/1). Q-196.',
  'D-163': 'Konut, kiracı ve ev sahibi olayları (Paket AB/5). Q-196.',
};

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
