/// Portföy kayıtları (D-162).
library;

import 'package:flutter/foundation.dart';

import '../../data/investment_catalog.dart';
import 'market_state.dart';

/// Bir yatırım türündeki pozisyon.
///
/// **Para tamsayı tutulur.** Adet/birim saklanmaz; bunun yerine
/// **maliyet esası** tutulur ve kâr/zarar oradan çıkar. Sebebi şu: bu
/// oyunda doğru olan şey paradır, gram ya da lot değil. Kesirli birim
/// saklamak kayıt tarafında yuvarlama kayması üretir ve cüzdanla portföy
/// arasında kuruş farkları doğurur.
///
/// Kısmi satış kesin hesaplanır: satılan oran kadar maliyet de düşer,
/// gerçekleşen kâr aradaki farktır.
@immutable
class Holding {
  const Holding({
    required this.typeId,
    required this.value,
    required this.costBasis,
    required this.totalInvested,
    required this.realizedProfit,
    required this.firstBoughtAtAge,
  });

  /// Yeni bir pozisyon açar.
  const Holding.opened({
    required this.typeId,
    required int amount,
    required int atAge,
  })  : value = amount,
        costBasis = amount,
        totalInvested = amount,
        realizedProfit = 0,
        firstBoughtAtAge = atAge;

  final String typeId;

  /// Bugünkü değer (₺).
  final int value;

  /// Elde duran kısmın maliyeti (₺). Satışta oranla azalır.
  final int costBasis;

  /// Hayat boyu bu türe yatırılan toplam (₺). Satış bunu azaltmaz.
  final int totalInvested;

  /// Hayat boyu bu türden **gerçekleşen** kâr/zarar (₺).
  final int realizedProfit;

  final int firstBoughtAtAge;

  InvestmentType? get type => investmentTypeById(typeId);

  String get name => type?.name ?? typeId;

  /// Gerçekleşmemiş kâr/zarar (₺).
  int get unrealizedProfit => value - costBasis;

  /// Gerçekleşmemiş kâr/zarar oranı; maliyet sıfırsa 0.
  double get unrealizedRatio =>
      costBasis <= 0 ? 0 : unrealizedProfit / costBasis;

  bool get isEmpty => value <= 0;

  Holding copyWith({
    int? value,
    int? costBasis,
    int? totalInvested,
    int? realizedProfit,
  }) =>
      Holding(
        typeId: typeId,
        value: value ?? this.value,
        costBasis: costBasis ?? this.costBasis,
        totalInvested: totalInvested ?? this.totalInvested,
        realizedProfit: realizedProfit ?? this.realizedProfit,
        firstBoughtAtAge: firstBoughtAtAge,
      );
}

/// Vadeli hesap kaydı.
///
/// Piyasa endeksiyle hareket etmez: vade dolunca anapara **artı faiz**
/// cüzdana girer. Vade dolmadan bozulursa faiz yanar (bkz.
/// `InvestmentEngine.breakTermDeposit`).
@immutable
class TermDeposit {
  const TermDeposit({
    required this.id,
    required this.amount,
    required this.openedAtAge,
    required this.maturesAtAge,
    required this.rateBasis,
  });

  final String id;

  /// Bağlanan anapara (₺).
  final int amount;

  final int openedAtAge;

  /// Vadenin dolduğu yaş.
  final int maturesAtAge;

  /// Yıllık oran, baz puan (600 = %6,00).
  final int rateBasis;

  /// Vade dolduğunda cüzdana girecek toplam (₺).
  int get maturityValue =>
      amount + (amount * rateBasis / MarketState.basis).round();

  /// Vade dolduğunda kazanılacak faiz (₺).
  int get interest => maturityValue - amount;

  /// [age] yaşında vade doldu mu?
  bool maturedAt(int age) => age >= maturesAtAge;
}

/// Portföy geçmişinde bir satır.
///
/// Yıllık fiyat hareketleri buraya yazılmaz; yalnızca oyuncunun yaptığı
/// işlemler ve sıra dışı sonuçlar yazılır (spec §12).
enum InvestmentRecordKind {
  aldi('Alım'),
  satti('Satış'),
  vadeAcildi('Vadeli açıldı'),
  vadeKapandi('Vade doldu'),
  vadeBozuldu('Vade bozuldu'),
  buyukKazanc('Büyük kazanç'),
  buyukKayip('Büyük kayıp');

  const InvestmentRecordKind(this.label);

  final String label;
}

@immutable
class InvestmentRecord {
  const InvestmentRecord({
    required this.typeId,
    required this.age,
    required this.kind,
    required this.amount,
    this.realized = 0,
  });

  final String typeId;
  final int age;
  final InvestmentRecordKind kind;

  /// İşleme konu tutar (₺).
  final int amount;

  /// Satışta gerçekleşen kâr/zarar (₺); diğerlerinde 0.
  final int realized;
}
