import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gymia/data/ai_client.dart';
import 'package:gymia/data/local_model_preflight.dart';
import 'package:gymia/data/local_model_runtime.dart';
import 'package:gymia/domain/ai_config.dart';
import 'package:gymia/domain/workout.dart';

void main() {
  test('local model hides completed and partial think blocks', () {
    expect(
      LocalModelOutput.visible('<think>private</think>Visible answer'),
      'Visible answer',
    );
    expect(LocalModelOutput.visible('Visible<think>private'), 'Visible');
    expect(
      LocalModelOutput.visible('A<think>one</think>B<think>two</think>C'),
      'ABC',
    );
  });

  test('local chat system budget follows the selected context', () {
    final system = '${'A' * 5000}important workout history';
    final compact = AiClient.compactLocalSystem(system, 1024);
    final larger = AiClient.compactLocalSystem(system, 4096);
    expect(compact.length, lessThanOrEqualTo(1024));
    expect(compact, startsWith('A'));
    expect(compact, contains('important workout history'));
    expect(larger.length, greaterThan(compact.length));
    expect(AiClient.compactLocalSystem('TrackIA', 8192), 'TrackIA');
  });

  AiConfig config({
    String? modelPath,
    String? projectorPath,
    int contextLength = 8192,
  }) => AiConfig(
    service: AiService.local,
    baseUrl: '',
    model: modelPath == null ? '' : 'MiniCPM.gguf',
    protocol: AiProtocol.chatCompletions,
    apiKey: '',
    localModelPath: modelPath,
    localProjectorPath: projectorPath,
    localContextLength: contextLength,
  );

  test('local provider round-trips model and vision projector paths', () {
    final original = config(
      modelPath: '/models/model.gguf',
      projectorPath: '/models/mmproj.gguf',
      contextLength: 16384,
    );
    final restored = AiConfig.fromJson(original.toJson());
    expect(restored.service, AiService.local);
    expect(restored.localModelPath, '/models/model.gguf');
    expect(restored.localProjectorPath, '/models/mmproj.gguf');
    expect(restored.localContextLength, 16384);
    expect(restored.apiKey, isEmpty);
    expect(() => restored.validate(), returnsNormally);
  });

  test(
    'local provider rejects missing model without requiring cloud credentials',
    () {
      expect(() => config().validate(), throwsA(isA<ValidationException>()));
    },
  );

  test('memory assessment warns when estimated use exceeds available RAM', () {
    const memory = LocalModelMemory(
      availableBytes: 800 * 1024 * 1024,
      totalBytes: 8 * 1024 * 1024 * 1024,
      thresholdBytes: 300 * 1024 * 1024,
      lowMemory: false,
    );
    expect(
      memory.assess(
        modelBytes: 650 * 1024 * 1024,
        projectorBytes: 900 * 1024 * 1024,
        contextLength: 8192,
      ),
      contains('Memoria ajustada'),
    );
  });

  test('TrackIA recommends context for its own working prompt', () {
    expect(LocalModelMemory.trackiaRecommendedContextLength, 8192);
  });

  test(
    'memory comparison shows current and estimated post-load availability',
    () {
      const memory = LocalModelMemory(
        availableBytes: 2 * 1024 * 1024 * 1024,
        totalBytes: 8 * 1024 * 1024 * 1024,
        thresholdBytes: 300 * 1024 * 1024,
        lowMemory: false,
      );
      final after = memory.projectedAvailableBytes(
        modelBytes: 100 * 1024 * 1024,
        projectorBytes: 0,
        contextLength: 2048,
      );
      expect(after, lessThan(memory.availableBytes));
      expect(after, greaterThan(0));
      expect(
        memory.estimatedShortfallBytes(
          modelBytes: 100 * 1024 * 1024,
          projectorBytes: 0,
          contextLength: 2048,
        ),
        0,
      );
      final moreContext = memory.projectedAvailableBytes(
        modelBytes: 100 * 1024 * 1024,
        projectorBytes: 0,
        contextLength: 8192,
      );
      expect(moreContext, lessThan(after));
    },
  );

  test(
    'reply routes local models directly to file validation, not HTTP',
    () async {
      final client = AiClient(
        transport: (_, _, _) async =>
            throw StateError('HTTP should not be called'),
      );
      await expectLater(
        client.reply(
          config(modelPath: '${Directory.systemTemp.path}/missing-model.gguf'),
          const [AiMessage('user', 'Hola')],
          system: 'TrackIA',
          sessionId: 'test',
        ),
        throwsA(isA<ValidationException>()),
      );
    },
  );
}
