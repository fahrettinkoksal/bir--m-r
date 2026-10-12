// Paket AP — yetişkin çocuğun evlilik hayatı (§14-§23, §50, §54, §67).
//
// Bu dosyanın tek derdi: çocuğun eşi **gerçek bir insan mı**, ve o
// evlilik gerçekten yaşanıyor mu (boşanma, yeniden evlilik, dulluk).
//
// Hepsi ürünün kendi API'lerinden geçiyor (§80): eş `ChildMarriage`
// motorundan doğuyor, boşanma/yeniden evlilik/dulluk `ChildMarriageLife`
// üzerinden işliyor. Test hiçbir yere elle "evli" yazmıyor.
library;

import 'dart:math';

import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/domain/generation/child_marriage.dart';
import 'package:bir_omur/domain/generation/child_marriage_life.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/kinship.dart';
import 'package:bir_omur/domain/models/npc_marriage.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/person_development.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/stats.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'paket_ao_aile_v2_test.dart' show aileliHayat;

/// Yetişkin, gelişim kaydı olan bir çocuk ekler.
///
/// Gelişim kaydı **elle** kuruluyor çünkü testin konusu evlilik;
/// `ChildProgression`'ı yıl yıl koşturmak bu dosyanın derdi değil.
/// Evlilik durumunun kendisi yine motordan geliyor.
GameState cocukEkle(
  GameState s, {
  String id = 'cocuk-ap',
  int age = 30,
  Gender gender = Gender.kadin,
  int happiness = 60,
  int money = 200000,
  String? city,
}) =>
    s.copyWith(
      people: List<Person>.unmodifiable(<Person>[
        ...s.people,
        Person(
          id: id,
          firstName: 'Elif',
          lastName: s.player.lastName,
          gender: gender,
          relation: RelationType.cocuk,
          age: age,
          isAlive: true,
          inPlayerHousehold: false,
          employment: EmploymentStatus.calisiyor,
          occupation: 'öğretmen',
          wealth: WealthTier.ortaHalli,
          bond: 60,
          city: city ?? s.player.currentCity,
          motherId: s.player.id,
          development: PersonDevelopment(
            tracksLife: true,
            stats: Stats(
              appearance: 55,
              happiness: happiness,
              health: 70,
              intelligence: 60,
              charisma: 55,
            ),
            finishedSchool: true,
            money: money,
          ),
        ),
      ]),
    );

/// Çocuğu motordan geçirerek evlendirir; olmazsa testi düşürür.
({GameState state, Person child, Person spouse}) evlendir(
  GameState s,
  String childId,
) {
  for (int seed = 0; seed < 400; seed++) {
    final Person cocuk = s.personById(childId)!;
    final ChildMarriageResult? r = ChildMarriage.maybeMarry(
      child: cocuk,
      playerAge: s.player.age,
      rng: Random(seed),
      relation: RelationType.cocuk,
      state: s,
    );
    if (r == null || r.spouse == null) continue;
    final GameState sonra = s.copyWith(
      people: List<Person>.unmodifiable(<Person>[
        for (final Person p in s.people)
          if (p.id == childId) r.person else p,
        r.spouse!,
      ]),
    );
    return (state: sonra, child: r.person, spouse: r.spouse!);
  }
  fail('400 denemede çocuk hiç evlenmedi: kapı kapalı.');
}

void main() {
  group('§14-§16 — çocuğun eşi gerçek bir kişi', () {
    test('evlenince gerçek Person kaydı oluşuyor, sadece isim değil', () {
      GameState s = aileliHayat(seed: 4, age: 55);
      s = cocukEkle(s);
      final int once = s.people.length;

      final ({GameState state, Person child, Person spouse}) r =
          evlendir(s, 'cocuk-ap');

      // Kişi listesine gerçekten yeni biri girdi.
      expect(r.state.people.length, once + 1);
      expect(r.spouse.relation, RelationType.cocugunEsi);
      expect(r.spouse.isAlive, isTrue);
      expect(r.spouse.firstName, isNotEmpty);

      // Kayıt iki tarafı birbirine bağlıyor.
      final PersonDevelopment d = r.child.development!;
      expect(d.spousePersonId, r.spouse.id,
          reason: '§16: evlilik gerçek kişiye bağlanmalı.');
      expect(d.spouseName, r.spouse.firstName);
      expect(d.marriageStatus, NpcMarriageStatus.evli);
      expect(d.isMarried, isTrue);
    });

    test('eş oyuncunun hanesinde yaşamıyor ve kendi soyadını taşıyor', () {
      GameState s = aileliHayat(seed: 4, age: 55);
      s = cocukEkle(s);
      final ({GameState state, Person child, Person spouse}) r =
          evlendir(s, 'cocuk-ap');
      expect(r.spouse.inPlayerHousehold, isFalse);
      expect(r.spouse.lastName, isNot(s.player.lastName),
          reason: 'Eş kendi ailesinden gelir; soyadı kopyalanmaz.');
    });

    test('§24: gelin/damat yakınlığı düşük başlar', () {
      GameState s = aileliHayat(seed: 4, age: 55);
      s = cocukEkle(s);
      final ({GameState state, Person child, Person spouse}) r =
          evlendir(s, 'cocuk-ap');
      // Otomatik "kendi çocuğun gibi" bir bağ verilmiyor.
      expect(r.spouse.bond, lessThan(45));
    });

    test('§16, §54: aynı evlilik ikinci kez eş üretmiyor', () {
      GameState s = aileliHayat(seed: 4, age: 55);
      s = cocukEkle(s);
      final ({GameState state, Person child, Person spouse}) r =
          evlendir(s, 'cocuk-ap');

      // Aynı çocuk için tekrar denendiğinde: zaten evli olduğu için
      // `eligible` kapısı kapanıyor.
      final ChildMarriageResult? ikinci = ChildMarriage.maybeMarry(
        child: r.child,
        playerAge: 55,
        rng: Random(1),
        relation: RelationType.cocuk,
        state: r.state,
        forceMarriage: true,
      );
      expect(ikinci, isNull,
          reason: 'Evli çocuk yeniden evlendirilemez.');

      final int esSayisi = r.state.people
          .where((Person p) => p.relation == RelationType.cocugunEsi)
          .length;
      expect(esSayisi, 1);
    });
  });

  group('§19-§22 — çocuk boşanması', () {
    /// Boşanma kesin olsun diye çok tohum denenir.
    ({GameState state, Person child}) bosandir(GameState s, String childId) {
      for (int seed = 0; seed < 600; seed++) {
        final ChildMarriageYear y =
            ChildMarriageLife.maybeDivorce(s, s.player.age, Random(seed));
        final Person c = y.state.personById(childId)!;
        if (c.development!.isDivorced) return (state: y.state, child: c);
      }
      fail('600 denemede çocuk hiç boşanmadı: mekanik ölü.');
    }

    test('boşanma durumu gerçekten yazılıyor ve geçmişe taşınıyor', () {
      GameState s = aileliHayat(seed: 4, age: 55);
      // Mutsuz ve parasız: boşanma ihtimali en yüksek bant.
      s = cocukEkle(s, happiness: 20, money: 0, age: 34);
      final ({GameState state, Person child, Person spouse}) evli =
          evlendir(s, 'cocuk-ap');
      // Evlilik süresi koşulu: en az iki yıl geçmiş olsun.
      GameState hazir = evli.state.copyWith(
        people: List<Person>.unmodifiable(<Person>[
          for (final Person p in evli.state.people)
            if (p.id == 'cocuk-ap')
              p.copyWith(
                development: p.development!.copyWith(marriedAtAge: 30),
              )
            else
              p,
        ]),
      );

      final ({GameState state, Person child}) r =
          bosandir(hazir, 'cocuk-ap');
      final PersonDevelopment d = r.child.development!;

      expect(d.isMarried, isFalse);
      expect(d.isDivorced, isTrue);
      expect(d.spousePersonId, isNull,
          reason: 'Yürüyen eş bağı kopmalı.');
      expect(d.pastMarriages, hasLength(1),
          reason: '§18: geçmiş kaybolmasın.');
      expect(d.pastMarriages.single.status, NpcMarriageStatus.bosandi);
      expect(d.pastMarriages.single.spousePersonId, evli.spouse.id,
          reason: 'Geçmiş kayıt hangi kişiyle olduğunu hatırlamalı.');
      expect(d.pastMarriages.single.endedAtAge, isNotNull);
    });

    test('§21: eski eş silinmiyor, bağı eskiCocugunEsi oluyor', () {
      GameState s = aileliHayat(seed: 4, age: 55);
      s = cocukEkle(s, happiness: 20, money: 0, age: 34);
      final ({GameState state, Person child, Person spouse}) evli =
          evlendir(s, 'cocuk-ap');
      final GameState hazir = evli.state.copyWith(
        people: List<Person>.unmodifiable(<Person>[
          for (final Person p in evli.state.people)
            if (p.id == 'cocuk-ap')
              p.copyWith(
                development: p.development!.copyWith(marriedAtAge: 30),
              )
            else
              p,
        ]),
      );
      final ({GameState state, Person child}) r = bosandir(hazir, 'cocuk-ap');

      final Person? eski = r.state.personById(evli.spouse.id);
      expect(eski, isNotNull, reason: '§21: kayıt silinmez.');
      expect(eski!.relation, RelationType.eskiCocugunEsi);
      expect(eski.isAlive, isTrue);
    });

    test('§22: boşanma torunun soy bağına dokunmuyor', () {
      GameState s = aileliHayat(seed: 4, age: 55);
      s = cocukEkle(s, happiness: 20, money: 0, age: 34);
      final ({GameState state, Person child, Person spouse}) evli =
          evlendir(s, 'cocuk-ap');

      // Torun: anne çocuk, baba gelin/damat.
      GameState hazir = evli.state.copyWith(
        people: List<Person>.unmodifiable(<Person>[
          for (final Person p in evli.state.people)
            if (p.id == 'cocuk-ap')
              p.copyWith(
                development: p.development!.copyWith(marriedAtAge: 30),
              )
            else
              p,
          Person(
            id: 'torun-ap',
            firstName: 'Can',
            lastName: s.player.lastName,
            gender: Gender.erkek,
            relation: RelationType.torun,
            age: 3,
            isAlive: true,
            inPlayerHousehold: false,
            employment: EmploymentStatus.cocuk,
            wealth: null,
            bond: 60,
            motherId: 'cocuk-ap',
            fatherId: evli.spouse.id,
          ),
        ]),
      );

      final ({GameState state, Person child}) r = bosandir(hazir, 'cocuk-ap');
      final Person torun = r.state.personById('torun-ap')!;
      expect(torun.motherId, 'cocuk-ap');
      expect(torun.fatherId, evli.spouse.id,
          reason: '§22: boşanma biyolojik ebeveyni değiştirmez.');
    });

    test('iki yıldan yeni evlilik boşanamaz', () {
      GameState s = aileliHayat(seed: 4, age: 55);
      s = cocukEkle(s, happiness: 10, money: 0, age: 30);
      final ({GameState state, Person child, Person spouse}) evli =
          evlendir(s, 'cocuk-ap');
      // Evlilik bu yıl kuruldu: süre 0.
      final Person c = evli.state.personById('cocuk-ap')!;
      expect(ChildMarriageLife.canDivorce(c, c.age), isFalse);
    });

    test('mutlu ve parası olan çocuk daha az boşanıyor', () {
      // İddia tek bir hayatta değil **ihtimalde**: motor girdileri
      // gerçekten kullanıyor mu?
      GameState mutsuz = cocukEkle(
        aileliHayat(seed: 4, age: 55),
        happiness: 15,
        money: 0,
        age: 40,
      );
      GameState mutlu = cocukEkle(
        aileliHayat(seed: 4, age: 55),
        happiness: 85,
        money: 900000,
        age: 40,
      );
      mutsuz = evlendir(mutsuz, 'cocuk-ap').state;
      mutlu = evlendir(mutlu, 'cocuk-ap').state;
      final Person a = mutsuz.personById('cocuk-ap')!.copyWith(
            development: mutsuz
                .personById('cocuk-ap')!
                .development!
                .copyWith(marriedAtAge: 35),
          );
      final Person b = mutlu.personById('cocuk-ap')!.copyWith(
            development: mutlu
                .personById('cocuk-ap')!
                .development!
                .copyWith(marriedAtAge: 35),
          );
      expect(
        ChildMarriageLife.divorceChance(a),
        greaterThan(ChildMarriageLife.divorceChance(b)),
        reason: '§19: mutluluk ve ekonomi gerçekten etkili olmalı.',
      );
    });
  });

  group('§23, §54 — yeniden evlenme', () {
    test('soğuma süresi geçmeden yeniden evlenilmiyor', () {
      GameState s = cocukEkle(aileliHayat(seed: 4, age: 55), age: 40);
      s = evlendir(s, 'cocuk-ap').state;
      final Person c = s.personById('cocuk-ap')!;
      // Boşanmış ama bu yıl boşanmış bir kayıt kuruyoruz.
      final Person bosanmis = c.copyWith(
        development: c.development!.copyWith(
          marriageStatus: NpcMarriageStatus.bosandi,
          spousePersonId: null,
          pastMarriages: <NpcMarriageRecord>[
            NpcMarriageRecord(
              spouseName: 'Ahmet',
              marriedAtAge: 30,
              endedAtAge: c.age,
              status: NpcMarriageStatus.bosandi,
            ),
          ],
        ),
      );
      expect(ChildMarriageLife.canRemarry(bosanmis), isFalse);
    });

    test('yeni eş FARKLI bir kişi; eski eş geçmişte kalıyor', () {
      GameState s = cocukEkle(aileliHayat(seed: 4, age: 55), age: 40);
      final ({GameState state, Person child, Person spouse}) ilk =
          evlendir(s, 'cocuk-ap');

      // Boşanmış, soğuma süresi geçmiş bir kayıt.
      GameState hazir = ilk.state.copyWith(
        people: List<Person>.unmodifiable(<Person>[
          for (final Person p in ilk.state.people)
            if (p.id == 'cocuk-ap')
              p.copyWith(
                development: p.development!.copyWith(
                  marriageStatus: NpcMarriageStatus.bosandi,
                  spousePersonId: null,
                  pastMarriages: <NpcMarriageRecord>[
                    NpcMarriageRecord(
                      spouseName: ilk.spouse.firstName,
                      spousePersonId: ilk.spouse.id,
                      marriedAtAge: 30,
                      endedAtAge: 34,
                      status: NpcMarriageStatus.bosandi,
                    ),
                  ],
                ),
              )
            else if (p.id == ilk.spouse.id)
              p.copyWith(relation: RelationType.eskiCocugunEsi)
            else
              p,
        ]),
      );

      GameState? sonuc;
      for (int seed = 0; seed < 600 && sonuc == null; seed++) {
        final ChildMarriageYear y =
            ChildMarriageLife.maybeRemarry(hazir, 55, Random(seed));
        if (y.state.personById('cocuk-ap')!.development!.isMarried) {
          sonuc = y.state;
        }
      }
      expect(sonuc, isNotNull,
          reason: '600 denemede hiç yeniden evlenme olmadı.');

      final PersonDevelopment d =
          sonuc!.personById('cocuk-ap')!.development!;
      expect(d.isMarried, isTrue);
      expect(d.spousePersonId, isNotNull);
      expect(d.spousePersonId, isNot(ilk.spouse.id),
          reason: '§54: yeni eş aynı Person olamaz.');

      // Eski eş hâlâ kayıtta ve hâlâ eski gelin/damat.
      final Person? eski = sonuc.personById(ilk.spouse.id);
      expect(eski, isNotNull);
      expect(eski!.relation, RelationType.eskiCocugunEsi);

      // İki ayrı gelin/damat kaydı var: biri güncel, biri eski.
      final int guncel = sonuc.people
          .where((Person p) => p.relation == RelationType.cocugunEsi)
          .length;
      expect(guncel, 1);
    });
  });

  group('§50 — eşin vefatı', () {
    test('eşi vefat eden çocuk dul yazılıyor, kayıt silinmiyor', () {
      GameState s = cocukEkle(aileliHayat(seed: 4, age: 55), age: 45);
      final ({GameState state, Person child, Person spouse}) evli =
          evlendir(s, 'cocuk-ap');

      // Eş vefat etti (genel ölüm motorunun yaptığı şey).
      final GameState olumSonrasi = evli.state.copyWith(
        people: List<Person>.unmodifiable(<Person>[
          for (final Person p in evli.state.people)
            if (p.id == evli.spouse.id)
              p.copyWith(isAlive: false, inPlayerHousehold: false)
            else
              p,
        ]),
      );

      final ChildMarriageYear y =
          ChildMarriageLife.applySpouseDeaths(olumSonrasi, 55);
      final PersonDevelopment d =
          y.state.personById('cocuk-ap')!.development!;

      expect(d.isWidowed, isTrue);
      expect(d.isMarried, isFalse);
      expect(d.pastMarriages, hasLength(1));
      expect(d.pastMarriages.single.status, NpcMarriageStatus.dul);
      // Kişi silinmedi.
      expect(y.state.personById(evli.spouse.id), isNotNull);
      expect(y.notices, isNotEmpty, reason: 'Oyuncuya haber ulaşmalı.');
    });

    test('eşi hayatta olan çocuk dul yazılmıyor', () {
      GameState s = cocukEkle(aileliHayat(seed: 4, age: 55), age: 45);
      final ({GameState state, Person child, Person spouse}) evli =
          evlendir(s, 'cocuk-ap');
      final ChildMarriageYear y =
          ChildMarriageLife.applySpouseDeaths(evli.state, 55);
      expect(
        y.state.personById('cocuk-ap')!.development!.isMarried,
        isTrue,
      );
      expect(y.notices, isEmpty);
    });
  });

  group('§17, §61 — eski kayıt uyumu ve save/load', () {
    test('sadece spouseName taşıyan eski kayıt evli sayılmaya devam eder',
        () {
      // Paket AP öncesinde kurulmuş kayıt: durum yok, eş kimliği yok.
      final PersonDevelopment eski = PersonDevelopment(
        stats: const Stats(
          appearance: 50,
          happiness: 50,
          health: 50,
          intelligence: 50,
          charisma: 50,
        ),
        marriedAtAge: 27,
        spouseName: 'Ahmet',
      );
      expect(eski.isMarried, isTrue,
          reason: '§17: eski kayıt bir anda "bekar" olmamalı.');
      expect(eski.spousePersonId, isNull,
          reason: 'Geriye dönük NPC uydurulmaz.');
      expect(eski.marriageStatus, isNull);
      expect(eski.pastMarriages, isEmpty);
    });

    test('yeni evlilik alanları kayıt turunda aynen dönüyor', () {
      GameState s = cocukEkle(aileliHayat(seed: 4, age: 55), age: 40);
      final ({GameState state, Person child, Person spouse}) evli =
          evlendir(s, 'cocuk-ap');

      final GameState geri =
          decodeGameState(encodeGameState(evli.state));
      final PersonDevelopment d = geri.personById('cocuk-ap')!.development!;
      expect(d.spousePersonId, evli.spouse.id);
      expect(d.marriageStatus, NpcMarriageStatus.evli);
      expect(geri.personById(evli.spouse.id)!.relation,
          RelationType.cocugunEsi);
    });

    test('geçmiş evlilik listesi kayıt turunda korunuyor', () {
      GameState s = cocukEkle(aileliHayat(seed: 4, age: 55), age: 45);
      final Person c = s.personById('cocuk-ap')!;
      final GameState hazir = s.copyWith(
        people: List<Person>.unmodifiable(<Person>[
          for (final Person p in s.people)
            if (p.id == 'cocuk-ap')
              p.copyWith(
                development: c.development!.copyWith(
                  marriageStatus: NpcMarriageStatus.dul,
                  pastMarriages: <NpcMarriageRecord>[
                    NpcMarriageRecord(
                      spouseName: 'Ahmet',
                      spousePersonId: 'cocugunesi-cocuk-ap-1',
                      marriedAtAge: 28,
                      endedAtAge: 41,
                      status: NpcMarriageStatus.dul,
                    ),
                  ],
                ),
              )
            else
              p,
        ]),
      );
      final GameState geri = decodeGameState(encodeGameState(hazir));
      final PersonDevelopment d = geri.personById('cocuk-ap')!.development!;
      expect(d.pastMarriages, hasLength(1));
      expect(d.pastMarriages.single.spouseName, 'Ahmet');
      expect(d.pastMarriages.single.spousePersonId, 'cocugunesi-cocuk-ap-1');
      expect(d.pastMarriages.single.endedAtAge, 41);
      expect(d.pastMarriages.single.status, NpcMarriageStatus.dul);
      expect(d.isWidowed, isTrue);
    });
  });

  group('§67 — romantik koruma', () {
    test('gelin/damat ve eski gelin/damat romantik havuza girmez', () {
      expect(Kinship.isRomanceForbidden(RelationType.cocugunEsi), isTrue);
      expect(
        Kinship.isRomanceForbidden(RelationType.eskiCocugunEsi),
        isTrue,
      );
    });

    test('§66: gelin/damat kan bağı sayılmaz', () {
      expect(RelationType.cocugunEsi.kanBagi, isFalse);
      expect(RelationType.eskiCocugunEsi.kanBagi, isFalse);
    });
  });
}
