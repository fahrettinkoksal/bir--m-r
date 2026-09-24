import 'package:flutter/material.dart';

import '../../data/university_catalog.dart';
import '../../domain/models/game_state.dart';
import '../../state/game_controller.dart';
import '../../state/game_scope.dart';
import '../../text/turkish_text.dart';
import '../sound/sound_scope.dart';
import '../sound/sound_service.dart';
import 'kilim_divider.dart';

/// Lise bittikten sonraki yol seçimi penceresi (D-111).
///
/// Faho bildirdi: "üni olayında da aynı şekilde ilk önce üni bölümümü
/// seçtikten sonra hayatta geri kalan aktivitelere karar vermeliyim".
/// Lise alan seçimiyle (D-094) aynı kural: karar verilmeden yaş alınamaz,
/// bu yüzden pencere dışarı dokunarak kapanmaz.
///
/// **Üniversiteye gitmemek de bir karardır** ve her zaman sunulur. Uygun
/// bölüm bulunmasa bile bu kapı açık kalır; yoksa oyuncu kilitlenirdi.
class AfterSchoolChoiceSheet extends StatefulWidget {
  const AfterSchoolChoiceSheet({super.key});

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
      builder: (BuildContext context) => const AfterSchoolChoiceSheet(),
    );
  }

  @override
  State<AfterSchoolChoiceSheet> createState() => _AfterSchoolChoiceSheetState();
}

class _AfterSchoolChoiceSheetState extends State<AfterSchoolChoiceSheet> {
  /// Karar verildiyse **gerçekten uygulanmış** sonucun metni.
  String? _sonuc;

  @override
  void initState() {
    super.initState();
    // Eski kayıtlarda ve yeni mezunlarda sınav puanı eksik olabilir.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) GameScope.of(context).ensureUniversityExamScore();
    });
  }

  void _basvur(UniversityProgram bolum) {
    final String? metin = GameScope.of(context).applyToUniversity(bolum)?.text;
    setState(() => _sonuc = metin);
  }

  void _gitme() {
    final String? metin = GameScope.of(context).skipUniversity()?.text;
    setState(() => _sonuc = metin);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final GameController controller = GameScope.of(context);
    final GameState? state = controller.state;
    final List<UniversityProgram> bolumler = controller.availablePrograms();
    final int? sinav = controller.universityExamScore;
    final String alan = state?.education.trackInfo?.label ?? 'yok';

    // Başvuru reddedilmiş olabilir; o zaman karar hâlâ bekliyordur ve
    // pencere kapanmaz. Kapanış yalnızca karar gerçekten kapandıysa.
    final bool karargapandi = !controller.needsAfterSchoolChoice;

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
                  Icons.school_rounded,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    trUpper('Lise bitti: sırada ne var?'),
                    key: const Key('after_school_title'),
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
                          'Lise alanın: $alan. Üniversite sınav puanın '
                              '${sinav ?? 0}. Bir karar vermeden yıl '
                              'geçmez: ya bir bölüme başvur ya da '
                              'üniversiteye gitmeyeceğini söyle.',
                      key: const Key('after_school_text'),
                      style: theme.textTheme.bodyLarge,
                    ),
                    if (!karargapandi) ...<Widget>[
                      const SizedBox(height: 14),
                      if (bolumler.isEmpty)
                        Text(
                          'Puanınla başvurabileceğin bir bölüm yok.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      for (final UniversityProgram bolum in bolumler) ...<Widget>[
                        _ProgramTile(
                          program: bolum,
                          myScore: controller.programScore(bolum),
                          blockReason: controller.programBlockReason(bolum),
                          onApply: () => _basvur(bolum),
                        ),
                        const SizedBox(height: 10),
                      ],
                      const SizedBox(height: 4),
                      // Bu kapı her zaman açıktır: uygun bölüm olmasa bile
                      // oyuncu kilitlenmez.
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          key: const Key('after_school_skip'),
                          onPressed: _gitme,
                          child: const Text(
                            'Üniversiteye gitmeyeceğim, iş arayacağım',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (karargapandi) ...<Widget>[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('after_school_close'),
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

/// Tek bir bölümün kartı.
///
/// Puanı yetmeyen bölüm gizlenmez; **neden kapalı olduğu** yazılarak soluk
/// gösterilir (D-063).
class _ProgramTile extends StatelessWidget {
  const _ProgramTile({
    required this.program,
    required this.myScore,
    required this.blockReason,
    required this.onApply,
  });

  final UniversityProgram program;
  final int myScore;
  final String? blockReason;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool acik = blockReason == null;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(program.name, style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              'Taban puan ${program.minScore} · senin puanın $myScore',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (!acik) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                blockReason!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonal(
                key: Key('after_school_apply_${program.id}'),
                onPressed: acik ? onApply : null,
                child: Text(acik ? 'Başvur' : 'Başvuramazsın'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
