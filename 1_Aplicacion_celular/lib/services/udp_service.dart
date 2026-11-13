import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';

class UdpService {
  static const _platform = MethodChannel('ohm01/network');
  RawDatagramSocket? _socket;
  StreamSubscription<RawSocketEvent>? _subscription;

  Future<void> start(
    int port,
    void Function(String, String) onData,
    void Function(String) onError,
  ) async {
    await stop();
    try {
      try {
        await _platform.invokeMethod<void>('acquireMulticastLock');
      } on MissingPluginException {
        // Enables unit/widget tests without an Android host.
      }
      final socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        port,
        reuseAddress: false,
      );
      _socket = socket;
      socket.broadcastEnabled = true;
      _subscription = socket.listen(
        (event) {
          if (event != RawSocketEvent.read) return;
          Datagram? packet;
          while ((packet = socket.receive()) != null) {
            final p = packet!;
            if (p.data.length > 96) {
              onError('Datagrama demasiado grande');
              continue;
            }
            try {
              onData(ascii.decode(p.data), p.address.address);
            } on FormatException {
              onError('Datagrama no ASCII');
            }
          }
        },
        onError: (Object error) => onError('UDP: $error'),
        onDone: () {
          onError('Socket UDP cerrado');
        },
      );
    } catch (_) {
      await stop();
      rethrow;
    }
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    _socket?.close();
    _socket = null;
    try {
      await _platform.invokeMethod<void>('releaseMulticastLock');
    } on MissingPluginException {
      // No Android host in tests.
    }
  }
}
