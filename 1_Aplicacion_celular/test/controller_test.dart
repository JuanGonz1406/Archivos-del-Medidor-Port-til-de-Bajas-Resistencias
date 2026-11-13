import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ohm01/app_controller.dart';
import 'package:ohm01/services/supabase_service.dart';
import 'package:ohm01/services/udp_service.dart';

class FakeUdp extends UdpService {
  @override
  Future<void> stop() async {}
}

void main() {
  test(
    'watchdog monotónico y duplicados congelados no reviven la sesión',
    () async {
      var time = 0;
      final c = AppController(udp: FakeUdp(), nowMs: () => time);
      c.listening = true;
      c.receive('D:100,2610,830,1,1\n', '192.168.1.2');
      expect(c.connected, true);
      time = 1900;
      c.receive('D:100,2610,830,1,1\n', '192.168.1.2');
      expect(c.duplicates, 1);
      time = 2001;
      expect(c.connected, false);
      c.receive('D:100,2610,830,1,1\n', '192.168.1.2');
      expect(c.connected, false);
      expect(c.duplicates, 2);
      expect(await c.capture(), false);
      c.receive('D:0,2610,830,1,1\n', '192.168.1.2');
      expect(c.connected, true);
      expect(c.current!.frame.sequence, 0);
      c.dispose();
    },
  );

  test('tramas inválidas y emisores distintos no reemplazan la lectura', () {
    final c = AppController(udp: FakeUdp());
    c.listening = true;
    c.receive('D:100,2610,830,1,1\n', '192.168.1.2');
    c.receive('D:101,2610,830,1,1\n', '192.168.1.3');
    c.receive('trama inválida\n', '192.168.1.2');
    c.receive('D:99,2610,830,1,1\n', '192.168.1.2');
    expect(c.accepted, 1);
    expect(c.rejected, 2);
    expect(c.outOfOrder, 1);
    expect(c.current!.frame.sequence, 100);
    c.dispose();
  });

  test('sin Internet: no hay cola ni reintento del payload', () async {
    var posts = 0;
    final cloud = SupabaseService(
      client: MockClient((_) async {
        posts++;
        throw Exception('sin Internet');
      }),
    );
    final c = AppController(cloud: cloud, udp: FakeUdp());
    c.listening = true;
    c.receive('D:1,2610,830,1,1\n', '192.168.1.2');
    expect(await c.capture(), false);
    expect(posts, 1);
    expect(c.droppedUploads, 1);
    expect(c.lastUpload, isNull);
    expect(c.httpCode, isNull);
    expect(c.uploading, false);
    expect(c.syncMessage, contains('no hay cola offline'));
    c.dispose();
  });

  test('una captura en curso impide envíos concurrentes', () async {
    final response = Completer<http.Response>();
    var posts = 0;
    final cloud = SupabaseService(
      client: MockClient((_) {
        posts++;
        return response.future;
      }),
    );
    final c = AppController(cloud: cloud, udp: FakeUdp());
    c.listening = true;
    c.receive('D:1,2610,830,1,1\n', '192.168.1.2');
    final first = c.capture();
    expect(c.uploading, true);
    expect(await c.capture(), false);
    response.complete(http.Response('', 201));
    expect(await first, true);
    expect(posts, 1);
    expect(c.httpCode, 201);
    expect(c.lastUpload, isNotNull);
    c.dispose();
  });
}
