import 'package:flutter/material.dart';

// Brand colors sampled from assets/branding/trackia-icon-master.png. Values and
// measured contrasts are fixed in specs/004-trackia-experience/contracts/visual-tokens.md.
const brandTeal = Color(0xFF027D92);
const brandTealLight = Color(0xFF35B5CB);
const brandOrange = Color(0xFFFE6101);
const brandRed = Color(0xFFF52C1F);
const brandCrimson = Color(0xFFDC0148);

/// Orange readable as text on each theme's surface (the brand orange is only
/// used for arcs, rings and the logo, never as a button fill).
const brandOrangeTextDark = Color(0xFFFF8A4D);
const brandOrangeTextLight = Color(0xFFC2410C);

/// Progress arcs, goal rings and the arrow of the logo.
const brandGradient = LinearGradient(
  begin: Alignment.bottomLeft,
  end: Alignment.topRight,
  colors: [brandCrimson, brandRed, brandOrange],
);

/// Companion accent colors by ID, for the dark and light themes.
const trackiaCompanionColors = <String, ({Color dark, Color light})>{
  'teal': (dark: Color(0xFF35B5CB), light: Color(0xFF027D92)),
  'orange': (dark: Color(0xFFFF8A4D), light: Color(0xFFC2410C)),
  'green': (dark: Color(0xFF7FD6A4), light: Color(0xFF2E7D4F)),
  'amber': (dark: Color(0xFFF2C46D), light: Color(0xFF8A5A00)),
  'crimson': (dark: Color(0xFFFF6B8E), light: Color(0xFFB0003A)),
  'violet': (dark: Color(0xFFB4A2F0), light: Color(0xFF5B44B3)),
};

/// Unfilled part of the timer ring; decorative, so no text contrast applies.
Color ringTrackColor(Brightness brightness) =>
    brightness == Brightness.dark
        ? const Color(0xFF1E5A68)
        : const Color(0xFFBFDCE2);

const _darkBackground = Color(0xFF0A1A20);
const _darkSurface = Color(0xFF12303A);
const _lightBackground = Color(0xFFF6FAFA);

ColorScheme _scheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final background = dark ? _darkBackground : _lightBackground;
  final surface = dark ? _darkSurface : Colors.white;
  return ColorScheme.fromSeed(
    seedColor: brandTeal,
    brightness: brightness,
  ).copyWith(
    primary: dark ? brandTealLight : brandTeal,
    onPrimary: dark ? _darkBackground : Colors.white,
    secondary: dark ? brandOrangeTextDark : brandOrangeTextLight,
    onSecondary: dark ? _darkBackground : Colors.white,
    surface: surface,
    onSurface: dark ? const Color(0xFFE6EEF0) : _darkBackground,
    onSurfaceVariant: dark ? const Color(0xFF9DB8BE) : const Color(0xFF4B6670),
    outlineVariant: dark ? const Color(0xFF1F4A55) : const Color(0xFFBCD3D8),
    error: dark ? const Color(0xFFFF8FA3) : const Color(0xFFB0003A),
    onError: dark ? _darkBackground : Colors.white,
    surfaceContainerLowest: background,
    surfaceContainerLow: surface,
    surfaceContainer: surface,
    surfaceContainerHigh: surface,
    surfaceContainerHighest: surface,
  );
}

OutlinedButtonThemeData _outlined(ColorScheme scheme) => OutlinedButtonThemeData(
  style: OutlinedButton.styleFrom(
    minimumSize: const Size(0, 50),
    foregroundColor: scheme.primary,
    side: BorderSide(color: scheme.primary, width: 1.5),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
);

FilledButtonThemeData _filled() => FilledButtonThemeData(
  style: FilledButton.styleFrom(
    minimumSize: const Size(0, 54),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
  ),
);

ThemeData _theme(Brightness brightness) {
  final scheme = _scheme(brightness);
  final dark = brightness == Brightness.dark;
  final background = dark ? _darkBackground : _lightBackground;
  final base = ThemeData(brightness: brightness).textTheme.apply(
    bodyColor: scheme.onSurface,
    displayColor: scheme.onSurface,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: background,
    textTheme: base,
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? _darkBackground : const Color(0xFFE9F3F4),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    ),
    filledButtonTheme: _filled(),
    outlinedButtonTheme: _outlined(scheme),
  );
}

final gymTheme = _theme(Brightness.dark);
final gymLightTheme = _theme(Brightness.light);

ButtonStyle _actionStyle(BuildContext context, Color fill) =>
    FilledButton.styleFrom(
      backgroundColor: fill,
      foregroundColor: Colors.white,
      disabledBackgroundColor: Theme.of(
        context,
      ).colorScheme.onSurface.withValues(alpha: 0.12),
      minimumSize: const Size(0, 54),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    );

/// «Iniciar»: teal with white bold text in both themes (contrast 4.83).
ButtonStyle startButtonStyle(BuildContext context) =>
    _actionStyle(context, brandTeal);

/// «Parar»: crimson with white bold text in both themes (contrast 5.07).
ButtonStyle stopButtonStyle(BuildContext context) =>
    _actionStyle(context, brandCrimson);
