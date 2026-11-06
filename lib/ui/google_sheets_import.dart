import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../application/workout_controller.dart';
import '../application/localization.dart';
import '../domain/transfer.dart';
import '../domain/workout.dart';
import '../domain/sheet_context.dart';
import '../data/profile_store.dart';
import 'accounts.dart';
import 'data_transfer.dart';

class GoogleSheetsImportScreen extends StatefulWidget {
  const GoogleSheetsImportScreen({
    super.key,
    required this.controller,
    this.forAssistant = false,
    this.loadOnly = false,
  });
  final WorkoutController controller;
  final bool forAssistant;
  final bool loadOnly;

  @override
  State<GoogleSheetsImportScreen> createState() =>
      _GoogleSheetsImportScreenState();
}

class _GoogleSheetsImportScreenState extends State<GoogleSheetsImportScreen> {
  static const channel = MethodChannel('com.gymia.app/google-sheets');
  final search = TextEditingController();
  List<Map<String, String>> files = [];
  String? nextPage;
  String? error;
  String query = '';
  String progress = '';
  bool busy = true;
  bool authorized = false;
  bool reconnect = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => connect());
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  void showError(Object e) {
    if (!mounted) return;
    setState(() {
      error = switch (e) {
        PlatformException p => googleSheetsError(context, p.code, p.message),
        ValidationException v => v.message,
        FormatException f => f.message,
        _ => appText(context).sheetsReadError,
      };
      reconnect = e is PlatformException && e.code == 'GOOGLE_AUTH_REQUIRED';
    });
  }

  Future<void> connect({bool chooseAccount = false}) async {
    if (!mounted) return;
    setState(() {
      busy = true;
      authorized = false;
      files = [];
      nextPage = null;
      error = null;
      progress = appText(context).sheetsAuthorizeProgress;
    });
    try {
      if (chooseAccount) {
        await Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const AccountsScreen()));
        if (mounted &&
            widget.controller.profileId != 'local' &&
            ProfileStore.instance.activeId == widget.controller.profileId) {
          // Resume onboarding after selecting a different saved Google profile.
          await connect();
        }
        return;
      }
      final bool? granted;
      if (widget.controller.profileId == 'local') {
        // Native refuses unscoped reads; retained for legacy channel fixtures.
        granted = await channel.invokeMethod<bool>('authorize');
      } else {
        await ProfileStore.instance.authorizeSheets(
          profileId: widget.controller.profileId,
        );
        granted = true;
      }
      if (!mounted) return;
      if (granted != true) {
        setState(() => error = appText(context).sheetsAuthIncomplete);
        return;
      }
      setState(() => authorized = true);
      await loadFiles();
    } catch (e) {
      showError(e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> loadFiles({bool more = false}) async {
    setState(() {
      busy = true;
      error = null;
      progress = appText(context).sheetsSearchProgress;
      if (!more) {
        query = search.text.trim();
        files = [];
        nextPage = null;
      }
    });
    try {
      final response = await channel.invokeMapMethod<String, dynamic>('list', {
        'query': query,
        if (widget.controller.profileId != 'local')
          'expectedSubject': ProfileStore.instance.active?.subject,
        if (more) 'pageToken': nextPage,
      });
      if (!mounted || response == null) return;
      if (widget.controller.profileId != 'local' &&
          ProfileStore.instance.activeId != widget.controller.profileId) {
        throw FormatException(appText(context).sheetsSearchAccountChanged);
      }
      final found =
          (response['files'] as List)
              .map(
                (f) => {
                  'id': (f as Map)['id'] as String,
                  'name': f['name'] as String,
                },
              )
              .toList();
      setState(() {
        files.addAll(found.where((f) => !files.any((v) => v['id'] == f['id'])));
        final page = response['nextPageToken'] as String?;
        nextPage = page == null || page.isEmpty ? null : page;
        if (response['incompleteSearch'] == true) {
          error = appText(context).sheetsPartial;
        }
      });
    } catch (e) {
      showError(e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> choose(Map<String, String> file) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
      progress = appText(context).sheetsLoadingTabs(file['name']!);
    });
    try {
      final tabs = await channel.invokeListMethod<String>('tabs', {
        'id': file['id'],
        if (widget.controller.profileId != 'local')
          'expectedSubject': ProfileStore.instance.active?.subject,
      });
      if (!mounted) return;
      if (widget.controller.profileId != 'local' &&
          ProfileStore.instance.activeId != widget.controller.profileId) {
        throw FormatException(appText(context).sheetsChooseAccountChanged);
      }
      if (tabs == null || tabs.isEmpty) {
        throw ValidationException(appText(context).sheetNoTabs);
      }
      setState(() => progress = '');
      final title = await showDialog<String>(
        context: context,
        builder:
            (context) => SimpleDialog(
              title: Text(appText(context).sheetChooseTab),
              children: [
                for (final tab in tabs)
                  SimpleDialogOption(
                    onPressed: () => Navigator.pop(context, tab),
                    child: Text(tab),
                  ),
              ],
            ),
      );
      if (title == null || !mounted) return;
      setState(() => progress = appText(context).sheetsReadingTab(title));
      final rows = await channel.invokeListMethod<dynamic>('read', {
        'id': file['id'],
        if (widget.controller.profileId != 'local')
          'expectedSubject': ProfileStore.instance.active?.subject,
        'title': title,
      });
      if (!mounted) return;
      if (widget.controller.profileId != 'local' &&
          ProfileStore.instance.activeId != widget.controller.profileId) {
        throw FormatException(appText(context).sheetsReadAccountChanged);
      }
      final cells = <List<String>>[
        for (final row in rows ?? [])
          [for (final cell in row as List) cell.toString()],
      ];
      if (widget.forAssistant) {
        final snapshot = SheetContext(
          id: file['id']!,
          name: file['name']!,
          title: title,
          loadedAt: DateTime.now(),
          rows: cells,
        );
        setState(() => progress = '');
        final confirmed = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder:
                (_) => SheetContextPreviewScreen(
                  sheet: snapshot,
                  loadOnly: widget.loadOnly,
                ),
          ),
        );
        if (confirmed == true && mounted) Navigator.pop(context, snapshot);
        return;
      }
      final sheet = CsvSheet.fromCells(cells);
      setState(() => progress = '');
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder:
              (_) =>
                  CsvImportScreen(controller: widget.controller, sheet: sheet),
        ),
      );
    } catch (e) {
      showError(e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(appText(context).sheetsTitle)),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          appText(context).sheetsChooseTitle,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          widget.forAssistant
              ? appText(context).sheetsAssistantIntro
              : appText(context).sheetsImportIntro,
        ),
        const SizedBox(height: 16),
        if (authorized) ...[
          TextField(
            controller: search,
            enabled: !busy,
            decoration: InputDecoration(
              labelText: appText(context).sheetsSearch,
              suffixIcon: IconButton(
                tooltip: appText(context).sheetsSearchTooltip,
                onPressed: busy ? null : () => loadFiles(),
                icon: const Icon(Icons.search),
              ),
            ),
            onSubmitted: (_) => loadFiles(),
          ),
          const SizedBox(height: 16),
          for (final file in files)
            Card(
              child: ListTile(
                leading: const Icon(Icons.table_chart_outlined),
                title: Text(file['name']!),
                trailing: const Icon(Icons.chevron_right),
                enabled: !busy,
                onTap: () => choose(file),
              ),
            ),
          if (!busy && error == null && files.isEmpty)
            Text(appText(context).sheetsNoResults),
          if (nextPage != null)
            TextButton(
              onPressed: busy ? null : () => loadFiles(more: true),
              child: Text(appText(context).sheetsLoadMore),
            ),
        ],
        if (busy && progress.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Center(child: CircularProgressIndicator()),
          const SizedBox(height: 12),
          Text(progress, textAlign: TextAlign.center),
        ],
        if (error != null) ...[
          const SizedBox(height: 16),
          Text(
            error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          if (authorized && !reconnect)
            TextButton(
              onPressed: busy ? null : () => loadFiles(),
              child: Text(appText(context).sheetsRetry),
            ),
        ],
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: busy ? null : () => connect(chooseAccount: authorized),
          icon: const Icon(Icons.account_circle_outlined),
          label: Text(
            authorized
                ? appText(context).sheetsReconnect
                : appText(context).sheetsConnect,
          ),
        ),
      ],
    ),
  );
}

class SheetContextPreviewScreen extends StatelessWidget {
  const SheetContextPreviewScreen({
    super.key,
    required this.sheet,
    this.loadOnly = false,
  });
  final SheetContext sheet;
  final bool loadOnly;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(appText(context).sheetReview)),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          '${sheet.name} · ${sheet.title}',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(appText(context).sheetRowsRead(sheet.rows.length)),
        const SizedBox(height: 12),
        Text(
          loadOnly
              ? appText(context).sheetLoadPending
              : appText(context).sheetSendToAi,
        ),
        const SizedBox(height: 12),
        Text(
          sheet.source == 'google'
              ? appText(context).sheetReadOnlyGoogle
              : appText(context).sheetReadOnlyFile,
        ),
        const SizedBox(height: 20),
        for (var i = 0; i < sheet.rows.length && i < 12; i++)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SelectableText(
                '${appText(context).rowLabel} ${i + 1}: ${sheet.rows[i].join(' | ')}',
              ),
            ),
          ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: () => Navigator.pop(context, true),
          icon: const Icon(Icons.auto_awesome_outlined),
          label: Text(
            loadOnly
                ? appText(context).sheetsLoad
                : appText(context).sheetsLoadAnalyze,
          ),
        ),
      ],
    ),
  );
}
