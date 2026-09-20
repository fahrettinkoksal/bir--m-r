import 'package:flutter/material.dart';

import '../../../domain/casino/casino_rules.dart';
import '../../../domain/casino/roulette.dart';
import '../../../domain/models/blackjack_game.dart';
import '../../../domain/models/game_state.dart';
import '../../../domain/models/interaction.dart';
import '../../../domain/models/playing_card.dart';
import '../../../state/game_controller.dart';
import '../../../state/game_scope.dart';
import '../../widgets/section_scaffold.dart';

/// Kumarhane ana sayfası: masalar ve kurallar.
///
/// Masalar **yalnızca oyunun sanal parasıyla** oynanır; gerçek para
/// yatırma, çekme veya ödül yoktur.
class CasinoPage extends StatefulWidget {
  const CasinoPage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<CasinoPage> createState() => _CasinoPageState();
}

enum _CasinoTable { kok, blackjack, rulet }

class _CasinoPageState extends State<CasinoPage> {
  _CasinoTable _masa = _CasinoTable.kok;

  @override
  Widget build(BuildContext context) {
    final GameController controller = GameScope.of(context);
    final GameState state = controller.state!;

    switch (_masa) {
      case _CasinoTable.blackjack:
        return BlackjackTablePage(
          onBack: () => setState(() => _masa = _CasinoTable.kok),
        );
      case _CasinoTable.rulet:
        return RouletteTablePage(
          onBack: () => setState(() => _masa = _CasinoTable.kok),
        );
      case _CasinoTable.kok:
        break;
    }

    final int kalan = (CasinoRules.prototypeOnlyYearlyWagerLimit -
            state.wagerThisAge)
        .clamp(0, CasinoRules.prototypeOnlyYearlyWagerLimit);

    return SectionScaffold(
      title: 'Kumarhane',
      subtitle: 'Cüzdanın: ${state.player.walletLabel}',
      backLabel: 'Aktiviteler',
      onBack: widget.onBack,
      children: <Widget>[
        const InfoPanel(
          icon: Icons.info_outline,
          text: CasinoRules.responsibleText,
        ),
        const SizedBox(height: 12),
        MenuRow(
          title: 'Blackjack',
          subtitle: state.hasOpenHand
              ? 'Masada devam eden bir elin var'
              : '21’e en çok yaklaşan kazanır',
          icon: Icons.style_outlined,
          onTap: () => setState(() => _masa = _CasinoTable.blackjack),
        ),
        const SizedBox(height: 10),
        MenuRow(
          title: 'Rulet',
          subtitle: 'Tek sıfırlı Avrupa ruleti',
          icon: Icons.casino_outlined,
          onTap: () => setState(() => _masa = _CasinoTable.rulet),
        ),
        const SizedBox(height: 12),
        InfoPanel(
          icon: Icons.savings_outlined,
          text: 'Bu yıl oynadığın toplam bahis: ${state.wagerThisAge} ₺. '
              'Yıllık sınıra kalan: $kalan ₺. '
              'Bahis en az ${CasinoRules.prototypeOnlyMinBet} ₺, '
              'en fazla ${CasinoRules.prototypeOnlyMaxBet} ₺.',
        ),
      ],
    );
  }
}

/// Bahis miktarı seçici: hazır adımlar.
class _BetSelector extends StatelessWidget {
  const _BetSelector({required this.bet, required this.onChanged});

  final int bet;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final GameController controller = GameScope.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final int adim in CasinoRules.prototypeOnlyBetSteps)
          ChoiceChip(
            key: Key('bet_$adim'),
            label: Text('$adim ₺'),
            selected: bet == adim,
            onSelected: controller.betAvailability(adim).isAllowed
                ? (_) => onChanged(adim)
                : null,
          ),
      ],
    );
  }
}

/// Blackjack masası.
class BlackjackTablePage extends StatefulWidget {
  const BlackjackTablePage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<BlackjackTablePage> createState() => _BlackjackTablePageState();
}

class _BlackjackTablePageState extends State<BlackjackTablePage> {
  int _bahis = CasinoRules.prototypeOnlyBetSteps.first;
  String? _sonMesaj;

  @override
  Widget build(BuildContext context) {
    final GameController controller = GameScope.of(context);
    final GameState state = controller.state!;
    final BlackjackGame? oyun = state.blackjack;

    return SectionScaffold(
      title: 'Blackjack',
      subtitle: 'Cüzdanın: ${state.player.walletLabel}',
      backLabel: 'Kumarhane',
      onBack: widget.onBack,
      children: <Widget>[
        const InfoPanel(
          icon: Icons.rule_outlined,
          text: CasinoRules.blackjackRulesText,
        ),
        const SizedBox(height: 12),
        if (oyun == null) ...<Widget>[
          Text('Bahsini seç', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          _BetSelector(
            bet: _bahis,
            onChanged: (int v) => setState(() => _bahis = v),
          ),
          const SizedBox(height: 14),
          _BlockReason(controller.betAvailability(_bahis)),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const Key('blackjack_deal'),
              onPressed: controller.betAvailability(_bahis).isAllowed
                  ? () => setState(() {
                        _sonMesaj = controller.dealBlackjack(_bahis)?.text;
                      })
                  : null,
              child: Text('$_bahis ₺ ile el aç'),
            ),
          ),
        ] else ...<Widget>[
          _HandCard(
            title: 'Krupiye',
            cards: oyun.visibleDealerCards,
            total: oyun.isFinished ? oyun.dealerTotal : oyun.visibleDealerTotal,
            hidden: !oyun.isFinished,
          ),
          const SizedBox(height: 10),
          _HandCard(
            title: 'Sen',
            cards: oyun.playerCards,
            total: oyun.playerTotal,
            soft: oyun.playerSoft,
          ),
          const SizedBox(height: 14),
          if (!oyun.isFinished)
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton.tonal(
                    key: const Key('blackjack_hit'),
                    onPressed: () => setState(() {
                      _sonMesaj = controller.hitBlackjack()?.text;
                    }),
                    child: const Text('Kart çek'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    key: const Key('blackjack_stand'),
                    onPressed: () => setState(() {
                      _sonMesaj = controller.standBlackjack()?.text;
                    }),
                    child: const Text('Dur'),
                  ),
                ),
              ],
            )
          else ...<Widget>[
            _ResultPanel(oyun: oyun),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                key: const Key('blackjack_close'),
                onPressed: () => setState(() {
                  controller.closeBlackjackHand();
                  _sonMesaj = null;
                }),
                child: const Text('Masadan kalk'),
              ),
            ),
          ],
        ],
        if (_sonMesaj != null) ...<Widget>[
          const SizedBox(height: 12),
          InfoPanel(icon: Icons.chat_bubble_outline, text: _sonMesaj!),
        ],
      ],
    );
  }
}

class _HandCard extends StatelessWidget {
  const _HandCard({
    required this.title,
    required this.cards,
    required this.total,
    this.hidden = false,
    this.soft = false,
  });

  final String title;
  final List<PlayingCard> cards;
  final int total;
  final bool hidden;
  final bool soft;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(title, style: theme.textTheme.titleMedium),
                Text(
                  hidden ? '$total + ?' : '${soft ? 'yumuşak ' : ''}$total',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final PlayingCard kart in cards) _CardChip(card: kart),
                if (hidden) const _HiddenCardChip(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CardChip extends StatelessWidget {
  const _CardChip({required this.card});

  final PlayingCard card;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      width: 46,
      height: 62,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Text(
        card.label,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: card.suit.isRed
              ? theme.colorScheme.error
              : theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _HiddenCardChip extends StatelessWidget {
  const _HiddenCardChip();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      width: 46,
      height: 62,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Icon(
        Icons.help_outline,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({required this.oyun});

  final BlackjackGame oyun;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int net = oyun.netGain;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              oyun.result?.label ?? '',
              key: const Key('blackjack_result'),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              net > 0
                  ? '$net ₺ kazandın.'
                  : net < 0
                      ? '${-net} ₺ kaybettin.'
                      : 'Bahsin geri geldi.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: net > 0
                    ? theme.colorScheme.primary
                    : net < 0
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlockReason extends StatelessWidget {
  const _BlockReason(this.availability);

  final InteractionAvailability availability;

  @override
  Widget build(BuildContext context) {
    if (availability.isAllowed) return const SizedBox.shrink();
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        availability.reason ?? '',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
        ),
      ),
    );
  }
}

/// Rulet masası.
class RouletteTablePage extends StatefulWidget {
  const RouletteTablePage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<RouletteTablePage> createState() => _RouletteTablePageState();
}

class _RouletteTablePageState extends State<RouletteTablePage> {
  int _bahis = CasinoRules.prototypeOnlyBetSteps.first;
  RouletteBetType _tur = RouletteBetType.kirmizi;
  int _sayi = 7;
  String? _sonMesaj;

  @override
  Widget build(BuildContext context) {
    final GameController controller = GameScope.of(context);
    final GameState state = controller.state!;
    final ThemeData theme = Theme.of(context);

    return SectionScaffold(
      title: 'Rulet',
      subtitle: 'Cüzdanın: ${state.player.walletLabel}',
      backLabel: 'Kumarhane',
      onBack: widget.onBack,
      children: <Widget>[
        const InfoPanel(
          icon: Icons.rule_outlined,
          text: CasinoRules.rouletteRulesText,
        ),
        const SizedBox(height: 12),
        Text('Bahis türü', style: theme.textTheme.titleMedium),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final RouletteBetType tur in RouletteBetType.values)
              ChoiceChip(
                key: Key('roulette_${tur.name}'),
                label: Text(
                  tur == RouletteBetType.sayi
                      ? '${tur.label} (35:1)'
                      : '${tur.label} (1:1)',
                ),
                selected: _tur == tur,
                onSelected: (_) => setState(() => _tur = tur),
              ),
          ],
        ),
        if (_tur == RouletteBetType.sayi) ...<Widget>[
          const SizedBox(height: 12),
          Text('Sayı: $_sayi', style: theme.textTheme.bodyMedium),
          Slider(
            key: const Key('roulette_number'),
            value: _sayi.toDouble(),
            min: 0,
            max: 36,
            divisions: 36,
            label: '$_sayi',
            onChanged: (double v) => setState(() => _sayi = v.round()),
          ),
        ],
        const SizedBox(height: 12),
        Text('Bahis miktarı', style: theme.textTheme.titleMedium),
        const SizedBox(height: 10),
        _BetSelector(
          bet: _bahis,
          onChanged: (int v) => setState(() => _bahis = v),
        ),
        const SizedBox(height: 14),
        _BlockReason(controller.betAvailability(_bahis)),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            key: const Key('roulette_spin'),
            onPressed: controller.betAvailability(_bahis).isAllowed
                ? () => setState(() {
                      _sonMesaj = controller
                          .spinRoulette(_tur, _bahis, number: _sayi)
                          ?.text;
                    })
                : null,
            child: Text('$_bahis ₺ oyna'),
          ),
        ),
        if (_sonMesaj != null) ...<Widget>[
          const SizedBox(height: 12),
          InfoPanel(icon: Icons.casino_outlined, text: _sonMesaj!),
        ],
      ],
    );
  }
}
