part of '../assistant_chat.dart';

/// Voice and attachments of the composer.
extension _ChatAttachments on _AssistantChatScreenState {
  void receiveText(String text) {
    if (!mounted || partialReply == text) return;
    update(() => partialReply = text);
    scheduleScrollToLatest();
  }

  Future<void> talk() async {
    if (!aiReady && !canRecord) return;
    if ((busy && (!widget.focusMode || companionFocus == null)) ||
        voiceStarting) {
      return;
    }
    if (listening) {
      await speech.stop();
      if (mounted) update(() => listening = false);
      return;
    }
    update(() {
      voiceStarting = true;
      error = null;
    });
    try {
      final available = await speech.initialize(
        options: [SpeechToText.androidNoBluetooth],
        onStatus: (status) {
          if (mounted && (status == 'done' || status == 'notListening')) {
            update(() => listening = false);
          }
        },
        onError: (_) {
          if (mounted) {
            update(() {
              listening = false;
              error =
                  'No se pudo reconocer la voz. Comprueba el permiso de micrófono o escribe tu mensaje.';
            });
          }
        },
      );
      if (!mounted) return;
      if (!available) {
        throw const ValidationException(
          'El reconocimiento de voz no está disponible. Revisa el permiso de micrófono y el servicio de voz del teléfono.',
        );
      }
      final locales = await speech.locales();
      if (!mounted) return;
      final spanish = locales
          .where((l) => l.localeId.toLowerCase().startsWith('es'))
          .toList();
      final prefix = input.text.trim();
      final speechFocus = focusId;
      update(() => listening = true);
      await speech.listen(
        localeId: spanish.isEmpty ? null : spanish.first.localeId,
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.dictation,
          partialResults: true,
          cancelOnError: true,
        ),
        onResult: (result) {
          if (!mounted || (widget.focusMode && focusId != speechFocus)) return;
          update(() {
            input.text = [
              if (prefix.isNotEmpty) prefix,
              result.recognizedWords,
            ].join(' ');
            input.selection = TextSelection.collapsed(
              offset: input.text.length,
            );
          });
        },
      );
    } on ValidationException catch (e) {
      if (mounted) {
        update(() {
          listening = false;
          error = e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        update(() {
          listening = false;
          error = 'No se pudo iniciar el dictado.';
        });
      }
    } finally {
      if (mounted) update(() => voiceStarting = false);
    }
  }

  Future<void> pickAttachment() async {
    FocusScope.of(context).unfocus();
    final kind = await showModalBottomSheet<String>(
      isScrollControlled: true,
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Cámara'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('Fotos'),
              onTap: () => Navigator.pop(context, 'image'),
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('Documento PDF'),
              subtitle: const Text('Necesita un modelo que admita documentos'),
              onTap: () => Navigator.pop(context, 'pdf'),
            ),
            ListTile(
              leading: const Icon(Icons.audio_file_outlined),
              title: const Text('Archivo de audio'),
              subtitle: const Text(
                'Requiere un modelo de Gemini que admita audio',
              ),
              onTap: () => Navigator.pop(context, 'audio'),
            ),
            ListTile(
              leading: const Icon(Icons.table_chart_outlined),
              title: const Text('Hoja Excel o CSV'),
              onTap: () => Navigator.pop(context, 'spreadsheet'),
            ),
            if (defaultTargetPlatform == TargetPlatform.android)
              ListTile(
                leading: const Icon(Icons.cloud_outlined),
                title: const Text('Google Sheets / Drive'),
                onTap: () => Navigator.pop(context, 'sheet'),
              ),
          ],
        ),
      ),
    );
    if (kind == null || !mounted) return;
    if (kind == 'sheet') {
      await chooseSheet();
      return;
    }
    if (kind == 'spreadsheet') {
      await pickSheetForChat(
        context,
        widget.controller,
        companionId: companionId,
      );
      return;
    }
    if (!aiReady && !canRecord) {
      update(
        () => error =
            'Conecta la IA para enviar imágenes, documentos o audio. Puedes cargar una hoja sin IA.',
      );
      return;
    }
    try {
      if (kind == 'camera' || kind == 'image') {
        final photo = await ImagePicker().pickImage(
          source: kind == 'camera' ? ImageSource.camera : ImageSource.gallery,
        );
        if (photo == null) return;
        if (await photo.length() > 4 * 1024 * 1024) {
          throw const ValidationException('La foto supera 4 MB.');
        }
        final bytes = await photo.readAsBytes();
        final extension = photo.name.split('.').last.toLowerCase();
        final mime = switch (extension) {
          'png' => 'image/png',
          'webp' => 'image/webp',
          'jpg' || 'jpeg' => 'image/jpeg',
          _ => null,
        };
        if (mime == null) {
          throw const ValidationException('Elige una foto JPG, PNG o WebP.');
        }
        if (bytes.isEmpty || bytes.length > 4 * 1024 * 1024) {
          throw const ValidationException(
            'La foto debe tener contenido y no superar 4 MB.',
          );
        }
        if (mounted) {
          update(() {
            attachment = AiAttachment(
              name: photo.name,
              mime: mime,
              bytes: bytes,
            );
            error = null;
          });
        }
        return;
      }
      if (kind == 'audio') {
        final config = await aiStore.load();
        if (config?.protocol != AiProtocol.gemini) {
          throw const ValidationException(
            'Para enviar un archivo de audio configura un modelo de Gemini con audio. Puedes usar el micrófono del chat para dictar el mensaje.',
          );
        }
      }
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: kind == 'pdf'
            ? ['pdf']
            : ['mp3', 'wav', 'm4a', 'ogg', 'flac'],
        withData: true,
      );
      if (picked == null || !mounted) return;
      final file = picked.files.single;
      if (file.size > 4 * 1024 * 1024) {
        throw const ValidationException('El adjunto supera 4 MB.');
      }
      final bytes =
          file.bytes ??
          (file.path == null ? null : await File(file.path!).readAsBytes());
      if (bytes == null || bytes.isEmpty) {
        throw const ValidationException('No se pudo leer el adjunto.');
      }
      final mime = switch (file.extension?.toLowerCase()) {
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'webp' => 'image/webp',
        'mp3' => 'audio/mpeg',
        'wav' => 'audio/wav',
        'm4a' => 'audio/mp4',
        'ogg' => 'audio/ogg',
        'flac' => 'audio/flac',
        'pdf' => 'application/pdf',
        _ => throw const ValidationException(
          'Formato de adjunto no compatible.',
        ),
      };
      if (mime == 'application/pdf' &&
          (bytes.length < 5 ||
              utf8.decode(bytes.take(5).toList(), allowMalformed: true) !=
                  '%PDF-')) {
        throw const ValidationException(
          'El archivo no contiene un PDF válido.',
        );
      }
      if (mounted) {
        update(() {
          attachment = AiAttachment(name: file.name, mime: mime, bytes: bytes);
          error = null;
        });
      }
    } on ValidationException catch (e) {
      if (mounted) update(() => error = e.message);
    } catch (_) {
      if (mounted) update(() => error = 'No se pudo abrir el adjunto.');
    }
  }

  Future<void> recoverPhoto() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final recovered = await ImagePicker().retrieveLostData();
      final photo = recovered.files?.lastOrNull;
      if (photo == null || !mounted || attachment != null) return;
      if (await photo.length() > 4 * 1024 * 1024) {
        update(
          () =>
              error = 'La foto recuperada supera 4 MB. Elige una más pequeña.',
        );
        return;
      }
      final mime = switch (photo.name.split('.').last.toLowerCase()) {
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'webp' => 'image/webp',
        _ => null,
      };
      if (mime == null) return;
      final bytes = await photo.readAsBytes();
      if (mounted && attachment == null && bytes.isNotEmpty) {
        update(
          () => attachment = AiAttachment(
            name: photo.name,
            mime: mime,
            bytes: bytes,
          ),
        );
      }
    } catch (_) {
      /* No pending photo on platforms without the picker bridge. */
    }
  }
}
