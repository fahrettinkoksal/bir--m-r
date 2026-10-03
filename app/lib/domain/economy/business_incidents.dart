/// İşletme olayları motoru (Paket AE, §11-25).
///
/// **Neden var.** Katalog olayları yazar, bu dosya onları **kime, ne
/// zaman ve kaç kez** geleceğine karar verir.
///
/// **Kurallar:**
/// * Zar işletmenin kendi akışından gelir ([BusinessMarket.seed]); kayıt
///   geri yüklenip aynı yıl yeniden çevrilemez ve ana oyun akışından
///   çekiliş çalmaz.
/// * Bir olay yılda **bir kez** uygulanır; masrafı bir kez çıkar
///   (§36: "sel double charge yok").
/// * Aynı olay arka arkaya çıkmaz: son yılların listesi tutulur.
/// * Her işletmede aynı olay çıkmaz (§24): olaylar etiketle dağılır,
///   serbest yazılımcıya su baskını gelmez (§21).
/// * Pencere yalnızca **önemli** olaylarda açılır (§25). Rutin gider yıl
///   sonu raporunda toplanır.
///
/// Bütün sayılar `prototypeOnly`'dir (Q-175).
library;

import 'dart:math';

import '../../data/business_catalog.dart';
import '../../data/business_incident_catalog.dart';
import '../models/business.dart';
import '../models/game_state.dart';
import '../models/pending_notice.dart';
import 'business_market.dart';

/// Bir yılın işletme olaylarının sonucu.
class BusinessIncidentOutcome {
  const BusinessIncidentOutcome({
    required this.business,
    this.cost = 0,
    this.demandShift = 1.0,
    this.notices = const <PendingNotice>[],
    this.logs = const <String>[],
  });

  /// Olayların işlendiği hâli.
  final Business business;

  /// Olayların çıkardığı toplam ek masraf (₺).
  final int cost;

  /// O yılın talebine uygulanacak çarpan.
  final double demandShift;

  /// Oyuncuya açılacak pencereler (§25).
  final List<PendingNotice> notices;

  /// Hayat günlüğüne yazılacak satırlar.
  final List<String> logs;

  bool get opensNotice => notices.isNotEmpty;
}

abstract final class BusinessIncidents {
  // -------------------------------------------------------------------
  // Kalibrasyon — hepsi prototypeOnly (Q-175)
  // -------------------------------------------------------------------

  /// prototypeOnly: bir yılda **en az bir** olay çıkma ihtimali.
  static const double prototypeOnlyFirstChance = 0.58;

  /// prototypeOnly: ikinci bir olay çıkma ihtimali.
  ///
  /// Üçüncüsü hiç çıkmaz: bir yılda üç ayrı felaket anlatı değil, gürültü.
  static const double prototypeOnlySecondChance = 0.20;

  /// prototypeOnly: kaç yıl aynı olay tekrar çıkmaz.
  static const int prototypeOnlyCooldownYears = 4;

  /// prototypeOnly: yıpranmış ekipmanın arıza ağırlığını kaç katı yapar.
  static const double prototypeOnlyWornEquipmentBoost = 2.1;

  /// prototypeOnly: huzursuz kadronun ayrılma ağırlığını kaç katı yapar.
  static const double prototypeOnlyLowMoraleBoost = 2.4;

  /// prototypeOnly: iyi haberin iyi işletmeye eğilimi.
  static const double prototypeOnlyGoodNewsBoost = 1.8;

  /// prototypeOnly: iyi haberin kötü işletmedeki ağırlık payı.
  static const double prototypeOnlyGoodNewsPenalty = 0.35;

  /// Yalnızca fiziksel mekânı olan işletmelere ait olay etiketleri (§21).
  ///
  /// Ayıklama burada **yapılmaz**, çünkü bir olay birden çok etiket
  /// taşıyabiliyor: mali denetim hem `dukkan` hem `serbest` hem `nakliye`
  /// etiketli ve §23 onu üçüne de istiyor. Motorda "bu etiketlerden biri
  /// varsa eleme" kuralı yazmayı denedim ve denetimi serbest yazılımcıdan
  /// koparıyordu.
  ///
  /// Doğru güvence katalog tarafında: mekânı olmayan bir işletme bu
  /// etiketleri **taşımaz**. `paket_ae_business_test.dart` bunu
  /// denetliyor; buradaki küme o testin okuduğu tanımdır.
  static const Set<String> prototypeOnlyShopOnlyTags = <String>{
    'dukkan',
    'tesis',
    'saha',
    'salon',
    'mutfak',
    'firin',
    'yikama',
  };

  /// Bir yılın olaylarını işler.
  static BusinessIncidentOutcome advance({
    required GameState state,
    required Business business,
    required BusinessType tur,
    required int newAge,
    required Random rng,
    required int lastDemandIndex,
  }) {
    final int yilSayisi = newAge - business.startedAtAge;
    final List<BusinessIncident> uygun = _eligible(business, tur, yilSayisi);
    if (uygun.isEmpty) return BusinessIncidentOutcome(business: business);

    final int adet = rng.nextDouble() < prototypeOnlyFirstChance
        ? (rng.nextDouble() < prototypeOnlySecondChance ? 2 : 1)
        : 0;
    if (adet == 0) return BusinessIncidentOutcome(business: business);

    Business b = business;
    int masraf = 0;
    double talep = 1.0;
    final List<PendingNotice> pencereler = <PendingNotice>[];
    final List<String> satirlar = <String>[];
    final Set<String> secilen = <String>{};

    for (int i = 0; i < adet; i++) {
      final BusinessIncident? olay = _pick(
        uygun.where((BusinessIncident o) => !secilen.contains(o.id)).toList(
              growable: false,
            ),
        b,
        tur,
        rng,
      );
      if (olay == null) break;
      secilen.add(olay.id);

      masraf += (tur.baseRevenue * olay.costShare).round();
      talep *= olay.demandShift;
      b = _apply(b, tur, olay);

      if (olay.major) {
        pencereler.add(
          PendingNotice(
            id: 'is-olay-${b.id}-${olay.id}-$newAge',
            kind: NoticeKind.kendiIsi,
            age: newAge,
            title: olay.title,
            text: olay.text,
          ),
        );
      }
      satirlar.add('${tur.name}: ${olay.title.toLowerCase()}.');
    }

    final List<String> gecmis = <String>[...b.recentIncidents, ...secilen];
    while (gecmis.length > prototypeOnlyCooldownYears * 2) {
      gecmis.removeAt(0);
    }

    return BusinessIncidentOutcome(
      business: b.copyWith(recentIncidents: gecmis),
      cost: masraf,
      demandShift: talep,
      notices: pencereler,
      logs: satirlar,
    );
  }

  /// Bu işletmeye gelebilecek olaylar.
  static List<BusinessIncident> _eligible(
    Business business,
    BusinessType tur,
    int yilSayisi,
  ) {
    final bool kadroVar = tur.staffSlots > 0;
    final bool ekipmanVar = tur.equipmentLabel != null;
    return kBusinessIncidents.where((BusinessIncident o) {
      if (yilSayisi < o.minYearsOpen) return false;
      if (o.requiresStaff && !kadroVar) return false;
      if (o.requiresEquipment && !ekipmanVar) return false;
      if (business.upkeep > o.maxUpkeep) return false;
      if (business.upkeep < o.minUpkeep) return false;
      if (business.reputation < o.minReputation) return false;
      if (business.recentIncidents.contains(o.id)) return false;
      // Yıldız etiketi: kadrosu olan **her** işe gelen personel olayları.
      if (o.tags.contains('*')) return kadroVar;
      return o.tags.any(tur.incidentTags.contains);
    }).toList(growable: false);
  }

  /// Ağırlıklı seçim.
  ///
  /// Ağırlıklar işletmenin **durumuna** göre kayar: yıpranmış ekipman
  /// daha çok bozulur, huzursuz kadro daha çok ayrılır, iyi haber iyi
  /// işletmeye daha çok gelir. Olaylar rastgele tokat değil, işletmenin
  /// hâlinin sonucudur.
  static BusinessIncident? _pick(
    List<BusinessIncident> havuz,
    Business business,
    BusinessType tur,
    Random rng,
  ) {
    if (havuz.isEmpty) return null;
    final List<double> agirlik = <double>[];
    double toplam = 0;
    for (final BusinessIncident o in havuz) {
      double w = o.weight;
      if (o.requiresEquipment && business.upkeep < 55) {
        w *= 1 +
            (prototypeOnlyWornEquipmentBoost - 1) *
                ((55 - business.upkeep) / 55);
      }
      if (o.staffLoss > 0 && business.staffMorale < 50) {
        w *= 1 +
            (prototypeOnlyLowMoraleBoost - 1) *
                ((50 - business.staffMorale) / 50);
      }
      if (o.isGoodNews) {
        final double not =
            (business.reputation * 0.6 + business.condition * 0.4) / 50;
        w *= not >= 1
            ? (1 + (not - 1) * (prototypeOnlyGoodNewsBoost - 1))
            : (prototypeOnlyGoodNewsPenalty +
                (1 - prototypeOnlyGoodNewsPenalty) * not);
      }
      agirlik.add(w);
      toplam += w;
    }
    if (toplam <= 0) return null;
    double atis = rng.nextDouble() * toplam;
    for (int i = 0; i < havuz.length; i++) {
      atis -= agirlik[i];
      if (atis <= 0) return havuz[i];
    }
    return havuz.last;
  }

  /// Olayın işletmeye etkisini uygular.
  static Business _apply(
    Business business,
    BusinessType tur,
    BusinessIncident olay,
  ) {
    int kadro = business.effectiveStaff;
    if (olay.staffLoss > 0) {
      kadro = (kadro - olay.staffLoss).clamp(0, tur.staffSlots);
    }
    return business.copyWith(
      demandPressure: (business.demandPressure * olay.lastingShift).clamp(
        BusinessMarket.prototypeOnlyPressureFloor,
        BusinessMarket.prototypeOnlyPressureCeiling,
      ),
      upkeep: (business.upkeep + olay.upkeepDelta).clamp(0, 100),
      staffMorale: (business.staffMorale + olay.moraleDelta).clamp(0, 100),
      staffQuality: (business.staffQuality + olay.qualityDelta).clamp(0, 100),
      reputation:
          (business.reputation + olay.reputationDelta).clamp(0, 100),
      condition: (business.condition + olay.conditionDelta).clamp(0, 100),
      staffCount: kadro,
    );
  }
}
