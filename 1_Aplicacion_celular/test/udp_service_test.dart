import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ohm01/services/udp_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('UDP real en loopback: recepción ASCII y cierre del puerto', () async {
    final reservation = await RawDatagramSocket.bind(
      InternetAddress.loopbackIPv4,
      0,
    );
    final port = reservation.port;
    reservation.close();
    final service = UdpService();
    final result = Completer<String>();
    final errors = <String>[];
    final sender = await RawDatagramSocket.bind(
      InternetAddress.loopbackIPv4,
      0,
    );
    try {
      await service.start(port, (line, address) {
        expect(address, '127.0.0.1');
        if (!result.isCompleted) result.complete(line);
      }, errors.add);
      sender.send(
        ascii.encode('D:104,2610,830,1,1\n'),
        InternetAddress.loopbackIPv4,
        port,
      );
      expect(
        await result.future.timeout(const Duration(seconds: 3)),
        'D:104,2610,830,1,1\n',
      );
      expect(errors, isEmpty);
      await service.stop();
      final reopened = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        port,
        reuseAddress: false,
      );
      reopened.close();
    } finally {
      sender.close();
      await service.stop();
    }
  });

  test('UDP real rechaza bytes no ASCII', () async {
    final reservation = await RawDatagramSocket.bind(
      InternetAddress.loopbackIPv4,
      0,
    );
    final port = reservation.port;
    reservation.close();
    final service = UdpService();
    final error = Completer<String>();
    final sender = await RawDatagramSocket.bind(
      InternetAddress.loopbackIPv4,
      0,
    );
    try {
      await service.start(
        port,
        (_, _) => fail('No debe entregar bytes no ASCII'),
        (message) {
          if (!error.isCompleted) error.complete(message);
        },
      );
      sender.send([255, 254, 253], InternetAddress.loopbackIPv4, port);
      expect(
        await error.future.timeout(const Duration(seconds: 3)),
        'Datagrama no ASCII',
      );
    } finally {
      sender.close();
      await service.stop();
    }
  });
}
