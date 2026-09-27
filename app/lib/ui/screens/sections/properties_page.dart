import 'package:flutter/material.dart';

import '../../../domain/economy/rental_engine.dart';
import '../../../domain/models/game_state.dart';
import '../../../domain/models/owned_item.dart';
import '../../../domain/models/rental.dart';
import '../../../state/game_controller.dart';
import '../../../state/game_scope.dart';
import '../../../text/turkish_text.dart';
import '../../theme/bir_omur_theme.dart';
import '../../widgets/section_scaffold.dart';

/// Evlerim ekranı (D-163).
///
/// Konutlar tek bir listede, **kullanım durumuyla** birlikte duruyor:
/// oturulan ev, kiradaki ev, boş ev. Her eve girilince detay açılıyor.
///
/// Kiraya verme akışı burada: oyuncu kira bedelini kendi belirliyor,
/// tahmini piyasa bandını görüyor, gelen adaylardan kiracıyı **kendi**
/// seçiyor. Sistem "en iyi aday" diye bir şey söylemiyor.
class PropertiesPage extends StatefulWidget {
  const PropertiesPage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<PropertiesPage> createState() => _PropertiesPageState();
}

class _PropertiesPageState extends State<PropertiesPage> {
  String? _acikEv;

  @override
  Widget build(BuildContext context) {
    final GameController controller = GameScope.of(context);
    final GameState state = controller.state!;
    final String? acik = _acikEv;

    if (acik != null && state.itemById(acik) != null) {
      return _PropertyDetail(
        home: state.itemById(acik)!,
        onBack: () => setState(() => _acikEv = null),
      );
    }

    final List<OwnedItem> evler = state.properties;

    return SectionScaffold(
      icon: Icons.home_work_rounded,
      accent: BirOmurAccents.yesil,
      title: 'Evlerim',
      subtitle: evler.isEmpty
          ? null
          : '${evler.length} konut · cüzdanında ${state.player.walletLabel}',
      backLabel: 'Varlıklar',
      onBack: widget.onBack,
      children: <Widget>[
        if (evler.isEmpty)
          const InfoPanel(
            icon: Icons.home_outlined,
            text: 'Henüz kendine ait bir evin yok. Mağazalar > Emlakçı '
                'bölümünden ilanlara bakabilirsin.',
          )
        else ...<Widget>[
          _PortfolioSummary(state: state),
          const SizedBox(height: 12),
          for (final OwnedItem ev in evler) ...<Widget>[
            _PropertyRow(
              home: ev,
              onTap: () => setState(() => _acikEv = ev.id),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ],
    );
  }
}

/// Bütün konutların toplamı: değer, yıllık kira, doluluk.
class _PortfolioSummary extends StatelessWidget {
  const _PortfolioSummary({required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<OwnedItem> evler = state.properties;
    int deger = 0;
    for (final OwnedItem ev in evler) {
      deger += RentalEngine.valueOf(state, ev);
    }
    final int yillikKira = state.leases
        .fold<int>(0, (int t, Lease l) => t + l.yearlyRent);
    final int kirada = state.leases.length;

    return Container(
      key: const Key('properties_summary'),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Toplam', style: theme.textTheme.titleSmall),
          const SizedBox(height: 6),
          _Line(label: 'Konut değeri', value: trMoney(deger)),
          _Line(label: 'Kirada', value: '$kirada / ${evler.length}'),
          if (yillikKira > 0)
            _Line(
              label: 'Aylık kira geliri',
              value: trMoney((yillikKira / 12).round()),
            ),
        ],
      ),
    );
  }
}

/// Listedeki bir satır: şehir, tip ve kullanım durumu.
class _PropertyRow extends StatelessWidget {
  const _PropertyRow({required this.home, required this.onTap});

  final OwnedItem home;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final GameState state = GameScope.of(context).state!;
    final PropertyUse durum = RentalEngine.useOf(state, home);
    final Lease? sozlesme = state.leaseOf(home.id);

    return InkWell(
      key: Key('property_row_${home.id}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              durum == PropertyUse.oturuluyor
                  ? Icons.house_rounded
                  : durum == PropertyUse.kirada
                      ? Icons.vpn_key_rounded
                      : Icons.meeting_room_outlined,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '${home.location ?? state.player.currentCity} / '
                    '${home.name}',
                    style: theme.textTheme.titleSmall,
                  ),
                  Text(
                    durum.label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (sozlesme != null)
                    Text(
                      'Kiracı: ${sozlesme.tenant.fullName} · aylık '
                      '${trMoney(sozlesme.monthlyRent)}',
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

/// Konut detayı: bilgiler, kiraya verme, bakım ve kârlılık özeti.
class _PropertyDetail extends StatefulWidget {
  const _PropertyDetail({required this.home, required this.onBack});

  final OwnedItem home;
  final VoidCallback onBack;

  @override
  State<_PropertyDetail> createState() => _PropertyDetailState();
}

class _PropertyDetailState extends State<_PropertyDetail> {
  final TextEditingController _kira = TextEditingController();
  bool _adayAc = false;
  String? _sonuc;
  bool _olumlu = false;
  bool _kiraBaslatildi = false;

  @override
  void dispose() {
    _kira.dispose();
    super.dispose();
  }

  int get _yazilanKira {
    final String temiz = _kira.text.replaceAll(RegExp(r'[^0-9]'), '');
    return temiz.isEmpty ? 0 : (int.tryParse(temiz) ?? 0);
  }

  void _sonucYaz(RentalOutcome? outcome) {
    if (outcome == null) return;
    setState(() {
      _sonuc = outcome.text;
      _olumlu = outcome.applied;
      if (outcome.applied) _adayAc = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final GameController controller = GameScope.of(context);
    final GameState state = controller.state!;
    final OwnedItem? ev = state.itemById(widget.home.id);
    if (ev == null) {
      return SectionScaffold(
        icon: Icons.home_work_rounded,
        accent: BirOmurAccents.yesil,
        title: 'Konut',
        backLabel: 'Evlerim',
        onBack: widget.onBack,
        children: const <Widget>[
          InfoPanel(
            icon: Icons.info_outline,
            text: 'Bu mülk artık sende değil.',
          ),
        ],
      );
    }

    final PropertyUse durum = RentalEngine.useOf(state, ev);
    final Lease? sozlesme = state.leaseOf(ev.id);
    final PropertyLedger defter = state.ledgerOf(ev.id);
    final int deger = RentalEngine.valueOf(state, ev);
    final ({int low, int high}) bant = RentalEngine.rentBand(state, ev);

    // Aylık kira alanı ilk açılışta piyasa bandının ortasıyla dolar:
    // oyuncu sıfırdan rakam uydurmak zorunda kalmasın.
    if (!_kiraBaslatildi && durum != PropertyUse.kirada) {
      _kiraBaslatildi = true;
      _kira.text = '${RentalEngine.marketRent(state, ev)}';
    }

    return SectionScaffold(
      icon: Icons.home_work_rounded,
      accent: BirOmurAccents.yesil,
      title: ev.name,
      subtitle: '${ev.location ?? state.player.currentCity} · ${durum.label}',
      backLabel: 'Evlerim',
      onBack: widget.onBack,
      children: <Widget>[
        Container(
          key: const Key('property_facts'),
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
              _Line(label: 'Şehir', value: ev.location ?? '—'),
              _Line(label: 'Konut tipi', value: ev.type.name),
              if (ev.purchasePrice != null)
                _Line(
                  label: 'Alış fiyatı',
                  value: trMoney(ev.purchasePrice!),
                ),
              _Line(label: 'Güncel tahmini değer', value: trMoney(deger)),
              _Line(
                label: 'Durum',
                value: '${ev.conditionLabel} (${ev.condition}/100)',
              ),
              _Line(
                label: 'Alındığı yaş',
                value: '${ev.acquiredAtAge} yaşında',
              ),
              _Line(label: 'Kullanım', value: durum.label),
              if (defter.lastMaintenanceAge != null)
                _Line(
                  label: 'Son bakım',
                  value: '${defter.lastMaintenanceAge} yaşında',
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_sonuc != null) ...<Widget>[
          Container(
            key: const Key('property_result'),
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

        // ---- Kiracı ------------------------------------------------------
        if (sozlesme != null)
          _TenantCard(
            lease: sozlesme,
            home: ev,
            onEnd: () => _sonucYaz(controller.endLease(ev)),
            onRenew: (int yeni) => _sonucYaz(controller.renewLease(ev, yeni)),
          )
        else if (durum == PropertyUse.bos)
          _RentOutCard(
            home: ev,
            band: bant,
            amountField: _kira,
            amount: _yazilanKira,
            showCandidates: _adayAc,
            onAmountChanged: () => setState(() {}),
            onFindTenants: () => setState(() => _adayAc = true),
            onPick: (TenantRecord t) => _sonucYaz(
              controller.signLease(
                home: ev,
                tenant: t,
                yearlyRent: _yazilanKira,
              ),
            ),
          )
        else
          const InfoPanel(
            icon: Icons.house_outlined,
            text: 'Burada yaşıyorsun. Kiraya vermek için önce başka bir eve '
                'ya da kiralık bir eve taşınman gerekiyor.',
          ),
        const SizedBox(height: 14),

        // ---- Bakım -------------------------------------------------------
        Text('Bakım', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        _UpkeepButtons(home: ev, onResult: _sonucYaz),
        const SizedBox(height: 16),

        // ---- Kârlılık ----------------------------------------------------
        _LedgerCard(ledger: defter),
      ],
    );
  }
}

/// Yürüyen sözleşme: kiracı, kira, ödeme geçmişi, yenileme.
class _TenantCard extends StatelessWidget {
  const _TenantCard({
    required this.lease,
    required this.home,
    required this.onEnd,
    required this.onRenew,
  });

  final Lease lease;
  final OwnedItem home;
  final VoidCallback onEnd;
  final void Function(int newYearlyRent) onRenew;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final GameController controller = GameScope.of(context);
    final int piyasa = controller.marketRent(home);
    final int yas = controller.state!.player.age;

    return Container(
      key: const Key('tenant_card'),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Kiracı', style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(lease.tenant.fullName, style: theme.textTheme.titleSmall),
          Text(
            '${lease.tenant.age} yaşında · ${lease.tenant.occupation}',
            style: theme.textTheme.bodySmall,
          ),
          Text(
            lease.tenant.household.label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          _Line(label: 'Aylık kira', value: trMoney(lease.monthlyRent)),
          _Line(label: 'Depozito', value: trMoney(lease.deposit)),
          _Line(
            label: 'Oturma süresi',
            value: '${lease.yearsIn(yas)} yıl',
          ),
          _Line(
            label: 'Ödeme',
            value: lease.troubleYears == 0
                ? '${lease.onTimeYears} yıl düzenli'
                : '${lease.onTimeYears} düzenli · '
                    '${lease.troubleYears} sorunlu yıl',
          ),
          const SizedBox(height: 10),
          // Kira yenileme: aynı kira, makul artış, yüksek artış. Yüksek
          // artış kiracının çıkma ihtimalini artırır — bu açıkça yazıyor.
          Text(
            'Kirayı yenile (tahmini piyasa: aylık '
            '${trMoney((piyasa / 12).round())})',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              OutlinedButton(
                key: const Key('renew_same'),
                onPressed: () => onRenew(lease.yearlyRent),
                child: const Text('Aynı kalsın'),
              ),
              OutlinedButton(
                key: const Key('renew_modest'),
                onPressed: () => onRenew((lease.yearlyRent * 1.10).round()),
                child: const Text('Makul artış'),
              ),
              OutlinedButton(
                key: const Key('renew_high'),
                onPressed: () => onRenew((lease.yearlyRent * 1.30).round()),
                child: const Text('Yüksek artış'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Yüksek artışta kiracı çıkabilir.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            key: const Key('end_lease'),
            onPressed: onEnd,
            child: const Text('Sözleşmeyi sonlandır'),
          ),
        ],
      ),
    );
  }
}

/// Boş evi kiraya verme: kira belirle, adayları getir, kiracıyı seç.
class _RentOutCard extends StatelessWidget {
  const _RentOutCard({
    required this.home,
    required this.band,
    required this.amountField,
    required this.amount,
    required this.showCandidates,
    required this.onAmountChanged,
    required this.onFindTenants,
    required this.onPick,
  });

  final OwnedItem home;
  final ({int low, int high}) band;
  final TextEditingController amountField;
  final int amount;
  final bool showCandidates;
  final VoidCallback onAmountChanged;
  final VoidCallback onFindTenants;
  final void Function(TenantRecord tenant) onPick;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final GameController controller = GameScope.of(context);
    final String engel = controller.rentOutAskBlockReason(home, amount);
    final List<TenantRecord> adaylar =
        showCandidates ? controller.tenantCandidatesFor(home, amount) : const <TenantRecord>[];

    return Container(
      key: const Key('rent_out_card'),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Kiraya ver', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Tahmini piyasa kirası: aylık '
            '${trMoney((band.low / 12).round())} – '
            '${trMoney((band.high / 12).round())}',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          TextField(
            key: const Key('rent_amount'),
            controller: amountField,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Yıllık kira (₺)',
              helperText: amount > 0
                  ? 'Aylık ${trMoney((amount / 12).round())}'
                  : 'Yıllık tutar yaz',
            ),
            onChanged: (String _) => onAmountChanged(),
          ),
          const SizedBox(height: 6),
          // Bandın dışına çıkmak serbest ama sonucu var: yüksek kirada
          // aday azalır, ev boş kalır. Bu açıkça yazıyor.
          Text(
            amount > band.high
                ? 'Piyasanın üstünde istiyorsun; başvuru az olur, ev boş '
                    'kalabilir.'
                : amount < band.low && amount > 0
                    ? 'Piyasanın altında istiyorsun; kiracı çabuk bulunur, '
                        'getiri düşer.'
                    : 'Piyasa bandındasın.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (engel.isNotEmpty) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              engel,
              key: const Key('rent_block'),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.error),
            ),
          ],
          const SizedBox(height: 10),
          FilledButton(
            key: const Key('find_tenants'),
            onPressed: engel.isEmpty ? onFindTenants : null,
            child: const Text('Kiracı ara'),
          ),
          if (showCandidates) ...<Widget>[
            const SizedBox(height: 12),
            if (adaylar.isEmpty)
              Text(
                'Bu kirayla kimse aramadı. Rakamı düşürmeyi düşünebilirsin.',
                key: const Key('no_candidates'),
                style: theme.textTheme.bodySmall,
              )
            else ...<Widget>[
              Text(
                '${adaylar.length} başvuru var. Kiracıyı sen seçiyorsun.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              for (final TenantRecord aday in adaylar) ...<Widget>[
                _CandidateTile(tenant: aday, onPick: () => onPick(aday)),
                const SizedBox(height: 8),
              ],
            ],
          ],
        ],
      ),
    );
  }
}

class _CandidateTile extends StatelessWidget {
  const _CandidateTile({required this.tenant, required this.onPick});

  final TenantRecord tenant;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      key: Key('candidate_${tenant.id}'),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(tenant.fullName, style: theme.textTheme.titleSmall),
          Text(
            '${tenant.age} yaşında · ${tenant.occupation}',
            style: theme.textTheme.bodySmall,
          ),
          Text(
            tenant.household.label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Gelir: ${tenant.income.label} · '
            'Ödeme geçmişi: ${tenant.track.label}',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          FilledButton.tonal(
            key: Key('pick_${tenant.id}'),
            onPressed: onPick,
            child: const Text('Bu kiracıyla anlaş'),
          ),
        ],
      ),
    );
  }
}

class _UpkeepButtons extends StatelessWidget {
  const _UpkeepButtons({required this.home, required this.onResult});

  final OwnedItem home;
  final void Function(RentalOutcome?) onResult;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final GameController controller = GameScope.of(context);
    final int bakim = controller.upkeepCost(home, major: false);
    final int tadilat = controller.upkeepCost(home, major: true);
    final String bakimEngel = controller.upkeepBlockReason(home, major: false);
    final String tadilatEngel = controller.upkeepBlockReason(home, major: true);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            OutlinedButton(
              key: const Key('do_upkeep'),
              onPressed: bakimEngel.isEmpty
                  ? () => onResult(
                        controller.upkeepProperty(home, major: false),
                      )
                  : null,
              child: Text('Bakım yap (${trMoney(bakim)})'),
            ),
            OutlinedButton(
              key: const Key('do_renovation'),
              onPressed: tadilatEngel.isEmpty
                  ? () => onResult(
                        controller.upkeepProperty(home, major: true),
                      )
                  : null,
              child: Text('Tadilat yap (${trMoney(tadilat)})'),
            ),
          ],
        ),
        if (bakimEngel.isNotEmpty) ...<Widget>[
          const SizedBox(height: 6),
          Text(
            bakimEngel,
            key: const Key('upkeep_block'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

/// Kârlılık özeti: bu ev gerçekten kazandırdı mı?
class _LedgerCard extends StatelessWidget {
  const _LedgerCard({required this.ledger});

  final PropertyLedger ledger;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    if (ledger.rentCollected == 0 && ledger.maintenanceSpent == 0) {
      return const InfoPanel(
        icon: Icons.receipt_long_outlined,
        text: 'Bu ev için henüz kira ya da masraf kaydı yok.',
      );
    }
    return Container(
      key: const Key('property_ledger'),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Bu evin hesabı', style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          _Line(
            label: 'Kira geliri',
            value: '+${trMoney(ledger.rentCollected)}',
          ),
          _Line(
            label: 'Bakım ve gider',
            value: '−${trMoney(ledger.maintenanceSpent)}',
          ),
          _Line(
            label: 'Net',
            value: ledger.netCash >= 0
                ? '+${trMoney(ledger.netCash)}'
                : trMoney(ledger.netCash),
            highlight: true,
          ),
          if (ledger.vacantYears > 0)
            _Line(label: 'Boş kaldığı yıl', value: '${ledger.vacantYears}'),
          if (ledger.tenantCount > 0)
            _Line(label: 'Kiracı sayısı', value: '${ledger.tenantCount}'),
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
