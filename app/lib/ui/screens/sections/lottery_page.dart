import 'package:flutter/material.dart';

import '../../../data/lottery_catalog.dart';
import '../../../domain/models/interaction.dart';
import '../../../domain/models/lottery_ticket.dart';
import '../../../state/game_controller.dart';
import '../../../state/game_scope.dart';
import '../../../text/turkish_text.dart';
import '../../theme/bir_omur_theme.dart';
import '../../widgets/section_scaffold.dart';

/// Milli Piyango bayii (Paket 33).
///
/// Bilet yıl içinde alınır; çekiliş yaş ilerlerken yapılır ve sonuç
/// bildirim panelinde çıkar.
class LotteryPage extends StatefulWidget {
  const LotteryPage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<LotteryPage> createState() => _LotteryPageState();
}

class _LotteryPageState extends State<LotteryPage> {
  String? _sonuc;

  @override
  Widget build(BuildContext context) {
    final GameController controller = GameScope.of(context);
    final List<LotteryTicket> biletler = controller.lotteryTickets;

    return SectionScaffold(
      icon: Icons.confirmation_number_rounded,
      accent: BirOmurAccents.pirinc,
      title: 'Milli Piyango',
      subtitle: 'Cüzdanında ${controller.state!.player.walletLabel} var. '
          'Çekiliş yıl sonunda yapılır.',
      backLabel: 'Aktiviteler',
      onBack: widget.onBack,
      children: <Widget>[
        const InfoPanel(
          icon: Icons.info_outline_rounded,
          text: 'Bu oyundaki piyango yalnızca oyunun sanal parasıyla '
              'çalışır. Gerçek para yatırılmaz, kazanılan tutar gerçek '
              'bir ödeme değildir. Piyangoda kasanın payı büyüktür: '
              'uzun vadede ödediğinden azı geri döner.',
        ),
        const SizedBox(height: 12),
        if (biletler.isNotEmpty) ...<Widget>[
          const MenuGroupTitle(
            text: 'Bekleyen biletlerin',
            accent: BirOmurAccents.pirinc,
          ),
          for (final LotteryTicket bilet in biletler) ...<Widget>[
            _TicketRow(ticket: bilet),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
        ],
        for (final LotteryDraw draw in LotteryDraw.values) ...<Widget>[
          _DrawCard(
            draw: draw,
            boughtThisAge: controller.lotteryTicketsThisAge(draw),
            availabilityFor: (TicketShare s) =>
                controller.lotteryAvailability(draw, s),
            onBuy: (TicketShare s) {
              final String? metin = controller.buyLotteryTicket(draw, s);
              setState(() => _sonuc = metin);
            },
          ),
          const SizedBox(height: 10),
        ],
        if (_sonuc != null) ...<Widget>[
          const SizedBox(height: 4),
          InfoPanel(
            icon: Icons.receipt_long_rounded,
            text: _sonuc!,
          ),
        ],
      ],
    );
  }
}

class _TicketRow extends StatelessWidget {
  const _TicketRow({required this.ticket});

  final LotteryTicket ticket;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      decoration: panelDecoration(context, radius: 16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: <Widget>[
            AccentIconTile(
              icon: Icons.confirmation_number_outlined,
              accent: BirOmurAccents.pirinc,
              size: 34,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(ticket.number, style: theme.textTheme.titleMedium),
                  Text(
                    ticket.label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              trMoney(ticket.price),
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

class _DrawCard extends StatelessWidget {
  const _DrawCard({
    required this.draw,
    required this.boughtThisAge,
    required this.availabilityFor,
    required this.onBuy,
  });

  final LotteryDraw draw;
  final int boughtThisAge;
  final InteractionAvailability Function(TicketShare) availabilityFor;
  final void Function(TicketShare) onBuy;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final LotteryPrize buyuk = draw.prizes.first;

    return Container(
      decoration: panelDecoration(context, radius: 20),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                AccentIconTile(
                  icon: draw == LotteryDraw.yilbasi
                      ? Icons.celebration_rounded
                      : Icons.confirmation_number_rounded,
                  accent: BirOmurAccents.pirinc,
                  size: 38,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(draw.label, style: theme.textTheme.titleMedium),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              draw.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${buyuk.label}: ${trMoneyShort(buyuk.fullTicketAmount)} '
              '(tam bilete)',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              'Bu yıl $boughtThisAge/${draw.maxTicketsPerAge} bilet aldın.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final TicketShare share in TicketShare.values)
                  FilledButton.tonal(
                    key: Key('piyango_${draw.id}_${share.name}'),
                    onPressed: availabilityFor(share).isAllowed
                        ? () => onBuy(share)
                        : null,
                    child: Text(
                      '${share.label} · ${trMoney(draw.priceFor(share))}',
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _PrizeTable(draw: draw),
          ],
        ),
      ),
    );
  }
}

/// İkramiye basamakları açıkça yazılır: ihtimaller gizlenmez.
class _PrizeTable extends StatelessWidget {
  const _PrizeTable({required this.draw});

  final LotteryDraw draw;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final LotteryPrize p in draw.prizes)
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    p.label,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '1/${p.oneIn}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  trMoneyShort(p.fullTicketAmount),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
