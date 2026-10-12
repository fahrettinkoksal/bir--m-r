import 'package:flutter/material.dart';

import '../../../data/school_club_catalog.dart';
import '../../../domain/models/game_state.dart';
import '../../../domain/models/school_club_progress.dart';
import '../../../domain/sports/school_club_engine.dart';
import '../../../state/game_controller.dart';
import '../../../state/game_scope.dart';
import '../../theme/bir_omur_theme.dart';
import '../../widgets/section_scaffold.dart';

/// Okul kulüpleri sayfası (Paket AV).
///
/// Paket AU kulüpleri, çok yıllı geçmişi ve rolleri kurdu ama oyuncu
/// bunları hiçbir ekranda göremiyordu: kulüp olayları akışta çıkıyor,
/// takımdaki yeri görünmüyordu. Bu sayfa o boşluğu kapatır.
///
/// Ekran **yeni kural koymaz**: katılma engelleri, seçme sonucu ve
/// antrenman sınırı motordan (`SchoolClubEngine`) gelir. Olmayan sistem
/// için sahte düğme konmaz; kapalı olan şeyin **gerekçesi** yazılır.
class SchoolClubsPage extends StatefulWidget {
  const SchoolClubsPage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<SchoolClubsPage> createState() => _SchoolClubsPageState();
}

class _SchoolClubsPageState extends State<SchoolClubsPage> {
  /// Son eylemin ekranda duran sonucu (seçme, antrenman, ayrılma).
  String? _sonuc;

  /// Kartı açık duran kulüp; aynı anda tek kart açılır.
  String? _acik;

  @override
  Widget build(BuildContext context) {
    final GameController controller = GameScope.of(context);
    final GameState state = controller.state!;
    final int sinif = state.education.grade ?? 0;

    final List<SchoolClubProgress> aktifler = state.schoolClubs.activeOnes;
    final List<SchoolClubProgress> gecmis = state.schoolClubs
        .where((SchoolClubProgress p) => !p.active)
        .toList(growable: false);

    // Katılınabilecek kulüpler: aktif olmayan ve bu sınıfa açık olanlar.
    final List<SchoolClub> acikOlanlar = <SchoolClub>[
      for (final SchoolClub c in kSchoolClubs)
        if (state.schoolClubs.activeFor(c.id) == null && c.openForGrade(sinif))
          c,
    ];

    return SectionScaffold(
      icon: Icons.emoji_events_rounded,
      accent: BirOmurAccents.yesil,
      title: 'Kulüpler',
      subtitle: aktifler.isEmpty
          ? 'Hiçbir kulübe üye değilsin'
          : '${aktifler.length} kulüpte aktifsin',
      backLabel: 'Okul',
      onBack: widget.onBack,
      children: <Widget>[
        if (_sonuc != null) ...<Widget>[
          InfoPanel(icon: Icons.info_outline, text: _sonuc!),
          const SizedBox(height: 12),
        ],

        // 1) Üye olduğun kulüpler.
        if (aktifler.isNotEmpty) ...<Widget>[
          const _Baslik('Üye olduğun kulüpler'),
          const SizedBox(height: 10),
          for (final SchoolClubProgress uyelik in aktifler) ...<Widget>[
            _AktifKulupKarti(
              uyelik: uyelik,
              kulup: _kulup(uyelik.clubId),
              charisma: state.player.stats.charisma,
              acik: _acik == uyelik.clubId,
              antrenmanAcik: controller.canTrainClub(uyelik.clubId),
              onAc: () => setState(
                () => _acik = _acik == uyelik.clubId ? null : uyelik.clubId,
              ),
              onAntrenman: () {
                final String? metin = controller.trainClub(uyelik.clubId);
                setState(() => _sonuc = metin);
              },
              onAyril: () {
                controller.leaveClub(uyelik.clubId);
                setState(() {
                  _acik = null;
                  _sonuc =
                      '${_kulup(uyelik.clubId)?.name ?? 'Kulüp'} kaydından '
                      'ayrıldın. Geçmişin silinmiyor: kaç sezon oynadığın '
                      've beceri geçmişin duruyor.';
                });
              },
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 6),
        ],

        // 2) Katılabileceğin kulüpler.
        const _Baslik('Katılabileceğin kulüpler'),
        const SizedBox(height: 10),
        if (!state.education.isStudent)
          const InfoPanel(
            icon: Icons.info_outline,
            text:
                'Kulüpler yalnızca okula devam ederken açık. Okul '
                'geçmişindeki kulüp kayıtların aşağıda duruyor.',
          )
        else if (acikOlanlar.isEmpty)
          const InfoPanel(
            icon: Icons.info_outline,
            text:
                'Bu sınıfa açık başka kulüp yok. Üst sınıflarda yeni '
                'kulüpler açılıyor.',
          )
        else
          for (final SchoolClub kulup in acikOlanlar) ...<Widget>[
            _AcikKulupSatiri(
              kulup: kulup,
              engel: controller.clubBlock(kulup),
              onKatil: () {
                final ClubJoinOutcome sonuc = controller.joinClub(kulup);
                setState(() => _sonuc = sonuc.reason);
              },
            ),
            const SizedBox(height: 10),
          ],

        // 3) Geçmiş kulüp kayıtları.
        if (gecmis.isNotEmpty) ...<Widget>[
          const SizedBox(height: 14),
          const _Baslik('Geçmiş kulüp kayıtların'),
          const SizedBox(height: 10),
          for (final SchoolClubProgress p in gecmis) ...<Widget>[
            _GecmisKulupSatiri(uyelik: p, kulup: _kulup(p.clubId)),
            const SizedBox(height: 8),
          ],
        ],

        const SizedBox(height: 14),
        const InfoPanel(
          icon: Icons.sports_outlined,
          text:
              'Kulüpte geçirdiğin her sezon kaydediliyor: takımdaki yerin '
              'yılla ve beceriyle değişiyor, kaptanlık kıdem istiyor. '
              'Antrenman yılda bir kez yapılır. Okul değişince üyelik '
              'düşer ama geçmişin ve becerin kalır.',
        ),
      ],
    );
  }

  SchoolClub? _kulup(String id) {
    for (final SchoolClub c in kSchoolClubs) {
      if (c.id == id) return c;
    }
    return null;
  }
}

/// Üye olunan bir kulübün kartı: rol, sezon, beceri, dereceler.
class _AktifKulupKarti extends StatelessWidget {
  const _AktifKulupKarti({
    required this.uyelik,
    required this.kulup,
    required this.charisma,
    required this.acik,
    required this.antrenmanAcik,
    required this.onAc,
    required this.onAntrenman,
    required this.onAyril,
  });

  final SchoolClubProgress uyelik;
  final SchoolClub? kulup;

  /// Rol puanı karizmayı da sayıyor (Paket CQ'nun etiketi için).
  final int charisma;
  final bool acik;
  final bool antrenmanAcik;
  final VoidCallback onAc;
  final VoidCallback onAntrenman;
  final VoidCallback onAyril;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SchoolClub? c = kulup;

    return Container(
      decoration: panelDecoration(context, radius: 22),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                AccentIconTile(
                  icon: _simge(c),
                  accent: BirOmurAccents.yesil,
                  size: 38,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        c?.name ?? 'Kulüp',
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        // Rekabetçi olmayan kulüpte "Yedek" yazmak
                        // yanlıştı (Paket CQ); etiket aynı puandan
                        // türüyor.
                        c == null
                            ? uyelik.role.label
                            : SchoolClubEngine.standingLabel(
                                club: c,
                                progress: uyelik,
                                charisma: charisma,
                              ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onAc,
                  icon: Icon(
                    acik ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  ),
                  tooltip: acik ? 'Kapat' : 'Ayrıntı',
                ),
              ],
            ),
            const SizedBox(height: 10),
            _Satir(
              etiket: 'Sezon',
              deger: '${uyelik.yearsActive} yıl',
            ),
            _Satir(
              etiket: 'Beceri',
              deger: '${uyelik.skill} · ${uyelik.skillBand}',
            ),
            if (uyelik.wasCaptain)
              _Satir(
                etiket: 'Kaptanlık',
                deger: '${uyelik.captainSinceAge} yaşından beri',
              ),
            if (acik) ...<Widget>[
              _Satir(
                etiket: 'Katılım',
                deger:
                    '${uyelik.joinedAtAge} yaşında, '
                    '${uyelik.joinedAtGrade}. sınıfta',
              ),
              _Satir(etiket: 'Performans', deger: '${uyelik.performance}'),
              if (uyelik.competitions > 0)
                _Satir(
                  etiket: 'Katıldığın yarışma',
                  deger: '${uyelik.competitions}',
                ),
              if (uyelik.awards > 0)
                _Satir(etiket: 'Derece', deger: '${uyelik.awards}'),
              if (c != null) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  c.blurb,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
            const SizedBox(height: 12),
            if (antrenmanAcik)
              MenuRow(
                key: Key('kulup_antrenman_${uyelik.clubId}'),
                title: 'Antrenmana git',
                subtitle: 'Beceriyi biraz yükseltir; yılda bir kez',
                icon: Icons.fitness_center_outlined,
                accent: BirOmurAccents.yesil,
                onTap: onAntrenman,
              )
            else
              const InfoPanel(
                icon: Icons.schedule_outlined,
                text:
                    'Bu yılın antrenmanını yaptın. Gelecek yıl yine '
                    'çalışabilirsin.',
              ),
            if (acik) ...<Widget>[
              const SizedBox(height: 10),
              MenuRow(
                key: Key('kulup_ayril_${uyelik.clubId}'),
                title: 'Kulüpten ayrıl',
                subtitle: 'Geçmiş kaydın silinmez',
                icon: Icons.logout_outlined,
                accent: BirOmurAccents.nar,
                onTap: onAyril,
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _simge(SchoolClub? c) {
    if (c == null) return Icons.emoji_events_outlined;
    switch (c.category) {
      case SchoolClubCategory.spor:
        return Icons.sports_soccer_outlined;
      case SchoolClubCategory.akademi:
        return Icons.psychology_outlined;
      case SchoolClubCategory.sanat:
        return Icons.palette_outlined;
    }
  }
}

/// Katılınabilecek bir kulübün satırı; engel varsa gerekçesi yazılır.
class _AcikKulupSatiri extends StatelessWidget {
  const _AcikKulupSatiri({
    required this.kulup,
    required this.engel,
    required this.onKatil,
  });

  final SchoolClub kulup;
  final ClubBlock? engel;
  final VoidCallback onKatil;

  @override
  Widget build(BuildContext context) {
    final ClubBlock? e = engel;
    if (e != null) {
      return InfoPanel(
        icon: Icons.lock_outline,
        text: '${kulup.name}: ${e.reason}',
      );
    }
    return MenuRow(
      key: Key('kulup_katil_${kulup.id}'),
      title: kulup.name,
      subtitle: kulup.requiresTryout
          ? '${kulup.category.label} · seçme var, sonuç kesin değil'
          : '${kulup.category.label} · seçme yok',
      icon: kulup.requiresTryout
          ? Icons.how_to_reg_outlined
          : Icons.add_circle_outline,
      accent: kulup.requiresTryout
          ? BirOmurAccents.pirinc
          : BirOmurAccents.cini,
      onTap: onKatil,
    );
  }
}

/// Ayrılınan ya da okul değişimiyle kapanan kulüp kaydı.
class _GecmisKulupSatiri extends StatelessWidget {
  const _GecmisKulupSatiri({required this.uyelik, required this.kulup});

  final SchoolClubProgress uyelik;
  final SchoolClub? kulup;

  @override
  Widget build(BuildContext context) {
    final String ad = kulup?.name ?? 'Kulüp';
    final String kaptan = uyelik.wasCaptain ? ', kaptanlık yaptın' : '';
    final String derece = uyelik.awards > 0
        ? ', ${uyelik.awards} derece'
        : '';
    return InfoPanel(
      icon: Icons.history_outlined,
      text:
          '$ad — ${uyelik.yearsActive} sezon, beceri ${uyelik.skill}'
          '$kaptan$derece. '
          '${uyelik.joinedAtAge} yaşında başladın'
          '${uyelik.leftAtAge != null ? ', ${uyelik.leftAtAge} yaşında bıraktın' : ''}.',
    );
  }
}

class _Satir extends StatelessWidget {
  const _Satir({required this.etiket, required this.deger});

  final String etiket;
  final String deger;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              etiket,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              deger,
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

class _Baslik extends StatelessWidget {
  const _Baslik(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.titleSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
