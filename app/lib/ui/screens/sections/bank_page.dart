import 'package:flutter/material.dart';

import '../../../domain/economy/banking.dart';
import '../../../domain/models/game_state.dart';
import '../../../domain/models/loan.dart';
import '../../../state/game_scope.dart';
import '../../../state/game_controller.dart';
import '../../../text/turkish_text.dart';
import '../../theme/bir_omur_theme.dart';
import '../../widgets/section_scaffold.dart';

/// Banka ve kredi ekranı (D-080).
///
/// Faho'nun isteği: "banka sistemi ekleyelim, kredi çekebilelim, faizi
/// ile ödenebilir şekilde olsun; 2 adet banka, Fakbank ve Bankavrupa;
/// biri az faiz ama onaylamayabilir, biri çok faiz ama onaylasın".
///
/// Ekran **hiçbir şeyi gizlemez**: başvurmadan önce yıllık taksit, vade
/// ve toplam geri ödeme yazar. Ret gerekçesi de açıkça gösterilir; banka
/// "olmadı" deyip geçmez.
class BankPage extends StatefulWidget {
  const BankPage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<BankPage> createState() => _BankPageState();
}

class _BankPageState extends State<BankPage> {
  Bank _banka = Bank.fakbank;
  int _vade = 2;
  late int _tutar = Banking.minAmount * 20;
  String? _sonuc;
  bool _olumlu = false;

  void _basvur() {
    final GameController controller = GameScope.of(context);
    final LoanDecision? karar = controller.applyForLoan(
      bank: _banka,
      amount: _tutar,
      termYears: _vade,
    );
    if (karar == null) return;
    setState(() {
      _sonuc = karar.reason;
      _olumlu = karar.approved;
    });
  }

  void _kapat(Loan kredi) {
    final GameController controller = GameScope.of(context);
    final String mesaj = controller.payOffLoan(kredi.id);
    setState(() {
      _sonuc = mesaj;
      _olumlu = mesaj.contains('kapattın');
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final GameController controller = GameScope.of(context);
    final GameState state = controller.state!;
    final List<Loan> acik = controller.activeLoans;

    final LoanDecision onizleme = controller.previewLoan(
      bank: _banka,
      amount: _tutar,
      termYears: _vade,
    );
    final String? engel = Banking.blockReason(state, amount: _tutar);

    return SectionScaffold(
      icon: Icons.account_balance_rounded,
      accent: BirOmurAccents.mavi,
      title: 'Banka',
      subtitle: 'Cüzdanında ${state.player.walletLabel} var.',
      backLabel: 'Varlıklar',
      onBack: widget.onBack,
      children: <Widget>[
        if (acik.isNotEmpty) ...<Widget>[
          Text('Açık kredilerin', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final Loan l in acik) ...<Widget>[
            _LoanCard(loan: l, onPayOff: () => _kapat(l)),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 4),
          Text(
            'Toplam kalan borç ${trMoney(controller.totalDebt)} · '
            'yıllık taksit yükü ${trMoney(controller.annualLoanBurden)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
        ],
        Text('Yeni kredi', style: theme.textTheme.titleMedium),
        const SizedBox(height: 10),
        for (final Bank b in Bank.values) ...<Widget>[
          ListTile(
            key: Key('bank_${b.name}'),
            onTap: () => setState(() => _banka = b),
            leading: Icon(
              b == _banka
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: theme.colorScheme.primary,
            ),
            title: Text(b.label),
            subtitle: Text(
              '${b.description}\n'
              'Aylık faiz %${(b.monthlyRate * 100).toStringAsFixed(2)} · '
              'yıllık %${(b.yearlyRate * 100).round()}',
            ),
            isThreeLine: true,
            contentPadding: EdgeInsets.zero,
          ),
        ],
        const SizedBox(height: 8),
        Text('Tutar: ${trMoney(_tutar)}', style: theme.textTheme.bodyMedium),
        Slider(
          key: const Key('loan_amount'),
          value: _tutar.toDouble(),
          min: Banking.minAmount.toDouble(),
          max: (Banking.minAmount * 400).toDouble(),
          divisions: 40,
          onChanged: (double v) =>
              setState(() => _tutar = (v ~/ 1000) * 1000),
        ),
        const SizedBox(height: 4),
        Text('Vade: $_vade yıl', style: theme.textTheme.bodyMedium),
        Slider(
          key: const Key('loan_term'),
          value: _vade.toDouble(),
          min: Banking.minTermYears.toDouble(),
          max: Banking.maxTermYears.toDouble(),
          divisions: Banking.maxTermYears - Banking.minTermYears,
          onChanged: (double v) => setState(() => _vade = v.round()),
        ),
        const SizedBox(height: 10),
        // Başvurmadan önce ne olacağı yazar; sürpriz yok.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (engel != null)
                Text(engel, style: theme.textTheme.bodyMedium)
              else ...<Widget>[
                Text(
                  onizleme.approved
                      ? 'Bu koşullarda onaylanır.'
                      : onizleme.reason,
                  key: const Key('loan_preview'),
                  style: theme.textTheme.bodyMedium,
                ),
                if (onizleme.annualPayment > 0) ...<Widget>[
                  const SizedBox(height: 6),
                  Text(
                    'Yıllık taksit ${trMoney(onizleme.annualPayment)} · '
                    'toplam geri ödeme '
                    '${trMoney(onizleme.annualPayment * _vade)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            key: const Key('loan_apply'),
            onPressed: engel == null ? _basvur : null,
            child: const Text('Başvur'),
          ),
        ),
        if (_sonuc != null) ...<Widget>[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: (_olumlu
                      ? theme.colorScheme.secondary
                      : theme.colorScheme.error)
                  .withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              _sonuc!,
              key: const Key('loan_result'),
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
        const SizedBox(height: 14),
        Text(
          'Faiz oranları 2026 Türkiye ihtiyaç kredisi piyasasına '
          'dayanır; vade en fazla ${Banking.maxTermYears} yıldır. '
          'Taksit her yıl cüzdanından düşer. Ödenemeyen taksit kaçar ve '
          'borç faiziyle büyür.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _LoanCard extends StatelessWidget {
  const _LoanCard({required this.loan, required this.onPayOff});

  final Loan loan;
  final VoidCallback onPayOff;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(loan.bank.label, style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            'Kalan borç ${trMoney(loan.outstanding)} · '
            '${loan.remainingPayments} taksit kaldı',
            style: theme.textTheme.bodySmall,
          ),
          Text(
            'Yıllık taksit ${trMoney(loan.annualPayment)}',
            style: theme.textTheme.bodySmall,
          ),
          if (loan.missedPayments > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${loan.missedPayments} taksit kaçtı; yeni başvurularda '
                'bu görünür.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              key: Key('payoff_${loan.id}'),
              onPressed: onPayOff,
              child: Text('Kapat (${trMoney(loan.outstanding)})'),
            ),
          ),
        ],
      ),
    );
  }
}
