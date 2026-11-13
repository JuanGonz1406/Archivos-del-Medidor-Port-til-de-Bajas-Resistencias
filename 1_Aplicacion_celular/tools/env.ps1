# Dot-source this script to configure this PowerShell session: . .\tools\env.ps1
$flutterRoot = Join-Path $env:LOCALAPPDATA 'ohm01-tools\flutter'
$env:ANDROID_HOME = Join-Path $env:LOCALAPPDATA 'Android\Sdk'
$env:ANDROID_SDK_ROOT = $env:ANDROID_HOME
$env:FLUTTER_TOOL_ARGS = '--old_gen_heap_size=384'
$env:JAVA_OPTS = '-Xmx256m'
[Environment]::SetEnvironmentVariable('ORG_GRADLE_PROJECT_kotlin.compiler.execution.strategy', 'in-process', 'Process')
$env:PATH = "$flutterRoot\bin;$env:ANDROID_HOME\platform-tools;$env:ANDROID_HOME\cmdline-tools\latest\bin;$env:PATH"

# Flutter's analysis protocol may fail with Unicode in the Windows project path.
# A junction provides an ASCII build path to the SAME files; there is no copy.
$OhmBuildPath = Split-Path $PSScriptRoot -Parent
if ($OhmBuildPath -match '[^\x00-\x7F]') {
    $junction = Join-Path $env:LOCALAPPDATA 'ohm01-tools\app'
    if (!(Test-Path $junction)) {
        New-Item -ItemType Junction -Path $junction -Target $OhmBuildPath | Out-Null
    }
    $item = Get-Item $junction
    if ($item.LinkType -ne 'Junction' -or $item.Target[0] -ne $OhmBuildPath) {
        throw "La ruta auxiliar $junction ya existe y apunta a otro proyecto. No se ha modificado."
    }
    $OhmBuildPath = $junction
}
