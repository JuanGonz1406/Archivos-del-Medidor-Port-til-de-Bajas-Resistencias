import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ohm01/app_controller.dart';
import 'package:ohm01/domain/measurement.dart';
import 'package:ohm01/services/udp_service.dart';
import 'package:ohm01/ui/app.dart';

class TestUdp extends UdpService {
  @override
  Future<void> stop() async {}
}

void main() {
  testWidgets('sin dispositivo, cuatro vistas y captura bloqueada', (
    tester,
  ) async {
    final c = AppController(udp: TestUdp());
    await tester.pumpWidget(OhmApp(controller: c));
    expect(find.text('Centro de medición'), findsOneWidget);
    expect(find.text('DESCONECTADO'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Capturar en Supabase'), 150);
    final capture = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Capturar en Supabase'),
        matching: find.byWidgetPredicate((w) => w is FilledButton),
      ),
    );
    expect(capture.onPressed, isNull);
    await tester.tap(find.text('Diagnóstico'));
    await tester.pumpAndSettle();
    expect(find.text('ENLACE LOCAL'), findsOneWidget);
    await tester.tap(find.text('Ajustes'));
    await tester.pumpAndSettle();
    expect(find.text('Puerto UDP'), findsOneWidget);
    expect(find.text('4210'), findsOneWidget);
    c.dispose();
  });

  testWidgets('muestra lectura y permite cambiar unidades', (tester) async {
    final c = AppController(udp: TestUdp());
    c.listening = true;
    c.receive('D:1,2610,830,1,1\n', '192.168.1.50');
    await tester.pumpWidget(OhmApp(controller: c));
    expect(find.text('OK'), findsOneWidget);
    final r = MeasurementCalculator.calculate(
      const RawFrame(1, 2610, 830, 1, 1),
      const AppSettings(),
    ).resistance!;
    expect(find.text(r.toStringAsFixed(4)), findsOneWidget);
    await tester.tap(find.text('mΩ'));
    await tester.pumpAndSettle();
    expect(find.text((r * 1000).toStringAsFixed(2)), findsOneWidget);
    c.dispose();
  });
}
