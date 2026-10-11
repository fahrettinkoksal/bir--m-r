import 'package:flutter/material.dart';

import '../../domain/features/feature_catalog.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/person.dart';
import '../../domain/models/pregnancy.dart';
import '../../text/turkish_text.dart';
import '../theme/bir_omur_theme.dart';

/// Bekleyen doğumun ekranda görünür hâli (Paket BK/1).
///
/// Gebelik kaydı Paket 26'da yazıldı ama ekranda **yalnızca** o kişinin
/// kartında görünüyordu: Hayat ekranında, İlişkiler ekranında ve yıl
/// özetinde hiçbir iz yoktu; günlüğe düşen tek satır da sonraki yılların
/// satırları arasında kayboluyordu (Q-202). Metin burada tek yerde
/// kurulur, iki ekranda birden kullanılır.
abstract final class PregnancyNotice {
  /// Bekleyen doğumun tam cümlesi; gebelik yoksa `null`.
  ///
  /// Bebek **bir sonraki yaşta** doğar: bu, motorun kendi kuralıdır
  /// (`LifeProgression._applyBirth`), burada ayrı bir süre uydurulmadı.
  /// Diğer ebeveyn kayıttan düşmüşse ya da hayatta değilse motor doğumu
  /// gerçekleştirmiyor; o durumda bebeği söz veren bir cümle yazılmaz.
  static String? sentence(GameState state) {
    // Modül kapalıysa hiçbir ekranda satır yoktur (Paket BL).
    if (!state.featureOn(FeatureId.gebelikGorunurlugu)) return null;
    final Pregnancy? bekleyen = state.pregnancy;
    if (bekleyen == null) return null;

    final Person? diger = state.personById(bekleyen.partnerId);
    if (diger == null || !diger.isAlive) {
      return 'Bekleyen bir doğum var ama bebeğin diğer ebeveyni artık '
          'hayatta değil.';
    }

    final String kim =
        '${trLowerFirst(diger.possessiveFor(state.player.age))} '
        '${diger.firstName}';
    return switch (bekleyen.expecting) {
      ExpectingParty.oyuncu =>
        'Hamilesin. Bebeğin diğer ebeveyni $kim. Bebeğiniz bir sonraki '
            'yaşta doğacak.',
      ExpectingParty.partner =>
        '${trUpperFirst(kim)} hamile. Bebeğiniz bir sonraki yaşta doğacak.',
    };
  }

  /// Üst künyedeki durum satırına giren kısa ek (küçük harfle başlar).
  ///
  /// Durum satırı yalnızca olağandışı durumları yazar; bekleyen doğum da
  /// böyle bir durumdur: bir yıl sürer, sonra hane bir kişi büyür.
  /// Kart ve çevresindeki boşluk çizilsin mi?
  ///
  /// Çağıran ekranlar bunu sorar; modül kapalıyken yalnızca kart değil
  /// kartın etrafındaki boşluk da kalkar (D-032 kalıbı: kapalı modül
  /// ekranda yer tutmaz).
  static bool visible(GameState state) => sentence(state) != null;

  static String? shortLabel(GameState state) {
    if (!state.featureOn(FeatureId.gebelikGorunurlugu)) return null;
    final Pregnancy? bekleyen = state.pregnancy;
    if (bekleyen == null) return null;
    return bekleyen.expecting == ExpectingParty.oyuncu
        ? 'hamilesin'
        : 'bebek yolda';
  }
}

/// Bekleyen doğumu anlatan kart. Gebelik yoksa hiç çizilmez.
///
/// Aynı kart iki ekranda kullanılır; anahtarı çağıran verir, çünkü
/// testler ekrana göre ayrı anahtar arıyor.
class PregnancyCard extends StatelessWidget {
  const PregnancyCard({super.key, required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String? metin = PregnancyNotice.sentence(state);
    if (metin == null) return const SizedBox.shrink();

    const BirOmurAccent aksan = BirOmurAccents.gul;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: aksan.softOf(context),
        borderRadius: BorderRadius.circular(Comic.yaricapBuyuk),
        border: Border.all(color: Comic.konturOf(context), width: Comic.kontur),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.child_friendly_rounded,
            size: 20,
            color: aksan.deepOf(context),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Bebek yolda',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(metin, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
