import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:trackia/domain/companion_package.dart';

import '../test/fixtures/companion_package_fixtures.dart';

/// El decodificador REAL de Android (ML Kit, el que usa el escáner) lee un QR
/// generado con las mismas opciones que la pantalla de compartir (T060/T058).
/// No sustituye una prueba con cámara física, pero demuestra que lo que se
/// muestra al compartir es lo que el escáner entiende.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<File> renderQr(String data, Directory dir) async {
    const side = 600.0;
    const margin = 60.0; // zona de silencio blanca alrededor del código
    final painter = QrPainter(
      data: data,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.L,
      gapless: true,
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: Colors.black,
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: Colors.black,
      ),
    );
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const total = side + margin * 2;
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, total, total),
      Paint()..color = Colors.white,
    );
    canvas.translate(margin, margin);
    painter.paint(canvas, const Size(side, side));
    final image = await recorder.endRecording().toImage(
      total.toInt(),
      total.toInt(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('${dir.path}/qr-${data.length}.png');
    await file.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
    return file;
  }

  testWidgets('el decodificador de Android lee el QR de un acompañante', (
    tester,
  ) async {
    final dir = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('trackia-qr-'),
    ))!;
    final scanner = MobileScannerController(formats: [BarcodeFormat.qrCode]);
    try {
      final text = typicalPackage().encode();
      expect(
        CompanionPackage.fitsInQr(text),
        isTrue,
        reason: 'el paquete típico debe caber en un QR',
      );
      final file = (await tester.runAsync(() => renderQr(text, dir)))!;
      final capture = await tester.runAsync(
        () => scanner.analyzeImage(
          file.path,
          formats: [BarcodeFormat.qrCode],
        ),
      );
      expect(capture, isNotNull, reason: 'ML Kit no encontró ningún código');
      expect(capture!.barcodes, isNotEmpty);
      final read = capture.barcodes.first.rawValue;
      expect(read, text, reason: 'el texto leído debe ser el del archivo');
      // Y el texto leído es un paquete válido con los campos esperados.
      final decoded = CompanionPackage.decode(read!);
      expect(decoded.name, typicalPackage().name);
      expect(decoded.instructions, typicalPackage().instructions);
    } finally {
      await tester.runAsync(() async {
        await scanner.dispose();
        await dir.delete(recursive: true);
      });
    }
  });
}
