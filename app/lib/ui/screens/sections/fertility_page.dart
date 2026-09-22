import 'package:flutter/material.dart';

import '../../../domain/interaction/fertility_treatment.dart';
import '../../../domain/interaction/intimacy.dart';
import '../../../domain/interaction/marriage_engine.dart';
import '../../../domain/models/person.dart';
import '../../../state/game_controller.dart';
import '../../../state/game_scope.dart';
import '../../../text/turkish_text.dart';
import '../../theme/bir_omur_theme.dart';
import '../../widgets/section_scaffold.dart';

/// Tüp bebek tedavisi — Sağlık Merkezi'nin içinde (Paket 35).
///
/// Kısır bir çiftin tek tıbbi çıkış yolu. Ekran **kimseye kısır demez**;
/// yalnızca sonucun ne olduğunu ve ihtimalin ne olduğunu söyler.
class FertilityPage extends StatefulWidget {
  const FertilityPage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<FertilityPage> createState() => _FertilityPageState();
}

class _FertilityPageState extends State<FertilityPage> {
  FamilyOutcome? _sonuc;

  @override
  Widget build(BuildContext context) {
    final GameController controller = GameScope.of(context);
    final String engel = controller.fertilityBlockReason;
    final bool acik = engel.isEmpty;
    final int oran = controller.fertilityChancePercent;
    final int deneme = controller.fertilityAttempts;
    final Person? es = Intimacy.partnerOf(controller.state!);

    return SectionScaffold(
      icon: Icons.child_friendly_rounded,
      accent: BirOmurAccents.nar,
      title: 'Tüp bebek tedavisi',
      subtitle: 'Cüzdanında ${controller.state!.player.walletLabel} var.',
      backLabel: 'Sağlık Merkezi',
      onBack: widget.onBack,
      children: <Widget>[
        const InfoPanel(
          icon: Icons.info_outline_rounded,
          text: 'Tedavi bir garanti değildir. Ücret her denemede ödenir ve '
              'sonuç alınamayabilir. Bu oyun içi bir kurgudur; tıbbi '
              'tavsiye değildir.',
        ),
        const SizedBox(height: 12),
        Container(
          decoration: panelDecoration(context, radius: 20),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    AccentIconTile(
                      icon: Icons.medical_services_rounded,
                      accent: BirOmurAccents.nar,
                      size: 38,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Bir deneme',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            es == null
                                ? 'Eş ya da sevgili gerekiyor'
                                : '${es.firstName} ile',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      trMoney(FertilityTreatment.prototypeOnlyCost),
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // İhtimal gizlenmez: oyuncu neye girdiğini bilir.
                if (acik) ...<Widget>[
                  Text(
                    'Hekimin verdiği yaklaşık şans: %$oran',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Yaş ilerledikçe bu oran düşer. Yılda bir deneme '
                    'yapılabilir.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ] else
                  Text(
                    engel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                if (deneme > 0) ...<Widget>[
                  const SizedBox(height: 6),
                  Text(
                    'Bugüne kadar $deneme deneme yaptınız.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.tonal(
                    key: const Key('tup_bebek_dene'),
                    onPressed: acik
                        ? () {
                            final FamilyOutcome? sonuc =
                                controller.tryFertilityTreatment();
                            setState(() => _sonuc = sonuc);
                          }
                        : null,
                    child: Text(acik ? 'Tedaviyi dene' : 'Şu an kapalı'),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_sonuc != null) ...<Widget>[
          const SizedBox(height: 12),
          InfoPanel(
            icon: Icons.receipt_long_rounded,
            text: _sonuc!.text,
          ),
        ],
      ],
    );
  }
}
