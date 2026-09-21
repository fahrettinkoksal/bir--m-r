import 'dart:math';

import 'package:bir_omur/data/activity_catalog.dart';
import 'package:bir_omur/data/fortune_catalog.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/domain/activities/activity_engine.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/generation/life_progression.dart';
import 'package:bir_omur/domain/life/astrology.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:bir_omur/domain/models/zodiac.dart';
import 'package:flutter_test/flutter_test.dart';

const ActivityEngine motor = ActivityEngine();

GameState yetiskin({int seed = 5, int age = 30, int wallet = 50000}) {
  final GameState base =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  return base.copyWith(
    pendingEvent: null,
    player: base.player.copyWith(age: age, wallet: wallet),
  );
}

ActivityAction eylem(String id) =>
    kActivityActions.firstWhere((ActivityAction a) => a.id == id);

void main() {
  group('Burç doğum ayı ve gününden gelir', () {
    test('yılın her günü bir burca düşer, boşluk yok', () {
      int toplam = 0;
      for (int ay = 1; ay <= 12; ay++) {
        for (int gun = 1; gun <= BirthDate.daysInMonth(ay); gun++) {
          expect(zodiacFor(ay, gun), isA<Zodiac>());
          toplam++;
        }
      }
      expect(toplam, 365, reason: 'Şubat 28 gün; artık yıl yok (D-003)');
    });

    test('sınır günleri doğru burca düşer', () {
      expect(zodiacFor(3, 20), Zodiac.balik);
      expect(zodiacFor(3, 21), Zodiac.koc);
      expect(zodiacFor(12, 21), Zodiac.yay);
      expect(zodiacFor(12, 22), Zodiac.oglak);
      expect(zodiacFor(1, 19), Zodiac.oglak);
      expect(zodiacFor(1, 20), Zodiac.kova);
    });

    test('her burcun bir elementi var ve dört element de kullanılıyor', () {
      final Set<String> elementler =
          Zodiac.values.map((Zodiac z) => z.element).toSet();
      expect(elementler, <String>{'ateş', 'toprak', 'hava', 'su'});
      for (final String e in elementler) {
        expect(
          Zodiac.values.where((Zodiac z) => z.element == e).length,
          3,
          reason: 'Her elementte üç burç olmalı',
        );
      }
    });

    test('hayat üretilirken doğum ayı ve günü belirlenir', () {
      for (int seed = 0; seed < 30; seed++) {
        final GameState s = yetiskin(seed: seed);
        final BirthDate? d = s.player.birthDate;
        expect(d, isNotNull);
        expect(d!.month, inInclusiveRange(1, 12));
        expect(d.day, inInclusiveRange(1, BirthDate.daysInMonth(d.month)));
      }
    });

    test('doğum tarihi kayda girer ve kapat-aç ile değişmez', () {
      final GameState s = yetiskin();
      final GameState geri = decodeGameState(encodeGameState(s));
      expect(geri.player.birthDate!.month, s.player.birthDate!.month);
      expect(geri.player.birthDate!.day, s.player.birthDate!.day);
      expect(Astrology.zodiacOf(geri), Astrology.zodiacOf(s));
    });

    test('eski kayıtta burç tohumdan türetilir ve hep aynı çıkar', () {
      // Geriye dönük uydurma bir tarih **yazılmaz**; türetme
      // deterministiktir, yani aynı hayat her açılışta aynı burcu görür.
      final GameState s = yetiskin(seed: 12);
      final Map<String, Object?> body =
          Map<String, Object?>.from(encodeGameState(s));
      final Map<String, Object?> oyuncu =
          Map<String, Object?>.from(body['player']! as Map<String, Object?>)
            ..remove('birthMonth')
            ..remove('birthDay');
      body['player'] = oyuncu;

      final GameState a = decodeGameState(body);
      final GameState b = decodeGameState(body);
      expect(a.player.birthDate, isNull);
      expect(Astrology.zodiacOf(a), Astrology.zodiacOf(b));
      expect(Astrology.birthDateOf(a).month,
          Astrology.birthDateOf(b).month);
    });

    test('farklı hayatlar farklı burçlar alır', () {
      final Set<Zodiac> burclar = <Zodiac>{};
      for (int seed = 0; seed < 60; seed++) {
        burclar.add(Astrology.zodiacOf(yetiskin(seed: seed)));
      }
      expect(burclar.length, greaterThan(4),
          reason: 'Burçlar tek bir değere sıkışmamalı');
    });

    test('kişinin burcu kalıcı kimliğinden gelir ve değişmez', () {
      final GameState s = yetiskin();
      for (final dynamic p in s.people) {
        final Zodiac ilk = Astrology.zodiacOfPerson(p);
        final Zodiac ikinci = Astrology.zodiacOfPerson(p);
        expect(ilk, ikinci);
      }
    });
  });

  group('Fal ve tarot', () {
    test('menüde üç eylem var ve biri ücretsiz', () {
      final List<ActivityAction> fal = kActivityActions
          .where((ActivityAction a) => a.venue == ActivityVenue.falTarot)
          .toList(growable: false);
      expect(fal, hasLength(3));
      expect(fal.any((ActivityAction a) => a.cost == 0), isTrue);
      for (final ActivityAction a in fal) {
        expect(ActivityEngine.isFortune(a), isTrue);
      }
    });

    test('kahve falı rastgele metin verir ve ücreti düşer', () {
      final GameState s = yetiskin();
      final ActivityAction a = eylem('kahve_fali');
      final ActivityResult r =
          motor.tellFortune(state: s, action: a, rng: Random(1));
      expect(r.outcome.applied, isTrue);
      expect(r.outcome.text, isNotEmpty);
      expect(r.state.player.wallet, s.player.wallet - a.cost);
    });

    test('fal sonucu hem iyi hem kötü çıkabilir', () {
      final ActivityAction a = eylem('kahve_fali');
      int iyi = 0;
      int kotu = 0;
      for (int seed = 0; seed < 60; seed++) {
        final GameState s = yetiskin(seed: seed % 10);
        final ActivityResult r =
            motor.tellFortune(state: s, action: a, rng: Random(seed));
        final int fark = r.state.player.stats.happiness -
            s.player.stats.happiness;
        if (fark > 0) iyi++;
        if (fark < 0) kotu++;
      }
      expect(iyi, greaterThan(0), reason: 'Hiç iyi fal çıkmıyor');
      expect(kotu, greaterThan(0), reason: 'Hiç kötü fal çıkmıyor');
    });

    test('tarotta kartın adı sonuçta yazar', () {
      final GameState s = yetiskin();
      final ActivityResult r = motor.tellFortune(
        state: s,
        action: eylem('tarot_actir'),
        rng: Random(3),
      );
      expect(
        kTarotCards.any((TarotCard k) => r.outcome.text.startsWith(k.name)),
        isTrue,
      );
    });

    test('burç yorumu oyuncunun kendi burcunu yazar ve ücretsizdir', () {
      final GameState s = yetiskin();
      final ActivityResult r = motor.tellFortune(
        state: s,
        action: eylem('burc_yorumu'),
        rng: Random(2),
      );
      expect(r.outcome.text, contains(Astrology.zodiacOf(s).label));
      expect(r.state.player.wallet, s.player.wallet);
    });

    test('her burcun yorumu vardır', () {
      for (final Zodiac z in Zodiac.values) {
        expect(kHoroscopes[z], isNotNull, reason: '${z.label} eksik');
        expect(kHoroscopes[z], isNotEmpty);
      }
    });

    test('kötü fal tekrar baktırılarak etkisiz hâle getirilemez', () {
      // Olumlu etki tekrar edildikçe azalır; olumsuz etki tam uygulanır.
      final GameState s = yetiskin();
      final ActivityAction a = eylem('kahve_fali');
      // Kötü sonuç veren bir tohum bulunur.
      for (int seed = 0; seed < 100; seed++) {
        final ActivityResult r =
            motor.tellFortune(state: s, action: a, rng: Random(seed));
        final int fark =
            r.state.player.stats.happiness - s.player.stats.happiness;
        if (fark >= 0) continue;
        // Aynı kötü sonuç, izin verilen son tekrarda da aynı düşüşü
        // verir. (Eylem zaten `maxPerAge` sınırında kapanıyor; sınırsız
        // tekrar da mümkün değil.)
        final GameState cokTekrar = s.copyWith(
          interactionCounts: <String, int>{
            GameState.interactionKey('aktivite', a.id): a.maxPerAge - 1,
          },
        );
        final ActivityResult r2 = motor.tellFortune(
          state: cokTekrar,
          action: a,
          rng: Random(seed),
        );
        expect(r2.outcome.applied, isTrue);
        expect(
          r2.state.player.stats.happiness - cokTekrar.player.stats.happiness,
          fark,
        );
        // Sınıra gelince eylem kapanır: sonsuz tekrar yok.
        final GameState dolu = s.copyWith(
          interactionCounts: <String, int>{
            GameState.interactionKey('aktivite', a.id): a.maxPerAge,
          },
        );
        expect(motor.availability(dolu, a).isAllowed, isFalse);
        return;
      }
      fail('Hiç kötü fal bulunamadı');
    });

    test('küçük yaşta fal açılmaz', () {
      final GameState cocuk = yetiskin(age: 6);
      expect(
        motor.availability(cocuk, eylem('kahve_fali')).isAllowed,
        isFalse,
      );
    });

    test('parası yetmeyene fal baktırılmaz ve cüzdan değişmez', () {
      final GameState fakir = yetiskin(wallet: 10);
      final ActivityResult r = motor.tellFortune(
        state: fakir,
        action: eylem('tarot_actir'),
        rng: Random(1),
      );
      expect(r.outcome.applied, isFalse);
      expect(r.state.player.wallet, fakir.player.wallet);
    });
  });

  group('Burçsal dönemler', () {
    test('her dönem en az bir burcu etkiler', () {
      for (final ZodiacPeriod d in kZodiacPeriods) {
        expect(d.elements, isNotEmpty);
        expect(
          Zodiac.values.any((Zodiac z) => d.affects(z)),
          isTrue,
          reason: '${d.id} hiçbir burcu etkilemiyor',
        );
      }
    });

    test('her burç en az bir dönemden etkilenir', () {
      // Yoksa bazı burçlar bu sistemi hiç görmez.
      for (final Zodiac z in Zodiac.values) {
        expect(
          kZodiacPeriods.any((ZodiacPeriod d) => d.affects(z)),
          isTrue,
          reason: '${z.label} hiçbir dönemden etkilenmiyor',
        );
      }
    });

    test('dönemler hem mutluluk artırır hem düşürür', () {
      expect(
        kZodiacPeriods.any((ZodiacPeriod d) => d.prototypeOnlyHappiness > 0),
        isTrue,
      );
      expect(
        kZodiacPeriods.any((ZodiacPeriod d) => d.prototypeOnlyHappiness < 0),
        isTrue,
      );
    });

    test('yıllar içinde burçsal dönem bildirimi çıkar', () {
      int bildirimli = 0;
      for (int seed = 0; seed < 25; seed++) {
        GameState akan = yetiskin(seed: seed, age: 25);
        for (int yil = 0; yil < 12; yil++) {
          akan = LifeProgression(Random(seed * 7 + yil)).advanceOneYear(akan);
          if (akan.deceased) break;
          if (akan.notices.any(
            (PendingNotice n) => n.kind == NoticeKind.burc,
          )) {
            bildirimli++;
            break;
          }
          akan = akan.copyWith(
            pendingEvent: null,
            notices: const <PendingNotice>[],
          );
        }
      }
      expect(bildirimli, greaterThan(0), reason: 'Hiç burç dönemi çıkmıyor');
    });

    test('çıkan dönem oyuncunun burcunu gerçekten etkiler', () {
      // "Seni etkilemiyor" diye bir bildirim gösterilmez.
      for (int seed = 0; seed < 40; seed++) {
        GameState akan = yetiskin(seed: seed, age: 25);
        for (int yil = 0; yil < 12; yil++) {
          akan = LifeProgression(Random(seed * 7 + yil)).advanceOneYear(akan);
          if (akan.deceased) break;
          final Iterable<PendingNotice> burc = akan.notices
              .where((PendingNotice n) => n.kind == NoticeKind.burc);
          if (burc.isNotEmpty) {
            final Zodiac z = Astrology.zodiacOf(akan);
            final ZodiacPeriod donem = kZodiacPeriods.firstWhere(
              (ZodiacPeriod d) => burc.single.id.contains(d.id),
            );
            expect(donem.affects(z), isTrue);
            expect(burc.single.text, contains(z.label));
            return;
          }
          akan = akan.copyWith(
            pendingEvent: null,
            notices: const <PendingNotice>[],
          );
        }
      }
      fail('Hiç burç dönemi çıkmadı');
    });

    test('küçük çocuğa burçsal dönem çıkmaz', () {
      GameState akan = yetiskin(age: 5);
      for (int yil = 0; yil < 5; yil++) {
        akan = LifeProgression(Random(yil)).advanceOneYear(akan);
        expect(
          akan.notices.any((PendingNotice n) => n.kind == NoticeKind.burc),
          isFalse,
        );
        akan = akan.copyWith(pendingEvent: null);
      }
    });
  });
}
