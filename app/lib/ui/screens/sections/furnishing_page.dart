import 'package:flutter/material.dart';

import '../../../domain/economy/furnishing.dart';
import '../../../domain/economy/housing.dart';
import '../../../domain/models/game_state.dart';
import '../../../domain/models/owned_item.dart';
import '../../../state/game_scope.dart';
import '../../../text/turkish_text.dart';
import '../../theme/bir_omur_theme.dart';
import '../../widgets/section_scaffold.dart';

/// **Evinin hâli** (Paket BT).
///
/// Oyuncu konut alıyor, taşınıyor, kiraya veriyor; ama evin içinde ne
/// olduğunu hiçbir yerde göremiyordu. Bu ekran yalnızca **okutur**:
/// hangi ihtiyaç karşılanmış, ne eksik, ne yıpranmış. Alışveriş yine
/// mağazadan yapılır; burada satın alma düğmesi yok, çünkü aynı ürünün
/// iki ayrı satış yolu olması ikinci bir fiyat/stok sistemi demek.
///
/// Ekran **hiçbir karar sormaz** ve döşeme eksikse kimseyi suçlamaz:
/// eksik liste bir hatırlatma, ceza değil.
class FurnishingPage extends StatelessWidget {
  const FurnishingPage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final GameState state = GameScope.of(context).state!;
    final int seviye = Furnishing.level(state);
    final List<FurnishingSlot> eksikler = Furnishing.missing(state);
    final List<OwnedItem> yipranmislar = Furnishing.wornOut(state);
    final ResidenceKind nerede = Housing.residenceOf(state);

    return SectionScaffold(
      key: const Key('furnishing_page'),
      icon: Icons.chair_rounded,
      accent: BirOmurAccents.yesil,
      title: 'Evinin hâli',
      subtitle: '${Furnishing.levelLabel(state)} · '
          '${Furnishing.essentialsFilled(state)}/'
          '${Furnishing.essentialCount} temel ihtiyaç',
      backLabel: 'Varlıklar',
      onBack: onBack,
      children: <Widget>[
        _SeviyeKarti(level: seviye, label: Furnishing.levelLabel(state)),
        const SizedBox(height: 12),
        InfoPanel(
          icon: nerede == ResidenceKind.kirada
              ? Icons.vpn_key_outlined
              : Icons.home_outlined,
          text: nerede == ResidenceKind.kirada
              ? 'Kiradasın; eşya senin, taşınınca seninle geliyor.'
              : 'Kendi evinde oturuyorsun. Eşya senin, taşınınca '
                  'seninle geliyor.',
        ),
        const SizedBox(height: 12),
        if (yipranmislar.isNotEmpty) ...<Widget>[
          InfoPanel(
            icon: Icons.build_outlined,
            text: yipranmislar.length == 1
                ? '${yipranmislar.first.name} iş görmeyecek kadar '
                    'yıprandı. Eşyalar listesinden tamir ettirebilirsin.'
                : '${yipranmislar.length} eşya iş görmeyecek kadar '
                    'yıprandı. Eşyalar listesinden tamir ettirebilirsin.',
          ),
          const SizedBox(height: 12),
        ],
        MenuGroupTitle(
          text: 'Temel ihtiyaçlar',
          accent: BirOmurAccents.yesil,
        ),
        const SizedBox(height: 8),
        for (final FurnishingSlot yuva in Furnishing.slots)
          if (yuva.essential) ...<Widget>[
            _YuvaSatiri(slot: yuva, item: Furnishing.itemFor(state, yuva)),
            const SizedBox(height: 8),
          ],
        const SizedBox(height: 6),
        MenuGroupTitle(
          text: 'Konfor',
          accent: BirOmurAccents.turuncu,
        ),
        const SizedBox(height: 8),
        for (final FurnishingSlot yuva in Furnishing.slots)
          if (!yuva.essential) ...<Widget>[
            _YuvaSatiri(slot: yuva, item: Furnishing.itemFor(state, yuva)),
            const SizedBox(height: 8),
          ],
        if (eksikler.isNotEmpty) ...<Widget>[
          const SizedBox(height: 6),
          InfoPanel(
            icon: Icons.storefront_outlined,
            text: 'Eksik olanlar Mağazalar > Ev ve yaşam altında duruyor. '
                'Eksiklerin toplamı '
                '${trMoney(eksikler.fold<int>(
                  0,
                  (int t, FurnishingSlot s) => t + s.price,
                ))}.',
          ),
        ],
      ],
    );
  }
}

/// Seviye çubuğu: tek bakışta evin ne kadar dolu olduğu.
class _SeviyeKarti extends StatelessWidget {
  const _SeviyeKarti({required this.level, required this.label});

  final int level;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      key: const Key('furnishing_level'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text('Döşeme', style: theme.textTheme.titleMedium),
              Text('%$level', style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: level / 100,
              minHeight: 10,
              backgroundColor:
                  theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// Tek bir yuva: dolu mu, hangi eşyayla, ne durumda.
class _YuvaSatiri extends StatelessWidget {
  const _YuvaSatiri({required this.slot, required this.item});

  final FurnishingSlot slot;

  /// Yuvayı dolduran eşya; yoksa `null`.
  final OwnedItem? item;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool dolu = item != null;

    return Container(
      key: Key('furnishing_slot_${slot.typeId}'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest
            .withValues(alpha: dolu ? 0.55 : 0.28),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            dolu ? Icons.check_circle_rounded : slot.type.icon,
            size: 20,
            color: dolu
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(slot.name, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  dolu
                      ? '${slot.need} · ${item!.conditionLabel}'
                      : '${slot.need} · ${trMoney(slot.price)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
