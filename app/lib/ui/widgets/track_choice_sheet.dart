import 'package:flutter/material.dart';

import '../../data/education_tracks.dart';
import '../../domain/models/game_state.dart';
import '../../state/game_controller.dart';
import '../../state/game_scope.dart';
import '../../text/turkish_text.dart';
import '../sound/sound_scope.dart';
import '../sound/sound_service.dart';
import 'kilim_divider.dart';

/// Lise alanı seçim penceresi (D-094).
///
/// Lise başladığında alan seçimi **zorunludur**: seçim yapılmadan yaş
/// alınamaz. Bu yüzden pencere dışarı dokunarak kapanmaz; oyuncu bir alan
/// seçmeden çıkamaz. Seçimden sonra aynı pencerede sonuç metni gösterilir,
/// seçim eğitim geçmişine ve hayat günlüğüne yazılır.
class TrackChoiceSheet extends StatefulWidget {
  const TrackChoiceSheet({super.key});

  static Future<void> show(BuildContext context) {
    SoundScope.play(context, GameSound.notice);
    return showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      useRootNavigator: true,
      showDragHandle: false,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      builder: (BuildContext context) => const TrackChoiceSheet(),
    );
  }

  @override
  State<TrackChoiceSheet> createState() => _TrackChoiceSheetState();
}

class _TrackChoiceSheetState extends State<TrackChoiceSheet> {
  /// Seçim yapıldıysa sonucun **gerçekten uygulanmış** metni.
  String? _sonuc;

  void _sec(EducationTrack track) {
    final String? metin = GameScope.of(context).chooseTrack(track)?.text;
    setState(() => _sonuc = metin);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final GameController controller = GameScope.of(context);
    final GameState? state = controller.state;
    final int puan = state?.education.placementScore ?? 0;
    final List<EducationTrackInfo> acik = controller.availableTracks();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.alt_route_rounded,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    trUpper('Lise alanını seç'),
                    key: const Key('track_choice_title'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const KilimDivider(),
            const SizedBox(height: 14),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _sonuc ??
                          'Yerleştirme puanın $puan. Liseye alan seçmeden '
                              'devam edemezsin: seçtiğin alan eğitim '
                              'geçmişine yazılır, üniversite bölümlerini ve '
                              'ileride başvurabileceğin işleri etkiler.',
                      key: const Key('track_choice_text'),
                      style: theme.textTheme.bodyLarge,
                    ),
                    if (_sonuc == null) ...<Widget>[
                      const SizedBox(height: 14),
                      for (final EducationTrackInfo alan
                          in kEducationTracks) ...<Widget>[
                        _TrackTile(
                          info: alan,
                          enabled: acik.contains(alan),
                          onSelect: () => _sec(alan.track),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            if (_sonuc != null) ...<Widget>[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('track_choice_close'),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Tamam'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Tek bir alanın kartı.
///
/// Puanı yetmeyen alan gizlenmez; **neden kapalı olduğu** yazılarak soluk
/// gösterilir (D-063: hiçbir seçenek sebepsiz pasif kalmaz).
class _TrackTile extends StatelessWidget {
  const _TrackTile({
    required this.info,
    required this.enabled,
    required this.onSelect,
  });

  final EducationTrackInfo info;
  final bool enabled;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(info.label, style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              info.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    info.minScore == 0
                        ? 'Puan şartı yok'
                        : 'En az ${info.minScore} puan',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  key: Key('track_choice_${info.track.name}'),
                  onPressed: enabled ? onSelect : null,
                  child: Text(enabled ? 'Bu alanı seç' : 'Puanın yetmiyor'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
