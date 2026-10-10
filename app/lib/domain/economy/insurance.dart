import '../../data/insurance_catalog.dart';
import '../models/game_state.dart';
import '../models/insurance_policy.dart';
import '../models/owned_item.dart';
import '../features/feature_catalog.dart';
import 'housing.dart';

/// Sigorta motoru (Paket CA).
///
/// **Sözleşme.**
///
/// * **Zar tüketmez.** Prim ve hasar karşılığı deterministik; poliçesi
///   olmayan oyuncunun akışı birebir Paket CA öncesiyle aynı kalır
///   (Paket BO'nun zar sözleşmesi).
/// * **Para uydurulmaz.** Prim cüzdandan çıkar, karşılık yalnızca
///   **zararı azaltır**; sigorta hiçbir yerde cüzdana para *eklemez*.
///   Yani exploit yolu yok: poliçe en iyi durumda zararı muafiyete
///   indirir.
/// * **Dayanağı olmayan poliçe düşer.** Konut poliçesi kendi evinde
///   oturmayı, kasko aracı gerektiriyor; ev satılınca ya da araç
///   gidince poliçe `lapsedAtAge` ile kapanır. Kayıt silinmez: ne kadar
///   prim ödendiği ve ne kadar karşılandığı durur.
/// * **Prim ödenemezse poliçe düşer.** Cüzdan yetmiyorsa poliçe o yıl
///   kapanır; borç yazılmaz (D-123 ile aynı ilke).
///
/// Bütün sayılar `prototypeOnly` (`insurance_catalog.dart`), modül
/// anahtarı `sigorta`.
abstract final class Insurance {
  /// Modül açık mı?
  static bool isOn(GameState state) => state.featureOn(FeatureId.sigorta);

  /// Bu türün yürürlükteki poliçesi (yoksa `null`).
  static InsurancePolicy? activeOf(GameState state, InsuranceKind kind) {
    for (final InsurancePolicy p in state.insurance) {
      if (p.kind == kind && p.isActive) return p;
    }
    return null;
  }

  /// Poliçenin dayanağı duruyor mu? (ev/araç koşulu)
  static bool supportHolds(GameState state, InsuranceKind kind) {
    final InsuranceTerms t = insuranceTermsOf(kind);
    if (t.requiresOwnedResidence &&
        Housing.residenceOf(state) != ResidenceKind.kendiEvinde) {
      return false;
    }
    if (t.requiresVehicle &&
        !state.items.any((OwnedItem i) => i.isVehicle)) {
      return false;
    }
    return true;
  }

  /// Bu poliçe şu an alınabilir mi? Alınamıyorsa **gerekçe** döner.
  ///
  /// Gerekçe her zaman yazılır; sahte düğme gösterilmez (D-063).
  static String? blockReason(GameState state, InsuranceKind kind) {
    if (!isOn(state)) return 'Sigorta modülü kapalı.';
    final InsuranceTerms t = insuranceTermsOf(kind);
    if (activeOf(state, kind) != null) {
      return '${t.kind.label} zaten var.';
    }
    if (state.player.age < t.prototypeOnlyMinAge) {
      return 'Poliçe ${t.prototypeOnlyMinAge} yaşından itibaren '
          'yapılabiliyor.';
    }
    if (t.requiresOwnedResidence &&
        Housing.residenceOf(state) != ResidenceKind.kendiEvinde) {
      return 'Konut poliçesi için kendi evinde oturman gerekiyor.';
    }
    if (t.requiresVehicle &&
        !state.items.any((OwnedItem i) => i.isVehicle)) {
      return 'Kasko için bir aracın olması gerekiyor.';
    }
    if (state.player.wallet < t.prototypeOnlyYearlyPremium) {
      return 'İlk primi ödeyecek paran yok '
          '(${t.prototypeOnlyYearlyPremium} ₺).';
    }
    return null;
  }

  /// Poliçeyi başlatır: ilk prim **peşin** ödenir.
  static ({GameState state, String text}) buy(
    GameState state,
    InsuranceKind kind,
  ) {
    final String? engel = blockReason(state, kind);
    if (engel != null) return (state: state, text: engel);
    final InsuranceTerms t = insuranceTermsOf(kind);
    final List<InsurancePolicy> liste = <InsurancePolicy>[
      ...state.insurance,
      InsurancePolicy(
        kind: kind,
        startedAtAge: state.player.age,
        premiumsPaid: t.prototypeOnlyYearlyPremium,
      ),
    ];
    return (
      state: state.copyWith(
        player: state.player.copyWith(
          wallet: state.player.wallet - t.prototypeOnlyYearlyPremium,
        ),
        insurance: liste,
      ),
      text: '${t.kind.label} başladı. İlk prim ödendi: '
          '${t.prototypeOnlyYearlyPremium} ₺.',
    );
  }

  /// Poliçeyi oyuncu kendi isteğiyle kapatır. Kayıt silinmez.
  static ({GameState state, String text}) cancel(
    GameState state,
    InsuranceKind kind,
  ) {
    final InsurancePolicy? p = activeOf(state, kind);
    if (p == null) {
      return (state: state, text: '${kind.label} yok.');
    }
    return (
      state: _replace(state, p.copyWith(lapsedAtAge: state.player.age)),
      text: '${kind.label} iptal edildi. Ödediğin primler geri gelmiyor.',
    );
  }

  /// Yılın primlerini tahsil eder ve dayanağı düşen poliçeleri kapatır.
  ///
  /// Zar tüketmez. Poliçesi olmayan oyuncuda hiçbir şey yapmaz.
  static ({GameState state, List<String> logLines}) advanceYear(
    GameState state,
  ) {
    if (state.insurance.isEmpty) {
      return (state: state, logLines: const <String>[]);
    }
    final List<String> log = <String>[];
    List<InsurancePolicy> liste = List<InsurancePolicy>.of(state.insurance);
    int cuzdan = state.player.wallet;

    for (int i = 0; i < liste.length; i++) {
      final InsurancePolicy p = liste[i];
      if (!p.isActive) continue;
      // Modül kapandıysa poliçe sessizce donar: prim çıkmaz.
      if (!isOn(state)) continue;
      if (!supportHolds(state, p.kind)) {
        liste[i] = p.copyWith(lapsedAtAge: state.player.age);
        log.add('${p.kind.label} düştü: dayanağı kalmadı.');
        continue;
      }
      final int prim = p.terms.prototypeOnlyYearlyPremium;
      if (cuzdan < prim) {
        liste[i] = p.copyWith(lapsedAtAge: state.player.age);
        log.add('${p.kind.label} primi ödenemedi; poliçe düştü.');
        continue;
      }
      cuzdan -= prim;
      liste[i] = p.copyWith(premiumsPaid: p.premiumsPaid + prim);
    }

    return (
      state: state.copyWith(
        player: state.player.copyWith(wallet: cuzdan),
        insurance: liste,
      ),
      logLines: log,
    );
  }

  /// Hasarın oyuncuya kalan kısmı.
  ///
  /// Poliçe yoksa zararın tamamı. Varsa: muafiyet + karşılanmayan pay.
  /// **Sigorta cüzdana para eklemez**, yalnızca zararı azaltır; bu
  /// yüzden dönen değer hiçbir zaman `loss`tan büyük olamaz.
  static ({int paid, int covered, String? note}) settle(
    GameState state,
    InsuranceKind kind,
    int loss,
  ) {
    if (loss <= 0) return (paid: loss, covered: 0, note: null);
    if (!isOn(state)) return (paid: loss, covered: 0, note: null);
    final InsurancePolicy? p = activeOf(state, kind);
    if (p == null || !supportHolds(state, kind)) {
      return (paid: loss, covered: 0, note: null);
    }
    final InsuranceTerms t = p.terms;
    if (loss <= t.prototypeOnlyDeductible) {
      // Muafiyetin altındaki hasarda poliçe devreye girmez; dosya
      // açılmadığı için sayaç da artmaz.
      return (paid: loss, covered: 0, note: null);
    }
    final int ustu = loss - t.prototypeOnlyDeductible;
    final int karsilanan = (ustu * t.prototypeOnlyCoveredShare).round();
    final int kalan = loss - karsilanan;
    return (
      paid: kalan,
      covered: karsilanan,
      note: '${t.kind.label} devreye girdi: $karsilanan ₺ karşılandı, '
          'cebinden $kalan ₺ çıktı.',
    );
  }

  /// Karşılığı poliçe kaydına işler (sayaç ve toplam).
  static GameState recordClaim(
    GameState state,
    InsuranceKind kind,
    int covered,
  ) {
    if (covered <= 0) return state;
    final InsurancePolicy? p = activeOf(state, kind);
    if (p == null) return state;
    return _replace(
      state,
      p.copyWith(
        claimsPaid: p.claimsPaid + covered,
        claimCount: p.claimCount + 1,
      ),
    );
  }

  static GameState _replace(GameState state, InsurancePolicy guncel) =>
      state.copyWith(
        insurance: <InsurancePolicy>[
          for (final InsurancePolicy p in state.insurance)
            if (p.kind == guncel.kind && p.startedAtAge == guncel.startedAtAge)
              guncel
            else
              p,
        ],
      );
}
