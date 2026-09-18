import 'package:flutter/material.dart';

import '../turkish_text.dart';

/// Bölüm başlığı ve isteğe bağlı açıklaması.
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
        Text(
          trUpper(title),
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: theme.colorScheme.primary,
          ),
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
