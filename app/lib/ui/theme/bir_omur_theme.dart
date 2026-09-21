import 'package:flutter/material.dart';

/// Bir Ömür'ün görsel yönü: **modern + ölçülü nostaljik**
/// (`docs/PROTOTYPE_UI.md` §2).
///
/// Sade, okunaklı ve tek elle kullanılabilir bir çağdaş arayüz; nostalji
/// yoğun süsleme yerine sıcak kâğıt tonları, hatıra defteri hissi veren
/// günlük ve ölçülü bir kilim şeridiyle verilir.
///
/// **Renkler bu prototip için seçilmiştir (`prototypeOnly`); kesin marka
/// paleti henüz kararlaştırılmadı** — bkz. `docs/DESIGN_REVIEW_QUEUE.md`
/// **Q-077**. Renk değerleri tek yerde toplandığı için istenirse tek
/// commit'le geri alınabilir.
abstract final class BirOmurColors {
  /// Eskimiş defter kâğıdı. Modern his için önceki tona göre biraz daha
  /// açık ve temiz; sıcaklığı korunur.
  static const Color kagit = Color(0xFFFBF7F0);
  static const Color kagitKoyu = Color(0xFFF1E9DC);

  /// Mürekkep siyahı.
  static const Color murekkep = Color(0xFF221D19);

  /// Nar kırmızısı — ana vurgu. Eski ton (0xFF8C2F39) fazla sönüktü;
  /// canlılığı artırıldı, sıcaklığı korundu.
  static const Color nar = Color(0xFFB53142);
  static const Color narKoyu = Color(0xFF7E1F2C);
  static const Color narAcik = Color(0xFFE2687A);

  /// Çini yeşili — ikincil vurgu.
  static const Color cini = Color(0xFF12897A);
  static const Color ciniKoyu = Color(0xFF0B5E54);

  /// Çini yeşilinin açık tonu — ikincil eylem düğmeleri.
  static const Color ciniAcik = Color(0xFFD5E9E4);

  /// Pirinç sarısı — küçük detaylar ve seçili durum.
  static const Color pirinc = Color(0xFFD69A2B);
  static const Color pirincKoyu = Color(0xFFA9741A);

  /// Alt gezinme çubuğunun sıcak koyu zemini (degrade için iki ton).
  static const Color koyuAhsap = Color(0xFF3D3029);
  static const Color koyuAhsapDip = Color(0xFF2A211C);

  /// Koyu zemin üzerindeki sönük metin/ikon rengi.
  static const Color sonukKrem = Color(0xFFD3C3B1);

  /// Koyu zemin üzerinde okunan açık krem.
  static const Color krem = Color(0xFFFDF6EC);

  static const Color geceMurekkep = Color(0xFF16130F);
  static const Color geceYuzey = Color(0xFF241E19);

  /// Koyu zeminde okunan karakter değeri renkleri.
  ///
  /// Açık temanın çini/pirinç tonları koyu zeminde birbirine yaklaşıyor ve
  /// "iyi" ile "orta" ayırt edilemiyordu.
  static const Color geceCini = Color(0xFF6FC0AE);
  static const Color gecePirinc = Color(0xFFE0B25E);
  static const Color geceUyari = Color(0xFFE98A8A);
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

  /// İkon kutusunun degradesi.
  LinearGradient gradientOf(BuildContext context) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[of(context), deepOf(context)],
      );
}

/// Menülerde kullanılan renk ailesi (`prototypeOnly`, Q-077).
abstract final class BirOmurAccents {
  static const BirOmurAccent nar = BirOmurAccent(
    Color(0xFFB53142),
    Color(0xFFE2687A),
    Color(0xFF7E1F2C),
    Color(0xFFB53142),
  );
  static const BirOmurAccent cini = BirOmurAccent(
    Color(0xFF12897A),
    Color(0xFF4FC3B0),
    Color(0xFF0B5E54),
    Color(0xFF12897A),
  );
  static const BirOmurAccent pirinc = BirOmurAccent(
    Color(0xFFD69A2B),
    Color(0xFFE9BC63),
    Color(0xFFA9741A),
    Color(0xFFC08A2E),
  );
  static const BirOmurAccent mor = BirOmurAccent(
    Color(0xFF7A4FB0),
    Color(0xFFB79AE0),
    Color(0xFF55337F),
    Color(0xFF7A4FB0),
  );
  static const BirOmurAccent mavi = BirOmurAccent(
    Color(0xFF2E6FD9),
    Color(0xFF7FAEF5),
    Color(0xFF1B4894),
    Color(0xFF2E6FD9),
  );
  static const BirOmurAccent yesil = BirOmurAccent(
    Color(0xFF2E9E5B),
    Color(0xFF6FD199),
    Color(0xFF1B6B3C),
    Color(0xFF2E9E5B),
  );
  static const BirOmurAccent turuncu = BirOmurAccent(
    Color(0xFFE0703A),
    Color(0xFFF2A27A),
    Color(0xFFA84C21),
    Color(0xFFE0703A),
  );
  static const BirOmurAccent gul = BirOmurAccent(
    Color(0xFFD6577C),
    Color(0xFFEE93AE),
    Color(0xFF9B3454),
    Color(0xFFD6577C),
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
          primaryContainer: const Color(0xFFF7DDE0),
          onPrimaryContainer: BirOmurColors.narKoyu,
          secondary: BirOmurColors.cini,
          onSecondary: BirOmurColors.krem,
          tertiary: BirOmurColors.pirinc,
          onTertiary: BirOmurColors.murekkep,
          surface: BirOmurColors.kagit,
          surfaceContainerHighest: BirOmurColors.kagitKoyu,
          surfaceContainerHigh: const Color(0xFFF7F1E7),
          onSurface: BirOmurColors.murekkep,
          onSurfaceVariant: const Color(0xFF6B6058),
          outlineVariant: const Color(0xFFDCD0BE),
          // Eylem düğmeleri kâğıt paletiyle uyumlu kalsın.
          secondaryContainer: BirOmurColors.ciniAcik,
          onSecondaryContainer: const Color(0xFF0B4A43),
        ),
      );

  static ThemeData dark() => _build(
        ColorScheme.fromSeed(
          seedColor: BirOmurColors.nar,
          brightness: Brightness.dark,
        ).copyWith(
          primary: BirOmurColors.narAcik,
          onPrimary: const Color(0xFF3A0C14),
          secondary: BirOmurColors.pirinc,
          tertiary: BirOmurColors.geceCini,
          surface: BirOmurColors.geceMurekkep,
          surfaceContainerHighest: BirOmurColors.geceYuzey,
          surfaceContainerHigh: const Color(0xFF2C251F),
          outlineVariant: const Color(0xFF4A4038),
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
        headlineSmall: base.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.6,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.1,
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.42),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: gece ? scheme.surfaceContainerHigh : scheme.surfaceContainerHighest,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.55)),
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
          letterSpacing: -0.2,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        indicatorColor: scheme.primary.withValues(alpha: 0.14),
        elevation: 0,
        labelTextStyle: WidgetStatePropertyAll<TextStyle>(
          base.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 17),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 0,
          // Gölge nötr kalır: renkli gölge, açık zeminli (tonal)
          // düğmelerin çevresinde pembe bir hale bırakıyordu.
          shadowColor: Colors.black.withValues(alpha: 0.30),
          // Metin stili gövde yazı tipinden türetilir; böylece düğmeler de
          // uygulamanın yazı tipini kullanır.
          textStyle: base.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            letterSpacing: 0.1,
          ),
        ).copyWith(
          elevation: WidgetStateProperty.resolveWith<double>(
            (Set<WidgetState> states) =>
                states.contains(WidgetState.pressed) ? 0 : 1.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 17),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          side: BorderSide(
            color: scheme.primary.withValues(alpha: 0.45),
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
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.7)),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.6),
        thickness: 1,
      ),
    );
  }
}
