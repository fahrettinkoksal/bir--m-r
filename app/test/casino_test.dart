import 'dart:convert';
import 'dart:math';

import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/data/save/save_format.dart';
import 'package:bir_omur/data/save/save_service.dart';
import 'package:bir_omur/data/save/save_store.dart';
import 'package:bir_omur/domain/casino/blackjack.dart';
import 'package:bir_omur/domain/casino/casino_rules.dart';
import 'package:bir_omur/domain/casino/roulette.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/generation/life_progression.dart';
import 'package:bir_omur/domain/models/blackjack_game.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/playing_card.dart';
import 'package:flutter_test/flutter_test.dart';

const Blackjack blackjack = Blackjack();
const Roulette roulette = Roulette();

GameState oyuncu(int seed, {int age = 25, int wallet = 20000}) {
  final GameState state =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  return state.copyWith(
    player: state.player.copyWith(age: age, wallet: wallet),
  );
}

/// Belirli kartlarla kurulmuş bir el; kural testleri için.
GameState masa(
  GameState state, {
  required List<PlayingCard> oyuncuKartlari,
  required List<PlayingCard> krupiyeKartlari,
  List<PlayingCard> deste = const <PlayingCard>[],
  int bet = 100,
  bool betDusuldu = true,
}) =>
    state.copyWith(
      player: state.player.copyWith(
        wallet: betDusuldu ? state.player.wallet - bet : state.player.wallet,
      ),
      blackjack: BlackjackGame(
        bet: bet,
        deck: List<PlayingCard>.unmodifiable(deste),
        playerCards: List<PlayingCard>.unmodifiable(oyuncuKartlari),
        dealerCards: List<PlayingCard>.unmodifiable(krupiyeKartlari),
        phase: BlackjackPhase.oyuncu,
        startedAtAge: state.player.age,
      ),
    );

PlayingCard kart(int rank, [CardSuit suit = CardSuit.maca]) =>
    PlayingCard(rank, suit);

void main() {
  // ===================================================================
  // Kart ve el değerleri
  // ===================================================================
  group('Deste ve el değerleri', () {
    test('deste 52 farklı karttan oluşur', () {
      final List<PlayingCard> deste = shuffledDeck(Random(1));
      expect(deste.length, 52);
      expect(deste.toSet().length, 52);
      expect(deste.where((PlayingCard c) => c.rank == 1).length, 4);
      expect(deste.where((PlayingCard c) => c.suit == CardSuit.kupa).length, 13);
    });

    test('resimli kartlar 10, as 1 veya 11 sayılır', () {
      expect(kart(13).blackjackValue, 10);
      expect(kart(12).blackjackValue, 10);
      expect(kart(11).blackjackValue, 10);
      expect(kart(1).blackjackValue, 1);

      expect(handValue(<PlayingCard>[kart(1), kart(13)]).total, 21);
      expect(handValue(<PlayingCard>[kart(1), kart(13)]).soft, isTrue);
      // İki as: biri 11, diğeri 1.
      expect(handValue(<PlayingCard>[kart(1), kart(1)]).total, 12);
      // As 11 sayılırsa 21 aşılıyorsa 1 sayılır.
      expect(
        handValue(<PlayingCard>[kart(1), kart(9), kart(5)]).total,
        15,
      );
      expect(
        handValue(<PlayingCard>[kart(1), kart(9), kart(5)]).soft,
        isFalse,
      );
    });

    test('kart kodu geri okunabilir', () {
      for (final PlayingCard c in shuffledDeck(Random(2))) {
        expect(PlayingCard.fromCode(c.code), c);
      }
      expect(PlayingCard.fromCode('bozuk'), isNull);
    });
  });

  // ===================================================================
  // Erişim ve bahis sınırları
  // ===================================================================
  group('Kumarhaneye giriş', () {
    test('18 yaşından küçük oynayamaz', () {
      final GameState kucuk = oyuncu(3, age: 16);
      expect(CasinoAccess.check(kucuk).isAllowed, isFalse);
      final CasinoResult r = blackjack.deal(kucuk, 1000, Random(1));
      expect(r.outcome.applied, isFalse);
      expect(r.state.blackjack, isNull);
      expect(r.state.player.wallet, kucuk.player.wallet);
    });

    test('bakiyesi yetmeyen bahis oynanamaz', () {
      final GameState fakir = oyuncu(4, wallet: 400);
      final CasinoResult r = blackjack.deal(fakir, 1000, Random(1));
      expect(r.outcome.applied, isFalse);
      expect(r.state.player.wallet, 400, reason: 'Cüzdan değişmemeli');
      expect(r.state.player.wallet, greaterThanOrEqualTo(0));
    });

    test('bahis alt ve üst sınırın dışına çıkamaz', () {
      final GameState zengin = oyuncu(5, wallet: 100000);
      expect(
        blackjack.deal(zengin, CasinoRules.prototypeOnlyMinBet - 1, Random(1))
            .outcome
            .applied,
        isFalse,
      );
      expect(
        blackjack
            .deal(zengin, CasinoAccess.maxBet(zengin) + 1, Random(1))
            .outcome
            .applied,
        isFalse,
      );
    });

    test('yıllık bahis bütçesi aşılamaz ve yaş dönünce yenilenir', () {
      // Bütçe her çağrıda **güncel cüzdandan** hesaplanıyor; oyuncu
      // kazandıkça bütçe de büyüyor. Eski tavan (150.000 ₺) bunu
      // maskeliyordu: 5.000.000 ₺ cüzdanın %5'i tavanı aştığı için bütçe
      // sabit kalıyordu. 2026 kalibrasyonunda tavan 450.000 ₺ olunca
      // bütçe yüzmeye başladı ve test kırıldı.
      //
      // Testin iddiası aynı kaldı; fixture bütçeyi yine tavana
      // sabitleyecek kadar büyütüldü. Bütçenin yıl içinde kaymasının
      // kendisi ayrı bir tasarım sorusudur (Q-115).
      GameState state = oyuncu(6, wallet: 12000000);
      final int butce = CasinoAccess.yearlyBudget(state);
      final int enFazla = CasinoAccess.maxBet(state);
      expect(butce, greaterThan(0));

      int oynanan = 0;
      for (int i = 0; i < 200; i++) {
        final CasinoResult r = roulette.spin(
          state,
          RouletteBetType.kirmizi,
          enFazla,
          Random(i),
        );
        if (!r.outcome.applied) break;
        state = r.state;
        oynanan += enFazla;
      }
      expect(oynanan, greaterThan(0));
      expect(state.wagerThisAge, oynanan);
      expect(
        roulette
            .spinAvailability(state, CasinoRules.prototypeOnlyMinBet)
            .isAllowed,
        isFalse,
        reason: 'Bütçe dolunca en küçük bahis bile açılmamalı',
      );

      // Yaş ilerleyince sayaç sıfırlanır.
      final GameState seneye = LifeProgression(Random(1)).advanceOneYear(state);
      expect(seneye.wagerThisAge, 0);
      expect(
        roulette
            .spinAvailability(seneye, CasinoRules.prototypeOnlyMinBet)
            .isAllowed,
        isTrue,
      );
    });
  });

  // ===================================================================
  // Blackjack kuralları
  // ===================================================================
  group('Blackjack', () {
    test('el açılınca bahis cüzdandan bir kez düşer', () {
      final GameState state = oyuncu(10, wallet: 500000);
      final CasinoResult r = blackjack.deal(state, 5000, Random(7));
      expect(r.outcome.applied, isTrue);
      final BlackjackGame oyun = r.state.blackjack!;
      expect(r.state.player.wallet, 500000 - 5000 + oyun.payout,
          reason: 'Bahis tam bir kez düşmeli');
      expect(oyun.bet, 5000);
      expect(oyun.playerCards.length, 2);
      expect(oyun.dealerCards.length, 2);
      expect(oyun.deck.length, 48);
      expect(r.state.wagerThisAge, 5000);
    });

    test('oyuncunun sırasında krupiyenin ikinci kartı gizlidir', () {
      final GameState state = masa(
        oyuncu(11),
        oyuncuKartlari: <PlayingCard>[kart(10), kart(6)],
        krupiyeKartlari: <PlayingCard>[kart(9), kart(7)],
      );
      final BlackjackGame oyun = state.blackjack!;
      expect(oyun.visibleDealerCards.length, 1);
      expect(oyun.visibleDealerTotal, 9);
      expect(oyun.isFinished, isFalse);
    });

    test('21 aşılınca el kaybedilir ve ödeme yapılmaz', () {
      final GameState state = masa(
        oyuncu(12, wallet: 10000),
        oyuncuKartlari: <PlayingCard>[kart(10), kart(9)],
        krupiyeKartlari: <PlayingCard>[kart(10), kart(7)],
        deste: <PlayingCard>[kart(5, CardSuit.kupa)],
        bet: 1000,
      );
      final int once = state.player.wallet;
      final CasinoResult r = blackjack.hit(state);

      expect(r.state.blackjack!.result, BlackjackResult.oyuncuBatti);
      expect(r.state.blackjack!.isFinished, isTrue);
      expect(r.state.player.wallet, once, reason: 'Kaybedince ödeme yok');
      expect(r.state.log.last.text, contains('Blackjack'));
    });

    test('doğal blackjack 3:2 öder', () {
      final GameState state = oyuncu(13, wallet: 100000);
      // As + papaz = doğal blackjack; krupiyede doğal yok.
      final GameState kurulu = masa(
        state,
        oyuncuKartlari: <PlayingCard>[kart(1), kart(13)],
        krupiyeKartlari: <PlayingCard>[kart(10), kart(7)],
        bet: 2000,
      );
      final int cuzdan = kurulu.player.wallet;
      final CasinoResult r = blackjack.stand(kurulu);

      expect(r.state.blackjack!.result, BlackjackResult.oyuncuBlackjack);
      expect(r.state.blackjack!.payout, 2000 + 3000);
      expect(r.state.player.wallet, cuzdan + 5000);
    });

    test('krupiye 17 ve üstünde durur', () {
      final GameState kurulu = masa(
        oyuncu(14),
        oyuncuKartlari: <PlayingCard>[kart(10), kart(8)],
        krupiyeKartlari: <PlayingCard>[kart(10), kart(6)],
        deste: <PlayingCard>[
          kart(2, CardSuit.kupa), // krupiye 18 olur, durur
          kart(9, CardSuit.karo),
        ],
      );
      final CasinoResult r = blackjack.stand(kurulu);
      final BlackjackGame oyun = r.state.blackjack!;
      expect(oyun.dealerTotal, 18);
      expect(oyun.dealerCards.length, 3, reason: '18 olunca durmalı');
      // Oyuncu da 18: krupiye 17 kuralında durduğu için el berabere biter.
      expect(oyun.result, BlackjackResult.berabere);
    });

    test('krupiye 21 aşarsa oyuncu 1:1 kazanır', () {
      final GameState kurulu = masa(
        oyuncu(15, wallet: 30000),
        oyuncuKartlari: <PlayingCard>[kart(10), kart(7)],
        krupiyeKartlari: <PlayingCard>[kart(10), kart(6)],
        deste: <PlayingCard>[kart(10, CardSuit.kupa)],
        bet: 3000,
      );
      final int cuzdan = kurulu.player.wallet;
      final CasinoResult r = blackjack.stand(kurulu);
      expect(r.state.blackjack!.result, BlackjackResult.krupiyeBatti);
      expect(r.state.player.wallet, cuzdan + 6000);
    });

    test('beraberlikte bahis geri gelir', () {
      final GameState kurulu = masa(
        oyuncu(16, wallet: 20000),
        oyuncuKartlari: <PlayingCard>[kart(10), kart(8)],
        krupiyeKartlari: <PlayingCard>[kart(10), kart(8)],
        bet: 4000,
      );
      final int cuzdan = kurulu.player.wallet;
      final CasinoResult r = blackjack.stand(kurulu);
      expect(r.state.blackjack!.result, BlackjackResult.berabere);
      expect(r.state.player.wallet, cuzdan + 4000);
      expect(r.state.blackjack!.netGain, 0);
    });

    test('ödeme iki kez uygulanmaz', () {
      final GameState kurulu = masa(
        oyuncu(17, wallet: 20000),
        oyuncuKartlari: <PlayingCard>[kart(10), kart(9)],
        krupiyeKartlari: <PlayingCard>[kart(10), kart(7)],
        bet: 2000,
      );
      final CasinoResult ilk = blackjack.stand(kurulu);
      expect(ilk.state.blackjack!.settled, isTrue);
      final int cuzdan = ilk.state.player.wallet;
      final int gunluk = ilk.state.log.length;

      // Biten ele yeniden dur/kart çek denenirse hiçbir şey değişmez.
      final CasinoResult tekrar = blackjack.stand(ilk.state);
      expect(tekrar.outcome.applied, isFalse);
      expect(tekrar.state.player.wallet, cuzdan);
      expect(tekrar.state.log.length, gunluk);

      final CasinoResult kartCek = blackjack.hit(ilk.state);
      expect(kartCek.outcome.applied, isFalse);
      expect(kartCek.state.player.wallet, cuzdan);

      // Masadan kalkmak ödeme yapmaz, yalnızca masayı temizler.
      final CasinoResult kalk = blackjack.closeHand(ilk.state);
      expect(kalk.state.blackjack, isNull);
      expect(kalk.state.player.wallet, cuzdan);
    });

    test('bitmemiş el masadan kaldırılamaz', () {
      final GameState kurulu = masa(
        oyuncu(18),
        oyuncuKartlari: <PlayingCard>[kart(10), kart(4)],
        krupiyeKartlari: <PlayingCard>[kart(9), kart(7)],
      );
      final CasinoResult r = blackjack.closeHand(kurulu);
      expect(r.outcome.applied, isFalse);
      expect(r.state.blackjack, isNotNull);
    });

    test('açık el varken yeni el açılamaz', () {
      final GameState kurulu = masa(
        oyuncu(19),
        oyuncuKartlari: <PlayingCard>[kart(10), kart(4)],
        krupiyeKartlari: <PlayingCard>[kart(9), kart(7)],
      );
      final int cuzdan = kurulu.player.wallet;
      final CasinoResult r = blackjack.deal(kurulu, 1000, Random(1));
      expect(r.outcome.applied, isFalse);
      expect(r.state.player.wallet, cuzdan);
    });

    test('cüzdan hiçbir elde eksiye düşmez', () {
      GameState state = oyuncu(20, wallet: 300000);
      for (int i = 0; i < 20; i++) {
        final CasinoResult acilis = blackjack.deal(state, 1000, Random(i));
        if (!acilis.outcome.applied) break;
        state = acilis.outcome.walletDelta == -1000
            ? blackjack.stand(acilis.state).state
            : acilis.state;
        state = state.blackjack == null
            ? state
            : blackjack.closeHand(state).state;
        expect(state.player.wallet, greaterThanOrEqualTo(0));
      }
      expect(state.player.wallet, greaterThanOrEqualTo(0));
    });
  });

  // ===================================================================
  // Rulet
  // ===================================================================
  group('Rulet', () {
    test('yalnızca 0-36 arası sayılar gelir', () {
      final Set<int> gelenler = <int>{};
      for (int i = 0; i < 400; i++) {
        final CasinoResult r = roulette.spin(
          oyuncu(30, wallet: 1000000),
          RouletteBetType.kirmizi,
          500,
          Random(i),
        );
        expect(r.outcome.applied, isTrue);
        final String metin = r.outcome.text;
        expect(metin, contains('çark'));
        gelenler.add(int.parse(
          RegExp(r'çark (\d+)').firstMatch(metin)!.group(1)!,
        ));
      }
      expect(gelenler.every((int n) => n >= 0 && n <= 36), isTrue);
      expect(gelenler.length, greaterThan(20),
          reason: 'Çark tek bir sayıya kilitlenmemeli');
    });

    test('renk ve tek/çift bahisleri 1:1 öder', () {
      // Aynı tohumla gelen sayıyı bulup beklenen ödemeyi hesaplıyoruz.
      for (int seed = 0; seed < 25; seed++) {
        final GameState state = oyuncu(31, wallet: 500000);
        final int gelen = Random(seed).nextInt(Roulette.pockets);
        final CasinoResult r = roulette.spin(
          state,
          RouletteBetType.kirmizi,
          1000,
          Random(seed),
        );
        final bool kazanmali =
            gelen != 0 && kRouletteRedNumbers.contains(gelen);
        expect(
          r.state.player.wallet,
          kazanmali ? state.player.wallet + 1000 : state.player.wallet - 1000,
          reason: 'Gelen sayı: $gelen',
        );
      }
    });

    test('sayıya bahis 35:1 öder', () {
      for (int seed = 0; seed < 40; seed++) {
        final GameState state = oyuncu(32, wallet: 500000);
        final int gelen = Random(seed).nextInt(Roulette.pockets);
        final CasinoResult r = roulette.spin(
          state,
          RouletteBetType.sayi,
          1000,
          Random(seed),
          number: 17,
        );
        expect(
          r.state.player.wallet,
          gelen == 17
              ? state.player.wallet + 35000
              : state.player.wallet - 1000,
          reason: 'Gelen sayı: $gelen',
        );
      }
    });

    test('0 gelince renk ve tek/çift bahisleri kaybeder', () {
      // 0 üreten bir tohum bul.
      int? sifirTohum;
      for (int seed = 0; seed < 500 && sifirTohum == null; seed++) {
        if (Random(seed).nextInt(Roulette.pockets) == 0) sifirTohum = seed;
      }
      expect(sifirTohum, isNotNull);

      for (final RouletteBetType tur in <RouletteBetType>[
        RouletteBetType.kirmizi,
        RouletteBetType.siyah,
        RouletteBetType.tek,
        RouletteBetType.cift,
      ]) {
        final GameState state = oyuncu(33, wallet: 500000);
        final CasinoResult r =
            roulette.spin(state, tur, 2000, Random(sifirTohum!));
        expect(r.state.player.wallet, state.player.wallet - 2000,
            reason: '${tur.label} bahsi 0 gelince kaybeder');
      }

      // 0'a oynanan sayı bahsi kazanır.
      final GameState state = oyuncu(33, wallet: 500000);
      final CasinoResult r = roulette.spin(
        state,
        RouletteBetType.sayi,
        2000,
        Random(sifirTohum!),
        number: 0,
      );
      expect(r.state.player.wallet, state.player.wallet + 70000);
    });

    test('sayı bahsinde geçersiz sayı reddedilir', () {
      final GameState state = oyuncu(34);
      final CasinoResult r = roulette.spin(
        state,
        RouletteBetType.sayi,
        1000,
        Random(1),
        number: 37,
      );
      expect(r.outcome.applied, isFalse);
      expect(r.state.player.wallet, state.player.wallet);
    });

    test('sonuç kırmızı/siyah dağılımı gerçekçi', () {
      int kirmizi = 0;
      int siyah = 0;
      int sifir = 0;
      for (int i = 0; i < 3700; i++) {
        final int gelen = Random(i).nextInt(Roulette.pockets);
        if (gelen == 0) {
          sifir++;
        } else if (kRouletteRedNumbers.contains(gelen)) {
          kirmizi++;
        } else {
          siyah++;
        }
      }
      expect(kRouletteRedNumbers.length, 18);
      expect(sifir, greaterThan(0));
      expect((kirmizi - siyah).abs(), lessThan(400),
          reason: 'Renkler dengeli dağılmalı');
    });

    test('bahis ve sonuç hayat günlüğüne yazılır', () {
      final GameState state = oyuncu(35, wallet: 200000);
      final CasinoResult r =
          roulette.spin(state, RouletteBetType.siyah, 1000, Random(2));
      expect(r.state.log.last.text, contains('Rulet'));
      expect(r.state.log.length, state.log.length + 1);
    });
  });

  // ===================================================================
  // Kayıt / yükleme
  // ===================================================================
  group('Kumarhane kaydı', () {
    test('açık el kaydedilip aynı kartlarla geri gelir', () async {
      final GameState state = oyuncu(40, wallet: 500000);
      final GameState acik = blackjack.deal(state, 2500, Random(9)).state;
      // Doğal blackjack denk gelirse el biter; açık el arıyoruz.
      final GameState devam = acik.blackjack!.isFinished
          ? blackjack.deal(
              blackjack.closeHand(acik).state,
              2500,
              Random(11),
            ).state
          : acik;

      final SaveService service = SaveService(MemorySaveStore());
      await service.save(devam);
      final SaveLoadResult result = await service.load();
      expect(result.isLoaded, isTrue, reason: result.message);

      final BlackjackGame once = devam.blackjack!;
      final BlackjackGame sonra = result.state!.blackjack!;
      expect(sonra.bet, once.bet);
      expect(sonra.playerCards, once.playerCards);
      expect(sonra.dealerCards, once.dealerCards);
      expect(sonra.deck, once.deck);
      expect(sonra.phase, once.phase);
      expect(sonra.settled, once.settled);
      expect(result.state!.player.wallet, devam.player.wallet);
      expect(result.state!.wagerThisAge, devam.wagerThisAge);
    });

    test('yeniden açmak sonucu değiştirmez ve bahsi tekrar tahsil etmez',
        () async {
      final GameState acik = masa(
        oyuncu(41, wallet: 60000),
        oyuncuKartlari: <PlayingCard>[kart(10), kart(6)],
        krupiyeKartlari: <PlayingCard>[kart(9), kart(7)],
        deste: <PlayingCard>[kart(4, CardSuit.karo), kart(8, CardSuit.kupa)],
        bet: 3000,
      );

      final SaveService service = SaveService(MemorySaveStore());
      await service.save(acik);
      final GameState geri = (await service.load()).state!;

      expect(geri.player.wallet, acik.player.wallet,
          reason: 'Yükleme bahsi ikinci kez kesmemeli');

      // Aynı el, aynı destede aynı sonucu verir.
      final CasinoResult a = blackjack.stand(acik);
      final CasinoResult b = blackjack.stand(geri);
      expect(b.state.blackjack!.result, a.state.blackjack!.result);
      expect(b.state.blackjack!.dealerCards, a.state.blackjack!.dealerCards);
      expect(b.state.player.wallet, a.state.player.wallet);
    });

    test('desteklenen en eski sürümün kaydı kumarhane alanları olmadan açılır', () async {
      final GameState state = oyuncu(42, wallet: 1234);
      final Map<String, Object?> body = encodeGameState(state);
      body.remove('blackjack');
      body.remove('wagerThisAge');

      final SaveLoadResult result = await SaveService(
        MemorySaveStore(
          initial: jsonEncode(
            <String, Object?>{'formatVersion': kMinReadableSaveVersion, 'state': body},
          ),
        ),
      ).load();
      expect(result.isLoaded, isTrue, reason: result.message);
      expect(result.state!.blackjack, isNull);
      expect(result.state!.wagerThisAge, 0);
      expect(result.state!.player.wallet, 1234);
      expect(result.state!.items.length, state.items.length);
    });
  });
}
