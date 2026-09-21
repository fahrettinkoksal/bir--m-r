import 'package:flutter/material.dart';

import '../../../data/social_catalog.dart';
import '../../../domain/models/game_state.dart';
import '../../../domain/models/interaction.dart';
import '../../../domain/models/social_account.dart';
import '../../../domain/social/social_engine.dart';
import '../../../state/game_controller.dart';
import '../../../state/game_scope.dart';
import '../../theme/bir_omur_theme.dart';
import '../../widgets/effect_chips.dart';
import '../../widgets/section_scaffold.dart';

/// Sosyal medya ana sayfası: platformlar ve hesap durumu.
///
/// Arayüz Bir Ömür'e özgüdür; gerçek platformların logoları veya ekran
/// tasarımları kullanılmaz.
class SocialMediaPage extends StatefulWidget {
  const SocialMediaPage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<SocialMediaPage> createState() => _SocialMediaPageState();
}

class _SocialMediaPageState extends State<SocialMediaPage> {
  SocialPlatform? _acikPlatform;
  SocialOutcome? _sonuc;

  @override
  Widget build(BuildContext context) {
    final GameController controller = GameScope.of(context);
    final GameState state = controller.state!;

    final SocialPlatform? acik = _acikPlatform;
    if (acik != null && state.accountFor(acik) != null) {
      return _PlatformPage(
        platform: acik,
        account: state.accountFor(acik)!,
        outcome: _sonuc,
        onPost: (SocialContent content) {
          final SocialOutcome? outcome = controller.postContent(content);
          setState(() => _sonuc = outcome);
        },
        onBack: () => setState(() {
          _acikPlatform = null;
          _sonuc = null;
        }),
      );
    }

    return SectionScaffold(
      accent: BirOmurAccents.cini,
      title: 'Sosyal medya',
      subtitle: state.socialAccounts.isEmpty
          ? 'Hesap açmak zorunda değilsin.'
          : 'Toplam ${state.totalFollowers} takipçi',
      backLabel: 'Aktiviteler',
      onBack: widget.onBack,
      children: <Widget>[
        for (final SocialPlatform platform in SocialPlatform.values) ...<Widget>[
          _PlatformCard(
            platform: platform,
            account: state.accountFor(platform),
            availability: controller.socialAccountAvailability(platform),
            onOpenAccount: () {
              final SocialOutcome? outcome =
                  controller.openSocialAccount(platform);
              setState(() => _sonuc = outcome);
            },
            onEnter: () => setState(() {
              _acikPlatform = platform;
              _sonuc = null;
            }),
          ),
          const SizedBox(height: 10),
        ],
        if (_sonuc != null && _acikPlatform == null) ...<Widget>[
          const SizedBox(height: 4),
          InfoPanel(icon: Icons.campaign_outlined, text: _sonuc!.text),
        ],
        const SizedBox(height: 12),
        const InfoPanel(
          icon: Icons.info_outline,
          text: 'Gelir, sponsorluk ve mesajlaşma henüz yazılmadı; '
              'yazılmamış özellikler düğme olarak gösterilmiyor.',
        ),
      ],
    );
  }
}

class _PlatformCard extends StatelessWidget {
  const _PlatformCard({
    required this.platform,
    required this.account,
    required this.availability,
    required this.onOpenAccount,
    required this.onEnter,
  });

  final SocialPlatform platform;
  final SocialAccount? account;
  final InteractionAvailability availability;
  final VoidCallback onOpenAccount;
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool hesapVar = account != null;

    return Card(
      child: InkWell(
        onTap: hesapVar ? onEnter : null,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(platform.icon, color: theme.colorScheme.secondary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      platform.label,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  if (hesapVar)
                    Text(
                      '${account!.followers} ${platform.audienceWord}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (hesapVar)
                Text(
                  '${account!.postCount} paylaşım · '
                  '${account!.createdAtAge} yaşında açıldı',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        availability.isAllowed
                            ? 'Hesabın yok. İstersen açabilirsin.'
                            : (availability.reason ?? ''),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    FilledButton.tonal(
                      onPressed:
                          availability.isAllowed ? onOpenAccount : null,
                      child: const Text('Hesap aç'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tek bir platformun sayfası: içerik türleri ve geçmiş.
class _PlatformPage extends StatelessWidget {
  const _PlatformPage({
    required this.platform,
    required this.account,
    required this.outcome,
    required this.onPost,
    required this.onBack,
  });

  final SocialPlatform platform;
  final SocialAccount account;
  final SocialOutcome? outcome;
  final void Function(SocialContent content) onPost;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final GameController controller = GameScope.of(context);
    final List<SocialContent> icerikler = contentsFor(platform);

    return SectionScaffold(
      accent: BirOmurAccents.cini,
      title: platform.label,
      subtitle: '${account.followers} ${platform.audienceWord} · '
          '${account.postCount} paylaşım · '
          'bu yıl kalan: ${controller.remainingSocialPosts(platform)}',
      backLabel: 'Sosyal medya',
      onBack: onBack,
      children: <Widget>[
        for (final SocialContent icerik in icerikler) ...<Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(icerik.label, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    icerik.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          controller
                                  .socialPostAvailability(icerik)
                                  .isAllowed
                              ? ''
                              : (controller
                                      .socialPostAvailability(icerik)
                                      .reason ??
                                  ''),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      FilledButton.tonal(
                        onPressed: controller
                                .socialPostAvailability(icerik)
                                .isAllowed
                            ? () => onPost(icerik)
                            : null,
                        child: const Text('Paylaş'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (outcome != null) ...<Widget>[
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.secondary.withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(outcome!.text, style: theme.textTheme.bodyMedium),
                if (outcome!.effects.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12),
                  EffectChips(effects: outcome!.effects),
                ],
              ],
            ),
          ),
        ],
        if (account.posts.isNotEmpty) ...<Widget>[
          const SizedBox(height: 14),
          Text(
            'Son paylaşımların',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          for (final SocialPost post in account.posts.reversed.take(6))
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '${post.age} yaşında · ${post.label} · '
                '${post.followerDelta >= 0 ? '+' : ''}${post.followerDelta} '
                '${platform.audienceWord}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ],
    );
  }
}
