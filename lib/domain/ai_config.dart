import 'workout.dart';

enum AiProtocol { chatCompletions, responses, anthropic, gemini }

enum AiService {
  opencodeGo,
  opencodeZen,
  openai,
  chatgpt,
  anthropic,
  gemini,
  openrouter,
  deepseek,
  minimax,
  kimi,
  custom,
  local,
}

extension AiServiceInfo on AiService {
  String get label => switch (this) {
    AiService.opencodeGo => 'OpenCode Go',
    AiService.opencodeZen => 'OpenCode Zen',
    AiService.openai => 'OpenAI',
    AiService.chatgpt => 'ChatGPT · usar mi plan',
    AiService.anthropic => 'Claude / Anthropic',
    AiService.gemini => 'Google Gemini',
    AiService.openrouter => 'OpenRouter',
    AiService.deepseek => 'DeepSeek',
    AiService.minimax => 'MiniMax',
    AiService.kimi => 'Kimi / Moonshot',
    AiService.custom => 'API personalizada',
    AiService.local => 'Modelo local · en este móvil',
  };
  String get baseUrl => switch (this) {
    AiService.opencodeGo => 'https://opencode.ai/zen/go/v1',
    AiService.opencodeZen => 'https://opencode.ai/zen/v1',
    AiService.openai || AiService.chatgpt => 'https://api.openai.com/v1',
    AiService.anthropic => 'https://api.anthropic.com/v1',
    AiService.gemini => 'https://generativelanguage.googleapis.com/v1beta',
    AiService.openrouter => 'https://openrouter.ai/api/v1',
    AiService.deepseek => 'https://api.deepseek.com/v1',
    AiService.minimax => 'https://api.minimax.io/v1',
    AiService.kimi => 'https://api.moonshot.ai/v1',
    AiService.custom => '',
    AiService.local => '',
  };
  AiProtocol get defaultProtocol => switch (this) {
    AiService.openai || AiService.chatgpt => AiProtocol.responses,
    AiService.anthropic => AiProtocol.anthropic,
    AiService.gemini => AiProtocol.gemini,
    _ => AiProtocol.chatCompletions,
  };

  AiProtocol protocolForModel(String value) {
    if (this != AiService.opencodeGo && this != AiService.opencodeZen) {
      return defaultProtocol;
    }
    final name = value.toLowerCase().trim().replaceFirst(
      RegExp(r'^opencode(?:-go)?/'),
      '',
    );
    if (name.startsWith('gemini-')) return AiProtocol.gemini;
    if (name.startsWith('claude-') ||
        name.startsWith('minimax-') ||
        (name.startsWith('qwen') &&
            !(this == AiService.opencodeZen && name == 'qwen3.8-max'))) {
      return AiProtocol.anthropic;
    }
    if (name.startsWith('gpt-') ||
        name.startsWith('grok-') ||
        name.startsWith('muse-')) {
      return AiProtocol.responses;
    }
    return AiProtocol.chatCompletions;
  }
}

class AiConfig {
  const AiConfig({
    required this.service,
    required this.baseUrl,
    required this.model,
    required this.protocol,
    required this.apiKey,
    this.chatGptClientId,
    this.profileId = 'local',
    this.localModelPath,
    this.localProjectorPath,
    this.localContextLength = 8192,
  });
  final AiService service;
  final String baseUrl, model, apiKey;
  final AiProtocol protocol;
  final String? chatGptClientId;
  final String? localModelPath, localProjectorPath;
  final int localContextLength;
  final String profileId;
  bool get usesChatGpt => service == AiService.chatgpt;
  bool get usesLocalModel => service == AiService.local;

  String get modelId => switch (service) {
    AiService.opencodeGo => model.replaceFirst(RegExp(r'^opencode-go/'), ''),
    AiService.opencodeZen => model.replaceFirst(RegExp(r'^opencode/'), ''),
    _ => model,
  };

  // GLM-5.3 and GLM-5.3-Flash are distinct models. Z.ai documents
  // only the latter as native multimodal. Unknown models are not blocked.
  String? get imageInputWarning =>
      modelId.toLowerCase().split('/').last == 'glm-5.3'
      ? 'GLM-5.3 admite solo texto. Para imágenes prueba glm-5.3-flash con Chat Completions, o configura otro modelo con visión. Tu mensaje y adjunto se conservan.'
      : null;

  void validate({bool requireModel = true}) {
    if (usesLocalModel) {
      if (localModelPath == null || localModelPath!.isEmpty) {
        throw const ValidationException('Selecciona un modelo GGUF local.');
      }
      if (requireModel && model.trim().isEmpty) {
        throw const ValidationException(
          'Selecciona el archivo del modelo local.',
        );
      }
      if (localContextLength < 1024 || localContextLength > 32768) {
        throw const ValidationException(
          'El contexto local debe estar entre 1024 y 32768 tokens.',
        );
      }
      return;
    }
    if (usesChatGpt &&
        (baseUrl != AiService.chatgpt.baseUrl ||
            protocol != AiProtocol.responses ||
            chatGptClientId == null ||
            chatGptClientId!.isEmpty ||
            apiKey.isNotEmpty)) {
      throw const ValidationException(
        'Conecta tu cuenta de ChatGPT desde ajustes de IA.',
      );
    }
    final uri = Uri.tryParse(baseUrl);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw const ValidationException(
        'Introduce la URL base HTTPS de la API, sin claves ni parámetros.',
      );
    }
    if (requireModel &&
        (modelId.trim().isEmpty ||
            model.length > 200 ||
            model.contains(RegExp(r'\s')))) {
      throw const ValidationException(
        'Introduce el identificador exacto del modelo.',
      );
    }
    if (!usesChatGpt &&
        (apiKey.trim().isEmpty || apiKey.contains(RegExp(r'[\r\n]')))) {
      throw const ValidationException('Introduce tu clave API del proveedor.');
    }
  }

  Map<String, dynamic> toJson() => {
    'service': service.name,
    'baseUrl': baseUrl,
    'model': model,
    'protocol': protocol.name,
    'apiKey': apiKey,
    if (usesChatGpt) 'chatGptClientId': chatGptClientId,
    if (usesChatGpt) 'profileId': profileId,
    if (localModelPath != null) 'localModelPath': localModelPath,
    if (localProjectorPath != null) 'localProjectorPath': localProjectorPath,
    if (usesLocalModel) 'localContextLength': localContextLength,
  };
  factory AiConfig.fromJson(Map<String, dynamic> value) => AiConfig(
    service: AiService.values.byName(value['service'] as String),
    baseUrl: value['baseUrl'] as String,
    model: value['model'] as String,
    protocol: AiProtocol.values.byName(value['protocol'] as String),
    apiKey: value['apiKey'] as String,
    chatGptClientId: value['chatGptClientId'] as String?,
    profileId: value['profileId'] as String? ?? 'local',
    localModelPath: value['localModelPath'] as String?,
    localProjectorPath: value['localProjectorPath'] as String?,
    localContextLength: value['localContextLength'] as int? ?? 2048,
  );
}

/// A companion's exception to the profile's AI setup: only which model of the
/// same provider to use. Credentials never live here; they belong to the profile.
class AiOverride {
  AiOverride({required this.service, required String model})
    : model = model.trim() {
    if (this.model.isEmpty ||
        this.model.length > 200 ||
        this.model.contains(RegExp(r'\s'))) {
      throw const ValidationException(
        'Introduce el identificador exacto del modelo.',
      );
    }
  }

  final AiService service;
  final String model;

  Map<String, dynamic> toJson() => {'provider': service.name, 'modelId': model};

  /// Strict: any other key (an API key, for instance) rejects the whole value.
  factory AiOverride.fromJson(Map<String, dynamic> value) {
    if (value.keys.toSet().difference({'provider', 'modelId'}).isNotEmpty ||
        value['provider'] is! String ||
        value['modelId'] is! String) {
      throw const FormatException('Excepción de IA no válida.');
    }
    return AiOverride(
      service: AiService.values.byName(value['provider'] as String),
      model: value['modelId'] as String,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AiOverride && other.service == service && other.model == model;

  @override
  int get hashCode => Object.hash(service, model);
}

extension AiConfigOverride on AiConfig {
  /// The profile's setup with the companion's model. An exception for another
  /// provider is ignored: this profile holds no credentials for it.
  AiConfig withOverride(AiOverride? exception) {
    if (exception == null || exception.service != service) return this;
    return AiConfig(
      service: service,
      baseUrl: baseUrl,
      model: exception.model,
      protocol: service.protocolForModel(exception.model),
      apiKey: apiKey,
      chatGptClientId: chatGptClientId,
      profileId: profileId,
      localModelPath: localModelPath,
      localProjectorPath: localProjectorPath,
      localContextLength: localContextLength,
    );
  }
}
