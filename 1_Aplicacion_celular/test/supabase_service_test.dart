import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ohm01/domain/measurement.dart';
import 'package:ohm01/services/supabase_service.dart';

void main() {
  test(
    'POST exacto: apikey sin Authorization, nueve campos y HTTP 201',
    () async {
      final service = SupabaseService(
        client: MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/rest/v1/measurements');
          expect(request.headers['apikey'], SupabaseService.publicKey);
          expect(request.headers.containsKey('Authorization'), false);
          expect(request.headers['Prefer'], 'return=minimal');
          final body = jsonDecode(request.body) as Map;
          expect(body.length, 9);
          expect(body.containsKey('id'), false);
          expect(body.containsKey('created_at'), false);
          return http.Response('', 201);
        }),
      );
      final m = MeasurementCalculator.calculate(
        const RawFrame(1, 2610, 830, 1, 1),
        const AppSettings(),
      );
      expect((await service.insert(m.toPayload())).success, true);
      service.dispose();
    },
  );
  test('errores de RLS se exponen, no se confirma el envío', () async {
    final service = SupabaseService(
      client: MockClient(
        (_) async => http.Response('{"message":"RLS denied"}', 403),
      ),
    );
    final response = await service.insert({});
    expect(response.success, false);
    expect(response.code, 403);
    expect(response.message, 'RLS denied');
    service.dispose();
  });
  test('historial remoto filtrado, ordenado y limitado', () async {
    final service = SupabaseService(
      client: MockClient((request) async {
        expect(request.url.queryParameters['device_id'], 'eq.OHM01');
        expect(request.url.queryParameters['order'], 'created_at.desc');
        expect(request.url.queryParameters['limit'], '100');
        return http.Response('[{"id":1,"resistance_ohm":0.1254}]', 200);
      }),
    );
    expect((await service.history()).single['resistance_ohm'], .1254);
    service.dispose();
  });
}
