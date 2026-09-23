import 'dart:math';

import 'package:bir_omur/data/event_pool.dart';
import 'package:bir_omur/data/interaction_texts.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/interaction/marriage_engine.dart';
import 'package:bir_omur/domain/interaction/shared_history.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/models/trip.dart';
import 'package:bir_omur/domain/events/event_engine.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/interaction.dart';
import 'package:bir_omur/domain/models/life_log.dart';
import 'package:bir_omur/domain/models/marriage.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/person_development.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/stats.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:bir_omur/text/turkish_text.dart';
import 'package:flutter_test/flutter_test.dart';

Person kisi({
  required String id,
  required RelationType relation,
  required Gender gender,
  int age = 40,
  String firstName = 'Kerem',
  bool alive = true,
  bool hane = true,
  PersonDevelopment? development,
}) =>
    Person(
      id: id,
      firstName: firstName,
      lastName: 'Yılmaz',
      gender: gender,
      relation: relation,
      age: age,
      isAlive: alive,
      inPlayerHousehold: alive && hane,
      employment: EmploymentStatus.issiz,
      wealth: WealthTier.ortaHalli,
      bond: 60,
      development: development,
    );

GameState hayat({int age = 40, Gender? cinsiyet, List<Person> people = const <Person>[]}) {
  for (int seed = 0; seed < 300; seed++) {
    final GameState taban =
        LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
    if (cinsiyet != null && taban.player.gender != cinsiyet) continue;
    return taban.copyWith(
      pendingEvent: null,
      notices: const <PendingNotice>[],
      pets: const <Pet>[],
      people: people,
      player: taban.player.copyWith(age: age, wallet: 2000000),
    );
  }
  throw StateError('Uygun hayat bulunamadı');
}

void main() {
  // ===================================================================
  // Türkçe büyük/küçük harf
  // ===================================================================
  group('Türkçe İ/ı dönüşümü', () {
    test('trLower I harfini ı yapar', () {
      expect(trLower('İlkokul'), 'ilkokul');
      expect(trLower('İş arkadaşı'), 'iş arkadaşı');
      expect(trLower('İkiz kız kardeşin'), 'ikiz kız kardeşin');
      expect(trLower('Işık'), 'ışık');
      expect(trLower('IŞIK'), 'ışık');
      expect(trLower('Isparta'), 'ısparta');
      expect(trLower('ÇOCUK'), 'çocuk');
      // Ölçülen fark: Dart'ın kendi dönüşümü 'I' harfini 'i' yapıyor.
      expect('Işık'.toLowerCase(), 'işık');
      expect(trLower('Işık'), isNot('Işık'.toLowerCase()));
    });

    test('trUpper ve trLower birbirini bozmaz', () {
      for (final String kelime in <String>[
        'İlkokul',
        'iş arkadaşı',
        'ışık',
        'Şehrazat',
        'ağırlık',
      ]) {
        expect(trLower(trUpper(kelime)), trLower(kelime), reason: kelime);
      }
    });

    test('hiçbir bağ etiketi küçültülünce birleşik nokta içermez', () {
      for (final RelationType r in RelationType.values) {
        for (final Gender g in Gender.values) {
          final Person p = kisi(id: 'x', relation: r, gender: g, age: 30);
          for (final String metin in <String>[
            trLower(p.labelFor(40)),
            trLower(p.possessiveFor(40)),
          ]) {
            expect(
              metin.contains('̇'),
              isFalse,
              reason: '${r.name}/${g.name}: "$metin" birleşik nokta içeriyor',
            );
          }
        }
      }
    });
  });

  // ===================================================================
  // Bağ etiketleri
  // ===================================================================
  group('Bağ etiketleri', () {
    test('cinsiyete göre doğru kardeş hitabı', () {
      // Oyuncu 40 yaşında.
      expect(
        kisi(id: 'k', relation: RelationType.kardes, gender: Gender.kadin, age: 45)
            .possessiveFor(40),
        'Ablan',
      );
      expect(
        kisi(id: 'k', relation: RelationType.kardes, gender: Gender.erkek, age: 45)
            .possessiveFor(40),
        'Abin',
      );
      expect(
        kisi(id: 'k', relation: RelationType.kardes, gender: Gender.erkek, age: 30)
            .possessiveFor(40),
        'Küçük erkek kardeşin',
      );
      expect(
        kisi(id: 'k', relation: RelationType.kardes, gender: Gender.kadin, age: 40)
            .possessiveFor(40),
        'İkiz kız kardeşin',
      );
    });

    test('çocuk, anne, baba, eş ve sevgili doğru yazılır', () {
      expect(
        kisi(id: 'c', relation: RelationType.cocuk, gender: Gender.kadin, age: 10)
            .possessiveFor(40),
        'Kızın',
      );
      expect(
        kisi(id: 'c', relation: RelationType.cocuk, gender: Gender.erkek, age: 10)
            .possessiveFor(40),
        'Oğlun',
      );
      expect(
        kisi(id: 'a', relation: RelationType.anne, gender: Gender.kadin)
            .possessiveFor(40),
        'Annen',
      );
      expect(
        kisi(id: 'b', relation: RelationType.baba, gender: Gender.erkek)
            .possessiveFor(40),
        'Baban',
      );
      expect(
        kisi(id: 'e', relation: RelationType.es, gender: Gender.kadin)
            .possessiveFor(40),
        'Eşin',
      );
      expect(
        kisi(id: 's', relation: RelationType.sevgili, gender: Gender.kadin)
            .possessiveFor(40),
        'Kız arkadaşın',
        reason: 'Evli olmayan sevgiliye "eşin" denmez',
      );
      expect(
        kisi(id: 'x', relation: RelationType.eskiEs, gender: Gender.erkek)
            .possessiveFor(40),
        'Eski eşin',
      );
    });

    test('sevgiliye hiçbir yerde "eş" denmez', () {
      for (final Gender g in Gender.values) {
        final Person p =
            kisi(id: 's', relation: RelationType.sevgili, gender: g);
        expect(p.labelFor(40).toLowerCase(), isNot(contains('eş')));
        expect(p.possessiveFor(40), isNot('Eşin'));
      }
    });
  });

  // ===================================================================
  // İkinci evlilik: eski eş ile yeni eş karışmaz
  // ===================================================================
  group('İkinci evlilik', () {
    const MarriageEngine motor = MarriageEngine();

    GameState evliHayat() {
      final Gender karsi = Gender.kadin;
      return hayat(
        cinsiyet: Gender.erkek,
        people: <Person>[
          kisi(
            id: 'es-1',
            relation: RelationType.sevgili,
            gender: karsi,
            firstName: 'Elif',
          ),
        ],
      );
    }

    test('vefat eden eş, yeniden evlenince "eş" olarak kalmaz', () {
      GameState s = motor.marry(evliHayat(), 'es-1').state;
      expect(s.personById('es-1')!.relation, RelationType.es);

      // Eş vefat etti; evlilik dul durumuna geçti.
      s = s.copyWith(
        people: s.people
            .map((Person p) =>
                p.id == 'es-1' ? p.copyWith(isAlive: false) : p)
            .toList(growable: false),
        marriage: s.marriage!.copyWith(
          status: MarriageStatus.dul,
          endedAtAge: s.player.age,
        ),
      );

      // Yeni sevgili ve ikinci evlilik.
      s = s.copyWith(
        people: <Person>[
          ...s.people,
          kisi(
            id: 'es-2',
            relation: RelationType.sevgili,
            gender: Gender.kadin,
            firstName: 'Derya',
          ),
        ],
      );
      s = motor.marry(s, 'es-2').state;

      expect(s.personById('es-2')!.relation, RelationType.es);
      expect(
        s.personById('es-1')!.relation,
        RelationType.eskiEs,
        reason: 'İki kişi birden "Eş" diye görünmemeli',
      );
      // Kayıt silinmedi ve geçmiş evlilik korundu.
      expect(s.personById('es-1'), isNotNull);
      expect(s.marriageWith('es-1'), isNotNull);
      expect(
        s.people.where((Person p) => p.relation == RelationType.es).length,
        1,
      );
    });

    test('boşanma sonrası da tek eş kalır', () {
      GameState s = motor.marry(evliHayat(), 'es-1').state;
      s = motor.divorce(s).state;
      expect(s.personById('es-1')!.relation, RelationType.eskiEs);
      s = s.copyWith(
        people: <Person>[
          ...s.people,
          kisi(
            id: 'es-2',
            relation: RelationType.sevgili,
            gender: Gender.kadin,
            firstName: 'Derya',
          ),
        ],
      );
      s = motor.marry(s, 'es-2').state;
      expect(
        s.people.where((Person p) => p.relation == RelationType.es).length,
        1,
      );
    });
  });

  // ===================================================================
  // Evlat edinilmiş çocuk ve vefat: uydurma anlatı yok
  // ===================================================================
  group('Ortak geçmişte uydurma yok', () {
    test('evlat edinilen çocuk için "dünyaya geldi" yazılmaz', () {
      final GameState s = hayat(
        age: 40,
        people: <Person>[
          kisi(
            id: 'cocuk-1',
            relation: RelationType.cocuk,
            gender: Gender.erkek,
            age: 9,
            firstName: 'Emre',
            development: const PersonDevelopment(
              tracksLife: true,
              adopted: true,
              stats: Stats(
                appearance: 50,
                happiness: 50,
                health: 50,
                intelligence: 50,
                charisma: 50,
              ),
              milestones: <LifeMilestone>[
                LifeMilestone(age: 7, text: 'Emre yeni ailesine katıldı.'),
              ],
            ),
          ),
        ],
      );
      final List<SharedMoment> anlar =
          SharedHistory.of(s, s.personById('cocuk-1')!);

      expect(
        anlar.any((SharedMoment m) => m.text.contains('dünyaya geldi')),
        isFalse,
        reason: 'Evlat edinilen çocuğun doğumu oyuncunun anısı değildir',
      );
      final List<SharedMoment> katilim = anlar
          .where((SharedMoment m) => m.text.contains('katıldı'))
          .toList();
      expect(katilim, hasLength(1), reason: 'Katılım iki kez yazılmamalı');
      expect(
        katilim.single.age,
        38,
        reason: '40 yaşındaki oyuncu, 9 yaşındaki çocuğu 7 yaşındayken '
            'aldıysa bu 38 yaşında olmuştur',
      );
    });

    test('öz çocukta doğum hâlâ doğru yılda yazılır', () {
      final GameState s = hayat(
        age: 40,
        people: <Person>[
          kisi(
            id: 'cocuk-1',
            relation: RelationType.cocuk,
            gender: Gender.kadin,
            age: 10,
            firstName: 'Nil',
          ),
        ],
      );
      final List<SharedMoment> anlar =
          SharedHistory.of(s, s.personById('cocuk-1')!);
      final SharedMoment dogum = anlar
          .firstWhere((SharedMoment m) => m.text.contains('dünyaya geldi'));
      expect(dogum.age, 30);
    });

    test('vefat etmiş kişi için uydurma yıl yazılmaz', () {
      GameState s = hayat(
        age: 40,
        people: <Person>[
          kisi(
            id: 'anne-1',
            relation: RelationType.anne,
            gender: Gender.kadin,
            age: 70,
            firstName: 'Sema',
            alive: false,
          ),
        ],
      );
      // Ölüm kaydı yoksa hiçbir vefat satırı uydurulmaz.
      expect(
        SharedHistory.of(s, s.personById('anne-1')!)
            .any((SharedMoment m) => m.text.contains('vefat')),
        isFalse,
      );

      // Gerçek kayıt varsa satır o yılda görünür.
      s = s.copyWith(
        log: <LifeLogEntry>[
          ...s.log,
          const LifeLogEntry(
            age: 32,
            text: 'Annen Sema Yılmaz vefat etti.',
            category: LogCategory.aile,
            personId: 'anne-1',
          ),
        ],
      );
      final List<SharedMoment> vefat = SharedHistory.of(
        s,
        s.personById('anne-1')!,
      ).where((SharedMoment m) => m.text.contains('vefat')).toList();
      expect(vefat, hasLength(1));
      expect(vefat.single.age, 32);
    });
  });

  // ===================================================================
  // Olay metinleri
  // ===================================================================
  group('Olay metinleri', () {
    const Set<String> kisiYerTutuculari = <String>{
      '{kisi}',
      '{sahip}',
      '{sahipk}',
      '{bag}',
    };

    bool kisiGerektirir(EventRequirement r) =>
        r.livingRelations.isNotEmpty ||
        r.requiresNeglectedRelative ||
        r.requiresTripMemory ||
        r.personRole != null;

    List<String> yerTutucular(String metin) {
      final RegExp desen = RegExp(r'\{[a-zçğıöşü]+\}');
      return desen
          .allMatches(metin)
          .map((RegExpMatch m) => m.group(0)!)
          .toList(growable: false);
    }

    test('bilinmeyen yer tutucu yok', () {
      const Set<String> bilinen = <String>{
        '{kisi}',
        '{sahip}',
        '{sahipk}',
        '{bag}',
        '{hayvan}',
        '{tur}',
        '{sehir}',
      };
      for (final GameEvent e in kEventPool) {
        final List<String> hepsi = <String>[
          ...yerTutucular(e.text),
          for (final EventChoice c in e.choices) ...<String>[
            ...yerTutucular(c.label),
            ...yerTutucular(c.resultText),
          ],
        ];
        for (final String y in hepsi) {
          expect(bilinen, contains(y), reason: '${e.id}: $y');
        }
      }
    });

    test('olay metni ve seçenek etiketinde kişi yer tutucusu ancak '
        'kişi şartı varsa kullanılır', () {
      // Bunlar seçim yapılmadan **önce** ekrana gelir; o anda kişi
      // yalnızca olayın şartı sayesinde vardır.
      for (final GameEvent e in kEventPool) {
        final String oncesi = <String>[
          e.text,
          for (final EventChoice c in e.choices) c.label,
        ].join(' ');
        if (!kisiYerTutuculari.any((String y) => oncesi.contains(y))) continue;
        expect(
          kisiGerektirir(e.requirement),
          isTrue,
          reason: '${e.id}: kişi yer tutucusu var ama kişi şartı yok',
        );
      }
    });

    test('sonuç metnindeki kişi yer tutucusu ya şarttan ya da o seçimin '
        'kurduğu ilişkiden dolar', () {
      for (final GameEvent e in kEventPool) {
        for (final EventChoice c in e.choices) {
          if (!kisiYerTutuculari.any((String y) => c.resultText.contains(y))) {
            continue;
          }
          final bool kisiUretiyor = c.startsRomance ||
              c.startsFriendship ||
              c.startsSchoolFriendship;
          expect(
            kisiGerektirir(e.requirement) || kisiUretiyor,
            isTrue,
            reason: '${e.id}/${c.id}: sonuç metninde doldurulamayacak '
                'kişi yer tutucusu var',
          );
        }
      }
    });

    test('hayvan yer tutucusu yalnızca hayvan şartlı olayda kullanılır', () {
      for (final GameEvent e in kEventPool) {
        final String hepsi = <String>[
          e.text,
          for (final EventChoice c in e.choices) '${c.label} ${c.resultText}',
        ].join(' ');
        if (!hepsi.contains('{hayvan}') && !hepsi.contains('{tur}')) continue;
        expect(e.requirement.requiresLivingPet, isTrue, reason: e.id);
      }
    });

    test('şehir yer tutucusu yalnızca gezi anısı olayında kullanılır', () {
      for (final GameEvent e in kEventPool) {
        final String hepsi = <String>[
          e.text,
          for (final EventChoice c in e.choices) '${c.label} ${c.resultText}',
        ].join(' ');
        if (!hepsi.contains('{sehir}')) continue;
        expect(e.requirement.requiresTripMemory, isTrue, reason: e.id);
      }
    });

    test('olay metinlerinde çift boşluk ve noktalama boşluğu yok', () {
      for (final GameEvent e in kEventPool) {
        final List<String> metinler = <String>[
          e.text,
          for (final EventChoice c in e.choices) ...<String>[
            c.label,
            c.resultText,
          ],
        ];
        for (final String m in metinler) {
          expect(m.contains('  '), isFalse, reason: '${e.id}: "$m"');
          expect(
            RegExp(r'\s[,.;:!?]').hasMatch(m),
            isFalse,
            reason: '${e.id}: "$m"',
          );
          expect(m.trim(), m, reason: '${e.id}: baştaki/sondaki boşluk');
          expect(m, isNotEmpty, reason: e.id);
        }
      }
    });

    test('hiçbir olay metninde birleşik noktalı i yok', () {
      for (final GameEvent e in kEventPool) {
        final String hepsi = <String>[
          e.text,
          for (final EventChoice c in e.choices) '${c.label} ${c.resultText}',
        ].join(' ');
        expect(hepsi.contains('̇'), isFalse, reason: e.id);
      }
    });
  });

  // ===================================================================
  // Etkileşim metinleri
  // ===================================================================
  group('Etkileşim metinleri', () {
    test('bütün bağ türleri için yer tutucu kalmaz', () {
      final Random rng = Random(5);
      for (final RelationType r in RelationType.values) {
        for (final Gender g in Gender.values) {
          final Person p = kisi(
            id: 'x',
            relation: r,
            gender: g,
            age: r == RelationType.cocuk ? 10 : 45,
          );
          for (final InteractionKind k in InteractionKind.values) {
            for (final bool kabul in <bool>[true, false]) {
              for (final bool kazancYok in <bool>[true, false]) {
                final String metin = interactionText(
                  kind: k,
                  person: p,
                  playerAge: 40,
                  rng: rng,
                  accepted: kabul,
                  noNewBenefit: kazancYok,
                  giftName: 'Bisiklet',
                );
                expect(
                  RegExp(r'\{[a-zçğıöşü]+\}').hasMatch(metin),
                  isFalse,
                  reason: '${r.name}/${g.name}/${k.name}: "$metin"',
                );
                expect(metin.contains('\u0307'), isFalse, reason: metin);
                expect(metin.contains('  '), isFalse, reason: metin);
              }
            }
          }
        }
      }
    });
  });

  // ===================================================================
  // Motorun doldurduğu metinler
  // ===================================================================
  group('Sonuç metni yer tutucuları', () {
    test('hayvan adı sonuç metninde de dolar', () {
      const GameEvent olay = GameEvent(
        id: 'test_hayvan_sonuc',
        category: EventCategory.kisisel,
        text: '{hayvan} kapıda bekliyor.',
        requirement: EventRequirement(minAge: 10, requiresLivingPet: true),
        choices: <EventChoice>[
          EventChoice(
            id: 'ac',
            label: 'Kapıyı aç',
            resultText: '{hayvan} içeri girdi; {tur} dediğin bu.',
          ),
        ],
      );
      const EventEngine motor = EventEngine(pool: <GameEvent>[olay]);

      GameState s = hayat(age: 30).copyWith(
        pets: <Pet>[
          const Pet(
            id: 'hayvan-1',
            name: 'Zeytin',
            species: 'kedi',
            age: 3,
            adoptedAtPlayerAge: 27,
          ),
        ],
      );
      final ActiveEvent? aktif = motor.openingEvent(s, Random(1));
      expect(aktif, isNotNull);
      expect(aktif!.text, contains('Zeytin'));

      s = motor.resolve(s.copyWith(pendingEvent: aktif), 'ac');
      final String sonuc = s.log.last.text;
      expect(sonuc, contains('Zeytin'));
      expect(sonuc, contains('Kedi'));
      expect(sonuc, isNot(contains('{hayvan}')));
      expect(sonuc, isNot(contains('{tur}')));
    });

    test('gezi şehri sonuç metninde de dolar', () {
      const GameEvent olay = GameEvent(
        id: 'test_gezi_sonuc',
        category: EventCategory.kisisel,
        text: '{kisi} ile {sehir} gezisi aklına geldi.',
        requirement: EventRequirement(minAge: 10, requiresTripMemory: true),
        choices: <EventChoice>[
          EventChoice(
            id: 'an',
            label: 'Hatırla',
            resultText: '{sehir} hâlâ aklında.',
          ),
        ],
      );
      const EventEngine motor = EventEngine(pool: <GameEvent>[olay]);

      GameState s = hayat(
        age: 40,
        people: <Person>[
          kisi(
            id: 'arkadas-1',
            relation: RelationType.arkadas,
            gender: Gender.erkek,
            firstName: 'Kerem',
          ),
        ],
      );
      s = s.copyWith(
        trips: <TripRecord>[
          const TripRecord(
            id: 'gezi-1',
            city: 'Trabzon',
            age: 30,
            mode: TravelMode.otobus,
            companionId: 'arkadas-1',
            cost: 1000,
            note: 'Yağmur yağdı.',
          ),
        ],
      );

      final ActiveEvent? aktif = motor.openingEvent(s, Random(1));
      expect(aktif, isNotNull);
      expect(aktif!.text, contains('Trabzon'));

      s = motor.resolve(s.copyWith(pendingEvent: aktif), 'an');
      final String sonuc = s.log.last.text;
      expect(sonuc, contains('Trabzon'));
      expect(sonuc, isNot(contains('{sehir}')));
    });
  });
}
