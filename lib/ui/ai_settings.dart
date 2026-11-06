import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../data/ai_client.dart';
import '../data/chatgpt_auth.dart';
import '../data/ai_model_catalog.dart';
import '../data/ai_settings_store.dart';
import '../data/local_model_preflight.dart';
import '../data/progress_repository.dart';
import '../domain/ai_config.dart';
import '../domain/workout.dart';
import 'package:uuid/uuid.dart';
import '../application/localization.dart';
import 'ai_per_companion.dart';

class AiSettingsScreen extends StatefulWidget {
  const AiSettingsScreen({
    super.key,
    this.catalog,
    this.client,
    this.profileId = 'local',
    this.chatGptAuth,
    this.progress,
  });
  final String profileId;

  /// With it, the screen lists «Por acompañante» (US11).
  final ProgressRepository? progress;
  final ChatGptAuth? chatGptAuth;
  final AiModelCatalog? catalog;
  final AiClient? client;
  @override
  State<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends State<AiSettingsScreen> {
  final base = TextEditingController();
  final model = TextEditingController();
  final key = TextEditingController();
  late final store = AiSettingsStore(profileId: widget.profileId);
  late final chatGpt =
      widget.chatGptAuth ?? ChatGptAuth(profileId: widget.profileId);
  List<ChatGptAccount> chatGptAccounts = [];
  String? chatGptClientId;
  String? localModelPath, localProjectorPath;
  String? localMemoryStatus;
  LocalModelMemory? localMemory;
  int? localModelBytes, localProjectorBytes;
  int localContextLength = LocalModelMemory.trackiaRecommendedContextLength;
  ChatGptAccount? get selectedChatGpt =>
      chatGptAccounts.where((a) => a.clientId == chatGptClientId).firstOrNull;
  AiService service = AiService.opencodeGo;
  AiProtocol protocol = AiProtocol.chatCompletions;
  bool busy = true;
  bool reveal = false;
  String? status;
  String? catalogStatus;
  List<AiModelOption> models = [];
  bool loadingModels = false;
  bool manualModel = false;
  Timer? catalogDebounce;
  int catalogRequest = 0;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final config = await store.load();
      final accounts = await chatGpt.accounts();
      if (!mounted) return;
      setState(() {
        service = config?.service ?? AiService.opencodeGo;
        protocol = config?.protocol ?? service.defaultProtocol;
        base.text = config?.baseUrl ?? service.baseUrl;
        model.text = config?.model ?? '';
        key.text = config?.apiKey ?? '';
        chatGptAccounts = accounts;
        chatGptClientId = config?.chatGptClientId;
        localModelPath = config?.localModelPath;
        localProjectorPath = config?.localProjectorPath;
        localContextLength =
            config?.localContextLength ??
            LocalModelMemory.trackiaRecommendedContextLength;
      });
    } catch (_) {
      if (mounted) {
        setState(() => status = 'No se pudo leer la configuración guardada.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
    if (mounted &&
        (key.text.trim().isNotEmpty || selectedChatGpt?.canUsePlan == true)) {
      await fetchModels();
    }
  }

  AiConfig config() => AiConfig(
    service: service,
    baseUrl: base.text.trim(),
    model: model.text.trim(),
    protocol: protocol,
    apiKey: service == AiService.chatgpt ? '' : key.text.trim(),
    chatGptClientId: service == AiService.chatgpt ? chatGptClientId : null,
    localModelPath: localModelPath,
    localProjectorPath: localProjectorPath,
    localContextLength: localContextLength,
    profileId: widget.profileId,
  );

  static String _contextLabel(int tokens) =>
      '${tokens >= 1024 ? (tokens / 1024).round().toString() : tokens}${tokens >= 1024 ? 'k' : ''} tokens';

  Future<void> pickLocalFile({required bool projector}) async {
    try {
      final selection = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['gguf'],
        withReadStream: true,
      );
      final picked = selection?.files.single;
      if (picked == null) return;
      final directory = Directory(
        '${(await getApplicationSupportDirectory()).path}/trackia_models',
      );
      await directory.create(recursive: true);
      final target = File(
        '${directory.path}/${projector ? 'mmproj_' : 'model_'}${picked.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')}',
      );
      final stream = picked.readStream;
      if (stream != null) {
        final sink = target.openWrite();
        await sink.addStream(stream);
        await sink.flush();
        await sink.close();
      } else if (picked.path != null) {
        await File(picked.path!).copy(target.path);
      } else {
        throw StateError('Android no entregó acceso al archivo seleccionado.');
      }
      if (!mounted) return;
      setState(() {
        if (projector) {
          localProjectorPath = target.path;
        } else {
          localModelPath = target.path;
          model.text = picked.name;
        }
        localMemoryStatus = null;
      });
      await refreshLocalMemory();
    } catch (error) {
      if (mounted) {
        setState(() => status = 'No se pudo importar el archivo GGUF: $error');
      }
    }
  }

  Future<void> refreshLocalMemory() async {
    final memory = await LocalModelMemory.read();
    if (memory == null || localModelPath == null || !mounted) return;
    final modelSize = await File(localModelPath!).length();
    final projectorSize = localProjectorPath == null
        ? 0
        : await File(localProjectorPath!).length();
    if (!mounted) return;
    setState(() {
      localMemory = memory;
      localModelBytes = modelSize;
      localProjectorBytes = projectorSize;
      localMemoryStatus = memory.assess(
        modelBytes: modelSize,
        projectorBytes: projectorSize,
        contextLength: localContextLength,
      );
    });
  }

  Widget localMemoryComparison() {
    final memory = localMemory!;
    final modelBytes = localModelBytes!;
    final projectorBytes = localProjectorBytes!;
    final afterModel = memory.projectedAvailableAfterModelBytes(
      modelBytes: modelBytes,
      projectorBytes: projectorBytes,
    );
    final projected = memory.projectedAvailableBytes(
      modelBytes: modelBytes,
      projectorBytes: projectorBytes,
      contextLength: localContextLength,
    );
    final shortfall = memory.estimatedShortfallBytes(
      modelBytes: modelBytes,
      projectorBytes: projectorBytes,
      contextLength: localContextLength,
    );
    final contextRange = memory.estimateContextBytes(localContextLength);
    final total = memory.totalBytes;
    String format(int bytes) {
      const mb = 1024 * 1024;
      if (bytes >= 1024 * mb) {
        return '${(bytes / (1024 * mb)).toStringAsFixed(1)} GB';
      }
      return '${(bytes / mb).round()} MB';
    }

    Widget bar(String label, int bytes) => Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text(label), Text(format(bytes))],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: total == 0 ? 0 : (bytes / total).clamp(0.0, 1.0),
            minHeight: 8,
            borderRadius: BorderRadius.circular(8),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          memory.assess(
            modelBytes: modelBytes,
            projectorBytes: projectorBytes,
            contextLength: localContextLength,
          ),
        ),
        bar('Disponible ahora', memory.availableBytes),
        bar('Después de modelo y proyector', afterModel),
        bar('Después + contexto seleccionado', projected),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'El contexto de ${_contextLabel(localContextLength)} añadiría aproximadamente ${format(contextRange.minimum)}–${format(contextRange.maximum)} de RAM.',
          ),
        ),
        if (shortfall > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'La estimación supera lo disponible por ${format(shortfall)}.',
            ),
          ),
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(
            'Estimación orientativa de pesos y proyector; el contexto elegido añade consumo y puede variar según el modelo.',
          ),
        ),
      ],
    );
  }

  Future<void> connectChatGpt({
    bool usePlan = false,
    bool newAccount = false,
  }) async {
    await run(() async {
      final account = await chatGpt.connect(
        clientId: newAccount ? null : chatGptClientId,
        usePlan:
            usePlan || (!newAccount && selectedChatGpt?.canUsePlan == true),
        consent: usePlan,
        newRegistration: newAccount,
      );
      final accounts = await chatGpt.accounts();
      if (!mounted) return;
      setState(() {
        invalidateCatalog();
        model.clear();
        chatGptAccounts = accounts;
        chatGptClientId = account.clientId;
        status = account.canUsePlan
            ? 'Cuenta conectada. Elige un modelo y prueba la conexión para usar el asistente.'
            : 'Identidad conectada. Puedes autorizar por separado el uso de tu plan ChatGPT.';
      });
    });
    if (mounted && selectedChatGpt?.canUsePlan == true) await fetchModels();
  }

  Future<void> disconnectChatGpt() => run(() async {
    final id = chatGptClientId;
    if (id == null) return;
    final revoked = await chatGpt.disconnect(id);
    final saved = await store.load();
    if (saved?.usesChatGpt == true && saved?.chatGptClientId == id) {
      await store.delete();
    }
    final accounts = await chatGpt.accounts();
    if (!mounted) return;
    setState(() {
      invalidateCatalog();
      chatGptAccounts = accounts;
      status = revoked
          ? 'Sesión ChatGPT desconectada.'
          : 'Sesión desconectada en este móvil. No se confirmó la revocación remota; desconecta TrackIA también en los ajustes de ChatGPT.';
    });
  });

  Future<void> run(Future<void> Function() action) async {
    if (busy) return;
    setState(() {
      busy = true;
      status = null;
    });
    try {
      await action();
    } on ValidationException catch (e) {
      if (mounted) setState(() => status = e.message);
    } catch (error) {
      if (mounted) {
        final details = service == AiService.local ? ': $error' : '';
        setState(() => status = 'No se pudo completar la operación$details');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void updateModelProtocol(String value) {
    if (service != AiService.opencodeGo && service != AiService.opencodeZen) {
      return;
    }
    setState(() {
      protocol = service.protocolForModel(value);
    });
  }

  void invalidateCatalog() {
    catalogDebounce?.cancel();
    catalogRequest++;
    models = [];
    loadingModels = false;
    catalogStatus = null;
  }

  void keyChanged(String _) {
    setState(invalidateCatalog);
    if (key.text.trim().isEmpty) return;
    catalogDebounce = Timer(const Duration(milliseconds: 900), fetchModels);
  }

  Future<void> fetchModels() async {
    catalogDebounce?.cancel();
    if (busy || !mounted) return;
    final requested = config();
    final ticket = ++catalogRequest;
    setState(() {
      loadingModels = true;
      catalogStatus = null;
    });
    try {
      final result = await (widget.catalog ?? AiModelCatalog()).list(requested);
      if (!mounted || ticket != catalogRequest) return;
      setState(() {
        models = result;
        if (model.text.trim().isEmpty) {
          // A real catalog entry, never a static default ID. Do not replace
          // an existing selection merely because it disappears from the list.
          model.text = result.first.id;
          if (service != AiService.custom) {
            protocol =
                result.first.protocol ??
                service.protocolForModel(result.first.id);
          }
        }
        catalogStatus = service == AiService.chatgpt
            ? 'Modelos disponibles para esta cuenta: ${result.length}. La prueba de conexión confirma el acceso al elegido.'
            : '${result.length} modelos obtenidos del proveedor. La prueba de conexión confirma si tu clave puede usar el elegido.';
      });
    } on ValidationException catch (e) {
      if (mounted && ticket == catalogRequest) {
        setState(() {
          catalogStatus = e.message;
          manualModel = true;
        });
      }
    } catch (_) {
      if (mounted && ticket == catalogRequest) {
        setState(() {
          catalogStatus = service == AiService.chatgpt
              ? 'No se pudo obtener el catálogo de esta cuenta. Comprueba la conexión e inténtalo de nuevo.'
              : 'No se pudo obtener el catálogo. Puedes volver a intentarlo o indicar el modelo manualmente.';
          manualModel = true;
        });
      }
    } finally {
      if (mounted && ticket == catalogRequest) {
        setState(() => loadingModels = false);
      }
    }
  }

  @override
  void dispose() {
    unawaited(chatGpt.cancel());
    catalogDebounce?.cancel();
    catalogRequest++;
    base.dispose();
    model.dispose();
    key.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(appText(context).aiProviderTitle)),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          appText(context).aiConnectTitle,
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Text(
          'Elige un proveedor en la nube o ejecuta un modelo local en este móvil. Los modelos locales pueden funcionar sin conexión; el rendimiento depende de la memoria y del modelo elegido.',
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<AiService>(
          key: ValueKey('service-$service'),
          initialValue: service,
          isExpanded: true,
          decoration: InputDecoration(labelText: appText(context).aiProviderLabel),
          items: [
            for (final s in AiService.values)
              DropdownMenuItem(value: s, child: Text(s.label)),
          ],
          onChanged: busy
              ? null
              : (s) {
                  if (s == null) return;
                  setState(() {
                    invalidateCatalog();
                    service = s;
                    protocol = s.defaultProtocol;
                    base.text = s.baseUrl;
                    model.text = s == AiService.local && localModelPath != null
                        ? localModelPath!.split(Platform.pathSeparator).last
                        : '';
                    key.clear();
                    status = null;
                    manualModel = false;
                  });
                  if (s == AiService.chatgpt &&
                      selectedChatGpt?.canUsePlan == true) {
                    unawaited(fetchModels());
                  }
                },
        ),
        const SizedBox(height: 16),
        if (service == AiService.local) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Modelo GGUF',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    localModelPath?.split(Platform.pathSeparator).last ??
                        'No hay modelo importado.',
                  ),
                  OutlinedButton.icon(
                    onPressed: busy
                        ? null
                        : () => pickLocalFile(projector: false),
                    icon: const Icon(Icons.download),
                    label: const Text('Seleccionar / importar modelo .gguf'),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Contexto del modelo local',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'TrackIA recomienda ${_contextLabel(LocalModelMemory.trackiaRecommendedContextLength)} para sus instrucciones, historial y datos. La recomendación es para las necesidades de la app, no para el límite de este GGUF. Si el modelo no soporta el tamaño elegido, puede fallar; tú decides si bajarlo.',
                  ),
                  Slider(
                    key: const Key('local-context-slider'),
                    value: LocalModelMemory.contextChoices
                        .indexOf(localContextLength)
                        .clamp(0, LocalModelMemory.contextChoices.length - 1)
                        .toDouble(),
                    min: 0,
                    max: (LocalModelMemory.contextChoices.length - 1)
                        .toDouble(),
                    divisions: LocalModelMemory.contextChoices.length - 1,
                    label: _contextLabel(localContextLength),
                    onChanged: busy
                        ? null
                        : (value) => setState(() {
                            localContextLength =
                                LocalModelMemory.contextChoices[value.round()];
                          }),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Seleccionado: ${_contextLabel(localContextLength)}',
                      ),
                      if (localContextLength !=
                          LocalModelMemory.trackiaRecommendedContextLength)
                        TextButton(
                          onPressed: busy
                              ? null
                              : () => setState(() {
                                  localContextLength = LocalModelMemory
                                      .trackiaRecommendedContextLength;
                                }),
                          child: const Text('Usar recomendación'),
                        ),
                    ],
                  ),
                  const Divider(),
                  const Text(
                    'Proyector visual (opcional)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Añádelo para usar imágenes. MiniCPM‑V necesita el archivo mmproj GGUF correspondiente.',
                  ),
                  Text(
                    localProjectorPath?.split(Platform.pathSeparator).last ??
                        'Sin proyector visual.',
                  ),
                  OutlinedButton.icon(
                    onPressed: busy
                        ? null
                        : () => pickLocalFile(projector: true),
                    icon: const Icon(Icons.image_search),
                    label: const Text('Seleccionar proyector mmproj'),
                  ),
                  if (localMemoryStatus != null && localMemory == null) ...[
                    const SizedBox(height: 8),
                    Text(localMemoryStatus!),
                  ],
                  if (localMemory != null &&
                      localModelBytes != null &&
                      localProjectorBytes != null)
                    localMemoryComparison(),
                  const Text(
                    'La memoria disponible se informa aparte. La recomendación de 8192 tokens responde a lo que TrackIA necesita; el GGUF puede no soportarlo y tú puedes elegir otro tamaño.',
                  ),
                  TextButton.icon(
                    onPressed: busy ? null : refreshLocalMemory,
                    icon: const Icon(Icons.memory),
                    label: const Text('Volver a calcular memoria disponible'),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          if (service == AiService.custom) ...[
            TextField(
              key: const Key('ai-base-url'),
              controller: base,
              enabled: !busy,
              onChanged: (_) => setState(invalidateCatalog),
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(
                labelText: 'URL base de la API',
                helperText: 'HTTPS, por ejemplo https://tu-proveedor.com/v1',
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (service == AiService.chatgpt) ...[
            const Text(
              'Usa tu plan si tu cuenta y espacio son elegibles. El uso consume sus límites compartidos. No da acceso a tus conversaciones de ChatGPT.',
            ),
            if (chatGptAccounts.isNotEmpty)
              DropdownButtonFormField<String>(
                key: ValueKey('chatgpt-account-$chatGptClientId'),
                initialValue: chatGptClientId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Cuenta ChatGPT'),
                items: [
                  for (final account in chatGptAccounts)
                    DropdownMenuItem(
                      value: account.clientId,
                      child: Text(
                        account.label,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: busy
                    ? null
                    : (id) {
                        setState(() {
                          chatGptClientId = id;
                          invalidateCatalog();
                          model.clear();
                        });
                        if (selectedChatGpt?.canUsePlan == true) {
                          unawaited(fetchModels());
                        }
                      },
              ),
            Text(
              selectedChatGpt?.connected == true
                  ? selectedChatGpt!.canUsePlan
                        ? 'Conectada · permiso de uso del plan concedido'
                        : 'Conectada · solo identidad'
                  : 'ChatGPT sin conectar',
            ),
            OutlinedButton(
              key: const Key('chatgpt-connect'),
              onPressed: busy ? null : () => connectChatGpt(),
              child: const Text('Continuar con ChatGPT'),
            ),
            if (selectedChatGpt?.connected == true)
              FilledButton(
                key: const Key('chatgpt-enable-plan'),
                onPressed: busy ? null : () => connectChatGpt(usePlan: true),
                child: Text(
                  selectedChatGpt!.canUsePlan
                      ? 'Revisar permiso de uso del plan'
                      : 'Autorizar uso de mi plan ChatGPT',
                ),
              ),
            if (chatGptAccounts.isNotEmpty)
              TextButton(
                onPressed: busy ? null : () => connectChatGpt(newAccount: true),
                child: const Text('Añadir otra cuenta o espacio'),
              ),
            TextButton(
              onPressed: busy ? null : () => run(chatGpt.showUsage),
              child: const Text('Ver uso y permisos en ChatGPT'),
            ),
            if (selectedChatGpt?.connected == true)
              TextButton(
                key: const Key('chatgpt-disconnect'),
                onPressed: busy ? null : disconnectChatGpt,
                child: const Text('Desconectar ChatGPT'),
              ),
            if (busy)
              TextButton(
                key: const Key('chatgpt-cancel'),
                onPressed: chatGpt.cancel,
                child: const Text('Cancelar conexión'),
              ),
          ] else
            TextField(
              key: const Key('ai-api-key'),
              controller: key,
              enabled: !busy,
              onChanged: keyChanged,
              onSubmitted: (_) => fetchModels(),
              obscureText: !reveal,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: 'Clave API',
                suffixIcon: IconButton(
                  tooltip: reveal ? 'Ocultar clave' : 'Mostrar clave',
                  onPressed: () => setState(() => reveal = !reveal),
                  icon: Icon(reveal ? Icons.visibility_off : Icons.visibility),
                ),
              ),
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const Key('ai-load-models'),
            onPressed: busy || loadingModels ? null : fetchModels,
            icon: const Icon(Icons.refresh),
            label: Text(
              loadingModels
                  ? 'Consultando modelos…'
                  : 'Obtener / actualizar modelos',
            ),
          ),
          if (loadingModels) const LinearProgressIndicator(),
          if (catalogStatus != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(catalogStatus!),
            ),
          if (models.isNotEmpty)
            DropdownButtonFormField<String>(
              key: ValueKey(
                'catalog-${models.map((m) => m.id).join('|')}-${config().modelId}',
              ),
              initialValue: models.any((m) => m.id == config().modelId)
                  ? config().modelId
                  : null,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Modelo'),
              hint: const Text('Elige un modelo del catálogo'),
              items: [
                for (final m in models)
                  DropdownMenuItem(
                    value: m.id,
                    child: Text(
                      m.label == m.id ? m.id : '${m.label} · ${m.id}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: busy
                  ? null
                  : (id) {
                      if (id == null) return;
                      final option = models.singleWhere((m) => m.id == id);
                      setState(() {
                        model.text = id;
                        if (service != AiService.custom) {
                          protocol =
                              option.protocol ?? service.protocolForModel(id);
                        }
                      });
                    },
            ),
          if (model.text.isNotEmpty &&
              !models.any((m) => m.id == config().modelId))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Modelo actual: ${model.text}. Se conserva aunque no aparezca en el catálogo.',
              ),
            ),
          if (service != AiService.chatgpt)
            TextButton(
              onPressed: busy
                  ? null
                  : () => setState(() => manualModel = !manualModel),
              child: Text(
                manualModel
                    ? 'Ocultar identificador manual'
                    : 'Introducir modelo manualmente',
              ),
            ),
          if (manualModel && service != AiService.chatgpt)
            TextField(
              key: const Key('ai-model-manual'),
              controller: model,
              enabled: !busy,
              onChanged: (value) {
                updateModelProtocol(value);
                setState(() {});
              },
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(
                labelText: 'Identificador del modelo',
              ),
            ),
          if (service == AiService.opencodeGo) ...[
            const SizedBox(height: 12),
            const Text(
              'Go está orientado a agentes de programación. Esta conexión se identifica como TrackIA; comprueba con tu proveedor si admite este uso. No se cambia automáticamente a Zen ni a otro servicio.',
            ),
          ],
          if (service != AiService.chatgpt)
            ExpansionTile(
              title: const Text('Configuración de la API'),
              children: [
                if (service != AiService.custom)
                  TextField(
                    key: const Key('ai-base-url'),
                    controller: base,
                    enabled: !busy,
                    onChanged: (_) => setState(invalidateCatalog),
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(
                      labelText: 'URL base HTTPS',
                    ),
                  ),
                const SizedBox(height: 12),
                DropdownButtonFormField<AiProtocol>(
                  key: ValueKey('protocol-$protocol'),
                  initialValue: protocol,
                  decoration: const InputDecoration(
                    labelText: 'Formato compatible con el modelo',
                  ),
                  items: [
                    for (final p in AiProtocol.values)
                      DropdownMenuItem(
                        value: p,
                        child: Text(switch (p) {
                          AiProtocol.chatCompletions => 'Chat Completions',
                          AiProtocol.responses => 'Responses',
                          AiProtocol.anthropic => 'Anthropic Messages',
                          AiProtocol.gemini => 'Gemini',
                        }),
                      ),
                  ],
                  onChanged: busy
                      ? null
                      : (p) {
                          if (p != null) {
                            setState(() {
                              invalidateCatalog();
                              protocol = p;
                            });
                          }
                        },
                ),
              ],
            ),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: busy
              ? null
              : () => run(() async {
                  await store.save(config());
                  if (mounted) {
                    setState(() => status = 'Configuración guardada.');
                  }
                }),
          child: Text(
            service == AiService.local
                ? 'Guardar modelo local'
                : 'Guardar proveedor',
          ),
        ),
        OutlinedButton(
          onPressed: busy
              ? null
              : () => run(() async {
                  final tested = config();
                  final answer = await (widget.client ?? AiClient()).reply(
                    tested,
                    const [
                      AiMessage(
                        'user',
                        'Responde brevemente en español para confirmar que funciona el chat de TrackIA.',
                      ),
                    ],
                    system:
                        'Eres el asistente de TrackIA para actividades, enfoque y bienestar. Esta solicitud prueba una conexión real de conversación, no una tarea de programación.',
                    sessionId: const Uuid().v4(),
                  );
                  await store.save(tested);
                  await store.markVerified(tested);
                  if (mounted) {
                    setState(() => status = 'El proveedor respondió:\n$answer');
                  }
                }),
          child: Text(
            service == AiService.local
                ? 'Probar modelo en este móvil'
                : service == AiService.chatgpt
                ? 'Probar conexión · usa mi plan ChatGPT'
                : 'Probar conexión · usa tu API',
          ),
        ),
        if (service != AiService.chatgpt)
          TextButton(
            onPressed: busy
                ? null
                : () => run(() async {
                    await store.delete();
                    setState(invalidateCatalog);
                    key.clear();
                    if (mounted) {
                      setState(
                        () => status = 'Configuración y clave eliminadas.',
                      );
                    }
                  }),
            child: const Text('Eliminar configuración y clave'),
          ),
        if (busy) const LinearProgressIndicator(),
        if (status != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(status!),
          ),
        if (widget.progress != null)
          AiPerCompanionSection(
            profileId: widget.profileId,
            progress: widget.progress!,
          ),
      ],
    ),
  );
}
