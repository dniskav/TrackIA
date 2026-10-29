import 'package:flutter/services.dart';

class LocalModelMemory {
  /// TrackIA's working prompt contains companion instructions, recent chat,
  /// activity records and (when connected) sheet context. This is an app
  /// requirement, not an estimate of a particular GGUF's capability.
  static const trackiaRecommendedContextLength = 8192;
  static const contextChoices = <int>[1024, 2048, 4096, 8192, 16384, 32768];
  static const _minimumContextBytesPerToken = 16 * 1024;
  static const _maximumContextBytesPerToken = 128 * 1024;

  const LocalModelMemory({
    required this.availableBytes,
    required this.totalBytes,
    required this.thresholdBytes,
    required this.lowMemory,
  });

  final int availableBytes, totalBytes, thresholdBytes;
  final bool lowMemory;
  static const _channel = MethodChannel('com.trackia/local-model');

  static Future<LocalModelMemory?> read() async {
    try {
      final values = await _channel.invokeMapMethod<String, Object?>('memory');
      if (values == null) return null;
      return LocalModelMemory(
        availableBytes: (values['availableBytes'] as num).toInt(),
        totalBytes: (values['totalBytes'] as num).toInt(),
        thresholdBytes: (values['thresholdBytes'] as num).toInt(),
        lowMemory: values['lowMemory'] as bool? ?? false,
      );
    } on MissingPluginException {
      return null;
    }
  }

  int estimateModelLoadBytes({
    required int modelBytes,
    required int projectorBytes,
  }) => ((modelBytes + projectorBytes) * 1.15 + 250 * 1024 * 1024).round();

  ({int minimum, int maximum}) estimateContextBytes(int contextLength) => (
    minimum: contextLength * _minimumContextBytesPerToken,
    maximum: contextLength * _maximumContextBytesPerToken,
  );

  int estimateLoadBytes({
    required int modelBytes,
    required int projectorBytes,
    required int contextLength,
  }) =>
      estimateModelLoadBytes(
        modelBytes: modelBytes,
        projectorBytes: projectorBytes,
      ) +
      estimateContextBytes(contextLength).maximum;

  int projectedAvailableAfterModelBytes({
    required int modelBytes,
    required int projectorBytes,
  }) =>
      (availableBytes -
              estimateModelLoadBytes(
                modelBytes: modelBytes,
                projectorBytes: projectorBytes,
              ))
          .clamp(0, totalBytes)
          .toInt();

  int projectedAvailableBytes({
    required int modelBytes,
    required int projectorBytes,
    required int contextLength,
  }) =>
      (availableBytes -
              estimateLoadBytes(
                modelBytes: modelBytes,
                projectorBytes: projectorBytes,
                contextLength: contextLength,
              ))
          .clamp(0, totalBytes)
          .toInt();

  int estimatedShortfallBytes({
    required int modelBytes,
    required int projectorBytes,
    required int contextLength,
  }) =>
      (estimateLoadBytes(
                modelBytes: modelBytes,
                projectorBytes: projectorBytes,
                contextLength: contextLength,
              ) -
              availableBytes)
          .clamp(0, totalBytes)
          .toInt();

  String assess({
    required int modelBytes,
    required int projectorBytes,
    required int contextLength,
  }) {
    const mb = 1024 * 1024;
    // Conservative rough estimate: mapped weights plus context/vision buffers.
    final estimate = estimateLoadBytes(
      modelBytes: modelBytes,
      projectorBytes: projectorBytes,
      contextLength: contextLength,
    );
    final available = availableBytes;
    if (lowMemory || available <= thresholdBytes) {
      return 'Android indica que queda poca memoria. Cierra otras apps antes de cargar el modelo.';
    }
    if (estimate > available) {
      return 'Memoria ajustada: modelo y contexto podrían cerrar o ralentizar el móvil. Estimación ${(estimate / mb).round()} MB; disponibles ${(available / mb).round()} MB. Puedes continuar si quieres probarlo.';
    }
    return 'Memoria estimada suficiente: ${(available / mb).round()} MB disponibles.';
  }
}
