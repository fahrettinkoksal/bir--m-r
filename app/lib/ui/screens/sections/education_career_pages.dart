import 'package:flutter/material.dart';

import '../../../data/education_tracks.dart';
import '../../../data/job_catalog.dart';
import '../../../data/university_catalog.dart';
import '../../../domain/career/job_market.dart';
import '../../../domain/education/education_path.dart';
import '../../../domain/models/game_state.dart';
import '../../../state/game_controller.dart';
import '../../../state/game_scope.dart';
import '../../widgets/interview_sheet.dart';
import '../../widgets/section_scaffold.dart';
import '../../../text/turkish_text.dart';

/// Lise alanı seçimi.
///
/// Puanın yettiği alanlar düğme olur; yetmeyenler gerekçesiyle soluk
/// gösterilir. Puan ne olursa olsun en az üç alan açıktır.
class TrackChoicePage extends StatefulWidget {
  const TrackChoicePage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<TrackChoicePage> createState() => _TrackChoicePageState();
}

class _TrackChoicePageState extends State<TrackChoicePage> {
  String? _sonuc;

  @override
  Widget build(BuildContext context) {
    final GameController controller = GameScope.of(context);
    final GameState state = controller.state!;
    final int puan = state.education.placementScore ?? 0;
    final List<EducationTrackInfo> acik = controller.availableTracks();

    return SectionScaffold(
      title: 'Lise alanı seç',
      subtitle: 'Yerleştirme puanın: $puan',
      backLabel: 'Okul',
      onBack: widget.onBack,
      children: <Widget>[
        const InfoPanel(
          icon: Icons.school_outlined,
          text: 'Seçtiğin alan eğitim geçmişine yazılır. İleride '
              'başvurabileceğin üniversite bölümlerini ve iş seçeneklerini '
              'etkiler.',
        ),
        const SizedBox(height: 12),
        for (final EducationTrackInfo alan in kEducationTracks) ...<Widget>[
          _TrackCard(
            info: alan,
            enabled: acik.contains(alan),
            onSelect: () {
              final String? metin = controller.chooseTrack(alan.track)?.text;
              setState(() => _sonuc = metin);
            },
          ),
          const SizedBox(height: 10),
        ],
        if (_sonuc != null) ...<Widget>[
          const SizedBox(height: 4),
          InfoPanel(icon: Icons.check_circle_outline, text: _sonuc!),
        ],
      ],
    );
  }
}

class _TrackCard extends StatelessWidget {
  const _TrackCard({
    required this.info,
    required this.enabled,
    required this.onSelect,
  });

  final EducationTrackInfo info;
  final bool enabled;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(info.label, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              info.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Text(
                  info.minScore == 0
                      ? 'Puan şartı yok'
                      : 'En az ${info.minScore} puan',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                FilledButton.tonal(
                  onPressed: enabled ? onSelect : null,
                  child: Text(enabled ? 'Bu alanı seç' : 'Puanın yetmiyor'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

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
