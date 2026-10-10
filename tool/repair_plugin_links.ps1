# Directory junctions let Flutter resolve local desktop plugins on Windows
# without requiring Developer Mode. Android/Web builds do not use these runners.
$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
$taskMetadata = Join-Path $taskRoot '.flutter-plugins-dependencies'
if (-not (Test-Path -LiteralPath $taskMetadata)) {
    throw 'Run flutter pub get once to generate plugin metadata first.'
}
$taskPlugins = Get-Content -LiteralPath $taskMetadata -Raw | ConvertFrom-Json
foreach ($taskPlatform in @('windows', 'linux')) {
    $taskPlatformRoot = Join-Path $taskRoot $taskPlatform
    if (-not (Test-Path -LiteralPath $taskPlatformRoot)) { continue }
    $taskLinks = Join-Path $taskPlatformRoot 'flutter\ephemeral\.plugin_symlinks'
    New-Item -ItemType Directory -Path $taskLinks -Force | Out-Null
    foreach ($taskPlugin in $taskPlugins.plugins.$taskPlatform) {
        if ($taskPlugin.name -notmatch '^[a-z0-9_]+$') { throw 'Invalid plugin name.' }
        $taskLink = Join-Path $taskLinks $taskPlugin.name
        if (-not (Test-Path -LiteralPath $taskLink)) {
            $taskTarget = (Resolve-Path -LiteralPath $taskPlugin.path).Path
            New-Item -ItemType Junction -Path $taskLink -Target $taskTarget | Out-Null
        }
    }
}
Write-Output 'Flutter plugin directory links are ready.'
