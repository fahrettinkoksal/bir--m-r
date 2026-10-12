import 'package:flutter/material.dart';

import '../../domain/interaction/elder_support.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/person.dart';
import '../../state/game_controller.dart';
import '../../state/game_scope.dart';
import '../../text/turkish_text.dart';
import '../theme/bir_omur_theme.dart';

/// Yaşlılıkta "kim yanında?" kartı (Paket CJ).
///
/// **Neden Hayat ekranında.** Yaşlı ebeveyn bakımı kişinin kartında
/// duruyor (`person_detail_sheet`), çünkü konu o kişi. Burada konu
/// **oyuncunun kendi yılı**: bekleyen doğum kartı gibi (Paket BK/1)
/// günlüğün üstünde durur, bir yıl sürer ve kararı verilince kapanır.
///
/// Çizilmeyen kapı gösterilmez ama **gerekçesi yazılı** kapı gösterilir
/// (D-038): gücü yetmeyen çocuk için düğme pasif kalır ve altına sebebi
/// yazılır.
class ElderSupportCard extends StatefulWidget {
  const ElderSupportCard({super.key});

  /// Kart ve çevresindeki boşluk çizilsin mi?
  ///
  /// Modül kapalıyken, yaş gelmemişken ya da sağlık iyiyken hiç yer
  /// tutmaz (D-032 kalıbı).
  static bool visible(GameState state) => ElderSupport.needsSupport(state);

  @override
  State<ElderSupportCard> createState() => _ElderSupportCardState();
}

class _ElderSupportCardState extends State<ElderSupportCard> {
  String? _sonuc;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final GameController controller = GameScope.of(context);
    final GameState state = controller.state!;
    if (!ElderSupportCard.visible(state)) return const SizedBox.shrink();

    final List<Person> yardimcilar = controller.elderSupportHelpers;
    final ({
      int cost,
      int childShare,
      int outOfPocket,
      List<String> childNames
    })? hesap = controller.elderSupportCost();
    final bool kararVerildi = controller.elderSupportDecided;
    const BirOmurAccent aksan = BirOmurAccents.gul;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: aksan.softOf(context),
        borderRadius: BorderRadius.circular(Comic.yaricapBuyuk),
        border: Border.all(color: Comic.konturOf(context), width: Comic.kontur),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.volunteer_activism_rounded,
                  size: 20, color: aksan.deepOf(context)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Bu yıl kim yanında?',
                  key: const Key('elder_support_title'),
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _durumSatiri(state, yardimcilar, hesap),
            key: const Key('elder_support_line'),
            style: theme.textTheme.bodySmall,
          ),
          if (!kararVerildi) ...<Widget>[
            const SizedBox(height: 10),
            for (final ElderSupportChoice secim in ElderSupportChoice.values)
              _KapiSatiri(
                secim: secim,
                engel: controller.elderSupportBlockReason(secim),
                onBas: () => setState(() {
                  _sonuc = controller.decideElderSupport(secim)?.text;
                }),
              ),
          ],
          if (_sonuc != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              _sonuc!,
              key: const Key('elder_support_result'),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  /// Kartın durum satırı: yılın gerçeği, geçmişin sayacı.
  String _durumSatiri(
    GameState state,
    List<Person> yardimcilar,
    ({
      int cost,
      int childShare,
      int outOfPocket,
      List<String> childNames
    })? hesap,
  ) {
    final List<String> parcalar = <String>[];
    // **Kapının gerekçesi burada tekrarlanmaz.** Ekran dökümü (Paket
    // CL) bu kartı 70 yaşında, kimsesiz bir hayatta bastı ve
    // "Yanında olabilecek kimse yok." cümlesi üst üste iki kez
    // çıkıyordu: bir kez durum satırında, bir kez de düğmenin altında.
    // Durum satırı artık yalnızca **olanı** yazıyor; yokluğu söyleyen
    // yer kapının kendi gerekçesi (D-038).
    parcalar.add(yardimcilar.isEmpty
        ? 'Bu yılı çevirmek eskisi gibi kolay değil.'
        : 'Bu yılı çevirmek eskisi gibi kolay değil. Yanında '
            '${yardimcilar.map((Person p) => p.firstName).join(', ')} '
            'olabilir.');
    if (hesap != null) {
      parcalar.add('Yıllık bakım masrafı ${trMoney(hesap.cost)}.');
      if (hesap.childShare > 0) {
        parcalar.add(
          '${hesap.childNames.join(' ve ')} ${trMoney(hesap.childShare)} '
          'kadarını üstlenebilir; cebinden ${trMoney(hesap.outOfPocket)} '
          'çıkar.',
        );
      }
    }
    final int destekliYil = state.elderSupport.yearsSupported;
    final int yalnizYil = state.elderSupport.yearsAlone;
    if (destekliYil > 0) {
      parcalar.add('Şimdiye kadar $destekliYil yıl aileden destek gördün.');
    }
    if (yalnizYil > 0) {
      parcalar.add('$yalnizYil yılı kimseye yüklenmeden çevirdin.');
    }
    final int gelen = state.elderSupport.receivedTotal;
    if (gelen > 0) {
      parcalar.add(
        'Çocuklarının bugüne kadar üstlendiği toplam ${trMoney(gelen)}.',
      );
    }
    final int odenen = state.elderSupport.paidTotal;
    if (odenen > 0) {
      parcalar.add('Kendi cebinden ödediğin toplam ${trMoney(odenen)}.');
    }
    return parcalar.join(' ');
  }
}

/// Tek bir kapı: düğme ve (varsa) gerekçesi.
class _KapiSatiri extends StatelessWidget {
  const _KapiSatiri({
    required this.secim,
    required this.engel,
    required this.onBas,
  });

  final ElderSupportChoice secim;
  final String engel;
  final VoidCallback onBas;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              key: Key('elder_support_${secim.name}'),
              onPressed: engel.isEmpty ? onBas : null,
              child: Text(secim.label),
            ),
          ),
          if (engel.isNotEmpty) ...<Widget>[
            const SizedBox(height: 3),
            Text(
              engel,
              key: Key('elder_support_block_${secim.name}'),
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
