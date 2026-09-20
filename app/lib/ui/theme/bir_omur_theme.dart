import 'package:flutter/material.dart';

/// Bir Ömür'ün görsel yönü: **modern + ölçülü nostaljik**
/// (`docs/PROTOTYPE_UI.md` §2).
///
/// Sade, okunaklı ve tek elle kullanılabilir bir çağdaş arayüz; nostalji
/// yoğun süsleme yerine sıcak kâğıt tonları, hatıra defteri hissi veren
/// günlük ve ölçülü bir kilim şeridiyle verilir. Renkler bu prototip için
/// seçilmiştir; kesin marka paleti henüz kararlaştırılmadı.
abstract final class BirOmurColors {
  /// Eskimiş defter kâğıdı.
  static const Color kagit = Color(0xFFF6F1E6);
  static const Color kagitKoyu = Color(0xFFEAE2D2);

  /// Mürekkep siyahı.
  static const Color murekkep = Color(0xFF241F1B);

  /// Nar kırmızısı — ana vurgu.
  static const Color nar = Color(0xFF8C2F39);

  /// Çini yeşili — ikincil vurgu.
  static const Color cini = Color(0xFF1F6F63);

  /// Çini yeşilinin açık tonu — ikincil eylem düğmeleri.
  static const Color ciniAcik = Color(0xFFD9E6E1);

  /// Pirinç sarısı — küçük detaylar.
  static const Color pirinc = Color(0xFFC08A2E);

  /// Alt gezinme çubuğunun sıcak koyu zemini.
  static const Color koyuAhsap = Color(0xFF3B2E27);

  /// Koyu zemin üzerindeki sönük metin/ikon rengi.
  static const Color sonukKrem = Color(0xFFCDBBA9);

  static const Color geceMurekkep = Color(0xFF16130F);
  static const Color geceYuzey = Color(0xFF221D18);

  /// Koyu zeminde okunan karakter değeri renkleri.
  ///
  /// Açık temanın çini/pirinç tonları koyu zeminde birbirine yaklaşıyor ve
  /// "iyi" ile "orta" ayırt edilemiyordu.
  static const Color geceCini = Color(0xFF6FC0AE);
  static const Color gecePirinc = Color(0xFFE0B25E);
  static const Color geceUyari = Color(0xFFE98A8A);
}

abstract final class BirOmurTheme {
  static ThemeData light() => _build(
        ColorScheme.fromSeed(
          seedColor: BirOmurColors.nar,
          brightness: Brightness.light,
        ).copyWith(
          primary: BirOmurColors.nar,
          secondary: BirOmurColors.cini,
          tertiary: BirOmurColors.pirinc,
          surface: BirOmurColors.kagit,
          surfaceContainerHighest: BirOmurColors.kagitKoyu,
          onSurface: BirOmurColors.murekkep,
          // Eylem düğmeleri kâğıt paletiyle uyumlu kalsın.
          secondaryContainer: BirOmurColors.ciniAcik,
          onSecondaryContainer: BirOmurColors.murekkep,
        ),
      );

  static ThemeData dark() => _build(
        ColorScheme.fromSeed(
          seedColor: BirOmurColors.nar,
          brightness: Brightness.dark,
        ).copyWith(
          secondary: BirOmurColors.pirinc,
          surface: BirOmurColors.geceMurekkep,
          surfaceContainerHighest: BirOmurColors.geceYuzey,
        ),
      );

  static ThemeData _build(ColorScheme scheme) {
    final ThemeData base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        headlineSmall: base.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.42),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerHighest,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.55)),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
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
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          // Metin stili gövde yazı tipinden türetilir; böylece düğmeler de
          // uygulamanın yazı tipini kullanır.
          textStyle: base.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: base.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.6),
        thickness: 1,
      ),
    );
  }
}
