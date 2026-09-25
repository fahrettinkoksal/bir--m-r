import 'package:flutter/material.dart';

import '../../../data/business_catalog.dart';
import '../../../domain/economy/business_engine.dart';
import '../../../domain/models/business.dart';
import '../../../domain/models/game_state.dart';
import '../../../domain/models/interaction.dart';
import '../../../state/game_controller.dart';
import '../../../state/game_scope.dart';
import '../../../text/turkish_text.dart';
import '../../theme/bir_omur_theme.dart';
import '../../widgets/kilim_divider.dart';
import '../../widgets/section_scaffold.dart';

/// Kendi İşim sayfası (D-132).
///
/// Meslek bölümünün altındadır: kendi işi de bir geçim yolu. Maaş gibi
/// garanti olmadığı ekranda açıkça yazar.
class BusinessPage extends StatefulWidget {
  const BusinessPage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<BusinessPage> createState() => _BusinessPageState();
}

class _BusinessPageState extends State<BusinessPage> {
  String? _sonuc;
  final TextEditingController _tutar = TextEditingController();

  @override
  void dispose() {
    _tutar.dispose();
    super.dispose();
  }

  void _uygula(BusinessOutcome? o) {
    if (o == null) return;
    setState(() => _sonuc = o.text);
  }

  Future<void> _kapatOnayi() async {
    final GameController controller = GameScope.of(context);
    final Business? is_ = controller.openBusiness;
    if (is_ == null) return;
    final bool? onay = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('İşi devret'),
        content: Text(
          '${is_.type?.name ?? 'İşini'} devretmek üzeresin. '
          'Sermayenin bir kısmı geri gelir, tamamı gelmez.\n\n'
          'Bu karar geri alınamaz.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Devret'),
          ),
        ],
      ),
    );
    if (onay != true || !mounted) return;
    _uygula(GameScope.of(context).closeBusiness());
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final GameController controller = GameScope.of(context);
    final GameState state = controller.state!;
    final Business? acik = controller.openBusiness;
    final List<Business> gecmis = controller.businesses
        .where((Business b) => !b.isOpen)
        .toList(growable: false);

    return SectionScaffold(
      icon: Icons.storefront_rounded,
      accent: BirOmurAccents.pirinc,
      title: 'Kendi İşim',
      subtitle: acik == null
          ? 'Maaş garantidir, kendi işi değildir. Sermaye ister, kâr da '
              'eder zarar da.'
          : null,
      backLabel: 'Meslek',
      onBack: widget.onBack,
      children: <Widget>[
        if (_sonuc != null) ...<Widget>[
          InfoPanel(icon: Icons.info_outline, text: _sonuc!),
          const SizedBox(height: 12),
        ],

        if (acik != null) ...<Widget>[
          _AcikIsKarti(business: acik, playerAge: state.player.age),
          const SizedBox(height: 14),

          // İşle ilgilen.
          Builder(
            builder: (BuildContext context) {
              final InteractionAvailability u =
                  controller.businessTendAvailability();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  FilledButton.icon(
                    key: const Key('business_tend'),
                    onPressed: u.isAllowed
                        ? () => _uygula(controller.tendBusiness())
                        : null,
                    icon: const Icon(Icons.handyman_outlined),
                    label: const Text('İşine bak'),
                  ),
                  if (!u.isAllowed) ...<Widget>[
                    const SizedBox(height: 6),
                    Text(
                      u.reason ?? '',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 14),

          // Para yatır.
          Text('İşe para koy', style: theme.textTheme.titleSmall),
          const SizedBox(height: 2),
          Text(
            'Para tek başına işi kurtarmaz ama toparlar. '
            'Cüzdanında ${trMoney(state.player.wallet)} var.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('business_invest_amount'),
            controller: _tutar,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Tutar (₺)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Builder(
            builder: (BuildContext context) {
              final int tutar = int.tryParse(_tutar.text.trim()) ?? 0;
              final InteractionAvailability u =
                  controller.businessInvestAvailability(tutar);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  OutlinedButton.icon(
                    key: const Key('business_invest'),
                    onPressed: u.isAllowed
                        ? () {
                            _uygula(controller.investInBusiness(tutar));
                            _tutar.clear();
                          }
                        : null,
                    icon: const Icon(Icons.savings_outlined),
                    label: const Text('Yatır'),
                  ),
                  if (!u.isAllowed && tutar > 0) ...<Widget>[
                    const SizedBox(height: 6),
                    Text(
                      u.reason ?? '',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            key: const Key('business_close'),
            onPressed: _kapatOnayi,
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('İşi devret'),
          ),
        ] else ...<Widget>[
          // Kurulabilecek işler.
          const MenuGroupTitle(
            text: 'Kurulabilecek işler',
            accent: BirOmurAccents.pirinc,
          ),
          const SizedBox(height: 8),
          for (final BusinessScale olcek in BusinessScale.values) ...<Widget>[
            if (kBusinessCatalog.any((BusinessType t) => t.scale == olcek))
              ...<Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 6),
                child: Text(
                  '${olcek.label} ölçek',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              for (final BusinessType tur in kBusinessCatalog
                  .where((BusinessType t) => t.scale == olcek)) ...<Widget>[
                _TurKarti(
                  tur: tur,
                  availability: controller.businessOpenAvailability(tur),
                  onOpen: () => _uygula(controller.openBusinessOf(tur)),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ],
        ],

        if (gecmis.isNotEmpty) ...<Widget>[
          const SizedBox(height: 18),
          const MenuGroupTitle(
            text: 'Geçmiş işler',
            accent: BirOmurAccents.mor,
          ),
          const SizedBox(height: 4),
          Text(
            'Kayıt silinmez: kapanan iş de burada durur.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          for (final Business b in gecmis) ...<Widget>[
            _AcikIsKarti(business: b, playerAge: state.player.age),
            const SizedBox(height: 10),
          ],
        ],
      ],
    );
  }
}

class _AcikIsKarti extends StatelessWidget {
  const _AcikIsKarti({required this.business, required this.playerAge});

  final Business business;
  final int playerAge;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final BusinessType? tur = business.type;
    final int beklenen = BusinessEngine.expectedProfit(business);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.45,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  tur?.name ?? business.typeId,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              Text(
                business.isOpen
                    ? '${business.startedAtAge} yaşından beri'
                    : business.endReason?.label ?? '',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const KilimDivider(),
          const SizedBox(height: 8),
          if (business.isOpen) ...<Widget>[
            _satir(theme, 'Durum', business.conditionLabel),
            _satir(
              theme,
              'Beklenen yıl',
              beklenen >= 0
                  ? '+${trMoney(beklenen)}'
                  : '−${trMoney(-beklenen)}',
            ),
          ] else
            _satir(
              theme,
              'Kapanış',
              '${business.closedAtAge} yaş · '
                  '${business.endReason?.label ?? ''}',
            ),
          _satir(theme, 'Konan para', trMoney(business.totalInvested)),
          _satir(
            theme,
            'Toplam net',
            business.totalProfit >= 0
                ? '+${trMoney(business.totalProfit)}'
                : '−${trMoney(-business.totalProfit)}',
          ),
          _satir(theme, 'Süre', '${business.yearsOpen(playerAge)} yıl'),
        ],
      ),
    );
  }

  Widget _satir(ThemeData theme, String baslik, String deger) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 104,
              child: Text(
                baslik,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: Text(deger, style: theme.textTheme.bodySmall),
            ),
          ],
        ),
      );
}

class _TurKarti extends StatelessWidget {
  const _TurKarti({
    required this.tur,
    required this.availability,
    required this.onOpen,
  });

  final BusinessType tur;
  final InteractionAvailability availability;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(tur.name, style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            tur.description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sermaye ${trMoney(tur.setupCost)} · iyi giderse yılda '
            '${trMoney(tur.baseYearlyProfit)}',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              key: Key('business_open_${tur.id}'),
              onPressed: availability.isAllowed ? onOpen : null,
              child: const Text('Kur'),
            ),
          ),
          if (!availability.isAllowed) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              availability.reason ?? '',
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
