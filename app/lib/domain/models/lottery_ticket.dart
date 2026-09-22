import 'package:flutter/foundation.dart';

import '../../data/lottery_catalog.dart';

/// Alınmış ama henüz çekilişi yapılmamış bir Milli Piyango bileti.
///
/// Kayda girer: uygulama kapanıp açılınca bilet kaybolmaz, çekiliş
/// bir sonraki yaş ilerlemesinde yapılır.
@immutable
class LotteryTicket {
  const LotteryTicket({
    required this.drawId,
    required this.share,
    required this.number,
    required this.boughtAtAge,
    required this.price,
  });

  final String drawId;
  final TicketShare share;

  /// Biletin üzerindeki numara (altı hane).
  final String number;

  final int boughtAtAge;

  /// Bilete ödenen tutar (₺). Amorti bunu geri verir.
  final int price;

  LotteryDraw? get draw => lotteryDrawById(drawId);

  String get label => '${draw?.label ?? drawId} · ${share.label}';
}

/// Bir çekilişten çıkan sonuç.
@immutable
class LotteryResult {
  const LotteryResult({
    required this.ticket,
    required this.prizeLabel,
    required this.amount,
  });

  final LotteryTicket ticket;

  /// Kazanılan basamağın adı; boşsa bilet tutmadı.
  final String prizeLabel;

  /// Cüzdana giren tutar (₺).
  final int amount;

  bool get won => amount > 0;
}
