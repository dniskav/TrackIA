import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gymia/data/app_info.dart';

void main() {
  test('trackiaVersion matches pubspec.yaml', () {
    final line = File(
      'pubspec.yaml',
    ).readAsLinesSync().firstWhere((l) => l.startsWith('version:'));
    final version = line.substring('version:'.length).trim().split('+').first;
    expect(trackiaVersion, version);
  });

  test('user agent names the app and its version', () {
    expect(trackiaUserAgent, 'TrackIA/$trackiaVersion');
  });
}
