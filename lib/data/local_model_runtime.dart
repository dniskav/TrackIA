import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:llama_cpp_dart/llama_cpp_dart.dart';

/// One model at a time, retained between chat turns to avoid reloading >1 GB
/// weights for every user message.
class LocalModelRuntime {
  static final LocalModelRuntime instance = LocalModelRuntime._();
  LocalModelRuntime._();

  LlamaEngine? _engine;
  String? _loadedModel, _loadedProjector;
  Future<void> _queue = Future<void>.value();

  Future<String> reply({
    required String modelPath,
    required int contextLength,
    String? projectorPath,
    required List<({String role, String text, Uint8List? image})> messages,
    required String system,
    void Function(String)? onText,
  }) async {
    final completer = Completer<String>();
    final previous = _queue;
    final next = Completer<void>();
    _queue = next.future;
    await previous;
    try {
      completer.complete(
        await _reply(
          modelPath: modelPath,
          contextLength: contextLength,
          projectorPath: projectorPath,
          messages: messages,
          system: system,
          onText: onText,
        ),
      );
    } catch (error, stack) {
      completer.completeError(error, stack);
    } finally {
      next.complete();
    }
    return completer.future;
  }

  Future<String> _reply({
    required String modelPath,
    required int contextLength,
    String? projectorPath,
    required List<({String role, String text, Uint8List? image})> messages,
    required String system,
    void Function(String)? onText,
  }) async {
    final model = File(modelPath);
    if (!await model.exists() || await model.length() == 0) {
      throw StateError('No encuentro el archivo GGUF seleccionado.');
    }
    if (projectorPath != null && !await File(projectorPath).exists()) {
      throw StateError('No encuentro el proyector visual seleccionado.');
    }
    if (_engine == null ||
        _loadedModel != '$modelPath|$contextLength' ||
        _loadedProjector != projectorPath) {
      await _engine?.dispose();
      _engine = null;
      _loadedModel = null;
      _loadedProjector = null;
      _engine = await LlamaEngine.spawn(
        modelParams: ModelParams(path: modelPath, gpuLayers: 0),
        contextParams: ContextParams.mobile(nCtx: contextLength),
        multimodalParams: projectorPath == null
            ? null
            : MultimodalParams(mmprojPath: projectorPath, useGpu: false),
      );
      _loadedModel = '$modelPath|$contextLength';
      _loadedProjector = projectorPath;
    }
    final chat = await _engine!.createChat();
    chat.addSystem(system);
    for (final message in messages) {
      switch (message.role) {
        case 'assistant':
          chat.addAssistant(message.text);
          break;
        case 'user':
          final image = message.image;
          chat.addUser(
            message.text,
            media: image == null ? const [] : [LlamaMedia.imageBytes(image)],
          );
          break;
        default:
          continue;
      }
    }
    final answer = StringBuffer();
    try {
      await for (final event in chat.generate(maxTokens: 384)) {
        if (event case TokenEvent(:final text) when text.isNotEmpty) {
          answer.write(text);
          onText?.call(LocalModelOutput.visible(answer.toString()));
        }
      }
    } finally {
      await chat.dispose();
    }
    final result = LocalModelOutput.visible(answer.toString()).trim();
    if (result.isEmpty) {
      throw StateError('El modelo local no generó una respuesta.');
    }
    return result;
  }

  Future<void> dispose() async {
    await _engine?.dispose();
    _engine = null;
    _loadedModel = null;
    _loadedProjector = null;
  }
}

/// Hides model-internal reasoning blocks while keeping useful answer text.
class LocalModelOutput {
  static final _completeThinkBlock = RegExp(
    r'<think>[\s\S]*?</think>',
    caseSensitive: false,
  );
  static final _thinkStart = RegExp(r'<think>', caseSensitive: false);
  static final _thinkEnd = RegExp(r'</think>', caseSensitive: false);

  static String visible(String text) {
    var output = text.replaceAll(_completeThinkBlock, '');
    final unfinished = _thinkStart.firstMatch(output);
    if (unfinished != null) output = output.substring(0, unfinished.start);
    return output.replaceAll(_thinkEnd, '');
  }
}
