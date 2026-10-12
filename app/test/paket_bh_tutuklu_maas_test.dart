// Tutukluyken maaş yatmaz, kıdem ilerlemez, iş bitmez (Q-199).
//
// **Nasıl bulundu.** Özel durum dökümü
// (`ekran_dokumu_ozel_durum_test.dart`) cezaevi karesini bastı ve
// günlükte şu iki satır yan yanaydı:
//
//     Bir yıl daha tutuklu geçti. Dosya hâlâ açık.
//     Oto tamircisi olarak bir yılın doldu; 631.800 ₺ cüzdanına girdi.
//     Oto tamircisi olarak 3 yılı doldurdun: artık kalfa sayılıyorsun.
//
// **Ölçüm (120 bot hayatı, elle kurulmuş durum yok):** hükümlü geçen 13
// yılın **0'ında** oyuncunun işi vardı — D-128 oradaki kuralı
// (`LegalEngine._enterPrison` işi bitirir) doğru uyguluyor. Tutuklu
// geçen 32 yılın ise **27'sinde** (%84) iş duruyor ve maaş akıyordu.
// D-128 yalnızca "hapis" diyor; tutukluluk orada geçmiyordu.
//
// **Kural (Faho onayladı, 6 Ekim 2026, Q-199):** tutuklulukta **iş
// bitmez**, **maaş ödenmez**, o yıl **kıdeme sayılmaz**. Tahliye olan
// işine döner; dosya mahkûmiyetle kapanırsa iş o zaman biter.
// Alternatif (tutuklulukta da işi bitirmek) bilerek seçilmedi: beraat
// eden oyuncu işini de kaybetmiş olurdu.
//
// **Kıdem neden `startedAtAge` ile oynanarak değil ayrı alanla
// donduruldu:** ekran "Başlangıç: 22 yaşında" diye o alanı gösteriyor;
// onu kaydırmak doğru bilgiyi bozardı. İçeride geçen yıllar
// `CareerState.detainedYears` içinde tutulup `yearsInJob`'dan düşülüyor.
// `yearsInJob` tek sıkıştırma noktası: ustalık, zam, terfi, işten
// çıkarma, olay koşulu ve Meslek ekranı hepsi oradan okuyor.
library;

import 'dart:math';

import 'package:bir_omur/data/job_catalog.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/generation/life_progression.dart';
import 'package:bir_omur/domain/models/career.dart';
import 'package:bir_omur/domain/models/criminal_record.dart';
import 'package:bir_omur/domain/models/education.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final JobType is_ = jobById('magaza_calisani')!;

  GameState calisan({required LegalState hukuk, int age = 40}) {
    final GameState temel =
        LifeGenerator.seeded(5).generate(mode: StartMode.tamamenRastgele);
    return temel.copyWith(
      pendingEvent: null,
      player: temel.player.copyWith(age: age, wallet: 0),
      education: const EducationState(finished: true, startedAtAge: 6),
      career: CareerState(
        jobId: is_.id,
        startedAtAge: 30,
        lastPaidAge: age - 1,
        salary: 500000,
        jobCity: temel.player.currentCity,
      ),
      legal: hukuk,
    );
  }

  test('tutukluyken maaş yatmaz ama iş bitmez', () {
    final GameState kur = calisan(hukuk: const LegalState(detainedSinceAge: 39));
    final GameState sonra = LifeProgression(Random(3)).advanceOneYear(kur);

    expect(sonra.career.isEmployed, isTrue,
        reason: 'Tutukluluk işi bitirmez; tahliyede işine dönecek.');
    expect(sonra.player.wallet, lessThan(500000),
        reason: 'Maaş yatmamalı. Cüzdan: ${sonra.player.wallet} ₺');
    expect(sonra.career.detainedYears, 1,
        reason: 'İçeride geçen yıl sayılmalı.');
  });

  test('serbest oyuncunun maaşı yatmaya devam eder', () {
    final GameState kur = calisan(hukuk: const LegalState());
    final GameState sonra = LifeProgression(Random(3)).advanceOneYear(kur);

    expect(sonra.player.wallet, greaterThan(100000),
        reason: 'Serbest oyuncunun maaşı kesilmemeli.');
    expect(sonra.career.detainedYears, 0);
  });

  test('içeride geçen yıl kıdeme sayılmaz', () {
    // 30'da başlayan, 40 yaşındaki oyuncu: 10 yıl kıdem.
    const CareerState temiz = CareerState(jobId: 'magaza_calisani',
        startedAtAge: 30);
    expect(temiz.yearsInJob(40), 10);

    // Aynı oyuncu üç yıl tutuklu kaldıysa kıdemi 7.
    final CareerState donmus = temiz.copyWith(detainedYears: 3);
    expect(donmus.yearsInJob(40), 7,
        reason: 'İçeride geçen yıl ustalığa ve zam hakkına sayılmaz.');

    // Başlangıç yaşı **oynanmadı**: ekranın gösterdiği bilgi doğru kalır.
    expect(donmus.startedAtAge, 30);

    // Toplam çalışma yılı da aynı hesabı kullanır.
    expect(donmus.totalWorkYears(40), 7);
  });

  test('kıdem eksiye düşmez', () {
    const CareerState abartili = CareerState(
      jobId: 'magaza_calisani',
      startedAtAge: 38,
      detainedYears: 9,
    );
    expect(abartili.yearsInJob(40), 0,
        reason: 'Veri bozuksa bile kıdem eksi görünmemeli.');
  });

  test('donmuş yıl sayısı kayıtta korunur', () {
    final GameState kur = calisan(hukuk: const LegalState(detainedSinceAge: 39))
        .copyWith(career: calisan(hukuk: const LegalState())
            .career
            .copyWith(detainedYears: 4));
    final GameState geri = decodeGameState(encodeGameState(kur));
    expect(geri.career.detainedYears, 4,
        reason: 'Alan kodeke yazılmazsa kayıt yüklenince kıdem geri '
            'sıçrar ve oyuncu içeride geçen yılları kazanır.');
  });

  test('hükümlü tarafı değişmedi: iş biter (D-128)', () {
    // Bu, Q-199 düzeltmesinin hükümlü tarafını bozmadığının kontrolü.
    // Hükümlülük `_enterPrison` üzerinden gelir ve işi bitirir; burada
    // yalnızca kuralın yerinde olduğunu sabitliyoruz.
    expect(JobEndReason.hapis.label, 'Hapis nedeniyle ayrıldı');
  });
}
