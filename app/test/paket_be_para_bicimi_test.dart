// Para değişimi binlik ayraçla yazılır.
//
// **Nasıl bulundu.** Bot dökümü (`ekran_dokumu_bot_test.dart`) 35
// yaşındaki oyuncunun Hayat ekranında yıl özeti kartını bastı:
//
//     34 yaşın böyle geçti
//     Mutluluk +5
//     Karizma +4
//     Cüzdan -988619 ₺
//
// Dökümün başlığında aynı anda "cüzdan 2772029 ₺" yazıyordu; ilk anda
// ekranın cüzdanı eksi gösterdiğini sanıp D-080'in ("cüzdan eksiye
// düşmez") ihlali olarak raporlayacaktım. Satırı bağlamıyla okuyunca
// gerçek ortaya çıktı: o satır **bakiye değil, yıllık değişim** ve
// değeri doğru. Yanlış olan tek şey **biçim**.
//
// **Kök neden.** `AppliedEffect.text` sayıyı ham basıyordu (`'$d'`).
// Stat değişimlerinde (+5) sorun yok; birimi ` ₺` olanlarda yedi haneli
// sayı tek blok oluyordu. Oyunun geri kalanı `trMoney`/`trNumber`
// kullanıyor ve `trNumber`in kendi açıklaması tam bu yüzden yazılmış:
// "Uzun tutarlar ekranda '163400' diye tek blok hâlinde okunmuyordu."
//
// İki yerde görünüyordu — yıl özeti (`year_review.dart`) ve olay sonucu
// penceresi (`effect_diff.dart`) — yani **parası değişen her olay**.
library;

import 'dart:io';

import 'package:bir_omur/domain/models/applied_effect.dart';
import 'package:bir_omur/text/turkish_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('büyük para değişimi ayraçlı yazılır', () {
    expect(
      const AppliedEffect(label: 'Cüzdan', delta: -988619, unit: ' ₺').text,
      'Cüzdan -988.619 ₺',
    );
    expect(
      const AppliedEffect(label: 'Cüzdan', delta: 1171847, unit: ' ₺').text,
      'Cüzdan +1.171.847 ₺',
    );
  });

  test('stat değişimi olduğu gibi kalır', () {
    // Üç haneye kadar ayraç yok; stat satırları değişmemeli.
    expect(const AppliedEffect(label: 'Mutluluk', delta: 5).text,
        'Mutluluk +5');
    expect(const AppliedEffect(label: 'Mutluluk', delta: -6).text,
        'Mutluluk -6');
    expect(const AppliedEffect(label: 'Sağlık', delta: 0).text, 'Sağlık 0');
  });

  test('sayısız kazanım etiketten ibaret kalır', () {
    expect(const AppliedEffect(label: 'Bisiklet kazanıldı').text,
        'Bisiklet kazanıldı');
  });

  test('ayraç oyunun geri kalanıyla aynı biçimde', () {
    // Aynı tutar `trMoney` ile ve etki satırında aynı görünmeli:
    // iki ayrı para biçimi olmamalı.
    for (final int tutar in <int>[1200, 50000, 988619, 1171847]) {
      final String etki =
          AppliedEffect(label: 'Cüzdan', delta: tutar, unit: ' ₺').text;
      expect(etki, 'Cüzdan +${trMoney(tutar)}',
          reason: 'Etki satırı ile trMoney farklı biçim üretiyor.');
    }
  });

  test('hiçbir etki satırı ayraçsız dört haneli sayı bırakmıyor', () {
    // Deseni doğrudan sınıyoruz: 1000 ve üstü bir para değişiminde
    // ayraç olmak zorunda.
    for (final int tutar in <int>[1000, -1000, 12345, -9876543]) {
      final String etki =
          AppliedEffect(label: 'Cüzdan', delta: tutar, unit: ' ₺').text;
      expect(etki, contains('.'),
          reason: '$tutar için ayraç yok: "$etki"');
    }
  });

  // -------------------------------------------------------------------
  // Paket DM ile sıkıştırıldı: **kaynak taraması**
  // -------------------------------------------------------------------
  //
  // Bu dosya üç yıl boyunca yalnızca `AppliedEffect.text`'i sınadı ve
  // kuralı orada tuttu. Paket DM sigorta sayfasını ilk kez okudu ve
  // ekranda "5000 ₺" buldu: aynı kartın bir üst satırında "Yıllık prim
  // 5.000 ₺" yazarken. Yani kural vardı, bekçi vardı, ama bekçi
  // **yalnızca bir çağrı yolunu** tutuyordu.
  //
  // Tarama ölçüldü: depoda bu desenden **iki** yer vardı ve ikisi de
  // aynı dosyadaydı (`insurance.dart`). Birincisini gözle okuma,
  // ikincisini bu tarama buldu. Muafiyet listesi **yok**: tutar
  // ekranda ayraçsız yazılmaz.
  test('kaynakta ham para interpolasyonu yok (Paket DM)', () {
    final RegExp desen = RegExp(r'\$\{([^{}]{0,80}?)\}\s*₺');
    const List<String> bicimciler = <String>[
      'trMoney',
      'trNumber',
      'trMoneyShort',
      'Label',
      'label',
    ];
    final List<String> bulgu = <String>[];

    for (final FileSystemEntity e
        in Directory('lib').listSync(recursive: true)) {
      if (e is! File || !e.path.endsWith('.dart')) continue;
      final List<String> satirlar = e.readAsLinesSync();
      for (int i = 0; i < satirlar.length; i++) {
        final String satir = satirlar[i];
        if (satir.trimLeft().startsWith('//')) continue;
        for (final RegExpMatch m in desen.allMatches(satir)) {
          final String ifade = m.group(1)!;
          if (bicimciler.any((String b) => ifade.contains(b))) continue;
          bulgu.add('${e.path}:${i + 1} → \${$ifade} ₺');
        }
      }
    }

    expect(
      bulgu,
      isEmpty,
      reason: 'Tutar ekranda ayraçsız yazılıyor; `trMoney` kullan:\n'
          '${bulgu.join("\n")}',
    );
  });
}
