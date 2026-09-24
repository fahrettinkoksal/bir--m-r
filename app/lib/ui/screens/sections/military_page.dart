import 'package:flutter/material.dart';

import '../../../data/military_catalog.dart';
import '../../../domain/career/military_service.dart';
import '../../../domain/models/game_state.dart';
import '../../../domain/models/interaction.dart';
import '../../../domain/models/military.dart';
import '../../../domain/models/person.dart';
import '../../../state/game_scope.dart';
import '../../../text/turkish_text.dart';
import '../../theme/bir_omur_theme.dart';
import '../../widgets/comic.dart';
import '../../widgets/section_scaffold.dart';

/// Askerlik menüsü (Paket 29).
///
/// Meslek bölümünün altında ayrı bir sayfadır. Koşulu sağlanmayan yol
/// **çalışmayan düğme olarak konmaz**: gerekçesi yazılır.
class MilitaryPage extends StatefulWidget {
  const MilitaryPage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<MilitaryPage> createState() => _MilitaryPageState();
}

class _MilitaryPageState extends State<MilitaryPage> {
  String? _sonuc;

  void _uygula(MilitaryResult? sonuc) {
    if (sonuc == null) return;
    setState(() => _sonuc = sonuc.text);
  }

  Future<void> _aileden() async {
    final List<Person> adaylar = GameScope.of(context).bedelliPayers();
    if (adaylar.isEmpty) return;
    final Person? secilen = await showModalBottomSheet<Person>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) => _PayerSheet(
        payers: adaylar,
        playerAge: GameScope.of(context).state!.player.age,
      ),
    );
    if (secilen == null || !mounted) return;
    _uygula(GameScope.of(context).askFamilyForBedelli(secilen.id));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final GameState state = GameScope.of(context).state!;
    final MilitaryState askerlik = state.military;
    final InteractionAvailability bedelli = GameScope.of(
      context,
    ).bedelliAvailability();
    final List<Person> odeyebilecekler = GameScope.of(context).bedelliPayers();

    return SectionScaffold(
      icon: Icons.military_tech_rounded,
      title: 'Askerlik',
      subtitle: askerlik.label,
      backLabel: 'Meslek',
      accent: BirOmurAccents.yesil,
      onBack: widget.onBack,
      children: <Widget>[
        _DurumKarti(state: state),
        const SizedBox(height: 12),

        if (askerlik.isServing)
          const InfoPanel(
            icon: Icons.schedule_rounded,
            text:
                'Şu an görevdesin. Süren dolunca terhis olacaksın; '
                'her yaş ilerlemesinde bir yıl geçer.',
          )
        else if (askerlik.isDeferred) ...<Widget>[
          InfoPanel(
            icon: Icons.pause_circle_outline,
            text: askerlik.studentDeferral
                ? 'Askerliğin okul yüzünden tecilli. Okulun bittiğinde '
                      'doğrudan çağrılacaksın.'
                : 'Askerliğin ${askerlik.deferredUntilAge} yaşına kadar '
                      'tecilli. O yaşta yeniden çağrılacaksın.',
          ),
          const SizedBox(height: 10),
          InfoPanel(
            icon: Icons.confirmation_number_outlined,
            text:
                'Kalan tecil hakkın: '
                '${MilitaryService.remainingDeferrals(state)}',
          ),
        ] else if (askerlik.isFugitive) ...<Widget>[
          // Bakaya: ceza birikiyor ve yakalanma ihtimali her yıl artıyor.
          InfoPanel(
            icon: Icons.running_with_errors_outlined,
            text:
                'Bakayasın. '
                '${MilitaryService.fugitiveYears(state)} yıldır '
                'gitmedin. Kendin başvurursan ceza '
                '${trMoney(MilitaryService.prototypeOnlyFineFor(state, caught: false))}; '
                'yakalanırsan iki katı. Yakalanma ihtimali her yıl '
                'artıyor.',
          ),
          const SizedBox(height: 10),
          MenuRow(
            key: const Key('military_surrender'),
            title: 'Kendin başvur',
            subtitle: 'Cezayı öde, yeniden çağrıl',
            icon: Icons.handshake_outlined,
            accent: BirOmurAccents.mavi,
            onTap: () => _uygula(GameScope.of(context).surrenderMilitary()),
          ),
          const SizedBox(height: 10),
          if (bedelli.isAllowed)
            MenuRow(
              key: const Key('military_bedelli_late'),
              title: 'Bedelli öde (ek bedelli)',
              subtitle:
                  'Ücret: '
                  '${trMoney(MilitaryService.bedelliCostFor(state))} · '
                  'Kaçtığın her yıl için ek bedel var',
              icon: Icons.payments_outlined,
              accent: BirOmurAccents.pirinc,
              onTap: () => _uygula(GameScope.of(context).payBedelli()),
            ),
          const SizedBox(height: 10),
        ] else if (askerlik.status.kapandi)
          InfoPanel(
            icon: Icons.check_circle_outline,
            text: askerlik.status == MilitaryStatus.bedelli
                ? _bedelliMetni(state)
                : 'Askerlik meselen kapandı: ${askerlik.status.label}.',
          )
        else ...<Widget>[
          // Zorunlu askerliği olmayan oyuncu (kadın) "Yapılmadı" yazısını
          // bir eksik gibi okuyordu. Durum bir kez açıkça yazılır ve
          // gönüllü yolun açık olduğu söylenir.
          if (!MilitaryService.isObliged(state)) ...<Widget>[
            const InfoPanel(
              icon: Icons.info_outline,
              text:
                  'Bu hayatta zorunlu askerliğin yok; yapılmamış bir '
                  'yükümlülük de yok. İstersen subay ya da astsubay '
                  'olarak gönüllü başvurabilirsin.',
            ),
            const SizedBox(height: 10),
          ],
          // Çağrıldıysa üç yol var: git, öde ya da kaç (Paket 31).
          if (askerlik.isCalled) ...<Widget>[
            const InfoPanel(
              icon: Icons.mark_email_unread_outlined,
              text:
                  'Celbin geldi. Askere gidebilir, bedelli ödeyebilir, '
                  'tecil hakkın varsa erteleyebilir ya da gitmeyip '
                  'bakaya kalabilirsin. Bakaya kalırsan ceza birikir ve '
                  'yakalanabilirsin.',
            ),
            const SizedBox(height: 10),
            if (MilitaryService.canDefer(state))
              MenuRow(
                key: const Key('military_defer'),
                title: 'Tecil ettir',
                subtitle:
                    '${MilitaryService.prototypeOnlyDeferralYears} yıl · '
                    'Kalan hak: '
                    '${MilitaryService.remainingDeferrals(state)}',
                icon: Icons.pause_circle_outline,
                accent: BirOmurAccents.mavi,
                onTap: () => _uygula(GameScope.of(context).deferMilitary()),
              )
            else
              const InfoPanel(
                icon: Icons.pause_circle_outline,
                text: 'Tecil hakkın kalmadı.',
              ),
            const SizedBox(height: 10),
            MenuRow(
              key: const Key('military_flee'),
              title: 'Gitme, bakaya kal',
              subtitle: 'Ceza birikir ve yakalanabilirsin',
              icon: Icons.directions_run_rounded,
              accent: BirOmurAccents.nar,
              onTap: () => _uygula(GameScope.of(context).fleeMilitary()),
            ),
            const SizedBox(height: 10),
          ],
          const MenuGroupTitle(
            text: 'Katılma yolları',
            accent: BirOmurAccents.yesil,
          ),
          for (final MilitaryTrack yol in MilitaryTrack.values)
            // Er yolu yalnızca yükümlünün yoludur. Yükümlü olmayana
            // "senin için yok" diye ayrı bir satır koymak, olmayan bir
            // yükümlülüğü hatırlatmaktan başka işe yaramıyordu.
            if (yol != MilitaryTrack.er ||
                MilitaryService.isObliged(state)) ...<Widget>[
              Builder(
                builder: (BuildContext context) {
                  final InteractionAvailability uygunluk = GameScope.of(
                    context,
                  ).militaryAvailability(yol);
                  if (!uygunluk.isAllowed) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InfoPanel(
                        icon: yol.icon,
                        text: '${yol.label}: ${uygunluk.reason}',
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: MenuRow(
                      key: Key('military_track_${yol.name}'),
                      title: yol.label,
                      subtitle: yol == MilitaryTrack.er
                          ? yol.description
                          : '${yol.description} '
                                'Maaş: ${trMoney(yol.prototypeOnlySalary)}/yıl',
                      icon: yol.icon,
                      accent: BirOmurAccents.yesil,
                      onTap: () =>
                          _uygula(GameScope.of(context).enlistMilitary(yol)),
                    ),
                  );
                },
              ),
            ],
          if (MilitaryService.isObliged(state)) ...<Widget>[
            const MenuGroupTitle(
              text: 'Bedelli',
              accent: BirOmurAccents.pirinc,
            ),
            if (!bedelli.isAllowed)
              InfoPanel(
                icon: Icons.payments_outlined,
                text: 'Bedelli: ${bedelli.reason}',
              )
            else ...<Widget>[
              MenuRow(
                key: const Key('military_bedelli_self'),
                title: 'Bedelli öde',
                subtitle:
                    'Ücret: '
                    '${trMoney(MilitaryService.bedelliCostFor(state))} · '
                    'Cüzdanında ${state.player.walletLabel}',
                icon: Icons.payments_outlined,
                accent: BirOmurAccents.pirinc,
                onTap: () => _uygula(GameScope.of(context).payBedelli()),
              ),
              const SizedBox(height: 10),
              // Uydurma bir hami gösterilmez: ödeyebilecek yakın yoksa
              // düğme de yok, gerekçesi yazılır.
              if (odeyebilecekler.isEmpty)
                const InfoPanel(
                  icon: Icons.family_restroom_outlined,
                  text:
                      'Ailenden isteyebileceğin kimse yok: bu ücreti '
                      'karşılayabilecek, aranın da iyi olduğu bir yakının '
                      'bulunmuyor.',
                )
              else
                MenuRow(
                  key: const Key('military_bedelli_family'),
                  title: 'Ailenden iste',
                  subtitle:
                      '${odeyebilecekler.length} kişiye sorabilirsin · '
                      'Hayır da diyebilirler',
                  icon: Icons.family_restroom_outlined,
                  accent: BirOmurAccents.gul,
                  onTap: _aileden,
                ),
              const SizedBox(height: 10),
            ],
          ],
        ],

        if (_sonuc != null) ...<Widget>[
          const SizedBox(height: 4),
          ComicCard(
            key: const Key('military_outcome'),
            color: theme.colorScheme.surfaceContainerHighest,
            child: Text(_sonuc!, style: theme.textTheme.bodyMedium),
          ),
        ],
      ],
    );
  }

  String _bedelliMetni(GameState state) {
    final String? odeyenId = state.military.paidByPersonId;
    if (odeyenId == null) {
      return 'Bedelli ücretini kendin ödedin; askerlik meselen kapandı.';
    }
    final Person? odeyen = state.personById(odeyenId);
    return odeyen == null
        ? 'Bedelli ödendi; askerlik meselen kapandı.'
        : 'Bedelli ücretini ${odeyen.fullName} ödedi; askerlik meselen '
              'kapandı.';
  }
}

class _DurumKarti extends StatelessWidget {
  const _DurumKarti({required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MilitaryState a = state.military;
    final bool yukumlu = MilitaryService.isObliged(state);
    final List<({String label, String value})>
    satirlar = <({String label, String value})>[
      (label: 'Durum', value: MilitaryService.statusLabel(state)),
      if (a.track != null) (label: 'Yol', value: a.track!.label),
      if (a.rank != null) (label: 'Rütbe', value: a.rank!.label),
      if (a.calledAtAge != null)
        (label: 'Celp', value: '${a.calledAtAge} yaşında'),
      if (a.startedAtAge != null)
        (label: 'Başlangıç', value: '${a.startedAtAge} yaşında'),
      if (a.finishedAtAge != null)
        (label: 'Bitiş', value: '${a.finishedAtAge} yaşında'),
      // Tecil yalnızca yükümlünün meselesidir; yükümlü olmayanda
      // "2 hakkın kaldı" demek anlamsız bir sayaç gösteriyordu.
      if (yukumlu)
        (
          label: 'Tecil hakkı',
          value: '${MilitaryService.remainingDeferrals(state)} kaldı',
        ),
      if (a.caughtCount > 0)
        (label: 'Yakalanma', value: '${a.caughtCount} kez'),
      if (a.fineTotal > 0) (label: 'Ödenen ceza', value: trMoney(a.fineTotal)),
    ];

    return ComicCard(
      color: BirOmurAccents.yesil.softOf(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final ({String label, String value}) r in satirlar)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(
                    width: 92,
                    child: Text(
                      r.label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(r.value, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Bedelliyi kimden isteyeceğini seçtiren sayfa.
class _PayerSheet extends StatelessWidget {
  const _PayerSheet({required this.payers, required this.playerAge});

  final List<Person> payers;
  final int playerAge;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Kimden isteyeceksin?', style: theme.textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(
                'Sorduğun kişi hayır diyebilir. Araniz ne kadar iyiyse ve '
                'durumu ne kadar yerindeyse kabul etme ihtimali o kadar '
                'yüksek.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              for (final Person p in payers) ...<Widget>[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    key: Key('bedelli_payer_${p.id}'),
                    onPressed: () => Navigator.of(context).pop(p),
                    style: OutlinedButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(p.fullName, style: theme.textTheme.titleSmall),
                        const SizedBox(height: 2),
                        Text(
                          '${p.labelFor(playerAge)} · '
                          '${p.wealth?.label ?? ''} · yakınlık ${p.bond}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
