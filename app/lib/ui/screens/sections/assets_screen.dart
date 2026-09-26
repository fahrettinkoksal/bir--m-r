import 'package:flutter/material.dart';

import '../../../data/shop_catalog.dart';
import '../../../domain/economy/property_market.dart';
import '../../../domain/economy/used_vehicle_market.dart';
import '../../../domain/interaction/item_actions.dart';
import '../../../domain/economy/housing.dart';
import '../../../domain/economy/living_costs.dart';
import '../../../domain/models/game_state.dart';
import '../../../domain/models/owned_item.dart';
import '../../../state/game_controller.dart';
import '../../../state/game_scope.dart';
import '../../theme/bir_omur_theme.dart';
import '../../widgets/effect_chips.dart';
import '../../widgets/item_detail_sheet.dart';
import '../../widgets/section_scaffold.dart';
import '../../../text/turkish_text.dart';

/// Varlıklar ana menüsü (NAV-001, ECO-001).
///
/// Oyuncunun **kendi** cüzdanı, sahip olduğu eşyalar ve evcil hayvanlar
/// burada toplanır. Ailenin ekonomik durumu buraya karıştırılmaz: aile
/// varlığı oyuncunun harcanabilir parası değildir.
/// Varlıklar alt sayfaları.
enum _AssetsPage { kok, magazalar, kategori }

class AssetsScreen extends StatefulWidget {
  const AssetsScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<AssetsScreen> createState() => _AssetsScreenState();
}

class _AssetsScreenState extends State<AssetsScreen> {
  _AssetsPage _page = _AssetsPage.kok;
  ShopCategory? _kategori;
  ItemOutcome? _sonMagazaSonucu;

  void _buy(ShopProduct product) {
    final ItemOutcome? outcome = GameScope.of(context).buyProduct(product);
    if (outcome == null) return;
    setState(() => _sonMagazaSonucu = outcome);
  }

  /// İlan panosundan satın alır: fiyat ve şehir ilandan gelir.
  void _buyListing(PropertyListing listing) {
    final ItemOutcome? outcome = GameScope.of(context).buyListing(listing);
    if (outcome == null) return;
    setState(() => _sonMagazaSonucu = outcome);
  }

  /// 2. el araç ilanından satın alır (D-137): araç ilanın kondisyonuyla
  /// envantere girer.
  void _buyUsedVehicle(UsedVehicleListing listing) {
    final ItemOutcome? outcome =
        GameScope.of(context).buyUsedVehicle(listing);
    if (outcome == null) return;
    setState(() => _sonMagazaSonucu = outcome);
  }

  @override
  Widget build(BuildContext context) {
    final GameState state = GameScope.of(context).state!;

    if (_page == _AssetsPage.kategori && _kategori != null) {
      return _ShopView(
        state: state,
        category: _kategori!,
        lastOutcome: _sonMagazaSonucu,
        listings: GameScope.of(context).listings(_kategori!),
        usedListings: _kategori!.isUsedMarket
            ? GameScope.of(context).usedVehicleListings()
            : const <UsedVehicleListing>[],
        onBuyListing: _buyListing,
        onBuyUsedVehicle: _buyUsedVehicle,
        onBuy: _buy,
        onBack: () => setState(() {
          _page = _AssetsPage.magazalar;
          _kategori = null;
          _sonMagazaSonucu = null;
        }),
      );
    }

    if (_page == _AssetsPage.magazalar) {
      return _ShopCategoryList(
        state: state,
        onOpen: (ShopCategory c) => setState(() {
          _kategori = c;
          _page = _AssetsPage.kategori;
          _sonMagazaSonucu = null;
        }),
        onBack: () => setState(() => _page = _AssetsPage.kok),
      );
    }

    // Eşyalar okunaklı olsun diye türe göre sıralanır.
    final List<OwnedItem> esyalar = state.items.toList(growable: true)
      ..sort((OwnedItem a, OwnedItem b) => a.name.compareTo(b.name));
    final List<ShopCategory> magazalar = shopCategoriesFor(state.player.age);
    final List<OwnedItem> araclar =
        esyalar.where((OwnedItem i) => i.isVehicle).toList(growable: false);
    final List<OwnedItem> mulkler =
        esyalar.where((OwnedItem i) => i.isProperty).toList(growable: false);
    final List<OwnedItem> digerleri = esyalar
        .where((OwnedItem i) => !i.isVehicle && !i.isProperty)
        .toList(growable: false);

    return SectionScaffold(
      icon: Icons.account_balance_wallet_rounded,
      title: 'Varlıklar',
      accent: BirOmurAccents.yesil,
      onBack: widget.onBack,
      children: <Widget>[
        _WalletCard(balance: state.player.walletLabel),
        const SizedBox(height: 10),
        const SizedBox(height: 2),
        _ResidenceCard(state: state),
        const SizedBox(height: 10),
        // Yıllık geçim gideri gerçek hesaptan okunur (D-033) ve
        // **kalem kalem** gösterilir (D-123). Faho sordu: "bu giderler
        // neye göre belirleniyor?" — hesap artık ekranda duruyor.
        InfoPanel(
          icon: Icons.receipt_long_outlined,
          text: LivingCosts.yearlyCost(state) == 0
              ? LivingCosts.labelFor(state)
              : '${LivingCosts.labelFor(state)} Yıllık geçim giderin: '
                  '${trMoney(LivingCosts.yearlyCost(state))}.'
                  '${state.hardshipYears > 0 ? ' Bu yıl geçim sıkıntısı '
                      'çekiyorsun.' : ''}',
        ),
        if (LivingCosts.yearlyCost(state) > 0) ...<Widget>[
          const SizedBox(height: 8),
          _CostBreakdownCard(breakdown: LivingCosts.breakdownFor(state)),
        ],
        const SizedBox(height: 12),
        if (magazalar.isNotEmpty) ...<Widget>[
          MenuRow(
            title: 'Mağazalar',
            subtitle: 'Genel mağaza, elektronik, spor, araç ve emlak',
            icon: Icons.storefront_outlined,
            accent: BirOmurAccents.turuncu,
            trailingText: '${magazalar.length}',
            onTap: () => setState(() => _page = _AssetsPage.magazalar),
          ),
          const SizedBox(height: 12),
        ],
        // Banka **Aktiviteler** altına taşındı (D-108): burası sahip
        // olunan şeylerin listesi; bankaya gitmek bir eylemdir. Açık
        // borç varsa oyuncu buradan da görsün diye tek satır kalır.
        if (GameScope.of(context).totalDebt > 0) ...<Widget>[
          InfoPanel(
            icon: Icons.account_balance_outlined,
            text: 'Bankaya olan borcun '
                '${trMoney(GameScope.of(context).totalDebt)}. '
                'Kredi işlemleri Aktiviteler > Banka altında.',
          ),
          const SizedBox(height: 12),
        ],
        if (mulkler.isNotEmpty) ...<Widget>[
          const _GroupTitle('Mülkler'),
          const SizedBox(height: 8),
          for (final OwnedItem mulk in mulkler) ...<Widget>[
            _ItemTile(
              item: mulk,
              onTap: () => ItemDetailSheet.show(context, itemId: mulk.id),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 4),
        ],
        if (araclar.isNotEmpty) ...<Widget>[
          const _GroupTitle('Araçlar'),
          const SizedBox(height: 8),
          for (final OwnedItem arac in araclar) ...<Widget>[
            _ItemTile(
              item: arac,
              onTap: () => ItemDetailSheet.show(context, itemId: arac.id),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 4),
        ],
        if (digerleri.isNotEmpty) ...<Widget>[
          const _GroupTitle('Eşyalar'),
          const SizedBox(height: 8),
          for (final OwnedItem esya in digerleri) ...<Widget>[
            _ItemTile(
              item: esya,
              onTap: () => ItemDetailSheet.show(context, itemId: esya.id),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 4),
        ],
        // D-146: evcil hayvanlar buradan kaldırıldı ve İlişkiler menüsüne
        // taşındı. Faho'nun isteği: "evdeki evcil hayvanımı ilişkiler
        // kısmına taşı, varlıklarda değil." Hayvan bir mülk değildir.
        if (state.pets.isNotEmpty) ...<Widget>[
          const InfoPanel(
            icon: Icons.pets_outlined,
            text: 'Evcil hayvanların İlişkiler menüsünde; onlarla orada '
                'vakit geçirebilirsin.',
          ),
          const SizedBox(height: 10),
        ],
        if (esyalar.isEmpty)
          const InfoPanel(
            icon: Icons.inventory_2_outlined,
            text: 'Henüz kendine ait bir eşyan yok. Hediyeler, olaylar ve '
                'mağazadan aldıkların burada görünecek.',
          ),
      ],
    );
  }
}

/// Mağaza listesi: yaşa uygun ürünü olan kategoriler.
///
/// Boş kategori gösterilmez; olmayan bir dükkân için sahte düğme konmaz.
class _ShopCategoryList extends StatelessWidget {
  const _ShopCategoryList({
    required this.state,
    required this.onOpen,
    required this.onBack,
  });

  final GameState state;
  final void Function(ShopCategory category) onOpen;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    // Mağazalar üç öbekte durur (D-138): gündelik alışveriş, araç ve
    // aksesuar, konut. Öbek ve satır sırası sabittir; liste her açılışta
    // aynı görünür.
    final Map<ShopGroup, List<ShopCategory>> obekler =
        shopGroupsFor(state.player.age);
    return SectionScaffold(
      icon: Icons.storefront_rounded,
      accent: BirOmurAccents.turuncu,
      title: 'Mağazalar',
      subtitle: 'Cüzdanında ${state.player.walletLabel} var.',
      backLabel: 'Varlıklar',
      onBack: onBack,
      children: <Widget>[
        for (final ShopGroup obek in obekler.keys) ...<Widget>[
          _GroupTitle(obek.label),
          const SizedBox(height: 8),
          for (final ShopCategory kategori in obekler[obek]!) ...<Widget>[
            MenuRow(
              key: Key('magaza_${kategori.name}'),
              title: kategori.label,
              subtitle: kategori.description,
              icon: kategori.icon,
              // 2. el pazarın ürünleri katalogda durmadığı için sayısı
              // ilan havuzundan okunur (D-137).
              trailingText: kategori.isUsedMarket
                  ? '${UsedVehicleMarket.prototypeOnlyListingCount}'
                  : '${shopProductsIn(kategori, state.player.age).length}',
              onTap: () => onOpen(kategori),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 4),
        ],
        const SizedBox(height: 4),
        const InfoPanel(
          icon: Icons.info_outline,
          text: 'Ev satın almak o eve taşındığın anlamına gelmez; mülk '
              'sahipliği ile hangi hanede yaşadığın ayrı tutulur. Kredi, '
              'kira ve taşınma henüz yazılmadı.',
        ),
      ],
    );
  }
}

/// Tek bir mağazanın sayfası: yaşa uygun ürünler.
class _ShopView extends StatelessWidget {
  const _ShopView({
    required this.state,
    required this.category,
    required this.lastOutcome,
    required this.listings,
    required this.usedListings,
    required this.onBuyListing,
    required this.onBuyUsedVehicle,
    required this.onBuy,
    required this.onBack,
  });

  final GameState state;
  final ShopCategory category;
  final ItemOutcome? lastOutcome;

  /// Yaşanan ildeki ev/araç ilanları; diğer mağazalarda boştur.
  final List<PropertyListing> listings;

  /// Yaşanan ildeki 2. el araç ilanları; yalnızca pazarda doludur (D-137).
  final List<UsedVehicleListing> usedListings;
  final void Function(PropertyListing listing) onBuyListing;
  final void Function(UsedVehicleListing listing) onBuyUsedVehicle;
  final void Function(ShopProduct product) onBuy;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<ShopProduct> urunler =
        shopProductsIn(category, state.player.age);
    // Emlakçı ve araç galerisi ilan panosuyla çalışır; diğer mağazalar
    // katalog fiyatıyla.
    final bool ilanli = category.isListed;
    final List<PropertyListing> ilanlar = listings;

    return SectionScaffold(
      icon: Icons.shopping_bag_rounded,
      title: category.label,
      subtitle: 'Cüzdanında ${state.player.walletLabel} var.',
      backLabel: 'Mağazalar',
      onBack: onBack,
      children: <Widget>[
        // Ev ve araç ilanları **yalnızca oyuncunun yaşadığı ilde**
        // gösterilir (Faho'nun kesin kararı). Eskiden emlakçıda 20
        // şehirlik bir seçici vardı ve oyuncu Amasya'da yaşarken
        // İstanbul'dan ev alabiliyordu; "Türkiye geneli" liste kalktı.
        // 2. el araç pazarı kendi ilan biçimini kullanır (D-137): yaş, km
        // ve "araç detayları" satırları emlak ilanına sığmıyordu.
        if (category.isUsedMarket) ...<Widget>[
          InfoPanel(
            icon: Icons.place_outlined,
            text: '${state.player.currentCity} pazarındaki ilanlar. '
                'İlanlar yılda bir tazelenir; taşınırsan yeni şehrin '
                'pazarını görürsün. İlan detaylarını satıcı yazar, '
                'ekspertiz raporu değildir.',
          ),
          const SizedBox(height: 12),
          if (usedListings.isEmpty)
            const InfoPanel(
              icon: Icons.info_outline,
              text: 'Şu an pazarda ilan yok.',
            ),
          for (final UsedVehicleListing ilan in usedListings) ...<Widget>[
            _UsedVehicleCard(
              listing: ilan,
              affordable: state.player.wallet >= ilan.price,
              onBuy: () => onBuyUsedVehicle(ilan),
            ),
            const SizedBox(height: 10),
          ],
        ],
        if (ilanli) ...<Widget>[
          InfoPanel(
            icon: Icons.place_outlined,
            text: '${state.player.currentCity} ilanları gösteriliyor. '
                'Başka ildeki ilanlar burada listelenmez; taşınırsan '
                'ilanlar yeni şehrine göre yenilenir.',
          ),
          const SizedBox(height: 12),
          for (final PropertyListing ilan in ilanlar) ...<Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(
                          ilan.product.type.icon,
                          color: theme.colorScheme.secondary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                ilan.name,
                                style: theme.textTheme.titleMedium,
                              ),
                              // Ad kurgusal bir model adı olduğunda sınıfı
                              // altına yazılır (D-136).
                              if (ilan.product.type.segment != null)
                                Text(
                                  ilan.product.type.segment!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color:
                                        theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          trMoney(ilan.price),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${ilan.city} · ${ilan.note}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.tonal(
                        key: Key('ilan_${ilan.id}'),
                        onPressed: state.player.wallet >= ilan.price
                            ? () => onBuyListing(ilan)
                            : null,
                        child: Text(
                          state.player.wallet >= ilan.price
                              ? 'Satın al'
                              : 'Paran yetmiyor',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
        if (!ilanli)
          for (final ShopProduct urun in urunler) ...<Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(urun.type.icon, color: theme.colorScheme.secondary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(urun.name,
                                style: theme.textTheme.titleMedium),
                            if (urun.type.segment != null)
                              Text(
                                urun.type.segment!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        trMoney(urun.price),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    urun.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.tonal(
                      // Parası yetmeyen ürün alınamaz; düğme kapalıdır.
                      onPressed: state.player.wallet >= urun.price
                          ? () => onBuy(urun)
                          : null,
                      child: Text(
                        state.player.wallet >= urun.price
                            ? 'Satın al'
                            : 'Paran yetmiyor',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (lastOutcome != null) ...<Widget>[
          const SizedBox(height: 6),
          _ShopOutcome(outcome: lastOutcome!),
        ],
        const SizedBox(height: 10),
        InfoPanel(
          icon: Icons.info_outline,
          text: category.isUsedMarket
              ? 'Pazardan alınan araç ikinci eldir: envantere ilanda '
                  'yazan durumla girer, sıfır gibi değil. Yorgun bir araç '
                  'bakım ister. Araç satın almak için ehliyet gerekmez; '
                  'kullanmak için gerekir.'
              : category.cheapVehicles
              ? 'Buradaki araçlar ucuz, çünkü yaşlılar: yıl içinde '
                  'masraf çıkarabilirler. Araç satın almak için ehliyet '
                  'gerekmez; aracı kullanmak için gerekir.'
              : category.isVehicle
                  ? 'Araç satın almak için ehliyet gerekmez; aracı '
                      'kullanmak için gerekir. Aksesuarı takmak için '
                      'Varlıklar\'tan araca gir.'
                  : category.isHousing
                      ? 'Ev satın almak o eve taşındığın anlamına gelmez. '
                          'Taşınmak için Varlıklar\'taki eve gir.'
                      : 'Aldığın aksesuarı takmak için Varlıklar\'tan '
                          'ilgili eşyaya gir.',
        ),
      ],
    );
  }
}

/// 2. el araç pazarındaki tek bir ilan kartı (D-137).
///
/// Gerçek ilan düzeni: üstte model adı ve satıcı, yanında fiyat, altında
/// yaş/km/durum etiketleri, sonra "Araç detayları" satırları ve satıcının
/// tek satırlık notu.
class _UsedVehicleCard extends StatelessWidget {
  const _UsedVehicleCard({
    required this.listing,
    required this.affordable,
    required this.onBuy,
  });

  final UsedVehicleListing listing;
  final bool affordable;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color soluk = theme.colorScheme.onSurfaceVariant;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(listing.type.icon, color: theme.colorScheme.secondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(listing.name, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        <String>[
                          if (listing.type.segment != null)
                            listing.type.segment!,
                          listing.seller.label,
                        ].join(' · '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: soluk,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      trMoney(listing.price),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'sıfırı ${trMoneyShort(listing.newPrice)}',
                      style: theme.textTheme.bodySmall?.copyWith(color: soluk),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: <Widget>[
                _AdChip(text: '${listing.ageYears} yaşında'),
                _AdChip(text: '${trNumber(listing.km)} km'),
                _AdChip(text: listing.grade.label),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Araç detayları',
              style: theme.textTheme.labelLarge?.copyWith(color: soluk),
            ),
            const SizedBox(height: 6),
            for (final String satir in listing.details) ...<Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: soluk,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(satir, style: theme.textTheme.bodySmall),
                  ),
                ],
              ),
              const SizedBox(height: 2),
            ],
            const SizedBox(height: 8),
            Text(
              '“${listing.sellerNote}”',
              style: theme.textTheme.bodySmall?.copyWith(
                color: soluk,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonal(
                key: Key('ikinci_el_${listing.id}'),
                onPressed: affordable ? onBuy : null,
                child: Text(affordable ? 'Satın al' : 'Paran yetmiyor'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// İlan etiketi: yaş, km, durum.
class _AdChip extends StatelessWidget {
  const _AdChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _ShopOutcome extends StatelessWidget {
  const _ShopOutcome({required this.outcome});

  final ItemOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color accent = outcome.applied
        ? theme.colorScheme.secondary
        : theme.colorScheme.error;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(outcome.text, style: theme.textTheme.bodyMedium),
          if (outcome.effects.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            EffectChips(effects: outcome.effects),
          ],
        ],
      ),
    );
  }
}

/// Envanterdeki bir eşyanın satırı.
class _ItemTile extends StatelessWidget {
  const _ItemTile({required this.item, required this.onTap});

  final OwnedItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: <Widget>[
              Icon(item.type.icon, color: theme.colorScheme.secondary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(item.name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      <String>[
                        // Ad kurgusal model adı olduğunda sınıfı görünsün
                        // (D-136): "Foros Kent 1.4" neyin nesi belli olsun.
                        if (item.type.segment != null) item.type.segment!,
                        item.conditionLabel,
                        if (item.attachments.isNotEmpty)
                          '${item.attachments.length} aksesuar',
                      ].join(' · '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WalletCard extends StatelessWidget {
  const _WalletCard({required this.balance});

  final String balance;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    // Cüzdan, Varlıklar ekranının ana kartıdır: menü satırlarıyla aynı
    // renkli dili kullanır.
    const BirOmurAccent renk = BirOmurAccents.yesil;
    return Container(
      decoration: panelDecoration(context, radius: 22),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const AccentIconTile(
                  icon: Icons.account_balance_wallet_outlined,
                  accent: renk,
                  size: 38,
                ),
                const SizedBox(width: 12),
                Text('Cüzdan', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              balance,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: renk.deepOf(context),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Bu para yalnızca sana ait. Ailenin ekonomik durumu ayrı '
              'tutulur ve senin harcayabileceğin para sayılmaz.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupTitle extends StatelessWidget {
  const _GroupTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _ResidenceCard extends StatefulWidget {
  const _ResidenceCard({required this.state});

  final GameState state;

  @override
  State<_ResidenceCard> createState() => _ResidenceCardState();
}

class _ResidenceCardState extends State<_ResidenceCard> {
  String? _sonuc;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final GameController controller = GameScope.of(context);
    final GameState state = controller.state ?? widget.state;
    final ResidenceKind durum = Housing.residenceOf(state);
    final OwnedItem? ev = Housing.residenceHome(state);
    final int kiraGeliri = Housing.yearlyRentIncome(state);
    final bool yetiskin = state.player.age >= Housing.prototypeOnlyMinAge;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.home_outlined, color: theme.colorScheme.secondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Yaşadığın yer',
                      style: theme.textTheme.titleMedium),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              ev == null
                  ? '${durum.label} · ${Housing.cityOf(state)}'
                  : '${ev.name} · ${Housing.cityOf(state)}',
              key: const Key('residence_label'),
              style: theme.textTheme.bodyMedium,
            ),
            if (kiraGeliri > 0) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                'Kiraya verdiğin evlerden yıllık ${trMoney(kiraGeliri)} kira geliri '
                'bekleniyor.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (yetiskin) ...<Widget>[
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  if (durum != ResidenceKind.kirada)
                    Expanded(
                      child: OutlinedButton(
                        key: const Key('move_to_rental'),
                        onPressed: () => setState(() {
                          _sonuc = controller.moveToRental()?.text;
                        }),
                        child: const Text('Kiralık eve çık'),
                      ),
                    ),
                  if (durum != ResidenceKind.kirada &&
                      durum != ResidenceKind.aileYaninda)
                    const SizedBox(width: 10),
                  if (durum != ResidenceKind.aileYaninda &&
                      Housing.hasAdultAtFamilyHome(state))
                    Expanded(
                      child: OutlinedButton(
                        key: const Key('move_to_family'),
                        onPressed: () => setState(() {
                          _sonuc = controller.moveBackToFamily()?.text;
                        }),
                        child: const Text('Ailenin yanına dön'),
                      ),
                    ),
                ],
              ),
            ],
            if (_sonuc != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(_sonuc!, style: theme.textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

/// Yıllık geçim giderinin kalem kalem dökümü (D-123).
///
/// Gider **uydurulmaz**: her satır hesaplanan kalemin kendisidir ve
/// toplam bu satırların toplamıdır.
class _CostBreakdownCard extends StatelessWidget {
  const _CostBreakdownCard({required this.breakdown});

  final CostBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Gider dökümü',
              key: const Key('cost_breakdown_title'),
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            for (final ({String label, int amount}) kalem in breakdown.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        kalem.label,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      trMoney(kalem.amount),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            const Divider(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Toplam',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                Text(
                  trMoney(breakdown.total),
                  key: const Key('cost_breakdown_total'),
                  style: theme.textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              breakdown.income > 0
                  ? 'Kalemler taban tutar ile yıllık gelirinin '
                      '(${trMoney(breakdown.income)}) payından oluşur.'
                  : 'Gelirin olmadığı için yalnızca taban tutarlar '
                      'işliyor.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
