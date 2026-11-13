import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../app_controller.dart';
import '../domain/measurement.dart';

const green = Color(0xff67a82e);
const ink = Color(0xff183325);
const muted = Color(0xff6c7b72);

class OhmApp extends StatelessWidget {
  const OhmApp({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'OHM01 · UIS',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: green,
        primary: const Color(0xff397b24),
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xfff3f6f2),
      fontFamily: 'sans-serif',
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xfff3f6f2),
        foregroundColor: ink,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xfff5f7f4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xffdce5d9)),
        ),
      ),
    ),
    home: HomeScreen(controller: controller),
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.controller});
  final AppController controller;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int page = 0;
  bool milliohms = false;
  AppController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      c.setActive(true);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      c.setActive(false);
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: c,
    builder: (context, _) {
      final titles = [
        'Centro de medición',
        'Diagnóstico',
        'Historial',
        'Ajustes',
      ];
      return Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'UIS / E3T',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: muted,
                ),
              ),
              Text(
                titles[page],
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: c.connected
                    ? const Color(0xffe5f1db)
                    : const Color(0xffe6eae6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.circle,
                    size: 7,
                    color: c.connected ? green : muted,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'OHM01',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: KeyedSubtree(
            key: ValueKey(page),
            child: switch (page) {
              0 => _dashboard(),
              1 => _diagnostics(),
              2 => _history(),
              _ => SettingsPage(controller: c),
            },
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: page,
          onDestinationSelected: (value) {
            setState(() => page = value);
            if (value == 2) c.loadHistory();
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.speed_outlined),
              selectedIcon: Icon(Icons.speed),
              label: 'Medición',
            ),
            NavigationDestination(icon: Icon(Icons.code), label: 'Diagnóstico'),
            NavigationDestination(
              icon: Icon(Icons.show_chart),
              label: 'Historial',
            ),
            NavigationDestination(icon: Icon(Icons.tune), label: 'Ajustes'),
          ],
        ),
      );
    },
  );

  Widget _dashboard() {
    final m = c.connected ? c.current : null;
    final color = m == null ? muted : statusColor(m.status);
    final r = m?.resistance;
    return _scroll([
      Row(
        children: [
          const Expanded(
            child: Text(
              'MEDIDOR DE BAJAS RESISTENCIAS',
              style: TextStyle(
                color: muted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.1,
              ),
            ),
          ),
          Text(
            '0 — 1 Ω',
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: ink,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'RESISTENCIA',
                  style: TextStyle(
                    color: Color(0xffa1b9a6),
                    fontSize: 12,
                    letterSpacing: 2,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .22),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    m?.status.wireName ?? 'DESCONECTADO',
                    style: TextStyle(
                      color: m == null
                          ? const Color(0xffc1cdc3)
                          : _brightStatus(m.status),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    r == null
                        ? (milliohms ? '–––.––' : '–.––––')
                        : (milliohms ? r * 1000 : r).toStringAsFixed(
                            milliohms ? 2 : 4,
                          ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 62,
                      fontWeight: FontWeight.w300,
                      letterSpacing: -2,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    milliohms ? 'mΩ' : 'Ω',
                    style: const TextStyle(
                      color: Color(0xffa1b9a6),
                      fontSize: 27,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              m?.status.label ?? 'Esperando datos del dispositivo',
              style: const TextStyle(color: Color(0xffb4c7b8), fontSize: 13),
            ),
            const SizedBox(height: 22),
            SegmentedButton<bool>(
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                foregroundColor: const Color(0xffb4c7b8),
                selectedForegroundColor: ink,
                selectedBackgroundColor: const Color(0xffbbdc9d),
              ),
              segments: const [
                ButtonSegment(
                  value: false,
                  label: Text('Ω'),
                  tooltip: 'Ohmios',
                ),
                ButtonSegment(
                  value: true,
                  label: Text('mΩ'),
                  tooltip: 'Miliohmios',
                ),
              ],
              selected: {milliohms},
              onSelectionChanged: (v) => setState(() => milliohms = v.first),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      _card(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  m?.charging == true
                      ? Icons.battery_charging_full
                      : Icons.battery_5_bar,
                  color: green,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Batería',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  m == null ? '— %' : '${m.batteryPercent} %',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: ink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (m?.batteryPercent ?? 0) / 100,
                minHeight: 7,
                color: m?.status == DeviceStatus.lowBattery
                    ? Colors.red
                    : green,
                backgroundColor: const Color(0xffedf1e9),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 16,
              runSpacing: 8,
              children: [
                Text(
                  m == null
                      ? '— V'
                      : '${m.batteryVoltage.toStringAsFixed(2)} V',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  m == null
                      ? 'Sin estimación'
                      : '${m.charging ? 'Carga' : 'Autonomía'} · ${durationText(m.chargeSeconds ?? m.dischargeSeconds)}',
                  style: const TextStyle(color: muted, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Estimación por voltaje · capacidad nominal 3700 mAh',
              style: TextStyle(color: muted, fontSize: 10),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: _smallMetric(
              'Voltaje en Rx',
              m?.enabled == true
                  ? '${(m!.resistorVoltage * 1000).toStringAsFixed(2)} mV'
                  : '—',
              Icons.electric_bolt,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _smallMetric(
              'Salida INA333',
              m?.enabled == true
                  ? '${m!.amplifierVoltage.toStringAsFixed(3)} V'
                  : '—',
              Icons.insights,
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      FilledButton.icon(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: !c.connected || c.uploading
            ? null
            : () async {
                final ok = await c.capture();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        ok ? 'Captura guardada en Supabase' : c.syncMessage,
                      ),
                    ),
                  );
                }
              },
        icon: c.uploading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add_a_photo_outlined),
        label: Text(c.uploading ? 'Enviando…' : 'Capturar en Supabase'),
      ),
      const SizedBox(height: 10),
      Center(
        child: Text(
          c.settings.automaticUpload
              ? 'Envío automático cada ${c.settings.uploadIntervalMs / 1000} s'
              : 'Envío automático desactivado',
          style: const TextStyle(color: muted, fontSize: 12),
        ),
      ),
      const SizedBox(height: 16),
      _syncStrip(),
      if (c.localError != null) ...[
        const SizedBox(height: 12),
        _notice(c.localError!, warning: true),
      ],
      if (!c.connected) ...[
        const SizedBox(height: 12),
        _notice(
          'Conecta el ESP-01 y este teléfono a la misma red. La app escucha broadcast UDP en el puerto ${c.settings.port}.',
        ),
      ],
    ]);
  }

  Widget _diagnostics() => _scroll([
    _section('ENLACE LOCAL', Icons.wifi),
    _card(
      Column(
        children: [
          _kv('Estado', c.connected ? 'Recibiendo' : 'DESCONECTADO'),
          _kv('Escucha', '0.0.0.0:${c.settings.port} · UDP'),
          _kv('Emisor', c.sourceIp ?? 'Sin descubrir'),
          _kv('Paquetes / segundo', '${c.packetsPerSecond}'),
          _kv('Aceptados / perdidos', '${c.accepted} / ${c.sequence.lost}'),
          _kv(
            'Duplicados / fuera de orden',
            '${c.duplicates} / ${c.outOfOrder}',
          ),
          _kv('Rechazados', '${c.rejected}'),
          _kv('Última secuencia', '${c.current?.frame.sequence ?? '—'}'),
          _kv(
            'Edad de la muestra',
            c.sampleAgeMs == null ? '—' : '${c.sampleAgeMs} ms',
          ),
          _kv(
            'AN0 / AN1',
            c.current == null
                ? '—'
                : '${c.current!.frame.adcBattery} / ${c.current!.frame.adcResistance}',
          ),
          _kv(
            'RB0 / MED_EN',
            c.current == null
                ? '—'
                : '${c.current!.frame.rb0} / ${c.current!.frame.medEn}',
          ),
          const Divider(),
          SelectableText(
            c.lastFrame ?? 'D:<seq>,<an0>,<an1>,<rb0>,<med_en>\\n',
            style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => c.start(),
            icon: const Icon(Icons.refresh),
            label: const Text('Reiniciar escucha'),
          ),
        ],
      ),
    ),
    if (c.localError != null) ...[
      const SizedBox(height: 12),
      _notice(c.localError!, warning: true),
    ],
    const SizedBox(height: 22),
    _section('SUPABASE', Icons.cloud_outlined),
    _card(
      Column(
        children: [
          _kv('Último HTTP', c.httpCode?.toString() ?? '—'),
          _kv('Último envío confirmado', dateText(c.lastUpload)),
          _kv('Capturas sin confirmar', '${c.droppedUploads}'),
          _kv('Modo', 'Directo · sin cola offline'),
          const SizedBox(height: 8),
          Text(
            c.syncMessage,
            style: const TextStyle(fontSize: 12, color: muted),
          ),
        ],
      ),
    ),
    const SizedBox(height: 22),
    _section('PAYLOAD ACTUAL · 9 CAMPOS', Icons.data_object),
    if (!c.connected)
      const Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: Text(
          'Última lectura, no se envía mientras esté desconectado.',
          style: TextStyle(fontSize: 12, color: muted),
        ),
      ),
    _jsonCard(c.current?.prettyJson ?? '// Esperando una trama válida'),
    if (c.lastSentPayload != null) ...[
      const SizedBox(height: 20),
      _section('ÚLTIMO PAYLOAD ENVIADO', Icons.upload),
      _jsonCard(const JsonEncoder.withIndent('  ').convert(c.lastSentPayload)),
    ],
  ]);

  Widget _history() => RefreshIndicator(
    onRefresh: c.loadHistory,
    child: _scroll([
      _section('TENDENCIA EN VIVO', Icons.monitor_heart_outlined),
      _card(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resistencia / tiempo',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const Text(
              'Últimas 180 muestras · solo memoria de esta sesión',
              style: TextStyle(color: muted, fontSize: 11),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 180,
              width: double.infinity,
              child: c.trend.where((m) => m.resistance != null).length < 2
                  ? const Center(
                      child: Text(
                        'Esperando mediciones válidas',
                        style: TextStyle(color: muted),
                      ),
                    )
                  : CustomPaint(painter: TrendPainter(List.of(c.trend))),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  c.trend.isEmpty ? '—' : timeText(c.trend.first.receivedAt),
                  style: const TextStyle(fontSize: 10, color: muted),
                ),
                const Text(
                  'Tiempo →',
                  style: TextStyle(fontSize: 10, color: muted),
                ),
                Text(
                  c.trend.isEmpty ? '—' : timeText(c.trend.last.receivedAt),
                  style: const TextStyle(fontSize: 10, color: muted),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 22),
      Row(
        children: [
          const Expanded(
            child: Text(
              'REGISTROS EN SUPABASE',
              style: TextStyle(
                fontSize: 11,
                color: muted,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
          IconButton(
            onPressed: c.loadingHistory ? null : c.loadHistory,
            tooltip: 'Actualizar historial',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      if (c.loadingHistory) const LinearProgressIndicator(),
      if (c.historyError != null) _notice(c.historyError!, warning: true),
      if (!c.loadingHistory &&
          c.remoteHistory.isEmpty &&
          c.historyError == null)
        _card(
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: Text('Todavía no hay registros.')),
          ),
        ),
      ...c.remoteHistory.map((row) {
        final r = row['resistance_ohm'] as num?;
        final date = DateTime.tryParse('${row['created_at']}');
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _card(
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xffedf4e7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.timeline, color: green),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r == null
                            ? 'Sin medición válida'
                            : '${r.toStringAsFixed(4)} Ω',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: ink,
                        ),
                      ),
                      Text(
                        dateText(date),
                        style: const TextStyle(fontSize: 11, color: muted),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${row['battery_percent']} %',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      '${row['status']}',
                      style: const TextStyle(fontSize: 9, color: muted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
      const SizedBox(height: 8),
      const Text(
        'Se consultan los 100 registros más recientes de OHM01. Desliza hacia abajo para actualizar.',
        style: TextStyle(fontSize: 11, color: muted),
      ),
    ]),
  );

  Widget _syncStrip() => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(
        c.httpCode == 201 ? Icons.cloud_done_outlined : Icons.cloud_outlined,
        size: 18,
        color: c.httpCode == 201 ? green : muted,
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          c.syncMessage,
          style: const TextStyle(color: muted, fontSize: 11),
        ),
      ),
    ],
  );
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.controller});
  final AppController controller;
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final form = GlobalKey<FormState>();
  late final TextEditingController port;
  late final TextEditingController interval;
  late final TextEditingController current;
  late final TextEditingController gain;
  late final TextEditingController offset;
  late bool automatic;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.controller.settings;
    port = TextEditingController(text: '${s.port}');
    interval = TextEditingController(text: '${s.uploadIntervalMs}');
    current = TextEditingController(text: '${s.systemCurrentMa}');
    gain = TextEditingController(text: '${s.gainCorrection}');
    offset = TextEditingController(text: '${s.offsetOhm}');
    automatic = s.automaticUpload;
  }

  @override
  void dispose() {
    for (final text in [port, interval, current, gain, offset]) {
      text.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Form(
    key: form,
    child: _scroll([
      _section('RED Y SINCRONIZACIÓN', Icons.wifi),
      _card(
        Column(
          children: [
            _field(
              port,
              'Puerto UDP',
              '1024 a 65535',
              integer: true,
              minimum: 1024,
              maximum: 65535,
            ),
            const SizedBox(height: 16),
            _field(
              interval,
              'Intervalo de envío (ms)',
              '1000 a 3600000',
              integer: true,
              minimum: 1000,
              maximum: 3600000,
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Envío automático',
                style: TextStyle(fontSize: 14),
              ),
              subtitle: const Text(
                'Además del botón de captura manual',
                style: TextStyle(fontSize: 11),
              ),
              value: automatic,
              onChanged: saving ? null : (v) => setState(() => automatic = v),
            ),
            const Text(
              'Descubrimiento automático por broadcast. No se necesita IP fija. El teléfono y el ESP-01 deben compartir red.',
              style: TextStyle(color: muted, fontSize: 12),
            ),
          ],
        ),
      ),
      const SizedBox(height: 22),
      _section('BATERÍA Y CALIBRACIÓN', Icons.tune),
      _card(
        Column(
          children: [
            _field(
              current,
              'Consumo del sistema (mA)',
              'Nominal: 85.0 mA',
              minimum: 0.001,
              maximum: 100000,
            ),
            const SizedBox(height: 16),
            _field(
              gain,
              'Corrección de ganancia',
              'Nominal: 1.0',
              minimum: 0.000001,
              maximum: 1000,
            ),
            const SizedBox(height: 16),
            _field(
              offset,
              'Offset de resistencia (Ω)',
              'Nominal: 0.0 Ω · intervalo −1 a 1',
              minimum: -1,
              maximum: 1,
            ),
            const SizedBox(height: 16),
            const Text(
              'R corregida = R calculada × ganancia + offset. Los valores negativos se rechazan: no se ocultan limitándolos a cero.',
              style: TextStyle(fontSize: 12, color: muted),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      FilledButton.icon(
        onPressed: saving ? null : _save,
        icon: const Icon(Icons.check),
        label: Text(saving ? 'Guardando…' : 'Guardar ajustes'),
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
      ),
      TextButton(
        onPressed: saving
            ? null
            : () => setState(() {
                port.text = '4210';
                interval.text = '5000';
                current.text = '85.0';
                gain.text = '1.0';
                offset.text = '0.0';
                automatic = true;
              }),
        child: const Text('Restablecer valores del formulario'),
      ),
      if (widget.controller.settingsError != null)
        _notice(widget.controller.settingsError!, warning: true),
      const SizedBox(height: 14),
      _notice(
        'Solo se guardan los ajustes. Las mediciones se envían directamente a Supabase: si falla Internet, no se conservan ni se reenvían. La adquisición funciona con la app abierta en primer plano.',
      ),
      const SizedBox(height: 22),
      const Center(
        child: Text(
          'OHM01 · v1.0.0\nUniversidad Industrial de Santander\nLaboratorio de Diseño de Sistemas Electrónicos',
          textAlign: TextAlign.center,
          style: TextStyle(color: muted, fontSize: 11, height: 1.7),
        ),
      ),
    ]),
  );

  Widget _field(
    TextEditingController text,
    String label,
    String hint, {
    bool integer = false,
    double minimum = 0,
    double maximum = double.infinity,
  }) => TextFormField(
    controller: text,
    enabled: !saving,
    keyboardType: TextInputType.numberWithOptions(
      decimal: !integer,
      signed: minimum < 0,
    ),
    decoration: InputDecoration(labelText: label, helperText: hint),
    validator: (value) {
      final clean = (value ?? '').replaceAll(',', '.');
      final n = double.tryParse(clean);
      if (n == null ||
          !n.isFinite ||
          n < minimum ||
          n > maximum ||
          integer && n != n.truncateToDouble()) {
        return 'Introduzca un valor válido';
      }
      return null;
    },
  );

  Future<void> _save() async {
    if (!form.currentState!.validate()) return;
    double number(TextEditingController t) =>
        double.parse(t.text.replaceAll(',', '.'));
    setState(() => saving = true);
    try {
      await widget.controller.saveSettings(
        AppSettings(
          port: number(port).toInt(),
          uploadIntervalMs: number(interval).toInt(),
          systemCurrentMa: number(current),
          gainCorrection: number(gain),
          offsetOhm: number(offset),
          automaticUpload: automatic,
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ajustes guardados. Esperando una nueva lectura.'),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudieron guardar: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
}

class TrendPainter extends CustomPainter {
  TrendPainter(this.samples);
  final List<Measurement> samples;
  @override
  void paint(Canvas canvas, Size size) {
    final valid = samples.where((m) => m.resistance != null).toList();
    if (valid.length < 2) return;
    final low = valid.map((m) => m.resistance!).reduce(math.min);
    final high = valid.map((m) => m.resistance!).reduce(math.max);
    final padding = math.max((high - low) * .2, .0005);
    final minY = math.max(0.0, low - padding);
    final maxY = math.min(1.0, high + padding);
    const left = 52.0;
    final width = math.max(1.0, size.width - left - 8);
    final height = size.height - 14;
    final start = samples.first.receivedAt.millisecondsSinceEpoch;
    final span = math.max(
      1,
      samples.last.receivedAt.millisecondsSinceEpoch - start,
    );
    for (var i = 0; i <= 4; i++) {
      final y = height * i / 4;
      canvas.drawLine(
        Offset(left, y),
        Offset(size.width, y),
        Paint()
          ..color = const Color(0xffe7ede3)
          ..strokeWidth = 1,
      );
      final text = TextPainter(
        text: TextSpan(
          text: '${(maxY - (maxY - minY) * i / 4).toStringAsFixed(4)} Ω',
          style: const TextStyle(color: muted, fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, Offset(0, y - (i == 0 ? 0 : 5)));
    }
    final path = Path();
    bool newSegment = true;
    DateTime? previous;
    for (final m in samples) {
      if (m.resistance == null) {
        newSegment = true;
        continue;
      }
      final x =
          left + (m.receivedAt.millisecondsSinceEpoch - start) / span * width;
      final y = height * (1 - (m.resistance! - minY) / (maxY - minY));
      if (newSegment ||
          previous != null &&
              m.receivedAt.difference(previous).inMilliseconds > 2000) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      previous = m.receivedAt;
      newSegment = false;
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = green
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant TrendPainter oldDelegate) => true;
}

Widget _scroll(List<Widget> children) => ListView(
  padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
  physics: const AlwaysScrollableScrollPhysics(),
  children: children,
);
Widget _card(Widget child) => Material(
  color: Colors.white,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),
    side: const BorderSide(color: Color(0xffe5ece1)),
  ),
  child: Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    child: child,
  ),
);
Widget _section(String label, IconData icon) => Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: Row(
    children: [
      Icon(icon, size: 17, color: muted),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          label,
          style: const TextStyle(
            color: muted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      ),
    ],
  ),
);
Widget _kv(String label, String value) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 7),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Text(label, style: const TextStyle(color: muted, fontSize: 12)),
      ),
      const SizedBox(width: 12),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
    ],
  ),
);
Widget _smallMetric(String label, String value, IconData icon) => _card(
  Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: green, size: 19),
      const SizedBox(height: 10),
      Text(
        value,
        style: const TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w500,
          color: ink,
        ),
      ),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(fontSize: 11, color: muted)),
    ],
  ),
);
Widget _notice(String text, {bool warning = false}) => Container(
  padding: const EdgeInsets.all(14),
  decoration: BoxDecoration(
    color: warning ? const Color(0xffffefdf) : const Color(0xffe9eee6),
    borderRadius: BorderRadius.circular(14),
  ),
  child: Text(
    text,
    style: TextStyle(
      color: warning ? const Color(0xff8a4813) : muted,
      fontSize: 12,
      height: 1.5,
    ),
  ),
);
Widget _jsonCard(String text) => Container(
  width: double.infinity,
  padding: const EdgeInsets.all(18),
  decoration: BoxDecoration(
    color: ink,
    borderRadius: BorderRadius.circular(18),
  ),
  child: SelectableText(
    text,
    style: const TextStyle(
      fontFamily: 'monospace',
      color: Color(0xffc0e2a5),
      fontSize: 11,
      height: 1.8,
    ),
  ),
);
Color statusColor(DeviceStatus status) => switch (status) {
  DeviceStatus.ok => green,
  DeviceStatus.charging => Colors.blue,
  DeviceStatus.lowBattery => Colors.red,
  DeviceStatus.overRange => Colors.orange,
};
Color _brightStatus(DeviceStatus status) => switch (status) {
  DeviceStatus.ok => const Color(0xffb4e78b),
  DeviceStatus.charging => const Color(0xff8fc9ff),
  DeviceStatus.lowBattery => const Color(0xffffa59b),
  DeviceStatus.overRange => const Color(0xffffcc82),
};
String durationText(int? seconds) => seconds == null
    ? '—'
    : '${(seconds ~/ 3600).toString().padLeft(2, '0')} h ${((seconds % 3600) ~/ 60).toString().padLeft(2, '0')} min';
String timeText(DateTime date) {
  final d = date.toLocal();
  return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')}';
}

String dateText(DateTime? date) {
  if (date == null) return '—';
  final d = date.toLocal();
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} · ${timeText(d)}';
}
