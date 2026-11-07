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
                  appText(context).chatAttachVoiceError;
            });
          }
        },
      );
      if (!mounted) return;
      if (!available) {
        throw ValidationException(
          appText(context).chatAttachVoiceUnavailable,
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
          error = appText(context).chatAttachDictationStart;
        });
      }
    } finally {
      if (mounted) update(() => voiceStarting = false);
    }
  }

  Future<void> pickAttachment() async {
    final l = appText(context);
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
              title: Text(appText(context).chatAttachCamera),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: Text(appText(context).chatAttachPhotos),
              onTap: () => Navigator.pop(context, 'image'),
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: Text(appText(context).chatAttachPdf),
              subtitle: Text(appText(context).chatAttachPdfHint),
              onTap: () => Navigator.pop(context, 'pdf'),
            ),
            ListTile(
              leading: const Icon(Icons.audio_file_outlined),
              title: Text(appText(context).chatAttachAudio),
              subtitle: Text(
                appText(context).chatAttachAudioHint,
              ),
              onTap: () => Navigator.pop(context, 'audio'),
            ),
            ListTile(
              leading: const Icon(Icons.table_chart_outlined),
              title: Text(appText(context).chatAttachSpreadsheet),
              onTap: () => Navigator.pop(context, 'spreadsheet'),
            ),
            if (defaultTargetPlatform == TargetPlatform.android)
              ListTile(
                leading: const Icon(Icons.cloud_outlined),
                title: Text(appText(context).chatAttachSheet),
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
            appText(context).chatAttachNeedsAi,
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
          throw ValidationException(l.chatAttachPhotoTooLarge);
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
          throw ValidationException(l.chatAttachPhotoFormat);
        }
        if (bytes.isEmpty || bytes.length > 4 * 1024 * 1024) {
          throw ValidationException(
            l.chatAttachPhotoEmpty,
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
          throw ValidationException(
            l.chatAttachAudioNeedsGemini,
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
        throw ValidationException(appText(context).chatAttachTooLarge);
      }
      final bytes =
          file.bytes ??
          (file.path == null ? null : await File(file.path!).readAsBytes());
      if (bytes == null || bytes.isEmpty) {
        throw ValidationException(l.chatAttachUnreadable);
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
        _ => throw ValidationException(
          l.chatAttachFormat,
        ),
      };
      if (mime == 'application/pdf' &&
          (bytes.length < 5 ||
              utf8.decode(bytes.take(5).toList(), allowMalformed: true) !=
                  '%PDF-')) {
        throw ValidationException(
          l.chatAttachInvalidPdf,
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
      if (mounted) update(() => error = appText(context).chatAttachOpenFailed);
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
              error = appText(context).chatAttachRecoveredTooLarge,
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
