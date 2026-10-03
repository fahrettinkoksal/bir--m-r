import 'package:flutter/material.dart';

import '../../../data/investment_catalog.dart';
import '../../../domain/economy/investment_engine.dart';
import '../../../domain/models/game_state.dart';
import '../../../domain/models/interaction.dart';
import '../../../domain/models/investment.dart';
import '../../../domain/models/market_state.dart';
import '../../../state/game_controller.dart';
import '../../../state/game_scope.dart';
import '../../../text/turkish_text.dart';
import '../../theme/bir_omur_theme.dart';
import '../../widgets/section_scaffold.dart';

/// Yatırımlar ekranı (D-162).
///
/// **Hiçbir şeyi gizlemez ve tavsiye vermez.** Her türün yanında ne
/// olduğu, risk kademesi, oyuncunun o türdeki tutarı ve kâr/zararı yazar.
/// "Şunu al kesin kazanırsın" gibi bir cümle hiçbir yerde geçmez; risk
/// notu da "garanti" demez.
///
/// Piyasa **yılda bir** ilerlediği için ekranı kapatıp açmak fiyatı
/// değiştirmez: oyuncu ekranla oynayarak zar çeviremez.
class InvestmentsPage extends StatefulWidget {
  const InvestmentsPage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<InvestmentsPage> createState() => _InvestmentsPageState();
}

class _InvestmentsPageState extends State<InvestmentsPage> {
  /// Açık duran türün kimliği; her seferinde tek kart açılır.
  String? _acik;
  String? _sonuc;
  bool _olumlu = false;

  final TextEditingController _tutar = TextEditingController();

  @override
  void dispose() {
    _tutar.dispose();
    super.dispose();
  }

  int get _yazilanTutar {
    final String temiz = _tutar.text.replaceAll(RegExp(r'[^0-9]'), '');
    return temiz.isEmpty ? 0 : (int.tryParse(temiz) ?? 0);
  }

  void _ac(String id) {
    setState(() {
      _acik = _acik == id ? null : id;
      _tutar.text = '';
      _sonuc = null;
    });
  }

  void _al(InvestmentType tur) {
    final GameController c = GameScope.of(context);
    final InvestmentOutcome? sonuc = c.buyInvestment(tur.id, _yazilanTutar);
    if (sonuc == null) return;
    setState(() {
      _sonuc = sonuc.text;
      _olumlu = sonuc.applied;
      if (sonuc.applied) _tutar.text = '';
    });
  }

  void _sat(InvestmentType tur, int tutar) {
    final GameController c = GameScope.of(context);
    final InvestmentOutcome? sonuc = c.sellInvestment(tur.id, tutar);
    if (sonuc == null) return;
    setState(() {
      _sonuc = sonuc.text;
      _olumlu = sonuc.applied;
      if (sonuc.applied) _tutar.text = '';
    });
  }

  void _boz(TermDeposit hesap) {
    final GameController c = GameScope.of(context);
    final InvestmentOutcome? sonuc = c.breakTermDeposit(hesap.id);
    if (sonuc == null) return;
    setState(() {
      _sonuc = sonuc.text;
      _olumlu = sonuc.applied;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final GameController controller = GameScope.of(context);
    final GameState state = controller.state!;
    final InteractionAvailability durum =
        controller.investmentAvailability;

    if (!durum.isAllowed) {
      return SectionScaffold(
        icon: Icons.trending_up_rounded,
        accent: BirOmurAccents.yesil,
        title: 'Yatırımlar',
        backLabel: 'Varlıklar',
        onBack: widget.onBack,
        children: <Widget>[
          InfoPanel(
            icon: Icons.lock_outline_rounded,
            text: durum.reason ?? 'Şu anda yatırım yapamazsın.',
          ),
        ],
      );
    }

    return SectionScaffold(
      icon: Icons.trending_up_rounded,
      accent: BirOmurAccents.yesil,
      title: 'Yatırımlar',
      subtitle: 'Cüzdanında ${state.player.walletLabel} var.',
      backLabel: 'Varlıklar',
      onBack: widget.onBack,
      children: <Widget>[
        _PortfolioCard(state: state),
        const SizedBox(height: 12),
        _MarketCard(market: state.market),
        const SizedBox(height: 12),
        if (_sonuc != null) ...<Widget>[
          Container(
            key: const Key('investment_result'),
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (_olumlu
                      ? theme.colorScheme.primary
                      : theme.colorScheme.error)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(_sonuc!, style: theme.textTheme.bodyMedium),
          ),
          const SizedBox(height: 12),
        ],
        for (final InvestmentGroup obek in InvestmentGroup.values) ...<Widget>[
          _GroupHeader(group: obek),
          const SizedBox(height: 8),
          for (final InvestmentType tur in investmentTypesIn(obek)) ...<Widget>[
            _TypeCard(
              type: tur,
              state: state,
              controller: controller,
              open: _acik == tur.id,
              amountField: _tutar,
              amount: _yazilanTutar,
              // Tutar yazıldıkça kartı yeniden kur: engel gerekçesi ve
              // düğmenin açık/kapalı hâli yazılan sayıya bağlı.
              onAmountChanged: () => setState(() {}),
              onToggle: () => _ac(tur.id),
              onBuy: () => _al(tur),
              onSell: (int tutar) => _sat(tur, tutar),
              onBreak: _boz,
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 6),
        ],
        if (state.investmentHistory.isNotEmpty) ...<Widget>[
          const SizedBox(height: 4),
          Text('Yatırım geçmişin', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          _HistoryCard(records: state.investmentHistory),
        ],
      ],
    );
  }
}

/// Portföyün tek bakışta özeti.
class _PortfolioCard extends StatelessWidget {
  const _PortfolioCard({required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int deger = state.portfolioValue;
    final int yatirilan = state.portfolioInvested;
    final int acik = state.portfolioUnrealized;
    final int gercek = state.portfolioRealized;

    return Container(
      key: const Key('portfolio_summary'),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Portföyün', style: theme.textTheme.titleSmall),
          const SizedBox(height: 6),
          if (deger == 0 && gercek == 0)
            Text(
              'Henüz yatırımın yok. Aşağıdan bir tür seçip başlayabilirsin.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else ...<Widget>[
            _Line(label: 'Güncel değer', value: trMoney(deger)),
            _Line(label: 'Yatırdığın', value: trMoney(yatirilan)),
            _Line(
              label: 'Şu anki kâr/zarar',
              value: _signed(acik),
              highlight: true,
            ),
            if (gercek != 0)
              _Line(label: 'Satıştan kalan', value: _signed(gercek)),
            const SizedBox(height: 8),
            // Dağılım: hangi türde ne kadar durduğu.
            for (final Holding h in state.investments)
              if (h.value > 0)
                _Line(
                  label: investmentTypeById(h.typeId)?.name ?? h.typeId,
                  value: '${trMoney(h.value)} '
                      '(%${deger == 0 ? 0 : (h.value * 100 / deger).round()})',
                ),
            for (final TermDeposit d in state.termDeposits)
              _Line(
                label: 'Vadeli hesap',
                value: '${trMoney(d.amount)} '
                    '(%${deger == 0 ? 0 : (d.amount * 100 / deger).round()})',
              ),
          ],
        ],
      ),
    );
  }
}

/// Piyasanın bu yıl nasıl gittiği. Sayı değil, gözlem yazar.
class _MarketCard extends StatelessWidget {
  const _MarketCard({required this.market});

  final MarketState market;

  @override
  Widget build(BuildContext context) => InfoPanel(
        key: const Key('market_mood'),
        icon: Icons.insights_outlined,
        text: '${market.regime.mood} '
            'Piyasa yılda bir kez hareket eder; ekranı açıp kapatmak '
            'fiyatı değiştirmez.',
      );
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.group});

  final InvestmentGroup group;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      children: <Widget>[
        Text(group.label, style: theme.textTheme.titleMedium),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            group.blurb,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

/// Bir yatırım türünün kartı: değer, kâr/zarar, al ve sat.
class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.type,
    required this.state,
    required this.controller,
    required this.open,
    required this.amountField,
    required this.amount,
    required this.onAmountChanged,
    required this.onToggle,
    required this.onBuy,
    required this.onSell,
    required this.onBreak,
  });

  final InvestmentType type;
  final GameState state;
  final GameController controller;
  final bool open;
  final TextEditingController amountField;
  final int amount;
  final VoidCallback onAmountChanged;
  final VoidCallback onToggle;
  final VoidCallback onBuy;
  final void Function(int amount) onSell;
  final void Function(TermDeposit deposit) onBreak;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Holding? h = state.holdingOf(type.id);
    final List<TermDeposit> vadeliler = type.isTermDeposit
        ? state.termDeposits
        : const <TermDeposit>[];
    final int elde = type.isTermDeposit
        ? vadeliler.fold<int>(0, (int t, TermDeposit d) => t + d.amount)
        : (h?.value ?? 0);
    final String alimEngeli =
        controller.investmentBuyBlockReason(type, amount);

    return Container(
      key: Key('investment_${type.id}'),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          InkWell(
            key: Key('investment_open_${type.id}'),
            onTap: onToggle,
            child: Row(
              children: <Widget>[
                Icon(type.icon, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(type.name, style: theme.textTheme.titleSmall),
                      Text(
                        type.risk.label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      elde == 0 ? '—' : trMoney(elde),
                      style: theme.textTheme.titleSmall,
                    ),
                    if (h != null && !h.isEmpty)
                      Text(
                        _signed(h.unrealizedProfit),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: h.unrealizedProfit >= 0
                              ? theme.colorScheme.primary
                              : theme.colorScheme.error,
                        ),
                      ),
                  ],
                ),
                Icon(open ? Icons.expand_less : Icons.expand_more),
              ],
            ),
          ),
          if (open) ...<Widget>[
            const SizedBox(height: 10),
            Text(type.description, style: theme.textTheme.bodySmall),
            const SizedBox(height: 10),
            // Vadeli hesapların kilidi **açıkça** yazar.
            for (final TermDeposit d in vadeliler) ...<Widget>[
              Container(
                key: Key('term_deposit_${d.id}'),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${trMoney(d.amount)} · ${d.openedAtAge} yaşında '
                      'açıldı, ${d.maturesAtAge} yaşında açılacak.',
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      'Vade dolunca ${trMoney(d.maturityValue)} olacak '
                      '(${trMoney(d.interest)} faiz). Şimdi bozarsan faiz '
                      'yanar, anapara geri gelir.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    OutlinedButton(
                      key: Key('break_deposit_${d.id}'),
                      onPressed: () => onBreak(d),
                      child: const Text('Vadeyi boz'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            TextField(
              key: Key('amount_${type.id}'),
              controller: amountField,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Tutar (₺)',
                helperText: type.isTermDeposit
                    ? 'En az ${trMoney(kTermDepositMinAmount)}'
                    : 'En az ${trMoney(kInvestmentMinBuy)}',
              ),
              onChanged: (String _) => onAmountChanged(),
            ),
            const SizedBox(height: 8),
            if (alimEngeli.isNotEmpty)
              Text(
                alimEngeli,
                key: Key('buy_block_${type.id}'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            const SizedBox(height: 6),
            FilledButton(
              key: Key('buy_${type.id}'),
              onPressed: alimEngeli.isEmpty ? onBuy : null,
              child: Text(type.isTermDeposit ? 'Vadeli hesap aç' : 'Al'),
            ),
            if (!type.isTermDeposit && h != null && !h.isEmpty) ...<Widget>[
              const SizedBox(height: 12),
              Text('Sat', style: theme.textTheme.titleSmall),
              const SizedBox(height: 6),
              // Hızlı oranlar: oyuncu hesap yapmak zorunda kalmasın.
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final int oran in <int>[25, 50, 75, 100])
                    OutlinedButton(
                      key: Key('sell_${type.id}_$oran'),
                      onPressed: () => onSell(
                        oran == 100
                            ? h.value
                            : (h.value * oran / 100).round(),
                      ),
                      child: Text(oran == 100 ? 'Tümü' : '%$oran'),
                    ),
                ],
              ),
              if (amount > 0) ...<Widget>[
                const SizedBox(height: 8),
                OutlinedButton(
                  key: Key('sell_amount_${type.id}'),
                  onPressed: controller
                          .investmentSellBlockReason(type, amount)
                          .isEmpty
                      ? () => onSell(amount)
                      : null,
                  child: Text('${trMoney(amount)} sat'),
                ),
              ],
            ],
          ],
        ],
      ),
    );
  }
}

/// Tür bazlı geçmiş. Yalnızca önemli hareketler yazılır.
class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.records});

  final List<InvestmentRecord> records;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    // Son hareketler üstte; liste sonsuz uzamasın diye son 20 satır.
    final List<InvestmentRecord> son = records.reversed.take(20).toList();
    return Container(
      key: const Key('investment_history'),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final InvestmentRecord r in son)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '${r.age} yaşında · '
                '${investmentTypeById(r.typeId)?.name ?? r.typeId} · '
                '${r.kind.label} ${trMoney(r.amount)}'
                '${r.realized == 0 ? '' : ' (${_signed(r.realized)})'}',
                style: theme.textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: highlight
                ? theme.textTheme.titleSmall
                : theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Artı/eksi işaretli para. Sıfır "0 ₺" olarak yazılır.
String _signed(int value) =>
    value > 0 ? '+${trMoney(value)}' : trMoney(value);
