import 'package:flutter/material.dart';

import '../sound/sound_scope.dart';
import '../sound/sound_service.dart';

import '../../domain/life/notices.dart';
import '../../domain/interaction/child_naming.dart';
import '../../domain/models/pending_notice.dart';
import '../../state/game_controller.dart';
import '../../state/game_scope.dart';
import '../../text/turkish_text.dart';
import 'effect_chips.dart';
import 'kilim_divider.dart';

/// Önemli haber penceresi (D-050).
///
/// Ölüm, miras ve cenaze bildirimleri burada gösterilir. Metin kısa ve
/// saygılıdır; etki yalnızca **gerçekten uygulandığı kadar** yazılır.
/// Pencere seçim yapılmadan kapanmaz; bekleyen bildirim kayıtta durur.
class NoticeSheet extends StatefulWidget {
  const NoticeSheet({super.key, required this.notice});

  final PendingNotice notice;

  static Future<void> show(BuildContext context, PendingNotice notice) {
    // Bildirim sakin bir çanla açılır (Paket 15).
    SoundScope.play(context, GameSound.notice);
    return showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      useRootNavigator: true,
      showDragHandle: false,
      // Varsayılan pencere ekranın 9/16'sını geçemez ve uzun bildirim
      // taşardı: check-up raporu gibi çok satırlı metinler sığmıyordu
      // (D-076'da ölçüldü: 48 px taşma). Artık pencere gerektiği kadar
      // uzayabiliyor, metin de kendi içinde kayıyor.
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      builder: (BuildContext context) => NoticeSheet(notice: notice),
    );
  }

  @override
  State<NoticeSheet> createState() => _NoticeSheetState();
}

class _NoticeSheetState extends State<NoticeSheet> {
  String? _sonuc;

  /// Cenaze akışında önce katılım sorulur (D-050): katılmak ile masrafa
  /// katkıda bulunmak aynı şey değildir.
  FuneralAttendance? _katilim;

  /// Doğum bildiriminde bebeğin adı (D-095).
  final TextEditingController _isimAlani = TextEditingController();

  /// İsim alanı bir kez doldurulur; her çizimde yazılan silinmesin.
  bool _isimHazir = false;

  /// İsim denemesinin sonucu: onay ya da sebebiyle birlikte ret.
  String? _isimNotu;

  @override
  void dispose() {
    _isimAlani.dispose();
    super.dispose();
  }

  /// Bebeğe girilen adı verir; sonuç ekranda yazılı kalır (D-095).
  void _isimVer(String childId) {
    final ({bool applied, String message}) sonuc =
        GameScope.of(context).nameChild(childId, _isimAlani.text);
    setState(() => _isimNotu = sonuc.message);
  }

  /// Bildirimi kapatır.
  ///
  /// Doğum bildirimindeyse **önce yazılan ad uygulanır**. Faho bildirdi:
  /// adı yazıp "Tamam"a basınca ad kayboluyordu, çünkü ad yalnızca ayrı
  /// "İsmi kaydet" düğmesiyle işleniyordu. Yazılan ad sessizce atılmaz:
  /// geçerliyse uygulanır, geçersizse pencere **kapanmaz** ve sebebi
  /// ekranda yazar.
  void _kapat() {
    if (!_adiUygula()) return;
    GameScope.of(context).dismissNotice();
    Navigator.of(context).pop();
  }

  /// Yazılan adı uygular. Kapatmaya devam edilebilirse `true` döner.
  bool _adiUygula() {
    final String bebekId = widget.notice.personId ?? '';
    if (widget.notice.kind != NoticeKind.dogum || bebekId.isEmpty) return true;
    final GameController controller = GameScope.of(context);
    if (!controller.canNameChild(bebekId)) return true;
    final String yazilan = _isimAlani.text.trim();
    if (yazilan.isEmpty) return true;
    // Ad zaten buysa boşuna günlüğe satır düşürmeyelim.
    final String mevcut =
        controller.state?.personById(bebekId)?.firstName ?? '';
    if (ChildNaming.normalize(yazilan) == mevcut) return true;
    final ({bool applied, String message}) sonuc =
        controller.nameChild(bebekId, yazilan);
    if (sonuc.applied) return true;
    setState(() => _isimNotu = sonuc.message);
    return false;
  }

  void _katilimSec(FuneralAttendance secim) {
    setState(() => _katilim = secim);
  }

  void _cenaze(FuneralChoice secim) {
    final String? metin = GameScope.of(context).respondToFuneral(
      secim,
      attendance: _katilim ?? FuneralAttendance.katildi,
    );
    setState(() => _sonuc = metin);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final PendingNotice notice = widget.notice;
    final bool cenaze = notice.kind == NoticeKind.cenaze && _sonuc == null;
    final bool katilimSorulacak = cenaze && _katilim == null;

    // Doğum bildiriminde bebeğe isim verilebilir (D-095). Ad zaten
    // önerilmiştir; oyuncu isterse değiştirir, istemezse "Tamam" der.
    final String? bebekId = notice.personId;
    final bool isimVerilebilir = notice.kind == NoticeKind.dogum &&
        bebekId != null &&
        GameScope.of(context).canNameChild(bebekId);
    if (isimVerilebilir && !_isimHazir) {
      _isimHazir = true;
      _isimAlani.text =
          GameScope.of(context).state?.personById(bebekId)?.firstName ?? '';
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  _simge(notice.kind),
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                // Uzun başlık dar ekranda satırı taşırıyordu (Paket 40'ta
                // ölçüldü: 360 px'de 4,4 px taşma). Başlık artık kendi
                // alanına sığar ve gerekirse alt satıra iner.
                Expanded(
                  child: Text(
                    trUpper(notice.title),
                    key: const Key('notice_title'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const KilimDivider(),
            const SizedBox(height: 14),
            // Metin ve etkiler kendi içinde kayar; başlık ve düğmeler
            // sabit kalır. Böylece uzun bir rapor da okunabilir ve
            // "Tamam" düğmesi ekrandan taşmaz.
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _sonuc ?? notice.text,
                      key: const Key('notice_text'),
                      style: theme.textTheme.bodyLarge,
                    ),
                    // Etki yalnızca gerçekten uygulandıysa yazılır.
                    if (_sonuc == null && notice.happinessDelta < 0) ...<Widget>[
                      const SizedBox(height: 12),
                      Text(
                        'Mutluluk ${notice.happinessDelta}',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                    // Gerçekten uygulanmış değişimler (D-074): "bana 5,
                    // kızıma 5" gibi bir sonucun iki satırı da burada.
                    if (_sonuc == null && notice.effects.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 12),
                      EffectChips(
                        key: const Key('notice_effects'),
                        effects: notice.effects,
                      ),
                    ],
                    if (isimVerilebilir) ...<Widget>[
                      const SizedBox(height: 16),
                      Text(
                        'Bebeğin adını sen koyabilirsin.',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        key: const Key('birth_name_field'),
                        controller: _isimAlani,
                        maxLength: ChildNaming.maxLength,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Bebeğin adı',
                          counterText: '',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton.tonal(
                          key: const Key('birth_name_save'),
                          onPressed: () => _isimVer(bebekId),
                          child: const Text('İsmi kaydet'),
                        ),
                      ),
                      if (_isimNotu != null) ...<Widget>[
                        const SizedBox(height: 8),
                        Text(
                          _isimNotu!,
                          key: const Key('birth_name_note'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                    if (_sonuc == null &&
                        notice.kind == NoticeKind.miras) ...<Widget>[
                      const SizedBox(height: 12),
                      if (notice.money > 0)
                        Text(
                          'Cüzdanına ${trMoney(notice.money)} geçti.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      for (final String ad in notice.itemNames)
                        Text('$ad sana kaldı.',
                            style: theme.textTheme.bodyMedium),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            if (katilimSorulacak) ...<Widget>[
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  key: const Key('funeral_attend_katildi'),
                  onPressed: () => _katilimSec(FuneralAttendance.katildi),
                  child: const Text('Cenazeye katıl'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  key: const Key('funeral_attend_katilamadi'),
                  onPressed: () => _katilimSec(FuneralAttendance.katilamadi),
                  child: const Text('Katılamıyorum'),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Cenazeye katılmak ile masraflara katkıda bulunmak ayrı '
                'şeylerdir; ikisini de ayrı ayrı seçeceksin.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ] else if (cenaze) ...<Widget>[
              Text(
                _katilim == FuneralAttendance.katildi
                    ? 'Cenazeye katılıyorsun. Masraflara katkıda bulunmak '
                        'ister misin?'
                    : 'Cenazeye katılamıyorsun. Masraflara katkıda bulunmak '
                        'ister misin?',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              for (final FuneralChoice secim in FuneralChoice.values)
                if (GameScope.of(context).canChooseFuneral(secim)) ...<Widget>[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonal(
                      key: Key('funeral_choice_${secim.name}'),
                      onPressed: () => _cenaze(secim),
                      child: Text(_secenekMetni(context, secim)),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              Text(
                'Katkı bir borç değildir ve mirası etkilemez.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ] else
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('notice_close'),
                  onPressed: _kapat,
                  child: const Text('Tamam'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _secenekMetni(BuildContext context, FuneralChoice secim) {
    final int tutar = GameScope.of(context).funeralAmount(secim);
    switch (secim) {
      case FuneralChoice.tamKatki:
        return 'Katkıda bulun (${trMoney(tutar)})';
      case FuneralChoice.kismiKatki:
        return 'Elinden geldiğince katkıda bulun (${trMoney(tutar)})';
      case FuneralChoice.katkiYok:
        return 'Bu sefer katkıda bulunma';
    }
  }

  static IconData _simge(NoticeKind kind) {
    switch (kind) {
      case NoticeKind.olum:
        return Icons.spa_outlined;
      case NoticeKind.miras:
        return Icons.card_giftcard_outlined;
      case NoticeKind.cenaze:
        return Icons.volunteer_activism_outlined;
      case NoticeKind.okul:
        return Icons.school_rounded;
      case NoticeKind.dogum:
        return Icons.child_friendly_rounded;
      case NoticeKind.burc:
        return Icons.auto_awesome_rounded;
      case NoticeKind.askerlik:
        return Icons.military_tech_rounded;
      case NoticeKind.piyango:
        return Icons.confirmation_number_rounded;
      case NoticeKind.hayvan:
        return Icons.pets_rounded;
      case NoticeKind.aktivite:
        return Icons.celebration_rounded;
      case NoticeKind.bosanma:
        return Icons.heart_broken_outlined;
      case NoticeKind.saglik:
        return Icons.monitor_heart_outlined;
      case NoticeKind.arac:
        return Icons.car_repair_outlined;
      case NoticeKind.banka:
        return Icons.account_balance_outlined;
      case NoticeKind.adli:
        return Icons.gavel_rounded;
      case NoticeKind.arkadaslik:
        return Icons.people_alt_rounded;
      case NoticeKind.kendiIsi:
        return Icons.storefront_rounded;
      case NoticeKind.kariyer:
        return Icons.work_outline;
      case NoticeKind.aileDonum:
        return Icons.celebration_outlined;
    }
  }
}
