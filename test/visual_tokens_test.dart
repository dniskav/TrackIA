import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackia/ui/theme.dart';

double _channel(int v) {
  final c = v / 255;
  return c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
}

double _luminance(Color c) =>
    0.2126 * _channel((c.r * 255).round()) +
    0.7152 * _channel((c.g * 255).round()) +
    0.0722 * _channel((c.b * 255).round());

/// WCAG 2.x contrast ratio, as used to fix the values in
/// specs/004-trackia-experience/contracts/visual-tokens.md.
double contrast(Color a, Color b) {
  final la = _luminance(a), lb = _luminance(b);
  final hi = math.max(la, lb), lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  test('brand palette matches the icon-derived contract', () {
    expect(brandTeal, const Color(0xFF027D92));
    expect(brandTealLight, const Color(0xFF35B5CB));
    expect(brandOrange, const Color(0xFFFE6101));
    expect(brandRed, const Color(0xFFF52C1F));
    expect(brandCrimson, const Color(0xFFDC0148));
    expect(brandGradient.colors, [brandCrimson, brandRed, brandOrange]);
  });

  test('dark theme uses the contract values', () {
    final s = gymTheme.colorScheme;
    expect(gymTheme.brightness, Brightness.dark);
    expect(gymTheme.scaffoldBackgroundColor, const Color(0xFF0A1A20));
    expect(s.surface, const Color(0xFF12303A));
    expect(s.onSurface, const Color(0xFFE6EEF0));
    expect(s.onSurfaceVariant, const Color(0xFF9DB8BE));
    expect(s.primary, const Color(0xFF35B5CB));
    expect(s.onPrimary, const Color(0xFF0A1A20));
    expect(s.outlineVariant, const Color(0xFF1F4A55));
    expect(s.error, const Color(0xFFFF8FA3));
    expect(gymTheme.inputDecorationTheme.fillColor, const Color(0xFF0A1A20));
  });

  test('light theme uses the contract values', () {
    final s = gymLightTheme.colorScheme;
    expect(gymLightTheme.brightness, Brightness.light);
    expect(gymLightTheme.scaffoldBackgroundColor, const Color(0xFFF6FAFA));
    expect(s.surface, const Color(0xFFFFFFFF));
    expect(s.onSurface, const Color(0xFF0A1A20));
    expect(s.onSurfaceVariant, const Color(0xFF4B6670));
    expect(s.primary, const Color(0xFF027D92));
    expect(s.onPrimary, const Color(0xFFFFFFFF));
    expect(s.outlineVariant, const Color(0xFFBCD3D8));
    expect(s.error, const Color(0xFFB0003A));
    expect(gymLightTheme.inputDecorationTheme.fillColor, const Color(0xFFE9F3F4));
  });

  test('every text and control pair meets WCAG AA', () {
    final d = gymTheme.colorScheme, l = gymLightTheme.colorScheme;
    final dBg = gymTheme.scaffoldBackgroundColor;
    final lBg = gymLightTheme.scaffoldBackgroundColor;
    final pairs = <String, (Color, Color, double)>{
      'oscuro: texto / fondo': (d.onSurface, dBg, 7),
      'oscuro: texto / superficie': (d.onSurface, d.surface, 7),
      'oscuro: secundario / fondo': (d.onSurfaceVariant, dBg, 4.5),
      'oscuro: secundario / superficie': (d.onSurfaceVariant, d.surface, 4.5),
      'oscuro: primario / fondo': (d.primary, dBg, 4.5),
      'oscuro: primario / superficie': (d.primary, d.surface, 4.5),
      'oscuro: onPrimary / primario': (d.onPrimary, d.primary, 4.5),
      'oscuro: error / superficie': (d.error, d.surface, 4.5),
      'oscuro: en curso / superficie': (brandOrangeTextDark, d.surface, 4.5),
      'claro: texto / fondo': (l.onSurface, lBg, 7),
      'claro: secundario / fondo': (l.onSurfaceVariant, lBg, 4.5),
      'claro: secundario / superficie': (l.onSurfaceVariant, l.surface, 4.5),
      'claro: primario / fondo': (l.primary, lBg, 4.5),
      'claro: primario / superficie': (l.primary, l.surface, 4.5),
      'claro: onPrimary / primario': (l.onPrimary, l.primary, 4.5),
      'claro: error / superficie': (l.error, l.surface, 4.5),
      'claro: en curso / superficie': (brandOrangeTextLight, l.surface, 4.5),
      'botón Iniciar': (Colors.white, brandTeal, 4.5),
      'botón Parar': (Colors.white, brandCrimson, 4.5),
    };
    for (final entry in pairs.entries) {
      final (fg, bg, min) = entry.value;
      expect(
        contrast(fg, bg),
        greaterThanOrEqualTo(min),
        reason: '${entry.key}: ${contrast(fg, bg).toStringAsFixed(2)} < $min',
      );
    }
  });

  test('white on the brand orange is not used for text (3.03 < 4.5)', () {
    expect(contrast(Colors.white, brandOrange), lessThan(4.5));
  });

  test('companion colors are readable on their theme surface', () {
    expect(trackiaCompanionColors.keys, {
      'teal',
      'orange',
      'green',
      'amber',
      'crimson',
      'violet',
    });
    for (final entry in trackiaCompanionColors.entries) {
      expect(
        contrast(entry.value.dark, gymTheme.colorScheme.surface),
        greaterThanOrEqualTo(4.5),
        reason: '${entry.key} oscuro',
      );
      expect(
        contrast(entry.value.light, gymLightTheme.colorScheme.surface),
        greaterThanOrEqualTo(4.5),
        reason: '${entry.key} claro',
      );
    }
  });

  group('primary action styles', () {
    Future<(ButtonStyle, ButtonStyle)> styles(
      WidgetTester tester,
      ThemeData theme,
    ) async {
      late ButtonStyle start, stop;
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Builder(
            builder: (context) {
              start = startButtonStyle(context);
              stop = stopButtonStyle(context);
              return const SizedBox();
            },
          ),
        ),
      );
      return (start, stop);
    }

    for (final theme in [gymTheme, gymLightTheme]) {
      testWidgets('Iniciar is teal and Parar is crimson (${theme.brightness.name})', (
        tester,
      ) async {
        final (start, stop) = await styles(tester, theme);
        expect(start.backgroundColor!.resolve({}), brandTeal);
        expect(start.foregroundColor!.resolve({}), Colors.white);
        expect(start.textStyle!.resolve({})!.fontWeight, FontWeight.w700);
        expect(stop.backgroundColor!.resolve({}), brandCrimson);
        expect(stop.foregroundColor!.resolve({}), Colors.white);
        expect(stop.textStyle!.resolve({})!.fontWeight, FontWeight.w700);
        expect(start.minimumSize!.resolve({})!.height, greaterThanOrEqualTo(54));
      });
    }

    testWidgets('secondary buttons outline with the theme primary', (
      tester,
    ) async {
      for (final theme in [gymTheme, gymLightTheme]) {
        final side = theme.outlinedButtonTheme.style!.side!.resolve({})!;
        expect(side.color, theme.colorScheme.primary);
        expect(side.width, 1.5);
      }
    });
  });
}
