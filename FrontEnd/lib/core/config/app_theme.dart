/// @file app_theme.dart
/// @description Paleta corporativa (AppColors) y temas Material light/dark de la app.
/// Todos los widgets deben referenciar AppColors.xxx o Theme.of(context)
/// — nunca colores hardcodeados.
/// @module Core
/// @layer Core
library;

import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// PALETA CORPORATIVA — 11 colores + 2 variantes de texto (13 constantes total)
// WCAG: primary/textPrimary/textSecondary son aptos para texto.
// secondary (#7BC47F) y accent (#FFD166) NO aptos para texto sobre fondo claro
// → usar accentText y errorText para esos casos.
// ═══════════════════════════════════════════════════════════════════════════════

/// Paleta corporativa de la app de gestión de plantas.
///
/// 11 colores semánticos + 2 variantes oscurecidas para texto.
/// Nunca usar Color() hardcodeados en widgets; referenciar siempre AppColors.xxx.
abstract final class AppColors {
  // ─── Colores principales ────────────────────────────────────────────────────

  /// Verde bosque — primario: logo, botones principales, acciones destacadas.
  static const Color primary = Color(0xFF2E8B57);

  /// Verde claro — secundario: apoyo, chips, badges activos.
  static const Color secondary = Color(0xFF7BC47F);

  /// Amarillo cálido — accent: CTA, etiquetas destacables, FAB.
  static const Color accent = Color(0xFFFFD166);

  // ─── Neutros ─────────────────────────────────────────────────────────────────

  /// Blanco roto — fondo claro de scaffolds y páginas.
  static const Color backgroundLight = Color(0xFFF7F9F6);

  /// Gris suave con tinte verde — fondo de cards y superficies elevadas.
  static const Color surface = Color(0xFFE8EDE6);

  /// Gris antracita — texto principal. Contraste WCAG AAA sobre fondos claros.
  static const Color textPrimary = Color(0xFF263238);

  /// Gris medio cálido — texto secundario, hints, placeholders, captions.
  /// Contraste WCAG AA (~4.5:1) sobre backgroundLight.
  static const Color textSecondary = Color(0xFF607D6B);

  // ─── Estados semánticos ──────────────────────────────────────────────────────

  /// Verde brillante — éxito, confirmación, riego completado.
  static const Color success = Color(0xFF38C172);

  /// Ámbar cálido — aviso, riego próximo, atención. NO apto para texto directo.
  static const Color warning = Color(0xFFF0A030);

  /// Azul claro — información, tooltips, banners informativos.
  static const Color info = Color(0xFF4AA3FF);

  /// Rojo suave — error, validación fallida, acción destructiva.
  static const Color error = Color(0xFFE04F5F);

  // ─── Variantes para texto (oscurecidas) ──────────────────────────────────────

  /// Accent oscurecido — usar cuando se necesite texto en tono accent.
  /// (El accent puro #FFD166 no tiene contraste suficiente sobre fondos claros.)
  static const Color accentText = Color(0xFFB8942A);

  /// Error oscurecido — usar cuando se necesite texto en tono error sobre fondos claros.
  static const Color errorText = Color(0xFFC4384A);

  // ─── Dark theme extras ───────────────────────────────────────────────────────

  /// Fondo oscuro para dark theme.
  static const Color backgroundDark = Color(0xFF1A2520);

  /// Superficie elevada en dark theme.
  static const Color surfaceDark = Color(0xFF243028);
}

// ═══════════════════════════════════════════════════════════════════════════════
// TIPOGRAFÍA
// ═══════════════════════════════════════════════════════════════════════════════

/// Tipografía base de la app. Usada por lightTheme() y darkTheme().
TextTheme appTextTheme({required Color bodyColor, required Color displayColor}) {
  return TextTheme(
    // Títulos de página / cabeceras grandes
    displayLarge:  TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: displayColor, letterSpacing: -0.5),
    displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: displayColor),
    displaySmall:  TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: displayColor),

    // Cabeceras de sección / AppBar
    headlineLarge:  TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: displayColor),
    headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: displayColor),
    headlineSmall:  TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: displayColor),

    // Texto de cuerpo
    bodyLarge:  TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: bodyColor, height: 1.5),
    bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: bodyColor, height: 1.5),
    bodySmall:  TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: bodyColor, height: 1.4),

    // Etiquetas / badges / chips
    labelLarge:  TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: bodyColor),
    labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: bodyColor),
    labelSmall:  TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: bodyColor, letterSpacing: 0.5),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// TEMA CLARO
// ═══════════════════════════════════════════════════════════════════════════════

/// Tema claro corporativo. Usar como ThemeData en MaterialApp.
ThemeData lightTheme() {
  final textTheme = appTextTheme(
    bodyColor:    AppColors.textPrimary,
    displayColor: AppColors.textPrimary,
  );

  final colorScheme = ColorScheme.light(
    primary:          AppColors.primary,
    onPrimary:        Colors.white,
    secondary:        AppColors.secondary,
    onSecondary:      AppColors.textPrimary,
    tertiary:         AppColors.accent,
    onTertiary:       AppColors.accentText,
    error:            AppColors.error,
    onError:          Colors.white,
    surface:          AppColors.surface,
    onSurface:        AppColors.textPrimary,
    // ignore: deprecated_member_use
    background:       AppColors.backgroundLight,
    // ignore: deprecated_member_use
    onBackground:     AppColors.textPrimary,
    surfaceContainerHighest: AppColors.surface,
    onSurfaceVariant:        AppColors.textSecondary,
    outline:          AppColors.textSecondary,
  );

  return ThemeData(
    useMaterial3:          true,
    colorScheme:           colorScheme,
    scaffoldBackgroundColor: AppColors.backgroundLight,
    textTheme:             textTheme,

    // AppBar
    appBarTheme: AppBarTheme(
      backgroundColor:  AppColors.primary,
      foregroundColor:  Colors.white,
      elevation:        0,
      centerTitle:      true,
      titleTextStyle:   textTheme.headlineMedium?.copyWith(color: Colors.white),
      iconTheme:        const IconThemeData(color: Colors.white),
    ),

    // Cards
    cardTheme: CardThemeData(
      color:        AppColors.surface,
      elevation:    2,
      shadowColor:  AppColors.primary.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin:       const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
    ),

    // Botones primarios
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor:  AppColors.primary,
        foregroundColor:  Colors.white,
        disabledBackgroundColor: AppColors.surface,
        elevation:        0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: textTheme.labelLarge?.copyWith(color: Colors.white),
      ),
    ),

    // Botones de contorno
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side:            const BorderSide(color: AppColors.primary, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),

    // Botones de texto
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: textTheme.labelLarge,
      ),
    ),

    // FAB
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation:       4,
    ),

    // Inputs
    // NOTA: se usan TextStyle explícitos (sin copyWith de textTheme) para evitar
    // heredar height:1.4 de bodySmall que recorta el floating label en Chrome/web.
    inputDecorationTheme: InputDecorationTheme(
      filled:    true,
      fillColor: AppColors.surface,
      // Label en reposo: gris medio legible sobre fondo claro.
      labelStyle: const TextStyle(
        color:      AppColors.textSecondary,
        fontSize:   14,
        fontWeight: FontWeight.w400,
      ),
      // Hint: mismo color que label en reposo.
      hintStyle: const TextStyle(
        color:      AppColors.textSecondary,
        fontSize:   14,
        fontWeight: FontWeight.w400,
      ),
      // Floating label (elevado al escribir): verde primario sin height heredado.
      floatingLabelStyle: const TextStyle(
        color:      AppColors.primary,
        fontSize:   12,
        fontWeight: FontWeight.w500,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:   const BorderSide(color: AppColors.surface),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:   const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:   const BorderSide(color: AppColors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:   const BorderSide(color: AppColors.error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),

    // Chips
    chipTheme: ChipThemeData(
      backgroundColor:    AppColors.surface,
      selectedColor:      AppColors.primary.withValues(alpha: 0.15),
      labelStyle:         textTheme.labelMedium,
      side:               BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.3)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    ),

    // Divider
    dividerTheme: DividerThemeData(
      color:     AppColors.textSecondary.withValues(alpha: 0.2),
      thickness: 1,
      space:     1,
    ),

    // SnackBar
    snackBarTheme: SnackBarThemeData(
      backgroundColor:  AppColors.textPrimary,
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      behavior:         SnackBarBehavior.floating,
    ),

    // Bottom Navigation Bar (legacy widget — no usado, pero mantenido por compatibilidad)
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor:      AppColors.backgroundLight,
      selectedItemColor:    AppColors.primary,
      unselectedItemColor:  AppColors.textSecondary,
      elevation:            8,
      type:                 BottomNavigationBarType.fixed,
    ),

    // NavigationBar (Material 3 — usado en MainTabsPage)
    // Colores y tamaños explícitos para evitar herencia incorrecta en Chrome/web
    // y garantizar alineación vertical consistente entre destinos.
    // - iconSize: 26 fijo en ambos estados (selected/unselected) → mismo bounding box.
    // - labelTextStyle: mismo fontSize en ambos estados → labels alineados verticalmente.
    // - height: 72 (definido en el widget) → safe area gestual sin padding fantasma.
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor:  AppColors.primary.withValues(alpha: 0.12),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: AppColors.primary, size: 26);
        }
        return const IconThemeData(color: AppColors.textSecondary, size: 26);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            color:      AppColors.primary,
            fontSize:   12,
            fontWeight: FontWeight.w600,
          );
        }
        return const TextStyle(
          color:    AppColors.textSecondary,
          fontSize: 12,
        );
      }),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// TEMA OSCURO
// ═══════════════════════════════════════════════════════════════════════════════

/// Tema oscuro corporativo. Derivado de la misma paleta con ajustes de brillo.
ThemeData darkTheme() {
  final textTheme = appTextTheme(
    bodyColor:    Colors.white.withValues(alpha: 0.87),
    displayColor: Colors.white,
  );

  final colorScheme = ColorScheme.dark(
    primary:          AppColors.secondary,   // verde claro más visible en oscuro
    onPrimary:        AppColors.textPrimary,
    secondary:        AppColors.primary,
    onSecondary:      Colors.white,
    tertiary:         AppColors.accent,
    onTertiary:       AppColors.textPrimary,
    error:            AppColors.error,
    onError:          Colors.white,
    surface:          AppColors.surfaceDark,
    onSurface:        Colors.white.withValues(alpha: 0.87),
    // ignore: deprecated_member_use
    background:       AppColors.backgroundDark,
    // ignore: deprecated_member_use
    onBackground:     Colors.white.withValues(alpha: 0.87),
    surfaceContainerHighest: AppColors.surfaceDark,
    onSurfaceVariant:        Colors.white.withValues(alpha: 0.6),
    outline:          Colors.white.withValues(alpha: 0.3),
  );

  return ThemeData(
    useMaterial3:            true,
    colorScheme:             colorScheme,
    scaffoldBackgroundColor: AppColors.backgroundDark,
    textTheme:               textTheme,

    appBarTheme: AppBarTheme(
      backgroundColor:  AppColors.surfaceDark,
      foregroundColor:  Colors.white,
      elevation:        0,
      centerTitle:      true,
      titleTextStyle:   textTheme.headlineMedium?.copyWith(color: Colors.white),
      iconTheme:        const IconThemeData(color: Colors.white),
    ),

    cardTheme: CardThemeData(
      color:     AppColors.surfaceDark,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.secondary,
      foregroundColor: AppColors.textPrimary,
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled:    true,
      fillColor: AppColors.surfaceDark,
      hintStyle: textTheme.bodyMedium?.copyWith(color: Colors.white38),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.secondary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),

    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor:     AppColors.surfaceDark,
      selectedItemColor:   AppColors.secondary,
      unselectedItemColor: Colors.white.withValues(alpha: 0.5),
      elevation:           8,
      type:                BottomNavigationBarType.fixed,
    ),

    // NavigationBar (Material 3) — usado en MainTabsPage también en dark mode.
    // Sin este override, Flutter caería a defaults Material 3 con iconos
    // `colorScheme.onSurfaceVariant` (blanco transparente) sobre el fondo
    // blanco forzado por el widget → iconos invisibles.
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surfaceDark,
      indicatorColor:  AppColors.secondary.withValues(alpha: 0.18),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: AppColors.secondary, size: 26);
        }
        return IconThemeData(color: Colors.white.withValues(alpha: 0.7), size: 26);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            color:      AppColors.secondary,
            fontSize:   12,
            fontWeight: FontWeight.w600,
          );
        }
        return TextStyle(
          color:    Colors.white.withValues(alpha: 0.7),
          fontSize: 12,
        );
      }),
    ),

    dividerTheme: DividerThemeData(
      color:     Colors.white.withValues(alpha: 0.12),
      thickness: 1,
      space:     1,
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor:  AppColors.surfaceDark,
      contentTextStyle: textTheme.bodyMedium,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
