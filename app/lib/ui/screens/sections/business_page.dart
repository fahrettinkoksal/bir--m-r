import 'package:flutter/material.dart';

import '../../../data/business_catalog.dart';
import '../../../domain/economy/business_engine.dart';
import '../../../domain/economy/business_market.dart';
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
  void initState() {
    super.initState();
    // **Gerçek hata (Faho bildirdi):** "kendi işime para yatırmak
    // istediğimde tutar yazmama rağmen yatır seçeneği aktif olmuyor."
    //
    // Düğmenin açıklığı `_tutar.text`ten hesaplanıyordu ama yazı yazmak
    // yeniden çizim tetiklemiyordu; düğme sayfa açıldığındaki değerle
    // (0) kalıyor, yani hiç açılmıyordu. Denetleyici dinleniyor.
    _tutar.addListener(_tutarDegisti);
  }

  void _tutarDegisti() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tutar.removeListener(_tutarDegisti);
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
          _AcikIsKarti(
            business: acik,
            playerAge: state.player.age,
            marketPrice: controller.businessMarketPrice(),
            price: controller.businessPrice(),
            demand: controller.businessDemand(),
          ),
          const SizedBox(height: 14),

          // --- Fiyat (§4) -------------------------------------------
          _FiyatBolumu(
            business: acik,
            onApply: (int fiyat) =>
                _uygula(controller.setBusinessPrice(fiyat)),
          ),
          const SizedBox(height: 14),

          // --- Reklam (§8) ------------------------------------------
          _ReklamBolumu(
            business: acik,
            onSelect: (BusinessAd r) => _uygula(controller.setBusinessAd(r)),
          ),
          const SizedBox(height: 14),

          // --- Bakım (§10) ------------------------------------------
          Builder(
            builder: (BuildContext context) {
              final InteractionAvailability u =
                  controller.businessMaintenanceAvailability();
              final int bedel = controller.businessMaintenanceCost();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  OutlinedButton.icon(
                    key: const Key('business_maintain'),
                    onPressed: u.isAllowed
                        ? () => _uygula(controller.maintainBusiness())
                        : null,
                    icon: const Icon(Icons.build_outlined),
                    label: Text('Bakım yaptır (${trMoney(bedel)})'),
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

          // --- Personel (§7) ----------------------------------------
          if ((acik.type?.staffSlots ?? 0) > 0) ...<Widget>[
            Text('Personel', style: theme.textTheme.titleSmall),
            const SizedBox(height: 2),
            Text(
              acik.staffLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            for (final ({StaffAction hamle, String etiket, IconData ikon}) a
                in const <({StaffAction hamle, String etiket, IconData ikon})>[
              (
                hamle: StaffAction.zam,
                etiket: 'Zam yap',
                ikon: Icons.trending_up_rounded,
              ),
              (
                hamle: StaffAction.iseAl,
                etiket: 'Yerine birini bul',
                ikon: Icons.person_add_alt_1_outlined,
              ),
              (
                hamle: StaffAction.ilgilen,
                etiket: 'Kendin ilgilen',
                ikon: Icons.groups_2_outlined,
              ),
            ]) ...<Widget>[
              Builder(
                builder: (BuildContext context) {
                  final InteractionAvailability u =
                      controller.businessStaffAvailability(a.hamle);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      OutlinedButton.icon(
                        key: Key('business_staff_${a.hamle.name}'),
                        onPressed: u.isAllowed
                            ? () => _uygula(
                                  controller.businessStaff(a.hamle),
                                )
                            : null,
                        icon: Icon(a.ikon),
                        label: Text(a.etiket),
                      ),
                      if (!u.isAllowed) ...<Widget>[
                        const SizedBox(height: 4),
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
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 6),
          ],

          // --- Son yılların dökümü (§31) ----------------------------
          if (acik.history.isNotEmpty) ...<Widget>[
            _GecmisYillar(business: acik),
            const SizedBox(height: 14),
          ],

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

/// Fiyat bölümü (§4).
///
/// Oyuncu ucuz, piyasa civarı, pahalı ya da kendi yazdığı tutarı seçer.
/// Bölge ortalaması ekranda yazılıdır ki karar körlemesine olmasın (§3).
class _FiyatBolumu extends StatefulWidget {
  const _FiyatBolumu({required this.business, required this.onApply});

  final Business business;
  final void Function(int fiyat) onApply;

  @override
  State<_FiyatBolumu> createState() => _FiyatBolumuState();
}

class _FiyatBolumuState extends State<_FiyatBolumu> {
  final TextEditingController _ozel = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ozel.addListener(_degisti);
  }

  void _degisti() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ozel
      ..removeListener(_degisti)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final GameController controller = GameScope.of(context);
    final BusinessType? tur = widget.business.type;
    if (tur == null) return const SizedBox.shrink();
    final int ortalama = controller.businessMarketPrice();
    final int simdiki = controller.businessPrice();
    final ({int min, int max}) aralik = controller.businessPriceRange();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(tur.priceLabel, style: theme.textTheme.titleSmall),
        const SizedBox(height: 2),
        Text(
          'Bölgendeki ortalama: ${trMoney(ortalama)}\n'
          'Senin fiyatın: ${trMoney(simdiki)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final ({String etiket, double oran}) s
                in <({String etiket, double oran})>[
              (
                etiket: 'Ucuz',
                oran: BusinessEngine.prototypeOnlyCheapRatio,
              ),
              (etiket: 'Piyasa', oran: 1.0),
              (
                etiket: 'Pahalı',
                oran: BusinessEngine.prototypeOnlyExpensiveRatio,
              ),
            ])
              OutlinedButton(
                key: Key('business_price_${s.etiket.toLowerCase()}'),
                onPressed: () =>
                    widget.onApply((ortalama * s.oran).round()),
                child: Text(
                  '${s.etiket} · ${trMoney((ortalama * s.oran).round())}',
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('business_price_custom'),
          controller: _ozel,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Özel tutar (₺)',
            helperText: '${trMoney(aralik.min)} – ${trMoney(aralik.max)}',
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const Key('business_price_apply'),
          onPressed: (int.tryParse(_ozel.text.trim()) ?? 0) > 0
              ? () {
                  widget.onApply(int.parse(_ozel.text.trim()));
                  _ozel.clear();
                }
              : null,
          icon: const Icon(Icons.sell_outlined),
          label: const Text('Fiyatı değiştir'),
        ),
      ],
    );
  }
}

/// Reklam bölümü (§8).
class _ReklamBolumu extends StatelessWidget {
  const _ReklamBolumu({required this.business, required this.onSelect});

  final Business business;
  final void Function(BusinessAd reklam) onSelect;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final BusinessType? tur = business.type;
    if (tur == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text('Reklam', style: theme.textTheme.titleSmall),
        const SizedBox(height: 2),
        Text(
          business.ad == BusinessAd.yok
              ? 'Şu an reklam vermiyorsun.'
              : '${business.ad.label} yürüyor '
                  '(${business.adStreak + 1}. yıl). '
                  'Aynı kampanya her yıl biraz daha az iş yapar.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        for (final BusinessAd r in BusinessAd.values)
          if (r != business.ad) ...<Widget>[
            OutlinedButton(
              key: Key('business_ad_${r.name}'),
              onPressed: () => onSelect(r),
              child: Text(
                r == BusinessAd.yok
                    ? 'Reklamı kes'
                    : '${r.label} · yıllık '
                        '${trMoney((tur.baseRevenue * r.costShare).round())}',
              ),
            ),
            const SizedBox(height: 6),
          ],
      ],
    );
  }
}

/// Son yılların dökümü (§31).
class _GecmisYillar extends StatelessWidget {
  const _GecmisYillar({required this.business});

  final Business business;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final BusinessType? tur = business.type;
    if (tur == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Son yıllar', style: theme.textTheme.titleSmall),
        const SizedBox(height: 6),
        for (final BusinessYear y in business.history.reversed)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(
                  color:
                      theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '${y.age} yaş',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    BusinessEngine.yearReport(tur, y)
                        .split('\n')
                        .skip(2)
                        .join('\n')
                        .trim(),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _AcikIsKarti extends StatelessWidget {
  const _AcikIsKarti({
    required this.business,
    required this.playerAge,
    this.marketPrice = 0,
    this.price = 0,
    this.demand,
  });

  final Business business;
  final int playerAge;

  /// Bölge ortalaması (§3). 0 ise gösterilmez (kapanmış iş).
  final int marketPrice;

  /// İşletmenin fiyatı (§4).
  final int price;

  /// Müşteri yoğunluğu (§5). `null` ise gösterilmez.
  final BusinessDemand? demand;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final BusinessType? tur = business.type;
    final int beklenen = BusinessEngine.expectedProfit(business);
    final BusinessYear? sonYil = business.lastYear;
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
            _satir(theme, 'İtibar', business.reputationLabel),
            if (marketPrice > 0 && tur != null) ...<Widget>[
              _satir(theme, tur.priceLabel, trMoney(price)),
              _satir(theme, 'Bölge ortalaması', trMoney(marketPrice)),
            ],
            if (demand != null)
              _satir(theme, 'Müşteri', demand!.label),
            if ((tur?.staffSlots ?? 0) > 0)
              _satir(theme, 'Personel', business.staffLabel),
            if (tur?.equipmentLabel != null)
              _satir(theme, 'Bakım', business.upkeepLabel),
            _satir(
              theme,
              'Reklam',
              business.ad == BusinessAd.yok ? 'Yok' : business.ad.label,
            ),
            if (sonYil != null) ...<Widget>[
              _satir(theme, 'Geçen yıl ciro', trMoney(sonYil.revenue)),
              _satir(theme, 'Geçen yıl gider', trMoney(sonYil.totalCost)),
              _satir(
                theme,
                'Geçen yıl net',
                sonYil.net >= 0
                    ? '+${trMoney(sonYil.net)}'
                    : '−${trMoney(-sonYil.net)}',
              ),
            ] else
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
