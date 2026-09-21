import 'package:flutter/material.dart';

import '../../domain/models/person.dart';
import '../../domain/models/relation.dart';
import '../sound/sound_scope.dart';
import '../sound/sound_service.dart';
import '../theme/bir_omur_theme.dart';
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

    // Kişi kartı da menü satırlarıyla aynı dili konuşur: yumuşak gölge,
    // renkli baş harf ve okunaklı rozetler.
    final bool gece = theme.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: gece
                ? Colors.black.withValues(alpha: 0.45)
                : const Color(0xFF1B1A2E).withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: () {
            SoundScope.play(context, GameSound.tap);
            onTap();
          },
          borderRadius: BorderRadius.circular(22),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: gece
                    ? theme.colorScheme.outlineVariant
                    : const Color(0xFFECECF3),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: <Widget>[
                _Initial(
                  person: person,
                  faded: !alive,
                  accent: _accentFor(person),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        person.fullName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 15.5,
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
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: theme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.55),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bağ türüne göre kişi kartının rengi.
///
/// Renk yalnızca görsel bir ipucudur; bağ türü, hane ve yakınlık bilgisi
/// yazıyla da gösterilmeye devam eder.
BirOmurAccent _accentFor(Person person) {
  if (!person.isAlive) return BirOmurAccents.pirinc;
  switch (person.relation) {
    case RelationType.es:
    case RelationType.sevgili:
    case RelationType.eskiSevgili:
    case RelationType.eskiEs:
      return BirOmurAccents.gul;
    case RelationType.cocuk:
    case RelationType.torun:
      return BirOmurAccents.mavi;
    case RelationType.anne:
    case RelationType.baba:
    case RelationType.kardes:
      return BirOmurAccents.nar;
    case RelationType.arkadas:
    case RelationType.sinifArkadasi:
      return BirOmurAccents.turuncu;
    case RelationType.isArkadasi:
      return BirOmurAccents.mor;
    case RelationType.ogretmen:
      return BirOmurAccents.mor;
    case RelationType.anneanne:
    case RelationType.babaanne:
    case RelationType.anneTarafiDede:
    case RelationType.babaTarafiDede:
    case RelationType.teyze:
    case RelationType.dayi:
    case RelationType.hala:
    case RelationType.amca:
      return BirOmurAccents.cini;
  }
}

class _Initial extends StatelessWidget {
  const _Initial({
    required this.person,
    required this.faded,
    required this.accent,
  });

  final Person person;
  final bool faded;
  final BirOmurAccent accent;

  @override
  Widget build(BuildContext context) {
    final Color base = accent.of(context);
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        gradient: faded
            ? LinearGradient(
                colors: <Color>[
                  base.withValues(alpha: 0.30),
                  accent.deepOf(context).withValues(alpha: 0.30),
                ],
              )
            : accent.gradientOf(context),
        shape: BoxShape.circle,
        boxShadow: faded
            ? const <BoxShadow>[]
            : <BoxShadow>[
                BoxShadow(
                  color: accent.deepOf(context).withValues(alpha: 0.30),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      alignment: Alignment.center,
      child: Text(
        trUpper(person.firstName.characters.first),
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 18,
          color: BirOmurColors.krem.withValues(alpha: faded ? 0.75 : 1),
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
        color: BirOmurColors.pirinc.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Aynı evde',
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0.1,
          color: theme.brightness == Brightness.dark
              ? BirOmurColors.pirincAcik
              : BirOmurColors.pirincKoyu,
        ),
      ),
    );
  }
}
