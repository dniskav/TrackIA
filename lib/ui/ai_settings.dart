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
        setState(() => status = appText(context).aiConfigReadError);
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
    final strings = appText(context);
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
        throw StateError(strings.aiSetAndroidFileAccess);
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
        setState(() => status = appText(context).aiModelImportError('$error'));
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
        bar(appText(context).aiMemoryAvailableNow, memory.availableBytes),
        bar(appText(context).aiMemoryAfterModel, afterModel),
        bar(appText(context).aiMemoryAfterContext, projected),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            appText(context).aiMemoryContextEstimate(_contextLabel(localContextLength), format(contextRange.minimum), format(contextRange.maximum)),
          ),
        ),
        if (shortfall > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              appText(context).aiMemoryShortfall(format(shortfall)),
            ),
          ),
        Padding(padding: const EdgeInsets.only(top: 8), child: Text(appText(context).aiMemoryEstimateHelp)),
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
            ? appText(context).aiConnectedChooseModel
            : appText(context).aiIdentityConnected;
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
          ? appText(context).aiChatGptDisconnected
          : appText(context).aiChatGptRemoteRevocationUnconfirmed;
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
        final details = service == AiService.local
            ? appText(context).aiOperationDetails('$error')
            : '';
        setState(() => status = appText(context).aiOperationError(details));
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
            ? appText(context).aiSetModelsCountChatGpt(result.length)
            : appText(context).aiSetCatalogCountApi(result.length);
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
              ? appText(context).aiSetCatalogErrorChatGpt
              : appText(context).aiSetCatalogErrorApi;
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
        Text(appText(context).aiProviderDescription),
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
                  Text(appText(context).aiSetGgufTitle, style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    localModelPath?.split(Platform.pathSeparator).last ??
                        appText(context).aiNoModelImported,
                  ),
                  OutlinedButton.icon(
                    onPressed: busy
                        ? null
                        : () => pickLocalFile(projector: false),
                    icon: const Icon(Icons.download),
                    label: Text(appText(context).aiSelectImportGguf),
                  ),
                  const SizedBox(height: 12),
                  Text(appText(context).aiLocalContextTitle, style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    appText(context).aiSetLocalContextHelp(_contextLabel(LocalModelMemory.trackiaRecommendedContextLength)),
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
                        appText(context).aiContextSelected(_contextLabel(localContextLength)),
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
                          child: Text(appText(context).aiUseRecommendation),
                        ),
                    ],
                  ),
                  const Divider(),
                  Text(appText(context).aiVisualProjector, style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(appText(context).aiProjectorHelp),
                  Text(
                    localProjectorPath?.split(Platform.pathSeparator).last ??
                        appText(context).aiNoProjector,
                  ),
                  OutlinedButton.icon(
                    onPressed: busy
                        ? null
                        : () => pickLocalFile(projector: true),
                    icon: const Icon(Icons.image_search),
                    label: Text(appText(context).aiSelectProjector),
                  ),
                  if (localMemoryStatus != null && localMemory == null) ...[
                    const SizedBox(height: 8),
                    Text(localMemoryStatus!),
                  ],
                  if (localMemory != null &&
                      localModelBytes != null &&
                      localProjectorBytes != null)
                    localMemoryComparison(),
                  Text(appText(context).aiMemoryHelp),
                  TextButton.icon(
                    onPressed: busy ? null : refreshLocalMemory,
                    icon: const Icon(Icons.memory),
                    label: Text(appText(context).aiRecalculateMemory),
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
              decoration: InputDecoration(labelText: appText(context).aiApiBase, helperText: appText(context).aiHttpsExample),
            ),
            const SizedBox(height: 16),
          ],
          if (service == AiService.chatgpt) ...[
            Text(appText(context).aiChatGptPlanHelp),
            if (chatGptAccounts.isNotEmpty)
              DropdownButtonFormField<String>(
                key: ValueKey('chatgpt-account-$chatGptClientId'),
                initialValue: chatGptClientId,
                isExpanded: true,
                decoration: InputDecoration(labelText: appText(context).aiChatGptAccount),
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
                        ? appText(context).aiChatGptConnectedPlan
                        : appText(context).aiChatGptConnectedIdentity
                  : appText(context).aiChatGptNotConnected,
            ),
            OutlinedButton(
              key: const Key('chatgpt-connect'),
              onPressed: busy ? null : () => connectChatGpt(),
              child: Text(appText(context).aiContinueChatGpt),
            ),
            if (selectedChatGpt?.connected == true)
              FilledButton(
                key: const Key('chatgpt-enable-plan'),
                onPressed: busy ? null : () => connectChatGpt(usePlan: true),
                child: Text(
                  selectedChatGpt!.canUsePlan
                      ? appText(context).aiReviewPlanPermission
                      : appText(context).aiAuthorizePlan,
                ),
              ),
            if (chatGptAccounts.isNotEmpty)
              TextButton(
                onPressed: busy ? null : () => connectChatGpt(newAccount: true),
                child: Text(appText(context).aiAddAccount),
              ),
            TextButton(
              onPressed: busy ? null : () => run(chatGpt.showUsage),
              child: Text(appText(context).aiViewUsagePermissions),
            ),
            if (selectedChatGpt?.connected == true)
              TextButton(
                key: const Key('chatgpt-disconnect'),
                onPressed: busy ? null : disconnectChatGpt,
                child: Text(appText(context).aiDisconnectChatGpt),
              ),
            if (busy)
              TextButton(
                key: const Key('chatgpt-cancel'),
                onPressed: chatGpt.cancel,
                child: Text(appText(context).aiCancelConnection),
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
                labelText: appText(context).aiApiKey,
                suffixIcon: IconButton(
                  tooltip: reveal ? appText(context).aiHideKey : appText(context).aiShowKey,
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
                  ? appText(context).aiLoadingModels
                  : appText(context).aiFetchModels,
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
              decoration: InputDecoration(labelText: appText(context).aiModelLabel),
              hint: Text(appText(context).aiChooseCatalogModel),
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
                appText(context).aiCurrentModelPreserved(model.text),
              ),
            ),
          if (service != AiService.chatgpt)
            TextButton(
              onPressed: busy
                  ? null
                  : () => setState(() => manualModel = !manualModel),
              child: Text(
                manualModel
                    ? appText(context).aiHideManualId
                    : appText(context).aiEnterManualModel,
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
              decoration: InputDecoration(labelText: appText(context).aiModelIdentifier),
            ),
          if (service == AiService.opencodeGo) ...[
            const SizedBox(height: 12),
            Text(appText(context).aiOpenCodeNotice),
          ],
          if (service != AiService.chatgpt)
            ExpansionTile(
              title: Text(appText(context).aiApiSettings),
              children: [
                if (service != AiService.custom)
                  TextField(
                    key: const Key('ai-base-url'),
                    controller: base,
                    enabled: !busy,
                    onChanged: (_) => setState(invalidateCatalog),
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(labelText: appText(context).aiHttpsBase),
                  ),
                const SizedBox(height: 12),
                DropdownButtonFormField<AiProtocol>(
                  key: ValueKey('protocol-$protocol'),
                  initialValue: protocol,
                  decoration: InputDecoration(labelText: appText(context).aiProtocol),
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
                    setState(() => status = appText(context).aiConfigSaved);
                  }
                }),
          child: Text(
            service == AiService.local
                ? appText(context).aiSaveLocalModel
                : appText(context).aiSaveProvider,
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
                    setState(() => status = appText(context).aiProviderResponded(answer));
                  }
                }),
          child: Text(
            service == AiService.local
                ? appText(context).aiTestLocalModel
                : service == AiService.chatgpt
                ? appText(context).aiTestChatGpt
                : appText(context).aiTestApi,
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
                        () => status = appText(context).aiConfigDeleted,
                      );
                    }
                  }),
            child: Text(appText(context).aiDeleteConfig),
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
