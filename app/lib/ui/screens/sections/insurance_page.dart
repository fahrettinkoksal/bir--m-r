import 'package:flutter/material.dart';

import '../../../data/insurance_catalog.dart';
import '../../../domain/economy/insurance.dart';
import '../../../domain/models/game_state.dart';
import '../../../domain/models/insurance_policy.dart';
import '../../../state/game_controller.dart';
import '../../../state/game_scope.dart';
import '../../../text/turkish_text.dart';
import '../../theme/bir_omur_theme.dart';
import '../../widgets/section_scaffold.dart';

/// **Sigorta** (Paket CA).
///
/// Bu ekran tek bir soru soruyor: *her yıl prim ödeyip hiçbir şey
/// olmamasını mı istersin, parayı cebinde tutup riski mi üstlenirsin?*
///
/// Ekran kimseyi yargılamaz ve "almalısın" demez. Poliçesi olanın
/// dökümünü gösterir (ne kadar prim ödedin, ne kadarı karşılandı),
/// olmayana koşulları ve varsa **gerekçeyi** yazar — sahte düğme yok
/// (D-063).
class InsurancePage extends StatefulWidget {
  const InsurancePage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<InsurancePage> createState() => _InsurancePageState();
}

class _InsurancePageState extends State<InsurancePage> {
  String? _mesaj;

  @override
  Widget build(BuildContext context) {
    final GameController scope = GameScope.of(context);
    final GameState state = scope.state!;

    final List<InsurancePolicy> aktifler = <InsurancePolicy>[
      for (final InsuranceKind k in InsuranceKind.values)
        if (Insurance.activeOf(state, k) != null)
          Insurance.activeOf(state, k)!,
    ];
    final int yillikToplam = aktifler.fold<int>(
      0,
      (int t, InsurancePolicy p) =>
          t + p.terms.prototypeOnlyYearlyPremium,
    );

    return SectionScaffold(
      key: const Key('insurance_page'),
      icon: Icons.shield_outlined,
      accent: BirOmurAccents.cini,
      title: 'Sigorta',
      subtitle: aktifler.isEmpty
          ? 'Poliçen yok'
          : '${aktifler.length} poliçe · yılda '
              '${trMoney(yillikToplam)}',
      backLabel: 'Aktiviteler',
      onBack: widget.onBack,
      children: <Widget>[
        InfoPanel(
          icon: Icons.info_outline,
          text: 'Sigorta kazanç getirmez; kötü bir yılın faturasını '
              'küçültür. Hasarın muafiyet kadarı her hâlde senin '
              'cebinden çıkar.',
        ),
        if (_mesaj != null) ...<Widget>[
          const SizedBox(height: 12),
          InfoPanel(icon: Icons.check_circle_outline, text: _mesaj!),
        ],
        const SizedBox(height: 12),
        for (final InsuranceTerms terms in kInsuranceCatalog) ...<Widget>[
          _PoliceKarti(
            terms: terms,
            police: Insurance.activeOf(state, terms.kind),
            engel: scope.insuranceBlockReason(terms.kind),
            onBuy: () {
              final ({bool applied, String message}) sonuc =
                  scope.buyInsurance(terms.kind);
              setState(() => _mesaj = sonuc.message);
            },
            onCancel: () {
              final ({bool applied, String message}) sonuc =
                  scope.cancelInsurance(terms.kind);
              setState(() => _mesaj = sonuc.message);
            },
          ),
          const SizedBox(height: 12),
        ],
        // Düşmüş poliçeler **silinmez**: ne kadar prim ödendiği durur.
        if (state.insurance.any((InsurancePolicy p) => !p.isActive))
          ...<Widget>[
          MenuGroupTitle(
            text: 'Geçmiş poliçeler',
            accent: BirOmurAccents.mor,
          ),
          const SizedBox(height: 8),
          for (final InsurancePolicy p in state.insurance)
            if (!p.isActive) ...<Widget>[
              InfoPanel(
                icon: Icons.history,
                text: '${p.kind.label} · ${p.startedAtAge}-'
                    '${p.lapsedAtAge} yaş · ödenen prim '
                    '${trMoney(p.premiumsPaid)} · karşılanan '
                    '${trMoney(p.claimsPaid)}',
              ),
              const SizedBox(height: 8),
            ],
        ],
      ],
    );
  }
}

/// Tek bir poliçenin kartı.
class _PoliceKarti extends StatelessWidget {
  const _PoliceKarti({
    required this.terms,
    required this.police,
    required this.engel,
    required this.onBuy,
    required this.onCancel,
  });

  final InsuranceTerms terms;
  final InsurancePolicy? police;
  final String? engel;
  final VoidCallback onBuy;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final InsurancePolicy? p = police;
    final ThemeData tema = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tema.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tema.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(terms.kind.label, style: tema.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(terms.kind.blurb, style: tema.textTheme.bodySmall),
          const SizedBox(height: 10),
          Text(
            'Yıllık prim ${trMoney(terms.prototypeOnlyYearlyPremium)} · '
            'muafiyet ${trMoney(terms.prototypeOnlyDeductible)} · '
            'karşılama %${(terms.prototypeOnlyCoveredShare * 100).round()}',
            style: tema.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          if (p != null) ...<Widget>[
            Text(
              '${p.startedAtAge} yaşından beri · ödenen prim '
              '${trMoney(p.premiumsPaid)} · karşılanan '
              '${trMoney(p.claimsPaid)} (${p.claimCount} hasar)',
              style: tema.textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              key: Key('insurance_cancel_${terms.kind.name}'),
              onPressed: onCancel,
              child: const Text('Poliçeyi iptal et'),
            ),
          ] else if (engel != null)
            // Gerekçe her zaman yazılır; düğme sahte durmaz.
            Text(engel!, style: tema.textTheme.bodySmall)
          else
            FilledButton(
              key: Key('insurance_buy_${terms.kind.name}'),
              onPressed: onBuy,
              child: const Text('Poliçe yaptır'),
            ),
        ],
      ),
    );
  }
}
