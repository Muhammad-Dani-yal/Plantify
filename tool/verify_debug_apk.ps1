# Verify the actual packaged Dart code, not just Gradle's successful exit.
$ErrorActionPreference = 'Stop'
$taskProject = Split-Path -Parent $PSScriptRoot
$taskApkPath = Join-Path $taskProject 'build\app\outputs\flutter-apk\app-debug.apk'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$taskArchive = [IO.Compression.ZipFile]::OpenRead($taskApkPath)
try {
    $taskEntry = $taskArchive.GetEntry('assets/flutter_assets/kernel_blob.bin')
    if ($null -eq $taskEntry) { throw 'Expected a debug APK with a packaged Dart kernel.' }
    $taskReader = [IO.StreamReader]::new($taskEntry.Open(), [Text.Encoding]::UTF8)
    try { $taskKernel = $taskReader.ReadToEnd() } finally { $taskReader.Dispose() }
    foreach ($taskMarker in @('world_photos.dart', 'motion_icon.dart', 'Plantify AI guide', 'No reusable photograph available yet.', 'plant_profile.dart', 'Browse care profiles', 'plants discovered', 'Photo request no longer visible')) {
        if (-not $taskKernel.Contains($taskMarker)) { throw "Stale APK: missing $taskMarker" }
    }
    if (-not $taskKernel.Contains('Downloaded plants (') -or -not $taskKernel.Contains('Explore online plants')) { throw 'Stale APK: missing downloaded-first discovery.' }
    Write-Output 'PASS: packaged Android APK contains downloaded-first discovery, shared profiles, photos, animations, and AI guide.'
} finally {
    $taskArchive.Dispose()
}
