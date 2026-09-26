import 'package:flutter/material.dart';

import '../../../domain/models/game_state.dart';
import '../../../domain/models/marriage.dart';
import '../../../domain/models/person.dart';
import '../../../state/game_scope.dart';
import '../../theme/bir_omur_theme.dart';
import '../../widgets/kilim_divider.dart';
import '../../widgets/section_scaffold.dart';

/// Evlilik Geçmişi sayfası (D-133).
///
/// İkinci evlilik D-036'da geldi ve eski kayıt `pastMarriages` içinde
/// saklanıyordu ama **hiçbir ekranda görünmüyordu**. Bu ekran onu
/// gösterir: kiminle, kaç yaşında, nasıl bitti.
class MarriageHistoryPage extends StatelessWidget {
  const MarriageHistoryPage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final GameState state = GameScope.of(context).state!;
    final Marriage? suren = state.marriage;
    final List<Marriage> gecmis = state.pastMarriages;

    return SectionScaffold(
      icon: Icons.favorite_rounded,
      accent: BirOmurAccents.gul,
      title: 'Evlilik Geçmişi',
      subtitle: state.marriageCount == 0
          ? null
          : 'Kayıt silinmez: biten evlilik de burada durur.',
      backLabel: 'İlişkiler',
      onBack: onBack,
      children: <Widget>[
        if (suren == null && gecmis.isEmpty)
          const InfoPanel(
            key: Key('evlilik_yok'),
            icon: Icons.favorite_outline,
            text: 'Henüz evlenmedin.',
          ),
        if (suren != null) ...<Widget>[
          const MenuGroupTitle(
            text: 'Süren evlilik',
            accent: BirOmurAccents.gul,
          ),
          const SizedBox(height: 8),
          _EvlilikKarti(
            marriage: suren,
            spouse: state.personById(suren.spouseId),
            playerAge: state.player.age,
          ),
        ],
        if (gecmis.isNotEmpty) ...<Widget>[
          const SizedBox(height: 16),
          const MenuGroupTitle(
            text: 'Geçmiş evlilikler',
            accent: BirOmurAccents.mor,
          ),
          const SizedBox(height: 8),
          for (final Marriage m in gecmis) ...<Widget>[
            _EvlilikKarti(
              marriage: m,
              spouse: state.personById(m.spouseId),
              playerAge: state.player.age,
            ),
            const SizedBox(height: 10),
          ],
        ],
      ],
    );
  }
}

class _EvlilikKarti extends StatelessWidget {
  const _EvlilikKarti({
    required this.marriage,
    required this.spouse,
    required this.playerAge,
  });

  final Marriage marriage;
  final Person? spouse;
  final int playerAge;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int bitis = marriage.endedAtAge ?? playerAge;
    final int sure = (bitis - marriage.marriedAtAge).clamp(0, 120);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.45,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  // Kişi kaydı silinmediği için ad gerçek kayıttan okunur;
                  // bulunamazsa uydurulmaz.
                  spouse?.fullName ?? 'Kaydı okunamayan eş',
                  style: theme.textTheme.titleSmall,
                ),
              ),
              Text(
                marriage.status.label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const KilimDivider(),
          const SizedBox(height: 8),
          _satir(theme, 'Evlilik', '${marriage.marriedAtAge} yaşında'),
          if (marriage.endedAtAge != null)
            _satir(theme, 'Bitiş', '${marriage.endedAtAge} yaşında'),
          _satir(
            theme,
            'Süre',
            marriage.endedAtAge == null ? '$sure yıl (sürüyor)' : '$sure yıl',
          ),
          if (spouse != null && !spouse!.isAlive)
            _satir(theme, 'Durum', 'Vefat etti'),
        ],
      ),
    );
  }

  Widget _satir(ThemeData theme, String baslik, String deger) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 72,
              child: Text(
                baslik,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: Text(deger, style: theme.textTheme.bodySmall),
            ),
          ],
        ),
      );
}
