import 'dart:math';

import 'package:bir_omur/data/economy.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/domain/economy/banking.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/interaction/family_interactions.dart';
import 'package:bir_omur/domain/models/career.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/interaction.dart';
import 'package:bir_omur/domain/models/loan.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:bir_omur/text/turkish_text.dart';
import 'package:flutter_test/flutter_test.dart';

/// Paket M: konut kredisi, kredi karnesi ve harçlık geri bildirimi (D-108).
void main() {
  GameState calisan({int seed = 5, int age = 30, int? salary}) {
    final GameState base =
        LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
    return base.copyWith(
      pendingEvent: null,
      player: base.player.copyWith(age: age, wallet: 200000),
      career: CareerState(
        jobId: 'ogretmen',
        startedAtAge: age - 5,
        salary: salary ?? Economy.netYearlyMinimumWage * 3,
      ),
    );
  }

  group('Konut kredisi (D-108)', () {
    test('konut kredisi ihtiyaç kredisinden ucuzdur', () {
      for (final Bank b in Bank.values) {
        expect(
          b.monthlyRateFor(LoanPurpose.konut),
          lessThan(b.monthlyRateFor(LoanPurpose.ihtiyac)),
        );
      }
    });

    test('konut kredisinde vade daha uzun, taban tutar daha yüksek', () {
      expect(
        Banking.maxTermFor(LoanPurpose.konut),
        greaterThan(Banking.maxTermFor(LoanPurpose.ihtiyac)),
      );
      expect(
        Banking.minAmountFor(LoanPurpose.konut),
        greaterThan(Banking.minAmountFor(LoanPurpose.ihtiyac)),
      );
    });

    test('küçük tutar için konut kredisi açılmaz, sebebi yazar', () {
      final GameState s = calisan();
      final String? engel = Banking.blockReason(
        s,
        amount: Banking.minAmount,
        purpose: LoanPurpose.konut,
      );
      expect(engel, isNotNull);
      expect(engel, contains('Konut kredisi'));
    });

    test('aynı tutar ve vadede konut taksiti daha düşüktür', () {
      const int tutar = 2000000;
      const int vade = 3;
      for (final Bank b in Bank.values) {
        final int ihtiyac = Banking.annualPaymentFor(
          amount: tutar,
          termYears: vade,
          bank: b,
        );
        final int konut = Banking.annualPaymentFor(
          amount: tutar,
          termYears: vade,
          bank: b,
          purpose: LoanPurpose.konut,
        );
        expect(konut, lessThan(ihtiyac));
      }
    });

    test('konut kredisi çekilir ve amacı kayıtta korunur', () {
      final GameState s = calisan(salary: Economy.netYearlyMinimumWage * 12);
      final ({GameState state, LoanDecision decision}) sonuc = Banking.borrow(
        s,
        bank: Bank.bankavrupa,
        amount: Banking.minHousingAmount,
        termYears: 10,
        purpose: LoanPurpose.konut,
      );
      expect(sonuc.decision.approved, isTrue, reason: sonuc.decision.reason);
      final Loan kredi = sonuc.state.loans.single;
      expect(kredi.purpose, LoanPurpose.konut);
      expect(kredi.termYears, 10);

      final GameState geri = decodeGameState(encodeGameState(sonuc.state));
      expect(geri.loans.single.purpose, LoanPurpose.konut);
    });

    test('örnek taksitler ölçülür', () {
      final List<String> satirlar = <String>[];
      for (final LoanPurpose p in LoanPurpose.values) {
        for (final Bank b in Bank.values) {
          final int tutar = p == LoanPurpose.konut ? 3000000 : 300000;
          final int vade = p == LoanPurpose.konut ? 10 : 3;
          final int taksit = Banking.annualPaymentFor(
            amount: tutar,
            termYears: vade,
            bank: b,
            purpose: p,
          );
          satirlar.add('${p.label} · ${b.label} · ${trMoney(tutar)} / '
              '$vade yıl -> yıllık ${trMoney(taksit)}, toplam '
              '${trMoney(taksit * vade)}');
        }
      }
      // ignore: avoid_print
      print('KREDI ORNEKLERI:\n  ${satirlar.join('\n  ')}');
      expect(satirlar, hasLength(4));
    });
  });

  group('Kredi karnesi (D-108)', () {
    test('kredisi olmayan oyuncu iyi durumdadır', () {
      expect(Banking.standingOf(calisan()), CreditStanding.iyi);
    });

    test('bir kaçan taksit riskli, ikisi çok riskli yapar', () {
      GameState s = calisan();
      const Loan kredi = Loan(
        id: 'k1',
        bank: Bank.fakbank,
        principal: 100000,
        annualPayment: 50000,
        termYears: 3,
        remainingPayments: 3,
        outstanding: 150000,
        takenAtAge: 28,
        missedPayments: 1,
      );
      s = s.copyWith(loans: const <Loan>[kredi]);
      expect(Banking.standingOf(s), CreditStanding.riskli);

      s = s.copyWith(
        loans: <Loan>[kredi.copyWith(missedPayments: 2)],
      );
      expect(Banking.standingOf(s), CreditStanding.cokRiskli);
    });

    test('ağır taksit yükü orta ve riskli kademeye taşır', () {
      final GameState taban =
          calisan(salary: Economy.netYearlyMinimumWage * 2);
      final int gelir = Banking.assessedIncome(taban);

      Loan yukle(int taksit) => Loan(
            id: 'k',
            bank: Bank.fakbank,
            principal: 100000,
            annualPayment: taksit,
            termYears: 3,
            remainingPayments: 3,
            outstanding: 300000,
            takenAtAge: 28,
          );

      expect(
        Banking.standingOf(taban.copyWith(loans: <Loan>[yukle((gelir * 0.1).round())])),
        CreditStanding.iyi,
      );
      expect(
        Banking.standingOf(taban.copyWith(loans: <Loan>[yukle((gelir * 0.3).round())])),
        CreditStanding.orta,
      );
      expect(
        Banking.standingOf(taban.copyWith(loans: <Loan>[yukle((gelir * 0.5).round())])),
        CreditStanding.riskli,
      );
    });

    test('dört kademenin de kendi açıklaması vardır', () {
      for (final CreditStanding c in CreditStanding.values) {
        expect(c.label, isNotEmpty);
        expect(c.description, isNotEmpty);
      }
      expect(CreditStanding.values, hasLength(4));
    });
  });

  test('harçlık sonucunda alınan tutar yazılır (D-108)', () {
    GameState s = calisan(age: 12);
    // Para verebilecek bir yakın bulunur.
    final Person veren = s.people.firstWhere(
      (Person p) =>
          p.isAlive && p.wealth != null && p.relation == RelationType.anne,
      orElse: () => s.people.firstWhere(
        (Person p) => p.isAlive && p.wealth != null,
      ),
    );
    s = s.copyWith(
      people: s.people
          .map((Person p) =>
              p.id == veren.id ? p.copyWith(wealth: WealthTier.varlikli) : p)
          .toList(growable: false),
    );

    for (int seed = 0; seed < 40; seed++) {
      final InteractionResult r = const FamilyInteractions().perform(
        state: s,
        personId: veren.id,
        kind: InteractionKind.paraIste,
        rng: Random(seed),
      );
      if (!r.outcome.accepted || r.outcome.moneyDelta <= 0) continue;
      expect(r.outcome.text, contains('Cüzdanına'));
      expect(r.outcome.text, contains(trMoney(r.outcome.moneyDelta)));
      return;
    }
    fail('Harçlık verilen bir durum bulunamadı');
  });
}
