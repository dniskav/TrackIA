import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';
import 'package:trackia/domain/activity.dart';
import 'package:trackia/domain/companion.dart';
import 'package:trackia/domain/companion_package.dart';
import 'package:trackia/domain/reminder.dart';
import 'package:trackia/l10n/generated/app_localizations.dart';
import 'package:trackia/ui/companion_share.dart';

/// Decodes the raw JSON of a `.trackia` text, without going through the
/// package model, so the test sees exactly what was written.
Map<String, Object?> rawJson(String text) {
  final padded = text.padRight(text.length + (4 - text.length % 4) % 4, '=');
  final json = utf8.decode(gzip.decode(base64Url.decode(padded)));
  return jsonDecode(json) as Map<String, Object?>;
}

void main() {
  late Directory tmp;
  late List<List<XFile>> shared;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('trackia-share-test-');
    shared = [];
  });
  tearDown(() async {
    await tmp.delete(recursive: true);
  });

  final lectura = Companion(
    id: 'lectura',
    name: 'Lectura Diaria',
    description: 'Libros y notas',
    prompt: 'Tono sereno y breve. Pregunta qué libro leo hoy.',
    icon: 'book',
    color: 'teal',
    reminderCopy: const ReminderTemplates(
      windowStart: ['Hora de leer un rato'],
      lastCall: ['Aún estás a tiempo de leer'],
      inactive: [],
    ),
  );

  final templates = [
    PackageTemplate(
      activity: ActivityDefinition(
        name: 'Leer',
        restSeconds: 60,
        instructions: 'Anota la página.',
      ),
    ),
    PackageTemplate(
      activity: ActivityDefinition(name: 'Beber agua'),
      instant: true,
    ),
  ];

  Future<void> pumpHost(
    WidgetTester tester, {
    required Companion companion,
    List<PackageTemplate> packageTemplates = const [],
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        home: Builder(
          builder:
              (context) => Scaffold(
                body: TextButton(
                  key: const Key('open'),
                  onPressed:
                      () => shareCompanionPackage(
                        context,
                        companion: companion,
                        templates: packageTemplates,
                        temporaryDirectory: () async => tmp,
                        share: (files, {subject, text, sharePositionOrigin}) async {
                          shared.add(files);
                        },
                      ),
                  child: const Text('abrir'),
                ),
              ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open')));
    await tester.pumpAndSettle();
  }

  /// The file is written with real I/O, which only completes outside the fake
  /// clock of testWidgets.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<String> readFile(WidgetTester tester, String path) async =>
      (await tester.runAsync(() => File(path).readAsString()))!;

  final l = lookupAppLocalizations(const Locale('es'));

  testWidgets('confirmar comparte exactamente un .trackia con los campos esperados', (
    tester,
  ) async {
    await pumpHost(tester, companion: lectura, packageTemplates: templates);

    expect(find.text(l.packageShareTitle), findsOneWidget);
    await tester.tap(find.byKey(const Key('share-companion-confirm')));
    await settle(tester);

    expect(shared, hasLength(1));
    expect(shared.single, hasLength(1));
    final file = shared.single.single;
    expect(file.name, 'Lectura-Diaria.trackia');
    final text = await readFile(tester, file.path);

    // Round trip through the package model.
    final package = CompanionPackage.decode(text);
    expect(package.name, 'Lectura Diaria');
    expect(package.icon, 'book');
    expect(package.color, 'teal');
    expect(package.description, 'Libros y notas');
    expect(package.instructions, 'Tono sereno y breve. Pregunta qué libro leo hoy.');
    expect(package.mode, 'reminder');
    expect(package.templates.map((t) => t.activity.name), ['Leer', 'Beber agua']);
    expect(package.templates.last.instant, isTrue);
    expect(package.reminders?.windowStart, ['Hora de leer un rato']);

    // Nothing outside the allowed list reaches the file, at any level.
    final raw = rawJson(text);
    expect(
      raw.keys.toSet(),
      {...CompanionPackage.allowedKeys, 'format', 'checksum'},
    );
    for (final t in (raw['templates'] as List).cast<Map<String, Object?>>()) {
      expect(t.keys.toSet().difference(
        {
          'name', 'repeated', 'restSeconds', 'activitySeconds', 'targetSets',
          'targetCycles', 'fields', 'instructions', 'segmentSingular',
          'segmentPlural', 'instant',
        },
      ), isEmpty);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancelar no comparte nada', (tester) async {
    await pumpHost(tester, companion: lectura, packageTemplates: templates);

    await tester.tap(find.byKey(const Key('share-companion-cancel')));
    await tester.pumpAndSettle();

    expect(shared, isEmpty);
    expect(tmp.listSync(), isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('instrucciones de más de 4000 caracteres: aviso y nada se comparte', (
    tester,
  ) async {
    final long = Companion(
      id: 'larga',
      name: 'Larga',
      description: '',
      prompt: 'a' * 4001,
    );
    await pumpHost(tester, companion: long);

    expect(find.text(l.packageShareInstructionsTooLong), findsOneWidget);
    expect(find.text(l.packageShareTitle), findsNothing);
    expect(shared, isEmpty);
    expect(tmp.listSync(), isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('más de 5 plantillas: se comparten 5 y el diálogo lo dice', (
    tester,
  ) async {
    final many = [
      for (var i = 0; i < 6; i++)
        PackageTemplate(activity: ActivityDefinition(name: 'Plantilla $i')),
    ];
    await pumpHost(tester, companion: lectura, packageTemplates: many);

    expect(find.text(l.packageShareTemplatesLimited), findsOneWidget);
    await tester.tap(find.byKey(const Key('share-companion-confirm')));
    await settle(tester);

    expect(shared, hasLength(1));
    final package = CompanionPackage.decode(
      await readFile(tester, shared.single.single.path),
    );
    expect(package.templates, hasLength(5));
    expect(tester.takeException(), isNull);
  });

  test('nombre de archivo sin caracteres raros', () {
    expect(companionPackageFileName('Calma ñandú!'), 'Calma-and.trackia');
    expect(companionPackageFileName('¡¡'), 'acompanante.trackia');
  });
}
