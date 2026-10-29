import 'package:flutter/material.dart';
import '../data/companion_store.dart';
import '../domain/companion.dart';

class CompanionDashboard extends StatefulWidget {
  const CompanionDashboard({
    super.key,
    required this.profileId,
    required this.onOpen,
  });
  final String profileId;
  final void Function(Companion) onOpen;

  @override
  State<CompanionDashboard> createState() => _CompanionDashboardState();
}

class _CompanionDashboardState extends State<CompanionDashboard> {
  late final store = CompanionStore(profileId: widget.profileId);
  List<Companion> companions = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    try {
      final loaded = await store.load();
      if (mounted) {
        setState(() {
          companions = loaded;
          loading = false;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          loading = false;
          error = 'No se pudieron cargar los acompañantes: $e';
        });
      }
    }
  }

  Future<void> edit([Companion? original]) async {
    final result = await showDialog<Companion>(
      context: context,
      builder: (_) => _CompanionEditor(original: original),
    );
    if (result == null) return;
    try {
      await store.upsert(result);
      await refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('No se pudo guardar: $e')));
      }
    }
  }

  Future<void> remove(Companion companion) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('¿Borrar ${companion.name}?'),
            content: const Text(
              'Se borrarán su chat, archivos y conexión local de Sheets. La hoja de Google y los registros de actividad no se borrarán.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Borrar'),
              ),
            ],
          ),
    );
    if (confirmed != true) return;
    try {
      await store.delete(companion.id);
      await refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('No se pudo borrar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('TrackIA')),
    floatingActionButton: FloatingActionButton.extended(
      key: const Key('companion-create'),
      onPressed: () => edit(),
      icon: const Icon(Icons.add),
      label: const Text('Crear acompañante'),
    ),
    body:
        loading
            ? const Center(child: CircularProgressIndicator())
            : error != null
            ? Center(child: TextButton(onPressed: refresh, child: Text(error!)))
            : ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 104),
              children: [
                Text(
                  'Tus acompañantes',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Elige con quién trabajar. Cada uno conserva su conversación y puede usar una hoja o pestaña de Google distinta.',
                ),
                const SizedBox(height: 20),
                if (companions.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Aún no tienes acompañantes. Crea uno para empezar.',
                      ),
                    ),
                  ),
                for (final companion in companions)
                  Card(
                    key: Key('companion-${companion.id}'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.auto_awesome_outlined),
                        ),
                        title: Text(companion.name),
                        subtitle: Text(companion.description),
                        onTap: () => widget.onOpen(companion),
                        trailing: PopupMenuButton<String>(
                          tooltip: 'Opciones de ${companion.name}',
                          onSelected:
                              (choice) =>
                                  choice == 'edit'
                                      ? edit(companion)
                                      : remove(companion),
                          itemBuilder:
                              (_) => const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Editar'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Borrar'),
                                ),
                              ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
  );
}

class _CompanionEditor extends StatefulWidget {
  const _CompanionEditor({this.original});
  final Companion? original;

  @override
  State<_CompanionEditor> createState() => _CompanionEditorState();
}

class _CompanionEditorState extends State<_CompanionEditor> {
  late final name = TextEditingController(text: widget.original?.name ?? '');
  late final description = TextEditingController(
    text: widget.original?.description ?? '',
  );
  late final prompt = TextEditingController(
    text: widget.original?.prompt ?? '',
  );

  @override
  void dispose() {
    name.dispose();
    description.dispose();
    prompt.dispose();
    super.dispose();
  }

  void save() {
    try {
      final original = widget.original;
      final value =
          original == null
              ? Companion.custom(
                name: name.text,
                prompt: prompt.text,
              ).copyWith(description: description.text)
              : original.copyWith(
                name: name.text,
                description: description.text,
                prompt: prompt.text,
              );
      Navigator.pop(context, value);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.original == null ? 'Crear acompañante' : 'Editar acompañante',
    ),
    content: SizedBox(
      width: 520,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              maxLength: 80,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            TextField(
              controller: description,
              maxLength: 120,
              decoration: const InputDecoration(labelText: '¿Para qué sirve?'),
            ),
            TextField(
              controller: prompt,
              maxLines: 8,
              maxLength: 8000,
              decoration: const InputDecoration(
                labelText: 'Instrucciones y personalidad',
                helperText:
                    'El asistente seguirá estas instrucciones en este acompañante.',
              ),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(onPressed: save, child: const Text('Guardar')),
    ],
  );
}
