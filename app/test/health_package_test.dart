import 'dart:math';

import 'package:bir_omur/data/activity_catalog.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/domain/activities/activity_engine.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/generation/life_progression.dart';
import 'package:bir_omur/domain/life/eye_exam.dart';
import 'package:bir_omur/domain/life/health_report.dart';
import 'package:bir_omur/domain/life/hair_loss.dart';
import 'package:bir_omur/domain/life/sick_leave.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/interaction.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sağlık bildirimleri, göz muayenesi mini oyunu, estetik ve hastalık
/// (D-076, D-077, D-078).
void main() {
  ActivityAction eylem(String id) =>
      kActivityActions.firstWhere((ActivityAction a) => a.id == id);

  GameState hayat(
    int seed, {
    int age = 40,
    int wallet = 900000,
    int? health,
  }) {
    final GameState base =
        LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
    return base.copyWith(
      player: base.player.copyWith(
        age: age,
        wallet: wallet,
        stats: health == null
            ? base.player.stats
            : base.player.stats.copyWith(health: health),
      ),
    );
  }

  group('Check-up raporu (D-076)', () {
    test('rapor gerçek sağlık değerine bakar; sağlıklı olan daha iyi çıkar',
        () {
      int iyiSayisi(int health) => HealthChecks.checkup(hayat(1, health: health))
          .lines
          .where((HealthLine l) => l.status == OrganStatus.iyi)
          .length;

      expect(iyiSayisi(95), greaterThan(iyiSayisi(35)));
    });

    test('aynı yıl aynı rapor çıkar; her bakışta yeniden zar atılmaz', () {
      final GameState s = hayat(2, health: 60);
      final HealthReport ilk = HealthChecks.checkup(s);
      for (int i = 0; i < 10; i++) {
        final HealthReport tekrar = HealthChecks.checkup(s);
        expect(
          tekrar.lines.map((HealthLine l) => l.status).toList(),
          ilk.lines.map((HealthLine l) => l.status).toList(),
        );
      }
    });

    test('yaş ilerleyince rapor değişebilir', () {
      final Set<String> sonuclar = <String>{};
      for (int yas = 30; yas <= 80; yas += 10) {
        final HealthReport r = HealthChecks.checkup(hayat(3, age: yas, health: 70));
        sonuclar.add(r.lines.map((HealthLine l) => l.status.name).join(','));
      }
      expect(sonuclar.length, greaterThan(1));
    });

    test('rapor bütün sistemleri adıyla yazar', () {
      final HealthReport r = HealthChecks.checkup(hayat(4, health: 70));
      for (final String ad in <String>[
        'Kalp ve tansiyon',
        'Akciğerler',
        'Kan değerleri',
        'Kemik ve eklemler',
        'Görme',
        'İşitme',
      ]) {
        expect(r.noticeText, contains(ad));
      }
    });

    test('check-up ekran bildirimi üretir', () {
      final GameState s = hayat(5, health: 70);
      final ActivityResult r = const ActivityEngine()
          .perform(state: s, action: eylem('genel_kontrol'), rng: Random(1));
      expect(r.outcome.applied, isTrue);
      expect(r.state.nextNotice, isNotNull);
      expect(r.state.nextNotice!.kind, NoticeKind.saglik);
      expect(r.state.nextNotice!.text, contains('Check-up bitti'));
    });

    test('aşı, diş ve uzman görüşmesi de bildirim üretir', () {
      for (final String id in <String>['mevsim_asisi', 'dis_kontrol',
        'ruh_sagligi']) {
        final GameState s = hayat(6, health: 70);
        final ActivityResult r = const ActivityEngine()
            .perform(state: s, action: eylem(id), rng: Random(1));
        expect(r.outcome.applied, isTrue, reason: id);
        expect(r.state.nextNotice, isNotNull, reason: '$id bildirim üretmeli');
        expect(r.state.nextNotice!.text.length, greaterThan(20),
            reason: '$id sonucu anlatmalı');
      }
    });

    test('uzman görüşmesi "uzmanla konuştun" demekle yetinmez', () {
      final GameState s = hayat(7, health: 70);
      final ActivityResult r = const ActivityEngine()
          .perform(state: s, action: eylem('ruh_sagligi'), rng: Random(1));
      expect(r.outcome.text, isNot(contains('tamamlandı')));
      expect(r.outcome.text, contains('Uzman'));
    });

    test('mutluluğu düşük ve yüksek oyuncu farklı cevap alır', () {
      final GameState mutlu = hayat(8).copyWith(
        player: hayat(8).player.copyWith(
              stats: hayat(8).player.stats.copyWith(happiness: 90),
            ),
      );
      final GameState kederli = hayat(8).copyWith(
        player: hayat(8).player.copyWith(
              stats: hayat(8).player.stats.copyWith(happiness: 10),
            ),
      );
      expect(
        HealthChecks.therapyOutcome(mutlu),
        isNot(HealthChecks.therapyOutcome(kederli)),
      );
    });
  });

  group('Tahlile yönlendirme (D-076)', () {
    test('yönlendirme yokken tahlil düğmesi kapalıdır', () {
      final GameState s = hayat(9, health: 95);
      final InteractionAvailability a =
          const ActivityEngine().availability(s, eylem('tahlil'));
      expect(a.isAllowed, isFalse);
      expect(a.reason, isNotNull);
    });

    test('raporu bozuk çıkan oyuncuya yönlendirme açılır ve tahlil kapatır',
        () {
      // Sağlığı düşük oyuncuda en az bir sistem takip gerektirir.
      final GameState s = hayat(10, health: 30);
      expect(HealthChecks.checkup(s).needsLabTest, isTrue);

      final ActivityResult kontrol = const ActivityEngine()
          .perform(state: s, action: eylem('genel_kontrol'), rng: Random(1));
      expect(
        kontrol.state.storyFlags.contains(HealthChecks.labTestFlag),
        isTrue,
        reason: 'Yönlendirme izi eklenmeli',
      );
      expect(
        const ActivityEngine()
            .availability(kontrol.state, eylem('tahlil'))
            .isAllowed,
        isTrue,
      );

      final ActivityResult tahlil = const ActivityEngine()
          .perform(state: kontrol.state, action: eylem('tahlil'), rng: Random(1));
      expect(tahlil.outcome.applied, isTrue);
      expect(
        tahlil.state.storyFlags.contains(HealthChecks.labTestFlag),
        isFalse,
        reason: 'Tahlile gidilince yönlendirme kapanmalı',
      );
    });
  });

  group('Göz muayenesi mini oyunu (D-076)', () {
    test('her satırda tam bir tane farklı karakter vardır', () {
      for (int seed = 0; seed < 50; seed++) {
        final EyeExamPuzzle p = EyeExam.generate(Random(seed));
        expect(p.length, EyeExam.rowCount);
        for (final EyeExamRow r in p.rows) {
          final String farkli = r.odd;
          final int adet =
              r.characters.where((String c) => c == farkli).length;
          expect(adet, 1, reason: 'Satırda tam bir farklı karakter olmalı');
          expect(r.oddIndex, inInclusiveRange(0, r.characters.length - 1));
        }
      }
    });

    test('satırlar aşağı indikçe uzar ve punto küçülür', () {
      final EyeExamPuzzle p = EyeExam.generate(Random(1));
      for (int i = 1; i < p.length; i++) {
        expect(
          p.rows[i].characters.length,
          greaterThan(p.rows[i - 1].characters.length),
        );
        expect(p.rows[i].fontSize, lessThan(p.rows[i - 1].fontSize));
      }
    });

    test('benzeyen karakter çiftleri birbirinden farklıdır', () {
      for (final List<String> cift in EyeExam.lookalikes) {
        expect(cift.length, 2);
        expect(cift[0], isNot(cift[1]));
      }
    });

    test('hekimin değerlendirmesi oyuncunun puanından bağımsızdır', () {
      // Mini oyunda iyi oynamak karakterin gözünü iyileştirmez.
      final String genc = EyeExam.sightNote(age: 25, health: 90);
      final String yasli = EyeExam.sightNote(age: 70, health: 40);
      expect(genc, isNot(yasli));
      expect(yasli, contains('azalma'));
    });

    test('puan metni gerçek sayıyı yazar', () {
      expect(EyeExam.scoreText(3, 5), contains('3'));
      expect(EyeExam.scoreText(5, 5), isNot(contains('zorlandın')));
    });
  });

  group('Estetik (D-077)', () {
    test('estetik işlemler erişkin yaş şartı taşır ve gerekçesi yazar', () {
      final List<ActivityAction> estetikler =
          actionsAt(ActivityVenue.estetik);
      expect(estetikler, isNotEmpty);
      for (final ActivityAction a in estetikler) {
        expect(a.minAge, greaterThanOrEqualTo(18), reason: a.id);
        expect(a.minAgeNote, isNotNull, reason: '${a.id} gerekçesiz');
        expect(a.riskChance, greaterThan(0),
            reason: '${a.id} risksiz görünmemeli');
      }
    });

    test('dökülme yokken saç ektirilemez', () {
      final GameState s = hayat(11, age: 40);
      expect(s.player.hairLossStage, 0);
      final InteractionAvailability a =
          const ActivityEngine().availability(s, eylem('sac_ekimi'));
      expect(a.isAllowed, isFalse);
      expect(a.reason, contains('dökülme'));
    });

    test('saç ekimi basamağı bir kademe düşürür', () {
      GameState s = hayat(12, age: 40);
      s = s.copyWith(player: s.player.copyWith(hairLossStage: 2));

      // Riskin gerçekleşmediği bir tohum aranır; kötü sonuçta basamak
      // düşmez, bu da kuralın kendisidir.
      bool dustu = false;
      for (int seed = 0; seed < 40 && !dustu; seed++) {
        final ActivityResult r = const ActivityEngine()
            .perform(state: s, action: eylem('sac_ekimi'), rng: Random(seed));
        if (r.outcome.applied && r.state.player.hairLossStage == 1) {
          dustu = true;
        }
      }
      expect(dustu, isTrue, reason: 'Başarılı ekim basamağı düşürmeli');
    });

    test('estetik işlem kötü sonuçlanabilir: ücret gider, kazanç gelmez', () {
      final GameState s = hayat(13, age: 40);
      bool kotuGoruldu = false;
      for (int seed = 0; seed < 80 && !kotuGoruldu; seed++) {
        final ActivityResult r = const ActivityEngine().perform(
          state: s,
          action: eylem('burun_ameliyati'),
          rng: Random(seed),
        );
        if (!r.outcome.applied) continue;
        if (r.state.player.stats.appearance <= s.player.stats.appearance) {
          kotuGoruldu = true;
          expect(
            r.state.player.wallet,
            s.player.wallet - eylem('burun_ameliyati').cost,
            reason: 'Kötü sonuçta da ücret ödenir',
          );
          expect(
            r.state.player.stats.happiness,
            lessThan(s.player.stats.happiness),
          );
        }
      }
      expect(kotuGoruldu, isTrue, reason: 'Risk gerçekten işlemeli');
    });

    test('estetik işlemler de bildirim üretir', () {
      final GameState s = hayat(14, age: 40);
      final ActivityResult r = const ActivityEngine()
          .perform(state: s, action: eylem('kas_dolgusu'), rng: Random(1));
      expect(r.outcome.applied, isTrue);
      expect(r.state.nextNotice, isNotNull);
      expect(r.state.nextNotice!.kind, NoticeKind.saglik);
    });

    test('estetik fiyatları 2026 ölçeğinde ve birbirine göre tutarlı', () {
      int ucret(String id) => eylem(id).cost;
      // Dolgu en ucuz, gülüş tasarımı en pahalı olmalı.
      expect(ucret('kas_dolgusu'), lessThan(ucret('goz_kapagi')));
      expect(ucret('goz_kapagi'), lessThan(ucret('burun_ameliyati')));
      expect(ucret('burun_ameliyati'), lessThan(ucret('dis_estetigi')));
    });
  });

  group('Hastalık ve işe gidememe (D-078)', () {
    test('okul çağından önce işletilmez', () {
      final Random rng = Random(1);
      for (int yas = 0; yas < SickLeaves.prototypeOnlyMinAge; yas++) {
        for (int i = 0; i < 30; i++) {
          final SickLeave s = SickLeaves.roll(
            age: yas,
            health: 20,
            yearsSinceSport: null,
            yearlySalary: null,
            previousWarnings: 0,
            rng: rng,
          );
          expect(s.happened, isFalse, reason: '$yas yaşında hastalık yok');
        }
      }
    });

    test('sağlığı düşük olan daha sık hastalanır', () {
      expect(
        SickLeaves.chance(age: 40, health: 30, yearsSinceSport: null),
        greaterThan(
          SickLeaves.chance(age: 40, health: 90, yearsSinceSport: null),
        ),
      );
    });

    test('spor yapan daha az hastalanır', () {
      expect(
        SickLeaves.chance(age: 40, health: 60, yearsSinceSport: 0),
        lessThan(SickLeaves.chance(age: 40, health: 60, yearsSinceSport: 10)),
      );
    });

    test('rapor süresi 3-7 gün arasındadır', () {
      for (int seed = 0; seed < 300; seed++) {
        final SickLeave s = SickLeaves.roll(
          age: 40,
          health: 20,
          yearsSinceSport: null,
          yearlySalary: 600000,
          previousWarnings: 0,
          rng: Random(seed),
        );
        if (!s.happened) continue;
        expect(s.days, inInclusiveRange(
          SickLeaves.prototypeOnlyMinDays,
          SickLeaves.prototypeOnlyMaxDays,
        ));
      }
    });

    test('çalışmayan oyuncuda gelir kaybı olmaz ve işveren tepkisi çıkmaz',
        () {
      for (int seed = 0; seed < 120; seed++) {
        final SickLeave s = SickLeaves.roll(
          age: 40,
          health: 20,
          yearsSinceSport: null,
          yearlySalary: null,
          previousWarnings: 0,
          rng: Random(seed),
        );
        if (!s.happened) continue;
        expect(s.wageLoss, 0);
        expect(s.employerUpset, isFalse);
        expect(s.text, isNot(contains('işe gidemedin')));
      }
    });

    test('çalışan oyuncuda ödenmeyen günler gelirden düşer', () {
      bool gorunen = false;
      for (int seed = 0; seed < 200 && !gorunen; seed++) {
        final SickLeave s = SickLeaves.roll(
          age: 40,
          health: 20,
          yearsSinceSport: null,
          yearlySalary: 730000,
          previousWarnings: 0,
          rng: Random(seed),
        );
        if (!s.happened) continue;
        gorunen = true;
        expect(s.wageLoss, greaterThan(0));
        // İlk iki gün ödenmez: yıllık 730.000 ₺ için günlük 2.000 ₺.
        expect(s.wageLoss, 4000);
      }
      expect(gorunen, isTrue);
    });

    test('uyarı işten çıkarılma ihtimalini artırır ama tavanı vardır', () {
      expect(SickLeaves.layoffBonus(0), 0);
      expect(SickLeaves.layoffBonus(1),
          greaterThan(SickLeaves.layoffBonus(0)));
      expect(
        SickLeaves.layoffBonus(100),
        SickLeaves.prototypeOnlyMaxWarningBonus,
      );
    });

    test('işveren uyarısı kayda girer ve kapat-aç ile korunur', () {
      GameState s = hayat(15, age: 40);
      s = s.copyWith(career: s.career.copyWith(employerWarnings: 2));
      final GameState geri = decodeGameState(encodeGameState(s));
      expect(geri.career.employerWarnings, 2);
    });

    test('eski kayıtta uyarı yoktur; sıfır okunur', () {
      final GameState s = hayat(16, age: 40);
      final Map<String, Object?> json = encodeGameState(s);
      (json['career']! as Map<String, Object?>).remove('employerWarnings');
      expect(decodeGameState(json).career.employerWarnings, 0);
    });

    test('bir ömür boyunca hastalık gerçekten yaşanır', () {
      int hastalikliHayat = 0;
      for (int seed = 0; seed < 40; seed++) {
        GameState s = LifeGenerator.seeded(seed)
            .generate(mode: StartMode.tamamenRastgele);
        final LifeProgression lp = LifeProgression(Random(seed + 500));
        while (!s.deceased && s.player.age < 70) {
          s = lp.advanceOneYear(s.copyWith(pendingEvent: null));
        }
        if (s.log.any((dynamic e) =>
            (e.text as String).contains('hasta yattın') ||
            (e.text as String).contains('yatakta kaldın'))) {
          hastalikliHayat++;
        }
      }
      expect(hastalikliHayat, greaterThan(5),
          reason: 'Hastalık hayatta görünür olmalı (ölçülen: $hastalikliHayat)');
    });
  });

  group('Saç ekimi ve dökülme birlikte', () {
    test('ekim basamağı sıfırın altına indirmez', () {
      GameState s = hayat(17, age: 40);
      s = s.copyWith(player: s.player.copyWith(hairLossStage: 1));
      for (int seed = 0; seed < 40; seed++) {
        final ActivityResult r = const ActivityEngine()
            .perform(state: s, action: eylem('sac_ekimi'), rng: Random(seed));
        if (!r.outcome.applied) continue;
        expect(r.state.player.hairLossStage,
            inInclusiveRange(0, HairLoss.maxStage));
      }
    });
  });
}
