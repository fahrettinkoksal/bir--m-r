import 'package:flutter/material.dart';

import '../../domain/models/person.dart';
import '../../domain/models/relation.dart';
import '../theme/bir_omur_theme.dart';
import 'comic.dart';
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
    final BirOmurAccent renk = _accentFor(person);

    return StickerButton(
      onPressed: onTap,
      expand: true,
      radius: Comic.yaricapBuyuk,
      padding: const EdgeInsets.fromLTRB(12, 11, 14, 11),
      child: Row(
        children: <Widget>[
          _Initial(person: person, faded: !alive, accent: renk),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  person.fullName,
                  textAlign: TextAlign.left,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: alive
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
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
            Icons.arrow_forward_ios_rounded,
            size: 15,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
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
    case RelationType.unlu:
      return BirOmurAccents.pirinc;
    case RelationType.torun:
    case RelationType.yegen:
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
    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: faded
            ? Theme.of(context).colorScheme.surfaceContainer
            : accent.color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Comic.konturOf(context),
          width: Comic.inceKontur,
        ),
        boxShadow: comicShadow(context, offset: Comic.kucukGolge),
      ),
      child: Text(
        trUpperFirst(person.firstName.characters.first),
        style: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w800,
          height: 1,
          color: faded
              ? Theme.of(context).colorScheme.onSurfaceVariant
              : accent.onColor,
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
        color: BirOmurColors.sari,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Comic.konturOf(context), width: 1.6),
      ),
      child: Text(
        'Aynı evde',
        style: theme.textTheme.labelSmall?.copyWith(
          color: BirOmurColors.murekkep,
        ),
      ),
    );
  }
}
