import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:trackia/data/feature_scope.dart';
import 'package:trackia/data/support_agreement_repository.dart';
import 'package:trackia/data/welcome_settings_store.dart';
import 'package:trackia/domain/support_agreement.dart';
import 'package:trackia/l10n/generated/app_localizations.dart';
import 'package:trackia/ui/support_agreement.dart';

/// T039 (US5) en Android: la pantalla real «Acuerdos de apoyo» con una base
/// SQLite real en archivo. Cubre crear con consentimiento, avance, pausar,
/// reanudar, modificar, finalizar con confirmación, reinicio (cerrar y reabrir
/// la base), estado de los permisos de notificaciones y aislamiento por
/// acompañante.
///
/// LÍMITES: el permiso de notificaciones no se puede conceder ni revocar desde
/// la prueba (`pm grant/revoke` queda fuera). Se lee el estado real con el
/// canal `com.gymia.app/reminders` y se comprueba que el flujo es idéntico con
/// el permiso en cualquier estado. Hoy no existe aviso por acuerdo (los avisos
/// son por acompañante), así que no se prueba ninguno: solo que crear un
/// acuerdo no programa avisos nuevos. La prueba no abre el chat: usa la
/// pantalla directamente (la entrada `menu-agreements` no se ejercita aquí).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const remindersChannel = MethodChannel('com.gymia.app/reminders');

  testWidgets('acuerdos de apoyo: ciclo, reinicio, permisos y aislamiento', (
    tester,
  ) async {
    // La bienvenida automática taparía la pantalla en una instalación nueva.
    WelcomeSettings.instance.offeredThisLaunch = true;
    final dir = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('trackia-agreements-qa-'),
    ))!;
    final path = '${dir.path}/agreements.sqlite';
    Database? db;
    var counter = 0;
    var prefix = 'a';
    var clock = DateTime.now();
    String newId() => '$prefix-${counter++}';
    DateTime now() => clock = clock.add(const Duration(minutes: 1));

    Future<void> settle() async {
      for (var i = 0; i < 4; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 60)),
        );
        await tester.pump(const Duration(milliseconds: 150));
      }
    }

    Future<T> real<T>(Future<T> Function() f) async =>
        (await tester.runAsync(f)) as T;

    Future<SupportAgreementRepository> openRepo(
      String companion, {
      bool reopen = false,
    }) async {
      if (reopen || db == null) {
        db = await real(() => openDatabase(path));
      }
      return SupportAgreementRepository(
        db!,
        FeatureScope(profileId: 'qa-profile', companionId: companion),
      );
    }

    Future<void> show(SupportAgreementRepository repo) async {
      await tester.pumpWidget(const SizedBox());
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
      await settle();
    }

    Future<void> create(
      String objective, {
      String? unit,
      String? target,
    }) async {
      await tester.tap(find.byKey(const Key('agreement-new')));
      await settle();
      await tester.enterText(
        find.byKey(const Key('agreement-objective')),
        objective,
      );
      if (unit != null) {
        await tester.enterText(find.byKey(const Key('agreement-unit')), unit);
      }
      if (target != null) {
        await tester.enterText(
          find.byKey(const Key('agreement-target')),
          target,
        );
      }
      await tester.tap(find.byKey(const Key('agreement-consent')));
      await settle();
      await tester.tap(find.byKey(const Key('agreement-form-submit')));
      await settle();
    }

    Future<Map<String, dynamic>?> notificationStatus() async {
      try {
        return await real(
          () => remindersChannel.invokeMapMethod<String, dynamic>('status'),
        );
      } on PlatformException {
        return null;
      } on MissingPluginException {
        return null;
      }
    }

    try {
      // (3) Permisos: estado real del emulador, antes de crear nada.
      final before = await notificationStatus();
      final permitted = before?['permitted'];
      final scheduledBefore = before?['scheduled'];
      debugPrint(
        'T039 permiso de notificaciones: permitted=$permitted '
        'avisos programados antes=$scheduledBefore',
      );

      var repo = await openRepo('comp-a');
      await show(repo);
      expect(find.byKey(const Key('agreement-new')), findsOneWidget);

      // (1) Crear con consentimiento, sea cual sea el permiso.
      await create('Caminar', unit: 'km', target: '5');
      expect(find.text('Caminar'), findsOneWidget);
      expect(find.text('Medida: 5 km'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const Key('agreement-a-0')));
      await settle();
      await tester.tap(find.byKey(const Key('agreement-record')));
      await settle();
      await tester.enterText(
        find.byKey(const Key('agreement-event-amount')),
        '2,5',
      );
      await tester.enterText(
        find.byKey(const Key('agreement-event-note')),
        'Por el parque',
      );
      await tester.tap(find.byKey(const Key('agreement-event-submit')));
      await settle();
      expect(find.text('2.5 · Por el parque'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const Key('agreement-pause')));
      await settle();
      expect(find.byKey(const Key('agreement-resume')), findsOneWidget);
      expect(find.byKey(const Key('agreement-record')), findsNothing);
      await tester.tap(find.byKey(const Key('agreement-resume')));
      await settle();
      expect(find.byKey(const Key('agreement-pause')), findsOneWidget);

      await tester.tap(find.byKey(const Key('agreement-modify')));
      await settle();
      await tester.enterText(
        find.byKey(const Key('agreement-objective')),
        'Caminar más',
      );
      await tester.enterText(find.byKey(const Key('agreement-target')), '7');
      await tester.tap(find.byKey(const Key('agreement-form-submit')));
      await settle();
      expect(find.text('Caminar más'), findsOneWidget);
      expect(find.text('Medida: 7 km'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Pausa antes del reinicio: el estado en pausa debe sobrevivir.
      await tester.tap(find.byKey(const Key('agreement-pause')));
      await settle();

      // (2) REINICIO: cerrar la base, reabrirla y montar la pantalla de nuevo.
      await tester.pumpWidget(const SizedBox());
      await real(() => db!.close());
      db = null;
      repo = await openRepo('comp-a', reopen: true);
      await show(repo);
      expect(find.text('Caminar más'), findsOneWidget);
      expect(find.text('En pausa'), findsOneWidget);
      await tester.tap(find.byKey(const Key('agreement-a-0')));
      await settle();
      expect(find.text('2.5 · Por el parque'), findsOneWidget);
      expect(find.byKey(const Key('agreement-resume')), findsOneWidget);
      final stored = (await real(() => repo.get('a-0')))!;
      expect(stored.status, SupportAgreementStatus.paused);
      expect(stored.objective, 'Caminar más');
      expect(stored.events.length, 1);
      // pausa, reanudar, modificar, pausa
      expect(stored.revisions.length, 4);
      expect(tester.takeException(), isNull);

      // Reanudar tras el reinicio y finalizar con confirmación.
      await tester.tap(find.byKey(const Key('agreement-resume')));
      await settle();
      await tester.tap(find.byKey(const Key('agreement-complete')));
      await settle();
      await tester.tap(find.byKey(const Key('agreement-complete-cancel')));
      await settle();
      expect(
        (await real(() => repo.get('a-0')))!.status,
        SupportAgreementStatus.active,
      );
      await tester.tap(find.byKey(const Key('agreement-complete')));
      await settle();
      await tester.tap(find.byKey(const Key('agreement-complete-confirm')));
      await settle();
      final done = (await real(() => repo.get('a-0')))!;
      expect(done.status, SupportAgreementStatus.completed);
      expect(find.byKey(const Key('agreement-record')), findsNothing);
      expect(find.byKey(const Key('agreement-modify')), findsNothing);
      expect(done.events.length, 1);
      expect(tester.takeException(), isNull);

      // (3) Permisos: crear y seguir no cambió ni dependió del permiso, y no
      // se programó ningún aviso por acuerdo (no existe esa función).
      final after = await notificationStatus();
      expect(after?['permitted'], permitted);
      expect(after?['scheduled'], scheduledBefore);

      // (4) Aislamiento: dos acompañantes con el mismo id de acuerdo.
      counter = 0;
      prefix = 'iso';
      final repoB = await openRepo('comp-b');
      final repoC = await openRepo('comp-c');
      await show(repoB);
      await create('Objetivo de B', target: '1');
      counter = 0;
      await show(repoC);
      await create('Objetivo de C', target: '2');
      expect(find.text('Objetivo de C'), findsOneWidget);
      expect(find.text('Objetivo de B'), findsNothing);
      final b = (await real(() => repoB.get('iso-0')))!;
      final c = (await real(() => repoC.get('iso-0')))!;
      expect(b.objective, 'Objetivo de B');
      expect(c.objective, 'Objetivo de C');
      expect((await real(repoB.list)).length, 1);
      expect((await real(repoC.list)).length, 1);
      // El acompañante A conserva solo su acuerdo finalizado.
      final repoA = await openRepo('comp-a');
      expect((await real(repoA.list)).map((e) => e.id), ['a-0']);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() async {
        await db?.close();
        await dir.delete(recursive: true);
      });
    }
  });
}
