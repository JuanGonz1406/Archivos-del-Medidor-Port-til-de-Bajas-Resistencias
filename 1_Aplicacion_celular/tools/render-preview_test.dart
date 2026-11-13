// Run with: flutter test tools/render-preview_test.dart
// Renders a simulated measurement without network access or uploads.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ohm01/app_controller.dart';
import 'package:ohm01/services/udp_service.dart';
import 'package:ohm01/ui/app.dart';

class PreviewUdp extends UdpService {
  @override
  Future<void> stop() async {}
}

void main() {
  testWidgets('Vista de medición en pantalla Android 390 × 844', (
    tester,
  ) async {
    // Widget tests otherwise use the square-glyph Ahem test font.
    await tester.runAsync(() async {
      final sdk =
          Platform.environment['FLUTTER_ROOT'] ??
          '${Platform.environment['LOCALAPPDATA']}/ohm01-tools/flutter';
      final fonts = '$sdk/bin/cache/artifacts/material_fonts';
      for (final (family, filename) in [
        ('sans-serif', 'roboto-regular.ttf'),
        ('MaterialIcons', 'materialicons-regular.otf'),
      ]) {
        final loader = FontLoader(family);
        loader.addFont(
          File('$fonts/$filename').readAsBytes().then(ByteData.sublistView),
        );
        await loader.load();
      }
    });
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = AppController(udp: PreviewUdp(), nowMs: () => 0);
    controller.listening = true;
    controller.receive('D:104,2610,830,1,1\n', '192.168.1.50');
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: OhmApp(controller: controller),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('build/previews/medicion.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });
}
