import 'package:flutter/material.dart';

import '../../domain/models/person.dart';
import '../../text/turkish_text.dart';

/// Aile listesindeki kişi satırı.
///
/// Bağ türü ile hane bilgisi ayrı ayrı gösterilir: akraba olmak aynı evde
/// yaşamayı gerektirmez (D-014).
class PersonCard extends StatelessWidget {
  const PersonCard({
    super.key,
    required this.person,
    required this.playerAge,
    required this.onTap,
  });

  final Person person;
  final int playerAge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool alive = person.isAlive;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: <Widget>[
              _Initial(person: person, faded: !alive),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      person.fullName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: alive
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: <Widget>[
                        Text(
                          alive
                              ? '${person.labelFor(playerAge)} · ${person.age} yaşında'
                              : '${person.labelFor(playerAge)} · vefat etti',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        // Hane bilgisi bağ türünden ayrı gösterilir (D-014).
                        if (alive && person.inPlayerHousehold)
                          const _HouseholdBadge(),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Initial extends StatelessWidget {
  const _Initial({required this.person, required this.faded});

  final Person person;
  final bool faded;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color base = faded ? scheme.outline : scheme.secondary;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: base.withValues(alpha: 0.14),
        shape: BoxShape.circle,
        border: Border.all(color: base.withValues(alpha: 0.4)),
      ),
      alignment: Alignment.center,
      child: Text(
        trUpper(person.firstName.characters.first),
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: base,
        ),
      ),
    );
  }
}

class _HouseholdBadge extends StatelessWidget {
  const _HouseholdBadge();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiary.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Aynı evde',
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}
