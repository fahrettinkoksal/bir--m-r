import 'package:flutter/material.dart';

import '../../../domain/models/game_state.dart';
import '../../../domain/sports/football_career.dart';
import '../../../text/turkish_text.dart';
import '../../../state/game_controller.dart';
import '../../../state/game_scope.dart';
import '../../theme/bir_omur_theme.dart';
import '../../widgets/section_scaffold.dart';

/// Spor Kariyeri sayfası (Paket AV).
///
/// Profesyonel futbol **bir meslek kataloğu işi değil** (AU kararı):
/// `kJobCatalog` içine girmez, kendi yolu vardır. Bu sayfa o yolun
/// oyuncuya bakan yüzü: gençlik geçmişi, hazırlık puanı ve kapının açık
/// olup olmadığının **gerekçesi**.
///
/// Sayfa hiçbir sayıyı kendisi hesaplamaz; hepsi `FootballPath` üzerinden
/// gelir. Henüz yazılmamış adım (profesyonel sözleşme, sezon akışı) için
/// sahte düğme konmaz, açıkça "henüz yok" yazılır.
class SportsCareerPage extends StatefulWidget {
  const SportsCareerPage({super.key, required this.onBack, this.backLabel});

  final VoidCallback onBack;

  /// Geri satırının etiketi; bu sayfaya Okul'dan da Meslek'ten de girilir.
  final String? backLabel;

  @override
  State<SportsCareerPage> createState() => _SportsCareerPageState();
}

class _SportsCareerPageState extends State<SportsCareerPage> {
  /// Son eylemin ekranda duran sonucu (deneme, bırakma).
  String? _sonuc;

  @override
  Widget build(BuildContext context) {
    final GameController controller = GameScope.of(context);
    final GameState state = controller.state!;
    final FootballEligibility? uygunluk = controller.footballEligibility();
    final List<String> gecmis = FootballPath.youthSummary(state);
    final bool scout = FootballPath.scoutInterest(state);
    final FootballCareer? kariyer = state.footballCareer;

    return SectionScaffold(
      icon: Icons.sports_soccer_rounded,
      accent: BirOmurAccents.yesil,
      title: 'Spor Kariyeri',
      subtitle: uygunluk == null ? null : _asamaBasligi(uygunluk.stage),
      backLabel: widget.backLabel ?? 'Okul',
      onBack: widget.onBack,
      children: <Widget>[
        if (uygunluk == null)
          const InfoPanel(
            icon: Icons.info_outline,
            text: 'Spor kariyeri durumu okunamadı.',
          )
        else ...<Widget>[
          if (_sonuc != null) ...<Widget>[
            InfoPanel(icon: Icons.info_outline, text: _sonuc!),
            const SizedBox(height: 12),
          ],

          // Profesyonel kariyer varsa önce o gelir: oyuncunun şu anki
          // hayatı, uygunluk kapısından önemlidir.
          if (kariyer != null) ...<Widget>[
            _KariyerKarti(kariyer: kariyer),
            const SizedBox(height: 12),
            if (kariyer.active)
              MenuRow(
                key: const Key('futbol_birak'),
                title: 'Futbolu bırak',
                subtitle: 'Kariyer kaydın silinmez',
                icon: Icons.logout_outlined,
                accent: BirOmurAccents.nar,
                onTap: () {
                  controller.retireFromFootball();
                  setState(() => _sonuc =
                      'Futbolu bıraktın. Kariyer geçmişin bu sayfada '
                      'duruyor.');
                },
              ),
            if (kariyer.seasonHistory.isNotEmpty) ...<Widget>[
              const SizedBox(height: 14),
              const _Baslik('Sezonlar'),
              const SizedBox(height: 10),
              for (final FootballSeason sezon in kariyer.seasonHistory.reversed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InfoPanel(
                    icon: Icons.event_note_outlined,
                    text: _sezonSatiri(sezon, kariyer.position),
                  ),
                ),
            ],
            const SizedBox(height: 14),
          ],

          // Durum ve gerekçe: oyuncu neden girebildiğini ya da neden
          // giremediğini okur. Kariyer başladıysa bu kapı kapanır.
          if (kariyer == null) ...<Widget>[
            _DurumKarti(uygunluk: uygunluk),
            const SizedBox(height: 12),
            if (controller.canAttemptFootballTrial())
              MenuRow(
                key: const Key('futbol_deneme'),
                title: 'Profesyonel denemeye gir',
                subtitle: 'Kabul garanti değil; kadro dolabilir',
                icon: Icons.sports_soccer_outlined,
                accent: BirOmurAccents.yesil,
                onTap: () {
                  final ({bool accepted, String reason}) sonuc =
                      controller.attemptFootballTrial();
                  setState(() => _sonuc = sonuc.reason);
                },
              ),
            const SizedBox(height: 12),
          ],

          if (scout) ...<Widget>[
            const InfoPanel(
              icon: Icons.visibility_outlined,
              text:
                  'Maçlarını izleyen biri var. Bu kendi başına bir teklif '
                  'değil; ilgi, geçmişin yeterince güçlü olduğu anlamına '
                  'geliyor.',
            ),
            const SizedBox(height: 12),
          ],

          // Gençlik geçmişi: kaç sezon, hangi kademede.
          const _Baslik('Futbol geçmişin'),
          const SizedBox(height: 10),
          if (gecmis.isEmpty)
            const InfoPanel(
              icon: Icons.info_outline,
              text:
                  'Hiç futbol oynamamışsın. Profesyonel futbola okul '
                  'takımından geçilir; Okul bölümündeki Kulüpler '
                  'sayfasından futbol takımına katılabilirsin.',
            )
          else
            for (final String satir in gecmis) ...<Widget>[
              InfoPanel(icon: Icons.history_outlined, text: satir),
              const SizedBox(height: 8),
            ],

          const SizedBox(height: 14),
          // Henüz yazılmamış adım dürüstçe söylenir. Paket AY sezon
          // akışını, formu, sakatlığı, kazancı ve kariyer sonunu yazdı;
          // aşağıdaki liste **gerçekten eksik olanlar**.
          const InfoPanel(
            icon: Icons.construction_outlined,
            text:
                'Kulüp ve lig adları, transfer pazarı, sözleşme pazarlığı '
                've maç maç simülasyon henüz yok. Sezonlar bir bütün '
                'olarak hesaplanıyor: kaç maç oynadığın, nasıl bir sezon '
                'geçirdiğin ve ne kazandığın yazılıyor.',
          ),
        ],
      ],
    );
  }

  /// Sezon satırı: kaç maç, kaç gol, nasıl bir sezon, sakatlık var mı.
  String _sezonSatiri(FootballSeason sezon, FootballPosition mevki) {
    final String nasil = sezon.rating >= 75
        ? 'çok iyi'
        : sezon.rating >= 58
            ? 'iyi'
            : sezon.rating >= 42
                ? 'ortalama'
                : 'zor';
    final String golKismi = mevki == FootballPosition.kaleci
        ? ''
        : ', ${sezon.goals} gol';
    final String sakatlikKismi =
        sezon.injury == null ? '' : ' · ${sezon.injury}';
    return '${sezon.age} yaş — ${sezon.appearances} maç$golKismi · '
        '$nasil sezon (${sezon.rating})$sakatlikKismi';
  }

  String _asamaBasligi(FootballStage asama) {
    switch (asama) {
      case FootballStage.gecmisYok:
        return 'Futbol geçmişin yok';
      case FootballStage.gelisiyor:
        return 'Gelişiyor';
      case FootballStage.denemeyeUygun:
        return 'Profesyonel deneme kapısı açık';
      case FootballStage.aktifProfesyonel:
        return 'Aktif profesyonel';
      case FootballStage.emekli:
        return 'Emekli';
    }
  }
}

/// Uygunluk durumu, gerekçesi ve hazırlık puanının dökümü.
class _DurumKarti extends StatelessWidget {
  const _DurumKarti({required this.uygunluk});

  final FootballEligibility uygunluk;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

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
                  icon: uygunluk.eligible
                      ? Icons.door_front_door_outlined
                      : Icons.lock_outline,
                  accent: uygunluk.eligible
                      ? BirOmurAccents.yesil
                      : BirOmurAccents.pirinc,
                  size: 38,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    uygunluk.eligible
                        ? 'Profesyonel denemeye girebilirsin'
                        : 'Şu an giremiyorsun',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Gerekçe her durumda yazılır: kuru "uygun değilsin" yok.
            Text(
              uygunluk.reason,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            _Satir(etiket: 'Hazırlık puanı', deger: '${uygunluk.score} / 100'),
            _Satir(etiket: 'Oynadığın sezon', deger: '${uygunluk.seasons}'),
            _Satir(etiket: 'En iyi beceri', deger: '${uygunluk.skill}'),
            if (uygunluk.startedAtAge != null)
              _Satir(
                etiket: 'Başlama yaşı',
                deger: '${uygunluk.startedAtAge}',
              ),
            if (uygunluk.wasCaptain)
              const _Satir(etiket: 'Kaptanlık', deger: 'Yaptın'),
          ],
        ),
      ),
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

/// Süren ya da bitmiş profesyonel kariyerin kartı.
class _KariyerKarti extends StatelessWidget {
  const _KariyerKarti({required this.kariyer});

  final FootballCareer kariyer;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool aktif = kariyer.active;

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
                  icon: aktif
                      ? Icons.sports_soccer_rounded
                      : Icons.emoji_events_outlined,
                  accent: aktif
                      ? BirOmurAccents.yesil
                      : BirOmurAccents.pirinc,
                  size: 38,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        aktif
                            ? 'Profesyonel futbolcu'
                            : 'Futbol kariyeri bitti',
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        kariyer.position.label,
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
            _Satir(
              etiket: 'Başlangıç',
              deger: '${kariyer.startedAtAge} yaşında',
            ),
            _Satir(etiket: 'Sezon', deger: '${kariyer.proSeasons}'),
            _Satir(etiket: 'Maç', deger: '${kariyer.totalAppearances}'),
            if (kariyer.position != FootballPosition.kaleci)
              _Satir(etiket: 'Gol', deger: '${kariyer.totalGoals}'),
            if (aktif) _Satir(etiket: 'Form', deger: '${kariyer.form}'),
            _Satir(etiket: 'İtibar', deger: '${kariyer.reputation}'),
            if (kariyer.careerEarnings > 0)
              _Satir(
                etiket: 'Futboldan kazanç',
                deger: trMoney(kariyer.careerEarnings),
              ),
            // Kariyerin neden bittiği yazılır; kuru "bitti" yok.
            if (!aktif && kariyer.exitReason != null)
              _Satir(
                etiket: 'Bitiş sebebi',
                deger: kariyer.exitReason!.label,
              ),
            if (!aktif && kariyer.retiredAtAge != null)
              _Satir(
                etiket: 'Bıraktığın yaş',
                deger: '${kariyer.retiredAtAge}',
              ),
          ],
        ),
      ),
    );
  }
}
