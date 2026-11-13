# OHM01 · Android

Aplicación Flutter para el medidor portátil de bajas resistencias de la UIS / E3T.
Recibe ADC y pines por UDP, calcula resistencia y estado de batería y envía
registros directamente a Supabase. **No utiliza SQLite ni cola offline.**

## Funciones

- Medición en Ω (4 decimales) o mΩ (2 decimales), con estados de color.
- Voltaje sobre Rx y a la salida del INA333.
- Batería, interpolación por tramos, carga y autonomía estimadas.
- Diagnóstico de UDP, secuencias, pérdidas, JSON y último HTTP.
- Tendencia de las últimas 180 muestras en RAM e historial remoto de 100 registros.
- Captura manual y envío automático configurable (5000 ms por defecto).
- Ajustes persistidos con SharedPreferences; **no se persisten mediciones**.
- Watchdog de 2000 ms: oculta la lectura y detiene nuevos envíos automáticos.

## Herramientas instaladas en este equipo

- Flutter: `%LOCALAPPDATA%\ohm01-tools\flutter` (incluye Dart).
- Android SDK: `%LOCALAPPDATA%\Android\Sdk`.
- Java: se utiliza el JDK 17 que ya estaba instalado.

Desde PowerShell, en esta carpeta:

```powershell
. .\tools\env.ps1
Set-Location $OhmBuildPath
flutter doctor -v
flutter analyze
flutter test --concurrency=1
flutter build apk --debug
```

`tools/env.ps1` modifica solo la sesión actual, sin reemplazar el PATH global.
Se redujo el uso de memoria de Flutter y Gradle para este equipo.
Como la ruta original contiene tildes, el script proporciona `$OhmBuildPath`
mediante una unión de directorios en `%LOCALAPPDATA%\ohm01-tools\app`.
Son los mismos archivos, no una copia. Esto evita problemas del analizador de
Flutter con rutas Unicode en Windows. Los scripts de compilación e instalación
usan esa ruta automáticamente.

### Compilar e instalar

```powershell
.\tools\build-apk.ps1
# APK: build\app\outputs\flutter-apk\app-debug.apk

# Conectar Android por USB, activar depuración USB y aceptar la autorización:
.\tools\install-android.ps1
```

Si hay varios dispositivos: `tools\install-android.ps1 -DeviceId NUMERO_DE_SERIE`.
También puede copiarse el APK al teléfono y abrirlo autorizando la instalación
desde esa fuente. No hace falta instalar Flutter en el celular.

La compilación release se solicita con `tools\build-apk.ps1 -Release`.
La firma configurada es la de desarrollo, para instalación académica directa;
no es una configuración de publicación en Play Store. No incluye un emulador:
se utiliza un teléfono físico. Mínimo con el SDK instalado: Android 7.0 (API 24);
`targetSdk` y `compileSdk`: 36.

## Conexión al instrumento

1. Abrir la app en primer plano.
2. Conectar el ESP-01 en modo Station al router del laboratorio o al hotspot
   del teléfono. Ambos deben poder comunicarse en la misma red.
3. Transmitir un datagrama por lectura a `255.255.255.255:4210`, con ASCII exacto:

```text
D:104,2610,830,1,1\n
```

Aquí `\n` representa un byte LF real, no dos caracteres. No enviar CRLF ni
varias tramas dentro de un datagrama. Los cinco valores son `seq,an0,an1,rb0,med_en`.
Los ADC deben ser promedios enteros de 32 muestras (0–4095); secuencia 0–65535.

La app mantiene una sesión por IP del emisor, rechaza duplicados y secuencias
antiguas y acepta el desbordamiento 65535→0. Tras más de dos segundos sin una
nueva muestra válida, permite descubrir de nuevo el emisor y su secuencia.
El botón «Reiniciar escucha» permite restablecer la sesión manualmente.

El broadcast limitado depende del router y del fabricante del teléfono. No
activar aislamiento de clientes. Algunos hotspots no entregan broadcast al
teléfono anfitrión: probar primero en un router compartido. Se adquiere un
MulticastLock de Android para reducir el filtrado de paquetes Wi-Fi, pero no
puede eliminar restricciones del punto de acceso. El protocolo UDP no autentica
el instrumento: usar una red de laboratorio de confianza.

La pantalla se mantiene encendida mientras se escucha. Al enviar la app a
segundo plano se cierra UDP y se detiene la adquisición. Un envío HTTP ya iniciado
puede terminar; al volver al primer plano se espera una trama nueva.

## Matemática e integridad

```text
Vbat = 2 × adc_an0 × 3.000 / 4095
Vout = adc_an1 × 3.000 / 4095
VRx  = Vout / 41
Rx   = (Vout / 2.46) × gainCorrection + offsetOhm
```

Las fórmulas suponen referencia del INA333 a 0 V y corriente de prueba de 60 mA.
Se calcula con precisión completa antes de clasificar y redondear. Una resistencia
corregida negativa se rechaza y se informa en Diagnóstico; no se disimula como cero.

Curva (V / %): 3.40/0, 3.50/10, 3.60/20, 3.70/40, 3.80/55, 3.90/70,
4.00/80, 4.10/90, 4.20/100. Se interpola linealmente, se acota a 0–100 y se
redondea el porcentaje al entero que se utiliza en el JSON y en los tiempos.
**3.82 V equivale aproximadamente a 58 %, no a 64 %.**

```text
t_carga_s   = round(3700 × (100 − porcentaje) / 100 / 1000 × 1.15 × 3600)
t_descarga_s = round(3700 × porcentaje / 100 / I_sys_mA × 3600)
```

Capacidad nominal: 3700 mAh. Consumo predeterminado: 85 mA, configurable.
Son estimaciones por voltaje, no medición de capacidad real ni contador de carga.
La carga CC/CV real y el consumo variable pueden cambiar los tiempos.
El voltaje en Rx solo se presenta como lectura activa cuando `med_en = 1`.

`rb0=0` significa carga activa; siempre requiere `med_en=0`. Cuando `rb0=1`,
el estado físico `med_en=0` identifica el bloqueo de batería baja, incluso al
conectarse dentro de la banda de histéresis. No se reconstruye un latch imaginario
a partir de un voltaje sin historia. Se rechazan las contradicciones:

- Cargando y `med_en=1`.
- No cargando, AN0 ≤2321 y `med_en=1`.
- No cargando, AN0 ≥2457 y `med_en=0`.

Prioridad: CHARGING → LOW_BATTERY → OVER_RANGE → OK. La protección física
permanece en el firmware del PIC; la app no controla RD0. Puntas abiertas solo
pueden clasificarse como OVER_RANGE si el circuito produce una lectura >1 Ω;
esta trama no tiene un indicador independiente de puntas abiertas.

## Supabase

Se utiliza REST con `apikey`, sin enviar la clave pública como Bearer.
El endpoint y la clave pública proporcionados están en
`lib/services/supabase_service.dart`. Se pueden reemplazar al compilar:

```powershell
flutter build apk --debug --dart-define=SUPABASE_URL=https://PROYECTO.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_CLAVE
```

No se incorpora ninguna clave privada ni `service_role`. Cada POST incluye
exactamente estos nueve campos, nunca `id` ni `created_at`:

```text
device_id, resistance_ohm, battery_voltage_v, battery_percent, charging,
charge_time_remaining_s, discharge_time_remaining_s, measurement_enabled, status
```

Solo HTTP 201 confirma la inserción. En errores de red no hay reintento del mismo
payload ni almacenamiento offline: el próximo intervalo intentará una captura
nueva si llega telemetría fresca. Si se pierde la respuesta HTTP, es posible que
el servidor haya guardado el registro aunque no se confirme en la app.

Historial requiere SELECT e inserción requiere INSERT para `anon`. El script
`supabase/setup.sql` sirve como referencia para un proyecto nuevo y debe
ejecutarse manualmente con permisos de administración, si hace falta. No se han
modificado datos ni políticas remotas automáticamente.

**Seguridad:** las políticas públicas acordadas permiten a quien conozca la clave
leer registros e insertar como OHM01. No equivalen a autenticación del hardware.

## Pruebas con datos sintéticos

Desactivar primero el envío automático para no mezclar datos ficticios con
mediciones reales en Supabase. No pulsar captura durante esta prueba.

```powershell
.\tools\send-test-udp.ps1 -State OK
.\tools\send-test-udp.ps1 -State CHARGING
.\tools\send-test-udp.ps1 -State LOW_BATTERY
.\tools\send-test-udp.ps1 -State OVER_RANGE
```

Se puede usar `-Destination IP_DEL_TELEFONO` para verificar el receptor mediante
unicast si la red filtra broadcast. Permitir los paquetes UDP necesarios en el
firewall si Windows bloquea el emisor de prueba.

## Estructura

- `lib/domain/measurement.dart`: parser, secuencias, fórmulas y payload.
- `lib/services/`: UDP y cliente REST.
- `lib/app_controller.dart`: watchdog, estado, ajustes y envíos.
- `lib/ui/app.dart`: cuatro vistas y gráfica nativa de Flutter.
- `android/`: proyecto Android y bloqueo multicast.
- `test/`: pruebas automatizadas sin escribir en Supabase real.

Para generar una vista previa con una trama simulada y sin enviar datos:

```powershell
flutter test tools/render-preview_test.dart
# Imagen generada: build\previews\medicion.png
```

Esta prueba carga las fuentes del SDK instalado y comprueba el diseño en una
pantalla lógica de 390 × 844. No sustituye las pruebas con el circuito y un Android real.
