import 'package:flutter/material.dart';

import '../../../data/possession_names.dart';
import '../../../domain/models/game_state.dart';
import '../../../domain/models/person.dart';
import '../../../state/game_scope.dart';
import '../../widgets/section_scaffold.dart';

/// Varlıklar ana menüsü (NAV-001, ECO-001).
///
/// Oyuncunun **kendi** cüzdanı, sahip olduğu eşyalar ve evcil hayvanlar
/// burada toplanır. Ailenin ekonomik durumu buraya karıştırılmaz: aile
/// varlığı oyuncunun harcanabilir parası değildir.
class AssetsScreen extends StatelessWidget {
  const AssetsScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final GameState state = GameScope.of(context).state!;
    final List<String> esyalar = state.possessions.toList(growable: false)
      ..sort();

    return SectionScaffold(
      title: 'Varlıklar',
      onBack: onBack,
      children: <Widget>[
        _WalletCard(balance: state.player.walletLabel),
        const SizedBox(height: 12),
        if (esyalar.isNotEmpty) ...<Widget>[
          const _GroupTitle('Eşyalar'),
          const SizedBox(height: 8),
          for (final String esya in esyalar) ...<Widget>[
            _AssetTile(
              title: possessionName(esya),
              icon: possessionIcon(esya),
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
            text: 'Henüz kendine ait bir eşyan yok. Olaylarla edindiğin '
                'şeyler burada görünecek.',
          ),
      ],
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
