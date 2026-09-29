// Paket AK — hobi/kurs → kariyer sinerjisi.
//
// Bu dosya üç şeyi ölçüyor:
//
// 1. §23'teki bağlantı tablosu koda gerçekten girdi mi,
// 2. avantaj beklendiği kadar mı (ne fazla ne az),
// 3. ve en önemlisi: **kimsenin kapısı kapanmadı mı**.
//
// Faho'nun kararı açıktı: kurs/hobi yapmamış oyuncunun bugün
// erişebildiği meslekler KAPANMAYACAK. O yüzden burada en sert test
// "hiçbir sinerji hiçbir işi kilitlemiyor" testidir.
//
// Ölçüm çıktısı doğrudan konsola yazılıyor; rapor buradan üretiliyor.
// ignore_for_file: avoid_print
library;

import 'dart:math';

import 'package:bir_omur/data/activity_catalog.dart';
import 'package:bir_omur/data/hobby_catalog.dart';
import 'package:bir_omur/data/interview_catalog.dart';
import 'package:bir_omur/data/job_catalog.dart';
import 'package:bir_omur/domain/career/career_synergy.dart';
import 'package:bir_omur/domain/career/craft_mastery.dart';
import 'package:bir_omur/domain/career/job_market.dart';
import 'package:bir_omur/domain/models/career.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/hobby_progress.dart';
import 'package:flutter_test/flutter_test.dart';

const JobMarket _pazar = JobMarket();

JobType _is(String id) => kJobCatalog.firstWhere((JobType j) => j.id == id);

/// §23'teki tablo. Test bunu koda karşı doğruluyor.
const Map<String, Map<String, SynergyStrength>> _beklenen =
    <String, Map<String, SynergyStrength>>{
  'resim': <String, SynergyStrength>{
    'ressam_tasarimci': SynergyStrength.guclu,
    'grafik_tasarimci': SynergyStrength.guclu,
  },
  'mutfak': <String, SynergyStrength>{'asci': SynergyStrength.guclu},
  'fotograf': <String, SynergyStrength>{
    'fotografci': SynergyStrength.guclu,
    'gazeteci': SynergyStrength.kucuk,
  },
  'yazilim': <String, SynergyStrength>{
    'yazilim_gelistirici': SynergyStrength.guclu,
    'teknik_servis': SynergyStrength.kucuk,
    'veri_analisti': SynergyStrength.orta,
  },
  'yazmak': <String, SynergyStrength>{
    'yazar': SynergyStrength.guclu,
    'gazeteci': SynergyStrength.orta,
  },
  'dil': <String, SynergyStrength>{
    'resepsiyonist': SynergyStrength.guclu,
    'satis_danismani': SynergyStrength.orta,
    'gazeteci': SynergyStrength.orta,
    'banka_personeli': SynergyStrength.kucuk,
    'cagri_merkezi': SynergyStrength.kucuk,
    'ik_uzmani': SynergyStrength.kucuk,
  },
  'spor': <String, SynergyStrength>{
    'guvenlik': SynergyStrength.orta,
    'polis': SynergyStrength.kucuk,
    'itfaiyeci': SynergyStrength.orta,
  },
  'dans': <String, SynergyStrength>{'manken': SynergyStrength.kucuk},
  'satranc': <String, SynergyStrength>{'veri_analisti': SynergyStrength.kucuk},
};

GameState _hayat({int seed = 8181, int age = 30}) {
  final GameState s =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  return s.copyWith(
    player: s.player.copyWith(age: age),
    pendingEvent: null,
  );
}

/// Hobiyi belli bir basamağa getirir.
GameState _hobi(
  GameState state,
  String hobbyId,
  int stageIndex, {
  int? lastPracticedAge,
}) {
  final HobbyKind h = hobbyById(hobbyId)!;
  final int deneyim = h.stages[stageIndex].experience;
  return state.copyWith(hobbies: <HobbyProgress>[
    ...state.hobbies.where((HobbyProgress p) => p.hobbyId != hobbyId),
    HobbyProgress(
      hobbyId: hobbyId,
      experience: deneyim,
      startedAtAge: 10,
      lastPracticedAge: lastPracticedAge ?? state.player.age,
    ),
  ]);
}

void main() {
  // =================================================================
  // §23 — bağlantı tablosu koda girdi mi
  // =================================================================
  group('Paket AK — bağlantı tablosu (§23)', () {
    test('§23\'teki her bağ kodda aynı güçte var', () {
      final Map<String, Map<String, SynergyStrength>> kodda =
          <String, Map<String, SynergyStrength>>{};
      for (final JobType j in kJobCatalog) {
        for (final CareerSynergy b in j.synergies) {
          kodda.putIfAbsent(b.hobbyId, () => <String, SynergyStrength>{})[j.id] =
              b.strength;
        }
      }
      for (final MapEntry<String, Map<String, SynergyStrength>> e
          in _beklenen.entries) {
        expect(kodda[e.key], e.value,
            reason: '${e.key} hobisinin bağları §23 ile uyuşmuyor.');
      }

      print('');
      print('-- hobi -> meslek sinerji tablosu --');
      for (final HobbyKind h in HobbyKind.values) {
        final Map<String, SynergyStrength> b =
            kodda[h.id] ?? <String, SynergyStrength>{};
        if (b.isEmpty) {
          print('${h.label.padRight(12)} (bağ yok)');
          continue;
        }
        final String satir = b.entries
            .map((MapEntry<String, SynergyStrength> e) =>
                '${_is(e.key).name} (${e.value.label})')
            .join(', ');
        print('${h.label.padRight(12)} $satir');
      }
    });

    test('bahçe zorla bir mesleğe bağlanmadı (§13)', () {
      for (final JobType j in kJobCatalog) {
        expect(j.synergies.any((CareerSynergy b) => b.hobbyId == 'bahce'),
            isFalse,
            reason: '${j.name} bahçe hobisine bağlanmış; §13 bunu yasaklıyor.');
      }
    });

    test('her sinerji gerçek bir hobi ve gerçek bir meslek', () {
      for (final JobType j in kJobCatalog) {
        for (final CareerSynergy b in j.synergies) {
          expect(hobbyById(b.hobbyId), isNotNull,
              reason: '${j.name}: "${b.hobbyId}" diye bir hobi yok.');
        }
        // Aynı hobi bir meslekte iki kez yazılmasın: çift sayım olmaz.
        final List<String> idler =
            j.synergies.map((CareerSynergy b) => b.hobbyId).toList();
        expect(idler.toSet().length, idler.length,
            reason: '${j.name} aynı hobiyi iki kez sayıyor.');
      }
    });
  });

  // =================================================================
  // EN SERT TEST — hiçbir kapı kapanmadı
  // =================================================================
  group('Paket AK — hiçbir meslek kapanmadı', () {
    test('hobisi olmayan oyuncu, sinerjili işlerin hiçbirinde engellenmiyor',
        () {
      // Hiç hobisi olmayan hayat.
      final GameState hobisiz =
          _hayat().copyWith(hobbies: const <HobbyProgress>[]);
      // Aynı hayat, bütün hobileri Usta.
      GameState ustaHer = _hayat();
      for (final HobbyKind h in HobbyKind.values) {
        ustaHer = _hobi(ustaHer, h.id, h.topStage);
      }

      int sinerjili = 0;
      for (final JobType j in kJobCatalog) {
        if (j.synergies.isEmpty) continue;
        sinerjili++;
        final String hobisizGerekce = _pazar.requirementReason(hobisiz, j);
        final String ustaGerekce = _pazar.requirementReason(ustaHer, j);
        // Sinerji bir gerekçe ÜRETMEMELİ: iki oyuncunun engeli aynı
        // olmalı (sert şart hobyId olan Yazar/Müzisyen hariç, orada da
        // fark sinerjiden değil eski sert şarttan gelir).
        if (j.hobbyId == null) {
          expect(hobisizGerekce, ustaGerekce,
              reason: '${j.name}: sinerji işe giriş koşulunu değiştirmiş.');
        }
        // Ve hiçbir gerekçe metni sinerjiden bahsetmemeli.
        expect(hobisizGerekce.contains('avantaj'), isFalse);
      }
      expect(sinerjili, greaterThanOrEqualTo(19));
      print('');
      print('-- sinerjili meslek sayısı: $sinerjili --');
    });

    test('sinerji requirementReason içine hiç girmiyor', () {
      // Kod düzeyinde: iş koşulu dosyası sinerjiyi kullanmıyor olmalı.
      // (Davranış testi yukarıda; bu, gelecekte kilit eklenmesini
      // yakalar.)
      final GameState s = _hobi(_hayat(), 'yazilim', 4);
      final JobType j = _is('yazilim_gelistirici');
      final String gerekceUsta = _pazar.requirementReason(s, j);
      final String gerekceYok = _pazar.requirementReason(
        _hayat().copyWith(hobbies: const <HobbyProgress>[]),
        j,
      );
      expect(gerekceUsta, gerekceYok);
    });
  });

  // =================================================================
  // §2 — basamak arttıkça avantaj artıyor
  // =================================================================
  group('Paket AK — avantaj basamaktan geliyor (§2)', () {
    test('Hevesli neredeyse etkisiz, Usta en yüksek ama garanti değil', () {
      final JobType j = _is('fotografci');
      final List<double> paylar = <double>[];
      for (int b = 0; b < 5; b++) {
        paylar.add(CareerSynergyRules.scoreFor(_hobi(_hayat(), 'fotograf', b), j));
      }
      // Hevesli sıfır: bir ders alıp kariyer bonusu yok (§22).
      expect(paylar[0], 0);
      // Monoton artıyor.
      for (int i = 1; i < paylar.length; i++) {
        expect(paylar[i], greaterThan(paylar[i - 1]),
            reason: '$i. basamak bir öncekinden büyük olmalı.');
      }
      // Usta bile garanti değil.
      final double ustaSans = CareerSynergyRules.interviewRescueChance(
        _hobi(_hayat(), 'fotograf', 4),
        j,
      );
      expect(ustaSans, lessThan(0.5),
          reason: 'En yüksek sinerji bile işe girmeyi garantilememeli.');

      print('');
      print('-- fotoğrafçı: basamak -> pay / mülakat ikinci şansı --');
      for (int b = 0; b < 5; b++) {
        final GameState s = _hobi(_hayat(), 'fotograf', b);
        print('${HobbyKind.fotograf.stages[b].label.padRight(10)} '
            'pay ${paylar[b].toStringAsFixed(2)}  '
            'ikinci şans '
            '%${(CareerSynergyRules.interviewRescueChance(s, j) * 100).round()}');
      }
    });

    test('güçlü bağ zayıf bağdan fazla verir', () {
      final GameState s = _hobi(_hayat(), 'fotograf', 4);
      final double guclu = CareerSynergyRules.scoreFor(s, _is('fotografci'));
      final double zayif = CareerSynergyRules.scoreFor(s, _is('gazeteci'));
      expect(guclu, greaterThan(zayif));
      print('');
      print('-- Usta fotoğraf: fotoğrafçı ${guclu.toStringAsFixed(2)} · '
          'gazeteci ${zayif.toStringAsFixed(2)} --');
    });
  });

  // =================================================================
  // §20 — aktif / bırakılmış hobi farkı
  // =================================================================
  group('Paket AK — aktif ve eski hobi farkı (§20)', () {
    test('yıllar önce usta olanın payı azalır ama sıfırlanmaz', () {
      final JobType j = _is('ressam_tasarimci');
      final GameState aktif = _hobi(_hayat(age: 40), 'resim', 4);
      final GameState eski =
          _hobi(_hayat(age: 40), 'resim', 4, lastPracticedAge: 28);

      final double a = CareerSynergyRules.scoreFor(aktif, j);
      final double e = CareerSynergyRules.scoreFor(eski, j);
      expect(e, lessThan(a));
      expect(e, greaterThan(0), reason: 'Geçmiş tamamen yok olmamalı.');
      print('');
      print('-- Usta resim: aktif ${a.toStringAsFixed(2)} · '
          '12 yıldır ara verilmiş ${e.toStringAsFixed(2)} --');
    });

    test('bırakılmış hobi terfi payı vermiyor (§19)', () {
      final JobType j = _is('asci');
      GameState eski = _hobi(_hayat(age: 40), 'mutfak', 4,
          lastPracticedAge: 25);
      eski = eski.copyWith(
        career: eski.career.copyWith(
          jobId: j.id,
          startedAtAge: 35,
          salary: j.yearlySalary,
        ),
      );
      expect(CareerSynergyRules.promotionBonus(eski), 0);

      GameState aktif = _hobi(_hayat(age: 40), 'mutfak', 4);
      aktif = aktif.copyWith(
        career: aktif.career.copyWith(
          jobId: j.id,
          startedAtAge: 35,
          salary: j.yearlySalary,
        ),
      );
      final double pay = CareerSynergyRules.promotionBonus(aktif);
      expect(pay, greaterThan(0));
      expect(pay,
          lessThanOrEqualTo(
              CareerSynergyRules.prototypeOnlyMaxPromotionBonus));
      print('');
      print('-- aşçı terfi payı: aktif ${pay.toStringAsFixed(3)} · '
          'bırakılmış 0 (tavan '
          '${CareerSynergyRules.prototypeOnlyMaxPromotionBonus}) --');
    });
  });

  // =================================================================
  // §18 — başlangıç ustalığı
  // =================================================================
  group('Paket AK — başlangıç ustalığı (§18)', () {
    test('ciddi geçmişi olan sıfır çırak başlamıyor, usta da başlamıyor', () {
      final JobType j = _is('fotografci');
      final GameState usta = _hobi(_hayat(age: 25), 'fotograf', 4);
      final GameState hobisiz =
          _hayat(age: 25).copyWith(hobbies: const <HobbyProgress>[]);

      final int payUsta = CareerSynergyRules.headStartYears(usta, j);
      final int payYok = CareerSynergyRules.headStartYears(hobisiz, j);
      expect(payYok, 0);
      expect(payUsta, greaterThan(0));

      // İşe girmiş gibi kur ve basamağı ölç.
      GameState iste = usta.copyWith(
        career: usta.career.copyWith(
          jobId: j.id,
          startedAtAge: 25,
          salary: j.yearlySalary,
          synergyHeadStart: payUsta,
        ),
      );
      final MasteryStage? basamak = CraftMastery.stageOf(iste);
      expect(basamak, isNotNull);
      expect(basamak, isNot(MasteryStage.cirak),
          reason: 'Yıllardır fotoğraf çeken çırak olarak başlamamalı.');
      expect(basamak!.index, lessThan(MasteryStage.usta.index),
          reason: 'Ama doğrudan usta olarak da başlamamalı.');

      // Maaş katalog maaşı: sinerji maaşı şişirmiyor (§3).
      expect(iste.career.yearlySalary, j.yearlySalary);
      print('');
      print('-- Usta fotoğraf: başlangıç payı $payUsta yıl -> '
          '${basamak.label} (hobisiz: $payYok yıl -> Çırak) --');
    });

    test('başlangıç payı kıdemi ve toplam çalışma yılını şişirmiyor', () {
      final JobType j = _is('asci');
      GameState s = _hobi(_hayat(age: 30), 'mutfak', 4);
      final int pay = CareerSynergyRules.headStartYears(s, j);
      s = s.copyWith(
        career: s.career.copyWith(
          jobId: j.id,
          startedAtAge: 28,
          salary: j.yearlySalary,
          synergyHeadStart: pay,
        ),
      );
      // Gerçek kıdem 2 yıl; sinerji buna girmiyor.
      expect(s.career.yearsInJob(s.player.age), 2);
      expect(s.career.totalWorkYears(s.player.age), 2);
      // Ustalık merdiveni ise payı sayıyor.
      expect(CraftMastery.effectiveYears(s), 2 + pay);
    });

    test('işten ayrılınca başlangıç payı sıfırlanıyor', () {
      final JobType j = _is('asci');
      GameState s = _hobi(_hayat(age: 30), 'mutfak', 4);
      s = s.copyWith(
        career: s.career.copyWith(
          jobId: j.id,
          startedAtAge: 28,
          salary: j.yearlySalary,
          synergyHeadStart: 5,
        ),
      );
      final CareerState sonra = s.career.closeCurrentJob(
        endedAtAge: 30,
        reason: JobEndReason.istifa,
      );
      expect(sonra.synergyHeadStart, 0);
    });
  });

  // =================================================================
  // §17 — mülakata etkisi
  // =================================================================
  group('Paket AK — mülakat (§17)', () {
    /// Yanlış cevap verip kaç kez işe alındığını sayar.
    int yanlisCevapKabul(GameState temel, JobType job, int deneme) {
      int kabul = 0;
      for (int i = 0; i < deneme; i++) {
        final Random rng = Random(1000 + i);
        final JobResult basvuru = _pazar.apply(temel, job, rng);
        if (!basvuru.outcome.interviewStarted) continue;
        final InterviewQuestion soru = basvuru.state.pendingInterview!.question!;
        // Bilerek yanlış seçenek.
        final int yanlis = soru.correctIndex == 0 ? 1 : 0;
        final JobResult cevap =
            _pazar.answerInterview(basvuru.state, yanlis, rng);
        if (cevap.outcome.accepted) kabul++;
      }
      return kabul;
    }

    test('yanlış cevap: hobisiz aday HİÇ alınmıyor, ustanın şansı var', () {
      final JobType j = _is('asci');
      const int deneme = 200;

      final GameState hobisiz =
          _hayat(age: 30).copyWith(hobbies: const <HobbyProgress>[]);
      final GameState usta = _hobi(_hayat(age: 30), 'mutfak', 4);
      final GameState duzenli = _hobi(_hayat(age: 30), 'mutfak', 2);

      final int a = yanlisCevapKabul(hobisiz, j, deneme);
      final int b = yanlisCevapKabul(duzenli, j, deneme);
      final int c = yanlisCevapKabul(usta, j, deneme);

      expect(a, 0,
          reason: 'Sinerjisi olmayan yanlış cevapla işe alınmamalı.');
      expect(b, greaterThan(0));
      expect(c, greaterThan(b),
          reason: 'Usta, Düzenli\'den daha şanslı olmalı.');
      expect(c, lessThan(deneme),
          reason: 'Usta bile GARANTİ işe girmemeli.');

      print('');
      print('-- aşçı, YANLIŞ cevapla $deneme başvuru --');
      print('  hobisiz  $a');
      print('  Düzenli  $b');
      print('  Usta     $c');
    });

    test('doğru cevap herkeste işe alıyor: sinerji şart değil', () {
      final JobType j = _is('asci');
      final GameState hobisiz =
          _hayat(age: 30).copyWith(hobbies: const <HobbyProgress>[]);
      final Random rng = Random(7);
      final JobResult basvuru = _pazar.apply(hobisiz, j, rng);
      final InterviewQuestion soru = basvuru.state.pendingInterview!.question!;
      final JobResult cevap =
          _pazar.answerInterview(basvuru.state, soru.correctIndex, rng);
      expect(cevap.outcome.accepted, isTrue,
          reason: 'Hobisi olmayan doğru cevapla işe girebilmeli.');
    });
  });

  // =================================================================
  // §22 — abuse
  // =================================================================
  group('Paket AK — abuse (§22)', () {
    test('bir ders alıp kariyer avantajı toplanamıyor', () {
      // Tek ders: deneyim 1, hiçbir hobide 1. basamağa yetmiyor
      // (en düşük eşik 3).
      GameState s = _hayat(age: 14);
      for (final HobbyKind h in HobbyKind.values) {
        s = s.copyWith(hobbies: <HobbyProgress>[
          ...s.hobbies.where((HobbyProgress p) => p.hobbyId != h.id),
          HobbyProgress(
            hobbyId: h.id,
            experience: 1,
            startedAtAge: 14,
            lastPracticedAge: 14,
          ),
        ]);
      }
      double enYuksek = 0;
      for (final JobType j in kJobCatalog) {
        final double pay = CareerSynergyRules.scoreFor(s, j);
        if (pay > enYuksek) enYuksek = pay;
      }
      expect(enYuksek, 0,
          reason: 'Her hobiden bir ders alan kariyer avantajı kazanmamalı.');
      print('');
      print('-- 12 hobiden birer ders: en yüksek kariyer payı '
          '${enYuksek.toStringAsFixed(2)} --');
    });

    test('beş hobiyi birden ilerletmek tek işte avantajı çarpmıyor', () {
      final JobType j = _is('gazeteci');
      // Gazetecinin üç bağı var: yazmak, fotograf, dil.
      GameState tek = _hobi(_hayat(), 'yazmak', 4);
      GameState uc = _hobi(_hobi(_hobi(_hayat(), 'yazmak', 4),
          'fotograf', 4), 'dil', 4);

      final double a = CareerSynergyRules.scoreFor(tek, j);
      final double b = CareerSynergyRules.scoreFor(uc, j);
      expect(b, greaterThan(a), reason: 'İkinci hobi bir şey katmalı (§8).');
      expect(b, lessThan(a * 2),
          reason: 'Ama toplanarak çarpmamalı.');
      expect(b, lessThanOrEqualTo(1.0));
      print('');
      print('-- gazeteci: tek hobi ${a.toStringAsFixed(2)} · '
          'üç hobi ${b.toStringAsFixed(2)} (tavan 1,00) --');
    });

    test('sinerji hiçbir maaşı değiştirmiyor (§3)', () {
      GameState usta = _hayat(age: 30);
      for (final HobbyKind h in HobbyKind.values) {
        usta = _hobi(usta, h.id, h.topStage);
      }
      for (final JobType j in kJobCatalog) {
        if (j.synergies.isEmpty) continue;
        GameState iste = usta.copyWith(
          career: usta.career.copyWith(
            jobId: j.id,
            startedAtAge: 30,
            salary: j.yearlySalary,
            synergyHeadStart: CareerSynergyRules.headStartYears(usta, j),
          ),
        );
        expect(iste.career.yearlySalary, j.yearlySalary,
            reason: '${j.name} maaşı sinerjiden etkilenmiş.');
      }
    });

    test('terfi payı tavanı aşmıyor, hobi spamı büyütmüyor', () {
      final JobType j = _is('yazilim_gelistirici');
      GameState s = _hobi(_hayat(age: 35), 'yazilim', 4);
      s = s.copyWith(
        career: s.career.copyWith(
          jobId: j.id,
          startedAtAge: 30,
          salary: j.yearlySalary,
        ),
      );
      final double bir = CareerSynergyRules.promotionBonus(s);

      // Aynı yıl deneyimi katla: basamak zaten tavanda, pay değişmemeli.
      final GameState spam = s.copyWith(hobbies: <HobbyProgress>[
        for (final HobbyProgress p in s.hobbies)
          if (p.hobbyId == 'yazilim')
            p.copyWith(experience: p.experience + 500)
          else
            p,
      ]);
      expect(CareerSynergyRules.promotionBonus(spam), bir,
          reason: 'Deneyimi şişirmek terfi payını büyütmemeli.');
      expect(bir,
          lessThanOrEqualTo(
              CareerSynergyRules.prototypeOnlyMaxPromotionBonus));
    });
  });

  // =================================================================
  // §14 — mevcut sert bağlar korundu
  // =================================================================
  group('Paket AK — sert şartlar korundu (§14)', () {
    test('Yazar ve Müzisyen hâlâ hobi şartı istiyor', () {
      for (final String id in <String>['yazar', 'muzisyen']) {
        final JobType j = _is(id);
        expect(j.hobbyId, isNotNull);
        expect(j.minHobbyStage, greaterThan(0));

        final GameState hobisiz = _hayat(age: 30)
            .copyWith(hobbies: const <HobbyProgress>[])
            .copyWith(
              player: _hayat(age: 30).player.copyWith(
                    age: 30,
                    stats: _hayat(age: 30).player.stats.copyWith(
                          intelligence: 90,
                          charisma: 90,
                        ),
                  ),
            );
        expect(_pazar.meetsRequirements(hobisiz, j), isFalse,
            reason: '$id sert hobi şartını kaybetmiş.');
      }
    });

    test('sinerji sert şartı bypass etmiyor', () {
      // Yazmak Usta ama okuma hiç yok: Yazar yine kapalı.
      final GameState s = _hobi(_hayat(age: 30), 'yazmak', 4);
      expect(_pazar.meetsRequirements(s, _is('yazar')), isFalse,
          reason: 'Yazmak hobisi okuma şartını bypass etmemeli.');
      // Ama sinerji payı var: hazırlıklı ama şartsız değil.
      expect(CareerSynergyRules.scoreFor(s, _is('yazar')), greaterThan(0));
    });
  });

  // =================================================================
  // §15 / §16 — ekran metinleri
  // =================================================================
  group('Paket AK — ekran metinleri (§15, §16)', () {
    test('avantaj satırı yüzde göstermiyor', () {
      final GameState s = _hobi(_hayat(), 'yazilim', 3);
      final String? not =
          CareerSynergyRules.applicationNote(s, _is('yazilim_gelistirici'));
      expect(not, isNotNull);
      expect(not!, isNot(contains('%')));
      expect(not, contains('avantaj'));
      print('');
      print('-- iş ilanı satırı: "$not" --');
    });

    test('avantajı olmayan işte satır yok', () {
      final GameState s = _hobi(_hayat(), 'yazilim', 3);
      // Hemşirelikle yazılımın bağı yok.
      expect(CareerSynergyRules.applicationNote(s, _is('hemsire')), isNull);
    });

    test('kurs kartı bu hobinin götürdüğü meslekleri sayıyor', () {
      final GameState s = _hobi(_hayat(), 'yazilim', 3);
      final ActivityAction kurs = kActivityActions
          .firstWhere((ActivityAction a) => a.id == 'bilgisayar_kursu');
      // Kurs gerçekten yazılım hobisini besliyor mu?
      expect(hobbyForActivity(kurs.id)?.id, 'yazilim');

      final List<JobType> beklenen = kJobCatalog
          .where((JobType j) =>
              j.synergies.any((CareerSynergy b) => b.hobbyId == 'yazilim'))
          .toList(growable: false);
      expect(beklenen.length, 3);
      for (final JobType j in beklenen) {
        expect(CareerSynergyRules.scoreFor(s, j), greaterThan(0),
            reason: '${j.name} kartta görünmeli.');
      }
      print('');
      print('-- Bilgisayar kursu — Tutkulu · kariyer avantajları --');
      for (final JobType j in beklenen) {
        print('  • ${j.name} — '
            '${CareerSynergyRules.label(CareerSynergyRules.scoreFor(s, j))}');
      }
    });
  });
}
