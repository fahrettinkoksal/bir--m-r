import 'dart:math';

import 'package:bir_omur/data/military_catalog.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/domain/career/military_service.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/generation/life_progression.dart';
import 'package:bir_omur/domain/life/notices.dart';
import 'package:bir_omur/domain/models/education.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/military.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:flutter_test/flutter_test.dart';

/// İstenen cinsiyette bir hayat bulur (cinsiyet kalıcıdır).
GameState hayat({
  Gender cinsiyet = Gender.erkek,
  int age = 20,
  int wallet = 0,
  EducationState egitim = const EducationState(finished: true, startedAtAge: 6),
}) {
  for (int seed = 0; seed < 120; seed++) {
    final GameState aday =
        LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
    if (aday.player.gender != cinsiyet) continue;
    return aday.copyWith(
      pendingEvent: null,
      player: aday.player.copyWith(age: age, wallet: wallet),
      education: egitim,
    );
  }
  throw StateError('$cinsiyet cinsiyetinde hayat bulunamadı');
}

/// Varlıklı ve yakın bir baba ekler.
GameState zenginBabali(GameState state, {int bond = 90}) {
  bool bulundu = false;
  final List<Person> kisiler = state.people.map((Person p) {
    if (!bulundu && p.isAlive && p.wealth != null) {
      bulundu = true;
      return p.copyWith(bond: bond, wealth: WealthTier.cokVarlikli);
    }
    return p;
  }).toList(growable: false);
  return state.copyWith(people: kisiler);
}

void main() {
  group('Yükümlülük ve celp', () {
    test('18 yaşından önce katılınamaz', () {
      final GameState genc = hayat(age: 16);
      for (final MilitaryTrack yol in MilitaryTrack.values) {
        expect(MilitaryService.blockReason(genc, yol), isNotEmpty);
      }
    });

    test('okuyan öğrenci çağrılmaz', () {
      final GameState ogrenci = hayat(
        age: 22,
        egitim: const EducationState(
          finished: true,
          startedAtAge: 6,
          universityProgramId: 'x',
        ),
      );
      expect(ogrenci.education.isStudent, isTrue);
      expect(MilitaryService.canBeCalled(ogrenci), isFalse);
    });

    test('okumayan yükümlü 20 yaşında çağrılır', () {
      final GameState s = hayat(age: 20);
      expect(MilitaryService.canBeCalled(s), isTrue);
      final GameState sonra = MilitaryService.applyCallUp(s, 20);
      expect(sonra.military.status, MilitaryStatus.cagrildi);
      expect(sonra.military.calledAtAge, 20);
      // Sessizce olmaz: ekranda bildirim çıkar.
      expect(
        sonra.notices.any((PendingNotice n) => n.kind == NoticeKind.askerlik),
        isTrue,
      );
    });

    test('20 yaşından önce çağrı gelmez', () {
      final GameState s = hayat(age: 19);
      expect(MilitaryService.canBeCalled(s), isFalse);
      expect(MilitaryService.applyCallUp(s, 19).military.status,
          MilitaryStatus.yok);
    });

    test('aynı celp iki kez kuyruğa girmez', () {
      final GameState s = hayat(age: 20);
      final GameState bir = MilitaryService.applyCallUp(s, 20);
      final GameState iki = MilitaryService.applyCallUp(bir, 20);
      expect(
        iki.notices.where((PendingNotice n) => n.kind == NoticeKind.askerlik),
        hasLength(1),
      );
    });

    test('yükümlü olmayan hayatta er yolu kapalı, rütbeli yol açık', () {
      final GameState kadin = hayat(
        cinsiyet: Gender.kadin,
        age: 24,
        egitim: const EducationState(
          finished: true,
          startedAtAge: 6,
          universityProgramId: 'x',
          universityFinished: true,
        ),
      );
      expect(MilitaryService.isObliged(kadin), isFalse);
      expect(MilitaryService.canBeCalled(kadin), isFalse);
      expect(
        MilitaryService.blockReason(kadin, MilitaryTrack.er),
        isNotEmpty,
      );
      expect(
        MilitaryService.blockReason(kadin, MilitaryTrack.subay),
        isEmpty,
      );
    });

    test('yükümlülük yaşı geçince çağrı gelmez', () {
      final GameState yasli =
          hayat(age: MilitaryService.prototypeOnlyExemptAge);
      expect(MilitaryService.canBeCalled(yasli), isFalse);
    });
  });

  group('Katılma ve rütbe', () {
    test('er olarak gidilir ve süresi dolunca terhis olunur', () {
      GameState s = hayat(age: 20);
      s = MilitaryService.enlist(s, MilitaryTrack.er, Random(1)).state;
      expect(s.military.isServing, isTrue);
      expect(s.military.rank!.id, 'er');

      // Bir yıl sonra terhis.
      final int bitis = 20 + MilitaryTrack.er.prototypeOnlyYears;
      final GameState sonra = MilitaryService.advanceYear(s, bitis);
      expect(sonra.military.status, MilitaryStatus.tamamlandi);
      expect(sonra.military.finishedAtAge, bitis);
      expect(
        sonra.notices.any((PendingNotice n) =>
            n.id == Notices.militaryDischargeNoticeId),
        isTrue,
      );
    });

    test('lise mezunu olmayan astsubay olamaz', () {
      final GameState s = hayat(
        age: 20,
        egitim: const EducationState(startedAtAge: 6),
      );
      expect(
        MilitaryService.blockReason(s, MilitaryTrack.astsubay),
        contains('lise'),
      );
    });

    test('üniversite mezunu olmayan subay olamaz', () {
      final GameState s = hayat(age: 24);
      expect(
        MilitaryService.blockReason(s, MilitaryTrack.subay),
        contains('üniversite'),
      );
    });

    test('rütbeli başvuru reddedilebilir', () {
      final GameState s = hayat(
        age: 24,
        egitim: const EducationState(
          finished: true,
          startedAtAge: 6,
          universityProgramId: 'x',
          universityFinished: true,
        ),
      );
      int kabul = 0;
      int ret = 0;
      for (int seed = 0; seed < 60; seed++) {
        final MilitaryResult r =
            MilitaryService.enlist(s, MilitaryTrack.subay, Random(seed));
        expect(r.applied, isTrue);
        if (r.state.military.isServing) {
          kabul++;
        } else {
          ret++;
        }
      }
      expect(kabul, greaterThan(0), reason: 'Hiç kabul edilmiyor');
      expect(ret, greaterThan(0), reason: 'Her başvuru kabul ediliyor');
    });

    test('görevde yıllar geçtikçe rütbe yükselir ve maaş yatar', () {
      GameState s = hayat(
        age: 24,
        egitim: const EducationState(
          finished: true,
          startedAtAge: 6,
          universityProgramId: 'x',
          universityFinished: true,
        ),
      );
      // Kabul edilene kadar dene.
      for (int seed = 0; seed < 60 && !s.military.isServing; seed++) {
        s = MilitaryService.enlist(s, MilitaryTrack.subay, Random(seed)).state;
      }
      expect(s.military.isServing, isTrue);
      final String ilkRutbe = s.military.rankId!;
      final int ilkCuzdan = s.player.wallet;

      GameState akan = s;
      for (int i = 1; i <= 3; i++) {
        akan = MilitaryService.advanceYear(
          akan.copyWith(player: akan.player.copyWith(age: 24 + i)),
          24 + i,
        );
      }
      expect(akan.military.rankId, isNot(ilkRutbe));
      expect(akan.player.wallet, greaterThan(ilkCuzdan));
    });

    test('er maaş almaz', () {
      expect(MilitaryTrack.er.prototypeOnlySalary, 0);
      GameState s = hayat(age: 20, wallet: 1000);
      s = MilitaryService.enlist(s, MilitaryTrack.er, Random(1)).state;
      final GameState sonra = MilitaryService.advanceYear(
        s.copyWith(player: s.player.copyWith(age: 21)),
        21,
      );
      expect(sonra.player.wallet, 1000);
    });

    test('görevdeyken ikinci kez katılınamaz', () {
      GameState s = hayat(age: 20);
      s = MilitaryService.enlist(s, MilitaryTrack.er, Random(1)).state;
      expect(
        MilitaryService.blockReason(s, MilitaryTrack.er),
        contains('görevdesin'),
      );
    });
  });

  group('Bedelli', () {
    test('parası yetmeyen kendi ödeyemez ve cüzdan değişmez', () {
      final GameState s = hayat(age: 21, wallet: 1000);
      final MilitaryResult r = MilitaryService.payBedelli(s);
      expect(r.applied, isFalse);
      expect(r.text, contains('yeterli para yok'));
      expect(r.state.player.wallet, 1000);
      expect(r.state.military.status, MilitaryStatus.yok);
    });

    test('parası olan öder ve askerlik kapanır', () {
      final GameState s = hayat(
        age: 21,
        wallet: MilitaryService.prototypeOnlyBedelliCost + 5000,
      );
      final MilitaryResult r = MilitaryService.payBedelli(s);
      expect(r.applied, isTrue);
      expect(r.state.military.status, MilitaryStatus.bedelli);
      expect(r.state.player.wallet, 5000);
      expect(r.state.military.paidByPersonId, isNull,
          reason: 'Kendi ödedi; uydurma ödeyen yazılmaz');
    });

    test('ödeyebilecek yakını olmayanda liste boş', () {
      final GameState s = hayat(age: 21);
      // Kimsenin serveti ve yakınlığı yeterli değil.
      final GameState fakir = s.copyWith(
        people: s.people
            .map((Person p) =>
                p.copyWith(wealth: WealthTier.yoksul, bond: 20))
            .toList(growable: false),
      );
      expect(MilitaryService.possiblePayers(fakir), isEmpty);
    });

    test('varlıklı ve yakın biri listeye girer', () {
      final GameState s = zenginBabali(hayat(age: 21));
      expect(MilitaryService.possiblePayers(s), isNotEmpty);
    });

    test('aileden istemek gerçekten reddedilebilir', () {
      final GameState s = zenginBabali(hayat(age: 21), bond: 60);
      final Person odeyen = MilitaryService.possiblePayers(s).first;
      int kabul = 0;
      int ret = 0;
      for (int seed = 0; seed < 80; seed++) {
        final MilitaryResult r =
            MilitaryService.askFamilyForBedelli(s, odeyen.id, Random(seed));
        expect(r.applied, isTrue);
        if (r.state.military.status == MilitaryStatus.bedelli) {
          kabul++;
        } else {
          ret++;
        }
      }
      expect(kabul, greaterThan(0), reason: 'Hiç kabul edilmiyor');
      expect(ret, greaterThan(0), reason: 'Her istek kabul ediliyor');
    });

    test('aile ödeyince oyuncunun cüzdanından para çıkmaz', () {
      final GameState s = zenginBabali(hayat(age: 21, wallet: 7000));
      final Person odeyen = MilitaryService.possiblePayers(s).first;
      for (int seed = 0; seed < 80; seed++) {
        final MilitaryResult r =
            MilitaryService.askFamilyForBedelli(s, odeyen.id, Random(seed));
        if (r.state.military.status != MilitaryStatus.bedelli) continue;
        expect(r.state.player.wallet, 7000);
        expect(r.state.military.paidByPersonId, odeyen.id);
        return;
      }
      fail('Hiç kabul edilmedi');
    });

    test('yakınlığı düşük kişiden istenemez', () {
      final GameState s = zenginBabali(hayat(age: 21), bond: 10);
      final Person uzak = s.people.firstWhere(
        (Person p) => p.wealth == WealthTier.cokVarlikli,
      );
      final MilitaryResult r =
          MilitaryService.askFamilyForBedelli(s, uzak.id, Random(1));
      expect(r.applied, isFalse);
      expect(r.state.military.status, MilitaryStatus.yok);
    });

    test('yükümlü olmayan bedelli ödemez', () {
      final GameState kadin = hayat(
        cinsiyet: Gender.kadin,
        age: 24,
        wallet: 999999,
      );
      expect(
        MilitaryService.bedelliBlockReason(kadin),
        contains('yükümlülüğü yok'),
      );
    });
  });

  group('Kayıt ve yıllık akış', () {
    test('askerlik kaydı kapat-aç ile korunur', () {
      GameState s = hayat(age: 20);
      s = MilitaryService.enlist(s, MilitaryTrack.er, Random(1)).state;
      final GameState geri = decodeGameState(encodeGameState(s));
      expect(geri.military.status, s.military.status);
      expect(geri.military.trackName, s.military.trackName);
      expect(geri.military.rankId, s.military.rankId);
      expect(geri.military.startedAtAge, s.military.startedAtAge);
    });

    test('eski kayıtta askerlik yapılmamış sayılır', () {
      final GameState s = hayat(age: 30);
      final Map<String, Object?> body =
          Map<String, Object?>.from(encodeGameState(s))..remove('military');
      final GameState geri = decodeGameState(body);
      expect(geri.military.status, MilitaryStatus.yok);
      expect(geri.military.trackName, isNull);
    });

    test('yaş alırken celp gelir ve hizmet ilerler', () {
      GameState s = hayat(age: 19);
      s = LifeProgression(Random(3)).advanceOneYear(s);
      if (s.deceased) return;
      expect(s.military.status, MilitaryStatus.cagrildi);

      s = MilitaryService.enlist(
        s.copyWith(pendingEvent: null),
        MilitaryTrack.er,
        Random(1),
      ).state;
      expect(s.military.isServing, isTrue);

      s = LifeProgression(Random(4)).advanceOneYear(s);
      if (s.deceased) return;
      expect(s.military.status, MilitaryStatus.tamamlandi);
    });
  });
}
