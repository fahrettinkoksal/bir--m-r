import 'package:flutter/material.dart';

import '../../domain/models/life_log.dart';

/// Hayat günlüğü — hatıra defteri hissi veren, en yeni satır üstte liste.
class LifeLogView extends StatelessWidget {
  const LifeLogView({super.key, required this.entries});

  final List<LifeLogEntry> entries;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<LifeLogEntry> ordered = entries.reversed.toList(growable: false);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Column(
        children: <Widget>[
          for (int i = 0; i < ordered.length; i++)
            _LogRow(entry: ordered[i], isLast: i == ordered.length - 1),
        ],
      ),
    );
  }
}

class _LogRow extends StatelessWidget {
  const _LogRow({required this.entry, required this.isLast});

  final LifeLogEntry entry;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 44,
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '${entry.age} yaş',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          Container(
            width: 1.2,
            height: 20,
            margin: const EdgeInsets.only(right: 12, top: 2),
            color: theme.colorScheme.tertiary.withValues(alpha: 0.5),
          ),
          Expanded(
            child: Text(entry.text, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
