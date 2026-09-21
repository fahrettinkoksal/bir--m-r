import 'package:flutter/material.dart';

/// Bir Ömür'ün görsel yönü: **çizgi roman / çıkartma**.
///
/// Paket 19'da tasarım üçüncü kez ve bu sefer baştan kuruldu. Önceki iki
/// deneme de "yapay zekâ işi gibi" bulundu; ikisinin de ortak yanı,
/// herhangi bir uygulamaya yapıştırılabilecek **genel** bir arayüz dili
/// olmasıydı: degradeler, yumuşak gölgeler, ince çizgiler, hazır ikonlar.
///
/// Bu sürümün kuralları bilerek serttir ve hepsi o genel dili kırmak
/// içindir:
///
/// 1. **Degrade yok.** Her yüzey tek ve düz bir renk.
/// 2. **Her yüzeyin kalın mürekkep konturu var.** Kart, düğme, rozet,
///    ikon kutusu — hepsi çizilmiş gibi durur.
/// 3. **Gölge bulanık değil, kaydırılmıştır.** `blurRadius: 0`; kartlar
///    kâğıda yapıştırılmış çıkartma gibi durur.
/// 4. **Düğmeler basınca gerçekten çöker.** Gölge kadar aşağı iner.
/// 5. **Yazı tipi oyunun kendi sesidir.** Baloo 2 (kalın, yuvarlak) ve
///    el yazısı aksanlar için Patrick Hand.
/// 6. **Renkler afiş rengidir:** doygun, düz, birbirinden açıkça ayrı.
///
/// **Renkler bu prototip için seçilmiştir (`prototypeOnly`); kesin marka
/// paleti henüz kararlaştırılmadı** — bkz. `docs/DESIGN_REVIEW_QUEUE.md`
/// **Q-087**.
abstract final class BirOmurColors {
  // -----------------------------------------------------------------
  // Kâğıt ve mürekkep
  // -----------------------------------------------------------------

  /// Açık temanın zemini: sıcak, hafif sarımsı bir çizim kâğıdı.
  static const Color kagit = Color(0xFFFFF3E2);

  /// Kâğıdın gölgeli tonu (doku, oyuk alanlar).
  static const Color kagitKoyu = Color(0xFFF3E3C8);

  /// Kartların zemini.
  static const Color kart = Color(0xFFFFFFFF);

  /// Mürekkep: bütün konturlar, gölgeler ve ana yazı bu renktedir.
  static const Color murekkep = Color(0xFF2A2233);

  /// İkincil yazı.
  static const Color soluk = Color(0xFF7A6E86);

  // -----------------------------------------------------------------
  // Gece
  // -----------------------------------------------------------------

  /// Koyu temada kontur kartın kendisinden **daha koyudur**; çizgi
  /// böylece koyu zeminde de görünür.
  static const Color geceZemin = Color(0xFF1B1526);
  static const Color geceKart = Color(0xFF2F2742);
  static const Color geceMurekkep = Color(0xFF0D0A14);
  static const Color geceMetin = Color(0xFFF8F1E6);
  static const Color geceSoluk = Color(0xFFB3A6C4);

  // -----------------------------------------------------------------
  // Afiş renkleri
  // -----------------------------------------------------------------

  static const Color kirmizi = Color(0xFFFF4D5B);
  static const Color kirmiziKoyu = Color(0xFFD42A3C);
  static const Color turuncu = Color(0xFFFF9327);
  static const Color turuncuKoyu = Color(0xFFE0700A);
  static const Color sari = Color(0xFFFFC93C);
  static const Color sariKoyu = Color(0xFFDFA200);
  static const Color yesil = Color(0xFF46C97A);
  static const Color yesilKoyu = Color(0xFF229A55);
  static const Color turkuaz = Color(0xFF2FC4C9);
  static const Color turkuazKoyu = Color(0xFF10999E);
  static const Color mavi = Color(0xFF4E8CFF);
  static const Color maviKoyu = Color(0xFF2765DC);
  static const Color mor = Color(0xFF9B6BFF);
  static const Color morKoyu = Color(0xFF7343E0);
  static const Color pembe = Color(0xFFFF6FB0);
  static const Color pembeKoyu = Color(0xFFE0468C);

  /// Koyu zemin üzerinde okunan açık ton.
  static const Color krem = Color(0xFFFFF8EC);

  // -----------------------------------------------------------------
  // Karakter değeri renkleri
  // -----------------------------------------------------------------

  static const Color degerDusuk = kirmizi;
  static const Color degerOrta = sari;
  static const Color degerYuksek = yesil;
}

/// Çizgi roman düzeninin ölçüleri.
///
/// Tek yerde durur; kalınlık ya da gölge derinliği değiştirilecekse
/// bütün ekranlar aynı anda değişir.
abstract final class Comic {
  /// Kontur kalınlığı.
  static const double kontur = 2.5;

  /// İnce kontur (küçük rozetler).
  static const double inceKontur = 2;

  /// Gölgenin kaydırma miktarı.
  static const double golge = 4;

  /// Küçük ögelerin gölgesi.
  static const double kucukGolge = 3;

  static const double yaricapBuyuk = 22;
  static const double yaricap = 16;
  static const double yaricapKucuk = 12;

  /// Zeminin üzerindeki konturun rengi.
  static Color konturOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? BirOmurColors.geceMurekkep
          : BirOmurColors.murekkep;
}

/// Bir menünün / bölümün rengi.
///
/// Afiş renkleri koyu zeminde de aynı kaldığı için tek ton yeter: kontur
/// zaten her zaman mürekkeptir ve rengi çerçeveler.
@immutable
class BirOmurAccent {
  const BirOmurAccent(this.color, this.deep);

  /// Düz dolgu rengi.
  final Color color;

  /// Aynı rengin koyu tonu: basılı durum ve yazı için.
  final Color deep;

  Color of(BuildContext context) => color;
  Color deepOf(BuildContext context) => deep;

  /// Rengin kâğıt üzerindeki çok açık tonu (rozet zemini).
  Color softOf(BuildContext context) => Color.alphaBlend(
        color.withValues(alpha: 0.22),
        Theme.of(context).brightness == Brightness.dark
            ? BirOmurColors.geceKart
            : BirOmurColors.kart,
      );

  /// Bu renkli zeminin üzerine yazılacak metnin rengi.
  ///
  /// Sarı gibi açık renklerde beyaz okunmuyor; mürekkep kullanılır.
  Color get onColor => color.computeLuminance() > 0.55
      ? BirOmurColors.murekkep
      : BirOmurColors.krem;
}

/// Menülerde kullanılan renk ailesi (`prototypeOnly`, Q-087).
abstract final class BirOmurAccents {
  static const BirOmurAccent nar =
      BirOmurAccent(BirOmurColors.kirmizi, BirOmurColors.kirmiziKoyu);
  static const BirOmurAccent cini =
      BirOmurAccent(BirOmurColors.turkuaz, BirOmurColors.turkuazKoyu);
  static const BirOmurAccent pirinc =
      BirOmurAccent(BirOmurColors.sari, BirOmurColors.sariKoyu);
  static const BirOmurAccent mor =
      BirOmurAccent(BirOmurColors.mor, BirOmurColors.morKoyu);
  static const BirOmurAccent mavi =
      BirOmurAccent(BirOmurColors.mavi, BirOmurColors.maviKoyu);
  static const BirOmurAccent yesil =
      BirOmurAccent(BirOmurColors.yesil, BirOmurColors.yesilKoyu);
  static const BirOmurAccent turuncu =
      BirOmurAccent(BirOmurColors.turuncu, BirOmurColors.turuncuKoyu);
  static const BirOmurAccent gul =
      BirOmurAccent(BirOmurColors.pembe, BirOmurColors.pembeKoyu);
}

abstract final class BirOmurTheme {
  /// Arayüzün yazı tipi.
  static const String yaziTipi = 'Baloo2';

  /// El yazısı aksanlar.
  static const String elYazisi = 'PatrickHand';

  static ThemeData light() => _build(
        const ColorScheme.light(
          primary: BirOmurColors.kirmizi,
          onPrimary: BirOmurColors.krem,
          primaryContainer: Color(0xFFFFDCDF),
          onPrimaryContainer: BirOmurColors.kirmiziKoyu,
          secondary: BirOmurColors.turkuaz,
          onSecondary: BirOmurColors.krem,
          secondaryContainer: Color(0xFFCFF3F4),
          onSecondaryContainer: BirOmurColors.turkuazKoyu,
          tertiary: BirOmurColors.sari,
          onTertiary: BirOmurColors.murekkep,
          surface: BirOmurColors.kagit,
          onSurface: BirOmurColors.murekkep,
          onSurfaceVariant: BirOmurColors.soluk,
          surfaceContainerHighest: BirOmurColors.kart,
          surfaceContainerHigh: BirOmurColors.kart,
          surfaceContainer: BirOmurColors.kagitKoyu,
          outline: BirOmurColors.murekkep,
          outlineVariant: BirOmurColors.murekkep,
          error: BirOmurColors.kirmiziKoyu,
          onError: BirOmurColors.krem,
        ),
      );

  static ThemeData dark() => _build(
        const ColorScheme.dark(
          primary: BirOmurColors.kirmizi,
          onPrimary: BirOmurColors.krem,
          primaryContainer: Color(0xFF5B1C26),
          onPrimaryContainer: Color(0xFFFFD6DA),
          secondary: BirOmurColors.turkuaz,
          onSecondary: BirOmurColors.murekkep,
          secondaryContainer: Color(0xFF134A4C),
          onSecondaryContainer: Color(0xFFBDF0F1),
          tertiary: BirOmurColors.sari,
          onTertiary: BirOmurColors.murekkep,
          surface: BirOmurColors.geceZemin,
          onSurface: BirOmurColors.geceMetin,
          onSurfaceVariant: BirOmurColors.geceSoluk,
          surfaceContainerHighest: BirOmurColors.geceKart,
          surfaceContainerHigh: BirOmurColors.geceKart,
          surfaceContainer: Color(0xFF261F35),
          outline: BirOmurColors.geceMurekkep,
          outlineVariant: BirOmurColors.geceMurekkep,
          error: BirOmurColors.kirmizi,
          onError: BirOmurColors.krem,
        ),
      );

  static ThemeData _build(ColorScheme scheme) {
    final ThemeData base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: yaziTipi,
      scaffoldBackgroundColor: scheme.surface,
    );

    // Baloo 2'nin kendi satır yüksekliği geniş; başlıklarda sıkılaştırılır.
    TextStyle s(double size, FontWeight w, {double h = 1.2, double ls = 0}) =>
        TextStyle(
          fontFamily: yaziTipi,
          fontSize: size,
          fontWeight: w,
          height: h,
          letterSpacing: ls,
          color: scheme.onSurface,
        );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        displaySmall: s(38, FontWeight.w800, h: 1.05),
        headlineMedium: s(29, FontWeight.w800, h: 1.1),
        headlineSmall: s(25, FontWeight.w800, h: 1.1),
        titleLarge: s(21, FontWeight.w700, h: 1.15),
        titleMedium: s(17, FontWeight.w700, h: 1.2),
        titleSmall: s(15, FontWeight.w600, h: 1.2),
        bodyLarge: s(16.5, FontWeight.w400, h: 1.45),
        bodyMedium: s(15, FontWeight.w400, h: 1.45),
        bodySmall: s(13.5, FontWeight.w400, h: 1.4),
        labelLarge: s(15, FontWeight.w700),
        labelMedium: s(13, FontWeight.w700),
        labelSmall: s(11.5, FontWeight.w700, ls: 0.4),
      ),
      // Material'ın kendi kartı kullanılmaz; her kart ComicCard'dır.
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerHighest,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Comic.yaricapBuyuk),
          side: BorderSide(color: scheme.outline, width: Comic.kontur),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: s(21, FontWeight.w800),
      ),
      // Tema düğmeleri yalnızca yardımcı yerlerde kalır; ana eylemler
      // StickerButton kullanır.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Comic.yaricap),
            side: BorderSide(color: scheme.outline, width: Comic.kontur),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
          textStyle: s(16, FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Comic.yaricap),
          ),
          side: BorderSide(color: scheme.outline, width: Comic.kontur),
          foregroundColor: scheme.onSurface,
          textStyle: s(16, FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.onSurface,
          textStyle: s(15, FontWeight.w700),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        labelStyle: s(13, FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide(color: scheme.outline, width: Comic.inceKontur),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          side: BorderSide(color: scheme.outline, width: Comic.kontur),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Comic.yaricapBuyuk),
          side: BorderSide(color: scheme.outline, width: Comic.kontur + 0.5),
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.outline, thickness: 2),
    );
  }
}
