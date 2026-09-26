
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/domain/economy/financial_strain.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/interaction/bond_decay.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/loan.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:flutter_test/flutter_test.dart';

/// Paket G: bildirilen gerçek hatalar (D-091 … D-093).
void main() {
  GameState hayat(int seed, {int age = 40, int wallet = 100000}) {
    final GameState base =
        LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
    return base.copyWith(
      player: base.player.copyWith(age: age, wallet: wallet),
    );
  }

  Person cocuk({int bond = 100, int age = 30}) => Person(
        id: 'cocuk-1',
        firstName: 'Elif',
        lastName: 'Demir',
        gender: Gender.kadin,
        relation: RelationType.cocuk,
        age: age,
        isAlive: true,
        inPlayerHousehold: false,
        employment: EmploymentStatus.calisiyor,
        occupation: 'öğretmen',
        wealth: WealthTier.ortaHalli,
        bond: bond,
      );

  group('Mali durum gerçek hesapla ölçülür (D-092)', () {
    test('milyoneri yoksulluk kademesine sokmaz', () {
      final GameState zengin = hayat(1, wallet: 3000000);
      expect(FinancialStrain.isStrained(zengin), isFalse,
          reason: 'Cüzdanında 3 milyon olan oyuncu sıkıntıda sayılamaz');
      expect(
        FinancialStrain.comfortOf(zengin).index,
        greaterThanOrEqualTo(FinancialComfort.idare.index),
      );
    });

    test('parasız ve gelirsiz oyuncu sıkıntıda sayılır', () {
      final GameState fakir = hayat(2, wallet: 0);
      expect(
        FinancialStrain.comfortOf(fakir).index,
        lessThanOrEqualTo(FinancialComfort.zor.index),
      );
    });

    test('kredi taksiti rahatlığı düşürür', () {
      final GameState borcsuz = hayat(3, wallet: 400000);
      final GameState borclu = borcsuz.copyWith(
        loans: <Loan>[
          const Loan(
            id: 'k1',
            bank: Bank.bankavrupa,
            principal: 500000,
            annualPayment: 300000,
            termYears: 3,
            remainingPayments: 3,
            outstanding: 900000,
            takenAtAge: 38,
          ),
        ],
      );
      expect(
        FinancialStrain.ratio(borclu),
        lessThan(FinancialStrain.ratio(borcsuz)),
      );
    });

    test('kademeler sıralıdır', () {
      expect(FinancialComfort.sikinti.index,
          lessThan(FinancialComfort.zor.index));
      expect(
          FinancialComfort.zor.index, lessThan(FinancialComfort.idare.index));
      expect(FinancialComfort.idare.index,
          lessThan(FinancialComfort.rahat.index));
      expect(FinancialComfort.rahat.index,
          lessThan(FinancialComfort.varlikli.index));
      expect(FinancialComfort.sikinti.isStrained, isTrue);
      expect(FinancialComfort.varlikli.isStrained, isFalse);
    });

    test('geçim sıkıntısı yılı doğrudan sıkıntı sayılır', () {
      final GameState s = hayat(4, wallet: 5000000).copyWith(hardshipYears: 2);
      expect(FinancialStrain.comfortOf(s), FinancialComfort.sikinti);
    });
  });

  group('İlgisizlik hızlanarak düşürür (D-093)', () {
    /// [yil] yıl hiç görüşülmemiş kişinin yakınlığı.
    int yakinlikSonrasi(Person kisi, int yil) {
      int bond = kisi.bond;
      for (int gecen = 1; gecen <= yil; gecen++) {
        if (gecen <= BondDecay.prototypeOnlyGraceYears) continue;
        final int ihmal = gecen - BondDecay.prototypeOnlyGraceYears;
        final int taban = BondDecay.floorFor(kisi);
        bond = (bond - BondDecay.lossFor(kisi, yearsNeglected: ihmal))
            .clamp(taban, 100);
      }
      return bond;
    }

    test('16 yıl görüşülmeyen çocukla yüksek yakınlık kalmaz', () {
      // Faho'nun bildirdiği hata: "16 yıldır görüşmediğim kızımla
      // yakınlığım neredeyse 100."
      final int sonra = yakinlikSonrasi(cocuk(), 16);
      expect(sonra, lessThan(60), reason: 'ölçülen: $sonra');
    });

    test('ilk iki yıl hoşgörü var', () {
      expect(yakinlikSonrasi(cocuk(), 1), 100);
      expect(yakinlikSonrasi(cocuk(), 2), 100);
    });

    test('kayıp zamanla hızlanır', () {
      final int besYil = 100 - yakinlikSonrasi(cocuk(), 5);
      final int onYil = 100 - yakinlikSonrasi(cocuk(), 10);
      final int onBesYil = 100 - yakinlikSonrasi(cocuk(), 15);
      // Her beş yıllık dilimde kayıp bir öncekinden büyük olmalı.
      expect(onYil - besYil, greaterThan(besYil));
      expect(onBesYil - onYil, greaterThan(onYil - besYil));
    });

    test('kan bağı tabanın altına inmez', () {
      final int cokUzun = yakinlikSonrasi(cocuk(), 60);
      expect(cokUzun, BondDecay.prototypeOnlyBloodFloor);
      expect(cokUzun, greaterThan(0), reason: 'Aile bağı sıfırlanmaz');
    });

    test('hızlanma çarpanı monoton artar', () {
      double onceki = 0;
      for (int yil = 0; yil <= 20; yil++) {
        final double simdi = BondDecay.accelerationFor(yil);
        expect(simdi, greaterThanOrEqualTo(onceki));
        onceki = simdi;
      }
    });

    test('yıllık kayıp hiç sıfır olmaz', () {
      for (int yil = 0; yil <= 30; yil++) {
        expect(
          BondDecay.lossFor(cocuk(), yearsNeglected: yil),
          greaterThanOrEqualTo(1),
        );
      }
    });

    test('gerçek akışta uzun ilgisizlik yakınlığı düşürür', () {
      GameState s = hayat(5).copyWith(
        people: <Person>[cocuk()],
        lastInteractionAge: <String, int>{'cocuk-1': 40},
      );
      for (int i = 0; i < 16; i++) {
        s = s.copyWith(
          player: s.player.copyWith(age: s.player.age + 1),
        );
        final BondDecayResult r = BondDecay.applyYear(s);
        s = s.copyWith(
          people: r.people,
          lastInteractionAge: r.lastInteractionAge,
        );
      }
      final int sonra = s.personById('cocuk-1')!.bond;
      expect(sonra, lessThan(60), reason: 'ölçülen: $sonra');
      expect(sonra, greaterThanOrEqualTo(BondDecay.prototypeOnlyBloodFloor));
    });

    test('görüşülen çocukta yakınlık düşmez', () {
      GameState s = hayat(6).copyWith(people: <Person>[cocuk()]);
      for (int i = 0; i < 16; i++) {
        s = s.copyWith(
          player: s.player.copyWith(age: s.player.age + 1),
          // Her yıl temas var.
          lastInteractionAge: <String, int>{'cocuk-1': s.player.age + 1},
        );
        final BondDecayResult r = BondDecay.applyYear(s);
        s = s.copyWith(people: r.people);
      }
      expect(s.personById('cocuk-1')!.bond, 100);
    });

    test('yakınlık kapat-aç ile korunur', () {
      final GameState s = hayat(7).copyWith(people: <Person>[cocuk(bond: 42)]);
      final GameState geri = decodeGameState(encodeGameState(s));
      expect(geri.personById('cocuk-1')!.bond, 42);
    });
  });
}
