import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../application/companion_creation.dart';
import '../application/localization.dart';
import '../data/companion_store.dart';
import '../domain/companion.dart';
import '../l10n/generated/app_localizations.dart';
import 'companion_import.dart';

/// Builds the camera view. Calls [onCode] with the first text found in a QR
/// code and [onError] when the camera cannot be used. Injectable for tests.
typedef CompanionScannerBuilder =
    Widget Function(
      BuildContext context,
      ValueChanged<String> onCode,
      ValueChanged<Object> onError,
    );

/// Opens the scanner and, with the scanned text, the import preview. The
/// camera (and its permission) is only touched once the scanner screen opens.
Future<Companion?> scanAndImportCompanion(
  BuildContext context, {
  required CompanionStore store,
  required CompanionCreation creation,
  Iterable<String> takenIds = const [],
  CompanionScannerBuilder? scannerBuilder,
}) async {
  final navigator = Navigator.of(context);
  final raw = await navigator.push<String>(
    MaterialPageRoute(
      builder: (_) => CompanionScanScreen(scannerBuilder: scannerBuilder),
    ),
  );
  if (raw == null) return null;
  return navigator.push<Companion>(
    MaterialPageRoute(
      builder: (_) => CompanionImportScreen(
        store: store,
        creation: creation,
        takenIds: takenIds,
        // The empty string means «import from file or text» instead.
        initialText: raw.isEmpty ? null : raw,
      ),
    ),
  );
}

/// «Escanear acompañante»: camera with a frame. Pops with the text of the
/// first QR code detected, or with [useFile] (empty string) when the user
/// prefers the file or text import after an error.
class CompanionScanScreen extends StatefulWidget {
  const CompanionScanScreen({super.key, this.scannerBuilder});

  /// Result meaning «go to the import by file or text».
  static const useFile = '';

  final CompanionScannerBuilder? scannerBuilder;

  @override
  State<CompanionScanScreen> createState() => _CompanionScanScreenState();
}

class _CompanionScanScreenState extends State<CompanionScanScreen> {
  Object? error;
  bool done = false;

  void _onCode(String raw) {
    if (done || !mounted) return;
    done = true;
    Navigator.of(context).pop(raw);
  }

  void _onError(Object e) {
    if (done || !mounted) return;
    setState(() => error = e);
  }

  bool get _denied =>
      error is MobileScannerException &&
      (error as MobileScannerException).errorCode ==
          MobileScannerErrorCode.permissionDenied;

  @override
  Widget build(BuildContext context) {
    final l = appText(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.packageScanTitle)),
      body: error != null ? _failure(l) : _camera(l),
    );
  }

  Widget _failure(AppLocalizations l) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.no_photography_outlined, size: 48),
          const SizedBox(height: 12),
          Text(
            _denied ? l.packageScanPermissionDenied : l.packageScanCameraError,
            key: const Key('scan-error'),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('scan-use-file'),
            onPressed: () =>
                Navigator.of(context).pop(CompanionScanScreen.useFile),
            child: Text(l.packageScanUseFile),
          ),
        ],
      ),
    ),
  );

  Widget _camera(AppLocalizations l) {
    final builder = widget.scannerBuilder ?? _defaultScanner;
    return Stack(
      fit: StackFit.expand,
      children: [
        builder(context, _onCode, _onError),
        IgnorePointer(
          child: Center(
            child: Container(
              key: const Key('scan-frame'),
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 24,
          child: Text(
            l.packageScanHint,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              shadows: [Shadow(blurRadius: 4)],
            ),
          ),
        ),
      ],
    );
  }

  static Widget _defaultScanner(
    BuildContext context,
    ValueChanged<String> onCode,
    ValueChanged<Object> onError,
  ) => _CameraView(onCode: onCode, onError: onError);
}

/// Real camera view: creates its controller when built (opening the screen)
/// and disposes it, which stops the camera.
class _CameraView extends StatefulWidget {
  const _CameraView({required this.onCode, required this.onError});

  final ValueChanged<String> onCode;
  final ValueChanged<Object> onError;

  @override
  State<_CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<_CameraView> {
  late final MobileScannerController controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool reported = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _detect(BarcodeCapture capture) {
    for (final b in capture.barcodes) {
      final raw = b.rawValue;
      if (b.format == BarcodeFormat.qrCode && raw != null && raw.isNotEmpty) {
        controller.stop();
        widget.onCode(raw);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(
          controller: controller,
          onDetect: _detect,
          errorBuilder: (context, e) {
            if (!reported) {
              reported = true;
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => widget.onError(e),
              );
            }
            return const ColoredBox(color: Colors.black);
          },
        ),
        Positioned(
          top: 8,
          right: 8,
          child: IconButton(
            key: const Key('scan-torch'),
            tooltip: appText(context).packageScanTorch,
            color: Colors.white,
            onPressed: controller.toggleTorch,
            icon: const Icon(Icons.flashlight_on_outlined),
          ),
        ),
      ],
    );
  }
}
