import 'dart:convert';

class AppSettings {
  const AppSettings({
    this.port = 4210,
    this.uploadIntervalMs = 5000,
    this.systemCurrentMa = 85,
    this.gainCorrection = 1,
    this.offsetOhm = 0,
    this.automaticUpload = true,
  });

  final int port;
  final int uploadIntervalMs;
  final double systemCurrentMa;
  final double gainCorrection;
  final double offsetOhm;
  final bool automaticUpload;

  bool get isValid =>
      port >= 1024 &&
      port <= 65535 &&
      uploadIntervalMs >= 1000 &&
      uploadIntervalMs <= 3600000 &&
      systemCurrentMa.isFinite &&
      systemCurrentMa >= .001 &&
      systemCurrentMa <= 100000 &&
      gainCorrection.isFinite &&
      gainCorrection >= .000001 &&
      gainCorrection <= 1000 &&
      offsetOhm.isFinite &&
      offsetOhm.abs() <= 1;

  Map<String, dynamic> toJson() => {
    'port': port,
    'uploadIntervalMs': uploadIntervalMs,
    'systemCurrentMa': systemCurrentMa,
    'gainCorrection': gainCorrection,
    'offsetOhm': offsetOhm,
    'automaticUpload': automaticUpload,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final settings = AppSettings(
      port: (json['port'] as num).toInt(),
      uploadIntervalMs: (json['uploadIntervalMs'] as num).toInt(),
      systemCurrentMa: (json['systemCurrentMa'] as num).toDouble(),
      gainCorrection: (json['gainCorrection'] as num).toDouble(),
      offsetOhm: (json['offsetOhm'] as num).toDouble(),
      automaticUpload: json['automaticUpload'] as bool,
    );
    if (!settings.isValid) throw const FormatException('Ajustes inválidos');
    return settings;
  }
}

class RawFrame {
  const RawFrame(
    this.sequence,
    this.adcBattery,
    this.adcResistance,
    this.rb0,
    this.medEn,
  );

  final int sequence;
  final int adcBattery;
  final int adcResistance;
  final int rb0;
  final int medEn;

  static final _pattern = RegExp(
    r'^D:([0-9]{1,5}),([0-9]{1,4}),([0-9]{1,4}),([01]),([01])\n$',
  );

  factory RawFrame.parse(String line) {
    if (line.length > 40) throw const FormatException('Trama demasiado larga');
    final match = _pattern.firstMatch(line);
    if (match == null || match.end != line.length) {
      throw const FormatException('Se esperaba D:seq,an0,an1,rb0,med_en\\n');
    }
    final v = List.generate(5, (i) => int.parse(match.group(i + 1)!));
    if (v[0] > 65535 || v[1] > 4095 || v[2] > 4095) {
      throw const FormatException('ADC o secuencia fuera de rango');
    }
    return RawFrame(v[0], v[1], v[2], v[3], v[4]);
  }
}

enum SequenceResult { first, next, duplicate, old }

class SequenceTracker {
  int? last;
  int lost = 0;

  SequenceResult accept(int sequence) {
    if (last == null) {
      last = sequence;
      return SequenceResult.first;
    }
    final delta = (sequence - last!) & 0xffff;
    if (delta == 0) return SequenceResult.duplicate;
    if (delta >= 32768) return SequenceResult.old;
    lost += delta - 1;
    last = sequence;
    return SequenceResult.next;
  }

  void reset() {
    last = null;
  }
}

enum DeviceStatus { charging, lowBattery, overRange, ok }

extension DeviceStatusName on DeviceStatus {
  String get wireName => switch (this) {
    DeviceStatus.charging => 'CHARGING',
    DeviceStatus.lowBattery => 'LOW_BATTERY',
    DeviceStatus.overRange => 'OVER_RANGE',
    DeviceStatus.ok => 'OK',
  };
  String get label => switch (this) {
    DeviceStatus.charging => 'Cargando',
    DeviceStatus.lowBattery => 'Batería baja',
    DeviceStatus.overRange => 'Fuera de rango',
    DeviceStatus.ok => 'Medición activa',
  };
}

class Measurement {
  const Measurement({
    required this.frame,
    required this.receivedAt,
    required this.batteryVoltage,
    required this.batteryPercent,
    required this.amplifierVoltage,
    required this.resistorVoltage,
    required this.resistance,
    required this.status,
    required this.chargeSeconds,
    required this.dischargeSeconds,
  });

  final RawFrame frame;
  final DateTime receivedAt;
  final double batteryVoltage;
  final int batteryPercent;
  final double amplifierVoltage;
  final double resistorVoltage;
  final double? resistance;
  final DeviceStatus status;
  final int? chargeSeconds;
  final int? dischargeSeconds;
  bool get charging => frame.rb0 == 0;
  bool get enabled => frame.medEn == 1;

  Map<String, dynamic> toPayload() => {
    'device_id': 'OHM01',
    'resistance_ohm': resistance == null ? null : _round(resistance!, 4),
    'battery_voltage_v': _round(batteryVoltage, 2),
    'battery_percent': batteryPercent,
    'charging': charging,
    'charge_time_remaining_s': chargeSeconds,
    'discharge_time_remaining_s': dischargeSeconds,
    'measurement_enabled': enabled,
    'status': status.wireName,
  };

  String get prettyJson =>
      const JsonEncoder.withIndent('  ').convert(toPayload());
  static double _round(double value, int digits) =>
      double.parse(value.toStringAsFixed(digits));
}

class MeasurementCalculator {
  static const batteryCurve = <(double, double)>[
    (3.4, 0),
    (3.5, 10),
    (3.6, 20),
    (3.7, 40),
    (3.8, 55),
    (3.9, 70),
    (4.0, 80),
    (4.1, 90),
    (4.2, 100),
  ];

  static double batteryPercentage(double voltage) {
    if (voltage <= batteryCurve.first.$1) return 0;
    for (var i = 1; i < batteryCurve.length; i++) {
      final (v1, p1) = batteryCurve[i - 1];
      final (v2, p2) = batteryCurve[i];
      if (voltage <= v2) return p1 + (voltage - v1) * (p2 - p1) / (v2 - v1);
    }
    return 100;
  }

  static Measurement calculate(
    RawFrame frame,
    AppSettings settings, {
    DateTime? receivedAt,
  }) {
    if (!settings.isValid) throw const FormatException('Ajustes inválidos');
    final charging = frame.rb0 == 0;
    final enabled = frame.medEn == 1;
    if (charging && enabled ||
        !charging && frame.adcBattery <= 2321 && enabled ||
        !charging && frame.adcBattery >= 2457 && !enabled) {
      throw const FormatException(
        'MED_EN no coincide con la protección del PIC',
      );
    }
    final voltage = 2 * frame.adcBattery * 3.0 / 4095;
    final percent = batteryPercentage(voltage).round().clamp(0, 100);
    final vout = frame.adcResistance * 3.0 / 4095;
    final vr = vout / 41;
    final resistance =
        vout / 2.46 * settings.gainCorrection + settings.offsetOhm;
    if (enabled && resistance < 0) {
      throw const FormatException(
        'Resistencia negativa: revise el offset de calibración',
      );
    }
    final status = charging
        ? DeviceStatus.charging
        : !enabled
        ? DeviceStatus.lowBattery
        : resistance > 1
        ? DeviceStatus.overRange
        : DeviceStatus.ok;
    // PostgreSQL int4. Very small configured currents saturate the estimate.
    int seconds(double value) => value.round().clamp(0, 2147483647);
    return Measurement(
      frame: frame,
      receivedAt: receivedAt ?? DateTime.now().toUtc(),
      batteryVoltage: voltage,
      batteryPercent: percent,
      amplifierVoltage: vout,
      resistorVoltage: vr,
      resistance: status == DeviceStatus.ok ? resistance : null,
      status: status,
      chargeSeconds: charging
          ? seconds(3700 * (100 - percent) / 100 / 1000 * 1.15 * 3600)
          : null,
      dischargeSeconds: charging
          ? null
          : seconds(3700 * percent / 100 / settings.systemCurrentMa * 3600),
    );
  }
}
