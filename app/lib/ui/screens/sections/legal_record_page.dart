import 'package:flutter/material.dart';

import '../../../data/crime_catalog.dart';
import '../../../domain/models/criminal_record.dart';
import '../../../domain/models/game_state.dart';
import '../../../domain/models/person.dart';
import '../../../state/game_controller.dart';
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
        if (hukuk.isSentenced)
          InfoPanel(
            key: const Key('adli_hapis'),
            icon: Icons.lock_outline,
            text: 'Şu an cezaevindesin. Tahliye yaşın: '
                '${hukuk.releaseAtAge}.'
                '${hukuk.goodBehaviour > 0 ? ' İyi hâl: '
                    '${hukuk.goodBehaviour}/100.' : ''}',
          )
        // Tutukluluk hükümlülükten ayrıdır (D-139): dosya sürüyor, ceza
        // verilmedi. Kefalet bu durumu kaldırır.
        else if (hukuk.isDetained)
          InfoPanel(
            key: const Key('adli_tutuklu'),
            icon: Icons.lock_clock_outlined,
            text: 'Tutuklusun; dosyan hâlâ sürüyor, ceza verilmedi. '
                'Kefalet yatırılırsa yargılama dışarıda devam eder.',
          )
        else if (hukuk.bailPaid)
          InfoPanel(
            key: const Key('adli_kefaletli'),
            icon: Icons.how_to_reg_outlined,
            text: 'Kefaletle dışarıdasın. Duruşmaya çıkınca kefalet '
                'geri verilir.',
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

        // Kefalet kartı yalnızca tutukluyken görünür (D-139).
        if (hukuk.isDetained) ...<Widget>[
          const SizedBox(height: 12),
          _BailCard(bail: hukuk.bailAmount ?? 0),
        ],

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

/// Tutukluyken görünen kefalet kartı (D-139).
///
/// İki kapı var: kefaleti kendin yatırmak ya da aileden istemek. İkisi de
/// **garantili değildir**: paran yetmiyorsa düğme kapanır ve gerekçesi
/// yazar (D-063); aileden istemek reddedilebilir.
class _BailCard extends StatelessWidget {
  const _BailCard({required this.bail});

  final int bail;

  Future<void> _askFamily(BuildContext context) async {
    final GameController controller = GameScope.of(context);
    final List<Person> yakinlar = controller.bailHelpers();
    if (yakinlar.isEmpty) return;

    final int oyuncuYasi = controller.state?.player.age ?? 0;
    final Person? secim = await showModalBottomSheet<Person>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Kefaleti kimden isteyeceksin?',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final Person kisi in yakinlar)
              ListTile(
                key: Key('kefalet_iste_${kisi.id}'),
                leading: const Icon(Icons.person_outline),
                title: Text(kisi.firstName),
                subtitle: Text(
                  <String>[
                    kisi.labelFor(oyuncuYasi),
                    if (kisi.wealth != null) kisi.wealth!.label,
                  ].join(' · '),
                ),
                onTap: () => Navigator.of(context).pop(kisi),
              ),
          ],
        ),
      ),
    );
    if (secim == null || !context.mounted) return;
    controller.askFamilyForBail(secim.id);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final GameController controller = GameScope.of(context);
    final String engel = controller.selfBailBlockReason();
    final bool kendiOdeyebilir = engel.isEmpty;
    final List<Person> yakinlar = controller.bailHelpers();

    return Container(
      decoration: panelDecoration(context, radius: 20),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const AccentIconTile(
                icon: Icons.account_balance_wallet_outlined,
                accent: BirOmurAccents.nar,
                size: 38,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Kefalet', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      trMoney(bail),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Kefalet teminattır: tutukluluğu kaldırır, cezayı satın '
            'almaz. Duruşmaya çıkınca geri verilir.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              key: const Key('kefalet_kendim'),
              onPressed:
                  kendiOdeyebilir ? () => controller.payBailSelf() : null,
              child: Text(
                kendiOdeyebilir
                    ? 'Kefaleti kendim yatırayım'
                    : 'Kendi paranla yatıramıyorsun',
              ),
            ),
          ),
          if (!kendiOdeyebilir) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              engel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              key: const Key('kefalet_aileden'),
              onPressed:
                  yakinlar.isEmpty ? null : () => _askFamily(context),
              child: Text(
                yakinlar.isEmpty
                    ? 'İsteyebileceğin kimse yok'
                    : 'Aileden kefaleti ödemesini isteyeyim',
              ),
            ),
          ),
        ],
      ),
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
