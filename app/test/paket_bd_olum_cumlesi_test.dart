// Ölüm cümlesi bozuk kurulmaz.
//
// **Nasıl bulundu.** Ekran dökümü testi (`ekran_dokumu_test.dart`) tek
// bir hayatın günlüğünde şu satırları bastı:
//
//     Anneannen Ceren Turan uykusunda, sakin bir şekilde nedeniyle
//     vefat etti.
//     Babaannen Sevgi Erdoğan uykusunda, sakin bir şekilde nedeniyle
//     vefat etti.
//     Gelinin Elif Aydın uykusunda, sakin bir şekilde nedeniyle vefat
//     etti.
//
// **Kök neden.** `Mortality.causeFor` iki tür metin döndürüyor: isim
// öbeği ("yaşlılığa bağlı nedenler") ve zarf öbeği ("uykusunda, sakin
// bir şekilde", "uzun bir ömrün ardından"). Üç yazım yeri
// (`life_progression` içinde yakının ölümü ve **oyuncunun kendi
// ölümü**, `notices` içinde kayıp bildirimi) eki koşulsuz ekliyordu.
// İkincisi oyunun son cümlesi: "70 yaşında uzun bir ömrün ardından
// nedeniyle hayatını kaybettin."
//
// Gerekçelerin kendisi doğru; hata ekin koşulsuz eklenmesiydi. Çözüm
// `Mortality.causeClause`: zarf öbeğine ek eklemez.
//
// Bu dosyanın asıl değeri **tamlık denetimi**: yeni bir ölüm gerekçesi
// eklenip sınıflandırılmazsa test düşer, yani aynı hata ikinci kez
// sessizce giremez.
library;

import 'dart:math';

import 'package:bir_omur/domain/life/mortality.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('her gerekçe ya isim öbeği ya zarf öbeği olarak sınıflanmış', () {
    // `causeFor` üç yaş bandından çekiyor; hepsini tarıyoruz.
    final Set<String> uretilen = <String>{};
    for (int yas = 1; yas <= 110; yas++) {
      final Random rng = Random(yas);
      for (int deneme = 0; deneme < 60; deneme++) {
        uretilen.add(Mortality.causeFor(yas, rng));
      }
    }

    expect(uretilen, isNotEmpty);
    expect(
      uretilen.difference(Mortality.allPrototypeOnlyCauses),
      isEmpty,
      reason: 'Bu gerekçeler hiçbir kümede yok; cümleye nasıl '
          'yerleşecekleri belirsiz. Yeni gerekçeyi '
          'kNounPhraseCauses ya da kSelfContainedCauses içine ekle.',
    );
    expect(
      Mortality.allPrototypeOnlyCauses.difference(uretilen),
      isEmpty,
      reason: 'Bu gerekçeler sınıflanmış ama hiçbir yaşta üretilmiyor: '
          'ölü içerik.',
    );
    expect(
      Mortality.kNounPhraseCauses
          .intersection(Mortality.kSelfContainedCauses),
      isEmpty,
      reason: 'Bir gerekçe iki kümede birden olamaz.',
    );
  });

  test('zarf öbeğine "nedeniyle" eklenmez, isim öbeğine eklenir', () {
    for (final String gerekce in Mortality.kSelfContainedCauses) {
      final String cumle = '${Mortality.causeClause(gerekce)} vefat etti.';
      expect(cumle, isNot(contains('nedeniyle')),
          reason: 'Zarf öbeğine ek eklenmiş: $cumle');
      expect(cumle, startsWith(gerekce));
    }
    for (final String gerekce in Mortality.kNounPhraseCauses) {
      expect(Mortality.causeClause(gerekce), '$gerekce nedeniyle',
          reason: 'İsim öbeği eksiz bırakılmış: $gerekce');
    }
  });

  test('bilinmeyen gerekçe eski davranışı korur', () {
    // Eski kayıttan gelen bir gerekçe kümelerde olmayabilir; o zaman
    // bugüne kadarki kalıp uygulanır, cümle yine kurulur.
    expect(Mortality.causeClause('bilinmiyor'), 'bilinmiyor nedeniyle');
  });

  test('bütün gerekçeler üç cümle kalıbında da okunabilir kalır', () {
    // Üç gerçek yazım yerinin kalıbı. "nedeniyle" hiçbir cümlede
    // zarf öbeğinin peşine düşmemeli.
    const List<String> bozukKaliplar = <String>[
      'şekilde nedeniyle',
      'ardından nedeniyle',
    ];
    for (final String gerekce in Mortality.allPrototypeOnlyCauses) {
      final String ek = Mortality.causeClause(gerekce);
      final List<String> cumleler = <String>[
        'Anneannen Ceren Turan $ek vefat etti.',
        '70 yaşında $ek hayatını kaybettin.',
        'Annen Sema Erdoğan, 66 yaşında $ek hayatını kaybetti.',
      ];
      for (final String cumle in cumleler) {
        for (final String bozuk in bozukKaliplar) {
          expect(cumle, isNot(contains(bozuk)),
              reason: 'Oyuncunun göreceği cümle bozuk: $cumle');
        }
      }
    }
  });
}
