import 'package:flutter/material.dart';

import '../../data/item_catalog.dart';
import '../../data/wedding_catalog.dart';
import '../../domain/interaction/intimacy.dart';

import '../../domain/interaction/bond_decay.dart';
import '../../domain/interaction/marriage_engine.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/interaction.dart';
import '../../domain/models/marriage.dart';
import '../../domain/models/pending_wedding.dart';
import '../../domain/models/pregnancy.dart';
import '../../domain/models/person.dart';
import '../../domain/models/relation.dart';
import '../../domain/interaction/shared_history.dart';
import '../theme/bir_omur_theme.dart';
import '../../state/game_scope.dart';
import 'effect_chips.dart';
import 'kilim_divider.dart';
import '../../domain/models/person_development.dart';
import '../../text/turkish_text.dart';

/// Kişi ayrıntısı ve aile etkileşimleri.
///
/// Kişi kimliğiyle çalışır; etkileşimden sonra güncel kayıt durumdan yeniden
/// okunur. Yapılamayacak bir etkileşim düğme olarak gösterilmez, gerekçesi
/// yazılır.
class PersonDetailSheet extends StatefulWidget {
  const PersonDetailSheet({super.key, required this.personId});

  final String personId;

  static Future<void> show(BuildContext context, {required String personId}) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext context) => PersonDetailSheet(personId: personId),
    );
  }

  @override
  State<PersonDetailSheet> createState() => _PersonDetailSheetState();
}

class _PersonDetailSheetState extends State<PersonDetailSheet> {
  InteractionOutcome? _lastOutcome;
  String? _notice;

  void _run(InteractionKind kind) {
    final InteractionOutcome? outcome =
        GameScope.of(context).interact(widget.personId, kind);
    if (outcome == null) return;
    setState(() {
      _lastOutcome = outcome;
      _notice = null;
    });
  }

  /// Ayrılık (D-029): kişi kaydı silinmez, aynı kimlikle eski sevgili olur.
  Future<void> _breakUp(Person person) async {
    final bool? onay = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Ayrılmak istiyor musun?'),
        content: Text(
          '${person.firstName} ile ilişkini bitireceksin. '
          'Kaydı silinmez; Aile bölümünde eski sevgili olarak kalır.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ayrıl'),
          ),
        ],
      ),
    );
    if (onay != true || !mounted) return;
    final String? sonuc = GameScope.of(context).endRomance(widget.personId);
    setState(() {
      _lastOutcome = null;
      _notice = sonuc;
    });
  }

  /// Evlenme teklifi (D-048, Paket 25): yanıt her zaman "evet" değildir.
  ///
  /// **Teklif etmek bedelsizdir.** Oyuncu nasıl teklif edeceğini seçer;
  /// pahalı seçenek yanıtı satın almaz, yalnızca ihtimali biraz artırır.
  Future<void> _marry(Person person) async {
    final int cuzdan = GameScope.of(context).state!.player.wallet;
    final ProposalStyle? stil = await showModalBottomSheet<ProposalStyle>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) => _StyleSheet(
        title: '${person.firstName} ile evlenmeyi teklif edeceksin',
        subtitle: 'Nasıl soracağını sen seçiyorsun. Teklif etmek '
            'bedelsizdir; hazırlık yapmak ihtimali biraz artırır ama '
            'yanıtı satın almaz.',
        wallet: cuzdan,
        options: <_StyleOption>[
          for (final ProposalStyle o in kProposalStyles)
            _StyleOption(
              key: o.id,
              label: o.label,
              description: o.description,
              cost: o.prototypeOnlyCost,
              icon: o.icon,
              value: o,
            ),
        ],
      ),
    );
    if (stil == null || !mounted) return;
    final FamilyOutcome? sonuc =
        GameScope.of(context).propose(widget.personId, styleId: stil.id);
    if (sonuc == null) return;
    setState(() {
      _lastOutcome = null;
      _notice = sonuc.text;
    });
    if (!mounted) return;
    // Kabul edildiyse sıra düğünde.
    if (GameScope.of(context).state!.hasPendingWedding) {
      await _wedding();
    }
  }

  /// Düğün seçimi (Paket 25): cüzdana göre.
  ///
  /// Bedelsiz seçenek her zaman vardır; "evet" almış oyuncu parasızlık
  /// yüzünden evlenemeden kalmaz.
  Future<void> _wedding() async {
    final GameState state = GameScope.of(context).state!;
    final PendingWedding? bekleyen = state.pendingWedding;
    if (bekleyen == null) return;
    final Person? es = state.personById(bekleyen.spouseId);
    final int cuzdan = state.player.wallet;
    final WeddingStyle? stil = await showModalBottomSheet<WeddingStyle>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      // Düğün seçimi yarıda bırakılabilir; kayıtta durur, sonra devam
      // edilir. Bu yüzden kapatmak serbesttir.
      builder: (BuildContext context) => _StyleSheet(
        title: es == null
            ? 'Sıra düğünde'
            : '${es.firstName} "evet" dedi. Sıra düğünde',
        subtitle: 'Bütçene uymayan seçenekler kapalı. Nikâhın masrafı '
            'yok: parasızlık yüzünden evlenemeden kalmazsın.',
        wallet: cuzdan,
        options: <_StyleOption>[
          for (final WeddingStyle o in kWeddingStyles)
            _StyleOption(
              key: o.id,
              label: o.label,
              description: o.description,
              cost: o.prototypeOnlyCost,
              icon: o.icon,
              value: o,
            ),
        ],
      ),
    );
    if (stil == null || !mounted) return;
    final FamilyOutcome? sonuc = GameScope.of(context).holdWedding(stil.id);
    if (sonuc == null) return;
    setState(() {
      _lastOutcome = null;
      _notice = sonuc.text;
    });
  }

  /// Boşanma (Paket E1): kişi kaydı silinmez, eski eş olur.
  Future<void> _divorce(Person person) async {
    final bool? onay = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Boşanmak istiyor musun?'),
        content: Text(
          '${person.firstName} ile evliliğin bitecek. Kaydı silinmez; '
          'İlişkiler bölümünde eski eş olarak kalır.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Boşan'),
          ),
        ],
      ),
    );
    if (onay != true || !mounted) return;
    final FamilyOutcome? sonuc = GameScope.of(context).divorce();
    if (sonuc == null) return;
    setState(() {
      _lastOutcome = null;
      _notice = sonuc.text;
    });
  }

  /// Baş başa kalmak (Paket 25).
  ///
  /// "Çocuk sahibi olun" düğmesinin yerini aldı: basınca doğrudan çocuk
  /// olmuyor. Korunma tercihi oyuncunun; korunmazsa çocuk bir
  /// **ihtimal**.
  /// Süren hamilelik varsa kişi kartında açıkça yazılır.
  ///
  /// Sessizce bekleyen bir durum olmamalı: oyuncu bebeğin yolda
  /// olduğunu ve bir sonraki yaşta doğacağını görebilmeli (Paket 26).
  Widget? _pregnancyNote(GameState state, Person person) {
    final Pregnancy? bekleyen = state.pregnancy;
    if (bekleyen == null || bekleyen.partnerId != person.id) return null;
    final String metin = bekleyen.expecting == ExpectingParty.oyuncu
        ? 'Hamilesin. Bebeğiniz bir sonraki yaşta doğacak.'
        : '${person.firstName} hamile. Bebeğiniz bir sonraki yaşta '
            'doğacak.';
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: _Note(key: const Key('person_pregnancy_note'), text: metin),
    );
  }

  Future<void> _intimacy(Person person) async {
    final Protection? secim = await showModalBottomSheet<Protection>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) => _ProtectionSheet(person: person),
    );
    if (secim == null || !mounted) return;
    final FamilyOutcome? sonuc =
        GameScope.of(context).beIntimate(widget.personId, secim);
    if (sonuc == null) return;
    setState(() {
      _lastOutcome = null;
      _notice = sonuc.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final GameState state = GameScope.of(context).state!;
    final Person? person = state.personById(widget.personId);
    if (person == null) return const SizedBox.shrink();

    final int playerAge = state.player.age;
    final InteractionAvailability availability =
        GameScope.of(context).availabilityFor(person);
    // Yalnızca gerçekten yapılabilen eylemler düğme olur; kalanlar
    // gerekçesiyle birlikte soluk gösterilir.
    final List<InteractionKind> available =
        availability.isAllowed
            ? GameScope.of(context).availableKindsFor(person)
            : const <InteractionKind>[];

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(person.fullName, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(
                person.labelFor(playerAge),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              const KilimDivider(),
              const SizedBox(height: 14),
              _Row(
                label: 'Yaş',
                value:
                    person.isAlive ? '${person.age}' : '${person.age} (vefat etti)',
              ),
              _Row(label: 'Cinsiyet', value: person.gender.label),
              // Evlilik kaydı gerçek bir kayıttır; eş ve eski eşte görünür.
              // İkinci evlilikten sonra da eski eşin kaydı kaybolmaz
              // (Paket 36): geçmiş evlilikler listesinden okunur.
              if (state.marriageWith(person.id) != null)
                _Row(
                  label: 'Evlilik',
                  value: _marriageLabel(state.marriageWith(person.id)!),
                ),
              _Row(label: 'Durum', value: person.occupationLabel),
              // Kendi hayatı izlenen kişilerde (oyuncunun çocukları, D-045)
              // eğitim, birikim ve ilgi alanları gerçek kayıttan okunur.
              // Diğer kişilerde yalnızca özellik kaydı olabilir (D-046);
              // onlarda eğitim/birikim satırı gösterilmez.
              if (person.relation == RelationType.cocuk &&
                  person.development != null) ...<Widget>[
                _Row(
                  label: 'Eğitim',
                  value: person.development!.educationLabel,
                ),
                _Row(
                  label: 'Kendi birikimi',
                  value: trMoney(person.development!.money),
                ),
                if (person.development!.interests.isNotEmpty)
                  _Row(
                    label: 'İlgi alanları',
                    value: person.development!.interests.join(', '),
                  ),
                // Evlat edinilen çocuk her bakımdan çocuktur; kayıt
                // yalnızca doğru anlatılır (D-049).
                if (person.development!.adopted)
                  const _Row(label: 'Aileye katılışı', value: 'Evlat edinildi'),
                // Diğer biyolojik ebeveyn kayıtlıysa gösterilir (D-047).
                if (person.development!.otherParentId != null &&
                    state.personById(person.development!.otherParentId!) != null)
                  _Row(
                    label: 'Diğer ebeveyni',
                    value: state
                        .personById(person.development!.otherParentId!)!
                        .fullName,
                  ),
              ] else if (person.wealth != null)
                _Row(label: 'Kendi maddi durumu', value: person.wealth!.label),
              // Kişinin gerçekten sahip olduğu eşyalar; miras bu listeden
              // dağıtılır (D-037, D-038).
              if (person.estate.isNotEmpty)
                _Row(
                  label: 'Sahip oldukları',
                  value: person.estate
                      .map((String t) => itemTypeOrFallback(t).name)
                      .join(', '),
                ),
              // Kendi hayatındaki dönüm noktaları: gerçekten yaşandıkları
              // yılla birlikte saklanır, sonradan yaştan uydurulmaz.
              if (person.relation == RelationType.cocuk &&
                  (person.development?.milestones.isNotEmpty ?? false)) ...<Widget>[
                const SizedBox(height: 14),
                Text('Hayatından', style: theme.textTheme.labelLarge),
                const SizedBox(height: 6),
                for (final LifeMilestone an in _sonAnlar(person.development!))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '${an.age} yaş · ${an.text}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
              ],
              // Hane bilgisi bağ türünden bağımsızdır (D-014): tanışıklık,
              // arkadaşlık veya akrabalık kimseyi hanene eklemez.
              _Row(
                label: 'Hane',
                value: person.isAlive
                    ? (person.inPlayerHousehold
                        ? 'Seninle aynı evde yaşıyor'
                        : 'Ayrı evde yaşıyor')
                    : '—',
              ),
              // Ortak geçmişiniz (Paket 14): yalnızca kayıtlarda gerçekten
              // duran anlar. Kayıt yoksa bölüm hiç gösterilmez.
              Builder(
                builder: (BuildContext context) {
                  // Az önce ekranda gösterilen sonuç, hemen altında
                  // ikinci kez yazılmasın diye listeden çıkarılır.
                  final String? sonSonuc = _lastOutcome?.text;
                  final List<SharedMoment> anlar = SharedHistory.of(
                    state,
                    person,
                  )
                      .where((SharedMoment m) => m.text != sonSonuc)
                      .toList(growable: false);
                  if (anlar.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const SizedBox(height: 16),
                      Text(
                        'Ortak geçmişiniz',
                        style: theme.textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      for (final SharedMoment an in anlar)
                        _SharedMomentRow(moment: an),
                    ],
                  );
                },
              ),
              if (person.isAlive) ...<Widget>[
                const SizedBox(height: 16),
                Text('Yakınlık', style: theme.textTheme.labelLarge),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: person.bond / 100,
                    minHeight: 8,
                    backgroundColor:
                        theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.secondary,
                    ),
                  ),
                ),
                // İlgisizlikten zayıflayan bağ oyuncuya **görünür**
                // olmalı; yoksa sessizce düşen bir sayı olur ve oyuncu
                // elinden bir şey gelmediğini sanır (Paket 24).
                Builder(
                  builder: (BuildContext context) {
                    final int? gecen =
                        BondDecay.yearsSinceContact(state, person);
                    if (gecen == null ||
                        !BondDecay.decays(state, person) ||
                        gecen <= BondDecay.prototypeOnlyGraceYears) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '$gecen yıldır görüşmediniz; araya mesafe giriyor.',
                        key: const Key('person_neglect_note'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 20),
              if (!availability.isAllowed)
                _Note(text: availability.reason!)
              else if (available.isEmpty)
                const _Note(
                  text: 'Şu an bu kişiyle yapabileceğin bir etkileşim yok.',
                )
              else
                _Actions(available: available, onSelected: _run),
              // Evlilik yalnızca sevgilide sunulur; koşul sağlanmıyorsa
              // düğme yerine gerekçe yazılır (sahte düğme olmaz).
              if (person.isAlive &&
                  person.relation == RelationType.sevgili) ...<Widget>[
                const SizedBox(height: 12),
                // "Evet" alınmış ama düğün seçilmemişse akış burada
                // kaldığı yerden sürer; yarıda kalan evlilik kaybolmaz.
                if (state.pendingWedding?.spouseId == widget.personId)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      key: const Key('person_wedding_button'),
                      onPressed: _wedding,
                      icon: const Icon(Icons.celebration_rounded),
                      label: const Text('Düğününüzü seçin'),
                    ),
                  )
                else if (GameScope.of(context)
                    .proposalAvailability(widget.personId)
                    .isAllowed)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      key: const Key('person_marry_button'),
                      onPressed: () => _marry(person),
                      icon: const Icon(Icons.favorite),
                      label: const Text('Evlenme teklif et'),
                    ),
                  )
                else
                  _Note(
                    text: 'Evlenme teklifi için: '
                        '${GameScope.of(context).proposalAvailability(widget.personId).reason}',
                  ),
                // Evlilik şart değildir (D-047): sevgiliyle de çocuk
                // sahibi olunabilir. Ama artık "çocuk yap" düğmesiyle
                // değil, korunmadan yakınlaşmanın ihtimaliyle
                // (Paket 25).
                ?_pregnancyNote(state, person),
                const SizedBox(height: 12),
                if (GameScope.of(context)
                    .intimacyAvailability(widget.personId)
                    .isAllowed)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      key: const Key('person_intimacy_button_partner'),
                      onPressed: () => _intimacy(person),
                      icon: const Icon(Icons.favorite_rounded),
                      label: const Text('Baş başa kalın 💞'),
                    ),
                  )
                else
                  _Note(
                    text: 'Baş başa kalmak için: '
                        '${GameScope.of(context).intimacyAvailability(widget.personId).reason}',
                  ),
              ],

              // Eşe özel eylemler: çocuk sahibi olmak ve boşanma.
              if (person.isAlive && person.relation == RelationType.es) ...<Widget>[
                ?_pregnancyNote(state, person),
                const SizedBox(height: 12),
                if (GameScope.of(context)
                    .intimacyAvailability(widget.personId)
                    .isAllowed)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      key: const Key('person_intimacy_button'),
                      onPressed: () => _intimacy(person),
                      icon: const Icon(Icons.favorite_rounded),
                      label: const Text('Baş başa kalın 💞'),
                    ),
                  )
                else
                  _Note(
                    text: 'Baş başa kalmak için: '
                        '${GameScope.of(context).intimacyAvailability(widget.personId).reason}',
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    key: const Key('person_divorce_button'),
                    onPressed: () => _divorce(person),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(
                        color: theme.colorScheme.error.withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Text('Boşan'),
                  ),
                ),
              ],
              // Ayrılma yalnızca gerçekten sevgili olan kişide sunulur;
              // eski sevgiliye sevgiliye özel eylem açılmaz.
              if (person.isAlive && person.relation == RelationType.sevgili) ...<Widget>[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _breakUp(person),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(
                        color: theme.colorScheme.error.withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Text('Ayrıl'),
                  ),
                ),
              ],
              if (_notice != null) ...<Widget>[
                const SizedBox(height: 16),
                _Note(text: _notice!),
              ],
              if (_lastOutcome != null) ...<Widget>[
                const SizedBox(height: 16),
                _OutcomeCard(outcome: _lastOutcome!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Evlilik kaydının okunur hâli.
String _marriageLabel(Marriage marriage) {
  switch (marriage.status) {
    case MarriageStatus.evli:
      return '${marriage.marriedAtAge} yaşında evlendiniz';
    case MarriageStatus.bosandi:
      return '${marriage.marriedAtAge} yaşında evlendiniz, '
          '${marriage.endedAtAge} yaşında boşandınız';
    case MarriageStatus.dul:
      return '${marriage.marriedAtAge} yaşında evlendiniz, '
          '${marriage.endedAtAge} yaşında kaybettin';
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.available, required this.onSelected});

  /// Yalnızca **gerçekten yapılabilen** etkileşimler.
  ///
  /// Kişiye uygun olmayan tür hiç gösterilmez: okul arkadaşının kartında
  /// kilitli bir "Para İste" satırı çıkmaz.
  final List<InteractionKind> available;
  final void Function(InteractionKind kind) onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: <Widget>[
        for (final InteractionKind kind in available)
          FilledButton.tonal(
            onPressed: () => onSelected(kind),
            child: Text(kind.label),
          ),
      ],
    );
  }
}

/// Son etkileşimin sonucu: metin ve gerçekten uygulanan değişimler.
class _OutcomeCard extends StatelessWidget {
  const _OutcomeCard({required this.outcome});

  final InteractionOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color accent =
        outcome.accepted ? theme.colorScheme.secondary : theme.colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(outcome.text, style: theme.textTheme.bodyMedium),
          if (outcome.effects.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            EffectChips(effects: outcome.effects),
          ],
          if (outcome.accepted && outcome.noNewBenefit) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              'Bu yaş için bu etkinlikten kazanacağın kalmadı. Başka kişiler '
              've başka etkinlikler açık.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Kişi kartında gösterilecek son dönüm noktaları (en yenisi altta).
List<LifeMilestone> _sonAnlar(PersonDevelopment dev) {
  const int kEnFazla = 6;
  final List<LifeMilestone> hepsi = dev.milestones;
  return hepsi.length <= kEnFazla
      ? hepsi
      : hepsi.sublist(hepsi.length - kEnFazla);
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


/// Ortak geçmişteki tek bir an.
class _SharedMomentRow extends StatelessWidget {
  const _SharedMomentRow({required this.moment});

  final SharedMoment moment;

  /// Anın türüne göre küçük bir ikon ve renk.
  ({IconData icon, BirOmurAccent accent}) get _stil => switch (moment.kind) {
        SharedMomentKind.hediye =>
          (icon: Icons.card_giftcard_outlined, accent: BirOmurAccents.pirinc),
        SharedMomentKind.gezi =>
          (icon: Icons.luggage_outlined, accent: BirOmurAccents.mavi),
        SharedMomentKind.kilometreTasi =>
          (icon: Icons.star_outline, accent: BirOmurAccents.gul),
        SharedMomentKind.olay =>
          (icon: Icons.chat_bubble_outline, accent: BirOmurAccents.cini),
      };

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ({IconData icon, BirOmurAccent accent}) stil = _stil;
    final Color renk = stil.accent.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: renk.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(stil.icon, size: 15, color: renk),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${moment.age} yaşında',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: renk,
                  ),
                ),
                Text(
                  moment.text,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


/// Seçenek listesi için tek satırlık veri.
class _StyleOption {
  const _StyleOption({
    required this.key,
    required this.label,
    required this.description,
    required this.cost,
    required this.icon,
    required this.value,
  });

  final String key;
  final String label;
  final String description;
  final int cost;
  final IconData icon;
  final Object value;
}

/// Teklif ve düğün seçeneklerini gösteren ortak sayfa.
///
/// Bütçeye uymayan seçenek **gizlenmez**, kapalı gösterilir ve nedeni
/// yazılır: oyuncu neyin neye mal olduğunu görebilmeli.
class _StyleSheet extends StatelessWidget {
  const _StyleSheet({
    required this.title,
    required this.subtitle,
    required this.wallet,
    required this.options,
  });

  final String title;
  final String subtitle;
  final int wallet;
  final List<_StyleOption> options;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: theme.textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              const KilimDivider(),
              const SizedBox(height: 14),
              for (final _StyleOption o in options) ...<Widget>[
                _StyleRow(option: o, affordable: o.cost <= wallet),
                const SizedBox(height: 10),
              ],
              Text(
                'Cüzdanında ${trMoney(wallet)} var.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StyleRow extends StatelessWidget {
  const _StyleRow({required this.option, required this.affordable});

  final _StyleOption option;
  final bool affordable;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        key: Key('style_option_${option.key}'),
        onPressed:
            affordable ? () => Navigator.of(context).pop(option.value) : null,
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(option.icon, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    option.cost == 0
                        ? '${option.label} · masrafsız'
                        : '${option.label} · ${trMoney(option.cost)}',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    option.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (!affordable) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      'Cüzdanında yeterli para yok.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Korunma tercihi sayfası (Paket 25).
///
/// Metin kapalı ve ölçülüdür; sahne anlatılmaz. Ne kastedildiği
/// başlıktaki simgeden ve seçeneklerin kendisinden anlaşılır.
class _ProtectionSheet extends StatelessWidget {
  const _ProtectionSheet({required this.person});

  final Person person;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '${person.firstName} ile baş başa 💞',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'Korunup korunmayacağınıza sen karar veriyorsun. '
              'Korunmazsanız çocuk ihtimal dahilinde; garanti değil.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            const KilimDivider(),
            const SizedBox(height: 14),
            for (final Protection p in Protection.values) ...<Widget>[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  key: Key('protection_${p.name}'),
                  onPressed: () => Navigator.of(context).pop(p),
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(p.label, style: theme.textTheme.titleSmall),
                      const SizedBox(height: 2),
                      Text(
                        p.hint,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}
