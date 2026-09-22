import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/casino/horse_race.dart';
import '../theme/bir_omur_theme.dart';

/// Koşan atların pisti (Paket 30).
///
/// **Animasyon sonucu belirlemez.** Kazanan ve bitiş sırası alanda
/// (`HorseRacing.placeBet`) zaten çekilmiştir; pist yalnızca o sonucu
/// gösterir: atlar bitiş sırasına göre varır.
class RaceTrack extends StatefulWidget {
  const RaceTrack({
    super.key,
    required this.horses,
    required this.result,
    required this.raceId,
    required this.betLane,
    required this.onFinished,
  });

  final List<RaceHorse> horses;

  /// Koşunun sonucu; `null` ise atlar başlangıç çizgisinde bekler.
  final RaceResult? result;

  /// Her koşuda değişen kimlik; aynı sonuç tekrar gelse de animasyon
  /// yeniden başlasın diye.
  final int raceId;

  /// Oyuncunun oynadığı kulvar; pistte işaretlenir.
  final int? betLane;

  /// Koşu bitince çağrılır: sonuç metni ancak o zaman gösterilir.
  final VoidCallback onFinished;

  @override
  State<RaceTrack> createState() => _RaceTrackState();
}

class _RaceTrackState extends State<RaceTrack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _kontrol = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3000),
  );

  @override
  void initState() {
    super.initState();
    _kontrol.addStatusListener((AnimationStatus durum) {
      if (durum == AnimationStatus.completed) widget.onFinished();
    });
    if (widget.result != null) _kontrol.forward();
  }

  @override
  void didUpdateWidget(RaceTrack eski) {
    super.didUpdateWidget(eski);
    if (widget.raceId != eski.raceId && widget.result != null) {
      _kontrol
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _kontrol.dispose();
    super.dispose();
  }

  /// Bir atın o andaki ilerlemesi (0-1).
  ///
  /// Bitiş sırası sonucu belirler: birinci en hızlı varır. Yol boyunca
  /// küçük dalgalanmalar var ki koşu tekdüze görünmesin — ama **varış
  /// sırası hiçbir zaman değişmez**.
  double _ilerleme(int lane, double t) {
    final RaceResult? sonuc = widget.result;
    if (sonuc == null) return 0;
    final int sira = sonuc.finishOrder.indexOf(lane);
    // Birinci tam 1'e ulaşır, sonrakiler biraz geride kalır.
    final double hedef = 1.0 - sira * 0.055;
    final double dalga =
        math.sin(t * math.pi * 3 + lane) * 0.035 * (1 - t) * (1 - t);
    return (Curves.easeInOut.transform(t) * hedef + dalga).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _kontrol,
      builder: (BuildContext context, Widget? child) {
        final double t = _kontrol.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            for (final RaceHorse at in widget.horses)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _Lane(
                  horse: at,
                  progress: _ilerleme(at.lane, t),
                  isBet: widget.betLane == at.lane,
                  finished: _kontrol.isCompleted,
                  won: widget.result?.winnerLane == at.lane,
                  theme: theme,
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Kulvar renkleri: her at bir bakışta ayırt edilsin.
Color _laneColor(int lane) {
  const List<Color> renkler = <Color>[
    BirOmurColors.kirmizi,
    BirOmurColors.mavi,
    BirOmurColors.sari,
    BirOmurColors.mor,
    BirOmurColors.turkuaz,
  ];
  return renkler[(lane - 1) % renkler.length];
}

class _Lane extends StatelessWidget {
  const _Lane({
    required this.horse,
    required this.progress,
    required this.isBet,
    required this.finished,
    required this.won,
    required this.theme,
  });

  final RaceHorse horse;
  final double progress;
  final bool isBet;
  final bool finished;
  final bool won;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final Color kontur = Comic.konturOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                '${horse.lane}. ${horse.name}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: isBet ? FontWeight.w800 : FontWeight.w500,
                  color: finished && won
                      ? BirOmurColors.yesilKoyu
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Text(
              horse.oddsLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints kisit) {
            const double atGenisligi = 26;
            final double yol =
                (kisit.maxWidth - atGenisligi).clamp(0.0, double.infinity);
            return SizedBox(
              height: 22,
              child: Stack(
                children: <Widget>[
                  // Pist.
                  Container(
                    height: 22,
                    decoration: BoxDecoration(
                      color: isBet
                          ? BirOmurColors.sari.withValues(alpha: 0.25)
                          : theme.colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: kontur,
                        width: Comic.inceKontur,
                      ),
                    ),
                  ),
                  // Bitiş çizgisi.
                  Positioned(
                    right: 6,
                    top: 3,
                    bottom: 3,
                    child: Container(width: 2, color: kontur),
                  ),
                  // At. **Emoji kullanılmıyor:** oyunun yazı tipleri
                  // emoji içermiyor ve her cihazda aynı görünmüyor;
                  // bunun yerine kulvar numarasını taşıyan renkli bir
                  // jokey işareti çiziliyor.
                  Positioned(
                    left: yol * progress,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Container(
                        width: atGenisligi - 4,
                        height: atGenisligi - 4,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _laneColor(horse.lane),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: kontur,
                            width: Comic.inceKontur,
                          ),
                        ),
                        child: Text(
                          '${horse.lane}',
                          style: TextStyle(
                            fontFamily: BirOmurTheme.yaziTipi,
                            fontSize: 12,
                            height: 1,
                            fontWeight: FontWeight.w800,
                            color: _laneColor(horse.lane).computeLuminance() >
                                    0.55
                                ? BirOmurColors.murekkep
                                : BirOmurColors.kagit,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
