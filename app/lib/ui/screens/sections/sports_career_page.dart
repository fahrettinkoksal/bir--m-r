import 'package:flutter/material.dart';

import '../../../domain/models/game_state.dart';
import '../../../domain/sports/football_career.dart';
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
class SportsCareerPage extends StatelessWidget {
  const SportsCareerPage({super.key, required this.onBack, this.backLabel});

  final VoidCallback onBack;

  /// Geri satırının etiketi; bu sayfaya Okul'dan da Meslek'ten de girilir.
  final String? backLabel;

  @override
  Widget build(BuildContext context) {
    final GameController controller = GameScope.of(context);
    final GameState state = controller.state!;
    final FootballEligibility? uygunluk = controller.footballEligibility();
    final List<String> gecmis = FootballPath.youthSummary(state);
    final bool scout = FootballPath.scoutInterest(state);

    return SectionScaffold(
      icon: Icons.sports_soccer_rounded,
      accent: BirOmurAccents.yesil,
      title: 'Spor Kariyeri',
      subtitle: uygunluk == null ? null : _asamaBasligi(uygunluk.stage),
      backLabel: backLabel ?? 'Okul',
      onBack: onBack,
      children: <Widget>[
        if (uygunluk == null)
          const InfoPanel(
            icon: Icons.info_outline,
            text: 'Spor kariyeri durumu okunamadı.',
          )
        else ...<Widget>[
          // Durum ve gerekçe en üstte: oyuncu neden girebildiğini ya da
          // neden giremediğini ilk satırda okur.
          _DurumKarti(uygunluk: uygunluk),
          const SizedBox(height: 12),

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
          // Henüz yazılmamış adım dürüstçe söylenir.
          const InfoPanel(
            icon: Icons.construction_outlined,
            text:
                'Profesyonel sözleşme, kulüp seçimi ve sezon akışı henüz '
                'yazılmadı. Şu an kurulan şey yolun kendisi: okul '
                'takımındaki sezonların, becerinin ve takımdaki yerinin '
                'bu kapıyı açıp açmadığı.',
          ),
        ],
      ],
    );
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
