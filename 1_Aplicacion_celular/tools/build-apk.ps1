param([switch]$Release)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\env.ps1"
Push-Location $OhmBuildPath
try {
    flutter pub get
    if ($LASTEXITCODE -ne 0) { throw 'No se pudieron resolver las dependencias' }
    flutter analyze
    if ($LASTEXITCODE -ne 0) { throw 'Falló el análisis estático' }
    flutter test --concurrency=1
    if ($LASTEXITCODE -ne 0) { throw 'Fallaron las pruebas' }
    $mode = if ($Release) { '--release' } else { '--debug' }
    flutter build apk $mode
    if ($LASTEXITCODE -ne 0) { throw 'Falló la compilación Android' }
} finally { Pop-Location }
