import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'ai_stream_response.dart';
import 'chatgpt_auth.dart';
import 'dart:typed_data';
import '../domain/ai_config.dart';
import '../domain/workout.dart';
import 'local_model_runtime.dart';

class AiAttachment {
  const AiAttachment({
    required this.name,
    required this.mime,
    required this.bytes,
  });
  final String name, mime;
  final Uint8List bytes;
  bool get isImage => mime.startsWith('image/');
  bool get isPdf => mime == 'application/pdf';
  String get encoded => base64Encode(bytes);
}

class AiMessage {
  const AiMessage(this.role, this.text, {this.attachment, this.recordedAt});
  final String role, text;
  final AiAttachment? attachment;
  final DateTime? recordedAt;
  Map<String, String> toJson() => {'role': role, 'content': text};
  Map<String, dynamic> forStorage() => {
    ...toJson(),
    if (recordedAt != null) 'recordedAt': recordedAt!.toIso8601String(),
    if (attachment != null)
      'attachment': {
        'name': attachment!.name,
        'mime': attachment!.mime,
        'bytes': attachment!.encoded,
      },
  };

  factory AiMessage.fromStorage(Map<String, dynamic> value) {
    final media = value['attachment'];
    AiAttachment? attachment;
    if (media is Map) {
      final encoded = media['bytes'] as String;
      if (encoded.length > 6 * 1024 * 1024) throw const FormatException();
      final bytes = base64Decode(encoded);
      if (bytes.isEmpty || bytes.length > 4 * 1024 * 1024) {
        throw const FormatException();
      }
      attachment = AiAttachment(
        name: media['name'] as String,
        mime: media['mime'] as String,
        bytes: bytes,
      );
    }
    return AiMessage(
      value['role'] as String,
      value['content'] as String,
      attachment: attachment,
      recordedAt: DateTime.tryParse(value['recordedAt'] as String? ?? ''),
    );
  }

  Map<String, dynamic> forApi(AiProtocol protocol) {
    final media = attachment;
    if (media == null) return toJson();
    final parts = <Map<String, dynamic>>[];
    switch (protocol) {
      case AiProtocol.chatCompletions:
        parts.add({'type': 'text', 'text': text});
        parts.add(
          media.isPdf
              ? {
                  'type': 'file',
                  'file': {
                    'filename': media.name,
                    'file_data': 'data:application/pdf;base64,${media.encoded}',
                  },
                }
              : {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:${media.mime};base64,${media.encoded}',
                  },
                },
        );
      case AiProtocol.responses:
        parts.add({'type': 'input_text', 'text': text});
        parts.add(
          media.isPdf
              ? {
                  'type': 'input_file',
                  'filename': media.name,
                  'file_data': 'data:application/pdf;base64,${media.encoded}',
                }
              : {
                  'type': 'input_image',
                  'image_url': 'data:${media.mime};base64,${media.encoded}',
                },
        );
      case AiProtocol.anthropic:
        parts.add({'type': 'text', 'text': text});
        parts.add({
          'type': media.isPdf ? 'document' : 'image',
          'source': {
            'type': 'base64',
            'media_type': media.mime,
            'data': media.encoded,
          },
        });
      case AiProtocol.gemini:
        parts.add({'text': text});
        parts.add({
          'inlineData': {'mimeType': media.mime, 'data': media.encoded},
        });
    }
    return {'role': role, 'content': parts};
  }
}

typedef AiTransport =
    Future<Map<String, dynamic>> Function(
      Uri uri,
      Map<String, String> headers,
      Map<String, dynamic> body,
    );

class AiClient {
  AiClient({AiTransport? transport, this.chatGptAuth}) : _transport = transport;
  final ChatGptAuth? chatGptAuth;
  final AiTransport? _transport;

  Future<String> reply(
    AiConfig config,
    List<AiMessage> messages, {
    required String system,
    required String sessionId,
    void Function(String text)? onText,
  }) async {
    config.validate();
    messages = messages.where((m) => m.role != 'event').toList();
    if (messages.isEmpty || messages.last.role != 'user') {
      throw const ValidationException('Escribe un mensaje para el asistente.');
    }
    if (config.usesLocalModel) {
      final maxLocalHistoryCharacters = config.localContextLength ~/ 2;
      final maxLocalMessageCharacters = config.localContextLength ~/ 2;
      for (final message in messages) {
        final attachment = message.attachment;
        if (attachment != null && !attachment.isImage) {
          throw const ValidationException(
            'Este modelo local admite texto e imágenes; los PDF y audios requieren un modelo compatible.',
          );
        }
        if (attachment?.isImage == true && config.localProjectorPath == null) {
          throw const ValidationException(
            'Para enviar imágenes con el modelo local, selecciona también el proyector visual mmproj.',
          );
        }
      }
      if (messages.last.text.length > maxLocalMessageCharacters) {
        throw ValidationException(
          'El mensaje supera el presupuesto de contexto local seleccionado (${config.localContextLength} tokens). Aumenta el contexto o divide el texto.',
        );
      }
      final localHistory = <({String role, String text, Uint8List? image})>[];
      var historyCharacters = 0;
      for (var i = messages.length - 1; i >= 0; i--) {
        final message = messages[i];
        if (historyCharacters + message.text.length >
            maxLocalHistoryCharacters) {
          break;
        }
        localHistory.add((
          role: message.role,
          text: message.text,
          // Re-encoding old images on every turn wastes memory; the current
          // request's image is enough because earlier answers remain as text.
          image: i == messages.length - 1 ? message.attachment?.bytes : null,
        ));
        historyCharacters += message.text.length;
      }
      try {
        return await LocalModelRuntime.instance.reply(
          modelPath: config.localModelPath!,
          projectorPath: config.localProjectorPath,
          contextLength: config.localContextLength,
          system: compactLocalSystem(system, config.localContextLength),
          onText: onText,
          messages: localHistory.reversed.toList(),
        );
      } on ValidationException {
        rethrow;
      } catch (error) {
        final detail = error
            .toString()
            .replaceFirst('Bad state: ', '')
            .replaceAll(RegExp(r'\s+'), ' ');
        final shortDetail = detail.length > 160
            ? '${detail.substring(0, 160)}…'
            : detail;
        throw ValidationException(
          'El modelo local no pudo procesar el chat. Se redujo el contexto; detalle: $shortDetail',
        );
      }
    }
    final base = config.baseUrl.replaceFirst(RegExp(r'/+$'), '');
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
      'User-Agent': 'GymIA/0.3.14',
    };
    if (config.service == AiService.opencodeGo ||
        config.service == AiService.opencodeZen) {
      headers['x-opencode-session'] = sessionId;
    }
    late String path;
    late Map<String, dynamic> body;
    for (final message in messages) {
      final media = message.attachment;
      if (media == null) continue;
      if (media.isImage && config.imageInputWarning != null) {
        throw ValidationException(config.imageInputWarning!);
      }
      if (media.bytes.isEmpty || media.bytes.length > 4 * 1024 * 1024) {
        throw const ValidationException(
          'El adjunto debe tener contenido y no superar 4 MB.',
        );
      }
      if (media.isPdf && config.imageInputWarning != null) {
        throw const ValidationException(
          'El modelo elegido admite solo texto. Elige un modelo que pueda leer PDF. El documento se conserva.',
        );
      }
      if (!media.isImage &&
          !media.isPdf &&
          config.protocol != AiProtocol.gemini) {
        throw const ValidationException(
          'Los archivos de audio se admiten con Gemini. Con este proveedor puedes usar el micrófono del chat para enviar texto dictado.',
        );
      }
    }
    switch (config.protocol) {
      case AiProtocol.chatCompletions:
        path = '/chat/completions';
        headers['Authorization'] = 'Bearer ${config.apiKey}';
        body = {
          'model': config.modelId,
          'stream': onText != null,
          'messages': [
            {'role': 'system', 'content': system},
            ...messages.map((m) => m.forApi(config.protocol)),
          ],
        };
      case AiProtocol.responses:
        path = '/responses';
        headers['Authorization'] = 'Bearer ${config.apiKey}';
        body = {
          'model': config.modelId,
          'stream': config.usesChatGpt || onText != null,
          'store': false,
          'instructions': system,
          'input': messages.map((m) => m.forApi(config.protocol)).toList(),
        };
      case AiProtocol.anthropic:
        path = '/messages';
        headers['x-api-key'] = config.apiKey;
        headers['anthropic-version'] = '2023-06-01';
        body = {
          'model': config.modelId,
          'stream': onText != null,
          'max_tokens': 2048,
          'system': system,
          'messages': messages.map((m) => m.forApi(config.protocol)).toList(),
        };
      case AiProtocol.gemini:
        path =
            '/models/${Uri.encodeComponent(config.modelId.replaceFirst('models/', ''))}:${onText == null ? 'generateContent' : 'streamGenerateContent?alt=sse'}';
        headers['x-goog-api-key'] = config.apiKey;
        body = {
          'systemInstruction': {
            'parts': [
              {'text': system},
            ],
          },
          'contents': [
            for (final m in messages)
              {
                'role': m.role == 'assistant' ? 'model' : 'user',
                'parts': m.attachment != null
                    ? m.forApi(config.protocol)['content']
                    : [
                        {'text': m.text},
                      ],
              },
          ],
        };
    }
    final uri = Uri.parse('$base$path');
    Future<Map<String, dynamic>> send() => _transport != null
        ? _transport(uri, headers, body)
        : _http(
            uri,
            headers,
            body,
            protocol: config.protocol,
            onText: onText,
            chatGpt: config.usesChatGpt,
          );
    final response = config.usesChatGpt
        ? await (chatGptAuth ?? ChatGptAuth(profileId: config.profileId))
              .authorized(config.chatGptClientId!, (token) {
                headers['Authorization'] = 'Bearer $token';
                headers['Accept'] = 'text/event-stream';
                return send();
              })
        : await send();
    try {
      final String text;
      switch (config.protocol) {
        case AiProtocol.chatCompletions:
          final message = (response['choices'] as List).first['message'] as Map;
          final content = message['content'];
          text = content is String ? content : _parts(content as List);
        case AiProtocol.responses:
          if (response['status'] == 'failed' ||
              response['status'] == 'incomplete') {
            throw const ValidationException(
              'El proveedor no completó la respuesta. Prueba de nuevo o cambia de modelo.',
            );
          }
          text = [
            for (final item in response['output'] as List)
              if (item['type'] == 'message') _parts(item['content'] as List),
          ].join('\n');
        case AiProtocol.anthropic:
          text = _parts(response['content'] as List);
        case AiProtocol.gemini:
          final candidates = response['candidates'] as List;
          text = _parts(candidates.first['content']['parts'] as List);
      }
      if (text.trim().isEmpty) throw const FormatException();
      onText?.call(text.trim());
      return text.trim();
    } on ValidationException {
      rethrow;
    } catch (_) {
      throw const ValidationException(
        'El modelo no devolvió texto legible. Revisa el modelo y su formato de API.',
      );
    }
  }

  /// Mobile models have a small context window. Keep the companion identity,
  /// current state and the beginning of its instructions while dropping the
  /// cloud-only sheet protocol and long historical payloads from the prompt.
  static String compactLocalSystem(String system, int contextLength) {
    final characterBudget = contextLength;
    const suffix =
        '\n[Contexto local reducido: conserva inicio y datos finales; omite parte intermedia.]\n';
    if (system.length <= characterBudget) return system;
    final contentBudget = characterBudget - suffix.length;
    final prefixBudget = (contentBudget * 0.7).floor();
    final suffixBudget = contentBudget - prefixBudget;
    return '${system.substring(0, prefixBudget)}'
        '$suffix'
        '${system.substring(system.length - suffixBudget)}';
  }

  static String _parts(List parts) => parts
      .where((p) => p is Map && p['text'] is String && p['thought'] != true)
      .map((p) => p['text'] as String)
      .join('\n');

  static Future<Map<String, dynamic>> _http(
    Uri uri,
    Map<String, String> headers,
    Map<String, dynamic> body, {
    required AiProtocol protocol,
    bool chatGpt = false,
    void Function(String text)? onText,
  }) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 20);
    try {
      // Close the client on timeout too; never follow redirects with credentials.
      return await (() async {
        final request = await client.postUrl(uri);
        request.followRedirects = false;
        headers.forEach(request.headers.set);
        // HttpClientRequest.write defaults to Latin-1 without a charset.
        // History can contain accents and emoji from either participant.
        request.add(utf8.encode(jsonEncode(body)));
        final response = await request.close();
        if (response.statusCode < 200 || response.statusCode >= 300) {
          if (chatGpt) {
            final bytes = <int>[];
            await for (final chunk in response) {
              if (bytes.length + chunk.length > 65536) break;
              bytes.addAll(chunk);
            }
            Map<String, dynamic> error = {};
            try {
              error = Map<String, dynamic>.from(
                jsonDecode(utf8.decode(bytes)) as Map,
              );
            } catch (_) {
              /* Non-JSON admission failure. */
            }
            throw ChatGptFailure.response(
              response.statusCode,
              error,
              requestId: response.headers.value('x-request-id'),
            );
          }
          final message = switch (response.statusCode) {
            400 =>
              'El proveedor rechazó la solicitud (400). Revisa el protocolo de API y si ese modelo admite el tipo de adjunto enviado.',
            401 => 'El proveedor rechazó la clave API.',
            403 =>
              'El proveedor no permite esta solicitud o este modelo con tu cuenta.',
            404 =>
              'No se encontró el modelo o el endpoint. Revisa la configuración.',
            429 =>
              'Has alcanzado una cuota del proveedor. Espera o revisa tu saldo.',
            _ => 'El proveedor devolvió un error (${response.statusCode}).',
          };
          throw ValidationException(message);
        }
        if (response.headers.contentType?.mimeType == 'text/event-stream') {
          final result = AiStreamResponse(protocol, chatGpt: chatGpt);
          final eventLines = <String>[];
          var wireBytes = 0;
          final clock = Stopwatch()..start();
          var lastPublish = -100;
          void dispatch() {
            if (eventLines.isEmpty) return;
            final data = eventLines.join('\n');
            eventLines.clear();
            if (data.trim() == '[DONE]') {
              result.done();
            } else {
              result.add(Map<String, dynamic>.from(jsonDecode(data) as Map));
            }
            if (result.text.isNotEmpty &&
                clock.elapsedMilliseconds - lastPublish >= 45) {
              onText?.call(result.text);
              lastPublish = clock.elapsedMilliseconds;
            }
          }

          final chunks = response.map((chunk) {
            wireBytes += chunk.length;
            if (wireBytes > 2 * 1024 * 1024) {
              throw const ValidationException(
                'La respuesta del proveedor es demasiado grande.',
              );
            }
            return chunk;
          });
          await for (final line
              in chunks
                  .transform(utf8.decoder)
                  .transform(const LineSplitter())) {
            if (line.isEmpty) {
              dispatch();
            } else if (line.startsWith('data:')) {
              eventLines.add(line.substring(5).trimLeft());
            }
          }
          dispatch();
          return result.response();
        }
        if (chatGpt) {
          throw const ValidationException(
            'ChatGPT no devolvió el flujo de respuesta esperado. No se ha ejecutado ninguna acción.',
          );
        }
        final bytes = <int>[];
        await for (final chunk in response) {
          if (bytes.length + chunk.length > 2 * 1024 * 1024) {
            throw const ValidationException(
              'La respuesta del proveedor es demasiado grande.',
            );
          }
          bytes.addAll(chunk);
        }
        final decoded = jsonDecode(utf8.decode(bytes));
        if (decoded is! Map<String, dynamic>) {
          throw const FormatException('Expected a JSON object');
        }
        return decoded;
      })().timeout(const Duration(seconds: 90));
    } on ValidationException {
      rethrow;
    } on TimeoutException {
      throw const ValidationException(
        'El proveedor tardó demasiado. Puedes volver a intentarlo.',
      );
    } on HandshakeException {
      throw const ValidationException(
        'No se pudo establecer la conexión segura con el proveedor. Vuelve a intentarlo.',
      );
    } on SocketException {
      throw const ValidationException(
        'Se perdió la conexión con el proveedor. Tu mensaje sigue en el cuadro para volver a enviarlo.',
      );
    } on HttpException {
      throw const ValidationException(
        'El proveedor interrumpió la respuesta HTTP. Tu mensaje sigue en el cuadro para volver a enviarlo.',
      );
    } on FormatException {
      throw const ValidationException(
        'El proveedor devolvió una respuesta que no se pudo leer. Vuelve a intentarlo.',
      );
    } catch (_) {
      throw const ValidationException(
        'No se pudo conectar con la API. Comprueba tu conexión y configuración.',
      );
    } finally {
      client.close(force: true);
    }
  }
}
