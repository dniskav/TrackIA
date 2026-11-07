import 'package:flutter/material.dart';

import '../application/app_version.dart';
import '../application/localization.dart';

/// «Versión 0.3.33 (36)», discreta, para Ayuda y la bienvenida. No ocupa
/// espacio mientras no hay versión.
class AppVersionLabel extends StatefulWidget {
  const AppVersionLabel({super.key, this.loader});

  /// Para pruebas; por defecto lee la versión de la plataforma.
  final AppVersionLoader? loader;

  @override
  State<AppVersionLabel> createState() => _AppVersionLabelState();
}

class _AppVersionLabelState extends State<AppVersionLabel> {
  late final Future<String> version = (widget.loader ?? loadAppVersion)();

  @override
  Widget build(BuildContext context) => FutureBuilder<String>(
    future: version,
    builder: (context, snapshot) {
      final value = snapshot.data ?? '';
      if (value.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          appText(context).appVersion(value),
          key: const Key('app-version'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    },
  );
}
