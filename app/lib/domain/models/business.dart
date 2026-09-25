/// Kendi işi kaydı (D-132).
///
/// **Kayıt silinmez:** batan ya da satılan iş listede kalır, nasıl
/// bittiği yazılı durur. Hayat sonu değerlendirmesi ve kuşak devamı bunu
/// okur.
library;

import 'package:flutter/foundation.dart';

import '../../data/business_catalog.dart';

/// İşin nasıl bittiği.
///
/// Yeni değerler listenin **sonuna** eklenir; eski kayıtlar bozulmasın.
enum BusinessEndReason {
  batti('Battı'),
  satildi('Satıldı'),
  birakildi('Bırakıldı'),
  kusakDevami('Kuşak devamında bırakıldı');

  const BusinessEndReason(this.label);

  final String label;
}

/// Kurulmuş bir iş.
@immutable
class Business {
  const Business({
    required this.id,
    required this.typeId,
    required this.startedAtAge,
    this.condition = prototypeOnlyStartCondition,
    this.totalInvested = 0,
    this.totalProfit = 0,
    this.lastTendedAge,
    this.lastSettledAge,
    this.closedAtAge,
    this.endReason,
  });

  /// prototypeOnly: yeni kurulan işin başlangıç durumu.
  ///
  /// Ortanın biraz altı: yeni iş kendiliğinden iyi gitmez.
  static const int prototypeOnlyStartCondition = 48;

  final String id;

  /// [BusinessType.id].
  final String typeId;

  final int startedAtAge;

  /// İşin durumu (0-100).
  ///
  /// Kâr buna bağlıdır. 0'a inerse iş **batar**. İlgilenmek yükseltir,
  /// ilgilenmemek düşürür.
  final int condition;

  /// Bugüne kadar işe konan toplam para (kurulum + sonraki yatırımlar).
  final int totalInvested;

  /// Bugüne kadar işten kazanılan **net** tutar (zarar eksi yazar).
  final int totalProfit;

  /// İşle en son ilgilenilen yaş.
  final int? lastTendedAge;

  /// Kâr/zararın en son işlendiği yaş. Aynı yıl iki kez işlenmez.
  final int? lastSettledAge;

  /// İşin kapandığı yaş; sürüyorsa `null`.
  final int? closedAtAge;

  final BusinessEndReason? endReason;

  BusinessType? get type => businessTypeById(typeId);

  bool get isOpen => closedAtAge == null;

  /// İşin durumunun okunur hâli.
  String get conditionLabel {
    if (condition >= 75) return 'İyi gidiyor';
    if (condition >= 50) return 'İdare ediyor';
    if (condition >= 30) return 'Zorlanıyor';
    if (condition > 0) return 'Batmak üzere';
    return 'Battı';
  }

  /// Kaç yıl açık kaldı (ya da kalıyor)?
  int yearsOpen(int playerAge) =>
      (closedAtAge ?? playerAge) - startedAtAge;

  Business copyWith({
    int? condition,
    int? totalInvested,
    int? totalProfit,
    Object? lastTendedAge = _unset,
    Object? lastSettledAge = _unset,
    Object? closedAtAge = _unset,
    Object? endReason = _unset,
  }) {
    return Business(
      id: id,
      typeId: typeId,
      startedAtAge: startedAtAge,
      condition: condition ?? this.condition,
      totalInvested: totalInvested ?? this.totalInvested,
      totalProfit: totalProfit ?? this.totalProfit,
      lastTendedAge:
          lastTendedAge == _unset ? this.lastTendedAge : lastTendedAge as int?,
      lastSettledAge: lastSettledAge == _unset
          ? this.lastSettledAge
          : lastSettledAge as int?,
      closedAtAge:
          closedAtAge == _unset ? this.closedAtAge : closedAtAge as int?,
      endReason: endReason == _unset
          ? this.endReason
          : endReason as BusinessEndReason?,
    );
  }
}

const Object _unset = Object();
