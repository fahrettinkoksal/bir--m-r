import 'package:flutter/material.dart';

import '../../../data/shop_catalog.dart';
import '../../../domain/interaction/item_actions.dart';
import '../../../data/name_pool.dart';
import '../../../domain/economy/housing.dart';
import '../../../domain/economy/living_costs.dart';
import '../../../domain/models/game_state.dart';
import '../../../domain/models/owned_item.dart';
import '../../../domain/models/person.dart';
import '../../../state/game_controller.dart';
import '../../../state/game_scope.dart';
import '../../widgets/effect_chips.dart';
import '../../widgets/item_detail_sheet.dart';
import '../../widgets/section_scaffold.dart';

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

  /// Emlakçıda seçilen şehir; diğer mağazalarda kullanılmaz.
  String? _secilenSehir;

  void _buy(ShopProduct product) {
    final ItemOutcome? outcome = GameScope.of(context)
        .buyProduct(product, location: _secilenSehir);
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
        selectedCity: _secilenSehir ?? Housing.cityOf(state),
        onCityChanged: (String sehir) =>
            setState(() => _secilenSehir = sehir),
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
      title: 'Varlıklar',
      onBack: widget.onBack,
      children: <Widget>[
        _WalletCard(balance: state.player.walletLabel),
        const SizedBox(height: 10),
        const SizedBox(height: 2),
        _ResidenceCard(state: state),
        const SizedBox(height: 10),
        // Yıllık geçim gideri gerçek hesaptan okunur (D-033).
        InfoPanel(
          icon: Icons.receipt_long_outlined,
          text: LivingCosts.yearlyCost(state) == 0
              ? LivingCosts.labelFor(state)
              : '${LivingCosts.labelFor(state)} Yıllık geçim giderin: '
                  '${LivingCosts.yearlyCost(state)} ₺.'
                  '${state.hardshipYears > 0 ? ' Bu yıl geçim sıkıntısı '
                      'çekiyorsun.' : ''}',
        ),
        const SizedBox(height: 12),
        if (magazalar.isNotEmpty) ...<Widget>[
          MenuRow(
            title: 'Mağazalar',
            subtitle: 'Genel mağaza, elektronik, spor, araç ve emlak',
            icon: Icons.storefront_outlined,
            trailingText: '${magazalar.length}',
            onTap: () => setState(() => _page = _AssetsPage.magazalar),
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
        if (state.pets.isNotEmpty) ...<Widget>[
          const _GroupTitle('Evcil hayvanlar'),
          const SizedBox(height: 8),
          for (final Pet pet in state.pets) ...<Widget>[
            _AssetTile(
              title: pet.name,
              subtitle: pet.species,
              icon: Icons.pets_outlined,
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 4),
        ],
        if (esyalar.isEmpty && state.pets.isEmpty)
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
    final List<ShopCategory> magazalar = shopCategoriesFor(state.player.age);
    return SectionScaffold(
      title: 'Mağazalar',
      subtitle: 'Cüzdanında ${state.player.walletLabel} var.',
      backLabel: 'Varlıklar',
      onBack: onBack,
      children: <Widget>[
        for (final ShopCategory kategori in magazalar) ...<Widget>[
          MenuRow(
            title: kategori.label,
            subtitle: kategori.description,
            icon: kategori.icon,
            trailingText:
                '${shopProductsIn(kategori, state.player.age).length}',
            onTap: () => onOpen(kategori),
          ),
          const SizedBox(height: 10),
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
    required this.selectedCity,
    required this.onCityChanged,
    required this.onBuy,
    required this.onBack,
  });

  final GameState state;
  final ShopCategory category;
  final ItemOutcome? lastOutcome;

  /// Emlakçıda seçili şehir.
  final String selectedCity;
  final ValueChanged<String> onCityChanged;
  final void Function(ShopProduct product) onBuy;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<ShopProduct> urunler =
        shopProductsIn(category, state.player.age);

    return SectionScaffold(
      title: category.label,
      subtitle: 'Cüzdanında ${state.player.walletLabel} var.',
      backLabel: 'Mağazalar',
      onBack: onBack,
      children: <Widget>[
        // Emlakçıda konutun hangi şehirde alındığı seçilir (D-043).
        if (category == ShopCategory.emlakci) ...<Widget>[
          Text('Şehir', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Seçtiğin şehirdeki ev mülk kaydına o şehirle yazılır. '
            'Ev almak taşınmak değildir; taşınmak için evin detayına gir.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final String sehir in sehirler)
                ChoiceChip(
                  key: Key('city_$sehir'),
                  label: Text(sehir),
                  selected: selectedCity == sehir,
                  onSelected: (_) => onCityChanged(sehir),
                ),
            ],
          ),
          const SizedBox(height: 14),
        ],
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
                        child: Text(urun.name,
                            style: theme.textTheme.titleMedium),
                      ),
                      Text(
                        '${urun.price} ₺',
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
          text: category == ShopCategory.aracGalerisi
              ? 'Araç satın almak için ehliyet gerekmez; aracı kullanmak '
                  'için gerekir. Aksesuarı takmak için Varlıklar\'tan '
                  'araca gir.'
              : category == ShopCategory.emlakci
                  ? 'Ev satın almak o eve taşındığın anlamına gelmez. '
                      'Kira, taşınma ve kredi henüz yazılmadı.'
                  : 'Aldığın aksesuarı takmak için Varlıklar\'tan ilgili '
                      'eşyaya gir.',
        ),
      ],
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
                      item.attachments.isEmpty
                          ? item.conditionLabel
                          : '${item.conditionLabel} · '
                              '${item.attachments.length} aksesuar',
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Text('Cüzdan', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              balance,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
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

class _AssetTile extends StatelessWidget {
  const _AssetTile({required this.title, required this.icon, this.subtitle});

  final String title;
  final String? subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: <Widget>[
            Icon(icon, color: theme.colorScheme.secondary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: theme.textTheme.titleMedium),
                  if (subtitle != null) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nerede yaşandığını gösteren kart ve taşınma eylemleri (D-043).
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
                'Kiraya verdiğin evlerden yıllık $kiraGeliri ₺ kira geliri '
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
