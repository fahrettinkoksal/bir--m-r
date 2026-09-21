import 'package:flutter/material.dart';

import '../../domain/life/life_verdict.dart';
import '../theme/bir_omur_theme.dart';
import 'comic.dart';

/// Hayat sonu değerlendirmesi: "nasıl bir hayattı?"
///
/// Özetin **üstünde** durur: ekranın ilk söylediği şey, kaç eşya
/// bırakıldığı değil, hayatın nasıl geçtiğidir.
class LifeVerdictPanel extends StatelessWidget {
  const LifeVerdictPanel({super.key, required this.verdict});

  final LifeVerdict verdict;

  /// Eksen kimliğine göre sabit renk; aynı eksen her hayatta aynı
  /// renkte görünsün diye.
  static BirOmurAccent accentFor(String axisId) {
    switch (axisId) {
      case 'baglar':
        return BirOmurAccents.gul;
      case 'emek':
        return BirOmurAccents.mavi;
      case 'deneyim':
        return BirOmurAccents.turuncu;
      case 'huzur':
        return BirOmurAccents.yesil;
      default:
        return BirOmurAccents.mor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final BirOmurAccent baskin = accentFor(verdict.strongest.id);

    return ComicCard(
      key: const Key('life_verdict_panel'),
      color: baskin.softOf(context),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: HandwrittenText(
                  verdict.title,
                  key: const Key('life_verdict_title'),
                  size: 27,
                  tilt: -1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            verdict.sentence,
            key: const Key('life_verdict_sentence'),
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
          const SizedBox(height: 16),
          for (final VerdictAxis eksen in verdict.axes)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AxisBar(axis: eksen, accent: accentFor(eksen.id)),
            ),
          if (verdict.firsts.isNotEmpty) ...<Widget>[
            const SizedBox(height: 4),
            const _Baslik(text: 'İlkler', accent: BirOmurAccents.pirinc),
            const SizedBox(height: 8),
            for (final VerdictFirst ilk in verdict.firsts)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    ComicTag(
                      text: '${ilk.age}',
                      color: BirOmurAccents.pirinc.color,
                      handwritten: true,
                      fontSize: 11,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          ilk.text,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (verdict.never.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            const _Baslik(text: 'Hiç olmadı', accent: BirOmurAccents.nar),
            const SizedBox(height: 8),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: <Widget>[
                for (final String hic in verdict.never)
                  ComicTag(
                    text: hic,
                    color: theme.colorScheme.surface,
                    fontSize: 12,
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          HandwrittenText(
            verdict.closing,
            key: const Key('life_verdict_closing'),
            size: 18,
            tilt: 0.6,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

/// Bir eksenin çubuğu. **Puan değil ayna:** yüzde yazılmaz, kazanma
/// veya kaybetme yoktur; çubuk yalnızca hayatın hangi yöne ağır
/// bastığını gösterir.
class _AxisBar extends StatelessWidget {
  const _AxisBar({required this.axis, required this.accent});

  final VerdictAxis axis;
  final BirOmurAccent accent;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              axis.label,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                axis.note,
                textAlign: TextAlign.right,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints kisit) {
            final double genislik = kisit.maxWidth;
            return Container(
              height: 15,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: Comic.konturOf(context),
                  width: Comic.inceKontur,
                ),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: (axis.value / 100).clamp(0.02, 1.0),
                  child: Container(
                    margin: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      color: accent.color,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    // Çok kısa çubuklar görünmez kalmasın diye en az
                    // bir tutam genişlik bırakılır.
                    constraints: BoxConstraints(minWidth: genislik * 0.02),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Küçük bölüm başlığı: renkli bir tutam ve kalın yazı.
class _Baslik extends StatelessWidget {
  const _Baslik({required this.text, required this.accent});

  final String text;
  final BirOmurAccent accent;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      children: <Widget>[
        Container(
          width: 13,
          height: 13,
          decoration: BoxDecoration(
            color: accent.color,
            shape: BoxShape.circle,
            border: Border.all(
              color: Comic.konturOf(context),
              width: Comic.inceKontur,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
