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
  LoanPurpose _amac = LoanPurpose.ihtiyac;
  int _vade = 2;
  late int _tutar = Banking.minAmount * 20;
  String? _sonuc;
  bool _olumlu = false;

  /// Tutar **elle** yazılabilir (D-108): kaydırıcı kaba kalıyordu.
  late final TextEditingController _tutarAlani =
      TextEditingController(text: '$_tutar');

  @override
  void dispose() {
    _tutarAlani.dispose();
    super.dispose();
  }

  /// Yazılan metni tutara çevirir; geçersizse tutar değişmez.
  void _tutarYazildi(String metin) {
    final String temiz = metin.replaceAll(RegExp(r'[^0-9]'), '');
    if (temiz.isEmpty) return;
    final int? deger = int.tryParse(temiz);
    if (deger == null) return;
    setState(() => _tutar = deger);
  }

  /// Amaç değişince vade ve tutar yeni sınırlara çekilir.
  void _amacSec(LoanPurpose amac) {
    setState(() {
      _amac = amac;
      _vade = _vade.clamp(
        Banking.minTermYears,
        Banking.maxTermFor(amac),
      );
      if (_tutar < Banking.minAmountFor(amac)) {
        _tutar = Banking.minAmountFor(amac);
        _tutarAlani.text = '$_tutar';
      }
    });
  }

  void _basvur() {
    final GameController controller = GameScope.of(context);
    final LoanDecision? karar = controller.applyForLoan(
      bank: _banka,
      amount: _tutar,
      termYears: _vade,
      purpose: _amac,
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
      purpose: _amac,
    );
    final String? engel =
        Banking.blockReason(state, amount: _tutar, purpose: _amac);
    final CreditStanding karne = controller.creditStanding;

    return SectionScaffold(
      icon: Icons.account_balance_rounded,
      accent: BirOmurAccents.mavi,
      title: 'Banka',
      subtitle: 'Cüzdanında ${state.player.walletLabel} var.',
      backLabel: 'Aktiviteler',
      onBack: widget.onBack,
      children: <Widget>[
        // Kredi karnesi (D-108): dört kademe, gerekçesiyle.
        Container(
          key: const Key('credit_standing'),
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
              Text(
                'Kredi durumun: ${karne.label}',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 2),
              Text(
                karne.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
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
        const SizedBox(height: 8),
        // Kredinin amacı (D-108): konut kredisi daha ucuz, daha uzun
        // vadeli ve daha büyüktür.
        for (final LoanPurpose p in LoanPurpose.values) ...<Widget>[
          ListTile(
            key: Key('loan_purpose_${p.name}'),
            onTap: () => _amacSec(p),
            leading: Icon(
              p == _amac
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: theme.colorScheme.primary,
            ),
            title: Text(p.label),
            subtitle: Text(p.description),
            contentPadding: EdgeInsets.zero,
          ),
        ],
        const SizedBox(height: 4),
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
              'Aylık faiz '
              '%${(b.monthlyRateFor(_amac) * 100).toStringAsFixed(2)} · '
              'yıllık %${(b.yearlyRateFor(_amac) * 100).round()}',
            ),
            isThreeLine: true,
            contentPadding: EdgeInsets.zero,
          ),
        ],
        const SizedBox(height: 8),
        // Tutar elle yazılır (D-108): kaydırıcı kaba kalıyordu, oyuncu
        // istediği rakamı giremiyordu.
        TextField(
          key: const Key('loan_amount_field'),
          controller: _tutarAlani,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Tutar (₺)',
            helperText: 'En az ${trMoney(Banking.minAmountFor(_amac))}',
            suffixText: trMoney(_tutar),
          ),
          onChanged: _tutarYazildi,
        ),
        const SizedBox(height: 12),
        Text(
          'Vade: $_vade yıl (en fazla ${Banking.maxTermFor(_amac)})',
          style: theme.textTheme.bodyMedium,
        ),
        Slider(
          key: const Key('loan_term'),
          value: _vade.toDouble().clamp(
                Banking.minTermYears.toDouble(),
                Banking.maxTermFor(_amac).toDouble(),
              ),
          min: Banking.minTermYears.toDouble(),
          max: Banking.maxTermFor(_amac).toDouble(),
          divisions: Banking.maxTermFor(_amac) - Banking.minTermYears,
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
