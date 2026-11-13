import 'package:flutter_test/flutter_test.dart';
import 'package:ohm01/domain/measurement.dart';

void main() {
  group('Trama UDP', () {
    test('ejemplo válido', () {
      final f = RawFrame.parse('D:104,2610,830,1,1\n');
      expect(f.sequence, 104);
      expect(f.adcBattery, 2610);
      expect(f.adcResistance, 830);
      expect(f.rb0, 1);
      expect(f.medEn, 1);
    });
    for (final invalid in [
      '104,2610,830,1,1\n',
      'D:104,2610,830,1,1',
      'D:65536,2610,830,1,1\n',
      'D:1,4096,0,1,1\n',
      'D:1,2610,4096,1,1\n',
      'D:1,2610,830,2,1\n',
      'D:1,2610,830,1,2\n',
      'D:1,2610,830,1,1,0\n',
      'D:-1,2610,830,1,1\n',
      'D:1,2610.0,830,1,1\n',
      'D:1,2610,830,1,1\nD:2,2610,830,1,1\n',
      'D:1,2610,830,1,1\n\n',
      'D: 1,2610,830,1,1\n',
    ]) {
      test('rechaza ${invalid.replaceAll('\n', r'\n')}', () {
        expect(() => RawFrame.parse(invalid), throwsFormatException);
      });
    }
  });

  group('Secuencias', () {
    test('duplicados, pérdidas y fuera de orden', () {
      final s = SequenceTracker();
      expect(s.accept(100), SequenceResult.first);
      expect(s.accept(100), SequenceResult.duplicate);
      expect(s.accept(103), SequenceResult.next);
      expect(s.lost, 2);
      expect(s.accept(102), SequenceResult.old);
      expect(s.last, 103);
    });
    test('desbordamiento y reinicio', () {
      final s = SequenceTracker();
      s.accept(65535);
      expect(s.accept(0), SequenceResult.next);
      expect(s.lost, 0);
      expect(s.accept(65535), SequenceResult.old);
      s.reset();
      expect(s.accept(0), SequenceResult.first);
    });
  });

  group('Cálculos', () {
    const settings = AppSettings();
    Measurement calculate(int an0, int an1, int rb0, int en) =>
        MeasurementCalculator.calculate(
          RawFrame(1, an0, an1, rb0, en),
          settings,
        );
    test('voltaje, resistencia y nueve campos exactos', () {
      final m = calculate(2610, 830, 1, 1);
      expect(m.batteryVoltage, closeTo(3.8241758, 1e-6));
      expect(m.batteryPercent, 59);
      expect(m.amplifierVoltage, closeTo(830 * 3 / 4095, 1e-12));
      expect(m.resistorVoltage, closeTo(m.amplifierVoltage / 41, 1e-12));
      expect(m.resistance, closeTo(m.resistorVoltage / .060, 1e-12));
      expect(m.status, DeviceStatus.ok);
      final json = m.toPayload();
      expect(json.keys.toSet(), {
        'device_id',
        'resistance_ohm',
        'battery_voltage_v',
        'battery_percent',
        'charging',
        'charge_time_remaining_s',
        'discharge_time_remaining_s',
        'measurement_enabled',
        'status',
      });
      expect(json['battery_voltage_v'], 3.82);
      expect(json['charge_time_remaining_s'], isNull);
      expect(
        json['discharge_time_remaining_s'],
        (3700 * .59 / 85 * 3600).round(),
      );
    });
    test('puntos e interpolación de batería', () {
      for (final (voltage, percent) in MeasurementCalculator.batteryCurve) {
        expect(
          MeasurementCalculator.batteryPercentage(voltage),
          closeTo(percent, 1e-9),
        );
      }
      expect(MeasurementCalculator.batteryPercentage(3.82), closeTo(58, 1e-8));
      expect(MeasurementCalculator.batteryPercentage(2), 0);
      expect(MeasurementCalculator.batteryPercentage(5), 100);
    });
    test('carga tiene prioridad sobre batería baja y rango', () {
      final m = calculate(2000, 4095, 0, 0);
      expect(m.status, DeviceStatus.charging);
      expect(m.resistance, isNull);
      expect(m.enabled, false);
      expect(m.chargeSeconds, 15318);
      expect(m.dischargeSeconds, isNull);
    });
    test('batería baja e histéresis inferida de MED_EN', () {
      expect(calculate(2321, 830, 1, 0).status, DeviceStatus.lowBattery);
      expect(calculate(2400, 830, 1, 0).status, DeviceStatus.lowBattery);
      expect(calculate(2400, 830, 1, 1).status, DeviceStatus.ok);
      expect(calculate(2457, 830, 1, 1).status, DeviceStatus.ok);
    });
    test('protección incompatible se rechaza', () {
      expect(() => calculate(2610, 830, 0, 1), throwsFormatException);
      expect(() => calculate(2321, 830, 1, 1), throwsFormatException);
      expect(() => calculate(2457, 830, 1, 0), throwsFormatException);
    });
    test('cero, fuera de rango y carga finalizada', () {
      expect(calculate(2610, 0, 1, 1).resistance, 0);
      final over = calculate(2610, 4095, 1, 1);
      expect(over.status, DeviceStatus.overRange);
      expect(over.resistance, isNull);
      expect(over.enabled, true);
      final full = calculate(2867, 830, 1, 1);
      expect(full.charging, false);
      expect(full.batteryPercent, 100);
      expect(full.chargeSeconds, isNull);
      expect(full.dischargeSeconds, (3700 / 85 * 3600).round());
    });
    test('calibración antes de redondeo y clasificación', () {
      final base = calculate(2610, 830, 1, 1);
      final adjusted = MeasurementCalculator.calculate(
        const RawFrame(1, 2610, 830, 1, 1),
        const AppSettings(gainCorrection: 1.02, offsetOhm: .0001),
      );
      expect(
        adjusted.resistance,
        closeTo(base.resistance! * 1.02 + .0001, 1e-12),
      );
      expect(
        () => MeasurementCalculator.calculate(
          const RawFrame(1, 2610, 0, 1, 1),
          const AppSettings(offsetOhm: -.001),
        ),
        throwsFormatException,
      );
    });
    test('ajustes serializables y consumo configurable', () {
      const s = AppSettings(systemCurrentMa: 462.8, automaticUpload: false);
      expect(AppSettings.fromJson(s.toJson()).systemCurrentMa, 462.8);
      expect(AppSettings.fromJson(s.toJson()).automaticUpload, false);
      expect(const AppSettings(systemCurrentMa: 0).isValid, false);
      expect(const AppSettings(port: 0).isValid, false);
      expect(const AppSettings(gainCorrection: double.nan).isValid, false);
    });
  });
}
