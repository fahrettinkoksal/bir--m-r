import 'dart:io';

import 'package:bir_omur/domain/models/stats.dart';
import 'package:flutter_test/flutter_test.dart';

/// Azalan getiri (D-099).
///
/// Değer yükseldikçe her yeni puan pahalılaşır; hiçbir değer sıradan
/// tekrarlarla 100'e yapışmaz. Kayıplar tam uygulanır.
void main() {
  group('StatGain', () {
    test('düşük değerde kazanç tam uygulanır', () {
      expect(StatGain.apply(40, 5), 45);
      expect(StatGain.apply(0, 10), 10);
    });

    test('yükseldikçe aynı kazanç daha az getirir', () {
      final int dusuk = StatGain.apply(40, 5) - 40;
      final int orta = StatGain.apply(70, 5) - 70;
      final int yuksek = StatGain.apply(88, 5) - 88;
      final int tavan = StatGain.apply(94, 5) - 94;

      expect(dusuk, greaterThan(orta));
      expect(orta, greaterThan(yuksek));
      expect(yuksek, greaterThanOrEqualTo(tavan));
      // ignore: avoid_print
      print('AZALAN GETIRI (+5): 40 -> +$dusuk · 70 -> +$orta · '
          '88 -> +$yuksek · 94 -> +$tavan');
    });

    test('kayıp tam uygulanır ve pazarlık etmez', () {
      expect(StatGain.apply(90, -5), 85);
      expect(StatGain.apply(40, -5), 35);
      expect(StatGain.apply(2, -10), 0);
    });

    test('değer 0-100 aralığının dışına çıkmaz', () {
      expect(StatGain.apply(99, 50), lessThanOrEqualTo(100));
      expect(StatGain.apply(0, -5), 0);
    });

    test('tavanın üstündeki değer kazançla yükselmez, düşmez de', () {
      expect(StatGain.apply(98, 20), 98);
      expect(StatGain.apply(100, 5), 100);
      // Kayıp yine tam işler.
      expect(StatGain.apply(98, -3), 95);
    });

    test('tavana sıradan tekrarlarla yapışılmaz', () {
      // Yılda +4 kazandıran bir alışkanlık 40 yıl sürse bile...
      int deger = 50;
      for (int yil = 0; yil < 40; yil++) {
        deger = StatGain.apply(deger, 4);
      }
      // ignore: avoid_print
      print('40 YIL +4/yil: 50 -> $deger');
      expect(deger, lessThanOrEqualTo(StatGain.prototypeOnlySoftCap));
      expect(deger, greaterThan(80), reason: 'Emek karşılıksız da kalmamalı');
    });

    test('yükseğe çıkmanın bedeli ölçülür', () {
      final int ilk = StatGain.rawPointsFor(50, 75);
      final int sonra = StatGain.rawPointsFor(75, 93);
      // ignore: avoid_print
      print('HAM PUAN: 50 -> 75 = $ilk · 75 -> 93 = $sonra');
      expect(sonra, greaterThan(ilk), reason: 'Üst basamak daha pahalı');
    });
  });

  group('Stats.gain', () {
    const Stats taban = Stats(
      appearance: 50,
      happiness: 50,
      health: 90,
      intelligence: 95,
      charisma: 50,
    );

    test('her değer kendi seviyesine göre kazanır', () {
      final Stats sonra = taban.gain(
        appearance: 6,
        health: 6,
        intelligence: 6,
      );
      expect(sonra.appearance - 50, 6);
      expect(sonra.health - 90, lessThan(6));
      expect(sonra.intelligence - 95, lessThan(sonra.health - 90));
      // Dokunulmayan değerler aynı kalır.
      expect(sonra.happiness, 50);
      expect(sonra.charisma, 50);
    });

    test('copyWith kesin değer yazar, gain değişim uygular', () {
      expect(taban.copyWith(intelligence: 100).intelligence, 100);
      expect(
        taban.gain(intelligence: 5).intelligence,
        lessThanOrEqualTo(StatGain.prototypeOnlySoftCap),
      );
    });
  });

  test('oyun içindeki bütün stat artışları gain üzerinden geçer', () {
    // Azalan getiriyi atlayan bir yol kalmasın: kaynakta ham
    // `stats.copyWith(... + ...)` kullanımı aranır (D-099).
    final List<String> kacaklar = <String>[];
    for (final FileSystemEntity f in Directory('lib')
        .listSync(recursive: true)
        .where((FileSystemEntity f) => f.path.endsWith('.dart'))) {
      final String kaynak = File(f.path).readAsStringSync();
      if (kaynak.contains('stats.copyWith(')) kacaklar.add(f.path);
    }
    expect(
      kacaklar,
      isEmpty,
      reason: 'Bu dosyalar stat değerini doğrudan yazıyor; '
          'artış için Stats.gain kullanılmalı: ${kacaklar.join(', ')}',
    );
  });
}
