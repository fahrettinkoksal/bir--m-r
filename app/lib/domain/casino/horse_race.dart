/// At yarışı (Paket 30).
///
/// **Yalnızca oyunun sanal cüzdanıyla oynanır.** Gerçek para yatırma,
/// çekme, ödüle dönüştürme, uygulama içi satın alma veya reklam
/// karşılığı bahis hakkı **yoktur** (kumarhanenin ortak kuralı).
///
/// Dürüstlük: kazanan at, bahis konmadan **önce** belirlenen oranlara
/// göre çekilir. Oyuncunun kazanması ya da kaybetmesi için sonuç
/// gizlice değiştirilmez. Ekrandaki koşu animasyonu **zaten belli olan**
/// sonucu gösterir, sonucu belirlemez.
///
/// Oranlar ve kâr payı `prototypeOnly`'dir (Q-098).
library;

import 'dart:math';

import '../models/game_state.dart';
import '../models/pending_race.dart';
import '../models/interaction.dart';
import '../models/life_log.dart';
import '../../text/turkish_text.dart';
import 'blackjack.dart';

/// Yarışa çıkan bir at.
class RaceHorse {
  const RaceHorse({
    required this.lane,
    required this.name,
    required this.odds,
  });

  /// Kulvar numarası (1'den başlar).
  final int lane;
  final String name;

  /// Ödeme oranı: kazanırsa bahis **bu katına** çıkar (bahis dâhil).
  ///
  /// 4.0 ise 100 ₺ bahis 400 ₺ döner.
  final double odds;

  /// Oranın işaret ettiği kazanma ihtimali (kâr payı dâhil).
  double get impliedChance => 1 / odds;

  String get oddsLabel => '${odds.toStringAsFixed(1)}x';
}

/// Bir koşunun sonucu.
class RaceResult {
  const RaceResult({
    required this.horses,
    required this.winnerLane,
    required this.finishOrder,
  });

  final List<RaceHorse> horses;

  /// Kazanan atın kulvarı.
  final int winnerLane;

  /// Bitiş sırası (kulvar numaraları, birinciden sonuncuya).
  final List<int> finishOrder;

  RaceHorse get winner =>
      horses.firstWhere((RaceHorse h) => h.lane == winnerLane);
}

/// Türkçe at adları havuzu. Metinler bu proje için yazıldı.
const List<String> kHorseNames = <String>[
  'Rüzgârkıran',
  'Şimşek',
  'Karayel',
  'Yıldırım',
  'Poyraz',
  'Kısrak Ayşe',
  'Sarıkız',
  'Bozkurt',
  'Deli Fişek',
  'Gümüş',
  'Zeybek',
  'Efe',
  'Toz Duman',
  'Al Yazmalım',
  'Kehribar',
  'Doludizgin',
];

abstract final class HorseRacing {
  /// prototypeOnly: bir koşudaki at sayısı.
  static const int prototypeOnlyHorseCount = 5;

  /// prototypeOnly: kasanın payı.
  ///
  /// Oranların işaret ettiği ihtimallerin toplamı bu kadar 1'i aşar.
  /// Rulette kasa payı 0'a oynamaktan gelir; burada açıkça yazılır.
  static const double prototypeOnlyHouseEdge = 0.12;

  /// prototypeOnly: en düşük ve en yüksek ödeme oranı.
  static const double prototypeOnlyMinOdds = 1.8;
  static const double prototypeOnlyMaxOdds = 12.0;

  static const String rulesText =
      'Beş at koşar, sen birine oynarsın. Oranlar ekranda yazar: '
      'kazanan atın oranı bahsinin kaç katına çıktığını gösterir. '
      'Kazanan at, bahsinden bağımsız olarak oranlara göre çekilir.';

  /// Yeni bir koşu kadrosu üretir.
  ///
  /// Oranlar rastgele ağırlıklardan türetilir; toplam ihtimal kasanın
  /// payı kadar 1'i aşar.
  static List<RaceHorse> buildField(Random rng) {
    final List<String> havuz = <String>[...kHorseNames]..shuffle(rng);
    // Ham ağırlıklar: her atın gerçek kazanma ihtimali bunlardan gelir.
    final List<double> agirliklar = <double>[
      for (int i = 0; i < prototypeOnlyHorseCount; i++)
        0.5 + rng.nextDouble() * 2.5,
    ];
    final double toplam = agirliklar.reduce((double a, double b) => a + b);

    return <RaceHorse>[
      for (int i = 0; i < prototypeOnlyHorseCount; i++)
        RaceHorse(
          lane: i + 1,
          name: havuz[i],
          // Gerçek ihtimal p ise adil oran 1/p olurdu; kasanın payı
          // kadar düşürülür.
          odds: (1 / (agirliklar[i] / toplam) / (1 + prototypeOnlyHouseEdge))
              .clamp(prototypeOnlyMinOdds, prototypeOnlyMaxOdds),
        ),
    ];
  }

  /// Kadronun **gerçek** kazanma ihtimalleri (toplamı 1).
  ///
  /// Oranlardan türetilir; ekranda gösterilen oranla tutarlıdır.
  static List<double> trueChances(List<RaceHorse> horses) {
    final List<double> ham = <double>[
      for (final RaceHorse h in horses) h.impliedChance,
    ];
    final double toplam = ham.reduce((double a, double b) => a + b);
    return <double>[for (final double p in ham) p / toplam];
  }

  /// Koşuyu çeker: kazanan ve bitiş sırası.
  ///
  /// Sonuç bahisten **bağımsızdır**.
  static RaceResult run(List<RaceHorse> horses, Random rng) {
    final List<RaceHorse> kalan = <RaceHorse>[...horses];
    final List<int> sira = <int>[];
    while (kalan.isNotEmpty) {
      final List<double> ihtimaller = trueChances(kalan);
      double nokta = rng.nextDouble();
      int secilen = kalan.length - 1;
      for (int i = 0; i < ihtimaller.length; i++) {
        nokta -= ihtimaller[i];
        if (nokta <= 0) {
          secilen = i;
          break;
        }
      }
      sira.add(kalan[secilen].lane);
      kalan.removeAt(secilen);
    }
    return RaceResult(
      horses: horses,
      winnerLane: sira.first,
      finishOrder: List<int>.unmodifiable(sira),
    );
  }

  static InteractionAvailability betAvailability(GameState state, int bet) {
    final InteractionAvailability temel = CasinoAccess.check(state);
    if (!temel.isAllowed) return temel;
    return CasinoAccess.checkBet(state, bet);
  }

  /// Bahsi oynar ve koşuyu çeker.
  static ({CasinoResult result, RaceResult? race}) placeBet(
    GameState state,
    List<RaceHorse> horses,
    int lane,
    int bet,
    Random rng,
  ) {
    final InteractionAvailability check = betAvailability(state, bet);
    if (!check.isAllowed) {
      return (
        result: CasinoResult(
          state: state,
          outcome: CasinoOutcome(applied: false, text: check.reason!),
        ),
        race: null,
      );
    }
    if (!horses.any((RaceHorse h) => h.lane == lane)) {
      return (
        result: CasinoResult(
          state: state,
          outcome: const CasinoOutcome(
            applied: false,
            text: 'Böyle bir kulvar yok.',
          ),
        ),
        race: null,
      );
    }

    if (state.hasPendingRace) {
      return (
        result: CasinoResult(
          state: state,
          outcome: const CasinoOutcome(
            applied: false,
            text: 'Önceki yarışın sonucu henüz kesinleşmedi.',
          ),
        ),
        race: null,
      );
    }

    final RaceResult kosu = run(horses, rng);
    final RaceHorse oynanan =
        horses.firstWhere((RaceHorse h) => h.lane == lane);
    final bool kazandi = kosu.winnerLane == lane;
    final int odeme = kazandi ? (bet * oynanan.odds).round() : 0;

    // **Yalnızca bahis tutarı** cüzdandan çıkar (emanet). Ödeme burada
    // yapılmaz; koşu bitip sonuç gösterilene kadar bekler (D-089).
    // Günlüğe de burada yazılmaz: henüz anlatılacak bir sonuç yok.
    final GameState next = state.copyWith(
      player: state.player.copyWith(wallet: state.player.wallet - bet),
      wagerThisAge: state.wagerThisAge + bet,
      pendingRace: PendingRace(
        id: 'yaris-${state.player.age}-${state.wagerThisAge}-$lane-$bet',
        lane: lane,
        bet: bet,
        winnerLane: kosu.winnerLane,
        payout: odeme,
        horseName: oynanan.name,
        winnerName: kosu.winner.name,
        oddsLabel: oynanan.oddsLabel,
        atAge: state.player.age,
      ),
    );

    return (
      result: CasinoResult(
        state: next,
        outcome: CasinoOutcome(
          applied: true,
          text: '${oynanan.name} (${oynanan.oddsLabel}) üzerine '
              '${trMoney(bet)} yatırdın. Koşu başlıyor.',
          walletDelta: -bet,
        ),
      ),
      race: kosu,
    );
  }

  /// Bekleyen bahsi **tek ve atomik** işlemle sonuçlandırır (D-089).
  ///
  /// Animasyon bittiğinde çağrılır. Bekleyen bahis yoksa **hiçbir şey
  /// olmaz**: bu yüzden animasyon yarıda kapatılsa da, ekran iki kez
  /// açılsa da çift ödeme ya da çift kayıp oluşamaz.
  static CasinoResult settle(GameState state) {
    final PendingRace? bekleyen = state.pendingRace;
    if (bekleyen == null) {
      return CasinoResult(
        state: state,
        outcome: const CasinoOutcome(
          applied: false,
          text: 'Sonuçlanmayı bekleyen bahis yok.',
        ),
      );
    }

    final String metin = 'At yarışı: ${bekleyen.winnerName} birinci geldi. '
        '${bekleyen.won ? '${trMoney(bekleyen.net)} kazandın.' : '${trMoney(bekleyen.bet)} kaybettin.'}';

    final GameState next = state.copyWith(
      player: state.player.copyWith(
        wallet: state.player.wallet + bekleyen.payout,
      ),
      pendingRace: null,
      log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
        ...state.log,
        LifeLogEntry(
          age: state.player.age,
          text: metin,
          category: LogCategory.kisisel,
        ),
      ]),
    );

    return CasinoResult(
      state: next,
      outcome: CasinoOutcome(
        applied: true,
        text: '${bekleyen.horseName} (${bekleyen.oddsLabel}) · $metin',
        walletDelta: bekleyen.payout,
      ),
    );
  }
}
