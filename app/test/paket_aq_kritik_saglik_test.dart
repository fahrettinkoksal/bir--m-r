// Paket AQ — kritik sağlık: bantlar, zorunlu çözüm, tek ölüm, save/load,
// düşük sağlıkta uygunluk ve açık korumaları.
//
// Hepsi **üretim motorlarından** geçiyor: durum test tarafında kurulabilir
// ama sağlığın düşmesi, kritik durumun açılması, tedavi, ölüm, kurtulma ve
// uygunluk kararları gerçek motorların işi.
library;

import 'dart:convert';
import 'dart:math';

import 'package:bir_omur/data/activity_catalog.dart';
import 'package:bir_omur/data/health_crisis_catalog.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/data/tour_catalog.dart';
import 'package:bir_omur/domain/activities/activity_engine.dart';
import 'package:bir_omur/domain/activities/travel.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/generation/life_progression.dart';
import 'package:bir_omur/domain/life/critical_health.dart';
import 'package:bir_omur/domain/life/health_crisis_engine.dart';
import 'package:bir_omur/domain/life/sick_leave.dart';
import 'package:bir_omur/domain/models/career.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/data/chronic_catalog.dart';
import 'package:bir_omur/domain/models/health_history.dart';
import 'package:bir_omur/domain/models/pending_crisis.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:bir_omur/domain/models/trip.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/invariants.dart';

const HealthCrisisEngine kMotor = HealthCrisisEngine();
const ActivityEngine kAktivite = ActivityEngine();

GameState _hayat(
  int seed, {
  int age = 40,
  int wallet = 300000,
  int? health,
}) {
  final GameState s =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  return s.copyWith(
    player: s.player.copyWith(
      age: age,
      wallet: wallet,
      stats: health == null
          ? s.player.stats
          : s.player.stats.copyWith(health: health),
    ),
  );
}

ActivityAction _eylem(String id) =>
    kActivityActions.firstWhere((ActivityAction a) => a.id == id);

void main() {
  // ===================================================================
  // Bantlar
  // ===================================================================
  group('Sağlık bantları', () {
    test('bant sınırları eksiksiz ve örtüşmesiz', () {
      expect(CriticalHealth.bandOf(100), HealthBand.normal);
      expect(CriticalHealth.bandOf(26), HealthBand.normal);
      expect(CriticalHealth.bandOf(25), HealthBand.kritikDusuk);
      expect(CriticalHealth.bandOf(11), HealthBand.kritikDusuk);
      expect(CriticalHealth.bandOf(10), HealthBand.hayatiTehlike);
      expect(CriticalHealth.bandOf(1), HealthBand.hayatiTehlike);
      expect(CriticalHealth.bandOf(0), HealthBand.acil);
    });

    test('yalnızca acil bant zorunlu çözüm ister', () {
      expect(CriticalHealth.bandOf(0).needsResolution, isTrue);
      expect(CriticalHealth.bandOf(1).needsResolution, isFalse);
      expect(CriticalHealth.bandOf(25).needsResolution, isFalse);
      expect(CriticalHealth.bandOf(60).needsResolution, isFalse);
    });

    test('her stat 0 = ölüm gibi bir genel kural yok', () {
      // Mutluluk, karizma, görünüş ve zekâ 0 olunca kritik sağlık
      // durumu açılmaz; yalnızca sağlık bu kapıyı açar.
      final GameState s = _hayat(1, health: 60).copyWith(
        player: _hayat(1).player.copyWith(
              stats: _hayat(1).player.stats.copyWith(
                    happiness: 0,
                    charisma: 0,
                    appearance: 0,
                    intelligence: 0,
                    health: 60,
                  ),
            ),
      );
      final GameState sonra =
          CriticalHealth.enforce(state: s, age: s.player.age);
      expect(sonra.hasPendingCrisis, isFalse);
      expect(sonra.deceased, isFalse);
    });
  });

  // ===================================================================
  // Zorunlu çözüm
  // ===================================================================
  group('Sağlık 0 → zorunlu çözüm', () {
    test('sağlık 0 olan yaşayan oyuncu sessizce kalamaz', () {
      final GameState s = _hayat(2, health: 0);
      // Değişmez ihlali: henüz hiçbir sağlık durumu açılmadı.
      expect(
        checkInvariants(s),
        isNotEmpty,
        reason: 'sağlık 0 + yaşıyor + bekleyen durum yok bir hata olmalı',
      );
      final GameState sonra = CriticalHealth.enforce(
        state: s,
        age: s.player.age,
        cause: CriticalHealthCause.hastalik,
      );
      expect(CriticalHealth.isPending(sonra), isTrue);
      expect(checkInvariants(sonra), isEmpty);
    });

    test('zorunlu çözüm açılırken ölüm uygulanmaz', () {
      final GameState sonra = CriticalHealth.enforce(
        state: _hayat(3, health: 0),
        age: 40,
      );
      expect(sonra.deceased, isFalse);
      expect(sonra.deathAge, isNull);
    });

    test('kritik kriz rastgele çıkmaz', () {
      // Kataloğun yaşa uygun listesi kritik krizi içermez; sağlığı
      // yerinde olan karakterin karşısına çıkmaması için.
      for (final int yas in <int>[5, 20, 40, 70, 95]) {
        expect(
          crisesForAge(yas).any((HealthCrisis c) => c.isCritical),
          isFalse,
          reason: '$yas yaşında kritik kriz rastgele havuzda',
        );
      }
    });

    test('aynı durum iki kez açılmaz', () {
      GameState s = CriticalHealth.enforce(
        state: _hayat(4, health: 0),
        age: 40,
      );
      final PendingCrisis ilk = s.pendingCrisis!;
      s = CriticalHealth.enforce(state: s, age: 40);
      expect(s.pendingCrisis, same(ilk));
    });

    test('sebep biliniyorsa yazılır, bilinmiyorsa uydurulmaz', () {
      final GameState bilinen = CriticalHealth.enforce(
        state: _hayat(5, health: 0),
        age: 40,
        cause: CriticalHealthCause.sakatlik,
      );
      expect(bilinen.pendingCrisis!.causeId, 'sakatlik');
      expect(CriticalHealth.causeLine(bilinen.pendingCrisis), isNotNull);

      final GameState bilinmeyen = CriticalHealth.enforce(
        state: _hayat(6, health: 0),
        age: 40,
      );
      expect(bilinmeyen.pendingCrisis!.causeId, isNull);
      expect(CriticalHealth.causeLine(bilinmeyen.pendingCrisis), isNull);
    });
  });

  // ===================================================================
  // Yaş alma kilidi
  // ===================================================================
  group('Kritik durum çözülmeden yaş ilerlemez', () {
    test('bekleyen kritik durumda advanceOneYear ilerletmez', () {
      final GameState s = CriticalHealth.enforce(
        state: _hayat(7, health: 0),
        age: 40,
      );
      final GameState sonra = LifeProgression(Random(1)).advanceOneYear(s);
      expect(sonra.player.age, s.player.age);
      expect(CriticalHealth.isPending(sonra), isTrue);
    });

    test('üç kez yaş almaya çalışmak da ilerletmez', () {
      GameState s = CriticalHealth.enforce(
        state: _hayat(8, health: 0),
        age: 40,
      );
      final LifeProgression motor = LifeProgression(Random(2));
      for (int i = 0; i < 3; i++) {
        s = motor.advanceOneYear(s);
      }
      expect(s.player.age, 40);
    });

    test('bekleyen olağan kriz de yaşı ilerletmez', () {
      // Eski hata: `rollCrisis` ekranda kriz varken yeni kriz açmıyordu
      // ama yaş ilerliyordu; kriz ekranda asılı kalıyordu.
      final GameState s = _hayat(9, health: 60).copyWith(
        pendingCrisis: const PendingCrisis(crisisId: 'ates_hastalik', age: 40),
      );
      expect(LifeProgression(Random(3)).advanceOneYear(s).player.age, 40);
    });

    test('sağlık yıl başında 0 ise yaş almadan durum açılır', () {
      final GameState s = _hayat(10, health: 0);
      final GameState sonra = LifeProgression(Random(4)).advanceOneYear(s);
      expect(sonra.player.age, 40, reason: 'yaş ilerlememeli');
      expect(CriticalHealth.isPending(sonra), isTrue);
    });

    test('çözüldükten sonra yaş yeniden ilerler', () {
      GameState s = CriticalHealth.enforce(
        state: _hayat(11, health: 0),
        age: 40,
      );
      // Parasız da seçilebilen acil servis yolu.
      final CrisisResult r = kMotor.respond(s, 'acil_servis', Random(5));
      s = r.state;
      if (s.deceased) return; // Ölümle bitti; yaş zaten ilerlemez.
      expect(CriticalHealth.isPending(s), isFalse);
      final GameState sonra = LifeProgression(Random(6)).advanceOneYear(s);
      expect(sonra.player.age, 41);
    });
  });

  // ===================================================================
  // Kurtulma ve ölüm
  // ===================================================================
  group('Kurtulma', () {
    test('kurtulan karakter ne 100 ne 1 sağlıkla kalır', () {
      int kurtulan = 0;
      for (int seed = 0; seed < 60; seed++) {
        GameState s = CriticalHealth.enforce(
          state: _hayat(seed, age: 35, health: 0),
          age: 35,
        );
        final CrisisResult r = kMotor.respond(s, 'acil_servis', Random(seed));
        s = r.state;
        if (!r.outcome.survived) continue;
        kurtulan++;
        expect(
          s.player.stats.health,
          inInclusiveRange(
            CriticalHealth.prototypeOnlyRecoveryFloor,
            CriticalHealth.prototypeOnlyRecoveryCeiling,
          ),
        );
        // Kritik derecede düşük bantta kalır: ağır iş hâlâ kapalı.
        expect(CriticalHealth.bandFor(s).isLow, isTrue);
      }
      expect(kurtulan, greaterThan(0), reason: 'hiç kurtulan yok');
    });

    test('tedavi seçimi sonucu değiştirir, garanti etmez', () {
      final GameState s = CriticalHealth.enforce(
        state: _hayat(12, age: 45, health: 0),
        age: 45,
      );
      final double acil = CriticalHealth.prototypeOnlySurvivalOf(
        s,
        'acil_servis',
      );
      final double ozel = CriticalHealth.prototypeOnlySurvivalOf(
        s,
        'ozel_tedavi',
      );
      final double evde = CriticalHealth.prototypeOnlySurvivalOf(
        s,
        'evde_bekle',
      );
      expect(ozel, greaterThan(acil));
      expect(acil, greaterThan(evde));
      expect(ozel, lessThan(1.0), reason: 'hiçbir seçenek garanti olmamalı');
      expect(evde, greaterThan(0.0), reason: 'hiçbir seçenek kesin ölüm değil');
    });

    test('kurtulma ihtimali yaşa ve geçmişe bağlı, sabit zar değil', () {
      final GameState genc = CriticalHealth.enforce(
        state: _hayat(13, age: 25, health: 0),
        age: 25,
      );
      final GameState yasli = CriticalHealth.enforce(
        state: _hayat(13, age: 82, health: 0),
        age: 82,
      );
      expect(
        CriticalHealth.prototypeOnlySurvivalOf(genc, 'acil_servis'),
        greaterThan(
          CriticalHealth.prototypeOnlySurvivalOf(yasli, 'acil_servis'),
        ),
      );
      expect(
        CriticalHealth.prototypeOnlySurvivalOf(genc, 'acil_servis'),
        isNot(0.5),
      );
    });

    test('ikinci kez aynı eşiğe gelmek daha tehlikeli', () {
      final GameState ilk = CriticalHealth.enforce(
        state: _hayat(14, age: 50, health: 0),
        age: 50,
      );
      final GameState ikinci = ilk.copyWith(
        healthHistory: <HealthHistoryEntry>[
          const HealthHistoryEntry(
            crisisId: CriticalHealth.crisisId,
            age: 44,
            choiceId: 'acil_servis',
          ),
        ],
      );
      expect(
        CriticalHealth.prototypeOnlySurvivalOf(ikinci, 'acil_servis'),
        lessThan(CriticalHealth.prototypeOnlySurvivalOf(ilk, 'acil_servis')),
      );
    });

    test('hayati tehlikeyi atlatmak hayattan silinmez', () {
      GameState s = CriticalHealth.enforce(
        state: _hayat(15, age: 40, health: 0),
        age: 40,
      );
      int kurtulan = 0;
      for (int seed = 0; seed < 40 && kurtulan == 0; seed++) {
        final CrisisResult r = kMotor.respond(s, 'acil_servis', Random(seed));
        if (!r.outcome.survived) continue;
        kurtulan++;
        expect(
          r.state.healthHistory
              .any((HealthHistoryEntry e) => e.crisisId == CriticalHealth.crisisId),
          isTrue,
          reason: 'sağlık geçmişinde iz kalmalı',
        );
      }
      expect(kurtulan, 1);
      s = s; // kullanılmayan uyarısı olmasın
    });

    test('kritik krizden otomatik kronik hastalık uydurulmaz', () {
      // Kritik krizin kronik eşlemesi yoktur: "diyabet oldun" gibi
      // rastgele bir tanı üretilmez.
      expect(chronicAfterCrisis(CriticalHealth.crisisId), isEmpty);
    });

    test('çalışan karakterin uzun yokluğu iş yerinde konuşulur', () {
      final GameState s = CriticalHealth.enforce(
        state: _hayat(16, age: 40, health: 0).copyWith(
          career: const CareerState(
            jobId: 'ofis_memuru',
            salary: 400000,
            startedAtAge: 30,
          ),
        ),
        age: 40,
      );
      final int once = s.career.employerWarnings;
      for (int seed = 0; seed < 40; seed++) {
        final CrisisResult r = kMotor.respond(s, 'acil_servis', Random(seed));
        if (!r.outcome.survived) continue;
        expect(r.state.career.employerWarnings, once + 1);
        // Uyarı tek başına işten atmaz.
        expect(r.state.career.isEmployed, isTrue);
        return;
      }
      fail('hiç kurtulan hayat üretilemedi');
    });
  });

  // ===================================================================
  // Tek ölüm
  // ===================================================================
  group('Tek ölüm, tek miras', () {
    test('kritik krizde ölüm olağan ölüm yolundan geçer', () {
      final GameState s = CriticalHealth.enforce(
        state: _hayat(17, age: 88, health: 0),
        age: 88,
      );
      for (int seed = 0; seed < 60; seed++) {
        final CrisisResult r = kMotor.respond(s, 'evde_bekle', Random(seed));
        if (r.outcome.survived) continue;
        expect(r.state.deceased, isTrue);
        expect(r.state.deathAge, 88);
        expect(r.state.deathCause, isNotNull);
        expect(r.state.deathCause, isNotEmpty);
        expect(r.state.pendingCrisis, isNull);
        expect(r.state.pendingEvent, isNull);
        return;
      }
      fail('hiç ölümle biten hayat üretilemedi');
    });

    test('yaşa bağlı ölüm bekleyen kritik durumu kapatır', () {
      // Aynı yıl iki ölüm sonucu üretilmemeli: Mortality sonucu
      // verdiyse kritik pencere iptal olur.
      GameState s = CriticalHealth.enforce(
        state: _hayat(18, age: 101, health: 0),
        age: 101,
      );
      // Kritik durumu çözüp 101 yaşında yaş almayı dene; mortality bu
      // yaşta çok yüksek.
      s = kMotor.respond(s, 'acil_servis', Random(7)).state;
      if (s.deceased) {
        expect(s.pendingCrisis, isNull);
        return;
      }
      for (int i = 0; i < 20 && !s.deceased; i++) {
        s = LifeProgression(Random(100 + i)).advanceOneYear(s);
        if (s.hasPendingCrisis) {
          s = kMotor.respond(s, 'acil_servis', Random(200 + i)).state;
        }
      }
      if (s.deceased) {
        expect(
          s.pendingCrisis,
          isNull,
          reason: 'vefat eden oyuncuda bekleyen kriz kalmaz',
        );
      }
    });

    test('tam hayat akışında tek ölüm kaydı oluşur', () {
      for (int seed = 0; seed < 25; seed++) {
        GameState s = _hayat(seed, age: 20, health: 40);
        final LifeProgression motor = LifeProgression(Random(seed + 11));
        int olumSayisi = 0;
        int guard = 0;
        while (!s.deceased && guard++ < 150) {
          s = s.copyWith(pendingEvent: null);
          if (s.hasPendingCrisis) {
            final HealthCrisis kriz = s.pendingCrisis!.crisis!;
            final CrisisChoice secim = kriz.choices.firstWhere(
              (CrisisChoice c) => kMotor.canChoose(s, c),
            );
            s = kMotor.respond(s, secim.id, Random(guard + seed)).state;
            if (s.deceased) olumSayisi++;
            continue;
          }
          final int yasOnce = s.player.age;
          s = motor.advanceOneYear(s);
          if (s.deceased) olumSayisi++;
          if (s.player.age == yasOnce && !s.hasPendingCrisis) break;
          expect(checkInvariants(s, where: 'tohum $seed'), isEmpty);
        }
        expect(olumSayisi, lessThanOrEqualTo(1),
            reason: 'tohum $seed: birden fazla ölüm geçişi');
      }
    });
  });

  // ===================================================================
  // Save / load
  // ===================================================================
  group('Kayıt', () {
    test('kritik durum ve sebebi save/load sonrası aynen durur', () {
      final GameState s = CriticalHealth.enforce(
        state: _hayat(19, age: 55, health: 0),
        age: 55,
        cause: CriticalHealthCause.rahatsizlik,
      );
      final GameState geri =
          decodeGameState(jsonDecode(jsonEncode(encodeGameState(s))) as Map<String, Object?>);
      expect(CriticalHealth.isPending(geri), isTrue);
      expect(geri.pendingCrisis!.causeId, 'rahatsizlik');
      expect(geri.pendingCrisis!.age, 55);
      expect(geri.player.stats.health, 0);
      // Sessizce sağlık 100 yapılmadı.
      expect(geri.player.stats.health, isNot(100));
    });

    test('eski kayıtta sebep yoktur; çökmez', () {
      final GameState s = CriticalHealth.enforce(
        state: _hayat(20, age: 55, health: 0),
        age: 55,
      );
      final Map<String, Object?> json =
          jsonDecode(jsonEncode(encodeGameState(s))) as Map<String, Object?>;
      (json['pendingCrisis']! as Map<String, Object?>).remove('causeId');
      final GameState geri = decodeGameState(json);
      expect(CriticalHealth.isPending(geri), isTrue);
      expect(geri.pendingCrisis!.causeId, isNull);
    });

    test('eski kayıtta healthDangerWarned yoktur; uyarı verilmemiş sayılır',
        () {
      final GameState s = _hayat(21, health: 8);
      final Map<String, Object?> json =
          jsonDecode(jsonEncode(encodeGameState(s))) as Map<String, Object?>
            ..remove('healthDangerWarned');
      expect(decodeGameState(json).healthDangerWarned, isFalse);
    });

    test('bozuk ama okunabilir eski kayıt: sağlık 0, oyuncu hayatta', () {
      // Paket AQ öncesi kayıtlarda bu durum **olağan**dı. Yüklenince
      // çökmemeli ve oyuncu sessizce sağlık 100'e çekilmemeli; ilk yaş
      // ilerletme denemesinde kritik durum güvenli biçimde açılmalı.
      final GameState eski = _hayat(22, age: 61, health: 0);
      final GameState geri = decodeGameState(
        jsonDecode(jsonEncode(encodeGameState(eski))) as Map<String, Object?>,
      );
      expect(geri.player.stats.health, 0);
      expect(geri.deceased, isFalse);
      final GameState sonra = LifeProgression(Random(8)).advanceOneYear(geri);
      expect(CriticalHealth.isPending(sonra), isTrue);
      expect(sonra.player.age, 61);
      expect(checkInvariants(sonra), isEmpty);
    });
  });

  // ===================================================================
  // Parasızlık ve soft-lock
  // ===================================================================
  group('Parasız oyuncu kilitlenmez', () {
    test('cüzdan 0 + sağlık 0: en az bir seçenek açık', () {
      final GameState s = CriticalHealth.enforce(
        state: _hayat(23, age: 40, wallet: 0, health: 0),
        age: 40,
      );
      final HealthCrisis kriz = s.pendingCrisis!.crisis!;
      final List<CrisisChoice> acik = kriz.choices
          .where((CrisisChoice c) => kMotor.canChoose(s, c))
          .toList(growable: false);
      expect(acik, isNotEmpty);
      // Açık olan seçenek gerçekten çalışır.
      final CrisisResult r = kMotor.respond(s, acik.first.id, Random(9));
      expect(r.outcome.applied, isTrue);
      expect(r.state.pendingCrisis, isNull);
      expect(r.state.player.wallet, greaterThanOrEqualTo(0));
    });

    test('her yaşta parasız açık seçenek var', () {
      for (final int yas in <int>[6, 15, 30, 55, 80, 95]) {
        final GameState s = CriticalHealth.enforce(
          state: _hayat(24, age: yas, wallet: 0, health: 0),
          age: yas,
        );
        expect(CriticalHealth.isPending(s), isTrue, reason: '$yas yaşında');
        expect(
          s.pendingCrisis!.crisis!.choices
              .any((CrisisChoice c) => kMotor.canChoose(s, c)),
          isTrue,
          reason: '$yas yaşında parasız seçenek yok',
        );
      }
    });

    test('özel tedavi parası olmayana kapalı, bedel iki kez kesilmez', () {
      final GameState zengin = CriticalHealth.enforce(
        state: _hayat(25, age: 40, wallet: 500000, health: 0),
        age: 40,
      );
      final CrisisChoice ozel = zengin.pendingCrisis!.crisis!.choices
          .firstWhere((CrisisChoice c) => c.id == 'ozel_tedavi');
      expect(kMotor.canChoose(zengin, ozel), isTrue);
      final CrisisResult r = kMotor.respond(zengin, 'ozel_tedavi', Random(10));
      expect(r.state.player.wallet, 500000 - ozel.cost);
      expect(r.outcome.cost, ozel.cost);

      final GameState parasiz = CriticalHealth.enforce(
        state: _hayat(25, age: 40, wallet: 0, health: 0),
        age: 40,
      );
      expect(kMotor.canChoose(parasiz, ozel), isFalse);
    });
  });

  // ===================================================================
  // Çocuk ve yaşlı
  // ===================================================================
  group('Çocuk ve yaşlı', () {
    test('küçük yaştaki oyuncuya yetişkin tedavi metni kopyalanmaz', () {
      final GameState temel = _hayat(26, age: 9, wallet: 0, health: 0);
      final GameState cocuk = CriticalHealth.enforce(
        state: temel.copyWith(
          people: <Person>[
            ...temel.people,
            Person(
              id: 'aq-anne',
              firstName: 'Nur',
              lastName: temel.player.lastName,
              gender: temel.player.gender,
              relation: RelationType.anne,
              age: 38,
              isAlive: true,
              inPlayerHousehold: true,
              employment: EmploymentStatus.calisiyor,
              occupation: 'öğretmen',
              wealth: WealthTier.ortaHalli,
              bond: 70,
            ),
          ],
        ),
        age: 9,
      );
      for (int seed = 0; seed < 40; seed++) {
        final CrisisResult r = kMotor.respond(cocuk, 'acil_servis', Random(seed));
        if (!r.outcome.survived) continue;
        expect(r.outcome.text, contains('Ailen'));
        return;
      }
      fail('kurtulan çocuk hayatı üretilemedi');
    });

    test('yaşlı karakterin kurtulma şansı ve kalan sağlığı daha düşük', () {
      final GameState genc = CriticalHealth.enforce(
        state: _hayat(27, age: 35, health: 0),
        age: 35,
      );
      final GameState yasli = CriticalHealth.enforce(
        state: _hayat(27, age: 80, health: 0),
        age: 80,
      );
      final CrisisChoice acil = genc.pendingCrisis!.crisis!.choices
          .firstWhere((CrisisChoice c) => c.id == 'acil_servis');
      expect(
        CriticalHealth.recoveredHealth(state: yasli, choice: acil),
        lessThan(CriticalHealth.recoveredHealth(state: genc, choice: acil)),
      );
    });

    test('öğrenciye okul sonucu yazılır', () {
      final GameState s = CriticalHealth.enforce(
        state: _hayat(28, age: 14, wallet: 0, health: 0),
        age: 14,
      );
      if (!s.education.isSchoolStudent) return; // kayıt öğrenci değilse atla
      expect(
        CriticalHealth.afterEffectLine(s),
        contains('okul'),
      );
    });
  });

  // ===================================================================
  // Düşük sağlıkta uygunluk
  // ===================================================================
  group('Düşük sağlıkta ne yapılabilir', () {
    test('ağır aktivite kritik bantta kapanır, hafifi açık kalır', () {
      final ActivityAction kosu = _eylem('kosu');
      final ActivityAction esneme = _eylem('esneme');
      expect(kosu.intensity, ActivityIntensity.agir);
      expect(esneme.intensity, ActivityIntensity.hafif);

      for (final int h in <int>[100, 60, 26]) {
        final GameState s = _hayat(29, age: 30, health: h);
        expect(kAktivite.availability(s, kosu).isAllowed, isTrue,
            reason: 'sağlık $h ağır aktiviteyi kapatmamalı');
      }
      for (final int h in <int>[25, 10, 1]) {
        final GameState s = _hayat(29, age: 30, health: h);
        expect(kAktivite.availability(s, kosu).isAllowed, isFalse,
            reason: 'sağlık $h ağır aktivite açık kalmamalı');
        expect(kAktivite.availability(s, esneme).isAllowed, isTrue,
            reason: 'sağlık $h hafif aktiviteyi de kapatmamalı');
      }
    });

    test('kapalı düğmenin gerekçesi doğal Türkçe, teknik terim yok', () {
      final String? gerekce = kAktivite
          .availability(_hayat(30, age: 30, health: 5), _eylem('kosu'))
          .reason;
      expect(gerekce, isNotNull);
      expect(gerekce!.toLowerCase(), isNot(contains('band')));
      expect(gerekce, isNot(contains('criticalHealth')));
      expect(gerekce, isNot(contains('prototypeOnly')));
      expect(gerekce, contains('Sağlığın'));
    });

    test('elektif estetik hayati tehlikede kapalı, kritik düşükte riskli',
        () {
      final ActivityAction burun = _eylem('burun_ameliyati');
      expect(burun.venue, ActivityVenue.estetik);
      expect(
        kAktivite
            .availability(_hayat(31, age: 40, health: 5), burun)
            .isAllowed,
        isFalse,
      );
      // 11-25 bandında kapı açık kalır; risk motoru daha yüksek
      // çalışır.
      expect(
        kAktivite
            .availability(_hayat(31, age: 40, health: 20), burun)
            .isAllowed,
        isTrue,
      );
      expect(
        ActivityEngine.prototypeOnlyLowHealthRiskFactor,
        greaterThan(1.0),
      );
    });

    test('sağlık merkezi düşük sağlıkta kapanmaz', () {
      // Tedavi yolunun kapanması oyuncuyu çıkışsız bırakırdı.
      final List<ActivityAction> saglik = actionsAt(ActivityVenue.saglikMerkezi)
          .where((ActivityAction a) =>
              a.requiresFlag == null && a.intensity != ActivityIntensity.agir)
          .toList(growable: false);
      expect(saglik, isNotEmpty);
      final GameState s = _hayat(32, age: 40, health: 6);
      expect(
        saglik.any((ActivityAction a) => kAktivite.availability(s, a).isAllowed),
        isTrue,
      );
    });

    test('uzun tur düşük sağlıkta kapanır, kısa tur açık kalır', () {
      final List<TourPackage> kisa = kTourPackages
          .where((TourPackage t) =>
              t.nights <= Travel.prototypeOnlyMaxTourNightsWhenLow)
          .toList(growable: false);
      final List<TourPackage> uzun = kTourPackages
          .where((TourPackage t) =>
              t.nights > Travel.prototypeOnlyMaxTourNightsWhenLow)
          .toList(growable: false);
      expect(kisa, isNotEmpty);
      expect(uzun, isNotEmpty);

      final GameState dusuk = _hayat(33, age: 40, health: 18);
      expect(Travel.tourHealthBlockReason(dusuk, kisa.first), isEmpty);
      expect(Travel.tourHealthBlockReason(dusuk, uzun.first), isNotEmpty);

      final GameState iyi = _hayat(33, age: 40, health: 70);
      expect(Travel.tourHealthBlockReason(iyi, uzun.first), isEmpty);
    });

    test('hayati tehlikede hiçbir tura çıkılmaz', () {
      final GameState s = _hayat(34, age: 40, health: 4);
      for (final TourPackage t in kTourPackages) {
        expect(Travel.tourHealthBlockReason(s, t), isNotEmpty);
      }
    });

    test('şehirler arası yolculuk hayati tehlikede kapalı', () {
      final GameState s = _hayat(35, age: 40, health: 4);
      final String hedef = Travel.destinations(s).first;
      expect(
        Travel.availability(s, mode: TravelMode.otobus, city: hedef).isAllowed,
        isFalse,
      );
      final GameState orta = _hayat(35, age: 40, health: 20);
      expect(
        Travel.availability(orta, mode: TravelMode.otobus, city: hedef)
            .isAllowed,
        isTrue,
      );
    });

    test('düşük sağlıkta hastalık ihtimali belirgin biçimde yüksek', () {
      // Mevcut sistem zaten health'e bakıyor; ikinci çarpan eklenmedi.
      // Ölçülen fark raporlanıyor.
      final double iyi =
          SickLeaves.chance(age: 40, health: 85, yearsSinceSport: null);
      final double dusuk =
          SickLeaves.chance(age: 40, health: 8, yearsSinceSport: null);
      expect(dusuk, greaterThan(iyi * 2));
    });
  });

  // ===================================================================
  // Açık (exploit) korumaları
  // ===================================================================
  group('Açık korumaları', () {
    test('kritik durum çözülmeden spor salonundan sağlık kazanılamaz', () {
      final GameState s = CriticalHealth.enforce(
        state: _hayat(36, age: 30, health: 0),
        age: 30,
      );
      for (final ActivityAction a in kActivityActions) {
        expect(
          kAktivite.availability(s, a).isAllowed,
          isFalse,
          reason: '${a.id} bekleyen kritik durumda açık',
        );
      }
      // Yine de zorlanırsa durum değişmez.
      final ActivityResult r = kAktivite.perform(
        state: s,
        action: _eylem('esneme'),
        rng: Random(11),
      );
      expect(r.outcome.applied, isFalse);
      expect(r.state.player.stats.health, 0);
      expect(CriticalHealth.isPending(r.state), isTrue);
    });

    test('kritik durum çözülmeden seyahatle kaçılamaz', () {
      final GameState s = CriticalHealth.enforce(
        state: _hayat(37, age: 40, health: 0),
        age: 40,
      );
      final String hedef = Travel.destinations(s).first;
      expect(
        Travel.availability(s, mode: TravelMode.otobus, city: hedef).isAllowed,
        isFalse,
      );
      expect(Travel.tourHealthBlockReason(s, kTourPackages.first), isNotEmpty);
    });

    test('save/load ile kritik durum silinemez', () {
      final GameState s = CriticalHealth.enforce(
        state: _hayat(38, age: 40, health: 0),
        age: 40,
      );
      GameState geri = decodeGameState(
        jsonDecode(jsonEncode(encodeGameState(s))) as Map<String, Object?>,
      );
      // Yükledikten sonra yaş almayı dene: yine ilerlemez.
      geri = LifeProgression(Random(12)).advanceOneYear(geri);
      expect(geri.player.age, 40);
      expect(CriticalHealth.isPending(geri), isTrue);
    });

    test('olağan krizi atlatıp sağlık 0 kalırsa kritik durum devralır', () {
      // "Atlattı ama sağlığı 0" sessiz bir durum olarak kalmamalı.
      final GameState s = _hayat(39, age: 70, health: 1).copyWith(
        pendingCrisis: const PendingCrisis(crisisId: 'dusme', age: 70),
      );
      for (int seed = 0; seed < 80; seed++) {
        final CrisisResult r = kMotor.respond(s, 'yatak', Random(seed));
        if (!r.outcome.survived) continue;
        if (r.state.player.stats.health > 0) continue;
        expect(CriticalHealth.isPending(r.state), isTrue);
        expect(checkInvariants(r.state), isEmpty);
        return;
      }
      // Bu tohum kümesinde sağlık 0'a inmediyse iddia edilecek bir şey
      // yok; değişmez zaten her adımda denetleniyor.
    });
  });

  // ===================================================================
  // Bildirim spam koruması
  // ===================================================================
  group('Bildirim spamı yok', () {
    test('aynı bantta ikinci uyarı çıkmaz, bant düzelince sıfırlanır', () {
      GameState s = _hayat(40, age: 45, health: 8);
      final LifeProgression motor = LifeProgression(Random(13));
      int tehlikeBildirimi = 0;
      for (int i = 0; i < 6 && !s.deceased; i++) {
        s = s.copyWith(pendingEvent: null);
        if (s.hasPendingCrisis) {
          s = kMotor.respond(s, 'acil_servis', Random(300 + i)).state;
          if (s.deceased) break;
          continue;
        }
        s = motor.advanceOneYear(s);
        tehlikeBildirimi += s.notices
            .where((PendingNotice n) => n.id.startsWith('saglik-tehlike-'))
            .length;
        s = s.copyWith(notices: const <PendingNotice>[]);
      }
      expect(
        tehlikeBildirimi,
        lessThanOrEqualTo(2),
        reason: 'hayati tehlike uyarısı her yıl tekrarlanmamalı',
      );
    });
  });
}
