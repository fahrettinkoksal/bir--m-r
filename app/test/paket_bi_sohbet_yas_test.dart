// Paket BI — sohbet metinleri kişinin **yaşına** uymalı.
//
// **Nasıl bulundu.** Ekran dökümünün dördüncü turunda yeni doğan bebek
// karesi okundu (`ekran_dokumu_ozel_durum_test.dart`). Aynı yılın
// günlüğünde iki satır yan yana duruyordu:
//
//   "Kemal adında bir oğlunuz oldu. Doğum masrafı 65.000 ₺ tuttu."
//   "Kemal okulda olanları anlattı; hikâyenin yarısı gerçek…"
//
// Kök neden `lib/data/interaction_texts.dart`: sohbet havuzu çocuk için
// `age <= 12` ile seçiliyordu, yani 0-3 yaşındaki bebek de okul/soru/
// korku havuzuna giriyordu. Hemen altındaki "vakit geçir" dalı ise
// `age <= 3` için ayrı bir bebek havuzu kullanıyor: aynı dosya bebeği
// zaten ayırmış, sohbet dalı atlamıştı.
//
// İkinci bulgu aynı okumadan çıktı: `_sohbetGenel` havuzundaki
// "kendi yaşındayken neler yaptığını anlattı" satırı oyuncudan
// **küçük** olan kişinin de ağzına girebiliyordu (13-17 yaş çocuk,
// küçük kardeş, sınıf arkadaşı, yeğen…).
//
// Bu test ikisini de kalıcı olarak kapatır. Metin havuzlarını isimle
// değil **anlamla** denetler: bebek sohbetinde okul/soru/korku geçmez,
// oyuncudan küçük kimse "kendi yaşındayken" diyemez.
library;

import 'dart:math';

import 'package:bir_omur/data/interaction_texts.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/interaction.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/generation_fixtures.dart';

Person _kisi({
  required int age,
  required RelationType relation,
  String firstName = 'Kemal',
}) {
  // Kişi kaydı ortak fixture ile kurulur: zorunlu alanlar (çalışma
  // durumu, servet basamağı) elle uydurulmaz.
  return kisi(
    id: 'k-$age-${relation.name}',
    relation: relation,
    gender: Gender.erkek,
    age: age,
    firstName: firstName,
    lastName: 'Erdoğan',
    hane: true,
    bond: 70,
  );
}

/// Aynı yaş için havuzun tamamını görmek adına çok tohumla üretir.
List<String> _metinler({
  required Person kisi,
  required InteractionKind kind,
  required int playerAge,
}) {
  return <String>[
    for (int seed = 0; seed < 60; seed++)
      interactionText(
        rng: Random(seed),
        person: kisi,
        kind: kind,
        accepted: true,
        noNewBenefit: false,
        playerAge: playerAge,
      ),
  ];
}

void main() {
  group('bebekle sohbet', () {
    // 0-3 yaş: konuşmayan ya da yeni konuşan çocuk.
    for (final int yas in <int>[0, 1, 2, 3]) {
      test('$yas yaşındaki çocukla sohbette okul/soru/korku geçmez', () {
        final List<String> metinler = _metinler(
          kisi: _kisi(age: yas, relation: RelationType.cocuk),
          kind: InteractionKind.sohbet,
          playerAge: 34,
        );
        expect(metinler, isNotEmpty);
        for (final String m in metinler) {
          expect(m.contains('okul'), isFalse,
              reason: '$yas yaşındaki çocuk okuldan bahsediyor: $m');
          expect(m.contains('soru sordu'), isFalse,
              reason: '$yas yaşındaki çocuk soru soruyor: $m');
          expect(m.contains('korkular'), isFalse,
              reason: '$yas yaşındaki çocukla korkular konuşuluyor: $m');
        }
      });
    }

    test('okul çağındaki çocukta okul satırı kapanmadı', () {
      // Düzeltme fazla geniş olmasın: 4-12 yaşta okul havuzu durmalı.
      final List<String> metinler = _metinler(
        kisi: _kisi(age: 9, relation: RelationType.cocuk),
        kind: InteractionKind.sohbet,
        playerAge: 40,
      );
      expect(metinler.any((String m) => m.contains('okul')), isTrue,
          reason: '9 yaşındaki çocuğun okul satırı kaybolmuş');
    });
  });

  group('"kendi yaşındayken" satırı', () {
    const String kalip = 'kendi yaşındayken';

    test('oyuncudan küçük kimse bunu söylemez', () {
      // Çocuk (13-17), küçük kardeş, sınıf arkadaşı, yeğen: hepsi
      // oyuncudan küçük ve hepsi `_sohbetGenel` havuzuna düşüyor.
      final List<(int, RelationType)> kucukler = <(int, RelationType)>[
        (15, RelationType.cocuk),
        (22, RelationType.cocuk),
        (12, RelationType.kardes),
        (16, RelationType.sinifArkadasi),
        (9, RelationType.yegen),
      ];
      for (final (int yas, RelationType bag) in kucukler) {
        final List<String> metinler = _metinler(
          kisi: _kisi(age: yas, relation: bag),
          kind: InteractionKind.sohbet,
          playerAge: 45,
        );
        for (final String m in metinler) {
          expect(m.contains(kalip), isFalse,
              reason: '$yas yaşındaki ${bag.name} oyuncuya (45) '
                  '"kendi yaşındayken" diyor: $m');
        }
      }
    });

    test('oyuncudan büyük kişide satır durmalı', () {
      // Düzeltme satırı tamamen öldürmesin: büyükten gelirse anlamlı.
      final List<String> metinler = _metinler(
        kisi: _kisi(age: 70, relation: RelationType.anne),
        kind: InteractionKind.sohbet,
        playerAge: 40,
      );
      expect(metinler.any((String m) => m.contains(kalip)), isTrue,
          reason: '70 yaşındaki anne artık "kendi yaşındayken" demiyor; '
              'düzeltme satırı tamamen kaldırmış');
    });
  });
}
