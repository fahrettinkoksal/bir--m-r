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

/// Reklam kampanyasının ölçeği (Paket AE, §8).
///
/// Yeni değerler listenin **sonuna** eklenir; eski kayıtlar bozulmasın.
enum BusinessAd {
  yok('Reklam yok', 0.0, 0.00, 0.0),
  mahalle('Mahalle reklamı', 0.030, 0.10, 0.25),
  sosyalMedya('Sosyal medya kampanyası', 0.075, 0.20, 0.85),
  buyuk('Büyük kampanya', 0.170, 0.38, 1.30);

  const BusinessAd(this.label, this.costShare, this.lift, this.variance);

  final String label;

  /// prototypeOnly: kampanyanın **geçen yılki ciroya** oranla maliyeti.
  final double costShare;

  /// prototypeOnly: talebe ortalama katkı (0,20 = %20).
  final double lift;

  /// prototypeOnly: katkının oynaklığı. Büyük kampanya **garanti
  /// değildir** (§8): tutabilir de, para gidebilir de.
  final double variance;

  /// prototypeOnly: bir kampanyanın kendiliğinden bitmesine kaç yıl.
  ///
  /// **Neden var (ölçümde yakalandı).** İlk hâlinde kampanya sonsuza
  /// kadar sürüyordu ve azalan marjinal etki yüzünden birkaç yıl sonra
  /// bedeli katkısını her işletmede aşıyordu: reklam bir karar değil,
  /// tuzaktı. Kampanya artık kendiliğinden bitiyor; oyuncu isterse
  /// yenisini kurar ve yorgunluk sayacı sıfırlanır.
  static const int prototypeOnlyRunYears = 3;
}

/// Bir işletme yılının kapanış dökümü (Paket AE, §6, §31).
///
/// Oyuncuya sade özet gösterilir; muhasebe simülatörü değildir.
@immutable
class BusinessYear {
  const BusinessYear({
    required this.age,
    required this.revenue,
    required this.staffCost,
    required this.supplyCost,
    required this.fixedCost,
    required this.maintenanceCost,
    required this.adCost,
    required this.incidentCost,
    required this.net,
    this.price = 0,
    this.marketPrice = 0,
    this.demandIndex = 100,
  });

  final int age;
  final int revenue;
  final int staffCost;
  final int supplyCost;

  /// Kira ve sabit giderler.
  final int fixedCost;
  final int maintenanceCost;
  final int adCost;

  /// O yıl olayların çıkardığı ek masraf.
  final int incidentCost;

  /// Net sonuç (eksi = zarar).
  final int net;

  /// O yıl uygulanan birim fiyat.
  final int price;

  /// O yılki bölge ortalaması.
  final int marketPrice;

  /// Müşteri yoğunluğu endeksi (100 = normal).
  final int demandIndex;

  /// Ciro dışındaki bütün giderlerin toplamı.
  int get totalCost =>
      staffCost + supplyCost + fixedCost + maintenanceCost + adCost +
      incidentCost;
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
    this.price = 0,
    this.reputation = prototypeOnlyStartReputation,
    this.upkeep = prototypeOnlyStartUpkeep,
    this.staffQuality = prototypeOnlyStartStaffQuality,
    this.staffMorale = prototypeOnlyStartStaffMorale,
    this.staffCount = -1,
    this.wageLevel = 100,
    this.ad = BusinessAd.yok,
    this.adStreak = 0,
    this.yearMaintenanceSpend = 0,
    this.lastMaintenanceAge,
    this.lastStaffCareAge,
    this.history = const <BusinessYear>[],
    this.recentIncidents = const <String>[],
  });

  /// prototypeOnly: yeni kurulan işin başlangıç durumu.
  ///
  /// Ortanın biraz altı: yeni iş kendiliğinden iyi gitmez.
  static const int prototypeOnlyStartCondition = 48;

  /// prototypeOnly: yeni işin itibarı (§9).
  ///
  /// Ortanın altı: kimse seni tanımıyor. Sıfır da değil, çünkü henüz
  /// kimse kötü bir şey de duymadı.
  static const int prototypeOnlyStartReputation = 45;

  /// prototypeOnly: yeni alınan ekipmanın durumu (§10).
  static const int prototypeOnlyStartUpkeep = 90;

  /// prototypeOnly: ilk kadronun niteliği (§7).
  static const int prototypeOnlyStartStaffQuality = 50;

  /// prototypeOnly: ilk kadronun memnuniyeti (§7).
  static const int prototypeOnlyStartStaffMorale = 60;

  /// prototypeOnly: son kaç yılın dökümü saklanır (§31).
  static const int prototypeOnlyHistoryYears = 5;

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

  /// Oyuncunun belirlediği birim fiyat (₺).
  ///
  /// `0` ise fiyat belirlenmemiştir ve iş **bölge ortalamasından**
  /// çalışır (§4). Kayıtta 0 görülürse eski kayıttır; davranış aynıdır.
  final int price;

  /// İşletmenin itibarı (0-100) (§9).
  ///
  /// Oyuncuya sayı olarak değil, okunur bir etiketle gösterilir.
  final int reputation;

  /// Mekânın ve ekipmanın durumu (0-100) (§10).
  final int upkeep;

  /// Kadronun niteliği (0-100) (§7).
  final int staffQuality;

  /// Kadronun memnuniyeti (0-100) (§7).
  final int staffMorale;

  /// Çalışan sayısı. `-1` ise türün tam kadrosu varsayılır.
  ///
  /// Eksik kadro talebi ve hizmeti düşürür; ayrılan çalışanın yerine
  /// biri bulunana kadar iş aksar.
  final int staffCount;

  /// prototypeOnly: ücret düzeyi (100 = piyasa) (§7).
  ///
  /// Zam yapmak memnuniyeti yükseltir ama personel gideri **kalıcı
  /// olarak** artar: zam bedava bir düğme değildir.
  final int wageLevel;

  /// Yürüyen reklam kampanyası (§8).
  final BusinessAd ad;

  /// Aynı kampanyanın üst üste kaçıncı yılı (§8, §35).
  ///
  /// Azalan marjinal etki bunun üstünden hesaplanır: her yıl en pahalı
  /// reklamı vermek garanti para üretmez.
  final int adStreak;

  /// Bu yıl bakıma çıkan para (₺).
  ///
  /// Cüzdandan **o an** çıkar; burada yalnızca yıl sonu raporunun bakım
  /// satırı için birikir ve her hesap kapanışında sıfırlanır. İki kez
  /// tahsil edilmez.
  final int yearMaintenanceSpend;

  /// Bakımın en son yapıldığı yaş.
  final int? lastMaintenanceAge;

  /// Personelle en son ilgilenilen yaş.
  final int? lastStaffCareAge;

  /// Son [prototypeOnlyHistoryYears] yılın dökümü; en yenisi sonda.
  final List<BusinessYear> history;

  /// Son yıllarda çıkan olayların kimlikleri; en yenisi sonda.
  ///
  /// Aynı olayın arka arkaya çıkmasını engeller: fırın her yıl bozulmaz.
  /// Kayda girer, yani kayıt geri yüklenerek olay tazelenemez.
  final List<String> recentIncidents;

  BusinessType? get type => businessTypeById(typeId);

  /// Bu işin fiilî kadrosu.
  int get effectiveStaff =>
      staffCount >= 0 ? staffCount : (type?.staffSlots ?? 0);

  /// Kadro eksiği (tam kadroya göre).
  int get staffGap {
    final int tam = type?.staffSlots ?? 0;
    if (tam <= 0) return 0;
    return (tam - effectiveStaff).clamp(0, tam);
  }

  /// En son kapanan yılın dökümü; hiç yıl kapanmadıysa `null`.
  BusinessYear? get lastYear => history.isEmpty ? null : history.last;

  /// İtibarın okunur hâli (§9: oyuncuya çıplak sayı gösterilmez).
  String get reputationLabel {
    if (reputation >= 80) return 'Adı iyi biliniyor';
    if (reputation >= 62) return 'Memnun müşteri çok';
    if (reputation >= 45) return 'Ortalama';
    if (reputation >= 28) return 'Şikâyet konuşuluyor';
    return 'Adı kötüye çıktı';
  }

  /// Bakım durumunun okunur hâli.
  String get upkeepLabel {
    if (upkeep >= 80) return 'Bakımlı';
    if (upkeep >= 60) return 'İdare eder';
    if (upkeep >= 38) return 'Yıpranmış';
    if (upkeep >= 18) return 'Bakım şart';
    return 'Dökülüyor';
  }

  /// Personel durumunun okunur hâli.
  String get staffLabel {
    final int tam = type?.staffSlots ?? 0;
    if (tam <= 0) return 'Tek başına';
    if (staffGap > 0) return 'Kadro eksik ($effectiveStaff/$tam)';
    if (staffMorale >= 70 && staffQuality >= 65) return 'Kadro güçlü';
    if (staffMorale < 35) return 'Kadro huzursuz';
    if (staffQuality < 35) return 'Kadro acemi';
    return 'Kadro tamam';
  }

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
    int? price,
    int? reputation,
    int? upkeep,
    int? staffQuality,
    int? staffMorale,
    int? staffCount,
    int? wageLevel,
    BusinessAd? ad,
    int? adStreak,
    int? yearMaintenanceSpend,
    Object? lastMaintenanceAge = _unset,
    Object? lastStaffCareAge = _unset,
    List<BusinessYear>? history,
    List<String>? recentIncidents,
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
      price: price ?? this.price,
      reputation: reputation ?? this.reputation,
      upkeep: upkeep ?? this.upkeep,
      staffQuality: staffQuality ?? this.staffQuality,
      staffMorale: staffMorale ?? this.staffMorale,
      staffCount: staffCount ?? this.staffCount,
      wageLevel: wageLevel ?? this.wageLevel,
      ad: ad ?? this.ad,
      adStreak: adStreak ?? this.adStreak,
      yearMaintenanceSpend:
          yearMaintenanceSpend ?? this.yearMaintenanceSpend,
      lastMaintenanceAge: lastMaintenanceAge == _unset
          ? this.lastMaintenanceAge
          : lastMaintenanceAge as int?,
      lastStaffCareAge: lastStaffCareAge == _unset
          ? this.lastStaffCareAge
          : lastStaffCareAge as int?,
      history: history == null
          ? this.history
          : List<BusinessYear>.unmodifiable(history),
      recentIncidents: recentIncidents == null
          ? this.recentIncidents
          : List<String>.unmodifiable(recentIncidents),
    );
  }
}

const Object _unset = Object();
