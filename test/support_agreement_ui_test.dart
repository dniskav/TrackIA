import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:trackia/data/feature_scope.dart';
import 'package:trackia/data/support_agreement_repository.dart';
import 'package:trackia/domain/support_agreement.dart';
import 'package:trackia/l10n/generated/app_localizations.dart';
import 'package:trackia/ui/support_agreement.dart';

void main() {
  sqfliteFfiInit();
  late Directory dir;
  late Database db;
  late SupportAgreementRepository repo;
  var counter = 0;
  var clock = DateTime.utc(2026, 11, 7, 10);
  final scope = FeatureScope(profileId: 'profile-a', companionId: 'comp-a');

  String newId() => 'id-${counter++}';
  DateTime now() => clock = clock.add(const Duration(minutes: 1));

  // sqflite ffi usa E/S real: se cede al reloj real entre fotogramas.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 40)),
      );
      await tester.pump(const Duration(milliseconds: 150));
    }
  }

  Future<T> real<T>(WidgetTester tester, Future<T> Function() f) async =>
      (await tester.runAsync(f)) as T;

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SupportAgreementScreen(
          repository: repo,
          now: now,
          newId: newId,
        ),
      ),
    );
    await settle(tester);
  }

  Future<void> create(
    WidgetTester tester,
    String objective, {
    String? unit,
    String? target,
    bool consent = true,
  }) async {
    await tester.tap(find.byKey(const Key('agreement-new')));
    await settle(tester);
    await tester.enterText(find.byKey(const Key('agreement-objective')), objective);
    if (unit != null) {
      await tester.enterText(find.byKey(const Key('agreement-unit')), unit);
    }
    if (target != null) {
      await tester.enterText(find.byKey(const Key('agreement-target')), target);
    }
    if (consent) {
      await tester.tap(find.byKey(const Key('agreement-consent')));
      await settle(tester);
    }
    await tester.tap(find.byKey(const Key('agreement-form-submit')));
    await settle(tester);
  }

  setUp(() async {
    counter = 0;
    clock = DateTime.utc(2026, 11, 7, 10);
    dir = await Directory.systemTemp.createTemp('trackia-agreement-ui-');
    db = await databaseFactoryFfi.openDatabase('${dir.path}/a.sqlite');
    repo = SupportAgreementRepository(db, scope);
  });

  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });

  testWidgets('crea varios objetivos distintos con consentimiento', (tester) async {
    await open(tester);
    await create(tester, 'Beber más agua', unit: 'vasos', target: '8');
    await create(tester, 'Llamar a mi madre');
    await create(tester, 'Dormir sin pantallas', target: '0,5');
    expect(find.text('Beber más agua'), findsOneWidget);
    expect(find.text('Llamar a mi madre'), findsOneWidget);
    expect(find.text('Medida: 8 vasos'), findsOneWidget);
    expect(find.text('Medida: 0.5'), findsOneWidget);
    expect((await real(tester, repo.list)).length, 3);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rechaza sin consentimiento, medida negativa o no finita', (tester) async {
    await open(tester);
    await create(tester, 'Meditar', consent: false);
    expect(find.text('Marca la casilla para crear el acuerdo.'), findsOneWidget);
    expect(await real(tester, repo.list), isEmpty);

    await tester.enterText(find.byKey(const Key('agreement-target')), '-3');
    await tester.tap(find.byKey(const Key('agreement-consent')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('agreement-form-submit')));
    await settle(tester);
    expect(find.textContaining('número finito'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('agreement-target')), 'Infinity');
    await tester.tap(find.byKey(const Key('agreement-form-submit')));
    await settle(tester);
    expect(find.textContaining('número finito'), findsOneWidget);
    expect(await real(tester, repo.list), isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pausar, reanudar, avance, modificar, finalizar e historial', (tester) async {
    await open(tester);
    await create(tester, 'Caminar', unit: 'km', target: '5');
    await tester.tap(find.text('Caminar'));
    await settle(tester);

    await tester.tap(find.byKey(const Key('agreement-record')));
    await settle(tester);
    await tester.enterText(find.byKey(const Key('agreement-event-amount')), '2,5');
    await tester.enterText(find.byKey(const Key('agreement-event-note')), 'Por el parque');
    await tester.tap(find.byKey(const Key('agreement-event-submit')));
    await settle(tester);
    expect(find.text('2.5 · Por el parque'), findsOneWidget);

    await tester.tap(find.byKey(const Key('agreement-pause')));
    await settle(tester);
    expect(find.byKey(const Key('agreement-record')), findsNothing);
    expect(find.byKey(const Key('agreement-resume')), findsOneWidget);
    await tester.tap(find.byKey(const Key('agreement-resume')));
    await settle(tester);
    expect(find.byKey(const Key('agreement-pause')), findsOneWidget);

    await tester.tap(find.byKey(const Key('agreement-modify')));
    await settle(tester);
    await tester.enterText(find.byKey(const Key('agreement-objective')), 'Caminar más');
    await tester.enterText(find.byKey(const Key('agreement-target')), '7');
    await tester.tap(find.byKey(const Key('agreement-form-submit')));
    await settle(tester);
    expect(find.text('Caminar más'), findsOneWidget);
    expect(find.text('Medida: 7 km'), findsOneWidget);

    // Cancelar la confirmación no finaliza.
    await tester.tap(find.byKey(const Key('agreement-complete')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('agreement-complete-cancel')));
    await settle(tester);
    expect((await real(tester, () => repo.get('id-0')))!.status, SupportAgreementStatus.active);

    await tester.tap(find.byKey(const Key('agreement-complete')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('agreement-complete-confirm')));
    await settle(tester);
    expect(find.byKey(const Key('agreement-record')), findsNothing);
    expect(find.byKey(const Key('agreement-modify')), findsNothing);

    final saved = (await real(tester, () => repo.get('id-0')))!;
    expect(saved.status, SupportAgreementStatus.completed);
    expect(saved.events.length, 1);
    expect(saved.revisions.length, 4); // pausa, reanudar, modificar, finalizar
    expect(find.byKey(const Key('agreement-revision-5')), findsOneWidget);
    expect(find.byKey(const Key('agreement-revision-2')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reinicio: reabrir con la misma base conserva todo', (tester) async {
    await open(tester);
    await create(tester, 'Leer', target: '10');
    await tester.tap(find.text('Leer'));
    await settle(tester);
    await tester.tap(find.byKey(const Key('agreement-pause')));
    await settle(tester);

    await tester.pumpWidget(const SizedBox());
    repo = SupportAgreementRepository(db, scope);
    await open(tester);
    expect(find.text('En pausa'), findsOneWidget);
    expect(find.text('Leer'), findsOneWidget);
    await tester.tap(find.text('Leer'));
    await settle(tester);
    expect(find.byKey(const Key('agreement-resume')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
