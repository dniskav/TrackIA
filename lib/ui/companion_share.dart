import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../application/localization.dart';
import '../domain/companion.dart';
import '../domain/companion_package.dart';

/// Hands the files to the system share sheet. Injected in tests.
typedef CompanionShareSender =
    Future<void> Function(
      List<XFile> files, {
      String? subject,
      String? text,
      Rect? sharePositionOrigin,
    });

Future<void> _systemShare(
  List<XFile> files, {
  String? subject,
  String? text,
  Rect? sharePositionOrigin,
}) async {
  await Share.shareXFiles(
    files,
    subject: subject,
    text: text,
    sharePositionOrigin: sharePositionOrigin,
  );
}

/// `<name>.trackia` with only ASCII letters, digits, `_` and `-`.
String companionPackageFileName(String name) {
  final clean = name
      .replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return '${clean.isEmpty ? 'acompanante' : clean}.trackia';
}

/// Builds the package of [companion] and, after the person confirms, shares it
/// as a `.trackia` file. Nothing is shared when the package cannot be built,
/// when the person cancels, or when the file cannot be written.
///
/// When the text fits in a QR code, a dialog shows it and offers to share the
/// file instead; otherwise the file is shared right away.
///
/// [templates] beyond the package limit are not included; the confirmation
/// says so. [share] and [temporaryDirectory] exist so tests can replace the
/// platform channels.
Future<void> shareCompanionPackage(
  BuildContext context, {
  required Companion companion,
  String mode = 'reminder',
  List<PackageTemplate> templates = const [],
  CompanionShareSender? share,
  Future<Directory> Function()? temporaryDirectory,
}) async {
  final l = appText(context);
  final messenger = ScaffoldMessenger.of(context);
  final box = context.findRenderObject() as RenderBox?;
  final origin = box == null ? null : box.localToGlobal(Offset.zero) & box.size;
  final included = templates.take(CompanionPackageLimits.maxTemplates).toList();
  final omitted = templates.length > included.length;

  final String text;
  try {
    text =
        CompanionPackage.fromCompanion(
          companion,
          mode: mode,
          templates: included,
        ).encode();
  } on CompanionPackageException catch (e) {
    final tooLong =
        e.field == 'instructions' ||
        e.problem == CompanionPackageProblem.tooLarge;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          tooLong ? l.packageShareInstructionsTooLong : l.packageShareInvalid,
        ),
      ),
    );
    return;
  }
  if (!context.mounted) return;

  final confirmed = await showDialog<bool>(
    context: context,
    builder:
        (context) => AlertDialog(
          title: Text(l.packageShareTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.packageShareIncludes),
                const SizedBox(height: 10),
                Text(l.packageShareExcludes),
                const SizedBox(height: 10),
                Text(l.packageShareReceiverNote),
                if (omitted) ...[
                  const SizedBox(height: 10),
                  Text(l.packageShareTemplatesLimited),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              key: const Key('share-companion-cancel'),
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.cancel),
            ),
            FilledButton(
              key: const Key('share-companion-confirm'),
              onPressed: () => Navigator.pop(context, true),
              child: Text(l.packageShareConfirm),
            ),
          ],
        ),
  );
  if (confirmed != true || !context.mounted) return;

  Future<void> shareFile() async {
    try {
      final folder = await (temporaryDirectory?.call() ?? getTemporaryDirectory());
      final name = companionPackageFileName(companion.name);
      final file = File(p.join(folder.path, name));
      await file.writeAsString(text, encoding: utf8, flush: true);
      await (share ?? _systemShare)(
        [XFile(file.path, mimeType: 'application/octet-stream', name: name)],
        subject: companion.name,
        sharePositionOrigin: origin,
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(l.packageShareWriteError)),
      );
    }
  }

  if (!CompanionPackage.fitsInQr(text)) {
    messenger.showSnackBar(SnackBar(content: Text(l.packageQrTooLarge)));
    await shareFile();
    return;
  }

  // Leaves room for the dialog's margins and padding.
  final qrSide =
      (MediaQuery.sizeOf(context).shortestSide - 120).clamp(200.0, 320.0).toDouble();
  final shareAsFile = await showDialog<bool>(
    context: context,
    builder:
        (context) => AlertDialog(
          title: Text(l.packageQrTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // White even in dark themes: the code needs a light quiet zone.
                // The explicit SizedBox keeps the dialog's intrinsic-size pass
                // away from the QR's LayoutBuilder.
                ColoredBox(
                  color: Colors.white,
                  child: RepaintBoundary(
                    key: const Key('share-qr-boundary'),
                    child: SizedBox.square(
                      dimension: qrSide,
                      child: QrImageView(
                        key: const Key('share-qr'),
                        data: text,
                        version: QrVersions.auto,
                        errorCorrectionLevel: QrErrorCorrectLevel.L,
                        size: qrSide,
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(l.packageQrNote, textAlign: TextAlign.center),
              ],
            ),
          ),
          actions: [
            TextButton(
              key: const Key('share-qr-close'),
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.packageQrClose),
            ),
            FilledButton(
              key: const Key('share-qr-file'),
              onPressed: () => Navigator.pop(context, true),
              child: Text(l.packageQrShareFile),
            ),
          ],
        ),
  );
  if (shareAsFile == true) await shareFile();
}
