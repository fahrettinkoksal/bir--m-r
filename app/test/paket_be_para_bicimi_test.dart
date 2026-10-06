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
}
