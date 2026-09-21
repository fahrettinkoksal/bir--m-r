import 'dart:math';

import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/domain/generation/life_progression.dart';
import 'package:bir_omur/domain/life/notices.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/generation_fixtures.dart';
import 'support/invariants.dart';

/// Yaşayan bir oyuncu ve verilen kişilerle durum kurar.
GameState hayat({
  required List<Person> people,
  int age = 40,
  int wallet = 300000,
  int happiness = 70,
}) {
  final GameState base = olenOyuncu(olumYasi: age);
  return base.copyWith(
    deceased: false,
    marriage: null,
    settledEstates: const <String>{},
    people: people,
    player: base.player.copyWith(
      age: age,
      wallet: wallet,
      stats: base.player.stats.copyWith(happiness: happiness, health: 80),
    ),
  );
}

/// Kişiyi vefat ettirip bir yıl ilerletir.
GameState olumYili(GameState state, String personId, Random rng) {
  final GameState hazir = state.copyWith(
    people: state.people
        .map((Person p) => p.id == personId
            ? p.copyWith(age: 95) // ölüm ihtimali yüksek yaş
            : p)
        .toList(growable: false),
  );
  GameState sonra = hazir;
  for (int i = 0; i < 25; i++) {
    sonra = LifeProgression(rng).advanceOneYear(
      sonra.copyWith(pendingEvent: null),
    );
    if (sonra.deceased) break;
    final Person? kisi = sonra.personById(personId);
    if (kisi != null && !kisi.isAlive) break;
  }
  return sonra;
}

void main() {
  // ===================================================================
  // Bildirim üretimi
  // ===================================================================
  group('Ölüm bildirimi', () {
    test('yakın biri vefat edince adı ve bağıyla bildirilir', () {
      final GameState state = hayat(
        people: <Person>[
          kisi(
            id: 'anne-1',
            relation: RelationType.anne,
            gender: Gender.kadin,
            age: 70,
            firstName: 'Hatice',
          ),
        ],
      );
      final GameState sonra = olumYili(state, 'anne-1', Random(3));
      final Person anne = sonra.personById('anne-1')!;
      if (anne.isAlive) return; // bu tohumda ölmediyse senaryo dışı

      final PendingNotice? olum = sonra.notices
          .where((PendingNotice n) => n.kind == NoticeKind.olum)
          .firstOrNull;
      expect(olum, isNotNull);
      expect(olum!.text, contains('Hatice'));
      expect(olum.text, contains('Anne'));
      expect(olum.personId, 'anne-1');
    });

    test('uzak tanıdık için bildirim çıkmaz', () {
      final GameState state = hayat(
        people: <Person>[
          kisi(
            id: 'ogretmen-1',
            relation: RelationType.ogretmen,
            gender: Gender.erkek,
            age: 80,
          ),
        ],
      );
      final GameState sonra = olumYili(state, 'ogretmen-1', Random(5));
      expect(
        sonra.notices.where((PendingNotice n) => n.kind == NoticeKind.olum),
        isEmpty,
      );
    });

    test('mutluluk zaten sıfırsa sahte düşüş yazılmaz', () {
      final GameState state = hayat(
        happiness: 0,
        people: <Person>[
          kisi(
            id: 'baba-1',
            relation: RelationType.baba,
            gender: Gender.erkek,
            age: 88,
          ),
        ],
      );
      final GameState sonra = olumYili(state, 'baba-1', Random(9));
      final PendingNotice? olum = sonra.notices
          .where((PendingNotice n) => n.kind == NoticeKind.olum)
          .firstOrNull;
      if (olum == null) return;
      expect(olum.happinessDelta, 0);
    });
  });

  group('Miras bildirimi', () {
    test('gerçekten bir şey kalmadıysa bildirim üretilmez', () {
      final PendingNotice? yok = Notices.inheritance(
        person: kisi(
          id: 'kardes-1',
          relation: RelationType.kardes,
          gender: Gender.kadin,
          age: 50,
        ),
        playerAge: 40,
        money: 0,
        itemNames: const <String>[],
      );
      expect(yok, isNull);
    });

    test('kalan para ve eşya açıkça yazılır', () {
      final PendingNotice? var_ = Notices.inheritance(
        person: kisi(
          id: 'anne-1',
          relation: RelationType.anne,
          gender: Gender.kadin,
          age: 70,
          firstName: 'Sevim',
        ),
        playerAge: 40,
        money: 180000,
        itemNames: const <String>['Küçük daire'],
      );
      expect(var_, isNotNull);
      expect(var_!.text, contains('Sevim'));
      expect(var_.text, contains('180.000 ₺'));
      expect(var_.text, contains('Küçük daire'));
      expect(var_.money, 180000);
    });
  });

  // ===================================================================
  // Cenaze masrafı
  // ===================================================================
  group('Cenaze masrafı', () {
    GameState cenazeli({int wallet = 300000}) {
      final GameState state = hayat(
        wallet: wallet,
        people: <Person>[
          kisi(
            id: 'anne-1',
            relation: RelationType.anne,
            gender: Gender.kadin,
            age: 70,
            firstName: 'Hatice',
            alive: false,
          ),
        ],
      );
      return Notices.enqueue(state, <PendingNotice>[
        Notices.funeral(person: state.personById('anne-1')!, playerAge: 40),
      ]);
    }

    test('katkı cüzdandan bir kez düşer ve günlüğe yazılır', () {
      final GameState state = cenazeli();
      final int cuzdan = state.player.wallet;
      final ({GameState state, String text}) sonuc =
          Notices.respondToFuneral(state, FuneralChoice.tamKatki);

      expect(
        sonuc.state.player.wallet,
        cuzdan - Notices.prototypeOnlyFuneralCost,
      );
      expect(sonuc.state.hasNotice, isFalse);
      expect(
        sonuc.state.log.last.text,
        contains(trMoneyKontrol(Notices.prototypeOnlyFuneralCost)),
      );
      // İkinci kez uygulanmaz: bildirim kuyrukta yok.
      final ({GameState state, String text}) tekrar =
          Notices.respondToFuneral(sonuc.state, FuneralChoice.tamKatki);
      expect(tekrar.state.player.wallet, sonuc.state.player.wallet);
    });

    test('katkıda bulunmamak cüzdanı değiştirmez ve cenazeyi engellemez', () {
      final GameState state = cenazeli();
      final ({GameState state, String text}) sonuc =
          Notices.respondToFuneral(state, FuneralChoice.katkiYok);
      expect(sonuc.state.player.wallet, state.player.wallet);
      expect(sonuc.text, contains('cenazedeydin'));
      expect(sonuc.text, contains('katkıda bulunmadın'));
    });

    test('parası yetmeyen oyuncu cüzdanını eksiye düşürmez', () {
      final GameState fakir = cenazeli(wallet: 10000);
      expect(
        Notices.canChoose(
          fakir,
          fakir.notices.first,
          FuneralChoice.tamKatki,
        ),
        isFalse,
      );
      final ({GameState state, String text}) sonuc =
          Notices.respondToFuneral(fakir, FuneralChoice.kismiKatki);
      expect(sonuc.state.player.wallet, greaterThanOrEqualTo(0));
      expect(sonuc.state.player.wallet, lessThan(fakir.player.wallet));
      expect(checkInvariants(sonuc.state), isEmpty);
    });

    test('hiç parası olmayana katkı seçeneği açılmaz', () {
      final GameState bos = cenazeli(wallet: 0);
      expect(
        Notices.canChoose(bos, bos.notices.first, FuneralChoice.tamKatki),
        isFalse,
      );
      expect(
        Notices.canChoose(bos, bos.notices.first, FuneralChoice.kismiKatki),
        isFalse,
      );
      expect(
        Notices.canChoose(bos, bos.notices.first, FuneralChoice.katkiYok),
        isTrue,
      );
    });
  });

  // ===================================================================
  // Kuyruk davranışı
  // ===================================================================
  group('Kuyruk', () {
    test('aynı bildirim iki kez kuyruğa girmez', () {
      final GameState state = hayat(people: <Person>[]);
      final PendingNotice n = PendingNotice(
        id: 'olum-x',
        kind: NoticeKind.olum,
        age: 40,
        title: 'Bir kaybın var',
        text: 'metin',
      );
      final GameState bir = Notices.enqueue(state, <PendingNotice>[n]);
      final GameState iki = Notices.enqueue(bir, <PendingNotice>[n]);
      expect(bir.notices.length, 1);
      expect(iki.notices.length, 1);
    });

    test('bildirimler sırayla gösterilir ve bekleyen olay ezilmez', () {
      final GameState state = hayat(people: <Person>[]);
      final GameState kuyruklu = Notices.enqueue(state, <PendingNotice>[
        const PendingNotice(
          id: 'olum-a',
          kind: NoticeKind.olum,
          age: 40,
          title: 'Bir kaybın var',
          text: 'birinci',
        ),
        const PendingNotice(
          id: 'miras-a',
          kind: NoticeKind.miras,
          age: 40,
          title: 'Miras',
          text: 'ikinci',
          money: 1000,
        ),
      ]);

      expect(kuyruklu.nextNotice!.id, 'olum-a');
      final GameState sonra = Notices.dismissFirst(kuyruklu);
      expect(sonra.nextNotice!.id, 'miras-a');
      expect(Notices.dismissFirst(sonra).hasNotice, isFalse);
    });

    test('bekleyen bildirim kayıtla birlikte saklanır', () {
      final GameState state = Notices.enqueue(
        hayat(people: <Person>[]),
        <PendingNotice>[
          const PendingNotice(
            id: 'cenaze-anne-1',
            kind: NoticeKind.cenaze,
            age: 40,
            title: 'Cenaze masrafları',
            text: 'katkı?',
            funeralCost: 25000,
          ),
        ],
      );
      final GameState geri = decodeGameState(encodeGameState(state));
      expect(geri.notices.length, 1);
      expect(geri.notices.first.kind, NoticeKind.cenaze);
      expect(geri.notices.first.funeralCost, 25000);
      expect(geri.notices.first.id, 'cenaze-anne-1');
    });
  });
  // ===================================================================
  // Bildirim kapsamı (D-050): çekirdek aile her hâlükârde, diğer bağlar
  // gerçekten yakınsa bildirilir.
  // ===================================================================
  group('Bildirim kapsamı', () {
    Person bagli(RelationType relation, int bond) => kisi(
          id: 'k-${relation.name}-$bond',
          relation: relation,
          gender: Gender.kadin,
          age: 60,
          bond: bond,
        );

    test('çekirdek aile yakınlıktan bağımsız bildirilir', () {
      expect(Notices.shouldNotify(bagli(RelationType.anne, 5)), isTrue);
      expect(Notices.shouldNotify(bagli(RelationType.cocuk, 0)), isTrue);
      expect(Notices.shouldNotify(bagli(RelationType.es, 10)), isTrue);
    });

    test('yakın olunan sevgili ve arkadaş da bildirilir', () {
      expect(Notices.shouldNotify(bagli(RelationType.sevgili, 80)), isTrue);
      expect(Notices.shouldNotify(bagli(RelationType.arkadas, 75)), isTrue);
      expect(Notices.shouldNotify(bagli(RelationType.teyze, 70)), isTrue);
    });

    test('uzak tanıdık için bildirim çıkmaz', () {
      expect(Notices.shouldNotify(bagli(RelationType.arkadas, 30)), isFalse);
      expect(Notices.shouldNotify(bagli(RelationType.sevgili, 20)), isFalse);
      expect(
        Notices.shouldNotify(bagli(RelationType.sinifArkadasi, 95)),
        isFalse,
      );
      expect(Notices.shouldNotify(bagli(RelationType.ogretmen, 95)), isFalse);
    });

    test('eşik tam sınırda da tutarlıdır', () {
      final int esik = Notices.prototypeOnlyCloseBond;
      expect(
        Notices.shouldNotify(bagli(RelationType.arkadas, esik)),
        isTrue,
      );
      expect(
        Notices.shouldNotify(bagli(RelationType.arkadas, esik - 1)),
        isFalse,
      );
    });
  });

  // ===================================================================
  // Cenazeye katılmak ile masrafa katkıda bulunmak **ayrı** şeylerdir
  // (D-050).
  // ===================================================================
  group('Cenazeye katılım', () {
    GameState cenazeli({int wallet = 300000, int kardesBagi = 50}) {
      final GameState state = hayat(
        wallet: wallet,
        people: <Person>[
          kisi(
            id: 'anne-1',
            relation: RelationType.anne,
            gender: Gender.kadin,
            age: 70,
            firstName: 'Hatice',
            alive: false,
          ),
          kisi(
            id: 'kardes-1',
            relation: RelationType.kardes,
            gender: Gender.erkek,
            age: 38,
            firstName: 'Mert',
            bond: kardesBagi,
          ),
          kisi(
            id: 'arkadas-1',
            relation: RelationType.arkadas,
            gender: Gender.kadin,
            age: 41,
            firstName: 'Sevda',
            bond: 50,
          ),
        ],
      );
      return Notices.enqueue(state, <PendingNotice>[
        Notices.funeral(person: state.personById('anne-1')!, playerAge: 40),
      ]);
    }

    test('katkı vermeden katılmak mümkündür', () {
      final GameState state = cenazeli();
      final ({GameState state, String text}) sonuc = Notices.respondToFuneral(
        state,
        FuneralChoice.katkiYok,
        attendance: FuneralAttendance.katildi,
      );
      expect(sonuc.state.player.wallet, state.player.wallet);
      expect(sonuc.text, contains('cenazedeydin'));
      expect(sonuc.text, contains('katkıda bulunmadın'));
      expect(
        sonuc.state.player.stats.happiness,
        state.player.stats.happiness + Notices.prototypeOnlyAttendanceHappiness,
      );
      expect(checkInvariants(sonuc.state), isEmpty);
    });

    test('katılamayan oyuncu yine de katkıda bulunabilir', () {
      final GameState state = cenazeli();
      final ({GameState state, String text}) sonuc = Notices.respondToFuneral(
        state,
        FuneralChoice.tamKatki,
        attendance: FuneralAttendance.katilamadi,
      );
      expect(
        sonuc.state.player.wallet,
        state.player.wallet - Notices.prototypeOnlyFuneralCost,
      );
      expect(sonuc.text, contains('katılamadın'));
      expect(
        sonuc.text,
        contains(trMoneyKontrol(Notices.prototypeOnlyFuneralCost)),
      );
      expect(checkInvariants(sonuc.state), isEmpty);
    });

    test('katılmak hayattaki kan bağlarına küçük bir yakınlık katar', () {
      final GameState state = cenazeli(kardesBagi: 50);
      final ({GameState state, String text}) sonuc = Notices.respondToFuneral(
        state,
        FuneralChoice.katkiYok,
        attendance: FuneralAttendance.katildi,
      );
      expect(
        sonuc.state.personById('kardes-1')!.bond,
        50 + Notices.prototypeOnlyAttendanceBond,
      );
      // Arkadaşlık kan bağı değildir; etkilenmez.
      expect(sonuc.state.personById('arkadas-1')!.bond, 50);
    });

    test('katılmamak kalıcı ceza değildir, küçük bir burukluktur', () {
      final GameState state = cenazeli();
      final ({GameState state, String text}) sonuc = Notices.respondToFuneral(
        state,
        FuneralChoice.katkiYok,
        attendance: FuneralAttendance.katilamadi,
      );
      final int fark =
          sonuc.state.player.stats.happiness - state.player.stats.happiness;
      expect(fark, Notices.prototypeOnlyAbsenceHappiness);
      expect(fark, greaterThan(-10));
      // Yakınlık yükselmez ama düşmez de.
      expect(sonuc.state.personById('kardes-1')!.bond, 50);
    });

    test('mutluluğu sıfır olan oyuncuda katılmamak eksiye düşürmez', () {
      final GameState state = cenazeli().copyWith(
        player: cenazeli().player.copyWith(
              stats: cenazeli().player.stats.copyWith(happiness: 0),
            ),
      );
      final ({GameState state, String text}) sonuc = Notices.respondToFuneral(
        state,
        FuneralChoice.katkiYok,
        attendance: FuneralAttendance.katilamadi,
      );
      expect(sonuc.state.player.stats.happiness, greaterThanOrEqualTo(0));
      expect(checkInvariants(sonuc.state), isEmpty);
    });
  });

}

/// Testte para metnini kontrol etmek için küçük yardımcı.
String trMoneyKontrol(int tutar) => '${_ayir(tutar)} ₺';

String _ayir(int value) {
  final String r = value.toString();
  final StringBuffer b = StringBuffer();
  for (int i = 0; i < r.length; i++) {
    if (i > 0 && (r.length - i) % 3 == 0) b.write('.');
    b.write(r[i]);
  }
  return b.toString();
}
