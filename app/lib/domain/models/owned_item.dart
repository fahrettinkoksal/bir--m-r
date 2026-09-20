import 'package:flutter/foundation.dart';

import '../../data/item_catalog.dart';

/// Bir eşyanın nasıl edinildiği.
enum ItemSource {
  hediye('Hediye'),
  satinAlma('Satın alındı'),
  olay('Olayla edinildi'),
  bilinmiyor('Bilinmiyor');

  const ItemSource(this.label);

  final String label;
}

/// Envanterdeki **tek bir eşya örneği**.
///
/// Aynı türden iki bisiklet iki ayrı örnektir: her birinin kendi kalıcı
/// kimliği, kondisyonu ve takılı aksesuarları olur.
///
/// Kondisyon 0-100 arası `prototypeOnly` bir ölçektir; nihai oyun dengesi
/// değildir (`docs/DESIGN_REVIEW_QUEUE.md`, Q-041).
@immutable
class OwnedItem {
  const OwnedItem({
    required this.id,
    required this.typeId,
    required this.acquiredAtAge,
    this.source = ItemSource.bilinmiyor,
    this.fromPersonId,
    this.condition = defaultCondition,
    this.attachments = const <String>[],
    this.purchasePrice,
    this.location,
  }) : assert(condition >= 0 && condition <= 100);

  /// prototypeOnly: yeni edinilen eşyanın kondisyonu.
  static const int defaultCondition = 90;

  /// prototypeOnly: eski kayıtlardan taşınan eşyaların kondisyonu.
  ///
  /// Kayıt göçünde eşyanın geçmişi bilinmediği için makul bir orta değer
  /// kullanılır; oyuncunun eşyası silinmez.
  static const int migratedCondition = 75;

  /// Bu örneğe ait kalıcı ve benzersiz kimlik.
  final String id;

  /// Katalogdaki eşya türü ([kItemTypes]).
  final String typeId;

  /// Oyuncunun eşyayı edindiği yaş.
  final int acquiredAtAge;

  /// Nasıl edinildiği.
  final ItemSource source;

  /// Hediyeyse veren kişinin kalıcı kimliği.
  final String? fromPersonId;

  /// 0-100 arası kondisyon (prototypeOnly ölçek).
  final int condition;

  /// Takılı aksesuarların **tür** kimlikleri.
  ///
  /// Aksesuar takıldığında envanterdeki aksesuar örneği tüketilir ve burada
  /// bağlı parça olarak saklanır; böylece aynı zil iki bisiklette birden
  /// görünmez.
  final List<String> attachments;

  /// Satın alındıysa **ödenen fiyat**.
  ///
  /// Araç ve konut kayıtlarında "satın alma fiyatı" olarak gösterilir.
  /// Hediye veya olayla gelen eşyalarda boştur.
  final int? purchasePrice;

  /// Konum/şehir. Konutlarda satın alındığı şehri tutar.
  ///
  /// **Mülk sahibi olmak, o evde yaşamak demek değildir**: hangi hanede
  /// yaşandığı kişi kayıtlarından gelir, bu alandan değil.
  final String? location;

  ItemType get type => itemTypeOrFallback(typeId);

  bool get isVehicle =>
      type.kind == ItemKind.bisiklet ||
      type.kind == ItemKind.motosiklet ||
      type.kind == ItemKind.otomobil;

  bool get isProperty => type.kind == ItemKind.konut;

  String get name => type.name;

  /// Kondisyonun okunaklı karşılığı.
  String get conditionLabel {
    if (condition >= 90) return 'Yeni gibi';
    if (condition >= 70) return 'İyi durumda';
    if (condition >= 45) return 'Yıpranmış';
    if (condition >= 20) return 'Kötü durumda';
    return 'Neredeyse kullanılmaz';
  }

  OwnedItem copyWith({
    int? condition,
    List<String>? attachments,
    int? purchasePrice,
    String? location,
  }) {
    return OwnedItem(
      id: id,
      typeId: typeId,
      acquiredAtAge: acquiredAtAge,
      source: source,
      fromPersonId: fromPersonId,
      condition: (condition ?? this.condition).clamp(0, 100),
      attachments: attachments ?? this.attachments,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      location: location ?? this.location,
    );
  }
}
