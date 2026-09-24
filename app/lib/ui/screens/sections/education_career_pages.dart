import 'package:flutter/material.dart';

import '../../../data/job_catalog.dart';
import '../../../data/university_catalog.dart';
import '../../../domain/career/job_market.dart';
import '../../../domain/education/education_path.dart';
import '../../../domain/models/career.dart';
import '../../../domain/models/game_state.dart';
import '../../../state/game_controller.dart';
import '../../../state/game_scope.dart';
import '../../widgets/interview_sheet.dart';
import '../../theme/bir_omur_theme.dart';
import '../../widgets/section_scaffold.dart';
import '../../../text/turkish_text.dart';

/// Lise sonrası yol seçimi ve üniversite başvurusu.
class AfterSchoolPage extends StatefulWidget {
  const AfterSchoolPage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<AfterSchoolPage> createState() => _AfterSchoolPageState();
}

class _AfterSchoolPageState extends State<AfterSchoolPage> {
  String? _sonuc;

  @override
  void initState() {
    super.initState();
    // Eski kayıtlarda ve yeni mezunlarda puan eksik olabilir; ekran
    // açılmadan önce bir kez hesaplanır.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) GameScope.of(context).ensureUniversityExamScore();
    });
  }

  @override
  Widget build(BuildContext context) {
    final GameController controller = GameScope.of(context);
    final GameState state = controller.state!;
    final List<UniversityProgram> bolumler = controller.availablePrograms();
    final int? sinavPuani = controller.universityExamScore;

    return SectionScaffold(
      icon: Icons.school_rounded,
      title: 'Mezuniyet sonrası',
      subtitle: state.education.trackInfo == null
          ? 'Lise bitti.'
          : 'Lise alanın: ${state.education.trackInfo!.label}',
      backLabel: 'Meslek',
      onBack: widget.onBack,
      children: <Widget>[
        // Oyuncunun kendi puanı en üstte, açıkça.
        _ScoreCard(
          examScore: sinavPuani,
          placementScore: state.education.placementScore,
          trackLabel: state.education.trackInfo?.label,
        ),
        const SizedBox(height: 12),
        const InfoPanel(
          icon: Icons.alt_route_outlined,
          text: 'Herkes üniversiteye gitmek zorunda değil. İster bir bölüme '
              'başvur, ister doğrudan iş hayatına gir.',
        ),
        const SizedBox(height: 12),
        if (bolumler.isNotEmpty) ...<Widget>[
          Text(
            'Üniversite başvurusu',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          for (final UniversityProgram bolum in bolumler) ...<Widget>[
            _ProgramCard(
              program: bolum,
              myScore: controller.programScore(bolum),
              trackBonus: controller.programTrackBonus(bolum),
              blockReason: controller.programBlockReason(bolum),
              onApply: () {
                final String? metin =
                    controller.applyToUniversity(bolum)?.text;
                setState(() => _sonuc = metin);
              },
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 4),
          OutlinedButton(
            onPressed: () {
              final String? metin = controller.skipUniversity()?.text;
              setState(() => _sonuc = metin);
            },
            child: const Text('Üniversiteye gitmeyeceğim, iş arayacağım'),
          ),
        ] else
          const InfoPanel(
            icon: Icons.info_outline,
            text: 'Üniversite başvurusu için uygun bir durum yok. '
                'İş aramaya Meslek bölümünden devam edebilirsin.',
          ),
        if (_sonuc != null) ...<Widget>[
          const SizedBox(height: 12),
          InfoPanel(icon: Icons.campaign_outlined, text: _sonuc!),
        ],
      ],
    );
  }
}

/// Oyuncunun kendi puanlarını gösteren kart.
///
/// Lise yerleştirme puanı ile üniversite sınav puanı **ayrı** adlarla
/// sunulur; ikisi farklı değerlerdir.
class _ScoreCard extends StatelessWidget {
  const _ScoreCard({
    required this.examScore,
    required this.placementScore,
    required this.trackLabel,
  });

  final int? examScore;
  final int? placementScore;
  final String? trackLabel;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.assignment_turned_in_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Text('Puanların', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              examScore == null
                  ? 'Üniversite sınav puanın hesaplanıyor…'
                  : 'Üniversite sınav puanın: $examScore',
              key: const Key('university_exam_score'),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            if (placementScore != null)
              Text(
                'Lise yerleştirme puanın: $placementScore '
                '(8. sınıf sonunda alınmıştı)',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            if (trackLabel != null) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                'Lise alanın: $trackLabel',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Başvuruda kullanılan puan, sınav puanına bölümün tercih '
              'ettiği alandan gelen ek puanın eklenmesiyle bulunur. '
              'Üniversite not ortalaması sistemi henüz yok.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgramCard extends StatelessWidget {
  const _ProgramCard({
    required this.program,
    required this.myScore,
    required this.trackBonus,
    required this.blockReason,
    required this.onApply,
  });

  final UniversityProgram program;

  /// Oyuncunun bu bölüm için geçerli puanı (alan uyumu dahil).
  final int myScore;
  final int trackBonus;

  /// Başvuru mümkün değilse gerekçe; uygunsa boş.
  final String blockReason;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool yeterli = myScore >= program.minScore;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(program.name, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              program.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            // Karşılaştırma açıkça yazılır.
            Text(
              'Senin puanın: $myScore  /  Taban puan: ${program.minScore}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: yeterli
                    ? theme.colorScheme.secondary
                    : theme.colorScheme.error,
              ),
            ),
            if (trackBonus > 0) ...<Widget>[
              const SizedBox(height: 2),
              Text(
                'Lise alanın bu bölümle uyumlu: +$trackBonus puan dahil',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    blockReason.isEmpty
                        ? '${program.durationYears} yıl'
                        : blockReason,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                FilledButton.tonal(
                  onPressed: blockReason.isEmpty ? onApply : null,
                  child: Text(blockReason.isEmpty ? 'Başvur' : 'Uygun değil'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// İş arama sayfası.
class JobSearchPage extends StatefulWidget {
  const JobSearchPage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<JobSearchPage> createState() => _JobSearchPageState();
}

class _JobSearchPageState extends State<JobSearchPage> {
  String? _sonuc;

  @override
  Widget build(BuildContext context) {
    final GameController controller = GameScope.of(context);
    final GameState state = controller.state!;
    final List<JobType> acik = controller.openJobs();
    final Map<JobType, String> kapali = controller.lockedJobs();

    return SectionScaffold(
      icon: Icons.person_search_rounded,
      title: 'İş ara',
      subtitle: state.career.isEmployed
          ? 'Şu an ${state.career.label} olarak çalışıyorsun.'
          : 'Koşullarını sağladığın işlere başvurabilirsin.',
      backLabel: 'Meslek',
      onBack: widget.onBack,
      children: <Widget>[
        if (acik.isEmpty)
          const InfoPanel(
            icon: Icons.work_off_outlined,
            text: 'Şu an koşullarını sağladığın bir iş yok. Eğitimini '
                'ilerletmek veya yaşının büyümesi seçenekleri açabilir.',
          ),
        for (final JobType job in acik) ...<Widget>[
          _JobCard(
            job: job,
            availability: controller.jobApplicationAvailability(job),
            onApply: () async {
              final JobOutcome? outcome = controller.applyForJob(job);
              if (outcome == null) return;
              if (outcome.interviewStarted && context.mounted) {
                // Başvuru doğrudan sonuçlanmaz: önce mülakat.
                await InterviewSheet.show(context);
                if (!context.mounted) return;
                setState(() => _sonuc = null);
                return;
              }
              setState(() => _sonuc = outcome.text);
            },
          ),
          const SizedBox(height: 10),
        ],
        if (_sonuc != null) ...<Widget>[
          const SizedBox(height: 4),
          InfoPanel(icon: Icons.mark_email_read_outlined, text: _sonuc!),
          const SizedBox(height: 8),
        ],
        if (kapali.isNotEmpty) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            'Şimdilik açık olmayan işler',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          // Koşulu belli olan işler gerekçesiyle listelenir; düğme konmaz.
          for (final MapEntry<JobType, String> giris in kapali.entries)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(
                    Icons.lock_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${giris.key.name}: ${giris.value}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({
    required this.job,
    required this.availability,
    required this.onApply,
  });

  final JobType job;
  final dynamic availability;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool acik = availability.isAllowed as bool;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(job.name, style: theme.textTheme.titleMedium),
                ),
                Text(
                  '${trMoney(job.yearlySalary)}/yıl',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              job.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    acik
                        ? '${job.education.label} · ${job.minAge} yaş+'
                        : (availability.reason as String? ?? ''),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                FilledButton.tonal(
                  onPressed: acik ? onApply : null,
                  child: const Text('Başvur'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Eğitim ve kariyer yardımcıları için ortak erişim.
///
/// `EducationPath` ve `JobMarket` doğrudan kullanılabilir olsun diye
/// dışa aktarılır; arayüz katmanı kendi kopyasını üretmez.
const EducationPath educationPath = EducationPath();
const JobMarket jobMarket = JobMarket();

/// Kariyer geçmişi: çalışılan bütün işler ve oradaki önemli anlar.
///
/// İş değiştirince eski kayıt **silinmez** (Paket 9). Kayıt yoksa uydurma
/// bir geçmiş gösterilmez.
class CareerHistoryPage extends StatelessWidget {
  const CareerHistoryPage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final GameState state = GameScope.of(context).state!;
    final List<JobHistoryEntry> kayitlar =
        state.career.allEntries().reversed.toList(growable: false);

    return SectionScaffold(
      icon: Icons.work_history_rounded,
      accent: BirOmurAccents.cini,
      title: 'Kariyer geçmişi',
      subtitle: kayitlar.isEmpty
          ? 'Henüz çalışma kaydın yok.'
          : 'Çalıştığın işler, görevlerin ve oradaki önemli anlar.',
      backLabel: 'Meslek',
      onBack: onBack,
      children: <Widget>[
        if (kayitlar.isEmpty)
          const InfoPanel(
            icon: Icons.work_outline,
            text: 'Henüz bir işte çalışmadın. İlk işine girdiğinde bu '
                'bölümde görünecek.',
          )
        else
          for (final JobHistoryEntry kayit in kayitlar) ...<Widget>[
            _HistoryCard(entry: kayit, playerAge: state.player.age),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.entry, required this.playerAge});

  final JobHistoryEntry entry;
  final int playerAge;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool suruyor = entry.endedAtAge == null;
    final BirOmurAccent renk =
        suruyor ? BirOmurAccents.mor : BirOmurAccents.cini;
    final int yil = entry.endedAtAge == null
        ? playerAge - entry.startedAtAge
        : entry.years!;

    return Container(
      decoration: panelDecoration(context, radius: 22),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              AccentIconTile(
                icon: suruyor
                    ? Icons.work_outline
                    : Icons.work_history_outlined,
                accent: renk,
                size: 38,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(entry.title, style: theme.textTheme.titleMedium),
                    Text(
                      suruyor
                          ? '${entry.startedAtAge} yaşından beri · $yil yıl'
                          : '${entry.startedAtAge}-${entry.endedAtAge} yaş · '
                              '$yil yıl',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (entry.salary != null)
            _HistoryRow(
              label: suruyor ? 'Yıllık maaş' : 'Son maaş',
              value: trMoney(entry.salary!),
            ),
          if (entry.city != null)
            _HistoryRow(label: 'Şehir', value: entry.city!),
          if (entry.endReason != null)
            _HistoryRow(label: 'Ayrılış', value: entry.endReason!.label),
          if (entry.milestones.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              'Bu işteki önemli anlar',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: renk.of(context),
              ),
            ),
            const SizedBox(height: 4),
            for (final CareerMilestone an in entry.milestones)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '${an.age} yaş · ${an.text}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Değer uzun olabilir (ör. uzun bir unvan); satır taşmasın diye
          // esner ve sağa yaslanır.
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
