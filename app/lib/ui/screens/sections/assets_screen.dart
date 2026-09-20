import 'package:flutter/material.dart';

import '../../../data/shop_catalog.dart';
import '../../../domain/interaction/item_actions.dart';
import '../../../domain/models/game_state.dart';
import '../../../domain/models/owned_item.dart';
import '../../../domain/models/person.dart';
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
enum _AssetsPage { kok, magaza }

class AssetsScreen extends StatefulWidget {
  const AssetsScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<AssetsScreen> createState() => _AssetsScreenState();
}

class _AssetsScreenState extends State<AssetsScreen> {
  _AssetsPage _page = _AssetsPage.kok;
  ItemOutcome? _sonMagazaSonucu;

  void _buy(ShopProduct product) {
    final ItemOutcome? outcome = GameScope.of(context).buyProduct(product);
    if (outcome == null) return;
    setState(() => _sonMagazaSonucu = outcome);
  }

  @override
  Widget build(BuildContext context) {
    final GameState state = GameScope.of(context).state!;

    if (_page == _AssetsPage.magaza) {
      return _ShopView(
        state: state,
        lastOutcome: _sonMagazaSonucu,
        onBuy: _buy,
        onBack: () => setState(() {
          _page = _AssetsPage.kok;
          _sonMagazaSonucu = null;
        }),
      );
    }

    // Eşyalar okunaklı olsun diye türe göre sıralanır.
    final List<OwnedItem> esyalar = state.items.toList(growable: true)
      ..sort((OwnedItem a, OwnedItem b) => a.name.compareTo(b.name));
    final List<ShopProduct> urunler = shopProductsFor(state.player.age);

    return SectionScaffold(
      title: 'Varlıklar',
      onBack: widget.onBack,
      children: <Widget>[
        _WalletCard(balance: state.player.walletLabel),
        const SizedBox(height: 12),
        if (urunler.isNotEmpty) ...<Widget>[
          MenuRow(
            title: 'Mağaza',
            subtitle: 'Küçük alışveriş: aksesuar ve birkaç eşya',
            icon: Icons.storefront_outlined,
            trailingText: '${urunler.length}',
            onTap: () => setState(() => _page = _AssetsPage.magaza),
          ),
          const SizedBox(height: 12),
        ],
        if (esyalar.isNotEmpty) ...<Widget>[
          const _GroupTitle('Eşyalar'),
          const SizedBox(height: 8),
          for (final OwnedItem esya in esyalar) ...<Widget>[
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

/// Mağaza sayfası: yaşa uygun birkaç ürün.
class _ShopView extends StatelessWidget {
  const _ShopView({
    required this.state,
    required this.lastOutcome,
    required this.onBuy,
    required this.onBack,
  });

  final GameState state;
  final ItemOutcome? lastOutcome;
  final void Function(ShopProduct product) onBuy;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<ShopProduct> urunler = shopProductsFor(state.player.age);

    return SectionScaffold(
      title: 'Mağaza',
      subtitle: 'Cüzdanında ${state.player.walletLabel} var.',
      backLabel: 'Varlıklar',
      onBack: onBack,
      children: <Widget>[
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
        const InfoPanel(
          icon: Icons.info_outline,
          text: 'Aldığın aksesuarı takmak için Varlıklar\'tan ilgili eşyaya '
              'gir. Geniş mağaza, kredi ve taşıt alımı henüz yazılmadı.',
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
