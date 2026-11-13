param([string]$DeviceId, [string]$Apk = 'build\app\outputs\flutter-apk\app-debug.apk', [int]$UserId = 0)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\env.ps1"
Push-Location $OhmBuildPath
try {
    if (!(Test-Path $Apk)) { throw "No existe el APK: $Apk. Ejecuta tools\build-apk.ps1." }
    if ($DeviceId) { adb -s $DeviceId install --user $UserId -r $Apk }
    else { adb install --user $UserId -r $Apk }
    if ($LASTEXITCODE -ne 0) { throw 'Conecta el celular por USB, habilita depuración USB y acepta la autorización.' }
} finally { Pop-Location }
