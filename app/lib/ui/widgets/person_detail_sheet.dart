import 'package:flutter/material.dart';

import '../../domain/models/person.dart';
import 'kilim_divider.dart';

/// Kişi ayrıntısı.
///
/// Yalnızca gerçekten modellenen bilgileri gösterir. Bu aşamada aile
/// etkileşimleri (vakit geçirme, hediye) **henüz uygulanmadığı için** sahte
/// düğme konmaz; bunun yerine durum açıkça yazılır.
class PersonDetailSheet extends StatelessWidget {
  const PersonDetailSheet({
    super.key,
    required this.person,
    required this.playerAge,
  });

  final Person person;
  final int playerAge;

  static Future<void> show(
    BuildContext context, {
    required Person person,
    required int playerAge,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext context) =>
          PersonDetailSheet(person: person, playerAge: playerAge),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(person.fullName, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              person.labelFor(playerAge),
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            const KilimDivider(),
            const SizedBox(height: 14),
            _Row(
              label: 'Yaş',
              value: person.isAlive ? '${person.age}' : '${person.age} (vefat etti)',
            ),
            _Row(label: 'Cinsiyet', value: person.gender.label),
            _Row(label: 'Durum', value: person.occupationLabel),
            if (person.wealth != null)
              _Row(label: 'Kendi maddi durumu', value: person.wealth!.label),
            _Row(
              label: 'Hane',
              value: person.isAlive
                  ? (person.inPlayerHousehold ? 'Seninle aynı evde' : 'Ayrı evde')
                  : '—',
            ),
            if (person.isAlive) ...<Widget>[
              const SizedBox(height: 16),
              Text('Yakınlık', style: theme.textTheme.labelLarge),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: person.bond / 100,
                  minHeight: 8,
                  backgroundColor:
                      theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                  valueColor:
                      AlwaysStoppedAnimation<Color>(theme.colorScheme.secondary),
                ),
              ),
            ],
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
              child: Text(
                'Vakit geçirme ve hediye gibi aile etkileşimleri bu sürümde '
                'henüz yazılmadı; sonraki aşamada eklenecek.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
