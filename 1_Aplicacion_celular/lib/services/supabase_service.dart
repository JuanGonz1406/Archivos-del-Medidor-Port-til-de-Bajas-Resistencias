import 'dart:convert';
import 'package:http/http.dart' as http;

class UploadResult {
  const UploadResult(this.code, this.message);
  final int code;
  final String message;
  bool get success => code == 201;
}

class SupabaseService {
  SupabaseService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  static const baseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://cnmyjbqtmhespicruvrk.supabase.co',
  );
  static const publicKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_PuFVcFURGHfgCLZB_rBNDQ_7xTDINvp',
  );

  Map<String, String> get _headers => {
    'apikey': publicKey,
    'Content-Type': 'application/json',
    'Prefer': 'return=minimal',
  };

  Future<UploadResult> insert(Map<String, dynamic> payload) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/rest/v1/measurements'),
          headers: _headers,
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 12));
    return UploadResult(
      response.statusCode,
      response.statusCode == 201 ? 'Registro almacenado' : _error(response),
    );
  }

  Future<List<Map<String, dynamic>>> history({int limit = 100}) async {
    final uri = Uri.parse('$baseUrl/rest/v1/measurements').replace(
      queryParameters: {
        'device_id': 'eq.OHM01',
        'select':
            'id,created_at,device_id,resistance_ohm,battery_voltage_v,battery_percent,charging,status',
        'order': 'created_at.desc',
        'limit': '$limit',
      },
    );
    final response = await _client
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: ${_error(response)}');
    }
    final body = jsonDecode(response.body) as List;
    return body.map((row) => Map<String, dynamic>.from(row as Map)).toList();
  }

  String _error(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return '${body['message'] ?? 'Error de Supabase'}';
    } catch (_) {
      return 'Respuesta HTTP ${response.statusCode}';
    }
  }

  void dispose() => _client.close();
}
