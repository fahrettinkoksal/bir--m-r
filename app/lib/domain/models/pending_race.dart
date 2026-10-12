import 'package:flutter/foundation.dart';

/// Oynanmış ama **henüz sonuçlanmamış** at yarışı bahsi (D-089).
///
/// **Neden var:** Faho bildirdi — kazanç/kayıp, yarış animasyonu
/// bitmeden cüzdana işliyordu. Sonuç daha ekranda görünmeden para
/// değişiyordu; animasyon yarıda kapatılırsa oyuncu ne olduğunu
/// göremeden bakiyesi değişmiş oluyordu.
///
/// Artık akış şu: bahis yatırıldığı anda **yalnızca bahis tutarı**
/// cüzdandan çıkar ve burada emanette tutulur. Koşunun sonucu bu kayıtta
/// saklanır ama **ödeme yapılmaz**. Animasyon bitip sonuç gösterildiğinde
/// ödeme **tek ve atomik** bir işlemle kesinleşir.
///
/// Kayıt oyunun durumunda durduğu için uygulama animasyonun ortasında
/// kapatılsa bile bahis kaybolmaz ve **iki kez ödenmez**: açılışta
/// bekleyen bahis görülür ve sonuçlandırılır.
@immutable
class PendingRace {
  const PendingRace({
    required this.id,
    required this.lane,
    required this.bet,
    required this.winnerLane,
    required this.payout,
    required this.horseName,
    required this.winnerName,
    required this.oddsLabel,
    required this.atAge,
  });

  /// Bu bahsin benzersiz kimliği; iki kez sonuçlandırmayı engeller.
  final String id;

  /// Oynanan kulvar.
  final int lane;

  /// Emanetteki bahis tutarı (cüzdandan zaten çıktı).
  final int bet;

  /// Koşuyu kazanan kulvar.
  final int winnerLane;

  /// Kazanıldıysa ödenecek toplam tutar; kaybedildiyse 0.
  ///
  /// Bu tutar **henüz ödenmedi**.
  final int payout;

  final String horseName;
  final String winnerName;
  final String oddsLabel;

  /// Bahsin oynandığı yaş.
  final int atAge;

  bool get won => winnerLane == lane;

  /// Oyuncunun cebine giren net değişim (bahis zaten düşmüştü).
  int get net => payout - bet;
}
