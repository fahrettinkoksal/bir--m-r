import 'package:flutter/material.dart';

import '../theme/bir_omur_theme.dart';
import 'comic.dart';

/// Bölüm başlığı ve isteğe bağlı açıklaması.
///
/// Ana ekranda "Hayat günlüğü" gibi başlıklar için: el yazısıyla yazılmış
/// bir başlık ve altında kısa bir açıklama (Paket 19).
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            HandwrittenText(title, size: 26, tilt: -1.5),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: Comic.konturOf(context).withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ],
        ),
        if (subtitle != null) ...<Widget>[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
