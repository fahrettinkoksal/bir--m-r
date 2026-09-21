import 'package:flutter/material.dart';

/// Bir Ömür'ün görsel yönü: **canlı, çağdaş ve yüksek karşıtlıklı**.
///
/// Paket 16'da palet baştan kuruldu. Önceki sürüm soluk bir "eski kâğıt"
/// zemini üzerine her satırı ayrı bir pastel tonla boyuyordu; bu hem
/// karşıtlığı düşürüyor hem de ekranı tek tip, karaktersiz gösteriyordu.
/// Yeni yön şudur:
///
/// * **Zemin sakin, renk vurguda.** Gövde neredeyse renksiz (açık temada
///   beyaz kart / soğuk gri zemin, koyu temada mürekkep moru); renk
///   ikonlarda, rozetlerde ve başlık şeritlerinde doygun biçimde çıkar.
/// * **Üst başlık ve alt çubuk koyu bir degrade taşır.** Ekranın üstü ve
///   altı çerçeve gibi durur, içerik bu çerçevenin arasında nefes alır.
/// * **Renkler doygun.** Nar, çini ve pirinç isimleri korundu ama tonlar
///   belirgin biçimde canlandırıldı.
///
/// **Renkler bu prototip için seçilmiştir (`prototypeOnly`); kesin marka
/// paleti henüz kararlaştırılmadı** — bkz. `docs/DESIGN_REVIEW_QUEUE.md`
/// **Q-077** ve **Q-084**. Renk değerleri tek yerde toplandığı için
/// istenirse tek commit'le geri alınabilir.
abstract final class BirOmurColors {
  // -----------------------------------------------------------------
  // Gövde zeminleri
  // -----------------------------------------------------------------

  /// Açık temanın zemini: hafif soğuk, neredeyse beyaz.
  static const Color zemin = Color(0xFFF1F2F7);

  /// Açık temada kartların zemini.
  static const Color kart = Color(0xFFFFFFFF);

  /// Açık temada ikinci derece yüzey (rozet, ayırıcı dolgusu).
  static const Color yumusakZemin = Color(0xFFE9EAF2);

  /// Mürekkep: ana metin rengi.
  static const Color murekkep = Color(0xFF14131F);

  /// İkincil metin.
  static const Color sonukMurekkep = Color(0xFF6B6883);

  /// İnce çizgi.
  static const Color cizgi = Color(0xFFE2E2ED);

  // -----------------------------------------------------------------
  // Koyu tema
  // -----------------------------------------------------------------

  static const Color geceZemin = Color(0xFF0C0B15);
  static const Color geceKart = Color(0xFF191826);
  static const Color geceYumusak = Color(0xFF221F31);
  static const Color geceCizgi = Color(0xFF2F2C40);
  static const Color geceMetin = Color(0xFFF2F1F8);
  static const Color geceSonuk = Color(0xFFA09DB6);

  // -----------------------------------------------------------------
  // Kimlik renkleri
  // -----------------------------------------------------------------

  /// Nar kırmızısı — ana vurgu. Doygunluğu belirgin biçimde artırıldı.
  static const Color nar = Color(0xFFE4224B);
  static const Color narKoyu = Color(0xFFA30F35);
  static const Color narAcik = Color(0xFFFF5E80);

  /// Çini turkuazı — ikincil vurgu.
  static const Color cini = Color(0xFF00A99B);
  static const Color ciniKoyu = Color(0xFF00776C);
  static const Color ciniAcik = Color(0xFF3FD8C3);

  /// Pirinç sarısı — para, seçili durum ve küçük detaylar.
  static const Color pirinc = Color(0xFFF5A623);
  static const Color pirincKoyu = Color(0xFFC97C00);
  static const Color pirincAcik = Color(0xFFFFC85C);

  // -----------------------------------------------------------------
  // Koyu çerçeve: üst başlık ve alt gezinme çubuğu
  // -----------------------------------------------------------------

  /// Üst karakter başlığının degradesi (sol üst → sağ alt).
  static const Color basligUst = Color(0xFF3B1E86);
  static const Color basligAlt = Color(0xFFB02A63);

  /// Alt gezinme çubuğunun degradesi.
  static const Color cubukUst = Color(0xFF1D1436);
  static const Color cubukAlt = Color(0xFF120B22);

  /// Koyu zemin üzerindeki sönük metin/ikon rengi.
  static const Color sonukKrem = Color(0xFFB9B2D4);

  /// Koyu zemin üzerinde okunan açık ton.
  static const Color krem = Color(0xFFFFFFFF);

  // -----------------------------------------------------------------
  // Karakter değeri renkleri
  // -----------------------------------------------------------------
  //
  // Koyu başlık şeridinin üzerinde de okunabilsin diye parlak tutulur.

  static const Color degerDusuk = Color(0xFFFF5470);
  static const Color degerOrta = Color(0xFFFFB524);
  static const Color degerYuksek = Color(0xFF17D4B4);

  /// Koyu zeminde okunan karşılıkları.
  static const Color geceUyari = Color(0xFFFF7A90);
  static const Color gecePirinc = Color(0xFFFFC55C);
  static const Color geceCini = Color(0xFF4EE3C6);
}

/// Menü satırlarının ve rozetlerin renk kimliği.
///
/// Her menü kendi rengini taşır; böylece uzun listelerde göz aradığını
/// daha çabuk bulur. Açık ve koyu tema için ayrı tonlar tutulur, çünkü
/// koyu zeminde aynı renk okunmuyor.
@immutable
class BirOmurAccent {
  const BirOmurAccent(this._light, this._dark, this._lightDeep, this._darkDeep);

  final Color _light;
  final Color _dark;
  final Color _lightDeep;
  final Color _darkDeep;

  /// Zemine göre ana ton.
  Color of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _dark : _light;

  /// Degradenin koyu ucu.
  Color deepOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _darkDeep : _lightDeep;

  /// İkon kutusunun ve başlık şeridinin degradesi.
  LinearGradient gradientOf(BuildContext context) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[of(context), deepOf(context)],
      );

  /// Bölüm başlığı kartının degradesi.
  ///
  /// Başlık kartında yazı her zaman beyazdır, bu yüzden degrade temadan
  /// bağımsız olarak açık temanın doygun tonlarını kullanır. Koyu uç
  /// tam `deep` değil, ana rengin yarı yolu kadardır: tam koyu uç
  /// turuncu gibi renklerde kahverengiye düşüyordu.
  LinearGradient get heroGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          _light,
          Color.lerp(_light, _lightDeep, 0.5)!,
        ],
      );

  /// Başlık kartının gölgesi için ana ton.
  Color get heroShadow => _light;

  /// Rozet ve yumuşak zeminler için rengin çok açık karşılığı.
  Color softOf(BuildContext context) {
    final bool gece = Theme.of(context).brightness == Brightness.dark;
    return of(context).withValues(alpha: gece ? 0.18 : 0.12);
  }
}

/// Menülerde kullanılan renk ailesi (`prototypeOnly`, Q-077/Q-084).
///
/// Tonlar canlı seçildi: soluk pastel bir dizi yerine doygun, birbirinden
/// açıkça ayrılan sekiz renk.
abstract final class BirOmurAccents {
  static const BirOmurAccent nar = BirOmurAccent(
    Color(0xFFE4224B),
    Color(0xFFFF5E80),
    Color(0xFFA30F35),
    Color(0xFFC81E45),
  );
  static const BirOmurAccent cini = BirOmurAccent(
    Color(0xFF00A99B),
    Color(0xFF2FD3BE),
    Color(0xFF00695F),
    Color(0xFF009C8C),
  );
  static const BirOmurAccent pirinc = BirOmurAccent(
    Color(0xFFF5A623),
    Color(0xFFFFC24D),
    Color(0xFFC06A00),
    Color(0xFFE09A1E),
  );
  static const BirOmurAccent mor = BirOmurAccent(
    Color(0xFF7C4DFF),
    Color(0xFFA98BFF),
    Color(0xFF4A19CC),
    Color(0xFF7B4DE8),
  );
  static const BirOmurAccent mavi = BirOmurAccent(
    Color(0xFF2D7FF9),
    Color(0xFF6BA9FF),
    Color(0xFF0B4CC0),
    Color(0xFF2F7DE0),
  );
  static const BirOmurAccent yesil = BirOmurAccent(
    Color(0xFF16B364),
    Color(0xFF48D992),
    Color(0xFF07753F),
    Color(0xFF17A45C),
  );
  static const BirOmurAccent turuncu = BirOmurAccent(
    Color(0xFFFF6A2B),
    Color(0xFFFF9260),
    Color(0xFFC23E00),
    Color(0xFFE85F24),
  );
  static const BirOmurAccent gul = BirOmurAccent(
    Color(0xFFF0479B),
    Color(0xFFFF7CBC),
    Color(0xFFB30F68),
    Color(0xFFDB3F8C),
  );
}

abstract final class BirOmurTheme {
  static ThemeData light() => _build(
        ColorScheme.fromSeed(
          seedColor: BirOmurColors.nar,
          brightness: Brightness.light,
        ).copyWith(
          primary: BirOmurColors.nar,
          onPrimary: BirOmurColors.krem,
          primaryContainer: const Color(0xFFFFE0E6),
          onPrimaryContainer: BirOmurColors.narKoyu,
          secondary: BirOmurColors.cini,
          onSecondary: BirOmurColors.krem,
          secondaryContainer: const Color(0xFFD3F6F0),
          onSecondaryContainer: const Color(0xFF00554D),
          tertiary: BirOmurColors.pirinc,
          onTertiary: BirOmurColors.murekkep,
          surface: BirOmurColors.zemin,
          surfaceContainerHighest: BirOmurColors.kart,
          surfaceContainerHigh: BirOmurColors.kart,
          surfaceContainer: BirOmurColors.yumusakZemin,
          onSurface: BirOmurColors.murekkep,
          onSurfaceVariant: BirOmurColors.sonukMurekkep,
          outlineVariant: BirOmurColors.cizgi,
          error: const Color(0xFFE02B4F),
        ),
      );

  static ThemeData dark() => _build(
        ColorScheme.fromSeed(
          seedColor: BirOmurColors.nar,
          brightness: Brightness.dark,
        ).copyWith(
          primary: BirOmurColors.narAcik,
          onPrimary: const Color(0xFF3A0011),
          primaryContainer: const Color(0xFF5E0C26),
          onPrimaryContainer: const Color(0xFFFFD9E0),
          secondary: BirOmurColors.ciniAcik,
          onSecondary: const Color(0xFF00322C),
          secondaryContainer: const Color(0xFF00453E),
          onSecondaryContainer: const Color(0xFFB8F5EB),
          tertiary: BirOmurColors.pirincAcik,
          onTertiary: const Color(0xFF3A2400),
          surface: BirOmurColors.geceZemin,
          surfaceContainerHighest: BirOmurColors.geceKart,
          surfaceContainerHigh: BirOmurColors.geceKart,
          surfaceContainer: BirOmurColors.geceYumusak,
          onSurface: BirOmurColors.geceMetin,
          onSurfaceVariant: BirOmurColors.geceSonuk,
          outlineVariant: BirOmurColors.geceCizgi,
          error: BirOmurColors.geceUyari,
        ),
      );

  static ThemeData _build(ColorScheme scheme) {
    final bool gece = scheme.brightness == Brightness.dark;
    final ThemeData base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        // Başlıklar iri ve sıkı: ekranın hiyerarşisi yazı boyundan okunur.
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: -1,
        ),
        headlineSmall: base.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: -0.8,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.45),
        bodySmall: base.textTheme.bodySmall?.copyWith(height: 1.4),
        // Küçük etiketler harf aralıklı ve kalın: rozet dili.
        labelSmall: base.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerHighest,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: gece ? 0.9 : 0.75),
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: scheme.onSurface,
          letterSpacing: -0.3,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        indicatorColor: scheme.primary.withValues(alpha: 0.16),
        elevation: 0,
        labelTextStyle: WidgetStatePropertyAll<TextStyle>(
          base.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 17),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          // Düğmeler düz: gölge, açık zeminli (tonal) düğmelerin
          // çevresinde gri bir halka bırakıyordu.
          elevation: 0,
          shadowColor: Colors.transparent,
          textStyle: base.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            letterSpacing: 0,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          side: BorderSide(
            color: scheme.primary.withValues(alpha: 0.5),
            width: 1.6,
          ),
          foregroundColor: scheme.primary,
          textStyle: base.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: base.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
      ),
    );
  }
}
