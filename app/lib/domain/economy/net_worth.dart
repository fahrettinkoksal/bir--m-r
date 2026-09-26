/// Net servet (D-162).
///
/// **Neden var:** Oyunda servete bakan yerler dağınıktı ve her biri farklı
/// bir şeye bakıyordu — biri yalnızca cüzdana, biri eşya sayısına, biri
/// ekonomik durum etiketine. Yatırım gelince bu dağınıklık hata üretir:
/// bütün parasını portföye koymuş oyuncu "cüzdanı boş" diye yoksul
/// sayılırdı.
///
/// Bu sınıf tek bir yerde toplar. **Hiçbir şeyi kendi başına değiştirmez**;
/// yalnızca okur.
library;

import '../interaction/divorce_settlement.dart';
import '../models/game_state.dart';
import '../models/loan.dart';
import '../models/owned_item.dart';

abstract final class NetWorth {
  /// Sahip olunan eşyaların toplam değeri (₺).
  ///
  /// Değer ölçüsü boşanma paylaşımıyla **aynı** yerden gelir
  /// (`DivorceSettlement.valueOf`): iki yerde iki farklı değer olmaz.
  static int itemsValue(GameState state) => state.items
      .fold<int>(0, (int t, OwnedItem i) => t + DivorceSettlement.valueOf(i));

  /// Kalan kredi borcu (₺).
  static int debt(GameState state) =>
      state.loans.fold<int>(0, (int t, Loan l) => t + l.outstanding);

  /// Nakit + portföy (₺). "Elimde ne kadar para var" sorusunun cevabı.
  ///
  /// Yatırım da paradır: portföye yatırmış olmak oyuncuyu yoksul yapmaz.
  static int liquid(GameState state) =>
      state.player.wallet + state.portfolioValue;

  /// Net servet: nakit + portföy + eşya − borç (₺).
  static int of(GameState state) =>
      liquid(state) + itemsValue(state) - debt(state);
}
