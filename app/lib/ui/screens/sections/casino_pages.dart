import 'package:flutter/material.dart';

import '../../../domain/casino/blackjack.dart';
import '../../../domain/casino/casino_rules.dart';
import '../../../domain/casino/roulette.dart';
import '../../../domain/models/blackjack_game.dart';
import '../../../domain/models/game_state.dart';
import '../../../domain/models/interaction.dart';
import '../../../domain/models/playing_card.dart';
import '../../../state/game_controller.dart';
import '../../../state/game_scope.dart';
import '../../theme/bir_omur_theme.dart';
import '../../widgets/roulette_wheel.dart';
import '../../../domain/casino/horse_race.dart';
import '../../widgets/race_track.dart';
import '../../widgets/section_scaffold.dart';
import '../../../text/turkish_text.dart';

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

enum _CasinoTable { kok, blackjack, rulet, atYarisi }

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
      case _CasinoTable.atYarisi:
        return HorseRacePage(
          onBack: () => setState(() => _masa = _CasinoTable.kok),
        );
      case _CasinoTable.kok:
        break;
    }

    return SectionScaffold(
      icon: Icons.casino_rounded,
      accent: BirOmurAccents.nar,
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
          accent: BirOmurAccents.yesil,
          onTap: () => setState(() => _masa = _CasinoTable.blackjack),
        ),
        const SizedBox(height: 10),
        MenuRow(
          key: const Key('casino_roulette_row'),
          title: 'Rulet',
          subtitle: 'Tek sıfırlı Avrupa ruleti',
          icon: Icons.casino_outlined,
          accent: BirOmurAccents.nar,
          onTap: () => setState(() => _masa = _CasinoTable.rulet),
        ),
        const SizedBox(height: 10),
        MenuRow(
          key: const Key('casino_horse_row'),
          title: 'At yarışı',
          subtitle: 'Beş at koşar, sen birine oynarsın',
          icon: Icons.emoji_events_outlined,
          accent: BirOmurAccents.turuncu,
          onTap: () => setState(() => _masa = _CasinoTable.atYarisi),
        ),
        const SizedBox(height: 12),
        InfoPanel(
          icon: Icons.savings_outlined,
          text: 'Bu yıl oynadığın toplam bahis: ${trMoney(state.wagerThisAge)}. '
              'Gelirine ve cüzdanına göre bu yılki bahis bütçen '
              '${trMoney(CasinoAccess.yearlyBudget(state))}'
              '${state.settings.wagerLimitPerAge == null ? '' : ' '
                  '(kendi sınırın: ${trMoney(state.settings.wagerLimitPerAge!)})'}'
              '. Bahis en az ${trMoney(CasinoRules.prototypeOnlyMinBet)}, '
              'en fazla ${trMoney(CasinoAccess.maxBet(state))}.',
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
    // Adımlar oyuncunun bu yılki bütçesinden türetilir; sabit yüksek
    // tutarlar gösterilmez (D-040).
    final List<int> adimlar = controller.betSteps();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final int adim in adimlar)
          ChoiceChip(
            key: Key('bet_$adim'),
            label: Text(trMoney(adim)),
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
  int? _secilenBahis;
  String? _sonMesaj;

  @override
  Widget build(BuildContext context) {
    final GameController controller = GameScope.of(context);
    final GameState state = controller.state!;
    final BlackjackGame? oyun = state.blackjack;
    // Bahis adımları oyuncunun bu yılki bütçesinden gelir; seçim yoksa en
    // küçük adım kullanılır.
    final List<int> adimlar = controller.betSteps();
    final int bahis = _secilenBahis != null && adimlar.contains(_secilenBahis)
        ? _secilenBahis!
        : adimlar.first;

    return SectionScaffold(
      icon: Icons.style_rounded,
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
            bet: bahis,
            onChanged: (int v) => setState(() => _secilenBahis = v),
          ),
          const SizedBox(height: 14),
          _BlockReason(controller.betAvailability(bahis)),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const Key('blackjack_deal'),
              onPressed: controller.betAvailability(bahis).isAllowed
                  ? () => setState(() {
                        _sonMesaj = controller.dealBlackjack(bahis)?.text;
                      })
                  : null,
              child: Text('${trMoney(bahis)} ile el aç'),
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
            // El bittiğinde tek seçenek "Masadan kalk" değildir (D-090):
            // oyuncu aynı bahisle devam edebilir ya da bahsini
            // değiştirebilir. Yeni el, önceki elin sonucu **kesinleşmiş**
            // durum üzerinden açılır; para iki kez el değiştirmez.
            _BlockReason(controller.betAvailability(oyun.bet)),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('blackjack_again'),
                onPressed: controller.betAvailability(oyun.bet).isAllowed
                    ? () => setState(() {
                          controller.closeBlackjackHand();
                          _sonMesaj = controller.dealBlackjack(oyun.bet)?.text;
                        })
                    : null,
                child: Text('Aynı bahisle tekrar (${trMoney(oyun.bet)})'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                key: const Key('blackjack_change_bet'),
                onPressed: () => setState(() {
                  controller.closeBlackjackHand();
                  _secilenBahis = oyun.bet;
                  _sonMesaj = null;
                }),
                child: const Text('Bahsi değiştir'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                key: const Key('blackjack_close'),
                onPressed: () => setState(() {
                  controller.closeBlackjackHand();
                  _sonMesaj = null;
                  widget.onBack();
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
                  ? '${trMoney(net)} kazandın.'
                  : net < 0
                      ? '${trMoney(-net)} kaybettin.'
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
  int? _secilenBahis;
  RouletteBetType _tur = RouletteBetType.kirmizi;
  int _sayi = 7;
  String? _sonMesaj;

  /// Çarkın duracağı sayı ve her çevirmede artan kimlik (Paket 30).
  ///
  /// Sonuç **alanda** belirlenir; animasyon yalnızca onu gösterir.
  int? _inecekSayi;
  int _cevirmeNo = 0;

  /// Çark dönerken sonuç metni **gizlenir**: çevirmeden önce sonucu
  /// okumak oyunu bozar.
  bool _donuyor = false;

  void _cevir(GameController controller, int bahis) {
    final CasinoOutcome? sonuc =
        controller.spinRoulette(_tur, bahis, number: _sayi);
    if (sonuc == null || !sonuc.applied) {
      setState(() => _sonMesaj = sonuc?.text);
      return;
    }
    setState(() {
      _sonMesaj = sonuc.text;
      _inecekSayi = controller.lastRouletteNumber;
      _cevirmeNo++;
      _donuyor = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final GameController controller = GameScope.of(context);
    final GameState state = controller.state!;
    final ThemeData theme = Theme.of(context);
    final List<int> adimlar = controller.betSteps();
    final int bahis = _secilenBahis != null && adimlar.contains(_secilenBahis)
        ? _secilenBahis!
        : adimlar.first;

    return SectionScaffold(
      icon: Icons.donut_large_rounded,
      title: 'Rulet',
      subtitle: 'Cüzdanın: ${state.player.walletLabel}',
      backLabel: 'Kumarhane',
      onBack: widget.onBack,
      children: <Widget>[
        const InfoPanel(
          icon: Icons.rule_outlined,
          text: CasinoRules.rouletteRulesText,
        ),
        const SizedBox(height: 14),
        Center(
          child: RouletteWheel(
            key: const Key('roulette_wheel'),
            landOn: _inecekSayi,
            spinId: _cevirmeNo,
            onFinished: () {
              if (mounted) setState(() => _donuyor = false);
            },
          ),
        ),
        const SizedBox(height: 14),
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
          bet: bahis,
          onChanged: (int v) => setState(() => _secilenBahis = v),
        ),
        const SizedBox(height: 14),
        _BlockReason(controller.betAvailability(bahis)),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            key: const Key('roulette_spin'),
            onPressed: !_donuyor && controller.betAvailability(bahis).isAllowed
                ? () => _cevir(controller, bahis)
                : null,
            child: Text(_donuyor ? 'Çark dönüyor…' : '${trMoney(bahis)} oyna'),
          ),
        ),
        // Sonuç ancak çark durunca yazılır.
        if (_sonMesaj != null && !_donuyor) ...<Widget>[
          const SizedBox(height: 12),
          InfoPanel(icon: Icons.casino_outlined, text: _sonMesaj!),
        ],
      ],
    );
  }
}


/// At yarışı masası (Paket 30).
///
/// Kazanan at bahisten **bağımsız** olarak çekilir; pist yalnızca o
/// sonucu gösterir.
class HorseRacePage extends StatefulWidget {
  const HorseRacePage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<HorseRacePage> createState() => _HorseRacePageState();
}

class _HorseRacePageState extends State<HorseRacePage> {
  int? _secilenBahis;
  int _kulvar = 1;
  String? _sonMesaj;
  int _kosuNo = 0;
  bool _kosuyor = false;

  @override
  void initState() {
    super.initState();
    // Sayfa açılınca kadro kurulur.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (GameScope.of(context).raceField.isEmpty) {
        GameScope.of(context).newRaceField();
      }
    });
  }

  void _kos(GameController controller, int bahis) {
    final CasinoOutcome? sonuc = controller.betOnHorse(_kulvar, bahis);
    if (sonuc == null || !sonuc.applied) {
      setState(() => _sonMesaj = sonuc?.text);
      return;
    }
    // Bahis yatırıldı; sonuç **henüz kesinleşmedi** (D-089). Ekranda
    // yalnızca "koşu başlıyor" yazar.
    setState(() {
      _sonMesaj = sonuc.text;
      _kosuNo++;
      _kosuyor = true;
    });
  }

  /// Bahis yapmadan koşuyu izler (D-089).
  ///
  /// Para hiç el değiştirmez; yalnızca kadro yenilenip koşu oynatılır.
  void _bahissizKos(GameController controller) {
    controller.newRaceField();
    setState(() {
      _sonMesaj = 'Bahis yapmadan izliyorsun.';
      _kosuNo++;
      _kosuyor = true;
    });
  }

  /// Animasyon bitti: bekleyen bahis **tek ve atomik** işlemle kesinleşir.
  void _kosuBitti(GameController controller) {
    if (!mounted) return;
    final CasinoOutcome? sonuc = controller.settleRace();
    setState(() {
      _kosuyor = false;
      if (sonuc != null && sonuc.applied) _sonMesaj = sonuc.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    final GameController controller = GameScope.of(context);
    final GameState state = controller.state!;
    final ThemeData theme = Theme.of(context);
    final List<int> adimlar = controller.betSteps();
    final int bahis = _secilenBahis != null && adimlar.contains(_secilenBahis)
        ? _secilenBahis!
        : adimlar.first;
    final List<RaceHorse> kadro = controller.raceField;

    return SectionScaffold(
      icon: Icons.emoji_events_rounded,
      title: 'At yarışı',
      subtitle: 'Cüzdanın: ${state.player.walletLabel}',
      backLabel: 'Kumarhane',
      onBack: widget.onBack,
      children: <Widget>[
        const InfoPanel(
          icon: Icons.rule_outlined,
          text: HorseRacing.rulesText,
        ),
        const SizedBox(height: 14),
        if (kadro.isEmpty)
          const InfoPanel(
            icon: Icons.hourglass_empty_rounded,
            text: 'Kadro hazırlanıyor…',
          )
        else ...<Widget>[
          RaceTrack(
            key: const Key('race_track'),
            horses: kadro,
            result: controller.lastRace,
            raceId: _kosuNo,
            betLane: _kulvar,
            onFinished: () => _kosuBitti(controller),
          ),
          const SizedBox(height: 14),
          Text('Hangi ata oynuyorsun?', style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final RaceHorse at in kadro)
                ChoiceChip(
                  key: Key('horse_lane_${at.lane}'),
                  label: Text('${at.name} · ${at.oddsLabel}'),
                  selected: _kulvar == at.lane,
                  onSelected:
                      _kosuyor ? null : (_) => setState(() => _kulvar = at.lane),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Bahis miktarı', style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          _BetSelector(
            bet: bahis,
            onChanged: (int v) => setState(() => _secilenBahis = v),
          ),
          const SizedBox(height: 14),
          _BlockReason(controller.horseBetAvailability(bahis)),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const Key('horse_race_start'),
              onPressed:
                  !_kosuyor && controller.horseBetAvailability(bahis).isAllowed
                      ? () => _kos(controller, bahis)
                      : null,
              child: Text(
                _kosuyor ? 'Koşu sürüyor…' : '${trMoney(bahis)} oyna',
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              // "Yeni kadro" kaldırıldı (D-089): oyuncu kadroyu beğenene
              // kadar yenileyip en iyi oranı seçebiliyordu. Yerine bahis
              // yapmadan izleme kondu.
              key: const Key('horse_race_watch'),
              onPressed: _kosuyor ? null : () => _bahissizKos(controller),
              child: const Text('Bahis yapmadan yarışı başlat'),
            ),
          ),
          // Sonuç ancak koşu bitince yazılır.
          if (_sonMesaj != null && !_kosuyor) ...<Widget>[
            const SizedBox(height: 12),
            InfoPanel(icon: Icons.emoji_events_outlined, text: _sonMesaj!),
          ],
        ],
      ],
    );
  }
}
