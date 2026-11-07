import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../application/workout_controller.dart';
import '../application/localization.dart';
import '../domain/transfer.dart';
import '../domain/transfer_repository.dart';
import '../domain/workout.dart';
import 'google_sheets_import.dart';
import '../domain/sheet_context.dart';
import '../data/sheet_context_store.dart';
import 'package:uuid/uuid.dart';

Future<void> pickSheetForChat(
  BuildContext context,
  WorkoutController controller, {
  String companionId = 'gymbro',
}) async {
  try {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final file = await const MethodChannel(
        'com.gymia.app/import',
      ).invokeMapMethod<String, dynamic>('pickSheet');
      if (file == null || !context.mounted) return;
      final bytes = file['bytes'];
      if (bytes is! Uint8List) {
        throw ValidationException(appText(context).transferSheetReadError);
      }
      await openImportDocument(
        context,
        controller,
        bytes,
        name: file['name'] as String? ?? appText(context).transferDefaultSheetName,
        companionId: companionId,
      );
    } else {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'csv'],
        withData: true,
      );
      if (result == null || !context.mounted) return;
      final file = result.files.single;
      if (file.size > 20 * 1024 * 1024) {
        throw ValidationException(appText(context).transferSheetTooLarge);
      }
      final bytes = file.bytes ?? await File(file.path!).readAsBytes();
      if (context.mounted) {
        await openImportDocument(
          context,
          controller,
          bytes,
          name: file.name,
          companionId: companionId,
        );
      }
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is ValidationException
                ? e.message
                : appText(context).transferSheetLoadError,
          ),
        ),
      );
    }
  }
}

Future<void> openImportDocument(
  BuildContext context,
  WorkoutController controller,
  Uint8List bytes, {
  String name = 'Hoja cargada',
  String companionId = 'gymbro',
}) async {
  final tabs = SheetDocument.decodeCells(bytes);
  var selected = tabs.keys.first;
  if (tabs.length > 1) {
    final choice = await showDialog<String>(
      context: context,
      builder:
          (context) => SimpleDialog(
            title: Text(appText(context).sheetChooseTab),
            children: [
              for (final name in tabs.keys)
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, name),
                  child: Text(name),
                ),
            ],
          ),
    );
    if (choice == null) return;
    selected = choice;
  }
  if (!context.mounted) return;
  final sheet = SheetContext(
    id: const Uuid().v4(),
    name: name,
    title: selected,
    loadedAt: DateTime.now(),
    rows: tabs[selected]!,
    source: 'file',
  );
  final confirmed = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => SheetContextPreviewScreen(sheet: sheet, loadOnly: true),
    ),
  );
  if (confirmed == true) {
    await SheetContextStore(
      profileId: controller.profileId,
      companionId: companionId,
    ).save(sheet);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appText(context).transferSheetLoaded)),
      );
    }
  }
}

class DataTransferScreen extends StatefulWidget {
  const DataTransferScreen({
    super.key,
    required this.controller,
    this.companionId = 'gymbro',
  });
  final WorkoutController controller;
  final String companionId;
  @override
  State<DataTransferScreen> createState() => _DataTransferScreenState();
}

class _DataTransferScreenState extends State<DataTransferScreen> {
  bool working = false;
  TransferRepository get store =>
      widget.controller.repository as TransferRepository;

  void message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<String?> pickText(List<String> extensions) async {
    final strings = appText(context);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: extensions,
      withData: true,
    );
    if (result == null) return null;
    final file = result.files.single;
    if (file.size > 20 * 1024 * 1024) {
      throw ValidationException(strings.transferFileTooLarge);
    }
    final bytes = file.bytes ?? await File(file.path!).readAsBytes();
    return utf8.decode(bytes);
  }

  Future<void> run(Future<void> Function() action) async {
    if (working) return;
    setState(() => working = true);
    try {
      await action();
    } on ValidationException catch (e) {
      message(e.message);
    } on PlatformException catch (e) {
      if (mounted) message(e.message ?? appText(context).transferSheetSelectedError);
    } catch (_) {
      if (mounted) message(appText(context).transferFileReadError);
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  Future<void> exportBackup() => run(() async {
    final json = await store.createBackupJson();
    final folder = await getTemporaryDirectory();
    final file = File(
      p.join(
        folder.path,
        'trackia-copia-${DateFormat('yyyyMMdd-HHmm').format(DateTime.now())}.json',
      ),
    );
    await file.writeAsString(json, flush: true);
    if (!mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      subject: appText(context).transferShareSubject,
      text: appText(context).transferShareText,
      sharePositionOrigin:
          box == null ? null : box.localToGlobal(Offset.zero) & box.size,
    );
  });

  Future<void> restoreBackup() => run(() async {
    final source = await pickText(['json']);
    if (source == null || !mounted) return;
    final summary = store.inspectBackupJson(source);
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(appText(context).transferRestoreTitle),
            content: Text(
              appText(context).transferRestoreBody(summary.workouts, summary.routines, summary.active ? appText(context).transferRestoreActive : ''),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(appText(context).cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(appText(context).transferRestoreAction),
              ),
            ],
          ),
    );
    if (confirmed != true) return;
    final ok = await widget.controller.run(
      () => store.restoreBackupJson(source),
    );
    if (ok && mounted) message(appText(context).transferRestored);
  });

  Future<void> importFile() => run(() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final file = await const MethodChannel(
        'com.gymia.app/import',
      ).invokeMapMethod<String, dynamic>('pickSheet');
      if (file == null || !mounted) return;
      final bytes = file['bytes'];
      if (bytes is! Uint8List) {
        throw ValidationException(appText(context).transferSheetSelectedError);
      }
      await openImportDocument(
        context,
        widget.controller,
        bytes,
        name: file['name'] as String? ?? appText(context).transferDefaultSheetName,
        companionId: widget.companionId,
      );
      return;
    }
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true,
    );
    if (result == null || !mounted) return;
    final file = result.files.single;
    if (file.size > 20 * 1024 * 1024) {
      throw ValidationException(appText(context).transferSheetTooLarge);
    }
    if (file.bytes == null && file.path == null) {
      throw ValidationException(appText(context).transferNoAccessSheet);
    }
    final bytes = file.bytes ?? await File(file.path!).readAsBytes();
    if (!mounted) return;
    await openImportDocument(
      context,
      widget.controller,
      bytes,
      name: file.name,
      companionId: widget.companionId,
    );
  });

  Future<void> importGoogleSheets() async {
    if (working) return;
    final sheet = await Navigator.of(context).push<SheetContext>(
      MaterialPageRoute<SheetContext>(
        builder:
            (_) => GoogleSheetsImportScreen(
              controller: widget.controller,
              forAssistant: true,
              loadOnly: true,
            ),
      ),
    );
    if (sheet != null) {
      await run(() async {
        await SheetContextStore(
          profileId: widget.controller.profileId,
          companionId: widget.companionId,
        ).save(sheet);
        if (mounted) message(appText(context).transferSheetLoaded);
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(appText(context).dataTitle)),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(appText(context).transferHeadline, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Text(
          appText(context).transferIntro,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 28),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(appText(context).transferBackupTitle, style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  appText(context).transferBackupHelp,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: working ? null : exportBackup,
                  icon: const Icon(Icons.ios_share_rounded),
                  label: Text(appText(context).dataCreateBackup),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: working ? null : restoreBackup,
                  icon: const Icon(Icons.restore_rounded),
                  label: Text(appText(context).dataRestoreBackup),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(appText(context).transferSheetsTitle, style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  defaultTargetPlatform == TargetPlatform.android
                      ? appText(context).transferSheetsHelpAndroid
                      : appText(context).transferSheetsHelpOther,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                if (defaultTargetPlatform == TargetPlatform.android) ...[
                  FilledButton.icon(
                    onPressed: working ? null : importGoogleSheets,
                    icon: const Icon(Icons.table_chart_outlined),
                    label: Text(appText(context).transferImportSheets),
                  ),
                  const SizedBox(height: 8),
                ],
                FilledButton.icon(
                  onPressed: working ? null : importFile,
                  icon: const Icon(Icons.upload_file_rounded),
                  label: Text(
                    defaultTargetPlatform == TargetPlatform.android
                        ? appText(context).transferChooseFileAndroid
                        : appText(context).transferChooseFileOther,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (working)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    ),
  );
}

class CsvImportScreen extends StatefulWidget {
  const CsvImportScreen({
    super.key,
    required this.controller,
    required this.sheet,
  });
  final WorkoutController controller;
  final CsvSheet sheet;
  @override
  State<CsvImportScreen> createState() => _CsvImportScreenState();
}

class _CsvImportScreenState extends State<CsvImportScreen> {
  late CsvMapping mapping = widget.sheet.suggestedMapping();
  CsvPreview? preview;
  Set<String> existing = {};
  bool busy = false;
  String? error;

  Widget workoutTile(ImportedWorkout workout) => Card(
    child: ExpansionTile(
      title: Text(workout.name),
      subtitle: Text(
        appText(context).transferWorkoutSubtitle(DateFormat('d/M/yyyy HH:mm').format(workout.date), workout.exercises.length, workout.setCount),
      ),
      trailing:
          existing.contains(importedFingerprint(workout))
              ? Icon(
                Icons.check_circle_outline_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              )
              : null,
      children: [
        for (final exercise in workout.exercises)
          ListTile(
            title: Text(exercise.name),
            subtitle: Text(
              exercise.sets
                  .map((s) => '${formatWeight(s.weight)} kg × ${s.reps}')
                  .join(' · '),
            ),
          ),
      ],
    ),
  );

  void showAll(String title, Widget Function(int) itemBuilder, int count) {
    showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                itemCount: count,
                itemBuilder: (context, i) => itemBuilder(i),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(appText(context).transferCloseAction),
              ),
            ],
          ),
    );
  }

  void change({
    int? date,
    int? exercise,
    int? weight,
    int? reps,
    int? session,
    bool sessionChanged = false,
  }) {
    setState(() {
      mapping = CsvMapping(
        date: date ?? mapping.date,
        exercise: exercise ?? mapping.exercise,
        weight: weight ?? mapping.weight,
        reps: reps ?? mapping.reps,
        session:
            sessionChanged ? (session == -1 ? null : session) : mapping.session,
      );
      preview = null;
      error = null;
    });
  }

  Widget selector(
    String label,
    int value,
    void Function(int) onChanged, {
    bool optional = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DropdownButtonFormField<int>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      isExpanded: true,
      items: [
        DropdownMenuItem(
          value: -1,
          child: Text(
            optional
                ? appText(context).transferNoColumnWorkout
                : appText(context).transferChooseColumn,
          ),
        ),
        for (var i = 0; i < widget.sheet.headers.length; i++)
          DropdownMenuItem(
            value: i,
            child: Text(
              '${i + 1}. ${widget.sheet.headers[i]}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    ),
  );

  Future<void> review() async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result = widget.sheet.preview(mapping);
      final fingerprints =
          await (widget.controller.repository as TransferRepository)
              .existingFingerprints();
      if (mounted) {
        setState(() {
          preview = result;
          existing = fingerprints;
        });
      }
    } on ValidationException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (_) {
      if (mounted) setState(() => error = appText(context).transferCsvReviewError);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> import() async {
    if (busy || preview == null) return;
    final ready =
        preview!.workouts
            .where((w) => !existing.contains(importedFingerprint(w)))
            .toList();
    if (ready.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(appText(context).transferImportSessionsTitle),
            content: Text(
              appText(context).transferImportSessionsBody(ready.length, ready.fold<int>(0, (n, w) => n + w.setCount), preview!.errors.length),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(appText(context).cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(appText(context).transferImportAction),
              ),
            ],
          ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => busy = true);
    ImportSummary? summary;
    final ok = await widget.controller.run(() async {
      summary = await (widget.controller.repository as TransferRepository)
          .importWorkouts(preview!.workouts);
    });
    if (!mounted) return;
    setState(() => busy = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            appText(context).transferImportedSummary(summary!.added, summary!.duplicates),
          ),
        ),
      );
      Navigator.pop(context);
    } else {
      setState(() => error = widget.controller.error ?? appText(context).transferImportError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final duplicateCount =
        preview?.workouts
            .where((w) => existing.contains(importedFingerprint(w)))
            .length ??
        0;
    final newCount = (preview?.workouts.length ?? 0) - duplicateCount;
    return Scaffold(
      appBar: AppBar(title: Text(appText(context).transferImportSheetTitle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            appText(context).transferRowsFound(widget.sheet.rows.length),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            appText(context).transferMapHelp,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          selector(appText(context).transferDate, mapping.date, (v) => change(date: v)),
          selector(
            appText(context).transferSessionOptional,
            mapping.session ?? -1,
            (v) => change(session: v, sessionChanged: true),
            optional: true,
          ),
          selector(appText(context).transferExercise, mapping.exercise, (v) => change(exercise: v)),
          selector(appText(context).transferWeightKg, mapping.weight, (v) => change(weight: v)),
          selector(appText(context).transferReps, mapping.reps, (v) => change(reps: v)),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: busy ? null : review,
            child: Text(appText(context).transferReviewImport),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(
                error!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          if (busy)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (preview != null) ...[
            const SizedBox(height: 28),
            Text(
              appText(context).transferPreviewSummary(newCount, duplicateCount, preview!.errors.length),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              appText(context).transferValidRows(preview!.validRows, preview!.totalRows),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            for (final w in preview!.workouts.take(10)) workoutTile(w),
            if (preview!.workouts.length > 10)
              TextButton(
                onPressed:
                    () => showAll(
                      appText(context).transferAllSessions,
                      (i) => workoutTile(preview!.workouts[i]),
                      preview!.workouts.length,
                    ),
                child: Text(appText(context).transferSeeSessions(preview!.workouts.length)),
              ),
            for (final issue in preview!.errors.take(15))
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  issue,
                  style: const TextStyle(color: Colors.orangeAccent),
                ),
              ),
            if (preview!.errors.length > 15)
              TextButton(
                onPressed:
                    () => showAll(
                      appText(context).transferErrorRows,
                      (i) => Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(preview!.errors[i]),
                      ),
                      preview!.errors.length,
                    ),
                child: Text(appText(context).transferSeeErrors(preview!.errors.length)),
              ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: busy || newCount == 0 ? null : import,
              icon: const Icon(Icons.check_rounded),
              label: Text(appText(context).transferImportNew),
            ),
          ],
        ],
      ),
    );
  }
}
