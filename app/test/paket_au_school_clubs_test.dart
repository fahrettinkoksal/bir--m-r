// Paket AU — okul kulüpleri: katılım, seçme, kadro rolü, save/load,
// okul değişikliği.
library;

import 'dart:math';

import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/data/school_club_catalog.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/education.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/school_club_progress.dart';
import 'package:bir_omur/domain/sports/school_club_engine.dart';
import 'package:flutter_test/flutter_test.dart';

const SchoolClubEngine _motor = SchoolClubEngine();

GameState _ogrenci(
  int seed, {
  int age = 11,
  int grade = 5,
  int health = 85,
  String schoolId = 'okul-1',
}) {
  final GameState base =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  return base.copyWith(
    player: base.player.copyWith(
      age: age,
      stats: base.player.stats.copyWith(health: health, charisma: 60),
    ),
    education: EducationState(
      enrolled: true,
      grade: grade,
      schoolId: schoolId,
      classId: 'sinif-1',
      startedAtAge: 6,
    ),
  );
}

SchoolClub get _satranc => schoolClubById('satranc_kulubu')!;
SchoolClub get _futbol => footballClub;

void main() {
  group('Katalog', () {
    test('kulüpler tekil kimlikli ve üç kategoriye dağılmış', () {
      final Set<String> idler = <String>{};
      for (final SchoolClub c in kSchoolClubs) {
        expect(idler.add(c.id), isTrue, reason: '${c.id} iki kez var.');
        expect(c.minGrade, lessThanOrEqualTo(c.maxGrade));
        expect(c.name.trim(), isNotEmpty);
        expect(c.blurb.trim(), isNotEmpty);
      }
      for (final SchoolClubCategory k in SchoolClubCategory.values) {
        expect(
          kSchoolClubs.any((SchoolClub c) => c.category == k),
          isTrue,
          reason: '${k.label} kategorisinde kulüp yok.',
        );
      }
    });

    test('takım sporu ile satranç aynı mekanik değil', () {
      expect(_futbol.requiresTryout, isTrue);
      expect(_futbol.physical, isTrue);
      expect(_satranc.requiresTryout, isFalse,
          reason: 'Satrançta seçme yok, doğrudan katılım.');
      expect(_satranc.physical, isFalse);
    });

    test('bağlanan hobiler gerçekten var olan hobiler', () {
      const Set<String> bilinen = <String>{
        'muzik', 'resim', 'okuma', 'spor', 'mutfak', 'fotograf',
        'dans', 'satranc', 'yazmak', 'bahce', 'dil', 'yazilim',
      };
      for (final SchoolClub c in kSchoolClubs) {
        final String? h = c.associatedHobbyId;
        if (h == null) continue;
        expect(bilenenIcerir(bilinen, h), isTrue,
            reason: '${c.id} tanınmayan hobiye bağlı: $h');
      }
    });
  });

  group('Katılım ve engeller', () {
    test('seçme istemeyen kulübe doğrudan girilir', () {
      final GameState s = _ogrenci(1);
      final ClubJoinOutcome r = _motor.join(s, _satranc, Random(1));
      expect(r.accepted, isTrue);
      expect(r.state!.schoolClubs.activeFor(_satranc.id), isNotNull);
      expect(r.state!.schoolClubs.single.joinedAtAge, 11);
      expect(r.state!.schoolClubs.single.joinedAtGrade, 5);
      expect(r.state!.schoolClubs.single.role, SquadRole.yedek);
    });

    test('okula gitmeyen kulübe giremez', () {
      final GameState s = _ogrenci(2).copyWith(
        education: const EducationState.notStarted(),
      );
      expect(_motor.blockFor(s, _satranc), isNotNull);
      expect(_motor.join(s, _satranc, Random(1)).accepted, isFalse);
    });

    test('sınıfı uygun olmayan kulüp gerekçeyle kapanır', () {
      // Münazara 7. sınıftan açılıyor; 5. sınıfta kapalı.
      final SchoolClub munazara = schoolClubById('munazara_kulubu')!;
      final GameState s = _ogrenci(3, grade: 5);
      final ClubBlock? engel = _motor.blockFor(s, munazara);
      expect(engel, isNotNull);
      expect(engel!.reason, contains('sınıfta açılmıyor'));
    });

    test('aynı kulübe iki aktif kayıt açılmaz', () {
      GameState s = _ogrenci(4);
      s = _motor.join(s, _satranc, Random(1)).state!;
      final ClubBlock? engel = _motor.blockFor(s, _satranc);
      expect(engel, isNotNull);
      expect(engel!.reason, contains('zaten üyesisin'));
    });

    test('aktif kulüp sınırı üçüncü başvuruyu gerekçeyle kapatır', () {
      GameState s = _ogrenci(5, grade: 8, age: 14);
      s = _motor.join(s, _satranc, Random(1)).state!;
      final SchoolClub muzik = schoolClubById('muzik_kulubu')!;
      s = _motor.join(s, muzik, Random(1)).state!;
      expect(s.schoolClubs.activeOnes.length,
          SchoolClubEngine.prototypeOnlyMaxActiveClubs);

      final SchoolClub halk = schoolClubById('halk_oyunlari')!;
      final ClubBlock? engel = _motor.blockFor(s, halk);
      expect(engel, isNotNull);
      expect(engel!.reason, contains('en fazla'));
    });

    test('kritik sağlıkta bedensel takıma girilmez (Paket AQ uyumu)', () {
      final GameState s = _ogrenci(6, health: 10);
      final ClubBlock? engel = _motor.blockFor(s, _futbol);
      expect(engel, isNotNull);
      expect(engel!.reason, contains('Sağlığın'));
      // Ama satranç açık kalır: sağlık zihinsel kulübü kapatmaz.
      expect(_motor.blockFor(s, _satranc), isNull);
    });
  });

  group('Futbol seçmesi sadece kura değil', () {
    test('seçme puanı sağlık ve geçmişle yükselir', () {
      final GameState zayif = _ogrenci(7, health: 40);
      final GameState saglikli = _ogrenci(7, health: 95);
      expect(
        _motor.tryoutScore(saglikli, _futbol),
        greaterThan(_motor.tryoutScore(zayif, _futbol)),
      );
    });

    test('geçmiş futbol deneyimi seçme puanını artırır', () {
      final GameState temiz = _ogrenci(8, age: 14, grade: 8);
      final GameState deneyimli = temiz.copyWith(
        schoolClubs: <SchoolClubProgress>[
          SchoolClubProgress(
            clubId: _futbol.id,
            schoolId: 'eski-okul',
            joinedAtAge: 10,
            joinedAtGrade: 4,
            active: false,
            leftAtAge: 13,
            yearsActive: 3,
            skill: 50,
          ),
        ],
      );
      expect(
        _motor.tryoutScore(deneyimli, _futbol),
        greaterThan(_motor.tryoutScore(temiz, _futbol)),
      );
    });

    test('mükemmel girdi bile kesin kabul değil', () {
      // Yüksek puanlı oyuncuda bile eleme ihtimali kalmalı: kura kenar
      // payı sıfırlanmadı. Birçok tohum üzerinde en az bir ret aranır.
      final GameState s = _ogrenci(9, age: 13, grade: 7, health: 100);
      // Puanı tavana yakın tutmak için geçmiş eklenmedi; yine de
      // seçmenin deterministik olmadığını göstermek yeterli: aynı
      // durumda farklı tohumlar farklı sonuç verebiliyor mu?
      final Set<bool> sonuclar = <bool>{};
      for (int tohum = 0; tohum < 60; tohum++) {
        sonuclar.add(_motor.join(s, _futbol, Random(tohum)).accepted);
      }
      expect(sonuclar.length, 2,
          reason: 'Seçme tamamen deterministik olmamalı; kura payı var.');
    });
  });

  group('Sezon, kadro rolü ve kaptanlık', () {
    test('rol tek sezonda iki kademe atlamaz', () {
      GameState s = _ogrenci(10, age: 11, grade: 5);
      s = s.copyWith(
        schoolClubs: <SchoolClubProgress>[
          SchoolClubProgress(
            clubId: _futbol.id,
            schoolId: 'okul-1',
            joinedAtAge: 11,
            joinedAtGrade: 5,
            skill: 95,
            performance: 95,
          ),
        ],
      );
      final SquadRole once = s.schoolClubs.single.role;
      final r = _motor.advanceSeason(s, Random(3));
      final SquadRole sonra = r.state.schoolClubs.single.role;
      expect(sonra.index - once.index, lessThanOrEqualTo(1));
    });

    test('kaptanlık en az üç sezon ister ve kalıcı yazılır', () {
      GameState s = _ogrenci(11, age: 11, grade: 5);
      s = _motor.join(s, _futbol, Random(0)).state ??
          s.copyWith(schoolClubs: <SchoolClubProgress>[
            SchoolClubProgress(
              clubId: _futbol.id,
              schoolId: 'okul-1',
              joinedAtAge: 11,
              joinedAtGrade: 5,
            ),
          ]);
      // Tek sezonda kaptan olunmaz.
      var r = _motor.advanceSeason(s, Random(4));
      expect(r.state.schoolClubs.single.role, isNot(SquadRole.kaptan));

      // Yıllar geçtikçe rol yükselebilir; olduğunda kalıcı yazılır.
      GameState akan = r.state;
      for (int i = 0; i < 7; i++) {
        akan = akan.copyWith(
          player: akan.player.copyWith(age: akan.player.age + 1),
        );
        akan = _motor.train(akan, _futbol.id, Random(10 + i));
        akan = _motor.advanceSeason(akan, Random(20 + i)).state;
      }
      final SchoolClubProgress son = akan.schoolClubs.single;
      expect(son.yearsActive, greaterThanOrEqualTo(7));
      if (son.wasCaptain) {
        expect(son.captainSinceAge, isNotNull);
        expect(son.captainSinceAge! >= 11 + 3, isTrue,
            reason: 'Kaptanlık en az üç sezon sonra gelmeli.');
      }
    });

    test('antrenman yılda bir kez sayılır', () {
      GameState s = _ogrenci(12, age: 12, grade: 6);
      s = _motor.join(s, _satranc, Random(1)).state!;
      expect(_motor.canTrain(s, _satranc.id), isTrue);
      s = _motor.train(s, _satranc.id, Random(1));
      expect(_motor.canTrain(s, _satranc.id), isFalse,
          reason: 'Aynı yaşta ikinci antrenman sayılmamalı.');
      final int beceri = s.schoolClubs.single.skill;
      s = _motor.train(s, _satranc.id, Random(2));
      expect(s.schoolClubs.single.skill, beceri,
          reason: 'Yıl içinde tekrar basmak beceriyi artırmamalı.');
    });

    test('beceri tek sezonda saçma biçimde sıçramaz', () {
      GameState s = _ogrenci(13, age: 11, grade: 5);
      s = s.copyWith(schoolClubs: <SchoolClubProgress>[
        SchoolClubProgress(
          clubId: _futbol.id,
          schoolId: 'okul-1',
          joinedAtAge: 11,
          joinedAtGrade: 5,
        ),
      ]);
      final int once = s.schoolClubs.single.skill;
      final r = _motor.advanceSeason(s, Random(5));
      final int artis = r.state.schoolClubs.single.skill - once;
      expect(artis,
          lessThanOrEqualTo(SchoolClubEngine.prototypeOnlyMaxSkillGainPerSeason));
    });
  });

  group('Okul değişikliği ve ayrılma', () {
    test('ayrılınca kayıt silinmez, aktiflik kapanır', () {
      GameState s = _ogrenci(14);
      s = _motor.join(s, _satranc, Random(1)).state!;
      s = _motor.leave(s, _satranc.id);
      expect(s.schoolClubs, hasLength(1));
      expect(s.schoolClubs.single.active, isFalse);
      expect(s.schoolClubs.single.leftAtAge, 11);
    });

    test('okul değişince geçmiş korunur, üyelik taşınmaz', () {
      GameState s = _ogrenci(15, age: 13, grade: 7);
      s = _motor.join(s, _futbol, Random(0)).state ??
          s.copyWith(schoolClubs: <SchoolClubProgress>[
            SchoolClubProgress(
              clubId: _futbol.id,
              schoolId: 'okul-1',
              joinedAtAge: 13,
              joinedAtGrade: 7,
              yearsActive: 2,
              skill: 40,
            ),
          ]);
      s = _motor.advanceSeason(s, Random(1)).state;
      final int beceriOnce = s.schoolClubs.single.skill;

      // Liseye geçiş: yeni okul kimliği.
      s = _motor.onSchoolChanged(s, 'okul-2');
      expect(s.schoolClubs, hasLength(1), reason: 'Geçmiş silinmemeli.');
      expect(s.schoolClubs.single.active, isFalse,
          reason: 'Aktif üyelik yeni okula taşınmamalı.');

      // Yeni okulda yeniden başvurulabilir ve beceri kişiyle kalır.
      s = s.copyWith(
        education: const EducationState(
          enrolled: true,
          grade: 9,
          schoolId: 'okul-2',
          classId: 'sinif-9',
          startedAtAge: 6,
        ),
      );
      final ClubJoinOutcome r = _motor.join(s, _futbol, Random(0));
      if (r.accepted) {
        final SchoolClubProgress yeni =
            r.state!.schoolClubs.activeFor(_futbol.id)!;
        expect(yeni.schoolId, 'okul-2');
        expect(yeni.skill, beceriOnce,
            reason: 'Beceri okulun değil kişinin.');
        expect(r.state!.schoolClubs, hasLength(2),
            reason: 'Eski kayıt yanında durmalı.');
      }
    });
  });

  group('Save / load', () {
    test('kulüp geçmişi birebir korunur', () {
      GameState s = _ogrenci(16, age: 17, grade: 11);
      s = s.copyWith(schoolClubs: <SchoolClubProgress>[
        SchoolClubProgress(
          clubId: _futbol.id,
          schoolId: 'ortaokul',
          joinedAtAge: 11,
          joinedAtGrade: 5,
          active: false,
          leftAtAge: 14,
          yearsActive: 3,
          skill: 48,
          performance: 72,
          role: SquadRole.ilkOnBir,
          competitions: 3,
          awards: 1,
          lastPracticedAge: 13,
        ),
        SchoolClubProgress(
          clubId: _futbol.id,
          schoolId: 'lise',
          joinedAtAge: 15,
          joinedAtGrade: 9,
          yearsActive: 2,
          skill: 62,
          performance: 80,
          role: SquadRole.kaptan,
          captainSinceAge: 17,
          competitions: 2,
        ),
        SchoolClubProgress(
          clubId: _satranc.id,
          schoolId: 'lise',
          joinedAtAge: 13,
          joinedAtGrade: 7,
          yearsActive: 4,
          skill: 55,
        ),
      ]);

      final GameState geri = decodeGameState(encodeGameState(s));
      expect(geri.schoolClubs, hasLength(3));
      for (int i = 0; i < 3; i++) {
        final SchoolClubProgress a = s.schoolClubs[i];
        final SchoolClubProgress b = geri.schoolClubs[i];
        expect(b.clubId, a.clubId);
        expect(b.schoolId, a.schoolId);
        expect(b.joinedAtAge, a.joinedAtAge);
        expect(b.joinedAtGrade, a.joinedAtGrade);
        expect(b.active, a.active);
        expect(b.leftAtAge, a.leftAtAge);
        expect(b.yearsActive, a.yearsActive);
        expect(b.skill, a.skill);
        expect(b.performance, a.performance);
        expect(b.role, a.role);
        expect(b.captainSinceAge, a.captainSinceAge);
        expect(b.competitions, a.competitions);
        expect(b.awards, a.awards);
        expect(b.lastPracticedAge, a.lastPracticedAge);
      }
      // Futbol geçmişi toplamı da korunur.
      expect(geri.schoolClubs.seasonsInSport(kFootballSportId), 5);
      expect(geri.schoolClubs.wasCaptainInSport(kFootballSportId), isTrue);
    });

    test('eski kayıtta kulüp geçmişi yok → boş liste, uydurma yok', () {
      final GameState s = _ogrenci(17);
      final Map<String, Object?> json = encodeGameState(s);
      json.remove('schoolClubs');
      final GameState geri = decodeGameState(json);
      expect(geri.schoolClubs, isEmpty);
    });

    test('atletik potansiyel save/load sonrası yeniden çekilmez', () {
      final GameState s = _ogrenci(18);
      final int once = s.player.athleticPotential;
      final GameState geri = decodeGameState(encodeGameState(s));
      expect(geri.player.athleticPotential, once);
      // İki kez yüklemek de değiştirmemeli.
      final GameState tekrar = decodeGameState(encodeGameState(geri));
      expect(tekrar.player.athleticPotential, once);
    });

    test('alanı taşımayan eski kayıtta potansiyel deterministik', () {
      final GameState s = _ogrenci(19);
      final Map<String, Object?> json = encodeGameState(s);
      (json['player']! as Map<String, Object?>).remove('athleticPotential');
      final GameState a = decodeGameState(json);
      final GameState b = decodeGameState(json);
      expect(a.player.athleticPotential, b.player.athleticPotential,
          reason: 'Her yüklemede aynı değer çıkmalı, rastgele atılmamalı.');
      expect(a.player.athleticPotential, inInclusiveRange(0, 100));
    });
  });

  group('Okul bitince üyelik kapanır (Paket AW düzeltmesi)', () {
    // ÖLÇÜLEN HATA: sezon ilerlemesi öğrenci olup olmadığına bakmıyordu;
    // mezun olan oyuncunun üyeliği açık kalıyor ve yearsActive ömür boyu
    // artıyordu (500 hayatta toplam sezon medyanı 58, en fazla 160).
    test('mezun olan oyuncunun üyeliği kapanır, geçmişi kalır', () {
      GameState s = _ogrenci(3, age: 17, grade: 12, schoolId: 'okul-lise-1')
          .copyWith(
        schoolClubs: <SchoolClubProgress>[
          SchoolClubProgress(
            clubId: 'futbol_takimi',
            schoolId: 'okul-lise-1',
            joinedAtAge: 11,
            joinedAtGrade: 5,
            yearsActive: 6,
            skill: 60,
            performance: 60,
            role: SquadRole.ilkOnBir,
          ),
        ],
      );

      // Okul sürerken sezon ilerliyor.
      final ({GameState state, List<String> log, List<String> milestones})
          okulda = const SchoolClubEngine().advanceSeason(s, Random(4));
      expect(
        okulda.state.schoolClubs.activeFor('futbol_takimi')!.yearsActive,
        7,
      );

      // Okul bitince üyelik kapanıyor ve sezon ARTMIYOR.
      s = s.copyWith(
        education: const EducationState(finished: true, startedAtAge: 6),
      );
      final ({GameState state, List<String> log, List<String> milestones})
          mezun = const SchoolClubEngine().advanceSeason(s, Random(4));
      expect(mezun.state.schoolClubs.activeFor('futbol_takimi'), isNull);
      // Kayıt silinmedi; geçmiş duruyor.
      expect(mezun.state.schoolClubs, hasLength(1));
      expect(mezun.state.schoolClubs.first.yearsActive, 6);
      expect(mezun.state.schoolClubs.first.leftAtAge, 17);
      expect(mezun.log, isNotEmpty);
    });

    test('okul bittikten sonra sezon bir daha hiç artmaz', () {
      GameState s = _ogrenci(3, age: 40).copyWith(
        education: const EducationState(finished: true, startedAtAge: 6),
        schoolClubs: <SchoolClubProgress>[
          SchoolClubProgress(
            clubId: 'futbol_takimi',
            schoolId: 'okul-lise-1',
            joinedAtAge: 11,
            joinedAtGrade: 5,
            yearsActive: 8,
            skill: 70,
            performance: 60,
            role: SquadRole.kaptan,
            captainSinceAge: 16,
          ),
        ],
      );
      for (int i = 0; i < 20; i++) {
        s = const SchoolClubEngine().advanceSeason(s, Random(i)).state;
      }
      expect(s.schoolClubs.first.yearsActive, 8);
      expect(s.schoolClubs.activeOnes, isEmpty);
    });
  });
}

/// Küme içinde arama; test okunurluğu için ayrı tutuldu.
bool bilenenIcerir(Set<String> bilinen, String h) => bilinen.contains(h);
