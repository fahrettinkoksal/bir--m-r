import 'package:flutter/material.dart';

import '../../domain/generation/generation_continuation.dart';
import '../../domain/life/life_verdict.dart';
import '../../domain/life/will.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/life_log.dart';
import '../../domain/models/owned_item.dart';
import '../../domain/models/relation.dart';
import '../../domain/models/person.dart';
import '../../domain/models/combat_career.dart';
import '../../domain/sports/football_career.dart';
import '../../text/turkish_text.dart';
import '../../state/game_scope.dart';
import '../widgets/kilim_divider.dart';
import '../widgets/life_verdict_panel.dart';
import '../widgets/section_scaffold.dart';

/// Oyuncu vefat ettiğinde gösterilen hayat özeti.
///
/// Hayat tamamlanmış sayılır; yaş ilerlemez. Kayıt silinmez, özet
/// uygulama kapatılıp açılınca da görünür. Yeni hayat yalnızca oyuncu
/// açıkça isterse başlar.
class LifeSummaryScreen extends StatelessWidget {
  const LifeSummaryScreen({
    super.key,
    required this.onNewLife,
    required this.onShowArchive,
    this.onContinueAsChild,
  });

  final VoidCallback onNewLife;

  /// **Çocuğum olarak devam et** akışı (Paket E3).
  ///
  /// `null` ise ya da hayatta çocuk yoksa düğme **hiç gösterilmez**:
  /// çalışmayan sahte düğme olmaz (D-038).
  final VoidCallback? onContinueAsChild;

  /// Geçmiş Hayatlar arşivini açar.
  final VoidCallback onShowArchive;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final GameState state = GameScope.of(context).state!;

    // Eş kan bağı değildir ama hayatın ailesindedir; çocuklar zaten
    // kan bağıyla listeye girer.
    final List<Person> aile = state.people
        .where((Person p) =>
            p.relation.kanBagi || p.relation == RelationType.es)
        .toList(growable: false);
    final List<Person> devamCocuklari = GenerationContinuation.heirs(state);
    final bool devamVar =
        onContinueAsChild != null && devamCocuklari.isNotEmpty;
    final List<LifeLogEntry> donumNoktalari = state.log
        .where((LifeLogEntry e) => e.category != LogCategory.yasDegisimi)
        .toList(growable: false);
    final List<LifeLogEntry> sonDonumNoktalari = donumNoktalari.length > 8
        ? donumNoktalari.sublist(donumNoktalari.length - 8)
        : donumNoktalari;

    return SectionScaffold(
      icon: Icons.local_florist_rounded,
      title: 'Bir ömür tamamlandı',
      subtitle: state.player.fullName,
      children: <Widget>[
        // Ekranın ilk söylediği şey kaç eşya bırakıldığı değil,
        // hayatın nasıl geçtiğidir (Paket 22).
        LifeVerdictPanel(verdict: LifeVerdictBuilder.build(state)),
        const SizedBox(height: 14),
        Card(
          key: const Key('life_summary_card'),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${state.player.fullName}, ${state.deathAge ?? state.player.age} '
                  'yaşında hayatını kaybetti.',
                  style: theme.textTheme.titleMedium,
                ),
                if (state.deathCause != null) ...<Widget>[
                  const SizedBox(height: 6),
                  Text(
                    'Sebep: ${state.deathCause}.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                const KilimDivider(),
                const SizedBox(height: 14),
                // Vasiyette geçerli bir mirasçı varsa yazılır; vefat
                // etmiş kişi mirasçı olarak gösterilmez (D-052).
                if (Will.effectiveHeir(state) != null)
                  _Satir(
                    label: 'Vasiyet',
                    value: 'Mirasçı: ${Will.effectiveHeir(state)!.fullName}',
                  ),
                if (state.isContinuedGeneration)
                  _Satir(
                    label: 'Kuşak',
                    value: '${state.generation}. kuşak',
                  ),
                _Satir(label: 'Doğum şehri', value: state.player.birthCity),
                _Satir(label: 'Eğitim', value: state.education.label),
                if (state.education.program != null)
                  _Satir(
                    label: 'Bölüm',
                    value: state.education.program!.name,
                  ),
                _Satir(
                  label: 'Meslek',
                  value: state.career.isEmployed
                      ? state.career.label
                      : state.career.pastJobIds.isEmpty
                          // Sporcuya "Çalışmadı" yazılmaz (AY/3, AY/5):
                          // o hayatın emeği sahada ya da ringde geçti.
                          ? ((state.footballCareer?.proSeasons ?? 0) > 0
                              ? 'Profesyonel futbolcu'
                              : _dovusenKariyerler(state).isNotEmpty
                                  ? 'Dövüş sporcusu'
                                  : 'Çalışmadı')
                          : 'Son iş: ${state.career.label}',
                ),
                // Futbol kariyeri ömür özetinde görünür (Paket AY/3).
                // Eskiden hiç yazılmıyordu: 15 sezon, 300 maçlık bir
                // kariyer ömür sonunda yok sayılıyordu.
                if ((state.footballCareer?.proSeasons ?? 0) > 0)
                  _Satir(
                    label: 'Futbol',
                    value: _futbolOzeti(state.footballCareer!),
                  ),
                // Dövüş kariyeri de görünür (Paket AY/5).
                //
                // AY/3'te futbol satırını eklediğimde bir tutarsızlık
                // doğdu: futbolcunun kariyeri ömür sonunda yazılıyor,
                // kemer kazanmış dövüşçünün yazılmıyordu. Aynı eksiklik
                // hükümde de vardı ve AY/4'te kapandı.
                for (final CombatCareer dovus in _dovusenKariyerler(state))
                  _Satir(
                    label: _dovusEtiketi(dovus),
                    value: _dovusOzeti(dovus),
                  ),
                _Satir(label: 'Cüzdan', value: state.player.walletLabel),
                _Satir(label: 'Eşya sayısı', value: '${state.items.length}'),
                if (state.licenses.isNotEmpty)
                  _Satir(
                    label: 'Ehliyetler',
                    value: '${state.licenses.length}',
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (aile.isNotEmpty) ...<Widget>[
          Text('Ailesi', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final Person p in aile)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '${p.labelFor(state.deathAge ?? state.player.age)}: '
                '${p.fullName}${p.isAlive ? '' : ' (vefat etti)'}',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          const SizedBox(height: 14),
        ],
        if (state.items.isNotEmpty) ...<Widget>[
          Text('Geride bıraktıkları', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final OwnedItem item in state.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '${item.name} (${item.source.label})',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          const SizedBox(height: 14),
        ],
        if (sonDonumNoktalari.isNotEmpty) ...<Widget>[
          Text('Hayatından satırlar', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final LifeLogEntry e in sonDonumNoktalari)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '${e.age}: ${e.text}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ),
          const SizedBox(height: 14),
        ],
        if (devamVar) ...<Widget>[
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const Key('life_summary_continue_generation'),
              onPressed: onContinueAsChild,
              icon: const Icon(Icons.child_care_outlined),
              label: Text(
                devamCocuklari.length == 1
                    ? '${devamCocuklari.single.firstName} olarak devam et'
                    : 'Çocuğum olarak devam et',
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        SizedBox(
          width: double.infinity,
          // Kuşak devamı varken ana eylem odur; yeni hayat ikincil kalır.
          child: devamVar
              ? OutlinedButton(
                  key: const Key('life_summary_new_life'),
                  onPressed: onNewLife,
                  child: const Text('Yeni bir hayata başla'),
                )
              : FilledButton(
                  key: const Key('life_summary_new_life'),
                  onPressed: onNewLife,
                  child: const Text('Yeni bir hayata başla'),
                ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            key: const Key('life_summary_archive'),
            onPressed: onShowArchive,
            child: Text(
              state.pastLives.isEmpty
                  ? 'Geçmiş Hayatlar'
                  : 'Geçmiş Hayatlar (${state.pastLives.length})',
            ),
          ),
        ),
        const SizedBox(height: 10),
        const InfoPanel(
          icon: Icons.save_outlined,
          text: 'Bu hayatın özeti, yeni hayata başlasan bile Geçmiş '
              'Hayatlar arşivinde saklanır.',
        ),
      ],
    );
  }
}

class _Satir extends StatelessWidget {
  const _Satir({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

/// Ömür özetindeki futbol satırı (Paket AY/3).
///
/// İç sayılar (form, itibar, beceri) gösterilmez; oyuncunun hatırlayacağı
/// şeyler yazılır: kaç sezon, kaç maç, kaç gol, nasıl bitti.
String _futbolOzeti(FootballCareer k) {
  final String golKismi = k.position == FootballPosition.kaleci
      ? ''
      : ', ${k.totalGoals} gol';
  final String bitis = k.active
      ? ' · sürüyor'
      : k.exitReason == null
          ? ''
          : ' · bitiş: ${trLower(k.exitReason!.label)}';
  return '${k.proSeasons} sezon, ${k.totalAppearances} maç$golKismi'
      '$bitis';
}

/// Ömür özetinde yazılacak dövüş kariyerleri (Paket AY/5).
///
/// Yalnızca **gerçekten müsabakaya çıkılmış** kariyerler. Lisans alıp
/// hiç dövüşmemiş bir kayıt ömür özetini şişirmez.
List<CombatCareer> _dovusenKariyerler(GameState state) => <CombatCareer>[
      for (final CombatCareer k in state.combatCareers)
        if (k.amateurWins + k.amateurLosses + k.proWins + k.proLosses > 0) k,
    ];

/// Satır etiketi: dal adı biliniyorsa onunla yazılır.
String _dovusEtiketi(CombatCareer k) => k.art?.name ?? 'Dövüş';

/// Dövüş kariyerinin özeti.
///
/// İç sayılar (form, itibar, sıralama) gösterilmez; oyuncunun
/// hatırlayacağı şeyler yazılır: kaç maç, galibiyet, şampiyonluk.
String _dovusOzeti(CombatCareer k) {
  final int mac = k.amateurWins + k.amateurLosses + k.proWins + k.proLosses;
  final int galibiyet = k.amateurWins + k.proWins;
  final String kemer =
      k.championships > 0 ? ', ${k.championships} şampiyonluk' : '';
  final String bitis = k.retiredAtAge == null
      ? ''
      : k.retirementReason == null
          ? ''
          : ' · bitiş: ${trLower(k.retirementReason!.label)}';
  return '$mac maç, $galibiyet galibiyet$kemer$bitis';
}
