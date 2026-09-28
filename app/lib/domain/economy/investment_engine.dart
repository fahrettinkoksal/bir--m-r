/// Portföy motoru: al, sat, vadeli ve yıllık ilerleme (D-162).
///
/// **İkinci bir ekonomi motoru değildir.** Para tek cüzdandan çıkar ve tek
/// cüzdana girer (`GameState.player.wallet`); banka, kredi ve yaşam gideri
/// olduğu gibi durur. Buranın yaptığı tek şey cüzdandaki paranın bir kısmını
/// **pozisyona** çevirmek ve piyasa endeksi hareket ettikçe o pozisyonun
/// değerini güncellemek.
///
/// Kurallar:
/// - Cüzdan **asla eksiye inmez**.
/// - Piyasa yaş başına **bir kez** ilerler; al-sat yapmak ya da ekranı
///   kapatıp açmak fiyatı yeniden çevirmez.
/// - Kayıt silinmez: pozisyon sıfırlansa bile geçmiş satırları kalır.
/// - Hiçbir metin yatırım tavsiyesi vermez, "kesin kazanç" demez.
///
/// Bütün sayılar `prototypeOnly`'dir (Q-165).
library;

import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../data/investment_catalog.dart';
import '../../text/turkish_text.dart';
import '../models/game_event.dart';
import '../models/game_state.dart';
import '../models/interaction.dart';
import '../models/investment.dart';
import '../models/life_log.dart';
import '../models/company_vitals.dart';
import '../models/market_incident.dart';
import '../models/market_state.dart';
import 'company_engine.dart';
import 'incident_engine.dart';
import '../models/pending_notice.dart';
import 'market_engine.dart';

/// Bir portföy işleminin sonucu.
class InvestmentOutcome {
  const InvestmentOutcome({
    required this.applied,
    required this.text,
    this.amount = 0,
    this.realized = 0,
  });

  final bool applied;
  final String text;

  /// İşleme konu tutar (₺).
  final int amount;

  /// Satışta gerçekleşen kâr/zarar (₺).
  final int realized;
}

class InvestmentResult {
  const InvestmentResult({required this.state, required this.outcome});

  final GameState state;
  final InvestmentOutcome outcome;
}

abstract final class InvestmentEngine {
  /// prototypeOnly: "büyük hareket" sayılan yıllık oran.
  ///
  /// Bildirim ve geçmiş satırı bu eşiğin üstünde açılır; sıradan yıl
  /// yalnızca portföy ekranında görünür.
  static const double prototypeOnlyBigMove = 0.22;

  /// prototypeOnly: piyasa bildirimleri arasında en az kaç yıl geçmeli.
  static const int prototypeOnlyNoticeGap = 2;

  // -------------------------------------------------------------------
  // Portföy maliyetleri (Paket AC, §22-23) — hepsi prototypeOnly
  // -------------------------------------------------------------------

  /// prototypeOnly: alım-satım komisyonu (işlem tutarının oranı).
  ///
  /// Küçük ama uzun vadede hissedilir: her yıl alım yapan oyuncu bunu
  /// altmış kez öder. Gerçek bir aracı kurum tarifesi taklit edilmedi.
  static const double prototypeOnlyTradeCommission = 0.002;

  /// prototypeOnly: fonun yıllık yönetim gideri (pozisyon değerinin oranı).
  ///
  /// Yalnızca fona uygulanır — "içinde biraz her şey var" diyen bir ürünün
  /// bir yöneticisi vardır ve o yönetici ücret alır.
  static const double prototypeOnlyFundAnnualFee = 0.011;

  /// prototypeOnly: satışta **gerçekleşen kârdan** yapılan kesinti.
  ///
  /// Gerçek Türkiye vergi mevzuatı **birebir kodlanmadı** (§23): tek
  /// oranlı, oyunlaştırılmış bir kesinti. Yalnızca kârdan alınır; zararda
  /// kesinti yoktur ve zarar mahsubu yoktur.
  static const double prototypeOnlyGainWithholding = 0.10;

  /// prototypeOnly: tek bir riskli varlıkta yoğunlaşmanın oynaklık zammı.
  ///
  /// Portföyün tamamı tek riskli varlıktaysa o varlığın kendi gürültüsü
  /// bu kat kadar büyür; dağıtıldığında etkisi kaybolur. Çeşitlendirme
  /// **kazanç garantisi vermez**, yalnızca oynaklığı düşürür (§24).
  /// prototypeOnly: tek varlığa yığılmanın **oynaklık** zammı.
  ///
  /// **Paket AD'de 0,55'ten 0,25'e indirildi ve yanına bir de
  /// beklenen-getiri cezası kondu.** Sebebi AD/6 ölçümü: 60 yıllık
  /// "%100 hisse" stratejisinde en iyi %10 **₺1,56 milyar**, görülen en
  /// yüksek servet **₺211.732 milyon** ve hayatların **%12,7'si**
  /// milyarder çıktı. §19 "milyarderlik çok nadir" diyor.
  ///
  /// Sebep mekanizmanın kendisiydi. Zam sapmayı çarpıyor ve yorumunda
  /// "beklenen değer kaymaz" yazıyordu — **tek yıl için doğru, bileşik
  /// servet için değil.** Sapmayı 1,55 ile çarpmak yıllık oynaklığı
  /// %23'ten ~%36'ya çıkarıyor; altmış yıl bileşiklenince bu, medyanı
  /// düşürürken üst kuyruğu patlatıyor. Yani "ceza" diye yazılan şey
  /// pratikte bir **piyango bileti** olmuş.
  static const double prototypeOnlyConcentrationVolBoost = 0.25;

  /// prototypeOnly: tek varlığa yığılmanın **beklenen getiri** cezası.
  ///
  /// Yoğunlaşma risk ekler ama karşılığında getiri **eklemez** — çeşitlenen
  /// oyuncu aynı riski daha ucuza alır. Oyun kuralı olarak: tam yoğunlaşmış
  /// portföy her yıl bu kadar geri kalır. §9'un "çeşitlendirme korur"
  /// kuralının sayısal karşılığı budur; çeşitlenen portföyde sıfırdır.
  static const double prototypeOnlyConcentrationDrag = 0.012;

  // -------------------------------------------------------------------
  // Uygunluk
  // -------------------------------------------------------------------

  /// Yatırım bölümü bu oyuncuya açık mı?
  static InteractionAvailability availability(GameState state) {
    if (state.player.age < kInvestmentMinAge) {
      return InteractionAvailability.blocked(
        'Kendi adına yatırım yapmak için $kInvestmentMinAge yaşında olman '
        'gerekiyor.',
      );
    }
    return const InteractionAvailability.allowed();
  }

  /// Bu tutarda alım yapılabilir mi? Yapılamıyorsa gerekçe (boş = uygun).
  static String buyBlockReason({
    required GameState state,
    required InvestmentType type,
    required int amount,
  }) {
    final InteractionAvailability u = availability(state);
    if (!u.isAllowed) return u.reason!;
    final int enAz = type.isTermDeposit ? kTermDepositMinAmount : kInvestmentMinBuy;
    if (amount < enAz) return 'En az ${trMoney(enAz)} ile başlanabiliyor.';
    // **İşlem sırası kapalıysa alım da yapılmaz (Paket AC, §5).**
    final TradingHalt? durma =
        state.market.haltFor(type.id, state.player.age);
    if (durma != null) return durma.reason;
    // Komisyon cüzdandan ayrıca çıkar; parası tam tutarsa alım olmaz.
    final int komisyon = commissionFor(amount);
    if (state.player.wallet < amount + komisyon) {
      return 'Cüzdanında ${trMoney(amount + komisyon)} yok '
          '(${trMoney(komisyon)} işlem masrafı dahil).';
    }
    return '';
  }

  /// Bu tutarda satış yapılabilir mi? (boş = uygun)
  static String sellBlockReason({
    required GameState state,
    required InvestmentType type,
    required int amount,
  }) {
    if (type.isTermDeposit) {
      return 'Vadeli hesap bu ekrandan satılmaz; vadesini bozabilirsin.';
    }
    final Holding? h = state.holdingOf(type.id);
    if (h == null || h.isEmpty) return 'Bu türde yatırımın yok.';
    if (amount <= 0) return 'Bir tutar yaz.';
    if (amount > h.value) {
      return 'Elindeki ${trMoney(h.value)} kadarını satabilirsin.';
    }
    // **İşlem sırası kapalıysa satış yapılamaz (Paket AC, §5).**
    // "Satayım kurtulayım" her zaman mümkün değil; gerçek yatırım
    // risklerinden biri bu. Süre sonsuz değil, `untilAge` ile biter.
    final TradingHalt? durma =
        state.market.haltFor(type.id, state.player.age);
    if (durma != null) return durma.reason;
    return '';
  }

  /// Bir işlemin komisyonu (₺). En az 1 ₺, tutar sıfırsa 0.
  static int commissionFor(int amount) {
    if (amount <= 0) return 0;
    final int k = (amount * prototypeOnlyTradeCommission).round();
    return k < 1 ? 1 : k;
  }

  // -------------------------------------------------------------------
  // Alım
  // -------------------------------------------------------------------

  /// Yatırım alır. Vadeli hesapta ayrı bir kayıt açar.
  static InvestmentResult buy({
    required GameState state,
    required String typeId,
    required int amount,
  }) {
    final InvestmentType? tur = investmentTypeById(typeId);
    if (tur == null) return _blocked(state, 'Böyle bir yatırım türü yok.');
    final String engel =
        buyBlockReason(state: state, type: tur, amount: amount);
    if (engel.isNotEmpty) return _blocked(state, engel);

    final int yas = state.player.age;
    if (tur.isTermDeposit) return _openTermDeposit(state, amount, yas);

    final Holding? mevcut = state.holdingOf(typeId);
    final Holding yeni = mevcut == null
        ? Holding.opened(typeId: typeId, amount: amount, atAge: yas)
        : mevcut.copyWith(
            value: mevcut.value + amount,
            costBasis: mevcut.costBasis + amount,
            totalInvested: mevcut.totalInvested + amount,
          );

    // **Komisyon (§22).** Yatırılan tutar pozisyona girer, masraf
    // cüzdandan ayrıca çıkar: maliyet esasını şişirmemek için.
    final int komisyon = commissionFor(amount);
    final String metin = komisyon > 0
        ? '${tur.name}: ${trMoney(amount)} aldın. '
            'İşlem masrafı ${trMoney(komisyon)}.'
        : '${tur.name}: ${trMoney(amount)} aldın.';
    final GameState next = state.copyWith(
      player: state.player.copyWith(
        wallet: state.player.wallet - amount - komisyon,
      ),
      investments: List<Holding>.unmodifiable(<Holding>[
        for (final Holding h in state.investments)
          if (h.typeId != typeId) h,
        yeni,
      ]),
      investmentHistory: List<InvestmentRecord>.unmodifiable(
        <InvestmentRecord>[
          ...state.investmentHistory,
          InvestmentRecord(
            typeId: typeId,
            age: yas,
            kind: InvestmentRecordKind.aldi,
            amount: amount,
          ),
        ],
      ),
    );

    return InvestmentResult(
      state: _log(next, metin, yas),
      outcome: InvestmentOutcome(applied: true, text: metin, amount: amount),
    );
  }

  static InvestmentResult _openTermDeposit(
    GameState state,
    int amount,
    int yas,
  ) {
    final int sayac = state.termDeposits.length +
        state.investmentHistory
            .where((InvestmentRecord r) =>
                r.kind == InvestmentRecordKind.vadeAcildi)
            .length +
        1;
    final TermDeposit kayit = TermDeposit(
      id: 'vadeli-$sayac',
      amount: amount,
      openedAtAge: yas,
      maturesAtAge: yas + kTermDepositYears,
      rateBasis: (kTermDepositRate * MarketState.basis).round(),
    );

    final String metin =
        'Vadeli hesaba ${trMoney(amount)} bağladın. Vade dolduğunda '
        '${trMoney(kayit.maturityValue)} olarak dönecek; o güne kadar '
        'para kilitli.';

    final GameState next = state.copyWith(
      player: state.player.copyWith(wallet: state.player.wallet - amount),
      termDeposits: List<TermDeposit>.unmodifiable(<TermDeposit>[
        ...state.termDeposits,
        kayit,
      ]),
      investmentHistory: List<InvestmentRecord>.unmodifiable(
        <InvestmentRecord>[
          ...state.investmentHistory,
          InvestmentRecord(
            typeId: 'vadeli',
            age: yas,
            kind: InvestmentRecordKind.vadeAcildi,
            amount: amount,
          ),
        ],
      ),
    );

    return InvestmentResult(
      state: _log(next, metin, yas),
      outcome: InvestmentOutcome(applied: true, text: metin, amount: amount),
    );
  }

  // -------------------------------------------------------------------
  // Satış
  // -------------------------------------------------------------------

  /// Pozisyonun bir kısmını (ya da tamamını) satar.
  ///
  /// Kısmi satışta **maliyet de oranla düşer**: gerçekleşen kâr, satılan
  /// kısmın maliyeti ile eline geçen para arasındaki farktır.
  static InvestmentResult sell({
    required GameState state,
    required String typeId,
    required int amount,
  }) {
    final InvestmentType? tur = investmentTypeById(typeId);
    if (tur == null) return _blocked(state, 'Böyle bir yatırım türü yok.');
    final String engel =
        sellBlockReason(state: state, type: tur, amount: amount);
    if (engel.isNotEmpty) return _blocked(state, engel);

    final Holding h = state.holdingOf(typeId)!;
    final int yas = state.player.age;
    final bool tamami = amount >= h.value;

    // Satılan oran kadar maliyet düşer. Tamamı satıldıysa maliyetin
    // tamamı gider; yoksa kuruş artıkları pozisyonda kalır.
    final int dusenMaliyet =
        tamami ? h.costBasis : (h.costBasis * amount / h.value).round();
    final int gerceklesen = amount - dusenMaliyet;

    final Holding yeni = h.copyWith(
      value: h.value - amount,
      costBasis: h.costBasis - dusenMaliyet,
      realizedProfit: h.realizedProfit + gerceklesen,
    );

    // **Komisyon ve kazanç kesintisi (§22-23).** Kesinti yalnızca
    // gerçekleşen **kârdan** alınır; zararda kesinti yoktur ve zarar
    // mahsubu yoktur (gerçek mevzuat birebir kodlanmadı).
    final int komisyon = commissionFor(amount);
    final int kesinti = gerceklesen > 0
        ? (gerceklesen * prototypeOnlyGainWithholding).round()
        : 0;
    final int eleGecen = amount - komisyon - kesinti;

    final String metin = gerceklesen >= 0
        ? '${tur.name}: ${trMoney(amount)} sattın. '
            'Kâr ${trMoney(gerceklesen)}, kesintiler '
            '${trMoney(komisyon + kesinti)}. '
            'Eline ${trMoney(eleGecen)} geçti.'
        : '${tur.name}: ${trMoney(amount)} sattın. '
            'Zarar ${trMoney(-gerceklesen)}, işlem masrafı '
            '${trMoney(komisyon)}.';

    final GameState next = state.copyWith(
      player: state.player.copyWith(
        wallet: state.player.wallet + eleGecen,
      ),
      investments: List<Holding>.unmodifiable(<Holding>[
        for (final Holding x in state.investments)
          if (x.typeId != typeId) x else yeni,
      ]),
      investmentHistory: List<InvestmentRecord>.unmodifiable(
        <InvestmentRecord>[
          ...state.investmentHistory,
          InvestmentRecord(
            typeId: typeId,
            age: yas,
            kind: InvestmentRecordKind.satti,
            amount: amount,
            realized: gerceklesen,
          ),
        ],
      ),
    );

    return InvestmentResult(
      state: _log(next, metin, yas),
      outcome: InvestmentOutcome(
        applied: true,
        text: metin,
        amount: amount,
        realized: gerceklesen,
      ),
    );
  }

  /// Vadeyi **erken** bozar: anapara geri gelir, faiz yanar.
  ///
  /// Oyun yıllık ilerlediği için vade içinde geçen "kısmi süre" yoktur;
  /// bu yüzden erken bozmada faizin tamamı kaybedilir. Ekranda bu açıkça
  /// yazılır.
  static InvestmentResult breakTermDeposit({
    required GameState state,
    required String depositId,
  }) {
    TermDeposit? kayit;
    for (final TermDeposit d in state.termDeposits) {
      if (d.id == depositId) kayit = d;
    }
    if (kayit == null) return _blocked(state, 'Böyle bir vadeli hesap yok.');

    final int yas = state.player.age;
    final String metin =
        'Vadeli hesabı vadesinden önce bozdun. ${trMoney(kayit.amount)} '
        'anapara geri geldi, faiz yandı.';

    final GameState next = state.copyWith(
      player: state.player.copyWith(
        wallet: state.player.wallet + kayit.amount,
      ),
      termDeposits: List<TermDeposit>.unmodifiable(<TermDeposit>[
        for (final TermDeposit d in state.termDeposits)
          if (d.id != depositId) d,
      ]),
      investmentHistory: List<InvestmentRecord>.unmodifiable(
        <InvestmentRecord>[
          ...state.investmentHistory,
          InvestmentRecord(
            typeId: 'vadeli',
            age: yas,
            kind: InvestmentRecordKind.vadeBozuldu,
            amount: kayit.amount,
          ),
        ],
      ),
    );

    return InvestmentResult(
      state: _log(next, metin, yas),
      outcome: InvestmentOutcome(
        applied: true,
        text: metin,
        amount: kayit.amount,
      ),
    );
  }

  /// Piyasanın o yıl kullanacağı tohum.
  ///
  /// Hayatın kimliğinden (ad, soyad, doğum şehri) ve yaştan türer. FNV-1a
  /// karması elle yazıldı: `String.hashCode` Dart sürümleri arasında
  /// değişebilir, bu sayı ise sabit kalır.
  static int marketSeed(GameState state, int age) {
    int h = 0x811c9dc5;
    void karistir(String metin) {
      for (final int kod in metin.codeUnits) {
        h = (h ^ kod) & 0xffffffff;
        h = (h * 0x01000193) & 0xffffffff;
      }
    }

    karistir(state.player.firstName);
    karistir(state.player.lastName);
    karistir(state.player.birthCity);
    // Yaş karmanın içine ayrı bir adımla girer; `h ^ age` komşu yıllarda
    // benzer tohum üretiyordu.
    h = (h ^ age) & 0xffffffff;
    h = (h * 0x01000193) & 0xffffffff;
    return h;
  }

  /// **Zorunlu satış (Paket AC, §19).** Geçim gideri gibi kaçınılmaz bir
  /// ödeme için portföyden nakit toplar.
  ///
  /// V1'de portföy geçim giderinden **tamamen korunuyordu**:
  /// `LivingCosts.apply` yalnızca cüzdana bakıyor, para yetmezse cüzdanı
  /// sıfırlıyor ve borç yazmadan "geçim sıkıntısı" kaydediyordu. Teşhiste
  /// ölçüldü — hayatların %46,7'si en az bir yıl bu durumu yaşıyordu ve o
  /// yıllarda ortalama 13,4M ₺ portföy **dokunulmadan** bileşik büyümeye
  /// devam ediyordu. Cüzdanında 5.000 ₺, portföyünde 40.000.000 ₺ olan
  /// biri "geçim giderini ödeyemedi" sayılıyordu. Artık portföy görünmez
  /// kasa değil.
  ///
  /// Sıra: **serbest pozisyonlar önce, vadeli hesap en son.** Vadeliyi
  /// bozmak faizi yakar, o yüzden son çare. İşlem sırası kapalı olan tür
  /// atlanır — zorunlu satış bile kapalı sırayı açmaz (§5).
  ///
  /// Satışlar normal [sell] ve [breakTermDeposit] üzerinden geçer:
  /// gerçekleşen kâr/zarar, komisyon, kazanç kesintisi, geçmiş kaydı ve
  /// günlük satırı tek yerden yazılır. İkinci bir muhasebe kurulmaz.
  ///
  /// [needed] **eline geçmesi gereken** net tutardır; komisyon ve kesinti
  /// düşüldükten sonra bu kadar nakit kalmalıdır.
  static ({GameState state, int raised}) raiseCashForExpense({
    required GameState state,
    required int needed,
  }) {
    if (needed <= 0) return (state: state, raised: 0);
    GameState s = state;
    final int baslangic = state.player.wallet;

    // Riskli pozisyonlar: en büyük olandan başla. Sebebi şu — küçük
    // pozisyonu tamamen tüketip portföyü parçalamak yerine büyük
    // pozisyondan bir dilim almak oyuncunun dağılımını daha az bozar.
    final List<Holding> sirali = state.investments
        .where((Holding h) => h.value > 0)
        .toList(growable: true)
      ..sort((Holding a, Holding b) => b.value.compareTo(a.value));

    for (final Holding h in sirali) {
      final int kalan = needed - (s.player.wallet - baslangic);
      if (kalan <= 0) break;
      if (s.market.haltFor(h.typeId, s.player.age) != null) continue;
      final Holding? guncel = s.holdingOf(h.typeId);
      if (guncel == null || guncel.value <= 0) continue;
      // Komisyon ve kesinti yüzünden satılan tutarın tamamı ele
      // geçmiyor; bir miktar fazla satmak gerekiyor. Oran küçük olduğu
      // için kaba bir pay yeterli, kalanı sonraki turda toplanır.
      final int hedef =
          (kalan / (1 - prototypeOnlyTradeCommission - prototypeOnlyGainWithholding))
              .ceil();
      final int miktar = hedef < guncel.value ? hedef : guncel.value;
      final InvestmentResult r =
          sell(state: s, typeId: h.typeId, amount: miktar);
      if (!r.outcome.applied) continue;
      s = r.state;
    }

    // Vadeli hesap: en son. Faizi yanar.
    for (final TermDeposit d in state.termDeposits) {
      final int kalan = needed - (s.player.wallet - baslangic);
      if (kalan <= 0) break;
      final InvestmentResult r = breakTermDeposit(state: s, depositId: d.id);
      if (!r.outcome.applied) continue;
      s = r.state;
    }

    return (state: s, raised: s.player.wallet - baslangic);
  }

  /// Boşanma payı gibi **zorunlu** bir ödeme için, belirtilen yaştan
  /// sonra açılmış pozisyonlardan nakit toplar.
  ///
  /// Kasıtlı olarak yeni bir muhasebe kurmuyor: her satış normal [sell],
  /// her vade bozma normal [breakTermDeposit] üzerinden geçer. Böylece
  /// gerçekleşen kâr/zarar, geçmiş kaydı ve günlük satırı tek yerden
  /// yazılır. Sıra önce serbest pozisyonlar, sonra vadeli hesaplar:
  /// vadeliyi bozmak faizi yakar, son çare olmalı.
  static GameState raiseCashFromPositions({
    required GameState state,
    required int needed,
    required int sinceAge,
  }) {
    if (needed <= 0) return state;
    GameState s = state;
    int kalan = needed;

    for (final Holding h in state.investments) {
      if (kalan <= 0) break;
      if (h.firstBoughtAtAge < sinceAge) continue;
      final Holding? guncel = s.holdingOf(h.typeId);
      if (guncel == null || guncel.value <= 0) continue;
      final int miktar = kalan < guncel.value ? kalan : guncel.value;
      final InvestmentResult r =
          sell(state: s, typeId: h.typeId, amount: miktar);
      if (!r.outcome.applied) continue;
      s = r.state;
      kalan -= miktar;
    }

    for (final TermDeposit d in state.termDeposits) {
      if (kalan <= 0) break;
      if (d.openedAtAge < sinceAge) continue;
      final InvestmentResult r = breakTermDeposit(state: s, depositId: d.id);
      if (!r.outcome.applied) continue;
      s = r.state;
      kalan -= d.amount;
    }

    return s;
  }

  // -------------------------------------------------------------------
  // Yıllık ilerleme
  // -------------------------------------------------------------------

  /// Piyasayı ve portföyü **bir yıl** ilerletir.
  ///
  /// Yaş başına bir kez çalışır: aynı yıl ikinci kez çağrılsa durum
  /// değişmez. Portföyü olmayan oyuncuda da piyasa ilerler, çünkü fiyat
  /// endeksi oyuncunun alım yapmasını beklemez.
  static GameState advanceYear({
    required GameState state,
    required int newAge,
  }) {
    if (MarketEngine.alreadyAdvancedAt(state.market, newAge)) return state;

    // Piyasa **kendi akışından** zar atar, oyunun ana rastgele akışından
    // değil. Neden: yıllık ilerlemeyi ana akışa bağlamak bütün tohuma
    // çakılı testlerin akışını kaydırıyordu — bir sistemi eklemek
    // alakasız yerlerde ölüm yılını değiştiriyor demek. Tohum hayatın
    // kimliğinden ve yaştan türer: aynı hayatın aynı yılı her zaman aynı
    // piyasayı verir, iki ayrı hayat ayrı piyasa görür ve hiçbir çekiliş
    // ana akıştan çalınmaz.
    final ({MarketState state, MarketYear year}) piyasa = MarketEngine.advance(
      state: state.market,
      newAge: newAge,
      rng: Random(marketSeed(state, newAge)),
    );

    // ---- Şirket sağlığı (Paket AD/2) ---------------------------------
    // Şirketlerin gizli göstergeleri ve sektör gücü her yıl yürür. Olay
    // katmanı **bundan sonra** çalışıyor, çünkü olayların ihtimali bu
    // duruma bakıyor: borcu yıllardır artan şirketin haberi kötü olur.
    // Kendi zar akışını kullanıyor, ana akıştan çekiliş çalmıyor.
    final ({
      Map<String, CompanyVitals> vitals,
      Map<String, int> sectorStrength,
      Map<String, String> statusChanges,
    }) sirketler = CompanyEngine.advance(
      state: state.market,
      regime: piyasa.state.regime,
      rng: Random(marketSeed(state, newAge) ^ 0x1f3a7c11),
    );
    final MarketState sirketliPiyasa = piyasa.state.copyWith(
      companyVitals: sirketler.vitals,
      sectorStrength: sirketler.sectorStrength,
      // Sessiz toparlanmalar olay katmanından **önce** işleniyor: aynı yıl
      // hem düzelip hem kötü haber alan şirket olabilir, ama kötü haber
      // son sözü söyler.
      companyStatus: sirketler.statusChanges.isEmpty
          ? piyasa.state.companyStatus
          : Map<String, String>.unmodifiable(<String, String>{
              ...piyasa.state.companyStatus,
              ...sirketler.statusChanges,
            }),
    );

    // ---- Olay katmanı (Paket AC) --------------------------------------
    // Olaylar **kendi zarını** kullanır (piyasa tohumundan türer) ve
    // etkileri portföye uygulanır, endekse değil: endeks bütün oyuncular
    // için ortaktır, olay etkisi ise pozisyona özeldir. Endeksi olayla
    // oynatmak portföyü olmayan oyuncunun fiyatını da kaydırır ve
    // etkiyi iki kez sayardı.
    final IncidentOutcome olaylar = IncidentEngine.advance(
      state: sirketliPiyasa,
      regime: piyasa.state.regime,
      newAge: newAge,
      basketValue: state.holdingOf('hisse')?.value ?? 0,
      fundValue: state.holdingOf('fon')?.value ?? 0,
      rng: Random(marketSeed(state, newAge) ^ 0x5bf03635),
    );

    GameState sonuc = state.copyWith(
      market: sirketliPiyasa.copyWith(
        companyStatus: Map<String, String>.unmodifiable(olaylar.companyStatus),
        companyClosedAtAge:
            Map<String, int>.unmodifiable(olaylar.companyClosedAtAge),
        companySuccessors:
            Map<String, String>.unmodifiable(olaylar.companySuccessors),
        halts: List<TradingHalt>.unmodifiable(olaylar.halts),
        incidents: List<MarketIncident>.unmodifiable(<MarketIncident>[
          ...state.market.incidents,
          ...olaylar.incidents,
        ]),
      ),
    );
    sonuc = _revaluePortfolio(sonuc, piyasa.year, newAge, olaylar);
    sonuc = _applyIncidentCash(sonuc, olaylar, newAge);
    sonuc = _settleTermDeposits(sonuc, newAge);
    sonuc = _maybeMarketNotice(sonuc, piyasa.year, newAge);
    return sonuc;
  }

  /// Pozisyonların değerini yılın getirisiyle günceller.
  static GameState _revaluePortfolio(
    GameState state,
    MarketYear year,
    int newAge,
    IncidentOutcome olaylar,
  ) {
    if (state.investments.isEmpty) return state;

    // **Yoğunlaşma (§24).** Portföyün ne kadarı tek bir riskli varlıkta?
    // Tamamı tek varlıktaysa o varlığın kendi gürültüsü büyür; dağıtılmışsa
    // etkisi kaybolur. Çeşitlendirme **kazanç garantisi vermez**, yalnızca
    // oynaklığı düşürür. Vadeli hesap riskli sayılmaz.
    final int riskliToplam = state.investments
        .fold<int>(0, (int t, Holding h) => t + (h.value > 0 ? h.value : 0));
    final int enBuyuk = state.investments.fold<int>(
        0, (int t, Holding h) => h.value > t ? h.value : t);
    final double yogunlasma =
        riskliToplam <= 0 ? 0 : (enBuyuk / riskliToplam).clamp(0.0, 1.0);
    // 0,5'te (iki eşit varlık) etki yok; 1,0'da tam zam.
    final double yogunlasmaZammi = ((yogunlasma - 0.5) / 0.5).clamp(0.0, 1.0) *
        prototypeOnlyConcentrationVolBoost;

    final List<Holding> yeni = <Holding>[];
    final List<InvestmentRecord> kayitlar = <InvestmentRecord>[];
    for (final Holding h in state.investments) {
      final double? getiri = year.returns[h.typeId];
      if (getiri == null || h.isEmpty) {
        yeni.add(h);
        continue;
      }
      // Yoğunlaşma iki şey yapar: sapmayı büyütür **ve** beklenen getiriyi
      // düşürür.
      //
      // İlk yazımda bütün getiriyi çarpıyordum (`getiri * (1 + zam)`).
      // O, eğilimi de çarpıyordu: yoğunlaşan portföyün beklenen getirisi
      // yükseliyordu. Sonuç ölçümde görüldü: 100 hayatta bir oyuncu
      // **10,2 milyar ₺** ile öldü. Düzeltip yalnızca sapmayı büyüttüm ve
      // yorumuna "beklenen değer kaymaz" yazdım.
      //
      // **O yorum tek yıl için doğruydu, bileşik servet için değil.**
      // AD/6 ölçümünde 60 yıllık "%100 hisse" stratejisinin en iyi %10'u
      // ₺1,56 milyar, en yükseği ₺211.732 milyon ve milyarder payı %12,7
      // çıktı: sapmayı büyütmek medyanı düşürürken üst kuyruğu
      // patlatıyor, yani ceza diye yazılan şey piyango bileti oluyor.
      //
      // Doğrusu, yoğunlaşmanın **bedeli** olması: aynı riski çeşitlenerek
      // daha ucuza alabilecekken almamanın karşılığı, her yıl eğilimin bir
      // miktar altında kalmak (§9).
      double etkinGetiri = getiri;
      if (yogunlasmaZammi > 0 && h.value == enBuyuk) {
        final double egilim = investmentTypeById(h.typeId)?.carry ?? 0;
        final double ceza = prototypeOnlyConcentrationDrag *
            (yogunlasmaZammi / prototypeOnlyConcentrationVolBoost);
        etkinGetiri =
            egilim - ceza + (getiri - egilim) * (1 + yogunlasmaZammi);
      }
      // Olay çarpanı (şirket batışı, panik, sektör…).
      final double olayCarpani = olaylar.multipliers[h.typeId] ?? 1.0;
      // Fonun yıllık yönetim gideri (§22).
      final double yonetimGideri =
          h.typeId == 'fon' ? prototypeOnlyFundAnnualFee : 0;

      final int yeniDeger =
          (h.value * (1 + etkinGetiri) * olayCarpani * (1 - yonetimGideri))
              .round();
      final int guvenli = yeniDeger < 0 ? 0 : yeniDeger;
      yeni.add(h.copyWith(value: guvenli));

      // Yalnızca **sıra dışı** yıl geçmişe yazılır; her yılın hareketi
      // yazılsa geçmiş okunamaz hâle gelirdi. Ölçü gerçekleşen değişimdir,
      // ham getiri değil: olay etkisi de sayılsın.
      final double gercekOran =
          h.value <= 0 ? 0 : (guvenli - h.value) / h.value;
      if (gercekOran.abs() >= prototypeOnlyBigMove) {
        kayitlar.add(
          InvestmentRecord(
            typeId: h.typeId,
            age: newAge,
            kind: gercekOran > 0
                ? InvestmentRecordKind.buyukKazanc
                : InvestmentRecordKind.buyukKayip,
            amount: (guvenli - h.value).abs(),
          ),
        );
      }
    }

    return state.copyWith(
      investments: List<Holding>.unmodifiable(yeni),
      investmentHistory: kayitlar.isEmpty
          ? state.investmentHistory
          : List<InvestmentRecord>.unmodifiable(<InvestmentRecord>[
              ...state.investmentHistory,
              ...kayitlar,
            ]),
    );
  }

  /// Olayların nakit tarafını uygular: temettü girişi ve fon tasfiyesi.
  ///
  /// **Tasfiye bir kez olur.** Fon pozisyonu piyasa değerinden nakde
  /// döner: gerçekleşen kâr/zarar normal satış muhasebesinden geçer,
  /// böylece iki yerde iki ayrı hesap olmaz. Tasfiyede komisyon ve
  /// kazanç kesintisi **alınmaz** — bu oyuncunun kararı değil, fonun
  /// kapanması.
  /// Bir olay seçiminin portföy hamlesini uygular (Paket AD, §AD/3).
  ///
  /// **İkinci bir ekonomi motoru değil:** hamle bu sınıfın kendi
  /// [buy]/[sell] yollarından geçiyor, yani komisyon, kazanç kesintisi,
  /// işlem durması ve maliyet esası aynen işliyor. Hamle **başarısız
  /// olabilir** (işlem durmuşsa, para yetmiyorsa, pozisyon yoksa); o zaman
  /// durum değişmez ve oyuncu yalnızca metni okur.
  ///
  /// Sonucun iyi mi kötü mü olduğunu burası **bilmiyor**: panikte satmak
  /// da almak da sonraki yılların piyasasına bağlı (§6).
  static GameState applyEventAction(
    GameState state, {
    required PortfolioAction action,
    required String typeId,
    required double share,
  }) {
    final double pay = share.clamp(0.05, 1.0);
    switch (action) {
      case PortfolioAction.satKismi:
      case PortfolioAction.karAl:
        final Holding? h = state.holdingOf(typeId);
        if (h == null || h.value <= 0) return state;
        // Kâr alma yalnızca kârdayken anlamlı.
        if (action == PortfolioAction.karAl && h.value <= h.costBasis) {
          return state;
        }
        final int miktar = (h.value * pay).round();
        if (miktar < kInvestmentMinBuy) return state;
        final InvestmentResult r =
            sell(state: state, typeId: typeId, amount: miktar);
        return r.outcome.applied ? r.state : state;

      case PortfolioAction.alKismi:
        final int nakit = state.player.wallet;
        final int miktar = (nakit * pay).round();
        if (miktar < kInvestmentMinBuy) return state;
        final InvestmentResult r =
            buy(state: state, typeId: typeId, amount: miktar);
        return r.outcome.applied ? r.state : state;
    }
  }

  static GameState _applyIncidentCash(
    GameState state,
    IncidentOutcome olaylar,
    int newAge,
  ) {
    if (olaylar.isEmpty) return state;
    GameState s = state;

    for (final MarketIncident olay in olaylar.incidents) {
      switch (olay.kind) {
        case IncidentKind.temettu:
          if (olay.cashDelta <= 0) break;
          s = s.copyWith(
            player: s.player.copyWith(
              wallet: s.player.wallet + olay.cashDelta,
            ),
          );
          s = _log(
            s,
            'Beklemediğin bir temettü geldi: ${trMoney(olay.cashDelta)}.',
            newAge,
          );

        case IncidentKind.fonTasfiye:
          final Holding? fon = s.holdingOf('fon');
          if (fon == null || fon.isEmpty) break;
          final int deger = fon.value;
          final int gerceklesen = deger - fon.costBasis;
          s = s.copyWith(
            player: s.player.copyWith(wallet: s.player.wallet + deger),
            investments: List<Holding>.unmodifiable(<Holding>[
              for (final Holding h in s.investments)
                if (h.typeId != 'fon')
                  h
                else
                  h.copyWith(
                    value: 0,
                    costBasis: 0,
                    realizedProfit: h.realizedProfit + gerceklesen,
                  ),
            ]),
            investmentHistory: List<InvestmentRecord>.unmodifiable(
              <InvestmentRecord>[
                ...s.investmentHistory,
                InvestmentRecord(
                  typeId: 'fon',
                  age: newAge,
                  kind: InvestmentRecordKind.satti,
                  amount: deger,
                  realized: gerceklesen,
                ),
              ],
            ),
          );
          s = _log(
            s,
            'Fon tasfiye edildi. Payın ${trMoney(deger)} olarak hesabına '
            'geçti; senin kararın değildi.',
            newAge,
          );

        default:
          break;
      }
    }
    return s;
  }

  /// Yalnızca ölçüm/test içindir: olayların nakit tarafını uygular.
  @visibleForTesting
  static GameState debugApplyIncidentCash(
    GameState state,
    IncidentOutcome olaylar,
    int newAge,
  ) =>
      _applyIncidentCash(state, olaylar, newAge);

  /// Vadesi dolan hesapları kapatır ve parayı cüzdana yazar.
  static GameState _settleTermDeposits(GameState state, int newAge) {
    if (state.termDeposits.isEmpty) return state;

    final List<TermDeposit> kalan = <TermDeposit>[];
    final List<TermDeposit> dolan = <TermDeposit>[];
    for (final TermDeposit d in state.termDeposits) {
      if (d.maturedAt(newAge)) {
        dolan.add(d);
      } else {
        kalan.add(d);
      }
    }
    if (dolan.isEmpty) return state;

    int giren = 0;
    final List<InvestmentRecord> kayitlar = <InvestmentRecord>[];
    final List<LifeLogEntry> satirlar = <LifeLogEntry>[];
    for (final TermDeposit d in dolan) {
      giren += d.maturityValue;
      kayitlar.add(
        InvestmentRecord(
          typeId: 'vadeli',
          age: newAge,
          kind: InvestmentRecordKind.vadeKapandi,
          amount: d.maturityValue,
          realized: d.interest,
        ),
      );
      satirlar.add(
        LifeLogEntry(
          age: newAge,
          text: 'Vadeli hesabın doldu: ${trMoney(d.maturityValue)} '
              'hesabına geçti (${trMoney(d.interest)} faiz).',
          category: LogCategory.kisisel,
        ),
      );
    }

    return state.copyWith(
      player: state.player.copyWith(
        wallet: state.player.wallet + giren,
      ),
      termDeposits: List<TermDeposit>.unmodifiable(kalan),
      investmentHistory: List<InvestmentRecord>.unmodifiable(
        <InvestmentRecord>[...state.investmentHistory, ...kayitlar],
      ),
      log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
        ...state.log,
        ...satirlar,
      ]),
    );
  }

  /// Piyasa belirgin hareket ettiyse bildirim açar.
  ///
  /// **Her yıl pencere açılmaz:** yalnızca portföyü olan oyuncuda, büyük
  /// hareket ya da kriz/güçlü yılda ve iki bildirim arasında en az
  /// [prototypeOnlyNoticeGap] yıl geçmişse.
  static GameState _maybeMarketNotice(
    GameState state,
    MarketYear year,
    int newAge,
  ) {
    if (state.investments.isEmpty) return state;

    final int? son = state.market.lastNoticeAge;
    if (son != null && newAge - son < prototypeOnlyNoticeGap) return state;

    // Oyuncunun **gerçekten tuttuğu** varlıklardaki en büyük hareket.
    double enBuyuk = 0;
    for (final Holding h in state.investments) {
      if (h.isEmpty) continue;
      final double? g = year.returns[h.typeId];
      if (g == null) continue;
      if (g.abs() > enBuyuk.abs()) enBuyuk = g;
    }
    final bool belirgin = enBuyuk.abs() >= prototypeOnlyBigMove ||
        (year.regime.isNotable && enBuyuk.abs() >= prototypeOnlyBigMove / 2);
    if (!belirgin) return state;

    return state.copyWith(
      market: state.market.copyWith(lastNoticeAge: newAge),
      notices: List<PendingNotice>.unmodifiable(<PendingNotice>[
        ...state.notices,
        PendingNotice(
          id: 'piyasa-$newAge',
          kind: NoticeKind.banka,
          age: newAge,
          title: enBuyuk >= 0 ? 'Piyasa iyi gitti' : 'Piyasa tatsızdı',
          text: marketNoticeText(year: year, biggestMove: enBuyuk),
        ),
      ]),
    );
  }

  /// Piyasa bildiriminin metni.
  ///
  /// Doğal Türkçe; "finansal piyasalarda olumlu gelişmeler yaşandı" gibi
  /// robotik kalıp yok. Hiçbir cümle tavsiye vermez.
  static String marketNoticeText({
    required MarketYear year,
    required double biggestMove,
  }) {
    final double hisse = year.returns['hisse'] ?? 0;
    final double altin = year.returns['altin'] ?? 0;

    if (year.regime == MarketRegime.kriz) {
      if (altin > 0 && hisse < 0) {
        return 'Piyasalar bu yıl tatsızdı. Hisse tarafı sert düştü, '
            'altın ise portföyü biraz tuttu.';
      }
      return 'Zor bir yıl oldu. Ekranı açınca rakam can sıkıyor; '
          'böyle yıllar da oluyor.';
    }
    if (year.regime == MarketRegime.guclu && biggestMove > 0) {
      return 'Bu yıl yatırımcıların yüzü güldü. Portföyün de bundan '
          'payını aldı.';
    }
    if (biggestMove > 0) {
      return 'Piyasa bu yıl iyi yürüdü. Portföyün bir köşesi yüzünü '
          'güldürdü.';
    }
    return 'Bu yıl piyasa pek yüz güldürmedi. Rakam biraz geri gitti.';
  }

  // -------------------------------------------------------------------
  // Yardımcılar
  // -------------------------------------------------------------------

  static InvestmentResult _blocked(GameState state, String reason) =>
      InvestmentResult(
        state: state,
        outcome: InvestmentOutcome(applied: false, text: reason),
      );

  static GameState _log(GameState state, String text, int age) =>
      state.copyWith(
        log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
          ...state.log,
          LifeLogEntry(age: age, text: text, category: LogCategory.kisisel),
        ]),
      );
}
