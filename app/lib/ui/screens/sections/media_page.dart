import 'package:flutter/material.dart';

import '../../../data/media_catalog.dart';
import '../../../domain/models/interaction.dart';
import '../../../domain/models/game_state.dart';
import '../../../domain/social/media_opportunities.dart';
import '../../../state/game_controller.dart';
import '../../../state/game_scope.dart';
import '../../../text/turkish_text.dart';
import '../../theme/bir_omur_theme.dart';
import '../../widgets/effect_chips.dart';
import '../../widgets/section_scaffold.dart';

/// Ün ve Medya Fırsatları (D-103).
///
/// Bölüm yalnızca Ün eşiği geçildiğinde menüde görünür; buraya gelen
/// oyuncunun Ünü zaten yeterlidir. Tek tek işlerin kendi Ün şartı
/// vardır ve yetmeyen iş **gerekçesiyle** soluk gösterilir (D-038).
class MediaPage extends StatefulWidget {
  const MediaPage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<MediaPage> createState() => _MediaPageState();
}

class _MediaPageState extends State<MediaPage> {
  MediaResult? _sonuc;

  @override
  Widget build(BuildContext context) {
    final GameController controller = GameScope.of(context);
    final GameState state = controller.state!;
    final int un = state.player.fame ?? 0;

    return SectionScaffold(
      icon: Icons.stars_rounded,
      accent: BirOmurAccents.pirinc,
      title: 'Ün ve Medya Fırsatları',
      subtitle: 'Ünün: $un',
      backLabel: 'Aktiviteler',
      onBack: widget.onBack,
      children: <Widget>[
        const InfoPanel(
          icon: Icons.campaign_outlined,
          text: 'Tanınmanın hayatta bir karşılığı vardır: dergiler, '
              'programlar ve markalar seni arar. Markalar kurgusaldır; '
              'bütün tutarlar oyun parasıdır.',
        ),
        // Kendiliğinden gelen davet ekranda açıkça durur (D-120).
        if (state.mediaInvitationId != null &&
            state.mediaInvitationAge == state.player.age) ...<Widget>[
          const SizedBox(height: 12),
          InfoPanel(
            icon: Icons.mark_email_unread_outlined,
            text: 'Bu yıl sana bir davet geldi: '
                '${_davetAdi(state.mediaInvitationId!)}. Ün şartı '
                'aranmıyor ve başvurun geri çevrilmeyecek. Davet bu yıl '
                'geçerli.',
          ),
        ],
        const SizedBox(height: 12),
        for (final MediaOpportunity is1 in kMediaOpportunities) ...<Widget>[
          _JobCard(
            job: is1,
            availability: controller.mediaAvailability(is1),
            followerGain: (state.totalFollowers * is1.followerRatio).round(),
            onAccept: () {
              final MediaResult? r = controller.acceptMediaJob(is1);
              setState(() => _sonuc = r);
            },
          ),
          const SizedBox(height: 10),
        ],
        if (_sonuc != null) ...<Widget>[
          const SizedBox(height: 4),
          InfoPanel(
            icon: _sonuc!.applied
                ? Icons.check_circle_outline
                : Icons.info_outline,
            text: _sonuc!.text,
          ),
          if (_sonuc!.effects.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            EffectChips(
              key: const Key('media_effects'),
              effects: _sonuc!.effects,
            ),
          ],
        ],
      ],
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({
    required this.job,
    required this.availability,
    required this.followerGain,
    required this.onAccept,
  });

  final MediaOpportunity job;
  final InteractionAvailability availability;

  /// Bu işin **gerçekten** getireceği takipçi; kitle yoksa sıfırdır.
  final int followerGain;

  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool acik = availability.isAllowed;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(job.label, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              job.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            // Yazan her satır **gerçekten** olacak olandır; takipçi
            // kazancı kitle yoksa hiç yazılmaz.
            Text(
              <String>[
                trMoney(job.fee),
                'Ün +${job.fameGain}',
                if (followerGain > 0) '${trNumber(followerGain)} takipçi',
              ].join(' · '),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (!acik) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                availability.reason!,
                key: Key('media_reason_${job.id}'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonal(
                key: Key('media_accept_${job.id}'),
                onPressed: acik ? onAccept : null,
                child: Text(acik ? 'Kabul et' : 'Şu an olmaz'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Davet edilen işin adı; katalogda yoksa kimliği yazılır.
String _davetAdi(String id) {
  for (final MediaOpportunity j in kMediaOpportunities) {
    if (j.id == id) return j.label;
  }
  return id;
}
