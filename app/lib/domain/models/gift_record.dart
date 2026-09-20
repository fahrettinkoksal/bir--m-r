import 'package:flutter/foundation.dart';

/// Gerçekleşmiş bir hediyeleşmenin kaydı.
///
/// Kim, kime, hangi eşyayı, kaç yaşında verdi? Eşya envantere girdiğinde bu
/// kayıt da tutulur; ileride eşyanın "nasıl edinildiği" ve satış geçmişi
/// buraya bağlanacak (Paket 2).
@immutable
class GiftRecord {
  const GiftRecord({
    required this.itemId,
    required this.fromId,
    required this.toId,
    required this.age,
  });

  /// Oyuncunun kendisi için kullanılan kimlik.
  static const String playerId = 'oyuncu';

  final String itemId;

  /// Veren kişinin kalıcı kimliği ([playerId] ise oyuncu verdi).
  final String fromId;

  /// Alan kişinin kalıcı kimliği ([playerId] ise oyuncu aldı).
  final String toId;

  /// Oyuncunun o sırada kaç yaşında olduğu.
  final int age;
}
