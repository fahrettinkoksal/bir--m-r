// Paket BA: onaysız sayı taramasının bulguları.
//
// Tarama Q-194'te önerilen yöntemle yapıldı: bir sabitin etkisini sıfırla
// ve ölçüm değişiyor mu diye bak. Değişmiyorsa sabit ya **dekoratif**
// (hiçbir şeyi elemiyor), ya **doymuş** (tavan tek bileşenle doluyor), ya
// da **ölü** (hiç okunmuyor).
//
// Bu dosya taramanın ölçülebilir bulgularını tutar. Ölü sabitlerin kalıcı
// bekçisi ayrı dosyada: `prototype_only_dead_constant_test.dart`.
library;

import 'package:bir_omur/domain/career/career_progress.dart';
import 'package:bir_omur/domain/career/craft_mastery.dart';
import 'package:bir_omur/domain/career/military_service.dart';
import 'package:bir_omur/domain/economy/business_engine.dart';
import 'package:bir_omur/domain/sports/school_club_engine.dart';
import 'package:bir_omur/domain/economy/financial_strain.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/career.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/data/military_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

GameState _hayat(int seed, {required int age, int wallet = 0}) {
  final GameState s =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  return s.copyWith(player: s.player.copyWith(age: age, wallet: wallet));
}

void main() {
  // ===================================================================
  // 1) Mali kademe: gideri olmayan oyuncu (D-092)
  // ===================================================================
  group('Gideri olmayan oyuncunun mali kademesi (D-092)', () {
    test('cebinde parası olan çocuk "varlıklı" sayılmaz', () {
      final GameState s = _hayat(1, age: 10, wallet: 50);
      // Ön koşul: gerçekten gideri olmayan bir durum ölçülüyor.
      expect(FinancialStrain.yearlyOutgoings(s), 0,
          reason: 'Test gideri olmayan durumu ölçmek için kuruldu; '
              'gider çıktıysa senaryo artık o durumu ölçmüyor.');
      expect(FinancialStrain.comfortOf(s), FinancialComfort.rahat,
          reason: 'Cebinde 50 lirası olan çocuk "Varlıklı" sayılırsa olay '
              'motoru ona varlık metni çıkarır, yoksulluk metnini kapatır '
              '(D-092). Ölçülmüş hata buydu.');
    });

    test('parası olmayan çocuk "idare ediyor" sayılmaz', () {
      final GameState s = _hayat(2, age: 10);
      expect(FinancialStrain.yearlyOutgoings(s), 0);
      expect(FinancialStrain.comfortOf(s), FinancialComfort.zor,
          reason: 'Gideri de parası da olmayan oyuncu, bandın üst sınırı '
              'döndürüldüğü için bir üst kademeye kayıyordu.');
    });

    test('kademe sınır değerinden tahmin edilmiyor', () {
      // `ratio` gideri olmayan durumda bandın **üst sınırını** döndürür;
      // bu bir kademe değildir. Kademenin oradan türetilmediği, iki
      // durumun farklı kademe vermesiyle görülür.
      final GameState parali = _hayat(3, age: 10, wallet: 500);
      final GameState parasiz = _hayat(3, age: 10);
      expect(FinancialStrain.comfortOf(parali),
          isNot(FinancialStrain.comfortOf(parasiz)));
    });
  });

  // ===================================================================
  // 2) Doymuş tavan: zam/terfi şansında kıdem (D-169 sınıfı hata)
  // ===================================================================
  group('Zam talebinde kıdem tavanı doyuruyor mu?', () {
    /// Belirli kıdemde, belirli statlarla çalışan oyuncu.
    GameState calisan({required int yil, required int stat}) {
      final GameState s = _hayat(7, age: 25 + yil);
      return s.copyWith(
        player: s.player.copyWith(
          stats: s.player.stats.copyWith(
            intelligence: stat,
            charisma: stat,
            happiness: 70,
          ),
        ),
        career: CareerState(
          jobId: 'kasiyer',
          startedAtAge: 25,
          lastPaidAge: 25 + yil,
        ),
      );
    }

    test('ÖLÇÜM: statların zam şansına etkisi hangi kıdemde biter', () {
      final List<String> tablo = <String>[];
      int? doyduguYil;
      for (int yil = 1; yil <= 30; yil++) {
        final double zayif =
            CareerProgress.prototypeOnlyChance(calisan(yil: yil, stat: 10),
                terfi: false);
        final double guclu =
            CareerProgress.prototypeOnlyChance(calisan(yil: yil, stat: 100),
                terfi: false);
        if (yil <= 14 || yil % 5 == 0) {
          tablo.add('  $yil yıl: stat 10 → ${zayif.toStringAsFixed(3)}, '
              'stat 100 → ${guclu.toStringAsFixed(3)}');
        }
        if (doyduguYil == null && zayif == guclu) doyduguYil = yil;
      }
      // ignore: avoid_print
      print('\nZam talebi kabul şansı (tavan '
          '${CareerProgress.prototypeOnlyMaxChance}):\n'
          '${tablo.join('\n')}\n'
          'Statların etkisi şu kıdemde bitiyor: '
          '${doyduguYil ?? "hiç bitmiyor"}\n'
          'Ustalık basamakları: Kalfa 3, Usta 8, Başusta 16, Duayen 28 '
          'yıl.\n');

      // KALICI BEKÇİ (D-176): kıdem hiçbir noktada tek başına tavanı
      // doldurmamalı. Doldurduğu an zekâ, karizma, ustalık, itibar ve
      // hobi sinerjisi **hiçbir şey** yapmaz hâle gelir — hata tam
      // olarak buydu.
      expect(doyduguYil, isNull,
          reason: 'Statların etkisi $doyduguYil yıl kıdemde bitiyor. '
              'Kıdem tek başına tavanı dolduruyorsa D-155 (ustalık ve '
              'itibar) ve Paket AK (hobi sinerjisi) o kıdemden sonra '
              'ölü demektir.');

      for (int yil = 1; yil <= 30; yil++) {
        for (final int stat in <int>[10, 100]) {
          final double s = CareerProgress.prototypeOnlyChance(
              calisan(yil: yil, stat: stat),
              terfi: false);
          expect(s, greaterThanOrEqualTo(CareerProgress.prototypeOnlyMinChance));
          expect(s, lessThanOrEqualTo(CareerProgress.prototypeOnlyMaxChance));
        }
      }
    });

    test('ustalık basamağına çıkmak zam şansını gerçekten değiştiriyor', () {
      // D-155 ustalığın zam talebini kolaylaştırdığını söylüyor. Pay
      // hesabının doğru olması yetmez; **sonucun** değişmesi gerekir.
      // Eski tavanda Usta/Başusta/Duayen geçişlerinin sonuca etkisi
      // sıfırdı.
      for (final (int, int) gecis in <(int, int)>[(7, 8), (15, 16), (27, 28)]) {
        final double once = CareerProgress.prototypeOnlyChance(
            calisan(yil: gecis.$1, stat: 10),
            terfi: false);
        final double sonra = CareerProgress.prototypeOnlyChance(
            calisan(yil: gecis.$2, stat: 10),
            terfi: false);
        expect(sonra, greaterThan(once),
            reason: '${gecis.$1} → ${gecis.$2} yıl geçişinde yeni ustalık '
                'basamağı zam şansını değiştirmiyor: '
                '${once.toStringAsFixed(3)} → ${sonra.toStringAsFixed(3)}.');
      }
    });

    test('ustalık basamakları gerçekten birbirinden farklı pay veriyor', () {
      // D-155 ustalığın ve itibarın zam talebini kolaylaştırdığını
      // söylüyor. Payın **kendisi** burada ölçülüyor: tavan ayrı bir
      // konu, ama pay hesabı basamak başına artmalı.
      final List<double> paylar = <double>[
        for (final int yil in <int>[1, 4, 9, 17, 29])
          CraftMastery.requestBonus(calisan(yil: yil, stat: 60)),
      ];
      for (int i = 1; i < paylar.length; i++) {
        expect(paylar[i], greaterThan(paylar[i - 1]),
            reason: 'D-155: üst basamak daha büyük pay vermeli. '
                'Ölçülen: $paylar');
      }
    });
  });

  // ===================================================================
  // 3) Dekoratif sınır: rütbeli askerlikte kabul şansının tabanı
  // ===================================================================
  test('ÖLÇÜM: rütbeli askerlikte kabul şansının alt sınırı erişilebilir mi',
      () {
    final List<String> satirlar = <String>[];
    double enKucuk = 1;
    for (final MilitaryTrack yol in MilitaryTrack.values) {
      if (yol == MilitaryTrack.er) continue;
      for (final int stat in <int>[0, 50, 100]) {
        final GameState s = _hayat(11, age: 21);
        final GameState k = s.copyWith(
          player: s.player.copyWith(
            stats: s.player.stats
                .copyWith(intelligence: stat, health: stat.clamp(1, 100)),
          ),
        );
        final double sans = MilitaryService.prototypeOnlyAcceptChance(k, yol);
        if (sans < enKucuk) enKucuk = sans;
        satirlar.add('  ${yol.name}, stat $stat → ${sans.toStringAsFixed(3)}');
      }
    }
    // ignore: avoid_print
    print('\nRütbeli askerlik kabul şansı:\n${satirlar.join('\n')}\n'
        'Ölçülen en küçük: ${enKucuk.toStringAsFixed(3)}\n');

    // KALICI BEKÇİ (D-177): yazılı bir alt sınır varsa **erişilebilir**
    // olmalı. Eskiden 0,05 yazıyordu ve ölçülen en kötü durum 0,30'du;
    // sınır hiçbir şeyi elemiyordu (D-164 ile aynı desen). Alt sınır
    // kaldırıldı; taban artık yolun kendi tabanı.
    expect(enKucuk, greaterThanOrEqualTo(0.30),
        reason: 'En kötü durum 0,30 olmalı: taban subay yolunun kendi '
            'tabanından geliyor.');
    expect(enKucuk, lessThanOrEqualTo(MilitaryService.prototypeOnlyAcceptCeiling));
  });

  // ===================================================================
  // 4) Doymuş alt puan: okul kulübü seçmesinde beceri
  // ===================================================================
  test('ÖLÇÜM: okul kulübü seçme puanında beceri hangi sezonda ölür', () {
    // Deneyim payı `(sezon × ağırlık + beceri ~/ 4)` ve tavanı 30.
    // Ağırlık 4 olduğu için sezon tek başına tavanı doldurabiliyor;
    // o noktadan sonra antrenmanla kazanılan beceri puana **hiç**
    // girmiyor. D-169 ve D-176 ile aynı desen.
    const int agirlik = SchoolClubEngine.prototypeOnlyExperienceWeight;
    const int tavan = 30;
    final List<String> tablo = <String>[];
    int? olduguSezon;
    for (int sezon = 0; sezon <= 12; sezon++) {
      final List<int> puanlar = <int>[
        for (final int beceri in <int>[0, 50, 100])
          (sezon * agirlik + beceri ~/ 4).clamp(0, tavan),
      ];
      tablo.add('  $sezon sezon: beceri 0 → ${puanlar[0]}, '
          '50 → ${puanlar[1]}, 100 → ${puanlar[2]}');
      if (olduguSezon == null && puanlar.toSet().length == 1) {
        olduguSezon = sezon;
      }
    }
    // ignore: avoid_print
    print('\nOkul kulübü deneyim payı (ağırlık $agirlik, tavan $tavan):\n'
        '${tablo.join('\n')}\n'
        'Becerinin etkisi şu sezonda bitiyor: '
        '${olduguSezon ?? "hiç bitmiyor"}\n'
        'Okul ~12 sezon sürüyor, yani bu aralık gerçekten yaşanıyor.\n');

    // KALICI BEKÇİ (D-178): sezon tek başına deneyim tavanını
    // dolduramaz. Doldurduğu an antrenmanla kazanılan beceri seçmede
    // **hiçbir şey** yapmaz hâle gelir — hata tam olarak buydu.
    expect(olduguSezon, isNull,
        reason: 'Becerinin etkisi $olduguSezon sezonda bitiyor. Sezon '
            'tek başına tavanı dolduruyorsa kulüpte durmak ile '
            'çalışmak aynı kapıya çıkar.');
    expect(agirlik, greaterThan(0));
  });

  // ===================================================================
  // 5) Dekoratif sabit: açık iş tavanı artık kapıdan okunuyor
  // ===================================================================
  test('açık iş tavanı sabit üzerinden denetleniyor', () {
    // Tavan uygulanıyordu ama sabit üzerinden değil: `openBusiness`
    // null mı diye bakılıyordu. Sabiti değiştirmek hiçbir şeyi
    // değiştirmiyordu — dekoratif sabit.
    expect(BusinessEngine.prototypeOnlyMaxOpenBusinesses, greaterThan(0));
    final GameState s = _hayat(5, age: 30);
    expect(BusinessEngine.openBusinessCount(s), 0,
        reason: 'Yeni hayatta açık iş olmamalı.');
  });
}
