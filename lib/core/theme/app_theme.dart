import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tripsfactory/core/services/preferences_service.dart';
import 'package:tripsfactory/core/theme/tripsfactory_design_tokens.dart';
import 'package:tripsfactory/core/config/brand_config.dart';

// --- App font: configurable via BrandConfig for white-labeling ---
const String kAppFontFamily = BrandConfig.fontFamily;

enum AppThemeMode {
  tripsfactoryDark, // Deep, modern dark
  tripsfactoryLight, // Clean, crisp light
  desertGold, // Warm/Premium (the original "desert" look)
  oasisGreen, // Desert look, light green palette
  skylineBlue, // Desert look, light blue palette
  limestoneGray, // Desert look, light grey palette
  midnightPurple, // Modern/Bold
  oceanTeal, // Fresh/Calm
  steelGray, // Minimal key
}

class ThemeNotifier extends StateNotifier<AppThemeMode> {
  final PreferencesService _prefsService;
  static const String _themeKey = 'app_theme_mode';

  /// White-label seam: the theme each fork ships as default on first launch.
  static const AppThemeMode defaultThemeMode = AppThemeMode.oasisGreen;

  ThemeNotifier(this._prefsService) : super(defaultThemeMode) {
    _loadTheme();
  }

  void _loadTheme() async {
    try {
      final savedTheme = await _prefsService.getString(_themeKey);
      if (savedTheme != null) {
        final themeMode = AppThemeMode.values.firstWhere(
          (mode) => mode.name == savedTheme,
          orElse: () => defaultThemeMode,
        );
        // Honor the fork's supported list: if a trimmed fork no longer includes
        // the persisted theme, fall back to the default.
        state = AppTheme.supportedThemes.contains(themeMode)
            ? themeMode
            : defaultThemeMode;
      }
    } catch (e) {
      // Keep default
    }
  }

  Future<void> setTheme(AppThemeMode mode) async {
    if (!AppTheme.supportedThemes.contains(mode)) return;
    state = mode;
    await _prefsService.setString(_themeKey, mode.name);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeMode>((ref) {
  final prefsService = ref.watch(preferencesServiceProvider);
  return ThemeNotifier(prefsService);
});

class AppTheme {
  // --- Modern Typography Hierarchy ---
  static TextTheme _buildTextTheme(
    TextTheme base,
    Color color, [
    String fontFamily = kAppFontFamily,
  ]) {
    try {
      final googleTextTheme = GoogleFonts.getTextTheme(fontFamily, base);
      return googleTextTheme
          .apply(bodyColor: color, displayColor: color)
          .copyWith(
            displayLarge: googleTextTheme.displayLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -1.0,
            ),
            displayMedium: googleTextTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
            displaySmall: googleTextTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            headlineLarge: googleTextTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
            headlineMedium: googleTextTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            headlineSmall: googleTextTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            titleLarge: googleTextTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
            titleMedium: googleTextTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
            titleSmall: googleTextTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
            ),
            bodyLarge: googleTextTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w400,
              height: 1.6,
            ),
            bodyMedium: googleTextTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w400,
              height: 1.6,
            ),
            labelLarge: googleTextTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          );
    } catch (_) {
      return base.apply(
        bodyColor: color,
        displayColor: color,
        fontFamily: fontFamily,
      );
    }
  }

  // --- Shared Premium Component Themes builders ---

  static CardThemeData _buildCardTheme(
    ColorScheme colors, {
    Color? shadowColor,
    Color? borderColor,
  }) {
    final isDark = colors.brightness == Brightness.dark;
    return CardThemeData(
      color: colors.surface,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: TripsFactoryDesignTokens.borderRadiusMedium,
        side: BorderSide(
          color:
              borderColor ??
              (isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7)),
          width: 1,
        ),
      ),
      shadowColor:
          shadowColor ?? Colors.black.withValues(alpha: isDark ? 0.4 : 0.04),
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme(ColorScheme colors) {
    return ElevatedButtonThemeData(
      style:
          ElevatedButton.styleFrom(
            foregroundColor: colors.onPrimary,
            backgroundColor: colors.primary,
            elevation: 0,
            minimumSize: const Size(88, 52),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              letterSpacing: 0.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: TripsFactoryDesignTokens.borderRadiusSmall,
            ),
          ).copyWith(
            elevation: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.hovered)) return 2;
              if (states.contains(WidgetState.pressed)) return 0;
              return 0;
            }),
          ),
    );
  }

  static InputDecorationTheme _buildInputDecorationTheme(ColorScheme colors) {
    final isDark = colors.brightness == Brightness.dark;
    final borderColor = isDark
        ? const Color(0xFF27272A)
        : const Color(0xFFE4E4E7);

    return InputDecorationTheme(
      filled: true,
      fillColor: colors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: TripsFactoryDesignTokens.borderRadiusMedium,
        borderSide: BorderSide(color: borderColor, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: TripsFactoryDesignTokens.borderRadiusMedium,
        borderSide: BorderSide(color: borderColor, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: TripsFactoryDesignTokens.borderRadiusMedium,
        borderSide: BorderSide(color: colors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: TripsFactoryDesignTokens.borderRadiusMedium,
        borderSide: BorderSide(color: colors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: TripsFactoryDesignTokens.borderRadiusMedium,
        borderSide: BorderSide(color: colors.error, width: 2),
      ),
      labelStyle: TextStyle(
        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
        fontWeight: FontWeight.w500,
      ),
      floatingLabelStyle: TextStyle(
        color: colors.primary,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: TextStyle(
        color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
      ),
    );
  }

  static AppBarTheme _buildAppBarTheme(ColorScheme colors, Color scaffoldBg) {
    return AppBarTheme(
      backgroundColor: scaffoldBg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: colors.onSurface),
      titleTextStyle: TextStyle(
        color: colors.onSurface,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
    );
  }

  static FloatingActionButtonThemeData _buildFabTheme(ColorScheme colors) {
    return FloatingActionButtonThemeData(
      backgroundColor: colors.primary,
      foregroundColor: colors.onPrimary,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  static BottomNavigationBarThemeData _buildBottomNavTheme(ColorScheme colors) {
    final isDark = colors.brightness == Brightness.dark;
    return BottomNavigationBarThemeData(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      elevation: 8,
      selectedItemColor: colors.primary,
      unselectedItemColor: isDark
          ? const Color(0xFF94A3B8)
          : const Color(0xFF64748B),
    );
  }

  static ThemeData _buildThemeFromColorScheme(
    ColorScheme colors, {
    required Color scaffoldBackgroundColor,
    String fontFamily = kAppFontFamily,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: colors.brightness,
      colorScheme: colors,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      cardTheme: _buildCardTheme(colors),
      appBarTheme: _buildAppBarTheme(colors, scaffoldBackgroundColor),
      elevatedButtonTheme: _buildElevatedButtonTheme(colors),
      inputDecorationTheme: _buildInputDecorationTheme(colors),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: TripsFactoryDesignTokens.borderRadiusLarge,
        ),
      ),
      floatingActionButtonTheme: _buildFabTheme(colors),
      bottomNavigationBarTheme: _buildBottomNavTheme(colors),
      textTheme: _buildTextTheme(
        colors.brightness == Brightness.dark
            ? ThemeData.dark().textTheme
            : ThemeData.light().textTheme,
        colors.onSurface,
        fontFamily,
      ),
    );
  }

  // --- Theme registry ---------------------------------------------------------
  //
  // White-label seam: the themes a fork includes in the picker. Default: all of
  // them. Trim this list to ship fewer (must be a subset of AppThemeMode). The
  // first-launch default is `ThemeNotifier.defaultThemeMode`.
  static const List<AppThemeMode> supportedThemes = <AppThemeMode>[
    AppThemeMode.tripsfactoryLight,
    AppThemeMode.tripsfactoryDark,
    AppThemeMode.desertGold,
    AppThemeMode.oasisGreen,
    AppThemeMode.skylineBlue,
    AppThemeMode.limestoneGray,
    AppThemeMode.midnightPurple,
    AppThemeMode.oceanTeal,
    AppThemeMode.steelGray,
  ];

  /// The (colors, scaffold background) pair for each theme. Single source of
  /// truth used to build the ThemeData (so every variant stays consistent).
  static ({ColorScheme colors, Color scaffold}) _schemeFor(AppThemeMode mode) {
    switch (mode) {
      // 1. TripsFactory Dark (Enhanced / Modern SaaS Dark Mode)
      case AppThemeMode.tripsfactoryDark:
        return (
          colors: const ColorScheme.dark(
            primary: Color(0xFF3B82F6),
            secondary: Color(0xFF10B981),
            surface: Color(0xFF131316),
            error: Color(0xFFEF4444),
            onSurface: Color(0xFFFAFAFA),
          ),
          scaffold: const Color(0xFF09090B),
        );

      // 2. TripsFactory Light (Corporate / Crisp SaaS Light Mode)
      case AppThemeMode.tripsfactoryLight:
        return (
          colors: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2563EB),
            primary: const Color(0xFF2563EB),
            secondary: const Color(0xFF059669),
            surface: Colors.white,
            error: const Color(0xFFE11D48),
            onSurface: const Color(0xFF09090B),
          ),
          scaffold: const Color(0xFFFAFAFA),
        );

      // 3. Desert Gold (Warm / Premium) — the original "desert" look.
      case AppThemeMode.desertGold:
        return (
          colors: ColorScheme.fromSeed(
            seedColor: const Color(0xFFD97706),
            primary: const Color(0xFFD97706),
            surface: Colors.white,
            onSurface: const Color(0xFF451A03),
          ),
          scaffold: const Color(0xFFFFFBEB),
        );

      // 3b. Oasis Green — the desert recipe in a light green palette.
      case AppThemeMode.oasisGreen:
        return (
          colors: ColorScheme.fromSeed(
            seedColor: const Color(0xFF059669),
            primary: const Color(0xFF059669),
            surface: Colors.white,
            onSurface: const Color(0xFF064E3B),
          ),
          scaffold: const Color(0xFFF0FDF4),
        );

      // 3c. Skyline Blue — the desert recipe in a light blue palette.
      case AppThemeMode.skylineBlue:
        return (
          colors: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0284C7),
            primary: const Color(0xFF0284C7),
            surface: Colors.white,
            onSurface: const Color(0xFF0C4A6E),
          ),
          scaffold: const Color(0xFFF0F9FF),
        );

      // 3d. Limestone Gray — the desert recipe in a light grey palette.
      case AppThemeMode.limestoneGray:
        return (
          colors: ColorScheme.fromSeed(
            seedColor: const Color(0xFF64748B),
            primary: const Color(0xFF475569),
            surface: Colors.white,
            onSurface: const Color(0xFF1E293B),
          ),
          scaffold: const Color(0xFFF8FAFC),
        );

      // 4. Midnight Purple (Modern/Bold)
      case AppThemeMode.midnightPurple:
        return (
          colors: ColorScheme.fromSeed(
            seedColor: const Color(0xFFC026D3),
            primary: const Color(0xFFC026D3),
            brightness: Brightness.dark,
            surface: const Color(0xFF3B0764),
            onSurface: const Color(0xFFFAE8FF),
          ),
          scaffold: const Color(0xFF2E1065),
        );

      // 5. Ocean Teal (Fresh/Calm)
      case AppThemeMode.oceanTeal:
        return (
          colors: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0891B2),
            primary: const Color(0xFF0891B2),
            surface: Colors.white,
            onSurface: const Color(0xFF164E63),
          ),
          scaffold: const Color(0xFFF0FDFA),
        );

      // 6. Steel Gray (Monochrome/Minimal — dark)
      case AppThemeMode.steelGray:
        return (
          colors: ColorScheme.fromSeed(
            seedColor: const Color(0xFF64748B),
            primary: const Color(0xFF64748B),
            brightness: Brightness.dark,
            surface: const Color(0xFF1E293B),
            onSurface: const Color(0xFFF8FAFC),
          ),
          scaffold: const Color(0xFF0F172A),
        );
    }
  }

  // Cache the default-font ThemeData per mode (the common path) so we don't
  // rebuild the color scheme on every widget rebuild.
  static final Map<AppThemeMode, ThemeData> _defaultFontCache = {};

  /// Builds the ThemeData for [mode]. Pass [fontFamily] to override the font
  /// (used for per-language / per-theme fonts via FontConfig); when null the
  /// brand default font is used and the result is cached.
  static ThemeData getTheme(AppThemeMode mode, {String? fontFamily}) {
    if (fontFamily == null || fontFamily == kAppFontFamily) {
      return _defaultFontCache.putIfAbsent(mode, () {
        final s = _schemeFor(mode);
        return _buildThemeFromColorScheme(
          s.colors,
          scaffoldBackgroundColor: s.scaffold,
        );
      });
    }
    final s = _schemeFor(mode);
    return _buildThemeFromColorScheme(
      s.colors,
      scaffoldBackgroundColor: s.scaffold,
      fontFamily: fontFamily,
    );
  }
}
