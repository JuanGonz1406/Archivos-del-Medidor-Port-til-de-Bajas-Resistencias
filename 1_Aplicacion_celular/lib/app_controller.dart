import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'domain/measurement.dart';
import 'services/supabase_service.dart';
import 'services/udp_service.dart';

class AppController extends ChangeNotifier {
  AppController({
    SupabaseService? cloud,
    UdpService? udp,
    int Function()? nowMs,
  }) : cloud = cloud ?? SupabaseService(),
       udp = udp ?? UdpService() {
    _nowMs = nowMs ?? (() => _clock.elapsedMilliseconds);
  }

  final SupabaseService cloud;
  final UdpService udp;
  final sequence = SequenceTracker();
  final _clock = Stopwatch()..start();
  late final int Function() _nowMs;
  AppSettings settings = const AppSettings();
  Measurement? current;
  final List<Measurement> trend = [];
  List<Map<String, dynamic>> remoteHistory = [];
  bool listening = false;
  bool uploading = false;
  bool loadingHistory = false;
  bool active = true;
  bool _disposed = false;
  String? sourceIp;
  String? lastFrame;
  String? localError;
  String? settingsError;
  String? historyError;
  String syncMessage = 'Sin envíos todavía';
  int? httpCode;
  DateTime? lastUpload;
  Map<String, dynamic>? lastSentPayload;
  int accepted = 0;
  int rejected = 0;
  int duplicates = 0;
  int outOfOrder = 0;
  int droppedUploads = 0;
  int packetsPerSecond = 0;
  int _rateCount = 0;
  int _rateStart = 0;
  int? _lastReceiveTick;
  int? _lastAutomaticSample;
  int _lastUploadAttempt = 0;
  Timer? _ticker;

  bool get connected =>
      active &&
      listening &&
      _lastReceiveTick != null &&
      _nowMs() - _lastReceiveTick! <= 2000;
  int? get sampleAgeMs =>
      _lastReceiveTick == null ? null : _nowMs() - _lastReceiveTick!;

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('ohm01.settings');
      if (stored != null) {
        settings = AppSettings.fromJson(
          jsonDecode(stored) as Map<String, dynamic>,
        );
      }
    } catch (_) {
      settingsError =
          'No se pudieron leer los ajustes; se usan los valores predeterminados.';
    }
    if (_disposed) return;
    await start();
    _ticker = Timer.periodic(const Duration(milliseconds: 300), (_) => _tick());
    unawaited(loadHistory());
  }

  Future<void> start() async {
    if (_disposed) return;
    listening = false;
    _lastReceiveTick = null;
    sourceIp = null;
    sequence.reset();
    _lastUploadAttempt = _nowMs();
    try {
      await udp.start(settings.port, receive, (error) {
        localError = error;
        rejected++;
        _notify();
      });
      if (_disposed) {
        await udp.stop();
        return;
      }
      listening = true;
      localError = null;
    } catch (error) {
      localError = 'No se pudo abrir UDP ${settings.port}: $error';
    }
    _notify();
  }

  void receive(String line, String address) {
    if (!active || _disposed) return;
    try {
      final frame = RawFrame.parse(line);
      final measurement = MeasurementCalculator.calculate(frame, settings);
      if (!connected) {
        // Repeated frozen packets cannot revive the watchdog after timeout.
        if (sourceIp == address && sequence.last == frame.sequence) {
          duplicates++;
          return;
        }
        sequence.reset();
        sourceIp = null;
      }
      if (sourceIp != null && sourceIp != address) {
        throw const FormatException(
          'Otro emisor UDP: se conserva el equipo conectado',
        );
      }
      final result = sequence.accept(frame.sequence);
      if (result == SequenceResult.duplicate) {
        duplicates++;
        return;
      }
      if (result == SequenceResult.old) {
        outOfOrder++;
        return;
      }
      sourceIp = address;
      lastFrame = line.trimRight();
      current = measurement;
      _lastReceiveTick = _nowMs();
      accepted++;
      _rateCount++;
      localError = null;
      trend.add(measurement);
      if (trend.length > 180) trend.removeAt(0);
      // Display is refreshed by the 300 ms ticker, not for every datagram.
    } on FormatException catch (error) {
      rejected++;
      localError = error.message;
    }
  }

  void _tick() {
    if (_disposed) return;
    final now = _nowMs();
    if (now - _rateStart >= 1000) {
      packetsPerSecond = (_rateCount * 1000 / (now - _rateStart)).round();
      _rateCount = 0;
      _rateStart = now;
    }
    if (settings.automaticUpload &&
        connected &&
        !uploading &&
        now - _lastUploadAttempt >= settings.uploadIntervalMs &&
        _lastAutomaticSample != _lastReceiveTick) {
      unawaited(capture(automatic: true));
    }
    _notify();
  }

  Future<bool> capture({bool automatic = false}) async {
    if (!connected || current == null || uploading) return false;
    uploading = true;
    _lastUploadAttempt = _nowMs();
    if (automatic) _lastAutomaticSample = _lastReceiveTick;
    final payload = current!.toPayload();
    lastSentPayload = Map.of(payload);
    syncMessage = 'Enviando a Supabase…';
    _notify();
    var success = false;
    try {
      final result = await cloud.insert(payload);
      httpCode = result.code;
      success = result.success;
      syncMessage = result.message;
      if (success) {
        lastUpload = DateTime.now();
      } else {
        droppedUploads++;
        syncMessage =
            '${result.message}. Captura no guardada; no hay cola offline.';
      }
    } catch (_) {
      httpCode = null;
      droppedUploads++;
      syncMessage =
          'Sin respuesta de Internet. Captura sin confirmar; no hay cola offline.';
    } finally {
      uploading = false;
      _notify();
    }
    return success;
  }

  Future<void> loadHistory() async {
    if (loadingHistory || _disposed) return;
    loadingHistory = true;
    historyError = null;
    _notify();
    try {
      final rows = await cloud.history();
      if (!_disposed) remoteHistory = rows;
    } catch (error) {
      historyError = 'No se pudo consultar el historial: $error';
    } finally {
      loadingHistory = false;
      _notify();
    }
  }

  Future<void> saveSettings(AppSettings value) async {
    if (!value.isValid) throw const FormatException('Revise los ajustes');
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString('ohm01.settings', jsonEncode(value.toJson()))) {
      throw Exception('No se pudieron guardar los ajustes');
    }
    final restart = value.port != settings.port;
    settings = value;
    // A new frame is required after changing calibration/current settings.
    current = null;
    trend.clear();
    _lastReceiveTick = null;
    sequence.reset();
    settingsError = null;
    _lastUploadAttempt = _nowMs();
    if (restart && active) await start();
    _notify();
  }

  Future<void> setActive(bool value) async {
    active = value;
    if (value) {
      await start();
    } else {
      listening = false;
      _lastReceiveTick = null;
      await udp.stop();
    }
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _ticker?.cancel();
    unawaited(udp.stop());
    cloud.dispose();
    super.dispose();
  }
}
