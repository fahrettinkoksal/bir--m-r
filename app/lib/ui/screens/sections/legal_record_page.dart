import 'package:flutter/material.dart';

import '../../../data/crime_catalog.dart';
import '../../../domain/models/criminal_record.dart';
import '../../../domain/models/game_state.dart';
import '../../../state/game_scope.dart';
import '../../../text/turkish_text.dart';
import '../../theme/bir_omur_theme.dart';
import '../../widgets/kilim_divider.dart';
import '../../widgets/section_scaffold.dart';

/// Adli Geçmiş sayfası (D-128).
///
/// Okul/Meslek bölümünün altındadır, çünkü sabıkanın oyundaki en somut
/// etkisi **iş başvurusudur** ve askerlik gibi devletle ilişkili diğer
/// durum da orada duruyor.
///
/// Ekran **yargılamaz**: ahlaki puan vermez, yalnızca olanı yazar.
/// Sayfa hiç kayıt yoksa da açılabilir ve tek satırla "temiz" der.
class LegalRecordPage extends StatelessWidget {
  const LegalRecordPage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final GameState state = GameScope.of(context).state!;
    final LegalState hukuk = state.legal;

    // Görünürde tutulacak dosyalar: trafik cezası gibi idari işlemler de
    // burada durur ama sabıka sayılmaz; ayrım ekranda yazılır.
    final List<CriminalCase> sabika = hukuk.record;
    final List<CriminalCase> diger = hukuk.cases
        .where((CriminalCase c) => !c.leavesRecord)
        .toList(growable: false);

    return SectionScaffold(
      icon: Icons.gavel_rounded,
      accent: BirOmurAccents.nar,
      title: 'Adli Geçmiş',
      subtitle: hukuk.cases.isEmpty
          ? null
          : 'Kayıt silinmez; kapanan dosya da burada durur.',
      backLabel: 'Okul / Meslek',
      onBack: onBack,
      children: <Widget>[
        // Durum satırı.
        if (hukuk.isImprisoned)
          InfoPanel(
            key: const Key('adli_hapis'),
            icon: Icons.lock_outline,
            text: 'Şu an cezaevindesin. Tahliye yaşın: '
                '${hukuk.releaseAtAge}.',
          )
        else if (hukuk.openCase != null)
          InfoPanel(
            key: const Key('adli_acik_dosya'),
            icon: Icons.hourglass_bottom_rounded,
            text: 'Süren bir dosyan var: '
                '${hukuk.openCase!.crime?.label ?? 'dosya'} · '
                '${hukuk.openCase!.stage.label}.',
          )
        else if (hukuk.probationUntilAge != null &&
            state.player.age < hukuk.probationUntilAge!)
          InfoPanel(
            key: const Key('adli_denetim'),
            icon: Icons.schedule_rounded,
            text: 'Denetim dönemindesin; '
                '${hukuk.probationUntilAge} yaşına kadar sürüyor.',
          )
        else if (!hukuk.hasRecord)
          const InfoPanel(
            key: Key('adli_temiz'),
            icon: Icons.verified_outlined,
            text: 'Adli kaydın temiz.',
          ),

        if (sabika.isNotEmpty) ...<Widget>[
          const SizedBox(height: 16),
          const MenuGroupTitle(
            text: 'Sabıka kaydı',
            accent: BirOmurAccents.nar,
          ),
          const SizedBox(height: 8),
          for (final CriminalCase dosya in sabika) ...<Widget>[
            _CaseCard(dosya: dosya, playerAge: state.player.age),
            const SizedBox(height: 10),
          ],
        ],

        if (diger.isNotEmpty) ...<Widget>[
          const SizedBox(height: 16),
          const MenuGroupTitle(
            text: 'Sabıkaya girmeyen kayıtlar',
            accent: BirOmurAccents.pirinc,
          ),
          const SizedBox(height: 4),
          Text(
            'İdari cezalar, takipsizlikle kapanan dosyalar ve beraatler. '
            'Bunlar iş başvurusunu etkilemez.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          for (final CriminalCase dosya in diger) ...<Widget>[
            _CaseCard(dosya: dosya, playerAge: state.player.age),
            const SizedBox(height: 10),
          ],
        ],
      ],
    );
  }
}

class _CaseCard extends StatelessWidget {
  const _CaseCard({required this.dosya, required this.playerAge});

  final CriminalCase dosya;
  final int playerAge;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final CrimeType? suc = dosya.crime;
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
                  suc?.recordLabel ?? dosya.crimeId,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              Text(
                '${dosya.ageAtIncident} yaş',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const KilimDivider(),
          const SizedBox(height: 8),
          _satir(theme, 'Tür', suc?.category.label ?? '—'),
          _satir(theme, 'Aşama', dosya.stage.label),
          if (dosya.verdict != Verdict.yok)
            _satir(theme, 'Sonuç', dosya.verdict.label),
          if (dosya.fine > 0)
            _satir(
              theme,
              'Ceza',
              dosya.finePaid
                  ? '${trMoney(dosya.fine)} (ödendi)'
                  : trMoney(dosya.fine),
            ),
          if (dosya.prisonYears > 0)
            _satir(theme, 'Hapis', '${dosya.prisonYears} yıl'),
          if (dosya.lawyer != null)
            _satir(theme, 'Avukat', dosya.lawyer!.label),
          _satir(
            theme,
            'Durum',
            dosya.isFinished
                ? 'Tamamlandı${dosya.closedAtAge == null ? '' : ' (${dosya.closedAtAge} yaş)'}'
                : 'Sürüyor',
          ),
          if (dosya.note != null) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              dosya.note!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _satir(ThemeData theme, String baslik, String deger) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 76,
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
