import 'package:flutter/material.dart';

import '../../data/item_catalog.dart';
import '../../domain/economy/housing.dart';
import '../../domain/interaction/item_actions.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/owned_item.dart';
import '../../state/game_controller.dart';
import '../../state/game_scope.dart';
import 'effect_chips.dart';
import 'kilim_divider.dart';

/// Bir eşyanın ayrıntısı ve türüne uygun eylemleri.
///
/// Yalnızca gerçekten yapılabilen eylemler düğme olur; türe uymayan eylem
/// hiç gösterilmez (kol saatine korna takılmaz, kitap sürülmez).
class ItemDetailSheet extends StatefulWidget {
  const ItemDetailSheet({super.key, required this.itemId});

  final String itemId;

  static Future<void> show(BuildContext context, {required String itemId}) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext context) => ItemDetailSheet(itemId: itemId),
    );
  }

  @override
  State<ItemDetailSheet> createState() => _ItemDetailSheetState();
}

class _ItemDetailSheetState extends State<ItemDetailSheet> {
  ItemOutcome? _lastOutcome;

  void _apply(ItemOutcome? outcome) {
    if (outcome == null) return;
    setState(() => _lastOutcome = outcome);
  }

  Future<void> _attach(OwnedItem item) async {
    final GameController controller = GameScope.of(context);
    final List<OwnedItem> aksesuarlar =
        controller.compatibleAccessoriesFor(item);
    if (aksesuarlar.isEmpty) return;

    final OwnedItem? secim = await showModalBottomSheet<OwnedItem>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                '${item.name} için aksesuar seç',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final OwnedItem a in aksesuarlar)
              ListTile(
                leading: Icon(a.type.icon),
                title: Text(a.name),
                subtitle: Text(a.conditionLabel),
                onTap: () => Navigator.of(context).pop(a),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (secim == null || !mounted) return;
    _apply(GameScope.of(context).attachAccessory(item.id, secim.id));
  }

  /// Satıştan önce teklif edilen tutar gösterilir ve onay alınır.
  Future<void> _sell(OwnedItem item) async {
    final GameController controller = GameScope.of(context);
    final int bedel = controller.estimatedPriceFor(item);

    final bool? onay = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('${item.name} satılsın mı?'),
        content: Text(
          'Teklif edilen tutar: $bedel ₺\n'
          'Durumu: ${item.conditionLabel}'
          '${item.attachments.isEmpty ? '' : '\nTakılı aksesuarlar da '
              'eşyayla birlikte gider.'}\n\n'
          'Satarsan eşya envanterinden çıkar ve geri alamazsın.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('$bedel ₺ karşılığında sat'),
          ),
        ],
      ),
    );
    if (onay != true || !mounted) return;

    final ItemOutcome? outcome = GameScope.of(context).sellItem(item.id);
    if (!mounted) return;
    // Eşya satıldıysa detay sayfası kapanır: satılmış eşyada bakım veya
    // aksesuar ekranı açık kalmaz.
    if (outcome != null && outcome.applied) {
      Navigator.of(context).pop();
      return;
    }
    _apply(outcome);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final GameController controller = GameScope.of(context);
    final GameState state = controller.state!;
    final OwnedItem? item = state.itemById(widget.itemId);
    if (item == null) return const SizedBox.shrink();

    final List<ItemActionKind> actions = controller.itemActionsFor(item);
    final Set<ItemActionKind> anlamli = actionsFor(item.type.kind);
    final List<ItemActionKind> kapali = anlamli
        .where((ItemActionKind a) => !actions.contains(a))
        .toList(growable: false);

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(item.type.icon, color: theme.colorScheme.secondary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.name,
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const KilimDivider(),
              const SizedBox(height: 14),
              _Row(label: 'Durum', value: item.conditionLabel),
              _Row(label: 'Kondisyon', value: '${item.condition}/100'),
              _Row(label: 'Edinme', value: item.source.label),
              _Row(label: 'Edinildiği yaş', value: '${item.acquiredAtAge}'),
              if (item.purchasePrice != null)
                _Row(
                  label: 'Satın alma fiyatı',
                  value: '${item.purchasePrice} ₺',
                ),
              if (item.location != null)
                _Row(label: 'Konum', value: item.location!),
              if (item.isProperty) ...<Widget>[
                _Row(
                  label: 'Oturum',
                  value: controller.state!.residenceItemId == item.id
                      ? 'Bu evde yaşıyorsun'
                      : item.rentedOut
                          ? 'Kirada (yılda '
                              '${Housing.yearlyRentOf(item)} ₺)'
                          : 'Boş duruyor',
                ),
              ],
              if (item.isVehicle || item.isProperty) ...<Widget>[
                _Row(label: 'Tür', value: item.type.name),
                _Row(
                  label: 'Sahip',
                  value: controller.state!.player.fullName,
                ),
                _Row(
                  label: 'Güncel satış değeri',
                  value: '${controller.estimatedPriceFor(item)} ₺',
                ),
              ],
              if (item.attachments.isNotEmpty)
                _Row(
                  label: 'Takılı aksesuarlar',
                  value: item.attachments
                      .map((String a) => itemTypeOrFallback(a).name)
                      .join(', '),
                ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: item.condition / 100,
                  minHeight: 8,
                  backgroundColor:
                      theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    item.condition >= 45
                        ? theme.colorScheme.secondary
                        : theme.colorScheme.error,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  for (final ItemActionKind action in actions)
                    FilledButton.tonal(
                      onPressed: () => _onAction(item, action),
                      child: Text(_label(controller, item, action)),
                    ),
                ],
              ),
              if (item.isProperty) ...<Widget>[
                const SizedBox(height: 4),
                _HousingActions(item: item),
              ],
              for (final ItemActionKind action in kapali)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${actionLabel(action, item.type.kind)}: '
                          '${controller.itemAvailability(item, action).reason ?? ''}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_lastOutcome != null) ...<Widget>[
                const SizedBox(height: 16),
                _OutcomeCard(outcome: _lastOutcome!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _label(
    GameController controller,
    OwnedItem item,
    ItemActionKind action,
  ) {
    final String temel = actionLabel(action, item.type.kind);
    switch (action) {
      case ItemActionKind.bakim:
        return '$temel (${controller.repairCostFor(item)} ₺)';
      case ItemActionKind.sat:
        return '$temel (${controller.estimatedPriceFor(item)} ₺)';
      default:
        return temel;
    }
  }

  void _onAction(OwnedItem item, ItemActionKind action) {
    switch (action) {
      case ItemActionKind.aksesuarTak:
        _attach(item);
      case ItemActionKind.sat:
        _sell(item);
      case ItemActionKind.kullan:
      case ItemActionKind.temizle:
      case ItemActionKind.bakim:
        _apply(GameScope.of(context).performItemAction(item.id, action));
    }
  }
}

class _OutcomeCard extends StatelessWidget {
  const _OutcomeCard({required this.outcome});

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
          if (outcome.noNewBenefit) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              'Bu yaş için bu eşyadan kazanacağın kalmadı; kullanmak yine '
              'de eşyayı eskitir.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Konuta özgü eylemler: taşınma ve kiraya verme (D-043).
///
/// Mülk sahipliği ile oturulan ev ayrıdır; bu yüzden eylemler ayrı
/// gösterilir ve engel varsa gerekçesi yazılır.
class _HousingActions extends StatefulWidget {
  const _HousingActions({required this.item});

  final OwnedItem item;

  @override
  State<_HousingActions> createState() => _HousingActionsState();
}

class _HousingActionsState extends State<_HousingActions> {
  String? _sonuc;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final GameController controller = GameScope.of(context);
    final OwnedItem? guncel = controller.state?.itemById(widget.item.id);
    if (guncel == null) return const SizedBox.shrink();

    final String tasinmaEngeli = controller.moveBlockReason(guncel);
    final String kiraEngeli = controller.rentOutBlockReason(guncel);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: FilledButton.tonal(
                key: const Key('home_move_in'),
                onPressed: tasinmaEngeli.isEmpty
                    ? () => setState(() {
                          _sonuc = controller.moveInto(guncel)?.text;
                        })
                    : null,
                child: Text(
                  'Bu eve taşın (${Housing.prototypeOnlyMoveCost} ₺)',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton(
                key: const Key('home_rent_toggle'),
                onPressed: guncel.rentedOut
                    ? () => setState(() {
                          _sonuc = controller.endLease(guncel)?.text;
                        })
                    : (kiraEngeli.isEmpty
                        ? () => setState(() {
                              _sonuc = controller.rentOutHome(guncel)?.text;
                            })
                        : null),
                child: Text(
                  guncel.rentedOut
                      ? 'Kirayı bitir'
                      : 'Kiraya ver (yılda '
                          '${Housing.yearlyRentOf(guncel)} ₺)',
                ),
              ),
            ),
          ],
        ),
        if (tasinmaEngeli.isNotEmpty || (kiraEngeli.isNotEmpty && !guncel.rentedOut))
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              tasinmaEngeli.isNotEmpty ? tasinmaEngeli : kiraEngeli,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        if (_sonuc != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_sonuc!, style: theme.textTheme.bodySmall),
          ),
      ],
    );
  }
}
