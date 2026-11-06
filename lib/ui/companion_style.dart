import 'package:flutter/material.dart';
import '../domain/companion.dart';
import 'theme.dart';

/// Companion icon IDs (see contracts/visual-tokens.md) to Material icons.
const companionIcons = <String, IconData>{
  'barbell': Icons.fitness_center,
  'hourglass': Icons.hourglass_top,
  'leaf': Icons.spa,
  'notebook': Icons.menu_book,
  'sparkles': Icons.auto_awesome,
  'book': Icons.auto_stories,
  'water': Icons.water_drop,
  'run': Icons.directions_run,
  'bike': Icons.directions_bike,
  'ball': Icons.sports_soccer,
  'music': Icons.music_note,
  'brush': Icons.brush,
  'work': Icons.work_outline,
  'pill': Icons.medication,
  'heart': Icons.favorite_border,
  'school': Icons.school,
};

/// Accent color for [id] in the current theme, readable on the surface.
Color companionColor(BuildContext context, String id) {
  final pair = trackiaCompanionColors[id] ?? trackiaCompanionColors['teal']!;
  return Theme.of(context).brightness == Brightness.dark
      ? pair.dark
      : pair.light;
}

/// Burbuja del asistente: color del acompañante mezclado sobre la superficie
/// (22 % en oscuro, 14 % en claro) y borde fino del mismo color.
({Color fill, Color border}) assistantBubbleColors(
  Color companion,
  ColorScheme scheme,
) {
  final dark = scheme.brightness == Brightness.dark;
  return (
    fill: Color.alphaBlend(
      companion.withValues(alpha: dark ? 0.22 : 0.14),
      scheme.surface,
    ),
    border: companion.withValues(alpha: 0.45),
  );
}

/// Burbuja del usuario: teal de marca con texto blanco en ambos temas (4,83).
const userBubbleColor = brandTeal;
const userBubbleTextColor = Colors.white;

/// The companion's icon on a circle tinted with its color at 20 %.
class CompanionAvatar extends StatelessWidget {
  const CompanionAvatar({super.key, required this.companion, this.radius = 20});

  final Companion companion;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final color = companionColor(context, companion.color);
    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withValues(alpha: 0.2),
      child: Icon(
        companionIcons[companion.icon] ?? Icons.auto_awesome,
        color: color,
        size: radius,
      ),
    );
  }
}
