import 'package:package_info_plus/package_info_plus.dart';

/// La versión instalada de la app, p. ej. `0.3.33 (36)`; en depuración lleva el
/// sufijo `-dev`. Cadena vacía si la plataforma no la puede dar.
typedef AppVersionLoader = Future<String> Function();

Future<String> loadAppVersion() async {
  try {
    final info = await PackageInfo.fromPlatform();
    final build = info.buildNumber.trim();
    return build.isEmpty ? info.version : '${info.version} ($build)';
  } catch (_) {
    return '';
  }
}
