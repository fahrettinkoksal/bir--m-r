import 'dart:math';

import 'package:bir_omur/data/job_catalog.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/generation/life_progression.dart';
import 'package:bir_omur/domain/life/notices.dart';
import 'package:bir_omur/domain/models/career.dart';
import 'package:bir_omur/domain/models/education.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_flow.dart';

/// Kritik haberler ekranda gösterilir (D-097) ve bildirim yağmuru olmaz.
void main() {
  /// İşe girmiş, yıllardır çalışan bir oyuncu durumu.
  GameState iseGirmisOyuncu({int seed = 3}) {
    final GameState base =
        LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
    final JobType is1 = kJobCatalog.firstWhere(
      (JobType j) => j.minAge <= 22 && j.education == JobEducation.yok,
      orElse: () => kJobCatalog.first,
    );
    return base.copyWith(
      pendingEvent: null,
      player: base.player.copyWith(age: 30, wallet: 400000),
      education: const EducationState(finished: true, startedAtAge: 6),
      career: CareerState(
        jobId: is1.id,
        startedAtAge: 22,
        salary: is1.yearlySalary,
      ),
    );
  }

  GameController hayat({int seed = 5}) {
    final GameController controller = GameController(random: Random(seed));
    controller.startNewLife(mode: StartMode.tamamenRastgele, seed: seed);
    return controller;
  }

  test('bir yılda aynı anda biriken bildirim sayısı makul kalır', () {
    int enCok = 0;
    int toplamBildirim = 0;
    int toplamYil = 0;

    for (int seed = 0; seed < 100; seed++) {
      final GameController controller = hayat(seed: seed);
      int guard = 0;
      while (!controller.state!.deceased && guard++ < 100) {
        final int oncekiYas = controller.state!.player.age;
        resolveTrackChoice(controller);
        controller.ageUp();
        if (controller.state!.player.age == oncekiYas) break;

        final int bekleyen = controller.state!.notices.length;
        if (bekleyen > enCok) enCok = bekleyen;
        toplamBildirim += bekleyen;
        toplamYil++;

        // Bildirimleri oyuncu gibi kapat, sonra olayı çöz.
        int noticeGuard = 0;
        while (controller.state!.hasNotice && noticeGuard++ < 30) {
          controller.dismissNotice();
        }
        resolvePendingEvents(controller);
      }
    }

    // ignore: avoid_print
    print('BILDIRIM: en cok $enCok / yil, ortalama '
        '${(toplamBildirim / toplamYil).toStringAsFixed(2)}');
    expect(toplamYil, greaterThan(1000), reason: 'Ölçüm yeterince geniş');
    expect(
      enCok,
      lessThanOrEqualTo(7),
      reason: 'Ölçülen en kötü yıl yedi penceredir: aynı yıl **üç** '
          'yakınını kaybeden oyuncuda üç vefat, üç cenaze ve bir toplu '
          'miras. Vefat ve cenaze kişiye özeldir, birleştirilmez; '
          'daha fazlası bildirim yağmuru sayılır.',
    );
    expect(
      toplamBildirim / toplamYil,
      lessThan(1.0),
      reason: 'Ortalama bir yıl bir pencereden az bildirim üretmeli.',
    );
  });

  test('işten çıkarılma bildirimi kuyruğa girer', () {
    // Gerçek akışta işten çıkarılma seyrektir; bildirim kuyruğunun
    // kritik iş haberini taşıdığı doğrudan sınanır.
    final GameController controller = hayat();
    final GameState state = controller.state!;
    final PendingNotice bildirim = PendingNotice(
      id: 'kariyer-isten-cikarma-${state.player.age}',
      kind: NoticeKind.kariyer,
      age: state.player.age,
      title: 'İşten çıkarıldın',
      text: 'İşine son verildi.',
    );
    controller.debugSetState(
      state.copyWith(
        notices: List<PendingNotice>.unmodifiable(<PendingNotice>[bildirim]),
      ),
    );
    expect(controller.state!.hasNotice, isTrue);
    expect(controller.state!.nextNotice!.kind, NoticeKind.kariyer);
    controller.dismissNotice();
    expect(controller.state!.hasNotice, isFalse);
  });

  test('işten çıkarılma bildirimi gerçek akışta üretilir', () {
    // İşe girmiş bir karakter yıllar boyunca ilerletilir; işten
    // çıkarılma seyrektir ama olduğunda bildirim kuyruğuna girer.
    bool bildirimGoruldu = false;
    for (int seed = 0; seed < 40 && !bildirimGoruldu; seed++) {
      GameState s = iseGirmisOyuncu(seed: seed);
      for (int yil = 0; yil < 40; yil++) {
        s = LifeProgression(Random(seed * 100 + yil)).advanceOneYear(s);
        if (s.deceased) break;
        final bool kariyerBildirimi = s.notices.any(
          (PendingNotice n) => n.kind == NoticeKind.kariyer,
        );
        if (kariyerBildirimi) {
          bildirimGoruldu = true;
          final PendingNotice n = s.notices.firstWhere(
            (PendingNotice n) => n.kind == NoticeKind.kariyer,
          );
          expect(n.text, isNotEmpty);
          expect(n.age, s.player.age);
          break;
        }
        // Bildirimler ve olay birikmesin.
        s = s.copyWith(
          notices: const <PendingNotice>[],
          pendingEvent: null,
          pendingCrisis: null,
        );
      }
    }
    expect(
      bildirimGoruldu,
      isTrue,
      reason: 'Hiç üretilmeyen bildirim yazılmış sayılmaz.',
    );
  });

  test('aynı yıl gelen miras payları tek bildirimde toplanır', () {
    final GameController controller = hayat();
    final GameState state = controller.state!;
    final PendingNotice a = PendingNotice(
      id: 'miras-a',
      kind: NoticeKind.miras,
      age: state.player.age,
      title: 'Miras',
      text: 'Deden Kemal vefatının ardından payına 1.000 ₺ düştü.',
      money: 1000,
      itemNames: const <String>['Saat'],
    );
    final PendingNotice b = PendingNotice(
      id: 'miras-b',
      kind: NoticeKind.miras,
      age: state.player.age,
      title: 'Miras',
      text: 'Ninen Hatice vefatının ardından payına 2.500 ₺ düştü.',
      money: 2500,
      itemNames: const <String>['Yüzük'],
    );

    // Tek pay: bildirim olduğu gibi kalır.
    expect(
      Notices.combinedInheritance(
        playerAge: state.player.age,
        shares: <PendingNotice>[a],
      ),
      same(a),
    );

    // İki pay: tek bildirim, tutar ve eşyalar toplanır, hiçbiri kaybolmaz.
    final PendingNotice? toplu = Notices.combinedInheritance(
      playerAge: state.player.age,
      shares: <PendingNotice>[a, b],
    );
    expect(toplu, isNotNull);
    expect(toplu!.money, 3500);
    expect(toplu.itemNames, containsAll(<String>['Saat', 'Yüzük']));
    expect(toplu.text, contains('Kemal'));
    expect(toplu.text, contains('Hatice'));
  });
}
