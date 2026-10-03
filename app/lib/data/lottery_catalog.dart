/// Milli Piyango biletleri ve ikramiye basamakları (Paket 33).
///
/// Gerçek düzeni izler: bilet **tam, yarım ve çeyrek** olarak satılır,
/// çeyrek bilet ikramiyenin dörtte birini alır. İki çekiliş vardır:
/// yıl içindeki olağan çekiliş ve yılbaşı özel çekilişi.
///
/// **Gerçek para yoktur.** Oyunun sanal cüzdanıyla çalışır; ikramiye
/// gerçek bir ödeme değildir.
///
/// Fiyatlar, ihtimaller ve ikramiyeler `prototypeOnly`'dir
/// (`docs/DESIGN_REVIEW_QUEUE.md`, Q-101). Payı bilerek yüksektir:
/// piyangoda kasanın payı kumarhanedekinden çok daha büyüktür ve
/// oyunda da öyle durur (Faho'nun kumar kararı, Q-098/1).
library;

import 'package:flutter/material.dart';

/// Bilet payı: tam, yarım, çeyrek.
enum TicketShare {
  ceyrek('Çeyrek bilet', 0.25),
  yarim('Yarım bilet', 0.5),
  tam('Tam bilet', 1.0);

  const TicketShare(this.label, this.ratio);

  final String label;

  /// Hem fiyatın hem ikramiyenin bu orandaki payı alınır.
  final double ratio;
}

/// Bir ikramiye basamağı.
@immutable
class LotteryPrize {
  const LotteryPrize({
    required this.label,
    required this.oneIn,
    required this.fullTicketAmount,
  });

  final String label;

  /// prototypeOnly: kaç bilette bir çıkar (1/[oneIn]).
  final int oneIn;

  /// prototypeOnly: **tam bilete** düşen tutar (₺).
  final int fullTicketAmount;

  double get chance => 1 / oneIn;
}

/// Çekiliş türü.
enum LotteryDraw {
  aylik(
    id: 'aylik',
    label: 'Olağan çekiliş',
    description: 'Yıl içinde bayiden alınan bilet. Küçük ama düzenli umut.',
    fullTicketPrice: 500, // prototypeOnly
    maxTicketsPerAge: 12, // prototypeOnly: ayda bir bilet
    prizes: <LotteryPrize>[
      LotteryPrize(
        label: 'Büyük ikramiye',
        oneIn: 500000,
        fullTicketAmount: 50000000,
      ),
      LotteryPrize(
        label: 'İkinci ikramiye',
        oneIn: 100000,
        fullTicketAmount: 5000000,
      ),
      LotteryPrize(
        label: 'Üçüncü ikramiye',
        oneIn: 20000,
        fullTicketAmount: 625000,
      ),
      LotteryPrize(
        label: 'Dördüncü ikramiye',
        oneIn: 2000,
        fullTicketAmount: 50000,
      ),
      LotteryPrize(
        label: 'Teselli ikramiyesi',
        oneIn: 200,
        fullTicketAmount: 5000,
      ),
      LotteryPrize(label: 'Amorti', oneIn: 10, fullTicketAmount: 500),
    ],
  ),

  yilbasi(
    id: 'yilbasi',
    label: 'Yılbaşı özel çekilişi',
    description:
        'Yılın en büyük ikramiyesi. Herkes bir bilet alır, '
        'herkes o geceyi bekler.',
    fullTicketPrice: 1200, // prototypeOnly
    maxTicketsPerAge: 4, // prototypeOnly
    prizes: <LotteryPrize>[
      LotteryPrize(
        label: 'Büyük ikramiye',
        oneIn: 4000000,
        fullTicketAmount: 1200000000,
      ),
      LotteryPrize(
        label: 'İkinci ikramiye',
        oneIn: 800000,
        fullTicketAmount: 60000000,
      ),
      LotteryPrize(
        label: 'Üçüncü ikramiye',
        oneIn: 100000,
        fullTicketAmount: 6000000,
      ),
      LotteryPrize(
        label: 'Dördüncü ikramiye',
        oneIn: 10000,
        fullTicketAmount: 300000,
      ),
      LotteryPrize(
        label: 'Teselli ikramiyesi',
        oneIn: 500,
        fullTicketAmount: 30000,
      ),
      LotteryPrize(label: 'Amorti', oneIn: 10, fullTicketAmount: 1200),
    ],
  );

  const LotteryDraw({
    required this.id,
    required this.label,
    required this.description,
    required this.fullTicketPrice,
    required this.maxTicketsPerAge,
    required this.prizes,
  });

  final String id;
  final String label;
  final String description;

  /// prototypeOnly: tam biletin fiyatı (₺).
  final int fullTicketPrice;

  /// prototypeOnly: bir yılda alınabilecek en fazla bilet.
  final int maxTicketsPerAge;

  /// İkramiye basamakları; **en büyükten en küçüğe** sıralıdır.
  final List<LotteryPrize> prizes;

  /// Verilen paydaki biletin fiyatı.
  int priceFor(TicketShare share) => (fullTicketPrice * share.ratio).round();

  /// Bir tam biletin ortalama geri dönüşü (₺).
  ///
  /// Testte kullanılır: kasanın payının gerçekten büyük olduğunu
  /// gösterir, gizlemez.
  double get expectedReturnPerFullTicket {
    double toplam = 0;
    for (final LotteryPrize p in prizes) {
      toplam += p.chance * p.fullTicketAmount;
    }
    return toplam;
  }

  /// Oyuncuya geri dönen oran (1 = başabaş).
  double get returnRatio => expectedReturnPerFullTicket / fullTicketPrice;

  /// Kasanın payı.
  double get houseEdge => 1 - returnRatio;
}

LotteryDraw? lotteryDrawById(String id) {
  for (final LotteryDraw d in LotteryDraw.values) {
    if (d.id == id) return d;
  }
  return null;
}

TicketShare? ticketShareByName(String name) {
  for (final TicketShare s in TicketShare.values) {
    if (s.name == name) return s;
  }
  return null;
}

/// prototypeOnly: bilet alınabilecek en küçük yaş.
const int kLotteryMinAge = 18;
