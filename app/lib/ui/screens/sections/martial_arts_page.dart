import 'package:flutter/material.dart';

import '../../../data/combat_circuit_catalog.dart';
import '../../../data/martial_arts_catalog.dart';
import '../../../domain/activities/activity_engine.dart';
import '../../../domain/combat/combat_career_engine.dart';
import '../../../domain/combat/sport_family_support.dart';
import '../../../domain/combat/sport_rivalry.dart';
import '../../../domain/models/combat_career.dart';
import '../../../domain/models/interaction.dart';
import '../../../domain/models/martial_progress.dart';
import '../../../domain/models/person.dart';
import '../../../state/game_controller.dart';
import '../../../state/game_scope.dart';
import '../../../text/turkish_text.dart';
import '../../theme/bir_omur_theme.dart';
import '../../widgets/section_scaffold.dart';
import 'activity_pages.dart';

/// Spor salonunun dövüş sanatları bölümü (Paket 32).
///
/// Üç dal: karate, kung fu ve yağlı güreş. Her dalın kendi **gerçek**
/// basamak düzeni vardır; ders ucuz, ilerleme yavaştır.
class MartialArtsPage extends StatefulWidget {
  const MartialArtsPage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<MartialArtsPage> createState() => _MartialArtsPageState();
}

class _MartialArtsPageState extends State<MartialArtsPage> {
  ActivityOutcome? _sonuc;
  MartialArt? _acik;

  @override
  Widget build(BuildContext context) {
    final GameController controller = GameScope.of(context);

    return SectionScaffold(
      icon: Icons.sports_martial_arts_rounded,
      accent: BirOmurAccents.nar,
      title: 'Dövüş sanatları',
      subtitle:
          'Ders ucuz, ustalık pahalı: kuşak yılla gelir. '
          'Cüzdanında ${controller.state!.player.walletLabel} var.',
      backLabel: 'Spor salonu',
      onBack: widget.onBack,
      children: <Widget>[
        // Rekabet kariyeri en üstte durur: sporcu önce kendi durumunu
        // görsün, sonra ders listesini (Paket AL, §26).
        if (controller.activeCombatCareer() != null) ...<Widget>[
          _CombatPanel(
            career: controller.activeCombatCareer()!,
            onResult: (String metin) => setState(
              () => _sonuc = ActivityOutcome(applied: true, text: metin),
            ),
          ),
          const SizedBox(height: 12),
        ],
        for (final MartialArt art in MartialArt.values) ...<Widget>[
          _ArtCard(
            art: art,
            progress: controller.martialProgress(art),
            availability: controller.martialAvailability(art),
            competeAvailability: controller.combatStartAvailability(art),
            healthGate: controller.combatHealthGate(),
            competing: controller.combatCareer(art) != null,
            onCompete: () {
              final ActivityOutcome? outcome = controller.startCompeting(art);
              setState(() => _sonuc = outcome);
            },
            lessonsThisAge: controller.martialLessonsThisAge(art),
            expanded: _acik == art,
            onToggle: () => setState(() => _acik = _acik == art ? null : art),
            seasonLessons: controller.martialSeasonLessons(art),
            onLesson: () {
              final ActivityOutcome? outcome = controller.takeMartialLesson(
                art,
              );
              setState(() => _sonuc = outcome);
            },
            onSeason: () {
              final ActivityOutcome? outcome = controller.takeMartialSeason(
                art,
              );
              setState(() => _sonuc = outcome);
            },
          ),
          const SizedBox(height: 10),
        ],
        if (_sonuc != null) ...<Widget>[
          const SizedBox(height: 4),
          OutcomeCard(outcome: _sonuc!),
        ],
      ],
    );
  }
}

class _ArtCard extends StatelessWidget {
  const _ArtCard({
    required this.art,
    required this.progress,
    required this.availability,
    required this.competeAvailability,
    required this.healthGate,
    required this.onCompete,
    required this.competing,
    required this.lessonsThisAge,
    required this.expanded,
    required this.onToggle,
    required this.onLesson,
    required this.seasonLessons,
    required this.onSeason,
  });

  final MartialArt art;
  final MartialProgress progress;
  final InteractionAvailability availability;

  /// Rekabete başlama durumu (Paket AL, §3).
  final InteractionAvailability competeAvailability;

  /// "73 / 80" biçiminde sağlık kapısı (Paket AM, §18).
  final String healthGate;
  final VoidCallback onCompete;
  final bool competing;
  final int lessonsThisAge;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onLesson;

  /// Bu yıl tek seferde alınabilecek ders sayısı (0 ise düğme çıkmaz).
  final int seasonLessons;
  final VoidCallback onSeason;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool acik = availability.isAllowed;
    final int? kalan = progress.lessonsToNextRank;

    return Container(
      decoration: panelDecoration(context, radius: 20),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                AccentIconTile(
                  icon: art.icon,
                  accent: BirOmurAccents.nar,
                  size: 38,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(art.label, style: theme.textTheme.titleMedium),
                      Text(
                        progress.lessons == 0
                            ? 'Henüz başlamadın'
                            : progress.rankName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  trMoney(art.lessonCost),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              art.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress.ratio,
                minHeight: 8,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              progress.isTopRank
                  ? 'En üst basamak: ${progress.rankName}'
                  : 'Sonraki basamak: ${art.ranks[progress.level + 1].name}'
                        '${kalan == null ? '' : ' — $kalan ders kaldı'}',
              style: theme.textTheme.bodySmall,
            ),
            Text(
              'Bu yıl $lessonsThisAge/$kMaxMartialLessonsPerAge ders · '
              'toplam ${progress.lessons} ders',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (progress.canTeach) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                'Bu basamakta eğitmenlik işine başvurabilirsin.',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            if (!competing &&
                !competeAvailability.isAllowed &&
                progress.lessons > 0 &&
                (competeAvailability.reason ?? '').isNotEmpty) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                'Müsabaka: ${competeAvailability.reason!}',
                key: Key('dovus_rekabet_gerekce_${art.id}'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            // §18: rekabetçi kariyer kapısının sağlık durumu açıkça
            // gösterilir — oyuncu eksiğinin ne kadar olduğunu görsün.
            // Ders alan ama henüz rekabet etmeyen sporcuda görünür.
            if (!competing && progress.lessons > 0) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                'Rekabetçi kariyer için sağlık: $healthGate',
                key: Key('dovus_saglik_kapisi_${art.id}'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: competeAvailability.isAllowed
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (!acik && (availability.reason ?? '').isNotEmpty) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                availability.reason!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 10),
            // Dar ekranda düğmeler alt alta iner; sebep metni yukarıda
            // ayrı satırda durur, böylece taşma olmaz.
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 6,
              runSpacing: 6,
              children: <Widget>[
                TextButton(
                  onPressed: onToggle,
                  child: Text(expanded ? 'Gizle' : 'Basamaklar'),
                ),
                FilledButton.tonal(
                  key: Key('dovus_ders_${art.id}'),
                  onPressed: acik ? onLesson : null,
                  child: Text(acik ? 'Ders al' : 'Şu an kapalı'),
                ),
                // Basamaklar yüzlerce ders istiyor; tek tek tıklamak
                // yerine yılın kalanı bir hamlede çalışılabilir. Kural
                // aynı: yıllık sınır, ücret ve eşikler değişmiyor.
                if (acik && seasonLessons > 1)
                  FilledButton(
                    key: Key('dovus_yil_${art.id}'),
                    onPressed: onSeason,
                    child: Text('Yılı çalış ($seasonLessons ders)'),
                  ),
                // Rekabete geçiş: teknik basamak tuttuğunda açılır.
                // Kapalıyken gerekçesi yukarıda yazar; sahte düğme yok.
                if (!competing && competeAvailability.isAllowed)
                  FilledButton(
                    key: Key('dovus_rekabet_${art.id}'),
                    onPressed: onCompete,
                    child: const Text('Müsabakalara başla'),
                  ),
              ],
            ),
            if (expanded) ...<Widget>[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 8),
              for (int i = 0; i < art.ranks.length; i++)
                _RankLine(
                  art: art,
                  index: i,
                  current: progress.level,
                  reached: progress.lessons >= art.ranks[i].lessonsNeeded,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RankLine extends StatelessWidget {
  const _RankLine({
    required this.art,
    required this.index,
    required this.current,
    required this.reached,
  });

  final MartialArt art;
  final int index;
  final int current;
  final bool reached;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MartialRank rank = art.ranks[index];
    final bool simdiki = index == current;
    final bool egitmenlik = index == art.instructorFromLevel;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            reached
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 16,
            color: reached
                ? BirOmurAccents.yesil.color
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  rank.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: simdiki ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
                Text(
                  egitmenlik
                      ? '${rank.note} (eğitmenlik burada açılır)'
                      : rank.note,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${rank.lessonsNeeded} ders',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Rekabet kariyeri paneli (Paket AL, §26).
///
/// Mevcut dövüş sanatı ekranı çöpe atılmadı, derinleştirildi: teknik
/// basamak yukarıda kartlarda duruyor, burada sporcunun **kariyeri**
/// var — form, rekor, sıradaki fırsat ve kararlar.
class _CombatPanel extends StatefulWidget {
  const _CombatPanel({required this.career, required this.onResult});

  final CombatCareer career;
  final void Function(String) onResult;

  @override
  State<_CombatPanel> createState() => _CombatPanelState();
}

class _CombatPanelState extends State<_CombatPanel> {
  bool _gecmisAcik = false;

  String _formLabel(int form) {
    if (form >= 80) return 'Çok iyi';
    if (form >= 62) return 'İyi';
    if (form >= 42) return 'Orta';
    if (form >= 25) return 'Düşük';
    return 'Çok düşük';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final GameController controller = GameScope.of(context);
    final CombatCareer k = widget.career;
    final MartialArt? art = k.art;
    final CombatCircuit? yol = combatCircuitFor(k.artId);
    if (art == null || yol == null) return const SizedBox.shrink();

    final CombatTier kademe = yol.tiers[k.tier.clamp(0, yol.tiers.length - 1)];
    final PendingBout? bekleyen = k.pendingBout;
    final bool catisma = controller.hasSchoolSportConflict();
    final bool saglikYeterli = controller.combatHealthAllowsBout();
    // §29: yüzde göstermeden, işin hazırlığa etkisini anlatan satır.
    final String? isNotu = controller.sportWorkloadNote();
    // §26: yalnızca 18 yaş altında ve yaşayan ebeveyn varsa dolu döner.
    final List<Person> destekciler = controller.sportSupportSponsors();

    return Container(
      key: const Key('spor_kariyeri_paneli'),
      decoration: panelDecoration(context, radius: 20),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                AccentIconTile(
                  icon: art.icon,
                  accent: BirOmurAccents.nar,
                  size: 38,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(art.label, style: theme.textTheme.titleMedium),
                      Text(
                        k.isRetired
                            ? 'Emekli — ${k.retirementReason?.label ?? ''}'
                            : k.status == CompetitiveStatus.profesyonel
                                ? yol.proLabel
                                : k.status.label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (k.isChampion)
                  Icon(
                    Icons.emoji_events_rounded,
                    color: theme.colorScheme.primary,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            _SatirCift(sol: 'Kademe', sag: kademe.label),
            _SatirCift(sol: 'Form', sag: _formLabel(k.form)),
            _SatirCift(
              sol: 'Rekor',
              sag: k.record +
                  (k.championships > 0
                      ? ' · ${k.championships} şampiyonluk'
                      : ''),
            ),
            if (k.ranking > 0)
              _SatirCift(sol: 'Sıralama', sag: '${k.ranking}.'),
            if (k.careerEarnings > 0)
              _SatirCift(
                sol: 'Kariyer geliri',
                sag: trMoney(k.careerEarnings),
              ),
            _SatirCift(
              sol: 'Antrenör',
              sag: CombatCareerEngine.coachLabels[k.coachLevel.clamp(0, 2)],
            ),

            // --- rekabet (§28) ---------------------------------------
            // Her rakip yığılmaz: yalnızca gerçekten anlamlı olanlar.
            for (final RivalStanding r in controller.sportRivals(k))
              _SatirCift(
                sol: r.label!,
                sag: '${r.opponent.name} · '
                    '${r.opponent.metCount} karşılaşma · '
                    'Sen ${r.opponent.playerWins} — '
                    'O ${r.opponent.playerLosses}',
              ),
            if (k.isInjured)
              _SatirCift(
                sol: 'Sakatlık',
                sag: '${k.injury.label} · ${k.injuryYearsLeft} yıl',
              ),
            // §5, §18: geçici sağlık engeli. Kariyer durur, silinmez;
            // satır bunu açıkça söyler.
            if (!k.isRetired && !k.isInjured && !saglikYeterli)
              _SatirCift(
                sol: 'Sağlık',
                sag: 'Müsabakaya çıkacak durumda değil '
                    '(${controller.combatHealthGate()})',
              ),

            // --- sıradaki fırsat -------------------------------------
            if (!k.isRetired && bekleyen != null) ...<Widget>[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Text(
                bekleyen.isTitle
                    ? '${yol.titleLabel}: ${bekleyen.opponent.name}'
                    : 'Sıradaki müsabaka: ${bekleyen.opponent.name}',
                key: const Key('spor_bekleyen_musabaka'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (bekleyen.opponent.headToHead != null)
                Text(
                  bekleyen.opponent.headToHead!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: 8),

              // --- okul + spor çatışması (Paket AL/2, §27) -----------
              // Karar verilmeden müsabakaya çıkılmaz: seçim gerçek.
              if (catisma) ...<Widget>[
                Text(
                  'Turnuva okulunla çakıştı. Önce buna karar ver.',
                  key: const Key('spor_okul_catismasi'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: <Widget>[
                    OutlinedButton(
                      key: const Key('spor_okul_turnuvaya_git'),
                      onPressed: () {
                        final ActivityOutcome? o = controller
                            .resolveSchoolSportConflict(chooseSport: true);
                        if (o != null) widget.onResult(o.text);
                      },
                      child: const Text('Turnuvaya git'),
                    ),
                    OutlinedButton(
                      key: const Key('spor_okul_oncelik'),
                      onPressed: () {
                        final ActivityOutcome? o = controller
                            .resolveSchoolSportConflict(chooseSport: false);
                        if (o != null) widget.onResult(o.text);
                      },
                      child: const Text('Okula öncelik ver'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // §10: birkaç anlamlı seçenek, yirmi mikro düğme değil.
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: <Widget>[
                  for (final CampChoice c in CampChoice.values)
                    OutlinedButton(
                      key: Key('spor_kamp_${c.name}'),
                      onPressed: k.isInjured || catisma || !saglikYeterli
                          ? null
                          : () {
                              final ({bool applied, String text, bool won})? r =
                                  controller.fightBout(c);
                              if (r != null) widget.onResult(r.text);
                            },
                      child: Text(
                        '${c.label} '
                        '(${trMoney(CombatCareerEngine.campCost(c))})',
                      ),
                    ),
                ],
              ),
            ] else if (!k.isRetired) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                k.isInjured
                    ? 'Sakatlığın geçmeden fırsat çıkmıyor.'
                    : 'Şu an önünde bir müsabaka yok. Fırsat her yıl '
                        'çıkmaz; çalışmaya devam et.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],

            // --- iş + spor (Paket AL/2, §29) --------------------------
            // Yüzde yok: oyuncuya matematik değil durum anlatılıyor.
            if (!k.isRetired && isNotu != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                isNotu,
                key: const Key('spor_is_yuku_notu'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],

            // --- aile desteği (Paket AL/2, §26) -----------------------
            // Yalnızca 18 yaş altında ve **yaşayan** ebeveyn varken
            // görünür; ebeveyn yoksa sahte seçenek gösterilmez.
            if (!k.isRetired && destekciler.isNotEmpty) ...<Widget>[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Text(
                'Bu masrafları tek başına karşılaman gerekmiyor.',
                key: const Key('spor_aile_destegi'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              for (final SportExpense gider in SportExpense.values)
                if (controller.sportExpenseCost(gider) > 0 &&
                    controller.sportSupportCredit(gider) <
                        controller.sportExpenseCost(gider)) ...<Widget>[
                  const SizedBox(height: 6),
                  Text(
                    '${gider.label} · '
                    '${trMoney(controller.sportExpenseCost(gider))}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: <Widget>[
                      for (final Person ebeveyn in destekciler)
                        Builder(
                          builder: (BuildContext context) {
                            final String engel = controller
                                .sportSupportBlockReason(gider, ebeveyn);
                            return OutlinedButton(
                              key: Key(
                                'spor_destek_${gider.name}_${ebeveyn.id}',
                              ),
                              onPressed: engel.isNotEmpty
                                  ? null
                                  : () {
                                      final ActivityOutcome? o = controller
                                          .askSportSupport(gider, ebeveyn);
                                      if (o != null) widget.onResult(o.text);
                                    },
                              child: Text(
                                '${ebeveyn.firstName} ile konuş',
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ],
            ],

            // --- kararlar --------------------------------------------
            if (!k.isRetired) ...<Widget>[
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 6,
                runSpacing: 6,
                children: <Widget>[
                  if (k.memories.isNotEmpty)
                    TextButton(
                      onPressed: () =>
                          setState(() => _gecmisAcik = !_gecmisAcik),
                      child: Text(_gecmisAcik ? 'Gizle' : 'Kariyeri gör'),
                    ),
                  if (k.isInjured)
                    OutlinedButton(
                      key: const Key('spor_riski_goze_al'),
                      onPressed: () {
                        final ActivityOutcome? o =
                            controller.pushThroughCombatInjury();
                        if (o != null) widget.onResult(o.text);
                      },
                      child: const Text('Riski göze al'),
                    ),
                  if (k.coachLevel < 2)
                    OutlinedButton(
                      key: const Key('spor_koc_yukselt'),
                      onPressed: () {
                        final ActivityOutcome? o =
                            controller.setCombatCoach(k.coachLevel + 1);
                        if (o != null) widget.onResult(o.text);
                      },
                      child: Text(
                        '${CombatCareerEngine.coachLabels[k.coachLevel + 1]}'
                        ' tut',
                      ),
                    ),
                  OutlinedButton(
                    key: const Key('spor_emekli_ol'),
                    onPressed: () {
                      final ActivityOutcome? o = controller.retireFromCombat();
                      if (o != null) widget.onResult(o.text);
                    },
                    child: const Text('Spordan çekil'),
                  ),
                ],
              ),
            ],

            // --- kariyer geçmişi (§27) --------------------------------
            if (_gecmisAcik && k.memories.isNotEmpty) ...<Widget>[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 8),
              for (final CombatMemory m in k.memories.reversed.take(10))
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${m.age} yaşında — ${m.text}',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SatirCift extends StatelessWidget {
  const _SatirCift({required this.sol, required this.sag});

  final String sol;
  final String sag;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 116,
            child: Text(
              sol,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              sag,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
